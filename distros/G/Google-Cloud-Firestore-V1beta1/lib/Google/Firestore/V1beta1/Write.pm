package Google::Firestore::V1beta1::Write;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Firestore::V1beta1::Common };
    eval { require Google::Firestore::V1beta1::Document };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvZmlyZXN0b3JlL3YxYmV0YTEvd3JpdGUucHJvdG8SGGdvb2dsZS5maXJlc3Rv
cmUudjFiZXRhMRolZ29vZ2xlL2ZpcmVzdG9yZS92MWJldGExL2NvbW1vbi5wcm90bxonZ29v
Z2xlL2ZpcmVzdG9yZS92MWJldGExL2RvY3VtZW50LnByb3RvGh9nb29nbGUvcHJvdG9idWYv
dGltZXN0YW1wLnByb3RvIr4DCgVXcml0ZRI8CgZ1cGRhdGUYASABKAsyIi5nb29nbGUuZmly
ZXN0b3JlLnYxYmV0YTEuRG9jdW1lbnRIAFIGdXBkYXRlEhgKBmRlbGV0ZRgCIAEoCUgAUgZk
ZWxldGUSSwoJdHJhbnNmb3JtGAYgASgLMisuZ29vZ2xlLmZpcmVzdG9yZS52MWJldGExLkRv
Y3VtZW50VHJhbnNmb3JtSABSCXRyYW5zZm9ybRJHCgt1cGRhdGVfbWFzaxgDIAEoCzImLmdv
b2dsZS5maXJlc3RvcmUudjFiZXRhMS5Eb2N1bWVudE1hc2tSCnVwZGF0ZU1hc2sSZwoRdXBk
YXRlX3RyYW5zZm9ybXMYByADKAsyOi5nb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEuRG9jdW1l
bnRUcmFuc2Zvcm0uRmllbGRUcmFuc2Zvcm1SEHVwZGF0ZVRyYW5zZm9ybXMSUQoQY3VycmVu
dF9kb2N1bWVudBgEIAEoCzImLmdvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5QcmVjb25kaXRp
b25SD2N1cnJlbnREb2N1bWVudEILCglvcGVyYXRpb24iiAYKEURvY3VtZW50VHJhbnNmb3Jt
EhoKCGRvY3VtZW50GAEgASgJUghkb2N1bWVudBJlChBmaWVsZF90cmFuc2Zvcm1zGAIgAygL
MjouZ29vZ2xlLmZpcmVzdG9yZS52MWJldGExLkRvY3VtZW50VHJhbnNmb3JtLkZpZWxkVHJh
bnNmb3JtUg9maWVsZFRyYW5zZm9ybXMa7wQKDkZpZWxkVHJhbnNmb3JtEh0KCmZpZWxkX3Bh
dGgYASABKAlSCWZpZWxkUGF0aBJ3ChNzZXRfdG9fc2VydmVyX3ZhbHVlGAIgASgOMkYuZ29v
Z2xlLmZpcmVzdG9yZS52MWJldGExLkRvY3VtZW50VHJhbnNmb3JtLkZpZWxkVHJhbnNmb3Jt
LlNlcnZlclZhbHVlSABSEHNldFRvU2VydmVyVmFsdWUSPwoJaW5jcmVtZW50GAMgASgLMh8u
Z29vZ2xlLmZpcmVzdG9yZS52MWJldGExLlZhbHVlSABSCWluY3JlbWVudBI7CgdtYXhpbXVt
GAQgASgLMh8uZ29vZ2xlLmZpcmVzdG9yZS52MWJldGExLlZhbHVlSABSB21heGltdW0SOwoH
bWluaW11bRgFIAEoCzIfLmdvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5WYWx1ZUgAUgdtaW5p
bXVtEl4KF2FwcGVuZF9taXNzaW5nX2VsZW1lbnRzGAYgASgLMiQuZ29vZ2xlLmZpcmVzdG9y
ZS52MWJldGExLkFycmF5VmFsdWVIAFIVYXBwZW5kTWlzc2luZ0VsZW1lbnRzElkKFXJlbW92
ZV9hbGxfZnJvbV9hcnJheRgHIAEoCzIkLmdvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5BcnJh
eVZhbHVlSABSEnJlbW92ZUFsbEZyb21BcnJheSI9CgtTZXJ2ZXJWYWx1ZRIcChhTRVJWRVJf
VkFMVUVfVU5TUEVDSUZJRUQQABIQCgxSRVFVRVNUX1RJTUUQAUIQCg50cmFuc2Zvcm1fdHlw
ZSKYAQoLV3JpdGVSZXN1bHQSOwoLdXBkYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEkwKEXRyYW5zZm9ybV9yZXN1bHRzGAIgAygLMh8u
Z29vZ2xlLmZpcmVzdG9yZS52MWJldGExLlZhbHVlUhB0cmFuc2Zvcm1SZXN1bHRzIp0BCg5E
b2N1bWVudENoYW5nZRI+Cghkb2N1bWVudBgBIAEoCzIiLmdvb2dsZS5maXJlc3RvcmUudjFi
ZXRhMS5Eb2N1bWVudFIIZG9jdW1lbnQSHQoKdGFyZ2V0X2lkcxgFIAMoBVIJdGFyZ2V0SWRz
EiwKEnJlbW92ZWRfdGFyZ2V0X2lkcxgGIAMoBVIQcmVtb3ZlZFRhcmdldElkcyKTAQoORG9j
dW1lbnREZWxldGUSGgoIZG9jdW1lbnQYASABKAlSCGRvY3VtZW50EiwKEnJlbW92ZWRfdGFy
Z2V0X2lkcxgGIAMoBVIQcmVtb3ZlZFRhcmdldElkcxI3CglyZWFkX3RpbWUYBCABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wUghyZWFkVGltZSKTAQoORG9jdW1lbnRSZW1vdmUS
GgoIZG9jdW1lbnQYASABKAlSCGRvY3VtZW50EiwKEnJlbW92ZWRfdGFyZ2V0X2lkcxgCIAMo
BVIQcmVtb3ZlZFRhcmdldElkcxI3CglyZWFkX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUghyZWFkVGltZSJECg9FeGlzdGVuY2VGaWx0ZXISGwoJdGFyZ2V0X2lk
GAEgASgFUgh0YXJnZXRJZBIUCgVjb3VudBgCIAEoBVIFY291bnRC2wEKHGNvbS5nb29nbGUu
ZmlyZXN0b3JlLnYxYmV0YTFCCldyaXRlUHJvdG9QAVpAY2xvdWQuZ29vZ2xlLmNvbS9nby9m
aXJlc3RvcmUvYXBpdjFiZXRhMS9maXJlc3RvcmVwYjtmaXJlc3RvcmVwYqICBEdDRlOqAh5H
b29nbGUuQ2xvdWQuRmlyZXN0b3JlLlYxQmV0YTHKAh5Hb29nbGVcQ2xvdWRcRmlyZXN0b3Jl
XFYxYmV0YTHqAiFHb29nbGU6OkNsb3VkOjpGaXJlc3RvcmU6OlYxYmV0YTFKm1MKBxIFDgCB
AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwAS
AxIALwoJCgIDARIDEwAxCgkKAgMCEgMUACkKCAoBCBIDFgA7CgkKAgglEgMWADsKCAoBCBID
FwBXCgkKAggLEgMXAFcKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQArCgkKAggIEgMZ
ACsKCAoBCBIDGgA1CgkKAggBEgMaADUKCAoBCBIDGwAiCgkKAggkEgMbACIKCAoBCBIDHAA7
CgkKAggpEgMcADsKCAoBCBIDHQA6CgkKAggtEgMdADoKJAoCBAASBCAARQEaGCBBIHdyaXRl
IG9uIGEgZG9jdW1lbnQuCgoKCgMEAAESAyAIDQopCgQEAAgAEgQiAiwDGhsgVGhlIG9wZXJh
dGlvbiB0byBleGVjdXRlLgoKDAoFBAAIAAESAyIIEQojCgQEAAIAEgMkBBgaFiBBIGRvY3Vt
ZW50IHRvIHdyaXRlLgoKDAoFBAACAAYSAyQEDAoMCgUEAAIAARIDJA0TCgwKBQQAAgADEgMk
FhcKhAEKBAQAAgESAygEFhp3IEEgZG9jdW1lbnQgbmFtZSB0byBkZWxldGUuIEluIHRoZSBm
b3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9
L2RvY3VtZW50cy97ZG9jdW1lbnRfcGF0aH1gLgoKDAoFBAACAQUSAygECgoMCgUEAAIBARID
KAsRCgwKBQQAAgEDEgMoFBUKNgoEBAACAhIDKwQkGikgQXBwbGllcyBhIHRyYW5zZm9ybWF0
aW9uIHRvIGEgZG9jdW1lbnQuCgoMCgUEAAICBhIDKwQVCgwKBQQAAgIBEgMrFh8KDAoFBAAC
AgMSAysiIwqFBAoEBAACAxIDOAIfGvcDIFRoZSBmaWVsZHMgdG8gdXBkYXRlIGluIHRoaXMg
d3JpdGUuCgogVGhpcyBmaWVsZCBjYW4gYmUgc2V0IG9ubHkgd2hlbiB0aGUgb3BlcmF0aW9u
IGlzIGB1cGRhdGVgLgogSWYgdGhlIG1hc2sgaXMgbm90IHNldCBmb3IgYW4gYHVwZGF0ZWAg
YW5kIHRoZSBkb2N1bWVudCBleGlzdHMsIGFueQogZXhpc3RpbmcgZGF0YSB3aWxsIGJlIG92
ZXJ3cml0dGVuLgogSWYgdGhlIG1hc2sgaXMgc2V0IGFuZCB0aGUgZG9jdW1lbnQgb24gdGhl
IHNlcnZlciBoYXMgZmllbGRzIG5vdCBjb3ZlcmVkIGJ5CiB0aGUgbWFzaywgdGhleSBhcmUg
bGVmdCB1bmNoYW5nZWQuCiBGaWVsZHMgcmVmZXJlbmNlZCBpbiB0aGUgbWFzaywgYnV0IG5v
dCBwcmVzZW50IGluIHRoZSBpbnB1dCBkb2N1bWVudCwgYXJlCiBkZWxldGVkIGZyb20gdGhl
IGRvY3VtZW50IG9uIHRoZSBzZXJ2ZXIuCiBUaGUgZmllbGQgcGF0aHMgaW4gdGhpcyBtYXNr
IG11c3Qgbm90IGNvbnRhaW4gYSByZXNlcnZlZCBmaWVsZCBuYW1lLgoKDAoFBAACAwYSAzgC
DgoMCgUEAAIDARIDOA8aCgwKBQQAAgMDEgM4HR4K8AEKBAQAAgQSAz8CQhriASBUaGUgdHJh
bnNmb3JtcyB0byBwZXJmb3JtIGFmdGVyIHVwZGF0ZS4KCiBUaGlzIGZpZWxkIGNhbiBiZSBz
ZXQgb25seSB3aGVuIHRoZSBvcGVyYXRpb24gaXMgYHVwZGF0ZWAuIElmIHByZXNlbnQsIHRo
aXMKIHdyaXRlIGlzIGVxdWl2YWxlbnQgdG8gcGVyZm9ybWluZyBgdXBkYXRlYCBhbmQgYHRy
YW5zZm9ybWAgdG8gdGhlIHNhbWUKIGRvY3VtZW50IGF0b21pY2FsbHkgYW5kIGluIG9yZGVy
LgoKDAoFBAACBAQSAz8CCgoMCgUEAAIEBhIDPwsrCgwKBQQAAgQBEgM/LD0KDAoFBAACBAMS
Az9AQQqBAQoEBAACBRIDRAIkGnQgQW4gb3B0aW9uYWwgcHJlY29uZGl0aW9uIG9uIHRoZSBk
b2N1bWVudC4KCiBUaGUgd3JpdGUgd2lsbCBmYWlsIGlmIHRoaXMgaXMgc2V0IGFuZCBub3Qg
bWV0IGJ5IHRoZSB0YXJnZXQgZG9jdW1lbnQuCgoMCgUEAAIFBhIDRAIOCgwKBQQAAgUBEgNE
Dx8KDAoFBAACBQMSA0QiIwouCgIEARIFSACqAQEaISBBIHRyYW5zZm9ybWF0aW9uIG9mIGEg
ZG9jdW1lbnQuCgoKCgMEAQESA0gIGQo9CgQEAQMAEgVKAqEBAxouIEEgdHJhbnNmb3JtYXRp
b24gb2YgYSBmaWVsZCBvZiB0aGUgZG9jdW1lbnQuCgoMCgUEAQMAARIDSgoYCjsKBgQBAwAE
ABIETARUBRorIEEgdmFsdWUgdGhhdCBpcyBjYWxjdWxhdGVkIGJ5IHRoZSBzZXJ2ZXIuCgoO
CgcEAQMABAABEgNMCRQKPAoIBAEDAAQAAgASA04GIxorIFVuc3BlY2lmaWVkLiBUaGlzIHZh
bHVlIG11c3Qgbm90IGJlIHVzZWQuCgoQCgkEAQMABAACAAESA04GHgoQCgkEAQMABAACAAIS
A04hIgrjAQoIBAEDAAQAAgESA1MGFxrRASBUaGUgdGltZSBhdCB3aGljaCB0aGUgc2VydmVy
IHByb2Nlc3NlZCB0aGUgcmVxdWVzdCwgd2l0aCBtaWxsaXNlY29uZAogcHJlY2lzaW9uLiBJ
ZiB1c2VkIG9uIG11bHRpcGxlIGZpZWxkcyAoc2FtZSBvciBkaWZmZXJlbnQgZG9jdW1lbnRz
KSBpbgogYSB0cmFuc2FjdGlvbiwgYWxsIHRoZSBmaWVsZHMgd2lsbCBnZXQgdGhlIHNhbWUg
c2VydmVyIHRpbWVzdGFtcC4KChAKCQQBAwAEAAIBARIDUwYSChAKCQQBAwAEAAIBAhIDUxUW
Co0BCgYEAQMAAgASA1gEGhp+IFRoZSBwYXRoIG9mIHRoZSBmaWVsZC4gU2VlIFtEb2N1bWVu
dC5maWVsZHNdW2dvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5Eb2N1bWVudC5maWVsZHNdIGZv
ciB0aGUgZmllbGQgcGF0aCBzeW50YXgKIHJlZmVyZW5jZS4KCg4KBwQBAwACAAUSA1gECgoO
CgcEAQMAAgABEgNYCxUKDgoHBAEDAAIAAxIDWBgZCjwKBgQBAwAIABIFWwSgAQUaKyBUaGUg
dHJhbnNmb3JtYXRpb24gdG8gYXBwbHkgb24gdGhlIGZpZWxkLgoKDgoHBAEDAAgAARIDWwoY
CjoKBgQBAwACARIDXQYqGisgU2V0cyB0aGUgZmllbGQgdG8gdGhlIGdpdmVuIHNlcnZlciB2
YWx1ZS4KCg4KBwQBAwACAQYSA10GEQoOCgcEAQMAAgEBEgNdEiUKDgoHBAEDAAIBAxIDXSgp
CrwECgYEAQMAAgISA2kGGhqsBCBBZGRzIHRoZSBnaXZlbiB2YWx1ZSB0byB0aGUgZmllbGQn
cyBjdXJyZW50IHZhbHVlLgoKIFRoaXMgbXVzdCBiZSBhbiBpbnRlZ2VyIG9yIGEgZG91Ymxl
IHZhbHVlLgogSWYgdGhlIGZpZWxkIGlzIG5vdCBhbiBpbnRlZ2VyIG9yIGRvdWJsZSwgb3Ig
aWYgdGhlIGZpZWxkIGRvZXMgbm90IHlldAogZXhpc3QsIHRoZSB0cmFuc2Zvcm1hdGlvbiB3
aWxsIHNldCB0aGUgZmllbGQgdG8gdGhlIGdpdmVuIHZhbHVlLgogSWYgZWl0aGVyIG9mIHRo
ZSBnaXZlbiB2YWx1ZSBvciB0aGUgY3VycmVudCBmaWVsZCB2YWx1ZSBhcmUgZG91YmxlcywK
IGJvdGggdmFsdWVzIHdpbGwgYmUgaW50ZXJwcmV0ZWQgYXMgZG91Ymxlcy4gRG91YmxlIGFy
aXRobWV0aWMgYW5kCiByZXByZXNlbnRhdGlvbiBvZiBkb3VibGUgdmFsdWVzIGZvbGxvdyBJ
RUVFIDc1NCBzZW1hbnRpY3MuCiBJZiB0aGVyZSBpcyBwb3NpdGl2ZS9uZWdhdGl2ZSBpbnRl
Z2VyIG92ZXJmbG93LCB0aGUgZmllbGQgaXMgcmVzb2x2ZWQKIHRvIHRoZSBsYXJnZXN0IG1h
Z25pdHVkZSBwb3NpdGl2ZS9uZWdhdGl2ZSBpbnRlZ2VyLgoKDgoHBAEDAAICBhIDaQYLCg4K
BwQBAwACAgESA2kMFQoOCgcEAQMAAgIDEgNpGBkKxwUKBgQBAwACAxIDdwYYGrcFIFNldHMg
dGhlIGZpZWxkIHRvIHRoZSBtYXhpbXVtIG9mIGl0cyBjdXJyZW50IHZhbHVlIGFuZCB0aGUg
Z2l2ZW4gdmFsdWUuCgogVGhpcyBtdXN0IGJlIGFuIGludGVnZXIgb3IgYSBkb3VibGUgdmFs
dWUuCiBJZiB0aGUgZmllbGQgaXMgbm90IGFuIGludGVnZXIgb3IgZG91YmxlLCBvciBpZiB0
aGUgZmllbGQgZG9lcyBub3QgeWV0CiBleGlzdCwgdGhlIHRyYW5zZm9ybWF0aW9uIHdpbGwg
c2V0IHRoZSBmaWVsZCB0byB0aGUgZ2l2ZW4gdmFsdWUuCiBJZiBhIG1heGltdW0gb3BlcmF0
aW9uIGlzIGFwcGxpZWQgd2hlcmUgdGhlIGZpZWxkIGFuZCB0aGUgaW5wdXQgdmFsdWUKIGFy
ZSBvZiBtaXhlZCB0eXBlcyAodGhhdCBpcyAtIG9uZSBpcyBhbiBpbnRlZ2VyIGFuZCBvbmUg
aXMgYSBkb3VibGUpCiB0aGUgZmllbGQgdGFrZXMgb24gdGhlIHR5cGUgb2YgdGhlIGxhcmdl
ciBvcGVyYW5kLiBJZiB0aGUgb3BlcmFuZHMgYXJlCiBlcXVpdmFsZW50IChlLmcuIDMgYW5k
IDMuMCksIHRoZSBmaWVsZCBkb2VzIG5vdCBjaGFuZ2UuCiAwLCAwLjAsIGFuZCAtMC4wIGFy
ZSBhbGwgemVyby4gVGhlIG1heGltdW0gb2YgYSB6ZXJvIHN0b3JlZCB2YWx1ZSBhbmQKIHpl
cm8gaW5wdXQgdmFsdWUgaXMgYWx3YXlzIHRoZSBzdG9yZWQgdmFsdWUuCiBUaGUgbWF4aW11
bSBvZiBhbnkgbnVtZXJpYyB2YWx1ZSB4IGFuZCBOYU4gaXMgTmFOLgoKDgoHBAEDAAIDBhID
dwYLCg4KBwQBAwACAwESA3cMEwoOCgcEAQMAAgMDEgN3FhcKyQUKBgQBAwACBBIEhQEGGBq4
BSBTZXRzIHRoZSBmaWVsZCB0byB0aGUgbWluaW11bSBvZiBpdHMgY3VycmVudCB2YWx1ZSBh
bmQgdGhlIGdpdmVuIHZhbHVlLgoKIFRoaXMgbXVzdCBiZSBhbiBpbnRlZ2VyIG9yIGEgZG91
YmxlIHZhbHVlLgogSWYgdGhlIGZpZWxkIGlzIG5vdCBhbiBpbnRlZ2VyIG9yIGRvdWJsZSwg
b3IgaWYgdGhlIGZpZWxkIGRvZXMgbm90IHlldAogZXhpc3QsIHRoZSB0cmFuc2Zvcm1hdGlv
biB3aWxsIHNldCB0aGUgZmllbGQgdG8gdGhlIGlucHV0IHZhbHVlLgogSWYgYSBtaW5pbXVt
IG9wZXJhdGlvbiBpcyBhcHBsaWVkIHdoZXJlIHRoZSBmaWVsZCBhbmQgdGhlIGlucHV0IHZh
bHVlCiBhcmUgb2YgbWl4ZWQgdHlwZXMgKHRoYXQgaXMgLSBvbmUgaXMgYW4gaW50ZWdlciBh
bmQgb25lIGlzIGEgZG91YmxlKQogdGhlIGZpZWxkIHRha2VzIG9uIHRoZSB0eXBlIG9mIHRo
ZSBzbWFsbGVyIG9wZXJhbmQuIElmIHRoZSBvcGVyYW5kcyBhcmUKIGVxdWl2YWxlbnQgKGUu
Zy4gMyBhbmQgMy4wKSwgdGhlIGZpZWxkIGRvZXMgbm90IGNoYW5nZS4KIDAsIDAuMCwgYW5k
IC0wLjAgYXJlIGFsbCB6ZXJvLiBUaGUgbWluaW11bSBvZiBhIHplcm8gc3RvcmVkIHZhbHVl
IGFuZAogemVybyBpbnB1dCB2YWx1ZSBpcyBhbHdheXMgdGhlIHN0b3JlZCB2YWx1ZS4KIFRo
ZSBtaW5pbXVtIG9mIGFueSBudW1lcmljIHZhbHVlIHggYW5kIE5hTiBpcyBOYU4uCgoPCgcE
AQMAAgQGEgSFAQYLCg8KBwQBAwACBAESBIUBDBMKDwoHBAEDAAIEAxIEhQEWFwqUBAoGBAED
AAIFEgSTAQYtGoMEIEFwcGVuZCB0aGUgZ2l2ZW4gZWxlbWVudHMgaW4gb3JkZXIgaWYgdGhl
eSBhcmUgbm90IGFscmVhZHkgcHJlc2VudCBpbgogdGhlIGN1cnJlbnQgZmllbGQgdmFsdWUu
CiBJZiB0aGUgZmllbGQgaXMgbm90IGFuIGFycmF5LCBvciBpZiB0aGUgZmllbGQgZG9lcyBu
b3QgeWV0IGV4aXN0LCBpdCBpcwogZmlyc3Qgc2V0IHRvIHRoZSBlbXB0eSBhcnJheS4KCiBF
cXVpdmFsZW50IG51bWJlcnMgb2YgZGlmZmVyZW50IHR5cGVzIChlLmcuIDNMIGFuZCAzLjAp
IGFyZQogY29uc2lkZXJlZCBlcXVhbCB3aGVuIGNoZWNraW5nIGlmIGEgdmFsdWUgaXMgbWlz
c2luZy4KIE5hTiBpcyBlcXVhbCB0byBOYU4sIGFuZCBOdWxsIGlzIGVxdWFsIHRvIE51bGwu
CiBJZiB0aGUgaW5wdXQgY29udGFpbnMgbXVsdGlwbGUgZXF1aXZhbGVudCB2YWx1ZXMsIG9u
bHkgdGhlIGZpcnN0IHdpbGwKIGJlIGNvbnNpZGVyZWQuCgogVGhlIGNvcnJlc3BvbmRpbmcg
dHJhbnNmb3JtX3Jlc3VsdCB3aWxsIGJlIHRoZSBudWxsIHZhbHVlLgoKDwoHBAEDAAIFBhIE
kwEGEAoPCgcEAQMAAgUBEgSTAREoCg8KBwQBAwACBQMSBJMBKywK6QMKBgQBAwACBhIEnwEG
KxrYAyBSZW1vdmUgYWxsIG9mIHRoZSBnaXZlbiBlbGVtZW50cyBmcm9tIHRoZSBhcnJheSBp
biB0aGUgZmllbGQuCiBJZiB0aGUgZmllbGQgaXMgbm90IGFuIGFycmF5LCBvciBpZiB0aGUg
ZmllbGQgZG9lcyBub3QgeWV0IGV4aXN0LCBpdCBpcwogc2V0IHRvIHRoZSBlbXB0eSBhcnJh
eS4KCiBFcXVpdmFsZW50IG51bWJlcnMgb2YgdGhlIGRpZmZlcmVudCB0eXBlcyAoZS5nLiAz
TCBhbmQgMy4wKSBhcmUKIGNvbnNpZGVyZWQgZXF1YWwgd2hlbiBkZWNpZGluZyB3aGV0aGVy
IGFuIGVsZW1lbnQgc2hvdWxkIGJlIHJlbW92ZWQuCiBOYU4gaXMgZXF1YWwgdG8gTmFOLCBh
bmQgTnVsbCBpcyBlcXVhbCB0byBOdWxsLgogVGhpcyB3aWxsIHJlbW92ZSBhbGwgZXF1aXZh
bGVudCB2YWx1ZXMgaWYgdGhlcmUgYXJlIGR1cGxpY2F0ZXMuCgogVGhlIGNvcnJlc3BvbmRp
bmcgdHJhbnNmb3JtX3Jlc3VsdCB3aWxsIGJlIHRoZSBudWxsIHZhbHVlLgoKDwoHBAEDAAIG
BhIEnwEGEAoPCgcEAQMAAgYBEgSfAREmCg8KBwQBAwACBgMSBJ8BKSoKNgoEBAECABIEpAEC
FhooIFRoZSBuYW1lIG9mIHRoZSBkb2N1bWVudCB0byB0cmFuc2Zvcm0uCgoNCgUEAQIABRIE
pAECCAoNCgUEAQIAARIEpAEJEQoNCgUEAQIAAxIEpAEUFQp3CgQEAQIBEgSpAQIvGmkgVGhl
IGxpc3Qgb2YgdHJhbnNmb3JtYXRpb25zIHRvIGFwcGx5IHRvIHRoZSBmaWVsZHMgb2YgdGhl
IGRvY3VtZW50LCBpbgogb3JkZXIuCiBUaGlzIG11c3Qgbm90IGJlIGVtcHR5LgoKDQoFBAEC
AQQSBKkBAgoKDQoFBAECAQYSBKkBCxkKDQoFBAECAQESBKkBGioKDQoFBAECAQMSBKkBLS4K
LwoCBAISBq0BALgBARohIFRoZSByZXN1bHQgb2YgYXBwbHlpbmcgYSB3cml0ZS4KCgsKAwQC
ARIErQEIEwrHAQoEBAICABIEswECLBq4ASBUaGUgbGFzdCB1cGRhdGUgdGltZSBvZiB0aGUg
ZG9jdW1lbnQgYWZ0ZXIgYXBwbHlpbmcgdGhlIHdyaXRlLiBOb3Qgc2V0CiBhZnRlciBhIGBk
ZWxldGVgLgoKIElmIHRoZSB3cml0ZSBkaWQgbm90IGFjdHVhbGx5IGNoYW5nZSB0aGUgZG9j
dW1lbnQsIHRoaXMgd2lsbCBiZSB0aGUKIHByZXZpb3VzIHVwZGF0ZV90aW1lLgoKDQoFBAIC
AAYSBLMBAhsKDQoFBAICAAESBLMBHCcKDQoFBAICAAMSBLMBKisKoAEKBAQCAgESBLcBAica
kQEgVGhlIHJlc3VsdHMgb2YgYXBwbHlpbmcgZWFjaCBbRG9jdW1lbnRUcmFuc2Zvcm0uRmll
bGRUcmFuc2Zvcm1dW2dvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5Eb2N1bWVudFRyYW5zZm9y
bS5GaWVsZFRyYW5zZm9ybV0sIGluIHRoZQogc2FtZSBvcmRlci4KCg0KBQQCAgEEEgS3AQIK
Cg0KBQQCAgEGEgS3AQsQCg0KBQQCAgEBEgS3AREiCg0KBQQCAgEDEgS3ASUmCqgDCgIEAxIG
wQEAzAEBGpkDIEEgW0RvY3VtZW50XVtnb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEuRG9jdW1l
bnRdIGhhcyBjaGFuZ2VkLgoKIE1heSBiZSB0aGUgcmVzdWx0IG9mIG11bHRpcGxlIFt3cml0
ZXNdW2dvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5Xcml0ZV0sIGluY2x1ZGluZyBkZWxldGVz
LCB0aGF0CiB1bHRpbWF0ZWx5IHJlc3VsdGVkIGluIGEgbmV3IHZhbHVlIGZvciB0aGUgW0Rv
Y3VtZW50XVtnb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEuRG9jdW1lbnRdLgoKIE11bHRpcGxl
IFtEb2N1bWVudENoYW5nZV1bZ29vZ2xlLmZpcmVzdG9yZS52MWJldGExLkRvY3VtZW50Q2hh
bmdlXSBtZXNzYWdlcyBtYXkgYmUgcmV0dXJuZWQgZm9yIHRoZSBzYW1lIGxvZ2ljYWwKIGNo
YW5nZSwgaWYgbXVsdGlwbGUgdGFyZ2V0cyBhcmUgYWZmZWN0ZWQuCgoLCgMEAwESBMEBCBYK
mQEKBAQDAgASBMUBAhgaigEgVGhlIG5ldyBzdGF0ZSBvZiB0aGUgW0RvY3VtZW50XVtnb29n
bGUuZmlyZXN0b3JlLnYxYmV0YTEuRG9jdW1lbnRdLgoKIElmIGBtYXNrYCBpcyBzZXQsIGNv
bnRhaW5zIG9ubHkgZmllbGRzIHRoYXQgd2VyZSB1cGRhdGVkIG9yIGFkZGVkLgoKDQoFBAMC
AAYSBMUBAgoKDQoFBAMCAAESBMUBCxMKDQoFBAMCAAMSBMUBFhcKSAoEBAMCARIEyAECIBo6
IEEgc2V0IG9mIHRhcmdldCBJRHMgb2YgdGFyZ2V0cyB0aGF0IG1hdGNoIHRoaXMgZG9jdW1l
bnQuCgoNCgUEAwIBBBIEyAECCgoNCgUEAwIBBRIEyAELEAoNCgUEAwIBARIEyAERGwoNCgUE
AwIBAxIEyAEeHwpTCgQEAwICEgTLAQIoGkUgQSBzZXQgb2YgdGFyZ2V0IElEcyBmb3IgdGFy
Z2V0cyB0aGF0IG5vIGxvbmdlciBtYXRjaCB0aGlzIGRvY3VtZW50LgoKDQoFBAMCAgQSBMsB
AgoKDQoFBAMCAgUSBMsBCxAKDQoFBAMCAgESBMsBESMKDQoFBAMCAgMSBMsBJicKmwMKAgQE
EgbVAQDgAQEajAMgQSBbRG9jdW1lbnRdW2dvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5Eb2N1
bWVudF0gaGFzIGJlZW4gZGVsZXRlZC4KCiBNYXkgYmUgdGhlIHJlc3VsdCBvZiBtdWx0aXBs
ZSBbd3JpdGVzXVtnb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEuV3JpdGVdLCBpbmNsdWRpbmcg
dXBkYXRlcywgdGhlCiBsYXN0IG9mIHdoaWNoIGRlbGV0ZWQgdGhlIFtEb2N1bWVudF1bZ29v
Z2xlLmZpcmVzdG9yZS52MWJldGExLkRvY3VtZW50XS4KCiBNdWx0aXBsZSBbRG9jdW1lbnRE
ZWxldGVdW2dvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5Eb2N1bWVudERlbGV0ZV0gbWVzc2Fn
ZXMgbWF5IGJlIHJldHVybmVkIGZvciB0aGUgc2FtZSBsb2dpY2FsCiBkZWxldGUsIGlmIG11
bHRpcGxlIHRhcmdldHMgYXJlIGFmZmVjdGVkLgoKCwoDBAQBEgTVAQgWCmgKBAQEAgASBNcB
AhYaWiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgW0RvY3VtZW50XVtnb29nbGUuZmlyZXN0
b3JlLnYxYmV0YTEuRG9jdW1lbnRdIHRoYXQgd2FzIGRlbGV0ZWQuCgoNCgUEBAIABRIE1wEC
CAoNCgUEBAIAARIE1wEJEQoNCgUEBAIAAxIE1wEUFQpUCgQEBAIBEgTaAQIoGkYgQSBzZXQg
b2YgdGFyZ2V0IElEcyBmb3IgdGFyZ2V0cyB0aGF0IHByZXZpb3VzbHkgbWF0Y2hlZCB0aGlz
IGVudGl0eS4KCg0KBQQEAgEEEgTaAQIKCg0KBQQEAgEFEgTaAQsQCg0KBQQEAgEBEgTaAREj
Cg0KBQQEAgEDEgTaASYnCnsKBAQEAgISBN8BAioabSBUaGUgcmVhZCB0aW1lc3RhbXAgYXQg
d2hpY2ggdGhlIGRlbGV0ZSB3YXMgb2JzZXJ2ZWQuCgogR3JlYXRlciBvciBlcXVhbCB0byB0
aGUgYGNvbW1pdF90aW1lYCBvZiB0aGUgZGVsZXRlLgoKDQoFBAQCAgYSBN8BAhsKDQoFBAQC
AgESBN8BHCUKDQoFBAQCAgMSBN8BKCkK2wMKAgQFEgbqAQD1AQEazAMgQSBbRG9jdW1lbnRd
W2dvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5Eb2N1bWVudF0gaGFzIGJlZW4gcmVtb3ZlZCBm
cm9tIHRoZSB2aWV3IG9mIHRoZSB0YXJnZXRzLgoKIFNlbnQgaWYgdGhlIGRvY3VtZW50IGlz
IG5vIGxvbmdlciByZWxldmFudCB0byBhIHRhcmdldCBhbmQgaXMgb3V0IG9mIHZpZXcuCiBD
YW4gYmUgc2VudCBpbnN0ZWFkIG9mIGEgRG9jdW1lbnREZWxldGUgb3IgYSBEb2N1bWVudENo
YW5nZSBpZiB0aGUgc2VydmVyCiBjYW4gbm90IHNlbmQgdGhlIG5ldyB2YWx1ZSBvZiB0aGUg
ZG9jdW1lbnQuCgogTXVsdGlwbGUgW0RvY3VtZW50UmVtb3ZlXVtnb29nbGUuZmlyZXN0b3Jl
LnYxYmV0YTEuRG9jdW1lbnRSZW1vdmVdIG1lc3NhZ2VzIG1heSBiZSByZXR1cm5lZCBmb3Ig
dGhlIHNhbWUgbG9naWNhbAogd3JpdGUgb3IgZGVsZXRlLCBpZiBtdWx0aXBsZSB0YXJnZXRz
IGFyZSBhZmZlY3RlZC4KCgsKAwQFARIE6gEIFgpxCgQEBQIAEgTsAQIWGmMgVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIFtEb2N1bWVudF1bZ29vZ2xlLmZpcmVzdG9yZS52MWJldGExLkRv
Y3VtZW50XSB0aGF0IGhhcyBnb25lIG91dCBvZiB2aWV3LgoKDQoFBAUCAAUSBOwBAggKDQoF
BAUCAAESBOwBCREKDQoFBAUCAAMSBOwBFBUKVgoEBAUCARIE7wECKBpIIEEgc2V0IG9mIHRh
cmdldCBJRHMgZm9yIHRhcmdldHMgdGhhdCBwcmV2aW91c2x5IG1hdGNoZWQgdGhpcyBkb2N1
bWVudC4KCg0KBQQFAgEEEgTvAQIKCg0KBQQFAgEFEgTvAQsQCg0KBQQFAgEBEgTvAREjCg0K
BQQFAgEDEgTvASYnCokBCgQEBQICEgT0AQIqGnsgVGhlIHJlYWQgdGltZXN0YW1wIGF0IHdo
aWNoIHRoZSByZW1vdmUgd2FzIG9ic2VydmVkLgoKIEdyZWF0ZXIgb3IgZXF1YWwgdG8gdGhl
IGBjb21taXRfdGltZWAgb2YgdGhlIGNoYW5nZS9kZWxldGUvcmVtb3ZlLgoKDQoFBAUCAgYS
BPQBAhsKDQoFBAUCAgESBPQBHCUKDQoFBAUCAgMSBPQBKCkKSAoCBAYSBvgBAIECARo6IEEg
ZGlnZXN0IG9mIGFsbCB0aGUgZG9jdW1lbnRzIHRoYXQgbWF0Y2ggYSBnaXZlbiB0YXJnZXQu
CgoLCgMEBgESBPgBCBcKOwoEBAYCABIE+gECFhotIFRoZSB0YXJnZXQgSUQgdG8gd2hpY2gg
dGhpcyBmaWx0ZXIgYXBwbGllcy4KCg0KBQQGAgAFEgT6AQIHCg0KBQQGAgABEgT6AQgRCg0K
BQQGAgADEgT6ARQVCo4CCgQEBgIBEgSAAgISGv8BIFRoZSB0b3RhbCBjb3VudCBvZiBkb2N1
bWVudHMgdGhhdCBtYXRjaCBbdGFyZ2V0X2lkXVtnb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEu
RXhpc3RlbmNlRmlsdGVyLnRhcmdldF9pZF0uCgogSWYgZGlmZmVyZW50IGZyb20gdGhlIGNv
dW50IG9mIGRvY3VtZW50cyBpbiB0aGUgY2xpZW50IHRoYXQgbWF0Y2gsIHRoZQogY2xpZW50
IG11c3QgbWFudWFsbHkgZGV0ZXJtaW5lIHdoaWNoIGRvY3VtZW50cyBubyBsb25nZXIgbWF0
Y2ggdGhlIHRhcmdldC4KCg0KBQQGAgEFEgSAAgIHCg0KBQQGAgEBEgSAAggNCg0KBQQGAgED
EgSAAhARYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1beta1::Write::Write ===
    # Fields for Write
    # Field: update Type: 11 (.google.firestore.v1beta1.Document)
    # Field: delete Type: 9 ()
    # Field: transform Type: 11 (.google.firestore.v1beta1.DocumentTransform)
    # Field: update_mask Type: 11 (.google.firestore.v1beta1.DocumentMask)
    # Field: update_transforms Type: 11 (.google.firestore.v1beta1.DocumentTransform.FieldTransform)
    # Field: current_document Type: 11 (.google.firestore.v1beta1.Precondition)

# === Message: Google::Firestore::V1beta1::Write::DocumentTransform ===
    # Fields for DocumentTransform
    # Field: document Type: 9 ()
    # Field: field_transforms Type: 11 (.google.firestore.v1beta1.DocumentTransform.FieldTransform)

# === Message: Google::Firestore::V1beta1::Write::WriteResult ===
    # Fields for WriteResult
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: transform_results Type: 11 (.google.firestore.v1beta1.Value)

# === Message: Google::Firestore::V1beta1::Write::DocumentChange ===
    # Fields for DocumentChange
    # Field: document Type: 11 (.google.firestore.v1beta1.Document)
    # Field: target_ids Type: 5 ()
    # Field: removed_target_ids Type: 5 ()

# === Message: Google::Firestore::V1beta1::Write::DocumentDelete ===
    # Fields for DocumentDelete
    # Field: document Type: 9 ()
    # Field: removed_target_ids Type: 5 ()
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::V1beta1::Write::DocumentRemove ===
    # Fields for DocumentRemove
    # Field: document Type: 9 ()
    # Field: removed_target_ids Type: 5 ()
    # Field: read_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::V1beta1::Write::ExistenceFilter ===
    # Fields for ExistenceFilter
    # Field: target_id Type: 5 ()
    # Field: count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1beta1::Write - Compiled Protocol Buffers messages for google/firestore/v1beta1/write.proto

=head1 SYNOPSIS

    use Google::Firestore::V1beta1::Write;

    my $msg = Google::Firestore::V1beta1::Write::Write->new({
        update => $update,
        delete => $delete,
        transform => $transform,
        update_mask => $update_mask,
    });

    # Read or update a field
    my $val = $msg->update();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1beta1::Write::Write->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1beta1/write.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1beta1::Write::Write

A write on a document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update() >> / C<< $msg->update($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Document::Document>)

A document to write.

=item * C<< $msg->delete() >> / C<< $msg->delete($value) >>

Type: C<String>

A document name to delete. In the format:
`projects/{project_id}/databases/{database_id}/documents/{document_path}`.

=item * C<< $msg->transform() >> / C<< $msg->transform($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Write::DocumentTransform>)

Applies a transformation to a document.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Common::DocumentMask>)

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

Type: C<Message> (L<Google::Firestore::V1beta1::Write::DocumentTransform::FieldTransform>)

The transforms to perform after update.

This field can be set only when the operation is `update`. If present, this
write is equivalent to performing `update` and `transform` to the same
document atomically and in order.

=item * C<< $msg->current_document() >> / C<< $msg->current_document($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Common::Precondition>)

An optional precondition on the document.

The write will fail if this is set and not met by the target document.

=back

=head2 Google::Firestore::V1beta1::Write::DocumentTransform

A transformation of a document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<String>

The name of the document to transform.

=item * C<< $msg->field_transforms() >> / C<< $msg->field_transforms($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Write::DocumentTransform::FieldTransform>)

The list of transformations to apply to the fields of the document, in
order.
This must not be empty.

=back

=head2 Google::Firestore::V1beta1::Write::WriteResult

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

Type: C<Message> (L<Google::Firestore::V1beta1::Document::Value>)

The results of applying each [DocumentTransform.FieldTransform][google.firestore.v1beta1.DocumentTransform.FieldTransform], in the
same order.

=back

=head2 Google::Firestore::V1beta1::Write::DocumentChange

A [Document][google.firestore.v1beta1.Document] has changed.

May be the result of multiple [writes][google.firestore.v1beta1.Write], including deletes, that
ultimately resulted in a new value for the [Document][google.firestore.v1beta1.Document].

Multiple [DocumentChange][google.firestore.v1beta1.DocumentChange] messages may be returned for the same logical
change, if multiple targets are affected.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Document::Document>)

The new state of the [Document][google.firestore.v1beta1.Document].

If `mask` is set, contains only fields that were updated or added.

=item * C<< $msg->target_ids() >> / C<< $msg->target_ids($value) >>

Type: C<Int32>

A set of target IDs of targets that match this document.

=item * C<< $msg->removed_target_ids() >> / C<< $msg->removed_target_ids($value) >>

Type: C<Int32>

A set of target IDs for targets that no longer match this document.

=back

=head2 Google::Firestore::V1beta1::Write::DocumentDelete

A [Document][google.firestore.v1beta1.Document] has been deleted.

May be the result of multiple [writes][google.firestore.v1beta1.Write], including updates, the
last of which deleted the [Document][google.firestore.v1beta1.Document].

Multiple [DocumentDelete][google.firestore.v1beta1.DocumentDelete] messages may be returned for the same logical
delete, if multiple targets are affected.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<String>

The resource name of the [Document][google.firestore.v1beta1.Document] that was deleted.

=item * C<< $msg->removed_target_ids() >> / C<< $msg->removed_target_ids($value) >>

Type: C<Int32>

A set of target IDs for targets that previously matched this entity.

=item * C<< $msg->read_time() >> / C<< $msg->read_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The read timestamp at which the delete was observed.

Greater or equal to the `commit_time` of the delete.

=back

=head2 Google::Firestore::V1beta1::Write::DocumentRemove

A [Document][google.firestore.v1beta1.Document] has been removed from the view of the targets.

Sent if the document is no longer relevant to a target and is out of view.
Can be sent instead of a DocumentDelete or a DocumentChange if the server
can not send the new value of the document.

Multiple [DocumentRemove][google.firestore.v1beta1.DocumentRemove] messages may be returned for the same logical
write or delete, if multiple targets are affected.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<String>

The resource name of the [Document][google.firestore.v1beta1.Document] that has gone out of view.

=item * C<< $msg->removed_target_ids() >> / C<< $msg->removed_target_ids($value) >>

Type: C<Int32>

A set of target IDs for targets that previously matched this document.

=item * C<< $msg->read_time() >> / C<< $msg->read_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The read timestamp at which the remove was observed.

Greater or equal to the `commit_time` of the change/delete/remove.

=back

=head2 Google::Firestore::V1beta1::Write::ExistenceFilter

A digest of all the documents that match a given target.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target_id() >> / C<< $msg->target_id($value) >>

Type: C<Int32>

The target ID to which this filter applies.

=item * C<< $msg->count() >> / C<< $msg->count($value) >>

Type: C<Int32>

The total count of documents that match [target_id][google.firestore.v1beta1.ExistenceFilter.target_id].

If different from the count of documents in the client that match, the
client must manually determine which documents no longer match the target.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1beta1::Write::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
