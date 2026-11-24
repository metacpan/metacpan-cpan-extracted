package Google::Cloud::Sql::V1beta4::CloudSqlUsers;

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
    eval { require Google::Cloud::Sql::V1beta4::CloudSqlResources };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc3FsL3YxYmV0YTQvY2xvdWRfc3FsX3VzZXJzLnByb3RvEhhnb29n
bGUuY2xvdWQuc3FsLnYxYmV0YTQaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dv
b2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
GjJnb29nbGUvY2xvdWQvc3FsL3YxYmV0YTQvY2xvdWRfc3FsX3Jlc291cmNlcy5wcm90bxoe
Z29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvIpYBChVTcWxVc2Vyc0RlbGV0ZVJlcXVlc3QSEgoEaG9zdBgBIAEoCVIEaG9z
dBIaCghpbnN0YW5jZRgCIAEoCVIIaW5zdGFuY2USEgoEbmFtZRgDIAEoCVIEbmFtZRIYCgdw
cm9qZWN0GAQgASgJUgdwcm9qZWN0Eh8KCGxvY2F0aW9uGAUgASgJQgPgQQFSCGxvY2F0aW9u
IpMBChJTcWxVc2Vyc0dldFJlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlSCGluc3RhbmNlEhIK
BG5hbWUYAiABKAlSBG5hbWUSGAoHcHJvamVjdBgDIAEoCVIHcHJvamVjdBISCgRob3N0GAQg
ASgJUgRob3N0Eh8KCGxvY2F0aW9uGAUgASgJQgPgQQFSCGxvY2F0aW9uIqIBChVTcWxVc2Vy
c0luc2VydFJlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QY
AiABKAlSB3Byb2plY3QSMgoEYm9keRhkIAEoCzIeLmdvb2dsZS5jbG91ZC5zcWwudjFiZXRh
NC5Vc2VyUgRib2R5Eh8KCGxvY2F0aW9uGAMgASgJQgPgQQFSCGxvY2F0aW9uImwKE1NxbFVz
ZXJzTGlzdFJlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QY
AiABKAlSB3Byb2plY3QSHwoIbG9jYXRpb24YAyABKAlCA+BBAVIIbG9jYXRpb24i5wMKFVNx
bFVzZXJzVXBkYXRlUmVxdWVzdBIXCgRob3N0GAEgASgJQgPgQQFSBGhvc3QSGgoIaW5zdGFu
Y2UYAiABKAlSCGluc3RhbmNlEhIKBG5hbWUYAyABKAlSBG5hbWUSGAoHcHJvamVjdBgEIAEo
CVIHcHJvamVjdBIqCg5kYXRhYmFzZV9yb2xlcxgFIAMoCUID4EEBUg1kYXRhYmFzZVJvbGVz
EjwKFXJldm9rZV9leGlzdGluZ19yb2xlcxgGIAEoCEID4EEBSABSE3Jldm9rZUV4aXN0aW5n
Um9sZXOIAQESJgoMc2VydmVyX3JvbGVzGAcgAygJQgPgQQFSC3NlcnZlclJvbGVzEkkKHHJl
dm9rZV9leGlzdGluZ19zZXJ2ZXJfcm9sZXMYCCABKAhCA+BBAUgBUhlyZXZva2VFeGlzdGlu
Z1NlcnZlclJvbGVziAEBEjIKBGJvZHkYZCABKAsyHi5nb29nbGUuY2xvdWQuc3FsLnYxYmV0
YTQuVXNlclIEYm9keRIfCghsb2NhdGlvbhgJIAEoCUID4EEBUghsb2NhdGlvbkIYChZfcmV2
b2tlX2V4aXN0aW5nX3JvbGVzQh8KHV9yZXZva2VfZXhpc3Rpbmdfc2VydmVyX3JvbGVzIv0C
ChxVc2VyUGFzc3dvcmRWYWxpZGF0aW9uUG9saWN5EjYKF2FsbG93ZWRfZmFpbGVkX2F0dGVt
cHRzGAEgASgFUhVhbGxvd2VkRmFpbGVkQXR0ZW1wdHMSWwoccGFzc3dvcmRfZXhwaXJhdGlv
bl9kdXJhdGlvbhgCIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIacGFzc3dvcmRF
eHBpcmF0aW9uRHVyYXRpb24SPwocZW5hYmxlX2ZhaWxlZF9hdHRlbXB0c19jaGVjaxgDIAEo
CFIZZW5hYmxlRmFpbGVkQXR0ZW1wdHNDaGVjaxJFCgZzdGF0dXMYBCABKAsyKC5nb29nbGUu
Y2xvdWQuc3FsLnYxYmV0YTQuUGFzc3dvcmRTdGF0dXNCA+BBA1IGc3RhdHVzEkAKHGVuYWJs
ZV9wYXNzd29yZF92ZXJpZmljYXRpb24YBSABKAhSGmVuYWJsZVBhc3N3b3JkVmVyaWZpY2F0
aW9uIn4KDlBhc3N3b3JkU3RhdHVzEhYKBmxvY2tlZBgBIAEoCFIGbG9ja2VkElQKGHBhc3N3
b3JkX2V4cGlyYXRpb25fdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
FnBhc3N3b3JkRXhwaXJhdGlvblRpbWUiyQkKBFVzZXISEgoEa2luZBgBIAEoCVIEa2luZBIa
CghwYXNzd29yZBgCIAEoCVIIcGFzc3dvcmQSEgoEZXRhZxgDIAEoCVIEZXRhZxISCgRuYW1l
GAQgASgJUgRuYW1lEhcKBGhvc3QYBSABKAlCA+BBAVIEaG9zdBIaCghpbnN0YW5jZRgGIAEo
CVIIaW5zdGFuY2USGAoHcHJvamVjdBgHIAEoCVIHcHJvamVjdBI+CgR0eXBlGAggASgOMiou
Z29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlVzZXIuU3FsVXNlclR5cGVSBHR5cGUSZgoWc3Fs
c2VydmVyX3VzZXJfZGV0YWlscxgJIAEoCzIuLmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5T
cWxTZXJ2ZXJVc2VyRGV0YWlsc0gAUhRzcWxzZXJ2ZXJVc2VyRGV0YWlscxIgCglpYW1fZW1h
aWwYCyABKAlCA+BBAVIIaWFtRW1haWwSXwoPcGFzc3dvcmRfcG9saWN5GAwgASgLMjYuZ29v
Z2xlLmNsb3VkLnNxbC52MWJldGE0LlVzZXJQYXNzd29yZFZhbGlkYXRpb25Qb2xpY3lSDnBh
c3N3b3JkUG9saWN5EmIKEmR1YWxfcGFzc3dvcmRfdHlwZRgNIAEoDjIvLmdvb2dsZS5jbG91
ZC5zcWwudjFiZXRhNC5Vc2VyLkR1YWxQYXNzd29yZFR5cGVIAVIQZHVhbFBhc3N3b3JkVHlw
ZYgBARJMCgppYW1fc3RhdHVzGA4gASgOMiguZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlVz
ZXIuSWFtU3RhdHVzSAJSCWlhbVN0YXR1c4gBARIqCg5kYXRhYmFzZV9yb2xlcxgPIAMoCUID
4EEBUg1kYXRhYmFzZVJvbGVzEiYKDHNlcnZlcl9yb2xlcxgQIAMoCUID4EEBUgtzZXJ2ZXJS
b2xlcyLxAQoLU3FsVXNlclR5cGUSDAoIQlVJTFRfSU4QABISCg5DTE9VRF9JQU1fVVNFUhAB
Eh0KGUNMT1VEX0lBTV9TRVJWSUNFX0FDQ09VTlQQAhITCg9DTE9VRF9JQU1fR1JPVVAQAxIY
ChRDTE9VRF9JQU1fR1JPVVBfVVNFUhAEEiMKH0NMT1VEX0lBTV9HUk9VUF9TRVJWSUNFX0FD
Q09VTlQQBRIgChxDTE9VRF9JQU1fV09SS0ZPUkNFX0lERU5USVRZEAYSEAoMRU5UUkFJRF9V
U0VSEAcSGQoVQUNUSVZFX0RJUkVDVE9SWV9VU0VSEAgifAoQRHVhbFBhc3N3b3JkVHlwZRIi
Ch5EVUFMX1BBU1NXT1JEX1RZUEVfVU5TUEVDSUZJRUQQABIbChdOT19NT0RJRllfRFVBTF9Q
QVNTV09SRBABEhQKEE5PX0RVQUxfUEFTU1dPUkQQAhIRCg1EVUFMX1BBU1NXT1JEEAMiQQoJ
SWFtU3RhdHVzEhoKFklBTV9TVEFUVVNfVU5TUEVDSUZJRUQQABIMCghJTkFDVElWRRABEgoK
BkFDVElWRRACQg4KDHVzZXJfZGV0YWlsc0IVChNfZHVhbF9wYXNzd29yZF90eXBlQg0KC19p
YW1fc3RhdHVzIlUKFFNxbFNlcnZlclVzZXJEZXRhaWxzEhoKCGRpc2FibGVkGAEgASgIUghk
aXNhYmxlZBIhCgxzZXJ2ZXJfcm9sZXMYAiADKAlSC3NlcnZlclJvbGVzIokBChFVc2Vyc0xp
c3RSZXNwb25zZRISCgRraW5kGAEgASgJUgRraW5kEjQKBWl0ZW1zGAIgAygLMh4uZ29vZ2xl
LmNsb3VkLnNxbC52MWJldGE0LlVzZXJSBWl0ZW1zEioKD25leHRfcGFnZV90b2tlbhgDIAEo
CUICGAFSDW5leHRQYWdlVG9rZW4y1AcKD1NxbFVzZXJzU2VydmljZRKiAQoGRGVsZXRlEi8u
Z29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlNxbFVzZXJzRGVsZXRlUmVxdWVzdBojLmdvb2ds
ZS5jbG91ZC5zcWwudjFiZXRhNC5PcGVyYXRpb24iQoLT5JMCPCo6L3NxbC92MWJldGE0L3By
b2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS91c2VycxKeAQoDR2V0Eiwu
Z29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlNxbFVzZXJzR2V0UmVxdWVzdBoeLmdvb2dsZS5j
bG91ZC5zcWwudjFiZXRhNC5Vc2VyIkmC0+STAkMSQS9zcWwvdjFiZXRhNC9wcm9qZWN0cy97
cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vdXNlcnMve25hbWV9EqgBCgZJbnNlcnQS
Ly5nb29nbGUuY2xvdWQuc3FsLnYxYmV0YTQuU3FsVXNlcnNJbnNlcnRSZXF1ZXN0GiMuZ29v
Z2xlLmNsb3VkLnNxbC52MWJldGE0Lk9wZXJhdGlvbiJIgtPkkwJCIjovc3FsL3YxYmV0YTQv
cHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L3VzZXJzOgRib2R5EqYB
CgRMaXN0Ei0uZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlNxbFVzZXJzTGlzdFJlcXVlc3Qa
Ky5nb29nbGUuY2xvdWQuc3FsLnYxYmV0YTQuVXNlcnNMaXN0UmVzcG9uc2UiQoLT5JMCPBI6
L3NxbC92MWJldGE0L3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS91
c2VycxKoAQoGVXBkYXRlEi8uZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlNxbFVzZXJzVXBk
YXRlUmVxdWVzdBojLmdvb2dsZS5jbG91ZC5zcWwudjFiZXRhNC5PcGVyYXRpb24iSILT5JMC
Qho6L3NxbC92MWJldGE0L3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNl
fS91c2VyczoEYm9keRp8ykEXc3FsYWRtaW4uZ29vZ2xlYXBpcy5jb23SQV9odHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvc3Fsc2VydmljZS5hZG1pbkJkChxjb20uZ29vZ2xlLmNsb3VkLnNx
bC52MWJldGE0QhJDbG91ZFNxbFVzZXJzUHJvdG9QAVouY2xvdWQuZ29vZ2xlLmNvbS9nby9z
cWwvYXBpdjFiZXRhNC9zcWxwYjtzcWxwYkrcXAoHEgUOANsCAQq8BAoBDBIDDgASMrEEIENv
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
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoC
AwISAxQAKQoJCgIDAxIDFQA8CgkKAgMEEgMWACgKCQoCAwUSAxcAKQoICgEIEgMZAEUKCQoC
CAsSAxkARQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADMKCQoCCAgSAxsAMwoICgEI
EgMcADUKCQoCCAESAxwANQomCgIGABIEHwBJARoaIENsb3VkIFNRTCB1c2VycyBzZXJ2aWNl
LgoKCgoDBgABEgMfCBcKCgoDBgADEgMgAj8KDAoFBgADmQgSAyACPwoLCgMGAAMSBCECIzkK
DQoFBgADmggSBCECIzkKOQoEBgACABIEJgIqAxorIERlbGV0ZXMgYSB1c2VyIGZyb20gYSBD
bG91ZCBTUUwgaW5zdGFuY2UuCgoMCgUGAAIAARIDJgYMCgwKBQYAAgACEgMmDSIKDAoFBgAC
AAMSAyYtNgoNCgUGAAIABBIEJwQpBgoRCgkGAAIABLDKvCISBCcEKQYKSQoEBgACARIELQIx
Axo7IFJldHJpZXZlcyBhIHJlc291cmNlIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gYWJvdXQg
YSB1c2VyLgoKDAoFBgACAQESAy0GCQoMCgUGAAIBAhIDLQocCgwKBQYAAgEDEgMtJysKDQoF
BgACAQQSBC4EMAYKEQoJBgACAQSwyrwiEgQuBDAGCjsKBAYAAgISBDQCOQMaLSBDcmVhdGVz
IGEgbmV3IHVzZXIgaW4gYSBDbG91ZCBTUUwgaW5zdGFuY2UuCgoMCgUGAAICARIDNAYMCgwK
BQYAAgICEgM0DSIKDAoFBgACAgMSAzQtNgoNCgUGAAICBBIENQQ4BgoRCgkGAAICBLDKvCIS
BDUEOAYKQAoEBgACAxIEPAJAAxoyIExpc3RzIHVzZXJzIGluIHRoZSBzcGVjaWZpZWQgQ2xv
dWQgU1FMIGluc3RhbmNlLgoKDAoFBgACAwESAzwGCgoMCgUGAAIDAhIDPAseCgwKBQYAAgMD
EgM8KToKDQoFBgACAwQSBD0EPwYKEQoJBgACAwSwyrwiEgQ9BD8GCkEKBAYAAgQSBEMCSAMa
MyBVcGRhdGVzIGFuIGV4aXN0aW5nIHVzZXIgaW4gYSBDbG91ZCBTUUwgaW5zdGFuY2UuCgoM
CgUGAAIEARIDQwYMCgwKBQYAAgQCEgNDDSIKDAoFBgACBAMSA0MtNgoNCgUGAAIEBBIERARH
BgoRCgkGAAIEBLDKvCISBEQERwYKCgoCBAASBEsAWgEKCgoDBAABEgNLCB0KMAoEBAACABID
TQISGiMgSG9zdCBvZiB0aGUgdXNlciBpbiB0aGUgaW5zdGFuY2UuCgoMCgUEAAIABRIDTQII
CgwKBQQAAgABEgNNCQ0KDAoFBAACAAMSA00QEQpKCgQEAAIBEgNQAhYaPSBEYXRhYmFzZSBp
bnN0YW5jZSBJRC4gVGhpcyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDAoF
BAACAQUSA1ACCAoMCgUEAAIBARIDUAkRCgwKBQQAAgEDEgNQFBUKMAoEBAACAhIDUwISGiMg
TmFtZSBvZiB0aGUgdXNlciBpbiB0aGUgaW5zdGFuY2UuCgoMCgUEAAICBRIDUwIICgwKBQQA
AgIBEgNTCQ0KDAoFBAACAgMSA1MQEQpECgQEAAIDEgNWAhUaNyBQcm9qZWN0IElEIG9mIHRo
ZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAACAwUSA1YCCAoM
CgUEAAIDARIDVgkQCgwKBQQAAgMDEgNWExQKOgoEBAACBBIDWQI/Gi0gT3B0aW9uYWwuIFJl
Z2lvbiBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDAoFBAACBAUSA1kCCAoMCgUEAAIE
ARIDWQkRCgwKBQQAAgQDEgNZFBUKDAoFBAACBAgSA1kWPgoPCggEAAIECJwIABIDWRc9Ci8K
AgQBEgRdAGwBGiMgUmVxdWVzdCBtZXNzYWdlIGZvciBVc2VycyBHZXQgUlBDCgoKCgMEAQES
A10IGgpKCgQEAQIAEgNfAhYaPSBEYXRhYmFzZSBpbnN0YW5jZSBJRC4gVGhpcyBkb2VzIG5v
dCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDAoFBAECAAUSA18CCAoMCgUEAQIAARIDXwkR
CgwKBQQBAgADEgNfFBUKJAoEBAECARIDYgISGhcgVXNlciBvZiB0aGUgaW5zdGFuY2UuCgoM
CgUEAQIBBRIDYgIICgwKBQQBAgEBEgNiCQ0KDAoFBAECAQMSA2IQEQpECgQEAQICEgNlAhUa
NyBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNl
LgoKDAoFBAECAgUSA2UCCAoMCgUEAQICARIDZQkQCgwKBQQBAgIDEgNlExQKLgoEBAECAxID
aAISGiEgSG9zdCBvZiBhIHVzZXIgb2YgdGhlIGluc3RhbmNlLgoKDAoFBAECAwUSA2gCCAoM
CgUEAQIDARIDaAkNCgwKBQQBAgMDEgNoEBEKOgoEBAECBBIDawI/Gi0gT3B0aW9uYWwuIFJl
Z2lvbiBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDAoFBAECBAUSA2sCCAoMCgUEAQIE
ARIDawkRCgwKBQQBAgQDEgNrFBUKDAoFBAECBAgSA2sWPgoPCggEAQIECJwIABIDaxc9CgoK
AgQCEgRuAHkBCgoKAwQCARIDbggdCkoKBAQCAgASA3ACFho9IERhdGFiYXNlIGluc3RhbmNl
IElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAgIABRID
cAIICgwKBQQCAgABEgNwCREKDAoFBAICAAMSA3AUFQpECgQEAgIBEgNzAhUaNyBQcm9qZWN0
IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAIC
AQUSA3MCCAoMCgUEAgIBARIDcwkQCgwKBQQCAgEDEgNzExQKCwoEBAICAhIDdQISCgwKBQQC
AgIGEgN1AgYKDAoFBAICAgESA3UHCwoMCgUEAgICAxIDdQ4RCjoKBAQCAgMSA3gCPxotIE9w
dGlvbmFsLiBSZWdpb24gb2YgdGhlIENsb3VkIFNRTCBpbnN0YW5jZS4KCgwKBQQCAgMFEgN4
AggKDAoFBAICAwESA3gJEQoMCgUEAgIDAxIDeBQVCgwKBQQCAgMIEgN4Fj4KDwoIBAICAwic
CAASA3gXPQoLCgIEAxIFewCEAQEKCgoDBAMBEgN7CBsKSgoEBAMCABIDfQIWGj0gRGF0YWJh
c2UgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4K
CgwKBQQDAgAFEgN9AggKDAoFBAMCAAESA30JEQoMCgUEAwIAAxIDfRQVCkUKBAQDAgESBIAB
AhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3Rh
bmNlLgoKDQoFBAMCAQUSBIABAggKDQoFBAMCAQESBIABCRAKDQoFBAMCAQMSBIABExQKOwoE
BAMCAhIEgwECPxotIE9wdGlvbmFsLiBSZWdpb24gb2YgdGhlIENsb3VkIFNRTCBpbnN0YW5j
ZS4KCg0KBQQDAgIFEgSDAQIICg0KBQQDAgIBEgSDAQkRCg0KBQQDAgIDEgSDARQVCg0KBQQD
AgIIEgSDARY+ChAKCAQDAgIInAgAEgSDARc9CgwKAgQEEgaGAQCsAQEKCwoDBAQBEgSGAQgd
CjsKBAQEAgASBIgBAjsaLSBPcHRpb25hbC4gSG9zdCBvZiB0aGUgdXNlciBpbiB0aGUgaW5z
dGFuY2UuCgoNCgUEBAIABRIEiAECCAoNCgUEBAIAARIEiAEJDQoNCgUEBAIAAxIEiAEQEQoN
CgUEBAIACBIEiAESOgoQCggEBAIACJwIABIEiAETOQpLCgQEBAIBEgSLAQIWGj0gRGF0YWJh
c2UgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4K
Cg0KBQQEAgEFEgSLAQIICg0KBQQEAgEBEgSLAQkRCg0KBQQEAgEDEgSLARQVCjEKBAQEAgIS
BI4BAhIaIyBOYW1lIG9mIHRoZSB1c2VyIGluIHRoZSBpbnN0YW5jZS4KCg0KBQQEAgIFEgSO
AQIICg0KBQQEAgIBEgSOAQkNCg0KBQQEAgIDEgSOARARCkUKBAQEAgMSBJEBAhUaNyBQcm9q
ZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDQoF
BAQCAwUSBJEBAggKDQoFBAQCAwESBJEBCRAKDQoFBAQCAwMSBJEBExQKfwoEBAQCBBIElQEC
ThpxIE9wdGlvbmFsLiBMaXN0IG9mIGRhdGFiYXNlIHJvbGVzIHRvIGdyYW50IHRvIHRoZSB1
c2VyLiBib2R5LmRhdGFiYXNlX3JvbGVzCiB3aWxsIGJlIGlnbm9yZWQgZm9yIHVwZGF0ZSBy
ZXF1ZXN0LgoKDQoFBAQCBAQSBJUBAgoKDQoFBAQCBAUSBJUBCxEKDQoFBAQCBAESBJUBEiAK
DQoFBAQCBAMSBJUBIyQKDQoFBAQCBAgSBJUBJU0KEAoIBAQCBAicCAASBJUBJkwK6wEKBAQE
AgUSBpoBApsBLxraASBPcHRpb25hbC4gU3BlY2lmaWVzIHdoZXRoZXIgdG8gcmV2b2tlIGV4
aXN0aW5nIHJvbGVzIHRoYXQgYXJlIG5vdCBwcmVzZW50CiBpbiB0aGUgYGRhdGFiYXNlX3Jv
bGVzYCBmaWVsZC4gSWYgYGZhbHNlYCBvciB1bnNldCwgdGhlIGRhdGFiYXNlIHJvbGVzCiBz
cGVjaWZpZWQgaW4gYGRhdGFiYXNlX3JvbGVzYCBhcmUgYWRkZWQgdG8gdGhlIHVzZXIncyBl
eGlzdGluZyByb2xlcy4KCg0KBQQEAgUEEgSaAQIKCg0KBQQEAgUFEgSaAQsPCg0KBQQEAgUB
EgSaARAlCg0KBQQEAgUDEgSaASgpCg0KBQQEAgUIEgSbAQYuChAKCAQEAgUInAgAEgSbAQct
CtIBCgQEBAIGEgSgAQJMGsMBIE9wdGlvbmFsLiBUaGUgc2VydmVyIHJvbGVzIHRvIGdyYW50
IHRvIHRoZSBTUUwgU2VydmVyIGxvZ2luLiBFeGlzdGluZwogc2VydmVyIHJvbGVzIHdpbGwg
bm90IGJlIHJldm9rZWQgaWYgcmV2b2tlX2V4aXN0aW5nX3JvbGVzIGlzIGZhbHNlLgogYm9k
eS5zZXJ2ZXJfcm9sZXMgd2lsbCBiZSBpZ25vcmVkIGZvciB1cGRhdGUgcmVxdWVzdC4KCg0K
BQQEAgYEEgSgAQIKCg0KBQQEAgYFEgSgAQsRCg0KBQQEAgYBEgSgARIeCg0KBQQEAgYDEgSg
ASEiCg0KBQQEAgYIEgSgASNLChAKCAQEAgYInAgAEgSgASRKCuwBCgQEBAIHEgalAQKmAS8a
2wEgT3B0aW9uYWwuIFNwZWNpZmllcyB3aGV0aGVyIHRvIHJldm9rZSBleGlzdGluZyByb2xl
cyB0aGF0IGFyZSBub3QgcHJlc2VudAogaW4gdGhlIGBzZXJ2ZXJfcm9sZXNgIGZpZWxkLiBJ
ZiBgZmFsc2VgIG9yIHVuc2V0LCB0aGUgc2VydmVyIHJvbGVzCiBzcGVjaWZpZWQgaW4gYHNl
cnZlcl9yb2xlc2AgYXJlIGFkZGVkIHRvIHRoZSB1c2VyJ3MgZXhpc3Rpbmcgc2VydmVyIHJv
bGVzLgoKDQoFBAQCBwQSBKUBAgoKDQoFBAQCBwUSBKUBCw8KDQoFBAQCBwESBKUBECwKDQoF
BAQCBwMSBKUBLzAKDQoFBAQCBwgSBKYBBi4KEAoIBAQCBwicCAASBKYBBy0KDAoEBAQCCBIE
qAECEgoNCgUEBAIIBhIEqAECBgoNCgUEBAIIARIEqAEHCwoNCgUEBAIIAxIEqAEOEQo7CgQE
BAIJEgSrAQI/Gi0gT3B0aW9uYWwuIFJlZ2lvbiBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNl
LgoKDQoFBAQCCQUSBKsBAggKDQoFBAQCCQESBKsBCREKDQoFBAQCCQMSBKsBFBUKDQoFBAQC
CQgSBKsBFj4KEAoIBAQCCQicCAASBKsBFz0KNgoCBAUSBq8BAL8BARooIFVzZXIgbGV2ZWwg
cGFzc3dvcmQgdmFsaWRhdGlvbiBwb2xpY3kuCgoLCgMEBQESBK8BCCQKTwoEBAUCABIEsQEC
JBpBIE51bWJlciBvZiBmYWlsZWQgbG9naW4gYXR0ZW1wdHMgYWxsb3dlZCBiZWZvcmUgdXNl
ciBnZXQgbG9ja2VkLgoKDQoFBAUCAAUSBLEBAgcKDQoFBAUCAAESBLEBCB8KDQoFBAUCAAMS
BLEBIiMKPgoEBAUCARIEtAECPBowIEV4cGlyYXRpb24gZHVyYXRpb24gYWZ0ZXIgcGFzc3dv
cmQgaXMgdXBkYXRlZC4KCg0KBQQFAgEGEgS0AQIaCg0KBQQFAgEBEgS0ARs3Cg0KBQQFAgED
EgS0ATo7CkUKBAQFAgISBLcBAigaNyBJZiB0cnVlLCBmYWlsZWQgbG9naW4gYXR0ZW1wdHMg
Y2hlY2sgd2lsbCBiZSBlbmFibGVkLgoKDQoFBAUCAgUSBLcBAgYKDQoFBAUCAgESBLcBByMK
DQoFBAUCAgMSBLcBJicKNwoEBAUCAxIEugECSBopIE91dHB1dCBvbmx5LiBSZWFkLW9ubHkg
cGFzc3dvcmQgc3RhdHVzLgoKDQoFBAUCAwYSBLoBAhAKDQoFBAUCAwESBLoBERcKDQoFBAUC
AwMSBLoBGhsKDQoFBAUCAwgSBLoBHEcKEAoIBAUCAwicCAASBLoBHUYKiQEKBAQFAgQSBL4B
AigaeyBJZiB0cnVlLCB0aGUgdXNlciBtdXN0IHNwZWNpZnkgdGhlIGN1cnJlbnQgcGFzc3dv
cmQgYmVmb3JlIGNoYW5naW5nIHRoZQogcGFzc3dvcmQuIFRoaXMgZmxhZyBpcyBzdXBwb3J0
ZWQgb25seSBmb3IgTXlTUUwuCgoNCgUEBQIEBRIEvgECBgoNCgUEBQIEARIEvgEHIwoNCgUE
BQIEAxIEvgEmJwoqCgIEBhIGwgEAyAEBGhwgUmVhZC1vbmx5IHBhc3N3b3JkIHN0YXR1cy4K
CgsKAwQGARIEwgEIFgo9CgQEBgIAEgTEAQISGi8gSWYgdHJ1ZSwgdXNlciBkb2VzIG5vdCBo
YXZlIGxvZ2luIHByaXZpbGVnZXMuCgoNCgUEBgIABRIExAECBgoNCgUEBgIAARIExAEHDQoN
CgUEBgIAAxIExAEQEQo8CgQEBgIBEgTHAQI5Gi4gVGhlIGV4cGlyYXRpb24gdGltZSBvZiB0
aGUgY3VycmVudCBwYXNzd29yZC4KCg0KBQQGAgEGEgTHAQIbCg0KBQQGAgEBEgTHARw0Cg0K
BQQGAgEDEgTHATc4CioKAgQHEgbLAQDGAgEaHCBBIENsb3VkIFNRTCB1c2VyIHJlc291cmNl
LgoKCwoDBAcBEgTLAQgMCiAKBAQHBAASBs0BAuoBAxoQIFRoZSB1c2VyIHR5cGUuCgoNCgUE
BwQAARIEzQEHEgo0CgYEBwQAAgASBM8BBBEaJCBUaGUgZGF0YWJhc2UncyBidWlsdC1pbiB1
c2VyIHR5cGUuCgoPCgcEBwQAAgABEgTPAQQMCg8KBwQHBAACAAISBM8BDxAKIQoGBAcEAAIB
EgTSAQQXGhEgQ2xvdWQgSUFNIHVzZXIuCgoPCgcEBwQAAgEBEgTSAQQSCg8KBwQHBAACAQIS
BNIBFRYKLAoGBAcEAAICEgTVAQQiGhwgQ2xvdWQgSUFNIHNlcnZpY2UgYWNjb3VudC4KCg8K
BwQHBAACAgESBNUBBB0KDwoHBAcEAAICAhIE1QEgIQo2CgYEBwQAAgMSBNgBBBgaJiBDbG91
ZCBJQU0gZ3JvdXAuIE5vdCB1c2VkIGZvciBsb2dpbi4KCg8KBwQHBAACAwESBNgBBBMKDwoH
BAcEAAIDAhIE2AEWFwpSCgYEBwQAAgQSBNsBBB0aQiBSZWFkLW9ubHkuIExvZ2luIGZvciBh
IHVzZXIgdGhhdCBiZWxvbmdzIHRvIHRoZSBDbG91ZCBJQU0gZ3JvdXAuCgoPCgcEBwQAAgQB
EgTbAQQYCg8KBwQHBAACBAISBNsBGxwKXgoGBAcEAAIFEgTfAQQoGk4gUmVhZC1vbmx5LiBM
b2dpbiBmb3IgYSBzZXJ2aWNlIGFjY291bnQgdGhhdCBiZWxvbmdzIHRvIHRoZQogQ2xvdWQg
SUFNIGdyb3VwLgoKDwoHBAcEAAIFARIE3wEEIwoPCgcEBwQAAgUCEgTfASYnClkKBgQHBAAC
BhIE4wEEJRpJIENsb3VkIElBTSB3b3JrZm9yY2UgaWRlbnRpdHkgbWFuYWdlZCBieSBXb3Jr
Zm9yY2UgSWRlbnRpdHkKIEZlZGVyYXRpb24uCgoPCgcEBwQAAgYBEgTjAQQgCg8KBwQHBAAC
BgISBOMBIyQKKgoGBAcEAAIHEgTmAQQVGhogTWljcm9zb2Z0IEVudHJhIElEIHVzZXIuCgoP
CgcEBwQAAgcBEgTmAQQQCg8KBwQHBAACBwISBOYBExQKKAoGBAcEAAIIEgTpAQQeGhggQWN0
aXZlIERpcmVjdG9yeSB1c2VyLgoKDwoHBAcEAAIIARIE6QEEGQoPCgcEBwQAAggCEgTpARwd
CjAKBAQHBAESBu0BAvkBAxogIFRoZSB0eXBlIG9mIHJldGFpbmVkIHBhc3N3b3JkLgoKDQoF
BAcEAQESBO0BBxcKJAoGBAcEAQIAEgTvAQQnGhQgVGhlIGRlZmF1bHQgdmFsdWUuCgoPCgcE
BwQBAgABEgTvAQQiCg8KBwQHBAECAAISBO8BJSYKQAoGBAcEAQIBEgTyAQQgGjAgRG8gbm90
IHVwZGF0ZSB0aGUgdXNlcidzIGR1YWwgcGFzc3dvcmQgc3RhdHVzLgoKDwoHBAcEAQIBARIE
8gEEGwoPCgcEBwQBAgECEgTyAR4fCkkKBgQHBAECAhIE9QEEGRo5IE5vIGR1YWwgcGFzc3dv
cmQgdXNhYmxlIGZvciBjb25uZWN0aW5nIHVzaW5nIHRoaXMgdXNlci4KCg8KBwQHBAECAgES
BPUBBBQKDwoHBAcEAQICAhIE9QEXGApGCgYEBwQBAgMSBPgBBBYaNiBEdWFsIHBhc3N3b3Jk
IHVzYWJsZSBmb3IgY29ubmVjdGluZyB1c2luZyB0aGlzIHVzZXIuCgoPCgcEBwQBAgMBEgT4
AQQRCg8KBwQHBAECAwISBPgBFBUKVAoEBAcEAhIG/AECigIDGkQgSW5kaWNhdGVzIGlmIGEg
Z3JvdXAgaXMgYXZhaWxhYmxlIGZvciBJQU0gZGF0YWJhc2UgYXV0aGVudGljYXRpb24uCgoN
CgUEBwQCARIE/AEHEAqZAgoGBAcEAgIAEgSCAgQfGogCIFRoZSBkZWZhdWx0IHZhbHVlIGZv
ciB1c2VycyB0aGF0IGFyZSBub3Qgb2YgdHlwZSBDTE9VRF9JQU1fR1JPVVAuCiBPbmx5IENM
T1VEX0lBTV9HUk9VUCB1c2VycyB3aWxsIGJlIGluYWN0aXZlIG9yIGFjdGl2ZS4KIFVzZXJz
IHdpdGggYW4gSWFtU3RhdHVzIG9mIElBTV9TVEFUVVNfVU5TUEVDSUZJRUQgd2lsbCBub3QK
IGRpc3BsYXkgd2hldGhlciB0aGV5IGFyZSBhY3RpdmUgb3IgaW5hY3RpdmUgYXMgdGhhdCBp
cyBub3QgYXBwbGljYWJsZSB0bwogdGhlbS4KCg8KBwQHBAICAAESBIICBBoKDwoHBAcEAgIA
AhIEggIdHgpfCgYEBwQCAgESBIYCBBEaTyBJTkFDVElWRSBpbmRpY2F0ZXMgYSBncm91cCBp
cyBub3QgYXZhaWxhYmxlIGZvciBJQU0gZGF0YWJhc2UKIGF1dGhlbnRpY2F0aW9uLgoKDwoH
BAcEAgIBARIEhgIEDAoPCgcEBwQCAgECEgSGAg8QClgKBgQHBAICAhIEiQIEDxpIIEFDVElW
RSBpbmRpY2F0ZXMgYSBncm91cCBpcyBhdmFpbGFibGUgZm9yIElBTSBkYXRhYmFzZSBhdXRo
ZW50aWNhdGlvbi4KCg8KBwQHBAICAgESBIkCBAoKDwoHBAcEAgICAhIEiQINDgoqCgQEBwIA
EgSNAgISGhwgVGhpcyBpcyBhbHdheXMgYHNxbCN1c2VyYC4KCg0KBQQHAgAFEgSNAgIICg0K
BQQHAgABEgSNAgkNCg0KBQQHAgADEgSNAhARCioKBAQHAgESBJACAhYaHCBUaGUgcGFzc3dv
cmQgZm9yIHRoZSB1c2VyLgoKDQoFBAcCAQUSBJACAggKDQoFBAcCAQESBJACCREKDQoFBAcC
AQMSBJACFBUKXwoEBAcCAhIElAICEhpRIFRoaXMgZmllbGQgaXMgZGVwcmVjYXRlZCBhbmQg
d2lsbCBiZSByZW1vdmVkIGZyb20gYSBmdXR1cmUgdmVyc2lvbiBvZiB0aGUKIEFQSS4KCg0K
BQQHAgIFEgSUAgIICg0KBQQHAgIBEgSUAgkNCg0KBQQHAgIDEgSUAhARCogBCgQEBwIDEgSY
AgISGnogVGhlIG5hbWUgb2YgdGhlIHVzZXIgaW4gdGhlIENsb3VkIFNRTCBpbnN0YW5jZS4g
Q2FuIGJlIG9taXR0ZWQgZm9yCiBgdXBkYXRlYCBiZWNhdXNlIGl0IGlzIGFscmVhZHkgc3Bl
Y2lmaWVkIGluIHRoZSBVUkwuCgoNCgUEBwIDBRIEmAICCAoNCgUEBwIDARIEmAIJDQoNCgUE
BwIDAxIEmAIQEQrZAgoEBAcCBBIEnwICOxrKAiBPcHRpb25hbC4gVGhlIGhvc3QgZnJvbSB3
aGljaCB0aGUgdXNlciBjYW4gY29ubmVjdC4gRm9yIGBpbnNlcnRgCiBvcGVyYXRpb25zLCBo
b3N0IGRlZmF1bHRzIHRvIGFuIGVtcHR5IHN0cmluZy4gRm9yIGB1cGRhdGVgCiBvcGVyYXRp
b25zLCBob3N0IGlzIHNwZWNpZmllZCBhcyBwYXJ0IG9mIHRoZSByZXF1ZXN0IFVSTC4gVGhl
IGhvc3QgbmFtZQogY2Fubm90IGJlIHVwZGF0ZWQgYWZ0ZXIgaW5zZXJ0aW9uLiAgRm9yIGEg
TXlTUUwgaW5zdGFuY2UsIGl0J3MgcmVxdWlyZWQ7CiBmb3IgYSBQb3N0Z3JlU1FMIG9yIFNR
TCBTZXJ2ZXIgaW5zdGFuY2UsIGl0J3Mgb3B0aW9uYWwuCgoNCgUEBwIEBRIEnwICCAoNCgUE
BwIEARIEnwIJDQoNCgUEBwIEAxIEnwIQEQoNCgUEBwIECBIEnwISOgoQCggEBwIECJwIABIE
nwITOQqpAQoEBAcCBRIEpAICFhqaASBUaGUgbmFtZSBvZiB0aGUgQ2xvdWQgU1FMIGluc3Rh
bmNlLiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCiBDYW4gYmUgb21p
dHRlZCBmb3IgPGI+dXBkYXRlPC9iPiBiZWNhdXNlIGl0IGlzIGFscmVhZHkgc3BlY2lmaWVk
IG9uIHRoZQogVVJMLgoKDQoFBAcCBQUSBKQCAggKDQoFBAcCBQESBKQCCREKDQoFBAcCBQMS
BKQCFBUK0gEKBAQHAgYSBKkCAhUawwEgVGhlIHByb2plY3QgSUQgb2YgdGhlIHByb2plY3Qg
Y29udGFpbmluZyB0aGUgQ2xvdWQgU1FMIGRhdGFiYXNlLiBUaGUgR29vZ2xlCiBhcHBzIGRv
bWFpbiBpcyBwcmVmaXhlZCBpZiBhcHBsaWNhYmxlLiBDYW4gYmUgb21pdHRlZCBmb3IKIDxi
PnVwZGF0ZTwvYj4gYmVjYXVzZSBpdCBpcyBhbHJlYWR5IHNwZWNpZmllZCBvbiB0aGUgVVJM
LgoKDQoFBAcCBgUSBKkCAggKDQoFBAcCBgESBKkCCRAKDQoFBAcCBgMSBKkCExQKkgEKBAQH
AgcSBK0CAhcagwEgVGhlIHVzZXIgdHlwZS4gSXQgZGV0ZXJtaW5lcyB0aGUgbWV0aG9kIHRv
IGF1dGhlbnRpY2F0ZSB0aGUgdXNlciBkdXJpbmcKIGxvZ2luLiBUaGUgZGVmYXVsdCBpcyB0
aGUgZGF0YWJhc2UncyBidWlsdC1pbiB1c2VyIHR5cGUuCgoNCgUEBwIHBhIErQICDQoNCgUE
BwIHARIErQIOEgoNCgUEBwIHAxIErQIVFgo5CgQEBwgAEgawAgKyAgMaKSBVc2VyIGRldGFp
bHMgZm9yIHNwZWNpZmljIGRhdGFiYXNlIHR5cGUKCg0KBQQHCAABEgSwAggUCgwKBAQHAggS
BLECBDQKDQoFBAcCCAYSBLECBBgKDQoFBAcCCAESBLECGS8KDQoFBAcCCAMSBLECMjMKmAEK
BAQHAgkSBLYCAkEaiQEgT3B0aW9uYWwuIFRoZSBmdWxsIGVtYWlsIGZvciBhbiBJQU0gdXNl
ci4gRm9yIG5vcm1hbCBkYXRhYmFzZSB1c2VycywgdGhpcwogd2lsbCBub3QgYmUgZmlsbGVk
LiBPbmx5IGFwcGxpY2FibGUgdG8gTXlTUUwgZGF0YWJhc2UgdXNlcnMuCgoNCgUEBwIJBRIE
tgICCAoNCgUEBwIJARIEtgIJEgoNCgUEBwIJAxIEtgIVFwoNCgUEBwIJCBIEtgIYQAoQCggE
BwIJCJwIABIEtgIZPwo2CgQEBwIKEgS5AgI0GiggVXNlciBsZXZlbCBwYXNzd29yZCB2YWxp
ZGF0aW9uIHBvbGljeS4KCg0KBQQHAgoGEgS5AgIeCg0KBQQHAgoBEgS5Ah8uCg0KBQQHAgoD
EgS5AjEzCjIKBAQHAgsSBLwCAjQaJCBEdWFsIHBhc3N3b3JkIHN0YXR1cyBmb3IgdGhlIHVz
ZXIuCgoNCgUEBwILBBIEvAICCgoNCgUEBwILBhIEvAILGwoNCgUEBwILARIEvAIcLgoNCgUE
BwILAxIEvAIxMwpbCgQEBwIMEgS/AgIlGk0gSW5kaWNhdGVzIGlmIGEgZ3JvdXAgaXMgYWN0
aXZlIG9yIGluYWN0aXZlIGZvciBJQU0gZGF0YWJhc2UgYXV0aGVudGljYXRpb24uCgoNCgUE
BwIMBBIEvwICCgoNCgUEBwIMBhIEvwILFAoNCgUEBwIMARIEvwIVHwoNCgUEBwIMAxIEvwIi
JAo2CgQEBwINEgTCAgJPGiggT3B0aW9uYWwuIFJvbGUgbWVtYmVyc2hpcHMgb2YgdGhlIHVz
ZXIKCg0KBQQHAg0EEgTCAgIKCg0KBQQHAg0FEgTCAgsRCg0KBQQHAg0BEgTCAhIgCg0KBQQH
Ag0DEgTCAiMlCg0KBQQHAg0IEgTCAiZOChAKCAQHAg0InAgAEgTCAidNCkQKBAQHAg4SBMUC
Ak0aNiBPcHRpb25hbC4gVGhlIHNlcnZlciByb2xlcyBmb3IgdGhlIFNRTCBTZXJ2ZXIgbG9n
aW4uCgoNCgUEBwIOBBIExQICCgoNCgUEBwIOBRIExQILEQoNCgUEBwIOARIExQISHgoNCgUE
BwIOAxIExQIhIwoNCgUEBwIOCBIExQIkTAoQCggEBwIOCJwIABIExQIlSwpHCgIECBIGyQIA
zwIBGjkgUmVwcmVzZW50cyBhIFNxbCBTZXJ2ZXIgdXNlciBvbiB0aGUgQ2xvdWQgU1FMIGlu
c3RhbmNlLgoKCwoDBAgBEgTJAggcCjgKBAQIAgASBMsCAhQaKiBJbmRpY2F0ZXMgaWYgdGhl
IHVzZXIgaGFzIGJlZW4gZGlzYWJsZWQuCgoNCgUECAIABRIEywICBgoNCgUECAIAARIEywIH
DwoNCgUECAIAAxIEywISEwo5CgQECAIBEgTOAgIjGisgSW5kaWNhdGVzIHRoZSBzZXJ2ZXIg
cm9sZXMgZm9yIHRoaXMgdXNlci4KCg0KBQQIAgEEEgTOAgIKCg0KBQQIAgEFEgTOAgsRCg0K
BQQIAgEBEgTOAhIeCg0KBQQIAgEDEgTOAiEiCiMKAgQJEgbSAgDbAgEaFSBVc2VyIGxpc3Qg
cmVzcG9uc2UuCgoLCgMECQESBNICCBkKNAoEBAkCABIE1AICEhomIFRoaXMgaXMgYWx3YXlz
IDxiPnNxbCN1c2Vyc0xpc3Q8L2I+LgoKDQoFBAkCAAUSBNQCAggKDQoFBAkCAAESBNQCCQ0K
DQoFBAkCAAMSBNQCEBEKNwoEBAkCARIE1wICGhopIExpc3Qgb2YgdXNlciByZXNvdXJjZXMg
aW4gdGhlIGluc3RhbmNlLgoKDQoFBAkCAQQSBNcCAgoKDQoFBAkCAQYSBNcCCw8KDQoFBAkC
AQESBNcCEBUKDQoFBAkCAQMSBNcCGBkKFwoEBAkCAhIE2gICMRoJIFVudXNlZC4KCg0KBQQJ
AgIFEgTaAgIICg0KBQQJAgIBEgTaAgkYCg0KBQQJAgIDEgTaAhscCg0KBQQJAgIIEgTaAh0w
Cg4KBgQJAgIIAxIE2gIeL2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersDeleteRequest ===
    # Fields for SqlUsersDeleteRequest
    # Field: host Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersGetRequest ===
    # Fields for SqlUsersGetRequest
    # Field: instance Type: 9 ()
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()
    # Field: host Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersInsertRequest ===
    # Fields for SqlUsersInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1beta4.User)
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersListRequest ===
    # Fields for SqlUsersListRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersUpdateRequest ===
    # Fields for SqlUsersUpdateRequest
    # Field: host Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()
    # Field: database_roles Type: 9 ()
    # Field: revoke_existing_roles Type: 8 ()
    # Field: server_roles Type: 9 ()
    # Field: revoke_existing_server_roles Type: 8 ()
    # Field: body Type: 11 (.google.cloud.sql.v1beta4.User)
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::UserPasswordValidationPolicy ===
    # Fields for UserPasswordValidationPolicy
    # Field: allowed_failed_attempts Type: 5 ()
    # Field: password_expiration_duration Type: 11 (.google.protobuf.Duration)
    # Field: enable_failed_attempts_check Type: 8 ()
    # Field: status Type: 11 (.google.cloud.sql.v1beta4.PasswordStatus)
    # Field: enable_password_verification Type: 8 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::PasswordStatus ===
    # Fields for PasswordStatus
    # Field: locked Type: 8 ()
    # Field: password_expiration_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::User ===
    # Fields for User
    # Field: kind Type: 9 ()
    # Field: password Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: name Type: 9 ()
    # Field: host Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: type Type: 14 (.google.cloud.sql.v1beta4.User.SqlUserType)
    # Field: sqlserver_user_details Type: 11 (.google.cloud.sql.v1beta4.SqlServerUserDetails)
    # Field: iam_email Type: 9 ()
    # Field: password_policy Type: 11 (.google.cloud.sql.v1beta4.UserPasswordValidationPolicy)
    # Field: dual_password_type Type: 14 (.google.cloud.sql.v1beta4.User.DualPasswordType)
    # Field: iam_status Type: 14 (.google.cloud.sql.v1beta4.User.IamStatus)
    # Field: database_roles Type: 9 ()
    # Field: server_roles Type: 9 ()

# Enum: User::SqlUserType
our $User_BUILT_IN = 0;
our $User_CLOUD_IAM_USER = 1;
our $User_CLOUD_IAM_SERVICE_ACCOUNT = 2;
our $User_CLOUD_IAM_GROUP = 3;
our $User_CLOUD_IAM_GROUP_USER = 4;
our $User_CLOUD_IAM_GROUP_SERVICE_ACCOUNT = 5;
our $User_CLOUD_IAM_WORKFORCE_IDENTITY = 6;
our $User_ENTRAID_USER = 7;
our $User_ACTIVE_DIRECTORY_USER = 8;

# Enum: User::DualPasswordType
our $User_DUAL_PASSWORD_TYPE_UNSPECIFIED = 0;
our $User_NO_MODIFY_DUAL_PASSWORD = 1;
our $User_NO_DUAL_PASSWORD = 2;
our $User_DUAL_PASSWORD = 3;

# Enum: User::IamStatus
our $User_IAM_STATUS_UNSPECIFIED = 0;
our $User_INACTIVE = 1;
our $User_ACTIVE = 2;

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlServerUserDetails ===
    # Fields for SqlServerUserDetails
    # Field: disabled Type: 8 ()
    # Field: server_roles Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlUsers::UsersListResponse ===
    # Fields for UsersListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1beta4.User)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersServiceClient ===
package Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersServiceClient

Client stub representing the remote C<SqlUsersService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub delete {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersDeleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlUsersService',
        method         => 'Delete',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation',
    });
}

sub get {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersGetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlUsersService',
        method         => 'Get',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlUsers::User',
    });
}

sub insert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersInsertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlUsersService',
        method         => 'Insert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlUsersService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlUsers::UsersListResponse',
    });
}

sub update {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersUpdateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlUsersService',
        method         => 'Update',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlUsers - Compiled Protocol Buffers messages for google/cloud/sql/v1beta4/cloud_sql_users.proto

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1beta4::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersDeleteRequest->new({
        host => $host,
        instance => $instance,
        name => $name,
        project => $project,
    });

    # Read or update a field
    my $val = $msg->host();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersDeleteRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1beta4/cloud_sql_users.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersDeleteRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host of the user in the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Database instance ID. This does not include the project ID.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the user in the instance.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Project ID of the project that contains the instance.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. Region of the Cloud SQL instance.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersGetRequest

Request message for Users Get RPC

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Database instance ID. This does not include the project ID.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

User of the instance.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Project ID of the project that contains the instance.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Host of a user of the instance.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. Region of the Cloud SQL instance.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersInsertRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Database instance ID. This does not include the project ID.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Project ID of the project that contains the instance.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlUsers::User>)

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. Region of the Cloud SQL instance.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersListRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Database instance ID. This does not include the project ID.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Project ID of the project that contains the instance.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. Region of the Cloud SQL instance.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlUsersUpdateRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Optional. Host of the user in the instance.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Database instance ID. This does not include the project ID.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the user in the instance.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Project ID of the project that contains the instance.

=item * C<< $msg->database_roles() >> / C<< $msg->database_roles($value) >>

Type: C<String>

Optional. List of database roles to grant to the user. body.database_roles
will be ignored for update request.

=item * C<< $msg->revoke_existing_roles() >> / C<< $msg->revoke_existing_roles($value) >>

Type: C<Bool>

Optional. Specifies whether to revoke existing roles that are not present
in the `database_roles` field. If `false` or unset, the database roles
specified in `database_roles` are added to the user's existing roles.

=item * C<< $msg->server_roles() >> / C<< $msg->server_roles($value) >>

Type: C<String>

Optional. The server roles to grant to the SQL Server login. Existing
server roles will not be revoked if revoke_existing_roles is false.
body.server_roles will be ignored for update request.

=item * C<< $msg->revoke_existing_server_roles() >> / C<< $msg->revoke_existing_server_roles($value) >>

Type: C<Bool>

Optional. Specifies whether to revoke existing roles that are not present
in the `server_roles` field. If `false` or unset, the server roles
specified in `server_roles` are added to the user's existing server roles.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlUsers::User>)

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. Region of the Cloud SQL instance.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::UserPasswordValidationPolicy

User level password validation policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->allowed_failed_attempts() >> / C<< $msg->allowed_failed_attempts($value) >>

Type: C<Int32>

Number of failed login attempts allowed before user get locked.

=item * C<< $msg->password_expiration_duration() >> / C<< $msg->password_expiration_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Expiration duration after password is updated.

=item * C<< $msg->enable_failed_attempts_check() >> / C<< $msg->enable_failed_attempts_check($value) >>

Type: C<Bool>

If true, failed login attempts check will be enabled.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlUsers::PasswordStatus>)

Output only. Read-only password status.

=item * C<< $msg->enable_password_verification() >> / C<< $msg->enable_password_verification($value) >>

Type: C<Bool>

If true, the user must specify the current password before changing the
password. This flag is supported only for MySQL.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::PasswordStatus

Read-only password status.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->locked() >> / C<< $msg->locked($value) >>

Type: C<Bool>

If true, user does not have login privileges.

=item * C<< $msg->password_expiration_time() >> / C<< $msg->password_expiration_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The expiration time of the current password.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::User

A Cloud SQL user resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

This is always `sql#user`.

=item * C<< $msg->password() >> / C<< $msg->password($value) >>

Type: C<String>

The password for the user.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

This field is deprecated and will be removed from a future version of the
API.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the user in the Cloud SQL instance. Can be omitted for
`update` because it is already specified in the URL.

=item * C<< $msg->host() >> / C<< $msg->host($value) >>

Type: C<String>

Optional. The host from which the user can connect. For `insert`
operations, host defaults to an empty string. For `update`
operations, host is specified as part of the request URL. The host name
cannot be updated after insertion.  For a MySQL instance, it's required;
for a PostgreSQL or SQL Server instance, it's optional.

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

The name of the Cloud SQL instance. This does not include the project ID.
Can be omitted for <b>update</b> because it is already specified on the
URL.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

The project ID of the project containing the Cloud SQL database. The Google
apps domain is prefixed if applicable. Can be omitted for
<b>update</b> because it is already specified on the URL.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::User::SqlUserType>)

The user type. It determines the method to authenticate the user during
login. The default is the database's built-in user type.

=item * C<< $msg->sqlserver_user_details() >> / C<< $msg->sqlserver_user_details($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlServerUserDetails>)

=item * C<< $msg->iam_email() >> / C<< $msg->iam_email($value) >>

Type: C<String>

Optional. The full email for an IAM user. For normal database users, this
will not be filled. Only applicable to MySQL database users.

=item * C<< $msg->password_policy() >> / C<< $msg->password_policy($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlUsers::UserPasswordValidationPolicy>)

User level password validation policy.

=item * C<< $msg->dual_password_type() >> / C<< $msg->dual_password_type($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::User::DualPasswordType>)

Dual password status for the user.

=item * C<< $msg->iam_status() >> / C<< $msg->iam_status($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1beta4::User::IamStatus>)

Indicates if a group is active or inactive for IAM database authentication.

=item * C<< $msg->database_roles() >> / C<< $msg->database_roles($value) >>

Type: C<String>

Optional. Role memberships of the user

=item * C<< $msg->server_roles() >> / C<< $msg->server_roles($value) >>

Type: C<String>

Optional. The server roles for the SQL Server login.

=back

=head3 Enum: User::SqlUserType

=over 4

=item * C<BUILT_IN> => C<0>

=item * C<CLOUD_IAM_USER> => C<1>

=item * C<CLOUD_IAM_SERVICE_ACCOUNT> => C<2>

=item * C<CLOUD_IAM_GROUP> => C<3>

=item * C<CLOUD_IAM_GROUP_USER> => C<4>

=item * C<CLOUD_IAM_GROUP_SERVICE_ACCOUNT> => C<5>

=item * C<CLOUD_IAM_WORKFORCE_IDENTITY> => C<6>

=item * C<ENTRAID_USER> => C<7>

=item * C<ACTIVE_DIRECTORY_USER> => C<8>

=back

=head3 Enum: User::DualPasswordType

=over 4

=item * C<DUAL_PASSWORD_TYPE_UNSPECIFIED> => C<0>

=item * C<NO_MODIFY_DUAL_PASSWORD> => C<1>

=item * C<NO_DUAL_PASSWORD> => C<2>

=item * C<DUAL_PASSWORD> => C<3>

=back

=head3 Enum: User::IamStatus

=over 4

=item * C<IAM_STATUS_UNSPECIFIED> => C<0>

=item * C<INACTIVE> => C<1>

=item * C<ACTIVE> => C<2>

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::SqlServerUserDetails

Represents a Sql Server user on the Cloud SQL instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->disabled() >> / C<< $msg->disabled($value) >>

Type: C<Bool>

Indicates if the user has been disabled.

=item * C<< $msg->server_roles() >> / C<< $msg->server_roles($value) >>

Type: C<String>

Indicates the server roles for this user.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlUsers::UsersListResponse

User list response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

This is always <b>sql#usersList</b>.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlUsers::User>)

List of user resources in the instance.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Unused.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1beta4::CloudSqlUsers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
