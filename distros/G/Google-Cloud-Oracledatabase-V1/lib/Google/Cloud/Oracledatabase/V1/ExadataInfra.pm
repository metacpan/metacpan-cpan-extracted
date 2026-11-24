package Google::Cloud::Oracledatabase::V1::ExadataInfra;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Oracledatabase::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Dayofweek };
    eval { require Google::Type::Month };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZXhhZGF0YV9pbmZyYS5wcm90bxIe
Z29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVz
b3VyY2UucHJvdG8aK2dvb2dsZS9jbG91ZC9vcmFjbGVkYXRhYmFzZS92MS9jb21tb24ucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aG2dvb2dsZS90eXBlL2RheW9m
d2Vlay5wcm90bxoXZ29vZ2xlL3R5cGUvbW9udGgucHJvdG8i6gUKGkNsb3VkRXhhZGF0YUlu
ZnJhc3RydWN0dXJlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIpCgxkaXNwbGF5X25hbWUY
AiABKAlCBuBBAeBBBVILZGlzcGxheU5hbWUSLgoPZ2NwX29yYWNsZV96b25lGAggASgJQgbg
QQHgQQVSDWdjcE9yYWNsZVpvbmUSKgoOZW50aXRsZW1lbnRfaWQYBCABKAlCA+BBA1INZW50
aXRsZW1lbnRJZBJsCgpwcm9wZXJ0aWVzGAUgASgLMkQuZ29vZ2xlLmNsb3VkLm9yYWNsZWRh
dGFiYXNlLnYxLkNsb3VkRXhhZGF0YUluZnJhc3RydWN0dXJlUHJvcGVydGllc0IG4EEB4EEF
Ugpwcm9wZXJ0aWVzEmMKBmxhYmVscxgGIAMoCzJGLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRh
YmFzZS52MS5DbG91ZEV4YWRhdGFJbmZyYXN0cnVjdHVyZS5MYWJlbHNFbnRyeUID4EEBUgZs
YWJlbHMSQAoLY3JlYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCmNyZWF0ZVRpbWUaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoF
dmFsdWUYAiABKAlSBXZhbHVlOgI4ATrbAepB1wEKOG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFw
aXMuY29tL0Nsb3VkRXhhZGF0YUluZnJhc3RydWN0dXJlEmJwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vY2xvdWRFeGFkYXRhSW5mcmFzdHJ1Y3R1cmVzL3tjbG91
ZF9leGFkYXRhX2luZnJhc3RydWN0dXJlfSobY2xvdWRFeGFkYXRhSW5mcmFzdHJ1Y3R1cmVz
MhpjbG91ZEV4YWRhdGFJbmZyYXN0cnVjdHVyZSKuEAokQ2xvdWRFeGFkYXRhSW5mcmFzdHJ1
Y3R1cmVQcm9wZXJ0aWVzEhcKBG9jaWQYASABKAlCA+BBA1IEb2NpZBIoCg1jb21wdXRlX2Nv
dW50GAIgASgFQgPgQQFSDGNvbXB1dGVDb3VudBIoCg1zdG9yYWdlX2NvdW50GAMgASgFQgPg
QQFSDHN0b3JhZ2VDb3VudBI2ChV0b3RhbF9zdG9yYWdlX3NpemVfZ2IYBCABKAVCA+BBAVIS
dG90YWxTdG9yYWdlU2l6ZUdiEj4KGWF2YWlsYWJsZV9zdG9yYWdlX3NpemVfZ2IYBSABKAVC
A+BBA1IWYXZhaWxhYmxlU3RvcmFnZVNpemVHYhJlChJtYWludGVuYW5jZV93aW5kb3cYBiAB
KAsyMS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuTWFpbnRlbmFuY2VXaW5kb3dC
A+BBAVIRbWFpbnRlbmFuY2VXaW5kb3cSZQoFc3RhdGUYByABKA4ySi5nb29nbGUuY2xvdWQu
b3JhY2xlZGF0YWJhc2UudjEuQ2xvdWRFeGFkYXRhSW5mcmFzdHJ1Y3R1cmVQcm9wZXJ0aWVz
LlN0YXRlQgPgQQNSBXN0YXRlEhkKBXNoYXBlGAggASgJQgPgQQJSBXNoYXBlEhwKB29jaV91
cmwYCSABKAlCA+BBA1IGb2NpVXJsEiAKCWNwdV9jb3VudBgKIAEoBUID4EEDUghjcHVDb3Vu
dBInCg1tYXhfY3B1X2NvdW50GAsgASgFQgPgQQNSC21heENwdUNvdW50EikKDm1lbW9yeV9z
aXplX2diGAwgASgFQgPgQQNSDG1lbW9yeVNpemVHYhInCg1tYXhfbWVtb3J5X2diGA0gASgF
QgPgQQNSC21heE1lbW9yeUdiEjkKF2RiX25vZGVfc3RvcmFnZV9zaXplX2diGA4gASgFQgPg
QQNSE2RiTm9kZVN0b3JhZ2VTaXplR2ISQAobbWF4X2RiX25vZGVfc3RvcmFnZV9zaXplX2di
GA8gASgFQgPgQQNSFm1heERiTm9kZVN0b3JhZ2VTaXplR2ISNAoUZGF0YV9zdG9yYWdlX3Np
emVfdGIYECABKAFCA+BBA1IRZGF0YVN0b3JhZ2VTaXplVGISMgoTbWF4X2RhdGFfc3RvcmFn
ZV90YhgRIAEoAUID4EEDUhBtYXhEYXRhU3RvcmFnZVRiEjsKF2FjdGl2YXRlZF9zdG9yYWdl
X2NvdW50GBIgASgFQgPgQQNSFWFjdGl2YXRlZFN0b3JhZ2VDb3VudBI9ChhhZGRpdGlvbmFs
X3N0b3JhZ2VfY291bnQYEyABKAVCA+BBA1IWYWRkaXRpb25hbFN0b3JhZ2VDb3VudBIvChFk
Yl9zZXJ2ZXJfdmVyc2lvbhgUIAEoCUID4EEDUg9kYlNlcnZlclZlcnNpb24SOQoWc3RvcmFn
ZV9zZXJ2ZXJfdmVyc2lvbhgVIAEoCUID4EEDUhRzdG9yYWdlU2VydmVyVmVyc2lvbhI6Chdu
ZXh0X21haW50ZW5hbmNlX3J1bl9pZBgWIAEoCUID4EEDUhRuZXh0TWFpbnRlbmFuY2VSdW5J
ZBJaChluZXh0X21haW50ZW5hbmNlX3J1bl90aW1lGBcgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUhZuZXh0TWFpbnRlbmFuY2VSdW5UaW1lEmsKIm5leHRfc2VjdXJp
dHlfbWFpbnRlbmFuY2VfcnVuX3RpbWUYGCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSHm5leHRTZWN1cml0eU1haW50ZW5hbmNlUnVuVGltZRJhChFjdXN0b21lcl9j
b250YWN0cxgZIAMoCzIvLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5DdXN0b21l
ckNvbnRhY3RCA+BBAVIQY3VzdG9tZXJDb250YWN0cxJICh5tb250aGx5X3N0b3JhZ2Vfc2Vy
dmVyX3ZlcnNpb24YGiABKAlCA+BBA1IbbW9udGhseVN0b3JhZ2VTZXJ2ZXJWZXJzaW9uEj4K
GW1vbnRobHlfZGJfc2VydmVyX3ZlcnNpb24YGyABKAlCA+BBA1IWbW9udGhseURiU2VydmVy
VmVyc2lvbhJWCg1jb21wdXRlX21vZGVsGB8gASgOMiwuZ29vZ2xlLmNsb3VkLm9yYWNsZWRh
dGFiYXNlLnYxLkNvbXB1dGVNb2RlbEID4EEDUgxjb21wdXRlTW9kZWwSNQoUZGF0YWJhc2Vf
c2VydmVyX3R5cGUYHSABKAlCA+BBAVISZGF0YWJhc2VTZXJ2ZXJUeXBlEjMKE3N0b3JhZ2Vf
c2VydmVyX3R5cGUYHiABKAlCA+BBAVIRc3RvcmFnZVNlcnZlclR5cGUSXAoPZXhhc2NhbGVf
Y29uZmlnGCAgASgLMi4uZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkV4YXNjYWxl
Q29uZmlnQgPgQQNSDmV4YXNjYWxlQ29uZmlnIpcBCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJ
RklFRBAAEhAKDFBST1ZJU0lPTklORxABEg0KCUFWQUlMQUJMRRACEgwKCFVQREFUSU5HEAMS
DwoLVEVSTUlOQVRJTkcQBBIOCgpURVJNSU5BVEVEEAUSCgoGRkFJTEVEEAYSGwoXTUFJTlRF
TkFOQ0VfSU5fUFJPR1JFU1MQByKKAgoORXhhc2NhbGVDb25maWcSNgoVdG90YWxfc3RvcmFn
ZV9zaXplX2diGAEgASgFQgPgQQNSEnRvdGFsU3RvcmFnZVNpemVHYhI+ChlhdmFpbGFibGVf
c3RvcmFnZV9zaXplX2diGAIgASgFQgPgQQNSFmF2YWlsYWJsZVN0b3JhZ2VTaXplR2ISOwoY
dG90YWxfdm1fc3RvcmFnZV9zaXplX2diGAMgASgFQgPgQQNSFHRvdGFsVm1TdG9yYWdlU2l6
ZUdiEkMKHGF2YWlsYWJsZV92bV9zdG9yYWdlX3NpemVfZ2IYBCABKAVCA+BBA1IYYXZhaWxh
YmxlVm1TdG9yYWdlU2l6ZUdiIrIGChFNYWludGVuYW5jZVdpbmRvdxJyCgpwcmVmZXJlbmNl
GAEgASgOMk0uZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLk1haW50ZW5hbmNlV2lu
ZG93Lk1haW50ZW5hbmNlV2luZG93UHJlZmVyZW5jZUID4EEBUgpwcmVmZXJlbmNlEi8KBm1v
bnRocxgCIAMoDjISLmdvb2dsZS50eXBlLk1vbnRoQgPgQQFSBm1vbnRocxIpCg53ZWVrc19v
Zl9tb250aBgDIAMoBUID4EEBUgx3ZWVrc09mTW9udGgSPQoMZGF5c19vZl93ZWVrGAQgAygO
MhYuZ29vZ2xlLnR5cGUuRGF5T2ZXZWVrQgPgQQFSCmRheXNPZldlZWsSJQoMaG91cnNfb2Zf
ZGF5GAUgAygFQgPgQQFSCmhvdXJzT2ZEYXkSKQoObGVhZF90aW1lX3dlZWsYBiABKAVCA+BB
AVIMbGVhZFRpbWVXZWVrEmgKDXBhdGNoaW5nX21vZGUYByABKA4yPi5nb29nbGUuY2xvdWQu
b3JhY2xlZGF0YWJhc2UudjEuTWFpbnRlbmFuY2VXaW5kb3cuUGF0Y2hpbmdNb2RlQgPgQQFS
DHBhdGNoaW5nTW9kZRJAChpjdXN0b21fYWN0aW9uX3RpbWVvdXRfbWlucxgIIAEoBUID4EEB
UhdjdXN0b21BY3Rpb25UaW1lb3V0TWlucxJLCiBpc19jdXN0b21fYWN0aW9uX3RpbWVvdXRf
ZW5hYmxlZBgJIAEoCEID4EEBUhxpc0N1c3RvbUFjdGlvblRpbWVvdXRFbmFibGVkInYKG01h
aW50ZW5hbmNlV2luZG93UHJlZmVyZW5jZRItCilNQUlOVEVOQU5DRV9XSU5ET1dfUFJFRkVS
RU5DRV9VTlNQRUNJRklFRBAAEhUKEUNVU1RPTV9QUkVGRVJFTkNFEAESEQoNTk9fUFJFRkVS
RU5DRRACIksKDFBhdGNoaW5nTW9kZRIdChlQQVRDSElOR19NT0RFX1VOU1BFQ0lGSUVEEAAS
CwoHUk9MTElORxABEg8KC05PTl9ST0xMSU5HEAIiqwIKMkNvbmZpZ3VyZUV4YXNjYWxlQ2xv
dWRFeGFkYXRhSW5mcmFzdHJ1Y3R1cmVSZXF1ZXN0ElQKBG5hbWUYASABKAlCQOBBAvpBOgo4
b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vQ2xvdWRFeGFkYXRhSW5mcmFzdHJ1Y3R1
cmVSBG5hbWUSNgoVdG90YWxfc3RvcmFnZV9zaXplX2diGAIgASgFQgPgQQJSEnRvdGFsU3Rv
cmFnZVNpemVHYhI7Chh0b3RhbF92bV9zdG9yYWdlX3NpemVfZ2IYBCABKAVCA+BBAVIUdG90
YWxWbVN0b3JhZ2VTaXplR2ISKgoKcmVxdWVzdF9pZBgDIAEoCUIL4ozP1wgCCAHgQQFSCXJl
cXVlc3RJZEL5AQoiY29tLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MUIfQ2xvdWRF
eGFkYXRhSW5mcmFzdHJ1Y3R1cmVQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL29yYWNs
ZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdv
b2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRh
YmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURhdGFiYXNlOjpWMUqBagoHEgUOANkC
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABID
EgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxIDFQA1CgkKAgMEEgMWACkKCQoCAwUS
AxcAJQoJCgIDBhIDGAAhCggKAQgSAxoAOwoJCgIIJRIDGgA7CggKAQgSAxsAYQoJCgIICxID
GwBhCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AQAoJCgIICBIDHQBACggKAQgSAx4A
OwoJCgIIARIDHgA7CggKAQgSAx8AOwoJCgIIKRIDHwA7CggKAQgSAyAAOgoJCgIILRIDIAA6
CpkBCgIEABIEJABPARqMASBSZXByZXNlbnRzIENsb3VkRXhhZGF0YUluZnJhc3RydWN0dXJl
IHJlc291cmNlLgogaHR0cHM6Ly9kb2NzLm9yYWNsZS5jb20vZW4tdXMvaWFhcy9hcGkvIy9l
bi9kYXRhYmFzZS8yMDE2MDkxOC9DbG91ZEV4YWRhdGFJbmZyYXN0cnVjdHVyZS8KCgoKAwQA
ARIDJAgiCgsKAwQABxIEJQIqBAoNCgUEAAedCBIEJQIqBAq/AQoEBAACABIDLwI9GrEBIElk
ZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBFeGFkYXRhIEluZnJhc3RydWN0dXJlIHJlc291
cmNlIHdpdGggdGhlCiBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ty
ZWdpb259L2Nsb3VkRXhhZGF0YUluZnJhc3RydWN0dXJlcy97Y2xvdWRfZXhhZGF0YV9pbmZy
YXN0cnVjdHVyZX0KCgwKBQQAAgAFEgMvAggKDAoFBAACAAESAy8JDQoMCgUEAAIAAxIDLxAR
CgwKBQQAAgAIEgMvEjwKDwoIBAACAAicCAASAy8TOwpKCgQEAAIBEgQyAjUEGjwgT3B0aW9u
YWwuIEltbXV0YWJsZS4gVXNlciBmcmllbmRseSBuYW1lIGZvciB0aGlzIHJlc291cmNlLgoK
DAoFBAACAQUSAzICCAoMCgUEAAIBARIDMgkVCgwKBQQAAgEDEgMyGBkKDQoFBAACAQgSBDIa
NQMKDwoIBAACAQicCAASAzMEKgoPCggEAAIBCJwIARIDNAQrCscBCgQEAAICEgQ6Aj0EGrgB
IE9wdGlvbmFsLiBJbW11dGFibGUuIFRoZSBHQ1AgT3JhY2xlIHpvbmUgd2hlcmUgT3JhY2xl
IEV4YWRhdGEKIEluZnJhc3RydWN0dXJlIGlzIGhvc3RlZC4gRXhhbXBsZTogdXMtZWFzdDQt
Yi1yMi4gSWYgbm90IHNwZWNpZmllZCwgdGhlCiBzeXN0ZW0gd2lsbCBwaWNrIGEgem9uZSBi
YXNlZCBvbiBhdmFpbGFiaWxpdHkuCgoMCgUEAAICBRIDOgIICgwKBQQAAgIBEgM6CRgKDAoF
BAACAgMSAzobHAoNCgUEAAICCBIEOh09AwoPCggEAAICCJwIABIDOwQqCg8KCAQAAgIInAgB
EgM8BCsKewoEBAACAxIDQQJIGm4gT3V0cHV0IG9ubHkuIEVudGl0bGVtZW50IElEIG9mIHRo
ZSBwcml2YXRlIG9mZmVyIGFnYWluc3Qgd2hpY2ggdGhpcwogaW5mcmFzdHJ1Y3R1cmUgcmVz
b3VyY2UgaXMgcHJvdmlzaW9uZWQuCgoMCgUEAAIDBRIDQQIICgwKBQQAAgMBEgNBCRcKDAoF
BAACAwMSA0EaGwoMCgUEAAIDCBIDQRxHCg8KCAQAAgMInAgAEgNBHUYKRQoEBAACBBIERAJH
BBo3IE9wdGlvbmFsLiBJbW11dGFibGUuIFZhcmlvdXMgcHJvcGVydGllcyBvZiB0aGUgaW5m
cmEuCgoMCgUEAAIEBhIDRAImCgwKBQQAAgQBEgNEJzEKDAoFBAACBAMSA0Q0NQoNCgUEAAIE
CBIERDZHAwoPCggEAAIECJwIABIDRQQqCg8KCAQAAgQInAgBEgNGBCsKRQoEBAACBRIDSgJK
GjggT3B0aW9uYWwuIExhYmVscyBvciB0YWdzIGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVzb3Vy
Y2UuCgoMCgUEAAIFBhIDSgIVCgwKBQQAAgUBEgNKFhwKDAoFBAACBQMSA0ofIAoMCgUEAAIF
CBIDSiFJCg8KCAQAAgUInAgAEgNKIkgKWwoEBAACBhIETQJOMhpNIE91dHB1dCBvbmx5LiBU
aGUgZGF0ZSBhbmQgdGltZSB0aGF0IHRoZSBFeGFkYXRhIEluZnJhc3RydWN0dXJlIHdhcyBj
cmVhdGVkLgoKDAoFBAACBgYSA00CGwoMCgUEAAIGARIDTRwnCgwKBQQAAgYDEgNNKisKDAoF
BAACBggSA04GMQoPCggEAAIGCJwIABIDTgcwCjwKAgQBEgVSAOMBARovIFZhcmlvdXMgcHJv
cGVydGllcyBvZiBFeGFkYXRhIEluZnJhc3RydWN0dXJlLgoKCgoDBAEBEgNSCCwKSwoEBAEE
ABIEVAJsAxo9IFRoZSB2YXJpb3VzIGxpZmVjeWNsZSBzdGF0ZXMgb2YgdGhlIEV4YWRhdGEg
SW5mcmFzdHJ1Y3R1cmUuCgoMCgUEAQQAARIDVAcMCisKBgQBBAACABIDVgQaGhwgRGVmYXVs
dCB1bnNwZWNpZmllZCB2YWx1ZS4KCg4KBwQBBAACAAESA1YEFQoOCgcEAQQAAgACEgNWGBkK
QQoGBAEEAAIBEgNZBBUaMiBUaGUgRXhhZGF0YSBJbmZyYXN0cnVjdHVyZSBpcyBiZWluZyBw
cm92aXNpb25lZC4KCg4KBwQBBAACAQESA1kEEAoOCgcEAQQAAgECEgNZExQKQQoGBAEEAAIC
EgNcBBIaMiBUaGUgRXhhZGF0YSBJbmZyYXN0cnVjdHVyZSBpcyBhdmFpbGFibGUgZm9yIHVz
ZS4KCg4KBwQBBAACAgESA1wEDQoOCgcEAQQAAgICEgNcEBEKPQoGBAEEAAIDEgNfBBEaLiBU
aGUgRXhhZGF0YSBJbmZyYXN0cnVjdHVyZSBpcyBiZWluZyB1cGRhdGVkLgoKDgoHBAEEAAID
ARIDXwQMCg4KBwQBBAACAwISA18PEApACgYEAQQAAgQSA2IEFBoxIFRoZSBFeGFkYXRhIElu
ZnJhc3RydWN0dXJlIGlzIGJlaW5nIHRlcm1pbmF0ZWQuCgoOCgcEAQQAAgQBEgNiBA8KDgoH
BAEEAAIEAhIDYhITCjoKBgQBBAACBRIDZQQTGisgVGhlIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1
cmUgaXMgdGVybWluYXRlZC4KCg4KBwQBBAACBQESA2UEDgoOCgcEAQQAAgUCEgNlERIKPwoG
BAEEAAIGEgNoBA8aMCBUaGUgRXhhZGF0YSBJbmZyYXN0cnVjdHVyZSBpcyBpbiBmYWlsZWQg
c3RhdGUuCgoOCgcEAQQAAgYBEgNoBAoKDgoHBAEEAAIGAhIDaA0OCj4KBgQBBAACBxIDawQg
Gi8gVGhlIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1cmUgaXMgaW4gbWFpbnRlbmFuY2UuCgoOCgcE
AQQAAgcBEgNrBBsKDgoHBAEEAAIHAhIDax4fCoYBCgQEAQIAEgNwAj4aeSBPdXRwdXQgb25s
eS4gT0NJRCBvZiBjcmVhdGVkIGluZnJhLgogaHR0cHM6Ly9kb2NzLm9yYWNsZS5jb20vZW4t
dXMvaWFhcy9Db250ZW50L0dlbmVyYWwvQ29uY2VwdHMvaWRlbnRpZmllcnMuaHRtI09yYWNs
ZQoKDAoFBAECAAUSA3ACCAoMCgUEAQIAARIDcAkNCgwKBQQBAgADEgNwEBEKDAoFBAECAAgS
A3ASPQoPCggEAQIACJwIABIDcBM8ClYKBAQBAgESA3MCQxpJIE9wdGlvbmFsLiBUaGUgbnVt
YmVyIG9mIGNvbXB1dGUgc2VydmVycyBmb3IgdGhlIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1cmUu
CgoMCgUEAQIBBRIDcwIHCgwKBQQBAgEBEgNzCBUKDAoFBAECAQMSA3MYGQoMCgUEAQIBCBID
cxpCCg8KCAQBAgEInAgAEgNzG0EKZQoEBAECAhIDdwJDGlggT3B0aW9uYWwuIFRoZSBudW1i
ZXIgb2YgQ2xvdWQgRXhhZGF0YSBzdG9yYWdlIHNlcnZlcnMgZm9yIHRoZSBFeGFkYXRhCiBJ
bmZyYXN0cnVjdHVyZS4KCgwKBQQBAgIFEgN3AgcKDAoFBAECAgESA3cIFQoMCgUEAQICAxID
dxgZCgwKBQQBAgIIEgN3GkIKDwoIBAECAgicCAASA3cbQQpwCgQEAQIDEgN7AksaYyBPcHRp
b25hbC4gVGhlIHRvdGFsIHN0b3JhZ2UgYWxsb2NhdGVkIHRvIHRoZSBFeGFkYXRhIEluZnJh
c3RydWN0dXJlCiByZXNvdXJjZSwgaW4gZ2lnYWJ5dGVzIChHQikuCgoMCgUEAQIDBRIDewIH
CgwKBQQBAgMBEgN7CB0KDAoFBAECAwMSA3sgIQoMCgUEAQIDCBIDeyJKCg8KCAQBAgMInAgA
EgN7I0kKgAEKBAQBAgQSBX8CgAEyGnEgT3V0cHV0IG9ubHkuIFRoZSBhdmFpbGFibGUgc3Rv
cmFnZSBjYW4gYmUgYWxsb2NhdGVkIHRvIHRoZSBFeGFkYXRhCiBJbmZyYXN0cnVjdHVyZSBy
ZXNvdXJjZSwgaW4gZ2lnYWJ5dGVzIChHQikuCgoMCgUEAQIEBRIDfwIHCgwKBQQBAgQBEgN/
CCEKDAoFBAECBAMSA38kJQoNCgUEAQIECBIEgAEGMQoQCggEAQIECJwIABIEgAEHMAo6CgQE
AQIFEgaDAQKEAS8aKiBPcHRpb25hbC4gTWFpbnRlbmFuY2Ugd2luZG93IGZvciByZXBhaXIu
CgoNCgUEAQIFBhIEgwECEwoNCgUEAQIFARIEgwEUJgoNCgUEAQIFAxIEgwEpKgoNCgUEAQIF
CBIEhAEGLgoQCggEAQIFCJwIABIEhAEHLQpXCgQEAQIGEgSHAQI+GkkgT3V0cHV0IG9ubHku
IFRoZSBjdXJyZW50IGxpZmVjeWNsZSBzdGF0ZSBvZiB0aGUgRXhhZGF0YSBJbmZyYXN0cnVj
dHVyZS4KCg0KBQQBAgYGEgSHAQIHCg0KBQQBAgYBEgSHAQgNCg0KBQQBAgYDEgSHARARCg0K
BQQBAgYIEgSHARI9ChAKCAQBAgYInAgAEgSHARM8CqUBCgQEAQIHEgSLAQI8GpYBIFJlcXVp
cmVkLiBUaGUgc2hhcGUgb2YgdGhlIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1cmUuIFRoZSBzaGFw
ZSBkZXRlcm1pbmVzIHRoZQogYW1vdW50IG9mIENQVSwgc3RvcmFnZSwgYW5kIG1lbW9yeSBy
ZXNvdXJjZXMgYWxsb2NhdGVkIHRvIHRoZSBpbnN0YW5jZS4KCg0KBQQBAgcFEgSLAQIICg0K
BQQBAgcBEgSLAQkOCg0KBQQBAgcDEgSLARESCg0KBQQBAgcIEgSLARM7ChAKCAQBAgcInAgA
EgSLARQ6ClAKBAQBAggSBI4BAkEaQiBPdXRwdXQgb25seS4gRGVlcCBsaW5rIHRvIHRoZSBP
Q0kgY29uc29sZSB0byB2aWV3IHRoaXMgcmVzb3VyY2UuCgoNCgUEAQIIBRIEjgECCAoNCgUE
AQIIARIEjgEJEAoNCgUEAQIIAxIEjgETFAoNCgUEAQIICBIEjgEVQAoQCggEAQIICJwIABIE
jgEWPwo9CgQEAQIJEgSRAQJDGi8gT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgZW5hYmxl
ZCBDUFUgY29yZXMuCgoNCgUEAQIJBRIEkQECBwoNCgUEAQIJARIEkQEIEQoNCgUEAQIJAxIE
kQEUFgoNCgUEAQIJCBIEkQEXQgoQCggEAQIJCJwIABIEkQEYQQpFCgQEAQIKEgSUAQJHGjcg
T3V0cHV0IG9ubHkuIFRoZSB0b3RhbCBudW1iZXIgb2YgQ1BVIGNvcmVzIGF2YWlsYWJsZS4K
Cg0KBQQBAgoFEgSUAQIHCg0KBQQBAgoBEgSUAQgVCg0KBQQBAgoDEgSUARgaCg0KBQQBAgoI
EgSUARtGChAKCAQBAgoInAgAEgSUARxFCjkKBAQBAgsSBJcBAkgaKyBPdXRwdXQgb25seS4g
VGhlIG1lbW9yeSBhbGxvY2F0ZWQgaW4gR0JzLgoKDQoFBAECCwUSBJcBAgcKDQoFBAECCwES
BJcBCBYKDQoFBAECCwMSBJcBGRsKDQoFBAECCwgSBJcBHEcKEAoIBAECCwicCAASBJcBHUYK
PwoEBAECDBIEmgECRxoxIE91dHB1dCBvbmx5LiBUaGUgdG90YWwgbWVtb3J5IGF2YWlsYWJs
ZSBpbiBHQnMuCgoNCgUEAQIMBRIEmgECBwoNCgUEAQIMARIEmgEIFQoNCgUEAQIMAxIEmgEY
GgoNCgUEAQIMCBIEmgEbRgoQCggEAQIMCJwIABIEmgEcRQpHCgQEAQINEgadAQKeATIaNyBP
dXRwdXQgb25seS4gVGhlIGxvY2FsIG5vZGUgc3RvcmFnZSBhbGxvY2F0ZWQgaW4gR0JzLgoK
DQoFBAECDQUSBJ0BAgcKDQoFBAECDQESBJ0BCB8KDQoFBAECDQMSBJ0BIiQKDQoFBAECDQgS
BJ4BBjEKEAoIBAECDQicCAASBJ4BBzAKTQoEBAECDhIGoQECogEyGj0gT3V0cHV0IG9ubHku
IFRoZSB0b3RhbCBsb2NhbCBub2RlIHN0b3JhZ2UgYXZhaWxhYmxlIGluIEdCcy4KCg0KBQQB
Ag4FEgShAQIHCg0KBQQBAg4BEgShAQgjCg0KBQQBAg4DEgShASYoCg0KBQQBAg4IEgSiAQYx
ChAKCAQBAg4InAgAEgSiAQcwCkgKBAQBAg8SBKUBAk8aOiBPdXRwdXQgb25seS4gU2l6ZSwg
aW4gdGVyYWJ5dGVzLCBvZiB0aGUgREFUQSBkaXNrIGdyb3VwLgoKDQoFBAECDwUSBKUBAggK
DQoFBAECDwESBKUBCR0KDQoFBAECDwMSBKUBICIKDQoFBAECDwgSBKUBI04KEAoIBAECDwic
CAASBKUBJE0KRgoEBAECEBIEqAECTho4IE91dHB1dCBvbmx5LiBUaGUgdG90YWwgYXZhaWxh
YmxlIERBVEEgZGlzayBncm91cCBzaXplLgoKDQoFBAECEAUSBKgBAggKDQoFBAECEAESBKgB
CRwKDQoFBAECEAMSBKgBHyEKDQoFBAECEAgSBKgBIk0KEAoIBAECEAicCAASBKgBI0wKfAoE
BAECERIGrAECrQEyGmwgT3V0cHV0IG9ubHkuIFRoZSByZXF1ZXN0ZWQgbnVtYmVyIG9mIGFk
ZGl0aW9uYWwgc3RvcmFnZSBzZXJ2ZXJzIGFjdGl2YXRlZAogZm9yIHRoZSBFeGFkYXRhIElu
ZnJhc3RydWN0dXJlLgoKDQoFBAECEQUSBKwBAgcKDQoFBAECEQESBKwBCB8KDQoFBAECEQMS
BKwBIiQKDQoFBAECEQgSBK0BBjEKEAoIBAECEQicCAASBK0BBzAKcgoEBAECEhIGsQECsgEy
GmIgT3V0cHV0IG9ubHkuIFRoZSByZXF1ZXN0ZWQgbnVtYmVyIG9mIGFkZGl0aW9uYWwgc3Rv
cmFnZSBzZXJ2ZXJzIGZvciB0aGUKIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1cmUuCgoNCgUEAQIS
BRIEsQECBwoNCgUEAQISARIEsQEIIAoNCgUEAQISAxIEsQEjJQoNCgUEAQISCBIEsgEGMQoQ
CggEAQISCJwIABIEsgEHMApwCgQEAQITEgS2AQJMGmIgT3V0cHV0IG9ubHkuIFRoZSBzb2Z0
d2FyZSB2ZXJzaW9uIG9mIHRoZSBkYXRhYmFzZSBzZXJ2ZXJzIChkb20wKSBpbiB0aGUKIEV4
YWRhdGEgSW5mcmFzdHJ1Y3R1cmUuCgoNCgUEAQITBRIEtgECCAoNCgUEAQITARIEtgEJGgoN
CgUEAQITAxIEtgEdHwoNCgUEAQITCBIEtgEgSwoQCggEAQITCJwIABIEtgEhSgpyCgQEAQIU
Ega6AQK7ATIaYiBPdXRwdXQgb25seS4gVGhlIHNvZnR3YXJlIHZlcnNpb24gb2YgdGhlIHN0
b3JhZ2Ugc2VydmVycyAoY2VsbHMpIGluIHRoZQogRXhhZGF0YSBJbmZyYXN0cnVjdHVyZS4K
Cg0KBQQBAhQFEgS6AQIICg0KBQQBAhQBEgS6AQkfCg0KBQQBAhQDEgS6ASIkCg0KBQQBAhQI
EgS7AQYxChAKCAQBAhQInAgAEgS7AQcwCkQKBAQBAhUSBr4BAr8BMho0IE91dHB1dCBvbmx5
LiBUaGUgT0NJRCBvZiB0aGUgbmV4dCBtYWludGVuYW5jZSBydW4uCgoNCgUEAQIVBRIEvgEC
CAoNCgUEAQIVARIEvgEJIAoNCgUEAQIVAxIEvgEjJQoNCgUEAQIVCBIEvwEGMQoQCggEAQIV
CJwIABIEvwEHMApRCgQEAQIWEgbCAQLDATIaQSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hl
biB0aGUgbmV4dCBtYWludGVuYW5jZSBydW4gd2lsbCBvY2N1ci4KCg0KBQQBAhYGEgTCAQIb
Cg0KBQQBAhYBEgTCARw1Cg0KBQQBAhYDEgTCATg6Cg0KBQQBAhYIEgTDAQYxChAKCAQBAhYI
nAgAEgTDAQcwCloKBAQBAhcSBsYBAscBMhpKIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVu
IHRoZSBuZXh0IHNlY3VyaXR5IG1haW50ZW5hbmNlIHJ1biB3aWxsIG9jY3VyLgoKDQoFBAEC
FwYSBMYBAhsKDQoFBAECFwESBMYBHD4KDQoFBAECFwMSBMYBQUMKDQoFBAECFwgSBMcBBjEK
EAoIBAECFwicCAASBMcBBzAKOgoEBAECGBIGygECywEvGiogT3B0aW9uYWwuIFRoZSBsaXN0
IG9mIGN1c3RvbWVyIGNvbnRhY3RzLgoKDQoFBAECGAQSBMoBAgoKDQoFBAECGAYSBMoBCxoK
DQoFBAECGAESBMoBGywKDQoFBAECGAMSBMoBLzEKDQoFBAECGAgSBMsBBi4KEAoIBAECGAic
CAASBMsBBy0KiwEKBAQBAhkSBs8BAtABMhp7IE91dHB1dCBvbmx5LiBUaGUgbW9udGhseSBz
b2Z0d2FyZSB2ZXJzaW9uIG9mIHRoZSBzdG9yYWdlIHNlcnZlcnMgKGNlbGxzKQogaW4gdGhl
IEV4YWRhdGEgSW5mcmFzdHJ1Y3R1cmUuIEV4YW1wbGU6IDIwLjEuMTUKCg0KBQQBAhkFEgTP
AQIICg0KBQQBAhkBEgTPAQknCg0KBQQBAhkDEgTPASosCg0KBQQBAhkIEgTQAQYxChAKCAQB
AhkInAgAEgTQAQcwCosBCgQEAQIaEgbUAQLVATIaeyBPdXRwdXQgb25seS4gVGhlIG1vbnRo
bHkgc29mdHdhcmUgdmVyc2lvbiBvZiB0aGUgZGF0YWJhc2Ugc2VydmVycyAoZG9tMCkKIGlu
IHRoZSBFeGFkYXRhIEluZnJhc3RydWN0dXJlLiBFeGFtcGxlOiAyMC4xLjE1CgoNCgUEAQIa
BRIE1AECCAoNCgUEAQIaARIE1AEJIgoNCgUEAQIaAxIE1AElJwoNCgUEAQIaCBIE1QEGMQoQ
CggEAQIaCJwIABIE1QEHMApNCgQEAQIbEgTYAQJOGj8gT3V0cHV0IG9ubHkuIFRoZSBjb21w
dXRlIG1vZGVsIG9mIHRoZSBFeGFkYXRhIEluZnJhc3RydWN0dXJlLgoKDQoFBAECGwYSBNgB
Ag4KDQoFBAECGwESBNgBDxwKDQoFBAECGwMSBNgBHyEKDQoFBAECGwgSBNgBIk0KEAoIBAEC
GwicCAASBNgBI0wKUQoEBAECHBIE2wECTBpDIE9wdGlvbmFsLiBUaGUgZGF0YWJhc2Ugc2Vy
dmVyIHR5cGUgb2YgdGhlIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1cmUuCgoNCgUEAQIcBRIE2wEC
CAoNCgUEAQIcARIE2wEJHQoNCgUEAQIcAxIE2wEgIgoNCgUEAQIcCBIE2wEjSwoQCggEAQIc
CJwIABIE2wEkSgpQCgQEAQIdEgTeAQJLGkIgT3B0aW9uYWwuIFRoZSBzdG9yYWdlIHNlcnZl
ciB0eXBlIG9mIHRoZSBFeGFkYXRhIEluZnJhc3RydWN0dXJlLgoKDQoFBAECHQUSBN4BAggK
DQoFBAECHQESBN4BCRwKDQoFBAECHQMSBN4BHyEKDQoFBAECHQgSBN4BIkoKEAoIBAECHQic
CAASBN4BI0kKWQoEBAECHhIG4QEC4gEyGkkgT3V0cHV0IG9ubHkuIFRoZSBFeGFzY2FsZSBj
b25maWd1cmF0aW9uIGZvciB0aGUgRXhhZGF0YSBJbmZyYXN0cnVjdHVyZS4KCg0KBQQBAh4G
EgThAQIQCg0KBQQBAh4BEgThAREgCg0KBQQBAh4DEgThASMlCg0KBQQBAh4IEgTiAQYxChAK
CAQBAh4InAgAEgTiAQcwClUKAgQCEgbmAQD1AQEaRyBEZXRhaWxzIG9mIHRoZSBFeGFzY2Fs
ZSBjb25maWd1cmF0aW9uIGZvciB0aGUgRXhhZGF0YSBJbmZyYXN0cnVjdHVyZS4KCgsKAwQC
ARIE5gEIFgpLCgQEAgIAEgToAQJOGj0gT3V0cHV0IG9ubHkuIFRvdGFsIHN0b3JhZ2Ugc2l6
ZSBuZWVkZWQgZm9yIEV4YXNjYWxlIGluIEdCcy4KCg0KBQQCAgAFEgToAQIHCg0KBQQCAgAB
EgToAQgdCg0KBQQCAgADEgToASAhCg0KBQQCAgAIEgToASJNChAKCAQCAgAInAgAEgToASNM
CkoKBAQCAgESBusBAuwBMho6IE91dHB1dCBvbmx5LiBBdmFpbGFibGUgc3RvcmFnZSBzaXpl
IGZvciBFeGFzY2FsZSBpbiBHQnMuCgoNCgUEAgIBBRIE6wECBwoNCgUEAgIBARIE6wEIIQoN
CgUEAgIBAxIE6wEkJQoNCgUEAgIBCBIE7AEGMQoQCggEAgIBCJwIABIE7AEHMApVCgQEAgIC
EgbvAQLwATIaRSBPdXRwdXQgb25seS4gU3RvcmFnZSBzaXplIG5lZWRlZCBmb3IgVk0gc3Rv
cmFnZSBvbiBFeGFzY2FsZSBpbiBHQnMuCgoNCgUEAgICBRIE7wECBwoNCgUEAgICARIE7wEI
IAoNCgUEAgICAxIE7wEjJAoNCgUEAgICCBIE8AEGMQoQCggEAgICCJwIABIE8AEHMApYCgQE
AgIDEgbzAQL0ATIaSCBPdXRwdXQgb25seS4gQXZhaWxhYmxlIHN0b3JhZ2Ugc2l6ZSBmb3Ig
Vk0gc3RvcmFnZSBvbiBFeGFzY2FsZSBpbiBHQnMuCgoNCgUEAgIDBRIE8wECBwoNCgUEAgID
ARIE8wEIJAoNCgUEAgIDAxIE8wEnKAoNCgUEAgIDCBIE9AEGMQoQCggEAgIDCJwIABIE9AEH
MAqUAQoCBAMSBvkBAMACARqFASBNYWludGVuYW5jZSB3aW5kb3cgYXMgZGVmaW5lZCBieSBP
cmFjbGUuCiBodHRwczovL2RvY3Mub3JhY2xlLmNvbS9lbi11cy9pYWFzL2FwaS8jL2VuL2Rh
dGFiYXNlLzIwMTYwOTE4L2RhdGF0eXBlcy9NYWludGVuYW5jZVdpbmRvdwoKCwoDBAMBEgT5
AQgZCjAKBAQDBAASBvsBAoQCAxogIE1haW50ZW5hbmNlIHdpbmRvdyBwcmVmZXJlbmNlLgoK
DQoFBAMEAAESBPsBByIKLAoGBAMEAAIAEgT9AQQyGhwgRGVmYXVsdCB1bnNwZWNpZmllZCB2
YWx1ZS4KCg8KBwQDBAACAAESBP0BBC0KDwoHBAMEAAIAAhIE/QEwMQokCgYEAwQAAgESBIAC
BBoaFCBDdXN0b20gcHJlZmVyZW5jZS4KCg8KBwQDBAACAQESBIACBBUKDwoHBAMEAAIBAhIE
gAIYGQogCgYEAwQAAgISBIMCBBYaECBObyBwcmVmZXJlbmNlLgoKDwoHBAMEAAICARIEgwIE
EQoPCgcEAwQAAgICEgSDAhQVCiAKBAQDBAESBocCApECAxoQIFBhdGNoaW5nIG1vZGUuCgoN
CgUEAwQBARIEhwIHEwosCgYEAwQBAgASBIkCBCIaHCBEZWZhdWx0IHVuc3BlY2lmaWVkIHZh
bHVlLgoKDwoHBAMEAQIAARIEiQIEHQoPCgcEAwQBAgACEgSJAiAhClcKBgQDBAECARIEjAIE
EBpHIFVwZGF0ZXMgdGhlIENsb3VkIEV4YWRhdGEgZGF0YWJhc2Ugc2VydmVyIGhvc3RzIGlu
IGEgcm9sbGluZyBmYXNoaW9uLgoKDwoHBAMEAQIBARIEjAIECwoPCgcEAwQBAgECEgSMAg4P
CpgBCgYEAwQBAgISBJACBBQahwEgVGhlIG5vbi1yb2xsaW5nIG1haW50ZW5hbmNlIG1ldGhv
ZCBmaXJzdCB1cGRhdGVzIHlvdXIgc3RvcmFnZSBzZXJ2ZXJzIGF0CiB0aGUgc2FtZSB0aW1l
LCB0aGVuIHlvdXIgZGF0YWJhc2Ugc2VydmVycyBhdCB0aGUgc2FtZSB0aW1lLgoKDwoHBAME
AQICARIEkAIEDwoPCgcEAwQBAgICEgSQAhITCkkKBAQDAgASBpQCApUCLxo5IE9wdGlvbmFs
LiBUaGUgbWFpbnRlbmFuY2Ugd2luZG93IHNjaGVkdWxpbmcgcHJlZmVyZW5jZS4KCg0KBQQD
AgAGEgSUAgIdCg0KBQQDAgABEgSUAh4oCg0KBQQDAgADEgSUAissCg0KBQQDAgAIEgSVAgYu
ChAKCAQDAgAInAgAEgSVAgctClgKBAQDAgESBpgCApkCLxpIIE9wdGlvbmFsLiBNb250aHMg
ZHVyaW5nIHRoZSB5ZWFyIHdoZW4gbWFpbnRlbmFuY2Ugc2hvdWxkIGJlIHBlcmZvcm1lZC4K
Cg0KBQQDAgEEEgSYAgIKCg0KBQQDAgEGEgSYAgscCg0KBQQDAgEBEgSYAh0jCg0KBQQDAgED
EgSYAiYnCg0KBQQDAgEIEgSZAgYuChAKCAQDAgEInAgAEgSZAgctCvsBCgQEAwICEgSfAgJN
GuwBIE9wdGlvbmFsLiBXZWVrcyBkdXJpbmcgdGhlIG1vbnRoIHdoZW4gbWFpbnRlbmFuY2Ug
c2hvdWxkIGJlIHBlcmZvcm1lZC4KIFdlZWtzIHN0YXJ0IG9uIHRoZSAxc3QsIDh0aCwgMTV0
aCwgYW5kIDIybmQgZGF5cyBvZiB0aGUgbW9udGgsIGFuZCBoYXZlIGEKIGR1cmF0aW9uIG9m
IDcgZGF5cy4gV2Vla3Mgc3RhcnQgYW5kIGVuZCBiYXNlZCBvbiBjYWxlbmRhciBkYXRlcywg
bm90IGRheXMKIG9mIHRoZSB3ZWVrLgoKDQoFBAMCAgQSBJ8CAgoKDQoFBAMCAgUSBJ8CCxAK
DQoFBAMCAgESBJ8CER8KDQoFBAMCAgMSBJ8CIiMKDQoFBAMCAggSBJ8CJEwKEAoIBAMCAgic
CAASBJ8CJUsKVgoEBAMCAxIGogICowIvGkYgT3B0aW9uYWwuIERheXMgZHVyaW5nIHRoZSB3
ZWVrIHdoZW4gbWFpbnRlbmFuY2Ugc2hvdWxkIGJlIHBlcmZvcm1lZC4KCg0KBQQDAgMEEgSi
AgIKCg0KBQQDAgMGEgSiAgsgCg0KBQQDAgMBEgSiAiEtCg0KBQQDAgMDEgSiAjAxCg0KBQQD
AgMIEgSjAgYuChAKCAQDAgMInAgAEgSjAgctCqUDCgQEAwIEEgStAgJLGpYDIE9wdGlvbmFs
LiBUaGUgd2luZG93IG9mIGhvdXJzIGR1cmluZyB0aGUgZGF5IHdoZW4gbWFpbnRlbmFuY2Ug
c2hvdWxkIGJlCiBwZXJmb3JtZWQuIFRoZSB3aW5kb3cgaXMgYSA0IGhvdXIgc2xvdC4gVmFs
aWQgdmFsdWVzIGFyZToKICAgMCAtIHJlcHJlc2VudHMgdGltZSBzbG90IDA6MDAgLSAzOjU5
IFVUQwogICA0IC0gcmVwcmVzZW50cyB0aW1lIHNsb3QgNDowMCAtIDc6NTkgVVRDCiAgIDgg
LSByZXByZXNlbnRzIHRpbWUgc2xvdCA4OjAwIC0gMTE6NTkgVVRDCiAgIDEyIC0gcmVwcmVz
ZW50cyB0aW1lIHNsb3QgMTI6MDAgLSAxNTo1OSBVVEMKICAgMTYgLSByZXByZXNlbnRzIHRp
bWUgc2xvdCAxNjowMCAtIDE5OjU5IFVUQwogICAyMCAtIHJlcHJlc2VudHMgdGltZSBzbG90
IDIwOjAwIC0gMjM6NTkgVVRDCgoNCgUEAwIEBBIErQICCgoNCgUEAwIEBRIErQILEAoNCgUE
AwIEARIErQIRHQoNCgUEAwIEAxIErQIgIQoNCgUEAwIECBIErQIiSgoQCggEAwIECJwIABIE
rQIjSQqkAQoEBAMCBRIEsQICRBqVASBPcHRpb25hbC4gTGVhZCB0aW1lIHdpbmRvdyBhbGxv
d3MgdXNlciB0byBzZXQgYSBsZWFkIHRpbWUgdG8gcHJlcGFyZSBmb3IgYQogZG93biB0aW1l
LiBUaGUgbGVhZCB0aW1lIGlzIGluIHdlZWtzIGFuZCB2YWxpZCB2YWx1ZSBpcyBiZXR3ZWVu
IDEgdG8gNC4KCg0KBQQDAgUFEgSxAgIHCg0KBQQDAgUBEgSxAggWCg0KBQQDAgUDEgSxAhka
Cg0KBQQDAgUIEgSxAhtDChAKCAQDAgUInAgAEgSxAhxCCo0BCgQEAwIGEgS1AgJKGn8gT3B0
aW9uYWwuIENsb3VkIENsb3VkRXhhZGF0YUluZnJhc3RydWN0dXJlIG5vZGUgcGF0Y2hpbmcg
bWV0aG9kLCBlaXRoZXIKICJST0xMSU5HIiBvciAiTk9OUk9MTElORyIuIERlZmF1bHQgdmFs
dWUgaXMgUk9MTElORy4KCg0KBQQDAgYGEgS1AgIOCg0KBQQDAgYBEgS1Ag8cCg0KBQQDAgYD
EgS1Ah8gCg0KBQQDAgYIEgS1AiFJChAKCAQDAgYInAgAEgS1AiJICuIBCgQEAwIHEgS6AgJQ
GtMBIE9wdGlvbmFsLiBEZXRlcm1pbmVzIHRoZSBhbW91bnQgb2YgdGltZSB0aGUgc3lzdGVt
IHdpbGwgd2FpdCBiZWZvcmUgdGhlCiBzdGFydCBvZiBlYWNoIGRhdGFiYXNlIHNlcnZlciBw
YXRjaGluZyBvcGVyYXRpb24uIEN1c3RvbSBhY3Rpb24gdGltZW91dCBpcwogaW4gbWludXRl
cyBhbmQgdmFsaWQgdmFsdWUgaXMgYmV0d2VlbiAxNSB0byAxMjAgKGluY2x1c2l2ZSkuCgoN
CgUEAwIHBRIEugICBwoNCgUEAwIHARIEugIIIgoNCgUEAwIHAxIEugIlJgoNCgUEAwIHCBIE
ugInTwoQCggEAwIHCJwIABIEugIoTgqZAQoEBAMCCBIGvgICvwIvGogBIE9wdGlvbmFsLiBJ
ZiB0cnVlLCBlbmFibGVzIHRoZSBjb25maWd1cmF0aW9uIG9mIGEgY3VzdG9tIGFjdGlvbiB0
aW1lb3V0CiAod2FpdGluZyBwZXJpb2QpIGJldHdlZW4gZGF0YWJhc2Ugc2VydmVyIHBhdGNo
aW5nIG9wZXJhdGlvbnMuCgoNCgUEAwIIBRIEvgICBgoNCgUEAwIIARIEvgIHJwoNCgUEAwII
AxIEvgIqKwoNCgUEAwIICBIEvwIGLgoQCggEAwIICJwIABIEvwIHLQpPCgIEBBIGwwIA2QIB
GkEgVGhlIHJlcXVlc3QgZm9yIGBDbG91ZEV4YWRhdGFJbmZyYXN0cnVjdHVyZS5Db25maWd1
cmVFeGFzY2FsZWAuCgoLCgMEBAESBMMCCDoKyAEKBAQEAgASBscCAswCBBq3ASBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIENsb3VkIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1cmUgaW4gdGhl
IGZvbGxvd2luZwogZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2Nsb3VkRXhhZGF0YUluZnJhc3RydWN0dXJlcy97Y2xvdWRfZXhhZGF0YV9pbmZy
YXN0cnVjdHVyZX0uCgoNCgUEBAIABRIExwICCAoNCgUEBAIAARIExwIJDQoNCgUEBAIAAxIE
xwIQEQoPCgUEBAIACBIGxwISzAIDChAKCAQEAgAInAgAEgTIAgQqChEKBwQEAgAInwgSBskC
BMsCBQpPCgQEBAIBEgTPAgJLGkEgUmVxdWlyZWQuIFRoZSB0b3RhbCBzdG9yYWdlIHRvIGJl
IGFsbG9jYXRlZCB0byBFeGFzY2FsZSBpbiBHQnMuCgoNCgUEBAIBBRIEzwICBwoNCgUEBAIB
ARIEzwIIHQoNCgUEBAIBAxIEzwIgIQoNCgUEBAIBCBIEzwIiSgoQCggEBAIBCJwIABIEzwIj
SQpQCgQEBAICEgTSAgJOGkIgT3B0aW9uYWwuIFN0b3JhZ2Ugc2l6ZSBuZWVkZWQgZm9yIFZN
IHN0b3JhZ2Ugb24gRXhhc2NhbGUgaW4gR0JzLgoKDQoFBAQCAgUSBNICAgcKDQoFBAQCAgES
BNICCCAKDQoFBAQCAgMSBNICIyQKDQoFBAQCAggSBNICJU0KEAoIBAQCAgicCAASBNICJkwK
QwoEBAQCAxIG1QIC2AIEGjMgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIElEIHRvIGlkZW50aWZ5
IHRoZSByZXF1ZXN0LgoKDQoFBAQCAwUSBNUCAggKDQoFBAQCAwESBNUCCRMKDQoFBAQCAwMS
BNUCFhcKDwoFBAQCAwgSBtUCGNgCAwoTCgsEBAIDCMzx+YoBARIE1gIEKgoQCggEBAIDCJwI
ABIE1wIEKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure ===
    # Fields for CloudExadataInfrastructure
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: gcp_oracle_zone Type: 9 ()
    # Field: entitlement_id Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.CloudExadataInfrastructureProperties)
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.CloudExadataInfrastructure.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructureProperties ===
    # Fields for CloudExadataInfrastructureProperties
    # Field: ocid Type: 9 ()
    # Field: compute_count Type: 5 ()
    # Field: storage_count Type: 5 ()
    # Field: total_storage_size_gb Type: 5 ()
    # Field: available_storage_size_gb Type: 5 ()
    # Field: maintenance_window Type: 11 (.google.cloud.oracledatabase.v1.MaintenanceWindow)
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.CloudExadataInfrastructureProperties.State)
    # Field: shape Type: 9 ()
    # Field: oci_url Type: 9 ()
    # Field: cpu_count Type: 5 ()
    # Field: max_cpu_count Type: 5 ()
    # Field: memory_size_gb Type: 5 ()
    # Field: max_memory_gb Type: 5 ()
    # Field: db_node_storage_size_gb Type: 5 ()
    # Field: max_db_node_storage_size_gb Type: 5 ()
    # Field: data_storage_size_tb Type: 1 ()
    # Field: max_data_storage_tb Type: 1 ()
    # Field: activated_storage_count Type: 5 ()
    # Field: additional_storage_count Type: 5 ()
    # Field: db_server_version Type: 9 ()
    # Field: storage_server_version Type: 9 ()
    # Field: next_maintenance_run_id Type: 9 ()
    # Field: next_maintenance_run_time Type: 11 (.google.protobuf.Timestamp)
    # Field: next_security_maintenance_run_time Type: 11 (.google.protobuf.Timestamp)
    # Field: customer_contacts Type: 11 (.google.cloud.oracledatabase.v1.CustomerContact)
    # Field: monthly_storage_server_version Type: 9 ()
    # Field: monthly_db_server_version Type: 9 ()
    # Field: compute_model Type: 14 (.google.cloud.oracledatabase.v1.ComputeModel)
    # Field: database_server_type Type: 9 ()
    # Field: storage_server_type Type: 9 ()
    # Field: exascale_config Type: 11 (.google.cloud.oracledatabase.v1.ExascaleConfig)

# Enum: CloudExadataInfrastructureProperties::State
our $CloudExadataInfrastructureProperties_STATE_UNSPECIFIED = 0;
our $CloudExadataInfrastructureProperties_PROVISIONING = 1;
our $CloudExadataInfrastructureProperties_AVAILABLE = 2;
our $CloudExadataInfrastructureProperties_UPDATING = 3;
our $CloudExadataInfrastructureProperties_TERMINATING = 4;
our $CloudExadataInfrastructureProperties_TERMINATED = 5;
our $CloudExadataInfrastructureProperties_FAILED = 6;
our $CloudExadataInfrastructureProperties_MAINTENANCE_IN_PROGRESS = 7;

# === Message: Google::Cloud::Oracledatabase::V1::ExadataInfra::ExascaleConfig ===
    # Fields for ExascaleConfig
    # Field: total_storage_size_gb Type: 5 ()
    # Field: available_storage_size_gb Type: 5 ()
    # Field: total_vm_storage_size_gb Type: 5 ()
    # Field: available_vm_storage_size_gb Type: 5 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExadataInfra::MaintenanceWindow ===
    # Fields for MaintenanceWindow
    # Field: preference Type: 14 (.google.cloud.oracledatabase.v1.MaintenanceWindow.MaintenanceWindowPreference)
    # Field: months Type: 14 (.google.type.Month)
    # Field: weeks_of_month Type: 5 ()
    # Field: days_of_week Type: 14 (.google.type.DayOfWeek)
    # Field: hours_of_day Type: 5 ()
    # Field: lead_time_week Type: 5 ()
    # Field: patching_mode Type: 14 (.google.cloud.oracledatabase.v1.MaintenanceWindow.PatchingMode)
    # Field: custom_action_timeout_mins Type: 5 ()
    # Field: is_custom_action_timeout_enabled Type: 8 ()

# Enum: MaintenanceWindow::MaintenanceWindowPreference
our $MaintenanceWindow_MAINTENANCE_WINDOW_PREFERENCE_UNSPECIFIED = 0;
our $MaintenanceWindow_CUSTOM_PREFERENCE = 1;
our $MaintenanceWindow_NO_PREFERENCE = 2;

# Enum: MaintenanceWindow::PatchingMode
our $MaintenanceWindow_PATCHING_MODE_UNSPECIFIED = 0;
our $MaintenanceWindow_ROLLING = 1;
our $MaintenanceWindow_NON_ROLLING = 2;

# === Message: Google::Cloud::Oracledatabase::V1::ExadataInfra::ConfigureExascaleCloudExadataInfrastructureRequest ===
    # Fields for ConfigureExascaleCloudExadataInfrastructureRequest
    # Field: name Type: 9 ()
    # Field: total_storage_size_gb Type: 5 ()
    # Field: total_vm_storage_size_gb Type: 5 ()
    # Field: request_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::ExadataInfra - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/exadata_infra.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::ExadataInfra;

    my $msg = Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure->new({
        name => $name,
        display_name => $display_name,
        gcp_oracle_zone => $gcp_oracle_zone,
        entitlement_id => $entitlement_id,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/exadata_infra.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure

Represents CloudExadataInfrastructure resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/CloudExadataInfrastructure/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Exadata Infrastructure resource with the
format:
projects/{project}/locations/{region}/cloudExadataInfrastructures/{cloud_exadata_infrastructure}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Immutable. User friendly name for this resource.

=item * C<< $msg->gcp_oracle_zone() >> / C<< $msg->gcp_oracle_zone($value) >>

Type: C<String>

Optional. Immutable. The GCP Oracle zone where Oracle Exadata
Infrastructure is hosted. Example: us-east4-b-r2. If not specified, the
system will pick a zone based on availability.

=item * C<< $msg->entitlement_id() >> / C<< $msg->entitlement_id($value) >>

Type: C<String>

Output only. Entitlement ID of the private offer against which this
infrastructure resource is provisioned.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructureProperties>)

Optional. Immutable. Various properties of the infra.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure::LabelsEntry>)

Optional. Labels or tags associated with the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the Exadata Infrastructure was created.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructureProperties

Various properties of Exadata Infrastructure.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. OCID of created infra.
https://docs.oracle.com/en-us/iaas/Content/General/Concepts/identifiers.htm#Oracle

=item * C<< $msg->compute_count() >> / C<< $msg->compute_count($value) >>

Type: C<Int32>

Optional. The number of compute servers for the Exadata Infrastructure.

=item * C<< $msg->storage_count() >> / C<< $msg->storage_count($value) >>

Type: C<Int32>

Optional. The number of Cloud Exadata storage servers for the Exadata
Infrastructure.

=item * C<< $msg->total_storage_size_gb() >> / C<< $msg->total_storage_size_gb($value) >>

Type: C<Int32>

Optional. The total storage allocated to the Exadata Infrastructure
resource, in gigabytes (GB).

=item * C<< $msg->available_storage_size_gb() >> / C<< $msg->available_storage_size_gb($value) >>

Type: C<Int32>

Output only. The available storage can be allocated to the Exadata
Infrastructure resource, in gigabytes (GB).

=item * C<< $msg->maintenance_window() >> / C<< $msg->maintenance_window($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExadataInfra::MaintenanceWindow>)

Optional. Maintenance window for repair.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::CloudExadataInfrastructureProperties::State>)

Output only. The current lifecycle state of the Exadata Infrastructure.

=item * C<< $msg->shape() >> / C<< $msg->shape($value) >>

Type: C<String>

Required. The shape of the Exadata Infrastructure. The shape determines the
amount of CPU, storage, and memory resources allocated to the instance.

=item * C<< $msg->oci_url() >> / C<< $msg->oci_url($value) >>

Type: C<String>

Output only. Deep link to the OCI console to view this resource.

=item * C<< $msg->cpu_count() >> / C<< $msg->cpu_count($value) >>

Type: C<Int32>

Output only. The number of enabled CPU cores.

=item * C<< $msg->max_cpu_count() >> / C<< $msg->max_cpu_count($value) >>

Type: C<Int32>

Output only. The total number of CPU cores available.

=item * C<< $msg->memory_size_gb() >> / C<< $msg->memory_size_gb($value) >>

Type: C<Int32>

Output only. The memory allocated in GBs.

=item * C<< $msg->max_memory_gb() >> / C<< $msg->max_memory_gb($value) >>

Type: C<Int32>

Output only. The total memory available in GBs.

=item * C<< $msg->db_node_storage_size_gb() >> / C<< $msg->db_node_storage_size_gb($value) >>

Type: C<Int32>

Output only. The local node storage allocated in GBs.

=item * C<< $msg->max_db_node_storage_size_gb() >> / C<< $msg->max_db_node_storage_size_gb($value) >>

Type: C<Int32>

Output only. The total local node storage available in GBs.

=item * C<< $msg->data_storage_size_tb() >> / C<< $msg->data_storage_size_tb($value) >>

Type: C<Double>

Output only. Size, in terabytes, of the DATA disk group.

=item * C<< $msg->max_data_storage_tb() >> / C<< $msg->max_data_storage_tb($value) >>

Type: C<Double>

Output only. The total available DATA disk group size.

=item * C<< $msg->activated_storage_count() >> / C<< $msg->activated_storage_count($value) >>

Type: C<Int32>

Output only. The requested number of additional storage servers activated
for the Exadata Infrastructure.

=item * C<< $msg->additional_storage_count() >> / C<< $msg->additional_storage_count($value) >>

Type: C<Int32>

Output only. The requested number of additional storage servers for the
Exadata Infrastructure.

=item * C<< $msg->db_server_version() >> / C<< $msg->db_server_version($value) >>

Type: C<String>

Output only. The software version of the database servers (dom0) in the
Exadata Infrastructure.

=item * C<< $msg->storage_server_version() >> / C<< $msg->storage_server_version($value) >>

Type: C<String>

Output only. The software version of the storage servers (cells) in the
Exadata Infrastructure.

=item * C<< $msg->next_maintenance_run_id() >> / C<< $msg->next_maintenance_run_id($value) >>

Type: C<String>

Output only. The OCID of the next maintenance run.

=item * C<< $msg->next_maintenance_run_time() >> / C<< $msg->next_maintenance_run_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the next maintenance run will occur.

=item * C<< $msg->next_security_maintenance_run_time() >> / C<< $msg->next_security_maintenance_run_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the next security maintenance run will occur.

=item * C<< $msg->customer_contacts() >> / C<< $msg->customer_contacts($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::Common::CustomerContact>)

Optional. The list of customer contacts.

=item * C<< $msg->monthly_storage_server_version() >> / C<< $msg->monthly_storage_server_version($value) >>

Type: C<String>

Output only. The monthly software version of the storage servers (cells)
in the Exadata Infrastructure. Example: 20.1.15

=item * C<< $msg->monthly_db_server_version() >> / C<< $msg->monthly_db_server_version($value) >>

Type: C<String>

Output only. The monthly software version of the database servers (dom0)
in the Exadata Infrastructure. Example: 20.1.15

=item * C<< $msg->compute_model() >> / C<< $msg->compute_model($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ComputeModel>)

Output only. The compute model of the Exadata Infrastructure.

=item * C<< $msg->database_server_type() >> / C<< $msg->database_server_type($value) >>

Type: C<String>

Optional. The database server type of the Exadata Infrastructure.

=item * C<< $msg->storage_server_type() >> / C<< $msg->storage_server_type($value) >>

Type: C<String>

Optional. The storage server type of the Exadata Infrastructure.

=item * C<< $msg->exascale_config() >> / C<< $msg->exascale_config($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExadataInfra::ExascaleConfig>)

Output only. The Exascale configuration for the Exadata Infrastructure.

=back

=head3 Enum: CloudExadataInfrastructureProperties::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<TERMINATING> => C<4>

=item * C<TERMINATED> => C<5>

=item * C<FAILED> => C<6>

=item * C<MAINTENANCE_IN_PROGRESS> => C<7>

=back

=head2 Google::Cloud::Oracledatabase::V1::ExadataInfra::ExascaleConfig

Details of the Exascale configuration for the Exadata Infrastructure.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->total_storage_size_gb() >> / C<< $msg->total_storage_size_gb($value) >>

Type: C<Int32>

Output only. Total storage size needed for Exascale in GBs.

=item * C<< $msg->available_storage_size_gb() >> / C<< $msg->available_storage_size_gb($value) >>

Type: C<Int32>

Output only. Available storage size for Exascale in GBs.

=item * C<< $msg->total_vm_storage_size_gb() >> / C<< $msg->total_vm_storage_size_gb($value) >>

Type: C<Int32>

Output only. Storage size needed for VM storage on Exascale in GBs.

=item * C<< $msg->available_vm_storage_size_gb() >> / C<< $msg->available_vm_storage_size_gb($value) >>

Type: C<Int32>

Output only. Available storage size for VM storage on Exascale in GBs.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExadataInfra::MaintenanceWindow

Maintenance window as defined by Oracle.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/datatypes/MaintenanceWindow

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->preference() >> / C<< $msg->preference($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::MaintenanceWindow::MaintenanceWindowPreference>)

Optional. The maintenance window scheduling preference.

=item * C<< $msg->months() >> / C<< $msg->months($value) >>

Type: C<Enum> (L<Google::Type::Month>)

Optional. Months during the year when maintenance should be performed.

=item * C<< $msg->weeks_of_month() >> / C<< $msg->weeks_of_month($value) >>

Type: C<Int32>

Optional. Weeks during the month when maintenance should be performed.
Weeks start on the 1st, 8th, 15th, and 22nd days of the month, and have a
duration of 7 days. Weeks start and end based on calendar dates, not days
of the week.

=item * C<< $msg->days_of_week() >> / C<< $msg->days_of_week($value) >>

Type: C<Enum> (L<Google::Type::DayOfWeek>)

Optional. Days during the week when maintenance should be performed.

=item * C<< $msg->hours_of_day() >> / C<< $msg->hours_of_day($value) >>

Type: C<Int32>

Optional. The window of hours during the day when maintenance should be
performed. The window is a 4 hour slot. Valid values are:
  0 - represents time slot 0:00 - 3:59 UTC
  4 - represents time slot 4:00 - 7:59 UTC
  8 - represents time slot 8:00 - 11:59 UTC
  12 - represents time slot 12:00 - 15:59 UTC
  16 - represents time slot 16:00 - 19:59 UTC
  20 - represents time slot 20:00 - 23:59 UTC

=item * C<< $msg->lead_time_week() >> / C<< $msg->lead_time_week($value) >>

Type: C<Int32>

Optional. Lead time window allows user to set a lead time to prepare for a
down time. The lead time is in weeks and valid value is between 1 to 4.

=item * C<< $msg->patching_mode() >> / C<< $msg->patching_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::MaintenanceWindow::PatchingMode>)

Optional. Cloud CloudExadataInfrastructure node patching method, either
"ROLLING" or "NONROLLING". Default value is ROLLING.

=item * C<< $msg->custom_action_timeout_mins() >> / C<< $msg->custom_action_timeout_mins($value) >>

Type: C<Int32>

Optional. Determines the amount of time the system will wait before the
start of each database server patching operation. Custom action timeout is
in minutes and valid value is between 15 to 120 (inclusive).

=item * C<< $msg->is_custom_action_timeout_enabled() >> / C<< $msg->is_custom_action_timeout_enabled($value) >>

Type: C<Bool>

Optional. If true, enables the configuration of a custom action timeout
(waiting period) between database server patching operations.

=back

=head3 Enum: MaintenanceWindow::MaintenanceWindowPreference

=over 4

=item * C<MAINTENANCE_WINDOW_PREFERENCE_UNSPECIFIED> => C<0>

=item * C<CUSTOM_PREFERENCE> => C<1>

=item * C<NO_PREFERENCE> => C<2>

=back

=head3 Enum: MaintenanceWindow::PatchingMode

=over 4

=item * C<PATCHING_MODE_UNSPECIFIED> => C<0>

=item * C<ROLLING> => C<1>

=item * C<NON_ROLLING> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::ExadataInfra::ConfigureExascaleCloudExadataInfrastructureRequest

The request for `CloudExadataInfrastructure.ConfigureExascale`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Cloud Exadata Infrastructure in the following
format:
projects/{project}/locations/{location}/cloudExadataInfrastructures/{cloud_exadata_infrastructure}.

=item * C<< $msg->total_storage_size_gb() >> / C<< $msg->total_storage_size_gb($value) >>

Type: C<Int32>

Required. The total storage to be allocated to Exascale in GBs.

=item * C<< $msg->total_vm_storage_size_gb() >> / C<< $msg->total_vm_storage_size_gb($value) >>

Type: C<Int32>

Optional. Storage size needed for VM storage on Exascale in GBs.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::ExadataInfra::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
