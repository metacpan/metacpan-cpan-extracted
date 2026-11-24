package Google::Cloud::Retail::V2::ModelService;

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
    eval { require Google::Cloud::Retail::V2::Model };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvcmV0YWlsL3YyL21vZGVsX3NlcnZpY2UucHJvdG8SFmdvb2dsZS5j
bG91ZC5yZXRhaWwudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGiJnb29nbGUvY2xvdWQvcmV0YWlsL3YyL21vZGVsLnBy
b3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3Byb3Rv
YnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byKrAQoS
Q3JlYXRlTW9kZWxSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEfCh1yZXRhaWwuZ29v
Z2xlYXBpcy5jb20vQ2F0YWxvZ1IGcGFyZW50EjgKBW1vZGVsGAIgASgLMh0uZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5Nb2RlbEID4EECUgVtb2RlbBIcCgdkcnlfcnVuGAMgASgIQgPgQQFS
BmRyeVJ1biKQAQoSVXBkYXRlTW9kZWxSZXF1ZXN0EjgKBW1vZGVsGAEgASgLMh0uZ29vZ2xl
LmNsb3VkLnJldGFpbC52Mi5Nb2RlbEID4EECUgVtb2RlbBJACgt1cGRhdGVfbWFzaxgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayJKCg9HZXRN
b2RlbFJlcXVlc3QSNwoEbmFtZRgBIAEoCUIj4EEC+kEdChtyZXRhaWwuZ29vZ2xlYXBpcy5j
b20vTW9kZWxSBG5hbWUiTAoRUGF1c2VNb2RlbFJlcXVlc3QSNwoEbmFtZRgBIAEoCUIj4EEC
+kEdChtyZXRhaWwuZ29vZ2xlYXBpcy5jb20vTW9kZWxSBG5hbWUiLQoSUmVzdW1lTW9kZWxS
ZXF1ZXN0EhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZSKYAQoRTGlzdE1vZGVsc1JlcXVlc3QS
PQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9DYXRhbG9n
UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9r
ZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIk0KEkRlbGV0ZU1vZGVsUmVxdWVzdBI3CgRuYW1l
GAEgASgJQiPgQQL6QR0KG3JldGFpbC5nb29nbGVhcGlzLmNvbS9Nb2RlbFIEbmFtZSJzChJM
aXN0TW9kZWxzUmVzcG9uc2USNQoGbW9kZWxzGAEgAygLMh0uZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5Nb2RlbFIGbW9kZWxzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VU
b2tlbiJLChBUdW5lTW9kZWxSZXF1ZXN0EjcKBG5hbWUYASABKAlCI+BBAvpBHQobcmV0YWls
Lmdvb2dsZWFwaXMuY29tL01vZGVsUgRuYW1lIisKE0NyZWF0ZU1vZGVsTWV0YWRhdGESFAoF
bW9kZWwYASABKAlSBW1vZGVsIikKEVR1bmVNb2RlbE1ldGFkYXRhEhQKBW1vZGVsGAEgASgJ
UgVtb2RlbCITChFUdW5lTW9kZWxSZXNwb25zZTLFDAoMTW9kZWxTZXJ2aWNlEvsBCgtDcmVh
dGVNb2RlbBIqLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ3JlYXRlTW9kZWxSZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKgAYLT5JMCPiI1L3YyL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9tb2RlbHM6BW1vZGVs2kEMcGFyZW50
LG1vZGVsykFKChxnb29nbGUuY2xvdWQucmV0YWlsLnYyLk1vZGVsEipnb29nbGUuY2xvdWQu
cmV0YWlsLnYyLkNyZWF0ZU1vZGVsTWV0YWRhdGESmAEKCEdldE1vZGVsEicuZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5HZXRNb2RlbFJlcXVlc3QaHS5nb29nbGUuY2xvdWQucmV0YWlsLnYy
Lk1vZGVsIkSC0+STAjcSNS92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFs
b2dzLyovbW9kZWxzLyp92kEEbmFtZRKlAQoKUGF1c2VNb2RlbBIpLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuUGF1c2VNb2RlbFJlcXVlc3QaHS5nb29nbGUuY2xvdWQucmV0YWlsLnYyLk1v
ZGVsIk2C0+STAkAiOy92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dz
LyovbW9kZWxzLyp9OnBhdXNlOgEq2kEEbmFtZRKoAQoLUmVzdW1lTW9kZWwSKi5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyLlJlc3VtZU1vZGVsUmVxdWVzdBodLmdvb2dsZS5jbG91ZC5yZXRh
aWwudjIuTW9kZWwiToLT5JMCQSI8L3YyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
Y2F0YWxvZ3MvKi9tb2RlbHMvKn06cmVzdW1lOgEq2kEEbmFtZRKXAQoLRGVsZXRlTW9kZWwS
Ki5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkRlbGV0ZU1vZGVsUmVxdWVzdBoWLmdvb2dsZS5w
cm90b2J1Zi5FbXB0eSJEgtPkkwI3KjUvdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jYXRhbG9ncy8qL21vZGVscy8qfdpBBG5hbWUSqwEKCkxpc3RNb2RlbHMSKS5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyLkxpc3RNb2RlbHNSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5MaXN0TW9kZWxzUmVzcG9uc2UiRoLT5JMCNxI1L3YyL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfS9tb2RlbHPaQQZwYXJlbnQSuAEKC1VwZGF0ZU1v
ZGVsEiouZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5VcGRhdGVNb2RlbFJlcXVlc3QaHS5nb29n
bGUuY2xvdWQucmV0YWlsLnYyLk1vZGVsIl6C0+STAkQyOy92Mi97bW9kZWwubmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovbW9kZWxzLyp9OgVtb2RlbNpBEW1vZGVs
LHVwZGF0ZV9tYXNrEvoBCglUdW5lTW9kZWwSKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlR1
bmVNb2RlbFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqMBgtPkkwI/
IjovdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qL21vZGVscy8q
fTp0dW5lOgEq2kEEbmFtZcpBVAooZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5UdW5lTW9kZWxS
ZXNwb25zZRIoZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5UdW5lTW9kZWxNZXRhZGF0YRpJykEV
cmV0YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybUK8AQoaY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJCEU1vZGVs
U2VydmljZVByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyL3JldGFp
bHBiO3JldGFpbHBiogIGUkVUQUlMqgIWR29vZ2xlLkNsb3VkLlJldGFpbC5WMsoCFkdvb2ds
ZVxDbG91ZFxSZXRhaWxcVjLqAhlHb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYySvo6CgcSBQ4A
hQIcCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMA
EgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYALAoJCgID
BRIDFwAtCgkKAgMGEgMYACUKCQoCAwcSAxkAKgoICgEIEgMbADMKCQoCCCUSAxsAMwoICgEI
EgMcAEkKCQoCCAsSAxwASQoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeADIKCQoCCAgS
Ax4AMgoICgEIEgMfADMKCQoCCAESAx8AMwoICgEIEgMgACQKCQoCCCQSAyAAJAoICgEIEgMh
ADMKCQoCCCkSAyEAMwoICgEIEgMiADIKCQoCCC0SAyIAMgqdBAoCBgASBTAAhAEBGo8EIFNl
cnZpY2UgZm9yIHBlcmZvcm1pbmcgQ1JVRCBvcGVyYXRpb25zIG9uIG1vZGVscy4KIFJlY29t
bWVuZGF0aW9uIG1vZGVscyBjb250YWluIGFsbCB0aGUgbWV0YWRhdGEgbmVjZXNzYXJ5IHRv
IGdlbmVyYXRlIGEgc2V0IG9mCiBtb2RlbHMgZm9yIHRoZSBgUHJlZGljdCgpYCBBUEkuIEEg
bW9kZWwgaXMgcXVlcmllZAogaW5kaXJlY3RseSB2aWEgYSBTZXJ2aW5nQ29uZmlnLCB3aGlj
aCBhc3NvY2lhdGVzIGEgbW9kZWwgd2l0aCBhCiBnaXZlbiBQbGFjZW1lbnQgKGUuZy4gRnJl
cXVlbnRseSBCb3VnaHQgVG9nZXRoZXIgb24gSG9tZSBQYWdlKS4KCiBUaGlzIHNlcnZpY2Ug
YWxsb3dzIHlvdSB0byBkbyB0aGUgZm9sbG93aW5nOgoKICogSW5pdGlhdGUgdHJhaW5pbmcg
b2YgYSBtb2RlbC4KICogUGF1c2UgdHJhaW5pbmcgb2YgYW4gZXhpc3RpbmcgbW9kZWwuCiAq
IExpc3QgYWxsIHRoZSBhdmFpbGFibGUgbW9kZWxzIGFsb25nIHdpdGggdGhlaXIgbWV0YWRh
dGEuCiAqIENvbnRyb2wgdGhlaXIgdHVuaW5nIHNjaGVkdWxlLgoKCgoDBgABEgMwCBQKCgoD
BgADEgMxAj0KDAoFBgADmQgSAzECPQoLCgMGAAMSBDICMzcKDQoFBgADmggSBDICMzcKJAoE
BgACABIENgJAAxoWIENyZWF0ZXMgYSBuZXcgbW9kZWwuCgoMCgUGAAIAARIDNgYRCgwKBQYA
AgACEgM2EiQKDAoFBgACAAMSAzYvSwoNCgUGAAIABBIENwQ6BgoRCgkGAAIABLDKvCISBDcE
OgYKDAoFBgACAAQSAzsEOgoPCggGAAIABJsIABIDOwQ6Cg0KBQYAAgAEEgQ8BD8GCg8KBwYA
AgAEmQgSBDwEPwYKHQoEBgACARIEQwJIAxoPIEdldHMgYSBtb2RlbC4KCgwKBQYAAgEBEgND
Bg4KDAoFBgACAQISA0MPHgoMCgUGAAIBAxIDQykuCg0KBQYAAgEEEgREBEYGChEKCQYAAgEE
sMq8IhIERARGBgoMCgUGAAIBBBIDRwQyCg8KCAYAAgEEmwgAEgNHBDIKOQoEBgACAhIESwJR
AxorIFBhdXNlcyB0aGUgdHJhaW5pbmcgb2YgYW4gZXhpc3RpbmcgbW9kZWwuCgoMCgUGAAIC
ARIDSwYQCgwKBQYAAgICEgNLESIKDAoFBgACAgMSA0stMgoNCgUGAAICBBIETARPBgoRCgkG
AAICBLDKvCISBEwETwYKDAoFBgACAgQSA1AEMgoPCggGAAICBJsIABIDUAQyCjoKBAYAAgMS
BFQCWgMaLCBSZXN1bWVzIHRoZSB0cmFpbmluZyBvZiBhbiBleGlzdGluZyBtb2RlbC4KCgwK
BQYAAgMBEgNUBhEKDAoFBgACAwISA1QSJAoMCgUGAAIDAxIDVC80Cg0KBQYAAgMEEgRVBFgG
ChEKCQYAAgMEsMq8IhIEVQRYBgoMCgUGAAIDBBIDWQQyCg8KCAYAAgMEmwgAEgNZBDIKKgoE
BgACBBIEXQJiAxocIERlbGV0ZXMgYW4gZXhpc3RpbmcgbW9kZWwuCgoMCgUGAAIEARIDXQYR
CgwKBQYAAgQCEgNdEiQKDAoFBgACBAMSA10vRAoNCgUGAAIEBBIEXgRgBgoRCgkGAAIEBLDK
vCISBF4EYAYKDAoFBgACBAQSA2EEMgoPCggGAAIEBJsIABIDYQQyCkAKBAYAAgUSBGUCagMa
MiBMaXN0cyBhbGwgdGhlIG1vZGVscyBsaW5rZWQgdG8gdGhpcyBldmVudCBzdG9yZS4KCgwK
BQYAAgUBEgNlBhAKDAoFBgACBQISA2URIgoMCgUGAAIFAxIDZS0/Cg0KBQYAAgUEEgRmBGgG
ChEKCQYAAgUEsMq8IhIEZgRoBgoMCgUGAAIFBBIDaQQ0Cg8KCAYAAgUEmwgAEgNpBDQKyAEK
BAYAAgYSBHACdgMauQEgVXBkYXRlIG9mIG1vZGVsIG1ldGFkYXRhLiBPbmx5IGZpZWxkcyB0
aGF0CiBjdXJyZW50bHkgY2FuIGJlIHVwZGF0ZWQgYXJlOiBgZmlsdGVyaW5nX29wdGlvbmAg
YW5kCiBgcGVyaW9kaWNfdHVuaW5nX3N0YXRlYC4KIElmIG90aGVyIHZhbHVlcyBhcmUgcHJv
dmlkZWQsIHRoaXMgQVBJIG1ldGhvZCBpZ25vcmVzIHRoZW0uCgoMCgUGAAIGARIDcAYRCgwK
BQYAAgYCEgNwEiQKDAoFBgACBgMSA3AvNAoNCgUGAAIGBBIEcQR0BgoRCgkGAAIGBLDKvCIS
BHEEdAYKDAoFBgACBgQSA3UEPwoPCggGAAIGBJsIABIDdQQ/CikKBAYAAgcSBXkCgwEDGhog
VHVuZXMgYW4gZXhpc3RpbmcgbW9kZWwuCgoMCgUGAAIHARIDeQYPCgwKBQYAAgcCEgN5ECAK
DAoFBgACBwMSA3krRwoNCgUGAAIHBBIEegR9BgoRCgkGAAIHBLDKvCISBHoEfQYKDAoFBgAC
BwQSA34EMgoPCggGAAIHBJsIABIDfgQyCg4KBQYAAgcEEgV/BIIBBgoQCgcGAAIHBJkIEgV/
BIIBBgotCgIEABIGhwEAlgEBGh8gUmVxdWVzdCBmb3IgY3JlYXRpbmcgYSBtb2RlbC4KCgsK
AwQAARIEhwEIGgqkAQoEBAACABIGigECjQEEGpMBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJl
c291cmNlIHVuZGVyIHdoaWNoIHRvIGNyZWF0ZSB0aGUgbW9kZWwuIEZvcm1hdDoKIGBwcm9q
ZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dz
L3tjYXRhbG9nX2lkfWAKCg0KBQQAAgAFEgSKAQIICg0KBQQAAgABEgSKAQkPCg0KBQQAAgAD
EgSKARITCg8KBQQAAgAIEgaKARSNAQMKEAoIBAACAAicCAASBIsBBCoKDwoHBAACAAifCBIE
jAEETwpfCgQEAAIBEgSRAQI7GlEgUmVxdWlyZWQuIFRoZSBwYXlsb2FkIG9mIHRoZSBbTW9k
ZWxdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuTW9kZWxdICB0bwogY3JlYXRlLgoKDQoFBAAC
AQYSBJEBAgcKDQoFBAACAQESBJEBCA0KDQoFBAACAQMSBJEBEBEKDQoFBAACAQgSBJEBEjoK
EAoIBAACAQicCAASBJEBEzkKcgoEBAACAhIElQECPBpkIE9wdGlvbmFsLiBXaGV0aGVyIHRv
IHJ1biBhIGRyeSBydW4gdG8gdmFsaWRhdGUgdGhlIHJlcXVlc3QgKHdpdGhvdXQKIGFjdHVh
bGx5IGNyZWF0aW5nIHRoZSBtb2RlbCkuCgoNCgUEAAICBRIElQECBgoNCgUEAAICARIElQEH
DgoNCgUEAAICAxIElQEREgoNCgUEAAICCBIElQETOwoQCggEAAICCJwIABIElQEUOgo3CgIE
ARIGmQEAoQEBGikgUmVxdWVzdCBmb3IgdXBkYXRpbmcgYW4gZXhpc3RpbmcgbW9kZWwuCgoL
CgMEAQESBJkBCBoKWAoEBAECABIEmwECOxpKIFJlcXVpcmVkLiBUaGUgYm9keSBvZiB0aGUg
dXBkYXRlZCBbTW9kZWxdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuTW9kZWxdLgoKDQoFBAEC
AAYSBJsBAgcKDQoFBAECAAESBJsBCA0KDQoFBAECAAMSBJsBEBEKDQoFBAECAAgSBJsBEjoK
EAoIBAECAAicCAASBJsBEzkKgQEKBAQBAgESBp8BAqABLxpxIE9wdGlvbmFsLiBJbmRpY2F0
ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZCAnbW9kZWwnIHRvCiB1cGRhdGUuIElm
IG5vdCBzZXQsIGJ5IGRlZmF1bHQgdXBkYXRlcyBhbGwgZmllbGRzLgoKDQoFBAECAQYSBJ8B
AhsKDQoFBAECAQESBJ8BHCcKDQoFBAECAQMSBJ8BKisKDQoFBAECAQgSBKABBi4KEAoIBAEC
AQicCAASBKABBy0KLAoCBAISBqQBAKwBARoeIFJlcXVlc3QgZm9yIGdldHRpbmcgYSBtb2Rl
bC4KCgsKAwQCARIEpAEIFwrGAQoEBAICABIGqAECqwEEGrUBIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgW01vZGVsXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLk1vZGVs
XSB0bwogZ2V0LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlv
bnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ30vbW9kZWxzL3ttb2RlbF9pZH1g
CgoNCgUEAgIABRIEqAECCAoNCgUEAgIAARIEqAEJDQoNCgUEAgIAAxIEqAEQEQoPCgUEAgIA
CBIGqAESqwEDChAKCAQCAgAInAgAEgSpAQQqCg8KBwQCAgAInwgSBKoBBE0KOAoCBAMSBq8B
ALcBARoqIFJlcXVlc3QgZm9yIHBhdXNpbmcgdHJhaW5pbmcgb2YgYSBtb2RlbC4KCgsKAwQD
ARIErwEIGQqiAQoEBAMCABIGswECtgEEGpEBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUg
bW9kZWwgdG8gcGF1c2UuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9s
b2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0vbW9kZWxzL3tt
b2RlbF9pZH1gCgoNCgUEAwIABRIEswECCAoNCgUEAwIAARIEswEJDQoNCgUEAwIAAxIEswEQ
EQoPCgUEAwIACBIGswEStgEDChAKCAQDAgAInAgAEgS0AQQqCg8KBwQDAgAInwgSBLUBBE0K
OQoCBAQSBroBAL8BARorIFJlcXVlc3QgZm9yIHJlc3VtaW5nIHRyYWluaW5nIG9mIGEgbW9k
ZWwuCgoLCgMEBAESBLoBCBoKoQEKBAQEAgASBL4BAjsakgEgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBtb2RlbCB0byByZXN1bWUuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3Rf
bnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0v
bW9kZWxzL3ttb2RlbF9pZH1gCgoNCgUEBAIABRIEvgECCAoNCgUEBAIAARIEvgEJDQoNCgUE
BAIAAxIEvgEQEQoNCgUEBAIACBIEvgESOgoQCggEBAIACJwIABIEvgETOQpGCgIEBRIGwgEA
0gEBGjggUmVxdWVzdCBmb3IgbGlzdGluZyBtb2RlbHMgYXNzb2NpYXRlZCB3aXRoIGEgcmVz
b3VyY2UuCgoLCgMEBQESBMIBCBkKlQEKBAQFAgASBsYBAskBBBqEASBSZXF1aXJlZC4gVGhl
IHBhcmVudCBmb3Igd2hpY2ggdG8gbGlzdCBtb2RlbHMuCiBGb3JtYXQ6CiBgcHJvamVjdHMv
e3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0
YWxvZ19pZH1gCgoNCgUEBQIABRIExgECCAoNCgUEBQIAARIExgEJDwoNCgUEBQIAAxIExgES
EwoPCgUEBQIACBIGxgEUyQEDChAKCAQFAgAInAgAEgTHAQQqCg8KBwQFAgAInwgSBMgBBE8K
egoEBAUCARIEzQECPxpsIE9wdGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZiByZXN1bHRzIHRv
IHJldHVybi4gSWYgdW5zcGVjaWZpZWQsIGRlZmF1bHRzCiB0byA1MC4gTWF4IGFsbG93ZWQg
dmFsdWUgaXMgMTAwMC4KCg0KBQQFAgEFEgTNAQIHCg0KBQQFAgEBEgTNAQgRCg0KBQQFAgED
EgTNARQVCg0KBQQFAgEIEgTNARY+ChAKCAQFAgEInAgAEgTNARc9CoIBCgQEBQICEgTRAQJB
GnQgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBM
aXN0TW9kZWxzYAogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1
ZW50IHBhZ2UuCgoNCgUEBQICBRIE0QECCAoNCgUEBQICARIE0QEJEwoNCgUEBQICAxIE0QEW
FwoNCgUEBQICCBIE0QEYQAoQCggEBQICCJwIABIE0QEZPwotCgIEBhIG1QEA3QEBGh8gUmVx
dWVzdCBmb3IgZGVsZXRpbmcgYSBtb2RlbC4KCgsKAwQGARIE1QEIGgrMAQoEBAYCABIG2QEC
3AEEGrsBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgW01vZGVsXVtnb29n
bGUuY2xvdWQucmV0YWlsLnYyLk1vZGVsXSB0bwogZGVsZXRlLiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97
Y2F0YWxvZ19pZH0vbW9kZWxzL3ttb2RlbF9pZH1gCgoNCgUEBgIABRIE2QECCAoNCgUEBgIA
ARIE2QEJDQoNCgUEBgIAAxIE2QEQEQoPCgUEBgIACBIG2QES3AEDChAKCAQGAgAInAgAEgTa
AQQqCg8KBwQGAgAInwgSBNsBBE0KLwoCBAcSBuABAOYBARohIFJlc3BvbnNlIHRvIGEgTGlz
dE1vZGVsUmVxdWVzdC4KCgsKAwQHARIE4AEIGgofCgQEBwIAEgTiAQIcGhEgTGlzdCBvZiBN
b2RlbHMuCgoNCgUEBwIABBIE4gECCgoNCgUEBwIABhIE4gELEAoNCgUEBwIAARIE4gERFwoN
CgUEBwIAAxIE4gEaGwpKCgQEBwIBEgTlAQIdGjwgUGFnaW5hdGlvbiB0b2tlbiwgaWYgbm90
IHJldHVybmVkIGluZGljYXRlcyB0aGUgbGFzdCBwYWdlLgoKDQoFBAcCAQUSBOUBAggKDQoF
BAcCAQESBOUBCRgKDQoFBAcCAQMSBOUBGxwKhQEKAgQIEgbqAQDyAQEadyBSZXF1ZXN0IHRv
IG1hbnVhbGx5IHN0YXJ0IGEgdHVuaW5nIHByb2Nlc3Mgbm93IChpbnN0ZWFkIG9mIHdhaXRp
bmcgZm9yCiB0aGUgcGVyaW9kaWNhbGx5IHNjaGVkdWxlZCB0dW5pbmcgdG8gaGFwcGVuKS4K
CgsKAwQIARIE6gEIGAqqAQoEBAgCABIG7gEC8QEEGpkBIFJlcXVpcmVkLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgbW9kZWwgdG8gdHVuZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJv
amVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9n
X2lkfS9tb2RlbHMve21vZGVsX2lkfWAKCg0KBQQIAgAFEgTuAQIICg0KBQQIAgABEgTuAQkN
Cg0KBQQIAgADEgTuARARCg8KBQQIAgAIEgbuARLxAQMKEAoIBAgCAAicCAASBO8BBCoKDwoH
BAgCAAifCBIE8AEETQo8CgIECRIG9QEA+gEBGi4gTWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRo
IGEgY3JlYXRlIG9wZXJhdGlvbi4KCgsKAwQJARIE9QEIGwqyAQoEBAkCABIE+QECExqjASBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbW9kZWwgdGhhdCB0aGlzIGNyZWF0ZSBhcHBsaWVz
IHRvLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3ts
b2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L21vZGVscy97bW9kZWxfaWR9YAoK
DQoFBAkCAAUSBPkBAggKDQoFBAkCAAESBPkBCQ4KDQoFBAkCAAMSBPkBERIKOgoCBAoSBv0B
AIICARosIE1ldGFkYXRhIGFzc29jaWF0ZWQgd2l0aCBhIHR1bmUgb3BlcmF0aW9uLgoKCwoD
BAoBEgT9AQgZCrABCgQECgIAEgSBAgITGqEBIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBt
b2RlbCB0aGF0IHRoaXMgdHVuZSBhcHBsaWVzIHRvLgogRm9ybWF0OgogYHByb2plY3RzL3tw
cm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFs
b2dfaWR9L21vZGVscy97bW9kZWxfaWR9YAoKDQoFBAoCAAUSBIECAggKDQoFBAoCAAESBIEC
CQ4KDQoFBAoCAAMSBIECERIKOAoCBAsSBIUCABwaLCBSZXNwb25zZSBhc3NvY2lhdGVkIHdp
dGggYSB0dW5lIG9wZXJhdGlvbi4KCgsKAwQLARIEhQIIGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::ModelService::CreateModelRequest ===
    # Fields for CreateModelRequest
    # Field: parent Type: 9 ()
    # Field: model Type: 11 (.google.cloud.retail.v2.Model)
    # Field: dry_run Type: 8 ()

# === Message: Google::Cloud::Retail::V2::ModelService::UpdateModelRequest ===
    # Fields for UpdateModelRequest
    # Field: model Type: 11 (.google.cloud.retail.v2.Model)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2::ModelService::GetModelRequest ===
    # Fields for GetModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::PauseModelRequest ===
    # Fields for PauseModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::ResumeModelRequest ===
    # Fields for ResumeModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::DeleteModelRequest ===
    # Fields for DeleteModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.cloud.retail.v2.Model)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::TuneModelRequest ===
    # Fields for TuneModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::CreateModelMetadata ===
    # Fields for CreateModelMetadata
    # Field: model Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::TuneModelMetadata ===
    # Fields for TuneModelMetadata
    # Field: model Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ModelService::TuneModelResponse ===
    # Fields for TuneModelResponse

# === Service Client: Google::Cloud::Retail::V2::ModelService::ModelServiceClient ===
package Google::Cloud::Retail::V2::ModelService::ModelServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::ModelService::ModelServiceClient

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
        ? Google::Cloud::Retail::V2::ModelService::CreateModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'CreateModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ModelService::GetModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'GetModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Model::Model',
    });
}

sub pause_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ModelService::PauseModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'PauseModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Model::Model',
    });
}

sub resume_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ModelService::ResumeModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'ResumeModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Model::Model',
    });
}

sub delete_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ModelService::DeleteModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'DeleteModel',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ModelService::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::ModelService::ListModelsResponse',
    });
}

sub update_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ModelService::UpdateModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'UpdateModel',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Model::Model',
    });
}

sub tune_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::ModelService::TuneModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'TuneModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::ModelService - Compiled Protocol Buffers messages for google/cloud/retail/v2/model_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::ModelService;

    my $msg = Google::Cloud::Retail::V2::ModelService::CreateModelRequest->new({
        parent => $parent,
        model => $model,
        dry_run => $dry_run,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::ModelService::CreateModelRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/model_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::ModelService::CreateModelRequest

Request for creating a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource under which to create the model. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Model::Model>)

Required. The payload of the [Model][google.cloud.retail.v2.Model]  to
create.

=item * C<< $msg->dry_run() >> / C<< $msg->dry_run($value) >>

Type: C<Bool>

Optional. Whether to run a dry run to validate the request (without
actually creating the model).

=back

=head2 Google::Cloud::Retail::V2::ModelService::UpdateModelRequest

Request for updating an existing model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Model::Model>)

Required. The body of the updated [Model][google.cloud.retail.v2.Model].

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided 'model' to
update. If not set, by default updates all fields.

=back

=head2 Google::Cloud::Retail::V2::ModelService::GetModelRequest

Request for getting a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the [Model][google.cloud.retail.v2.Model] to
get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2::ModelService::PauseModelRequest

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

=head2 Google::Cloud::Retail::V2::ModelService::ResumeModelRequest

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

=head2 Google::Cloud::Retail::V2::ModelService::ListModelsRequest

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

=head2 Google::Cloud::Retail::V2::ModelService::DeleteModelRequest

Request for deleting a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the [Model][google.cloud.retail.v2.Model] to
delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`

=back

=head2 Google::Cloud::Retail::V2::ModelService::ListModelsResponse

Response to a ListModelRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Model::Model>)

List of Models.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head2 Google::Cloud::Retail::V2::ModelService::TuneModelRequest

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

=head2 Google::Cloud::Retail::V2::ModelService::CreateModelMetadata

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

=head2 Google::Cloud::Retail::V2::ModelService::TuneModelMetadata

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

=head2 Google::Cloud::Retail::V2::ModelService::TuneModelResponse

Response associated with a tune operation.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::ModelService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
