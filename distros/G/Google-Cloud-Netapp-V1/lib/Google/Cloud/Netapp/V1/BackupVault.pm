package Google::Cloud::Netapp::V1::BackupVault;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvbmV0YXBwL3YxL2JhY2t1cF92YXVsdC5wcm90bxIWZ29vZ2xlLmNs
b3VkLm5ldGFwcC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i3A8KC0JhY2t1cFZhdWx0EhcKBG5h
bWUYASABKAlCA+BBCFIEbmFtZRJECgVzdGF0ZRgCIAEoDjIpLmdvb2dsZS5jbG91ZC5uZXRh
cHAudjEuQmFja3VwVmF1bHQuU3RhdGVCA+BBA1IFc3RhdGUSQAoLY3JlYXRlX3RpbWUYAyAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSIAoLZGVz
Y3JpcHRpb24YBCABKAlSC2Rlc2NyaXB0aW9uEkcKBmxhYmVscxgFIAMoCzIvLmdvb2dsZS5j
bG91ZC5uZXRhcHAudjEuQmFja3VwVmF1bHQuTGFiZWxzRW50cnlSBmxhYmVscxJkChFiYWNr
dXBfdmF1bHRfdHlwZRgGIAEoDjIzLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuQmFja3VwVmF1
bHQuQmFja3VwVmF1bHRUeXBlQgPgQQFSD2JhY2t1cFZhdWx0VHlwZRJOCg1zb3VyY2VfcmVn
aW9uGAcgASgJQingQQH6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIM
c291cmNlUmVnaW9uEk4KDWJhY2t1cF9yZWdpb24YCCABKAlCKeBBAfpBIwohbG9jYXRpb25z
Lmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgxiYWNrdXBSZWdpb24SWQoTc291cmNlX2JhY2t1
cF92YXVsdBgJIAEoCUIp4EED+kEjCiFuZXRhcHAuZ29vZ2xlYXBpcy5jb20vQmFja3VwVmF1
bHRSEXNvdXJjZUJhY2t1cFZhdWx0EmMKGGRlc3RpbmF0aW9uX2JhY2t1cF92YXVsdBgKIAEo
CUIp4EED+kEjCiFuZXRhcHAuZ29vZ2xlYXBpcy5jb20vQmFja3VwVmF1bHRSFmRlc3RpbmF0
aW9uQmFja3VwVmF1bHQSdgoXYmFja3VwX3JldGVudGlvbl9wb2xpY3kYCyABKAsyOS5nb29n
bGUuY2xvdWQubmV0YXBwLnYxLkJhY2t1cFZhdWx0LkJhY2t1cFJldGVudGlvblBvbGljeUID
4EEBUhViYWNrdXBSZXRlbnRpb25Qb2xpY3kSRgoKa21zX2NvbmZpZxgMIAEoCUIn4EEB+kEh
Ch9uZXRhcHAuZ29vZ2xlYXBpcy5jb20vS21zQ29uZmlnUglrbXNDb25maWcSYwoQZW5jcnlw
dGlvbl9zdGF0ZRgNIAEoDjIzLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuQmFja3VwVmF1bHQu
RW5jcnlwdGlvblN0YXRlQgPgQQNSD2VuY3J5cHRpb25TdGF0ZRJAChpiYWNrdXBzX2NyeXB0
b19rZXlfdmVyc2lvbhgOIAEoCUID4EEDUhdiYWNrdXBzQ3J5cHRvS2V5VmVyc2lvbhrkAgoV
QmFja3VwUmV0ZW50aW9uUG9saWN5ElcKJmJhY2t1cF9taW5pbXVtX2VuZm9yY2VkX3JldGVu
dGlvbl9kYXlzGAEgASgFQgPgQQJSImJhY2t1cE1pbmltdW1FbmZvcmNlZFJldGVudGlvbkRh
eXMSOQoWZGFpbHlfYmFja3VwX2ltbXV0YWJsZRgCIAEoCEID4EEBUhRkYWlseUJhY2t1cElt
bXV0YWJsZRI7Chd3ZWVrbHlfYmFja3VwX2ltbXV0YWJsZRgDIAEoCEID4EEBUhV3ZWVrbHlC
YWNrdXBJbW11dGFibGUSPQoYbW9udGhseV9iYWNrdXBfaW1tdXRhYmxlGAQgASgIQgPgQQFS
Fm1vbnRobHlCYWNrdXBJbW11dGFibGUSOwoXbWFudWFsX2JhY2t1cF9pbW11dGFibGUYBSAB
KAhCA+BBAVIVbWFudWFsQmFja3VwSW1tdXRhYmxlGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiXgoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgkKBVJFQURZEAISDAoIREVMRVRJTkcQAxIJ
CgVFUlJPUhAEEgwKCFVQREFUSU5HEAUiVQoPQmFja3VwVmF1bHRUeXBlEiEKHUJBQ0tVUF9W
QVVMVF9UWVBFX1VOU1BFQ0lGSUVEEAASDQoJSU5fUkVHSU9OEAESEAoMQ1JPU1NfUkVHSU9O
EAIisAEKD0VuY3J5cHRpb25TdGF0ZRIgChxFTkNSWVBUSU9OX1NUQVRFX1VOU1BFQ0lGSUVE
EAASHAoYRU5DUllQVElPTl9TVEFURV9QRU5ESU5HEAESHgoaRU5DUllQVElPTl9TVEFURV9D
T01QTEVURUQQAhIgChxFTkNSWVBUSU9OX1NUQVRFX0lOX1BST0dSRVNTEAMSGwoXRU5DUllQ
VElPTl9TVEFURV9GQUlMRUQQBDqHAepBgwEKIW5ldGFwcC5nb29nbGVhcGlzLmNvbS9CYWNr
dXBWYXVsdBJDcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1
cFZhdWx0cy97YmFja3VwX3ZhdWx0fSoMYmFja3VwVmF1bHRzMgtiYWNrdXBWYXVsdCJWChVH
ZXRCYWNrdXBWYXVsdFJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFuZXRhcHAuZ29v
Z2xlYXBpcy5jb20vQmFja3VwVmF1bHRSBG5hbWUiywEKF0xpc3RCYWNrdXBWYXVsdHNSZXF1
ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjEiFuZXRhcHAuZ29vZ2xlYXBpcy5jb20vQmFj
a3VwVmF1bHRSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2Vf
dG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIZCghvcmRlcl9ieRgEIAEoCVIHb3JkZXJCeRIWCgZm
aWx0ZXIYBSABKAlSBmZpbHRlciKuAQoYTGlzdEJhY2t1cFZhdWx0c1Jlc3BvbnNlEkgKDWJh
Y2t1cF92YXVsdHMYASADKAsyIy5nb29nbGUuY2xvdWQubmV0YXBwLnYxLkJhY2t1cFZhdWx0
UgxiYWNrdXBWYXVsdHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
EiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSLXAQoYQ3JlYXRlQmFja3VwVmF1
bHRSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjEiFuZXRhcHAuZ29vZ2xlYXBpcy5j
b20vQmFja3VwVmF1bHRSBnBhcmVudBIrCg9iYWNrdXBfdmF1bHRfaWQYAiABKAlCA+BBAlIN
YmFja3VwVmF1bHRJZBJLCgxiYWNrdXBfdmF1bHQYAyABKAsyIy5nb29nbGUuY2xvdWQubmV0
YXBwLnYxLkJhY2t1cFZhdWx0QgPgQQJSC2JhY2t1cFZhdWx0IlkKGERlbGV0ZUJhY2t1cFZh
dWx0UmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIW5ldGFwcC5nb29nbGVhcGlzLmNv
bS9CYWNrdXBWYXVsdFIEbmFtZSKpAQoYVXBkYXRlQmFja3VwVmF1bHRSZXF1ZXN0EkAKC3Vw
ZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1cGRh
dGVNYXNrEksKDGJhY2t1cF92YXVsdBgCIAEoCzIjLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEu
QmFja3VwVmF1bHRCA+BBAlILYmFja3VwVmF1bHRCsgEKGmNvbS5nb29nbGUuY2xvdWQubmV0
YXBwLnYxQhBCYWNrdXBWYXVsdFByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vbmV0YXBw
L2FwaXYxL25ldGFwcHBiO25ldGFwcHBiqgIWR29vZ2xlLkNsb3VkLk5ldEFwcC5WMcoCFkdv
b2dsZVxDbG91ZFxOZXRBcHBcVjHqAhlHb29nbGU6OkNsb3VkOjpOZXRBcHA6OlYxSvJMCgcS
BQ4ArgIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAqCgkKAgMDEgMVACkKCAoBCBIDFwAzCgkK
AgglEgMXADMKCAoBCBIDGABJCgkKAggLEgMYAEkKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoB
CBIDGgAxCgkKAggIEgMaADEKCAoBCBIDGwAzCgkKAggBEgMbADMKCAoBCBIDHAAzCgkKAggp
EgMcADMKCAoBCBIDHQAyCgkKAggtEgMdADIKJAoCBAASBSAAywEBGhcgQSBOZXRBcHAgQmFj
a3VwVmF1bHQuCgoKCgMEAAESAyAIEwoLCgMEAAcSBCECJgQKDQoFBAAHnQgSBCECJgQKQAoE
BAADABIEKQJCAxoyIFJldGVudGlvbiBwb2xpY3kgZm9yIGJhY2t1cHMgaW4gdGhlIGJhY2t1
cCB2YXVsdAoKDAoFBAADAAESAykKHwpgCgYEAAMAAgASBCwELTEaUCBSZXF1aXJlZC4gTWlu
aW11bSByZXRlbnRpb24gZHVyYXRpb24gaW4gZGF5cyBmb3IgYmFja3VwcyBpbiB0aGUgYmFj
a3VwCiB2YXVsdC4KCg4KBwQAAwACAAUSAywECQoOCgcEAAMAAgABEgMsCjAKDgoHBAADAAIA
AxIDLDM0Cg4KBwQAAwACAAgSAy0IMAoRCgoEAAMAAgAInAgAEgMtCS8KzwEKBgQAAwACARID
MgRNGr8BIE9wdGlvbmFsLiBJbmRpY2F0ZXMgaWYgdGhlIGRhaWx5IGJhY2t1cHMgYXJlIGlt
bXV0YWJsZS4KIEF0IGxlYXN0IG9uZSBvZiBkYWlseV9iYWNrdXBfaW1tdXRhYmxlLCB3ZWVr
bHlfYmFja3VwX2ltbXV0YWJsZSwKIG1vbnRobHlfYmFja3VwX2ltbXV0YWJsZSBhbmQgbWFu
dWFsX2JhY2t1cF9pbW11dGFibGUgbXVzdCBiZSB0cnVlLgoKDgoHBAADAAIBBRIDMgQICg4K
BwQAAwACAQESAzIJHwoOCgcEAAMAAgEDEgMyIiMKDgoHBAADAAIBCBIDMiRMChEKCgQAAwAC
AQicCAASAzIlSwrQAQoGBAADAAICEgM3BE4awAEgT3B0aW9uYWwuIEluZGljYXRlcyBpZiB0
aGUgd2Vla2x5IGJhY2t1cHMgYXJlIGltbXV0YWJsZS4KIEF0IGxlYXN0IG9uZSBvZiBkYWls
eV9iYWNrdXBfaW1tdXRhYmxlLCB3ZWVrbHlfYmFja3VwX2ltbXV0YWJsZSwKIG1vbnRobHlf
YmFja3VwX2ltbXV0YWJsZSBhbmQgbWFudWFsX2JhY2t1cF9pbW11dGFibGUgbXVzdCBiZSB0
cnVlLgoKDgoHBAADAAICBRIDNwQICg4KBwQAAwACAgESAzcJIAoOCgcEAAMAAgIDEgM3IyQK
DgoHBAADAAICCBIDNyVNChEKCgQAAwACAgicCAASAzcmTArRAQoGBAADAAIDEgM8BE8awQEg
T3B0aW9uYWwuIEluZGljYXRlcyBpZiB0aGUgbW9udGhseSBiYWNrdXBzIGFyZSBpbW11dGFi
bGUuCiBBdCBsZWFzdCBvbmUgb2YgZGFpbHlfYmFja3VwX2ltbXV0YWJsZSwgd2Vla2x5X2Jh
Y2t1cF9pbW11dGFibGUsCiBtb250aGx5X2JhY2t1cF9pbW11dGFibGUgYW5kIG1hbnVhbF9i
YWNrdXBfaW1tdXRhYmxlIG11c3QgYmUgdHJ1ZS4KCg4KBwQAAwACAwUSAzwECAoOCgcEAAMA
AgMBEgM8CSEKDgoHBAADAAIDAxIDPCQlCg4KBwQAAwACAwgSAzwmTgoRCgoEAAMAAgMInAgA
EgM8J00K0AEKBgQAAwACBBIDQQROGsABIE9wdGlvbmFsLiBJbmRpY2F0ZXMgaWYgdGhlIG1h
bnVhbCBiYWNrdXBzIGFyZSBpbW11dGFibGUuCiBBdCBsZWFzdCBvbmUgb2YgZGFpbHlfYmFj
a3VwX2ltbXV0YWJsZSwgd2Vla2x5X2JhY2t1cF9pbW11dGFibGUsCiBtb250aGx5X2JhY2t1
cF9pbW11dGFibGUgYW5kIG1hbnVhbF9iYWNrdXBfaW1tdXRhYmxlIG11c3QgYmUgdHJ1ZS4K
Cg4KBwQAAwACBAUSA0EECAoOCgcEAAMAAgQBEgNBCSAKDgoHBAADAAIEAxIDQSMkCg4KBwQA
AwACBAgSA0ElTQoRCgoEAAMAAgQInAgAEgNBJkwKJwoEBAAEABIERQJXAxoZIFRoZSBCYWNr
dXAgVmF1bHQgU3RhdGVzCgoMCgUEAAQAARIDRQcMCh8KBgQABAACABIDRwQaGhAgU3RhdGUg
bm90IHNldC4KCg4KBwQABAACAAESA0cEFQoOCgcEAAQAAgACEgNHGBkKLgoGBAAEAAIBEgNK
BBEaHyBCYWNrdXBWYXVsdCBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDSgQMCg4K
BwQABAACAQISA0oPEAoyCgYEAAQAAgISA00EDhojIEJhY2t1cFZhdWx0IGlzIGF2YWlsYWJs
ZSBmb3IgdXNlLgoKDgoHBAAEAAICARIDTQQJCg4KBwQABAACAgISA00MDQouCgYEAAQAAgMS
A1AEERofIEJhY2t1cFZhdWx0IGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgMBEgNQBAwK
DgoHBAAEAAIDAhIDUA8QCj0KBgQABAACBBIDUwQOGi4gQmFja3VwVmF1bHQgaXMgbm90IHZh
bGlkIGFuZCBjYW5ub3QgYmUgdXNlZC4KCg4KBwQABAACBAESA1MECQoOCgcEAAQAAgQCEgNT
DA0KLgoGBAAEAAIFEgNWBBEaHyBCYWNrdXBWYXVsdCBpcyBiZWluZyB1cGRhdGVkLgoKDgoH
BAAEAAIFARIDVgQMCg4KBwQABAACBQISA1YPEAoiCgQEAAQBEgRaAmMDGhQgQmFja3VwIFZh
dWx0IFR5cGUuCgoMCgUEAAQBARIDWgcWCioKBgQABAECABIDXAQmGhsgQmFja3VwVmF1bHQg
dHlwZSBub3Qgc2V0LgoKDgoHBAAEAQIAARIDXAQhCg4KBwQABAECAAISA1wkJQovCgYEAAQB
AgESA18EEhogIEJhY2t1cFZhdWx0IHR5cGUgaXMgSU5fUkVHSU9OLgoKDgoHBAAEAQIBARID
XwQNCg4KBwQABAECAQISA18QEQoyCgYEAAQBAgISA2IEFRojIEJhY2t1cFZhdWx0IHR5cGUg
aXMgQ1JPU1NfUkVHSU9OLgoKDgoHBAAEAQICARIDYgQQCg4KBwQABAECAgISA2ITFApUCgQE
AAQCEgRmAnUDGkYgRW5jcnlwdGlvbiBzdGF0ZSBvZiBjdXN0b21lci1tYW5hZ2VkIGVuY3J5
cHRpb24ga2V5cyAoQ01FSykgYmFja3Vwcy4KCgwKBQQABAIBEgNmBxYKKgoGBAAEAgIAEgNo
BCUaGyBFbmNyeXB0aW9uIHN0YXRlIG5vdCBzZXQuCgoOCgcEAAQCAgABEgNoBCAKDgoHBAAE
AgIAAhIDaCMkCi0KBgQABAICARIDawQhGh4gRW5jcnlwdGlvbiBzdGF0ZSBpcyBwZW5kaW5n
LgoKDgoHBAAEAgIBARIDawQcCg4KBwQABAICAQISA2sfIAooCgYEAAQCAgISA24EIxoZIEVu
Y3J5cHRpb24gaXMgY29tcGxldGUuCgoOCgcEAAQCAgIBEgNuBB4KDgoHBAAEAgICAhIDbiEi
CisKBgQABAICAxIDcQQlGhwgRW5jcnlwdGlvbiBpcyBpbiBwcm9ncmVzcy4KCg4KBwQABAIC
AwESA3EEIAoOCgcEAAQCAgMCEgNxIyQKJwoGBAAEAgIEEgN0BCAaGCBFbmNyeXB0aW9uIGhh
cyBmYWlsZWQuCgoOCgcEAAQCAgQBEgN0BBsKDgoHBAAEAgIEAhIDdB4fCpkBCgQEAAIAEgN6
Aj0aiwEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGJhY2t1cCB2YXVs
dC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYmFja3VwVmF1bHRzL3tiYWNrdXBfdmF1bHRfaWR9YC4KCgwKBQQAAgAFEgN6AggKDAoF
BAACAAESA3oJDQoMCgUEAAIAAxIDehARCgwKBQQAAgAIEgN6EjwKDwoIBAACAAicCAASA3oT
OwozCgQEAAIBEgN9Aj4aJiBPdXRwdXQgb25seS4gVGhlIGJhY2t1cCB2YXVsdCBzdGF0ZS4K
CgwKBQQAAgEGEgN9AgcKDAoFBAACAQESA30IDQoMCgUEAAIBAxIDfRARCgwKBQQAAgEIEgN9
Ej0KDwoIBAACAQicCAASA30TPAo/CgQEAAICEgaAAQKBATIaLyBPdXRwdXQgb25seS4gQ3Jl
YXRlIHRpbWUgb2YgdGhlIGJhY2t1cCB2YXVsdC4KCg0KBQQAAgIGEgSAAQIbCg0KBQQAAgIB
EgSAARwnCg0KBQQAAgIDEgSAASorCg0KBQQAAgIIEgSBAQYxChAKCAQAAgIInAgAEgSBAQcw
CjAKBAQAAgMSBIQBAhkaIiBEZXNjcmlwdGlvbiBvZiB0aGUgYmFja3VwIHZhdWx0LgoKDQoF
BAACAwUSBIQBAggKDQoFBAACAwESBIQBCRQKDQoFBAACAwMSBIQBFxgKRAoEBAACBBIEhwEC
IRo2IFJlc291cmNlIGxhYmVscyB0byByZXByZXNlbnQgdXNlciBwcm92aWRlZCBtZXRhZGF0
YS4KCg0KBQQAAgQGEgSHAQIVCg0KBQQAAgQBEgSHARYcCg0KBQQAAgQDEgSHAR8gClYKBAQA
AgUSBosBAowBLxpGIE9wdGlvbmFsLiBUeXBlIG9mIGJhY2t1cCB2YXVsdCB0byBiZSBjcmVh
dGVkLgogRGVmYXVsdCBpcyBJTl9SRUdJT04uCgoNCgUEAAIFBhIEiwECEQoNCgUEAAIFARIE
iwESIwoNCgUEAAIFAxIEiwEmJwoNCgUEAAIFCBIEjAEGLgoQCggEAAIFCJwIABIEjAEHLQp+
CgQEAAIGEgaQAQKVAQQabiBPcHRpb25hbC4gUmVnaW9uIGluIHdoaWNoIHRoZSBiYWNrdXAg
dmF1bHQgaXMgY3JlYXRlZC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2Nh
dGlvbnMve2xvY2F0aW9ufWAKCg0KBQQAAgYFEgSQAQIICg0KBQQAAgYBEgSQAQkWCg0KBQQA
AgYDEgSQARkaCg8KBQQAAgYIEgaQARuVAQMKEAoIBAACBgicCAASBJEBBCoKEQoHBAACBgif
CBIGkgEElAEFCnYKBAQAAgcSBpkBAp4BBBpmIE9wdGlvbmFsLiBSZWdpb24gd2hlcmUgdGhl
IGJhY2t1cHMgYXJlIHN0b3JlZC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0X2lkfS9s
b2NhdGlvbnMve2xvY2F0aW9ufWAKCg0KBQQAAgcFEgSZAQIICg0KBQQAAgcBEgSZAQkWCg0K
BQQAAgcDEgSZARkaCg8KBQQAAgcIEgaZARueAQMKEAoIBAACBwicCAASBJoBBCoKEQoHBAAC
BwifCBIGmwEEnQEFCqgBCgQEAAIIEgajAQKoAQQalwEgT3V0cHV0IG9ubHkuIE5hbWUgb2Yg
dGhlIEJhY2t1cCB2YXVsdCBjcmVhdGVkIGluIHNvdXJjZSByZWdpb24uCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1cFZhdWx0
cy97YmFja3VwX3ZhdWx0X2lkfWAKCg0KBQQAAggFEgSjAQIICg0KBQQAAggBEgSjAQkcCg0K
BQQAAggDEgSjAR8gCg8KBQQAAggIEgajASGoAQMKEAoIBAACCAicCAASBKQBBC0KEQoHBAAC
CAifCBIGpQEEpwEFCqgBCgQEAAIJEgatAQKyAQQalwEgT3V0cHV0IG9ubHkuIE5hbWUgb2Yg
dGhlIEJhY2t1cCB2YXVsdCBjcmVhdGVkIGluIGJhY2t1cCByZWdpb24uCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1cFZhdWx0
cy97YmFja3VwX3ZhdWx0X2lkfWAKCg0KBQQAAgkFEgStAQIICg0KBQQAAgkBEgStAQkhCg0K
BQQAAgkDEgStASQmCg8KBQQAAgkIEgatASeyAQMKEAoIBAACCQicCAASBK4BBC0KEQoHBAAC
CQifCBIGrwEEsQEFClYKBAQAAgoSBrUBArYBLxpGIE9wdGlvbmFsLiBCYWNrdXAgcmV0ZW50
aW9uIHBvbGljeSBkZWZpbmluZyB0aGUgcmV0ZW50aW9uIG9mIGJhY2t1cHMuCgoNCgUEAAIK
BhIEtQECFwoNCgUEAAIKARIEtQEYLwoNCgUEAAIKAxIEtQEyNAoNCgUEAAIKCBIEtgEGLgoQ
CggEAAIKCJwIABIEtgEHLQrCAQoEBAACCxIGuwECwAEEGrEBIE9wdGlvbmFsLiBTcGVjaWZp
ZXMgdGhlIEtleSBNYW5hZ2VtZW50IFN5c3RlbSAoS01TKSBjb25maWd1cmF0aW9uIHRvIGJl
CiB1c2VkIGZvciBiYWNrdXAgZW5jcnlwdGlvbi4gRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9rbXNDb25maWdzL3trbXNfY29uZmlnfWAKCg0K
BQQAAgsFEgS7AQIICg0KBQQAAgsBEgS7AQkTCg0KBQQAAgsDEgS7ARYYCg8KBQQAAgsIEga7
ARnAAQMKEAoIBAACCwicCAASBLwBBCoKEQoHBAACCwifCBIGvQEEvwEFClEKBAQAAgwSBsMB
AsQBMhpBIE91dHB1dCBvbmx5LiBGaWVsZCBpbmRpY2F0aW5nIGVuY3J5cHRpb24gc3RhdGUg
b2YgQ01FSyBiYWNrdXBzLgoKDQoFBAACDAYSBMMBAhEKDQoFBAACDAESBMMBEiIKDQoFBAAC
DAMSBMMBJScKDQoFBAACDAgSBMQBBjEKEAoIBAACDAicCAASBMQBBzAK3wEKBAQAAg0SBskB
AsoBMhrOASBPdXRwdXQgb25seS4gVGhlIGNyeXB0byBrZXkgdmVyc2lvbiB1c2VkIHRvIGVu
Y3J5cHQgdGhlIGJhY2t1cCB2YXVsdC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlzL3tj
cnlwdG9fa2V5fS9jcnlwdG9LZXlWZXJzaW9ucy97Y3J5cHRvX2tleV92ZXJzaW9ufWAKCg0K
BQQAAg0FEgTJAQIICg0KBQQAAg0BEgTJAQkjCg0KBQQAAg0DEgTJASYoCg0KBQQAAg0IEgTK
AQYxChAKCAQAAg0InAgAEgTKAQcwCkYKAgQBEgbOAQDXAQEaOCBHZXRCYWNrdXBWYXVsdFJl
cXVlc3QgZ2V0cyB0aGUgc3RhdGUgb2YgYSBiYWNrdXBWYXVsdC4KCgsKAwQBARIEzgEIHQqW
AQoEBAECABIG0QEC1gEEGoUBIFJlcXVpcmVkLiBUaGUgYmFja3VwVmF1bHQgcmVzb3VyY2Ug
bmFtZSwgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9iYWNrdXBWYXVsdHMve2JhY2t1cF92YXVsdF9pZH1gCgoNCgUEAQIABRIE
0QECCAoNCgUEAQIAARIE0QEJDQoNCgUEAQIAAxIE0QEQEQoPCgUEAQIACBIG0QES1gEDChAK
CAQBAgAInAgAEgTSAQQqChEKBwQBAgAInwgSBtMBBNUBBQo7CgIEAhIG2gEA8QEBGi0gTGlz
dEJhY2t1cFZhdWx0c1JlcXVlc3QgbGlzdHMgYmFja3VwVmF1bHRzLgoKCwoDBAIBEgTaAQgf
CpYBCgQEAgIAEgbeAQLjAQQahQEgUmVxdWlyZWQuIFRoZSBsb2NhdGlvbiBmb3Igd2hpY2gg
dG8gcmV0cmlldmUgYmFja3VwVmF1bHQgaW5mb3JtYXRpb24sCiBpbiB0aGUgZm9ybWF0CiBg
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCg0KBQQCAgAF
EgTeAQIICg0KBQQCAgABEgTeAQkPCg0KBQQCAgADEgTeARITCg8KBQQCAgAIEgbeARTjAQMK
EAoIBAICAAicCAASBN8BBCoKEQoHBAICAAifCBIG4AEE4gEFCjYKBAQCAgESBOYBAhYaKCBU
aGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuLgoKDQoFBAICAQUSBOYBAgcK
DQoFBAICAQESBOYBCBEKDQoFBAICAQMSBOYBFBUKdAoEBAICAhIE6gECGBpmIFRoZSBuZXh0
X3BhZ2VfdG9rZW4gdmFsdWUgdG8gdXNlIGlmIHRoZXJlIGFyZSBhZGRpdGlvbmFsCiByZXN1
bHRzIHRvIHJldHJpZXZlIGZvciB0aGlzIGxpc3QgcmVxdWVzdC4KCg0KBQQCAgIFEgTqAQII
Cg0KBQQCAgIBEgTqAQkTCg0KBQQCAgIDEgTqARYXClgKBAQCAgMSBO0BAhYaSiBTb3J0IHJl
c3VsdHMuIFN1cHBvcnRlZCB2YWx1ZXMgYXJlICJuYW1lIiwgIm5hbWUgZGVzYyIgb3IgIiIg
KHVuc29ydGVkKS4KCg0KBQQCAgMFEgTtAQIICg0KBQQCAgMBEgTtAQkRCg0KBQQCAgMDEgTt
ARQVChwKBAQCAgQSBPABAhQaDiBMaXN0IGZpbHRlci4KCg0KBQQCAgQFEgTwAQIICg0KBQQC
AgQBEgTwAQkPCg0KBQQCAgQDEgTwARITClIKAgQDEgb0AQD+AQEaRCBMaXN0QmFja3VwVmF1
bHRzUmVzcG9uc2UgaXMgdGhlIHJlc3VsdCBvZiBMaXN0QmFja3VwVmF1bHRzUmVxdWVzdC4K
CgsKAwQDARIE9AEIIApRCgQEAwIAEgT2AQIpGkMgQSBsaXN0IG9mIGJhY2t1cFZhdWx0cyBp
biB0aGUgcHJvamVjdCBmb3IgdGhlIHNwZWNpZmllZCBsb2NhdGlvbi4KCg0KBQQDAgAEEgT2
AQIKCg0KBQQDAgAGEgT2AQsWCg0KBQQDAgABEgT2ARckCg0KBQQDAgADEgT2AScoCoMBCgQE
AwIBEgT6AQIdGnUgVGhlIHRva2VuIHlvdSBjYW4gdXNlIHRvIHJldHJpZXZlIHRoZSBuZXh0
IHBhZ2Ugb2YgcmVzdWx0cy4gTm90IHJldHVybmVkCiBpZiB0aGVyZSBhcmUgbm8gbW9yZSBy
ZXN1bHRzIGluIHRoZSBsaXN0LgoKDQoFBAMCAQUSBPoBAggKDQoFBAMCAQESBPoBCRgKDQoF
BAMCAQMSBPoBGxwKNAoEBAMCAhIE/QECIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBi
ZSByZWFjaGVkLgoKDQoFBAMCAgQSBP0BAgoKDQoFBAMCAgUSBP0BCxEKDQoFBAMCAgESBP0B
Eh0KDQoFBAMCAgMSBP0BICEKQAoCBAQSBoECAJQCARoyIENyZWF0ZUJhY2t1cFZhdWx0UmVx
dWVzdCBjcmVhdGVzIGEgYmFja3VwIHZhdWx0LgoKCwoDBAQBEgSBAgggCoEBCgQEBAIAEgaE
AgKJAgQacSBSZXF1aXJlZC4gVGhlIGxvY2F0aW9uIHRvIGNyZWF0ZSB0aGUgYmFja3VwIHZh
dWx0cywgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMv
e2xvY2F0aW9ufWAKCg0KBQQEAgAFEgSEAgIICg0KBQQEAgABEgSEAgkPCg0KBQQEAgADEgSE
AhITCg8KBQQEAgAIEgaEAhSJAgMKEAoIBAQCAAicCAASBIUCBCoKEQoHBAQCAAifCBIGhgIE
iAIFCoMCCgQEBAIBEgSQAgJGGvQBIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUg
YmFja3VwVmF1bHQuCiBUaGUgSUQgbXVzdCBiZSB1bmlxdWUgd2l0aGluIHRoZSBzcGVjaWZp
ZWQgbG9jYXRpb24uCiBNdXN0IGNvbnRhaW4gb25seSBsZXR0ZXJzLCBudW1iZXJzIGFuZCBo
eXBoZW4sIHdpdGggdGhlIGZpcnN0CiBjaGFyYWN0ZXIgYSBsZXR0ZXIsIHRoZSBsYXN0IGEg
bGV0dGVyIG9yIGEKIG51bWJlciwgYW5kIGEgNjMgY2hhcmFjdGVyIG1heGltdW0uCgoNCgUE
BAIBBRIEkAICCAoNCgUEBAIBARIEkAIJGAoNCgUEBAIBAxIEkAIbHAoNCgUEBAIBCBIEkAId
RQoQCggEBAIBCJwIABIEkAIeRAowCgQEBAICEgSTAgJIGiIgUmVxdWlyZWQuIEEgYmFja3Vw
VmF1bHQgcmVzb3VyY2UKCg0KBQQEAgIGEgSTAgINCg0KBQQEAgIBEgSTAg4aCg0KBQQEAgID
EgSTAh0eCg0KBQQEAgIIEgSTAh9HChAKCAQEAgIInAgAEgSTAiBGCj8KAgQFEgaXAgCgAgEa
MSBEZWxldGVCYWNrdXBWYXVsdFJlcXVlc3QgZGVsZXRlcyBhIGJhY2t1cFZhdWx0LgoKCwoD
BAUBEgSXAgggCpYBCgQEBQIAEgaaAgKfAgQahQEgUmVxdWlyZWQuIFRoZSBiYWNrdXBWYXVs
dCByZXNvdXJjZSBuYW1lLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3RfaWR9
L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1cFZhdWx0cy97YmFja3VwX3ZhdWx0X2lkfWAK
Cg0KBQQFAgAFEgSaAgIICg0KBQQFAgABEgSaAgkNCg0KBQQFAgADEgSaAhARCg8KBQQFAgAI
EgaaAhKfAgMKEAoIBAUCAAicCAASBJsCBCoKEQoHBAUCAAifCBIGnAIEngIFCl0KAgQGEgaj
AgCuAgEaTyBVcGRhdGVCYWNrdXBWYXVsdFJlcXVlc3QgdXBkYXRlcyBkZXNjcmlwdGlvbiBh
bmQvb3IgbGFiZWxzIGZvciBhIGJhY2t1cFZhdWx0LgoKCwoDBAYBEgSjAgggCtgCCgQEBgIA
EgapAgKqAi8axwIgUmVxdWlyZWQuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRo
ZSBmaWVsZHMgdG8gYmUgb3ZlcndyaXR0ZW4gaW4gdGhlCiBCYWNrdXAgcmVzb3VyY2UgdG8g
YmUgdXBkYXRlZC4KIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBh
cmUgcmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEg
ZmllbGQgd2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4gSWYgdGhl
CiB1c2VyIGRvZXMgbm90IHByb3ZpZGUgYSBtYXNrIHRoZW4gYWxsIGZpZWxkcyB3aWxsIGJl
IG92ZXJ3cml0dGVuLgoKDQoFBAYCAAYSBKkCAhsKDQoFBAYCAAESBKkCHCcKDQoFBAYCAAMS
BKkCKisKDQoFBAYCAAgSBKoCBi4KEAoIBAYCAAicCAASBKoCBy0KNwoEBAYCARIErQICSBop
IFJlcXVpcmVkLiBUaGUgYmFja3VwVmF1bHQgYmVpbmcgdXBkYXRlZAoKDQoFBAYCAQYSBK0C
Ag0KDQoFBAYCAQESBK0CDhoKDQoFBAYCAQMSBK0CHR4KDQoFBAYCAQgSBK0CH0cKEAoIBAYC
AQicCAASBK0CIEZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::BackupVault::BackupVault ===
    # Fields for BackupVault
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.netapp.v1.BackupVault.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.netapp.v1.BackupVault.LabelsEntry)
    # Field: backup_vault_type Type: 14 (.google.cloud.netapp.v1.BackupVault.BackupVaultType)
    # Field: source_region Type: 9 ()
    # Field: backup_region Type: 9 ()
    # Field: source_backup_vault Type: 9 ()
    # Field: destination_backup_vault Type: 9 ()
    # Field: backup_retention_policy Type: 11 (.google.cloud.netapp.v1.BackupVault.BackupRetentionPolicy)
    # Field: kms_config Type: 9 ()
    # Field: encryption_state Type: 14 (.google.cloud.netapp.v1.BackupVault.EncryptionState)
    # Field: backups_crypto_key_version Type: 9 ()

# Enum: BackupVault::State
our $BackupVault_STATE_UNSPECIFIED = 0;
our $BackupVault_CREATING = 1;
our $BackupVault_READY = 2;
our $BackupVault_DELETING = 3;
our $BackupVault_ERROR = 4;
our $BackupVault_UPDATING = 5;

# Enum: BackupVault::BackupVaultType
our $BackupVault_BACKUP_VAULT_TYPE_UNSPECIFIED = 0;
our $BackupVault_IN_REGION = 1;
our $BackupVault_CROSS_REGION = 2;

# Enum: BackupVault::EncryptionState
our $BackupVault_ENCRYPTION_STATE_UNSPECIFIED = 0;
our $BackupVault_ENCRYPTION_STATE_PENDING = 1;
our $BackupVault_ENCRYPTION_STATE_COMPLETED = 2;
our $BackupVault_ENCRYPTION_STATE_IN_PROGRESS = 3;
our $BackupVault_ENCRYPTION_STATE_FAILED = 4;

# === Message: Google::Cloud::Netapp::V1::BackupVault::GetBackupVaultRequest ===
    # Fields for GetBackupVaultRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsRequest ===
    # Fields for ListBackupVaultsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsResponse ===
    # Fields for ListBackupVaultsResponse
    # Field: backup_vaults Type: 11 (.google.cloud.netapp.v1.BackupVault)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::BackupVault::CreateBackupVaultRequest ===
    # Fields for CreateBackupVaultRequest
    # Field: parent Type: 9 ()
    # Field: backup_vault_id Type: 9 ()
    # Field: backup_vault Type: 11 (.google.cloud.netapp.v1.BackupVault)

# === Message: Google::Cloud::Netapp::V1::BackupVault::DeleteBackupVaultRequest ===
    # Fields for DeleteBackupVaultRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::BackupVault::UpdateBackupVaultRequest ===
    # Fields for UpdateBackupVaultRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: backup_vault Type: 11 (.google.cloud.netapp.v1.BackupVault)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::BackupVault - Compiled Protocol Buffers messages for google/cloud/netapp/v1/backup_vault.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::BackupVault;

    my $msg = Google::Cloud::Netapp::V1::BackupVault::BackupVault->new({
        name => $name,
        state => $state,
        create_time => $create_time,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::BackupVault::BackupVault->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/backup_vault.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::BackupVault::BackupVault

A NetApp BackupVault.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the backup vault.
Format:
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::BackupVault::State>)

Output only. The backup vault state.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the backup vault.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the backup vault.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupVault::BackupVault::LabelsEntry>)

Resource labels to represent user provided metadata.

=item * C<< $msg->backup_vault_type() >> / C<< $msg->backup_vault_type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::BackupVault::BackupVaultType>)

Optional. Type of backup vault to be created.
Default is IN_REGION.

=item * C<< $msg->source_region() >> / C<< $msg->source_region($value) >>

Type: C<String>

Optional. Region in which the backup vault is created.
Format: `projects/{project_id}/locations/{location}`

=item * C<< $msg->backup_region() >> / C<< $msg->backup_region($value) >>

Type: C<String>

Optional. Region where the backups are stored.
Format: `projects/{project_id}/locations/{location}`

=item * C<< $msg->source_backup_vault() >> / C<< $msg->source_backup_vault($value) >>

Type: C<String>

Output only. Name of the Backup vault created in source region.
Format:
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}`

=item * C<< $msg->destination_backup_vault() >> / C<< $msg->destination_backup_vault($value) >>

Type: C<String>

Output only. Name of the Backup vault created in backup region.
Format:
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}`

=item * C<< $msg->backup_retention_policy() >> / C<< $msg->backup_retention_policy($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupVault::BackupVault::BackupRetentionPolicy>)

Optional. Backup retention policy defining the retention of backups.

=item * C<< $msg->kms_config() >> / C<< $msg->kms_config($value) >>

Type: C<String>

Optional. Specifies the Key Management System (KMS) configuration to be
used for backup encryption. Format:
`projects/{project}/locations/{location}/kmsConfigs/{kms_config}`

=item * C<< $msg->encryption_state() >> / C<< $msg->encryption_state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::BackupVault::EncryptionState>)

Output only. Field indicating encryption state of CMEK backups.

=item * C<< $msg->backups_crypto_key_version() >> / C<< $msg->backups_crypto_key_version($value) >>

Type: C<String>

Output only. The crypto key version used to encrypt the backup vault.
Format:
`projects/{project}/locations/{location}/keyRings/{key_ring}/cryptoKeys/{crypto_key}/cryptoKeyVersions/{crypto_key_version}`

=back

=head3 Enum: BackupVault::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<DELETING> => C<3>

=item * C<ERROR> => C<4>

=item * C<UPDATING> => C<5>

=back

=head3 Enum: BackupVault::BackupVaultType

=over 4

=item * C<BACKUP_VAULT_TYPE_UNSPECIFIED> => C<0>

=item * C<IN_REGION> => C<1>

=item * C<CROSS_REGION> => C<2>

=back

=head3 Enum: BackupVault::EncryptionState

=over 4

=item * C<ENCRYPTION_STATE_UNSPECIFIED> => C<0>

=item * C<ENCRYPTION_STATE_PENDING> => C<1>

=item * C<ENCRYPTION_STATE_COMPLETED> => C<2>

=item * C<ENCRYPTION_STATE_IN_PROGRESS> => C<3>

=item * C<ENCRYPTION_STATE_FAILED> => C<4>

=back

=head2 Google::Cloud::Netapp::V1::BackupVault::GetBackupVaultRequest

GetBackupVaultRequest gets the state of a backupVault.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The backupVault resource name, in the format
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}`

=back

=head2 Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsRequest

ListBackupVaultsRequest lists backupVaults.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location for which to retrieve backupVault information,
in the format
`projects/{project_id}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value to use if there are additional
results to retrieve for this list request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Sort results. Supported values are "name", "name desc" or "" (unsorted).

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

List filter.

=back

=head2 Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsResponse

ListBackupVaultsResponse is the result of ListBackupVaultsRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_vaults() >> / C<< $msg->backup_vaults($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupVault::BackupVault>)

A list of backupVaults in the project for the specified location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token you can use to retrieve the next page of results. Not returned
if there are no more results in the list.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::BackupVault::CreateBackupVaultRequest

CreateBackupVaultRequest creates a backup vault.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location to create the backup vaults, in the format
`projects/{project_id}/locations/{location}`

=item * C<< $msg->backup_vault_id() >> / C<< $msg->backup_vault_id($value) >>

Type: C<String>

Required. The ID to use for the backupVault.
The ID must be unique within the specified location.
Must contain only letters, numbers and hyphen, with the first
character a letter, the last a letter or a
number, and a 63 character maximum.

=item * C<< $msg->backup_vault() >> / C<< $msg->backup_vault($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupVault::BackupVault>)

Required. A backupVault resource

=back

=head2 Google::Cloud::Netapp::V1::BackupVault::DeleteBackupVaultRequest

DeleteBackupVaultRequest deletes a backupVault.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The backupVault resource name, in the format
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}`

=back

=head2 Google::Cloud::Netapp::V1::BackupVault::UpdateBackupVaultRequest

UpdateBackupVaultRequest updates description and/or labels for a backupVault.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
Backup resource to be updated.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->backup_vault() >> / C<< $msg->backup_vault($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::BackupVault::BackupVault>)

Required. The backupVault being updated

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::BackupVault::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
