package Google::Cloud::Numberregistry::V1alpha::Service;

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
    eval { require Google::Cloud::Numberregistry::V1alpha::Core };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvbnVtYmVycmVnaXN0cnkvdjFhbHBoYS9zZXJ2aWNlLnByb3RvEiNn
b29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aLmdvb2dsZS9jbG91ZC9udW1iZXJyZWdpc3RyeS92MWFscGhhL2Nv
cmUucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
1QIKEU9wZXJhdGlvbk1ldGFkYXRhEkAKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEjoKCGVuZF90aW1lGAIgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lEhsKBnRhcmdldBgDIAEo
CUID4EEDUgZ0YXJnZXQSFwoEdmVyYhgEIAEoCUID4EEDUgR2ZXJiEioKDnN0YXR1c19tZXNz
YWdlGAUgASgJQgPgQQNSDXN0YXR1c01lc3NhZ2USOgoWcmVxdWVzdGVkX2NhbmNlbGxhdGlv
bhgGIAEoCEID4EEDUhVyZXF1ZXN0ZWRDYW5jZWxsYXRpb24SJAoLYXBpX3ZlcnNpb24YByAB
KAlCA+BBA1IKYXBpVmVyc2lvbjLjOQoTQ2xvdWROdW1iZXJSZWdpc3RyeRLjAQoTTGlzdElw
YW1BZG1pblNjb3BlcxI/Lmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLkxp
c3RJcGFtQWRtaW5TY29wZXNSZXF1ZXN0GkAuZ29vZ2xlLmNsb3VkLm51bWJlcnJlZ2lzdHJ5
LnYxYWxwaGEuTGlzdElwYW1BZG1pblNjb3Blc1Jlc3BvbnNlIkmC0+STAjoSOC92MWFscGhh
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vaXBhbUFkbWluU2NvcGVz2kEGcGFy
ZW50EtABChFHZXRJcGFtQWRtaW5TY29wZRI9Lmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3Ry
eS52MWFscGhhLkdldElwYW1BZG1pblNjb3BlUmVxdWVzdBozLmdvb2dsZS5jbG91ZC5udW1i
ZXJyZWdpc3RyeS52MWFscGhhLklwYW1BZG1pblNjb3BlIkeC0+STAjoSOC92MWFscGhhL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovaXBhbUFkbWluU2NvcGVzLyp92kEEbmFtZRKj
AgogQ2hlY2tBdmFpbGFiaWxpdHlJcGFtQWRtaW5TY29wZXMSTC5nb29nbGUuY2xvdWQubnVt
YmVycmVnaXN0cnkudjFhbHBoYS5DaGVja0F2YWlsYWJpbGl0eUlwYW1BZG1pblNjb3Blc1Jl
cXVlc3QaTS5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5DaGVja0F2YWls
YWJpbGl0eUlwYW1BZG1pblNjb3Blc1Jlc3BvbnNlImKC0+STAkwSSi92MWFscGhhL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vaXBhbUFkbWluU2NvcGVzOmNoZWNrQXZhaWxh
YmlsaXR52kENcGFyZW50LHNjb3BlcxKgAgoUQ3JlYXRlSXBhbUFkbWluU2NvcGUSQC5nb29n
bGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5DcmVhdGVJcGFtQWRtaW5TY29wZVJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqYBgtPkkwJMIjgvdjFhbHBo
YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2lwYW1BZG1pblNjb3BlczoQaXBh
bV9hZG1pbl9zY29wZdpBK3BhcmVudCxpcGFtX2FkbWluX3Njb3BlLGlwYW1fYWRtaW5fc2Nv
cGVfaWTKQSMKDklwYW1BZG1pblNjb3BlEhFPcGVyYXRpb25NZXRhZGF0YRKiAgoUVXBkYXRl
SXBhbUFkbWluU2NvcGUSQC5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5V
cGRhdGVJcGFtQWRtaW5TY29wZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uIqgBgtPkkwJdMkkvdjFhbHBoYS97aXBhbV9hZG1pbl9zY29wZS5uYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovaXBhbUFkbWluU2NvcGVzLyp9OhBpcGFtX2FkbWluX3Njb3Bl2kEc
aXBhbV9hZG1pbl9zY29wZSx1cGRhdGVfbWFza8pBIwoOSXBhbUFkbWluU2NvcGUSEU9wZXJh
dGlvbk1ldGFkYXRhEu0BChREZWxldGVJcGFtQWRtaW5TY29wZRJALmdvb2dsZS5jbG91ZC5u
dW1iZXJyZWdpc3RyeS52MWFscGhhLkRlbGV0ZUlwYW1BZG1pblNjb3BlUmVxdWVzdBodLmdv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24idILT5JMCOio4L3YxYWxwaGEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9pcGFtQWRtaW5TY29wZXMvKn3aQQRuYW1lykEqChVnb29n
bGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEvMBChVEaXNhYmxlSXBhbUFk
bWluU2NvcGUSQS5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5EaXNhYmxl
SXBhbUFkbWluU2NvcGVSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ4
gtPkkwJFIkAvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2lwYW1BZG1p
blNjb3Blcy8qfTpkaXNhYmxlOgEq2kEEbmFtZcpBIwoOSXBhbUFkbWluU2NvcGUSEU9wZXJh
dGlvbk1ldGFkYXRhEvMBChVDbGVhbnVwSXBhbUFkbWluU2NvcGUSQS5nb29nbGUuY2xvdWQu
bnVtYmVycmVnaXN0cnkudjFhbHBoYS5DbGVhbnVwSXBhbUFkbWluU2NvcGVSZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ4gtPkkwJFIkAvdjFhbHBoYS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2lwYW1BZG1pblNjb3Blcy8qfTpjbGVhbnVwOgEq2kEE
bmFtZcpBIwoOSXBhbUFkbWluU2NvcGUSEU9wZXJhdGlvbk1ldGFkYXRhEtsBChFMaXN0UmVn
aXN0cnlCb29rcxI9Lmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLkxpc3RS
ZWdpc3RyeUJvb2tzUmVxdWVzdBo+Lmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFs
cGhhLkxpc3RSZWdpc3RyeUJvb2tzUmVzcG9uc2UiR4LT5JMCOBI2L3YxYWxwaGEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9yZWdpc3RyeUJvb2tz2kEGcGFyZW50EsgBCg9H
ZXRSZWdpc3RyeUJvb2sSOy5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5H
ZXRSZWdpc3RyeUJvb2tSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLm51bWJlcnJlZ2lzdHJ5LnYx
YWxwaGEuUmVnaXN0cnlCb29rIkWC0+STAjgSNi92MWFscGhhL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovcmVnaXN0cnlCb29rcy8qfdpBBG5hbWUS7gEKEVNlYXJjaElwUmVzb3Vy
Y2VzEj0uZ29vZ2xlLmNsb3VkLm51bWJlcnJlZ2lzdHJ5LnYxYWxwaGEuU2VhcmNoSXBSZXNv
dXJjZXNSZXF1ZXN0Gj4uZ29vZ2xlLmNsb3VkLm51bWJlcnJlZ2lzdHJ5LnYxYWxwaGEuU2Vh
cmNoSXBSZXNvdXJjZXNSZXNwb25zZSJagtPkkwJNIkgvdjFhbHBoYS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL3JlZ2lzdHJ5Qm9va3MvKn06c2VhcmNoSXBSZXNvdXJjZXM6ASra
QQRuYW1lEo8CChJDcmVhdGVSZWdpc3RyeUJvb2sSPi5nb29nbGUuY2xvdWQubnVtYmVycmVn
aXN0cnkudjFhbHBoYS5DcmVhdGVSZWdpc3RyeUJvb2tSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbiKZAYLT5JMCRyI2L3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qfS9yZWdpc3RyeUJvb2tzOg1yZWdpc3RyeV9ib29r2kElcGFyZW50LHJl
Z2lzdHJ5X2Jvb2sscmVnaXN0cnlfYm9va19pZMpBIQoMUmVnaXN0cnlCb29rEhFPcGVyYXRp
b25NZXRhZGF0YRKRAgoSVXBkYXRlUmVnaXN0cnlCb29rEj4uZ29vZ2xlLmNsb3VkLm51bWJl
cnJlZ2lzdHJ5LnYxYWxwaGEuVXBkYXRlUmVnaXN0cnlCb29rUmVxdWVzdBodLmdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb24imwGC0+STAlUyRC92MWFscGhhL3tyZWdpc3RyeV9ib29r
Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZWdpc3RyeUJvb2tzLyp9Og1yZWdpc3Ry
eV9ib29r2kEZcmVnaXN0cnlfYm9vayx1cGRhdGVfbWFza8pBIQoMUmVnaXN0cnlCb29rEhFP
cGVyYXRpb25NZXRhZGF0YRLnAQoSRGVsZXRlUmVnaXN0cnlCb29rEj4uZ29vZ2xlLmNsb3Vk
Lm51bWJlcnJlZ2lzdHJ5LnYxYWxwaGEuRGVsZXRlUmVnaXN0cnlCb29rUmVxdWVzdBodLmdv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24icoLT5JMCOCo2L3YxYWxwaGEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9yZWdpc3RyeUJvb2tzLyp92kEEbmFtZcpBKgoVZ29vZ2xl
LnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRK/AQoKTGlzdFJlYWxtcxI2Lmdv
b2dsZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLkxpc3RSZWFsbXNSZXF1ZXN0Gjcu
Z29vZ2xlLmNsb3VkLm51bWJlcnJlZ2lzdHJ5LnYxYWxwaGEuTGlzdFJlYWxtc1Jlc3BvbnNl
IkCC0+STAjESLy92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vcmVh
bG1z2kEGcGFyZW50EqwBCghHZXRSZWFsbRI0Lmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3Ry
eS52MWFscGhhLkdldFJlYWxtUmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3Ry
eS52MWFscGhhLlJlYWxtIj6C0+STAjESLy92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovcmVhbG1zLyp92kEEbmFtZRLaAQoLQ3JlYXRlUmVhbG0SNy5nb29nbGUuY2xv
dWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5DcmVhdGVSZWFsbVJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uInOC0+STAjgiLy92MWFscGhhL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKn0vcmVhbG1zOgVyZWFsbdpBFXBhcmVudCxyZWFsbSxyZWFsbV9p
ZMpBGgoFUmVhbG0SEU9wZXJhdGlvbk1ldGFkYXRhEtwBCgtVcGRhdGVSZWFsbRI3Lmdvb2ds
ZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLlVwZGF0ZVJlYWxtUmVxdWVzdBodLmdv
b2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24idYLT5JMCPjI1L3YxYWxwaGEve3JlYWxtLm5h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZWFsbXMvKn06BXJlYWxt2kERcmVhbG0sdXBk
YXRlX21hc2vKQRoKBVJlYWxtEhFPcGVyYXRpb25NZXRhZGF0YRLSAQoLRGVsZXRlUmVhbG0S
Ny5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5EZWxldGVSZWFsbVJlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uImuC0+STAjEqLy92MWFscGhhL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcmVhbG1zLyp92kEEbmFtZcpBKgoVZ29vZ2xl
LnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRLnAQoUTGlzdERpc2NvdmVyZWRS
YW5nZXMSQC5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5MaXN0RGlzY292
ZXJlZFJhbmdlc1JlcXVlc3QaQS5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBo
YS5MaXN0RGlzY292ZXJlZFJhbmdlc1Jlc3BvbnNlIkqC0+STAjsSOS92MWFscGhhL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZGlzY292ZXJlZFJhbmdlc9pBBnBhcmVudBLU
AQoSR2V0RGlzY292ZXJlZFJhbmdlEj4uZ29vZ2xlLmNsb3VkLm51bWJlcnJlZ2lzdHJ5LnYx
YWxwaGEuR2V0RGlzY292ZXJlZFJhbmdlUmVxdWVzdBo0Lmdvb2dsZS5jbG91ZC5udW1iZXJy
ZWdpc3RyeS52MWFscGhhLkRpc2NvdmVyZWRSYW5nZSJIgtPkkwI7EjkvdjFhbHBoYS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Rpc2NvdmVyZWRSYW5nZXMvKn3aQQRuYW1lEqoC
Ch9GaW5kRGlzY292ZXJlZFJhbmdlRnJlZUlwUmFuZ2VzEksuZ29vZ2xlLmNsb3VkLm51bWJl
cnJlZ2lzdHJ5LnYxYWxwaGEuRmluZERpc2NvdmVyZWRSYW5nZUZyZWVJcFJhbmdlc1JlcXVl
c3QaTC5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5GaW5kRGlzY292ZXJl
ZFJhbmdlRnJlZUlwUmFuZ2VzUmVzcG9uc2UibILT5JMCTBJKL3YxYWxwaGEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9kaXNjb3ZlcmVkUmFuZ2VzLyp9OmZpbmRGcmVlSXBSYW5n
ZXPaQRduYW1lLGNpZHJfcHJlZml4X2xlbmd0aBLXAQoQTGlzdEN1c3RvbVJhbmdlcxI8Lmdv
b2dsZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLkxpc3RDdXN0b21SYW5nZXNSZXF1
ZXN0Gj0uZ29vZ2xlLmNsb3VkLm51bWJlcnJlZ2lzdHJ5LnYxYWxwaGEuTGlzdEN1c3RvbVJh
bmdlc1Jlc3BvbnNlIkaC0+STAjcSNS92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKn0vY3VzdG9tUmFuZ2Vz2kEGcGFyZW50EsQBCg5HZXRDdXN0b21SYW5nZRI6Lmdv
b2dsZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLkdldEN1c3RvbVJhbmdlUmVxdWVz
dBowLmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLkN1c3RvbVJhbmdlIkSC
0+STAjcSNS92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY3VzdG9tUmFu
Z2VzLyp92kEEbmFtZRKDAgoaU2hvd0N1c3RvbVJhbmdlVXRpbGl6YXRpb24SRi5nb29nbGUu
Y2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5TaG93Q3VzdG9tUmFuZ2VVdGlsaXphdGlv
blJlcXVlc3QaRy5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5TaG93Q3Vz
dG9tUmFuZ2VVdGlsaXphdGlvblJlc3BvbnNlIlSC0+STAkcSRS92MWFscGhhL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY3VzdG9tUmFuZ2VzLyp9OnNob3dVdGlsaXphdGlvbtpB
BG5hbWUSkwIKHlNob3dEaXNjb3ZlcmVkUmFuZ2VVdGlsaXphdGlvbhJKLmdvb2dsZS5jbG91
ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLlNob3dEaXNjb3ZlcmVkUmFuZ2VVdGlsaXphdGlv
blJlcXVlc3QaSy5nb29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5TaG93RGlz
Y292ZXJlZFJhbmdlVXRpbGl6YXRpb25SZXNwb25zZSJYgtPkkwJLEkkvdjFhbHBoYS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Rpc2NvdmVyZWRSYW5nZXMvKn06c2hvd1V0aWxp
emF0aW9u2kEEbmFtZRKaAgobRmluZEN1c3RvbVJhbmdlRnJlZUlwUmFuZ2VzEkcuZ29vZ2xl
LmNsb3VkLm51bWJlcnJlZ2lzdHJ5LnYxYWxwaGEuRmluZEN1c3RvbVJhbmdlRnJlZUlwUmFu
Z2VzUmVxdWVzdBpILmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLkZpbmRD
dXN0b21SYW5nZUZyZWVJcFJhbmdlc1Jlc3BvbnNlImiC0+STAkgSRi92MWFscGhhL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovY3VzdG9tUmFuZ2VzLyp9OmZpbmRGcmVlSXBSYW5n
ZXPaQRduYW1lLGNpZHJfcHJlZml4X2xlbmd0aBKIAgoRQ3JlYXRlQ3VzdG9tUmFuZ2USPS5n
b29nbGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5DcmVhdGVDdXN0b21SYW5nZVJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIpQBgtPkkwJFIjUvdjFhbHBo
YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2N1c3RvbVJhbmdlczoMY3VzdG9t
X3Jhbmdl2kEjcGFyZW50LGN1c3RvbV9yYW5nZSxjdXN0b21fcmFuZ2VfaWTKQSAKC0N1c3Rv
bVJhbmdlEhFPcGVyYXRpb25NZXRhZGF0YRKKAgoRVXBkYXRlQ3VzdG9tUmFuZ2USPS5nb29n
bGUuY2xvdWQubnVtYmVycmVnaXN0cnkudjFhbHBoYS5VcGRhdGVDdXN0b21SYW5nZVJlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIpYBgtPkkwJSMkIvdjFhbHBoYS97
Y3VzdG9tX3JhbmdlLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jdXN0b21SYW5nZXMv
Kn06DGN1c3RvbV9yYW5nZdpBGGN1c3RvbV9yYW5nZSx1cGRhdGVfbWFza8pBIAoLQ3VzdG9t
UmFuZ2USEU9wZXJhdGlvbk1ldGFkYXRhEuQBChFEZWxldGVDdXN0b21SYW5nZRI9Lmdvb2ds
ZS5jbG91ZC5udW1iZXJyZWdpc3RyeS52MWFscGhhLkRlbGV0ZUN1c3RvbVJhbmdlUmVxdWVz
dBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24icYLT5JMCNyo1L3YxYWxwaGEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jdXN0b21SYW5nZXMvKn3aQQRuYW1lykEqChVn
b29nbGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhGlbKQSJjbG91ZG51bWJl
cnJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybUL/AQonY29tLmdvb2dsZS5jbG91ZC5udW1iZXJyZWdpc3Ry
eS52MWFscGhhQgxTZXJ2aWNlUHJvdG9QAVpPY2xvdWQuZ29vZ2xlLmNvbS9nby9udW1iZXJy
ZWdpc3RyeS9hcGl2MWFscGhhL251bWJlcnJlZ2lzdHJ5cGI7bnVtYmVycmVnaXN0cnlwYqoC
I0dvb2dsZS5DbG91ZC5OdW1iZXJSZWdpc3RyeS5WMUFscGhhygIjR29vZ2xlXENsb3VkXE51
bWJlclJlZ2lzdHJ5XFYxYWxwaGHqAiZHb29nbGU6OkNsb3VkOjpOdW1iZXJSZWdpc3RyeTo6
VjFhbHBoYUquQQoHEgUOAJMDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAALAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQA4
CgkKAgMEEgMWAC0KCQoCAwUSAxcAJQoJCgIDBhIDGAApCggKAQgSAxoAQAoJCgIIJRIDGgBA
CggKAQgSAxsAZgoJCgIICxIDGwBmCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ALQoJ
CgIICBIDHQAtCggKAQgSAx4AQAoJCgIIARIDHgBACggKAQgSAx8AQAoJCgIIKRIDHwBACggK
AQgSAyAAPwoJCgIILRIDIAA/CuIBCgIGABIFJQD1AgEa1AEgVGhlIENsb3VkIE51bWJlciBS
ZWdpc3RyeSBzZXJ2aWNlIG1hbmFnZXMgSVAgYWRkcmVzcyBzcGFjZSB2aXNpYmlsaXR5IGFu
ZAogdHJhY2tpbmcuIEl0IGVuYWJsZXMgdGhlIGRpc2NvdmVyeSwgb3JnYW5pemF0aW9uLCBh
bmQgbW9uaXRvcmluZyBvZiBJUAogYWRkcmVzcyByYW5nZXMgYWNyb3NzIGRpZmZlcmVudCBj
bG91ZCBpbmZyYXN0cnVjdHVyZSBwbGF0Zm9ybXMuCgoKCgMGAAESAyUIGwoKCgMGAAMSAyYC
SgoMCgUGAAOZCBIDJgJKCgsKAwYAAxIEJwIoNwoNCgUGAAOaCBIEJwIoNwpGCgQGAAIAEgQr
AjEDGjggTGlzdHMgSXBhbUFkbWluU2NvcGVzIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9j
YXRpb24uCgoMCgUGAAIAARIDKwYZCgwKBQYAAgACEgMrGjQKDAoFBgACAAMSAywPKgoNCgUG
AAIABBIELQQvBgoRCgkGAAIABLDKvCISBC0ELwYKDAoFBgACAAQSAzAENAoPCggGAAIABJsI
ABIDMAQ0CjgKBAYAAgESBDQCOQMaKiBHZXRzIGRldGFpbHMgb2YgYSBzaW5nbGUgSXBhbUFk
bWluU2NvcGUuCgoMCgUGAAIBARIDNAYXCgwKBQYAAgECEgM0GDAKDAoFBgACAQMSAzQ7SQoN
CgUGAAIBBBIENQQ3BgoRCgkGAAIBBLDKvCISBDUENwYKDAoFBgACAQQSAzgEMgoPCggGAAIB
BJsIABIDOAQyClwKBAYAAgISBD0CQwMaTiBDaGVja3MgdGhlIGF2YWlsYWJpbGl0eSBvZiBJ
cGFtQWRtaW5TY29wZXMgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZAogbG9jYXRpb24uCgoMCgUG
AAICARIDPQYmCgwKBQYAAgICEgM9J04KDAoFBgACAgMSAz4PNwoNCgUGAAICBBIEPwRBBgoR
CgkGAAICBLDKvCISBD8EQQYKDAoFBgACAgQSA0IEOwoPCggGAAICBJsIABIDQgQ7Ck0KBAYA
AgMSBEYCUgMaPyBDcmVhdGVzIGEgbmV3IElwYW1BZG1pblNjb3BlIGluIGEgZ2l2ZW4gcHJv
amVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAIDARIDRgYaCgwKBQYAAgMCEgNGGzYKDAoFBgAC
AwMSA0cPKwoNCgUGAAIDBBIESARLBgoRCgkGAAIDBLDKvCISBEgESwYKDQoFBgACAwQSBEwE
TTYKEAoIBgACAwSbCAASBEwETTYKDQoFBgACAwQSBE4EUQYKDwoHBgACAwSZCBIETgRRBgpC
CgQGAAIEEgRVAmADGjQgVXBkYXRlcyB0aGUgcGFyYW1ldGVycyBvZiBhIHNpbmdsZSBJcGFt
QWRtaW5TY29wZS4KCgwKBQYAAgQBEgNVBhoKDAoFBgACBAISA1UbNgoMCgUGAAIEAxIDVg8r
Cg0KBQYAAgQEEgRXBFoGChEKCQYAAgQEsMq8IhIEVwRaBgoMCgUGAAIEBBIDWwRKCg8KCAYA
AgQEmwgAEgNbBEoKDQoFBgACBAQSBFwEXwYKDwoHBgACBASZCBIEXARfBgowCgQGAAIFEgRj
Am0DGiIgRGVsZXRlcyBhIHNpbmdsZSBJcGFtQWRtaW5TY29wZS4KCgwKBQYAAgUBEgNjBhoK
DAoFBgACBQISA2MbNgoMCgUGAAIFAxIDZA8rCg0KBQYAAgUEEgRlBGcGChEKCQYAAgUEsMq8
IhIEZQRnBgoMCgUGAAIFBBIDaAQyCg8KCAYAAgUEmwgAEgNoBDIKDQoFBgACBQQSBGkEbAYK
DwoHBgACBQSZCBIEaQRsBgoxCgQGAAIGEgRwAnsDGiMgRGlzYWJsZXMgYSBzaW5nbGUgSXBh
bUFkbWluU2NvcGUuCgoMCgUGAAIGARIDcAYbCgwKBQYAAgYCEgNwHDgKDAoFBgACBgMSA3EP
KwoNCgUGAAIGBBIEcgR1BgoRCgkGAAIGBLDKvCISBHIEdQYKDAoFBgACBgQSA3YEMgoPCggG
AAIGBJsIABIDdgQyCg0KBQYAAgYEEgR3BHoGCg8KBwYAAgYEmQgSBHcEegYKMwoEBgACBxIF
fgKJAQMaJCBDbGVhbnMgdXAgYSBzaW5nbGUgSXBhbUFkbWluU2NvcGUuCgoMCgUGAAIHARID
fgYbCgwKBQYAAgcCEgN+HDgKDAoFBgACBwMSA38PKwoPCgUGAAIHBBIGgAEEgwEGChMKCQYA
AgcEsMq8IhIGgAEEgwEGCg0KBQYAAgcEEgSEAQQyChAKCAYAAgcEmwgAEgSEAQQyCg8KBQYA
AgcEEgaFAQSIAQYKEQoHBgACBwSZCBIGhQEEiAEGCkYKBAYAAggSBowBApIBAxo2IExpc3Rz
IFJlZ2lzdHJ5Qm9va3MgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCg0KBQYA
AggBEgSMAQYXCg0KBQYAAggCEgSMARgwCg0KBQYAAggDEgSNAQ8oCg8KBQYAAggEEgaOAQSQ
AQYKEwoJBgACCASwyrwiEgaOAQSQAQYKDQoFBgACCAQSBJEBBDQKEAoIBgACCASbCAASBJEB
BDQKOAoEBgACCRIGlQECmgEDGiggR2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIFJlZ2lzdHJ5
Qm9vay4KCg0KBQYAAgkBEgSVAQYVCg0KBQYAAgkCEgSVARYsCg0KBQYAAgkDEgSVATdDCg8K
BQYAAgkEEgaWAQSYAQYKEwoJBgACCQSwyrwiEgaWAQSYAQYKDQoFBgACCQQSBJkBBDIKEAoI
BgACCQSbCAASBJkBBDIKQAoEBgACChIGnQECpAEDGjAgU2VhcmNoZXMgSVAgcmVzb3VyY2Vz
IGluIGEgZ2l2ZW4gUmVnaXN0cnlCb29rLgoKDQoFBgACCgESBJ0BBhcKDQoFBgACCgISBJ0B
GDAKDQoFBgACCgMSBJ4BDygKDwoFBgACCgQSBp8BBKIBBgoTCgkGAAIKBLDKvCISBp8BBKIB
BgoNCgUGAAIKBBIEowEEMgoQCggGAAIKBJsIABIEowEEMgpNCgQGAAILEganAQKzAQMaPSBD
cmVhdGVzIGEgbmV3IFJlZ2lzdHJ5Qm9vayBpbiBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0
aW9uLgoKDQoFBgACCwESBKcBBhgKDQoFBgACCwISBKcBGTIKDQoFBgACCwMSBKgBDysKDwoF
BgACCwQSBqkBBKwBBgoTCgkGAAILBLDKvCISBqkBBKwBBgoPCgUGAAILBBIGrQEErgEwChIK
CAYAAgsEmwgAEgatAQSuATAKDwoFBgACCwQSBq8BBLIBBgoRCgcGAAILBJkIEgavAQSyAQYK
QgoEBgACDBIGtgECwQEDGjIgVXBkYXRlcyB0aGUgcGFyYW1ldGVycyBvZiBhIHNpbmdsZSBS
ZWdpc3RyeUJvb2suCgoNCgUGAAIMARIEtgEGGAoNCgUGAAIMAhIEtgEZMgoNCgUGAAIMAxIE
twEPKwoPCgUGAAIMBBIGuAEEuwEGChMKCQYAAgwEsMq8IhIGuAEEuwEGCg0KBQYAAgwEEgS8
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
aXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCg0KBQYAAhYBEgShAgYWCg0KBQYAAhYCEgSh
AhcuCg0KBQYAAhYDEgSiAg8nCg8KBQYAAhYEEgajAgSlAgYKEwoJBgACFgSwyrwiEgajAgSl
AgYKDQoFBgACFgQSBKYCBDQKEAoIBgACFgSbCAASBKYCBDQKNwoEBgACFxIGqgICrwIDGicg
R2V0cyBkZXRhaWxzIG9mIGEgc2luZ2xlIEN1c3RvbVJhbmdlLgoKDQoFBgACFwESBKoCBhQK
DQoFBgACFwISBKoCFSoKDQoFBgACFwMSBKoCNUAKDwoFBgACFwQSBqsCBK0CBgoTCgkGAAIX
BLDKvCISBqsCBK0CBgoNCgUGAAIXBBIErgIEMgoQCggGAAIXBJsIABIErgIEMgpPCgQGAAIY
EgayAgK4AgMaPyBHZXRzIHRoZSBkZXRhaWxzIG9mIGEgc2luZ2xlIEN1c3RvbVJhbmdlIGFu
ZCBpdHMgdXRpbGl6YXRpb24uCgoNCgUGAAIYARIEsgIGIAoNCgUGAAIYAhIEsgIhQgoNCgUG
AAIYAxIEswIPMQoPCgUGAAIYBBIGtAIEtgIGChMKCQYAAhgEsMq8IhIGtAIEtgIGCg0KBQYA
AhgEEgS3AgQyChAKCAYAAhgEmwgAEgS3AgQyClMKBAYAAhkSBrsCAsECAxpDIEdldHMgdGhl
IGRldGFpbHMgb2YgYSBzaW5nbGUgRGlzY292ZXJlZFJhbmdlIGFuZCBpdHMgdXRpbGl6YXRp
b24uCgoNCgUGAAIZARIEuwIGJAoNCgUGAAIZAhIEuwIlSgoNCgUGAAIZAxIEvAIPNQoPCgUG
AAIZBBIGvQIEvwIGChMKCQYAAhkEsMq8IhIGvQIEvwIGCg0KBQYAAhkEEgTAAgQyChAKCAYA
AhkEmwgAEgTAAgQyCj8KBAYAAhoSBsQCAsoCAxovIEZpbmRzIGZyZWUgSVAgcmFuZ2VzIGlu
IGEgc2luZ2xlIEN1c3RvbVJhbmdlLgoKDQoFBgACGgESBMQCBiEKDQoFBgACGgISBMQCIkQK
DQoFBgACGgMSBMUCDzIKDwoFBgACGgQSBsYCBMgCBgoTCgkGAAIaBLDKvCISBsYCBMgCBgoN
CgUGAAIaBBIEyQIERQoQCggGAAIaBJsIABIEyQIERQpMCgQGAAIbEgbNAgLZAgMaPCBDcmVh
dGVzIGEgbmV3IEN1c3RvbVJhbmdlIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24u
CgoNCgUGAAIbARIEzQIGFwoNCgUGAAIbAhIEzQIYMAoNCgUGAAIbAxIEzgIPKwoPCgUGAAIb
BBIGzwIE0gIGChMKCQYAAhsEsMq8IhIGzwIE0gIGCg8KBQYAAhsEEgbTAgTUAi4KEgoIBgAC
GwSbCAASBtMCBNQCLgoPCgUGAAIbBBIG1QIE2AIGChEKBwYAAhsEmQgSBtUCBNgCBgpBCgQG
AAIcEgbcAgLnAgMaMSBVcGRhdGVzIHRoZSBwYXJhbWV0ZXJzIG9mIGEgc2luZ2xlIEN1c3Rv
bVJhbmdlLgoKDQoFBgACHAESBNwCBhcKDQoFBgACHAISBNwCGDAKDQoFBgACHAMSBN0CDysK
DwoFBgACHAQSBt4CBOECBgoTCgkGAAIcBLDKvCISBt4CBOECBgoNCgUGAAIcBBIE4gIERgoQ
CggGAAIcBJsIABIE4gIERgoPCgUGAAIcBBIG4wIE5gIGChEKBwYAAhwEmQgSBuMCBOYCBgov
CgQGAAIdEgbqAgL0AgMaHyBEZWxldGVzIGEgc2luZ2xlIEN1c3RvbVJhbmdlLgoKDQoFBgAC
HQESBOoCBhcKDQoFBgACHQISBOoCGDAKDQoFBgACHQMSBOsCDysKDwoFBgACHQQSBuwCBO4C
BgoTCgkGAAIdBLDKvCISBuwCBO4CBgoNCgUGAAIdBBIE7wIEMgoQCggGAAIdBJsIABIE7wIE
MgoPCgUGAAIdBBIG8AIE8wIGChEKBwYAAh0EmQgSBvACBPMCBgpGCgIEABIG+AIAkwMBGjgg
UmVwcmVzZW50cyB0aGUgbWV0YWRhdGEgb2YgdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24u
CgoLCgMEAAESBPgCCBkKQgoEBAACABIG+gIC+wIyGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1l
IHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoNCgUEAAIABhIE+gICGwoNCgUEAAIAARIE
+gIcJwoNCgUEAAIAAxIE+gIqKwoNCgUEAAIACBIE+wIGMQoQCggEAAIACJwIABIE+wIHMApH
CgQEAAIBEgb+AgL/AjIaNyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBm
aW5pc2hlZCBydW5uaW5nLgoKDQoFBAACAQYSBP4CAhsKDQoFBAACAQESBP4CHCQKDQoFBAAC
AQMSBP4CJygKDQoFBAACAQgSBP8CBjEKEAoIBAACAQicCAASBP8CBzAKWgoEBAACAhIEggMC
QBpMIE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRoIGZvciB0aGUg
dGFyZ2V0IG9mIHRoZSBvcGVyYXRpb24uCgoNCgUEAAICBRIEggMCCAoNCgUEAAICARIEggMJ
DwoNCgUEAAICAxIEggMSEwoNCgUEAAICCBIEggMUPwoQCggEAAICCJwIABIEggMVPgpICgQE
AAIDEgSFAwI+GjogT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkg
dGhlIG9wZXJhdGlvbi4KCg0KBQQAAgMFEgSFAwIICg0KBQQAAgMBEgSFAwkNCg0KBQQAAgMD
EgSFAxARCg0KBQQAAgMIEgSFAxI9ChAKCAQAAgMInAgAEgSFAxM8CkwKBAQAAgQSBIgDAkga
PiBPdXRwdXQgb25seS4gSHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRpb24s
IGlmIGFueS4KCg0KBQQAAgQFEgSIAwIICg0KBQQAAgQBEgSIAwkXCg0KBQQAAgQDEgSIAxob
Cg0KBQQAAgQIEgSIAxxHChAKCAQAAgQInAgAEgSIAx1GCpsCCgQEAAIFEgSPAwJOGowCIE91
dHB1dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBj
YW5jZWxsYXRpb24KIG9mIHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIGJl
ZW4gY2FuY2VsbGVkIHN1Y2Nlc3NmdWxseQogaGF2ZSBbT3BlcmF0aW9uLmVycm9yXVtdIHZh
bHVlIHdpdGggYQogW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVz
LmNvZGVdIG9mIDEsIGNvcnJlc3BvbmRpbmcgdG8KIGBDb2RlLkNBTkNFTExFRGAuCgoNCgUE
AAIFBRIEjwMCBgoNCgUEAAIFARIEjwMHHQoNCgUEAAIFAxIEjwMgIQoNCgUEAAIFCBIEjwMi
TQoQCggEAAIFCJwIABIEjwMjTApFCgQEAAIGEgSSAwJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2
ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCg0KBQQAAgYFEgSSAwIICg0K
BQQAAgYBEgSSAwkUCg0KBQQAAgYDEgSSAxcYCg0KBQQAAgYIEgSSAxlEChAKCAQAAgYInAgA
EgSSAxpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Numberregistry::V1alpha::Service::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Numberregistry::V1alpha::Service::CloudNumberRegistryClient ===
package Google::Cloud::Numberregistry::V1alpha::Service::CloudNumberRegistryClient;

=pod

=head2 Service Client: Google::Cloud::Numberregistry::V1alpha::Service::CloudNumberRegistryClient

Client stub representing the remote C<CloudNumberRegistry> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<numberregistry.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'numberregistry.googleapis.com:443' );

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

sub list_ipam_admin_scopes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::ListIpamAdminScopesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'ListIpamAdminScopes',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::ListIpamAdminScopesResponse',
    });
}

sub get_ipam_admin_scope {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::GetIpamAdminScopeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'GetIpamAdminScope',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScope',
    });
}

sub check_availability_ipam_admin_scopes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::CheckAvailabilityIpamAdminScopesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'CheckAvailabilityIpamAdminScopes',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::CheckAvailabilityIpamAdminScopesResponse',
    });
}

sub create_ipam_admin_scope {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::CreateIpamAdminScopeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'CreateIpamAdminScope',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_ipam_admin_scope {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::UpdateIpamAdminScopeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'UpdateIpamAdminScope',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_ipam_admin_scope {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::DeleteIpamAdminScopeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'DeleteIpamAdminScope',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub disable_ipam_admin_scope {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::DisableIpamAdminScopeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'DisableIpamAdminScope',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub cleanup_ipam_admin_scope {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::CleanupIpamAdminScopeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'CleanupIpamAdminScope',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_registry_books {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::ListRegistryBooksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'ListRegistryBooks',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::ListRegistryBooksResponse',
    });
}

sub get_registry_book {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::GetRegistryBookRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'GetRegistryBook',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook',
    });
}

sub search_ip_resources {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'SearchIpResources',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesResponse',
    });
}

sub create_registry_book {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::CreateRegistryBookRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'CreateRegistryBook',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_registry_book {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::UpdateRegistryBookRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'UpdateRegistryBook',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_registry_book {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::DeleteRegistryBookRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'DeleteRegistryBook',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_realms {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::ListRealmsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'ListRealms',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::ListRealmsResponse',
    });
}

sub get_realm {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::GetRealmRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'GetRealm',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::Realm',
    });
}

sub create_realm {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::CreateRealmRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'CreateRealm',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_realm {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::UpdateRealmRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'UpdateRealm',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_realm {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::DeleteRealmRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'DeleteRealm',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_discovered_ranges {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::ListDiscoveredRangesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'ListDiscoveredRanges',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::ListDiscoveredRangesResponse',
    });
}

sub get_discovered_range {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::GetDiscoveredRangeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'GetDiscoveredRange',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::DiscoveredRange',
    });
}

sub find_discovered_range_free_ip_ranges {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::FindDiscoveredRangeFreeIpRangesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'FindDiscoveredRangeFreeIpRanges',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::FindDiscoveredRangeFreeIpRangesResponse',
    });
}

sub list_custom_ranges {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::ListCustomRangesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'ListCustomRanges',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::ListCustomRangesResponse',
    });
}

sub get_custom_range {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::GetCustomRangeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'GetCustomRange',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::CustomRange',
    });
}

sub show_custom_range_utilization {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::ShowCustomRangeUtilizationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'ShowCustomRangeUtilization',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::ShowCustomRangeUtilizationResponse',
    });
}

sub show_discovered_range_utilization {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::ShowDiscoveredRangeUtilizationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'ShowDiscoveredRangeUtilization',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::ShowDiscoveredRangeUtilizationResponse',
    });
}

sub find_custom_range_free_ip_ranges {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::FindCustomRangeFreeIpRangesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'FindCustomRangeFreeIpRanges',
        request        => $req,
        response_class => 'Google::Cloud::Numberregistry::V1alpha::Core::FindCustomRangeFreeIpRangesResponse',
    });
}

sub create_custom_range {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::CreateCustomRangeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'CreateCustomRange',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_custom_range {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::UpdateCustomRangeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'UpdateCustomRange',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_custom_range {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Numberregistry::V1alpha::Core::DeleteCustomRangeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.numberregistry.v1alpha.CloudNumberRegistry',
        method         => 'DeleteCustomRange',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Numberregistry::V1alpha::Service - Compiled Protocol Buffers messages for google/cloud/numberregistry/v1alpha/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Numberregistry::V1alpha::Service;

    my $msg = Google::Cloud::Numberregistry::V1alpha::Service::OperationMetadata->new({
        create_time => $create_time,
        end_time => $end_time,
        target => $target,
        verb => $verb,
    });

    # Read or update a field
    my $val = $msg->create_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Numberregistry::V1alpha::Service::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/numberregistry/v1alpha/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Numberregistry::V1alpha::Service::OperationMetadata

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

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have been cancelled successfully
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Numberregistry::V1alpha::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
