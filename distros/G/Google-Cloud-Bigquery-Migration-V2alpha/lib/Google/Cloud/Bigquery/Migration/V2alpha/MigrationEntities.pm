package Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities;

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
    eval { require Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask };
    eval { require Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails };
    eval { require Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics };
    eval { require Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::ErrorDetails };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyYWxwaGEvbWlncmF0aW9uX2Vu
dGl0aWVzLnByb3RvEidnb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEa
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aPWdvb2dsZS9jbG91ZC9iaWdxdWVyeS9taWdyYXRpb24vdjJhbHBoYS9hc3Nlc3Nt
ZW50X3Rhc2sucHJvdG8aRWdvb2dsZS9jbG91ZC9iaWdxdWVyeS9taWdyYXRpb24vdjJhbHBo
YS9taWdyYXRpb25fZXJyb3JfZGV0YWlscy5wcm90bxo/Z29vZ2xlL2Nsb3VkL2JpZ3F1ZXJ5
L21pZ3JhdGlvbi92MmFscGhhL21pZ3JhdGlvbl9tZXRyaWNzLnByb3RvGj5nb29nbGUvY2xv
dWQvYmlncXVlcnkvbWlncmF0aW9uL3YyYWxwaGEvdHJhbnNsYXRpb25fdGFzay5wcm90bxoZ
Z29vZ2xlL3Byb3RvYnVmL2FueS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90bxoeZ29vZ2xlL3JwYy9lcnJvcl9kZXRhaWxzLnByb3RvIssFChFNaWdyYXRpb25Xb3Jr
ZmxvdxIaCgRuYW1lGAEgASgJQgbgQQPgQQVSBG5hbWUSIQoMZGlzcGxheV9uYW1lGAYgASgJ
UgtkaXNwbGF5TmFtZRJbCgV0YXNrcxgCIAMoCzJFLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5t
aWdyYXRpb24udjJhbHBoYS5NaWdyYXRpb25Xb3JrZmxvdy5UYXNrc0VudHJ5UgV0YXNrcxJb
CgVzdGF0ZRgDIAEoDjJALmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBo
YS5NaWdyYXRpb25Xb3JrZmxvdy5TdGF0ZUID4EEDUgVzdGF0ZRI7CgtjcmVhdGVfdGltZRgE
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSRAoQbGFzdF91
cGRhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDmxhc3RVcGRh
dGVUaW1lGnAKClRhc2tzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSTAoFdmFsdWUYAiABKAsy
Ni5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuTWlncmF0aW9uVGFz
a1IFdmFsdWU6AjgBIlEKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCQoFRFJBRlQQ
ARILCgdSVU5OSU5HEAISCgoGUEFVU0VEEAMSDQoJQ09NUExFVEVEEAQ6depBcgoyYmlncXVl
cnltaWdyYXRpb24uZ29vZ2xlYXBpcy5jb20vTWlncmF0aW9uV29ya2Zsb3cSPHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS93b3JrZmxvd3Mve3dvcmtmbG93fSKN
BwoNTWlncmF0aW9uVGFzaxJ4Chdhc3Nlc3NtZW50X3Rhc2tfZGV0YWlscxgMIAEoCzI+Lmdv
b2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBoYS5Bc3Nlc3NtZW50VGFza0Rl
dGFpbHNIAFIVYXNzZXNzbWVudFRhc2tEZXRhaWxzEnsKGHRyYW5zbGF0aW9uX3Rhc2tfZGV0
YWlscxgNIAEoCzI/Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBoYS5U
cmFuc2xhdGlvblRhc2tEZXRhaWxzSABSFnRyYW5zbGF0aW9uVGFza0RldGFpbHMSFgoCaWQY
ASABKAlCBuBBA+BBBVICaWQSEgoEdHlwZRgCIAEoCVIEdHlwZRIuCgdkZXRhaWxzGAMgASgL
MhQuZ29vZ2xlLnByb3RvYnVmLkFueVIHZGV0YWlscxJXCgVzdGF0ZRgEIAEoDjI8Lmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBoYS5NaWdyYXRpb25UYXNrLlN0YXRl
QgPgQQNSBXN0YXRlEkUKEHByb2Nlc3NpbmdfZXJyb3IYBSABKAsyFS5nb29nbGUucnBjLkVy
cm9ySW5mb0ID4EEDUg9wcm9jZXNzaW5nRXJyb3ISOwoLY3JlYXRlX3RpbWUYBiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEkQKEGxhc3RfdXBkYXRlX3Rp
bWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg5sYXN0VXBkYXRlVGltZRKB
AQoUb3JjaGVzdHJhdGlvbl9yZXN1bHQYCiABKAsySS5nb29nbGUuY2xvdWQuYmlncXVlcnku
bWlncmF0aW9uLnYyYWxwaGEuTWlncmF0aW9uVGFza09yY2hlc3RyYXRpb25SZXN1bHRCA+BB
A1ITb3JjaGVzdHJhdGlvblJlc3VsdCJyCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAA
EgsKB1BFTkRJTkcQARIRCg1PUkNIRVNUUkFUSU5HEAISCwoHUlVOTklORxADEgoKBlBBVVNF
RBAEEg0KCVNVQ0NFRURFRBAFEgoKBkZBSUxFRBAGQg4KDHRhc2tfZGV0YWlscyLmBgoQTWln
cmF0aW9uU3VidGFzaxIaCgRuYW1lGAEgASgJQgbgQQPgQQVSBG5hbWUSFwoHdGFza19pZBgC
IAEoCVIGdGFza0lkEhIKBHR5cGUYAyABKAlSBHR5cGUSWgoFc3RhdGUYBSABKA4yPy5nb29n
bGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuTWlncmF0aW9uU3VidGFzay5T
dGF0ZUID4EEDUgVzdGF0ZRJFChBwcm9jZXNzaW5nX2Vycm9yGAYgASgLMhUuZ29vZ2xlLnJw
Yy5FcnJvckluZm9CA+BBA1IPcHJvY2Vzc2luZ0Vycm9yEncKFnJlc291cmNlX2Vycm9yX2Rl
dGFpbHMYDCADKAsyPC5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEu
UmVzb3VyY2VFcnJvckRldGFpbEID4EEDUhRyZXNvdXJjZUVycm9yRGV0YWlscxIwChRyZXNv
dXJjZV9lcnJvcl9jb3VudBgNIAEoBVIScmVzb3VyY2VFcnJvckNvdW50EjsKC2NyZWF0ZV90
aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRJEChBs
YXN0X3VwZGF0ZV90aW1lGAggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIObGFz
dFVwZGF0ZVRpbWUSTQoHbWV0cmljcxgLIAMoCzIzLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5t
aWdyYXRpb24udjJhbHBoYS5UaW1lU2VyaWVzUgdtZXRyaWNzIl4KBVN0YXRlEhUKEVNUQVRF
X1VOU1BFQ0lGSUVEEAASCgoGQUNUSVZFEAESCwoHUlVOTklORxACEg0KCVNVQ0NFRURFRBAD
EgoKBkZBSUxFRBAEEgoKBlBBVVNFRBAFOogB6kGEAQoxYmlncXVlcnltaWdyYXRpb24uZ29v
Z2xlYXBpcy5jb20vTWlncmF0aW9uU3VidGFzaxJPcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L3dvcmtmbG93cy97d29ya2Zsb3d9L3N1YnRhc2tzL3tzdWJ0YXNr
fSKtAQogTWlncmF0aW9uVGFza09yY2hlc3RyYXRpb25SZXN1bHQSfgoSYXNzZXNzbWVudF9k
ZXRhaWxzGAEgASgLMk0uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhh
LkFzc2Vzc21lbnRPcmNoZXN0cmF0aW9uUmVzdWx0RGV0YWlsc0gAUhFhc3Nlc3NtZW50RGV0
YWlsc0IJCgdkZXRhaWxzQuYBCitjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlv
bi52MmFscGhhQhZNaWdyYXRpb25FbnRpdGllc1Byb3RvUAFaSWNsb3VkLmdvb2dsZS5jb20v
Z28vYmlncXVlcnkvbWlncmF0aW9uL2FwaXYyYWxwaGEvbWlncmF0aW9ucGI7bWlncmF0aW9u
cGKqAidHb29nbGUuQ2xvdWQuQmlnUXVlcnkuTWlncmF0aW9uLlYyQWxwaGHKAidHb29nbGVc
Q2xvdWRcQmlnUXVlcnlcTWlncmF0aW9uXFYyYWxwaGFKk0EKBxIFDgDzAQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADAKCQoCAwASAxIAKQoJCgIDARID
EwAjCgkKAgMCEgMUAEcKCQoCAwMSAxUATwoJCgIDBBIDFgBJCgkKAgMFEgMXAEgKCQoCAwYS
AxgAIwoJCgIDBxIDGQApCgkKAgMIEgMaACgKCAoBCBIDHABECgkKAgglEgMcAEQKCAoBCBID
HQBgCgkKAggLEgMdAGAKCAoBCBIDHgAiCgkKAggKEgMeACIKCAoBCBIDHwA3CgkKAggIEgMf
ADcKCAoBCBIDIABECgkKAggBEgMgAEQKCAoBCBIDIQBFCgkKAggpEgMhAEUKXwoCBAASBCUA
WwEaUyBBIG1pZ3JhdGlvbiB3b3JrZmxvdyB3aGljaCBzcGVjaWZpZXMgd2hhdCBuZWVkcyB0
byBiZSBkb25lIGZvciBhbiBFRFcKIG1pZ3JhdGlvbi4KCgoKAwQAARIDJQgZCgsKAwQABxIE
JgIpBAoNCgUEAAedCBIEJgIpBAozCgQEAAQAEgQsAj8DGiUgUG9zc2libGUgbWlncmF0aW9u
IHdvcmtmbG93IHN0YXRlcy4KCgwKBQQABAABEgMsBwwKLwoGBAAEAAIAEgMuBBoaICBXb3Jr
ZmxvdyBzdGF0ZSBpcyB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAy4EFQoOCgcEAAQAAgAC
EgMuGBkKXQoGBAAEAAIBEgMyBA4aTiBXb3JrZmxvdyBpcyBpbiBkcmFmdCBzdGF0dXMsIGku
ZS4gdGFza3MgYXJlIG5vdCB5ZXQgZWxpZ2libGUgZm9yCiBleGVjdXRpb24uCgoOCgcEAAQA
AgEBEgMyBAkKDgoHBAAEAAIBAhIDMgwNCk0KBgQABAACAhIDNQQQGj4gV29ya2Zsb3cgaXMg
cnVubmluZyAoaS5lLiB0YXNrcyBhcmUgZWxpZ2libGUgZm9yIGV4ZWN1dGlvbikuCgoOCgcE
AAQAAgIBEgM1BAsKDgoHBAAEAAICAhIDNQ4PCncKBgQABAACAxIDOQQPGmggV29ya2Zsb3cg
aXMgcGF1c2VkLiBUYXNrcyBjdXJyZW50bHkgaW4gcHJvZ3Jlc3MgbWF5IGNvbnRpbnVlLCBi
dXQgbm8KIGZ1cnRoZXIgdGFza3Mgd2lsbCBiZSBzY2hlZHVsZWQuCgoOCgcEAAQAAgMBEgM5
BAoKDgoHBAAEAAIDAhIDOQ0OCqYBCgYEAAQAAgQSAz4EEhqWASBXb3JrZmxvdyBpcyBjb21w
bGV0ZS4gVGhlcmUgc2hvdWxkIG5vdCBiZSBhbnkgdGFzayBpbiBhIG5vbi10ZXJtaW5hbAog
c3RhdGUsIGJ1dCBpZiB0aGV5IGFyZSAoZS5nLiBmb3JjZWQgdGVybWluYXRpb24pLCB0aGV5
IHdpbGwgbm90IGJlCiBzY2hlZHVsZWQuCgoOCgcEAAQAAgQBEgM+BA0KDgoHBAAEAAIEAhID
PhARCqwBCgQEAAIAEgRFAkgEGp0BIE91dHB1dCBvbmx5LiBJbW11dGFibGUuIFRoZSB1bmlx
dWUgaWRlbnRpZmllciBmb3IgdGhlIG1pZ3JhdGlvbiB3b3JrZmxvdy4gVGhlIElEIGlzCiBz
ZXJ2ZXItZ2VuZXJhdGVkLgoKIEV4YW1wbGU6IGBwcm9qZWN0cy8xMjMvbG9jYXRpb25zL3Vz
L3dvcmtmbG93cy8zNDVgCgoMCgUEAAIABRIDRQIICgwKBQQAAgABEgNFCQ0KDAoFBAACAAMS
A0UQEQoNCgUEAAIACBIERRJIAwoPCggEAAIACJwIABIDRgQtCg8KCAQAAgAInAgBEgNHBCsK
nQEKBAQAAgESA0wCGhqPASBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSB3b3JrZmxvdy4gVGhp
cyBjYW4gYmUgc2V0IHRvIGdpdmUgYSB3b3JrZmxvdwogYSBkZXNjcmlwdGl2ZSBuYW1lLiBU
aGVyZSBpcyBubyBndWFyYW50ZWUgb3IgZW5mb3JjZW1lbnQgb2YgdW5pcXVlbmVzcy4KCgwK
BQQAAgEFEgNMAggKDAoFBAACAQESA0wJFQoMCgUEAAIBAxIDTBgZCqUBCgQEAAICEgNRAica
lwEgVGhlIHRhc2tzIGluIGEgd29ya2Zsb3cgaW4gYSBuYW1lZCBtYXAuIFRoZSBuYW1lIChp
LmUuIGtleSkgaGFzIG5vCiBtZWFuaW5nIGFuZCBpcyBtZXJlbHkgYSBjb252ZW5pZW50IHdh
eSB0byBhZGRyZXNzIGEgc3BlY2lmaWMgdGFzawogaW4gYSB3b3JrZmxvdy4KCgwKBQQAAgIG
EgNRAhwKDAoFBAACAgESA1EdIgoMCgUEAAICAxIDUSUmCjgKBAQAAgMSA1QCPhorIE91dHB1
dCBvbmx5LiBUaGF0IHN0YXR1cyBvZiB0aGUgd29ya2Zsb3cuCgoMCgUEAAIDBhIDVAIHCgwK
BQQAAgMBEgNUCA0KDAoFBAACAwMSA1QQEQoMCgUEAAIDCBIDVBI9Cg8KCAQAAgMInAgAEgNU
EzwKMgoEBAACBBIDVwIsGiUgVGltZSB3aGVuIHRoZSB3b3JrZmxvdyB3YXMgY3JlYXRlZC4K
CgwKBQQAAgQGEgNXAhsKDAoFBAACBAESA1ccJwoMCgUEAAIEAxIDVyorCjcKBAQAAgUSA1oC
MRoqIFRpbWUgd2hlbiB0aGUgd29ya2Zsb3cgd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgUG
EgNaAhsKDAoFBAACBQESA1ocLAoMCgUEAAIFAxIDWi8wCmQKAgQBEgVfAJ4BARpXIEEgc2lu
Z2xlIHRhc2sgZm9yIGEgbWlncmF0aW9uIHdoaWNoIGhhcyBkZXRhaWxzIGFib3V0IHRoZSBj
b25maWd1cmF0aW9uIG9mCiB0aGUgdGFzay4KCgoKAwQBARIDXwgVCjQKBAQBBAASBGECdwMa
JiBQb3NzaWJsZSBzdGF0ZXMgb2YgYSBtaWdyYXRpb24gdGFzay4KCgwKBQQBBAABEgNhBwwK
KgoGBAEEAAIAEgNjBBoaGyBUaGUgc3RhdGUgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAQQAAgAB
EgNjBBUKDgoHBAEEAAIAAhIDYxgZCjcKBgQBBAACARIDZgQQGiggVGhlIHRhc2sgaXMgd2Fp
dGluZyBmb3Igb3JjaGVzdHJhdGlvbi4KCg4KBwQBBAACAQESA2YECwoOCgcEAQQAAgECEgNm
Dg8KOQoGBAEEAAICEgNpBBYaKiBUaGUgdGFzayBpcyBhc3NpZ25lZCB0byBhbiBvcmNoZXN0
cmF0b3IuCgoOCgcEAQQAAgIBEgNpBBEKDgoHBAEEAAICAhIDaRQVClAKBgQBBAACAxIDbAQQ
GkEgVGhlIHRhc2sgaXMgcnVubmluZywgaS5lLiBpdHMgc3VidGFza3MgYXJlIHJlYWR5IGZv
ciBleGVjdXRpb24uCgoOCgcEAQQAAgMBEgNsBAsKDgoHBAEEAAIDAhIDbA4PCmwKBgQBBAAC
BBIDcAQPGl0gVGhhIHRhc2sgaXMgcGF1c2VkLiBBc3NpZ25lZCBzdWJ0YXNrcyBjYW4gY29u
dGludWUsIGJ1dCBubyBuZXcgc3VidGFza3MKIHdpbGwgYmUgc2NoZWR1bGVkLgoKDgoHBAEE
AAIEARIDcAQKCg4KBwQBBAACBAISA3ANDgowCgYEAQQAAgUSA3MEEhohIFRoZSB0YXNrIGZp
bmlzaGVkIHN1Y2Nlc3NmdWxseS4KCg4KBwQBBAACBQESA3MEDQoOCgcEAQQAAgUCEgNzEBEK
MgoGBAEEAAIGEgN2BA8aIyBUaGUgdGFzayBmaW5pc2hlZCB1bnN1Y2Nlc3NmdWxseS4KCg4K
BwQBBAACBgESA3YECgoOCgcEAQQAAgYCEgN2DQ4KKQoEBAEIABIFegKAAQMaGiBUaGUgZGV0
YWlscyBvZiB0aGUgdGFzay4KCgwKBQQBCAABEgN6CBQKMQoEBAECABIDfAQ3GiQgVGFzayBj
b25maWd1cmF0aW9uIGZvciBBc3Nlc3NtZW50LgoKDAoFBAECAAYSA3wEGQoMCgUEAQIAARID
fBoxCgwKBQQBAgADEgN8NDYKRAoEBAECARIDfwQ5GjcgVGFzayBjb25maWd1cmF0aW9uIGZv
ciBCYXRjaC9PZmZsaW5lIFNRTCBUcmFuc2xhdGlvbi4KCgwKBQQBAgEGEgN/BBoKDAoFBAEC
AQESA38bMwoMCgUEAQIBAxIDfzY4CnMKBAQBAgISBoMBAoYBBBpjIE91dHB1dCBvbmx5LiBJ
bW11dGFibGUuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIG1pZ3JhdGlvbiB0YXNr
LiBUaGUgSUQgaXMgc2VydmVyLWdlbmVyYXRlZC4KCg0KBQQBAgIFEgSDAQIICg0KBQQBAgIB
EgSDAQkLCg0KBQQBAgIDEgSDAQ4PCg8KBQQBAgIIEgaDARCGAQMKEAoIBAECAgicCAASBIQB
BC0KEAoIBAECAgicCAESBIUBBCsKSQoEBAECAxIEiQECEho7IFRoZSB0eXBlIG9mIHRoZSB0
YXNrLiBUaGlzIG11c3QgYmUgYSBzdXBwb3J0ZWQgdGFzayB0eXBlLgoKDQoFBAECAwUSBIkB
AggKDQoFBAECAwESBIkBCQ0KDQoFBAECAwMSBIkBEBEKvQEKBAQBAgQSBI4BAiIargEgREVQ
UkVDQVRFRCEgVXNlIG9uZSBvZiB0aGUgdGFza19kZXRhaWxzIGJlbG93LgogVGhlIGRldGFp
bHMgb2YgdGhlIHRhc2suIFRoZSB0eXBlIFVSTCBtdXN0IGJlIG9uZSBvZiB0aGUgc3VwcG9y
dGVkIHRhc2sKIGRldGFpbHMgbWVzc2FnZXMgYW5kIGNvcnJlc3BvbmQgdG8gdGhlIFRhc2sn
cyB0eXBlLgoKDQoFBAECBAYSBI4BAhUKDQoFBAECBAESBI4BFh0KDQoFBAECBAMSBI4BICEK
OwoEBAECBRIEkQECPhotIE91dHB1dCBvbmx5LiBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGUg
dGFzay4KCg0KBQQBAgUGEgSRAQIHCg0KBQQBAgUBEgSRAQgNCg0KBQQBAgUDEgSRARARCg0K
BQQBAgUIEgSRARI9ChAKCAQBAgUInAgAEgSRARM8CmMKBAQBAgYSBJQBAlgaVSBPdXRwdXQg
b25seS4gQW4gZXhwbGFuYXRpb24gdGhhdCBtYXkgYmUgcG9wdWxhdGVkIHdoZW4gdGhlIHRh
c2sgaXMgaW4gRkFJTEVEIHN0YXRlLgoKDQoFBAECBgYSBJQBAhYKDQoFBAECBgESBJQBFycK
DQoFBAECBgMSBJQBKisKDQoFBAECBggSBJQBLFcKEAoIBAECBgicCAASBJQBLVYKLwoEBAEC
BxIElwECLBohIFRpbWUgd2hlbiB0aGUgdGFzayB3YXMgY3JlYXRlZC4KCg0KBQQBAgcGEgSX
AQIbCg0KBQQBAgcBEgSXARwnCg0KBQQBAgcDEgSXASorCjQKBAQBAggSBJoBAjEaJiBUaW1l
IHdoZW4gdGhlIHRhc2sgd2FzIGxhc3QgdXBkYXRlZC4KCg0KBQQBAggGEgSaAQIbCg0KBQQB
AggBEgSaARwsCg0KBQQBAggDEgSaAS8wCkwKBAQBAgkSBJ0BAmkaPiBPdXRwdXQgb25seS4g
QWRkaXRpb25hbCBpbmZvcm1hdGlvbiBhYm91dCB0aGUgb3JjaGVzdHJhdGlvbi4KCg0KBQQB
AgkGEgSdAQIiCg0KBQQBAgkBEgSdASM3Cg0KBQQBAgkDEgSdATo8Cg0KBQQBAgkIEgSdAT1o
ChAKCAQBAgkInAgAEgSdAT5nCuoBCgIEAhIGowEA6QEBGtsBIEEgc3VidGFzayBmb3IgYSBt
aWdyYXRpb24gd2hpY2ggY2FycmllcyBkZXRhaWxzIGFib3V0IHRoZSBjb25maWd1cmF0aW9u
IG9mCiB0aGUgc3VidGFzay4gVGhlIGNvbnRlbnQgb2YgdGhlIGRldGFpbHMgc2hvdWxkIG5v
dCBtYXR0ZXIgdG8gdGhlIGVuZCB1c2VyLAogYnV0IGlzIGEgY29udHJhY3QgYmV0d2VlbiB0
aGUgc3VidGFzayBjcmVhdG9yIGFuZCBzdWJ0YXNrIHdvcmtlci4KCgsKAwQCARIEowEIGAoN
CgMEAgcSBqQBAqcBBAoPCgUEAgedCBIGpAECpwEECjkKBAQCBAASBqoBAr0BAxopIFBvc3Np
YmxlIHN0YXRlcyBvZiBhIG1pZ3JhdGlvbiBzdWJ0YXNrLgoKDQoFBAIEAAESBKoBBwwKKwoG
BAIEAAIAEgSsAQQaGhsgVGhlIHN0YXRlIGlzIHVuc3BlY2lmaWVkLgoKDwoHBAIEAAIAARIE
rAEEFQoPCgcEAgQAAgACEgSsARgZCkcKBgQCBAACARIErwEEDxo3IFRoZSBzdWJ0YXNrIGlz
IHJlYWR5LCBpLmUuIGl0IGlzIHJlYWR5IGZvciBleGVjdXRpb24uCgoPCgcEAgQAAgEBEgSv
AQQKCg8KBwQCBAACAQISBK8BDQ4KWAoGBAIEAAICEgSyAQQQGkggVGhlIHN1YnRhc2sgaXMg
cnVubmluZywgaS5lLiBpdCBpcyBhc3NpZ25lZCB0byBhIHdvcmtlciBmb3IgZXhlY3V0aW9u
LgoKDwoHBAIEAAICARIEsgEECwoPCgcEAgQAAgICEgSyAQ4PCjQKBgQCBAACAxIEtQEEEhok
IFRoZSBzdWJ0YXNrIGZpbmlzaGVkIHN1Y2Nlc3NmdWxseS4KCg8KBwQCBAACAwESBLUBBA0K
DwoHBAIEAAIDAhIEtQEQEQo2CgYEAgQAAgQSBLgBBA8aJiBUaGUgc3VidGFzayBmaW5pc2hl
ZCB1bnN1Y2Nlc3NmdWxseS4KCg8KBwQCBAACBAESBLgBBAoKDwoHBAIEAAIEAhIEuAENDgqm
AQoGBAIEAAIFEgS8AQQPGpUBIFRoZSBzdWJ0YXNrIGlzIHBhdXNlZCwgaS5lLiwgaXQgd2ls
bCBub3QgYmUgc2NoZWR1bGVkLiBJZiBpdCB3YXMgYWxyZWFkeQogYXNzaWduZWQsaXQgbWln
aHQgc3RpbGwgZmluaXNoIGJ1dCBubyBuZXcgbGVhc2UgcmVuZXdhbHMgd2lsbCBiZSBncmFu
dGVkLgoKDwoHBAIEAAIFARIEvAEECgoPCgcEAgQAAgUCEgS8AQ0OCrYBCgQEAgIAEgbDAQLG
AQQapQEgT3V0cHV0IG9ubHkuIEltbXV0YWJsZS4gVGhlIHJlc291cmNlIG5hbWUgZm9yIHRo
ZSBtaWdyYXRpb24gc3VidGFzay4gVGhlIElEIGlzCiBzZXJ2ZXItZ2VuZXJhdGVkLgoKIEV4
YW1wbGU6IGBwcm9qZWN0cy8xMjMvbG9jYXRpb25zL3VzL3dvcmtmbG93cy8zNDUvc3VidGFz
a3MvNjc4YAoKDQoFBAICAAUSBMMBAggKDQoFBAICAAESBMMBCQ0KDQoFBAICAAMSBMMBEBEK
DwoFBAICAAgSBsMBEsYBAwoQCggEAgIACJwIABIExAEELQoQCggEAgIACJwIARIExQEEKwpI
CgQEAgIBEgTJAQIVGjogVGhlIHVuaXF1ZSBJRCBvZiB0aGUgdGFzayB0byB3aGljaCB0aGlz
IHN1YnRhc2sgYmVsb25ncy4KCg0KBQQCAgEFEgTJAQIICg0KBQQCAgEBEgTJAQkQCg0KBQQC
AgEDEgTJARMUCooCCgQEAgICEgTPAQISGvsBIFRoZSB0eXBlIG9mIHRoZSBTdWJ0YXNrLiBU
aGUgbWlncmF0aW9uIHNlcnZpY2UgZG9lcyBub3QgY2hlY2sgd2hldGhlciB0aGlzCiBpcyBh
IGtub3duIHR5cGUuIEl0IGlzIHVwIHRvIHRoZSB0YXNrIGNyZWF0b3IgKGkuZS4gb3JjaGVz
dHJhdG9yIG9yIHdvcmtlcikKIHRvIGVuc3VyZSBpdCBvbmx5IGNyZWF0ZXMgc3VidGFza3Mg
Zm9yIHdoaWNoIHRoZXJlIGFyZSBjb21wYXRpYmxlIHdvcmtlcnMKIHBvbGxpbmcgZm9yIFN1
YnRhc2tzLgoKDQoFBAICAgUSBM8BAggKDQoFBAICAgESBM8BCQ0KDQoFBAICAgMSBM8BEBEK
PgoEBAICAxIE0gECPhowIE91dHB1dCBvbmx5LiBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGUg
c3VidGFzay4KCg0KBQQCAgMGEgTSAQIHCg0KBQQCAgMBEgTSAQgNCg0KBQQCAgMDEgTSARAR
Cg0KBQQCAgMIEgTSARI9ChAKCAQCAgMInAgAEgTSARM8CmMKBAQCAgQSBNUBAlgaVSBPdXRw
dXQgb25seS4gQW4gZXhwbGFuYXRpb24gdGhhdCBtYXkgYmUgcG9wdWxhdGVkIHdoZW4gdGhl
IHRhc2sgaXMgaW4gRkFJTEVEIHN0YXRlLgoKDQoFBAICBAYSBNUBAhYKDQoFBAICBAESBNUB
FycKDQoFBAICBAMSBNUBKisKDQoFBAICBAgSBNUBLFcKEAoIBAICBAicCAASBNUBLVYKrwEK
BAQCAgUSBNkBAmcaoAEgT3V0cHV0IG9ubHkuIFByb3ZpZGVzIGRldGFpbHMgdG8gZXJyb3Jz
IGFuZCBpc3N1ZXMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUKIHN1YnRhc2su
IFByZXNlbmNlIG9mIGVycm9yIGRldGFpbHMgZG9lcyBub3QgbWVhbiB0aGF0IHRoZSBzdWJ0
YXNrIGZhaWxlZC4KCg0KBQQCAgUEEgTZAQIKCg0KBQQCAgUGEgTZAQseCg0KBQQCAgUBEgTZ
AR81Cg0KBQQCAgUDEgTZATg6Cg0KBQQCAgUIEgTZATtmChAKCAQCAgUInAgAEgTZATxlCpUC
CgQEAgIGEgTfAQIiGoYCIFRoZSBudW1iZXIgb3IgcmVzb3VyY2VzIHdpdGggZXJyb3JzLiBO
b3RlOiBUaGlzIGlzIG5vdCB0aGUgdG90YWwKIG51bWJlciBvZiBlcnJvcnMgYXMgZWFjaCBy
ZXNvdXJjZSBjYW4gaGF2ZSBtb3JlIHRoYW4gb25lIGVycm9yLgogVGhpcyBpcyB1c2VkIHRv
IGluZGljYXRlIHRydW5jYXRpb24gYnkgaGF2aW5nIGEgYHJlc291cmNlX2Vycm9yX2NvdW50
YAogdGhhdCBpcyBoaWdoZXIgdGhhbiB0aGUgc2l6ZSBvZiBgcmVzb3VyY2VfZXJyb3JfZGV0
YWlsc2AuCgoNCgUEAgIGBRIE3wECBwoNCgUEAgIGARIE3wEIHAoNCgUEAgIGAxIE3wEfIQoy
CgQEAgIHEgTiAQIsGiQgVGltZSB3aGVuIHRoZSBzdWJ0YXNrIHdhcyBjcmVhdGVkLgoKDQoF
BAICBwYSBOIBAhsKDQoFBAICBwESBOIBHCcKDQoFBAICBwMSBOIBKisKNwoEBAICCBIE5QEC
MRopIFRpbWUgd2hlbiB0aGUgc3VidGFzayB3YXMgbGFzdCB1cGRhdGVkLgoKDQoFBAICCAYS
BOUBAhsKDQoFBAICCAESBOUBHCwKDQoFBAICCAMSBOUBLzAKLAoEBAICCRIE6AECIxoeIFRo
ZSBtZXRyaWNzIGZvciB0aGUgc3VidGFzay4KCg0KBQQCAgkEEgToAQIKCg0KBQQCAgkGEgTo
AQsVCg0KBQQCAgkBEgToARYdCg0KBQQCAgkDEgToASAiCmoKAgQDEgbtAQDzAQEaXCBBZGRp
dGlvbmFsIGluZm9ybWF0aW9uIGZyb20gdGhlIG9yY2hlc3RyYXRvciB3aGVuIGl0IGlzIGRv
bmUgd2l0aCB0aGUKIHRhc2sgb3JjaGVzdHJhdGlvbi4KCgsKAwQDARIE7QEIKAo0CgQEAwgA
EgbvAQLyAQMaJCBEZXRhaWxzIHNwZWNpZmljIHRvIHRoZSB0YXNrIHR5cGUuCgoNCgUEAwgA
ARIE7wEIDwo6CgQEAwIAEgTxAQRAGiwgRGV0YWlscyBzcGVjaWZpYyB0byBhc3Nlc3NtZW50
IHRhc2sgdHlwZXMuCgoNCgUEAwIABhIE8QEEKAoNCgUEAwIAARIE8QEpOwoNCgUEAwIAAxIE
8QE+P2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow ===
    # Fields for MigrationWorkflow
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: tasks Type: 11 (.google.cloud.bigquery.migration.v2alpha.MigrationWorkflow.TasksEntry)
    # Field: state Type: 14 (.google.cloud.bigquery.migration.v2alpha.MigrationWorkflow.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: MigrationWorkflow::State
our $MigrationWorkflow_STATE_UNSPECIFIED = 0;
our $MigrationWorkflow_DRAFT = 1;
our $MigrationWorkflow_RUNNING = 2;
our $MigrationWorkflow_PAUSED = 3;
our $MigrationWorkflow_COMPLETED = 4;

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTask ===
    # Fields for MigrationTask
    # Field: assessment_task_details Type: 11 (.google.cloud.bigquery.migration.v2alpha.AssessmentTaskDetails)
    # Field: translation_task_details Type: 11 (.google.cloud.bigquery.migration.v2alpha.TranslationTaskDetails)
    # Field: id Type: 9 ()
    # Field: type Type: 9 ()
    # Field: details Type: 11 (.google.protobuf.Any)
    # Field: state Type: 14 (.google.cloud.bigquery.migration.v2alpha.MigrationTask.State)
    # Field: processing_error Type: 11 (.google.rpc.ErrorInfo)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: orchestration_result Type: 11 (.google.cloud.bigquery.migration.v2alpha.MigrationTaskOrchestrationResult)

# Enum: MigrationTask::State
our $MigrationTask_STATE_UNSPECIFIED = 0;
our $MigrationTask_PENDING = 1;
our $MigrationTask_ORCHESTRATING = 2;
our $MigrationTask_RUNNING = 3;
our $MigrationTask_PAUSED = 4;
our $MigrationTask_SUCCEEDED = 5;
our $MigrationTask_FAILED = 6;

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationSubtask ===
    # Fields for MigrationSubtask
    # Field: name Type: 9 ()
    # Field: task_id Type: 9 ()
    # Field: type Type: 9 ()
    # Field: state Type: 14 (.google.cloud.bigquery.migration.v2alpha.MigrationSubtask.State)
    # Field: processing_error Type: 11 (.google.rpc.ErrorInfo)
    # Field: resource_error_details Type: 11 (.google.cloud.bigquery.migration.v2alpha.ResourceErrorDetail)
    # Field: resource_error_count Type: 5 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: metrics Type: 11 (.google.cloud.bigquery.migration.v2alpha.TimeSeries)

# Enum: MigrationSubtask::State
our $MigrationSubtask_STATE_UNSPECIFIED = 0;
our $MigrationSubtask_ACTIVE = 1;
our $MigrationSubtask_RUNNING = 2;
our $MigrationSubtask_SUCCEEDED = 3;
our $MigrationSubtask_FAILED = 4;
our $MigrationSubtask_PAUSED = 5;

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTaskOrchestrationResult ===
    # Fields for MigrationTaskOrchestrationResult
    # Field: assessment_details Type: 11 (.google.cloud.bigquery.migration.v2alpha.AssessmentOrchestrationResultDetails)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2alpha/migration_entities.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities;

    my $msg = Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow->new({
        name => $name,
        display_name => $display_name,
        tasks => $tasks,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2alpha/migration_entities.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow

A migration workflow which specifies what needs to be done for an EDW
migration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Immutable. The unique identifier for the migration workflow. The ID is
server-generated.

Example: `projects/123/locations/us/workflows/345`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the workflow. This can be set to give a workflow
a descriptive name. There is no guarantee or enforcement of uniqueness.

=item * C<< $msg->tasks() >> / C<< $msg->tasks($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow::TasksEntry>)

The tasks in a workflow in a named map. The name (i.e. key) has no
meaning and is merely a convenient way to address a specific task
in a workflow.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationWorkflow::State>)

Output only. That status of the workflow.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the workflow was created.

=item * C<< $msg->last_update_time() >> / C<< $msg->last_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the workflow was last updated.

=back

=head3 Enum: MigrationWorkflow::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<DRAFT> => C<1>

=item * C<RUNNING> => C<2>

=item * C<PAUSED> => C<3>

=item * C<COMPLETED> => C<4>

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTask

A single task for a migration which has details about the configuration of
the task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->assessment_task_details() >> / C<< $msg->assessment_task_details($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::AssessmentTaskDetails>)

Task configuration for Assessment.

=item * C<< $msg->translation_task_details() >> / C<< $msg->translation_task_details($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails>)

Task configuration for Batch/Offline SQL Translation.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. Immutable. The unique identifier for the migration task. The ID is server-generated.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of the task. This must be a supported task type.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

DEPRECATED! Use one of the task_details below.
The details of the task. The type URL must be one of the supported task
details messages and correspond to the Task's type.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationTask::State>)

Output only. The current state of the task.

=item * C<< $msg->processing_error() >> / C<< $msg->processing_error($value) >>

Type: C<Message> (L<Google::Rpc::ErrorDetails::ErrorInfo>)

Output only. An explanation that may be populated when the task is in FAILED state.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the task was created.

=item * C<< $msg->last_update_time() >> / C<< $msg->last_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the task was last updated.

=item * C<< $msg->orchestration_result() >> / C<< $msg->orchestration_result($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTaskOrchestrationResult>)

Output only. Additional information about the orchestration.

=back

=head3 Enum: MigrationTask::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<ORCHESTRATING> => C<2>

=item * C<RUNNING> => C<3>

=item * C<PAUSED> => C<4>

=item * C<SUCCEEDED> => C<5>

=item * C<FAILED> => C<6>

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationSubtask

A subtask for a migration which carries details about the configuration of
the subtask. The content of the details should not matter to the end user,
but is a contract between the subtask creator and subtask worker.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Immutable. The resource name for the migration subtask. The ID is
server-generated.

Example: `projects/123/locations/us/workflows/345/subtasks/678`

=item * C<< $msg->task_id() >> / C<< $msg->task_id($value) >>

Type: C<String>

The unique ID of the task to which this subtask belongs.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of the Subtask. The migration service does not check whether this
is a known type. It is up to the task creator (i.e. orchestrator or worker)
to ensure it only creates subtasks for which there are compatible workers
polling for Subtasks.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationSubtask::State>)

Output only. The current state of the subtask.

=item * C<< $msg->processing_error() >> / C<< $msg->processing_error($value) >>

Type: C<Message> (L<Google::Rpc::ErrorDetails::ErrorInfo>)

Output only. An explanation that may be populated when the task is in FAILED state.

=item * C<< $msg->resource_error_details() >> / C<< $msg->resource_error_details($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ResourceErrorDetail>)

Output only. Provides details to errors and issues encountered while processing the
subtask. Presence of error details does not mean that the subtask failed.

=item * C<< $msg->resource_error_count() >> / C<< $msg->resource_error_count($value) >>

Type: C<Int32>

The number or resources with errors. Note: This is not the total
number of errors as each resource can have more than one error.
This is used to indicate truncation by having a `resource_error_count`
that is higher than the size of `resource_error_details`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the subtask was created.

=item * C<< $msg->last_update_time() >> / C<< $msg->last_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the subtask was last updated.

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeSeries>)

The metrics for the subtask.

=back

=head3 Enum: MigrationSubtask::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<RUNNING> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<PAUSED> => C<5>

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTaskOrchestrationResult

Additional information from the orchestrator when it is done with the
task orchestration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->assessment_details() >> / C<< $msg->assessment_details($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::AssessmentTask::AssessmentOrchestrationResultDetails>)

Details specific to assessment task types.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
