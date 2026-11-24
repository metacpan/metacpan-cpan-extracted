package Google::Cloud::Oracledatabase::V1::OdbDnsZone;

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
CjFnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvb2RiX2Ruc196b25lLnByb3RvEh5n
b29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8i+AQKCk9kYkRuc1pvbmUSFwoEbmFtZRgBIAEoCUID
4EEIUgRuYW1lEh4KBmRvbWFpbhgCIAEoCUIG4EEC4EEFUgZkb21haW4SUwoGbGFiZWxzGAMg
AygLMjYuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLk9kYkRuc1pvbmUuTGFiZWxz
RW50cnlCA+BBAVIGbGFiZWxzEksKBXN0YXRlGAQgASgOMjAuZ29vZ2xlLmNsb3VkLm9yYWNs
ZWRhdGFiYXNlLnYxLk9kYkRuc1pvbmUuU3RhdGVCA+BBA1IFc3RhdGUSQAoLY3JlYXRlX3Rp
bWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUa
OQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVl
OgI4ASJqCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEhAKDFBST1ZJU0lPTklORxAB
Eg0KCUFWQUlMQUJMRRACEgwKCElOQUNUSVZFEAMSDwoLVEVSTUlOQVRJTkcQBBIKCgZGQUlM
RUQQBTqlAepBoQEKKG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL09kYkRuc1pvbmUS
XHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vZGJOZXR3b3Jrcy97
b2RiX25ldHdvcmt9L29kYkRuc1pvbmVzL3tvZGJfZG5zX3pvbmV9KgtvZGJEbnNab25lczIK
b2RiRG5zWm9uZSKOAgoXQ3JlYXRlT2RiRG5zWm9uZVJlcXVlc3QSSAoGcGFyZW50GAEgASgJ
QjDgQQL6QSoSKG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL09kYkRuc1pvbmVSBnBh
cmVudBIqCg9vZGJfZG5zX3pvbmVfaWQYAiABKAlCA+BBAlIMb2RiRG5zWm9uZUlkElEKDG9k
Yl9kbnNfem9uZRgDIAEoCzIqLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5PZGJE
bnNab25lQgPgQQJSCm9kYkRuc1pvbmUSKgoKcmVxdWVzdF9pZBgEIAEoCUIL4ozP1wgCCAHg
QQFSCXJlcXVlc3RJZCKLAQoXRGVsZXRlT2RiRG5zWm9uZVJlcXVlc3QSRAoEbmFtZRgBIAEo
CUIw4EEC+kEqCihvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9PZGJEbnNab25lUgRu
YW1lEioKCnJlcXVlc3RfaWQYAiABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQi5QEKFkxp
c3RPZGJEbnNab25lc1JlcXVlc3QSSAoGcGFyZW50GAEgASgJQjDgQQL6QSoSKG9yYWNsZWRh
dGFiYXNlLmdvb2dsZWFwaXMuY29tL09kYkRuc1pvbmVSBnBhcmVudBIgCglwYWdlX3NpemUY
AiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9r
ZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID4EEB
UgdvcmRlckJ5IrMBChdMaXN0T2RiRG5zWm9uZXNSZXNwb25zZRJOCg1vZGJfZG5zX3pvbmVz
GAEgAygLMiouZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLk9kYkRuc1pvbmVSC29k
YkRuc1pvbmVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1
bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFibGUiXAoUR2V0T2RiRG5zWm9uZVJlcXVlc3QS
RAoEbmFtZRgBIAEoCUIw4EEC+kEqCihvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9P
ZGJEbnNab25lUgRuYW1lItoBChdVcGRhdGVPZGJEbnNab25lUmVxdWVzdBJACgt1cGRhdGVf
bWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFz
axJRCgxvZGJfZG5zX3pvbmUYAiABKAsyKi5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2Uu
djEuT2RiRG5zWm9uZUID4EECUgpvZGJEbnNab25lEioKCnJlcXVlc3RfaWQYAyABKAlCC+KM
z9cIAggB4EEBUglyZXF1ZXN0SWRC6QEKImNvbS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJh
c2UudjFCD09kYkRuc1pvbmVQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL29yYWNsZWRh
dGFiYXNlL2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2ds
ZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFz
ZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURhdGFiYXNlOjpWMUr3PwoHEgUOAOABAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAp
CgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxIDFQAqCgkKAgMEEgMWACkKCAoBCBIDGAA7
CgkKAgglEgMYADsKCAoBCBIDGQBhCgkKAggLEgMZAGEKCAoBCBIDGgAiCgkKAggKEgMaACIK
CAoBCBIDGwAwCgkKAggIEgMbADAKCAoBCBIDHAA7CgkKAggBEgMcADsKCAoBCBIDHQA7CgkK
AggpEgMdADsKCAoBCBIDHgA6CgkKAggtEgMeADoKLQoCBAASBCEAUgEaISBSZXByZXNlbnRz
IE9kYkRuc1pvbmUgcmVzb3VyY2UuCgoKCgMEAAESAyEIEgoLCgMEAAcSBCICJwQKDQoFBAAH
nQgSBCICJwQKPwoEBAAEABIEKgI8AxoxIFRoZSB2YXJpb3VzIGxpZmVjeWNsZSBzdGF0ZXMg
b2YgdGhlIE9kYkRuc1pvbmUuCgoMCgUEAAQAARIDKgcMCisKBgQABAACABIDLAQaGhwgRGVm
YXVsdCB1bnNwZWNpZmllZCB2YWx1ZS4KCg4KBwQABAACAAESAywEFQoOCgcEAAQAAgACEgMs
GBkKSAoGBAAEAAIBEgMvBBUaOSBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4g
YSBwcm92aXNpb25pbmcgc3RhdGUuCgoOCgcEAAQAAgEBEgMvBBAKDgoHBAAEAAIBAhIDLxMU
CkYKBgQABAACAhIDMgQSGjcgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIGFu
IGF2YWlsYWJsZSBzdGF0ZS4KCg4KBwQABAACAgESAzIEDQoOCgcEAAQAAgICEgMyEBEKRwoG
BAAEAAIDEgM1BBEaOCBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgYXZhaWxhYmxl
IGJ1dCBpbmFjdGl2ZS4KCg4KBwQABAACAwESAzUEDAoOCgcEAAQAAgMCEgM1DxAKRwoGBAAE
AAIEEgM4BBQaOCBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4gYSB0ZXJtaW5h
dGluZyBzdGF0ZS4KCg4KBwQABAACBAESAzgEDwoOCgcEAAQAAgQCEgM4EhMKQgoGBAAEAAIF
EgM7BA8aMyBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4gYSBmYWlsZWQgc3Rh
dGUuCgoOCgcEAAQAAgUBEgM7BAoKDgoHBAAEAAIFAhIDOw0OCrYBCgQEAAIAEgNAAj0aqAEg
SWRlbnRpZmllci4gVGhlIG5hbWUgb2YgdGhlIE9kYkRuc1pvbmUgcmVzb3VyY2UgaW4gdGhl
IGZvbGxvd2luZyBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vb2RiTmV0d29ya3Mve29kYl9uZXR3b3JrfS9vZGJEbnNab25lcy97b2RiX2Ruc196
b25lfQoKDAoFBAACAAUSA0ACCAoMCgUEAAIAARIDQAkNCgwKBQQAAgADEgNAEBEKDAoFBAAC
AAgSA0ASPAoPCggEAAIACJwIABIDQBM7ClcKBAQAAgESBEQCRwQaSSBSZXF1aXJlZC4gSW1t
dXRhYmxlLiBUaGUgRE5TIHN1ZmZpeCBmb3IgdGhlIHpvbmUuCiBFeDogYWJjLmV4YW1wbGUu
Y29tLgoKDAoFBAACAQUSA0QCCAoMCgUEAAIBARIDRAkPCgwKBQQAAgEDEgNEEhMKDQoFBAAC
AQgSBEQURwMKDwoIBAACAQicCAASA0UEKgoPCggEAAIBCJwIARIDRgQrCkUKBAQAAgISA0oC
Sho4IE9wdGlvbmFsLiBMYWJlbHMgb3IgdGFncyBhc3NvY2lhdGVkIHdpdGggdGhlIHJlc291
cmNlLgoKDAoFBAACAgYSA0oCFQoMCgUEAAICARIDShYcCgwKBQQAAgIDEgNKHyAKDAoFBAAC
AggSA0ohSQoPCggEAAICCJwIABIDSiJICjQKBAQAAgMSA00CPhonIE91dHB1dCBvbmx5LiBT
dGF0ZSBvZiB0aGUgT2RiRG5zWm9uZS4KCgwKBQQAAgMGEgNNAgcKDAoFBAACAwESA00IDQoM
CgUEAAIDAxIDTRARCgwKBQQAAgMIEgNNEj0KDwoIBAACAwicCAASA00TPApPCgQEAAIEEgRQ
AlEyGkEgT3V0cHV0IG9ubHkuIFRoZSBkYXRlIGFuZCB0aW1lIHRoYXQgdGhlIE9kYkRuc1pv
bmUgd2FzIGNyZWF0ZWQuCgoMCgUEAAIEBhIDUAIbCgwKBQQAAgQBEgNQHCcKDAoFBAACBAMS
A1AqKwoMCgUEAAIECBIDUQYxCg8KCAQAAgQInAgAEgNRBzAKMgoCBAESBFUAdAEaJiBUaGUg
cmVxdWVzdCBmb3IgYE9kYkRuc1pvbmUuQ3JlYXRlYC4KCgoKAwQBARIDVQgfCpsBCgQEAQIA
EgRYAl0EGowBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHZhbHVlIGZvciB0aGUgT2RiRG5zWm9u
ZSBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9vZGJOZXR3b3Jrcy97b2RiX25ldHdvcmt9LgoKDAoFBAECAAUSA1gC
CAoMCgUEAQIAARIDWAkPCgwKBQQBAgADEgNYEhMKDQoFBAECAAgSBFgUXQMKDwoIBAECAAic
CAASA1kEKgoPCgcEAQIACJ8IEgRaBFwFCvgBCgQEAQIBEgNjAkYa6gEgUmVxdWlyZWQuIFRo
ZSBJRCBvZiB0aGUgT2RiRG5zWm9uZSB0byBjcmVhdGUuIFRoaXMgdmFsdWUgaXMgcmVzdHJp
Y3RlZAogdG8gKF5bYS16XShbYS16MC05LV17MCw2MX1bYS16MC05XSk/JCkgYW5kIG11c3Qg
YmUgYSBtYXhpbXVtIG9mIDYzCiBjaGFyYWN0ZXJzIGluIGxlbmd0aC4gVGhlIHZhbHVlIG11
c3Qgc3RhcnQgd2l0aCBhIGxldHRlciBhbmQgZW5kIHdpdGgKIGEgbGV0dGVyIG9yIGEgbnVt
YmVyLgoKDAoFBAECAQUSA2MCCAoMCgUEAQIBARIDYwkYCgwKBQQBAgEDEgNjGxwKDAoFBAEC
AQgSA2MdRQoPCggEAQIBCJwIABIDYx5ECkYKBAQBAgISA2YCRxo5IFJlcXVpcmVkLiBEZXRh
aWxzIG9mIHRoZSBPZGJEbnNab25lIGluc3RhbmNlIHRvIGNyZWF0ZS4KCgwKBQQBAgIGEgNm
AgwKDAoFBAECAgESA2YNGQoMCgUEAQICAxIDZhwdCgwKBQQBAgIIEgNmHkYKDwoIBAECAgic
CAASA2YfRQrVAwoEBAECAxIEcAJzBBrGAyBPcHRpb25hbC4gQW4gb3B0aW9uYWwgSUQgdG8g
aWRlbnRpZnkgdGhlIHJlcXVlc3QuIFRoaXMgdmFsdWUgaXMgdXNlZCB0bwogaWRlbnRpZnkg
ZHVwbGljYXRlIHJlcXVlc3RzLiBJZiB5b3UgbWFrZSBhIHJlcXVlc3Qgd2l0aCB0aGUgc2Ft
ZSByZXF1ZXN0IElECiBhbmQgdGhlIG9yaWdpbmFsIHJlcXVlc3QgaXMgc3RpbGwgaW4gcHJv
Z3Jlc3Mgb3IgY29tcGxldGVkLCB0aGUgc2VydmVyCiBpZ25vcmVzIHRoZSBzZWNvbmQgcmVx
dWVzdC4gVGhpcyBwcmV2ZW50cyBjbGllbnRzIGZyb20KIGFjY2lkZW50YWxseSBjcmVhdGlu
ZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZh
bGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3Vw
cG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDAoFBAEC
AwUSA3ACCAoMCgUEAQIDARIDcAkTCgwKBQQBAgMDEgNwFhcKDQoFBAECAwgSBHAYcwMKEgoL
BAECAwjM8fmKAQESA3EEKgoPCggEAQIDCJwIABIDcgQqCjMKAgQCEgV3AI0BARomIFRoZSBy
ZXF1ZXN0IGZvciBgT2RiRG5zWm9uZS5EZWxldGVgLgoKCgoDBAIBEgN3CB8KqwEKBAQCAgAS
BHoCfwQanAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSByZXNvdXJjZSBpbiB0aGUgZm9s
bG93aW5nIGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9vZGJOZXR3b3Jrcy97b2RiX25ldHdvcmt9L29kYkRuc1pvbmVzL3tvZGJfZG5zX3pvbmV9
LgoKDAoFBAICAAUSA3oCCAoMCgUEAgIAARIDegkNCgwKBQQCAgADEgN6EBEKDQoFBAICAAgS
BHoSfwMKDwoIBAICAAicCAASA3sEKgoPCgcEAgIACJ8IEgR8BH4FCtcDCgQEAgIBEgaJAQKM
AQQaxgMgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIElEIHRvIGlkZW50aWZ5IHRoZSByZXF1ZXN0
LiBUaGlzIHZhbHVlIGlzIHVzZWQgdG8KIGlkZW50aWZ5IGR1cGxpY2F0ZSByZXF1ZXN0cy4g
SWYgeW91IG1ha2UgYSByZXF1ZXN0IHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogYW5kIHRo
ZSBvcmlnaW5hbCByZXF1ZXN0IGlzIHN0aWxsIGluIHByb2dyZXNzIG9yIGNvbXBsZXRlZCwg
dGhlIHNlcnZlcgogaWdub3JlcyB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMg
Y2xpZW50cyBmcm9tCiBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1l
bnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4
Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAw
MC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQCAgEFEgSJAQIICg0KBQQCAgEBEgSJ
AQkTCg0KBQQCAgEDEgSJARYXCg8KBQQCAgEIEgaJARiMAQMKEwoLBAICAQjM8fmKAQESBIoB
BCoKEAoIBAICAQicCAASBIsBBCoKMgoCBAMSBpABAKcBARokIFRoZSByZXF1ZXN0IGZvciBg
T2RiRG5zWm9uZS5MaXN0YC4KCgsKAwQDARIEkAEIHgqdAQoEBAMCABIGkwECmAEEGowBIFJl
cXVpcmVkLiBUaGUgcGFyZW50IHZhbHVlIGZvciB0aGUgT2RiRG5zWm9uZSBpbiB0aGUgZm9s
bG93aW5nIGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9vZGJOZXR3b3Jrcy97b2RiX25ldHdvcmt9LgoKDQoFBAMCAAUSBJMBAggKDQoFBAMCAAES
BJMBCQ8KDQoFBAMCAAMSBJMBEhMKDwoFBAMCAAgSBpMBFJgBAwoQCggEAwIACJwIABIElAEE
KgoRCgcEAwIACJ8IEgaVAQSXAQUKwgEKBAQDAgESBJ0BAj8aswEgT3B0aW9uYWwuIFRoZSBt
YXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4uCiBJZiB1bnNwZWNpZmllZCwgYXQg
bW9zdCA1MCBPZGJEbnNab25lcyB3aWxsIGJlIHJldHVybmVkLgogVGhlIG1heGltdW0gdmFs
dWUgaXMgMTAwMDsgdmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAu
CgoNCgUEAwIBBRIEnQECBwoNCgUEAwIBARIEnQEIEQoNCgUEAwIBAxIEnQEUFQoNCgUEAwIB
CBIEnQEWPgoQCggEAwIBCJwIABIEnQEXPQpZCgQEAwICEgSgAQJBGksgT3B0aW9uYWwuIEEg
dG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQg
cmV0dXJuLgoKDQoFBAMCAgUSBKABAggKDQoFBAMCAgESBKABCRMKDQoFBAMCAgMSBKABFhcK
DQoFBAMCAggSBKABGEAKEAoIBAMCAgicCAASBKABGT8KUQoEBAMCAxIEowECPRpDIE9wdGlv
bmFsLiBBbiBleHByZXNzaW9uIGZvciBmaWx0ZXJpbmcgdGhlIHJlc3VsdHMgb2YgdGhlIHJl
cXVlc3QuCgoNCgUEAwIDBRIEowECCAoNCgUEAwIDARIEowEJDwoNCgUEAwIDAxIEowESEwoN
CgUEAwIDCBIEowEUPAoQCggEAwIDCJwIABIEowEVOwpQCgQEAwIEEgSmAQI/GkIgT3B0aW9u
YWwuIEFuIGV4cHJlc3Npb24gZm9yIG9yZGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1
ZXN0LgoKDQoFBAMCBAUSBKYBAggKDQoFBAMCBAESBKYBCREKDQoFBAMCBAMSBKYBFBUKDQoF
BAMCBAgSBKYBFj4KEAoIBAMCBAicCAASBKYBFz0KMwoCBAQSBqoBALQBARolIFRoZSByZXNw
b25zZSBmb3IgYE9kYkRuc1pvbmUuTGlzdGAuCgoLCgMEBAESBKoBCB8KKAoEBAQCABIErAEC
KBoaIFRoZSBsaXN0IG9mIE9kYkRuc1pvbmVzLgoKDQoFBAQCAAQSBKwBAgoKDQoFBAQCAAYS
BKwBCxUKDQoFBAQCAAESBKwBFiMKDQoFBAQCAAMSBKwBJicKTwoEBAQCARIErwECHRpBIEEg
dG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQg
cmV0dXJuLgoKDQoFBAQCAQUSBK8BAggKDQoFBAQCAQESBK8BCRgKDQoFBAQCAQMSBK8BGxwK
bwoEBAQCAhIEswECIhphIFVucmVhY2hhYmxlIGxvY2F0aW9ucyB3aGVuIGxpc3RpbmcgcmVz
b3VyY2VzIGFjcm9zcyBhbGwgbG9jYXRpb25zIHVzaW5nCiB3aWxkY2FyZCBsb2NhdGlvbiAn
LScuCgoNCgUEBAICBBIEswECCgoNCgUEBAICBRIEswELEQoNCgUEBAICARIEswESHQoNCgUE
BAICAxIEswEgIQoxCgIEBRIGtwEAwAEBGiMgVGhlIHJlcXVlc3QgZm9yIGBPZGJEbnNab25l
LkdldGAuCgoLCgMEBQESBLcBCBwKrwEKBAQFAgASBroBAr8BBBqeASBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlIE9kYkRuc1pvbmUgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vb2RiTmV0d29ya3Mve29kYl9u
ZXR3b3JrfS9vZGJEbnNab25lcy97b2RiX2Ruc196b25lfS4KCg0KBQQFAgAFEgS6AQIICg0K
BQQFAgABEgS6AQkNCg0KBQQFAgADEgS6ARARCg8KBQQFAgAIEga6ARK/AQMKEAoIBAUCAAic
CAASBLsBBCoKEQoHBAUCAAifCBIGvAEEvgEFCjQKAgQGEgbDAQDgAQEaJiBUaGUgcmVxdWVz
dCBmb3IgYE9kYkRuc1pvbmUuVXBkYXRlYC4KCgsKAwQGARIEwwEIHwr3AgoEBAYCABIGyQEC
ygEvGuYCIE9wdGlvbmFsLiBBIG1hc2sgc3BlY2lmeWluZyB3aGljaCBmaWVsZHMgaW4gdGhl
IE9kYkRuc1pvbmUgc2hvdWxkIGJlCiB1cGRhdGVkLiBBIGZpZWxkIHNwZWNpZmllZCBpbiB0
aGUgbWFzayBpcyB1cGRhdGVkLiBJZiBhIG1hc2sgaXNuJ3QKIHByb3ZpZGVkLCB0aGUgc2Vy
dmljZSB0cmVhdHMgdGhpcyBhcyBhbiBpbXBsaWVkIGZpZWxkIG1hc2sgZXF1aXZhbGVudCB0
bwogYWxsIGZpZWxkcyB0aGF0IGFyZSBwb3B1bGF0ZWQgKGhhdmUgYSBub24tZW1wdHkgdmFs
dWUpLiBUbyBjbGVhciBvciB1bnNldCBhCiBmaWVsZCwgdGhlIGZpZWxkIG11c3QgYmUgZXhw
bGljaXRseSBzcGVjaWZpZWQgaW4gdGhlIGB1cGRhdGVfbWFza2AuCgoNCgUEBgIABhIEyQEC
GwoNCgUEBgIAARIEyQEcJwoNCgUEBgIAAxIEyQEqKwoNCgUEBgIACBIEygEGLgoQCggEBgIA
CJwIABIEygEHLQqwAwoEBAYCARIE0gECRxqhAyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGJl
aW5nIHVwZGF0ZWQuIE5vdGUgb25seSBsYWJlbHMgY2FuIGJlIHVwZGF0ZWQuCiBUaGUgcHJv
dmlkZWQgbGFiZWxzIHdpbGwgY29tcGxldGVseSByZXBsYWNlIHRoZSBleGlzdGluZyBsYWJl
bHMuCiBBbnkgZXhpc3RpbmcgbGFiZWwga2V5cyB0aGF0IGFyZSBub3QgaW5jbHVkZWQgaW4g
dGhlIHVwZGF0ZSByZXF1ZXN0IHdpbGwgYmUKIGRlbGV0ZWQuIE5vdCBwcm92aWRpbmcgbGFi
ZWxzIGFuZCB1cGRhdGVfbWFzayB3aWxsIG5vdCB1cGRhdGUgdGhlIGxhYmVscy4KIFRvIGNs
ZWFyIGFsbCBsYWJlbHMsIHNwZWNpZnkgYGxhYmVsc2AgaW4gdGhlIGB1cGRhdGVfbWFza2Ag
YW5kIG9taXQgb3IKIGxlYXZlIHRoZSBgbGFiZWxzYCBmaWVsZCBlbXB0eSBpbiB0aGUgdXBk
YXRlIHJlcXVlc3QuCgoNCgUEBgIBBhIE0gECDAoNCgUEBgIBARIE0gENGQoNCgUEBgIBAxIE
0gEcHQoNCgUEBgIBCBIE0gEeRgoQCggEBgIBCJwIABIE0gEfRQrXAwoEBAYCAhIG3AEC3wEE
GsYDIE9wdGlvbmFsLiBBbiBvcHRpb25hbCBJRCB0byBpZGVudGlmeSB0aGUgcmVxdWVzdC4g
VGhpcyB2YWx1ZSBpcyB1c2VkIHRvCiBpZGVudGlmeSBkdXBsaWNhdGUgcmVxdWVzdHMuIElm
IHlvdSBtYWtlIGEgcmVxdWVzdCB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIGFuZCB0aGUg
b3JpZ2luYWwgcmVxdWVzdCBpcyBzdGlsbCBpbiBwcm9ncmVzcyBvciBjb21wbGV0ZWQsIHRo
ZSBzZXJ2ZXIKIGlnbm9yZXMgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzIGNs
aWVudHMgZnJvbQogYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50
cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNl
cHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAt
MDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBgICBRIE3AECCAoNCgUEBgICARIE3AEJ
EwoNCgUEBgICAxIE3AEWFwoPCgUEBgICCBIG3AEY3wEDChMKCwQGAgIIzPH5igEBEgTdAQQq
ChAKCAQGAgIInAgAEgTeAQQqYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone ===
    # Fields for OdbDnsZone
    # Field: name Type: 9 ()
    # Field: domain Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.OdbDnsZone.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.OdbDnsZone.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# Enum: OdbDnsZone::State
our $OdbDnsZone_STATE_UNSPECIFIED = 0;
our $OdbDnsZone_PROVISIONING = 1;
our $OdbDnsZone_AVAILABLE = 2;
our $OdbDnsZone_INACTIVE = 3;
our $OdbDnsZone_TERMINATING = 4;
our $OdbDnsZone_FAILED = 5;

# === Message: Google::Cloud::Oracledatabase::V1::OdbDnsZone::CreateOdbDnsZoneRequest ===
    # Fields for CreateOdbDnsZoneRequest
    # Field: parent Type: 9 ()
    # Field: odb_dns_zone_id Type: 9 ()
    # Field: odb_dns_zone Type: 11 (.google.cloud.oracledatabase.v1.OdbDnsZone)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbDnsZone::DeleteOdbDnsZoneRequest ===
    # Fields for DeleteOdbDnsZoneRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesRequest ===
    # Fields for ListOdbDnsZonesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesResponse ===
    # Fields for ListOdbDnsZonesResponse
    # Field: odb_dns_zones Type: 11 (.google.cloud.oracledatabase.v1.OdbDnsZone)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbDnsZone::GetOdbDnsZoneRequest ===
    # Fields for GetOdbDnsZoneRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbDnsZone::UpdateOdbDnsZoneRequest ===
    # Fields for UpdateOdbDnsZoneRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: odb_dns_zone Type: 11 (.google.cloud.oracledatabase.v1.OdbDnsZone)
    # Field: request_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::OdbDnsZone - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/odb_dns_zone.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::OdbDnsZone;

    my $msg = Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone->new({
        name => $name,
        domain => $domain,
        labels => $labels,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/odb_dns_zone.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone

Represents OdbDnsZone resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the OdbDnsZone resource in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbDnsZones/{odb_dns_zone}

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<String>

Required. Immutable. The DNS suffix for the zone.
Ex: abc.example.com.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone::LabelsEntry>)

Optional. Labels or tags associated with the resource.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::OdbDnsZone::State>)

Output only. State of the OdbDnsZone.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the OdbDnsZone was created.

=back

=head3 Enum: OdbDnsZone::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<INACTIVE> => C<3>

=item * C<TERMINATING> => C<4>

=item * C<FAILED> => C<5>

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbDnsZone::CreateOdbDnsZoneRequest

The request for `OdbDnsZone.Create`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the OdbDnsZone in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}.

=item * C<< $msg->odb_dns_zone_id() >> / C<< $msg->odb_dns_zone_id($value) >>

Type: C<String>

Required. The ID of the OdbDnsZone to create. This value is restricted
to (^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$) and must be a maximum of 63
characters in length. The value must start with a letter and end with
a letter or a number.

=item * C<< $msg->odb_dns_zone() >> / C<< $msg->odb_dns_zone($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone>)

Required. Details of the OdbDnsZone instance to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbDnsZone::DeleteOdbDnsZoneRequest

The request for `OdbDnsZone.Delete`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the resource in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbDnsZones/{odb_dns_zone}.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesRequest

The request for `OdbDnsZone.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the OdbDnsZone in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, at most 50 OdbDnsZones will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression for ordering the results of the request.

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesResponse

The response for `OdbDnsZone.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->odb_dns_zones() >> / C<< $msg->odb_dns_zones($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone>)

The list of OdbDnsZones.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable locations when listing resources across all locations using
wildcard location '-'.

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbDnsZone::GetOdbDnsZoneRequest

The request for `OdbDnsZone.Get`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the OdbDnsZone in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbDnsZones/{odb_dns_zone}.

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbDnsZone::UpdateOdbDnsZoneRequest

The request for `OdbDnsZone.Update`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. A mask specifying which fields in the OdbDnsZone should be
updated. A field specified in the mask is updated. If a mask isn't
provided, the service treats this as an implied field mask equivalent to
all fields that are populated (have a non-empty value). To clear or unset a
field, the field must be explicitly specified in the `update_mask`.

=item * C<< $msg->odb_dns_zone() >> / C<< $msg->odb_dns_zone($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone>)

Required. The resource being updated. Note only labels can be updated.
The provided labels will completely replace the existing labels.
Any existing label keys that are not included in the update request will be
deleted. Not providing labels and update_mask will not update the labels.
To clear all labels, specify `labels` in the `update_mask` and omit or
leave the `labels` field empty in the update request.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::OdbDnsZone::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
