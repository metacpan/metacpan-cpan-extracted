package Google::Cloud::Retail::V2::CatalogService;

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
    eval { require Google::Cloud::Retail::V2::Catalog };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2NhdGFsb2dfc2VydmljZS5wcm90bxIWZ29vZ2xl
LmNsb3VkLnJldGFpbC52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJGdvb2dsZS9jbG91ZC9yZXRhaWwvdjIvY2F0YWxv
Zy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYv
ZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKUAQoT
TGlzdENhdGFsb2dzUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwohbG9jYXRpb25z
Lmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghw
YWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4iewoUTGlzdENhdGFsb2dz
UmVzcG9uc2USOwoIY2F0YWxvZ3MYASADKAsyHy5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkNh
dGFsb2dSCGNhdGFsb2dzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tl
biKTAQoUVXBkYXRlQ2F0YWxvZ1JlcXVlc3QSPgoHY2F0YWxvZxgBIAEoCzIfLmdvb2dsZS5j
bG91ZC5yZXRhaWwudjIuQ2F0YWxvZ0ID4EECUgdjYXRhbG9nEjsKC3VwZGF0ZV9tYXNrGAIg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayLBAQoXU2V0RGVm
YXVsdEJyYW5jaFJlcXVlc3QSPAoHY2F0YWxvZxgBIAEoCUIi+kEfCh1yZXRhaWwuZ29vZ2xl
YXBpcy5jb20vQ2F0YWxvZ1IHY2F0YWxvZxI+CglicmFuY2hfaWQYAiABKAlCIfpBHgoccmV0
YWlsLmdvb2dsZWFwaXMuY29tL0JyYW5jaFIIYnJhbmNoSWQSEgoEbm90ZRgDIAEoCVIEbm90
ZRIUCgVmb3JjZRgEIAEoCFIFZm9yY2UiVwoXR2V0RGVmYXVsdEJyYW5jaFJlcXVlc3QSPAoH
Y2F0YWxvZxgBIAEoCUIi+kEfCh1yZXRhaWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IHY2F0
YWxvZyKgAQoYR2V0RGVmYXVsdEJyYW5jaFJlc3BvbnNlEjkKBmJyYW5jaBgBIAEoCUIh+kEe
ChxyZXRhaWwuZ29vZ2xlYXBpcy5jb20vQnJhbmNoUgZicmFuY2gSNQoIc2V0X3RpbWUYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdzZXRUaW1lEhIKBG5vdGUYAyABKAlS
BG5vdGUiYAoaR2V0Q29tcGxldGlvbkNvbmZpZ1JlcXVlc3QSQgoEbmFtZRgBIAEoCUIu4EEC
+kEoCiZyZXRhaWwuZ29vZ2xlYXBpcy5jb20vQ29tcGxldGlvbkNvbmZpZ1IEbmFtZSK4AQod
VXBkYXRlQ29tcGxldGlvbkNvbmZpZ1JlcXVlc3QSWgoRY29tcGxldGlvbl9jb25maWcYASAB
KAsyKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkNvbXBsZXRpb25Db25maWdCA+BBAlIQY29t
cGxldGlvbkNvbmZpZxI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tSCnVwZGF0ZU1hc2siYAoaR2V0QXR0cmlidXRlc0NvbmZpZ1JlcXVlc3QSQgoE
bmFtZRgBIAEoCUIu4EEC+kEoCiZyZXRhaWwuZ29vZ2xlYXBpcy5jb20vQXR0cmlidXRlc0Nv
bmZpZ1IEbmFtZSK4AQodVXBkYXRlQXR0cmlidXRlc0NvbmZpZ1JlcXVlc3QSWgoRYXR0cmli
dXRlc19jb25maWcYASABKAsyKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkF0dHJpYnV0ZXND
b25maWdCA+BBAlIQYXR0cmlidXRlc0NvbmZpZxI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2si1QEKGkFkZENhdGFsb2dBdHRy
aWJ1dGVSZXF1ZXN0ElsKEWF0dHJpYnV0ZXNfY29uZmlnGAEgASgJQi7gQQL6QSgKJnJldGFp
bC5nb29nbGVhcGlzLmNvbS9BdHRyaWJ1dGVzQ29uZmlnUhBhdHRyaWJ1dGVzQ29uZmlnEloK
EWNhdGFsb2dfYXR0cmlidXRlGAIgASgLMiguZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5DYXRh
bG9nQXR0cmlidXRlQgPgQQJSEGNhdGFsb2dBdHRyaWJ1dGUikwEKHVJlbW92ZUNhdGFsb2dB
dHRyaWJ1dGVSZXF1ZXN0ElsKEWF0dHJpYnV0ZXNfY29uZmlnGAEgASgJQi7gQQL6QSgKJnJl
dGFpbC5nb29nbGVhcGlzLmNvbS9BdHRyaWJ1dGVzQ29uZmlnUhBhdHRyaWJ1dGVzQ29uZmln
EhUKA2tleRgCIAEoCUID4EECUgNrZXkilgIKHlJlcGxhY2VDYXRhbG9nQXR0cmlidXRlUmVx
dWVzdBJbChFhdHRyaWJ1dGVzX2NvbmZpZxgBIAEoCUIu4EEC+kEoCiZyZXRhaWwuZ29vZ2xl
YXBpcy5jb20vQXR0cmlidXRlc0NvbmZpZ1IQYXR0cmlidXRlc0NvbmZpZxJaChFjYXRhbG9n
X2F0dHJpYnV0ZRgCIAEoCzIoLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ2F0YWxvZ0F0dHJp
YnV0ZUID4EECUhBjYXRhbG9nQXR0cmlidXRlEjsKC3VwZGF0ZV9tYXNrGAMgASgLMhouZ29v
Z2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzazKXEwoOQ2F0YWxvZ1NlcnZpY2US
qAEKDExpc3RDYXRhbG9ncxIrLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuTGlzdENhdGFsb2dz
UmVxdWVzdBosLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuTGlzdENhdGFsb2dzUmVzcG9uc2Ui
PYLT5JMCLhIsL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vY2F0YWxvZ3Pa
QQZwYXJlbnQSuwEKDVVwZGF0ZUNhdGFsb2cSLC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlVw
ZGF0ZUNhdGFsb2dSZXF1ZXN0Gh8uZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5DYXRhbG9nIluC
0+STAj8yNC92Mi97Y2F0YWxvZy5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxv
Z3MvKn06B2NhdGFsb2faQRNjYXRhbG9nLHVwZGF0ZV9tYXNrErIBChBTZXREZWZhdWx0QnJh
bmNoEi8uZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZXREZWZhdWx0QnJhbmNoUmVxdWVzdBoW
Lmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJVgtPkkwJFIkAvdjIve2NhdGFsb2c9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfTpzZXREZWZhdWx0QnJhbmNoOgEq2kEHY2F0YWxv
ZxLJAQoQR2V0RGVmYXVsdEJyYW5jaBIvLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuR2V0RGVm
YXVsdEJyYW5jaFJlcXVlc3QaMC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkdldERlZmF1bHRC
cmFuY2hSZXNwb25zZSJSgtPkkwJCEkAvdjIve2NhdGFsb2c9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jYXRhbG9ncy8qfTpnZXREZWZhdWx0QnJhbmNo2kEHY2F0YWxvZxLBAQoTR2V0Q29t
cGxldGlvbkNvbmZpZxIyLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuR2V0Q29tcGxldGlvbkNv
bmZpZ1JlcXVlc3QaKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkNvbXBsZXRpb25Db25maWci
TILT5JMCPxI9L3YyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKi9j
b21wbGV0aW9uQ29uZmlnfdpBBG5hbWUShgIKFlVwZGF0ZUNvbXBsZXRpb25Db25maWcSNS5n
b29nbGUuY2xvdWQucmV0YWlsLnYyLlVwZGF0ZUNvbXBsZXRpb25Db25maWdSZXF1ZXN0Gigu
Z29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Db21wbGV0aW9uQ29uZmlnIooBgtPkkwJkMk8vdjIv
e2NvbXBsZXRpb25fY29uZmlnLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9n
cy8qL2NvbXBsZXRpb25Db25maWd9OhFjb21wbGV0aW9uX2NvbmZpZ9pBHWNvbXBsZXRpb25f
Y29uZmlnLHVwZGF0ZV9tYXNrEsEBChNHZXRBdHRyaWJ1dGVzQ29uZmlnEjIuZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5HZXRBdHRyaWJ1dGVzQ29uZmlnUmVxdWVzdBooLmdvb2dsZS5jbG91
ZC5yZXRhaWwudjIuQXR0cmlidXRlc0NvbmZpZyJMgtPkkwI/Ej0vdjIve25hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qL2F0dHJpYnV0ZXNDb25maWd92kEEbmFtZRKG
AgoWVXBkYXRlQXR0cmlidXRlc0NvbmZpZxI1Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuVXBk
YXRlQXR0cmlidXRlc0NvbmZpZ1JlcXVlc3QaKC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkF0
dHJpYnV0ZXNDb25maWciigGC0+STAmQyTy92Mi97YXR0cmlidXRlc19jb25maWcubmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovYXR0cmlidXRlc0NvbmZpZ306EWF0
dHJpYnV0ZXNfY29uZmln2kEdYXR0cmlidXRlc19jb25maWcsdXBkYXRlX21hc2sS3gEKE0Fk
ZENhdGFsb2dBdHRyaWJ1dGUSMi5nb29nbGUuY2xvdWQucmV0YWlsLnYyLkFkZENhdGFsb2dB
dHRyaWJ1dGVSZXF1ZXN0GiguZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5BdHRyaWJ1dGVzQ29u
ZmlnImmC0+STAmMiXi92Mi97YXR0cmlidXRlc19jb25maWc9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jYXRhbG9ncy8qL2F0dHJpYnV0ZXNDb25maWd9OmFkZENhdGFsb2dBdHRyaWJ1dGU6
ASoS5wEKFlJlbW92ZUNhdGFsb2dBdHRyaWJ1dGUSNS5nb29nbGUuY2xvdWQucmV0YWlsLnYy
LlJlbW92ZUNhdGFsb2dBdHRyaWJ1dGVSZXF1ZXN0GiguZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5BdHRyaWJ1dGVzQ29uZmlnImyC0+STAmYiYS92Mi97YXR0cmlidXRlc19jb25maWc9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qL2F0dHJpYnV0ZXNDb25maWd9OnJlbW92
ZUNhdGFsb2dBdHRyaWJ1dGU6ASoS6gEKF1JlcGxhY2VDYXRhbG9nQXR0cmlidXRlEjYuZ29v
Z2xlLmNsb3VkLnJldGFpbC52Mi5SZXBsYWNlQ2F0YWxvZ0F0dHJpYnV0ZVJlcXVlc3QaKC5n
b29nbGUuY2xvdWQucmV0YWlsLnYyLkF0dHJpYnV0ZXNDb25maWcibYLT5JMCZyJiL3YyL3th
dHRyaWJ1dGVzX2NvbmZpZz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovYXR0
cmlidXRlc0NvbmZpZ306cmVwbGFjZUNhdGFsb2dBdHRyaWJ1dGU6ASoaScpBFXJldGFpbC5n
b29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQt
cGxhdGZvcm1CvgEKGmNvbS5nb29nbGUuY2xvdWQucmV0YWlsLnYyQhNDYXRhbG9nU2Vydmlj
ZVByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyL3JldGFpbHBiO3Jl
dGFpbHBiogIGUkVUQUlMqgIWR29vZ2xlLkNsb3VkLlJldGFpbC5WMsoCFkdvb2dsZVxDbG91
ZFxSZXRhaWxcVjLqAhlHb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYySo99CgcSBQ4A3AMBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACYK
CQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYALgoJCgIDBRIDFwAl
CgkKAgMGEgMYACoKCQoCAwcSAxkAKQoICgEIEgMbADMKCQoCCCUSAxsAMwoICgEIEgMcAEkK
CQoCCAsSAxwASQoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeADQKCQoCCAgSAx4ANAoI
CgEIEgMfADMKCQoCCAESAx8AMwoICgEIEgMgACQKCQoCCCQSAyAAJAoICgEIEgMhADMKCQoC
CCkSAyEAMwoICgEIEgMiADIKCQoCCC0SAyIAMgo6CgIGABIFJQDKAQEaLSBTZXJ2aWNlIGZv
ciBtYW5hZ2luZyBjYXRhbG9nIGNvbmZpZ3VyYXRpb24uCgoKCgMGAAESAyUIFgoKCgMGAAMS
AyYCPQoMCgUGAAOZCBIDJgI9CgsKAwYAAxIEJwIoNwoNCgUGAAOaCBIEJwIoNwpmCgQGAAIA
EgQsAjEDGlggTGlzdHMgYWxsIHRoZSBbQ2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52
Mi5DYXRhbG9nXXMgYXNzb2NpYXRlZCB3aXRoCiB0aGUgcHJvamVjdC4KCgwKBQYAAgABEgMs
BhIKDAoFBgACAAISAywTJgoMCgUGAAIAAxIDLDFFCg0KBQYAAgAEEgQtBC8GChEKCQYAAgAE
sMq8IhIELQQvBgoMCgUGAAIABBIDMAQ0Cg8KCAYAAgAEmwgAEgMwBDQKRwoEBgACARIENAI6
Axo5IFVwZGF0ZXMgdGhlIFtDYXRhbG9nXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFs
b2ddcy4KCgwKBQYAAgEBEgM0BhMKDAoFBgACAQISAzQUKAoMCgUGAAIBAxIDNDM6Cg0KBQYA
AgEEEgQ1BDgGChEKCQYAAgEEsMq8IhIENQQ4BgoMCgUGAAIBBBIDOQRBCg8KCAYAAgEEmwgA
EgM5BEEK9wwKBAYAAgISBF4CZQMa6AwgU2V0IGEgc3BlY2lmaWVkIGJyYW5jaCBpZCBhcyBk
ZWZhdWx0IGJyYW5jaC4gQVBJIG1ldGhvZHMgc3VjaCBhcwogW1NlYXJjaFNlcnZpY2UuU2Vh
cmNoXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNlYXJjaFNlcnZpY2UuU2VhcmNoXSwKIFtQ
cm9kdWN0U2VydmljZS5HZXRQcm9kdWN0XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlByb2R1
Y3RTZXJ2aWNlLkdldFByb2R1Y3RdLAogW1Byb2R1Y3RTZXJ2aWNlLkxpc3RQcm9kdWN0c11b
Z29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Qcm9kdWN0U2VydmljZS5MaXN0UHJvZHVjdHNdCiB3
aWxsIHRyZWF0IHJlcXVlc3RzIHVzaW5nICJkZWZhdWx0X2JyYW5jaCIgdG8gdGhlIGFjdHVh
bCBicmFuY2ggaWQgc2V0IGFzCiBkZWZhdWx0LgoKIEZvciBleGFtcGxlLCBpZiBgcHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qL2JyYW5jaGVzLzFgIGlzIHNldCBhcwogZGVm
YXVsdCwgc2V0dGluZwogW1NlYXJjaFJlcXVlc3QuYnJhbmNoXVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyLlNlYXJjaFJlcXVlc3QuYnJhbmNoXSB0bwogYHByb2plY3RzLyovbG9jYXRpb25z
LyovY2F0YWxvZ3MvKi9icmFuY2hlcy9kZWZhdWx0X2JyYW5jaGAgaXMgZXF1aXZhbGVudAog
dG8gc2V0dGluZwogW1NlYXJjaFJlcXVlc3QuYnJhbmNoXVtnb29nbGUuY2xvdWQucmV0YWls
LnYyLlNlYXJjaFJlcXVlc3QuYnJhbmNoXSB0bwogYHByb2plY3RzLyovbG9jYXRpb25zLyov
Y2F0YWxvZ3MvKi9icmFuY2hlcy8xYC4KCiBVc2luZyBtdWx0aXBsZSBicmFuY2hlcyBjYW4g
YmUgdXNlZnVsIHdoZW4gZGV2ZWxvcGVycyB3b3VsZCBsaWtlCiB0byBoYXZlIGEgc3RhZ2lu
ZyBicmFuY2ggdG8gdGVzdCBhbmQgdmVyaWZ5IGZvciBmdXR1cmUgdXNhZ2UuIFdoZW4gaXQK
IGJlY29tZXMgcmVhZHksIGRldmVsb3BlcnMgc3dpdGNoIG9uIHRoZSBzdGFnaW5nIGJyYW5j
aCB1c2luZyB0aGlzIEFQSQogd2hpbGUga2VlcGluZyB1c2luZwogYHByb2plY3RzLyovbG9j
YXRpb25zLyovY2F0YWxvZ3MvKi9icmFuY2hlcy9kZWZhdWx0X2JyYW5jaGAgYXMKIFtTZWFy
Y2hSZXF1ZXN0LmJyYW5jaF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZWFyY2hSZXF1ZXN0
LmJyYW5jaF0gdG8KIHJvdXRlIHRoZSB0cmFmZmljIHRvIHRoaXMgc3RhZ2luZyBicmFuY2gu
CgogQ0FVVElPTjogSWYgeW91IGhhdmUgbGl2ZSBwcmVkaWN0L3NlYXJjaCB0cmFmZmljLCBz
d2l0Y2hpbmcgdGhlIGRlZmF1bHQKIGJyYW5jaCBjb3VsZCBwb3RlbnRpYWxseSBjYXVzZSBv
dXRhZ2VzIGlmIHRoZSBJRCBzcGFjZSBvZiB0aGUgbmV3IGJyYW5jaAogaXMgdmVyeSBkaWZm
ZXJlbnQgZnJvbSB0aGUgb2xkIG9uZS4KCiBNb3JlIHNwZWNpZmljYWxseToKCiAqIFByZWRp
Y3Rpb25TZXJ2aWNlIHdpbGwgb25seSByZXR1cm4gcHJvZHVjdCBJRHMgZnJvbSBicmFuY2gg
e25ld0JyYW5jaH0uCiAqIFNlYXJjaFNlcnZpY2Ugd2lsbCBvbmx5IHJldHVybiBwcm9kdWN0
IElEcyBmcm9tIGJyYW5jaCB7bmV3QnJhbmNofQogICAoaWYgYnJhbmNoIGlzIG5vdCBleHBs
aWNpdGx5IHNldCkuCiAqIFVzZXJFdmVudFNlcnZpY2Ugd2lsbCBvbmx5IGpvaW4gZXZlbnRz
IHdpdGggcHJvZHVjdHMgZnJvbSBicmFuY2gKICAge25ld0JyYW5jaH0uCgoMCgUGAAICARID
XgYWCgwKBQYAAgICEgNeFy4KDAoFBgACAgMSA18PJAoNCgUGAAICBBIEYARjBgoRCgkGAAIC
BLDKvCISBGAEYwYKDAoFBgACAgQSA2QENQoPCggGAAICBJsIABIDZAQ1CskBCgQGAAIDEgRq
AnADGroBIEdldCB3aGljaCBicmFuY2ggaXMgY3VycmVudGx5IGRlZmF1bHQgYnJhbmNoIHNl
dCBieQogW0NhdGFsb2dTZXJ2aWNlLlNldERlZmF1bHRCcmFuY2hdW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuQ2F0YWxvZ1NlcnZpY2UuU2V0RGVmYXVsdEJyYW5jaF0KIG1ldGhvZCB1bmRl
ciBhIHNwZWNpZmllZCBwYXJlbnQgY2F0YWxvZy4KCgwKBQYAAgMBEgNqBhYKDAoFBgACAwIS
A2oXLgoMCgUGAAIDAxIDaw8nCg0KBQYAAgMEEgRsBG4GChEKCQYAAgMEsMq8IhIEbARuBgoM
CgUGAAIDBBIDbwQ1Cg8KCAYAAgMEmwgAEgNvBDUKUwoEBgACBBIEcwJ5AxpFIEdldHMgYSBb
Q29tcGxldGlvbkNvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Db21wbGV0aW9uQ29u
ZmlnXS4KCgwKBQYAAgQBEgNzBhkKDAoFBgACBAISA3MaNAoMCgUGAAIEAxIDdA8fCg0KBQYA
AgQEEgR1BHcGChEKCQYAAgQEsMq8IhIEdQR3BgoMCgUGAAIEBBIDeAQyCg8KCAYAAgQEmwgA
EgN4BDIKWgoEBgACBRIFfAKDAQMaSyBVcGRhdGVzIHRoZSBbQ29tcGxldGlvbkNvbmZpZ11b
Z29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Db21wbGV0aW9uQ29uZmlnXXMuCgoMCgUGAAIFARID
fAYcCgwKBQYAAgUCEgN8HToKDAoFBgACBQMSA30PHwoOCgUGAAIFBBIFfgSBAQYKEgoJBgAC
BQSwyrwiEgV+BIEBBgoNCgUGAAIFBBIEggEESwoQCggGAAIFBJsIABIEggEESwpWCgQGAAIG
EgaGAQKMAQMaRiBHZXRzIGFuIFtBdHRyaWJ1dGVzQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyLkF0dHJpYnV0ZXNDb25maWddLgoKDQoFBgACBgESBIYBBhkKDQoFBgACBgISBIYB
GjQKDQoFBgACBgMSBIcBDx8KDwoFBgACBgQSBogBBIoBBgoTCgkGAAIGBLDKvCISBogBBIoB
BgoNCgUGAAIGBBIEiwEEMgoQCggGAAIGBJsIABIEiwEEMgqWBAoEBgACBxIGlgECnQEDGoUE
IFVwZGF0ZXMgdGhlIFtBdHRyaWJ1dGVzQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
LkF0dHJpYnV0ZXNDb25maWddLgoKIFRoZSBjYXRhbG9nIGF0dHJpYnV0ZXMgaW4gdGhlIHJl
cXVlc3Qgd2lsbCBiZSB1cGRhdGVkIGluIHRoZSBjYXRhbG9nLCBvcgogaW5zZXJ0ZWQgaWYg
dGhleSBkbyBub3QgZXhpc3QuIEV4aXN0aW5nIGNhdGFsb2cgYXR0cmlidXRlcyBub3QgaW5j
bHVkZWQgaW4KIHRoZSByZXF1ZXN0IHdpbGwgcmVtYWluIHVuY2hhbmdlZC4gQXR0cmlidXRl
cyB0aGF0IGFyZSBhc3NpZ25lZCB0bwogcHJvZHVjdHMsIGJ1dCBkbyBub3QgZXhpc3QgYXQg
dGhlIGNhdGFsb2cgbGV2ZWwsIGFyZSBhbHdheXMgaW5jbHVkZWQgaW4gdGhlCiByZXNwb25z
ZS4gVGhlIHByb2R1Y3QgYXR0cmlidXRlIGlzIGFzc2lnbmVkIGRlZmF1bHQgdmFsdWVzIGZv
ciBtaXNzaW5nCiBjYXRhbG9nIGF0dHJpYnV0ZSBmaWVsZHMsIGUuZy4sIHNlYXJjaGFibGUg
YW5kIGR5bmFtaWMgZmFjZXRhYmxlIG9wdGlvbnMuCgoNCgUGAAIHARIElgEGHAoNCgUGAAIH
AhIElgEdOgoNCgUGAAIHAxIElwEPHwoPCgUGAAIHBBIGmAEEmwEGChMKCQYAAgcEsMq8IhIG
mAEEmwEGCg0KBQYAAgcEEgScAQRLChAKCAYAAgcEmwgAEgScAQRLCqkCCgQGAAIIEgalAQKr
AQMamAIgQWRkcyB0aGUgc3BlY2lmaWVkCiBbQ2F0YWxvZ0F0dHJpYnV0ZV1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5DYXRhbG9nQXR0cmlidXRlXSB0byB0aGUKIFtBdHRyaWJ1dGVzQ29u
ZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkF0dHJpYnV0ZXNDb25maWddLgoKIElmIHRo
ZSBbQ2F0YWxvZ0F0dHJpYnV0ZV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5DYXRhbG9nQXR0
cmlidXRlXSB0byBhZGQKIGFscmVhZHkgZXhpc3RzLCBhbiBBTFJFQURZX0VYSVNUUyBlcnJv
ciBpcyByZXR1cm5lZC4KCg0KBQYAAggBEgSlAQYZCg0KBQYAAggCEgSlARo0Cg0KBQYAAggD
EgSmAQ8fCg8KBQYAAggEEganAQSqAQYKEwoJBgACCASwyrwiEganAQSqAQYKqwIKBAYAAgkS
BrMBArkBAxqaAiBSZW1vdmVzIHRoZSBzcGVjaWZpZWQKIFtDYXRhbG9nQXR0cmlidXRlXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFsb2dBdHRyaWJ1dGVdIGZyb20gdGhlCiBbQXR0
cmlidXRlc0NvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5BdHRyaWJ1dGVzQ29uZmln
XS4KCiBJZiB0aGUgW0NhdGFsb2dBdHRyaWJ1dGVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIu
Q2F0YWxvZ0F0dHJpYnV0ZV0gdG8KIHJlbW92ZSBkb2VzIG5vdCBleGlzdCwgYSBOT1RfRk9V
TkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUGAAIJARIEswEGHAoNCgUGAAIJAhIEswEdOgoN
CgUGAAIJAxIEtAEPHwoPCgUGAAIJBBIGtQEEuAEGChMKCQYAAgkEsMq8IhIGtQEEuAEGCqED
CgQGAAIKEgbDAQLJAQMakAMgUmVwbGFjZXMgdGhlIHNwZWNpZmllZAogW0NhdGFsb2dBdHRy
aWJ1dGVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ2F0YWxvZ0F0dHJpYnV0ZV0gaW4gdGhl
CiBbQXR0cmlidXRlc0NvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5BdHRyaWJ1dGVz
Q29uZmlnXSBieSB1cGRhdGluZyB0aGUKIGNhdGFsb2cgYXR0cmlidXRlIHdpdGggdGhlIHNh
bWUKIFtDYXRhbG9nQXR0cmlidXRlLmtleV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5DYXRh
bG9nQXR0cmlidXRlLmtleV0uCgogSWYgdGhlIFtDYXRhbG9nQXR0cmlidXRlXVtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyLkNhdGFsb2dBdHRyaWJ1dGVdIHRvCiByZXBsYWNlIGRvZXMgbm90
IGV4aXN0LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQYAAgoBEgTDAQYd
Cg0KBQYAAgoCEgTDAR48Cg0KBQYAAgoDEgTEAQ8fCg8KBQYAAgoEEgbFAQTIAQYKEwoJBgAC
CgSwyrwiEgbFAQTIAQYKdwoCBAASBs8BAO8BARppIFJlcXVlc3QgZm9yCiBbQ2F0YWxvZ1Nl
cnZpY2UuTGlzdENhdGFsb2dzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFsb2dTZXJ2
aWNlLkxpc3RDYXRhbG9nc10KIG1ldGhvZC4KCgsKAwQAARIEzwEIGwqhAgoEBAACABIG1gEC
2wEEGpACIFJlcXVpcmVkLiBUaGUgYWNjb3VudCByZXNvdXJjZSBuYW1lIHdpdGggYW4gYXNz
b2NpYXRlZCBsb2NhdGlvbi4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlz
c2lvbiB0byBsaXN0CiBbQ2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5DYXRhbG9n
XXMgdW5kZXIgdGhpcyBsb2NhdGlvbiwgcmVnYXJkbGVzcwogb2Ygd2hldGhlciBvciBub3Qg
dGhpcyBsb2NhdGlvbiBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMKIHJl
dHVybmVkLgoKDQoFBAACAAUSBNYBAggKDQoFBAACAAESBNYBCQ8KDQoFBAACAAMSBNYBEhMK
DwoFBAACAAgSBtYBFNsBAwoQCggEAAIACJwIABIE1wEEKgoRCgcEAAIACJ8IEgbYAQTaAQUK
hgIKBAQAAgESBOIBAhYa9wEgTWF4aW11bSBudW1iZXIgb2YgW0NhdGFsb2ddW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjIuQ2F0YWxvZ11zIHRvIHJldHVybi4gSWYKIHVuc3BlY2lmaWVkLCBk
ZWZhdWx0cyB0byA1MC4gVGhlIG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcyAxMDAwLiBWYWx1
ZXMKIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCgogSWYgdGhpcyBmaWVs
ZCBpcyBuZWdhdGl2ZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBpcyByZXR1cm5lZC4KCg0KBQQA
AgEFEgTiAQIHCg0KBQQAAgEBEgTiAQgRCg0KBQQAAgEDEgTiARQVCpIECgQEAAICEgTuAQIY
GoMEIEEgcGFnZSB0b2tlbgogW0xpc3RDYXRhbG9nc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tl
bl1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5MaXN0Q2F0YWxvZ3NSZXNwb25zZS5uZXh0X3Bh
Z2VfdG9rZW5dLAogcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBbQ2F0YWxvZ1NlcnZpY2Uu
TGlzdENhdGFsb2dzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFsb2dTZXJ2aWNlLkxp
c3RDYXRhbG9nc10KIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2Vx
dWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJv
dmlkZWQgdG8KIFtDYXRhbG9nU2VydmljZS5MaXN0Q2F0YWxvZ3NdW2dvb2dsZS5jbG91ZC5y
ZXRhaWwudjIuQ2F0YWxvZ1NlcnZpY2UuTGlzdENhdGFsb2dzXQogbXVzdCBtYXRjaCB0aGUg
Y2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLiBPdGhlcndpc2UsIGFuCiBJTlZB
TElEX0FSR1VNRU5UIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAACAgUSBO4BAggKDQoFBAAC
AgESBO4BCRMKDQoFBAACAgMSBO4BFhcKeAoCBAESBvQBAP0BARpqIFJlc3BvbnNlIGZvcgog
W0NhdGFsb2dTZXJ2aWNlLkxpc3RDYXRhbG9nc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5D
YXRhbG9nU2VydmljZS5MaXN0Q2F0YWxvZ3NdCiBtZXRob2QuCgoLCgMEAQESBPQBCBwKTgoE
BAECABIE9gECIBpAIEFsbCB0aGUgY3VzdG9tZXIncyBbQ2F0YWxvZ11bZ29vZ2xlLmNsb3Vk
LnJldGFpbC52Mi5DYXRhbG9nXXMuCgoNCgUEAQIABBIE9gECCgoNCgUEAQIABhIE9gELEgoN
CgUEAQIAARIE9gETGwoNCgUEAQIAAxIE9gEeHwrbAQoEBAECARIE/AECHRrMASBBIHRva2Vu
IHRoYXQgY2FuIGJlIHNlbnQgYXMKIFtMaXN0Q2F0YWxvZ3NSZXF1ZXN0LnBhZ2VfdG9rZW5d
W2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuTGlzdENhdGFsb2dzUmVxdWVzdC5wYWdlX3Rva2Vu
XQogdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVk
LCB0aGVyZSBhcmUgbm8KIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEAQIBBRIE/AECCAoNCgUE
AQIBARIE/AEJGAoNCgUEAQIBAxIE/AEbHAp5CgIEAhIGggIAkwIBGmsgUmVxdWVzdCBmb3IK
IFtDYXRhbG9nU2VydmljZS5VcGRhdGVDYXRhbG9nXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
LkNhdGFsb2dTZXJ2aWNlLlVwZGF0ZUNhdGFsb2ddCiBtZXRob2QuCgoLCgMEAgESBIICCBwK
8wIKBAQCAgASBIsCAj8a5AIgUmVxdWlyZWQuIFRoZSBbQ2F0YWxvZ11bZ29vZ2xlLmNsb3Vk
LnJldGFpbC52Mi5DYXRhbG9nXSB0byB1cGRhdGUuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5v
dCBoYXZlIHBlcm1pc3Npb24gdG8gdXBkYXRlIHRoZQogW0NhdGFsb2ddW2dvb2dsZS5jbG91
ZC5yZXRhaWwudjIuQ2F0YWxvZ10sIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlciBvciBub3QgaXQK
IGV4aXN0cywgYSBQRVJNSVNTSU9OX0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0
aGUgW0NhdGFsb2ddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ2F0YWxvZ10gdG8gdXBkYXRl
IGRvZXMgbm90IGV4aXN0LAogYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUE
AgIABhIEiwICCQoNCgUEAgIAARIEiwIKEQoNCgUEAgIAAxIEiwIUFQoNCgUEAgIACBIEiwIW
PgoQCggEAgIACJwIABIEiwIXPQrHAQoEBAICARIEkgICLBq4ASBJbmRpY2F0ZXMgd2hpY2gg
ZmllbGRzIGluIHRoZSBwcm92aWRlZAogW0NhdGFsb2ddW2dvb2dsZS5jbG91ZC5yZXRhaWwu
djIuQ2F0YWxvZ10gdG8gdXBkYXRlLgoKIElmIGFuIHVuc3VwcG9ydGVkIG9yIHVua25vd24g
ZmllbGQgaXMgcHJvdmlkZWQsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IKIGlzIHJldHVy
bmVkLgoKDQoFBAICAQYSBJICAhsKDQoFBAICAQESBJICHCcKDQoFBAICAQMSBJICKisKUAoC
BAMSBpYCALUCARpCIFJlcXVlc3QgbWVzc2FnZSB0byBzZXQgYSBzcGVjaWZpZWQgYnJhbmNo
IGFzIG5ldyBkZWZhdWx0X2JyYW5jaC4KCgsKAwQDARIElgIIHwp1CgQEAwIAEgaZAgKbAgQa
ZSBGdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIGNhdGFsb2csIHN1Y2ggYXMKIGBwcm9qZWN0
cy8qL2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvZGVmYXVsdF9jYXRhbG9nYC4KCg0KBQQD
AgAFEgSZAgIICg0KBQQDAgABEgSZAgkQCg0KBQQDAgADEgSZAhMUCg8KBQQDAgAIEgaZAhWb
AgMKDwoHBAMCAAifCBIEmgIETwrlAgoEBAMCARIGpQICpwIEGtQCIFRoZSBmaW5hbCBjb21w
b25lbnQgb2YgdGhlIHJlc291cmNlIG5hbWUgb2YgYSBicmFuY2guCgogVGhpcyBmaWVsZCBt
dXN0IGJlIG9uZSBvZiAiMCIsICIxIiBvciAiMiIuIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9B
UkdVTUVOVAogZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlcmUgYXJlIG5vIHN1ZmZpY2ll
bnQgYWN0aXZlIHByb2R1Y3RzIGluIHRoZSB0YXJnZXRlZCBicmFuY2ggYW5kCiBbZm9yY2Vd
W2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuU2V0RGVmYXVsdEJyYW5jaFJlcXVlc3QuZm9yY2Vd
IGlzIG5vdCBzZXQsIGEKIEZBSUxFRF9QUkVDT05ESVRJT04gZXJyb3IgaXMgcmV0dXJuZWQu
CgoNCgUEAwIBBRIEpQICCAoNCgUEAwIBARIEpQIJEgoNCgUEAwIBAxIEpQIVFgoPCgUEAwIB
CBIGpQIXpwIDCg8KBwQDAgEInwgSBKYCBE4K1QIKBAQDAgISBK8CAhIaxgIgU29tZSBub3Rl
IG9uIHRoaXMgcmVxdWVzdCwgdGhpcyBjYW4gYmUgcmV0cmlldmVkIGJ5CiBbQ2F0YWxvZ1Nl
cnZpY2UuR2V0RGVmYXVsdEJyYW5jaF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5DYXRhbG9n
U2VydmljZS5HZXREZWZhdWx0QnJhbmNoXQogYmVmb3JlIG5leHQgdmFsaWQgZGVmYXVsdCBi
cmFuY2ggc2V0IG9jY3Vycy4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVk
IHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEsMDAwCiBjaGFyYWN0ZXJzLiBPdGhl
cndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAwIC
BRIErwICCAoNCgUEAwICARIErwIJDQoNCgUEAwICAxIErwIQEQq8AQoEBAMCAxIEtAICERqt
ASBJZiBzZXQgdG8gdHJ1ZSwgaXQgcGVybWl0cyBzd2l0Y2hpbmcgdG8gYSBicmFuY2ggd2l0
aAogW2JyYW5jaF9pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5TZXREZWZhdWx0QnJhbmNo
UmVxdWVzdC5icmFuY2hfaWRdIGV2ZW4KIGlmIGl0IGhhcyBubyBzdWZmaWNpZW50IGFjdGl2
ZSBwcm9kdWN0cy4KCg0KBQQDAgMFEgS0AgIGCg0KBQQDAgMBEgS0AgcMCg0KBQQDAgMDEgS0
Ag8QClUKAgQEEga4AgC+AgEaRyBSZXF1ZXN0IG1lc3NhZ2UgdG8gc2hvdyB3aGljaCBicmFu
Y2ggaXMgY3VycmVudGx5IHRoZSBkZWZhdWx0IGJyYW5jaC4KCgsKAwQEARIEuAIIHwp0CgQE
BAIAEga7AgK9AgQaZCBUaGUgcGFyZW50IGNhdGFsb2cgcmVzb3VyY2UgbmFtZSwgc3VjaCBh
cwogYHByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9ncy9kZWZhdWx0X2NhdGFs
b2dgLgoKDQoFBAQCAAUSBLsCAggKDQoFBAQCAAESBLsCCRAKDQoFBAQCAAMSBLsCExQKDwoF
BAQCAAgSBrsCFb0CAwoPCgcEBAIACJ8IEgS8AgRPCn8KAgQFEgbCAgDPAgEacSBSZXNwb25z
ZSBtZXNzYWdlIG9mCiBbQ2F0YWxvZ1NlcnZpY2UuR2V0RGVmYXVsdEJyYW5jaF1bZ29vZ2xl
LmNsb3VkLnJldGFpbC52Mi5DYXRhbG9nU2VydmljZS5HZXREZWZhdWx0QnJhbmNoXS4KCgsK
AwQFARIEwgIIIApWCgQEBQIAEgbEAgLGAgQaRiBGdWxsIHJlc291cmNlIG5hbWUgb2YgdGhl
IGJyYW5jaCBpZCBjdXJyZW50bHkgc2V0IGFzIGRlZmF1bHQgYnJhbmNoLgoKDQoFBAUCAAUS
BMQCAggKDQoFBAUCAAESBMQCCQ8KDQoFBAUCAAMSBMQCEhMKDwoFBAUCAAgSBsQCFMYCAwoP
CgcEBQIACJ8IEgTFAgROCjwKBAQFAgESBMkCAikaLiBUaGUgdGltZSB3aGVuIHRoaXMgYnJh
bmNoIGlzIHNldCB0byBkZWZhdWx0LgoKDQoFBAUCAQYSBMkCAhsKDQoFBAUCAQESBMkCHCQK
DQoFBAUCAQMSBMkCJygKpgEKBAQFAgISBM4CAhIalwEgVGhpcyBjb3JyZXNwb25kcyB0bwog
W1NldERlZmF1bHRCcmFuY2hSZXF1ZXN0Lm5vdGVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIu
U2V0RGVmYXVsdEJyYW5jaFJlcXVlc3Qubm90ZV0KIGZpZWxkLCB3aGVuIHRoaXMgYnJhbmNo
IHdhcyBzZXQgYXMgZGVmYXVsdC4KCg0KBQQFAgIFEgTOAgIICg0KBQQFAgIBEgTOAgkNCg0K
BQQFAgIDEgTOAhARCoUBCgIEBhIG1AIA3QIBGncgUmVxdWVzdCBmb3IKIFtDYXRhbG9nU2Vy
dmljZS5HZXRDb21wbGV0aW9uQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFs
b2dTZXJ2aWNlLkdldENvbXBsZXRpb25Db25maWddCiBtZXRob2QuCgoLCgMEBgESBNQCCCIK
pQEKBAQGAgASBtcCAtwCBBqUASBSZXF1aXJlZC4gRnVsbCBDb21wbGV0aW9uQ29uZmlnIHJl
c291cmNlIG5hbWUuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0
aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lkfS9jb21wbGV0aW9uQ29u
ZmlnYAoKDQoFBAYCAAUSBNcCAggKDQoFBAYCAAESBNcCCQ0KDQoFBAYCAAMSBNcCEBEKDwoF
BAYCAAgSBtcCEtwCAwoQCggEBgIACJwIABIE2AIEKgoRCgcEBgIACJ8IEgbZAgTbAgUKiwEK
AgQHEgbiAgD6AgEafSBSZXF1ZXN0IGZvcgogW0NhdGFsb2dTZXJ2aWNlLlVwZGF0ZUNvbXBs
ZXRpb25Db25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ2F0YWxvZ1NlcnZpY2UuVXBk
YXRlQ29tcGxldGlvbkNvbmZpZ10KIG1ldGhvZC4KCgsKAwQHARIE4gIIJQqJAwoEBAcCABIG
7AIC7QIvGvgCIFJlcXVpcmVkLiBUaGUgW0NvbXBsZXRpb25Db25maWddW2dvb2dsZS5jbG91
ZC5yZXRhaWwudjIuQ29tcGxldGlvbkNvbmZpZ10KIHRvIHVwZGF0ZS4KCiBJZiB0aGUgY2Fs
bGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRhdGUgdGhlCiBbQ29tcGxldGlv
bkNvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Db21wbGV0aW9uQ29uZmlnXSwgdGhl
biBhCiBQRVJNSVNTSU9OX0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW0Nv
bXBsZXRpb25Db25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29tcGxldGlvbkNvbmZp
Z10gdG8KIHVwZGF0ZSBkb2VzIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0
dXJuZWQuCgoNCgUEBwIABhIE7AICEgoNCgUEBwIAARIE7AITJAoNCgUEBwIAAxIE7AInKAoN
CgUEBwIACBIE7QIGLgoQCggEBwIACJwIABIE7QIHLQrYBAoEBAcCARIE+QICLBrJBCBJbmRp
Y2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZAogW0NvbXBsZXRpb25Db25maWdd
W2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29tcGxldGlvbkNvbmZpZ10gdG8gdXBkYXRlLiBU
aGUKIGZvbGxvd2luZyBhcmUgdGhlIG9ubHkgc3VwcG9ydGVkIGZpZWxkczoKCiAqIFtDb21w
bGV0aW9uQ29uZmlnLm1hdGNoaW5nX29yZGVyXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNv
bXBsZXRpb25Db25maWcubWF0Y2hpbmdfb3JkZXJdCiAqIFtDb21wbGV0aW9uQ29uZmlnLm1h
eF9zdWdnZXN0aW9uc11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Db21wbGV0aW9uQ29uZmln
Lm1heF9zdWdnZXN0aW9uc10KICogW0NvbXBsZXRpb25Db25maWcubWluX3ByZWZpeF9sZW5n
dGhdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuQ29tcGxldGlvbkNvbmZpZy5taW5fcHJlZml4
X2xlbmd0aF0KICogW0NvbXBsZXRpb25Db25maWcuYXV0b19sZWFybmluZ11bZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5Db21wbGV0aW9uQ29uZmlnLmF1dG9fbGVhcm5pbmddCgogSWYgbm90
IHNldCwgYWxsIHN1cHBvcnRlZCBmaWVsZHMgYXJlIHVwZGF0ZWQuCgoNCgUEBwIBBhIE+QIC
GwoNCgUEBwIBARIE+QIcJwoNCgUEBwIBAxIE+QIqKwqFAQoCBAgSBv8CAIgDARp3IFJlcXVl
c3QgZm9yCiBbQ2F0YWxvZ1NlcnZpY2UuR2V0QXR0cmlidXRlc0NvbmZpZ11bZ29vZ2xlLmNs
b3VkLnJldGFpbC52Mi5DYXRhbG9nU2VydmljZS5HZXRBdHRyaWJ1dGVzQ29uZmlnXQogbWV0
aG9kLgoKCwoDBAgBEgT/AggiCqUBCgQECAIAEgaCAwKHAwQalAEgUmVxdWlyZWQuIEZ1bGwg
QXR0cmlidXRlc0NvbmZpZyByZXNvdXJjZSBuYW1lLiBGb3JtYXQ6CiBgcHJvamVjdHMve3By
b2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxv
Z19pZH0vYXR0cmlidXRlc0NvbmZpZ2AKCg0KBQQIAgAFEgSCAwIICg0KBQQIAgABEgSCAwkN
Cg0KBQQIAgADEgSCAxARCg8KBQQIAgAIEgaCAxKHAwMKEAoIBAgCAAicCAASBIMDBCoKEQoH
BAgCAAifCBIGhAMEhgMFCosBCgIECRIGjQMAmwMBGn0gUmVxdWVzdCBmb3IKIFtDYXRhbG9n
U2VydmljZS5VcGRhdGVBdHRyaWJ1dGVzQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYy
LkNhdGFsb2dTZXJ2aWNlLlVwZGF0ZUF0dHJpYnV0ZXNDb25maWddCiBtZXRob2QuCgoLCgME
CQESBI0DCCUKZwoEBAkCABIGkAMCkQMvGlcgUmVxdWlyZWQuIFRoZSBbQXR0cmlidXRlc0Nv
bmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5BdHRyaWJ1dGVzQ29uZmlnXQogdG8gdXBk
YXRlLgoKDQoFBAkCAAYSBJADAhIKDQoFBAkCAAESBJADEyQKDQoFBAkCAAMSBJADJygKDQoF
BAkCAAgSBJEDBi4KEAoIBAkCAAicCAASBJEDBy0KwQIKBAQJAgESBJoDAiwasgIgSW5kaWNh
dGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQKIFtBdHRyaWJ1dGVzQ29uZmlnXVtn
b29nbGUuY2xvdWQucmV0YWlsLnYyLkF0dHJpYnV0ZXNDb25maWddIHRvIHVwZGF0ZS4gVGhl
CiBmb2xsb3dpbmcgaXMgdGhlIG9ubHkgc3VwcG9ydGVkIGZpZWxkOgoKICogW0F0dHJpYnV0
ZXNDb25maWcuY2F0YWxvZ19hdHRyaWJ1dGVzXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkF0
dHJpYnV0ZXNDb25maWcuY2F0YWxvZ19hdHRyaWJ1dGVzXQoKIElmIG5vdCBzZXQsIGFsbCBz
dXBwb3J0ZWQgZmllbGRzIGFyZSB1cGRhdGVkLgoKDQoFBAkCAQYSBJoDAhsKDQoFBAkCAQES
BJoDHCcKDQoFBAkCAQMSBJoDKisKhQEKAgQKEgagAwCuAwEadyBSZXF1ZXN0IGZvcgogW0Nh
dGFsb2dTZXJ2aWNlLkFkZENhdGFsb2dBdHRyaWJ1dGVdW2dvb2dsZS5jbG91ZC5yZXRhaWwu
djIuQ2F0YWxvZ1NlcnZpY2UuQWRkQ2F0YWxvZ0F0dHJpYnV0ZV0KIG1ldGhvZC4KCgsKAwQK
ARIEoAMIIgqlAQoEBAoCABIGowMCqAMEGpQBIFJlcXVpcmVkLiBGdWxsIEF0dHJpYnV0ZXND
b25maWcgcmVzb3VyY2UgbmFtZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJl
cn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L2F0dHJp
YnV0ZXNDb25maWdgCgoNCgUECgIABRIEowMCCAoNCgUECgIAARIEowMJGgoNCgUECgIAAxIE
owMdHgoPCgUECgIACBIGowMfqAMDChAKCAQKAgAInAgAEgSkAwQqChEKBwQKAgAInwgSBqUD
BKcDBQpkCgQECgIBEgasAwKtAy8aVCBSZXF1aXJlZC4gVGhlIFtDYXRhbG9nQXR0cmlidXRl
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFsb2dBdHRyaWJ1dGVdCiB0byBhZGQuCgoN
CgUECgIBBhIErAMCEgoNCgUECgIBARIErAMTJAoNCgUECgIBAxIErAMnKAoNCgUECgIBCBIE
rQMGLgoQCggECgIBCJwIABIErQMHLQqLAQoCBAsSBrMDAMADARp9IFJlcXVlc3QgZm9yCiBb
Q2F0YWxvZ1NlcnZpY2UuUmVtb3ZlQ2F0YWxvZ0F0dHJpYnV0ZV1bZ29vZ2xlLmNsb3VkLnJl
dGFpbC52Mi5DYXRhbG9nU2VydmljZS5SZW1vdmVDYXRhbG9nQXR0cmlidXRlXQogbWV0aG9k
LgoKCwoDBAsBEgSzAwglCqUBCgQECwIAEga2AwK7AwQalAEgUmVxdWlyZWQuIEZ1bGwgQXR0
cmlidXRlc0NvbmZpZyByZXNvdXJjZSBuYW1lLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2pl
Y3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19p
ZH0vYXR0cmlidXRlc0NvbmZpZ2AKCg0KBQQLAgAFEgS2AwIICg0KBQQLAgABEgS2AwkaCg0K
BQQLAgADEgS2Ax0eCg8KBQQLAgAIEga2Ax+7AwMKEAoIBAsCAAicCAASBLcDBCoKEQoHBAsC
AAifCBIGuAMEugMFCn8KBAQLAgESBL8DAjoacSBSZXF1aXJlZC4gVGhlIGF0dHJpYnV0ZSBu
YW1lIGtleSBvZiB0aGUKIFtDYXRhbG9nQXR0cmlidXRlXVtnb29nbGUuY2xvdWQucmV0YWls
LnYyLkNhdGFsb2dBdHRyaWJ1dGVdIHRvIHJlbW92ZS4KCg0KBQQLAgEFEgS/AwIICg0KBQQL
AgEBEgS/AwkMCg0KBQQLAgEDEgS/Aw8QCg0KBQQLAgEIEgS/AxE5ChAKCAQLAgEInAgAEgS/
AxI4Co0BCgIEDBIGxQMA3AMBGn8gUmVxdWVzdCBmb3IKIFtDYXRhbG9nU2VydmljZS5SZXBs
YWNlQ2F0YWxvZ0F0dHJpYnV0ZV1bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5DYXRhbG9nU2Vy
dmljZS5SZXBsYWNlQ2F0YWxvZ0F0dHJpYnV0ZV0KIG1ldGhvZC4KCgsKAwQMARIExQMIJgql
AQoEBAwCABIGyAMCzQMEGpQBIFJlcXVpcmVkLiBGdWxsIEF0dHJpYnV0ZXNDb25maWcgcmVz
b3VyY2UgbmFtZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRp
b25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L2F0dHJpYnV0ZXNDb25m
aWdgCgoNCgUEDAIABRIEyAMCCAoNCgUEDAIAARIEyAMJGgoNCgUEDAIAAxIEyAMdHgoPCgUE
DAIACBIGyAMfzQMDChAKCAQMAgAInAgAEgTJAwQqChEKBwQMAgAInwgSBsoDBMwDBQplCgQE
DAIBEgbRAwLSAy8aVSBSZXF1aXJlZC4gVGhlIHVwZGF0ZWQKIFtDYXRhbG9nQXR0cmlidXRl
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLkNhdGFsb2dBdHRyaWJ1dGVdLgoKDQoFBAwCAQYS
BNEDAhIKDQoFBAwCAQESBNEDEyQKDQoFBAwCAQMSBNEDJygKDQoFBAwCAQgSBNIDBi4KEAoI
BAwCAQicCAASBNIDBy0KmQIKBAQMAgISBNsDAiwaigIgSW5kaWNhdGVzIHdoaWNoIGZpZWxk
cyBpbiB0aGUgcHJvdmlkZWQKIFtDYXRhbG9nQXR0cmlidXRlXVtnb29nbGUuY2xvdWQucmV0
YWlsLnYyLkNhdGFsb2dBdHRyaWJ1dGVdIHRvIHVwZGF0ZS4gVGhlCiBmb2xsb3dpbmcgYXJl
IE5PVCBzdXBwb3J0ZWQ6CgogKiBbQ2F0YWxvZ0F0dHJpYnV0ZS5rZXldW2dvb2dsZS5jbG91
ZC5yZXRhaWwudjIuQ2F0YWxvZ0F0dHJpYnV0ZS5rZXldCgogSWYgbm90IHNldCwgYWxsIHN1
cHBvcnRlZCBmaWVsZHMgYXJlIHVwZGF0ZWQuCgoNCgUEDAICBhIE2wMCGwoNCgUEDAICARIE
2wMcJwoNCgUEDAICAxIE2wMqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest ===
    # Fields for ListCatalogsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse ===
    # Fields for ListCatalogsResponse
    # Field: catalogs Type: 11 (.google.cloud.retail.v2.Catalog)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2::CatalogService::UpdateCatalogRequest ===
    # Fields for UpdateCatalogRequest
    # Field: catalog Type: 11 (.google.cloud.retail.v2.Catalog)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2::CatalogService::SetDefaultBranchRequest ===
    # Fields for SetDefaultBranchRequest
    # Field: catalog Type: 9 ()
    # Field: branch_id Type: 9 ()
    # Field: note Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Retail::V2::CatalogService::GetDefaultBranchRequest ===
    # Fields for GetDefaultBranchRequest
    # Field: catalog Type: 9 ()

# === Message: Google::Cloud::Retail::V2::CatalogService::GetDefaultBranchResponse ===
    # Fields for GetDefaultBranchResponse
    # Field: branch Type: 9 ()
    # Field: set_time Type: 11 (.google.protobuf.Timestamp)
    # Field: note Type: 9 ()

# === Message: Google::Cloud::Retail::V2::CatalogService::GetCompletionConfigRequest ===
    # Fields for GetCompletionConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::CatalogService::UpdateCompletionConfigRequest ===
    # Fields for UpdateCompletionConfigRequest
    # Field: completion_config Type: 11 (.google.cloud.retail.v2.CompletionConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2::CatalogService::GetAttributesConfigRequest ===
    # Fields for GetAttributesConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2::CatalogService::UpdateAttributesConfigRequest ===
    # Fields for UpdateAttributesConfigRequest
    # Field: attributes_config Type: 11 (.google.cloud.retail.v2.AttributesConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2::CatalogService::AddCatalogAttributeRequest ===
    # Fields for AddCatalogAttributeRequest
    # Field: attributes_config Type: 9 ()
    # Field: catalog_attribute Type: 11 (.google.cloud.retail.v2.CatalogAttribute)

# === Message: Google::Cloud::Retail::V2::CatalogService::RemoveCatalogAttributeRequest ===
    # Fields for RemoveCatalogAttributeRequest
    # Field: attributes_config Type: 9 ()
    # Field: key Type: 9 ()

# === Message: Google::Cloud::Retail::V2::CatalogService::ReplaceCatalogAttributeRequest ===
    # Fields for ReplaceCatalogAttributeRequest
    # Field: attributes_config Type: 9 ()
    # Field: catalog_attribute Type: 11 (.google.cloud.retail.v2.CatalogAttribute)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Retail::V2::CatalogService::CatalogServiceClient ===
package Google::Cloud::Retail::V2::CatalogService::CatalogServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::CatalogService::CatalogServiceClient

Client stub representing the remote C<CatalogService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_catalogs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'ListCatalogs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse',
    });
}

sub update_catalog {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::UpdateCatalogRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'UpdateCatalog',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Catalog::Catalog',
    });
}

sub set_default_branch {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::SetDefaultBranchRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'SetDefaultBranch',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_default_branch {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::GetDefaultBranchRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'GetDefaultBranch',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::CatalogService::GetDefaultBranchResponse',
    });
}

sub get_completion_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::GetCompletionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'GetCompletionConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Catalog::CompletionConfig',
    });
}

sub update_completion_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::UpdateCompletionConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'UpdateCompletionConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Catalog::CompletionConfig',
    });
}

sub get_attributes_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::GetAttributesConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'GetAttributesConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Catalog::AttributesConfig',
    });
}

sub update_attributes_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::UpdateAttributesConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'UpdateAttributesConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Catalog::AttributesConfig',
    });
}

sub add_catalog_attribute {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::AddCatalogAttributeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'AddCatalogAttribute',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Catalog::AttributesConfig',
    });
}

sub remove_catalog_attribute {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::RemoveCatalogAttributeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'RemoveCatalogAttribute',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Catalog::AttributesConfig',
    });
}

sub replace_catalog_attribute {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2::CatalogService::ReplaceCatalogAttributeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'ReplaceCatalogAttribute',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2::Catalog::AttributesConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::CatalogService - Compiled Protocol Buffers messages for google/cloud/retail/v2/catalog_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::CatalogService;

    my $msg = Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/catalog_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest

Request for
[CatalogService.ListCatalogs][google.cloud.retail.v2.CatalogService.ListCatalogs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The account resource name with an associated location.

If the caller does not have permission to list
[Catalog][google.cloud.retail.v2.Catalog]s under this location, regardless
of whether or not this location exists, a PERMISSION_DENIED error is
returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of [Catalog][google.cloud.retail.v2.Catalog]s to return. If
unspecified, defaults to 50. The maximum allowed value is 1000. Values
above 1000 will be coerced to 1000.

If this field is negative, an INVALID_ARGUMENT is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListCatalogsResponse.next_page_token][google.cloud.retail.v2.ListCatalogsResponse.next_page_token],
received from a previous
[CatalogService.ListCatalogs][google.cloud.retail.v2.CatalogService.ListCatalogs]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[CatalogService.ListCatalogs][google.cloud.retail.v2.CatalogService.ListCatalogs]
must match the call that provided the page token. Otherwise, an
INVALID_ARGUMENT error is returned.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse

Response for
[CatalogService.ListCatalogs][google.cloud.retail.v2.CatalogService.ListCatalogs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalogs() >> / C<< $msg->catalogs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Catalog::Catalog>)

All the customer's [Catalog][google.cloud.retail.v2.Catalog]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListCatalogsRequest.page_token][google.cloud.retail.v2.ListCatalogsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::UpdateCatalogRequest

Request for
[CatalogService.UpdateCatalog][google.cloud.retail.v2.CatalogService.UpdateCatalog]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Catalog::Catalog>)

Required. The [Catalog][google.cloud.retail.v2.Catalog] to update.

If the caller does not have permission to update the
[Catalog][google.cloud.retail.v2.Catalog], regardless of whether or not it
exists, a PERMISSION_DENIED error is returned.

If the [Catalog][google.cloud.retail.v2.Catalog] to update does not exist,
a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[Catalog][google.cloud.retail.v2.Catalog] to update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::SetDefaultBranchRequest

Request message to set a specified branch as new default_branch.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Full resource name of the catalog, such as
`projects/*/locations/global/catalogs/default_catalog`.

=item * C<< $msg->branch_id() >> / C<< $msg->branch_id($value) >>

Type: C<String>

The final component of the resource name of a branch.

This field must be one of "0", "1" or "2". Otherwise, an INVALID_ARGUMENT
error is returned.

If there are no sufficient active products in the targeted branch and
[force][google.cloud.retail.v2.SetDefaultBranchRequest.force] is not set, a
FAILED_PRECONDITION error is returned.

=item * C<< $msg->note() >> / C<< $msg->note($value) >>

Type: C<String>

Some note on this request, this can be retrieved by
[CatalogService.GetDefaultBranch][google.cloud.retail.v2.CatalogService.GetDefaultBranch]
before next valid default branch set occurs.

This field must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

If set to true, it permits switching to a branch with
[branch_id][google.cloud.retail.v2.SetDefaultBranchRequest.branch_id] even
if it has no sufficient active products.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::GetDefaultBranchRequest

Request message to show which branch is currently the default branch.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

The parent catalog resource name, such as
`projects/*/locations/global/catalogs/default_catalog`.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::GetDefaultBranchResponse

Response message of
[CatalogService.GetDefaultBranch][google.cloud.retail.v2.CatalogService.GetDefaultBranch].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->branch() >> / C<< $msg->branch($value) >>

Type: C<String>

Full resource name of the branch id currently set as default branch.

=item * C<< $msg->set_time() >> / C<< $msg->set_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when this branch is set to default.

=item * C<< $msg->note() >> / C<< $msg->note($value) >>

Type: C<String>

This corresponds to
[SetDefaultBranchRequest.note][google.cloud.retail.v2.SetDefaultBranchRequest.note]
field, when this branch was set as default.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::GetCompletionConfigRequest

Request for
[CatalogService.GetCompletionConfig][google.cloud.retail.v2.CatalogService.GetCompletionConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full CompletionConfig resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/completionConfig`

=back

=head2 Google::Cloud::Retail::V2::CatalogService::UpdateCompletionConfigRequest

Request for
[CatalogService.UpdateCompletionConfig][google.cloud.retail.v2.CatalogService.UpdateCompletionConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_config() >> / C<< $msg->completion_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Catalog::CompletionConfig>)

Required. The [CompletionConfig][google.cloud.retail.v2.CompletionConfig]
to update.

If the caller does not have permission to update the
[CompletionConfig][google.cloud.retail.v2.CompletionConfig], then a
PERMISSION_DENIED error is returned.

If the [CompletionConfig][google.cloud.retail.v2.CompletionConfig] to
update does not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[CompletionConfig][google.cloud.retail.v2.CompletionConfig] to update. The
following are the only supported fields:

* [CompletionConfig.matching_order][google.cloud.retail.v2.CompletionConfig.matching_order]
* [CompletionConfig.max_suggestions][google.cloud.retail.v2.CompletionConfig.max_suggestions]
* [CompletionConfig.min_prefix_length][google.cloud.retail.v2.CompletionConfig.min_prefix_length]
* [CompletionConfig.auto_learning][google.cloud.retail.v2.CompletionConfig.auto_learning]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::GetAttributesConfigRequest

Request for
[CatalogService.GetAttributesConfig][google.cloud.retail.v2.CatalogService.GetAttributesConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full AttributesConfig resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/attributesConfig`

=back

=head2 Google::Cloud::Retail::V2::CatalogService::UpdateAttributesConfigRequest

Request for
[CatalogService.UpdateAttributesConfig][google.cloud.retail.v2.CatalogService.UpdateAttributesConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attributes_config() >> / C<< $msg->attributes_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Catalog::AttributesConfig>)

Required. The [AttributesConfig][google.cloud.retail.v2.AttributesConfig]
to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[AttributesConfig][google.cloud.retail.v2.AttributesConfig] to update. The
following is the only supported field:

* [AttributesConfig.catalog_attributes][google.cloud.retail.v2.AttributesConfig.catalog_attributes]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::AddCatalogAttributeRequest

Request for
[CatalogService.AddCatalogAttribute][google.cloud.retail.v2.CatalogService.AddCatalogAttribute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attributes_config() >> / C<< $msg->attributes_config($value) >>

Type: C<String>

Required. Full AttributesConfig resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/attributesConfig`

=item * C<< $msg->catalog_attribute() >> / C<< $msg->catalog_attribute($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Catalog::CatalogAttribute>)

Required. The [CatalogAttribute][google.cloud.retail.v2.CatalogAttribute]
to add.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::RemoveCatalogAttributeRequest

Request for
[CatalogService.RemoveCatalogAttribute][google.cloud.retail.v2.CatalogService.RemoveCatalogAttribute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attributes_config() >> / C<< $msg->attributes_config($value) >>

Type: C<String>

Required. Full AttributesConfig resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/attributesConfig`

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Required. The attribute name key of the
[CatalogAttribute][google.cloud.retail.v2.CatalogAttribute] to remove.

=back

=head2 Google::Cloud::Retail::V2::CatalogService::ReplaceCatalogAttributeRequest

Request for
[CatalogService.ReplaceCatalogAttribute][google.cloud.retail.v2.CatalogService.ReplaceCatalogAttribute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attributes_config() >> / C<< $msg->attributes_config($value) >>

Type: C<String>

Required. Full AttributesConfig resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/attributesConfig`

=item * C<< $msg->catalog_attribute() >> / C<< $msg->catalog_attribute($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Catalog::CatalogAttribute>)

Required. The updated
[CatalogAttribute][google.cloud.retail.v2.CatalogAttribute].

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[CatalogAttribute][google.cloud.retail.v2.CatalogAttribute] to update. The
following are NOT supported:

* [CatalogAttribute.key][google.cloud.retail.v2.CatalogAttribute.key]

If not set, all supported fields are updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::CatalogService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
