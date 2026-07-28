package Google::Cloud::Sql::V1::CloudSqlBackupRuns;

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
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9iYWNrdXBfcnVucy5wcm90bxITZ29v
Z2xlLmNsb3VkLnNxbC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aLWdv
b2dsZS9jbG91ZC9zcWwvdjEvY2xvdWRfc3FsX3Jlc291cmNlcy5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byJiChpTcWxCYWNrdXBSdW5zRGVsZXRlUmVxdWVzdBIO
CgJpZBgBIAEoA1ICaWQSGgoIaW5zdGFuY2UYAiABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QY
AyABKAlSB3Byb2plY3QiXwoXU3FsQmFja3VwUnVuc0dldFJlcXVlc3QSDgoCaWQYASABKANS
AmlkEhoKCGluc3RhbmNlGAIgASgJUghpbnN0YW5jZRIYCgdwcm9qZWN0GAMgASgJUgdwcm9q
ZWN0IoYBChpTcWxCYWNrdXBSdW5zSW5zZXJ0UmVxdWVzdBIaCghpbnN0YW5jZRgBIAEoCVII
aW5zdGFuY2USGAoHcHJvamVjdBgCIAEoCVIHcHJvamVjdBIyCgRib2R5GGQgASgLMh4uZ29v
Z2xlLmNsb3VkLnNxbC52MS5CYWNrdXBSdW5SBGJvZHkikAEKGFNxbEJhY2t1cFJ1bnNMaXN0
UmVxdWVzdBIaCghpbnN0YW5jZRgBIAEoCVIIaW5zdGFuY2USHwoLbWF4X3Jlc3VsdHMYAiAB
KAVSCm1heFJlc3VsdHMSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEhgKB3Byb2pl
Y3QYBCABKAlSB3Byb2plY3QivwgKCUJhY2t1cFJ1bhISCgRraW5kGAEgASgJUgRraW5kEj8K
BnN0YXR1cxgCIAEoDjInLmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsQmFja3VwUnVuU3RhdHVz
UgZzdGF0dXMSPwoNZW5xdWV1ZWRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSDGVucXVldWVkVGltZRIOCgJpZBgEIAEoA1ICaWQSOQoKc3RhcnRfdGltZRgFIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgG
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSOQoFZXJyb3IYByAB
KAsyIy5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbkVycm9yUgVlcnJvchI5CgR0eXBl
GAggASgOMiUuZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxCYWNrdXBSdW5UeXBlUgR0eXBlEiAK
C2Rlc2NyaXB0aW9uGAkgASgJUgtkZXNjcmlwdGlvbhJGChF3aW5kb3dfc3RhcnRfdGltZRgK
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSD3dpbmRvd1N0YXJ0VGltZRIaCghp
bnN0YW5jZRgLIAEoCVIIaW5zdGFuY2USGwoJc2VsZl9saW5rGAwgASgJUghzZWxmTGluaxIa
Cghsb2NhdGlvbhgNIAEoCVIIbG9jYXRpb24SVwoQZGF0YWJhc2VfdmVyc2lvbhgPIAEoDjIn
Lmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsRGF0YWJhc2VWZXJzaW9uQgPgQQNSD2RhdGFiYXNl
VmVyc2lvbhJ0Ch1kaXNrX2VuY3J5cHRpb25fY29uZmlndXJhdGlvbhgQIAEoCzIwLmdvb2ds
ZS5jbG91ZC5zcWwudjEuRGlza0VuY3J5cHRpb25Db25maWd1cmF0aW9uUhtkaXNrRW5jcnlw
dGlvbkNvbmZpZ3VyYXRpb24SXwoWZGlza19lbmNyeXB0aW9uX3N0YXR1cxgRIAEoCzIpLmdv
b2dsZS5jbG91ZC5zcWwudjEuRGlza0VuY3J5cHRpb25TdGF0dXNSFGRpc2tFbmNyeXB0aW9u
U3RhdHVzEkMKC2JhY2t1cF9raW5kGBMgASgOMiIuZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxC
YWNrdXBLaW5kUgpiYWNrdXBLaW5kEhsKCXRpbWVfem9uZRgXIAEoCVIIdGltZVpvbmUSOgoU
bWF4X2NoYXJnZWFibGVfYnl0ZXMYGCABKANCA+BBA0gAUhJtYXhDaGFyZ2VhYmxlQnl0ZXOI
AQFCFwoVX21heF9jaGFyZ2VhYmxlX2J5dGVzIooBChZCYWNrdXBSdW5zTGlzdFJlc3BvbnNl
EhIKBGtpbmQYASABKAlSBGtpbmQSNAoFaXRlbXMYAiADKAsyHi5nb29nbGUuY2xvdWQuc3Fs
LnYxLkJhY2t1cFJ1blIFaXRlbXMSJgoPbmV4dF9wYWdlX3Rva2VuGAMgASgJUg1uZXh0UGFn
ZVRva2VuKsQBChJTcWxCYWNrdXBSdW5TdGF0dXMSJQohU1FMX0JBQ0tVUF9SVU5fU1RBVFVT
X1VOU1BFQ0lGSUVEEAASDAoIRU5RVUVVRUQQARILCgdPVkVSRFVFEAISCwoHUlVOTklORxAD
EgoKBkZBSUxFRBAEEg4KClNVQ0NFU1NGVUwQBRILCgdTS0lQUEVEEAYSFAoQREVMRVRJT05f
UEVORElORxAHEhMKD0RFTEVUSU9OX0ZBSUxFRBAIEgsKB0RFTEVURUQQCSpMCg1TcWxCYWNr
dXBLaW5kEh8KG1NRTF9CQUNLVVBfS0lORF9VTlNQRUNJRklFRBAAEgwKCFNOQVBTSE9UEAES
DAoIUEhZU0lDQUwQAipVChBTcWxCYWNrdXBSdW5UeXBlEiMKH1NRTF9CQUNLVVBfUlVOX1RZ
UEVfVU5TUEVDSUZJRUQQABINCglBVVRPTUFURUQQARINCglPTl9ERU1BTkQQAjKXBgoUU3Fs
QmFja3VwUnVuc1NlcnZpY2USngEKBkRlbGV0ZRIvLmdvb2dsZS5jbG91ZC5zcWwudjEuU3Fs
QmFja3VwUnVuc0RlbGV0ZVJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlv
biJDgtPkkwI9KjsvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9
L2JhY2t1cFJ1bnMve2lkfRKYAQoDR2V0EiwuZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxCYWNr
dXBSdW5zR2V0UmVxdWVzdBoeLmdvb2dsZS5jbG91ZC5zcWwudjEuQmFja3VwUnVuIkOC0+ST
Aj0SOy92MS9wcm9qZWN0cy97cHJvamVjdH0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vYmFja3Vw
UnVucy97aWR9Ep8BCgZJbnNlcnQSLy5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbEJhY2t1cFJ1
bnNJbnNlcnRSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnNxbC52MS5PcGVyYXRpb24iRILT5JMC
PiI2L3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNlfS9iYWNrdXBS
dW5zOgRib2R5EqIBCgRMaXN0Ei0uZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxCYWNrdXBSdW5z
TGlzdFJlcXVlc3QaKy5nb29nbGUuY2xvdWQuc3FsLnYxLkJhY2t1cFJ1bnNMaXN0UmVzcG9u
c2UiPoLT5JMCOBI2L3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3RhbmNl
fS9iYWNrdXBSdW5zGnzKQRdzcWxhZG1pbi5nb29nbGVhcGlzLmNvbdJBX2h0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9zcWxzZXJ2aWNlLmFkbWluQl8KF2NvbS5nb29nbGUuY2xvdWQuc3Fs
LnYxQhdDbG91ZFNxbEJhY2t1cFJ1bnNQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL3Nx
bC9hcGl2MS9zcWxwYjtzcWxwYkq1QQoHEgUOAI0CAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQA
KQoJCgIDAxIDFQA3CgkKAgMEEgMWACkKCAoBCBIDGABACgkKAggLEgMYAEAKCAoBCBIDGQAi
CgkKAggKEgMZACIKCAoBCBIDGgA4CgkKAggIEgMaADgKCAoBCBIDGwAwCgkKAggBEgMbADAK
NAoCBgASBB4AQgEaKCBTZXJ2aWNlIGZvciBtYW5hZ2luZyBkYXRhYmFzZSBiYWNrdXBzLgoK
CgoDBgABEgMeCBwKCgoDBgADEgMfAj8KDAoFBgADmQgSAx8CPwoLCgMGAAMSBCACIjkKDQoF
BgADmggSBCACIjkKOQoEBgACABIEJQIpAxorIERlbGV0ZXMgdGhlIGJhY2t1cCB0YWtlbiBi
eSBhIGJhY2t1cCBydW4uCgoMCgUGAAIAARIDJQYMCgwKBQYAAgACEgMlDScKDAoFBgACAAMS
AyUyOwoNCgUGAAIABBIEJgQoBgoRCgkGAAIABLDKvCISBCYEKAYKTwoEBgACARIELAIwAxpB
IFJldHJpZXZlcyBhIHJlc291cmNlIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gYWJvdXQgYSBi
YWNrdXAgcnVuLgoKDAoFBgACAQESAywGCQoMCgUGAAIBAhIDLAohCgwKBQYAAgEDEgMsLDUK
DQoFBgACAQQSBC0ELwYKEQoJBgACAQSwyrwiEgQtBC8GCjMKBAYAAgISBDMCOAMaJSBDcmVh
dGVzIGEgbmV3IGJhY2t1cCBydW4gb24gZGVtYW5kLgoKDAoFBgACAgESAzMGDAoMCgUGAAIC
AhIDMw0nCgwKBQYAAgIDEgMzMjsKDQoFBgACAgQSBDQENwYKEQoJBgACAgSwyrwiEgQ0BDcG
CqwBCgQGAAIDEgQ9AkEDGp0BIExpc3RzIGFsbCBiYWNrdXAgcnVucyBhc3NvY2lhdGVkIHdp
dGggdGhlIHByb2plY3Qgb3IgYSBnaXZlbiBpbnN0YW5jZQogYW5kIGNvbmZpZ3VyYXRpb24g
aW4gdGhlIHJldmVyc2UgY2hyb25vbG9naWNhbCBvcmRlciBvZiB0aGUgYmFja3VwCiBpbml0
aWF0aW9uIHRpbWUuCgoMCgUGAAIDARIDPQYKCgwKBQYAAgMCEgM9CyMKDAoFBgACAwMSAz0u
RAoNCgUGAAIDBBIEPgRABgoRCgkGAAIDBLDKvCISBD4EQAYKKQoCBAASBEUAUAEaHSBCYWNr
dXAgcnVucyBkZWxldGUgcmVxdWVzdC4KCgoKAwQAARIDRQgiCrABCgQEAAIAEgNJAg8aogEg
VGhlIElEIG9mIHRoZSBiYWNrdXAgcnVuIHRvIGRlbGV0ZS4gVG8gZmluZCBhIGJhY2t1cCBy
dW4gSUQsIHVzZSB0aGUKIFtsaXN0XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3FsL2Rv
Y3MvbXlzcWwvYWRtaW4tYXBpL3Jlc3QvdjEvYmFja3VwUnVucy9saXN0KQogbWV0aG9kLgoK
DAoFBAACAAUSA0kCBwoMCgUEAAIAARIDSQgKCgwKBQQAAgADEgNJDQ4KSwoEBAACARIDTAIW
Gj4gQ2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHBy
b2plY3QgSUQuCgoMCgUEAAIBBRIDTAIICgwKBQQAAgEBEgNMCREKDAoFBAACAQMSA0wUFQpE
CgQEAAICEgNPAhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMg
dGhlIGluc3RhbmNlLgoKDAoFBAACAgUSA08CCAoMCgUEAAICARIDTwkQCgwKBQQAAgIDEgNP
ExQKJgoCBAESBFMAXAEaGiBCYWNrdXAgcnVucyBnZXQgcmVxdWVzdC4KCgoKAwQBARIDUwgf
CikKBAQBAgASA1UCDxocIFRoZSBJRCBvZiB0aGlzIGJhY2t1cCBydW4uCgoMCgUEAQIABRID
VQIHCgwKBQQBAgABEgNVCAoKDAoFBAECAAMSA1UNDgpLCgQEAQIBEgNYAhYaPiBDbG91ZCBT
UUwgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4K
CgwKBQQBAgEFEgNYAggKDAoFBAECAQESA1gJEQoMCgUEAQIBAxIDWBQVCkQKBAQBAgISA1sC
FRo3IFByb2plY3QgSUQgb2YgdGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFu
Y2UuCgoMCgUEAQICBRIDWwIICgwKBQQBAgIBEgNbCRAKDAoFBAECAgMSA1sTFAopCgIEAhIE
XwBnARodIEJhY2t1cCBydW5zIGluc2VydCByZXF1ZXN0LgoKCgoDBAIBEgNfCCIKSwoEBAIC
ABIDYQIWGj4gQ2xvdWQgU1FMIGluc3RhbmNlIElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUg
dGhlIHByb2plY3QgSUQuCgoMCgUEAgIABRIDYQIICgwKBQQCAgABEgNhCREKDAoFBAICAAMS
A2EUFQpECgQEAgIBEgNkAhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29u
dGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAICAQUSA2QCCAoMCgUEAgIBARIDZAkQCgwKBQQC
AgEDEgNkExQKCwoEBAICAhIDZgIXCgwKBQQCAgIGEgNmAgsKDAoFBAICAgESA2YMEAoMCgUE
AgICAxIDZhMWCicKAgQDEgRqAHgBGhsgQmFja3VwIHJ1bnMgbGlzdCByZXF1ZXN0LgoKCgoD
BAMBEgNqCCAKZgoEBAMCABIDbQIWGlkgQ2xvdWQgU1FMIGluc3RhbmNlIElELCBvciAiLSIg
Zm9yIGFsbCBpbnN0YW5jZXMuIFRoaXMgZG9lcyBub3QgaW5jbHVkZQogdGhlIHByb2plY3Qg
SUQuCgoMCgUEAwIABRIDbQIICgwKBQQDAgABEgNtCREKDAoFBAMCAAMSA20UFQo6CgQEAwIB
EgNwAhgaLSBNYXhpbXVtIG51bWJlciBvZiBiYWNrdXAgcnVucyBwZXIgcmVzcG9uc2UuCgoM
CgUEAwIBBRIDcAIHCgwKBQQDAgEBEgNwCBMKDAoFBAMCAQMSA3AWFwpoCgQEAwICEgN0Ahga
WyBBIHByZXZpb3VzbHktcmV0dXJuZWQgcGFnZSB0b2tlbiByZXByZXNlbnRpbmcgcGFydCBv
ZiB0aGUgbGFyZ2VyIHNldCBvZgogcmVzdWx0cyB0byB2aWV3LgoKDAoFBAMCAgUSA3QCCAoM
CgUEAwICARIDdAkTCgwKBQQDAgIDEgN0FhcKRAoEBAMCAxIDdwIVGjcgUHJvamVjdCBJRCBv
ZiB0aGUgcHJvamVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCgwKBQQDAgMFEgN3
AggKDAoFBAMCAwESA3cJEAoMCgUEAwIDAxIDdxMUCiQKAgQEEgV7AMQBARoXIEEgQmFja3Vw
UnVuIHJlc291cmNlLgoKCgoDBAQBEgN7CBEKLgoEBAQCABIDfQISGiEgVGhpcyBpcyBhbHdh
eXMgYHNxbCNiYWNrdXBSdW5gLgoKDAoFBAQCAAUSA30CCAoMCgUEBAIAARIDfQkNCgwKBQQE
AgADEgN9EBEKJwoEBAQCARIEgAECIBoZIFRoZSBzdGF0dXMgb2YgdGhpcyBydW4uCgoNCgUE
BAIBBhIEgAECFAoNCgUEBAIBARIEgAEVGwoNCgUEBAIBAxIEgAEeHwqjAQoEBAQCAhIEhQEC
LhqUASBUaGUgdGltZSB0aGUgcnVuIHdhcyBlbnF1ZXVlZCBpbiBVVEMgdGltZXpvbmUgaW4K
IFtSRkMgMzMzOV0oaHR0cHM6Ly90b29scy5pZXRmLm9yZy9odG1sL3JmYzMzMzkpIGZvcm1h
dCwgZm9yIGV4YW1wbGUKIGAyMDEyLTExLTE1VDE2OjE5OjAwLjA5NFpgLgoKDQoFBAQCAgYS
BIUBAhsKDQoFBAQCAgESBIUBHCkKDQoFBAQCAgMSBIUBLC0KYwoEBAQCAxIEiQECDxpVIFRo
ZSBpZGVudGlmaWVyIGZvciB0aGlzIGJhY2t1cCBydW4uIFVuaXF1ZSBvbmx5IGZvciBhIHNw
ZWNpZmljIENsb3VkIFNRTAogaW5zdGFuY2UuCgoNCgUEBAIDBRIEiQECBwoNCgUEBAIDARIE
iQEICgoNCgUEBAIDAxIEiQENDgq0AQoEBAQCBBIEjgECKxqlASBUaGUgdGltZSB0aGUgYmFj
a3VwIG9wZXJhdGlvbiBhY3R1YWxseSBzdGFydGVkIGluIFVUQyB0aW1lem9uZSBpbgogW1JG
QyAzMzM5XShodHRwczovL3Rvb2xzLmlldGYub3JnL2h0bWwvcmZjMzMzOSkgZm9ybWF0LCBm
b3IgZXhhbXBsZQogYDIwMTItMTEtMTVUMTY6MTk6MDAuMDk0WmAuCgoNCgUEBAIEBhIEjgEC
GwoNCgUEBAIEARIEjgEcJgoNCgUEBAIEAxIEjgEpKgqtAQoEBAQCBRIEkwECKRqeASBUaGUg
dGltZSB0aGUgYmFja3VwIG9wZXJhdGlvbiBjb21wbGV0ZWQgaW4gVVRDIHRpbWV6b25lIGlu
CiBbUkZDIDMzMzldKGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9yZmMzMzM5KSBmb3Jt
YXQsIGZvciBleGFtcGxlCiBgMjAxMi0xMS0xNVQxNjoxOTowMC4wOTRaYC4KCg0KBQQEAgUG
EgSTAQIbCg0KBQQEAgUBEgSTARwkCg0KBQQEAgUDEgSTAScoCnoKBAQEAgYSBJcBAhsabCBJ
bmZvcm1hdGlvbiBhYm91dCB3aHkgdGhlIGJhY2t1cCBvcGVyYXRpb24gZmFpbGVkLiBUaGlz
IGlzIG9ubHkgcHJlc2VudCBpZgogdGhlIHJ1biBoYXMgdGhlIEZBSUxFRCBzdGF0dXMuCgoN
CgUEBAIGBhIElwECEAoNCgUEBAIGARIElwERFgoNCgUEBAIGAxIElwEZGgq0AQoEBAQCBxIE
nAECHBqlASBUaGUgdHlwZSBvZiB0aGlzIHJ1bjsgY2FuIGJlIGVpdGhlciAiQVVUT01BVEVE
IiBvciAiT05fREVNQU5EIiBvciAiRklOQUwiLgogVGhpcyBmaWVsZCBkZWZhdWx0cyB0byAi
T05fREVNQU5EIiBhbmQgaXMgaWdub3JlZCwgd2hlbiBzcGVjaWZpZWQgZm9yCiBpbnNlcnQg
cmVxdWVzdHMuCgoNCgUEBAIHBhIEnAECEgoNCgUEBAIHARIEnAETFwoNCgUEBAIHAxIEnAEa
GwpSCgQEBAIIEgSfAQIZGkQgVGhlIGRlc2NyaXB0aW9uIG9mIHRoaXMgcnVuLCBvbmx5IGFw
cGxpY2FibGUgdG8gb24tZGVtYW5kIGJhY2t1cHMuCgoNCgUEBAIIBRIEnwECCAoNCgUEBAII
ARIEnwEJFAoNCgUEBAIIAxIEnwEXGArEAQoEBAQCCRIEpAECMxq1ASBUaGUgc3RhcnQgdGlt
ZSBvZiB0aGUgYmFja3VwIHdpbmRvdyBkdXJpbmcgd2hpY2ggdGhpcyB0aGUgYmFja3VwIHdh
cwogYXR0ZW1wdGVkIGluIFtSRkMgMzMzOV0oaHR0cHM6Ly90b29scy5pZXRmLm9yZy9odG1s
L3JmYzMzMzkpIGZvcm1hdCwgZm9yCiBleGFtcGxlIGAyMDEyLTExLTE1VDE2OjE5OjAwLjA5
NFpgLgoKDQoFBAQCCQYSBKQBAhsKDQoFBAQCCQESBKQBHC0KDQoFBAQCCQMSBKQBMDIKLgoE
BAQCChIEpwECFxogIE5hbWUgb2YgdGhlIGRhdGFiYXNlIGluc3RhbmNlLgoKDQoFBAQCCgUS
BKcBAggKDQoFBAQCCgESBKcBCREKDQoFBAQCCgMSBKcBFBYKKQoEBAQCCxIEqgECGBobIFRo
ZSBVUkkgb2YgdGhpcyByZXNvdXJjZS4KCg0KBQQEAgsFEgSqAQIICg0KBQQEAgsBEgSqAQkS
Cg0KBQQEAgsDEgSqARUXCigKBAQEAgwSBK0BAhcaGiBMb2NhdGlvbiBvZiB0aGUgYmFja3Vw
cy4KCg0KBQQEAgwFEgStAQIICg0KBQQEAgwBEgStAQkRCg0KBQQEAgwDEgStARQWCl8KBAQE
Ag0SBrEBArIBMhpPIE91dHB1dCBvbmx5LiBUaGUgaW5zdGFuY2UgZGF0YWJhc2UgdmVyc2lv
biBhdCB0aGUgdGltZSB0aGlzIGJhY2t1cCB3YXMKIG1hZGUuCgoNCgUEBAINBhIEsQECFAoN
CgUEBAINARIEsQEVJQoNCgUEBAINAxIEsQEoKgoNCgUEBAINCBIEsgEGMQoQCggEBAINCJwI
ABIEsgEHMAo+CgQEBAIOEgS1AQJBGjAgRW5jcnlwdGlvbiBjb25maWd1cmF0aW9uIHNwZWNp
ZmljIHRvIGEgYmFja3VwLgoKDQoFBAQCDgYSBLUBAh0KDQoFBAQCDgESBLUBHjsKDQoFBAQC
DgMSBLUBPkAKNwoEBAQCDxIEuAECMxopIEVuY3J5cHRpb24gc3RhdHVzIHNwZWNpZmljIHRv
IGEgYmFja3VwLgoKDQoFBAQCDwYSBLgBAhYKDQoFBAQCDwESBLgBFy0KDQoFBAQCDwMSBLgB
MDIKSwoEBAQCEBIEuwECIRo9IFNwZWNpZmllcyB0aGUga2luZCBvZiBiYWNrdXAsIFBIWVNJ
Q0FMIG9yIERFRkFVTFRfU05BUFNIT1QuCgoNCgUEBAIQBhIEuwECDwoNCgUEBAIQARIEuwEQ
GwoNCgUEBAIQAxIEuwEeIAqCAQoEBAQCERIEvwECGBp0IEJhY2t1cCB0aW1lIHpvbmUgdG8g
cHJldmVudCByZXN0b3JlcyB0byBhbiBpbnN0YW5jZSB3aXRoCiBhIGRpZmZlcmVudCB0aW1l
IHpvbmUuIE5vdyByZWxldmFudCBvbmx5IGZvciBTUUwgU2VydmVyLgoKDQoFBAQCEQUSBL8B
AggKDQoFBAQCEQESBL8BCRIKDQoFBAQCEQMSBL8BFRcKSwoEBAQCEhIGwgECwwEyGjsgT3V0
cHV0IG9ubHkuIFRoZSBtYXhpbXVtIGNoYXJnZWFibGUgYnl0ZXMgZm9yIHRoZSBiYWNrdXAu
CgoNCgUEBAISBBIEwgECCgoNCgUEBAISBRIEwgELEAoNCgUEBAISARIEwgERJQoNCgUEBAIS
AxIEwgEoKgoNCgUEBAISCBIEwwEGMQoQCggEBAISCJwIABIEwwEHMAooCgIEBRIGxwEA0QEB
GhogQmFja3VwIHJ1biBsaXN0IHJlc3VsdHMuCgoLCgMEBQESBMcBCB4KNAoEBAUCABIEyQEC
EhomIFRoaXMgaXMgYWx3YXlzIGBzcWwjYmFja3VwUnVuc0xpc3RgLgoKDQoFBAUCAAUSBMkB
AggKDQoFBAUCAAESBMkBCQ0KDQoFBAUCAAMSBMkBEBEKWgoEBAUCARIEzAECHxpMIEEgbGlz
dCBvZiBiYWNrdXAgcnVucyBpbiByZXZlcnNlIGNocm9ub2xvZ2ljYWwgb3JkZXIgb2YgdGhl
IGVucXVldWVkIHRpbWUuCgoNCgUEBQIBBBIEzAECCgoNCgUEBQIBBhIEzAELFAoNCgUEBQIB
ARIEzAEVGgoNCgUEBQIBAxIEzAEdHgqgAQoEBAUCAhIE0AECHRqRASBUaGUgY29udGludWF0
aW9uIHRva2VuLCB1c2VkIHRvIHBhZ2UgdGhyb3VnaCBsYXJnZSByZXN1bHQgc2V0cy4gUHJv
dmlkZQogdGhpcyB2YWx1ZSBpbiBhIHN1YnNlcXVlbnQgcmVxdWVzdCB0byByZXR1cm4gdGhl
IG5leHQgcGFnZSBvZiByZXN1bHRzLgoKDQoFBAUCAgUSBNABAggKDQoFBAUCAgESBNABCRgK
DQoFBAUCAgMSBNABGxwKKwoCBQASBtQBAPUBARodIFRoZSBzdGF0dXMgb2YgYSBiYWNrdXAg
cnVuLgoKCwoDBQABEgTUAQUXCjEKBAUAAgASBNYBAigaIyBUaGUgc3RhdHVzIG9mIHRoZSBy
dW4gaXMgdW5rbm93bi4KCg0KBQUAAgABEgTWAQIjCg0KBQUAAgACEgTWASYnCjIKBAUAAgES
BNkBAg8aJCBUaGUgYmFja3VwIG9wZXJhdGlvbiB3YXMgZW5xdWV1ZWQuCgoNCgUFAAIBARIE
2QECCgoNCgUFAAIBAhIE2QENDgqgAQoEBQACAhIE3gECDhqRASBUaGUgYmFja3VwIGlzIG92
ZXJkdWUgYWNyb3NzIGEgZ2l2ZW4gYmFja3VwIHdpbmRvdy4gSW5kaWNhdGVzIGEKIHByb2Js
ZW0uIEV4YW1wbGU6IExvbmctcnVubmluZyBvcGVyYXRpb24gaW4gcHJvZ3Jlc3MgZHVyaW5n
CiB0aGUgd2hvbGUgd2luZG93LgoKDQoFBQACAgESBN4BAgkKDQoFBQACAgISBN4BDA0KKgoE
BQACAxIE4QECDhocIFRoZSBiYWNrdXAgaXMgaW4gcHJvZ3Jlc3MuCgoNCgUFAAIDARIE4QEC
CQoNCgUFAAIDAhIE4QEMDQoiCgQFAAIEEgTkAQINGhQgVGhlIGJhY2t1cCBmYWlsZWQuCgoN
CgUFAAIEARIE5AECCAoNCgUFAAIEAhIE5AELDAoqCgQFAAIFEgTnAQIRGhwgVGhlIGJhY2t1
cCB3YXMgc3VjY2Vzc2Z1bC4KCg0KBQUAAgUBEgTnAQIMCg0KBQUAAgUCEgTnAQ8QCnEKBAUA
AgYSBOsBAg4aYyBUaGUgYmFja3VwIHdhcyBza2lwcGVkICh3aXRob3V0IHByb2JsZW1zKSBm
b3IgYSBnaXZlbiBiYWNrdXAKIHdpbmRvdy4gRXhhbXBsZTogSW5zdGFuY2Ugd2FzIGlkbGUu
CgoNCgUFAAIGARIE6wECCQoNCgUFAAIGAhIE6wEMDQoyCgQFAAIHEgTuAQIXGiQgVGhlIGJh
Y2t1cCBpcyBhYm91dCB0byBiZSBkZWxldGVkLgoKDQoFBQACBwESBO4BAhIKDQoFBQACBwIS
BO4BFRYKKwoEBQACCBIE8QECFhodIFRoZSBiYWNrdXAgZGVsZXRpb24gZmFpbGVkLgoKDQoF
BQACCAESBPEBAhEKDQoFBQACCAISBPEBFBUKLAoEBQACCRIE9AECDhoeIFRoZSBiYWNrdXAg
aGFzIGJlZW4gZGVsZXRlZC4KCg0KBQUAAgkBEgT0AQIJCg0KBQUAAgkCEgT0AQwNCjMKAgUB
Egb4AQCBAgEaJSBEZWZpbmVzIHRoZSBzdXBwb3J0ZWQgYmFja3VwIGtpbmRzLgoKCwoDBQEB
EgT4AQUSCi4KBAUBAgASBPoBAiIaICBUaGlzIGlzIGFuIHVua25vd24gQmFja3VwS2luZC4K
Cg0KBQUBAgABEgT6AQIdCg0KBQUBAgACEgT6ASAhCicKBAUBAgESBP0BAg8aGSBTbmFwc2hv
dC1iYXNlZCBiYWNrdXBzLgoKDQoFBQECAQESBP0BAgoKDQoFBQECAQISBP0BDQ4KIQoEBQEC
AhIEgAICDxoTIFBoeXNpY2FsIGJhY2t1cHMuCgoNCgUFAQICARIEgAICCgoNCgUFAQICAhIE
gAINDgpACgIFAhIGhAIAjQIBGjIgVHlwZSBvZiBiYWNrdXAgKGkuZS4gYXV0b21hdGVkLCBv
biBkZW1hbmQsIGV0YykuCgoLCgMFAgESBIQCBRUKMgoEBQICABIEhgICJhokIFRoaXMgaXMg
YW4gdW5rbm93biBCYWNrdXBSdW4gdHlwZS4KCg0KBQUCAgABEgSGAgIhCg0KBQUCAgACEgSG
AiQlCkQKBAUCAgESBIkCAhAaNiBUaGUgYmFja3VwIHNjaGVkdWxlIGF1dG9tYXRpY2FsbHkg
dHJpZ2dlcnMgYSBiYWNrdXAuCgoNCgUFAgIBARIEiQICCwoNCgUFAgIBAhIEiQIODwo0CgQF
AgICEgSMAgIQGiYgVGhlIHVzZXIgbWFudWFsbHkgdHJpZ2dlcnMgYSBiYWNrdXAuCgoNCgUF
AgICARIEjAICCwoNCgUFAgICAhIEjAIOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsDeleteRequest ===
    # Fields for SqlBackupRunsDeleteRequest
    # Field: id Type: 3 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsDeleteRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackupRuns;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsDeleteRequest->new(
        id => $value,
    );

=head1 FIELDS

=over 4

=item * B<id>

Type: Int64

=item * B<instance>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsGetRequest ===
    # Fields for SqlBackupRunsGetRequest
    # Field: id Type: 3 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsGetRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackupRuns;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsGetRequest->new(
        id => $value,
    );

=head1 FIELDS

=over 4

=item * B<id>

Type: Int64

=item * B<instance>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsInsertRequest ===
    # Fields for SqlBackupRunsInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.BackupRun)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsInsertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackupRuns;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsInsertRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<body>

Type: Message (.google.cloud.sql.v1.BackupRun)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsListRequest ===
    # Fields for SqlBackupRunsListRequest
    # Field: instance Type: 9 ()
    # Field: max_results Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackupRuns;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsListRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<max_results>

Type: Int32

=item * B<page_token>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRun ===
    # Fields for BackupRun
    # Field: kind Type: 9 ()
    # Field: status Type: 14 (.google.cloud.sql.v1.SqlBackupRunStatus)
    # Field: enqueued_time Type: 11 (.google.protobuf.Timestamp)
    # Field: id Type: 3 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: error Type: 11 (.google.cloud.sql.v1.OperationError)
    # Field: type Type: 14 (.google.cloud.sql.v1.SqlBackupRunType)
    # Field: description Type: 9 ()
    # Field: window_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instance Type: 9 ()
    # Field: self_link Type: 9 ()
    # Field: location Type: 9 ()
    # Field: database_version Type: 14 (.google.cloud.sql.v1.SqlDatabaseVersion)
    # Field: disk_encryption_configuration Type: 11 (.google.cloud.sql.v1.DiskEncryptionConfiguration)
    # Field: disk_encryption_status Type: 11 (.google.cloud.sql.v1.DiskEncryptionStatus)
    # Field: backup_kind Type: 14 (.google.cloud.sql.v1.SqlBackupKind)
    # Field: time_zone Type: 9 ()
    # Field: max_chargeable_bytes Type: 3 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRun - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackupRuns;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRun->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<status>

Type: Enum (.google.cloud.sql.v1.SqlBackupRunStatus)

=item * B<enqueued_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<id>

Type: Int64

=item * B<start_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<end_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<error>

Type: Message (.google.cloud.sql.v1.OperationError)

=item * B<type>

Type: Enum (.google.cloud.sql.v1.SqlBackupRunType)

=item * B<description>

Type: String

=item * B<window_start_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<instance>

Type: String

=item * B<self_link>

Type: String

=item * B<location>

Type: String

=item * B<database_version>

Type: Enum (.google.cloud.sql.v1.SqlDatabaseVersion)

=item * B<disk_encryption_configuration>

Type: Message (.google.cloud.sql.v1.DiskEncryptionConfiguration)

=item * B<disk_encryption_status>

Type: Message (.google.cloud.sql.v1.DiskEncryptionStatus)

=item * B<backup_kind>

Type: Enum (.google.cloud.sql.v1.SqlBackupKind)

=item * B<time_zone>

Type: String

=item * B<max_chargeable_bytes>

Type: Int64

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRunsListResponse ===
    # Fields for BackupRunsListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.BackupRun)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRunsListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlBackupRuns;

    my $msg = Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRunsListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.BackupRun)

=item * B<next_page_token>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsServiceClient - Client stub representing the remote SqlBackupRunsService service

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
        ? Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsDeleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupRunsService',
        method         => 'Delete',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub get {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsGetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupRunsService',
        method         => 'Get',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRun',
    });
}

sub insert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsInsertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupRunsService',
        method         => 'Insert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlBackupRunsService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRunsListResponse',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
