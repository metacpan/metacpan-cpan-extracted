package Google::Cloud::Dataproc::V1::SessionTemplates;

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
    eval { require Google::Cloud::Dataproc::V1::Sessions };
    eval { require Google::Cloud::Dataproc::V1::Shared };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGF0YXByb2MvdjEvc2Vzc2lvbl90ZW1wbGF0ZXMucHJvdG8SGGdv
b2dsZS5jbG91ZC5kYXRhcHJvYy52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJ2dvb2dsZS9jbG91ZC9kYXRhcHJvYy92
MS9zZXNzaW9ucy5wcm90bxolZ29vZ2xlL2Nsb3VkL2RhdGFwcm9jL3YxL3NoYXJlZC5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvIsIBChxDcmVhdGVTZXNzaW9uVGVtcGxhdGVSZXF1ZXN0EkcKBnBhcmVudBgB
IAEoCUIv4EEC+kEpEidkYXRhcHJvYy5nb29nbGVhcGlzLmNvbS9TZXNzaW9uVGVtcGxhdGVS
BnBhcmVudBJZChBzZXNzaW9uX3RlbXBsYXRlGAMgASgLMikuZ29vZ2xlLmNsb3VkLmRhdGFw
cm9jLnYxLlNlc3Npb25UZW1wbGF0ZUID4EECUg9zZXNzaW9uVGVtcGxhdGUieQocVXBkYXRl
U2Vzc2lvblRlbXBsYXRlUmVxdWVzdBJZChBzZXNzaW9uX3RlbXBsYXRlGAEgASgLMikuZ29v
Z2xlLmNsb3VkLmRhdGFwcm9jLnYxLlNlc3Npb25UZW1wbGF0ZUID4EECUg9zZXNzaW9uVGVt
cGxhdGUiYAoZR2V0U2Vzc2lvblRlbXBsYXRlUmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6
QSkKJ2RhdGFwcm9jLmdvb2dsZWFwaXMuY29tL1Nlc3Npb25UZW1wbGF0ZVIEbmFtZSLJAQob
TGlzdFNlc3Npb25UZW1wbGF0ZXNSZXF1ZXN0EkcKBnBhcmVudBgBIAEoCUIv4EEC+kEpEidk
YXRhcHJvYy5nb29nbGVhcGlzLmNvbS9TZXNzaW9uVGVtcGxhdGVSBnBhcmVudBIgCglwYWdl
X3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglw
YWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlciKjAQocTGlzdFNlc3Npb25U
ZW1wbGF0ZXNSZXNwb25zZRJbChFzZXNzaW9uX3RlbXBsYXRlcxgBIAMoCzIpLmdvb2dsZS5j
bG91ZC5kYXRhcHJvYy52MS5TZXNzaW9uVGVtcGxhdGVCA+BBA1IQc2Vzc2lvblRlbXBsYXRl
cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iYwocRGVsZXRlU2Vz
c2lvblRlbXBsYXRlUmVxdWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ2RhdGFwcm9jLmdv
b2dsZWFwaXMuY29tL1Nlc3Npb25UZW1wbGF0ZVIEbmFtZSKcBwoPU2Vzc2lvblRlbXBsYXRl
EhoKBG5hbWUYASABKAlCBuBBAuBBCFIEbmFtZRIlCgtkZXNjcmlwdGlvbhgJIAEoCUID4EEB
UgtkZXNjcmlwdGlvbhJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJXCg9qdXB5dGVyX3Nlc3Npb24YAyABKAsyJy5n
b29nbGUuY2xvdWQuZGF0YXByb2MudjEuSnVweXRlckNvbmZpZ0ID4EEBSABSDmp1cHl0ZXJT
ZXNzaW9uEmcKFXNwYXJrX2Nvbm5lY3Rfc2Vzc2lvbhgLIAEoCzIsLmdvb2dsZS5jbG91ZC5k
YXRhcHJvYy52MS5TcGFya0Nvbm5lY3RDb25maWdCA+BBAUgAUhNzcGFya0Nvbm5lY3RTZXNz
aW9uEh0KB2NyZWF0b3IYBSABKAlCA+BBA1IHY3JlYXRvchJSCgZsYWJlbHMYBiADKAsyNS5n
b29nbGUuY2xvdWQuZGF0YXByb2MudjEuU2Vzc2lvblRlbXBsYXRlLkxhYmVsc0VudHJ5QgPg
QQFSBmxhYmVscxJTCg5ydW50aW1lX2NvbmZpZxgHIAEoCzInLmdvb2dsZS5jbG91ZC5kYXRh
cHJvYy52MS5SdW50aW1lQ29uZmlnQgPgQQFSDXJ1bnRpbWVDb25maWcSXwoSZW52aXJvbm1l
bnRfY29uZmlnGAggASgLMisuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkVudmlyb25tZW50
Q29uZmlnQgPgQQFSEWVudmlyb25tZW50Q29uZmlnEkAKC3VwZGF0ZV90aW1lGAogASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEhcKBHV1aWQYDCAB
KAlCA+BBA1IEdXVpZBo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1
ZRgCIAEoCVIFdmFsdWU6AjgBOnHqQW4KJ2RhdGFwcm9jLmdvb2dsZWFwaXMuY29tL1Nlc3Np
b25UZW1wbGF0ZRJDcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Nl
c3Npb25UZW1wbGF0ZXMve3RlbXBsYXRlfUIQCg5zZXNzaW9uX2NvbmZpZzLYCQoZU2Vzc2lv
blRlbXBsYXRlQ29udHJvbGxlchLkAQoVQ3JlYXRlU2Vzc2lvblRlbXBsYXRlEjYuZ29vZ2xl
LmNsb3VkLmRhdGFwcm9jLnYxLkNyZWF0ZVNlc3Npb25UZW1wbGF0ZVJlcXVlc3QaKS5nb29n
bGUuY2xvdWQuZGF0YXByb2MudjEuU2Vzc2lvblRlbXBsYXRlImiC0+STAkgiNC92MS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3Nlc3Npb25UZW1wbGF0ZXM6EHNlc3Npb25f
dGVtcGxhdGXaQRdwYXJlbnQsc2Vzc2lvbl90ZW1wbGF0ZRLuAQoVVXBkYXRlU2Vzc2lvblRl
bXBsYXRlEjYuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLlVwZGF0ZVNlc3Npb25UZW1wbGF0
ZVJlcXVlc3QaKS5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuU2Vzc2lvblRlbXBsYXRlInKC
0+STAlkyRS92MS97c2Vzc2lvbl90ZW1wbGF0ZS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25z
Lyovc2Vzc2lvblRlbXBsYXRlcy8qfToQc2Vzc2lvbl90ZW1wbGF0ZdpBEHNlc3Npb25fdGVt
cGxhdGUSuQEKEkdldFNlc3Npb25UZW1wbGF0ZRIzLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52
MS5HZXRTZXNzaW9uVGVtcGxhdGVSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYx
LlNlc3Npb25UZW1wbGF0ZSJDgtPkkwI2EjQvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9zZXNzaW9uVGVtcGxhdGVzLyp92kEEbmFtZRLMAQoUTGlzdFNlc3Npb25UZW1wbGF0
ZXMSNS5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuTGlzdFNlc3Npb25UZW1wbGF0ZXNSZXF1
ZXN0GjYuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkxpc3RTZXNzaW9uVGVtcGxhdGVzUmVz
cG9uc2UiRYLT5JMCNhI0L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vc2Vz
c2lvblRlbXBsYXRlc9pBBnBhcmVudBKsAQoVRGVsZXRlU2Vzc2lvblRlbXBsYXRlEjYuZ29v
Z2xlLmNsb3VkLmRhdGFwcm9jLnYxLkRlbGV0ZVNlc3Npb25UZW1wbGF0ZVJlcXVlc3QaFi5n
b29nbGUucHJvdG9idWYuRW1wdHkiQ4LT5JMCNio0L3YxL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovc2Vzc2lvblRlbXBsYXRlcy8qfdpBBG5hbWUaqAHKQRdkYXRhcHJvYy5nb29n
bGVhcGlzLmNvbdJBigFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBs
YXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGF0YXByb2MsaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kYXRhcHJvYy5yZWFkLW9ubHlCdAocY29tLmdv
b2dsZS5jbG91ZC5kYXRhcHJvYy52MUIVU2Vzc2lvblRlbXBsYXRlc1Byb3RvUAFaO2Nsb3Vk
Lmdvb2dsZS5jb20vZ28vZGF0YXByb2MvdjIvYXBpdjEvZGF0YXByb2NwYjtkYXRhcHJvY3Bi
SqMyCgcSBQ4A3QEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
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
EAAhCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQS
AxYAMQoJCgIDBRIDFwAvCgkKAgMGEgMYACUKCQoCAwcSAxkAKQoICgEIEgMbAFIKCQoCCAsS
AxsAUgoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADYKCQoCCAgSAx0ANgoICgEIEgMe
ADUKCQoCCAESAx4ANQpZCgIGABIEIQBVARpNIFRoZSBTZXNzaW9uVGVtcGxhdGVDb250cm9s
bGVyIHByb3ZpZGVzIG1ldGhvZHMgdG8gbWFuYWdlIHNlc3Npb24gdGVtcGxhdGVzLgoKCgoD
BgABEgMhCCEKCgoDBgADEgMiAj8KDAoFBgADmQgSAyICPwoLCgMGAAMSBCMCJjsKDQoFBgAD
mggSBCMCJjsKOAoEBgACABIEKQIwAxoqIENyZWF0ZSBhIHNlc3Npb24gdGVtcGxhdGUgc3lu
Y2hyb25vdXNseS4KCgwKBQYAAgABEgMpBhsKDAoFBgACAAISAykcOAoMCgUGAAIAAxIDKg8e
Cg0KBQYAAgAEEgQrBC4GChEKCQYAAgAEsMq8IhIEKwQuBgoMCgUGAAIABBIDLwRFCg8KCAYA
AgAEmwgAEgMvBEUKOwoEBgACARIEMwI6AxotIFVwZGF0ZXMgdGhlIHNlc3Npb24gdGVtcGxh
dGUgc3luY2hyb25vdXNseS4KCgwKBQYAAgEBEgMzBhsKDAoFBgACAQISAzMcOAoMCgUGAAIB
AxIDNA8eCg0KBQYAAgEEEgQ1BDgGChEKCQYAAgEEsMq8IhIENQQ4BgoMCgUGAAIBBBIDOQQ+
Cg8KCAYAAgEEmwgAEgM5BD4KSAoEBgACAhIEPQJCAxo6IEdldHMgdGhlIHJlc291cmNlIHJl
cHJlc2VudGF0aW9uIGZvciBhIHNlc3Npb24gdGVtcGxhdGUuCgoMCgUGAAICARIDPQYYCgwK
BQYAAgICEgM9GTIKDAoFBgACAgMSAz09TAoNCgUGAAICBBIEPgRABgoRCgkGAAICBLDKvCIS
BD4EQAYKDAoFBgACAgQSA0EEMgoPCggGAAICBJsIABIDQQQyCigKBAYAAgMSBEUCSwMaGiBM
aXN0cyBzZXNzaW9uIHRlbXBsYXRlcy4KCgwKBQYAAgMBEgNFBhoKDAoFBgACAwISA0UbNgoM
CgUGAAIDAxIDRg8rCg0KBQYAAgMEEgRHBEkGChEKCQYAAgMEsMq8IhIERwRJBgoMCgUGAAID
BBIDSgQ0Cg8KCAYAAgMEmwgAEgNKBDQKKwoEBgACBBIETgJUAxodIERlbGV0ZXMgYSBzZXNz
aW9uIHRlbXBsYXRlLgoKDAoFBgACBAESA04GGwoMCgUGAAIEAhIDThw4CgwKBQYAAgQDEgNP
DyQKDQoFBgACBAQSBFAEUgYKEQoJBgACBASwyrwiEgRQBFIGCgwKBQYAAgQEEgNTBDIKDwoI
BgACBASbCAASA1MEMgo1CgIEABIEWABjARopIEEgcmVxdWVzdCB0byBjcmVhdGUgYSBzZXNz
aW9uIHRlbXBsYXRlLgoKCgoDBAABEgNYCCQKWgoEBAACABIEWgJfBBpMIFJlcXVpcmVkLiBU
aGUgcGFyZW50IHJlc291cmNlIHdoZXJlIHRoaXMgc2Vzc2lvbiB0ZW1wbGF0ZSB3aWxsIGJl
IGNyZWF0ZWQuCgoMCgUEAAIABRIDWgIICgwKBQQAAgABEgNaCQ8KDAoFBAACAAMSA1oSEwoN
CgUEAAIACBIEWhRfAwoPCggEAAIACJwIABIDWwQqCg8KBwQAAgAInwgSBFwEXgUKOAoEBAAC
ARIDYgJQGisgUmVxdWlyZWQuIFRoZSBzZXNzaW9uIHRlbXBsYXRlIHRvIGNyZWF0ZS4KCgwK
BQQAAgEGEgNiAhEKDAoFBAACAQESA2ISIgoMCgUEAAIBAxIDYiUmCgwKBQQAAgEIEgNiJ08K
DwoIBAACAQicCAASA2IoTgo1CgIEARIEZgBpARopIEEgcmVxdWVzdCB0byB1cGRhdGUgYSBz
ZXNzaW9uIHRlbXBsYXRlLgoKCgoDBAEBEgNmCCQKNgoEBAECABIDaAJQGikgUmVxdWlyZWQu
IFRoZSB1cGRhdGVkIHNlc3Npb24gdGVtcGxhdGUuCgoMCgUEAQIABhIDaAIRCgwKBQQBAgAB
EgNoEiIKDAoFBAECAAMSA2glJgoMCgUEAQIACBIDaCdPCg8KCAQBAgAInAgAEgNoKE4KUgoC
BAISBGwAdAEaRiBBIHJlcXVlc3QgdG8gZ2V0IHRoZSByZXNvdXJjZSByZXByZXNlbnRhdGlv
biBmb3IgYSBzZXNzaW9uIHRlbXBsYXRlLgoKCgoDBAIBEgNsCCEKRwoEBAICABIEbgJzBBo5
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc2Vzc2lvbiB0ZW1wbGF0ZSB0byByZXRyaWV2
ZS4KCgwKBQQCAgAFEgNuAggKDAoFBAICAAESA24JDQoMCgUEAgIAAxIDbhARCg0KBQQCAgAI
EgRuEnMDCg8KCAQCAgAInAgAEgNvBCoKDwoHBAICAAifCBIEcARyBQpACgIEAxIFdwCNAQEa
MyBBIHJlcXVlc3QgdG8gbGlzdCBzZXNzaW9uIHRlbXBsYXRlcyBpbiBhIHByb2plY3QuCgoK
CgMEAwESA3cIIwpUCgQEAwIAEgR5An4EGkYgUmVxdWlyZWQuIFRoZSBwYXJlbnQgdGhhdCBv
d25zIHRoaXMgY29sbGVjdGlvbiBvZiBzZXNzaW9uIHRlbXBsYXRlcy4KCgwKBQQDAgAFEgN5
AggKDAoFBAMCAAESA3kJDwoMCgUEAwIAAxIDeRITCg0KBQQDAgAIEgR5FH4DCg8KCAQDAgAI
nAgAEgN6BCoKDwoHBAMCAAifCBIEewR9BQqDAQoEBAMCARIEggECPxp1IE9wdGlvbmFsLiBU
aGUgbWF4aW11bSBudW1iZXIgb2Ygc2Vzc2lvbnMgdG8gcmV0dXJuIGluIGVhY2ggcmVzcG9u
c2UuCiBUaGUgc2VydmljZSBtYXkgcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4KCg0K
BQQDAgEFEgSCAQIHCg0KBQQDAgEBEgSCAQgRCg0KBQQDAgEDEgSCARQVCg0KBQQDAgEIEgSC
ARY+ChAKCAQDAgEInAgAEgSCARc9CokBCgQEAwICEgSGAQJBGnsgT3B0aW9uYWwuIEEgcGFn
ZSB0b2tlbiByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RTZXNzaW9uc2AgY2FsbC4K
IFByb3ZpZGUgdGhpcyB0b2tlbiB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoK
DQoFBAMCAgUSBIYBAggKDQoFBAMCAgESBIYBCRMKDQoFBAMCAgMSBIYBFhcKDQoFBAMCAggS
BIYBGEAKEAoIBAMCAgicCAASBIYBGT8KvwEKBAQDAgMSBIwBAj0asAEgT3B0aW9uYWwuIEEg
ZmlsdGVyIGZvciB0aGUgc2Vzc2lvbiB0ZW1wbGF0ZXMgdG8gcmV0dXJuIGluIHRoZSByZXNw
b25zZS4KIEZpbHRlcnMgYXJlIGNhc2Ugc2Vuc2l0aXZlIGFuZCBoYXZlIHRoZSBmb2xsb3dp
bmcgc3ludGF4OgoKIFtmaWVsZCA9IHZhbHVlXSBBTkQgW2ZpZWxkIFs9IHZhbHVlXV0gLi4u
CgoNCgUEAwIDBRIEjAECCAoNCgUEAwIDARIEjAEJDwoNCgUEAwIDAxIEjAESEwoNCgUEAwID
CBIEjAEUPAoQCggEAwIDCJwIABIEjAEVOwosCgIEBBIGkAEAmAEBGh4gQSBsaXN0IG9mIHNl
c3Npb24gdGVtcGxhdGVzLgoKCwoDBAQBEgSQAQgkCjQKBAQEAgASBpIBApMBMhokIE91dHB1
dCBvbmx5LiBTZXNzaW9uIHRlbXBsYXRlIGxpc3QKCg0KBQQEAgAEEgSSAQIKCg0KBQQEAgAG
EgSSAQsaCg0KBQQEAgABEgSSARssCg0KBQQEAgADEgSSAS8wCg0KBQQEAgAIEgSTAQYxChAK
CAQEAgAInAgAEgSTAQcwCpABCgQEBAIBEgSXAQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBi
ZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYg
dGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4K
Cg0KBQQEAgEFEgSXAQIICg0KBQQEAgEBEgSXAQkYCg0KBQQEAgEDEgSXARscCjcKAgQFEgab
AQCjAQEaKSBBIHJlcXVlc3QgdG8gZGVsZXRlIGEgc2Vzc2lvbiB0ZW1wbGF0ZS4KCgsKAwQF
ARIEmwEIJApQCgQEBQIAEgadAQKiAQQaQCBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHNl
c3Npb24gdGVtcGxhdGUgcmVzb3VyY2UgdG8gZGVsZXRlLgoKDQoFBAUCAAUSBJ0BAggKDQoF
BAUCAAESBJ0BCQ0KDQoFBAUCAAMSBJ0BEBEKDwoFBAUCAAgSBp0BEqIBAwoQCggEBQIACJwI
ABIEngEEKgoRCgcEBQIACJ8IEgafAQShAQUKNwoCBAYSBqYBAN0BARopIEEgcmVwcmVzZW50
YXRpb24gb2YgYSBzZXNzaW9uIHRlbXBsYXRlLgoKCwoDBAYBEgSmAQgXCg0KAwQGBxIGpwEC
qgEECg8KBQQGB50IEganAQKqAQQKUgoEBAYCABIGrQECsAEEGkIgUmVxdWlyZWQuIElkZW50
aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBzZXNzaW9uIHRlbXBsYXRlLgoKDQoF
BAYCAAUSBK0BAggKDQoFBAYCAAESBK0BCQ0KDQoFBAYCAAMSBK0BEBEKDwoFBAYCAAgSBq0B
ErABAwoQCggEBgIACJwIABIErgEEKgoQCggEBgIACJwIARIErwEELAo8CgQEBgIBEgSzAQJC
Gi4gT3B0aW9uYWwuIEJyaWVmIGRlc2NyaXB0aW9uIG9mIHRoZSB0ZW1wbGF0ZS4KCg0KBQQG
AgEFEgSzAQIICg0KBQQGAgEBEgSzAQkUCg0KBQQGAgEDEgSzARcYCg0KBQQGAgEIEgSzARlB
ChAKCAQGAgEInAgAEgSzARpACkYKBAQGAgISBrYBArcBMho2IE91dHB1dCBvbmx5LiBUaGUg
dGltZSB3aGVuIHRoZSB0ZW1wbGF0ZSB3YXMgY3JlYXRlZC4KCg0KBQQGAgIGEgS2AQIbCg0K
BQQGAgIBEgS2ARwnCg0KBQQGAgIDEgS2ASorCg0KBQQGAgIIEgS3AQYxChAKCAQGAgIInAgA
EgS3AQcwCiwKBAQGCAASBroBAsEBAxocIFRoZSBzZXNzaW9uIGNvbmZpZ3VyYXRpb24uCgoN
CgUEBggAARIEugEIFgoxCgQEBgIDEgS8AQRPGiMgT3B0aW9uYWwuIEp1cHl0ZXIgc2Vzc2lv
biBjb25maWcuCgoNCgUEBgIDBhIEvAEEEQoNCgUEBgIDARIEvAESIQoNCgUEBgIDAxIEvAEk
JQoNCgUEBgIDCBIEvAEmTgoQCggEBgIDCJwIABIEvAEnTQo5CgQEBgIEEga/AQTAATEaKSBP
cHRpb25hbC4gU3BhcmsgY29ubmVjdCBzZXNzaW9uIGNvbmZpZy4KCg0KBQQGAgQGEgS/AQQW
Cg0KBQQGAgQBEgS/ARcsCg0KBQQGAgQDEgS/AS8xCg0KBQQGAgQIEgTAAQgwChAKCAQGAgQI
nAgAEgTAAQkvClQKBAQGAgUSBMQBAkEaRiBPdXRwdXQgb25seS4gVGhlIGVtYWlsIGFkZHJl
c3Mgb2YgdGhlIHVzZXIgd2hvIGNyZWF0ZWQgdGhlIHRlbXBsYXRlLgoKDQoFBAYCBQUSBMQB
AggKDQoFBAYCBQESBMQBCRAKDQoFBAYCBQMSBMQBExQKDQoFBAYCBQgSBMQBFUAKEAoIBAYC
BQicCAASBMQBFj8KnwMKBAQGAgYSBM0BAkoakAMgT3B0aW9uYWwuIExhYmVscyB0byBhc3Nv
Y2lhdGUgd2l0aCBzZXNzaW9ucyBjcmVhdGVkIHVzaW5nIHRoaXMgdGVtcGxhdGUuCiBMYWJl
bCAqKmtleXMqKiBtdXN0IGNvbnRhaW4gMSB0byA2MyBjaGFyYWN0ZXJzLCBhbmQgbXVzdCBj
b25mb3JtIHRvCiBbUkZDIDEwMzVdKGh0dHBzOi8vd3d3LmlldGYub3JnL3JmYy9yZmMxMDM1
LnR4dCkuCiBMYWJlbCAqKnZhbHVlcyoqIGNhbiBiZSBlbXB0eSwgYnV0LCBpZiBwcmVzZW50
LCBtdXN0IGNvbnRhaW4gMSB0byA2MwogY2hhcmFjdGVycyBhbmQgY29uZm9ybSB0byBbUkZD
CiAxMDM1XShodHRwczovL3d3dy5pZXRmLm9yZy9yZmMvcmZjMTAzNS50eHQpLiBObyBtb3Jl
IHRoYW4gMzIgbGFiZWxzIGNhbiBiZQogYXNzb2NpYXRlZCB3aXRoIGEgc2Vzc2lvbi4KCg0K
BQQGAgYGEgTNAQIVCg0KBQQGAgYBEgTNARYcCg0KBQQGAgYDEgTNAR8gCg0KBQQGAgYIEgTN
ASFJChAKCAQGAgYInAgAEgTNASJICkYKBAQGAgcSBNABAkwaOCBPcHRpb25hbC4gUnVudGlt
ZSBjb25maWd1cmF0aW9uIGZvciBzZXNzaW9uIGV4ZWN1dGlvbi4KCg0KBQQGAgcGEgTQAQIP
Cg0KBQQGAgcBEgTQARAeCg0KBQQGAgcDEgTQASEiCg0KBQQGAgcIEgTQASNLChAKCAQGAgcI
nAgAEgTQASRKCkwKBAQGAggSBtMBAtQBLxo8IE9wdGlvbmFsLiBFbnZpcm9ubWVudCBjb25m
aWd1cmF0aW9uIGZvciBzZXNzaW9uIGV4ZWN1dGlvbi4KCg0KBQQGAggGEgTTAQITCg0KBQQG
AggBEgTTARQmCg0KBQQGAggDEgTTASkqCg0KBQQGAggIEgTUAQYuChAKCAQGAggInAgAEgTU
AQctCkYKBAQGAgkSBtcBAtgBMho2IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgdGVtcGxh
dGUgd2FzIGxhc3QgdXBkYXRlZC4KCg0KBQQGAgkGEgTXAQIbCg0KBQQGAgkBEgTXARwnCg0K
BQQGAgkDEgTXASosCg0KBQQGAgkIEgTYAQYxChAKCAQGAgkInAgAEgTYAQcwCpwBCgQEBgIK
EgTcAQI/Go0BIE91dHB1dCBvbmx5LiBBIHNlc3Npb24gdGVtcGxhdGUgVVVJRCAoVW5pcXVl
IFVuaXZlcnNhbCBJZGVudGlmaWVyKS4gVGhlCiBzZXJ2aWNlIGdlbmVyYXRlcyB0aGlzIHZh
bHVlIHdoZW4gaXQgY3JlYXRlcyB0aGUgc2Vzc2lvbiB0ZW1wbGF0ZS4KCg0KBQQGAgoFEgTc
AQIICg0KBQQGAgoBEgTcAQkNCg0KBQQGAgoDEgTcARASCg0KBQQGAgoIEgTcARM+ChAKCAQG
AgoInAgAEgTcARQ9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataproc::V1::SessionTemplates::CreateSessionTemplateRequest ===
    # Fields for CreateSessionTemplateRequest
    # Field: parent Type: 9 ()
    # Field: session_template Type: 11 (.google.cloud.dataproc.v1.SessionTemplate)

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::CreateSessionTemplateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::SessionTemplates;

    my $msg = Google::Cloud::Dataproc::V1::SessionTemplates::CreateSessionTemplateRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<session_template>

Type: Message (.google.cloud.dataproc.v1.SessionTemplate)

=back

=cut

# === Message: Google::Cloud::Dataproc::V1::SessionTemplates::UpdateSessionTemplateRequest ===
    # Fields for UpdateSessionTemplateRequest
    # Field: session_template Type: 11 (.google.cloud.dataproc.v1.SessionTemplate)

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::UpdateSessionTemplateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::SessionTemplates;

    my $msg = Google::Cloud::Dataproc::V1::SessionTemplates::UpdateSessionTemplateRequest->new(
        session_template => $value,
    );

=head1 FIELDS

=over 4

=item * B<session_template>

Type: Message (.google.cloud.dataproc.v1.SessionTemplate)

=back

=cut

# === Message: Google::Cloud::Dataproc::V1::SessionTemplates::GetSessionTemplateRequest ===
    # Fields for GetSessionTemplateRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::GetSessionTemplateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::SessionTemplates;

    my $msg = Google::Cloud::Dataproc::V1::SessionTemplates::GetSessionTemplateRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesRequest ===
    # Fields for ListSessionTemplatesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::SessionTemplates;

    my $msg = Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesRequest->new(
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

=back

=cut

# === Message: Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesResponse ===
    # Fields for ListSessionTemplatesResponse
    # Field: session_templates Type: 11 (.google.cloud.dataproc.v1.SessionTemplate)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::SessionTemplates;

    my $msg = Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesResponse->new(
        session_templates => $value,
    );

=head1 FIELDS

=over 4

=item * B<session_templates>

Type: Message (.google.cloud.dataproc.v1.SessionTemplate)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Cloud::Dataproc::V1::SessionTemplates::DeleteSessionTemplateRequest ===
    # Fields for DeleteSessionTemplateRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::DeleteSessionTemplateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::SessionTemplates;

    my $msg = Google::Cloud::Dataproc::V1::SessionTemplates::DeleteSessionTemplateRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate ===
    # Fields for SessionTemplate
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: jupyter_session Type: 11 (.google.cloud.dataproc.v1.JupyterConfig)
    # Field: spark_connect_session Type: 11 (.google.cloud.dataproc.v1.SparkConnectConfig)
    # Field: creator Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.dataproc.v1.SessionTemplate.LabelsEntry)
    # Field: runtime_config Type: 11 (.google.cloud.dataproc.v1.RuntimeConfig)
    # Field: environment_config Type: 11 (.google.cloud.dataproc.v1.EnvironmentConfig)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: uuid Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::SessionTemplates;

    my $msg = Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=item * B<description>

Type: String

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<jupyter_session>

Type: Message (.google.cloud.dataproc.v1.JupyterConfig)

=item * B<spark_connect_session>

Type: Message (.google.cloud.dataproc.v1.SparkConnectConfig)

=item * B<creator>

Type: String

=item * B<labels>

Type: Message (.google.cloud.dataproc.v1.SessionTemplate.LabelsEntry)

=item * B<runtime_config>

Type: Message (.google.cloud.dataproc.v1.RuntimeConfig)

=item * B<environment_config>

Type: Message (.google.cloud.dataproc.v1.EnvironmentConfig)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<uuid>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplateControllerClient ===
package Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplateControllerClient;

=pod

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplateControllerClient - Client stub representing the remote SessionTemplateController service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<dataproc.googleapis.com:443>.

=head2 credentials

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

sub create_session_template {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::SessionTemplates::CreateSessionTemplateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionTemplateController',
        method         => 'CreateSessionTemplate',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate',
    });
}

sub update_session_template {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::SessionTemplates::UpdateSessionTemplateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionTemplateController',
        method         => 'UpdateSessionTemplate',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate',
    });
}

sub get_session_template {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::SessionTemplates::GetSessionTemplateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionTemplateController',
        method         => 'GetSessionTemplate',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::SessionTemplates::SessionTemplate',
    });
}

sub list_session_templates {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionTemplateController',
        method         => 'ListSessionTemplates',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::SessionTemplates::ListSessionTemplatesResponse',
    });
}

sub delete_session_template {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::SessionTemplates::DeleteSessionTemplateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.SessionTemplateController',
        method         => 'DeleteSessionTemplate',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::SessionTemplates - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
