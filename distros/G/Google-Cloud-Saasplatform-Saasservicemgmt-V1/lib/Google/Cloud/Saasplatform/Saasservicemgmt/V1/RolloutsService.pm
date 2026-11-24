package Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService;

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
    eval { require Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvc2Fhc3BsYXRmb3JtL3NhYXNzZXJ2aWNlbWdtdC92MS9yb2xsb3V0
c19zZXJ2aWNlLnByb3RvEixnb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3JtLnNhYXNzZXJ2aWNl
bWdtdC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGll
bnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aRWdvb2dsZS9jbG91ZC9zYWFzcGxhdGZvcm0vc2Fhc3NlcnZpY2Vt
Z210L3YxL3JvbGxvdXRzX3Jlc291cmNlcy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5
LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byLRAQoTTGlzdFJvbGxv
dXRzUmVxdWVzdBJHCgZwYXJlbnQYlk4gASgJQi7gQQL6QSgSJnNhYXNzZXJ2aWNlbWdtdC5n
b29nbGVhcGlzLmNvbS9Sb2xsb3V0UgZwYXJlbnQSHAoJcGFnZV9zaXplGIlSIAEoBVIIcGFn
ZVNpemUSHgoKcGFnZV90b2tlbhiKUiABKAlSCXBhZ2VUb2tlbhIXCgZmaWx0ZXIYi1IgASgJ
UgZmaWx0ZXISGgoIb3JkZXJfYnkYjFIgASgJUgdvcmRlckJ5IrYBChRMaXN0Um9sbG91dHNS
ZXNwb25zZRJSCghyb2xsb3V0cxiNUiADKAsyNS5nb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3Jt
LnNhYXNzZXJ2aWNlbWdtdC52MS5Sb2xsb3V0Ughyb2xsb3V0cxInCg9uZXh0X3BhZ2VfdG9r
ZW4YjlIgASgJUg1uZXh0UGFnZVRva2VuEiEKC3VucmVhY2hhYmxlGI9SIAMoCVILdW5yZWFj
aGFibGUiWAoRR2V0Um9sbG91dFJlcXVlc3QSQwoEbmFtZRiRTiABKAlCLuBBAvpBKAomc2Fh
c3NlcnZpY2VtZ210Lmdvb2dsZWFwaXMuY29tL1JvbGxvdXRSBG5hbWUioQIKFENyZWF0ZVJv
bGxvdXRSZXF1ZXN0EkcKBnBhcmVudBiWTiABKAlCLuBBAvpBKBImc2Fhc3NlcnZpY2VtZ210
Lmdvb2dsZWFwaXMuY29tL1JvbGxvdXRSBnBhcmVudBIjCgpyb2xsb3V0X2lkGIdSIAEoCUID
4EECUglyb2xsb3V0SWQSVQoHcm9sbG91dBiIUiABKAsyNS5nb29nbGUuY2xvdWQuc2Fhc3Bs
YXRmb3JtLnNhYXNzZXJ2aWNlbWdtdC52MS5Sb2xsb3V0QgPgQQJSB3JvbGxvdXQSJAoNdmFs
aWRhdGVfb25seRiFUiABKAhSDHZhbGlkYXRlT25seRIeCgpyZXF1ZXN0X2lkGIZSIAEoCVIJ
cmVxdWVzdElkIvEBChRVcGRhdGVSb2xsb3V0UmVxdWVzdBJVCgdyb2xsb3V0GIhSIAEoCzI1
Lmdvb2dsZS5jbG91ZC5zYWFzcGxhdGZvcm0uc2Fhc3NlcnZpY2VtZ210LnYxLlJvbGxvdXRC
A+BBAlIHcm9sbG91dBIkCg12YWxpZGF0ZV9vbmx5GIVSIAEoCFIMdmFsaWRhdGVPbmx5Eh4K
CnJlcXVlc3RfaWQYhlIgASgJUglyZXF1ZXN0SWQSPAoLdXBkYXRlX21hc2sYkFIgASgLMhou
Z29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayK2AQoURGVsZXRlUm9sbG91
dFJlcXVlc3QSQwoEbmFtZRiRTiABKAlCLuBBAvpBKAomc2Fhc3NlcnZpY2VtZ210Lmdvb2ds
ZWFwaXMuY29tL1JvbGxvdXRSBG5hbWUSEwoEZXRhZxjaTyABKAlSBGV0YWcSJAoNdmFsaWRh
dGVfb25seRiFUiABKAhSDHZhbGlkYXRlT25seRIeCgpyZXF1ZXN0X2lkGIZSIAEoCVIJcmVx
dWVzdElkItkBChdMaXN0Um9sbG91dEtpbmRzUmVxdWVzdBJLCgZwYXJlbnQYlk4gASgJQjLg
QQL6QSwSKnNhYXNzZXJ2aWNlbWdtdC5nb29nbGVhcGlzLmNvbS9Sb2xsb3V0S2luZFIGcGFy
ZW50EhwKCXBhZ2Vfc2l6ZRiJUiABKAVSCHBhZ2VTaXplEh4KCnBhZ2VfdG9rZW4YilIgASgJ
UglwYWdlVG9rZW4SFwoGZmlsdGVyGItSIAEoCVIGZmlsdGVyEhoKCG9yZGVyX2J5GIxSIAEo
CVIHb3JkZXJCeSLHAQoYTGlzdFJvbGxvdXRLaW5kc1Jlc3BvbnNlEl8KDXJvbGxvdXRfa2lu
ZHMYjVIgAygLMjkuZ29vZ2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQu
djEuUm9sbG91dEtpbmRSDHJvbGxvdXRLaW5kcxInCg9uZXh0X3BhZ2VfdG9rZW4YjlIgASgJ
Ug1uZXh0UGFnZVRva2VuEiEKC3VucmVhY2hhYmxlGI9SIAMoCVILdW5yZWFjaGFibGUiYAoV
R2V0Um9sbG91dEtpbmRSZXF1ZXN0EkcKBG5hbWUYkU4gASgJQjLgQQL6QSwKKnNhYXNzZXJ2
aWNlbWdtdC5nb29nbGVhcGlzLmNvbS9Sb2xsb3V0S2luZFIEbmFtZSK/AgoYQ3JlYXRlUm9s
bG91dEtpbmRSZXF1ZXN0EksKBnBhcmVudBiWTiABKAlCMuBBAvpBLBIqc2Fhc3NlcnZpY2Vt
Z210Lmdvb2dsZWFwaXMuY29tL1JvbGxvdXRLaW5kUgZwYXJlbnQSLAoPcm9sbG91dF9raW5k
X2lkGIdSIAEoCUID4EECUg1yb2xsb3V0S2luZElkEmIKDHJvbGxvdXRfa2luZBiIUiABKAsy
OS5nb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3JtLnNhYXNzZXJ2aWNlbWdtdC52MS5Sb2xsb3V0
S2luZEID4EECUgtyb2xsb3V0S2luZBIkCg12YWxpZGF0ZV9vbmx5GIVSIAEoCFIMdmFsaWRh
dGVPbmx5Eh4KCnJlcXVlc3RfaWQYhlIgASgJUglyZXF1ZXN0SWQiggIKGFVwZGF0ZVJvbGxv
dXRLaW5kUmVxdWVzdBJiCgxyb2xsb3V0X2tpbmQYiFIgASgLMjkuZ29vZ2xlLmNsb3VkLnNh
YXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjEuUm9sbG91dEtpbmRCA+BBAlILcm9sbG91
dEtpbmQSJAoNdmFsaWRhdGVfb25seRiFUiABKAhSDHZhbGlkYXRlT25seRIeCgpyZXF1ZXN0
X2lkGIZSIAEoCVIJcmVxdWVzdElkEjwKC3VwZGF0ZV9tYXNrGJBSIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sivgEKGERlbGV0ZVJvbGxvdXRLaW5kUmVx
dWVzdBJHCgRuYW1lGJFOIAEoCUIy4EEC+kEsCipzYWFzc2VydmljZW1nbXQuZ29vZ2xlYXBp
cy5jb20vUm9sbG91dEtpbmRSBG5hbWUSEwoEZXRhZxjaTyABKAlSBGV0YWcSJAoNdmFsaWRh
dGVfb25seRiFUiABKAhSDHZhbGlkYXRlT25seRIeCgpyZXF1ZXN0X2lkGIZSIAEoCVIJcmVx
dWVzdElkMvISCgxTYWFzUm9sbG91dHMS1AEKDExpc3RSb2xsb3V0cxJBLmdvb2dsZS5jbG91
ZC5zYWFzcGxhdGZvcm0uc2Fhc3NlcnZpY2VtZ210LnYxLkxpc3RSb2xsb3V0c1JlcXVlc3Qa
Qi5nb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3JtLnNhYXNzZXJ2aWNlbWdtdC52MS5MaXN0Um9s
bG91dHNSZXNwb25zZSI9gtPkkwIuEiwvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qfS9yb2xsb3V0c9pBBnBhcmVudBLBAQoKR2V0Um9sbG91dBI/Lmdvb2dsZS5jbG91ZC5z
YWFzcGxhdGZvcm0uc2Fhc3NlcnZpY2VtZ210LnYxLkdldFJvbGxvdXRSZXF1ZXN0GjUuZ29v
Z2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjEuUm9sbG91dCI7gtPk
kwIuEiwvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yb2xsb3V0cy8qfdpBBG5h
bWUS5QEKDUNyZWF0ZVJvbGxvdXQSQi5nb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3JtLnNhYXNz
ZXJ2aWNlbWdtdC52MS5DcmVhdGVSb2xsb3V0UmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5zYWFz
cGxhdGZvcm0uc2Fhc3NlcnZpY2VtZ210LnYxLlJvbGxvdXQiWYLT5JMCNyIsL3YxL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vcm9sbG91dHM6B3JvbGxvdXTaQRlwYXJlbnQs
cm9sbG91dCxyb2xsb3V0X2lkEucBCg1VcGRhdGVSb2xsb3V0EkIuZ29vZ2xlLmNsb3VkLnNh
YXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjEuVXBkYXRlUm9sbG91dFJlcXVlc3QaNS5n
b29nbGUuY2xvdWQuc2Fhc3BsYXRmb3JtLnNhYXNzZXJ2aWNlbWdtdC52MS5Sb2xsb3V0IluC
0+STAj8yNC92MS97cm9sbG91dC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcm9sbG91
dHMvKn06B3JvbGxvdXTaQRNyb2xsb3V0LHVwZGF0ZV9tYXNrEqgBCg1EZWxldGVSb2xsb3V0
EkIuZ29vZ2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjEuRGVsZXRl
Um9sbG91dFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiO4LT5JMCLiosL3YxL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcm9sbG91dHMvKn3aQQRuYW1lEuQBChBMaXN0
Um9sbG91dEtpbmRzEkUuZ29vZ2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1n
bXQudjEuTGlzdFJvbGxvdXRLaW5kc1JlcXVlc3QaRi5nb29nbGUuY2xvdWQuc2Fhc3BsYXRm
b3JtLnNhYXNzZXJ2aWNlbWdtdC52MS5MaXN0Um9sbG91dEtpbmRzUmVzcG9uc2UiQYLT5JMC
MhIwL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vcm9sbG91dEtpbmRz2kEG
cGFyZW50EtEBCg5HZXRSb2xsb3V0S2luZBJDLmdvb2dsZS5jbG91ZC5zYWFzcGxhdGZvcm0u
c2Fhc3NlcnZpY2VtZ210LnYxLkdldFJvbGxvdXRLaW5kUmVxdWVzdBo5Lmdvb2dsZS5jbG91
ZC5zYWFzcGxhdGZvcm0uc2Fhc3NlcnZpY2VtZ210LnYxLlJvbGxvdXRLaW5kIj+C0+STAjIS
MC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3JvbGxvdXRLaW5kcy8qfdpBBG5h
bWUShAIKEUNyZWF0ZVJvbGxvdXRLaW5kEkYuZ29vZ2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5z
YWFzc2VydmljZW1nbXQudjEuQ3JlYXRlUm9sbG91dEtpbmRSZXF1ZXN0GjkuZ29vZ2xlLmNs
b3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjEuUm9sbG91dEtpbmQibILT5JMC
QCIwL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vcm9sbG91dEtpbmRzOgxy
b2xsb3V0X2tpbmTaQSNwYXJlbnQscm9sbG91dF9raW5kLHJvbGxvdXRfa2luZF9pZBKGAgoR
VXBkYXRlUm9sbG91dEtpbmQSRi5nb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3JtLnNhYXNzZXJ2
aWNlbWdtdC52MS5VcGRhdGVSb2xsb3V0S2luZFJlcXVlc3QaOS5nb29nbGUuY2xvdWQuc2Fh
c3BsYXRmb3JtLnNhYXNzZXJ2aWNlbWdtdC52MS5Sb2xsb3V0S2luZCJugtPkkwJNMj0vdjEv
e3JvbGxvdXRfa2luZC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcm9sbG91dEtpbmRz
Lyp9Ogxyb2xsb3V0X2tpbmTaQRhyb2xsb3V0X2tpbmQsdXBkYXRlX21hc2sStAEKEURlbGV0
ZVJvbGxvdXRLaW5kEkYuZ29vZ2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1n
bXQudjEuRGVsZXRlUm9sbG91dEtpbmRSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5
Ij+C0+STAjIqMC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3JvbGxvdXRLaW5k
cy8qfdpBBG5hbWUaxwHKQR5zYWFzc2VydmljZW1nbXQuZ29vZ2xlYXBpcy5jb23SQaIBaHR0
cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL3NhYXNzZXJ2aWNlbWdtdC5yZWFkLXdyaXRlLGh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvc2Fhc3NlcnZpY2VtZ210LnJlYWRvbmx5QrsC
CjBjb20uZ29vZ2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjFCGFNh
YXNSb2xsb3V0c1NlcnZpY2VQcm90b1ABWlpjbG91ZC5nb29nbGUuY29tL2dvL3NhYXNwbGF0
Zm9ybS9zYWFzc2VydmljZW1nbXQvYXBpdjEvc2Fhc3NlcnZpY2VtZ210cGI7c2Fhc3NlcnZp
Y2VtZ210cGKqAixHb29nbGUuQ2xvdWQuU2Fhc1BsYXRmb3JtLlNhYXNTZXJ2aWNlTWdtdC5W
McoCLEdvb2dsZVxDbG91ZFxTYWFzUGxhdGZvcm1cU2Fhc1NlcnZpY2VNZ210XFYx6gIwR29v
Z2xlOjpDbG91ZDo6U2Fhc1BsYXRmb3JtOjpTYWFzU2VydmljZU1nbXQ6OlYxSuh5CgcSBQ4A
wAMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA1CgkKAgMA
EgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYATwoJCgID
BRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgBJCgkKAgglEgMaAEkKCAoBCBIDGwBxCgkKAggL
EgMbAHEKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA5CgkKAggIEgMdADkKCAoBCBID
HgBJCgkKAggBEgMeAEkKCAoBCBIDHwBKCgkKAggpEgMfAEoKCAoBCBIDIABJCgkKAggtEgMg
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
ARIXCg8KBQQAAgAIEgaFARiKAQMKEAoIBAACAAicCAASBIYBBCoKEQoHBAACAAifCBIGhwEE
iQEFCkAKBAQAAgESBI0BAhoaMiBUaGUgbWF4aW11bSBudW1iZXIgb2Ygcm9sbG91dHMgdG8g
c2VuZCBwZXIgcGFnZS4KCg0KBQQAAgEFEgSNAQIHCg0KBQQAAgEBEgSNAQgRCg0KBQQAAgED
EgSNARQZCokBCgQEAAICEgSRAQIcGnsgVGhlIHBhZ2UgdG9rZW46IElmIHRoZSBuZXh0X3Bh
Z2VfdG9rZW4gZnJvbSBhIHByZXZpb3VzIHJlc3BvbnNlCiBpcyBwcm92aWRlZCwgdGhpcyBy
ZXF1ZXN0IHdpbGwgc2VuZCB0aGUgc3Vic2VxdWVudCBwYWdlLgoKDQoFBAACAgUSBJEBAggK
DQoFBAACAgESBJEBCRMKDQoFBAACAgMSBJEBFhsKSwoEBAACAxIElAECGBo9IEZpbHRlciB0
aGUgbGlzdCBhcyBzcGVjaWZpZWQgaW4gaHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xNjAuCgoN
CgUEAAIDBRIElAECCAoNCgUEAAIDARIElAEJDwoNCgUEAAIDAxIElAESFwpJCgQEAAIEEgSX
AQIaGjsgT3JkZXIgcmVzdWx0cyBhcyBzcGVjaWZpZWQgaW4gaHR0cHM6Ly9nb29nbGUuYWlw
LmRldi8xMzIuCgoNCgUEAAIEBRIElwECCAoNCgUEAAIEARIElwEJEQoNCgUEAAIEAxIElwEU
GQpDCgIEARIGmwEApgEBGjUgVGhlIHJlc3BvbnNlIHN0cnVjdHVyZSBmb3IgdGhlIExpc3RS
b2xsb3V0cyBtZXRob2QuCgoLCgMEAQESBJsBCBwKJwoEBAECABIEnQECJBoZIFRoZSByZXN1
bHRpbmcgcm9sbG91dHMuCgoNCgUEAQIABBIEnQECCgoNCgUEAQIABhIEnQELEgoNCgUEAQIA
ARIEnQETGwoNCgUEAQIAAxIEnQEeIwqeAQoEBAECARIEogECIRqPASBJZiBwcmVzZW50LCB0
aGUgbmV4dCBwYWdlIHRva2VuIGNhbiBiZSBwcm92aWRlZCB0byBhIHN1YnNlcXVlbnQKIExp
c3RSb2xsb3V0cyBjYWxsIHRvIGxpc3QgdGhlIG5leHQgcGFnZS4KIElmIGVtcHR5LCB0aGVy
ZSBhcmUgbm8gbW9yZSBwYWdlcy4KCg0KBQQBAgEFEgSiAQIICg0KBQQBAgEBEgSiAQkYCg0K
BQQBAgEDEgSiARsgCjQKBAQBAgISBKUBAiYaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3Qg
YmUgcmVhY2hlZC4KCg0KBQQBAgIEEgSlAQIKCg0KBQQBAgIFEgSlAQsRCg0KBQQBAgIBEgSl
ARIdCg0KBQQBAgIDEgSlASAlCkAKAgQCEgapAQCxAQEaMiBUaGUgcmVxdWVzdCBzdHJ1Y3R1
cmUgZm9yIHRoZSBHZXRSb2xsb3V0IG1ldGhvZC4KCgsKAwQCARIEqQEIGQpPCgQEAgIAEgar
AQKwAQQaPyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHJlc291cmNlIHdp
dGhpbiBhIHNlcnZpY2UuCgoNCgUEAgIABRIEqwECCAoNCgUEAgIAARIEqwEJDQoNCgUEAgIA
AxIEqwEQFQoPCgUEAgIACBIGqwEWsAEDChAKCAQCAgAInAgAEgSsAQQqChEKBwQCAgAInwgS
Bq0BBK8BBQpDCgIEAxIGtAEA1QEBGjUgVGhlIHJlcXVlc3Qgc3RydWN0dXJlIGZvciB0aGUg
Q3JlYXRlUm9sbG91dCBtZXRob2QuCgoLCgMEAwESBLQBCBwKNgoEBAMCABIGtgECuwEEGiYg
UmVxdWlyZWQuIFRoZSBwYXJlbnQgb2YgdGhlIHJvbGxvdXQuCgoNCgUEAwIABRIEtgECCAoN
CgUEAwIAARIEtgEJDwoNCgUEAwIAAxIEtgESFwoPCgUEAwIACBIGtgEYuwEDChAKCAQDAgAI
nAgAEgS3AQQqChEKBwQDAgAInwgSBrgBBLoBBQo7CgQEAwIBEgS+AQJFGi0gUmVxdWlyZWQu
IFRoZSBJRCB2YWx1ZSBmb3IgdGhlIG5ldyByb2xsb3V0LgoKDQoFBAMCAQUSBL4BAggKDQoF
BAMCAQESBL4BCRMKDQoFBAMCAQMSBL4BFhsKDQoFBAMCAQgSBL4BHEQKEAoIBAMCAQicCAAS
BL4BHUMKPAoEBAMCAhIEwQECQxouIFJlcXVpcmVkLiBUaGUgZGVzaXJlZCBzdGF0ZSBmb3Ig
dGhlIHJvbGxvdXQuCgoNCgUEAwICBhIEwQECCQoNCgUEAwICARIEwQEKEQoNCgUEAwICAxIE
wQEUGQoNCgUEAwICCBIEwQEaQgoQCggEAwICCJwIABIEwQEbQQqaAQoEBAMCAxIExQECHRqL
ASBJZiAidmFsaWRhdGVfb25seSIgaXMgc2V0IHRvIHRydWUsIHRoZSBzZXJ2aWNlIHdpbGwg
dHJ5IHRvIHZhbGlkYXRlCiB0aGF0IHRoaXMgcmVxdWVzdCB3b3VsZCBzdWNjZWVkLCBidXQg
d2lsbCBub3QgYWN0dWFsbHkgbWFrZSBjaGFuZ2VzLgoKDQoFBAMCAwUSBMUBAgYKDQoFBAMC
AwESBMUBBxQKDQoFBAMCAwMSBMUBFxwKhQYKBAQDAgQSBNQBAhwa9gUgQW4gb3B0aW9uYWwg
cmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZSByZXF1
ZXN0IElECiBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNl
cnZlciB3aWxsIGtub3cgdG8gaWdub3JlCiB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFk
eSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsIGd1YXJhbnRlZQogdGhhdCBmb3Ig
YXQgbGVhc3QgNjAgbWludXRlcyBzaW5jZSB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhh
bXBsZSwgY29uc2lkZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCBy
ZXF1ZXN0IGFuZCB0aGUKIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVx
dWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBj
aGVjayBpZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3
YXMgcmVjZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0
LiBUaGlzIHByZXZlbnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1
cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQg
VVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0
ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEAwIEBRIE
1AECCAoNCgUEAwIEARIE1AEJEwoNCgUEAwIEAxIE1AEWGwpDCgIEBBIG2AEA+AEBGjUgVGhl
IHJlcXVlc3Qgc3RydWN0dXJlIGZvciB0aGUgVXBkYXRlUm9sbG91dCBtZXRob2QuCgoLCgME
BAESBNgBCBwKPAoEBAQCABIE2gECQxouIFJlcXVpcmVkLiBUaGUgZGVzaXJlZCBzdGF0ZSBm
b3IgdGhlIHJvbGxvdXQuCgoNCgUEBAIABhIE2gECCQoNCgUEBAIAARIE2gEKEQoNCgUEBAIA
AxIE2gEUGQoNCgUEBAIACBIE2gEaQgoQCggEBAIACJwIABIE2gEbQQqaAQoEBAQCARIE3gEC
HRqLASBJZiAidmFsaWRhdGVfb25seSIgaXMgc2V0IHRvIHRydWUsIHRoZSBzZXJ2aWNlIHdp
bGwgdHJ5IHRvIHZhbGlkYXRlCiB0aGF0IHRoaXMgcmVxdWVzdCB3b3VsZCBzdWNjZWVkLCBi
dXQgd2lsbCBub3QgYWN0dWFsbHkgbWFrZSBjaGFuZ2VzLgoKDQoFBAQCAQUSBN4BAgYKDQoF
BAQCAQESBN4BBxQKDQoFBAQCAQMSBN4BFxwKhQYKBAQEAgISBO0BAhwa9gUgQW4gb3B0aW9u
YWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZSBy
ZXF1ZXN0IElECiBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhl
IHNlcnZlciB3aWxsIGtub3cgdG8gaWdub3JlCiB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxy
ZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsIGd1YXJhbnRlZQogdGhhdCBm
b3IgYXQgbGVhc3QgNjAgbWludXRlcyBzaW5jZSB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3Ig
ZXhhbXBsZSwgY29uc2lkZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlh
bCByZXF1ZXN0IGFuZCB0aGUKIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUg
cmVxdWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNh
biBjaGVjayBpZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElE
CiB3YXMgcmVjZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1
ZXN0LiBUaGlzIHByZXZlbnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5n
IGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFs
aWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBw
b3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBAIC
BRIE7QECCAoNCgUEBAICARIE7QEJEwoNCgUEBAICAxIE7QEWGwrfAgoEBAQCAxIE9wECMBrQ
AiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0aGUgZmllbGRzIHRvIGJlIG92ZXJ3
cml0dGVuIGluIHRoZQogUm9sbG91dCByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgoKIFRoZSBm
aWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBhcmUgcmVsYXRpdmUgdG8gdGhl
IHJlc291cmNlLCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEgZmllbGQgd2lsbCBiZSBvdmVy
d3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4KCiBJZiB0aGUgdXNlciBkb2VzIG5vdCBw
cm92aWRlIGEgbWFzayB0aGVuIGFsbCBmaWVsZHMgaW4gdGhlCiBSb2xsb3V0IHdpbGwgYmUg
b3ZlcndyaXR0ZW4uCgoNCgUEBAIDBhIE9wECGwoNCgUEBAIDARIE9wEcJwoNCgUEBAIDAxIE
9wEqLwpDCgIEBRIG+wEAoAIBGjUgVGhlIHJlcXVlc3Qgc3RydWN0dXJlIGZvciB0aGUgRGVs
ZXRlUm9sbG91dCBtZXRob2QuCgoLCgMEBQESBPsBCBwKTwoEBAUCABIG/QECggIEGj8gUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSByZXNvdXJjZSB3aXRoaW4gYSBzZXJ2
aWNlLgoKDQoFBAUCAAUSBP0BAggKDQoFBAUCAAESBP0BCQ0KDQoFBAUCAAMSBP0BEBUKDwoF
BAUCAAgSBv0BFoICAwoQCggEBQIACJwIABIE/gEEKgoRCgcEBQIACJ8IEgb/AQSBAgUK0wMK
BAQFAgESBIwCAhYaxAMgVGhlIGV0YWcga25vd24gdG8gdGhlIGNsaWVudCBmb3IgdGhlIGV4
cGVjdGVkIHN0YXRlIG9mIHRoZSByb2xsb3V0LiBUaGlzIGlzCiB1c2VkIHdpdGggc3RhdGUt
Y2hhbmdpbmcgbWV0aG9kcyB0byBwcmV2ZW50IGFjY2lkZW50YWwgb3ZlcndyaXRlcyB3aGVu
CiBtdWx0aXBsZSB1c2VyIGFnZW50cyBtaWdodCBiZSBhY3RpbmcgaW4gcGFyYWxsZWwgb24g
dGhlIHNhbWUgcmVzb3VyY2UuCgogQW4gZXRhZyB3aWxkY2FyZCBwcm92aWRlIG9wdGltaXN0
aWMgY29uY3VycmVuY3kgYmFzZWQgb24gdGhlIGV4cGVjdGVkCiBleGlzdGVuY2Ugb2YgdGhl
IHJvbGxvdXQuIFRoZSBBbnkgd2lsZGNhcmQgKGAqYCkgcmVxdWlyZXMgdGhhdCB0aGUgcmVz
b3VyY2UKIG11c3QgYWxyZWFkeSBleGlzdHMsIGFuZCB0aGUgTm90IEFueSB3aWxkY2FyZCAo
YCEqYCkgcmVxdWlyZXMgdGhhdCBpdCBtdXN0CiBub3QuCgoNCgUEBQIBBRIEjAICCAoNCgUE
BQIBARIEjAIJDQoNCgUEBQIBAxIEjAIQFQqaAQoEBAUCAhIEkAICHRqLASBJZiAidmFsaWRh
dGVfb25seSIgaXMgc2V0IHRvIHRydWUsIHRoZSBzZXJ2aWNlIHdpbGwgdHJ5IHRvIHZhbGlk
YXRlCiB0aGF0IHRoaXMgcmVxdWVzdCB3b3VsZCBzdWNjZWVkLCBidXQgd2lsbCBub3QgYWN0
dWFsbHkgbWFrZSBjaGFuZ2VzLgoKDQoFBAUCAgUSBJACAgYKDQoFBAUCAgESBJACBxQKDQoF
BAUCAgMSBJACFxwKhQYKBAQFAgMSBJ8CAhwa9gUgQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0
byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZSByZXF1ZXN0IElECiBzbyB0
aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtu
b3cgdG8gaWdub3JlCiB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBs
ZXRlZC4gVGhlIHNlcnZlciB3aWxsIGd1YXJhbnRlZQogdGhhdCBmb3IgYXQgbGVhc3QgNjAg
bWludXRlcyBzaW5jZSB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgY29uc2lk
ZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCByZXF1ZXN0IGFuZCB0
aGUKIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3
aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBjaGVjayBpZiBvcmln
aW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3YXMgcmVjZWl2ZWQs
IGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZl
bnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21t
aXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRo
ZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAw
LTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBQIDBRIEnwICCAoNCgUEBQID
ARIEnwIJEwoNCgUEBQIDAxIEnwIWGwpGCgIEBhIGowIAuAIBGjggVGhlIHJlcXVlc3Qgc3Ry
dWN0dXJlIGZvciB0aGUgTGlzdFJvbGxvdXRLaW5kcyBtZXRob2QuCgoLCgMEBgESBKMCCB8K
OwoEBAYCABIGpQICqgIEGisgUmVxdWlyZWQuIFRoZSBwYXJlbnQgb2YgdGhlIHJvbGxvdXQg
a2luZC4KCg0KBQQGAgAFEgSlAgIICg0KBQQGAgABEgSlAgkPCg0KBQQGAgADEgSlAhIXCg8K
BQQGAgAIEgalAhiqAgMKEAoIBAYCAAicCAASBKYCBCoKEQoHBAYCAAifCBIGpwIEqQIFCkUK
BAQGAgESBK0CAhoaNyBUaGUgbWF4aW11bSBudW1iZXIgb2Ygcm9sbG91dCBraW5kcyB0byBz
ZW5kIHBlciBwYWdlLgoKDQoFBAYCAQUSBK0CAgcKDQoFBAYCAQESBK0CCBEKDQoFBAYCAQMS
BK0CFBkKiQEKBAQGAgISBLECAhwaeyBUaGUgcGFnZSB0b2tlbjogSWYgdGhlIG5leHRfcGFn
ZV90b2tlbiBmcm9tIGEgcHJldmlvdXMgcmVzcG9uc2UKIGlzIHByb3ZpZGVkLCB0aGlzIHJl
cXVlc3Qgd2lsbCBzZW5kIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgoNCgUEBgICBRIEsQICCAoN
CgUEBgICARIEsQIJEwoNCgUEBgICAxIEsQIWGwpLCgQEBgIDEgS0AgIYGj0gRmlsdGVyIHRo
ZSBsaXN0IGFzIHNwZWNpZmllZCBpbiBodHRwczovL2dvb2dsZS5haXAuZGV2LzE2MC4KCg0K
BQQGAgMFEgS0AgIICg0KBQQGAgMBEgS0AgkPCg0KBQQGAgMDEgS0AhIXCkkKBAQGAgQSBLcC
AhoaOyBPcmRlciByZXN1bHRzIGFzIHNwZWNpZmllZCBpbiBodHRwczovL2dvb2dsZS5haXAu
ZGV2LzEzMi4KCg0KBQQGAgQFEgS3AgIICg0KBQQGAgQBEgS3AgkRCg0KBQQGAgQDEgS3AhQZ
CkcKAgQHEga7AgDGAgEaOSBUaGUgcmVzcG9uc2Ugc3RydWN0dXJlIGZvciB0aGUgTGlzdFJv
bGxvdXRLaW5kcyBtZXRob2QuCgoLCgMEBwESBLsCCCAKLAoEBAcCABIEvQICLRoeIFRoZSBy
ZXN1bHRpbmcgcm9sbG91dCBraW5kcy4KCg0KBQQHAgAEEgS9AgIKCg0KBQQHAgAGEgS9AgsW
Cg0KBQQHAgABEgS9AhckCg0KBQQHAgADEgS9AicsCqIBCgQEBwIBEgTCAgIhGpMBIElmIHBy
ZXNlbnQsIHRoZSBuZXh0IHBhZ2UgdG9rZW4gY2FuIGJlIHByb3ZpZGVkIHRvIGEgc3Vic2Vx
dWVudAogTGlzdFJvbGxvdXRLaW5kcyBjYWxsIHRvIGxpc3QgdGhlIG5leHQgcGFnZS4KIElm
IGVtcHR5LCB0aGVyZSBhcmUgbm8gbW9yZSBwYWdlcy4KCg0KBQQHAgEFEgTCAgIICg0KBQQH
AgEBEgTCAgkYCg0KBQQHAgEDEgTCAhsgCjQKBAQHAgISBMUCAiYaJiBMb2NhdGlvbnMgdGhh
dCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQHAgIEEgTFAgIKCg0KBQQHAgIFEgTFAgsR
Cg0KBQQHAgIBEgTFAhIdCg0KBQQHAgIDEgTFAiAlCkQKAgQIEgbJAgDRAgEaNiBUaGUgcmVx
dWVzdCBzdHJ1Y3R1cmUgZm9yIHRoZSBHZXRSb2xsb3V0S2luZCBtZXRob2QuCgoLCgMECAES
BMkCCB0KTwoEBAgCABIGywIC0AIEGj8gUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSByZXNvdXJjZSB3aXRoaW4gYSBzZXJ2aWNlLgoKDQoFBAgCAAUSBMsCAggKDQoFBAgC
AAESBMsCCQ0KDQoFBAgCAAMSBMsCEBUKDwoFBAgCAAgSBssCFtACAwoQCggECAIACJwIABIE
zAIEKgoRCgcECAIACJ8IEgbNAgTPAgUKRwoCBAkSBtQCAPUCARo5IFRoZSByZXF1ZXN0IHN0
cnVjdHVyZSBmb3IgdGhlIENyZWF0ZVJvbGxvdXRLaW5kIG1ldGhvZC4KCgsKAwQJARIE1AII
IAo7CgQECQIAEgbWAgLbAgQaKyBSZXF1aXJlZC4gVGhlIHBhcmVudCBvZiB0aGUgcm9sbG91
dCBraW5kLgoKDQoFBAkCAAUSBNYCAggKDQoFBAkCAAESBNYCCQ8KDQoFBAkCAAMSBNYCEhcK
DwoFBAkCAAgSBtYCGNsCAwoQCggECQIACJwIABIE1wIEKgoRCgcECQIACJ8IEgbYAgTaAgUK
QAoEBAkCARIE3gICShoyIFJlcXVpcmVkLiBUaGUgSUQgdmFsdWUgZm9yIHRoZSBuZXcgcm9s
bG91dCBraW5kLgoKDQoFBAkCAQUSBN4CAggKDQoFBAkCAQESBN4CCRgKDQoFBAkCAQMSBN4C
GyAKDQoFBAkCAQgSBN4CIUkKEAoIBAkCAQicCAASBN4CIkgKQQoEBAkCAhIE4QICTBozIFJl
cXVpcmVkLiBUaGUgZGVzaXJlZCBzdGF0ZSBmb3IgdGhlIHJvbGxvdXQga2luZC4KCg0KBQQJ
AgIGEgThAgINCg0KBQQJAgIBEgThAg4aCg0KBQQJAgIDEgThAh0iCg0KBQQJAgIIEgThAiNL
ChAKCAQJAgIInAgAEgThAiRKCpoBCgQECQIDEgTlAgIdGosBIElmICJ2YWxpZGF0ZV9vbmx5
IiBpcyBzZXQgdG8gdHJ1ZSwgdGhlIHNlcnZpY2Ugd2lsbCB0cnkgdG8gdmFsaWRhdGUKIHRo
YXQgdGhpcyByZXF1ZXN0IHdvdWxkIHN1Y2NlZWQsIGJ1dCB3aWxsIG5vdCBhY3R1YWxseSBt
YWtlIGNoYW5nZXMuCgoNCgUECQIDBRIE5QICBgoNCgUECQIDARIE5QIHFAoNCgUECQIDAxIE
5QIXHAqFBgoEBAkCBBIE9AICHBr2BSBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50
aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlIHJlcXVlc3QgSUQKIHNvIHRoYXQgaWYg
eW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0byBp
Z25vcmUKIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBU
aGUgc2VydmVyIHdpbGwgZ3VhcmFudGVlCiB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVz
IHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNp
dHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kIHRoZQogcmVx
dWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhl
IHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9w
ZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlm
IHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNs
aWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRz
LgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2Vw
dGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0w
MDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQJAgQFEgT0AgIICg0KBQQJAgQBEgT0AgkT
Cg0KBQQJAgQDEgT0AhYbCkcKAgQKEgb4AgCYAwEaOSBUaGUgcmVxdWVzdCBzdHJ1Y3R1cmUg
Zm9yIHRoZSBVcGRhdGVSb2xsb3V0S2luZCBtZXRob2QuCgoLCgMECgESBPgCCCAKQQoEBAoC
ABIE+gICTBozIFJlcXVpcmVkLiBUaGUgZGVzaXJlZCBzdGF0ZSBmb3IgdGhlIHJvbGxvdXQg
a2luZC4KCg0KBQQKAgAGEgT6AgINCg0KBQQKAgABEgT6Ag4aCg0KBQQKAgADEgT6Ah0iCg0K
BQQKAgAIEgT6AiNLChAKCAQKAgAInAgAEgT6AiRKCpoBCgQECgIBEgT+AgIdGosBIElmICJ2
YWxpZGF0ZV9vbmx5IiBpcyBzZXQgdG8gdHJ1ZSwgdGhlIHNlcnZpY2Ugd2lsbCB0cnkgdG8g
dmFsaWRhdGUKIHRoYXQgdGhpcyByZXF1ZXN0IHdvdWxkIHN1Y2NlZWQsIGJ1dCB3aWxsIG5v
dCBhY3R1YWxseSBtYWtlIGNoYW5nZXMuCgoNCgUECgIBBRIE/gICBgoNCgUECgIBARIE/gIH
FAoNCgUECgIBAxIE/gIXHAqFBgoEBAoCAhIEjQMCHBr2BSBBbiBvcHRpb25hbCByZXF1ZXN0
IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlIHJlcXVlc3QgSUQK
IHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdp
bGwga25vdyB0byBpZ25vcmUKIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4g
Y29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwgZ3VhcmFudGVlCiB0aGF0IGZvciBhdCBsZWFz
dCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBj
b25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3Qg
YW5kIHRoZQogcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFn
YWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlm
IG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdhcyByZWNl
aXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMg
cHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRl
IGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdp
dGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAw
MDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQKAgIFEgSNAwIICg0K
BQQKAgIBEgSNAwkTCg0KBQQKAgIDEgSNAxYbCucCCgQECgIDEgSXAwIwGtgCIEZpZWxkIG1h
c2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUgb3ZlcndyaXR0ZW4gaW4g
dGhlCiBSb2xsb3V0S2luZCByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgoKIFRoZSBmaWVsZHMg
c3BlY2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBhcmUgcmVsYXRpdmUgdG8gdGhlIHJlc291
cmNlLCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEgZmllbGQgd2lsbCBiZSBvdmVyd3JpdHRl
biBpZiBpdCBpcyBpbiB0aGUgbWFzay4KCiBJZiB0aGUgdXNlciBkb2VzIG5vdCBwcm92aWRl
IGEgbWFzayB0aGVuIGFsbCBmaWVsZHMgaW4gdGhlCiBSb2xsb3V0S2luZCB3aWxsIGJlIG92
ZXJ3cml0dGVuLgoKDQoFBAoCAwYSBJcDAhsKDQoFBAoCAwESBJcDHCcKDQoFBAoCAwMSBJcD
Ki8KRwoCBAsSBpsDAMADARo5IFRoZSByZXF1ZXN0IHN0cnVjdHVyZSBmb3IgdGhlIERlbGV0
ZVJvbGxvdXRLaW5kIG1ldGhvZC4KCgsKAwQLARIEmwMIIApPCgQECwIAEgadAwKiAwQaPyBS
ZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHJlc291cmNlIHdpdGhpbiBhIHNl
cnZpY2UuCgoNCgUECwIABRIEnQMCCAoNCgUECwIAARIEnQMJDQoNCgUECwIAAxIEnQMQFQoP
CgUECwIACBIGnQMWogMDChAKCAQLAgAInAgAEgSeAwQqChEKBwQLAgAInwgSBp8DBKEDBQrd
AwoEBAsCARIErAMCFhrOAyBUaGUgZXRhZyBrbm93biB0byB0aGUgY2xpZW50IGZvciB0aGUg
ZXhwZWN0ZWQgc3RhdGUgb2YgdGhlIHJvbGxvdXQga2luZC4KIFRoaXMgaXMgdXNlZCB3aXRo
IHN0YXRlLWNoYW5naW5nIG1ldGhvZHMgdG8gcHJldmVudCBhY2NpZGVudGFsIG92ZXJ3cml0
ZXMKIHdoZW4gbXVsdGlwbGUgdXNlciBhZ2VudHMgbWlnaHQgYmUgYWN0aW5nIGluIHBhcmFs
bGVsIG9uIHRoZSBzYW1lIHJlc291cmNlLgoKIEFuIGV0YWcgd2lsZGNhcmQgcHJvdmlkZSBv
cHRpbWlzdGljIGNvbmN1cnJlbmN5IGJhc2VkIG9uIHRoZSBleHBlY3RlZAogZXhpc3RlbmNl
IG9mIHRoZSByb2xsb3V0IGtpbmQuIFRoZSBBbnkgd2lsZGNhcmQgKGAqYCkgcmVxdWlyZXMg
dGhhdCB0aGUKIHJlc291cmNlIG11c3QgYWxyZWFkeSBleGlzdHMsIGFuZCB0aGUgTm90IEFu
eSB3aWxkY2FyZCAoYCEqYCkgcmVxdWlyZXMgdGhhdAogaXQgbXVzdCBub3QuCgoNCgUECwIB
BRIErAMCCAoNCgUECwIBARIErAMJDQoNCgUECwIBAxIErAMQFQqaAQoEBAsCAhIEsAMCHRqL
ASBJZiAidmFsaWRhdGVfb25seSIgaXMgc2V0IHRvIHRydWUsIHRoZSBzZXJ2aWNlIHdpbGwg
dHJ5IHRvIHZhbGlkYXRlCiB0aGF0IHRoaXMgcmVxdWVzdCB3b3VsZCBzdWNjZWVkLCBidXQg
d2lsbCBub3QgYWN0dWFsbHkgbWFrZSBjaGFuZ2VzLgoKDQoFBAsCAgUSBLADAgYKDQoFBAsC
AgESBLADBxQKDQoFBAsCAgMSBLADFxwKhQYKBAQLAgMSBL8DAhwa9gUgQW4gb3B0aW9uYWwg
cmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZSByZXF1
ZXN0IElECiBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNl
cnZlciB3aWxsIGtub3cgdG8gaWdub3JlCiB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFk
eSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsIGd1YXJhbnRlZQogdGhhdCBmb3Ig
YXQgbGVhc3QgNjAgbWludXRlcyBzaW5jZSB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhh
bXBsZSwgY29uc2lkZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCBy
ZXF1ZXN0IGFuZCB0aGUKIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVx
dWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBj
aGVjayBpZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3
YXMgcmVjZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0
LiBUaGlzIHByZXZlbnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1
cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQg
VVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0
ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUECwIDBRIE
vwMCCAoNCgUECwIDARIEvwMJEwoNCgUECwIDAxIEvwMWG2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsRequest ===
    # Fields for ListRolloutsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsResponse ===
    # Fields for ListRolloutsResponse
    # Field: rollouts Type: 11 (.google.cloud.saasplatform.saasservicemgmt.v1.Rollout)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutRequest ===
    # Fields for GetRolloutRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutRequest ===
    # Fields for CreateRolloutRequest
    # Field: parent Type: 9 ()
    # Field: rollout_id Type: 9 ()
    # Field: rollout Type: 11 (.google.cloud.saasplatform.saasservicemgmt.v1.Rollout)
    # Field: validate_only Type: 8 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutRequest ===
    # Fields for UpdateRolloutRequest
    # Field: rollout Type: 11 (.google.cloud.saasplatform.saasservicemgmt.v1.Rollout)
    # Field: validate_only Type: 8 ()
    # Field: request_id Type: 9 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutRequest ===
    # Fields for DeleteRolloutRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsRequest ===
    # Fields for ListRolloutKindsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsResponse ===
    # Fields for ListRolloutKindsResponse
    # Field: rollout_kinds Type: 11 (.google.cloud.saasplatform.saasservicemgmt.v1.RolloutKind)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutKindRequest ===
    # Fields for GetRolloutKindRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutKindRequest ===
    # Fields for CreateRolloutKindRequest
    # Field: parent Type: 9 ()
    # Field: rollout_kind_id Type: 9 ()
    # Field: rollout_kind Type: 11 (.google.cloud.saasplatform.saasservicemgmt.v1.RolloutKind)
    # Field: validate_only Type: 8 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutKindRequest ===
    # Fields for UpdateRolloutKindRequest
    # Field: rollout_kind Type: 11 (.google.cloud.saasplatform.saasservicemgmt.v1.RolloutKind)
    # Field: validate_only Type: 8 ()
    # Field: request_id Type: 9 ()
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutKindRequest ===
    # Fields for DeleteRolloutKindRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: request_id Type: 9 ()

# === Service Client: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::SaasRolloutsClient ===
package Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::SaasRolloutsClient;

=pod

=head2 Service Client: Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::SaasRolloutsClient

Client stub representing the remote C<SaasRollouts> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<saasplatform.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'saasplatform.googleapis.com:443' );

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

sub list_rollouts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'ListRollouts',
        request        => $req,
        response_class => 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsResponse',
    });
}

sub get_rollout {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'GetRollout',
        request        => $req,
        response_class => 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout',
    });
}

sub create_rollout {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'CreateRollout',
        request        => $req,
        response_class => 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout',
    });
}

sub update_rollout {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'UpdateRollout',
        request        => $req,
        response_class => 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout',
    });
}

sub delete_rollout {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'DeleteRollout',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_rollout_kinds {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'ListRolloutKinds',
        request        => $req,
        response_class => 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsResponse',
    });
}

sub get_rollout_kind {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutKindRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'GetRolloutKind',
        request        => $req,
        response_class => 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind',
    });
}

sub create_rollout_kind {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutKindRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'CreateRolloutKind',
        request        => $req,
        response_class => 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind',
    });
}

sub update_rollout_kind {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutKindRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'UpdateRolloutKind',
        request        => $req,
        response_class => 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind',
    });
}

sub delete_rollout_kind {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutKindRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.saasplatform.saasservicemgmt.v1.SaasRollouts',
        method         => 'DeleteRolloutKind',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService - Compiled Protocol Buffers messages for google/cloud/saasplatform/saasservicemgmt/v1/rollouts_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService;

    my $msg = Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/saasplatform/saasservicemgmt/v1/rollouts_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsRequest

The request structure for the ListRollouts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the rollout.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of rollouts to send per page.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The page token: If the next_page_token from a previous response
is provided, this request will send the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter the list as specified in https://google.aip.dev/160.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Order results as specified in https://google.aip.dev/132.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsResponse

The response structure for the ListRollouts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rollouts() >> / C<< $msg->rollouts($value) >>

Type: C<Message> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout>)

The resulting rollouts.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If present, the next page token can be provided to a subsequent
ListRollouts call to list the next page.
If empty, there are no more pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutRequest

The request structure for the GetRollout method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the resource within a service.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutRequest

The request structure for the CreateRollout method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the rollout.

=item * C<< $msg->rollout_id() >> / C<< $msg->rollout_id($value) >>

Type: C<String>

Required. The ID value for the new rollout.

=item * C<< $msg->rollout() >> / C<< $msg->rollout($value) >>

Type: C<Message> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout>)

Required. The desired state for the rollout.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If "validate_only" is set to true, the service will try to validate
that this request would succeed, but will not actually make changes.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutRequest

The request structure for the UpdateRollout method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rollout() >> / C<< $msg->rollout($value) >>

Type: C<Message> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout>)

Required. The desired state for the rollout.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If "validate_only" is set to true, the service will try to validate
that this request would succeed, but will not actually make changes.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Field mask is used to specify the fields to be overwritten in the
Rollout resource by the update.

The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask.

If the user does not provide a mask then all fields in the
Rollout will be overwritten.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutRequest

The request structure for the DeleteRollout method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the resource within a service.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

The etag known to the client for the expected state of the rollout. This is
used with state-changing methods to prevent accidental overwrites when
multiple user agents might be acting in parallel on the same resource.

An etag wildcard provide optimistic concurrency based on the expected
existence of the rollout. The Any wildcard (`*`) requires that the resource
must already exists, and the Not Any wildcard (`!*`) requires that it must
not.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If "validate_only" is set to true, the service will try to validate
that this request would succeed, but will not actually make changes.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsRequest

The request structure for the ListRolloutKinds method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the rollout kind.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of rollout kinds to send per page.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The page token: If the next_page_token from a previous response
is provided, this request will send the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter the list as specified in https://google.aip.dev/160.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Order results as specified in https://google.aip.dev/132.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsResponse

The response structure for the ListRolloutKinds method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rollout_kinds() >> / C<< $msg->rollout_kinds($value) >>

Type: C<Message> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind>)

The resulting rollout kinds.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If present, the next page token can be provided to a subsequent
ListRolloutKinds call to list the next page.
If empty, there are no more pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutKindRequest

The request structure for the GetRolloutKind method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the resource within a service.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutKindRequest

The request structure for the CreateRolloutKind method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the rollout kind.

=item * C<< $msg->rollout_kind_id() >> / C<< $msg->rollout_kind_id($value) >>

Type: C<String>

Required. The ID value for the new rollout kind.

=item * C<< $msg->rollout_kind() >> / C<< $msg->rollout_kind($value) >>

Type: C<Message> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind>)

Required. The desired state for the rollout kind.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If "validate_only" is set to true, the service will try to validate
that this request would succeed, but will not actually make changes.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutKindRequest

The request structure for the UpdateRolloutKind method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rollout_kind() >> / C<< $msg->rollout_kind($value) >>

Type: C<Message> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind>)

Required. The desired state for the rollout kind.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If "validate_only" is set to true, the service will try to validate
that this request would succeed, but will not actually make changes.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Field mask is used to specify the fields to be overwritten in the
RolloutKind resource by the update.

The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask.

If the user does not provide a mask then all fields in the
RolloutKind will be overwritten.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutKindRequest

The request structure for the DeleteRolloutKind method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the resource within a service.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

The etag known to the client for the expected state of the rollout kind.
This is used with state-changing methods to prevent accidental overwrites
when multiple user agents might be acting in parallel on the same resource.

An etag wildcard provide optimistic concurrency based on the expected
existence of the rollout kind. The Any wildcard (`*`) requires that the
resource must already exists, and the Not Any wildcard (`!*`) requires that
it must not.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

If "validate_only" is set to true, the service will try to validate
that this request would succeed, but will not actually make changes.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional request ID to identify requests. Specify a unique request ID
so that if you must retry your request, the server will know to ignore
the request if it has already been completed. The server will guarantee
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
