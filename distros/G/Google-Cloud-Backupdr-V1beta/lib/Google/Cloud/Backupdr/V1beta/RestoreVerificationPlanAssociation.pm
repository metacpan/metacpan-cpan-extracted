package Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Ckhnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL3Jlc3RvcmVfdmVyaWZpY2F0aW9uX3Bs
YW5fYXNzb2NpYXRpb24ucHJvdG8SHGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEaH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8i4QgKIlJlc3RvcmVWZXJpZmlj
YXRpb25QbGFuQXNzb2NpYXRpb24SXwoQcmVzdG9yZV90ZW1wbGF0ZRgIIAEoCUIy4EEC4EEF
+kEpCidiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVGVtcGxhdGVIAFIPcmVzdG9y
ZVRlbXBsYXRlEhoKBG5hbWUYASABKAlCBuBBA+BBCFIEbmFtZRIlCgtkZXNjcmlwdGlvbhgC
IAEoCUID4EEBUgtkZXNjcmlwdGlvbhJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgEIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJhCgVzdGF0
ZRgFIAEoDjJGLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVzdG9yZVZlcmlmaWNh
dGlvblBsYW5Bc3NvY2lhdGlvbi5TdGF0ZUID4EEDUgVzdGF0ZRJaCg90cmlnZ2VyX3N1bW1h
cnkYBiABKAsyLC5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLlRyaWdnZXJTdW1tYXJ5
QgPgQQNSDnRyaWdnZXJTdW1tYXJ5EisKDXJlc291cmNlX3R5cGUYByABKAlCBuBBAuBBBVIM
cmVzb3VyY2VUeXBlEmkKBmxhYmVscxgJIAMoCzJMLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52
MWJldGEuUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlvbi5MYWJlbHNFbnRyeUID
4EEBUgZsYWJlbHMaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4ASJtCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENS
RUFUSU5HEAESCgoGQUNUSVZFEAISDAoIREVMRVRJTkcQAxIMCghJTkFDVElWRRAEEgwKCFVQ
REFUSU5HEAUSCQoFRVJST1IQBjqCAupB/gEKOmJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jl
c3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb24Sd3Byb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlVmVyaWZpY2F0aW9uUGxhbnMve3Jlc3RvcmVf
dmVyaWZpY2F0aW9uX3BsYW59L2Fzc29jaWF0aW9ucy97YXNzb2NpYXRpb259KiNyZXN0b3Jl
VmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uczIicmVzdG9yZVZlcmlmaWNhdGlvblBsYW5B
c3NvY2lhdGlvbkINCgthc3NvY2lhdGlvbiLrAgoOVHJpZ2dlclN1bW1hcnkSSwoRbGFzdF90
cmlnZ2VyX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSD2xh
c3RUcmlnZ2VyVGltZRJLChFuZXh0X3RyaWdnZXJfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IPbmV4dFRyaWdnZXJUaW1lEkUKEmxhc3RfdHJpZ2dlcl9l
cnJvchgDIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzQgPgQQNSEGxhc3RUcmlnZ2VyRXJyb3IS
eAobbGFzdF92ZXJpZmljYXRpb25fZXhlY3V0aW9uGAQgASgJQjjgQQP6QTIKMGJhY2t1cGRy
Lmdvb2dsZWFwaXMuY29tL1Jlc3RvcmVUZW1wbGF0ZUV4ZWN1dGlvblIZbGFzdFZlcmlmaWNh
dGlvbkV4ZWN1dGlvbiKmAwovQ3JlYXRlUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lh
dGlvblJlcXVlc3QSTwoGcGFyZW50GAEgASgJQjfgQQL6QTEKL2JhY2t1cGRyLmdvb2dsZWFw
aXMuY29tL1Jlc3RvcmVWZXJpZmljYXRpb25QbGFuUgZwYXJlbnQSWwoocmVzdG9yZV92ZXJp
ZmljYXRpb25fcGxhbl9hc3NvY2lhdGlvbl9pZBgCIAEoCUID4EECUiRyZXN0b3JlVmVyaWZp
Y2F0aW9uUGxhbkFzc29jaWF0aW9uSWQSmAEKJXJlc3RvcmVfdmVyaWZpY2F0aW9uX3BsYW5f
YXNzb2NpYXRpb24YAyABKAsyQC5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLlJlc3Rv
cmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25CA+BBAlIicmVzdG9yZVZlcmlmaWNhdGlv
blBsYW5Bc3NvY2lhdGlvbhIqCgpyZXF1ZXN0X2lkGAQgASgJQgvijM/XCAIIAeBBAVIJcmVx
dWVzdElkIoYBCixHZXRSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uUmVxdWVz
dBJWCgRuYW1lGAEgASgJQkLgQQL6QTwKOmJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jlc3Rv
cmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25SBG5hbWUihAIKLkxpc3RSZXN0b3JlVmVy
aWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uc1JlcXVlc3QSTwoGcGFyZW50GAEgASgJQjfgQQL6
QTEKL2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jlc3RvcmVWZXJpZmljYXRpb25QbGFuUgZw
YXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4Y
AyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoI
b3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSKYAgovTGlzdFJlc3RvcmVWZXJpZmljYXRp
b25QbGFuQXNzb2NpYXRpb25zUmVzcG9uc2USlQEKJnJlc3RvcmVfdmVyaWZpY2F0aW9uX3Bs
YW5fYXNzb2NpYXRpb25zGAEgAygLMkAuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5S
ZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uUiNyZXN0b3JlVmVyaWZpY2F0aW9u
UGxhbkFzc29jaWF0aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9r
ZW4SJQoLdW5yZWFjaGFibGUYAyADKAlCA+BBBlILdW5yZWFjaGFibGUitQEKL0RlbGV0ZVJl
c3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25SZXF1ZXN0ElYKBG5hbWUYASABKAlC
QuBBAvpBPAo6YmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVZlcmlmaWNhdGlvblBs
YW5Bc3NvY2lhdGlvblIEbmFtZRIqCgpyZXF1ZXN0X2lkGAIgASgJQgvijM/XCAIIAeBBAVIJ
cmVxdWVzdElkIqcBCiFUcmlnZ2VyUmVzdG9yZVZlcmlmaWNhdGlvblJlcXVlc3QSVgoEbmFt
ZRgBIAEoCUJC4EEC+kE8CjpiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVmVyaWZp
Y2F0aW9uUGxhbkFzc29jaWF0aW9uUgRuYW1lEioKCnJlcXVlc3RfaWQYAiABKAlCC+KMz9cI
AggB4EEBUglyZXF1ZXN0SWQinAEKIlRyaWdnZXJSZXN0b3JlVmVyaWZpY2F0aW9uUmVzcG9u
c2USdgoacmVzdG9yZV90ZW1wbGF0ZV9leGVjdXRpb24YASABKAlCOOBBA/pBMgowYmFja3Vw
ZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVRlbXBsYXRlRXhlY3V0aW9uUhhyZXN0b3JlVGVt
cGxhdGVFeGVjdXRpb25C6wEKIGNvbS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhQidS
ZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uUHJvdG9QAVo8Y2xvdWQuZ29vZ2xl
LmNvbS9nby9iYWNrdXBkci9hcGl2MWJldGEvYmFja3VwZHJwYjtiYWNrdXBkcnBiqgIcR29v
Z2xlLkNsb3VkLkJhY2t1cERSLlYxQmV0YcoCHEdvb2dsZVxDbG91ZFxCYWNrdXBEUlxWMWJl
dGHqAh9Hb29nbGU6OkNsb3VkOjpCYWNrdXBEUjo6VjFiZXRhSuBQCgcSBQ4AtAIBCrwECgEM
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
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACkKCQoC
AwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVACkKCQoCAwQSAxYAIQoICgEIEgMYADkKCQoC
CCUSAxgAOQoICgEIEgMZAFMKCQoCCAsSAxkAUwoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEI
EgMbAEgKCQoCCAgSAxsASAoICgEIEgMcADkKCQoCCAESAxwAOQoICgEIEgMdADkKCQoCCCkS
Ax0AOQoICgEIEgMeADgKCQoCCC0SAx4AOApvCgIEABIEIgB3ARpjIEEgYFJlc3RvcmVWZXJp
ZmljYXRpb25QbGFuQXNzb2NpYXRpb25gIGJpbmRzIGEgc3BlY2lmaWMgd29ya2xvYWQgdG8g
YQogYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYC4KCgoKAwQAARIDIggqCgsKAwQABxIEIwIo
BAoNCgUEAAedCBIEIwIoBApjCgQEAAQAEgQsAkEDGlUgYFN0YXRlYCBlbnVtZXJhdGVzIHRo
ZSBwb3NzaWJsZSBzdGF0ZXMgZm9yIGEKIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29j
aWF0aW9uYC4KCgwKBQQABAABEgMsBwwKHwoGBAAEAAIAEgMuBBoaECBTdGF0ZSBub3Qgc2V0
LgoKDgoHBAAEAAIAARIDLgQVCg4KBwQABAACAAISAy4YGQovCgYEAAQAAgESAzEEERogIFRo
ZSByZXNvdXJjZSBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDMQQMCg4KBwQABAAC
AQISAzEPEApDCgYEAAQAAgISAzQEDxo0IFRoZSByZXNvdXJjZSBoYXMgYmVlbiBjcmVhdGVk
IGFuZCBpcyBmdWxseSB1c2FibGUuCgoOCgcEAAQAAgIBEgM0BAoKDgoHBAAEAAICAhIDNA0O
Ci8KBgQABAACAxIDNwQRGiAgVGhlIHJlc291cmNlIGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcE
AAQAAgMBEgM3BAwKDgoHBAAEAAIDAhIDNw8QCkEKBgQABAACBBIDOgQRGjIgVGhlIHJlc291
cmNlIGhhcyBiZWVuIGNyZWF0ZWQgYnV0IGlzIG5vdCB1c2FibGUuCgoOCgcEAAQAAgQBEgM6
BAwKDgoHBAAEAAIEAhIDOg8QCi8KBgQABAACBRIDPQQRGiAgVGhlIHJlc291cmNlIGlzIGJl
aW5nIHVwZGF0ZWQuCgoOCgcEAAQAAgUBEgM9BAwKDgoHBAAEAAIFAhIDPQ8QClAKBgQABAAC
BhIDQAQOGkEgVGhlIHJlc291cmNlIGlzIGluIGFuIGVycm9yIHN0YXRlIGR1ZSB0byBhIGNv
bmZpZ3VyYXRpb24gaXNzdWUuCgoOCgcEAAQAAgYBEgNABAkKDgoHBAAEAAIGAhIDQAwNCi4K
BAQACAASBEQCTgMaICBUaGUgc3BlY2lmaWMgYXNzb2NpYXRpb24gbGluay4KCgwKBQQACAAB
EgNECBMKWwoEBAACABIERwRNBhpNIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSBjYW5vbmlj
YWwgbmFtZSBvZiB0aGUgUmVzdG9yZVRlbXBsYXRlIHRvCiB0cmlnZ2VyLgoKDAoFBAACAAUS
A0cECgoMCgUEAAIAARIDRwsbCgwKBQQAAgADEgNHHh8KDQoFBAACAAgSBEcgTQUKDwoIBAAC
AAicCAASA0gGLAoPCggEAAIACJwIARIDSQYtCg8KBwQAAgAInwgSBEoGTAcK7gEKBAQAAgES
BFUCWAQa3wEgT3V0cHV0IG9ubHkuIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZQogYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25gLgoKIEZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVzdG9yZVZlcmlm
aWNhdGlvblBsYW5zL3tyZXN0b3JlX3ZlcmlmaWNhdGlvbl9wbGFufS9hc3NvY2lhdGlvbnMv
e2Fzc29jaWF0aW9ufWAKCgwKBQQAAgEFEgNVAggKDAoFBAACAQESA1UJDQoMCgUEAAIBAxID
VRARCg0KBQQAAgEIEgRVElgDCg8KCAQAAgEInAgAEgNWBC0KDwoIBAACAQicCAESA1cELApf
CgQEAAICEgNcAkIaUiBPcHRpb25hbC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBgUmVzdG9y
ZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlvbmAKIHJlc291cmNlLgoKDAoFBAACAgUSA1wC
CAoMCgUEAAICARIDXAkUCgwKBQQAAgIDEgNcFxgKDAoFBAACAggSA1wZQQoPCggEAAICCJwI
ABIDXBpACkcKBAQAAgMSBF8CYDIaOSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUg
YXNzb2NpYXRpb24gd2FzIGNyZWF0ZWQuCgoMCgUEAAIDBhIDXwIbCgwKBQQAAgMBEgNfHCcK
DAoFBAACAwMSA18qKwoMCgUEAAIDCBIDYAYxCg8KCAQAAgMInAgAEgNgBzAKRwoEBAACBBIE
YwJkMho5IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBhc3NvY2lhdGlvbiB3YXMg
dXBkYXRlZC4KCgwKBQQAAgQGEgNjAhsKDAoFBAACBAESA2McJwoMCgUEAAIEAxIDYyorCgwK
BQQAAgQIEgNkBjEKDwoIBAACBAicCAASA2QHMApVCgQEAAIFEgNnAj4aSCBPdXRwdXQgb25s
eS4gVGhlIGBTdGF0ZWAgZm9yIHRoZSBgUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lh
dGlvbmAuCgoMCgUEAAIFBhIDZwIHCgwKBQQAAgUBEgNnCA0KDAoFBAACBQMSA2cQEQoMCgUE
AAIFCBIDZxI9Cg8KCAQAAgUInAgAEgNnEzwKfAoEBAACBhIEawJsMhpuIE91dHB1dCBvbmx5
LiBSZXN1bHRzIG9mIHRoZSBtb3N0IHJlY2VudCBhdXRvbWF0ZWQgcmVzdG9yZSBpbml0aWF0
aW9uCiBhbmQgdGhlIG5leHQgc2NoZWR1bGVkIGV4ZWN1dGlvbiB0aW1lLgoKDAoFBAACBgYS
A2sCEAoMCgUEAAIGARIDaxEgCgwKBQQAAgYDEgNrIyQKDAoFBAACBggSA2wGMQoPCggEAAIG
CJwIABIDbAcwCpsBCgQEAAIHEgRwAnMEGowBIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSB0
eXBlIG9mIHRoZSBHb29nbGUgQ2xvdWQgcmVzb3VyY2UgKGUuZy4sCiBgY29tcHV0ZS5nb29n
bGVhcGlzLmNvbS9JbnN0YW5jZWAsIGBzcWxhZG1pbi5nb29nbGVhcGlzLmNvbS9JbnN0YW5j
ZWApLgoKDAoFBAACBwUSA3ACCAoMCgUEAAIHARIDcAkWCgwKBQQAAgcDEgNwGRoKDQoFBAAC
BwgSBHAbcwMKDwoIBAACBwicCAASA3EEKgoPCggEAAIHCJwIARIDcgQrCi0KBAQAAggSA3YC
ShogIE9wdGlvbmFsLiBVc2VyLWRlZmluZWQgbGFiZWxzLgoKDAoFBAACCAYSA3YCFQoMCgUE
AAIIARIDdhYcCgwKBQQAAggDEgN2HyAKDAoFBAACCAgSA3YhSQoPCggEAAIICJwIABIDdiJI
CowBCgIEARIFewCSAQEafyBgVHJpZ2dlclN1bW1hcnlgIGNvbnRhaW5zIHRoZSByZXN1bHRz
IG9mIHRoZSBtb3N0IHJlY2VudCBhdXRvbWF0ZWQgcmVzdG9yZQogaW5pdGlhdGlvbiBhbmQg
dGhlIG5leHQgc2NoZWR1bGVkIGV4ZWN1dGlvbiB0aW1lLgoKCgoDBAEBEgN7CBYKTAoEBAEC
ABIEfQJ+Mho+IE91dHB1dCBvbmx5LiBUaGUgdGltZSBvZiB0aGUgbW9zdCByZWNlbnQgdHJp
Z2dlciBpbml0aWF0aW9uLgoKDAoFBAECAAYSA30CGwoMCgUEAQIAARIDfRwtCgwKBQQBAgAD
EgN9MDEKDAoFBAECAAgSA34GMQoPCggEAQIACJwIABIDfgcwClEKBAQBAgESBoEBAoIBMhpB
IE91dHB1dCBvbmx5LiBUaGUgc2NoZWR1bGVkIHRpbWUgb2YgdGhlIG5leHQgdHJpZ2dlciBp
bml0aWF0aW9uLgoKDQoFBAECAQYSBIEBAhsKDQoFBAECAQESBIEBHC0KDQoFBAECAQMSBIEB
MDEKDQoFBAECAQgSBIIBBjEKEAoIBAECAQicCAASBIIBBzAKUgoEBAECAhIGhQEChgEyGkIg
T3V0cHV0IG9ubHkuIFRoZSBlcnJvciBzdGF0dXMgb2YgdGhlIG1vc3QgcmVjZW50IGZhaWxl
ZCB0cmlnZ2VyLgoKDQoFBAECAgYSBIUBAhMKDQoFBAECAgESBIUBFCYKDQoFBAECAgMSBIUB
KSoKDQoFBAECAggSBIYBBjEKEAoIBAECAgicCAASBIYBBzAK2AEKBAQBAgMSBowBApEBBBrH
ASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIG1vc3QgcmVjZW50IGlu
aXRpYXRlZAogUmVzdG9yZVRlbXBsYXRlRXhlY3V0aW9uLgogRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlVGVtcGxhdGVzL3tyZXN0
b3JlX3RlbXBsYXRlfS9leGVjdXRpb25zL3tleGVjdXRpb259YAoKDQoFBAECAwUSBIwBAggK
DQoFBAECAwESBIwBCSQKDQoFBAECAwMSBIwBJygKDwoFBAECAwgSBowBKZEBAwoQCggEAQID
CJwIABIEjQEELQoRCgcEAQIDCJ8IEgaOAQSQAQUKTQoCBAISBpUBALYBARo/IFJlcXVlc3Qg
bWVzc2FnZSBmb3IgQ3JlYXRlUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlvbi4K
CgsKAwQCARIElQEINwrBAQoEBAICABIGmQECngEEGrABIFJlcXVpcmVkLiBUaGUgcGFyZW50
IHJlc291cmNlIHdoZXJlIHRoaXMgYXNzb2NpYXRpb24gd2lsbCBiZSBjcmVhdGVkLgogRm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3Jl
VmVyaWZpY2F0aW9uUGxhbnMve3Jlc3RvcmVfdmVyaWZpY2F0aW9uX3BsYW59YAoKDQoFBAIC
AAUSBJkBAggKDQoFBAICAAESBJkBCQ8KDQoFBAICAAMSBJkBEhMKDwoFBAICAAgSBpkBFJ4B
AwoQCggEAgIACJwIABIEmgEEKgoRCgcEAgIACJ8IEgabAQSdAQUK2gEKBAQCAgESBqUBAqYB
LxrJASBSZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIGFzc29jaWF0aW9uLCB3aGlj
aCB3aWxsIGJlY29tZSB0aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUgYXNzb2NpYXRpb24n
cyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgc2hvdWxkIGJlIDEtNjMgY2hhcmFjdGVy
cywgYW5kIHZhbGlkIGNoYXJhY3RlcnMgYXJlCiAvW2EtejAtOV8tXS8uCgoNCgUEAgIBBRIE
pQECCAoNCgUEAgIBARIEpQEJMQoNCgUEAgIBAxIEpQE0NQoNCgUEAgIBCBIEpgEGLgoQCggE
AgIBCJwIABIEpgEHLQpWCgQEAgICEgapAQKqAS8aRiBSZXF1aXJlZC4gVGhlIFJlc3RvcmVW
ZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb24gcmVzb3VyY2UgdG8gY3JlYXRlLgoKDQoFBAIC
AgYSBKkBAiQKDQoFBAICAgESBKkBJUoKDQoFBAICAgMSBKkBTU4KDQoFBAICAggSBKoBBi4K
EAoIBAICAgicCAASBKoBBy0KiQMKBAQCAgMSBrIBArUBBBr4AiBPcHRpb25hbC4gQW4gb3B0
aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1
ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwg
dGhlIHNlcnZlciB3aWxsIGtub3cKIHRoYXQgdGhlIHNlcnZlciBoYXMgYWxyZWFkeSByZWNl
aXZlZCB0aGUgZHVwbGljYXRlIHJlcXVlc3QgYW5kIGNhbiBhdm9pZAogcmVzcG9uZGluZyB3
aXRoIGFuIGVycm9yLiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRo
IHRoZQogZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzIG5vdCBzdXBwb3J0ZWQKICgwMDAw
MDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAICAwUSBLIBAggKDQoF
BAICAwESBLIBCRMKDQoFBAICAwMSBLIBFhcKDwoFBAICAwgSBrIBGLUBAwoTCgsEAgIDCMzx
+YoBARIEswEEKgoQCggEAgIDCJwIABIEtAEEKgpKCgIEAxIGuQEAxAEBGjwgUmVxdWVzdCBt
ZXNzYWdlIGZvciBHZXRSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uLgoKCwoD
BAMBEgS5AQg0CuoBCgQEAwIAEga+AQLDAQQa2QEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBu
YW1lIG9mIHRoZSBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uIHRvCiByZXRy
aWV2ZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vcmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zL3tyZXN0b3JlX3ZlcmlmaWNhdGlvbl9wbGFu
fS9hc3NvY2lhdGlvbnMve2Fzc29jaWF0aW9ufWAKCg0KBQQDAgAFEgS+AQIICg0KBQQDAgAB
EgS+AQkNCg0KBQQDAgADEgS+ARARCg8KBQQDAgAIEga+ARLDAQMKEAoIBAMCAAicCAASBL8B
BCoKEQoHBAMCAAifCBIGwAEEwgEFCkwKAgQEEgbHAQDmAQEaPiBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIExpc3RSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9ucy4KCgsKAwQEARIE
xwEINgquAQoEBAQCABIGywEC0AEEGp0BIFJlcXVpcmVkLiBUaGUgcGFyZW50IFJlc3RvcmVW
ZXJpZmljYXRpb25QbGFuIG5hbWUuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L3Jlc3RvcmVWZXJpZmljYXRpb25QbGFucy97cmVzdG9yZV92
ZXJpZmljYXRpb25fcGxhbn1gCgoNCgUEBAIABRIEywECCAoNCgUEBAIAARIEywEJDwoNCgUE
BAIAAxIEywESEwoPCgUEBAIACBIGywEU0AEDChAKCAQEAgAInAgAEgTMAQQqChEKBwQEAgAI
nwgSBs0BBM8BBQr6AQoEBAQCARIE1gECPxrrASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVt
YmVyIG9mIGFzc29jaWF0aW9ucyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1heQogcmV0dXJu
IGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4KIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwMCBh
c3NvY2lhdGlvbnMgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEw
MDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoFBAQC
AQUSBNYBAgcKDQoFBAQCAQESBNYBCBEKDQoFBAQCAQMSBNYBFBUKDQoFBAQCAQgSBNYBFj4K
EAoIBAQCAQicCAASBNYBFz0KswIKBAQEAgISBN8BAkEapAIgT3B0aW9uYWwuIEEgcGFnZSB0
b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgTGlzdFJlc3RvcmVWZXJpZmljYXRp
b25QbGFuQXNzb2NpYXRpb25zYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRo
ZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1l
dGVycyBwcm92aWRlZCB0bwogYExpc3RSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0
aW9uc2AgbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkCiB0aGUgcGFnZSB0b2tl
bi4KCg0KBQQEAgIFEgTfAQIICg0KBQQEAgIBEgTfAQkTCg0KBQQEAgIDEgTfARYXCg0KBQQE
AgIIEgTfARhAChAKCAQEAgIInAgAEgTfARk/CiwKBAQEAgMSBOIBAj0aHiBPcHRpb25hbC4g
RmlsdGVyaW5nIHJlc3VsdHMuCgoNCgUEBAIDBRIE4gECCAoNCgUEBAIDARIE4gEJDwoNCgUE
BAIDAxIE4gESEwoNCgUEBAIDCBIE4gEUPAoQCggEBAIDCJwIABIE4gEVOwo8CgQEBAIEEgTl
AQI/Gi4gT3B0aW9uYWwuIEhpbnQgZm9yIGhvdyB0byBvcmRlciB0aGUgcmVzdWx0cy4KCg0K
BQQEAgQFEgTlAQIICg0KBQQEAgQBEgTlAQkRCg0KBQQEAgQDEgTlARQVCg0KBQQEAgQIEgTl
ARY+ChAKCAQEAgQInAgAEgTlARc9Ck0KAgQFEgbpAQD1AQEaPyBSZXNwb25zZSBtZXNzYWdl
IGZvciBMaXN0UmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlvbnMuCgoLCgMEBQES
BOkBCDcKQgoEBAUCABIG6wEC7AExGjIgVGhlIGxpc3Qgb2YgUmVzdG9yZVZlcmlmaWNhdGlv
blBsYW5Bc3NvY2lhdGlvbnMuCgoNCgUEBQIABBIE6wECCgoNCgUEBQIABhIE6wELLQoNCgUE
BQIAARIE7AEGLAoNCgUEBQIAAxIE7AEvMAqQAQoEBAUCARIE8AECHRqBASBBIHRva2VuLCB3
aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQg
cGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVl
bnQgcGFnZXMuCgoNCgUEBQIBBRIE8AECCAoNCgUEBQIBARIE8AEJGAoNCgUEBQIBAxIE8AEb
HApGCgQEBQICEgbzAQL0ATUaNiBVbm9yZGVyZWQgbGlzdC4gTG9jYXRpb25zIHRoYXQgY291
bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEBQICBBIE8wECCgoNCgUEBQICBRIE8wELEQoNCgUE
BQICARIE8wESHQoNCgUEBQICAxIE8wEgIQoNCgUEBQICCBIE9AEGNAoQCggEBQICCJwIABIE
9AEHMwpNCgIEBhIG+AEAjgIBGj8gUmVxdWVzdCBtZXNzYWdlIGZvciBEZWxldGVSZXN0b3Jl
VmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uLgoKCwoDBAYBEgT4AQg3CugBCgQEBgIAEgb9
AQKCAgQa1wEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBSZXN0b3JlVmVy
aWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uIHRvCiBkZWxldGUuCiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jlc3RvcmVWZXJpZmljYXRpb25Q
bGFucy97cmVzdG9yZV92ZXJpZmljYXRpb25fcGxhbn0vYXNzb2NpYXRpb25zL3thc3NvY2lh
dGlvbn1gCgoNCgUEBgIABRIE/QECCAoNCgUEBgIAARIE/QEJDQoNCgUEBgIAAxIE/QEQEQoP
CgUEBgIACBIG/QESggIDChAKCAQGAgAInAgAEgT+AQQqChEKBwQGAgAInwgSBv8BBIECBQqJ
AwoEBAYCARIGigICjQIEGvgCIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRv
IGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRo
YXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25v
dwogdGhhdCB0aGUgc2VydmVyIGhhcyBhbHJlYWR5IHJlY2VpdmVkIHRoZSBkdXBsaWNhdGUg
cmVxdWVzdCBhbmQgY2FuIGF2b2lkCiByZXNwb25kaW5nIHdpdGggYW4gZXJyb3IuIFRoZSBy
ZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlCiBleGNlcHRpb24gdGhh
dCB6ZXJvIFVVSUQgaXMgbm90IHN1cHBvcnRlZAogKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAw
LTAwMDAwMDAwMDAwMCkuCgoNCgUEBgIBBRIEigICCAoNCgUEBgIBARIEigIJEwoNCgUEBgIB
AxIEigIWFwoPCgUEBgIBCBIGigIYjQIDChMKCwQGAgEIzPH5igEBEgSLAgQqChAKCAQGAgEI
nAgAEgSMAgQqCj8KAgQHEgaRAgCnAgEaMSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFRyaWdnZXJS
ZXN0b3JlVmVyaWZpY2F0aW9uLgoKCwoDBAcBEgSRAggpCukBCgQEBwIAEgaWAgKbAgQa2AEg
UmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBSZXN0b3JlVmVyaWZpY2F0aW9u
UGxhbkFzc29jaWF0aW9uIHRvCiB0cmlnZ2VyLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlVmVyaWZpY2F0aW9uUGxhbnMve3Jl
c3RvcmVfdmVyaWZpY2F0aW9uX3BsYW59L2Fzc29jaWF0aW9ucy97YXNzb2NpYXRpb259YAoK
DQoFBAcCAAUSBJYCAggKDQoFBAcCAAESBJYCCQ0KDQoFBAcCAAMSBJYCEBEKDwoFBAcCAAgS
BpYCEpsCAwoQCggEBwIACJwIABIElwIEKgoRCgcEBwIACJ8IEgaYAgSaAgUKiQMKBAQHAgES
BqMCAqYCBBr4AiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlm
eSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlv
dSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cKIHRoYXQg
dGhlIHNlcnZlciBoYXMgYWxyZWFkeSByZWNlaXZlZCB0aGUgZHVwbGljYXRlIHJlcXVlc3Qg
YW5kIGNhbiBhdm9pZAogcmVzcG9uZGluZyB3aXRoIGFuIGVycm9yLiBUaGUgcmVxdWVzdCBJ
RCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZQogZXhjZXB0aW9uIHRoYXQgemVybyBV
VUlEIGlzIG5vdCBzdXBwb3J0ZWQKICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAw
MDAwMDApLgoKDQoFBAcCAQUSBKMCAggKDQoFBAcCAQESBKMCCRMKDQoFBAcCAQMSBKMCFhcK
DwoFBAcCAQgSBqMCGKYCAwoTCgsEBwIBCMzx+YoBARIEpAIEKgoQCggEBwIBCJwIABIEpQIE
KgpACgIECBIGqgIAtAIBGjIgUmVzcG9uc2UgbWVzc2FnZSBmb3IgVHJpZ2dlclJlc3RvcmVW
ZXJpZmljYXRpb24uCgoLCgMECAESBKoCCCoKywEKBAQIAgASBq4CArMCBBq6ASBPdXRwdXQg
b25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGluaXRpYXRlZCBSZXN0b3JlVGVtcGxh
dGVFeGVjdXRpb24uCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L3Jlc3RvcmVUZW1wbGF0ZXMve3Jlc3RvcmVfdGVtcGxhdGV9L2V4ZWN1dGlv
bnMve2V4ZWN1dGlvbn1gCgoNCgUECAIABRIErgICCAoNCgUECAIAARIErgIJIwoNCgUECAIA
AxIErgImJwoPCgUECAIACBIGrgIoswIDChAKCAQIAgAInAgAEgSvAgQtChEKBwQIAgAInwgS
BrACBLICBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation ===
    # Fields for RestoreVerificationPlanAssociation
    # Field: restore_template Type: 9 ()
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.backupdr.v1beta.RestoreVerificationPlanAssociation.State)
    # Field: trigger_summary Type: 11 (.google.cloud.backupdr.v1beta.TriggerSummary)
    # Field: resource_type Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.backupdr.v1beta.RestoreVerificationPlanAssociation.LabelsEntry)

# Enum: RestoreVerificationPlanAssociation::State
our $RestoreVerificationPlanAssociation_STATE_UNSPECIFIED = 0;
our $RestoreVerificationPlanAssociation_CREATING = 1;
our $RestoreVerificationPlanAssociation_ACTIVE = 2;
our $RestoreVerificationPlanAssociation_DELETING = 3;
our $RestoreVerificationPlanAssociation_INACTIVE = 4;
our $RestoreVerificationPlanAssociation_UPDATING = 5;
our $RestoreVerificationPlanAssociation_ERROR = 6;

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerSummary ===
    # Fields for TriggerSummary
    # Field: last_trigger_time Type: 11 (.google.protobuf.Timestamp)
    # Field: next_trigger_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_trigger_error Type: 11 (.google.rpc.Status)
    # Field: last_verification_execution Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::CreateRestoreVerificationPlanAssociationRequest ===
    # Fields for CreateRestoreVerificationPlanAssociationRequest
    # Field: parent Type: 9 ()
    # Field: restore_verification_plan_association_id Type: 9 ()
    # Field: restore_verification_plan_association Type: 11 (.google.cloud.backupdr.v1beta.RestoreVerificationPlanAssociation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::GetRestoreVerificationPlanAssociationRequest ===
    # Fields for GetRestoreVerificationPlanAssociationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsRequest ===
    # Fields for ListRestoreVerificationPlanAssociationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsResponse ===
    # Fields for ListRestoreVerificationPlanAssociationsResponse
    # Field: restore_verification_plan_associations Type: 11 (.google.cloud.backupdr.v1beta.RestoreVerificationPlanAssociation)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::DeleteRestoreVerificationPlanAssociationRequest ===
    # Fields for DeleteRestoreVerificationPlanAssociationRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationRequest ===
    # Fields for TriggerRestoreVerificationRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationResponse ===
    # Fields for TriggerRestoreVerificationResponse
    # Field: restore_template_execution Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/restore_verification_plan_association.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation;

    my $msg = Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation->new({
        restore_template => $restore_template,
        name => $name,
        description => $description,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->restore_template();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/restore_verification_plan_association.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation

A `RestoreVerificationPlanAssociation` binds a specific workload to a
`RestoreVerificationPlan`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_template() >> / C<< $msg->restore_template($value) >>

Type: C<String>

Required. Immutable. The canonical name of the RestoreTemplate to
trigger.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the
`RestoreVerificationPlanAssociation`.

Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restore_verification_plan}/associations/{association}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the `RestoreVerificationPlanAssociation`
resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the association was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the association was updated.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::State>)

Output only. The `State` for the `RestoreVerificationPlanAssociation`.

=item * C<< $msg->trigger_summary() >> / C<< $msg->trigger_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerSummary>)

Output only. Results of the most recent automated restore initiation
and the next scheduled execution time.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. Immutable. The type of the Google Cloud resource (e.g.,
`compute.googleapis.com/Instance`, `sqladmin.googleapis.com/Instance`).

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation::LabelsEntry>)

Optional. User-defined labels.

=back

=head3 Enum: RestoreVerificationPlanAssociation::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=item * C<INACTIVE> => C<4>

=item * C<UPDATING> => C<5>

=item * C<ERROR> => C<6>

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerSummary

`TriggerSummary` contains the results of the most recent automated restore
initiation and the next scheduled execution time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->last_trigger_time() >> / C<< $msg->last_trigger_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time of the most recent trigger initiation.

=item * C<< $msg->next_trigger_time() >> / C<< $msg->next_trigger_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The scheduled time of the next trigger initiation.

=item * C<< $msg->last_trigger_error() >> / C<< $msg->last_trigger_error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. The error status of the most recent failed trigger.

=item * C<< $msg->last_verification_execution() >> / C<< $msg->last_verification_execution($value) >>

Type: C<String>

Output only. The resource name of the most recent initiated
RestoreTemplateExecution.
Format:
`projects/{project}/locations/{location}/restoreTemplates/{restore_template}/executions/{execution}`

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::CreateRestoreVerificationPlanAssociationRequest

Request message for CreateRestoreVerificationPlanAssociation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this association will be created.
Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restore_verification_plan}`

=item * C<< $msg->restore_verification_plan_association_id() >> / C<< $msg->restore_verification_plan_association_id($value) >>

Type: C<String>

Required. The ID to use for the association, which will become the final
component of the association's resource name.

This value should be 1-63 characters, and valid characters are
/[a-z0-9_-]/.

=item * C<< $msg->restore_verification_plan_association() >> / C<< $msg->restore_verification_plan_association($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation>)

Required. The RestoreVerificationPlanAssociation resource to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know
that the server has already received the duplicate request and can avoid
responding with an error. The request ID must be a valid UUID with the
exception that zero UUID is not supported
(00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::GetRestoreVerificationPlanAssociationRequest

Request message for GetRestoreVerificationPlanAssociation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the RestoreVerificationPlanAssociation to
retrieve.
Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restore_verification_plan}/associations/{association}`

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsRequest

Request message for ListRestoreVerificationPlanAssociations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent RestoreVerificationPlan name.
Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restore_verification_plan}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of associations to return. The service may
return fewer than this value.
If unspecified, at most 500 associations will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListRestoreVerificationPlanAssociations` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
`ListRestoreVerificationPlanAssociations` must match the call that provided
the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filtering results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Hint for how to order the results.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsResponse

Response message for ListRestoreVerificationPlanAssociations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_verification_plan_associations() >> / C<< $msg->restore_verification_plan_associations($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation>)

The list of RestoreVerificationPlanAssociations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::DeleteRestoreVerificationPlanAssociationRequest

Request message for DeleteRestoreVerificationPlanAssociation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the RestoreVerificationPlanAssociation to
delete.
Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restore_verification_plan}/associations/{association}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know
that the server has already received the duplicate request and can avoid
responding with an error. The request ID must be a valid UUID with the
exception that zero UUID is not supported
(00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationRequest

Request message for TriggerRestoreVerification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the RestoreVerificationPlanAssociation to
trigger.
Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restore_verification_plan}/associations/{association}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know
that the server has already received the duplicate request and can avoid
responding with an error. The request ID must be a valid UUID with the
exception that zero UUID is not supported
(00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationResponse

Response message for TriggerRestoreVerification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_template_execution() >> / C<< $msg->restore_template_execution($value) >>

Type: C<String>

Output only. The resource name of the initiated RestoreTemplateExecution.
Format:
`projects/{project}/locations/{location}/restoreTemplates/{restore_template}/executions/{execution}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
