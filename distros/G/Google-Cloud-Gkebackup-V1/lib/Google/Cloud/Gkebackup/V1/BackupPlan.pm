package Google::Cloud::Gkebackup::V1::BackupPlan;

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
    eval { require Google::Cloud::Gkebackup::V1::Common };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Date };
    eval { require Google::Type::Dayofweek };
    eval { require Google::Type::Timeofday };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL2JhY2t1cF9wbGFuLnByb3RvEhlnb29nbGUu
Y2xvdWQuZ2tlYmFja3VwLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiZnb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL2Nv
bW1vbi5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvGhZnb29nbGUvdHlwZS9kYXRlLnByb3RvGhtnb29nbGUv
dHlwZS9kYXlvZndlZWsucHJvdG8aG2dvb2dsZS90eXBlL3RpbWVvZmRheS5wcm90byLEEgoK
QmFja3VwUGxhbhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSFQoDdWlkGAIgASgJQgPgQQNS
A3VpZBJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIlCgtkZXNjcmlwdGlvbhgFIAEoCUID4EEB
UgtkZXNjcmlwdGlvbhJFCgdjbHVzdGVyGAYgASgJQivgQQXgQQL6QSIKIGNvbnRhaW5lci5n
b29nbGVhcGlzLmNvbS9DbHVzdGVyUgdjbHVzdGVyEmUKEHJldGVudGlvbl9wb2xpY3kYByAB
KAsyNS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxLkJhY2t1cFBsYW4uUmV0ZW50aW9uUG9s
aWN5QgPgQQFSD3JldGVudGlvblBvbGljeRJOCgZsYWJlbHMYCCADKAsyMS5nb29nbGUuY2xv
dWQuZ2tlYmFja3VwLnYxLkJhY2t1cFBsYW4uTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzElwK
D2JhY2t1cF9zY2hlZHVsZRgJIAEoCzIuLmdvb2dsZS5jbG91ZC5na2ViYWNrdXAudjEuQmFj
a3VwUGxhbi5TY2hlZHVsZUID4EEBUg5iYWNrdXBTY2hlZHVsZRIXCgRldGFnGAogASgJQgPg
QQNSBGV0YWcSJQoLZGVhY3RpdmF0ZWQYCyABKAhCA+BBAVILZGVhY3RpdmF0ZWQSXAoNYmFj
a3VwX2NvbmZpZxgMIAEoCzIyLmdvb2dsZS5jbG91ZC5na2ViYWNrdXAudjEuQmFja3VwUGxh
bi5CYWNrdXBDb25maWdCA+BBAVIMYmFja3VwQ29uZmlnEjMKE3Byb3RlY3RlZF9wb2RfY291
bnQYDSABKAVCA+BBA1IRcHJvdGVjdGVkUG9kQ291bnQSRgoFc3RhdGUYDiABKA4yKy5nb29n
bGUuY2xvdWQuZ2tlYmFja3VwLnYxLkJhY2t1cFBsYW4uU3RhdGVCA+BBA1IFc3RhdGUSJgoM
c3RhdGVfcmVhc29uGA8gASgJQgPgQQNSC3N0YXRlUmVhc29uEikKDnJwb19yaXNrX2xldmVs
GBAgASgFQgPgQQNSDHJwb1Jpc2tMZXZlbBIrCg9ycG9fcmlza19yZWFzb24YESABKAlCA+BB
A1INcnBvUmlza1JlYXNvbhJVCg5iYWNrdXBfY2hhbm5lbBgSIAEoCUIu4EED+kEoCiZna2Vi
YWNrdXAuZ29vZ2xlYXBpcy5jb20vQmFja3VwQ2hhbm5lbFINYmFja3VwQ2hhbm5lbBJeChts
YXN0X3N1Y2Nlc3NmdWxfYmFja3VwX3RpbWUYEyABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSGGxhc3RTdWNjZXNzZnVsQmFja3VwVGltZRqdAQoPUmV0ZW50aW9uUG9s
aWN5EjoKF2JhY2t1cF9kZWxldGVfbG9ja19kYXlzGAEgASgFQgPgQQFSFGJhY2t1cERlbGV0
ZUxvY2tEYXlzEjEKEmJhY2t1cF9yZXRhaW5fZGF5cxgCIAEoBUID4EEBUhBiYWNrdXBSZXRh
aW5EYXlzEhsKBmxvY2tlZBgDIAEoCEID4EEBUgZsb2NrZWQa+QEKCFNjaGVkdWxlEigKDWNy
b25fc2NoZWR1bGUYASABKAlCA+BBAVIMY3JvblNjaGVkdWxlEhsKBnBhdXNlZBgCIAEoCEID
4EEBUgZwYXVzZWQSSAoKcnBvX2NvbmZpZxgDIAEoCzIkLmdvb2dsZS5jbG91ZC5na2ViYWNr
dXAudjEuUnBvQ29uZmlnQgPgQQFSCXJwb0NvbmZpZxJcChpuZXh0X3NjaGVkdWxlZF9iYWNr
dXBfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IXbmV4dFNj
aGVkdWxlZEJhY2t1cFRpbWUa6wMKDEJhY2t1cENvbmZpZxInCg5hbGxfbmFtZXNwYWNlcxgB
IAEoCEgAUg1hbGxOYW1lc3BhY2VzElgKE3NlbGVjdGVkX25hbWVzcGFjZXMYAiABKAsyJS5n
b29nbGUuY2xvdWQuZ2tlYmFja3VwLnYxLk5hbWVzcGFjZXNIAFISc2VsZWN0ZWROYW1lc3Bh
Y2VzEmEKFXNlbGVjdGVkX2FwcGxpY2F0aW9ucxgDIAEoCzIqLmdvb2dsZS5jbG91ZC5na2Vi
YWNrdXAudjEuTmFtZXNwYWNlZE5hbWVzSABSFHNlbGVjdGVkQXBwbGljYXRpb25zEjMKE2lu
Y2x1ZGVfdm9sdW1lX2RhdGEYBCABKAhCA+BBAVIRaW5jbHVkZVZvbHVtZURhdGESLAoPaW5j
bHVkZV9zZWNyZXRzGAUgASgIQgPgQQFSDmluY2x1ZGVTZWNyZXRzElQKDmVuY3J5cHRpb25f
a2V5GAYgASgLMiguZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MS5FbmNyeXB0aW9uS2V5QgPg
QQFSDWVuY3J5cHRpb25LZXkSLAoPcGVybWlzc2l2ZV9tb2RlGAcgASgIQgPgQQFSDnBlcm1p
c3NpdmVNb2RlQg4KDGJhY2t1cF9zY29wZRo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlS
A2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBInsKBVN0YXRlEhUKEVNUQVRFX1VOU1BF
Q0lGSUVEEAASEwoPQ0xVU1RFUl9QRU5ESU5HEAESEAoMUFJPVklTSU9OSU5HEAISCQoFUkVB
RFkQAxIKCgZGQUlMRUQQBBIPCgtERUFDVElWQVRFRBAFEgwKCERFTEVUSU5HEAY6a+pBaAoj
Z2tlYmFja3VwLmdvb2dsZWFwaXMuY29tL0JhY2t1cFBsYW4SQXByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBQbGFucy97YmFja3VwX3BsYW59IpwBCglS
cG9Db25maWcSMQoSdGFyZ2V0X3Jwb19taW51dGVzGAEgASgFQgPgQQJSEHRhcmdldFJwb01p
bnV0ZXMSXAoRZXhjbHVzaW9uX3dpbmRvd3MYAiADKAsyKi5nb29nbGUuY2xvdWQuZ2tlYmFj
a3VwLnYxLkV4Y2x1c2lvbldpbmRvd0ID4EEBUhBleGNsdXNpb25XaW5kb3dzIqgDCg9FeGNs
dXNpb25XaW5kb3cSOgoKc3RhcnRfdGltZRgBIAEoCzIWLmdvb2dsZS50eXBlLlRpbWVPZkRh
eUID4EECUglzdGFydFRpbWUSOgoIZHVyYXRpb24YAiABKAsyGS5nb29nbGUucHJvdG9idWYu
RHVyYXRpb25CA+BBAlIIZHVyYXRpb24SSQoWc2luZ2xlX29jY3VycmVuY2VfZGF0ZRgDIAEo
CzIRLmdvb2dsZS50eXBlLkRhdGVIAFIUc2luZ2xlT2NjdXJyZW5jZURhdGUSFgoFZGFpbHkY
BCABKAhIAFIFZGFpbHkSXAoMZGF5c19vZl93ZWVrGAUgASgLMjguZ29vZ2xlLmNsb3VkLmdr
ZWJhY2t1cC52MS5FeGNsdXNpb25XaW5kb3cuRGF5T2ZXZWVrTGlzdEgAUgpkYXlzT2ZXZWVr
Gk4KDURheU9mV2Vla0xpc3QSPQoMZGF5c19vZl93ZWVrGAEgAygOMhYuZ29vZ2xlLnR5cGUu
RGF5T2ZXZWVrQgPgQQFSCmRheXNPZldlZWtCDAoKcmVjdXJyZW5jZULGAQodY29tLmdvb2ds
ZS5jbG91ZC5na2ViYWNrdXAudjFCD0JhY2t1cFBsYW5Qcm90b1ABWjtjbG91ZC5nb29nbGUu
Y29tL2dvL2drZWJhY2t1cC9hcGl2MS9na2ViYWNrdXBwYjtna2ViYWNrdXBwYqoCGUdvb2ds
ZS5DbG91ZC5Ha2VCYWNrdXAuVjHKAhlHb29nbGVcQ2xvdWRcR2tlQmFja3VwXFYx6gIcR29v
Z2xlOjpDbG91ZDo6R2tlQmFja3VwOjpWMUqMdwoHEgUOAOwCAQq8BAoBDBIDDgASMrEEIENv
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
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQAMAoJCgIDAxIDFQAoCgkKAgMEEgMWACkKCQoCAwUSAxcAIAoJCgIDBhIDGAAlCgkK
AgMHEgMZACUKCAoBCBIDGwA2CgkKAgglEgMbADYKCAoBCBIDHABSCgkKAggLEgMcAFIKCAoB
CBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAwCgkKAggIEgMeADAKCAoBCBIDHwA2CgkKAggB
EgMfADYKCAoBCBIDIAA2CgkKAggpEgMgADYKCAoBCBIDIQA1CgkKAggtEgMhADUKUAoCBAAS
BSQAqgIBGkMgRGVmaW5lcyB0aGUgY29uZmlndXJhdGlvbiBhbmQgc2NoZWR1bGluZyBmb3Ig
YSAibGluZSIgb2YgQmFja3Vwcy4KCgoKAwQAARIDJAgSCgsKAwQABxIEJQIoBAoNCgUEAAed
CBIEJQIoBApTCgQEAAMAEgQrAlIDGkUgUmV0ZW50aW9uUG9saWN5IGRlZmluZXMgYSBCYWNr
dXAgcmV0ZW50aW9uIHBvbGljeSBmb3IgYSBCYWNrdXBQbGFuLgoKDAoFBAADAAESAysKGQrV
AwoGBAADAAIAEgM1BE8axQMgT3B0aW9uYWwuIE1pbmltdW0gYWdlIGZvciBCYWNrdXBzIGNy
ZWF0ZWQgdmlhIHRoaXMgQmFja3VwUGxhbiAoaW4gZGF5cykuCiBUaGlzIGZpZWxkIE1VU1Qg
YmUgYW4gaW50ZWdlciB2YWx1ZSBiZXR3ZWVuIDAtOTAgKGluY2x1c2l2ZSkuCiBBIEJhY2t1
cCBjcmVhdGVkIHVuZGVyIHRoaXMgQmFja3VwUGxhbiB3aWxsIE5PVCBiZSBkZWxldGFibGUg
dW50aWwgaXQKIHJlYWNoZXMgQmFja3VwJ3MgKGNyZWF0ZV90aW1lICsgYmFja3VwX2RlbGV0
ZV9sb2NrX2RheXMpLgogVXBkYXRpbmcgdGhpcyBmaWVsZCBvZiBhIEJhY2t1cFBsYW4gZG9l
cyBOT1QgYWZmZWN0IGV4aXN0aW5nIEJhY2t1cHMKIHVuZGVyIGl0LiBCYWNrdXBzIGNyZWF0
ZWQgQUZURVIgYSBzdWNjZXNzZnVsIHVwZGF0ZSB3aWxsIGluaGVyaXQKIHRoZSBuZXcgdmFs
dWUuCgogRGVmYXVsdDogMCAobm8gZGVsZXRlIGJsb2NraW5nKQoKDgoHBAADAAIABRIDNQQJ
Cg4KBwQAAwACAAESAzUKIQoOCgcEAAMAAgADEgM1JCUKDgoHBAADAAIACBIDNSZOChEKCgQA
AwACAAicCAASAzUnTQqnCAoGBAADAAIBEgNKBEoalwggT3B0aW9uYWwuIFRoZSBkZWZhdWx0
IG1heGltdW0gYWdlIG9mIGEgQmFja3VwIGNyZWF0ZWQgdmlhIHRoaXMKIEJhY2t1cFBsYW4u
IFRoaXMgZmllbGQgTVVTVCBiZSBhbiBpbnRlZ2VyIHZhbHVlID49IDAgYW5kIDw9IDM2NS4g
SWYKIHNwZWNpZmllZCwgYSBCYWNrdXAgY3JlYXRlZCB1bmRlciB0aGlzIEJhY2t1cFBsYW4g
d2lsbCBiZSBhdXRvbWF0aWNhbGx5CiBkZWxldGVkIGFmdGVyIGl0cyBhZ2UgcmVhY2hlcyAo
Y3JlYXRlX3RpbWUgKyBiYWNrdXBfcmV0YWluX2RheXMpLiBJZiBub3QKIHNwZWNpZmllZCwg
QmFja3VwcyBjcmVhdGVkIHVuZGVyIHRoaXMgQmFja3VwUGxhbiB3aWxsIE5PVCBiZSBzdWJq
ZWN0IHRvCiBhdXRvbWF0aWMgZGVsZXRpb24uIFVwZGF0aW5nIHRoaXMgZmllbGQgZG9lcyBO
T1QgYWZmZWN0IGV4aXN0aW5nIEJhY2t1cHMKIHVuZGVyIGl0LiBCYWNrdXBzIGNyZWF0ZWQg
QUZURVIgYSBzdWNjZXNzZnVsIHVwZGF0ZSB3aWxsIGF1dG9tYXRpY2FsbHkKIHBpY2sgdXAg
dGhlIG5ldyB2YWx1ZS4gTk9URTogYmFja3VwX3JldGFpbl9kYXlzIG11c3QgYmUgPj0KIFti
YWNrdXBfZGVsZXRlX2xvY2tfZGF5c11bZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC52MS5CYWNr
dXBQbGFuLlJldGVudGlvblBvbGljeS5iYWNrdXBfZGVsZXRlX2xvY2tfZGF5c10uCiBJZgog
W2Nyb25fc2NoZWR1bGVdW2dvb2dsZS5jbG91ZC5na2ViYWNrdXAudjEuQmFja3VwUGxhbi5T
Y2hlZHVsZS5jcm9uX3NjaGVkdWxlXQogaXMgZGVmaW5lZCwgdGhlbiB0aGlzIG11c3QgYmUK
IDw9IDM2MCAqIHRoZSBjcmVhdGlvbiBpbnRlcnZhbC4gSWYKIFtycG9fY29uZmlnXVtnb29n
bGUuY2xvdWQuZ2tlYmFja3VwLnYxLkJhY2t1cFBsYW4uU2NoZWR1bGUucnBvX2NvbmZpZ10g
aXMKIGRlZmluZWQsIHRoZW4gdGhpcyBtdXN0IGJlCiA8PSAzNjAgKiBbdGFyZ2V0X3Jwb19t
aW51dGVzXVtTY2hlZHVsZS5ycG9fY29uZmlnLnRhcmdldF9ycG9fbWludXRlc10gLwogKDE0
NDBtaW51dGVzL2RheSkuCgogRGVmYXVsdDogMCAobm8gYXV0b21hdGljIGRlbGV0aW9uKQoK
DgoHBAADAAIBBRIDSgQJCg4KBwQAAwACAQESA0oKHAoOCgcEAAMAAgEDEgNKHyAKDgoHBAAD
AAIBCBIDSiFJChEKCgQAAwACAQicCAASA0oiSAreAQoGBAADAAICEgNRBD0azgEgT3B0aW9u
YWwuIFRoaXMgZmxhZyBkZW5vdGVzIHdoZXRoZXIgdGhlIHJldGVudGlvbiBwb2xpY3kgb2Yg
dGhpcwogQmFja3VwUGxhbiBpcyBsb2NrZWQuICBJZiBzZXQgdG8gVHJ1ZSwgbm8gZnVydGhl
ciB1cGRhdGUgaXMgYWxsb3dlZCBvbgogdGhpcyBwb2xpY3ksIGluY2x1ZGluZyB0aGUgYGxv
Y2tlZGAgZmllbGQgaXRzZWxmLgoKIERlZmF1bHQ6IEZhbHNlCgoOCgcEAAMAAgIFEgNRBAgK
DgoHBAADAAICARIDUQkPCg4KBwQAAwACAgMSA1ESEwoOCgcEAAMAAgIIEgNRFDwKEQoKBAAD
AAICCJwIABIDURU7CmYKBAQAAwESBFYCeAMaWCBEZWZpbmVzIHNjaGVkdWxpbmcgcGFyYW1l
dGVycyBmb3IgYXV0b21hdGljYWxseSBjcmVhdGluZyBCYWNrdXBzCiB2aWEgdGhpcyBCYWNr
dXBQbGFuLgoKDAoFBAADAQESA1YKEgqeBAoGBAADAQIAEgNhBEYajgQgT3B0aW9uYWwuIEEg
c3RhbmRhcmQgW2Nyb25dKGh0dHBzOi8vd2lraXBlZGlhLmNvbS93aWtpL2Nyb24pIHN0cmlu
ZyB0aGF0CiBkZWZpbmVzIGEgcmVwZWF0aW5nIHNjaGVkdWxlIGZvciBjcmVhdGluZyBCYWNr
dXBzIHZpYSB0aGlzIEJhY2t1cFBsYW4uCiBUaGlzIGlzIG11dHVhbGx5IGV4Y2x1c2l2ZSB3
aXRoIHRoZQogW3Jwb19jb25maWddW2dvb2dsZS5jbG91ZC5na2ViYWNrdXAudjEuQmFja3Vw
UGxhbi5TY2hlZHVsZS5ycG9fY29uZmlnXQogZmllbGQgc2luY2UgYXQgbW9zdCBvbmUgc2No
ZWR1bGUgY2FuIGJlIGRlZmluZWQgZm9yIGEgQmFja3VwUGxhbi4gSWYgdGhpcwogaXMgZGVm
aW5lZCwgdGhlbgogW2JhY2t1cF9yZXRhaW5fZGF5c11bZ29vZ2xlLmNsb3VkLmdrZWJhY2t1
cC52MS5CYWNrdXBQbGFuLlJldGVudGlvblBvbGljeS5iYWNrdXBfcmV0YWluX2RheXNdCiBt
dXN0IGFsc28gYmUgZGVmaW5lZC4KCiBEZWZhdWx0IChlbXB0eSk6IG5vIGF1dG9tYXRpYyBi
YWNrdXAgY3JlYXRpb24gd2lsbCBvY2N1ci4KCg4KBwQAAwECAAUSA2EECgoOCgcEAAMBAgAB
EgNhCxgKDgoHBAADAQIAAxIDYRscCg4KBwQAAwECAAgSA2EdRQoRCgoEAAMBAgAInAgAEgNh
HkQKfwoGBAADAQIBEgNnBD0acCBPcHRpb25hbC4gVGhpcyBmbGFnIGRlbm90ZXMgd2hldGhl
ciBhdXRvbWF0aWMgQmFja3VwIGNyZWF0aW9uIGlzIHBhdXNlZAogZm9yIHRoaXMgQmFja3Vw
UGxhbi4KCiBEZWZhdWx0OiBGYWxzZQoKDgoHBAADAQIBBRIDZwQICg4KBwQAAwECAQESA2cJ
DwoOCgcEAAMBAgEDEgNnEhMKDgoHBAADAQIBCBIDZxQ8ChEKCgQAAwECAQicCAASA2cVOwrZ
AwoGBAADAQICEgNyBEYayQMgT3B0aW9uYWwuIERlZmluZXMgdGhlIFJQTyBzY2hlZHVsZSBj
b25maWd1cmF0aW9uIGZvciB0aGlzIEJhY2t1cFBsYW4uCiBUaGlzIGlzIG11dHVhbGx5IGV4
Y2x1c2l2ZSB3aXRoIHRoZQogW2Nyb25fc2NoZWR1bGVdW2dvb2dsZS5jbG91ZC5na2ViYWNr
dXAudjEuQmFja3VwUGxhbi5TY2hlZHVsZS5jcm9uX3NjaGVkdWxlXQogZmllbGQgc2luY2Ug
YXQgbW9zdCBvbmUgc2NoZWR1bGUgY2FuIGJlIGRlZmluZWQgZm9yIGEgQmFja3VwUExhbi4g
SWYgdGhpcwogaXMgZGVmaW5lZCwgdGhlbgogW2JhY2t1cF9yZXRhaW5fZGF5c11bZ29vZ2xl
LmNsb3VkLmdrZWJhY2t1cC52MS5CYWNrdXBQbGFuLlJldGVudGlvblBvbGljeS5iYWNrdXBf
cmV0YWluX2RheXNdCiBtdXN0IGFsc28gYmUgZGVmaW5lZC4KCiBEZWZhdWx0IChlbXB0eSk6
IG5vIGF1dG9tYXRpYyBiYWNrdXAgY3JlYXRpb24gd2lsbCBvY2N1ci4KCg4KBwQAAwECAgYS
A3IEDQoOCgcEAAMBAgIBEgNyDhgKDgoHBAADAQICAxIDchscCg4KBwQAAwECAggSA3IdRQoR
CgoEAAMBAgIInAgAEgNyHkQKgAEKBgQAAwECAxIEdgR3NBpwIE91dHB1dCBvbmx5LiBTdGFy
dCB0aW1lIG9mIG5leHQgc2NoZWR1bGVkIGJhY2t1cCB1bmRlciB0aGlzIEJhY2t1cFBsYW4g
YnkKIGVpdGhlciBjcm9uX3NjaGVkdWxlIG9yIHJwbyBjb25maWcuCgoOCgcEAAMBAgMGEgN2
BB0KDgoHBAADAQIDARIDdh44Cg4KBwQAAwECAwMSA3Y7PAoOCgcEAAMBAgMIEgN3CDMKEQoK
BAADAQIDCJwIABIDdwkyCmAKBAQAAwISBXwCpQEDGlEgQmFja3VwQ29uZmlnIGRlZmluZXMg
dGhlIGNvbmZpZ3VyYXRpb24gb2YgQmFja3VwcyBjcmVhdGVkIHZpYSB0aGlzCiBCYWNrdXBQ
bGFuLgoKDAoFBAADAgESA3wKFgrEAQoGBAADAggAEgaAAQSKAQUasQEgVGhpcyBkZWZpbmVz
IHRoZSAic2NvcGUiIG9mIHRoZSBCYWNrdXAgLSB3aGljaCBuYW1lc3BhY2VkCiByZXNvdXJj
ZXMgaW4gdGhlIGNsdXN0ZXIgd2lsbCBiZSBpbmNsdWRlZCBpbiBhIEJhY2t1cC4KIEV4YWN0
bHkgb25lIG9mIHRoZSBmaWVsZHMgb2YgYmFja3VwX3Njb3BlIE1VU1QgYmUgc3BlY2lmaWVk
LgoKDwoHBAADAggAARIEgAEKFgo7CgYEAAMCAgASBIIBBh4aKyBJZiBUcnVlLCBpbmNsdWRl
IGFsbCBuYW1lc3BhY2VkIHJlc291cmNlcwoKDwoHBAADAgIABRIEggEGCgoPCgcEAAMCAgAB
EgSCAQsZCg8KBwQAAwICAAMSBIIBHB0KTgoGBAADAgIBEgSFAQYpGj4gSWYgc2V0LCBpbmNs
dWRlIGp1c3QgdGhlIHJlc291cmNlcyBpbiB0aGUgbGlzdGVkIG5hbWVzcGFjZXMuCgoPCgcE
AAMCAgEGEgSFAQYQCg8KBwQAAwICAQESBIUBESQKDwoHBAADAgIBAxIEhQEnKAplCgYEAAMC
AgISBIkBBjAaVSBJZiBzZXQsIGluY2x1ZGUganVzdCB0aGUgcmVzb3VyY2VzIHJlZmVyZW5j
ZWQgYnkgdGhlIGxpc3RlZAogUHJvdGVjdGVkQXBwbGljYXRpb25zLgoKDwoHBAADAgICBhIE
iQEGFQoPCgcEAAMCAgIBEgSJARYrCg8KBwQAAwICAgMSBIkBLi8KmwEKBgQAAwICAxIEkAEE
ShqKASBPcHRpb25hbC4gVGhpcyBmbGFnIHNwZWNpZmllcyB3aGV0aGVyIHZvbHVtZSBkYXRh
IHNob3VsZCBiZSBiYWNrZWQgdXAKIHdoZW4gUFZDcyBhcmUgaW5jbHVkZWQgaW4gdGhlIHNj
b3BlIG9mIGEgQmFja3VwLgoKIERlZmF1bHQ6IEZhbHNlCgoPCgcEAAMCAgMFEgSQAQQICg8K
BwQAAwICAwESBJABCRwKDwoHBAADAgIDAxIEkAEfIAoPCgcEAAMCAgMIEgSQASFJChIKCgQA
AwICAwicCAASBJABIkgKowEKBgQAAwICBBIElgEERhqSASBPcHRpb25hbC4gVGhpcyBmbGFn
IHNwZWNpZmllcyB3aGV0aGVyIEt1YmVybmV0ZXMgU2VjcmV0IHJlc291cmNlcyBzaG91bGQK
IGJlIGluY2x1ZGVkIHdoZW4gdGhleSBmYWxsIGludG8gdGhlIHNjb3BlIG9mIEJhY2t1cHMu
CgogRGVmYXVsdDogRmFsc2UKCg8KBwQAAwICBAUSBJYBBAgKDwoHBAADAgIEARIElgEJGAoP
CgcEAAMCAgQDEgSWARscCg8KBwQAAwICBAgSBJYBHUUKEgoKBAADAgIECJwIABIElgEeRAr+
AQoGBAADAgIFEgSdAQROGu0BIE9wdGlvbmFsLiBUaGlzIGRlZmluZXMgYSBjdXN0b21lciBt
YW5hZ2VkIGVuY3J5cHRpb24ga2V5IHRoYXQgd2lsbCBiZQogdXNlZCB0byBlbmNyeXB0IHRo
ZSAiY29uZmlnIiBwb3J0aW9uICh0aGUgS3ViZXJuZXRlcyByZXNvdXJjZXMpIG9mCiBCYWNr
dXBzIGNyZWF0ZWQgdmlhIHRoaXMgcGxhbi4KCiBEZWZhdWx0IChlbXB0eSk6IENvbmZpZyBi
YWNrdXAgYXJ0aWZhY3RzIHdpbGwgbm90IGJlIGVuY3J5cHRlZC4KCg8KBwQAAwICBQYSBJ0B
BBEKDwoHBAADAgIFARIEnQESIAoPCgcEAAMCAgUDEgSdASMkCg8KBwQAAwICBQgSBJ0BJU0K
EgoKBAADAgIFCJwIABIEnQEmTAq+AQoGBAADAgIGEgSkAQRGGq0BIE9wdGlvbmFsLiBJZiBm
YWxzZSwgQmFja3VwcyB3aWxsIGZhaWwgd2hlbiBCYWNrdXAgZm9yIEdLRSBkZXRlY3RzCiBL
dWJlcm5ldGVzIGNvbmZpZ3VyYXRpb24gdGhhdCBpcyBub24tc3RhbmRhcmQgb3IKIHJlcXVp
cmVzIGFkZGl0aW9uYWwgc2V0dXAgdG8gcmVzdG9yZS4KCiBEZWZhdWx0OiBGYWxzZQoKDwoH
BAADAgIGBRIEpAEECAoPCgcEAAMCAgYBEgSkAQkYCg8KBwQAAwICBgMSBKQBGxwKDwoHBAAD
AgIGCBIEpAEdRQoSCgoEAAMCAgYInAgAEgSkAR5EChcKBAQABAASBqgBAr0BAxoHIFN0YXRl
CgoNCgUEAAQAARIEqAEHDAowCgYEAAQAAgASBKoBBBoaICBEZWZhdWx0IGZpcnN0IHZhbHVl
IGZvciBFbnVtcy4KCg8KBwQABAACAAESBKoBBBUKDwoHBAAEAAIAAhIEqgEYGQo6CgYEAAQA
AgESBK0BBBgaKiBXYWl0aW5nIGZvciBjbHVzdGVyIHN0YXRlIHRvIGJlIFJVTk5JTkcuCgoP
CgcEAAQAAgEBEgStAQQTCg8KBwQABAACAQISBK0BFhcKRAoGBAAEAAICEgSwAQQVGjQgVGhl
IEJhY2t1cFBsYW4gaXMgaW4gdGhlIHByb2Nlc3Mgb2YgYmVpbmcgY3JlYXRlZC4KCg8KBwQA
BAACAgESBLABBBAKDwoHBAAEAAICAhIEsAETFApYCgYEAAQAAgMSBLMBBA4aSCBUaGUgQmFj
a3VwUGxhbiBoYXMgc3VjY2Vzc2Z1bGx5IGJlZW4gY3JlYXRlZCBhbmQgaXMgcmVhZHkgZm9y
IEJhY2t1cHMuCgoPCgcEAAQAAgMBEgSzAQQJCg8KBwQABAACAwISBLMBDA0KMQoGBAAEAAIE
EgS2AQQPGiEgQmFja3VwUGxhbiBjcmVhdGlvbiBoYXMgZmFpbGVkLgoKDwoHBAAEAAIEARIE
tgEECgoPCgcEAAQAAgQCEgS2AQ0OCjYKBgQABAACBRIEuQEEFBomIFRoZSBCYWNrdXBQbGFu
IGhhcyBiZWVuIGRlYWN0aXZhdGVkLgoKDwoHBAAEAAIFARIEuQEEDwoPCgcEAAQAAgUCEgS5
ARITCkQKBgQABAACBhIEvAEEERo0IFRoZSBCYWNrdXBQbGFuIGlzIGluIHRoZSBwcm9jZXNz
IG9mIGJlaW5nIGRlbGV0ZWQuCgoPCgcEAAQAAgYBEgS8AQQMCg8KBwQABAACBgISBLwBDxAK
dgoEBAACABIEwQECPhpoIE91dHB1dCBvbmx5LiBUaGUgZnVsbCBuYW1lIG9mIHRoZSBCYWNr
dXBQbGFuIHJlc291cmNlLgogRm9ybWF0OiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9iYWNr
dXBQbGFucy8qYAoKDQoFBAACAAUSBMEBAggKDQoFBAACAAESBMEBCQ0KDQoFBAACAAMSBMEB
EBEKDQoFBAACAAgSBMEBEj0KEAoIBAACAAicCAASBMEBEzwKlwEKBAQAAgESBMUBAj0aiAEg
T3V0cHV0IG9ubHkuIFNlcnZlciBnZW5lcmF0ZWQgZ2xvYmFsIHVuaXF1ZSBpZGVudGlmaWVy
IG9mCiBbVVVJRF0oaHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvVW5pdmVyc2FsbHlf
dW5pcXVlX2lkZW50aWZpZXIpIGZvcm1hdC4KCg0KBQQAAgEFEgTFAQIICg0KBQQAAgEBEgTF
AQkMCg0KBQQAAgEDEgTFAQ8QCg0KBQQAAgEIEgTFARE8ChAKCAQAAgEInAgAEgTFARI7ClcK
BAQAAgISBsgBAskBMhpHIE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhpcyBC
YWNrdXBQbGFuIHJlc291cmNlIHdhcyBjcmVhdGVkLgoKDQoFBAACAgYSBMgBAhsKDQoFBAAC
AgESBMgBHCcKDQoFBAACAgMSBMgBKisKDQoFBAACAggSBMkBBjEKEAoIBAACAgicCAASBMkB
BzAKXQoEBAACAxIGzQECzgEyGk0gT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0
aGlzIEJhY2t1cFBsYW4gcmVzb3VyY2Ugd2FzIGxhc3QKIHVwZGF0ZWQuCgoNCgUEAAIDBhIE
zQECGwoNCgUEAAIDARIEzQEcJwoNCgUEAAIDAxIEzQEqKwoNCgUEAAIDCBIEzgEGMQoQCggE
AAIDCJwIABIEzgEHMApQCgQEAAIEEgTRAQJCGkIgT3B0aW9uYWwuIFVzZXIgc3BlY2lmaWVk
IGRlc2NyaXB0aXZlIHN0cmluZyBmb3IgdGhpcyBCYWNrdXBQbGFuLgoKDQoFBAACBAUSBNEB
AggKDQoFBAACBAESBNEBCRQKDQoFBAACBAMSBNEBFxgKDQoFBAACBAgSBNEBGUEKEAoIBAAC
BAicCAASBNEBGkAKzQEKBAQAAgUSBtgBAt4BBBq8ASBSZXF1aXJlZC4gSW1tdXRhYmxlLiBU
aGUgc291cmNlIGNsdXN0ZXIgZnJvbSB3aGljaCBCYWNrdXBzIHdpbGwgYmUgY3JlYXRlZAog
dmlhIHRoaXMgQmFja3VwUGxhbi4gVmFsaWQgZm9ybWF0czoKCiAtIGBwcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2NsdXN0ZXJzLypgCiAtIGBwcm9qZWN0cy8qL3pvbmVzLyovY2x1c3RlcnMv
KmAKCg0KBQQAAgUFEgTYAQIICg0KBQQAAgUBEgTYAQkQCg0KBQQAAgUDEgTYARMUCg8KBQQA
AgUIEgbYARXeAQMKEAoIBAACBQicCAASBNkBBCsKEAoIBAACBQicCAESBNoBBCoKEQoHBAAC
BQifCBIG2wEE3QEFCmAKBAQAAgYSBOIBAlAaUiBPcHRpb25hbC4gUmV0ZW50aW9uUG9saWN5
IGdvdmVybnMgbGlmZWN5Y2xlIG9mIEJhY2t1cHMgY3JlYXRlZCB1bmRlciB0aGlzCiBwbGFu
LgoKDQoFBAACBgYSBOIBAhEKDQoFBAACBgESBOIBEiIKDQoFBAACBgMSBOIBJSYKDQoFBAAC
BggSBOIBJ08KEAoIBAACBgicCAASBOIBKE4KQgoEBAACBxIE5QECSho0IE9wdGlvbmFsLiBB
IHNldCBvZiBjdXN0b20gbGFiZWxzIHN1cHBsaWVkIGJ5IHVzZXIuCgoNCgUEAAIHBhIE5QEC
FQoNCgUEAAIHARIE5QEWHAoNCgUEAAIHAxIE5QEfIAoNCgUEAAIHCBIE5QEhSQoQCggEAAIH
CJwIABIE5QEiSApgCgQEAAIIEgTpAQJIGlIgT3B0aW9uYWwuIERlZmluZXMgYSBzY2hlZHVs
ZSBmb3IgYXV0b21hdGljIEJhY2t1cCBjcmVhdGlvbiB2aWEgdGhpcwogQmFja3VwUGxhbi4K
Cg0KBQQAAggGEgTpAQIKCg0KBQQAAggBEgTpAQsaCg0KBQQAAggDEgTpAR0eCg0KBQQAAggI
EgTpAR9HChAKCAQAAggInAgAEgTpASBGCr8ECgQEAAIJEgTzAQI/GrAEIE91dHB1dCBvbmx5
LiBgZXRhZ2AgaXMgdXNlZCBmb3Igb3B0aW1pc3RpYyBjb25jdXJyZW5jeSBjb250cm9sIGFz
IGEgd2F5IHRvCiBoZWxwIHByZXZlbnQgc2ltdWx0YW5lb3VzIHVwZGF0ZXMgb2YgYSBiYWNr
dXAgcGxhbiBmcm9tIG92ZXJ3cml0aW5nIGVhY2gKIG90aGVyLiBJdCBpcyBzdHJvbmdseSBz
dWdnZXN0ZWQgdGhhdCBzeXN0ZW1zIG1ha2UgdXNlIG9mIHRoZSAnZXRhZycgaW4gdGhlCiBy
ZWFkLW1vZGlmeS13cml0ZSBjeWNsZSB0byBwZXJmb3JtIEJhY2t1cFBsYW4gdXBkYXRlcyBp
biBvcmRlciB0byBhdm9pZAogcmFjZSBjb25kaXRpb25zOiBBbiBgZXRhZ2AgaXMgcmV0dXJu
ZWQgaW4gdGhlIHJlc3BvbnNlIHRvIGBHZXRCYWNrdXBQbGFuYCwKIGFuZCBzeXN0ZW1zIGFy
ZSBleHBlY3RlZCB0byBwdXQgdGhhdCBldGFnIGluIHRoZSByZXF1ZXN0IHRvCiBgVXBkYXRl
QmFja3VwUGxhbmAgb3IgYERlbGV0ZUJhY2t1cFBsYW5gIHRvIGVuc3VyZSB0aGF0IHRoZWly
IGNoYW5nZQogd2lsbCBiZSBhcHBsaWVkIHRvIHRoZSBzYW1lIHZlcnNpb24gb2YgdGhlIHJl
c291cmNlLgoKDQoFBAACCQUSBPMBAggKDQoFBAACCQESBPMBCQ0KDQoFBAACCQMSBPMBEBIK
DQoFBAACCQgSBPMBEz4KEAoIBAACCQicCAASBPMBFD0K7wIKBAQAAgoSBPwBAkEa4AIgT3B0
aW9uYWwuIFRoaXMgZmxhZyBpbmRpY2F0ZXMgd2hldGhlciB0aGlzIEJhY2t1cFBsYW4gaGFz
IGJlZW4gZGVhY3RpdmF0ZWQuCiBTZXR0aW5nIHRoaXMgZmllbGQgdG8gVHJ1ZSBsb2NrcyB0
aGUgQmFja3VwUGxhbiBzdWNoIHRoYXQgbm8gZnVydGhlcgogdXBkYXRlcyB3aWxsIGJlIGFs
bG93ZWQgKGV4Y2VwdCBkZWxldGVzKSwgaW5jbHVkaW5nIHRoZSBkZWFjdGl2YXRlZCBmaWVs
ZAogaXRzZWxmLiBJdCBhbHNvIHByZXZlbnRzIGFueSBuZXcgQmFja3VwcyBmcm9tIGJlaW5n
IGNyZWF0ZWQgdmlhIHRoaXMKIEJhY2t1cFBsYW4gKGluY2x1ZGluZyBzY2hlZHVsZWQgQmFj
a3VwcykuCgogRGVmYXVsdDogRmFsc2UKCg0KBQQAAgoFEgT8AQIGCg0KBQQAAgoBEgT8AQcS
Cg0KBQQAAgoDEgT8ARUXCg0KBQQAAgoIEgT8ARhAChAKCAQAAgoInAgAEgT8ARk/ClsKBAQA
AgsSBP8BAksaTSBPcHRpb25hbC4gRGVmaW5lcyB0aGUgY29uZmlndXJhdGlvbiBvZiBCYWNr
dXBzIGNyZWF0ZWQgdmlhIHRoaXMgQmFja3VwUGxhbi4KCg0KBQQAAgsGEgT/AQIOCg0KBQQA
AgsBEgT/AQ8cCg0KBQQAAgsDEgT/AR8hCg0KBQQAAgsIEgT/ASJKChAKCAQAAgsInAgAEgT/
ASNJCoABCgQEAAIMEgSDAgJNGnIgT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgS3ViZXJu
ZXRlcyBQb2RzIGJhY2tlZCB1cCBpbiB0aGUKIGxhc3Qgc3VjY2Vzc2Z1bCBCYWNrdXAgY3Jl
YXRlZCB2aWEgdGhpcyBCYWNrdXBQbGFuLgoKDQoFBAACDAUSBIMCAgcKDQoFBAACDAESBIMC
CBsKDQoFBAACDAMSBIMCHiAKDQoFBAACDAgSBIMCIUwKEAoIBAACDAicCAASBIMCIksK6AEK
BAQAAg0SBIkCAj8a2QEgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBCYWNrdXBQbGFuLiBU
aGlzIFN0YXRlIGZpZWxkIHJlZmxlY3RzIHRoZQogdmFyaW91cyBzdGFnZXMgYSBCYWNrdXBQ
bGFuIGNhbiBiZSBpbgogZHVyaW5nIHRoZSBDcmVhdGUgb3BlcmF0aW9uLiBJdCB3aWxsIGJl
IHNldCB0byAiREVBQ1RJVkFURUQiCiBpZiB0aGUgQmFja3VwUGxhbiBpcyBkZWFjdGl2YXRl
ZCBvbiBhbiBVcGRhdGUKCg0KBQQAAg0GEgSJAgIHCg0KBQQAAg0BEgSJAggNCg0KBQQAAg0D
EgSJAhASCg0KBQQAAg0IEgSJAhM+ChAKCAQAAg0InAgAEgSJAhQ9CvABCgQEAAIOEgSOAgJH
GuEBIE91dHB1dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB3aHkgQmFj
a3VwUGxhbiBpcyBpbiB0aGUgY3VycmVudAogYHN0YXRlYC4gVGhpcyBmaWVsZCBpcyBvbmx5
IG1lYW50IGZvciBodW1hbiByZWFkYWJpbGl0eSBhbmQgc2hvdWxkIG5vdCBiZQogdXNlZCBw
cm9ncmFtbWF0aWNhbGx5IGFzIHRoaXMgZmllbGQgaXMgbm90IGd1YXJhbnRlZWQgdG8gYmUg
Y29uc2lzdGVudC4KCg0KBQQAAg4FEgSOAgIICg0KBQQAAg4BEgSOAgkVCg0KBQQAAg4DEgSO
AhgaCg0KBQQAAg4IEgSOAhtGChAKCAQAAg4InAgAEgSOAhxFCqYBCgQEAAIPEgSTAgJIGpcB
IE91dHB1dCBvbmx5LiBBIG51bWJlciB0aGF0IHJlcHJlc2VudHMgdGhlIGN1cnJlbnQgcmlz
ayBsZXZlbCBvZiB0aGlzCiBCYWNrdXBQbGFuIGZyb20gUlBPIHBlcnNwZWN0aXZlIHdpdGgg
MSBiZWluZyBubyByaXNrIGFuZCA1IGJlaW5nIGhpZ2hlc3QKIHJpc2suCgoNCgUEAAIPBRIE
kwICBwoNCgUEAAIPARIEkwIIFgoNCgUEAAIPAxIEkwIZGwoNCgUEAAIPCBIEkwIcRwoQCggE
AAIPCJwIABIEkwIdRgqIAQoEBAACEBIElwICShp6IE91dHB1dCBvbmx5LiBIdW1hbi1yZWFk
YWJsZSBkZXNjcmlwdGlvbiBvZiB3aHkgdGhlIEJhY2t1cFBsYW4gaXMgaW4gdGhlCiBjdXJy
ZW50IHJwb19yaXNrX2xldmVsIGFuZCBhY3Rpb24gaXRlbXMgaWYgYW55LgoKDQoFBAACEAUS
BJcCAggKDQoFBAACEAESBJcCCRgKDQoFBAACEAMSBJcCGx0KDQoFBAACEAgSBJcCHkkKEAoI
BAACEAicCAASBJcCH0gK6gEKBAQAAhESBp0CAqICBBrZASBPdXRwdXQgb25seS4gVGhlIGZ1
bGx5IHF1YWxpZmllZCBuYW1lIG9mIHRoZSBCYWNrdXBDaGFubmVsIHRvIGJlIHVzZWQgdG8K
IGNyZWF0ZSBhIGJhY2t1cC4gVGhpcyBmaWVsZCBpcyBzZXQgb25seSBpZiB0aGUgY2x1c3Rl
ciBiZWluZyBiYWNrZWQgdXAgaXMKIGluIGEgZGlmZmVyZW50IHByb2plY3QuCiBgcHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9iYWNrdXBDaGFubmVscy8qYAoKDQoFBAACEQUSBJ0CAggKDQoF
BAACEQESBJ0CCRcKDQoFBAACEQMSBJ0CGhwKDwoFBAACEQgSBp0CHaICAwoQCggEAAIRCJwI
ABIEngIELQoRCgcEAAIRCJ8IEgafAgShAgUK/AEKBAQAAhISBqgCAqkCMhrrASBPdXRwdXQg
b25seS4gQ29tcGxldGlvbiB0aW1lIG9mIHRoZSBsYXN0IHN1Y2Nlc3NmdWwgQmFja3VwLiBU
aGlzIGlzIHNvdXJjZWQKIGZyb20gYSBzdWNjZXNzZnVsIEJhY2t1cCdzIGNvbXBsZXRlX3Rp
bWUgZmllbGQuIFRoaXMgZmllbGQgaXMgYWRkZWQgdG8KIG1haW50YWluIGNvbnNpc3RlbmN5
IHdpdGggQmFja3VwUGxhbkJpbmRpbmcgdG8gZGlzcGxheSBsYXN0IHN1Y2Nlc3NmdWwKIGJh
Y2t1cCB0aW1lLgoKDQoFBAACEgYSBKgCAhsKDQoFBAACEgESBKgCHDcKDQoFBAACEgMSBKgC
OjwKDQoFBAACEggSBKkCBjEKEAoIBAACEgicCAASBKkCBzAKbQoCBAESBq4CAMECARpfIERl
ZmluZXMgUlBPIHNjaGVkdWxpbmcgY29uZmlndXJhdGlvbiBmb3IgYXV0b21hdGljYWxseSBj
cmVhdGluZwogQmFja3VwcyB2aWEgdGhpcyBCYWNrdXBQbGFuLgoKCwoDBAEBEgSuAggRCvYB
CgQEAQIAEgSzAgJIGucBIFJlcXVpcmVkLiBEZWZpbmVzIHRoZSB0YXJnZXQgUlBPIGZvciB0
aGUgQmFja3VwUGxhbiBpbiBtaW51dGVzLCB3aGljaCBtZWFucwogdGhlIHRhcmdldCBtYXhp
bXVtIGRhdGEgbG9zcyBpbiB0aW1lIHRoYXQgaXMgYWNjZXB0YWJsZSBmb3IgdGhpcwogQmFj
a3VwUGxhbi4gVGhpcyBtdXN0IGJlIGF0IGxlYXN0IDYwLCBpLmUuLCAxIGhvdXIsIGFuZCBh
dCBtb3N0IDg2NDAwLAogaS5lLiwgNjAgZGF5cy4KCg0KBQQBAgAFEgSzAgIHCg0KBQQBAgAB
EgSzAggaCg0KBQQBAgADEgSzAh0eCg0KBQQBAgAIEgSzAh9HChAKCAQBAgAInAgAEgSzAiBG
CtMECgQEAQIBEga/AgLAAi8awgQgT3B0aW9uYWwuIFVzZXIgc3BlY2lmaWVkIHRpbWUgd2lu
ZG93cyBkdXJpbmcgd2hpY2ggYmFja3VwIGNhbiBOT1QgaGFwcGVuCiBmb3IgdGhpcyBCYWNr
dXBQbGFuIC0gYmFja3VwcyBzaG91bGQgc3RhcnQgYW5kIGZpbmlzaCBvdXRzaWRlIG9mIGFu
eSBnaXZlbgogZXhjbHVzaW9uIHdpbmRvdy4gTm90ZTogYmFja3VwIGpvYnMgd2lsbCBiZSBz
Y2hlZHVsZWQgdG8gc3RhcnQgYW5kCiBmaW5pc2ggb3V0c2lkZSB0aGUgZHVyYXRpb24gb2Yg
dGhlIHdpbmRvdyBhcyBtdWNoIGFzIHBvc3NpYmxlLCBidXQKIHJ1bm5pbmcgam9icyB3aWxs
IG5vdCBnZXQgY2FuY2VsZWQgd2hlbiBpdCBydW5zIGludG8gdGhlIHdpbmRvdy4KIEFsbCB0
aGUgdGltZSBhbmQgZGF0ZSB2YWx1ZXMgaW4gZXhjbHVzaW9uX3dpbmRvd3MgZW50cnkgaW4g
dGhlIEFQSSBhcmUgaW4KIFVUQy4KIFdlIG9ubHkgYWxsb3cgPD0xIHJlY3VycmVuY2UgKGRh
aWx5IG9yIHdlZWtseSkgZXhjbHVzaW9uIHdpbmRvdyBmb3IgYQogQmFja3VwUGxhbiB3aGls
ZSBubyByZXN0cmljdGlvbiBvbiBudW1iZXIgb2Ygc2luZ2xlIG9jY3VycmVuY2UKIHdpbmRv
d3MuCgoNCgUEAQIBBBIEvwICCgoNCgUEAQIBBhIEvwILGgoNCgUEAQIBARIEvwIbLAoNCgUE
AQIBAxIEvwIvMAoNCgUEAQIBCBIEwAIGLgoQCggEAQIBCJwIABIEwAIHLQpqCgIEAhIGxQIA
7AIBGlwgRGVmaW5lcyBhIHRpbWUgd2luZG93IGR1cmluZyB3aGljaCBubyBiYWNrdXAgc2hv
dWxkCiBoYXBwZW4uIEFsbCB0aW1lIGFuZCBkYXRlIGFyZSBpbiBVVEMuCgoLCgMEAgESBMUC
CBcKQgoEBAIDABIGxwICywIDGjIgSG9sZHMgcmVwZWF0ZWQgRGF5c09mV2VlayB2YWx1ZXMg
YXMgYSBjb250YWluZXIuCgoNCgUEAgMAARIExwIKFwo1CgYEAgMAAgASBskCBMoCMRojIE9w
dGlvbmFsLiBBIGxpc3Qgb2YgZGF5cyBvZiB3ZWVrLgoKDwoHBAIDAAIABBIEyQIEDAoPCgcE
AgMAAgAGEgTJAg0iCg8KBwQCAwACAAESBMkCIy8KDwoHBAIDAAIAAxIEyQIyMwoPCgcEAgMA
AgAIEgTKAggwChIKCgQCAwACAAicCAASBMoCCS8KXwoEBAICABIEzwICUBpRIFJlcXVpcmVk
LiBTcGVjaWZpZXMgdGhlIHN0YXJ0IHRpbWUgb2YgdGhlIHdpbmRvdyB1c2luZyB0aW1lIG9m
IHRoZSBkYXkgaW4KIFVUQy4KCg0KBQQCAgAGEgTPAgIXCg0KBQQCAgABEgTPAhgiCg0KBQQC
AgADEgTPAiUmCg0KBQQCAgAIEgTPAidPChAKCAQCAgAInAgAEgTPAihOCooECgQEAgIBEgbb
AgLcAi8a+QMgUmVxdWlyZWQuIFNwZWNpZmllcyBkdXJhdGlvbiBvZiB0aGUgd2luZG93Lgog
RHVyYXRpb24gbXVzdCBiZSA+PSA1IG1pbnV0ZXMgYW5kIDwgKHRhcmdldCBSUE8gLSAyMCBt
aW51dGVzKS4KIEFkZGl0aW9uYWwgcmVzdHJpY3Rpb25zIGJhc2VkIG9uIHRoZSByZWN1cnJl
bmNlIHR5cGUgdG8gYWxsb3cgc29tZSB0aW1lIGZvcgogYmFja3VwIHRvIGhhcHBlbjoKIC0g
c2luZ2xlX29jY3VycmVuY2VfZGF0ZTogIG5vIHJlc3RyaWN0aW9uLCBidXQgVUkgbWF5IHdh
cm4gYWJvdXQgdGhpcyB3aGVuCiBkdXJhdGlvbiA+PSB0YXJnZXQgUlBPCiAtIGRhaWx5IHdp
bmRvdzogZHVyYXRpb24gPCAyNCBob3VycwogLSB3ZWVrbHkgd2luZG93OgogICAtIGRheXMg
b2Ygd2VlayBpbmNsdWRlcyBhbGwgc2V2ZW4gZGF5cyBvZiBhIHdlZWs6IGR1cmF0aW9uIDwg
MjQgaG91cnMKICAgLSBhbGwgb3RoZXIgd2Vla2x5IHdpbmRvdzogZHVyYXRpb24gPCAxNjgg
aG91cnMgKGkuZS4sIDI0ICogNyBob3VycykKCg0KBQQCAgEGEgTbAgIaCg0KBQQCAgEBEgTb
AhsjCg0KBQQCAgEDEgTbAiYnCg0KBQQCAgEIEgTcAgYuChAKCAQCAgEInAgAEgTcAgctCooB
CgQEAggAEgbgAgLrAgMaeiBSZXF1aXJlZC4gU3BlY2lmaWVzIHRoZSBkYXkocykgb24gd2hp
Y2ggdGhlIGV4Y2x1c2lvbiB3aW5kb3cgdGFrZXMKIGVmZmVjdC4gRXhhY3RseSBvbmUgb2Yg
dGhlIGZpZWxkcyBNVVNUIGJlIHNwZWNpZmllZC4KCg0KBQQCCAABEgTgAggSCl4KBAQCAgIS
BOMCBDAaUCBObyByZWN1cnJlbmNlLiBUaGUgZXhjbHVzaW9uIHdpbmRvdyBvY2N1cnMgb25s
eSBvbmNlIGFuZCBvbiB0aGlzCiBkYXRlIGluIFVUQy4KCg0KBQQCAgIGEgTjAgQUCg0KBQQC
AgIBEgTjAhUrCg0KBQQCAgIDEgTjAi4vCnYKBAQCAgMSBOcCBBMaaCBUaGUgZXhjbHVzaW9u
IHdpbmRvdyBvY2N1cnMgZXZlcnkgZGF5IGlmIHNldCB0byAiVHJ1ZSIuCiBTcGVjaWZ5aW5n
IHRoaXMgZmllbGQgdG8gIkZhbHNlIiBpcyBhbiBlcnJvci4KCg0KBQQCAgMFEgTnAgQICg0K
BQQCAgMBEgTnAgkOCg0KBQQCAgMDEgTnAhESCk4KBAQCAgQSBOoCBCMaQCBUaGUgZXhjbHVz
aW9uIHdpbmRvdyBvY2N1cnMgb24gdGhlc2UgZGF5cyBvZiBlYWNoIHdlZWsgaW4gVVRDLgoK
DQoFBAICBAYSBOoCBBEKDQoFBAICBAESBOoCEh4KDQoFBAICBAMSBOoCISJiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan ===
    # Fields for BackupPlan
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: cluster Type: 9 ()
    # Field: retention_policy Type: 11 (.google.cloud.gkebackup.v1.BackupPlan.RetentionPolicy)
    # Field: labels Type: 11 (.google.cloud.gkebackup.v1.BackupPlan.LabelsEntry)
    # Field: backup_schedule Type: 11 (.google.cloud.gkebackup.v1.BackupPlan.Schedule)
    # Field: etag Type: 9 ()
    # Field: deactivated Type: 8 ()
    # Field: backup_config Type: 11 (.google.cloud.gkebackup.v1.BackupPlan.BackupConfig)
    # Field: protected_pod_count Type: 5 ()
    # Field: state Type: 14 (.google.cloud.gkebackup.v1.BackupPlan.State)
    # Field: state_reason Type: 9 ()
    # Field: rpo_risk_level Type: 5 ()
    # Field: rpo_risk_reason Type: 9 ()
    # Field: backup_channel Type: 9 ()
    # Field: last_successful_backup_time Type: 11 (.google.protobuf.Timestamp)

# Enum: BackupPlan::State
our $BackupPlan_STATE_UNSPECIFIED = 0;
our $BackupPlan_CLUSTER_PENDING = 1;
our $BackupPlan_PROVISIONING = 2;
our $BackupPlan_READY = 3;
our $BackupPlan_FAILED = 4;
our $BackupPlan_DEACTIVATED = 5;
our $BackupPlan_DELETING = 6;

# === Message: Google::Cloud::Gkebackup::V1::BackupPlan::RpoConfig ===
    # Fields for RpoConfig
    # Field: target_rpo_minutes Type: 5 ()
    # Field: exclusion_windows Type: 11 (.google.cloud.gkebackup.v1.ExclusionWindow)

# === Message: Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow ===
    # Fields for ExclusionWindow
    # Field: start_time Type: 11 (.google.type.TimeOfDay)
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: single_occurrence_date Type: 11 (.google.type.Date)
    # Field: daily Type: 8 ()
    # Field: days_of_week Type: 11 (.google.cloud.gkebackup.v1.ExclusionWindow.DayOfWeekList)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::V1::BackupPlan - Compiled Protocol Buffers messages for google/cloud/gkebackup/v1/backup_plan.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::BackupPlan;

    my $msg = Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/v1/backup_plan.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan

Defines the configuration and scheduling for a "line" of Backups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The full name of the BackupPlan resource.
Format: `projects/*/locations/*/backupPlans/*`

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated global unique identifier of
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) format.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this BackupPlan resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this BackupPlan resource was last
updated.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User specified descriptive string for this BackupPlan.

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<String>

Required. Immutable. The source cluster from which Backups will be created
via this BackupPlan. Valid formats:

- `projects/*/locations/*/clusters/*`
- `projects/*/zones/*/clusters/*`

=item * C<< $msg->retention_policy() >> / C<< $msg->retention_policy($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::RetentionPolicy>)

Optional. RetentionPolicy governs lifecycle of Backups created under this
plan.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::LabelsEntry>)

Optional. A set of custom labels supplied by user.

=item * C<< $msg->backup_schedule() >> / C<< $msg->backup_schedule($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::Schedule>)

Optional. Defines a schedule for automatic Backup creation via this
BackupPlan.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. `etag` is used for optimistic concurrency control as a way to
help prevent simultaneous updates of a backup plan from overwriting each
other. It is strongly suggested that systems make use of the 'etag' in the
read-modify-write cycle to perform BackupPlan updates in order to avoid
race conditions: An `etag` is returned in the response to `GetBackupPlan`,
and systems are expected to put that etag in the request to
`UpdateBackupPlan` or `DeleteBackupPlan` to ensure that their change
will be applied to the same version of the resource.

=item * C<< $msg->deactivated() >> / C<< $msg->deactivated($value) >>

Type: C<Bool>

Optional. This flag indicates whether this BackupPlan has been deactivated.
Setting this field to True locks the BackupPlan such that no further
updates will be allowed (except deletes), including the deactivated field
itself. It also prevents any new Backups from being created via this
BackupPlan (including scheduled Backups).

Default: False

=item * C<< $msg->backup_config() >> / C<< $msg->backup_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::BackupConfig>)

Optional. Defines the configuration of Backups created via this BackupPlan.

=item * C<< $msg->protected_pod_count() >> / C<< $msg->protected_pod_count($value) >>

Type: C<Int32>

Output only. The number of Kubernetes Pods backed up in the
last successful Backup created via this BackupPlan.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::V1::BackupPlan::State>)

Output only. State of the BackupPlan. This State field reflects the
various stages a BackupPlan can be in
during the Create operation. It will be set to "DEACTIVATED"
if the BackupPlan is deactivated on an Update

=item * C<< $msg->state_reason() >> / C<< $msg->state_reason($value) >>

Type: C<String>

Output only. Human-readable description of why BackupPlan is in the current
`state`. This field is only meant for human readability and should not be
used programmatically as this field is not guaranteed to be consistent.

=item * C<< $msg->rpo_risk_level() >> / C<< $msg->rpo_risk_level($value) >>

Type: C<Int32>

Output only. A number that represents the current risk level of this
BackupPlan from RPO perspective with 1 being no risk and 5 being highest
risk.

=item * C<< $msg->rpo_risk_reason() >> / C<< $msg->rpo_risk_reason($value) >>

Type: C<String>

Output only. Human-readable description of why the BackupPlan is in the
current rpo_risk_level and action items if any.

=item * C<< $msg->backup_channel() >> / C<< $msg->backup_channel($value) >>

Type: C<String>

Output only. The fully qualified name of the BackupChannel to be used to
create a backup. This field is set only if the cluster being backed up is
in a different project.
`projects/*/locations/*/backupChannels/*`

=item * C<< $msg->last_successful_backup_time() >> / C<< $msg->last_successful_backup_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Completion time of the last successful Backup. This is sourced
from a successful Backup's complete_time field. This field is added to
maintain consistency with BackupPlanBinding to display last successful
backup time.

=back

=head3 Enum: BackupPlan::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CLUSTER_PENDING> => C<1>

=item * C<PROVISIONING> => C<2>

=item * C<READY> => C<3>

=item * C<FAILED> => C<4>

=item * C<DEACTIVATED> => C<5>

=item * C<DELETING> => C<6>

=back

=head2 Google::Cloud::Gkebackup::V1::BackupPlan::RpoConfig

Defines RPO scheduling configuration for automatically creating
Backups via this BackupPlan.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target_rpo_minutes() >> / C<< $msg->target_rpo_minutes($value) >>

Type: C<Int32>

Required. Defines the target RPO for the BackupPlan in minutes, which means
the target maximum data loss in time that is acceptable for this
BackupPlan. This must be at least 60, i.e., 1 hour, and at most 86400,
i.e., 60 days.

=item * C<< $msg->exclusion_windows() >> / C<< $msg->exclusion_windows($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow>)

Optional. User specified time windows during which backup can NOT happen
for this BackupPlan - backups should start and finish outside of any given
exclusion window. Note: backup jobs will be scheduled to start and
finish outside the duration of the window as much as possible, but
running jobs will not get canceled when it runs into the window.
All the time and date values in exclusion_windows entry in the API are in
UTC.
We only allow <=1 recurrence (daily or weekly) exclusion window for a
BackupPlan while no restriction on number of single occurrence
windows.

=back

=head2 Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow

Defines a time window during which no backup should
happen. All time and date are in UTC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Type::Timeofday::TimeOfDay>)

Required. Specifies the start time of the window using time of the day in
UTC.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. Specifies duration of the window.
Duration must be >= 5 minutes and < (target RPO - 20 minutes).
Additional restrictions based on the recurrence type to allow some time for
backup to happen:
- single_occurrence_date:  no restriction, but UI may warn about this when
duration >= target RPO
- daily window: duration < 24 hours
- weekly window:
  - days of week includes all seven days of a week: duration < 24 hours
  - all other weekly window: duration < 168 hours (i.e., 24 * 7 hours)

=item * C<< $msg->single_occurrence_date() >> / C<< $msg->single_occurrence_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

No recurrence. The exclusion window occurs only once and on this
date in UTC.

=item * C<< $msg->daily() >> / C<< $msg->daily($value) >>

Type: C<Bool>

The exclusion window occurs every day if set to "True".
Specifying this field to "False" is an error.

=item * C<< $msg->days_of_week() >> / C<< $msg->days_of_week($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow::DayOfWeekList>)

The exclusion window occurs on these days of each week in UTC.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::V1::BackupPlan::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
