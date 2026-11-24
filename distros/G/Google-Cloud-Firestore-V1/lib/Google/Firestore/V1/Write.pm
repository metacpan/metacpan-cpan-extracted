package Google::Firestore::V1::Write;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Firestore::V1::BloomFilter };
    eval { require Google::Firestore::V1::Common };
    eval { require Google::Firestore::V1::Document };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ch9nb29nbGUvZmlyZXN0b3JlL3YxL3dyaXRlLnByb3RvEhNnb29nbGUuZmlyZXN0b3JlLnYx
GiZnb29nbGUvZmlyZXN0b3JlL3YxL2Jsb29tX2ZpbHRlci5wcm90bxogZ29vZ2xlL2ZpcmVz
dG9yZS92MS9jb21tb24ucHJvdG8aImdvb2dsZS9maXJlc3RvcmUvdjEvZG9jdW1lbnQucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ipQMKBVdyaXRlEjcKBnVwZGF0
ZRgBIAEoCzIdLmdvb2dsZS5maXJlc3RvcmUudjEuRG9jdW1lbnRIAFIGdXBkYXRlEhgKBmRl
bGV0ZRgCIAEoCUgAUgZkZWxldGUSRgoJdHJhbnNmb3JtGAYgASgLMiYuZ29vZ2xlLmZpcmVz
dG9yZS52MS5Eb2N1bWVudFRyYW5zZm9ybUgAUgl0cmFuc2Zvcm0SQgoLdXBkYXRlX21hc2sY
AyABKAsyIS5nb29nbGUuZmlyZXN0b3JlLnYxLkRvY3VtZW50TWFza1IKdXBkYXRlTWFzaxJi
ChF1cGRhdGVfdHJhbnNmb3JtcxgHIAMoCzI1Lmdvb2dsZS5maXJlc3RvcmUudjEuRG9jdW1l
bnRUcmFuc2Zvcm0uRmllbGRUcmFuc2Zvcm1SEHVwZGF0ZVRyYW5zZm9ybXMSTAoQY3VycmVu
dF9kb2N1bWVudBgEIAEoCzIhLmdvb2dsZS5maXJlc3RvcmUudjEuUHJlY29uZGl0aW9uUg9j
dXJyZW50RG9jdW1lbnRCCwoJb3BlcmF0aW9uIuUFChFEb2N1bWVudFRyYW5zZm9ybRIaCghk
b2N1bWVudBgBIAEoCVIIZG9jdW1lbnQSYAoQZmllbGRfdHJhbnNmb3JtcxgCIAMoCzI1Lmdv
b2dsZS5maXJlc3RvcmUudjEuRG9jdW1lbnRUcmFuc2Zvcm0uRmllbGRUcmFuc2Zvcm1SD2Zp
ZWxkVHJhbnNmb3JtcxrRBAoORmllbGRUcmFuc2Zvcm0SHQoKZmllbGRfcGF0aBgBIAEoCVIJ
ZmllbGRQYXRoEnIKE3NldF90b19zZXJ2ZXJfdmFsdWUYAiABKA4yQS5nb29nbGUuZmlyZXN0
b3JlLnYxLkRvY3VtZW50VHJhbnNmb3JtLkZpZWxkVHJhbnNmb3JtLlNlcnZlclZhbHVlSABS
EHNldFRvU2VydmVyVmFsdWUSOgoJaW5jcmVtZW50GAMgASgLMhouZ29vZ2xlLmZpcmVzdG9y
ZS52MS5WYWx1ZUgAUglpbmNyZW1lbnQSNgoHbWF4aW11bRgEIAEoCzIaLmdvb2dsZS5maXJl
c3RvcmUudjEuVmFsdWVIAFIHbWF4aW11bRI2CgdtaW5pbXVtGAUgASgLMhouZ29vZ2xlLmZp
cmVzdG9yZS52MS5WYWx1ZUgAUgdtaW5pbXVtElkKF2FwcGVuZF9taXNzaW5nX2VsZW1lbnRz
GAYgASgLMh8uZ29vZ2xlLmZpcmVzdG9yZS52MS5BcnJheVZhbHVlSABSFWFwcGVuZE1pc3Np
bmdFbGVtZW50cxJUChVyZW1vdmVfYWxsX2Zyb21fYXJyYXkYByABKAsyHy5nb29nbGUuZmly
ZXN0b3JlLnYxLkFycmF5VmFsdWVIAFIScmVtb3ZlQWxsRnJvbUFycmF5Ij0KC1NlcnZlclZh
bHVlEhwKGFNFUlZFUl9WQUxVRV9VTlNQRUNJRklFRBAAEhAKDFJFUVVFU1RfVElNRRABQhAK
DnRyYW5zZm9ybV90eXBlIpMBCgtXcml0ZVJlc3VsdBI7Cgt1cGRhdGVfdGltZRgBIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSRwoRdHJhbnNmb3JtX3Jl
c3VsdHMYAiADKAsyGi5nb29nbGUuZmlyZXN0b3JlLnYxLlZhbHVlUhB0cmFuc2Zvcm1SZXN1
bHRzIpgBCg5Eb2N1bWVudENoYW5nZRI5Cghkb2N1bWVudBgBIAEoCzIdLmdvb2dsZS5maXJl
c3RvcmUudjEuRG9jdW1lbnRSCGRvY3VtZW50Eh0KCnRhcmdldF9pZHMYBSADKAVSCXRhcmdl
dElkcxIsChJyZW1vdmVkX3RhcmdldF9pZHMYBiADKAVSEHJlbW92ZWRUYXJnZXRJZHMikwEK
DkRvY3VtZW50RGVsZXRlEhoKCGRvY3VtZW50GAEgASgJUghkb2N1bWVudBIsChJyZW1vdmVk
X3RhcmdldF9pZHMYBiADKAVSEHJlbW92ZWRUYXJnZXRJZHMSNwoJcmVhZF90aW1lGAQgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIIcmVhZFRpbWUikwEKDkRvY3VtZW50UmVt
b3ZlEhoKCGRvY3VtZW50GAEgASgJUghkb2N1bWVudBIsChJyZW1vdmVkX3RhcmdldF9pZHMY
AiADKAVSEHJlbW92ZWRUYXJnZXRJZHMSNwoJcmVhZF90aW1lGAQgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcFIIcmVhZFRpbWUijwEKD0V4aXN0ZW5jZUZpbHRlchIbCgl0YXJn
ZXRfaWQYASABKAVSCHRhcmdldElkEhQKBWNvdW50GAIgASgFUgVjb3VudBJJCg91bmNoYW5n
ZWRfbmFtZXMYAyABKAsyIC5nb29nbGUuZmlyZXN0b3JlLnYxLkJsb29tRmlsdGVyUg51bmNo
YW5nZWROYW1lc0LCAQoXY29tLmdvb2dsZS5maXJlc3RvcmUudjFCCldyaXRlUHJvdG9QAVo7
Y2xvdWQuZ29vZ2xlLmNvbS9nby9maXJlc3RvcmUvYXBpdjEvZmlyZXN0b3JlcGI7ZmlyZXN0
b3JlcGKiAgRHQ0ZTqgIZR29vZ2xlLkNsb3VkLkZpcmVzdG9yZS5WMcoCGUdvb2dsZVxDbG91
ZFxGaXJlc3RvcmVcVjHqAhxHb29nbGU6OkNsb3VkOjpGaXJlc3RvcmU6OlYxStlaCgcSBQ4A
nQIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMA
EgMSADAKCQoCAwESAxMAKgoJCgIDAhIDFAAsCgkKAgMDEgMVACkKCAoBCBIDFwA2CgkKAggl
EgMXADYKCAoBCBIDGABSCgkKAggLEgMYAFIKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBID
GgArCgkKAggIEgMaACsKCAoBCBIDGwAwCgkKAggBEgMbADAKCAoBCBIDHAAiCgkKAggkEgMc
ACIKCAoBCBIDHQA2CgkKAggpEgMdADYKCAoBCBIDHgA1CgkKAggtEgMeADUKJAoCBAASBCEA
RgEaGCBBIHdyaXRlIG9uIGEgZG9jdW1lbnQuCgoKCgMEAAESAyEIDQopCgQEAAgAEgQjAi0D
GhsgVGhlIG9wZXJhdGlvbiB0byBleGVjdXRlLgoKDAoFBAAIAAESAyMIEQojCgQEAAIAEgMl
BBgaFiBBIGRvY3VtZW50IHRvIHdyaXRlLgoKDAoFBAACAAYSAyUEDAoMCgUEAAIAARIDJQ0T
CgwKBQQAAgADEgMlFhcKhAEKBAQAAgESAykEFhp3IEEgZG9jdW1lbnQgbmFtZSB0byBkZWxl
dGUuIEluIHRoZSBmb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2RhdGFiYXNlcy97
ZGF0YWJhc2VfaWR9L2RvY3VtZW50cy97ZG9jdW1lbnRfcGF0aH1gLgoKDAoFBAACAQUSAykE
CgoMCgUEAAIBARIDKQsRCgwKBQQAAgEDEgMpFBUKNgoEBAACAhIDLAQkGikgQXBwbGllcyBh
IHRyYW5zZm9ybWF0aW9uIHRvIGEgZG9jdW1lbnQuCgoMCgUEAAICBhIDLAQVCgwKBQQAAgIB
EgMsFh8KDAoFBAACAgMSAywiIwqFBAoEBAACAxIDOQIfGvcDIFRoZSBmaWVsZHMgdG8gdXBk
YXRlIGluIHRoaXMgd3JpdGUuCgogVGhpcyBmaWVsZCBjYW4gYmUgc2V0IG9ubHkgd2hlbiB0
aGUgb3BlcmF0aW9uIGlzIGB1cGRhdGVgLgogSWYgdGhlIG1hc2sgaXMgbm90IHNldCBmb3Ig
YW4gYHVwZGF0ZWAgYW5kIHRoZSBkb2N1bWVudCBleGlzdHMsIGFueQogZXhpc3RpbmcgZGF0
YSB3aWxsIGJlIG92ZXJ3cml0dGVuLgogSWYgdGhlIG1hc2sgaXMgc2V0IGFuZCB0aGUgZG9j
dW1lbnQgb24gdGhlIHNlcnZlciBoYXMgZmllbGRzIG5vdCBjb3ZlcmVkIGJ5CiB0aGUgbWFz
aywgdGhleSBhcmUgbGVmdCB1bmNoYW5nZWQuCiBGaWVsZHMgcmVmZXJlbmNlZCBpbiB0aGUg
bWFzaywgYnV0IG5vdCBwcmVzZW50IGluIHRoZSBpbnB1dCBkb2N1bWVudCwgYXJlCiBkZWxl
dGVkIGZyb20gdGhlIGRvY3VtZW50IG9uIHRoZSBzZXJ2ZXIuCiBUaGUgZmllbGQgcGF0aHMg
aW4gdGhpcyBtYXNrIG11c3Qgbm90IGNvbnRhaW4gYSByZXNlcnZlZCBmaWVsZCBuYW1lLgoK
DAoFBAACAwYSAzkCDgoMCgUEAAIDARIDOQ8aCgwKBQQAAgMDEgM5HR4K8AEKBAQAAgQSA0AC
QhriASBUaGUgdHJhbnNmb3JtcyB0byBwZXJmb3JtIGFmdGVyIHVwZGF0ZS4KCiBUaGlzIGZp
ZWxkIGNhbiBiZSBzZXQgb25seSB3aGVuIHRoZSBvcGVyYXRpb24gaXMgYHVwZGF0ZWAuIElm
IHByZXNlbnQsIHRoaXMKIHdyaXRlIGlzIGVxdWl2YWxlbnQgdG8gcGVyZm9ybWluZyBgdXBk
YXRlYCBhbmQgYHRyYW5zZm9ybWAgdG8gdGhlIHNhbWUKIGRvY3VtZW50IGF0b21pY2FsbHkg
YW5kIGluIG9yZGVyLgoKDAoFBAACBAQSA0ACCgoMCgUEAAIEBhIDQAsrCgwKBQQAAgQBEgNA
LD0KDAoFBAACBAMSA0BAQQqBAQoEBAACBRIDRQIkGnQgQW4gb3B0aW9uYWwgcHJlY29uZGl0
aW9uIG9uIHRoZSBkb2N1bWVudC4KCiBUaGUgd3JpdGUgd2lsbCBmYWlsIGlmIHRoaXMgaXMg
c2V0IGFuZCBub3QgbWV0IGJ5IHRoZSB0YXJnZXQgZG9jdW1lbnQuCgoMCgUEAAIFBhIDRQIO
CgwKBQQAAgUBEgNFDx8KDAoFBAACBQMSA0UiIwouCgIEARIFSQCsAQEaISBBIHRyYW5zZm9y
bWF0aW9uIG9mIGEgZG9jdW1lbnQuCgoKCgMEAQESA0kIGQo9CgQEAQMAEgVLAqMBAxouIEEg
dHJhbnNmb3JtYXRpb24gb2YgYSBmaWVsZCBvZiB0aGUgZG9jdW1lbnQuCgoMCgUEAQMAARID
SwoYCjsKBgQBAwAEABIETQRVBRorIEEgdmFsdWUgdGhhdCBpcyBjYWxjdWxhdGVkIGJ5IHRo
ZSBzZXJ2ZXIuCgoOCgcEAQMABAABEgNNCRQKPAoIBAEDAAQAAgASA08GIxorIFVuc3BlY2lm
aWVkLiBUaGlzIHZhbHVlIG11c3Qgbm90IGJlIHVzZWQuCgoQCgkEAQMABAACAAESA08GHgoQ
CgkEAQMABAACAAISA08hIgrjAQoIBAEDAAQAAgESA1QGFxrRASBUaGUgdGltZSBhdCB3aGlj
aCB0aGUgc2VydmVyIHByb2Nlc3NlZCB0aGUgcmVxdWVzdCwgd2l0aCBtaWxsaXNlY29uZAog
cHJlY2lzaW9uLiBJZiB1c2VkIG9uIG11bHRpcGxlIGZpZWxkcyAoc2FtZSBvciBkaWZmZXJl
bnQgZG9jdW1lbnRzKSBpbgogYSB0cmFuc2FjdGlvbiwgYWxsIHRoZSBmaWVsZHMgd2lsbCBn
ZXQgdGhlIHNhbWUgc2VydmVyIHRpbWVzdGFtcC4KChAKCQQBAwAEAAIBARIDVAYSChAKCQQB
AwAEAAIBAhIDVBUWCokBCgYEAQMAAgASA1oEGhp6IFRoZSBwYXRoIG9mIHRoZSBmaWVsZC4g
U2VlCiBbRG9jdW1lbnQuZmllbGRzXVtnb29nbGUuZmlyZXN0b3JlLnYxLkRvY3VtZW50LmZp
ZWxkc10gZm9yIHRoZSBmaWVsZCBwYXRoCiBzeW50YXggcmVmZXJlbmNlLgoKDgoHBAEDAAIA
BRIDWgQKCg4KBwQBAwACAAESA1oLFQoOCgcEAQMAAgADEgNaGBkKPAoGBAEDAAgAEgVdBKIB
BRorIFRoZSB0cmFuc2Zvcm1hdGlvbiB0byBhcHBseSBvbiB0aGUgZmllbGQuCgoOCgcEAQMA
CAABEgNdChgKOgoGBAEDAAIBEgNfBioaKyBTZXRzIHRoZSBmaWVsZCB0byB0aGUgZ2l2ZW4g
c2VydmVyIHZhbHVlLgoKDgoHBAEDAAIBBhIDXwYRCg4KBwQBAwACAQESA18SJQoOCgcEAQMA
AgEDEgNfKCkKvAQKBgQBAwACAhIDawYaGqwEIEFkZHMgdGhlIGdpdmVuIHZhbHVlIHRvIHRo
ZSBmaWVsZCdzIGN1cnJlbnQgdmFsdWUuCgogVGhpcyBtdXN0IGJlIGFuIGludGVnZXIgb3Ig
YSBkb3VibGUgdmFsdWUuCiBJZiB0aGUgZmllbGQgaXMgbm90IGFuIGludGVnZXIgb3IgZG91
YmxlLCBvciBpZiB0aGUgZmllbGQgZG9lcyBub3QgeWV0CiBleGlzdCwgdGhlIHRyYW5zZm9y
bWF0aW9uIHdpbGwgc2V0IHRoZSBmaWVsZCB0byB0aGUgZ2l2ZW4gdmFsdWUuCiBJZiBlaXRo
ZXIgb2YgdGhlIGdpdmVuIHZhbHVlIG9yIHRoZSBjdXJyZW50IGZpZWxkIHZhbHVlIGFyZSBk
b3VibGVzLAogYm90aCB2YWx1ZXMgd2lsbCBiZSBpbnRlcnByZXRlZCBhcyBkb3VibGVzLiBE
b3VibGUgYXJpdGhtZXRpYyBhbmQKIHJlcHJlc2VudGF0aW9uIG9mIGRvdWJsZSB2YWx1ZXMg
Zm9sbG93IElFRUUgNzU0IHNlbWFudGljcy4KIElmIHRoZXJlIGlzIHBvc2l0aXZlL25lZ2F0
aXZlIGludGVnZXIgb3ZlcmZsb3csIHRoZSBmaWVsZCBpcyByZXNvbHZlZAogdG8gdGhlIGxh
cmdlc3QgbWFnbml0dWRlIHBvc2l0aXZlL25lZ2F0aXZlIGludGVnZXIuCgoOCgcEAQMAAgIG
EgNrBgsKDgoHBAEDAAICARIDawwVCg4KBwQBAwACAgMSA2sYGQrHBQoGBAEDAAIDEgN5Bhga
twUgU2V0cyB0aGUgZmllbGQgdG8gdGhlIG1heGltdW0gb2YgaXRzIGN1cnJlbnQgdmFsdWUg
YW5kIHRoZSBnaXZlbiB2YWx1ZS4KCiBUaGlzIG11c3QgYmUgYW4gaW50ZWdlciBvciBhIGRv
dWJsZSB2YWx1ZS4KIElmIHRoZSBmaWVsZCBpcyBub3QgYW4gaW50ZWdlciBvciBkb3VibGUs
IG9yIGlmIHRoZSBmaWVsZCBkb2VzIG5vdCB5ZXQKIGV4aXN0LCB0aGUgdHJhbnNmb3JtYXRp
b24gd2lsbCBzZXQgdGhlIGZpZWxkIHRvIHRoZSBnaXZlbiB2YWx1ZS4KIElmIGEgbWF4aW11
bSBvcGVyYXRpb24gaXMgYXBwbGllZCB3aGVyZSB0aGUgZmllbGQgYW5kIHRoZSBpbnB1dCB2
YWx1ZQogYXJlIG9mIG1peGVkIHR5cGVzICh0aGF0IGlzIC0gb25lIGlzIGFuIGludGVnZXIg
YW5kIG9uZSBpcyBhIGRvdWJsZSkKIHRoZSBmaWVsZCB0YWtlcyBvbiB0aGUgdHlwZSBvZiB0
aGUgbGFyZ2VyIG9wZXJhbmQuIElmIHRoZSBvcGVyYW5kcyBhcmUKIGVxdWl2YWxlbnQgKGUu
Zy4gMyBhbmQgMy4wKSwgdGhlIGZpZWxkIGRvZXMgbm90IGNoYW5nZS4KIDAsIDAuMCwgYW5k
IC0wLjAgYXJlIGFsbCB6ZXJvLiBUaGUgbWF4aW11bSBvZiBhIHplcm8gc3RvcmVkIHZhbHVl
IGFuZAogemVybyBpbnB1dCB2YWx1ZSBpcyBhbHdheXMgdGhlIHN0b3JlZCB2YWx1ZS4KIFRo
ZSBtYXhpbXVtIG9mIGFueSBudW1lcmljIHZhbHVlIHggYW5kIE5hTiBpcyBOYU4uCgoOCgcE
AQMAAgMGEgN5BgsKDgoHBAEDAAIDARIDeQwTCg4KBwQBAwACAwMSA3kWFwrJBQoGBAEDAAIE
EgSHAQYYGrgFIFNldHMgdGhlIGZpZWxkIHRvIHRoZSBtaW5pbXVtIG9mIGl0cyBjdXJyZW50
IHZhbHVlIGFuZCB0aGUgZ2l2ZW4gdmFsdWUuCgogVGhpcyBtdXN0IGJlIGFuIGludGVnZXIg
b3IgYSBkb3VibGUgdmFsdWUuCiBJZiB0aGUgZmllbGQgaXMgbm90IGFuIGludGVnZXIgb3Ig
ZG91YmxlLCBvciBpZiB0aGUgZmllbGQgZG9lcyBub3QgeWV0CiBleGlzdCwgdGhlIHRyYW5z
Zm9ybWF0aW9uIHdpbGwgc2V0IHRoZSBmaWVsZCB0byB0aGUgaW5wdXQgdmFsdWUuCiBJZiBh
IG1pbmltdW0gb3BlcmF0aW9uIGlzIGFwcGxpZWQgd2hlcmUgdGhlIGZpZWxkIGFuZCB0aGUg
aW5wdXQgdmFsdWUKIGFyZSBvZiBtaXhlZCB0eXBlcyAodGhhdCBpcyAtIG9uZSBpcyBhbiBp
bnRlZ2VyIGFuZCBvbmUgaXMgYSBkb3VibGUpCiB0aGUgZmllbGQgdGFrZXMgb24gdGhlIHR5
cGUgb2YgdGhlIHNtYWxsZXIgb3BlcmFuZC4gSWYgdGhlIG9wZXJhbmRzIGFyZQogZXF1aXZh
bGVudCAoZS5nLiAzIGFuZCAzLjApLCB0aGUgZmllbGQgZG9lcyBub3QgY2hhbmdlLgogMCwg
MC4wLCBhbmQgLTAuMCBhcmUgYWxsIHplcm8uIFRoZSBtaW5pbXVtIG9mIGEgemVybyBzdG9y
ZWQgdmFsdWUgYW5kCiB6ZXJvIGlucHV0IHZhbHVlIGlzIGFsd2F5cyB0aGUgc3RvcmVkIHZh
bHVlLgogVGhlIG1pbmltdW0gb2YgYW55IG51bWVyaWMgdmFsdWUgeCBhbmQgTmFOIGlzIE5h
Ti4KCg8KBwQBAwACBAYSBIcBBgsKDwoHBAEDAAIEARIEhwEMEwoPCgcEAQMAAgQDEgSHARYX
CpQECgYEAQMAAgUSBJUBBi0agwQgQXBwZW5kIHRoZSBnaXZlbiBlbGVtZW50cyBpbiBvcmRl
ciBpZiB0aGV5IGFyZSBub3QgYWxyZWFkeSBwcmVzZW50IGluCiB0aGUgY3VycmVudCBmaWVs
ZCB2YWx1ZS4KIElmIHRoZSBmaWVsZCBpcyBub3QgYW4gYXJyYXksIG9yIGlmIHRoZSBmaWVs
ZCBkb2VzIG5vdCB5ZXQgZXhpc3QsIGl0IGlzCiBmaXJzdCBzZXQgdG8gdGhlIGVtcHR5IGFy
cmF5LgoKIEVxdWl2YWxlbnQgbnVtYmVycyBvZiBkaWZmZXJlbnQgdHlwZXMgKGUuZy4gM0wg
YW5kIDMuMCkgYXJlCiBjb25zaWRlcmVkIGVxdWFsIHdoZW4gY2hlY2tpbmcgaWYgYSB2YWx1
ZSBpcyBtaXNzaW5nLgogTmFOIGlzIGVxdWFsIHRvIE5hTiwgYW5kIE51bGwgaXMgZXF1YWwg
dG8gTnVsbC4KIElmIHRoZSBpbnB1dCBjb250YWlucyBtdWx0aXBsZSBlcXVpdmFsZW50IHZh
bHVlcywgb25seSB0aGUgZmlyc3Qgd2lsbAogYmUgY29uc2lkZXJlZC4KCiBUaGUgY29ycmVz
cG9uZGluZyB0cmFuc2Zvcm1fcmVzdWx0IHdpbGwgYmUgdGhlIG51bGwgdmFsdWUuCgoPCgcE
AQMAAgUGEgSVAQYQCg8KBwQBAwACBQESBJUBESgKDwoHBAEDAAIFAxIElQErLArpAwoGBAED
AAIGEgShAQYrGtgDIFJlbW92ZSBhbGwgb2YgdGhlIGdpdmVuIGVsZW1lbnRzIGZyb20gdGhl
IGFycmF5IGluIHRoZSBmaWVsZC4KIElmIHRoZSBmaWVsZCBpcyBub3QgYW4gYXJyYXksIG9y
IGlmIHRoZSBmaWVsZCBkb2VzIG5vdCB5ZXQgZXhpc3QsIGl0IGlzCiBzZXQgdG8gdGhlIGVt
cHR5IGFycmF5LgoKIEVxdWl2YWxlbnQgbnVtYmVycyBvZiB0aGUgZGlmZmVyZW50IHR5cGVz
IChlLmcuIDNMIGFuZCAzLjApIGFyZQogY29uc2lkZXJlZCBlcXVhbCB3aGVuIGRlY2lkaW5n
IHdoZXRoZXIgYW4gZWxlbWVudCBzaG91bGQgYmUgcmVtb3ZlZC4KIE5hTiBpcyBlcXVhbCB0
byBOYU4sIGFuZCBOdWxsIGlzIGVxdWFsIHRvIE51bGwuCiBUaGlzIHdpbGwgcmVtb3ZlIGFs
bCBlcXVpdmFsZW50IHZhbHVlcyBpZiB0aGVyZSBhcmUgZHVwbGljYXRlcy4KCiBUaGUgY29y
cmVzcG9uZGluZyB0cmFuc2Zvcm1fcmVzdWx0IHdpbGwgYmUgdGhlIG51bGwgdmFsdWUuCgoP
CgcEAQMAAgYGEgShAQYQCg8KBwQBAwACBgESBKEBESYKDwoHBAEDAAIGAxIEoQEpKgo2CgQE
AQIAEgSmAQIWGiggVGhlIG5hbWUgb2YgdGhlIGRvY3VtZW50IHRvIHRyYW5zZm9ybS4KCg0K
BQQBAgAFEgSmAQIICg0KBQQBAgABEgSmAQkRCg0KBQQBAgADEgSmARQVCncKBAQBAgESBKsB
Ai8aaSBUaGUgbGlzdCBvZiB0cmFuc2Zvcm1hdGlvbnMgdG8gYXBwbHkgdG8gdGhlIGZpZWxk
cyBvZiB0aGUgZG9jdW1lbnQsIGluCiBvcmRlci4KIFRoaXMgbXVzdCBub3QgYmUgZW1wdHku
CgoNCgUEAQIBBBIEqwECCgoNCgUEAQIBBhIEqwELGQoNCgUEAQIBARIEqwEaKgoNCgUEAQIB
AxIEqwEtLgovCgIEAhIGrwEAuwEBGiEgVGhlIHJlc3VsdCBvZiBhcHBseWluZyBhIHdyaXRl
LgoKCwoDBAIBEgSvAQgTCscBCgQEAgIAEgS1AQIsGrgBIFRoZSBsYXN0IHVwZGF0ZSB0aW1l
IG9mIHRoZSBkb2N1bWVudCBhZnRlciBhcHBseWluZyB0aGUgd3JpdGUuIE5vdCBzZXQKIGFm
dGVyIGEgYGRlbGV0ZWAuCgogSWYgdGhlIHdyaXRlIGRpZCBub3QgYWN0dWFsbHkgY2hhbmdl
IHRoZSBkb2N1bWVudCwgdGhpcyB3aWxsIGJlIHRoZQogcHJldmlvdXMgdXBkYXRlX3RpbWUu
CgoNCgUEAgIABhIEtQECGwoNCgUEAgIAARIEtQEcJwoNCgUEAgIAAxIEtQEqKwqcAQoEBAIC
ARIEugECJxqNASBUaGUgcmVzdWx0cyBvZiBhcHBseWluZyBlYWNoCiBbRG9jdW1lbnRUcmFu
c2Zvcm0uRmllbGRUcmFuc2Zvcm1dW2dvb2dsZS5maXJlc3RvcmUudjEuRG9jdW1lbnRUcmFu
c2Zvcm0uRmllbGRUcmFuc2Zvcm1dLAogaW4gdGhlIHNhbWUgb3JkZXIuCgoNCgUEAgIBBBIE
ugECCgoNCgUEAgIBBhIEugELEAoNCgUEAgIBARIEugERIgoNCgUEAgIBAxIEugElJgqVAwoC
BAMSBsUBANABARqGAyBBIFtEb2N1bWVudF1bZ29vZ2xlLmZpcmVzdG9yZS52MS5Eb2N1bWVu
dF0gaGFzIGNoYW5nZWQuCgogTWF5IGJlIHRoZSByZXN1bHQgb2YgbXVsdGlwbGUgW3dyaXRl
c11bZ29vZ2xlLmZpcmVzdG9yZS52MS5Xcml0ZV0sIGluY2x1ZGluZwogZGVsZXRlcywgdGhh
dCB1bHRpbWF0ZWx5IHJlc3VsdGVkIGluIGEgbmV3IHZhbHVlIGZvciB0aGUKIFtEb2N1bWVu
dF1bZ29vZ2xlLmZpcmVzdG9yZS52MS5Eb2N1bWVudF0uCgogTXVsdGlwbGUgW0RvY3VtZW50
Q2hhbmdlXVtnb29nbGUuZmlyZXN0b3JlLnYxLkRvY3VtZW50Q2hhbmdlXSBtZXNzYWdlcyBt
YXkgYmUKIHJldHVybmVkIGZvciB0aGUgc2FtZSBsb2dpY2FsIGNoYW5nZSwgaWYgbXVsdGlw
bGUgdGFyZ2V0cyBhcmUgYWZmZWN0ZWQuCgoLCgMEAwESBMUBCBYKlAEKBAQDAgASBMkBAhga
hQEgVGhlIG5ldyBzdGF0ZSBvZiB0aGUgW0RvY3VtZW50XVtnb29nbGUuZmlyZXN0b3JlLnYx
LkRvY3VtZW50XS4KCiBJZiBgbWFza2AgaXMgc2V0LCBjb250YWlucyBvbmx5IGZpZWxkcyB0
aGF0IHdlcmUgdXBkYXRlZCBvciBhZGRlZC4KCg0KBQQDAgAGEgTJAQIKCg0KBQQDAgABEgTJ
AQsTCg0KBQQDAgADEgTJARYXCkgKBAQDAgESBMwBAiAaOiBBIHNldCBvZiB0YXJnZXQgSURz
IG9mIHRhcmdldHMgdGhhdCBtYXRjaCB0aGlzIGRvY3VtZW50LgoKDQoFBAMCAQQSBMwBAgoK
DQoFBAMCAQUSBMwBCxAKDQoFBAMCAQESBMwBERsKDQoFBAMCAQMSBMwBHh8KUwoEBAMCAhIE
zwECKBpFIEEgc2V0IG9mIHRhcmdldCBJRHMgZm9yIHRhcmdldHMgdGhhdCBubyBsb25nZXIg
bWF0Y2ggdGhpcyBkb2N1bWVudC4KCg0KBQQDAgIEEgTPAQIKCg0KBQQDAgIFEgTPAQsQCg0K
BQQDAgIBEgTPAREjCg0KBQQDAgIDEgTPASYnCogDCgIEBBIG2gEA5gEBGvkCIEEgW0RvY3Vt
ZW50XVtnb29nbGUuZmlyZXN0b3JlLnYxLkRvY3VtZW50XSBoYXMgYmVlbiBkZWxldGVkLgoK
IE1heSBiZSB0aGUgcmVzdWx0IG9mIG11bHRpcGxlIFt3cml0ZXNdW2dvb2dsZS5maXJlc3Rv
cmUudjEuV3JpdGVdLCBpbmNsdWRpbmcKIHVwZGF0ZXMsIHRoZSBsYXN0IG9mIHdoaWNoIGRl
bGV0ZWQgdGhlCiBbRG9jdW1lbnRdW2dvb2dsZS5maXJlc3RvcmUudjEuRG9jdW1lbnRdLgoK
IE11bHRpcGxlIFtEb2N1bWVudERlbGV0ZV1bZ29vZ2xlLmZpcmVzdG9yZS52MS5Eb2N1bWVu
dERlbGV0ZV0gbWVzc2FnZXMgbWF5IGJlCiByZXR1cm5lZCBmb3IgdGhlIHNhbWUgbG9naWNh
bCBkZWxldGUsIGlmIG11bHRpcGxlIHRhcmdldHMgYXJlIGFmZmVjdGVkLgoKCwoDBAQBEgTa
AQgWCmQKBAQEAgASBN0BAhYaViBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgW0RvY3VtZW50
XVtnb29nbGUuZmlyZXN0b3JlLnYxLkRvY3VtZW50XSB0aGF0IHdhcwogZGVsZXRlZC4KCg0K
BQQEAgAFEgTdAQIICg0KBQQEAgABEgTdAQkRCg0KBQQEAgADEgTdARQVClQKBAQEAgESBOAB
AigaRiBBIHNldCBvZiB0YXJnZXQgSURzIGZvciB0YXJnZXRzIHRoYXQgcHJldmlvdXNseSBt
YXRjaGVkIHRoaXMgZW50aXR5LgoKDQoFBAQCAQQSBOABAgoKDQoFBAQCAQUSBOABCxAKDQoF
BAQCAQESBOABESMKDQoFBAQCAQMSBOABJicKewoEBAQCAhIE5QECKhptIFRoZSByZWFkIHRp
bWVzdGFtcCBhdCB3aGljaCB0aGUgZGVsZXRlIHdhcyBvYnNlcnZlZC4KCiBHcmVhdGVyIG9y
IGVxdWFsIHRvIHRoZSBgY29tbWl0X3RpbWVgIG9mIHRoZSBkZWxldGUuCgoNCgUEBAICBhIE
5QECGwoNCgUEBAICARIE5QEcJQoNCgUEBAICAxIE5QEoKQrTAwoCBAUSBvIBAP4BARrEAyBB
IFtEb2N1bWVudF1bZ29vZ2xlLmZpcmVzdG9yZS52MS5Eb2N1bWVudF0gaGFzIGJlZW4gcmVt
b3ZlZCBmcm9tIHRoZSB2aWV3IG9mCiB0aGUgdGFyZ2V0cy4KCiBTZW50IGlmIHRoZSBkb2N1
bWVudCBpcyBubyBsb25nZXIgcmVsZXZhbnQgdG8gYSB0YXJnZXQgYW5kIGlzIG91dCBvZiB2
aWV3LgogQ2FuIGJlIHNlbnQgaW5zdGVhZCBvZiBhIERvY3VtZW50RGVsZXRlIG9yIGEgRG9j
dW1lbnRDaGFuZ2UgaWYgdGhlIHNlcnZlcgogY2FuIG5vdCBzZW5kIHRoZSBuZXcgdmFsdWUg
b2YgdGhlIGRvY3VtZW50LgoKIE11bHRpcGxlIFtEb2N1bWVudFJlbW92ZV1bZ29vZ2xlLmZp
cmVzdG9yZS52MS5Eb2N1bWVudFJlbW92ZV0gbWVzc2FnZXMgbWF5IGJlCiByZXR1cm5lZCBm
b3IgdGhlIHNhbWUgbG9naWNhbCB3cml0ZSBvciBkZWxldGUsIGlmIG11bHRpcGxlIHRhcmdl
dHMgYXJlCiBhZmZlY3RlZC4KCgsKAwQFARIE8gEIFgptCgQEBQIAEgT1AQIWGl8gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlIFtEb2N1bWVudF1bZ29vZ2xlLmZpcmVzdG9yZS52MS5Eb2N1
bWVudF0gdGhhdCBoYXMKIGdvbmUgb3V0IG9mIHZpZXcuCgoNCgUEBQIABRIE9QECCAoNCgUE
BQIAARIE9QEJEQoNCgUEBQIAAxIE9QEUFQpWCgQEBQIBEgT4AQIoGkggQSBzZXQgb2YgdGFy
Z2V0IElEcyBmb3IgdGFyZ2V0cyB0aGF0IHByZXZpb3VzbHkgbWF0Y2hlZCB0aGlzIGRvY3Vt
ZW50LgoKDQoFBAUCAQQSBPgBAgoKDQoFBAUCAQUSBPgBCxAKDQoFBAUCAQESBPgBESMKDQoF
BAUCAQMSBPgBJicKiQEKBAQFAgISBP0BAioaeyBUaGUgcmVhZCB0aW1lc3RhbXAgYXQgd2hp
Y2ggdGhlIHJlbW92ZSB3YXMgb2JzZXJ2ZWQuCgogR3JlYXRlciBvciBlcXVhbCB0byB0aGUg
YGNvbW1pdF90aW1lYCBvZiB0aGUgY2hhbmdlL2RlbGV0ZS9yZW1vdmUuCgoNCgUEBQICBhIE
/QECGwoNCgUEBQICARIE/QEcJQoNCgUEBQICAxIE/QEoKQpICgIEBhIGgQIAnQIBGjogQSBk
aWdlc3Qgb2YgYWxsIHRoZSBkb2N1bWVudHMgdGhhdCBtYXRjaCBhIGdpdmVuIHRhcmdldC4K
CgsKAwQGARIEgQIIFwo7CgQEBgIAEgSDAgIWGi0gVGhlIHRhcmdldCBJRCB0byB3aGljaCB0
aGlzIGZpbHRlciBhcHBsaWVzLgoKDQoFBAYCAAUSBIMCAgcKDQoFBAYCAAESBIMCCBEKDQoF
BAYCAAMSBIMCFBUK/AMKBAQGAgESBI8CAhIa7QMgVGhlIHRvdGFsIGNvdW50IG9mIGRvY3Vt
ZW50cyB0aGF0IG1hdGNoCiBbdGFyZ2V0X2lkXVtnb29nbGUuZmlyZXN0b3JlLnYxLkV4aXN0
ZW5jZUZpbHRlci50YXJnZXRfaWRdLgoKIElmIGRpZmZlcmVudCBmcm9tIHRoZSBjb3VudCBv
ZiBkb2N1bWVudHMgaW4gdGhlIGNsaWVudCB0aGF0IG1hdGNoLCB0aGUKIGNsaWVudCBtdXN0
IG1hbnVhbGx5IGRldGVybWluZSB3aGljaCBkb2N1bWVudHMgbm8gbG9uZ2VyIG1hdGNoIHRo
ZSB0YXJnZXQuCgogVGhlIGNsaWVudCBjYW4gdXNlIHRoZSBgdW5jaGFuZ2VkX25hbWVzYCBi
bG9vbSBmaWx0ZXIgdG8gYXNzaXN0IHdpdGgKIHRoaXMgZGV0ZXJtaW5hdGlvbiBieSB0ZXN0
aW5nIEFMTCB0aGUgZG9jdW1lbnQgbmFtZXMgYWdhaW5zdCB0aGUgZmlsdGVyOwogaWYgdGhl
IGRvY3VtZW50IG5hbWUgaXMgTk9UIGluIHRoZSBmaWx0ZXIsIGl0IG1lYW5zIHRoZSBkb2N1
bWVudCBubwogbG9uZ2VyIG1hdGNoZXMgdGhlIHRhcmdldC4KCg0KBQQGAgEFEgSPAgIHCg0K
BQQGAgEBEgSPAggNCg0KBQQGAgEDEgSPAhARCtgFCgQEBgICEgScAgIiGskFIEEgYmxvb20g
ZmlsdGVyIHRoYXQsIGRlc3BpdGUgaXRzIG5hbWUsIGNvbnRhaW5zIHRoZSBVVEYtOCBieXRl
IGVuY29kaW5ncyBvZgogdGhlIHJlc291cmNlIG5hbWVzIG9mIEFMTCB0aGUgZG9jdW1lbnRz
IHRoYXQgbWF0Y2gKIFt0YXJnZXRfaWRdW2dvb2dsZS5maXJlc3RvcmUudjEuRXhpc3RlbmNl
RmlsdGVyLnRhcmdldF9pZF0sIGluIHRoZSBmb3JtCiBgcHJvamVjdHMve3Byb2plY3RfaWR9
L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2RvY3VtZW50cy97ZG9jdW1lbnRfcGF0aH1gLgoK
IFRoaXMgYmxvb20gZmlsdGVyIG1heSBiZSBvbWl0dGVkIGF0IHRoZSBzZXJ2ZXIncyBkaXNj
cmV0aW9uLCBzdWNoIGFzIGlmIGl0CiBpcyBkZWVtZWQgdGhhdCB0aGUgY2xpZW50IHdpbGwg
bm90IG1ha2UgdXNlIG9mIGl0IG9yIGlmIGl0IGlzIHRvbwogY29tcHV0YXRpb25hbGx5IGV4
cGVuc2l2ZSB0byBjYWxjdWxhdGUgb3IgdHJhbnNtaXQuIENsaWVudHMgbXVzdCBncmFjZWZ1
bGx5CiBoYW5kbGUgdGhpcyBmaWVsZCBiZWluZyBhYnNlbnQgYnkgZmFsbGluZyBiYWNrIHRv
IHRoZSBsb2dpYyB1c2VkIGJlZm9yZQogdGhpcyBmaWVsZCBleGlzdGVkOyB0aGF0IGlzLCBy
ZS1hZGQgdGhlIHRhcmdldCB3aXRob3V0IGEgcmVzdW1lIHRva2VuIHRvCiBmaWd1cmUgb3V0
IHdoaWNoIGRvY3VtZW50cyBpbiB0aGUgY2xpZW50J3MgY2FjaGUgYXJlIG91dCBvZiBzeW5j
LgoKDQoFBAYCAgYSBJwCAg0KDQoFBAYCAgESBJwCDh0KDQoFBAYCAgMSBJwCICFiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1::Write::Write ===
    # Fields for Write
    # Field: update Type: 11 (.google.firestore.v1.Document)
    # Field: delete Type: 9 ()
    # Field: transform Type: 11 (.google.firestore.v1.DocumentTransform)
    # Field: update_mask Type: 11 (.google.firestore.v1.DocumentMask)
    # Field: update_transforms Type: 11 (.google.firestore.v1.DocumentTransform.FieldTransform)
    # Field: current_document Type: 11 (.google.firestore.v1.Precondition)

# === Message: Google::Firestore::V1::Write::DocumentTransform ===
    # Fields for DocumentTransform
    # Field: document Type: 9 ()
    # Field: field_transforms Type: 11 (.google.firestore.v1.DocumentTransform.FieldTransform)

# === Message: Google::Firestore::V1::Write::WriteResult ===
    # Fields for WriteResult
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: transform_results Type: 11 (.google.firestore.v1.Value)

# === Message: Google::Firestore::V1::Write::DocumentChange ===
    # Fields for DocumentChange
    # Field: document Type: 11 (.google.firestore.v1.Document)
    # Field: target_ids Type: 5 ()
    # Field: removed_target_ids Type: 5 ()

# === Message: Google::Firestore::V1::Write::DocumentDelete ===
    # Fields for DocumentDelete
    # Field: document Type: 9 ()
    # Field: removed_target_ids Type: 5 ()
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::V1::Write::DocumentRemove ===
    # Fields for DocumentRemove
    # Field: document Type: 9 ()
    # Field: removed_target_ids Type: 5 ()
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::V1::Write::ExistenceFilter ===
    # Fields for ExistenceFilter
    # Field: target_id Type: 5 ()
    # Field: count Type: 5 ()
    # Field: unchanged_names Type: 11 (.google.firestore.v1.BloomFilter)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1::Write - Compiled Protocol Buffers messages for google/firestore/v1/write.proto

=head1 SYNOPSIS

    use Google::Firestore::V1::Write;

    my $msg = Google::Firestore::V1::Write::Write->new({
        update => $update,
        delete => $delete,
        transform => $transform,
        update_mask => $update_mask,
    });

    # Read or update a field
    my $val = $msg->update();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1::Write::Write->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1/write.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1::Write::Write

A write on a document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update() >> / C<< $msg->update($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Document>)

A document to write.

=item * C<< $msg->delete() >> / C<< $msg->delete($value) >>

Type: C<String>

A document name to delete. In the format:
`projects/{project_id}/databases/{database_id}/documents/{document_path}`.

=item * C<< $msg->transform() >> / C<< $msg->transform($value) >>

Type: C<Message> (L<Google::Firestore::V1::Write::DocumentTransform>)

Applies a transformation to a document.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Firestore::V1::Common::DocumentMask>)

The fields to update in this write.

This field can be set only when the operation is `update`.
If the mask is not set for an `update` and the document exists, any
existing data will be overwritten.
If the mask is set and the document on the server has fields not covered by
the mask, they are left unchanged.
Fields referenced in the mask, but not present in the input document, are
deleted from the document on the server.
The field paths in this mask must not contain a reserved field name.

=item * C<< $msg->update_transforms() >> / C<< $msg->update_transforms($value) >>

Type: C<Message> (L<Google::Firestore::V1::Write::DocumentTransform::FieldTransform>)

The transforms to perform after update.

This field can be set only when the operation is `update`. If present, this
write is equivalent to performing `update` and `transform` to the same
document atomically and in order.

=item * C<< $msg->current_document() >> / C<< $msg->current_document($value) >>

Type: C<Message> (L<Google::Firestore::V1::Common::Precondition>)

An optional precondition on the document.

The write will fail if this is set and not met by the target document.

=back

=head2 Google::Firestore::V1::Write::DocumentTransform

A transformation of a document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<String>

The name of the document to transform.

=item * C<< $msg->field_transforms() >> / C<< $msg->field_transforms($value) >>

Type: C<Message> (L<Google::Firestore::V1::Write::DocumentTransform::FieldTransform>)

The list of transformations to apply to the fields of the document, in
order.
This must not be empty.

=back

=head2 Google::Firestore::V1::Write::WriteResult

The result of applying a write.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last update time of the document after applying the write. Not set
after a `delete`.

If the write did not actually change the document, this will be the
previous update_time.

=item * C<< $msg->transform_results() >> / C<< $msg->transform_results($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Value>)

The results of applying each
[DocumentTransform.FieldTransform][google.firestore.v1.DocumentTransform.FieldTransform],
in the same order.

=back

=head2 Google::Firestore::V1::Write::DocumentChange

A [Document][google.firestore.v1.Document] has changed.

May be the result of multiple [writes][google.firestore.v1.Write], including
deletes, that ultimately resulted in a new value for the
[Document][google.firestore.v1.Document].

Multiple [DocumentChange][google.firestore.v1.DocumentChange] messages may be
returned for the same logical change, if multiple targets are affected.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Document>)

The new state of the [Document][google.firestore.v1.Document].

If `mask` is set, contains only fields that were updated or added.

=item * C<< $msg->target_ids() >> / C<< $msg->target_ids($value) >>

Type: C<Int32>

A set of target IDs of targets that match this document.

=item * C<< $msg->removed_target_ids() >> / C<< $msg->removed_target_ids($value) >>

Type: C<Int32>

A set of target IDs for targets that no longer match this document.

=back

=head2 Google::Firestore::V1::Write::DocumentDelete

A [Document][google.firestore.v1.Document] has been deleted.

May be the result of multiple [writes][google.firestore.v1.Write], including
updates, the last of which deleted the
[Document][google.firestore.v1.Document].

Multiple [DocumentDelete][google.firestore.v1.DocumentDelete] messages may be
returned for the same logical delete, if multiple targets are affected.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<String>

The resource name of the [Document][google.firestore.v1.Document] that was
deleted.

=item * C<< $msg->removed_target_ids() >> / C<< $msg->removed_target_ids($value) >>

Type: C<Int32>

A set of target IDs for targets that previously matched this entity.

=item * C<< $msg->read_time() >> / C<< $msg->read_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The read timestamp at which the delete was observed.

Greater or equal to the `commit_time` of the delete.

=back

=head2 Google::Firestore::V1::Write::DocumentRemove

A [Document][google.firestore.v1.Document] has been removed from the view of
the targets.

Sent if the document is no longer relevant to a target and is out of view.
Can be sent instead of a DocumentDelete or a DocumentChange if the server
can not send the new value of the document.

Multiple [DocumentRemove][google.firestore.v1.DocumentRemove] messages may be
returned for the same logical write or delete, if multiple targets are
affected.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<String>

The resource name of the [Document][google.firestore.v1.Document] that has
gone out of view.

=item * C<< $msg->removed_target_ids() >> / C<< $msg->removed_target_ids($value) >>

Type: C<Int32>

A set of target IDs for targets that previously matched this document.

=item * C<< $msg->read_time() >> / C<< $msg->read_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The read timestamp at which the remove was observed.

Greater or equal to the `commit_time` of the change/delete/remove.

=back

=head2 Google::Firestore::V1::Write::ExistenceFilter

A digest of all the documents that match a given target.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target_id() >> / C<< $msg->target_id($value) >>

Type: C<Int32>

The target ID to which this filter applies.

=item * C<< $msg->count() >> / C<< $msg->count($value) >>

Type: C<Int32>

The total count of documents that match
[target_id][google.firestore.v1.ExistenceFilter.target_id].

If different from the count of documents in the client that match, the
client must manually determine which documents no longer match the target.

The client can use the `unchanged_names` bloom filter to assist with
this determination by testing ALL the document names against the filter;
if the document name is NOT in the filter, it means the document no
longer matches the target.

=item * C<< $msg->unchanged_names() >> / C<< $msg->unchanged_names($value) >>

Type: C<Message> (L<Google::Firestore::V1::BloomFilter::BloomFilter>)

A bloom filter that, despite its name, contains the UTF-8 byte encodings of
the resource names of ALL the documents that match
[target_id][google.firestore.v1.ExistenceFilter.target_id], in the form
`projects/{project_id}/databases/{database_id}/documents/{document_path}`.

This bloom filter may be omitted at the server's discretion, such as if it
is deemed that the client will not make use of it or if it is too
computationally expensive to calculate or transmit. Clients must gracefully
handle this field being absent by falling back to the logic used before
this field existed; that is, re-add the target without a resume token to
figure out which documents in the client's cache are out of sync.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1::Write::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
