package Google::Cloud::Ces::V1::Omnichannel;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvY2VzL3YxL29tbmljaGFubmVsLnByb3RvEhNnb29nbGUuY2xvdWQu
Y2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jl
c291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIv4DCgtPbW5p
Y2hhbm5lbBIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJ
QgPgQQJSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPgQQFSC2Rlc2NyaXB0
aW9uEkAKC2NyZWF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEhcKBGV0YWcYBiABKAlCA+BBA1IEZXRhZxJl
ChJpbnRlZ3JhdGlvbl9jb25maWcYByABKAsyMS5nb29nbGUuY2xvdWQuY2VzLnYxLk9tbmlj
aGFubmVsSW50ZWdyYXRpb25Db25maWdCA+BBAVIRaW50ZWdyYXRpb25Db25maWc6ggHqQX8K
HmNlcy5nb29nbGVhcGlzLmNvbS9PbW5pY2hhbm5lbBJCcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L29tbmljaGFubmVscy97b21uaWNoYW5uZWx9KgxvbW5pY2hh
bm5lbHMyC29tbmljaGFubmVsIvsLChxPbW5pY2hhbm5lbEludGVncmF0aW9uQ29uZmlnEnMK
D2NoYW5uZWxfY29uZmlncxgBIAMoCzJFLmdvb2dsZS5jbG91ZC5jZXMudjEuT21uaWNoYW5u
ZWxJbnRlZ3JhdGlvbkNvbmZpZy5DaGFubmVsQ29uZmlnc0VudHJ5QgPgQQFSDmNoYW5uZWxD
b25maWdzEnwKEnN1YnNjcmliZXJfY29uZmlncxgCIAMoCzJILmdvb2dsZS5jbG91ZC5jZXMu
djEuT21uaWNoYW5uZWxJbnRlZ3JhdGlvbkNvbmZpZy5TdWJzY3JpYmVyQ29uZmlnc0VudHJ5
QgPgQQFSEXN1YnNjcmliZXJDb25maWdzEnMKD3JvdXRpbmdfY29uZmlncxgDIAMoCzJFLmdv
b2dsZS5jbG91ZC5jZXMudjEuT21uaWNoYW5uZWxJbnRlZ3JhdGlvbkNvbmZpZy5Sb3V0aW5n
Q29uZmlnc0VudHJ5QgPgQQFSDnJvdXRpbmdDb25maWdzGo4BCg1DaGFubmVsQ29uZmlnEmsK
D3doYXRzYXBwX2NvbmZpZxgBIAEoCzJALmdvb2dsZS5jbG91ZC5jZXMudjEuT21uaWNoYW5u
ZWxJbnRlZ3JhdGlvbkNvbmZpZy5XaGF0c2FwcENvbmZpZ0gAUg53aGF0c2FwcENvbmZpZ0IQ
Cg5jaGFubmVsX2NvbmZpZxrDAgoOV2hhdHNhcHBDb25maWcSJgoPcGhvbmVfbnVtYmVyX2lk
GAEgASgJUg1waG9uZU51bWJlcklkEiEKDHBob25lX251bWJlchgCIAEoCVILcGhvbmVOdW1i
ZXISPwocd2hhdHNhcHBfYnVzaW5lc3NfYWNjb3VudF9pZBgDIAEoCVIZd2hhdHNhcHBCdXNp
bmVzc0FjY291bnRJZBIwChR3ZWJob29rX3ZlcmlmeV90b2tlbhgEIAEoCVISd2ViaG9va1Zl
cmlmeVRva2VuEjYKF3doYXRzYXBwX2J1c2luZXNzX3Rva2VuGAUgASgJUhV3aGF0c2FwcEJ1
c2luZXNzVG9rZW4SOwoabWV0YV9idXNpbmVzc19wb3J0Zm9saW9faWQYBiABKAlSF21ldGFC
dXNpbmVzc1BvcnRmb2xpb0lkGo8BChBTdWJzY3JpYmVyQ29uZmlnEmYKDmNlc19hcHBfY29u
ZmlnGAEgASgLMj4uZ29vZ2xlLmNsb3VkLmNlcy52MS5PbW5pY2hhbm5lbEludGVncmF0aW9u
Q29uZmlnLkNlc0FwcENvbmZpZ0gAUgxjZXNBcHBDb25maWdCEwoRc3Vic2NyaWJlcl9jb25m
aWcaPQoMQ2VzQXBwQ29uZmlnEi0KA2FwcBgBIAEoCUIb+kEYChZjZXMuZ29vZ2xlYXBpcy5j
b20vQXBwUgNhcHAaNgoNUm91dGluZ0NvbmZpZxIlCg5zdWJzY3JpYmVyX2tleRgBIAEoCVIN
c3Vic2NyaWJlcktleRqCAQoTQ2hhbm5lbENvbmZpZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRJVCgV2YWx1ZRgCIAEoCzI/Lmdvb2dsZS5jbG91ZC5jZXMudjEuT21uaWNoYW5uZWxJbnRl
Z3JhdGlvbkNvbmZpZy5DaGFubmVsQ29uZmlnUgV2YWx1ZToCOAEaiAEKFlN1YnNjcmliZXJD
b25maWdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSWAoFdmFsdWUYAiABKAsyQi5nb29nbGUu
Y2xvdWQuY2VzLnYxLk9tbmljaGFubmVsSW50ZWdyYXRpb25Db25maWcuU3Vic2NyaWJlckNv
bmZpZ1IFdmFsdWU6AjgBGoIBChNSb3V0aW5nQ29uZmlnc0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5ElUKBXZhbHVlGAIgASgLMj8uZ29vZ2xlLmNsb3VkLmNlcy52MS5PbW5pY2hhbm5lbElu
dGVncmF0aW9uQ29uZmlnLlJvdXRpbmdDb25maWdSBXZhbHVlOgI4AUJYChdjb20uZ29vZ2xl
LmNsb3VkLmNlcy52MUIQT21uaWNoYW5uZWxQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dv
L2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkqkIwoHEgUOAIYBAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQAKQoICgEIEgMWAEAKCQoCCAsSAxYAQAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMY
ADEKCQoCCAgSAxgAMQoICgEIEgMZADAKCQoCCAESAxkAMAoxCgIEABIEHAA+ARolIFJlcHJl
c2VudHMgYW4gT21uaWNoYW5uZWwgcmVzb3VyY2UuCgoKCgMEAAESAxwIEwoLCgMEAAcSBB0C
IgQKDQoFBAAHnQgSBB0CIgQKnQEKBAQAAgASAycCPRqPASBJZGVudGlmaWVyLiBUaGUgdW5p
cXVlIGlkZW50aWZpZXIgb2YgdGhlIG9tbmljaGFubmVsIHJlc291cmNlLgogRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vbW5pY2hhbm5lbHMv
e29tbmljaGFubmVsfWAKCgwKBQQAAgAFEgMnAggKDAoFBAACAAESAycJDQoMCgUEAAIAAxID
JxARCgwKBQQAAgAIEgMnEjwKDwoIBAACAAicCAASAycTOwpCCgQEAAIBEgMqAkMaNSBSZXF1
aXJlZC4gRGlzcGxheSBuYW1lIG9mIHRoZSBvbW5pY2hhbm5lbCByZXNvdXJjZS4KCgwKBQQA
AgEFEgMqAggKDAoFBAACAQESAyoJFQoMCgUEAAIBAxIDKhgZCgwKBQQAAgEIEgMqGkIKDwoI
BAACAQicCAASAyobQQpQCgQEAAICEgMtAkIaQyBPcHRpb25hbC4gSHVtYW4tcmVhZGFibGUg
ZGVzY3JpcHRpb24gb2YgdGhlIG9tbmljaGFubmVsIHJlc291cmNlLgoKDAoFBAACAgUSAy0C
CAoMCgUEAAICARIDLQkUCgwKBQQAAgIDEgMtFxgKDAoFBAACAggSAy0ZQQoPCggEAAICCJwI
ABIDLRpAClEKBAQAAgMSBDACMTIaQyBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhl
IG9tbmljaGFubmVsIHJlc291cmNlIHdhcyBjcmVhdGVkLgoKDAoFBAACAwYSAzACGwoMCgUE
AAIDARIDMBwnCgwKBQQAAgMDEgMwKisKDAoFBAACAwgSAzEGMQoPCggEAAIDCJwIABIDMQcw
ClYKBAQAAgQSBDQCNTIaSCBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIG9tbmlj
aGFubmVsIHJlc291cmNlIHdhcyBsYXN0IHVwZGF0ZWQuCgoMCgUEAAIEBhIDNAIbCgwKBQQA
AgQBEgM0HCcKDAoFBAACBAMSAzQqKwoMCgUEAAIECBIDNQYxCg8KCAQAAgQInAgAEgM1BzAK
cAoEBAACBRIDOQI+GmMgT3V0cHV0IG9ubHkuIEV0YWcgdXNlZCB0byBlbnN1cmUgdGhlIG9i
amVjdCBoYXNuJ3QgY2hhbmdlZCBkdXJpbmcgYQogcmVhZC1tb2RpZnktd3JpdGUgb3BlcmF0
aW9uLgoKDAoFBAACBQUSAzkCCAoMCgUEAAIFARIDOQkNCgwKBQQAAgUDEgM5EBEKDAoFBAAC
BQgSAzkSPQoPCggEAAIFCJwIABIDORM8Ck4KBAQAAgYSBDwCPS8aQCBPcHRpb25hbC4gVGhl
IGludGVncmF0aW9uIGNvbmZpZyBmb3IgdGhlIG9tbmljaGFubmVsIHJlc291cmNlLgoKDAoF
BAACBgYSAzwCHgoMCgUEAAIGARIDPB8xCgwKBQQAAgYDEgM8NDUKDAoFBAACBggSAz0GLgoP
CggEAAIGCJwIABIDPQctClEKAgQBEgVBAIYBARpEIE9tbmljaGFubmVsSW50ZWdyYXRpb25D
b25maWcgY29udGFpbnMgYWxsIEFwcCBpbnRlZ3JhdGlvbiBjb25maWdzLgoKCgoDBAEBEgNB
CCQKTQoEBAEDABIEQwJJAxo/IENoYW5uZWxDb25maWcgY29udGFpbnMgY29uZmlnIGZvciB2
YXJpb3VzIG9mIGFwcCBpbnRlZ3JhdGlvbi4KCgwKBQQBAwABEgNDChcKKQoGBAEDAAgAEgRF
BEgFGhkgVGhlIGNvbmZpZyBmb3IgdGhlIGFwcC4KCg4KBwQBAwAIAAESA0UKGAohCgYEAQMA
AgASA0cGKRoSIFdoYXRzQXBwIGNvbmZpZy4KCg4KBwQBAwACAAYSA0cGFAoOCgcEAQMAAgAB
EgNHFSQKDgoHBAEDAAIAAxIDRycoCkoKBAQBAwESBEwCYQMaPCBIb3cgT21uaWNoYW5uZWwg
c2hvdWxkIHJlY2VpdmUvcmVwbHkgZXZlbnRzIGZyb20gV2hhdHNBcHAuCgoMCgUEAQMBARID
TAoYClMKBgQBAwECABIDTgQfGkQgVGhlIFBob25lIE51bWJlciBJRCBhc3NvY2lhdGVkIHdp
dGggdGhlIFdoYXRzQXBwIEJ1c2luZXNzIEFjY291bnQuCgoOCgcEAQMBAgAFEgNOBAoKDgoH
BAEDAQIAARIDTgsaCg4KBwQBAwECAAMSA04dHgpGCgYEAQMBAgESA1EEHBo3IFRoZSBwaG9u
ZSBudW1iZXIgdXNlZCBmb3Igc2VuZGluZy9yZWNlaXZpbmcgbWVzc2FnZXMuCgoOCgcEAQMB
AgEFEgNRBAoKDgoHBAEDAQIBARIDUQsXCg4KBwQBAwECAQMSA1EaGwpECgYEAQMBAgISA1QE
LBo1IFRoZSBjdXN0b21lcidzIFdoYXRzQXBwIEJ1c2luZXNzIEFjY291bnQgKFdBQkEpIElE
LgoKDgoHBAEDAQICBRIDVAQKCg4KBwQBAwECAgESA1QLJwoOCgcEAQMBAgIDEgNUKisKYQoG
BAEDAQIDEgNYBCQaUiBUaGUgdmVyaWZ5IHRva2VuIGNvbmZpZ3VyZWQgaW4gdGhlIE1ldGEg
QXBwIERhc2hib2FyZCBmb3Igd2ViaG9vawogdmVyaWZpY2F0aW9uLgoKDgoHBAEDAQIDBRID
WAQKCg4KBwQBAwECAwESA1gLHwoOCgcEAQMBAgMDEgNYIiMK3QEKBgQBAwECBBIDXAQnGs0B
IFRoZSBhY2Nlc3MgdG9rZW4gZm9yIGF1dGhlbnRpY2F0aW5nIEFQSSBjYWxscyB0byB0aGUg
V2hhdHNBcHAgQ2xvdWQgQVBJLgogaHR0cHM6Ly9kZXZlbG9wZXJzLmZhY2Vib29rLmNvbS9k
b2NzL3doYXRzYXBwL2J1c2luZXNzLW1hbmFnZW1lbnQtYXBpL2dldC1zdGFydGVkLyNidXNp
bmVzcy1pbnRlZ3JhdGlvbi1zeXN0ZW0tdXNlci1hY2Nlc3MtdG9rZW5zCgoOCgcEAQMBAgQF
EgNcBAoKDgoHBAEDAQIEARIDXAsiCg4KBwQBAwECBAMSA1wlJgpvCgYEAQMBAgUSA2AEKhpg
IFRoZSBNZXRhIEJ1c2luZXNzIFBvcnRmb2xpbyAoTUJQKSBJRC4KIGh0dHBzOi8vd3d3LmZh
Y2Vib29rLmNvbS9idXNpbmVzcy9oZWxwLzE3MTAwNzczNzkyMDM2NTcKCg4KBwQBAwECBQUS
A2AECgoOCgcEAQMBAgUBEgNgCyUKDgoHBAEDAQIFAxIDYCgpCicKBAQBAwISBGQCagMaGSBD
b25maWdzIG9mIHN1YnNjcmliZXJzLgoKDAoFBAEDAgESA2QKGgowCgYEAQMCCAASBGYEaQUa
ICBUaGUgY29uZmlnIGZvciB0aGUgc3Vic2NyaWJlci4KCg4KBwQBAwIIAAESA2YKGwogCgYE
AQMCAgASA2gGJhoRIENlcyBhcHAgY29uZmlnLgoKDgoHBAEDAgIABhIDaAYSCg4KBwQBAwIC
AAESA2gTIQoOCgcEAQMCAgADEgNoJCUKJAoEBAEDAxIEbQJyAxoWIENvbmZpZ3MgZm9yIENF
UyBhcHAuCgoMCgUEAQMDARIDbQoWCnUKBgQBAwMCABIEcARxTxplIFRoZSB1bmlxdWUgaWRl
bnRpZmllciBvZiB0aGUgQ0VTIGFwcC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9YAoKDgoHBAEDAwIABRIDcAQKCg4KBwQB
AwMCAAESA3ALDgoOCgcEAQMDAgADEgNwERIKDgoHBAEDAwIACBIDcQhOChAKCQQBAwMCAAif
CBIDcQlNClMKBAQBAwQSBHUCeAMaRSBSb3V0aW5nIGNvbmZpZyBzcGVjaWZ5IGhvdy93aG8g
dG8gcm91dGUgYXBwIGV2ZW50cyB0byBhIHN1YnNjcmliZXIuCgoMCgUEAQMEARIDdQoXCisK
BgQBAwQCABIDdwQeGhwgVGhlIGtleSBvZiB0aGUgc3Vic2NyaWJlci4KCg4KBwQBAwQCAAUS
A3cECgoOCgcEAQMEAgABEgN3CxkKDgoHBAEDBAIAAxIDdxwdCksKBAQBAgASBHsCfC8aPSBP
cHRpb25hbC4gVmFyaW91cyBvZiBjb25maWd1cmF0aW9uIGZvciBoYW5kbGluZyBBcHAgZXZl
bnRzLgoKDAoFBAECAAYSA3sCHAoMCgUEAQIAARIDex0sCgwKBQQBAgADEgN7LzAKDAoFBAEC
AAgSA3wGLgoPCggEAQIACJwIABIDfActCjoKBAQBAgESBX8CgAEvGisgT3B0aW9uYWwuIFZh
cmlvdXMgb2Ygc3Vic2NyaWJlcnMgY29uZmlncy4KCgwKBQQBAgEGEgN/Ah8KDAoFBAECAQES
A38gMgoMCgUEAQIBAxIDfzU2Cg0KBQQBAgEIEgSAAQYuChAKCAQBAgEInAgAEgSAAQctCo8B
CgQEAQICEgaEAQKFAS8afyBPcHRpb25hbC4gVGhlIGtleSBvZiByb3V0aW5nX2NvbmZpZ3Mg
aXMgYSBrZXkgb2YgYGFwcF9jb25maWdzYCwgdmFsdWUgaXMgYQogYFJvdXRpbmdDb25maWdg
LCB3aGljaCBjb250YWlucyBzdWJzY3JpYmVyJ3Mga2V5LgoKDQoFBAECAgYSBIQBAhwKDQoF
BAECAgESBIQBHSwKDQoFBAECAgMSBIQBLzAKDQoFBAECAggSBIUBBi4KEAoIBAECAgicCAAS
BIUBBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Omnichannel::Omnichannel ===
    # Fields for Omnichannel
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: integration_config Type: 11 (.google.cloud.ces.v1.OmnichannelIntegrationConfig)

# === Message: Google::Cloud::Ces::V1::Omnichannel::OmnichannelIntegrationConfig ===
    # Fields for OmnichannelIntegrationConfig
    # Field: channel_configs Type: 11 (.google.cloud.ces.v1.OmnichannelIntegrationConfig.ChannelConfigsEntry)
    # Field: subscriber_configs Type: 11 (.google.cloud.ces.v1.OmnichannelIntegrationConfig.SubscriberConfigsEntry)
    # Field: routing_configs Type: 11 (.google.cloud.ces.v1.OmnichannelIntegrationConfig.RoutingConfigsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Omnichannel - Compiled Protocol Buffers messages for google/cloud/ces/v1/omnichannel.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Omnichannel;

    my $msg = Google::Cloud::Ces::V1::Omnichannel::Omnichannel->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Omnichannel::Omnichannel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/omnichannel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Omnichannel::Omnichannel

Represents an Omnichannel resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the omnichannel resource.
Format:
`projects/{project}/locations/{location}/omnichannels/{omnichannel}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the omnichannel resource.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Human-readable description of the omnichannel resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the omnichannel resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the omnichannel resource was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. Etag used to ensure the object hasn't changed during a
read-modify-write operation.

=item * C<< $msg->integration_config() >> / C<< $msg->integration_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Omnichannel::OmnichannelIntegrationConfig>)

Optional. The integration config for the omnichannel resource.

=back

=head2 Google::Cloud::Ces::V1::Omnichannel::OmnichannelIntegrationConfig

OmnichannelIntegrationConfig contains all App integration configs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->channel_configs() >> / C<< $msg->channel_configs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Omnichannel::OmnichannelIntegrationConfig::ChannelConfigsEntry>)

Optional. Various of configuration for handling App events.

=item * C<< $msg->subscriber_configs() >> / C<< $msg->subscriber_configs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Omnichannel::OmnichannelIntegrationConfig::SubscriberConfigsEntry>)

Optional. Various of subscribers configs.

=item * C<< $msg->routing_configs() >> / C<< $msg->routing_configs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Omnichannel::OmnichannelIntegrationConfig::RoutingConfigsEntry>)

Optional. The key of routing_configs is a key of `app_configs`, value is a
`RoutingConfig`, which contains subscriber's key.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Omnichannel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
