package Google::Cloud::Sql::V1::CloudSqlUsers;

use strict;
use warnings;

our $VERSION = '0.12';

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

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersGetRequest ===
    # Fields for SqlUsersGetRequest
    # Field: instance Type: 9 ()
    # Field: name Type: 9 ()
    # Field: project Type: 9 ()
    # Field: host Type: 9 ()
    # Field: location Type: 9 ()

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

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersInsertRequest ===
    # Fields for SqlUsersInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.User)
    # Field: location Type: 9 ()

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

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlUsers::SqlUsersListRequest ===
    # Fields for SqlUsersListRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

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

=item * B<location>

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
    # Field: location Type: 9 ()

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

=item * B<location>

Type: String

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
our $User_ACTIVE_DIRECTORY_USER = 8;

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

=item * C<ACTIVE_DIRECTORY_USER> => 8

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
