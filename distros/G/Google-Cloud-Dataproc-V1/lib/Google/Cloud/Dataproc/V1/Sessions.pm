package Google::Cloud::Dataproc::V1::Sessions;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dataproc::V1::Shared };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvZGF0YXByb2MvdjEvc2Vzc2lvbnMucHJvdG8SGGdvb2dsZS5jbG91
ZC5kYXRhcHJvYy52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2Fw
aS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aJWdvb2dsZS9jbG91ZC9kYXRhcHJvYy92MS9zaGFyZWQu
cHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIuEBChRDcmVhdGVTZXNzaW9uUmVxdWVzdBI/CgZwYXJl
bnQYASABKAlCJ+BBAvpBIRIfZGF0YXByb2MuZ29vZ2xlYXBpcy5jb20vU2Vzc2lvblIGcGFy
ZW50EkAKB3Nlc3Npb24YAiABKAsyIS5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuU2Vzc2lv
bkID4EECUgdzZXNzaW9uEiIKCnNlc3Npb25faWQYAyABKAlCA+BBAlIJc2Vzc2lvbklkEiIK
CnJlcXVlc3RfaWQYBCABKAlCA+BBAVIJcmVxdWVzdElkIlAKEUdldFNlc3Npb25SZXF1ZXN0
EjsKBG5hbWUYASABKAlCJ+BBAvpBIQofZGF0YXByb2MuZ29vZ2xlYXBpcy5jb20vU2Vzc2lv
blIEbmFtZSK5AQoTTGlzdFNlc3Npb25zUmVxdWVzdBI/CgZwYXJlbnQYASABKAlCJ+BBAvpB
IRIfZGF0YXByb2MuZ29vZ2xlYXBpcy5jb20vU2Vzc2lvblIGcGFyZW50EiAKCXBhZ2Vfc2l6
ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VU
b2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyIoIBChRMaXN0U2Vzc2lvbnNSZXNw
b25zZRJCCghzZXNzaW9ucxgBIAMoCzIhLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5TZXNz
aW9uQgPgQQNSCHNlc3Npb25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiJ6ChdUZXJtaW5hdGVTZXNzaW9uUmVxdWVzdBI7CgRuYW1lGAEgASgJQifgQQL6QSEK
H2RhdGFwcm9jLmdvb2dsZWFwaXMuY29tL1Nlc3Npb25SBG5hbWUSIgoKcmVxdWVzdF9pZBgC
IAEoCUID4EEBUglyZXF1ZXN0SWQidwoURGVsZXRlU2Vzc2lvblJlcXVlc3QSOwoEbmFtZRgB
IAEoCUIn4EEC+kEhCh9kYXRhcHJvYy5nb29nbGVhcGlzLmNvbS9TZXNzaW9uUgRuYW1lEiIK
CnJlcXVlc3RfaWQYAiABKAlCA+BBAVIJcmVxdWVzdElkIpoMCgdTZXNzaW9uEhcKBG5hbWUY
ASABKAlCA+BBCFIEbmFtZRIXCgR1dWlkGAIgASgJQgPgQQNSBHV1aWQSQAoLY3JlYXRlX3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUS
VwoPanVweXRlcl9zZXNzaW9uGAQgASgLMicuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkp1
cHl0ZXJDb25maWdCA+BBAUgAUg5qdXB5dGVyU2Vzc2lvbhJnChVzcGFya19jb25uZWN0X3Nl
c3Npb24YESABKAsyLC5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuU3BhcmtDb25uZWN0Q29u
ZmlnQgPgQQFIAFITc3BhcmtDb25uZWN0U2Vzc2lvbhJNCgxydW50aW1lX2luZm8YBiABKAsy
JS5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuUnVudGltZUluZm9CA+BBA1ILcnVudGltZUlu
Zm8SQgoFc3RhdGUYByABKA4yJy5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuU2Vzc2lvbi5T
dGF0ZUID4EEDUgVzdGF0ZRIoCg1zdGF0ZV9tZXNzYWdlGAggASgJQgPgQQNSDHN0YXRlTWVz
c2FnZRI+CgpzdGF0ZV90aW1lGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUglzdGF0ZVRpbWUSHQoHY3JlYXRvchgKIAEoCUID4EEDUgdjcmVhdG9yEkoKBmxhYmVs
cxgLIAMoCzItLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5TZXNzaW9uLkxhYmVsc0VudHJ5
QgPgQQFSBmxhYmVscxJTCg5ydW50aW1lX2NvbmZpZxgMIAEoCzInLmdvb2dsZS5jbG91ZC5k
YXRhcHJvYy52MS5SdW50aW1lQ29uZmlnQgPgQQFSDXJ1bnRpbWVDb25maWcSXwoSZW52aXJv
bm1lbnRfY29uZmlnGA0gASgLMisuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkVudmlyb25t
ZW50Q29uZmlnQgPgQQFSEWVudmlyb25tZW50Q29uZmlnEhcKBHVzZXIYDiABKAlCA+BBAVIE
dXNlchJfCg1zdGF0ZV9oaXN0b3J5GA8gAygLMjUuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYx
LlNlc3Npb24uU2Vzc2lvblN0YXRlSGlzdG9yeUID4EEDUgxzdGF0ZUhpc3RvcnkSWgoQc2Vz
c2lvbl90ZW1wbGF0ZRgQIAEoCUIv4EEB+kEpCidkYXRhcHJvYy5nb29nbGVhcGlzLmNvbS9T
ZXNzaW9uVGVtcGxhdGVSD3Nlc3Npb25UZW1wbGF0ZRrOAQoTU2Vzc2lvblN0YXRlSGlzdG9y
eRJCCgVzdGF0ZRgBIAEoDjInLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5TZXNzaW9uLlN0
YXRlQgPgQQNSBXN0YXRlEigKDXN0YXRlX21lc3NhZ2UYAiABKAlCA+BBA1IMc3RhdGVNZXNz
YWdlEkkKEHN0YXRlX3N0YXJ0X3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSDnN0YXRlU3RhcnRUaW1lGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiZQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVD
SUZJRUQQABIMCghDUkVBVElORxABEgoKBkFDVElWRRACEg8KC1RFUk1JTkFUSU5HEAMSDgoK
VEVSTUlOQVRFRBAEEgoKBkZBSUxFRBAFOmDqQV0KH2RhdGFwcm9jLmdvb2dsZWFwaXMuY29t
L1Nlc3Npb24SOnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXNz
aW9ucy97c2Vzc2lvbn1CEAoOc2Vzc2lvbl9jb25maWcivQEKDUp1cHl0ZXJDb25maWcSSwoG
a2VybmVsGAEgASgOMi4uZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkp1cHl0ZXJDb25maWcu
S2VybmVsQgPgQQFSBmtlcm5lbBImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAVILZGlzcGxh
eU5hbWUiNwoGS2VybmVsEhYKEktFUk5FTF9VTlNQRUNJRklFRBAAEgoKBlBZVEhPThABEgkK
BVNDQUxBEAIiFAoSU3BhcmtDb25uZWN0Q29uZmlnMtMJChFTZXNzaW9uQ29udHJvbGxlchL5
AQoNQ3JlYXRlU2Vzc2lvbhIuLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5DcmVhdGVTZXNz
aW9uUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24imAGC0+STAjciLC92
MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3Nlc3Npb25zOgdzZXNzaW9u2kEZ
cGFyZW50LHNlc3Npb24sc2Vzc2lvbl9pZMpBPAoHU2Vzc2lvbhIxZ29vZ2xlLmNsb3VkLmRh
dGFwcm9jLnYxLlNlc3Npb25PcGVyYXRpb25NZXRhZGF0YRKZAQoKR2V0U2Vzc2lvbhIrLmdv
b2dsZS5jbG91ZC5kYXRhcHJvYy52MS5HZXRTZXNzaW9uUmVxdWVzdBohLmdvb2dsZS5jbG91
ZC5kYXRhcHJvYy52MS5TZXNzaW9uIjuC0+STAi4SLC92MS97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL3Nlc3Npb25zLyp92kEEbmFtZRKsAQoMTGlzdFNlc3Npb25zEi0uZ29vZ2xl
LmNsb3VkLmRhdGFwcm9jLnYxLkxpc3RTZXNzaW9uc1JlcXVlc3QaLi5nb29nbGUuY2xvdWQu
ZGF0YXByb2MudjEuTGlzdFNlc3Npb25zUmVzcG9uc2UiPYLT5JMCLhIsL3YxL3twYXJlbnQ9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vc2Vzc2lvbnPaQQZwYXJlbnQS7gEKEFRlcm1pbmF0
ZVNlc3Npb24SMS5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuVGVybWluYXRlU2Vzc2lvblJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIocBgtPkkwI7IjYvdjEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zZXNzaW9ucy8qfTp0ZXJtaW5hdGU6ASraQQRu
YW1lykE8CgdTZXNzaW9uEjFnb29nbGUuY2xvdWQuZGF0YXByb2MudjEuU2Vzc2lvbk9wZXJh
dGlvbk1ldGFkYXRhEtoBCg1EZWxldGVTZXNzaW9uEi4uZ29vZ2xlLmNsb3VkLmRhdGFwcm9j
LnYxLkRlbGV0ZVNlc3Npb25SZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
biJ6gtPkkwIuKiwvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9zZXNzaW9ucy8q
fdpBBG5hbWXKQTwKB1Nlc3Npb24SMWdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5TZXNzaW9u
T3BlcmF0aW9uTWV0YWRhdGEaqAHKQRdkYXRhcHJvYy5nb29nbGVhcGlzLmNvbdJBigFodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGF0YXByb2MsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5j
b20vYXV0aC9kYXRhcHJvYy5yZWFkLW9ubHlCbAocY29tLmdvb2dsZS5jbG91ZC5kYXRhcHJv
Yy52MUINU2Vzc2lvbnNQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2RhdGFwcm9jL3Yy
L2FwaXYxL2RhdGFwcm9jcGI7ZGF0YXByb2NwYkqOYgoHEgUOAPwCHQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAC8KCQoCAwUSAxcALQoJCgIDBhIDGAAp
CggKAQgSAxoAUgoJCgIICxIDGgBSCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwALgoJ
CgIICBIDHAAuCggKAQgSAx0ANQoJCgIIARIDHQA1ClYKAgYAEgQgAGABGkogVGhlIGBTZXNz
aW9uQ29udHJvbGxlcmAgcHJvdmlkZXMgbWV0aG9kcyB0byBtYW5hZ2UgaW50ZXJhY3RpdmUg
c2Vzc2lvbnMuCgoKCgMGAAESAyAIGQoKCgMGAAMSAyECPwoMCgUGAAOZCBIDIQI/CgsKAwYA
AxIEIgIlOwoNCgUGAAOaCBIEIgIlOwo9CgQGAAIAEgQoAjMDGi8gQ3JlYXRlIGFuIGludGVy
YWN0aXZlIHNlc3Npb24gYXN5bmNocm9ub3VzbHkuCgoMCgUGAAIAARIDKAYTCgwKBQYAAgAC
EgMoFCgKDAoFBgACAAMSAykPKwoNCgUGAAIABBIEKgQtBgoRCgkGAAIABLDKvCISBCoELQYK
DAoFBgACAAQSAy4ERwoPCggGAAIABJsIABIDLgRHCg0KBQYAAgAEEgQvBDIGCg8KBwYAAgAE
mQgSBC8EMgYKTAoEBgACARIENgI7Axo+IEdldHMgdGhlIHJlc291cmNlIHJlcHJlc2VudGF0
aW9uIGZvciBhbiBpbnRlcmFjdGl2ZSBzZXNzaW9uLgoKDAoFBgACAQESAzYGEAoMCgUGAAIB
AhIDNhEiCgwKBQYAAgEDEgM2LTQKDQoFBgACAQQSBDcEOQYKEQoJBgACAQSwyrwiEgQ3BDkG
CgwKBQYAAgEEEgM6BDIKDwoIBgACAQSbCAASAzoEMgorCgQGAAICEgQ+AkMDGh0gTGlzdHMg
aW50ZXJhY3RpdmUgc2Vzc2lvbnMuCgoMCgUGAAICARIDPgYSCgwKBQYAAgICEgM+EyYKDAoF
BgACAgMSAz4xRQoNCgUGAAICBBIEPwRBBgoRCgkGAAICBLDKvCISBD8EQQYKDAoFBgACAgQS
A0IENAoPCggGAAICBJsIABIDQgQ0CjMKBAYAAgMSBEYCUQMaJSBUZXJtaW5hdGVzIHRoZSBp
bnRlcmFjdGl2ZSBzZXNzaW9uLgoKDAoFBgACAwESA0YGFgoMCgUGAAIDAhIDRhcuCgwKBQYA
AgMDEgNHDysKDQoFBgACAwQSBEgESwYKEQoJBgACAwSwyrwiEgRIBEsGCgwKBQYAAgMEEgNM
BDIKDwoIBgACAwSbCAASA0wEMgoNCgUGAAIDBBIETQRQBgoPCgcGAAIDBJkIEgRNBFAGCocB
CgQGAAIEEgRVAl8DGnkgRGVsZXRlcyB0aGUgaW50ZXJhY3RpdmUgc2Vzc2lvbiByZXNvdXJj
ZS4gSWYgdGhlIHNlc3Npb24gaXMgbm90IGluIHRlcm1pbmFsCiBzdGF0ZSwgaXQgaXMgdGVy
bWluYXRlZCwgYW5kIHRoZW4gZGVsZXRlZC4KCgwKBQYAAgQBEgNVBhMKDAoFBgACBAISA1UU
KAoMCgUGAAIEAxIDVg8rCg0KBQYAAgQEEgRXBFkGChEKCQYAAgQEsMq8IhIEVwRZBgoMCgUG
AAIEBBIDWgQyCg8KCAYAAgQEmwgAEgNaBDIKDQoFBgACBAQSBFsEXgYKDwoHBgACBASZCBIE
WwReBgotCgIEABIFYwCDAQEaICBBIHJlcXVlc3QgdG8gY3JlYXRlIGEgc2Vzc2lvbi4KCgoK
AwQAARIDYwgcClEKBAQAAgASBGUCagQaQyBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJj
ZSB3aGVyZSB0aGlzIHNlc3Npb24gd2lsbCBiZSBjcmVhdGVkLgoKDAoFBAACAAUSA2UCCAoM
CgUEAAIAARIDZQkPCgwKBQQAAgADEgNlEhMKDQoFBAACAAgSBGUUagMKDwoIBAACAAicCAAS
A2YEKgoPCgcEAAIACJ8IEgRnBGkFCjsKBAQAAgESA20CPxouIFJlcXVpcmVkLiBUaGUgaW50
ZXJhY3RpdmUgc2Vzc2lvbiB0byBjcmVhdGUuCgoMCgUEAAIBBhIDbQIJCgwKBQQAAgEBEgNt
ChEKDAoFBAACAQMSA20UFQoMCgUEAAIBCBIDbRY+Cg8KCAQAAgEInAgAEgNtFz0KxgEKBAQA
AgISA3QCQRq4ASBSZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIHNlc3Npb24sIHdo
aWNoIGJlY29tZXMgdGhlIGZpbmFsIGNvbXBvbmVudAogb2YgdGhlIHNlc3Npb24ncyByZXNv
dXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgbXVzdCBiZSA0LTYzIGNoYXJhY3RlcnMuIFZhbGlk
IGNoYXJhY3RlcnMKIGFyZSAvW2Etel1bMC05XS0vLgoKDAoFBAACAgUSA3QCCAoMCgUEAAIC
ARIDdAkTCgwKBQQAAgIDEgN0FhcKDAoFBAACAggSA3QYQAoPCggEAAICCJwIABIDdBk/CoEF
CgQEAAIDEgSCAQJBGvIEIE9wdGlvbmFsLiBBIHVuaXF1ZSBJRCB1c2VkIHRvIGlkZW50aWZ5
IHRoZSByZXF1ZXN0LiBJZiB0aGUgc2VydmljZQogcmVjZWl2ZXMgdHdvCiBbQ3JlYXRlU2Vz
c2lvblJlcXVlc3RzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGF0YXByb2MvZG9jcy9y
ZWZlcmVuY2UvcnBjL2dvb2dsZS5jbG91ZC5kYXRhcHJvYy52MSNnb29nbGUuY2xvdWQuZGF0
YXByb2MudjEuQ3JlYXRlU2Vzc2lvblJlcXVlc3Qpcwogd2l0aCB0aGUgc2FtZSBJRCwgdGhl
IHNlY29uZCByZXF1ZXN0IGlzIGlnbm9yZWQsIGFuZCB0aGUKIGZpcnN0IFtTZXNzaW9uXVtn
b29nbGUuY2xvdWQuZGF0YXByb2MudjEuU2Vzc2lvbl0gaXMgY3JlYXRlZCBhbmQgc3RvcmVk
IGluCiB0aGUgYmFja2VuZC4KCiBSZWNvbW1lbmRhdGlvbjogU2V0IHRoaXMgdmFsdWUgdG8g
YQogW1VVSURdKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL1VuaXZlcnNhbGx5X3Vu
aXF1ZV9pZGVudGlmaWVyKS4KCiBUaGUgdmFsdWUgbXVzdCBjb250YWluIG9ubHkgbGV0dGVy
cyAoYS16LCBBLVopLCBudW1iZXJzICgwLTkpLAogdW5kZXJzY29yZXMgKF8pLCBhbmQgaHlw
aGVucyAoLSkuIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyA0MCBjaGFyYWN0ZXJzLgoKDQoFBAAC
AwUSBIIBAggKDQoFBAACAwESBIIBCRMKDQoFBAACAwMSBIIBFhcKDQoFBAACAwgSBIIBGEAK
EAoIBAACAwicCAASBIIBGT8KSwoCBAESBoYBAI4BARo9IEEgcmVxdWVzdCB0byBnZXQgdGhl
IHJlc291cmNlIHJlcHJlc2VudGF0aW9uIGZvciBhIHNlc3Npb24uCgoLCgMEAQESBIYBCBkK
QAoEBAECABIGiAECjQEEGjAgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzZXNzaW9uIHRv
IHJldHJpZXZlLgoKDQoFBAECAAUSBIgBAggKDQoFBAECAAESBIgBCQ0KDQoFBAECAAMSBIgB
EBEKDwoFBAECAAgSBogBEo0BAwoQCggEAQIACJwIABIEiQEEKgoRCgcEAQIACJ8IEgaKAQSM
AQUKOAoCBAISBpEBALIBARoqIEEgcmVxdWVzdCB0byBsaXN0IHNlc3Npb25zIGluIGEgcHJv
amVjdC4KCgsKAwQCARIEkQEIGwpPCgQEAgIAEgaTAQKYAQQaPyBSZXF1aXJlZC4gVGhlIHBh
cmVudCwgd2hpY2ggb3ducyB0aGlzIGNvbGxlY3Rpb24gb2Ygc2Vzc2lvbnMuCgoNCgUEAgIA
BRIEkwECCAoNCgUEAgIAARIEkwEJDwoNCgUEAgIAAxIEkwESEwoPCgUEAgIACBIGkwEUmAED
ChAKCAQCAgAInAgAEgSUAQQqChEKBwQCAgAInwgSBpUBBJcBBQqDAQoEBAICARIEnAECPxp1
IE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2Ygc2Vzc2lvbnMgdG8gcmV0dXJuIGlu
IGVhY2ggcmVzcG9uc2UuCiBUaGUgc2VydmljZSBtYXkgcmV0dXJuIGZld2VyIHRoYW4gdGhp
cyB2YWx1ZS4KCg0KBQQCAgEFEgScAQIHCg0KBQQCAgEBEgScAQgRCg0KBQQCAgEDEgScARQV
Cg0KBQQCAgEIEgScARY+ChAKCAQCAgEInAgAEgScARc9CokBCgQEAgICEgSgAQJBGnsgT3B0
aW9uYWwuIEEgcGFnZSB0b2tlbiByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RTZXNz
aW9uc2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0b2tlbiB0byByZXRyaWV2ZSB0aGUgc3Vic2Vx
dWVudCBwYWdlLgoKDQoFBAICAgUSBKABAggKDQoFBAICAgESBKABCRMKDQoFBAICAgMSBKAB
FhcKDQoFBAICAggSBKABGEAKEAoIBAICAgicCAASBKABGT8KrwYKBAQCAgMSBLEBAj0aoAYg
T3B0aW9uYWwuIEEgZmlsdGVyIGZvciB0aGUgc2Vzc2lvbnMgdG8gcmV0dXJuIGluIHRoZSBy
ZXNwb25zZS4KCiBBIGZpbHRlciBpcyBhIGxvZ2ljYWwgZXhwcmVzc2lvbiBjb25zdHJhaW5p
bmcgdGhlIHZhbHVlcyBvZiB2YXJpb3VzIGZpZWxkcwogaW4gZWFjaCBzZXNzaW9uIHJlc291
cmNlLiBGaWx0ZXJzIGFyZSBjYXNlIHNlbnNpdGl2ZSwgYW5kIG1heSBjb250YWluCiBtdWx0
aXBsZSBjbGF1c2VzIGNvbWJpbmVkIHdpdGggbG9naWNhbCBvcGVyYXRvcnMgKEFORCwgT1Ip
LgogU3VwcG9ydGVkIGZpZWxkcyBhcmUgYHNlc3Npb25faWRgLCBgc2Vzc2lvbl91dWlkYCwg
YHN0YXRlYCwgYGNyZWF0ZV90aW1lYCwKIGFuZCBgbGFiZWxzYC4KCiBFeGFtcGxlOiBgc3Rh
dGUgPSBBQ1RJVkUgYW5kIGNyZWF0ZV90aW1lIDwgIjIwMjMtMDEtMDFUMDA6MDA6MDBaImAK
IGlzIGEgZmlsdGVyIGZvciBzZXNzaW9ucyBpbiBhbiBBQ1RJVkUgc3RhdGUgdGhhdCB3ZXJl
IGNyZWF0ZWQgYmVmb3JlCiAyMDIzLTAxLTAxLiBgc3RhdGUgPSBBQ1RJVkUgYW5kIGxhYmVs
cy5lbnZpcm9ubWVudD1wcm9kdWN0aW9uYCBpcyBhIGZpbHRlcgogZm9yIHNlc3Npb25zIGlu
IGFuIEFDVElWRSBzdGF0ZSB0aGF0IGhhdmUgYSBwcm9kdWN0aW9uIGVudmlyb25tZW50IGxh
YmVsLgoKIFNlZSBodHRwczovL2dvb2dsZS5haXAuZGV2L2Fzc2V0cy9taXNjL2VibmYtZmls
dGVyaW5nLnR4dCBmb3IgYSBkZXRhaWxlZAogZGVzY3JpcHRpb24gb2YgdGhlIGZpbHRlciBz
eW50YXggYW5kIGEgbGlzdCBvZiBzdXBwb3J0ZWQgY29tcGFyYXRvcnMuCgoNCgUEAgIDBRIE
sQECCAoNCgUEAgIDARIEsQEJDwoNCgUEAgIDAxIEsQESEwoNCgUEAgIDCBIEsQEUPAoQCggE
AgIDCJwIABIEsQEVOwovCgIEAxIGtQEAvAEBGiEgQSBsaXN0IG9mIGludGVyYWN0aXZlIHNl
c3Npb25zLgoKCwoDBAMBEgS1AQgcCkgKBAQDAgASBLcBAkwaOiBPdXRwdXQgb25seS4gVGhl
IHNlc3Npb25zIGZyb20gdGhlIHNwZWNpZmllZCBjb2xsZWN0aW9uLgoKDQoFBAMCAAQSBLcB
AgoKDQoFBAMCAAYSBLcBCxIKDQoFBAMCAAESBLcBExsKDQoFBAMCAAMSBLcBHh8KDQoFBAMC
AAgSBLcBIEsKEAoIBAMCAAicCAASBLcBIUoKkQEKBAQDAgESBLsBAh0aggEgQSB0b2tlbiwg
d2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gLCB0byByZXRyaWV2ZSB0aGUgbmV4
dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2Vx
dWVudCBwYWdlcy4KCg0KBQQDAgEFEgS7AQIICg0KBQQDAgEBEgS7AQkYCg0KBQQDAgEDEgS7
ARscCj4KAgQEEga/AQDTAQEaMCBBIHJlcXVlc3QgdG8gdGVybWluYXRlIGFuIGludGVyYWN0
aXZlIHNlc3Npb24uCgoLCgMEBAESBL8BCB8KSgoEBAQCABIGwQECxgEEGjogUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBzZXNzaW9uIHJlc291cmNlIHRvIHRlcm1pbmF0ZS4KCg0KBQQE
AgAFEgTBAQIICg0KBQQEAgABEgTBAQkNCg0KBQQEAgADEgTBARARCg8KBQQEAgAIEgbBARLG
AQMKEAoIBAQCAAicCAASBMIBBCoKEQoHBAQCAAifCBIGwwEExQEFCqQECgQEBAIBEgTSAQJB
GpUEIE9wdGlvbmFsLiBBIHVuaXF1ZSBJRCB1c2VkIHRvIGlkZW50aWZ5IHRoZSByZXF1ZXN0
LiBJZiB0aGUgc2VydmljZQogcmVjZWl2ZXMgdHdvCiBbVGVybWluYXRlU2Vzc2lvblJlcXVl
c3RdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kYXRhcHJvYy9kb2NzL3JlZmVyZW5jZS9y
cGMvZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxI2dvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5U
ZXJtaW5hdGVTZXNzaW9uUmVxdWVzdClzCiB3aXRoIHRoZSBzYW1lIElELCB0aGUgc2Vjb25k
IHJlcXVlc3QgaXMgaWdub3JlZC4KCiBSZWNvbW1lbmRhdGlvbjogU2V0IHRoaXMgdmFsdWUg
dG8gYQogW1VVSURdKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL1VuaXZlcnNhbGx5
X3VuaXF1ZV9pZGVudGlmaWVyKS4KCiBUaGUgdmFsdWUgbXVzdCBjb250YWluIG9ubHkgbGV0
dGVycyAoYS16LCBBLVopLCBudW1iZXJzICgwLTkpLAogdW5kZXJzY29yZXMgKF8pLCBhbmQg
aHlwaGVucyAoLSkuIFRoZSBtYXhpbXVtIGxlbmd0aCBpcyA0MCBjaGFyYWN0ZXJzLgoKDQoF
BAQCAQUSBNIBAggKDQoFBAQCAQESBNIBCRMKDQoFBAQCAQMSBNIBFhcKDQoFBAQCAQgSBNIB
GEAKEAoIBAQCAQicCAASBNIBGT8KLgoCBAUSBtYBAOoBARogIEEgcmVxdWVzdCB0byBkZWxl
dGUgYSBzZXNzaW9uLgoKCwoDBAUBEgTWAQgcCkcKBAQFAgASBtgBAt0BBBo3IFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgc2Vzc2lvbiByZXNvdXJjZSB0byBkZWxldGUuCgoNCgUEBQIA
BRIE2AECCAoNCgUEBQIAARIE2AEJDQoNCgUEBQIAAxIE2AEQEQoPCgUEBQIACBIG2AES3QED
ChAKCAQFAgAInAgAEgTZAQQqChEKBwQFAgAInwgSBtoBBNwBBQqeBAoEBAUCARIE6QECQRqP
BCBPcHRpb25hbC4gQSB1bmlxdWUgSUQgdXNlZCB0byBpZGVudGlmeSB0aGUgcmVxdWVzdC4g
SWYgdGhlIHNlcnZpY2UKIHJlY2VpdmVzIHR3bwogW0RlbGV0ZVNlc3Npb25SZXF1ZXN0XSho
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGF0YXByb2MvZG9jcy9yZWZlcmVuY2UvcnBjL2dv
b2dsZS5jbG91ZC5kYXRhcHJvYy52MSNnb29nbGUuY2xvdWQuZGF0YXByb2MudjEuRGVsZXRl
U2Vzc2lvblJlcXVlc3Qpcwogd2l0aCB0aGUgc2FtZSBJRCwgdGhlIHNlY29uZCByZXF1ZXN0
IGlzIGlnbm9yZWQuCgogUmVjb21tZW5kYXRpb246IFNldCB0aGlzIHZhbHVlIHRvIGEKIFtV
VUlEXShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9Vbml2ZXJzYWxseV91bmlxdWVf
aWRlbnRpZmllcikuCgogVGhlIHZhbHVlIG11c3QgY29udGFpbiBvbmx5IGxldHRlcnMgKGEt
eiwgQS1aKSwgbnVtYmVycyAoMC05KSwKIHVuZGVyc2NvcmVzIChfKSwgYW5kIGh5cGhlbnMg
KC0pLiBUaGUgbWF4aW11bSBsZW5ndGggaXMgNDAgY2hhcmFjdGVycy4KCg0KBQQFAgEFEgTp
AQIICg0KBQQFAgEBEgTpAQkTCg0KBQQFAgEDEgTpARYXCg0KBQQFAgEIEgTpARhAChAKCAQF
AgEInAgAEgTpARk/Ci4KAgQGEgbtAQDkAgEaICBBIHJlcHJlc2VudGF0aW9uIG9mIGEgc2Vz
c2lvbi4KCgsKAwQGARIE7QEIDwoNCgMEBgcSBu4BAvEBBAoPCgUEBgedCBIG7gEC8QEECiQK
BAQGBAASBvQBAoYCAxoUIFRoZSBzZXNzaW9uIHN0YXRlLgoKDQoFBAYEAAESBPQBBwwKLwoG
BAYEAAIAEgT2AQQaGh8gVGhlIHNlc3Npb24gc3RhdGUgaXMgdW5rbm93bi4KCg8KBwQGBAAC
AAESBPYBBBUKDwoHBAYEAAIAAhIE9gEYGQo6CgYEBgQAAgESBPkBBBEaKiBUaGUgc2Vzc2lv
biBpcyBjcmVhdGVkIHByaW9yIHRvIHJ1bm5pbmcuCgoPCgcEBgQAAgEBEgT5AQQMCg8KBwQG
BAACAQISBPkBDxAKKQoGBAYEAAICEgT8AQQPGhkgVGhlIHNlc3Npb24gaXMgcnVubmluZy4K
Cg8KBwQGBAACAgESBPwBBAoKDwoHBAYEAAICAhIE/AENDgotCgYEBgQAAgMSBP8BBBQaHSBU
aGUgc2Vzc2lvbiBpcyB0ZXJtaW5hdGluZy4KCg8KBwQGBAACAwESBP8BBA8KDwoHBAYEAAID
AhIE/wESEwo5CgYEBgQAAgQSBIICBBMaKSBUaGUgc2Vzc2lvbiBpcyB0ZXJtaW5hdGVkIHN1
Y2Nlc3NmdWxseS4KCg8KBwQGBAACBAESBIICBA4KDwoHBAYEAAIEAhIEggIREgpDCgYEBgQA
AgUSBIUCBA8aMyBUaGUgc2Vzc2lvbiBpcyBubyBsb25nZXIgcnVubmluZyBkdWUgdG8gYW4g
ZXJyb3IuCgoPCgcEBgQAAgUBEgSFAgQKCg8KBwQGBAACBQISBIUCDQ4KLwoEBAYDABIGiQIC
lQIDGh8gSGlzdG9yaWNhbCBzdGF0ZSBpbmZvcm1hdGlvbi4KCg0KBQQGAwABEgSJAgodCl4K
BgQGAwACABIEjAIEQBpOIE91dHB1dCBvbmx5LiBUaGUgc3RhdGUgb2YgdGhlIHNlc3Npb24g
YXQgdGhpcyBwb2ludCBpbiB0aGUgc2Vzc2lvbgogaGlzdG9yeS4KCg8KBwQGAwACAAYSBIwC
BAkKDwoHBAYDAAIAARIEjAIKDwoPCgcEBgMAAgADEgSMAhITCg8KBwQGAwACAAgSBIwCFD8K
EgoKBAYDAAIACJwIABIEjAIVPgpdCgYEBgMAAgESBJACBEkaTSBPdXRwdXQgb25seS4gRGV0
YWlscyBhYm91dCB0aGUgc3RhdGUgYXQgdGhpcyBwb2ludCBpbiB0aGUgc2Vzc2lvbgogaGlz
dG9yeS4KCg8KBwQGAwACAQUSBJACBAoKDwoHBAYDAAIBARIEkAILGAoPCgcEBgMAAgEDEgSQ
AhscCg8KBwQGAwACAQgSBJACHUgKEgoKBAYDAAIBCJwIABIEkAIeRwpYCgYEBgMAAgISBpMC
BJQCNBpGIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBzZXNzaW9uIGVudGVyZWQg
dGhlIGhpc3RvcmljYWwgc3RhdGUuCgoPCgcEBgMAAgIGEgSTAgQdCg8KBwQGAwACAgESBJMC
Hi4KDwoHBAYDAAICAxIEkwIxMgoPCgcEBgMAAgIIEgSUAggzChIKCgQGAwACAgicCAASBJQC
CTIKPQoEBAYCABIEmAICPRovIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRo
ZSBzZXNzaW9uLgoKDQoFBAYCAAUSBJgCAggKDQoFBAYCAAESBJgCCQ0KDQoFBAYCAAMSBJgC
EBEKDQoFBAYCAAgSBJgCEjwKEAoIBAYCAAicCAASBJgCEzsKiQEKBAQGAgESBJwCAj4aeyBP
dXRwdXQgb25seS4gQSBzZXNzaW9uIFVVSUQgKFVuaXF1ZSBVbml2ZXJzYWwgSWRlbnRpZmll
cikuIFRoZSBzZXJ2aWNlCiBnZW5lcmF0ZXMgdGhpcyB2YWx1ZSB3aGVuIGl0IGNyZWF0ZXMg
dGhlIHNlc3Npb24uCgoNCgUEBgIBBRIEnAICCAoNCgUEBgIBARIEnAIJDQoNCgUEBgIBAxIE
nAIQEQoNCgUEBgIBCBIEnAISPQoQCggEBgIBCJwIABIEnAITPApFCgQEBgICEgafAgKgAjIa
NSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgc2Vzc2lvbiB3YXMgY3JlYXRlZC4K
Cg0KBQQGAgIGEgSfAgIbCg0KBQQGAgIBEgSfAhwnCg0KBQQGAgIDEgSfAiorCg0KBQQGAgII
EgSgAgYxChAKCAQGAgIInAgAEgSgAgcwCiwKBAQGCAASBqMCAqoCAxocIFRoZSBzZXNzaW9u
IGNvbmZpZ3VyYXRpb24uCgoNCgUEBggAARIEowIIFgoxCgQEBgIDEgSlAgRPGiMgT3B0aW9u
YWwuIEp1cHl0ZXIgc2Vzc2lvbiBjb25maWcuCgoNCgUEBgIDBhIEpQIEEQoNCgUEBgIDARIE
pQISIQoNCgUEBgIDAxIEpQIkJQoNCgUEBgIDCBIEpQImTgoQCggEBgIDCJwIABIEpQInTQo5
CgQEBgIEEgaoAgSpAjEaKSBPcHRpb25hbC4gU3BhcmsgY29ubmVjdCBzZXNzaW9uIGNvbmZp
Zy4KCg0KBQQGAgQGEgSoAgQWCg0KBQQGAgQBEgSoAhcsCg0KBQQGAgQDEgSoAi8xCg0KBQQG
AgQIEgSpAggwChAKCAQGAgQInAgAEgSpAgkvCkkKBAQGAgUSBK0CAksaOyBPdXRwdXQgb25s
eS4gUnVudGltZSBpbmZvcm1hdGlvbiBhYm91dCBzZXNzaW9uIGV4ZWN1dGlvbi4KCg0KBQQG
AgUGEgStAgINCg0KBQQGAgUBEgStAg4aCg0KBQQGAgUDEgStAh0eCg0KBQQGAgUIEgStAh9K
ChAKCAQGAgUInAgAEgStAiBJCjQKBAQGAgYSBLACAj4aJiBPdXRwdXQgb25seS4gQSBzdGF0
ZSBvZiB0aGUgc2Vzc2lvbi4KCg0KBQQGAgYGEgSwAgIHCg0KBQQGAgYBEgSwAggNCg0KBQQG
AgYDEgSwAhARCg0KBQQGAgYIEgSwAhI9ChAKCAQGAgYInAgAEgSwAhM8Cm4KBAQGAgcSBLQC
AkcaYCBPdXRwdXQgb25seS4gU2Vzc2lvbiBzdGF0ZSBkZXRhaWxzLCBzdWNoIGFzIHRoZSBm
YWlsdXJlCiBkZXNjcmlwdGlvbiBpZiB0aGUgc3RhdGUgaXMgYEZBSUxFRGAuCgoNCgUEBgIH
BRIEtAICCAoNCgUEBgIHARIEtAIJFgoNCgUEBgIHAxIEtAIZGgoNCgUEBgIHCBIEtAIbRgoQ
CggEBgIHCJwIABIEtAIcRQpTCgQEBgIIEga3AgK4AjIaQyBPdXRwdXQgb25seS4gVGhlIHRp
bWUgd2hlbiB0aGUgc2Vzc2lvbiBlbnRlcmVkIHRoZSBjdXJyZW50IHN0YXRlLgoKDQoFBAYC
CAYSBLcCAhsKDQoFBAYCCAESBLcCHCYKDQoFBAYCCAMSBLcCKSoKDQoFBAYCCAgSBLgCBjEK
EAoIBAYCCAicCAASBLgCBzAKUwoEBAYCCRIEuwICQhpFIE91dHB1dCBvbmx5LiBUaGUgZW1h
aWwgYWRkcmVzcyBvZiB0aGUgdXNlciB3aG8gY3JlYXRlZCB0aGUgc2Vzc2lvbi4KCg0KBQQG
AgkFEgS7AgIICg0KBQQGAgkBEgS7AgkQCg0KBQQGAgkDEgS7AhMVCg0KBQQGAgkIEgS7AhZB
ChAKCAQGAgkInAgAEgS7AhdACpADCgQEBgIKEgTEAgJLGoEDIE9wdGlvbmFsLiBUaGUgbGFi
ZWxzIHRvIGFzc29jaWF0ZSB3aXRoIHRoZSBzZXNzaW9uLgogTGFiZWwgKiprZXlzKiogbXVz
dCBjb250YWluIDEgdG8gNjMgY2hhcmFjdGVycywgYW5kIG11c3QgY29uZm9ybSB0bwogW1JG
QyAxMDM1XShodHRwczovL3d3dy5pZXRmLm9yZy9yZmMvcmZjMTAzNS50eHQpLgogTGFiZWwg
Kip2YWx1ZXMqKiBtYXkgYmUgZW1wdHksIGJ1dCwgaWYgcHJlc2VudCwgbXVzdCBjb250YWlu
IDEgdG8gNjMKIGNoYXJhY3RlcnMsIGFuZCBtdXN0IGNvbmZvcm0gdG8gW1JGQwogMTAzNV0o
aHR0cHM6Ly93d3cuaWV0Zi5vcmcvcmZjL3JmYzEwMzUudHh0KS4gTm8gbW9yZSB0aGFuIDMy
IGxhYmVscyBjYW4gYmUKIGFzc29jaWF0ZWQgd2l0aCBhIHNlc3Npb24uCgoNCgUEBgIKBhIE
xAICFQoNCgUEBgIKARIExAIWHAoNCgUEBgIKAxIExAIfIQoNCgUEBgIKCBIExAIiSgoQCggE
BgIKCJwIABIExAIjSQpKCgQEBgILEgTHAgJNGjwgT3B0aW9uYWwuIFJ1bnRpbWUgY29uZmln
dXJhdGlvbiBmb3IgdGhlIHNlc3Npb24gZXhlY3V0aW9uLgoKDQoFBAYCCwYSBMcCAg8KDQoF
BAYCCwESBMcCEB4KDQoFBAYCCwMSBMcCISMKDQoFBAYCCwgSBMcCJEwKEAoIBAYCCwicCAAS
BMcCJUsKUAoEBAYCDBIGygICywIvGkAgT3B0aW9uYWwuIEVudmlyb25tZW50IGNvbmZpZ3Vy
YXRpb24gZm9yIHRoZSBzZXNzaW9uIGV4ZWN1dGlvbi4KCg0KBQQGAgwGEgTKAgITCg0KBQQG
AgwBEgTKAhQmCg0KBQQGAgwDEgTKAikrCg0KBQQGAgwIEgTLAgYuChAKCAQGAgwInAgAEgTL
AgctCk0KBAQGAg0SBM4CAjwaPyBPcHRpb25hbC4gVGhlIGVtYWlsIGFkZHJlc3Mgb2YgdGhl
IHVzZXIgd2hvIG93bnMgdGhlIHNlc3Npb24uCgoNCgUEBgINBRIEzgICCAoNCgUEBgINARIE
zgIJDQoNCgUEBgINAxIEzgIQEgoNCgUEBgINCBIEzgITOwoQCggEBgINCJwIABIEzgIUOgpM
CgQEBgIOEgbRAgLSAjIaPCBPdXRwdXQgb25seS4gSGlzdG9yaWNhbCBzdGF0ZSBpbmZvcm1h
dGlvbiBmb3IgdGhlIHNlc3Npb24uCgoNCgUEBgIOBBIE0QICCgoNCgUEBgIOBhIE0QILHgoN
CgUEBgIOARIE0QIfLAoNCgUEBgIOAxIE0QIvMQoNCgUEBgIOCBIE0gIGMQoQCggEBgIOCJwI
ABIE0gIHMAq4AwoEBAYCDxIG3gIC4wIEGqcDIE9wdGlvbmFsLiBUaGUgc2Vzc2lvbiB0ZW1w
bGF0ZSB1c2VkIGJ5IHRoZSBzZXNzaW9uLgoKIE9ubHkgcmVzb3VyY2UgbmFtZXMsIGluY2x1
ZGluZyBwcm9qZWN0IElEIGFuZCBsb2NhdGlvbiwgYXJlIHZhbGlkLgoKIEV4YW1wbGU6CiAq
IGBodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9jb21wdXRlL3YxL3Byb2plY3RzL1twcm9q
ZWN0X2lkXS9sb2NhdGlvbnMvW2RhdGFwcm9jX3JlZ2lvbl0vc2Vzc2lvblRlbXBsYXRlcy9b
dGVtcGxhdGVfaWRdYAogKiBgcHJvamVjdHMvW3Byb2plY3RfaWRdL2xvY2F0aW9ucy9bZGF0
YXByb2NfcmVnaW9uXS9zZXNzaW9uVGVtcGxhdGVzL1t0ZW1wbGF0ZV9pZF1gCgogVGhlIHRl
bXBsYXRlIG11c3QgYmUgaW4gdGhlIHNhbWUgcHJvamVjdCBhbmQgRGF0YXByb2MgcmVnaW9u
IGFzIHRoZQogc2Vzc2lvbi4KCg0KBQQGAg8FEgTeAgIICg0KBQQGAg8BEgTeAgkZCg0KBQQG
Ag8DEgTeAhweCg8KBQQGAg8IEgbeAh/jAgMKEAoIBAYCDwicCAASBN8CBCoKEQoHBAYCDwif
CBIG4AIE4gIFCkEKAgQHEgbnAgD5AgEaMyBKdXB5dGVyIGNvbmZpZ3VyYXRpb24gZm9yIGFu
IGludGVyYWN0aXZlIHNlc3Npb24uCgoLCgMEBwESBOcCCBUKJwoEBAcEABIG6QIC8gIDGhcg
SnVweXRlciBrZXJuZWwgdHlwZXMuCgoNCgUEBwQAARIE6QIHDQooCgYEBwQAAgASBOsCBBsa
GCBUaGUga2VybmVsIGlzIHVua25vd24uCgoPCgcEBwQAAgABEgTrAgQWCg8KBwQHBAACAAIS
BOsCGRoKIAoGBAcEAAIBEgTuAgQPGhAgUHl0aG9uIGtlcm5lbC4KCg8KBwQHBAACAQESBO4C
BAoKDwoHBAcEAAIBAhIE7gINDgofCgYEBwQAAgISBPECBA4aDyBTY2FsYSBrZXJuZWwuCgoP
CgcEBwQAAgIBEgTxAgQJCg8KBwQHBAACAgISBPECDA0KIAoEBAcCABIE9QICPRoSIE9wdGlv
bmFsLiBLZXJuZWwKCg0KBQQHAgAGEgT1AgIICg0KBQQHAgABEgT1AgkPCg0KBQQHAgADEgT1
AhITCg0KBQQHAgAIEgT1AhQ8ChAKCAQHAgAInAgAEgT1AhU7Ck0KBAQHAgESBPgCAkMaPyBP
cHRpb25hbC4gRGlzcGxheSBuYW1lLCBzaG93biBpbiB0aGUgSnVweXRlciBrZXJuZWxzcGVj
IGNhcmQuCgoNCgUEBwIBBRIE+AICCAoNCgUEBwIBARIE+AIJFQoNCgUEBwIBAxIE+AIYGQoN
CgUEBwIBCBIE+AIaQgoQCggEBwIBCJwIABIE+AIbQQpFCgIECBIE/AIAHRo5IFNwYXJrIGNv
bm5lY3QgY29uZmlndXJhdGlvbiBmb3IgYW4gaW50ZXJhY3RpdmUgc2Vzc2lvbi4KCgsKAwQI
ARIE/AIIGmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest ===
    # Fields for CreateSessionRequest
    # Field: parent Type: 9 ()
    # Field: session Type: 11 (.google.cloud.dataproc.v1.Session)
    # Field: session_id Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::Sessions::GetSessionRequest ===
    # Fields for GetSessionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::Sessions::ListSessionsRequest ===
    # Fields for ListSessionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::Sessions::ListSessionsResponse ===
    # Fields for ListSessionsResponse
    # Field: sessions Type: 11 (.google.cloud.dataproc.v1.Session)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::Sessions::TerminateSessionRequest ===
    # Fields for TerminateSessionRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::Sessions::DeleteSessionRequest ===
    # Fields for DeleteSessionRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::Sessions::Session ===
    # Fields for Session
    # Field: name Type: 9 ()
    # Field: uuid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: jupyter_session Type: 11 (.google.cloud.dataproc.v1.JupyterConfig)
    # Field: spark_connect_session Type: 11 (.google.cloud.dataproc.v1.SparkConnectConfig)
    # Field: runtime_info Type: 11 (.google.cloud.dataproc.v1.RuntimeInfo)
    # Field: state Type: 14 (.google.cloud.dataproc.v1.Session.State)
    # Field: state_message Type: 9 ()
    # Field: state_time Type: 11 (.google.protobuf.Timestamp)
    # Field: creator Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.dataproc.v1.Session.LabelsEntry)
    # Field: runtime_config Type: 11 (.google.cloud.dataproc.v1.RuntimeConfig)
    # Field: environment_config Type: 11 (.google.cloud.dataproc.v1.EnvironmentConfig)
    # Field: user Type: 9 ()
    # Field: state_history Type: 11 (.google.cloud.dataproc.v1.Session.SessionStateHistory)
    # Field: session_template Type: 9 ()

# Enum: Session::State
our $Session_STATE_UNSPECIFIED = 0;
our $Session_CREATING = 1;
our $Session_ACTIVE = 2;
our $Session_TERMINATING = 3;
our $Session_TERMINATED = 4;
our $Session_FAILED = 5;

# === Message: Google::Cloud::Dataproc::V1::Sessions::JupyterConfig ===
    # Fields for JupyterConfig
    # Field: kernel Type: 14 (.google.cloud.dataproc.v1.JupyterConfig.Kernel)
    # Field: display_name Type: 9 ()

# Enum: JupyterConfig::Kernel
our $JupyterConfig_KERNEL_UNSPECIFIED = 0;
our $JupyterConfig_PYTHON = 1;
our $JupyterConfig_SCALA = 2;

# === Message: Google::Cloud::Dataproc::V1::Sessions::SparkConnectConfig ===
    # Fields for SparkConnectConfig

# === Service Client: Google::Cloud::Dataproc::V1::Sessions::SessionControllerClient ===
package Google::Cloud::Dataproc::V1::Sessions::SessionControllerClient;

=pod

=head2 Service Client: Google::Cloud::Dataproc::V1::Sessions::SessionControllerClient

Client stub representing the remote C<SessionController> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dataproc.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataproc.googleapis.com:443' );

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

sub create_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionController',
        method         => 'CreateSession',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::Sessions::GetSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionController',
        method         => 'GetSession',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::Sessions::Session',
    });
}

sub list_sessions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::Sessions::ListSessionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionController',
        method         => 'ListSessions',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::Sessions::ListSessionsResponse',
    });
}

sub terminate_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::Sessions::TerminateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionController',
        method         => 'TerminateSession',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::Sessions::DeleteSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionController',
        method         => 'DeleteSession',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataproc::V1::Sessions - Compiled Protocol Buffers messages for google/cloud/dataproc/v1/sessions.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::Sessions;

    my $msg = Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest->new({
        parent => $parent,
        session => $session,
        session_id => $session_id,
        request_id => $request_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataproc/v1/sessions.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest

A request to create a session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this session will be created.

=item * C<< $msg->session() >> / C<< $msg->session($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Sessions::Session>)

Required. The interactive session to create.

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

Required. The ID to use for the session, which becomes the final component
of the session's resource name.

This value must be 4-63 characters. Valid characters
are /[a-z][0-9]-/.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A unique ID used to identify the request. If the service
receives two
[CreateSessionRequests](https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.CreateSessionRequest)s
with the same ID, the second request is ignored, and the
first [Session][google.cloud.dataproc.v1.Session] is created and stored in
the backend.

Recommendation: Set this value to a
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier).

The value must contain only letters (a-z, A-Z), numbers (0-9),
underscores (_), and hyphens (-). The maximum length is 40 characters.

=back

=head2 Google::Cloud::Dataproc::V1::Sessions::GetSessionRequest

A request to get the resource representation for a session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the session to retrieve.

=back

=head2 Google::Cloud::Dataproc::V1::Sessions::ListSessionsRequest

A request to list sessions in a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of sessions.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of sessions to return in each response.
The service may return fewer than this value.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token received from a previous `ListSessions` call.
Provide this token to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter for the sessions to return in the response.

A filter is a logical expression constraining the values of various fields
in each session resource. Filters are case sensitive, and may contain
multiple clauses combined with logical operators (AND, OR).
Supported fields are `session_id`, `session_uuid`, `state`, `create_time`,
and `labels`.

Example: `state = ACTIVE and create_time < "2023-01-01T00:00:00Z"`
is a filter for sessions in an ACTIVE state that were created before
2023-01-01. `state = ACTIVE and labels.environment=production` is a filter
for sessions in an ACTIVE state that have a production environment label.

See https://google.aip.dev/assets/misc/ebnf-filtering.txt for a detailed
description of the filter syntax and a list of supported comparators.

=back

=head2 Google::Cloud::Dataproc::V1::Sessions::ListSessionsResponse

A list of interactive sessions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sessions() >> / C<< $msg->sessions($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Sessions::Session>)

Output only. The sessions from the specified collection.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token`, to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Dataproc::V1::Sessions::TerminateSessionRequest

A request to terminate an interactive session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the session resource to terminate.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A unique ID used to identify the request. If the service
receives two
[TerminateSessionRequest](https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.TerminateSessionRequest)s
with the same ID, the second request is ignored.

Recommendation: Set this value to a
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier).

The value must contain only letters (a-z, A-Z), numbers (0-9),
underscores (_), and hyphens (-). The maximum length is 40 characters.

=back

=head2 Google::Cloud::Dataproc::V1::Sessions::DeleteSessionRequest

A request to delete a session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the session resource to delete.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A unique ID used to identify the request. If the service
receives two
[DeleteSessionRequest](https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.DeleteSessionRequest)s
with the same ID, the second request is ignored.

Recommendation: Set this value to a
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier).

The value must contain only letters (a-z, A-Z), numbers (0-9),
underscores (_), and hyphens (-). The maximum length is 40 characters.

=back

=head2 Google::Cloud::Dataproc::V1::Sessions::Session

A representation of a session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the session.

=item * C<< $msg->uuid() >> / C<< $msg->uuid($value) >>

Type: C<String>

Output only. A session UUID (Unique Universal Identifier). The service
generates this value when it creates the session.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the session was created.

=item * C<< $msg->jupyter_session() >> / C<< $msg->jupyter_session($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Sessions::JupyterConfig>)

Optional. Jupyter session config.

=item * C<< $msg->spark_connect_session() >> / C<< $msg->spark_connect_session($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Sessions::SparkConnectConfig>)

Optional. Spark connect session config.

=item * C<< $msg->runtime_info() >> / C<< $msg->runtime_info($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Shared::RuntimeInfo>)

Output only. Runtime information about session execution.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dataproc::V1::Session::State>)

Output only. A state of the session.

=item * C<< $msg->state_message() >> / C<< $msg->state_message($value) >>

Type: C<String>

Output only. Session state details, such as the failure
description if the state is `FAILED`.

=item * C<< $msg->state_time() >> / C<< $msg->state_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the session entered the current state.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<String>

Output only. The email address of the user who created the session.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Sessions::Session::LabelsEntry>)

Optional. The labels to associate with the session.
Label B<keys> must contain 1 to 63 characters, and must conform to
[RFC 1035](https://www.ietf.org/rfc/rfc1035.txt).
Label B<values> may be empty, but, if present, must contain 1 to 63
characters, and must conform to [RFC
1035](https://www.ietf.org/rfc/rfc1035.txt). No more than 32 labels can be
associated with a session.

=item * C<< $msg->runtime_config() >> / C<< $msg->runtime_config($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Shared::RuntimeConfig>)

Optional. Runtime configuration for the session execution.

=item * C<< $msg->environment_config() >> / C<< $msg->environment_config($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Shared::EnvironmentConfig>)

Optional. Environment configuration for the session execution.

=item * C<< $msg->user() >> / C<< $msg->user($value) >>

Type: C<String>

Optional. The email address of the user who owns the session.

=item * C<< $msg->state_history() >> / C<< $msg->state_history($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Sessions::Session::SessionStateHistory>)

Output only. Historical state information for the session.

=item * C<< $msg->session_template() >> / C<< $msg->session_template($value) >>

Type: C<String>

Optional. The session template used by the session.

Only resource names, including project ID and location, are valid.

Example:
* `https://www.googleapis.com/compute/v1/projects/[project_id]/locations/[dataproc_region]/sessionTemplates/[template_id]`
* `projects/[project_id]/locations/[dataproc_region]/sessionTemplates/[template_id]`

The template must be in the same project and Dataproc region as the
session.

=back

=head3 Enum: Session::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<TERMINATING> => C<3>

=item * C<TERMINATED> => C<4>

=item * C<FAILED> => C<5>

=back

=head2 Google::Cloud::Dataproc::V1::Sessions::JupyterConfig

Jupyter configuration for an interactive session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kernel() >> / C<< $msg->kernel($value) >>

Type: C<Enum> (L<Google::Cloud::Dataproc::V1::JupyterConfig::Kernel>)

Optional. Kernel

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Display name, shown in the Jupyter kernelspec card.

=back

=head3 Enum: JupyterConfig::Kernel

=over 4

=item * C<KERNEL_UNSPECIFIED> => C<0>

=item * C<PYTHON> => C<1>

=item * C<SCALA> => C<2>

=back

=head2 Google::Cloud::Dataproc::V1::Sessions::SparkConnectConfig

Spark connect configuration for an interactive session.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataproc::V1::Sessions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
