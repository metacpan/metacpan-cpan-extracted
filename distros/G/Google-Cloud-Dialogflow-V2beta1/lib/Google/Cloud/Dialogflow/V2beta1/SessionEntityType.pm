package Google::Cloud::Dialogflow::V2beta1::SessionEntityType;

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
    eval { require Google::Cloud::Dialogflow::V2beta1::EntityType };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL3Nlc3Npb25fZW50aXR5X3R5cGUu
cHJvdG8SH2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEaHGdvb2dsZS9hcGkvYW5u
b3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjFnb29nbGUv
Y2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2VudGl0eV90eXBlLnByb3RvGhtnb29nbGUvcHJv
dG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIsAG
ChFTZXNzaW9uRW50aXR5VHlwZRISCgRuYW1lGAEgASgJUgRuYW1lEncKFGVudGl0eV9vdmVy
cmlkZV9tb2RlGAIgASgOMkUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TZXNz
aW9uRW50aXR5VHlwZS5FbnRpdHlPdmVycmlkZU1vZGVSEmVudGl0eU92ZXJyaWRlTW9kZRJO
CghlbnRpdGllcxgDIAMoCzIyLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuRW50
aXR5VHlwZS5FbnRpdHlSCGVudGl0aWVzIoIBChJFbnRpdHlPdmVycmlkZU1vZGUSJAogRU5U
SVRZX09WRVJSSURFX01PREVfVU5TUEVDSUZJRUQQABIhCh1FTlRJVFlfT1ZFUlJJREVfTU9E
RV9PVkVSUklERRABEiMKH0VOVElUWV9PVkVSUklERV9NT0RFX1NVUFBMRU1FTlQQAjrIA+pB
xAMKK2RpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vU2Vzc2lvbkVudGl0eVR5cGUSRXByb2pl
Y3RzL3twcm9qZWN0fS9hZ2VudC9zZXNzaW9ucy97c2Vzc2lvbn0vZW50aXR5VHlwZXMve2Vu
dGl0eV90eXBlfRJacHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fn
ZW50L3Nlc3Npb25zL3tzZXNzaW9ufS9lbnRpdHlUeXBlcy97ZW50aXR5X3R5cGV9Em1wcm9q
ZWN0cy97cHJvamVjdH0vYWdlbnQvZW52aXJvbm1lbnRzL3tlbnZpcm9ubWVudH0vdXNlcnMv
e3VzZXJ9L3Nlc3Npb25zL3tzZXNzaW9ufS9lbnRpdHlUeXBlcy97ZW50aXR5X3R5cGV9EoIB
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50L2Vudmlyb25t
ZW50cy97ZW52aXJvbm1lbnR9L3VzZXJzL3t1c2VyfS9zZXNzaW9ucy97c2Vzc2lvbn0vZW50
aXR5VHlwZXMve2VudGl0eV90eXBlfSKoAQodTGlzdFNlc3Npb25FbnRpdHlUeXBlc1JlcXVl
c3QSSwoGcGFyZW50GAEgASgJQjPgQQL6QS0SK2RpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20v
U2Vzc2lvbkVudGl0eVR5cGVSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXpl
Eh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKuAQoeTGlzdFNlc3Npb25FbnRpdHlU
eXBlc1Jlc3BvbnNlEmQKFHNlc3Npb25fZW50aXR5X3R5cGVzGAEgAygLMjIuZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TZXNzaW9uRW50aXR5VHlwZVISc2Vzc2lvbkVudGl0
eVR5cGVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJmChtHZXRT
ZXNzaW9uRW50aXR5VHlwZVJlcXVlc3QSRwoEbmFtZRgBIAEoCUIz4EEC+kEtCitkaWFsb2dm
bG93Lmdvb2dsZWFwaXMuY29tL1Nlc3Npb25FbnRpdHlUeXBlUgRuYW1lItYBCh5DcmVhdGVT
ZXNzaW9uRW50aXR5VHlwZVJlcXVlc3QSSwoGcGFyZW50GAEgASgJQjPgQQL6QS0SK2RpYWxv
Z2Zsb3cuZ29vZ2xlYXBpcy5jb20vU2Vzc2lvbkVudGl0eVR5cGVSBnBhcmVudBJnChNzZXNz
aW9uX2VudGl0eV90eXBlGAIgASgLMjIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRh
MS5TZXNzaW9uRW50aXR5VHlwZUID4EECUhFzZXNzaW9uRW50aXR5VHlwZSLGAQoeVXBkYXRl
U2Vzc2lvbkVudGl0eVR5cGVSZXF1ZXN0EmcKE3Nlc3Npb25fZW50aXR5X3R5cGUYASABKAsy
Mi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlNlc3Npb25FbnRpdHlUeXBlQgPg
QQJSEXNlc3Npb25FbnRpdHlUeXBlEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJpCh5EZWxldGVTZXNzaW9uRW50aXR5VHlw
ZVJlcXVlc3QSRwoEbmFtZRgBIAEoCUIz4EEC+kEtCitkaWFsb2dmbG93Lmdvb2dsZWFwaXMu
Y29tL1Nlc3Npb25FbnRpdHlUeXBlUgRuYW1lMvsVChJTZXNzaW9uRW50aXR5VHlwZXMS5AMK
Fkxpc3RTZXNzaW9uRW50aXR5VHlwZXMSPi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJl
dGExLkxpc3RTZXNzaW9uRW50aXR5VHlwZXNSZXF1ZXN0Gj8uZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjJiZXRhMS5MaXN0U2Vzc2lvbkVudGl0eVR5cGVzUmVzcG9uc2UiyAKC0+STArgC
EjkvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyovYWdlbnQvc2Vzc2lvbnMvKn0vZW50aXR5
VHlwZXNaUhJQL3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50L2Vudmlyb25tZW50
cy8qL3VzZXJzLyovc2Vzc2lvbnMvKn0vZW50aXR5VHlwZXNaRxJFL3YyYmV0YTEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L3Nlc3Npb25zLyp9L2VudGl0eVR5cGVz
Wl4SXC92MmJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9lbnZp
cm9ubWVudHMvKi91c2Vycy8qL3Nlc3Npb25zLyp9L2VudGl0eVR5cGVz2kEGcGFyZW50EtED
ChRHZXRTZXNzaW9uRW50aXR5VHlwZRI8Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0
YTEuR2V0U2Vzc2lvbkVudGl0eVR5cGVSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cudjJiZXRhMS5TZXNzaW9uRW50aXR5VHlwZSLGAoLT5JMCuAISOS92MmJldGExL3tuYW1l
PXByb2plY3RzLyovYWdlbnQvc2Vzc2lvbnMvKi9lbnRpdHlUeXBlcy8qfVpSElAvdjJiZXRh
MS97bmFtZT1wcm9qZWN0cy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lv
bnMvKi9lbnRpdHlUeXBlcy8qfVpHEkUvdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2FnZW50L3Nlc3Npb25zLyovZW50aXR5VHlwZXMvKn1aXhJcL3YyYmV0YTEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9lbnZpcm9ubWVudHMvKi91c2Vycy8q
L3Nlc3Npb25zLyovZW50aXR5VHlwZXMvKn3aQQRuYW1lEsEEChdDcmVhdGVTZXNzaW9uRW50
aXR5VHlwZRI/Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ3JlYXRlU2Vzc2lv
bkVudGl0eVR5cGVSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5T
ZXNzaW9uRW50aXR5VHlwZSKwA4LT5JMCjAMiOS92MmJldGExL3twYXJlbnQ9cHJvamVjdHMv
Ki9hZ2VudC9zZXNzaW9ucy8qfS9lbnRpdHlUeXBlczoTc2Vzc2lvbl9lbnRpdHlfdHlwZVpn
IlAvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyovYWdlbnQvZW52aXJvbm1lbnRzLyovdXNl
cnMvKi9zZXNzaW9ucy8qfS9lbnRpdHlUeXBlczoTc2Vzc2lvbl9lbnRpdHlfdHlwZVpcIkUv
djJiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvc2Vzc2lvbnMv
Kn0vZW50aXR5VHlwZXM6E3Nlc3Npb25fZW50aXR5X3R5cGVacyJcL3YyYmV0YTEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyov
c2Vzc2lvbnMvKn0vZW50aXR5VHlwZXM6E3Nlc3Npb25fZW50aXR5X3R5cGXaQRpwYXJlbnQs
c2Vzc2lvbl9lbnRpdHlfdHlwZRKtBQoXVXBkYXRlU2Vzc2lvbkVudGl0eVR5cGUSPy5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlVwZGF0ZVNlc3Npb25FbnRpdHlUeXBlUmVx
dWVzdBoyLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuU2Vzc2lvbkVudGl0eVR5
cGUinASC0+STAt0DMk0vdjJiZXRhMS97c2Vzc2lvbl9lbnRpdHlfdHlwZS5uYW1lPXByb2pl
Y3RzLyovYWdlbnQvc2Vzc2lvbnMvKi9lbnRpdHlUeXBlcy8qfToTc2Vzc2lvbl9lbnRpdHlf
dHlwZVp7MmQvdjJiZXRhMS97c2Vzc2lvbl9lbnRpdHlfdHlwZS5uYW1lPXByb2plY3RzLyov
YWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9
OhNzZXNzaW9uX2VudGl0eV90eXBlWnAyWS92MmJldGExL3tzZXNzaW9uX2VudGl0eV90eXBl
Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9zZXNzaW9ucy8qL2VudGl0eVR5
cGVzLyp9OhNzZXNzaW9uX2VudGl0eV90eXBlWocBMnAvdjJiZXRhMS97c2Vzc2lvbl9lbnRp
dHlfdHlwZS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRz
LyovdXNlcnMvKi9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9OhNzZXNzaW9uX2VudGl0eV90
eXBl2kETc2Vzc2lvbl9lbnRpdHlfdHlwZdpBH3Nlc3Npb25fZW50aXR5X3R5cGUsdXBkYXRl
X21hc2sSuwMKF0RlbGV0ZVNlc3Npb25FbnRpdHlUeXBlEj8uZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjJiZXRhMS5EZWxldGVTZXNzaW9uRW50aXR5VHlwZVJlcXVlc3QaFi5nb29nbGUu
cHJvdG9idWYuRW1wdHkixgKC0+STArgCKjkvdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2Fn
ZW50L3Nlc3Npb25zLyovZW50aXR5VHlwZXMvKn1aUipQL3YyYmV0YTEve25hbWU9cHJvamVj
dHMvKi9hZ2VudC9lbnZpcm9ubWVudHMvKi91c2Vycy8qL3Nlc3Npb25zLyovZW50aXR5VHlw
ZXMvKn1aRypFL3YyYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9z
ZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9Wl4qXC92MmJldGExL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qL2Vu
dGl0eVR5cGVzLyp92kEEbmFtZRp4ykEZZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaWFsb2dmbG93QqsBCiNjb20uZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjJiZXRhMUIWU2Vzc2lvbkVudGl0eVR5cGVQcm90b1ABWkNjbG91ZC5n
b29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjJiZXRhMS9kaWFsb2dmbG93cGI7ZGlhbG9n
Zmxvd3BiogICREaqAh9Hb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkJldGExSqRXCgcSBQ4A
7AIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMA
EgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAOwoJCgID
BRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgA8CgkKAgglEgMaADwKCAoBCBIDGwBaCgkKAggL
EgMbAFoKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA3CgkKAggIEgMdADcKCAoBCBID
HgA8CgkKAggBEgMeADwKCAoBCBIDHwAgCgkKAggkEgMfACAKbQoCBgASBSMAogEBGmAgU2Vy
dmljZSBmb3IgbWFuYWdpbmcKIFtTZXNzaW9uRW50aXR5VHlwZXNdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyYmV0YTEuU2Vzc2lvbkVudGl0eVR5cGVdLgoKCgoDBgABEgMjCBoKCgoD
BgADEgMkAkEKDAoFBgADmQgSAyQCQQoLCgMGAAMSBCUCJzMKDQoFBgADmggSBCUCJzMK+QEK
BAYAAgASBC4CPQMa6gEgUmV0dXJucyB0aGUgbGlzdCBvZiBhbGwgc2Vzc2lvbiBlbnRpdHkg
dHlwZXMgaW4gdGhlIHNwZWNpZmllZCBzZXNzaW9uLgoKIFRoaXMgbWV0aG9kIGRvZXNuJ3Qg
d29yayB3aXRoIEdvb2dsZSBBc3Npc3RhbnQgaW50ZWdyYXRpb24uCiBDb250YWN0IERpYWxv
Z2Zsb3cgc3VwcG9ydCBpZiB5b3UgbmVlZCB0byB1c2Ugc2Vzc2lvbiBlbnRpdGllcwogd2l0
aCBHb29nbGUgQXNzaXN0YW50IGludGVncmF0aW9uLgoKDAoFBgACAAESAy4GHAoMCgUGAAIA
AhIDLh06CgwKBQYAAgADEgMvDy0KDQoFBgACAAQSBDAEOwYKEQoJBgACAASwyrwiEgQwBDsG
CgwKBQYAAgAEEgM8BDQKDwoIBgACAASbCAASAzwENArfAQoEBgACARIERAJTAxrQASBSZXRy
aWV2ZXMgdGhlIHNwZWNpZmllZCBzZXNzaW9uIGVudGl0eSB0eXBlLgoKIFRoaXMgbWV0aG9k
IGRvZXNuJ3Qgd29yayB3aXRoIEdvb2dsZSBBc3Npc3RhbnQgaW50ZWdyYXRpb24uCiBDb250
YWN0IERpYWxvZ2Zsb3cgc3VwcG9ydCBpZiB5b3UgbmVlZCB0byB1c2Ugc2Vzc2lvbiBlbnRp
dGllcwogd2l0aCBHb29nbGUgQXNzaXN0YW50IGludGVncmF0aW9uLgoKDAoFBgACAQESA0QG
GgoMCgUGAAIBAhIDRBs2CgwKBQYAAgEDEgNFDyAKDQoFBgACAQQSBEYEUQYKEQoJBgACAQSw
yrwiEgRGBFEGCgwKBQYAAgEEEgNSBDIKDwoIBgACAQSbCAASA1IEMgqsAgoEBgACAhIEXQJw
AxqdAiBDcmVhdGVzIGEgc2Vzc2lvbiBlbnRpdHkgdHlwZS4KCiBJZiB0aGUgc3BlY2lmaWVk
IHNlc3Npb24gZW50aXR5IHR5cGUgYWxyZWFkeSBleGlzdHMsIG92ZXJyaWRlcyB0aGUKIHNl
c3Npb24gZW50aXR5IHR5cGUuCgogVGhpcyBtZXRob2QgZG9lc24ndCB3b3JrIHdpdGggR29v
Z2xlIEFzc2lzdGFudCBpbnRlZ3JhdGlvbi4KIENvbnRhY3QgRGlhbG9nZmxvdyBzdXBwb3J0
IGlmIHlvdSBuZWVkIHRvIHVzZSBzZXNzaW9uIGVudGl0aWVzCiB3aXRoIEdvb2dsZSBBc3Np
c3RhbnQgaW50ZWdyYXRpb24uCgoMCgUGAAICARIDXQYdCgwKBQYAAgICEgNdHjwKDAoFBgAC
AgMSA14PIAoNCgUGAAICBBIEXwRuBgoRCgkGAAICBLDKvCISBF8EbgYKDAoFBgACAgQSA28E
SAoPCggGAAICBJsIABIDbwRICt4BCgQGAAIDEgV3AosBAxrOASBVcGRhdGVzIHRoZSBzcGVj
aWZpZWQgc2Vzc2lvbiBlbnRpdHkgdHlwZS4KCiBUaGlzIG1ldGhvZCBkb2Vzbid0IHdvcmsg
d2l0aCBHb29nbGUgQXNzaXN0YW50IGludGVncmF0aW9uLgogQ29udGFjdCBEaWFsb2dmbG93
IHN1cHBvcnQgaWYgeW91IG5lZWQgdG8gdXNlIHNlc3Npb24gZW50aXRpZXMKIHdpdGggR29v
Z2xlIEFzc2lzdGFudCBpbnRlZ3JhdGlvbi4KCgwKBQYAAgMBEgN3Bh0KDAoFBgACAwISA3ce
PAoMCgUGAAIDAxIDeA8gCg4KBQYAAgMEEgV5BIgBBgoSCgkGAAIDBLDKvCISBXkEiAEGCg0K
BQYAAgMEEgSJAQRBChAKCAYAAgMEmwgAEgSJAQRBCg0KBQYAAgMEEgSKAQRNChAKCAYAAgME
mwgBEgSKAQRNCt8BCgQGAAIEEgaSAQKhAQMazgEgRGVsZXRlcyB0aGUgc3BlY2lmaWVkIHNl
c3Npb24gZW50aXR5IHR5cGUuCgogVGhpcyBtZXRob2QgZG9lc24ndCB3b3JrIHdpdGggR29v
Z2xlIEFzc2lzdGFudCBpbnRlZ3JhdGlvbi4KIENvbnRhY3QgRGlhbG9nZmxvdyBzdXBwb3J0
IGlmIHlvdSBuZWVkIHRvIHVzZSBzZXNzaW9uIGVudGl0aWVzCiB3aXRoIEdvb2dsZSBBc3Np
c3RhbnQgaW50ZWdyYXRpb24uCgoNCgUGAAIEARIEkgEGHQoNCgUGAAIEAhIEkgEePAoNCgUG
AAIEAxIEkwEPJAoPCgUGAAIEBBIGlAEEnwEGChMKCQYAAgQEsMq8IhIGlAEEnwEGCg0KBQYA
AgQEEgSgAQQyChAKCAYAAgQEmwgAEgSgAQQyCvMDCgIEABIGrAEA5QEBGuQDIEEgc2Vzc2lv
biByZXByZXNlbnRzIGEgY29udmVyc2F0aW9uIGJldHdlZW4gYSBEaWFsb2dmbG93IGFnZW50
IGFuZCBhbgogZW5kLXVzZXIuIFlvdSBjYW4gY3JlYXRlIHNwZWNpYWwgZW50aXRpZXMsIGNh
bGxlZCBzZXNzaW9uIGVudGl0aWVzLCBkdXJpbmcgYQogc2Vzc2lvbi4gU2Vzc2lvbiBlbnRp
dGllcyBjYW4gZXh0ZW5kIG9yIHJlcGxhY2UgY3VzdG9tIGVudGl0eSB0eXBlcyBhbmQgb25s
eQogZXhpc3QgZHVyaW5nIHRoZSBzZXNzaW9uIHRoYXQgdGhleSB3ZXJlIGNyZWF0ZWQgZm9y
LiBBbGwgc2Vzc2lvbiBkYXRhLAogaW5jbHVkaW5nIHNlc3Npb24gZW50aXRpZXMsIGlzIHN0
b3JlZCBieSBEaWFsb2dmbG93IGZvciAyMCBtaW51dGVzLgoKIEZvciBtb3JlIGluZm9ybWF0
aW9uLCBzZWUgdGhlIFtzZXNzaW9uIGVudGl0eQogZ3VpZGVdKGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9kaWFsb2dmbG93L2RvY3MvZW50aXRpZXMtc2Vzc2lvbikuCgoLCgMEAAESBKwB
CBkKDQoDBAAHEgatAQKzAQQKDwoFBAAHnQgSBq0BArMBBApHCgQEAAQAEga2AQLJAQMaNyBU
aGUgdHlwZXMgb2YgbW9kaWZpY2F0aW9ucyBmb3IgYSBzZXNzaW9uIGVudGl0eSB0eXBlLgoK
DQoFBAAEAAESBLYBBxkKQQoGBAAEAAIAEgS4AQQpGjEgTm90IHNwZWNpZmllZC4gVGhpcyB2
YWx1ZSBzaG91bGQgYmUgbmV2ZXIgdXNlZC4KCg8KBwQABAACAAESBLgBBCQKDwoHBAAEAAIA
AhIEuAEnKAqDAQoGBAAEAAIBEgS8AQQmGnMgVGhlIGNvbGxlY3Rpb24gb2Ygc2Vzc2lvbiBl
bnRpdGllcyBvdmVycmlkZXMgdGhlIGNvbGxlY3Rpb24gb2YgZW50aXRpZXMKIGluIHRoZSBj
b3JyZXNwb25kaW5nIGN1c3RvbSBlbnRpdHkgdHlwZS4KCg8KBwQABAACAQESBLwBBCEKDwoH
BAAEAAIBAhIEvAEkJQqXBAoGBAAEAAICEgTIAQQoGoYEIFRoZSBjb2xsZWN0aW9uIG9mIHNl
c3Npb24gZW50aXRpZXMgZXh0ZW5kcyB0aGUgY29sbGVjdGlvbiBvZiBlbnRpdGllcyBpbgog
dGhlIGNvcnJlc3BvbmRpbmcgY3VzdG9tIGVudGl0eSB0eXBlLgoKIE5vdGU6IEV2ZW4gaW4g
dGhpcyBvdmVycmlkZSBtb2RlIGNhbGxzIHRvIGBMaXN0U2Vzc2lvbkVudGl0eVR5cGVzYCwK
IGBHZXRTZXNzaW9uRW50aXR5VHlwZWAsIGBDcmVhdGVTZXNzaW9uRW50aXR5VHlwZWAgYW5k
CiBgVXBkYXRlU2Vzc2lvbkVudGl0eVR5cGVgIG9ubHkgcmV0dXJuIHRoZSBhZGRpdGlvbmFs
IGVudGl0aWVzIGFkZGVkIGluCiB0aGlzIHNlc3Npb24gZW50aXR5IHR5cGUuIElmIHlvdSB3
YW50IHRvIGdldCB0aGUgc3VwcGxlbWVudGVkIGxpc3QsCiBwbGVhc2UgY2FsbAogW0VudGl0
eVR5cGVzLkdldEVudGl0eVR5cGVdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
RW50aXR5VHlwZXMuR2V0RW50aXR5VHlwZV0KIG9uIHRoZSBjdXN0b20gZW50aXR5IHR5cGUg
YW5kIG1lcmdlLgoKDwoHBAAEAAICARIEyAEEIwoPCgcEAAQAAgICEgTIASYnCtIHCgQEAAIA
EgTcAQISGsMHIFJlcXVpcmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhpcyBzZXNz
aW9uIGVudGl0eSB0eXBlLiBTdXBwb3J0ZWQKIGZvcm1hdHM6CiAtIGBwcm9qZWN0cy88UHJv
amVjdCBJRD4vYWdlbnQvc2Vzc2lvbnMvPFNlc3Npb24gSUQ+L2VudGl0eVR5cGVzLzxFbnRp
dHkKICAgVHlwZSBEaXNwbGF5IE5hbWU+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xv
Y2F0aW9ucy88TG9jYXRpb24gSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9uCiAgIElEPi9l
bnRpdHlUeXBlcy88RW50aXR5IFR5cGUgRGlzcGxheSBOYW1lPmAKIC0gYHByb2plY3RzLzxQ
cm9qZWN0IElEPi9hZ2VudC9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50IElEPi91c2Vycy88
VXNlcgogICBJRD4vc2Vzc2lvbnMvPFNlc3Npb24gSUQ+L2VudGl0eVR5cGVzLzxFbnRpdHkg
VHlwZSBEaXNwbGF5IE5hbWU+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9u
cy88TG9jYXRpb24gSUQ+L2FnZW50L2Vudmlyb25tZW50cy8KICAgPEVudmlyb25tZW50IElE
Pi91c2Vycy88VXNlciBJRD4vc2Vzc2lvbnMvPFNlc3Npb24KICAgSUQ+L2VudGl0eVR5cGVz
LzxFbnRpdHkgVHlwZSBEaXNwbGF5IE5hbWU+YAoKIElmIGBMb2NhdGlvbiBJRGAgaXMgbm90
IHNwZWNpZmllZCB3ZSBhc3N1bWUgZGVmYXVsdCAndXMnIGxvY2F0aW9uLiBJZgogYEVudmly
b25tZW50IElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnZHJhZnQn
IGVudmlyb25tZW50LgogSWYgYFVzZXIgSURgIGlzIG5vdCBzcGVjaWZpZWQsIHdlIGFzc3Vt
ZSBkZWZhdWx0ICctJyB1c2VyLgogYDxFbnRpdHkgVHlwZSBEaXNwbGF5IE5hbWU+YCBtdXN0
IGJlIHRoZSBkaXNwbGF5IG5hbWUgb2YgYW4gZXhpc3RpbmcgZW50aXR5CiB0eXBlIGluIHRo
ZSBzYW1lIGFnZW50IHRoYXQgd2lsbCBiZSBvdmVycmlkZGVuIG9yIHN1cHBsZW1lbnRlZC4K
Cg0KBQQAAgAFEgTcAQIICg0KBQQAAgABEgTcAQkNCg0KBQQAAgADEgTcARARCoEBCgQEAAIB
EgTgAQIuGnMgUmVxdWlyZWQuIEluZGljYXRlcyB3aGV0aGVyIHRoZSBhZGRpdGlvbmFsIGRh
dGEgc2hvdWxkIG92ZXJyaWRlIG9yCiBzdXBwbGVtZW50IHRoZSBjdXN0b20gZW50aXR5IHR5
cGUgZGVmaW5pdGlvbi4KCg0KBQQAAgEGEgTgAQIUCg0KBQQAAgEBEgTgARUpCg0KBQQAAgED
EgTgASwtCl8KBAQAAgISBOQBAioaUSBSZXF1aXJlZC4gVGhlIGNvbGxlY3Rpb24gb2YgZW50
aXRpZXMgYXNzb2NpYXRlZCB3aXRoIHRoaXMgc2Vzc2lvbiBlbnRpdHkKIHR5cGUuCgoNCgUE
AAICBBIE5AECCgoNCgUEAAICBhIE5AELHAoNCgUEAAICARIE5AEdJQoNCgUEAAICAxIE5AEo
KQqhAQoCBAESBukBAIUCARqSASBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW1Nlc3Npb25F
bnRpdHlUeXBlcy5MaXN0U2Vzc2lvbkVudGl0eVR5cGVzXVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52MmJldGExLlNlc3Npb25FbnRpdHlUeXBlcy5MaXN0U2Vzc2lvbkVudGl0eVR5cGVz
XS4KCgsKAwQBARIE6QEIJQqpBQoEBAECABIG+AEC/QEEGpgFIFJlcXVpcmVkLiBUaGUgc2Vz
c2lvbiB0byBsaXN0IGFsbCBzZXNzaW9uIGVudGl0eSB0eXBlcyBmcm9tLgogU3VwcG9ydGVk
IGZvcm1hdHM6CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvc2Vzc2lvbnMvPFNl
c3Npb24gSUQ+LAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRp
b24gSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9uCiAgIElEPmAsCiAtIGBwcm9qZWN0cy88
UHJvamVjdCBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNlcnMv
PFVzZXIKICAgSUQ+L3Nlc3Npb25zLzxTZXNzaW9uIElEPmAsCiAtIGBwcm9qZWN0cy88UHJv
amVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbgogICBJRD4vYWdlbnQvZW52aXJvbm1lbnRz
LzxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVzZXIgSUQ+L3Nlc3Npb25zLzxTZXNzaW9uCiAg
IElEPmAsCgogSWYgYExvY2F0aW9uIElEYCBpcyBub3Qgc3BlY2lmaWVkIHdlIGFzc3VtZSBk
ZWZhdWx0ICd1cycgbG9jYXRpb24uIElmCiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVj
aWZpZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcgZW52aXJvbm1lbnQuCiBJZiBgVXNl
ciBJRGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJy0nIHVzZXIuCgoN
CgUEAQIABRIE+AECCAoNCgUEAQIAARIE+AEJDwoNCgUEAQIAAxIE+AESEwoPCgUEAQIACBIG
+AEU/QEDChAKCAQBAgAInAgAEgT5AQQqChEKBwQBAgAInwgSBvoBBPwBBQpzCgQEAQIBEgSB
AgIWGmUgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4g
aW4gYSBzaW5nbGUgcGFnZS4gQnkKIGRlZmF1bHQgMTAwIGFuZCBhdCBtb3N0IDEwMDAuCgoN
CgUEAQIBBRIEgQICBwoNCgUEAQIBARIEgQIIEQoNCgUEAQIBAxIEgQIUFQpaCgQEAQICEgSE
AgIYGkwgT3B0aW9uYWwuIFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJv
bSBhIHByZXZpb3VzIGxpc3QgcmVxdWVzdC4KCg0KBQQBAgIFEgSEAgIICg0KBQQBAgIBEgSE
AgkTCg0KBQQBAgIDEgSEAhYXCqIBCgIEAhIGiQIAkQIBGpMBIFRoZSByZXNwb25zZSBtZXNz
YWdlIGZvcgogW1Nlc3Npb25FbnRpdHlUeXBlcy5MaXN0U2Vzc2lvbkVudGl0eVR5cGVzXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlNlc3Npb25FbnRpdHlUeXBlcy5MaXN0
U2Vzc2lvbkVudGl0eVR5cGVzXS4KCgsKAwQCARIEiQIIJgqRAQoEBAICABIEjAICNhqCASBU
aGUgbGlzdCBvZiBzZXNzaW9uIGVudGl0eSB0eXBlcy4gVGhlcmUgd2lsbCBiZSBhIG1heGlt
dW0gbnVtYmVyIG9mIGl0ZW1zCiByZXR1cm5lZCBiYXNlZCBvbiB0aGUgcGFnZV9zaXplIGZp
ZWxkIGluIHRoZSByZXF1ZXN0LgoKDQoFBAICAAQSBIwCAgoKDQoFBAICAAYSBIwCCxwKDQoF
BAICAAESBIwCHTEKDQoFBAICAAMSBIwCNDUKbwoEBAICARIEkAICHRphIFRva2VuIHRvIHJl
dHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJl
IG5vCiBtb3JlIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAgIBBRIEkAICCAoNCgUEAgIB
ARIEkAIJGAoNCgUEAgIBAxIEkAIbHAqdAQoCBAMSBpUCAKoCARqOASBUaGUgcmVxdWVzdCBt
ZXNzYWdlIGZvcgogW1Nlc3Npb25FbnRpdHlUeXBlcy5HZXRTZXNzaW9uRW50aXR5VHlwZV1b
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TZXNzaW9uRW50aXR5VHlwZXMuR2V0
U2Vzc2lvbkVudGl0eVR5cGVdLgoKCwoDBAMBEgSVAggjCrcGCgQEAwIAEgakAgKpAgQapgYg
UmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzZXNzaW9uIGVudGl0eSB0eXBlLiBTdXBwb3J0
ZWQgZm9ybWF0czoKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9zZXNzaW9ucy88
U2Vzc2lvbiBJRD4vZW50aXR5VHlwZXMvPEVudGl0eQogICBUeXBlIERpc3BsYXkgTmFtZT5g
CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD4vYWdl
bnQvc2Vzc2lvbnMvPFNlc3Npb24KICAgSUQ+L2VudGl0eVR5cGVzLzxFbnRpdHkgVHlwZSBE
aXNwbGF5IE5hbWU+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vudmlyb25t
ZW50cy88RW52aXJvbm1lbnQgSUQ+L3VzZXJzLzxVc2VyCiAgIElEPi9zZXNzaW9ucy88U2Vz
c2lvbiBJRD4vZW50aXR5VHlwZXMvPEVudGl0eSBUeXBlIERpc3BsYXkgTmFtZT5gCiAtIGBw
cm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD4vYWdlbnQvZW52
aXJvbm1lbnRzLwogICA8RW52aXJvbm1lbnQgSUQ+L3VzZXJzLzxVc2VyIElEPi9zZXNzaW9u
cy88U2Vzc2lvbgogICBJRD4vZW50aXR5VHlwZXMvPEVudGl0eSBUeXBlIERpc3BsYXkgTmFt
ZT5gCgogSWYgYExvY2F0aW9uIElEYCBpcyBub3Qgc3BlY2lmaWVkIHdlIGFzc3VtZSBkZWZh
dWx0ICd1cycgbG9jYXRpb24uIElmCiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZp
ZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcgZW52aXJvbm1lbnQuCiBJZiBgVXNlciBJ
RGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJy0nIHVzZXIuCgoNCgUE
AwIABRIEpAICCAoNCgUEAwIAARIEpAIJDQoNCgUEAwIAAxIEpAIQEQoPCgUEAwIACBIGpAIS
qQIDChAKCAQDAgAInAgAEgSlAgQqChEKBwQDAgAInwgSBqYCBKgCBQqjAQoCBAQSBq4CAMcC
ARqUASBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW1Nlc3Npb25FbnRpdHlUeXBlcy5DcmVh
dGVTZXNzaW9uRW50aXR5VHlwZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5T
ZXNzaW9uRW50aXR5VHlwZXMuQ3JlYXRlU2Vzc2lvbkVudGl0eVR5cGVdLgoKCwoDBAQBEgSu
AggmCqcFCgQEBAIAEga9AgLCAgQalgUgUmVxdWlyZWQuIFRoZSBzZXNzaW9uIHRvIGNyZWF0
ZSBhIHNlc3Npb24gZW50aXR5IHR5cGUgZm9yLgogU3VwcG9ydGVkIGZvcm1hdHM6CiAtIGBw
cm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvc2Vzc2lvbnMvPFNlc3Npb24gSUQ+LAogLSBg
cHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+L2FnZW50L3Nl
c3Npb25zLzxTZXNzaW9uCiAgIElEPmAsCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdl
bnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVzZXIKICAgSUQ+L3Nl
c3Npb25zLzxTZXNzaW9uIElEPmAsCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRp
b25zLzxMb2NhdGlvbgogICBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJ
RD4vdXNlcnMvPFVzZXIgSUQ+L3Nlc3Npb25zLzxTZXNzaW9uCiAgIElEPmAsCgogSWYgYExv
Y2F0aW9uIElEYCBpcyBub3Qgc3BlY2lmaWVkIHdlIGFzc3VtZSBkZWZhdWx0ICd1cycgbG9j
YXRpb24uIElmCiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZpZWQsIHdlIGFzc3Vt
ZSBkZWZhdWx0ICdkcmFmdCcgZW52aXJvbm1lbnQuCiBJZiBgVXNlciBJRGAgaXMgbm90IHNw
ZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJy0nIHVzZXIuCgoNCgUEBAIABRIEvQICCAoN
CgUEBAIAARIEvQIJDwoNCgUEBAIAAxIEvQISEwoPCgUEBAIACBIGvQIUwgIDChAKCAQEAgAI
nAgAEgS+AgQqChEKBwQEAgAInwgSBr8CBMECBQo+CgQEBAIBEgbFAgLGAi8aLiBSZXF1aXJl
ZC4gVGhlIHNlc3Npb24gZW50aXR5IHR5cGUgdG8gY3JlYXRlLgoKDQoFBAQCAQYSBMUCAhMK
DQoFBAQCAQESBMUCFCcKDQoFBAQCAQMSBMUCKisKDQoFBAQCAQgSBMYCBi4KEAoIBAQCAQic
CAASBMYCBy0KowEKAgQFEgbLAgDSAgEalAEgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtT
ZXNzaW9uRW50aXR5VHlwZXMuVXBkYXRlU2Vzc2lvbkVudGl0eVR5cGVdW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyYmV0YTEuU2Vzc2lvbkVudGl0eVR5cGVzLlVwZGF0ZVNlc3Npb25F
bnRpdHlUeXBlXS4KCgsKAwQFARIEywIIJgo+CgQEBQIAEgbNAgLOAi8aLiBSZXF1aXJlZC4g
VGhlIHNlc3Npb24gZW50aXR5IHR5cGUgdG8gdXBkYXRlLgoKDQoFBAUCAAYSBM0CAhMKDQoF
BAUCAAESBM0CFCcKDQoFBAUCAAMSBM0CKisKDQoFBAUCAAgSBM4CBi4KEAoIBAUCAAicCAAS
BM4CBy0KRwoEBAUCARIE0QICLBo5IE9wdGlvbmFsLiBUaGUgbWFzayB0byBjb250cm9sIHdo
aWNoIGZpZWxkcyBnZXQgdXBkYXRlZC4KCg0KBQQFAgEGEgTRAgIbCg0KBQQFAgEBEgTRAhwn
Cg0KBQQFAgEDEgTRAiorCqMBCgIEBhIG1gIA7AIBGpQBIFRoZSByZXF1ZXN0IG1lc3NhZ2Ug
Zm9yCiBbU2Vzc2lvbkVudGl0eVR5cGVzLkRlbGV0ZVNlc3Npb25FbnRpdHlUeXBlXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlNlc3Npb25FbnRpdHlUeXBlcy5EZWxldGVT
ZXNzaW9uRW50aXR5VHlwZV0uCgoLCgMEBgESBNYCCCYKugYKBAQGAgASBuYCAusCBBqpBiBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGVudGl0eSB0eXBlIHRvIGRlbGV0ZS4KIFN1cHBv
cnRlZCBmb3JtYXRzOgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L3Nlc3Npb25z
LzxTZXNzaW9uIElEPi9lbnRpdHlUeXBlcy88RW50aXR5CiAgIFR5cGUgRGlzcGxheSBOYW1l
PmAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9h
Z2VudC9zZXNzaW9ucy88U2Vzc2lvbgogICBJRD4vZW50aXR5VHlwZXMvPEVudGl0eSBUeXBl
IERpc3BsYXkgTmFtZT5gCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvZW52aXJv
bm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVzZXIKICAgSUQ+L3Nlc3Npb25zLzxT
ZXNzaW9uIElEPi9lbnRpdHlUeXBlcy88RW50aXR5IFR5cGUgRGlzcGxheSBOYW1lPmAKIC0g
YHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9hZ2VudC9l
bnZpcm9ubWVudHMvCiAgIDxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVzZXIgSUQ+L3Nlc3Np
b25zLzxTZXNzaW9uCiAgIElEPi9lbnRpdHlUeXBlcy88RW50aXR5IFR5cGUgRGlzcGxheSBO
YW1lPmAKCiBJZiBgTG9jYXRpb24gSURgIGlzIG5vdCBzcGVjaWZpZWQgd2UgYXNzdW1lIGRl
ZmF1bHQgJ3VzJyBsb2NhdGlvbi4gSWYKIGBFbnZpcm9ubWVudCBJRGAgaXMgbm90IHNwZWNp
ZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJ2RyYWZ0JyBlbnZpcm9ubWVudC4KIElmIGBVc2Vy
IElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnLScgdXNlci4KCg0K
BQQGAgAFEgTmAgIICg0KBQQGAgABEgTmAgkNCg0KBQQGAgADEgTmAhARCg8KBQQGAgAIEgbm
AhLrAgMKEAoIBAYCAAicCAASBOcCBCoKEQoHBAYCAAifCBIG6AIE6gIFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType ===
    # Fields for SessionEntityType
    # Field: name Type: 9 ()
    # Field: entity_override_mode Type: 14 (.google.cloud.dialogflow.v2beta1.SessionEntityType.EntityOverrideMode)
    # Field: entities Type: 11 (.google.cloud.dialogflow.v2beta1.EntityType.Entity)

# Enum: SessionEntityType::EntityOverrideMode
our $SessionEntityType_ENTITY_OVERRIDE_MODE_UNSPECIFIED = 0;
our $SessionEntityType_ENTITY_OVERRIDE_MODE_OVERRIDE = 1;
our $SessionEntityType_ENTITY_OVERRIDE_MODE_SUPPLEMENT = 2;

# === Message: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesRequest ===
    # Fields for ListSessionEntityTypesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesResponse ===
    # Fields for ListSessionEntityTypesResponse
    # Field: session_entity_types Type: 11 (.google.cloud.dialogflow.v2beta1.SessionEntityType)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::GetSessionEntityTypeRequest ===
    # Fields for GetSessionEntityTypeRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::CreateSessionEntityTypeRequest ===
    # Fields for CreateSessionEntityTypeRequest
    # Field: parent Type: 9 ()
    # Field: session_entity_type Type: 11 (.google.cloud.dialogflow.v2beta1.SessionEntityType)

# === Message: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::UpdateSessionEntityTypeRequest ===
    # Fields for UpdateSessionEntityTypeRequest
    # Field: session_entity_type Type: 11 (.google.cloud.dialogflow.v2beta1.SessionEntityType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::DeleteSessionEntityTypeRequest ===
    # Fields for DeleteSessionEntityTypeRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityTypesClient ===
package Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityTypesClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityTypesClient

Client stub representing the remote C<SessionEntityTypes> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub list_session_entity_types {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SessionEntityTypes',
        method         => 'ListSessionEntityTypes',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesResponse',
    });
}

sub get_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SessionEntityType::GetSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SessionEntityTypes',
        method         => 'GetSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType',
    });
}

sub create_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SessionEntityType::CreateSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SessionEntityTypes',
        method         => 'CreateSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType',
    });
}

sub update_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SessionEntityType::UpdateSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SessionEntityTypes',
        method         => 'UpdateSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType',
    });
}

sub delete_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SessionEntityType::DeleteSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SessionEntityTypes',
        method         => 'DeleteSessionEntityType',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::SessionEntityType - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/session_entity_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::SessionEntityType;

    my $msg = Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType->new({
        name => $name,
        entity_override_mode => $entity_override_mode,
        entities => $entities,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/session_entity_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType

A session represents a conversation between a Dialogflow agent and an
end-user. You can create special entities, called session entities, during a
session. Session entities can extend or replace custom entity types and only
exist during the session that they were created for. All session data,
including session entities, is stored by Dialogflow for 20 minutes.

For more information, see the [session entity
guide](https://cloud.google.com/dialogflow/docs/entities-session).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier of this session entity type. Supported
formats:
- `projects/<Project ID>/agent/sessions/<Session ID>/entityTypes/<Entity
  Type Display Name>`
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>/entityTypes/<Entity Type Display Name>`
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>/entityTypes/<Entity Type Display Name>`
- `projects/<Project ID>/locations/<Location ID>/agent/environments/
  <Environment ID>/users/<User ID>/sessions/<Session
  ID>/entityTypes/<Entity Type Display Name>`

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.
`<Entity Type Display Name>` must be the display name of an existing entity
type in the same agent that will be overridden or supplemented.

=item * C<< $msg->entity_override_mode() >> / C<< $msg->entity_override_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::SessionEntityType::EntityOverrideMode>)

Required. Indicates whether the additional data should override or
supplement the custom entity type definition.

=item * C<< $msg->entities() >> / C<< $msg->entities($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType::Entity>)

Required. The collection of entities associated with this session entity
type.

=back

=head3 Enum: SessionEntityType::EntityOverrideMode

=over 4

=item * C<ENTITY_OVERRIDE_MODE_UNSPECIFIED> => C<0>

=item * C<ENTITY_OVERRIDE_MODE_OVERRIDE> => C<1>

=item * C<ENTITY_OVERRIDE_MODE_SUPPLEMENT> => C<2>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesRequest

The request message for
[SessionEntityTypes.ListSessionEntityTypes][google.cloud.dialogflow.v2beta1.SessionEntityTypes.ListSessionEntityTypes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to list all session entity types from.
Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>`,

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesResponse

The response message for
[SessionEntityTypes.ListSessionEntityTypes][google.cloud.dialogflow.v2beta1.SessionEntityTypes.ListSessionEntityTypes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_entity_types() >> / C<< $msg->session_entity_types($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType>)

The list of session entity types. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SessionEntityType::GetSessionEntityTypeRequest

The request message for
[SessionEntityTypes.GetSessionEntityType][google.cloud.dialogflow.v2beta1.SessionEntityTypes.GetSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the session entity type. Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>/entityTypes/<Entity
  Type Display Name>`
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>/entityTypes/<Entity Type Display Name>`
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>/entityTypes/<Entity Type Display Name>`
- `projects/<Project ID>/locations/<Location ID>/agent/environments/
  <Environment ID>/users/<User ID>/sessions/<Session
  ID>/entityTypes/<Entity Type Display Name>`

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SessionEntityType::CreateSessionEntityTypeRequest

The request message for
[SessionEntityTypes.CreateSessionEntityType][google.cloud.dialogflow.v2beta1.SessionEntityTypes.CreateSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to create a session entity type for.
Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>`,

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=item * C<< $msg->session_entity_type() >> / C<< $msg->session_entity_type($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType>)

Required. The session entity type to create.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SessionEntityType::UpdateSessionEntityTypeRequest

The request message for
[SessionEntityTypes.UpdateSessionEntityType][google.cloud.dialogflow.v2beta1.SessionEntityTypes.UpdateSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_entity_type() >> / C<< $msg->session_entity_type($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType>)

Required. The session entity type to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SessionEntityType::DeleteSessionEntityTypeRequest

The request message for
[SessionEntityTypes.DeleteSessionEntityType][google.cloud.dialogflow.v2beta1.SessionEntityTypes.DeleteSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the entity type to delete.
Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>/entityTypes/<Entity
  Type Display Name>`
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>/entityTypes/<Entity Type Display Name>`
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>/entityTypes/<Entity Type Display Name>`
- `projects/<Project ID>/locations/<Location ID>/agent/environments/
  <Environment ID>/users/<User ID>/sessions/<Session
  ID>/entityTypes/<Entity Type Display Name>`

If `Location ID` is not specified we assume default 'us' location. If
`Environment ID` is not specified, we assume default 'draft' environment.
If `User ID` is not specified, we assume default '-' user.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::SessionEntityType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
