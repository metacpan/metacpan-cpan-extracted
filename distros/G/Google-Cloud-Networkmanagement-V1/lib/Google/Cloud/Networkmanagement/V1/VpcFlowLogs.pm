package Google::Cloud::Networkmanagement::V1::VpcFlowLogs;

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
    eval { require Google::Cloud::Networkmanagement::V1::Reachability };
    eval { require Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvbmV0d29ya21hbmFnZW1lbnQvdjEvdnBjX2Zsb3dfbG9ncy5wcm90
bxIhZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo0Z29vZ2xlL2Ns
b3VkL25ldHdvcmttYW5hZ2VtZW50L3YxL3JlYWNoYWJpbGl0eS5wcm90bxo8Z29vZ2xlL2Ns
b3VkL25ldHdvcmttYW5hZ2VtZW50L3YxL3ZwY19mbG93X2xvZ3NfY29uZmlnLnByb3RvGiNn
b29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2Vt
cHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byL2AQodTGlzdFZw
Y0Zsb3dMb2dzQ29uZmlnc1JlcXVlc3QSUgoGcGFyZW50GAEgASgJQjrgQQL6QTQSMm5ldHdv
cmttYW5hZ2VtZW50Lmdvb2dsZWFwaXMuY29tL1ZwY0Zsb3dMb2dzQ29uZmlnUgZwYXJlbnQS
IAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlC
A+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJf
YnkYBSABKAlCA+BBAVIHb3JkZXJCeSLTAQoeTGlzdFZwY0Zsb3dMb2dzQ29uZmlnc1Jlc3Bv
bnNlEmcKFXZwY19mbG93X2xvZ3NfY29uZmlncxgBIAMoCzI0Lmdvb2dsZS5jbG91ZC5uZXR3
b3JrbWFuYWdlbWVudC52MS5WcGNGbG93TG9nc0NvbmZpZ1ISdnBjRmxvd0xvZ3NDb25maWdz
EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJs
ZRgDIAMoCVILdW5yZWFjaGFibGUibQobR2V0VnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0Ek4K
BG5hbWUYASABKAlCOuBBAvpBNAoybmV0d29ya21hbmFnZW1lbnQuZ29vZ2xlYXBpcy5jb20v
VnBjRmxvd0xvZ3NDb25maWdSBG5hbWUi0gIKHkNyZWF0ZVZwY0Zsb3dMb2dzQ29uZmlnUmVx
dWVzdBJSCgZwYXJlbnQYASABKAlCOuBBAvpBNBIybmV0d29ya21hbmFnZW1lbnQuZ29vZ2xl
YXBpcy5jb20vVnBjRmxvd0xvZ3NDb25maWdSBnBhcmVudBJwChd2cGNfZmxvd19sb2dzX2Nv
bmZpZ19pZBgCIAEoCUI64EEC+kE0CjJuZXR3b3JrbWFuYWdlbWVudC5nb29nbGVhcGlzLmNv
bS9WcGNGbG93TG9nc0NvbmZpZ1ITdnBjRmxvd0xvZ3NDb25maWdJZBJqChR2cGNfZmxvd19s
b2dzX2NvbmZpZxgDIAEoCzI0Lmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MS5W
cGNGbG93TG9nc0NvbmZpZ0ID4EECUhF2cGNGbG93TG9nc0NvbmZpZyLOAQoeVXBkYXRlVnBj
Rmxvd0xvZ3NDb25maWdSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrEmoKFHZwY19mbG93X2xvZ3NfY29u
ZmlnGAIgASgLMjQuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLlZwY0Zsb3dM
b2dzQ29uZmlnQgPgQQJSEXZwY0Zsb3dMb2dzQ29uZmlnInAKHkRlbGV0ZVZwY0Zsb3dMb2dz
Q29uZmlnUmVxdWVzdBJOCgRuYW1lGAEgASgJQjrgQQL6QTQKMm5ldHdvcmttYW5hZ2VtZW50
Lmdvb2dsZWFwaXMuY29tL1ZwY0Zsb3dMb2dzQ29uZmlnUgRuYW1lItoBCiFRdWVyeU9yZ1Zw
Y0Zsb3dMb2dzQ29uZmlnc1JlcXVlc3QSUgoGcGFyZW50GAEgASgJQjrgQQL6QTQSMm5ldHdv
cmttYW5hZ2VtZW50Lmdvb2dsZWFwaXMuY29tL1ZwY0Zsb3dMb2dzQ29uZmlnUgZwYXJlbnQS
IAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlC
A+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIi1wEKIlF1ZXJ5
T3JnVnBjRmxvd0xvZ3NDb25maWdzUmVzcG9uc2USZwoVdnBjX2Zsb3dfbG9nc19jb25maWdz
GAEgAygLMjQuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLlZwY0Zsb3dMb2dz
Q29uZmlnUhJ2cGNGbG93TG9nc0NvbmZpZ3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1u
ZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSL9AQojU2hv
d0VmZmVjdGl2ZUZsb3dMb2dzQ29uZmlnc1JlcXVlc3QSUgoGcGFyZW50GAEgASgJQjrgQQL6
QTQSMm5ldHdvcmttYW5hZ2VtZW50Lmdvb2dsZWFwaXMuY29tL1ZwY0Zsb3dMb2dzQ29uZmln
UgZwYXJlbnQSHwoIcmVzb3VyY2UYAiABKAlCA+BBAlIIcmVzb3VyY2USIAoJcGFnZV9zaXpl
GAMgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YBCABKAlCA+BBAVIJcGFnZVRv
a2VuEhsKBmZpbHRlchgFIAEoCUID4EEBUgZmaWx0ZXIi7gEKJFNob3dFZmZlY3RpdmVGbG93
TG9nc0NvbmZpZ3NSZXNwb25zZRJ8ChtlZmZlY3RpdmVfZmxvd19sb2dzX2NvbmZpZ3MYASAD
KAsyPS5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuRWZmZWN0aXZlVnBjRmxv
d0xvZ3NDb25maWdSGGVmZmVjdGl2ZUZsb3dMb2dzQ29uZmlncxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hh
YmxlMoIQChJWcGNGbG93TG9nc1NlcnZpY2US5gEKFkxpc3RWcGNGbG93TG9nc0NvbmZpZ3MS
QC5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuTGlzdFZwY0Zsb3dMb2dzQ29u
Zmlnc1JlcXVlc3QaQS5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuTGlzdFZw
Y0Zsb3dMb2dzQ29uZmlnc1Jlc3BvbnNlIkeC0+STAjgSNi92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyp9L3ZwY0Zsb3dMb2dzQ29uZmlnc9pBBnBhcmVudBLTAQoUR2V0VnBj
Rmxvd0xvZ3NDb25maWcSPi5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuR2V0
VnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0GjQuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2Vt
ZW50LnYxLlZwY0Zsb3dMb2dzQ29uZmlnIkWC0+STAjgSNi92MS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL3ZwY0Zsb3dMb2dzQ29uZmlncy8qfdpBBG5hbWUS0wIKF0NyZWF0ZVZw
Y0Zsb3dMb2dzQ29uZmlnEkEuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLkNy
ZWF0ZVZwY0Zsb3dMb2dzQ29uZmlnUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVy
YXRpb24i1QGC0+STAk4iNi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3Zw
Y0Zsb3dMb2dzQ29uZmlnczoUdnBjX2Zsb3dfbG9nc19jb25maWfaQTNwYXJlbnQsdnBjX2Zs
b3dfbG9nc19jb25maWcsdnBjX2Zsb3dfbG9nc19jb25maWdfaWTKQUgKEVZwY0Zsb3dMb2dz
Q29uZmlnEjNnb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuT3BlcmF0aW9uTWV0
YWRhdGES1QIKF1VwZGF0ZVZwY0Zsb3dMb2dzQ29uZmlnEkEuZ29vZ2xlLmNsb3VkLm5ldHdv
cmttYW5hZ2VtZW50LnYxLlVwZGF0ZVZwY0Zsb3dMb2dzQ29uZmlnUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24i1wGC0+STAmMySy92MS97dnBjX2Zsb3dfbG9nc19j
b25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3ZwY0Zsb3dMb2dzQ29uZmlncy8q
fToUdnBjX2Zsb3dfbG9nc19jb25maWfaQSB2cGNfZmxvd19sb2dzX2NvbmZpZyx1cGRhdGVf
bWFza8pBSAoRVnBjRmxvd0xvZ3NDb25maWcSM2dvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdl
bWVudC52MS5PcGVyYXRpb25NZXRhZGF0YRKSAgoXRGVsZXRlVnBjRmxvd0xvZ3NDb25maWcS
QS5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuRGVsZXRlVnBjRmxvd0xvZ3ND
b25maWdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKUAYLT5JMCOCo2
L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovdnBjRmxvd0xvZ3NDb25maWdzLyp9
2kEEbmFtZcpBTAoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EjNnb29nbGUuY2xvdWQubmV0d29y
a21hbmFnZW1lbnQudjEuT3BlcmF0aW9uTWV0YWRhdGEShAIKGlF1ZXJ5T3JnVnBjRmxvd0xv
Z3NDb25maWdzEkQuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLlF1ZXJ5T3Jn
VnBjRmxvd0xvZ3NDb25maWdzUmVxdWVzdBpFLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdl
bWVudC52MS5RdWVyeU9yZ1ZwY0Zsb3dMb2dzQ29uZmlnc1Jlc3BvbnNlIlmC0+STAlMSUS92
MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3ZwY0Zsb3dMb2dzQ29uZmlnczpx
dWVyeU9yZ1ZwY0Zsb3dMb2dzQ29uZmlncxKMAgocU2hvd0VmZmVjdGl2ZUZsb3dMb2dzQ29u
ZmlncxJGLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MS5TaG93RWZmZWN0aXZl
Rmxvd0xvZ3NDb25maWdzUmVxdWVzdBpHLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVu
dC52MS5TaG93RWZmZWN0aXZlRmxvd0xvZ3NDb25maWdzUmVzcG9uc2UiW4LT5JMCVRJTL3Yx
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vdnBjRmxvd0xvZ3NDb25maWdzOnNo
b3dFZmZlY3RpdmVGbG93TG9nc0NvbmZpZ3MaVMpBIG5ldHdvcmttYW5hZ2VtZW50Lmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybTKRDAoeT3JnYW5pemF0aW9uVnBjRmxvd0xvZ3NTZXJ2aWNlEusBChZMaXN0VnBjRmxv
d0xvZ3NDb25maWdzEkAuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLkxpc3RW
cGNGbG93TG9nc0NvbmZpZ3NSZXF1ZXN0GkEuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2Vt
ZW50LnYxLkxpc3RWcGNGbG93TG9nc0NvbmZpZ3NSZXNwb25zZSJMgtPkkwI9EjsvdjEve3Bh
cmVudD1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyp9L3ZwY0Zsb3dMb2dzQ29uZmlnc9pB
BnBhcmVudBLYAQoUR2V0VnBjRmxvd0xvZ3NDb25maWcSPi5nb29nbGUuY2xvdWQubmV0d29y
a21hbmFnZW1lbnQudjEuR2V0VnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0GjQuZ29vZ2xlLmNs
b3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLlZwY0Zsb3dMb2dzQ29uZmlnIkqC0+STAj0SOy92
MS97bmFtZT1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyovdnBjRmxvd0xvZ3NDb25maWdz
Lyp92kEEbmFtZRLYAgoXQ3JlYXRlVnBjRmxvd0xvZ3NDb25maWcSQS5nb29nbGUuY2xvdWQu
bmV0d29ya21hbmFnZW1lbnQudjEuQ3JlYXRlVnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLaAYLT5JMCUyI7L3YxL3twYXJlbnQ9b3Jn
YW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qfS92cGNGbG93TG9nc0NvbmZpZ3M6FHZwY19mbG93
X2xvZ3NfY29uZmln2kEzcGFyZW50LHZwY19mbG93X2xvZ3NfY29uZmlnLHZwY19mbG93X2xv
Z3NfY29uZmlnX2lkykFIChFWcGNGbG93TG9nc0NvbmZpZxIzZ29vZ2xlLmNsb3VkLm5ldHdv
cmttYW5hZ2VtZW50LnYxLk9wZXJhdGlvbk1ldGFkYXRhEtoCChdVcGRhdGVWcGNGbG93TG9n
c0NvbmZpZxJBLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MS5VcGRhdGVWcGNG
bG93TG9nc0NvbmZpZ1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uItwB
gtPkkwJoMlAvdjEve3ZwY19mbG93X2xvZ3NfY29uZmlnLm5hbWU9b3JnYW5pemF0aW9ucy8q
L2xvY2F0aW9ucy8qL3ZwY0Zsb3dMb2dzQ29uZmlncy8qfToUdnBjX2Zsb3dfbG9nc19jb25m
aWfaQSB2cGNfZmxvd19sb2dzX2NvbmZpZyx1cGRhdGVfbWFza8pBSAoRVnBjRmxvd0xvZ3ND
b25maWcSM2dvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MS5PcGVyYXRpb25NZXRh
ZGF0YRKXAgoXRGVsZXRlVnBjRmxvd0xvZ3NDb25maWcSQS5nb29nbGUuY2xvdWQubmV0d29y
a21hbmFnZW1lbnQudjEuRGVsZXRlVnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0Gh0uZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbiKZAYLT5JMCPSo7L3YxL3tuYW1lPW9yZ2FuaXphdGlv
bnMvKi9sb2NhdGlvbnMvKi92cGNGbG93TG9nc0NvbmZpZ3MvKn3aQQRuYW1lykFMChVnb29n
bGUucHJvdG9idWYuRW1wdHkSM2dvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MS5P
cGVyYXRpb25NZXRhZGF0YRpUykEgbmV0d29ya21hbmFnZW1lbnQuZ29vZ2xlYXBpcy5jb23S
QS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQv8BCiVj
b20uZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxQhBWcGNGbG93TG9nc1Byb3Rv
UAFaU2Nsb3VkLmdvb2dsZS5jb20vZ28vbmV0d29ya21hbmFnZW1lbnQvYXBpdjEvbmV0d29y
a21hbmFnZW1lbnRwYjtuZXR3b3JrbWFuYWdlbWVudHBiqgIhR29vZ2xlLkNsb3VkLk5ldHdv
cmtNYW5hZ2VtZW50LlYxygIhR29vZ2xlXENsb3VkXE5ldHdvcmtNYW5hZ2VtZW50XFYx6gIk
R29vZ2xlOjpDbG91ZDo6TmV0d29ya01hbmFnZW1lbnQ6OlYxSsFpCgcSBQ4AxQMBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACYKCQoC
AwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPgoJCgIDBRIDFwBGCgkK
AgMGEgMYAC0KCQoCAwcSAxkAJQoJCgIDCBIDGgAqCggKAQgSAxwAPgoJCgIIJRIDHAA+CggK
AQgSAx0AagoJCgIICxIDHQBqCggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8AMQoJCgII
CBIDHwAxCggKAQgSAyAAPgoJCgIIARIDIAA+CggKAQgSAyEAPgoJCgIIKRIDIQA+CggKAQgS
AyIAPQoJCgIILRIDIgA9CtoBCgIGABIFJwCVAQEazAEgVGhlIFZQQyBGbG93IExvZ3Mgc2Vy
dmljZSBpbiB0aGUgR29vZ2xlIENsb3VkIE5ldHdvcmsgTWFuYWdlbWVudCBBUEkgcHJvdmlk
ZXMKIGNvbmZpZ3VyYXRpb25zIHRoYXQgZ2VuZXJhdGUgRmxvdyBMb2dzLiBUaGUgc2Vydmlj
ZSBhbmQgdGhlIGNvbmZpZ3VyYXRpb24KIHJlc291cmNlcyBjcmVhdGVkIHVzaW5nIHRoaXMg
c2VydmljZSBhcmUgZ2xvYmFsLgoKCgoDBgABEgMnCBoKCgoDBgADEgMoAkgKDAoFBgADmQgS
AygCSAoLCgMGAAMSBCkCKjcKDQoFBgADmggSBCkCKjcKQgoEBgACABIELQIzAxo0IExpc3Rz
IGFsbCBgVnBjRmxvd0xvZ3NDb25maWdzYCBpbiBhIGdpdmVuIHByb2plY3QuCgoMCgUGAAIA
ARIDLQYcCgwKBQYAAgACEgMtHToKDAoFBgACAAMSAy4PLQoNCgUGAAIABBIELwQxBgoRCgkG
AAIABLDKvCISBC8EMQYKDAoFBgACAAQSAzIENAoPCggGAAIABJsIABIDMgQ0CkMKBAYAAgES
BDYCPAMaNSBHZXRzIHRoZSBkZXRhaWxzIG9mIGEgc3BlY2lmaWMgYFZwY0Zsb3dMb2dzQ29u
ZmlnYC4KCgwKBQYAAgEBEgM2BhoKDAoFBgACAQISAzYbNgoMCgUGAAIBAxIDNw8gCg0KBQYA
AgEEEgQ4BDoGChEKCQYAAgEEsMq8IhIEOAQ6BgoMCgUGAAIBBBIDOwQyCg8KCAYAAgEEmwgA
EgM7BDIKvgQKBAYAAgISBE0CWQMarwQgQ3JlYXRlcyBhIG5ldyBgVnBjRmxvd0xvZ3NDb25m
aWdgLgogSWYgYSBjb25maWd1cmF0aW9uIHdpdGggdGhlIGV4YWN0IHNhbWUgc2V0dGluZ3Mg
YWxyZWFkeSBleGlzdHMgKGV2ZW4gaWYgdGhlCiBJRCBpcyBkaWZmZXJlbnQpLCB0aGUgY3Jl
YXRpb24gZmFpbHMuCiBOb3RlczoKCiAgIDEuIENyZWF0aW5nIGEgY29uZmlndXJhdGlvbiB3
aXRoIGBzdGF0ZT1ESVNBQkxFRGAgd2lsbCBmYWlsCiAgIDIuIFRoZSBmb2xsb3dpbmcgZmll
bGRzIGFyZSBub3QgY29uc2lkZXJlZCBhcyBzZXR0aW5ncyBmb3IgdGhlIHB1cnBvc2UKICAg
b2YgdGhlIGNoZWNrIG1lbnRpb25lZCBhYm92ZSwgdGhlcmVmb3JlIC0gY3JlYXRpbmcgYW5v
dGhlciBjb25maWd1cmF0aW9uCiAgIHdpdGggdGhlIHNhbWUgZmllbGRzIGJ1dCBkaWZmZXJl
bnQgdmFsdWVzIGZvciB0aGUgZm9sbG93aW5nIGZpZWxkcyB3aWxsCiAgIGZhaWwgYXMgd2Vs
bDoKICAgICAgICogbmFtZQogICAgICAgKiBjcmVhdGVfdGltZQogICAgICAgKiB1cGRhdGVf
dGltZQogICAgICAgKiBsYWJlbHMKICAgICAgICogZGVzY3JpcHRpb24KCgwKBQYAAgIBEgNN
Bh0KDAoFBgACAgISA00ePAoMCgUGAAICAxIDTg8rCg0KBQYAAgIEEgRPBFIGChEKCQYAAgIE
sMq8IhIETwRSBgoNCgUGAAICBBIEUwRUPgoQCggGAAICBJsIABIEUwRUPgoNCgUGAAICBBIE
VQRYBgoPCgcGAAICBJkIEgRVBFgGCsUECgQGAAIDEgRqAnUDGrYEIFVwZGF0ZXMgYW4gZXhp
c3RpbmcgYFZwY0Zsb3dMb2dzQ29uZmlnYC4KIElmIGEgY29uZmlndXJhdGlvbiB3aXRoIHRo
ZSBleGFjdCBzYW1lIHNldHRpbmdzIGFscmVhZHkgZXhpc3RzIChldmVuIGlmIHRoZQogSUQg
aXMgZGlmZmVyZW50KSwgdGhlIGNyZWF0aW9uIGZhaWxzLgogTm90ZXM6CgogICAxLiBVcGRh
dGluZyBhIGNvbmZpZ3VyYXRpb24gd2l0aCBgc3RhdGU9RElTQUJMRURgIHdpbGwgZmFpbC4K
ICAgMi4gVGhlIGZvbGxvd2luZyBmaWVsZHMgYXJlIG5vdCBjb25zaWRlcmVkIGFzIHNldHRp
bmdzIGZvciB0aGUgcHVycG9zZQogICBvZiB0aGUgY2hlY2sgbWVudGlvbmVkIGFib3ZlLCB0
aGVyZWZvcmUgLSB1cGRhdGluZyBhbm90aGVyIGNvbmZpZ3VyYXRpb24KICAgd2l0aCB0aGUg
c2FtZSBmaWVsZHMgYnV0IGRpZmZlcmVudCB2YWx1ZXMgZm9yIHRoZSBmb2xsb3dpbmcgZmll
bGRzIHdpbGwKICAgZmFpbCBhcyB3ZWxsOgogICAgICAgKiBuYW1lCiAgICAgICAqIGNyZWF0
ZV90aW1lCiAgICAgICAqIHVwZGF0ZV90aW1lCiAgICAgICAqIGxhYmVscwogICAgICAgKiBk
ZXNjcmlwdGlvbgoKDAoFBgACAwESA2oGHQoMCgUGAAIDAhIDah48CgwKBQYAAgMDEgNrDysK
DQoFBgACAwQSBGwEbwYKEQoJBgACAwSwyrwiEgRsBG8GCgwKBQYAAgMEEgNwBE4KDwoIBgAC
AwSbCAASA3AETgoNCgUGAAIDBBIEcQR0BgoPCgcGAAIDBJkIEgRxBHQGCjgKBAYAAgQSBXgC
ggEDGikgRGVsZXRlcyBhIHNwZWNpZmljIGBWcGNGbG93TG9nc0NvbmZpZ2AuCgoMCgUGAAIE
ARIDeAYdCgwKBQYAAgQCEgN4HjwKDAoFBgACBAMSA3kPKwoNCgUGAAIEBBIEegR8BgoRCgkG
AAIEBLDKvCISBHoEfAYKDAoFBgACBAQSA30EMgoPCggGAAIEBJsIABIDfQQyCg4KBQYAAgQE
EgV+BIEBBgoQCgcGAAIEBJkIEgV+BIEBBgqZAQoEBgACBRIGhgECiwEDGogBIFF1ZXJ5T3Jn
VnBjRmxvd0xvZ3NDb25maWdzIHJldHVybnMgYSBsaXN0IG9mIGFsbCBvcmdhbml6YXRpb24t
bGV2ZWwgVlBDCiBGbG93IExvZ3MgY29uZmlndXJhdGlvbnMgYXBwbGljYWJsZSB0byB0aGUg
c3BlY2lmaWVkIHByb2plY3QuCgoNCgUGAAIFARIEhgEGIAoNCgUGAAIFAhIEhgEhQgoNCgUG
AAIFAxIEhwEPMQoPCgUGAAIFBBIGiAEEigEGChMKCQYAAgUEsMq8IhIGiAEEigEGCoYBCgQG
AAIGEgaPAQKUAQMadiBTaG93RWZmZWN0aXZlRmxvd0xvZ3NDb25maWdzIHJldHVybnMgYSBs
aXN0IG9mIGFsbCBWUEMgRmxvdyBMb2dzCiBjb25maWd1cmF0aW9ucyBhcHBsaWNhYmxlIHRv
IGEgc3BlY2lmaWVkIHJlc291cmNlLgoKDQoFBgACBgESBI8BBiIKDQoFBgACBgISBI8BI0YK
DQoFBgACBgMSBJABDzMKDwoFBgACBgQSBpEBBJMBBgoTCgkGAAIGBLDKvCISBpEBBJMBBgr8
AQoCBgESBpsBAPcBARrtASBUaGUgVlBDIEZsb3cgTG9ncyBvcmdhbml6YXRpb24gc2Vydmlj
ZSBpbiB0aGUgR29vZ2xlIENsb3VkIE5ldHdvcmsgTWFuYWdlbWVudAogQVBJIHByb3ZpZGVz
IG9yZ2FuaXphdGlvbiBsZXZlbCBjb25maWd1cmF0aW9ucyB0aGF0IGdlbmVyYXRlIEZsb3cg
TG9ncy4gVGhlCiBzZXJ2aWNlIGFuZCB0aGUgY29uZmlndXJhdGlvbiByZXNvdXJjZXMgY3Jl
YXRlZCB1c2luZyB0aGlzIHNlcnZpY2UgYXJlCiBnbG9iYWwuCgoLCgMGAQESBJsBCCYKCwoD
BgEDEgScAQJICg0KBQYBA5kIEgScAQJICg0KAwYBAxIGnQECngE3Cg8KBQYBA5oIEgadAQKe
ATcKSQoEBgECABIGoQECpwEDGjkgTGlzdHMgYWxsIGBWcGNGbG93TG9nc0NvbmZpZ3NgIGlu
IGEgZ2l2ZW4gb3JnYW5pemF0aW9uLgoKDQoFBgECAAESBKEBBhwKDQoFBgECAAISBKEBHToK
DQoFBgECAAMSBKIBDy0KDwoFBgECAAQSBqMBBKUBBgoTCgkGAQIABLDKvCISBqMBBKUBBgoN
CgUGAQIABBIEpgEENAoQCggGAQIABJsIABIEpgEENApFCgQGAQIBEgaqAQKwAQMaNSBHZXRz
IHRoZSBkZXRhaWxzIG9mIGEgc3BlY2lmaWMgYFZwY0Zsb3dMb2dzQ29uZmlnYC4KCg0KBQYB
AgEBEgSqAQYaCg0KBQYBAgECEgSqARs2Cg0KBQYBAgEDEgSrAQ8gCg8KBQYBAgEEEgasAQSu
AQYKEwoJBgECAQSwyrwiEgasAQSuAQYKDQoFBgECAQQSBK8BBDIKEAoIBgECAQSbCAASBK8B
BDIKwAQKBAYBAgISBsEBAs0BAxqvBCBDcmVhdGVzIGEgbmV3IGBWcGNGbG93TG9nc0NvbmZp
Z2AuCiBJZiBhIGNvbmZpZ3VyYXRpb24gd2l0aCB0aGUgZXhhY3Qgc2FtZSBzZXR0aW5ncyBh
bHJlYWR5IGV4aXN0cyAoZXZlbiBpZiB0aGUKIElEIGlzIGRpZmZlcmVudCksIHRoZSBjcmVh
dGlvbiBmYWlscy4KIE5vdGVzOgoKICAgMS4gQ3JlYXRpbmcgYSBjb25maWd1cmF0aW9uIHdp
dGggYHN0YXRlPURJU0FCTEVEYCB3aWxsIGZhaWwKICAgMi4gVGhlIGZvbGxvd2luZyBmaWVs
ZHMgYXJlIG5vdCBjb25zaWRlcmVkIGFzIHNldHRpbmdzIGZvciB0aGUgcHVycG9zZQogICBv
ZiB0aGUgY2hlY2sgbWVudGlvbmVkIGFib3ZlLCB0aGVyZWZvcmUgLSBjcmVhdGluZyBhbm90
aGVyIGNvbmZpZ3VyYXRpb24KICAgd2l0aCB0aGUgc2FtZSBmaWVsZHMgYnV0IGRpZmZlcmVu
dCB2YWx1ZXMgZm9yIHRoZSBmb2xsb3dpbmcgZmllbGRzIHdpbGwKICAgZmFpbCBhcyB3ZWxs
OgogICAgICAgKiBuYW1lCiAgICAgICAqIGNyZWF0ZV90aW1lCiAgICAgICAqIHVwZGF0ZV90
aW1lCiAgICAgICAqIGxhYmVscwogICAgICAgKiBkZXNjcmlwdGlvbgoKDQoFBgECAgESBMEB
Bh0KDQoFBgECAgISBMEBHjwKDQoFBgECAgMSBMIBDysKDwoFBgECAgQSBsMBBMYBBgoTCgkG
AQICBLDKvCISBsMBBMYBBgoPCgUGAQICBBIGxwEEyAE+ChIKCAYBAgIEmwgAEgbHAQTIAT4K
DwoFBgECAgQSBskBBMwBBgoRCgcGAQICBJkIEgbJAQTMAQYKxgQKBAYBAgMSBt4BAukBAxq1
BCBVcGRhdGVzIGFuIGV4aXN0aW5nIGBWcGNGbG93TG9nc0NvbmZpZ2AuCiBJZiBhIGNvbmZp
Z3VyYXRpb24gd2l0aCB0aGUgZXhhY3Qgc2FtZSBzZXR0aW5ncyBhbHJlYWR5IGV4aXN0cyAo
ZXZlbiBpZiB0aGUKIElEIGlzIGRpZmZlcmVudCksIHRoZSBjcmVhdGlvbiBmYWlscy4KIE5v
dGVzOgoKICAgMS4gVXBkYXRpbmcgYSBjb25maWd1cmF0aW9uIHdpdGggYHN0YXRlPURJU0FC
TEVEYCB3aWxsIGZhaWwKICAgMi4gVGhlIGZvbGxvd2luZyBmaWVsZHMgYXJlIG5vdCBjb25z
aWRlcmVkIGFzIHNldHRpbmdzIGZvciB0aGUgcHVycG9zZQogICBvZiB0aGUgY2hlY2sgbWVu
dGlvbmVkIGFib3ZlLCB0aGVyZWZvcmUgLSB1cGRhdGluZyBhbm90aGVyIGNvbmZpZ3VyYXRp
b24KICAgd2l0aCB0aGUgc2FtZSBmaWVsZHMgYnV0IGRpZmZlcmVudCB2YWx1ZXMgZm9yIHRo
ZSBmb2xsb3dpbmcgZmllbGRzIHdpbGwKICAgZmFpbCBhcyB3ZWxsOgogICAgICAgKiBuYW1l
CiAgICAgICAqIGNyZWF0ZV90aW1lCiAgICAgICAqIHVwZGF0ZV90aW1lCiAgICAgICAqIGxh
YmVscwogICAgICAgKiBkZXNjcmlwdGlvbgoKDQoFBgECAwESBN4BBh0KDQoFBgECAwISBN4B
HjwKDQoFBgECAwMSBN8BDysKDwoFBgECAwQSBuABBOMBBgoTCgkGAQIDBLDKvCISBuABBOMB
BgoNCgUGAQIDBBIE5AEETgoQCggGAQIDBJsIABIE5AEETgoPCgUGAQIDBBIG5QEE6AEGChEK
BwYBAgMEmQgSBuUBBOgBBgo5CgQGAQIEEgbsAQL2AQMaKSBEZWxldGVzIGEgc3BlY2lmaWMg
YFZwY0Zsb3dMb2dzQ29uZmlnYC4KCg0KBQYBAgQBEgTsAQYdCg0KBQYBAgQCEgTsAR48Cg0K
BQYBAgQDEgTtAQ8rCg8KBQYBAgQEEgbuAQTwAQYKEwoJBgECBASwyrwiEgbuAQTwAQYKDQoF
BgECBAQSBPEBBDIKEAoIBgECBASbCAASBPEBBDIKDwoFBgECBAQSBvIBBPUBBgoRCgcGAQIE
BJkIEgbyAQT1AQYKQAoCBAASBvoBAJcCARoyIFJlcXVlc3QgZm9yIHRoZSBgTGlzdFZwY0Zs
b3dMb2dzQ29uZmlnc2AgbWV0aG9kLgoKCwoDBAABEgT6AQglCpACCgQEAAIAEgaCAgKHAgQa
/wEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugb2YgdGhlIFZwY0Zsb3dMb2dzQ29u
ZmlnLAogaW4gb25lIG9mIHRoZSBmb2xsb3dpbmcgZm9ybWF0czoKCiAtIEZvciBwcm9qZWN0
LWxldmVsIHJlc291cmNlczogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xv
YmFsYAoKIC0gRm9yIG9yZ2FuaXphdGlvbi1sZXZlbCByZXNvdXJjZXM6CiBgb3JnYW5pemF0
aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMvZ2xvYmFsYAoKDQoFBAACAAUSBIIC
AggKDQoFBAACAAESBIICCQ8KDQoFBAACAAMSBIICEhMKDwoFBAACAAgSBoICFIcCAwoQCggE
AAIACJwIABIEgwIEKgoRCgcEAAIACJ8IEgaEAgSGAgUKQwoEBAACARIEigICPxo1IE9wdGlv
bmFsLiBOdW1iZXIgb2YgYFZwY0Zsb3dMb2dzQ29uZmlnc2AgdG8gcmV0dXJuLgoKDQoFBAAC
AQUSBIoCAgcKDQoFBAACAQESBIoCCBEKDQoFBAACAQMSBIoCFBUKDQoFBAACAQgSBIoCFj4K
EAoIBAACAQicCAASBIoCFz0KXgoEBAACAhIEjgICQRpQIE9wdGlvbmFsLiBQYWdlIHRva2Vu
IGZyb20gYW4gZWFybGllciBxdWVyeSwgYXMgcmV0dXJuZWQgaW4KIGBuZXh0X3BhZ2VfdG9r
ZW5gLgoKDQoFBAACAgUSBI4CAggKDQoFBAACAgESBI4CCRMKDQoFBAACAgMSBI4CFhcKDQoF
BAACAggSBI4CGEAKEAoIBAACAgicCAASBI4CGT8K+QEKBAQAAgMSBJMCAj0a6gEgT3B0aW9u
YWwuIExpc3RzIHRoZSBgVnBjRmxvd0xvZ3NDb25maWdzYCB0aGF0IG1hdGNoIHRoZSBmaWx0
ZXIgZXhwcmVzc2lvbi4KIEEgZmlsdGVyIGV4cHJlc3Npb24gbXVzdCB1c2UgdGhlIHN1cHBv
cnRlZCBbQ0VMIGxvZ2ljIG9wZXJhdG9yc10KIChodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
dnBjL2RvY3MvYWJvdXQtZmxvdy1sb2dzLXJlY29yZHMjc3VwcG9ydGVkX2NlbF9sb2dpY19v
cGVyYXRvcnMpLgoKDQoFBAACAwUSBJMCAggKDQoFBAACAwESBJMCCQ8KDQoFBAACAwMSBJMC
EhMKDQoFBAACAwgSBJMCFDwKEAoIBAACAwicCAASBJMCFTsKOAoEBAACBBIElgICPxoqIE9w
dGlvbmFsLiBGaWVsZCB0byB1c2UgdG8gc29ydCB0aGUgbGlzdC4KCg0KBQQAAgQFEgSWAgII
Cg0KBQQAAgQBEgSWAgkRCg0KBQQAAgQDEgSWAhQVCg0KBQQAAgQIEgSWAhY+ChAKCAQAAgQI
nAgAEgSWAhc9CkEKAgQBEgaaAgCjAgEaMyBSZXNwb25zZSBmb3IgdGhlIGBMaXN0VnBjRmxv
d0xvZ3NDb25maWdzYCBtZXRob2QuCgoLCgMEAQESBJoCCCYKNAoEBAECABIEnAICNxomIExp
c3Qgb2YgVlBDIEZsb3cgTG9nIGNvbmZpZ3VyYXRpb25zLgoKDQoFBAECAAQSBJwCAgoKDQoF
BAECAAYSBJwCCxwKDQoFBAECAAESBJwCHTIKDQoFBAECAAMSBJwCNTYKQwoEBAECARIEnwIC
HRo1IFBhZ2UgdG9rZW4gdG8gZmV0Y2ggdGhlIG5leHQgc2V0IG9mIGNvbmZpZ3VyYXRpb25z
LgoKDQoFBAECAQUSBJ8CAggKDQoFBAECAQESBJ8CCRgKDQoFBAECAQMSBJ8CGxwKWwoEBAEC
AhIEogICIhpNIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkICh3aGVuIHF1
ZXJ5aW5nIGFsbCBsb2NhdGlvbnMgd2l0aCBgLWApLgoKDQoFBAECAgQSBKICAgoKDQoFBAEC
AgUSBKICCxEKDQoFBAECAgESBKICEh0KDQoFBAECAgMSBKICICEKPgoCBAISBqYCALUCARow
IFJlcXVlc3QgZm9yIHRoZSBgR2V0VnBjRmxvd0xvZ3NDb25maWdgIG1ldGhvZC4KCgsKAwQC
ARIEpgIIIwrpAgoEBAICABIGrwICtAIEGtgCIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgVnBjRmxvd0xvZ3NDb25maWcsCiBpbiBvbmUgb2YgdGhlIGZvbGxvd2luZyBm
b3JtYXRzOgoKIC0gRm9yIHByb2plY3QtbGV2ZWwgcmVzb3VyY2VzOgogYHByb2plY3RzL3tw
cm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsL3ZwY0Zsb3dMb2dzQ29uZmlncy97dnBjX2Zs
b3dfbG9nc19jb25maWdfaWR9YAoKIC0gRm9yIG9yZ2FuaXphdGlvbi1sZXZlbCByZXNvdXJj
ZXM6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMvZ2xvYmFs
L3ZwY0Zsb3dMb2dzQ29uZmlncy97dnBjX2Zsb3dfbG9nc19jb25maWdfaWR9YAoKDQoFBAIC
AAUSBK8CAggKDQoFBAICAAESBK8CCQ0KDQoFBAICAAMSBK8CEBEKDwoFBAICAAgSBq8CErQC
AwoQCggEAgIACJwIABIEsAIEKgoRCgcEAgIACJ8IEgaxAgSzAgUKQQoCBAMSBrgCANICARoz
IFJlcXVlc3QgZm9yIHRoZSBgQ3JlYXRlVnBjRmxvd0xvZ3NDb25maWdgIG1ldGhvZC4KCgsK
AwQDARIEuAIIJgqaAgoEBAMCABIGwAICxQIEGokCIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJl
c291cmNlIG9mIHRoZSBWcGNGbG93TG9nc0NvbmZpZyB0byBjcmVhdGUsCiBpbiBvbmUgb2Yg
dGhlIGZvbGxvd2luZyBmb3JtYXRzOgoKIC0gRm9yIHByb2plY3QtbGV2ZWwgcmVzb3VyY2Vz
OiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWxgCgogLSBGb3Igb3Jn
YW5pemF0aW9uLWxldmVsIHJlc291cmNlczoKIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRp
b25faWR9L2xvY2F0aW9ucy9nbG9iYWxgCgoNCgUEAwIABRIEwAICCAoNCgUEAwIAARIEwAIJ
DwoNCgUEAwIAAxIEwAISEwoPCgUEAwIACBIGwAIUxQIDChAKCAQDAgAInAgAEgTBAgQqChEK
BwQDAgAInwgSBsICBMQCBQo6CgQEAwIBEgbIAgLNAgQaKiBSZXF1aXJlZC4gSUQgb2YgdGhl
IGBWcGNGbG93TG9nc0NvbmZpZ2AuCgoNCgUEAwIBBRIEyAICCAoNCgUEAwIBARIEyAIJIAoN
CgUEAwIBAxIEyAIjJAoPCgUEAwIBCBIGyAIlzQIDChAKCAQDAgEInAgAEgTJAgQqChEKBwQD
AgEInwgSBsoCBMwCBQo6CgQEAwICEgbQAgLRAi8aKiBSZXF1aXJlZC4gQSBgVnBjRmxvd0xv
Z3NDb25maWdgIHJlc291cmNlCgoNCgUEAwICBhIE0AICEwoNCgUEAwICARIE0AIUKAoNCgUE
AwICAxIE0AIrLAoNCgUEAwICCBIE0QIGLgoQCggEAwICCJwIABIE0QIHLQpBCgIEBBIG1QIA
5AIBGjMgUmVxdWVzdCBmb3IgdGhlIGBVcGRhdGVWcGNGbG93TG9nc0NvbmZpZ2AgbWV0aG9k
LgoKCwoDBAQBEgTVAggmCocDCgQEBAIAEgbeAgLfAi8a9gIgUmVxdWlyZWQuIE1hc2sgb2Yg
ZmllbGRzIHRvIHVwZGF0ZS4gQXQgbGVhc3Qgb25lIHBhdGggbXVzdCBiZSBzdXBwbGllZCBp
bgogdGhpcyBmaWVsZC4KIEZvciBleGFtcGxlLCB0byBjaGFuZ2UgdGhlIHN0YXRlIG9mIHRo
ZSBjb25maWd1cmF0aW9uIHRvIEVOQUJMRUQsIHNwZWNpZnkKICAgYHVwZGF0ZV9tYXNrYCA9
IGAic3RhdGUiYCwgYW5kIHRoZSBgdnBjX2Zsb3dfbG9nc19jb25maWdgIHdvdWxkIGJlOgog
ICBgdnBjX2Zsb3dfbG9nc19jb25maWcgPSB7CiAgICAgbmFtZSA9CiAgICAgInByb2plY3Rz
L215LXByb2plY3QvbG9jYXRpb25zL2dsb2JhbC92cGNGbG93TG9nc0NvbmZpZ3MvbXktY29u
ZmlnIgogICAgIHN0YXRlID0gIkVOQUJMRUQiIH1gCgoNCgUEBAIABhIE3gICGwoNCgUEBAIA
ARIE3gIcJwoNCgUEBAIAAxIE3gIqKwoNCgUEBAIACBIE3wIGLgoQCggEBAIACJwIABIE3wIH
LQpNCgQEBAIBEgbiAgLjAi8aPSBSZXF1aXJlZC4gT25seSBmaWVsZHMgc3BlY2lmaWVkIGlu
IHVwZGF0ZV9tYXNrIGFyZSB1cGRhdGVkLgoKDQoFBAQCAQYSBOICAhMKDQoFBAQCAQESBOIC
FCgKDQoFBAQCAQMSBOICKywKDQoFBAQCAQgSBOMCBi4KEAoIBAQCAQicCAASBOMCBy0KQQoC
BAUSBucCAPYCARozIFJlcXVlc3QgZm9yIHRoZSBgRGVsZXRlVnBjRmxvd0xvZ3NDb25maWdg
IG1ldGhvZC4KCgsKAwQFARIE5wIIJgrsAgoEBAUCABIG8AIC9QIEGtsCIFJlcXVpcmVkLiBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgVnBjRmxvd0xvZ3NDb25maWcsCiBpbiBvbmUgb2Yg
dGhlIGZvbGxvd2luZyBmb3JtYXRzOgoKIC0gRm9yIGEgcHJvamVjdC1sZXZlbCByZXNvdXJj
ZToKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2JhbC92cGNGbG93TG9n
c0NvbmZpZ3Mve3ZwY19mbG93X2xvZ3NfY29uZmlnX2lkfWAKCiAtIEZvciBhbiBvcmdhbml6
YXRpb24tbGV2ZWwgcmVzb3VyY2U6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lk
fS9sb2NhdGlvbnMvZ2xvYmFsL3ZwY0Zsb3dMb2dzQ29uZmlncy97dnBjX2Zsb3dfbG9nc19j
b25maWdfaWR9YAoKDQoFBAUCAAUSBPACAggKDQoFBAUCAAESBPACCQ0KDQoFBAUCAAMSBPAC
EBEKDwoFBAUCAAgSBvACEvUCAwoQCggEBQIACJwIABIE8QIEKgoRCgcEBQIACJ8IEgbyAgT0
AgUKRAoCBAYSBvkCAI4DARo2IFJlcXVlc3QgZm9yIHRoZSBgUXVlcnlPcmdWcGNGbG93TG9n
c0NvbmZpZ3NgIG1ldGhvZC4KCgsKAwQGARIE+QIIKQqXAQoEBAYCABIG/AICgQMEGoYBIFJl
cXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG9mIHRoZSBWcGNGbG93TG9nc0NvbmZpZywg
c3BlY2lmaWVkIGluCiB0aGUgZm9sbG93aW5nIGZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0
X2lkfS9sb2NhdGlvbnMvZ2xvYmFsYAoKDQoFBAYCAAUSBPwCAggKDQoFBAYCAAESBPwCCQ8K
DQoFBAYCAAMSBPwCEhMKDwoFBAYCAAgSBvwCFIEDAwoQCggEBgIACJwIABIE/QIEKgoRCgcE
BgIACJ8IEgb+AgSAAwUKQwoEBAYCARIEhAMCPxo1IE9wdGlvbmFsLiBOdW1iZXIgb2YgYFZw
Y0Zsb3dMb2dzQ29uZmlnc2AgdG8gcmV0dXJuLgoKDQoFBAYCAQUSBIQDAgcKDQoFBAYCAQES
BIQDCBEKDQoFBAYCAQMSBIQDFBUKDQoFBAYCAQgSBIQDFj4KEAoIBAYCAQicCAASBIQDFz0K
XgoEBAYCAhIEiAMCQRpQIE9wdGlvbmFsLiBQYWdlIHRva2VuIGZyb20gYW4gZWFybGllciBx
dWVyeSwgYXMgcmV0dXJuZWQgaW4KIGBuZXh0X3BhZ2VfdG9rZW5gLgoKDQoFBAYCAgUSBIgD
AggKDQoFBAYCAgESBIgDCRMKDQoFBAYCAgMSBIgDFhcKDQoFBAYCAggSBIgDGEAKEAoIBAYC
AgicCAASBIgDGT8K+QEKBAQGAgMSBI0DAj0a6gEgT3B0aW9uYWwuIExpc3RzIHRoZSBgVnBj
Rmxvd0xvZ3NDb25maWdzYCB0aGF0IG1hdGNoIHRoZSBmaWx0ZXIgZXhwcmVzc2lvbi4KIEEg
ZmlsdGVyIGV4cHJlc3Npb24gbXVzdCB1c2UgdGhlIHN1cHBvcnRlZCBbQ0VMIGxvZ2ljIG9w
ZXJhdG9yc10KIChodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vdnBjL2RvY3MvYWJvdXQtZmxv
dy1sb2dzLXJlY29yZHMjc3VwcG9ydGVkX2NlbF9sb2dpY19vcGVyYXRvcnMpLgoKDQoFBAYC
AwUSBI0DAggKDQoFBAYCAwESBI0DCQ8KDQoFBAYCAwMSBI0DEhMKDQoFBAYCAwgSBI0DFDwK
EAoIBAYCAwicCAASBI0DFTsKQgoCBAcSBpEDAJoDARo0IFJlc3BvbnNlIGZvciB0aGUgYFF1
ZXJ5VnBjRmxvd0xvZ3NDb25maWdzYCBtZXRob2QuCgoLCgMEBwESBJEDCCoKNAoEBAcCABIE
kwMCNxomIExpc3Qgb2YgVlBDIEZsb3cgTG9nIGNvbmZpZ3VyYXRpb25zLgoKDQoFBAcCAAQS
BJMDAgoKDQoFBAcCAAYSBJMDCxwKDQoFBAcCAAESBJMDHTIKDQoFBAcCAAMSBJMDNTYKQwoE
BAcCARIElgMCHRo1IFBhZ2UgdG9rZW4gdG8gZmV0Y2ggdGhlIG5leHQgc2V0IG9mIGNvbmZp
Z3VyYXRpb25zLgoKDQoFBAcCAQUSBJYDAggKDQoFBAcCAQESBJYDCRgKDQoFBAcCAQMSBJYD
GxwKWwoEBAcCAhIEmQMCIhpNIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVk
ICh3aGVuIHF1ZXJ5aW5nIGFsbCBsb2NhdGlvbnMgd2l0aCBgLWApLgoKDQoFBAcCAgQSBJkD
AgoKDQoFBAcCAgUSBJkDCxEKDQoFBAcCAgESBJkDEh0KDQoFBAcCAgMSBJkDICEKRgoCBAgS
Bp0DALkDARo4IFJlcXVlc3QgZm9yIHRoZSBgU2hvd0VmZmVjdGl2ZUZsb3dMb2dzQ29uZmln
c2AgbWV0aG9kLgoKCwoDBAgBEgSdAwgrCpcBCgQECAIAEgagAwKlAwQahgEgUmVxdWlyZWQu
IFRoZSBwYXJlbnQgcmVzb3VyY2Ugb2YgdGhlIFZwY0Zsb3dMb2dzQ29uZmlnLCBzcGVjaWZp
ZWQgaW4KIHRoZSBmb2xsb3dpbmcgZm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xv
Y2F0aW9ucy9nbG9iYWxgCgoNCgUECAIABRIEoAMCCAoNCgUECAIAARIEoAMJDwoNCgUECAIA
AxIEoAMSEwoPCgUECAIACBIGoAMUpQMDChAKCAQIAgAInAgAEgShAwQqChEKBwQIAgAInwgS
BqIDBKQDBQr7AQoEBAgCARIEqwMCPxrsASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIHRvIGdl
dCB0aGUgZWZmZWN0aXZlIFZQQyBGbG93IExvZ3MgY29uZmlndXJhdGlvbgogZm9yLiBUaGUg
cmVzb3VyY2UgbXVzdCBiZWxvbmcgdG8gdGhlIHNhbWUgcHJvamVjdCBhcyB0aGUgcGFyZW50
LiBUaGUKIHJlc291cmNlIG11c3QgYmUgYSBuZXR3b3JrLCBzdWJuZXR3b3JrLCBpbnRlcmNv
bm5lY3QgYXR0YWNobWVudCwgVlBOCiB0dW5uZWwsIG9yIGEgcHJvamVjdC4KCg0KBQQIAgEF
EgSrAwIICg0KBQQIAgEBEgSrAwkRCg0KBQQIAgEDEgSrAxQVCg0KBQQIAgEIEgSrAxY+ChAK
CAQIAgEInAgAEgSrAxc9ClsKBAQIAgISBK4DAj8aTSBPcHRpb25hbC4gTnVtYmVyIG9mIGBF
ZmZlY3RpdmVWcGNGbG93TG9nc0NvbmZpZ3NgIHRvIHJldHVybi4gRGVmYXVsdCBpcyAzMC4K
Cg0KBQQIAgIFEgSuAwIHCg0KBQQIAgIBEgSuAwgRCg0KBQQIAgIDEgSuAxQVCg0KBQQIAgII
EgSuAxY+ChAKCAQIAgIInAgAEgSuAxc9Cl4KBAQIAgMSBLIDAkEaUCBPcHRpb25hbC4gUGFn
ZSB0b2tlbiBmcm9tIGFuIGVhcmxpZXIgcXVlcnksIGFzIHJldHVybmVkIGluCiBgbmV4dF9w
YWdlX3Rva2VuYC4KCg0KBQQIAgMFEgSyAwIICg0KBQQIAgMBEgSyAwkTCg0KBQQIAgMDEgSy
AxYXCg0KBQQIAgMIEgSyAxhAChAKCAQIAgMInAgAEgSyAxk/CoMCCgQECAIEEgS4AwI9GvQB
IE9wdGlvbmFsLiBMaXN0cyB0aGUgYEVmZmVjdGl2ZVZwY0Zsb3dMb2dzQ29uZmlnc2AgdGhh
dCBtYXRjaCB0aGUgZmlsdGVyCiBleHByZXNzaW9uLiBBIGZpbHRlciBleHByZXNzaW9uIG11
c3QgdXNlIHRoZSBzdXBwb3J0ZWQgW0NFTCBsb2dpYwogb3BlcmF0b3JzXQogKGh0dHBzOi8v
Y2xvdWQuZ29vZ2xlLmNvbS92cGMvZG9jcy9hYm91dC1mbG93LWxvZ3MtcmVjb3JkcyNzdXBw
b3J0ZWRfY2VsX2xvZ2ljX29wZXJhdG9ycykuCgoNCgUECAIEBRIEuAMCCAoNCgUECAIEARIE
uAMJDwoNCgUECAIEAxIEuAMSEwoNCgUECAIECBIEuAMUPAoQCggECAIECJwIABIEuAMVOwpH
CgIECRIGvAMAxQMBGjkgUmVzcG9uc2UgZm9yIHRoZSBgU2hvd0VmZmVjdGl2ZUZsb3dMb2dz
Q29uZmlnc2AgbWV0aG9kLgoKCwoDBAkBEgS8AwgsCj8KBAQJAgASBL4DAkYaMSBMaXN0IG9m
IEVmZmVjdGl2ZSBWcGMgRmxvdyBMb2dzIGNvbmZpZ3VyYXRpb25zLgoKDQoFBAkCAAQSBL4D
AgoKDQoFBAkCAAYSBL4DCyUKDQoFBAkCAAESBL4DJkEKDQoFBAkCAAMSBL4DREUKQwoEBAkC
ARIEwQMCHRo1IFBhZ2UgdG9rZW4gdG8gZmV0Y2ggdGhlIG5leHQgc2V0IG9mIGNvbmZpZ3Vy
YXRpb25zLgoKDQoFBAkCAQUSBMEDAggKDQoFBAkCAQESBMEDCRgKDQoFBAkCAQMSBMEDGxwK
WwoEBAkCAhIExAMCIhpNIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkICh3
aGVuIHF1ZXJ5aW5nIGFsbCBsb2NhdGlvbnMgd2l0aCBgLWApLgoKDQoFBAkCAgQSBMQDAgoK
DQoFBAkCAgUSBMQDCxEKDQoFBAkCAgESBMQDEh0KDQoFBAkCAgMSBMQDICFiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest ===
    # Fields for ListVpcFlowLogsConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse ===
    # Fields for ListVpcFlowLogsConfigsResponse
    # Field: vpc_flow_logs_configs Type: 11 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::GetVpcFlowLogsConfigRequest ===
    # Fields for GetVpcFlowLogsConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest ===
    # Fields for CreateVpcFlowLogsConfigRequest
    # Field: parent Type: 9 ()
    # Field: vpc_flow_logs_config_id Type: 9 ()
    # Field: vpc_flow_logs_config Type: 11 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig)

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest ===
    # Fields for UpdateVpcFlowLogsConfigRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: vpc_flow_logs_config Type: 11 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig)

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest ===
    # Fields for DeleteVpcFlowLogsConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest ===
    # Fields for QueryOrgVpcFlowLogsConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse ===
    # Fields for QueryOrgVpcFlowLogsConfigsResponse
    # Field: vpc_flow_logs_configs Type: 11 (.google.cloud.networkmanagement.v1.VpcFlowLogsConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest ===
    # Fields for ShowEffectiveFlowLogsConfigsRequest
    # Field: parent Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse ===
    # Fields for ShowEffectiveFlowLogsConfigsResponse
    # Field: effective_flow_logs_configs Type: 11 (.google.cloud.networkmanagement.v1.EffectiveVpcFlowLogsConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Service Client: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::VpcFlowLogsServiceClient ===
package Google::Cloud::Networkmanagement::V1::VpcFlowLogs::VpcFlowLogsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::VpcFlowLogsServiceClient

Client stub representing the remote C<VpcFlowLogsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<networkmanagement.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networkmanagement.googleapis.com:443' );

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

sub list_vpc_flow_logs_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.VpcFlowLogsService',
        method         => 'ListVpcFlowLogsConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse',
    });
}

sub get_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::GetVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.VpcFlowLogsService',
        method         => 'GetVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig',
    });
}

sub create_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.VpcFlowLogsService',
        method         => 'CreateVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.VpcFlowLogsService',
        method         => 'UpdateVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.VpcFlowLogsService',
        method         => 'DeleteVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub query_org_vpc_flow_logs_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.VpcFlowLogsService',
        method         => 'QueryOrgVpcFlowLogsConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse',
    });
}

sub show_effective_flow_logs_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.VpcFlowLogsService',
        method         => 'ShowEffectiveFlowLogsConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse',
    });
}

# === Service Client: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::OrganizationVpcFlowLogsServiceClient ===
package Google::Cloud::Networkmanagement::V1::VpcFlowLogs::OrganizationVpcFlowLogsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networkmanagement::V1::VpcFlowLogs::OrganizationVpcFlowLogsServiceClient

Client stub representing the remote C<OrganizationVpcFlowLogsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<networkmanagement.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networkmanagement.googleapis.com:443' );

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

sub list_vpc_flow_logs_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.OrganizationVpcFlowLogsService',
        method         => 'ListVpcFlowLogsConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse',
    });
}

sub get_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::GetVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.OrganizationVpcFlowLogsService',
        method         => 'GetVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig',
    });
}

sub create_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.OrganizationVpcFlowLogsService',
        method         => 'CreateVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.OrganizationVpcFlowLogsService',
        method         => 'UpdateVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.OrganizationVpcFlowLogsService',
        method         => 'DeleteVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkmanagement::V1::VpcFlowLogs - Compiled Protocol Buffers messages for google/cloud/networkmanagement/v1/vpc_flow_logs.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkmanagement::V1::VpcFlowLogs;

    my $msg = Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkmanagement/v1/vpc_flow_logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest

Request for the `ListVpcFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the VpcFlowLogsConfig,
in one of the following formats:

- For project-level resources: `projects/{project_id}/locations/global`

- For organization-level resources:
`organizations/{organization_id}/locations/global`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Number of `VpcFlowLogsConfigs` to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Page token from an earlier query, as returned in
`next_page_token`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Lists the `VpcFlowLogsConfigs` that match the filter expression.
A filter expression must use the supported [CEL logic operators]
(https://cloud.google.com/vpc/docs/about-flow-logs-records#supported_cel_logic_operators).

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field to use to sort the list.

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse

Response for the `ListVpcFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vpc_flow_logs_configs() >> / C<< $msg->vpc_flow_logs_configs($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig>)

List of VPC Flow Log configurations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token to fetch the next set of configurations.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached (when querying all locations with `-`).

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::GetVpcFlowLogsConfigRequest

Request for the `GetVpcFlowLogsConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the VpcFlowLogsConfig,
in one of the following formats:

- For project-level resources:
`projects/{project_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

- For organization-level resources:
`organizations/{organization_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest

Request for the `CreateVpcFlowLogsConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the VpcFlowLogsConfig to create,
in one of the following formats:

- For project-level resources: `projects/{project_id}/locations/global`

- For organization-level resources:
`organizations/{organization_id}/locations/global`

=item * C<< $msg->vpc_flow_logs_config_id() >> / C<< $msg->vpc_flow_logs_config_id($value) >>

Type: C<String>

Required. ID of the `VpcFlowLogsConfig`.

=item * C<< $msg->vpc_flow_logs_config() >> / C<< $msg->vpc_flow_logs_config($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig>)

Required. A `VpcFlowLogsConfig` resource

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest

Request for the `UpdateVpcFlowLogsConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Mask of fields to update. At least one path must be supplied in
this field.
For example, to change the state of the configuration to ENABLED, specify
  `update_mask` = `"state"`, and the `vpc_flow_logs_config` would be:
  `vpc_flow_logs_config = {
    name =
    "projects/my-project/locations/global/vpcFlowLogsConfigs/my-config"
    state = "ENABLED" }`

=item * C<< $msg->vpc_flow_logs_config() >> / C<< $msg->vpc_flow_logs_config($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig>)

Required. Only fields specified in update_mask are updated.

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest

Request for the `DeleteVpcFlowLogsConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the VpcFlowLogsConfig,
in one of the following formats:

- For a project-level resource:
`projects/{project_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

- For an organization-level resource:
`organizations/{organization_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest

Request for the `QueryOrgVpcFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the VpcFlowLogsConfig, specified in
the following format: `projects/{project_id}/locations/global`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Number of `VpcFlowLogsConfigs` to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Page token from an earlier query, as returned in
`next_page_token`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Lists the `VpcFlowLogsConfigs` that match the filter expression.
A filter expression must use the supported [CEL logic operators]
(https://cloud.google.com/vpc/docs/about-flow-logs-records#supported_cel_logic_operators).

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse

Response for the `QueryVpcFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vpc_flow_logs_configs() >> / C<< $msg->vpc_flow_logs_configs($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig>)

List of VPC Flow Log configurations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token to fetch the next set of configurations.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached (when querying all locations with `-`).

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest

Request for the `ShowEffectiveFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the VpcFlowLogsConfig, specified in
the following format: `projects/{project_id}/locations/global`

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Required. The resource to get the effective VPC Flow Logs configuration
for. The resource must belong to the same project as the parent. The
resource must be a network, subnetwork, interconnect attachment, VPN
tunnel, or a project.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Number of `EffectiveVpcFlowLogsConfigs` to return. Default is 30.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Page token from an earlier query, as returned in
`next_page_token`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Lists the `EffectiveVpcFlowLogsConfigs` that match the filter
expression. A filter expression must use the supported [CEL logic
operators]
(https://cloud.google.com/vpc/docs/about-flow-logs-records#supported_cel_logic_operators).

=back

=head2 Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse

Response for the `ShowEffectiveFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->effective_flow_logs_configs() >> / C<< $msg->effective_flow_logs_configs($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig>)

List of Effective Vpc Flow Logs configurations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token to fetch the next set of configurations.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached (when querying all locations with `-`).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkmanagement::V1::VpcFlowLogs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
