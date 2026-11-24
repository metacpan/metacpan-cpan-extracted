package Google::Cloud::Sql::V1::CloudSqlBackups;

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
    eval { require Google::Cloud::Sql::V1::CloudSqlBackupRuns };
    eval { require Google::Cloud::Sql::V1::CloudSqlInstances };
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Protobuf::Wrappers };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9iYWNrdXBzLnByb3RvEhNnb29nbGUu
Y2xvdWQuc3FsLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBp
L2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxovZ29vZ2xlL2Nsb3VkL3NxbC92MS9jbG91ZF9zcWxfYmFj
a3VwX3J1bnMucHJvdG8aLWdvb2dsZS9jbG91ZC9zcWwvdjEvY2xvdWRfc3FsX2luc3RhbmNl
cy5wcm90bxotZ29vZ2xlL2Nsb3VkL3NxbC92MS9jbG91ZF9zcWxfcmVzb3VyY2VzLnByb3Rv
GiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL3dyYXBwZXJzLnByb3RvGhpnb29nbGUv
dHlwZS9pbnRlcnZhbC5wcm90byKPAQoTQ3JlYXRlQmFja3VwUmVxdWVzdBI+CgZwYXJlbnQY
ASABKAlCJuBBAvpBIBIec3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20vQmFja3VwUgZwYXJlbnQS
OAoGYmFja3VwGAIgASgLMhsuZ29vZ2xlLmNsb3VkLnNxbC52MS5CYWNrdXBCA+BBAlIGYmFj
a3VwIk4KEEdldEJhY2t1cFJlcXVlc3QSOgoEbmFtZRgBIAEoCUIm4EEC+kEgCh5zcWxhZG1p
bi5nb29nbGVhcGlzLmNvbS9CYWNrdXBSBG5hbWUiqAEKEkxpc3RCYWNrdXBzUmVxdWVzdBI+
CgZwYXJlbnQYASABKAlCJuBBAvpBIBIec3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20vQmFja3Vw
UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMg
ASgJUglwYWdlVG9rZW4SFgoGZmlsdGVyGAQgASgJUgZmaWx0ZXIisQEKE0xpc3RCYWNrdXBz
UmVzcG9uc2USNQoHYmFja3VwcxgBIAMoCzIbLmdvb2dsZS5jbG91ZC5zcWwudjEuQmFja3Vw
UgdiYWNrdXBzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhI7Cgh3
YXJuaW5ncxgDIAMoCzIfLmdvb2dsZS5jbG91ZC5zcWwudjEuQXBpV2FybmluZ1IId2Fybmlu
Z3MijAEKE1VwZGF0ZUJhY2t1cFJlcXVlc3QSOAoGYmFja3VwGAEgASgLMhsuZ29vZ2xlLmNs
b3VkLnNxbC52MS5CYWNrdXBCA+BBAlIGYmFja3VwEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhou
Z29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJRChNEZWxldGVCYWNrdXBS
ZXF1ZXN0EjoKBG5hbWUYASABKAlCJuBBAvpBIAoec3FsYWRtaW4uZ29vZ2xlYXBpcy5jb20v
QmFja3VwUgRuYW1lIocNCgZCYWNrdXASFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEhcKBGtp
bmQYAiABKAlCA+BBA1IEa2luZBIgCglzZWxmX2xpbmsYAyABKAlCA+BBA1IIc2VsZkxpbmsS
QgoEdHlwZRgEIAEoDjIpLmdvb2dsZS5jbG91ZC5zcWwudjEuQmFja3VwLlNxbEJhY2t1cFR5
cGVCA+BBA1IEdHlwZRIgCgtkZXNjcmlwdGlvbhgFIAEoCVILZGVzY3JpcHRpb24SGgoIaW5z
dGFuY2UYBiABKAlSCGluc3RhbmNlEhoKCGxvY2F0aW9uGAcgASgJUghsb2NhdGlvbhJDCg9i
YWNrdXBfaW50ZXJ2YWwYCCABKAsyFS5nb29nbGUudHlwZS5JbnRlcnZhbEID4EEDUg5iYWNr
dXBJbnRlcnZhbBJFCgVzdGF0ZRgJIAEoDjIqLmdvb2dsZS5jbG91ZC5zcWwudjEuQmFja3Vw
LlNxbEJhY2t1cFN0YXRlQgPgQQNSBXN0YXRlEj4KBWVycm9yGAogASgLMiMuZ29vZ2xlLmNs
b3VkLnNxbC52MS5PcGVyYXRpb25FcnJvckID4EEDUgVlcnJvchJCCgdrbXNfa2V5GAsgASgJ
QingQQP6QSMKIWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleVIGa21zS2V5ElgK
D2ttc19rZXlfdmVyc2lvbhgMIAEoCUIw4EED+kEqCihjbG91ZGttcy5nb29nbGVhcGlzLmNv
bS9DcnlwdG9LZXlWZXJzaW9uUg1rbXNLZXlWZXJzaW9uEkgKC2JhY2t1cF9raW5kGA0gASgO
MiIuZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxCYWNrdXBLaW5kQgPgQQNSCmJhY2t1cEtpbmQS
IAoJdGltZV96b25lGA8gASgJQgPgQQNSCHRpbWVab25lEiAKCHR0bF9kYXlzGBAgASgDQgPg
QQRIAFIHdHRsRGF5cxI9CgtleHBpcnlfdGltZRgRIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBIAFIKZXhwaXJ5VGltZRJXChBkYXRhYmFzZV92ZXJzaW9uGBQgASgOMicuZ29v
Z2xlLmNsb3VkLnNxbC52MS5TcWxEYXRhYmFzZVZlcnNpb25CA+BBA1IPZGF0YWJhc2VWZXJz
aW9uEjoKFG1heF9jaGFyZ2VhYmxlX2J5dGVzGBcgASgDQgPgQQNIAVISbWF4Q2hhcmdlYWJs
ZUJ5dGVziAEBElgKFmluc3RhbmNlX2RlbGV0aW9uX3RpbWUYGCABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgbgQQHgQQNSFGluc3RhbmNlRGVsZXRpb25UaW1lEloKEWluc3Rh
bmNlX3NldHRpbmdzGBkgASgLMiUuZ29vZ2xlLmNsb3VkLnNxbC52MS5EYXRhYmFzZUluc3Rh
bmNlQgbgQQHgQQNSEGluc3RhbmNlU2V0dGluZ3MSIgoKYmFja3VwX3J1bhgaIAEoCUID4EED
UgliYWNrdXBSdW4SRAoNc2F0aXNmaWVzX3B6cxgbIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5C
b29sVmFsdWVCA+BBA1IMc2F0aXNmaWVzUHpzEkQKDXNhdGlzZmllc19wemkYHCABKAsyGi5n
b29nbGUucHJvdG9idWYuQm9vbFZhbHVlQgPgQQNSDHNhdGlzZmllc1B6aSJZCg1TcWxCYWNr
dXBUeXBlEh8KG1NRTF9CQUNLVVBfVFlQRV9VTlNQRUNJRklFRBAAEg0KCUFVVE9NQVRFRBAB
Eg0KCU9OX0RFTUFORBACEgkKBUZJTkFMEAMijAEKDlNxbEJhY2t1cFN0YXRlEiAKHFNRTF9C
QUNLVVBfU1RBVEVfVU5TUEVDSUZJRUQQABIMCghFTlFVRVVFRBABEgsKB1JVTk5JTkcQAhIK
CgZGQUlMRUQQAxIOCgpTVUNDRVNTRlVMEAQSDAoIREVMRVRJTkcQBRITCg9ERUxFVElPTl9G
QUlMRUQQBjpI6kFFCh5zcWxhZG1pbi5nb29nbGVhcGlzLmNvbS9CYWNrdXASI3Byb2plY3Rz
L3twcm9qZWN0fS9iYWNrdXBzL3tiYWNrdXB9QgwKCmV4cGlyYXRpb25CFwoVX21heF9jaGFy
Z2VhYmxlX2J5dGVzMvgGChFTcWxCYWNrdXBzU2VydmljZRKaAQoMQ3JlYXRlQmFja3VwEigu
Z29vZ2xlLmNsb3VkLnNxbC52MS5DcmVhdGVCYWNrdXBSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3Vk
LnNxbC52MS5PcGVyYXRpb24iQILT5JMCKSIfL3YxL3twYXJlbnQ9cHJvamVjdHMvKn0vYmFj
a3VwczoGYmFja3Vw2kEOcGFyZW50LCBiYWNrdXASfwoJR2V0QmFja3VwEiUuZ29vZ2xlLmNs
b3VkLnNxbC52MS5HZXRCYWNrdXBSZXF1ZXN0GhsuZ29vZ2xlLmNsb3VkLnNxbC52MS5CYWNr
dXAiLoLT5JMCIRIfL3YxL3tuYW1lPXByb2plY3RzLyovYmFja3Vwcy8qfdpBBG5hbWUSkgEK
C0xpc3RCYWNrdXBzEicuZ29vZ2xlLmNsb3VkLnNxbC52MS5MaXN0QmFja3Vwc1JlcXVlc3Qa
KC5nb29nbGUuY2xvdWQuc3FsLnYxLkxpc3RCYWNrdXBzUmVzcG9uc2UiMILT5JMCIRIfL3Yx
L3twYXJlbnQ9cHJvamVjdHMvKn0vYmFja3Vwc9pBBnBhcmVudBKmAQoMVXBkYXRlQmFja3Vw
EiguZ29vZ2xlLmNsb3VkLnNxbC52MS5VcGRhdGVCYWNrdXBSZXF1ZXN0Gh4uZ29vZ2xlLmNs
b3VkLnNxbC52MS5PcGVyYXRpb24iTILT5JMCMDImL3YxL3tiYWNrdXAubmFtZT1wcm9qZWN0
cy8qL2JhY2t1cHMvKn06BmJhY2t1cNpBE2JhY2t1cCwgdXBkYXRlX21hc2sSiAEKDERlbGV0
ZUJhY2t1cBIoLmdvb2dsZS5jbG91ZC5zcWwudjEuRGVsZXRlQmFja3VwUmVxdWVzdBoeLmdv
b2dsZS5jbG91ZC5zcWwudjEuT3BlcmF0aW9uIi6C0+STAiEqHy92MS97bmFtZT1wcm9qZWN0
cy8qL2JhY2t1cHMvKn3aQQRuYW1lGnzKQRdzcWxhZG1pbi5nb29nbGVhcGlzLmNvbdJBX2h0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9zcWxzZXJ2aWNlLmFkbWluQlwKF2NvbS5nb29nbGUu
Y2xvdWQuc3FsLnYxQhRDbG91ZFNxbEJhY2t1cHNQcm90b1ABWiljbG91ZC5nb29nbGUuY29t
L2dvL3NxbC9hcGl2MS9zcWxwYjtzcWxwYkrRUwoHEgUOANECAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoC
AwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADkKCQoCAwUSAxcANwoJCgIDBhIDGAA3CgkK
AgMHEgMZACoKCQoCAwgSAxoAKQoJCgIDCRIDGwAoCgkKAgMKEgMcACQKCAoBCBIDHgBACgkK
AggLEgMeAEAKCAoBCBIDHwAiCgkKAggKEgMfACIKCAoBCBIDIAA1CgkKAggIEgMgADUKCAoB
CBIDIQAwCgkKAggBEgMhADAKTAoCBgASBCQAVQEaQCBTZXJ2aWNlIGZvciBtYW5hZ2luZyBk
YXRhYmFzZSBiYWNrdXBzIGZvciBDbG91ZCBTUUwgaW5zdGFuY2VzLgoKCgoDBgABEgMkCBkK
CgoDBgADEgMlAj8KDAoFBgADmQgSAyUCPwoLCgMGAAMSBCYCKDkKDQoFBgADmggSBCYCKDkK
cgoEBgACABIELAIyAxpkIENyZWF0ZXMgYSBiYWNrdXAgZm9yIGEgQ2xvdWQgU1FMIGluc3Rh
bmNlLiBUaGlzIEFQSSBjYW4gYmUgdXNlZCBvbmx5IHRvCiBjcmVhdGUgb24tZGVtYW5kIGJh
Y2t1cHMuCgoMCgUGAAIAARIDLAYSCgwKBQYAAgACEgMsEyYKDAoFBgACAAMSAywxOgoNCgUG
AAIABBIELQQwBgoRCgkGAAIABLDKvCISBC0EMAYKDAoFBgACAAQSAzEEPAoPCggGAAIABJsI
ABIDMQQ8CksKBAYAAgESBDUCOgMaPSBSZXRyaWV2ZXMgYSByZXNvdXJjZSBjb250YWluaW5n
IGluZm9ybWF0aW9uIGFib3V0IGEgYmFja3VwLgoKDAoFBgACAQESAzUGDwoMCgUGAAIBAhID
NRAgCgwKBQYAAgEDEgM1KzEKDQoFBgACAQQSBDYEOAYKEQoJBgACAQSwyrwiEgQ2BDgGCgwK
BQYAAgEEEgM5BDIKDwoIBgACAQSbCAASAzkEMgo+CgQGAAICEgQ9AkIDGjAgTGlzdHMgYWxs
IGJhY2t1cHMgYXNzb2NpYXRlZCB3aXRoIHRoZSBwcm9qZWN0LgoKDAoFBgACAgESAz0GEQoM
CgUGAAICAhIDPRIkCgwKBQYAAgIDEgM9L0IKDQoFBgACAgQSBD4EQAYKEQoJBgACAgSwyrwi
EgQ+BEAGCgwKBQYAAgIEEgNBBDQKDwoIBgACAgSbCAASA0EENAp/CgQGAAIDEgRGAkwDGnEg
VXBkYXRlcyB0aGUgcmV0ZW50aW9uIHBlcmlvZCBhbmQgZGVzY3JpcHRpb24gb2YgdGhlIGJh
Y2t1cC4gWW91IGNhbiB1c2UKIHRoaXMgQVBJIHRvIHVwZGF0ZSBmaW5hbCBiYWNrdXBzIG9u
bHkuCgoMCgUGAAIDARIDRgYSCgwKBQYAAgMCEgNGEyYKDAoFBgACAwMSA0YxOgoNCgUGAAID
BBIERwRKBgoRCgkGAAIDBLDKvCISBEcESgYKDAoFBgACAwQSA0sEQQoPCggGAAIDBJsIABID
SwRBCiMKBAYAAgQSBE8CVAMaFSBEZWxldGVzIHRoZSBiYWNrdXAuCgoMCgUGAAIEARIDTwYS
CgwKBQYAAgQCEgNPEyYKDAoFBgACBAMSA08xOgoNCgUGAAIEBBIEUARSBgoRCgkGAAIEBLDK
vCISBFAEUgYKDAoFBgACBAQSA1MEMgoPCggGAAIEBJsIABIDUwQyCjYKAgQAEgRYAGQBGiog
VGhlIHJlcXVlc3QgcGF5bG9hZCB0byBjcmVhdGUgdGhlIGJhY2t1cAoKCgoDBAABEgNYCBsK
ZwoEBAACABIEWwJgBBpZIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIHdoZXJlIHRo
aXMgYmFja3VwIGlzIGNyZWF0ZWQuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fQoKDAoF
BAACAAUSA1sCCAoMCgUEAAIAARIDWwkPCgwKBQQAAgADEgNbEhMKDQoFBAACAAgSBFsUYAMK
DwoIBAACAAicCAASA1wEKgoPCgcEAAIACJ8IEgRdBF8FCi4KBAQAAgESA2MCPRohIFJlcXVp
cmVkLiBUaGUgQmFja3VwIHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgNjAggKDAoFBAACAQESA2MJ
DwoMCgUEAAIBAxIDYxITCgwKBQQAAgEIEgNjFDwKDwoIBAACAQicCAASA2MVOwo0CgIEARIE
ZwBuARooIFRoZSByZXF1ZXN0IHBheWxvYWQgdG8gZ2V0IHRoZSBiYWNrdXAuCgoKCgMEAQES
A2cIGApqCgQEAQIAEgRqAm0EGlwgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBiYWNrdXAg
dG8gcmV0cmlldmUuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9iYWNrdXBzL3tiYWNr
dXB9CgoMCgUEAQIABRIDagIICgwKBQQBAgABEgNqCQ0KDAoFBAECAAMSA2oQEQoNCgUEAQIA
CBIEahJtAwoPCggEAQIACJwIABIDawQqCg4KBwQBAgAInwgSA2wEUAo3CgIEAhIFcQCOAQEa
KiBUaGUgcmVxdWVzdCBwYXlsb2FkIHRvIGxpc3QgdGhlIGJhY2t1cHMuCgoKCgMEAgESA3EI
GgpmCgQEAgIAEgR0AnkEGlggUmVxdWlyZWQuIFRoZSBwYXJlbnQgdGhhdCBvd25zIHRoaXMg
Y29sbGVjdGlvbiBvZiBiYWNrdXBzLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0KCgwK
BQQCAgAFEgN0AggKDAoFBAICAAESA3QJDwoMCgUEAgIAAxIDdBITCg0KBQQCAgAIEgR0FHkD
Cg8KCAQCAgAInAgAEgN1BCoKDwoHBAICAAifCBIEdgR4BQrDAgoEBAICARIEgAECFhq0AiBU
aGUgbWF4aW11bSBudW1iZXIgb2YgYmFja3VwcyB0byByZXR1cm4gcGVyIHJlc3BvbnNlLiBU
aGUgc2VydmljZSBtaWdodAogcmV0dXJuIGZld2VyIGJhY2t1cHMgdGhhbiB0aGlzIHZhbHVl
LiBJZiBhIHZhbHVlIGZvciB0aGlzIHBhcmFtZXRlciBpc24ndAogc3BlY2lmaWVkLCB0aGVu
LCBhdCBtb3N0LCA1MDAgYmFja3VwcyBhcmUgcmV0dXJuZWQuIFRoZSBtYXhpbXVtIHZhbHVl
IGlzCiAyLDAwMC4gQW55IHZhbHVlcyB0aGF0IHlvdSBzZXQsIHdoaWNoIGFyZSBncmVhdGVy
IHRoYW4gMiwwMDAsIGFyZSBjaGFuZ2VkCiB0byAyLDAwMC4KCg0KBQQCAgEFEgSAAQIHCg0K
BQQCAgEBEgSAAQgRCg0KBQQCAgEDEgSAARQVCu8BCgQEAgICEgSHAQIYGuABIEEgcGFnZSB0
b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0QmFja3Vwc2AgY2FsbC4KIFBy
b3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFn
aW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RCYWNrdXBz
YCBtdXN0IG1hdGNoCiB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoK
DQoFBAICAgUSBIcBAggKDQoFBAICAgESBIcBCRMKDQoFBAICAgMSBIcBFhcKjQIKBAQCAgMS
BI0BAhQa/gEgTXVsdGlwbGUgZmlsdGVyIHF1ZXJpZXMgYXJlIHNlcGFyYXRlZCBieSBzcGFj
ZXMuIEZvciBleGFtcGxlLAogJ2luc3RhbmNlOmFiYyBBTkQgdHlwZTpGSU5BTCwgJ2xvY2F0
aW9uOnVzJywKICdiYWNrdXBJbnRlcnZhbC5zdGFydFRpbWU+PTE5NTAtMDEtMDFUMDE6MDE6
MjUuNzcxWicuIFlvdSBjYW4gZmlsdGVyIGJ5CiB0eXBlLCBpbnN0YW5jZSwgYmFja3VwSW50
ZXJ2YWwuc3RhcnRUaW1lIChjcmVhdGlvbiB0aW1lKSwgb3IgbG9jYXRpb24uCgoNCgUEAgID
BRIEjQECCAoNCgUEAgIDARIEjQEJDwoNCgUEAgIDAxIEjQESEwpGCgIEAxIGkQEAnAEBGjgg
VGhlIHJlc3BvbnNlIHBheWxvYWQgY29udGFpbmluZyBhIGxpc3Qgb2YgdGhlIGJhY2t1cHMu
CgoLCgMEAwESBJEBCBsKIgoEBAMCABIEkwECHhoUIEEgbGlzdCBvZiBiYWNrdXBzLgoKDQoF
BAMCAAQSBJMBAgoKDQoFBAMCAAYSBJMBCxEKDQoFBAMCAAESBJMBEhkKDQoFBAMCAAMSBJMB
HB0KlQEKBAQDAgESBJcBAh0ahgEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBh
Z2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlz
IG9taXR0ZWQsIHRoZW4gdGhlcmUgYXJlbid0IHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEAwIB
BRIElwECCAoNCgUEAwIBARIElwEJGAoNCgUEAwIBAxIElwEbHApxCgQEAwICEgSbAQIjGmMg
SWYgYSByZWdpb24gaXNuJ3QgdW5hdmFpbGFibGUgb3IgaWYgYW4gdW5rbm93biBlcnJvciBv
Y2N1cnMsIHRoZW4gYSB3YXJuaW5nCiBtZXNzYWdlIGlzIHJldHVybmVkLgoKDQoFBAMCAgQS
BJsBAgoKDQoFBAMCAgYSBJsBCxUKDQoFBAMCAgESBJsBFh4KDQoFBAMCAgMSBJsBISIKOQoC
BAQSBp8BAKgBARorIFRoZSByZXF1ZXN0IHBheWxvYWQgdG8gdXBkYXRlIHRoZSBiYWNrdXAu
CgoLCgMEBAESBJ8BCBsKpAEKBAQEAgASBKMBAj0alQEgUmVxdWlyZWQuIFRoZSBiYWNrdXAg
dG8gdXBkYXRlLgogVGhlIGJhY2t1cOKAmXMgYG5hbWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRl
bnRpZnkgdGhlIGJhY2t1cCB0byB1cGRhdGUuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0
fS9iYWNrdXBzL3tiYWNrdXB9CgoNCgUEBAIABhIEowECCAoNCgUEBAIAARIEowEJDwoNCgUE
BAIAAxIEowESEwoNCgUEBAIACBIEowEUPAoQCggEBAIACJwIABIEowEVOwqGAQoEBAQCARIE
pwECLBp4IFRoZSBsaXN0IG9mIGZpZWxkcyB0aGF0IHlvdSBjYW4gdXBkYXRlLiBZb3UgY2Fu
IHVwZGF0ZSBvbmx5IHRoZSBkZXNjcmlwdGlvbgogYW5kIHJldGVudGlvbiBwZXJpb2Qgb2Yg
dGhlIGZpbmFsIGJhY2t1cC4KCg0KBQQEAgEGEgSnAQIbCg0KBQQEAgEBEgSnARwnCg0KBQQE
AgEDEgSnASorCjkKAgQFEgarAQCyAQEaKyBUaGUgcmVxdWVzdCBwYXlsb2FkIHRvIGRlbGV0
ZSB0aGUgYmFja3VwLgoKCwoDBAUBEgSrAQgbCmoKBAQFAgASBq4BArEBBBpaIFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgYmFja3VwIHRvIGRlbGV0ZS4KIEZvcm1hdDogcHJvamVjdHMv
e3Byb2plY3R9L2JhY2t1cHMve2JhY2t1cH0KCg0KBQQFAgAFEgSuAQIICg0KBQQFAgABEgSu
AQkNCg0KBQQFAgADEgSuARARCg8KBQQFAgAIEgauARKxAQMKEAoIBAUCAAicCAASBK8BBCoK
DwoHBAUCAAifCBIEsAEEUAoiCgIEBhIGtQEA0QIBGhQgQSBiYWNrdXAgcmVzb3VyY2UuCgoL
CgMEBgESBLUBCA4KDQoDBAYHEga2AQK5AQQKDwoFBAYHnQgSBrYBArkBBAoiCgQEBgQAEga8
AQLIAQMaEiBUaGUgYmFja3VwIHR5cGUuCgoNCgUEBgQAARIEvAEHFAoxCgYEBgQAAgASBL4B
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
9AEUFQpYCgQEBgIGEgT3AQIWGkogVGhlIHN0b3JhZ2UgbG9jYXRpb24gb2YgdGhlIGJhY2t1
cHMuIFRoZSBsb2NhdGlvbiBjYW4gYmUgbXVsdGktcmVnaW9uYWwuCgoNCgUEBgIGBRIE9wEC
CAoNCgUEBgIGARIE9wEJEQoNCgUEBgIGAxIE9wEUFQrLAQoEBAYCBxIG/AEC/QEyGroBIE91
dHB1dCBvbmx5LiBUaGlzIG91dHB1dCBjb250YWlucyB0aGUgZm9sbG93aW5nIHZhbHVlczoK
IHN0YXJ0X3RpbWU6IEFsbCBkYXRhYmFzZSB3cml0ZXMgdXAgdG8gdGhpcyB0aW1lIGFyZSBh
dmFpbGFibGUuCiBlbmRfdGltZTogQW55IGRhdGFiYXNlIHdyaXRlcyBhZnRlciB0aGlzIHRp
bWUgYXJlbid0IGF2YWlsYWJsZS4KCg0KBQQGAgcGEgT8AQIWCg0KBQQGAgcBEgT8ARcmCg0K
BQQGAgcDEgT8ASkqCg0KBQQGAgcIEgT9AQYxChAKCAQGAgcInAgAEgT9AQcwCjcKBAQGAggS
BIACAkcaKSBPdXRwdXQgb25seS4gVGhlIHN0YXR1cyBvZiB0aGlzIGJhY2t1cC4KCg0KBQQG
AggGEgSAAgIQCg0KBQQGAggBEgSAAhEWCg0KBQQGAggDEgSAAhkaCg0KBQQGAggIEgSAAhtG
ChAKCAQGAggInAgAEgSAAhxFCnoKBAQGAgkSBIQCAkgabCBPdXRwdXQgb25seS4gSW5mb3Jt
YXRpb24gYWJvdXQgd2h5IHRoZSBiYWNrdXAgb3BlcmF0aW9uIGZhaWxzIChmb3IgZXhhbXBs
ZSwKIHdoZW4gdGhlIGJhY2t1cCBzdGF0ZSBmYWlscykuCgoNCgUEBgIJBhIEhAICEAoNCgUE
BgIJARIEhAIRFgoNCgUEBgIJAxIEhAIZGwoNCgUEBgIJCBIEhAIcRwoQCggEBgIJCJwIABIE
hAIdRgqZAQoEBAYCChIGiAICjQIEGogBIE91dHB1dCBvbmx5LiBUaGlzIG91dHB1dCBjb250
YWlucyB0aGUgZW5jcnlwdGlvbiBjb25maWd1cmF0aW9uIGZvciBhIGJhY2t1cAogYW5kIHRo
ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBLTVMga2V5IGZvciBkaXNrIGVuY3J5cHRpb24uCgoN
CgUEBgIKBRIEiAICCAoNCgUEBgIKARIEiAIJEAoNCgUEBgIKAxIEiAITFQoPCgUEBgIKCBIG
iAIWjQIDChAKCAQGAgoInAgAEgSJAgQtChEKBwQGAgoInwgSBooCBIwCBQqmAQoEBAYCCxIG
kQIClgIEGpUBIE91dHB1dCBvbmx5LiBUaGlzIG91dHB1dCBjb250YWlucyB0aGUgZW5jcnlw
dGlvbiBzdGF0dXMgZm9yIGEgYmFja3VwIGFuZAogdGhlIHZlcnNpb24gb2YgdGhlIEtNUyBr
ZXkgdGhhdCdzIHVzZWQgdG8gZW5jcnlwdCB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDQoF
BAYCCwUSBJECAggKDQoFBAYCCwESBJECCRgKDQoFBAYCCwMSBJECGx0KDwoFBAYCCwgSBpEC
HpYCAwoQCggEBgILCJwIABIEkgIELQoRCgcEBgILCJ8IEgaTAgSVAgUKWAoEBAYCDBIEmQIC
TRpKIE91dHB1dCBvbmx5LiBTcGVjaWZpZXMgdGhlIGtpbmQgb2YgYmFja3VwLCBQSFlTSUNB
TCBvciBERUZBVUxUX1NOQVBTSE9ULgoKDQoFBAYCDAYSBJkCAg8KDQoFBAYCDAESBJkCEBsK
DQoFBAYCDAMSBJkCHiAKDQoFBAYCDAgSBJkCIUwKEAoIBAYCDAicCAASBJkCIksK1wEKBAQG
Ag0SBJ4CAkQayAEgT3V0cHV0IG9ubHkuIFRoaXMgb3V0cHV0IGNvbnRhaW5zIGEgYmFja3Vw
IHRpbWUgem9uZS4gSWYgYSBDbG91ZCBTUUwgZm9yCiBTUUwgU2VydmVyIGluc3RhbmNlIGhh
cyBhIGRpZmZlcmVudCB0aW1lIHpvbmUgZnJvbSB0aGUgYmFja3VwJ3MgdGltZSB6b25lLAog
dGhlbiB0aGUgcmVzdG9yZSB0byB0aGUgaW5zdGFuY2UgZG9lc24ndCBoYXBwZW4uCgoNCgUE
BgINBRIEngICCAoNCgUEBgINARIEngIJEgoNCgUEBgINAxIEngIVFwoNCgUEBgINCBIEngIY
QwoQCggEBgINCJwIABIEngIZQgoOCgQEBggAEgagAgKqAgMKDQoFBAYIAAESBKACCBIK7AEK
BAQGAg4SBKUCBEMa3QEgSW5wdXQgb25seS4gVGhlIHRpbWUtdG8tbGl2ZSAoVFRMKSBpbnRl
cnZhbCBmb3IgdGhpcyByZXNvdXJjZSAoaW4gZGF5cykuCiBGb3IgZXhhbXBsZTogdHRsRGF5
czo3LCBtZWFucyA3IGRheXMgZnJvbSB0aGUgY3VycmVudCB0aW1lLiBUaGUKIGV4cGlyYXRp
b24gdGltZSBjYW4ndCBleGNlZWQgMzY1IGRheXMgZnJvbSB0aGUgdGltZSB0aGF0IHRoZSBi
YWNrdXAgaXMKIGNyZWF0ZWQuCgoNCgUEBgIOBRIEpQIECQoNCgUEBgIOARIEpQIKEgoNCgUE
BgIOAxIEpQIVFwoNCgUEBgIOCBIEpQIYQgoQCggEBgIOCJwIABIEpQIZQQpVCgQEBgIPEgSp
AgQvGkcgQmFja3VwIGV4cGlyYXRpb24gdGltZS4KIEEgVVRDIHRpbWVzdGFtcCBvZiB3aGVu
IHRoaXMgYmFja3VwIGV4cGlyZWQuCgoNCgUEBgIPBhIEqQIEHQoNCgUEBgIPARIEqQIeKQoN
CgUEBgIPAxIEqQIsLgppCgQEBgIQEgauAgKvAjIaWSBPdXRwdXQgb25seS4gVGhlIGRhdGFi
YXNlIHZlcnNpb24gb2YgdGhlIGluc3RhbmNlIG9mIGF0IHRoZSB0aW1lIHRoaXMKIGJhY2t1
cCB3YXMgbWFkZS4KCg0KBQQGAhAGEgSuAgIUCg0KBQQGAhABEgSuAhUlCg0KBQQGAhADEgSu
AigqCg0KBQQGAhAIEgSvAgYxChAKCAQGAhAInAgAEgSvAgcwCksKBAQGAhESBrICArMCMho7
IE91dHB1dCBvbmx5LiBUaGUgbWF4aW11bSBjaGFyZ2VhYmxlIGJ5dGVzIGZvciB0aGUgYmFj
a3VwLgoKDQoFBAYCEQQSBLICAgoKDQoFBAYCEQUSBLICCxAKDQoFBAYCEQESBLICESUKDQoF
BAYCEQMSBLICKCoKDQoFBAYCEQgSBLMCBjEKEAoIBAYCEQicCAASBLMCBzAKdwoEBAYCEhIG
twICugIEGmcgT3B0aW9uYWwuIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgaW4gVVRDIG9mIHdo
ZW4gdGhlIGluc3RhbmNlIGFzc29jaWF0ZWQKIHdpdGggdGhpcyBiYWNrdXAgaXMgZGVsZXRl
ZC4KCg0KBQQGAhIGEgS3AgIbCg0KBQQGAhIBEgS3AhwyCg0KBQQGAhIDEgS3AjU3Cg8KBQQG
AhIIEga3Aji6AgMKEAoIBAYCEgicCAASBLgCBCoKEAoIBAYCEgicCAESBLkCBC0KeQoEBAYC
ExIGvgICwQIEGmkgT3B0aW9uYWwuIE91dHB1dCBvbmx5LiBUaGUgaW5zdGFuY2Ugc2V0dGlu
ZyBvZiB0aGUgc291cmNlIGluc3RhbmNlIHRoYXQncwogYXNzb2NpYXRlZCB3aXRoIHRoaXMg
YmFja3VwLgoKDQoFBAYCEwYSBL4CAhIKDQoFBAYCEwESBL4CEyQKDQoFBAYCEwMSBL4CJykK
DwoFBAYCEwgSBr4CKsECAwoQCggEBgITCJwIABIEvwIEKgoQCggEBgITCJwIARIEwAIELQpZ
CgQEBgIUEgTEAgJFGksgT3V0cHV0IG9ubHkuIFRoZSBtYXBwaW5nIHRvIGJhY2t1cCBydW4g
cmVzb3VyY2UgdXNlZCBmb3IgSUFNIHZhbGlkYXRpb25zLgoKDQoFBAYCFAUSBMQCAggKDQoF
BAYCFAESBMQCCRMKDQoFBAYCFAMSBMQCFhgKDQoFBAYCFAgSBMQCGUQKEAoIBAYCFAicCAAS
BMQCGkMKfwoEBAYCFRIGyQICygIyGm8gT3V0cHV0IG9ubHkuIFRoaXMgc3RhdHVzIGluZGlj
YXRlcyB3aGV0aGVyIHRoZSBiYWNrdXAgc2F0aXNmaWVzIFBaUy4KCiBUaGUgc3RhdHVzIGlz
IHJlc2VydmVkIGZvciBmdXR1cmUgdXNlLgoKDQoFBAYCFQYSBMkCAhsKDQoFBAYCFQESBMkC
HCkKDQoFBAYCFQMSBMkCLC4KDQoFBAYCFQgSBMoCBjEKEAoIBAYCFQicCAASBMoCBzAKfwoE
BAYCFhIGzwIC0AIyGm8gT3V0cHV0IG9ubHkuIFRoaXMgc3RhdHVzIGluZGljYXRlcyB3aGV0
aGVyIHRoZSBiYWNrdXAgc2F0aXNmaWVzIFBaSS4KCiBUaGUgc3RhdHVzIGlzIHJlc2VydmVk
IGZvciBmdXR1cmUgdXNlLgoKDQoFBAYCFgYSBM8CAhsKDQoFBAYCFgESBM8CHCkKDQoFBAYC
FgMSBM8CLC4KDQoFBAYCFggSBNACBjEKEAoIBAYCFgicCAASBNACBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest ===
    # Fields for CreateBackupRequest
    # Field: parent Type: 9 ()
    # Field: backup Type: 11 (.google.cloud.sql.v1.Backup)

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest ===
    # Fields for GetBackupRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest ===
    # Fields for ListBackupsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse ===
    # Fields for ListBackupsResponse
    # Field: backups Type: 11 (.google.cloud.sql.v1.Backup)
    # Field: next_page_token Type: 9 ()
    # Field: warnings Type: 11 (.google.cloud.sql.v1.ApiWarning)

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest ===
    # Fields for UpdateBackupRequest
    # Field: backup Type: 11 (.google.cloud.sql.v1.Backup)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest ===
    # Fields for DeleteBackupRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlBackups::Backup ===
    # Fields for Backup
    # Field: name Type: 9 ()
    # Field: kind Type: 9 ()
    # Field: self_link Type: 9 ()
    # Field: type Type: 14 (.google.cloud.sql.v1.Backup.SqlBackupType)
    # Field: description Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: location Type: 9 ()
    # Field: backup_interval Type: 11 (.google.type.Interval)
    # Field: state Type: 14 (.google.cloud.sql.v1.Backup.SqlBackupState)
    # Field: error Type: 11 (.google.cloud.sql.v1.OperationError)
    # Field: kms_key Type: 9 ()
    # Field: kms_key_version Type: 9 ()
    # Field: backup_kind Type: 14 (.google.cloud.sql.v1.SqlBackupKind)
    # Field: time_zone Type: 9 ()
    # Field: ttl_days Type: 3 ()
    # Field: expiry_time Type: 11 (.google.protobuf.Timestamp)
    # Field: database_version Type: 14 (.google.cloud.sql.v1.SqlDatabaseVersion)
    # Field: max_chargeable_bytes Type: 3 ()
    # Field: instance_deletion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance_settings Type: 11 (.google.cloud.sql.v1.DatabaseInstance)
    # Field: backup_run Type: 9 ()
    # Field: satisfies_pzs Type: 11 (.google.protobuf.BoolValue)
    # Field: satisfies_pzi Type: 11 (.google.protobuf.BoolValue)

# Enum: Backup::SqlBackupType
our $Backup_SQL_BACKUP_TYPE_UNSPECIFIED = 0;
our $Backup_AUTOMATED = 1;
our $Backup_ON_DEMAND = 2;
our $Backup_FINAL = 3;

# Enum: Backup::SqlBackupState
our $Backup_SQL_BACKUP_STATE_UNSPECIFIED = 0;
our $Backup_ENQUEUED = 1;
our $Backup_RUNNING = 2;
our $Backup_FAILED = 3;
our $Backup_SUCCESSFUL = 4;
our $Backup_DELETING = 5;
our $Backup_DELETION_FAILED = 6;

# === Service Client: Google::Cloud::Sql::V1::CloudSqlBackups::SqlBackupsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlBackups::SqlBackupsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1::CloudSqlBackups::SqlBackupsServiceClient

Client stub representing the remote C<SqlBackupsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'sql.googleapis.com:443' );

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

sub create_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'CreateBackup',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub get_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'GetBackup',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlBackups::Backup',
    });
}

sub list_backups {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'ListBackups',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse',
    });
}

sub update_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'UpdateBackup',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub delete_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupsService',
        method         => 'DeleteBackup',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups - Compiled Protocol Buffers messages for google/cloud/sql/v1/cloud_sql_backups.proto

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackups;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest->new({
        parent => $parent,
        backup => $backup,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1/cloud_sql_backups.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest

The request payload to create the backup

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this backup is created.
Format: projects/{project}

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlBackups::Backup>)

Required. The Backup to create.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest

The request payload to get the backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the backup to retrieve.
Format: projects/{project}/backups/{backup}

=back

=head2 Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest

The request payload to list the backups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent that owns this collection of backups.
Format: projects/{project}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of backups to return per response. The service might
return fewer backups than this value. If a value for this parameter isn't
specified, then, at most, 500 backups are returned. The maximum value is
2,000. Any values that you set, which are greater than 2,000, are changed
to 2,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListBackups` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListBackups` must match
the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Multiple filter queries are separated by spaces. For example,
'instance:abc AND type:FINAL, 'location:us',
'backupInterval.startTime>=1950-01-01T01:01:25.771Z'. You can filter by
type, instance, backupInterval.startTime (creation time), or location.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse

The response payload containing a list of the backups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backups() >> / C<< $msg->backups($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlBackups::Backup>)

A list of backups.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, then there aren't subsequent pages.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlResources::ApiWarning>)

If a region isn't unavailable or if an unknown error occurs, then a warning
message is returned.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest

The request payload to update the backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlBackups::Backup>)

Required. The backup to update.
The backup’s `name` field is used to identify the backup to update.
Format: projects/{project}/backups/{backup}

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields that you can update. You can update only the description
and retention period of the final backup.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest

The request payload to delete the backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the backup to delete.
Format: projects/{project}/backups/{backup}

=back

=head2 Google::Cloud::Sql::V1::CloudSqlBackups::Backup

A backup resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the backup.
Format: projects/{project}/backups/{backup}.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

Output only. This is always `sql#backup`.

=item * C<< $msg->self_link() >> / C<< $msg->self_link($value) >>

Type: C<String>

Output only. The URI of this resource.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::Backup::SqlBackupType>)

Output only. The type of this backup. The type can be "AUTOMATED",
"ON_DEMAND" or “FINAL”.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of this backup.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

The name of the source database instance.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The storage location of the backups. The location can be multi-regional.

=item * C<< $msg->backup_interval() >> / C<< $msg->backup_interval($value) >>

Type: C<Message> (L<Google::Type::Interval::Interval>)

Output only. This output contains the following values:
start_time: All database writes up to this time are available.
end_time: Any database writes after this time aren't available.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::Backup::SqlBackupState>)

Output only. The status of this backup.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlResources::OperationError>)

Output only. Information about why the backup operation fails (for example,
when the backup state fails).

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Output only. This output contains the encryption configuration for a backup
and the resource name of the KMS key for disk encryption.

=item * C<< $msg->kms_key_version() >> / C<< $msg->kms_key_version($value) >>

Type: C<String>

Output only. This output contains the encryption status for a backup and
the version of the KMS key that's used to encrypt the Cloud SQL instance.

=item * C<< $msg->backup_kind() >> / C<< $msg->backup_kind($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::SqlBackupKind>)

Output only. Specifies the kind of backup, PHYSICAL or DEFAULT_SNAPSHOT.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Output only. This output contains a backup time zone. If a Cloud SQL for
SQL Server instance has a different time zone from the backup's time zone,
then the restore to the instance doesn't happen.

=item * C<< $msg->ttl_days() >> / C<< $msg->ttl_days($value) >>

Type: C<Int64>

Input only. The time-to-live (TTL) interval for this resource (in days).
For example: ttlDays:7, means 7 days from the current time. The
expiration time can't exceed 365 days from the time that the backup is
created.

=item * C<< $msg->expiry_time() >> / C<< $msg->expiry_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Backup expiration time.
A UTC timestamp of when this backup expired.

=item * C<< $msg->database_version() >> / C<< $msg->database_version($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::SqlDatabaseVersion>)

Output only. The database version of the instance of at the time this
backup was made.

=item * C<< $msg->max_chargeable_bytes() >> / C<< $msg->max_chargeable_bytes($value) >>

Type: C<Int64>

Output only. The maximum chargeable bytes for the backup.

=item * C<< $msg->instance_deletion_time() >> / C<< $msg->instance_deletion_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Output only. Timestamp in UTC of when the instance associated
with this backup is deleted.

=item * C<< $msg->instance_settings() >> / C<< $msg->instance_settings($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance>)

Optional. Output only. The instance setting of the source instance that's
associated with this backup.

=item * C<< $msg->backup_run() >> / C<< $msg->backup_run($value) >>

Type: C<String>

Output only. The mapping to backup run resource used for IAM validations.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::BoolValue>)

Output only. This status indicates whether the backup satisfies PZS.

The status is reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::BoolValue>)

Output only. This status indicates whether the backup satisfies PZI.

The status is reserved for future use.

=back

=head3 Enum: Backup::SqlBackupType

=over 4

=item * C<SQL_BACKUP_TYPE_UNSPECIFIED> => C<0>

=item * C<AUTOMATED> => C<1>

=item * C<ON_DEMAND> => C<2>

=item * C<FINAL> => C<3>

=back

=head3 Enum: Backup::SqlBackupState

=over 4

=item * C<SQL_BACKUP_STATE_UNSPECIFIED> => C<0>

=item * C<ENQUEUED> => C<1>

=item * C<RUNNING> => C<2>

=item * C<FAILED> => C<3>

=item * C<SUCCESSFUL> => C<4>

=item * C<DELETING> => C<5>

=item * C<DELETION_FAILED> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1::CloudSqlBackups::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
