package Google::Cloud::Sql::V1::CloudSqlUsers;

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
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF91c2Vycy5wcm90bxITZ29vZ2xlLmNs
b3VkLnNxbC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9j
bGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9jbG91ZC9zcWwvdjEvY2xvdWRfc3FsX3Jlc291
cmNlcy5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIpYBChVTcWxVc2Vyc0RlbGV0ZVJlcXVlc3QSEgoEaG9z
dBgBIAEoCVIEaG9zdBIaCghpbnN0YW5jZRgCIAEoCVIIaW5zdGFuY2USEgoEbmFtZRgDIAEo
CVIEbmFtZRIYCgdwcm9qZWN0GAQgASgJUgdwcm9qZWN0Eh8KCGxvY2F0aW9uGAUgASgJQgPg
QQFSCGxvY2F0aW9uIpMBChJTcWxVc2Vyc0dldFJlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlS
CGluc3RhbmNlEhIKBG5hbWUYAiABKAlSBG5hbWUSGAoHcHJvamVjdBgDIAEoCVIHcHJvamVj
dBISCgRob3N0GAQgASgJUgRob3N0Eh8KCGxvY2F0aW9uGAUgASgJQgPgQQFSCGxvY2F0aW9u
Ip0BChVTcWxVc2Vyc0luc2VydFJlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlSCGluc3RhbmNl
EhgKB3Byb2plY3QYAiABKAlSB3Byb2plY3QSLQoEYm9keRhkIAEoCzIZLmdvb2dsZS5jbG91
ZC5zcWwudjEuVXNlclIEYm9keRIfCghsb2NhdGlvbhgDIAEoCUID4EEBUghsb2NhdGlvbiJs
ChNTcWxVc2Vyc0xpc3RSZXF1ZXN0EhoKCGluc3RhbmNlGAEgASgJUghpbnN0YW5jZRIYCgdw
cm9qZWN0GAIgASgJUgdwcm9qZWN0Eh8KCGxvY2F0aW9uGAMgASgJQgPgQQFSCGxvY2F0aW9u
IuIDChVTcWxVc2Vyc1VwZGF0ZVJlcXVlc3QSFwoEaG9zdBgBIAEoCUID4EEBUgRob3N0EhoK
CGluc3RhbmNlGAIgASgJUghpbnN0YW5jZRISCgRuYW1lGAMgASgJUgRuYW1lEhgKB3Byb2pl
Y3QYBCABKAlSB3Byb2plY3QSKgoOZGF0YWJhc2Vfcm9sZXMYBSADKAlCA+BBAVINZGF0YWJh
c2VSb2xlcxI8ChVyZXZva2VfZXhpc3Rpbmdfcm9sZXMYBiABKAhCA+BBAUgAUhNyZXZva2VF
eGlzdGluZ1JvbGVziAEBEiYKDHNlcnZlcl9yb2xlcxgHIAMoCUID4EEBUgtzZXJ2ZXJSb2xl
cxJJChxyZXZva2VfZXhpc3Rpbmdfc2VydmVyX3JvbGVzGAggASgIQgPgQQFIAVIZcmV2b2tl
RXhpc3RpbmdTZXJ2ZXJSb2xlc4gBARItCgRib2R5GGQgASgLMhkuZ29vZ2xlLmNsb3VkLnNx
bC52MS5Vc2VyUgRib2R5Eh8KCGxvY2F0aW9uGAkgASgJQgPgQQFSCGxvY2F0aW9uQhgKFl9y
ZXZva2VfZXhpc3Rpbmdfcm9sZXNCHwodX3Jldm9rZV9leGlzdGluZ19zZXJ2ZXJfcm9sZXMi
+AIKHFVzZXJQYXNzd29yZFZhbGlkYXRpb25Qb2xpY3kSNgoXYWxsb3dlZF9mYWlsZWRfYXR0
ZW1wdHMYASABKAVSFWFsbG93ZWRGYWlsZWRBdHRlbXB0cxJbChxwYXNzd29yZF9leHBpcmF0
aW9uX2R1cmF0aW9uGAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhpwYXNzd29y
ZEV4cGlyYXRpb25EdXJhdGlvbhI/ChxlbmFibGVfZmFpbGVkX2F0dGVtcHRzX2NoZWNrGAMg
ASgIUhllbmFibGVGYWlsZWRBdHRlbXB0c0NoZWNrEkAKBnN0YXR1cxgEIAEoCzIjLmdvb2ds
ZS5jbG91ZC5zcWwudjEuUGFzc3dvcmRTdGF0dXNCA+BBA1IGc3RhdHVzEkAKHGVuYWJsZV9w
YXNzd29yZF92ZXJpZmljYXRpb24YBSABKAhSGmVuYWJsZVBhc3N3b3JkVmVyaWZpY2F0aW9u
In4KDlBhc3N3b3JkU3RhdHVzEhYKBmxvY2tlZBgBIAEoCFIGbG9ja2VkElQKGHBhc3N3b3Jk
X2V4cGlyYXRpb25fdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSFnBh
c3N3b3JkRXhwaXJhdGlvblRpbWUisAkKBFVzZXISEgoEa2luZBgBIAEoCVIEa2luZBIaCghw
YXNzd29yZBgCIAEoCVIIcGFzc3dvcmQSEgoEZXRhZxgDIAEoCVIEZXRhZxISCgRuYW1lGAQg
ASgJUgRuYW1lEhcKBGhvc3QYBSABKAlCA+BBAVIEaG9zdBIaCghpbnN0YW5jZRgGIAEoCVII
aW5zdGFuY2USGAoHcHJvamVjdBgHIAEoCVIHcHJvamVjdBI5CgR0eXBlGAggASgOMiUuZ29v
Z2xlLmNsb3VkLnNxbC52MS5Vc2VyLlNxbFVzZXJUeXBlUgR0eXBlEmEKFnNxbHNlcnZlcl91
c2VyX2RldGFpbHMYCSABKAsyKS5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbFNlcnZlclVzZXJE
ZXRhaWxzSABSFHNxbHNlcnZlclVzZXJEZXRhaWxzEiAKCWlhbV9lbWFpbBgLIAEoCUID4EEB
UghpYW1FbWFpbBJaCg9wYXNzd29yZF9wb2xpY3kYDCABKAsyMS5nb29nbGUuY2xvdWQuc3Fs
LnYxLlVzZXJQYXNzd29yZFZhbGlkYXRpb25Qb2xpY3lSDnBhc3N3b3JkUG9saWN5El0KEmR1
YWxfcGFzc3dvcmRfdHlwZRgNIAEoDjIqLmdvb2dsZS5jbG91ZC5zcWwudjEuVXNlci5EdWFs
UGFzc3dvcmRUeXBlSAFSEGR1YWxQYXNzd29yZFR5cGWIAQESRwoKaWFtX3N0YXR1cxgOIAEo
DjIjLmdvb2dsZS5jbG91ZC5zcWwudjEuVXNlci5JYW1TdGF0dXNIAlIJaWFtU3RhdHVziAEB
EioKDmRhdGFiYXNlX3JvbGVzGA8gAygJQgPgQQFSDWRhdGFiYXNlUm9sZXMSJgoMc2VydmVy
X3JvbGVzGBAgAygJQgPgQQFSC3NlcnZlclJvbGVzIvEBCgtTcWxVc2VyVHlwZRIMCghCVUlM
VF9JThAAEhIKDkNMT1VEX0lBTV9VU0VSEAESHQoZQ0xPVURfSUFNX1NFUlZJQ0VfQUNDT1VO
VBACEhMKD0NMT1VEX0lBTV9HUk9VUBADEhgKFENMT1VEX0lBTV9HUk9VUF9VU0VSEAQSIwof
Q0xPVURfSUFNX0dST1VQX1NFUlZJQ0VfQUNDT1VOVBAFEiAKHENMT1VEX0lBTV9XT1JLRk9S
Q0VfSURFTlRJVFkQBhIQCgxFTlRSQUlEX1VTRVIQBxIZChVBQ1RJVkVfRElSRUNUT1JZX1VT
RVIQCCJ8ChBEdWFsUGFzc3dvcmRUeXBlEiIKHkRVQUxfUEFTU1dPUkRfVFlQRV9VTlNQRUNJ
RklFRBAAEhsKF05PX01PRElGWV9EVUFMX1BBU1NXT1JEEAESFAoQTk9fRFVBTF9QQVNTV09S
RBACEhEKDURVQUxfUEFTU1dPUkQQAyJBCglJYW1TdGF0dXMSGgoWSUFNX1NUQVRVU19VTlNQ
RUNJRklFRBAAEgwKCElOQUNUSVZFEAESCgoGQUNUSVZFEAJCDgoMdXNlcl9kZXRhaWxzQhUK
E19kdWFsX3Bhc3N3b3JkX3R5cGVCDQoLX2lhbV9zdGF0dXMiVQoUU3FsU2VydmVyVXNlckRl
dGFpbHMSGgoIZGlzYWJsZWQYASABKAhSCGRpc2FibGVkEiEKDHNlcnZlcl9yb2xlcxgCIAMo
CVILc2VydmVyUm9sZXMihAEKEVVzZXJzTGlzdFJlc3BvbnNlEhIKBGtpbmQYASABKAlSBGtp
bmQSLwoFaXRlbXMYAiADKAsyGS5nb29nbGUuY2xvdWQuc3FsLnYxLlVzZXJSBWl0ZW1zEioK
D25leHRfcGFnZV90b2tlbhgDIAEoCUICGAFSDW5leHRQYWdlVG9rZW4y9QYKD1NxbFVzZXJz
U2VydmljZRKPAQoGRGVsZXRlEiouZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxVc2Vyc0RlbGV0
ZVJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbiI5gtPkkwIzKjEvdjEv
cHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L3VzZXJzEosBCgNHZXQS
Jy5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbFVzZXJzR2V0UmVxdWVzdBoZLmdvb2dsZS5jbG91
ZC5zcWwudjEuVXNlciJAgtPkkwI6EjgvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNl
cy97aW5zdGFuY2V9L3VzZXJzL3tuYW1lfRKVAQoGSW5zZXJ0EiouZ29vZ2xlLmNsb3VkLnNx
bC52MS5TcWxVc2Vyc0luc2VydFJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJh
dGlvbiI/gtPkkwI5IjEvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFu
Y2V9L3VzZXJzOgRib2R5EpMBCgRMaXN0EiguZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxVc2Vy
c0xpc3RSZXF1ZXN0GiYuZ29vZ2xlLmNsb3VkLnNxbC52MS5Vc2Vyc0xpc3RSZXNwb25zZSI5
gtPkkwIzEjEvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L3Vz
ZXJzEpUBCgZVcGRhdGUSKi5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbFVzZXJzVXBkYXRlUmVx
dWVzdBoeLmdvb2dsZS5jbG91ZC5zcWwudjEuT3BlcmF0aW9uIj+C0+STAjkaMS92MS9wcm9q
ZWN0cy97cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vdXNlcnM6BGJvZHkafMpBF3Nx
bGFkbWluLmdvb2dsZWFwaXMuY29t0kFfaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3NxbHNl
cnZpY2UuYWRtaW5CWgoXY29tLmdvb2dsZS5jbG91ZC5zcWwudjFCEkNsb3VkU3FsVXNlcnNQ
cm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL3NxbC9hcGl2MS9zcWxwYjtzcWxwYkrYXAoH
EgUOANwCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJ
CgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADcK
CQoCAwUSAxcAKAoJCgIDBhIDGAApCggKAQgSAxoAQAoJCgIICxIDGgBACggKAQgSAxsAIgoJ
CgIIChIDGwAiCggKAQgSAxwAMwoJCgIICBIDHAAzCggKAQgSAx0AMAoJCgIIARIDHQAwCiYK
AgYAEgQgAEoBGhogQ2xvdWQgU1FMIHVzZXJzIHNlcnZpY2UuCgoKCgMGAAESAyAIFwoKCgMG
AAMSAyECPwoMCgUGAAOZCBIDIQI/CgsKAwYAAxIEIgIkOQoNCgUGAAOaCBIEIgIkOQo5CgQG
AAIAEgQnAisDGisgRGVsZXRlcyBhIHVzZXIgZnJvbSBhIENsb3VkIFNRTCBpbnN0YW5jZS4K
CgwKBQYAAgABEgMnBgwKDAoFBgACAAISAycNIgoMCgUGAAIAAxIDJy02Cg0KBQYAAgAEEgQo
BCoGChEKCQYAAgAEsMq8IhIEKAQqBgpJCgQGAAIBEgQuAjIDGjsgUmV0cmlldmVzIGEgcmVz
b3VyY2UgY29udGFpbmluZyBpbmZvcm1hdGlvbiBhYm91dCBhIHVzZXIuCgoMCgUGAAIBARID
LgYJCgwKBQYAAgECEgMuChwKDAoFBgACAQMSAy4nKwoNCgUGAAIBBBIELwQxBgoRCgkGAAIB
BLDKvCISBC8EMQYKOwoEBgACAhIENQI6AxotIENyZWF0ZXMgYSBuZXcgdXNlciBpbiBhIENs
b3VkIFNRTCBpbnN0YW5jZS4KCgwKBQYAAgIBEgM1BgwKDAoFBgACAgISAzUNIgoMCgUGAAIC
AxIDNS02Cg0KBQYAAgIEEgQ2BDkGChEKCQYAAgIEsMq8IhIENgQ5BgpACgQGAAIDEgQ9AkED
GjIgTGlzdHMgdXNlcnMgaW4gdGhlIHNwZWNpZmllZCBDbG91ZCBTUUwgaW5zdGFuY2UuCgoM
CgUGAAIDARIDPQYKCgwKBQYAAgMCEgM9Cx4KDAoFBgACAwMSAz0pOgoNCgUGAAIDBBIEPgRA
BgoRCgkGAAIDBLDKvCISBD4EQAYKQQoEBgACBBIERAJJAxozIFVwZGF0ZXMgYW4gZXhpc3Rp
bmcgdXNlciBpbiBhIENsb3VkIFNRTCBpbnN0YW5jZS4KCgwKBQYAAgQBEgNEBgwKDAoFBgAC
BAISA0QNIgoMCgUGAAIEAxIDRC02Cg0KBQYAAgQEEgRFBEgGChEKCQYAAgQEsMq8IhIERQRI
BgoKCgIEABIETABbAQoKCgMEAAESA0wIHQowCgQEAAIAEgNOAhIaIyBIb3N0IG9mIHRoZSB1
c2VyIGluIHRoZSBpbnN0YW5jZS4KCgwKBQQAAgAFEgNOAggKDAoFBAACAAESA04JDQoMCgUE
AAIAAxIDThARCkoKBAQAAgESA1ECFho9IERhdGFiYXNlIGluc3RhbmNlIElELiBUaGlzIGRv
ZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAAIBBRIDUQIICgwKBQQAAgEB
EgNRCREKDAoFBAACAQMSA1EUFQowCgQEAAICEgNUAhIaIyBOYW1lIG9mIHRoZSB1c2VyIGlu
IHRoZSBpbnN0YW5jZS4KCgwKBQQAAgIFEgNUAggKDAoFBAACAgESA1QJDQoMCgUEAAICAxID
VBARCkQKBAQAAgMSA1cCFRo3IFByb2plY3QgSUQgb2YgdGhlIHByb2plY3QgdGhhdCBjb250
YWlucyB0aGUgaW5zdGFuY2UuCgoMCgUEAAIDBRIDVwIICgwKBQQAAgMBEgNXCRAKDAoFBAAC
AwMSA1cTFAo6CgQEAAIEEgNaAj8aLSBPcHRpb25hbC4gUmVnaW9uIG9mIHRoZSBDbG91ZCBT
UUwgaW5zdGFuY2UuCgoMCgUEAAIEBRIDWgIICgwKBQQAAgQBEgNaCREKDAoFBAACBAMSA1oU
FQoMCgUEAAIECBIDWhY+Cg8KCAQAAgQInAgAEgNaFz0KLwoCBAESBF4AbQEaIyBSZXF1ZXN0
IG1lc3NhZ2UgZm9yIFVzZXJzIEdldCBSUEMKCgoKAwQBARIDXggaCkoKBAQBAgASA2ACFho9
IERhdGFiYXNlIGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2pl
Y3QgSUQuCgoMCgUEAQIABRIDYAIICgwKBQQBAgABEgNgCREKDAoFBAECAAMSA2AUFQokCgQE
AQIBEgNjAhIaFyBVc2VyIG9mIHRoZSBpbnN0YW5jZS4KCgwKBQQBAgEFEgNjAggKDAoFBAEC
AQESA2MJDQoMCgUEAQIBAxIDYxARCkQKBAQBAgISA2YCFRo3IFByb2plY3QgSUQgb2YgdGhl
IHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoMCgUEAQICBRIDZgIICgwK
BQQBAgIBEgNmCRAKDAoFBAECAgMSA2YTFAouCgQEAQIDEgNpAhIaISBIb3N0IG9mIGEgdXNl
ciBvZiB0aGUgaW5zdGFuY2UuCgoMCgUEAQIDBRIDaQIICgwKBQQBAgMBEgNpCQ0KDAoFBAEC
AwMSA2kQEQo6CgQEAQIEEgNsAj8aLSBPcHRpb25hbC4gUmVnaW9uIG9mIHRoZSBDbG91ZCBT
UUwgaW5zdGFuY2UuCgoMCgUEAQIEBRIDbAIICgwKBQQBAgQBEgNsCREKDAoFBAECBAMSA2wU
FQoMCgUEAQIECBIDbBY+Cg8KCAQBAgQInAgAEgNsFz0KCgoCBAISBG8AegEKCgoDBAIBEgNv
CB0KSgoEBAICABIDcQIWGj0gRGF0YWJhc2UgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3Qg
aW5jbHVkZSB0aGUgcHJvamVjdCBJRC4KCgwKBQQCAgAFEgNxAggKDAoFBAICAAESA3EJEQoM
CgUEAgIAAxIDcRQVCkQKBAQCAgESA3QCFRo3IFByb2plY3QgSUQgb2YgdGhlIHByb2plY3Qg
dGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoMCgUEAgIBBRIDdAIICgwKBQQCAgEBEgN0
CRAKDAoFBAICAQMSA3QTFAoLCgQEAgICEgN2AhIKDAoFBAICAgYSA3YCBgoMCgUEAgICARID
dgcLCgwKBQQCAgIDEgN2DhEKOgoEBAICAxIDeQI/Gi0gT3B0aW9uYWwuIFJlZ2lvbiBvZiB0
aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDAoFBAICAwUSA3kCCAoMCgUEAgIDARIDeQkRCgwK
BQQCAgMDEgN5FBUKDAoFBAICAwgSA3kWPgoPCggEAgIDCJwIABIDeRc9CgsKAgQDEgV8AIUB
AQoKCgMEAwESA3wIGwpKCgQEAwIAEgN+AhYaPSBEYXRhYmFzZSBpbnN0YW5jZSBJRC4gVGhp
cyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDAoFBAMCAAUSA34CCAoMCgUE
AwIAARIDfgkRCgwKBQQDAgADEgN+FBUKRQoEBAMCARIEgQECFRo3IFByb2plY3QgSUQgb2Yg
dGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoNCgUEAwIBBRIEgQEC
CAoNCgUEAwIBARIEgQEJEAoNCgUEAwIBAxIEgQETFAo7CgQEAwICEgSEAQI/Gi0gT3B0aW9u
YWwuIFJlZ2lvbiBvZiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLgoKDQoFBAMCAgUSBIQBAggK
DQoFBAMCAgESBIQBCREKDQoFBAMCAgMSBIQBFBUKDQoFBAMCAggSBIQBFj4KEAoIBAMCAgic
CAASBIQBFz0KDAoCBAQSBocBAK0BAQoLCgMEBAESBIcBCB0KOwoEBAQCABIEiQECOxotIE9w
dGlvbmFsLiBIb3N0IG9mIHRoZSB1c2VyIGluIHRoZSBpbnN0YW5jZS4KCg0KBQQEAgAFEgSJ
AQIICg0KBQQEAgABEgSJAQkNCg0KBQQEAgADEgSJARARCg0KBQQEAgAIEgSJARI6ChAKCAQE
AgAInAgAEgSJARM5CksKBAQEAgESBIwBAhYaPSBEYXRhYmFzZSBpbnN0YW5jZSBJRC4gVGhp
cyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDQoFBAQCAQUSBIwBAggKDQoF
BAQCAQESBIwBCREKDQoFBAQCAQMSBIwBFBUKMQoEBAQCAhIEjwECEhojIE5hbWUgb2YgdGhl
IHVzZXIgaW4gdGhlIGluc3RhbmNlLgoKDQoFBAQCAgUSBI8BAggKDQoFBAQCAgESBI8BCQ0K
DQoFBAQCAgMSBI8BEBEKRQoEBAQCAxIEkgECFRo3IFByb2plY3QgSUQgb2YgdGhlIHByb2pl
Y3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoNCgUEBAIDBRIEkgECCAoNCgUEBAID
ARIEkgEJEAoNCgUEBAIDAxIEkgETFAp/CgQEBAIEEgSWAQJOGnEgT3B0aW9uYWwuIExpc3Qg
b2YgZGF0YWJhc2Ugcm9sZXMgdG8gZ3JhbnQgdG8gdGhlIHVzZXIuIGJvZHkuZGF0YWJhc2Vf
cm9sZXMKIHdpbGwgYmUgaWdub3JlZCBmb3IgdXBkYXRlIHJlcXVlc3QuCgoNCgUEBAIEBBIE
lgECCgoNCgUEBAIEBRIElgELEQoNCgUEBAIEARIElgESIAoNCgUEBAIEAxIElgEjJAoNCgUE
BAIECBIElgElTQoQCggEBAIECJwIABIElgEmTArrAQoEBAQCBRIGmwECnAEvGtoBIE9wdGlv
bmFsLiBTcGVjaWZpZXMgd2hldGhlciB0byByZXZva2UgZXhpc3Rpbmcgcm9sZXMgdGhhdCBh
cmUgbm90IHByZXNlbnQKIGluIHRoZSBgZGF0YWJhc2Vfcm9sZXNgIGZpZWxkLiBJZiBgZmFs
c2VgIG9yIHVuc2V0LCB0aGUgZGF0YWJhc2Ugcm9sZXMKIHNwZWNpZmllZCBpbiBgZGF0YWJh
c2Vfcm9sZXNgIGFyZSBhZGRlZCB0byB0aGUgdXNlcidzIGV4aXN0aW5nIHJvbGVzLgoKDQoF
BAQCBQQSBJsBAgoKDQoFBAQCBQUSBJsBCw8KDQoFBAQCBQESBJsBECUKDQoFBAQCBQMSBJsB
KCkKDQoFBAQCBQgSBJwBBi4KEAoIBAQCBQicCAASBJwBBy0K0gEKBAQEAgYSBKEBAkwawwEg
T3B0aW9uYWwuIFRoZSBzZXJ2ZXIgcm9sZXMgdG8gZ3JhbnQgdG8gdGhlIFNRTCBTZXJ2ZXIg
bG9naW4uIEV4aXN0aW5nCiBzZXJ2ZXIgcm9sZXMgd2lsbCBub3QgYmUgcmV2b2tlZCBpZiBy
ZXZva2VfZXhpc3Rpbmdfcm9sZXMgaXMgZmFsc2UuCiBib2R5LnNlcnZlcl9yb2xlcyB3aWxs
IGJlIGlnbm9yZWQgZm9yIHVwZGF0ZSByZXF1ZXN0LgoKDQoFBAQCBgQSBKEBAgoKDQoFBAQC
BgUSBKEBCxEKDQoFBAQCBgESBKEBEh4KDQoFBAQCBgMSBKEBISIKDQoFBAQCBggSBKEBI0sK
EAoIBAQCBgicCAASBKEBJEoK7AEKBAQEAgcSBqYBAqcBLxrbASBPcHRpb25hbC4gU3BlY2lm
aWVzIHdoZXRoZXIgdG8gcmV2b2tlIGV4aXN0aW5nIHJvbGVzIHRoYXQgYXJlIG5vdCBwcmVz
ZW50CiBpbiB0aGUgYHNlcnZlcl9yb2xlc2AgZmllbGQuIElmIGBmYWxzZWAgb3IgdW5zZXQs
IHRoZSBzZXJ2ZXIgcm9sZXMKIHNwZWNpZmllZCBpbiBgc2VydmVyX3JvbGVzYCBhcmUgYWRk
ZWQgdG8gdGhlIHVzZXIncyBleGlzdGluZyBzZXJ2ZXIgcm9sZXMuCgoNCgUEBAIHBBIEpgEC
CgoNCgUEBAIHBRIEpgELDwoNCgUEBAIHARIEpgEQLAoNCgUEBAIHAxIEpgEvMAoNCgUEBAIH
CBIEpwEGLgoQCggEBAIHCJwIABIEpwEHLQoMCgQEBAIIEgSpAQISCg0KBQQEAggGEgSpAQIG
Cg0KBQQEAggBEgSpAQcLCg0KBQQEAggDEgSpAQ4RCjsKBAQEAgkSBKwBAj8aLSBPcHRpb25h
bC4gUmVnaW9uIG9mIHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UuCgoNCgUEBAIJBRIErAECCAoN
CgUEBAIJARIErAEJEQoNCgUEBAIJAxIErAEUFQoNCgUEBAIJCBIErAEWPgoQCggEBAIJCJwI
ABIErAEXPQo2CgIEBRIGsAEAwAEBGiggVXNlciBsZXZlbCBwYXNzd29yZCB2YWxpZGF0aW9u
IHBvbGljeS4KCgsKAwQFARIEsAEIJApPCgQEBQIAEgSyAQIkGkEgTnVtYmVyIG9mIGZhaWxl
ZCBsb2dpbiBhdHRlbXB0cyBhbGxvd2VkIGJlZm9yZSB1c2VyIGdldCBsb2NrZWQuCgoNCgUE
BQIABRIEsgECBwoNCgUEBQIAARIEsgEIHwoNCgUEBQIAAxIEsgEiIwo+CgQEBQIBEgS1AQI8
GjAgRXhwaXJhdGlvbiBkdXJhdGlvbiBhZnRlciBwYXNzd29yZCBpcyB1cGRhdGVkLgoKDQoF
BAUCAQYSBLUBAhoKDQoFBAUCAQESBLUBGzcKDQoFBAUCAQMSBLUBOjsKRQoEBAUCAhIEuAEC
KBo3IElmIHRydWUsIGZhaWxlZCBsb2dpbiBhdHRlbXB0cyBjaGVjayB3aWxsIGJlIGVuYWJs
ZWQuCgoNCgUEBQICBRIEuAECBgoNCgUEBQICARIEuAEHIwoNCgUEBQICAxIEuAEmJwo3CgQE
BQIDEgS7AQJIGikgT3V0cHV0IG9ubHkuIFJlYWQtb25seSBwYXNzd29yZCBzdGF0dXMuCgoN
CgUEBQIDBhIEuwECEAoNCgUEBQIDARIEuwERFwoNCgUEBQIDAxIEuwEaGwoNCgUEBQIDCBIE
uwEcRwoQCggEBQIDCJwIABIEuwEdRgqJAQoEBAUCBBIEvwECKBp7IElmIHRydWUsIHRoZSB1
c2VyIG11c3Qgc3BlY2lmeSB0aGUgY3VycmVudCBwYXNzd29yZCBiZWZvcmUgY2hhbmdpbmcg
dGhlCiBwYXNzd29yZC4gVGhpcyBmbGFnIGlzIHN1cHBvcnRlZCBvbmx5IGZvciBNeVNRTC4K
Cg0KBQQFAgQFEgS/AQIGCg0KBQQFAgQBEgS/AQcjCg0KBQQFAgQDEgS/ASYnCioKAgQGEgbD
AQDJAQEaHCBSZWFkLW9ubHkgcGFzc3dvcmQgc3RhdHVzLgoKCwoDBAYBEgTDAQgWCj0KBAQG
AgASBMUBAhIaLyBJZiB0cnVlLCB1c2VyIGRvZXMgbm90IGhhdmUgbG9naW4gcHJpdmlsZWdl
cy4KCg0KBQQGAgAFEgTFAQIGCg0KBQQGAgABEgTFAQcNCg0KBQQGAgADEgTFARARCjwKBAQG
AgESBMgBAjkaLiBUaGUgZXhwaXJhdGlvbiB0aW1lIG9mIHRoZSBjdXJyZW50IHBhc3N3b3Jk
LgoKDQoFBAYCAQYSBMgBAhsKDQoFBAYCAQESBMgBHDQKDQoFBAYCAQMSBMgBNzgKKgoCBAcS
BswBAMcCARocIEEgQ2xvdWQgU1FMIHVzZXIgcmVzb3VyY2UuCgoLCgMEBwESBMwBCAwKIAoE
BAcEABIGzgEC6wEDGhAgVGhlIHVzZXIgdHlwZS4KCg0KBQQHBAABEgTOAQcSCjQKBgQHBAAC
ABIE0AEEERokIFRoZSBkYXRhYmFzZSdzIGJ1aWx0LWluIHVzZXIgdHlwZS4KCg8KBwQHBAAC
AAESBNABBAwKDwoHBAcEAAIAAhIE0AEPEAohCgYEBwQAAgESBNMBBBcaESBDbG91ZCBJQU0g
dXNlci4KCg8KBwQHBAACAQESBNMBBBIKDwoHBAcEAAIBAhIE0wEVFgosCgYEBwQAAgISBNYB
BCIaHCBDbG91ZCBJQU0gc2VydmljZSBhY2NvdW50LgoKDwoHBAcEAAICARIE1gEEHQoPCgcE
BwQAAgICEgTWASAhCjYKBgQHBAACAxIE2QEEGBomIENsb3VkIElBTSBncm91cC4gTm90IHVz
ZWQgZm9yIGxvZ2luLgoKDwoHBAcEAAIDARIE2QEEEwoPCgcEBwQAAgMCEgTZARYXClIKBgQH
BAACBBIE3AEEHRpCIFJlYWQtb25seS4gTG9naW4gZm9yIGEgdXNlciB0aGF0IGJlbG9uZ3Mg
dG8gdGhlIENsb3VkIElBTSBncm91cC4KCg8KBwQHBAACBAESBNwBBBgKDwoHBAcEAAIEAhIE
3AEbHApeCgYEBwQAAgUSBOABBCgaTiBSZWFkLW9ubHkuIExvZ2luIGZvciBhIHNlcnZpY2Ug
YWNjb3VudCB0aGF0IGJlbG9uZ3MgdG8gdGhlCiBDbG91ZCBJQU0gZ3JvdXAuCgoPCgcEBwQA
AgUBEgTgAQQjCg8KBwQHBAACBQISBOABJicKWQoGBAcEAAIGEgTkAQQlGkkgQ2xvdWQgSUFN
IHdvcmtmb3JjZSBpZGVudGl0eSBtYW5hZ2VkIGJ5IFdvcmtmb3JjZSBJZGVudGl0eQogRmVk
ZXJhdGlvbi4KCg8KBwQHBAACBgESBOQBBCAKDwoHBAcEAAIGAhIE5AEjJAoqCgYEBwQAAgcS
BOcBBBUaGiBNaWNyb3NvZnQgRW50cmEgSUQgdXNlci4KCg8KBwQHBAACBwESBOcBBBAKDwoH
BAcEAAIHAhIE5wETFAooCgYEBwQAAggSBOoBBB4aGCBBY3RpdmUgRGlyZWN0b3J5IHVzZXIu
CgoPCgcEBwQAAggBEgTqAQQZCg8KBwQHBAACCAISBOoBHB0KMAoEBAcEARIG7gEC+gEDGiAg
VGhlIHR5cGUgb2YgcmV0YWluZWQgcGFzc3dvcmQuCgoNCgUEBwQBARIE7gEHFwokCgYEBwQB
AgASBPABBCcaFCBUaGUgZGVmYXVsdCB2YWx1ZS4KCg8KBwQHBAECAAESBPABBCIKDwoHBAcE
AQIAAhIE8AElJgpACgYEBwQBAgESBPMBBCAaMCBEbyBub3QgdXBkYXRlIHRoZSB1c2VyJ3Mg
ZHVhbCBwYXNzd29yZCBzdGF0dXMuCgoPCgcEBwQBAgEBEgTzAQQbCg8KBwQHBAECAQISBPMB
Hh8KSQoGBAcEAQICEgT2AQQZGjkgTm8gZHVhbCBwYXNzd29yZCB1c2FibGUgZm9yIGNvbm5l
Y3RpbmcgdXNpbmcgdGhpcyB1c2VyLgoKDwoHBAcEAQICARIE9gEEFAoPCgcEBwQBAgICEgT2
ARcYCkYKBgQHBAECAxIE+QEEFho2IER1YWwgcGFzc3dvcmQgdXNhYmxlIGZvciBjb25uZWN0
aW5nIHVzaW5nIHRoaXMgdXNlci4KCg8KBwQHBAECAwESBPkBBBEKDwoHBAcEAQIDAhIE+QEU
FQpUCgQEBwQCEgb9AQKLAgMaRCBJbmRpY2F0ZXMgaWYgYSBncm91cCBpcyBhdmFpbGFibGUg
Zm9yIElBTSBkYXRhYmFzZSBhdXRoZW50aWNhdGlvbi4KCg0KBQQHBAIBEgT9AQcQCpkCCgYE
BwQCAgASBIMCBB8aiAIgVGhlIGRlZmF1bHQgdmFsdWUgZm9yIHVzZXJzIHRoYXQgYXJlIG5v
dCBvZiB0eXBlIENMT1VEX0lBTV9HUk9VUC4KIE9ubHkgQ0xPVURfSUFNX0dST1VQIHVzZXJz
IHdpbGwgYmUgaW5hY3RpdmUgb3IgYWN0aXZlLgogVXNlcnMgd2l0aCBhbiBJYW1TdGF0dXMg
b2YgSUFNX1NUQVRVU19VTlNQRUNJRklFRCB3aWxsIG5vdAogZGlzcGxheSB3aGV0aGVyIHRo
ZXkgYXJlIGFjdGl2ZSBvciBpbmFjdGl2ZSBhcyB0aGF0IGlzIG5vdCBhcHBsaWNhYmxlIHRv
CiB0aGVtLgoKDwoHBAcEAgIAARIEgwIEGgoPCgcEBwQCAgACEgSDAh0eCl8KBgQHBAICARIE
hwIEERpPIElOQUNUSVZFIGluZGljYXRlcyBhIGdyb3VwIGlzIG5vdCBhdmFpbGFibGUgZm9y
IElBTSBkYXRhYmFzZQogYXV0aGVudGljYXRpb24uCgoPCgcEBwQCAgEBEgSHAgQMCg8KBwQH
BAICAQISBIcCDxAKWAoGBAcEAgICEgSKAgQPGkggQUNUSVZFIGluZGljYXRlcyBhIGdyb3Vw
IGlzIGF2YWlsYWJsZSBmb3IgSUFNIGRhdGFiYXNlIGF1dGhlbnRpY2F0aW9uLgoKDwoHBAcE
AgICARIEigIECgoPCgcEBwQCAgICEgSKAg0OCioKBAQHAgASBI4CAhIaHCBUaGlzIGlzIGFs
d2F5cyBgc3FsI3VzZXJgLgoKDQoFBAcCAAUSBI4CAggKDQoFBAcCAAESBI4CCQ0KDQoFBAcC
AAMSBI4CEBEKKgoEBAcCARIEkQICFhocIFRoZSBwYXNzd29yZCBmb3IgdGhlIHVzZXIuCgoN
CgUEBwIBBRIEkQICCAoNCgUEBwIBARIEkQIJEQoNCgUEBwIBAxIEkQIUFQpfCgQEBwICEgSV
AgISGlEgVGhpcyBmaWVsZCBpcyBkZXByZWNhdGVkIGFuZCB3aWxsIGJlIHJlbW92ZWQgZnJv
bSBhIGZ1dHVyZSB2ZXJzaW9uIG9mIHRoZQogQVBJLgoKDQoFBAcCAgUSBJUCAggKDQoFBAcC
AgESBJUCCQ0KDQoFBAcCAgMSBJUCEBEKiAEKBAQHAgMSBJkCAhIaeiBUaGUgbmFtZSBvZiB0
aGUgdXNlciBpbiB0aGUgQ2xvdWQgU1FMIGluc3RhbmNlLiBDYW4gYmUgb21pdHRlZCBmb3IK
IGB1cGRhdGVgIGJlY2F1c2UgaXQgaXMgYWxyZWFkeSBzcGVjaWZpZWQgaW4gdGhlIFVSTC4K
Cg0KBQQHAgMFEgSZAgIICg0KBQQHAgMBEgSZAgkNCg0KBQQHAgMDEgSZAhARCtkCCgQEBwIE
EgSgAgI7GsoCIE9wdGlvbmFsLiBUaGUgaG9zdCBmcm9tIHdoaWNoIHRoZSB1c2VyIGNhbiBj
b25uZWN0LiBGb3IgYGluc2VydGAKIG9wZXJhdGlvbnMsIGhvc3QgZGVmYXVsdHMgdG8gYW4g
ZW1wdHkgc3RyaW5nLiBGb3IgYHVwZGF0ZWAKIG9wZXJhdGlvbnMsIGhvc3QgaXMgc3BlY2lm
aWVkIGFzIHBhcnQgb2YgdGhlIHJlcXVlc3QgVVJMLiBUaGUgaG9zdCBuYW1lCiBjYW5ub3Qg
YmUgdXBkYXRlZCBhZnRlciBpbnNlcnRpb24uICBGb3IgYSBNeVNRTCBpbnN0YW5jZSwgaXQn
cyByZXF1aXJlZDsKIGZvciBhIFBvc3RncmVTUUwgb3IgU1FMIFNlcnZlciBpbnN0YW5jZSwg
aXQncyBvcHRpb25hbC4KCg0KBQQHAgQFEgSgAgIICg0KBQQHAgQBEgSgAgkNCg0KBQQHAgQD
EgSgAhARCg0KBQQHAgQIEgSgAhI6ChAKCAQHAgQInAgAEgSgAhM5CqQBCgQEBwIFEgSlAgIW
GpUBIFRoZSBuYW1lIG9mIHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UuIFRoaXMgZG9lcyBub3Qg
aW5jbHVkZSB0aGUgcHJvamVjdCBJRC4KIENhbiBiZSBvbWl0dGVkIGZvciBgdXBkYXRlYCBi
ZWNhdXNlIGl0IGlzIGFscmVhZHkgc3BlY2lmaWVkIG9uIHRoZQogVVJMLgoKDQoFBAcCBQUS
BKUCAggKDQoFBAcCBQESBKUCCREKDQoFBAcCBQMSBKUCFBUKzQEKBAQHAgYSBKoCAhUavgEg
VGhlIHByb2plY3QgSUQgb2YgdGhlIHByb2plY3QgY29udGFpbmluZyB0aGUgQ2xvdWQgU1FM
IGRhdGFiYXNlLiBUaGUgR29vZ2xlCiBhcHBzIGRvbWFpbiBpcyBwcmVmaXhlZCBpZiBhcHBs
aWNhYmxlLiBDYW4gYmUgb21pdHRlZCBmb3IgYHVwZGF0ZWAgYmVjYXVzZQogaXQgaXMgYWxy
ZWFkeSBzcGVjaWZpZWQgb24gdGhlIFVSTC4KCg0KBQQHAgYFEgSqAgIICg0KBQQHAgYBEgSq
AgkQCg0KBQQHAgYDEgSqAhMUCpIBCgQEBwIHEgSuAgIXGoMBIFRoZSB1c2VyIHR5cGUuIEl0
IGRldGVybWluZXMgdGhlIG1ldGhvZCB0byBhdXRoZW50aWNhdGUgdGhlIHVzZXIgZHVyaW5n
CiBsb2dpbi4gVGhlIGRlZmF1bHQgaXMgdGhlIGRhdGFiYXNlJ3MgYnVpbHQtaW4gdXNlciB0
eXBlLgoKDQoFBAcCBwYSBK4CAg0KDQoFBAcCBwESBK4CDhIKDQoFBAcCBwMSBK4CFRYKOQoE
BAcIABIGsQICswIDGikgVXNlciBkZXRhaWxzIGZvciBzcGVjaWZpYyBkYXRhYmFzZSB0eXBl
CgoNCgUEBwgAARIEsQIIFAoMCgQEBwIIEgSyAgQ0Cg0KBQQHAggGEgSyAgQYCg0KBQQHAggB
EgSyAhkvCg0KBQQHAggDEgSyAjIzCpgBCgQEBwIJEgS3AgJBGokBIE9wdGlvbmFsLiBUaGUg
ZnVsbCBlbWFpbCBmb3IgYW4gSUFNIHVzZXIuIEZvciBub3JtYWwgZGF0YWJhc2UgdXNlcnMs
IHRoaXMKIHdpbGwgbm90IGJlIGZpbGxlZC4gT25seSBhcHBsaWNhYmxlIHRvIE15U1FMIGRh
dGFiYXNlIHVzZXJzLgoKDQoFBAcCCQUSBLcCAggKDQoFBAcCCQESBLcCCRIKDQoFBAcCCQMS
BLcCFRcKDQoFBAcCCQgSBLcCGEAKEAoIBAcCCQicCAASBLcCGT8KNgoEBAcCChIEugICNBoo
IFVzZXIgbGV2ZWwgcGFzc3dvcmQgdmFsaWRhdGlvbiBwb2xpY3kuCgoNCgUEBwIKBhIEugIC
HgoNCgUEBwIKARIEugIfLgoNCgUEBwIKAxIEugIxMwoyCgQEBwILEgS9AgI0GiQgRHVhbCBw
YXNzd29yZCBzdGF0dXMgZm9yIHRoZSB1c2VyLgoKDQoFBAcCCwQSBL0CAgoKDQoFBAcCCwYS
BL0CCxsKDQoFBAcCCwESBL0CHC4KDQoFBAcCCwMSBL0CMTMKWwoEBAcCDBIEwAICJRpNIElu
ZGljYXRlcyBpZiBhIGdyb3VwIGlzIGFjdGl2ZSBvciBpbmFjdGl2ZSBmb3IgSUFNIGRhdGFi
YXNlIGF1dGhlbnRpY2F0aW9uLgoKDQoFBAcCDAQSBMACAgoKDQoFBAcCDAYSBMACCxQKDQoF
BAcCDAESBMACFR8KDQoFBAcCDAMSBMACIiQKNgoEBAcCDRIEwwICTxooIE9wdGlvbmFsLiBS
b2xlIG1lbWJlcnNoaXBzIG9mIHRoZSB1c2VyCgoNCgUEBwINBBIEwwICCgoNCgUEBwINBRIE
wwILEQoNCgUEBwINARIEwwISIAoNCgUEBwINAxIEwwIjJQoNCgUEBwINCBIEwwImTgoQCggE
BwINCJwIABIEwwInTQpECgQEBwIOEgTGAgJNGjYgT3B0aW9uYWwuIFRoZSBzZXJ2ZXIgcm9s
ZXMgZm9yIHRoZSBTUUwgU2VydmVyIGxvZ2luLgoKDQoFBAcCDgQSBMYCAgoKDQoFBAcCDgUS
BMYCCxEKDQoFBAcCDgESBMYCEh4KDQoFBAcCDgMSBMYCISMKDQoFBAcCDggSBMYCJEwKEAoI
BAcCDgicCAASBMYCJUsKRwoCBAgSBsoCANACARo5IFJlcHJlc2VudHMgYSBTcWwgU2VydmVy
IHVzZXIgb24gdGhlIENsb3VkIFNRTCBpbnN0YW5jZS4KCgsKAwQIARIEygIIHAo4CgQECAIA
EgTMAgIUGiogSW5kaWNhdGVzIGlmIHRoZSB1c2VyIGhhcyBiZWVuIGRpc2FibGVkLgoKDQoF
BAgCAAUSBMwCAgYKDQoFBAgCAAESBMwCBw8KDQoFBAgCAAMSBMwCEhMKOQoEBAgCARIEzwIC
IxorIEluZGljYXRlcyB0aGUgc2VydmVyIHJvbGVzIGZvciB0aGlzIHVzZXIuCgoNCgUECAIB
BBIEzwICCgoNCgUECAIBBRIEzwILEQoNCgUECAIBARIEzwISHgoNCgUECAIBAxIEzwIhIgoj
CgIECRIG0wIA3AIBGhUgVXNlciBsaXN0IHJlc3BvbnNlLgoKCwoDBAkBEgTTAggZCi8KBAQJ
AgASBNUCAhIaISBUaGlzIGlzIGFsd2F5cyBgc3FsI3VzZXJzTGlzdGAuCgoNCgUECQIABRIE
1QICCAoNCgUECQIAARIE1QIJDQoNCgUECQIAAxIE1QIQEQo3CgQECQIBEgTYAgIaGikgTGlz
dCBvZiB1c2VyIHJlc291cmNlcyBpbiB0aGUgaW5zdGFuY2UuCgoNCgUECQIBBBIE2AICCgoN
CgUECQIBBhIE2AILDwoNCgUECQIBARIE2AIQFQoNCgUECQIBAxIE2AIYGQoXCgQECQICEgTb
AgIxGgkgVW51c2VkLgoKDQoFBAkCAgUSBNsCAggKDQoFBAkCAgESBNsCCRgKDQoFBAkCAgMS
BNsCGxwKDQoFBAkCAggSBNsCHTAKDgoGBAkCAggDEgTbAh4vYgZwcm90bzM=
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
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest ===
    # Fields for SqlUsersGetRequest
    # Field: instance Type: 9 ()
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()
    # Field: host Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest ===
    # Fields for SqlUsersInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.User)
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest ===
    # Fields for SqlUsersListRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

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
    # Field: location Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy ===
    # Fields for UserPasswordValidationPolicy
    # Field: allowed_failed_attempts Type: 5 ()
    # Field: password_expiration_duration Type: 11 (.google.protobuf.Duration)
    # Field: enable_failed_attempts_check Type: 8 ()
    # Field: status Type: 11 (.google.cloud.sql.v1.PasswordStatus)
    # Field: enable_password_verification Type: 8 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus ===
    # Fields for PasswordStatus
    # Field: locked Type: 8 ()
    # Field: password_expiration_time Type: 11 (.google.protobuf.Timestamp)

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

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails ===
    # Fields for SqlServerUserDetails
    # Field: disabled Type: 8 ()
    # Field: server_roles Type: 9 ()

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse ===
    # Fields for UsersListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.User)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersServiceClient

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

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlUsers - Compiled Protocol Buffers messages for google/cloud/sql/v1/cloud_sql_users.proto

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlUsers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest->new({
        host => $host,
        instance => $instance,
        name => $name,
        project => $project,
    });

    # Read or update a field
    my $val = $msg->host();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1/cloud_sql_users.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersDeleteRequest

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

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest

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

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest

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

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlUsers::User>)

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. Region of the Cloud SQL instance.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest

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

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersUpdateRequest

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

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlUsers::User>)

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. Region of the Cloud SQL instance.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy

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

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus>)

Output only. Read-only password status.

=item * C<< $msg->enable_password_verification() >> / C<< $msg->enable_password_verification($value) >>

Type: C<Bool>

If true, the user must specify the current password before changing the
password. This flag is supported only for MySQL.

=back

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::PasswordStatus

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

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::User

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
Can be omitted for `update` because it is already specified on the
URL.

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

The project ID of the project containing the Cloud SQL database. The Google
apps domain is prefixed if applicable. Can be omitted for `update` because
it is already specified on the URL.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::User::SqlUserType>)

The user type. It determines the method to authenticate the user during
login. The default is the database's built-in user type.

=item * C<< $msg->sqlserver_user_details() >> / C<< $msg->sqlserver_user_details($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails>)

=item * C<< $msg->iam_email() >> / C<< $msg->iam_email($value) >>

Type: C<String>

Optional. The full email for an IAM user. For normal database users, this
will not be filled. Only applicable to MySQL database users.

=item * C<< $msg->password_policy() >> / C<< $msg->password_policy($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlUsers::UserPasswordValidationPolicy>)

User level password validation policy.

=item * C<< $msg->dual_password_type() >> / C<< $msg->dual_password_type($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::User::DualPasswordType>)

Dual password status for the user.

=item * C<< $msg->iam_status() >> / C<< $msg->iam_status($value) >>

Type: C<Enum> (L<Google::Cloud::Sql::V1::User::IamStatus>)

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

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::SqlServerUserDetails

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

=head2 Google::Cloud::Sql::V1::CloudSqlUsers::UsersListResponse

User list response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

This is always `sql#usersList`.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1::CloudSqlUsers::User>)

List of user resources in the instance.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Unused.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1::CloudSqlUsers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
