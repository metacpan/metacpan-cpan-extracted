package Google::Cloud::Policysimulator::V1::Simulator;

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
    eval { require Google::Cloud::Policysimulator::V1::Explanations };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    eval { require Google::Type::Date };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvcG9saWN5c2ltdWxhdG9yL3YxL3NpbXVsYXRvci5wcm90bxIfZ29v
Z2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMmdvb2dsZS9jbG91ZC9wb2xp
Y3lzaW11bGF0b3IvdjEvZXhwbGFuYXRpb25zLnByb3RvGhpnb29nbGUvaWFtL3YxL3BvbGlj
eS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvGhZnb29n
bGUvdHlwZS9kYXRlLnByb3RvIuMGCgZSZXBsYXkSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1l
EkgKBXN0YXRlGAIgASgOMi0uZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBs
YXkuU3RhdGVCA+BBA1IFc3RhdGUSSgoGY29uZmlnGAMgASgLMi0uZ29vZ2xlLmNsb3VkLnBv
bGljeXNpbXVsYXRvci52MS5SZXBsYXlDb25maWdCA+BBAlIGY29uZmlnEmQKD3Jlc3VsdHNf
c3VtbWFyeRgFIAEoCzI2Lmdvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuUmVwbGF5
LlJlc3VsdHNTdW1tYXJ5QgPgQQNSDnJlc3VsdHNTdW1tYXJ5GooCCg5SZXN1bHRzU3VtbWFy
eRIbCglsb2dfY291bnQYASABKAVSCGxvZ0NvdW50EicKD3VuY2hhbmdlZF9jb3VudBgCIAEo
BVIOdW5jaGFuZ2VkQ291bnQSKQoQZGlmZmVyZW5jZV9jb3VudBgDIAEoBVIPZGlmZmVyZW5j
ZUNvdW50Eh8KC2Vycm9yX2NvdW50GAQgASgFUgplcnJvckNvdW50EjIKC29sZGVzdF9kYXRl
GAUgASgLMhEuZ29vZ2xlLnR5cGUuRGF0ZVIKb2xkZXN0RGF0ZRIyCgtuZXdlc3RfZGF0ZRgG
IAEoCzIRLmdvb2dsZS50eXBlLkRhdGVSCm5ld2VzdERhdGUiUwoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABILCgdQRU5ESU5HEAESCwoHUlVOTklORxACEg0KCVNVQ0NFRURFRBAD
EgoKBkZBSUxFRBAEOuEB6kHdAQolcG9saWN5c2ltdWxhdG9yLmdvb2dsZWFwaXMuY29tL1Jl
cGxheRI4cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcGxheXMv
e3JlcGxheX0SNmZvbGRlcnMve2ZvbGRlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVwbGF5
cy97cmVwbGF5fRJCb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9yZXBsYXlzL3tyZXBsYXl9IpsFCgxSZXBsYXlSZXN1bHQSQQoEZGlmZhgFIAEo
CzIrLmdvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuUmVwbGF5RGlmZkgAUgRkaWZm
EioKBWVycm9yGAYgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNIAFIFZXJyb3ISEgoEbmFtZRgB
IAEoCVIEbmFtZRJCCgZwYXJlbnQYAiABKAlCKvpBJwolcG9saWN5c2ltdWxhdG9yLmdvb2ds
ZWFwaXMuY29tL1JlcGxheVIGcGFyZW50Ek8KDGFjY2Vzc190dXBsZRgDIAEoCzIsLmdvb2ds
ZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuQWNjZXNzVHVwbGVSC2FjY2Vzc1R1cGxlEjcK
Dmxhc3Rfc2Vlbl9kYXRlGAQgASgLMhEuZ29vZ2xlLnR5cGUuRGF0ZVIMbGFzdFNlZW5EYXRl
Oq8C6kGrAgorcG9saWN5c2ltdWxhdG9yLmdvb2dsZWFwaXMuY29tL1JlcGxheVJlc3VsdBJQ
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcGxheXMve3JlcGxh
eX0vcmVzdWx0cy97cmVwbGF5X3Jlc3VsdH0STmZvbGRlcnMve2ZvbGRlcn0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vcmVwbGF5cy97cmVwbGF5fS9yZXN1bHRzL3tyZXBsYXlfcmVzdWx0fRJa
b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXBs
YXlzL3tyZXBsYXl9L3Jlc3VsdHMve3JlcGxheV9yZXN1bHR9QggKBnJlc3VsdCJ4ChNDcmVh
dGVSZXBsYXlSZXF1ZXN0EhsKBnBhcmVudBgBIAEoCUID4EECUgZwYXJlbnQSRAoGcmVwbGF5
GAIgASgLMicuZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBsYXlCA+BBAlIG
cmVwbGF5IlQKF1JlcGxheU9wZXJhdGlvbk1ldGFkYXRhEjkKCnN0YXJ0X3RpbWUYASABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglzdGFydFRpbWUiVQoQR2V0UmVwbGF5UmVx
dWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJXBvbGljeXNpbXVsYXRvci5nb29nbGVhcGlz
LmNvbS9SZXBsYXlSBG5hbWUinQEKGExpc3RSZXBsYXlSZXN1bHRzUmVxdWVzdBJFCgZwYXJl
bnQYASABKAlCLeBBAvpBJwolcG9saWN5c2ltdWxhdG9yLmdvb2dsZWFwaXMuY29tL1JlcGxh
eVIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgD
IAEoCVIJcGFnZVRva2VuIpkBChlMaXN0UmVwbGF5UmVzdWx0c1Jlc3BvbnNlElQKDnJlcGxh
eV9yZXN1bHRzGAEgAygLMi0uZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBs
YXlSZXN1bHRSDXJlcGxheVJlc3VsdHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0
UGFnZVRva2VuIuYCCgxSZXBsYXlDb25maWcSZwoOcG9saWN5X292ZXJsYXkYASADKAsyQC5n
b29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheUNvbmZpZy5Qb2xpY3lPdmVy
bGF5RW50cnlSDXBvbGljeU92ZXJsYXkSVgoKbG9nX3NvdXJjZRgCIAEoDjI3Lmdvb2dsZS5j
bG91ZC5wb2xpY3lzaW11bGF0b3IudjEuUmVwbGF5Q29uZmlnLkxvZ1NvdXJjZVIJbG9nU291
cmNlGlcKElBvbGljeU92ZXJsYXlFbnRyeRIQCgNrZXkYASABKAlSA2tleRIrCgV2YWx1ZRgC
IAEoCzIVLmdvb2dsZS5pYW0udjEuUG9saWN5UgV2YWx1ZToCOAEiPAoJTG9nU291cmNlEhoK
FkxPR19TT1VSQ0VfVU5TUEVDSUZJRUQQABITCg9SRUNFTlRfQUNDRVNTRVMQASJfCgpSZXBs
YXlEaWZmElEKC2FjY2Vzc19kaWZmGAIgASgLMjAuZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVs
YXRvci52MS5BY2Nlc3NTdGF0ZURpZmZSCmFjY2Vzc0RpZmYizQMKD0FjY2Vzc1N0YXRlRGlm
ZhJMCghiYXNlbGluZRgBIAEoCzIwLmdvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEu
RXhwbGFpbmVkQWNjZXNzUghiYXNlbGluZRJOCglzaW11bGF0ZWQYAiABKAsyMC5nb29nbGUu
Y2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLkV4cGxhaW5lZEFjY2Vzc1IJc2ltdWxhdGVkEmYK
DWFjY2Vzc19jaGFuZ2UYAyABKA4yQS5nb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYx
LkFjY2Vzc1N0YXRlRGlmZi5BY2Nlc3NDaGFuZ2VUeXBlUgxhY2Nlc3NDaGFuZ2UiswEKEEFj
Y2Vzc0NoYW5nZVR5cGUSIgoeQUNDRVNTX0NIQU5HRV9UWVBFX1VOU1BFQ0lGSUVEEAASDQoJ
Tk9fQ0hBTkdFEAESEgoOVU5LTk9XTl9DSEFOR0UQAhISCg5BQ0NFU1NfUkVWT0tFRBADEhEK
DUFDQ0VTU19HQUlORUQQBBIYChRBQ0NFU1NfTUFZQkVfUkVWT0tFRBAFEhcKE0FDQ0VTU19N
QVlCRV9HQUlORUQQBiLcAQoPRXhwbGFpbmVkQWNjZXNzEk8KDGFjY2Vzc19zdGF0ZRgBIAEo
DjIsLmdvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuQWNjZXNzU3RhdGVSC2FjY2Vz
c1N0YXRlEkwKCHBvbGljaWVzGAIgAygLMjAuZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRv
ci52MS5FeHBsYWluZWRQb2xpY3lSCHBvbGljaWVzEioKBmVycm9ycxgDIAMoCzISLmdvb2ds
ZS5ycGMuU3RhdHVzUgZlcnJvcnMygQgKCVNpbXVsYXRvchKHAgoJR2V0UmVwbGF5EjEuZ29v
Z2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5HZXRSZXBsYXlSZXF1ZXN0GicuZ29vZ2xl
LmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBsYXkinQGC0+STAo8BEisvdjEve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBsYXlzLyp9WiwSKi92MS97bmFtZT1mb2xkZXJz
LyovbG9jYXRpb25zLyovcmVwbGF5cy8qfVoyEjAvdjEve25hbWU9b3JnYW5pemF0aW9ucy8q
L2xvY2F0aW9ucy8qL3JlcGxheXMvKn3aQQRuYW1lEsgCCgxDcmVhdGVSZXBsYXkSNC5nb29n
bGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLkNyZWF0ZVJlcGxheVJlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIuIBgtPkkwKnASIrL3YxL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKn0vcmVwbGF5czoGcmVwbGF5WjQiKi92MS97cGFyZW50PWZvbGRl
cnMvKi9sb2NhdGlvbnMvKn0vcmVwbGF5czoGcmVwbGF5WjoiMC92MS97cGFyZW50PW9yZ2Fu
aXphdGlvbnMvKi9sb2NhdGlvbnMvKn0vcmVwbGF5czoGcmVwbGF52kENcGFyZW50LHJlcGxh
ecpBIQoGUmVwbGF5EhdSZXBsYXlPcGVyYXRpb25NZXRhZGF0YRLKAgoRTGlzdFJlcGxheVJl
c3VsdHMSOS5nb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLkxpc3RSZXBsYXlSZXN1
bHRzUmVxdWVzdBo6Lmdvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuTGlzdFJlcGxh
eVJlc3VsdHNSZXNwb25zZSK9AYLT5JMCrQESNS92MS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyovcmVwbGF5cy8qfS9yZXN1bHRzWjYSNC92MS97cGFyZW50PWZvbGRlcnMvKi9s
b2NhdGlvbnMvKi9yZXBsYXlzLyp9L3Jlc3VsdHNaPBI6L3YxL3twYXJlbnQ9b3JnYW5pemF0
aW9ucy8qL2xvY2F0aW9ucy8qL3JlcGxheXMvKn0vcmVzdWx0c9pBBnBhcmVudBpSykEecG9s
aWN5c2ltdWxhdG9yLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5j
b20vYXV0aC9jbG91ZC1wbGF0Zm9ybULvAQojY29tLmdvb2dsZS5jbG91ZC5wb2xpY3lzaW11
bGF0b3IudjFCDlNpbXVsYXRvclByb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vcG9saWN5
c2ltdWxhdG9yL2FwaXYxL3BvbGljeXNpbXVsYXRvcnBiO3BvbGljeXNpbXVsYXRvcnBiqgIf
R29vZ2xlLkNsb3VkLlBvbGljeVNpbXVsYXRvci5WMcoCH0dvb2dsZVxDbG91ZFxQb2xpY3lT
aW11bGF0b3JcVjHqAiJHb29nbGU6OkNsb3VkOjpQb2xpY3lTaW11bGF0b3I6OlYxSsd7CgcS
BQ4AywMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkK
AgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPAoJ
CgIDBRIDFwAkCgkKAgMGEgMYAC0KCQoCAwcSAxkAKQoJCgIDCBIDGgAhCgkKAgMJEgMbACAK
CAoBCBIDHQA8CgkKAgglEgMdADwKCAoBCBIDHgBkCgkKAggLEgMeAGQKCAoBCBIDHwAiCgkK
AggKEgMfACIKCAoBCBIDIAAvCgkKAggIEgMgAC8KCAoBCBIDIQA8CgkKAggBEgMhADwKCAoB
CBIDIgA8CgkKAggpEgMiADwKCAoBCBIDIwA7CgkKAggtEgMjADsKjwUKAgYAEgQxAGgBGoIF
IFBvbGljeSBTaW11bGF0b3IgQVBJIHNlcnZpY2UuCgogUG9saWN5IFNpbXVsYXRvciBpcyBh
IGNvbGxlY3Rpb24gb2YgZW5kcG9pbnRzIGZvciBjcmVhdGluZywgcnVubmluZywgYW5kCiB2
aWV3aW5nIGEgW1JlcGxheV1bZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBs
YXldLiBBCiBbUmVwbGF5XVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxh
eV0gaXMgYSB0eXBlIG9mIHNpbXVsYXRpb24gdGhhdAogbGV0cyB5b3Ugc2VlIGhvdyB5b3Vy
IHByaW5jaXBhbHMnIGFjY2VzcyB0byByZXNvdXJjZXMgbWlnaHQgY2hhbmdlIGlmIHlvdQog
Y2hhbmdlZCB5b3VyIElBTSBwb2xpY3kuCgogRHVyaW5nIGEgW1JlcGxheV1bZ29vZ2xlLmNs
b3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBsYXldLCBQb2xpY3kgU2ltdWxhdG9yCiByZS1l
dmFsdWF0ZXMsIG9yIHJlcGxheXMsIHBhc3QgYWNjZXNzIGF0dGVtcHRzIHVuZGVyIGJvdGgg
dGhlIGN1cnJlbnQgcG9saWN5CiBhbmQgIHlvdXIgcHJvcG9zZWQgcG9saWN5LCBhbmQgY29t
cGFyZXMgdGhvc2UgcmVzdWx0cyB0byBkZXRlcm1pbmUgaG93IHlvdXIKIHByaW5jaXBhbHMn
IGFjY2VzcyBtaWdodCBjaGFuZ2UgdW5kZXIgdGhlIHByb3Bvc2VkIHBvbGljeS4KCgoKAwYA
ARIDMQgRCgoKAwYAAxIDMgJGCgwKBQYAA5kIEgMyAkYKCwoDBgADEgQzAjQ3Cg0KBQYAA5oI
EgQzAjQ3CoUBCgQGAAIAEgQ4AkEDGncgR2V0cyB0aGUgc3BlY2lmaWVkIFtSZXBsYXldW2dv
b2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuUmVwbGF5XS4gRWFjaAogYFJlcGxheWAg
aXMgYXZhaWxhYmxlIGZvciBhdCBsZWFzdCA3IGRheXMuCgoMCgUGAAIAARIDOAYPCgwKBQYA
AgACEgM4ECAKDAoFBgACAAMSAzgrMQoNCgUGAAIABBIEOQQ/BgoRCgkGAAIABLDKvCISBDkE
PwYKDAoFBgACAAQSA0AEMgoPCggGAAIABJsIABIDQAQyCqUBCgQGAAIBEgRFAlcDGpYBIENy
ZWF0ZXMgYW5kIHN0YXJ0cyBhIFtSZXBsYXldW2dvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0
b3IudjEuUmVwbGF5XSB1c2luZwogdGhlIGdpdmVuIFtSZXBsYXlDb25maWddW2dvb2dsZS5j
bG91ZC5wb2xpY3lzaW11bGF0b3IudjEuUmVwbGF5Q29uZmlnXS4KCgwKBQYAAgEBEgNFBhIK
DAoFBgACAQISA0UTJgoMCgUGAAIBAxIDRTFNCg0KBQYAAgEEEgRGBFEGChEKCQYAAgEEsMq8
IhIERgRRBgoMCgUGAAIBBBIDUgQ7Cg8KCAYAAgEEmwgAEgNSBDsKDQoFBgACAQQSBFMEVgYK
DwoHBgACAQSZCBIEUwRWBgphCgQGAAICEgRbAmcDGlMgTGlzdHMgdGhlIHJlc3VsdHMgb2Yg
cnVubmluZyBhCiBbUmVwbGF5XVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJl
cGxheV0uCgoMCgUGAAICARIDWwYXCgwKBQYAAgICEgNbGDAKDAoFBgACAgMSA1wPKAoNCgUG
AAICBBIEXQRlBgoRCgkGAAICBLDKvCISBF0EZQYKDAoFBgACAgQSA2YENAoPCggGAAICBJsI
ABIDZgQ0Cj8KAgQAEgVrALABARoyIEEgcmVzb3VyY2UgZGVzY3JpYmluZyBhIGBSZXBsYXlg
LCBvciBzaW11bGF0aW9uLgoKCgoDBAABEgNrCA4KCwoDBAAHEgRsAnEECg0KBQQAB50IEgRs
AnEECkMKBAQAAwASBXQCiAEDGjQgU3VtbWFyeSBzdGF0aXN0aWNzIGFib3V0IHRoZSByZXBs
YXllZCBsb2cgZW50cmllcy4KCgwKBQQAAwABEgN0ChgKOgoGBAADAAIAEgN2BBgaKyBUaGUg
dG90YWwgbnVtYmVyIG9mIGxvZyBlbnRyaWVzIHJlcGxheWVkLgoKDgoHBAADAAIABRIDdgQJ
Cg4KBwQAAwACAAESA3YKEwoOCgcEAAMAAgADEgN2FhcKcAoGBAADAAIBEgN6BB4aYSBUaGUg
bnVtYmVyIG9mIHJlcGxheWVkIGxvZyBlbnRyaWVzIHdpdGggbm8gZGlmZmVyZW5jZSBiZXR3
ZWVuCiBiYXNlbGluZSBhbmQgc2ltdWxhdGVkIHBvbGljaWVzLgoKDgoHBAADAAIBBRIDegQJ
Cg4KBwQAAwACAQESA3oKGQoOCgcEAAMAAgEDEgN6HB0KbwoGBAADAAICEgN+BB8aYCBUaGUg
bnVtYmVyIG9mIHJlcGxheWVkIGxvZyBlbnRyaWVzIHdpdGggYSBkaWZmZXJlbmNlIGJldHdl
ZW4gYmFzZWxpbmUgYW5kCiBzaW11bGF0ZWQgcG9saWNpZXMuCgoOCgcEAAMAAgIFEgN+BAkK
DgoHBAADAAICARIDfgoaCg4KBwQAAwACAgMSA34dHgpHCgYEAAMAAgMSBIEBBBoaNyBUaGUg
bnVtYmVyIG9mIGxvZyBlbnRyaWVzIHRoYXQgY291bGQgbm90IGJlIHJlcGxheWVkLgoKDwoH
BAADAAIDBRIEgQEECQoPCgcEAAMAAgMBEgSBAQoVCg8KBwQAAwACAwMSBIEBGBkKPAoGBAAD
AAIEEgSEAQQlGiwgVGhlIGRhdGUgb2YgdGhlIG9sZGVzdCBsb2cgZW50cnkgcmVwbGF5ZWQu
CgoPCgcEAAMAAgQGEgSEAQQUCg8KBwQAAwACBAESBIQBFSAKDwoHBAADAAIEAxIEhAEjJAo8
CgYEAAMAAgUSBIcBBCUaLCBUaGUgZGF0ZSBvZiB0aGUgbmV3ZXN0IGxvZyBlbnRyeSByZXBs
YXllZC4KCg8KBwQAAwACBQYSBIcBBBQKDwoHBAADAAIFARIEhwEVIAoPCgcEAAMAAgUDEgSH
ASMkClwKBAQABAASBosBApoBAxpMIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBbUmVwbGF5
XVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheV0uCgoNCgUEAAQAARIE
iwEHDAo2CgYEAAQAAgASBI0BBBoaJiBEZWZhdWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVu
dXNlZC4KCg8KBwQABAACAAESBI0BBBUKDwoHBAAEAAIAAhIEjQEYGQozCgYEAAQAAgESBJAB
BBAaIyBUaGUgYFJlcGxheWAgaGFzIG5vdCBzdGFydGVkIHlldC4KCg8KBwQABAACAQESBJAB
BAsKDwoHBAAEAAIBAhIEkAEODwo0CgYEAAQAAgISBJMBBBAaJCBUaGUgYFJlcGxheWAgaXMg
Y3VycmVudGx5IHJ1bm5pbmcuCgoPCgcEAAQAAgIBEgSTAQQLCg8KBwQABAACAgISBJMBDg8K
OgoGBAAEAAIDEgSWAQQSGiogVGhlIGBSZXBsYXlgIGhhcyBzdWNjZXNzZnVsbHkgY29tcGxl
dGVkLgoKDwoHBAAEAAIDARIElgEEDQoPCgcEAAQAAgMCEgSWARARCjoKBgQABAACBBIEmQEE
DxoqIFRoZSBgUmVwbGF5YCBoYXMgZmluaXNoZWQgd2l0aCBhbiBlcnJvci4KCg8KBwQABAAC
BAESBJkBBAoKDwoHBAAEAAIEAhIEmQENDgqCAwoEBAACABIEpQECPhrzAiBPdXRwdXQgb25s
eS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGBSZXBsYXlgLCB3aGljaCBoYXMgdGhlIGZv
bGxvd2luZwogZm9ybWF0OgoKIGB7cHJvamVjdHN8Zm9sZGVyc3xvcmdhbml6YXRpb25zfS97
cmVzb3VyY2UtaWR9L2xvY2F0aW9ucy9nbG9iYWwvcmVwbGF5cy97cmVwbGF5LWlkfWAsCiB3
aGVyZSBge3Jlc291cmNlLWlkfWAgaXMgdGhlIElEIG9mIHRoZSBwcm9qZWN0LCBmb2xkZXIs
IG9yIG9yZ2FuaXphdGlvbgogdGhhdCBvd25zIHRoZSBSZXBsYXkuCgogRXhhbXBsZToKIGBw
cm9qZWN0cy9teS1leGFtcGxlLXByb2plY3QvbG9jYXRpb25zL2dsb2JhbC9yZXBsYXlzLzUw
NmE1ZjdmLTM4Y2UtNGQ3ZC04ZTAzLTQ3OWNlMTgzM2MzNmAKCg0KBQQAAgAFEgSlAQIICg0K
BQQAAgABEgSlAQkNCg0KBQQAAgADEgSlARARCg0KBQQAAgAIEgSlARI9ChAKCAQAAgAInAgA
EgSlARM8Cj8KBAQAAgESBKgBAj4aMSBPdXRwdXQgb25seS4gVGhlIGN1cnJlbnQgc3RhdGUg
b2YgdGhlIGBSZXBsYXlgLgoKDQoFBAACAQYSBKgBAgcKDQoFBAACAQESBKgBCA0KDQoFBAAC
AQMSBKgBEBEKDQoFBAACAQgSBKgBEj0KEAoIBAACAQicCAASBKgBEzwKQgoEBAACAhIEqwEC
Qxo0IFJlcXVpcmVkLiBUaGUgY29uZmlndXJhdGlvbiB1c2VkIGZvciB0aGUgYFJlcGxheWAu
CgoNCgUEAAICBhIEqwECDgoNCgUEAAICARIEqwEPFQoNCgUEAAICAxIEqwEYGQoNCgUEAAIC
CBIEqwEaQgoQCggEAAICCJwIABIEqwEbQQpRCgQEAAIDEgauAQKvATIaQSBPdXRwdXQgb25s
eS4gU3VtbWFyeSBzdGF0aXN0aWNzIGFib3V0IHRoZSByZXBsYXllZCBsb2cgZW50cmllcy4K
Cg0KBQQAAgMGEgSuAQIQCg0KBQQAAgMBEgSuAREgCg0KBQQAAgMDEgSuASMkCg0KBQQAAgMI
EgSvAQYxChAKCAQAAgMInAgAEgSvAQcwClgKAgQBEgazAQDkAQEaSiBUaGUgcmVzdWx0IG9m
IHJlcGxheWluZyBhIHNpbmdsZSBhY2Nlc3MgdHVwbGUgYWdhaW5zdCBhIHNpbXVsYXRlZCBz
dGF0ZS4KCgsKAwQBARIEswEIFAoNCgMEAQcSBrQBArkBBAoPCgUEAQedCBIGtAECuQEECjsK
BAQBCAASBrwBAssBAxorIFRoZSByZXN1bHQgb2YgcmVwbGF5aW5nIHRoZSBhY2Nlc3MgdHVw
bGUuCgoNCgUEAQgAARIEvAEIDgrMAgoEBAECABIExAEEGBq9AiBUaGUgZGlmZmVyZW5jZSBi
ZXR3ZWVuIHRoZSBwcmluY2lwYWwncyBhY2Nlc3MgdW5kZXIgdGhlIGN1cnJlbnQKIChiYXNl
bGluZSkgcG9saWNpZXMgYW5kIHRoZSBwcmluY2lwYWwncyBhY2Nlc3MgdW5kZXIgdGhlIHBy
b3Bvc2VkCiAoc2ltdWxhdGVkKSBwb2xpY2llcy4KCiBUaGlzIGZpZWxkIGlzIG9ubHkgaW5j
bHVkZWQgZm9yIGFjY2VzcyB0dXBsZXMgdGhhdCB3ZXJlIHN1Y2Nlc3NmdWxseQogcmVwbGF5
ZWQgYW5kIGhhZCBkaWZmZXJlbnQgcmVzdWx0cyB1bmRlciB0aGUgY3VycmVudCBwb2xpY2ll
cyBhbmQgdGhlCiBwcm9wb3NlZCBwb2xpY2llcy4KCg0KBQQBAgAGEgTEAQQOCg0KBQQBAgAB
EgTEAQ8TCg0KBQQBAgADEgTEARYXCp0BCgQEAQIBEgTKAQQgGo4BIFRoZSBlcnJvciB0aGF0
IGNhdXNlZCB0aGUgYWNjZXNzIHR1cGxlIHJlcGxheSB0byBmYWlsLgoKIFRoaXMgZmllbGQg
aXMgb25seSBpbmNsdWRlZCBmb3IgYWNjZXNzIHR1cGxlcyB0aGF0IHdlcmUgbm90IHJlcGxh
eWVkCiBzdWNjZXNzZnVsbHkuCgoNCgUEAQIBBhIEygEEFQoNCgUEAQIBARIEygEWGwoNCgUE
AQIBAxIEygEeHwrFAwoEBAECAhIE1QECEhq2AyBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
YFJlcGxheVJlc3VsdGAsIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgoKIGB7cHJvamVjdHN8
Zm9sZGVyc3xvcmdhbml6YXRpb25zfS97cmVzb3VyY2UtaWR9L2xvY2F0aW9ucy9nbG9iYWwv
cmVwbGF5cy97cmVwbGF5LWlkfS9yZXN1bHRzL3tyZXBsYXktcmVzdWx0LWlkfWAsCiB3aGVy
ZSBge3Jlc291cmNlLWlkfWAgaXMgdGhlIElEIG9mIHRoZSBwcm9qZWN0LCBmb2xkZXIsIG9y
IG9yZ2FuaXphdGlvbgogdGhhdCBvd25zIHRoZSBbUmVwbGF5XVtnb29nbGUuY2xvdWQucG9s
aWN5c2ltdWxhdG9yLnYxLlJlcGxheV0uCgogRXhhbXBsZToKIGBwcm9qZWN0cy9teS1leGFt
cGxlLXByb2plY3QvbG9jYXRpb25zL2dsb2JhbC9yZXBsYXlzLzUwNmE1ZjdmLTM4Y2UtNGQ3
ZC04ZTAzLTQ3OWNlMTgzM2MzNi9yZXN1bHRzLzEyMzRgCgoNCgUEAQICBRIE1QECCAoNCgUE
AQICARIE1QEJDQoNCgUEAQICAxIE1QEQEQpuCgQEAQIDEgbZAQLbAQUaXiBUaGUgW1JlcGxh
eV1bZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBsYXldIHRoYXQgdGhlIGFj
Y2VzcyB0dXBsZQogd2FzIGluY2x1ZGVkIGluLgoKDQoFBAECAwUSBNkBAggKDQoFBAECAwES
BNkBCQ8KDQoFBAECAwMSBNkBEhMKDwoFBAECAwgSBtkBFNsBBAoRCgcEAQIDCJ8IEgbZARXb
AQMKrgEKBAQBAgQSBOABAh8anwEgVGhlIGFjY2VzcyB0dXBsZSB0aGF0IHdhcyByZXBsYXll
ZC4gVGhpcyBmaWVsZCBpbmNsdWRlcyBpbmZvcm1hdGlvbiBhYm91dAogdGhlIHByaW5jaXBh
bCwgcmVzb3VyY2UsIGFuZCBwZXJtaXNzaW9uIHRoYXQgd2VyZSBpbnZvbHZlZCBpbiB0aGUg
YWNjZXNzCiBhdHRlbXB0LgoKDQoFBAECBAYSBOABAg0KDQoFBAECBAESBOABDhoKDQoFBAEC
BAMSBOABHR4KRwoEBAECBRIE4wECJho5IFRoZSBsYXRlc3QgZGF0ZSB0aGlzIGFjY2VzcyB0
dXBsZSB3YXMgc2VlbiBpbiB0aGUgbG9ncy4KCg0KBQQBAgUGEgTjAQISCg0KBQQBAgUBEgTj
ARMhCg0KBQQBAgUDEgTjASQlCnYKAgQCEgboAQDzAQEaaCBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbU2ltdWxhdG9yLkNyZWF0ZVJlcGxheV1bZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRv
ci52MS5TaW11bGF0b3IuQ3JlYXRlUmVwbGF5XS4KCgsKAwQCARIE6AEIGwqBAgoEBAICABIE
7gECPRryASBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSB3aGVyZSB0aGlzCiBbUmVw
bGF5XVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheV0gd2lsbCBiZSBj
cmVhdGVkLiBUaGlzCiByZXNvdXJjZSBtdXN0IGJlIGEgcHJvamVjdCwgZm9sZGVyLCBvciBv
cmdhbml6YXRpb24gd2l0aCBhIGxvY2F0aW9uLgoKIEV4YW1wbGU6IGBwcm9qZWN0cy9teS1l
eGFtcGxlLXByb2plY3QvbG9jYXRpb25zL2dsb2JhbGAKCg0KBQQCAgAFEgTuAQIICg0KBQQC
AgABEgTuAQkPCg0KBQQCAgADEgTuARITCg0KBQQCAgAIEgTuARQ8ChAKCAQCAgAInAgAEgTu
ARU7Co0BCgQEAgIBEgTyAQI9Gn8gUmVxdWlyZWQuIFRoZSBbUmVwbGF5XVtnb29nbGUuY2xv
dWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheV0gdG8gY3JlYXRlLgogU2V0IGBSZXBsYXku
UmVwbGF5Q29uZmlnYCB0byBjb25maWd1cmUgdGhlIHJlcGxheS4KCg0KBQQCAgEGEgTyAQII
Cg0KBQQCAgEBEgTyAQkPCg0KBQQCAgEDEgTyARITCg0KBQQCAgEIEgTyARQ8ChAKCAQCAgEI
nAgAEgTyARU7CjIKAgQDEgb2AQD5AQEaJCBNZXRhZGF0YSBhYm91dCBhIFJlcGxheSBvcGVy
YXRpb24uCgoLCgMEAwESBPYBCB8KMwoEBAMCABIE+AECKxolIFRpbWUgd2hlbiB0aGUgcmVx
dWVzdCB3YXMgcmVjZWl2ZWQuCgoNCgUEAwIABhIE+AECGwoNCgUEAwIAARIE+AEcJgoNCgUE
AwIAAxIE+AEpKgpwCgIEBBIG/QEAjQIBGmIgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NpbXVs
YXRvci5HZXRSZXBsYXldW2dvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuU2ltdWxh
dG9yLkdldFJlcGxheV0uCgoLCgMEBAESBP0BCBgKpwMKBAQEAgASBocCAowCBBqWAyBSZXF1
aXJlZC4gVGhlIG5hbWUgb2YgdGhlIFtSZXBsYXldW2dvb2dsZS5jbG91ZC5wb2xpY3lzaW11
bGF0b3IudjEuUmVwbGF5XQogdG8gcmV0cmlldmUsIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0
OgoKIGB7cHJvamVjdHN8Zm9sZGVyc3xvcmdhbml6YXRpb25zfS97cmVzb3VyY2UtaWR9L2xv
Y2F0aW9ucy9nbG9iYWwvcmVwbGF5cy97cmVwbGF5LWlkfWAsCiB3aGVyZSBge3Jlc291cmNl
LWlkfWAgaXMgdGhlIElEIG9mIHRoZSBwcm9qZWN0LCBmb2xkZXIsIG9yIG9yZ2FuaXphdGlv
bgogdGhhdCBvd25zIHRoZSBgUmVwbGF5YC4KCiBFeGFtcGxlOgogYHByb2plY3RzL215LWV4
YW1wbGUtcHJvamVjdC9sb2NhdGlvbnMvZ2xvYmFsL3JlcGxheXMvNTA2YTVmN2YtMzhjZS00
ZDdkLThlMDMtNDc5Y2UxODMzYzM2YAoKDQoFBAQCAAUSBIcCAggKDQoFBAQCAAESBIcCCQ0K
DQoFBAQCAAMSBIcCEBEKDwoFBAQCAAgSBocCEowCAwoQCggEBAIACJwIABIEiAIEKgoRCgcE
BAIACJ8IEgaJAgSLAgUKgAEKAgQFEgaRAgCvAgEaciBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBb
U2ltdWxhdG9yLkxpc3RSZXBsYXlSZXN1bHRzXVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxh
dG9yLnYxLlNpbXVsYXRvci5MaXN0UmVwbGF5UmVzdWx0c10uCgoLCgMEBQESBJECCCAKvQIK
BAQFAgASBpkCAp4CBBqsAiBSZXF1aXJlZC4gVGhlIFtSZXBsYXldW2dvb2dsZS5jbG91ZC5w
b2xpY3lzaW11bGF0b3IudjEuUmVwbGF5XSB3aG9zZQogcmVzdWx0cyBhcmUgbGlzdGVkLCBp
biB0aGUgZm9sbG93aW5nIGZvcm1hdDoKCiBge3Byb2plY3RzfGZvbGRlcnN8b3JnYW5pemF0
aW9uc30ve3Jlc291cmNlLWlkfS9sb2NhdGlvbnMvZ2xvYmFsL3JlcGxheXMve3JlcGxheS1p
ZH1gCgogRXhhbXBsZToKIGBwcm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0aW9ucy9nbG9iYWwv
cmVwbGF5cy81MDZhNWY3Zi0zOGNlLTRkN2QtOGUwMy00NzljZTE4MzNjMzZgCgoNCgUEBQIA
BRIEmQICCAoNCgUEBQIAARIEmQIJDwoNCgUEBQIAAxIEmQISEwoPCgUEBQIACBIGmQIUngID
ChAKCAQFAgAInAgAEgSaAgQqChEKBwQFAgAInwgSBpsCBJ0CBQrTAQoEBAUCARIEpQICFhrE
ASBUaGUgbWF4aW11bSBudW1iZXIgb2YKIFtSZXBsYXlSZXN1bHRdW2dvb2dsZS5jbG91ZC5w
b2xpY3lzaW11bGF0b3IudjEuUmVwbGF5UmVzdWx0XSBvYmplY3RzIHRvCiByZXR1cm4uIERl
ZmF1bHRzIHRvIDUwMDAuCgogVGhlIG1heGltdW0gdmFsdWUgaXMgNTAwMDsgdmFsdWVzIGFi
b3ZlIDUwMDAgYXJlIHJvdW5kZWQgZG93biB0byA1MDAwLgoKDQoFBAUCAQUSBKUCAgcKDQoF
BAUCAQESBKUCCBEKDQoFBAUCAQMSBKUCFBUK2gIKBAQFAgISBK4CAhgaywIgQSBwYWdlIHRv
a2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIFtTaW11bGF0b3IuTGlzdFJlcGxheVJl
c3VsdHNdW2dvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuU2ltdWxhdG9yLkxpc3RS
ZXBsYXlSZXN1bHRzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRva2VuIHRvIHJldHJpZXZlIHRo
ZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBw
YXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBbU2ltdWxhdG9yLkxpc3RSZXBsYXlSZXN1bHRzW10g
bXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlCiB0b2tlbi4KCg0K
BQQFAgIFEgSuAgIICg0KBQQFAgIBEgSuAgkTCg0KBQQFAgIDEgSuAhYXCoEBCgIEBhIGswIA
uwIBGnMgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtTaW11bGF0b3IuTGlzdFJlcGxheVJlc3Vs
dHNdW2dvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEuU2ltdWxhdG9yLkxpc3RSZXBs
YXlSZXN1bHRzXS4KCgsKAwQGARIEswIIIQpaCgQEBgIAEgS1AgIrGkwgVGhlIHJlc3VsdHMg
b2YgcnVubmluZyBhIFtSZXBsYXldW2dvb2dsZS5jbG91ZC5wb2xpY3lzaW11bGF0b3IudjEu
UmVwbGF5XS4KCg0KBQQGAgAEEgS1AgIKCg0KBQQGAgAGEgS1AgsXCg0KBQQGAgABEgS1Ahgm
Cg0KBQQGAgADEgS1AikqCscBCgQEBgIBEgS6AgIdGrgBIEEgdG9rZW4gdGhhdCB5b3UgY2Fu
IHVzZSB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mCiBbUmVwbGF5UmVzdWx0XVtnb29n
bGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheVJlc3VsdF0gb2JqZWN0cy4gSWYK
IHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMu
CgoNCgUEBgIBBRIEugICCAoNCgUEBgIBARIEugIJGAoNCgUEBgIBAxIEugIbHApfCgIEBxIG
vwIA4QIBGlEgVGhlIGNvbmZpZ3VyYXRpb24gdXNlZCBmb3IgYQogW1JlcGxheV1bZ29vZ2xl
LmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5SZXBsYXldLgoKCwoDBAcBEgS/AggUCmgKBAQH
BAASBsICAswCAxpYIFRoZSBzb3VyY2Ugb2YgdGhlIGxvZ3MgdG8gdXNlIGZvciBhCiBbUmVw
bGF5XVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheV0uCgoNCgUEBwQA
ARIEwgIHEAqsAQoGBAcEAAIAEgTHAgQfGpsBIEFuIHVuc3BlY2lmaWVkIGxvZyBzb3VyY2Uu
CiBJZiB0aGUgbG9nIHNvdXJjZSBpcyB1bnNwZWNpZmllZCwgdGhlCiBbUmVwbGF5XVtnb29n
bGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheV0gZGVmYXVsdHMgdG8gdXNpbmcK
IGBSRUNFTlRfQUNDRVNTRVNgLgoKDwoHBAcEAAIAARIExwIEGgoPCgcEBwQAAgACEgTHAh0e
CnYKBgQHBAACARIEywIEGBpmIEFsbCBhY2Nlc3MgbG9ncyBmcm9tIHRoZSBsYXN0IDkwIGRh
eXMuIFRoZXNlIGxvZ3MgbWF5IG5vdCBpbmNsdWRlIGxvZ3MKIGZyb20gdGhlIG1vc3QgcmVj
ZW50IDcgZGF5cy4KCg8KBwQHBAACAQESBMsCBBMKDwoHBAcEAAIBAhIEywIWFwrLBQoEBAcC
ABIE3AICNxq8BSBBIG1hcHBpbmcgb2YgdGhlIHJlc291cmNlcyB0aGF0IHlvdSB3YW50IHRv
IHNpbXVsYXRlIHBvbGljaWVzIGZvciBhbmQgdGhlCiBwb2xpY2llcyB0aGF0IHlvdSB3YW50
IHRvIHNpbXVsYXRlLgoKIEtleXMgYXJlIHRoZSBmdWxsIHJlc291cmNlIG5hbWVzIGZvciB0
aGUgcmVzb3VyY2VzLiBGb3IgZXhhbXBsZSwKIGAvL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdv
b2dsZWFwaXMuY29tL3Byb2plY3RzL215LXByb2plY3RgLgogRm9yIGV4YW1wbGVzIG9mIGZ1
bGwgcmVzb3VyY2UgbmFtZXMgZm9yIEdvb2dsZSBDbG91ZCBzZXJ2aWNlcywgc2VlCiBodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vaWFtL2hlbHAvdHJvdWJsZXNob290ZXIvZnVsbC1yZXNv
dXJjZS1uYW1lcy4KCiBWYWx1ZXMgYXJlIFtQb2xpY3ldW2dvb2dsZS5pYW0udjEuUG9saWN5
XSBvYmplY3RzIHJlcHJlc2VudGluZyB0aGUgcG9saWNpZXMKIHRoYXQgeW91IHdhbnQgdG8g
c2ltdWxhdGUuCgogUmVwbGF5cyBhdXRvbWF0aWNhbGx5IHRha2UgaW50byBhY2NvdW50IGFu
eSBJQU0gcG9saWNpZXMgaW5oZXJpdGVkIHRocm91Z2gKIHRoZSByZXNvdXJjZSBoaWVyYXJj
aHksIGFuZCBhbnkgcG9saWNpZXMgc2V0IG9uIGRlc2NlbmRhbnQgcmVzb3VyY2VzLiBZb3UK
IGRvIG5vdCBuZWVkIHRvIGluY2x1ZGUgdGhlc2UgcG9saWNpZXMgaW4gdGhlIHBvbGljeSBv
dmVybGF5LgoKDQoFBAcCAAYSBNwCAiMKDQoFBAcCAAESBNwCJDIKDQoFBAcCAAMSBNwCNTYK
YwoEBAcCARIE4AICGxpVIFRoZSBsb2dzIHRvIHVzZSBhcyBpbnB1dCBmb3IgdGhlCiBbUmVw
bGF5XVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLlJlcGxheV0uCgoNCgUEBwIB
BhIE4AICCwoNCgUEBwIBARIE4AIMFgoNCgUEBwIBAxIE4AIZGgqNAgoCBAgSBucCAO8CARr+
ASBUaGUgZGlmZmVyZW5jZSBiZXR3ZWVuIHRoZSByZXN1bHRzIG9mIGV2YWx1YXRpbmcgYW4g
YWNjZXNzIHR1cGxlIHVuZGVyCiB0aGUgY3VycmVudCAoYmFzZWxpbmUpIHBvbGljaWVzIGFu
ZCB1bmRlciB0aGUgcHJvcG9zZWQgKHNpbXVsYXRlZCkgcG9saWNpZXMuCiBUaGlzIGRpZmZl
cmVuY2UgZXhwbGFpbnMgaG93IGEgcHJpbmNpcGFsJ3MgYWNjZXNzIGNvdWxkIGNoYW5nZSBp
ZiB0aGUKIHByb3Bvc2VkIHBvbGljaWVzIHdlcmUgYXBwbGllZC4KCgsKAwQIARIE5wIIEgqt
AgoEBAgCABIE7gICIhqeAiBBIHN1bW1hcnkgYW5kIGNvbXBhcmlzb24gb2YgdGhlIHByaW5j
aXBhbCdzIGFjY2VzcyB1bmRlciB0aGUgY3VycmVudAogKGJhc2VsaW5lKSBwb2xpY2llcyBh
bmQgdGhlIHByb3Bvc2VkIChzaW11bGF0ZWQpIHBvbGljaWVzIGZvciBhIHNpbmdsZQogYWNj
ZXNzIHR1cGxlLgoKIFRoZSBldmFsdWF0aW9uIG9mIHRoZSBwcmluY2lwYWwncyBhY2Nlc3Mg
aXMgcmVwb3J0ZWQgaW4gdGhlCiBbQWNjZXNzU3RhdGVdW2dvb2dsZS5jbG91ZC5wb2xpY3lz
aW11bGF0b3IudjEuQWNjZXNzU3RhdGVdIGZpZWxkLgoKDQoFBAgCAAYSBO4CAhEKDQoFBAgC
AAESBO4CEh0KDQoFBAgCAAMSBO4CICEKrAEKAgQJEgb0AgCyAwEanQEgQSBzdW1tYXJ5IGFu
ZCBjb21wYXJpc29uIG9mIHRoZSBwcmluY2lwYWwncyBhY2Nlc3MgdW5kZXIgdGhlIGN1cnJl
bnQKIChiYXNlbGluZSkgcG9saWNpZXMgYW5kIHRoZSBwcm9wb3NlZCAoc2ltdWxhdGVkKSBw
b2xpY2llcyBmb3IgYSBzaW5nbGUKIGFjY2VzcyB0dXBsZS4KCgsKAwQJARIE9AIIFwqmAQoE
BAkEABIG9wICoAMDGpUBIEhvdyB0aGUgcHJpbmNpcGFsJ3MgYWNjZXNzLCBzcGVjaWZpZWQg
aW4gdGhlIEFjY2Vzc1N0YXRlIGZpZWxkLCBjaGFuZ2VkCiBiZXR3ZWVuIHRoZSBjdXJyZW50
IChiYXNlbGluZSkgcG9saWNpZXMgYW5kIHByb3Bvc2VkIChzaW11bGF0ZWQpIHBvbGljaWVz
LgoKDQoFBAkEAAESBPcCBxcKNgoGBAkEAAIAEgT5AgQnGiYgRGVmYXVsdCB2YWx1ZS4gVGhp
cyB2YWx1ZSBpcyB1bnVzZWQuCgoPCgcECQQAAgABEgT5AgQiCg8KBwQJBAACAAISBPkCJSYK
rAEKBgQJBAACARIE/gIEEhqbASBUaGUgcHJpbmNpcGFsJ3MgYWNjZXNzIGRpZCBub3QgY2hh
bmdlLgogVGhpcyBpbmNsdWRlcyB0aGUgY2FzZSB3aGVyZSBib3RoIGJhc2VsaW5lIGFuZCBz
aW11bGF0ZWQgYXJlIFVOS05PV04sCiBidXQgdGhlIHVua25vd24gaW5mb3JtYXRpb24gaXMg
ZXF1aXZhbGVudC4KCg8KBwQJBAACAQESBP4CBA0KDwoHBAkEAAIBAhIE/gIQEQqkAQoGBAkE
AAICEgSCAwQXGpMBIFRoZSBwcmluY2lwYWwncyBhY2Nlc3MgdW5kZXIgYm90aCB0aGUgY3Vy
cmVudCBwb2xpY2llcyBhbmQgdGhlIHByb3Bvc2VkCiBwb2xpY2llcyBpcyBgVU5LTk9XTmAs
IGJ1dCB0aGUgdW5rbm93biBpbmZvcm1hdGlvbiBkaWZmZXJzIGJldHdlZW4gdGhlbS4KCg8K
BwQJBAACAgESBIIDBBIKDwoHBAkEAAICAhIEggMVFgqfAQoGBAkEAAIDEgSGAwQXGo4BIFRo
ZSBwcmluY2lwYWwgaGFkIGFjY2VzcyB1bmRlciB0aGUgY3VycmVudCBwb2xpY2llcyAoYEdS
QU5URURgKSwgYnV0IHdpbGwKIG5vIGxvbmdlciBoYXZlIGFjY2VzcyBhZnRlciB0aGUgcHJv
cG9zZWQgY2hhbmdlcyAoYE5PVF9HUkFOVEVEYCkuCgoPCgcECQQAAgMBEgSGAwQSCg8KBwQJ
BAACAwISBIYDFRYKnwEKBgQJBAACBBIEiwMEFhqOASBUaGUgcHJpbmNpcGFsIGRpZCBub3Qg
aGF2ZSBhY2Nlc3MgdW5kZXIgdGhlIGN1cnJlbnQgcG9saWNpZXMKIChgTk9UX0dSQU5URURg
KSwgYnV0IHdpbGwgaGF2ZSBhY2Nlc3MgYWZ0ZXIgdGhlIHByb3Bvc2VkIGNoYW5nZXMKIChg
R1JBTlRFRGApLgoKDwoHBAkEAAIEARIEiwMEEQoPCgcECQQAAgQCEgSLAxQVCtcCCgYECQQA
AgUSBJUDBB0axgIgVGhpcyByZXN1bHQgY2FuIG9jY3VyIGZvciB0aGUgZm9sbG93aW5nIHJl
YXNvbnM6CgogKiBUaGUgcHJpbmNpcGFsIGhhZCBhY2Nlc3MgdW5kZXIgdGhlIGN1cnJlbnQg
cG9saWNpZXMgKGBHUkFOVEVEYCksIGJ1dAogICB0aGVpciBhY2Nlc3MgYWZ0ZXIgdGhlIHBy
b3Bvc2VkIGNoYW5nZXMgaXMgYFVOS05PV05gLgoKICogVGhlIHByaW5jaXBhbCdzIGFjY2Vz
cyB1bmRlciB0aGUgY3VycmVudCBwb2xpY2llcyBpcyBgVU5LTk9XTmAsIGJ1dAogdGhleQog
ICB3aWxsIG5vdCBoYXZlIGFjY2VzcyBhZnRlciB0aGUgcHJvcG9zZWQgY2hhbmdlcyAoYE5P
VF9HUkFOVEVEYCkuCgoPCgcECQQAAgUBEgSVAwQYCg8KBwQJBAACBQISBJUDGxwK3AIKBgQJ
BAACBhIEnwMEHBrLAiBUaGlzIHJlc3VsdCBjYW4gb2NjdXIgZm9yIHRoZSBmb2xsb3dpbmcg
cmVhc29uczoKCiAqIFRoZSBwcmluY2lwYWwgZGlkIG5vdCBoYXZlIGFjY2VzcyB1bmRlciB0
aGUgY3VycmVudCBwb2xpY2llcwogICAoYE5PVF9HUkFOVEVEYCksIGJ1dCB0aGVpciBhY2Nl
c3MgYWZ0ZXIgdGhlIHByb3Bvc2VkIGNoYW5nZXMgaXMKICAgYFVOS05PV05gLgoKICogVGhl
IHByaW5jaXBhbCdzIGFjY2VzcyB1bmRlciB0aGUgY3VycmVudCBwb2xpY2llcyBpcyBgVU5L
Tk9XTmAsIGJ1dAogdGhleSB3aWxsIGhhdmUgYWNjZXNzIGFmdGVyIHRoZSBwcm9wb3NlZCBj
aGFuZ2VzIChgR1JBTlRFRGApLgoKDwoHBAkEAAIGARIEnwMEFwoPCgcECQQAAgYCEgSfAxob
Ct4BCgQECQIAEgSnAwIfGs8BIFRoZSByZXN1bHRzIG9mIGV2YWx1YXRpbmcgdGhlIGFjY2Vz
cyB0dXBsZSB1bmRlciB0aGUgY3VycmVudCAoYmFzZWxpbmUpCiBwb2xpY2llcy4KCiBJZiB0
aGUgW0FjY2Vzc1N0YXRlXVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLkFjY2Vz
c1N0YXRlXSBjb3VsZG4ndAogYmUgZnVsbHkgZXZhbHVhdGVkLCB0aGlzIGZpZWxkIGV4cGxh
aW5zIHdoeS4KCg0KBQQJAgAGEgSnAwIRCg0KBQQJAgABEgSnAxIaCg0KBQQJAgADEgSnAx0e
CrABCgQECQIBEgStAwIgGqEBIFRoZSByZXN1bHRzIG9mIGV2YWx1YXRpbmcgdGhlIGFjY2Vz
cyB0dXBsZSB1bmRlciB0aGUgcHJvcG9zZWQgKHNpbXVsYXRlZCkKIHBvbGljaWVzLgoKIElm
IHRoZSBBY2Nlc3NTdGF0ZSBjb3VsZG4ndCBiZSBmdWxseSBldmFsdWF0ZWQsIHRoaXMgZmll
bGQgZXhwbGFpbnMgd2h5LgoKDQoFBAkCAQYSBK0DAhEKDQoFBAkCAQESBK0DEhsKDQoFBAkC
AQMSBK0DHh8KpAEKBAQJAgISBLEDAiUalQEgSG93IHRoZSBwcmluY2lwYWwncyBhY2Nlc3Ms
IHNwZWNpZmllZCBpbiB0aGUgQWNjZXNzU3RhdGUgZmllbGQsIGNoYW5nZWQKIGJldHdlZW4g
dGhlIGN1cnJlbnQgKGJhc2VsaW5lKSBwb2xpY2llcyBhbmQgcHJvcG9zZWQgKHNpbXVsYXRl
ZCkgcG9saWNpZXMuCgoNCgUECQICBhIEsQMCEgoNCgUECQICARIEsQMTIAoNCgUECQICAxIE
sQMjJAr3AQoCBAoSBrgDAMsDARroASBEZXRhaWxzIGFib3V0IGhvdyBhIHNldCBvZiBwb2xp
Y2llcywgbGlzdGVkIGluCiBbRXhwbGFpbmVkUG9saWN5XVtnb29nbGUuY2xvdWQucG9saWN5
c2ltdWxhdG9yLnYxLkV4cGxhaW5lZFBvbGljeV0sIHJlc3VsdGVkCiBpbiBhIGNlcnRhaW4g
W0FjY2Vzc1N0YXRlXVtnb29nbGUuY2xvdWQucG9saWN5c2ltdWxhdG9yLnYxLkFjY2Vzc1N0
YXRlXSB3aGVuCiByZXBsYXlpbmcgYW4gYWNjZXNzIHR1cGxlLgoKCwoDBAoBEgS4AwgXCo8B
CgQECgIAEgS7AwIfGoABIFdoZXRoZXIgdGhlIHByaW5jaXBhbCBpbiB0aGUgYWNjZXNzIHR1
cGxlIGhhcyBwZXJtaXNzaW9uIHRvIGFjY2VzcyB0aGUKIHJlc291cmNlIGluIHRoZSBhY2Nl
c3MgdHVwbGUgdW5kZXIgdGhlIGdpdmVuIHBvbGljaWVzLgoKDQoFBAoCAAYSBLsDAg0KDQoF
BAoCAAESBLsDDhoKDQoFBAoCAAMSBLsDHR4K6QEKBAQKAgESBMIDAiga2gEgSWYgdGhlIFtB
Y2Nlc3NTdGF0ZV1bZ29vZ2xlLmNsb3VkLnBvbGljeXNpbXVsYXRvci52MS5BY2Nlc3NTdGF0
ZV0gaXMKIGBVTktOT1dOYCwgdGhpcyBmaWVsZCBjb250YWlucyB0aGUgcG9saWNpZXMgdGhh
dCBsZWQgdG8gdGhhdCByZXN1bHQuCgogSWYgdGhlIGBBY2Nlc3NTdGF0ZWAgaXMgYEdSQU5U
RURgIG9yIGBOT1RfR1JBTlRFRGAsIHRoaXMgZmllbGQgaXMKIG9taXR0ZWQuCgoNCgUECgIB
BBIEwgMCCgoNCgUECgIBBhIEwgMLGgoNCgUECgIBARIEwgMbIwoNCgUECgIBAxIEwgMmJwr9
AQoEBAoCAhIEygMCKBruASBJZiB0aGUgW0FjY2Vzc1N0YXRlXVtnb29nbGUuY2xvdWQucG9s
aWN5c2ltdWxhdG9yLnYxLkFjY2Vzc1N0YXRlXSBpcwogYFVOS05PV05gLCB0aGlzIGZpZWxk
IGNvbnRhaW5zIGEgbGlzdCBvZiBlcnJvcnMgZXhwbGFpbmluZyB3aHkgdGhlIHJlc3VsdAog
aXMgYFVOS05PV05gLgoKIElmIHRoZSBgQWNjZXNzU3RhdGVgIGlzIGBHUkFOVEVEYCBvciBg
Tk9UX0dSQU5URURgLCB0aGlzIGZpZWxkIGlzCiBvbWl0dGVkLgoKDQoFBAoCAgQSBMoDAgoK
DQoFBAoCAgYSBMoDCxwKDQoFBAoCAgESBMoDHSMKDQoFBAoCAgMSBMoDJidiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Policysimulator::V1::Simulator::Replay ===
    # Fields for Replay
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.policysimulator.v1.Replay.State)
    # Field: config Type: 11 (.google.cloud.policysimulator.v1.ReplayConfig)
    # Field: results_summary Type: 11 (.google.cloud.policysimulator.v1.Replay.ResultsSummary)

# Enum: Replay::State
our $Replay_STATE_UNSPECIFIED = 0;
our $Replay_PENDING = 1;
our $Replay_RUNNING = 2;
our $Replay_SUCCEEDED = 3;
our $Replay_FAILED = 4;

# === Message: Google::Cloud::Policysimulator::V1::Simulator::ReplayResult ===
    # Fields for ReplayResult
    # Field: diff Type: 11 (.google.cloud.policysimulator.v1.ReplayDiff)
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: name Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: access_tuple Type: 11 (.google.cloud.policysimulator.v1.AccessTuple)
    # Field: last_seen_date Type: 11 (.google.type.Date)

# === Message: Google::Cloud::Policysimulator::V1::Simulator::CreateReplayRequest ===
    # Fields for CreateReplayRequest
    # Field: parent Type: 9 ()
    # Field: replay Type: 11 (.google.cloud.policysimulator.v1.Replay)

# === Message: Google::Cloud::Policysimulator::V1::Simulator::ReplayOperationMetadata ===
    # Fields for ReplayOperationMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Policysimulator::V1::Simulator::GetReplayRequest ===
    # Fields for GetReplayRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsRequest ===
    # Fields for ListReplayResultsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsResponse ===
    # Fields for ListReplayResultsResponse
    # Field: replay_results Type: 11 (.google.cloud.policysimulator.v1.ReplayResult)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig ===
    # Fields for ReplayConfig
    # Field: policy_overlay Type: 11 (.google.cloud.policysimulator.v1.ReplayConfig.PolicyOverlayEntry)
    # Field: log_source Type: 14 (.google.cloud.policysimulator.v1.ReplayConfig.LogSource)

# Enum: ReplayConfig::LogSource
our $ReplayConfig_LOG_SOURCE_UNSPECIFIED = 0;
our $ReplayConfig_RECENT_ACCESSES = 1;

# === Message: Google::Cloud::Policysimulator::V1::Simulator::ReplayDiff ===
    # Fields for ReplayDiff
    # Field: access_diff Type: 11 (.google.cloud.policysimulator.v1.AccessStateDiff)

# === Message: Google::Cloud::Policysimulator::V1::Simulator::AccessStateDiff ===
    # Fields for AccessStateDiff
    # Field: baseline Type: 11 (.google.cloud.policysimulator.v1.ExplainedAccess)
    # Field: simulated Type: 11 (.google.cloud.policysimulator.v1.ExplainedAccess)
    # Field: access_change Type: 14 (.google.cloud.policysimulator.v1.AccessStateDiff.AccessChangeType)

# Enum: AccessStateDiff::AccessChangeType
our $AccessStateDiff_ACCESS_CHANGE_TYPE_UNSPECIFIED = 0;
our $AccessStateDiff_NO_CHANGE = 1;
our $AccessStateDiff_UNKNOWN_CHANGE = 2;
our $AccessStateDiff_ACCESS_REVOKED = 3;
our $AccessStateDiff_ACCESS_GAINED = 4;
our $AccessStateDiff_ACCESS_MAYBE_REVOKED = 5;
our $AccessStateDiff_ACCESS_MAYBE_GAINED = 6;

# === Message: Google::Cloud::Policysimulator::V1::Simulator::ExplainedAccess ===
    # Fields for ExplainedAccess
    # Field: access_state Type: 14 (.google.cloud.policysimulator.v1.AccessState)
    # Field: policies Type: 11 (.google.cloud.policysimulator.v1.ExplainedPolicy)
    # Field: errors Type: 11 (.google.rpc.Status)

# === Service Client: Google::Cloud::Policysimulator::V1::Simulator::SimulatorClient ===
package Google::Cloud::Policysimulator::V1::Simulator::SimulatorClient;

=pod

=head2 Service Client: Google::Cloud::Policysimulator::V1::Simulator::SimulatorClient

Client stub representing the remote C<Simulator> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<policysimulator.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'policysimulator.googleapis.com:443' );

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

sub get_replay {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Policysimulator::V1::Simulator::GetReplayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.policysimulator.v1.Simulator',
        method         => 'GetReplay',
        request        => $req,
        response_class => 'Google::Cloud::Policysimulator::V1::Simulator::Replay',
    });
}

sub create_replay {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Policysimulator::V1::Simulator::CreateReplayRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.policysimulator.v1.Simulator',
        method         => 'CreateReplay',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_replay_results {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.policysimulator.v1.Simulator',
        method         => 'ListReplayResults',
        request        => $req,
        response_class => 'Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Policysimulator::V1::Simulator - Compiled Protocol Buffers messages for google/cloud/policysimulator/v1/simulator.proto

=head1 SYNOPSIS

    use Google::Cloud::Policysimulator::V1::Simulator;

    my $msg = Google::Cloud::Policysimulator::V1::Simulator::Replay->new({
        name => $name,
        state => $state,
        config => $config,
        results_summary => $results_summary,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Policysimulator::V1::Simulator::Replay->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/policysimulator/v1/simulator.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Policysimulator::V1::Simulator::Replay

A resource describing a `Replay`, or simulation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the `Replay`, which has the following
format:

`{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`,
where `{resource-id}` is the ID of the project, folder, or organization
that owns the Replay.

Example:
`projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::Replay::State>)

Output only. The current state of the `Replay`.

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig>)

Required. The configuration used for the `Replay`.

=item * C<< $msg->results_summary() >> / C<< $msg->results_summary($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::Replay::ResultsSummary>)

Output only. Summary statistics about the replayed log entries.

=back

=head3 Enum: Replay::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::ReplayResult

The result of replaying a single access tuple against a simulated state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->diff() >> / C<< $msg->diff($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::ReplayDiff>)

The difference between the principal's access under the current
(baseline) policies and the principal's access under the proposed
(simulated) policies.

This field is only included for access tuples that were successfully
replayed and had different results under the current policies and the
proposed policies.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The error that caused the access tuple replay to fail.

This field is only included for access tuples that were not replayed
successfully.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the `ReplayResult`, in the following format:

`{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}/results/{replay-result-id}`,
where `{resource-id}` is the ID of the project, folder, or organization
that owns the [Replay][google.cloud.policysimulator.v1.Replay].

Example:
`projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36/results/1234`

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The [Replay][google.cloud.policysimulator.v1.Replay] that the access tuple
was included in.

=item * C<< $msg->access_tuple() >> / C<< $msg->access_tuple($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Explanations::AccessTuple>)

The access tuple that was replayed. This field includes information about
the principal, resource, and permission that were involved in the access
attempt.

=item * C<< $msg->last_seen_date() >> / C<< $msg->last_seen_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

The latest date this access tuple was seen in the logs.

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::CreateReplayRequest

Request message for
[Simulator.CreateReplay][google.cloud.policysimulator.v1.Simulator.CreateReplay].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this
[Replay][google.cloud.policysimulator.v1.Replay] will be created. This
resource must be a project, folder, or organization with a location.

Example: `projects/my-example-project/locations/global`

=item * C<< $msg->replay() >> / C<< $msg->replay($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::Replay>)

Required. The [Replay][google.cloud.policysimulator.v1.Replay] to create.
Set `Replay.ReplayConfig` to configure the replay.

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::ReplayOperationMetadata

Metadata about a Replay operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the request was received.

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::GetReplayRequest

Request message for
[Simulator.GetReplay][google.cloud.policysimulator.v1.Simulator.GetReplay].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the [Replay][google.cloud.policysimulator.v1.Replay]
to retrieve, in the following format:

`{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`,
where `{resource-id}` is the ID of the project, folder, or organization
that owns the `Replay`.

Example:
`projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsRequest

Request message for
[Simulator.ListReplayResults][google.cloud.policysimulator.v1.Simulator.ListReplayResults].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The [Replay][google.cloud.policysimulator.v1.Replay] whose
results are listed, in the following format:

`{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`

Example:
`projects/my-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of
[ReplayResult][google.cloud.policysimulator.v1.ReplayResult] objects to
return. Defaults to 5000.

The maximum value is 5000; values above 5000 are rounded down to 5000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous
[Simulator.ListReplayResults][google.cloud.policysimulator.v1.Simulator.ListReplayResults]
call. Provide this token to retrieve the next page of results.

When paginating, all other parameters provided to
[Simulator.ListReplayResults[] must match the call that provided the page
token.

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsResponse

Response message for
[Simulator.ListReplayResults][google.cloud.policysimulator.v1.Simulator.ListReplayResults].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->replay_results() >> / C<< $msg->replay_results($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::ReplayResult>)

The results of running a [Replay][google.cloud.policysimulator.v1.Replay].

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that you can use to retrieve the next page of
[ReplayResult][google.cloud.policysimulator.v1.ReplayResult] objects. If
this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig

The configuration used for a
[Replay][google.cloud.policysimulator.v1.Replay].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_overlay() >> / C<< $msg->policy_overlay($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig::PolicyOverlayEntry>)

A mapping of the resources that you want to simulate policies for and the
policies that you want to simulate.

Keys are the full resource names for the resources. For example,
`//cloudresourcemanager.googleapis.com/projects/my-project`.
For examples of full resource names for Google Cloud services, see
https://cloud.google.com/iam/help/troubleshooter/full-resource-names.

Values are [Policy][google.iam.v1.Policy] objects representing the policies
that you want to simulate.

Replays automatically take into account any IAM policies inherited through
the resource hierarchy, and any policies set on descendant resources. You
do not need to include these policies in the policy overlay.

=item * C<< $msg->log_source() >> / C<< $msg->log_source($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::ReplayConfig::LogSource>)

The logs to use as input for the
[Replay][google.cloud.policysimulator.v1.Replay].

=back

=head3 Enum: ReplayConfig::LogSource

=over 4

=item * C<LOG_SOURCE_UNSPECIFIED> => C<0>

=item * C<RECENT_ACCESSES> => C<1>

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::ReplayDiff

The difference between the results of evaluating an access tuple under
the current (baseline) policies and under the proposed (simulated) policies.
This difference explains how a principal's access could change if the
proposed policies were applied.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_diff() >> / C<< $msg->access_diff($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::AccessStateDiff>)

A summary and comparison of the principal's access under the current
(baseline) policies and the proposed (simulated) policies for a single
access tuple.

The evaluation of the principal's access is reported in the
[AccessState][google.cloud.policysimulator.v1.AccessState] field.

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::AccessStateDiff

A summary and comparison of the principal's access under the current
(baseline) policies and the proposed (simulated) policies for a single
access tuple.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->baseline() >> / C<< $msg->baseline($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::ExplainedAccess>)

The results of evaluating the access tuple under the current (baseline)
policies.

If the [AccessState][google.cloud.policysimulator.v1.AccessState] couldn't
be fully evaluated, this field explains why.

=item * C<< $msg->simulated() >> / C<< $msg->simulated($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Simulator::ExplainedAccess>)

The results of evaluating the access tuple under the proposed (simulated)
policies.

If the AccessState couldn't be fully evaluated, this field explains why.

=item * C<< $msg->access_change() >> / C<< $msg->access_change($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::AccessStateDiff::AccessChangeType>)

How the principal's access, specified in the AccessState field, changed
between the current (baseline) policies and proposed (simulated) policies.

=back

=head3 Enum: AccessStateDiff::AccessChangeType

=over 4

=item * C<ACCESS_CHANGE_TYPE_UNSPECIFIED> => C<0>

=item * C<NO_CHANGE> => C<1>

=item * C<UNKNOWN_CHANGE> => C<2>

=item * C<ACCESS_REVOKED> => C<3>

=item * C<ACCESS_GAINED> => C<4>

=item * C<ACCESS_MAYBE_REVOKED> => C<5>

=item * C<ACCESS_MAYBE_GAINED> => C<6>

=back

=head2 Google::Cloud::Policysimulator::V1::Simulator::ExplainedAccess

Details about how a set of policies, listed in
[ExplainedPolicy][google.cloud.policysimulator.v1.ExplainedPolicy], resulted
in a certain [AccessState][google.cloud.policysimulator.v1.AccessState] when
replaying an access tuple.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_state() >> / C<< $msg->access_state($value) >>

Type: C<Enum> (L<Google::Cloud::Policysimulator::V1::AccessState>)

Whether the principal in the access tuple has permission to access the
resource in the access tuple under the given policies.

=item * C<< $msg->policies() >> / C<< $msg->policies($value) >>

Type: C<Message> (L<Google::Cloud::Policysimulator::V1::Explanations::ExplainedPolicy>)

If the [AccessState][google.cloud.policysimulator.v1.AccessState] is
`UNKNOWN`, this field contains the policies that led to that result.

If the `AccessState` is `GRANTED` or `NOT_GRANTED`, this field is
omitted.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

If the [AccessState][google.cloud.policysimulator.v1.AccessState] is
`UNKNOWN`, this field contains a list of errors explaining why the result
is `UNKNOWN`.

If the `AccessState` is `GRANTED` or `NOT_GRANTED`, this field is
omitted.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Policysimulator::V1::Simulator::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
