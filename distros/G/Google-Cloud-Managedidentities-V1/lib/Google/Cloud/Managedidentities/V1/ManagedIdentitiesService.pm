package Google::Cloud::Managedidentities::V1::ManagedIdentitiesService;

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
    eval { require Google::Cloud::Managedidentities::V1::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvbWFuYWdlZGlkZW50aXRpZXMvdjEvbWFuYWdlZF9pZGVudGl0aWVz
X3NlcnZpY2UucHJvdG8SIWdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MRocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aMGdvb2dsZS9jbG91ZC9tYW5hZ2VkaWRlbnRpdGllcy92MS9yZXNvdXJjZS5wcm90bxoj
Z29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9m
aWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqICCgpP
cE1ldGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEhsKBnRhcmdldBgDIAEoCUID4EEDUgZ0YXJn
ZXQSFwoEdmVyYhgEIAEoCUID4EEDUgR2ZXJiEjoKFnJlcXVlc3RlZF9jYW5jZWxsYXRpb24Y
BSABKAhCA+BBA1IVcmVxdWVzdGVkQ2FuY2VsbGF0aW9uEiQKC2FwaV92ZXJzaW9uGAYgASgJ
QgPgQQNSCmFwaVZlcnNpb24i1wEKHkNyZWF0ZU1pY3Jvc29mdEFkRG9tYWluUmVxdWVzdBJH
CgZwYXJlbnQYASABKAlCL+BBAvpBKRInbWFuYWdlZGlkZW50aXRpZXMuZ29vZ2xlYXBpcy5j
b20vRG9tYWluUgZwYXJlbnQSJAoLZG9tYWluX25hbWUYAiABKAlCA+BBAlIKZG9tYWluTmFt
ZRJGCgZkb21haW4YAyABKAsyKS5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEu
RG9tYWluQgPgQQJSBmRvbWFpbiJgChlSZXNldEFkbWluUGFzc3dvcmRSZXF1ZXN0EkMKBG5h
bWUYASABKAlCL+BBAvpBKQonbWFuYWdlZGlkZW50aXRpZXMuZ29vZ2xlYXBpcy5jb20vRG9t
YWluUgRuYW1lIjgKGlJlc2V0QWRtaW5QYXNzd29yZFJlc3BvbnNlEhoKCHBhc3N3b3JkGAEg
ASgJUghwYXNzd29yZCLgAQoSTGlzdERvbWFpbnNSZXF1ZXN0EkcKBnBhcmVudBgBIAEoCUIv
4EEC+kEpEidtYW5hZ2VkaWRlbnRpdGllcy5nb29nbGVhcGlzLmNvbS9Eb21haW5SBnBhcmVu
dBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEo
CUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRl
cl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5IqQBChNMaXN0RG9tYWluc1Jlc3BvbnNlEkMKB2Rv
bWFpbnMYASADKAsyKS5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuRG9tYWlu
Ugdkb21haW5zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1
bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiVwoQR2V0RG9tYWluUmVxdWVzdBJDCgRu
YW1lGAEgASgJQi/gQQL6QSkKJ21hbmFnZWRpZGVudGl0aWVzLmdvb2dsZWFwaXMuY29tL0Rv
bWFpblIEbmFtZSKfAQoTVXBkYXRlRG9tYWluUmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFzaxJGCgZkb21h
aW4YAiABKAsyKS5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuRG9tYWluQgPg
QQJSBmRvbWFpbiJaChNEZWxldGVEb21haW5SZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpB
KQonbWFuYWdlZGlkZW50aXRpZXMuZ29vZ2xlYXBpcy5jb20vRG9tYWluUgRuYW1lIp4BChJB
dHRhY2hUcnVzdFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidtYW5hZ2VkaWRlbnRp
dGllcy5nb29nbGVhcGlzLmNvbS9Eb21haW5SBG5hbWUSQwoFdHJ1c3QYAiABKAsyKC5nb29n
bGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuVHJ1c3RCA+BBAlIFdHJ1c3QizQEKF1Jl
Y29uZmlndXJlVHJ1c3RSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonbWFuYWdlZGlk
ZW50aXRpZXMuZ29vZ2xlYXBpcy5jb20vRG9tYWluUgRuYW1lEjEKEnRhcmdldF9kb21haW5f
bmFtZRgCIAEoCUID4EECUhB0YXJnZXREb21haW5OYW1lEjoKF3RhcmdldF9kbnNfaXBfYWRk
cmVzc2VzGAMgAygJQgPgQQJSFHRhcmdldERuc0lwQWRkcmVzc2VzIp4BChJEZXRhY2hUcnVz
dFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidtYW5hZ2VkaWRlbnRpdGllcy5nb29n
bGVhcGlzLmNvbS9Eb21haW5SBG5hbWUSQwoFdHJ1c3QYAiABKAsyKC5nb29nbGUuY2xvdWQu
bWFuYWdlZGlkZW50aXRpZXMudjEuVHJ1c3RCA+BBAlIFdHJ1c3QioAEKFFZhbGlkYXRlVHJ1
c3RSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonbWFuYWdlZGlkZW50aXRpZXMuZ29v
Z2xlYXBpcy5jb20vRG9tYWluUgRuYW1lEkMKBXRydXN0GAIgASgLMiguZ29vZ2xlLmNsb3Vk
Lm1hbmFnZWRpZGVudGl0aWVzLnYxLlRydXN0QgPgQQJSBXRydXN0MvIRChhNYW5hZ2VkSWRl
bnRpdGllc1NlcnZpY2US8AEKF0NyZWF0ZU1pY3Jvc29mdEFkRG9tYWluEkEuZ29vZ2xlLmNs
b3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxLkNyZWF0ZU1pY3Jvc29mdEFkRG9tYWluUmVxdWVz
dBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ic4LT5JMCOiIwL3YxL3twYXJlbnQ9
cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsfS9kb21haW5zOgZkb21haW7aQRlwYXJlbnQs
ZG9tYWluX25hbWUsZG9tYWluykEUCgZEb21haW4SCk9wTWV0YWRhdGES6AEKElJlc2V0QWRt
aW5QYXNzd29yZBI8Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5SZXNldEFk
bWluUGFzc3dvcmRSZXF1ZXN0Gj0uZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYx
LlJlc2V0QWRtaW5QYXNzd29yZFJlc3BvbnNlIlWC0+STAkgiQy92MS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy9nbG9iYWwvZG9tYWlucy8qfTpyZXNldEFkbWluUGFzc3dvcmQ6ASra
QQRuYW1lEr8BCgtMaXN0RG9tYWlucxI1Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGll
cy52MS5MaXN0RG9tYWluc1JlcXVlc3QaNi5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRp
ZXMudjEuTGlzdERvbWFpbnNSZXNwb25zZSJBgtPkkwIyEjAvdjEve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy9nbG9iYWx9L2RvbWFpbnPaQQZwYXJlbnQSrAEKCUdldERvbWFpbhIz
Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5HZXREb21haW5SZXF1ZXN0Giku
Z29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxLkRvbWFpbiI/gtPkkwIyEjAvdjEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2RvbWFpbnMvKn3aQQRuYW1lEtoB
CgxVcGRhdGVEb21haW4SNi5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuVXBk
YXRlRG9tYWluUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ic4LT5JMC
QTI3L3YxL3tkb21haW4ubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvZG9tYWlu
cy8qfToGZG9tYWlu2kESZG9tYWluLHVwZGF0ZV9tYXNrykEUCgZEb21haW4SCk9wTWV0YWRh
dGESzAEKDERlbGV0ZURvbWFpbhI2Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52
MS5EZWxldGVEb21haW5SZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJl
gtPkkwIyKjAvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2RvbWFpbnMv
Kn3aQQRuYW1lykEjChVnb29nbGUucHJvdG9idWYuRW1wdHkSCk9wTWV0YWRhdGES0AEKC0F0
dGFjaFRydXN0EjUuZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxLkF0dGFjaFRy
dXN0UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ia4LT5JMCQSI8L3Yx
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9kb21haW5zLyp9OmF0dGFjaFRy
dXN0OgEq2kEKbmFtZSx0cnVzdMpBFAoGRG9tYWluEgpPcE1ldGFkYXRhEoUCChBSZWNvbmZp
Z3VyZVRydXN0EjouZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxLlJlY29uZmln
dXJlVHJ1c3RSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKVAYLT5JMC
RiJBL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9kb21haW5zLyp9OnJl
Y29uZmlndXJlVHJ1c3Q6ASraQS9uYW1lLHRhcmdldF9kb21haW5fbmFtZSx0YXJnZXRfZG5z
X2lwX2FkZHJlc3Nlc8pBFAoGRG9tYWluEgpPcE1ldGFkYXRhEtABCgtEZXRhY2hUcnVzdBI1
Lmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5EZXRhY2hUcnVzdFJlcXVlc3Qa
HS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uImuC0+STAkEiPC92MS97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvZG9tYWlucy8qfTpkZXRhY2hUcnVzdDoBKtpBCm5h
bWUsdHJ1c3TKQRQKBkRvbWFpbhIKT3BNZXRhZGF0YRLWAQoNVmFsaWRhdGVUcnVzdBI3Lmdv
b2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5WYWxpZGF0ZVRydXN0UmVxdWVzdBod
Lmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ibYLT5JMCQyI+L3YxL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zL2dsb2JhbC9kb21haW5zLyp9OnZhbGlkYXRlVHJ1c3Q6ASraQQpu
YW1lLHRydXN0ykEUCgZEb21haW4SCk9wTWV0YWRhdGEaVMpBIG1hbmFnZWRpZGVudGl0aWVz
Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybUKTAgolY29tLmdvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MUId
TWFuYWdlZElkZW50aXRpZXNTZXJ2aWNlUHJvdG9QAVpTY2xvdWQuZ29vZ2xlLmNvbS9nby9t
YW5hZ2VkaWRlbnRpdGllcy9hcGl2MS9tYW5hZ2VkaWRlbnRpdGllc3BiO21hbmFnZWRpZGVu
dGl0aWVzcGKiAgRHQ01JqgIhR29vZ2xlLkNsb3VkLk1hbmFnZWRJZGVudGl0aWVzLlYxygIh
R29vZ2xlXENsb3VkXE1hbmFnZWRJZGVudGl0aWVzXFYx6gIkR29vZ2xlOjpDbG91ZDo6TWFu
YWdlZElkZW50aXRpZXM6OlYxSttjCgcSBQ8ApQMBCr0ECgEMEgMPABIysgQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCggKAQISAxEAKgoJCgIDABIDEwAmCgkKAgMBEgMUACEKCQoCAwISAxUA
KQoJCgIDAxIDFgAjCgkKAgMEEgMXADoKCQoCAwUSAxgALQoJCgIDBhIDGQAqCgkKAgMHEgMa
ACkKCAoBCBIDHAA+CgkKAgglEgMcAD4KCAoBCBIDHQBqCgkKAggLEgMdAGoKCAoBCBIDHgAi
CgkKAggKEgMeACIKCAoBCBIDHwA+CgkKAggIEgMfAD4KCAoBCBIDIAA+CgkKAggBEgMgAD4K
CAoBCBIDIQAiCgkKAggkEgMhACIKCAoBCBIDIgA+CgkKAggpEgMiAD4KCAoBCBIDIwA9CgkK
AggtEgMjAD0KvAkKAgYAEgVFALwBARquCSBBUEkgT3ZlcnZpZXcKCiBUaGUgYG1hbmFnZWRp
ZGVudGl0ZXMuZ29vZ2xlYXBpcy5jb21gIHNlcnZpY2UgaW1wbGVtZW50cyB0aGUgR29vZ2xl
IENsb3VkCiBNYW5hZ2VkIElkZW50aXRlcyBBUEkgZm9yIGlkZW50aXR5IHNlcnZpY2VzCiAo
ZS5nLiBNaWNyb3NvZnQgQWN0aXZlIERpcmVjdG9yeSkuCgogVGhlIE1hbmFnZWQgSWRlbnRp
dGllcyBzZXJ2aWNlIHByb3ZpZGVzIG1ldGhvZHMgdG8gbWFuYWdlCiAoY3JlYXRlL3JlYWQv
dXBkYXRlL2RlbGV0ZSkgZG9tYWlucywgcmVzZXQgbWFuYWdlZCBpZGVudGl0aWVzIGFkbWlu
IHBhc3N3b3JkLAogYWRkL3JlbW92ZSBkb21haW4gY29udHJvbGxlcnMgaW4gR0NQIHJlZ2lv
bnMgYW5kIGFkZC9yZW1vdmUgVlBDIHBlZXJpbmcuCgogRGF0YSBNb2RlbAoKIFRoZSBNYW5h
Z2VkIElkZW50aXRpZXMgc2VydmljZSBleHBvc2VzIHRoZSBmb2xsb3dpbmcgcmVzb3VyY2Vz
OgoKICogTG9jYXRpb25zIGFzIGdsb2JhbCwgbmFtZWQgYXMgZm9sbG93czoKICAgYHByb2pl
Y3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsYC4KCiAqIERvbWFpbnMsIG5hbWVk
IGFzIGZvbGxvd3M6CiAgIGAvcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9i
YWwvZG9tYWluL3tkb21haW5fbmFtZX1gLgoKIFRoZSBge2RvbWFpbl9uYW1lfWAgcmVmZXJz
IHRvIGZ1bGx5IHF1YWxpZmllZCBkb21haW4gbmFtZSBpbiB0aGUgY3VzdG9tZXIKIHByb2pl
Y3QgZS5nLiBteWRvbWFpbi5teW9yZ2FuaXphdGlvbi5jb20sIHdpdGggdGhlIGZvbGxvd2lu
ZyByZXN0cmljdGlvbnM6CgogICogTXVzdCBjb250YWluIG9ubHkgbG93ZXJjYXNlIGxldHRl
cnMsIG51bWJlcnMsIHBlcmlvZHMgYW5kIGh5cGhlbnMuCiAgKiBNdXN0IHN0YXJ0IHdpdGgg
YSBsZXR0ZXIuCiAgKiBNdXN0IGNvbnRhaW4gYmV0d2VlbiAyLTY0IGNoYXJhY3RlcnMuCiAg
KiBNdXN0IGVuZCB3aXRoIGEgbnVtYmVyIG9yIGEgbGV0dGVyLgogICogTXVzdCBub3Qgc3Rh
cnQgd2l0aCBwZXJpb2QuCiAgKiBGaXJzdCBzZWdlbWVudCBsZW5ndGggKG15ZG9tYWluIGZv
cm0gZXhhbXBsZSBhYm92ZSkgc2hvdWxkbid0IGV4Y2VlZAogICAgMTUgY2hhcnMuCiAgKiBU
aGUgbGFzdCBzZWdtZW50IGNhbm5vdCBiZSBmdWxseSBudW1lcmljLgogICogTXVzdCBiZSB1
bmlxdWUgd2l0aGluIHRoZSBjdXN0b21lciBwcm9qZWN0LgoKCgoDBgABEgNFCCAKCgoDBgAD
EgNGAkgKDAoFBgADmQgSA0YCSAoKCgMGAAMSA0cCVgoMCgUGAAOaCBIDRwJWCi4KBAYAAgAS
BEoCVAMaICBDcmVhdGVzIGEgTWljcm9zb2Z0IEFEIGRvbWFpbi4KCgwKBQYAAgABEgNKBh0K
DAoFBgACAAISA0oePAoMCgUGAAIAAxIDSkdjCg0KBQYAAgAEEgRLBE4GChEKCQYAAgAEsMq8
IhIESwROBgoMCgUGAAIABBIDTwRHCg8KCAYAAgAEmwgAEgNPBEcKDQoFBgACAAQSBFAEUwYK
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
aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgsKAwQAARIEvwEIEgpACgQEAAIAEgTBAQJY
GjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoN
CgUEAAIABhIEwQECGwoNCgUEAAIAARIEwQEcJwoNCgUEAAIAAxIEwQEqKwoNCgUEAAIACBIE
wQEsVwoQCggEAAIACJwIABIEwQEtVgpFCgQEAAIBEgTEAQJVGjcgT3V0cHV0IG9ubHkuIFRo
ZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCg0KBQQAAgEGEgTEAQIb
Cg0KBQQAAgEBEgTEARwkCg0KBQQAAgEDEgTEAScoCg0KBQQAAgEIEgTEASlUChAKCAQAAgEI
nAgAEgTEASpTCloKBAQAAgISBMcBAkAaTCBPdXRwdXQgb25seS4gU2VydmVyLWRlZmluZWQg
cmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0aW9uLgoKDQoFBAAC
AgUSBMcBAggKDQoFBAACAgESBMcBCQ8KDQoFBAACAgMSBMcBEhMKDQoFBAACAggSBMcBFD8K
EAoIBAACAgicCAASBMcBFT4KSAoEBAACAxIEygECPho6IE91dHB1dCBvbmx5LiBOYW1lIG9m
IHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoNCgUEAAIDBRIEygECCAoN
CgUEAAIDARIEygEJDQoNCgUEAAIDAxIEygEQEQoNCgUEAAIDCBIEygESPQoQCggEAAIDCJwI
ABIEygETPAqaAgoEBAACBBIE0AECThqLAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0
aGVyIHRoZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0
aW9uLiBPcGVyYXRpb25zIHRoYXQgaGF2ZSBzdWNjZXNzZnVsbHkgYmVlbiBjYW5jZWxsZWQK
IGhhdmUgW09wZXJhdGlvbi5lcnJvcl1bXSB2YWx1ZSB3aXRoIGEgW2dvb2dsZS5ycGMuU3Rh
dHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsCiBjb3JyZXNwb25kaW5n
IHRvIGBDb2RlLkNBTkNFTExFRGAuCgoNCgUEAAIEBRIE0AECBgoNCgUEAAIEARIE0AEHHQoN
CgUEAAIEAxIE0AEgIQoNCgUEAAIECBIE0AEiTQoQCggEAAIECJwIABIE0AEjTApFCgQEAAIF
EgTTAQJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9w
ZXJhdGlvbi4KCg0KBQQAAgUFEgTTAQIICg0KBQQAAgUBEgTTAQkUCg0KBQQAAgUDEgTTARcY
Cg0KBQQAAgUIEgTTARlEChAKCAQAAgUInAgAEgTTARpDCnkKAgQBEgbYAQDyAQEaayBSZXF1
ZXN0IG1lc3NhZ2UgZm9yCiBbQ3JlYXRlTWljcm9zb2Z0QWREb21haW5dW2dvb2dsZS5jbG91
ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5DcmVhdGVNaWNyb3NvZnRBZERvbWFpbl0KCgsKAwQB
ARIE2AEIJgp8CgQEAQIAEgbbAQLgAQQabCBSZXF1aXJlZC4gVGhlIHJlc291cmNlIHByb2pl
Y3QgbmFtZSBhbmQgbG9jYXRpb24gdXNpbmcgdGhlIGZvcm06CiBgcHJvamVjdHMve3Byb2pl
Y3RfaWR9L2xvY2F0aW9ucy9nbG9iYWxgCgoNCgUEAQIABRIE2wECCAoNCgUEAQIAARIE2wEJ
DwoNCgUEAQIAAxIE2wESEwoPCgUEAQIACBIG2wEU4AEDChAKCAQBAgAInAgAEgTcAQQqChEK
BwQBAgAInwgSBt0BBN8BBQqMBAoEBAECARIE7gECQhr9AyBSZXF1aXJlZC4gVGhlIGZ1bGx5
IHF1YWxpZmllZCBkb21haW4gbmFtZS4KIGUuZy4gbXlkb21haW4ubXlvcmdhbml6YXRpb24u
Y29tLCB3aXRoIHRoZSBmb2xsb3dpbmcgcmVzdHJpY3Rpb25zOgoKICAqIE11c3QgY29udGFp
biBvbmx5IGxvd2VyY2FzZSBsZXR0ZXJzLCBudW1iZXJzLCBwZXJpb2RzIGFuZCBoeXBoZW5z
LgogICogTXVzdCBzdGFydCB3aXRoIGEgbGV0dGVyLgogICogTXVzdCBjb250YWluIGJldHdl
ZW4gMi02NCBjaGFyYWN0ZXJzLgogICogTXVzdCBlbmQgd2l0aCBhIG51bWJlciBvciBhIGxl
dHRlci4KICAqIE11c3Qgbm90IHN0YXJ0IHdpdGggcGVyaW9kLgogICogRmlyc3Qgc2VnZW1l
bnQgbGVuZ3RoIChteWRvbWFpbiBmb3JtIGV4YW1wbGUgYWJvdmUpIHNob3VsZG4ndCBleGNl
ZWQKICAgIDE1IGNoYXJzLgogICogVGhlIGxhc3Qgc2VnbWVudCBjYW5ub3QgYmUgZnVsbHkg
bnVtZXJpYy4KICAqIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgY3VzdG9tZXIgcHJvamVj
dC4KCg0KBQQBAgEFEgTuAQIICg0KBQQBAgEBEgTuAQkUCg0KBQQBAgEDEgTuARcYCg0KBQQB
AgEIEgTuARlBChAKCAQBAgEInAgAEgTuARpACj0KBAQBAgISBPEBAj0aLyBSZXF1aXJlZC4g
QSBNYW5hZ2VkIElkZW50aXR5IGRvbWFpbiByZXNvdXJjZS4KCg0KBQQBAgIGEgTxAQIICg0K
BQQBAgIBEgTxAQkPCg0KBQQBAgIDEgTxARITCg0KBQQBAgIIEgTxARQ8ChAKCAQBAgIInAgA
EgTxARU7Cm8KAgQCEgb2AQD/AQEaYSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbUmVzZXRBZG1p
blBhc3N3b3JkXVtnb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuUmVzZXRBZG1p
blBhc3N3b3JkXQoKCwoDBAIBEgT2AQghCoQBCgQEAgIAEgb5AQL+AQQadCBSZXF1aXJlZC4g
VGhlIGRvbWFpbiByZXNvdXJjZSBuYW1lIHVzaW5nIHRoZSBmb3JtOgogYHByb2plY3RzL3tw
cm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsL2RvbWFpbnMve2RvbWFpbl9uYW1lfWAKCg0K
BQQCAgAFEgT5AQIICg0KBQQCAgABEgT5AQkNCg0KBQQCAgADEgT5ARARCg8KBQQCAgAIEgb5
ARL+AQMKEAoIBAICAAicCAASBPoBBCoKEQoHBAICAAifCBIG+wEE/QEFCnAKAgQDEgaDAgCG
AgEaYiBSZXNwb25zZSBtZXNzYWdlIGZvcgogW1Jlc2V0QWRtaW5QYXNzd29yZF1bZ29vZ2xl
LmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxLlJlc2V0QWRtaW5QYXNzd29yZF0KCgsKAwQD
ARIEgwIIIgp0CgQEAwIAEgSFAgIWGmYgQSByYW5kb20gcGFzc3dvcmQuIFNlZSBbYWRtaW5d
W2dvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5Eb21haW4uYWRtaW5dIGZvciBt
b3JlIGluZm9ybWF0aW9uLgoKDQoFBAMCAAUSBIUCAggKDQoFBAMCAAESBIUCCREKDQoFBAMC
AAMSBIUCFBUKYQoCBAQSBooCAKkCARpTIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtMaXN0RG9t
YWluc11bZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxLkxpc3REb21haW5zXQoK
CwoDBAQBEgSKAggaCn4KBAQEAgASBo0CApICBBpuIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgZG9tYWluIGxvY2F0aW9uIHVzaW5nIHRoZSBmb3JtOgogYHByb2plY3Rz
L3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsYAoKDQoFBAQCAAUSBI0CAggKDQoFBAQC
AAESBI0CCQ8KDQoFBAQCAAMSBI0CEhMKDwoFBAQCAAgSBo0CFJICAwoQCggEBAIACJwIABIE
jgIEKgoRCgcEBAIACJ8IEgaPAgSRAgUK/QIKBAQEAgESBJoCAj8a7gIgT3B0aW9uYWwuIFRo
ZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4uCiBJZiBub3Qgc3BlY2lmaWVk
LCBhIGRlZmF1bHQgdmFsdWUgb2YgMTAwMCB3aWxsIGJlIHVzZWQuCiBSZWdhcmRsZXNzIG9m
IHRoZSBwYWdlX3NpemUgdmFsdWUsIHRoZSByZXNwb25zZSBtYXkgaW5jbHVkZSBhIHBhcnRp
YWwgbGlzdC4KIENhbGxlcnMgc2hvdWxkIHJlbHkgb24gYSByZXNwb25zZSdzCiBbbmV4dF9w
YWdlX3Rva2VuXVtnb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuTGlzdERvbWFp
bnNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dCiB0byBkZXRlcm1pbmUgaWYgdGhlcmUgYXJl
IGFkZGl0aW9uYWwgcmVzdWx0cyB0byBsaXN0LgoKDQoFBAQCAQUSBJoCAgcKDQoFBAQCAQES
BJoCCBEKDQoFBAQCAQMSBJoCFBUKDQoFBAQCAQgSBJoCFj4KEAoIBAQCAQicCAASBJoCFz0K
cwoEBAQCAhIEngICQRplIE9wdGlvbmFsLiBUaGUgYG5leHRfcGFnZV90b2tlbmAgdmFsdWUg
cmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIExpc3REb21haW5zUmVxdWVzdAogcmVxdWVzdCwg
aWYgYW55LgoKDQoFBAQCAgUSBJ4CAggKDQoFBAQCAgESBJ4CCRMKDQoFBAQCAgMSBJ4CFhcK
DQoFBAQCAggSBJ4CGEAKEAoIBAQCAgicCAASBJ4CGT8KhQEKBAQEAgMSBKICAj0adyBPcHRp
b25hbC4gQSBmaWx0ZXIgc3BlY2lmeWluZyBjb25zdHJhaW50cyBvZiBhIGxpc3Qgb3BlcmF0
aW9uLgogRm9yIGV4YW1wbGUsIGBEb21haW4uZnFkbj0ibXlkb21haW4ubXlvcmdpbml6YXRp
b24iYC4KCg0KBQQEAgMFEgSiAgIICg0KBQQEAgMBEgSiAgkPCg0KBQQEAgMDEgSiAhITCg0K
BQQEAgMIEgSiAhQ8ChAKCAQEAgMInAgAEgSiAhU7Cq4BCgQEBAIEEgSoAgI/Gp8BIE9wdGlv
bmFsLiBTcGVjaWZpZXMgdGhlIG9yZGVyaW5nIG9mIHJlc3VsdHMuIFNlZQogW1NvcnRpbmcK
IG9yZGVyXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vZGVzaWduX3Bh
dHRlcm5zI3NvcnRpbmdfb3JkZXIpCiBmb3IgbW9yZSBpbmZvcm1hdGlvbi4KCg0KBQQEAgQF
EgSoAgIICg0KBQQEAgQBEgSoAgkRCg0KBQQEAgQDEgSoAhQVCg0KBQQEAgQIEgSoAhY+ChAK
CAQEAgQInAgAEgSoAhc9CmIKAgQFEgatAgC3AgEaVCBSZXNwb25zZSBtZXNzYWdlIGZvcgog
W0xpc3REb21haW5zXVtnb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuTGlzdERv
bWFpbnNdCgoLCgMEBQESBK0CCBsKTAoEBAUCABIErwICHho+IEEgbGlzdCBvZiBNYW5hZ2Vk
IElkZW50aXRpZXMgU2VydmljZSBkb21haW5zIGluIHRoZSBwcm9qZWN0LgoKDQoFBAUCAAQS
BK8CAgoKDQoFBAUCAAYSBK8CCxEKDQoFBAUCAAESBK8CEhkKDQoFBAUCAAMSBK8CHB0KcQoE
BAUCARIEswICHRpjIEEgdG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1
bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8gbW9yZQogcmVzdWx0cyBpbiB0aGUgbGlz
dC4KCg0KBQQFAgEFEgSzAgIICg0KBQQFAgEBEgSzAgkYCg0KBQQFAgEDEgSzAhscCj4KBAQF
AgISBLYCAiIaMCBBIGxpc3Qgb2YgbG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNo
ZWQuCgoNCgUEBQICBBIEtgICCgoNCgUEBQICBRIEtgILEQoNCgUEBQICARIEtgISHQoNCgUE
BQICAxIEtgIgIQpcCgIEBhIGugIAwwIBGk4gUmVxdWVzdCBtZXNzYWdlIGZvciBbR2V0RG9t
YWluXVtnb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuR2V0RG9tYWluXQoKCwoD
BAYBEgS6AggYCoQBCgQEBgIAEga9AgLCAgQadCBSZXF1aXJlZC4gVGhlIGRvbWFpbiByZXNv
dXJjZSBuYW1lIHVzaW5nIHRoZSBmb3JtOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2Nh
dGlvbnMvZ2xvYmFsL2RvbWFpbnMve2RvbWFpbl9uYW1lfWAKCg0KBQQGAgAFEgS9AgIICg0K
BQQGAgABEgS9AgkNCg0KBQQGAgADEgS9AhARCg8KBQQGAgAIEga9AhLCAgMKEAoIBAYCAAic
CAASBL4CBCoKEQoHBAYCAAifCBIGvwIEwQIFCmMKAgQHEgbHAgDTAgEaVSBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbVXBkYXRlRG9tYWluXVtnb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRp
ZXMudjEuVXBkYXRlRG9tYWluXQoKCwoDBAcBEgTHAggbCpkCCgQEBwIAEgTOAgJVGooCIFJl
cXVpcmVkLiBNYXNrIG9mIGZpZWxkcyB0byB1cGRhdGUuIEF0IGxlYXN0IG9uZSBwYXRoIG11
c3QgYmUgc3VwcGxpZWQgaW4gdGhpcwogZmllbGQuIFRoZSBlbGVtZW50cyBvZiB0aGUgcmVw
ZWF0ZWQgcGF0aHMgZmllbGQgbWF5IG9ubHkgaW5jbHVkZQogZmllbGRzIGZyb20gW0RvbWFp
bl1bZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxLkRvbWFpbl06CiAgKiBgbGFi
ZWxzYAogICogYGxvY2F0aW9uc2AKICAqIGBhdXRob3JpemVkX25ldHdvcmtzYAoKDQoFBAcC
AAYSBM4CAhsKDQoFBAcCAAESBM4CHCcKDQoFBAcCAAMSBM4CKisKDQoFBAcCAAgSBM4CLFQK
EAoIBAcCAAicCAASBM4CLVMKegoEBAcCARIE0gICPRpsIFJlcXVpcmVkLiBEb21haW4gbWVz
c2FnZSB3aXRoIHVwZGF0ZWQgZmllbGRzLiBPbmx5IHN1cHBvcnRlZCBmaWVsZHMgc3BlY2lm
aWVkIGluCiB1cGRhdGVfbWFzayBhcmUgdXBkYXRlZC4KCg0KBQQHAgEGEgTSAgIICg0KBQQH
AgEBEgTSAgkPCg0KBQQHAgEDEgTSAhITCg0KBQQHAgEIEgTSAhQ8ChAKCAQHAgEInAgAEgTS
AhU7CmMKAgQIEgbXAgDgAgEaVSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGVsZXRlRG9tYWlu
XVtnb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuRGVsZXRlRG9tYWluXQoKCwoD
BAgBEgTXAggbCoQBCgQECAIAEgbaAgLfAgQadCBSZXF1aXJlZC4gVGhlIGRvbWFpbiByZXNv
dXJjZSBuYW1lIHVzaW5nIHRoZSBmb3JtOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2Nh
dGlvbnMvZ2xvYmFsL2RvbWFpbnMve2RvbWFpbl9uYW1lfWAKCg0KBQQIAgAFEgTaAgIICg0K
BQQIAgABEgTaAgkNCg0KBQQIAgADEgTaAhARCg8KBQQIAgAIEgbaAhLfAgMKEAoIBAgCAAic
CAASBNsCBCoKEQoHBAgCAAifCBIG3AIE3gIFCmEKAgQJEgbkAgDwAgEaUyBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbQXR0YWNoVHJ1c3RdW2dvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGll
cy52MS5BdHRhY2hUcnVzdF0KCgsKAwQJARIE5AIIGgqgAQoEBAkCABIG5wIC7AIEGo8BIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgZG9tYWluIG5hbWUsIHByb2plY3QgbmFtZSBhbmQgbG9j
YXRpb24gdXNpbmcgdGhlIGZvcm06CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9u
cy9nbG9iYWwvZG9tYWlucy97ZG9tYWluX25hbWV9YAoKDQoFBAkCAAUSBOcCAggKDQoFBAkC
AAESBOcCCQ0KDQoFBAkCAAMSBOcCEBEKDwoFBAkCAAgSBucCEuwCAwoQCggECQIACJwIABIE
6AIEKgoRCgcECQIACJ8IEgbpAgTrAgUKNAoEBAkCARIE7wICOxomIFJlcXVpcmVkLiBUaGUg
ZG9tYWluIHRydXN0IHJlc291cmNlLgoKDQoFBAkCAQYSBO8CAgcKDQoFBAkCAQESBO8CCA0K
DQoFBAkCAQMSBO8CEBEKDQoFBAkCAQgSBO8CEjoKEAoIBAkCAQicCAASBO8CEzkKawoCBAoS
BvQCAIUDARpdIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtSZWNvbmZpZ3VyZVRydXN0XVtnb29n
bGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuUmVjb25maWd1cmVUcnVzdF0KCgsKAwQK
ARIE9AIIHwqgAQoEBAoCABIG9wIC/AIEGo8BIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgZG9t
YWluIG5hbWUsIHByb2plY3QgbmFtZSBhbmQgbG9jYXRpb24gdXNpbmcgdGhlIGZvcm06CiBg
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwvZG9tYWlucy97ZG9tYWlu
X25hbWV9YAoKDQoFBAoCAAUSBPcCAggKDQoFBAoCAAESBPcCCQ0KDQoFBAoCAAMSBPcCEBEK
DwoFBAoCAAgSBvcCEvwCAwoQCggECgIACJwIABIE+AIEKgoRCgcECgIACJ8IEgb5AgT7AgUK
bQoEBAoCARIEgAMCSRpfIFJlcXVpcmVkLiBUaGUgZnVsbHktcXVhbGlmaWVkIHRhcmdldCBk
b21haW4gbmFtZSB3aGljaCB3aWxsIGJlIGluIHRydXN0IHdpdGggY3VycmVudAogZG9tYWlu
LgoKDQoFBAoCAQUSBIADAggKDQoFBAoCAQESBIADCRsKDQoFBAoCAQMSBIADHh8KDQoFBAoC
AQgSBIADIEgKEAoIBAoCAQicCAASBIADIUcKcQoEBAoCAhIEhAMCVxpjIFJlcXVpcmVkLiBU
aGUgdGFyZ2V0IEROUyBzZXJ2ZXIgSVAgYWRkcmVzc2VzIHRvIHJlc29sdmUgdGhlIHJlbW90
ZSBkb21haW4gaW52b2x2ZWQKIGluIHRoZSB0cnVzdC4KCg0KBQQKAgIEEgSEAwIKCg0KBQQK
AgIFEgSEAwsRCg0KBQQKAgIBEgSEAxIpCg0KBQQKAgIDEgSEAywtCg0KBQQKAgIIEgSEAy5W
ChAKCAQKAgIInAgAEgSEAy9VCmEKAgQLEgaJAwCVAwEaUyBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbRGV0YWNoVHJ1c3RdW2dvb2dsZS5jbG91ZC5tYW5hZ2VkaWRlbnRpdGllcy52MS5EZXRh
Y2hUcnVzdF0KCgsKAwQLARIEiQMIGgqhAQoEBAsCABIGjAMCkQMEGpABIFJlcXVpcmVkLiBU
aGUgcmVzb3VyY2UgZG9tYWluIG5hbWUsIHByb2plY3QgbmFtZSwgYW5kIGxvY2F0aW9uIHVz
aW5nIHRoZSBmb3JtOgogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFs
L2RvbWFpbnMve2RvbWFpbl9uYW1lfWAKCg0KBQQLAgAFEgSMAwIICg0KBQQLAgABEgSMAwkN
Cg0KBQQLAgADEgSMAxARCg8KBQQLAgAIEgaMAxKRAwMKEAoIBAsCAAicCAASBI0DBCoKEQoH
BAsCAAifCBIGjgMEkAMFCj8KBAQLAgESBJQDAjsaMSBSZXF1aXJlZC4gVGhlIGRvbWFpbiB0
cnVzdCByZXNvdXJjZSB0byByZW1vdmVkLgoKDQoFBAsCAQYSBJQDAgcKDQoFBAsCAQESBJQD
CA0KDQoFBAsCAQMSBJQDEBEKDQoFBAsCAQgSBJQDEjoKEAoIBAsCAQicCAASBJQDEzkKZQoC
BAwSBpkDAKUDARpXIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtWYWxpZGF0ZVRydXN0XVtnb29n
bGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjEuVmFsaWRhdGVUcnVzdF0KCgsKAwQMARIE
mQMIHAqhAQoEBAwCABIGnAMCoQMEGpABIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgZG9tYWlu
IG5hbWUsIHByb2plY3QgbmFtZSwgYW5kIGxvY2F0aW9uIHVzaW5nIHRoZSBmb3JtOgogYHBy
b2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsL2RvbWFpbnMve2RvbWFpbl9u
YW1lfWAKCg0KBQQMAgAFEgScAwIICg0KBQQMAgABEgScAwkNCg0KBQQMAgADEgScAxARCg8K
BQQMAgAIEgacAxKhAwMKEAoIBAwCAAicCAASBJ0DBCoKEQoHBAwCAAifCBIGngMEoAMFCkcK
BAQMAgESBKQDAjsaOSBSZXF1aXJlZC4gVGhlIGRvbWFpbiB0cnVzdCB0byB2YWxpZGF0ZSB0
cnVzdCBzdGF0ZSBmb3IuCgoNCgUEDAIBBhIEpAMCBwoNCgUEDAIBARIEpAMIDQoNCgUEDAIB
AxIEpAMQEQoNCgUEDAIBCBIEpAMSOgoQCggEDAIBCJwIABIEpAMTOWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::OpMetadata ===
    # Fields for OpMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest ===
    # Fields for CreateMicrosoftAdDomainRequest
    # Field: parent Type: 9 ()
    # Field: domain_name Type: 9 ()
    # Field: domain Type: 11 (.google.cloud.managedidentities.v1.Domain)

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ResetAdminPasswordRequest ===
    # Fields for ResetAdminPasswordRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ResetAdminPasswordResponse ===
    # Fields for ResetAdminPasswordResponse
    # Field: password Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ListDomainsRequest ===
    # Fields for ListDomainsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ListDomainsResponse ===
    # Fields for ListDomainsResponse
    # Field: domains Type: 11 (.google.cloud.managedidentities.v1.Domain)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::GetDomainRequest ===
    # Fields for GetDomainRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::UpdateDomainRequest ===
    # Fields for UpdateDomainRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: domain Type: 11 (.google.cloud.managedidentities.v1.Domain)

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::DeleteDomainRequest ===
    # Fields for DeleteDomainRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::AttachTrustRequest ===
    # Fields for AttachTrustRequest
    # Field: name Type: 9 ()
    # Field: trust Type: 11 (.google.cloud.managedidentities.v1.Trust)

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ReconfigureTrustRequest ===
    # Fields for ReconfigureTrustRequest
    # Field: name Type: 9 ()
    # Field: target_domain_name Type: 9 ()
    # Field: target_dns_ip_addresses Type: 9 ()

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::DetachTrustRequest ===
    # Fields for DetachTrustRequest
    # Field: name Type: 9 ()
    # Field: trust Type: 11 (.google.cloud.managedidentities.v1.Trust)

# === Message: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ValidateTrustRequest ===
    # Fields for ValidateTrustRequest
    # Field: name Type: 9 ()
    # Field: trust Type: 11 (.google.cloud.managedidentities.v1.Trust)

# === Service Client: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ManagedIdentitiesServiceClient ===
package Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ManagedIdentitiesServiceClient;

=pod

=head2 Service Client: Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ManagedIdentitiesServiceClient

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
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'CreateMicrosoftAdDomain',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub reset_admin_password {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ResetAdminPasswordRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'ResetAdminPassword',
        request        => $req,
        response_class => 'Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ResetAdminPasswordResponse',
    });
}

sub list_domains {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ListDomainsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'ListDomains',
        request        => $req,
        response_class => 'Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ListDomainsResponse',
    });
}

sub get_domain {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::GetDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'GetDomain',
        request        => $req,
        response_class => 'Google::Cloud::Managedidentities::V1::Resource::Domain',
    });
}

sub update_domain {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::UpdateDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'UpdateDomain',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_domain {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::DeleteDomainRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'DeleteDomain',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub attach_trust {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::AttachTrustRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'AttachTrust',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub reconfigure_trust {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ReconfigureTrustRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'ReconfigureTrust',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub detach_trust {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::DetachTrustRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'DetachTrust',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub validate_trust {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ValidateTrustRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedidentities.v1.ManagedIdentitiesService',
        method         => 'ValidateTrust',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Managedidentities::V1::ManagedIdentitiesService - Compiled Protocol Buffers messages for google/cloud/managedidentities/v1/managed_identities_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Managedidentities::V1::ManagedIdentitiesService;

    my $msg = Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::OpMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::OpMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/managedidentities/v1/managed_identities_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::OpMetadata

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

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest

Request message for
[CreateMicrosoftAdDomain][google.cloud.managedidentities.v1.CreateMicrosoftAdDomain]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource project name and location using the form:
`projects/{project_id}/locations/global`

=item * C<< $msg->domain_name() >> / C<< $msg->domain_name($value) >>

Type: C<String>

Required. The fully qualified domain name.
e.g. mydomain.myorganization.com, with the following restrictions:

 * Must contain only lowercase letters, numbers, periods and hyphens.
 * Must start with a letter.
 * Must contain between 2-64 characters.
 * Must end with a number or a letter.
 * Must not start with period.
 * First segement length (mydomain form example above) shouldn't exceed
   15 chars.
 * The last segment cannot be fully numeric.
 * Must be unique within the customer project.

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1::Resource::Domain>)

Required. A Managed Identity domain resource.

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ResetAdminPasswordRequest

Request message for
[ResetAdminPassword][google.cloud.managedidentities.v1.ResetAdminPassword]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The domain resource name using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ResetAdminPasswordResponse

Response message for
[ResetAdminPassword][google.cloud.managedidentities.v1.ResetAdminPassword]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->password() >> / C<< $msg->password($value) >>

Type: C<String>

A random password. See [admin][google.cloud.managedidentities.v1.Domain.admin] for more information.

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ListDomainsRequest

Request message for
[ListDomains][google.cloud.managedidentities.v1.ListDomains]

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
[next_page_token][google.cloud.managedidentities.v1.ListDomainsResponse.next_page_token]
to determine if there are additional results to list.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The `next_page_token` value returned from a previous ListDomainsRequest
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

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ListDomainsResponse

Response message for
[ListDomains][google.cloud.managedidentities.v1.ListDomains]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->domains() >> / C<< $msg->domains($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1::Resource::Domain>)

A list of Managed Identities Service domains in the project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results, or empty if there are no more
results in the list.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

A list of locations that could not be reached.

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::GetDomainRequest

Request message for [GetDomain][google.cloud.managedidentities.v1.GetDomain]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The domain resource name using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::UpdateDomainRequest

Request message for
[UpdateDomain][google.cloud.managedidentities.v1.UpdateDomain]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Mask of fields to update. At least one path must be supplied in this
field. The elements of the repeated paths field may only include
fields from [Domain][google.cloud.managedidentities.v1.Domain]:
 * `labels`
 * `locations`
 * `authorized_networks`

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1::Resource::Domain>)

Required. Domain message with updated fields. Only supported fields specified in
update_mask are updated.

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::DeleteDomainRequest

Request message for
[DeleteDomain][google.cloud.managedidentities.v1.DeleteDomain]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The domain resource name using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::AttachTrustRequest

Request message for
[AttachTrust][google.cloud.managedidentities.v1.AttachTrust]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource domain name, project name and location using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=item * C<< $msg->trust() >> / C<< $msg->trust($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1::Resource::Trust>)

Required. The domain trust resource.

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ReconfigureTrustRequest

Request message for
[ReconfigureTrust][google.cloud.managedidentities.v1.ReconfigureTrust]

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

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::DetachTrustRequest

Request message for
[DetachTrust][google.cloud.managedidentities.v1.DetachTrust]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource domain name, project name, and location using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=item * C<< $msg->trust() >> / C<< $msg->trust($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1::Resource::Trust>)

Required. The domain trust resource to removed.

=back

=head2 Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::ValidateTrustRequest

Request message for
[ValidateTrust][google.cloud.managedidentities.v1.ValidateTrust]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource domain name, project name, and location using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`

=item * C<< $msg->trust() >> / C<< $msg->trust($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1::Resource::Trust>)

Required. The domain trust to validate trust state for.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Managedidentities::V1::ManagedIdentitiesService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
