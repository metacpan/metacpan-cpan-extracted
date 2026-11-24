package Google::Monitoring::V3::SnoozeService;

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
    eval { require Google::Monitoring::V3::Snooze };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvbW9uaXRvcmluZy92My9zbm9vemVfc2VydmljZS5wcm90bxIUZ29vZ2xlLm1v
bml0b3JpbmcudjMaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkv
Y2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGiFnb29nbGUvbW9uaXRvcmluZy92My9zbm9vemUucHJvdG8a
IGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIpIBChNDcmVhdGVTbm9vemVSZXF1
ZXN0EkAKBnBhcmVudBgBIAEoCUIo4EEC+kEiEiBtb25pdG9yaW5nLmdvb2dsZWFwaXMuY29t
L1Nub296ZVIGcGFyZW50EjkKBnNub296ZRgCIAEoCzIcLmdvb2dsZS5tb25pdG9yaW5nLnYz
LlNub296ZUID4EECUgZzbm9vemUiuQEKEkxpc3RTbm9vemVzUmVxdWVzdBJACgZwYXJlbnQY
ASABKAlCKOBBAvpBIhIgbW9uaXRvcmluZy5nb29nbGVhcGlzLmNvbS9Tbm9vemVSBnBhcmVu
dBIbCgZmaWx0ZXIYAiABKAlCA+BBAVIGZmlsdGVyEiAKCXBhZ2Vfc2l6ZRgEIAEoBUID4EEB
UghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAUgASgJQgPgQQFSCXBhZ2VUb2tlbiJ1ChNMaXN0
U25vb3plc1Jlc3BvbnNlEjYKB3Nub296ZXMYASADKAsyHC5nb29nbGUubW9uaXRvcmluZy52
My5Tbm9vemVSB3Nub296ZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuIlAKEEdldFNub296ZVJlcXVlc3QSPAoEbmFtZRgBIAEoCUIo4EEC+kEiCiBtb25pdG9y
aW5nLmdvb2dsZWFwaXMuY29tL1Nub296ZVIEbmFtZSKSAQoTVXBkYXRlU25vb3plUmVxdWVz
dBI5CgZzbm9vemUYASABKAsyHC5nb29nbGUubW9uaXRvcmluZy52My5Tbm9vemVCA+BBAlIG
c25vb3plEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFz
a0ID4EECUgp1cGRhdGVNYXNrMpgGCg1Tbm9vemVTZXJ2aWNlEpgBCgxDcmVhdGVTbm9vemUS
KS5nb29nbGUubW9uaXRvcmluZy52My5DcmVhdGVTbm9vemVSZXF1ZXN0GhwuZ29vZ2xlLm1v
bml0b3JpbmcudjMuU25vb3plIj+C0+STAikiHy92My97cGFyZW50PXByb2plY3RzLyp9L3Nu
b296ZXM6BnNub296ZdpBDXBhcmVudCxzbm9vemUSlAEKC0xpc3RTbm9vemVzEiguZ29vZ2xl
Lm1vbml0b3JpbmcudjMuTGlzdFNub296ZXNSZXF1ZXN0GikuZ29vZ2xlLm1vbml0b3Jpbmcu
djMuTGlzdFNub296ZXNSZXNwb25zZSIwgtPkkwIhEh8vdjMve3BhcmVudD1wcm9qZWN0cy8q
fS9zbm9vemVz2kEGcGFyZW50EoEBCglHZXRTbm9vemUSJi5nb29nbGUubW9uaXRvcmluZy52
My5HZXRTbm9vemVSZXF1ZXN0GhwuZ29vZ2xlLm1vbml0b3JpbmcudjMuU25vb3plIi6C0+ST
AiESHy92My97bmFtZT1wcm9qZWN0cy8qL3Nub296ZXMvKn3aQQRuYW1lEqQBCgxVcGRhdGVT
bm9vemUSKS5nb29nbGUubW9uaXRvcmluZy52My5VcGRhdGVTbm9vemVSZXF1ZXN0GhwuZ29v
Z2xlLm1vbml0b3JpbmcudjMuU25vb3plIkuC0+STAjAyJi92My97c25vb3plLm5hbWU9cHJv
amVjdHMvKi9zbm9vemVzLyp9OgZzbm9vemXaQRJzbm9vemUsdXBkYXRlX21hc2saqQHKQRlt
b25pdG9yaW5nLmdvb2dsZWFwaXMuY29t0kGJAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29t
L2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9t
b25pdG9yaW5nLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvbW9uaXRvcmluZy5y
ZWFkQs0BChhjb20uZ29vZ2xlLm1vbml0b3JpbmcudjNCElNub296ZVNlcnZpY2VQcm90b1AB
WkFjbG91ZC5nb29nbGUuY29tL2dvL21vbml0b3JpbmcvYXBpdjMvdjIvbW9uaXRvcmluZ3Bi
O21vbml0b3JpbmdwYqoCGkdvb2dsZS5DbG91ZC5Nb25pdG9yaW5nLlYzygIaR29vZ2xlXENs
b3VkXE1vbml0b3JpbmdcVjPqAh1Hb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpWM0qvNAoH
EgUOAM8BAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHQoJ
CgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACsK
CQoCAwUSAxcAKgoICgEIEgMZADcKCQoCCCUSAxkANwoICgEIEgMaAFgKCQoCCAsSAxoAWAoI
CgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADMKCQoCCAgSAxwAMwoICgEIEgMdADEKCQoC
CAESAx0AMQoICgEIEgMeADcKCQoCCCkSAx4ANwoICgEIEgMfADYKCQoCCC0SAx8ANgrxAQoC
BgASBCQAUAEa5AEgVGhlIFNub296ZVNlcnZpY2UgQVBJIGlzIHVzZWQgdG8gdGVtcG9yYXJp
bHkgcHJldmVudCBhbiBhbGVydCBwb2xpY3kgZnJvbQogZ2VuZXJhdGluZyBhbGVydHMuIEEg
U25vb3plIGlzIGEgZGVzY3JpcHRpb24gb2YgdGhlIGNyaXRlcmlhIHVuZGVyIHdoaWNoIG9u
ZQogb3IgbW9yZSBhbGVydCBwb2xpY2llcyBzaG91bGQgbm90IGZpcmUgYWxlcnRzIGZvciB0
aGUgc3BlY2lmaWVkIGR1cmF0aW9uLgoKCgoDBgABEgMkCBUKCgoDBgADEgMlAkEKDAoFBgAD
mQgSAyUCQQoLCgMGAAMSBCYCKTgKDQoFBgADmggSBCYCKTgKqAEKBAYAAgASBC4CNAMamQEg
Q3JlYXRlcyBhIGBTbm9vemVgIHRoYXQgd2lsbCBwcmV2ZW50IGFsZXJ0cywgd2hpY2ggbWF0
Y2ggdGhlIHByb3ZpZGVkCiBjcml0ZXJpYSwgZnJvbSBiZWluZyBvcGVuZWQuIFRoZSBgU25v
b3plYCBhcHBsaWVzIGZvciBhIHNwZWNpZmljIHRpbWUKIGludGVydmFsLgoKDAoFBgACAAES
Ay4GEgoMCgUGAAIAAhIDLhMmCgwKBQYAAgADEgMuMTcKDQoFBgACAAQSBC8EMgYKEQoJBgAC
AASwyrwiEgQvBDIGCgwKBQYAAgAEEgMzBDsKDwoIBgACAASbCAASAzMEOwqQAQoEBgACARIE
OAI9AxqBASBMaXN0cyB0aGUgYFNub296ZWBzIGFzc29jaWF0ZWQgd2l0aCBhIHByb2plY3Qu
IENhbiBvcHRpb25hbGx5IHBhc3MgaW4KIGBmaWx0ZXJgLCB3aGljaCBzcGVjaWZpZXMgcHJl
ZGljYXRlcyB0byBtYXRjaCBgU25vb3plYHMuCgoMCgUGAAIBARIDOAYRCgwKBQYAAgECEgM4
EiQKDAoFBgACAQMSAzgvQgoNCgUGAAIBBBIEOQQ7BgoRCgkGAAIBBLDKvCISBDkEOwYKDAoF
BgACAQQSAzwENAoPCggGAAIBBJsIABIDPAQ0Ci8KBAYAAgISBEACRQMaISBSZXRyaWV2ZXMg
YSBgU25vb3plYCBieSBgbmFtZWAuCgoMCgUGAAICARIDQAYPCgwKBQYAAgICEgNAECAKDAoF
BgACAgMSA0ArMQoNCgUGAAICBBIEQQRDBgoRCgkGAAICBLDKvCISBEEEQwYKDAoFBgACAgQS
A0QEMgoPCggGAAICBJsIABIDRAQyCnAKBAYAAgMSBEkCTwMaYiBVcGRhdGVzIGEgYFNub296
ZWAsIGlkZW50aWZpZWQgYnkgaXRzIGBuYW1lYCwgd2l0aCB0aGUgcGFyYW1ldGVycyBpbiB0
aGUKIGdpdmVuIGBTbm9vemVgIG9iamVjdC4KCgwKBQYAAgMBEgNJBhIKDAoFBgACAwISA0kT
JgoMCgUGAAIDAxIDSTE3Cg0KBQYAAgMEEgRKBE0GChEKCQYAAgMEsMq8IhIESgRNBgoMCgUG
AAIDBBIDTgRACg8KCAYAAgMEmwgAEgNOBEAKowEKAgQAEgRUAGQBGpYBIFRoZSBtZXNzYWdl
IGRlZmluaXRpb24gZm9yIGNyZWF0aW5nIGEgYFNub296ZWAuIFVzZXJzIG11c3QgcHJvdmlk
ZSB0aGUgYm9keQogb2YgdGhlIGBTbm9vemVgIHRvIGJlIGNyZWF0ZWQgYnV0IG11c3Qgb21p
dCB0aGUgYFNub296ZWAgZmllbGQsIGBuYW1lYC4KCgoKAwQAARIDVAgbCr8BCgQEAAIAEgRa
Al8EGrABIFJlcXVpcmVkLiBUaGUKIFtwcm9qZWN0XShodHRwczovL2Nsb3VkLmdvb2dsZS5j
b20vbW9uaXRvcmluZy9hcGkvdjMjcHJvamVjdF9uYW1lKSBpbiB3aGljaAogYSBgU25vb3pl
YCBzaG91bGQgYmUgY3JlYXRlZC4gVGhlIGZvcm1hdCBpczoKCiAgICAgcHJvamVjdHMvW1BS
T0pFQ1RfSURfT1JfTlVNQkVSXQoKDAoFBAACAAUSA1oCCAoMCgUEAAIAARIDWgkPCgwKBQQA
AgADEgNaEhMKDQoFBAACAAgSBFoUXwMKDwoIBAACAAicCAASA1sEKgoPCgcEAAIACJ8IEgRc
BF4FCmwKBAQAAgESA2MCPRpfIFJlcXVpcmVkLiBUaGUgYFNub296ZWAgdG8gY3JlYXRlLiBP
bWl0IHRoZSBgbmFtZWAgZmllbGQsIGFzIGl0IHdpbGwgYmUKIGZpbGxlZCBpbiBieSB0aGUg
QVBJLgoKDAoFBAACAQYSA2MCCAoMCgUEAAIBARIDYwkPCgwKBQQAAgEDEgNjEhMKDAoFBAAC
AQgSA2MUPAoPCggEAAIBCJwIABIDYxU7CoIBCgIEARIFaACLAQEadSBUaGUgbWVzc2FnZSBk
ZWZpbml0aW9uIGZvciBsaXN0aW5nIGBTbm9vemVgcyBhc3NvY2lhdGVkIHdpdGggdGhlIGdp
dmVuCiBgcGFyZW50YCwgc2F0aXNmeWluZyB0aGUgb3B0aW9uYWwgYGZpbHRlcmAuCgoKCgME
AQESA2gIGgq6AQoEBAECABIEbgJzBBqrASBSZXF1aXJlZC4gVGhlCiBbcHJvamVjdF0oaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL21vbml0b3JpbmcvYXBpL3YzI3Byb2plY3RfbmFtZSkg
d2hvc2UKIGBTbm9vemVgcyBzaG91bGQgYmUgbGlzdGVkLiBUaGUgZm9ybWF0IGlzOgoKICAg
ICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdCgoMCgUEAQIABRIDbgIICgwKBQQB
AgABEgNuCQ8KDAoFBAECAAMSA24SEwoNCgUEAQIACBIEbhRzAwoPCggEAQIACJwIABIDbwQq
Cg8KBwQBAgAInwgSBHAEcgUKsgIKBAQBAgESA38CPRqkAiBPcHRpb25hbC4gT3B0aW9uYWwg
ZmlsdGVyIHRvIHJlc3RyaWN0IHJlc3VsdHMgdG8gdGhlIGdpdmVuIGNyaXRlcmlhLiBUaGUK
IGZvbGxvd2luZyBmaWVsZHMgYXJlIHN1cHBvcnRlZC4KCiAgICogYGludGVydmFsLnN0YXJ0
X3RpbWVgCiAgICogYGludGVydmFsLmVuZF90aW1lYAoKIEZvciBleGFtcGxlOgoKICAgICBp
bnRlcnZhbC5zdGFydF90aW1lID4gIjIwMjItMDMtMTFUMDA6MDA6MDAtMDg6MDAiIEFORAog
ICAgICAgICBpbnRlcnZhbC5lbmRfdGltZSA8ICIyMDIyLTAzLTEyVDAwOjAwOjAwLTA4OjAw
IgoKDAoFBAECAQUSA38CCAoMCgUEAQIBARIDfwkPCgwKBQQBAgEDEgN/EhMKDAoFBAECAQgS
A38UPAoPCggEAQIBCJwIABIDfxU7CscCCgQEAQICEgSGAQI/GrgCIE9wdGlvbmFsLiBUaGUg
bWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1cm4gZm9yIGEgc2luZ2xlIHF1ZXJ5
LiBUaGUKIHNlcnZlciBtYXkgZnVydGhlciBjb25zdHJhaW4gdGhlIG1heGltdW0gbnVtYmVy
IG9mIHJlc3VsdHMgcmV0dXJuZWQgaW4gYQogc2luZ2xlIHBhZ2UuIFRoZSB2YWx1ZSBzaG91
bGQgYmUgaW4gdGhlIHJhbmdlIFsxLCAxMDAwXS4gSWYgdGhlIHZhbHVlIGdpdmVuCiBpcyBv
dXRzaWRlIHRoaXMgcmFuZ2UsIHRoZSBzZXJ2ZXIgd2lsbCBkZWNpZGUgdGhlIG51bWJlciBv
ZiByZXN1bHRzIHRvIGJlCiByZXR1cm5lZC4KCg0KBQQBAgIFEgSGAQIHCg0KBQQBAgIBEgSG
AQgRCg0KBQQBAgIDEgSGARQVCg0KBQQBAgIIEgSGARY+ChAKCAQBAgIInAgAEgSGARc9Cn4K
BAQBAgMSBIoBAkEacCBPcHRpb25hbC4gVGhlIGBuZXh0X3BhZ2VfdG9rZW5gIGZyb20gYSBw
cmV2aW91cyBjYWxsIHRvCiBgTGlzdFNub296ZXNSZXF1ZXN0YCB0byBnZXQgdGhlIG5leHQg
cGFnZSBvZiByZXN1bHRzLgoKDQoFBAECAwUSBIoBAggKDQoFBAECAwESBIoBCRMKDQoFBAEC
AwMSBIoBFhcKDQoFBAECAwgSBIoBGEAKEAoIBAECAwicCAASBIoBGT8KYwoCBAISBo8BAJYB
ARpVIFRoZSByZXN1bHRzIG9mIGEgc3VjY2Vzc2Z1bCBgTGlzdFNub296ZXNgIGNhbGwsIGNv
bnRhaW5pbmcgdGhlIG1hdGNoaW5nCiBgU25vb3plYHMuCgoLCgMEAgESBI8BCBsKMgoEBAIC
ABIEkQECHhokIGBTbm9vemVgcyBtYXRjaGluZyB0aGlzIGxpc3QgY2FsbC4KCg0KBQQCAgAE
EgSRAQIKCg0KBQQCAgAGEgSRAQsRCg0KBQQCAgABEgSRARIZCg0KBQQCAgADEgSRARwdCp0B
CgQEAgIBEgSVAQIdGo4BIFBhZ2UgdG9rZW4gZm9yIHJlcGVhdGVkIGNhbGxzIHRvIGBMaXN0
U25vb3plc2AsIHRvIGZldGNoIGFkZGl0aW9uYWwgcGFnZXMKIG9mIHJlc3VsdHMuIElmIHRo
aXMgaXMgZW1wdHkgb3IgbWlzc2luZywgdGhlcmUgYXJlIG5vIG1vcmUgcGFnZXMuCgoNCgUE
AgIBBRIElQECCAoNCgUEAgIBARIElQEJGAoNCgUEAgIBAxIElQEbHAqHAQoCBAMSBpoBAKQB
ARp5IFRoZSBtZXNzYWdlIGRlZmluaXRpb24gZm9yIHJldHJpZXZpbmcgYSBgU25vb3plYC4g
VXNlcnMgbXVzdCBzcGVjaWZ5IHRoZQogZmllbGQsIGBuYW1lYCwgd2hpY2ggaWRlbnRpZmll
cyB0aGUgYFNub296ZWAuCgoLCgMEAwESBJoBCBgKiAEKBAQDAgASBp4BAqMBBBp4IFJlcXVp
cmVkLiBUaGUgSUQgb2YgdGhlIGBTbm9vemVgIHRvIHJldHJpZXZlLiBUaGUgZm9ybWF0IGlz
OgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL3Nub296ZXMvW1NOT09a
RV9JRF0KCg0KBQQDAgAFEgSeAQIICg0KBQQDAgABEgSeAQkNCg0KBQQDAgADEgSeARARCg8K
BQQDAgAIEgaeARKjAQMKEAoIBAMCAAicCAASBJ8BBCoKEQoHBAMCAAifCBIGoAEEogEFCoIF
CgIEBBIGswEAzwEBGvMEIFRoZSBtZXNzYWdlIGRlZmluaXRpb24gZm9yIHVwZGF0aW5nIGEg
YFNub296ZWAuIFRoZSBmaWVsZCwgYHNub296ZS5uYW1lYAogaWRlbnRpZmllcyB0aGUgYFNu
b296ZWAgdG8gYmUgdXBkYXRlZC4gVGhlIHJlbWFpbmRlciBvZiBgc25vb3plYCBnaXZlcyB0
aGUKIGNvbnRlbnQgdGhlIGBTbm9vemVgIGluIHF1ZXN0aW9uIHdpbGwgYmUgYXNzaWduZWQu
CgogV2hhdCBmaWVsZHMgY2FuIGJlIHVwZGF0ZWQgZGVwZW5kcyBvbiB0aGUgc3RhcnQgdGlt
ZSBhbmQgZW5kIHRpbWUgb2YgdGhlCiBgU25vb3plYC4KCiAgICogZW5kIHRpbWUgaXMgaW4g
dGhlIHBhc3Q6IFRoZXNlIGBTbm9vemVgcyBhcmUgY29uc2lkZXJlZAogICAgIHJlYWQtb25s
eSBhbmQgY2Fubm90IGJlIHVwZGF0ZWQuCiAgICogc3RhcnQgdGltZSBpcyBpbiB0aGUgcGFz
dCBhbmQgZW5kIHRpbWUgaXMgaW4gdGhlIGZ1dHVyZTogYGRpc3BsYXlfbmFtZWAKICAgICBh
bmQgYGludGVydmFsLmVuZF90aW1lYCBjYW4gYmUgdXBkYXRlZC4KICAgKiBzdGFydCB0aW1l
IGlzIGluIHRoZSBmdXR1cmU6IGBkaXNwbGF5X25hbWVgLCBgaW50ZXJ2YWwuc3RhcnRfdGlt
ZWAgYW5kCiAgICAgYGludGVydmFsLmVuZF90aW1lYCBjYW4gYmUgdXBkYXRlZC4KCgsKAwQE
ARIEswEIGwpTCgQEBAIAEgS1AQI9GkUgUmVxdWlyZWQuIFRoZSBgU25vb3plYCB0byB1cGRh
dGUuIE11c3QgaGF2ZSB0aGUgbmFtZSBmaWVsZCBwcmVzZW50LgoKDQoFBAQCAAYSBLUBAggK
DQoFBAQCAAESBLUBCQ8KDQoFBAQCAAMSBLUBEhMKDQoFBAQCAAgSBLUBFDwKEAoIBAQCAAic
CAASBLUBFTsK+AYKBAQEAgESBs0BAs4BLxrnBiBSZXF1aXJlZC4gVGhlIGZpZWxkcyB0byB1
cGRhdGUuCgogRm9yIGVhY2ggZmllbGQgbGlzdGVkIGluIGB1cGRhdGVfbWFza2A6CgogICAq
IElmIHRoZSBgU25vb3plYCBvYmplY3Qgc3VwcGxpZWQgaW4gdGhlIGBVcGRhdGVTbm9vemVS
ZXF1ZXN0YCBoYXMgYQogICAgIHZhbHVlIGZvciB0aGF0IGZpZWxkLCB0aGUgdmFsdWUgb2Yg
dGhlIGZpZWxkIGluIHRoZSBleGlzdGluZyBgU25vb3plYAogICAgIHdpbGwgYmUgc2V0IHRv
IHRoZSB2YWx1ZSBvZiB0aGUgZmllbGQgaW4gdGhlIHN1cHBsaWVkIGBTbm9vemVgLgogICAq
IElmIHRoZSBmaWVsZCBkb2VzIG5vdCBoYXZlIGEgdmFsdWUgaW4gdGhlIHN1cHBsaWVkIGBT
bm9vemVgLCB0aGUgZmllbGQKICAgICBpbiB0aGUgZXhpc3RpbmcgYFNub296ZWAgaXMgc2V0
IHRvIGl0cyBkZWZhdWx0IHZhbHVlLgoKIEZpZWxkcyBub3QgbGlzdGVkIHJldGFpbiB0aGVp
ciBleGlzdGluZyB2YWx1ZS4KCiBUaGUgZm9sbG93aW5nIGFyZSB0aGUgZmllbGQgbmFtZXMg
dGhhdCBhcmUgYWNjZXB0ZWQgaW4gYHVwZGF0ZV9tYXNrYDoKCiAgICogYGRpc3BsYXlfbmFt
ZWAKICAgKiBgaW50ZXJ2YWwuc3RhcnRfdGltZWAKICAgKiBgaW50ZXJ2YWwuZW5kX3RpbWVg
CgogVGhhdCBzYWlkLCB0aGUgc3RhcnQgdGltZSBhbmQgZW5kIHRpbWUgb2YgdGhlIGBTbm9v
emVgIGRldGVybWluZXMgd2hpY2gKIGZpZWxkcyBjYW4gbGVnYWxseSBiZSB1cGRhdGVkLiBC
ZWZvcmUgYXR0ZW1wdGluZyBhbiB1cGRhdGUsIHVzZXJzIHNob3VsZAogY29uc3VsdCB0aGUg
ZG9jdW1lbnRhdGlvbiBmb3IgYFVwZGF0ZVNub296ZVJlcXVlc3RgLCB3aGljaCB0YWxrcyBh
Ym91dAogd2hpY2ggZmllbGRzIGNhbiBiZSB1cGRhdGVkLgoKDQoFBAQCAQYSBM0BAhsKDQoF
BAQCAQESBM0BHCcKDQoFBAQCAQMSBM0BKisKDQoFBAQCAQgSBM4BBi4KEAoIBAQCAQicCAAS
BM4BBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest ===
    # Fields for CreateSnoozeRequest
    # Field: parent Type: 9 ()
    # Field: snooze Type: 11 (.google.monitoring.v3.Snooze)

# === Message: Google::Monitoring::V3::SnoozeService::ListSnoozesRequest ===
    # Fields for ListSnoozesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::V3::SnoozeService::ListSnoozesResponse ===
    # Fields for ListSnoozesResponse
    # Field: snoozes Type: 11 (.google.monitoring.v3.Snooze)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Monitoring::V3::SnoozeService::GetSnoozeRequest ===
    # Fields for GetSnoozeRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::SnoozeService::UpdateSnoozeRequest ===
    # Fields for UpdateSnoozeRequest
    # Field: snooze Type: 11 (.google.monitoring.v3.Snooze)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Monitoring::V3::SnoozeService::SnoozeServiceClient ===
package Google::Monitoring::V3::SnoozeService::SnoozeServiceClient;

=pod

=head2 Service Client: Google::Monitoring::V3::SnoozeService::SnoozeServiceClient

Client stub representing the remote C<SnoozeService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<monitoring.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'monitoring.googleapis.com:443' );

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

sub create_snooze {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.SnoozeService',
        method         => 'CreateSnooze',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Snooze::Snooze',
    });
}

sub list_snoozes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::SnoozeService::ListSnoozesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.SnoozeService',
        method         => 'ListSnoozes',
        request        => $req,
        response_class => 'Google::Monitoring::V3::SnoozeService::ListSnoozesResponse',
    });
}

sub get_snooze {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::SnoozeService::GetSnoozeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.SnoozeService',
        method         => 'GetSnooze',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Snooze::Snooze',
    });
}

sub update_snooze {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::SnoozeService::UpdateSnoozeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.SnoozeService',
        method         => 'UpdateSnooze',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Snooze::Snooze',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::SnoozeService - Compiled Protocol Buffers messages for google/monitoring/v3/snooze_service.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::SnoozeService;

    my $msg = Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest->new({
        parent => $parent,
        snooze => $snooze,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/snooze_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest

The message definition for creating a `Snooze`. Users must provide the body
of the `Snooze` to be created but must omit the `Snooze` field, `name`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) in which
a `Snooze` should be created. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

=item * C<< $msg->snooze() >> / C<< $msg->snooze($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Snooze::Snooze>)

Required. The `Snooze` to create. Omit the `name` field, as it will be
filled in by the API.

=back

=head2 Google::Monitoring::V3::SnoozeService::ListSnoozesRequest

The message definition for listing `Snooze`s associated with the given
`parent`, satisfying the optional `filter`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The
[project](https://cloud.google.com/monitoring/api/v3#project_name) whose
`Snooze`s should be listed. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Optional filter to restrict results to the given criteria. The
following fields are supported.

  * `interval.start_time`
  * `interval.end_time`

For example:

    interval.start_time > "2022-03-11T00:00:00-08:00" AND
        interval.end_time < "2022-03-12T00:00:00-08:00"

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of results to return for a single query. The
server may further constrain the maximum number of results returned in a
single page. The value should be in the range [1, 1000]. If the value given
is outside this range, the server will decide the number of results to be
returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The `next_page_token` from a previous call to
`ListSnoozesRequest` to get the next page of results.

=back

=head2 Google::Monitoring::V3::SnoozeService::ListSnoozesResponse

The results of a successful `ListSnoozes` call, containing the matching
`Snooze`s.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->snoozes() >> / C<< $msg->snoozes($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Snooze::Snooze>)

`Snooze`s matching this list call.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token for repeated calls to `ListSnoozes`, to fetch additional pages
of results. If this is empty or missing, there are no more pages.

=back

=head2 Google::Monitoring::V3::SnoozeService::GetSnoozeRequest

The message definition for retrieving a `Snooze`. Users must specify the
field, `name`, which identifies the `Snooze`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The ID of the `Snooze` to retrieve. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/snoozes/[SNOOZE_ID]

=back

=head2 Google::Monitoring::V3::SnoozeService::UpdateSnoozeRequest

The message definition for updating a `Snooze`. The field, `snooze.name`
identifies the `Snooze` to be updated. The remainder of `snooze` gives the
content the `Snooze` in question will be assigned.

What fields can be updated depends on the start time and end time of the
`Snooze`.

  * end time is in the past: These `Snooze`s are considered
    read-only and cannot be updated.
  * start time is in the past and end time is in the future: `display_name`
    and `interval.end_time` can be updated.
  * start time is in the future: `display_name`, `interval.start_time` and
    `interval.end_time` can be updated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->snooze() >> / C<< $msg->snooze($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Snooze::Snooze>)

Required. The `Snooze` to update. Must have the name field present.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The fields to update.

For each field listed in `update_mask`:

  * If the `Snooze` object supplied in the `UpdateSnoozeRequest` has a
    value for that field, the value of the field in the existing `Snooze`
    will be set to the value of the field in the supplied `Snooze`.
  * If the field does not have a value in the supplied `Snooze`, the field
    in the existing `Snooze` is set to its default value.

Fields not listed retain their existing value.

The following are the field names that are accepted in `update_mask`:

  * `display_name`
  * `interval.start_time`
  * `interval.end_time`

That said, the start time and end time of the `Snooze` determines which
fields can legally be updated. Before attempting an update, users should
consult the documentation for `UpdateSnoozeRequest`, which talks about
which fields can be updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::SnoozeService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
