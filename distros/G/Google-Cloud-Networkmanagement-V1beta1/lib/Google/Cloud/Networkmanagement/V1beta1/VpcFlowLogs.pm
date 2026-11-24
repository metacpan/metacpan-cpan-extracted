package Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs;

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
    eval { require Google::Cloud::Networkmanagement::V1beta1::Reachability };
    eval { require Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvbmV0d29ya21hbmFnZW1lbnQvdjFiZXRhMS92cGNfZmxvd19sb2dz
LnByb3RvEiZnb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRhMRocZ29vZ2xl
L2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
OWdvb2dsZS9jbG91ZC9uZXR3b3JrbWFuYWdlbWVudC92MWJldGExL3JlYWNoYWJpbGl0eS5w
cm90bxpBZ29vZ2xlL2Nsb3VkL25ldHdvcmttYW5hZ2VtZW50L3YxYmV0YTEvdnBjX2Zsb3df
bG9nc19jb25maWcucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3Rv
Ghtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9t
YXNrLnByb3RvIvYBCh1MaXN0VnBjRmxvd0xvZ3NDb25maWdzUmVxdWVzdBJSCgZwYXJlbnQY
ASABKAlCOuBBAvpBNBIybmV0d29ya21hbmFnZW1lbnQuZ29vZ2xlYXBpcy5jb20vVnBjRmxv
d0xvZ3NDb25maWdSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUS
IgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPg
QQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5ItgBCh5MaXN0VnBj
Rmxvd0xvZ3NDb25maWdzUmVzcG9uc2USbAoVdnBjX2Zsb3dfbG9nc19jb25maWdzGAEgAygL
MjkuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuVnBjRmxvd0xvZ3ND
b25maWdSEnZwY0Zsb3dMb2dzQ29uZmlncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlIm0KG0dldFZw
Y0Zsb3dMb2dzQ29uZmlnUmVxdWVzdBJOCgRuYW1lGAEgASgJQjrgQQL6QTQKMm5ldHdvcmtt
YW5hZ2VtZW50Lmdvb2dsZWFwaXMuY29tL1ZwY0Zsb3dMb2dzQ29uZmlnUgRuYW1lItcCCh5D
cmVhdGVWcGNGbG93TG9nc0NvbmZpZ1JlcXVlc3QSUgoGcGFyZW50GAEgASgJQjrgQQL6QTQS
Mm5ldHdvcmttYW5hZ2VtZW50Lmdvb2dsZWFwaXMuY29tL1ZwY0Zsb3dMb2dzQ29uZmlnUgZw
YXJlbnQScAoXdnBjX2Zsb3dfbG9nc19jb25maWdfaWQYAiABKAlCOuBBAvpBNAoybmV0d29y
a21hbmFnZW1lbnQuZ29vZ2xlYXBpcy5jb20vVnBjRmxvd0xvZ3NDb25maWdSE3ZwY0Zsb3dM
b2dzQ29uZmlnSWQSbwoUdnBjX2Zsb3dfbG9nc19jb25maWcYAyABKAsyOS5nb29nbGUuY2xv
dWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5WcGNGbG93TG9nc0NvbmZpZ0ID4EECUhF2
cGNGbG93TG9nc0NvbmZpZyLTAQoeVXBkYXRlVnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0EkAK
C3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1
cGRhdGVNYXNrEm8KFHZwY19mbG93X2xvZ3NfY29uZmlnGAIgASgLMjkuZ29vZ2xlLmNsb3Vk
Lm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuVnBjRmxvd0xvZ3NDb25maWdCA+BBAlIRdnBj
Rmxvd0xvZ3NDb25maWcicAoeRGVsZXRlVnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0Ek4KBG5h
bWUYASABKAlCOuBBAvpBNAoybmV0d29ya21hbmFnZW1lbnQuZ29vZ2xlYXBpcy5jb20vVnBj
Rmxvd0xvZ3NDb25maWdSBG5hbWUi2gEKIVF1ZXJ5T3JnVnBjRmxvd0xvZ3NDb25maWdzUmVx
dWVzdBJSCgZwYXJlbnQYASABKAlCOuBBAvpBNBIybmV0d29ya21hbmFnZW1lbnQuZ29vZ2xl
YXBpcy5jb20vVnBjRmxvd0xvZ3NDb25maWdSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVC
A+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoG
ZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlciLcAQoiUXVlcnlPcmdWcGNGbG93TG9nc0NvbmZp
Z3NSZXNwb25zZRJsChV2cGNfZmxvd19sb2dzX2NvbmZpZ3MYASADKAsyOS5nb29nbGUuY2xv
dWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5WcGNGbG93TG9nc0NvbmZpZ1ISdnBjRmxv
d0xvZ3NDb25maWdzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIg
Cgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUi/QEKI1Nob3dFZmZlY3RpdmVGbG93
TG9nc0NvbmZpZ3NSZXF1ZXN0ElIKBnBhcmVudBgBIAEoCUI64EEC+kE0EjJuZXR3b3JrbWFu
YWdlbWVudC5nb29nbGVhcGlzLmNvbS9WcGNGbG93TG9nc0NvbmZpZ1IGcGFyZW50Eh8KCHJl
c291cmNlGAIgASgJQgPgQQJSCHJlc291cmNlEiAKCXBhZ2Vfc2l6ZRgDIAEoBUID4EEBUghw
YWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAQgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIY
BSABKAlCA+BBAVIGZmlsdGVyIvQBCiRTaG93RWZmZWN0aXZlRmxvd0xvZ3NDb25maWdzUmVz
cG9uc2USgQEKG2VmZmVjdGl2ZV9mbG93X2xvZ3NfY29uZmlncxgBIAMoCzJCLmdvb2dsZS5j
bG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJldGExLkVmZmVjdGl2ZVZwY0Zsb3dMb2dzQ29u
ZmlnUhhlZmZlY3RpdmVGbG93TG9nc0NvbmZpZ3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJ
Ug1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZTLrEAoS
VnBjRmxvd0xvZ3NTZXJ2aWNlEvUBChZMaXN0VnBjRmxvd0xvZ3NDb25maWdzEkUuZ29vZ2xl
LmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuTGlzdFZwY0Zsb3dMb2dzQ29uZmln
c1JlcXVlc3QaRi5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5MaXN0
VnBjRmxvd0xvZ3NDb25maWdzUmVzcG9uc2UiTILT5JMCPRI7L3YxYmV0YTEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qfS92cGNGbG93TG9nc0NvbmZpZ3PaQQZwYXJlbnQS4gEK
FEdldFZwY0Zsb3dMb2dzQ29uZmlnEkMuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50
LnYxYmV0YTEuR2V0VnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0GjkuZ29vZ2xlLmNsb3VkLm5l
dHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuVnBjRmxvd0xvZ3NDb25maWciSoLT5JMCPRI7L3Yx
YmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi92cGNGbG93TG9nc0NvbmZpZ3Mv
Kn3aQQRuYW1lEuICChdDcmVhdGVWcGNGbG93TG9nc0NvbmZpZxJGLmdvb2dsZS5jbG91ZC5u
ZXR3b3JrbWFuYWdlbWVudC52MWJldGExLkNyZWF0ZVZwY0Zsb3dMb2dzQ29uZmlnUmVxdWVz
dBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i3wGC0+STAlMiOy92MWJldGExL3tw
YXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vdnBjRmxvd0xvZ3NDb25maWdzOhR2cGNf
Zmxvd19sb2dzX2NvbmZpZ9pBM3BhcmVudCx2cGNfZmxvd19sb2dzX2NvbmZpZyx2cGNfZmxv
d19sb2dzX2NvbmZpZ19pZMpBTQoRVnBjRmxvd0xvZ3NDb25maWcSOGdvb2dsZS5jbG91ZC5u
ZXR3b3JrbWFuYWdlbWVudC52MWJldGExLk9wZXJhdGlvbk1ldGFkYXRhEuQCChdVcGRhdGVW
cGNGbG93TG9nc0NvbmZpZxJGLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJl
dGExLlVwZGF0ZVZwY0Zsb3dMb2dzQ29uZmlnUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmlu
Zy5PcGVyYXRpb24i4QGC0+STAmgyUC92MWJldGExL3t2cGNfZmxvd19sb2dzX2NvbmZpZy5u
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovdnBjRmxvd0xvZ3NDb25maWdzLyp9OhR2cGNf
Zmxvd19sb2dzX2NvbmZpZ9pBIHZwY19mbG93X2xvZ3NfY29uZmlnLHVwZGF0ZV9tYXNrykFN
ChFWcGNGbG93TG9nc0NvbmZpZxI4Z29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYx
YmV0YTEuT3BlcmF0aW9uTWV0YWRhdGESoQIKF0RlbGV0ZVZwY0Zsb3dMb2dzQ29uZmlnEkYu
Z29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuRGVsZXRlVnBjRmxvd0xv
Z3NDb25maWdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKeAYLT5JMC
PSo7L3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi92cGNGbG93TG9nc0Nv
bmZpZ3MvKn3aQQRuYW1lykFRChVnb29nbGUucHJvdG9idWYuRW1wdHkSOGdvb2dsZS5jbG91
ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJldGExLk9wZXJhdGlvbk1ldGFkYXRhEpMCChpRdWVy
eU9yZ1ZwY0Zsb3dMb2dzQ29uZmlncxJJLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVu
dC52MWJldGExLlF1ZXJ5T3JnVnBjRmxvd0xvZ3NDb25maWdzUmVxdWVzdBpKLmdvb2dsZS5j
bG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJldGExLlF1ZXJ5T3JnVnBjRmxvd0xvZ3NDb25m
aWdzUmVzcG9uc2UiXoLT5JMCWBJWL3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qfS92cGNGbG93TG9nc0NvbmZpZ3M6cXVlcnlPcmdWcGNGbG93TG9nc0NvbmZpZ3MS
mwIKHFNob3dFZmZlY3RpdmVGbG93TG9nc0NvbmZpZ3MSSy5nb29nbGUuY2xvdWQubmV0d29y
a21hbmFnZW1lbnQudjFiZXRhMS5TaG93RWZmZWN0aXZlRmxvd0xvZ3NDb25maWdzUmVxdWVz
dBpMLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJldGExLlNob3dFZmZlY3Rp
dmVGbG93TG9nc0NvbmZpZ3NSZXNwb25zZSJggtPkkwJaElgvdjFiZXRhMS97cGFyZW50PXBy
b2plY3RzLyovbG9jYXRpb25zLyp9L3ZwY0Zsb3dMb2dzQ29uZmlnczpzaG93RWZmZWN0aXZl
Rmxvd0xvZ3NDb25maWdzGlTKQSBuZXR3b3JrbWFuYWdlbWVudC5nb29nbGVhcGlzLmNvbdJB
Lmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0y3AwKHk9y
Z2FuaXphdGlvblZwY0Zsb3dMb2dzU2VydmljZRL6AQoWTGlzdFZwY0Zsb3dMb2dzQ29uZmln
cxJFLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJldGExLkxpc3RWcGNGbG93
TG9nc0NvbmZpZ3NSZXF1ZXN0GkYuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYx
YmV0YTEuTGlzdFZwY0Zsb3dMb2dzQ29uZmlnc1Jlc3BvbnNlIlGC0+STAkISQC92MWJldGEx
L3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qfS92cGNGbG93TG9nc0NvbmZp
Z3PaQQZwYXJlbnQS5wEKFEdldFZwY0Zsb3dMb2dzQ29uZmlnEkMuZ29vZ2xlLmNsb3VkLm5l
dHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuR2V0VnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0Gjku
Z29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuVnBjRmxvd0xvZ3NDb25m
aWciT4LT5JMCQhJAL3YxYmV0YTEve25hbWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8q
L3ZwY0Zsb3dMb2dzQ29uZmlncy8qfdpBBG5hbWUS5wIKF0NyZWF0ZVZwY0Zsb3dMb2dzQ29u
ZmlnEkYuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuQ3JlYXRlVnBj
Rmxvd0xvZ3NDb25maWdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLk
AYLT5JMCWCJAL3YxYmV0YTEve3BhcmVudD1vcmdhbml6YXRpb25zLyovbG9jYXRpb25zLyp9
L3ZwY0Zsb3dMb2dzQ29uZmlnczoUdnBjX2Zsb3dfbG9nc19jb25maWfaQTNwYXJlbnQsdnBj
X2Zsb3dfbG9nc19jb25maWcsdnBjX2Zsb3dfbG9nc19jb25maWdfaWTKQU0KEVZwY0Zsb3dM
b2dzQ29uZmlnEjhnb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5PcGVy
YXRpb25NZXRhZGF0YRLpAgoXVXBkYXRlVnBjRmxvd0xvZ3NDb25maWcSRi5nb29nbGUuY2xv
dWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5VcGRhdGVWcGNGbG93TG9nc0NvbmZpZ1Jl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIuYBgtPkkwJtMlUvdjFiZXRh
MS97dnBjX2Zsb3dfbG9nc19jb25maWcubmFtZT1vcmdhbml6YXRpb25zLyovbG9jYXRpb25z
LyovdnBjRmxvd0xvZ3NDb25maWdzLyp9OhR2cGNfZmxvd19sb2dzX2NvbmZpZ9pBIHZwY19m
bG93X2xvZ3NfY29uZmlnLHVwZGF0ZV9tYXNrykFNChFWcGNGbG93TG9nc0NvbmZpZxI4Z29v
Z2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuT3BlcmF0aW9uTWV0YWRhdGES
pgIKF0RlbGV0ZVZwY0Zsb3dMb2dzQ29uZmlnEkYuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5h
Z2VtZW50LnYxYmV0YTEuRGVsZXRlVnBjRmxvd0xvZ3NDb25maWdSZXF1ZXN0Gh0uZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbiKjAYLT5JMCQipAL3YxYmV0YTEve25hbWU9b3JnYW5p
emF0aW9ucy8qL2xvY2F0aW9ucy8qL3ZwY0Zsb3dMb2dzQ29uZmlncy8qfdpBBG5hbWXKQVEK
FWdvb2dsZS5wcm90b2J1Zi5FbXB0eRI4Z29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50
LnYxYmV0YTEuT3BlcmF0aW9uTWV0YWRhdGEaVMpBIG5ldHdvcmttYW5hZ2VtZW50Lmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybUKYAgoqY29tLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJldGExQhBW
cGNGbG93TG9nc1Byb3RvUAFaWGNsb3VkLmdvb2dsZS5jb20vZ28vbmV0d29ya21hbmFnZW1l
bnQvYXBpdjFiZXRhMS9uZXR3b3JrbWFuYWdlbWVudHBiO25ldHdvcmttYW5hZ2VtZW50cGKq
AiZHb29nbGUuQ2xvdWQuTmV0d29ya01hbmFnZW1lbnQuVjFCZXRhMcoCJkdvb2dsZVxDbG91
ZFxOZXR3b3JrTWFuYWdlbWVudFxWMWJldGEx6gIpR29vZ2xlOjpDbG91ZDo6TmV0d29ya01h
bmFnZW1lbnQ6OlYxYmV0YTFKwGkKBxIFDgDFAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQAC8KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkK
CQoCAwMSAxUAIwoJCgIDBBIDFgBDCgkKAgMFEgMXAEsKCQoCAwYSAxgALQoJCgIDBxIDGQAl
CgkKAgMIEgMaACoKCAoBCBIDHABDCgkKAgglEgMcAEMKCAoBCBIDHQBvCgkKAggLEgMdAG8K
CAoBCBIDHgAiCgkKAggKEgMeACIKCAoBCBIDHwAxCgkKAggIEgMfADEKCAoBCBIDIABDCgkK
AggBEgMgAEMKCAoBCBIDIQBDCgkKAggpEgMhAEMKCAoBCBIDIgBCCgkKAggtEgMiAEIK2gEK
AgYAEgUnAJUBARrMASBUaGUgVlBDIEZsb3cgTG9ncyBzZXJ2aWNlIGluIHRoZSBHb29nbGUg
Q2xvdWQgTmV0d29yayBNYW5hZ2VtZW50IEFQSSBwcm92aWRlcwogY29uZmlndXJhdGlvbnMg
dGhhdCBnZW5lcmF0ZSBGbG93IExvZ3MuIFRoZSBzZXJ2aWNlIGFuZCB0aGUgY29uZmlndXJh
dGlvbgogcmVzb3VyY2VzIGNyZWF0ZWQgdXNpbmcgdGhpcyBzZXJ2aWNlIGFyZSBnbG9iYWwu
CgoKCgMGAAESAycIGgoKCgMGAAMSAygCSAoMCgUGAAOZCBIDKAJICgsKAwYAAxIEKQIqNwoN
CgUGAAOaCBIEKQIqNwpCCgQGAAIAEgQtAjMDGjQgTGlzdHMgYWxsIGBWcGNGbG93TG9nc0Nv
bmZpZ3NgIGluIGEgZ2l2ZW4gcHJvamVjdC4KCgwKBQYAAgABEgMtBhwKDAoFBgACAAISAy0d
OgoMCgUGAAIAAxIDLg8tCg0KBQYAAgAEEgQvBDEGChEKCQYAAgAEsMq8IhIELwQxBgoMCgUG
AAIABBIDMgQ0Cg8KCAYAAgAEmwgAEgMyBDQKQwoEBgACARIENgI8Axo1IEdldHMgdGhlIGRl
dGFpbHMgb2YgYSBzcGVjaWZpYyBgVnBjRmxvd0xvZ3NDb25maWdgLgoKDAoFBgACAQESAzYG
GgoMCgUGAAIBAhIDNhs2CgwKBQYAAgEDEgM3DyAKDQoFBgACAQQSBDgEOgYKEQoJBgACAQSw
yrwiEgQ4BDoGCgwKBQYAAgEEEgM7BDIKDwoIBgACAQSbCAASAzsEMgq+BAoEBgACAhIETQJZ
AxqvBCBDcmVhdGVzIGEgbmV3IGBWcGNGbG93TG9nc0NvbmZpZ2AuCiBJZiBhIGNvbmZpZ3Vy
YXRpb24gd2l0aCB0aGUgZXhhY3Qgc2FtZSBzZXR0aW5ncyBhbHJlYWR5IGV4aXN0cyAoZXZl
biBpZiB0aGUKIElEIGlzIGRpZmZlcmVudCksIHRoZSBjcmVhdGlvbiBmYWlscy4KIE5vdGVz
OgoKICAgMS4gQ3JlYXRpbmcgYSBjb25maWd1cmF0aW9uIHdpdGggYHN0YXRlPURJU0FCTEVE
YCB3aWxsIGZhaWwKICAgMi4gVGhlIGZvbGxvd2luZyBmaWVsZHMgYXJlIG5vdCBjb25zaWRl
cmVkIGFzIHNldHRpbmdzIGZvciB0aGUgcHVycG9zZQogICBvZiB0aGUgY2hlY2sgbWVudGlv
bmVkIGFib3ZlLCB0aGVyZWZvcmUgLSBjcmVhdGluZyBhbm90aGVyIGNvbmZpZ3VyYXRpb24K
ICAgd2l0aCB0aGUgc2FtZSBmaWVsZHMgYnV0IGRpZmZlcmVudCB2YWx1ZXMgZm9yIHRoZSBm
b2xsb3dpbmcgZmllbGRzIHdpbGwKICAgZmFpbCBhcyB3ZWxsOgogICAgICAgKiBuYW1lCiAg
ICAgICAqIGNyZWF0ZV90aW1lCiAgICAgICAqIHVwZGF0ZV90aW1lCiAgICAgICAqIGxhYmVs
cwogICAgICAgKiBkZXNjcmlwdGlvbgoKDAoFBgACAgESA00GHQoMCgUGAAICAhIDTR48CgwK
BQYAAgIDEgNODysKDQoFBgACAgQSBE8EUgYKEQoJBgACAgSwyrwiEgRPBFIGCg0KBQYAAgIE
EgRTBFQ+ChAKCAYAAgIEmwgAEgRTBFQ+Cg0KBQYAAgIEEgRVBFgGCg8KBwYAAgIEmQgSBFUE
WAYKxAQKBAYAAgMSBGoCdQMatQQgVXBkYXRlcyBhbiBleGlzdGluZyBgVnBjRmxvd0xvZ3ND
b25maWdgLgogSWYgYSBjb25maWd1cmF0aW9uIHdpdGggdGhlIGV4YWN0IHNhbWUgc2V0dGlu
Z3MgYWxyZWFkeSBleGlzdHMgKGV2ZW4gaWYgdGhlCiBJRCBpcyBkaWZmZXJlbnQpLCB0aGUg
Y3JlYXRpb24gZmFpbHMuCiBOb3RlczoKCiAgIDEuIFVwZGF0aW5nIGEgY29uZmlndXJhdGlv
biB3aXRoIGBzdGF0ZT1ESVNBQkxFRGAgd2lsbCBmYWlsCiAgIDIuIFRoZSBmb2xsb3dpbmcg
ZmllbGRzIGFyZSBub3QgY29uc2lkZXJlZCBhcyBzZXR0aW5ncyBmb3IgdGhlIHB1cnBvc2UK
ICAgb2YgdGhlIGNoZWNrIG1lbnRpb25lZCBhYm92ZSwgdGhlcmVmb3JlIC0gdXBkYXRpbmcg
YW5vdGhlciBjb25maWd1cmF0aW9uCiAgIHdpdGggdGhlIHNhbWUgZmllbGRzIGJ1dCBkaWZm
ZXJlbnQgdmFsdWVzIGZvciB0aGUgZm9sbG93aW5nIGZpZWxkcyB3aWxsCiAgIGZhaWwgYXMg
d2VsbDoKICAgICAgICogbmFtZQogICAgICAgKiBjcmVhdGVfdGltZQogICAgICAgKiB1cGRh
dGVfdGltZQogICAgICAgKiBsYWJlbHMKICAgICAgICogZGVzY3JpcHRpb24KCgwKBQYAAgMB
EgNqBh0KDAoFBgACAwISA2oePAoMCgUGAAIDAxIDaw8rCg0KBQYAAgMEEgRsBG8GChEKCQYA
AgMEsMq8IhIEbARvBgoMCgUGAAIDBBIDcAROCg8KCAYAAgMEmwgAEgNwBE4KDQoFBgACAwQS
BHEEdAYKDwoHBgACAwSZCBIEcQR0Bgo4CgQGAAIEEgV4AoIBAxopIERlbGV0ZXMgYSBzcGVj
aWZpYyBgVnBjRmxvd0xvZ3NDb25maWdgLgoKDAoFBgACBAESA3gGHQoMCgUGAAIEAhIDeB48
CgwKBQYAAgQDEgN5DysKDQoFBgACBAQSBHoEfAYKEQoJBgACBASwyrwiEgR6BHwGCgwKBQYA
AgQEEgN9BDIKDwoIBgACBASbCAASA30EMgoOCgUGAAIEBBIFfgSBAQYKEAoHBgACBASZCBIF
fgSBAQYKmQEKBAYAAgUSBoYBAosBAxqIASBRdWVyeU9yZ1ZwY0Zsb3dMb2dzQ29uZmlncyBy
ZXR1cm5zIGEgbGlzdCBvZiBhbGwgb3JnYW5pemF0aW9uLWxldmVsIFZQQwogRmxvdyBMb2dz
IGNvbmZpZ3VyYXRpb25zIGFwcGxpY2FibGUgdG8gdGhlIHNwZWNpZmllZCBwcm9qZWN0LgoK
DQoFBgACBQESBIYBBiAKDQoFBgACBQISBIYBIUIKDQoFBgACBQMSBIcBDzEKDwoFBgACBQQS
BogBBIoBBgoTCgkGAAIFBLDKvCISBogBBIoBBgqGAQoEBgACBhIGjwEClAEDGnYgU2hvd0Vm
ZmVjdGl2ZUZsb3dMb2dzQ29uZmlncyByZXR1cm5zIGEgbGlzdCBvZiBhbGwgVlBDIEZsb3cg
TG9ncwogY29uZmlndXJhdGlvbnMgYXBwbGljYWJsZSB0byBhIHNwZWNpZmllZCByZXNvdXJj
ZS4KCg0KBQYAAgYBEgSPAQYiCg0KBQYAAgYCEgSPASNGCg0KBQYAAgYDEgSQAQ8zCg8KBQYA
AgYEEgaRAQSTAQYKEwoJBgACBgSwyrwiEgaRAQSTAQYK/AEKAgYBEgabAQD3AQEa7QEgVGhl
IFZQQyBGbG93IExvZ3Mgb3JnYW5pemF0aW9uIHNlcnZpY2UgaW4gdGhlIEdvb2dsZSBDbG91
ZCBOZXR3b3JrIE1hbmFnZW1lbnQKIEFQSSBwcm92aWRlcyBvcmdhbml6YXRpb24gbGV2ZWwg
Y29uZmlndXJhdGlvbnMgdGhhdCBnZW5lcmF0ZSBGbG93IExvZ3MuIFRoZQogc2VydmljZSBh
bmQgdGhlIGNvbmZpZ3VyYXRpb24gcmVzb3VyY2VzIGNyZWF0ZWQgdXNpbmcgdGhpcyBzZXJ2
aWNlIGFyZQogZ2xvYmFsLgoKCwoDBgEBEgSbAQgmCgsKAwYBAxIEnAECSAoNCgUGAQOZCBIE
nAECSAoNCgMGAQMSBp0BAp4BNwoPCgUGAQOaCBIGnQECngE3CkkKBAYBAgASBqEBAqcBAxo5
IExpc3RzIGFsbCBgVnBjRmxvd0xvZ3NDb25maWdzYCBpbiBhIGdpdmVuIG9yZ2FuaXphdGlv
bi4KCg0KBQYBAgABEgShAQYcCg0KBQYBAgACEgShAR06Cg0KBQYBAgADEgSiAQ8tCg8KBQYB
AgAEEgajAQSlAQYKEwoJBgECAASwyrwiEgajAQSlAQYKDQoFBgECAAQSBKYBBDQKEAoIBgEC
AASbCAASBKYBBDQKRQoEBgECARIGqgECsAEDGjUgR2V0cyB0aGUgZGV0YWlscyBvZiBhIHNw
ZWNpZmljIGBWcGNGbG93TG9nc0NvbmZpZ2AuCgoNCgUGAQIBARIEqgEGGgoNCgUGAQIBAhIE
qgEbNgoNCgUGAQIBAxIEqwEPIAoPCgUGAQIBBBIGrAEErgEGChMKCQYBAgEEsMq8IhIGrAEE
rgEGCg0KBQYBAgEEEgSvAQQyChAKCAYBAgEEmwgAEgSvAQQyCsAECgQGAQICEgbBAQLNAQMa
rwQgQ3JlYXRlcyBhIG5ldyBgVnBjRmxvd0xvZ3NDb25maWdgLgogSWYgYSBjb25maWd1cmF0
aW9uIHdpdGggdGhlIGV4YWN0IHNhbWUgc2V0dGluZ3MgYWxyZWFkeSBleGlzdHMgKGV2ZW4g
aWYgdGhlCiBJRCBpcyBkaWZmZXJlbnQpLCB0aGUgY3JlYXRpb24gZmFpbHMuCiBOb3RlczoK
CiAgIDEuIENyZWF0aW5nIGEgY29uZmlndXJhdGlvbiB3aXRoIGBzdGF0ZT1ESVNBQkxFRGAg
d2lsbCBmYWlsCiAgIDIuIFRoZSBmb2xsb3dpbmcgZmllbGRzIGFyZSBub3QgY29uc2lkZXJl
ZCBhcyBzZXR0aW5ncyBmb3IgdGhlIHB1cnBvc2UKICAgb2YgdGhlIGNoZWNrIG1lbnRpb25l
ZCBhYm92ZSwgdGhlcmVmb3JlIC0gY3JlYXRpbmcgYW5vdGhlciBjb25maWd1cmF0aW9uCiAg
IHdpdGggdGhlIHNhbWUgZmllbGRzIGJ1dCBkaWZmZXJlbnQgdmFsdWVzIGZvciB0aGUgZm9s
bG93aW5nIGZpZWxkcyB3aWxsCiAgIGZhaWwgYXMgd2VsbDoKICAgICAgICogbmFtZQogICAg
ICAgKiBjcmVhdGVfdGltZQogICAgICAgKiB1cGRhdGVfdGltZQogICAgICAgKiBsYWJlbHMK
ICAgICAgICogZGVzY3JpcHRpb24KCg0KBQYBAgIBEgTBAQYdCg0KBQYBAgICEgTBAR48Cg0K
BQYBAgIDEgTCAQ8rCg8KBQYBAgIEEgbDAQTGAQYKEwoJBgECAgSwyrwiEgbDAQTGAQYKDwoF
BgECAgQSBscBBMgBPgoSCggGAQICBJsIABIGxwEEyAE+Cg8KBQYBAgIEEgbJAQTMAQYKEQoH
BgECAgSZCBIGyQEEzAEGCsYECgQGAQIDEgbeAQLpAQMatQQgVXBkYXRlcyBhbiBleGlzdGlu
ZyBgVnBjRmxvd0xvZ3NDb25maWdgLgogSWYgYSBjb25maWd1cmF0aW9uIHdpdGggdGhlIGV4
YWN0IHNhbWUgc2V0dGluZ3MgYWxyZWFkeSBleGlzdHMgKGV2ZW4gaWYgdGhlCiBJRCBpcyBk
aWZmZXJlbnQpLCB0aGUgY3JlYXRpb24gZmFpbHMuCiBOb3RlczoKCiAgIDEuIFVwZGF0aW5n
IGEgY29uZmlndXJhdGlvbiB3aXRoIGBzdGF0ZT1ESVNBQkxFRGAgd2lsbCBmYWlsCiAgIDIu
IFRoZSBmb2xsb3dpbmcgZmllbGRzIGFyZSBub3QgY29uc2lkZXJlZCBhcyBzZXR0aW5ncyBm
b3IgdGhlIHB1cnBvc2UKICAgb2YgdGhlIGNoZWNrIG1lbnRpb25lZCBhYm92ZSwgdGhlcmVm
b3JlIC0gdXBkYXRpbmcgYW5vdGhlciBjb25maWd1cmF0aW9uCiAgIHdpdGggdGhlIHNhbWUg
ZmllbGRzIGJ1dCBkaWZmZXJlbnQgdmFsdWVzIGZvciB0aGUgZm9sbG93aW5nIGZpZWxkcyB3
aWxsCiAgIGZhaWwgYXMgd2VsbDoKICAgICAgICogbmFtZQogICAgICAgKiBjcmVhdGVfdGlt
ZQogICAgICAgKiB1cGRhdGVfdGltZQogICAgICAgKiBsYWJlbHMKICAgICAgICogZGVzY3Jp
cHRpb24KCg0KBQYBAgMBEgTeAQYdCg0KBQYBAgMCEgTeAR48Cg0KBQYBAgMDEgTfAQ8rCg8K
BQYBAgMEEgbgAQTjAQYKEwoJBgECAwSwyrwiEgbgAQTjAQYKDQoFBgECAwQSBOQBBE4KEAoI
BgECAwSbCAASBOQBBE4KDwoFBgECAwQSBuUBBOgBBgoRCgcGAQIDBJkIEgblAQToAQYKOQoE
BgECBBIG7AEC9gEDGikgRGVsZXRlcyBhIHNwZWNpZmljIGBWcGNGbG93TG9nc0NvbmZpZ2Au
CgoNCgUGAQIEARIE7AEGHQoNCgUGAQIEAhIE7AEePAoNCgUGAQIEAxIE7QEPKwoPCgUGAQIE
BBIG7gEE8AEGChMKCQYBAgQEsMq8IhIG7gEE8AEGCg0KBQYBAgQEEgTxAQQyChAKCAYBAgQE
mwgAEgTxAQQyCg8KBQYBAgQEEgbyAQT1AQYKEQoHBgECBASZCBIG8gEE9QEGCkAKAgQAEgb6
AQCXAgEaMiBSZXF1ZXN0IGZvciB0aGUgYExpc3RWcGNGbG93TG9nc0NvbmZpZ3NgIG1ldGhv
ZC4KCgsKAwQAARIE+gEIJQqQAgoEBAACABIGggIChwIEGv8BIFJlcXVpcmVkLiBUaGUgcGFy
ZW50IHJlc291cmNlIG9mIHRoZSBWcGNGbG93TG9nc0NvbmZpZywKIGluIG9uZSBvZiB0aGUg
Zm9sbG93aW5nIGZvcm1hdHM6CgogLSBGb3IgcHJvamVjdC1sZXZlbCByZXNvdXJjZXM6IGBw
cm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2JhbGAKCiAtIEZvciBvcmdhbml6
YXRpb24tbGV2ZWwgcmVzb3VyY2VzOgogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9p
ZH0vbG9jYXRpb25zL2dsb2JhbGAKCg0KBQQAAgAFEgSCAgIICg0KBQQAAgABEgSCAgkPCg0K
BQQAAgADEgSCAhITCg8KBQQAAgAIEgaCAhSHAgMKEAoIBAACAAicCAASBIMCBCoKEQoHBAAC
AAifCBIGhAIEhgIFCkMKBAQAAgESBIoCAj8aNSBPcHRpb25hbC4gTnVtYmVyIG9mIGBWcGNG
bG93TG9nc0NvbmZpZ3NgIHRvIHJldHVybi4KCg0KBQQAAgEFEgSKAgIHCg0KBQQAAgEBEgSK
AggRCg0KBQQAAgEDEgSKAhQVCg0KBQQAAgEIEgSKAhY+ChAKCAQAAgEInAgAEgSKAhc9Cl4K
BAQAAgISBI4CAkEaUCBPcHRpb25hbC4gUGFnZSB0b2tlbiBmcm9tIGFuIGVhcmxpZXIgcXVl
cnksIGFzIHJldHVybmVkIGluCiBgbmV4dF9wYWdlX3Rva2VuYC4KCg0KBQQAAgIFEgSOAgII
Cg0KBQQAAgIBEgSOAgkTCg0KBQQAAgIDEgSOAhYXCg0KBQQAAgIIEgSOAhhAChAKCAQAAgII
nAgAEgSOAhk/CvkBCgQEAAIDEgSTAgI9GuoBIE9wdGlvbmFsLiBMaXN0cyB0aGUgYFZwY0Zs
b3dMb2dzQ29uZmlnc2AgdGhhdCBtYXRjaCB0aGUgZmlsdGVyIGV4cHJlc3Npb24uCiBBIGZp
bHRlciBleHByZXNzaW9uIG11c3QgdXNlIHRoZSBzdXBwb3J0ZWQgW0NFTCBsb2dpYyBvcGVy
YXRvcnNdCiAoaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3ZwYy9kb2NzL2Fib3V0LWZsb3ct
bG9ncy1yZWNvcmRzI3N1cHBvcnRlZF9jZWxfbG9naWNfb3BlcmF0b3JzKS4KCg0KBQQAAgMF
EgSTAgIICg0KBQQAAgMBEgSTAgkPCg0KBQQAAgMDEgSTAhITCg0KBQQAAgMIEgSTAhQ8ChAK
CAQAAgMInAgAEgSTAhU7CjgKBAQAAgQSBJYCAj8aKiBPcHRpb25hbC4gRmllbGQgdG8gdXNl
IHRvIHNvcnQgdGhlIGxpc3QuCgoNCgUEAAIEBRIElgICCAoNCgUEAAIEARIElgIJEQoNCgUE
AAIEAxIElgIUFQoNCgUEAAIECBIElgIWPgoQCggEAAIECJwIABIElgIXPQpBCgIEARIGmgIA
owIBGjMgUmVzcG9uc2UgZm9yIHRoZSBgTGlzdFZwY0Zsb3dMb2dzQ29uZmlnc2AgbWV0aG9k
LgoKCwoDBAEBEgSaAggmCjQKBAQBAgASBJwCAjcaJiBMaXN0IG9mIFZQQyBGbG93IExvZyBj
b25maWd1cmF0aW9ucy4KCg0KBQQBAgAEEgScAgIKCg0KBQQBAgAGEgScAgscCg0KBQQBAgAB
EgScAh0yCg0KBQQBAgADEgScAjU2CkMKBAQBAgESBJ8CAh0aNSBQYWdlIHRva2VuIHRvIGZl
dGNoIHRoZSBuZXh0IHNldCBvZiBjb25maWd1cmF0aW9ucy4KCg0KBQQBAgEFEgSfAgIICg0K
BQQBAgEBEgSfAgkYCg0KBQQBAgEDEgSfAhscClsKBAQBAgISBKICAiIaTSBMb2NhdGlvbnMg
dGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZCAod2hlbiBxdWVyeWluZyBhbGwgbG9jYXRpb25z
IHdpdGggYC1gKS4KCg0KBQQBAgIEEgSiAgIKCg0KBQQBAgIFEgSiAgsRCg0KBQQBAgIBEgSi
AhIdCg0KBQQBAgIDEgSiAiAhCj4KAgQCEgamAgC1AgEaMCBSZXF1ZXN0IGZvciB0aGUgYEdl
dFZwY0Zsb3dMb2dzQ29uZmlnYCBtZXRob2QuCgoLCgMEAgESBKYCCCMK6QIKBAQCAgASBq8C
ArQCBBrYAiBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFZwY0Zsb3dMb2dz
Q29uZmlnLAogaW4gb25lIG9mIHRoZSBmb2xsb3dpbmcgZm9ybWF0czoKCiAtIEZvciBwcm9q
ZWN0LWxldmVsIHJlc291cmNlczoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25z
L2dsb2JhbC92cGNGbG93TG9nc0NvbmZpZ3Mve3ZwY19mbG93X2xvZ3NfY29uZmlnX2lkfWAK
CiAtIEZvciBvcmdhbml6YXRpb24tbGV2ZWwgcmVzb3VyY2VzOgogYG9yZ2FuaXphdGlvbnMv
e29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL2dsb2JhbC92cGNGbG93TG9nc0NvbmZpZ3Mv
e3ZwY19mbG93X2xvZ3NfY29uZmlnX2lkfWAKCg0KBQQCAgAFEgSvAgIICg0KBQQCAgABEgSv
AgkNCg0KBQQCAgADEgSvAhARCg8KBQQCAgAIEgavAhK0AgMKEAoIBAICAAicCAASBLACBCoK
EQoHBAICAAifCBIGsQIEswIFCkEKAgQDEga4AgDSAgEaMyBSZXF1ZXN0IGZvciB0aGUgYENy
ZWF0ZVZwY0Zsb3dMb2dzQ29uZmlnYCBtZXRob2QuCgoLCgMEAwESBLgCCCYKmgIKBAQDAgAS
BsACAsUCBBqJAiBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBvZiB0aGUgVnBjRmxv
d0xvZ3NDb25maWcgdG8gY3JlYXRlLAogaW4gb25lIG9mIHRoZSBmb2xsb3dpbmcgZm9ybWF0
czoKCiAtIEZvciBwcm9qZWN0LWxldmVsIHJlc291cmNlczogYHByb2plY3RzL3twcm9qZWN0
X2lkfS9sb2NhdGlvbnMvZ2xvYmFsYAoKIC0gRm9yIG9yZ2FuaXphdGlvbi1sZXZlbCByZXNv
dXJjZXM6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMvZ2xv
YmFsYAoKDQoFBAMCAAUSBMACAggKDQoFBAMCAAESBMACCQ8KDQoFBAMCAAMSBMACEhMKDwoF
BAMCAAgSBsACFMUCAwoQCggEAwIACJwIABIEwQIEKgoRCgcEAwIACJ8IEgbCAgTEAgUKOgoE
BAMCARIGyAICzQIEGiogUmVxdWlyZWQuIElEIG9mIHRoZSBgVnBjRmxvd0xvZ3NDb25maWdg
LgoKDQoFBAMCAQUSBMgCAggKDQoFBAMCAQESBMgCCSAKDQoFBAMCAQMSBMgCIyQKDwoFBAMC
AQgSBsgCJc0CAwoQCggEAwIBCJwIABIEyQIEKgoRCgcEAwIBCJ8IEgbKAgTMAgUKOgoEBAMC
AhIG0AIC0QIvGiogUmVxdWlyZWQuIEEgYFZwY0Zsb3dMb2dzQ29uZmlnYCByZXNvdXJjZQoK
DQoFBAMCAgYSBNACAhMKDQoFBAMCAgESBNACFCgKDQoFBAMCAgMSBNACKywKDQoFBAMCAggS
BNECBi4KEAoIBAMCAgicCAASBNECBy0KQQoCBAQSBtUCAOQCARozIFJlcXVlc3QgZm9yIHRo
ZSBgVXBkYXRlVnBjRmxvd0xvZ3NDb25maWdgIG1ldGhvZC4KCgsKAwQEARIE1QIIJgqHAwoE
BAQCABIG3gIC3wIvGvYCIFJlcXVpcmVkLiBNYXNrIG9mIGZpZWxkcyB0byB1cGRhdGUuIEF0
IGxlYXN0IG9uZSBwYXRoIG11c3QgYmUgc3VwcGxpZWQgaW4KIHRoaXMgZmllbGQuCiBGb3Ig
ZXhhbXBsZSwgdG8gY2hhbmdlIHRoZSBzdGF0ZSBvZiB0aGUgY29uZmlndXJhdGlvbiB0byBF
TkFCTEVELCBzcGVjaWZ5CiAgIGB1cGRhdGVfbWFza2AgPSBgInN0YXRlImAsIGFuZCB0aGUg
YHZwY19mbG93X2xvZ3NfY29uZmlnYCB3b3VsZCBiZToKICAgYHZwY19mbG93X2xvZ3NfY29u
ZmlnID0gewogICAgIG5hbWUgPQogICAgICJwcm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0aW9u
cy9nbG9iYWwvdnBjRmxvd0xvZ3NDb25maWdzL215LWNvbmZpZyIKICAgICBzdGF0ZSA9ICJF
TkFCTEVEIiB9YAoKDQoFBAQCAAYSBN4CAhsKDQoFBAQCAAESBN4CHCcKDQoFBAQCAAMSBN4C
KisKDQoFBAQCAAgSBN8CBi4KEAoIBAQCAAicCAASBN8CBy0KTQoEBAQCARIG4gIC4wIvGj0g
UmVxdWlyZWQuIE9ubHkgZmllbGRzIHNwZWNpZmllZCBpbiB1cGRhdGVfbWFzayBhcmUgdXBk
YXRlZC4KCg0KBQQEAgEGEgTiAgITCg0KBQQEAgEBEgTiAhQoCg0KBQQEAgEDEgTiAissCg0K
BQQEAgEIEgTjAgYuChAKCAQEAgEInAgAEgTjAgctCkEKAgQFEgbnAgD2AgEaMyBSZXF1ZXN0
IGZvciB0aGUgYERlbGV0ZVZwY0Zsb3dMb2dzQ29uZmlnYCBtZXRob2QuCgoLCgMEBQESBOcC
CCYK7AIKBAQFAgASBvACAvUCBBrbAiBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIFZwY0Zsb3dMb2dzQ29uZmlnLAogaW4gb25lIG9mIHRoZSBmb2xsb3dpbmcgZm9ybWF0
czoKCiAtIEZvciBhIHByb2plY3QtbGV2ZWwgcmVzb3VyY2U6CiBgcHJvamVjdHMve3Byb2pl
Y3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwvdnBjRmxvd0xvZ3NDb25maWdzL3t2cGNfZmxvd19s
b2dzX2NvbmZpZ19pZH1gCgogLSBGb3IgYW4gb3JnYW5pemF0aW9uLWxldmVsIHJlc291cmNl
OgogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL2dsb2JhbC92
cGNGbG93TG9nc0NvbmZpZ3Mve3ZwY19mbG93X2xvZ3NfY29uZmlnX2lkfWAKCg0KBQQFAgAF
EgTwAgIICg0KBQQFAgABEgTwAgkNCg0KBQQFAgADEgTwAhARCg8KBQQFAgAIEgbwAhL1AgMK
EAoIBAUCAAicCAASBPECBCoKEQoHBAUCAAifCBIG8gIE9AIFCkQKAgQGEgb5AgCOAwEaNiBS
ZXF1ZXN0IGZvciB0aGUgYFF1ZXJ5T3JnVnBjRmxvd0xvZ3NDb25maWdzYCBtZXRob2QuCgoL
CgMEBgESBPkCCCkKlwEKBAQGAgASBvwCAoEDBBqGASBSZXF1aXJlZC4gVGhlIHBhcmVudCBy
ZXNvdXJjZSBvZiB0aGUgVnBjRmxvd0xvZ3NDb25maWcsIHNwZWNpZmllZCBpbgogdGhlIGZv
bGxvd2luZyBmb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2Jh
bGAKCg0KBQQGAgAFEgT8AgIICg0KBQQGAgABEgT8AgkPCg0KBQQGAgADEgT8AhITCg8KBQQG
AgAIEgb8AhSBAwMKEAoIBAYCAAicCAASBP0CBCoKEQoHBAYCAAifCBIG/gIEgAMFCkMKBAQG
AgESBIQDAj8aNSBPcHRpb25hbC4gTnVtYmVyIG9mIGBWcGNGbG93TG9nc0NvbmZpZ3NgIHRv
IHJldHVybi4KCg0KBQQGAgEFEgSEAwIHCg0KBQQGAgEBEgSEAwgRCg0KBQQGAgEDEgSEAxQV
Cg0KBQQGAgEIEgSEAxY+ChAKCAQGAgEInAgAEgSEAxc9Cl4KBAQGAgISBIgDAkEaUCBPcHRp
b25hbC4gUGFnZSB0b2tlbiBmcm9tIGFuIGVhcmxpZXIgcXVlcnksIGFzIHJldHVybmVkIGlu
CiBgbmV4dF9wYWdlX3Rva2VuYC4KCg0KBQQGAgIFEgSIAwIICg0KBQQGAgIBEgSIAwkTCg0K
BQQGAgIDEgSIAxYXCg0KBQQGAgIIEgSIAxhAChAKCAQGAgIInAgAEgSIAxk/CvkBCgQEBgID
EgSNAwI9GuoBIE9wdGlvbmFsLiBMaXN0cyB0aGUgYFZwY0Zsb3dMb2dzQ29uZmlnc2AgdGhh
dCBtYXRjaCB0aGUgZmlsdGVyIGV4cHJlc3Npb24uCiBBIGZpbHRlciBleHByZXNzaW9uIG11
c3QgdXNlIHRoZSBzdXBwb3J0ZWQgW0NFTCBsb2dpYyBvcGVyYXRvcnNdCiAoaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL3ZwYy9kb2NzL2Fib3V0LWZsb3ctbG9ncy1yZWNvcmRzI3N1cHBv
cnRlZF9jZWxfbG9naWNfb3BlcmF0b3JzKS4KCg0KBQQGAgMFEgSNAwIICg0KBQQGAgMBEgSN
AwkPCg0KBQQGAgMDEgSNAxITCg0KBQQGAgMIEgSNAxQ8ChAKCAQGAgMInAgAEgSNAxU7CkIK
AgQHEgaRAwCaAwEaNCBSZXNwb25zZSBmb3IgdGhlIGBRdWVyeVZwY0Zsb3dMb2dzQ29uZmln
c2AgbWV0aG9kLgoKCwoDBAcBEgSRAwgqCjQKBAQHAgASBJMDAjcaJiBMaXN0IG9mIFZQQyBG
bG93IExvZyBjb25maWd1cmF0aW9ucy4KCg0KBQQHAgAEEgSTAwIKCg0KBQQHAgAGEgSTAwsc
Cg0KBQQHAgABEgSTAx0yCg0KBQQHAgADEgSTAzU2CkMKBAQHAgESBJYDAh0aNSBQYWdlIHRv
a2VuIHRvIGZldGNoIHRoZSBuZXh0IHNldCBvZiBjb25maWd1cmF0aW9ucy4KCg0KBQQHAgEF
EgSWAwIICg0KBQQHAgEBEgSWAwkYCg0KBQQHAgEDEgSWAxscClsKBAQHAgISBJkDAiIaTSBM
b2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZCAod2hlbiBxdWVyeWluZyBhbGwg
bG9jYXRpb25zIHdpdGggYC1gKS4KCg0KBQQHAgIEEgSZAwIKCg0KBQQHAgIFEgSZAwsRCg0K
BQQHAgIBEgSZAxIdCg0KBQQHAgIDEgSZAyAhCkYKAgQIEgadAwC5AwEaOCBSZXF1ZXN0IGZv
ciB0aGUgYFNob3dFZmZlY3RpdmVGbG93TG9nc0NvbmZpZ3NgIG1ldGhvZC4KCgsKAwQIARIE
nQMIKwqXAQoEBAgCABIGoAMCpQMEGoYBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNl
IG9mIHRoZSBWcGNGbG93TG9nc0NvbmZpZywgc3BlY2lmaWVkIGluCiB0aGUgZm9sbG93aW5n
IGZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsYAoKDQoF
BAgCAAUSBKADAggKDQoFBAgCAAESBKADCQ8KDQoFBAgCAAMSBKADEhMKDwoFBAgCAAgSBqAD
FKUDAwoQCggECAIACJwIABIEoQMEKgoRCgcECAIACJ8IEgaiAwSkAwUK+wEKBAQIAgESBKsD
Aj8a7AEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSB0byBnZXQgdGhlIGVmZmVjdGl2ZSBWUEMg
RmxvdyBMb2dzIGNvbmZpZ3VyYXRpb24KIGZvci4gVGhlIHJlc291cmNlIG11c3QgYmVsb25n
IHRvIHRoZSBzYW1lIHByb2plY3QgYXMgdGhlIHBhcmVudC4gVGhlCiByZXNvdXJjZSBtdXN0
IGJlIGEgbmV0d29yaywgc3VibmV0d29yaywgaW50ZXJjb25uZWN0IGF0dGFjaG1lbnQsIFZQ
TgogdHVubmVsLCBvciBhIHByb2plY3QuCgoNCgUECAIBBRIEqwMCCAoNCgUECAIBARIEqwMJ
EQoNCgUECAIBAxIEqwMUFQoNCgUECAIBCBIEqwMWPgoQCggECAIBCJwIABIEqwMXPQpbCgQE
CAICEgSuAwI/Gk0gT3B0aW9uYWwuIE51bWJlciBvZiBgRWZmZWN0aXZlVnBjRmxvd0xvZ3ND
b25maWdzYCB0byByZXR1cm4uIERlZmF1bHQgaXMgMzAuCgoNCgUECAICBRIErgMCBwoNCgUE
CAICARIErgMIEQoNCgUECAICAxIErgMUFQoNCgUECAICCBIErgMWPgoQCggECAICCJwIABIE
rgMXPQpeCgQECAIDEgSyAwJBGlAgT3B0aW9uYWwuIFBhZ2UgdG9rZW4gZnJvbSBhbiBlYXJs
aWVyIHF1ZXJ5LCBhcyByZXR1cm5lZCBpbgogYG5leHRfcGFnZV90b2tlbmAuCgoNCgUECAID
BRIEsgMCCAoNCgUECAIDARIEsgMJEwoNCgUECAIDAxIEsgMWFwoNCgUECAIDCBIEsgMYQAoQ
CggECAIDCJwIABIEsgMZPwqDAgoEBAgCBBIEuAMCPRr0ASBPcHRpb25hbC4gTGlzdHMgdGhl
IGBFZmZlY3RpdmVWcGNGbG93TG9nc0NvbmZpZ3NgIHRoYXQgbWF0Y2ggdGhlIGZpbHRlcgog
ZXhwcmVzc2lvbi4gQSBmaWx0ZXIgZXhwcmVzc2lvbiBtdXN0IHVzZSB0aGUgc3VwcG9ydGVk
IFtDRUwgbG9naWMKIG9wZXJhdG9yc10KIChodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vdnBj
L2RvY3MvYWJvdXQtZmxvdy1sb2dzLXJlY29yZHMjc3VwcG9ydGVkX2NlbF9sb2dpY19vcGVy
YXRvcnMpLgoKDQoFBAgCBAUSBLgDAggKDQoFBAgCBAESBLgDCQ8KDQoFBAgCBAMSBLgDEhMK
DQoFBAgCBAgSBLgDFDwKEAoIBAgCBAicCAASBLgDFTsKRwoCBAkSBrwDAMUDARo5IFJlc3Bv
bnNlIGZvciB0aGUgYFNob3dFZmZlY3RpdmVGbG93TG9nc0NvbmZpZ3NgIG1ldGhvZC4KCgsK
AwQJARIEvAMILAo/CgQECQIAEgS+AwJGGjEgTGlzdCBvZiBFZmZlY3RpdmUgVnBjIEZsb3cg
TG9ncyBjb25maWd1cmF0aW9ucy4KCg0KBQQJAgAEEgS+AwIKCg0KBQQJAgAGEgS+AwslCg0K
BQQJAgABEgS+AyZBCg0KBQQJAgADEgS+A0RFCkMKBAQJAgESBMEDAh0aNSBQYWdlIHRva2Vu
IHRvIGZldGNoIHRoZSBuZXh0IHNldCBvZiBjb25maWd1cmF0aW9ucy4KCg0KBQQJAgEFEgTB
AwIICg0KBQQJAgEBEgTBAwkYCg0KBQQJAgEDEgTBAxscClsKBAQJAgISBMQDAiIaTSBMb2Nh
dGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZCAod2hlbiBxdWVyeWluZyBhbGwgbG9j
YXRpb25zIHdpdGggYC1gKS4KCg0KBQQJAgIEEgTEAwIKCg0KBQQJAgIFEgTEAwsRCg0KBQQJ
AgIBEgTEAxIdCg0KBQQJAgIDEgTEAyAhYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest ===
    # Fields for ListVpcFlowLogsConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse ===
    # Fields for ListVpcFlowLogsConfigsResponse
    # Field: vpc_flow_logs_configs Type: 11 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::GetVpcFlowLogsConfigRequest ===
    # Fields for GetVpcFlowLogsConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest ===
    # Fields for CreateVpcFlowLogsConfigRequest
    # Field: parent Type: 9 ()
    # Field: vpc_flow_logs_config_id Type: 9 ()
    # Field: vpc_flow_logs_config Type: 11 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig)

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest ===
    # Fields for UpdateVpcFlowLogsConfigRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: vpc_flow_logs_config Type: 11 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig)

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest ===
    # Fields for DeleteVpcFlowLogsConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest ===
    # Fields for QueryOrgVpcFlowLogsConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse ===
    # Fields for QueryOrgVpcFlowLogsConfigsResponse
    # Field: vpc_flow_logs_configs Type: 11 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest ===
    # Fields for ShowEffectiveFlowLogsConfigsRequest
    # Field: parent Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse ===
    # Fields for ShowEffectiveFlowLogsConfigsResponse
    # Field: effective_flow_logs_configs Type: 11 (.google.cloud.networkmanagement.v1beta1.EffectiveVpcFlowLogsConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Service Client: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::VpcFlowLogsServiceClient ===
package Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::VpcFlowLogsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::VpcFlowLogsServiceClient

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
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.VpcFlowLogsService',
        method         => 'ListVpcFlowLogsConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse',
    });
}

sub get_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::GetVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.VpcFlowLogsService',
        method         => 'GetVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig',
    });
}

sub create_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.VpcFlowLogsService',
        method         => 'CreateVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.VpcFlowLogsService',
        method         => 'UpdateVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.VpcFlowLogsService',
        method         => 'DeleteVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub query_org_vpc_flow_logs_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.VpcFlowLogsService',
        method         => 'QueryOrgVpcFlowLogsConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse',
    });
}

sub show_effective_flow_logs_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.VpcFlowLogsService',
        method         => 'ShowEffectiveFlowLogsConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse',
    });
}

# === Service Client: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::OrganizationVpcFlowLogsServiceClient ===
package Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::OrganizationVpcFlowLogsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::OrganizationVpcFlowLogsServiceClient

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
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.OrganizationVpcFlowLogsService',
        method         => 'ListVpcFlowLogsConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse',
    });
}

sub get_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::GetVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.OrganizationVpcFlowLogsService',
        method         => 'GetVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig',
    });
}

sub create_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.OrganizationVpcFlowLogsService',
        method         => 'CreateVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.OrganizationVpcFlowLogsService',
        method         => 'UpdateVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_vpc_flow_logs_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.OrganizationVpcFlowLogsService',
        method         => 'DeleteVpcFlowLogsConfig',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs - Compiled Protocol Buffers messages for google/cloud/networkmanagement/v1beta1/vpc_flow_logs.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs;

    my $msg = Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkmanagement/v1beta1/vpc_flow_logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest

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

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse

Response for the `ListVpcFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vpc_flow_logs_configs() >> / C<< $msg->vpc_flow_logs_configs($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig>)

List of VPC Flow Log configurations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token to fetch the next set of configurations.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached (when querying all locations with `-`).

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::GetVpcFlowLogsConfigRequest

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

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest

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

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig>)

Required. A `VpcFlowLogsConfig` resource

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest

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

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig>)

Required. Only fields specified in update_mask are updated.

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest

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

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest

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

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse

Response for the `QueryVpcFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vpc_flow_logs_configs() >> / C<< $msg->vpc_flow_logs_configs($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig>)

List of VPC Flow Log configurations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token to fetch the next set of configurations.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached (when querying all locations with `-`).

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest

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

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse

Response for the `ShowEffectiveFlowLogsConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->effective_flow_logs_configs() >> / C<< $msg->effective_flow_logs_configs($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig>)

List of Effective Vpc Flow Logs configurations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token to fetch the next set of configurations.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached (when querying all locations with `-`).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
