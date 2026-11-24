package Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService;

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
    eval { require Google::Cloud::Managedidentities::V1beta1::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ckdnb29nbGUvY2xvdWQvbWFuYWdlZGlkZW50aXRpZXMvdjFiZXRhMS9tYW5hZ2VkX2lkZW50
aXRpZXNfc2VydmljZS5wcm90bxImZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYx
YmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50
LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jl
c291cmNlLnByb3RvGjVnb29nbGUvY2xvdWQvbWFuYWdlZGlkZW50aXRpZXMvdjFiZXRhMS9y
ZXNvdXJjZS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aIGdv
b2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvIqICCgpPcE1ldGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90aW1lGAIgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEhsKBnRhcmdldBgD
IAEoCUID4EEDUgZ0YXJnZXQSFwoEdmVyYhgEIAEoCUID4EEDUgR2ZXJiEjoKFnJlcXVlc3Rl
ZF9jYW5jZWxsYXRpb24YBSABKAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0aW9uEiQKC2Fw
aV92ZXJzaW9uGAYgASgJQgPgQQNSCmFwaVZlcnNpb24i3AEKHkNyZWF0ZU1pY3Jvc29mdEFk
RG9tYWluUmVxdWVzdBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKRInbWFuYWdlZGlkZW50aXRp
ZXMuZ29vZ2xlYXBpcy5jb20vRG9tYWluUgZwYXJlbnQSJAoLZG9tYWluX25hbWUYAiABKAlC
A+BBAlIKZG9tYWluTmFtZRJLCgZkb21haW4YAyABKAsyLi5nb29nbGUuY2xvdWQubWFuYWdl
ZGlkZW50aXRpZXMudjFiZXRhMS5Eb21haW5CA+BBAlIGZG9tYWluImAKGVJlc2V0QWRtaW5Q
YXNzd29yZFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidtYW5hZ2VkaWRlbnRpdGll
cy5nb29nbGVhcGlzLmNvbS9Eb21haW5SBG5hbWUiOAoaUmVzZXRBZG1pblBhc3N3b3JkUmVz
cG9uc2USGgoIcGFzc3dvcmQYASABKAlSCHBhc3N3b3JkIswBChJMaXN0RG9tYWluc1JlcXVl
c3QSRwoGcGFyZW50GAEgASgJQi/gQQL6QSkSJ21hbmFnZWRpZGVudGl0aWVzLmdvb2dsZWFw
aXMuY29tL0RvbWFpblIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoK
cGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEhYKBmZpbHRlchgEIAEoCVIGZmlsdGVyEhkK
CG9yZGVyX2J5GAUgASgJUgdvcmRlckJ5IqkBChNMaXN0RG9tYWluc1Jlc3BvbnNlEkgKB2Rv
bWFpbnMYASADKAsyLi5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjFiZXRhMS5E
b21haW5SB2RvbWFpbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
EiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJXChBHZXREb21haW5SZXF1ZXN0
EkMKBG5hbWUYASABKAlCL+BBAvpBKQonbWFuYWdlZGlkZW50aXRpZXMuZ29vZ2xlYXBpcy5j
b20vRG9tYWluUgRuYW1lIqQBChNVcGRhdGVEb21haW5SZXF1ZXN0EkAKC3VwZGF0ZV9tYXNr
GAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrEksK
BmRvbWFpbhgCIAEoCzIuLmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGEx
LkRvbWFpbkID4EECUgZkb21haW4iWgoTRGVsZXRlRG9tYWluUmVxdWVzdBJDCgRuYW1lGAEg
ASgJQi/gQQL6QSkKJ21hbmFnZWRpZGVudGl0aWVzLmdvb2dsZWFwaXMuY29tL0RvbWFpblIE
bmFtZSKjAQoSQXR0YWNoVHJ1c3RSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonbWFu
YWdlZGlkZW50aXRpZXMuZ29vZ2xlYXBpcy5jb20vRG9tYWluUgRuYW1lEkgKBXRydXN0GAIg
ASgLMi0uZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTEuVHJ1c3RCA+BB
AlIFdHJ1c3QizQEKF1JlY29uZmlndXJlVHJ1c3RSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BB
AvpBKQonbWFuYWdlZGlkZW50aXRpZXMuZ29vZ2xlYXBpcy5jb20vRG9tYWluUgRuYW1lEjEK
EnRhcmdldF9kb21haW5fbmFtZRgCIAEoCUID4EECUhB0YXJnZXREb21haW5OYW1lEjoKF3Rh
cmdldF9kbnNfaXBfYWRkcmVzc2VzGAMgAygJQgPgQQJSFHRhcmdldERuc0lwQWRkcmVzc2Vz
IqMBChJEZXRhY2hUcnVzdFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidtYW5hZ2Vk
aWRlbnRpdGllcy5nb29nbGVhcGlzLmNvbS9Eb21haW5SBG5hbWUSSAoFdHJ1c3QYAiABKAsy
LS5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjFiZXRhMS5UcnVzdEID4EECUgV0
cnVzdCKlAQoUVmFsaWRhdGVUcnVzdFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidt
YW5hZ2VkaWRlbnRpdGllcy5nb29nbGVhcGlzLmNvbS9Eb21haW5SBG5hbWUSSAoFdHJ1c3QY
AiABKAsyLS5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjFiZXRhMS5UcnVzdEID
4EECUgV0cnVzdDLlEgoYTWFuYWdlZElkZW50aXRpZXNTZXJ2aWNlEvoBChdDcmVhdGVNaWNy
b3NvZnRBZERvbWFpbhJGLmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGEx
LkNyZWF0ZU1pY3Jvc29mdEFkRG9tYWluUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5P
cGVyYXRpb24ieILT5JMCPyI1L3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9u
cy9nbG9iYWx9L2RvbWFpbnM6BmRvbWFpbtpBGXBhcmVudCxkb21haW5fbmFtZSxkb21haW7K
QRQKBkRvbWFpbhIKT3BNZXRhZGF0YRL3AQoSUmVzZXRBZG1pblBhc3N3b3JkEkEuZ29vZ2xl
LmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTEuUmVzZXRBZG1pblBhc3N3b3JkUmVx
dWVzdBpCLmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLlJlc2V0QWRt
aW5QYXNzd29yZFJlc3BvbnNlIlqC0+STAk0iSC92MWJldGExL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zL2dsb2JhbC9kb21haW5zLyp9OnJlc2V0QWRtaW5QYXNzd29yZDoBKtpBBG5h
bWUSzgEKC0xpc3REb21haW5zEjouZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYx
YmV0YTEuTGlzdERvbWFpbnNSZXF1ZXN0GjsuZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0
aWVzLnYxYmV0YTEuTGlzdERvbWFpbnNSZXNwb25zZSJGgtPkkwI3EjUvdjFiZXRhMS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbH0vZG9tYWluc9pBBnBhcmVudBK7AQoJ
R2V0RG9tYWluEjguZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTEuR2V0
RG9tYWluUmVxdWVzdBouLmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGEx
LkRvbWFpbiJEgtPkkwI3EjUvdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy9n
bG9iYWwvZG9tYWlucy8qfdpBBG5hbWUS5AEKDFVwZGF0ZURvbWFpbhI7Lmdvb2dsZS5jbG91
ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLlVwZGF0ZURvbWFpblJlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIniC0+STAkYyPC92MWJldGExL3tkb21haW4ubmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvZG9tYWlucy8qfToGZG9tYWlu2kESZG9t
YWluLHVwZGF0ZV9tYXNrykEUCgZEb21haW4SCk9wTWV0YWRhdGES1gEKDERlbGV0ZURvbWFp
bhI7Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLkRlbGV0ZURvbWFp
blJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uImqC0+STAjcqNS92MWJl
dGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9kb21haW5zLyp92kEEbmFt
ZcpBIwoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EgpPcE1ldGFkYXRhEtoBCgtBdHRhY2hUcnVz
dBI6Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLkF0dGFjaFRydXN0
UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24icILT5JMCRiJBL3YxYmV0
YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2RvbWFpbnMvKn06YXR0YWNo
VHJ1c3Q6ASraQQpuYW1lLHRydXN0ykEUCgZEb21haW4SCk9wTWV0YWRhdGESjwIKEFJlY29u
ZmlndXJlVHJ1c3QSPy5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjFiZXRhMS5S
ZWNvbmZpZ3VyZVRydXN0UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i
mgGC0+STAksiRi92MWJldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9k
b21haW5zLyp9OnJlY29uZmlndXJlVHJ1c3Q6ASraQS9uYW1lLHRhcmdldF9kb21haW5fbmFt
ZSx0YXJnZXRfZG5zX2lwX2FkZHJlc3Nlc8pBFAoGRG9tYWluEgpPcE1ldGFkYXRhEtoBCgtE
ZXRhY2hUcnVzdBI6Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLkRl
dGFjaFRydXN0UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24icILT5JMC
RiJBL3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2RvbWFpbnMv
Kn06ZGV0YWNoVHJ1c3Q6ASraQQpuYW1lLHRydXN0ykEUCgZEb21haW4SCk9wTWV0YWRhdGES
4AEKDVZhbGlkYXRlVHJ1c3QSPC5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjFi
ZXRhMS5WYWxpZGF0ZVRydXN0UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24icoLT5JMCSCJDL3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFs
L2RvbWFpbnMvKn06dmFsaWRhdGVUcnVzdDoBKtpBCm5hbWUsdHJ1c3TKQRQKBkRvbWFpbhIK
T3BNZXRhZGF0YRpUykEgbWFuYWdlZGlkZW50aXRpZXMuZ29vZ2xlYXBpcy5jb23SQS5odHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQqwCCipjb20uZ29v
Z2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTFCHU1hbmFnZWRJZGVudGl0aWVz
U2VydmljZVByb3RvUAFaWGNsb3VkLmdvb2dsZS5jb20vZ28vbWFuYWdlZGlkZW50aXRpZXMv
YXBpdjFiZXRhMS9tYW5hZ2VkaWRlbnRpdGllc3BiO21hbmFnZWRpZGVudGl0aWVzcGKiAgRH
Q01JqgImR29vZ2xlLkNsb3VkLk1hbmFnZWRJZGVudGl0aWVzLlYxQmV0YTHKAiZHb29nbGVc
Q2xvdWRcTWFuYWdlZElkZW50aXRpZXNcVjFiZXRhMeoCKUdvb2dsZTo6Q2xvdWQ6Ok1hbmFn
ZWRJZGVudGl0aWVzOjpWMWJldGExSrpZCgcSBQ4AhAMBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAvCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhID
FAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPwoJCgIDBRIDFwAtCgkKAgMGEgMYACoKCQoCAwcS
AxkAKQoICgEIEgMbAEMKCQoCCCUSAxsAQwoICgEIEgMcAG8KCQoCCAsSAxwAbwoICgEIEgMd
ACIKCQoCCAoSAx0AIgoICgEIEgMeAD4KCQoCCAgSAx4APgoICgEIEgMfAEMKCQoCCAESAx8A
QwoICgEIEgMgACIKCQoCCCQSAyAAIgoICgEIEgMhAEMKCQoCCCkSAyEAQwoICgEIEgMiAEIK
CQoCCC0SAyIAQgoLCgIGABIFJACbAQEKCgoDBgABEgMkCCAKCgoDBgADEgMlAkgKDAoFBgAD
mQgSAyUCSAoKCgMGAAMSAyYCVgoMCgUGAAOaCBIDJgJWCi4KBAYAAgASBCkCMwMaICBDcmVh
dGVzIGEgTWljcm9zb2Z0IEFEIGRvbWFpbi4KCgwKBQYAAgABEgMpBh0KDAoFBgACAAISAyke
PAoMCgUGAAIAAxIDKUdjCg0KBQYAAgAEEgQqBC0GChEKCQYAAgAEsMq8IhIEKgQtBgoMCgUG
AAIABBIDLgRHCg8KCAYAAgAEmwgAEgMuBEcKDQoFBgACAAQSBC8EMgYKDwoHBgACAASZCBIE
LwQyBgo5CgQGAAIBEgQ2AjwDGisgUmVzZXRzIGEgZG9tYWluJ3MgYWRtaW5pc3RyYXRvciBw
YXNzd29yZC4KCgwKBQYAAgEBEgM2BhgKDAoFBgACAQISAzYZMgoMCgUGAAIBAxIDNj1XCg0K
BQYAAgEEEgQ3BDoGChEKCQYAAgEEsMq8IhIENwQ6BgoMCgUGAAIBBBIDOwQyCg8KCAYAAgEE
mwgAEgM7BDIKKwoEBgACAhIEPwJEAxodIExpc3RzIGRvbWFpbnMgaW4gYSBwcm9qZWN0LgoK
DAoFBgACAgESAz8GEQoMCgUGAAICAhIDPxIkCgwKBQYAAgIDEgM/L0IKDQoFBgACAgQSBEAE
QgYKEQoJBgACAgSwyrwiEgRABEIGCgwKBQYAAgIEEgNDBDQKDwoIBgACAgSbCAASA0MENAow
CgQGAAIDEgRHAkwDGiIgR2V0cyBpbmZvcm1hdGlvbiBhYm91dCBhIGRvbWFpbi4KCgwKBQYA
AgMBEgNHBg8KDAoFBgACAwISA0cQIAoMCgUGAAIDAxIDRysxCg0KBQYAAgMEEgRIBEoGChEK
CQYAAgMEsMq8IhIESARKBgoMCgUGAAIDBBIDSwQyCg8KCAYAAgMEmwgAEgNLBDIKQwoEBgAC
BBIETwJZAxo1IFVwZGF0ZXMgdGhlIG1ldGFkYXRhIGFuZCBjb25maWd1cmF0aW9uIG9mIGEg
ZG9tYWluLgoKDAoFBgACBAESA08GEgoMCgUGAAIEAhIDTxMmCgwKBQYAAgQDEgNPMU0KDQoF
BgACBAQSBFAEUwYKEQoJBgACBASwyrwiEgRQBFMGCgwKBQYAAgQEEgNUBEAKDwoIBgACBASb
CAASA1QEQAoNCgUGAAIEBBIEVQRYBgoPCgcGAAIEBJkIEgRVBFgGCiEKBAYAAgUSBFwCZQMa
EyBEZWxldGVzIGEgZG9tYWluLgoKDAoFBgACBQESA1wGEgoMCgUGAAIFAhIDXBMmCgwKBQYA
AgUDEgNcMU0KDQoFBgACBQQSBF0EXwYKEQoJBgACBQSwyrwiEgRdBF8GCgwKBQYAAgUEEgNg
BDIKDwoIBgACBQSbCAASA2AEMgoNCgUGAAIFBBIEYQRkBgoPCgcGAAIFBJkIEgRhBGQGCi0K
BAYAAgYSBGgCcgMaHyBBZGRzIGFuIEFEIHRydXN0IHRvIGEgZG9tYWluLgoKDAoFBgACBgES
A2gGEQoMCgUGAAIGAhIDaBIkCgwKBQYAAgYDEgNoL0sKDQoFBgACBgQSBGkEbAYKEQoJBgAC
BgSwyrwiEgRpBGwGCgwKBQYAAgYEEgNtBDgKDwoIBgACBgSbCAASA20EOAoNCgUGAAIGBBIE
bgRxBgoPCgcGAAIGBJkIEgRuBHEGCjYKBAYAAgcSBHUCfwMaKCBVcGRhdGVzIHRoZSBETlMg
Y29uZGl0aW9uYWwgZm9yd2FyZGVyLgoKDAoFBgACBwESA3UGFgoMCgUGAAIHAhIDdRcuCgwK
BQYAAgcDEgN1OVUKDQoFBgACBwQSBHYEeQYKEQoJBgACBwSwyrwiEgR2BHkGCgwKBQYAAgcE
EgN6BF0KDwoIBgACBwSbCAASA3oEXQoNCgUGAAIHBBIEewR+BgoPCgcGAAIHBJkIEgR7BH4G
CiYKBAYAAggSBoIBAowBAxoWIFJlbW92ZXMgYW4gQUQgdHJ1c3QuCgoNCgUGAAIIARIEggEG
EQoNCgUGAAIIAhIEggESJAoNCgUGAAIIAxIEggEvSwoPCgUGAAIIBBIGgwEEhgEGChMKCQYA
AggEsMq8IhIGgwEEhgEGCg0KBQYAAggEEgSHAQQ4ChAKCAYAAggEmwgAEgSHAQQ4Cg8KBQYA
AggEEgaIAQSLAQYKEQoHBgACCASZCBIGiAEEiwEGCpcBCgQGAAIJEgaQAQKaAQMahgEgVmFs
aWRhdGVzIGEgdHJ1c3Qgc3RhdGUsIHRoYXQgdGhlIHRhcmdldCBkb21haW4gaXMgcmVhY2hh
YmxlLCBhbmQgdGhhdCB0aGUKIHRhcmdldCBkb21haW4gaXMgYWJsZSB0byBhY2NlcHQgaW5j
b21pbmcgdHJ1c3QgcmVxdWVzdHMuCgoNCgUGAAIJARIEkAEGEwoNCgUGAAIJAhIEkAEUKAoN
CgUGAAIJAxIEkAEzTwoPCgUGAAIJBBIGkQEElAEGChMKCQYAAgkEsMq8IhIGkQEElAEGCg0K
BQYAAgkEEgSVAQQ4ChAKCAYAAgkEmwgAEgSVAQQ4Cg8KBQYAAgkEEgaWAQSZAQYKEQoHBgAC
CQSZCBIGlgEEmQEGCkYKAgQAEgaeAQCzAQEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBv
ZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgsKAwQAARIEngEIEgpACgQEAAIAEgSg
AQJYGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQu
CgoNCgUEAAIABhIEoAECGwoNCgUEAAIAARIEoAEcJwoNCgUEAAIAAxIEoAEqKwoNCgUEAAIA
CBIEoAEsVwoQCggEAAIACJwIABIEoAEtVgpFCgQEAAIBEgSjAQJVGjcgT3V0cHV0IG9ubHku
IFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCg0KBQQAAgEGEgSj
AQIbCg0KBQQAAgEBEgSjARwkCg0KBQQAAgEDEgSjAScoCg0KBQQAAgEIEgSjASlUChAKCAQA
AgEInAgAEgSjASpTCloKBAQAAgISBKYBAkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRlZmlu
ZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoKDQoF
BAACAgUSBKYBAggKDQoFBAACAgESBKYBCQ8KDQoFBAACAgMSBKYBEhMKDQoFBAACAggSBKYB
FD8KEAoIBAACAgicCAASBKYBFT4KSAoEBAACAxIEqQECPho6IE91dHB1dCBvbmx5LiBOYW1l
IG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoNCgUEAAIDBRIEqQEC
CAoNCgUEAAIDARIEqQEJDQoNCgUEAAIDAxIEqQEQEQoNCgUEAAIDCBIEqQESPQoQCggEAAID
CJwIABIEqQETPAqaAgoEBAACBBIErwECThqLAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3
aGV0aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3Bl
cmF0aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBzdWNjZXNzZnVsbHkgYmVlbiBjYW5jZWxs
ZWQKIGhhdmUgW09wZXJhdGlvbi5lcnJvcl1bXSB2YWx1ZSB3aXRoIGEgW2dvb2dsZS5ycGMu
U3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsCiBjb3JyZXNwb25k
aW5nIHRvIGBDb2RlLkNBTkNFTExFRGAuCgoNCgUEAAIEBRIErwECBgoNCgUEAAIEARIErwEH
HQoNCgUEAAIEAxIErwEgIQoNCgUEAAIECBIErwEiTQoQCggEAAIECJwIABIErwEjTApFCgQE
AAIFEgSyAQJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhl
IG9wZXJhdGlvbi4KCg0KBQQAAgUFEgSyAQIICg0KBQQAAgUBEgSyAQkUCg0KBQQAAgUDEgSy
ARcYCg0KBQQAAgUIEgSyARlEChAKCAQAAgUInAgAEgSyARpDCn4KAgQBEga3AQDPAQEacCBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ3JlYXRlTWljcm9zb2Z0QWREb21haW5dW2dvb2dsZS5j
bG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLkNyZWF0ZU1pY3Jvc29mdEFkRG9tYWlu
XQoKCwoDBAEBEgS3AQgmCnwKBAQBAgASBroBAr8BBBpsIFJlcXVpcmVkLiBUaGUgcmVzb3Vy
Y2UgcHJvamVjdCBuYW1lIGFuZCBsb2NhdGlvbiB1c2luZyB0aGUgZm9ybToKIGBwcm9qZWN0
cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2JhbGAKCg0KBQQBAgAFEgS6AQIICg0KBQQB
AgABEgS6AQkPCg0KBQQBAgADEgS6ARITCg8KBQQBAgAIEga6ARS/AQMKEAoIBAECAAicCAAS
BLsBBCoKEQoHBAECAAifCBIGvAEEvgEFCu4DCgQEAQIBEgTLAQJCGt8DIFJlcXVpcmVkLiBB
IGRvbWFpbiBuYW1lLCBlLmcuIG15ZG9tYWluLm15b3JnLmNvbSwgd2l0aCB0aGUgZm9sbG93
aW5nIHJlc3RyaWN0aW9uczoKICAqIE11c3QgY29udGFpbiBvbmx5IGxvd2VyY2FzZSBsZXR0
ZXJzLCBudW1iZXJzLCBwZXJpb2RzIGFuZCBoeXBoZW5zLgogICogTXVzdCBzdGFydCB3aXRo
IGEgbGV0dGVyLgogICogTXVzdCBjb250YWluIGJldHdlZW4gMi02NCBjaGFyYWN0ZXJzLgog
ICogTXVzdCBlbmQgd2l0aCBhIG51bWJlciBvciBhIGxldHRlci4KICAqIE11c3Qgbm90IHN0
YXJ0IHdpdGggcGVyaW9kLgogICogRmlyc3Qgc2VnbWVudCBsZW5ndGggKG15ZG9tYWluIGZv
cm0gZXhhbXBsZSBhYm92ZSkgc2hvdWxkbid0IGV4Y2VlZAogICAgMTUgY2hhcnMuCiAgKiBU
aGUgbGFzdCBzZWdtZW50IGNhbm5vdCBiZSBmdWxseSBudW1lcmljLgogICogTXVzdCBiZSB1
bmlxdWUgd2l0aGluIHRoZSBjdXN0b21lciBwcm9qZWN0LgoKDQoFBAECAQUSBMsBAggKDQoF
BAECAQESBMsBCRQKDQoFBAECAQMSBMsBFxgKDQoFBAECAQgSBMsBGUEKEAoIBAECAQicCAAS
BMsBGkAKPQoEBAECAhIEzgECPRovIFJlcXVpcmVkLiBBIE1hbmFnZWQgSWRlbnRpdHkgZG9t
YWluIHJlc291cmNlLgoKDQoFBAECAgYSBM4BAggKDQoFBAECAgESBM4BCQ8KDQoFBAECAgMS
BM4BEhMKDQoFBAECAggSBM4BFDwKEAoIBAECAgicCAASBM4BFTsKdAoCBAISBtMBANwBARpm
IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtSZXNldEFkbWluUGFzc3dvcmRdW2dvb2dsZS5jbG91
ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLlJlc2V0QWRtaW5QYXNzd29yZF0KCgsKAwQC
ARIE0wEIIQqEAQoEBAICABIG1gEC2wEEGnQgUmVxdWlyZWQuIFRoZSBkb21haW4gcmVzb3Vy
Y2UgbmFtZSB1c2luZyB0aGUgZm9ybToKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRp
b25zL2dsb2JhbC9kb21haW5zL3tkb21haW5fbmFtZX1gCgoNCgUEAgIABRIE1gECCAoNCgUE
AgIAARIE1gEJDQoNCgUEAgIAAxIE1gEQEQoPCgUEAgIACBIG1gES2wEDChAKCAQCAgAInAgA
EgTXAQQqChEKBwQCAgAInwgSBtgBBNoBBQp1CgIEAxIG4AEA4wEBGmcgUmVzcG9uc2UgbWVz
c2FnZSBmb3IKIFtSZXNldEFkbWluUGFzc3dvcmRdW2dvb2dsZS5jbG91ZC5tYW5hZ2VkaWRl
bnRpdGllcy52MWJldGExLlJlc2V0QWRtaW5QYXNzd29yZF0KCgsKAwQDARIE4AEIIgp5CgQE
AwIAEgTiAQIWGmsgQSByYW5kb20gcGFzc3dvcmQuIFNlZSBbYWRtaW5dW2dvb2dsZS5jbG91
ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLkRvbWFpbi5hZG1pbl0gZm9yIG1vcmUgaW5m
b3JtYXRpb24uCgoNCgUEAwIABRIE4gECCAoNCgUEAwIAARIE4gEJEQoNCgUEAwIAAxIE4gEU
FQpmCgIEBBIG5wEAhgIBGlggUmVxdWVzdCBtZXNzYWdlIGZvcgogW0xpc3REb21haW5zXVtn
b29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjFiZXRhMS5MaXN0RG9tYWluc10KCgsK
AwQEARIE5wEIGgp+CgQEBAIAEgbqAQLvAQQabiBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIGRvbWFpbiBsb2NhdGlvbiB1c2luZyB0aGUgZm9ybToKIGBwcm9qZWN0cy97
cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2JhbGAKCg0KBQQEAgAFEgTqAQIICg0KBQQEAgAB
EgTqAQkPCg0KBQQEAgADEgTqARITCg8KBQQEAgAIEgbqARTvAQMKEAoIBAQCAAicCAASBOsB
BCoKEQoHBAQCAAifCBIG7AEE7gEFCoIDCgQEBAIBEgT3AQIWGvMCIE9wdGlvbmFsLiBUaGUg
bWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuLgogSWYgbm90IHNwZWNpZmllZCwg
YSBkZWZhdWx0IHZhbHVlIG9mIDEwMDAgd2lsbCBiZSB1c2VkLgogUmVnYXJkbGVzcyBvZiB0
aGUgcGFnZV9zaXplIHZhbHVlLCB0aGUgcmVzcG9uc2UgbWF5IGluY2x1ZGUgYSBwYXJ0aWFs
IGxpc3QuCiBDYWxsZXJzIHNob3VsZCByZWx5IG9uIGEgcmVzcG9uc2UncwogW25leHRfcGFn
ZV90b2tlbl1bZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTEuTGlzdERv
bWFpbnNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dCiB0byBkZXRlcm1pbmUgaWYgdGhlcmUg
YXJlIGFkZGl0aW9uYWwgcmVzdWx0cyB0byBsaXN0LgoKDQoFBAQCAQUSBPcBAgcKDQoFBAQC
AQESBPcBCBEKDQoFBAQCAQMSBPcBFBUKaQoEBAQCAhIE+wECGBpbIFRoZSBgbmV4dF9wYWdl
X3Rva2VuYCB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgTGlzdERvbWFpbnNSZXF1
ZXN0CiByZXF1ZXN0LCBpZiBhbnkuCgoNCgUEBAICBRIE+wECCAoNCgUEBAICARIE+wEJEwoN
CgUEBAICAxIE+wEWFwqFAQoEBAQCAxIE/wECFBp3IE9wdGlvbmFsLiBBIGZpbHRlciBzcGVj
aWZ5aW5nIGNvbnN0cmFpbnRzIG9mIGEgbGlzdCBvcGVyYXRpb24uCiBGb3IgZXhhbXBsZSwg
YERvbWFpbi5mcWRuPSJteWRvbWFpbi5teW9yZ2luaXphdGlvbiJgLgoKDQoFBAQCAwUSBP8B
AggKDQoFBAQCAwESBP8BCQ8KDQoFBAQCAwMSBP8BEhMKrgEKBAQEAgQSBIUCAhYanwEgT3B0
aW9uYWwuIFNwZWNpZmllcyB0aGUgb3JkZXJpbmcgb2YgcmVzdWx0cy4gU2VlCiBbU29ydGlu
Zwogb3JkZXJdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rlc2lnbi9kZXNpZ25f
cGF0dGVybnMjc29ydGluZ19vcmRlcikKIGZvciBtb3JlIGluZm9ybWF0aW9uLgoKDQoFBAQC
BAUSBIUCAggKDQoFBAQCBAESBIUCCREKDQoFBAQCBAMSBIUCFBUKZwoCBAUSBooCAJQCARpZ
IFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbTGlzdERvbWFpbnNdW2dvb2dsZS5jbG91ZC5tYW5h
Z2VkaWRlbnRpdGllcy52MWJldGExLkxpc3REb21haW5zXQoKCwoDBAUBEgSKAggbCkwKBAQF
AgASBIwCAh4aPiBBIGxpc3Qgb2YgTWFuYWdlZCBJZGVudGl0aWVzIFNlcnZpY2UgZG9tYWlu
cyBpbiB0aGUgcHJvamVjdC4KCg0KBQQFAgAEEgSMAgIKCg0KBQQFAgAGEgSMAgsRCg0KBQQF
AgABEgSMAhIZCg0KBQQFAgADEgSMAhwdCnEKBAQFAgESBJACAh0aYyBBIHRva2VuIHRvIHJl
dHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJl
IG5vIG1vcmUKIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEBQIBBRIEkAICCAoNCgUEBQIB
ARIEkAIJGAoNCgUEBQIBAxIEkAIbHAo+CgQEBQICEgSTAgIiGjAgQSBsaXN0IG9mIGxvY2F0
aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDQoFBAUCAgQSBJMCAgoKDQoFBAUC
AgUSBJMCCxEKDQoFBAUCAgESBJMCEh0KDQoFBAUCAgMSBJMCICEKYgoCBAYSBpgCAKECARpU
IFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtHZXREb21haW5dW2dvb2dsZS5jbG91ZC5tYW5hZ2Vk
aWRlbnRpdGllcy52MWJldGExLkdldERvbWFpbl0KCgsKAwQGARIEmAIIGAqEAQoEBAYCABIG
mwICoAIEGnQgUmVxdWlyZWQuIFRoZSBkb21haW4gcmVzb3VyY2UgbmFtZSB1c2luZyB0aGUg
Zm9ybToKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2JhbC9kb21haW5z
L3tkb21haW5fbmFtZX1gCgoNCgUEBgIABRIEmwICCAoNCgUEBgIAARIEmwIJDQoNCgUEBgIA
AxIEmwIQEQoPCgUEBgIACBIGmwISoAIDChAKCAQGAgAInAgAEgScAgQqChEKBwQGAgAInwgS
Bp0CBJ8CBQpoCgIEBxIGpQIAsgIBGlogUmVxdWVzdCBtZXNzYWdlIGZvcgogW1VwZGF0ZURv
bWFpbl1bZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTEuVXBkYXRlRG9t
YWluXQoKCwoDBAcBEgSlAggbCrcCCgQEBwIAEgStAgJVGqgCIFJlcXVpcmVkLiBNYXNrIG9m
IGZpZWxkcyB0byB1cGRhdGUuIEF0IGxlYXN0IG9uZSBwYXRoIG11c3QgYmUgc3VwcGxpZWQg
aW4gdGhpcwogZmllbGQuIFRoZSBlbGVtZW50cyBvZiB0aGUgcmVwZWF0ZWQgcGF0aHMgZmll
bGQgbWF5IG9ubHkgaW5jbHVkZQogZmllbGRzIGZyb20gW0RvbWFpbl1bZ29vZ2xlLmNsb3Vk
Lm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTEuRG9tYWluXToKICAqIGBsYWJlbHNgCiAgKiBg
bG9jYXRpb25zYAogICogYGF1dGhvcml6ZWRfbmV0d29ya3NgCiAgKiBgYXVkaXRfbG9nc19l
bmFibGVkYAoKDQoFBAcCAAYSBK0CAhsKDQoFBAcCAAESBK0CHCcKDQoFBAcCAAMSBK0CKisK
DQoFBAcCAAgSBK0CLFQKEAoIBAcCAAicCAASBK0CLVMKegoEBAcCARIEsQICPRpsIFJlcXVp
cmVkLiBEb21haW4gbWVzc2FnZSB3aXRoIHVwZGF0ZWQgZmllbGRzLiBPbmx5IHN1cHBvcnRl
ZCBmaWVsZHMgc3BlY2lmaWVkIGluCiB1cGRhdGVfbWFzayBhcmUgdXBkYXRlZC4KCg0KBQQH
AgEGEgSxAgIICg0KBQQHAgEBEgSxAgkPCg0KBQQHAgEDEgSxAhITCg0KBQQHAgEIEgSxAhQ8
ChAKCAQHAgEInAgAEgSxAhU7CmgKAgQIEga2AgC/AgEaWiBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbRGVsZXRlRG9tYWluXVtnb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjFiZXRh
MS5EZWxldGVEb21haW5dCgoLCgMECAESBLYCCBsKhAEKBAQIAgASBrkCAr4CBBp0IFJlcXVp
cmVkLiBUaGUgZG9tYWluIHJlc291cmNlIG5hbWUgdXNpbmcgdGhlIGZvcm06CiBgcHJvamVj
dHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwvZG9tYWlucy97ZG9tYWluX25hbWV9
YAoKDQoFBAgCAAUSBLkCAggKDQoFBAgCAAESBLkCCQ0KDQoFBAgCAAMSBLkCEBEKDwoFBAgC
AAgSBrkCEr4CAwoQCggECAIACJwIABIEugIEKgoRCgcECAIACJ8IEga7AgS9AgUKZgoCBAkS
BsMCAM8CARpYIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtBdHRhY2hUcnVzdF1bZ29vZ2xlLmNs
b3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTEuQXR0YWNoVHJ1c3RdCgoLCgMECQESBMMC
CBoKoAEKBAQJAgASBsYCAssCBBqPASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGRvbWFpbiBu
YW1lLCBwcm9qZWN0IG5hbWUgYW5kIGxvY2F0aW9uIHVzaW5nIHRoZSBmb3JtOgogYHByb2pl
Y3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsL2RvbWFpbnMve2RvbWFpbl9uYW1l
fWAKCg0KBQQJAgAFEgTGAgIICg0KBQQJAgABEgTGAgkNCg0KBQQJAgADEgTGAhARCg8KBQQJ
AgAIEgbGAhLLAgMKEAoIBAkCAAicCAASBMcCBCoKEQoHBAkCAAifCBIGyAIEygIFCjQKBAQJ
AgESBM4CAjsaJiBSZXF1aXJlZC4gVGhlIGRvbWFpbiB0cnVzdCByZXNvdXJjZS4KCg0KBQQJ
AgEGEgTOAgIHCg0KBQQJAgEBEgTOAggNCg0KBQQJAgEDEgTOAhARCg0KBQQJAgEIEgTOAhI6
ChAKCAQJAgEInAgAEgTOAhM5CnAKAgQKEgbTAgDkAgEaYiBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbUmVjb25maWd1cmVUcnVzdF1bZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYx
YmV0YTEuUmVjb25maWd1cmVUcnVzdF0KCgsKAwQKARIE0wIIHwqgAQoEBAoCABIG1gIC2wIE
Go8BIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgZG9tYWluIG5hbWUsIHByb2plY3QgbmFtZSBh
bmQgbG9jYXRpb24gdXNpbmcgdGhlIGZvcm06CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xv
Y2F0aW9ucy9nbG9iYWwvZG9tYWlucy97ZG9tYWluX25hbWV9YAoKDQoFBAoCAAUSBNYCAggK
DQoFBAoCAAESBNYCCQ0KDQoFBAoCAAMSBNYCEBEKDwoFBAoCAAgSBtYCEtsCAwoQCggECgIA
CJwIABIE1wIEKgoRCgcECgIACJ8IEgbYAgTaAgUKbQoEBAoCARIE3wICSRpfIFJlcXVpcmVk
LiBUaGUgZnVsbHktcXVhbGlmaWVkIHRhcmdldCBkb21haW4gbmFtZSB3aGljaCB3aWxsIGJl
IGluIHRydXN0IHdpdGggY3VycmVudAogZG9tYWluLgoKDQoFBAoCAQUSBN8CAggKDQoFBAoC
AQESBN8CCRsKDQoFBAoCAQMSBN8CHh8KDQoFBAoCAQgSBN8CIEgKEAoIBAoCAQicCAASBN8C
IUcKcQoEBAoCAhIE4wICVxpjIFJlcXVpcmVkLiBUaGUgdGFyZ2V0IEROUyBzZXJ2ZXIgSVAg
YWRkcmVzc2VzIHRvIHJlc29sdmUgdGhlIHJlbW90ZSBkb21haW4gaW52b2x2ZWQKIGluIHRo
ZSB0cnVzdC4KCg0KBQQKAgIEEgTjAgIKCg0KBQQKAgIFEgTjAgsRCg0KBQQKAgIBEgTjAhIp
Cg0KBQQKAgIDEgTjAiwtCg0KBQQKAgIIEgTjAi5WChAKCAQKAgIInAgAEgTjAi9VCmYKAgQL
EgboAgD0AgEaWCBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGV0YWNoVHJ1c3RdW2dvb2dsZS5j
bG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MWJldGExLkRldGFjaFRydXN0XQoKCwoDBAsBEgTo
AggaCqEBCgQECwIAEgbrAgLwAgQakAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBkb21haW4g
bmFtZSwgcHJvamVjdCBuYW1lLCBhbmQgbG9jYXRpb24gdXNpbmcgdGhlIGZvcm06CiBgcHJv
amVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwvZG9tYWlucy97ZG9tYWluX25h
bWV9YAoKDQoFBAsCAAUSBOsCAggKDQoFBAsCAAESBOsCCQ0KDQoFBAsCAAMSBOsCEBEKDwoF
BAsCAAgSBusCEvACAwoQCggECwIACJwIABIE7AIEKgoRCgcECwIACJ8IEgbtAgTvAgUKPwoE
BAsCARIE8wICOxoxIFJlcXVpcmVkLiBUaGUgZG9tYWluIHRydXN0IHJlc291cmNlIHRvIHJl
bW92ZWQuCgoNCgUECwIBBhIE8wICBwoNCgUECwIBARIE8wIIDQoNCgUECwIBAxIE8wIQEQoN
CgUECwIBCBIE8wISOgoQCggECwIBCJwIABIE8wITOQpqCgIEDBIG+AIAhAMBGlwgUmVxdWVz
dCBtZXNzYWdlIGZvcgogW1ZhbGlkYXRlVHJ1c3RdW2dvb2dsZS5jbG91ZC5tYW5hZ2VkaWRl
bnRpdGllcy52MWJldGExLlZhbGlkYXRlVHJ1c3RdCgoLCgMEDAESBPgCCBwKoQEKBAQMAgAS
BvsCAoADBBqQASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGRvbWFpbiBuYW1lLCBwcm9qZWN0
IG5hbWUsIGFuZCBsb2NhdGlvbiB1c2luZyB0aGUgZm9ybToKIGBwcm9qZWN0cy97cHJvamVj
dF9pZH0vbG9jYXRpb25zL2dsb2JhbC9kb21haW5zL3tkb21haW5fbmFtZX1gCgoNCgUEDAIA
BRIE+wICCAoNCgUEDAIAARIE+wIJDQoNCgUEDAIAAxIE+wIQEQoPCgUEDAIACBIG+wISgAMD
ChAKCAQMAgAInAgAEgT8AgQqChEKBwQMAgAInwgSBv0CBP8CBQpHCgQEDAIBEgSDAwI7Gjkg
UmVxdWlyZWQuIFRoZSBkb21haW4gdHJ1c3QgdG8gdmFsaWRhdGUgdHJ1c3Qgc3RhdGUgZm9y
LgoKDQoFBAwCAQYSBIMDAgcKDQoFBAwCAQESBIMDCA0KDQoFBAwCAQMSBIMDEBEKDQoFBAwC
AQgSBIMDEjoKEAoIBAwCAQicCAASBIMDEzliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::OpMetadata ===
    # Fields for OpMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest ===
    # Fields for CreateMicrosoftAdDomainRequest
    # Field: parent Type: 9 ()
    # Field: domain_name Type: 9 ()
    # Field: domain Type: 11 (.google.cloud.managedidentities.v1beta1.Domain)

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordRequest ===
    # Fields for ResetAdminPasswordRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordResponse ===
    # Fields for ResetAdminPasswordResponse
    # Field: password Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsRequest ===
    # Fields for ListDomainsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsResponse ===
    # Fields for ListDomainsResponse
    # Field: domains Type: 11 (.google.cloud.managedidentities.v1beta1.Domain)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::GetDomainRequest ===
    # Fields for GetDomainRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::UpdateDomainRequest ===
    # Fields for UpdateDomainRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: domain Type: 11 (.google.cloud.managedidentities.v1beta1.Domain)

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DeleteDomainRequest ===
    # Fields for DeleteDomainRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::AttachTrustRequest ===
    # Fields for AttachTrustRequest
    # Field: name Type: 9 ()
    # Field: trust Type: 11 (.google.cloud.managedidentities.v1beta1.Trust)

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ReconfigureTrustRequest ===
    # Fields for ReconfigureTrustRequest
    # Field: name Type: 9 ()
    # Field: target_domain_name Type: 9 ()
    # Field: target_dns_ip_addresses Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DetachTrustRequest ===
    # Fields for DetachTrustRequest
    # Field: name Type: 9 ()
    # Field: trust Type: 11 (.google.cloud.managedidentities.v1beta1.Trust)

# === Message: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ValidateTrustRequest ===
    # Fields for ValidateTrustRequest
    # Field: name Type: 9 ()
    # Field: trust Type: 11 (.google.cloud.managedidentities.v1beta1.Trust)

# === Service Client: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ManagedIdentitiesServiceClient ===
package Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ManagedIdentitiesServiceClient;

=pod

=head2 Service Client: Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ManagedIdentitiesServiceClient

Client stub representing the remote C<ManagedIdentitiesService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<managedidentities.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'managedidentities.googleapis.com:443' );

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

sub create_microsoft_ad_domain {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'CreateMicrosoftAdDomain',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub reset_admin_password {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'ResetAdminPassword',
        request        => $req,
        response_class => 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordResponse',
    });
}

sub list_domains {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'ListDomains',
        request        => $req,
        response_class => 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsResponse',
    });
}

sub get_domain {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::GetDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'GetDomain',
        request        => $req,
        response_class => 'Google::Cloud::Managedidentities::V1beta1::Resource::Domain',
    });
}

sub update_domain {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::UpdateDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'UpdateDomain',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_domain {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DeleteDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'DeleteDomain',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub attach_trust {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::AttachTrustRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'AttachTrust',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub reconfigure_trust {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ReconfigureTrustRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'ReconfigureTrust',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub detach_trust {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DetachTrustRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'DetachTrust',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub validate_trust {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ValidateTrustRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1beta1.ManagedIdentitiesService',
        method         => 'ValidateTrust',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService - Compiled Protocol Buffers messages for google/cloud/managedidentities/v1beta1/managed_identities_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService;

    my $msg = Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::OpMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::OpMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/managedidentities/v1beta1/managed_identities_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::OpMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest

Request message for
[CreateMicrosoftAdDomain][google.cloud.managedidentities.v1beta1.CreateMicrosoftAdDomain]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource project name and location using the form:
`projects/{project_id}/locations/global`

=item * C<< $msg->domain_name() >> / C<< $msg->domain_name($value) >>

Type: C<String>

Required. A domain name, e.g. mydomain.myorg.com, with the following restrictions:
 * Must contain only lowercase letters, numbers, periods and hyphens.
 * Must start with a letter.
 * Must contain between 2-64 characters.
 * Must end with a number or a letter.
 * Must not start with period.
 * First segment length (mydomain form example above) shouldn't exceed
   15 chars.
 * The last segment cannot be fully numeric.
 * Must be unique within the customer project.

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1beta1::Resource::Domain>)

Required. A Managed Identity domain resource.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordRequest

Request message for
[ResetAdminPassword][google.cloud.managedidentities.v1beta1.ResetAdminPassword]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The domain resource name using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordResponse

Response message for
[ResetAdminPassword][google.cloud.managedidentities.v1beta1.ResetAdminPassword]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->password() >> / C<< $msg->password($value) >>

Type: C<String>

A random password. See [admin][google.cloud.managedidentities.v1beta1.Domain.admin] for more information.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsRequest

Request message for
[ListDomains][google.cloud.managedidentities.v1beta1.ListDomains]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the domain location using the form:
`projects/{project_id}/locations/global`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If not specified, a default value of 1000 will be used.
Regardless of the page_size value, the response may include a partial list.
Callers should rely on a response's
[next_page_token][google.cloud.managedidentities.v1beta1.ListDomainsResponse.next_page_token]
to determine if there are additional results to list.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The `next_page_token` value returned from a previous ListDomainsRequest
request, if any.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter specifying constraints of a list operation.
For example, `Domain.fqdn="mydomain.myorginization"`.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Specifies the ordering of results. See
[Sorting
order](https://cloud.google.com/apis/design/design_patterns#sorting_order)
for more information.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsResponse

Response message for
[ListDomains][google.cloud.managedidentities.v1beta1.ListDomains]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->domains() >> / C<< $msg->domains($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1beta1::Resource::Domain>)

A list of Managed Identities Service domains in the project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results, or empty if there are no more
results in the list.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

A list of locations that could not be reached.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::GetDomainRequest

Request message for
[GetDomain][google.cloud.managedidentities.v1beta1.GetDomain]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The domain resource name using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::UpdateDomainRequest

Request message for
[UpdateDomain][google.cloud.managedidentities.v1beta1.UpdateDomain]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Mask of fields to update. At least one path must be supplied in this
field. The elements of the repeated paths field may only include
fields from [Domain][google.cloud.managedidentities.v1beta1.Domain]:
 * `labels`
 * `locations`
 * `authorized_networks`
 * `audit_logs_enabled`

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1beta1::Resource::Domain>)

Required. Domain message with updated fields. Only supported fields specified in
update_mask are updated.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DeleteDomainRequest

Request message for
[DeleteDomain][google.cloud.managedidentities.v1beta1.DeleteDomain]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The domain resource name using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::AttachTrustRequest

Request message for
[AttachTrust][google.cloud.managedidentities.v1beta1.AttachTrust]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource domain name, project name and location using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=item * C<< $msg->trust() >> / C<< $msg->trust($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1beta1::Resource::Trust>)

Required. The domain trust resource.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ReconfigureTrustRequest

Request message for
[ReconfigureTrust][google.cloud.managedidentities.v1beta1.ReconfigureTrust]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource domain name, project name and location using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=item * C<< $msg->target_domain_name() >> / C<< $msg->target_domain_name($value) >>

Type: C<String>

Required. The fully-qualified target domain name which will be in trust with current
domain.

=item * C<< $msg->target_dns_ip_addresses() >> / C<< $msg->target_dns_ip_addresses($value) >>

Type: C<String>

Required. The target DNS server IP addresses to resolve the remote domain involved
in the trust.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DetachTrustRequest

Request message for
[DetachTrust][google.cloud.managedidentities.v1beta1.DetachTrust]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource domain name, project name, and location using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=item * C<< $msg->trust() >> / C<< $msg->trust($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1beta1::Resource::Trust>)

Required. The domain trust resource to removed.

=back

=head2 Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ValidateTrustRequest

Request message for
[ValidateTrust][google.cloud.managedidentities.v1beta1.ValidateTrust]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource domain name, project name, and location using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=item * C<< $msg->trust() >> / C<< $msg->trust($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1beta1::Resource::Trust>)

Required. The domain trust to validate trust state for.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
