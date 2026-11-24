package Google::Devtools::Resultstore::V2::Action;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Devtools::Resultstore::V2::Common };
    eval { require Google::Devtools::Resultstore::V2::Coverage };
    eval { require Google::Devtools::Resultstore::V2::File };
    eval { require Google::Devtools::Resultstore::V2::FileProcessingError };
    eval { require Google::Devtools::Resultstore::V2::TestSuite };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvYWN0aW9uLnByb3RvEh5nb29nbGUu
ZGV2dG9vbHMucmVzdWx0c3RvcmUudjIaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aK2dv
b2dsZS9kZXZ0b29scy9yZXN1bHRzdG9yZS92Mi9jb21tb24ucHJvdG8aLWdvb2dsZS9kZXZ0
b29scy9yZXN1bHRzdG9yZS92Mi9jb3ZlcmFnZS5wcm90bxopZ29vZ2xlL2RldnRvb2xzL3Jl
c3VsdHN0b3JlL3YyL2ZpbGUucHJvdG8aOmdvb2dsZS9kZXZ0b29scy9yZXN1bHRzdG9yZS92
Mi9maWxlX3Byb2Nlc3NpbmdfZXJyb3IucHJvdG8aL2dvb2dsZS9kZXZ0b29scy9yZXN1bHRz
dG9yZS92Mi90ZXN0X3N1aXRlLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJv
dG8i2gkKBkFjdGlvbhISCgRuYW1lGAEgASgJUgRuYW1lEjkKAmlkGAIgASgLMikuZ29vZ2xl
LmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkFjdGlvbi5JZFICaWQSXQoRc3RhdHVzX2F0dHJp
YnV0ZXMYAyABKAsyMC5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuU3RhdHVzQXR0
cmlidXRlc1IQc3RhdHVzQXR0cmlidXRlcxI+CgZ0aW1pbmcYBCABKAsyJi5nb29nbGUuZGV2
dG9vbHMucmVzdWx0c3RvcmUudjIuVGltaW5nUgZ0aW1pbmcSUAoMYnVpbGRfYWN0aW9uGAkg
ASgLMisuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkJ1aWxkQWN0aW9uSABSC2J1
aWxkQWN0aW9uEk0KC3Rlc3RfYWN0aW9uGAogASgLMiouZ29vZ2xlLmRldnRvb2xzLnJlc3Vs
dHN0b3JlLnYyLlRlc3RBY3Rpb25IAFIKdGVzdEFjdGlvbhJdChFhY3Rpb25fYXR0cmlidXRl
cxgFIAEoCzIwLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5BY3Rpb25BdHRyaWJ1
dGVzUhBhY3Rpb25BdHRyaWJ1dGVzElsKE2FjdGlvbl9kZXBlbmRlbmNpZXMYDiADKAsyKi5n
b29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuRGVwZW5kZW5jeVISYWN0aW9uRGVwZW5k
ZW5jaWVzEkgKCnByb3BlcnRpZXMYByADKAsyKC5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3Rv
cmUudjIuUHJvcGVydHlSCnByb3BlcnRpZXMSOgoFZmlsZXMYCCADKAsyJC5nb29nbGUuZGV2
dG9vbHMucmVzdWx0c3RvcmUudjIuRmlsZVIFZmlsZXMSGwoJZmlsZV9zZXRzGA8gAygJUghm
aWxlU2V0cxJKCghjb3ZlcmFnZRgLIAEoCzIuLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9y
ZS52Mi5BY3Rpb25Db3ZlcmFnZVIIY292ZXJhZ2USagoWZmlsZV9wcm9jZXNzaW5nX2Vycm9y
cxgNIAMoCzI0Lmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5GaWxlUHJvY2Vzc2lu
Z0Vycm9yc1IUZmlsZVByb2Nlc3NpbmdFcnJvcnMajgEKAklkEiMKDWludm9jYXRpb25faWQY
ASABKAlSDGludm9jYXRpb25JZBIbCgl0YXJnZXRfaWQYAiABKAlSCHRhcmdldElkEikKEGNv
bmZpZ3VyYXRpb25faWQYAyABKAlSD2NvbmZpZ3VyYXRpb25JZBIbCglhY3Rpb25faWQYBCAB
KAlSCGFjdGlvbklkOokB6kGFAQohcmVzdWx0c3RvcmUuZ29vZ2xlYXBpcy5jb20vQWN0aW9u
EmBpbnZvY2F0aW9ucy97aW52b2NhdGlvbn0vdGFyZ2V0cy97dGFyZ2V0fS9jb25maWd1cmVk
VGFyZ2V0cy97Y29uZmlndXJlZF90YXJnZXR9L2FjdGlvbnMve2FjdGlvbn1CDQoLYWN0aW9u
X3R5cGUifwoLQnVpbGRBY3Rpb24SEgoEdHlwZRgBIAEoCVIEdHlwZRIsChJwcmltYXJ5X2lu
cHV0X3BhdGgYAiABKAlSEHByaW1hcnlJbnB1dFBhdGgSLgoTcHJpbWFyeV9vdXRwdXRfcGF0
aBgDIAEoCVIRcHJpbWFyeU91dHB1dFBhdGgiiwMKClRlc3RBY3Rpb24SSwoLdGVzdF90aW1p
bmcYASABKAsyKi5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuVGVzdFRpbWluZ1IK
dGVzdFRpbWluZxIhCgxzaGFyZF9udW1iZXIYAiABKAVSC3NoYXJkTnVtYmVyEh0KCnJ1bl9u
dW1iZXIYAyABKAVSCXJ1bk51bWJlchIlCg5hdHRlbXB0X251bWJlchgEIAEoBVINYXR0ZW1w
dE51bWJlchJICgp0ZXN0X3N1aXRlGAUgASgLMikuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0
b3JlLnYyLlRlc3RTdWl0ZVIJdGVzdFN1aXRlEkcKCHdhcm5pbmdzGAggAygLMisuZ29vZ2xl
LmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLlRlc3RXYXJuaW5nUgh3YXJuaW5ncxI0ChZlc3Rp
bWF0ZWRfbWVtb3J5X2J5dGVzGAogASgDUhRlc3RpbWF0ZWRNZW1vcnlCeXRlcyKEAgoQQWN0
aW9uQXR0cmlidXRlcxJgChJleGVjdXRpb25fc3RyYXRlZ3kYASABKA4yMS5nb29nbGUuZGV2
dG9vbHMucmVzdWx0c3RvcmUudjIuRXhlY3V0aW9uU3RyYXRlZ3lSEWV4ZWN1dGlvblN0cmF0
ZWd5EhsKCWV4aXRfY29kZRgCIAEoBVIIZXhpdENvZGUSGgoIaG9zdG5hbWUYAyABKAlSCGhv
c3RuYW1lElUKD2lucHV0X2ZpbGVfaW5mbxgEIAEoCzItLmdvb2dsZS5kZXZ0b29scy5yZXN1
bHRzdG9yZS52Mi5JbnB1dEZpbGVJbmZvUg1pbnB1dEZpbGVJbmZvIsQBCg1JbnB1dEZpbGVJ
bmZvEhQKBWNvdW50GAEgASgDUgVjb3VudBIlCg5kaXN0aW5jdF9jb3VudBgCIAEoA1INZGlz
dGluY3RDb3VudBIfCgtjb3VudF9saW1pdBgDIAEoA1IKY291bnRMaW1pdBIlCg5kaXN0aW5j
dF9ieXRlcxgEIAEoA1INZGlzdGluY3RCeXRlcxIuChNkaXN0aW5jdF9ieXRlX2xpbWl0GAUg
ASgDUhFkaXN0aW5jdEJ5dGVMaW1pdCJgCg9Mb2NhbFRlc3RUaW1pbmcSTQoVdGVzdF9wcm9j
ZXNzX2R1cmF0aW9uGAEgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhN0ZXN0UHJv
Y2Vzc0R1cmF0aW9uIocDChdSZW1vdGVUZXN0QXR0ZW1wdFRpbWluZxJACg5xdWV1ZV9kdXJh
dGlvbhgBIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblINcXVldWVEdXJhdGlvbhJC
Cg91cGxvYWRfZHVyYXRpb24YAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SDnVw
bG9hZER1cmF0aW9uEk8KFm1hY2hpbmVfc2V0dXBfZHVyYXRpb24YAyABKAsyGS5nb29nbGUu
cHJvdG9idWYuRHVyYXRpb25SFG1hY2hpbmVTZXR1cER1cmF0aW9uEk0KFXRlc3RfcHJvY2Vz
c19kdXJhdGlvbhgEIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblITdGVzdFByb2Nl
c3NEdXJhdGlvbhJGChFkb3dubG9hZF9kdXJhdGlvbhgFIAEoCzIZLmdvb2dsZS5wcm90b2J1
Zi5EdXJhdGlvblIQZG93bmxvYWREdXJhdGlvbiK6AQoQUmVtb3RlVGVzdFRpbWluZxJRChds
b2NhbF9hbmFseXNpc19kdXJhdGlvbhgBIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
blIVbG9jYWxBbmFseXNpc0R1cmF0aW9uElMKCGF0dGVtcHRzGAIgAygLMjcuZ29vZ2xlLmRl
dnRvb2xzLnJlc3VsdHN0b3JlLnYyLlJlbW90ZVRlc3RBdHRlbXB0VGltaW5nUghhdHRlbXB0
cyKTAwoKVGVzdFRpbWluZxJHCgVsb2NhbBgBIAEoCzIvLmdvb2dsZS5kZXZ0b29scy5yZXN1
bHRzdG9yZS52Mi5Mb2NhbFRlc3RUaW1pbmdIAFIFbG9jYWwSSgoGcmVtb3RlGAIgASgLMjAu
Z29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLlJlbW90ZVRlc3RUaW1pbmdIAFIGcmVt
b3RlEksKFHN5c3RlbV90aW1lX2R1cmF0aW9uGAMgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1
cmF0aW9uUhJzeXN0ZW1UaW1lRHVyYXRpb24SRwoSdXNlcl90aW1lX2R1cmF0aW9uGAQgASgL
MhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhB1c2VyVGltZUR1cmF0aW9uEk4KDHRlc3Rf
Y2FjaGluZxgFIAEoDjIrLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5UZXN0Q2Fj
aGluZ1ILdGVzdENhY2hpbmdCCgoIbG9jYXRpb24iNgoLVGVzdFdhcm5pbmcSJwoPd2Fybmlu
Z19tZXNzYWdlGAEgASgJUg53YXJuaW5nTWVzc2FnZSqMAQoRRXhlY3V0aW9uU3RyYXRlZ3kS
IgoeRVhFQ1VUSU9OX1NUUkFURUdZX1VOU1BFQ0lGSUVEEAASFQoRT1RIRVJfRU5WSVJPTk1F
TlQQARISCg5SRU1PVEVfU0VSVklDRRACEhIKDkxPQ0FMX1BBUkFMTEVMEAMSFAoQTE9DQUxf
U0VRVUVOVElBTBAEKmYKC1Rlc3RDYWNoaW5nEhwKGFRFU1RfQ0FDSElOR19VTlNQRUNJRklF
RBAAEhMKD0xPQ0FMX0NBQ0hFX0hJVBABEhQKEFJFTU9URV9DQUNIRV9ISVQQAhIOCgpDQUNI
RV9NSVNTEANCfgoiY29tLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52MkILQWN0aW9u
UHJvdG9QAVpJZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29s
cy9yZXN1bHRzdG9yZS92MjtyZXN1bHRzdG9yZUrnbwoHEgUOAOECAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAjCgkKAgMBEgMTADUK
CQoCAwISAxQANwoJCgIDAxIDFQAzCgkKAgMEEgMWAEQKCQoCAwUSAxcAOQoJCgIDBhIDGAAo
CggKAQgSAxoAYAoJCgIICxIDGgBgCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwALAoJ
CgIICBIDHAAsCggKAQgSAx0AOwoJCgIIARIDHQA7CucDCgIEABIFKACUAQEa2QMgQW4gYWN0
aW9uIHRoYXQgaGFwcGVuZWQgYXMgcGFydCBvZiBhIGNvbmZpZ3VyZWQgdGFyZ2V0LiBUaGlz
IGFjdGlvbiBjb3VsZCBiZQogYSBidWlsZCwgYSB0ZXN0LCBvciBhbm90aGVyIHR5cGUgb2Yg
YWN0aW9uLCBhcyBzcGVjaWZpZWQgaW4gYWN0aW9uX3R5cGUKIG9uZW9mLgoKIEVhY2ggcGFy
ZW50IENvbmZpZ3VyZWRUYXJnZXQgcmVzb3VyY2Ugc2hvdWxkIGhhdmUgYXQgbGVhc3Qgb25l
IEFjdGlvbiBhcyBpdHMKIGNoaWxkIHJlc291cmNlIGJlZm9yZSB0aGUgaW52b2NhdGlvbiBp
cyBmaW5hbGl6ZWQuIEZvciBhIHNpbXBsZSBidWlsZCwgYXQKIGxlYXN0IG9uZSBidWlsZCBh
Y3Rpb24gc2hvdWxkIGJlIGNyZWF0ZWQgdG8gcmVwcmVzZW50IHRoZSBidWlsZCByZXN1bHQs
IGFuZAogYXQgbGVhc3Qgb25lIHRlc3QgYWN0aW9uIHNob3VsZCBiZSBjcmVhdGVkIHRvIHJl
cHJlc2VudCB0aGUgdGVzdCByZXN1bHQsIGlmCiBhbnkuCgoKCgMEAAESAygIDgoLCgMEAAcS
BCkCLAQKDQoFBAAHnQgSBCkCLAQKRAoEBAADABIELwI7Axo2IFRoZSByZXNvdXJjZSBJRCBj
b21wb25lbnRzIHRoYXQgaWRlbnRpZnkgdGhlIEFjdGlvbi4KCgwKBQQAAwABEgMvCgwKIwoG
BAADAAIAEgMxBB0aFCBUaGUgSW52b2NhdGlvbiBJRC4KCg4KBwQAAwACAAUSAzEECgoOCgcE
AAMAAgABEgMxCxgKDgoHBAADAAIAAxIDMRscCh8KBgQAAwACARIDNAQZGhAgVGhlIFRhcmdl
dCBJRC4KCg4KBwQAAwACAQUSAzQECgoOCgcEAAMAAgEBEgM0CxQKDgoHBAADAAIBAxIDNBcY
CiYKBgQAAwACAhIDNwQgGhcgVGhlIENvbmZpZ3VyYXRpb24gSUQuCgoOCgcEAAMAAgIFEgM3
BAoKDgoHBAADAAICARIDNwsbCg4KBwQAAwACAgMSAzceHwofCgYEAAMAAgMSAzoEGRoQIFRo
ZSBBY3Rpb24gSUQuCgoOCgcEAAMAAgMFEgM6BAoKDgoHBAADAAIDARIDOgsUCg4KBwQAAwAC
AwMSAzoXGAr4AQoEBAACABIDQQISGuoBIFRoZSByZXNvdXJjZSBuYW1lLiAgSXRzIGZvcm1h
dCBtdXN0IGJlOgogaW52b2NhdGlvbnMvJHtJTlZPQ0FUSU9OX0lEfS90YXJnZXRzLyR7dXJs
X2VuY29kZShUQVJHRVRfSUQpfS9jb25maWd1cmVkVGFyZ2V0cy91cmxfZW5jb2RlKCR7Q09O
RklHX0lEfSkvYWN0aW9ucy8ke3VybF9lbmNvZGUoQUNUSU9OX0lEKX0KCiBTZWUgQ3JlYXRl
QWN0aW9uUmVxdWVzdCBwcm90byBmb3IgbW9yZSBpbmZvcm1hdGlvbi4KCgwKBQQAAgAFEgNB
AggKDAoFBAACAAESA0EJDQoMCgUEAAIAAxIDQRARCn0KBAQAAgESA0UCDBpwIFRoZSByZXNv
dXJjZSBJRCBjb21wb25lbnRzIHRoYXQgaWRlbnRpZnkgdGhlIEFjdGlvbi4gVGhleSBtdXN0
IG1hdGNoIHRoZQogcmVzb3VyY2UgbmFtZSBhZnRlciBwcm9wZXIgZW5jb2RpbmcuCgoMCgUE
AAIBBhIDRQIECgwKBQQAAgEBEgNFBQcKDAoFBAACAQMSA0UKCwooCgQEAAICEgNIAikaGyBU
aGUgc3RhdHVzIG9mIHRoZSBhY3Rpb24uCgoMCgUEAAICBhIDSAISCgwKBQQAAgIBEgNIEyQK
DAoFBAACAgMSA0gnKAq8AQoEBAACAxIDTQIUGq4BIFRoZSB0aW1pbmcgb2YgdGhlIHdob2xl
IGFjdGlvbi4gRm9yIFRlc3RBY3Rpb25zLCB0aGUgc3RhcnQgdGltZSBtYXkgYmUKIGJlZm9y
ZSB0aGUgdGVzdCBhY3R1YWxseSBzdGFydGVkLCBhbmQgdGhlIGR1cmF0aW9uIG1heSBsYXN0
IHVudGlsIGFmdGVyIHRoZQogdGVzdCBhY3R1YWxseSBmaW5pc2hlZC4KCgwKBQQAAgMGEgNN
AggKDAoFBAACAwESA00JDwoMCgUEAAIDAxIDTRITCrQDCgQEAAgAEgRVAlsDGqUDIFRoZSB0
eXBlIG9mIHRoZSBhY3Rpb24uIFRoZSB0eXBlIG9mIGFuIGFjdGlvbiBtYXkgbm90IGNoYW5n
ZSBvdmVyIHRoZQogbGlmZXRpbWUgb2YgdGhlIGludm9jYXRpb24uIElmIG9uZSBvZiB0aGVz
ZSBmaWVsZHMgaXMgdG8gYmUgc2V0LCBpdCBtdXN0IGJlCiBzZXQgaW4gdGhlIENyZWF0ZUFj
dGlvbiBtZXRob2QuIEl0IG1heSBiZSBzZXQgdG8gYW4gZW1wdHkgbWVzc2FnZSB0aGF0IGlz
CiBwb3B1bGF0ZWQgaW4gbGF0ZXIgbWV0aG9kcyBvciBwb3N0LXByb2Nlc3NpbmcuIEEgZ2Vu
ZXJpYyAidW50eXBlZCIgYWN0aW9uCiBjYW4gYmUgY3JlYXRlZCBieSBub3Qgc2V0dGluZyBh
bnkgb2YgdGhlc2UgZmllbGRzLiBBbiB1bnR5cGVkIGFjdGlvbiB3aWxsCiBiZSB1bnR5cGVk
IGZvciB0aGUgbGlmZXRpbWUgb2YgdGhlIGludm9jYXRpb24uCgoMCgUEAAgAARIDVQgTCkQK
BAQAAgQSA1cEIRo3IFVzZWQgb25seSB3aGVuIHRoaXMgYWN0aW9uIHJlcHJlc2VudHMgYSBi
dWlsZCBhY3Rpb24uCgoMCgUEAAIEBhIDVwQPCgwKBQQAAgQBEgNXEBwKDAoFBAACBAMSA1cf
IAolCgQEAAIFEgNaBCAaGCBPbmx5IGZvciB0ZXN0IGFjdGlvbnMuCgoMCgUEAAIFBhIDWgQO
CgwKBQQAAgUBEgNaDxoKDAoFBAACBQMSA1odHwowCgQEAAIGEgNeAikaIyBHZW5lcmFsIGF0
dHJpYnV0ZXMgb2YgdGhlIGFjdGlvbi4KCgwKBQQAAgYGEgNeAhIKDAoFBAACBgESA14TJAoM
CgUEAAIGAxIDXicoCp4BCgQEAAIHEgNiAi8akAEgQSBsaXN0IG9mIHJlc291cmNlcyB0aGF0
IHRoaXMgYWN0aW9uIGRlcGVuZGVkIHVwb24uIE1heSBiZSB1c2VkIHRvIHByb3ZpZGUKIHRo
ZSBjYXVzZSBvZiBhIGJ1aWxkIGZhaWx1cmUgaW4gdGhlIGNhc2Ugb2YgYSBmYWlsZWQgYnVp
bGQgYWN0aW9uLgoKDAoFBAACBwQSA2ICCgoMCgUEAAIHBhIDYgsVCgwKBQQAAgcBEgNiFikK
DAoFBAACBwMSA2IsLgrBAQoEBAACCBIDZwIjGrMBIEFyYml0cmFyeSBuYW1lLXZhbHVlIHBh
aXJzLgogVGhpcyBpcyBpbXBsZW1lbnRlZCBhcyBhIG11bHRpLW1hcC4gTXVsdGlwbGUgcHJv
cGVydGllcyBhcmUgYWxsb3dlZCB3aXRoCiB0aGUgc2FtZSBrZXkuIFByb3BlcnRpZXMgd2ls
bCBiZSByZXR1cm5lZCBpbiBsZXhpY29ncmFwaGljYWwgb3JkZXIgYnkga2V5LgoKDAoFBAAC
CAQSA2cCCgoMCgUEAAIIBhIDZwsTCgwKBQQAAggBEgNnFB4KDAoFBAACCAMSA2chIgqDCAoE
BAACCRIDfgIaGvUHIEEgbGlzdCBvZiBmaWxlIHJlZmVyZW5jZXMgZm9yIGFjdGlvbiBsZXZl
bCBmaWxlcy4KIFRoZSBmaWxlIElEcyBtdXN0IGJlIHVuaXF1ZSB3aXRoaW4gdGhpcyBsaXN0
LiBEdXBsaWNhdGUgZmlsZSBJRHMgd2lsbAogcmVzdWx0IGluIGFuIGVycm9yLiBGaWxlcyB3
aWxsIGJlIHJldHVybmVkIGluIGxleGljb2dyYXBoaWNhbCBvcmRlciBieSBJRC4KCiBGaWxl
cyB3aXRoIHRoZSBmb2xsb3dpbmcgcmVzZXJ2ZWQgZmlsZSBJRHMgY2F1c2Ugc3BlY2lmaWMg
cG9zdC1wcm9jZXNzaW5nCiBvciBoYXZlIHNwZWNpYWwgaGFuZGxpbmcuIFRoZXNlIGZpbGVz
IG11c3QgYmUgaW1tZWRpYXRlbHkgYXZhaWxhYmxlIHRvCiBSZXN1bHRTdG9yZSBmb3IgcHJv
Y2Vzc2luZyB3aGVuIHRoZSByZWZlcmVuY2UgaXMgdXBsb2FkZWQuCgogRm9yIGJ1aWxkIGFj
dGlvbnM6CiBzdGRvdXQ6IFRoZSBzdGRvdXQgb2YgdGhlIGFjdGlvbgogc3RkZXJyOiBUaGUg
c3RkZXJyIG9mIHRoZSBhY3Rpb24KIGJhc2VsaW5lLmxjb3Y6IEJhc2VsaW5lIGNvdmVyYWdl
IGZpbGUgdG8gYmUgcGFyc2VkIGJ5IHRoZSBzZXJ2ZXIuIFRoaXMKICAgICB1c2VzIGEgc3Ry
aXBwZWQgZG93biBpbXBsZW1lbnRhdGlvbiBvZiB0aGUgTENPViBzdGFuZGFyZC4KICAgICBo
dHRwOi8vbHRwLnNvdXJjZWZvcmdlLm5ldC9jb3ZlcmFnZS9sY292L2dlbmluZm8uMS5waHAK
CiBGb3IgdGVzdCBhY3Rpb25zOgogdGVzdC54bWw6IFRoZSB0ZXN0IHN1aXRlIC8gdGVzdCBj
YXNlIGRhdGEgaW4gWE1MIGZvcm1hdC4KIHRlc3QubG9nOiBUaGUgY29tYmluZWQgc3Rkb3V0
IGFuZCBzdGRlcnIgb2YgdGhlIHRlc3QgcHJvY2Vzcy4KIHRlc3QubGNvdjogQ292ZXJhZ2Ug
ZmlsZSB0byBiZSBwYXJzZWQgYnkgdGhlIHNlcnZlci4gVGhpcyB1c2VzIGEgc3RyaXBwZWQK
ICAgICBkb3duIGltcGxlbWVudGF0aW9uIG9mIHRoZSBMQ09WIHN0YW5kYXJkLgogICAgIGh0
dHA6Ly9sdHAuc291cmNlZm9yZ2UubmV0L2NvdmVyYWdlL2xjb3YvZ2VuaW5mby4xLnBocAoK
DAoFBAACCQQSA34CCgoMCgUEAAIJBhIDfgsPCgwKBQQAAgkBEgN+EBUKDAoFBAACCQMSA34Y
GQrfAQoEBAACChIEgwECIRrQASBMaXN0IG9mIG5hbWVzIG9mIGZpbGUgc2V0cyB0aGF0IGFy
ZSByZWZlcmVuY2VkIGZyb20gdGhpcyBBY3Rpb24uCiBFYWNoIG5hbWUgbXVzdCBwb2ludCB0
byBhIGZpbGUgc2V0IHVuZGVyIHRoZSBzYW1lIEludm9jYXRpb24uIFRoZSBuYW1lCiBmb3Jt
YXQgbXVzdCBiZTogaW52b2NhdGlvbnMvJHtJTlZPQ0FUSU9OX0lEfS9maWxlU2V0cy8ke0ZJ
TEVfU0VUX0lEfQoKDQoFBAACCgQSBIMBAgoKDQoFBAACCgUSBIMBCxEKDQoFBAACCgESBIMB
EhsKDQoFBAACCgMSBIMBHiAK3QMKBAQAAgsSBIwBAh8azgMgQ292ZXJhZ2UgZGF0YSB3YXMg
Y29sbGVjdGVkIHdoaWxlIHJ1bm5pbmcgdGhlIGJ1aWxkIG9yIHRlc3QgYWN0aW9uLiBUaGlz
CiB1c3VhbGx5IGluY2x1ZGVzIGxpbmUgY292ZXJhZ2UsIGFuZCBtYXkgYWxzbyBpbmNsdWRl
IGJyYW5jaCBjb3ZlcmFnZS4KIEZvciB0ZXN0IGFjdGlvbnMsIHRoaXMgaXMgdXN1YWxseSBv
bmx5IGZvciB0aGUgc291cmNlIGZpbGVzIHdoaWNoIHdlcmUKIGFjdHVhbGx5IGV4ZWN1dGVk
IGJ5IHRoYXQgcGFydGljdWxhciBhY3Rpb24uCiBGb3IgYnVpbGQgYWN0aW9ucywgdGhpcyBp
cyB0aGUgYmFzZWxpbmUgY292ZXJhZ2UsIHdoaWNoIGNhcHR1cmVzIHRoZQogaW5zdHJ1bWVu
dGVkIGZpbGVzIGFuZCBsaW5lcywgd2l0aG91dCBhbnkgbGluZXMgYmVpbmcgZXhlY3V0ZWQu
IFRoaXMKIGVuc3VyZXMgZmlsZXMgdGhhdCBhcmUgbmV2ZXIgY292ZXJlZCBhdCBhbGwgYXJl
IGluY2x1ZGVkLgoKDQoFBAACCwYSBIwBAhAKDQoFBAACCwESBIwBERkKDQoFBAACCwMSBIwB
HB4KtwIKBAQAAgwSBJMBAjwaqAIgUmVzdWx0U3RvcmUgd2lsbCByZWFkIGFuZCBwYXJzZSBG
aWxlcyB3aXRoIHJlc2VydmVkIElEcyBsaXN0ZWQgYWJvdmUuIFJlYWQKIGFuZCBwYXJzZSBl
cnJvcnMgZm9yIGFsbCB0aGVzZSBGaWxlcyBhcmUgcmVwb3J0ZWQgaGVyZS4KIFRoaXMgaXMg
aW1wbGVtZW50ZWQgYXMgYSBtYXAsIHdpdGggb25lIEZpbGVQcm9jZXNzaW5nRXJyb3JzIGZv
ciBlYWNoIGZpbGUuCiBUeXBpY2FsbHkgcHJvZHVjZWQgd2hlbiBwYXJzaW5nIEZpbGVzLCBi
dXQgbWF5IGFsc28gYmUgcHJvdmlkZWQgZGlyZWN0bHkKIGJ5IGNsaWVudHMuCgoNCgUEAAIM
BBIEkwECCgoNCgUEAAIMBhIEkwELHwoNCgUEAAIMARIEkwEgNgoNCgUEAAIMAxIEkwE5OwpA
CgIEARIGlwEApgEBGjIgQSBidWlsZCBhY3Rpb24sIHN1Y2ggYXMgYnVpbGRpbmcgYSBqYXZh
IGxpYnJhcnkuCgoLCgMEAQESBJcBCBMKrQEKBAQBAgASBJsBAhIangEgVGhlIHR5cGUgb2Yg
dGhlIGFjdGlvbi4gIFRoaXMgaXMgaW50ZW5kZWQgdG8gYmUgYSBjbHVlIGFzIHRvIGhvdyB0
aGUgb3V0cHV0CiBvZiB0aGUgYWN0aW9uIHNob3VsZCBiZSBwYXJzZWQuIEZvciBleGFtcGxl
ICJqYXZhYyIgZm9yIGEgSmF2YSBjb21waWxlCiBhY3Rpb24uCgoNCgUEAQIABRIEmwECCAoN
CgUEAQIAARIEmwEJDQoNCgUEAQIAAxIEmwEQEQrOAQoEBAECARIEoAECIBq/ASBUaGUgInBy
aW1hcnkiIGlucHV0IGFydGlmYWN0IHByb2Nlc3NlZCBieSB0aGlzIGFjdGlvbi4gIEUuZy4s
IHRoZSAuY2MgZmlsZQogb2YgYSBDKysgY29tcGlsZSBhY3Rpb24uICBFbXB0eSBzdHJpbmcg
KCIiKSBpZiB0aGUgYWN0aW9uIGhhcyBubyBpbnB1dAogYXJ0aWZhY3RzIG9yIG5vICJwcmlt
YXJ5IiBpbnB1dCBhcnRpZmFjdC4KCg0KBQQBAgEFEgSgAQIICg0KBQQBAgEBEgSgAQkbCg0K
BQQBAgEDEgSgAR4fCtABCgQEAQICEgSlAQIhGsEBIFRoZSAicHJpbWFyeSIgb3V0cHV0IGFy
dGlmYWN0IHByb2Nlc3NlZCBieSB0aGlzIGFjdGlvbi4gIEUuZy4sIHRoZSAubyBmaWxlCiBv
ZiBhIEMrKyBjb21waWxlIGFjdGlvbi4gIEVtcHR5IHN0cmluZyAoIiIpIGlmIHRoZSBhY3Rp
b24gaGFzIG5vIG91dHB1dAogYXJ0aWZhY3RzIG9yIG5vICJwcmltYXJ5IiBvdXRwdXQgYXJ0
aWZhY3QuCgoNCgUEAQICBRIEpQECCAoNCgUEAQICARIEpQEJHAoNCgUEAQICAxIEpQEfIApE
CgIEAhIGqQEAywEBGjYgQSB0ZXN0IGFjdGlvbiwgc3VjaCBhcyBydW5uaW5nIGEgSlVuaXQ0
IHRlc3QgYmluYXJ5LgoKCwoDBAIBEgSpAQgSCj0KBAQCAgASBKsBAh0aLyBUaW1pbmcgZGF0
YSBmb3IgZXhlY3V0aW9uIG9mIHRoZSB0ZXN0IGFjdGlvbi4KCg0KBQQCAgAGEgSrAQIMCg0K
BQQCAgABEgSrAQ0YCg0KBQQCAgADEgSrARscCpACCgQEAgIBEgSxAQIZGoECIElmIHRoZSB0
ZXN0IGlzIGRpdmlkZWQgdXAgaW50byBzaGFyZHMgdG8gaW1wcm92ZSBwZXJmb3JtYW5jZSwg
c2V0IHRoaXMgdG8KIGluZGljYXRlIHdoaWNoIHNoYXJkIHRoaXMgdGVzdCBhY3Rpb24gaXMg
Zm9yLiBWYWx1ZSBtdXN0IGJlIGluIGludGVydmFsCiBbMCwgdG90YWxfc2hhcmRfY291bnQp
LiBEZWZhdWx0cyB0byAwLCB3aGljaCBpcyBhcHByb3ByaWF0ZSBpZiBhbGwgdGVzdAogY2Fz
ZXMgYXJlIHJ1biBpbiB0aGUgc2FtZSBwcm9jZXNzLgoKDQoFBAICAQUSBLEBAgcKDQoFBAIC
AQESBLEBCBQKDQoFBAICAQMSBLEBFxgKqAIKBAQCAgISBLcBAhcamQIgSWYgdGhlIHVzZXIg
cmVxdWVzdGVkIHRoYXQgZXZlcnkgdGVzdCBiZSBydW4gbXVsdGlwbGUgdGltZXMsIGFzIGlz
IG9mdGVuCiBkb25lIHRvIG1lYXN1cmUgZmxha2luZXNzLCBzZXQgdGhpcyB0byBpbmRpY2F0
ZSB3aGljaCBydW4gdGhpcyB0ZXN0IGFjdGlvbgogaXMgZm9yLiBWYWx1ZSBtdXN0IGJlIGlu
IGludGVydmFsIFswLCB0b3RhbF9ydW5fY291bnQpLiBEZWZhdWx0cyB0byAwLAogd2hpY2gg
aXMgYXBwcm9wcmlhdGUgaWYgbXVsdGlwbGUgcnVucyB3ZXJlIG5vdCByZXF1ZXN0ZWQuCgoN
CgUEAgICBRIEtwECBwoNCgUEAgICARIEtwEIEgoNCgUEAgICAxIEtwEVFgrzAQoEBAICAxIE
vQECGxrkASBJZiBmbGFreSB0ZXN0cyBhcmUgYXV0b21hdGljYWxseSByZXRyaWVkLCBzZXQg
dGhpcyB0byBpbmRpY2F0ZSB3aGljaAogYXR0ZW1wdCB0aGlzIHRlc3QgYWN0aW9uIGlzIGZv
ci4gKGUuZy4gMCBmb3IgdGhlIGZpcnN0IGF0dGVtcHQsIDEgZm9yCiBzZWNvbmQsIGFuZCBz
byBvbikuIERlZmF1bHRzIHRvIDAsIHdoaWNoIGlzIGFwcHJvcHJpYXRlIGlmIHRoaXMgaXMg
dGhlIG9ubHkKIGF0dGVtcHQuCgoNCgUEAgIDBRIEvQECBwoNCgUEAgIDARIEvQEIFgoNCgUE
AgIDAxIEvQEZGgr6AQoEBAICBBIEwwECGxrrASBBIHRyZWUgb2YgdGVzdCBzdWl0ZXMgYW5k
IHRlc3QgY2FzZXMgdGhhdCB3ZXJlIHJ1biBieSB0aGlzIHRlc3QgYWN0aW9uLgogRWFjaCB0
ZXN0IGNhc2UgaGFzIGl0cyBvd24gc3RhdHVzIGluZm9ybWF0aW9uLCBpbmNsdWRpbmcgc3Rh
Y2sgdHJhY2VzLgogVHlwaWNhbGx5IHByb2R1Y2VkIGJ5IHBhcnNpbmcgYW4gWE1MIExvZywg
YnV0IG1heSBhbHNvIGJlIHByb3ZpZGVkIGRpcmVjdGx5CiBieSBjbGllbnRzLgoKDQoFBAIC
BAYSBMMBAgsKDQoFBAICBAESBMMBDBYKDQoFBAICBAMSBMMBGRoKLgoEBAICBRIExgECJBog
IFdhcm5pbmdzIGZvciB0aGlzIHRlc3QgYWN0aW9uLgoKDQoFBAICBQQSBMYBAgoKDQoFBAIC
BQYSBMYBCxYKDQoFBAICBQESBMYBFx8KDQoFBAICBQMSBMYBIiMKmgEKBAQCAgYSBMoBAiQa
iwEgRXN0aW1hdGVkIG1lbW9yeSBjb25zdW1wdGlvbiBvZiB0aGUgdGVzdCBhY3Rpb24sIGlu
IGJ5dGVzLiBBIGRlZmF1bHQgdmFsdWUKIG9mIDAgbWVhbnMgdGhlcmUgaXMgbm8gbWVtb3J5
IGNvbnN1bXB0aW9uIGVzdGltYXRlIHNwZWNpZmllZC4KCg0KBQQCAgYFEgTKAQIHCg0KBQQC
AgYBEgTKAQgeCg0KBQQCAgYDEgTKASEjCi8KAgQDEgbOAQDcAQEaISBHZW5lcmFsIGF0dHJp
YnV0ZXMgb2YgYW4gYWN0aW9uCgoLCgMEAwESBM4BCBgKNwoEBAMCABIE0AECKxopIFN0cmF0
ZWd5IHVzZWQgZm9yIGV4ZWN1dGluZyB0aGUgYWN0aW9uLgoKDQoFBAMCAAYSBNABAhMKDQoF
BAMCAAESBNABFCYKDQoFBAMCAAMSBNABKSoKXgoEBAMCARIE1AECFhpQIEV4aXQgY29kZSBv
ZiB0aGUgcHJvY2VzcyB0aGF0IHJhbiB0aGUgYWN0aW9uLiBBIG5vbi16ZXJvIHZhbHVlIG1l
YW5zCiBmYWlsdXJlLgoKDQoFBAMCAQUSBNQBAgcKDQoFBAMCAQESBNQBCBEKDQoFBAMCAQMS
BNQBFBUKKQoEBAMCAhIE1wECFhobIFdoZXJlIHRoZSBhY3Rpb24gd2FzIHJ1bi4KCg0KBQQD
AgIFEgTXAQIICg0KBQQDAgIBEgTXAQkRCg0KBQQDAgIDEgTXARQVCmQKBAQDAgMSBNsBAiQa
ViBJbmZvcm1hdGlvbiBhYm91dCB0aGUgaW5wdXQgZmlsZXMgdXNlZCBpbiBhbGwgYWN0aW9u
cyB1bmRlciB0aGlzIGNvbmZpZ3VyZWQKIHRhcmdldC4KCg0KBQQDAgMGEgTbAQIPCg0KBQQD
AgMBEgTbARAfCg0KBQQDAgMDEgTbASIjClsKAgQEEgbfAQDvAQEaTSBGaWxlIGNvdW50IGFu
ZCBzaXplIGluZm9ybWF0aW9uIGZvciB0aGUgaW5wdXQgZmlsZXMgdG8gYSBjb25maWd1cmVk
IHRhcmdldC4KCgsKAwQEARIE3wEIFQpVCgQEBAIAEgThAQISGkcgVGhlIG51bWJlciBvZiBp
bnB1dCBmaWxlcyAoY291bnRpbmcgZXZlcnkgZmlsZSwgZXZlbiBpZiBhIGR1cGxpY2F0ZSku
CgoNCgUEBAIABRIE4QECBwoNCgUEBAIAARIE4QEIDQoNCgUEBAIAAxIE4QEQEQozCgQEBAIB
EgTkAQIbGiUgVGhlIG51bWJlciBvZiBkaXN0aW5jdCBpbnB1dCBmaWxlcy4KCg0KBQQEAgEF
EgTkAQIHCg0KBQQEAgEBEgTkAQgWCg0KBQQEAgEDEgTkARkaCnYKBAQEAgISBOgBAhgaaCBU
aGUgbWF4IG51bWJlciBvZiBpbnB1dCBmaWxlcyBhbGxvd2VkIGJ5IHRoZSBidWlsZCBzeXN0
ZW0gKGNvdW50aW5nIGV2ZXJ5CiBmaWxlLCBldmVuIGlmIGEgZHVwbGljYXRlKS4KCg0KBQQE
AgIFEgToAQIHCg0KBQQEAgIBEgToAQgTCg0KBQQEAgIDEgToARYXCjsKBAQEAgMSBOsBAhsa
LSBUaGUgdG90YWwgc2l6ZSBvZiB0aGUgZGlzdGluY3QgaW5wdXQgZmlsZXMuCgoNCgUEBAID
BRIE6wECBwoNCgUEBAIDARIE6wEIFgoNCgUEBAIDAxIE6wEZGgpHCgQEBAIEEgTuAQIgGjkg
VGhlIG1heCBhbGxvd2VkIHRvdGFsIHNpemUgb2YgdGhlIGRpc3RpbmN0IGlucHV0IGZpbGVz
LgoKDQoFBAQCBAUSBO4BAgcKDQoFBAQCBAESBO4BCBsKDQoFBAQCBAMSBO4BHh8KWAoCBAUS
BvIBAPYBARpKIFRpbWluZyBkYXRhIGZvciB0ZXN0cyBleGVjdXRlZCBsb2NhbGx5IG9uIHRo
ZSBtYWNoaW5lIHJ1bm5pbmcgdGhlIGJ1aWxkLgoKCwoDBAUBEgTyAQgXCmAKBAQFAgASBPUB
AjUaUiBUaW1lIHRha2VuIGJ5IHRoZSB0ZXN0IHByb2Nlc3MsIHR5cGljYWxseSBzdXJyb3Vu
ZGVkIGJ5IGEgc21hbGwgd3JhcHBlcgogc2NyaXB0LgoKDQoFBAUCAAYSBPUBAhoKDQoFBAUC
AAESBPUBGzAKDQoFBAUCAAMSBPUBMzQKTgoCBAYSBvkBAJECARpAIFRpbWluZyBkYXRhIGZv
ciBvbmUgYXR0ZW1wdCB0byBleGVjdXRlIGEgdGVzdCBhY3Rpb24gcmVtb3RlbHkuCgoLCgME
BgESBPkBCB8KVQoEBAYCABIE+wECLhpHIElkbGUgcGVyaW9kIGJlZm9yZSB0aGUgdGVzdCBw
cm9jZXNzIGlzIGludm9rZWQgb24gdGhlIHJlbW90ZSBtYWNoaW5lLgoKDQoFBAYCAAYSBPsB
AhoKDQoFBAYCAAESBPsBGykKDQoFBAYCAAMSBPsBLC0KjQEKBAQGAgESBP8BAi8afyBUaW1l
IHRvIHVwbG9hZCBkYXRhIGRlcGVuZGVuY2llcyBmcm9tIHRoZSBsb2NhbCBtYWNoaW5lIHRv
IHRoZSByZW1vdGUKIG1hY2hpbmUgcnVubmluZyB0aGUgdGVzdCwgb3IgdG8gdGhlIGRpc3Ry
aWJ1dGVkIGNhY2hlLgoKDQoFBAYCAQYSBP8BAhoKDQoFBAYCAQESBP8BGyoKDQoFBAYCAQMS
BP8BLS4KnAEKBAQGAgISBIQCAjYajQEgVGltZSB0byBzZXQgdXAgdGhlIHJlbW90ZSBtYWNo
aW5lLgogTm90IHRvIGJlIGNvbmZ1c2VkIHdpdGggc2V0dXAgdGltZSBpbgogeFVuaXQgdGVz
dCBmcmFtZXdvcmtzLCB3aGljaCBmYWxscyB3aXRoaW4gdGhlIHRlc3RfcHJvY2Vzc190aW1l
LgoKDQoFBAYCAgYSBIQCAhoKDQoFBAYCAgESBIQCGzEKDQoFBAYCAgMSBIQCNDUK2AIKBAQG
AgMSBIwCAjUayQIgVGltZSB0YWtlbiBieSB0aGUgdGVzdCBwcm9jZXNzLCB0eXBpY2FsbHkg
c3Vycm91bmRlZCBieSBhIHNtYWxsIHdyYXBwZXIKIHNjcmlwdC4KIEZvciBKYXZhIHRlc3Rz
LCB0aGlzIGluY2x1ZGVzIEpWTSBzZXR1cCwgZmxhZyBwYXJzaW5nLCBjbGFzcyBwYXRoIHNl
dHVwLAogcGFyc2luZyBmaWxlcyB0byBzZXR1cCB0aGUgc3VpdGUsIGFuZCBmaW5hbGx5IHJ1
bm5pbmcgeW91ciB0ZXN0IG1ldGhvZHMuCiBJbiBtYW55IGNhc2VzLCBvbmx5IGEgc21hbGwg
ZnJhY3Rpb24gb2YgdGhlIHRlc3QgcHJvY2VzcyB0aW1lIGlzIHNwZW50CiBydW5uaW5nIHRo
ZSB0ZXN0IG1ldGhvZHMuCgoNCgUEBgIDBhIEjAICGgoNCgUEBgIDARIEjAIbMAoNCgUEBgID
AxIEjAIzNApnCgQEBgIEEgSQAgIxGlkgVGltZSBzcGVudCByZXRyaWV2aW5nIHRlc3QgbG9n
cyBhbmQgYW55IG90aGVyIHRlc3Qgb3V0cHV0cywgYmFjayB0byB0aGUKIGxvY2FsIG1hY2hp
bmUuCgoNCgUEBgIEBhIEkAICGgoNCgUEBgIEARIEkAIbLAoNCgUEBgIEAxIEkAIvMApVCgIE
BxIGlAIAmwIBGkcgVGltaW5nIGRhdGEgZm9yIHRoZSBwYXJ0IG9mIHRoZSB0ZXN0IGV4ZWN1
dGlvbiB0aGF0IGlzIGRvbmUgcmVtb3RlbHkuCgoLCgMEBwESBJQCCBgKOwoEBAcCABIElgIC
NxotIFRpbWUgdGFrZW4gbG9jYWxseSB0byBkZXRlcm1pbmUgd2hhdCB0byBkby4KCg0KBQQH
AgAGEgSWAgIaCg0KBQQHAgABEgSWAhsyCg0KBQQHAgADEgSWAjU2Cn8KBAQHAgESBJoCAjAa
cSBOb3JtYWxseSB0aGVyZSBpcyBvbmx5IG9uZSBhdHRlbXB0LCBidXQgdGhlIHN5c3RlbSBt
YXkgcmV0cnkgb24gaW50ZXJuYWwKIGVycm9ycywgbGVhZGluZyB0byBtdWx0aXBsZSBhdHRl
bXB0cy4KCg0KBQQHAgEEEgSaAgIKCg0KBQQHAgEGEgSaAgsiCg0KBQQHAgEBEgSaAiMrCg0K
BQQHAgEDEgSaAi4vCpEBCgIECBIGnwIAuAIBGoIBIFRpbWluZyBkYXRhIGZvciBleGVjdXRp
b24gb2YgYSB0ZXN0IGFjdGlvbi4gVGhlIGFjdGlvbiBtYXkgYmUgcGVyZm9ybWVkCiBsb2Nh
bGx5LCBvbiB0aGUgbWFjaGluZSBydW5uaW5nIHRoZSBidWlsZCwgb3IgcmVtb3RlbHkuCgoL
CgMECAESBJ8CCBIKRQoEBAgIABIGoQICpwIDGjUgVGVzdCB0aW1pbmcgZm9yIGVpdGhlciBh
IGxvY2FsIG9yIHJlbW90ZSBleGVjdXRpb24uCgoNCgUECAgAARIEoQIIEAosCgQECAIAEgSj
AgQeGh4gVXNlZCBmb3IgbG9jYWwgdGVzdCBhY3Rpb25zLgoKDQoFBAgCAAYSBKMCBBMKDQoF
BAgCAAESBKMCFBkKDQoFBAgCAAMSBKMCHB0KLQoEBAgCARIEpgIEIBofIFVzZWQgZm9yIHJl
bW90ZSB0ZXN0IGFjdGlvbnMuCgoNCgUECAIBBhIEpgIEFAoNCgUECAIBARIEpgIVGwoNCgUE
CAIBAxIEpgIeHwrRAQoEBAgCAhIErAICNBrCASBUaGUgYW1vdW50IG9mIENQVSB0aW1lIHNw
ZW50IGJ5IHRoZSB0ZXN0IHByb2Nlc3MgZXhlY3V0aW5nIHN5c3RlbSBjYWxscwogd2l0aGlu
IHRoZSBrZXJuZWwsIGFzIG9wcG9zZWQgdG8gbGlicmFyeSBjb2RlLiBUaW1lIHRoZSB0ZXN0
IHByb2Nlc3Mgc3BlbnQKIGJsb2NrZWQgZG9lcyBub3QgY291bnQgdG93YXJkcyB0aGlzIGZp
Z3VyZS4KCg0KBQQIAgIGEgSsAgIaCg0KBQQIAgIBEgSsAhsvCg0KBQQIAgIDEgSsAjIzCqsC
CgQECAIDEgSyAgIyGpwCIFRoZSBhbW91bnQgb2YgQ1BVIHRpbWUgc3BlbnQgYnkgdGhlIHRl
c3QgcHJvY2VzcyBleGVjdXRpbmcgdXNlci1tb2RlIGNvZGUKIG91dHNpZGUgdGhlIGtlcm5l
bCwgYXMgb3Bwb3NlZCB0byBsaWJyYXJ5IGNvZGUuIFRpbWUgdGhlIHRlc3QgcHJvY2Vzcwog
c3BlbnQgYmxvY2tlZCBkb2VzIG5vdCBjb3VudCB0b3dhcmRzIHRoaXMgZmlndXJlLiBZb3Ug
Y2FuIGFkZCB1c2VyX3RpbWUgdG8KIHN5c3RlbV90aW1lIHRvIGdldCB0b3RhbCBDUFUgdGlt
ZSB0YWtlbiBieSB0aGUgdGVzdCBwcm9jZXNzLgoKDQoFBAgCAwYSBLICAhoKDQoFBAgCAwES
BLICGy0KDQoFBAgCAwMSBLICMDEK3AEKBAQIAgQSBLcCAh8azQEgTW9zdCBidWlsZCBzeXN0
ZW1zIGNhY2hlIGJ1aWxkIHJlc3VsdHMgdG8gc3BlZWQgdXAgaW5jcmVtZW50YWwgYnVpbGRz
LgogU29tZSBhbHNvIGNhY2hlIHRlc3QgcmVzdWx0cyB0b28uIFRoaXMgaW5kaWNhdGVzIHdo
ZXRoZXIgdGhlIHRlc3QgcmVzdWx0cwogd2VyZSBmb3VuZCBpbiBhIGNhY2hlLCBhbmQgd2hl
cmUgdGhhdCBjYWNoZSB3YXMgbG9jYXRlZC4KCg0KBQQIAgQGEgS3AgINCg0KBQQIAgQBEgS3
Ag4aCg0KBQQIAgQDEgS3Ah0eCjAKAgQJEga7AgC+AgEaIiBBIHdhcm5pbmcgZnJvbSBhIHRl
c3QgZXhlY3V0aW9uLgoKCwoDBAkBEgS7AggTCjsKBAQJAgASBL0CAh0aLSBDb250YWlucyB0
aGUgbWVzc2FnZSBkZXRhaWxpbmcgdGhlIHdhcm5pbmcuCgoNCgUECQIABRIEvQICCAoNCgUE
CQIAARIEvQIJGAoNCgUECQIAAxIEvQIbHAo9CgIFABIGwQIA0AIBGi8gSW5kaWNhdGVzIGhv
dy93aGVyZSB0aGlzIEFjdGlvbiB3YXMgZXhlY3V0ZWQuCgoLCgMFAAESBMECBRYKQAoEBQAC
ABIEwwICJRoyIFRoZSBhY3Rpb24gZGlkIG5vdCBpbmRpY2F0ZSBob3cgaXQgd2FzIGV4ZWN1
dGVkLgoKDQoFBQACAAESBMMCAiAKDQoFBQACAAISBMMCIyQKOwoEBQACARIExgICGBotIFRo
ZSBhY3Rpb24gd2FzIGV4ZWN1dGVkIGluIHNvbWUgb3RoZXIgZm9ybS4KCg0KBQUAAgEBEgTG
AgITCg0KBQUAAgECEgTGAhYXCjcKBAUAAgISBMkCAhUaKSBUaGUgYWN0aW9uIHVzZWQgYSBy
ZW1vdGUgYnVpbGQgc2VydmljZS4KCg0KBQUAAgIBEgTJAgIQCg0KBQUAAgICEgTJAhMUClAK
BAUAAgMSBMwCAhUaQiBUaGUgYWN0aW9uIHdhcyBleGVjdXRlZCBsb2NhbGx5LCBpbiBwYXJh
bGxlbCB3aXRoIG90aGVyIGFjdGlvbnMuCgoNCgUFAAIDARIEzAICEAoNCgUFAAIDAhIEzAIT
FApFCgQFAAIEEgTPAgIXGjcgVGhlIGFjdGlvbiB3YXMgZXhlY3V0ZWQgbG9jYWxseSwgd2l0
aG91dCBwYXJhbGxlbGlzbS4KCg0KBQUAAgQBEgTPAgISCg0KBQUAAgQCEgTPAhUWCtwBCgIF
ARIG1QIA4QIBGs0BIE1vc3QgYnVpbGQgc3lzdGVtcyBjYWNoZSBidWlsZCByZXN1bHRzIHRv
IHNwZWVkIHVwIGluY3JlbWVudGFsIGJ1aWxkcy4KIFNvbWUgYWxzbyBjYWNoZSB0ZXN0IHJl
c3VsdHMgdG9vLiBUaGlzIGluZGljYXRlcyB3aGV0aGVyIHRoZSB0ZXN0IHJlc3VsdHMKIHdl
cmUgZm91bmQgaW4gYSBjYWNoZSwgYW5kIHdoZXJlIHRoYXQgY2FjaGUgd2FzIGxvY2F0ZWQu
CgoLCgMFAQESBNUCBRAKRQoEBQECABIE1wICHxo3IFRoZSBpbXBsaWNpdCBkZWZhdWx0IGVu
dW0gdmFsdWUuIFNob3VsZCBuZXZlciBiZSBzZXQuCgoNCgUFAQIAARIE1wICGgoNCgUFAQIA
AhIE1wIdHgpTCgQFAQIBEgTaAgIWGkUgVGhlIHRlc3QgcmVzdWx0IHdhcyBmb3VuZCBpbiBh
IGxvY2FsIGNhY2hlLCBzbyBpdCB3YXNuJ3QgcnVuIGFnYWluLgoKDQoFBQECAQESBNoCAhEK
DQoFBQECAQISBNoCFBUKVAoEBQECAhIE3QICFxpGIFRoZSB0ZXN0IHJlc3VsdCB3YXMgZm91
bmQgaW4gYSByZW1vdGUgY2FjaGUsIHNvIGl0IHdhc24ndCBydW4gYWdhaW4uCgoNCgUFAQIC
ARIE3QICEgoNCgUFAQICAhIE3QIVFgpWCgQFAQIDEgTgAgIRGkggVGhlIHRlc3QgcmVzdWx0
IHdhcyBub3QgZm91bmQgaW4gYW55IGNhY2hlLCBzbyBpdCBoYWQgdG8gYmUgcnVuIGFnYWlu
LgoKDQoFBQECAwESBOACAgwKDQoFBQECAwISBOACDxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::Action::Action ===
    # Fields for Action
    # Field: name Type: 9 ()
    # Field: id Type: 11 (.google.devtools.resultstore.v2.Action.Id)
    # Field: status_attributes Type: 11 (.google.devtools.resultstore.v2.StatusAttributes)
    # Field: timing Type: 11 (.google.devtools.resultstore.v2.Timing)
    # Field: build_action Type: 11 (.google.devtools.resultstore.v2.BuildAction)
    # Field: test_action Type: 11 (.google.devtools.resultstore.v2.TestAction)
    # Field: action_attributes Type: 11 (.google.devtools.resultstore.v2.ActionAttributes)
    # Field: action_dependencies Type: 11 (.google.devtools.resultstore.v2.Dependency)
    # Field: properties Type: 11 (.google.devtools.resultstore.v2.Property)
    # Field: files Type: 11 (.google.devtools.resultstore.v2.File)
    # Field: file_sets Type: 9 ()
    # Field: coverage Type: 11 (.google.devtools.resultstore.v2.ActionCoverage)
    # Field: file_processing_errors Type: 11 (.google.devtools.resultstore.v2.FileProcessingErrors)

# === Message: Google::Devtools::Resultstore::V2::Action::BuildAction ===
    # Fields for BuildAction
    # Field: type Type: 9 ()
    # Field: primary_input_path Type: 9 ()
    # Field: primary_output_path Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::Action::TestAction ===
    # Fields for TestAction
    # Field: test_timing Type: 11 (.google.devtools.resultstore.v2.TestTiming)
    # Field: shard_number Type: 5 ()
    # Field: run_number Type: 5 ()
    # Field: attempt_number Type: 5 ()
    # Field: test_suite Type: 11 (.google.devtools.resultstore.v2.TestSuite)
    # Field: warnings Type: 11 (.google.devtools.resultstore.v2.TestWarning)
    # Field: estimated_memory_bytes Type: 3 ()

# === Message: Google::Devtools::Resultstore::V2::Action::ActionAttributes ===
    # Fields for ActionAttributes
    # Field: execution_strategy Type: 14 (.google.devtools.resultstore.v2.ExecutionStrategy)
    # Field: exit_code Type: 5 ()
    # Field: hostname Type: 9 ()
    # Field: input_file_info Type: 11 (.google.devtools.resultstore.v2.InputFileInfo)

# === Message: Google::Devtools::Resultstore::V2::Action::InputFileInfo ===
    # Fields for InputFileInfo
    # Field: count Type: 3 ()
    # Field: distinct_count Type: 3 ()
    # Field: count_limit Type: 3 ()
    # Field: distinct_bytes Type: 3 ()
    # Field: distinct_byte_limit Type: 3 ()

# === Message: Google::Devtools::Resultstore::V2::Action::LocalTestTiming ===
    # Fields for LocalTestTiming
    # Field: test_process_duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Devtools::Resultstore::V2::Action::RemoteTestAttemptTiming ===
    # Fields for RemoteTestAttemptTiming
    # Field: queue_duration Type: 11 (.google.protobuf.Duration)
    # Field: upload_duration Type: 11 (.google.protobuf.Duration)
    # Field: machine_setup_duration Type: 11 (.google.protobuf.Duration)
    # Field: test_process_duration Type: 11 (.google.protobuf.Duration)
    # Field: download_duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Devtools::Resultstore::V2::Action::RemoteTestTiming ===
    # Fields for RemoteTestTiming
    # Field: local_analysis_duration Type: 11 (.google.protobuf.Duration)
    # Field: attempts Type: 11 (.google.devtools.resultstore.v2.RemoteTestAttemptTiming)

# === Message: Google::Devtools::Resultstore::V2::Action::TestTiming ===
    # Fields for TestTiming
    # Field: local Type: 11 (.google.devtools.resultstore.v2.LocalTestTiming)
    # Field: remote Type: 11 (.google.devtools.resultstore.v2.RemoteTestTiming)
    # Field: system_time_duration Type: 11 (.google.protobuf.Duration)
    # Field: user_time_duration Type: 11 (.google.protobuf.Duration)
    # Field: test_caching Type: 14 (.google.devtools.resultstore.v2.TestCaching)

# === Message: Google::Devtools::Resultstore::V2::Action::TestWarning ===
    # Fields for TestWarning
    # Field: warning_message Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::Action - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/action.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::Action;

    my $msg = Google::Devtools::Resultstore::V2::Action::Action->new({
        name => $name,
        id => $id,
        status_attributes => $status_attributes,
        timing => $timing,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::Action::Action->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/action.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::Action::Action

An action that happened as part of a configured target. This action could be
a build, a test, or another type of action, as specified in action_type
oneof.

Each parent ConfiguredTarget resource should have at least one Action as its
child resource before the invocation is finalized. For a simple build, at
least one build action should be created to represent the build result, and
at least one test action should be created to represent the test result, if
any.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name.  Its format must be:
invocations/${INVOCATION_ID}/targets/${url_encode(TARGET_ID)}/configuredTargets/url_encode(${CONFIG_ID})/actions/${url_encode(ACTION_ID)}

See CreateActionRequest proto for more information.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::Action::Id>)

The resource ID components that identify the Action. They must match the
resource name after proper encoding.

=item * C<< $msg->status_attributes() >> / C<< $msg->status_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::StatusAttributes>)

The status of the action.

=item * C<< $msg->timing() >> / C<< $msg->timing($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Timing>)

The timing of the whole action. For TestActions, the start time may be
before the test actually started, and the duration may last until after the
test actually finished.

=item * C<< $msg->build_action() >> / C<< $msg->build_action($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::BuildAction>)

Used only when this action represents a build action.

=item * C<< $msg->test_action() >> / C<< $msg->test_action($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::TestAction>)

Only for test actions.

=item * C<< $msg->action_attributes() >> / C<< $msg->action_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::ActionAttributes>)

General attributes of the action.

=item * C<< $msg->action_dependencies() >> / C<< $msg->action_dependencies($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Dependency>)

A list of resources that this action depended upon. May be used to provide
the cause of a build failure in the case of a failed build action.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Property>)

Arbitrary name-value pairs.
This is implemented as a multi-map. Multiple properties are allowed with
the same key. Properties will be returned in lexicographical order by key.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::File::File>)

A list of file references for action level files.
The file IDs must be unique within this list. Duplicate file IDs will
result in an error. Files will be returned in lexicographical order by ID.

Files with the following reserved file IDs cause specific post-processing
or have special handling. These files must be immediately available to
ResultStore for processing when the reference is uploaded.

For build actions:
stdout: The stdout of the action
stderr: The stderr of the action
baseline.lcov: Baseline coverage file to be parsed by the server. This
    uses a stripped down implementation of the LCOV standard.
    http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php

For test actions:
test.xml: The test suite / test case data in XML format.
test.log: The combined stdout and stderr of the test process.
test.lcov: Coverage file to be parsed by the server. This uses a stripped
    down implementation of the LCOV standard.
    http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php

=item * C<< $msg->file_sets() >> / C<< $msg->file_sets($value) >>

Type: C<String>

List of names of file sets that are referenced from this Action.
Each name must point to a file set under the same Invocation. The name
format must be: invocations/${INVOCATION_ID}/fileSets/${FILE_SET_ID}

=item * C<< $msg->coverage() >> / C<< $msg->coverage($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Coverage::ActionCoverage>)

Coverage data was collected while running the build or test action. This
usually includes line coverage, and may also include branch coverage.
For test actions, this is usually only for the source files which were
actually executed by that particular action.
For build actions, this is the baseline coverage, which captures the
instrumented files and lines, without any lines being executed. This
ensures files that are never covered at all are included.

=item * C<< $msg->file_processing_errors() >> / C<< $msg->file_processing_errors($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors>)

ResultStore will read and parse Files with reserved IDs listed above. Read
and parse errors for all these Files are reported here.
This is implemented as a map, with one FileProcessingErrors for each file.
Typically produced when parsing Files, but may also be provided directly
by clients.

=back

=head2 Google::Devtools::Resultstore::V2::Action::BuildAction

A build action, such as building a java library.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The type of the action.  This is intended to be a clue as to how the output
of the action should be parsed. For example "javac" for a Java compile
action.

=item * C<< $msg->primary_input_path() >> / C<< $msg->primary_input_path($value) >>

Type: C<String>

The "primary" input artifact processed by this action.  E.g., the .cc file
of a C++ compile action.  Empty string ("") if the action has no input
artifacts or no "primary" input artifact.

=item * C<< $msg->primary_output_path() >> / C<< $msg->primary_output_path($value) >>

Type: C<String>

The "primary" output artifact processed by this action.  E.g., the .o file
of a C++ compile action.  Empty string ("") if the action has no output
artifacts or no "primary" output artifact.

=back

=head2 Google::Devtools::Resultstore::V2::Action::TestAction

A test action, such as running a JUnit4 test binary.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->test_timing() >> / C<< $msg->test_timing($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::TestTiming>)

Timing data for execution of the test action.

=item * C<< $msg->shard_number() >> / C<< $msg->shard_number($value) >>

Type: C<Int32>

If the test is divided up into shards to improve performance, set this to
indicate which shard this test action is for. Value must be in interval
[0, total_shard_count). Defaults to 0, which is appropriate if all test
cases are run in the same process.

=item * C<< $msg->run_number() >> / C<< $msg->run_number($value) >>

Type: C<Int32>

If the user requested that every test be run multiple times, as is often
done to measure flakiness, set this to indicate which run this test action
is for. Value must be in interval [0, total_run_count). Defaults to 0,
which is appropriate if multiple runs were not requested.

=item * C<< $msg->attempt_number() >> / C<< $msg->attempt_number($value) >>

Type: C<Int32>

If flaky tests are automatically retried, set this to indicate which
attempt this test action is for. (e.g. 0 for the first attempt, 1 for
second, and so on). Defaults to 0, which is appropriate if this is the only
attempt.

=item * C<< $msg->test_suite() >> / C<< $msg->test_suite($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::TestSuite::TestSuite>)

A tree of test suites and test cases that were run by this test action.
Each test case has its own status information, including stack traces.
Typically produced by parsing an XML Log, but may also be provided directly
by clients.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::TestWarning>)

Warnings for this test action.

=item * C<< $msg->estimated_memory_bytes() >> / C<< $msg->estimated_memory_bytes($value) >>

Type: C<Int64>

Estimated memory consumption of the test action, in bytes. A default value
of 0 means there is no memory consumption estimate specified.

=back

=head2 Google::Devtools::Resultstore::V2::Action::ActionAttributes

General attributes of an action

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->execution_strategy() >> / C<< $msg->execution_strategy($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::ExecutionStrategy>)

Strategy used for executing the action.

=item * C<< $msg->exit_code() >> / C<< $msg->exit_code($value) >>

Type: C<Int32>

Exit code of the process that ran the action. A non-zero value means
failure.

=item * C<< $msg->hostname() >> / C<< $msg->hostname($value) >>

Type: C<String>

Where the action was run.

=item * C<< $msg->input_file_info() >> / C<< $msg->input_file_info($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::InputFileInfo>)

Information about the input files used in all actions under this configured
target.

=back

=head2 Google::Devtools::Resultstore::V2::Action::InputFileInfo

File count and size information for the input files to a configured target.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->count() >> / C<< $msg->count($value) >>

Type: C<Int64>

The number of input files (counting every file, even if a duplicate).

=item * C<< $msg->distinct_count() >> / C<< $msg->distinct_count($value) >>

Type: C<Int64>

The number of distinct input files.

=item * C<< $msg->count_limit() >> / C<< $msg->count_limit($value) >>

Type: C<Int64>

The max number of input files allowed by the build system (counting every
file, even if a duplicate).

=item * C<< $msg->distinct_bytes() >> / C<< $msg->distinct_bytes($value) >>

Type: C<Int64>

The total size of the distinct input files.

=item * C<< $msg->distinct_byte_limit() >> / C<< $msg->distinct_byte_limit($value) >>

Type: C<Int64>

The max allowed total size of the distinct input files.

=back

=head2 Google::Devtools::Resultstore::V2::Action::LocalTestTiming

Timing data for tests executed locally on the machine running the build.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->test_process_duration() >> / C<< $msg->test_process_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time taken by the test process, typically surrounded by a small wrapper
script.

=back

=head2 Google::Devtools::Resultstore::V2::Action::RemoteTestAttemptTiming

Timing data for one attempt to execute a test action remotely.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->queue_duration() >> / C<< $msg->queue_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Idle period before the test process is invoked on the remote machine.

=item * C<< $msg->upload_duration() >> / C<< $msg->upload_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time to upload data dependencies from the local machine to the remote
machine running the test, or to the distributed cache.

=item * C<< $msg->machine_setup_duration() >> / C<< $msg->machine_setup_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time to set up the remote machine.
Not to be confused with setup time in
xUnit test frameworks, which falls within the test_process_time.

=item * C<< $msg->test_process_duration() >> / C<< $msg->test_process_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time taken by the test process, typically surrounded by a small wrapper
script.
For Java tests, this includes JVM setup, flag parsing, class path setup,
parsing files to setup the suite, and finally running your test methods.
In many cases, only a small fraction of the test process time is spent
running the test methods.

=item * C<< $msg->download_duration() >> / C<< $msg->download_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time spent retrieving test logs and any other test outputs, back to the
local machine.

=back

=head2 Google::Devtools::Resultstore::V2::Action::RemoteTestTiming

Timing data for the part of the test execution that is done remotely.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->local_analysis_duration() >> / C<< $msg->local_analysis_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Time taken locally to determine what to do.

=item * C<< $msg->attempts() >> / C<< $msg->attempts($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::RemoteTestAttemptTiming>)

Normally there is only one attempt, but the system may retry on internal
errors, leading to multiple attempts.

=back

=head2 Google::Devtools::Resultstore::V2::Action::TestTiming

Timing data for execution of a test action. The action may be performed
locally, on the machine running the build, or remotely.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->local() >> / C<< $msg->local($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::LocalTestTiming>)

Used for local test actions.

=item * C<< $msg->remote() >> / C<< $msg->remote($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Action::RemoteTestTiming>)

Used for remote test actions.

=item * C<< $msg->system_time_duration() >> / C<< $msg->system_time_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The amount of CPU time spent by the test process executing system calls
within the kernel, as opposed to library code. Time the test process spent
blocked does not count towards this figure.

=item * C<< $msg->user_time_duration() >> / C<< $msg->user_time_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The amount of CPU time spent by the test process executing user-mode code
outside the kernel, as opposed to library code. Time the test process
spent blocked does not count towards this figure. You can add user_time to
system_time to get total CPU time taken by the test process.

=item * C<< $msg->test_caching() >> / C<< $msg->test_caching($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::TestCaching>)

Most build systems cache build results to speed up incremental builds.
Some also cache test results too. This indicates whether the test results
were found in a cache, and where that cache was located.

=back

=head2 Google::Devtools::Resultstore::V2::Action::TestWarning

A warning from a test execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->warning_message() >> / C<< $msg->warning_message($value) >>

Type: C<String>

Contains the message detailing the warning.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::Action::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
