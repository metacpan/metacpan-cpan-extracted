package Google::Cloud::Dataplex::V1::Cmek;

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
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dataplex::V1::Service };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvY2xvdWQvZGF0YXBsZXgvdjEvY21lay5wcm90bxIYZ29vZ2xlLmNsb3VkLmRh
dGFwbGV4LnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2Ns
aWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxomZ29vZ2xlL2Nsb3VkL2RhdGFwbGV4L3YxL3NlcnZpY2UucHJv
dG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9i
dWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29n
bGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIvgHChBFbmNyeXB0aW9uQ29uZmlnEkQKBG5h
bWUYASABKAlCMOBBCPpBKgooZGF0YXBsZXguZ29vZ2xlYXBpcy5jb20vRW5jcnlwdGlvbkNv
bmZpZ1IEbmFtZRIVCgNrZXkYAiABKAlCA+BBAVIDa2V5EkAKC2NyZWF0ZV90aW1lGAMgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0
ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVU
aW1lEmoKEGVuY3J5cHRpb25fc3RhdGUYBSABKA4yOi5nb29nbGUuY2xvdWQuZGF0YXBsZXgu
djEuRW5jcnlwdGlvbkNvbmZpZy5FbmNyeXB0aW9uU3RhdGVCA+BBA1IPZW5jcnlwdGlvblN0
YXRlEhIKBGV0YWcYBiABKAlSBGV0YWcSZwoPZmFpbHVyZV9kZXRhaWxzGAcgASgLMjkuZ29v
Z2xlLmNsb3VkLmRhdGFwbGV4LnYxLkVuY3J5cHRpb25Db25maWcuRmFpbHVyZURldGFpbHNC
A+BBA1IOZmFpbHVyZURldGFpbHMSQwobZW5hYmxlX21ldGFzdG9yZV9lbmNyeXB0aW9uGAgg
ASgIQgPgQQFSGWVuYWJsZU1ldGFzdG9yZUVuY3J5cHRpb24a6gEKDkZhaWx1cmVEZXRhaWxz
EmcKCmVycm9yX2NvZGUYASABKA4yQy5nb29nbGUuY2xvdWQuZGF0YXBsZXgudjEuRW5jcnlw
dGlvbkNvbmZpZy5GYWlsdXJlRGV0YWlscy5FcnJvckNvZGVCA+BBA1IJZXJyb3JDb2RlEigK
DWVycm9yX21lc3NhZ2UYAiABKAlCA+BBA1IMZXJyb3JNZXNzYWdlIkUKCUVycm9yQ29kZRIL
CgdVTktOT1dOEAASEgoOSU5URVJOQUxfRVJST1IQARIXChNSRVFVSVJFX1VTRVJfQUNUSU9O
EAIiXgoPRW5jcnlwdGlvblN0YXRlEiAKHEVOQ1JZUFRJT05fU1RBVEVfVU5TUEVDSUZJRUQQ
ABIOCgpFTkNSWVBUSU5HEAESDQoJQ09NUExFVEVEEAISCgoGRkFJTEVEEAM6hwHqQYMBCihk
YXRhcGxleC5nb29nbGVhcGlzLmNvbS9FbmNyeXB0aW9uQ29uZmlnEldvcmdhbml6YXRpb25z
L3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L2VuY3J5cHRpb25Db25maWdz
L3tlbmNyeXB0aW9uX2NvbmZpZ30iggIKHUNyZWF0ZUVuY3J5cHRpb25Db25maWdSZXF1ZXN0
EkwKBnBhcmVudBgBIAEoCUI04EEC+kEuCixkYXRhcGxleC5nb29nbGVhcGlzLmNvbS9Pcmdh
bml6YXRpb25Mb2NhdGlvblIGcGFyZW50EjUKFGVuY3J5cHRpb25fY29uZmlnX2lkGAIgASgJ
QgPgQQJSEmVuY3J5cHRpb25Db25maWdJZBJcChFlbmNyeXB0aW9uX2NvbmZpZxgDIAEoCzIq
Lmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MS5FbmNyeXB0aW9uQ29uZmlnQgPgQQJSEGVuY3J5
cHRpb25Db25maWciYgoaR2V0RW5jcnlwdGlvbkNvbmZpZ1JlcXVlc3QSRAoEbmFtZRgBIAEo
CUIw4EEC+kEqCihkYXRhcGxleC5nb29nbGVhcGlzLmNvbS9FbmNyeXB0aW9uQ29uZmlnUgRu
YW1lIr8BCh1VcGRhdGVFbmNyeXB0aW9uQ29uZmlnUmVxdWVzdBJcChFlbmNyeXB0aW9uX2Nv
bmZpZxgBIAEoCzIqLmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MS5FbmNyeXB0aW9uQ29uZmln
QgPgQQJSEGVuY3J5cHRpb25Db25maWcSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sifgodRGVsZXRlRW5jcnlwdGlv
bkNvbmZpZ1JlcXVlc3QSRAoEbmFtZRgBIAEoCUIw4EEC+kEqCihkYXRhcGxleC5nb29nbGVh
cGlzLmNvbS9FbmNyeXB0aW9uQ29uZmlnUgRuYW1lEhcKBGV0YWcYAiABKAlCA+BBAVIEZXRh
ZyLrAQocTGlzdEVuY3J5cHRpb25Db25maWdzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBB
AvpBKhIoZGF0YXBsZXguZ29vZ2xlYXBpcy5jb20vRW5jcnlwdGlvbkNvbmZpZ1IGcGFyZW50
EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJ
QgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyEh4KCG9yZGVy
X2J5GAUgASgJQgPgQQFSB29yZGVyQnki/wEKHUxpc3RFbmNyeXB0aW9uQ29uZmlnc1Jlc3Bv
bnNlElkKEmVuY3J5cHRpb25fY29uZmlncxgBIAMoCzIqLmdvb2dsZS5jbG91ZC5kYXRhcGxl
eC52MS5FbmNyeXB0aW9uQ29uZmlnUhFlbmNyeXB0aW9uQ29uZmlncxImCg9uZXh0X3BhZ2Vf
dG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SWwoVdW5yZWFjaGFibGVfbG9jYXRpb25zGAMg
AygJQib6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIUdW5yZWFjaGFi
bGVMb2NhdGlvbnMy3goKC0NtZWtTZXJ2aWNlEqACChZDcmVhdGVFbmNyeXB0aW9uQ29uZmln
EjcuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkNyZWF0ZUVuY3J5cHRpb25Db25maWdSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKtAYLT5JMCTyI6L3YxL3twYXJl
bnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qfS9lbmNyeXB0aW9uQ29uZmlnczoRZW5j
cnlwdGlvbl9jb25maWfaQS1wYXJlbnQsZW5jcnlwdGlvbl9jb25maWcsZW5jcnlwdGlvbl9j
b25maWdfaWTKQSUKEEVuY3J5cHRpb25Db25maWcSEU9wZXJhdGlvbk1ldGFkYXRhEqICChZV
cGRhdGVFbmNyeXB0aW9uQ29uZmlnEjcuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLlVwZGF0
ZUVuY3J5cHRpb25Db25maWdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
biKvAYLT5JMCYTJML3YxL3tlbmNyeXB0aW9uX2NvbmZpZy5uYW1lPW9yZ2FuaXphdGlvbnMv
Ki9sb2NhdGlvbnMvKi9lbmNyeXB0aW9uQ29uZmlncy8qfToRZW5jcnlwdGlvbl9jb25maWfa
QR1lbmNyeXB0aW9uX2NvbmZpZyx1cGRhdGVfbWFza8pBJQoQRW5jcnlwdGlvbkNvbmZpZxIR
T3BlcmF0aW9uTWV0YWRhdGES6AEKFkRlbGV0ZUVuY3J5cHRpb25Db25maWcSNy5nb29nbGUu
Y2xvdWQuZGF0YXBsZXgudjEuRGVsZXRlRW5jcnlwdGlvbkNvbmZpZ1JlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uInaC0+STAjwqOi92MS97bmFtZT1vcmdhbml6YXRp
b25zLyovbG9jYXRpb25zLyovZW5jcnlwdGlvbkNvbmZpZ3MvKn3aQQRuYW1lykEqChVnb29n
bGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEtUBChVMaXN0RW5jcnlwdGlv
bkNvbmZpZ3MSNi5nb29nbGUuY2xvdWQuZGF0YXBsZXgudjEuTGlzdEVuY3J5cHRpb25Db25m
aWdzUmVxdWVzdBo3Lmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MS5MaXN0RW5jcnlwdGlvbkNv
bmZpZ3NSZXNwb25zZSJLgtPkkwI8EjovdjEve3BhcmVudD1vcmdhbml6YXRpb25zLyovbG9j
YXRpb25zLyp9L2VuY3J5cHRpb25Db25maWdz2kEGcGFyZW50EsIBChNHZXRFbmNyeXB0aW9u
Q29uZmlnEjQuZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkdldEVuY3J5cHRpb25Db25maWdS
ZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYxLkVuY3J5cHRpb25Db25maWciSYLT
5JMCPBI6L3YxL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9lbmNyeXB0aW9u
Q29uZmlncy8qfdpBBG5hbWUaf8pBF2RhdGFwbGV4Lmdvb2dsZWFwaXMuY29t0kFiaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2RhdGFwbGV4LnJlYWQtd3JpdGVCnQIKHGNvbS5nb29nbGUu
Y2xvdWQuZGF0YXBsZXgudjFCCUNtZWtQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2Rh
dGFwbGV4L2FwaXYxL2RhdGFwbGV4cGI7ZGF0YXBsZXhwYqoCGEdvb2dsZS5DbG91ZC5EYXRh
cGxleC5WMcoCGEdvb2dsZVxDbG91ZFxEYXRhcGxleFxWMeoCG0dvb2dsZTo6Q2xvdWQ6OkRh
dGFwbGV4OjpWMepBYQosZGF0YXBsZXguZ29vZ2xlYXBpcy5jb20vT3JnYW5pemF0aW9uTG9j
YXRpb24SMW9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlv
bn1KukgKBxIFDgC3AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgID
BBIDFgAwCgkKAgMFEgMXAC0KCQoCAwYSAxgAJQoJCgIDBxIDGQAqCgkKAgMIEgMaACkKCAoB
CBIDHAA1CgkKAgglEgMcADUKCAoBCBIDHQBPCgkKAggLEgMdAE8KCAoBCBIDHgAiCgkKAggK
EgMeACIKCAoBCBIDHwAqCgkKAggIEgMfACoKCAoBCBIDIAA1CgkKAggBEgMgADUKCAoBCBID
IQA1CgkKAggpEgMhADUKCAoBCBIDIgA0CgkKAggtEgMiADQKCQoBCBIEIwAmAgoMCgQInQgA
EgQjACYCClgKAgYAEgQpAGoBGkwgRGF0YXBsZXggVW5pdmVyc2FsIENhdGFsb2cgQ3VzdG9t
ZXIgTWFuYWdlZCBFbmNyeXB0aW9uIEtleXMgKENNRUspIFNlcnZpY2UKCgoKAwYAARIDKQgT
CgoKAwYAAxIDKgI/CgwKBQYAA5kIEgMqAj8KCwoDBgADEgQrAi08Cg0KBQYAA5oIEgQrAi08
CisKBAYAAgASBDACPAMaHSBDcmVhdGUgYW4gRW5jcnlwdGlvbkNvbmZpZy4KCgwKBQYAAgAB
EgMwBhwKDAoFBgACAAISAzAdOgoMCgUGAAIAAxIDMQ8rCg0KBQYAAgAEEgQyBDUGChEKCQYA
AgAEsMq8IhIEMgQ1BgoNCgUGAAIABBIENgQ3OAoQCggGAAIABJsIABIENgQ3OAoNCgUGAAIA
BBIEOAQ7BgoPCgcGAAIABJkIEgQ4BDsGCisKBAYAAgESBD8CSgMaHSBVcGRhdGUgYW4gRW5j
cnlwdGlvbkNvbmZpZy4KCgwKBQYAAgEBEgM/BhwKDAoFBgACAQISAz8dOgoMCgUGAAIBAxID
QA8rCg0KBQYAAgEEEgRBBEQGChEKCQYAAgEEsMq8IhIEQQREBgoMCgUGAAIBBBIDRQRLCg8K
CAYAAgEEmwgAEgNFBEsKDQoFBgACAQQSBEYESQYKDwoHBgACAQSZCBIERgRJBgorCgQGAAIC
EgRNAlcDGh0gRGVsZXRlIGFuIEVuY3J5cHRpb25Db25maWcuCgoMCgUGAAICARIDTQYcCgwK
BQYAAgICEgNNHToKDAoFBgACAgMSA04PKwoNCgUGAAICBBIETwRRBgoRCgkGAAICBLDKvCIS
BE8EUQYKDAoFBgACAgQSA1IEMgoPCggGAAICBJsIABIDUgQyCg0KBQYAAgIEEgRTBFYGCg8K
BwYAAgIEmQgSBFMEVgYKJwoEBgACAxIEWgJgAxoZIExpc3QgRW5jcnlwdGlvbkNvbmZpZ3Mu
CgoMCgUGAAIDARIDWgYbCgwKBQYAAgMCEgNaHDgKDAoFBgACAwMSA1sPLAoNCgUGAAIDBBIE
XAReBgoRCgkGAAIDBLDKvCISBFwEXgYKDAoFBgACAwQSA18ENAoPCggGAAIDBJsIABIDXwQ0
CigKBAYAAgQSBGMCaQMaGiBHZXQgYW4gRW5jcnlwdGlvbkNvbmZpZy4KCgwKBQYAAgQBEgNj
BhkKDAoFBgACBAISA2MaNAoMCgUGAAIEAxIDZA8fCg0KBQYAAgQEEgRlBGcGChEKCQYAAgQE
sMq8IhIEZQRnBgoMCgUGAAIEBBIDaAQyCg8KCAYAAgQEmwgAEgNoBDIKiQEKAgQAEgVuAMMB
ARp8IEEgUmVzb3VyY2UgZGVzaWduZWQgdG8gbWFuYWdlIGVuY3J5cHRpb24gY29uZmlndXJh
dGlvbnMgZm9yIGN1c3RvbWVycyB0bwogc3VwcG9ydCBDdXN0b21lciBNYW5hZ2VkIEVuY3J5
cHRpb24gS2V5cyAoQ01FSykuCgoKCgMEAAESA24IGAoLCgMEAAcSBG8CcgQKDQoFBAAHnQgS
BG8CcgQKYwoEBAAEABIFdgKGAQMaVCBTdGF0ZSBvZiBlbmNyeXB0aW9uIG9mIHRoZSBkYXRh
YmFzZXMgd2hlbiBFbmNyeXB0aW9uQ29uZmlnIGlzIGNyZWF0ZWQgb3IKIHVwZGF0ZWQuCgoM
CgUEAAQAARIDdgcWCigKBgQABAACABIDeAQlGhkgU3RhdGUgaXMgbm90IHNwZWNpZmllZC4K
Cg4KBwQABAACAAESA3gEIAoOCgcEAAQAAgACEgN4IyQKwwEKBgQABAACARIDfQQTGrMBIFRo
ZSBlbmNyeXB0aW9uIHN0YXRlIG9mIHRoZSBkYXRhYmFzZSB3aGVuIHRoZSBFbmNyeXB0aW9u
Q29uZmlnIGlzIGNyZWF0ZWQKIG9yIHVwZGF0ZWQuIElmIHRoZSBlbmNyeXB0aW9uIGZhaWxz
LCBpdCBpcyByZXRyaWVkIGluZGVmaW5pdGVseSBhbmQgdGhlCiBzdGF0ZSBpcyBzaG93biBh
cyBFTkNSWVBUSU5HLgoKDgoHBAAEAAIBARIDfQQOCg4KBwQABAACAQISA30REgpECgYEAAQA
AgISBIABBBIaNCBUaGUgZW5jcnlwdGlvbiBvZiBkYXRhIGhhcyBjb21wbGV0ZWQgc3VjY2Vz
c2Z1bGx5LgoKDwoHBAAEAAICARIEgAEEDQoPCgcEAAQAAgICEgSAARARCqQBCgYEAAQAAgMS
BIUBBA8akwEgVGhlIGVuY3J5cHRpb24gb2YgZGF0YSBoYXMgZmFpbGVkLgogVGhlIHN0YXRl
IGlzIHNldCB0byBGQUlMRUQgd2hlbiB0aGUgZW5jcnlwdGlvbiBmYWlscyBkdWUgdG8gcmVh
c29ucyBsaWtlCiBwZXJtaXNzaW9uIGlzc3VlcywgaW52YWxpZCBrZXkgZXRjLgoKDwoHBAAE
AAIDARIEhQEECgoPCgcEAAQAAgMCEgSFAQ0OCk4KBAQAAwASBokBApwBAxo+IERldGFpbHMg
b2YgdGhlIGZhaWx1cmUgaWYgYW55dGhpbmcgcmVsYXRlZCB0byBDbWVrIGRiIGZhaWxzLgoK
DQoFBAADAAESBIkBChgKVAoGBAADAAQAEgaLAQSUAQUaQiBFcnJvciBjb2RlIGZvciB0aGUg
ZmFpbHVyZSBpZiBhbnl0aGluZyByZWxhdGVkIHRvIENtZWsgZGIgZmFpbHMuCgoPCgcEAAMA
BAABEgSLAQkSCjMKCAQAAwAEAAIAEgSNAQYSGiEgVGhlIGVycm9yIGNvZGUgaXMgbm90IHNw
ZWNpZmllZAoKEQoJBAADAAQAAgABEgSNAQYNChEKCQQAAwAEAAIAAhIEjQEQEQpaCggEAAMA
BAACARIEkAEGGRpIIEVycm9yIGJlY2F1c2Ugb2YgaW50ZXJuYWwgc2VydmVyIGVycm9yLCB3
aWxsIGJlIHJldHJpZWQgYXV0b21hdGljYWxseS4KChEKCQQAAwAEAAIBARIEkAEGFAoRCgkE
AAMABAACAQISBJABFxgKQQoIBAADAAQAAgISBJMBBh4aLyBVc2VyIGFjdGlvbiBpcyByZXF1
aXJlZCB0byByZXNvbHZlIHRoZSBlcnJvci4KChEKCQQAAwAEAAICARIEkwEGGQoRCgkEAAMA
BAACAgISBJMBHB0KPgoGBAADAAIAEgSXAQRJGi4gT3V0cHV0IG9ubHkuIFRoZSBlcnJvciBj
b2RlIGZvciB0aGUgZmFpbHVyZS4KCg8KBwQAAwACAAYSBJcBBA0KDwoHBAADAAIAARIElwEO
GAoPCgcEAAMAAgADEgSXARscCg8KBwQAAwACAAgSBJcBHUgKEgoKBAADAAIACJwIABIElwEe
Rwp/CgYEAAMAAgESBJsBBEkabyBPdXRwdXQgb25seS4gVGhlIGVycm9yIG1lc3NhZ2Ugd2ls
bCBiZSBzaG93biB0byB0aGUgdXNlci4gU2V0IG9ubHkgaWYgdGhlCiBlcnJvciBjb2RlIGlz
IFJFUVVJUkVfVVNFUl9BQ1RJT04uCgoPCgcEAAMAAgEFEgSbAQQKCg8KBwQAAwACAQESBJsB
CxgKDwoHBAADAAIBAxIEmwEbHAoPCgcEAAMAAgEIEgSbAR1IChIKCgQAAwACAQicCAASBJsB
HkcKzgEKBAQAAgASBqIBAqcBBBq9ASBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgRW5jcnlwdGlvbkNvbmZpZy4KIEZvcm1hdDoKIG9yZ2FuaXphdGlvbnMve29yZ2Fu
aXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZW5jcnlwdGlvbkNvbmZpZ3Mve2VuY3J5
cHRpb25fY29uZmlnfQogR2xvYmFsIGxvY2F0aW9uIGlzIG5vdCBzdXBwb3J0ZWQuCgoNCgUE
AAIABRIEogECCAoNCgUEAAIAARIEogEJDQoNCgUEAAIAAxIEogEQEQoPCgUEAAIACBIGogES
pwEDChAKCAQAAgAInAgAEgSjAQQsChEKBwQAAgAInwgSBqQBBKYBBQqxAQoEBAACARIErAEC
OhqiASBPcHRpb25hbC4gSWYgYSBrZXkgaXMgY2hvc2VuLCBpdCBtZWFucyB0aGF0IHRoZSBj
dXN0b21lciBpcyB1c2luZyBDTUVLLgogSWYgYSBrZXkgaXMgbm90IGNob3NlbiwgaXQgbWVh
bnMgdGhhdCB0aGUgY3VzdG9tZXIgaXMgdXNpbmcgR29vZ2xlIG1hbmFnZWQKIGVuY3J5cHRp
b24uCgoNCgUEAAIBBRIErAECCAoNCgUEAAIBARIErAEJDAoNCgUEAAIBAxIErAEPEAoNCgUE
AAIBCBIErAEROQoQCggEAAIBCJwIABIErAESOApWCgQEAAICEgavAQKwATIaRiBPdXRwdXQg
b25seS4gVGhlIHRpbWUgd2hlbiB0aGUgRW5jcnlwdGlvbiBjb25maWd1cmF0aW9uIHdhcyBj
cmVhdGVkLgoKDQoFBAACAgYSBK8BAhsKDQoFBAACAgESBK8BHCcKDQoFBAACAgMSBK8BKisK
DQoFBAACAggSBLABBjEKEAoIBAACAgicCAASBLABBzAKWwoEBAACAxIGswECtAEyGksgT3V0
cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIEVuY3J5cHRpb24gY29uZmlndXJhdGlvbiB3
YXMgbGFzdCB1cGRhdGVkLgoKDQoFBAACAwYSBLMBAhsKDQoFBAACAwESBLMBHCcKDQoFBAAC
AwMSBLMBKisKDQoFBAACAwgSBLQBBjEKEAoIBAACAwicCAASBLQBBzAKSAoEBAACBBIGtwEC
uAEyGjggT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiBlbmNyeXB0aW9uIG9mIHRoZSBkYXRh
YmFzZXMuCgoNCgUEAAIEBhIEtwECEQoNCgUEAAIEARIEtwESIgoNCgUEAAIEAxIEtwElJgoN
CgUEAAIECBIEuAEGMQoQCggEAAIECJwIABIEuAEHMApECgQEAAIFEgS7AQISGjYgRXRhZyBv
ZiB0aGUgRW5jcnlwdGlvbkNvbmZpZy4gVGhpcyBpcyBhIHN0cm9uZyBldGFnLgoKDQoFBAAC
BQUSBLsBAggKDQoFBAACBQESBLsBCQ0KDQoFBAACBQMSBLsBEBEKWwoEBAACBhIGvgECvwEy
GksgT3V0cHV0IG9ubHkuIERldGFpbHMgb2YgdGhlIGZhaWx1cmUgaWYgYW55dGhpbmcgcmVs
YXRlZCB0byBDbWVrIGRiIGZhaWxzLgoKDQoFBAACBgYSBL4BAhAKDQoFBAACBgESBL4BESAK
DQoFBAACBgMSBL4BIyQKDQoFBAACBggSBL8BBjEKEAoIBAACBgicCAASBL8BBzAKSwoEBAAC
BxIEwgECUBo9IE9wdGlvbmFsLiBSZXByZXNlbnQgdGhlIHN0YXRlIG9mIENNRUsgb3B0LWlu
IGZvciBtZXRhc3RvcmUuCgoNCgUEAAIHBRIEwgECBgoNCgUEAAIHARIEwgEHIgoNCgUEAAIH
AxIEwgElJgoNCgUEAAIHCBIEwgEnTwoQCggEAAIHCJwIABIEwgEoTgovCgIEARIGxgEA1wEB
GiEgQ3JlYXRlIEVuY3J5cHRpb25Db25maWcgUmVxdWVzdAoKCwoDBAEBEgTGAQglClgKBAQB
AgASBsgBAs0BBBpIIFJlcXVpcmVkLiBUaGUgbG9jYXRpb24gYXQgd2hpY2ggdGhlIEVuY3J5
cHRpb25Db25maWcgaXMgdG8gYmUgY3JlYXRlZC4KCg0KBQQBAgAFEgTIAQIICg0KBQQBAgAB
EgTIAQkPCg0KBQQBAgADEgTIARITCg8KBQQBAgAIEgbIARTNAQMKEAoIBAECAAicCAASBMkB
BCoKEQoHBAECAAifCBIGygEEzAEFCqYBCgQEAQIBEgTSAQJLGpcBIFJlcXVpcmVkLiBUaGUg
SUQgb2YgdGhlCiBbRW5jcnlwdGlvbkNvbmZpZ11bZ29vZ2xlLmNsb3VkLmRhdGFwbGV4LnYx
LkVuY3J5cHRpb25Db25maWddIHRvIGNyZWF0ZS4KIEN1cnJlbnRseSwgb25seSBhIHZhbHVl
IG9mICJkZWZhdWx0IiBpcyBzdXBwb3J0ZWQuCgoNCgUEAQIBBRIE0gECCAoNCgUEAQIBARIE
0gEJHQoNCgUEAQIBAxIE0gEgIQoNCgUEAQIBCBIE0gEiSgoQCggEAQIBCJwIABIE0gEjSQo7
CgQEAQICEgbVAQLWAS8aKyBSZXF1aXJlZC4gVGhlIEVuY3J5cHRpb25Db25maWcgdG8gY3Jl
YXRlLgoKDQoFBAECAgYSBNUBAhIKDQoFBAECAgESBNUBEyQKDQoFBAECAgMSBNUBJygKDQoF
BAECAggSBNYBBi4KEAoIBAECAgicCAASBNYBBy0KLAoCBAISBtoBAOIBARoeIEdldCBFbmNy
eXB0aW9uQ29uZmlnIFJlcXVlc3QKCgsKAwQCARIE2gEIIgpGCgQEAgIAEgbcAQLhAQQaNiBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIEVuY3J5cHRpb25Db25maWcgdG8gZmV0Y2guCgoN
CgUEAgIABRIE3AECCAoNCgUEAgIAARIE3AEJDQoNCgUEAgIAAxIE3AEQEQoPCgUEAgIACBIG
3AES4QEDChAKCAQCAgAInAgAEgTdAQQqChEKBwQCAgAInwgSBt4BBOABBQovCgIEAxIG5QEA
7wEBGiEgVXBkYXRlIEVuY3J5cHRpb25Db25maWcgUmVxdWVzdAoKCwoDBAMBEgTlAQglCjsK
BAQDAgASBucBAugBLxorIFJlcXVpcmVkLiBUaGUgRW5jcnlwdGlvbkNvbmZpZyB0byB1cGRh
dGUuCgoNCgUEAwIABhIE5wECEgoNCgUEAwIAARIE5wETJAoNCgUEAwIAAxIE5wEnKAoNCgUE
AwIACBIE6AEGLgoQCggEAwIACJwIABIE6AEHLQrAAQoEBAMCARIG7QEC7gEvGq8BIE9wdGlv
bmFsLiBNYXNrIG9mIGZpZWxkcyB0byB1cGRhdGUuCiBUaGUgc2VydmljZSB0cmVhdHMgYW4g
b21pdHRlZCBmaWVsZCBtYXNrIGFzIGFuIGltcGxpZWQgZmllbGQgbWFzawogZXF1aXZhbGVu
dCB0byBhbGwgZmllbGRzIHRoYXQgYXJlIHBvcHVsYXRlZCAoaGF2ZSBhIG5vbi1lbXB0eSB2
YWx1ZSkuCgoNCgUEAwIBBhIE7QECGwoNCgUEAwIBARIE7QEcJwoNCgUEAwIBAxIE7QEqKwoN
CgUEAwIBCBIE7gEGLgoQCggEAwIBCJwIABIE7gEHLQovCgIEBBIG8gEA/QEBGiEgRGVsZXRl
IEVuY3J5cHRpb25Db25maWcgUmVxdWVzdAoKCwoDBAQBEgTyAQglCkcKBAQEAgASBvQBAvkB
BBo3IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgRW5jcnlwdGlvbkNvbmZpZyB0byBkZWxl
dGUuCgoNCgUEBAIABRIE9AECCAoNCgUEBAIAARIE9AEJDQoNCgUEBAIAAxIE9AEQEQoPCgUE
BAIACBIG9AES+QEDChAKCAQEAgAInAgAEgT1AQQqChEKBwQEAgAInwgSBvYBBPgBBQpOCgQE
BAIBEgT8AQI7GkAgT3B0aW9uYWwuIEV0YWcgb2YgdGhlIEVuY3J5cHRpb25Db25maWcuIFRo
aXMgaXMgYSBzdHJvbmcgZXRhZy4KCg0KBQQEAgEFEgT8AQIICg0KBQQEAgEBEgT8AQkNCg0K
BQQEAgEDEgT8ARARCg0KBQQEAgEIEgT8ARI6ChAKCAQEAgEInAgAEgT8ARM5Ci4KAgQFEgaA
AgCoAgEaICBMaXN0IEVuY3J5cHRpb25Db25maWdzIFJlcXVlc3QKCgsKAwQFARIEgAIIJApY
CgQEBQIAEgaCAgKHAgQaSCBSZXF1aXJlZC4gVGhlIGxvY2F0aW9uIGZvciB3aGljaCB0aGUg
RW5jcnlwdGlvbkNvbmZpZyBpcyB0byBiZSBsaXN0ZWQuCgoNCgUEBQIABRIEggICCAoNCgUE
BQIAARIEggIJDwoNCgUEBQIAAxIEggISEwoPCgUEBQIACBIGggIUhwIDChAKCAQFAgAInAgA
EgSDAgQqChEKBwQFAgAInwgSBoQCBIYCBQr/AQoEBAUCARIEjQICPxrwASBPcHRpb25hbC4g
TWF4aW11bSBudW1iZXIgb2YgRW5jcnlwdGlvbkNvbmZpZ3MgdG8gcmV0dXJuLiBUaGUgc2Vy
dmljZSBtYXkKIHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuIElmIHVuc3BlY2lmaWVk
LCBhdCBtb3N0IDEwIEVuY3J5cHRpb25Db25maWdzCiB3aWxsIGJlIHJldHVybmVkLiBUaGUg
bWF4aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlCiBjb2Vy
Y2VkIHRvIDEwMDAuCgoNCgUEBQIBBRIEjQICBwoNCgUEBQIBARIEjQIIEQoNCgUEBQIBAxIE
jQIUFQoNCgUEBQIBCBIEjQIWPgoQCggEBQIBCJwIABIEjQIXPQqZAgoEBAUCAhIEkwICQRqK
AiBPcHRpb25hbC4gUGFnZSB0b2tlbiByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RF
bmNyeXB0aW9uQ29uZmlnc2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUg
c3Vic2VxdWVudCBwYWdlLiBXaGVuIHBhZ2luYXRpbmcsIHRoZQogcGFyYW1ldGVycyAtIGZp
bHRlciBhbmQgb3JkZXJfYnkgcHJvdmlkZWQgdG8gYExpc3RFbmNyeXB0aW9uQ29uZmlnc2Ag
bXVzdAogbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0K
BQQFAgIFEgSTAgIICg0KBQQFAgIBEgSTAgkTCg0KBQQFAgIDEgSTAhYXCg0KBQQFAgIIEgST
AhhAChAKCAQFAgIInAgAEgSTAhk/CroFCgQEBQIDEgSkAgI9GqsFIE9wdGlvbmFsLiBGaWx0
ZXIgdGhlIEVuY3J5cHRpb25Db25maWdzIHRvIGJlIHJldHVybmVkLgogVXNpbmcgYmFyZSBs
aXRlcmFsczogKFRoZXNlIHZhbHVlcyB3aWxsIGJlIG1hdGNoZWQgYW55d2hlcmUgaXQgbWF5
IGFwcGVhcgogaW4gdGhlIG9iamVjdCdzIGZpZWxkIHZhbHVlcykKICogZmlsdGVyPXNvbWVf
dmFsdWUKIFVzaW5nIGZpZWxkczogKFRoZXNlIHZhbHVlcyB3aWxsIGJlIG1hdGNoZWQgb25s
eSBpbiB0aGUgc3BlY2lmaWVkIGZpZWxkKQogKiBmaWx0ZXI9c29tZV9maWVsZD1zb21lX3Zh
bHVlCiBTdXBwb3J0ZWQgZmllbGRzOgogKiBuYW1lLCBrZXksIGNyZWF0ZV90aW1lLCB1cGRh
dGVfdGltZSwgZW5jcnlwdGlvbl9zdGF0ZQogRXhhbXBsZToKICogZmlsdGVyPW5hbWU9b3Jn
YW5pemF0aW9ucy8xMjMvbG9jYXRpb25zL3VzLWNlbnRyYWwxL2VuY3J5cHRpb25Db25maWdz
L3Rlc3QtY29uZmlnCiBjb25qdW5jdGlvbnM6IChBTkQsIE9SLCBOT1QpCiAqIGZpbHRlcj1u
YW1lPW9yZ2FuaXphdGlvbnMvMTIzL2xvY2F0aW9ucy91cy1jZW50cmFsMS9lbmNyeXB0aW9u
Q29uZmlncy90ZXN0LWNvbmZpZwogQU5EIG1vZGU9Q01FSwogbG9naWNhbCBvcGVyYXRvcnM6
ICg+LCA8LCA+PSwgPD0sICE9LCA9LCA6KSwKICogZmlsdGVyPWNyZWF0ZV90aW1lPjIwMjQt
MDUtMDFUMDA6MDA6MDAuMDAwWgoKDQoFBAUCAwUSBKQCAggKDQoFBAUCAwESBKQCCQ8KDQoF
BAUCAwMSBKQCEhMKDQoFBAUCAwgSBKQCFDwKEAoIBAUCAwicCAASBKQCFTsKOQoEBAUCBBIE
pwICPxorIE9wdGlvbmFsLiBPcmRlciBieSBmaWVsZHMgZm9yIHRoZSByZXN1bHQuCgoNCgUE
BQIEBRIEpwICCAoNCgUEBQIEARIEpwIJEQoNCgUEBQIEAxIEpwIUFQoNCgUEBQIECBIEpwIW
PgoQCggEBQIECJwIABIEpwIXPQovCgIEBhIGqwIAtwIBGiEgTGlzdCBFbmNyeXB0aW9uQ29u
ZmlncyBSZXNwb25zZQoKCwoDBAYBEgSrAgglCk4KBAQGAgASBK0CAjMaQCBUaGUgbGlzdCBv
ZiBFbmNyeXB0aW9uQ29uZmlncyB1bmRlciB0aGUgZ2l2ZW4gcGFyZW50IGxvY2F0aW9uLgoK
DQoFBAYCAAQSBK0CAgoKDQoFBAYCAAYSBK0CCxsKDQoFBAYCAAESBK0CHC4KDQoFBAYCAAMS
BK0CMTIKbwoEBAYCARIEsQICHRphIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ug
b2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgaW4g
dGhlIGxpc3QuCgoNCgUEBgIBBRIEsQICCAoNCgUEBgIBARIEsQIJGAoNCgUEBgIBAxIEsQIb
HAo2CgQEBgICEga0AgK2AgUaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hl
ZC4KCg0KBQQGAgIEEgS0AgIKCg0KBQQGAgIFEgS0AgsRCg0KBQQGAgIBEgS0AhInCg0KBQQG
AgIDEgS0AiorCg8KBQQGAgIIEga0Aiy2AgQKEQoHBAYCAgifCBIGtAIttgIDYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig ===
    # Fields for EncryptionConfig
    # Field: name Type: 9 ()
    # Field: key Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: encryption_state Type: 14 (.google.cloud.dataplex.v1.EncryptionConfig.EncryptionState)
    # Field: etag Type: 9 ()
    # Field: failure_details Type: 11 (.google.cloud.dataplex.v1.EncryptionConfig.FailureDetails)
    # Field: enable_metastore_encryption Type: 8 ()

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Cmek;

    my $msg = Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<key>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<encryption_state>

Type: Enum (.google.cloud.dataplex.v1.EncryptionConfig.EncryptionState)

=item * B<etag>

Type: String

=item * B<failure_details>

Type: Message (.google.cloud.dataplex.v1.EncryptionConfig.FailureDetails)

=item * B<enable_metastore_encryption>

Type: Bool

=back

=cut

# Enum: EncryptionConfig::EncryptionState
our $EncryptionConfig_ENCRYPTION_STATE_UNSPECIFIED = 0;
our $EncryptionConfig_ENCRYPTING = 1;
our $EncryptionConfig_COMPLETED = 2;
our $EncryptionConfig_FAILED = 3;

=pod

=head2 Enum: EncryptionConfig::EncryptionState

Values:

=over 4

=item * C<ENCRYPTION_STATE_UNSPECIFIED> => 0

=item * C<ENCRYPTING> => 1

=item * C<COMPLETED> => 2

=item * C<FAILED> => 3

=back

=cut

# === Message: Google::Cloud::Dataplex::V1::Cmek::CreateEncryptionConfigRequest ===
    # Fields for CreateEncryptionConfigRequest
    # Field: parent Type: 9 ()
    # Field: encryption_config_id Type: 9 ()
    # Field: encryption_config Type: 11 (.google.cloud.dataplex.v1.EncryptionConfig)

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::CreateEncryptionConfigRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Cmek;

    my $msg = Google::Cloud::Dataplex::V1::Cmek::CreateEncryptionConfigRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<encryption_config_id>

Type: String

=item * B<encryption_config>

Type: Message (.google.cloud.dataplex.v1.EncryptionConfig)

=back

=cut

# === Message: Google::Cloud::Dataplex::V1::Cmek::GetEncryptionConfigRequest ===
    # Fields for GetEncryptionConfigRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::GetEncryptionConfigRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Cmek;

    my $msg = Google::Cloud::Dataplex::V1::Cmek::GetEncryptionConfigRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Dataplex::V1::Cmek::UpdateEncryptionConfigRequest ===
    # Fields for UpdateEncryptionConfigRequest
    # Field: encryption_config Type: 11 (.google.cloud.dataplex.v1.EncryptionConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::UpdateEncryptionConfigRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Cmek;

    my $msg = Google::Cloud::Dataplex::V1::Cmek::UpdateEncryptionConfigRequest->new(
        encryption_config => $value,
    );

=head1 FIELDS

=over 4

=item * B<encryption_config>

Type: Message (.google.cloud.dataplex.v1.EncryptionConfig)

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=back

=cut

# === Message: Google::Cloud::Dataplex::V1::Cmek::DeleteEncryptionConfigRequest ===
    # Fields for DeleteEncryptionConfigRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::DeleteEncryptionConfigRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Cmek;

    my $msg = Google::Cloud::Dataplex::V1::Cmek::DeleteEncryptionConfigRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<etag>

Type: String

=back

=cut

# === Message: Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsRequest ===
    # Fields for ListEncryptionConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Cmek;

    my $msg = Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=item * B<filter>

Type: String

=item * B<order_by>

Type: String

=back

=cut

# === Message: Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsResponse ===
    # Fields for ListEncryptionConfigsResponse
    # Field: encryption_configs Type: 11 (.google.cloud.dataplex.v1.EncryptionConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable_locations Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::Cmek;

    my $msg = Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsResponse->new(
        encryption_configs => $value,
    );

=head1 FIELDS

=over 4

=item * B<encryption_configs>

Type: Message (.google.cloud.dataplex.v1.EncryptionConfig)

=item * B<next_page_token>

Type: String

=item * B<unreachable_locations>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Dataplex::V1::Cmek::CmekServiceClient ===
package Google::Cloud::Dataplex::V1::Cmek::CmekServiceClient;

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek::CmekServiceClient - Client stub representing the remote CmekService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<dataplex.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataplex.googleapis.com:443' );

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

sub create_encryption_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataplex::V1::Cmek::CreateEncryptionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataplex.v1.CmekService',
        method         => 'CreateEncryptionConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_encryption_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataplex::V1::Cmek::UpdateEncryptionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataplex.v1.CmekService',
        method         => 'UpdateEncryptionConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_encryption_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataplex::V1::Cmek::DeleteEncryptionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataplex.v1.CmekService',
        method         => 'DeleteEncryptionConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_encryption_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataplex.v1.CmekService',
        method         => 'ListEncryptionConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Dataplex::V1::Cmek::ListEncryptionConfigsResponse',
    });
}

sub get_encryption_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataplex::V1::Cmek::GetEncryptionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataplex.v1.CmekService',
        method         => 'GetEncryptionConfig',
        request        => $req,
        response_class => 'Google::Cloud::Dataplex::V1::Cmek::EncryptionConfig',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Cmek - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
