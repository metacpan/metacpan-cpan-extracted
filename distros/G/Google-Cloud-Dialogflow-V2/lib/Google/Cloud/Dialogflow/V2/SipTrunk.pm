package Google::Cloud::Dialogflow::V2::SipTrunk;

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
Cipnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9zaXBfdHJ1bmsucHJvdG8SGmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnBy
b3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVs
ZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqMBChVDcmVh
dGVTaXBUcnVua1JlcXVlc3QSQgoGcGFyZW50GAEgASgJQirgQQL6QSQSImRpYWxvZ2Zsb3cu
Z29vZ2xlYXBpcy5jb20vU2lwVHJ1bmtSBnBhcmVudBJGCglzaXBfdHJ1bmsYAiABKAsyJC5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TaXBUcnVua0ID4EECUghzaXBUcnVuayJXChVE
ZWxldGVTaXBUcnVua1JlcXVlc3QSPgoEbmFtZRgBIAEoCUIq4EEC+kEkCiJkaWFsb2dmbG93
Lmdvb2dsZWFwaXMuY29tL1NpcFRydW5rUgRuYW1lIqABChRMaXN0U2lwVHJ1bmtzUmVxdWVz
dBJCCgZwYXJlbnQYASABKAlCKuBBAvpBJBIiZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9T
aXBUcnVua1IGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKEAQoVTGlzdFNpcFRydW5rc1Jlc3Bv
bnNlEkMKCnNpcF90cnVua3MYASADKAsyJC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5T
aXBUcnVua1IJc2lwVHJ1bmtzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiJUChJHZXRTaXBUcnVua1JlcXVlc3QSPgoEbmFtZRgBIAEoCUIq4EEC+kEkCiJkaWFs
b2dmbG93Lmdvb2dsZWFwaXMuY29tL1NpcFRydW5rUgRuYW1lIqEBChVVcGRhdGVTaXBUcnVu
a1JlcXVlc3QSRgoJc2lwX3RydW5rGAEgASgLMiQuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djIuU2lwVHJ1bmtCA+BBAlIIc2lwVHJ1bmsSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29n
bGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2si2AQKCFNpcFRydW5rEhcK
BG5hbWUYASABKAlCA+BBCFIEbmFtZRIwChFleHBlY3RlZF9ob3N0bmFtZRgCIAMoCUID4EEC
UhBleHBlY3RlZEhvc3RuYW1lEk0KC2Nvbm5lY3Rpb25zGAMgAygLMiYuZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjIuQ29ubmVjdGlvbkID4EEDUgtjb25uZWN0aW9ucxImCgxkaXNwbGF5
X25hbWUYBCABKAlCA+BBAVILZGlzcGxheU5hbWUSUwoOcGVlcl9ob3N0bmFtZXMYCCADKAsy
Jy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TaXBIb3N0bmFtZUID4EECUg1wZWVySG9z
dG5hbWVzEm8KFWdvb2dsZV9yb290X2NlcnRfZmlsZRgJIAEoDjI3Lmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyLlNpcFRydW5rLkdvb2dsZVJvb3RDZXJ0RmlsZUID4EEBUhJnb29nbGVS
b290Q2VydEZpbGUiSAoSR29vZ2xlUm9vdENlcnRGaWxlEhkKFUNFUlRfRklMRV9VTlNQRUNJ
RklFRBAAEhcKE0VYVEVSTkFMX1BSSVZBVEVfQ0EQBTp66kF3CiJkaWFsb2dmbG93Lmdvb2ds
ZWFwaXMuY29tL1NpcFRydW5rEjxwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vc2lwVHJ1bmtzL3tzaXB0cnVua30qCXNpcFRydW5rczIIc2lwVHJ1bmsiwAcKCkNv
bm5lY3Rpb24SKAoNY29ubmVjdGlvbl9pZBgBIAEoCUID4EEDUgxjb25uZWN0aW9uSWQSRwoF
c3RhdGUYAiABKA4yLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db25uZWN0aW9uLlN0
YXRlQgPgQQNSBXN0YXRlEkUKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDSABSCnVwZGF0ZVRpbWWIAQESYgoNZXJyb3JfZGV0YWlscxgEIAEo
CzIzLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbm5lY3Rpb24uRXJyb3JEZXRhaWxz
QgPgQQNIAVIMZXJyb3JEZXRhaWxziAEBGtABCgxFcnJvckRldGFpbHMSbgoRY2VydGlmaWNh
dGVfc3RhdGUYASABKA4yNy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db25uZWN0aW9u
LkNlcnRpZmljYXRlU3RhdGVCA+BBA0gAUhBjZXJ0aWZpY2F0ZVN0YXRliAEBEigKDWVycm9y
X21lc3NhZ2UYAiABKAlIAVIMZXJyb3JNZXNzYWdliAEBQhQKEl9jZXJ0aWZpY2F0ZV9zdGF0
ZUIQCg5fZXJyb3JfbWVzc2FnZSJpCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg0K
CUNPTk5FQ1RFRBABEhAKDERJU0NPTk5FQ1RFRBACEhkKFUFVVEhFTlRJQ0FUSU9OX0ZBSUxF
RBADEg0KCUtFRVBBTElWRRAEIrMCChBDZXJ0aWZpY2F0ZVN0YXRlEiEKHUNFUlRJRklDQVRF
X1NUQVRFX1VOU1BFQ0lGSUVEEAASFQoRQ0VSVElGSUNBVEVfVkFMSUQQARIXChNDRVJUSUZJ
Q0FURV9JTlZBTElEEAISFwoTQ0VSVElGSUNBVEVfRVhQSVJFRBADEiIKHkNFUlRJRklDQVRF
X0hPU1ROQU1FX05PVF9GT1VORBAEEh8KG0NFUlRJRklDQVRFX1VOQVVUSEVOVElDQVRFRBAF
EiUKIUNFUlRJRklDQVRFX1RSVVNUX1NUT1JFX05PVF9GT1VORBAGEicKI0NFUlRJRklDQVRF
X0hPU1ROQU1FX0lOVkFMSURfRk9STUFUEAcSHgoaQ0VSVElGSUNBVEVfUVVPVEFfRVhDRUVE
RUQQCEIOCgxfdXBkYXRlX3RpbWVCEAoOX2Vycm9yX2RldGFpbHMiowgKC1NpcEhvc3RuYW1l
EigKDXBlZXJfaG9zdG5hbWUYASABKAlCA+BBAlIMcGVlckhvc3RuYW1lEi0KEGVuYWJsZWRf
c2lwX3BpbmcYAiABKAhCA+BBA1IOZW5hYmxlZFNpcFBpbmcSQwoNcGluZ19pbnRlcnZhbBgD
IAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbkID4EEDUgxwaW5nSW50ZXJ2YWwSMwoT
cGVlcl9zb2NrZXRfYWRkcmVzcxgEIAEoCUID4EEDUhFwZWVyU29ja2V0QWRkcmVzcxJSCg1w
cm9iZV9kZXRhaWxzGAUgASgLMiguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuUHJvYmVE
ZXRhaWxzQgPgQQNSDHByb2JlRGV0YWlscxJnChBjb25uZWN0aW9uX3N0YXRlGAYgASgOMjcu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuU2lwSG9zdG5hbWUuQ29ubmVjdGlvblN0YXRl
QgPgQQNSD2Nvbm5lY3Rpb25TdGF0ZRJmCg1lcnJvcl9kZXRhaWxzGAcgASgLMjwuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIuU2lwSG9zdG5hbWUuSG9zdG5hbWVFcnJvckRldGFpbHNC
A+BBA1IMZXJyb3JEZXRhaWxzGrQBChRIb3N0bmFtZUVycm9yRGV0YWlscxJyChFjZXJ0aWZp
Y2F0ZV9zdGF0ZRgBIAEoDjJALmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlNpcEhvc3Ru
YW1lLkhvc3RuYW1lQ2VydGlmaWNhdGVTdGF0ZUID4EEDUhBjZXJ0aWZpY2F0ZVN0YXRlEigK
DWVycm9yX21lc3NhZ2UYAiABKAlCA+BBA1IMZXJyb3JNZXNzYWdlIn4KD0Nvbm5lY3Rpb25T
dGF0ZRIgChxDT05ORUNUSU9OX1NUQVRFX1VOU1BFQ0lGSUVEEAASDQoJQ09OTkVDVEVEEAES
EAoMRElTQ09OTkVDVEVEEAISGQoVQVVUSEVOVElDQVRJT05fRkFJTEVEEAMSDQoJS0VFUEFM
SVZFEAQi5AEKGEhvc3RuYW1lQ2VydGlmaWNhdGVTdGF0ZRIqCiZIT1NUTkFNRV9DRVJUSUZJ
Q0FURV9TVEFURV9VTlNQRUNJRklFRBAAEgkKBVZBTElEEAESCwoHSU5WQUxJRBACEgsKB0VY
UElSRUQQAxIWChJIT1NUTkFNRV9OT1RfRk9VTkQQBBITCg9VTkFVVEhFTlRJQ0FURUQQBRIZ
ChVUUlVTVF9TVE9SRV9OT1RfRk9VTkQQBhIbChdIT1NUTkFNRV9JTlZBTElEX0ZPUk1BVBAH
EhIKDlFVT1RBX0VYQ0VFREVEEAgi0wIKDFByb2JlRGV0YWlscxJHCg9vcHRpb25zX2xhdGVu
Y3kYASABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBA1IOb3B0aW9uc0xhdGVu
Y3kSXAoMcHJvYmVfc3RhdHVzGAIgASgOMjQuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIu
UHJvYmVEZXRhaWxzLlByb2JlU3RhdHVzQgPgQQNSC3Byb2JlU3RhdHVzEjwKCWluaXRfdGlt
ZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IIaW5pdFRpbWUiXgoL
UHJvYmVTdGF0dXMSHAoYUFJPQkVfU1RBVFVTX1VOU1BFQ0lGSUVEEAASGAoUUFJPQkVfU1RB
VFVTX1NVQ0NFU1MQARIXChNQUk9CRV9TVEFUVVNfRkFJTEVEEAIyjQgKCVNpcFRydW5rcxK+
AQoOQ3JlYXRlU2lwVHJ1bmsSMS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5DcmVhdGVT
aXBUcnVua1JlcXVlc3QaJC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TaXBUcnVuayJT
gtPkkwI6Ii0vdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9zaXBUcnVua3M6
CXNpcF90cnVua9pBEHBhcmVudCxzaXBfdHJ1bmsSmQEKDkRlbGV0ZVNpcFRydW5rEjEuZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRGVsZXRlU2lwVHJ1bmtSZXF1ZXN0GhYuZ29vZ2xl
LnByb3RvYnVmLkVtcHR5IjyC0+STAi8qLS92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3NpcFRydW5rcy8qfdpBBG5hbWUStAEKDUxpc3RTaXBUcnVua3MSMC5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52Mi5MaXN0U2lwVHJ1bmtzUmVxdWVzdBoxLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyLkxpc3RTaXBUcnVua3NSZXNwb25zZSI+gtPkkwIvEi0vdjIve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9zaXBUcnVua3PaQQZwYXJlbnQSoQEKC0dldFNp
cFRydW5rEi4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuR2V0U2lwVHJ1bmtSZXF1ZXN0
GiQuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuU2lwVHJ1bmsiPILT5JMCLxItL3YyL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovc2lwVHJ1bmtzLyp92kEEbmFtZRLNAQoOVXBk
YXRlU2lwVHJ1bmsSMS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5VcGRhdGVTaXBUcnVu
a1JlcXVlc3QaJC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TaXBUcnVuayJigtPkkwJE
MjcvdjIve3NpcF90cnVuay5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovc2lwVHJ1bmtz
Lyp9OglzaXBfdHJ1bmvaQRVzaXBfdHJ1bmssdXBkYXRlX21hc2saeMpBGWRpYWxvZ2Zsb3cu
Z29vZ2xlYXBpcy5jb23SQVlodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3Vk
LXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlhbG9nZmxvd0KT
AQoeY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyQg1TaXBUcnVua1Byb3RvUAFaPmNs
b3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2Mi9kaWFsb2dmbG93cGI7ZGlhbG9n
Zmxvd3BiogICREaqAhpHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkqgYgoHEgUOAJIDAQq8
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
CgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACgKCQoCAwUSAxcA
JQoJCgIDBhIDGAAqCgkKAgMHEgMZACkKCAoBCBIDGwA3CgkKAgglEgMbADcKCAoBCBIDHABV
CgkKAggLEgMcAFUKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAuCgkKAggIEgMeAC4K
CAoBCBIDHwA3CgkKAggBEgMfADcKCAoBCBIDIAAgCgkKAggkEgMgACAKVAoCBgASBCMAUgEa
SCBTZXJ2aWNlIGZvciBtYW5hZ2luZyBbU2lwVHJ1bmtzXVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52Mi5TaXBUcnVua10uCgoKCgMGAAESAyMIEQoKCgMGAAMSAyQCQQoMCgUGAAOZCBID
JAJBCgsKAwYAAxIEJQInMwoNCgUGAAOaCBIEJQInMwo8CgQGAAIAEgQqAjADGi4gQ3JlYXRl
cyBhIFNpcFRydW5rIGZvciBhIHNwZWNpZmllZCBsb2NhdGlvbi4KCgwKBQYAAgABEgMqBhQK
DAoFBgACAAISAyoVKgoMCgUGAAIAAxIDKjU9Cg0KBQYAAgAEEgQrBC4GChEKCQYAAgAEsMq8
IhIEKwQuBgoMCgUGAAIABBIDLwQ+Cg8KCAYAAgAEmwgAEgMvBD4KLQoEBgACARIEMwI4Axof
IERlbGV0ZXMgYSBzcGVjaWZpZWQgU2lwVHJ1bmsuCgoMCgUGAAIBARIDMwYUCgwKBQYAAgEC
EgMzFSoKDAoFBgACAQMSAzM1SgoNCgUGAAIBBBIENAQ2BgoRCgkGAAIBBLDKvCISBDQENgYK
DAoFBgACAQQSAzcEMgoPCggGAAIBBJsIABIDNwQyCkYKBAYAAgISBDsCQAMaOCBSZXR1cm5z
IGEgbGlzdCBvZiBTaXBUcnVua3MgaW4gdGhlIHNwZWNpZmllZCBsb2NhdGlvbi4KCgwKBQYA
AgIBEgM7BhMKDAoFBgACAgISAzsUKAoMCgUGAAICAxIDOzNICg0KBQYAAgIEEgQ8BD4GChEK
CQYAAgIEsMq8IhIEPAQ+BgoMCgUGAAICBBIDPwQ0Cg8KCAYAAgIEmwgAEgM/BDQKMQoEBgAC
AxIEQwJIAxojIFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkIFNpcFRydW5rLgoKDAoFBgACAwES
A0MGEQoMCgUGAAIDAhIDQxIkCgwKBQYAAgMDEgNDLzcKDQoFBgACAwQSBEQERgYKEQoJBgAC
AwSwyrwiEgREBEYGCgwKBQYAAgMEEgNHBDIKDwoIBgACAwSbCAASA0cEMgovCgQGAAIEEgRL
AlEDGiEgVXBkYXRlcyB0aGUgc3BlY2lmaWVkIFNpcFRydW5rLgoKDAoFBgACBAESA0sGFAoM
CgUGAAIEAhIDSxUqCgwKBQYAAgQDEgNLNT0KDQoFBgACBAQSBEwETwYKEQoJBgACBASwyrwi
EgRMBE8GCgwKBQYAAgQEEgNQBEMKDwoIBgACBASbCAASA1AEQwp3CgIEABIEVgBiARprIFRo
ZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2lwVHJ1bmtzLkNyZWF0ZVNpcFRydW5rXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TaXBUcnVua3MuQ3JlYXRlU2lwVHJ1bmtdLgoKCgoD
BAABEgNWCB0KewoEBAACABIEWQJeBBptIFJlcXVpcmVkLiBUaGUgbG9jYXRpb24gdG8gY3Jl
YXRlIGEgU0lQIHRydW5rIGZvci4KIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9s
b2NhdGlvbnMvPExvY2F0aW9uIElEPmAuCgoMCgUEAAIABRIDWQIICgwKBQQAAgABEgNZCQ8K
DAoFBAACAAMSA1kSEwoNCgUEAAIACBIEWRReAwoPCggEAAIACJwIABIDWgQqCg8KBwQAAgAI
nwgSBFsEXQUKMQoEBAACARIDYQJCGiQgUmVxdWlyZWQuIFRoZSBTSVAgdHJ1bmsgdG8gY3Jl
YXRlLgoKDAoFBAACAQYSA2ECCgoMCgUEAAIBARIDYQsUCgwKBQQAAgEDEgNhFxgKDAoFBAAC
AQgSA2EZQQoPCggEAAIBCJwIABIDYRpACncKAgQBEgRmAHABGmsgVGhlIHJlcXVlc3QgbWVz
c2FnZSBmb3IKIFtTaXBUcnVua3MuRGVsZXRlU2lwVHJ1bmtdW2dvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLlNpcFRydW5rcy5EZWxldGVTaXBUcnVua10uCgoKCgMEAQESA2YIHQqSAQoE
BAECABIEagJvBBqDASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIFNJUCB0cnVuayB0byBk
ZWxldGUuCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2Nh
dGlvbiBJRD4vc2lwVHJ1bmtzLzxTaXBUcnVuawogSUQ+YC4KCgwKBQQBAgAFEgNqAggKDAoF
BAECAAESA2oJDQoMCgUEAQIAAxIDahARCg0KBQQBAgAIEgRqEm8DCg8KCAQBAgAInAgAEgNr
BCoKDwoHBAECAAifCBIEbARuBQp2CgIEAhIFdACEAQEaaSBUaGUgcmVxdWVzdCBtZXNzYWdl
IGZvcgogW1NpcFRydW5rcy5MaXN0U2lwVHJ1bmtzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5TaXBUcnVua3MuTGlzdFNpcFRydW5rc10uCgoKCgMEAgESA3QIHAp5CgQEAgIAEgR3
AnwEGmsgUmVxdWlyZWQuIFRoZSBsb2NhdGlvbiB0byBsaXN0IFNJUCB0cnVua3MgZnJvbS4K
IEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElE
PmAuCgoMCgUEAgIABRIDdwIICgwKBQQCAgABEgN3CQ8KDAoFBAICAAMSA3cSEwoNCgUEAgIA
CBIEdxR8AwoPCggEAgIACJwIABIDeAQqCg8KBwQCAgAInwgSBHkEewUKcwoEBAICARIEgAEC
PxplIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGlu
IGEgc2luZ2xlIHBhZ2UuIEJ5CiBkZWZhdWx0IDEwMCBhbmQgYXQgbW9zdCAxMDAwLgoKDQoF
BAICAQUSBIABAgcKDQoFBAICAQESBIABCBEKDQoFBAICAQMSBIABFBUKDQoFBAICAQgSBIAB
Fj4KEAoIBAICAQicCAASBIABFz0KWgoEBAICAhIEgwECQRpMIE9wdGlvbmFsLiBUaGUgbmV4
dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJlcXVl
c3QuCgoNCgUEAgICBRIEgwECCAoNCgUEAgICARIEgwEJEwoNCgUEAgICAxIEgwEWFwoNCgUE
AgICCBIEgwEYQAoQCggEAgICCJwIABIEgwEZPwp4CgIEAxIGiAEAjwEBGmogVGhlIHJlc3Bv
bnNlIG1lc3NhZ2UgZm9yCiBbU2lwVHJ1bmtzLkxpc3RTaXBUcnVua3NdW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyLlNpcFRydW5rcy5MaXN0U2lwVHJ1bmtzXS4KCgsKAwQDARIEiAEI
HQonCgQEAwIAEgSKAQIjGhkgVGhlIGxpc3Qgb2YgU0lQIHRydW5rcy4KCg0KBQQDAgAEEgSK
AQIKCg0KBQQDAgAGEgSKAQsTCg0KBQQDAgABEgSKARQeCg0KBQQDAgADEgSKASEiCm8KBAQD
AgESBI4BAh0aYSBUb2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMs
IG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubwogbW9yZSByZXN1bHRzIGluIHRoZSBsaXN0LgoK
DQoFBAMCAQUSBI4BAggKDQoFBAMCAQESBI4BCRgKDQoFBAMCAQMSBI4BGxwKcwoCBAQSBpMB
AJ0BARplIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2lwVHJ1bmtzLkdldFNpcFRydW5r
XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TaXBUcnVua3MuR2V0U2lwVHJ1bmtdLgoK
CwoDBAQBEgSTAQgaCpQBCgQEBAIAEgaXAQKcAQQagwEgUmVxdWlyZWQuIFRoZSBuYW1lIG9m
IHRoZSBTSVAgdHJ1bmsgdG8gZGVsZXRlLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3Qg
SUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+L3NpcFRydW5rcy88U2lwVHJ1bmsKIElEPmAu
CgoNCgUEBAIABRIElwECCAoNCgUEBAIAARIElwEJDQoNCgUEBAIAAxIElwEQEQoPCgUEBAIA
CBIGlwESnAEDChAKCAQEAgAInAgAEgSYAQQqChEKBwQEAgAInwgSBpkBBJsBBQp5CgIEBRIG
oQEAqQEBGmsgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTaXBUcnVua3MuVXBkYXRlU2lw
VHJ1bmtdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlNpcFRydW5rcy5VcGRhdGVTaXBU
cnVua10uCgoLCgMEBQESBKEBCB0KMQoEBAUCABIEowECQhojIFJlcXVpcmVkLiBUaGUgU2lw
VHJ1bmsgdG8gdXBkYXRlLgoKDQoFBAUCAAYSBKMBAgoKDQoFBAUCAAESBKMBCxQKDQoFBAUC
AAMSBKMBFxgKDQoFBAUCAAgSBKMBGUEKEAoIBAUCAAicCAASBKMBGkAKggEKBAQFAgESBqcB
AqgBLxpyIE9wdGlvbmFsLiBUaGUgbWFzayB0byBjb250cm9sIHdoaWNoIGZpZWxkcyBnZXQg
dXBkYXRlZC4gSWYgdGhlIG1hc2sgaXMgbm90CiBwcmVzZW50LCBhbGwgZmllbGRzIHdpbGwg
YmUgdXBkYXRlZC4KCg0KBQQFAgEGEgSnAQIbCg0KBQQFAgEBEgSnARwnCg0KBQQFAgEDEgSn
ASorCg0KBQQFAgEIEgSoAQYuChAKCAQFAgEInAgAEgSoAQctCoMBCgIEBhIGrQEA1gEBGnUg
U2lwVHJ1bmsgaXMgdGhlIHJlc291cmNlIHRoYXQgcmVwcmVzZW50cyBhIFNJUCB0cnVuayB0
byBjb25uZWN0IHRvIEdvb2dsZQogVGVsZXBob255IHBsYXRmb3JtIFNJUCB0cnVua2luZyBz
ZXJ2aWNlLgoKCwoDBAYBEgStAQgQCg0KAwQGBxIGrgECswEECg8KBQQGB50IEgauAQKzAQQK
SQoEBAYEABIGtgECvAEDGjkgVGhlIHR5cGUgb2YgR29vZ2xlIHJvb3QgY2VydGlmaWNhdGUg
ZmlsZSB1c2VkIGZvciBtVExTLgoKDQoFBAYEAAESBLYBBxkKNAoGBAYEAAIAEgS4AQQeGiQg
VW5zcGVjaWZpZWQgcm9vdCBjZXJ0aWZpY2F0ZSBmaWxlLgoKDwoHBAYEAAIAARIEuAEEGQoP
CgcEBgQAAgACEgS4ARwdCioKBgQGBAACARIEuwEEHBoaIFVzZSBleHRlcm5hbCBwcml2YXRl
IENBLgoKDwoHBAYEAAIBARIEuwEEFwoPCgcEBgQAAgECEgS7ARobCpcBCgQEBgIAEgTBAQI9
GogBIElkZW50aWZpZXIuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgU0lQIHRydW5r
LgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24g
SUQ+L3NpcFRydW5rcy88U2lwVHJ1bmsKIElEPmAuCgoNCgUEBgIABRIEwQECCAoNCgUEBgIA
ARIEwQEJDQoNCgUEBgIAAxIEwQEQEQoNCgUEBgIACBIEwQESPAoQCggEBgIACJwIABIEwQET
Owp9CgQEBgIBEgbFAQLGAS8abSBSZXF1aXJlZC4gVGhlIGV4cGVjdGVkIGhvc3RuYW1lcyBp
biB0aGUgcGVlciBjZXJ0aWZpY2F0ZSBmcm9tIHBhcnRuZXIgdGhhdAogaXMgdXNlZCBmb3Ig
VExTIGF1dGhlbnRpY2F0aW9uLgoKDQoFBAYCAQQSBMUBAgoKDQoFBAYCAQUSBMUBCxEKDQoF
BAYCAQESBMUBEiMKDQoFBAYCAQMSBMUBJicKDQoFBAYCAQgSBMYBBi4KEAoIBAYCAQicCAAS
BMYBBy0KPAoEBAYCAhIGyQECygEyGiwgT3V0cHV0IG9ubHkuIENvbm5lY3Rpb25zIG9mIHRo
ZSBTSVAgdHJ1bmsuCgoNCgUEBgICBBIEyQECCgoNCgUEBgICBhIEyQELFQoNCgUEBgICARIE
yQEWIQoNCgUEBgICAxIEyQEkJQoNCgUEBgICCBIEygEGMQoQCggEBgICCJwIABIEygEHMAo+
CgQEBgIDEgTNAQJDGjAgT3B0aW9uYWwuIEh1bWFuIHJlYWRhYmxlIGFsaWFzIGZvciB0aGlz
IHRydW5rLgoKDQoFBAYCAwUSBM0BAggKDQoFBAYCAwESBM0BCRUKDQoFBAYCAwMSBM0BGBkK
DQoFBAYCAwgSBM0BGkIKEAoIBAYCAwicCAASBM0BG0EKPAoEBAYCBBIG0AEC0QEvGiwgUmVx
dWlyZWQuIFBlZXIgaG9zdG5hbWVzIG9mIHRoZSBTSVAgdHJ1bmsuCgoNCgUEBgIEBBIE0AEC
CgoNCgUEBgIEBhIE0AELFgoNCgUEBgIEARIE0AEXJQoNCgUEBgIEAxIE0AEoKQoNCgUEBgIE
CBIE0QEGLgoQCggEBgIECJwIABIE0QEHLQpQCgQEBgIFEgbUAQLVAS8aQCBPcHRpb25hbC4g
VGhlIHJvb3QgY2VydGlmaWNhdGUgZmlsZSB0byB1c2UgZm9yIHRoaXMgU0lQIHRydW5rLgoK
DQoFBAYCBQYSBNQBAhQKDQoFBAYCBQESBNQBFSoKDQoFBAYCBQMSBNQBLS4KDQoFBAYCBQgS
BNUBBi4KEAoIBAYCBQicCAASBNUBBy0KNgoCBAcSBtkBAKICARooIFJlcHJlc2VudHMgYSBj
b25uZWN0aW9uIGZvciBTSVAgVHJ1bmsuCgoLCgMEBwESBNkBCBIKNAoEBAcEABIG2wEC6gED
GiQgVGhlIHN0YXRlIG9mIFNpcCBUcnVuayBjb25uZWN0aW9uLgoKDQoFBAcEAAESBNsBBwwK
PgoGBAcEAAIAEgTdAQQaGi4gU0lQIFRydW5rIGNvbm5lY3Rpb24gc3RhdGUgaXMgTm90IHNw
ZWNpZmllZC4KCg8KBwQHBAACAAESBN0BBBUKDwoHBAcEAAIAAhIE3QEYGQo0CgYEBwQAAgES
BOABBBIaJCBTSVAgVHJ1bmsgY29ubmVjdGlvbiBpcyBjb25uZWN0ZWQuCgoPCgcEBwQAAgEB
EgTgAQQNCg8KBwQHBAACAQISBOABEBEKNwoGBAcEAAICEgTjAQQVGicgU0lQIFRydW5rIGNv
bm5lY3Rpb24gaXMgZGlzY29ubmVjdGVkLgoKDwoHBAcEAAICARIE4wEEEAoPCgcEBwQAAgIC
EgTjARMUCkAKBgQHBAACAxIE5gEEHhowIFNJUCBUcnVuayBjb25uZWN0aW9uIGhhcyBhdXRo
ZW50aWNhdGlvbiBlcnJvci4KCg8KBwQHBAACAwESBOYBBBkKDwoHBAcEAAIDAhIE5gEcHQo0
CgYEBwQAAgQSBOkBBBIaJCBTSVAgVHJ1bmsgY29ubmVjdGlvbiBpcyBrZWVwYWxpdmUuCgoP
CgcEBwQAAgQBEgTpAQQNCg8KBwQHBAACBAISBOkBEBEKRAoEBAcEARIG7QECiAIDGjQgVGhl
IHN0YXRlIG9mIFNpcCBUcnVuayBjZXJ0aWZpY2F0ZSBhdXRoZW50aWNhdGlvbi4KCg0KBQQH
BAEBEgTtAQcXCjUKBgQHBAECABIE7wEEJholIENlcnRpZmljYXRlIHN0YXRlIGlzIG5vdCBz
cGVjaWZpZWQuCgoPCgcEBwQBAgABEgTvAQQhCg8KBwQHBAECAAISBO8BJCUKJwoGBAcEAQIB
EgTyAQQaGhcgQ2VydGlmaWNhdGUgaXMgdmFsaWQuCgoPCgcEBwQBAgEBEgTyAQQVCg8KBwQH
BAECAQISBPIBGBkKOAoGBAcEAQICEgT1AQQcGiggQ2F0Y2ggYWxsIGZvciBhbnkgZXJyb3Ig
bm90IHNwZWNpZmllZC4KCg8KBwQHBAECAgESBPUBBBcKDwoHBAcEAQICAhIE9QEaGwo0CgYE
BwQBAgMSBPgBBBwaJCBDZXJ0aWZpY2F0ZSBsZWFmIG5vZGUgaGFzIGV4cGlyZWQuCgoPCgcE
BwQBAgMBEgT4AQQXCg8KBwQHBAECAwISBPgBGhsKVAoGBAcEAQIEEgT7AQQnGkQgVGhlcmUg
aXMgbm8gaG9zdG5hbWUgZGVmaW5lZCB0byBhdXRoZW50aWNhdGUgaW4gU2lwVHJ1bmtpbmdT
ZXJ2ZXIuCgoPCgcEBwQBAgQBEgT7AQQiCg8KBwQHBAECBAISBPsBJSYKRgoGBAcEAQIFEgT+
AQQkGjYgTm8gcGF0aCBmb3VuZCBmcm9tIHRoZSBsZWFmIGNlcnRpZmljYXRlIHRvIGFueSBy
b290LgoKDwoHBAcEAQIFARIE/gEEHwoPCgcEBwQBAgUCEgT+ASIjCi0KBgQHBAECBhIEgQIE
KhodIFRydXN0IHN0b3JlIGRvZXMgbm90IGV4aXN0LgoKDwoHBAcEAQIGARIEgQIEJQoPCgcE
BwQBAgYCEgSBAigpCi4KBgQHBAECBxIEhAIELBoeIEhvc3RuYW1lIGhhcyBpbnZhbGlkIGZv
cm1hdC4KCg8KBwQHBAECBwESBIQCBCcKDwoHBAcEAQIHAhIEhAIqKwo2CgYEBwQBAggSBIcC
BCMaJiBDZXJ0aWZpY2F0ZSBoYXMgZXhoYXVzdGVkIGl0cyBxdW90YS4KCg8KBwQHBAECCAES
BIcCBB4KDwoHBAcEAQIIAhIEhwIhIgpLCgQEBwMAEgaLAgKSAgMaOyBUaGUgZXJyb3IgZGV0
YWlscyBvZiBTaXAgVHJ1bmsgY29ubmVjdGlvbiBhdXRoZW50aWNhdGlvbi4KCg0KBQQHAwAB
EgSLAgoWCk4KBgQHAwACABIGjQIEjgI0GjwgT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2Yg
dGhlIGNlcnRpZmljYXRlIGF1dGhlbnRpY2F0aW9uLgoKDwoHBAcDAAIABBIEjQIEDAoPCgcE
BwMAAgAGEgSNAg0dCg8KBwQHAwACAAESBI0CHi8KDwoHBAcDAAIAAxIEjQIyMwoPCgcEBwMA
AgAIEgSOAggzChIKCgQHAwACAAicCAASBI4CCTIKSwoGBAcDAAIBEgSRAgQmGjsgVGhlIGVy
cm9yIG1lc3NhZ2UgcHJvdmlkZWQgZnJvbSBTSVAgdHJ1bmtpbmcgYXV0aCBzZXJ2aWNlCgoP
CgcEBwMAAgEEEgSRAgQMCg8KBwQHAwACAQUSBJECDRMKDwoHBAcDAAIBARIEkQIUIQoPCgcE
BwMAAgEDEgSRAiQlCk8KBAQHAgASBJUCAkcaQSBPdXRwdXQgb25seS4gVGhlIHVuaXF1ZSBp
ZGVudGlmaWVyIG9mIHRoZSBTSVAgVHJ1bmsgY29ubmVjdGlvbi4KCg0KBQQHAgAFEgSVAgII
Cg0KBQQHAgABEgSVAgkWCg0KBQQHAgADEgSVAhkaCg0KBQQHAgAIEgSVAhtGChAKCAQHAgAI
nAgAEgSVAhxFCjUKBAQHAgESBJgCAj4aJyBPdXRwdXQgb25seS4gU3RhdGUgb2YgdGhlIGNv
bm5lY3Rpb24uCgoNCgUEBwIBBhIEmAICBwoNCgUEBwIBARIEmAIIDQoNCgUEBwIBAxIEmAIQ
EQoNCgUEBwIBCBIEmAISPQoQCggEBwIBCJwIABIEmAITPApCCgQEBwICEgabAgKcAjIaMiBP
dXRwdXQgb25seS4gV2hlbiB0aGUgY29ubmVjdGlvbiBzdGF0dXMgY2hhbmdlZC4KCg0KBQQH
AgIEEgSbAgIKCg0KBQQHAgIGEgSbAgskCg0KBQQHAgIBEgSbAiUwCg0KBQQHAgIDEgSbAjM0
Cg0KBQQHAgIIEgScAgYxChAKCAQHAgIInAgAEgScAgcwCnYKBAQHAgMSBqACAqECMhpmIE91
dHB1dCBvbmx5LiBUaGUgZXJyb3IgZGV0YWlscyBmb3IgdGhlIGNvbm5lY3Rpb24uIE9ubHkg
cG9wdWxhdGVkIHdoZW4KIGF1dGhlbnRpY2F0aW9uIGVycm9ycyBvY2N1ci4KCg0KBQQHAgME
EgSgAgIKCg0KBQQHAgMGEgSgAgsXCg0KBQQHAgMBEgSgAhglCg0KBQQHAgMDEgSgAigpCg0K
BQQHAgMIEgShAgYxChAKCAQHAgMInAgAEgShAgcwCjkKAgQIEgalAgD4AgEaKyBSZXByZXNl
bnRzIGEgcGVlciBob3N0bmFtZSBmb3IgU0lQIFRydW5rLgoKCwoDBAgBEgSlAggTCjcKBAQI
BAASBqcCArYCAxonIFRoZSBzdGF0ZSBvZiBTQkMgaG9zdG5hbWUgY29ubmVjdGlvbi4KCg0K
BQQIBAABEgSnAgcWCkEKBgQIBAACABIEqQIEJRoxIFNCQyBob3N0bmFtZSBjb25uZWN0aW9u
IHN0YXRlIGlzIE5vdCBzcGVjaWZpZWQuCgoPCgcECAQAAgABEgSpAgQgCg8KBwQIBAACAAIS
BKkCIyQKNwoGBAgEAAIBEgSsAgQSGicgU0JDIGhvc3RuYW1lIGNvbm5lY3Rpb24gaXMgY29u
bmVjdGVkLgoKDwoHBAgEAAIBARIErAIEDQoPCgcECAQAAgECEgSsAhARCjoKBgQIBAACAhIE
rwIEFRoqIFNCQyBob3N0bmFtZSBjb25uZWN0aW9uIGlzIGRpc2Nvbm5lY3RlZC4KCg8KBwQI
BAACAgESBK8CBBAKDwoHBAgEAAICAhIErwITFApDCgYECAQAAgMSBLICBB4aMyBTQkMgaG9z
dG5hbWUgY29ubmVjdGlvbiBoYXMgYXV0aGVudGljYXRpb24gZXJyb3IuCgoPCgcECAQAAgMB
EgSyAgQZCg8KBwQIBAACAwISBLICHB0KNwoGBAgEAAIEEgS1AgQSGicgU0JDIGhvc3RuYW1l
IGNvbm5lY3Rpb24gaXMga2VlcGFsaXZlLgoKDwoHBAgEAAIEARIEtQIEDQoPCgcECAQAAgQC
EgS1AhARCkQKBAQIBAESBrkCAtQCAxo0IFRoZSBzdGF0ZSBvZiBTaXAgVHJ1bmsgY2VydGlm
aWNhdGUgYXV0aGVudGljYXRpb24uCgoNCgUECAQBARIEuQIHHwo1CgYECAQBAgASBLsCBC8a
JSBDZXJ0aWZpY2F0ZSBzdGF0ZSBpcyBub3Qgc3BlY2lmaWVkLgoKDwoHBAgEAQIAARIEuwIE
KgoPCgcECAQBAgACEgS7Ai0uCicKBgQIBAECARIEvgIEDhoXIENlcnRpZmljYXRlIGlzIHZh
bGlkLgoKDwoHBAgEAQIBARIEvgIECQoPCgcECAQBAgECEgS+AgwNCjgKBgQIBAECAhIEwQIE
EBooIENhdGNoIGFsbCBmb3IgYW55IGVycm9yIG5vdCBzcGVjaWZpZWQuCgoPCgcECAQBAgIB
EgTBAgQLCg8KBwQIBAECAgISBMECDg8KNAoGBAgEAQIDEgTEAgQQGiQgQ2VydGlmaWNhdGUg
bGVhZiBub2RlIGhhcyBleHBpcmVkLgoKDwoHBAgEAQIDARIExAIECwoPCgcECAQBAgMCEgTE
Ag4PClQKBgQIBAECBBIExwIEGxpEIFRoZXJlIGlzIG5vIGhvc3RuYW1lIGRlZmluZWQgdG8g
YXV0aGVudGljYXRlIGluIFNpcFRydW5raW5nU2VydmVyLgoKDwoHBAgEAQIEARIExwIEFgoP
CgcECAQBAgQCEgTHAhkaCkYKBgQIBAECBRIEygIEGBo2IE5vIHBhdGggZm91bmQgZnJvbSB0
aGUgbGVhZiBjZXJ0aWZpY2F0ZSB0byBhbnkgcm9vdC4KCg8KBwQIBAECBQESBMoCBBMKDwoH
BAgEAQIFAhIEygIWFwotCgYECAQBAgYSBM0CBB4aHSBUcnVzdCBzdG9yZSBkb2VzIG5vdCBl
eGlzdC4KCg8KBwQIBAECBgESBM0CBBkKDwoHBAgEAQIGAhIEzQIcHQouCgYECAQBAgcSBNAC
BCAaHiBIb3N0bmFtZSBoYXMgaW52YWxpZCBmb3JtYXQuCgoPCgcECAQBAgcBEgTQAgQbCg8K
BwQIBAECBwISBNACHh8KNgoGBAgEAQIIEgTTAgQXGiYgQ2VydGlmaWNhdGUgaGFzIGV4aGF1
c3RlZCBpdHMgcXVvdGEuCgoPCgcECAQBAggBEgTTAgQSCg8KBwQIBAECCAISBNMCFRYKUwoE
BAgDABIG1wIC3gIDGkMgVGhlIGVycm9yIGRldGFpbHMgb2YgU2lwIFRydW5rIGhvc3RuYW1l
Y29ubmVjdGlvbiBhdXRoZW50aWNhdGlvbi4KCg0KBQQIAwABEgTXAgoeCk4KBgQIAwACABIG
2QIE2gI0GjwgT3V0cHV0IG9ubHkuIFRoZSBzdGF0dXMgb2YgdGhlIGNlcnRpZmljYXRlIGF1
dGhlbnRpY2F0aW9uLgoKDwoHBAgDAAIABhIE2QIEHAoPCgcECAMAAgABEgTZAh0uCg8KBwQI
AwACAAMSBNkCMTIKDwoHBAgDAAIACBIE2gIIMwoSCgoECAMAAgAInAgAEgTaAgkyClgKBgQI
AwACARIE3QIESRpIIE91dHB1dCBvbmx5LiBUaGUgZXJyb3IgbWVzc2FnZSBwcm92aWRlZCBm
cm9tIFNJUCB0cnVua2luZyBhdXRoIHNlcnZpY2UKCg8KBwQIAwACAQUSBN0CBAoKDwoHBAgD
AAIBARIE3QILGAoPCgcECAMAAgEDEgTdAhscCg8KBwQIAwACAQgSBN0CHUgKEgoKBAgDAAIB
CJwIABIE3QIeRwotCgQECAIAEgThAgJEGh8gUmVxdWlyZWQuIFBlZXIgaG9zdG5hbWUgbmFt
ZS4KCg0KBQQIAgAFEgThAgIICg0KBQQIAgABEgThAgkWCg0KBQQIAgADEgThAhkaCg0KBQQI
AgAIEgThAhtDChAKCAQIAgAInAgAEgThAhxCCkAKBAQIAgESBOQCAkgaMiBPdXRwdXQgb25s
eS4gUGVlciBob3N0bmFtZSBlbmFibGVkIGZvciBTSVAgcGluZy4KCg0KBQQIAgEFEgTkAgIG
Cg0KBQQIAgEBEgTkAgcXCg0KBQQIAgEDEgTkAhobCg0KBQQIAgEIEgTkAhxHChAKCAQIAgEI
nAgAEgTkAh1GCkMKBAQIAgISBucCAugCMhozIE91dHB1dCBvbmx5LiBIb3cgb2Z0ZW4gdGhl
IHNpcCBwaW5nIHNob3VsZCBvY2N1ci4KCg0KBQQIAgIGEgTnAgIaCg0KBQQIAgIBEgTnAhso
Cg0KBQQIAgIDEgTnAissCg0KBQQIAgIIEgToAgYxChAKCAQIAgIInAgAEgToAgcwCk8KBAQI
AgMSBOsCAk0aQSBPdXRwdXQgb25seS4gVGhlIHBlZXJfc29ja2V0IGFkZHJlc3Mgb2YgdGhl
IHBhcnRuZXIgU0JDIHBpbmdlZC4KCg0KBQQIAgMFEgTrAgIICg0KBQQIAgMBEgTrAgkcCg0K
BQQIAgMDEgTrAh8gCg0KBQQIAgMIEgTrAiFMChAKCAQIAgMInAgAEgTrAiJLCkAKBAQIAgQS
BO4CAk0aMiBPdXRwdXQgb25seS4gVGhlIGRldGFpbHMgZnJvbSB0aGUgb3B0aW9ucyBwcm9i
ZS4KCg0KBQQIAgQGEgTuAgIOCg0KBQQIAgQBEgTuAg8cCg0KBQQIAgQDEgTuAh8gCg0KBQQI
AgQIEgTuAiFMChAKCAQIAgQInAgAEgTuAiJLCjcKBAQIAgUSBvECAvICMhonIE91dHB1dCBv
bmx5LiBTdGF0ZSBvZiB0aGUgY29ubmVjdGlvbi4KCg0KBQQIAgUGEgTxAgIRCg0KBQQIAgUB
EgTxAhIiCg0KBQQIAgUDEgTxAiUmCg0KBQQIAgUIEgTyAgYxChAKCAQIAgUInAgAEgTyAgcw
CnYKBAQIAgYSBvYCAvcCMhpmIE91dHB1dCBvbmx5LiBUaGUgZXJyb3IgZGV0YWlscyBmb3Ig
dGhlIGNvbm5lY3Rpb24uIE9ubHkgcG9wdWxhdGVkIHdoZW4KIGF1dGhlbnRpY2F0aW9uIGVy
cm9ycyBvY2N1ci4KCg0KBQQIAgYGEgT2AgIWCg0KBQQIAgYBEgT2AhckCg0KBQQIAgYDEgT2
AicoCg0KBQQIAgYIEgT3AgYxChAKCAQIAgYInAgAEgT3AgcwCj0KAgQJEgb7AgCSAwEaLyBU
aGUgcHJvYmUgZGV0YWlscyBvZiBTaXAgVHJ1bmsgcGVlciBob3N0bmFtZS4KCgsKAwQJARIE
+wIIFApICgQECQQAEgb9AgKGAwMaOCBUaGUgc3RhdHVzIG9mIEluaXRpYXRlU2lwT3B0aW9u
c1BpbmcgdG8gcGVlciBob3N0bmFtZS4KCg0KBQQJBAABEgT9AgcSCjwKBgQJBAACABIE/wIE
IRosIFBlZXIgaG9zdG5hbWUgcGluZyBzdGF0ZSBpcyBub3Qgc3BlY2lmaWVkLgoKDwoHBAkE
AAIAARIE/wIEHAoPCgcECQQAAgACEgT/Ah8gCi8KBgQJBAACARIEggMEHRofIFBlZXIgaG9z
dG5hbWUgcGluZyBzdWNjZWVkZWQuCgoPCgcECQQAAgEBEgSCAwQYCg8KBwQJBAACAQISBIID
GxwKLAoGBAkEAAICEgSFAwQcGhwgUGVlciBob3N0bmFtZSBwaW5nIGZhaWxlZC4KCg8KBwQJ
BAACAgESBIUDBBcKDwoHBAkEAAICAhIEhQMaGwpWCgQECQIAEgaJAwKKAzIaRiBPdXRwdXQg
b25seS4gRHVyYXRpb24gYmV0d2VlbiBPUFRJT05TIHNlbmQgYW5kIE9QVElPTlMgMjAwIHJl
Y2VpdmVkLgoKDQoFBAkCAAYSBIkDAhoKDQoFBAkCAAESBIkDGyoKDQoFBAkCAAMSBIkDLS4K
DQoFBAkCAAgSBIoDBjEKEAoIBAkCAAicCAASBIoDBzAKMQoEBAkCARIEjQMCSxojIE91dHB1
dCBvbmx5LiBSZXN1bHQgb2YgdGhlIHByb2JlLgoKDQoFBAkCAQYSBI0DAg0KDQoFBAkCAQES
BI0DDhoKDQoFBAkCAQMSBI0DHR4KDQoFBAkCAQgSBI0DH0oKEAoIBAkCAQicCAASBI0DIEkK
QgoEBAkCAhIGkAMCkQMyGjIgT3V0cHV0IG9ubHkuIFdoZW4gdGhlIG9wdGlvbnMgcHJvYmUg
d2FzIHN0YXJ0ZWQuCgoNCgUECQICBhIEkAMCGwoNCgUECQICARIEkAMcJQoNCgUECQICAxIE
kAMoKQoNCgUECQICCBIEkQMGMQoQCggECQICCJwIABIEkQMHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::CreateSipTrunkRequest ===
    # Fields for CreateSipTrunkRequest
    # Field: parent Type: 9 ()
    # Field: sip_trunk Type: 11 (.google.cloud.dialogflow.v2.SipTrunk)

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::DeleteSipTrunkRequest ===
    # Fields for DeleteSipTrunkRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksRequest ===
    # Fields for ListSipTrunksRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksResponse ===
    # Fields for ListSipTrunksResponse
    # Field: sip_trunks Type: 11 (.google.cloud.dialogflow.v2.SipTrunk)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::GetSipTrunkRequest ===
    # Fields for GetSipTrunkRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::UpdateSipTrunkRequest ===
    # Fields for UpdateSipTrunkRequest
    # Field: sip_trunk Type: 11 (.google.cloud.dialogflow.v2.SipTrunk)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk ===
    # Fields for SipTrunk
    # Field: name Type: 9 ()
    # Field: expected_hostname Type: 9 ()
    # Field: connections Type: 11 (.google.cloud.dialogflow.v2.Connection)
    # Field: display_name Type: 9 ()
    # Field: peer_hostnames Type: 11 (.google.cloud.dialogflow.v2.SipHostname)
    # Field: google_root_cert_file Type: 14 (.google.cloud.dialogflow.v2.SipTrunk.GoogleRootCertFile)

# Enum: SipTrunk::GoogleRootCertFile
our $SipTrunk_CERT_FILE_UNSPECIFIED = 0;
our $SipTrunk_EXTERNAL_PRIVATE_CA = 5;

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::Connection ===
    # Fields for Connection
    # Field: connection_id Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dialogflow.v2.Connection.State)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: error_details Type: 11 (.google.cloud.dialogflow.v2.Connection.ErrorDetails)

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

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname ===
    # Fields for SipHostname
    # Field: peer_hostname Type: 9 ()
    # Field: enabled_sip_ping Type: 8 ()
    # Field: ping_interval Type: 11 (.google.protobuf.Duration)
    # Field: peer_socket_address Type: 9 ()
    # Field: probe_details Type: 11 (.google.cloud.dialogflow.v2.ProbeDetails)
    # Field: connection_state Type: 14 (.google.cloud.dialogflow.v2.SipHostname.ConnectionState)
    # Field: error_details Type: 11 (.google.cloud.dialogflow.v2.SipHostname.HostnameErrorDetails)

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

# === Message: Google::Cloud::Dialogflow::V2::SipTrunk::ProbeDetails ===
    # Fields for ProbeDetails
    # Field: options_latency Type: 11 (.google.protobuf.Duration)
    # Field: probe_status Type: 14 (.google.cloud.dialogflow.v2.ProbeDetails.ProbeStatus)
    # Field: init_time Type: 11 (.google.protobuf.Timestamp)

# Enum: ProbeDetails::ProbeStatus
our $ProbeDetails_PROBE_STATUS_UNSPECIFIED = 0;
our $ProbeDetails_PROBE_STATUS_SUCCESS = 1;
our $ProbeDetails_PROBE_STATUS_FAILED = 2;

# === Service Client: Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunksClient ===
package Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunksClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunksClient

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
        ? Google::Cloud::Dialogflow::V2::SipTrunk::CreateSipTrunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SipTrunks',
        method         => 'CreateSipTrunk',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk',
    });
}

sub delete_sip_trunk {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::SipTrunk::DeleteSipTrunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SipTrunks',
        method         => 'DeleteSipTrunk',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_sip_trunks {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SipTrunks',
        method         => 'ListSipTrunks',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksResponse',
    });
}

sub get_sip_trunk {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::SipTrunk::GetSipTrunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SipTrunks',
        method         => 'GetSipTrunk',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk',
    });
}

sub update_sip_trunk {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::SipTrunk::UpdateSipTrunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SipTrunks',
        method         => 'UpdateSipTrunk',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::SipTrunk - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/sip_trunk.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::SipTrunk;

    my $msg = Google::Cloud::Dialogflow::V2::SipTrunk::CreateSipTrunkRequest->new({
        parent => $parent,
        sip_trunk => $sip_trunk,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::SipTrunk::CreateSipTrunkRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/sip_trunk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::CreateSipTrunkRequest

The request message for
[SipTrunks.CreateSipTrunk][google.cloud.dialogflow.v2.SipTrunks.CreateSipTrunk].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location to create a SIP trunk for.
Format: `projects/<Project ID>/locations/<Location ID>`.

=item * C<< $msg->sip_trunk() >> / C<< $msg->sip_trunk($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk>)

Required. The SIP trunk to create.

=back

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::DeleteSipTrunkRequest

The request message for
[SipTrunks.DeleteSipTrunk][google.cloud.dialogflow.v2.SipTrunks.DeleteSipTrunk].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the SIP trunk to delete.
Format: `projects/<Project ID>/locations/<Location ID>/sipTrunks/<SipTrunk
ID>`.

=back

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksRequest

The request message for
[SipTrunks.ListSipTrunks][google.cloud.dialogflow.v2.SipTrunks.ListSipTrunks].

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

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksResponse

The response message for
[SipTrunks.ListSipTrunks][google.cloud.dialogflow.v2.SipTrunks.ListSipTrunks].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sip_trunks() >> / C<< $msg->sip_trunks($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk>)

The list of SIP trunks.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::GetSipTrunkRequest

The request message for
[SipTrunks.GetSipTrunk][google.cloud.dialogflow.v2.SipTrunks.GetSipTrunk].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the SIP trunk to delete.
Format: `projects/<Project ID>/locations/<Location ID>/sipTrunks/<SipTrunk
ID>`.

=back

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::UpdateSipTrunkRequest

The request message for
[SipTrunks.UpdateSipTrunk][google.cloud.dialogflow.v2.SipTrunks.UpdateSipTrunk].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sip_trunk() >> / C<< $msg->sip_trunk($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk>)

Required. The SipTrunk to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated. If the mask is not
present, all fields will be updated.

=back

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk

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

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SipTrunk::Connection>)

Output only. Connections of the SIP trunk.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Human readable alias for this trunk.

=item * C<< $msg->peer_hostnames() >> / C<< $msg->peer_hostnames($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname>)

Required. Peer hostnames of the SIP trunk.

=item * C<< $msg->google_root_cert_file() >> / C<< $msg->google_root_cert_file($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::SipTrunk::GoogleRootCertFile>)

Optional. The root certificate file to use for this SIP trunk.

=back

=head3 Enum: SipTrunk::GoogleRootCertFile

=over 4

=item * C<CERT_FILE_UNSPECIFIED> => C<0>

=item * C<EXTERNAL_PRIVATE_CA> => C<5>

=back

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::Connection

Represents a connection for SIP Trunk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connection_id() >> / C<< $msg->connection_id($value) >>

Type: C<String>

Output only. The unique identifier of the SIP Trunk connection.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::Connection::State>)

Output only. State of the connection.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the connection status changed.

=item * C<< $msg->error_details() >> / C<< $msg->error_details($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SipTrunk::Connection::ErrorDetails>)

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

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname

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

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SipTrunk::ProbeDetails>)

Output only. The details from the options probe.

=item * C<< $msg->connection_state() >> / C<< $msg->connection_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::SipHostname::ConnectionState>)

Output only. State of the connection.

=item * C<< $msg->error_details() >> / C<< $msg->error_details($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname::HostnameErrorDetails>)

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

=head2 Google::Cloud::Dialogflow::V2::SipTrunk::ProbeDetails

The probe details of Sip Trunk peer hostname.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->options_latency() >> / C<< $msg->options_latency($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. Duration between OPTIONS send and OPTIONS 200 received.

=item * C<< $msg->probe_status() >> / C<< $msg->probe_status($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::ProbeDetails::ProbeStatus>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::SipTrunk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
