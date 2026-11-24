package Google::Cloud::Financialservices::V1::Model;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Financialservices::V1::BigqueryDestination };
    eval { require Google::Cloud::Financialservices::V1::LineOfBusiness };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvbW9kZWwucHJvdG8SIWdvb2ds
ZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo8Z29vZ2xlL2Nsb3VkL2ZpbmFu
Y2lhbHNlcnZpY2VzL3YxL2JpZ3F1ZXJ5X2Rlc3RpbmF0aW9uLnByb3RvGjhnb29nbGUvY2xv
dWQvZmluYW5jaWFsc2VydmljZXMvdjEvbGluZV9vZl9idXNpbmVzcy5wcm90bxogZ29vZ2xl
L3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8igAgKBU1vZGVsEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJACgtjcmVhdGVfdGlt
ZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJA
Cgt1cGRhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
dXBkYXRlVGltZRJMCgZsYWJlbHMYBCADKAsyNC5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2Vy
dmljZXMudjEuTW9kZWwuTGFiZWxzRW50cnlSBmxhYmVscxJJCgVzdGF0ZRgFIAEoDjIuLmdv
b2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5Nb2RlbC5TdGF0ZUID4EEDUgVzdGF0
ZRJdCg5lbmdpbmVfdmVyc2lvbhgGIAEoCUI24EED+kEwCi5maW5hbmNpYWxzZXJ2aWNlcy5n
b29nbGVhcGlzLmNvbS9FbmdpbmVWZXJzaW9uUg1lbmdpbmVWZXJzaW9uEloKDWVuZ2luZV9j
b25maWcYByABKAlCNeBBAvpBLwotZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBpcy5jb20v
RW5naW5lQ29uZmlnUgxlbmdpbmVDb25maWcSWQoPcHJpbWFyeV9kYXRhc2V0GAggASgJQjDg
QQL6QSoKKGZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0RhdGFzZXRSDnByaW1h
cnlEYXRhc2V0EjoKCGVuZF90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EECUgdlbmRUaW1lEmAKEGxpbmVfb2ZfYnVzaW5lc3MYDCABKA4yMS5nb29nbGUuY2xv
dWQuZmluYW5jaWFsc2VydmljZXMudjEuTGluZU9mQnVzaW5lc3NCA+BBA1IObGluZU9mQnVz
aW5lc3MaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlS
BXZhbHVlOgI4ASJUCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5H
EAESCgoGQUNUSVZFEAISDAoIVVBEQVRJTkcQAxIMCghERUxFVElORxAEOnzqQXkKJmZpbmFu
Y2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL01vZGVsEk9wcm9qZWN0cy97cHJvamVjdF9u
dW19L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L21vZGVscy97
bW9kZWx9Is0BChFMaXN0TW9kZWxzUmVxdWVzdBJJCgZwYXJlbnQYASABKAlCMeBBAvpBKwop
ZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSBnBhcmVudBIbCglw
YWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tl
bhIWCgZmaWx0ZXIYBCABKAlSBmZpbHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJCeSKg
AQoSTGlzdE1vZGVsc1Jlc3BvbnNlEkAKBm1vZGVscxgBIAMoCzIoLmdvb2dsZS5jbG91ZC5m
aW5hbmNpYWxzZXJ2aWNlcy52MS5Nb2RlbFIGbW9kZWxzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUi
VQoPR2V0TW9kZWxSZXF1ZXN0EkIKBG5hbWUYASABKAlCLuBBAvpBKAomZmluYW5jaWFsc2Vy
dmljZXMuZ29vZ2xlYXBpcy5jb20vTW9kZWxSBG5hbWUi6AEKEkNyZWF0ZU1vZGVsUmVxdWVz
dBJJCgZwYXJlbnQYASABKAlCMeBBAvpBKwopZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBp
cy5jb20vSW5zdGFuY2VSBnBhcmVudBIeCghtb2RlbF9pZBgCIAEoCUID4EECUgdtb2RlbElk
EkMKBW1vZGVsGAMgASgLMiguZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLk1v
ZGVsQgPgQQJSBW1vZGVsEiIKCnJlcXVlc3RfaWQYBCABKAlCA+BBAVIJcmVxdWVzdElkIr8B
ChJVcGRhdGVNb2RlbFJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASABKAsyGi5nb29nbGUucHJv
dG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSQwoFbW9kZWwYAiABKAsyKC5nb29n
bGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuTW9kZWxCA+BBAlIFbW9kZWwSIgoKcmVx
dWVzdF9pZBgDIAEoCUID4EEBUglyZXF1ZXN0SWQifAoSRGVsZXRlTW9kZWxSZXF1ZXN0EkIK
BG5hbWUYASABKAlCLuBBAvpBKAomZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBpcy5jb20v
TW9kZWxSBG5hbWUSIgoKcmVxdWVzdF9pZBgCIAEoCUID4EEBUglyZXF1ZXN0SWQi6AEKGkV4
cG9ydE1vZGVsTWV0YWRhdGFSZXF1ZXN0EkQKBW1vZGVsGAEgASgJQi7gQQL6QSgKJmZpbmFu
Y2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL01vZGVsUgVtb2RlbBKDAQofc3RydWN0dXJl
ZF9tZXRhZGF0YV9kZXN0aW5hdGlvbhgCIAEoCzI2Lmdvb2dsZS5jbG91ZC5maW5hbmNpYWxz
ZXJ2aWNlcy52MS5CaWdRdWVyeURlc3RpbmF0aW9uQgPgQQJSHXN0cnVjdHVyZWRNZXRhZGF0
YURlc3RpbmF0aW9uIh0KG0V4cG9ydE1vZGVsTWV0YWRhdGFSZXNwb25zZUL5AQolY29tLmdv
b2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MUIKTW9kZWxQcm90b1ABWlNjbG91ZC5n
b29nbGUuY29tL2dvL2ZpbmFuY2lhbHNlcnZpY2VzL2FwaXYxL2ZpbmFuY2lhbHNlcnZpY2Vz
cGI7ZmluYW5jaWFsc2VydmljZXNwYqoCIUdvb2dsZS5DbG91ZC5GaW5hbmNpYWxTZXJ2aWNl
cy5WMcoCIUdvb2dsZVxDbG91ZFxGaW5hbmNpYWxTZXJ2aWNlc1xWMeoCJEdvb2dsZTo6Q2xv
dWQ6OkZpbmFuY2lhbFNlcnZpY2VzOjpWMUqTTQoHEgUOAJQCJgq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQARgoJCgIDAxIDFQBCCgkKAgMEEgMWACoKCQoCAwUSAxcAKQoICgEIEgMZAD4KCQoC
CCUSAxkAPgoICgEIEgMaAGoKCQoCCAsSAxoAagoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEI
EgMcACsKCQoCCAgSAxwAKwoICgEIEgMdAD4KCQoCCAESAx0APgoICgEIEgMeAD4KCQoCCCkS
Ax4APgoICgEIEgMfAD0KCQoCCC0SAx8APQovCgIEABIEIgB1ARojIE1vZGVsIHJlcHJlc2Vu
dHMgYSB0cmFpbmVkIG1vZGVsLgoKCgoDBAABEgMiCA0KCwoDBAAHEgQjAiYECg0KBQQAB50I
EgQjAiYECjIKBAQABAASBCkCOAMaJCBUaGUgcG9zc2libGUgc3RhdGVzIG9mIGEgcmVzb3Vy
Y2UuCgoMCgUEAAQAARIDKQcMCjgKBgQABAACABIDKwQaGikgU3RhdGUgaXMgdW5zcGVjaWZp
ZWQsIHNob3VsZCBub3Qgb2NjdXIuCgoOCgcEAAQAAgABEgMrBBUKDgoHBAAEAAIAAhIDKxgZ
Cj0KBgQABAACARIDLgQRGi4gVGhlIHJlc291cmNlIGhhcyBub3QgZmluaXNoZWQgYmVpbmcg
Y3JlYXRlZC4KCg4KBwQABAACAQESAy4EDAoOCgcEAAQAAgECEgMuDxAKOQoGBAAEAAICEgMx
BA8aKiBUaGUgcmVzb3VyY2UgaXMgYWN0aXZlL3JlYWR5IHRvIGJlIHVzZWQuCgoOCgcEAAQA
AgIBEgMxBAoKDgoHBAAEAAICAhIDMQ0OCkEKBgQABAACAxIDNAQRGjIgVGhlIHJlc291cmNl
IGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIHVwZGF0ZWQuCgoOCgcEAAQAAgMBEgM0BAwK
DgoHBAAEAAIDAhIDNA8QCkEKBgQABAACBBIDNwQRGjIgVGhlIHJlc291cmNlIGlzIGluIHRo
ZSBwcm9jZXNzIG9mIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgQBEgM3BAwKDgoHBAAEAAIE
AhIDNw8QCpkBCgQEAAIAEgM9Aj4aiwEgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1l
IG9mIHRoZSBNb2RlbC4KIGZvcm1hdDoKIGAvcHJvamVjdHMve3Byb2plY3RfbnVtfS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9tb2RlbHMve21vZGVsfWAK
CgwKBQQAAgAFEgM9AggKDAoFBAACAAESAz0JDQoMCgUEAAIAAxIDPRARCgwKBQQAAgAIEgM9
Ej0KDwoIBAACAAicCAASAz0TPApICgQEAAIBEgRAAkEyGjogT3V0cHV0IG9ubHkuIFRoZSB0
aW1lc3RhbXAgb2YgY3JlYXRpb24gb2YgdGhpcyByZXNvdXJjZS4KCgwKBQQAAgEGEgNAAhsK
DAoFBAACAQESA0AcJwoMCgUEAAIBAxIDQCorCgwKBQQAAgEIEgNBBjEKDwoIBAACAQicCAAS
A0EHMApWCgQEAAICEgREAkUyGkggT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2YgdGhl
IG1vc3QgcmVjZW50IHVwZGF0ZSBvZiB0aGlzIHJlc291cmNlLgoKDAoFBAACAgYSA0QCGwoM
CgUEAAICARIDRBwnCgwKBQQAAgIDEgNEKisKDAoFBAACAggSA0UGMQoPCggEAAICCJwIABID
RQcwChUKBAQAAgMSA0gCIRoIIExhYmVscwoKDAoFBAACAwYSA0gCFQoMCgUEAAIDARIDSBYc
CgwKBQQAAgMDEgNIHyAKUQoEBAACBBIDSwI+GkQgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRo
ZSBtb2RlbCAoY3JlYXRpbmcsIGFjdGl2ZSwgZGVsZXRpbmcsIGV0Yy4pCgoMCgUEAAIEBhID
SwIHCgwKBQQAAgQBEgNLCA0KDAoFBAACBAMSA0sQEQoMCgUEAAIECBIDSxI9Cg8KCAQAAgQI
nAgAEgNLEzwKkQEKBAQAAgUSBE8CVAQaggEgT3V0cHV0IG9ubHkuIFRoZSBFbmdpbmVWZXJz
aW9uIHVzZWQgaW4gdHJhaW5pbmcgdGhpcyBtb2RlbC4gIFRoaXMgaXMgb3V0cHV0CiBvbmx5
LCBhbmQgaXMgZGV0ZXJtaW5lZCBmcm9tIHRoZSBFbmdpbmVDb25maWcgdXNlZC4KCgwKBQQA
AgUFEgNPAggKDAoFBAACBQESA08JFwoMCgUEAAIFAxIDTxobCg0KBQQAAgUIEgRPHFQDCg8K
CAQAAgUInAgAEgNQBC0KDwoHBAACBQifCBIEUQRTBQrQAQoEBAACBhIEWQJeBBrBASBSZXF1
aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIEVuZ2luZUNvbmZpZyB0aGUgbW9kZWwg
dHJhaW5pbmcgd2lsbCBiZQogYmFzZWQgb24uIEZvcm1hdDoKIGAvcHJvamVjdHMve3Byb2pl
Y3RfbnVtfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9lbmdp
bmVDb25maWdzL3tlbmdpbmVDb25maWd9YAoKDAoFBAACBgUSA1kCCAoMCgUEAAIGARIDWQkW
CgwKBQQAAgYDEgNZGRoKDQoFBAACBggSBFkbXgMKDwoIBAACBgicCAASA1oEKgoPCgcEAAIG
CJ8IEgRbBF0FCrMCCgQEAAIHEgRkAmkEGqQCIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgUHJpbWFyeSBEYXRhc2V0IHVzZWQgaW4gdGhpcyBtb2RlbAogdHJhaW5pbmcu
IEZvciBpbmZvcm1hdGlvbiBhYm91dCBob3cgcHJpbWFyeSBhbmQgYXV4aWxpYXJ5IGRhdGFz
ZXRzIGFyZQogdXNlZCwgcmVmZXIgdG8gdGhlIGVuZ2luZSB2ZXJzaW9uJ3MgZG9jdW1lbnRh
dGlvbi4gIEZvcm1hdDoKIGAvcHJvamVjdHMve3Byb2plY3RfbnVtfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9kYXRhc2V0cy97ZGF0YXNldH1gCgoMCgUE
AAIHBRIDZAIICgwKBQQAAgcBEgNkCRgKDAoFBAACBwMSA2QbHAoNCgUEAAIHCBIEZB1pAwoP
CggEAAIHCJwIABIDZQQqCg8KBwQAAgcInwgSBGYEaAUK5QEKBAQAAggSBG4Cby8a1gEgUmVx
dWlyZWQuIEVuZF90aW1lIHNwZWNpZmllcyB0aGUgbGF0ZXN0IHRpbWUgZnJvbSB3aGljaCBs
YWJlbHMgYXJlIHVzZWQgYW5kCiBmcm9tIHdoaWNoIGRhdGEgaXMgdXNlZCB0byBnZW5lcmF0
ZSBmZWF0dXJlcyBmb3IgdHJhaW5pbmcuICBFbmRfdGltZSBzaG91bGQKIGJlIG5vIGxhdGVy
IHRoYW4gdGhlIGVuZCBvZiB0aGUgZGF0ZV9yYW5nZSBvZiB0aGUgZGF0YXNldC4KCgwKBQQA
AggGEgNuAhsKDAoFBAACCAESA24cJAoMCgUEAAIIAxIDbicpCgwKBQQAAggIEgNvBi4KDwoI
BAACCAicCAASA28HLQqSAQoEBAACCRIEcwJ0MhqDASBPdXRwdXQgb25seS4gVGhlIGxpbmUg
b2YgYnVzaW5lc3MgKFJldGFpbC9Db21tZXJjaWFsKSB0aGlzIG1vZGVsIGlzIHVzZWQKIGZv
ci4gRGV0ZXJtaW5lZCBieSBFbmdpbmVDb25maWcsIGNhbm5vdCBiZSBzZXQgYnkgdXNlci4K
CgwKBQQAAgkGEgNzAhAKDAoFBAACCQESA3MRIQoMCgUEAAIJAxIDcyQmCgwKBQQAAgkIEgN0
BjEKDwoIBAACCQicCAASA3QHMApsCgIEARIFeQCSAQEaXyBSZXF1ZXN0IGZvciByZXRyaWV2
aW5nIGEgcGFnaW5hdGVkIGxpc3Qgb2YgTW9kZWwgcmVzb3VyY2VzIHRoYXQgbWVldCB0aGUK
IHNwZWNpZmllZCBjcml0ZXJpYS4KCgoKAwQBARIDeQgZCkMKBAQBAgASBXsCgAEEGjQgUmVx
dWlyZWQuIFRoZSBwYXJlbnQgb2YgdGhlIE1vZGVsIGlzIHRoZSBJbnN0YW5jZS4KCgwKBQQB
AgAFEgN7AggKDAoFBAECAAESA3sJDwoMCgUEAQIAAxIDexITCg4KBQQBAgAIEgV7FIABAwoP
CggEAQIACJwIABIDfAQqCg8KBwQBAgAInwgSBH0EfwUKrQEKBAQBAgESBIUBAhYangEgVGhl
IG51bWJlciBvZiByZXNvdXJjZXMgdG8gYmUgaW5jbHVkZWQgaW4gdGhlIHJlc3BvbnNlLiBU
aGUgcmVzcG9uc2UKIGNvbnRhaW5zIGEgbmV4dF9wYWdlX3Rva2VuLCB3aGljaCBjYW4gYmUg
dXNlZCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mCiByZXNvdXJjZXMuCgoNCgUEAQIB
BRIEhQECBwoNCgUEAQIBARIEhQEIEQoNCgUEAQIBAxIEhQEUFQqiAgoEBAECAhIEiwECGBqT
AiBJbiBjYXNlIG9mIHBhZ2luYXRlZCByZXN1bHRzLCB0aGlzIGlzIHRoZSB0b2tlbiB0aGF0
IHdhcyByZXR1cm5lZCBpbiB0aGUKIHByZXZpb3VzIExpc3RNb2RlbHNSZXNwb25zZS4gSXQg
c2hvdWxkIGJlIGNvcGllZCBoZXJlIHRvIHJldHJpZXZlIHRoZSBuZXh0CiBwYWdlIG9mIHJl
c291cmNlcy4gRW1wdHkgd2lsbCBnaXZlIHRoZSBmaXJzdCBwYWdlIG9mIExpc3RNb2RlbHNS
ZXF1ZXN0LCBhbmQKIHRoZSBsYXN0IHBhZ2Ugd2lsbCByZXR1cm4gYW4gZW1wdHkgcGFnZV90
b2tlbi4KCg0KBQQBAgIFEgSLAQIICg0KBQQBAgIBEgSLAQkTCg0KBQQBAgIDEgSLARYXCjoK
BAQBAgMSBI4BAhQaLCBTcGVjaWZ5IGEgZmlsdGVyIHRvIG5hcnJvdyBzZWFyY2ggcmVzdWx0
cy4KCg0KBQQBAgMFEgSOAQIICg0KBQQBAgMBEgSOAQkPCg0KBQQBAgMDEgSOARITCjQKBAQB
AgQSBJEBAhYaJiBTcGVjaWZ5IGEgZmllbGQgdG8gdXNlIGZvciBvcmRlcmluZy4KCg0KBQQB
AgQFEgSRAQIICg0KBQQBAgQBEgSRAQkRCg0KBQQBAgQDEgSRARQVCjgKAgQCEgaVAQCfAQEa
KiBSZXNwb25zZSBmb3IgcmV0cmlldmluZyBhIGxpc3Qgb2YgTW9kZWxzCgoLCgMEAgESBJUB
CBoKJwoEBAICABIElwECHBoZIExpc3Qgb2YgTW9kZWwgcmVzb3VyY2VzCgoNCgUEAgIABBIE
lwECCgoNCgUEAgIABhIElwELEAoNCgUEAgIAARIElwERFwoNCgUEAgIAAxIElwEaGwqQAQoE
BAICARIEmwECHRqBASBUaGlzIHRva2VuIHNob3VsZCBiZSBwYXNzZWQgdG8gdGhlIG5leHQg
TGlzdE1vZGVsc1JlcXVlc3QgdG8KIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgTW9kZWxz
IChlbXB0eSBpbmRpY2ljYXRlcyB3ZSBhcmUgZG9uZSkuCgoNCgUEAgIBBRIEmwECCAoNCgUE
AgIBARIEmwEJGAoNCgUEAgIBAxIEmwEbHAo0CgQEAgICEgSeAQIiGiYgTG9jYXRpb25zIHRo
YXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAgICBBIEngECCgoNCgUEAgICBRIEngEL
EQoNCgUEAgICARIEngESHQoNCgUEAgICAxIEngEgIQpBCgIEAxIGogEAqgEBGjMgUmVxdWVz
dCBmb3IgcmV0cmlldmluZyBhIHNwZWNpZmljIE1vZGVsIHJlc291cmNlLgoKCwoDBAMBEgSi
AQgXCjoKBAQDAgASBqQBAqkBBBoqIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0
aGUgTW9kZWwKCg0KBQQDAgAFEgSkAQIICg0KBQQDAgABEgSkAQkNCg0KBQQDAgADEgSkARAR
Cg8KBQQDAgAIEgakARKpAQMKEAoIBAMCAAicCAASBKUBBCoKEQoHBAMCAAifCBIGpgEEqAEF
CjYKAgQEEgatAQDKAQEaKCBSZXF1ZXN0IGZvciBjcmVhdGluZyBhIE1vZGVsIHJlc291cmNl
LgoKCwoDBAQBEgStAQgaCkQKBAQEAgASBq8BArQBBBo0IFJlcXVpcmVkLiBUaGUgcGFyZW50
IG9mIHRoZSBNb2RlbCBpcyB0aGUgSW5zdGFuY2UuCgoNCgUEBAIABRIErwECCAoNCgUEBAIA
ARIErwEJDwoNCgUEBAIAAxIErwESEwoPCgUEBAIACBIGrwEUtAEDChAKCAQEAgAInAgAEgSw
AQQqChEKBwQEAgAInwgSBrEBBLMBBQo2CgQEBAIBEgS3AQI/GiggUmVxdWlyZWQuIFRoZSBy
ZXNvdXJjZSBpZCBvZiB0aGUgTW9kZWwKCg0KBQQEAgEFEgS3AQIICg0KBQQEAgEBEgS3AQkR
Cg0KBQQEAgEDEgS3ARQVCg0KBQQEAgEIEgS3ARY+ChAKCAQEAgEInAgAEgS3ARc9CjkKBAQE
AgISBLoBAjsaKyBSZXF1aXJlZC4gVGhlIE1vZGVsIHRoYXQgd2lsbCBiZSBjcmVhdGVkLgoK
DQoFBAQCAgYSBLoBAgcKDQoFBAQCAgESBLoBCA0KDQoFBAQCAgMSBLoBEBEKDQoFBAQCAggS
BLoBEjoKEAoIBAQCAgicCAASBLoBEzkKjwYKBAQEAgMSBMkBAkEagAYgT3B0aW9uYWwuIEFu
IG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1
bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVl
c3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQg
aGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVl
IHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3Qu
CgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFu
IGluaXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1h
a2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNl
cnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVx
dWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNv
bmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBj
cmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBi
ZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBu
b3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoK
DQoFBAQCAwUSBMkBAggKDQoFBAQCAwESBMkBCRMKDQoFBAQCAwMSBMkBFhcKDQoFBAQCAwgS
BMkBGEAKEAoIBAQCAwicCAASBMkBGT8KLAoCBAUSBs0BAOgBARoeIFJlcXVlc3QgZm9yIHVw
ZGF0aW5nIGEgTW9kZWwKCgsKAwQFARIEzQEIGgrXAgoEBAUCABIG0wEC1AEvGsYCIE9wdGlv
bmFsLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92
ZXJ3cml0dGVuIGluIHRoZQogTW9kZWwgcmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4KIFRoZSBm
aWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBhcmUgcmVsYXRpdmUgdG8gdGhl
IHJlc291cmNlLCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEgZmllbGQgd2lsbCBiZSBvdmVy
d3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4gSWYgdGhlCiB1c2VyIGRvZXMgbm90IHBy
b3ZpZGUgYSBtYXNrIHRoZW4gYWxsIGZpZWxkcyB3aWxsIGJlIG92ZXJ3cml0dGVuLgoKDQoF
BAUCAAYSBNMBAhsKDQoFBAUCAAESBNMBHCcKDQoFBAUCAAMSBNMBKisKDQoFBAUCAAgSBNQB
Bi4KEAoIBAUCAAicCAASBNQBBy0KbwoEBAUCARIE2AECOxphIFJlcXVpcmVkLiBUaGUgbmV3
IHZhbHVlIG9mIHRoZSBNb2RlbCBmaWVsZHMgdGhhdCB3aWxsIGJlIHVwZGF0ZWQgYWNjb3Jk
aW5nCiB0byB0aGUgdXBkYXRlX21hc2suCgoNCgUEBQIBBhIE2AECBwoNCgUEBQIBARIE2AEI
DQoNCgUEBQIBAxIE2AEQEQoNCgUEBQIBCBIE2AESOgoQCggEBQIBCJwIABIE2AETOQqPBgoE
BAUCAhIE5wECQRqABiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVu
dGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlm
IHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8K
IGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4g
VGhlIHNlcnZlciB3aWxsCiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRl
cyBzaW5jZSB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgYSBz
aXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCByZXF1ZXN0IGFuZCB0aGUKIHJl
cXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRo
ZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBjaGVjayBpZiBvcmlnaW5hbCBv
cGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3YXMgcmVjZWl2ZWQsIGFuZCBp
ZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzCiBj
bGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50
cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNl
cHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAt
MDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBQICBRIE5wECCAoNCgUEBQICARIE5wEJ
EwoNCgUEBQICAxIE5wEWFwoNCgUEBQICCBIE5wEYQAoQCggEBQICCJwIABIE5wEZPwotCgIE
BhIG6wEAggIBGh8gUmVxdWVzdCBmb3IgZGVsZXRpbmcgYSBNb2RlbC4KCgsKAwQGARIE6wEI
Ggo7CgQEBgIAEgbtAQLyAQQaKyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IE1vZGVsLgoKDQoFBAYCAAUSBO0BAggKDQoFBAYCAAESBO0BCQ0KDQoFBAYCAAMSBO0BEBEK
DwoFBAYCAAgSBu0BEvIBAwoQCggEBgIACJwIABIE7gEEKgoRCgcEBgIACJ8IEgbvAQTxAQUK
jwYKBAQGAgESBIECAkEagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8g
aWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhh
dCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93
IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0
ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1p
bnV0ZXMgYWZ0ZXIgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVy
IGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdGhl
CiByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0
aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2lu
YWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBh
bmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50
cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0
bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUg
ZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0w
MDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAYCAQUSBIECAggKDQoFBAYCAQES
BIECCRMKDQoFBAYCAQMSBIECFhcKDQoFBAYCAQgSBIECGEAKEAoIBAYCAQicCAASBIECGT8K
NQoCBAcSBoUCAJECARonIFJlcXVlc3QgZm9yIGV4cG9ydGluZyBNb2RlbCBtZXRhZGF0YS4K
CgsKAwQHARIEhQIIIgo7CgQEBwIAEgaHAgKMAgQaKyBSZXF1aXJlZC4gVGhlIHJlc291cmNl
IG5hbWUgb2YgdGhlIE1vZGVsLgoKDQoFBAcCAAUSBIcCAggKDQoFBAcCAAESBIcCCQ4KDQoF
BAcCAAMSBIcCERIKDwoFBAcCAAgSBocCE4wCAwoQCggEBwIACJwIABIEiAIEKgoRCgcEBwIA
CJ8IEgaJAgSLAgUKTwoEBAcCARIGjwICkAIvGj8gUmVxdWlyZWQuIEJpZ1F1ZXJ5IG91dHB1
dCB3aGVyZSB0aGUgbWV0YWRhdGEgd2lsbCBiZSB3cml0dGVuLgoKDQoFBAcCAQYSBI8CAhUK
DQoFBAcCAQESBI8CFjUKDQoFBAcCAQMSBI8CODkKDQoFBAcCAQgSBJACBi4KEAoIBAcCAQic
CAASBJACBy0KNAoCBAgSBJQCACYaKCBSZXNwb25zZSBmb3IgZXhwb3J0aW5nIE1vZGVsIG1l
dGFkYXRhLgoKCwoDBAgBEgSUAggjYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::Model::Model ===
    # Fields for Model
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.financialservices.v1.Model.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.financialservices.v1.Model.State)
    # Field: engine_version Type: 9 ()
    # Field: engine_config Type: 9 ()
    # Field: primary_dataset Type: 9 ()
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: line_of_business Type: 14 (.google.cloud.financialservices.v1.LineOfBusiness)

# Enum: Model::State
our $Model_STATE_UNSPECIFIED = 0;
our $Model_CREATING = 1;
our $Model_ACTIVE = 2;
our $Model_UPDATING = 3;
our $Model_DELETING = 4;

# === Message: Google::Cloud::Financialservices::V1::Model::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Model::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.cloud.financialservices.v1.Model)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Model::GetModelRequest ===
    # Fields for GetModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Model::CreateModelRequest ===
    # Fields for CreateModelRequest
    # Field: parent Type: 9 ()
    # Field: model_id Type: 9 ()
    # Field: model Type: 11 (.google.cloud.financialservices.v1.Model)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Model::UpdateModelRequest ===
    # Fields for UpdateModelRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: model Type: 11 (.google.cloud.financialservices.v1.Model)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Model::DeleteModelRequest ===
    # Fields for DeleteModelRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::Model::ExportModelMetadataRequest ===
    # Fields for ExportModelMetadataRequest
    # Field: model Type: 9 ()
    # Field: structured_metadata_destination Type: 11 (.google.cloud.financialservices.v1.BigQueryDestination)

# === Message: Google::Cloud::Financialservices::V1::Model::ExportModelMetadataResponse ===
    # Fields for ExportModelMetadataResponse

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::Model - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/model.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::Model;

    my $msg = Google::Cloud::Financialservices::V1::Model::Model->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::Model::Model

Model represents a trained model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the Model.
format:
`/projects/{project_num}/locations/{location}/instances/{instance}/models/{model}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of creation of this resource.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of the most recent update of this resource.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Model::Model::LabelsEntry>)

Labels

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::Model::State>)

Output only. State of the model (creating, active, deleting, etc.)

=item * C<< $msg->engine_version() >> / C<< $msg->engine_version($value) >>

Type: C<String>

Output only. The EngineVersion used in training this model.  This is output
only, and is determined from the EngineConfig used.

=item * C<< $msg->engine_config() >> / C<< $msg->engine_config($value) >>

Type: C<String>

Required. The resource name of the EngineConfig the model training will be
based on. Format:
`/projects/{project_num}/locations/{location}/instances/{instance}/engineConfigs/{engineConfig}`

=item * C<< $msg->primary_dataset() >> / C<< $msg->primary_dataset($value) >>

Type: C<String>

Required. The resource name of the Primary Dataset used in this model
training. For information about how primary and auxiliary datasets are
used, refer to the engine version's documentation.  Format:
`/projects/{project_num}/locations/{location}/instances/{instance}/datasets/{dataset}`

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. End_time specifies the latest time from which labels are used and
from which data is used to generate features for training.  End_time should
be no later than the end of the date_range of the dataset.

=item * C<< $msg->line_of_business() >> / C<< $msg->line_of_business($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::LineOfBusiness>)

Output only. The line of business (Retail/Commercial) this model is used
for. Determined by EngineConfig, cannot be set by user.

=back

=head3 Enum: Model::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Financialservices::V1::Model::ListModelsRequest

Request for retrieving a paginated list of Model resources that meet the
specified criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the Model is the Instance.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The number of resources to be included in the response. The response
contains a next_page_token, which can be used to retrieve the next page of
resources.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

In case of paginated results, this is the token that was returned in the
previous ListModelsResponse. It should be copied here to retrieve the next
page of resources. Empty will give the first page of ListModelsRequest, and
the last page will return an empty page_token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Specify a filter to narrow search results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Specify a field to use for ordering.

=back

=head2 Google::Cloud::Financialservices::V1::Model::ListModelsResponse

Response for retrieving a list of Models

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Model::Model>)

List of Model resources

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token should be passed to the next ListModelsRequest to
retrieve the next page of Models (empty indicicates we are done).

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Financialservices::V1::Model::GetModelRequest

Request for retrieving a specific Model resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Model

=back

=head2 Google::Cloud::Financialservices::V1::Model::CreateModelRequest

Request for creating a Model resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the Model is the Instance.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

Required. The resource id of the Model

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Model::Model>)

Required. The Model that will be created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::Model::UpdateModelRequest

Request for updating a Model

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
Model resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::Model::Model>)

Required. The new value of the Model fields that will be updated according
to the update_mask.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::Model::DeleteModelRequest

Request for deleting a Model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Model.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::Model::ExportModelMetadataRequest

Request for exporting Model metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The resource name of the Model.

=item * C<< $msg->structured_metadata_destination() >> / C<< $msg->structured_metadata_destination($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination>)

Required. BigQuery output where the metadata will be written.

=back

=head2 Google::Cloud::Financialservices::V1::Model::ExportModelMetadataResponse

Response for exporting Model metadata.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
