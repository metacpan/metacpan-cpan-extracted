package Google::Cloud::Batch::V1alpha::ResourceAllowance;

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
    eval { require Google::Cloud::Batch::V1alpha::Notification };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvYmF0Y2gvdjFhbHBoYS9yZXNvdXJjZV9hbGxvd2FuY2UucHJvdG8S
Gmdvb2dsZS5jbG91ZC5iYXRjaC52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aLWdvb2dsZS9jbG91ZC9iYXRjaC92MWFscGhhL25vdGlmaWNhdGlvbi5wcm90
bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoaZ29vZ2xlL3R5cGUvaW50ZXJ2
YWwucHJvdG8iogUKEVJlc291cmNlQWxsb3dhbmNlEm4KGHVzYWdlX3Jlc291cmNlX2FsbG93
YW5jZRgEIAEoCzIyLmdvb2dsZS5jbG91ZC5iYXRjaC52MWFscGhhLlVzYWdlUmVzb3VyY2VB
bGxvd2FuY2VIAFIWdXNhZ2VSZXNvdXJjZUFsbG93YW5jZRIXCgRuYW1lGAEgASgJQgPgQQhS
BG5hbWUSHQoDdWlkGAIgASgJQgvijM/XCAIIAeBBA1IDdWlkEkAKC2NyZWF0ZV90aW1lGAMg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lElYKBmxh
YmVscxgFIAMoCzI5Lmdvb2dsZS5jbG91ZC5iYXRjaC52MWFscGhhLlJlc291cmNlQWxsb3dh
bmNlLkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxJTCg1ub3RpZmljYXRpb25zGAYgAygLMigu
Z29vZ2xlLmNsb3VkLmJhdGNoLnYxYWxwaGEuTm90aWZpY2F0aW9uQgPgQQFSDW5vdGlmaWNh
dGlvbnMaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlS
BXZhbHVlOgI4ATqkAepBoAEKJmJhdGNoLmdvb2dsZWFwaXMuY29tL1Jlc291cmNlQWxsb3dh
bmNlEk9wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVzb3VyY2VB
bGxvd2FuY2VzL3tyZXNvdXJjZV9hbGxvd2FuY2V9KhJyZXNvdXJjZUFsbG93YW5jZXMyEXJl
c291cmNlQWxsb3dhbmNlQhQKEnJlc291cmNlX2FsbG93YW5jZSLAAQoWVXNhZ2VSZXNvdXJj
ZUFsbG93YW5jZRJPCgRzcGVjGAEgASgLMjYuZ29vZ2xlLmNsb3VkLmJhdGNoLnYxYWxwaGEu
VXNhZ2VSZXNvdXJjZUFsbG93YW5jZVNwZWNCA+BBAlIEc3BlYxJVCgZzdGF0dXMYAiABKAsy
OC5nb29nbGUuY2xvdWQuYmF0Y2gudjFhbHBoYS5Vc2FnZVJlc291cmNlQWxsb3dhbmNlU3Rh
dHVzQgPgQQNSBnN0YXR1cyKqAgoaVXNhZ2VSZXNvdXJjZUFsbG93YW5jZVNwZWMSFwoEdHlw
ZRgBIAEoCUID4EECUgR0eXBlElcKBWxpbWl0GAIgASgLMjwuZ29vZ2xlLmNsb3VkLmJhdGNo
LnYxYWxwaGEuVXNhZ2VSZXNvdXJjZUFsbG93YW5jZVNwZWMuTGltaXRCA+BBAlIFbGltaXQa
mQEKBUxpbWl0EloKD2NhbGVuZGFyX3BlcmlvZBgBIAEoDjIqLmdvb2dsZS5jbG91ZC5iYXRj
aC52MWFscGhhLkNhbGVuZGFyUGVyaW9kQgPgQQFIAFIOY2FsZW5kYXJQZXJpb2QSHgoFbGlt
aXQYAiABKAFCA+BBAkgBUgVsaW1pdIgBAUIKCghkdXJhdGlvbkIICgZfbGltaXQi9gcKHFVz
YWdlUmVzb3VyY2VBbGxvd2FuY2VTdGF0dXMSTQoFc3RhdGUYASABKA4yMi5nb29nbGUuY2xv
dWQuYmF0Y2gudjFhbHBoYS5SZXNvdXJjZUFsbG93YW5jZVN0YXRlQgPgQQNSBXN0YXRlEmwK
DGxpbWl0X3N0YXR1cxgCIAEoCzJELmdvb2dsZS5jbG91ZC5iYXRjaC52MWFscGhhLlVzYWdl
UmVzb3VyY2VBbGxvd2FuY2VTdGF0dXMuTGltaXRTdGF0dXNCA+BBA1ILbGltaXRTdGF0dXMS
ZwoGcmVwb3J0GAMgASgLMkouZ29vZ2xlLmNsb3VkLmJhdGNoLnYxYWxwaGEuVXNhZ2VSZXNv
dXJjZUFsbG93YW5jZVN0YXR1cy5Db25zdW1wdGlvblJlcG9ydEID4EEDUgZyZXBvcnQauQEK
C0xpbWl0U3RhdHVzEk0KFGNvbnN1bXB0aW9uX2ludGVydmFsGAEgASgLMhUuZ29vZ2xlLnR5
cGUuSW50ZXJ2YWxCA+BBA1ITY29uc3VtcHRpb25JbnRlcnZhbBIeCgVsaW1pdBgCIAEoAUID
4EEDSABSBWxpbWl0iAEBEiQKCGNvbnN1bWVkGAMgASgBQgPgQQNIAVIIY29uc3VtZWSIAQFC
CAoGX2xpbWl0QgsKCV9jb25zdW1lZBqVAQoRUGVyaW9kQ29uc3VtcHRpb24STQoUY29uc3Vt
cHRpb25faW50ZXJ2YWwYASABKAsyFS5nb29nbGUudHlwZS5JbnRlcnZhbEID4EEDUhNjb25z
dW1wdGlvbkludGVydmFsEiQKCGNvbnN1bWVkGAIgASgBQgPgQQNIAFIIY29uc3VtZWSIAQFC
CwoJX2NvbnN1bWVkGtsCChFDb25zdW1wdGlvblJlcG9ydBKrAQoabGF0ZXN0X3BlcmlvZF9j
b25zdW1wdGlvbnMYASADKAsyaC5nb29nbGUuY2xvdWQuYmF0Y2gudjFhbHBoYS5Vc2FnZVJl
c291cmNlQWxsb3dhbmNlU3RhdHVzLkNvbnN1bXB0aW9uUmVwb3J0LkxhdGVzdFBlcmlvZENv
bnN1bXB0aW9uc0VudHJ5QgPgQQNSGGxhdGVzdFBlcmlvZENvbnN1bXB0aW9ucxqXAQodTGF0
ZXN0UGVyaW9kQ29uc3VtcHRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSYAoFdmFsdWUY
AiABKAsySi5nb29nbGUuY2xvdWQuYmF0Y2gudjFhbHBoYS5Vc2FnZVJlc291cmNlQWxsb3dh
bmNlU3RhdHVzLlBlcmlvZENvbnN1bXB0aW9uUgV2YWx1ZToCOAEqZgoOQ2FsZW5kYXJQZXJp
b2QSHwobQ0FMRU5EQVJfUEVSSU9EX1VOU1BFQ0lGSUVEEAASCQoFTU9OVEgQARILCgdRVUFS
VEVSEAISCAoEWUVBUhADEggKBFdFRUsQBBIHCgNEQVkQBSqCAQoWUmVzb3VyY2VBbGxvd2Fu
Y2VTdGF0ZRIoCiRSRVNPVVJDRV9BTExPV0FOQ0VfU1RBVEVfVU5TUEVDSUZJRUQQABIdChlS
RVNPVVJDRV9BTExPV0FOQ0VfQUNUSVZFEAESHwobUkVTT1VSQ0VfQUxMT1dBTkNFX0RFUExF
VEVEEAJC0AEKHmNvbS5nb29nbGUuY2xvdWQuYmF0Y2gudjFhbHBoYUIWUmVzb3VyY2VBbGxv
d2FuY2VQcm90b1ABWjRjbG91ZC5nb29nbGUuY29tL2dvL2JhdGNoL2FwaXYxYWxwaGEvYmF0
Y2hwYjtiYXRjaHBiogIDR0NCqgIaR29vZ2xlLkNsb3VkLkJhdGNoLlYxQWxwaGHKAhpHb29n
bGVcQ2xvdWRcQmF0Y2hcVjFhbHBoYeoCHUdvb2dsZTo6Q2xvdWQ6OkJhdGNoOjpWMWFscGhh
Sv84CgcSBQ4AzwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAjCgkKAgMAEgMSACkKCQoCAwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVADcKCQoCAwQS
AxYAKQoJCgIDBRIDFwAkCggKAQgSAxkANwoJCgIIJRIDGQA3CggKAQgSAxoASwoJCgIICxID
GgBLCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwANwoJCgIICBIDHAA3CggKAQgSAx0A
NwoJCgIIARIDHQA3CggKAQgSAx4AIQoJCgIIJBIDHgAhCggKAQgSAx8ANwoJCgIIKRIDHwA3
CggKAQgSAyAANgoJCgIILRIDIAA2CrgBCgIFABIEJQA5ARqrASBBIGBDYWxlbmRhclBlcmlv
ZGAgcmVwcmVzZW50cyB0aGUgYWJzdHJhY3QgY29uY2VwdCBvZiBhIHRpbWUgcGVyaW9kIHRo
YXQKIGhhcyBhIGNhbm9uaWNhbCBzdGFydC4gQWxsIGNhbGVuZGFyIHRpbWVzIGJlZ2luIGF0
IDEyIEFNIFVTIGFuZCBDYW5hZGlhbgogUGFjaWZpYyBUaW1lIChVVEMtOCkuCgoKCgMFAAES
AyUFEwobCgQFAAIAEgMnAiIaDiBVbnNwZWNpZmllZC4KCgwKBQUAAgABEgMnAh0KDAoFBQAC
AAISAycgIQpqCgQFAAIBEgMrAgwaXSBUaGUgbW9udGggc3RhcnRzIG9uIHRoZSBmaXJzdCBk
YXRlIG9mIHRoZSBtb250aCBhbmQgcmVzZXRzIGF0IHRoZSBiZWdpbm5pbmcKIG9mIGVhY2gg
bW9udGguCgoMCgUFAAIBARIDKwIHCgwKBQUAAgECEgMrCgsKlAEKBAUAAgISAy8CDhqGASBU
aGUgcXVhcnRlciBzdGFydHMgb24gZGF0ZXMgSmFudWFyeSAxLCBBcHJpbCAxLCBKdWx5IDEs
IGFuZCBPY3RvYmVyIDEgb2YKIGVhY2ggeWVhciBhbmQgcmVzZXRzIGF0IHRoZSBiZWdpbm5p
bmcgb2YgdGhlIG5leHQgcXVhcnRlci4KCgwKBQUAAgIBEgMvAgkKDAoFBQACAgISAy8MDQpZ
CgQFAAIDEgMyAgsaTCBUaGUgeWVhciBzdGFydHMgb24gSmFudWFyeSAxIGFuZCByZXNldHMg
YXQgdGhlIGJlZ2lubmluZyBvZiB0aGUgbmV4dCB5ZWFyLgoKDAoFBQACAwESAzICBgoMCgUF
AAIDAhIDMgkKCj4KBAUAAgQSAzUCCxoxIFRoZSB3ZWVrIHBlcmlvZCBzdGFydHMgYW5kIHJl
c2V0cyBldmVyeSBNb25kYXkuCgoMCgUFAAIEARIDNQIGCgwKBQUAAgQCEgM1CQoKKQoEBQAC
BRIDOAIKGhwgVGhlIGRheSBzdGFydHMgYXQgMTI6MDBhbS4KCgwKBQUAAgUBEgM4AgUKDAoF
BQACBQISAzgICQosCgIFARIEPABFARogIFJlc291cmNlQWxsb3dhbmNlIHZhbGlkIHN0YXRl
LgoKCgoDBQEBEgM8BRsKGwoEBQECABIDPgIrGg4gVW5zcGVjaWZpZWQuCgoMCgUFAQIAARID
PgImCgwKBQUBAgACEgM+KSoKNgoEBQECARIDQQIgGikgUmVzb3VyY2VBbGxvd2FuY2UgaXMg
YWN0aXZlIGFuZCBpbiB1c2UuCgoMCgUFAQIBARIDQQIbCgwKBQUBAgECEgNBHh8KMgoEBQEC
AhIDRAIiGiUgUmVzb3VyY2VBbGxvd2FuY2UgbGltaXQgaXMgcmVhY2hlZC4KCgwKBQUBAgIB
EgNEAh0KDAoFBQECAgISA0QgIQqYAQoCBAASBEoAeAEaiwEgVGhlIFJlc291cmNlIEFsbG93
YW5jZSBkZXNjcmlwdGlvbiBmb3IgQ2xvdWQgQmF0Y2guCiBPbmx5IG9uZSBSZXNvdXJjZSBB
bGxvd2FuY2UgaXMgc3VwcG9ydGVkIG5vdyB1bmRlciBhIHNwZWNpZmljIGxvY2F0aW9uIGFu
ZAogcHJvamVjdC4KCgoKAwQAARIDSggZCgsKAwQABxIESwJQBAoNCgUEAAedCBIESwJQBAop
CgQEAAgAEgRTAlYDGhsgUmVzb3VyY2VBbGxvd2FuY2UgZGV0YWlsLgoKDAoFBAAIAAESA1MI
Ggo2CgQEAAIAEgNVBDgaKSBUaGUgZGV0YWlsIG9mIHVzYWdlIHJlc291cmNlIGFsbG93YW5j
ZS4KCgwKBQQAAgAGEgNVBBoKDAoFBAACAAESA1UbMwoMCgUEAAIAAxIDVTY3CpMBCgQEAAIB
EgNbAj0ahQEgSWRlbnRpZmllci4gUmVzb3VyY2VBbGxvd2FuY2UgbmFtZS4KIEZvciBleGFt
cGxlOgogInByb2plY3RzLzEyMzQ1Ni9sb2NhdGlvbnMvdXMtY2VudHJhbDEvcmVzb3VyY2VB
bGxvd2FuY2VzL3Jlc291cmNlLWFsbG93YW5jZS0xIi4KCgwKBQQAAgEFEgNbAggKDAoFBAAC
AQESA1sJDQoMCgUEAAIBAxIDWxARCgwKBQQAAgEIEgNbEjwKDwoIBAACAQicCAASA1sTOwpn
CgQEAAICEgRfAmIEGlkgT3V0cHV0IG9ubHkuIEEgc3lzdGVtIGdlbmVyYXRlZCB1bmlxdWUg
SUQgKGluIFVVSUQ0IGZvcm1hdCkgZm9yIHRoZQogUmVzb3VyY2VBbGxvd2FuY2UuCgoMCgUE
AAICBRIDXwIICgwKBQQAAgIBEgNfCQwKDAoFBAACAgMSA18PEAoNCgUEAAICCBIEXxFiAwoS
CgsEAAICCMzx+YoBARIDYAQqCg8KCAQAAgIInAgAEgNhBC0KSQoEBAACAxIEZQJmMho7IE91
dHB1dCBvbmx5LiBUaW1lIHdoZW4gdGhlIFJlc291cmNlQWxsb3dhbmNlIHdhcyBjcmVhdGVk
LgoKDAoFBAACAwYSA2UCGwoMCgUEAAIDARIDZRwnCgwKBQQAAgMDEgNlKisKDAoFBAACAwgS
A2YGMQoPCggEAAIDCJwIABIDZgcwCpYECgQEAAIEEgNzAkoaiAQgT3B0aW9uYWwuIExhYmVs
cyBhcmUgYXR0cmlidXRlcyB0aGF0IGNhbiBiZSBzZXQgYW5kIHVzZWQgYnkgYm90aCB0aGUK
IHVzZXIgYW5kIGJ5IEJhdGNoLiBMYWJlbHMgbXVzdCBtZWV0IHRoZSBmb2xsb3dpbmcgY29u
c3RyYWludHM6CgogKiBLZXlzIGFuZCB2YWx1ZXMgY2FuIGNvbnRhaW4gb25seSBsb3dlcmNh
c2UgbGV0dGVycywgbnVtZXJpYyBjaGFyYWN0ZXJzLAogdW5kZXJzY29yZXMsIGFuZCBkYXNo
ZXMuCiAqIEFsbCBjaGFyYWN0ZXJzIG11c3QgdXNlIFVURi04IGVuY29kaW5nLCBhbmQgaW50
ZXJuYXRpb25hbCBjaGFyYWN0ZXJzIGFyZQogYWxsb3dlZC4KICogS2V5cyBtdXN0IHN0YXJ0
IHdpdGggYSBsb3dlcmNhc2UgbGV0dGVyIG9yIGludGVybmF0aW9uYWwgY2hhcmFjdGVyLgog
KiBFYWNoIHJlc291cmNlIGlzIGxpbWl0ZWQgdG8gYSBtYXhpbXVtIG9mIDY0IGxhYmVscy4K
CiBCb3RoIGtleXMgYW5kIHZhbHVlcyBhcmUgYWRkaXRpb25hbGx5IGNvbnN0cmFpbmVkIHRv
IGJlIDw9IDEyOCBieXRlcy4KCgwKBQQAAgQGEgNzAhUKDAoFBAACBAESA3MWHAoMCgUEAAIE
AxIDcx8gCgwKBQQAAgQIEgNzIUkKDwoIBAACBAicCAASA3MiSAo2CgQEAAIFEgR2AncvGigg
T3B0aW9uYWwuIE5vdGlmaWNhdGlvbiBjb25maWd1cmF0aW9ucy4KCgwKBQQAAgUEEgN2AgoK
DAoFBAACBQYSA3YLFwoMCgUEAAIFARIDdhglCgwKBQQAAgUDEgN2KCkKDAoFBAACBQgSA3cG
LgoPCggEAAIFCJwIABIDdwctClcKAgQBEgV7AIIBARpKIFVzYWdlUmVzb3VyY2VBbGxvd2Fu
Y2UgZGVzY3JpYmVzIHRoZSBkZXRhaWwgb2YgdXNhZ2UgcmVzb3VyY2UgYWxsb3dhbmNlLgoK
CgoDBAEBEgN7CB4KOwoEBAECABIDfQJPGi4gUmVxdWlyZWQuIFNwZWMgb2YgYSB1c2FnZSBS
ZXNvdXJjZUFsbG93YW5jZS4KCgwKBQQBAgAGEgN9AhwKDAoFBAECAAESA30dIQoMCgUEAQIA
AxIDfSQlCgwKBQQBAgAIEgN9Jk4KDwoIBAECAAicCAASA30nTQpDCgQEAQIBEgaAAQKBATIa
MyBPdXRwdXQgb25seS4gU3RhdHVzIG9mIGEgdXNhZ2UgUmVzb3VyY2VBbGxvd2FuY2UuCgoN
CgUEAQIBBhIEgAECHgoNCgUEAQIBARIEgAEfJQoNCgUEAQIBAxIEgAEoKQoNCgUEAQIBCBIE
gQEGMQoQCggEAQIBCJwIABIEgQEHMAoyCgIEAhIGhQEAogEBGiQgU3BlYyBvZiBhIHVzYWdl
IFJlc291cmNlQWxsb3dhbmNlLgoKCwoDBAIBEgSFAQgiCjQKBAQCAwASBocBApgBAxokIFVz
YWdlUmVzb3VyY2VBbGxvd2FuY2UgbGltaXRhdGlvbi4KCg0KBQQCAwABEgSHAQoPChAKBgQC
AwAIABIGiAEEjQEFCg8KBwQCAwAIAAESBIgBChIKfAoGBAIDAAIAEgaLAQaMATMaaiBPcHRp
b25hbC4gQSBDYWxlbmRhclBlcmlvZCByZXByZXNlbnRzIHRoZSBhYnN0cmFjdCBjb25jZXB0
IG9mIGEgdGltZQogcGVyaW9kIHRoYXQgaGFzIGEgY2Fub25pY2FsIHN0YXJ0LgoKDwoHBAID
AAIABhIEiwEGFAoPCgcEAgMAAgABEgSLARUkCg8KBwQCAwACAAMSBIsBJygKDwoHBAIDAAIA
CBIEjAEKMgoSCgoEAgMAAgAInAgAEgSMAQsxCoQDCgYEAgMAAgESBJcBBEca8wIgUmVxdWly
ZWQuIExpbWl0IHZhbHVlIG9mIGEgVXNhZ2VSZXNvdXJjZUFsbG93YW5jZSB3aXRoaW4gaXRz
IG9uZQogZHVyYXRpb24uCgogTGltaXQgY2Fubm90IGJlIGEgbmVnYXRpdmUgdmFsdWUuIERl
ZmF1bHQgaXMgMC4KIEZvciBleGFtcGxlLCB5b3UgY2FuIHNldCBgbGltaXRgIGFzIDEwMDAw
LjAgd2l0aCBkdXJhdGlvbiBvZiB0aGUgY3VycmVudAogbW9udGggYnkgc2V0dGluZyBgY2Fs
ZW5kYXJfcGVyaW9kYCBmaWVsZCBhcyBtb250aGx5LiBUaGF0IG1lYW5zIGluIHlvdXIKIGN1
cnJlbnQgbW9udGgsIDEwMDAwLjAgaXMgdGhlIGNvcmUgaG91ciBsaW1pdGF0aW9uIHRoYXQg
eW91ciByZXNvdXJjZXMKIGFyZSBhbGxvd2VkIHRvIGNvbnN1bWUuCgoPCgcEAgMAAgEEEgSX
AQQMCg8KBwQCAwACAQUSBJcBDRMKDwoHBAIDAAIBARIElwEUGQoPCgcEAgMAAgEDEgSXARwd
Cg8KBwQCAwACAQgSBJcBHkYKEgoKBAIDAAIBCJwIABIElwEfRQqnAQoEBAICABIEnQECOxqY
ASBSZXF1aXJlZC4gU3BlYyB0eXBlIGlzIHVuaXF1ZSBmb3IgZWFjaCB1c2FnZSBSZXNvdXJj
ZUFsbG93YW5jZS4KIEJhdGNoIG5vdyBvbmx5IHN1cHBvcnRzIHR5cGUgYXMgImNwdS1jb3Jl
LWhvdXJzIiBmb3IgQ1BVIHVzYWdlIGNvbnN1bXB0aW9uCiB0cmFja2luZy4KCg0KBQQCAgAF
EgSdAQIICg0KBQQCAgABEgSdAQkNCg0KBQQCAgADEgSdARARCg0KBQQCAgAIEgSdARI6ChAK
CAQCAgAInAgAEgSdARM5CnsKBAQCAgESBKEBAjsabSBSZXF1aXJlZC4gVGhyZXNob2xkIG9m
IGEgVXNhZ2VSZXNvdXJjZUFsbG93YW5jZSBsaW1pdGluZyBob3cgbWFueSByZXNvdXJjZXMK
IGNhbiBiZSBjb25zdW1lZCBmb3IgZWFjaCB0eXBlLgoKDQoFBAICAQYSBKEBAgcKDQoFBAIC
AQESBKEBCA0KDQoFBAICAQMSBKEBEBEKDQoFBAICAQgSBKEBEjoKEAoIBAICAQicCAASBKEB
EzkKNAoCBAMSBqUBAM8BARomIFN0YXR1cyBvZiBhIHVzYWdlIFJlc291cmNlQWxsb3dhbmNl
LgoKCwoDBAMBEgSlAQgkCk4KBAQDAwASBqcBArIBAxo+IFVzYWdlUmVzb3VyY2VBbGxvd2Fu
Y2VTdGF0dXMgZGV0YWlsIGFib3V0IHVzYWdlIGNvbnN1bXB0aW9uLgoKDQoFBAMDAAESBKcB
ChUKOgoGBAMDAAIAEgapAQSqATQaKCBPdXRwdXQgb25seS4gVGhlIGNvbnN1bXB0aW9uIGlu
dGVydmFsLgoKDwoHBAMDAAIABhIEqQEEGAoPCgcEAwMAAgABEgSpARktCg8KBwQDAwACAAMS
BKkBMDEKDwoHBAMDAAIACBIEqgEIMwoSCgoEAwMAAgAInAgAEgSqAQkyCmAKBgQDAwACARIE
rgEEShpQIE91dHB1dCBvbmx5LiBMaW1pdCB2YWx1ZSBvZiBhIFVzYWdlUmVzb3VyY2VBbGxv
d2FuY2Ugd2l0aGluIGl0cyBvbmUKIGR1cmF0aW9uLgoKDwoHBAMDAAIBBBIErgEEDAoPCgcE
AwMAAgEFEgSuAQ0TCg8KBwQDAwACAQESBK4BFBkKDwoHBAMDAAIBAxIErgEcHQoPCgcEAwMA
AgEIEgSuAR5JChIKCgQDAwACAQicCAASBK4BH0gKVQoGBAMDAAICEgSxAQRNGkUgT3V0cHV0
IG9ubHkuIEFjY3VtdWxhdGVkIGNvbnN1bXB0aW9uIGR1cmluZyBgY29uc3VtcHRpb25faW50
ZXJ2YWxgLgoKDwoHBAMDAAICBBIEsQEEDAoPCgcEAwMAAgIFEgSxAQ0TCg8KBwQDAwACAgES
BLEBFBwKDwoHBAMDAAICAxIEsQEfIAoPCgcEAwMAAgIIEgSxASFMChIKCgQDAwACAgicCAAS
BLEBIksKDgoEBAMDARIGtAECuwEDCg0KBQQDAwEBEgS0AQobCjoKBgQDAwECABIGtgEEtwE0
GiggT3V0cHV0IG9ubHkuIFRoZSBjb25zdW1wdGlvbiBpbnRlcnZhbC4KCg8KBwQDAwECAAYS
BLYBBBgKDwoHBAMDAQIAARIEtgEZLQoPCgcEAwMBAgADEgS2ATAxCg8KBwQDAwECAAgSBLcB
CDMKEgoKBAMDAQIACJwIABIEtwEJMgpVCgYEAwMBAgESBLoBBE0aRSBPdXRwdXQgb25seS4g
QWNjdW11bGF0ZWQgY29uc3VtcHRpb24gZHVyaW5nIGBjb25zdW1wdGlvbl9pbnRlcnZhbGAu
CgoPCgcEAwMBAgEEEgS6AQQMCg8KBwQDAwECAQUSBLoBDRMKDwoHBAMDAQIBARIEugEUHAoP
CgcEAwMBAgEDEgS6AR8gCg8KBwQDAwECAQgSBLoBIUwKEgoKBAMDAQIBCJwIABIEugEiSwpm
CgQEAwMCEga/AQLFAQMaViBDb25zdW1wdGlvblJlcG9ydCBpcyB0aGUgcmVwb3J0IG9mIFJl
c291cmNlQWxsb3dhbmNlIGNvbnN1bXB0aW9ucyBpbiBhIHRpbWUKIHBlcmlvZC4KCg0KBQQD
AwIBEgS/AQobCsIBCgYEAwMCAgASBsMBBMQBNBqvASBPdXRwdXQgb25seS4gUmVzb3VyY2VB
bGxvd2FuY2UgY29uc3VtcHRpb25zIGluIHRoZSBsYXRlc3QgY2FsZW5kYXIKIHBlcmlvZC4g
S2V5IGlzIHRoZSBjYWxlbmRhciBwZXJpb2QgaW4gc3RyaW5nIGZvcm1hdC4gQmF0Y2ggY3Vy
cmVudGx5CiBzdXBwb3J0cyBIT1VSLCBEQVksIE1PTlRIIGFuZCBZRUFSLgoKDwoHBAMDAgIA
BhIEwwEEIgoPCgcEAwMCAgABEgTDASM9Cg8KBwQDAwICAAMSBMMBQEEKDwoHBAMDAgIACBIE
xAEIMwoSCgoEAwMCAgAInAgAEgTEAQkyCjUKBAQDAgASBMgBAk8aJyBPdXRwdXQgb25seS4g
UmVzb3VyY2VBbGxvd2FuY2Ugc3RhdGUuCgoNCgUEAwIABhIEyAECGAoNCgUEAwIAARIEyAEZ
HgoNCgUEAwIAAxIEyAEhIgoNCgUEAwIACBIEyAEjTgoQCggEAwIACJwIABIEyAEkTQpWCgQE
AwIBEgTLAQJLGkggT3V0cHV0IG9ubHkuIFJlc291cmNlQWxsb3dhbmNlIGNvbnN1bXB0aW9u
IHN0YXR1cyBmb3IgdXNhZ2UgcmVzb3VyY2VzLgoKDQoFBAMCAQYSBMsBAg0KDQoFBAMCAQES
BMsBDhoKDQoFBAMCAQMSBMsBHR4KDQoFBAMCAQgSBMsBH0oKEAoIBAMCAQicCAASBMsBIEkK
WwoEBAMCAhIEzgECSxpNIE91dHB1dCBvbmx5LiBUaGUgcmVwb3J0IG9mIFJlc291cmNlQWxs
b3dhbmNlIGNvbnN1bXB0aW9ucyBpbiBhIHRpbWUgcGVyaW9kLgoKDQoFBAMCAgYSBM4BAhMK
DQoFBAMCAgESBM4BFBoKDQoFBAMCAgMSBM4BHR4KDQoFBAMCAggSBM4BH0oKEAoIBAMCAgic
CAASBM4BIEliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance ===
    # Fields for ResourceAllowance
    # Field: usage_resource_allowance Type: 11 (.google.cloud.batch.v1alpha.UsageResourceAllowance)
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.batch.v1alpha.ResourceAllowance.LabelsEntry)
    # Field: notifications Type: 11 (.google.cloud.batch.v1alpha.Notification)

# === Message: Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowance ===
    # Fields for UsageResourceAllowance
    # Field: spec Type: 11 (.google.cloud.batch.v1alpha.UsageResourceAllowanceSpec)
    # Field: status Type: 11 (.google.cloud.batch.v1alpha.UsageResourceAllowanceStatus)

# === Message: Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec ===
    # Fields for UsageResourceAllowanceSpec
    # Field: type Type: 9 ()
    # Field: limit Type: 11 (.google.cloud.batch.v1alpha.UsageResourceAllowanceSpec.Limit)

# === Message: Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus ===
    # Fields for UsageResourceAllowanceStatus
    # Field: state Type: 14 (.google.cloud.batch.v1alpha.ResourceAllowanceState)
    # Field: limit_status Type: 11 (.google.cloud.batch.v1alpha.UsageResourceAllowanceStatus.LimitStatus)
    # Field: report Type: 11 (.google.cloud.batch.v1alpha.UsageResourceAllowanceStatus.ConsumptionReport)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Batch::V1alpha::ResourceAllowance - Compiled Protocol Buffers messages for google/cloud/batch/v1alpha/resource_allowance.proto

=head1 SYNOPSIS

    use Google::Cloud::Batch::V1alpha::ResourceAllowance;

    my $msg = Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance->new({
        usage_resource_allowance => $usage_resource_allowance,
        name => $name,
        uid => $uid,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->usage_resource_allowance();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/batch/v1alpha/resource_allowance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance

The Resource Allowance description for Cloud Batch.
Only one Resource Allowance is supported now under a specific location and
project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->usage_resource_allowance() >> / C<< $msg->usage_resource_allowance($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowance>)

The detail of usage resource allowance.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. ResourceAllowance name.
For example:
"projects/123456/locations/us-central1/resourceAllowances/resource-allowance-1".

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A system generated unique ID (in UUID4 format) for the
ResourceAllowance.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the ResourceAllowance was created.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance::LabelsEntry>)

Optional. Labels are attributes that can be set and used by both the
user and by Batch. Labels must meet the following constraints:

* Keys and values can contain only lowercase letters, numeric characters,
underscores, and dashes.
* All characters must use UTF-8 encoding, and international characters are
allowed.
* Keys must start with a lowercase letter or international character.
* Each resource is limited to a maximum of 64 labels.

Both keys and values are additionally constrained to be <= 128 bytes.

=item * C<< $msg->notifications() >> / C<< $msg->notifications($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::Notification::Notification>)

Optional. Notification configurations.

=back

=head2 Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowance

UsageResourceAllowance describes the detail of usage resource allowance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->spec() >> / C<< $msg->spec($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec>)

Required. Spec of a usage ResourceAllowance.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus>)

Output only. Status of a usage ResourceAllowance.

=back

=head2 Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec

Spec of a usage ResourceAllowance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. Spec type is unique for each usage ResourceAllowance.
Batch now only supports type as "cpu-core-hours" for CPU usage consumption
tracking.

=item * C<< $msg->limit() >> / C<< $msg->limit($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec::Limit>)

Required. Threshold of a UsageResourceAllowance limiting how many resources
can be consumed for each type.

=back

=head2 Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus

Status of a usage ResourceAllowance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Batch::V1alpha::ResourceAllowanceState>)

Output only. ResourceAllowance state.

=item * C<< $msg->limit_status() >> / C<< $msg->limit_status($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::LimitStatus>)

Output only. ResourceAllowance consumption status for usage resources.

=item * C<< $msg->report() >> / C<< $msg->report($value) >>

Type: C<Message> (L<Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::ConsumptionReport>)

Output only. The report of ResourceAllowance consumptions in a time period.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Batch::V1alpha::ResourceAllowance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
