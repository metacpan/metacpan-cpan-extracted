package Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2F1dG9wcm90ZWN0aW9ucG9saWN5LnBy
b3RvEhxnb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29n
bGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItoHChRBdXRvUHJvdGVjdGlvblBvbGljeRIa
CgRuYW1lGAEgASgJQgbgQQPgQQhSBG5hbWUSJQoLZGVzY3JpcHRpb24YAiABKAlCA+BBAVIL
ZGVzY3JpcHRpb24SYwoTYmFja3VwX3BsYW5fZGV0YWlscxgDIAMoCzIuLmdvb2dsZS5jbG91
ZC5iYWNrdXBkci52MWJldGEuQmFja3VwUGxhbkRldGFpbEID4EECUhFiYWNrdXBQbGFuRGV0
YWlscxJHCghjcml0ZXJpYRgEIAEoCzImLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEu
Q3JpdGVyaWFCA+BBAlIIY3JpdGVyaWESUwoFc3RhdGUYBSABKA4yOC5nb29nbGUuY2xvdWQu
YmFja3VwZHIudjFiZXRhLkF1dG9Qcm90ZWN0aW9uUG9saWN5LlN0YXRlQgPgQQNSBXN0YXRl
EhIKBGV0YWcYBiABKAlSBGV0YWcSWgoPYmluZGluZ19zdW1tYXJ5GAcgASgLMiwuZ29vZ2xl
LmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5CaW5kaW5nU3VtbWFyeUID4EEDUg5iaW5kaW5nU3Vt
bWFyeRJ2Chlwb2xpY3lfZXZhbHVhdGlvbl9zdW1tYXJ5GAggASgLMjUuZ29vZ2xlLmNsb3Vk
LmJhY2t1cGRyLnYxYmV0YS5Qb2xpY3lFdmFsdWF0aW9uU3VtbWFyeUID4EEDUhdwb2xpY3lF
dmFsdWF0aW9uU3VtbWFyeRJACgtjcmVhdGVfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgKIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZSJUCgVTdGF0ZRIVChFT
VEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCgoGQUNUSVZFEAISDAoIVVBEQVRJ
TkcQAxIMCghERUxFVElORxAEOrkB6kG1AQosYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vQXV0
b1Byb3RlY3Rpb25Qb2xpY3kSV3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9hdXRvUHJvdGVjdGlvblBvbGljaWVzL3thdXRvX3Byb3RlY3Rpb25fcG9saWN5fSoW
YXV0b1Byb3RlY3Rpb25Qb2xpY2llczIUYXV0b1Byb3RlY3Rpb25Qb2xpY3kiiQEKEEJhY2t1
cFBsYW5EZXRhaWwSKAoNcmVzb3VyY2VfdHlwZRgBIAEoCUID4EECUgxyZXNvdXJjZVR5cGUS
SwoLYmFja3VwX3BsYW4YAiABKAlCKuBBAvpBJAoiYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20v
QmFja3VwUGxhblIKYmFja3VwUGxhbiJxCghDcml0ZXJpYRJlChNtYXRjaGluZ19jb25kaXRp
b25zGAEgAygLMi8uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5NYXRjaGluZ0NvbmRp
dGlvbkID4EECUhJtYXRjaGluZ0NvbmRpdGlvbnMifAoRTWF0Y2hpbmdDb25kaXRpb24SWgoP
bGFiZWxfY29uZGl0aW9uGAEgASgLMiouZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5L
ZXlWYWx1ZVBhaXJCA+BBAUgAUg5sYWJlbENvbmRpdGlvbkILCgljb25kaXRpb24izgEKF1Bv
bGljeUV2YWx1YXRpb25TdW1tYXJ5EjsKF21hdGNoaW5nX3Jlc291cmNlX2NvdW50GAEgASgD
QgPgQQNSFW1hdGNoaW5nUmVzb3VyY2VDb3VudBI9Chhwcm90ZWN0ZWRfcmVzb3VyY2VfY291
bnQYAiABKANCA+BBA1IWcHJvdGVjdGVkUmVzb3VyY2VDb3VudBI3ChVmYWlsZWRfcmVzb3Vy
Y2VfY291bnQYAyABKANCA+BBA1ITZmFpbGVkUmVzb3VyY2VDb3VudCI6Cg5CaW5kaW5nU3Vt
bWFyeRIoCg1wcm9qZWN0X2NvdW50GAEgASgDQgPgQQNSDHByb2plY3RDb3VudCJCCgxLZXlW
YWx1ZVBhaXISFQoDa2V5GAEgASgJQgPgQQJSA2tleRIbCgZ2YWx1ZXMYAiADKAlCA+BBAlIG
dmFsdWVzIsECCiFDcmVhdGVBdXRvUHJvdGVjdGlvblBvbGljeVJlcXVlc3QSQQoGcGFyZW50
GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFy
ZW50Ej4KGWF1dG9fcHJvdGVjdGlvbl9wb2xpY3lfaWQYAiABKAlCA+BBAlIWYXV0b1Byb3Rl
Y3Rpb25Qb2xpY3lJZBJtChZhdXRvX3Byb3RlY3Rpb25fcG9saWN5GAMgASgLMjIuZ29vZ2xl
LmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5BdXRvUHJvdGVjdGlvblBvbGljeUID4EECUhRhdXRv
UHJvdGVjdGlvblBvbGljeRIqCgpyZXF1ZXN0X2lkGAQgASgJQgvijM/XCAIIAeBBAVIJcmVx
dWVzdElkImoKHkdldEF1dG9Qcm90ZWN0aW9uUG9saWN5UmVxdWVzdBJICgRuYW1lGAEgASgJ
QjTgQQL6QS4KLGJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL0F1dG9Qcm90ZWN0aW9uUG9saWN5
UgRuYW1lIoACCiFVcGRhdGVBdXRvUHJvdGVjdGlvblBvbGljeVJlcXVlc3QSbQoWYXV0b19w
cm90ZWN0aW9uX3BvbGljeRgBIAEoCzIyLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEu
QXV0b1Byb3RlY3Rpb25Qb2xpY3lCA+BBAlIUYXV0b1Byb3RlY3Rpb25Qb2xpY3kSQAoLdXBk
YXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0
ZU1hc2sSKgoKcmVxdWVzdF9pZBgDIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCKyAQoh
RGVsZXRlQXV0b1Byb3RlY3Rpb25Qb2xpY3lSZXF1ZXN0EkgKBG5hbWUYASABKAlCNOBBAvpB
LgosYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vQXV0b1Byb3RlY3Rpb25Qb2xpY3lSBG5hbWUS
FwoEZXRhZxgCIAEoCUID4EEBUgRldGFnEioKCnJlcXVlc3RfaWQYAyABKAlCC+KMz9cIAggB
4EEBUglyZXF1ZXN0SWQi6QEKIUxpc3RBdXRvUHJvdGVjdGlvblBvbGljaWVzUmVxdWVzdBJB
CgZwYXJlbnQYASABKAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0
aW9uUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2Vf
dG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0
ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSLhAQoiTGlzdEF1dG9Qcm90ZWN0
aW9uUG9saWNpZXNSZXNwb25zZRJsChhhdXRvX3Byb3RlY3Rpb25fcG9saWNpZXMYASADKAsy
Mi5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLkF1dG9Qcm90ZWN0aW9uUG9saWN5UhZh
dXRvUHJvdGVjdGlvblBvbGljaWVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBh
Z2VUb2tlbhIlCgt1bnJlYWNoYWJsZRgDIAMoCUID4EEGUgt1bnJlYWNoYWJsZULdAQogY29t
Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGFCGUF1dG9Qcm90ZWN0aW9uUG9saWN5UHJv
dG9QAVo8Y2xvdWQuZ29vZ2xlLmNvbS9nby9iYWNrdXBkci9hcGl2MWJldGEvYmFja3VwZHJw
YjtiYWNrdXBkcnBiqgIcR29vZ2xlLkNsb3VkLkJhY2t1cERSLlYxQmV0YcoCHEdvb2dsZVxD
bG91ZFxCYWNrdXBEUlxWMWJldGHqAh9Hb29nbGU6OkNsb3VkOjpCYWNrdXBEUjo6VjFiZXRh
SohgCgcSBQ4AzAIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAlCgkKAgMAEgMSACkKCQoCAwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVACoKCQoCAwQS
AxYAKQoICgEIEgMYADkKCQoCCCUSAxgAOQoICgEIEgMZAFMKCQoCCAsSAxkAUwoICgEIEgMa
ACIKCQoCCAoSAxoAIgoICgEIEgMbADoKCQoCCAgSAxsAOgoICgEIEgMcADkKCQoCCAESAxwA
OQoICgEIEgMdADkKCQoCCCkSAx0AOQoICgEIEgMeADgKCQoCCC0SAx4AOAqvAgoCBAASBCQA
agEaogIgQW4gQXV0b3Byb3RlY3Rpb25Qb2xpY3kgaXMgYSBwb2xpY3kgcmVzb3VyY2UgZGVz
aWduZWQgdG8gYXV0b21hdGUgYmFja3VwCiBtYW5hZ2VtZW50LCBtb3ZpbmcgZnJvbSBtYW51
YWwgcGVyLXJlc291cmNlIHByb3RlY3Rpb24gdG8gYSBidWxrIGFwcHJvYWNoLgogVGhlIHBv
bGljeSBkeW5hbWljYWxseSBkaXNjb3ZlcnMgYW5kIGFwcGxpZXMgYSBzcGVjaWZpZWQgYmFj
a3VwIHBsYW4gdG8gYWxsCiBlbGlnaWJsZSByZXNvdXJjZXMgdGhhdCBtYXRjaCBpdHMgZGVm
aW5lZCBzY29wZSBhbmQgY3JpdGVyaWEuCgoKCgMEAAESAyQIHAoLCgMEAAcSBCUCKgQKDQoF
BAAHnQgSBCUCKgQKNQoEBAAEABIELQI8AxonIFRoZSBzdGF0ZSBvZiBhbiBBdXRvcHJvdGVj
dGlvblBvbGljeS4KCgwKBQQABAABEgMtBwwKOAoGBAAEAAIAEgMvBBoaKSBUaGUgc3RhdGUg
b2YgdGhlIHBvbGljeSBpcyB1bnNwZWNpZmllZC4KCg4KBwQABAACAAESAy8EFQoOCgcEAAQA
AgACEgMvGBkKLQoGBAAEAAIBEgMyBBEaHiBUaGUgcG9saWN5IGlzIGJlaW5nIGNyZWF0ZWQu
CgoOCgcEAAQAAgEBEgMyBAwKDgoHBAAEAAIBAhIDMg8QCkgKBgQABAACAhIDNQQPGjkgVGhl
IHBvbGljeSBpcyBhY3RpdmUgYW5kIHByb3RlY3RpbmcgbWF0Y2hpbmcgcmVzb3VyY2VzLgoK
DgoHBAAEAAICARIDNQQKCg4KBwQABAACAgISAzUNDgotCgYEAAQAAgMSAzgEERoeIFRoZSBw
b2xpY3kgaXMgYmVpbmcgdXBkYXRlZC4KCg4KBwQABAACAwESAzgEDAoOCgcEAAQAAgMCEgM4
DxAKLQoGBAAEAAIEEgM7BBEaHiBUaGUgcG9saWN5IGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcE
AAQAAgQBEgM7BAwKDgoHBAAEAAIEAhIDOw8QCrwBCgQEAAIAEgRBAkQEGq0BIE91dHB1dCBv
bmx5LiBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQXV0b3Byb3RlY3Rp
b25Qb2xpY3kuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2F1dG9Qcm90ZWN0aW9uUG9saWNpZXMve2F1dG9fcHJvdGVjdGlvbl9wb2xpY3l9
YAoKDAoFBAACAAUSA0ECCAoMCgUEAAIAARIDQQkNCgwKBQQAAgADEgNBEBEKDQoFBAACAAgS
BEESRAMKDwoIBAACAAicCAASA0IELQoPCggEAAIACJwIARIDQwQsCmcKBAQAAgESA0gCQhpa
IE9wdGlvbmFsLiBBIGRlc2NyaXB0aW9uIG9mIHRoZSBwb2xpY3kuIFRoZSBkZXNjcmlwdGlv
biBtdXN0IGJlIGF0IG1vc3QgMjA0OAogY2hhcmFjdGVycy4KCgwKBQQAAgEFEgNIAggKDAoF
BAACAQESA0gJFAoMCgUEAAIBAxIDSBcYCgwKBQQAAgEIEgNIGUEKDwoIBAACAQicCAASA0ga
QApJCgQEAAICEgRLAkwvGjsgUmVxdWlyZWQuIFRoZSBiYWNrdXAgcGxhbiBkZXRhaWxzIGZv
ciBtYXRjaGluZyByZXNvdXJjZXMuCgoMCgUEAAICBBIDSwIKCgwKBQQAAgIGEgNLCxsKDAoF
BAACAgESA0scLwoMCgUEAAICAxIDSzIzCgwKBQQAAgIIEgNMBi4KDwoIBAACAgicCAASA0wH
LQo9CgQEAAIDEgNPAkEaMCBSZXF1aXJlZC4gVGhlIGNyaXRlcmlhIGZvciBtYXRjaGluZyBy
ZXNvdXJjZXMuCgoMCgUEAAIDBhIDTwIKCgwKBQQAAgMBEgNPCxMKDAoFBAACAwMSA08WFwoM
CgUEAAIDCBIDTxhACg8KCAQAAgMInAgAEgNPGT8KSgoEBAACBBIDUgI+Gj0gT3V0cHV0IG9u
bHkuIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBBdXRvcHJvdGVjdGlvblBvbGljeS4KCgwK
BQQAAgQGEgNSAgcKDAoFBAACBAESA1IIDQoMCgUEAAIEAxIDUhARCgwKBQQAAgQIEgNSEj0K
DwoIBAACBAicCAASA1ITPAq1AQoEBAACBRIDVwISGqcBIE91dHB1dCBvbmx5LiBUaGUgZXRh
ZyBmb3IgdGhlIHBvbGljeS4KIElmIHRoaXMgaXMgcHJvdmlkZWQgb24gdXBkYXRlLCBpdCBt
dXN0IG1hdGNoIHRoZSBzZXJ2ZXIncyBldGFnLCBvdGhlcndpc2UKIHRoZSByZXF1ZXN0IHdp
bGwgYmUgcmVqZWN0ZWQgd2l0aCBhbiBBQk9SVEVEIGVycm9yLgoKDAoFBAACBQUSA1cCCAoM
CgUEAAIFARIDVwkNCgwKBQQAAgUDEgNXEBEKaQoEBAACBhIEWwJcMhpbIE91dHB1dCBvbmx5
LiBTdW1tYXJ5IG9mIHRvdGFsIGNvdW50IG9mIGRpZmZlcmVudCBjb250YWluZXJzIGNvdmVy
ZWQgdGhyb3VnaAogdGhpcyBwb2xpY3kuCgoMCgUEAAIGBhIDWwIQCgwKBQQAAgYBEgNbESAK
DAoFBAACBgMSA1sjJAoMCgUEAAIGCBIDXAYxCg8KCAQAAgYInAgAEgNcBzAKZAoEBAACBxIE
YAJhMhpWIE91dHB1dCBvbmx5LiBTdW1tYXJ5IG9mIGxhc3QgcG9saWN5IGFwcGxpY2F0aW9u
IHdoZW4gam9iIHdhcyBydW4gcGVyCiB3b3JrbG9hZCB0eXBlLgoKDAoFBAACBwYSA2ACGQoM
CgUEAAIHARIDYBozCgwKBQQAAgcDEgNgNjcKDAoFBAACBwgSA2EGMQoPCggEAAIHCJwIABID
YQcwCkcKBAQAAggSBGQCZTIaOSBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRo
ZSBwb2xpY3kgd2FzIGNyZWF0ZWQuCgoMCgUEAAIIBhIDZAIbCgwKBQQAAggBEgNkHCcKDAoF
BAACCAMSA2QqKwoMCgUEAAIICBIDZQYxCg8KCAQAAggInAgAEgNlBzAKTAoEBAACCRIEaAJp
Mho+IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHBvbGljeSB3YXMgbGFz
dCB1cGRhdGVkLgoKDAoFBAACCQYSA2gCGwoMCgUEAAIJARIDaBwnCgwKBQQAAgkDEgNoKiwK
DAoFBAACCQgSA2kGMQoPCggEAAIJCJwIABIDaQcwCkMKAgQBEgRtAH0BGjcgQmFja3VwUGxh
bkRldGFpbCBkZWZpbmVzIGNvbmZpZ3VyYXRpb24gb2YgcHJvdGVjdGlvbi4KCgoKAwQBARID
bQgYCrkBCgQEAQIAEgNxAkQaqwEgUmVxdWlyZWQuIFRoZSB0eXBlIG9mIHJlc291cmNlIHRo
YXQgdGhpcyBwb2xpY3kgd2lsbCBhdXRvbWF0aWNhbGx5IHByb3RlY3QuCiBGb3IgTVZQLCBg
Y29tcHV0ZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZWAgYW5kCiBgY29tcHV0ZS5nb29nbGVh
cGlzLmNvbS9EaXNrYCBhcmUgc3VwcG9ydGVkLgoKDAoFBAECAAUSA3ECCAoMCgUEAQIAARID
cQkWCgwKBQQBAgADEgNxGRoKDAoFBAECAAgSA3EbQwoPCggEAQIACJwIABIDcRxCCosCCgQE
AQIBEgR3AnwEGvwBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQmFja3Vw
UGxhbiB0byBhcHBseSB0byByZXNvdXJjZXMgdGhhdAogbWF0Y2ggdGhlIHBvbGljeSdzIGNy
aXRlcmlhLiBUaGlzIGJhY2t1cCBwbGFuIG11c3QgYmUgaW4gdGhlIHNhbWUgbG9jYXRpb24K
IGFzIEF1dG9Qcm90ZWN0aW9uUG9saWN5LiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vYmFja3VwUGxhbnMve2JhY2t1cFBsYW5JZH0KCgwKBQQB
AgEFEgN3AggKDAoFBAECAQESA3cJFAoMCgUEAQIBAxIDdxcYCg0KBQQBAgEIEgR3GXwDCg8K
CAQBAgEInAgAEgN4BCoKDwoHBAECAQifCBIEeQR7BQpMCgIEAhIGgAEAhQEBGj4gQ3JpdGVy
aWEgc3BlY2lmaWVzIGEgc2V0IG9mIGNyaXRlcmlhIGZvciBtYXRjaGluZyByZXNvdXJjZXMu
CgoLCgMEAgESBIABCBAKcwoEBAICABIGgwEChAEvGmMgUmVxdWlyZWQuIEEgbGlzdCBvZiBt
YXRjaGluZyBjb25kaXRpb25zIHRoYXQgYSByZXNvdXJjZSBtdXN0IG1lZXQgdG8gYmUKIHBy
b3RlY3RlZCBieSB0aGUgcG9saWN5LgoKDQoFBAICAAQSBIMBAgoKDQoFBAICAAYSBIMBCxwK
DQoFBAICAAESBIMBHTAKDQoFBAICAAMSBIMBMzQKDQoFBAICAAgSBIQBBi4KEAoIBAICAAic
CAASBIQBBy0KVwoCBAMSBogBAJABARpJIE1hdGNoaW5nQ29uZGl0aW9uIHNwZWNpZmllcyBh
IHNldCBvZiBjb25kaXRpb25zIGZvciBtYXRjaGluZyByZXNvdXJjZXMuCgoLCgMEAwESBIgB
CBkKVwoEBAMIABIGiwECjwEDGkcgQSBjb25kaXRpb24gdGhhdCBhIHJlc291cmNlIG11c3Qg
bWVldCB0byBiZSBwcm90ZWN0ZWQgYnkgdGhlCiBwb2xpY3kuCgoNCgUEAwgAARIEiwEIEQqG
AQoEBAMCABIEjgEEThp4IE9wdGlvbmFsLiBBIGNvbmRpdGlvbiB0aGF0IG1hdGNoZXMgcmVz
b3VyY2VzIGJhc2VkIG9uIHRoZWlyIGxhYmVscy4KIEZvciBNVlAsIHRoaXMgaXMgbGltaXRl
ZCB0byBhIHNpbmdsZSBsYWJlbCBtYXRjaC4KCg0KBQQDAgAGEgSOAQQQCg0KBQQDAgABEgSO
AREgCg0KBQQDAgADEgSOASMkCg0KBQQDAgAIEgSOASVNChAKCAQDAgAInAgAEgSOASZMCn8K
AgQEEgaUAQChAQEacSBQb2xpY3lFdmFsdWF0aW9uU3VtbWFyeSBjb250YWlucyB0aGUgc3Vt
bWFyeSBvZiB0aGUgbGFzdCBydW4gb2Ygam9iIHRoYXQKIGFwcGxpZXMgcG9saWN5IHRvIG1h
dGNoaW5nIHJlc291cmNlcy4KCgsKAwQEARIElAEIHwphCgQEBAIAEgSXAQJQGlMgT3V0cHV0
IG9ubHkuIFRoZSBudW1iZXIgb2YgcmVzb3VyY2VzIHRoYXQgY3VycmVudGx5IG1hdGNoIHRo
ZSBwb2xpY3kncwogY3JpdGVyaWEuCgoNCgUEBAIABRIElwECBwoNCgUEBAIAARIElwEIHwoN
CgUEBAIAAxIElwEiIwoNCgUEBAIACBIElwEkTwoQCggEBAIACJwIABIElwElTgphCgQEBAIB
EgabAQKcATIaUSBPdXRwdXQgb25seS4gVGhlIG51bWJlciBvZiBtYXRjaGluZyByZXNvdXJj
ZXMgdGhhdCBhcmUgc3VjY2Vzc2Z1bGx5CiBwcm90ZWN0ZWQuCgoNCgUEBAIBBRIEmwECBwoN
CgUEBAIBARIEmwEIIAoNCgUEBAIBAxIEmwEjJAoNCgUEBAIBCBIEnAEGMQoQCggEBAIBCJwI
ABIEnAEHMApmCgQEBAICEgSgAQJOGlggT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgbWF0
Y2hpbmcgcmVzb3VyY2VzIHdob3NlIHByb3RlY3Rpb24gZmFpbGVkCiBkdXJpbmcgam9iIHJ1
bi4KCg0KBQQEAgIFEgSgAQIHCg0KBQQEAgIBEgSgAQgdCg0KBQQEAgIDEgSgASAhCg0KBQQE
AgIIEgSgASJNChAKCAQEAgIInAgAEgSgASNMCmMKAgQFEgalAQCoAQEaVSBCaW5kaW5nU3Vt
bWFyeSBjb250YWlucyBjb3VudCBvZiBkaWZmZXJlbnQgY29udGFpbmVycyBjb3ZlcmVkIHRo
cm91Z2ggdGhpcwogcG9saWN5LgoKCwoDBAUBEgSlAQgWClAKBAQFAgASBKcBAkYaQiBPdXRw
dXQgb25seS4gVG90YWwgY291bnQgb2YgUHJvamVjdHMgcHJvdGVjdGVkIHdpdGggdGhpcyBw
b2xpY3kuCgoNCgUEBQIABRIEpwECBwoNCgUEBQIAARIEpwEIFQoNCgUEBQIAAxIEpwEYGQoN
CgUEBQIACBIEpwEaRQoQCggEBQIACJwIABIEpwEbRApTCgIEBhIGqwEAuAEBGkUgS2V5VmFs
dWVQYWlyIGRlZmluZXMgYSBrZXktdmFsdWUgcGFpciBmb3IgbWF0Y2hpbmcgcmVzb3VyY2Ug
bGFiZWxzLgoKCwoDBAYBEgSrAQgUCrcBCgQEBgIAEgSwAQI6GqgBIFJlcXVpcmVkLiBUaGUg
a2V5IG9mIHRoZSBsYWJlbCB0byBtYXRjaC4KIFRoaXMgbXVzdCBiZSBpbiB0aGUgZm9ybWF0
IGB7bGFiZWxfa2V5fWAuCiBUaGUga2V5IG11c3QgbWF0Y2ggdGhlIHJlZ2V4CiBGb3JtYXQ6
YFtccHtMbH1ccHtMb31dW1xwe0xsfVxwe0xvfVxwe059Xy1dezAsNjJ9YC4KCg0KBQQGAgAF
EgSwAQIICg0KBQQGAgABEgSwAQkMCg0KBQQGAgADEgSwAQ8QCg0KBQQGAgAIEgSwARE5ChAK
CAQGAgAInAgAEgSwARI4CvABCgQEBgIBEgS3AQJGGuEBIFJlcXVpcmVkLiBUaGUgdmFsdWVz
IG9mIHRoZSBsYWJlbCB0byBtYXRjaC4KIFRoZXJlIHdpbGwgYmUgZXhwbGljaXQgIk9SIiBi
ZXR3ZWVuIHZhbHVlcyBvZiBhcnJheS4KIEVhY2ggdmFsdWUgbXVzdCBiZSBpbiB0aGUgZm9y
bWF0IGB7bGFiZWxfdmFsdWV9YC4KIFRoZSB2YWx1ZSBtdXN0IG1hdGNoIHRoZSByZWdleAog
Rm9ybWF0OiBgW1xccHtMbH1cXHB7TG99XFxwe059Xy1dezEsNjN9YC4KCg0KBQQGAgEEEgS3
AQIKCg0KBQQGAgEFEgS3AQsRCg0KBQQGAgEBEgS3ARIYCg0KBQQGAgEDEgS3ARscCg0KBQQG
AgEIEgS3AR1FChAKCAQGAgEInAgAEgS3AR5ECkUKAgQHEga7AQDbAQEaNyBSZXF1ZXN0IG1l
c3NhZ2UgZm9yIGNyZWF0aW5nIGFuIEF1dG9Qcm90ZWN0aW9uUG9saWN5LgoKCwoDBAcBEgS7
AQgpCoMBCgQEBwIAEga+AQLDAQQacyBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSB3
aGVyZSB0aGlzIHBvbGljeSB3aWxsIGJlIGNyZWF0ZWQuCiBGb3JtYXQ6IHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufQoKDQoFBAcCAAUSBL4BAggKDQoFBAcCAAES
BL4BCQ8KDQoFBAcCAAMSBL4BEhMKDwoFBAcCAAgSBr4BFMMBAwoQCggEBwIACJwIABIEvwEE
KgoRCgcEBwIACJ8IEgbAAQTCAQUKiQIKBAQHAgESBMoBAlAa+gEgUmVxdWlyZWQuIFRoZSBJ
RCB0byB1c2UgZm9yIHRoZSBwb2xpY3kuCiBUaGlzIHdpbGwgYmVjb21lIHRoZSBmaW5hbCBj
b21wb25lbnQgb2YgdGhlIHBvbGljeSdzIHJlc291cmNlIG5hbWUuCgogVGhpcyB2YWx1ZSBt
dXN0IHN0YXJ0IHdpdGggYSBsb3dlcmNhc2UgbGV0dGVyIGZvbGxvd2VkIGJ5IHVwIHRvIDYy
CiBsb3dlcmNhc2UgbGV0dGVycywgbnVtYmVycywgb3IgaHlwaGVucywgYW5kIGNhbm5vdCBl
bmQgd2l0aCBhIGh5cGhlbi4KCg0KBQQHAgEFEgTKAQIICg0KBQQHAgEBEgTKAQkiCg0KBQQH
AgEDEgTKASUmCg0KBQQHAgEIEgTKASdPChAKCAQHAgEInAgAEgTKAShOCkgKBAQHAgISBs0B
As4BLxo4IFJlcXVpcmVkLiBUaGUgQXV0b1Byb3RlY3Rpb25Qb2xpY3kgcmVzb3VyY2UgdG8g
Y3JlYXRlLgoKDQoFBAcCAgYSBM0BAhYKDQoFBAcCAgESBM0BFy0KDQoFBAcCAgMSBM0BMDEK
DQoFBAcCAggSBM4BBi4KEAoIBAcCAgicCAASBM4BBy0KrwMKBAQHAgMSBtcBAtoBBBqeAyBP
cHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4g
U3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5
IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVx
dWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxs
CiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBzaW5jZSB0aGUgZmly
c3QgcmVxdWVzdC4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRo
IHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAw
MDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBwIDBRIE1wECCAoNCgUE
BwIDARIE1wEJEwoNCgUEBwIDAxIE1wEWFwoPCgUEBwIDCBIG1wEY2gEDChMKCwQHAgMIzPH5
igEBEgTYAQQqChAKCAQHAgMInAgAEgTZAQQqCkQKAgQIEgbeAQDoAQEaNiBSZXF1ZXN0IG1l
c3NhZ2UgZm9yIGdldHRpbmcgYW4gQXV0b1Byb3RlY3Rpb25Qb2xpY3kuCgoLCgMECAESBN4B
CCYKogEKBAQIAgASBuIBAucBBBqRASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHBvbGlj
eSB0byByZXRyaWV2ZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9hdXRvUHJvdGVjdGlvblBvbGljaWVzL3thdXRvX3Byb3RlY3Rpb25fcG9s
aWN5fQoKDQoFBAgCAAUSBOIBAggKDQoFBAgCAAESBOIBCQ0KDQoFBAgCAAMSBOIBEBEKDwoF
BAgCAAgSBuIBEucBAwoQCggECAIACJwIABIE4wEEKgoRCgcECAIACJ8IEgbkAQTmAQUKRQoC
BAkSBusBAIMCARo3IFJlcXVlc3QgbWVzc2FnZSBmb3IgdXBkYXRpbmcgYW4gQXV0b1Byb3Rl
Y3Rpb25Qb2xpY3kuCgoLCgMECQESBOsBCCkKMQoEBAkCABIG7QEC7gEvGiEgUmVxdWlyZWQu
IFRoZSBwb2xpY3kgdG8gdXBkYXRlLgoKDQoFBAkCAAYSBO0BAhYKDQoFBAkCAAESBO0BFy0K
DQoFBAkCAAMSBO0BMDEKDQoFBAkCAAgSBO4BBi4KEAoIBAkCAAicCAASBO4BBy0K5gIKBAQJ
AgESBvUBAvYBLxrVAiBPcHRpb25hbC4gRmllbGQgbWFzayBpcyB1c2VkIHRvIHNwZWNpZnkg
dGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIEF1dG9Qcm90ZWN0aW9uUG9s
aWN5IHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuCiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0
aGUgdXBkYXRlX21hc2sgYXJlIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0aGUg
ZnVsbCByZXF1ZXN0LiBBIGZpZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4g
dGhlIG1hc2suIElmIHRoZQogdXNlciBkb2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVuIGFs
bCBmaWVsZHMgd2lsbCBiZSBvdmVyd3JpdHRlbi4KCg0KBQQJAgEGEgT1AQIbCg0KBQQJAgEB
EgT1ARwnCg0KBQQJAgEDEgT1ASorCg0KBQQJAgEIEgT2AQYuChAKCAQJAgEInAgAEgT2AQct
Cq8DCgQECQICEgb/AQKCAgQangMgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQg
dG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28g
dGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBr
bm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21w
bGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYw
IG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgogVGhlIHJlcXVlc3QgSUQgbXVz
dCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlz
CiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAp
LgoKDQoFBAkCAgUSBP8BAggKDQoFBAkCAgESBP8BCRMKDQoFBAkCAgMSBP8BFhcKDwoFBAkC
AggSBv8BGIICAwoTCgsECQICCMzx+YoBARIEgAIEKgoQCggECQICCJwIABIEgQIEKgpFCgIE
ChIGhgIAoQIBGjcgUmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhbiBBdXRvUHJvdGVj
dGlvblBvbGljeS4KCgsKAwQKARIEhgIIKQqgAQoEBAoCABIGigICjwIEGo8BIFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgcG9saWN5IHRvIGRlbGV0ZS4KIEZvcm1hdDoKIHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRvUHJvdGVjdGlvblBvbGljaWVz
L3thdXRvX3Byb3RlY3Rpb25fcG9saWN5fQoKDQoFBAoCAAUSBIoCAggKDQoFBAoCAAESBIoC
CQ0KDQoFBAoCAAMSBIoCEBEKDwoFBAoCAAgSBooCEo8CAwoQCggECgIACJwIABIEiwIEKgoR
CgcECgIACJ8IEgaMAgSOAgUKzAEKBAQKAgESBJQCAjsavQEgT3B0aW9uYWwuIFRoZSBjdXJy
ZW50IGV0YWcgb2YgdGhlIEF1dG9Qcm90ZWN0aW9uUG9saWN5LgogSWYgYW4gZXRhZyBpcyBw
cm92aWRlZCBhbmQgZG9lcyBub3QgbWF0Y2ggdGhlIGN1cnJlbnQgZXRhZyBvZiB0aGUKIGNv
bm5lY3Rpb24sIHRoZSByZXF1ZXN0IHdpbGwgYmUgcmVqZWN0ZWQgd2l0aCBhbiBBQk9SVEVE
IGVycm9yLgoKDQoFBAoCAQUSBJQCAggKDQoFBAoCAQESBJQCCQ0KDQoFBAoCAQMSBJQCEBEK
DQoFBAoCAQgSBJQCEjoKEAoIBAoCAQicCAASBJQCEzkKrwMKBAQKAgISBp0CAqACBBqeAyBP
cHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4g
U3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5
IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVx
dWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxs
CiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBzaW5jZSB0aGUgZmly
c3QgcmVxdWVzdC4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRo
IHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAw
MDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUECgICBRIEnQICCAoNCgUE
CgICARIEnQIJEwoNCgUECgICAxIEnQIWFwoPCgUECgICCBIGnQIYoAIDChMKCwQKAgIIzPH5
igEBEgSeAgQqChAKCAQKAgIInAgAEgSfAgQqCj8KAgQLEgakAgC+AgEaMSBSZXF1ZXN0IG1l
c3NhZ2UgZm9yIExpc3RBdXRvUHJvdGVjdGlvblBvbGljaWVzLgoKCwoDBAsBEgSkAggpCpIB
CgQECwIAEganAgKsAgQagQEgUmVxdWlyZWQuIFRoZSBwcm9qZWN0IGFuZCBsb2NhdGlvbiBm
b3Igd2hpY2ggdG8gcmV0cmlldmUgdGhlIGxpc3Qgb2YKIHBvbGljaWVzLiBGb3JtYXQ6IHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufQoKDQoFBAsCAAUSBKcCAggK
DQoFBAsCAAESBKcCCQ8KDQoFBAsCAAMSBKcCEhMKDwoFBAsCAAgSBqcCFKwCAwoQCggECwIA
CJwIABIEqAIEKgoRCgcECwIACJ8IEgapAgSrAgUKigEKBAQLAgESBLACAj8afCBPcHRpb25h
bC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHBvbGljaWVzIHRvIHJldHVybiBpbiBhIHNpbmds
ZSBwYWdlLgogSWYgdW5zcGVjaWZpZWQsIGEgc2VydmVyLWRlZmF1bHQgdmFsdWUgd2lsbCBi
ZSB1c2VkLgoKDQoFBAsCAQUSBLACAgcKDQoFBAsCAQESBLACCBEKDQoFBAsCAQMSBLACFBUK
DQoFBAsCAQgSBLACFj4KEAoIBAsCAQicCAASBLACFz0KlAEKBAQLAgISBLUCAkEahQEgT3B0
aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBgTGlzdEF1
dG9Qcm90ZWN0aW9uUG9saWNpZXNgIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0
aGUgc3Vic2VxdWVudAogcGFnZS4KCg0KBQQLAgIFEgS1AgIICg0KBQQLAgIBEgS1AgkTCg0K
BQQLAgIDEgS1AhYXCg0KBQQLAgIIEgS1AhhAChAKCAQLAgIInAgAEgS1Ahk/CoIBCgQECwID
EgS5AgI9GnQgT3B0aW9uYWwuIEEgZmlsdGVyIGV4cHJlc3Npb24gdGhhdCBmaWx0ZXJzIHJl
c291cmNlcyBsaXN0ZWQgaW4gdGhlCiByZXNwb25zZS4gVGhlIGZvbGxvd2luZyBmaWVsZHMg
YXJlIGZpbHRlcmFibGU6CgoNCgUECwIDBRIEuQICCAoNCgUECwIDARIEuQIJDwoNCgUECwID
AxIEuQISEwoNCgUECwIDCBIEuQIUPAoQCggECwIDCJwIABIEuQIVOwpzCgQECwIEEgS9AgI/
GmUgT3B0aW9uYWwuIEFuIGV4cHJlc3Npb24gdGhhdCBzb3J0cyB0aGUgcmVzdWx0cyBpbiB0
aGUgcmVzcG9uc2UuIFRoZQogZm9sbG93aW5nIGZpZWxkcyBhcmUgc29ydGFibGU6CgoNCgUE
CwIEBRIEvQICCAoNCgUECwIEARIEvQIJEQoNCgUECwIEAxIEvQIUFQoNCgUECwIECBIEvQIW
PgoQCggECwIECJwIABIEvQIXPQpACgIEDBIGwQIAzAIBGjIgUmVzcG9uc2UgbWVzc2FnZSBm
b3IgTGlzdEF1dG9Qcm90ZWN0aW9uUG9saWNpZXMuCgoLCgMEDAESBMECCCoKQwoEBAwCABIE
wwICPRo1IEEgbGlzdCBvZiB0aGUgQXV0b1Byb3RlY3Rpb25Qb2xpY3kgcmVzb3VyY2VzIGZv
dW5kLgoKDQoFBAwCAAQSBMMCAgoKDQoFBAwCAAYSBMMCCx8KDQoFBAwCAAESBMMCIDgKDQoF
BAwCAAMSBMMCOzwKjQEKBAQMAgESBMcCAh0afyBBIHRva2VuIHRoYXQgY2FuIGJlIHNlbnQg
YXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZp
ZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAwC
AQUSBMcCAggKDQoFBAwCAQESBMcCCRgKDQoFBAwCAQMSBMcCGxwKRgoEBAwCAhIGygICywI1
GjYgVW5vcmRlcmVkIGxpc3QuIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVk
LgoKDQoFBAwCAgQSBMoCAgoKDQoFBAwCAgUSBMoCCxEKDQoFBAwCAgESBMoCEh0KDQoFBAwC
AgMSBMoCICEKDQoFBAwCAggSBMsCBjQKEAoIBAwCAgicCAASBMsCBzNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::AutoProtectionPolicy ===
    # Fields for AutoProtectionPolicy
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: backup_plan_details Type: 11 (.google.cloud.backupdr.v1beta.BackupPlanDetail)
    # Field: criteria Type: 11 (.google.cloud.backupdr.v1beta.Criteria)
    # Field: state Type: 14 (.google.cloud.backupdr.v1beta.AutoProtectionPolicy.State)
    # Field: etag Type: 9 ()
    # Field: binding_summary Type: 11 (.google.cloud.backupdr.v1beta.BindingSummary)
    # Field: policy_evaluation_summary Type: 11 (.google.cloud.backupdr.v1beta.PolicyEvaluationSummary)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: AutoProtectionPolicy::State
our $AutoProtectionPolicy_STATE_UNSPECIFIED = 0;
our $AutoProtectionPolicy_CREATING = 1;
our $AutoProtectionPolicy_ACTIVE = 2;
our $AutoProtectionPolicy_UPDATING = 3;
our $AutoProtectionPolicy_DELETING = 4;

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::BackupPlanDetail ===
    # Fields for BackupPlanDetail
    # Field: resource_type Type: 9 ()
    # Field: backup_plan Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::Criteria ===
    # Fields for Criteria
    # Field: matching_conditions Type: 11 (.google.cloud.backupdr.v1beta.MatchingCondition)

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::MatchingCondition ===
    # Fields for MatchingCondition
    # Field: label_condition Type: 11 (.google.cloud.backupdr.v1beta.KeyValuePair)

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::PolicyEvaluationSummary ===
    # Fields for PolicyEvaluationSummary
    # Field: matching_resource_count Type: 3 ()
    # Field: protected_resource_count Type: 3 ()
    # Field: failed_resource_count Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::BindingSummary ===
    # Fields for BindingSummary
    # Field: project_count Type: 3 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::KeyValuePair ===
    # Fields for KeyValuePair
    # Field: key Type: 9 ()
    # Field: values Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::CreateAutoProtectionPolicyRequest ===
    # Fields for CreateAutoProtectionPolicyRequest
    # Field: parent Type: 9 ()
    # Field: auto_protection_policy_id Type: 9 ()
    # Field: auto_protection_policy Type: 11 (.google.cloud.backupdr.v1beta.AutoProtectionPolicy)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::GetAutoProtectionPolicyRequest ===
    # Fields for GetAutoProtectionPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::UpdateAutoProtectionPolicyRequest ===
    # Fields for UpdateAutoProtectionPolicyRequest
    # Field: auto_protection_policy Type: 11 (.google.cloud.backupdr.v1beta.AutoProtectionPolicy)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::DeleteAutoProtectionPolicyRequest ===
    # Fields for DeleteAutoProtectionPolicyRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::ListAutoProtectionPoliciesRequest ===
    # Fields for ListAutoProtectionPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::ListAutoProtectionPoliciesResponse ===
    # Fields for ListAutoProtectionPoliciesResponse
    # Field: auto_protection_policies Type: 11 (.google.cloud.backupdr.v1beta.AutoProtectionPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/autoprotectionpolicy.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy;

    my $msg = Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::AutoProtectionPolicy->new({
        name => $name,
        description => $description,
        backup_plan_details => $backup_plan_details,
        criteria => $criteria,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::AutoProtectionPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/autoprotectionpolicy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::AutoProtectionPolicy

An AutoprotectionPolicy is a policy resource designed to automate backup
management, moving from manual per-resource protection to a bulk approach.
The policy dynamically discovers and applies a specified backup plan to all
eligible resources that match its defined scope and criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the AutoprotectionPolicy.
Format:
`projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A description of the policy. The description must be at most 2048
characters.

=item * C<< $msg->backup_plan_details() >> / C<< $msg->backup_plan_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::BackupPlanDetail>)

Required. The backup plan details for matching resources.

=item * C<< $msg->criteria() >> / C<< $msg->criteria($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::Criteria>)

Required. The criteria for matching resources.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::AutoProtectionPolicy::State>)

Output only. The current state of the AutoprotectionPolicy.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. The etag for the policy.
If this is provided on update, it must match the server's etag, otherwise
the request will be rejected with an ABORTED error.

=item * C<< $msg->binding_summary() >> / C<< $msg->binding_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::BindingSummary>)

Output only. Summary of total count of different containers covered through
this policy.

=item * C<< $msg->policy_evaluation_summary() >> / C<< $msg->policy_evaluation_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::PolicyEvaluationSummary>)

Output only. Summary of last policy application when job was run per
workload type.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the policy was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the policy was last updated.

=back

=head3 Enum: AutoProtectionPolicy::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::BackupPlanDetail

BackupPlanDetail defines configuration of protection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. The type of resource that this policy will automatically protect.
For MVP, `compute.googleapis.com/Instance` and
`compute.googleapis.com/Disk` are supported.

=item * C<< $msg->backup_plan() >> / C<< $msg->backup_plan($value) >>

Type: C<String>

Required. The resource name of the BackupPlan to apply to resources that
match the policy's criteria. This backup plan must be in the same location
as AutoProtectionPolicy. Format:
projects/{project}/locations/{location}/backupPlans/{backupPlanId}

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::Criteria

Criteria specifies a set of criteria for matching resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_conditions() >> / C<< $msg->matching_conditions($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::MatchingCondition>)

Required. A list of matching conditions that a resource must meet to be
protected by the policy.

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::MatchingCondition

MatchingCondition specifies a set of conditions for matching resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label_condition() >> / C<< $msg->label_condition($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::KeyValuePair>)

Optional. A condition that matches resources based on their labels.
For MVP, this is limited to a single label match.

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::PolicyEvaluationSummary

PolicyEvaluationSummary contains the summary of the last run of job that
applies policy to matching resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_resource_count() >> / C<< $msg->matching_resource_count($value) >>

Type: C<Int64>

Output only. The number of resources that currently match the policy's
criteria.

=item * C<< $msg->protected_resource_count() >> / C<< $msg->protected_resource_count($value) >>

Type: C<Int64>

Output only. The number of matching resources that are successfully
protected.

=item * C<< $msg->failed_resource_count() >> / C<< $msg->failed_resource_count($value) >>

Type: C<Int64>

Output only. The number of matching resources whose protection failed
during job run.

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::BindingSummary

BindingSummary contains count of different containers covered through this
policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_count() >> / C<< $msg->project_count($value) >>

Type: C<Int64>

Output only. Total count of Projects protected with this policy.

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::KeyValuePair

KeyValuePair defines a key-value pair for matching resource labels.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Required. The key of the label to match.
This must be in the format `{label_key}`.
The key must match the regex
Format:`[\p{Ll}\p{Lo}][\p{Ll}\p{Lo}\p{N}_-]{0,62}`.

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Required. The values of the label to match.
There will be explicit "OR" between values of array.
Each value must be in the format `{label_value}`.
The value must match the regex
Format: `[\\p{Ll}\\p{Lo}\\p{N}_-]{1,63}`.

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::CreateAutoProtectionPolicyRequest

Request message for creating an AutoProtectionPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this policy will be created.
Format: projects/{project}/locations/{location}

=item * C<< $msg->auto_protection_policy_id() >> / C<< $msg->auto_protection_policy_id($value) >>

Type: C<String>

Required. The ID to use for the policy.
This will become the final component of the policy's resource name.

This value must start with a lowercase letter followed by up to 62
lowercase letters, numbers, or hyphens, and cannot end with a hyphen.

=item * C<< $msg->auto_protection_policy() >> / C<< $msg->auto_protection_policy($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::AutoProtectionPolicy>)

Required. The AutoProtectionPolicy resource to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::GetAutoProtectionPolicyRequest

Request message for getting an AutoProtectionPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the policy to retrieve.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::UpdateAutoProtectionPolicyRequest

Request message for updating an AutoProtectionPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auto_protection_policy() >> / C<< $msg->auto_protection_policy($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::AutoProtectionPolicy>)

Required. The policy to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
AutoProtectionPolicy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::DeleteAutoProtectionPolicyRequest

Request message for deleting an AutoProtectionPolicy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the policy to delete.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The current etag of the AutoProtectionPolicy.
If an etag is provided and does not match the current etag of the
connection, the request will be rejected with an ABORTED error.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::ListAutoProtectionPoliciesRequest

Request message for ListAutoProtectionPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve the list of
policies. Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of policies to return in a single page.
If unspecified, a server-default value will be used.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAutoProtectionPolicies` call. Provide this to retrieve the subsequent
page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters resources listed in the
response. The following fields are filterable:

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression that sorts the results in the response. The
following fields are sortable:

=back

=head2 Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::ListAutoProtectionPoliciesResponse

Response message for ListAutoProtectionPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auto_protection_policies() >> / C<< $msg->auto_protection_policies($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::AutoProtectionPolicy>)

A list of the AutoProtectionPolicy resources found.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
