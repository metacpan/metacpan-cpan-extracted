package Google::Cloud::Retail::V2::ServingConfig;

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
    eval { require Google::Cloud::Retail::V2::SearchService };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvcmV0YWlsL3YyL3NlcnZpbmdfY29uZmlnLnByb3RvEhZnb29nbGUu
Y2xvdWQucmV0YWlsLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGiNnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2NvbW1vbi5w
cm90bxorZ29vZ2xlL2Nsb3VkL3JldGFpbC92Mi9zZWFyY2hfc2VydmljZS5wcm90byKKCwoN
U2VydmluZ0NvbmZpZxIXCgRuYW1lGAEgASgJQgPgQQVSBG5hbWUSJgoMZGlzcGxheV9uYW1l
GAIgASgJQgPgQQJSC2Rpc3BsYXlOYW1lEhkKCG1vZGVsX2lkGAMgASgJUgdtb2RlbElkEjIK
FXByaWNlX3JlcmFua2luZ19sZXZlbBgEIAEoCVITcHJpY2VSZXJhbmtpbmdMZXZlbBIqChFm
YWNldF9jb250cm9sX2lkcxgFIAMoCVIPZmFjZXRDb250cm9sSWRzEmQKEmR5bmFtaWNfZmFj
ZXRfc3BlYxgGIAEoCzI2Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuU2VhcmNoUmVxdWVzdC5E
eW5hbWljRmFjZXRTcGVjUhBkeW5hbWljRmFjZXRTcGVjEioKEWJvb3N0X2NvbnRyb2xfaWRz
GAcgAygJUg9ib29zdENvbnRyb2xJZHMSLAoSZmlsdGVyX2NvbnRyb2xfaWRzGAkgAygJUhBm
aWx0ZXJDb250cm9sSWRzEjAKFHJlZGlyZWN0X2NvbnRyb2xfaWRzGAogAygJUhJyZWRpcmVj
dENvbnRyb2xJZHMSPQobdHdvd2F5X3N5bm9ueW1zX2NvbnRyb2xfaWRzGBIgAygJUhh0d293
YXlTeW5vbnltc0NvbnRyb2xJZHMSPQobb25ld2F5X3N5bm9ueW1zX2NvbnRyb2xfaWRzGAwg
AygJUhhvbmV3YXlTeW5vbnltc0NvbnRyb2xJZHMSPgocZG9fbm90X2Fzc29jaWF0ZV9jb250
cm9sX2lkcxgNIAMoCVIYZG9Ob3RBc3NvY2lhdGVDb250cm9sSWRzEjYKF3JlcGxhY2VtZW50
X2NvbnRyb2xfaWRzGA4gAygJUhVyZXBsYWNlbWVudENvbnRyb2xJZHMSLAoSaWdub3JlX2Nv
bnRyb2xfaWRzGA8gAygJUhBpZ25vcmVDb250cm9sSWRzEicKD2RpdmVyc2l0eV9sZXZlbBgI
IAEoCVIOZGl2ZXJzaXR5TGV2ZWwSWgoOZGl2ZXJzaXR5X3R5cGUYFCABKA4yMy5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWcuRGl2ZXJzaXR5VHlwZVINZGl2ZXJzaXR5
VHlwZRI/ChxlbmFibGVfY2F0ZWdvcnlfZmlsdGVyX2xldmVsGBAgASgJUhllbmFibGVDYXRl
Z29yeUZpbHRlckxldmVsEjAKFGlnbm9yZV9yZWNzX2RlbnlsaXN0GBggASgIUhJpZ25vcmVS
ZWNzRGVueWxpc3QSbAoUcGVyc29uYWxpemF0aW9uX3NwZWMYFSABKAsyOS5nb29nbGUuY2xv
dWQucmV0YWlsLnYyLlNlYXJjaFJlcXVlc3QuUGVyc29uYWxpemF0aW9uU3BlY1ITcGVyc29u
YWxpemF0aW9uU3BlYxJTCg5zb2x1dGlvbl90eXBlcxgTIAMoDjIkLmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuU29sdXRpb25UeXBlQgbgQQLgQQVSDXNvbHV0aW9uVHlwZXMiZAoNRGl2ZXJz
aXR5VHlwZRIeChpESVZFUlNJVFlfVFlQRV9VTlNQRUNJRklFRBAAEhgKFFJVTEVfQkFTRURf
RElWRVJTSVRZEAISGQoVREFUQV9EUklWRU5fRElWRVJTSVRZEAM6hQHqQYEBCiNyZXRhaWwu
Z29vZ2xlYXBpcy5jb20vU2VydmluZ0NvbmZpZxJacHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2NhdGFsb2dzL3tjYXRhbG9nfS9zZXJ2aW5nQ29uZmlncy97c2Vy
dmluZ19jb25maWd9Qr0BChpjb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MkISU2VydmluZ0Nv
bmZpZ1Byb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyL3JldGFpbHBi
O3JldGFpbHBiogIGUkVUQUlMqgIWR29vZ2xlLkNsb3VkLlJldGFpbC5WMsoCFkdvb2dsZVxD
bG91ZFxSZXRhaWxcVjLqAhlHb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYySvBWCgcSBQ4AjAIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMS
ACkKCQoCAwESAxMAIwoJCgIDAhIDFAAtCgkKAgMDEgMVADUKCAoBCBIDFwAzCgkKAgglEgMX
ADMKCAoBCBIDGABJCgkKAggLEgMYAEkKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAz
CgkKAggIEgMaADMKCAoBCBIDGwAzCgkKAggBEgMbADMKCAoBCBIDHAAkCgkKAggkEgMcACQK
CAoBCBIDHQAzCgkKAggpEgMdADMKCAoBCBIDHgAyCgkKAggtEgMeADIKhgEKAgQAEgUiAIwC
ARp5IENvbmZpZ3VyZXMgbWV0YWRhdGEgdGhhdCBpcyB1c2VkIHRvIGdlbmVyYXRlIHNlcnZp
bmcgdGltZSByZXN1bHRzIChlLmcuCiBzZWFyY2ggcmVzdWx0cyBvciByZWNvbW1lbmRhdGlv
biBwcmVkaWN0aW9ucykuCgoKCgMEAAESAyIIFQoLCgMEAAcSBCMCJgQKDQoFBAAHnQgSBCMC
JgQKPAoEBAAEABIEKQIyAxouIFdoYXQgdHlwZSBvZiBkaXZlcnNpdHkgLSBkYXRhIG9yIHJ1
bGUgYmFzZWQuCgoMCgUEAAQAARIDKQcUCh8KBgQABAACABIDKwQjGhAgRGVmYXVsdCB2YWx1
ZS4KCg4KBwQABAACAAESAysEHgoOCgcEAAQAAgACEgMrISIKJgoGBAAEAAIBEgMuBB0aFyBS
dWxlIGJhc2VkIGRpdmVyc2l0eS4KCg4KBwQABAACAQESAy4EGAoOCgcEAAQAAgECEgMuGxwK
JwoGBAAEAAICEgMxBB4aGCBEYXRhIGRyaXZlbiBkaXZlcnNpdHkuCgoOCgcEAAQAAgIBEgMx
BBkKDgoHBAAEAAICAhIDMRwdCmgKBAQAAgASAzYCPBpbIEltbXV0YWJsZS4gRnVsbHkgcXVh
bGlmaWVkIG5hbWUKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvKi9z
ZXJ2aW5nQ29uZmlnLypgCgoMCgUEAAIABRIDNgIICgwKBQQAAgABEgM2CQ0KDAoFBAACAAMS
AzYQEQoMCgUEAAIACBIDNhI7Cg8KCAQAAgAInAgAEgM2EzoK4wEKBAQAAgESAz0CQxrVASBS
ZXF1aXJlZC4gVGhlIGh1bWFuIHJlYWRhYmxlIHNlcnZpbmcgY29uZmlnIGRpc3BsYXkgbmFt
ZS4gVXNlZCBpbiBSZXRhaWwKIFVJLgoKIFRoaXMgZmllbGQgbXVzdCBiZSBhIFVURi04IGVu
Y29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMTI4CiBjaGFyYWN0ZXJzLiBP
dGhlcndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUE
AAIBBRIDPQIICgwKBQQAAgEBEgM9CRUKDAoFBAACAQMSAz0YGQoMCgUEAAIBCBIDPRpCCg8K
CAQAAgEInAgAEgM9G0EKlAQKBAQAAgISA0gCFhqGBCBUaGUgaWQgb2YgdGhlIG1vZGVsIGlu
IHRoZSBzYW1lIFtDYXRhbG9nXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFsb2ddCiB0
byB1c2UgYXQgc2VydmluZyB0aW1lLiBDdXJyZW50bHkgb25seSBSZWNvbW1lbmRhdGlvbk1v
ZGVscyBhcmUgc3VwcG9ydGVkOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3JldGFpbC9y
ZWNvbW1lbmRhdGlvbnMtYWkvZG9jcy9jcmVhdGUtbW9kZWxzCiBDYW4gYmUgY2hhbmdlZCBi
dXQgb25seSB0byBhIGNvbXBhdGlibGUgbW9kZWwgKGUuZy4KIG90aGVycy15b3UtbWF5LWxp
a2UgQ1RSIHRvIG90aGVycy15b3UtbWF5LWxpa2UgQ1ZSKS4KCiBSZXF1aXJlZCB3aGVuCiBb
c29sdXRpb25fdHlwZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuU2VydmluZ0NvbmZpZy5z
b2x1dGlvbl90eXBlc10gaXMKIFtTT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXVtnb29n
bGUuY2xvdWQucmV0YWlsLnYyLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1JFQ09NTUVO
REFUSU9OXS4KCgwKBQQAAgIFEgNIAggKDAoFBAACAgESA0gJEQoMCgUEAAICAxIDSBQVCsIF
CgQEAAIDEgNcAiMatAUgSG93IG11Y2ggcHJpY2UgcmFua2luZyB3ZSB3YW50IGluIHNlcnZp
bmcgcmVzdWx0cy4KIFByaWNlIHJlcmFua2luZyBjYXVzZXMgcHJvZHVjdCBpdGVtcyB3aXRo
IGEgc2ltaWxhcgogcmVjb21tZW5kYXRpb24gcHJvYmFiaWxpdHkgdG8gYmUgb3JkZXJlZCBi
eSBwcmljZSwgd2l0aCB0aGUKIGhpZ2hlc3QtcHJpY2VkIGl0ZW1zIGZpcnN0LiBUaGlzIHNl
dHRpbmcgY291bGQgcmVzdWx0IGluIGEgZGVjcmVhc2UgaW4KIGNsaWNrLXRocm91Z2ggYW5k
IGNvbnZlcnNpb24gcmF0ZXMuCiAgQWxsb3dlZCB2YWx1ZXMgYXJlOgoKICogYG5vLXByaWNl
LXJlcmFua2luZ2AKICogYGxvdy1wcmljZS1yZXJhbmtpbmdgCiAqIGBtZWRpdW0tcHJpY2Ut
cmVyYW5raW5nYAogKiBgaGlnaC1wcmljZS1yZXJhbmtpbmdgCgogSWYgbm90IHNwZWNpZmll
ZCwgd2UgY2hvb3NlIGRlZmF1bHQgYmFzZWQgb24gbW9kZWwgdHlwZS4gRGVmYXVsdCB2YWx1
ZToKIGBuby1wcmljZS1yZXJhbmtpbmdgLgoKIENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0
aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWcuc29sdXRp
b25fdHlwZXNdIGlzCiBbU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElPTl1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5Tb2x1dGlvblR5cGUuU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElP
Tl0uCgoMCgUEAAIDBRIDXAIICgwKBQQAAgMBEgNcCR4KDAoFBAACAwMSA1whIgrvBAoEBAAC
BBIDaQIoGuEEIEZhY2V0IHNwZWNpZmljYXRpb25zIGZvciBmYWNldGVkIHNlYXJjaC4gSWYg
ZW1wdHksIG5vIGZhY2V0cyBhcmUgcmV0dXJuZWQuCiBUaGUgaWRzIHJlZmVyIHRvIHRoZSBp
ZHMgb2YgW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29udHJvbF0KIHJlc291
cmNlcyB3aXRoIG9ubHkgdGhlIEZhY2V0IGNvbnRyb2wgc2V0LiBUaGVzZSBjb250cm9scyBh
cmUgYXNzdW1lZCB0byBiZQogaW4gdGhlIHNhbWUgW0NhdGFsb2ddW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuQ2F0YWxvZ10gYXMgdGhlCiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xlLmNsb3Vk
LnJldGFpbC52Mi5TZXJ2aW5nQ29uZmlnXS4KIEEgbWF4aW11bSBvZiAxMDAgdmFsdWVzIGFy
ZSBhbGxvd2VkLiBPdGhlcndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IKIGlzIHJl
dHVybmVkLgoKIENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdIGlzCiBbU09M
VVRJT05fVFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuU29sdXRpb25UeXBl
LlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCgwKBQQAAgQEEgNpAgoKDAoFBAACBAUSA2kLEQoM
CgUEAAIEARIDaRIjCgwKBQQAAgQDEgNpJicKtAIKBAQAAgUSA3ECOBqmAiBUaGUgc3BlY2lm
aWNhdGlvbiBmb3IgZHluYW1pY2FsbHkgZ2VuZXJhdGVkIGZhY2V0cy4gTm90aWNlIHRoYXQg
b25seQogdGV4dHVhbCBmYWNldHMgY2FuIGJlIGR5bmFtaWNhbGx5IGdlbmVyYXRlZC4KCiBD
YW4gb25seSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5TZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXSBpcwogW1NPTFVUSU9OX1RZUEVf
U0VBUkNIXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9U
WVBFX1NFQVJDSF0uCgoMCgUEAAIFBhIDcQIgCgwKBQQAAgUBEgNxITMKDAoFBAACBQMSA3E2
NwrDBgoEBAACBhIEgwECKBq0BiBDb25kaXRpb24gYm9vc3Qgc3BlY2lmaWNhdGlvbnMuIElm
IGEgcHJvZHVjdCBtYXRjaGVzIG11bHRpcGxlIGNvbmRpdGlvbnMKIGluIHRoZSBzcGVjaWZp
Y2F0aW9ucywgYm9vc3Qgc2NvcmVzIGZyb20gdGhlc2Ugc3BlY2lmaWNhdGlvbnMgYXJlIGFs
bAogYXBwbGllZCBhbmQgY29tYmluZWQgaW4gYSBub24tbGluZWFyIHdheS4gTWF4aW11bSBu
dW1iZXIgb2YKIHNwZWNpZmljYXRpb25zIGlzIDEwMC4KCiBOb3RpY2UgdGhhdCBpZiBib3Ro
CiBbU2VydmluZ0NvbmZpZy5ib29zdF9jb250cm9sX2lkc11bZ29vZ2xlLmNsb3VkLnJldGFp
bC52Mi5TZXJ2aW5nQ29uZmlnLmJvb3N0X2NvbnRyb2xfaWRzXQogYW5kCiBbU2VhcmNoUmVx
dWVzdC5ib29zdF9zcGVjXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNlYXJjaFJlcXVlc3Qu
Ym9vc3Rfc3BlY10KIGFyZSBzZXQsIHRoZSBib29zdCBjb25kaXRpb25zIGZyb20gYm90aCBw
bGFjZXMgYXJlIGV2YWx1YXRlZC4gSWYgYSBzZWFyY2gKIHJlcXVlc3QgbWF0Y2hlcyBtdWx0
aXBsZSBib29zdCBjb25kaXRpb25zLCB0aGUgZmluYWwgYm9vc3Qgc2NvcmUgaXMgZXF1YWwK
IHRvIHRoZSBzdW0gb2YgdGhlIGJvb3N0IHNjb3JlcyBmcm9tIGFsbCBtYXRjaGVkIGJvb3N0
IGNvbmRpdGlvbnMuCgogQ2FuIG9ubHkgYmUgc2V0IGlmCiBbc29sdXRpb25fdHlwZXNdW2dv
b2dsZS5jbG91ZC5yZXRhaWwudjIuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10gaXMK
IFtTT0xVVElPTl9UWVBFX1NFQVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Tb2x1dGlv
blR5cGUuU09MVVRJT05fVFlQRV9TRUFSQ0hdLgoKDQoFBAACBgQSBIMBAgoKDQoFBAACBgUS
BIMBCxEKDQoFBAACBgESBIMBEiMKDQoFBAACBgMSBIMBJicKpAMKBAQAAgcSBI0BAikalQMg
Q29uZGl0aW9uIGZpbHRlciBzcGVjaWZpY2F0aW9ucy4gSWYgYSBwcm9kdWN0IG1hdGNoZXMg
bXVsdGlwbGUgY29uZGl0aW9ucwogaW4gdGhlIHNwZWNpZmljYXRpb25zLCBmaWx0ZXJzIGZy
b20gdGhlc2Ugc3BlY2lmaWNhdGlvbnMgYXJlIGFsbAogYXBwbGllZCBhbmQgY29tYmluZWQg
dmlhIHRoZSBBTkQgb3BlcmF0b3IuIE1heGltdW0gbnVtYmVyIG9mCiBzcGVjaWZpY2F0aW9u
cyBpcyAxMDAuCgogQ2FuIG9ubHkgYmUgc2V0IGlmCiBbc29sdXRpb25fdHlwZXNdW2dvb2ds
ZS5jbG91ZC5yZXRhaWwudjIuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10gaXMKIFtT
T0xVVElPTl9UWVBFX1NFQVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Tb2x1dGlvblR5
cGUuU09MVVRJT05fVFlQRV9TRUFSQ0hdLgoKDQoFBAACBwQSBI0BAgoKDQoFBAACBwUSBI0B
CxEKDQoFBAACBwESBI0BEiQKDQoFBAACBwMSBI0BJygK3gIKBAQAAggSBJYBAiwazwIgQ29u
ZGl0aW9uIHJlZGlyZWN0IHNwZWNpZmljYXRpb25zLiBPbmx5IHRoZSBmaXJzdCB0cmlnZ2Vy
ZWQgcmVkaXJlY3QgYWN0aW9uCiBpcyBhcHBsaWVkLCBldmVuIGlmIG11bHRpcGxlIGFwcGx5
LiBNYXhpbXVtIG51bWJlciBvZiBzcGVjaWZpY2F0aW9ucyBpcwogMTAwMC4KCiBDYW4gb25s
eSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5T
ZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXSBpcwogW1NPTFVUSU9OX1RZUEVfU0VBUkNI
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1NF
QVJDSF0uCgoNCgUEAAIIBBIElgECCgoNCgUEAAIIBRIElgELEQoNCgUEAAIIARIElgESJgoN
CgUEAAIIAxIElgEpKwqeAwoEBAACCRIEoAECMxqPAyBDb25kaXRpb24gc3lub255bXMgc3Bl
Y2lmaWNhdGlvbnMuIElmIG11bHRpcGxlIHN5b255bXMgY29uZGl0aW9ucyBtYXRjaCwKIGFs
bCBtYXRjaGluZyBzeW5vbnltcyBjb250cm9sIGluIHRoZSBsaXN0IHdpbGwgZXhlY3V0ZS4g
T3JkZXIgb2YgY29udHJvbHMKIGluIHRoZSBsaXN0IHdpbGwgbm90IG1hdHRlci4gTWF4aW11
bSBudW1iZXIgb2Ygc3BlY2lmaWNhdGlvbnMgaXMKIDEwMC4KCiBDYW4gb25seSBiZSBzZXQg
aWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZXJ2aW5nQ29u
ZmlnLnNvbHV0aW9uX3R5cGVzXSBpcwogW1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1NFQVJDSF0uCgoN
CgUEAAIJBBIEoAECCgoNCgUEAAIJBRIEoAELEQoNCgUEAAIJARIEoAESLQoNCgUEAAIJAxIE
oAEwMgq1AwoEBAACChIEqgECMxqmAyBDb25kaXRpb24gb25ld2F5IHN5bm9ueW1zIHNwZWNp
ZmljYXRpb25zLiBJZiBtdWx0aXBsZSBvbmV3YXkgc3lub255bXMKIGNvbmRpdGlvbnMgbWF0
Y2gsIGFsbCBtYXRjaGluZyBvbmV3YXkgc3lub255bXMgY29udHJvbHMgaW4gdGhlIGxpc3Qg
d2lsbAogZXhlY3V0ZS4gT3JkZXIgb2YgY29udHJvbHMgaW4gdGhlIGxpc3Qgd2lsbCBub3Qg
bWF0dGVyLiBNYXhpbXVtIG51bWJlciBvZgogc3BlY2lmaWNhdGlvbnMgaXMgMTAwLgoKIENh
biBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQucmV0YWls
LnYyLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdIGlzCiBbU09MVVRJT05fVFlQRV9T
RUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZ
UEVfU0VBUkNIXS4KCg0KBQQAAgoEEgSqAQIKCg0KBQQAAgoFEgSqAQsRCg0KBQQAAgoBEgSq
ARItCg0KBQQAAgoDEgSqATAyCqUDCgQEAAILEgS1AQI0GpYDIENvbmRpdGlvbiBkbyBub3Qg
YXNzb2NpYXRlIHNwZWNpZmljYXRpb25zLiBJZiBtdWx0aXBsZSBkbyBub3QgYXNzb2NpYXRl
CiBjb25kaXRpb25zIG1hdGNoLCBhbGwgbWF0Y2hpbmcgZG8gbm90IGFzc29jaWF0ZSBjb250
cm9scyBpbiB0aGUgbGlzdCB3aWxsCiBleGVjdXRlLgogLSBPcmRlciBkb2VzIG5vdCBtYXR0
ZXIuCiAtIE1heGltdW0gbnVtYmVyIG9mIHNwZWNpZmljYXRpb25zIGlzIDEwMC4KCiBDYW4g
b25seSBiZSBzZXQgaWYKIFtzb2x1dGlvbl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5TZXJ2aW5nQ29uZmlnLnNvbHV0aW9uX3R5cGVzXSBpcwogW1NPTFVUSU9OX1RZUEVfU0VB
UkNIXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBF
X1NFQVJDSF0uCgoNCgUEAAILBBIEtQECCgoNCgUEAAILBRIEtQELEQoNCgUEAAILARIEtQES
LgoNCgUEAAILAxIEtQExMwr5AgoEBAACDBIEvwECLxrqAiBDb25kaXRpb24gcmVwbGFjZW1l
bnQgc3BlY2lmaWNhdGlvbnMuCiAtIEFwcGxpZWQgYWNjb3JkaW5nIHRvIHRoZSBvcmRlciBp
biB0aGUgbGlzdC4KIC0gQSBwcmV2aW91c2x5IHJlcGxhY2VkIHRlcm0gY2FuIG5vdCBiZSBy
ZS1yZXBsYWNlZC4KIC0gTWF4aW11bSBudW1iZXIgb2Ygc3BlY2lmaWNhdGlvbnMgaXMgMTAw
LgoKIENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUuY2xvdWQu
cmV0YWlsLnYyLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdIGlzCiBbU09MVVRJT05f
VFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuU29sdXRpb25UeXBlLlNPTFVU
SU9OX1RZUEVfU0VBUkNIXS4KCg0KBQQAAgwEEgS/AQIKCg0KBQQAAgwFEgS/AQsRCg0KBQQA
AgwBEgS/ARIpCg0KBQQAAgwDEgS/ASwuCocDCgQEAAINEgTKAQIqGvgCIENvbmRpdGlvbiBp
Z25vcmUgc3BlY2lmaWNhdGlvbnMuIElmIG11bHRpcGxlIGlnbm9yZQogY29uZGl0aW9ucyBt
YXRjaCwgYWxsIG1hdGNoaW5nIGlnbm9yZSBjb250cm9scyBpbiB0aGUgbGlzdCB3aWxsCiBl
eGVjdXRlLgogLSBPcmRlciBkb2VzIG5vdCBtYXR0ZXIuCiAtIE1heGltdW0gbnVtYmVyIG9m
IHNwZWNpZmljYXRpb25zIGlzIDEwMC4KCiBDYW4gb25seSBiZSBzZXQgaWYKIFtzb2x1dGlv
bl90eXBlc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZXJ2aW5nQ29uZmlnLnNvbHV0aW9u
X3R5cGVzXSBpcwogW1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtnb29nbGUuY2xvdWQucmV0YWls
LnYyLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1NFQVJDSF0uCgoNCgUEAAINBBIEygEC
CgoNCgUEAAINBRIEygELEQoNCgUEAAINARIEygESJAoNCgUEAAINAxIEygEnKQqkBAoEBAAC
DhIE2wECHRqVBCBIb3cgbXVjaCBkaXZlcnNpdHkgdG8gdXNlIGluIHJlY29tbWVuZGF0aW9u
IG1vZGVsIHJlc3VsdHMgZS5nLgogYG1lZGl1bS1kaXZlcnNpdHlgIG9yIGBoaWdoLWRpdmVy
c2l0eWAuIEN1cnJlbnRseSBzdXBwb3J0ZWQgdmFsdWVzOgoKICogYG5vLWRpdmVyc2l0eWAK
ICogYGxvdy1kaXZlcnNpdHlgCiAqIGBtZWRpdW0tZGl2ZXJzaXR5YAogKiBgaGlnaC1kaXZl
cnNpdHlgCiAqIGBhdXRvLWRpdmVyc2l0eWAKCiBJZiBub3Qgc3BlY2lmaWVkLCB3ZSBjaG9v
c2UgZGVmYXVsdCBiYXNlZCBvbiByZWNvbW1lbmRhdGlvbiBtb2RlbAogdHlwZS4gRGVmYXVs
dCB2YWx1ZTogYG5vLWRpdmVyc2l0eWAuCgogQ2FuIG9ubHkgYmUgc2V0IGlmCiBbc29sdXRp
b25fdHlwZXNdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuU2VydmluZ0NvbmZpZy5zb2x1dGlv
bl90eXBlc10gaXMKIFtTT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9O
XS4KCg0KBQQAAg4FEgTbAQIICg0KBQQAAg4BEgTbAQkYCg0KBQQAAg4DEgTbARscCtgBCgQE
AAIPEgTgAQIkGskBIFdoYXQga2luZCBvZiBkaXZlcnNpdHkgdG8gdXNlIC0gZGF0YSBkcml2
ZW4gb3IgcnVsZSBiYXNlZC4gSWYgdW5zZXQsIHRoZQogc2VydmVyIGJlaGF2aW9yIGRlZmF1
bHRzIHRvCiBbUlVMRV9CQVNFRF9ESVZFUlNJVFldW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIu
U2VydmluZ0NvbmZpZy5EaXZlcnNpdHlUeXBlLlJVTEVfQkFTRURfRElWRVJTSVRZXS4KCg0K
BQQAAg8GEgTgAQIPCg0KBQQAAg8BEgTgARAeCg0KBQQAAg8DEgTgASEjCu4FCgQEAAIQEgTw
AQIrGt8FIFdoZXRoZXIgdG8gYWRkIGFkZGl0aW9uYWwgY2F0ZWdvcnkgZmlsdGVycyBvbiB0
aGUgYHNpbWlsYXItaXRlbXNgIG1vZGVsLgogSWYgbm90IHNwZWNpZmllZCwgd2UgZW5hYmxl
IGl0IGJ5IGRlZmF1bHQuCiAgQWxsb3dlZCB2YWx1ZXMgYXJlOgoKICogYG5vLWNhdGVnb3J5
LW1hdGNoYDogTm8gYWRkaXRpb25hbCBmaWx0ZXJpbmcgb2Ygb3JpZ2luYWwgcmVzdWx0cyBm
cm9tCiAgIHRoZSBtb2RlbCBhbmQgdGhlIGN1c3RvbWVyJ3MgZmlsdGVycy4KICogYHJlbGF4
ZWQtY2F0ZWdvcnktbWF0Y2hgOiBPbmx5IGtlZXAgcmVzdWx0cyB3aXRoIGNhdGVnb3JpZXMg
dGhhdCBtYXRjaAogICBhdCBsZWFzdCBvbmUgaXRlbSBjYXRlZ29yaWVzIGluIHRoZSBQcmVk
aWN0UmVxdWVzdHMncyBjb250ZXh0IGl0ZW0uCiAgICogSWYgY3VzdG9tZXIgYWxzbyBzZW5k
cyBmaWx0ZXJzIGluIHRoZSBQcmVkaWN0UmVxdWVzdCwgdGhlbiB0aGUgcmVzdWx0cwogICB3
aWxsIHNhdGlzZnkgYm90aCBjb25kaXRpb25zICh1c2VyIGdpdmVuIGFuZCBjYXRlZ29yeSBt
YXRjaCkuCgogQ2FuIG9ubHkgYmUgc2V0IGlmCiBbc29sdXRpb25fdHlwZXNdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjIuU2VydmluZ0NvbmZpZy5zb2x1dGlvbl90eXBlc10gaXMKIFtTT0xV
VElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNvbHV0
aW9uVHlwZS5TT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXS4KCg0KBQQAAhAFEgTwAQII
Cg0KBQQAAhABEgTwAQklCg0KBQQAAhADEgTwASgqCokBCgQEAAIREgT0AQIhGnsgV2hlbiB0
aGUgZmxhZyBpcyBlbmFibGVkLCB0aGUgcHJvZHVjdHMgaW4gdGhlIGRlbnlsaXN0IHdpbGwg
bm90IGJlIGZpbHRlcmVkCiBvdXQgaW4gdGhlIHJlY29tbWVuZGF0aW9uIGZpbHRlcmluZyBy
ZXN1bHRzLgoKDQoFBAACEQUSBPQBAgYKDQoFBAACEQESBPQBBxsKDQoFBAACEQMSBPQBHiAK
pwUKBAQAAhISBIQCAj4amAUgVGhlIHNwZWNpZmljYXRpb24gZm9yIHBlcnNvbmFsaXphdGlv
biBzcGVjLgoKIENhbiBvbmx5IGJlIHNldCBpZgogW3NvbHV0aW9uX3R5cGVzXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWcuc29sdXRpb25fdHlwZXNdIGlzCiBbU09M
VVRJT05fVFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuU29sdXRpb25UeXBl
LlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCiBOb3RpY2UgdGhhdCBpZiBib3RoCiBbU2Vydmlu
Z0NvbmZpZy5wZXJzb25hbGl6YXRpb25fc3BlY11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5T
ZXJ2aW5nQ29uZmlnLnBlcnNvbmFsaXphdGlvbl9zcGVjXQogYW5kCiBbU2VhcmNoUmVxdWVz
dC5wZXJzb25hbGl6YXRpb25fc3BlY11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZWFyY2hS
ZXF1ZXN0LnBlcnNvbmFsaXphdGlvbl9zcGVjXQogYXJlIHNldC4KIFtTZWFyY2hSZXF1ZXN0
LnBlcnNvbmFsaXphdGlvbl9zcGVjXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNlYXJjaFJl
cXVlc3QucGVyc29uYWxpemF0aW9uX3NwZWNdCiB3aWxsIG92ZXJyaWRlCiBbU2VydmluZ0Nv
bmZpZy5wZXJzb25hbGl6YXRpb25fc3BlY11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZXJ2
aW5nQ29uZmlnLnBlcnNvbmFsaXphdGlvbl9zcGVjXS4KCg0KBQQAAhIGEgSEAgIjCg0KBQQA
AhIBEgSEAiQ4Cg0KBQQAAhIDEgSEAjs9CqsBCgQEAAITEgaIAgKLAgQamgEgUmVxdWlyZWQu
IEltbXV0YWJsZS4gU3BlY2lmaWVzIHRoZSBzb2x1dGlvbiB0eXBlcyB0aGF0IGEgc2Vydmlu
ZyBjb25maWcgY2FuCiBiZSBhc3NvY2lhdGVkIHdpdGguIEN1cnJlbnRseSB3ZSBzdXBwb3J0
IHNldHRpbmcgb25seSBvbmUgdHlwZSBvZiBzb2x1dGlvbi4KCg0KBQQAAhMEEgSIAgIKCg0K
BQQAAhMGEgSIAgsXCg0KBQQAAhMBEgSIAhgmCg0KBQQAAhMDEgSIAikrCg8KBQQAAhMIEgaI
AiyLAgMKEAoIBAACEwicCAASBIkCBCoKEAoIBAACEwicCAESBIoCBCtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::ServingConfig::ServingConfig ===
    # Fields for ServingConfig
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: model_id Type: 9 ()
    # Field: price_reranking_level Type: 9 ()
    # Field: facet_control_ids Type: 9 ()
    # Field: dynamic_facet_spec Type: 11 (.google.cloud.retail.v2.SearchRequest.DynamicFacetSpec)
    # Field: boost_control_ids Type: 9 ()
    # Field: filter_control_ids Type: 9 ()
    # Field: redirect_control_ids Type: 9 ()
    # Field: twoway_synonyms_control_ids Type: 9 ()
    # Field: oneway_synonyms_control_ids Type: 9 ()
    # Field: do_not_associate_control_ids Type: 9 ()
    # Field: replacement_control_ids Type: 9 ()
    # Field: ignore_control_ids Type: 9 ()
    # Field: diversity_level Type: 9 ()
    # Field: diversity_type Type: 14 (.google.cloud.retail.v2.ServingConfig.DiversityType)
    # Field: enable_category_filter_level Type: 9 ()
    # Field: ignore_recs_denylist Type: 8 ()
    # Field: personalization_spec Type: 11 (.google.cloud.retail.v2.SearchRequest.PersonalizationSpec)
    # Field: solution_types Type: 14 (.google.cloud.retail.v2.SolutionType)

# Enum: ServingConfig::DiversityType
our $ServingConfig_DIVERSITY_TYPE_UNSPECIFIED = 0;
our $ServingConfig_RULE_BASED_DIVERSITY = 2;
our $ServingConfig_DATA_DRIVEN_DIVERSITY = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::ServingConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2/serving_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::ServingConfig;

    my $msg = Google::Cloud::Retail::V2::ServingConfig::ServingConfig->new({
        name => $name,
        display_name => $display_name,
        model_id => $model_id,
        price_reranking_level => $price_reranking_level,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::ServingConfig::ServingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/serving_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::ServingConfig::ServingConfig

Configures metadata that is used to generate serving time results (e.g.
search results or recommendation predictions).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/*/locations/global/catalogs/*/servingConfig/*`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human readable serving config display name. Used in Retail
UI.

This field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

The id of the model in the same [Catalog][google.cloud.retail.v2.Catalog]
to use at serving time. Currently only RecommendationModels are supported:
https://cloud.google.com/retail/recommendations-ai/docs/create-models
Can be changed but only to a compatible model (e.g.
others-you-may-like CTR to others-you-may-like CVR).

Required when
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->price_reranking_level() >> / C<< $msg->price_reranking_level($value) >>

Type: C<String>

How much price ranking we want in serving results.
Price reranking causes product items with a similar
recommendation probability to be ordered by price, with the
highest-priced items first. This setting could result in a decrease in
click-through and conversion rates.
 Allowed values are:

* `no-price-reranking`
* `low-price-reranking`
* `medium-price-reranking`
* `high-price-reranking`

If not specified, we choose default based on model type. Default value:
`no-price-reranking`.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->facet_control_ids() >> / C<< $msg->facet_control_ids($value) >>

Type: C<String>

Facet specifications for faceted search. If empty, no facets are returned.
The ids refer to the ids of [Control][google.cloud.retail.v2.Control]
resources with only the Facet control set. These controls are assumed to be
in the same [Catalog][google.cloud.retail.v2.Catalog] as the
[ServingConfig][google.cloud.retail.v2.ServingConfig].
A maximum of 100 values are allowed. Otherwise, an INVALID_ARGUMENT error
is returned.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->dynamic_facet_spec() >> / C<< $msg->dynamic_facet_spec($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::SearchService::SearchRequest::DynamicFacetSpec>)

The specification for dynamically generated facets. Notice that only
textual facets can be dynamically generated.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->boost_control_ids() >> / C<< $msg->boost_control_ids($value) >>

Type: C<String>

Condition boost specifications. If a product matches multiple conditions
in the specifications, boost scores from these specifications are all
applied and combined in a non-linear way. Maximum number of
specifications is 100.

Notice that if both
[ServingConfig.boost_control_ids][google.cloud.retail.v2.ServingConfig.boost_control_ids]
and
[SearchRequest.boost_spec][google.cloud.retail.v2.SearchRequest.boost_spec]
are set, the boost conditions from both places are evaluated. If a search
request matches multiple boost conditions, the final boost score is equal
to the sum of the boost scores from all matched boost conditions.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->filter_control_ids() >> / C<< $msg->filter_control_ids($value) >>

Type: C<String>

Condition filter specifications. If a product matches multiple conditions
in the specifications, filters from these specifications are all
applied and combined via the AND operator. Maximum number of
specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->redirect_control_ids() >> / C<< $msg->redirect_control_ids($value) >>

Type: C<String>

Condition redirect specifications. Only the first triggered redirect action
is applied, even if multiple apply. Maximum number of specifications is
1000.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->twoway_synonyms_control_ids() >> / C<< $msg->twoway_synonyms_control_ids($value) >>

Type: C<String>

Condition synonyms specifications. If multiple syonyms conditions match,
all matching synonyms control in the list will execute. Order of controls
in the list will not matter. Maximum number of specifications is
100.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->oneway_synonyms_control_ids() >> / C<< $msg->oneway_synonyms_control_ids($value) >>

Type: C<String>

Condition oneway synonyms specifications. If multiple oneway synonyms
conditions match, all matching oneway synonyms controls in the list will
execute. Order of controls in the list will not matter. Maximum number of
specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->do_not_associate_control_ids() >> / C<< $msg->do_not_associate_control_ids($value) >>

Type: C<String>

Condition do not associate specifications. If multiple do not associate
conditions match, all matching do not associate controls in the list will
execute.
- Order does not matter.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->replacement_control_ids() >> / C<< $msg->replacement_control_ids($value) >>

Type: C<String>

Condition replacement specifications.
- Applied according to the order in the list.
- A previously replaced term can not be re-replaced.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->ignore_control_ids() >> / C<< $msg->ignore_control_ids($value) >>

Type: C<String>

Condition ignore specifications. If multiple ignore
conditions match, all matching ignore controls in the list will
execute.
- Order does not matter.
- Maximum number of specifications is 100.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->diversity_level() >> / C<< $msg->diversity_level($value) >>

Type: C<String>

How much diversity to use in recommendation model results e.g.
`medium-diversity` or `high-diversity`. Currently supported values:

* `no-diversity`
* `low-diversity`
* `medium-diversity`
* `high-diversity`
* `auto-diversity`

If not specified, we choose default based on recommendation model
type. Default value: `no-diversity`.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->diversity_type() >> / C<< $msg->diversity_type($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::ServingConfig::DiversityType>)

What kind of diversity to use - data driven or rule based. If unset, the
server behavior defaults to
[RULE_BASED_DIVERSITY][google.cloud.retail.v2.ServingConfig.DiversityType.RULE_BASED_DIVERSITY].

=item * C<< $msg->enable_category_filter_level() >> / C<< $msg->enable_category_filter_level($value) >>

Type: C<String>

Whether to add additional category filters on the `similar-items` model.
If not specified, we enable it by default.
 Allowed values are:

* `no-category-match`: No additional filtering of original results from
  the model and the customer's filters.
* `relaxed-category-match`: Only keep results with categories that match
  at least one item categories in the PredictRequests's context item.
  * If customer also sends filters in the PredictRequest, then the results
  will satisfy both conditions (user given and category match).

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->ignore_recs_denylist() >> / C<< $msg->ignore_recs_denylist($value) >>

Type: C<Bool>

When the flag is enabled, the products in the denylist will not be filtered
out in the recommendation filtering results.

=item * C<< $msg->personalization_spec() >> / C<< $msg->personalization_spec($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::SearchService::SearchRequest::PersonalizationSpec>)

The specification for personalization spec.

Can only be set if
[solution_types][google.cloud.retail.v2.ServingConfig.solution_types] is
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

Notice that if both
[ServingConfig.personalization_spec][google.cloud.retail.v2.ServingConfig.personalization_spec]
and
[SearchRequest.personalization_spec][google.cloud.retail.v2.SearchRequest.personalization_spec]
are set.
[SearchRequest.personalization_spec][google.cloud.retail.v2.SearchRequest.personalization_spec]
will override
[ServingConfig.personalization_spec][google.cloud.retail.v2.ServingConfig.personalization_spec].

=item * C<< $msg->solution_types() >> / C<< $msg->solution_types($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::SolutionType>)

Required. Immutable. Specifies the solution types that a serving config can
be associated with. Currently we support setting only one type of solution.

=back

=head3 Enum: ServingConfig::DiversityType

=over 4

=item * C<DIVERSITY_TYPE_UNSPECIFIED> => C<0>

=item * C<RULE_BASED_DIVERSITY> => C<2>

=item * C<DATA_DRIVEN_DIVERSITY> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::ServingConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
