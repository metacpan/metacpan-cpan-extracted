package Google::Cloud::Dialogflow::V2beta1::Environment;

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
    eval { require Google::Cloud::Dialogflow::V2beta1::AudioConfig };
    eval { require Google::Cloud::Dialogflow::V2beta1::Fulfillment };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2Vudmlyb25tZW50LnByb3RvEh9n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExGhxnb29nbGUvYXBpL2Fubm90YXRpb25z
LnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoyZ29vZ2xlL2Nsb3VkL2Rp
YWxvZ2Zsb3cvdjJiZXRhMS9hdWRpb19jb25maWcucHJvdG8aMWdvb2dsZS9jbG91ZC9kaWFs
b2dmbG93L3YyYmV0YTEvZnVsZmlsbG1lbnQucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0
eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8i6gUKC0Vudmlyb25tZW50EhcKBG5hbWUYASABKAlCA+BB
A1IEbmFtZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJOCg1hZ2Vu
dF92ZXJzaW9uGAMgASgJQingQQH6QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVmVy
c2lvblIMYWdlbnRWZXJzaW9uEk0KBXN0YXRlGAQgASgOMjIuZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVudC5TdGF0ZUID4EEDUgVzdGF0ZRJACgt1cGRhdGVf
dGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGlt
ZRJxChd0ZXh0X3RvX3NwZWVjaF9zZXR0aW5ncxgHIAEoCzI1Lmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTEuVGV4dFRvU3BlZWNoU2V0dGluZ3NCA+BBAVIUdGV4dFRvU3BlZWNo
U2V0dGluZ3MSUwoLZnVsZmlsbG1lbnQYCCABKAsyLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52MmJldGExLkZ1bGZpbGxtZW50QgPgQQFSC2Z1bGZpbGxtZW50IkUKBVN0YXRlEhUKEVNU
QVRFX1VOU1BFQ0lGSUVEEAASCwoHU1RPUFBFRBABEgsKB0xPQURJTkcQAhILCgdSVU5OSU5H
EAM6qgHqQaYBCiVkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0Vudmlyb25tZW50EjNwcm9q
ZWN0cy97cHJvamVjdH0vYWdlbnQvZW52aXJvbm1lbnRzL3tlbnZpcm9ubWVudH0SSHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hZ2VudC9lbnZpcm9ubWVudHMv
e2Vudmlyb25tZW50fSKKBAoUVGV4dFRvU3BlZWNoU2V0dGluZ3MSNgoVZW5hYmxlX3RleHRf
dG9fc3BlZWNoGAEgASgIQgPgQQFSEmVuYWJsZVRleHRUb1NwZWVjaBJtChVvdXRwdXRfYXVk
aW9fZW5jb2RpbmcYAiABKA4yNC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLk91
dHB1dEF1ZGlvRW5jb2RpbmdCA+BBAlITb3V0cHV0QXVkaW9FbmNvZGluZxIvChFzYW1wbGVf
cmF0ZV9oZXJ0ehgDIAEoBUID4EEBUg9zYW1wbGVSYXRlSGVydHoSkwEKGXN5bnRoZXNpemVf
c3BlZWNoX2NvbmZpZ3MYBCADKAsyUi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGEx
LlRleHRUb1NwZWVjaFNldHRpbmdzLlN5bnRoZXNpemVTcGVlY2hDb25maWdzRW50cnlCA+BB
AVIXc3ludGhlc2l6ZVNwZWVjaENvbmZpZ3MagwEKHFN5bnRoZXNpemVTcGVlY2hDb25maWdz
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSTQoFdmFsdWUYAiABKAsyNy5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52MmJldGExLlN5bnRoZXNpemVTcGVlY2hDb25maWdSBXZhbHVlOgI4ASKm
AQoXTGlzdEVudmlyb25tZW50c1JlcXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScSJWRp
YWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRW52aXJvbm1lbnRSBnBhcmVudBIgCglwYWdlX3Np
emUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdl
VG9rZW4ilAEKGExpc3RFbnZpcm9ubWVudHNSZXNwb25zZRJQCgxlbnZpcm9ubWVudHMYASAD
KAsyLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkVudmlyb25tZW50UgxlbnZp
cm9ubWVudHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIloKFUdl
dEVudmlyb25tZW50UmVxdWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJWRpYWxvZ2Zsb3cu
Z29vZ2xlYXBpcy5jb20vRW52aXJvbm1lbnRSBG5hbWUi4gEKGENyZWF0ZUVudmlyb25tZW50
UmVxdWVzdBJFCgZwYXJlbnQYASABKAlCLeBBAvpBJxIlZGlhbG9nZmxvdy5nb29nbGVhcGlz
LmNvbS9FbnZpcm9ubWVudFIGcGFyZW50ElMKC2Vudmlyb25tZW50GAIgASgLMiwuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVudEID4EECUgtlbnZpcm9ubWVu
dBIqCg5lbnZpcm9ubWVudF9pZBgDIAEoCUID4EECUg1lbnZpcm9ubWVudElkIooCChhVcGRh
dGVFbnZpcm9ubWVudFJlcXVlc3QSUwoLZW52aXJvbm1lbnQYASABKAsyLC5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MmJldGExLkVudmlyb25tZW50QgPgQQJSC2Vudmlyb25tZW50EkAK
C3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1
cGRhdGVNYXNrElcKJ2FsbG93X2xvYWRfdG9fZHJhZnRfYW5kX2Rpc2NhcmRfY2hhbmdlcxgD
IAEoCEID4EEBUiFhbGxvd0xvYWRUb0RyYWZ0QW5kRGlzY2FyZENoYW5nZXMiXQoYRGVsZXRl
RW52aXJvbm1lbnRSZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlhbG9nZmxvdy5n
b29nbGVhcGlzLmNvbS9FbnZpcm9ubWVudFIEbmFtZSKrAQocR2V0RW52aXJvbm1lbnRIaXN0
b3J5UmVxdWVzdBJFCgZwYXJlbnQYASABKAlCLeBBAvpBJwolZGlhbG9nZmxvdy5nb29nbGVh
cGlzLmNvbS9FbnZpcm9ubWVudFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghw
YWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiLGAgoSRW52aXJv
bm1lbnRIaXN0b3J5EhsKBnBhcmVudBgBIAEoCUID4EEDUgZwYXJlbnQSWAoHZW50cmllcxgC
IAMoCzI5Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuRW52aXJvbm1lbnRIaXN0
b3J5LkVudHJ5QgPgQQNSB2VudHJpZXMSKwoPbmV4dF9wYWdlX3Rva2VuGAMgASgJQgPgQQNS
DW5leHRQYWdlVG9rZW4aiwEKBUVudHJ5EiMKDWFnZW50X3ZlcnNpb24YASABKAlSDGFnZW50
VmVyc2lvbhIgCgtkZXNjcmlwdGlvbhgCIAEoCVILZGVzY3JpcHRpb24SOwoLY3JlYXRlX3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lMr8NCgxF
bnZpcm9ubWVudHMSiAIKEExpc3RFbnZpcm9ubWVudHMSOC5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52MmJldGExLkxpc3RFbnZpcm9ubWVudHNSZXF1ZXN0GjkuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjJiZXRhMS5MaXN0RW52aXJvbm1lbnRzUmVzcG9uc2Uif4LT5JMCcBIvL3Yy
YmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50fS9lbnZpcm9ubWVudHNaPRI7L3YyYmV0
YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50fS9lbnZpcm9ubWVudHPa
QQZwYXJlbnQS7gEKDkdldEVudmlyb25tZW50EjYuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djJiZXRhMS5HZXRFbnZpcm9ubWVudFJlcXVlc3QaLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52MmJldGExLkVudmlyb25tZW50InaC0+STAnASLy92MmJldGExL3tuYW1lPXByb2plY3Rz
LyovYWdlbnQvZW52aXJvbm1lbnRzLyp9Wj0SOy92MmJldGExL3tuYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRzLyp9EpACChFDcmVhdGVFbnZpcm9ubWVu
dBI5Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ3JlYXRlRW52aXJvbm1lbnRS
ZXF1ZXN0GiwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVudCKR
AYLT5JMCigEiLy92MmJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9hZ2VudH0vZW52aXJvbm1l
bnRzOgtlbnZpcm9ubWVudFpKIjsvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyovYWdlbnR9L2Vudmlyb25tZW50czoLZW52aXJvbm1lbnQSqAIKEVVwZGF0ZUVudmly
b25tZW50EjkuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5VcGRhdGVFbnZpcm9u
bWVudFJlcXVlc3QaLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkVudmlyb25t
ZW50IqkBgtPkkwKiATI7L3YyYmV0YTEve2Vudmlyb25tZW50Lm5hbWU9cHJvamVjdHMvKi9h
Z2VudC9lbnZpcm9ubWVudHMvKn06C2Vudmlyb25tZW50WlYyRy92MmJldGExL3tlbnZpcm9u
bWVudC5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRzLyp9
OgtlbnZpcm9ubWVudBLeAQoRRGVsZXRlRW52aXJvbm1lbnQSOS5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MmJldGExLkRlbGV0ZUVudmlyb25tZW50UmVxdWVzdBoWLmdvb2dsZS5wcm90
b2J1Zi5FbXB0eSJ2gtPkkwJwKi8vdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2FnZW50L2Vu
dmlyb25tZW50cy8qfVo9KjsvdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2FnZW50L2Vudmlyb25tZW50cy8qfRKZAgoVR2V0RW52aXJvbm1lbnRIaXN0b3J5Ej0uZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5HZXRFbnZpcm9ubWVudEhpc3RvcnlSZXF1
ZXN0GjMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVudEhpc3Rv
cnkiiwGC0+STAoQBEjkvdjJiZXRhMS97cGFyZW50PXByb2plY3RzLyovYWdlbnQvZW52aXJv
bm1lbnRzLyp9L2hpc3RvcnlaRxJFL3YyYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2FnZW50L2Vudmlyb25tZW50cy8qfS9oaXN0b3J5GnjKQRlkaWFsb2dmbG93Lmdv
b2dsZWFwaXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1w
bGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dCpQEK
I2NvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExQhBFbnZpcm9ubWVudFByb3Rv
UAFaQ2Nsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2MmJldGExL2RpYWxvZ2Zs
b3dwYjtkaWFsb2dmbG93cGKiAgJERqoCH0dvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYyQmV0
YTFKy2QKBxIFDgCEAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACgKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgID
BBIDFgA8CgkKAgMFEgMXADsKCQoCAwYSAxgAJQoJCgIDBxIDGQAqCgkKAgMIEgMaACkKCAoB
CBIDHAA8CgkKAgglEgMcADwKCAoBCBIDHQBaCgkKAggLEgMdAFoKCAoBCBIDHgAiCgkKAggK
EgMeACIKCAoBCBIDHwAxCgkKAggIEgMfADEKCAoBCBIDIAA8CgkKAggBEgMgADwKCAoBCBID
IQAgCgkKAggkEgMhACAKYAoCBgASBCUAeQEaVCBTZXJ2aWNlIGZvciBtYW5hZ2luZwogW0Vu
dmlyb25tZW50c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVu
dF0uCgoKCgMGAAESAyUIFAoKCgMGAAMSAyYCQQoMCgUGAAOZCBIDJgJBCgsKAwYAAxIEJwIp
MwoNCgUGAAOaCBIEJwIpMwpWCgQGAAIAEgQsAjUDGkggUmV0dXJucyB0aGUgbGlzdCBvZiBh
bGwgbm9uLWRyYWZ0IGVudmlyb25tZW50cyBvZiB0aGUgc3BlY2lmaWVkIGFnZW50LgoKDAoF
BgACAAESAywGFgoMCgUGAAIAAhIDLBcuCgwKBQYAAgADEgMtDycKDQoFBgACAAQSBC4EMwYK
EQoJBgACAASwyrwiEgQuBDMGCgwKBQYAAgAEEgM0BDQKDwoIBgACAASbCAASAzQENAo6CgQG
AAIBEgQ4Aj8DGiwgUmV0cmlldmVzIHRoZSBzcGVjaWZpZWQgYWdlbnQgZW52aXJvbm1lbnQu
CgoMCgUGAAIBARIDOAYUCgwKBQYAAgECEgM4FSoKDAoFBgACAQMSAzg1QAoNCgUGAAIBBBIE
OQQ+BgoRCgkGAAIBBLDKvCISBDkEPgYKLQoEBgACAhIEQgJLAxofIENyZWF0ZXMgYW4gYWdl
bnQgZW52aXJvbm1lbnQuCgoMCgUGAAICARIDQgYXCgwKBQYAAgICEgNCGDAKDAoFBgACAgMS
A0I7RgoNCgUGAAICBBIEQwRKBgoRCgkGAAICBLDKvCISBEMESgYK0wUKBAYAAgMSBFkCYgMa
xAUgVXBkYXRlcyB0aGUgc3BlY2lmaWVkIGFnZW50IGVudmlyb25tZW50LgoKIFRoaXMgbWV0
aG9kIGFsbG93cyB5b3UgdG8gZGVwbG95IG5ldyBhZ2VudCB2ZXJzaW9ucyBpbnRvIHRoZSBl
bnZpcm9ubWVudC4KIFdoZW4gYW4gZW52aXJvbm1lbnQgaXMgcG9pbnRlZCB0byBhIG5ldyBh
Z2VudCB2ZXJzaW9uIGJ5IHNldHRpbmcKIGBlbnZpcm9ubWVudC5hZ2VudF92ZXJzaW9uYCwg
dGhlIGVudmlyb25tZW50IGlzIHRlbXBvcmFyaWx5IHNldCB0byB0aGUKIGBMT0FESU5HYCBz
dGF0ZS4gRHVyaW5nIHRoYXQgdGltZSwgdGhlIGVudmlyb25tZW50IGtlZXBzIG9uIHNlcnZp
bmcgdGhlCiBwcmV2aW91cyB2ZXJzaW9uIG9mIHRoZSBhZ2VudC4gQWZ0ZXIgdGhlIG5ldyBh
Z2VudCB2ZXJzaW9uIGlzIGRvbmUgbG9hZGluZywKIHRoZSBlbnZpcm9ubWVudCBpcyBzZXQg
YmFjayB0byB0aGUgYFJVTk5JTkdgIHN0YXRlLgogWW91IGNhbiB1c2UgIi0iIGFzIEVudmly
b25tZW50IElEIGluIGVudmlyb25tZW50IG5hbWUgdG8gdXBkYXRlIHZlcnNpb24KIGluICJk
cmFmdCIgZW52aXJvbm1lbnQuIFdBUk5JTkc6IHRoaXMgd2lsbCBuZWdhdGUgYWxsIHJlY2Vu
dCBjaGFuZ2VzIHRvCiBkcmFmdCBhbmQgY2FuJ3QgYmUgdW5kb25lLiBZb3UgbWF5IHdhbnQg
dG8gc2F2ZSB0aGUgZHJhZnQgdG8gYSB2ZXJzaW9uCiBiZWZvcmUgY2FsbGluZyB0aGlzIGZ1
bmN0aW9uLgoKDAoFBgACAwESA1kGFwoMCgUGAAIDAhIDWRgwCgwKBQYAAgMDEgNZO0YKDQoF
BgACAwQSBFoEYQYKEQoJBgACAwSwyrwiEgRaBGEGCjgKBAYAAgQSBGUCbQMaKiBEZWxldGVz
IHRoZSBzcGVjaWZpZWQgYWdlbnQgZW52aXJvbm1lbnQuCgoMCgUGAAIEARIDZQYXCgwKBQYA
AgQCEgNlGDAKDAoFBgACBAMSA2YPJAoNCgUGAAIEBBIEZwRsBgoRCgkGAAIEBLDKvCISBGcE
bAYKPgoEBgACBRIEcAJ4AxowIEdldHMgdGhlIGhpc3Rvcnkgb2YgdGhlIHNwZWNpZmllZCBl
bnZpcm9ubWVudC4KCgwKBQYAAgUBEgNwBhsKDAoFBgACBQISA3AcOAoMCgUGAAIFAxIDcQ8h
Cg0KBQYAAgUEEgRyBHcGChEKCQYAAgUEsMq8IhIEcgR3BgqWBQoCBAASBo0BAM0BARqHBSBZ
b3UgY2FuIGNyZWF0ZSBtdWx0aXBsZSB2ZXJzaW9ucyBvZiB5b3VyIGFnZW50IGFuZCBwdWJs
aXNoIHRoZW0gdG8gc2VwYXJhdGUKIGVudmlyb25tZW50cy4KCiBXaGVuIHlvdSBlZGl0IGFu
IGFnZW50LCB5b3UgYXJlIGVkaXRpbmcgdGhlIGRyYWZ0IGFnZW50LiBBdCBhbnkgcG9pbnQs
IHlvdQogY2FuIHNhdmUgdGhlIGRyYWZ0IGFnZW50IGFzIGFuIGFnZW50IHZlcnNpb24sIHdo
aWNoIGlzIGFuIGltbXV0YWJsZSBzbmFwc2hvdAogb2YgeW91ciBhZ2VudC4KCiBXaGVuIHlv
dSBzYXZlIHRoZSBkcmFmdCBhZ2VudCwgaXQgaXMgcHVibGlzaGVkIHRvIHRoZSBkZWZhdWx0
IGVudmlyb25tZW50LgogV2hlbiB5b3UgY3JlYXRlIGFnZW50IHZlcnNpb25zLCB5b3UgY2Fu
IHB1Ymxpc2ggdGhlbSB0byBjdXN0b20gZW52aXJvbm1lbnRzLgogWW91IGNhbiBjcmVhdGUg
YSB2YXJpZXR5IG9mIGN1c3RvbSBlbnZpcm9ubWVudHMgZm9yOgoKIC0gdGVzdGluZwogLSBk
ZXZlbG9wbWVudAogLSBwcm9kdWN0aW9uCiAtIGV0Yy4KCiBGb3IgbW9yZSBpbmZvcm1hdGlv
biwgc2VlIHRoZSBbdmVyc2lvbnMgYW5kIGVudmlyb25tZW50cwogZ3VpZGVdKGh0dHBzOi8v
Y2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2RvY3MvYWdlbnRzLXZlcnNpb25zKS4KCgsK
AwQAARIEjQEIEwoNCgMEAAcSBo4BApIBBAoPCgUEAAedCBIGjgECkgEECuACCgQEAAQAEgaZ
AQKlAQMazwIgUmVwcmVzZW50cyBhbiBlbnZpcm9ubWVudCBzdGF0ZS4gV2hlbiBhbiBlbnZp
cm9ubWVudCBpcyBwb2ludGVkIHRvIGEgbmV3CiBhZ2VudCB2ZXJzaW9uLCB0aGUgZW52aXJv
bm1lbnQgaXMgdGVtcG9yYXJpbHkgc2V0IHRvIHRoZSBgTE9BRElOR2Agc3RhdGUuCiBEdXJp
bmcgdGhhdCB0aW1lLCB0aGUgZW52aXJvbm1lbnQga2VlcHMgb24gc2VydmluZyB0aGUgcHJl
dmlvdXMgdmVyc2lvbiBvZgogdGhlIGFnZW50LiBBZnRlciB0aGUgbmV3IGFnZW50IHZlcnNp
b24gaXMgZG9uZSBsb2FkaW5nLCB0aGUgZW52aXJvbm1lbnQgaXMKIHNldCBiYWNrIHRvIHRo
ZSBgUlVOTklOR2Agc3RhdGUuCgoNCgUEAAQAARIEmQEHDAo4CgYEAAQAAgASBJsBBBoaKCBO
b3Qgc3BlY2lmaWVkLiBUaGlzIHZhbHVlIGlzIG5vdCB1c2VkLgoKDwoHBAAEAAIAARIEmwEE
FQoPCgcEAAQAAgACEgSbARgZChoKBgQABAACARIEngEEEBoKIFN0b3BwZWQuCgoPCgcEAAQA
AgEBEgSeAQQLCg8KBwQABAACAQISBJ4BDg8KGgoGBAAEAAICEgShAQQQGgogTG9hZGluZy4K
Cg8KBwQABAACAgESBKEBBAsKDwoHBAAEAAICAhIEoQEODwoaCgYEAAQAAgMSBKQBBBAaCiBS
dW5uaW5nLgoKDwoHBAAEAAIDARIEpAEECwoPCgcEAAQAAgMCEgSkAQ4PCvkBCgQEAAIAEgSs
AQI+GuoBIE91dHB1dCBvbmx5LiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhpcyBhZ2Vu
dCBlbnZpcm9ubWVudC4KIFN1cHBvcnRlZCBmb3JtYXRzOgogLSBgcHJvamVjdHMvPFByb2pl
Y3QgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+YAogLSBgcHJvamVj
dHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24KIElEPi9hZ2VudC9lbnZpcm9u
bWVudHMvPEVudmlyb25tZW50IElEPmAKCg0KBQQAAgAFEgSsAQIICg0KBQQAAgABEgSsAQkN
Cg0KBQQAAgADEgSsARARCg0KBQQAAgAIEgSsARI9ChAKCAQAAgAInAgAEgSsARM8CqABCgQE
AAIBEgSwAQJCGpEBIE9wdGlvbmFsLiBUaGUgZGV2ZWxvcGVyLXByb3ZpZGVkIGRlc2NyaXB0
aW9uIGZvciB0aGlzIGVudmlyb25tZW50LgogVGhlIG1heGltdW0gbGVuZ3RoIGlzIDUwMCBj
aGFyYWN0ZXJzLiBJZiBleGNlZWRlZCwgdGhlIHJlcXVlc3QgaXMgcmVqZWN0ZWQuCgoNCgUE
AAIBBRIEsAECCAoNCgUEAAIBARIEsAEJFAoNCgUEAAIBAxIEsAEXGAoNCgUEAAIBCBIEsAEZ
QQoQCggEAAIBCJwIABIEsAEaQArnAQoEBAACAhIGtwECvAEEGtYBIE9wdGlvbmFsLiBUaGUg
YWdlbnQgdmVyc2lvbiBsb2FkZWQgaW50byB0aGlzIGVudmlyb25tZW50LgogU3VwcG9ydGVk
IGZvcm1hdHM6CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvdmVyc2lvbnMvPFZl
cnNpb24gSUQ+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRp
b24gSUQ+L2FnZW50L3ZlcnNpb25zLzxWZXJzaW9uCiBJRD5gCgoNCgUEAAICBRIEtwECCAoN
CgUEAAICARIEtwEJFgoNCgUEAAICAxIEtwEZGgoPCgUEAAICCBIGtwEbvAEDChAKCAQAAgII
nAgAEgS4AQQqChEKBwQAAgIInwgSBrkBBLsBBQqKAQoEBAACAxIEwAECPhp8IE91dHB1dCBv
bmx5LiBUaGUgc3RhdGUgb2YgdGhpcyBlbnZpcm9ubWVudC4gVGhpcyBmaWVsZCBpcyByZWFk
LW9ubHksIGkuZS4sCiBpdCBjYW5ub3QgYmUgc2V0IGJ5IGNyZWF0ZSBhbmQgdXBkYXRlIG1l
dGhvZHMuCgoNCgUEAAIDBhIEwAECBwoNCgUEAAIDARIEwAEIDQoNCgUEAAIDAxIEwAEQEQoN
CgUEAAIDCBIEwAESPQoQCggEAAIDCJwIABIEwAETPAqYAQoEBAACBBIGxAECxQEyGocBIE91
dHB1dCBvbmx5LiBUaGUgbGFzdCB1cGRhdGUgdGltZSBvZiB0aGlzIGVudmlyb25tZW50LiBU
aGlzIGZpZWxkIGlzCiByZWFkLW9ubHksIGkuZS4sIGl0IGNhbm5vdCBiZSBzZXQgYnkgY3Jl
YXRlIGFuZCB1cGRhdGUgbWV0aG9kcy4KCg0KBQQAAgQGEgTEAQIbCg0KBQQAAgQBEgTEARwn
Cg0KBQQAAgQDEgTEASorCg0KBQQAAgQIEgTFAQYxChAKCAQAAgQInAgAEgTFAQcwCkkKBAQA
AgUSBsgBAskBLxo5IE9wdGlvbmFsLiBUZXh0IHRvIHNwZWVjaCBzZXR0aW5ncyBmb3IgdGhp
cyBlbnZpcm9ubWVudC4KCg0KBQQAAgUGEgTIAQIWCg0KBQQAAgUBEgTIARcuCg0KBQQAAgUD
EgTIATEyCg0KBQQAAgUIEgTJAQYuChAKCAQAAgUInAgAEgTJAQctCk8KBAQAAgYSBMwBAkca
QSBPcHRpb25hbC4gVGhlIGZ1bGZpbGxtZW50IHNldHRpbmdzIHRvIHVzZSBmb3IgdGhpcyBl
bnZpcm9ubWVudC4KCg0KBQQAAgYGEgTMAQINCg0KBQQAAgYBEgTMAQ4ZCg0KBQQAAgYDEgTM
ARwdCg0KBQQAAgYIEgTMAR5GChAKCAQAAgYInAgAEgTMAR9FCl0KAgQBEgbQAQDlAQEaTyBJ
bnN0cnVjdHMgdGhlIHNwZWVjaCBzeW50aGVzaXplciBvbiBob3cgdG8gZ2VuZXJhdGUgdGhl
IG91dHB1dCBhdWRpbyBjb250ZW50LgoKCwoDBAEBEgTQAQgcCpgBCgQEAQIAEgTTAQJKGokB
IE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0ZXh0IHRvIHNwZWVjaCBpcyBlbmFibGVk
LiBFdmVuIHdoZW4gdGhpcyBmaWVsZAogaXMgZmFsc2UsIG90aGVyIHNldHRpbmdzIGluIHRo
aXMgcHJvdG8gYXJlIHN0aWxsIHJldGFpbmVkLgoKDQoFBAECAAUSBNMBAgYKDQoFBAECAAES
BNMBBxwKDQoFBAECAAMSBNMBHyAKDQoFBAECAAgSBNMBIUkKEAoIBAECAAicCAASBNMBIkgK
TAoEBAECARIG1gEC1wEvGjwgUmVxdWlyZWQuIEF1ZGlvIGVuY29kaW5nIG9mIHRoZSBzeW50
aGVzaXplZCBhdWRpbyBjb250ZW50LgoKDQoFBAECAQYSBNYBAhUKDQoFBAECAQESBNYBFisK
DQoFBAECAQMSBNYBLi8KDQoFBAECAQgSBNcBBi4KEAoIBAECAQicCAASBNcBBy0K9QIKBAQB
AgISBN4BAkca5gIgT3B0aW9uYWwuIFRoZSBzeW50aGVzaXMgc2FtcGxlIHJhdGUgKGluIGhl
cnR6KSBmb3IgdGhpcyBhdWRpby4gSWYgbm90CiBwcm92aWRlZCwgdGhlbiB0aGUgc3ludGhl
c2l6ZXIgd2lsbCB1c2UgdGhlIGRlZmF1bHQgc2FtcGxlIHJhdGUgYmFzZWQgb24KIHRoZSBh
dWRpbyBlbmNvZGluZy4gSWYgdGhpcyBpcyBkaWZmZXJlbnQgZnJvbSB0aGUgdm9pY2UncyBu
YXR1cmFsIHNhbXBsZQogcmF0ZSwgdGhlbiB0aGUgc3ludGhlc2l6ZXIgd2lsbCBob25vciB0
aGlzIHJlcXVlc3QgYnkgY29udmVydGluZyB0byB0aGUKIGRlc2lyZWQgc2FtcGxlIHJhdGUg
KHdoaWNoIG1pZ2h0IHJlc3VsdCBpbiB3b3JzZSBhdWRpbyBxdWFsaXR5KS4KCg0KBQQBAgIF
EgTeAQIHCg0KBQQBAgIBEgTeAQgZCg0KBQQBAgIDEgTeARwdCg0KBQQBAgIIEgTeAR5GChAK
CAQBAgIInAgAEgTeAR9FCsABCgQEAQIDEgbjAQLkAS8arwEgT3B0aW9uYWwuIENvbmZpZ3Vy
YXRpb24gb2YgaG93IHNwZWVjaCBzaG91bGQgYmUgc3ludGhlc2l6ZWQsIG1hcHBpbmcgZnJv
bQogbGFuZ3VhZ2UgKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2RvY3Mv
cmVmZXJlbmNlL2xhbmd1YWdlKSB0bwogU3ludGhlc2l6ZVNwZWVjaENvbmZpZy4KCg0KBQQB
AgMGEgTjAQIlCg0KBQQBAgMBEgTjASY/Cg0KBQQBAgMDEgTjAUJDCg0KBQQBAgMIEgTkAQYu
ChAKCAQBAgMInAgAEgTkAQctCogBCgIEAhIG6QEA+wEBGnogVGhlIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtFbnZpcm9ubWVudHMuTGlzdEVudmlyb25tZW50c11bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVudHMuTGlzdEVudmlyb25tZW50c10uCgoLCgME
AgESBOkBCB8KqAEKBAQCAgASBu4BAvMBBBqXASBSZXF1aXJlZC4gVGhlIGFnZW50IHRvIGxp
c3QgYWxsIGVudmlyb25tZW50cyBmcm9tLgogRm9ybWF0OgogLSBgcHJvamVjdHMvPFByb2pl
Y3QgSUQ+L2FnZW50YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9j
YXRpb24gSUQ+L2FnZW50YAoKDQoFBAICAAUSBO4BAggKDQoFBAICAAESBO4BCQ8KDQoFBAIC
AAMSBO4BEhMKDwoFBAICAAgSBu4BFPMBAwoQCggEAgIACJwIABIE7wEEKgoRCgcEAgIACJ8I
EgbwAQTyAQUKcwoEBAICARIE9wECPxplIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIg
b2YgaXRlbXMgdG8gcmV0dXJuIGluIGEgc2luZ2xlIHBhZ2UuIEJ5CiBkZWZhdWx0IDEwMCBh
bmQgYXQgbW9zdCAxMDAwLgoKDQoFBAICAQUSBPcBAgcKDQoFBAICAQESBPcBCBEKDQoFBAIC
AQMSBPcBFBUKDQoFBAICAQgSBPcBFj4KEAoIBAICAQicCAASBPcBFz0KWgoEBAICAhIE+gEC
QRpMIE9wdGlvbmFsLiBUaGUgbmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVybmVkIGZyb20g
YSBwcmV2aW91cyBsaXN0IHJlcXVlc3QuCgoNCgUEAgICBRIE+gECCAoNCgUEAgICARIE+gEJ
EwoNCgUEAgICAxIE+gEWFwoNCgUEAgICCBIE+gEYQAoQCggEAgICCJwIABIE+gEZPwqJAQoC
BAMSBv8BAIcCARp7IFRoZSByZXNwb25zZSBtZXNzYWdlIGZvcgogW0Vudmlyb25tZW50cy5M
aXN0RW52aXJvbm1lbnRzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkVudmly
b25tZW50cy5MaXN0RW52aXJvbm1lbnRzXS4KCgsKAwQDARIE/wEIIAqPAQoEBAMCABIEggIC
KBqAASBUaGUgbGlzdCBvZiBhZ2VudCBlbnZpcm9ubWVudHMuIFRoZXJlIHdpbGwgYmUgYSBt
YXhpbXVtIG51bWJlciBvZiBpdGVtcwogcmV0dXJuZWQgYmFzZWQgb24gdGhlIHBhZ2Vfc2l6
ZSBmaWVsZCBpbiB0aGUgcmVxdWVzdC4KCg0KBQQDAgAEEgSCAgIKCg0KBQQDAgAGEgSCAgsW
Cg0KBQQDAgABEgSCAhcjCg0KBQQDAgADEgSCAiYnCm8KBAQDAgESBIYCAh0aYSBUb2tlbiB0
byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJl
IGFyZSBubwogbW9yZSByZXN1bHRzIGluIHRoZSBsaXN0LgoKDQoFBAMCAQUSBIYCAggKDQoF
BAMCAQESBIYCCRgKDQoFBAMCAQMSBIYCGxwKhAEKAgQEEgaLAgCXAgEadiBUaGUgcmVxdWVz
dCBtZXNzYWdlIGZvcgogW0Vudmlyb25tZW50cy5HZXRFbnZpcm9ubWVudF1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVudHMuR2V0RW52aXJvbm1lbnRdLgoK
CwoDBAQBEgSLAggdCuYBCgQEBAIAEgaRAgKWAgQa1QEgUmVxdWlyZWQuIFRoZSBuYW1lIG9m
IHRoZSBlbnZpcm9ubWVudC4KIFN1cHBvcnRlZCBmb3JtYXRzOgogLSBgcHJvamVjdHMvPFBy
b2plY3QgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+YAogLSBgcHJv
amVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24KICAgSUQ+L2FnZW50L2Vu
dmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+YAoKDQoFBAQCAAUSBJECAggKDQoFBAQCAAES
BJECCQ0KDQoFBAQCAAMSBJECEBEKDwoFBAQCAAgSBpECEpYCAwoQCggEBAIACJwIABIEkgIE
KgoRCgcEBAIACJ8IEgaTAgSVAgUKigEKAgQFEgabAgCsAgEafCBUaGUgcmVxdWVzdCBtZXNz
YWdlIGZvcgogW0Vudmlyb25tZW50cy5DcmVhdGVFbnZpcm9ubWVudF1bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVudHMuQ3JlYXRlRW52aXJvbm1lbnRdLgoK
CwoDBAUBEgSbAgggCrIBCgQEBQIAEgagAgKlAgQaoQEgUmVxdWlyZWQuIFRoZSBhZ2VudCB0
byBjcmVhdGUgYW4gZW52aXJvbm1lbnQgZm9yLgogU3VwcG9ydGVkIGZvcm1hdHM6CiAtIGBw
cm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnRgCiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4v
bG9jYXRpb25zLzxMb2NhdGlvbiBJRD4vYWdlbnRgCgoNCgUEBQIABRIEoAICCAoNCgUEBQIA
ARIEoAIJDwoNCgUEBQIAAxIEoAISEwoPCgUEBQIACBIGoAIUpQIDChAKCAQFAgAInAgAEgSh
AgQqChEKBwQFAgAInwgSBqICBKQCBQo0CgQEBQIBEgSoAgJHGiYgUmVxdWlyZWQuIFRoZSBl
bnZpcm9ubWVudCB0byBjcmVhdGUuCgoNCgUEBQIBBhIEqAICDQoNCgUEBQIBARIEqAIOGQoN
CgUEBQIBAxIEqAIcHQoNCgUEBQIBCBIEqAIeRgoQCggEBQIBCJwIABIEqAIfRQo/CgQEBQIC
EgSrAgJFGjEgUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWQgb2YgdGhlIG5ldyBlbnZpcm9ubWVu
dC4KCg0KBQQFAgIFEgSrAgIICg0KBQQFAgIBEgSrAgkXCg0KBQQFAgIDEgSrAhobCg0KBQQF
AgIIEgSrAhxEChAKCAQFAgIInAgAEgSrAh1DCooBCgIEBhIGsAIAvgIBGnwgVGhlIHJlcXVl
c3QgbWVzc2FnZSBmb3IKIFtFbnZpcm9ubWVudHMuVXBkYXRlRW52aXJvbm1lbnRdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuRW52aXJvbm1lbnRzLlVwZGF0ZUVudmlyb25t
ZW50XS4KCgsKAwQGARIEsAIIIAo0CgQEBgIAEgSyAgJHGiYgUmVxdWlyZWQuIFRoZSBlbnZp
cm9ubWVudCB0byB1cGRhdGUuCgoNCgUEBgIABhIEsgICDQoNCgUEBgIAARIEsgIOGQoNCgUE
BgIAAxIEsgIcHQoNCgUEBgIACBIEsgIeRgoQCggEBgIACJwIABIEsgIfRQpJCgQEBgIBEga1
AgK2Ai8aOSBSZXF1aXJlZC4gVGhlIG1hc2sgdG8gY29udHJvbCB3aGljaCBmaWVsZHMgZ2V0
IHVwZGF0ZWQuCgoNCgUEBgIBBhIEtQICGwoNCgUEBgIBARIEtQIcJwoNCgUEBgIBAxIEtQIq
KwoNCgUEBgIBCBIEtgIGLgoQCggEBgIBCJwIABIEtgIHLQqyAgoEBAYCAhIGvAICvQIvGqEC
IE9wdGlvbmFsLiBUaGlzIGZpZWxkIGlzIHVzZWQgdG8gcHJldmVudCBhY2NpZGVudGFsIG92
ZXJ3cml0ZSBvZiB0aGUgZHJhZnQKIGVudmlyb25tZW50LCB3aGljaCBpcyBhbiBvcGVyYXRp
b24gdGhhdCBjYW5ub3QgYmUgdW5kb25lLiBUbyBjb25maXJtIHRoYXQKIHRoZSBjYWxsZXIg
ZGVzaXJlcyB0aGlzIG92ZXJ3cml0ZSwgdGhpcyBmaWVsZCBtdXN0IGJlIGV4cGxpY2l0bHkg
c2V0IHRvCiB0cnVlIHdoZW4gdXBkYXRpbmcgdGhlIGRyYWZ0IGVudmlyb25tZW50IChlbnZp
cm9ubWVudCBJRCA9IGAtYCkuCgoNCgUEBgICBRIEvAICBgoNCgUEBgICARIEvAIHLgoNCgUE
BgICAxIEvAIxMgoNCgUEBgICCBIEvQIGLgoQCggEBgICCJwIABIEvQIHLQqKAQoCBAcSBsIC
AM4CARp8IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRW52aXJvbm1lbnRzLkRlbGV0ZUVu
dmlyb25tZW50XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkVudmlyb25tZW50
cy5EZWxldGVFbnZpcm9ubWVudF0uCgoLCgMEBwESBMICCCAK5QEKBAQHAgASBsgCAs0CBBrU
ASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGVudmlyb25tZW50IHRvIGRlbGV0ZS4KIC8g
Rm9ybWF0OgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88
RW52aXJvbm1lbnQgSUQ+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88
TG9jYXRpb24KIElEPi9hZ2VudC9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50IElEPmAKCg0K
BQQHAgAFEgTIAgIICg0KBQQHAgABEgTIAgkNCg0KBQQHAgADEgTIAhARCg8KBQQHAgAIEgbI
AhLNAgMKEAoIBAcCAAicCAASBMkCBCoKEQoHBAcCAAifCBIGygIEzAIFCpMBCgIECBIG0gIA
5QIBGoQBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRW52aXJvbm1lbnRzLkdldEVudmly
b25tZW50SGlzdG9yeV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5FbnZpcm9u
bWVudHMuR2V0RW52aXJvbm1lbnRIaXN0b3J5XS4KCgsKAwQIARIE0gIIJAr+AQoEBAgCABIG
2AIC3QIEGu0BIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgZW52aXJvbm1lbnQgdG8gcmV0
cmlldmUgaGlzdG9yeSBmb3IuCiBTdXBwb3J0ZWQgZm9ybWF0czoKIC0gYHByb2plY3RzLzxQ
cm9qZWN0IElEPi9hZ2VudC9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50IElEPmAKIC0gYHBy
b2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uCiAgIElEPi9hZ2VudC9l
bnZpcm9ubWVudHMvPEVudmlyb25tZW50IElEPmAKCg0KBQQIAgAFEgTYAgIICg0KBQQIAgAB
EgTYAgkPCg0KBQQIAgADEgTYAhITCg8KBQQIAgAIEgbYAhTdAgMKEAoIBAgCAAicCAASBNkC
BCoKEQoHBAgCAAifCBIG2gIE3AIFCnMKBAQIAgESBOECAj8aZSBPcHRpb25hbC4gVGhlIG1h
eGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeQog
ZGVmYXVsdCAxMDAgYW5kIGF0IG1vc3QgMTAwMC4KCg0KBQQIAgEFEgThAgIHCg0KBQQIAgEB
EgThAggRCg0KBQQIAgEDEgThAhQVCg0KBQQIAgEIEgThAhY+ChAKCAQIAgEInAgAEgThAhc9
CloKBAQIAgISBOQCAkEaTCBPcHRpb25hbC4gVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSBy
ZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAgCAgUSBOQCAggK
DQoFBAgCAgESBOQCCRMKDQoFBAgCAgMSBOQCFhcKDQoFBAgCAggSBOQCGEAKEAoIBAgCAgic
CAASBOQCGT8KlAEKAgQJEgbpAgCEAwEahQEgVGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBb
RW52aXJvbm1lbnRzLkdldEVudmlyb25tZW50SGlzdG9yeV1bZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjJiZXRhMS5FbnZpcm9ubWVudHMuR2V0RW52aXJvbm1lbnRIaXN0b3J5XS4KCgsK
AwQJARIE6QIIGgo6CgQECQMAEgbrAgL0AgMaKiBSZXByZXNlbnRzIGFuIGVudmlyb25tZW50
IGhpc3RvcnkgZW50cnkuCgoNCgUECQMAARIE6wIKDwpPCgYECQMAAgASBO0CBB0aPyBUaGUg
YWdlbnQgdmVyc2lvbiBsb2FkZWQgaW50byB0aGlzIGVudmlyb25tZW50IGhpc3RvcnkgZW50
cnkuCgoPCgcECQMAAgAFEgTtAgQKCg8KBwQJAwACAAESBO0CCxgKDwoHBAkDAAIAAxIE7QIb
HApYCgYECQMAAgESBPACBBsaSCBUaGUgZGV2ZWxvcGVyLXByb3ZpZGVkIGRlc2NyaXB0aW9u
IGZvciB0aGlzIGVudmlyb25tZW50IGhpc3RvcnkgZW50cnkuCgoPCgcECQMAAgEFEgTwAgQK
Cg8KBwQJAwACAQESBPACCxYKDwoHBAkDAAIBAxIE8AIZGgpGCgYECQMAAgISBPMCBC4aNiBU
aGUgY3JlYXRpb24gdGltZSBvZiB0aGlzIGVudmlyb25tZW50IGhpc3RvcnkgZW50cnkuCgoP
CgcECQMAAgIGEgTzAgQdCg8KBwQJAwACAgESBPMCHikKDwoHBAkDAAICAxIE8wIsLQr8AQoE
BAkCABIE+wICQBrtASBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIGVudmlyb25tZW50
IHRoaXMgaGlzdG9yeSBpcyBmb3IuCiBTdXBwb3J0ZWQgZm9ybWF0czoKIC0gYHByb2plY3Rz
LzxQcm9qZWN0IElEPi9hZ2VudC9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50IElEPmAKIC0g
YHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uCiAgICBJRD4vYWdl
bnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD5gCgoNCgUECQIABRIE+wICCAoNCgUE
CQIAARIE+wIJDwoNCgUECQIAAxIE+wISEwoNCgUECQIACBIE+wIUPwoQCggECQIACJwIABIE
+wIVPgqcAQoEBAkCARIE/wICSRqNASBPdXRwdXQgb25seS4gVGhlIGxpc3Qgb2YgYWdlbnQg
ZW52aXJvbm1lbnRzLiBUaGVyZSB3aWxsIGJlIGEgbWF4aW11bSBudW1iZXIKIG9mIGl0ZW1z
IHJldHVybmVkIGJhc2VkIG9uIHRoZSBwYWdlX3NpemUgZmllbGQgaW4gdGhlIHJlcXVlc3Qu
CgoNCgUECQIBBBIE/wICCgoNCgUECQIBBhIE/wILEAoNCgUECQIBARIE/wIRGAoNCgUECQIB
AxIE/wIbHAoNCgUECQIBCBIE/wIdSAoQCggECQIBCJwIABIE/wIeRwp8CgQECQICEgSDAwJJ
Gm4gT3V0cHV0IG9ubHkuIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVz
dWx0cywgb3IgZW1wdHkgaWYgdGhlcmUKIGFyZSBubyBtb3JlIHJlc3VsdHMgaW4gdGhlIGxp
c3QuCgoNCgUECQICBRIEgwMCCAoNCgUECQICARIEgwMJGAoNCgUECQICAxIEgwMbHAoNCgUE
CQICCBIEgwMdSAoQCggECQICCJwIABIEgwMeR2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::Environment ===
    # Fields for Environment
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: agent_version Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dialogflow.v2beta1.Environment.State)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: text_to_speech_settings Type: 11 (.google.cloud.dialogflow.v2beta1.TextToSpeechSettings)
    # Field: fulfillment Type: 11 (.google.cloud.dialogflow.v2beta1.Fulfillment)

# Enum: Environment::State
our $Environment_STATE_UNSPECIFIED = 0;
our $Environment_STOPPED = 1;
our $Environment_LOADING = 2;
our $Environment_RUNNING = 3;

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::TextToSpeechSettings ===
    # Fields for TextToSpeechSettings
    # Field: enable_text_to_speech Type: 8 ()
    # Field: output_audio_encoding Type: 14 (.google.cloud.dialogflow.v2beta1.OutputAudioEncoding)
    # Field: sample_rate_hertz Type: 5 ()
    # Field: synthesize_speech_configs Type: 11 (.google.cloud.dialogflow.v2beta1.TextToSpeechSettings.SynthesizeSpeechConfigsEntry)

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsRequest ===
    # Fields for ListEnvironmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsResponse ===
    # Fields for ListEnvironmentsResponse
    # Field: environments Type: 11 (.google.cloud.dialogflow.v2beta1.Environment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::GetEnvironmentRequest ===
    # Fields for GetEnvironmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::CreateEnvironmentRequest ===
    # Fields for CreateEnvironmentRequest
    # Field: parent Type: 9 ()
    # Field: environment Type: 11 (.google.cloud.dialogflow.v2beta1.Environment)
    # Field: environment_id Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::UpdateEnvironmentRequest ===
    # Fields for UpdateEnvironmentRequest
    # Field: environment Type: 11 (.google.cloud.dialogflow.v2beta1.Environment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: allow_load_to_draft_and_discard_changes Type: 8 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::DeleteEnvironmentRequest ===
    # Fields for DeleteEnvironmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::GetEnvironmentHistoryRequest ===
    # Fields for GetEnvironmentHistoryRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::Environment::EnvironmentHistory ===
    # Fields for EnvironmentHistory
    # Field: parent Type: 9 ()
    # Field: entries Type: 11 (.google.cloud.dialogflow.v2beta1.EnvironmentHistory.Entry)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::V2beta1::Environment::EnvironmentsClient ===
package Google::Cloud::Dialogflow::V2beta1::Environment::EnvironmentsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::Environment::EnvironmentsClient

Client stub representing the remote C<Environments> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_environments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Environments',
        method         => 'ListEnvironments',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsResponse',
    });
}

sub get_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Environment::GetEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Environments',
        method         => 'GetEnvironment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Environment::Environment',
    });
}

sub create_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Environment::CreateEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Environments',
        method         => 'CreateEnvironment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Environment::Environment',
    });
}

sub update_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Environment::UpdateEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Environments',
        method         => 'UpdateEnvironment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Environment::Environment',
    });
}

sub delete_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Environment::DeleteEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Environments',
        method         => 'DeleteEnvironment',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_environment_history {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::Environment::GetEnvironmentHistoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.Environments',
        method         => 'GetEnvironmentHistory',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::Environment::EnvironmentHistory',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Environment - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/environment.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Environment;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Environment::Environment->new({
        name => $name,
        description => $description,
        agent_version => $agent_version,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Environment::Environment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/environment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::Environment

You can create multiple versions of your agent and publish them to separate
environments.

When you edit an agent, you are editing the draft agent. At any point, you
can save the draft agent as an agent version, which is an immutable snapshot
of your agent.

When you save the draft agent, it is published to the default environment.
When you create agent versions, you can publish them to custom environments.
You can create a variety of custom environments for:

- testing
- development
- production
- etc.

For more information, see the [versions and environments
guide](https://cloud.google.com/dialogflow/docs/agents-versions).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique identifier of this agent environment.
Supported formats:
- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
ID>/agent/environments/<Environment ID>`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The developer-provided description for this environment.
The maximum length is 500 characters. If exceeded, the request is rejected.

=item * C<< $msg->agent_version() >> / C<< $msg->agent_version($value) >>

Type: C<String>

Optional. The agent version loaded into this environment.
Supported formats:
- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
ID>`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::Environment::State>)

Output only. The state of this environment. This field is read-only, i.e.,
it cannot be set by create and update methods.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update time of this environment. This field is
read-only, i.e., it cannot be set by create and update methods.

=item * C<< $msg->text_to_speech_settings() >> / C<< $msg->text_to_speech_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Environment::TextToSpeechSettings>)

Optional. Text to speech settings for this environment.

=item * C<< $msg->fulfillment() >> / C<< $msg->fulfillment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment>)

Optional. The fulfillment settings to use for this environment.

=back

=head3 Enum: Environment::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STOPPED> => C<1>

=item * C<LOADING> => C<2>

=item * C<RUNNING> => C<3>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::TextToSpeechSettings

Instructs the speech synthesizer on how to generate the output audio content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_text_to_speech() >> / C<< $msg->enable_text_to_speech($value) >>

Type: C<Bool>

Optional. Indicates whether text to speech is enabled. Even when this field
is false, other settings in this proto are still retained.

=item * C<< $msg->output_audio_encoding() >> / C<< $msg->output_audio_encoding($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::OutputAudioEncoding>)

Required. Audio encoding of the synthesized audio content.

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

Optional. The synthesis sample rate (in hertz) for this audio. If not
provided, then the synthesizer will use the default sample rate based on
the audio encoding. If this is different from the voice's natural sample
rate, then the synthesizer will honor this request by converting to the
desired sample rate (which might result in worse audio quality).

=item * C<< $msg->synthesize_speech_configs() >> / C<< $msg->synthesize_speech_configs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Environment::TextToSpeechSettings::SynthesizeSpeechConfigsEntry>)

Optional. Configuration of how speech should be synthesized, mapping from
language (https://cloud.google.com/dialogflow/docs/reference/language) to
SynthesizeSpeechConfig.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsRequest

The request message for
[Environments.ListEnvironments][google.cloud.dialogflow.v2beta1.Environments.ListEnvironments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to list all environments from.
Format:
- `projects/<Project ID>/agent`
- `projects/<Project ID>/locations/<Location ID>/agent`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsResponse

The response message for
[Environments.ListEnvironments][google.cloud.dialogflow.v2beta1.Environments.ListEnvironments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->environments() >> / C<< $msg->environments($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Environment::Environment>)

The list of agent environments. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::GetEnvironmentRequest

The request message for
[Environments.GetEnvironment][google.cloud.dialogflow.v2beta1.Environments.GetEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the environment.
Supported formats:
- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>`

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::CreateEnvironmentRequest

The request message for
[Environments.CreateEnvironment][google.cloud.dialogflow.v2beta1.Environments.CreateEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to create an environment for.
Supported formats:
- `projects/<Project ID>/agent`
- `projects/<Project ID>/locations/<Location ID>/agent`

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Environment::Environment>)

Required. The environment to create.

=item * C<< $msg->environment_id() >> / C<< $msg->environment_id($value) >>

Type: C<String>

Required. The unique id of the new environment.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::UpdateEnvironmentRequest

The request message for
[Environments.UpdateEnvironment][google.cloud.dialogflow.v2beta1.Environments.UpdateEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Environment::Environment>)

Required. The environment to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated.

=item * C<< $msg->allow_load_to_draft_and_discard_changes() >> / C<< $msg->allow_load_to_draft_and_discard_changes($value) >>

Type: C<Bool>

Optional. This field is used to prevent accidental overwrite of the draft
environment, which is an operation that cannot be undone. To confirm that
the caller desires this overwrite, this field must be explicitly set to
true when updating the draft environment (environment ID = `-`).

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::DeleteEnvironmentRequest

The request message for
[Environments.DeleteEnvironment][google.cloud.dialogflow.v2beta1.Environments.DeleteEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the environment to delete.
/ Format:
- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
ID>/agent/environments/<Environment ID>`

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::GetEnvironmentHistoryRequest

The request message for
[Environments.GetEnvironmentHistory][google.cloud.dialogflow.v2beta1.Environments.GetEnvironmentHistory].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the environment to retrieve history for.
Supported formats:
- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Environment::EnvironmentHistory

The response message for
[Environments.GetEnvironmentHistory][google.cloud.dialogflow.v2beta1.Environments.GetEnvironmentHistory].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Output only. The name of the environment this history is for.
Supported formats:
- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
   ID>/agent/environments/<Environment ID>`

=item * C<< $msg->entries() >> / C<< $msg->entries($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Environment::EnvironmentHistory::Entry>)

Output only. The list of agent environments. There will be a maximum number
of items returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Output only. Token to retrieve the next page of results, or empty if there
are no more results in the list.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Environment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
