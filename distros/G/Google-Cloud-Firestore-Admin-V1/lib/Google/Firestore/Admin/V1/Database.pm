package Google::Firestore::Admin::V1::Database;

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
    eval { require Google::Firestore::Admin::V1::RealtimeUpdates };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxL2RhdGFiYXNlLnByb3RvEhlnb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGjBnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxL3JlYWx0
aW1lX3VwZGF0ZXMucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byK+HQoIRGF0YWJhc2USEgoEbmFtZRgBIAEo
CVIEbmFtZRIVCgN1aWQYAyABKAlCA+BBA1IDdWlkEkAKC2NyZWF0ZV90aW1lGAUgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90
aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1l
EkAKC2RlbGV0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
UgpkZWxldGVUaW1lEh8KC2xvY2F0aW9uX2lkGAkgASgJUgpsb2NhdGlvbklkEkQKBHR5cGUY
CiABKA4yMC5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLkRhdGFiYXNlLkRhdGFiYXNlVHlw
ZVIEdHlwZRJeChBjb25jdXJyZW5jeV9tb2RlGA8gASgOMjMuZ29vZ2xlLmZpcmVzdG9yZS5h
ZG1pbi52MS5EYXRhYmFzZS5Db25jdXJyZW5jeU1vZGVSD2NvbmN1cnJlbmN5TW9kZRJYChh2
ZXJzaW9uX3JldGVudGlvbl9wZXJpb2QYESABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRp
b25CA+BBA1IWdmVyc2lvblJldGVudGlvblBlcmlvZBJTChVlYXJsaWVzdF92ZXJzaW9uX3Rp
bWUYEiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSE2VhcmxpZXN0VmVy
c2lvblRpbWUSiwEKIXBvaW50X2luX3RpbWVfcmVjb3ZlcnlfZW5hYmxlbWVudBgVIAEoDjJB
Lmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEuRGF0YWJhc2UuUG9pbnRJblRpbWVSZWNvdmVy
eUVuYWJsZW1lbnRSHXBvaW50SW5UaW1lUmVjb3ZlcnlFbmFibGVtZW50EnsKG2FwcF9lbmdp
bmVfaW50ZWdyYXRpb25fbW9kZRgTIAEoDjI8Lmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEu
RGF0YWJhc2UuQXBwRW5naW5lSW50ZWdyYXRpb25Nb2RlUhhhcHBFbmdpbmVJbnRlZ3JhdGlv
bk1vZGUSIgoKa2V5X3ByZWZpeBgUIAEoCUID4EEDUglrZXlQcmVmaXgScQoXZGVsZXRlX3By
b3RlY3Rpb25fc3RhdGUYFiABKA4yOS5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLkRhdGFi
YXNlLkRlbGV0ZVByb3RlY3Rpb25TdGF0ZVIVZGVsZXRlUHJvdGVjdGlvblN0YXRlElQKC2Nt
ZWtfY29uZmlnGBcgASgLMi4uZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MS5EYXRhYmFzZS5D
bWVrQ29uZmlnQgPgQQFSCmNtZWtDb25maWcSJAoLcHJldmlvdXNfaWQYGSABKAlCA+BBA1IK
cHJldmlvdXNJZBJUCgtzb3VyY2VfaW5mbxgaIAEoCzIuLmdvb2dsZS5maXJlc3RvcmUuYWRt
aW4udjEuRGF0YWJhc2UuU291cmNlSW5mb0ID4EEDUgpzb3VyY2VJbmZvEkwKBHRhZ3MYHSAD
KAsyLS5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLkRhdGFiYXNlLlRhZ3NFbnRyeUIJ4EEE
4EEF4EEBUgR0YWdzEiUKCWZyZWVfdGllchgeIAEoCEID4EEDSABSCGZyZWVUaWVyiAEBEhIK
BGV0YWcYYyABKAlSBGV0YWcSYwoQZGF0YWJhc2VfZWRpdGlvbhgcIAEoDjIzLmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjEuRGF0YWJhc2UuRGF0YWJhc2VFZGl0aW9uQgPgQQVSD2RhdGFi
YXNlRWRpdGlvbhJnChVyZWFsdGltZV91cGRhdGVzX21vZGUYHyABKA4yLi5nb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxLlJlYWx0aW1lVXBkYXRlc01vZGVCA+BBBVITcmVhbHRpbWVVcGRh
dGVzTW9kZRJ0ChpmaXJlc3RvcmVfZGF0YV9hY2Nlc3NfbW9kZRghIAEoDjIyLmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjEuRGF0YWJhc2UuRGF0YUFjY2Vzc01vZGVCA+BBAVIXZmlyZXN0
b3JlRGF0YUFjY2Vzc01vZGUShQEKI21vbmdvZGJfY29tcGF0aWJsZV9kYXRhX2FjY2Vzc19t
b2RlGCIgASgOMjIuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MS5EYXRhYmFzZS5EYXRhQWNj
ZXNzTW9kZUID4EEBUh9tb25nb2RiQ29tcGF0aWJsZURhdGFBY2Nlc3NNb2RlGmYKCkNtZWtD
b25maWcSJQoMa21zX2tleV9uYW1lGAEgASgJQgPgQQJSCmttc0tleU5hbWUSMQoSYWN0aXZl
X2tleV92ZXJzaW9uGAIgAygJQgPgQQNSEGFjdGl2ZUtleVZlcnNpb24aggIKClNvdXJjZUlu
Zm8SVQoGYmFja3VwGAEgASgLMjsuZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MS5EYXRhYmFz
ZS5Tb3VyY2VJbmZvLkJhY2t1cFNvdXJjZUgAUgZiYWNrdXASRQoJb3BlcmF0aW9uGAMgASgJ
Qif6QSQKImZpcmVzdG9yZS5nb29nbGVhcGlzLmNvbS9PcGVyYXRpb25SCW9wZXJhdGlvbhpM
CgxCYWNrdXBTb3VyY2USPAoGYmFja3VwGAEgASgJQiT6QSEKH2ZpcmVzdG9yZS5nb29nbGVh
cGlzLmNvbS9CYWNrdXBSBmJhY2t1cEIICgZzb3VyY2Ua4AQKEEVuY3J5cHRpb25Db25maWcS
kQEKGWdvb2dsZV9kZWZhdWx0X2VuY3J5cHRpb24YASABKAsyUy5nb29nbGUuZmlyZXN0b3Jl
LmFkbWluLnYxLkRhdGFiYXNlLkVuY3J5cHRpb25Db25maWcuR29vZ2xlRGVmYXVsdEVuY3J5
cHRpb25PcHRpb25zSABSF2dvb2dsZURlZmF1bHRFbmNyeXB0aW9uEoIBChV1c2Vfc291cmNl
X2VuY3J5cHRpb24YAiABKAsyTC5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLkRhdGFiYXNl
LkVuY3J5cHRpb25Db25maWcuU291cmNlRW5jcnlwdGlvbk9wdGlvbnNIAFITdXNlU291cmNl
RW5jcnlwdGlvbhKXAQobY3VzdG9tZXJfbWFuYWdlZF9lbmNyeXB0aW9uGAMgASgLMlUuZ29v
Z2xlLmZpcmVzdG9yZS5hZG1pbi52MS5EYXRhYmFzZS5FbmNyeXB0aW9uQ29uZmlnLkN1c3Rv
bWVyTWFuYWdlZEVuY3J5cHRpb25PcHRpb25zSABSGWN1c3RvbWVyTWFuYWdlZEVuY3J5cHRp
b24aIAoeR29vZ2xlRGVmYXVsdEVuY3J5cHRpb25PcHRpb25zGhkKF1NvdXJjZUVuY3J5cHRp
b25PcHRpb25zGkkKIEN1c3RvbWVyTWFuYWdlZEVuY3J5cHRpb25PcHRpb25zEiUKDGttc19r
ZXlfbmFtZRgBIAEoCUID4EECUgprbXNLZXlOYW1lQhEKD2VuY3J5cHRpb25fdHlwZRo3CglU
YWdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJX
CgxEYXRhYmFzZVR5cGUSHQoZREFUQUJBU0VfVFlQRV9VTlNQRUNJRklFRBAAEhQKEEZJUkVT
VE9SRV9OQVRJVkUQARISCg5EQVRBU1RPUkVfTU9ERRACIncKD0NvbmN1cnJlbmN5TW9kZRIg
ChxDT05DVVJSRU5DWV9NT0RFX1VOU1BFQ0lGSUVEEAASDgoKT1BUSU1JU1RJQxABEg8KC1BF
U1NJTUlTVElDEAISIQodT1BUSU1JU1RJQ19XSVRIX0VOVElUWV9HUk9VUFMQAyKbAQodUG9p
bnRJblRpbWVSZWNvdmVyeUVuYWJsZW1lbnQSMQotUE9JTlRfSU5fVElNRV9SRUNPVkVSWV9F
TkFCTEVNRU5UX1VOU1BFQ0lGSUVEEAASIgoeUE9JTlRfSU5fVElNRV9SRUNPVkVSWV9FTkFC
TEVEEAESIwofUE9JTlRfSU5fVElNRV9SRUNPVkVSWV9ESVNBQkxFRBACImIKGEFwcEVuZ2lu
ZUludGVncmF0aW9uTW9kZRIrCidBUFBfRU5HSU5FX0lOVEVHUkFUSU9OX01PREVfVU5TUEVD
SUZJRUQQABILCgdFTkFCTEVEEAESDAoIRElTQUJMRUQQAiJ/ChVEZWxldGVQcm90ZWN0aW9u
U3RhdGUSJwojREVMRVRFX1BST1RFQ1RJT05fU1RBVEVfVU5TUEVDSUZJRUQQABIeChpERUxF
VEVfUFJPVEVDVElPTl9ESVNBQkxFRBABEh0KGURFTEVURV9QUk9URUNUSU9OX0VOQUJMRUQQ
AiJRCg9EYXRhYmFzZUVkaXRpb24SIAocREFUQUJBU0VfRURJVElPTl9VTlNQRUNJRklFRBAA
EgwKCFNUQU5EQVJEEAESDgoKRU5URVJQUklTRRACIm8KDkRhdGFBY2Nlc3NNb2RlEiAKHERB
VEFfQUNDRVNTX01PREVfVU5TUEVDSUZJRUQQABIcChhEQVRBX0FDQ0VTU19NT0RFX0VOQUJM
RUQQARIdChlEQVRBX0FDQ0VTU19NT0RFX0RJU0FCTEVEEAI6UupBTwohZmlyZXN0b3JlLmdv
b2dsZWFwaXMuY29tL0RhdGFiYXNlEidwcm9qZWN0cy97cHJvamVjdH0vZGF0YWJhc2VzL3tk
YXRhYmFzZX1SAQFCDAoKX2ZyZWVfdGllckLDAgodY29tLmdvb2dsZS5maXJlc3RvcmUuYWRt
aW4udjFCDURhdGFiYXNlUHJvdG9QAVo5Y2xvdWQuZ29vZ2xlLmNvbS9nby9maXJlc3RvcmUv
YXBpdjEvYWRtaW4vYWRtaW5wYjthZG1pbnBiogIER0NGU6oCH0dvb2dsZS5DbG91ZC5GaXJl
c3RvcmUuQWRtaW4uVjHKAh9Hb29nbGVcQ2xvdWRcRmlyZXN0b3JlXEFkbWluXFYx6gIjR29v
Z2xlOjpDbG91ZDo6RmlyZXN0b3JlOjpBZG1pbjo6VjHqQWQKImZpcmVzdG9yZS5nb29nbGVh
cGlzLmNvbS9PcGVyYXRpb24SPnByb2plY3RzL3twcm9qZWN0fS9kYXRhYmFzZXMve2RhdGFi
YXNlfS9vcGVyYXRpb25zL3tvcGVyYXRpb259SpBzCgcSBQ4AkgMBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJ
CgIDAhIDFAA6CgkKAgMDEgMVACgKCQoCAwQSAxYAKQoICgEIEgMYADwKCQoCCCUSAxgAPAoI
CgEIEgMZAFAKCQoCCAsSAxkAUAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC4KCQoC
CAgSAxsALgoICgEIEgMcADYKCQoCCAESAxwANgoICgEIEgMdACIKCQoCCCQSAx0AIgoICgEI
EgMeAD0KCQoCCCkSAx4APQoICgEIEgMfADwKCQoCCC0SAx8APAoJCgEIEgQgACMCCgwKBAid
CAASBCAAIwIKKgoCBAASBSYAkgMBGh0gQSBDbG91ZCBGaXJlc3RvcmUgRGF0YWJhc2UuCgoK
CgMEAAESAyYIEAoLCgMEAAcSBCcCKwQKDQoFBAAHnQgSBCcCKwQKzgEKBAQABAASBDICOwMa
vwEgVGhlIHR5cGUgb2YgdGhlIGRhdGFiYXNlLgogU2VlIGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9kYXRhc3RvcmUvZG9jcy9maXJlc3RvcmUtb3ItZGF0YXN0b3JlIGZvcgogaW5mb3Jt
YXRpb24gYWJvdXQgaG93IHRvIGNob29zZS4KCiBNb2RlIGNoYW5nZXMgYXJlIG9ubHkgYWxs
b3dlZCBpZiB0aGUgZGF0YWJhc2UgaXMgZW1wdHkuCgoMCgUEAAQAARIDMgcTChoKBgQABAAC
ABIDNAQiGgsgTm90IHVzZWQuCgoOCgcEAAQAAgABEgM0BB0KDgoHBAAEAAIAAhIDNCAhCiYK
BgQABAACARIDNwQZGhcgRmlyZXN0b3JlIE5hdGl2ZSBNb2RlCgoOCgcEAAQAAgEBEgM3BBQK
DgoHBAAEAAIBAhIDNxcYCi0KBgQABAACAhIDOgQXGh4gRmlyZXN0b3JlIGluIERhdGFzdG9y
ZSBNb2RlLgoKDgoHBAAEAAICARIDOgQSCg4KBwQABAACAgISAzoVFgpGCgQEAAQBEgQ+AlgD
GjggVGhlIHR5cGUgb2YgY29uY3VycmVuY3kgY29udHJvbCBtb2RlIGZvciB0cmFuc2FjdGlv
bnMuCgoMCgUEAAQBARIDPgcWChoKBgQABAECABIDQAQlGgsgTm90IHVzZWQuCgoOCgcEAAQB
AgABEgNABCAKDgoHBAAEAQIAAhIDQCMkCsgBCgYEAAQBAgESA0cEExq4ASBVc2Ugb3B0aW1p
c3RpYyBjb25jdXJyZW5jeSBjb250cm9sIGJ5IGRlZmF1bHQuIFRoaXMgbW9kZSBpcyBhdmFp
bGFibGUKIGZvciBDbG91ZCBGaXJlc3RvcmUgZGF0YWJhc2VzLgoKIFRoaXMgaXMgdGhlIGRl
ZmF1bHQgc2V0dGluZyBmb3IgQ2xvdWQgRmlyZXN0b3JlIEVudGVycHJpc2UgRWRpdGlvbgog
ZGF0YWJhc2VzLgoKDgoHBAAEAQIBARIDRwQOCg4KBwQABAECAQISA0cREgrHAQoGBAAEAQIC
EgNOBBQatwEgVXNlIHBlc3NpbWlzdGljIGNvbmN1cnJlbmN5IGNvbnRyb2wgYnkgZGVmYXVs
dC4gVGhpcyBtb2RlIGlzIGF2YWlsYWJsZQogZm9yIENsb3VkIEZpcmVzdG9yZSBkYXRhYmFz
ZXMuCgogVGhpcyBpcyB0aGUgZGVmYXVsdCBzZXR0aW5nIGZvciBDbG91ZCBGaXJlc3RvcmUg
U3RhbmRhcmQgRWRpdGlvbgogZGF0YWJhc2VzLgoKDgoHBAAEAQICARIDTgQPCg4KBwQABAEC
AgISA04SEwq+AgoGBAAEAQIDEgNXBCYargIgVXNlIG9wdGltaXN0aWMgY29uY3VycmVuY3kg
Y29udHJvbCB3aXRoIGVudGl0eSBncm91cHMgYnkgZGVmYXVsdC4KCiBUaGlzIG1vZGUgaXMg
ZW5hYmxlZCBmb3Igc29tZSBkYXRhYmFzZXMgdGhhdCB3ZXJlIGF1dG9tYXRpY2FsbHkgdXBn
cmFkZWQKIGZyb20gQ2xvdWQgRGF0YXN0b3JlIHRvIENsb3VkIEZpcmVzdG9yZSB3aXRoIERh
dGFzdG9yZSBNb2RlLgoKIEl0IGlzIG5vdCByZWNvbW1lbmRlZCBmb3IgYW55IG5ldyBkYXRh
YmFzZXMsIGFuZCBub3Qgc3VwcG9ydGVkIGZvcgogRmlyZXN0b3JlIE5hdGl2ZSBkYXRhYmFz
ZXMuCgoOCgcEAAQBAgMBEgNXBCEKDgoHBAAEAQIDAhIDVyQlCjoKBAQABAISBFsCbAMaLCBQ
b2ludCBJbiBUaW1lIFJlY292ZXJ5IGZlYXR1cmUgZW5hYmxlbWVudC4KCgwKBQQABAIBEgNb
ByQKGgoGBAAEAgIAEgNdBDYaCyBOb3QgdXNlZC4KCg4KBwQABAICAAESA10EMQoOCgcEAAQC
AgACEgNdNDUKyAIKBgQABAICARIDZwQnGrgCIFJlYWRzIGFyZSBzdXBwb3J0ZWQgb24gc2Vs
ZWN0ZWQgdmVyc2lvbnMgb2YgdGhlIGRhdGEgZnJvbSB3aXRoaW4gdGhlIHBhc3QKIDcgZGF5
czoKCiAqIFJlYWRzIGFnYWluc3QgYW55IHRpbWVzdGFtcCB3aXRoaW4gdGhlIHBhc3QgaG91
cgogKiBSZWFkcyBhZ2FpbnN0IDEtbWludXRlIHNuYXBzaG90cyBiZXlvbmQgMSBob3VyIGFu
ZCB3aXRoaW4gNyBkYXlzCgogYHZlcnNpb25fcmV0ZW50aW9uX3BlcmlvZGAgYW5kIGBlYXJs
aWVzdF92ZXJzaW9uX3RpbWVgIGNhbiBiZQogdXNlZCB0byBkZXRlcm1pbmUgdGhlIHN1cHBv
cnRlZCB2ZXJzaW9ucy4KCg4KBwQABAICAQESA2cEIgoOCgcEAAQCAgECEgNnJSYKXQoGBAAE
AgICEgNrBCgaTiBSZWFkcyBhcmUgc3VwcG9ydGVkIG9uIGFueSB2ZXJzaW9uIG9mIHRoZSBk
YXRhIGZyb20gd2l0aGluIHRoZSBwYXN0IDEKIGhvdXIuCgoOCgcEAAQCAgIBEgNrBCMKDgoH
BAAEAgICAhIDayYnCjgKBAQABAMSBG8CfgMaKiBUaGUgdHlwZSBvZiBBcHAgRW5naW5lIGlu
dGVncmF0aW9uIG1vZGUuCgoMCgUEAAQDARIDbwcfChoKBgQABAMCABIDcQQwGgsgTm90IHVz
ZWQuCgoOCgcEAAQDAgABEgNxBCsKDgoHBAAEAwIAAhIDcS4vCvUBCgYEAAQDAgESA3cEEBrl
ASBJZiBhbiBBcHAgRW5naW5lIGFwcGxpY2F0aW9uIGV4aXN0cyBpbiB0aGUgc2FtZSByZWdp
b24gYXMgdGhpcyBkYXRhYmFzZSwKIEFwcCBFbmdpbmUgY29uZmlndXJhdGlvbiB3aWxsIGlt
cGFjdCB0aGlzIGRhdGFiYXNlLiBUaGlzIGluY2x1ZGVzCiBkaXNhYmxpbmcgb2YgdGhlIGFw
cGxpY2F0aW9uICYgZGF0YWJhc2UsIGFzIHdlbGwgYXMgZGlzYWJsaW5nIHdyaXRlcyB0bwog
dGhlIGRhdGFiYXNlLgoKDgoHBAAEAwIBARIDdwQLCg4KBwQABAMCAQISA3cODwqqAQoGBAAE
AwICEgN9BBEamgEgQXBwIEVuZ2luZSBoYXMgbm8gZWZmZWN0IG9uIHRoZSBhYmlsaXR5IG9m
IHRoaXMgZGF0YWJhc2UgdG8gc2VydmUKIHJlcXVlc3RzLgoKIFRoaXMgaXMgdGhlIGRlZmF1
bHQgc2V0dGluZyBmb3IgZGF0YWJhc2VzIGNyZWF0ZWQgd2l0aCB0aGUgRmlyZXN0b3JlIEFQ
SS4KCg4KBwQABAMCAgESA30EDAoOCgcEAAQDAgICEgN9DxAKPgoEBAAEBBIGgQECigEDGi4g
VGhlIGRlbGV0ZSBwcm90ZWN0aW9uIHN0YXRlIG9mIHRoZSBkYXRhYmFzZS4KCg0KBQQABAQB
EgSBAQccCkwKBgQABAQCABIEgwEELBo8IFRoZSBkZWZhdWx0IHZhbHVlLiBEZWxldGUgcHJv
dGVjdGlvbiB0eXBlIGlzIG5vdCBzcGVjaWZpZWQKCg8KBwQABAQCAAESBIMBBCcKDwoHBAAE
BAIAAhIEgwEqKwovCgYEAAQEAgESBIYBBCMaHyBEZWxldGUgcHJvdGVjdGlvbiBpcyBkaXNh
YmxlZAoKDwoHBAAEBAIBARIEhgEEHgoPCgcEAAQEAgECEgSGASEiCi4KBgQABAQCAhIEiQEE
IhoeIERlbGV0ZSBwcm90ZWN0aW9uIGlzIGVuYWJsZWQKCg8KBwQABAQCAgESBIkBBB0KDwoH
BAAEBAICAhIEiQEgIQq1AQoEBAADABIGjwECpQEDGqQBIFRoZSBDTUVLIChDdXN0b21lciBN
YW5hZ2VkIEVuY3J5cHRpb24gS2V5KSBjb25maWd1cmF0aW9uIGZvciBhIEZpcmVzdG9yZQog
ZGF0YWJhc2UuIElmIG5vdCBwcmVzZW50LCB0aGUgZGF0YWJhc2UgaXMgc2VjdXJlZCBieSB0
aGUgZGVmYXVsdCBHb29nbGUKIGVuY3J5cHRpb24ga2V5LgoKDQoFBAADAAESBI8BChQKygMK
BgQAAwACABIEmgEERRq5AyBSZXF1aXJlZC4gT25seSBrZXlzIGluIHRoZSBzYW1lIGxvY2F0
aW9uIGFzIHRoaXMgZGF0YWJhc2UgYXJlIGFsbG93ZWQgdG8KIGJlIHVzZWQgZm9yIGVuY3J5
cHRpb24uCgogRm9yIEZpcmVzdG9yZSdzIG5hbTUgbXVsdGktcmVnaW9uLCB0aGlzIGNvcnJl
c3BvbmRzIHRvIENsb3VkIEtNUwogbXVsdGktcmVnaW9uIHVzLiBGb3IgRmlyZXN0b3JlJ3Mg
ZXVyMyBtdWx0aS1yZWdpb24sIHRoaXMgY29ycmVzcG9uZHMgdG8KIENsb3VkIEtNUyBtdWx0
aS1yZWdpb24gZXVyb3BlLiBTZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9rbXMvZG9j
cy9sb2NhdGlvbnMuCgogVGhlIGV4cGVjdGVkIGZvcm1hdCBpcwogYHByb2plY3RzL3twcm9q
ZWN0X2lkfS9sb2NhdGlvbnMve2ttc19sb2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nfS9j
cnlwdG9LZXlzL3tjcnlwdG9fa2V5fWAuCgoPCgcEAAMAAgAFEgSaAQQKCg8KBwQAAwACAAES
BJoBCxcKDwoHBAADAAIAAxIEmgEaGwoPCgcEAAMAAgAIEgSaARxEChIKCgQAAwACAAicCAAS
BJoBHUMKlgMKBgQAAwACARIGowEEpAE0GoMDIE91dHB1dCBvbmx5LiBDdXJyZW50bHkgaW4t
dXNlIFtLTVMga2V5CiB2ZXJzaW9uc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2ttcy9k
b2NzL3Jlc291cmNlLWhpZXJhcmNoeSNrZXlfdmVyc2lvbnMpLgogRHVyaW5nIFtrZXkgcm90
YXRpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9rbXMvZG9jcy9rZXktcm90YXRpb24p
LAogdGhlcmUgY2FuIGJlIG11bHRpcGxlIGluLXVzZSBrZXkgdmVyc2lvbnMuCgogVGhlIGV4
cGVjdGVkIGZvcm1hdCBpcwogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2tt
c19sb2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5
fS9jcnlwdG9LZXlWZXJzaW9ucy97a2V5X3ZlcnNpb259YC4KCg8KBwQAAwACAQQSBKMBBAwK
DwoHBAADAAIBBRIEowENEwoPCgcEAAMAAgEBEgSjARQmCg8KBwQAAwACAQMSBKMBKSoKDwoH
BAADAAIBCBIEpAEIMwoSCgoEAAMAAgEInAgAEgSkAQkyCkQKBAQAAwESBqgBAsABAxo0IElu
Zm9ybWF0aW9uIGFib3V0IHRoZSBwcm92ZW5hbmNlIG9mIHRoaXMgZGF0YWJhc2UuCgoNCgUE
AAMBARIEqAEKFApTCgYEAAMBAwASBqoBBLEBBRpBIEluZm9ybWF0aW9uIGFib3V0IGEgYmFj
a3VwIHRoYXQgd2FzIHVzZWQgdG8gcmVzdG9yZSBhIGRhdGFiYXNlLgoKDwoHBAADAQMAARIE
qgEMGAqkAQoIBAADAQMAAgASBq4BBrABCRqPASBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
YmFja3VwIHRoYXQgd2FzIHVzZWQgdG8gcmVzdG9yZSB0aGlzCiBkYXRhYmFzZS4gRm9ybWF0
OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBzL3ti
YWNrdXB9YC4KChEKCQQAAwEDAAIABRIErgEGDAoRCgkEAAMBAwACAAESBK4BDRMKEQoJBAAD
AQMAAgADEgSuARYXChMKCQQAAwEDAAIACBIGrgEYsAEIChUKCwQAAwEDAAIACJ8IEgauARmw
AQcKQwoGBAADAQgAEga0AQS4AQUaMSBUaGUgc291cmNlIGZyb20gd2hpY2ggdGhpcyBkYXRh
YmFzZSBpcyBkZXJpdmVkLgoKDwoHBAADAQgAARIEtAEKEApoCgYEAAMBAgASBLcBBh4aWCBJ
ZiBzZXQsIHRoaXMgZGF0YWJhc2Ugd2FzIHJlc3RvcmVkIGZyb20gdGhlIHNwZWNpZmllZCBi
YWNrdXAgKG9yIGEKIHNuYXBzaG90IHRoZXJlb2YpLgoKDwoHBAADAQIABhIEtwEGEgoPCgcE
AAMBAgABEgS3ARMZCg8KBwQAAwECAAMSBLcBHB0KxAEKBgQAAwECARIGvQEEvwEHGrEBIFRo
ZSBhc3NvY2lhdGVkIGxvbmctcnVubmluZyBvcGVyYXRpb24uIFRoaXMgZmllbGQgbWF5IG5v
dCBiZSBzZXQgYWZ0ZXIKIHRoZSBvcGVyYXRpb24gaGFzIGNvbXBsZXRlZC4gRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9kYXRhYmFzZXMve2RhdGFiYXNlfS9vcGVyYXRpb25zL3tv
cGVyYXRpb259YC4KCg8KBwQAAwECAQUSBL0BBAoKDwoHBAADAQIBARIEvQELFAoPCgcEAAMB
AgEDEgS9ARcYChEKBwQAAwECAQgSBr0BGb8BBgoTCgkEAAMBAgEInwgSBr0BGr8BBQrjAQoE
BAADAhIGxwEC6gEDGtIBIEVuY3J5cHRpb24gY29uZmlndXJhdGlvbiBmb3IgYSBuZXcgZGF0
YWJhc2UgYmVpbmcgY3JlYXRlZCBmcm9tIGFub3RoZXIKIHNvdXJjZS4KCiBUaGUgc291cmNl
IGNvdWxkIGJlIGEgW0JhY2t1cF1bZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MS5CYWNrdXBd
IG9yIGEKIFtQaXRyU25hcHNob3RdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjEuUGl0clNu
YXBzaG90XS4KCg0KBQQAAwIBEgTHAQoaClAKBgQAAwIDABIEyQEELRpAIFRoZSBjb25maWd1
cmF0aW9uIG9wdGlvbnMgZm9yIHVzaW5nIEdvb2dsZSBkZWZhdWx0IGVuY3J5cHRpb24uCgoP
CgcEAAMCAwABEgTJAQwqCmAKBgQAAwIDARIEzQEEJhpQIFRoZSBjb25maWd1cmF0aW9uIG9w
dGlvbnMgZm9yIHVzaW5nIHRoZSBzYW1lIGVuY3J5cHRpb24gbWV0aG9kIGFzIHRoZQogc291
cmNlLgoKDwoHBAADAgMBARIEzQEMIwprCgYEAAMCAwISBtEBBN0BBRpZIFRoZSBjb25maWd1
cmF0aW9uIG9wdGlvbnMgZm9yIHVzaW5nIENNRUsgKEN1c3RvbWVyIE1hbmFnZWQgRW5jcnlw
dGlvbgogS2V5KSBlbmNyeXB0aW9uLgoKDwoHBAADAgMCARIE0QEMLArLAwoIBAADAgMCAgAS
BNwBBkcauAMgUmVxdWlyZWQuIE9ubHkga2V5cyBpbiB0aGUgc2FtZSBsb2NhdGlvbiBhcyB0
aGUgZGF0YWJhc2UgYXJlIGFsbG93ZWQgdG8KIGJlIHVzZWQgZm9yIGVuY3J5cHRpb24uCgog
Rm9yIEZpcmVzdG9yZSdzIG5hbTUgbXVsdGktcmVnaW9uLCB0aGlzIGNvcnJlc3BvbmRzIHRv
IENsb3VkIEtNUwogbXVsdGktcmVnaW9uIHVzLiBGb3IgRmlyZXN0b3JlJ3MgZXVyMyBtdWx0
aS1yZWdpb24sIHRoaXMgY29ycmVzcG9uZHMgdG8KIENsb3VkIEtNUyBtdWx0aS1yZWdpb24g
ZXVyb3BlLiBTZWUKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9rbXMvZG9jcy9sb2NhdGlv
bnMuCgogVGhlIGV4cGVjdGVkIGZvcm1hdCBpcwogYHByb2plY3RzL3twcm9qZWN0X2lkfS9s
b2NhdGlvbnMve2ttc19sb2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlz
L3tjcnlwdG9fa2V5fWAuCgoRCgkEAAMCAwICAAUSBNwBBgwKEQoJBAADAgMCAgABEgTcAQ0Z
ChEKCQQAAwIDAgIAAxIE3AEcHQoRCgkEAAMCAwICAAgSBNwBHkYKFAoMBAADAgMCAgAInAgA
EgTcAR9FCjsKBgQAAwIIABIG4AEE6QEFGikgVGhlIG1ldGhvZCBmb3IgZW5jcnlwdGluZyB0
aGUgZGF0YWJhc2UuCgoPCgcEAAMCCAABEgTgAQoZCjAKBgQAAwICABIE4gEGQxogIFVzZSBH
b29nbGUgZGVmYXVsdCBlbmNyeXB0aW9uLgoKDwoHBAADAgIABhIE4gEGJAoPCgcEAAMCAgAB
EgTiASU+Cg8KBwQAAwICAAMSBOIBQUIKWAoGBAADAgIBEgTlAQY4GkggVGhlIGRhdGFiYXNl
IHdpbGwgdXNlIHRoZSBzYW1lIGVuY3J5cHRpb24gY29uZmlndXJhdGlvbiBhcyB0aGUgc291
cmNlLgoKDwoHBAADAgIBBhIE5QEGHQoPCgcEAAMCAgEBEgTlAR4zCg8KBwQAAwICAQMSBOUB
NjcKTQoGBAADAgICEgToAQZHGj0gVXNlIEN1c3RvbWVyIE1hbmFnZWQgRW5jcnlwdGlvbiBL
ZXlzIChDTUVLKSBmb3IgZW5jcnlwdGlvbi4KCg8KBwQAAwICAgYSBOgBBiYKDwoHBAADAgIC
ARIE6AEnQgoPCgcEAAMCAgIDEgToAUVGCi4KBAQABAUSBu0BAvgBAxoeIFRoZSBlZGl0aW9u
IG9mIHRoZSBkYXRhYmFzZS4KCg0KBQQABAUBEgTtAQcWChsKBgQABAUCABIE7wEEJRoLIE5v
dCB1c2VkLgoKDwoHBAAEBQIAARIE7wEEIAoPCgcEAAQFAgACEgTvASMkClMKBgQABAUCARIE
9AEEERpDIFN0YW5kYXJkIGVkaXRpb24uCgogVGhpcyBpcyB0aGUgZGVmYXVsdCBzZXR0aW5n
IGlmIG5vdCBzcGVjaWZpZWQuCgoPCgcEAAQFAgEBEgT0AQQMCg8KBwQABAUCAQISBPQBDxAK
JQoGBAAEBQICEgT3AQQTGhUgRW50ZXJwcmlzZSBlZGl0aW9uLgoKDwoHBAAEBQICARIE9wEE
DgoPCgcEAAQFAgICEgT3ARESCicKBAQABAYSBvsBAoQCAxoXIFRoZSBkYXRhIGFjY2VzcyBt
b2RlLgoKDQoFBAAEBgESBPsBBxUKGwoGBAAEBgIAEgT9AQQlGgsgTm90IFVzZWQuCgoPCgcE
AAQGAgABEgT9AQQgCg8KBwQABAYCAAISBP0BIyQKRAoGBAAEBgIBEgSAAgQhGjQgQWNjZXNz
aW5nIHRoZSBkYXRhYmFzZSB0aHJvdWdoIHRoZSBBUEkgaXMgYWxsb3dlZC4KCg8KBwQABAYC
AQESBIACBBwKDwoHBAAEBgIBAhIEgAIfIApHCgYEAAQGAgISBIMCBCIaNyBBY2Nlc3Npbmcg
dGhlIGRhdGFiYXNlIHRocm91Z2ggdGhlIEFQSSBpcyBkaXNhbGxvd2VkLgoKDwoHBAAEBgIC
ARIEgwIEHQoPCgcEAAQGAgICEgSDAiAhCmUKBAQAAgASBIgCAhIaVyBUaGUgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgRGF0YWJhc2UuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vZGF0
YWJhc2VzL3tkYXRhYmFzZX1gCgoNCgUEAAIABRIEiAICCAoNCgUEAAIAARIEiAIJDQoNCgUE
AAIAAxIEiAIQEQpKCgQEAAIBEgSLAgI9GjwgT3V0cHV0IG9ubHkuIFRoZSBzeXN0ZW0tZ2Vu
ZXJhdGVkIFVVSUQ0IGZvciB0aGlzIERhdGFiYXNlLgoKDQoFBAACAQUSBIsCAggKDQoFBAAC
AQESBIsCCQwKDQoFBAACAQMSBIsCDxAKDQoFBAACAQgSBIsCETwKEAoIBAACAQicCAASBIsC
EjsKjAEKBAQAAgISBo8CApACMhp8IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIGF0IHdo
aWNoIHRoaXMgZGF0YWJhc2Ugd2FzIGNyZWF0ZWQuIERhdGFiYXNlcwogY3JlYXRlZCBiZWZv
cmUgMjAxNiBkbyBub3QgcG9wdWxhdGUgY3JlYXRlX3RpbWUuCgoNCgUEAAICBhIEjwICGwoN
CgUEAAICARIEjwIcJwoNCgUEAAICAxIEjwIqKwoNCgUEAAICCBIEkAIGMQoQCggEAAICCJwI
ABIEkAIHMArCAQoEBAACAxIGlQIClgIyGrEBIE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1w
IGF0IHdoaWNoIHRoaXMgZGF0YWJhc2Ugd2FzIG1vc3QgcmVjZW50bHkKIHVwZGF0ZWQuIE5v
dGUgdGhpcyBvbmx5IGluY2x1ZGVzIHVwZGF0ZXMgdG8gdGhlIGRhdGFiYXNlIHJlc291cmNl
IGFuZCBub3QKIGRhdGEgY29udGFpbmVkIGJ5IHRoZSBkYXRhYmFzZS4KCg0KBQQAAgMGEgSV
AgIbCg0KBQQAAgMBEgSVAhwnCg0KBQQAAgMDEgSVAiorCg0KBQQAAgMIEgSWAgYxChAKCAQA
AgMInAgAEgSWAgcwCnwKBAQAAgQSBpoCApsCMhpsIE91dHB1dCBvbmx5LiBUaGUgdGltZXN0
YW1wIGF0IHdoaWNoIHRoaXMgZGF0YWJhc2Ugd2FzIGRlbGV0ZWQuIE9ubHkgc2V0IGlmCiB0
aGUgZGF0YWJhc2UgaGFzIGJlZW4gZGVsZXRlZC4KCg0KBQQAAgQGEgSaAgIbCg0KBQQAAgQB
EgSaAhwnCg0KBQQAAgQDEgSaAiorCg0KBQQAAgQIEgSbAgYxChAKCAQAAgQInAgAEgSbAgcw
CoMBCgQEAAIFEgSfAgIZGnUgVGhlIGxvY2F0aW9uIG9mIHRoZSBkYXRhYmFzZS4gQXZhaWxh
YmxlIGxvY2F0aW9ucyBhcmUgbGlzdGVkIGF0CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
ZmlyZXN0b3JlL2RvY3MvbG9jYXRpb25zLgoKDQoFBAACBQUSBJ8CAggKDQoFBAACBQESBJ8C
CRQKDQoFBAACBQMSBJ8CFxgKlAEKBAQAAgYSBKQCAhkahQEgVGhlIHR5cGUgb2YgdGhlIGRh
dGFiYXNlLgogU2VlIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kYXRhc3RvcmUvZG9jcy9m
aXJlc3RvcmUtb3ItZGF0YXN0b3JlIGZvcgogaW5mb3JtYXRpb24gYWJvdXQgaG93IHRvIGNo
b29zZS4KCg0KBQQAAgYGEgSkAgIOCg0KBQQAAgYBEgSkAg8TCg0KBQQAAgYDEgSkAhYYCusB
CgQEAAIHEgSrAgIoGtwBIFRoZSBjb25jdXJyZW5jeSBjb250cm9sIG1vZGUgdG8gdXNlIGZv
ciB0aGlzIGRhdGFiYXNlLgoKIElmIHVuc3BlY2lmaWVkIGluIGEgQ3JlYXRlRGF0YWJhc2Ug
cmVxdWVzdCwgdGhpcyB3aWxsIGRlZmF1bHQgYmFzZWQgb24gdGhlCiBkYXRhYmFzZSBlZGl0
aW9uOiBPcHRpbWlzdGljIGZvciBFbnRlcnByaXNlIGFuZCBQZXNzaW1pc3RpYyBmb3IgYWxs
IG90aGVyCiBkYXRhYmFzZXMuCgoNCgUEAAIHBhIEqwICEQoNCgUEAAIHARIEqwISIgoNCgUE
AAIHAxIEqwIlJwq/AwoEBAACCBIGtwICuAIyGq4DIE91dHB1dCBvbmx5LiBUaGUgcGVyaW9k
IGR1cmluZyB3aGljaCBwYXN0IHZlcnNpb25zIG9mIGRhdGEgYXJlIHJldGFpbmVkIGluCiB0
aGUgZGF0YWJhc2UuCgogQW55IFtyZWFkXVtnb29nbGUuZmlyZXN0b3JlLnYxLkdldERvY3Vt
ZW50UmVxdWVzdC5yZWFkX3RpbWVdCiBvciBbcXVlcnldW2dvb2dsZS5maXJlc3RvcmUudjEu
TGlzdERvY3VtZW50c1JlcXVlc3QucmVhZF90aW1lXSBjYW4gc3BlY2lmeQogYSBgcmVhZF90
aW1lYCB3aXRoaW4gdGhpcyB3aW5kb3csIGFuZCB3aWxsIHJlYWQgdGhlIHN0YXRlIG9mIHRo
ZSBkYXRhYmFzZQogYXQgdGhhdCB0aW1lLgoKIElmIHRoZSBQSVRSIGZlYXR1cmUgaXMgZW5h
YmxlZCwgdGhlIHJldGVudGlvbiBwZXJpb2QgaXMgNyBkYXlzLiBPdGhlcndpc2UsCiB0aGUg
cmV0ZW50aW9uIHBlcmlvZCBpcyAxIGhvdXIuCgoNCgUEAAIIBhIEtwICGgoNCgUEAAIIARIE
twIbMwoNCgUEAAIIAxIEtwI2OAoNCgUEAAIICBIEuAIGMQoQCggEAAIICJwIABIEuAIHMArc
AwoEBAACCRIGwgICwwIyGssDIE91dHB1dCBvbmx5LiBUaGUgZWFybGllc3QgdGltZXN0YW1w
IGF0IHdoaWNoIG9sZGVyIHZlcnNpb25zIG9mIHRoZSBkYXRhIGNhbgogYmUgcmVhZCBmcm9t
IHRoZSBkYXRhYmFzZS4gU2VlIFt2ZXJzaW9uX3JldGVudGlvbl9wZXJpb2RdIGFib3ZlOyB0
aGlzIGZpZWxkCiBpcyBwb3B1bGF0ZWQgd2l0aCBgbm93IC0gdmVyc2lvbl9yZXRlbnRpb25f
cGVyaW9kYC4KCiBUaGlzIHZhbHVlIGlzIGNvbnRpbnVvdXNseSB1cGRhdGVkLCBhbmQgYmVj
b21lcyBzdGFsZSB0aGUgbW9tZW50IGl0IGlzCiBxdWVyaWVkLiBJZiB5b3UgYXJlIHVzaW5n
IHRoaXMgdmFsdWUgdG8gcmVjb3ZlciBkYXRhLCBtYWtlIHN1cmUgdG8gYWNjb3VudAogZm9y
IHRoZSB0aW1lIGZyb20gdGhlIG1vbWVudCB3aGVuIHRoZSB2YWx1ZSBpcyBxdWVyaWVkIHRv
IHRoZSBtb21lbnQgd2hlbgogeW91IGluaXRpYXRlIHRoZSByZWNvdmVyeS4KCg0KBQQAAgkG
EgTCAgIbCg0KBQQAAgkBEgTCAhwxCg0KBQQAAgkDEgTCAjQ2Cg0KBQQAAgkIEgTDAgYxChAK
CAQAAgkInAgAEgTDAgcwCkQKBAQAAgoSBMYCAkcaNiBXaGV0aGVyIHRvIGVuYWJsZSB0aGUg
UElUUiBmZWF0dXJlIG9uIHRoaXMgZGF0YWJhc2UuCgoNCgUEAAIKBhIExgICHwoNCgUEAAIK
ARIExgIgQQoNCgUEAAIKAxIExgJERgpJCgQEAAILEgTJAgI8GjsgVGhlIEFwcCBFbmdpbmUg
aW50ZWdyYXRpb24gbW9kZSB0byB1c2UgZm9yIHRoaXMgZGF0YWJhc2UuCgoNCgUEAAILBhIE
yQICGgoNCgUEAAILARIEyQIbNgoNCgUEAAILAxIEyQI5OwqYAwoEBAACDBIE0gICRRqJAyBP
dXRwdXQgb25seS4gVGhlIGtleV9wcmVmaXggZm9yIHRoaXMgZGF0YWJhc2UuIFRoaXMga2V5
X3ByZWZpeCBpcyB1c2VkLCBpbgogY29tYmluYXRpb24gd2l0aCB0aGUgcHJvamVjdCBJRCAo
IjxrZXkgcHJlZml4Pn48cHJvamVjdCBpZD4iKSB0byBjb25zdHJ1Y3QKIHRoZSBhcHBsaWNh
dGlvbiBJRCB0aGF0IGlzIHJldHVybmVkIGZyb20gdGhlIENsb3VkIERhdGFzdG9yZSBBUElz
IGluIEdvb2dsZQogQXBwIEVuZ2luZSBmaXJzdCBnZW5lcmF0aW9uIHJ1bnRpbWVzLgoKIFRo
aXMgdmFsdWUgbWF5IGJlIGVtcHR5IGluIHdoaWNoIGNhc2UgdGhlIGFwcGlkIHRvIHVzZSBm
b3IgVVJMLWVuY29kZWQga2V5cwogaXMgdGhlIHByb2plY3RfaWQgKGVnOiBmb28gaW5zdGVh
ZCBvZiB2fmZvbykuCgoNCgUEAAIMBRIE0gICCAoNCgUEAAIMARIE0gIJEwoNCgUEAAIMAxIE
0gIWGAoNCgUEAAIMCBIE0gIZRAoQCggEAAIMCJwIABIE0gIaQwo8CgQEAAINEgTVAgI1Gi4g
U3RhdGUgb2YgZGVsZXRlIHByb3RlY3Rpb24gZm9yIHRoZSBkYXRhYmFzZS4KCg0KBQQAAg0G
EgTVAgIXCg0KBQQAAg0BEgTVAhgvCg0KBQQAAg0DEgTVAjI0Ck8KBAQAAg4SBNgCAkcaQSBP
cHRpb25hbC4gUHJlc2VuY2UgaW5kaWNhdGVzIENNRUsgaXMgZW5hYmxlZCBmb3IgdGhpcyBk
YXRhYmFzZS4KCg0KBQQAAg4GEgTYAgIMCg0KBQQAAg4BEgTYAg0YCg0KBQQAAg4DEgTYAhsd
Cg0KBQQAAg4IEgTYAh5GChAKCAQAAg4InAgAEgTYAh9FCnwKBAQAAg8SBNwCAkYabiBPdXRw
dXQgb25seS4gVGhlIGRhdGFiYXNlIHJlc291cmNlJ3MgcHJpb3IgZGF0YWJhc2UgSUQuIFRo
aXMgZmllbGQgaXMgb25seQogcG9wdWxhdGVkIGZvciBkZWxldGVkIGRhdGFiYXNlcy4KCg0K
BQQAAg8FEgTcAgIICg0KBQQAAg8BEgTcAgkUCg0KBQQAAg8DEgTcAhcZCg0KBQQAAg8IEgTc
AhpFChAKCAQAAg8InAgAEgTcAhtECk8KBAQAAhASBN8CAkoaQSBPdXRwdXQgb25seS4gSW5m
b3JtYXRpb24gYWJvdXQgdGhlIHByb3ZlbmFuY2Ugb2YgdGhpcyBkYXRhYmFzZS4KCg0KBQQA
AhAGEgTfAgIMCg0KBQQAAhABEgTfAg0YCg0KBQQAAhADEgTfAhsdCg0KBQQAAhAIEgTfAh5J
ChAKCAQAAhAInAgAEgTfAh9ICrcBCgQEAAIREgblAgLpAgQapgEgT3B0aW9uYWwuIElucHV0
IG9ubHkuIEltbXV0YWJsZS4gVGFnIGtleXMvdmFsdWVzIGRpcmVjdGx5IGJvdW5kIHRvIHRo
aXMKIHJlc291cmNlLiBGb3IgZXhhbXBsZToKICAgIjEyMy9lbnZpcm9ubWVudCI6ICJwcm9k
dWN0aW9uIiwKICAgIjEyMy9jb3N0Q2VudGVyIjogIm1hcmtldGluZyIKCg0KBQQAAhEGEgTl
AgIVCg0KBQQAAhEBEgTlAhYaCg0KBQQAAhEDEgTlAh0fCg8KBQQAAhEIEgblAiDpAgMKEAoI
BAACEQicCAASBOYCBCwKEAoIBAACEQicCAESBOcCBCsKEAoIBAACEQicCAISBOgCBCoKywQK
BAQAAhISBPYCAksavAQgT3V0cHV0IG9ubHkuIEJhY2tncm91bmQ6IEZyZWUgdGllciBpcyB0
aGUgYWJpbGl0eSBvZiBhIEZpcmVzdG9yZSBkYXRhYmFzZQogdG8gdXNlIGEgc21hbGwgYW1v
dW50IG9mIHJlc291cmNlcyBldmVyeSBkYXkgd2l0aG91dCBiZWluZyBjaGFyZ2VkLiBPbmNl
CiB1c2FnZSBleGNlZWRzIHRoZSBmcmVlIHRpZXIgbGltaXQgZnVydGhlciB1c2FnZSBpcyBj
aGFyZ2VkLgoKIFdoZXRoZXIgdGhpcyBkYXRhYmFzZSBjYW4gbWFrZSB1c2Ugb2YgdGhlIGZy
ZWUgdGllci4gT25seSBvbmUgZGF0YWJhc2UKIHBlciBwcm9qZWN0IGNhbiBiZSBlbGlnaWJs
ZSBmb3IgdGhlIGZyZWUgdGllci4KCiBUaGUgZmlyc3QgKG9yIG5leHQpIGRhdGFiYXNlIHRo
YXQgaXMgY3JlYXRlZCBpbiBhIHByb2plY3Qgd2l0aG91dCBhIGZyZWUKIHRpZXIgZGF0YWJh
c2Ugd2lsbCBiZSBtYXJrZWQgYXMgZWxpZ2libGUgZm9yIHRoZSBmcmVlIHRpZXIuIERhdGFi
YXNlcyB0aGF0CiBhcmUgY3JlYXRlZCB3aGlsZSB0aGVyZSBpcyBhIGZyZWUgdGllciBkYXRh
YmFzZSB3aWxsIG5vdCBiZSBlbGlnaWJsZSBmb3IKIHRoZSBmcmVlIHRpZXIuCgoNCgUEAAIS
BBIE9gICCgoNCgUEAAISBRIE9gILDwoNCgUEAAISARIE9gIQGQoNCgUEAAISAxIE9gIcHgoN
CgUEAAISCBIE9gIfSgoQCggEAAISCJwIABIE9gIgSQrMAQoEBAACExIE+wICExq9ASBUaGlz
IGNoZWNrc3VtIGlzIGNvbXB1dGVkIGJ5IHRoZSBzZXJ2ZXIgYmFzZWQgb24gdGhlIHZhbHVl
IG9mIG90aGVyCiBmaWVsZHMsIGFuZCBtYXkgYmUgc2VudCBvbiB1cGRhdGUgYW5kIGRlbGV0
ZSByZXF1ZXN0cyB0byBlbnN1cmUgdGhlCiBjbGllbnQgaGFzIGFuIHVwLXRvLWRhdGUgdmFs
dWUgYmVmb3JlIHByb2NlZWRpbmcuCgoNCgUEAAITBRIE+wICCAoNCgUEAAITARIE+wIJDQoN
CgUEAAITAxIE+wIQEgo5CgQEAAIUEgb+AgL/AjAaKSBJbW11dGFibGUuIFRoZSBlZGl0aW9u
IG9mIHRoZSBkYXRhYmFzZS4KCg0KBQQAAhQGEgT+AgIRCg0KBQQAAhQBEgT+AhIiCg0KBQQA
AhQDEgT+AiUnCg0KBQQAAhQIEgT/AgYvChAKCAQAAhQInAgAEgT/AgcuClgKBAQAAhUSBoID
AoMDMBpIIEltbXV0YWJsZS4gVGhlIGRlZmF1bHQgUmVhbHRpbWUgVXBkYXRlcyBtb2RlIHRv
IHVzZSBmb3IgdGhpcyBkYXRhYmFzZS4KCg0KBQQAAhUGEgSCAwIVCg0KBQQAAhUBEgSCAxYr
Cg0KBQQAAhUDEgSCAy4wCg0KBQQAAhUIEgSDAwYvChAKCAQAAhUInAgAEgSDAwcuCoACCgQE
AAIWEgaJAwKKAy8a7wEgT3B0aW9uYWwuIFRoZSBGaXJlc3RvcmUgQVBJIGRhdGEgYWNjZXNz
IG1vZGUgdG8gdXNlIGZvciB0aGlzIGRhdGFiYXNlLiBJZgogbm90IHNldCBvbiB3cml0ZToK
IC0gdGhlIGRlZmF1bHQgdmFsdWUgaXMgREFUQV9BQ0NFU1NfTU9ERV9ESVNBQkxFRCBmb3Ig
RW50ZXJwcmlzZSBFZGl0aW9uLgogLSB0aGUgZGVmYXVsdCB2YWx1ZSBpcyBEQVRBX0FDQ0VT
U19NT0RFX0VOQUJMRUQgZm9yIFN0YW5kYXJkIEVkaXRpb24uCgoNCgUEAAIWBhIEiQMCEAoN
CgUEAAIWARIEiQMRKwoNCgUEAAIWAxIEiQMuMAoNCgUEAAIWCBIEigMGLgoQCggEAAIWCJwI
ABIEigMHLQqEAgoEBAACFxIGkAMCkQMvGvMBIE9wdGlvbmFsLiBUaGUgTW9uZ29EQiBjb21w
YXRpYmxlIEFQSSBkYXRhIGFjY2VzcyBtb2RlIHRvIHVzZSBmb3IgdGhpcwogZGF0YWJhc2Uu
IElmIG5vdCBzZXQgb24gd3JpdGUsIHRoZSBkZWZhdWx0IHZhbHVlIGlzCiBEQVRBX0FDQ0VT
U19NT0RFX0VOQUJMRUQgZm9yIEVudGVycHJpc2UgRWRpdGlvbi4gVGhlIHZhbHVlIGlzIGFs
d2F5cwogREFUQV9BQ0NFU1NfTU9ERV9ESVNBQkxFRCBmb3IgU3RhbmRhcmQgRWRpdGlvbi4K
Cg0KBQQAAhcGEgSQAwIQCg0KBQQAAhcBEgSQAxE0Cg0KBQQAAhcDEgSQAzc5Cg0KBQQAAhcI
EgSRAwYuChAKCAQAAhcInAgAEgSRAwctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1::Database::Database ===
    # Fields for Database
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: location_id Type: 9 ()
    # Field: type Type: 14 (.google.firestore.admin.v1.Database.DatabaseType)
    # Field: concurrency_mode Type: 14 (.google.firestore.admin.v1.Database.ConcurrencyMode)
    # Field: version_retention_period Type: 11 (.google.protobuf.Duration)
    # Field: earliest_version_time Type: 11 (.google.protobuf.Timestamp)
    # Field: point_in_time_recovery_enablement Type: 14 (.google.firestore.admin.v1.Database.PointInTimeRecoveryEnablement)
    # Field: app_engine_integration_mode Type: 14 (.google.firestore.admin.v1.Database.AppEngineIntegrationMode)
    # Field: key_prefix Type: 9 ()
    # Field: delete_protection_state Type: 14 (.google.firestore.admin.v1.Database.DeleteProtectionState)
    # Field: cmek_config Type: 11 (.google.firestore.admin.v1.Database.CmekConfig)
    # Field: previous_id Type: 9 ()
    # Field: source_info Type: 11 (.google.firestore.admin.v1.Database.SourceInfo)
    # Field: tags Type: 11 (.google.firestore.admin.v1.Database.TagsEntry)
    # Field: free_tier Type: 8 ()
    # Field: etag Type: 9 ()
    # Field: database_edition Type: 14 (.google.firestore.admin.v1.Database.DatabaseEdition)
    # Field: realtime_updates_mode Type: 14 (.google.firestore.admin.v1.RealtimeUpdatesMode)
    # Field: firestore_data_access_mode Type: 14 (.google.firestore.admin.v1.Database.DataAccessMode)
    # Field: mongodb_compatible_data_access_mode Type: 14 (.google.firestore.admin.v1.Database.DataAccessMode)

# Enum: Database::DatabaseType
our $Database_DATABASE_TYPE_UNSPECIFIED = 0;
our $Database_FIRESTORE_NATIVE = 1;
our $Database_DATASTORE_MODE = 2;

# Enum: Database::ConcurrencyMode
our $Database_CONCURRENCY_MODE_UNSPECIFIED = 0;
our $Database_OPTIMISTIC = 1;
our $Database_PESSIMISTIC = 2;
our $Database_OPTIMISTIC_WITH_ENTITY_GROUPS = 3;

# Enum: Database::PointInTimeRecoveryEnablement
our $Database_POINT_IN_TIME_RECOVERY_ENABLEMENT_UNSPECIFIED = 0;
our $Database_POINT_IN_TIME_RECOVERY_ENABLED = 1;
our $Database_POINT_IN_TIME_RECOVERY_DISABLED = 2;

# Enum: Database::AppEngineIntegrationMode
our $Database_APP_ENGINE_INTEGRATION_MODE_UNSPECIFIED = 0;
our $Database_ENABLED = 1;
our $Database_DISABLED = 2;

# Enum: Database::DeleteProtectionState
our $Database_DELETE_PROTECTION_STATE_UNSPECIFIED = 0;
our $Database_DELETE_PROTECTION_DISABLED = 1;
our $Database_DELETE_PROTECTION_ENABLED = 2;

# Enum: Database::DatabaseEdition
our $Database_DATABASE_EDITION_UNSPECIFIED = 0;
our $Database_STANDARD = 1;
our $Database_ENTERPRISE = 2;

# Enum: Database::DataAccessMode
our $Database_DATA_ACCESS_MODE_UNSPECIFIED = 0;
our $Database_DATA_ACCESS_MODE_ENABLED = 1;
our $Database_DATA_ACCESS_MODE_DISABLED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1::Database - Compiled Protocol Buffers messages for google/firestore/admin/v1/database.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1::Database;

    my $msg = Google::Firestore::Admin::V1::Database::Database->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1::Database::Database->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1/database.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1::Database::Database

A Cloud Firestore Database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the Database.
Format: `projects/{project}/databases/{database}`

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The system-generated UUID4 for this Database.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp at which this database was created. Databases
created before 2016 do not populate create_time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp at which this database was most recently
updated. Note this only includes updates to the database resource and not
data contained by the database.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp at which this database was deleted. Only set if
the database has been deleted.

=item * C<< $msg->location_id() >> / C<< $msg->location_id($value) >>

Type: C<String>

The location of the database. Available locations are listed at
https://cloud.google.com/firestore/docs/locations.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Database::DatabaseType>)

The type of the database.
See https://cloud.google.com/datastore/docs/firestore-or-datastore for
information about how to choose.

=item * C<< $msg->concurrency_mode() >> / C<< $msg->concurrency_mode($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Database::ConcurrencyMode>)

The concurrency control mode to use for this database.

If unspecified in a CreateDatabase request, this will default based on the
database edition: Optimistic for Enterprise and Pessimistic for all other
databases.

=item * C<< $msg->version_retention_period() >> / C<< $msg->version_retention_period($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. The period during which past versions of data are retained in
the database.

Any [read][google.firestore.v1.GetDocumentRequest.read_time]
or [query][google.firestore.v1.ListDocumentsRequest.read_time] can specify
a `read_time` within this window, and will read the state of the database
at that time.

If the PITR feature is enabled, the retention period is 7 days. Otherwise,
the retention period is 1 hour.

=item * C<< $msg->earliest_version_time() >> / C<< $msg->earliest_version_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The earliest timestamp at which older versions of the data can
be read from the database. See [version_retention_period] above; this field
is populated with `now - version_retention_period`.

This value is continuously updated, and becomes stale the moment it is
queried. If you are using this value to recover data, make sure to account
for the time from the moment when the value is queried to the moment when
you initiate the recovery.

=item * C<< $msg->point_in_time_recovery_enablement() >> / C<< $msg->point_in_time_recovery_enablement($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Database::PointInTimeRecoveryEnablement>)

Whether to enable the PITR feature on this database.

=item * C<< $msg->app_engine_integration_mode() >> / C<< $msg->app_engine_integration_mode($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Database::AppEngineIntegrationMode>)

The App Engine integration mode to use for this database.

=item * C<< $msg->key_prefix() >> / C<< $msg->key_prefix($value) >>

Type: C<String>

Output only. The key_prefix for this database. This key_prefix is used, in
combination with the project ID ("<key prefix>~<project id>") to construct
the application ID that is returned from the Cloud Datastore APIs in Google
App Engine first generation runtimes.

This value may be empty in which case the appid to use for URL-encoded keys
is the project_id (eg: foo instead of v~foo).

=item * C<< $msg->delete_protection_state() >> / C<< $msg->delete_protection_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Database::DeleteProtectionState>)

State of delete protection for the database.

=item * C<< $msg->cmek_config() >> / C<< $msg->cmek_config($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Database::Database::CmekConfig>)

Optional. Presence indicates CMEK is enabled for this database.

=item * C<< $msg->previous_id() >> / C<< $msg->previous_id($value) >>

Type: C<String>

Output only. The database resource's prior database ID. This field is only
populated for deleted databases.

=item * C<< $msg->source_info() >> / C<< $msg->source_info($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Database::Database::SourceInfo>)

Output only. Information about the provenance of this database.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Database::Database::TagsEntry>)

Optional. Input only. Immutable. Tag keys/values directly bound to this
resource. For example:
  "123/environment": "production",
  "123/costCenter": "marketing"

=item * C<< $msg->free_tier() >> / C<< $msg->free_tier($value) >>

Type: C<Bool>

Output only. Background: Free tier is the ability of a Firestore database
to use a small amount of resources every day without being charged. Once
usage exceeds the free tier limit further usage is charged.

Whether this database can make use of the free tier. Only one database
per project can be eligible for the free tier.

The first (or next) database that is created in a project without a free
tier database will be marked as eligible for the free tier. Databases that
are created while there is a free tier database will not be eligible for
the free tier.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

This checksum is computed by the server based on the value of other
fields, and may be sent on update and delete requests to ensure the
client has an up-to-date value before proceeding.

=item * C<< $msg->database_edition() >> / C<< $msg->database_edition($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Database::DatabaseEdition>)

Immutable. The edition of the database.

=item * C<< $msg->realtime_updates_mode() >> / C<< $msg->realtime_updates_mode($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::RealtimeUpdatesMode>)

Immutable. The default Realtime Updates mode to use for this database.

=item * C<< $msg->firestore_data_access_mode() >> / C<< $msg->firestore_data_access_mode($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Database::DataAccessMode>)

Optional. The Firestore API data access mode to use for this database. If
not set on write:
- the default value is DATA_ACCESS_MODE_DISABLED for Enterprise Edition.
- the default value is DATA_ACCESS_MODE_ENABLED for Standard Edition.

=item * C<< $msg->mongodb_compatible_data_access_mode() >> / C<< $msg->mongodb_compatible_data_access_mode($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Database::DataAccessMode>)

Optional. The MongoDB compatible API data access mode to use for this
database. If not set on write, the default value is
DATA_ACCESS_MODE_ENABLED for Enterprise Edition. The value is always
DATA_ACCESS_MODE_DISABLED for Standard Edition.

=back

=head3 Enum: Database::DatabaseType

=over 4

=item * C<DATABASE_TYPE_UNSPECIFIED> => C<0>

=item * C<FIRESTORE_NATIVE> => C<1>

=item * C<DATASTORE_MODE> => C<2>

=back

=head3 Enum: Database::ConcurrencyMode

=over 4

=item * C<CONCURRENCY_MODE_UNSPECIFIED> => C<0>

=item * C<OPTIMISTIC> => C<1>

=item * C<PESSIMISTIC> => C<2>

=item * C<OPTIMISTIC_WITH_ENTITY_GROUPS> => C<3>

=back

=head3 Enum: Database::PointInTimeRecoveryEnablement

=over 4

=item * C<POINT_IN_TIME_RECOVERY_ENABLEMENT_UNSPECIFIED> => C<0>

=item * C<POINT_IN_TIME_RECOVERY_ENABLED> => C<1>

=item * C<POINT_IN_TIME_RECOVERY_DISABLED> => C<2>

=back

=head3 Enum: Database::AppEngineIntegrationMode

=over 4

=item * C<APP_ENGINE_INTEGRATION_MODE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=back

=head3 Enum: Database::DeleteProtectionState

=over 4

=item * C<DELETE_PROTECTION_STATE_UNSPECIFIED> => C<0>

=item * C<DELETE_PROTECTION_DISABLED> => C<1>

=item * C<DELETE_PROTECTION_ENABLED> => C<2>

=back

=head3 Enum: Database::DatabaseEdition

=over 4

=item * C<DATABASE_EDITION_UNSPECIFIED> => C<0>

=item * C<STANDARD> => C<1>

=item * C<ENTERPRISE> => C<2>

=back

=head3 Enum: Database::DataAccessMode

=over 4

=item * C<DATA_ACCESS_MODE_UNSPECIFIED> => C<0>

=item * C<DATA_ACCESS_MODE_ENABLED> => C<1>

=item * C<DATA_ACCESS_MODE_DISABLED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1::Database::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
