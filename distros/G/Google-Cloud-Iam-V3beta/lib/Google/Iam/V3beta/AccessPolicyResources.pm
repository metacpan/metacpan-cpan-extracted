package Google::Iam::V3beta::AccessPolicyResources;

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
Ci9nb29nbGUvaWFtL3YzYmV0YS9hY2Nlc3NfcG9saWN5X3Jlc291cmNlcy5wcm90bxIRZ29v
Z2xlLmlhbS52M2JldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aG2dvb2ds
ZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoWZ29vZ2xlL3R5cGUvZXhwci5wcm90byKR
BgoMQWNjZXNzUG9saWN5EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIdCgN1aWQYAiABKAlC
C+KMz9cIAggB4EEDUgN1aWQSFwoEZXRhZxgDIAEoCUID4EEBUgRldGFnEiYKDGRpc3BsYXlf
bmFtZRgEIAEoCUID4EEBUgtkaXNwbGF5TmFtZRJXCgthbm5vdGF0aW9ucxgFIAMoCzIwLmdv
b2dsZS5pYW0udjNiZXRhLkFjY2Vzc1BvbGljeS5Bbm5vdGF0aW9uc0VudHJ5QgPgQQFSC2Fu
bm90YXRpb25zEkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkUKB2RldGFpbHMYCCABKAsyJi5n
b29nbGUuaWFtLnYzYmV0YS5BY2Nlc3NQb2xpY3lEZXRhaWxzQgPgQQFSB2RldGFpbHMaPgoQ
QW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBOqMC6kGfAgofaWFtLmdvb2dsZWFwaXMuY29tL0FjY2Vzc1BvbGljeRJQb3JnYW5p
emF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hY2Nlc3NQb2xp
Y2llcy97YWNjZXNzX3BvbGljeX0SRGZvbGRlcnMve2ZvbGRlcn0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xpY3l9EkZwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve2FjY2Vzc19wb2xpY3l9
Kg5hY2Nlc3NQb2xpY2llczIMYWNjZXNzUG9saWN5IlUKE0FjY2Vzc1BvbGljeURldGFpbHMS
PgoFcnVsZXMYASADKAsyIy5nb29nbGUuaWFtLnYzYmV0YS5BY2Nlc3NQb2xpY3lSdWxlQgPg
QQJSBXJ1bGVzIqMFChBBY2Nlc3NQb2xpY3lSdWxlEioKC2Rlc2NyaXB0aW9uGAEgASgJQgPg
QQFIAFILZGVzY3JpcHRpb26IAQESTAoGZWZmZWN0GAIgASgOMiouZ29vZ2xlLmlhbS52M2Jl
dGEuQWNjZXNzUG9saWN5UnVsZS5FZmZlY3RCA+BBAkgBUgZlZmZlY3SIAQESIwoKcHJpbmNp
cGFscxgDIAMoCUID4EECUgpwcmluY2lwYWxzEjQKE2V4Y2x1ZGVkX3ByaW5jaXBhbHMYBCAD
KAlCA+BBAVISZXhjbHVkZWRQcmluY2lwYWxzElAKCW9wZXJhdGlvbhgKIAEoCzItLmdvb2ds
ZS5pYW0udjNiZXRhLkFjY2Vzc1BvbGljeVJ1bGUuT3BlcmF0aW9uQgPgQQJSCW9wZXJhdGlv
bhJYCgpjb25kaXRpb25zGAkgAygLMjMuZ29vZ2xlLmlhbS52M2JldGEuQWNjZXNzUG9saWN5
UnVsZS5Db25kaXRpb25zRW50cnlCA+BBAVIKY29uZGl0aW9ucxpqCglPcGVyYXRpb24SJQoL
cGVybWlzc2lvbnMYASADKAlCA+BBAVILcGVybWlzc2lvbnMSNgoUZXhjbHVkZWRfcGVybWlz
c2lvbnMYAiADKAlCA+BBAVITZXhjbHVkZWRQZXJtaXNzaW9ucxpQCg9Db25kaXRpb25zRW50
cnkSEAoDa2V5GAEgASgJUgNrZXkSJwoFdmFsdWUYAiABKAsyES5nb29nbGUudHlwZS5FeHBy
UgV2YWx1ZToCOAEiNQoGRWZmZWN0EhYKEkVGRkVDVF9VTlNQRUNJRklFRBAAEggKBERFTlkQ
ARIJCgVBTExPVxACQg4KDF9kZXNjcmlwdGlvbkIJCgdfZWZmZWN0QpgBChVjb20uZ29vZ2xl
LmlhbS52M2JldGFCGkFjY2Vzc1BvbGljeVJlc291cmNlc1Byb3RvUAFaLWNsb3VkLmdvb2ds
ZS5jb20vZ28vaWFtL2FwaXYzYmV0YS9pYW1wYjtpYW1wYqoCF0dvb2dsZS5DbG91ZC5JYW0u
VjNCZXRhygIXR29vZ2xlXENsb3VkXElhbVxWM2JldGFK6UAKBxIFDgDXAQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABoKCQoCAwASAxIAKQoJCgIDARID
EwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAKQoJCgIDBBIDFgAgCggKAQgSAxgANAoJCgIIJRID
GAA0CggKAQgSAxkARAoJCgIICxIDGQBECggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsA
OwoJCgIICBIDGwA7CggKAQgSAxwALgoJCgIIARIDHAAuCggKAQgSAx0ANAoJCgIIKRIDHQA0
CiwKAgQAEgQgAFIBGiAgQW4gSUFNIGFjY2VzcyBwb2xpY3kgcmVzb3VyY2UuCgoKCgMEAAES
AyAIFAoLCgMEAAcSBCECKAQKDQoFBAAHnQgSBCECKAQKowMKBAQAAgASAzICPRqVAyBJZGVu
dGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYWNjZXNzIHBvbGljeS4KCiBUaGUg
Zm9sbG93aW5nIGZvcm1hdHMgYXJlIHN1cHBvcnRlZDoKCiAqIGBwcm9qZWN0cy97cHJvamVj
dF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNzUG9saWNpZXMve3BvbGljeV9pZH1g
CiAqIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fj
Y2Vzc1BvbGljaWVzL3twb2xpY3lfaWR9YAogKiBgZm9sZGVycy97Zm9sZGVyX2lkfS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9hY2Nlc3NQb2xpY2llcy97cG9saWN5X2lkfWAKICogYG9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNjZXNz
UG9saWNpZXMve3BvbGljeV9pZH1gCgoMCgUEAAIABRIDMgIICgwKBQQAAgABEgMyCQ0KDAoF
BAACAAMSAzIQEQoMCgUEAAIACBIDMhI8Cg8KCAQAAgAInAgAEgMyEzsKSQoEBAACARIENQI4
BBo7IE91dHB1dCBvbmx5LiBUaGUgZ2xvYmFsbHkgdW5pcXVlIElEIG9mIHRoZSBhY2Nlc3Mg
cG9saWN5LgoKDAoFBAACAQUSAzUCCAoMCgUEAAIBARIDNQkMCgwKBQQAAgEDEgM1DxAKDQoF
BAACAQgSBDUROAMKEgoLBAACAQjM8fmKAQESAzYEKgoPCggEAAIBCJwIABIDNwQtCnkKBAQA
AgISAzwCOxpsIE9wdGlvbmFsLiBUaGUgZXRhZyBmb3IgdGhlIGFjY2VzcyBwb2xpY3kuCiBJ
ZiB0aGlzIGlzIHByb3ZpZGVkIG9uIHVwZGF0ZSwgaXQgbXVzdCBtYXRjaCB0aGUgc2VydmVy
J3MgZXRhZy4KCgwKBQQAAgIFEgM8AggKDAoFBAACAgESAzwJDQoMCgUEAAICAxIDPBARCgwK
BQQAAgIIEgM8EjoKDwoIBAACAgicCAASAzwTOQpsCgQEAAIDEgNAAkMaXyBPcHRpb25hbC4g
VGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBhY2Nlc3MgcG9saWN5LiBNdXN0IGJlIGxlc3MgdGhh
bgogb3IgZXF1YWwgdG8gNjMgY2hhcmFjdGVycy4KCgwKBQQAAgMFEgNAAggKDAoFBAACAwES
A0AJFQoMCgUEAAIDAxIDQBgZCgwKBQQAAgMIEgNAGkIKDwoIBAACAwicCAASA0AbQQqVAQoE
BAACBBIDRQJPGocBIE9wdGlvbmFsLiBVc2VyIGRlZmluZWQgYW5ub3RhdGlvbnMuIFNlZQog
aHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xNDgjYW5ub3RhdGlvbnMgZm9yIG1vcmUgZGV0YWls
cyBzdWNoIGFzIGZvcm1hdCBhbmQKIHNpemUgbGltaXRhdGlvbnMKCgwKBQQAAgQGEgNFAhUK
DAoFBAACBAESA0UWIQoMCgUEAAIEAxIDRSQlCgwKBQQAAgQIEgNFJk4KDwoIBAACBAicCAAS
A0UnTQpJCgQEAAIFEgRIAkkyGjsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIGFj
Y2VzcyBwb2xpY3kgd2FzIGNyZWF0ZWQuCgoMCgUEAAIFBhIDSAIbCgwKBQQAAgUBEgNIHCcK
DAoFBAACBQMSA0gqKwoMCgUEAAIFCBIDSQYxCg8KCAQAAgUInAgAEgNJBzAKWAoEBAACBhIE
TQJOMhpKIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBhY2Nlc3MgcG9saWN5IHdh
cyBtb3N0IHJlY2VudGx5CiB1cGRhdGVkLgoKDAoFBAACBgYSA00CGwoMCgUEAAIGARIDTRwn
CgwKBQQAAgYDEgNNKisKDAoFBAACBggSA04GMQoPCggEAAIGCJwIABIDTgcwCjsKBAQAAgcS
A1ECSxouIE9wdGlvbmFsLiBUaGUgZGV0YWlscyBmb3IgdGhlIGFjY2VzcyBwb2xpY3kuCgoM
CgUEAAIHBhIDUQIVCgwKBQQAAgcBEgNRFh0KDAoFBAACBwMSA1EgIQoMCgUEAAIHCBIDUSJK
Cg8KCAQAAgcInAgAEgNRI0kKJAoCBAESBFUAWAEaGCBBY2Nlc3MgcG9saWN5IGRldGFpbHMu
CgoKCgMEAQESA1UIGwo3CgQEAQIAEgNXAk8aKiBSZXF1aXJlZC4gQSBsaXN0IG9mIGFjY2Vz
cyBwb2xpY3kgcnVsZXMuCgoMCgUEAQIABBIDVwIKCgwKBQQBAgAGEgNXCxsKDAoFBAECAAES
A1ccIQoMCgUEAQIAAxIDVyQlCgwKBQQBAgAIEgNXJk4KDwoIBAECAAicCAASA1cnTQpNCgIE
AhIFWwDXAQEaQCBBY2Nlc3MgUG9saWN5IFJ1bGUgdGhhdCBkZXRlcm1pbmVzIHRoZSBiZWhh
dmlvciBvZiB0aGUgcG9saWN5LgoKCgoDBAIBEgNbCBgKXgoEBAIDABIEXgJwAxpQIEF0dHJp
YnV0ZXMgdGhhdCBhcmUgdXNlZCB0byBkZXRlcm1pbmUgd2hldGhlciB0aGlzIHJ1bGUgYXBw
bGllcyB0byBhCiByZXF1ZXN0LgoKDAoFBAIDAAESA14KEwrMAgoGBAIDAAIAEgNlBE0avAIg
T3B0aW9uYWwuIFRoZSBwZXJtaXNzaW9ucyB0aGF0IGFyZSBleHBsaWNpdGx5IGFmZmVjdGVk
IGJ5IHRoaXMgcnVsZS4gRWFjaAogcGVybWlzc2lvbiB1c2VzIHRoZSBmb3JtYXQgYHtzZXJ2
aWNlX2ZxZG59L3tyZXNvdXJjZX0ue3ZlcmJ9YCwgd2hlcmUKIGB7c2VydmljZV9mcWRufWAg
aXMgdGhlIGZ1bGx5IHF1YWxpZmllZCBkb21haW4gbmFtZSBmb3IgdGhlIHNlcnZpY2UuCiBD
dXJyZW50bHkgc3VwcG9ydGVkIHBlcm1pc3Npb25zIGFyZSBhcyBmb2xsb3dzOgoKICogYGV2
ZW50YXJjLmdvb2dsZWFwaXMuY29tL21lc3NhZ2VCdXNlcy5wdWJsaXNoYC4KCg4KBwQCAwAC
AAQSA2UEDAoOCgcEAgMAAgAFEgNlDRMKDgoHBAIDAAIAARIDZRQfCg4KBwQCAwACAAMSA2Ui
IwoOCgcEAgMAAgAIEgNlJEwKEQoKBAIDAAIACJwIABIDZSVLCuACCgYEAgMAAgESBG4EbzEa
zwIgT3B0aW9uYWwuIFNwZWNpZmllcyB0aGUgcGVybWlzc2lvbnMgdGhhdCB0aGlzIHJ1bGUg
ZXhjbHVkZXMgZnJvbSB0aGUgc2V0CiBvZiBhZmZlY3RlZCBwZXJtaXNzaW9ucyBnaXZlbiBi
eSBgcGVybWlzc2lvbnNgLiBJZiBhIHBlcm1pc3Npb24gYXBwZWFycwogaW4gYHBlcm1pc3Np
b25zYCBfYW5kXyBpbiBgZXhjbHVkZWRfcGVybWlzc2lvbnNgIHRoZW4gaXQgd2lsbCBfbm90
XyBiZQogc3ViamVjdCB0byB0aGUgcG9saWN5IGVmZmVjdC4KCiBUaGUgZXhjbHVkZWQgcGVy
bWlzc2lvbnMgY2FuIGJlIHNwZWNpZmllZCB1c2luZyB0aGUgc2FtZSBzeW50YXggYXMKIGBw
ZXJtaXNzaW9uc2AuCgoOCgcEAgMAAgEEEgNuBAwKDgoHBAIDAAIBBRIDbg0TCg4KBwQCAwAC
AQESA24UKAoOCgcEAgMAAgEDEgNuKywKDgoHBAIDAAIBCBIDbwgwChEKCgQCAwACAQicCAAS
A28JLwo+CgQEAgQAEgRzAnwDGjAgQW4gZWZmZWN0IHRvIGRlc2NyaWJlIHRoZSBhY2Nlc3Mg
cmVsYXRpb25zaGlwLgoKDAoFBAIEAAESA3MHDQorCgYEAgQAAgASA3UEGxocIFRoZSBlZmZl
Y3QgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAgQAAgABEgN1BBYKDgoHBAIEAAIAAhIDdRkaCkUK
BgQCBAACARIDeAQNGjYgVGhlIHBvbGljeSB3aWxsIGRlbnkgYWNjZXNzIGlmIGl0IGV2YWx1
YXRlcyB0byB0cnVlLgoKDgoHBAIEAAIBARIDeAQICg4KBwQCBAACAQISA3gLDApGCgYEAgQA
AgISA3sEDho3IFRoZSBwb2xpY3kgd2lsbCBncmFudCBhY2Nlc3MgaWYgaXQgZXZhbHVhdGVz
IHRvIHRydWUuCgoOCgcEAgQAAgIBEgN7BAkKDgoHBAIEAAICAhIDewwNCnQKBAQCAgASBIAB
AksaZiBPcHRpb25hbC4gQ3VzdG9tZXIgc3BlY2lmaWVkIGRlc2NyaXB0aW9uIG9mIHRoZSBy
dWxlLiBNdXN0IGJlIGxlc3MgdGhhbiBvcgogZXF1YWwgdG8gMjU2IGNoYXJhY3RlcnMuCgoN
CgUEAgIABBIEgAECCgoNCgUEAgIABRIEgAELEQoNCgUEAgIAARIEgAESHQoNCgUEAgIAAxIE
gAEgIQoNCgUEAgIACBIEgAEiSgoQCggEAgIACJwIABIEgAEjSQoxCgQEAgIBEgSDAQJGGiMg
UmVxdWlyZWQuIFRoZSBlZmZlY3Qgb2YgdGhlIHJ1bGUuCgoNCgUEAgIBBBIEgwECCgoNCgUE
AgIBBhIEgwELEQoNCgUEAgIBARIEgwESGAoNCgUEAgIBAxIEgwEbHAoNCgUEAgIBCBIEgwEd
RQoQCggEAgIBCJwIABIEgwEeRAqaEQoEBAICAhIErwECShqLESBSZXF1aXJlZC4gVGhlIGlk
ZW50aXRpZXMgZm9yIHdoaWNoIHRoaXMgcnVsZSdzIGVmZmVjdCBnb3Zlcm5zIHVzaW5nIG9u
ZSBvcgogbW9yZSBwZXJtaXNzaW9ucyBvbiBHb29nbGUgQ2xvdWQgcmVzb3VyY2VzLiBUaGlz
IGZpZWxkIGNhbiBjb250YWluIHRoZQogZm9sbG93aW5nIHZhbHVlczoKCiAqIGBwcmluY2lw
YWw6Ly9nb29nL3N1YmplY3Qve2VtYWlsX2lkfWA6IEEgc3BlY2lmaWMgR29vZ2xlIEFjY291
bnQuCiBJbmNsdWRlcyBHbWFpbCwgQ2xvdWQgSWRlbnRpdHksIGFuZCBHb29nbGUgV29ya3Nw
YWNlIHVzZXIgYWNjb3VudHMuIEZvcgogZXhhbXBsZSwgYHByaW5jaXBhbDovL2dvb2cvc3Vi
amVjdC9hbGljZUBleGFtcGxlLmNvbWAuCgogKiBgcHJpbmNpcGFsOi8vaWFtLmdvb2dsZWFw
aXMuY29tL3Byb2plY3RzLy0vc2VydmljZUFjY291bnRzL3tzZXJ2aWNlX2FjY291bnRfaWR9
YDoKIEEgR29vZ2xlIENsb3VkIHNlcnZpY2UgYWNjb3VudC4gRm9yIGV4YW1wbGUsCiBgcHJp
bmNpcGFsOi8vaWFtLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzLy0vc2VydmljZUFjY291bnRz
L215LXNlcnZpY2UtYWNjb3VudEBpYW0uZ3NlcnZpY2VhY2NvdW50LmNvbWAuCgogKiBgcHJp
bmNpcGFsU2V0Oi8vZ29vZy9ncm91cC97Z3JvdXBfaWR9YDogQSBHb29nbGUgZ3JvdXAuIEZv
ciBleGFtcGxlLAogYHByaW5jaXBhbFNldDovL2dvb2cvZ3JvdXAvYWRtaW5zQGV4YW1wbGUu
Y29tYC4KCiAqIGBwcmluY2lwYWxTZXQ6Ly9nb29nL2Nsb3VkSWRlbnRpdHlDdXN0b21lcklk
L3tjdXN0b21lcl9pZH1gOiBBbGwgb2YgdGhlCiBwcmluY2lwYWxzIGFzc29jaWF0ZWQgd2l0
aCB0aGUgc3BlY2lmaWVkIEdvb2dsZSBXb3Jrc3BhY2Ugb3IgQ2xvdWQKIElkZW50aXR5IGN1
c3RvbWVyIElELiBGb3IgZXhhbXBsZSwKIGBwcmluY2lwYWxTZXQ6Ly9nb29nL2Nsb3VkSWRl
bnRpdHlDdXN0b21lcklkL0MwMUFiYzM1YC4KCgogSWYgYW4gaWRlbnRpZmllciB0aGF0IHdh
cyBwcmV2aW91c2x5IHNldCBvbiBhIHBvbGljeSBpcyBzb2Z0IGRlbGV0ZWQsIHRoZW4KIGNh
bGxzIHRvIHJlYWQgdGhhdCBwb2xpY3kgd2lsbCByZXR1cm4gdGhlIGlkZW50aWZpZXIgd2l0
aCBhIGRlbGV0ZWQKIHByZWZpeC4gVXNlcnMgY2Fubm90IHNldCBpZGVudGlmaWVycyB3aXRo
IHRoaXMgc3ludGF4LgoKICogYGRlbGV0ZWQ6cHJpbmNpcGFsOi8vZ29vZy9zdWJqZWN0L3tl
bWFpbF9pZH0/dWlkPXt1aWR9YDogQSBzcGVjaWZpYwogR29vZ2xlIEFjY291bnQgdGhhdCB3
YXMgZGVsZXRlZCByZWNlbnRseS4gRm9yIGV4YW1wbGUsCiBgZGVsZXRlZDpwcmluY2lwYWw6
Ly9nb29nL3N1YmplY3QvYWxpY2VAZXhhbXBsZS5jb20/dWlkPTEyMzQ1Njc4OTBgLiBJZgog
dGhlIEdvb2dsZSBBY2NvdW50IGlzIHJlY292ZXJlZCwgdGhpcyBpZGVudGlmaWVyIHJldmVy
dHMgdG8gdGhlIHN0YW5kYXJkCiBpZGVudGlmaWVyIGZvciBhIEdvb2dsZSBBY2NvdW50LgoK
ICogYGRlbGV0ZWQ6cHJpbmNpcGFsU2V0Oi8vZ29vZy9ncm91cC97Z3JvdXBfaWR9P3VpZD17
dWlkfWA6IEEgR29vZ2xlIGdyb3VwCiB0aGF0IHdhcyBkZWxldGVkIHJlY2VudGx5LiBGb3Ig
ZXhhbXBsZSwKIGBkZWxldGVkOnByaW5jaXBhbFNldDovL2dvb2cvZ3JvdXAvYWRtaW5zQGV4
YW1wbGUuY29tP3VpZD0xMjM0NTY3ODkwYC4KIElmIHRoZSBHb29nbGUgZ3JvdXAgaXMgcmVz
dG9yZWQsIHRoaXMgaWRlbnRpZmllciByZXZlcnRzIHRvIHRoZSBzdGFuZGFyZAogaWRlbnRp
ZmllciBmb3IgYSBHb29nbGUgZ3JvdXAuCgogKiBgZGVsZXRlZDpwcmluY2lwYWw6Ly9pYW0u
Z29vZ2xlYXBpcy5jb20vcHJvamVjdHMvLS9zZXJ2aWNlQWNjb3VudHMve3NlcnZpY2VfYWNj
b3VudF9pZH0/dWlkPXt1aWR9YDoKIEEgR29vZ2xlIENsb3VkIHNlcnZpY2UgYWNjb3VudCB0
aGF0IHdhcyBkZWxldGVkIHJlY2VudGx5LiBGb3IgZXhhbXBsZSwKIGBkZWxldGVkOnByaW5j
aXBhbDovL2lhbS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy8tL3NlcnZpY2VBY2NvdW50cy9t
eS1zZXJ2aWNlLWFjY291bnRAaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20/dWlkPTEyMzQ1Njc4
OTBgLgogSWYgdGhlIHNlcnZpY2UgYWNjb3VudCBpcyB1bmRlbGV0ZWQsIHRoaXMgaWRlbnRp
ZmllciByZXZlcnRzIHRvIHRoZQogc3RhbmRhcmQgaWRlbnRpZmllciBmb3IgYSBzZXJ2aWNl
IGFjY291bnQuCgoNCgUEAgICBBIErwECCgoNCgUEAgICBRIErwELEQoNCgUEAgICARIErwES
HAoNCgUEAgICAxIErwEfIAoNCgUEAgICCBIErwEhSQoQCggEAgICCJwIABIErwEiSAr/AQoE
BAICAxIGtQECtgEvGu4BIE9wdGlvbmFsLiBUaGUgaWRlbnRpdGllcyB0aGF0IGFyZSBleGNs
dWRlZCBmcm9tIHRoZSBhY2Nlc3MgcG9saWN5IHJ1bGUsCiBldmVuIGlmIHRoZXkgYXJlIGxp
c3RlZCBpbiB0aGUgYHByaW5jaXBhbHNgLiBGb3IgZXhhbXBsZSwgeW91IGNvdWxkIGFkZCBh
CiBHb29nbGUgZ3JvdXAgdG8gdGhlIGBwcmluY2lwYWxzYCwgdGhlbiBleGNsdWRlIHNwZWNp
ZmljIHVzZXJzIHdobyBiZWxvbmcgdG8KIHRoYXQgZ3JvdXAuCgoNCgUEAgIDBBIEtQECCgoN
CgUEAgIDBRIEtQELEQoNCgUEAgIDARIEtQESJQoNCgUEAgIDAxIEtQEoKQoNCgUEAgIDCBIE
tgEGLgoQCggEAgIDCJwIABIEtgEHLQpoCgQEAgIEEgS6AQJEGlogUmVxdWlyZWQuIEF0dHJp
YnV0ZXMgdGhhdCBhcmUgdXNlZCB0byBkZXRlcm1pbmUgd2hldGhlciB0aGlzIHJ1bGUgYXBw
bGllcwogdG8gYSByZXF1ZXN0LgoKDQoFBAICBAYSBLoBAgsKDQoFBAICBAESBLoBDBUKDQoF
BAICBAMSBLoBGBoKDQoFBAICBAgSBLoBG0MKEAoIBAICBAicCAASBLoBHEIKqQYKBAQCAgUS
BtUBAtYBLxqYBiBPcHRpb25hbC4gVGhlIGNvbmRpdGlvbnMgdGhhdCBkZXRlcm1pbmUgd2hl
dGhlciB0aGlzIHJ1bGUgYXBwbGllcyB0byBhCiByZXF1ZXN0LiBDb25kaXRpb25zIGFyZSBp
ZGVudGlmaWVkIGJ5IHRoZWlyIGtleSwgd2hpY2ggaXMgdGhlIEZRRE4gb2YgdGhlCiBzZXJ2
aWNlIHRoYXQgdGhleSBhcmUgcmVsZXZhbnQgdG8uIEZvciBleGFtcGxlOgoKIGBgYAogImNv
bmRpdGlvbnMiOiB7CiAgImlhbS5nb29nbGVhcGlzLmNvbSI6IHsKICAgImV4cHJlc3Npb24i
OiA8Y2VsIGV4cHJlc3Npb24+CiAgfQogfQogYGBgCgogRWFjaCBydWxlIGlzIGV2YWx1YXRl
ZCBpbmRlcGVuZGVudGx5LiBJZiB0aGlzIHJ1bGUgZG9lcyBub3QgYXBwbHkKIHRvIGEgcmVx
dWVzdCwgb3RoZXIgcnVsZXMgbWlnaHQgc3RpbGwgYXBwbHkuCiBDdXJyZW50bHkgc3VwcG9y
dGVkIGtleXMgYXJlIGFzIGZvbGxvd3M6CgoKICogYGV2ZW50YXJjLmdvb2dsZWFwaXMuY29t
YDogQ2FuIHVzZSBgQ0VMYCBmdW5jdGlvbnMgdGhhdCBldmFsdWF0ZQogICByZXNvdXJjZSBm
aWVsZHMuCgogKiBgaWFtLmdvb2dsZWFwaXMuY29tYDogQ2FuIHVzZSBgQ0VMYCBmdW5jdGlv
bnMgdGhhdCBldmFsdWF0ZQogICBbcmVzb3VyY2UKICAgdGFnc10oaHR0cHM6Ly9jbG91ZC5n
b29nbGUuY29tL2lhbS9oZWxwL2NvbmRpdGlvbnMvcmVzb3VyY2UtdGFncykgYW5kCiAgIGNv
bWJpbmUgdGhlbSB1c2luZyBib29sZWFuIGFuZCBsb2dpY2FsIG9wZXJhdG9ycy4gT3RoZXIg
ZnVuY3Rpb25zIGFuZAogICBvcGVyYXRvcnMgYXJlIG5vdCBzdXBwb3J0ZWQuCgoNCgUEAgIF
BhIE1QECHwoNCgUEAgIFARIE1QEgKgoNCgUEAgIFAxIE1QEtLgoNCgUEAgIFCBIE1gEGLgoQ
CggEAgIFCJwIABIE1gEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3beta::AccessPolicyResources::AccessPolicy ===
    # Fields for AccessPolicy
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: annotations Type: 11 (.google.iam.v3beta.AccessPolicy.AnnotationsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: details Type: 11 (.google.iam.v3beta.AccessPolicyDetails)

# === Message: Google::Iam::V3beta::AccessPolicyResources::AccessPolicyDetails ===
    # Fields for AccessPolicyDetails
    # Field: rules Type: 11 (.google.iam.v3beta.AccessPolicyRule)

# === Message: Google::Iam::V3beta::AccessPolicyResources::AccessPolicyRule ===
    # Fields for AccessPolicyRule
    # Field: description Type: 9 ()
    # Field: effect Type: 14 (.google.iam.v3beta.AccessPolicyRule.Effect)
    # Field: principals Type: 9 ()
    # Field: excluded_principals Type: 9 ()
    # Field: operation Type: 11 (.google.iam.v3beta.AccessPolicyRule.Operation)
    # Field: conditions Type: 11 (.google.iam.v3beta.AccessPolicyRule.ConditionsEntry)

# Enum: AccessPolicyRule::Effect
our $AccessPolicyRule_EFFECT_UNSPECIFIED = 0;
our $AccessPolicyRule_DENY = 1;
our $AccessPolicyRule_ALLOW = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3beta::AccessPolicyResources - Compiled Protocol Buffers messages for google/iam/v3beta/access_policy_resources.proto

=head1 SYNOPSIS

    use Google::Iam::V3beta::AccessPolicyResources;

    my $msg = Google::Iam::V3beta::AccessPolicyResources::AccessPolicy->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3beta::AccessPolicyResources::AccessPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3beta/access_policy_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3beta::AccessPolicyResources::AccessPolicy

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

Type: C<Message> (L<Google::Iam::V3beta::AccessPolicyResources::AccessPolicy::AnnotationsEntry>)

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

Type: C<Message> (L<Google::Iam::V3beta::AccessPolicyResources::AccessPolicyDetails>)

Optional. The details for the access policy.

=back

=head2 Google::Iam::V3beta::AccessPolicyResources::AccessPolicyDetails

Access policy details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Iam::V3beta::AccessPolicyResources::AccessPolicyRule>)

Required. A list of access policy rules.

=back

=head2 Google::Iam::V3beta::AccessPolicyResources::AccessPolicyRule

Access Policy Rule that determines the behavior of the policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Customer specified description of the rule. Must be less than or
equal to 256 characters.

=item * C<< $msg->effect() >> / C<< $msg->effect($value) >>

Type: C<Enum> (L<Google::Iam::V3beta::AccessPolicyRule::Effect>)

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

Type: C<Message> (L<Google::Iam::V3beta::AccessPolicyResources::AccessPolicyRule::Operation>)

Required. Attributes that are used to determine whether this rule applies
to a request.

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Iam::V3beta::AccessPolicyResources::AccessPolicyRule::ConditionsEntry>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3beta::AccessPolicyResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
