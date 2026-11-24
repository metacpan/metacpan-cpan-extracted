package Google::Devtools::Testing::V1::DirectAccessService;

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
    eval { require Google::Devtools::Testing::V1::AdbService };
    eval { require Google::Devtools::Testing::V1::TestExecution };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvZGV2dG9vbHMvdGVzdGluZy92MS9kaXJlY3RfYWNjZXNzX3NlcnZpY2UucHJv
dG8SGmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25z
LnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2RldnRvb2xz
L3Rlc3RpbmcvdjEvYWRiX3NlcnZpY2UucHJvdG8aL2dvb2dsZS9kZXZ0b29scy90ZXN0aW5n
L3YxL3Rlc3RfZXhlY3V0aW9uLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJv
dG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxk
X21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iwAEKGkNyZWF0
ZURldmljZVNlc3Npb25SZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJl
c291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSVQoOZGV2aWNl
X3Nlc3Npb24YAiABKAsyKS5nb29nbGUuZGV2dG9vbHMudGVzdGluZy52MS5EZXZpY2VTZXNz
aW9uQgPgQQJSDWRldmljZVNlc3Npb24iywEKGUxpc3REZXZpY2VTZXNzaW9uc1JlcXVlc3QS
SwoGcGFyZW50GAQgASgJQjPgQQL6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFw
aXMuY29tL1Byb2plY3RSBnBhcmVudBIgCglwYWdlX3NpemUYASABKAVCA+BBAVIIcGFnZVNp
emUSIgoKcGFnZV90b2tlbhgCIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAMgASgJ
QgPgQQFSBmZpbHRlciKYAQoaTGlzdERldmljZVNlc3Npb25zUmVzcG9uc2USUgoPZGV2aWNl
X3Nlc3Npb25zGAEgAygLMikuZ29vZ2xlLmRldnRvb2xzLnRlc3RpbmcudjEuRGV2aWNlU2Vz
c2lvblIOZGV2aWNlU2Vzc2lvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFn
ZVRva2VuIlsKF0dldERldmljZVNlc3Npb25SZXF1ZXN0EkAKBG5hbWUYASABKAlCLOBBAvpB
JgokdGVzdGluZy5nb29nbGVhcGlzLmNvbS9EZXZpY2VTZXNzaW9uUgRuYW1lIl4KGkNhbmNl
bERldmljZVNlc3Npb25SZXF1ZXN0EkAKBG5hbWUYASABKAlCLOBBAvpBJgokdGVzdGluZy5n
b29nbGVhcGlzLmNvbS9EZXZpY2VTZXNzaW9uUgRuYW1lIrUBChpVcGRhdGVEZXZpY2VTZXNz
aW9uUmVxdWVzdBJVCg5kZXZpY2Vfc2Vzc2lvbhgBIAEoCzIpLmdvb2dsZS5kZXZ0b29scy50
ZXN0aW5nLnYxLkRldmljZVNlc3Npb25CA+BBAlINZGV2aWNlU2Vzc2lvbhJACgt1cGRhdGVf
bWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFz
ayKSCQoNRGV2aWNlU2Vzc2lvbhIXCgRuYW1lGAEgASgJQgPgQQFSBG5hbWUSJgoMZGlzcGxh
eV9uYW1lGAIgASgJQgPgQQNSC2Rpc3BsYXlOYW1lElEKBXN0YXRlGAMgASgOMjYuZ29vZ2xl
LmRldnRvb2xzLnRlc3RpbmcudjEuRGV2aWNlU2Vzc2lvbi5TZXNzaW9uU3RhdGVCA+BBA1IF
c3RhdGUSaQoPc3RhdGVfaGlzdG9yaWVzGA4gAygLMjsuZ29vZ2xlLmRldnRvb2xzLnRlc3Rp
bmcudjEuRGV2aWNlU2Vzc2lvbi5TZXNzaW9uU3RhdGVFdmVudEID4EEDUg5zdGF0ZUhpc3Rv
cmllcxIyCgN0dGwYDSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBAUgAUgN0
dGwSQgoLZXhwaXJlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQFIAFIKZXhwaXJlVGltZRJNChJpbmFjdGl2aXR5X3RpbWVvdXQYByABKAsyGS5nb29nbGUu
cHJvdG9idWYuRHVyYXRpb25CA+BBA1IRaW5hY3Rpdml0eVRpbWVvdXQSQAoLY3JlYXRlX3Rp
bWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUS
SwoRYWN0aXZlX3N0YXJ0X3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSD2FjdGl2ZVN0YXJ0VGltZRJVCg5hbmRyb2lkX2RldmljZRgPIAEoCzIpLmdvb2ds
ZS5kZXZ0b29scy50ZXN0aW5nLnYxLkFuZHJvaWREZXZpY2VCA+BBAlINYW5kcm9pZERldmlj
ZRrfAQoRU2Vzc2lvblN0YXRlRXZlbnQSYAoNc2Vzc2lvbl9zdGF0ZRgBIAEoDjI2Lmdvb2ds
ZS5kZXZ0b29scy50ZXN0aW5nLnYxLkRldmljZVNlc3Npb24uU2Vzc2lvblN0YXRlQgPgQQNS
DHNlc3Npb25TdGF0ZRI+CgpldmVudF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUglldmVudFRpbWUSKAoNc3RhdGVfbWVzc2FnZRgDIAEoCUID4EEDUgxz
dGF0ZU1lc3NhZ2UijAEKDFNlc3Npb25TdGF0ZRIdChlTRVNTSU9OX1NUQVRFX1VOU1BFQ0lG
SUVEEAASDQoJUkVRVUVTVEVEEAESCwoHUEVORElORxACEgoKBkFDVElWRRADEgsKB0VYUElS
RUQQBBIMCghGSU5JU0hFRBAFEg8KC1VOQVZBSUxBQkxFEAYSCQoFRVJST1IQBzpW6kFTCiR0
ZXN0aW5nLmdvb2dsZWFwaXMuY29tL0RldmljZVNlc3Npb24SK3Byb2plY3RzL3twcm9qZWN0
fS9kZXZpY2VTZXNzaW9ucy97c2Vzc2lvbn1CDAoKZXhwaXJhdGlvbjKPCQoTRGlyZWN0QWNj
ZXNzU2VydmljZRLQAQoTQ3JlYXRlRGV2aWNlU2Vzc2lvbhI2Lmdvb2dsZS5kZXZ0b29scy50
ZXN0aW5nLnYxLkNyZWF0ZURldmljZVNlc3Npb25SZXF1ZXN0GikuZ29vZ2xlLmRldnRvb2xz
LnRlc3RpbmcudjEuRGV2aWNlU2Vzc2lvbiJWgtPkkwI4IiYvdjEve3BhcmVudD1wcm9qZWN0
cy8qfS9kZXZpY2VTZXNzaW9uczoOZGV2aWNlX3Nlc3Npb27aQRVwYXJlbnQsZGV2aWNlX3Nl
c3Npb24SvAEKEkxpc3REZXZpY2VTZXNzaW9ucxI1Lmdvb2dsZS5kZXZ0b29scy50ZXN0aW5n
LnYxLkxpc3REZXZpY2VTZXNzaW9uc1JlcXVlc3QaNi5nb29nbGUuZGV2dG9vbHMudGVzdGlu
Zy52MS5MaXN0RGV2aWNlU2Vzc2lvbnNSZXNwb25zZSI3gtPkkwIoEiYvdjEve3BhcmVudD1w
cm9qZWN0cy8qfS9kZXZpY2VTZXNzaW9uc9pBBnBhcmVudBKpAQoQR2V0RGV2aWNlU2Vzc2lv
bhIzLmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxLkdldERldmljZVNlc3Npb25SZXF1ZXN0
GikuZ29vZ2xlLmRldnRvb2xzLnRlc3RpbmcudjEuRGV2aWNlU2Vzc2lvbiI1gtPkkwIoEiYv
djEve25hbWU9cHJvamVjdHMvKi9kZXZpY2VTZXNzaW9ucy8qfdpBBG5hbWUSnwEKE0NhbmNl
bERldmljZVNlc3Npb24SNi5nb29nbGUuZGV2dG9vbHMudGVzdGluZy52MS5DYW5jZWxEZXZp
Y2VTZXNzaW9uUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI4gtPkkwIyIi0vdjEv
e25hbWU9cHJvamVjdHMvKi9kZXZpY2VTZXNzaW9ucy8qfTpjYW5jZWw6ASoS5AEKE1VwZGF0
ZURldmljZVNlc3Npb24SNi5nb29nbGUuZGV2dG9vbHMudGVzdGluZy52MS5VcGRhdGVEZXZp
Y2VTZXNzaW9uUmVxdWVzdBopLmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxLkRldmljZVNl
c3Npb24iaoLT5JMCRzI1L3YxL3tkZXZpY2Vfc2Vzc2lvbi5uYW1lPXByb2plY3RzLyovZGV2
aWNlU2Vzc2lvbnMvKn06DmRldmljZV9zZXNzaW9u2kEaZGV2aWNlX3Nlc3Npb24sdXBkYXRl
X21hc2sSZQoKQWRiQ29ubmVjdBImLmdvb2dsZS5kZXZ0b29scy50ZXN0aW5nLnYxLkFkYk1l
c3NhZ2UaKS5nb29nbGUuZGV2dG9vbHMudGVzdGluZy52MS5EZXZpY2VNZXNzYWdlIgAoATAB
GkrKQRZ0ZXN0aW5nLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5j
b20vYXV0aC9jbG91ZC1wbGF0Zm9ybUJ/Ch5jb20uZ29vZ2xlLmRldnRvb2xzLnRlc3Rpbmcu
djFCGERpcmVjdEFjY2Vzc1NlcnZpY2VQcm90b1ABWkFnb29nbGUuZ29sYW5nLm9yZy9nZW5w
cm90by9nb29nbGVhcGlzL2RldnRvb2xzL3Rlc3RpbmcvdjE7dGVzdGluZ0r8TgoHEgUOAKwC
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADYKCQoCAwUS
AxcAOQoJCgIDBhIDGAAoCgkKAgMHEgMZACUKCQoCAwgSAxoAKgoJCgIDCRIDGwApCggKAQgS
Ax0AWAoJCgIICxIDHQBYCggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8AOQoJCgIICBID
HwA5CggKAQgSAyAANwoJCgIIARIDIAA3Co4FCgIGABIEMAByARqBBSBBIHNlcnZpY2UgZm9y
IGFsbG9jYXRpbmcgZGV2aWNlcyBhbmQgaW50ZXJhY3Rpbmcgd2l0aCB0aGUgbGl2ZS1hbGxv
Y2F0ZWQKIGRldmljZXMuCgogVGhpcyBzZXJ2aWNlIGlzIHBhcnQgb2YgRmlyZWJhc2UgVGVz
dCBMYWIuIFRvIGxlYXJuIGFib3V0IGhvdyB0byB1c2UgdGhlCiBwcm9kdWN0LCBhbmQgaG93
IHRvIGludGVncmF0ZSBpdCB3aXRoIHlvdXIgc3lzdGVtLAogdmlzaXQgaHR0cHM6Ly9maXJl
YmFzZS5nb29nbGUuY29tL2RvY3MvdGVzdC1sYWIuCgogRWFjaCBTZXNzaW9uIHdpbGwgd2Fp
dCBmb3IgYXZhaWxhYmxlIGNhcGFjaXR5LCBhdCBhIGhpZ2hlcgogcHJpb3JpdHkgb3ZlciBU
ZXN0IEV4ZWN1dGlvbi4gV2hlbiBhbGxvY2F0ZWQsIHRoZSBzZXNzaW9uIHdpbGwgYmUgZXhw
b3NlZAogdGhyb3VnaCBhIHN0cmVhbSBmb3IgaW50ZWdyYXRpb24uCgogRGlyZWN0QWNjZXNz
U2VydmljZSBpcyBjdXJyZW50bHkgYXZhaWxhYmxlIGFzIGEgcHJldmlldyB0byBzZWxlY3Qg
ZGV2ZWxvcGVycy4KIFlvdSBjYW4gcmVnaXN0ZXIgdG9kYXkgb24gYmVoYWxmIG9mIHlvdSBh
bmQgeW91ciB0ZWFtIGF0CiBodHRwczovL2RldmVsb3Blci5hbmRyb2lkLmNvbS9zdHVkaW8v
cHJldmlldy9hbmRyb2lkLWRldmljZS1zdHJlYW1pbmcKCgoKAwYAARIDMAgbCgoKAwYAAxID
MQI+CgwKBQYAA5kIEgMxAj4KCwoDBgADEgQyAjM3Cg0KBQYAA5oIEgQyAjM3Cj0KBAYAAgAS
BDYCPAMaLyBQT1NUIC92MS9wcm9qZWN0cy97cHJvamVjdF9pZH0vZGV2aWNlU2Vzc2lvbnMK
CgwKBQYAAgABEgM2BhkKDAoFBgACAAISAzYaNAoMCgUGAAIAAxIDNj9MCg0KBQYAAgAEEgQ3
BDoGChEKCQYAAgAEsMq8IhIENwQ6BgoMCgUGAAIABBIDOwRDCg8KCAYAAgAEmwgAEgM7BEMK
bgoEBgACARIEQAJGAxpgIEdFVCAvdjEvcHJvamVjdHMve3Byb2plY3RfaWR9L2RldmljZVNl
c3Npb25zCiBMaXN0cyBkZXZpY2UgU2Vzc2lvbnMgb3duZWQgYnkgdGhlIHByb2plY3QgdXNl
ci4KCgwKBQYAAgEBEgNABhgKDAoFBgACAQISA0AZMgoMCgUGAAIBAxIDQQ8pCg0KBQYAAgEE
EgRCBEQGChEKCQYAAgEEsMq8IhIEQgREBgoMCgUGAAIBBBIDRQQ0Cg8KCAYAAgEEmwgAEgNF
BDQK+QEKBAYAAgISBEwCUQMa6gEgR0VUIC92MS9wcm9qZWN0cy97cHJvamVjdF9pZH0vZGV2
aWNlU2Vzc2lvbnMve2RldmljZV9zZXNzaW9uX2lkfQogUmV0dXJuIGEgRGV2aWNlU2Vzc2lv
biwgd2hpY2ggZG9jdW1lbnRzIHRoZSBhbGxvY2F0aW9uIHN0YXR1cyBhbmQKIHdoZXRoZXIg
dGhlIGRldmljZSBpcyBhbGxvY2F0ZWQuIENsaWVudHMgbWFraW5nIHJlcXVlc3RzIGZyb20g
dGhpcyBBUEkKIG11c3QgcG9sbCBHZXREZXZpY2VTZXNzaW9uLgoKDAoFBgACAgESA0wGFgoM
CgUGAAICAhIDTBcuCgwKBQYAAgIDEgNMOUYKDQoFBgACAgQSBE0ETwYKEQoJBgACAgSwyrwi
EgRNBE8GCgwKBQYAAgIEEgNQBDIKDwoIBgACAgSbCAASA1AEMgqtAgoEBgACAxIEWAJeAxqe
AiBQT1NUCiAvdjEvcHJvamVjdHMve3Byb2plY3RfaWR9L2RldmljZVNlc3Npb25zL3tkZXZp
Y2Vfc2Vzc2lvbl9pZH06Y2FuY2VsCiBDaGFuZ2VzIHRoZSBEZXZpY2VTZXNzaW9uIHRvIHN0
YXRlIEZJTklTSEVEIGFuZCB0ZXJtaW5hdGVzIGFsbCBjb25uZWN0aW9ucy4KIENhbmNlbGVk
IHNlc3Npb25zIGFyZSBub3QgZGVsZXRlZCBhbmQgY2FuIGJlIHJldHJpZXZlZCBvcgogbGlz
dGVkIGJ5IHRoZSB1c2VyIHVudGlsIHRoZXkgZXhwaXJlIGJhc2VkIG9uIHRoZSAyOCBkYXkg
ZGVsZXRpb24gcG9saWN5LgoKDAoFBgACAwESA1gGGQoMCgUGAAIDAhIDWBo0CgwKBQYAAgMD
EgNZDyQKDQoFBgACAwQSBFoEXQYKEQoJBgACAwSwyrwiEgRaBF0GCrUBCgQGAAIEEgRkAmoD
GqYBIFBBVENICiAvdjEvcHJvamVjdHMve3Byb2plY3RJZH0vZGV2aWNlU2Vzc2lvbnMvZGV2
aWNlU2Vzc2lvbklkfTp1cGRhdGVEZXZpY2VTZXNzaW9uCiBVcGRhdGVzIHRoZSBjdXJyZW50
IGRldmljZSBzZXNzaW9uIHRvIHRoZSBmaWVsZHMgZGVzY3JpYmVkIGJ5IHRoZQogdXBkYXRl
X21hc2suCgoMCgUGAAIEARIDZAYZCgwKBQYAAgQCEgNkGjQKDAoFBgACBAMSA2Q/TAoNCgUG
AAIEBBIEZQRoBgoRCgkGAAIEBLDKvCISBGUEaAYKDAoFBgACBAQSA2kESAoPCggGAAIEBJsI
ABIDaQRICq8CCgQGAAIFEgNxAkUaoQIgRXhwb3NlcyBBREIgY29ubmVjdGlvbiBmb3IgdXNl
IHdpdGggdGhlIEFkYiBEZXZpY2UgRm9yd2FyZGVyIHByb2plY3QKIGlmIHRoZSByZXNlcnZl
ZCBkZXZpY2Ugc3VwcG9ydHMgQURCLgogZ1JQQyBoZWFkZXJzIGFyZSB1c2VkIHRvIGF1dGhl
bnRpY2F0ZSB0aGUgQ29ubmVjdCBSUEMsIGFzIHdlbGwgYXMKIGFzc29jaWF0ZSB0byBhIHBh
cnRpY3VsYXIgZGV2aWNlIHNlc3Npb24uCiBJbiBwYXJ0aWN1bGFyLCB0aGUgdXNlciBtdXN0
IHNwZWNpZnkgdGhlICJYLUZUTC1TZXNzaW9uLU5hbWUiIGhlYWRlci4KCgwKBQYAAgUBEgNx
BhAKDAoFBgACBQUSA3ERFwoMCgUGAAIFAhIDcRgiCgwKBQYAAgUGEgNxLTMKDAoFBgACBQMS
A3E0QQpJCgIEABIFdQCBAQEaPCBBIFJlcXVlc3QgZm9yIHRoZSBkZXZpY2Ugc2Vzc2lvbiBm
cm9tIHRoZSBzZXNzaW9uIHNlcnZpY2UuCgoKCgMEAAESA3UIIgp4CgQEAAIAEgR4An0EGmog
UmVxdWlyZWQuIFRoZSBDb21wdXRlIEVuZ2luZSBwcm9qZWN0IHVuZGVyIHdoaWNoIHRoaXMg
ZGV2aWNlIHdpbGwgYmUKIGFsbG9jYXRlZC4gInByb2plY3RzL3twcm9qZWN0X2lkfSIKCgwK
BQQAAgAFEgN4AggKDAoFBAACAAESA3gJDwoMCgUEAAIAAxIDeBITCg0KBQQAAgAIEgR4FH0D
Cg8KCAQAAgAInAgAEgN5BCoKDwoHBAACAAifCBIEegR8BQo1CgQEAAIBEgSAAQJMGicgUmVx
dWlyZWQuIEEgZGV2aWNlIHNlc3Npb24gdG8gY3JlYXRlLgoKDQoFBAACAQYSBIABAg8KDQoF
BAACAQESBIABEB4KDQoFBAACAQMSBIABISIKDQoFBAACAQgSBIABI0sKEAoIBAACAQicCAAS
BIABJEoKZAoCBAESBoUBAJcBARpWIFJlcXVlc3QgYSBsaXN0IG9mIGRldmljZSBzZXNzaW9u
cyBpbiB0aGUgcHJvdmlkZWQgcGFyZW50IG1hdGNoaW5nIHRoZSBnaXZlbgogZmlsdGVyLgoK
CwoDBAEBEgSFAQghClsKBAQBAgASBocBAowBBBpLIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgcGFyZW50IHRvIHJlcXVlc3QsIGUuZy4gInByb2plY3RzL3twcm9qZWN0X2lkfSIKCg0K
BQQBAgAFEgSHAQIICg0KBQQBAgABEgSHAQkPCg0KBQQBAgADEgSHARITCg8KBQQBAgAIEgaH
ARSMAQMKEAoIBAECAAicCAASBIgBBCoKEQoHBAECAAifCBIGiQEEiwEFCkkKBAQBAgESBI8B
Aj8aOyBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIERldmljZVNlc3Npb25zIHRv
IHJldHVybi4KCg0KBQQBAgEFEgSPAQIHCg0KBQQBAgEBEgSPAQgRCg0KBQQBAgEDEgSPARQV
Cg0KBQQBAgEIEgSPARY+ChAKCAQBAgEInAgAEgSPARc9CjoKBAQBAgISBJIBAkEaLCBPcHRp
b25hbC4gQSBjb250aW51YXRpb24gdG9rZW4gZm9yIHBhZ2luZy4KCg0KBQQBAgIFEgSSAQII
Cg0KBQQBAgIBEgSSAQkTCg0KBQQBAgIDEgSSARYXCg0KBQQBAgIIEgSSARhAChAKCAQBAgII
nAgAEgSSARk/CnsKBAQBAgMSBJYBAj0abSBPcHRpb25hbC4gSWYgc3BlY2lmaWVkLCByZXNw
b25zZXMgd2lsbCBiZSBmaWx0ZXJlZCBieSB0aGUgZ2l2ZW4gZmlsdGVyLgogQWxsb3dlZCBm
aWVsZHMgYXJlOiBzZXNzaW9uX3N0YXRlLgoKDQoFBAECAwUSBJYBAggKDQoFBAECAwESBJYB
CQ8KDQoFBAECAwMSBJYBEhMKDQoFBAECAwgSBJYBFDwKEAoIBAECAwicCAASBJYBFTsKKgoC
BAISBpoBAKEBARocIEEgbGlzdCBvZiBkZXZpY2Ugc2Vzc2lvbnMuCgoLCgMEAgESBJoBCCIK
VgoEBAICABIEnAECLRpIIFRoZSBzZXNzaW9ucyBtYXRjaGluZyB0aGUgc3BlY2lmaWVkIGZp
bHRlciBpbiB0aGUgZ2l2ZW4gY2xvdWQgcHJvamVjdC4KCg0KBQQCAgAEEgScAQIKCg0KBQQC
AgAGEgScAQsYCg0KBQQCAgABEgScARkoCg0KBQQCAgADEgScASssCpABCgQEAgIBEgSgAQId
GoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRy
aWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBh
cmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQCAgEFEgSgAQIICg0KBQQCAgEBEgSgAQkY
Cg0KBQQCAgEDEgSgARscCjgKAgQDEgakAQCtAQEaKiBUaGUgcmVxdWVzdCBvYmplY3QgZm9y
IGEgRGV2aWNlIFNlc3Npb24uCgoLCgMEAwESBKQBCB8KcAoEBAMCABIGpwECrAEEGmAgUmVx
dWlyZWQuIE5hbWUgb2YgdGhlIERldmljZVNlc3Npb24sIGUuZy4KICJwcm9qZWN0cy97cHJv
amVjdF9pZH0vZGV2aWNlU2Vzc2lvbnMve3Nlc3Npb25faWR9IgoKDQoFBAMCAAUSBKcBAggK
DQoFBAMCAAESBKcBCQ0KDQoFBAMCAAMSBKcBEBEKDwoFBAMCAAgSBqcBEqwBAwoQCggEAwIA
CJwIABIEqAEEKgoRCgcEAwIACJ8IEgapAQSrAQUKQwoCBAQSBrABALkBARo1IFRoZSByZXF1
ZXN0IG9iamVjdCBmb3IgY2FuY2VsbGluZyBhIERldmljZSBTZXNzaW9uLgoKCwoDBAQBEgSw
AQgiCnAKBAQEAgASBrMBArgBBBpgIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBEZXZpY2VTZXNz
aW9uLCBlLmcuCiAicHJvamVjdHMve3Byb2plY3RfaWR9L2RldmljZVNlc3Npb25zL3tzZXNz
aW9uX2lkfSIKCg0KBQQEAgAFEgSzAQIICg0KBQQEAgABEgSzAQkNCg0KBQQEAgADEgSzARAR
Cg8KBQQEAgAIEgazARK4AQMKEAoIBAQCAAicCAASBLQBBCoKEQoHBAQCAAifCBIGtQEEtwEF
CkMKAgQFEga8AQDFAQEaNSBUaGUgcmVxdWVzdCBvYmplY3QgZm9yIHRoZSBVcGRhdGVEZXZp
Y2VTZXNzaW9uIFJQQy4KCgsKAwQFARIEvAEIIgq1AQoEBAUCABIEwAECTBqmASBSZXF1aXJl
ZC4gRGV2aWNlU2Vzc2lvbiB0byB1cGRhdGUuCiBUaGUgZGV2aWNlIHNlc3Npb24ncyBgbmFt
ZWAgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUgc2Vzc2lvbiB0byB1cGRhdGUKICJw
cm9qZWN0cy97cHJvamVjdF9pZH0vZGV2aWNlU2Vzc2lvbnMve3Nlc3Npb25faWR9IgoKDQoF
BAUCAAYSBMABAg8KDQoFBAUCAAESBMABEB4KDQoFBAUCAAMSBMABISIKDQoFBAUCAAgSBMAB
I0sKEAoIBAUCAAicCAASBMABJEoKOQoEBAUCARIGwwECxAEvGikgUmVxdWlyZWQuIFRoZSBs
aXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuCgoNCgUEBQIBBhIEwwECGwoNCgUEBQIBARIEwwEc
JwoNCgUEBQIBAxIEwwEqKwoNCgUEBQIBCBIExAEGLgoQCggEBQIBCJwIABIExAEHLQpXCgIE
BhIGyAEArAIBGkkgUHJvdG9idWYgbWVzc2FnZSBkZXNjcmliaW5nIHRoZSBkZXZpY2UgbWVz
c2FnZSwgdXNlZCBmcm9tIHNldmVyYWwgUlBDcy4KCgsKAwQGARIEyAEIFQoNCgMEBgcSBskB
AswBBAoPCgUEBgedCBIGyQECzAEECjwKBAQGBAASBs8BAvABAxosIFRoZSBzdGF0ZSB0aGF0
IHRoZSBkZXZpY2Ugc2Vzc2lvbiByZXNpZGVzLgoKDQoFBAYEAAESBM8BBxMKNgoGBAYEAAIA
EgTRAQQiGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoPCgcEBgQA
AgABEgTRAQQdCg8KBwQGBAACAAISBNEBICEKiAEKBgQGBAACARIE1QEEEhp4IEluaXRpYWwg
c3RhdGUgb2YgYSBzZXNzaW9uIHJlcXVlc3QuIFRoZSBzZXNzaW9uIGlzIGJlaW5nIHZhbGlk
YXRlZCBmb3IKIGNvcnJlY3RuZXNzIGFuZCBhIGRldmljZSBpcyBub3QgeWV0IHJlcXVlc3Rl
ZC4KCg8KBwQGBAACAQESBNUBBA0KDwoHBAYEAAIBAhIE1QEQEQpSCgYEBgQAAgISBNgBBBAa
QiBUaGUgc2Vzc2lvbiBoYXMgYmVlbiB2YWxpZGF0ZWQgYW5kIGlzIGluIHRoZSBxdWV1ZSBm
b3IgYSBkZXZpY2UuCgoPCgcEBgQAAgIBEgTYAQQLCg8KBwQGBAACAgISBNgBDg8KWAoGBAYE
AAIDEgTcAQQPGkggVGhlIHNlc3Npb24gaGFzIGJlZW4gZ3JhbnRlZCBhbmQgdGhlIGRldmlj
ZSBpcyBhY2NlcHRpbmcKIGNvbm5lY3Rpb25zLgoKDwoHBAYEAAIDARIE3AEECgoPCgcEBgQA
AgMCEgTcAQ0OCnQKBgQGBAACBBIE4AEEEBpkIFRoZSBzZXNzaW9uIGR1cmF0aW9uIGV4Y2Vl
ZGVkIHRoZSBkZXZpY2XigJlzIHJlc2VydmF0aW9uIHRpbWUgcGVyaW9kIGFuZAogdGltZWQg
b3V0IGF1dG9tYXRpY2FsbHkuCgoPCgcEBgQAAgQBEgTgAQQLCg8KBwQGBAACBAISBOABDg8K
vAEKBgQGBAACBRIE5QEEERqrASBUaGUgdXNlciBpcyBmaW5pc2hlZCB3aXRoIHRoZSBzZXNz
aW9uIGFuZCBpdCB3YXMgY2FuY2VsZWQgYnkgdGhlIHVzZXIKIHdoaWxlIHRoZSByZXF1ZXN0
IHdhcyBzdGlsbCBnZXR0aW5nIGFsbG9jYXRlZCBvciBhZnRlciBhbGxvY2F0aW9uIGFuZAog
ZHVyaW5nIGRldmljZSB1c2FnZSBwZXJpb2QuCgoPCgcEBgQAAgUBEgTlAQQMCg8KBwQGBAAC
BQISBOUBDxAK7wEKBgQGBAACBhIE6wEEFBreASBVbmFibGUgdG8gY29tcGxldGUgdGhlIHNl
c3Npb24gYmVjYXVzZSB0aGUgZGV2aWNlIHdhcyB1bmF2YWlsYWJsZSBhbmQKIGl0IGZhaWxl
ZCB0byBhbGxvY2F0ZSB0aHJvdWdoIHRoZSBzY2hlZHVsZXIuIEZvciBleGFtcGxlLCBhIGRl
dmljZSBub3QKIGluIHRoZSBjYXRhbG9nIHdhcyByZXF1ZXN0ZWQgb3IgdGhlIHJlcXVlc3Qg
ZXhwaXJlZCBpbiB0aGUgYWxsb2NhdGlvbgogcXVldWUuCgoPCgcEBgQAAgYBEgTrAQQPCg8K
BwQGBAACBgISBOsBEhMKbAoGBAYEAAIHEgTvAQQOGlwgVW5hYmxlIHRvIGNvbXBsZXRlIHRo
ZSBzZXNzaW9uIGZvciBhbiBpbnRlcm5hbCByZWFzb24sIHN1Y2ggYXMgYW4KIGluZnJhc3Ry
dWN0dXJlIGZhaWx1cmUuCgoPCgcEBgQAAgcBEgTvAQQJCg8KBwQGBAACBwISBO8BDA0KhQEK
BAQGAwASBvQBAv8BAxp1IEEgbWVzc2FnZSBlbmNhcHN1bGF0aW5nIGEgc2VyaWVzIG9mIFNl
c3Npb24gc3RhdGVzIGFuZCB0aGUgdGltZSB0aGF0IHRoZQogRGV2aWNlU2Vzc2lvbiBmaXJz
dCBlbnRlcmVkIHRob3NlIHN0YXRlcy4KCg0KBQQGAwABEgT0AQobCkYKBgQGAwACABIE9gEE
Txo2IE91dHB1dCBvbmx5LiBUaGUgc2Vzc2lvbl9zdGF0ZSB0cmFja2VkIGJ5IHRoaXMgZXZl
bnQKCg8KBwQGAwACAAYSBPYBBBAKDwoHBAYDAAIAARIE9gERHgoPCgcEBgMAAgADEgT2ASEi
Cg8KBwQGAwACAAgSBPYBI04KEgoKBAYDAAIACJwIABIE9gEkTQpfCgYEBgMAAgESBvoBBPsB
NBpNIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGF0IHRoZSBzZXNzaW9uX3N0YXRlIGZpcnN0
IGVuY291bnRlcmVkIHRoYXQKIHN0YXRlLgoKDwoHBAYDAAIBBhIE+gEEHQoPCgcEBgMAAgEB
EgT6AR4oCg8KBwQGAwACAQMSBPoBKywKDwoHBAYDAAIBCBIE+wEIMwoSCgoEBgMAAgEInAgA
EgT7AQkyCk0KBgQGAwACAhIE/gEESRo9IE91dHB1dCBvbmx5LiBBIGh1bWFuLXJlYWRhYmxl
IG1lc3NhZ2UgdG8gZXhwbGFpbiB0aGUgc3RhdGUuCgoPCgcEBgMAAgIFEgT+AQQKCg8KBwQG
AwACAgESBP4BCxgKDwoHBAYDAAICAxIE/gEbHAoPCgcEBgMAAgIIEgT+AR1IChIKCgQGAwAC
AgicCAASBP4BHkcKbgoEBAYCABIEgwICOxpgIE9wdGlvbmFsLiBOYW1lIG9mIHRoZSBEZXZp
Y2VTZXNzaW9uLCBlLmcuCiAicHJvamVjdHMve3Byb2plY3RfaWR9L2RldmljZVNlc3Npb25z
L3tzZXNzaW9uX2lkfSIKCg0KBQQGAgAFEgSDAgIICg0KBQQGAgABEgSDAgkNCg0KBQQGAgAD
EgSDAhARCg0KBQQGAgAIEgSDAhI6ChAKCAQGAgAInAgAEgSDAhM5ClYKBAQGAgESBIYCAkYa
SCBPdXRwdXQgb25seS4gVGhlIHRpdGxlIG9mIHRoZSBEZXZpY2VTZXNzaW9uIHRvIGJlIHBy
ZXNlbnRlZCBpbiB0aGUgVUkuCgoNCgUEBgIBBRIEhgICCAoNCgUEBgIBARIEhgIJFQoNCgUE
BgIBAxIEhgIYGQoNCgUEBgIBCBIEhgIaRQoQCggEBgIBCJwIABIEhgIbRApACgQEBgICEgSJ
AgJFGjIgT3V0cHV0IG9ubHkuIEN1cnJlbnQgc3RhdGUgb2YgdGhlIERldmljZVNlc3Npb24u
CgoNCgUEBgICBhIEiQICDgoNCgUEBgICARIEiQIPFAoNCgUEBgICAxIEiQIXGAoNCgUEBgIC
CBIEiQIZRAoQCggEBgICCJwIABIEiQIaQwqCAQoEBAYCAxIGjQICjgIyGnIgT3V0cHV0IG9u
bHkuIFRoZSBoaXN0b3JpY2FsIHN0YXRlIHRyYW5zaXRpb25zIG9mIHRoZSBzZXNzaW9uX3N0
YXRlIG1lc3NhZ2UKIGluY2x1ZGluZyB0aGUgY3VycmVudCBzZXNzaW9uIHN0YXRlLgoKDQoF
BAYCAwQSBI0CAgoKDQoFBAYCAwYSBI0CCxwKDQoFBAYCAwESBI0CHSwKDQoFBAYCAwMSBI0C
LzEKDQoFBAYCAwgSBI4CBjEKEAoIBAYCAwicCAASBI4CBzAKDgoEBAYIABIGkAICmwIDCg0K
BQQGCAABEgSQAggSCrUBCgQEBgIEEgSUAgRPGqYBIE9wdGlvbmFsLiBUaGUgYW1vdW50IG9m
IHRpbWUgdGhhdCBhIGRldmljZSB3aWxsIGJlIGluaXRpYWxseSBhbGxvY2F0ZWQKIGZvci4g
VGhpcyBjYW4gZXZlbnR1YWxseSBiZSBleHRlbmRlZCB3aXRoIHRoZSBVcGRhdGVEZXZpY2VT
ZXNzaW9uIFJQQy4KIERlZmF1bHQ6IDE1IG1pbnV0ZXMuCgoNCgUEBgIEBhIElAIEHAoNCgUE
BgIEARIElAIdIAoNCgUEBgIEAxIElAIjJQoNCgUEBgIECBIElAImTgoQCggEBgIECJwIABIE
lAInTQqmAQoEBAYCBRIGmQIEmgIxGpUBIE9wdGlvbmFsLiBJZiB0aGUgZGV2aWNlIGlzIHN0
aWxsIGluIHVzZSBhdCB0aGlzIHRpbWUsIGFueSBjb25uZWN0aW9ucwogd2lsbCBiZSBlbmRl
ZCBhbmQgdGhlIFNlc3Npb25TdGF0ZSB3aWxsIHRyYW5zaXRpb24gZnJvbSBBQ1RJVkUgdG8K
IEZJTklTSEVELgoKDQoFBAYCBQYSBJkCBB0KDQoFBAYCBQESBJkCHikKDQoFBAYCBQMSBJkC
LC0KDQoFBAYCBQgSBJoCCDAKEAoIBAYCBQicCAASBJoCCS8KlwEKBAQGAgYSBp8CAqACMhqG
ASBPdXRwdXQgb25seS4gVGhlIGludGVydmFsIG9mIHRpbWUgdGhhdCB0aGlzIGRldmljZSBt
dXN0IGJlIGludGVyYWN0ZWQgd2l0aAogYmVmb3JlIGl0IHRyYW5zaXRpb25zIGZyb20gQUNU
SVZFIHRvIFRJTUVPVVRfSU5BQ1RJVklUWS4KCg0KBQQGAgYGEgSfAgIaCg0KBQQGAgYBEgSf
AhstCg0KBQQGAgYDEgSfAjAxCg0KBQQGAgYIEgSgAgYxChAKCAQGAgYInAgAEgSgAgcwCkUK
BAQGAgcSBqMCAqQCMho1IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGF0IHRoZSBTZXNzaW9u
IHdhcyBjcmVhdGVkLgoKDQoFBAYCBwYSBKMCAhsKDQoFBAYCBwESBKMCHCcKDQoFBAYCBwMS
BKMCKisKDQoFBAYCBwgSBKQCBjEKEAoIBAYCBwicCAASBKQCBzAKUgoEBAYCCBIGpwICqAIy
GkIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgdGhhdCB0aGUgc2Vzc2lvbiBmaXJzdCBi
ZWNhbWUgQUNUSVZFLgoKDQoFBAYCCAYSBKcCAhsKDQoFBAYCCAESBKcCHC0KDQoFBAYCCAMS
BKcCMDEKDQoFBAYCCAgSBKgCBjEKEAoIBAYCCAicCAASBKgCBzAKLgoEBAYCCRIEqwICTRog
IFJlcXVpcmVkLiBUaGUgcmVxdWVzdGVkIGRldmljZQoKDQoFBAYCCQYSBKsCAg8KDQoFBAYC
CQESBKsCEB4KDQoFBAYCCQMSBKsCISMKDQoFBAYCCQgSBKsCJEwKEAoIBAYCCQicCAASBKsC
JUtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest ===
    # Fields for CreateDeviceSessionRequest
    # Field: parent Type: 9 ()
    # Field: device_session Type: 11 (.google.devtools.testing.v1.DeviceSession)

# === Message: Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsRequest ===
    # Fields for ListDeviceSessionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsResponse ===
    # Fields for ListDeviceSessionsResponse
    # Field: device_sessions Type: 11 (.google.devtools.testing.v1.DeviceSession)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Testing::V1::DirectAccessService::GetDeviceSessionRequest ===
    # Fields for GetDeviceSessionRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Testing::V1::DirectAccessService::CancelDeviceSessionRequest ===
    # Fields for CancelDeviceSessionRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Testing::V1::DirectAccessService::UpdateDeviceSessionRequest ===
    # Fields for UpdateDeviceSessionRequest
    # Field: device_session Type: 11 (.google.devtools.testing.v1.DeviceSession)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Devtools::Testing::V1::DirectAccessService::DeviceSession ===
    # Fields for DeviceSession
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: state Type: 14 (.google.devtools.testing.v1.DeviceSession.SessionState)
    # Field: state_histories Type: 11 (.google.devtools.testing.v1.DeviceSession.SessionStateEvent)
    # Field: ttl Type: 11 (.google.protobuf.Duration)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: inactivity_timeout Type: 11 (.google.protobuf.Duration)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: active_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: android_device Type: 11 (.google.devtools.testing.v1.AndroidDevice)

# Enum: DeviceSession::SessionState
our $DeviceSession_SESSION_STATE_UNSPECIFIED = 0;
our $DeviceSession_REQUESTED = 1;
our $DeviceSession_PENDING = 2;
our $DeviceSession_ACTIVE = 3;
our $DeviceSession_EXPIRED = 4;
our $DeviceSession_FINISHED = 5;
our $DeviceSession_UNAVAILABLE = 6;
our $DeviceSession_ERROR = 7;

# === Service Client: Google::Devtools::Testing::V1::DirectAccessService::DirectAccessServiceClient ===
package Google::Devtools::Testing::V1::DirectAccessService::DirectAccessServiceClient;

=pod

=head2 Service Client: Google::Devtools::Testing::V1::DirectAccessService::DirectAccessServiceClient

Client stub representing the remote C<DirectAccessService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

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
        ? Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.testing.v1.DirectAccessService',
        method         => 'CreateDeviceSession',
        request        => $req,
        response_class => 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession',
    });
}

sub list_device_sessions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.testing.v1.DirectAccessService',
        method         => 'ListDeviceSessions',
        request        => $req,
        response_class => 'Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsResponse',
    });
}

sub get_device_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Testing::V1::DirectAccessService::GetDeviceSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.testing.v1.DirectAccessService',
        method         => 'GetDeviceSession',
        request        => $req,
        response_class => 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession',
    });
}

sub cancel_device_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Testing::V1::DirectAccessService::CancelDeviceSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.testing.v1.DirectAccessService',
        method         => 'CancelDeviceSession',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_device_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Testing::V1::DirectAccessService::UpdateDeviceSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.testing.v1.DirectAccessService',
        method         => 'UpdateDeviceSession',
        request        => $req,
        response_class => 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession',
    });
}

sub adb_connect {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Testing::V1::AdbService::AdbMessage->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.testing.v1.DirectAccessService',
        method         => 'AdbConnect',
        request        => $req,
        response_class => 'Google::Devtools::Testing::V1::AdbService::DeviceMessage',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Testing::V1::DirectAccessService - Compiled Protocol Buffers messages for google/devtools/testing/v1/direct_access_service.proto

=head1 SYNOPSIS

    use Google::Devtools::Testing::V1::DirectAccessService;

    my $msg = Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest->new({
        parent => $parent,
        device_session => $device_session,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/testing/v1/direct_access_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest

A Request for the device session from the session service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The Compute Engine project under which this device will be
allocated. "projects/{project_id}"

=item * C<< $msg->device_session() >> / C<< $msg->device_session($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::DirectAccessService::DeviceSession>)

Required. A device session to create.

=back

=head2 Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsRequest

Request a list of device sessions in the provided parent matching the given
filter.

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

=head2 Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsResponse

A list of device sessions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->device_sessions() >> / C<< $msg->device_sessions($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::DirectAccessService::DeviceSession>)

The sessions matching the specified filter in the given cloud project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Devtools::Testing::V1::DirectAccessService::GetDeviceSessionRequest

The request object for a Device Session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the DeviceSession, e.g.
"projects/{project_id}/deviceSessions/{session_id}"

=back

=head2 Google::Devtools::Testing::V1::DirectAccessService::CancelDeviceSessionRequest

The request object for cancelling a Device Session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the DeviceSession, e.g.
"projects/{project_id}/deviceSessions/{session_id}"

=back

=head2 Google::Devtools::Testing::V1::DirectAccessService::UpdateDeviceSessionRequest

The request object for the UpdateDeviceSession RPC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->device_session() >> / C<< $msg->device_session($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::DirectAccessService::DeviceSession>)

Required. DeviceSession to update.
The device session's `name` field is used to identify the session to update
"projects/{project_id}/deviceSessions/{session_id}"

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The list of fields to update.

=back

=head2 Google::Devtools::Testing::V1::DirectAccessService::DeviceSession

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

Type: C<Enum> (L<Google::Devtools::Testing::V1::DeviceSession::SessionState>)

Output only. Current state of the DeviceSession.

=item * C<< $msg->state_histories() >> / C<< $msg->state_histories($value) >>

Type: C<Message> (L<Google::Devtools::Testing::V1::DirectAccessService::DeviceSession::SessionStateEvent>)

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

Type: C<Message> (L<Google::Devtools::Testing::V1::TestExecution::AndroidDevice>)

Required. The requested device

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

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Testing::V1::DirectAccessService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
