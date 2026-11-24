package Google::Cloud::Connectors::V1::ConnectorVersion;

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
    eval { require Google::Cloud::Connectors::V1::Authconfig };
    eval { require Google::Cloud::Connectors::V1::Common };
    eval { require Google::Cloud::Connectors::V1::SslConfig };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9jb25uZWN0b3JfdmVyc2lvbi5wcm90bxIa
Z29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aK2dvb2dsZS9jbG91ZC9jb25uZWN0
b3JzL3YxL2F1dGhjb25maWcucHJvdG8aJ2dvb2dsZS9jbG91ZC9jb25uZWN0b3JzL3YxL2Nv
bW1vbi5wcm90bxorZ29vZ2xlL2Nsb3VkL2Nvbm5lY3RvcnMvdjEvc3NsX2NvbmZpZy5wcm90
bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLACgoQQ29ubmVjdG9yVmVyc2lv
bhIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUY
AyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSVQoG
bGFiZWxzGAQgAygLMjguZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuQ29ubmVjdG9yVmVy
c2lvbi5MYWJlbHNFbnRyeUID4EEDUgZsYWJlbHMSTwoMbGF1bmNoX3N0YWdlGAYgASgOMicu
Z29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuTGF1bmNoU3RhZ2VCA+BBA1ILbGF1bmNoU3Rh
Z2USLAoPcmVsZWFzZV92ZXJzaW9uGAcgASgJQgPgQQNSDnJlbGVhc2VWZXJzaW9uEmcKFWF1
dGhfY29uZmlnX3RlbXBsYXRlcxgIIAMoCzIuLmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYx
LkF1dGhDb25maWdUZW1wbGF0ZUID4EEDUhNhdXRoQ29uZmlnVGVtcGxhdGVzEnMKGWNvbmZp
Z192YXJpYWJsZV90ZW1wbGF0ZXMYCSADKAsyMi5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52
MS5Db25maWdWYXJpYWJsZVRlbXBsYXRlQgPgQQNSF2NvbmZpZ1ZhcmlhYmxlVGVtcGxhdGVz
EncKGnN1cHBvcnRlZF9ydW50aW1lX2ZlYXR1cmVzGAogASgLMjQuZ29vZ2xlLmNsb3VkLmNv
bm5lY3RvcnMudjEuU3VwcG9ydGVkUnVudGltZUZlYXR1cmVzQgPgQQNSGHN1cHBvcnRlZFJ1
bnRpbWVGZWF0dXJlcxImCgxkaXNwbGF5X25hbWUYCyABKAlCA+BBA1ILZGlzcGxheU5hbWUS
aAoVZWdyZXNzX2NvbnRyb2xfY29uZmlnGAwgASgLMi8uZ29vZ2xlLmNsb3VkLmNvbm5lY3Rv
cnMudjEuRWdyZXNzQ29udHJvbENvbmZpZ0ID4EEDUhNlZ3Jlc3NDb250cm9sQ29uZmlnEksK
C3JvbGVfZ3JhbnRzGA4gAygLMiUuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuUm9sZUdy
YW50QgPgQQNSCnJvbGVHcmFudHMSSQoKcm9sZV9ncmFudBgPIAEoCzIlLmdvb2dsZS5jbG91
ZC5jb25uZWN0b3JzLnYxLlJvbGVHcmFudEID4EEDUglyb2xlR3JhbnQSYgoTc3NsX2NvbmZp
Z190ZW1wbGF0ZRgRIAEoCzItLmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLlNzbENvbmZp
Z1RlbXBsYXRlQgPgQQNSEXNzbENvbmZpZ1RlbXBsYXRlGjkKC0xhYmVsc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6mAHqQZQBCipjb25uZWN0
b3JzLmdvb2dsZWFwaXMuY29tL0Nvbm5lY3RvclZlcnNpb24SZnByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wcm92aWRlcnMve3Byb3ZpZGVyfS9jb25uZWN0b3Jz
L3tjb25uZWN0b3J9L3ZlcnNpb25zL3t2ZXJzaW9ufSKqAQoaR2V0Q29ubmVjdG9yVmVyc2lv
blJlcXVlc3QSRgoEbmFtZRgBIAEoCUIy4EEC+kEsCipjb25uZWN0b3JzLmdvb2dsZWFwaXMu
Y29tL0Nvbm5lY3RvclZlcnNpb25SBG5hbWUSRAoEdmlldxgCIAEoDjIwLmdvb2dsZS5jbG91
ZC5jb25uZWN0b3JzLnYxLkNvbm5lY3RvclZlcnNpb25WaWV3UgR2aWV3IuUBChxMaXN0Q29u
bmVjdG9yVmVyc2lvbnNSZXF1ZXN0EkMKBnBhcmVudBgBIAEoCUIr4EEC+kElCiNjb25uZWN0
b3JzLmdvb2dsZWFwaXMuY29tL0Nvbm5lY3RvclIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEo
BVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEkQKBHZpZXcYBCAB
KA4yMC5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MS5Db25uZWN0b3JWZXJzaW9uVmlld1IE
dmlldyLGAQodTGlzdENvbm5lY3RvclZlcnNpb25zUmVzcG9uc2USWwoSY29ubmVjdG9yX3Zl
cnNpb25zGAEgAygLMiwuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuQ29ubmVjdG9yVmVy
c2lvblIRY29ubmVjdG9yVmVyc2lvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0
UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJ5ChhTdXBwb3J0
ZWRSdW50aW1lRmVhdHVyZXMSHwoLZW50aXR5X2FwaXMYASABKAhSCmVudGl0eUFwaXMSHwoL
YWN0aW9uX2FwaXMYAiABKAhSCmFjdGlvbkFwaXMSGwoJc3FsX3F1ZXJ5GAMgASgIUghzcWxR
dWVyeSKfAQoTRWdyZXNzQ29udHJvbENvbmZpZxIcCghiYWNrZW5kcxgBIAEoCUgAUghiYWNr
ZW5kcxJYChBleHRyYWN0aW9uX3J1bGVzGAIgASgLMisuZ29vZ2xlLmNsb3VkLmNvbm5lY3Rv
cnMudjEuRXh0cmFjdGlvblJ1bGVzSABSD2V4dHJhY3Rpb25SdWxlc0IQCg5vbmVvZl9iYWNr
ZW5kcyJmCg9FeHRyYWN0aW9uUnVsZXMSUwoPZXh0cmFjdGlvbl9ydWxlGAEgAygLMiouZ29v
Z2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuRXh0cmFjdGlvblJ1bGVSDmV4dHJhY3Rpb25SdWxl
IsMCCg5FeHRyYWN0aW9uUnVsZRJJCgZzb3VyY2UYASABKAsyMS5nb29nbGUuY2xvdWQuY29u
bmVjdG9ycy52MS5FeHRyYWN0aW9uUnVsZS5Tb3VyY2VSBnNvdXJjZRIpChBleHRyYWN0aW9u
X3JlZ2V4GAIgASgJUg9leHRyYWN0aW9uUmVnZXgaewoGU291cmNlElYKC3NvdXJjZV90eXBl
GAEgASgOMjUuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuRXh0cmFjdGlvblJ1bGUuU291
cmNlVHlwZVIKc291cmNlVHlwZRIZCghmaWVsZF9pZBgCIAEoCVIHZmllbGRJZCI+CgpTb3Vy
Y2VUeXBlEhsKF1NPVVJDRV9UWVBFX1VOU1BFQ0lGSUVEEAASEwoPQ09ORklHX1ZBUklBQkxF
EAEqgQEKFENvbm5lY3RvclZlcnNpb25WaWV3EiYKIkNPTk5FQ1RPUl9WRVJTSU9OX1ZJRVdf
VU5TUEVDSUZJRUQQABIgChxDT05ORUNUT1JfVkVSU0lPTl9WSUVXX0JBU0lDEAESHwobQ09O
TkVDVE9SX1ZFUlNJT05fVklFV19GVUxMEAJCeQoeY29tLmdvb2dsZS5jbG91ZC5jb25uZWN0
b3JzLnYxQhVDb25uZWN0b3JWZXJzaW9uUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9j
b25uZWN0b3JzL2FwaXYxL2Nvbm5lY3RvcnNwYjtjb25uZWN0b3JzcGJK/TsKBxIFDgDhAQEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIA
KQoJCgIDARIDEwAjCgkKAgMCEgMUADUKCQoCAwMSAxUAMQoJCgIDBBIDFgA1CgkKAgMFEgMX
ACkKCAoBCBIDGQBVCgkKAggLEgMZAFUKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA2
CgkKAggIEgMbADYKCAoBCBIDHAA3CgkKAggBEgMcADcKSwoCBAASBB8AXQEaPyBDb25uZWN0
b3JWZXJzaW9uIGluZGljYXRlcyBhIHNwZWNpZmljIHZlcnNpb24gb2YgYSBjb25uZWN0b3Iu
CgoKCgMEAAESAx8IGAoLCgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQK5gEKBAQAAgASAykC
PhrYASBPdXRwdXQgb25seS4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgVmVyc2lvbi4KIEZvcm1h
dDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9wcm92aWRlcnMv
e3Byb3ZpZGVyfS9jb25uZWN0b3JzL3tjb25uZWN0b3J9L3ZlcnNpb25zL3t2ZXJzaW9ufQog
T25seSBnbG9iYWwgbG9jYXRpb24gaXMgc3VwcG9ydGVkIGZvciBDb25uZWN0b3IgcmVzb3Vy
Y2UuCgoMCgUEAAIABRIDKQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQoMCgUEAAIA
CBIDKRI9Cg8KCAQAAgAInAgAEgMpEzwKKgoEBAACARIELAItMhocIE91dHB1dCBvbmx5LiBD
cmVhdGVkIHRpbWUuCgoMCgUEAAIBBhIDLAIbCgwKBQQAAgEBEgMsHCcKDAoFBAACAQMSAywq
KwoMCgUEAAIBCBIDLQYxCg8KCAQAAgEInAgAEgMtBzAKKgoEBAACAhIEMAIxMhocIE91dHB1
dCBvbmx5LiBVcGRhdGVkIHRpbWUuCgoMCgUEAAICBhIDMAIbCgwKBQQAAgIBEgMwHCcKDAoF
BAACAgMSAzAqKwoMCgUEAAICCBIDMQYxCg8KCAQAAgIInAgAEgMxBzAKxQEKBAQAAgMSAzYC
TRq3ASBPdXRwdXQgb25seS4gUmVzb3VyY2UgbGFiZWxzIHRvIHJlcHJlc2VudCB1c2VyLXBy
b3ZpZGVkIG1ldGFkYXRhLgogUmVmZXIgdG8gY2xvdWQgZG9jdW1lbnRhdGlvbiBvbiBsYWJl
bHMgZm9yIG1vcmUgZGV0YWlscy4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRl
L2RvY3MvbGFiZWxpbmctcmVzb3VyY2VzCgoMCgUEAAIDBhIDNgIVCgwKBQQAAgMBEgM2FhwK
DAoFBAACAwMSAzYfIAoMCgUEAAIDCBIDNiFMCg8KCAQAAgMInAgAEgM2IksKUQoEBAACBBID
OQJLGkQgT3V0cHV0IG9ubHkuIEZsYWcgdG8gbWFyayB0aGUgdmVyc2lvbiBpbmRpY2F0aW5n
IHRoZSBsYXVuY2ggc3RhZ2UuCgoMCgUEAAIEBhIDOQINCgwKBQQAAgQBEgM5DhoKDAoFBAAC
BAMSAzkdHgoMCgUEAAIECBIDOR9KCg8KCAQAAgQInAgAEgM5IEkKWAoEBAACBRIDPAJJGksg
T3V0cHV0IG9ubHkuIFJlbGVhc2VWZXJzaW9uIG9mIHRoZSBjb25uZWN0b3IsIGZvciBleGFt
cGxlOiAiMS4wLjEtYWxwaGEiLgoKDAoFBAACBQUSAzwCCAoMCgUEAAIFARIDPAkYCgwKBQQA
AgUDEgM8GxwKDAoFBAACBQgSAzwdSAoPCggEAAIFCJwIABIDPB5HClUKBAQAAgYSBD8CQDIa
RyBPdXRwdXQgb25seS4gTGlzdCBvZiBhdXRoIGNvbmZpZ3Mgc3VwcG9ydGVkIGJ5IHRoZSBD
b25uZWN0b3IgVmVyc2lvbi4KCgwKBQQAAgYEEgM/AgoKDAoFBAACBgYSAz8LHQoMCgUEAAIG
ARIDPx4zCgwKBQQAAgYDEgM/NjcKDAoFBAACBggSA0AGMQoPCggEAAIGCJwIABIDQAcwClQK
BAQAAgcSBEMCRDIaRiBPdXRwdXQgb25seS4gTGlzdCBvZiBjb25maWcgdmFyaWFibGVzIG5l
ZWRlZCB0byBjcmVhdGUgYSBjb25uZWN0aW9uLgoKDAoFBAACBwQSA0MCCgoMCgUEAAIHBhID
QwshCgwKBQQAAgcBEgNDIjsKDAoFBAACBwMSA0M+PwoMCgUEAAIHCBIDRAYxCg8KCAQAAgcI
nAgAEgNEBzAKYAoEBAACCBIESAJJMhpSIE91dHB1dCBvbmx5LiBJbmZvcm1hdGlvbiBhYm91
dCB0aGUgcnVudGltZSBmZWF0dXJlcyBzdXBwb3J0ZWQgYnkgdGhlCiBDb25uZWN0b3IuCgoM
CgUEAAIIBhIDSAIaCgwKBQQAAggBEgNIGzUKDAoFBAACCAMSA0g4OgoMCgUEAAIICBIDSQYx
Cg8KCAQAAggInAgAEgNJBzAKKQoEBAACCRIDTAJHGhwgT3V0cHV0IG9ubHkuIERpc3BsYXkg
bmFtZS4KCgwKBQQAAgkFEgNMAggKDAoFBAACCQESA0wJFQoMCgUEAAIJAxIDTBgaCgwKBQQA
AgkIEgNMG0YKDwoIBAACCQicCAASA0wcRQo+CgQEAAIKEgRPAlAyGjAgT3V0cHV0IG9ubHku
IENvbmZpZ3VyYXRpb24gZm9yIEVncmVzcyBDb250cm9sLgoKDAoFBAACCgYSA08CFQoMCgUE
AAIKARIDTxYrCgwKBQQAAgoDEgNPLjAKDAoFBAACCggSA1AGMQoPCggEAAIKCJwIABIDUAcw
ClIKBAQAAgsSBFMCVDIaRCBPdXRwdXQgb25seS4gUm9sZSBncmFudCBjb25maWd1cmF0aW9u
cyBmb3IgdGhpcyBjb25uZWN0b3IgdmVyc2lvbi4KCgwKBQQAAgsEEgNTAgoKDAoFBAACCwYS
A1MLFAoMCgUEAAILARIDUxUgCgwKBQQAAgsDEgNTIyUKDAoFBAACCwgSA1QGMQoPCggEAAIL
CJwIABIDVAcwCmsKBAQAAgwSA1gCSBpeIE91dHB1dCBvbmx5LiBSb2xlIGdyYW50IGNvbmZp
Z3VyYXRpb24gZm9yIHRoaXMgY29uZmlnIHZhcmlhYmxlLiBJdCB3aWxsIGJlCiBERVBSRUNB
VEVEIHNvb24uCgoMCgUEAAIMBhIDWAILCgwKBQQAAgwBEgNYDBYKDAoFBAACDAMSA1gZGwoM
CgUEAAIMCBIDWBxHCg8KCAQAAgwInAgAEgNYHUYKSgoEBAACDRIEWwJcMho8IE91dHB1dCBv
bmx5LiBTc2wgY29uZmlndXJhdGlvbiBzdXBwb3J0ZWQgYnkgdGhlIENvbm5lY3Rvci4KCgwK
BQQAAg0GEgNbAhMKDAoFBAACDQESA1sUJwoMCgUEAAINAxIDWyosCgwKBQQAAg0IEgNcBjEK
DwoIBAACDQicCAASA1wHMApBCgIEARIEYABuARo1IFJlcXVlc3QgbWVzc2FnZSBmb3IgQ29u
bmVjdG9ycy5HZXRDb25uZWN0b3JWZXJzaW9uLgoKCgoDBAEBEgNgCCIKtQEKBAQBAgASBGQC
aQQapgEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIGZvcm06CiBgcHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9wcm92aWRlcnMvKi9jb25uZWN0b3JzLyovdmVyc2lvbnMvKmAKIE9u
bHkgZ2xvYmFsIGxvY2F0aW9uIGlzIHN1cHBvcnRlZCBmb3IgQ29ubmVjdG9yVmVyc2lvbiBy
ZXNvdXJjZS4KCgwKBQQBAgAFEgNkAggKDAoFBAECAAESA2QJDQoMCgUEAQIAAxIDZBARCg0K
BQQBAgAIEgRkEmkDCg8KCAQBAgAInAgAEgNlBCoKDwoHBAECAAifCBIEZgRoBQp5CgQEAQIB
EgNtAiAabCBTcGVjaWZpZXMgd2hpY2ggZmllbGRzIG9mIHRoZSBDb25uZWN0b3JWZXJzaW9u
IGFyZSByZXR1cm5lZCBpbiB0aGUKIHJlc3BvbnNlLiBEZWZhdWx0cyB0byBgQ1VTVE9NRVJg
IHZpZXcuCgoMCgUEAQIBBhIDbQIWCgwKBQQBAgEBEgNtFxsKDAoFBAECAQMSA20eHwpECgIE
AhIFcQCFAQEaNyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIENvbm5lY3RvcnMuTGlzdENvbm5lY3Rv
clZlcnNpb25zLgoKCgoDBAIBEgNxCCQKvwEKBAQCAgASBHUCegQasAEgUmVxdWlyZWQuIFBh
cmVudCByZXNvdXJjZSBvZiB0aGUgY29ubmVjdG9ycywgb2YgdGhlIGZvcm06CiBgcHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9wcm92aWRlcnMvKi9jb25uZWN0b3JzLypgCiBPbmx5IGdsb2Jh
bCBsb2NhdGlvbiBpcyBzdXBwb3J0ZWQgZm9yIENvbm5lY3RvclZlcnNpb24gcmVzb3VyY2Uu
CgoMCgUEAgIABRIDdQIICgwKBQQCAgABEgN1CQ8KDAoFBAICAAMSA3USEwoNCgUEAgIACBIE
dRR6AwoPCggEAgIACJwIABIDdgQqCg8KBwQCAgAInwgSBHcEeQUKGQoEBAICARIDfQIWGgwg
UGFnZSBzaXplLgoKDAoFBAICAQUSA30CBwoMCgUEAgIBARIDfQgRCgwKBQQCAgEDEgN9FBUK
GwoEBAICAhIEgAECGBoNIFBhZ2UgdG9rZW4uCgoNCgUEAgICBRIEgAECCAoNCgUEAgICARIE
gAEJEwoNCgUEAgICAxIEgAEWFwp3CgQEAgIDEgSEAQIgGmkgU3BlY2lmaWVzIHdoaWNoIGZp
ZWxkcyBvZiB0aGUgQ29ubmVjdG9yVmVyc2lvbiBhcmUgcmV0dXJuZWQgaW4gdGhlCiByZXNw
b25zZS4gRGVmYXVsdHMgdG8gYEJBU0lDYCB2aWV3LgoKDQoFBAICAwYSBIQBAhYKDQoFBAIC
AwESBIQBFxsKDQoFBAICAwMSBIQBHh8KRgoCBAMSBogBAJEBARo4IFJlc3BvbnNlIG1lc3Nh
Z2UgZm9yIENvbm5lY3RvcnMuTGlzdENvbm5lY3RvclZlcnNpb25zLgoKCwoDBAMBEgSIAQgl
Ci0KBAQDAgASBIoBAjMaHyBBIGxpc3Qgb2YgY29ubmVjdG9yIHZlcnNpb25zLgoKDQoFBAMC
AAQSBIoBAgoKDQoFBAMCAAYSBIoBCxsKDQoFBAMCAAESBIoBHC4KDQoFBAMCAAMSBIoBMTIK
IAoEBAMCARIEjQECHRoSIE5leHQgcGFnZSB0b2tlbi4KCg0KBQQDAgEFEgSNAQIICg0KBQQD
AgEBEgSNAQkYCg0KBQQDAgEDEgSNARscCjQKBAQDAgISBJABAiIaJiBMb2NhdGlvbnMgdGhh
dCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQDAgIEEgSQAQIKCg0KBQQDAgIFEgSQAQsR
Cg0KBQQDAgIBEgSQARIdCg0KBQQDAgIDEgSQASAhCpUCCgIEBBIGlwEAoAEBGoYCIFN1cHBv
cnRlZCBydW50aW1lIGZlYXR1cmVzIG9mIGEgY29ubmVjdG9yIHZlcnNpb24uIFRoaXMgaXMg
cGFzc2VkIHRvIHRoZQogbWFuYWdlbWVudCBsYXllciB0byBhZGQgYSBuZXcgY29ubmVjdG9y
IHZlcnNpb24gYnkgdGhlIGNvbm5lY3RvciBkZXZlbG9wZXIuCiBEZXRhaWxzIGFib3V0IGhv
dyB0aGlzIHByb3RvIGlzIHBhc3NlZCB0byB0aGUgbWFuYWdlbWVudCBsYXllciBpcyBjb3Zl
cmVkIGluCiB0aGlzIGRvYyAtIGdvL3J1bnRpbWUtbWFuaWZlc3QuCgoLCgMEBAESBJcBCCAK
VAoEBAQCABIEmQECFxpGIFNwZWNpZmllcyBpZiB0aGUgY29ubmVjdG9yIHN1cHBvcnRzIGVu
dGl0eSBhcGlzIGxpa2UgJ2NyZWF0ZUVudGl0eScuCgoNCgUEBAIABRIEmQECBgoNCgUEBAIA
ARIEmQEHEgoNCgUEBAIAAxIEmQEVFgpVCgQEBAIBEgScAQIXGkcgU3BlY2lmaWVzIGlmIHRo
ZSBjb25uZWN0b3Igc3VwcG9ydHMgYWN0aW9uIGFwaXMgbGlrZSAnZXhlY3V0ZUFjdGlvbicu
CgoNCgUEBAIBBRIEnAECBgoNCgUEBAIBARIEnAEHEgoNCgUEBAIBAxIEnAEVFgpQCgQEBAIC
EgSfAQIVGkIgU3BlY2lmaWVzIGlmIHRoZSBjb25uZWN0b3Igc3VwcG9ydHMgJ0V4ZWN1dGVT
cWxRdWVyeScgb3BlcmF0aW9uLgoKDQoFBAQCAgUSBJ8BAgYKDQoFBAQCAgESBJ8BBxAKDQoF
BAQCAgMSBJ8BExQKxQIKAgQFEganAQCyAQEatgIgRWdyZXNzIGNvbnRyb2wgY29uZmlnIGZv
ciBjb25uZWN0b3IgcnVudGltZS4gVGhlc2UgY29uZmlndXJhdGlvbnMgZGVmaW5lIHRoZQog
cnVsZXMgdG8gaWRlbnRpZnkgd2hpY2ggb3V0Ym91bmQgZG9tYWlucy9ob3N0cyBuZWVkcyB0
byBiZSB3aGl0ZWxpc3RlZC4gSXQKIG1heSBiZSBhIHN0YXRpYyBpbmZvcm1hdGlvbiBmb3Ig
YSBwYXJ0aWN1bGFyIGNvbm5lY3RvciB2ZXJzaW9uIG9yIGl0IGlzCiBkZXJpdmVkIGZyb20g
dGhlIGNvbmZpZ3VyYXRpb25zIHByb3ZpZGVkIGJ5IHRoZSBjdXN0b21lciBpbiBDb25uZWN0
aW9uCiByZXNvdXJjZS4KCgsKAwQFARIEpwEIGwoOCgQEBQgAEgaoAQKxAQMKDQoFBAUIAAES
BKgBCBYKyAEKBAQFAgASBKwBBBgauQEgU3RhdGljIENvbW1hIHNlcGFyYXRlZCBiYWNrZW5k
cyB3aGljaCBhcmUgY29tbW9uIGZvciBhbGwgQ29ubmVjdGlvbgogcmVzb3VyY2VzLiBTdXBw
b3J0ZWQgZm9ybWF0cyBmb3IgZWFjaCBiYWNrZW5kIGFyZSBob3N0OnBvcnQgb3IganVzdAog
aG9zdCAoaG9zdCBjYW4gYmUgaXAgYWRkcmVzcyBvciBkb21haW4gbmFtZSkuCgoNCgUEBQIA
BRIErAEECgoNCgUEBQIAARIErAELEwoNCgUEBQIAAxIErAEWFwpgCgQEBQIBEgSwAQQpGlIg
RXh0cmFjdGlvbnMgUnVsZXMgdG8gZXh0cmFjdCB0aGUgYmFja2VuZHMgZnJvbSBjdXN0b21l
ciBwcm92aWRlZAogY29uZmlndXJhdGlvbi4KCg0KBQQFAgEGEgSwAQQTCg0KBQQFAgEBEgSw
ARQkCg0KBQQFAgEDEgSwAScoCncKAgQGEga2AQC5AQEaaSBFeHRyYWN0aW9uIFJ1bGVzIHRv
IGlkZW50aXR5IHRoZSBiYWNrZW5kcyBmcm9tIGN1c3RvbWVyIHByb3ZpZGVkCiBjb25maWd1
cmF0aW9uIGluIENvbm5lY3Rpb24gcmVzb3VyY2UuCgoLCgMEBgESBLYBCBcKLgoEBAYCABIE
uAECLhogIENvbGxlY3Rpb24gb2YgRXh0cmFjdGlvbiBSdWxlLgoKDQoFBAYCAAQSBLgBAgoK
DQoFBAYCAAYSBLgBCxkKDQoFBAYCAAESBLgBGikKDQoFBAYCAAMSBLgBLC0KIAoCBAcSBrwB
ANUBARoSIEV4dHJhY3Rpb24gUnVsZS4KCgsKAwQHARIEvAEIFgo1CgQEBwMAEga+AQLEAQMa
JSBTb3VyY2UgdG8gZXh0cmFjdCB0aGUgYmFja2VuZCBmcm9tLgoKDQoFBAcDAAESBL4BChAK
JQoGBAcDAAIAEgTAAQQfGhUgVHlwZSBvZiB0aGUgc291cmNlLgoKDwoHBAcDAAIABhIEwAEE
DgoPCgcEBwMAAgABEgTAAQ8aCg8KBwQHAwACAAMSBMABHR4KRAoGBAcDAAIBEgTDAQQYGjQg
RmllbGQgaWRlbnRpZmllci4gRm9yIGV4YW1wbGUgY29uZmlnIHZhaWFibGUgbmFtZS4KCg8K
BwQHAwACAQUSBMMBBAoKDwoHBAcDAAIBARIEwwELEwoPCgcEBwMAAgEDEgTDARYXCjgKBAQH
BAASBscBAs0BAxooIFN1cHBvcnRlZCBTb3VyY2UgdHlwZXMgZm9yIGV4dHJhY3Rpb24uCgoN
CgUEBwQAARIExwEHEQohCgYEBwQAAgASBMkBBCAaESBEZWZhdWx0IFNPVVJDRS4KCg8KBwQH
BAACAAESBMkBBBsKDwoHBAcEAAIAAhIEyQEeHwouCgYEBwQAAgESBMwBBBgaHiBDb25maWcg
VmFyaWFibGUgc291cmNlIHR5cGUuCgoPCgcEBwQAAgEBEgTMAQQTCg8KBwQHBAACAQISBMwB
FhcKNAoEBAcCABIE0AECFBomIFNvdXJjZSBvbiB3aGljaCB0aGUgcnVsZSBpcyBhcHBsaWVk
LgoKDQoFBAcCAAYSBNABAggKDQoFBAcCAAESBNABCQ8KDQoFBAcCAAMSBNABEhMKbgoEBAcC
ARIE1AECHhpgIFJlZ2V4IHVzZWQgdG8gZXh0cmFjdCBiYWNrZW5kIGRldGFpbHMgZnJvbSBz
b3VyY2UuIElmIGVtcHR5LCB3aG9sZSBzb3VyY2UKIHZhbHVlIHdpbGwgYmUgdXNlZC4KCg0K
BQQHAgEFEgTUAQIICg0KBQQHAgEBEgTUAQkZCg0KBQQHAgEDEgTUARwdClAKAgUAEgbYAQDh
AQEaQiBFbnVtIHRvIGNvbnRyb2wgd2hpY2ggZmllbGRzIHNob3VsZCBiZSBpbmNsdWRlZCBp
biB0aGUgcmVzcG9uc2UuCgoLCgMFAAESBNgBBRkKMwoEBQACABIE2gECKRolIENPTk5FQ1RP
Ul9WRVJTSU9OX1ZJRVdfVU5TUEVDSUZJRUQuCgoNCgUFAAIAARIE2gECJAoNCgUFAAIAAhIE
2gEnKAoyCgQFAAIBEgTdAQIjGiQgRG8gbm90IGluY2x1ZGUgcm9sZSBncmFudCBjb25maWdz
LgoKDQoFBQACAQESBN0BAh4KDQoFBQACAQISBN0BISIKKwoEBQACAhIE4AECIhodIEluY2x1
ZGUgcm9sZSBncmFudCBjb25maWdzLgoKDQoFBQACAgESBOABAh0KDQoFBQACAgISBOABICFi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion ===
    # Fields for ConnectorVersion
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.connectors.v1.ConnectorVersion.LabelsEntry)
    # Field: launch_stage Type: 14 (.google.cloud.connectors.v1.LaunchStage)
    # Field: release_version Type: 9 ()
    # Field: auth_config_templates Type: 11 (.google.cloud.connectors.v1.AuthConfigTemplate)
    # Field: config_variable_templates Type: 11 (.google.cloud.connectors.v1.ConfigVariableTemplate)
    # Field: supported_runtime_features Type: 11 (.google.cloud.connectors.v1.SupportedRuntimeFeatures)
    # Field: display_name Type: 9 ()
    # Field: egress_control_config Type: 11 (.google.cloud.connectors.v1.EgressControlConfig)
    # Field: role_grants Type: 11 (.google.cloud.connectors.v1.RoleGrant)
    # Field: role_grant Type: 11 (.google.cloud.connectors.v1.RoleGrant)
    # Field: ssl_config_template Type: 11 (.google.cloud.connectors.v1.SslConfigTemplate)

# === Message: Google::Cloud::Connectors::V1::ConnectorVersion::GetConnectorVersionRequest ===
    # Fields for GetConnectorVersionRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.cloud.connectors.v1.ConnectorVersionView)

# === Message: Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsRequest ===
    # Fields for ListConnectorVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: view Type: 14 (.google.cloud.connectors.v1.ConnectorVersionView)

# === Message: Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsResponse ===
    # Fields for ListConnectorVersionsResponse
    # Field: connector_versions Type: 11 (.google.cloud.connectors.v1.ConnectorVersion)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::ConnectorVersion::SupportedRuntimeFeatures ===
    # Fields for SupportedRuntimeFeatures
    # Field: entity_apis Type: 8 ()
    # Field: action_apis Type: 8 ()
    # Field: sql_query Type: 8 ()

# === Message: Google::Cloud::Connectors::V1::ConnectorVersion::EgressControlConfig ===
    # Fields for EgressControlConfig
    # Field: backends Type: 9 ()
    # Field: extraction_rules Type: 11 (.google.cloud.connectors.v1.ExtractionRules)

# === Message: Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRules ===
    # Fields for ExtractionRules
    # Field: extraction_rule Type: 11 (.google.cloud.connectors.v1.ExtractionRule)

# === Message: Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule ===
    # Fields for ExtractionRule
    # Field: source Type: 11 (.google.cloud.connectors.v1.ExtractionRule.Source)
    # Field: extraction_regex Type: 9 ()

# Enum: ExtractionRule::SourceType
our $ExtractionRule_SOURCE_TYPE_UNSPECIFIED = 0;
our $ExtractionRule_CONFIG_VARIABLE = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::ConnectorVersion - Compiled Protocol Buffers messages for google/cloud/connectors/v1/connector_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::ConnectorVersion;

    my $msg = Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/connector_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion

ConnectorVersion indicates a specific version of a connector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the Version.
Format:
projects/{project}/locations/{location}/providers/{provider}/connectors/{connector}/versions/{version}
Only global location is supported for Connector resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Created time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Updated time.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion::LabelsEntry>)

Output only. Resource labels to represent user-provided metadata.
Refer to cloud documentation on labels for more details.
https://cloud.google.com/compute/docs/labeling-resources

=item * C<< $msg->launch_stage() >> / C<< $msg->launch_stage($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::LaunchStage>)

Output only. Flag to mark the version indicating the launch stage.

=item * C<< $msg->release_version() >> / C<< $msg->release_version($value) >>

Type: C<String>

Output only. ReleaseVersion of the connector, for example: "1.0.1-alpha".

=item * C<< $msg->auth_config_templates() >> / C<< $msg->auth_config_templates($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Authconfig::AuthConfigTemplate>)

Output only. List of auth configs supported by the Connector Version.

=item * C<< $msg->config_variable_templates() >> / C<< $msg->config_variable_templates($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::ConfigVariableTemplate>)

Output only. List of config variables needed to create a connection.

=item * C<< $msg->supported_runtime_features() >> / C<< $msg->supported_runtime_features($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::ConnectorVersion::SupportedRuntimeFeatures>)

Output only. Information about the runtime features supported by the
Connector.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name.

=item * C<< $msg->egress_control_config() >> / C<< $msg->egress_control_config($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::ConnectorVersion::EgressControlConfig>)

Output only. Configuration for Egress Control.

=item * C<< $msg->role_grants() >> / C<< $msg->role_grants($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::RoleGrant>)

Output only. Role grant configurations for this connector version.

=item * C<< $msg->role_grant() >> / C<< $msg->role_grant($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::RoleGrant>)

Output only. Role grant configuration for this config variable. It will be
DEPRECATED soon.

=item * C<< $msg->ssl_config_template() >> / C<< $msg->ssl_config_template($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::SslConfig::SslConfigTemplate>)

Output only. Ssl configuration supported by the Connector.

=back

=head2 Google::Cloud::Connectors::V1::ConnectorVersion::GetConnectorVersionRequest

Request message for Connectors.GetConnectorVersion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the form:
`projects/*/locations/*/providers/*/connectors/*/versions/*`
Only global location is supported for ConnectorVersion resource.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::ConnectorVersionView>)

Specifies which fields of the ConnectorVersion are returned in the
response. Defaults to `CUSTOMER` view.

=back

=head2 Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsRequest

Request message for Connectors.ListConnectorVersions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent resource of the connectors, of the form:
`projects/*/locations/*/providers/*/connectors/*`
Only global location is supported for ConnectorVersion resource.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Page token.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::ConnectorVersionView>)

Specifies which fields of the ConnectorVersion are returned in the
response. Defaults to `BASIC` view.

=back

=head2 Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsResponse

Response message for Connectors.ListConnectorVersions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connector_versions() >> / C<< $msg->connector_versions($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion>)

A list of connector versions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Next page token.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Connectors::V1::ConnectorVersion::SupportedRuntimeFeatures

Supported runtime features of a connector version. This is passed to the
management layer to add a new connector version by the connector developer.
Details about how this proto is passed to the management layer is covered in
this doc - go/runtime-manifest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entity_apis() >> / C<< $msg->entity_apis($value) >>

Type: C<Bool>

Specifies if the connector supports entity apis like 'createEntity'.

=item * C<< $msg->action_apis() >> / C<< $msg->action_apis($value) >>

Type: C<Bool>

Specifies if the connector supports action apis like 'executeAction'.

=item * C<< $msg->sql_query() >> / C<< $msg->sql_query($value) >>

Type: C<Bool>

Specifies if the connector supports 'ExecuteSqlQuery' operation.

=back

=head2 Google::Cloud::Connectors::V1::ConnectorVersion::EgressControlConfig

Egress control config for connector runtime. These configurations define the
rules to identify which outbound domains/hosts needs to be whitelisted. It
may be a static information for a particular connector version or it is
derived from the configurations provided by the customer in Connection
resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backends() >> / C<< $msg->backends($value) >>

Type: C<String>

Static Comma separated backends which are common for all Connection
resources. Supported formats for each backend are host:port or just
host (host can be ip address or domain name).

=item * C<< $msg->extraction_rules() >> / C<< $msg->extraction_rules($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRules>)

Extractions Rules to extract the backends from customer provided
configuration.

=back

=head2 Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRules

Extraction Rules to identity the backends from customer provided
configuration in Connection resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->extraction_rule() >> / C<< $msg->extraction_rule($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule>)

Collection of Extraction Rule.

=back

=head2 Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule

Extraction Rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule::Source>)

Source on which the rule is applied.

=item * C<< $msg->extraction_regex() >> / C<< $msg->extraction_regex($value) >>

Type: C<String>

Regex used to extract backend details from source. If empty, whole source
value will be used.

=back

=head3 Enum: ExtractionRule::SourceType

=over 4

=item * C<SOURCE_TYPE_UNSPECIFIED> => C<0>

=item * C<CONFIG_VARIABLE> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::ConnectorVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
