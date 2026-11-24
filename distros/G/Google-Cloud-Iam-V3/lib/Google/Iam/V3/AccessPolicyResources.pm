package Google::Iam::V3::AccessPolicyResources;

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
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvaWFtL3YzL2FjY2Vzc19wb2xpY3lfcmVzb3VyY2VzLnByb3RvEg1nb29nbGUu
aWFtLnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhtnb29nbGUvYXBpL2Zp
ZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8aFmdvb2dsZS90eXBlL2V4cHIucHJvdG8iiQYKDEFjY2Vz
c1BvbGljeRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSHQoDdWlkGAIgASgJQgvijM/XCAII
AeBBA1IDdWlkEhcKBGV0YWcYAyABKAlCA+BBAVIEZXRhZxImCgxkaXNwbGF5X25hbWUYBCAB
KAlCA+BBAVILZGlzcGxheU5hbWUSUwoLYW5ub3RhdGlvbnMYBSADKAsyLC5nb29nbGUuaWFt
LnYzLkFjY2Vzc1BvbGljeS5Bbm5vdGF0aW9uc0VudHJ5QgPgQQFSC2Fubm90YXRpb25zEkAK
C2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpj
cmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgp1cGRhdGVUaW1lEkEKB2RldGFpbHMYCCABKAsyIi5nb29nbGUuaWFtLnYz
LkFjY2Vzc1BvbGljeURldGFpbHNCA+BBAVIHZGV0YWlscxo+ChBBbm5vdGF0aW9uc0VudHJ5
EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6owLqQZ8CCh9p
YW0uZ29vZ2xlYXBpcy5jb20vQWNjZXNzUG9saWN5ElBvcmdhbml6YXRpb25zL3tvcmdhbml6
YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L2FjY2Vzc1BvbGljaWVzL3thY2Nlc3NfcG9s
aWN5fRJEZm9sZGVycy97Zm9sZGVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hY2Nlc3NQb2xp
Y2llcy97YWNjZXNzX3BvbGljeX0SRnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9hY2Nlc3NQb2xpY2llcy97YWNjZXNzX3BvbGljeX0qDmFjY2Vzc1BvbGljaWVz
MgxhY2Nlc3NQb2xpY3kiUQoTQWNjZXNzUG9saWN5RGV0YWlscxI6CgVydWxlcxgBIAMoCzIf
Lmdvb2dsZS5pYW0udjMuQWNjZXNzUG9saWN5UnVsZUID4EECUgVydWxlcyKXBQoQQWNjZXNz
UG9saWN5UnVsZRIqCgtkZXNjcmlwdGlvbhgBIAEoCUID4EEBSABSC2Rlc2NyaXB0aW9uiAEB
EkgKBmVmZmVjdBgCIAEoDjImLmdvb2dsZS5pYW0udjMuQWNjZXNzUG9saWN5UnVsZS5FZmZl
Y3RCA+BBAkgBUgZlZmZlY3SIAQESIwoKcHJpbmNpcGFscxgDIAMoCUID4EECUgpwcmluY2lw
YWxzEjQKE2V4Y2x1ZGVkX3ByaW5jaXBhbHMYBCADKAlCA+BBAVISZXhjbHVkZWRQcmluY2lw
YWxzEkwKCW9wZXJhdGlvbhgKIAEoCzIpLmdvb2dsZS5pYW0udjMuQWNjZXNzUG9saWN5UnVs
ZS5PcGVyYXRpb25CA+BBAlIJb3BlcmF0aW9uElQKCmNvbmRpdGlvbnMYCSADKAsyLy5nb29n
bGUuaWFtLnYzLkFjY2Vzc1BvbGljeVJ1bGUuQ29uZGl0aW9uc0VudHJ5QgPgQQFSCmNvbmRp
dGlvbnMaagoJT3BlcmF0aW9uEiUKC3Blcm1pc3Npb25zGAEgAygJQgPgQQFSC3Blcm1pc3Np
b25zEjYKFGV4Y2x1ZGVkX3Blcm1pc3Npb25zGAIgAygJQgPgQQFSE2V4Y2x1ZGVkUGVybWlz
c2lvbnMaUAoPQ29uZGl0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EicKBXZhbHVlGAIg
ASgLMhEuZ29vZ2xlLnR5cGUuRXhwclIFdmFsdWU6AjgBIjUKBkVmZmVjdBIWChJFRkZFQ1Rf
VU5TUEVDSUZJRUQQABIICgRERU5ZEAESCQoFQUxMT1cQAkIOCgxfZGVzY3JpcHRpb25CCQoH
X2VmZmVjdEKIAQoRY29tLmdvb2dsZS5pYW0udjNCGkFjY2Vzc1BvbGljeVJlc291cmNlc1By
b3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vaWFtL2FwaXYzL2lhbXBiO2lhbXBiqgITR29v
Z2xlLkNsb3VkLklhbS5WM8oCE0dvb2dsZVxDbG91ZFxJYW1cVjNK6UAKBxIFDgDXAQEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABYKCQoCAwASAxIAKQoJ
CgIDARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAKQoJCgIDBBIDFgAgCggKAQgSAxgAMAoJ
CgIIJRIDGAAwCggKAQgSAxkAQAoJCgIICxIDGQBACggKAQgSAxoAIgoJCgIIChIDGgAiCggK
AQgSAxsAOwoJCgIICBIDGwA7CggKAQgSAxwAKgoJCgIIARIDHAAqCggKAQgSAx0AMAoJCgII
KRIDHQAwCiwKAgQAEgQgAFIBGiAgQW4gSUFNIGFjY2VzcyBwb2xpY3kgcmVzb3VyY2UuCgoK
CgMEAAESAyAIFAoLCgMEAAcSBCECKAQKDQoFBAAHnQgSBCECKAQKowMKBAQAAgASAzICPRqV
AyBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYWNjZXNzIHBvbGljeS4K
CiBUaGUgZm9sbG93aW5nIGZvcm1hdHMgYXJlIHN1cHBvcnRlZDoKCiAqIGBwcm9qZWN0cy97
cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve3BvbGlj
eV9pZH1gCiAqIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRp
b259L2FjY2Vzc1BvbGljaWVzL3twb2xpY3lfaWR9YAogKiBgZm9sZGVycy97Zm9sZGVyX2lk
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hY2Nlc3NQb2xpY2llcy97cG9saWN5X2lkfWAKICog
YG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
YWNjZXNzUG9saWNpZXMve3BvbGljeV9pZH1gCgoMCgUEAAIABRIDMgIICgwKBQQAAgABEgMy
CQ0KDAoFBAACAAMSAzIQEQoMCgUEAAIACBIDMhI8Cg8KCAQAAgAInAgAEgMyEzsKSQoEBAAC
ARIENQI4BBo7IE91dHB1dCBvbmx5LiBUaGUgZ2xvYmFsbHkgdW5pcXVlIElEIG9mIHRoZSBh
Y2Nlc3MgcG9saWN5LgoKDAoFBAACAQUSAzUCCAoMCgUEAAIBARIDNQkMCgwKBQQAAgEDEgM1
DxAKDQoFBAACAQgSBDUROAMKEgoLBAACAQjM8fmKAQESAzYEKgoPCggEAAIBCJwIABIDNwQt
CnkKBAQAAgISAzwCOxpsIE9wdGlvbmFsLiBUaGUgZXRhZyBmb3IgdGhlIGFjY2VzcyBwb2xp
Y3kuCiBJZiB0aGlzIGlzIHByb3ZpZGVkIG9uIHVwZGF0ZSwgaXQgbXVzdCBtYXRjaCB0aGUg
c2VydmVyJ3MgZXRhZy4KCgwKBQQAAgIFEgM8AggKDAoFBAACAgESAzwJDQoMCgUEAAICAxID
PBARCgwKBQQAAgIIEgM8EjoKDwoIBAACAgicCAASAzwTOQpsCgQEAAIDEgNAAkMaXyBPcHRp
b25hbC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBhY2Nlc3MgcG9saWN5LiBNdXN0IGJlIGxl
c3MgdGhhbgogb3IgZXF1YWwgdG8gNjMgY2hhcmFjdGVycy4KCgwKBQQAAgMFEgNAAggKDAoF
BAACAwESA0AJFQoMCgUEAAIDAxIDQBgZCgwKBQQAAgMIEgNAGkIKDwoIBAACAwicCAASA0Ab
QQqVAQoEBAACBBIDRQJPGocBIE9wdGlvbmFsLiBVc2VyIGRlZmluZWQgYW5ub3RhdGlvbnMu
IFNlZQogaHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xNDgjYW5ub3RhdGlvbnMgZm9yIG1vcmUg
ZGV0YWlscyBzdWNoIGFzIGZvcm1hdCBhbmQKIHNpemUgbGltaXRhdGlvbnMKCgwKBQQAAgQG
EgNFAhUKDAoFBAACBAESA0UWIQoMCgUEAAIEAxIDRSQlCgwKBQQAAgQIEgNFJk4KDwoIBAAC
BAicCAASA0UnTQpJCgQEAAIFEgRIAkkyGjsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4g
dGhlIGFjY2VzcyBwb2xpY3kgd2FzIGNyZWF0ZWQuCgoMCgUEAAIFBhIDSAIbCgwKBQQAAgUB
EgNIHCcKDAoFBAACBQMSA0gqKwoMCgUEAAIFCBIDSQYxCg8KCAQAAgUInAgAEgNJBzAKWAoE
BAACBhIETQJOMhpKIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBhY2Nlc3MgcG9s
aWN5IHdhcyBtb3N0IHJlY2VudGx5CiB1cGRhdGVkLgoKDAoFBAACBgYSA00CGwoMCgUEAAIG
ARIDTRwnCgwKBQQAAgYDEgNNKisKDAoFBAACBggSA04GMQoPCggEAAIGCJwIABIDTgcwCjsK
BAQAAgcSA1ECSxouIE9wdGlvbmFsLiBUaGUgZGV0YWlscyBmb3IgdGhlIGFjY2VzcyBwb2xp
Y3kuCgoMCgUEAAIHBhIDUQIVCgwKBQQAAgcBEgNRFh0KDAoFBAACBwMSA1EgIQoMCgUEAAIH
CBIDUSJKCg8KCAQAAgcInAgAEgNRI0kKJAoCBAESBFUAWAEaGCBBY2Nlc3MgcG9saWN5IGRl
dGFpbHMuCgoKCgMEAQESA1UIGwo3CgQEAQIAEgNXAk8aKiBSZXF1aXJlZC4gQSBsaXN0IG9m
IGFjY2VzcyBwb2xpY3kgcnVsZXMuCgoMCgUEAQIABBIDVwIKCgwKBQQBAgAGEgNXCxsKDAoF
BAECAAESA1ccIQoMCgUEAQIAAxIDVyQlCgwKBQQBAgAIEgNXJk4KDwoIBAECAAicCAASA1cn
TQpNCgIEAhIFWwDXAQEaQCBBY2Nlc3MgUG9saWN5IFJ1bGUgdGhhdCBkZXRlcm1pbmVzIHRo
ZSBiZWhhdmlvciBvZiB0aGUgcG9saWN5LgoKCgoDBAIBEgNbCBgKXgoEBAIDABIEXgJwAxpQ
IEF0dHJpYnV0ZXMgdGhhdCBhcmUgdXNlZCB0byBkZXRlcm1pbmUgd2hldGhlciB0aGlzIHJ1
bGUgYXBwbGllcyB0byBhCiByZXF1ZXN0LgoKDAoFBAIDAAESA14KEwrMAgoGBAIDAAIAEgNl
BE0avAIgT3B0aW9uYWwuIFRoZSBwZXJtaXNzaW9ucyB0aGF0IGFyZSBleHBsaWNpdGx5IGFm
ZmVjdGVkIGJ5IHRoaXMgcnVsZS4gRWFjaAogcGVybWlzc2lvbiB1c2VzIHRoZSBmb3JtYXQg
YHtzZXJ2aWNlX2ZxZG59L3tyZXNvdXJjZX0ue3ZlcmJ9YCwgd2hlcmUKIGB7c2VydmljZV9m
cWRufWAgaXMgdGhlIGZ1bGx5IHF1YWxpZmllZCBkb21haW4gbmFtZSBmb3IgdGhlIHNlcnZp
Y2UuCiBDdXJyZW50bHkgc3VwcG9ydGVkIHBlcm1pc3Npb25zIGFyZSBhcyBmb2xsb3dzOgoK
ICogYGV2ZW50YXJjLmdvb2dsZWFwaXMuY29tL21lc3NhZ2VCdXNlcy5wdWJsaXNoYC4KCg4K
BwQCAwACAAQSA2UEDAoOCgcEAgMAAgAFEgNlDRMKDgoHBAIDAAIAARIDZRQfCg4KBwQCAwAC
AAMSA2UiIwoOCgcEAgMAAgAIEgNlJEwKEQoKBAIDAAIACJwIABIDZSVLCuACCgYEAgMAAgES
BG4EbzEazwIgT3B0aW9uYWwuIFNwZWNpZmllcyB0aGUgcGVybWlzc2lvbnMgdGhhdCB0aGlz
IHJ1bGUgZXhjbHVkZXMgZnJvbSB0aGUgc2V0CiBvZiBhZmZlY3RlZCBwZXJtaXNzaW9ucyBn
aXZlbiBieSBgcGVybWlzc2lvbnNgLiBJZiBhIHBlcm1pc3Npb24gYXBwZWFycwogaW4gYHBl
cm1pc3Npb25zYCBfYW5kXyBpbiBgZXhjbHVkZWRfcGVybWlzc2lvbnNgIHRoZW4gaXQgd2ls
bCBfbm90XyBiZQogc3ViamVjdCB0byB0aGUgcG9saWN5IGVmZmVjdC4KCiBUaGUgZXhjbHVk
ZWQgcGVybWlzc2lvbnMgY2FuIGJlIHNwZWNpZmllZCB1c2luZyB0aGUgc2FtZSBzeW50YXgg
YXMKIGBwZXJtaXNzaW9uc2AuCgoOCgcEAgMAAgEEEgNuBAwKDgoHBAIDAAIBBRIDbg0TCg4K
BwQCAwACAQESA24UKAoOCgcEAgMAAgEDEgNuKywKDgoHBAIDAAIBCBIDbwgwChEKCgQCAwAC
AQicCAASA28JLwo+CgQEAgQAEgRzAnwDGjAgQW4gZWZmZWN0IHRvIGRlc2NyaWJlIHRoZSBh
Y2Nlc3MgcmVsYXRpb25zaGlwLgoKDAoFBAIEAAESA3MHDQorCgYEAgQAAgASA3UEGxocIFRo
ZSBlZmZlY3QgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAgQAAgABEgN1BBYKDgoHBAIEAAIAAhID
dRkaCkUKBgQCBAACARIDeAQNGjYgVGhlIHBvbGljeSB3aWxsIGRlbnkgYWNjZXNzIGlmIGl0
IGV2YWx1YXRlcyB0byB0cnVlLgoKDgoHBAIEAAIBARIDeAQICg4KBwQCBAACAQISA3gLDApG
CgYEAgQAAgISA3sEDho3IFRoZSBwb2xpY3kgd2lsbCBncmFudCBhY2Nlc3MgaWYgaXQgZXZh
bHVhdGVzIHRvIHRydWUuCgoOCgcEAgQAAgIBEgN7BAkKDgoHBAIEAAICAhIDewwNCnQKBAQC
AgASBIABAksaZiBPcHRpb25hbC4gQ3VzdG9tZXIgc3BlY2lmaWVkIGRlc2NyaXB0aW9uIG9m
IHRoZSBydWxlLiBNdXN0IGJlIGxlc3MgdGhhbiBvcgogZXF1YWwgdG8gMjU2IGNoYXJhY3Rl
cnMuCgoNCgUEAgIABBIEgAECCgoNCgUEAgIABRIEgAELEQoNCgUEAgIAARIEgAESHQoNCgUE
AgIAAxIEgAEgIQoNCgUEAgIACBIEgAEiSgoQCggEAgIACJwIABIEgAEjSQoxCgQEAgIBEgSD
AQJGGiMgUmVxdWlyZWQuIFRoZSBlZmZlY3Qgb2YgdGhlIHJ1bGUuCgoNCgUEAgIBBBIEgwEC
CgoNCgUEAgIBBhIEgwELEQoNCgUEAgIBARIEgwESGAoNCgUEAgIBAxIEgwEbHAoNCgUEAgIB
CBIEgwEdRQoQCggEAgIBCJwIABIEgwEeRAqaEQoEBAICAhIErwECShqLESBSZXF1aXJlZC4g
VGhlIGlkZW50aXRpZXMgZm9yIHdoaWNoIHRoaXMgcnVsZSdzIGVmZmVjdCBnb3Zlcm5zIHVz
aW5nIG9uZSBvcgogbW9yZSBwZXJtaXNzaW9ucyBvbiBHb29nbGUgQ2xvdWQgcmVzb3VyY2Vz
LiBUaGlzIGZpZWxkIGNhbiBjb250YWluIHRoZQogZm9sbG93aW5nIHZhbHVlczoKCiAqIGBw
cmluY2lwYWw6Ly9nb29nL3N1YmplY3Qve2VtYWlsX2lkfWA6IEEgc3BlY2lmaWMgR29vZ2xl
IEFjY291bnQuCiBJbmNsdWRlcyBHbWFpbCwgQ2xvdWQgSWRlbnRpdHksIGFuZCBHb29nbGUg
V29ya3NwYWNlIHVzZXIgYWNjb3VudHMuIEZvcgogZXhhbXBsZSwgYHByaW5jaXBhbDovL2dv
b2cvc3ViamVjdC9hbGljZUBleGFtcGxlLmNvbWAuCgogKiBgcHJpbmNpcGFsOi8vaWFtLmdv
b2dsZWFwaXMuY29tL3Byb2plY3RzLy0vc2VydmljZUFjY291bnRzL3tzZXJ2aWNlX2FjY291
bnRfaWR9YDoKIEEgR29vZ2xlIENsb3VkIHNlcnZpY2UgYWNjb3VudC4gRm9yIGV4YW1wbGUs
CiBgcHJpbmNpcGFsOi8vaWFtLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzLy0vc2VydmljZUFj
Y291bnRzL215LXNlcnZpY2UtYWNjb3VudEBpYW0uZ3NlcnZpY2VhY2NvdW50LmNvbWAuCgog
KiBgcHJpbmNpcGFsU2V0Oi8vZ29vZy9ncm91cC97Z3JvdXBfaWR9YDogQSBHb29nbGUgZ3Jv
dXAuIEZvciBleGFtcGxlLAogYHByaW5jaXBhbFNldDovL2dvb2cvZ3JvdXAvYWRtaW5zQGV4
YW1wbGUuY29tYC4KCiAqIGBwcmluY2lwYWxTZXQ6Ly9nb29nL2Nsb3VkSWRlbnRpdHlDdXN0
b21lcklkL3tjdXN0b21lcl9pZH1gOiBBbGwgb2YgdGhlCiBwcmluY2lwYWxzIGFzc29jaWF0
ZWQgd2l0aCB0aGUgc3BlY2lmaWVkIEdvb2dsZSBXb3Jrc3BhY2Ugb3IgQ2xvdWQKIElkZW50
aXR5IGN1c3RvbWVyIElELiBGb3IgZXhhbXBsZSwKIGBwcmluY2lwYWxTZXQ6Ly9nb29nL2Ns
b3VkSWRlbnRpdHlDdXN0b21lcklkL0MwMUFiYzM1YC4KCgogSWYgYW4gaWRlbnRpZmllciB0
aGF0IHdhcyBwcmV2aW91c2x5IHNldCBvbiBhIHBvbGljeSBpcyBzb2Z0IGRlbGV0ZWQsIHRo
ZW4KIGNhbGxzIHRvIHJlYWQgdGhhdCBwb2xpY3kgd2lsbCByZXR1cm4gdGhlIGlkZW50aWZp
ZXIgd2l0aCBhIGRlbGV0ZWQKIHByZWZpeC4gVXNlcnMgY2Fubm90IHNldCBpZGVudGlmaWVy
cyB3aXRoIHRoaXMgc3ludGF4LgoKICogYGRlbGV0ZWQ6cHJpbmNpcGFsOi8vZ29vZy9zdWJq
ZWN0L3tlbWFpbF9pZH0/dWlkPXt1aWR9YDogQSBzcGVjaWZpYwogR29vZ2xlIEFjY291bnQg
dGhhdCB3YXMgZGVsZXRlZCByZWNlbnRseS4gRm9yIGV4YW1wbGUsCiBgZGVsZXRlZDpwcmlu
Y2lwYWw6Ly9nb29nL3N1YmplY3QvYWxpY2VAZXhhbXBsZS5jb20/dWlkPTEyMzQ1Njc4OTBg
LiBJZgogdGhlIEdvb2dsZSBBY2NvdW50IGlzIHJlY292ZXJlZCwgdGhpcyBpZGVudGlmaWVy
IHJldmVydHMgdG8gdGhlIHN0YW5kYXJkCiBpZGVudGlmaWVyIGZvciBhIEdvb2dsZSBBY2Nv
dW50LgoKICogYGRlbGV0ZWQ6cHJpbmNpcGFsU2V0Oi8vZ29vZy9ncm91cC97Z3JvdXBfaWR9
P3VpZD17dWlkfWA6IEEgR29vZ2xlIGdyb3VwCiB0aGF0IHdhcyBkZWxldGVkIHJlY2VudGx5
LiBGb3IgZXhhbXBsZSwKIGBkZWxldGVkOnByaW5jaXBhbFNldDovL2dvb2cvZ3JvdXAvYWRt
aW5zQGV4YW1wbGUuY29tP3VpZD0xMjM0NTY3ODkwYC4KIElmIHRoZSBHb29nbGUgZ3JvdXAg
aXMgcmVzdG9yZWQsIHRoaXMgaWRlbnRpZmllciByZXZlcnRzIHRvIHRoZSBzdGFuZGFyZAog
aWRlbnRpZmllciBmb3IgYSBHb29nbGUgZ3JvdXAuCgogKiBgZGVsZXRlZDpwcmluY2lwYWw6
Ly9pYW0uZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMvLS9zZXJ2aWNlQWNjb3VudHMve3NlcnZp
Y2VfYWNjb3VudF9pZH0/dWlkPXt1aWR9YDoKIEEgR29vZ2xlIENsb3VkIHNlcnZpY2UgYWNj
b3VudCB0aGF0IHdhcyBkZWxldGVkIHJlY2VudGx5LiBGb3IgZXhhbXBsZSwKIGBkZWxldGVk
OnByaW5jaXBhbDovL2lhbS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy8tL3NlcnZpY2VBY2Nv
dW50cy9teS1zZXJ2aWNlLWFjY291bnRAaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20/dWlkPTEy
MzQ1Njc4OTBgLgogSWYgdGhlIHNlcnZpY2UgYWNjb3VudCBpcyB1bmRlbGV0ZWQsIHRoaXMg
aWRlbnRpZmllciByZXZlcnRzIHRvIHRoZQogc3RhbmRhcmQgaWRlbnRpZmllciBmb3IgYSBz
ZXJ2aWNlIGFjY291bnQuCgoNCgUEAgICBBIErwECCgoNCgUEAgICBRIErwELEQoNCgUEAgIC
ARIErwESHAoNCgUEAgICAxIErwEfIAoNCgUEAgICCBIErwEhSQoQCggEAgICCJwIABIErwEi
SAr/AQoEBAICAxIGtQECtgEvGu4BIE9wdGlvbmFsLiBUaGUgaWRlbnRpdGllcyB0aGF0IGFy
ZSBleGNsdWRlZCBmcm9tIHRoZSBhY2Nlc3MgcG9saWN5IHJ1bGUsCiBldmVuIGlmIHRoZXkg
YXJlIGxpc3RlZCBpbiB0aGUgYHByaW5jaXBhbHNgLiBGb3IgZXhhbXBsZSwgeW91IGNvdWxk
IGFkZCBhCiBHb29nbGUgZ3JvdXAgdG8gdGhlIGBwcmluY2lwYWxzYCwgdGhlbiBleGNsdWRl
IHNwZWNpZmljIHVzZXJzIHdobyBiZWxvbmcgdG8KIHRoYXQgZ3JvdXAuCgoNCgUEAgIDBBIE
tQECCgoNCgUEAgIDBRIEtQELEQoNCgUEAgIDARIEtQESJQoNCgUEAgIDAxIEtQEoKQoNCgUE
AgIDCBIEtgEGLgoQCggEAgIDCJwIABIEtgEHLQpoCgQEAgIEEgS6AQJEGlogUmVxdWlyZWQu
IEF0dHJpYnV0ZXMgdGhhdCBhcmUgdXNlZCB0byBkZXRlcm1pbmUgd2hldGhlciB0aGlzIHJ1
bGUgYXBwbGllcwogdG8gYSByZXF1ZXN0LgoKDQoFBAICBAYSBLoBAgsKDQoFBAICBAESBLoB
DBUKDQoFBAICBAMSBLoBGBoKDQoFBAICBAgSBLoBG0MKEAoIBAICBAicCAASBLoBHEIKqQYK
BAQCAgUSBtUBAtYBLxqYBiBPcHRpb25hbC4gVGhlIGNvbmRpdGlvbnMgdGhhdCBkZXRlcm1p
bmUgd2hldGhlciB0aGlzIHJ1bGUgYXBwbGllcyB0byBhCiByZXF1ZXN0LiBDb25kaXRpb25z
IGFyZSBpZGVudGlmaWVkIGJ5IHRoZWlyIGtleSwgd2hpY2ggaXMgdGhlIEZRRE4gb2YgdGhl
CiBzZXJ2aWNlIHRoYXQgdGhleSBhcmUgcmVsZXZhbnQgdG8uIEZvciBleGFtcGxlOgoKIGBg
YAogImNvbmRpdGlvbnMiOiB7CiAgImlhbS5nb29nbGVhcGlzLmNvbSI6IHsKICAgImV4cHJl
c3Npb24iOiA8Y2VsIGV4cHJlc3Npb24+CiAgfQogfQogYGBgCgogRWFjaCBydWxlIGlzIGV2
YWx1YXRlZCBpbmRlcGVuZGVudGx5LiBJZiB0aGlzIHJ1bGUgZG9lcyBub3QgYXBwbHkKIHRv
IGEgcmVxdWVzdCwgb3RoZXIgcnVsZXMgbWlnaHQgc3RpbGwgYXBwbHkuCiBDdXJyZW50bHkg
c3VwcG9ydGVkIGtleXMgYXJlIGFzIGZvbGxvd3M6CgoKICogYGV2ZW50YXJjLmdvb2dsZWFw
aXMuY29tYDogQ2FuIHVzZSBgQ0VMYCBmdW5jdGlvbnMgdGhhdCBldmFsdWF0ZQogICByZXNv
dXJjZSBmaWVsZHMuCgogKiBgaWFtLmdvb2dsZWFwaXMuY29tYDogQ2FuIHVzZSBgQ0VMYCBm
dW5jdGlvbnMgdGhhdCBldmFsdWF0ZQogICBbcmVzb3VyY2UKICAgdGFnc10oaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL2lhbS9oZWxwL2NvbmRpdGlvbnMvcmVzb3VyY2UtdGFncykgYW5k
CiAgIGNvbWJpbmUgdGhlbSB1c2luZyBib29sZWFuIGFuZCBsb2dpY2FsIG9wZXJhdG9ycy4g
T3RoZXIgZnVuY3Rpb25zIGFuZAogICBvcGVyYXRvcnMgYXJlIG5vdCBzdXBwb3J0ZWQuCgoN
CgUEAgIFBhIE1QECHwoNCgUEAgIFARIE1QEgKgoNCgUEAgIFAxIE1QEtLgoNCgUEAgIFCBIE
1gEGLgoQCggEAgIFCJwIABIE1gEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3::AccessPolicyResources::AccessPolicy ===
    # Fields for AccessPolicy
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: annotations Type: 11 (.google.iam.v3.AccessPolicy.AnnotationsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: details Type: 11 (.google.iam.v3.AccessPolicyDetails)

# === Message: Google::Iam::V3::AccessPolicyResources::AccessPolicyDetails ===
    # Fields for AccessPolicyDetails
    # Field: rules Type: 11 (.google.iam.v3.AccessPolicyRule)

# === Message: Google::Iam::V3::AccessPolicyResources::AccessPolicyRule ===
    # Fields for AccessPolicyRule
    # Field: description Type: 9 ()
    # Field: effect Type: 14 (.google.iam.v3.AccessPolicyRule.Effect)
    # Field: principals Type: 9 ()
    # Field: excluded_principals Type: 9 ()
    # Field: operation Type: 11 (.google.iam.v3.AccessPolicyRule.Operation)
    # Field: conditions Type: 11 (.google.iam.v3.AccessPolicyRule.ConditionsEntry)

# Enum: AccessPolicyRule::Effect
our $AccessPolicyRule_EFFECT_UNSPECIFIED = 0;
our $AccessPolicyRule_DENY = 1;
our $AccessPolicyRule_ALLOW = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3::AccessPolicyResources - Compiled Protocol Buffers messages for google/iam/v3/access_policy_resources.proto

=head1 SYNOPSIS

    use Google::Iam::V3::AccessPolicyResources;

    my $msg = Google::Iam::V3::AccessPolicyResources::AccessPolicy->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3::AccessPolicyResources::AccessPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3/access_policy_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3::AccessPolicyResources::AccessPolicy

An IAM access policy resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the access policy.

The following formats are supported:

* `projects/{project_id}/locations/{location}/accessPolicies/{policy_id}`
* `projects/{project_number}/locations/{location}/accessPolicies/{policy_id}`
* `folders/{folder_id}/locations/{location}/accessPolicies/{policy_id}`
* `organizations/{organization_id}/locations/{location}/accessPolicies/{policy_id}`

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The globally unique ID of the access policy.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag for the access policy.
If this is provided on update, it must match the server's etag.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The description of the access policy. Must be less than
or equal to 63 characters.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Iam::V3::AccessPolicyResources::AccessPolicy::AnnotationsEntry>)

Optional. User defined annotations. See
https://google.aip.dev/148#annotations for more details such as format and
size limitations

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the access policy was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the access policy was most recently
updated.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Iam::V3::AccessPolicyResources::AccessPolicyDetails>)

Optional. The details for the access policy.

=back

=head2 Google::Iam::V3::AccessPolicyResources::AccessPolicyDetails

Access policy details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Iam::V3::AccessPolicyResources::AccessPolicyRule>)

Required. A list of access policy rules.

=back

=head2 Google::Iam::V3::AccessPolicyResources::AccessPolicyRule

Access Policy Rule that determines the behavior of the policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Customer specified description of the rule. Must be less than or
equal to 256 characters.

=item * C<< $msg->effect() >> / C<< $msg->effect($value) >>

Type: C<Enum> (L<Google::Iam::V3::AccessPolicyRule::Effect>)

Required. The effect of the rule.

=item * C<< $msg->principals() >> / C<< $msg->principals($value) >>

Type: C<String>

Required. The identities for which this rule's effect governs using one or
more permissions on Google Cloud resources. This field can contain the
following values:

* `principal://goog/subject/{email_id}`: A specific Google Account.
Includes Gmail, Cloud Identity, and Google Workspace user accounts. For
example, `principal://goog/subject/alice@example.com`.

* `principal://iam.googleapis.com/projects/-/serviceAccounts/{service_account_id}`:
A Google Cloud service account. For example,
`principal://iam.googleapis.com/projects/-/serviceAccounts/my-service-account@iam.gserviceaccount.com`.

* `principalSet://goog/group/{group_id}`: A Google group. For example,
`principalSet://goog/group/admins@example.com`.

* `principalSet://goog/cloudIdentityCustomerId/{customer_id}`: All of the
principals associated with the specified Google Workspace or Cloud
Identity customer ID. For example,
`principalSet://goog/cloudIdentityCustomerId/C01Abc35`.


If an identifier that was previously set on a policy is soft deleted, then
calls to read that policy will return the identifier with a deleted
prefix. Users cannot set identifiers with this syntax.

* `deleted:principal://goog/subject/{email_id}?uid={uid}`: A specific
Google Account that was deleted recently. For example,
`deleted:principal://goog/subject/alice@example.com?uid=1234567890`. If
the Google Account is recovered, this identifier reverts to the standard
identifier for a Google Account.

* `deleted:principalSet://goog/group/{group_id}?uid={uid}`: A Google group
that was deleted recently. For example,
`deleted:principalSet://goog/group/admins@example.com?uid=1234567890`.
If the Google group is restored, this identifier reverts to the standard
identifier for a Google group.

* `deleted:principal://iam.googleapis.com/projects/-/serviceAccounts/{service_account_id}?uid={uid}`:
A Google Cloud service account that was deleted recently. For example,
`deleted:principal://iam.googleapis.com/projects/-/serviceAccounts/my-service-account@iam.gserviceaccount.com?uid=1234567890`.
If the service account is undeleted, this identifier reverts to the
standard identifier for a service account.

=item * C<< $msg->excluded_principals() >> / C<< $msg->excluded_principals($value) >>

Type: C<String>

Optional. The identities that are excluded from the access policy rule,
even if they are listed in the `principals`. For example, you could add a
Google group to the `principals`, then exclude specific users who belong to
that group.

=item * C<< $msg->operation() >> / C<< $msg->operation($value) >>

Type: C<Message> (L<Google::Iam::V3::AccessPolicyResources::AccessPolicyRule::Operation>)

Required. Attributes that are used to determine whether this rule applies
to a request.

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Iam::V3::AccessPolicyResources::AccessPolicyRule::ConditionsEntry>)

Optional. The conditions that determine whether this rule applies to a
request. Conditions are identified by their key, which is the FQDN of the
service that they are relevant to. For example:

```
"conditions": {
 "iam.googleapis.com": {
  "expression": <cel expression>
 }
}
```

Each rule is evaluated independently. If this rule does not apply
to a request, other rules might still apply.
Currently supported keys are as follows:


* `eventarc.googleapis.com`: Can use `CEL` functions that evaluate
  resource fields.

* `iam.googleapis.com`: Can use `CEL` functions that evaluate
  [resource
  tags](https://cloud.google.com/iam/help/conditions/resource-tags) and
  combine them using boolean and logical operators. Other functions and
  operators are not supported.

=back

=head3 Enum: AccessPolicyRule::Effect

=over 4

=item * C<EFFECT_UNSPECIFIED> => C<0>

=item * C<DENY> => C<1>

=item * C<ALLOW> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3::AccessPolicyResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
