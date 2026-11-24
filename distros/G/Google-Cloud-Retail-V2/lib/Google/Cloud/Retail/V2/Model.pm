package Google::Cloud::Retail::V2::Model;

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
    eval { require Google::Cloud::Retail::V2::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvcmV0YWlsL3YyL21vZGVsLnByb3RvEhZnb29nbGUuY2xvdWQucmV0
YWlsLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jl
c291cmNlLnByb3RvGiNnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2NvbW1vbi5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byK+EAoFTW9kZWwSFwoEbmFtZRgBIAEoCUID
4EECUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRJXCg50
cmFpbmluZ19zdGF0ZRgDIAEoDjIrLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuTW9kZWwuVHJh
aW5pbmdTdGF0ZUID4EEBUg10cmFpbmluZ1N0YXRlElQKDXNlcnZpbmdfc3RhdGUYBCABKA4y
Ki5nb29nbGUuY2xvdWQucmV0YWlsLnYyLk1vZGVsLlNlcnZpbmdTdGF0ZUID4EEDUgxzZXJ2
aW5nU3RhdGUSQAoLY3JlYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBiABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSFwoEdHlwZRgHIAEoCUID4EECUgR0
eXBlEjoKFm9wdGltaXphdGlvbl9vYmplY3RpdmUYCCABKAlCA+BBAVIVb3B0aW1pemF0aW9u
T2JqZWN0aXZlEmoKFXBlcmlvZGljX3R1bmluZ19zdGF0ZRgLIAEoDjIxLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjIuTW9kZWwuUGVyaW9kaWNUdW5pbmdTdGF0ZUID4EEBUhNwZXJpb2RpY1R1
bmluZ1N0YXRlEkUKDmxhc3RfdHVuZV90aW1lGAwgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUgxsYXN0VHVuZVRpbWUSLgoQdHVuaW5nX29wZXJhdGlvbhgPIAEoCUID
4EEDUg90dW5pbmdPcGVyYXRpb24SSwoKZGF0YV9zdGF0ZRgQIAEoDjInLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjIuTW9kZWwuRGF0YVN0YXRlQgPgQQNSCWRhdGFTdGF0ZRJmChBmaWx0ZXJp
bmdfb3B0aW9uGBIgASgOMjYuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5SZWNvbW1lbmRhdGlv
bnNGaWx0ZXJpbmdPcHRpb25CA+BBAVIPZmlsdGVyaW5nT3B0aW9uEmYKFHNlcnZpbmdfY29u
ZmlnX2xpc3RzGBMgAygLMi8uZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Nb2RlbC5TZXJ2aW5n
Q29uZmlnTGlzdEID4EEDUhJzZXJ2aW5nQ29uZmlnTGlzdHMSagoVbW9kZWxfZmVhdHVyZXNf
Y29uZmlnGBYgASgLMjEuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Nb2RlbC5Nb2RlbEZlYXR1
cmVzQ29uZmlnQgPgQQFSE21vZGVsRmVhdHVyZXNDb25maWcaRgoRU2VydmluZ0NvbmZpZ0xp
c3QSMQoSc2VydmluZ19jb25maWdfaWRzGAEgAygJQgPgQQFSEHNlcnZpbmdDb25maWdJZHMa
lAEKJkZyZXF1ZW50bHlCb3VnaHRUb2dldGhlckZlYXR1cmVzQ29uZmlnEmoKFWNvbnRleHRf
cHJvZHVjdHNfdHlwZRgCIAEoDjIxLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuTW9kZWwuQ29u
dGV4dFByb2R1Y3RzVHlwZUID4EEBUhNjb250ZXh0UHJvZHVjdHNUeXBlGsIBChNNb2RlbEZl
YXR1cmVzQ29uZmlnEpEBCiFmcmVxdWVudGx5X2JvdWdodF90b2dldGhlcl9jb25maWcYASAB
KAsyRC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLk1vZGVsLkZyZXF1ZW50bHlCb3VnaHRUb2dl
dGhlckZlYXR1cmVzQ29uZmlnSABSHmZyZXF1ZW50bHlCb3VnaHRUb2dldGhlckNvbmZpZ0IX
ChV0eXBlX2RlZGljYXRlZF9jb25maWciUgoMU2VydmluZ1N0YXRlEh0KGVNFUlZJTkdfU1RB
VEVfVU5TUEVDSUZJRUQQABIMCghJTkFDVElWRRABEgoKBkFDVElWRRACEgkKBVRVTkVEEAMi
SQoNVHJhaW5pbmdTdGF0ZRIeChpUUkFJTklOR19TVEFURV9VTlNQRUNJRklFRBAAEgoKBlBB
VVNFRBABEgwKCFRSQUlOSU5HEAIikAEKE1BlcmlvZGljVHVuaW5nU3RhdGUSJQohUEVSSU9E
SUNfVFVOSU5HX1NUQVRFX1VOU1BFQ0lGSUVEEAASHAoYUEVSSU9ESUNfVFVOSU5HX0RJU0FC
TEVEEAESFwoTQUxMX1RVTklOR19ESVNBQkxFRBADEhsKF1BFUklPRElDX1RVTklOR19FTkFC
TEVEEAIiRAoJRGF0YVN0YXRlEhoKFkRBVEFfU1RBVEVfVU5TUEVDSUZJRUQQABILCgdEQVRB
X09LEAESDgoKREFUQV9FUlJPUhACIncKE0NvbnRleHRQcm9kdWN0c1R5cGUSJQohQ09OVEVY
VF9QUk9EVUNUU19UWVBFX1VOU1BFQ0lGSUVEEAASGgoWU0lOR0xFX0NPTlRFWFRfUFJPRFVD
VBABEh0KGU1VTFRJUExFX0NPTlRFWFRfUFJPRFVDVFMQAjpr6kFoChtyZXRhaWwuZ29vZ2xl
YXBpcy5jb20vTW9kZWwSSXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jYXRhbG9ncy97Y2F0YWxvZ30vbW9kZWxzL3ttb2RlbH1CtQEKGmNvbS5nb29nbGUuY2xv
dWQucmV0YWlsLnYyQgpNb2RlbFByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWls
L2FwaXYyL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIWR29vZ2xlLkNsb3VkLlJldGFp
bC5WMsoCFkdvb2dsZVxDbG91ZFxSZXRhaWxcVjLqAhlHb29nbGU6OkNsb3VkOjpSZXRhaWw6
OlYySvRRCgcSBQ4AlAIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAfCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAtCgkKAgMDEgMVACkKCAoB
CBIDFwAzCgkKAgglEgMXADMKCAoBCBIDGABJCgkKAggLEgMYAEkKCAoBCBIDGQAiCgkKAggK
EgMZACIKCAoBCBIDGgArCgkKAggIEgMaACsKCAoBCBIDGwAzCgkKAggBEgMbADMKCAoBCBID
HAAkCgkKAggkEgMcACQKCAoBCBIDHQAzCgkKAggpEgMdADMKCAoBCBIDHgAyCgkKAggtEgMe
ADIKnAIKAgQAEgUlAJQCARqOAiBNZXRhZGF0YSB0aGF0IGRlc2NyaWJlcyB0aGUgdHJhaW5p
bmcgYW5kIHNlcnZpbmcgcGFyYW1ldGVycyBvZiBhCiBbTW9kZWxdW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuTW9kZWxdLiBBCiBbTW9kZWxdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuTW9k
ZWxdIGNhbiBiZSBhc3NvY2lhdGVkIHdpdGggYQogW1NlcnZpbmdDb25maWddW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjIuU2VydmluZ0NvbmZpZ10gYW5kIHRoZW4gcXVlcmllZAogdGhyb3Vn
aCB0aGUgUHJlZGljdCBBUEkuCgoKCgMEAAESAyUIDQoLCgMEAAcSBCYCKQQKDQoFBAAHnQgS
BCYCKQQKhwEKBAQAAwASBC0CMgMaeSBSZXByZXNlbnRzIGFuIG9yZGVyZWQgY29tYmluYXRp
b24gb2YgdmFsaWQgc2VydmluZyBjb25maWdzLCB3aGljaAogY2FuIGJlIHVzZWQgZm9yIGBQ
QUdFX09QVElNSVpBVElPTmAgcmVjb21tZW5kYXRpb25zLgoKDAoFBAADAAESAy0KGwplCgYE
AAMAAgASBDAEMTEaVSBPcHRpb25hbC4gQSBzZXQgb2YgdmFsaWQgc2VydmluZyBjb25maWdz
IHRoYXQgbWF5IGJlIHVzZWQgZm9yCiBgUEFHRV9PUFRJTUlaQVRJT05gLgoKDgoHBAADAAIA
BBIDMAQMCg4KBwQAAwACAAUSAzANEwoOCgcEAAMAAgABEgMwFCYKDgoHBAADAAIAAxIDMCkq
Cg4KBwQAAwACAAgSAzEIMAoRCgoEAAMAAgAInAgAEgMxCS8KUQoEBAADARIENQI8AxpDIEFk
ZGl0aW9uYWwgY29uZmlncyBmb3IgdGhlIGZyZXF1ZW50bHktYm91Z2h0LXRvZ2V0aGVyIG1v
ZGVsIHR5cGUuCgoMCgUEAAMBARIDNQowCrECCgYEAAMBAgASBDoEOzEaoAIgT3B0aW9uYWwu
IFNwZWNpZmllcyB0aGUgY29udGV4dCBvZiB0aGUgbW9kZWwgd2hlbiBpdCBpcyB1c2VkIGlu
IHByZWRpY3QKIHJlcXVlc3RzLiBDYW4gb25seSBiZSBzZXQgZm9yIHRoZSBgZnJlcXVlbnRs
eS1ib3VnaHQtdG9nZXRoZXJgIHR5cGUuIElmCiBpdCBpc24ndCBzcGVjaWZpZWQsIGl0IGRl
ZmF1bHRzIHRvCiBbTVVMVElQTEVfQ09OVEVYVF9QUk9EVUNUU11bZ29vZ2xlLmNsb3VkLnJl
dGFpbC52Mi5Nb2RlbC5Db250ZXh0UHJvZHVjdHNUeXBlLk1VTFRJUExFX0NPTlRFWFRfUFJP
RFVDVFNdLgoKDgoHBAADAQIABhIDOgQXCg4KBwQAAwECAAESAzoYLQoOCgcEAAMBAgADEgM6
MDEKDgoHBAADAQIACBIDOwgwChEKCgQAAwECAAicCAASAzsJLwoxCgQEAAMCEgQ/AkUDGiMg
QWRkaXRpb25hbCBtb2RlbCBmZWF0dXJlcyBjb25maWcuCgoMCgUEAAMCARIDPwodCg4KBgQA
AwIIABIEQAREBQoOCgcEAAMCCAABEgNACh8KSwoGBAADAgIAEgRCBkMMGjsgQWRkaXRpb25h
bCBjb25maWdzIGZvciBmcmVxdWVudGx5LWJvdWdodC10b2dldGhlciBtb2RlbHMuCgoOCgcE
AAMCAgAGEgNCBiwKDgoHBAADAgIAARIDQi1OCg4KBwQAAwICAAMSA0MKCwovCgQEAAQAEgRI
AlUDGiEgVGhlIHNlcnZpbmcgc3RhdGUgb2YgdGhlIG1vZGVsLgoKDAoFBAAEAAESA0gHEwor
CgYEAAQAAgASA0oEIhocIFVuc3BlY2lmaWVkIHNlcnZpbmcgc3RhdGUuCgoOCgcEAAQAAgAB
EgNKBB0KDgoHBAAEAAIAAhIDSiAhCioKBgQABAACARIDTQQRGhsgVGhlIG1vZGVsIGlzIG5v
dCBzZXJ2aW5nLgoKDgoHBAAEAAIBARIDTQQMCg4KBwQABAACAQISA00PEAo5CgYEAAQAAgIS
A1AEDxoqIFRoZSBtb2RlbCBpcyBzZXJ2aW5nIGFuZCBjYW4gYmUgcXVlcmllZC4KCg4KBwQA
BAACAgESA1AECgoOCgcEAAQAAgICEgNQDQ4KUwoGBAAEAAIDEgNUBA4aRCBUaGUgbW9kZWwg
aXMgdHJhaW5lZCBvbiB0dW5lZCBoeXBlcnBhcmFtZXRlcnMgYW5kIGNhbiBiZQogcXVlcmll
ZC4KCg4KBwQABAACAwESA1QECQoOCgcEAAQAAgMCEgNUDA0KMAoEBAAEARIEWAJhAxoiIFRo
ZSB0cmFpbmluZyBzdGF0ZSBvZiB0aGUgbW9kZWwuCgoMCgUEAAQBARIDWAcUCiwKBgQABAEC
ABIDWgQjGh0gVW5zcGVjaWZpZWQgdHJhaW5pbmcgc3RhdGUuCgoOCgcEAAQBAgABEgNaBB4K
DgoHBAAEAQIAAhIDWiEiCi4KBgQABAECARIDXQQPGh8gVGhlIG1vZGVsIHRyYWluaW5nIGlz
IHBhdXNlZC4KCg4KBwQABAECAQESA10ECgoOCgcEAAQBAgECEgNdDQ4KJwoGBAAEAQICEgNg
BBEaGCBUaGUgbW9kZWwgaXMgdHJhaW5pbmcuCgoOCgcEAAQBAgIBEgNgBAwKDgoHBAAEAQIC
AhIDYA8QCvwCCgQEAAQCEgRpAnsDGu0CIERlc2NyaWJlcyB3aGV0aGVyIHBlcmlvZGljIHR1
bmluZyBpcyBlbmFibGVkIGZvciB0aGlzIG1vZGVsCiBvciBub3QuIFBlcmlvZGljIHR1bmlu
ZyBpcyBzY2hlZHVsZWQgYXQgbW9zdCBldmVyeSB0aHJlZSBtb250aHMuIFlvdSBjYW4KIHN0
YXJ0IGEgdHVuaW5nIHByb2Nlc3MgbWFudWFsbHkgYnkgdXNpbmcgdGhlIGBUdW5lTW9kZWxg
CiBtZXRob2QsIHdoaWNoIHN0YXJ0cyBhIHR1bmluZyBwcm9jZXNzIGltbWVkaWF0ZWx5IGFu
ZCByZXNldHMgdGhlIHF1YXJ0ZXJseQogc2NoZWR1bGUuIEVuYWJsaW5nIG9yIGRpc2FibGlu
ZyBwZXJpb2RpYyB0dW5pbmcgZG9lcyBub3QgYWZmZWN0IGFueQogY3VycmVudCB0dW5pbmcg
cHJvY2Vzc2VzLgoKDAoFBAAEAgESA2kHGgpLCgYEAAQCAgASA2sEKho8IFVuc3BlY2lmaWVk
IGRlZmF1bHQgdmFsdWUsIHNob3VsZCBuZXZlciBiZSBleHBsaWNpdGx5IHNldC4KCg4KBwQA
BAICAAESA2sEJQoOCgcEAAQCAgACEgNrKCkKqwEKBgQABAICARIDcAQhGpsBIFRoZSBtb2Rl
bCBoYXMgcGVyaW9kaWMgdHVuaW5nIGRpc2FibGVkLiBUdW5pbmcKIGNhbiBiZSByZWVuYWJs
ZWQgYnkgY2FsbGluZyB0aGUgYEVuYWJsZU1vZGVsUGVyaW9kaWNUdW5pbmdgCiBtZXRob2Qg
b3IgYnkgY2FsbGluZyB0aGUgYFR1bmVNb2RlbGAgbWV0aG9kLgoKDgoHBAAEAgIBARIDcAQc
Cg4KBwQABAICAQISA3AfIAq5AQoGBAAEAgICEgN1BBwaqQEgVGhlIG1vZGVsIGNhbm5vdCBi
ZSB0dW5lZCB3aXRoIHBlcmlvZGljIHR1bmluZyBPUiB0aGUKIGBUdW5lTW9kZWxgIG1ldGhv
ZC4gSGlkZSB0aGUgb3B0aW9ucyBpbiBjdXN0b21lciBVSSBhbmQKIHJlamVjdCBhbnkgcmVx
dWVzdHMgdGhyb3VnaCB0aGUgYmFja2VuZCBzZWxmIHNlcnZlIEFQSS4KCg4KBwQABAICAgES
A3UEFwoOCgcEAAQCAgICEgN1GhsKhAEKBgQABAICAxIDegQgGnUgVGhlIG1vZGVsIGhhcyBw
ZXJpb2RpYyB0dW5pbmcgZW5hYmxlZC4gVHVuaW5nCiBjYW4gYmUgZGlzYWJsZWQgYnkgY2Fs
bGluZyB0aGUgYERpc2FibGVNb2RlbFBlcmlvZGljVHVuaW5nYAogbWV0aG9kLgoKDgoHBAAE
AgIDARIDegQbCg4KBwQABAICAwISA3oeHwpoCgQEAAQDEgV/AokBAxpZIERlc2NyaWJlcyB3
aGV0aGVyIHRoaXMgbW9kZWwgaGF2ZSBzdWZmaWNpZW50IHRyYWluaW5nIGRhdGEKIHRvIGJl
IGNvbnRpbnVvdXNseSB0cmFpbmVkLgoKDAoFBAAEAwESA38HEApMCgYEAAQDAgASBIEBBB8a
PCBVbnNwZWNpZmllZCBkZWZhdWx0IHZhbHVlLCBzaG91bGQgbmV2ZXIgYmUgZXhwbGljaXRs
eSBzZXQuCgoPCgcEAAQDAgABEgSBAQQaCg8KBwQABAMCAAISBIEBHR4KOQoGBAAEAwIBEgSE
AQQQGikgVGhlIG1vZGVsIGhhcyBzdWZmaWNpZW50IHRyYWluaW5nIGRhdGEuCgoPCgcEAAQD
AgEBEgSEAQQLCg8KBwQABAMCAQISBIQBDg8KcwoGBAAEAwICEgSIAQQTGmMgVGhlIG1vZGVs
IGRvZXMgbm90IGhhdmUgc3VmZmljaWVudCB0cmFpbmluZyBkYXRhLiBFcnJvcgogbWVzc2Fn
ZXMgY2FuIGJlIHF1ZXJpZWQgdmlhIFN0YWNrZHJpdmVyLgoKDwoHBAAEAwICARIEiAEEDgoP
CgcEAAQDAgICEgSIARESCk4KBAQABAQSBowBApkBAxo+IFVzZSBzaW5nbGUgb3IgbXVsdGlw
bGUgY29udGV4dCBwcm9kdWN0cyBmb3IgcmVjb21tZW5kYXRpb25zLgoKDQoFBAAEBAESBIwB
BxoKxAEKBgQABAQCABIEkAEEKhqzASBVbnNwZWNpZmllZCBkZWZhdWx0IHZhbHVlLCBzaG91
bGQgbmV2ZXIgYmUgZXhwbGljaXRseSBzZXQuCiBEZWZhdWx0cyB0bwogW01VTFRJUExFX0NP
TlRFWFRfUFJPRFVDVFNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuTW9kZWwuQ29udGV4dFBy
b2R1Y3RzVHlwZS5NVUxUSVBMRV9DT05URVhUX1BST0RVQ1RTXS4KCg8KBwQABAQCAAESBJAB
BCUKDwoHBAAEBAIAAhIEkAEoKQqMAQoGBAAEBAIBEgSUAQQfGnwgVXNlIG9ubHkgYSBzaW5n
bGUgcHJvZHVjdCBhcyBjb250ZXh0IGZvciB0aGUgcmVjb21tZW5kYXRpb24uIFR5cGljYWxs
eQogdXNlZCBvbiBwYWdlcyBsaWtlIGFkZC10by1jYXJ0IG9yIHByb2R1Y3QgZGV0YWlscy4K
Cg8KBwQABAQCAQESBJQBBBoKDwoHBAAEBAIBAhIElAEdHgp5CgYEAAQEAgISBJgBBCIaaSBV
c2Ugb25lIG9yIG11bHRpcGxlIHByb2R1Y3RzIGFzIGNvbnRleHQgZm9yIHRoZSByZWNvbW1l
bmRhdGlvbi4gVHlwaWNhbGx5CiB1c2VkIG9uIHNob3BwaW5nIGNhcnQgcGFnZXMuCgoPCgcE
AAQEAgIBEgSYAQQdCg8KBwQABAQCAgISBJgBICEKggIKBAQAAgASBKEBAjsa8wEgUmVxdWly
ZWQuIFRoZSBmdWxseSBxdWFsaWZpZWQgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbW9kZWwuCgog
Rm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L21vZGVscy97bW9kZWxfaWR9YAogY2F0YWxv
Z19pZCBoYXMgY2hhciBsaW1pdCBvZiA1MC4KIHJlY29tbWVuZGF0aW9uX21vZGVsX2lkIGhh
cyBjaGFyIGxpbWl0IG9mIDQwLgoKDQoFBAACAAUSBKEBAggKDQoFBAACAAESBKEBCQ0KDQoF
BAACAAMSBKEBEBEKDQoFBAACAAgSBKEBEjoKEAoIBAACAAicCAASBKEBEzkK2AEKBAQAAgES
BKgBAkMayQEgUmVxdWlyZWQuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIG1vZGVsLgoKIFNo
b3VsZCBiZSBodW1hbiByZWFkYWJsZSwgdXNlZCB0byBkaXNwbGF5IFJlY29tbWVuZGF0aW9u
IE1vZGVscyBpbiB0aGUKIFJldGFpbCBDbG91ZCBDb25zb2xlIERhc2hib2FyZC4gVVRGLTgg
ZW5jb2RlZCBzdHJpbmcgd2l0aCBsaW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDQoFBAAC
AQUSBKgBAggKDQoFBAACAQESBKgBCRUKDQoFBAACAQMSBKgBGBkKDQoFBAACAQgSBKgBGkIK
EAoIBAACAQicCAASBKgBG0EKnQMKBAQAAgISBLIBAkwajgMgT3B0aW9uYWwuIFRoZSB0cmFp
bmluZyBzdGF0ZSB0aGF0IHRoZSBtb2RlbCBpcyBpbiAoZS5nLgogYFRSQUlOSU5HYCBvciBg
UEFVU0VEYCkuCgogU2luY2UgcGFydCBvZiB0aGUgY29zdCBvZiBydW5uaW5nIHRoZSBzZXJ2
aWNlCiBpcyBmcmVxdWVuY3kgb2YgdHJhaW5pbmcgLSB0aGlzIGNhbiBiZSB1c2VkIHRvIGRl
dGVybWluZSB3aGVuIHRvIHRyYWluCiBtb2RlbCBpbiBvcmRlciB0byBjb250cm9sIGNvc3Qu
IElmIG5vdCBzcGVjaWZpZWQ6IHRoZSBkZWZhdWx0IHZhbHVlIGZvcgogYENyZWF0ZU1vZGVs
YCBtZXRob2QgaXMgYFRSQUlOSU5HYC4gVGhlIGRlZmF1bHQgdmFsdWUgZm9yCiBgVXBkYXRl
TW9kZWxgIG1ldGhvZCBpcyB0byBrZWVwIHRoZSBzdGF0ZSB0aGUgc2FtZSBhcyBiZWZvcmUu
CgoNCgUEAAICBhIEsgECDwoNCgUEAAICARIEsgEQHgoNCgUEAAICAxIEsgEhIgoNCgUEAAIC
CBIEsgEjSwoQCggEAAICCJwIABIEsgEkSgpUCgQEAAIDEgS1AQJNGkYgT3V0cHV0IG9ubHku
IFRoZSBzZXJ2aW5nIHN0YXRlIG9mIHRoZSBtb2RlbDogYEFDVElWRWAsIGBOT1RfQUNUSVZF
YC4KCg0KBQQAAgMGEgS1AQIOCg0KBQQAAgMBEgS1AQ8cCg0KBQQAAgMDEgS1AR8gCg0KBQQA
AgMIEgS1ASFMChAKCAQAAgMInAgAEgS1ASJLClEKBAQAAgQSBrgBArkBMhpBIE91dHB1dCBv
bmx5LiBUaW1lc3RhbXAgdGhlIFJlY29tbWVuZGF0aW9uIE1vZGVsIHdhcyBjcmVhdGVkIGF0
LgoKDQoFBAACBAYSBLgBAhsKDQoFBAACBAESBLgBHCcKDQoFBAACBAMSBLgBKisKDQoFBAAC
BAgSBLkBBjEKEAoIBAACBAicCAASBLkBBzAKsgEKBAQAAgUSBr4BAr8BMhqhASBPdXRwdXQg
b25seS4gVGltZXN0YW1wIHRoZSBSZWNvbW1lbmRhdGlvbiBNb2RlbCB3YXMgbGFzdCB1cGRh
dGVkLiBFLmcuCiBpZiBhIFJlY29tbWVuZGF0aW9uIE1vZGVsIHdhcyBwYXVzZWQgLSB0aGlz
IHdvdWxkIGJlIHRoZSB0aW1lIHRoZSBwYXVzZSB3YXMKIGluaXRpYXRlZC4KCg0KBQQAAgUG
EgS+AQIbCg0KBQQAAgUBEgS+ARwnCg0KBQQAAgUDEgS+ASorCg0KBQQAAgUIEgS/AQYxChAK
CAQAAgUInAgAEgS/AQcwCrYGCgQEAAIGEgTQAQI7GqcGIFJlcXVpcmVkLiBUaGUgdHlwZSBv
ZiBtb2RlbCBlLmcuIGBob21lLXBhZ2VgLgoKIEN1cnJlbnRseSBzdXBwb3J0ZWQgdmFsdWVz
OiBgcmVjb21tZW5kZWQtZm9yLXlvdWAsIGBvdGhlcnMteW91LW1heS1saWtlYCwKIGBmcmVx
dWVudGx5LWJvdWdodC10b2dldGhlcmAsIGBwYWdlLW9wdGltaXphdGlvbmAsIGBzaW1pbGFy
LWl0ZW1zYCwKIGBidXktaXQtYWdhaW5gLCBgb24tc2FsZS1pdGVtc2AsIGFuZCBgcmVjZW50
bHktdmlld2VkYChyZWFkb25seSB2YWx1ZSkuCgogVGhpcyBmaWVsZCB0b2dldGhlciB3aXRo
CiBbb3B0aW1pemF0aW9uX29iamVjdGl2ZV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Nb2Rl
bC5vcHRpbWl6YXRpb25fb2JqZWN0aXZlXQogZGVzY3JpYmUgbW9kZWwgbWV0YWRhdGEgdG8g
dXNlIHRvIGNvbnRyb2wgbW9kZWwgdHJhaW5pbmcgYW5kIHNlcnZpbmcuCiBTZWUgaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL3JldGFpbC9kb2NzL21vZGVscwogZm9yIG1vcmUgZGV0YWls
cyBvbiB3aGF0IHRoZSBtb2RlbCBtZXRhZGF0YSBjb250cm9sIGFuZCB3aGljaCBjb21iaW5h
dGlvbgogb2YgcGFyYW1ldGVycyBhcmUgdmFsaWQuIEZvciBpbnZhbGlkIGNvbWJpbmF0aW9u
cyBvZiBwYXJhbWV0ZXJzIChlLmcuIHR5cGUKID0gYGZyZXF1ZW50bHktYm91Z2h0LXRvZ2V0
aGVyYCBhbmQgb3B0aW1pemF0aW9uX29iamVjdGl2ZSA9IGBjdHJgKSwgeW91CiByZWNlaXZl
IGFuIGVycm9yIDQwMCBpZiB5b3UgdHJ5IHRvIGNyZWF0ZS91cGRhdGUgYSByZWNvbW1lbmRh
dGlvbiB3aXRoCiB0aGlzIHNldCBvZiBrbm9icy4KCg0KBQQAAgYFEgTQAQIICg0KBQQAAgYB
EgTQAQkNCg0KBQQAAgYDEgTQARARCg0KBQQAAgYIEgTQARI6ChAKCAQAAgYInAgAEgTQARM5
Cu8GCgQEAAIHEgTpAQJNGuAGIE9wdGlvbmFsLiBUaGUgb3B0aW1pemF0aW9uIG9iamVjdGl2
ZSBlLmcuIGBjdnJgLgoKIEN1cnJlbnRseSBzdXBwb3J0ZWQKIHZhbHVlczogYGN0cmAsIGBj
dnJgLCBgcmV2ZW51ZS1wZXItb3JkZXJgLgoKICBJZiBub3Qgc3BlY2lmaWVkLCB3ZSBjaG9v
c2UgZGVmYXVsdCBiYXNlZCBvbiBtb2RlbCB0eXBlLgogRGVmYXVsdCBkZXBlbmRzIG9uIHR5
cGUgb2YgcmVjb21tZW5kYXRpb246CgogYHJlY29tbWVuZGVkLWZvci15b3VgID0+IGBjdHJg
CgogYG90aGVycy15b3UtbWF5LWxpa2VgID0+IGBjdHJgCgogYGZyZXF1ZW50bHktYm91Z2h0
LXRvZ2V0aGVyYCA9PiBgcmV2ZW51ZV9wZXJfb3JkZXJgCgogVGhpcyBmaWVsZCB0b2dldGhl
ciB3aXRoCiBbb3B0aW1pemF0aW9uX29iamVjdGl2ZV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5Nb2RlbC50eXBlXQogZGVzY3JpYmUgbW9kZWwgbWV0YWRhdGEgdG8gdXNlIHRvIGNvbnRy
b2wgbW9kZWwgdHJhaW5pbmcgYW5kIHNlcnZpbmcuCiBTZWUgaHR0cHM6Ly9jbG91ZC5nb29n
bGUuY29tL3JldGFpbC9kb2NzL21vZGVscwogZm9yIG1vcmUgZGV0YWlscyBvbiB3aGF0IHRo
ZSBtb2RlbCBtZXRhZGF0YSBjb250cm9sIGFuZCB3aGljaCBjb21iaW5hdGlvbgogb2YgcGFy
YW1ldGVycyBhcmUgdmFsaWQuIEZvciBpbnZhbGlkIGNvbWJpbmF0aW9ucyBvZiBwYXJhbWV0
ZXJzIChlLmcuIHR5cGUKID0gYGZyZXF1ZW50bHktYm91Z2h0LXRvZ2V0aGVyYCBhbmQgb3B0
aW1pemF0aW9uX29iamVjdGl2ZSA9IGBjdHJgKSwgeW91CiByZWNlaXZlIGFuIGVycm9yIDQw
MCBpZiB5b3UgdHJ5IHRvIGNyZWF0ZS91cGRhdGUgYSByZWNvbW1lbmRhdGlvbiB3aXRoCiB0
aGlzIHNldCBvZiBrbm9icy4KCg0KBQQAAgcFEgTpAQIICg0KBQQAAgcBEgTpAQkfCg0KBQQA
AgcDEgTpASIjCg0KBQQAAgcIEgTpASRMChAKCAQAAgcInAgAEgTpASVLCsMBCgQEAAIIEgbw
AQLxAS8asgEgT3B0aW9uYWwuIFRoZSBzdGF0ZSBvZiBwZXJpb2RpYyB0dW5pbmcuCgogVGhl
IHBlcmlvZCB3ZSB1c2UgaXMgMyBtb250aHMgLSB0byBkbyBhCiBvbmUtb2ZmIHR1bmUgZWFy
bGllciB1c2UgdGhlIGBUdW5lTW9kZWxgIG1ldGhvZC4gRGVmYXVsdCB2YWx1ZQogaXMgYFBF
UklPRElDX1RVTklOR19FTkFCTEVEYC4KCg0KBQQAAggGEgTwAQIVCg0KBQQAAggBEgTwARYr
Cg0KBQQAAggDEgTwAS4wCg0KBQQAAggIEgTxAQYuChAKCAQAAggInAgAEgTxAQctClYKBAQA
AgkSBvQBAvUBMhpGIE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIGxhdGVz
dCBzdWNjZXNzZnVsIHR1bmUgZmluaXNoZWQuCgoNCgUEAAIJBhIE9AECGwoNCgUEAAIJARIE
9AEcKgoNCgUEAAIJAxIE9AEtLwoNCgUEAAIJCBIE9QEGMQoQCggEAAIJCJwIABIE9QEHMArE
AQoEBAACChIE+wECSxq1ASBPdXRwdXQgb25seS4gVGhlIHR1bmUgb3BlcmF0aW9uIGFzc29j
aWF0ZWQgd2l0aCB0aGUgbW9kZWwuCgogQ2FuIGJlIHVzZWQgdG8gZGV0ZXJtaW5lIGlmIHRo
ZXJlIGlzIGFuIG9uZ29pbmcgdHVuZSBmb3IgdGhpcwogcmVjb21tZW5kYXRpb24uIEVtcHR5
IGZpZWxkIGltcGxpZXMgbm8gdHVuZSBpcyBnb2lnIG9uLgoKDQoFBAACCgUSBPsBAggKDQoF
BAACCgESBPsBCRkKDQoFBAACCgMSBPsBHB4KDQoFBAACCggSBPsBH0oKEAoIBAACCgicCAAS
BPsBIEkKiwMKBAQAAgsSBIUCAkga/AIgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiBkYXRh
IHJlcXVpcmVtZW50cyBmb3IgdGhpcyBtb2RlbDogYERBVEFfT0tgIGFuZAogYERBVEFfRVJS
T1JgLgoKIFJlY29tbWVuZGF0aW9uIG1vZGVsIGNhbm5vdCBiZSB0cmFpbmVkIGlmIHRoZSBk
YXRhIGlzIGluCiBgREFUQV9FUlJPUmAgc3RhdGUuIFJlY29tbWVuZGF0aW9uIG1vZGVsIGNh
biBoYXZlIGBEQVRBX0VSUk9SYCBzdGF0ZSBldmVuCiBpZiBzZXJ2aW5nIHN0YXRlIGlzIGBB
Q1RJVkVgOiBtb2RlbHMgd2VyZSB0cmFpbmVkIHN1Y2Nlc3NmdWxseSBiZWZvcmUsIGJ1dAog
Y2Fubm90IGJlIHJlZnJlc2hlZCBiZWNhdXNlIG1vZGVsIG5vIGxvbmdlciBoYXMgc3VmZmlj
aWVudAogZGF0YSBmb3IgdHJhaW5pbmcuCgoNCgUEAAILBhIEhQICCwoNCgUEAAILARIEhQIM
FgoNCgUEAAILAxIEhQIZGwoNCgUEAAILCBIEhQIcRwoQCggEAAILCJwIABIEhQIdRgqFAQoE
BAACDBIGiQICigIvGnUgT3B0aW9uYWwuIElmIGBSRUNPTU1FTkRBVElPTlNfRklMVEVSSU5H
X0VOQUJMRURgLCByZWNvbW1lbmRhdGlvbiBmaWx0ZXJpbmcKIGJ5IGF0dHJpYnV0ZXMgaXMg
ZW5hYmxlZCBmb3IgdGhlIG1vZGVsLgoKDQoFBAACDAYSBIkCAiAKDQoFBAACDAESBIkCITEK
DQoFBAACDAMSBIkCNDYKDQoFBAACDAgSBIoCBi4KEAoIBAACDAicCAASBIoCBy0KbQoEBAAC
DRIGjgICjwIyGl0gT3V0cHV0IG9ubHkuIFRoZSBsaXN0IG9mIHZhbGlkIHNlcnZpbmcgY29u
ZmlncyBhc3NvY2lhdGVkIHdpdGggdGhlCiBQYWdlT3B0aW1pemF0aW9uQ29uZmlnLgoKDQoF
BAACDQQSBI4CAgoKDQoFBAACDQYSBI4CCxwKDQoFBAACDQESBI4CHTEKDQoFBAACDQMSBI4C
NDYKDQoFBAACDQgSBI8CBjEKEAoIBAACDQicCAASBI8CBzAKPQoEBAACDhIGkgICkwIvGi0g
T3B0aW9uYWwuIEFkZGl0aW9uYWwgbW9kZWwgZmVhdHVyZXMgY29uZmlnLgoKDQoFBAACDgYS
BJICAhUKDQoFBAACDgESBJICFisKDQoFBAACDgMSBJICLjAKDQoFBAACDggSBJMCBi4KEAoI
BAACDgicCAASBJMCBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::Model::Model ===
    # Fields for Model
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: training_state Type: 14 (.google.cloud.retail.v2.Model.TrainingState)
    # Field: serving_state Type: 14 (.google.cloud.retail.v2.Model.ServingState)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: type Type: 9 ()
    # Field: optimization_objective Type: 9 ()
    # Field: periodic_tuning_state Type: 14 (.google.cloud.retail.v2.Model.PeriodicTuningState)
    # Field: last_tune_time Type: 11 (.google.protobuf.Timestamp)
    # Field: tuning_operation Type: 9 ()
    # Field: data_state Type: 14 (.google.cloud.retail.v2.Model.DataState)
    # Field: filtering_option Type: 14 (.google.cloud.retail.v2.RecommendationsFilteringOption)
    # Field: serving_config_lists Type: 11 (.google.cloud.retail.v2.Model.ServingConfigList)
    # Field: model_features_config Type: 11 (.google.cloud.retail.v2.Model.ModelFeaturesConfig)

# Enum: Model::ServingState
our $Model_SERVING_STATE_UNSPECIFIED = 0;
our $Model_INACTIVE = 1;
our $Model_ACTIVE = 2;
our $Model_TUNED = 3;

# Enum: Model::TrainingState
our $Model_TRAINING_STATE_UNSPECIFIED = 0;
our $Model_PAUSED = 1;
our $Model_TRAINING = 2;

# Enum: Model::PeriodicTuningState
our $Model_PERIODIC_TUNING_STATE_UNSPECIFIED = 0;
our $Model_PERIODIC_TUNING_DISABLED = 1;
our $Model_ALL_TUNING_DISABLED = 3;
our $Model_PERIODIC_TUNING_ENABLED = 2;

# Enum: Model::DataState
our $Model_DATA_STATE_UNSPECIFIED = 0;
our $Model_DATA_OK = 1;
our $Model_DATA_ERROR = 2;

# Enum: Model::ContextProductsType
our $Model_CONTEXT_PRODUCTS_TYPE_UNSPECIFIED = 0;
our $Model_SINGLE_CONTEXT_PRODUCT = 1;
our $Model_MULTIPLE_CONTEXT_PRODUCTS = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::Model - Compiled Protocol Buffers messages for google/cloud/retail/v2/model.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::Model;

    my $msg = Google::Cloud::Retail::V2::Model::Model->new({
        name => $name,
        display_name => $display_name,
        training_state => $training_state,
        serving_state => $serving_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::Model::Model

Metadata that describes the training and serving parameters of a
[Model][google.cloud.retail.v2.Model]. A
[Model][google.cloud.retail.v2.Model] can be associated with a
[ServingConfig][google.cloud.retail.v2.ServingConfig] and then queried
through the Predict API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The fully qualified resource name of the model.

Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`
catalog_id has char limit of 50.
recommendation_model_id has char limit of 40.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the model.

Should be human readable, used to display Recommendation Models in the
Retail Cloud Console Dashboard. UTF-8 encoded string with limit of 1024
characters.

=item * C<< $msg->training_state() >> / C<< $msg->training_state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::Model::TrainingState>)

Optional. The training state that the model is in (e.g.
`TRAINING` or `PAUSED`).

Since part of the cost of running the service
is frequency of training - this can be used to determine when to train
model in order to control cost. If not specified: the default value for
`CreateModel` method is `TRAINING`. The default value for
`UpdateModel` method is to keep the state the same as before.

=item * C<< $msg->serving_state() >> / C<< $msg->serving_state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::Model::ServingState>)

Output only. The serving state of the model: `ACTIVE`, `NOT_ACTIVE`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the Recommendation Model was created at.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the Recommendation Model was last updated. E.g.
if a Recommendation Model was paused - this would be the time the pause was
initiated.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. The type of model e.g. `home-page`.

Currently supported values: `recommended-for-you`, `others-you-may-like`,
`frequently-bought-together`, `page-optimization`, `similar-items`,
`buy-it-again`, `on-sale-items`, and `recently-viewed`(readonly value).

This field together with
[optimization_objective][google.cloud.retail.v2.Model.optimization_objective]
describe model metadata to use to control model training and serving.
See https://cloud.google.com/retail/docs/models
for more details on what the model metadata control and which combination
of parameters are valid. For invalid combinations of parameters (e.g. type
 = `frequently-bought-together` and optimization_objective = `ctr`), you
receive an error 400 if you try to create/update a recommendation with
this set of knobs.

=item * C<< $msg->optimization_objective() >> / C<< $msg->optimization_objective($value) >>

Type: C<String>

Optional. The optimization objective e.g. `cvr`.

Currently supported
values: `ctr`, `cvr`, `revenue-per-order`.

 If not specified, we choose default based on model type.
Default depends on type of recommendation:

`recommended-for-you` => `ctr`

`others-you-may-like` => `ctr`

`frequently-bought-together` => `revenue_per_order`

This field together with
[optimization_objective][google.cloud.retail.v2.Model.type]
describe model metadata to use to control model training and serving.
See https://cloud.google.com/retail/docs/models
for more details on what the model metadata control and which combination
of parameters are valid. For invalid combinations of parameters (e.g. type
 = `frequently-bought-together` and optimization_objective = `ctr`), you
receive an error 400 if you try to create/update a recommendation with
this set of knobs.

=item * C<< $msg->periodic_tuning_state() >> / C<< $msg->periodic_tuning_state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::Model::PeriodicTuningState>)

Optional. The state of periodic tuning.

The period we use is 3 months - to do a
one-off tune earlier use the `TuneModel` method. Default value
is `PERIODIC_TUNING_ENABLED`.

=item * C<< $msg->last_tune_time() >> / C<< $msg->last_tune_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the latest successful tune finished.

=item * C<< $msg->tuning_operation() >> / C<< $msg->tuning_operation($value) >>

Type: C<String>

Output only. The tune operation associated with the model.

Can be used to determine if there is an ongoing tune for this
recommendation. Empty field implies no tune is goig on.

=item * C<< $msg->data_state() >> / C<< $msg->data_state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::Model::DataState>)

Output only. The state of data requirements for this model: `DATA_OK` and
`DATA_ERROR`.

Recommendation model cannot be trained if the data is in
`DATA_ERROR` state. Recommendation model can have `DATA_ERROR` state even
if serving state is `ACTIVE`: models were trained successfully before, but
cannot be refreshed because model no longer has sufficient
data for training.

=item * C<< $msg->filtering_option() >> / C<< $msg->filtering_option($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::RecommendationsFilteringOption>)

Optional. If `RECOMMENDATIONS_FILTERING_ENABLED`, recommendation filtering
by attributes is enabled for the model.

=item * C<< $msg->serving_config_lists() >> / C<< $msg->serving_config_lists($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Model::Model::ServingConfigList>)

Output only. The list of valid serving configs associated with the
PageOptimizationConfig.

=item * C<< $msg->model_features_config() >> / C<< $msg->model_features_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Model::Model::ModelFeaturesConfig>)

Optional. Additional model features config.

=back

=head3 Enum: Model::ServingState

=over 4

=item * C<SERVING_STATE_UNSPECIFIED> => C<0>

=item * C<INACTIVE> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<TUNED> => C<3>

=back

=head3 Enum: Model::TrainingState

=over 4

=item * C<TRAINING_STATE_UNSPECIFIED> => C<0>

=item * C<PAUSED> => C<1>

=item * C<TRAINING> => C<2>

=back

=head3 Enum: Model::PeriodicTuningState

=over 4

=item * C<PERIODIC_TUNING_STATE_UNSPECIFIED> => C<0>

=item * C<PERIODIC_TUNING_DISABLED> => C<1>

=item * C<ALL_TUNING_DISABLED> => C<3>

=item * C<PERIODIC_TUNING_ENABLED> => C<2>

=back

=head3 Enum: Model::DataState

=over 4

=item * C<DATA_STATE_UNSPECIFIED> => C<0>

=item * C<DATA_OK> => C<1>

=item * C<DATA_ERROR> => C<2>

=back

=head3 Enum: Model::ContextProductsType

=over 4

=item * C<CONTEXT_PRODUCTS_TYPE_UNSPECIFIED> => C<0>

=item * C<SINGLE_CONTEXT_PRODUCT> => C<1>

=item * C<MULTIPLE_CONTEXT_PRODUCTS> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
