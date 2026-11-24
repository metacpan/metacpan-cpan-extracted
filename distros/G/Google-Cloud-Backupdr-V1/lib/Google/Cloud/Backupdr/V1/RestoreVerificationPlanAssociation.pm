package Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation;

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
CkRnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvcmVzdG9yZV92ZXJpZmljYXRpb25fcGxhbl9h
c3NvY2lhdGlvbi5wcm90bxIYZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvItUICiJSZXN0b3JlVmVyaWZpY2F0aW9uUGxh
bkFzc29jaWF0aW9uEhoKBG5hbWUYASABKAlCBuBBA+BBCFIEbmFtZRIlCgtkZXNjcmlwdGlv
bhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgE
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJdCgVz
dGF0ZRgFIAEoDjJCLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5SZXN0b3JlVmVyaWZpY2F0
aW9uUGxhbkFzc29jaWF0aW9uLlN0YXRlQgPgQQNSBXN0YXRlElYKD3RyaWdnZXJfc3VtbWFy
eRgGIAEoCzIoLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5UcmlnZ2VyU3VtbWFyeUID4EED
Ug50cmlnZ2VyU3VtbWFyeRIrCg1yZXNvdXJjZV90eXBlGAcgASgJQgbgQQLgQQVSDHJlc291
cmNlVHlwZRJfChByZXN0b3JlX3RlbXBsYXRlGAggASgJQjLgQQLgQQX6QSkKJ2JhY2t1cGRy
Lmdvb2dsZWFwaXMuY29tL1Jlc3RvcmVUZW1wbGF0ZUgAUg9yZXN0b3JlVGVtcGxhdGUSZQoG
bGFiZWxzGAkgAygLMkguZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLlJlc3RvcmVWZXJpZmlj
YXRpb25QbGFuQXNzb2NpYXRpb24uTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzGjkKC0xhYmVs
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEibQoF
U3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgoKBkFDVElWRRAC
EgwKCERFTEVUSU5HEAMSDAoISU5BQ1RJVkUQBBIMCghVUERBVElORxAFEgkKBUVSUk9SEAY6
ggLqQf4BCjpiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVmVyaWZpY2F0aW9uUGxh
bkFzc29jaWF0aW9uEndwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
cmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zL3tyZXN0b3JlX3ZlcmlmaWNhdGlvbl9wbGFufS9h
c3NvY2lhdGlvbnMve2Fzc29jaWF0aW9ufSojcmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3Nv
Y2lhdGlvbnMyInJlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25CDQoLYXNzb2Np
YXRpb24i6wIKDlRyaWdnZXJTdW1tYXJ5EksKEWxhc3RfdHJpZ2dlcl90aW1lGAEgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUg9sYXN0VHJpZ2dlclRpbWUSSwoRbmV4
dF90cmlnZ2VyX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
D25leHRUcmlnZ2VyVGltZRJFChJsYXN0X3RyaWdnZXJfZXJyb3IYAyABKAsyEi5nb29nbGUu
cnBjLlN0YXR1c0ID4EEDUhBsYXN0VHJpZ2dlckVycm9yEngKG2xhc3RfdmVyaWZpY2F0aW9u
X2V4ZWN1dGlvbhgEIAEoCUI44EED+kEyCjBiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0
b3JlVGVtcGxhdGVFeGVjdXRpb25SGWxhc3RWZXJpZmljYXRpb25FeGVjdXRpb24iogMKL0Ny
ZWF0ZVJlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25SZXF1ZXN0Ek8KBnBhcmVu
dBgBIAEoCUI34EEC+kExCi9iYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVmVyaWZp
Y2F0aW9uUGxhblIGcGFyZW50ElsKKHJlc3RvcmVfdmVyaWZpY2F0aW9uX3BsYW5fYXNzb2Np
YXRpb25faWQYAiABKAlCA+BBAlIkcmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlv
bklkEpQBCiVyZXN0b3JlX3ZlcmlmaWNhdGlvbl9wbGFuX2Fzc29jaWF0aW9uGAMgASgLMjwu
Z29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLlJlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2Np
YXRpb25CA+BBAlIicmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlvbhIqCgpyZXF1
ZXN0X2lkGAQgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElkIoYBCixHZXRSZXN0b3JlVmVy
aWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uUmVxdWVzdBJWCgRuYW1lGAEgASgJQkLgQQL6QTwK
OmJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2Np
YXRpb25SBG5hbWUihAIKLkxpc3RSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9u
c1JlcXVlc3QSTwoGcGFyZW50GAEgASgJQjfgQQL6QTEKL2JhY2t1cGRyLmdvb2dsZWFwaXMu
Y29tL1Jlc3RvcmVWZXJpZmljYXRpb25QbGFuUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgF
QgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsK
BmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3Jk
ZXJCeSKUAgovTGlzdFJlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25zUmVzcG9u
c2USkQEKJnJlc3RvcmVfdmVyaWZpY2F0aW9uX3BsYW5fYXNzb2NpYXRpb25zGAEgAygLMjwu
Z29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxLlJlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2Np
YXRpb25SI3Jlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25zEiYKD25leHRfcGFn
ZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIlCgt1bnJlYWNoYWJsZRgDIAMoCUID4EEG
Ugt1bnJlYWNoYWJsZSK1AQovRGVsZXRlUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lh
dGlvblJlcXVlc3QSVgoEbmFtZRgBIAEoCUJC4EEC+kE8CjpiYWNrdXBkci5nb29nbGVhcGlz
LmNvbS9SZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uUgRuYW1lEioKCnJlcXVl
c3RfaWQYAiABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQipwEKIVRyaWdnZXJSZXN0b3Jl
VmVyaWZpY2F0aW9uUmVxdWVzdBJWCgRuYW1lGAEgASgJQkLgQQL6QTwKOmJhY2t1cGRyLmdv
b2dsZWFwaXMuY29tL1Jlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25SBG5hbWUS
KgoKcmVxdWVzdF9pZBgCIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCKcAQoiVHJpZ2dl
clJlc3RvcmVWZXJpZmljYXRpb25SZXNwb25zZRJ2ChpyZXN0b3JlX3RlbXBsYXRlX2V4ZWN1
dGlvbhgBIAEoCUI44EED+kEyCjBiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVGVt
cGxhdGVFeGVjdXRpb25SGHJlc3RvcmVUZW1wbGF0ZUV4ZWN1dGlvbkLXAQocY29tLmdvb2ds
ZS5jbG91ZC5iYWNrdXBkci52MUInUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlv
blByb3RvUAFaOGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIvYXBpdjEvYmFja3VwZHJw
YjtiYWNrdXBkcnBiqgIYR29vZ2xlLkNsb3VkLkJhY2t1cERSLlYxygIYR29vZ2xlXENsb3Vk
XEJhY2t1cERSXFYx6gIbR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6OlYxSuBQCgcSBQ4AtAIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMS
ACkKCQoCAwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVACkKCQoCAwQSAxYAIQoICgEIEgMY
ADUKCQoCCCUSAxgANQoICgEIEgMZAE8KCQoCCAsSAxkATwoICgEIEgMaACIKCQoCCAoSAxoA
IgoICgEIEgMbAEgKCQoCCAgSAxsASAoICgEIEgMcADUKCQoCCAESAxwANQoICgEIEgMdADUK
CQoCCCkSAx0ANQoICgEIEgMeADQKCQoCCC0SAx4ANApvCgIEABIEIgB3ARpjIEEgYFJlc3Rv
cmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25gIGJpbmRzIGEgc3BlY2lmaWMgd29ya2xv
YWQgdG8gYQogYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYC4KCgoKAwQAARIDIggqCgsKAwQA
BxIEIwIoBAoNCgUEAAedCBIEIwIoBApjCgQEAAQAEgQsAkEDGlUgYFN0YXRlYCBlbnVtZXJh
dGVzIHRoZSBwb3NzaWJsZSBzdGF0ZXMgZm9yIGEKIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxh
bkFzc29jaWF0aW9uYC4KCgwKBQQABAABEgMsBwwKHwoGBAAEAAIAEgMuBBoaECBTdGF0ZSBu
b3Qgc2V0LgoKDgoHBAAEAAIAARIDLgQVCg4KBwQABAACAAISAy4YGQovCgYEAAQAAgESAzEE
ERogIFRoZSByZXNvdXJjZSBpcyBiZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDMQQMCg4K
BwQABAACAQISAzEPEApDCgYEAAQAAgISAzQEDxo0IFRoZSByZXNvdXJjZSBoYXMgYmVlbiBj
cmVhdGVkIGFuZCBpcyBmdWxseSB1c2FibGUuCgoOCgcEAAQAAgIBEgM0BAoKDgoHBAAEAAIC
AhIDNA0OCi8KBgQABAACAxIDNwQRGiAgVGhlIHJlc291cmNlIGlzIGJlaW5nIGRlbGV0ZWQu
CgoOCgcEAAQAAgMBEgM3BAwKDgoHBAAEAAIDAhIDNw8QCkEKBgQABAACBBIDOgQRGjIgVGhl
IHJlc291cmNlIGhhcyBiZWVuIGNyZWF0ZWQgYnV0IGlzIG5vdCB1c2FibGUuCgoOCgcEAAQA
AgQBEgM6BAwKDgoHBAAEAAIEAhIDOg8QCi8KBgQABAACBRIDPQQRGiAgVGhlIHJlc291cmNl
IGlzIGJlaW5nIHVwZGF0ZWQuCgoOCgcEAAQAAgUBEgM9BAwKDgoHBAAEAAIFAhIDPQ8QClAK
BgQABAACBhIDQAQOGkEgVGhlIHJlc291cmNlIGlzIGluIGFuIGVycm9yIHN0YXRlIGR1ZSB0
byBhIGNvbmZpZ3VyYXRpb24gaXNzdWUuCgoOCgcEAAQAAgYBEgNABAkKDgoHBAAEAAIGAhID
QAwNCu4BCgQEAAIAEgRIAksEGt8BIE91dHB1dCBvbmx5LiBJZGVudGlmaWVyLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUKIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9u
YC4KCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L3Jlc3RvcmVWZXJpZmljYXRpb25QbGFucy97cmVzdG9yZV92ZXJpZmljYXRpb25fcGxhbn0v
YXNzb2NpYXRpb25zL3thc3NvY2lhdGlvbn1gCgoMCgUEAAIABRIDSAIICgwKBQQAAgABEgNI
CQ0KDAoFBAACAAMSA0gQEQoNCgUEAAIACBIESBJLAwoPCggEAAIACJwIABIDSQQtCg8KCAQA
AgAInAgBEgNKBCwKXwoEBAACARIDTwJCGlIgT3B0aW9uYWwuIFRoZSBkZXNjcmlwdGlvbiBv
ZiB0aGUgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb25gCiByZXNvdXJjZS4K
CgwKBQQAAgEFEgNPAggKDAoFBAACAQESA08JFAoMCgUEAAIBAxIDTxcYCgwKBQQAAgEIEgNP
GUEKDwoIBAACAQicCAASA08aQApHCgQEAAICEgRSAlMyGjkgT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIHdoZW4gdGhlIGFzc29jaWF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACAgYSA1ICGwoM
CgUEAAICARIDUhwnCgwKBQQAAgIDEgNSKisKDAoFBAACAggSA1MGMQoPCggEAAICCJwIABID
UwcwCkcKBAQAAgMSBFYCVzIaOSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgYXNz
b2NpYXRpb24gd2FzIHVwZGF0ZWQuCgoMCgUEAAIDBhIDVgIbCgwKBQQAAgMBEgNWHCcKDAoF
BAACAwMSA1YqKwoMCgUEAAIDCBIDVwYxCg8KCAQAAgMInAgAEgNXBzAKVQoEBAACBBIDWgI+
GkggT3V0cHV0IG9ubHkuIFRoZSBgU3RhdGVgIGZvciB0aGUgYFJlc3RvcmVWZXJpZmljYXRp
b25QbGFuQXNzb2NpYXRpb25gLgoKDAoFBAACBAYSA1oCBwoMCgUEAAIEARIDWggNCgwKBQQA
AgQDEgNaEBEKDAoFBAACBAgSA1oSPQoPCggEAAIECJwIABIDWhM8CnwKBAQAAgUSBF4CXzIa
biBPdXRwdXQgb25seS4gUmVzdWx0cyBvZiB0aGUgbW9zdCByZWNlbnQgYXV0b21hdGVkIHJl
c3RvcmUgaW5pdGlhdGlvbgogYW5kIHRoZSBuZXh0IHNjaGVkdWxlZCBleGVjdXRpb24gdGlt
ZS4KCgwKBQQAAgUGEgNeAhAKDAoFBAACBQESA14RIAoMCgUEAAIFAxIDXiMkCgwKBQQAAgUI
EgNfBjEKDwoIBAACBQicCAASA18HMAqbAQoEBAACBhIEYwJmBBqMASBSZXF1aXJlZC4gSW1t
dXRhYmxlLiBUaGUgdHlwZSBvZiB0aGUgR29vZ2xlIENsb3VkIHJlc291cmNlIChlLmcuLAog
YGNvbXB1dGUuZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VgLCBgc3FsYWRtaW4uZ29vZ2xlYXBp
cy5jb20vSW5zdGFuY2VgKS4KCgwKBQQAAgYFEgNjAggKDAoFBAACBgESA2MJFgoMCgUEAAIG
AxIDYxkaCg0KBQQAAgYIEgRjG2YDCg8KCAQAAgYInAgAEgNkBCoKDwoIBAACBgicCAESA2UE
KwouCgQEAAgAEgRpAnMDGiAgVGhlIHNwZWNpZmljIGFzc29jaWF0aW9uIGxpbmsuCgoMCgUE
AAgAARIDaQgTClsKBAQAAgcSBGwEcgYaTSBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgY2Fu
b25pY2FsIG5hbWUgb2YgdGhlIFJlc3RvcmVUZW1wbGF0ZSB0bwogdHJpZ2dlci4KCgwKBQQA
AgcFEgNsBAoKDAoFBAACBwESA2wLGwoMCgUEAAIHAxIDbB4fCg0KBQQAAgcIEgRsIHIFCg8K
CAQAAgcInAgAEgNtBiwKDwoIBAACBwicCAESA24GLQoPCgcEAAIHCJ8IEgRvBnEHCi0KBAQA
AggSA3YCShogIE9wdGlvbmFsLiBVc2VyLWRlZmluZWQgbGFiZWxzLgoKDAoFBAACCAYSA3YC
FQoMCgUEAAIIARIDdhYcCgwKBQQAAggDEgN2HyAKDAoFBAACCAgSA3YhSQoPCggEAAIICJwI
ABIDdiJICowBCgIEARIFewCSAQEafyBgVHJpZ2dlclN1bW1hcnlgIGNvbnRhaW5zIHRoZSBy
ZXN1bHRzIG9mIHRoZSBtb3N0IHJlY2VudCBhdXRvbWF0ZWQgcmVzdG9yZQogaW5pdGlhdGlv
biBhbmQgdGhlIG5leHQgc2NoZWR1bGVkIGV4ZWN1dGlvbiB0aW1lLgoKCgoDBAEBEgN7CBYK
TAoEBAECABIEfQJ+Mho+IE91dHB1dCBvbmx5LiBUaGUgdGltZSBvZiB0aGUgbW9zdCByZWNl
bnQgdHJpZ2dlciBpbml0aWF0aW9uLgoKDAoFBAECAAYSA30CGwoMCgUEAQIAARIDfRwtCgwK
BQQBAgADEgN9MDEKDAoFBAECAAgSA34GMQoPCggEAQIACJwIABIDfgcwClEKBAQBAgESBoEB
AoIBMhpBIE91dHB1dCBvbmx5LiBUaGUgc2NoZWR1bGVkIHRpbWUgb2YgdGhlIG5leHQgdHJp
Z2dlciBpbml0aWF0aW9uLgoKDQoFBAECAQYSBIEBAhsKDQoFBAECAQESBIEBHC0KDQoFBAEC
AQMSBIEBMDEKDQoFBAECAQgSBIIBBjEKEAoIBAECAQicCAASBIIBBzAKUgoEBAECAhIGhQEC
hgEyGkIgT3V0cHV0IG9ubHkuIFRoZSBlcnJvciBzdGF0dXMgb2YgdGhlIG1vc3QgcmVjZW50
IGZhaWxlZCB0cmlnZ2VyLgoKDQoFBAECAgYSBIUBAhMKDQoFBAECAgESBIUBFCYKDQoFBAEC
AgMSBIUBKSoKDQoFBAECAggSBIYBBjEKEAoIBAECAgicCAASBIYBBzAK2AEKBAQBAgMSBowB
ApEBBBrHASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIG1vc3QgcmVj
ZW50IGluaXRpYXRlZAogUmVzdG9yZVRlbXBsYXRlRXhlY3V0aW9uLgogRm9ybWF0OgogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlVGVtcGxhdGVz
L3tyZXN0b3JlX3RlbXBsYXRlfS9leGVjdXRpb25zL3tleGVjdXRpb259YAoKDQoFBAECAwUS
BIwBAggKDQoFBAECAwESBIwBCSQKDQoFBAECAwMSBIwBJygKDwoFBAECAwgSBowBKZEBAwoQ
CggEAQIDCJwIABIEjQEELQoRCgcEAQIDCJ8IEgaOAQSQAQUKTQoCBAISBpUBALYBARo/IFJl
cXVlc3QgbWVzc2FnZSBmb3IgQ3JlYXRlUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lh
dGlvbi4KCgsKAwQCARIElQEINwrBAQoEBAICABIGmQECngEEGrABIFJlcXVpcmVkLiBUaGUg
cGFyZW50IHJlc291cmNlIHdoZXJlIHRoaXMgYXNzb2NpYXRpb24gd2lsbCBiZSBjcmVhdGVk
LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9y
ZXN0b3JlVmVyaWZpY2F0aW9uUGxhbnMve3Jlc3RvcmVfdmVyaWZpY2F0aW9uX3BsYW59YAoK
DQoFBAICAAUSBJkBAggKDQoFBAICAAESBJkBCQ8KDQoFBAICAAMSBJkBEhMKDwoFBAICAAgS
BpkBFJ4BAwoQCggEAgIACJwIABIEmgEEKgoRCgcEAgIACJ8IEgabAQSdAQUK2gEKBAQCAgES
BqUBAqYBLxrJASBSZXF1aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIGFzc29jaWF0aW9u
LCB3aGljaCB3aWxsIGJlY29tZSB0aGUgZmluYWwKIGNvbXBvbmVudCBvZiB0aGUgYXNzb2Np
YXRpb24ncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgc2hvdWxkIGJlIDEtNjMgY2hh
cmFjdGVycywgYW5kIHZhbGlkIGNoYXJhY3RlcnMgYXJlCiAvW2EtejAtOV8tXS8uCgoNCgUE
AgIBBRIEpQECCAoNCgUEAgIBARIEpQEJMQoNCgUEAgIBAxIEpQE0NQoNCgUEAgIBCBIEpgEG
LgoQCggEAgIBCJwIABIEpgEHLQpWCgQEAgICEgapAQKqAS8aRiBSZXF1aXJlZC4gVGhlIFJl
c3RvcmVWZXJpZmljYXRpb25QbGFuQXNzb2NpYXRpb24gcmVzb3VyY2UgdG8gY3JlYXRlLgoK
DQoFBAICAgYSBKkBAiQKDQoFBAICAgESBKkBJUoKDQoFBAICAgMSBKkBTU4KDQoFBAICAggS
BKoBBi4KEAoIBAICAgicCAASBKoBBy0KiQMKBAQCAgMSBrIBArUBBBr4AiBPcHRpb25hbC4g
QW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBh
IHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVx
dWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cKIHRoYXQgdGhlIHNlcnZlciBoYXMgYWxyZWFk
eSByZWNlaXZlZCB0aGUgZHVwbGljYXRlIHJlcXVlc3QgYW5kIGNhbiBhdm9pZAogcmVzcG9u
ZGluZyB3aXRoIGFuIGVycm9yLiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJ
RCB3aXRoIHRoZQogZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzIG5vdCBzdXBwb3J0ZWQK
ICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAICAwUSBLIB
AggKDQoFBAICAwESBLIBCRMKDQoFBAICAwMSBLIBFhcKDwoFBAICAwgSBrIBGLUBAwoTCgsE
AgIDCMzx+YoBARIEswEEKgoQCggEAgIDCJwIABIEtAEEKgpKCgIEAxIGuQEAxAEBGjwgUmVx
dWVzdCBtZXNzYWdlIGZvciBHZXRSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9u
LgoKCwoDBAMBEgS5AQg0CuoBCgQEAwIAEga+AQLDAQQa2QEgUmVxdWlyZWQuIFRoZSByZXNv
dXJjZSBuYW1lIG9mIHRoZSBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uIHRv
CiByZXRyaWV2ZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vcmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zL3tyZXN0b3JlX3ZlcmlmaWNhdGlv
bl9wbGFufS9hc3NvY2lhdGlvbnMve2Fzc29jaWF0aW9ufWAKCg0KBQQDAgAFEgS+AQIICg0K
BQQDAgABEgS+AQkNCg0KBQQDAgADEgS+ARARCg8KBQQDAgAIEga+ARLDAQMKEAoIBAMCAAic
CAASBL8BBCoKEQoHBAMCAAifCBIGwAEEwgEFCkwKAgQEEgbHAQDmAQEaPiBSZXF1ZXN0IG1l
c3NhZ2UgZm9yIExpc3RSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9ucy4KCgsK
AwQEARIExwEINgquAQoEBAQCABIGywEC0AEEGp0BIFJlcXVpcmVkLiBUaGUgcGFyZW50IFJl
c3RvcmVWZXJpZmljYXRpb25QbGFuIG5hbWUuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jlc3RvcmVWZXJpZmljYXRpb25QbGFucy97cmVz
dG9yZV92ZXJpZmljYXRpb25fcGxhbn1gCgoNCgUEBAIABRIEywECCAoNCgUEBAIAARIEywEJ
DwoNCgUEBAIAAxIEywESEwoPCgUEBAIACBIGywEU0AEDChAKCAQEAgAInAgAEgTMAQQqChEK
BwQEAgAInwgSBs0BBM8BBQr6AQoEBAQCARIE1gECPxrrASBPcHRpb25hbC4gVGhlIG1heGlt
dW0gbnVtYmVyIG9mIGFzc29jaWF0aW9ucyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1heQog
cmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4KIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0
IDUwMCBhc3NvY2lhdGlvbnMgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVtIHZhbHVl
IGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoK
DQoFBAQCAQUSBNYBAgcKDQoFBAQCAQESBNYBCBEKDQoFBAQCAQMSBNYBFBUKDQoFBAQCAQgS
BNYBFj4KEAoIBAQCAQicCAASBNYBFz0KswIKBAQEAgISBN8BAkEapAIgT3B0aW9uYWwuIEEg
cGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgTGlzdFJlc3RvcmVWZXJp
ZmljYXRpb25QbGFuQXNzb2NpYXRpb25zYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJp
ZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIg
cGFyYW1ldGVycyBwcm92aWRlZCB0bwogYExpc3RSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFz
c29jaWF0aW9uc2AgbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkCiB0aGUgcGFn
ZSB0b2tlbi4KCg0KBQQEAgIFEgTfAQIICg0KBQQEAgIBEgTfAQkTCg0KBQQEAgIDEgTfARYX
Cg0KBQQEAgIIEgTfARhAChAKCAQEAgIInAgAEgTfARk/CiwKBAQEAgMSBOIBAj0aHiBPcHRp
b25hbC4gRmlsdGVyaW5nIHJlc3VsdHMuCgoNCgUEBAIDBRIE4gECCAoNCgUEBAIDARIE4gEJ
DwoNCgUEBAIDAxIE4gESEwoNCgUEBAIDCBIE4gEUPAoQCggEBAIDCJwIABIE4gEVOwo8CgQE
BAIEEgTlAQI/Gi4gT3B0aW9uYWwuIEhpbnQgZm9yIGhvdyB0byBvcmRlciB0aGUgcmVzdWx0
cy4KCg0KBQQEAgQFEgTlAQIICg0KBQQEAgQBEgTlAQkRCg0KBQQEAgQDEgTlARQVCg0KBQQE
AgQIEgTlARY+ChAKCAQEAgQInAgAEgTlARc9Ck0KAgQFEgbpAQD1AQEaPyBSZXNwb25zZSBt
ZXNzYWdlIGZvciBMaXN0UmVzdG9yZVZlcmlmaWNhdGlvblBsYW5Bc3NvY2lhdGlvbnMuCgoL
CgMEBQESBOkBCDcKQgoEBAUCABIG6wEC7AExGjIgVGhlIGxpc3Qgb2YgUmVzdG9yZVZlcmlm
aWNhdGlvblBsYW5Bc3NvY2lhdGlvbnMuCgoNCgUEBQIABBIE6wECCgoNCgUEBQIABhIE6wEL
LQoNCgUEBQIAARIE7AEGLAoNCgUEBQIAAxIE7AEvMAqQAQoEBAUCARIE8AECHRqBASBBIHRv
a2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhl
IG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1
YnNlcXVlbnQgcGFnZXMuCgoNCgUEBQIBBRIE8AECCAoNCgUEBQIBARIE8AEJGAoNCgUEBQIB
AxIE8AEbHApGCgQEBQICEgbzAQL0ATUaNiBVbm9yZGVyZWQgbGlzdC4gTG9jYXRpb25zIHRo
YXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEBQICBBIE8wECCgoNCgUEBQICBRIE8wEL
EQoNCgUEBQICARIE8wESHQoNCgUEBQICAxIE8wEgIQoNCgUEBQICCBIE9AEGNAoQCggEBQIC
CJwIABIE9AEHMwpNCgIEBhIG+AEAjgIBGj8gUmVxdWVzdCBtZXNzYWdlIGZvciBEZWxldGVS
ZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uLgoKCwoDBAYBEgT4AQg3CugBCgQE
BgIAEgb9AQKCAgQa1wEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBSZXN0
b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9uIHRvCiBkZWxldGUuCiBGb3JtYXQ6CiBg
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jlc3RvcmVWZXJpZmlj
YXRpb25QbGFucy97cmVzdG9yZV92ZXJpZmljYXRpb25fcGxhbn0vYXNzb2NpYXRpb25zL3th
c3NvY2lhdGlvbn1gCgoNCgUEBgIABRIE/QECCAoNCgUEBgIAARIE/QEJDQoNCgUEBgIAAxIE
/QEQEQoPCgUEBgIACBIG/QESggIDChAKCAQGAgAInAgAEgT+AQQqChEKBwQGAgAInwgSBv8B
BIECBQqJAwoEBAYCARIGigICjQIEGvgCIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0
IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElE
IHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdp
bGwga25vdwogdGhhdCB0aGUgc2VydmVyIGhhcyBhbHJlYWR5IHJlY2VpdmVkIHRoZSBkdXBs
aWNhdGUgcmVxdWVzdCBhbmQgY2FuIGF2b2lkCiByZXNwb25kaW5nIHdpdGggYW4gZXJyb3Iu
IFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlCiBleGNlcHRp
b24gdGhhdCB6ZXJvIFVVSUQgaXMgbm90IHN1cHBvcnRlZAogKDAwMDAwMDAwLTAwMDAtMDAw
MC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBgIBBRIEigICCAoNCgUEBgIBARIEigIJEwoN
CgUEBgIBAxIEigIWFwoPCgUEBgIBCBIGigIYjQIDChMKCwQGAgEIzPH5igEBEgSLAgQqChAK
CAQGAgEInAgAEgSMAgQqCj8KAgQHEgaRAgCnAgEaMSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFRy
aWdnZXJSZXN0b3JlVmVyaWZpY2F0aW9uLgoKCwoDBAcBEgSRAggpCukBCgQEBwIAEgaWAgKb
AgQa2AEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBSZXN0b3JlVmVyaWZp
Y2F0aW9uUGxhbkFzc29jaWF0aW9uIHRvCiB0cmlnZ2VyLgogRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlVmVyaWZpY2F0aW9uUGxh
bnMve3Jlc3RvcmVfdmVyaWZpY2F0aW9uX3BsYW59L2Fzc29jaWF0aW9ucy97YXNzb2NpYXRp
b259YAoKDQoFBAcCAAUSBJYCAggKDQoFBAcCAAESBJYCCQ0KDQoFBAcCAAMSBJYCEBEKDwoF
BAcCAAgSBpYCEpsCAwoQCggEBwIACJwIABIElwIEKgoRCgcEBwIACJ8IEgaYAgSaAgUKiQMK
BAQHAgESBqMCAqYCBBr4AiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBp
ZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0
IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cK
IHRoYXQgdGhlIHNlcnZlciBoYXMgYWxyZWFkeSByZWNlaXZlZCB0aGUgZHVwbGljYXRlIHJl
cXVlc3QgYW5kIGNhbiBhdm9pZAogcmVzcG9uZGluZyB3aXRoIGFuIGVycm9yLiBUaGUgcmVx
dWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZQogZXhjZXB0aW9uIHRoYXQg
emVybyBVVUlEIGlzIG5vdCBzdXBwb3J0ZWQKICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0w
MDAwMDAwMDAwMDApLgoKDQoFBAcCAQUSBKMCAggKDQoFBAcCAQESBKMCCRMKDQoFBAcCAQMS
BKMCFhcKDwoFBAcCAQgSBqMCGKYCAwoTCgsEBwIBCMzx+YoBARIEpAIEKgoQCggEBwIBCJwI
ABIEpQIEKgpACgIECBIGqgIAtAIBGjIgUmVzcG9uc2UgbWVzc2FnZSBmb3IgVHJpZ2dlclJl
c3RvcmVWZXJpZmljYXRpb24uCgoLCgMECAESBKoCCCoKywEKBAQIAgASBq4CArMCBBq6ASBP
dXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGluaXRpYXRlZCBSZXN0b3Jl
VGVtcGxhdGVFeGVjdXRpb24uCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L3Jlc3RvcmVUZW1wbGF0ZXMve3Jlc3RvcmVfdGVtcGxhdGV9L2V4
ZWN1dGlvbnMve2V4ZWN1dGlvbn1gCgoNCgUECAIABRIErgICCAoNCgUECAIAARIErgIJIwoN
CgUECAIAAxIErgImJwoPCgUECAIACBIGrgIoswIDChAKCAQIAgAInAgAEgSvAgQtChEKBwQI
AgAInwgSBrACBLICBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation ===
    # Fields for RestoreVerificationPlanAssociation
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.backupdr.v1.RestoreVerificationPlanAssociation.State)
    # Field: trigger_summary Type: 11 (.google.cloud.backupdr.v1.TriggerSummary)
    # Field: resource_type Type: 9 ()
    # Field: restore_template Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.backupdr.v1.RestoreVerificationPlanAssociation.LabelsEntry)

# Enum: RestoreVerificationPlanAssociation::State
our $RestoreVerificationPlanAssociation_STATE_UNSPECIFIED = 0;
our $RestoreVerificationPlanAssociation_CREATING = 1;
our $RestoreVerificationPlanAssociation_ACTIVE = 2;
our $RestoreVerificationPlanAssociation_DELETING = 3;
our $RestoreVerificationPlanAssociation_INACTIVE = 4;
our $RestoreVerificationPlanAssociation_UPDATING = 5;
our $RestoreVerificationPlanAssociation_ERROR = 6;

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::TriggerSummary ===
    # Fields for TriggerSummary
    # Field: last_trigger_time Type: 11 (.google.protobuf.Timestamp)
    # Field: next_trigger_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_trigger_error Type: 11 (.google.rpc.Status)
    # Field: last_verification_execution Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::CreateRestoreVerificationPlanAssociationRequest ===
    # Fields for CreateRestoreVerificationPlanAssociationRequest
    # Field: parent Type: 9 ()
    # Field: restore_verification_plan_association_id Type: 9 ()
    # Field: restore_verification_plan_association Type: 11 (.google.cloud.backupdr.v1.RestoreVerificationPlanAssociation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::GetRestoreVerificationPlanAssociationRequest ===
    # Fields for GetRestoreVerificationPlanAssociationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsRequest ===
    # Fields for ListRestoreVerificationPlanAssociationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsResponse ===
    # Fields for ListRestoreVerificationPlanAssociationsResponse
    # Field: restore_verification_plan_associations Type: 11 (.google.cloud.backupdr.v1.RestoreVerificationPlanAssociation)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::DeleteRestoreVerificationPlanAssociationRequest ===
    # Fields for DeleteRestoreVerificationPlanAssociationRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::TriggerRestoreVerificationRequest ===
    # Fields for TriggerRestoreVerificationRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::TriggerRestoreVerificationResponse ===
    # Fields for TriggerRestoreVerificationResponse
    # Field: restore_template_execution Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/restore_verification_plan_association.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation;

    my $msg = Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/restore_verification_plan_association.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation

A `RestoreVerificationPlanAssociation` binds a specific workload to a
`RestoreVerificationPlan`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

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

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::State>)

Output only. The `State` for the `RestoreVerificationPlanAssociation`.

=item * C<< $msg->trigger_summary() >> / C<< $msg->trigger_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::TriggerSummary>)

Output only. Results of the most recent automated restore initiation
and the next scheduled execution time.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. Immutable. The type of the Google Cloud resource (e.g.,
`compute.googleapis.com/Instance`, `sqladmin.googleapis.com/Instance`).

=item * C<< $msg->restore_template() >> / C<< $msg->restore_template($value) >>

Type: C<String>

Required. Immutable. The canonical name of the RestoreTemplate to
trigger.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation::LabelsEntry>)

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

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::TriggerSummary

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

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::CreateRestoreVerificationPlanAssociationRequest

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

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation>)

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

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::GetRestoreVerificationPlanAssociationRequest

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

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsRequest

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

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsResponse

Response message for ListRestoreVerificationPlanAssociations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_verification_plan_associations() >> / C<< $msg->restore_verification_plan_associations($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation>)

The list of RestoreVerificationPlanAssociations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::DeleteRestoreVerificationPlanAssociationRequest

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

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::TriggerRestoreVerificationRequest

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

=head2 Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::TriggerRestoreVerificationResponse

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::RestoreVerificationPlanAssociation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
