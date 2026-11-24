package Google::Cloud::Lustre::V1::Mirror;

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
    eval { require Google::Cloud::Lustre::V1::Transfer };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvY2xvdWQvbHVzdHJlL3YxL21pcnJvci5wcm90bxIWZ29vZ2xlLmNsb3VkLmx1
c3RyZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxobZ29vZ2xlL2FwaS9m
aWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiVnb29nbGUvY2xv
dWQvbHVzdHJlL3YxL3RyYW5zZmVyLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFz
ay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byL5BwoGTWlycm9yEhcK
BG5hbWUYASABKAlCA+BBCFIEbmFtZRJCCghnY3NfcGF0aBgDIAEoCzIfLmdvb2dsZS5jbG91
ZC5sdXN0cmUudjEuR2NzUGF0aEIG4EEC4EEFUgdnY3NQYXRoEksKC2x1c3RyZV9wYXRoGAQg
ASgLMiIuZ29vZ2xlLmNsb3VkLmx1c3RyZS52MS5MdXN0cmVQYXRoQgbgQQLgQQVSCmx1c3Ry
ZVBhdGgSTgoJZGlyZWN0aW9uGAUgASgOMiguZ29vZ2xlLmNsb3VkLmx1c3RyZS52MS5NaXJy
b3IuRGlyZWN0aW9uQgbgQQLgQQVSCWRpcmVjdGlvbhI5ChZkZWxldGVkX2ZpbGVzX3JldGFp
bmVkGAYgASgIQgPgQQFSFGRlbGV0ZWRGaWxlc1JldGFpbmVkEiUKC2Rlc2NyaXB0aW9uGAcg
ASgJQgPgQQFSC2Rlc2NyaXB0aW9uEkcKBmxhYmVscxgIIAMoCzIqLmdvb2dsZS5jbG91ZC5s
dXN0cmUudjEuTWlycm9yLkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxJACgtjcmVhdGVfdGlt
ZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJA
Cgt1cGRhdGVfdGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
dXBkYXRlVGltZRIdCgN1aWQYCyABKAlCC+KMz9cIAggB4EEDUgN1aWQSPwoFc3RhdGUYDCAB
KA4yJC5nb29nbGUuY2xvdWQubHVzdHJlLnYxLk1pcnJvci5TdGF0ZUID4EEDUgVzdGF0ZRo5
CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6
AjgBIj4KCURpcmVjdGlvbhIZChVESVJFQ1RJT05fVU5TUEVDSUZJRUQQABIWChJGUk9NX0NM
T1VEX1NUT1JBR0UQASJnCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFU
SU5HEAESEAoMSU5JVElBTF9TWU5DEAISDAoIREVMRVRJTkcQAxIKCgZBQ1RJVkUQBBINCglT
VVNQRU5ERUQQBTqBAepBfgocbHVzdHJlLmdvb2dsZWFwaXMuY29tL01pcnJvchJNcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9
L21pcnJvcnMve21pcnJvcn0qB21pcnJvcnMyBm1pcnJvciLeAQoTQ3JlYXRlTWlycm9yUmVx
dWVzdBI8CgZwYXJlbnQYASABKAlCJOBBAvpBHhIcbHVzdHJlLmdvb2dsZWFwaXMuY29tL01p
cnJvclIGcGFyZW50EiAKCW1pcnJvcl9pZBgCIAEoCUID4EECUghtaXJyb3JJZBI7CgZtaXJy
b3IYAyABKAsyHi5nb29nbGUuY2xvdWQubHVzdHJlLnYxLk1pcnJvckID4EECUgZtaXJyb3IS
KgoKcmVxdWVzdF9pZBgEIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCLAAQoTVXBkYXRl
TWlycm9yUmVxdWVzdBI7CgZtaXJyb3IYASABKAsyHi5nb29nbGUuY2xvdWQubHVzdHJlLnYx
Lk1pcnJvckID4EECUgZtaXJyb3ISQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSKgoKcmVxdWVzdF9pZBgDIAEoCUIL
4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCJ7ChNEZWxldGVNaXJyb3JSZXF1ZXN0EjgKBG5hbWUY
ASABKAlCJOBBAvpBHgocbHVzdHJlLmdvb2dsZWFwaXMuY29tL01pcnJvclIEbmFtZRIqCgpy
ZXF1ZXN0X2lkGAIgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElkIkwKEEdldE1pcnJvclJl
cXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC+kEeChxsdXN0cmUuZ29vZ2xlYXBpcy5jb20vTWly
cm9yUgRuYW1lItUBChJMaXN0TWlycm9yc1JlcXVlc3QSPAoGcGFyZW50GAEgASgJQiTgQQL6
QR4SHGx1c3RyZS5nb29nbGVhcGlzLmNvbS9NaXJyb3JSBnBhcmVudBIgCglwYWdlX3NpemUY
AiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9r
ZW4SHgoIb3JkZXJfYnkYBCABKAlCA+BBAVIHb3JkZXJCeRIbCgZmaWx0ZXIYBSABKAlCA+BB
AVIGZmlsdGVyIp4BChNMaXN0TWlycm9yc1Jlc3BvbnNlEjgKB21pcnJvcnMYASADKAsyHi5n
b29nbGUuY2xvdWQubHVzdHJlLnYxLk1pcnJvclIHbWlycm9ycxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SJQoLdW5yZWFjaGFibGUYAyADKAlCA+BBBlILdW5y
ZWFjaGFibGUiugMKFENyZWF0ZU1pcnJvck1ldGFkYXRhEmAKEm9wZXJhdGlvbl9tZXRhZGF0
YRgBIAEoCzIxLmdvb2dsZS5jbG91ZC5sdXN0cmUudjEuVHJhbnNmZXJPcGVyYXRpb25NZXRh
ZGF0YVIRb3BlcmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAyABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAQg
ASgJQgPgQQNSBnRhcmdldBIXCgR2ZXJiGAUgASgJQgPgQQNSBHZlcmISKgoOc3RhdHVzX21l
c3NhZ2UYBiABKAlCA+BBA1INc3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0
aW9uGAcgASgIQgPgQQNSFXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgI
IAEoCUID4EEDUgphcGlWZXJzaW9uQl8KGmNvbS5nb29nbGUuY2xvdWQubHVzdHJlLnYxQgtN
aXJyb3JQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2x1c3RyZS9hcGl2MS9sdXN0cmVw
YjtsdXN0cmVwYkqgXQoHEgUOAL0CAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAHwoJCgIDABIDEgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxID
FQAvCgkKAgMEEgMWACoKCQoCAwUSAxcAKQoICgEIEgMZAEkKCQoCCAsSAxkASQoICgEIEgMa
ACIKCQoCCAoSAxoAIgoICgEIEgMbACwKCQoCCAgSAxsALAoICgEIEgMcADMKCQoCCAESAxwA
MwowCgIEABIEHwB8ARokIFJlcHJlc2VudHMgYSBDbG91ZCBTdG9yYWdlIG1pcnJvci4KCgoK
AwQAARIDHwgOCgsKAwQABxIEIAIlBAoNCgUEAAedCBIEIAIlBAp6CgQEAAQAEgQpAi8DGmwg
UmVwcmVzZW50cyB0aGUgZGlyZWN0aW9uIG9mIHRoZSBtaXJyb3IuCiBUaGlzIGVudW0gZXhw
ZWN0cyB0byBiZSBleHRlbmRlZCBpbiBmdXR1cmUgd2l0aCBuZXcgbWlycm9yIHR5cGVzLgoK
DAoFBAAEAAESAykHEAofCgYEAAQAAgASAysEHhoQIEludmFsaWQgdmFsdWUuCgoOCgcEAAQA
AgABEgMrBBkKDgoHBAAEAAIAAhIDKxwdCjUKBgQABAACARIDLgQbGiYgTWlycm9yIGZyb20g
Q2xvdWQgU3RvcmFnZSB0byBMdXN0cmUuCgoOCgcEAAQAAgEBEgMuBBYKDgoHBAAEAAIBAhID
LhkaCiQKBAQABAESBDICRAMaFiBTdGF0ZSBvZiB0aGUgbWlycm9yLgoKDAoFBAAEAQESAzIH
DAomCgYEAAQBAgASAzQEGhoXIFN0YXRlIGlzIHVuc3BlY2lmaWVkLgoKDgoHBAAEAQIAARID
NAQVCg4KBwQABAECAAISAzQYGQo2CgYEAAQBAgESAzcEERonIFRoZSBtaXJyb3IgcmVzb3Vy
Y2UgaXMgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAECAQESAzcEDAoOCgcEAAQBAgECEgM3DxAK
UQoGBAAEAQICEgM6BBUaQiBUaGUgaW5pdGlhbCBzeW5jIGlzIGNvcHlpbmcgZXhpc3Rpbmcg
b2JqZWN0cyBmcm9tIENsb3VkIFN0b3JhZ2UuCgoOCgcEAAQBAgIBEgM6BBAKDgoHBAAEAQIC
AhIDOhMUCi0KBgQABAECAxIDPQQRGh4gVGhlIG1pcnJvciBpcyBiZWluZyBkZWxldGVkLgoK
DgoHBAAEAQIDARIDPQQMCg4KBwQABAECAwISAz0PEApDCgYEAAQBAgQSA0AEDxo0IFRoZSBt
aXJyb3IgaXMgc3luY2hyb25pemluZyBjaGFuZ2VzIGFzIHRoZXkgb2NjdXIuCgoOCgcEAAQB
AgQBEgNABAoKDgoHBAAEAQIEAhIDQA0OClgKBgQABAECBRIDQwQSGkkgU3luY2hyb25pemF0
aW9uIGlzIHBhdXNlZCBiZWNhdXNlIHRoZSBmaWxlIHN5c3RlbSBpcyBjbG9zZSB0byBjYXBh
Y2l0eS4KCg4KBwQABAECBQESA0MEDQoOCgcEAAQBAgUCEgNDEBEKiAEKBAQAAgASA0kCPRp7
IElkZW50aWZpZXIuIE5hbWUgb2YgdGhlIG1pcnJvci4KIEZvcm1hdDoKIGBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vbWly
cm9ycy97bWlycm9yfWAKCgwKBQQAAgAFEgNJAggKDAoFBAACAAESA0kJDQoMCgUEAAIAAxID
SRARCgwKBQQAAgAIEgNJEjwKDwoIBAACAAicCAASA0kTOwrvAQoEBAACARIETgJRBBrgASBS
ZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgVVJJIHRvIGEgQ2xvdWQgU3RvcmFnZSBidWNrZXQs
IG9yIGEgcGF0aCB3aXRoaW4gYQogYnVja2V0LCB1c2luZyB0aGUgZm9ybWF0IGBnczovL3tC
VUNLRVRfTkFNRX0ve09QVElPTkFMX1BBVEh9L2AuIElmIGEgcGF0aAogaW5zaWRlIHRoZSBi
dWNrZXQgaXMgc3BlY2lmaWVkLCBpdCBtdXN0IGVuZCB3aXRoIGEgZm9yd2FyZCBzbGFzaCAo
YC9gKS4KCgwKBQQAAgEGEgNOAgkKDAoFBAACAQESA04KEgoMCgUEAAIBAxIDThUWCg0KBQQA
AgEIEgROF1EDCg8KCAQAAgEInAgAEgNPBCoKDwoIBAACAQicCAESA1AEKwqEAgoEBAACAhIE
VwJaBBr1ASBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgTWFuYWdlZCBMdXN0cmUgZGlyZWN0
b3J5IHRvIG1pcnJvciB0by4gTXVzdCBiZSBhbgogYWJzb2x1dGUgcGF0aCBzdGFydGluZyB3
aXRoIGAvYCwgZm9yIGV4YW1wbGUgYC9kYXRhYCBvciBgL2RhdGEvc3ViZGlyYC4KIERlZmF1
bHRzIHRvIHRoZSByb290IGRpcmVjdG9yeSwgYC9gLiBJZiB0aGUgc3BlY2lmaWVkIGRpcmVj
dG9yeSBkb2Vzbid0CiBleGlzdCwgaXQgaXMgY3JlYXRlZC4KCgwKBQQAAgIGEgNXAgwKDAoF
BAACAgESA1cNGAoMCgUEAAICAxIDVxscCg0KBQQAAgIIEgRXHVoDCg8KCAQAAgIInAgAEgNY
BCoKDwoIBAACAgicCAESA1kEKwpMCgQEAAIDEgRdAmAEGj4gUmVxdWlyZWQuIEltbXV0YWJs
ZS4gUmVwcmVzZW50cyB0aGUgZGlyZWN0aW9uIG9mIHRoZSBtaXJyb3IuCgoMCgUEAAIDBhID
XQILCgwKBQQAAgMBEgNdDBUKDAoFBAACAwMSA10YGQoNCgUEAAIDCBIEXRpgAwoPCggEAAID
CJwIABIDXgQqCg8KCAQAAgMInAgBEgNfBCsKmQEKBAQAAgQSA2QCSxqLASBPcHRpb25hbC4g
SWYgYHRydWVgLCBmaWxlcyBhcmUgbm90IGRlbGV0ZWQgZnJvbSBNYW5hZ2VkIEx1c3RyZSB3
aGVuIHRoZQogc291cmNlIGZpbGVzIGFyZSBkZWxldGVkIGZyb20gQ2xvdWQgU3RvcmFnZS4g
RGVmYXVsdCBpcyBgZmFsc2VgLgoKDAoFBAACBAUSA2QCBgoMCgUEAAIEARIDZAcdCgwKBQQA
AgQDEgNkICEKDAoFBAACBAgSA2QiSgoPCggEAAIECJwIABIDZCNJCjMKBAQAAgUSA2cCQhom
IE9wdGlvbmFsLiBEZXNjcmlwdGlvbiBvZiB0aGUgbWlycm9yLgoKDAoFBAACBQUSA2cCCAoM
CgUEAAIFARIDZwkUCgwKBQQAAgUDEgNnFxgKDAoFBAACBQgSA2cZQQoPCggEAAIFCJwIABID
ZxpACjcKBAQAAgYSA2oCShoqIE9wdGlvbmFsLiBMYWJlbHMgdG8gYXBwbHkgdG8gdGhlIG1p
cnJvci4KCgwKBQQAAgYGEgNqAhUKDAoFBAACBgESA2oWHAoMCgUEAAIGAxIDah8gCgwKBQQA
AgYIEgNqIUkKDwoIBAACBgicCAASA2oiSAo9CgQEAAIHEgRtAm4yGi8gT3V0cHV0IG9ubHku
IFtPdXRwdXQgb25seV0gQ3JlYXRlIHRpbWUgc3RhbXAuCgoMCgUEAAIHBhIDbQIbCgwKBQQA
AgcBEgNtHCcKDAoFBAACBwMSA20qKwoMCgUEAAIHCBIDbgYxCg8KCAQAAgcInAgAEgNuBzAK
PQoEBAACCBIEcQJyMhovIE91dHB1dCBvbmx5LiBbT3V0cHV0IG9ubHldIFVwZGF0ZSB0aW1l
IHN0YW1wLgoKDAoFBAACCAYSA3ECGwoMCgUEAAIIARIDcRwnCgwKBQQAAggDEgNxKiwKDAoF
BAACCAgSA3IGMQoPCggEAAIICJwIABIDcgcwCjcKBAQAAgkSBHUCeAQaKSBPdXRwdXQgb25s
eS4gVW5pcXVlIElEIG9mIHRoZSByZXNvdXJjZS4KCgwKBQQAAgkFEgN1AggKDAoFBAACCQES
A3UJDAoMCgUEAAIJAxIDdQ8RCg0KBQQAAgkIEgR1EngDChIKCwQAAgkIzPH5igEBEgN2BCoK
DwoIBAACCQicCAASA3cELQpKCgQEAAIKEgN7Aj8aPSBPdXRwdXQgb25seS4gW091dHB1dCBv
bmx5XSBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgbWlycm9yLgoKDAoFBAACCgYSA3sCBwoM
CgUEAAIKARIDewgNCgwKBQQAAgoDEgN7EBIKDAoFBAACCggSA3sTPgoPCggEAAIKCJwIABID
exQ9CigKAgQBEgV/AKkBARobIFJlcXVlc3QgZm9yIENyZWF0ZU1pcnJvci4KCgoKAwQBARID
fwgbCqYBCgQEAQIAEgaCAQKHAQQalQEgUmVxdWlyZWQuIFBhcmVudCBpbnN0YW5jZSByZXNv
dXJjZSB3aGVyZSB0aGUgbWlycm9yIHdpbGwgYmUgY3JlYXRlZCwgaW4gdGhlCiBmb3JtYXQ6
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tp
bnN0YW5jZX1gCgoNCgUEAQIABRIEggECCAoNCgUEAQIAARIEggEJDwoNCgUEAQIAAxIEggES
EwoPCgUEAQIACBIGggEUhwEDChAKCAQBAgAInAgAEgSDAQQqChEKBwQBAgAInwgSBoQBBIYB
BQqXAgoEBAECARIEkQECQBqIAiBSZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIG1p
cnJvci4KCiAqIE11c3QgY29udGFpbiBvbmx5IGxvd2VyY2FzZSBsZXR0ZXJzLCBudW1iZXJz
LCBhbmQgaHlwaGVucy4KICogTXVzdCBzdGFydCB3aXRoIGEgbGV0dGVyLgogKiBNdXN0IGJl
IGJldHdlZW4gMS02MyBjaGFyYWN0ZXJzLgogKiBNdXN0IGVuZCB3aXRoIGEgbnVtYmVyIG9y
IGEgbGV0dGVyLgoKIFRoZSBJRCBjYW5ub3QgYmUgY2hhbmdlZCBhZnRlciB0aGUgbWlycm9y
IGlzIGNyZWF0ZWQuCgoNCgUEAQIBBRIEkQECCAoNCgUEAQIBARIEkQEJEgoNCgUEAQIBAxIE
kQEVFgoNCgUEAQIBCBIEkQEXPwoQCggEAQIBCJwIABIEkQEYPgovCgQEAQICEgSUAQI9GiEg
UmVxdWlyZWQuIFRoZSBtaXJyb3IgdG8gY3JlYXRlLgoKDQoFBAECAgYSBJQBAggKDQoFBAEC
AgESBJQBCQ8KDQoFBAECAgMSBJQBEhMKDQoFBAECAggSBJQBFDwKEAoIBAECAgicCAASBJQB
FTsK7wYKBAQBAgMSBqUBAqgBBBreBiBPcHRpb25hbC4gVGhlIHVuaXF1ZSBJRCB0byBpZGVu
dGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZSByZXF1ZXN0IElECiBzbyB0aGF0IGlm
IHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8g
aWdub3JlCiB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4g
VGhlIHNlcnZlciBndWFyYW50ZWVzIHRoYXQgYQogcmVxdWVzdCBkb2Vzbid0IHJlc3VsdCBp
biBjcmVhdGlvbiBvZiBkdXBsaWNhdGUgbWlycm9ycyBmb3IgYXQgbGVhc3QgNjAKIG1pbnV0
ZXMuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtl
IGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91
IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhl
IHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUg
cmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBz
ZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxs
eSBjcmVhdGluZyBkdXBsaWNhdGUgbWlycm9ycy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJl
IGEgdmFsaWQgVVVJRCB2ZXJzaW9uIDQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybwog
VVVJRCBpcyBub3Qgc3VwcG9ydGVkIChgMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAw
MDAwMDAwYCkuCiBUaGlzIHJlcXVlc3QgaXMgb25seSBpZGVtcG90ZW50IGlmIGEgYHJlcXVl
c3RfaWRgIGlzIHByb3ZpZGVkLgoKDQoFBAECAwUSBKUBAggKDQoFBAECAwESBKUBCRMKDQoF
BAECAwMSBKUBFhcKDwoFBAECAwgSBqUBGKgBAwoTCgsEAQIDCMzx+YoBARIEpgEEKgoQCggE
AQIDCJwIABIEpwEEKgopCgIEAhIGrAEAygEBGhsgUmVxdWVzdCBmb3IgVXBkYXRlTWlycm9y
LgoKCwoDBAIBEgSsAQgbCtEBCgQEAgIAEgSwAQI9GsIBIFJlcXVpcmVkLiBNaXJyb3IgdG8g
dXBkYXRlLiBUaGUgbWlycm9yJ3MgYG5hbWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkK
IHRoZSBtaXJyb3IgdG8gdXBkYXRlLCBpbiB0aGUgZm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9taXJyb3Jz
L3ttaXJyb3J9YAoKDQoFBAICAAYSBLABAggKDQoFBAICAAESBLABCQ8KDQoFBAICAAMSBLAB
EhMKDQoFBAICAAgSBLABFDwKEAoIBAICAAicCAASBLABFTsK9wEKBAQCAgESBrUBArYBLxrm
ASBPcHRpb25hbC4gRmllbGRzIHNwZWNpZmllZCBpbiB0aGUgdXBkYXRlX21hc2sgYXJlIHJl
bGF0aXZlIHRvIHRoZSByZXNvdXJjZSwKIG5vdCB0aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxk
IHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4gdGhlIG1hc2suIElmCiBubyBtYXNr
IGlzIHByb3ZpZGVkIHRoZW4gYWxsIGZpZWxkcyBwcmVzZW50IGluIHRoZSByZXF1ZXN0IGFy
ZSBvdmVyd3JpdHRlbi4KCg0KBQQCAgEGEgS1AQIbCg0KBQQCAgEBEgS1ARwnCg0KBQQCAgED
EgS1ASorCg0KBQQCAgEIEgS2AQYuChAKCAQCAgEInAgAEgS2AQctCrMGCgQEAgICEgbGAQLJ
AQQaogYgT3B0aW9uYWwuIFRoZSB1bmlxdWUgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNw
ZWNpZnkgYSB1bmlxdWUgcmVxdWVzdCBJRAogc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5
b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvIGlnbm9yZQogdGhlIHJlcXVl
c3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgZ3VhcmFu
dGVlcyB0aGF0IGEKIHJlcXVlc3QgZG9lc24ndCByZXN1bHQgaW4gdGhlIHNhbWUgdXBkYXRl
IHJlcXVlc3QgYmVpbmcgZXhlY3V0ZWQgZm9yIGF0CiBsZWFzdCA2MCBtaW51dGVzLgoKIEZv
ciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0
aWFsIHJlcXVlc3QgYW5kIHRoZQogcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRo
ZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIg
Y2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3Qg
SUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJl
cXVlc3QuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgdmVyc2lvbiA0
IHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8KIFVVSUQgaXMgbm90IHN1cHBvcnRlZCAo
YDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMGApLgogVGhpcyByZXF1ZXN0
IGlzIG9ubHkgaWRlbXBvdGVudCBpZiBhIGByZXF1ZXN0X2lkYCBpcyBwcm92aWRlZC4KCg0K
BQQCAgIFEgTGAQIICg0KBQQCAgIBEgTGAQkTCg0KBQQCAgIDEgTGARYXCg8KBQQCAgIIEgbG
ARjJAQMKEwoLBAICAgjM8fmKAQESBMcBBCoKEAoIBAICAgicCAASBMgBBCoKKQoCBAMSBs0B
AOcBARobIFJlcXVlc3QgZm9yIERlbGV0ZU1pcnJvci4KCgsKAwQDARIEzQEIGwqaAQoEBAMC
ABIG0AEC0wEEGokBIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBtaXJyb3IgdG8gZGVsZXRlLCBp
biB0aGUgZm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9pbnN0YW5jZXMve2luc3RhbmNlfS9taXJyb3JzL3ttaXJyb3J9YAoKDQoFBAMCAAUSBNAB
AggKDQoFBAMCAAESBNABCQ0KDQoFBAMCAAMSBNABEBEKDwoFBAMCAAgSBtABEtMBAwoQCggE
AwIACJwIABIE0QEEKgoPCgcEAwIACJ8IEgTSAQROCrMGCgQEAwIBEgbjAQLmAQQaogYgT3B0
aW9uYWwuIFRoZSB1bmlxdWUgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1
bmlxdWUgcmVxdWVzdCBJRAogc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVl
c3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvIGlnbm9yZQogdGhlIHJlcXVlc3QgaWYgaXQg
aGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgZ3VhcmFudGVlcyB0aGF0
IGEKIHJlcXVlc3QgZG9lc24ndCByZXN1bHQgaW4gdGhlIHNhbWUgZGVsZXRlIHJlcXVlc3Qg
YmVpbmcgZXhlY3V0ZWQgZm9yIGF0CiBsZWFzdCA2MCBtaW51dGVzLgoKIEZvciBleGFtcGxl
LCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVl
c3QgYW5kIHRoZQogcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0
IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNr
IGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyBy
ZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuCgog
VGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgdmVyc2lvbiA0IHdpdGggdGhl
IGV4Y2VwdGlvbiB0aGF0IHplcm8KIFVVSUQgaXMgbm90IHN1cHBvcnRlZCAoYDAwMDAwMDAw
LTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMGApLgogVGhpcyByZXF1ZXN0IGlzIG9ubHkg
aWRlbXBvdGVudCBpZiBhIGByZXF1ZXN0X2lkYCBpcyBwcm92aWRlZC4KCg0KBQQDAgEFEgTj
AQIICg0KBQQDAgEBEgTjAQkTCg0KBQQDAgEDEgTjARYXCg8KBQQDAgEIEgbjARjmAQMKEwoL
BAMCAQjM8fmKAQESBOQBBCoKEAoIBAMCAQicCAASBOUBBCoKJgoCBAQSBuoBAPEBARoYIFJl
cXVlc3QgZm9yIEdldE1pcnJvci4KCgsKAwQEARIE6gEIGAqcAQoEBAQCABIG7QEC8AEEGosB
IFJlcXVpcmVkLiBOYW1lIG9mIHRoZSBtaXJyb3IgdG8gcmV0cmlldmUsIGluIHRoZSBmb3Jt
YXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNl
cy97aW5zdGFuY2V9L21pcnJvcnMve21pcnJvcn1gCgoNCgUEBAIABRIE7QECCAoNCgUEBAIA
ARIE7QEJDQoNCgUEBAIAAxIE7QEQEQoPCgUEBAIACBIG7QES8AEDChAKCAQEAgAInAgAEgTu
AQQqCg8KBwQEAgAInwgSBO8BBE4KKAoCBAUSBvQBAI4CARoaIFJlcXVlc3QgZm9yIExpc3RN
aXJyb3JzLgoKCwoDBAUBEgT0AQgaCqYBCgQEBQIAEgb3AQL8AQQalQEgUmVxdWlyZWQuIFBh
cmVudCBpbnN0YW5jZSByZXNvdXJjZSB3aGVyZSB0aGUgbWlycm9ycyB3aWxsIGJlIGxpc3Rl
ZCwgaW4gdGhlCiBmb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX1gCgoNCgUEBQIABRIE9wECCAoNCgUEBQIAARIE
9wEJDwoNCgUEBQIAAxIE9wESEwoPCgUEBQIACBIG9wEU/AEDChAKCAQFAgAInAgAEgT4AQQq
ChEKBwQFAgAInwgSBvkBBPsBBQqtAQoEBAUCARIEgQICPxqeASBPcHRpb25hbC4gUmVxdWVz
dGVkIHBhZ2Ugc2l6ZS4gVGhlIHNlcnZlciBtaWdodCByZXR1cm4gZmV3ZXIgaXRlbXMgdGhh
bgogcmVxdWVzdGVkLiBJZiB1bnNwZWNpZmllZCwgdGhlIGRlZmF1bHQgcGFnZSBzaXplIGlz
IDEwLiBUaGUgbWF4aW11bSB2YWx1ZQogaXMgMTAwMC4KCg0KBQQFAgEFEgSBAgIHCg0KBQQF
AgEBEgSBAggRCg0KBQQFAgEDEgSBAhQVCg0KBQQFAgEIEgSBAhY+ChAKCAQFAgEInAgAEgSB
Ahc9CvgBCgQEBQICEgSHAgJBGukBIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVk
IGZyb20gYSBwcmV2aW91cyBgTGlzdE1pcnJvcnNgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8g
cmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KIFdoZW4gcGFnaW5hdGluZywgYWxsIG90
aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RNaXJyb3JzYCBtdXN0IG1hdGNoCiB0
aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAUCAgUSBIcCAggK
DQoFBAUCAgESBIcCCRMKDQoFBAUCAgMSBIcCFhcKDQoFBAUCAggSBIcCGEAKEAoIBAUCAgic
CAASBIcCGT8KMwoEBAUCAxIEigICPxolIE9wdGlvbmFsLiBEZXNpcmVkIG9yZGVyIG9mIHJl
c3VsdHMuCgoNCgUEBQIDBRIEigICCAoNCgUEBQIDARIEigIJEQoNCgUEBQIDAxIEigIUFQoN
CgUEBQIDCBIEigIWPgoQCggEBQIDCJwIABIEigIXPQosCgQEBQIEEgSNAgI9Gh4gT3B0aW9u
YWwuIEZpbHRlcmluZyByZXN1bHRzLgoKDQoFBAUCBAUSBI0CAggKDQoFBAUCBAESBI0CCQ8K
DQoFBAUCBAMSBI0CEhMKDQoFBAUCBAgSBI0CFDwKEAoIBAUCBAicCAASBI0CFTsKKQoCBAYS
BpECAJsCARobIFJlc3BvbnNlIGZvciBMaXN0TWlycm9ycy4KCgsKAwQGARIEkQIIGwowCgQE
BgIAEgSTAgIeGiIgTGlzdCBvZiBtaXJyb3JzIG9uIHRoZSBpbnN0YW5jZS4KCg0KBQQGAgAE
EgSTAgIKCg0KBQQGAgAGEgSTAgsRCg0KBQQGAgABEgSTAhIZCg0KBQQGAgADEgSTAhwdCk8K
BAQGAgESBJYCAh0aQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRo
ZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0KBQQGAgEFEgSWAgIICg0KBQQGAgEBEgSWAgkY
Cg0KBQQGAgEDEgSWAhscCkYKBAQGAgISBpkCApoCNRo2IFVub3JkZXJlZCBsaXN0LiBMb2Nh
dGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQGAgIEEgSZAgIKCg0KBQQG
AgIFEgSZAgsRCg0KBQQGAgIBEgSZAhIdCg0KBQQGAgIDEgSZAiAhCg0KBQQGAgIIEgSaAgY0
ChAKCAQGAgIInAgAEgSaAgczCjgKAgQHEgaeAgC9AgEaKiBNZXRhZGF0YSBvZiB0aGUgY3Jl
YXRlIG1pcnJvciBvcGVyYXRpb24uCgoLCgMEBwESBJ4CCBwKMQoEBAcCABIEoAICMxojIERh
dGEgdHJhbnNmZXIgb3BlcmF0aW9uIG1ldGFkYXRhLgoKDQoFBAcCAAYSBKACAhsKDQoFBAcC
AAESBKACHC4KDQoFBAcCAAMSBKACMTIKQgoEBAcCARIGowICpAIyGjIgT3V0cHV0IG9ubHku
IFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoNCgUEBwIBBhIEowICGwoN
CgUEBwIBARIEowIcJwoNCgUEBwIBAxIEowIqKwoNCgUEBwIBCBIEpAIGMQoQCggEBwIBCJwI
ABIEpAIHMApHCgQEBwICEganAgKoAjIaNyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9w
ZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5nLgoKDQoFBAcCAgYSBKcCAhsKDQoFBAcCAgESBKcC
HCQKDQoFBAcCAgMSBKcCJygKDQoFBAcCAggSBKgCBjEKEAoIBAcCAgicCAASBKgCBzAKWgoE
BAcCAxIEqwICQBpMIE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRo
IGZvciB0aGUgdGFyZ2V0IG9mIHRoZSBvcGVyYXRpb24uCgoNCgUEBwIDBRIEqwICCAoNCgUE
BwIDARIEqwIJDwoNCgUEBwIDAxIEqwISEwoNCgUEBwIDCBIEqwIUPwoQCggEBwIDCJwIABIE
qwIVPgpICgQEBwIEEgSuAgI+GjogT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhl
Y3V0ZWQgYnkgdGhlIG9wZXJhdGlvbi4KCg0KBQQHAgQFEgSuAgIICg0KBQQHAgQBEgSuAgkN
Cg0KBQQHAgQDEgSuAhARCg0KBQQHAgQIEgSuAhI9ChAKCAQHAgQInAgAEgSuAhM8CkwKBAQH
AgUSBLECAkgaPiBPdXRwdXQgb25seS4gSHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBv
cGVyYXRpb24sIGlmIGFueS4KCg0KBQQHAgUFEgSxAgIICg0KBQQHAgUBEgSxAgkXCg0KBQQH
AgUDEgSxAhobCg0KBQQHAgUIEgSxAhxHChAKCAQHAgUInAgAEgSxAh1GCtECCgQEBwIGEgS5
AgJOGsICIE91dHB1dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJl
cXVlc3RlZCBjYW5jZWxsYXRpb24KIG9mIHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhh
dCBoYXZlIHN1Y2Nlc3NmdWxseSBiZWVuIGNhbmNlbGxlZAogaGF2ZQogW2dvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24uZXJyb3JdW2dvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24u
ZXJyb3JdCiB2YWx1ZSB3aXRoIGEgW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5y
cGMuU3RhdHVzLmNvZGVdIG9mIDEsCiBjb3JyZXNwb25kaW5nIHRvIGBDb2RlLkNBTkNFTExF
RGAuCgoNCgUEBwIGBRIEuQICBgoNCgUEBwIGARIEuQIHHQoNCgUEBwIGAxIEuQIgIQoNCgUE
BwIGCBIEuQIiTQoQCggEBwIGCJwIABIEuQIjTApFCgQEBwIHEgS8AgJFGjcgT3V0cHV0IG9u
bHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCg0KBQQHAgcF
EgS8AgIICg0KBQQHAgcBEgS8AgkUCg0KBQQHAgcDEgS8AhcYCg0KBQQHAgcIEgS8AhlEChAK
CAQHAgcInAgAEgS8AhpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Lustre::V1::Mirror::Mirror ===
    # Fields for Mirror
    # Field: name Type: 9 ()
    # Field: gcs_path Type: 11 (.google.cloud.lustre.v1.GcsPath)
    # Field: lustre_path Type: 11 (.google.cloud.lustre.v1.LustrePath)
    # Field: direction Type: 14 (.google.cloud.lustre.v1.Mirror.Direction)
    # Field: deleted_files_retained Type: 8 ()
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.lustre.v1.Mirror.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: uid Type: 9 ()
    # Field: state Type: 14 (.google.cloud.lustre.v1.Mirror.State)

# Enum: Mirror::Direction
our $Mirror_DIRECTION_UNSPECIFIED = 0;
our $Mirror_FROM_CLOUD_STORAGE = 1;

# Enum: Mirror::State
our $Mirror_STATE_UNSPECIFIED = 0;
our $Mirror_CREATING = 1;
our $Mirror_INITIAL_SYNC = 2;
our $Mirror_DELETING = 3;
our $Mirror_ACTIVE = 4;
our $Mirror_SUSPENDED = 5;

# === Message: Google::Cloud::Lustre::V1::Mirror::CreateMirrorRequest ===
    # Fields for CreateMirrorRequest
    # Field: parent Type: 9 ()
    # Field: mirror_id Type: 9 ()
    # Field: mirror Type: 11 (.google.cloud.lustre.v1.Mirror)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Mirror::UpdateMirrorRequest ===
    # Fields for UpdateMirrorRequest
    # Field: mirror Type: 11 (.google.cloud.lustre.v1.Mirror)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Mirror::DeleteMirrorRequest ===
    # Fields for DeleteMirrorRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Mirror::GetMirrorRequest ===
    # Fields for GetMirrorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Mirror::ListMirrorsRequest ===
    # Fields for ListMirrorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Mirror::ListMirrorsResponse ===
    # Fields for ListMirrorsResponse
    # Field: mirrors Type: 11 (.google.cloud.lustre.v1.Mirror)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Lustre::V1::Mirror::CreateMirrorMetadata ===
    # Fields for CreateMirrorMetadata
    # Field: operation_metadata Type: 11 (.google.cloud.lustre.v1.TransferOperationMetadata)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Lustre::V1::Mirror - Compiled Protocol Buffers messages for google/cloud/lustre/v1/mirror.proto

=head1 SYNOPSIS

    use Google::Cloud::Lustre::V1::Mirror;

    my $msg = Google::Cloud::Lustre::V1::Mirror::Mirror->new({
        name => $name,
        gcs_path => $gcs_path,
        lustre_path => $lustre_path,
        direction => $direction,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Lustre::V1::Mirror::Mirror->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/lustre/v1/mirror.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Lustre::V1::Mirror::Mirror

Represents a Cloud Storage mirror.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the mirror.
Format:
`projects/{project}/locations/{location}/instances/{instance}/mirrors/{mirror}`

=item * C<< $msg->gcs_path() >> / C<< $msg->gcs_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::GcsPath>)

Required. Immutable. The URI to a Cloud Storage bucket, or a path within a
bucket, using the format `gs://{BUCKET_NAME}/{OPTIONAL_PATH}/`. If a path
inside the bucket is specified, it must end with a forward slash (`/`).

=item * C<< $msg->lustre_path() >> / C<< $msg->lustre_path($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::LustrePath>)

Required. Immutable. The Managed Lustre directory to mirror to. Must be an
absolute path starting with `/`, for example `/data` or `/data/subdir`.
Defaults to the root directory, `/`. If the specified directory doesn't
exist, it is created.

=item * C<< $msg->direction() >> / C<< $msg->direction($value) >>

Type: C<Enum> (L<Google::Cloud::Lustre::V1::Mirror::Direction>)

Required. Immutable. Represents the direction of the mirror.

=item * C<< $msg->deleted_files_retained() >> / C<< $msg->deleted_files_retained($value) >>

Type: C<Bool>

Optional. If `true`, files are not deleted from Managed Lustre when the
source files are deleted from Cloud Storage. Default is `false`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the mirror.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Mirror::Mirror::LabelsEntry>)

Optional. Labels to apply to the mirror.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] Create time stamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] Update time stamp.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Unique ID of the resource.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Lustre::V1::Mirror::State>)

Output only. [Output only] The current state of the mirror.

=back

=head3 Enum: Mirror::Direction

=over 4

=item * C<DIRECTION_UNSPECIFIED> => C<0>

=item * C<FROM_CLOUD_STORAGE> => C<1>

=back

=head3 Enum: Mirror::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<INITIAL_SYNC> => C<2>

=item * C<DELETING> => C<3>

=item * C<ACTIVE> => C<4>

=item * C<SUSPENDED> => C<5>

=back

=head2 Google::Cloud::Lustre::V1::Mirror::CreateMirrorRequest

Request for CreateMirror.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent instance resource where the mirror will be created, in the
format: `projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->mirror_id() >> / C<< $msg->mirror_id($value) >>

Type: C<String>

Required. The ID to use for the mirror.

* Must contain only lowercase letters, numbers, and hyphens.
* Must start with a letter.
* Must be between 1-63 characters.
* Must end with a number or a letter.

The ID cannot be changed after the mirror is created.

=item * C<< $msg->mirror() >> / C<< $msg->mirror($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Mirror::Mirror>)

Required. The mirror to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. The unique ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server guarantees that a
request doesn't result in creation of duplicate mirrors for at least 60
minutes.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate mirrors.

The request ID must be a valid UUID version 4 with the exception that zero
UUID is not supported (`00000000-0000-0000-0000-000000000000`).
This request is only idempotent if a `request_id` is provided.

=back

=head2 Google::Cloud::Lustre::V1::Mirror::UpdateMirrorRequest

Request for UpdateMirror.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mirror() >> / C<< $msg->mirror($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Mirror::Mirror>)

Required. Mirror to update. The mirror's `name` field is used to identify
the mirror to update, in the format:
`projects/{project}/locations/{location}/instances/{instance}/mirrors/{mirror}`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Fields specified in the update_mask are relative to the resource,
not the full request. A field will be overwritten if it is in the mask. If
no mask is provided then all fields present in the request are overwritten.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. The unique ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server guarantees that a
request doesn't result in the same update request being executed for at
least 60 minutes.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request.

The request ID must be a valid UUID version 4 with the exception that zero
UUID is not supported (`00000000-0000-0000-0000-000000000000`).
This request is only idempotent if a `request_id` is provided.

=back

=head2 Google::Cloud::Lustre::V1::Mirror::DeleteMirrorRequest

Request for DeleteMirror.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the mirror to delete, in the format:
`projects/{project}/locations/{location}/instances/{instance}/mirrors/{mirror}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. The unique ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server guarantees that a
request doesn't result in the same delete request being executed for at
least 60 minutes.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request.

The request ID must be a valid UUID version 4 with the exception that zero
UUID is not supported (`00000000-0000-0000-0000-000000000000`).
This request is only idempotent if a `request_id` is provided.

=back

=head2 Google::Cloud::Lustre::V1::Mirror::GetMirrorRequest

Request for GetMirror.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the mirror to retrieve, in the format:
`projects/{project}/locations/{location}/instances/{instance}/mirrors/{mirror}`

=back

=head2 Google::Cloud::Lustre::V1::Mirror::ListMirrorsRequest

Request for ListMirrors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent instance resource where the mirrors will be listed, in the
format: `projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. The server might return fewer items than
requested. If unspecified, the default page size is 10. The maximum value
is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListMirrors` call.
Provide this to retrieve the subsequent page.
When paginating, all other parameters provided to `ListMirrors` must match
the call that provided the page token.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Desired order of results.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results.

=back

=head2 Google::Cloud::Lustre::V1::Mirror::ListMirrorsResponse

Response for ListMirrors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mirrors() >> / C<< $msg->mirrors($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Mirror::Mirror>)

List of mirrors on the instance.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head2 Google::Cloud::Lustre::V1::Mirror::CreateMirrorMetadata

Metadata of the create mirror operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operation_metadata() >> / C<< $msg->operation_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Lustre::V1::Transfer::TransferOperationMetadata>)

Data transfer operation metadata.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Lustre::V1::Mirror::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
