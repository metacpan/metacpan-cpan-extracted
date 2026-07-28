package Google::Cloud::Sql::V1::CloudSqlUsers;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF91c2Vycy5wcm90bxITZ29vZ2xlLmNs
b3VkLnNxbC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9j
bGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9jbG91ZC9zcWwvdjEvY2xvdWRfc3FsX3Jlc291
cmNlcy5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvInUKFVNxbFVzZXJzRGVsZXRlUmVxdWVzdBISCgRob3N0
GAEgASgJUgRob3N0EhoKCGluc3RhbmNlGAIgASgJUghpbnN0YW5jZRISCgRuYW1lGAMgASgJ
UgRuYW1lEhgKB3Byb2plY3QYBCABKAlSB3Byb2plY3QicgoSU3FsVXNlcnNHZXRSZXF1ZXN0
EhoKCGluc3RhbmNlGAEgASgJUghpbnN0YW5jZRISCgRuYW1lGAIgASgJUgRuYW1lEhgKB3By
b2plY3QYAyABKAlSB3Byb2plY3QSEgoEaG9zdBgEIAEoCVIEaG9zdCJ8ChVTcWxVc2Vyc0lu
c2VydFJlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QYAiAB
KAlSB3Byb2plY3QSLQoEYm9keRhkIAEoCzIZLmdvb2dsZS5jbG91ZC5zcWwudjEuVXNlclIE
Ym9keSJLChNTcWxVc2Vyc0xpc3RSZXF1ZXN0EhoKCGluc3RhbmNlGAEgASgJUghpbnN0YW5j
ZRIYCgdwcm9qZWN0GAIgASgJUgdwcm9qZWN0IsEDChVTcWxVc2Vyc1VwZGF0ZVJlcXVlc3QS
FwoEaG9zdBgBIAEoCUID4EEBUgRob3N0EhoKCGluc3RhbmNlGAIgASgJUghpbnN0YW5jZRIS
CgRuYW1lGAMgASgJUgRuYW1lEhgKB3Byb2plY3QYBCABKAlSB3Byb2plY3QSKgoOZGF0YWJh
c2Vfcm9sZXMYBSADKAlCA+BBAVINZGF0YWJhc2VSb2xlcxI8ChVyZXZva2VfZXhpc3Rpbmdf
cm9sZXMYBiABKAhCA+BBAUgAUhNyZXZva2VFeGlzdGluZ1JvbGVziAEBEiYKDHNlcnZlcl9y
b2xlcxgHIAMoCUID4EEBUgtzZXJ2ZXJSb2xlcxJJChxyZXZva2VfZXhpc3Rpbmdfc2VydmVy
X3JvbGVzGAggASgIQgPgQQFIAVIZcmV2b2tlRXhpc3RpbmdTZXJ2ZXJSb2xlc4gBARItCgRi
b2R5GGQgASgLMhkuZ29vZ2xlLmNsb3VkLnNxbC52MS5Vc2VyUgRib2R5QhgKFl9yZXZva2Vf
ZXhpc3Rpbmdfcm9sZXNCHwodX3Jldm9rZV9leGlzdGluZ19zZXJ2ZXJfcm9sZXMi+AIKHFVz
ZXJQYXNzd29yZFZhbGlkYXRpb25Qb2xpY3kSNgoXYWxsb3dlZF9mYWlsZWRfYXR0ZW1wdHMY
ASABKAVSFWFsbG93ZWRGYWlsZWRBdHRlbXB0cxJbChxwYXNzd29yZF9leHBpcmF0aW9uX2R1
cmF0aW9uGAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhpwYXNzd29yZEV4cGly
YXRpb25EdXJhdGlvbhI/ChxlbmFibGVfZmFpbGVkX2F0dGVtcHRzX2NoZWNrGAMgASgIUhll
bmFibGVGYWlsZWRBdHRlbXB0c0NoZWNrEkAKBnN0YXR1cxgEIAEoCzIjLmdvb2dsZS5jbG91
ZC5zcWwudjEuUGFzc3dvcmRTdGF0dXNCA+BBA1IGc3RhdHVzEkAKHGVuYWJsZV9wYXNzd29y
ZF92ZXJpZmljYXRpb24YBSABKAhSGmVuYWJsZVBhc3N3b3JkVmVyaWZpY2F0aW9uIn4KDlBh
c3N3b3JkU3RhdHVzEhYKBmxvY2tlZBgBIAEoCFIGbG9ja2VkElQKGHBhc3N3b3JkX2V4cGly
YXRpb25fdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSFnBhc3N3b3Jk
RXhwaXJhdGlvblRpbWUilQkKBFVzZXISEgoEa2luZBgBIAEoCVIEa2luZBIaCghwYXNzd29y
ZBgCIAEoCVIIcGFzc3dvcmQSEgoEZXRhZxgDIAEoCVIEZXRhZxISCgRuYW1lGAQgASgJUgRu
YW1lEhcKBGhvc3QYBSABKAlCA+BBAVIEaG9zdBIaCghpbnN0YW5jZRgGIAEoCVIIaW5zdGFu
Y2USGAoHcHJvamVjdBgHIAEoCVIHcHJvamVjdBI5CgR0eXBlGAggASgOMiUuZ29vZ2xlLmNs
b3VkLnNxbC52MS5Vc2VyLlNxbFVzZXJUeXBlUgR0eXBlEmEKFnNxbHNlcnZlcl91c2VyX2Rl
dGFpbHMYCSABKAsyKS5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbFNlcnZlclVzZXJEZXRhaWxz
SABSFHNxbHNlcnZlclVzZXJEZXRhaWxzEiAKCWlhbV9lbWFpbBgLIAEoCUID4EEBUghpYW1F
bWFpbBJaCg9wYXNzd29yZF9wb2xpY3kYDCABKAsyMS5nb29nbGUuY2xvdWQuc3FsLnYxLlVz
ZXJQYXNzd29yZFZhbGlkYXRpb25Qb2xpY3lSDnBhc3N3b3JkUG9saWN5El0KEmR1YWxfcGFz
c3dvcmRfdHlwZRgNIAEoDjIqLmdvb2dsZS5jbG91ZC5zcWwudjEuVXNlci5EdWFsUGFzc3dv
cmRUeXBlSAFSEGR1YWxQYXNzd29yZFR5cGWIAQESRwoKaWFtX3N0YXR1cxgOIAEoDjIjLmdv
b2dsZS5jbG91ZC5zcWwudjEuVXNlci5JYW1TdGF0dXNIAlIJaWFtU3RhdHVziAEBEioKDmRh
dGFiYXNlX3JvbGVzGA8gAygJQgPgQQFSDWRhdGFiYXNlUm9sZXMSJgoMc2VydmVyX3JvbGVz
GBAgAygJQgPgQQFSC3NlcnZlclJvbGVzItYBCgtTcWxVc2VyVHlwZRIMCghCVUlMVF9JThAA
EhIKDkNMT1VEX0lBTV9VU0VSEAESHQoZQ0xPVURfSUFNX1NFUlZJQ0VfQUNDT1VOVBACEhMK
D0NMT1VEX0lBTV9HUk9VUBADEhgKFENMT1VEX0lBTV9HUk9VUF9VU0VSEAQSIwofQ0xPVURf
SUFNX0dST1VQX1NFUlZJQ0VfQUNDT1VOVBAFEiAKHENMT1VEX0lBTV9XT1JLRk9SQ0VfSURF
TlRJVFkQBhIQCgxFTlRSQUlEX1VTRVIQByJ8ChBEdWFsUGFzc3dvcmRUeXBlEiIKHkRVQUxf
UEFTU1dPUkRfVFlQRV9VTlNQRUNJRklFRBAAEhsKF05PX01PRElGWV9EVUFMX1BBU1NXT1JE
EAESFAoQTk9fRFVBTF9QQVNTV09SRBACEhEKDURVQUxfUEFTU1dPUkQQAyJBCglJYW1TdGF0
dXMSGgoWSUFNX1NUQVRVU19VTlNQRUNJRklFRBAAEgwKCElOQUNUSVZFEAESCgoGQUNUSVZF
EAJCDgoMdXNlcl9kZXRhaWxzQhUKE19kdWFsX3Bhc3N3b3JkX3R5cGVCDQoLX2lhbV9zdGF0
dXMiVQoUU3FsU2VydmVyVXNlckRldGFpbHMSGgoIZGlzYWJsZWQYASABKAhSCGRpc2FibGVk
EiEKDHNlcnZlcl9yb2xlcxgCIAMoCVILc2VydmVyUm9sZXMihAEKEVVzZXJzTGlzdFJlc3Bv
bnNlEhIKBGtpbmQYASABKAlSBGtpbmQSLwoFaXRlbXMYAiADKAsyGS5nb29nbGUuY2xvdWQu
c3FsLnYxLlVzZXJSBWl0ZW1zEioKD25leHRfcGFnZV90b2tlbhgDIAEoCUICGAFSDW5leHRQ
YWdlVG9rZW4y9QYKD1NxbFVzZXJzU2VydmljZRKPAQoGRGVsZXRlEiouZ29vZ2xlLmNsb3Vk
LnNxbC52MS5TcWxVc2Vyc0RlbGV0ZVJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9w
ZXJhdGlvbiI5gtPkkwIzKjEvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5z
dGFuY2V9L3VzZXJzEosBCgNHZXQSJy5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbFVzZXJzR2V0
UmVxdWVzdBoZLmdvb2dsZS5jbG91ZC5zcWwudjEuVXNlciJAgtPkkwI6EjgvdjEvcHJvamVj
dHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L3VzZXJzL3tuYW1lfRKVAQoGSW5z
ZXJ0EiouZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxVc2Vyc0luc2VydFJlcXVlc3QaHi5nb29n
bGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbiI/gtPkkwI5IjEvdjEvcHJvamVjdHMve3Byb2pl
Y3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L3VzZXJzOgRib2R5EpMBCgRMaXN0EiguZ29vZ2xl
LmNsb3VkLnNxbC52MS5TcWxVc2Vyc0xpc3RSZXF1ZXN0GiYuZ29vZ2xlLmNsb3VkLnNxbC52
MS5Vc2Vyc0xpc3RSZXNwb25zZSI5gtPkkwIzEjEvdjEvcHJvamVjdHMve3Byb2plY3R9L2lu
c3RhbmNlcy97aW5zdGFuY2V9L3VzZXJzEpUBCgZVcGRhdGUSKi5nb29nbGUuY2xvdWQuc3Fs
LnYxLlNxbFVzZXJzVXBkYXRlUmVxdWVzdBoeLmdvb2dsZS5jbG91ZC5zcWwudjEuT3BlcmF0
aW9uIj+C0+STAjkaMS92MS9wcm9qZWN0cy97cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5j
ZX0vdXNlcnM6BGJvZHkafMpBF3NxbGFkbWluLmdvb2dsZWFwaXMuY29t0kFfaHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL3NxbHNlcnZpY2UuYWRtaW5CWgoXY29tLmdvb2dsZS5jbG91ZC5z
cWwudjFCEkNsb3VkU3FsVXNlcnNQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL3NxbC9h
cGl2MS9zcWxwYjtzcWxwYkrKVgoHEgUOAMoCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJ
CgIDAxIDFQAjCgkKAgMEEgMWADcKCQoCAwUSAxcAKAoJCgIDBhIDGAApCggKAQgSAxoAQAoJ
CgIICxIDGgBACggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwAMwoJCgIICBIDHAAzCggK
AQgSAx0AMAoJCgIIARIDHQAwCiYKAgYAEgQgAEoBGhogQ2xvdWQgU1FMIHVzZXJzIHNlcnZp
Y2UuCgoKCgMGAAESAyAIFwoKCgMGAAMSAyECPwoMCgUGAAOZCBIDIQI/CgsKAwYAAxIEIgIk
OQoNCgUGAAOaCBIEIgIkOQo5CgQGAAIAEgQnAisDGisgRGVsZXRlcyBhIHVzZXIgZnJvbSBh
IENsb3VkIFNRTCBpbnN0YW5jZS4KCgwKBQYAAgABEgMnBgwKDAoFBgACAAISAycNIgoMCgUG
AAIAAxIDJy02Cg0KBQYAAgAEEgQoBCoGChEKCQYAAgAEsMq8IhIEKAQqBgpJCgQGAAIBEgQu
AjIDGjsgUmV0cmlldmVzIGEgcmVzb3VyY2UgY29udGFpbmluZyBpbmZvcm1hdGlvbiBhYm91
dCBhIHVzZXIuCgoMCgUGAAIBARIDLgYJCgwKBQYAAgECEgMuChwKDAoFBgACAQMSAy4nKwoN
CgUGAAIBBBIELwQxBgoRCgkGAAIBBLDKvCISBC8EMQYKOwoEBgACAhIENQI6AxotIENyZWF0
ZXMgYSBuZXcgdXNlciBpbiBhIENsb3VkIFNRTCBpbnN0YW5jZS4KCgwKBQYAAgIBEgM1BgwK
DAoFBgACAgISAzUNIgoMCgUGAAICAxIDNS02Cg0KBQYAAgIEEgQ2BDkGChEKCQYAAgIEsMq8
IhIENgQ5BgpACgQGAAIDEgQ9AkEDGjIgTGlzdHMgdXNlcnMgaW4gdGhlIHNwZWNpZmllZCBD
bG91ZCBTUUwgaW5zdGFuY2UuCgoMCgUGAAIDARIDPQYKCgwKBQYAAgMCEgM9Cx4KDAoFBgAC
AwMSAz0pOgoNCgUGAAIDBBIEPgRABgoRCgkGAAIDBLDKvCISBD4EQAYKQQoEBgACBBIERAJJ
AxozIFVwZGF0ZXMgYW4gZXhpc3RpbmcgdXNlciBpbiBhIENsb3VkIFNRTCBpbnN0YW5jZS4K
CgwKBQYAAgQBEgNEBgwKDAoFBgACBAISA0QNIgoMCgUGAAIEAxIDRC02Cg0KBQYAAgQEEgRF
BEgGChEKCQYAAgQEsMq8IhIERQRIBgoKCgIEABIETABYAQoKCgMEAAESA0wIHQowCgQEAAIA
EgNOAhIaIyBIb3N0IG9mIHRoZSB1c2VyIGluIHRoZSBpbnN0YW5jZS4KCgwKBQQAAgAFEgNO
AggKDAoFBAACAAESA04JDQoMCgUEAAIAAxIDThARCkoKBAQAAgESA1ECFho9IERhdGFiYXNl
IGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoM
CgUEAAIBBRIDUQIICgwKBQQAAgEBEgNRCREKDAoFBAACAQMSA1EUFQowCgQEAAICEgNUAhIa
IyBOYW1lIG9mIHRoZSB1c2VyIGluIHRoZSBpbnN0YW5jZS4KCgwKBQQAAgIFEgNUAggKDAoF
BAACAgESA1QJDQoMCgUEAAICAxIDVBARCkQKBAQAAgMSA1cCFRo3IFByb2plY3QgSUQgb2Yg
dGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoMCgUEAAIDBRIDVwII
CgwKBQQAAgMBEgNXCRAKDAoFBAACAwMSA1cTFAovCgIEARIEWwBnARojIFJlcXVlc3QgbWVz
c2FnZSBmb3IgVXNlcnMgR2V0IFJQQwoKCgoDBAEBEgNbCBoKSgoEBAECABIDXQIWGj0gRGF0
YWJhc2UgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJ
RC4KCgwKBQQBAgAFEgNdAggKDAoFBAECAAESA10JEQoMCgUEAQIAAxIDXRQVCiQKBAQBAgES
A2ACEhoXIFVzZXIgb2YgdGhlIGluc3RhbmNlLgoKDAoFBAECAQUSA2ACCAoMCgUEAQIBARID
YAkNCgwKBQQBAgEDEgNgEBEKRAoEBAECAhIDYwIVGjcgUHJvamVjdCBJRCBvZiB0aGUgcHJv
amVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCgwKBQQBAgIFEgNjAggKDAoFBAEC
AgESA2MJEAoMCgUEAQICAxIDYxMUCi4KBAQBAgMSA2YCEhohIEhvc3Qgb2YgYSB1c2VyIG9m
IHRoZSBpbnN0YW5jZS4KCgwKBQQBAgMFEgNmAggKDAoFBAECAwESA2YJDQoMCgUEAQIDAxID
ZhARCgoKAgQCEgRpAHEBCgoKAwQCARIDaQgdCkoKBAQCAgASA2sCFho9IERhdGFiYXNlIGlu
c3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUE
AgIABRIDawIICgwKBQQCAgABEgNrCREKDAoFBAICAAMSA2sUFQpECgQEAgIBEgNuAhUaNyBQ
cm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoK
DAoFBAICAQUSA24CCAoMCgUEAgIBARIDbgkQCgwKBQQCAgEDEgNuExQKCwoEBAICAhIDcAIS
CgwKBQQCAgIGEgNwAgYKDAoFBAICAgESA3AHCwoMCgUEAgICAxIDcA4RCgoKAgQDEgRzAHkB
CgoKAwQDARIDcwgbCkoKBAQDAgASA3UCFho9IERhdGFiYXNlIGluc3RhbmNlIElELiBUaGlz
IGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAwIABRIDdQIICgwKBQQD
AgABEgN1CREKDAoFBAMCAAMSA3UUFQpECgQEAwIBEgN4AhUaNyBQcm9qZWN0IElEIG9mIHRo
ZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAMCAQUSA3gCCAoM
CgUEAwIBARIDeAkQCgwKBQQDAgEDEgN4ExQKCwoCBAQSBXsAngEBCgoKAwQEARIDewgdCjoK
BAQEAgASA30COxotIE9wdGlvbmFsLiBIb3N0IG9mIHRoZSB1c2VyIGluIHRoZSBpbnN0YW5j
ZS4KCgwKBQQEAgAFEgN9AggKDAoFBAQCAAESA30JDQoMCgUEBAIAAxIDfRARCgwKBQQEAgAI
EgN9EjoKDwoIBAQCAAicCAASA30TOQpLCgQEBAIBEgSAAQIWGj0gRGF0YWJhc2UgaW5zdGFu
Y2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4KCg0KBQQEAgEF
EgSAAQIICg0KBQQEAgEBEgSAAQkRCg0KBQQEAgEDEgSAARQVCjEKBAQEAgISBIMBAhIaIyBO
YW1lIG9mIHRoZSB1c2VyIGluIHRoZSBpbnN0YW5jZS4KCg0KBQQEAgIFEgSDAQIICg0KBQQE
AgIBEgSDAQkNCg0KBQQEAgIDEgSDARARCkUKBAQEAgMSBIYBAhUaNyBQcm9qZWN0IElEIG9m
IHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDQoFBAQCAwUSBIYB
AggKDQoFBAQCAwESBIYBCRAKDQoFBAQCAwMSBIYBExQKfwoEBAQCBBIEigECThpxIE9wdGlv
bmFsLiBMaXN0IG9mIGRhdGFiYXNlIHJvbGVzIHRvIGdyYW50IHRvIHRoZSB1c2VyLiBib2R5
LmRhdGFiYXNlX3JvbGVzCiB3aWxsIGJlIGlnbm9yZWQgZm9yIHVwZGF0ZSByZXF1ZXN0LgoK
DQoFBAQCBAQSBIoBAgoKDQoFBAQCBAUSBIoBCxEKDQoFBAQCBAESBIoBEiAKDQoFBAQCBAMS
BIoBIyQKDQoFBAQCBAgSBIoBJU0KEAoIBAQCBAicCAASBIoBJkwK6wEKBAQEAgUSBo8BApAB
LxraASBPcHRpb25hbC4gU3BlY2lmaWVzIHdoZXRoZXIgdG8gcmV2b2tlIGV4aXN0aW5nIHJv
bGVzIHRoYXQgYXJlIG5vdCBwcmVzZW50CiBpbiB0aGUgYGRhdGFiYXNlX3JvbGVzYCBmaWVs
ZC4gSWYgYGZhbHNlYCBvciB1bnNldCwgdGhlIGRhdGFiYXNlIHJvbGVzCiBzcGVjaWZpZWQg
aW4gYGRhdGFiYXNlX3JvbGVzYCBhcmUgYWRkZWQgdG8gdGhlIHVzZXIncyBleGlzdGluZyBy
b2xlcy4KCg0KBQQEAgUEEgSPAQIKCg0KBQQEAgUFEgSPAQsPCg0KBQQEAgUBEgSPARAlCg0K
BQQEAgUDEgSPASgpCg0KBQQEAgUIEgSQAQYuChAKCAQEAgUInAgAEgSQAQctCtIBCgQEBAIG
EgSVAQJMGsMBIE9wdGlvbmFsLiBUaGUgc2VydmVyIHJvbGVzIHRvIGdyYW50IHRvIHRoZSBT
UUwgU2VydmVyIGxvZ2luLiBFeGlzdGluZwogc2VydmVyIHJvbGVzIHdpbGwgbm90IGJlIHJl
dm9rZWQgaWYgcmV2b2tlX2V4aXN0aW5nX3JvbGVzIGlzIGZhbHNlLgogYm9keS5zZXJ2ZXJf
cm9sZXMgd2lsbCBiZSBpZ25vcmVkIGZvciB1cGRhdGUgcmVxdWVzdC4KCg0KBQQEAgYEEgSV
AQIKCg0KBQQEAgYFEgSVAQsRCg0KBQQEAgYBEgSVARIeCg0KBQQEAgYDEgSVASEiCg0KBQQE
AgYIEgSVASNLChAKCAQEAgYInAgAEgSVASRKCuwBCgQEBAIHEgaaAQKbAS8a2wEgT3B0aW9u
YWwuIFNwZWNpZmllcyB3aGV0aGVyIHRvIHJldm9rZSBleGlzdGluZyByb2xlcyB0aGF0IGFy
ZSBub3QgcHJlc2VudAogaW4gdGhlIGBzZXJ2ZXJfcm9sZXNgIGZpZWxkLiBJZiBgZmFsc2Vg
IG9yIHVuc2V0LCB0aGUgc2VydmVyIHJvbGVzCiBzcGVjaWZpZWQgaW4gYHNlcnZlcl9yb2xl
c2AgYXJlIGFkZGVkIHRvIHRoZSB1c2VyJ3MgZXhpc3Rpbmcgc2VydmVyIHJvbGVzLgoKDQoF
BAQCBwQSBJoBAgoKDQoFBAQCBwUSBJoBCw8KDQoFBAQCBwESBJoBECwKDQoFBAQCBwMSBJoB
LzAKDQoFBAQCBwgSBJsBBi4KEAoIBAQCBwicCAASBJsBBy0KDAoEBAQCCBIEnQECEgoNCgUE
BAIIBhIEnQECBgoNCgUEBAIIARIEnQEHCwoNCgUEBAIIAxIEnQEOEQo2CgIEBRIGoQEAsQEB
GiggVXNlciBsZXZlbCBwYXNzd29yZCB2YWxpZGF0aW9uIHBvbGljeS4KCgsKAwQFARIEoQEI
JApPCgQEBQIAEgSjAQIkGkEgTnVtYmVyIG9mIGZhaWxlZCBsb2dpbiBhdHRlbXB0cyBhbGxv
d2VkIGJlZm9yZSB1c2VyIGdldCBsb2NrZWQuCgoNCgUEBQIABRIEowECBwoNCgUEBQIAARIE
owEIHwoNCgUEBQIAAxIEowEiIwo+CgQEBQIBEgSmAQI8GjAgRXhwaXJhdGlvbiBkdXJhdGlv
biBhZnRlciBwYXNzd29yZCBpcyB1cGRhdGVkLgoKDQoFBAUCAQYSBKYBAhoKDQoFBAUCAQES
BKYBGzcKDQoFBAUCAQMSBKYBOjsKRQoEBAUCAhIEqQECKBo3IElmIHRydWUsIGZhaWxlZCBs
b2dpbiBhdHRlbXB0cyBjaGVjayB3aWxsIGJlIGVuYWJsZWQuCgoNCgUEBQICBRIEqQECBgoN
CgUEBQICARIEqQEHIwoNCgUEBQICAxIEqQEmJwo3CgQEBQIDEgSsAQJIGikgT3V0cHV0IG9u
bHkuIFJlYWQtb25seSBwYXNzd29yZCBzdGF0dXMuCgoNCgUEBQIDBhIErAECEAoNCgUEBQID
ARIErAERFwoNCgUEBQIDAxIErAEaGwoNCgUEBQIDCBIErAEcRwoQCggEBQIDCJwIABIErAEd
RgqJAQoEBAUCBBIEsAECKBp7IElmIHRydWUsIHRoZSB1c2VyIG11c3Qgc3BlY2lmeSB0aGUg
Y3VycmVudCBwYXNzd29yZCBiZWZvcmUgY2hhbmdpbmcgdGhlCiBwYXNzd29yZC4gVGhpcyBm
bGFnIGlzIHN1cHBvcnRlZCBvbmx5IGZvciBNeVNRTC4KCg0KBQQFAgQFEgSwAQIGCg0KBQQF
AgQBEgSwAQcjCg0KBQQFAgQDEgSwASYnCioKAgQGEga0AQC6AQEaHCBSZWFkLW9ubHkgcGFz
c3dvcmQgc3RhdHVzLgoKCwoDBAYBEgS0AQgWCj0KBAQGAgASBLYBAhIaLyBJZiB0cnVlLCB1
c2VyIGRvZXMgbm90IGhhdmUgbG9naW4gcHJpdmlsZWdlcy4KCg0KBQQGAgAFEgS2AQIGCg0K
BQQGAgABEgS2AQcNCg0KBQQGAgADEgS2ARARCjwKBAQGAgESBLkBAjkaLiBUaGUgZXhwaXJh
dGlvbiB0aW1lIG9mIHRoZSBjdXJyZW50IHBhc3N3b3JkLgoKDQoFBAYCAQYSBLkBAhsKDQoF
BAYCAQESBLkBHDQKDQoFBAYCAQMSBLkBNzgKKgoCBAcSBr0BALUCARocIEEgQ2xvdWQgU1FM
IHVzZXIgcmVzb3VyY2UuCgoLCgMEBwESBL0BCAwKIAoEBAcEABIGvwEC2QEDGhAgVGhlIHVz
ZXIgdHlwZS4KCg0KBQQHBAABEgS/AQcSCjQKBgQHBAACABIEwQEEERokIFRoZSBkYXRhYmFz
ZSdzIGJ1aWx0LWluIHVzZXIgdHlwZS4KCg8KBwQHBAACAAESBMEBBAwKDwoHBAcEAAIAAhIE
wQEPEAohCgYEBwQAAgESBMQBBBcaESBDbG91ZCBJQU0gdXNlci4KCg8KBwQHBAACAQESBMQB
BBIKDwoHBAcEAAIBAhIExAEVFgosCgYEBwQAAgISBMcBBCIaHCBDbG91ZCBJQU0gc2Vydmlj
ZSBhY2NvdW50LgoKDwoHBAcEAAICARIExwEEHQoPCgcEBwQAAgICEgTHASAhCjYKBgQHBAAC
AxIEygEEGBomIENsb3VkIElBTSBncm91cC4gTm90IHVzZWQgZm9yIGxvZ2luLgoKDwoHBAcE
AAIDARIEygEEEwoPCgcEBwQAAgMCEgTKARYXClIKBgQHBAACBBIEzQEEHRpCIFJlYWQtb25s
eS4gTG9naW4gZm9yIGEgdXNlciB0aGF0IGJlbG9uZ3MgdG8gdGhlIENsb3VkIElBTSBncm91
cC4KCg8KBwQHBAACBAESBM0BBBgKDwoHBAcEAAIEAhIEzQEbHApeCgYEBwQAAgUSBNEBBCga
TiBSZWFkLW9ubHkuIExvZ2luIGZvciBhIHNlcnZpY2UgYWNjb3VudCB0aGF0IGJlbG9uZ3Mg
dG8gdGhlCiBDbG91ZCBJQU0gZ3JvdXAuCgoPCgcEBwQAAgUBEgTRAQQjCg8KBwQHBAACBQIS
BNEBJicKXwoGBAcEAAIGEgTVAQQlGk8gQ2xvdWQgSUFNIHdvcmtmb3JjZSBpZGVudGl0eSB1
c2VyIG1hbmFnZWQgdmlhIHdvcmtmb3JjZSBpZGVudGl0eQogZmVkZXJhdGlvbi4KCg8KBwQH
BAACBgESBNUBBCAKDwoHBAcEAAIGAhIE1QEjJAoqCgYEBwQAAgcSBNgBBBUaGiBNaWNyb3Nv
ZnQgRW50cmEgSUQgdXNlci4KCg8KBwQHBAACBwESBNgBBBAKDwoHBAcEAAIHAhIE2AETFAow
CgQEBwQBEgbcAQLoAQMaICBUaGUgdHlwZSBvZiByZXRhaW5lZCBwYXNzd29yZC4KCg0KBQQH
BAEBEgTcAQcXCiQKBgQHBAECABIE3gEEJxoUIFRoZSBkZWZhdWx0IHZhbHVlLgoKDwoHBAcE
AQIAARIE3gEEIgoPCgcEBwQBAgACEgTeASUmCkAKBgQHBAECARIE4QEEIBowIERvIG5vdCB1
cGRhdGUgdGhlIHVzZXIncyBkdWFsIHBhc3N3b3JkIHN0YXR1cy4KCg8KBwQHBAECAQESBOEB
BBsKDwoHBAcEAQIBAhIE4QEeHwpJCgYEBwQBAgISBOQBBBkaOSBObyBkdWFsIHBhc3N3b3Jk
IHVzYWJsZSBmb3IgY29ubmVjdGluZyB1c2luZyB0aGlzIHVzZXIuCgoPCgcEBwQBAgIBEgTk
AQQUCg8KBwQHBAECAgISBOQBFxgKRgoGBAcEAQIDEgTnAQQWGjYgRHVhbCBwYXNzd29yZCB1
c2FibGUgZm9yIGNvbm5lY3RpbmcgdXNpbmcgdGhpcyB1c2VyLgoKDwoHBAcEAQIDARIE5wEE
EQoPCgcEBwQBAgMCEgTnARQVClQKBAQHBAISBusBAvkBAxpEIEluZGljYXRlcyBpZiBhIGdy
b3VwIGlzIGF2YWlsYWJsZSBmb3IgSUFNIGRhdGFiYXNlIGF1dGhlbnRpY2F0aW9uLgoKDQoF
BAcEAgESBOsBBxAKmQIKBgQHBAICABIE8QEEHxqIAiBUaGUgZGVmYXVsdCB2YWx1ZSBmb3Ig
dXNlcnMgdGhhdCBhcmUgbm90IG9mIHR5cGUgQ0xPVURfSUFNX0dST1VQLgogT25seSBDTE9V
RF9JQU1fR1JPVVAgdXNlcnMgd2lsbCBiZSBpbmFjdGl2ZSBvciBhY3RpdmUuCiBVc2VycyB3
aXRoIGFuIElhbVN0YXR1cyBvZiBJQU1fU1RBVFVTX1VOU1BFQ0lGSUVEIHdpbGwgbm90CiBk
aXNwbGF5IHdoZXRoZXIgdGhleSBhcmUgYWN0aXZlIG9yIGluYWN0aXZlIGFzIHRoYXQgaXMg
bm90IGFwcGxpY2FibGUgdG8KIHRoZW0uCgoPCgcEBwQCAgABEgTxAQQaCg8KBwQHBAICAAIS
BPEBHR4KXwoGBAcEAgIBEgT1AQQRGk8gSU5BQ1RJVkUgaW5kaWNhdGVzIGEgZ3JvdXAgaXMg
bm90IGF2YWlsYWJsZSBmb3IgSUFNIGRhdGFiYXNlCiBhdXRoZW50aWNhdGlvbi4KCg8KBwQH
BAICAQESBPUBBAwKDwoHBAcEAgIBAhIE9QEPEApYCgYEBwQCAgISBPgBBA8aSCBBQ1RJVkUg
aW5kaWNhdGVzIGEgZ3JvdXAgaXMgYXZhaWxhYmxlIGZvciBJQU0gZGF0YWJhc2UgYXV0aGVu
dGljYXRpb24uCgoPCgcEBwQCAgIBEgT4AQQKCg8KBwQHBAICAgISBPgBDQ4KKgoEBAcCABIE
/AECEhocIFRoaXMgaXMgYWx3YXlzIGBzcWwjdXNlcmAuCgoNCgUEBwIABRIE/AECCAoNCgUE
BwIAARIE/AEJDQoNCgUEBwIAAxIE/AEQEQoqCgQEBwIBEgT/AQIWGhwgVGhlIHBhc3N3b3Jk
IGZvciB0aGUgdXNlci4KCg0KBQQHAgEFEgT/AQIICg0KBQQHAgEBEgT/AQkRCg0KBQQHAgED
EgT/ARQVCl8KBAQHAgISBIMCAhIaUSBUaGlzIGZpZWxkIGlzIGRlcHJlY2F0ZWQgYW5kIHdp
bGwgYmUgcmVtb3ZlZCBmcm9tIGEgZnV0dXJlIHZlcnNpb24gb2YgdGhlCiBBUEkuCgoNCgUE
BwICBRIEgwICCAoNCgUEBwICARIEgwIJDQoNCgUEBwICAxIEgwIQEQqIAQoEBAcCAxIEhwIC
Ehp6IFRoZSBuYW1lIG9mIHRoZSB1c2VyIGluIHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UuIENh
biBiZSBvbWl0dGVkIGZvcgogYHVwZGF0ZWAgYmVjYXVzZSBpdCBpcyBhbHJlYWR5IHNwZWNp
ZmllZCBpbiB0aGUgVVJMLgoKDQoFBAcCAwUSBIcCAggKDQoFBAcCAwESBIcCCQ0KDQoFBAcC
AwMSBIcCEBEK2QIKBAQHAgQSBI4CAjsaygIgT3B0aW9uYWwuIFRoZSBob3N0IGZyb20gd2hp
Y2ggdGhlIHVzZXIgY2FuIGNvbm5lY3QuIEZvciBgaW5zZXJ0YAogb3BlcmF0aW9ucywgaG9z
dCBkZWZhdWx0cyB0byBhbiBlbXB0eSBzdHJpbmcuIEZvciBgdXBkYXRlYAogb3BlcmF0aW9u
cywgaG9zdCBpcyBzcGVjaWZpZWQgYXMgcGFydCBvZiB0aGUgcmVxdWVzdCBVUkwuIFRoZSBo
b3N0IG5hbWUKIGNhbm5vdCBiZSB1cGRhdGVkIGFmdGVyIGluc2VydGlvbi4gIEZvciBhIE15
U1FMIGluc3RhbmNlLCBpdCdzIHJlcXVpcmVkOwogZm9yIGEgUG9zdGdyZVNRTCBvciBTUUwg
U2VydmVyIGluc3RhbmNlLCBpdCdzIG9wdGlvbmFsLgoKDQoFBAcCBAUSBI4CAggKDQoFBAcC
BAESBI4CCQ0KDQoFBAcCBAMSBI4CEBEKDQoFBAcCBAgSBI4CEjoKEAoIBAcCBAicCAASBI4C
EzkKpAEKBAQHAgUSBJMCAhYalQEgVGhlIG5hbWUgb2YgdGhlIENsb3VkIFNRTCBpbnN0YW5j
ZS4gVGhpcyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgogQ2FuIGJlIG9taXR0
ZWQgZm9yIGB1cGRhdGVgIGJlY2F1c2UgaXQgaXMgYWxyZWFkeSBzcGVjaWZpZWQgb24gdGhl
CiBVUkwuCgoNCgUEBwIFBRIEkwICCAoNCgUEBwIFARIEkwIJEQoNCgUEBwIFAxIEkwIUFQrN
AQoEBAcCBhIEmAICFRq+ASBUaGUgcHJvamVjdCBJRCBvZiB0aGUgcHJvamVjdCBjb250YWlu
aW5nIHRoZSBDbG91ZCBTUUwgZGF0YWJhc2UuIFRoZSBHb29nbGUKIGFwcHMgZG9tYWluIGlz
IHByZWZpeGVkIGlmIGFwcGxpY2FibGUuIENhbiBiZSBvbWl0dGVkIGZvciBgdXBkYXRlYCBi
ZWNhdXNlCiBpdCBpcyBhbHJlYWR5IHNwZWNpZmllZCBvbiB0aGUgVVJMLgoKDQoFBAcCBgUS
BJgCAggKDQoFBAcCBgESBJgCCRAKDQoFBAcCBgMSBJgCExQKkgEKBAQHAgcSBJwCAhcagwEg
VGhlIHVzZXIgdHlwZS4gSXQgZGV0ZXJtaW5lcyB0aGUgbWV0aG9kIHRvIGF1dGhlbnRpY2F0
ZSB0aGUgdXNlciBkdXJpbmcKIGxvZ2luLiBUaGUgZGVmYXVsdCBpcyB0aGUgZGF0YWJhc2Un
cyBidWlsdC1pbiB1c2VyIHR5cGUuCgoNCgUEBwIHBhIEnAICDQoNCgUEBwIHARIEnAIOEgoN
CgUEBwIHAxIEnAIVFgo5CgQEBwgAEgafAgKhAgMaKSBVc2VyIGRldGFpbHMgZm9yIHNwZWNp
ZmljIGRhdGFiYXNlIHR5cGUKCg0KBQQHCAABEgSfAggUCgwKBAQHAggSBKACBDQKDQoFBAcC
CAYSBKACBBgKDQoFBAcCCAESBKACGS8KDQoFBAcCCAMSBKACMjMKmAEKBAQHAgkSBKUCAkEa
iQEgT3B0aW9uYWwuIFRoZSBmdWxsIGVtYWlsIGZvciBhbiBJQU0gdXNlci4gRm9yIG5vcm1h
bCBkYXRhYmFzZSB1c2VycywgdGhpcwogd2lsbCBub3QgYmUgZmlsbGVkLiBPbmx5IGFwcGxp
Y2FibGUgdG8gTXlTUUwgZGF0YWJhc2UgdXNlcnMuCgoNCgUEBwIJBRIEpQICCAoNCgUEBwIJ
ARIEpQIJEgoNCgUEBwIJAxIEpQIVFwoNCgUEBwIJCBIEpQIYQAoQCggEBwIJCJwIABIEpQIZ
Pwo2CgQEBwIKEgSoAgI0GiggVXNlciBsZXZlbCBwYXNzd29yZCB2YWxpZGF0aW9uIHBvbGlj
eS4KCg0KBQQHAgoGEgSoAgIeCg0KBQQHAgoBEgSoAh8uCg0KBQQHAgoDEgSoAjEzCjIKBAQH
AgsSBKsCAjQaJCBEdWFsIHBhc3N3b3JkIHN0YXR1cyBmb3IgdGhlIHVzZXIuCgoNCgUEBwIL
BBIEqwICCgoNCgUEBwILBhIEqwILGwoNCgUEBwILARIEqwIcLgoNCgUEBwILAxIEqwIxMwpb
CgQEBwIMEgSuAgIlGk0gSW5kaWNhdGVzIGlmIGEgZ3JvdXAgaXMgYWN0aXZlIG9yIGluYWN0
aXZlIGZvciBJQU0gZGF0YWJhc2UgYXV0aGVudGljYXRpb24uCgoNCgUEBwIMBBIErgICCgoN
CgUEBwIMBhIErgILFAoNCgUEBwIMARIErgIVHwoNCgUEBwIMAxIErgIiJAo2CgQEBwINEgSx
AgJPGiggT3B0aW9uYWwuIFJvbGUgbWVtYmVyc2hpcHMgb2YgdGhlIHVzZXIKCg0KBQQHAg0E
EgSxAgIKCg0KBQQHAg0FEgSxAgsRCg0KBQQHAg0BEgSxAhIgCg0KBQQHAg0DEgSxAiMlCg0K
BQQHAg0IEgSxAiZOChAKCAQHAg0InAgAEgSxAidNCkQKBAQHAg4SBLQCAk0aNiBPcHRpb25h
bC4gVGhlIHNlcnZlciByb2xlcyBmb3IgdGhlIFNRTCBTZXJ2ZXIgbG9naW4uCgoNCgUEBwIO
BBIEtAICCgoNCgUEBwIOBRIEtAILEQoNCgUEBwIOARIEtAISHgoNCgUEBwIOAxIEtAIhIwoN
CgUEBwIOCBIEtAIkTAoQCggEBwIOCJwIABIEtAIlSwpHCgIECBIGuAIAvgIBGjkgUmVwcmVz
ZW50cyBhIFNxbCBTZXJ2ZXIgdXNlciBvbiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKCwoD
BAgBEgS4AggcCi0KBAQIAgASBLoCAhQaHyBJZiB0aGUgdXNlciBoYXMgYmVlbiBkaXNhYmxl
ZAoKDQoFBAgCAAUSBLoCAgYKDQoFBAgCAAESBLoCBw8KDQoFBAgCAAMSBLoCEhMKLgoEBAgC
ARIEvQICIxogIFRoZSBzZXJ2ZXIgcm9sZXMgZm9yIHRoaXMgdXNlcgoKDQoFBAgCAQQSBL0C
AgoKDQoFBAgCAQUSBL0CCxEKDQoFBAgCAQESBL0CEh4KDQoFBAgCAQMSBL0CISIKIwoCBAkS
BsECAMoCARoVIFVzZXIgbGlzdCByZXNwb25zZS4KCgsKAwQJARIEwQIIGQovCgQECQIAEgTD
AgISGiEgVGhpcyBpcyBhbHdheXMgYHNxbCN1c2Vyc0xpc3RgLgoKDQoFBAkCAAUSBMMCAggK
DQoFBAkCAAESBMMCCQ0KDQoFBAkCAAMSBMMCEBEKNwoEBAkCARIExgICGhopIExpc3Qgb2Yg
dXNlciByZXNvdXJjZXMgaW4gdGhlIGluc3RhbmNlLgoKDQoFBAkCAQQSBMYCAgoKDQoFBAkC
AQYSBMYCCw8KDQoFBAkCAQESBMYCEBUKDQoFBAkCAQMSBMYCGBkKFwoEBAkCAhIEyQICMRoJ
IFVudXNlZC4KCg0KBQQJAgIFEgTJAgIICg0KBQQJAgIBEgTJAgkYCg0KBQQJAgIDEgTJAhsc
Cg0KBQQJAgIIEgTJAh0wCg4KBgQJAgIIAxIEyQIeL2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest ===
    # Fields for SqlUsersDeleteRequest
    # Field: host Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest->new(
        host => $value,
    );

=head1 FIELDS

=over 4

=item * B<host>

Type: String

=item * B<instance>

Type: String

=item * B<name>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest ===
    # Fields for SqlUsersGetRequest
    # Field: instance Type: 9 ()
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()
    # Field: host Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<name>

Type: String

=item * B<project>

Type: String

=item * B<host>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest ===
    # Fields for SqlUsersInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.User)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<body>

Type: Message (.google.cloud.sql.v1.User)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest ===
    # Fields for SqlUsersListRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersUpdateRequest ===
    # Fields for SqlUsersUpdateRequest
    # Field: host Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()
    # Field: database_roles Type: 9 ()
    # Field: revoke_existing_roles Type: 8 ()
    # Field: server_roles Type: 9 ()
    # Field: revoke_existing_server_roles Type: 8 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.User)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersUpdateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersUpdateRequest->new(
        host => $value,
    );

=head1 FIELDS

=over 4

=item * B<host>

Type: String

=item * B<instance>

Type: String

=item * B<name>

Type: String

=item * B<project>

Type: String

=item * B<database_roles>

Type: String

=item * B<revoke_existing_roles>

Type: Bool

=item * B<server_roles>

Type: String

=item * B<revoke_existing_server_roles>

Type: Bool

=item * B<body>

Type: Message (.google.cloud.sql.v1.User)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy ===
    # Fields for UserPasswordValidationPolicy
    # Field: allowed_failed_attempts Type: 5 ()
    # Field: password_expiration_duration Type: 11 (.google.protobuf.Duration)
    # Field: enable_failed_attempts_check Type: 8 ()
    # Field: status Type: 11 (.google.cloud.sql.v1.PasswordStatus)
    # Field: enable_password_verification Type: 8 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy->new(
        allowed_failed_attempts => $value,
    );

=head1 FIELDS

=over 4

=item * B<allowed_failed_attempts>

Type: Int32

=item * B<password_expiration_duration>

Type: Message (.google.protobuf.Duration)

=item * B<enable_failed_attempts_check>

Type: Bool

=item * B<status>

Type: Message (.google.cloud.sql.v1.PasswordStatus)

=item * B<enable_password_verification>

Type: Bool

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus ===
    # Fields for PasswordStatus
    # Field: locked Type: 8 ()
    # Field: password_expiration_time Type: 11 (.google.protobuf.Timestamp)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus->new(
        locked => $value,
    );

=head1 FIELDS

=over 4

=item * B<locked>

Type: Bool

=item * B<password_expiration_time>

Type: Message (.google.protobuf.Timestamp)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::User ===
    # Fields for User
    # Field: kind Type: 9 ()
    # Field: password Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: name Type: 9 ()
    # Field: host Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: type Type: 14 (.google.cloud.sql.v1.User.SqlUserType)
    # Field: sqlserver_user_details Type: 11 (.google.cloud.sql.v1.SqlServerUserDetails)
    # Field: iam_email Type: 9 ()
    # Field: password_policy Type: 11 (.google.cloud.sql.v1.UserPasswordValidationPolicy)
    # Field: dual_password_type Type: 14 (.google.cloud.sql.v1.User.DualPasswordType)
    # Field: iam_status Type: 14 (.google.cloud.sql.v1.User.IamStatus)
    # Field: database_roles Type: 9 ()
    # Field: server_roles Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::User - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::User->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<password>

Type: String

=item * B<etag>

Type: String

=item * B<name>

Type: String

=item * B<host>

Type: String

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<type>

Type: Enum (.google.cloud.sql.v1.User.SqlUserType)

=item * B<sqlserver_user_details>

Type: Message (.google.cloud.sql.v1.SqlServerUserDetails)

=item * B<iam_email>

Type: String

=item * B<password_policy>

Type: Message (.google.cloud.sql.v1.UserPasswordValidationPolicy)

=item * B<dual_password_type>

Type: Enum (.google.cloud.sql.v1.User.DualPasswordType)

=item * B<iam_status>

Type: Enum (.google.cloud.sql.v1.User.IamStatus)

=item * B<database_roles>

Type: String

=item * B<server_roles>

Type: String

=back

=cut

# Enum: User::SqlUserType
our $User_BUILT_IN = 0;
our $User_CLOUD_IAM_USER = 1;
our $User_CLOUD_IAM_SERVICE_ACCOUNT = 2;
our $User_CLOUD_IAM_GROUP = 3;
our $User_CLOUD_IAM_GROUP_USER = 4;
our $User_CLOUD_IAM_GROUP_SERVICE_ACCOUNT = 5;
our $User_CLOUD_IAM_WORKFORCE_IDENTITY = 6;
our $User_ENTRAID_USER = 7;

=pod

=head2 Enum: User::SqlUserType

Values:

=over 4

=item * C<BUILT_IN> => 0

=item * C<CLOUD_IAM_USER> => 1

=item * C<CLOUD_IAM_SERVICE_ACCOUNT> => 2

=item * C<CLOUD_IAM_GROUP> => 3

=item * C<CLOUD_IAM_GROUP_USER> => 4

=item * C<CLOUD_IAM_GROUP_SERVICE_ACCOUNT> => 5

=item * C<CLOUD_IAM_WORKFORCE_IDENTITY> => 6

=item * C<ENTRAID_USER> => 7

=back

=cut

# Enum: User::DualPasswordType
our $User_DUAL_PASSWORD_TYPE_UNSPECIFIED = 0;
our $User_NO_MODIFY_DUAL_PASSWORD = 1;
our $User_NO_DUAL_PASSWORD = 2;
our $User_DUAL_PASSWORD = 3;

=pod

=head2 Enum: User::DualPasswordType

Values:

=over 4

=item * C<DUAL_PASSWORD_TYPE_UNSPECIFIED> => 0

=item * C<NO_MODIFY_DUAL_PASSWORD> => 1

=item * C<NO_DUAL_PASSWORD> => 2

=item * C<DUAL_PASSWORD> => 3

=back

=cut

# Enum: User::IamStatus
our $User_IAM_STATUS_UNSPECIFIED = 0;
our $User_INACTIVE = 1;
our $User_ACTIVE = 2;

=pod

=head2 Enum: User::IamStatus

Values:

=over 4

=item * C<IAM_STATUS_UNSPECIFIED> => 0

=item * C<INACTIVE> => 1

=item * C<ACTIVE> => 2

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails ===
    # Fields for SqlServerUserDetails
    # Field: disabled Type: 8 ()
    # Field: server_roles Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails->new(
        disabled => $value,
    );

=head1 FIELDS

=over 4

=item * B<disabled>

Type: Bool

=item * B<server_roles>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse ===
    # Fields for UsersListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.User)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.User)

=item * B<next_page_token>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersServiceClient - Client stub representing the remote SqlUsersService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head2 credentials

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
        ? Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlUsersService',
        method         => 'Delete',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub get {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlUsersService',
        method         => 'Get',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlUsers::User',
    });
}

sub insert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlUsersService',
        method         => 'Insert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlUsersService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse',
    });
}

sub update {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersUpdateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlUsersService',
        method         => 'Update',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
