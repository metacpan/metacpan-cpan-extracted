package Google::Cloud::Dataproc::V1::AutoscalingPolicies;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGF0YXByb2MvdjEvYXV0b3NjYWxpbmdfcG9saWNpZXMucHJvdG8S
GGdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJh
dGlvbi5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvIqQHChFBdXRvc2NhbGlu
Z1BvbGljeRIOCgJpZBgBIAEoCVICaWQSFwoEbmFtZRgCIAEoCUID4EEDUgRuYW1lEmMKD2Jh
c2ljX2FsZ29yaXRobRgDIAEoCzIzLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5CYXNpY0F1
dG9zY2FsaW5nQWxnb3JpdGhtQgPgQQJIAFIOYmFzaWNBbGdvcml0aG0SaAoNd29ya2VyX2Nv
bmZpZxgEIAEoCzI+Lmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5JbnN0YW5jZUdyb3VwQXV0
b3NjYWxpbmdQb2xpY3lDb25maWdCA+BBAlIMd29ya2VyQ29uZmlnEnsKF3NlY29uZGFyeV93
b3JrZXJfY29uZmlnGAUgASgLMj4uZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkluc3RhbmNl
R3JvdXBBdXRvc2NhbGluZ1BvbGljeUNvbmZpZ0ID4EEBUhVzZWNvbmRhcnlXb3JrZXJDb25m
aWcSVAoGbGFiZWxzGAYgAygLMjcuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkF1dG9zY2Fs
aW5nUG9saWN5LkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxJfCgxjbHVzdGVyX3R5cGUYByAB
KA4yNy5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuQXV0b3NjYWxpbmdQb2xpY3kuQ2x1c3Rl
clR5cGVCA+BBAVILY2x1c3RlclR5cGUaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNr
ZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJJCgtDbHVzdGVyVHlwZRIcChhDTFVTVEVS
X1RZUEVfVU5TUEVDSUZJRUQQABIMCghTVEFOREFSRBABEg4KClpFUk9fU0NBTEUQAjrPAepB
ywEKKWRhdGFwcm9jLmdvb2dsZWFwaXMuY29tL0F1dG9zY2FsaW5nUG9saWN5ElBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXV0b3NjYWxpbmdQb2xpY2llcy97
YXV0b3NjYWxpbmdfcG9saWN5fRJMcHJvamVjdHMve3Byb2plY3R9L3JlZ2lvbnMve3JlZ2lv
bn0vYXV0b3NjYWxpbmdQb2xpY2llcy97YXV0b3NjYWxpbmdfcG9saWN5fUILCglhbGdvcml0
aG0izAEKGUJhc2ljQXV0b3NjYWxpbmdBbGdvcml0aG0SXAoLeWFybl9jb25maWcYASABKAsy
NC5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuQmFzaWNZYXJuQXV0b3NjYWxpbmdDb25maWdC
A+BBAkgAUgp5YXJuQ29uZmlnEkcKD2Nvb2xkb3duX3BlcmlvZBgCIAEoCzIZLmdvb2dsZS5w
cm90b2J1Zi5EdXJhdGlvbkID4EEBUg5jb29sZG93blBlcmlvZEIICgZjb25maWci7AIKGkJh
c2ljWWFybkF1dG9zY2FsaW5nQ29uZmlnEmIKHWdyYWNlZnVsX2RlY29tbWlzc2lvbl90aW1l
b3V0GAUgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQJSG2dyYWNlZnVsRGVj
b21taXNzaW9uVGltZW91dBIrCg9zY2FsZV91cF9mYWN0b3IYASABKAFCA+BBAlINc2NhbGVV
cEZhY3RvchIvChFzY2FsZV9kb3duX2ZhY3RvchgCIAEoAUID4EECUg9zY2FsZURvd25GYWN0
b3ISQwocc2NhbGVfdXBfbWluX3dvcmtlcl9mcmFjdGlvbhgDIAEoAUID4EEBUhhzY2FsZVVw
TWluV29ya2VyRnJhY3Rpb24SRwoec2NhbGVfZG93bl9taW5fd29ya2VyX2ZyYWN0aW9uGAQg
ASgBQgPgQQFSGnNjYWxlRG93bk1pbldvcmtlckZyYWN0aW9uIpcBCiRJbnN0YW5jZUdyb3Vw
QXV0b3NjYWxpbmdQb2xpY3lDb25maWcSKAoNbWluX2luc3RhbmNlcxgBIAEoBUID4EEBUgxt
aW5JbnN0YW5jZXMSKAoNbWF4X2luc3RhbmNlcxgCIAEoBUID4EECUgxtYXhJbnN0YW5jZXMS
GwoGd2VpZ2h0GAMgASgFQgPgQQFSBndlaWdodCK1AQoeQ3JlYXRlQXV0b3NjYWxpbmdQb2xp
Y3lSZXF1ZXN0EkkKBnBhcmVudBgBIAEoCUIx4EEC+kErEilkYXRhcHJvYy5nb29nbGVhcGlz
LmNvbS9BdXRvc2NhbGluZ1BvbGljeVIGcGFyZW50EkgKBnBvbGljeRgCIAEoCzIrLmdvb2ds
ZS5jbG91ZC5kYXRhcHJvYy52MS5BdXRvc2NhbGluZ1BvbGljeUID4EECUgZwb2xpY3kiZAob
R2V0QXV0b3NjYWxpbmdQb2xpY3lSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopZGF0
YXByb2MuZ29vZ2xlYXBpcy5jb20vQXV0b3NjYWxpbmdQb2xpY3lSBG5hbWUiagoeVXBkYXRl
QXV0b3NjYWxpbmdQb2xpY3lSZXF1ZXN0EkgKBnBvbGljeRgBIAEoCzIrLmdvb2dsZS5jbG91
ZC5kYXRhcHJvYy52MS5BdXRvc2NhbGluZ1BvbGljeUID4EECUgZwb2xpY3kiZwoeRGVsZXRl
QXV0b3NjYWxpbmdQb2xpY3lSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopZGF0YXBy
b2MuZ29vZ2xlYXBpcy5jb20vQXV0b3NjYWxpbmdQb2xpY3lSBG5hbWUisQEKHkxpc3RBdXRv
c2NhbGluZ1BvbGljaWVzUmVxdWVzdBJJCgZwYXJlbnQYASABKAlCMeBBAvpBKxIpZGF0YXBy
b2MuZ29vZ2xlYXBpcy5jb20vQXV0b3NjYWxpbmdQb2xpY3lSBnBhcmVudBIgCglwYWdlX3Np
emUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdl
VG9rZW4inAEKH0xpc3RBdXRvc2NhbGluZ1BvbGljaWVzUmVzcG9uc2USTAoIcG9saWNpZXMY
ASADKAsyKy5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuQXV0b3NjYWxpbmdQb2xpY3lCA+BB
A1IIcG9saWNpZXMSKwoPbmV4dF9wYWdlX3Rva2VuGAIgASgJQgPgQQNSDW5leHRQYWdlVG9r
ZW4yrgsKGEF1dG9zY2FsaW5nUG9saWN5U2VydmljZRKcAgoXQ3JlYXRlQXV0b3NjYWxpbmdQ
b2xpY3kSOC5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuQ3JlYXRlQXV0b3NjYWxpbmdQb2xp
Y3lSZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkF1dG9zY2FsaW5nUG9saWN5
IpkBgtPkkwKCASI3L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vYXV0b3Nj
YWxpbmdQb2xpY2llczoGcG9saWN5Wj8iNS92MS97cGFyZW50PXByb2plY3RzLyovcmVnaW9u
cy8qfS9hdXRvc2NhbGluZ1BvbGljaWVzOgZwb2xpY3naQQ1wYXJlbnQscG9saWN5EqMCChdV
cGRhdGVBdXRvc2NhbGluZ1BvbGljeRI4Lmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5VcGRh
dGVBdXRvc2NhbGluZ1BvbGljeVJlcXVlc3QaKy5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEu
QXV0b3NjYWxpbmdQb2xpY3kioAGC0+STApABGj4vdjEve3BvbGljeS5uYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovYXV0b3NjYWxpbmdQb2xpY2llcy8qfToGcG9saWN5WkYaPC92MS97
cG9saWN5Lm5hbWU9cHJvamVjdHMvKi9yZWdpb25zLyovYXV0b3NjYWxpbmdQb2xpY2llcy8q
fToGcG9saWN52kEGcG9saWN5EvsBChRHZXRBdXRvc2NhbGluZ1BvbGljeRI1Lmdvb2dsZS5j
bG91ZC5kYXRhcHJvYy52MS5HZXRBdXRvc2NhbGluZ1BvbGljeVJlcXVlc3QaKy5nb29nbGUu
Y2xvdWQuZGF0YXByb2MudjEuQXV0b3NjYWxpbmdQb2xpY3kif4LT5JMCchI3L3YxL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovYXV0b3NjYWxpbmdQb2xpY2llcy8qfVo3EjUvdjEv
e25hbWU9cHJvamVjdHMvKi9yZWdpb25zLyovYXV0b3NjYWxpbmdQb2xpY2llcy8qfdpBBG5h
bWUSkgIKF0xpc3RBdXRvc2NhbGluZ1BvbGljaWVzEjguZ29vZ2xlLmNsb3VkLmRhdGFwcm9j
LnYxLkxpc3RBdXRvc2NhbGluZ1BvbGljaWVzUmVxdWVzdBo5Lmdvb2dsZS5jbG91ZC5kYXRh
cHJvYy52MS5MaXN0QXV0b3NjYWxpbmdQb2xpY2llc1Jlc3BvbnNlIoEBgtPkkwJyEjcvdjEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9hdXRvc2NhbGluZ1BvbGljaWVzWjcS
NS92MS97cGFyZW50PXByb2plY3RzLyovcmVnaW9ucy8qfS9hdXRvc2NhbGluZ1BvbGljaWVz
2kEGcGFyZW50EuwBChdEZWxldGVBdXRvc2NhbGluZ1BvbGljeRI4Lmdvb2dsZS5jbG91ZC5k
YXRhcHJvYy52MS5EZWxldGVBdXRvc2NhbGluZ1BvbGljeVJlcXVlc3QaFi5nb29nbGUucHJv
dG9idWYuRW1wdHkif4LT5JMCcio3L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
YXV0b3NjYWxpbmdQb2xpY2llcy8qfVo3KjUvdjEve25hbWU9cHJvamVjdHMvKi9yZWdpb25z
LyovYXV0b3NjYWxpbmdQb2xpY2llcy8qfdpBBG5hbWUaS8pBF2RhdGFwcm9jLmdvb2dsZWFw
aXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9y
bUK/AQocY29tLmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MUIYQXV0b3NjYWxpbmdQb2xpY2ll
c1Byb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZGF0YXByb2MvdjIvYXBpdjEvZGF0YXBy
b2NwYjtkYXRhcHJvY3Bi6kFFCh5kYXRhcHJvYy5nb29nbGVhcGlzLmNvbS9SZWdpb24SI3By
b2plY3RzL3twcm9qZWN0fS9yZWdpb25zL3tyZWdpb259Sp9qCgcSBQ4AjgMBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACYKCQoCAwES
AxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAKAoJCgIDBRIDFwAlCggKAQgS
AxkAUgoJCgIICxIDGQBSCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAOQoJCgIICBID
GwA5CggKAQgSAxwANQoJCgIIARIDHAA1CgkKAQgSBB0AIAIKDAoECJ0IABIEHQAgAgpXCgIG
ABIEJABsARpLIFRoZSBBUEkgaW50ZXJmYWNlIGZvciBtYW5hZ2luZyBhdXRvc2NhbGluZyBw
b2xpY2llcyBpbiB0aGUKIERhdGFwcm9jIEFQSS4KCgoKAwYAARIDJAggCgoKAwYAAxIDJQI/
CgwKBQYAA5kIEgMlAj8KCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3Ci8KBAYAAgASBCoC
NQMaISBDcmVhdGVzIG5ldyBhdXRvc2NhbGluZyBwb2xpY3kuCgoMCgUGAAIAARIDKgYdCgwK
BQYAAgACEgMqHjwKDAoFBgACAAMSAysPIAoNCgUGAAIABBIELAQzBgoRCgkGAAIABLDKvCIS
BCwEMwYKDAoFBgACAAQSAzQEOwoPCggGAAIABJsIABIDNAQ7CogBCgQGAAIBEgQ7AkYDGnog
VXBkYXRlcyAocmVwbGFjZXMpIGF1dG9zY2FsaW5nIHBvbGljeS4KCiBEaXNhYmxlZCBjaGVj
ayBmb3IgdXBkYXRlX21hc2ssIGJlY2F1c2UgYWxsIHVwZGF0ZXMgd2lsbCBiZSBmdWxsCiBy
ZXBsYWNlbWVudHMuCgoMCgUGAAIBARIDOwYdCgwKBQYAAgECEgM7HjwKDAoFBgACAQMSAzwP
IAoNCgUGAAIBBBIEPQREBgoRCgkGAAIBBLDKvCISBD0ERAYKDAoFBgACAQQSA0UENAoPCggG
AAIBBJsIABIDRQQ0Ci0KBAYAAgISBEkCUgMaHyBSZXRyaWV2ZXMgYXV0b3NjYWxpbmcgcG9s
aWN5LgoKDAoFBgACAgESA0kGGgoMCgUGAAICAhIDSRs2CgwKBQYAAgIDEgNKDyAKDQoFBgAC
AgQSBEsEUAYKEQoJBgACAgSwyrwiEgRLBFAGCgwKBQYAAgIEEgNRBDIKDwoIBgACAgSbCAAS
A1EEMgo6CgQGAAIDEgRVAl4DGiwgTGlzdHMgYXV0b3NjYWxpbmcgcG9saWNpZXMgaW4gdGhl
IHByb2plY3QuCgoMCgUGAAIDARIDVQYdCgwKBQYAAgMCEgNVHjwKDAoFBgACAwMSA1YPLgoN
CgUGAAIDBBIEVwRcBgoRCgkGAAIDBLDKvCISBFcEXAYKDAoFBgACAwQSA10ENAoPCggGAAID
BJsIABIDXQQ0CoYBCgQGAAIEEgRiAmsDGnggRGVsZXRlcyBhbiBhdXRvc2NhbGluZyBwb2xp
Y3kuIEl0IGlzIGFuIGVycm9yIHRvIGRlbGV0ZSBhbiBhdXRvc2NhbGluZwogcG9saWN5IHRo
YXQgaXMgaW4gdXNlIGJ5IG9uZSBvciBtb3JlIGNsdXN0ZXJzLgoKDAoFBgACBAESA2IGHQoM
CgUGAAIEAhIDYh48CgwKBQYAAgQDEgNjDyQKDQoFBgACBAQSBGQEaQYKEQoJBgACBASwyrwi
EgRkBGkGCgwKBQYAAgQEEgNqBDIKDwoIBgACBASbCAASA2oEMgpPCgIEABIFbwCyAQEaQiBE
ZXNjcmliZXMgYW4gYXV0b3NjYWxpbmcgcG9saWN5IGZvciBEYXRhcHJvYyBjbHVzdGVyIGF1
dG9zY2FsZXIuCgoKCgMEAAESA28IGQoLCgMEAAcSBHACdAQKDQoFBAAHnQgSBHACdAQKYQoE
BAAEABIFeAKCAQMaUiBUaGUgdHlwZSBvZiB0aGUgY2x1c3RlcnMgZm9yIHdoaWNoIHRoaXMg
YXV0b3NjYWxpbmcgcG9saWN5IGlzIHRvIGJlCiBjb25maWd1cmVkLgoKDAoFBAAEAAESA3gH
EgoZCgYEAAQAAgASA3oEIRoKIE5vdCBzZXQuCgoOCgcEAAQAAgABEgN6BBwKDgoHBAAEAAIA
AhIDeh8gClEKBgQABAACARIDfQQRGkIgU3RhbmRhcmQgZGF0YXByb2MgY2x1c3RlciB3aXRo
IGEgbWluaW11bSBvZiB0d28gcHJpbWFyeSB3b3JrZXJzLgoKDgoHBAAEAAIBARIDfQQMCg4K
BwQABAACAQISA30PEApyCgYEAAQAAgISBIEBBBMaYiBDbHVzdGVycyB0aGF0IGNhbiB1c2Ug
b25seSBzZWNvbmRhcnkgd29ya2VycyBhbmQgYmUgc2NhbGVkIGRvd24gdG8gemVybwogc2Vj
b25kYXJ5IHdvcmtlciBub2Rlcy4KCg8KBwQABAACAgESBIEBBA4KDwoHBAAEAAICAhIEgQER
EgroAQoEBAACABIEigECEBrZASBSZXF1aXJlZC4gVGhlIHBvbGljeSBpZC4KCiBUaGUgaWQg
bXVzdCBjb250YWluIG9ubHkgbGV0dGVycyAoYS16LCBBLVopLCBudW1iZXJzICgwLTkpLAog
dW5kZXJzY29yZXMgKF8pLCBhbmQgaHlwaGVucyAoLSkuIENhbm5vdCBiZWdpbiBvciBlbmQg
d2l0aCB1bmRlcnNjb3JlCiBvciBoeXBoZW4uIE11c3QgY29uc2lzdCBvZiBiZXR3ZWVuIDMg
YW5kIDUwIGNoYXJhY3RlcnMuCgoKDQoFBAACAAUSBIoBAggKDQoFBAACAAESBIoBCQsKDQoF
BAACAAMSBIoBDg8KigQKBAQAAgESBJYBAj4a+wMgT3V0cHV0IG9ubHkuIFRoZSAicmVzb3Vy
Y2UgbmFtZSIgb2YgdGhlIGF1dG9zY2FsaW5nIHBvbGljeSwgYXMgZGVzY3JpYmVkCiBpbiBo
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMuCgog
KiBGb3IgYHByb2plY3RzLnJlZ2lvbnMuYXV0b3NjYWxpbmdQb2xpY2llc2AsIHRoZSByZXNv
dXJjZSBuYW1lIG9mIHRoZQogICBwb2xpY3kgaGFzIHRoZSBmb2xsb3dpbmcgZm9ybWF0Ogog
ICBgcHJvamVjdHMve3Byb2plY3RfaWR9L3JlZ2lvbnMve3JlZ2lvbn0vYXV0b3NjYWxpbmdQ
b2xpY2llcy97cG9saWN5X2lkfWAKCiAqIEZvciBgcHJvamVjdHMubG9jYXRpb25zLmF1dG9z
Y2FsaW5nUG9saWNpZXNgLCB0aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUKICAgcG9saWN5IGhh
cyB0aGUgZm9sbG93aW5nIGZvcm1hdDoKICAgYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9hdXRvc2NhbGluZ1BvbGljaWVzL3twb2xpY3lfaWR9YAoKDQoF
BAACAQUSBJYBAggKDQoFBAACAQESBJYBCQ0KDQoFBAACAQMSBJYBEBEKDQoFBAACAQgSBJYB
Ej0KEAoIBAACAQicCAASBJYBEzwKMwoEBAAIABIGmQECnAEDGiMgQXV0b3NjYWxpbmcgYWxn
b3JpdGhtIGZvciBwb2xpY3kuCgoNCgUEAAgAARIEmQEIEQoOCgQEAAICEgaaAQSbATEKDQoF
BAACAgYSBJoBBB0KDQoFBAACAgESBJoBHi0KDQoFBAACAgMSBJoBMDEKDQoFBAACAggSBJsB
CDAKEAoIBAACAgicCAASBJsBCS8KWgoEBAACAxIGnwECoAEvGkogUmVxdWlyZWQuIERlc2Ny
aWJlcyBob3cgdGhlIGF1dG9zY2FsZXIgd2lsbCBvcGVyYXRlIGZvciBwcmltYXJ5IHdvcmtl
cnMuCgoNCgUEAAIDBhIEnwECJgoNCgUEAAIDARIEnwEnNAoNCgUEAAIDAxIEnwE3OAoNCgUE
AAIDCBIEoAEGLgoQCggEAAIDCJwIABIEoAEHLQpcCgQEAAIEEgajAQKkAS8aTCBPcHRpb25h
bC4gRGVzY3JpYmVzIGhvdyB0aGUgYXV0b3NjYWxlciB3aWxsIG9wZXJhdGUgZm9yIHNlY29u
ZGFyeSB3b3JrZXJzLgoKDQoFBAACBAYSBKMBAiYKDQoFBAACBAESBKMBJz4KDQoFBAACBAMS
BKMBQUIKDQoFBAACBAgSBKQBBi4KEAoIBAACBAicCAASBKQBBy0KqAMKBAQAAgUSBK0BAkoa
mQMgT3B0aW9uYWwuIFRoZSBsYWJlbHMgdG8gYXNzb2NpYXRlIHdpdGggdGhpcyBhdXRvc2Nh
bGluZyBwb2xpY3kuCiBMYWJlbCAqKmtleXMqKiBtdXN0IGNvbnRhaW4gMSB0byA2MyBjaGFy
YWN0ZXJzLCBhbmQgbXVzdCBjb25mb3JtIHRvCiBbUkZDIDEwMzVdKGh0dHBzOi8vd3d3Lmll
dGYub3JnL3JmYy9yZmMxMDM1LnR4dCkuCiBMYWJlbCAqKnZhbHVlcyoqIG1heSBiZSBlbXB0
eSwgYnV0LCBpZiBwcmVzZW50LCBtdXN0IGNvbnRhaW4gMSB0byA2MwogY2hhcmFjdGVycywg
YW5kIG11c3QgY29uZm9ybSB0byBbUkZDCiAxMDM1XShodHRwczovL3d3dy5pZXRmLm9yZy9y
ZmMvcmZjMTAzNS50eHQpLiBObyBtb3JlIHRoYW4gMzIgbGFiZWxzIGNhbiBiZQogYXNzb2Np
YXRlZCB3aXRoIGFuIGF1dG9zY2FsaW5nIHBvbGljeS4KCg0KBQQAAgUGEgStAQIVCg0KBQQA
AgUBEgStARYcCg0KBQQAAgUDEgStAR8gCg0KBQQAAgUIEgStASFJChAKCAQAAgUInAgAEgSt
ASJICmoKBAQAAgYSBLEBAkgaXCBPcHRpb25hbC4gVGhlIHR5cGUgb2YgdGhlIGNsdXN0ZXJz
IGZvciB3aGljaCB0aGlzIGF1dG9zY2FsaW5nIHBvbGljeSBpcyB0bwogYmUgY29uZmlndXJl
ZC4KCg0KBQQAAgYGEgSxAQINCg0KBQQAAgYBEgSxAQ4aCg0KBQQAAgYDEgSxAR0eCg0KBQQA
AgYIEgSxAR9HChAKCAQAAgYInAgAEgSxASBGCjAKAgQBEga1AQDCAQEaIiBCYXNpYyBhbGdv
cml0aG0gZm9yIGF1dG9zY2FsaW5nLgoKCwoDBAEBEgS1AQghCg4KBAQBCAASBrYBAroBAwoN
CgUEAQgAARIEtgEIDgo7CgQEAQIAEga4AQS5ATEaKyBSZXF1aXJlZC4gWUFSTiBhdXRvc2Nh
bGluZyBjb25maWd1cmF0aW9uLgoKDQoFBAECAAYSBLgBBB4KDQoFBAECAAESBLgBHyoKDQoF
BAECAAMSBLgBLS4KDQoFBAECAAgSBLkBCDAKEAoIBAECAAicCAASBLkBCS8KuQEKBAQBAgES
BsABAsEBLxqoASBPcHRpb25hbC4gRHVyYXRpb24gYmV0d2VlbiBzY2FsaW5nIGV2ZW50cy4g
QSBzY2FsaW5nIHBlcmlvZCBzdGFydHMgYWZ0ZXIKIHRoZSB1cGRhdGUgb3BlcmF0aW9uIGZy
b20gdGhlIHByZXZpb3VzIGV2ZW50IGhhcyBjb21wbGV0ZWQuCgogQm91bmRzOiBbMm0sIDFk
XS4gRGVmYXVsdDogMm0uCgoNCgUEAQIBBhIEwAECGgoNCgUEAQIBARIEwAEbKgoNCgUEAQIB
AxIEwAEtLgoNCgUEAQIBCBIEwQEGLgoQCggEAQIBCJwIABIEwQEHLQo6CgIEAhIGxQEA+gEB
GiwgQmFzaWMgYXV0b3NjYWxpbmcgY29uZmlndXJhdGlvbnMgZm9yIFlBUk4uCgoLCgMEAgES
BMUBCCIKlgIKBAQCAgASBswBAs0BLxqFAiBSZXF1aXJlZC4gVGltZW91dCBmb3IgWUFSTiBn
cmFjZWZ1bCBkZWNvbW1pc3Npb25pbmcgb2YgTm9kZSBNYW5hZ2Vycy4KIFNwZWNpZmllcyB0
aGUgZHVyYXRpb24gdG8gd2FpdCBmb3Igam9icyB0byBjb21wbGV0ZSBiZWZvcmUgZm9yY2Vm
dWxseQogcmVtb3Zpbmcgd29ya2VycyAoYW5kIHBvdGVudGlhbGx5IGludGVycnVwdGluZyBq
b2JzKS4gT25seSBhcHBsaWNhYmxlIHRvCiBkb3duc2NhbGluZyBvcGVyYXRpb25zLgoKIEJv
dW5kczogWzBzLCAxZF0uCgoNCgUEAgIABhIEzAECGgoNCgUEAgIAARIEzAEbOAoNCgUEAgIA
AxIEzAE7PAoNCgUEAgIACBIEzQEGLgoQCggEAgIACJwIABIEzQEHLQqlBAoEBAICARIE2QEC
RhqWBCBSZXF1aXJlZC4gRnJhY3Rpb24gb2YgYXZlcmFnZSBZQVJOIHBlbmRpbmcgbWVtb3J5
IGluIHRoZSBsYXN0IGNvb2xkb3duCiBwZXJpb2QgZm9yIHdoaWNoIHRvIGFkZCB3b3JrZXJz
LiBBIHNjYWxlLXVwIGZhY3RvciBvZiAxLjAgd2lsbCByZXN1bHQgaW4KIHNjYWxpbmcgdXAg
c28gdGhhdCB0aGVyZSBpcyBubyBwZW5kaW5nIG1lbW9yeSByZW1haW5pbmcgYWZ0ZXIgdGhl
IHVwZGF0ZQogKG1vcmUgYWdncmVzc2l2ZSBzY2FsaW5nKS4gQSBzY2FsZS11cCBmYWN0b3Ig
Y2xvc2VyIHRvIDAgd2lsbCByZXN1bHQgaW4gYQogc21hbGxlciBtYWduaXR1ZGUgb2Ygc2Nh
bGluZyB1cCAobGVzcyBhZ2dyZXNzaXZlIHNjYWxpbmcpLiBTZWUgW0hvdwogYXV0b3NjYWxp
bmcKIHdvcmtzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGF0YXByb2MvZG9jcy9jb25j
ZXB0cy9jb25maWd1cmluZy1jbHVzdGVycy9hdXRvc2NhbGluZyNob3dfYXV0b3NjYWxpbmdf
d29ya3MpCiBmb3IgbW9yZSBpbmZvcm1hdGlvbi4KCiBCb3VuZHM6IFswLjAsIDEuMF0uCgoN
CgUEAgIBBRIE2QECCAoNCgUEAgIBARIE2QEJGAoNCgUEAgIBAxIE2QEbHAoNCgUEAgIBCBIE
2QEdRQoQCggEAgIBCJwIABIE2QEeRAqsBAoEBAICAhIE5QECSBqdBCBSZXF1aXJlZC4gRnJh
Y3Rpb24gb2YgYXZlcmFnZSBZQVJOIHBlbmRpbmcgbWVtb3J5IGluIHRoZSBsYXN0IGNvb2xk
b3duCiBwZXJpb2QgZm9yIHdoaWNoIHRvIHJlbW92ZSB3b3JrZXJzLiBBIHNjYWxlLWRvd24g
ZmFjdG9yIG9mIDEgd2lsbCByZXN1bHQgaW4KIHNjYWxpbmcgZG93biBzbyB0aGF0IHRoZXJl
IGlzIG5vIGF2YWlsYWJsZSBtZW1vcnkgcmVtYWluaW5nIGFmdGVyIHRoZQogdXBkYXRlICht
b3JlIGFnZ3Jlc3NpdmUgc2NhbGluZykuIEEgc2NhbGUtZG93biBmYWN0b3Igb2YgMCBkaXNh
YmxlcwogcmVtb3Zpbmcgd29ya2Vycywgd2hpY2ggY2FuIGJlIGJlbmVmaWNpYWwgZm9yIGF1
dG9zY2FsaW5nIGEgc2luZ2xlIGpvYi4KIFNlZSBbSG93IGF1dG9zY2FsaW5nCiB3b3Jrc10o
aHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RhdGFwcm9jL2RvY3MvY29uY2VwdHMvY29uZmln
dXJpbmctY2x1c3RlcnMvYXV0b3NjYWxpbmcjaG93X2F1dG9zY2FsaW5nX3dvcmtzKQogZm9y
IG1vcmUgaW5mb3JtYXRpb24uCgogQm91bmRzOiBbMC4wLCAxLjBdLgoKDQoFBAICAgUSBOUB
AggKDQoFBAICAgESBOUBCRoKDQoFBAICAgMSBOUBHR4KDQoFBAICAggSBOUBH0cKEAoIBAIC
AgicCAASBOUBIEYK/AIKBAQCAgMSBu4BAu8BLxrrAiBPcHRpb25hbC4gTWluaW11bSBzY2Fs
ZS11cCB0aHJlc2hvbGQgYXMgYSBmcmFjdGlvbiBvZiB0b3RhbCBjbHVzdGVyIHNpemUKIGJl
Zm9yZSBzY2FsaW5nIG9jY3Vycy4gRm9yIGV4YW1wbGUsIGluIGEgMjAtd29ya2VyIGNsdXN0
ZXIsIGEgdGhyZXNob2xkIG9mCiAwLjEgbWVhbnMgdGhlIGF1dG9zY2FsZXIgbXVzdCByZWNv
bW1lbmQgYXQgbGVhc3QgYSAyLXdvcmtlciBzY2FsZS11cCBmb3IKIHRoZSBjbHVzdGVyIHRv
IHNjYWxlLiBBIHRocmVzaG9sZCBvZiAwIG1lYW5zIHRoZSBhdXRvc2NhbGVyIHdpbGwgc2Nh
bGUgdXAKIG9uIGFueSByZWNvbW1lbmRlZCBjaGFuZ2UuCgogQm91bmRzOiBbMC4wLCAxLjBd
LiBEZWZhdWx0OiAwLjAuCgoNCgUEAgIDBRIE7gECCAoNCgUEAgIDARIE7gEJJQoNCgUEAgID
AxIE7gEoKQoNCgUEAgIDCBIE7wEGLgoQCggEAgIDCJwIABIE7wEHLQqCAwoEBAICBBIG+AEC
+QEvGvECIE9wdGlvbmFsLiBNaW5pbXVtIHNjYWxlLWRvd24gdGhyZXNob2xkIGFzIGEgZnJh
Y3Rpb24gb2YgdG90YWwgY2x1c3RlciBzaXplCiBiZWZvcmUgc2NhbGluZyBvY2N1cnMuIEZv
ciBleGFtcGxlLCBpbiBhIDIwLXdvcmtlciBjbHVzdGVyLCBhIHRocmVzaG9sZCBvZgogMC4x
IG1lYW5zIHRoZSBhdXRvc2NhbGVyIG11c3QgcmVjb21tZW5kIGF0IGxlYXN0IGEgMiB3b3Jr
ZXIgc2NhbGUtZG93biBmb3IKIHRoZSBjbHVzdGVyIHRvIHNjYWxlLiBBIHRocmVzaG9sZCBv
ZiAwIG1lYW5zIHRoZSBhdXRvc2NhbGVyIHdpbGwgc2NhbGUgZG93bgogb24gYW55IHJlY29t
bWVuZGVkIGNoYW5nZS4KCiBCb3VuZHM6IFswLjAsIDEuMF0uIERlZmF1bHQ6IDAuMC4KCg0K
BQQCAgQFEgT4AQIICg0KBQQCAgQBEgT4AQknCg0KBQQCAgQDEgT4ASorCg0KBQQCAgQIEgT5
AQYuChAKCAQCAgQInAgAEgT5AQctCnkKAgQDEgb+AQCgAgEaayBDb25maWd1cmF0aW9uIGZv
ciB0aGUgc2l6ZSBib3VuZHMgb2YgYW4gaW5zdGFuY2UgZ3JvdXAsIGluY2x1ZGluZyBpdHMK
IHByb3BvcnRpb25hbCBzaXplIHRvIG90aGVyIGdyb3Vwcy4KCgsKAwQDARIE/gEILAq/AQoE
BAMCABIEgwICQxqwASBPcHRpb25hbC4gTWluaW11bSBudW1iZXIgb2YgaW5zdGFuY2VzIGZv
ciB0aGlzIGdyb3VwLgoKIFByaW1hcnkgd29ya2VycyAtIEJvdW5kczogWzIsIG1heF9pbnN0
YW5jZXNdLiBEZWZhdWx0OiAyLgogU2Vjb25kYXJ5IHdvcmtlcnMgLSBCb3VuZHM6IFswLCBt
YXhfaW5zdGFuY2VzXS4gRGVmYXVsdDogMC4KCg0KBQQDAgAFEgSDAgIHCg0KBQQDAgABEgSD
AggVCg0KBQQDAgADEgSDAhgZCg0KBQQDAgAIEgSDAhpCChAKCAQDAgAInAgAEgSDAhtBCtoC
CgQEAwIBEgSLAgJDGssCIFJlcXVpcmVkLiBNYXhpbXVtIG51bWJlciBvZiBpbnN0YW5jZXMg
Zm9yIHRoaXMgZ3JvdXAuIFJlcXVpcmVkIGZvciBwcmltYXJ5CiB3b3JrZXJzLiBOb3RlIHRo
YXQgYnkgZGVmYXVsdCwgY2x1c3RlcnMgd2lsbCBub3QgdXNlIHNlY29uZGFyeSB3b3JrZXJz
LgogUmVxdWlyZWQgZm9yIHNlY29uZGFyeSB3b3JrZXJzIGlmIHRoZSBtaW5pbXVtIHNlY29u
ZGFyeSBpbnN0YW5jZXMgaXMgc2V0LgoKIFByaW1hcnkgd29ya2VycyAtIEJvdW5kczogW21p
bl9pbnN0YW5jZXMsICkuCiBTZWNvbmRhcnkgd29ya2VycyAtIEJvdW5kczogW21pbl9pbnN0
YW5jZXMsICkuIERlZmF1bHQ6IDAuCgoNCgUEAwIBBRIEiwICBwoNCgUEAwIBARIEiwIIFQoN
CgUEAwIBAxIEiwIYGQoNCgUEAwIBCBIEiwIaQgoQCggEAwIBCJwIABIEiwIbQQqbCAoEBAMC
AhIEnwICPBqMCCBPcHRpb25hbC4gV2VpZ2h0IGZvciB0aGUgaW5zdGFuY2UgZ3JvdXAsIHdo
aWNoIGlzIHVzZWQgdG8gZGV0ZXJtaW5lIHRoZQogZnJhY3Rpb24gb2YgdG90YWwgd29ya2Vy
cyBpbiB0aGUgY2x1c3RlciBmcm9tIHRoaXMgaW5zdGFuY2UgZ3JvdXAuCiBGb3IgZXhhbXBs
ZSwgaWYgcHJpbWFyeSB3b3JrZXJzIGhhdmUgd2VpZ2h0IDIsIGFuZCBzZWNvbmRhcnkgd29y
a2VycyBoYXZlCiB3ZWlnaHQgMSwgdGhlIGNsdXN0ZXIgd2lsbCBoYXZlIGFwcHJveGltYXRl
bHkgMiBwcmltYXJ5IHdvcmtlcnMgZm9yIGVhY2gKIHNlY29uZGFyeSB3b3JrZXIuCgogVGhl
IGNsdXN0ZXIgbWF5IG5vdCByZWFjaCB0aGUgc3BlY2lmaWVkIGJhbGFuY2UgaWYgY29uc3Ry
YWluZWQKIGJ5IG1pbi9tYXggYm91bmRzIG9yIG90aGVyIGF1dG9zY2FsaW5nIHNldHRpbmdz
LiBGb3IgZXhhbXBsZSwgaWYKIGBtYXhfaW5zdGFuY2VzYCBmb3Igc2Vjb25kYXJ5IHdvcmtl
cnMgaXMgMCwgdGhlbiBvbmx5IHByaW1hcnkgd29ya2VycyB3aWxsCiBiZSBhZGRlZC4gVGhl
IGNsdXN0ZXIgY2FuIGFsc28gYmUgb3V0IG9mIGJhbGFuY2Ugd2hlbiBjcmVhdGVkLgoKIElm
IHdlaWdodCBpcyBub3Qgc2V0IG9uIGFueSBpbnN0YW5jZSBncm91cCwgdGhlIGNsdXN0ZXIg
d2lsbCBkZWZhdWx0IHRvCiBlcXVhbCB3ZWlnaHQgZm9yIGFsbCBncm91cHM6IHRoZSBjbHVz
dGVyIHdpbGwgYXR0ZW1wdCB0byBtYWludGFpbiBhbiBlcXVhbAogbnVtYmVyIG9mIHdvcmtl
cnMgaW4gZWFjaCBncm91cCB3aXRoaW4gdGhlIGNvbmZpZ3VyZWQgc2l6ZSBib3VuZHMgZm9y
IGVhY2gKIGdyb3VwLiBJZiB3ZWlnaHQgaXMgc2V0IGZvciBvbmUgZ3JvdXAgb25seSwgdGhl
IGNsdXN0ZXIgd2lsbCBkZWZhdWx0IHRvCiB6ZXJvIHdlaWdodCBvbiB0aGUgdW5zZXQgZ3Jv
dXAuIEZvciBleGFtcGxlIGlmIHdlaWdodCBpcyBzZXQgb25seSBvbgogcHJpbWFyeSB3b3Jr
ZXJzLCB0aGUgY2x1c3RlciB3aWxsIHVzZSBwcmltYXJ5IHdvcmtlcnMgb25seSBhbmQgbm8K
IHNlY29uZGFyeSB3b3JrZXJzLgoKDQoFBAMCAgUSBJ8CAgcKDQoFBAMCAgESBJ8CCA4KDQoF
BAMCAgMSBJ8CERIKDQoFBAMCAggSBJ8CEzsKEAoIBAMCAgicCAASBJ8CFDoKOgoCBAQSBqMC
ALcCARosIEEgcmVxdWVzdCB0byBjcmVhdGUgYW4gYXV0b3NjYWxpbmcgcG9saWN5LgoKCwoD
BAQBEgSjAggmCtkDCgQEBAIAEgauAgKzAgQayAMgUmVxdWlyZWQuIFRoZSAicmVzb3VyY2Ug
bmFtZSIgb2YgdGhlIHJlZ2lvbiBvciBsb2NhdGlvbiwgYXMgZGVzY3JpYmVkCiBpbiBodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMuCgogKiBG
b3IgYHByb2plY3RzLnJlZ2lvbnMuYXV0b3NjYWxpbmdQb2xpY2llcy5jcmVhdGVgLCB0aGUg
cmVzb3VyY2UgbmFtZQogICBvZiB0aGUgcmVnaW9uIGhhcyB0aGUgZm9sbG93aW5nIGZvcm1h
dDoKICAgYHByb2plY3RzL3twcm9qZWN0X2lkfS9yZWdpb25zL3tyZWdpb259YAoKICogRm9y
IGBwcm9qZWN0cy5sb2NhdGlvbnMuYXV0b3NjYWxpbmdQb2xpY2llcy5jcmVhdGVgLCB0aGUg
cmVzb3VyY2UgbmFtZQogICBvZiB0aGUgbG9jYXRpb24gaGFzIHRoZSBmb2xsb3dpbmcgZm9y
bWF0OgogICBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259YAoK
DQoFBAQCAAUSBK4CAggKDQoFBAQCAAESBK4CCQ8KDQoFBAQCAAMSBK4CEhMKDwoFBAQCAAgS
Bq4CFLMCAwoQCggEBAIACJwIABIErwIEKgoRCgcEBAIACJ8IEgawAgSyAgUKOwoEBAQCARIE
tgICSBotIFJlcXVpcmVkLiBUaGUgYXV0b3NjYWxpbmcgcG9saWN5IHRvIGNyZWF0ZS4KCg0K
BQQEAgEGEgS2AgITCg0KBQQEAgEBEgS2AhQaCg0KBQQEAgEDEgS2Ah0eCg0KBQQEAgEIEgS2
Ah9HChAKCAQEAgEInAgAEgS2AiBGCjkKAgQFEga6AgDLAgEaKyBBIHJlcXVlc3QgdG8gZmV0
Y2ggYW4gYXV0b3NjYWxpbmcgcG9saWN5LgoKCwoDBAUBEgS6AggjCpEECgQEBQIAEgbFAgLK
AgQagAQgUmVxdWlyZWQuIFRoZSAicmVzb3VyY2UgbmFtZSIgb2YgdGhlIGF1dG9zY2FsaW5n
IHBvbGljeSwgYXMgZGVzY3JpYmVkCiBpbiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBp
cy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMuCgogKiBGb3IgYHByb2plY3RzLnJlZ2lvbnMuYXV0
b3NjYWxpbmdQb2xpY2llcy5nZXRgLCB0aGUgcmVzb3VyY2UgbmFtZQogICBvZiB0aGUgcG9s
aWN5IGhhcyB0aGUgZm9sbG93aW5nIGZvcm1hdDoKICAgYHByb2plY3RzL3twcm9qZWN0X2lk
fS9yZWdpb25zL3tyZWdpb259L2F1dG9zY2FsaW5nUG9saWNpZXMve3BvbGljeV9pZH1gCgog
KiBGb3IgYHByb2plY3RzLmxvY2F0aW9ucy5hdXRvc2NhbGluZ1BvbGljaWVzLmdldGAsIHRo
ZSByZXNvdXJjZSBuYW1lCiAgIG9mIHRoZSBwb2xpY3kgaGFzIHRoZSBmb2xsb3dpbmcgZm9y
bWF0OgogICBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1
dG9zY2FsaW5nUG9saWNpZXMve3BvbGljeV9pZH1gCgoNCgUEBQIABRIExQICCAoNCgUEBQIA
ARIExQIJDQoNCgUEBQIAAxIExQIQEQoPCgUEBQIACBIGxQISygIDChAKCAQFAgAInAgAEgTG
AgQqChEKBwQFAgAInwgSBscCBMkCBQo6CgIEBhIGzgIA0QIBGiwgQSByZXF1ZXN0IHRvIHVw
ZGF0ZSBhbiBhdXRvc2NhbGluZyBwb2xpY3kuCgoLCgMEBgESBM4CCCYKOQoEBAYCABIE0AIC
SBorIFJlcXVpcmVkLiBUaGUgdXBkYXRlZCBhdXRvc2NhbGluZyBwb2xpY3kuCgoNCgUEBgIA
BhIE0AICEwoNCgUEBgIAARIE0AIUGgoNCgUEBgIAAxIE0AIdHgoNCgUEBgIACBIE0AIfRwoQ
CggEBgIACJwIABIE0AIgRgqFAQoCBAcSBtYCAOcCARp3IEEgcmVxdWVzdCB0byBkZWxldGUg
YW4gYXV0b3NjYWxpbmcgcG9saWN5LgoKIEF1dG9zY2FsaW5nIHBvbGljaWVzIGluIHVzZSBi
eSBvbmUgb3IgbW9yZSBjbHVzdGVycyB3aWxsIG5vdCBiZSBkZWxldGVkLgoKCwoDBAcBEgTW
AggmCpcECgQEBwIAEgbhAgLmAgQahgQgUmVxdWlyZWQuIFRoZSAicmVzb3VyY2UgbmFtZSIg
b2YgdGhlIGF1dG9zY2FsaW5nIHBvbGljeSwgYXMgZGVzY3JpYmVkCiBpbiBodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMuCgogKiBGb3IgYHBy
b2plY3RzLnJlZ2lvbnMuYXV0b3NjYWxpbmdQb2xpY2llcy5kZWxldGVgLCB0aGUgcmVzb3Vy
Y2UgbmFtZQogICBvZiB0aGUgcG9saWN5IGhhcyB0aGUgZm9sbG93aW5nIGZvcm1hdDoKICAg
YHByb2plY3RzL3twcm9qZWN0X2lkfS9yZWdpb25zL3tyZWdpb259L2F1dG9zY2FsaW5nUG9s
aWNpZXMve3BvbGljeV9pZH1gCgogKiBGb3IgYHByb2plY3RzLmxvY2F0aW9ucy5hdXRvc2Nh
bGluZ1BvbGljaWVzLmRlbGV0ZWAsIHRoZSByZXNvdXJjZSBuYW1lCiAgIG9mIHRoZSBwb2xp
Y3kgaGFzIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogICBgcHJvamVjdHMve3Byb2plY3RfaWR9
L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9zY2FsaW5nUG9saWNpZXMve3BvbGljeV9pZH1g
CgoNCgUEBwIABRIE4QICCAoNCgUEBwIAARIE4QIJDQoNCgUEBwIAAxIE4QIQEQoPCgUEBwIA
CBIG4QIS5gIDChAKCAQHAgAInAgAEgTiAgQqChEKBwQHAgAInwgSBuMCBOUCBQpECgIECBIG
6gIAgwMBGjYgQSByZXF1ZXN0IHRvIGxpc3QgYXV0b3NjYWxpbmcgcG9saWNpZXMgaW4gYSBw
cm9qZWN0LgoKCwoDBAgBEgTqAggmCtUDCgQECAIAEgb1AgL6AgQaxAMgUmVxdWlyZWQuIFRo
ZSAicmVzb3VyY2UgbmFtZSIgb2YgdGhlIHJlZ2lvbiBvciBsb2NhdGlvbiwgYXMgZGVzY3Jp
YmVkCiBpbiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2Vf
bmFtZXMuCgogKiBGb3IgYHByb2plY3RzLnJlZ2lvbnMuYXV0b3NjYWxpbmdQb2xpY2llcy5s
aXN0YCwgdGhlIHJlc291cmNlIG5hbWUKICAgb2YgdGhlIHJlZ2lvbiBoYXMgdGhlIGZvbGxv
d2luZyBmb3JtYXQ6CiAgIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vcmVnaW9ucy97cmVnaW9u
fWAKCiAqIEZvciBgcHJvamVjdHMubG9jYXRpb25zLmF1dG9zY2FsaW5nUG9saWNpZXMubGlz
dGAsIHRoZSByZXNvdXJjZSBuYW1lCiAgIG9mIHRoZSBsb2NhdGlvbiBoYXMgdGhlIGZvbGxv
d2luZyBmb3JtYXQ6CiAgIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn1gCgoNCgUECAIABRIE9QICCAoNCgUECAIAARIE9QIJDwoNCgUECAIAAxIE9QISEwoP
CgUECAIACBIG9QIU+gIDChAKCAQIAgAInAgAEgT2AgQqChEKBwQIAgAInwgSBvcCBPkCBQqJ
AQoEBAgCARIE/gICPxp7IE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgcmVzdWx0
cyB0byByZXR1cm4gaW4gZWFjaCByZXNwb25zZS4KIE11c3QgYmUgbGVzcyB0aGFuIG9yIGVx
dWFsIHRvIDEwMDAuIERlZmF1bHRzIHRvIDEwMC4KCg0KBQQIAgEFEgT+AgIHCg0KBQQIAgEB
EgT+AggRCg0KBQQIAgEDEgT+AhQVCg0KBQQIAgEIEgT+AhY+ChAKCAQIAgEInAgAEgT+Ahc9
CmwKBAQIAgISBIIDAkEaXiBPcHRpb25hbC4gVGhlIHBhZ2UgdG9rZW4sIHJldHVybmVkIGJ5
IGEgcHJldmlvdXMgY2FsbCwgdG8gcmVxdWVzdCB0aGUKIG5leHQgcGFnZSBvZiByZXN1bHRz
LgoKDQoFBAgCAgUSBIIDAggKDQoFBAgCAgESBIIDCRMKDQoFBAgCAgMSBIIDFhcKDQoFBAgC
AggSBIIDGEAKEAoIBAgCAgicCAASBIIDGT8KUgoCBAkSBoYDAI4DARpEIEEgcmVzcG9uc2Ug
dG8gYSByZXF1ZXN0IHRvIGxpc3QgYXV0b3NjYWxpbmcgcG9saWNpZXMgaW4gYSBwcm9qZWN0
LgoKCwoDBAkBEgSGAwgnCjkKBAQJAgASBogDAokDMhopIE91dHB1dCBvbmx5LiBBdXRvc2Nh
bGluZyBwb2xpY2llcyBsaXN0LgoKDQoFBAkCAAQSBIgDAgoKDQoFBAkCAAYSBIgDCxwKDQoF
BAkCAAESBIgDHSUKDQoFBAkCAAMSBIgDKCkKDQoFBAkCAAgSBIkDBjEKEAoIBAkCAAicCAAS
BIkDBzAKaAoEBAkCARIEjQMCSRpaIE91dHB1dCBvbmx5LiBUaGlzIHRva2VuIGlzIGluY2x1
ZGVkIGluIHRoZSByZXNwb25zZSBpZiB0aGVyZSBhcmUgbW9yZQogcmVzdWx0cyB0byBmZXRj
aC4KCg0KBQQJAgEFEgSNAwIICg0KBQQJAgEBEgSNAwkYCg0KBQQJAgEDEgSNAxscCg0KBQQJ
AgEIEgSNAx1IChAKCAQJAgEInAgAEgSNAx5HYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy ===
    # Fields for AutoscalingPolicy
    # Field: id Type: 9 ()
    # Field: name Type: 9 ()
    # Field: basic_algorithm Type: 11 (.google.cloud.dataproc.v1.BasicAutoscalingAlgorithm)
    # Field: worker_config Type: 11 (.google.cloud.dataproc.v1.InstanceGroupAutoscalingPolicyConfig)
    # Field: secondary_worker_config Type: 11 (.google.cloud.dataproc.v1.InstanceGroupAutoscalingPolicyConfig)
    # Field: labels Type: 11 (.google.cloud.dataproc.v1.AutoscalingPolicy.LabelsEntry)
    # Field: cluster_type Type: 14 (.google.cloud.dataproc.v1.AutoscalingPolicy.ClusterType)

# Enum: AutoscalingPolicy::ClusterType
our $AutoscalingPolicy_CLUSTER_TYPE_UNSPECIFIED = 0;
our $AutoscalingPolicy_STANDARD = 1;
our $AutoscalingPolicy_ZERO_SCALE = 2;

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicAutoscalingAlgorithm ===
    # Fields for BasicAutoscalingAlgorithm
    # Field: yarn_config Type: 11 (.google.cloud.dataproc.v1.BasicYarnAutoscalingConfig)
    # Field: cooldown_period Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicYarnAutoscalingConfig ===
    # Fields for BasicYarnAutoscalingConfig
    # Field: graceful_decommission_timeout Type: 11 (.google.protobuf.Duration)
    # Field: scale_up_factor Type: 1 ()
    # Field: scale_down_factor Type: 1 ()
    # Field: scale_up_min_worker_fraction Type: 1 ()
    # Field: scale_down_min_worker_fraction Type: 1 ()

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::InstanceGroupAutoscalingPolicyConfig ===
    # Fields for InstanceGroupAutoscalingPolicyConfig
    # Field: min_instances Type: 5 ()
    # Field: max_instances Type: 5 ()
    # Field: weight Type: 5 ()

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::CreateAutoscalingPolicyRequest ===
    # Fields for CreateAutoscalingPolicyRequest
    # Field: parent Type: 9 ()
    # Field: policy Type: 11 (.google.cloud.dataproc.v1.AutoscalingPolicy)

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::GetAutoscalingPolicyRequest ===
    # Fields for GetAutoscalingPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::UpdateAutoscalingPolicyRequest ===
    # Fields for UpdateAutoscalingPolicyRequest
    # Field: policy Type: 11 (.google.cloud.dataproc.v1.AutoscalingPolicy)

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::DeleteAutoscalingPolicyRequest ===
    # Fields for DeleteAutoscalingPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesRequest ===
    # Fields for ListAutoscalingPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesResponse ===
    # Fields for ListAutoscalingPoliciesResponse
    # Field: policies Type: 11 (.google.cloud.dataproc.v1.AutoscalingPolicy)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicyServiceClient ===
package Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicyServiceClient;

=pod

=head2 Service Client: Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicyServiceClient

Client stub representing the remote C<AutoscalingPolicyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dataproc.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataproc.googleapis.com:443' );

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

sub create_autoscaling_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::AutoscalingPolicies::CreateAutoscalingPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.AutoscalingPolicyService',
        method         => 'CreateAutoscalingPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy',
    });
}

sub update_autoscaling_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::AutoscalingPolicies::UpdateAutoscalingPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.AutoscalingPolicyService',
        method         => 'UpdateAutoscalingPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy',
    });
}

sub get_autoscaling_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::AutoscalingPolicies::GetAutoscalingPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.AutoscalingPolicyService',
        method         => 'GetAutoscalingPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy',
    });
}

sub list_autoscaling_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.AutoscalingPolicyService',
        method         => 'ListAutoscalingPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesResponse',
    });
}

sub delete_autoscaling_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dataproc::V1::AutoscalingPolicies::DeleteAutoscalingPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dataproc.v1.AutoscalingPolicyService',
        method         => 'DeleteAutoscalingPolicy',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataproc::V1::AutoscalingPolicies - Compiled Protocol Buffers messages for google/cloud/dataproc/v1/autoscaling_policies.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::AutoscalingPolicies;

    my $msg = Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy->new({
        id => $id,
        name => $name,
        basic_algorithm => $basic_algorithm,
        worker_config => $worker_config,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataproc/v1/autoscaling_policies.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy

Describes an autoscaling policy for Dataproc cluster autoscaler.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Required. The policy id.

The id must contain only letters (a-z, A-Z), numbers (0-9),
underscores (_), and hyphens (-). Cannot begin or end with underscore
or hyphen. Must consist of between 3 and 50 characters.


=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The "resource name" of the autoscaling policy, as described
in https://cloud.google.com/apis/design/resource_names.

* For `projects.regions.autoscalingPolicies`, the resource name of the
  policy has the following format:
  `projects/{project_id}/regions/{region}/autoscalingPolicies/{policy_id}`

* For `projects.locations.autoscalingPolicies`, the resource name of the
  policy has the following format:
  `projects/{project_id}/locations/{location}/autoscalingPolicies/{policy_id}`

=item * C<< $msg->basic_algorithm() >> / C<< $msg->basic_algorithm($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicAutoscalingAlgorithm>)

=item * C<< $msg->worker_config() >> / C<< $msg->worker_config($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::InstanceGroupAutoscalingPolicyConfig>)

Required. Describes how the autoscaler will operate for primary workers.

=item * C<< $msg->secondary_worker_config() >> / C<< $msg->secondary_worker_config($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::InstanceGroupAutoscalingPolicyConfig>)

Optional. Describes how the autoscaler will operate for secondary workers.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy::LabelsEntry>)

Optional. The labels to associate with this autoscaling policy.
Label B<keys> must contain 1 to 63 characters, and must conform to
[RFC 1035](https://www.ietf.org/rfc/rfc1035.txt).
Label B<values> may be empty, but, if present, must contain 1 to 63
characters, and must conform to [RFC
1035](https://www.ietf.org/rfc/rfc1035.txt). No more than 32 labels can be
associated with an autoscaling policy.

=item * C<< $msg->cluster_type() >> / C<< $msg->cluster_type($value) >>

Type: C<Enum> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicy::ClusterType>)

Optional. The type of the clusters for which this autoscaling policy is to
be configured.

=back

=head3 Enum: AutoscalingPolicy::ClusterType

=over 4

=item * C<CLUSTER_TYPE_UNSPECIFIED> => C<0>

=item * C<STANDARD> => C<1>

=item * C<ZERO_SCALE> => C<2>

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicAutoscalingAlgorithm

Basic algorithm for autoscaling.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->yarn_config() >> / C<< $msg->yarn_config($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicYarnAutoscalingConfig>)

Required. YARN autoscaling configuration.

=item * C<< $msg->cooldown_period() >> / C<< $msg->cooldown_period($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. Duration between scaling events. A scaling period starts after
the update operation from the previous event has completed.

Bounds: [2m, 1d]. Default: 2m.

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicYarnAutoscalingConfig

Basic autoscaling configurations for YARN.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->graceful_decommission_timeout() >> / C<< $msg->graceful_decommission_timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. Timeout for YARN graceful decommissioning of Node Managers.
Specifies the duration to wait for jobs to complete before forcefully
removing workers (and potentially interrupting jobs). Only applicable to
downscaling operations.

Bounds: [0s, 1d].

=item * C<< $msg->scale_up_factor() >> / C<< $msg->scale_up_factor($value) >>

Type: C<Double>

Required. Fraction of average YARN pending memory in the last cooldown
period for which to add workers. A scale-up factor of 1.0 will result in
scaling up so that there is no pending memory remaining after the update
(more aggressive scaling). A scale-up factor closer to 0 will result in a
smaller magnitude of scaling up (less aggressive scaling). See [How
autoscaling
works](https://cloud.google.com/dataproc/docs/concepts/configuring-clusters/autoscaling#how_autoscaling_works)
for more information.

Bounds: [0.0, 1.0].

=item * C<< $msg->scale_down_factor() >> / C<< $msg->scale_down_factor($value) >>

Type: C<Double>

Required. Fraction of average YARN pending memory in the last cooldown
period for which to remove workers. A scale-down factor of 1 will result in
scaling down so that there is no available memory remaining after the
update (more aggressive scaling). A scale-down factor of 0 disables
removing workers, which can be beneficial for autoscaling a single job.
See [How autoscaling
works](https://cloud.google.com/dataproc/docs/concepts/configuring-clusters/autoscaling#how_autoscaling_works)
for more information.

Bounds: [0.0, 1.0].

=item * C<< $msg->scale_up_min_worker_fraction() >> / C<< $msg->scale_up_min_worker_fraction($value) >>

Type: C<Double>

Optional. Minimum scale-up threshold as a fraction of total cluster size
before scaling occurs. For example, in a 20-worker cluster, a threshold of
0.1 means the autoscaler must recommend at least a 2-worker scale-up for
the cluster to scale. A threshold of 0 means the autoscaler will scale up
on any recommended change.

Bounds: [0.0, 1.0]. Default: 0.0.

=item * C<< $msg->scale_down_min_worker_fraction() >> / C<< $msg->scale_down_min_worker_fraction($value) >>

Type: C<Double>

Optional. Minimum scale-down threshold as a fraction of total cluster size
before scaling occurs. For example, in a 20-worker cluster, a threshold of
0.1 means the autoscaler must recommend at least a 2 worker scale-down for
the cluster to scale. A threshold of 0 means the autoscaler will scale down
on any recommended change.

Bounds: [0.0, 1.0]. Default: 0.0.

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::InstanceGroupAutoscalingPolicyConfig

Configuration for the size bounds of an instance group, including its
proportional size to other groups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->min_instances() >> / C<< $msg->min_instances($value) >>

Type: C<Int32>

Optional. Minimum number of instances for this group.

Primary workers - Bounds: [2, max_instances]. Default: 2.
Secondary workers - Bounds: [0, max_instances]. Default: 0.

=item * C<< $msg->max_instances() >> / C<< $msg->max_instances($value) >>

Type: C<Int32>

Required. Maximum number of instances for this group. Required for primary
workers. Note that by default, clusters will not use secondary workers.
Required for secondary workers if the minimum secondary instances is set.

Primary workers - Bounds: [min_instances, ).
Secondary workers - Bounds: [min_instances, ). Default: 0.

=item * C<< $msg->weight() >> / C<< $msg->weight($value) >>

Type: C<Int32>

Optional. Weight for the instance group, which is used to determine the
fraction of total workers in the cluster from this instance group.
For example, if primary workers have weight 2, and secondary workers have
weight 1, the cluster will have approximately 2 primary workers for each
secondary worker.

The cluster may not reach the specified balance if constrained
by min/max bounds or other autoscaling settings. For example, if
`max_instances` for secondary workers is 0, then only primary workers will
be added. The cluster can also be out of balance when created.

If weight is not set on any instance group, the cluster will default to
equal weight for all groups: the cluster will attempt to maintain an equal
number of workers in each group within the configured size bounds for each
group. If weight is set for one group only, the cluster will default to
zero weight on the unset group. For example if weight is set only on
primary workers, the cluster will use primary workers only and no
secondary workers.

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::CreateAutoscalingPolicyRequest

A request to create an autoscaling policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The "resource name" of the region or location, as described
in https://cloud.google.com/apis/design/resource_names.

* For `projects.regions.autoscalingPolicies.create`, the resource name
  of the region has the following format:
  `projects/{project_id}/regions/{region}`

* For `projects.locations.autoscalingPolicies.create`, the resource name
  of the location has the following format:
  `projects/{project_id}/locations/{location}`

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy>)

Required. The autoscaling policy to create.

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::GetAutoscalingPolicyRequest

A request to fetch an autoscaling policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The "resource name" of the autoscaling policy, as described
in https://cloud.google.com/apis/design/resource_names.

* For `projects.regions.autoscalingPolicies.get`, the resource name
  of the policy has the following format:
  `projects/{project_id}/regions/{region}/autoscalingPolicies/{policy_id}`

* For `projects.locations.autoscalingPolicies.get`, the resource name
  of the policy has the following format:
  `projects/{project_id}/locations/{location}/autoscalingPolicies/{policy_id}`

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::UpdateAutoscalingPolicyRequest

A request to update an autoscaling policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy>)

Required. The updated autoscaling policy.

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::DeleteAutoscalingPolicyRequest

A request to delete an autoscaling policy.

Autoscaling policies in use by one or more clusters will not be deleted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The "resource name" of the autoscaling policy, as described
in https://cloud.google.com/apis/design/resource_names.

* For `projects.regions.autoscalingPolicies.delete`, the resource name
  of the policy has the following format:
  `projects/{project_id}/regions/{region}/autoscalingPolicies/{policy_id}`

* For `projects.locations.autoscalingPolicies.delete`, the resource name
  of the policy has the following format:
  `projects/{project_id}/locations/{location}/autoscalingPolicies/{policy_id}`

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesRequest

A request to list autoscaling policies in a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The "resource name" of the region or location, as described
in https://cloud.google.com/apis/design/resource_names.

* For `projects.regions.autoscalingPolicies.list`, the resource name
  of the region has the following format:
  `projects/{project_id}/regions/{region}`

* For `projects.locations.autoscalingPolicies.list`, the resource name
  of the location has the following format:
  `projects/{project_id}/locations/{location}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return in each response.
Must be less than or equal to 1000. Defaults to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The page token, returned by a previous call, to request the
next page of results.

=back

=head2 Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesResponse

A response to a request to list autoscaling policies in a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policies() >> / C<< $msg->policies($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy>)

Output only. Autoscaling policies list.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Output only. This token is included in the response if there are more
results to fetch.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataproc::V1::AutoscalingPolicies::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
