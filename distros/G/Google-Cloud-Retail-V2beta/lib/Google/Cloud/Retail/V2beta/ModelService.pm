package Google::Cloud::Retail::V2beta::ModelService;

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
    eval { require Google::Cloud::Retail::V2beta::Model };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9tb2RlbF9zZXJ2aWNlLnByb3RvEhpnb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJmdvb2dsZS9jbG91ZC9yZXRhaWwvdjJi
ZXRhL21vZGVsLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxob
Z29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFz
ay5wcm90byKvAQoSQ3JlYXRlTW9kZWxSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEf
Ch1yZXRhaWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IGcGFyZW50EjwKBW1vZGVsGAIgASgL
MiEuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuTW9kZWxCA+BBAlIFbW9kZWwSHAoHZHJ5
X3J1bhgDIAEoCEID4EEBUgZkcnlSdW4ilAEKElVwZGF0ZU1vZGVsUmVxdWVzdBI8CgVtb2Rl
bBgBIAEoCzIhLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLk1vZGVsQgPgQQJSBW1vZGVs
EkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEB
Ugp1cGRhdGVNYXNrIkoKD0dldE1vZGVsUmVxdWVzdBI3CgRuYW1lGAEgASgJQiPgQQL6QR0K
G3JldGFpbC5nb29nbGVhcGlzLmNvbS9Nb2RlbFIEbmFtZSJMChFQYXVzZU1vZGVsUmVxdWVz
dBI3CgRuYW1lGAEgASgJQiPgQQL6QR0KG3JldGFpbC5nb29nbGVhcGlzLmNvbS9Nb2RlbFIE
bmFtZSItChJSZXN1bWVNb2RlbFJlcXVlc3QSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lIpgB
ChFMaXN0TW9kZWxzUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0YWlsLmdv
b2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVII
cGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4iTQoSRGVsZXRl
TW9kZWxSZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BBAvpBHQobcmV0YWlsLmdvb2dsZWFwaXMu
Y29tL01vZGVsUgRuYW1lIncKEkxpc3RNb2RlbHNSZXNwb25zZRI5CgZtb2RlbHMYASADKAsy
IS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Nb2RlbFIGbW9kZWxzEiYKD25leHRfcGFn
ZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJLChBUdW5lTW9kZWxSZXF1ZXN0EjcKBG5h
bWUYASABKAlCI+BBAvpBHQobcmV0YWlsLmdvb2dsZWFwaXMuY29tL01vZGVsUgRuYW1lIisK
E0NyZWF0ZU1vZGVsTWV0YWRhdGESFAoFbW9kZWwYASABKAlSBW1vZGVsIikKEVR1bmVNb2Rl
bE1ldGFkYXRhEhQKBW1vZGVsGAEgASgJUgVtb2RlbCITChFUdW5lTW9kZWxSZXNwb25zZTKp
DQoMTW9kZWxTZXJ2aWNlEosCCgtDcmVhdGVNb2RlbBIuLmdvb2dsZS5jbG91ZC5yZXRhaWwu
djJiZXRhLkNyZWF0ZU1vZGVsUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24irAGC0+STAkIiOS92MmJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nh
dGFsb2dzLyp9L21vZGVsczoFbW9kZWzaQQxwYXJlbnQsbW9kZWzKQVIKIGdvb2dsZS5jbG91
ZC5yZXRhaWwudjJiZXRhLk1vZGVsEi5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5DcmVh
dGVNb2RlbE1ldGFkYXRhEqQBCghHZXRNb2RlbBIrLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJi
ZXRhLkdldE1vZGVsUmVxdWVzdBohLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLk1vZGVs
IkiC0+STAjsSOS92MmJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9n
cy8qL21vZGVscy8qfdpBBG5hbWUSsQEKClBhdXNlTW9kZWwSLS5nb29nbGUuY2xvdWQucmV0
YWlsLnYyYmV0YS5QYXVzZU1vZGVsUmVxdWVzdBohLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJi
ZXRhLk1vZGVsIlGC0+STAkQiPy92MmJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jYXRhbG9ncy8qL21vZGVscy8qfTpwYXVzZToBKtpBBG5hbWUStAEKC1Jlc3VtZU1vZGVs
Ei4uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUmVzdW1lTW9kZWxSZXF1ZXN0GiEuZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmJldGEuTW9kZWwiUoLT5JMCRSJAL3YyYmV0YS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovbW9kZWxzLyp9OnJlc3VtZToBKtpB
BG5hbWUSnwEKC0RlbGV0ZU1vZGVsEi4uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuRGVs
ZXRlTW9kZWxSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IkiC0+STAjsqOS92MmJl
dGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qL21vZGVscy8qfdpB
BG5hbWUStwEKCkxpc3RNb2RlbHMSLS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5MaXN0
TW9kZWxzUmVxdWVzdBouLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkxpc3RNb2RlbHNS
ZXNwb25zZSJKgtPkkwI7EjkvdjJiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jYXRhbG9ncy8qfS9tb2RlbHPaQQZwYXJlbnQSxAEKC1VwZGF0ZU1vZGVsEi4uZ29vZ2xl
LmNsb3VkLnJldGFpbC52MmJldGEuVXBkYXRlTW9kZWxSZXF1ZXN0GiEuZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmJldGEuTW9kZWwiYoLT5JMCSDI/L3YyYmV0YS97bW9kZWwubmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovbW9kZWxzLyp9OgVtb2RlbNpBEW1vZGVs
LHVwZGF0ZV9tYXNrEooCCglUdW5lTW9kZWwSLC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0
YS5UdW5lTW9kZWxSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKvAYLT
5JMCQyI+L3YyYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyov
bW9kZWxzLyp9OnR1bmU6ASraQQRuYW1lykFcCixnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0
YS5UdW5lTW9kZWxSZXNwb25zZRIsZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuVHVuZU1v
ZGVsTWV0YWRhdGEaScpBFXJldGFpbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C0AEKHmNvbS5nb29nbGUuY2xvdWQu
cmV0YWlsLnYyYmV0YUIRTW9kZWxTZXJ2aWNlUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9n
by9yZXRhaWwvYXBpdjJiZXRhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIaR29vZ2xl
LkNsb3VkLlJldGFpbC5WMkJldGHKAhpHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYmV0YeoCHUdv
b2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJiZXRhSos7CgcSBQ4AhgIcCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJ
CgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAMAoJCgIDBRIDFwAtCgkKAgMGEgMYACUK
CQoCAwcSAxkAKgoICgEIEgMbADcKCQoCCCUSAxsANwoICgEIEgMcAE0KCQoCCAsSAxwATQoI
CgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeADIKCQoCCAgSAx4AMgoICgEIEgMfADcKCQoC
CAESAx8ANwoICgEIEgMgACQKCQoCCCQSAyAAJAoICgEIEgMhADcKCQoCCCkSAyEANwoICgEI
EgMiADYKCQoCCC0SAyIANgqdBAoCBgASBTAAhAEBGo8EIFNlcnZpY2UgZm9yIHBlcmZvcm1p
bmcgQ1JVRCBvcGVyYXRpb25zIG9uIG1vZGVscy4KIFJlY29tbWVuZGF0aW9uIG1vZGVscyBj
b250YWluIGFsbCB0aGUgbWV0YWRhdGEgbmVjZXNzYXJ5IHRvIGdlbmVyYXRlIGEgc2V0IG9m
CiBtb2RlbHMgZm9yIHRoZSBgUHJlZGljdCgpYCBBUEkuIEEgbW9kZWwgaXMgcXVlcmllZAog
aW5kaXJlY3RseSB2aWEgYSBTZXJ2aW5nQ29uZmlnLCB3aGljaCBhc3NvY2lhdGVzIGEgbW9k
ZWwgd2l0aCBhCiBnaXZlbiBQbGFjZW1lbnQgKGUuZy4gRnJlcXVlbnRseSBCb3VnaHQgVG9n
ZXRoZXIgb24gSG9tZSBQYWdlKS4KCiBUaGlzIHNlcnZpY2UgYWxsb3dzIHlvdSB0byBkbyB0
aGUgZm9sbG93aW5nOgoKICogSW5pdGlhdGUgdHJhaW5pbmcgb2YgYSBtb2RlbC4KICogUGF1
c2UgdHJhaW5pbmcgb2YgYW4gZXhpc3RpbmcgbW9kZWwuCiAqIExpc3QgYWxsIHRoZSBhdmFp
bGFibGUgbW9kZWxzIGFsb25nIHdpdGggdGhlaXIgbWV0YWRhdGEuCiAqIENvbnRyb2wgdGhl
aXIgdHVuaW5nIHNjaGVkdWxlLgoKCgoDBgABEgMwCBQKCgoDBgADEgMxAj0KDAoFBgADmQgS
AzECPQoLCgMGAAMSBDICMzcKDQoFBgADmggSBDICMzcKJAoEBgACABIENgJAAxoWIENyZWF0
ZXMgYSBuZXcgbW9kZWwuCgoMCgUGAAIAARIDNgYRCgwKBQYAAgACEgM2EiQKDAoFBgACAAMS
AzYvSwoNCgUGAAIABBIENwQ6BgoRCgkGAAIABLDKvCISBDcEOgYKDAoFBgACAAQSAzsEOgoP
CggGAAIABJsIABIDOwQ6Cg0KBQYAAgAEEgQ8BD8GCg8KBwYAAgAEmQgSBDwEPwYKHQoEBgAC
ARIEQwJIAxoPIEdldHMgYSBtb2RlbC4KCgwKBQYAAgEBEgNDBg4KDAoFBgACAQISA0MPHgoM
CgUGAAIBAxIDQykuCg0KBQYAAgEEEgREBEYGChEKCQYAAgEEsMq8IhIERARGBgoMCgUGAAIB
BBIDRwQyCg8KCAYAAgEEmwgAEgNHBDIKOQoEBgACAhIESwJRAxorIFBhdXNlcyB0aGUgdHJh
aW5pbmcgb2YgYW4gZXhpc3RpbmcgbW9kZWwuCgoMCgUGAAICARIDSwYQCgwKBQYAAgICEgNL
ESIKDAoFBgACAgMSA0stMgoNCgUGAAICBBIETARPBgoRCgkGAAICBLDKvCISBEwETwYKDAoF
BgACAgQSA1AEMgoPCggGAAICBJsIABIDUAQyCjoKBAYAAgMSBFQCWgMaLCBSZXN1bWVzIHRo
ZSB0cmFpbmluZyBvZiBhbiBleGlzdGluZyBtb2RlbC4KCgwKBQYAAgMBEgNUBhEKDAoFBgAC
AwISA1QSJAoMCgUGAAIDAxIDVC80Cg0KBQYAAgMEEgRVBFgGChEKCQYAAgMEsMq8IhIEVQRY
BgoMCgUGAAIDBBIDWQQyCg8KCAYAAgMEmwgAEgNZBDIKKgoEBgACBBIEXQJiAxocIERlbGV0
ZXMgYW4gZXhpc3RpbmcgbW9kZWwuCgoMCgUGAAIEARIDXQYRCgwKBQYAAgQCEgNdEiQKDAoF
BgACBAMSA10vRAoNCgUGAAIEBBIEXgRgBgoRCgkGAAIEBLDKvCISBF4EYAYKDAoFBgACBAQS
A2EEMgoPCggGAAIEBJsIABIDYQQyCkAKBAYAAgUSBGUCagMaMiBMaXN0cyBhbGwgdGhlIG1v
ZGVscyBsaW5rZWQgdG8gdGhpcyBldmVudCBzdG9yZS4KCgwKBQYAAgUBEgNlBhAKDAoFBgAC
BQISA2URIgoMCgUGAAIFAxIDZS0/Cg0KBQYAAgUEEgRmBGgGChEKCQYAAgUEsMq8IhIEZgRo
BgoMCgUGAAIFBBIDaQQ0Cg8KCAYAAgUEmwgAEgNpBDQKyAEKBAYAAgYSBHACdgMauQEgVXBk
YXRlIG9mIG1vZGVsIG1ldGFkYXRhLiBPbmx5IGZpZWxkcyB0aGF0CiBjdXJyZW50bHkgY2Fu
IGJlIHVwZGF0ZWQgYXJlOiBgZmlsdGVyaW5nX29wdGlvbmAgYW5kCiBgcGVyaW9kaWNfdHVu
aW5nX3N0YXRlYC4KIElmIG90aGVyIHZhbHVlcyBhcmUgcHJvdmlkZWQsIHRoaXMgQVBJIG1l
dGhvZCBpZ25vcmVzIHRoZW0uCgoMCgUGAAIGARIDcAYRCgwKBQYAAgYCEgNwEiQKDAoFBgAC
BgMSA3AvNAoNCgUGAAIGBBIEcQR0BgoRCgkGAAIGBLDKvCISBHEEdAYKDAoFBgACBgQSA3UE
PwoPCggGAAIGBJsIABIDdQQ/CikKBAYAAgcSBXkCgwEDGhogVHVuZXMgYW4gZXhpc3Rpbmcg
bW9kZWwuCgoMCgUGAAIHARIDeQYPCgwKBQYAAgcCEgN5ECAKDAoFBgACBwMSA3krRwoNCgUG
AAIHBBIEegR9BgoRCgkGAAIHBLDKvCISBHoEfQYKDAoFBgACBwQSA34EMgoPCggGAAIHBJsI
ABIDfgQyCg4KBQYAAgcEEgV/BIIBBgoQCgcGAAIHBJkIEgV/BIIBBgotCgIEABIGhwEAlgEB
Gh8gUmVxdWVzdCBmb3IgY3JlYXRpbmcgYSBtb2RlbC4KCgsKAwQAARIEhwEIGgqkAQoEBAAC
ABIGigECjQEEGpMBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIHVuZGVyIHdoaWNo
IHRvIGNyZWF0ZSB0aGUgbW9kZWwuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1i
ZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lkfWAKCg0K
BQQAAgAFEgSKAQIICg0KBQQAAgABEgSKAQkPCg0KBQQAAgADEgSKARITCg8KBQQAAgAIEgaK
ARSNAQMKEAoIBAACAAicCAASBIsBBCoKDwoHBAACAAifCBIEjAEETwpjCgQEAAIBEgSRAQI7
GlUgUmVxdWlyZWQuIFRoZSBwYXlsb2FkIG9mIHRoZSBbTW9kZWxdW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjJiZXRhLk1vZGVsXSAgdG8KIGNyZWF0ZS4KCg0KBQQAAgEGEgSRAQIHCg0KBQQA
AgEBEgSRAQgNCg0KBQQAAgEDEgSRARARCg0KBQQAAgEIEgSRARI6ChAKCAQAAgEInAgAEgSR
ARM5CnIKBAQAAgISBJUBAjwaZCBPcHRpb25hbC4gV2hldGhlciB0byBydW4gYSBkcnkgcnVu
IHRvIHZhbGlkYXRlIHRoZSByZXF1ZXN0ICh3aXRob3V0CiBhY3R1YWxseSBjcmVhdGluZyB0
aGUgbW9kZWwpLgoKDQoFBAACAgUSBJUBAgYKDQoFBAACAgESBJUBBw4KDQoFBAACAgMSBJUB
ERIKDQoFBAACAggSBJUBEzsKEAoIBAACAgicCAASBJUBFDoKNwoCBAESBpkBAKIBARopIFJl
cXVlc3QgZm9yIHVwZGF0aW5nIGFuIGV4aXN0aW5nIG1vZGVsLgoKCwoDBAEBEgSZAQgaCl0K
BAQBAgASBJwBAjsaTyBSZXF1aXJlZC4gVGhlIGJvZHkgb2YgdGhlIHVwZGF0ZWQKIFtNb2Rl
bF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuTW9kZWxdLgoKDQoFBAECAAYSBJwBAgcK
DQoFBAECAAESBJwBCA0KDQoFBAECAAMSBJwBEBEKDQoFBAECAAgSBJwBEjoKEAoIBAECAAic
CAASBJwBEzkKgQEKBAQBAgESBqABAqEBLxpxIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hpY2gg
ZmllbGRzIGluIHRoZSBwcm92aWRlZCAnbW9kZWwnIHRvCiB1cGRhdGUuIElmIG5vdCBzZXQs
IGJ5IGRlZmF1bHQgdXBkYXRlcyBhbGwgZmllbGRzLgoKDQoFBAECAQYSBKABAhsKDQoFBAEC
AQESBKABHCcKDQoFBAECAQMSBKABKisKDQoFBAECAQgSBKEBBi4KEAoIBAECAQicCAASBKEB
By0KLAoCBAISBqUBAK0BARoeIFJlcXVlc3QgZm9yIGdldHRpbmcgYSBtb2RlbC4KCgsKAwQC
ARIEpQEIFwrKAQoEBAICABIGqQECrAEEGrkBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUKIFtNb2RlbF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuTW9kZWxdIHRv
IGdldC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3ts
b2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2d9L21vZGVscy97bW9kZWxfaWR9YAoKDQoF
BAICAAUSBKkBAggKDQoFBAICAAESBKkBCQ0KDQoFBAICAAMSBKkBEBEKDwoFBAICAAgSBqkB
EqwBAwoQCggEAgIACJwIABIEqgEEKgoPCgcEAgIACJ8IEgSrAQRNCjgKAgQDEgawAQC4AQEa
KiBSZXF1ZXN0IGZvciBwYXVzaW5nIHRyYWluaW5nIG9mIGEgbW9kZWwuCgoLCgMEAwESBLAB
CBkKogEKBAQDAgASBrQBArcBBBqRASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIG1vZGVs
IHRvIHBhdXNlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRp
b25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L21vZGVscy97bW9kZWxf
aWR9YAoKDQoFBAMCAAUSBLQBAggKDQoFBAMCAAESBLQBCQ0KDQoFBAMCAAMSBLQBEBEKDwoF
BAMCAAgSBrQBErcBAwoQCggEAwIACJwIABIEtQEEKgoPCgcEAwIACJ8IEgS2AQRNCjkKAgQE
Ega7AQDAAQEaKyBSZXF1ZXN0IGZvciByZXN1bWluZyB0cmFpbmluZyBvZiBhIG1vZGVsLgoK
CwoDBAQBEgS7AQgaCqEBCgQEBAIAEgS/AQI7GpIBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgbW9kZWwgdG8gcmVzdW1lLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJl
cn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L21vZGVs
cy97bW9kZWxfaWR9YAoKDQoFBAQCAAUSBL8BAggKDQoFBAQCAAESBL8BCQ0KDQoFBAQCAAMS
BL8BEBEKDQoFBAQCAAgSBL8BEjoKEAoIBAQCAAicCAASBL8BEzkKRgoCBAUSBsMBANMBARo4
IFJlcXVlc3QgZm9yIGxpc3RpbmcgbW9kZWxzIGFzc29jaWF0ZWQgd2l0aCBhIHJlc291cmNl
LgoKCwoDBAUBEgTDAQgZCpUBCgQEBQIAEgbHAQLKAQQahAEgUmVxdWlyZWQuIFRoZSBwYXJl
bnQgZm9yIHdoaWNoIHRvIGxpc3QgbW9kZWxzLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2df
aWR9YAoKDQoFBAUCAAUSBMcBAggKDQoFBAUCAAESBMcBCQ8KDQoFBAUCAAMSBMcBEhMKDwoF
BAUCAAgSBscBFMoBAwoQCggEBQIACJwIABIEyAEEKgoPCgcEBQIACJ8IEgTJAQRPCnoKBAQF
AgESBM4BAj8abCBPcHRpb25hbC4gTWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1
cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cwogdG8gNTAuIE1heCBhbGxvd2VkIHZhbHVl
IGlzIDEwMDAuCgoNCgUEBQIBBRIEzgECBwoNCgUEBQIBARIEzgEIEQoNCgUEBQIBAxIEzgEU
FQoNCgUEBQIBCBIEzgEWPgoQCggEBQIBCJwIABIEzgEXPQqCAQoEBAUCAhIE0gECQRp0IE9w
dGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdE1v
ZGVsc2AKIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBw
YWdlLgoKDQoFBAUCAgUSBNIBAggKDQoFBAUCAgESBNIBCRMKDQoFBAUCAgMSBNIBFhcKDQoF
BAUCAggSBNIBGEAKEAoIBAUCAgicCAASBNIBGT8KLQoCBAYSBtYBAN4BARofIFJlcXVlc3Qg
Zm9yIGRlbGV0aW5nIGEgbW9kZWwuCgoLCgMEBgESBNYBCBoK0AEKBAQGAgASBtoBAt0BBBq/
ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlCiBbTW9kZWxdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhLk1vZGVsXSB0byBkZWxldGUuIEZvcm1hdDoKIGBwcm9qZWN0
cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tj
YXRhbG9nX2lkfS9tb2RlbHMve21vZGVsX2lkfWAKCg0KBQQGAgAFEgTaAQIICg0KBQQGAgAB
EgTaAQkNCg0KBQQGAgADEgTaARARCg8KBQQGAgAIEgbaARLdAQMKEAoIBAYCAAicCAASBNsB
BCoKDwoHBAYCAAifCBIE3AEETQovCgIEBxIG4QEA5wEBGiEgUmVzcG9uc2UgdG8gYSBMaXN0
TW9kZWxSZXF1ZXN0LgoKCwoDBAcBEgThAQgaCh8KBAQHAgASBOMBAhwaESBMaXN0IG9mIE1v
ZGVscy4KCg0KBQQHAgAEEgTjAQIKCg0KBQQHAgAGEgTjAQsQCg0KBQQHAgABEgTjAREXCg0K
BQQHAgADEgTjARobCkoKBAQHAgESBOYBAh0aPCBQYWdpbmF0aW9uIHRva2VuLCBpZiBub3Qg
cmV0dXJuZWQgaW5kaWNhdGVzIHRoZSBsYXN0IHBhZ2UuCgoNCgUEBwIBBRIE5gECCAoNCgUE
BwIBARIE5gEJGAoNCgUEBwIBAxIE5gEbHAqFAQoCBAgSBusBAPMBARp3IFJlcXVlc3QgdG8g
bWFudWFsbHkgc3RhcnQgYSB0dW5pbmcgcHJvY2VzcyBub3cgKGluc3RlYWQgb2Ygd2FpdGlu
ZyBmb3IKIHRoZSBwZXJpb2RpY2FsbHkgc2NoZWR1bGVkIHR1bmluZyB0byBoYXBwZW4pLgoK
CwoDBAgBEgTrAQgYCqoBCgQECAIAEgbvAQLyAQQamQEgUmVxdWlyZWQuIFRoZSByZXNvdXJj
ZSBuYW1lIG9mIHRoZSBtb2RlbCB0byB0dW5lLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2df
aWR9L21vZGVscy97bW9kZWxfaWR9YAoKDQoFBAgCAAUSBO8BAggKDQoFBAgCAAESBO8BCQ0K
DQoFBAgCAAMSBO8BEBEKDwoFBAgCAAgSBu8BEvIBAwoQCggECAIACJwIABIE8AEEKgoPCgcE
CAIACJ8IEgTxAQRNCjwKAgQJEgb2AQD7AQEaLiBNZXRhZGF0YSBhc3NvY2lhdGVkIHdpdGgg
YSBjcmVhdGUgb3BlcmF0aW9uLgoKCwoDBAkBEgT2AQgbCrIBCgQECQIAEgT6AQITGqMBIFRo
ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbCB0aGF0IHRoaXMgY3JlYXRlIGFwcGxpZXMg
dG8uCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xv
Y2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0vbW9kZWxzL3ttb2RlbF9pZH1gCgoN
CgUECQIABRIE+gECCAoNCgUECQIAARIE+gEJDgoNCgUECQIAAxIE+gEREgo6CgIEChIG/gEA
gwIBGiwgTWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRoIGEgdHVuZSBvcGVyYXRpb24uCgoLCgME
CgESBP4BCBkKsAEKBAQKAgASBIICAhMaoQEgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIG1v
ZGVsIHRoYXQgdGhpcyB0dW5lIGFwcGxpZXMgdG8uCiBGb3JtYXQ6CiBgcHJvamVjdHMve3By
b2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxv
Z19pZH0vbW9kZWxzL3ttb2RlbF9pZH1gCgoNCgUECgIABRIEggICCAoNCgUECgIAARIEggIJ
DgoNCgUECgIAAxIEggIREgo4CgIECxIEhgIAHBosIFJlc3BvbnNlIGFzc29jaWF0ZWQgd2l0
aCBhIHR1bmUgb3BlcmF0aW9uLgoKCwoDBAsBEgSGAggZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::ModelService::CreateModelRequest ===
    # Fields for CreateModelRequest
    # Field: parent Type: 9 ()
    # Field: model Type: 11 (.google.cloud.retail.v2beta.Model)
    # Field: dry_run Type: 8 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::UpdateModelRequest ===
    # Fields for UpdateModelRequest
    # Field: model Type: 11 (.google.cloud.retail.v2beta.Model)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2beta::ModelService::GetModelRequest ===
    # Fields for GetModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::PauseModelRequest ===
    # Fields for PauseModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::ResumeModelRequest ===
    # Fields for ResumeModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::DeleteModelRequest ===
    # Fields for DeleteModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.cloud.retail.v2beta.Model)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::TuneModelRequest ===
    # Fields for TuneModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::CreateModelMetadata ===
    # Fields for CreateModelMetadata
    # Field: model Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::TuneModelMetadata ===
    # Fields for TuneModelMetadata
    # Field: model Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ModelService::TuneModelResponse ===
    # Fields for TuneModelResponse

# === Service Client: Google::Cloud::Retail::V2beta::ModelService::ModelServiceClient ===
package Google::Cloud::Retail::V2beta::ModelService::ModelServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::ModelService::ModelServiceClient

Client stub representing the remote C<ModelService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub create_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ModelService::CreateModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'CreateModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ModelService::GetModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'GetModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Model::Model',
    });
}

sub pause_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ModelService::PauseModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'PauseModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Model::Model',
    });
}

sub resume_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ModelService::ResumeModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'ResumeModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Model::Model',
    });
}

sub delete_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ModelService::DeleteModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'DeleteModel',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ModelService::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::ModelService::ListModelsResponse',
    });
}

sub update_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ModelService::UpdateModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'UpdateModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::Model::Model',
    });
}

sub tune_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ModelService::TuneModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'TuneModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::ModelService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/model_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::ModelService;

    my $msg = Google::Cloud::Retail::V2beta::ModelService::CreateModelRequest->new({
        parent => $parent,
        model => $model,
        dry_run => $dry_run,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::ModelService::CreateModelRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/model_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::ModelService::CreateModelRequest

Request for creating a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource under which to create the model. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Model::Model>)

Required. The payload of the [Model][google.cloud.retail.v2beta.Model]  to
create.

=item * C<< $msg->dry_run() >> / C<< $msg->dry_run($value) >>

Type: C<Bool>

Optional. Whether to run a dry run to validate the request (without
actually creating the model).

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::UpdateModelRequest

Request for updating an existing model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Model::Model>)

Required. The body of the updated
[Model][google.cloud.retail.v2beta.Model].

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided 'model' to
update. If not set, by default updates all fields.

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::GetModelRequest

Request for getting a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Model][google.cloud.retail.v2beta.Model] to get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::PauseModelRequest

Request for pausing training of a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the model to pause.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::ResumeModelRequest

Request for resuming training of a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the model to resume.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::ListModelsRequest

Request for listing models associated with a resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent for which to list models.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 50. Max allowed value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListModels`
call. Provide this to retrieve the subsequent page.

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::DeleteModelRequest

Request for deleting a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Model][google.cloud.retail.v2beta.Model] to delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::ListModelsResponse

Response to a ListModelRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Model::Model>)

List of Models.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::TuneModelRequest

Request to manually start a tuning process now (instead of waiting for
the periodically scheduled tuning to happen).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the model to tune.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::CreateModelMetadata

Metadata associated with a create operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

The resource name of the model that this create applies to.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::TuneModelMetadata

Metadata associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

The resource name of the model that this tune applies to.
Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ModelService::TuneModelResponse

Response associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::ModelService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
