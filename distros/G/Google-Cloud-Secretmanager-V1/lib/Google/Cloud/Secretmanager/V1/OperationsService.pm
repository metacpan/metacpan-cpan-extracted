package Google::Cloud::Secretmanager::V1::OperationsService;

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
    eval { require Google::Cloud::Secretmanager::V1::Resources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvc2VjcmV0bWFuYWdlci92MS9vcGVyYXRpb25zX3NlcnZpY2UucHJv
dG8SHWdvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxotZ29vZ2xlL2Nsb3Vk
L3NlY3JldG1hbmFnZXIvdjEvcmVzb3VyY2VzLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcv
b3BlcmF0aW9ucy5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUv
cHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byLcAQoSTGlzdEJhY2t1cHNSZXF1ZXN0EkMKBnBhcmVudBgBIAEoCUIr4EEC+kElEiNz
ZWNyZXRtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL0JhY2t1cFIGcGFyZW50EiAKCXBhZ2Vfc2l6
ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VU
b2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BBAVIGZmlsdGVyEh4KCG9yZGVyX2J5GAUgASgJQgPg
QQFSB29yZGVyQnkipQEKE0xpc3RCYWNrdXBzUmVzcG9uc2USPwoHYmFja3VwcxgBIAMoCzIl
Lmdvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLkJhY2t1cFIHYmFja3VwcxImCg9uZXh0
X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SJQoLdW5yZWFjaGFibGUYAyADKAlC
A+BBBlILdW5yZWFjaGFibGUiUwoQR2V0QmFja3VwUmVxdWVzdBI/CgRuYW1lGAEgASgJQivg
QQL6QSUKI3NlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vQmFja3VwUgRuYW1lIsABChND
cmVhdGVCYWNrdXBSZXF1ZXN0EkMKBnBhcmVudBgBIAEoCUIr4EEC+kElEiNzZWNyZXRtYW5h
Z2VyLmdvb2dsZWFwaXMuY29tL0JhY2t1cFIGcGFyZW50EiAKCWJhY2t1cF9pZBgCIAEoCUID
4EECUghiYWNrdXBJZBJCCgZiYWNrdXAYAyABKAsyJS5nb29nbGUuY2xvdWQuc2VjcmV0bWFu
YWdlci52MS5CYWNrdXBCA+BBAlIGYmFja3VwIpsBChNVcGRhdGVCYWNrdXBSZXF1ZXN0EkAK
C3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1
cGRhdGVNYXNrEkIKBmJhY2t1cBgCIAEoCzIlLmdvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2Vy
LnYxLkJhY2t1cEID4EECUgZiYWNrdXAibwoTRGVsZXRlQmFja3VwUmVxdWVzdBI/CgRuYW1l
GAEgASgJQivgQQL6QSUKI3NlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vQmFja3VwUgRu
YW1lEhcKBGV0YWcYAiABKAlCA+BBAVIEZXRhZyLGAgoUUmVzdG9yZUJhY2t1cFJlcXVlc3QS
PwoEbmFtZRgBIAEoCUIr4EEC+kElCiNzZWNyZXRtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL0Jh
Y2t1cFIEbmFtZRJnChlkZXN0aW5hdGlvbl9zZWNyZXRfcGFyZW50GAIgASgJQivgQQL6QSUS
I3NlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0UhdkZXN0aW5hdGlvblNlY3Jl
dFBhcmVudBI3ChVkZXN0aW5hdGlvbl9zZWNyZXRfaWQYAyABKAlCA+BBAlITZGVzdGluYXRp
b25TZWNyZXRJZBJLCgxrbXNfa2V5X25hbWUYBCABKAlCKeBBAfpBIwohY2xvdWRrbXMuZ29v
Z2xlYXBpcy5jb20vQ3J5cHRvS2V5UgprbXNLZXlOYW1lIucEChFPcGVyYXRpb25NZXRhZGF0
YRJACgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKY3JlYXRlVGltZRI6CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IHZW5kVGltZRIbCgZ0YXJnZXQYAyABKAlCA+BBA1IGdGFyZ2V0EhcKBHZl
cmIYBCABKAlCA+BBA1IEdmVyYhIqCg5zdGF0dXNfbWVzc2FnZRgFIAEoCUID4EEDUg1zdGF0
dXNNZXNzYWdlEjoKFnJlcXVlc3RlZF9jYW5jZWxsYXRpb24YBiABKAhCA+BBA1IVcmVxdWVz
dGVkQ2FuY2VsbGF0aW9uEiQKC2FwaV92ZXJzaW9uGAcgASgJQgPgQQNSCmFwaVZlcnNpb24S
WgoIcHJvZ3Jlc3MYCCABKAsyOS5nb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdlci52MS5PcGVy
YXRpb25NZXRhZGF0YS5Qcm9ncmVzc0ID4EEDUghwcm9ncmVzcxqzAQoIUHJvZ3Jlc3MSMwoT
dG90YWxfdmVyc2lvbl9jb3VudBgBIAEoBUID4EEDUhF0b3RhbFZlcnNpb25Db3VudBI7Chdj
b21wbGV0ZWRfdmVyc2lvbl9jb3VudBgCIAEoBUID4EEDUhVjb21wbGV0ZWRWZXJzaW9uQ291
bnQSNQoUZmFpbGVkX3ZlcnNpb25fY291bnQYAyABKAVCA+BBA1ISZmFpbGVkVmVyc2lvbkNv
dW50IrUGCgZCYWNrdXASFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lElMKDXNvdXJjZV9zZWNy
ZXQYAiABKAlCLuBBAuBBBfpBJQojc2VjcmV0bWFuYWdlci5nb29nbGVhcGlzLmNvbS9TZWNy
ZXRSDHNvdXJjZVNlY3JldBJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgEIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJaChlzb3VyY2Vfc2Vj
cmV0X2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
UhZzb3VyY2VTZWNyZXRDcmVhdGVUaW1lEigKDXZlcnNpb25fY291bnQYBiABKAVCA+BBA1IM
dmVyc2lvbkNvdW50Ek4KBmxhYmVscxgHIAMoCzIxLmdvb2dsZS5jbG91ZC5zZWNyZXRtYW5h
Z2VyLnYxLkJhY2t1cC5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSRgoFc3RhdGUYCCABKA4y
Ky5nb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdlci52MS5CYWNrdXAuU3RhdGVCA+BBA1IFc3Rh
dGUSFwoEZXRhZxgLIAEoCUID4EEBUgRldGFnGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEo
CVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiUgoFU3RhdGUSFQoRU1RBVEVfVU5T
UEVDSUZJRUQQABIMCghDUkVBVElORxABEgoKBkFDVElWRRACEgwKCFVQREFUSU5HEAMSCgoG
RkFJTEVEEAQ6c+pBcAojc2VjcmV0bWFuYWdlci5nb29nbGVhcGlzLmNvbS9CYWNrdXASOHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBzL3tiYWNrdXB9
KgdiYWNrdXBzMgZiYWNrdXAy3QoKF1NlY3JldE9wZXJhdGlvbnNTZXJ2aWNlErIBCgtMaXN0
QmFja3VwcxIxLmdvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLkxpc3RCYWNrdXBzUmVx
dWVzdBoyLmdvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLkxpc3RCYWNrdXBzUmVzcG9u
c2UiPILT5JMCLRIrL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vYmFja3Vw
c9pBBnBhcmVudBKfAQoJR2V0QmFja3VwEi8uZ29vZ2xlLmNsb3VkLnNlY3JldG1hbmFnZXIu
djEuR2V0QmFja3VwUmVxdWVzdBolLmdvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLkJh
Y2t1cCI6gtPkkwItEisvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9iYWNrdXBz
Lyp92kEEbmFtZRLWAQoMQ3JlYXRlQmFja3VwEjIuZ29vZ2xlLmNsb3VkLnNlY3JldG1hbmFn
ZXIudjEuQ3JlYXRlQmFja3VwUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24ic4LT5JMCNSIrL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vYmFja3Vw
czoGYmFja3Vw2kEXcGFyZW50LGJhY2t1cCxiYWNrdXBfaWTKQRsKBkJhY2t1cBIRT3BlcmF0
aW9uTWV0YWRhdGES2AEKDFVwZGF0ZUJhY2t1cBIyLmdvb2dsZS5jbG91ZC5zZWNyZXRtYW5h
Z2VyLnYxLlVwZGF0ZUJhY2t1cFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uInWC0+STAjwyMi92MS97YmFja3VwLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9i
YWNrdXBzLyp9OgZiYWNrdXDaQRJiYWNrdXAsdXBkYXRlX21hc2vKQRsKBkJhY2t1cBIRT3Bl
cmF0aW9uTWV0YWRhdGESygEKDERlbGV0ZUJhY2t1cBIyLmdvb2dsZS5jbG91ZC5zZWNyZXRt
YW5hZ2VyLnYxLkRlbGV0ZUJhY2t1cFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uImeC0+STAi0qKy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2JhY2t1
cHMvKn3aQQRuYW1lykEqChVnb29nbGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFk
YXRhEpcCCg1SZXN0b3JlQmFja3VwEjMuZ29vZ2xlLmNsb3VkLnNlY3JldG1hbmFnZXIudjEu
UmVzdG9yZUJhY2t1cFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrEB
gtPkkwI4IjMvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9iYWNrdXBzLyp9OnJl
c3RvcmU6ASraQTRuYW1lLGRlc3RpbmF0aW9uX3NlY3JldF9wYXJlbnQsZGVzdGluYXRpb25f
c2VjcmV0X2lkykE5CiRnb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdlci52MS5TZWNyZXQSEU9w
ZXJhdGlvbk1ldGFkYXRhGlDKQRxzZWNyZXRtYW5hZ2VyLmdvb2dsZWFwaXMuY29t0kEuaHR0
cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULqAgohY29tLmdv
b2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxQhZPcGVyYXRpb25zU2VydmljZVByb3RvUAFa
R2Nsb3VkLmdvb2dsZS5jb20vZ28vc2VjcmV0bWFuYWdlci9hcGl2MS9zZWNyZXRtYW5hZ2Vy
cGI7c2VjcmV0bWFuYWdlcnBiogIDR1NNqgIdR29vZ2xlLkNsb3VkLlNlY3JldE1hbmFnZXIu
VjHKAh1Hb29nbGVcQ2xvdWRcU2VjcmV0TWFuYWdlclxWMeoCIEdvb2dsZTo6Q2xvdWQ6OlNl
Y3JldE1hbmFnZXI6OlYx6kF4CiFjbG91ZGttcy5nb29nbGVhcGlzLmNvbS9DcnlwdG9LZXkS
U3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5
X3Jpbmd9L2NyeXB0b0tleXMve2NyeXB0b19rZXl9StRtCgcSBQ4AnwMBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAmCgkKAgMAEgMSACYKCQoCAwESAxMA
IQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANwoJCgIDBRIDFwAtCgkKAgMGEgMY
ACUKCQoCAwcSAxkAKgoJCgIDCBIDGgApCggKAQgSAxwAOgoJCgIIJRIDHAA6CggKAQgSAx0A
XgoJCgIICxIDHQBeCggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8ANwoJCgIICBIDHwA3
CggKAQgSAyAAOgoJCgIIARIDIAA6CggKAQgSAyEAIQoJCgIIJBIDIQAhCggKAQgSAyIAOgoJ
CgIIKRIDIgA6CggKAQgSAyMAOQoJCgIILRIDIwA5CgkKAQgSBCQAJwIKDAoECJ0IABIEJAAn
AgrEAgoCBgASBDIAfgEatwIgU2VjcmV0IE9wZXJhdGlvbnMgU2VydmljZQoKIE1hbmFnZXMg
YmFja3VwcyBvZiBzZWNyZXRzLiBJbXBsZW1lbnRzIGEgUkVTVCBtb2RlbCB3aXRoIHRoZSBm
b2xsb3dpbmcKIG9iamVjdHM6CgogKiBbQmFja3VwXVtnb29nbGUuY2xvdWQuc2VjcmV0bWFu
YWdlci52MS5CYWNrdXBdCgogTm90ZTogYFNlY3JldE9wZXJhdGlvbnNTZXJ2aWNlYCBpcyBh
IHJlZ2lvbmFsIHNlcnZpY2UgYW5kIG11c3QgYmUgY2FsbGVkCiB1c2luZyByZWdpb25hbCBl
bmRwb2ludHMgKGBzZWNyZXRtYW5hZ2VyLntsb2NhdGlvbn0ucmVwLmdvb2dsZWFwaXMuY29t
YCkuCgoKCgMGAAESAzIIHwoKCgMGAAMSAzMCRAoMCgUGAAOZCBIDMwJECgsKAwYAAxIENAI1
NwoNCgUGAAOaCBIENAI1Nwo+CgQGAAIAEgQ4Aj0DGjAgTGlzdHMgQmFja3VwcyBpbiBhIGdp
dmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACAAESAzgGEQoMCgUGAAIAAhIDOBIk
CgwKBQYAAgADEgM4L0IKDQoFBgACAAQSBDkEOwYKEQoJBgACAASwyrwiEgQ5BDsGCgwKBQYA
AgAEEgM8BDQKDwoIBgACAASbCAASAzwENAowCgQGAAIBEgRAAkUDGiIgR2V0cyBkZXRhaWxz
IG9mIGEgc2luZ2xlIEJhY2t1cC4KCgwKBQYAAgEBEgNABg8KDAoFBgACAQISA0AQIAoMCgUG
AAIBAxIDQCsxCg0KBQYAAgEEEgRBBEMGChEKCQYAAgEEsMq8IhIEQQRDBgoMCgUGAAIBBBID
RAQyCg8KCAYAAgEEmwgAEgNEBDIKRQoEBgACAhIESAJSAxo3IENyZWF0ZXMgYSBuZXcgQmFj
a3VwIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAICARIDSAYSCgwK
BQYAAgICEgNIEyYKDAoFBgACAgMSA0gxTQoNCgUGAAICBBIESQRMBgoRCgkGAAICBLDKvCIS
BEkETAYKDAoFBgACAgQSA00ERQoPCggGAAICBJsIABIDTQRFCg0KBQYAAgIEEgROBFEGCg8K
BwYAAgIEmQgSBE4EUQYKOgoEBgACAxIEVQJfAxosIFVwZGF0ZXMgdGhlIHBhcmFtZXRlcnMg
b2YgYSBzaW5nbGUgQmFja3VwLgoKDAoFBgACAwESA1UGEgoMCgUGAAIDAhIDVRMmCgwKBQYA
AgMDEgNVMU0KDQoFBgACAwQSBFYEWQYKEQoJBgACAwSwyrwiEgRWBFkGCgwKBQYAAgMEEgNa
BEAKDwoIBgACAwSbCAASA1oEQAoNCgUGAAIDBBIEWwReBgoPCgcGAAIDBJkIEgRbBF4GCigK
BAYAAgQSBGICawMaGiBEZWxldGVzIGEgc2luZ2xlIEJhY2t1cC4KCgwKBQYAAgQBEgNiBhIK
DAoFBgACBAISA2ITJgoMCgUGAAIEAxIDYjFNCg0KBQYAAgQEEgRjBGUGChEKCQYAAgQEsMq8
IhIEYwRlBgoMCgUGAAIEBBIDZgQyCg8KCAYAAgQEmwgAEgNmBDIKDQoFBgACBAQSBGcEagYK
DwoHBgACBASZCBIEZwRqBgq5AgoEBgACBRIEcQJ9AxqqAiBSZXN0b3JlcyBhIFtTZWNyZXRd
W2dvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLlNlY3JldF0gZnJvbSB0aGUgZ2l2ZW4K
IFtCYWNrdXBdW2dvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLkJhY2t1cF0uIFRoaXMg
Y3JlYXRlcyBhICpuZXcqCiBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdlci52
MS5TZWNyZXRdIHJlc291cmNlLiBUaGUgTFJPIHRyYWNrcyB0aGUKIHJlc3RvcmF0aW9uIHBy
b2Nlc3MsIGFuZCB0aGUgcmVzdWx0IG9mIHRoZSBMUk8gaXMgdGhlIG5ld2x5IGNyZWF0ZWQg
U2VjcmV0LgoKDAoFBgACBQESA3EGEwoMCgUGAAIFAhIDcRQoCgwKBQYAAgUDEgNyDysKDQoF
BgACBQQSBHMEdgYKEQoJBgACBQSwyrwiEgRzBHYGCg0KBQYAAgUEEgR3BHg/ChAKCAYAAgUE
mwgAEgR3BHg/Cg0KBQYAAgUEEgR5BHwGCg8KBwYAAgUEmQgSBHkEfAYKjwEKAgQAEgaCAQCb
AQEagAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NlY3JldE9wZXJhdGlvbnNTZXJ2aWNlLkxp
c3RCYWNrdXBzXVtnb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdlci52MS5TZWNyZXRPcGVyYXRp
b25zU2VydmljZS5MaXN0QmFja3Vwc10uCgoLCgMEAAESBIIBCBoKvgEKBAQAAgASBoYBAosB
BBqtASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGxvY2F0aW9uIGFzc29j
aWF0ZWQgd2l0aCB0aGUKIFtCYWNrdXBzXVtnb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdlci52
MS5CYWNrdXBdLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259YC4KCg0KBQQAAgAFEgSGAQIICg0KBQQAAgABEgSGAQkPCg0KBQQAAgAD
EgSGARITCg8KBQQAAgAIEgaGARSLAQMKEAoIBAACAAicCAASBIcBBCoKEQoHBAACAAifCBIG
iAEEigEFCuoBCgQEAAIBEgSQAQI/GtsBIE9wdGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZiBi
YWNrdXBzIHRvIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5IHJldHVybiBmZXdlcgogdGhhbiB0
aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBiYWNrdXBzIHdpbGwgYmUg
cmV0dXJuZWQuIFRoZQogbWF4aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAw
MCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCg0KBQQAAgEFEgSQAQIHCg0KBQQAAgEBEgSQ
AQgRCg0KBQQAAgEDEgSQARQVCg0KBQQAAgEIEgSQARY+ChAKCAQAAgEInAgAEgSQARc9ClkK
BAQAAgISBJMBAkEaSyBPcHRpb25hbC4gQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2Yg
cmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4uCgoNCgUEAAICBRIEkwECCAoNCgUE
AAICARIEkwEJEwoNCgUEAAICAxIEkwEWFwoNCgUEAAICCBIEkwEYQAoQCggEAAICCJwIABIE
kwEZPwp2CgQEAAIDEgSXAQI9GmggT3B0aW9uYWwuIEZpbHRlciBleHByZXNzaW9uIHRvIHJl
c3RyaWN0IHRoZSByZXR1cm5lZAogW0JhY2t1cHNdW2dvb2dsZS5jbG91ZC5zZWNyZXRtYW5h
Z2VyLnYxLkJhY2t1cF0uCgoNCgUEAAIDBRIElwECCAoNCgUEAAIDARIElwEJDwoNCgUEAAID
AxIElwESEwoNCgUEAAIDCBIElwEUPAoQCggEAAIDCJwIABIElwEVOwpWCgQEAAIEEgSaAQI/
GkggT3B0aW9uYWwuIEZpZWxkIHNwZWNpZmljYXRpb24gZm9yIHNvcnRpbmcgdGhlIHJlc3Vs
dHMgaW4gdGhlIHJlc3BvbnNlLgoKDQoFBAACBAUSBJoBAggKDQoFBAACBAESBJoBCREKDQoF
BAACBAMSBJoBFBUKDQoFBAACBAgSBJoBFj4KEAoIBAACBAicCAASBJoBFz0KkAEKAgQBEgaf
AQCrAQEagQEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtTZWNyZXRPcGVyYXRpb25zU2Vydmlj
ZS5MaXN0QmFja3Vwc11bZ29vZ2xlLmNsb3VkLnNlY3JldG1hbmFnZXIudjEuU2VjcmV0T3Bl
cmF0aW9uc1NlcnZpY2UuTGlzdEJhY2t1cHNdLgoKCwoDBAEBEgSfAQgbCl0KBAQBAgASBKIB
Ah4aTyBUaGUgbGlzdCBvZiBbQmFja3Vwc11bZ29vZ2xlLmNsb3VkLnNlY3JldG1hbmFnZXIu
djEuQmFja3VwXSBpbiB0aGUKIGxvY2F0aW9uLgoKDQoFBAECAAQSBKIBAgoKDQoFBAECAAYS
BKIBCxEKDQoFBAECAAESBKIBEhkKDQoFBAECAAMSBKIBHB0KTwoEBAECARIEpQECHRpBIEEg
dG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQg
cmV0dXJuLgoKDQoFBAECAQUSBKUBAggKDQoFBAECAQESBKUBCRgKDQoFBAECAQMSBKUBGxwK
gQEKBAQBAgISBqkBAqoBNRpxIFVub3JkZXJlZCBsaXN0LiBSZXNvdXJjZSBuYW1lcyBvZiB0
aGUgdW5yZWFjaGFibGUgbG9jYXRpb25zLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259YAoKDQoFBAECAgQSBKkBAgoKDQoFBAECAgUSBKkBCxEK
DQoFBAECAgESBKkBEh0KDQoFBAECAgMSBKkBICEKDQoFBAECAggSBKoBBjQKEAoIBAECAgic
CAASBKoBBzMKigEKAgQCEgavAQC5AQEafCBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2VjcmV0
T3BlcmF0aW9uc1NlcnZpY2UuR2V0QmFja3VwXVtnb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdl
ci52MS5TZWNyZXRPcGVyYXRpb25zU2VydmljZS5HZXRCYWNrdXBdLgoKCwoDBAIBEgSvAQgY
CrEBCgQEAgIAEgazAQK4AQQaoAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRo
ZQogW0JhY2t1cF1bZ29vZ2xlLmNsb3VkLnNlY3JldG1hbmFnZXIudjEuQmFja3VwXSwgaW4g
dGhlIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9i
YWNrdXBzL3tiYWNrdXB9YC4KCg0KBQQCAgAFEgSzAQIICg0KBQQCAgABEgSzAQkNCg0KBQQC
AgADEgSzARARCg8KBQQCAgAIEgazARK4AQMKEAoIBAICAAicCAASBLQBBCoKEQoHBAICAAif
CBIGtQEEtwEFCpEBCgIEAxIGvQEAzwEBGoIBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZWNy
ZXRPcGVyYXRpb25zU2VydmljZS5DcmVhdGVCYWNrdXBdW2dvb2dsZS5jbG91ZC5zZWNyZXRt
YW5hZ2VyLnYxLlNlY3JldE9wZXJhdGlvbnNTZXJ2aWNlLkNyZWF0ZUJhY2t1cF0uCgoLCgME
AwESBL0BCBsKwwEKBAQDAgASBsEBAsYBBBqyASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIGxvY2F0aW9uIHdoZXJlIHRoZQogW0JhY2t1cF1bZ29vZ2xlLmNsb3VkLnNl
Y3JldG1hbmFnZXIudjEuQmFja3VwXSB3aWxsIGJlIGNyZWF0ZWQsIGluIHRoZQogZm9ybWF0
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDQoFBAMCAAUS
BMEBAggKDQoFBAMCAAESBMEBCQ8KDQoFBAMCAAMSBMEBEhMKDwoFBAMCAAgSBsEBFMYBAwoQ
CggEAwIACJwIABIEwgEEKgoRCgcEAwIACJ8IEgbDAQTFAQUKfQoEBAMCARIEygECQBpvIFJl
cXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgYmFja3VwLCB3aGljaCB3aWxsIGJlY29t
ZSB0aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUgYmFja3VwJ3MgcmVzb3VyY2UgbmFtZS4K
Cg0KBQQDAgEFEgTKAQIICg0KBQQDAgEBEgTKAQkSCg0KBQQDAgEDEgTKARUWCg0KBQQDAgEI
EgTKARc/ChAKCAQDAgEInAgAEgTKARg+CmEKBAQDAgISBM4BAj0aUyBSZXF1aXJlZC4gVGhl
IFtCYWNrdXBdW2dvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLkJhY2t1cF0gcmVzb3Vy
Y2UgdG8KIGNyZWF0ZS4KCg0KBQQDAgIGEgTOAQIICg0KBQQDAgIBEgTOAQkPCg0KBQQDAgID
EgTOARITCg0KBQQDAgIIEgTOARQ8ChAKCAQDAgIInAgAEgTOARU7CpEBCgIEBBIG0wEA4AEB
GoIBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZWNyZXRPcGVyYXRpb25zU2VydmljZS5VcGRh
dGVCYWNrdXBdW2dvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLlNlY3JldE9wZXJhdGlv
bnNTZXJ2aWNlLlVwZGF0ZUJhY2t1cF0uCgoLCgMEBAESBNMBCBsKmgMKBAQEAgASBtoBAtsB
LxqJAyBPcHRpb25hbC4gRmllbGQgbWFzayBpcyB1c2VkIHRvIHNwZWNpZnkgdGhlIGZpZWxk
cyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIFtCYWNrdXBdW2dvb2dsZS5jbG91ZC5zZWNy
ZXRtYW5hZ2VyLnYxLkJhY2t1cF0gcmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4KIFRoZSBmaWVs
ZHMgc3BlY2lmaWVkIGluIHRoZSBgdXBkYXRlX21hc2tgIGFyZSByZWxhdGl2ZSB0byB0aGUg
cmVzb3VyY2UsIG5vdAogdGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3
cml0dGVuIGlmIGl0IGlzIGluIHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3QgcHJv
dmlkZSBhIG1hc2sgdGhlbiBhbGwgZmllbGRzIHByZXNlbnQgaW4gdGhlIHJlcXVlc3Qgd2ls
bCBiZQogb3ZlcndyaXR0ZW4uCgoNCgUEBAIABhIE2gECGwoNCgUEBAIAARIE2gEcJwoNCgUE
BAIAAxIE2gEqKwoNCgUEBAIACBIE2wEGLgoQCggEBAIACJwIABIE2wEHLQprCgQEBAIBEgTf
AQI9Gl0gUmVxdWlyZWQuIFRoZSBbQmFja3VwXVtnb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdl
ci52MS5CYWNrdXBdIHJlc291cmNlIHdpdGgKIHVwZGF0ZWQgZmllbGRzLgoKDQoFBAQCAQYS
BN8BAggKDQoFBAQCAQESBN8BCQ8KDQoFBAQCAQMSBN8BEhMKDQoFBAQCAQgSBN8BFDwKEAoI
BAQCAQicCAASBN8BFTsKkQEKAgQFEgbkAQDyAQEaggEgUmVxdWVzdCBtZXNzYWdlIGZvcgog
W1NlY3JldE9wZXJhdGlvbnNTZXJ2aWNlLkRlbGV0ZUJhY2t1cF1bZ29vZ2xlLmNsb3VkLnNl
Y3JldG1hbmFnZXIudjEuU2VjcmV0T3BlcmF0aW9uc1NlcnZpY2UuRGVsZXRlQmFja3VwXS4K
CgsKAwQFARIE5AEIGwq7AQoEBAUCABIG6AEC7QEEGqoBIFJlcXVpcmVkLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUKIFtCYWNrdXBdW2dvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYx
LkJhY2t1cF0gdG8gZGVsZXRlLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1cHMve2JhY2t1cH1gLgoKDQoFBAUCAAUSBOgB
AggKDQoFBAUCAAESBOgBCQ0KDQoFBAUCAAMSBOgBEBEKDwoFBAUCAAgSBugBEu0BAwoQCggE
BQIACJwIABIE6QEEKgoRCgcEBQIACJ8IEgbqAQTsAQUKoAEKBAQFAgESBPEBAjsakQEgT3B0
aW9uYWwuIElmIHNldCwgdGhlIHJlcXVlc3Qgd2lsbCBvbmx5IHN1Y2NlZWQgaWYgaXQgbWF0
Y2hlcyB0aGUgZXRhZyBvZgogdGhlIGN1cnJlbnRseSBzdG9yZWQgW0JhY2t1cF1bZ29vZ2xl
LmNsb3VkLnNlY3JldG1hbmFnZXIudjEuQmFja3VwXS4KCg0KBQQFAgEFEgTxAQIICg0KBQQF
AgEBEgTxAQkNCg0KBQQFAgEDEgTxARARCg0KBQQFAgEIEgTxARI6ChAKCAQFAgEInAgAEgTx
ARM5CpMBCgIEBhIG9gEAngIBGoQBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZWNyZXRPcGVy
YXRpb25zU2VydmljZS5SZXN0b3JlQmFja3VwXVtnb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdl
ci52MS5TZWNyZXRPcGVyYXRpb25zU2VydmljZS5SZXN0b3JlQmFja3VwXS4KCgsKAwQGARIE
9gEIHAq6AQoEBAYCABIG+gEC/wEEGqkBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUKIFtCYWNrdXBdW2dvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLkJhY2t1cF0g
dG8gcmVzdG9yZSBmcm9tLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2JhY2t1cHMve2JhY2t1cH1gCgoNCgUEBgIABRIE+gECCAoNCgUEBgIA
ARIE+gEJDQoNCgUEBgIAAxIE+gEQEQoPCgUEBgIACBIG+gES/wEDChAKCAQGAgAInAgAEgT7
AQQqChEKBwQGAgAInwgSBvwBBP4BBQr4AQoEBAYCARIGhQICigIEGucBIFJlcXVpcmVkLiBQ
YXJlbnQgb2YgdGhlIG5ldyBbU2VjcmV0XVtnb29nbGUuY2xvdWQuc2VjcmV0bWFuYWdlci52
MS5TZWNyZXRdCiB0byBiZSBjcmVhdGVkIGZyb20gdGhpcyBiYWNrdXAuIEZvcm1hdHM6CiAt
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gIChmb3IgcmVnaW9u
YWwgc2VjcmV0cykKIC0gYHByb2plY3RzL3twcm9qZWN0fWAgKGZvciBnbG9iYWwgc2VjcmV0
cykKCg0KBQQGAgEFEgSFAgIICg0KBQQGAgEBEgSFAgkiCg0KBQQGAgEDEgSFAiUmCg8KBQQG
AgEIEgaFAieKAgMKEAoIBAYCAQicCAASBIYCBCoKEQoHBAYCAQifCBIGhwIEiQIFCtUCCgQE
BgICEgSSAgJMGsYCIFJlcXVpcmVkLiBJRCBvZiB0aGUgbmV3IFtTZWNyZXRdW2dvb2dsZS5j
bG91ZC5zZWNyZXRtYW5hZ2VyLnYxLlNlY3JldF0gdG8KIGJlIGNyZWF0ZWQgZnJvbSB0aGlz
IGJhY2t1cC4gVGhpcyBtdXN0IGJlIHVuaXF1ZSB3aXRoaW4gdGhlIHByb2plY3QuCgogQSBz
ZWNyZXQgSUQgaXMgYSBzdHJpbmcgd2l0aCBhIG1heGltdW0gbGVuZ3RoIG9mIDI1NSBjaGFy
YWN0ZXJzIGFuZCBjYW4KIGNvbnRhaW4gdXBwZXJjYXNlIGFuZCBsb3dlcmNhc2UgbGV0dGVy
cywgbnVtZXJhbHMsIGFuZCB0aGUgaHlwaGVuIChgLWApCiBhbmQgdW5kZXJzY29yZSAoYF9g
KSBjaGFyYWN0ZXJzLgoKDQoFBAYCAgUSBJICAggKDQoFBAYCAgESBJICCR4KDQoFBAYCAgMS
BJICISIKDQoFBAYCAggSBJICI0sKEAoIBAYCAgicCAASBJICJEoK9AEKBAQGAgMSBpgCAp0C
BBrjASBPcHRpb25hbC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIENsb3VkIEtNUyBDcnlw
dG9LZXkgdG8gYmUgdXNlZCB0bwogZW5jcnlwdCB0aGUgW1NlY3JldF1bZ29vZ2xlLmNsb3Vk
LnNlY3JldG1hbmFnZXIudjEuU2VjcmV0XS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlz
L3tjcnlwdG9fa2V5fWAKCg0KBQQGAgMFEgSYAgIICg0KBQQGAgMBEgSYAgkVCg0KBQQGAgMD
EgSYAhgZCg8KBQQGAgMIEgaYAhqdAgMKEAoIBAYCAwicCAASBJkCBCoKEQoHBAYCAwifCBIG
mgIEnAIFCkYKAgQHEgahAgDRAgEaOCBSZXByZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUg
bG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgsKAwQHARIEoQIIGQplCgQEBwMAEgakAgKwAgMa
VSBSZXByZXNlbnRzIHByb2dyZXNzIGluZm9ybWF0aW9uIGZvciBvcGVyYXRpb25zIGludm9s
dmluZyBtdWx0aXBsZSBzZWNyZXQKIHZlcnNpb25zLgoKDQoFBAcDAAESBKQCChIKbgoGBAcD
AAIAEgSnAgROGl4gT3V0cHV0IG9ubHkuIFByb3ZpZGVzIHRoZSB0b3RhbCBudW1iZXIgb2Yg
c2VjcmV0IHZlcnNpb25zIHRvIGJlIHByb2Nlc3NlZAogYnkgdGhlIG9wZXJhdGlvbi4KCg8K
BwQHAwACAAUSBKcCBAkKDwoHBAcDAAIAARIEpwIKHQoPCgcEBwMAAgADEgSnAiAhCg8KBwQH
AwACAAgSBKcCIk0KEgoKBAcDAAIACJwIABIEpwIjTAppCgYEBwMAAgESBqsCBKwCNBpXIE91
dHB1dCBvbmx5LiBOdW1iZXIgb2Ygc2VjcmV0IHZlcnNpb25zIHRoYXQgaGF2ZSBiZWVuIHN1
Y2Nlc3NmdWxseQogcHJvY2Vzc2VkIHNvIGZhci4KCg8KBwQHAwACAQUSBKsCBAkKDwoHBAcD
AAIBARIEqwIKIQoPCgcEBwMAAgEDEgSrAiQlCg8KBwQHAwACAQgSBKwCCDMKEgoKBAcDAAIB
CJwIABIErAIJMgpQCgYEBwMAAgISBK8CBE8aQCBPdXRwdXQgb25seS4gTnVtYmVyIG9mIHNl
Y3JldCB2ZXJzaW9ucyB0aGF0IGZhaWxlZCB0byBwcm9jZXNzLgoKDwoHBAcDAAICBRIErwIE
CQoPCgcEBwMAAgIBEgSvAgoeCg8KBwQHAwACAgMSBK8CISIKDwoHBAcDAAICCBIErwIjTgoS
CgoEBwMAAgIInAgAEgSvAiRNCj4KBAQHAgASBrMCArQCMhouIE91dHB1dCBvbmx5LiBUaW1l
IHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoNCgUEBwIABhIEswICGwoNCgUEBwIAARIE
swIcJwoNCgUEBwIAAxIEswIqKwoNCgUEBwIACBIEtAIGMQoQCggEBwIACJwIABIEtAIHMApD
CgQEBwIBEga3AgK4AjIaMyBPdXRwdXQgb25seS4gVGltZSB0aGUgb3BlcmF0aW9uIGZpbmlz
aGVkIHJ1bm5pbmcuCgoNCgUEBwIBBhIEtwICGwoNCgUEBwIBARIEtwIcJAoNCgUEBwIBAxIE
twInKAoNCgUEBwIBCBIEuAIGMQoQCggEBwIBCJwIABIEuAIHMApaCgQEBwICEgS7AgJAGkwg
T3V0cHV0IG9ubHkuIFNlcnZlci1kZWZpbmVkIHJlc291cmNlIHBhdGggZm9yIHRoZSB0YXJn
ZXQgb2YgdGhlIG9wZXJhdGlvbi4KCg0KBQQHAgIFEgS7AgIICg0KBQQHAgIBEgS7AgkPCg0K
BQQHAgIDEgS7AhITCg0KBQQHAgIIEgS7AhQ/ChAKCAQHAgIInAgAEgS7AhU+CkgKBAQHAgMS
BL4CAj4aOiBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgdmVyYiBleGVjdXRlZCBieSB0aGUg
b3BlcmF0aW9uLgoKDQoFBAcCAwUSBL4CAggKDQoFBAcCAwESBL4CCQ0KDQoFBAcCAwMSBL4C
EBEKDQoFBAcCAwgSBL4CEj0KEAoIBAcCAwicCAASBL4CEzwKTAoEBAcCBBIEwQICSBo+IE91
dHB1dCBvbmx5LiBIdW1hbi1yZWFkYWJsZSBzdGF0dXMgb2YgdGhlIG9wZXJhdGlvbiwgaWYg
YW55LgoKDQoFBAcCBAUSBMECAggKDQoFBAcCBAESBMECCRcKDQoFBAcCBAMSBMECGhsKDQoF
BAcCBAgSBMECHEcKEAoIBAcCBAicCAASBMECHUYK0wIKBAQHAgUSBMkCAk4axAIgT3V0cHV0
IG9ubHkuIElkZW50aWZpZXMgd2hldGhlciB0aGUgdXNlciBoYXMgcmVxdWVzdGVkIGNhbmNl
bGxhdGlvbgogb2YgdGhlIG9wZXJhdGlvbi4gT3BlcmF0aW9ucyB0aGF0IGhhdmUgYmVlbiBj
YW5jZWxsZWQgc3VjY2Vzc2Z1bGx5CiBoYXZlCiBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbi5lcnJvcl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5lcnJvcl0KIHZhbHVl
IHdpdGggYSBbZ29vZ2xlLnJwYy5TdGF0dXMuY29kZV1bZ29vZ2xlLnJwYy5TdGF0dXMuY29k
ZV0gb2YgYDFgLAogY29ycmVzcG9uZGluZyB0byBgQ29kZS5DQU5DRUxMRURgLgoKDQoFBAcC
BQUSBMkCAgYKDQoFBAcCBQESBMkCBx0KDQoFBAcCBQMSBMkCICEKDQoFBAcCBQgSBMkCIk0K
EAoIBAcCBQicCAASBMkCI0wKRQoEBAcCBhIEzAICRRo3IE91dHB1dCBvbmx5LiBBUEkgdmVy
c2lvbiB1c2VkIHRvIHN0YXJ0IHRoZSBvcGVyYXRpb24uCgoNCgUEBwIGBRIEzAICCAoNCgUE
BwIGARIEzAIJFAoNCgUEBwIGAxIEzAIXGAoNCgUEBwIGCBIEzAIZRAoQCggEBwIGCJwIABIE
zAIaQwqhAQoEBAcCBxIE0AICRBqSASBPdXRwdXQgb25seS4gUmVwcmVzZW50cyB0aGUgcHJv
Z3Jlc3Mgb2YgdGhlIG9wZXJhdGlvbi4gVGhpcyBmaWVsZCBpcwogcG9wdWxhdGVkIGZvciBv
cGVyYXRpb25zIHRoYXQgaW52b2x2ZSBwcm9jZXNzaW5nIG11bHRpcGxlIHNlY3JldCB2ZXJz
aW9ucy4KCg0KBQQHAgcGEgTQAgIKCg0KBQQHAgcBEgTQAgsTCg0KBQQHAgcDEgTQAhYXCg0K
BQQHAgcIEgTQAhhDChAKCAQHAgcInAgAEgTQAhlCCkYKAgQIEgbVAgCfAwEaOCBBIEJhY2t1
cCBvZiBhIFNlY3JldC4KIEJhY2t1cHMgYXJlIHJlZ2lvbmFsIHJlc291cmNlcy4KCgsKAwQI
ARIE1QIIDgoNCgMECAcSBtYCAtsCBAoPCgUECAedCBIG1gIC2wIECmUKBAQIBAASBt8CAu4C
AxpVIEVudW0gcmVwcmVzZW50aW5nIHRoZSBzdGF0ZSBvZiB0aGUKIFtCYWNrdXBdW2dvb2ds
ZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLkJhY2t1cF0uCgoNCgUECAQAARIE3wIHDAouCgYE
CAQAAgASBOECBBoaHiBCYWNrdXAgc3RhdGUgaXMgdW5zcGVjaWZpZWQuCgoPCgcECAQAAgAB
EgThAgQVCg8KBwQIBAACAAISBOECGBkKLgoGBAgEAAIBEgTkAgQRGh4gVGhlIGJhY2t1cCBp
cyBiZWluZyBjcmVhdGVkLgoKDwoHBAgEAAIBARIE5AIEDAoPCgcECAQAAgECEgTkAg8QCjcK
BgQIBAACAhIE5wIEDxonIFRoZSBiYWNrdXAgaXMgYWN0aXZlIGFuZCBjYW4gYmUgdXNlZC4K
Cg8KBwQIBAACAgESBOcCBAoKDwoHBAgEAAICAhIE5wINDgouCgYECAQAAgMSBOoCBBEaHiBU
aGUgYmFja3VwIGlzIGJlaW5nIHVwZGF0ZWQuCgoPCgcECAQAAgMBEgTqAgQMCg8KBwQIBAAC
AwISBOoCDxAKNwoGBAgEAAIEEgTtAgQPGicgVGhlIGJhY2t1cCBjcmVhdGlvbiBvciB1cGRh
dGUgZmFpbGVkLgoKDwoHBAgEAAIEARIE7QIECgoPCgcECAQAAgQCEgTtAg0OCnwKBAQIAgAS
BPICAj0abiBJZGVudGlmaWVyLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBiYWNrdXAuCiBGb3Jt
YXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYmFja3Vwcy97
YmFja3VwfWAKCg0KBQQIAgAFEgTyAgIICg0KBQQIAgABEgTyAgkNCg0KBQQIAgADEgTyAhAR
Cg0KBQQIAgAIEgTyAhI8ChAKCAQIAgAInAgAEgTyAhM7Ct0DCgQECAIBEgb8AgKCAwQazAMg
UmVxdWlyZWQuIEltbXV0YWJsZS4gUmVzb3VyY2UgbmFtZSBvZiB0aGUKIFtTZWNyZXRdW2dv
b2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLlNlY3JldF0gdGhhdCB0aGlzIGJhY2t1cCBp
cyBmb3IuIFRoZQogc291cmNlIFtTZWNyZXRdW2dvb2dsZS5jbG91ZC5zZWNyZXRtYW5hZ2Vy
LnYxLlNlY3JldF0gY2FuIGJlIGluIGEgZGlmZmVyZW50CiByZWdpb24gdGhhbiB0aGUgW0Jh
Y2t1cF1bZ29vZ2xlLmNsb3VkLnNlY3JldG1hbmFnZXIudjEuQmFja3VwXS4gVGhpcyBmaWVs
ZAogaXMgaW1tdXRhYmxlIGFmdGVyIGNyZWF0aW9uLiBGb3JtYXRzOgogLSBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3NlY3JldHMve3NlY3JldH1gIChmb3Ig
cmVnaW9uYWwKIHNlY3JldHMpCiAtIGBwcm9qZWN0cy97cHJvamVjdH0vc2VjcmV0cy97c2Vj
cmV0fWAgKGZvciBnbG9iYWwgc2VjcmV0cykKCg0KBQQIAgEFEgT8AgIICg0KBQQIAgEBEgT8
AgkWCg0KBQQIAgEDEgT8AhkaCg8KBQQIAgEIEgb8AhuCAwMKEAoIBAgCAQicCAASBP0CBCoK
EAoIBAgCAQicCAESBP4CBCsKEQoHBAgCAQifCBIG/wIEgQMFCk0KBAQIAgISBoUDAoYDMho9
IE91dHB1dCBvbmx5LiBUaW1lIGF0IHdoaWNoIHRoZSBiYWNrdXAgcmVzb3VyY2Ugd2FzIGNy
ZWF0ZWQuCgoNCgUECAICBhIEhQMCGwoNCgUECAICARIEhQMcJwoNCgUECAICAxIEhQMqKwoN
CgUECAICCBIEhgMGMQoQCggECAICCJwIABIEhgMHMApSCgQECAIDEgaJAwKKAzIaQiBPdXRw
dXQgb25seS4gVGltZSBhdCB3aGljaCB0aGUgYmFja3VwIHJlc291cmNlIHdhcyBsYXN0IHVw
ZGF0ZWQuCgoNCgUECAIDBhIEiQMCGwoNCgUECAIDARIEiQMcJwoNCgUECAIDAxIEiQMqKwoN
CgUECAIDCBIEigMGMQoQCggECAIDCJwIABIEigMHMAqUAQoEBAgCBBIGjwMCkAMyGoMBIE91
dHB1dCBvbmx5LiBDcmVhdGlvbiB0aW1lIG9mIHRoZSBzb3VyY2UKIFtTZWNyZXRdW2dvb2ds
ZS5jbG91ZC5zZWNyZXRtYW5hZ2VyLnYxLlNlY3JldF0gYXQgdGhlIG1vbWVudCB0aGUgYmFj
a3VwIHdhcwogaW5pdGlhdGVkLgoKDQoFBAgCBAYSBI8DAhsKDQoFBAgCBAESBI8DHDUKDQoF
BAgCBAMSBI8DODkKDQoFBAgCBAgSBJADBjEKEAoIBAgCBAicCAASBJADBzAKXwoEBAgCBRIE
lAMCRhpRIE91dHB1dCBvbmx5LiBOdW1iZXIgb2Ygbm9uLWRlc3Ryb3llZCBzZWNyZXQgdmVy
c2lvbnMgY29udGFpbmVkIGluIHRoaXMKIGJhY2t1cC4KCg0KBQQIAgUFEgSUAwIHCg0KBQQI
AgUBEgSUAwgVCg0KBQQIAgUDEgSUAxgZCg0KBQQIAgUIEgSUAxpFChAKCAQIAgUInAgAEgSU
AxtECjwKBAQIAgYSBJcDAkoaLiBPcHRpb25hbC4gTGFiZWxzIHdpdGggdXNlci1kZWZpbmVk
IG1ldGFkYXRhLgoKDQoFBAgCBgYSBJcDAhUKDQoFBAgCBgESBJcDFhwKDQoFBAgCBgMSBJcD
HyAKDQoFBAgCBggSBJcDIUkKEAoIBAgCBgicCAASBJcDIkgKOQoEBAgCBxIEmgMCPhorIE91
dHB1dCBvbmx5LiBDdXJyZW50IHN0YXRlIG9mIHRoZSBCYWNrdXAuCgoNCgUECAIHBhIEmgMC
BwoNCgUECAIHARIEmgMIDQoNCgUECAIHAxIEmgMQEQoNCgUECAIHCBIEmgMSPQoQCggECAIH
CJwIABIEmgMTPAqaAQoEBAgCCBIEngMCPBqLASBPcHRpb25hbC4gVXNlZCBmb3Igb3B0aW1p
c3RpYyBjb25jdXJyZW5jeSBjb250cm9sIGFzIGEgd2F5IHRvIGhlbHAgcHJldmVudAogc2lt
dWx0YW5lb3VzIHVwZGF0ZXMgb2YgYSBiYWNrdXAgZnJvbSBvdmVyd3JpdGluZyBlYWNoIG90
aGVyLgoKDQoFBAgCCAUSBJ4DAggKDQoFBAgCCAESBJ4DCQ0KDQoFBAgCCAMSBJ4DEBIKDQoF
BAgCCAgSBJ4DEzsKEAoIBAgCCAicCAASBJ4DFDpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsRequest ===
    # Fields for ListBackupsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsResponse ===
    # Fields for ListBackupsResponse
    # Field: backups Type: 11 (.google.cloud.secretmanager.v1.Backup)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::GetBackupRequest ===
    # Fields for GetBackupRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::CreateBackupRequest ===
    # Fields for CreateBackupRequest
    # Field: parent Type: 9 ()
    # Field: backup_id Type: 9 ()
    # Field: backup Type: 11 (.google.cloud.secretmanager.v1.Backup)

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::UpdateBackupRequest ===
    # Fields for UpdateBackupRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: backup Type: 11 (.google.cloud.secretmanager.v1.Backup)

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::DeleteBackupRequest ===
    # Fields for DeleteBackupRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::RestoreBackupRequest ===
    # Fields for RestoreBackupRequest
    # Field: name Type: 9 ()
    # Field: destination_secret_parent Type: 9 ()
    # Field: destination_secret_id Type: 9 ()
    # Field: kms_key_name Type: 9 ()

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()
    # Field: progress Type: 11 (.google.cloud.secretmanager.v1.OperationMetadata.Progress)

# === Message: Google::Cloud::Secretmanager::V1::OperationsService::Backup ===
    # Fields for Backup
    # Field: name Type: 9 ()
    # Field: source_secret Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: source_secret_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: version_count Type: 5 ()
    # Field: labels Type: 11 (.google.cloud.secretmanager.v1.Backup.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.secretmanager.v1.Backup.State)
    # Field: etag Type: 9 ()

# Enum: Backup::State
our $Backup_STATE_UNSPECIFIED = 0;
our $Backup_CREATING = 1;
our $Backup_ACTIVE = 2;
our $Backup_UPDATING = 3;
our $Backup_FAILED = 4;

# === Service Client: Google::Cloud::Secretmanager::V1::OperationsService::SecretOperationsServiceClient ===
package Google::Cloud::Secretmanager::V1::OperationsService::SecretOperationsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Secretmanager::V1::OperationsService::SecretOperationsServiceClient

Client stub representing the remote C<SecretOperationsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<secretmanager.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'secretmanager.googleapis.com:443' );

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

sub list_backups {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secretmanager.v1.SecretOperationsService',
        method         => 'ListBackups',
        request        => $req,
        response_class => 'Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsResponse',
    });
}

sub get_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secretmanager::V1::OperationsService::GetBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secretmanager.v1.SecretOperationsService',
        method         => 'GetBackup',
        request        => $req,
        response_class => 'Google::Cloud::Secretmanager::V1::OperationsService::Backup',
    });
}

sub create_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secretmanager::V1::OperationsService::CreateBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secretmanager.v1.SecretOperationsService',
        method         => 'CreateBackup',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secretmanager::V1::OperationsService::UpdateBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secretmanager.v1.SecretOperationsService',
        method         => 'UpdateBackup',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secretmanager::V1::OperationsService::DeleteBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secretmanager.v1.SecretOperationsService',
        method         => 'DeleteBackup',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub restore_backup {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Secretmanager::V1::OperationsService::RestoreBackupRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.secretmanager.v1.SecretOperationsService',
        method         => 'RestoreBackup',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Secretmanager::V1::OperationsService - Compiled Protocol Buffers messages for google/cloud/secretmanager/v1/operations_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Secretmanager::V1::OperationsService;

    my $msg = Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/secretmanager/v1/operations_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsRequest

Request message for
[SecretOperationsService.ListBackups][google.cloud.secretmanager.v1.SecretOperationsService.ListBackups].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the location associated with the
[Backups][google.cloud.secretmanager.v1.Backup], in the format
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of backups to return. The service may return fewer
than this value. If unspecified, at most 50 backups will be returned. The
maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter expression to restrict the returned
[Backups][google.cloud.secretmanager.v1.Backup].

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field specification for sorting the results in the response.

=back

=head2 Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsResponse

Response message for
[SecretOperationsService.ListBackups][google.cloud.secretmanager.v1.SecretOperationsService.ListBackups].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backups() >> / C<< $msg->backups($value) >>

Type: C<Message> (L<Google::Cloud::Secretmanager::V1::OperationsService::Backup>)

The list of [Backups][google.cloud.secretmanager.v1.Backup] in the
location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Resource names of the unreachable locations.
Format: `projects/{project}/locations/{location}`

=back

=head2 Google::Cloud::Secretmanager::V1::OperationsService::GetBackupRequest

Request message for
[SecretOperationsService.GetBackup][google.cloud.secretmanager.v1.SecretOperationsService.GetBackup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Backup][google.cloud.secretmanager.v1.Backup], in the format
`projects/{project}/locations/{location}/backups/{backup}`.

=back

=head2 Google::Cloud::Secretmanager::V1::OperationsService::CreateBackupRequest

Request message for
[SecretOperationsService.CreateBackup][google.cloud.secretmanager.v1.SecretOperationsService.CreateBackup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the location where the
[Backup][google.cloud.secretmanager.v1.Backup] will be created, in the
format `projects/{project}/locations/{location}`.

=item * C<< $msg->backup_id() >> / C<< $msg->backup_id($value) >>

Type: C<String>

Required. The ID to use for the backup, which will become the final
component of the backup's resource name.

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<Message> (L<Google::Cloud::Secretmanager::V1::OperationsService::Backup>)

Required. The [Backup][google.cloud.secretmanager.v1.Backup] resource to
create.

=back

=head2 Google::Cloud::Secretmanager::V1::OperationsService::UpdateBackupRequest

Request message for
[SecretOperationsService.UpdateBackup][google.cloud.secretmanager.v1.SecretOperationsService.UpdateBackup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
[Backup][google.cloud.secretmanager.v1.Backup] resource by the update.
The fields specified in the `update_mask` are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields present in the request will be
overwritten.

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<Message> (L<Google::Cloud::Secretmanager::V1::OperationsService::Backup>)

Required. The [Backup][google.cloud.secretmanager.v1.Backup] resource with
updated fields.

=back

=head2 Google::Cloud::Secretmanager::V1::OperationsService::DeleteBackupRequest

Request message for
[SecretOperationsService.DeleteBackup][google.cloud.secretmanager.v1.SecretOperationsService.DeleteBackup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Backup][google.cloud.secretmanager.v1.Backup] to delete, in the format
`projects/{project}/locations/{location}/backups/{backup}`.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. If set, the request will only succeed if it matches the etag of
the currently stored [Backup][google.cloud.secretmanager.v1.Backup].

=back

=head2 Google::Cloud::Secretmanager::V1::OperationsService::RestoreBackupRequest

Request message for
[SecretOperationsService.RestoreBackup][google.cloud.secretmanager.v1.SecretOperationsService.RestoreBackup].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the
[Backup][google.cloud.secretmanager.v1.Backup] to restore from. Format:
`projects/{project}/locations/{location}/backups/{backup}`

=item * C<< $msg->destination_secret_parent() >> / C<< $msg->destination_secret_parent($value) >>

Type: C<String>

Required. Parent of the new [Secret][google.cloud.secretmanager.v1.Secret]
to be created from this backup. Formats:
- `projects/{project}/locations/{location}` (for regional secrets)
- `projects/{project}` (for global secrets)

=item * C<< $msg->destination_secret_id() >> / C<< $msg->destination_secret_id($value) >>

Type: C<String>

Required. ID of the new [Secret][google.cloud.secretmanager.v1.Secret] to
be created from this backup. This must be unique within the project.

A secret ID is a string with a maximum length of 255 characters and can
contain uppercase and lowercase letters, numerals, and the hyphen (`-`)
and underscore (`_`) characters.

=item * C<< $msg->kms_key_name() >> / C<< $msg->kms_key_name($value) >>

Type: C<String>

Optional. The resource name of the Cloud KMS CryptoKey to be used to
encrypt the [Secret][google.cloud.secretmanager.v1.Secret].
Format:
`projects/{project}/locations/{location}/keyRings/{key_ring}/cryptoKeys/{crypto_key}`

=back

=head2 Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the operation finished running.

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
have
[google.longrunning.Operation.error][google.longrunning.Operation.error]
value with a [google.rpc.Status.code][google.rpc.Status.code] of `1`,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=item * C<< $msg->progress() >> / C<< $msg->progress($value) >>

Type: C<Message> (L<Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata::Progress>)

Output only. Represents the progress of the operation. This field is
populated for operations that involve processing multiple secret versions.

=back

=head2 Google::Cloud::Secretmanager::V1::OperationsService::Backup

A Backup of a Secret.
Backups are regional resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the backup.
Format: `projects/{project}/locations/{location}/backups/{backup}`

=item * C<< $msg->source_secret() >> / C<< $msg->source_secret($value) >>

Type: C<String>

Required. Immutable. Resource name of the
[Secret][google.cloud.secretmanager.v1.Secret] that this backup is for. The
source [Secret][google.cloud.secretmanager.v1.Secret] can be in a different
region than the [Backup][google.cloud.secretmanager.v1.Backup]. This field
is immutable after creation. Formats:
- `projects/{project}/locations/{location}/secrets/{secret}` (for regional
secrets)
- `projects/{project}/secrets/{secret}` (for global secrets)

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time at which the backup resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time at which the backup resource was last updated.

=item * C<< $msg->source_secret_create_time() >> / C<< $msg->source_secret_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time of the source
[Secret][google.cloud.secretmanager.v1.Secret] at the moment the backup was
initiated.

=item * C<< $msg->version_count() >> / C<< $msg->version_count($value) >>

Type: C<Int32>

Output only. Number of non-destroyed secret versions contained in this
backup.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Secretmanager::V1::OperationsService::Backup::LabelsEntry>)

Optional. Labels with user-defined metadata.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Secretmanager::V1::Backup::State>)

Output only. Current state of the Backup.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. Used for optimistic concurrency control as a way to help prevent
simultaneous updates of a backup from overwriting each other.

=back

=head3 Enum: Backup::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<FAILED> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Secretmanager::V1::OperationsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
