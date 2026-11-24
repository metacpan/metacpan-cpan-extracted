package Google::Cloud::Support::V2::CaseService;

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
    eval { require Google::Cloud::Support::V2::Case };
    eval { require Google::Cloud::Support::V2::Escalation };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9jYXNlX3NlcnZpY2UucHJvdG8SF2dvb2dsZS5j
bG91ZC5zdXBwb3J0LnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxoiZ29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjIvY2FzZS5w
cm90bxooZ29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjIvZXNjYWxhdGlvbi5wcm90bxogZ29vZ2xl
L3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8iTgoOR2V0Q2FzZVJlcXVlc3QSPAoEbmFtZRgB
IAEoCUIo4EEC+kEiCiBjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vQ2FzZVIEbmFtZSKN
AQoRQ3JlYXRlQ2FzZVJlcXVlc3QSQAoGcGFyZW50GAEgASgJQijgQQL6QSISIGNsb3Vkc3Vw
cG9ydC5nb29nbGVhcGlzLmNvbS9DYXNlUgZwYXJlbnQSNgoEY2FzZRgCIAEoCzIdLmdvb2ds
ZS5jbG91ZC5zdXBwb3J0LnYyLkNhc2VCA+BBAlIEY2FzZSKoAQoQTGlzdENhc2VzUmVxdWVz
dBJACgZwYXJlbnQYASABKAlCKOBBAvpBIhIgY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29t
L0Nhc2VSBnBhcmVudBIWCgZmaWx0ZXIYAiABKAlSBmZpbHRlchIbCglwYWdlX3NpemUYBCAB
KAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YBSABKAlSCXBhZ2VUb2tlbiJwChFMaXN0Q2Fz
ZXNSZXNwb25zZRIzCgVjYXNlcxgBIAMoCzIdLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkNh
c2VSBWNhc2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJ+ChJT
ZWFyY2hDYXNlc1JlcXVlc3QSFgoGcGFyZW50GAQgASgJUgZwYXJlbnQSFAoFcXVlcnkYASAB
KAlSBXF1ZXJ5EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgD
IAEoCVIJcGFnZVRva2VuInIKE1NlYXJjaENhc2VzUmVzcG9uc2USMwoFY2FzZXMYASADKAsy
HS5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5DYXNlUgVjYXNlcxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4imAEKE0VzY2FsYXRlQ2FzZVJlcXVlc3QSPAoEbmFt
ZRgBIAEoCUIo4EEC+kEiCiBjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vQ2FzZVIEbmFt
ZRJDCgplc2NhbGF0aW9uGAIgASgLMiMuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIuRXNjYWxh
dGlvblIKZXNjYWxhdGlvbiKIAQoRVXBkYXRlQ2FzZVJlcXVlc3QSNgoEY2FzZRgBIAEoCzId
Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkNhc2VCA+BBAlIEY2FzZRI7Cgt1cGRhdGVfbWFz
axgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siUAoQQ2xv
c2VDYXNlUmVxdWVzdBI8CgRuYW1lGAEgASgJQijgQQL6QSIKIGNsb3Vkc3VwcG9ydC5nb29n
bGVhcGlzLmNvbS9DYXNlUgRuYW1lInQKIFNlYXJjaENhc2VDbGFzc2lmaWNhdGlvbnNSZXF1
ZXN0EhQKBXF1ZXJ5GAEgASgJUgVxdWVyeRIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXpl
Eh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKrAQohU2VhcmNoQ2FzZUNsYXNzaWZp
Y2F0aW9uc1Jlc3BvbnNlEl4KFGNhc2VfY2xhc3NpZmljYXRpb25zGAEgAygLMisuZ29vZ2xl
LmNsb3VkLnN1cHBvcnQudjIuQ2FzZUNsYXNzaWZpY2F0aW9uUhNjYXNlQ2xhc3NpZmljYXRp
b25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbjLPDAoLQ2FzZVNl
cnZpY2USpQEKB0dldENhc2USJy5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5HZXRDYXNlUmVx
dWVzdBodLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkNhc2UiUoLT5JMCRRIdL3YyL3tuYW1l
PXByb2plY3RzLyovY2FzZXMvKn1aJBIiL3YyL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9jYXNl
cy8qfdpBBG5hbWUSuAEKCUxpc3RDYXNlcxIpLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkxp
c3RDYXNlc1JlcXVlc3QaKi5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5MaXN0Q2FzZXNSZXNw
b25zZSJUgtPkkwJFEh0vdjIve3BhcmVudD1wcm9qZWN0cy8qfS9jYXNlc1okEiIvdjIve3Bh
cmVudD1vcmdhbml6YXRpb25zLyp9L2Nhc2Vz2kEGcGFyZW50EsMBCgtTZWFyY2hDYXNlcxIr
Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLlNlYXJjaENhc2VzUmVxdWVzdBosLmdvb2dsZS5j
bG91ZC5zdXBwb3J0LnYyLlNlYXJjaENhc2VzUmVzcG9uc2UiWYLT5JMCUxIkL3YyL3twYXJl
bnQ9cHJvamVjdHMvKn0vY2FzZXM6c2VhcmNoWisSKS92Mi97cGFyZW50PW9yZ2FuaXphdGlv
bnMvKn0vY2FzZXM6c2VhcmNoEr4BCgpDcmVhdGVDYXNlEiouZ29vZ2xlLmNsb3VkLnN1cHBv
cnQudjIuQ3JlYXRlQ2FzZVJlcXVlc3QaHS5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5DYXNl
ImWC0+STAlEiHS92Mi97cGFyZW50PXByb2plY3RzLyp9L2Nhc2VzOgRjYXNlWioiIi92Mi97
cGFyZW50PW9yZ2FuaXphdGlvbnMvKn0vY2FzZXM6BGNhc2XaQQtwYXJlbnQsY2FzZRLNAQoK
VXBkYXRlQ2FzZRIqLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLlVwZGF0ZUNhc2VSZXF1ZXN0
Gh0uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIuQ2FzZSJ0gtPkkwJbMiIvdjIve2Nhc2UubmFt
ZT1wcm9qZWN0cy8qL2Nhc2VzLyp9OgRjYXNlWi8yJy92Mi97Y2FzZS5uYW1lPW9yZ2FuaXph
dGlvbnMvKi9jYXNlcy8qfToEY2FzZdpBEGNhc2UsdXBkYXRlX21hc2sSwAEKDEVzY2FsYXRl
Q2FzZRIsLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkVzY2FsYXRlQ2FzZVJlcXVlc3QaHS5n
b29nbGUuY2xvdWQuc3VwcG9ydC52Mi5DYXNlImOC0+STAl0iJi92Mi97bmFtZT1wcm9qZWN0
cy8qL2Nhc2VzLyp9OmVzY2FsYXRlOgEqWjAiKy92Mi97bmFtZT1vcmdhbml6YXRpb25zLyov
Y2FzZXMvKn06ZXNjYWxhdGU6ASoStAEKCUNsb3NlQ2FzZRIpLmdvb2dsZS5jbG91ZC5zdXBw
b3J0LnYyLkNsb3NlQ2FzZVJlcXVlc3QaHS5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5DYXNl
Il2C0+STAlciIy92Mi97bmFtZT1wcm9qZWN0cy8qL2Nhc2VzLyp9OmNsb3NlOgEqWi0iKC92
Mi97bmFtZT1vcmdhbml6YXRpb25zLyovY2FzZXMvKn06Y2xvc2U6ASoSugEKGVNlYXJjaENh
c2VDbGFzc2lmaWNhdGlvbnMSOS5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5TZWFyY2hDYXNl
Q2xhc3NpZmljYXRpb25zUmVxdWVzdBo6Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLlNlYXJj
aENhc2VDbGFzc2lmaWNhdGlvbnNSZXNwb25zZSImgtPkkwIgEh4vdjIvY2FzZUNsYXNzaWZp
Y2F0aW9uczpzZWFyY2gaT8pBG2Nsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbdJBLmh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CuQEKG2NvbS5nb29n
bGUuY2xvdWQuc3VwcG9ydC52MkIQQ2FzZVNlcnZpY2VQcm90b1ABWjVjbG91ZC5nb29nbGUu
Y29tL2dvL3N1cHBvcnQvYXBpdjIvc3VwcG9ydHBiO3N1cHBvcnRwYqoCF0dvb2dsZS5DbG91
ZC5TdXBwb3J0LlYyygIXR29vZ2xlXENsb3VkXFN1cHBvcnRcVjLqAhpHb29nbGU6OkNsb3Vk
OjpTdXBwb3J0OjpWMkqCVgoHEgUOAO4CAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgID
AxIDFQAjCgkKAgMEEgMWACwKCQoCAwUSAxcAMgoJCgIDBhIDGAAqCggKAQgSAxoANAoJCgII
JRIDGgA0CggKAQgSAxsATAoJCgIICxIDGwBMCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgS
Ax0AMQoJCgIICBIDHQAxCggKAQgSAx4ANAoJCgIIARIDHgA0CggKAQgSAx8ANAoJCgIIKRID
HwA0CggKAQgSAyAAMwoJCgIILRIDIAAzCj4KAgYAEgUjAJIBARoxIEEgc2VydmljZSB0byBt
YW5hZ2UgR29vZ2xlIENsb3VkIHN1cHBvcnQgY2FzZXMuCgoKCgMGAAESAyMIEwoKCgMGAAMS
AyQCQwoMCgUGAAOZCBIDJAJDCgsKAwYAAxIEJQImNwoNCgUGAAOaCBIEJQImNwogCgQGAAIA
EgQpAi8DGhIgUmV0cmlldmUgYSBjYXNlLgoKDAoFBgACAAESAykGDQoMCgUGAAIAAhIDKQ4c
CgwKBQYAAgADEgMpJysKDQoFBgACAAQSBCoELQYKEQoJBgACAASwyrwiEgQqBC0GCgwKBQYA
AgAEEgMuBDIKDwoIBgACAASbCAASAy4EMgqUAgoEBgACARIENgI8AxqFAiBSZXRyaWV2ZSBh
bGwgY2FzZXMgdW5kZXIgYSBwYXJlbnQsIGJ1dCBub3QgaXRzIGNoaWxkcmVuLgoKIEZvciBl
eGFtcGxlLCBsaXN0aW5nIGNhc2VzIHVuZGVyIGFuIG9yZ2FuaXphdGlvbiBvbmx5IHJldHVy
bnMgdGhlIGNhc2VzCiB0aGF0IGFyZSBkaXJlY3RseSBwYXJlbnRlZCBieSB0aGF0IG9yZ2Fu
aXphdGlvbi4gVG8gcmV0cmlldmUgY2FzZXMKIHVuZGVyIGFuIG9yZ2FuaXphdGlvbiBhbmQg
aXRzIHByb2plY3RzLCB1c2UgYGNhc2VzLnNlYXJjaGAuCgoMCgUGAAIBARIDNgYPCgwKBQYA
AgECEgM2ECAKDAoFBgACAQMSAzYrPAoNCgUGAAIBBBIENwQ6BgoRCgkGAAIBBLDKvCISBDcE
OgYKDAoFBgACAQQSAzsENAoPCggGAAIBBJsIABIDOwQ0Ci8KBAYAAgISBD8CRAMaISBTZWFy
Y2ggZm9yIGNhc2VzIHVzaW5nIGEgcXVlcnkuCgoMCgUGAAICARIDPwYRCgwKBQYAAgICEgM/
EiQKDAoFBgACAgMSAz8vQgoNCgUGAAICBBIEQARDBgoRCgkGAAICBLDKvCISBEAEQwYKkQIK
BAYAAgMSBEsCVQMaggIgQ3JlYXRlIGEgbmV3IGNhc2UgYW5kIGFzc29jaWF0ZSBpdCB3aXRo
IGEgcGFyZW50LgoKIEl0IG11c3QgaGF2ZSB0aGUgZm9sbG93aW5nIGZpZWxkcyBzZXQ6IGBk
aXNwbGF5X25hbWVgLCBgZGVzY3JpcHRpb25gLAogYGNsYXNzaWZpY2F0aW9uYCwgYW5kIGBw
cmlvcml0eWAuIElmIHlvdSdyZSBqdXN0IHRlc3RpbmcgdGhlIEFQSSBhbmQgZG9uJ3QKIHdh
bnQgdG8gcm91dGUgeW91ciBjYXNlIHRvIGFuIGFnZW50LCBzZXQgYHRlc3RDYXNlPXRydWVg
LgoKDAoFBgACAwESA0sGEAoMCgUGAAIDAhIDSxEiCgwKBQYAAgMDEgNLLTEKDQoFBgACAwQS
BEwEUwYKEQoJBgACAwSwyrwiEgRMBFMGCgwKBQYAAgMEEgNUBDkKDwoIBgACAwSbCAASA1QE
OQo/CgQGAAIEEgRYAmIDGjEgVXBkYXRlIGEgY2FzZS4gT25seSBzb21lIGZpZWxkcyBjYW4g
YmUgdXBkYXRlZC4KCgwKBQYAAgQBEgNYBhAKDAoFBgACBAISA1gRIgoMCgUGAAIEAxIDWC0x
Cg0KBQYAAgQEEgRZBGAGChEKCQYAAgQEsMq8IhIEWQRgBgoMCgUGAAIEBBIDYQQ+Cg8KCAYA
AgQEmwgAEgNhBD4KtAIKBAYAAgUSBGsCdAMapQIgRXNjYWxhdGUgYSBjYXNlLCBzdGFydGlu
ZyB0aGUgR29vZ2xlIENsb3VkIFN1cHBvcnQgZXNjYWxhdGlvbiBtYW5hZ2VtZW50CiBwcm9j
ZXNzLgoKIFRoaXMgb3BlcmF0aW9uIGlzIG9ubHkgYXZhaWxhYmxlIGZvciBzb21lIHN1cHBv
cnQgc2VydmljZXMuIEdvIHRvCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vc3VwcG9ydCBh
bmQgbG9vayBmb3IgJ1RlY2huaWNhbCBzdXBwb3J0CiBlc2NhbGF0aW9ucycgaW4gdGhlIGZl
YXR1cmUgbGlzdCB0byBmaW5kIG91dCB3aGljaCBvbmVzIGxldCB5b3UKIGRvIHRoYXQuCgoM
CgUGAAIFARIDawYSCgwKBQYAAgUCEgNrEyYKDAoFBgACBQMSA2sxNQoNCgUGAAIFBBIEbARz
BgoRCgkGAAIFBLDKvCISBGwEcwYKHgoEBgACBhIFdwKAAQMaDyBDbG9zZSBhIGNhc2UuCgoM
CgUGAAIGARIDdwYPCgwKBQYAAgYCEgN3ECAKDAoFBgACBgMSA3crLwoNCgUGAAIGBBIEeAR/
BgoRCgkGAAIGBLDKvCISBHgEfwYKjAQKBAYAAgcSBowBApEBAxr7AyBSZXRyaWV2ZSB2YWxp
ZCBjbGFzc2lmaWNhdGlvbnMgdG8gdXNlIHdoZW4gY3JlYXRpbmcgYSBzdXBwb3J0IGNhc2Uu
CgogQ2xhc3NpZmljYXRpb25zIGFyZSBoaWVyYXJjaGljYWwuIEVhY2ggY2xhc3NpZmljYXRp
b24gaXMgYSBzdHJpbmcKIGNvbnRhaW5pbmcgYWxsIGxldmVscyBvZiB0aGUgaGllcmFyY2h5
IHNlcGFyYXRlZCBieSBgIiA+ICJgLiBGb3IgZXhhbXBsZSwKIGAiVGVjaG5pY2FsIElzc3Vl
ID4gQ29tcHV0ZSA+IENvbXB1dGUgRW5naW5lImAuCgogQ2xhc3NpZmljYXRpb24gSURzIHJl
dHVybmVkIGJ5IHRoaXMgZW5kcG9pbnQgYXJlIHZhbGlkIGZvciBhdCBsZWFzdCBzaXgKIG1v
bnRocy4gV2hlbiBhIGNsYXNzaWZpY2F0aW9uIGlzIGRlYWN0aXZhdGVkLCB0aGlzIGVuZHBv
aW50IGltbWVkaWF0ZWx5CiBzdG9wcyByZXR1cm5pbmcgaXQuIEFmdGVyIHNpeCBtb250aHMs
IGBjYXNlLmNyZWF0ZWAgcmVxdWVzdHMgdXNpbmcgdGhlCiBjbGFzc2lmaWNhdGlvbiB3aWxs
IGZhaWwuCgoNCgUGAAIHARIEjAEGHwoNCgUGAAIHAhIEjAEgQAoNCgUGAAIHAxIEjQEPMAoP
CgUGAAIHBBIGjgEEkAEGChMKCQYAAgcEsMq8IhIGjgEEkAEGCj0KAgQAEgaVAQCdAQEaLyBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgR2V0Q2FzZSBlbmRwb2ludC4KCgsKAwQAARIE
lQEIFgpECgQEAAIAEgaXAQKcAQQaNCBSZXF1aXJlZC4gVGhlIGZ1bGwgbmFtZSBvZiBhIGNh
c2UgdG8gYmUgcmV0cmlldmVkLgoKDQoFBAACAAUSBJcBAggKDQoFBAACAAESBJcBCQ0KDQoF
BAACAAMSBJcBEBEKDwoFBAACAAgSBpcBEpwBAwoQCggEAAIACJwIABIEmAEEKgoRCgcEAAIA
CJ8IEgaZAQSbAQUKQAoCBAESBqABAKsBARoyIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIHRo
ZSBDcmVhdGVDYXNlIGVuZHBvaW50LgoKCwoDBAEBEgSgAQgZCloKBAQBAgASBqIBAqcBBBpK
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcGFyZW50IHVuZGVyIHdoaWNoIHRoZSBjYXNl
IHNob3VsZCBiZSBjcmVhdGVkLgoKDQoFBAECAAUSBKIBAggKDQoFBAECAAESBKIBCQ8KDQoF
BAECAAMSBKIBEhMKDwoFBAECAAgSBqIBFKcBAwoQCggEAQIACJwIABIEowEEKgoRCgcEAQIA
CJ8IEgakAQSmAQUKMQoEBAECARIEqgECORojIFJlcXVpcmVkLiBUaGUgY2FzZSB0byBiZSBj
cmVhdGVkLgoKDQoFBAECAQYSBKoBAgYKDQoFBAECAQESBKoBBwsKDQoFBAECAQMSBKoBDg8K
DQoFBAECAQgSBKoBEDgKEAoIBAECAQicCAASBKoBETcKPwoCBAISBq4BANIBARoxIFRoZSBy
ZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBMaXN0Q2FzZXMgZW5kcG9pbnQuCgoLCgMEAgESBK4B
CBgKRQoEBAICABIGsAECtQEEGjUgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIGEgcGFyZW50IHRv
IGxpc3QgY2FzZXMgdW5kZXIuCgoNCgUEAgIABRIEsAECCAoNCgUEAgIAARIEsAEJDwoNCgUE
AgIAAxIEsAESEwoPCgUEAgIACBIGsAEUtQEDChAKCAQCAgAInAgAEgSxAQQqChEKBwQCAgAI
nwgSBrIBBLQBBQqTBQoEBAICARIEygECFBqEBSBBbiBleHByZXNzaW9uIHVzZWQgdG8gZmls
dGVyIGNhc2VzLgoKIElmIGl0J3MgYW4gZW1wdHkgc3RyaW5nLCB0aGVuIG5vIGZpbHRlcmlu
ZyBoYXBwZW5zLiBPdGhlcndpc2UsIHRoZSBlbmRwb2ludAogcmV0dXJucyB0aGUgY2FzZXMg
dGhhdCBtYXRjaCB0aGUgZmlsdGVyLgoKIEV4cHJlc3Npb25zIHVzZSB0aGUgZm9sbG93aW5n
IGZpZWxkcyBzZXBhcmF0ZWQgYnkgYEFORGAgYW5kIHNwZWNpZmllZCB3aXRoCiBgPWA6Cgog
LSBgc3RhdGVgOiBDYW4gYmUgYE9QRU5gIG9yIGBDTE9TRURgLgogLSBgcHJpb3JpdHlgOiBD
YW4gYmUgYFAwYCwgYFAxYCwgYFAyYCwgYFAzYCwgb3IgYFA0YC4gWW91CiBjYW4gc3BlY2lm
eSBtdWx0aXBsZSB2YWx1ZXMgZm9yIHByaW9yaXR5IHVzaW5nIHRoZSBgT1JgIG9wZXJhdG9y
LiBGb3IKIGV4YW1wbGUsIGBwcmlvcml0eT1QMSBPUiBwcmlvcml0eT1QMmAuCiAtIGBjcmVh
dG9yLmVtYWlsYDogVGhlIGVtYWlsIGFkZHJlc3Mgb2YgdGhlIGNhc2UgY3JlYXRvci4KCiBF
WEFNUExFUzoKCiAtIGBzdGF0ZT1DTE9TRURgCiAtIGBzdGF0ZT1PUEVOIEFORCBjcmVhdG9y
LmVtYWlsPSJ0ZXN0ZXJAZXhhbXBsZS5jb20iYAogLSBgc3RhdGU9T1BFTiBBTkQgKHByaW9y
aXR5PVAwIE9SIHByaW9yaXR5PVAxKWAKCg0KBQQCAgEFEgTKAQIICg0KBQQCAgEBEgTKAQkP
Cg0KBQQCAgEDEgTKARITClYKBAQCAgISBM0BAhYaSCBUaGUgbWF4aW11bSBudW1iZXIgb2Yg
Y2FzZXMgZmV0Y2hlZCB3aXRoIGVhY2ggcmVxdWVzdC4gRGVmYXVsdHMgdG8gMTAuCgoNCgUE
AgICBRIEzQECBwoNCgUEAgICARIEzQEIEQoNCgUEAgICAxIEzQEUFQpwCgQEAgIDEgTRAQIY
GmIgQSB0b2tlbiBpZGVudGlmeWluZyB0aGUgcGFnZSBvZiByZXN1bHRzIHRvIHJldHVybi4g
SWYgdW5zcGVjaWZpZWQsIHRoZQogZmlyc3QgcGFnZSBpcyByZXRyaWV2ZWQuCgoNCgUEAgID
BRIE0QECCAoNCgUEAgIDARIE0QEJEwoNCgUEAgIDAxIE0QEWFwpACgIEAxIG1QEA3gEBGjIg
VGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yIHRoZSBMaXN0Q2FzZXMgZW5kcG9pbnQuCgoLCgME
AwESBNUBCBkKYgoEBAMCABIE2AECGhpUIFRoZSBsaXN0IG9mIGNhc2VzIGFzc29jaWF0ZWQg
d2l0aCB0aGUgcGFyZW50IGFmdGVyIGFueQogZmlsdGVycyBoYXZlIGJlZW4gYXBwbGllZC4K
Cg0KBQQDAgAEEgTYAQIKCg0KBQQDAgAGEgTYAQsPCg0KBQQDAgABEgTYARAVCg0KBQQDAgAD
EgTYARgZCr8BCgQEAwIBEgTdAQIdGrABIEEgdG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQg
cGFnZSBvZiByZXN1bHRzLiBTZXQgdGhpcyBpbiB0aGUgYHBhZ2VfdG9rZW5gCiBmaWVsZCBv
ZiBzdWJzZXF1ZW50IGBjYXNlcy5saXN0YCByZXF1ZXN0cy4gSWYgdW5zcGVjaWZpZWQsIHRo
ZXJlIGFyZSBubwogbW9yZSByZXN1bHRzIHRvIHJldHJpZXZlLgoKDQoFBAMCAQUSBN0BAggK
DQoFBAMCAQESBN0BCRgKDQoFBAMCAQMSBN0BGxwKQQoCBAQSBuEBAJ4CARozIFRoZSByZXF1
ZXN0IG1lc3NhZ2UgZm9yIHRoZSBTZWFyY2hDYXNlcyBlbmRwb2ludC4KCgsKAwQEARIE4QEI
GgpKCgQEBAIAEgTjAQIUGjwgVGhlIG5hbWUgb2YgdGhlIHBhcmVudCByZXNvdXJjZSB0byBz
ZWFyY2ggZm9yIGNhc2VzIHVuZGVyLgoKDQoFBAQCAAUSBOMBAggKDQoFBAQCAAESBOMBCQ8K
DQoFBAQCAAMSBOMBEhMKgg8KBAQEAgESBJUCAhMa8w4gQW4gZXhwcmVzc2lvbiB1c2VkIHRv
IGZpbHRlciBjYXNlcy4KCiBFeHByZXNzaW9ucyB1c2UgdGhlIGZvbGxvd2luZyBmaWVsZHMg
c2VwYXJhdGVkIGJ5IGBBTkRgIGFuZCBzcGVjaWZpZWQgd2l0aAogYD1gOgoKIC0gYHN0YXRl
YDogQ2FuIGJlIGBPUEVOYCBvciBgQ0xPU0VEYC4KIC0gYHByaW9yaXR5YDogQ2FuIGJlIGBQ
MGAsIGBQMWAsIGBQMmAsIGBQM2AsIG9yIGBQNGAuIFlvdQogY2FuIHNwZWNpZnkgbXVsdGlw
bGUgdmFsdWVzIGZvciBwcmlvcml0eSB1c2luZyB0aGUgYE9SYCBvcGVyYXRvci4gRm9yCiBl
eGFtcGxlLCBgcHJpb3JpdHk9UDEgT1IgcHJpb3JpdHk9UDJgLgogLSBgY3JlYXRvci5lbWFp
bGA6IFRoZSBlbWFpbCBhZGRyZXNzIG9mIHRoZSBjYXNlIGNyZWF0b3IuCgogVG8gc2VhcmNo
IGFjcm9zcyBgZGlzcGxheU5hbWVgLCBgZGVzY3JpcHRpb25gLCBhbmQgY29tbWVudHMsIHVz
ZSBhIGdsb2JhbAogcmVzdHJpY3Rpb24gd2l0aCBubyBrZXl3b3JkIG9yIG9wZXJhdG9yLiBG
b3IgZXhhbXBsZSwgYCJteSBzZWFyY2giYC4KCiBUbyBzZWFyY2ggb25seSBjYXNlcyB1cGRh
dGVkIGFmdGVyIGEgY2VydGFpbiBkYXRlLCB1c2UgYHVwZGF0ZV90aW1lYAogcmVzdHJpY3Rl
ZCB3aXRoIHRoYXQgcGFydGljdWxhciBkYXRlLCB0aW1lLCBhbmQgdGltZXpvbmUgaW4gSVNP
IGRhdGV0aW1lCiBmb3JtYXQuIEZvciBleGFtcGxlLCBgdXBkYXRlX3RpbWU+IjIwMjAtMDEt
MDFUMDA6MDA6MDAtMDU6MDAiYC4KIGB1cGRhdGVfdGltZWAgb25seSBzdXBwb3J0cyB0aGUg
Z3JlYXRlciB0aGFuIG9wZXJhdG9yIChgPmApLgoKIElmIHlvdSBhcmUgdXNpbmcgdGhlIGB2
MmAgdmVyc2lvbiBvZiB0aGUgQVBJLCB5b3UgbXVzdCBzcGVjaWZ5IHRoZSBjYXNlCiBwYXJl
bnQgaW4gdGhlIGBwYXJlbnRgIGZpZWxkLiBJZiB5b3UgcHJvdmlkZSBhbiBlbXB0eSBgcXVl
cnlgLCBhbGwgY2FzZXMKIHVuZGVyIHRoZSBwYXJlbnQgcmVzb3VyY2Ugd2lsbCBiZSByZXR1
cm5lZC4KCiBJZiB5b3UgYXJlIHVzaW5nIHRoZSBgdjJiZXRhYCB2ZXJzaW9uIG9mIHRoZSBB
UEksIHlvdSBtdXN0IHNwZWNpZnkgdGhlIGNhc2UKIHBhcmVudCBpbiB0aGUgYHF1ZXJ5YCBm
aWVsZCB1c2luZyBvbmUgb2YgdGhlIHR3byBmaWVsZHMgYmVsb3csIHdoaWNoIGFyZQogb25s
eSBhdmFpbGFibGUgZm9yIGB2MmJldGFgLiBUaGUgYHBhcmVudGAgZmllbGQgd2lsbCBiZSBp
Z25vcmVkLgoKIC0gYG9yZ2FuaXphdGlvbmA6IEFuIG9yZ2FuaXphdGlvbiBuYW1lIGluIHRo
ZSBmb3JtCiBgb3JnYW5pemF0aW9ucy88b3JnYW5pemF0aW9uX2lkPmAuCiAtIGBwcm9qZWN0
YDogQSBwcm9qZWN0IG5hbWUgaW4gdGhlIGZvcm0gYHByb2plY3RzLzxwcm9qZWN0X2lkPmAu
CgogRXhhbXBsZXM6CgogRm9yIGB2MmA6CgogLSBgc3RhdGU9Q0xPU0VEYAogLSBgc3RhdGU9
T1BFTiBBTkQgY3JlYXRvci5lbWFpbD0idGVzdGVyQGV4YW1wbGUuY29tImAKIC0gYHN0YXRl
PU9QRU4gQU5EIChwcmlvcml0eT1QMCBPUiBwcmlvcml0eT1QMSlgCiAtIGB1cGRhdGVfdGlt
ZT4iMjAyMC0wMS0wMVQwMDowMDowMC0wNTowMCJgCgogRm9yIGB2MmJldGFgOgoKIC0gYG9y
Z2FuaXphdGlvbj0ib3JnYW5pemF0aW9ucy8xMjM0NTY3ODkiYAogLSBgcHJvamVjdD0icHJv
amVjdHMvbXktcHJvamVjdC1pZCJgCiAtIGBwcm9qZWN0PSJwcm9qZWN0cy8xMjM0NTY3ODki
YAogLSBgb3JnYW5pemF0aW9uPSJvcmdhbml6YXRpb25zLzEyMzQ1Njc4OSIgQU5EIHN0YXRl
PUNMT1NFRGAKIC0gYHByb2plY3Q9InByb2plY3RzL215LXByb2plY3QtaWQiIEFORCBjcmVh
dG9yLmVtYWlsPSJ0ZXN0ZXJAZXhhbXBsZS5jb20iYAogLSBgcHJvamVjdD0icHJvamVjdHMv
bXktcHJvamVjdC1pZCIgQU5EIChwcmlvcml0eT1QMCBPUiBwcmlvcml0eT1QMSlgCgoNCgUE
BAIBBRIElQICCAoNCgUEBAIBARIElQIJDgoNCgUEBAIBAxIElQIREgpkCgQEBAICEgSZAgIW
GlYgVGhlIG1heGltdW0gbnVtYmVyIG9mIGNhc2VzIGZldGNoZWQgd2l0aCBlYWNoIHJlcXVl
c3QuIFRoZSBkZWZhdWx0IHBhZ2UKIHNpemUgaXMgMTAuCgoNCgUEBAICBRIEmQICBwoNCgUE
BAICARIEmQIIEQoNCgUEBAICAxIEmQIUFQpwCgQEBAIDEgSdAgIYGmIgQSB0b2tlbiBpZGVu
dGlmeWluZyB0aGUgcGFnZSBvZiByZXN1bHRzIHRvIHJldHVybi4gSWYgdW5zcGVjaWZpZWQs
IHRoZQogZmlyc3QgcGFnZSBpcyByZXRyaWV2ZWQuCgoNCgUEBAIDBRIEnQICCAoNCgUEBAID
ARIEnQIJEwoNCgUEBAIDAxIEnQIWFwpCCgIEBRIGoQIAqgIBGjQgVGhlIHJlc3BvbnNlIG1l
c3NhZ2UgZm9yIHRoZSBTZWFyY2hDYXNlcyBlbmRwb2ludC4KCgsKAwQFARIEoQIIGwpiCgQE
BQIAEgSkAgIaGlQgVGhlIGxpc3Qgb2YgY2FzZXMgYXNzb2NpYXRlZCB3aXRoIHRoZSBwYXJl
bnQgYWZ0ZXIgYW55CiBmaWx0ZXJzIGhhdmUgYmVlbiBhcHBsaWVkLgoKDQoFBAUCAAQSBKQC
AgoKDQoFBAUCAAYSBKQCCw8KDQoFBAUCAAESBKQCEBUKDQoFBAUCAAMSBKQCGBkKwQEKBAQF
AgESBKkCAh0asgEgQSB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3Vs
dHMuIFNldCB0aGlzIGluIHRoZQogYHBhZ2VfdG9rZW5gIGZpZWxkIG9mIHN1YnNlcXVlbnQg
YGNhc2VzLnNlYXJjaGAgcmVxdWVzdHMuIElmIHVuc3BlY2lmaWVkLAogdGhlcmUgYXJlIG5v
IG1vcmUgcmVzdWx0cyB0byByZXRyaWV2ZS4KCg0KBQQFAgEFEgSpAgIICg0KBQQFAgEBEgSp
AgkYCg0KBQQFAgEDEgSpAhscCkIKAgQGEgatAgC4AgEaNCBUaGUgcmVxdWVzdCBtZXNzYWdl
IGZvciB0aGUgRXNjYWxhdGVDYXNlIGVuZHBvaW50LgoKCwoDBAYBEgStAggbCkEKBAQGAgAS
Bq8CArQCBBoxIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgY2FzZSB0byBiZSBlc2NhbGF0
ZWQuCgoNCgUEBgIABRIErwICCAoNCgUEBgIAARIErwIJDQoNCgUEBgIAAxIErwIQEQoPCgUE
BgIACBIGrwIStAIDChAKCAQGAgAInAgAEgSwAgQqChEKBwQGAgAInwgSBrECBLMCBQpSCgQE
BgIBEgS3AgIcGkQgVGhlIGVzY2FsYXRpb24gaW5mb3JtYXRpb24gdG8gYmUgc2VudCB3aXRo
IHRoZSBlc2NhbGF0aW9uIHJlcXVlc3QuCgoNCgUEBgIBBhIEtwICDAoNCgUEBgIBARIEtwIN
FwoNCgUEBgIBAxIEtwIaGwo/CgIEBxIGuwIAyAIBGjEgVGhlIHJlcXVlc3QgbWVzc2FnZSBm
b3IgdGhlIFVwZGF0ZUNhc2UgZW5kcG9pbnQKCgsKAwQHARIEuwIIGQotCgQEBwIAEgS9AgI5
Gh8gUmVxdWlyZWQuIFRoZSBjYXNlIHRvIHVwZGF0ZS4KCg0KBQQHAgAGEgS9AgIGCg0KBQQH
AgABEgS9AgcLCg0KBQQHAgADEgS9Ag4PCg0KBQQHAgAIEgS9AhA4ChAKCAQHAgAInAgAEgS9
AhE3CuQDCgQEBwIBEgTHAgIsGtUDIEEgbGlzdCBvZiBhdHRyaWJ1dGVzIG9mIHRoZSBjYXNl
IHRoYXQgc2hvdWxkIGJlIHVwZGF0ZWQuIFN1cHBvcnRlZCB2YWx1ZXMKIGFyZSBgcHJpb3Jp
dHlgLCBgZGlzcGxheV9uYW1lYCwgYW5kIGBzdWJzY3JpYmVyX2VtYWlsX2FkZHJlc3Nlc2Au
IElmIG5vCiBmaWVsZHMgYXJlIHNwZWNpZmllZCwgYWxsIHN1cHBvcnRlZCBmaWVsZHMgYXJl
IHVwZGF0ZWQuCgogQmUgY2FyZWZ1bCAtIGlmIHlvdSBkbyBub3QgcHJvdmlkZSBhIGZpZWxk
IG1hc2ssIHRoZW4geW91IG1pZ2h0CiBhY2NpZGVudGFsbHkgY2xlYXIgc29tZSBmaWVsZHMu
IEZvciBleGFtcGxlLCBpZiB5b3UgbGVhdmUgdGhlIGZpZWxkIG1hc2sKIGVtcHR5IGFuZCBk
byBub3QgcHJvdmlkZSBhIHZhbHVlIGZvciBgc3Vic2NyaWJlcl9lbWFpbF9hZGRyZXNzZXNg
LCB0aGVuCiBgc3Vic2NyaWJlcl9lbWFpbF9hZGRyZXNzZXNgIGlzIHVwZGF0ZWQgdG8gZW1w
dHkuCgoNCgUEBwIBBhIExwICGwoNCgUEBwIBARIExwIcJwoNCgUEBwIBAxIExwIqKwo/CgIE
CBIGywIA0wIBGjEgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIENsb3NlQ2FzZSBlbmRw
b2ludC4KCgsKAwQIARIEywIIGAo6CgQECAIAEgbNAgLSAgQaKiBSZXF1aXJlZC4gVGhlIG5h
bWUgb2YgdGhlIGNhc2UgdG8gY2xvc2UuCgoNCgUECAIABRIEzQICCAoNCgUECAIAARIEzQIJ
DQoNCgUECAIAAxIEzQIQEQoPCgUECAIACBIGzQIS0gIDChAKCAQIAgAInAgAEgTOAgQqChEK
BwQIAgAInwgSBs8CBNECBQpPCgIECRIG1gIA4wIBGkEgVGhlIHJlcXVlc3QgbWVzc2FnZSBm
b3IgdGhlIFNlYXJjaENhc2VDbGFzc2lmaWNhdGlvbnMgZW5kcG9pbnQuCgoLCgMECQESBNYC
CCgKwgEKBAQJAgASBNsCAhMaswEgQW4gZXhwcmVzc2lvbiB1c2VkIHRvIGZpbHRlciBjYXNl
IGNsYXNzaWZpY2F0aW9ucy4KCiBJZiBpdCdzIGFuIGVtcHR5IHN0cmluZywgdGhlbiBubyBm
aWx0ZXJpbmcgaGFwcGVucy4gT3RoZXJ3aXNlLCBjYXNlCiBjbGFzc2lmaWNhdGlvbnMgd2ls
bCBiZSByZXR1cm5lZCB0aGF0IG1hdGNoIHRoZSBmaWx0ZXIuCgoNCgUECQIABRIE2wICCAoN
CgUECQIAARIE2wIJDgoNCgUECQIAAxIE2wIREgpQCgQECQIBEgTeAgIWGkIgVGhlIG1heGlt
dW0gbnVtYmVyIG9mIGNsYXNzaWZpY2F0aW9ucyBmZXRjaGVkIHdpdGggZWFjaCByZXF1ZXN0
LgoKDQoFBAkCAQUSBN4CAgcKDQoFBAkCAQESBN4CCBEKDQoFBAkCAQMSBN4CFBUKcAoEBAkC
AhIE4gICGBpiIEEgdG9rZW4gaWRlbnRpZnlpbmcgdGhlIHBhZ2Ugb2YgcmVzdWx0cyB0byBy
ZXR1cm4uIElmIHVuc3BlY2lmaWVkLCB0aGUKIGZpcnN0IHBhZ2UgaXMgcmV0cmlldmVkLgoK
DQoFBAkCAgUSBOICAggKDQoFBAkCAgESBOICCRMKDQoFBAkCAgMSBOICFhcKTAoCBAoSBuYC
AO4CARo+IFRoZSByZXNwb25zZSBtZXNzYWdlIGZvciBTZWFyY2hDYXNlQ2xhc3NpZmljYXRp
b25zIGVuZHBvaW50LgoKCwoDBAoBEgTmAggpCi4KBAQKAgASBOgCAjcaICBUaGUgY2xhc3Np
ZmljYXRpb25zIHJldHJpZXZlZC4KCg0KBQQKAgAEEgToAgIKCg0KBQQKAgAGEgToAgsdCg0K
BQQKAgABEgToAh4yCg0KBQQKAgADEgToAjU2Cs0BCgQECgIBEgTtAgIdGr4BIEEgdG9rZW4g
dG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLiBTZXQgdGhpcyBpbiB0aGUg
YHBhZ2VfdG9rZW5gCiBmaWVsZCBvZiBzdWJzZXF1ZW50IGBjYXNlQ2xhc3NpZmljYXRpb25z
Lmxpc3RgIHJlcXVlc3RzLiBJZiB1bnNwZWNpZmllZCwKIHRoZXJlIGFyZSBubyBtb3JlIHJl
c3VsdHMgdG8gcmV0cmlldmUuCgoNCgUECgIBBRIE7QICCAoNCgUECgIBARIE7QIJGAoNCgUE
CgIBAxIE7QIbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::CaseService::GetCaseRequest ===
    # Fields for GetCaseRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2::CaseService::CreateCaseRequest ===
    # Fields for CreateCaseRequest
    # Field: parent Type: 9 ()
    # Field: case Type: 11 (.google.cloud.support.v2.Case)

# === Message: Google::Cloud::Support::V2::CaseService::ListCasesRequest ===
    # Fields for ListCasesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::CaseService::ListCasesResponse ===
    # Fields for ListCasesResponse
    # Field: cases Type: 11 (.google.cloud.support.v2.Case)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::CaseService::SearchCasesRequest ===
    # Fields for SearchCasesRequest
    # Field: parent Type: 9 ()
    # Field: query Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::CaseService::SearchCasesResponse ===
    # Fields for SearchCasesResponse
    # Field: cases Type: 11 (.google.cloud.support.v2.Case)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::CaseService::EscalateCaseRequest ===
    # Fields for EscalateCaseRequest
    # Field: name Type: 9 ()
    # Field: escalation Type: 11 (.google.cloud.support.v2.Escalation)

# === Message: Google::Cloud::Support::V2::CaseService::UpdateCaseRequest ===
    # Fields for UpdateCaseRequest
    # Field: case Type: 11 (.google.cloud.support.v2.Case)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Support::V2::CaseService::CloseCaseRequest ===
    # Fields for CloseCaseRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsRequest ===
    # Fields for SearchCaseClassificationsRequest
    # Field: query Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsResponse ===
    # Fields for SearchCaseClassificationsResponse
    # Field: case_classifications Type: 11 (.google.cloud.support.v2.CaseClassification)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Support::V2::CaseService::CaseServiceClient ===
package Google::Cloud::Support::V2::CaseService::CaseServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2::CaseService::CaseServiceClient

Client stub representing the remote C<CaseService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<support.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'support.googleapis.com:443' );

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

sub get_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CaseService::GetCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'GetCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::Case::Case',
    });
}

sub list_cases {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CaseService::ListCasesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'ListCases',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::CaseService::ListCasesResponse',
    });
}

sub search_cases {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CaseService::SearchCasesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'SearchCases',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::CaseService::SearchCasesResponse',
    });
}

sub create_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CaseService::CreateCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'CreateCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::Case::Case',
    });
}

sub update_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CaseService::UpdateCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'UpdateCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::Case::Case',
    });
}

sub escalate_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CaseService::EscalateCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'EscalateCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::Case::Case',
    });
}

sub close_case {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CaseService::CloseCaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'CloseCase',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::Case::Case',
    });
}

sub search_case_classifications {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'SearchCaseClassifications',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::CaseService - Compiled Protocol Buffers messages for google/cloud/support/v2/case_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::CaseService;

    my $msg = Google::Cloud::Support::V2::CaseService::GetCaseRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::CaseService::GetCaseRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/case_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::CaseService::GetCaseRequest

The request message for the GetCase endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full name of a case to be retrieved.

=back

=head2 Google::Cloud::Support::V2::CaseService::CreateCaseRequest

The request message for the CreateCase endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent under which the case should be created.

=item * C<< $msg->case() >> / C<< $msg->case($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Case::Case>)

Required. The case to be created.

=back

=head2 Google::Cloud::Support::V2::CaseService::ListCasesRequest

The request message for the ListCases endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of a parent to list cases under.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

An expression used to filter cases.

If it's an empty string, then no filtering happens. Otherwise, the endpoint
returns the cases that match the filter.

Expressions use the following fields separated by `AND` and specified with
`=`:

- `state`: Can be `OPEN` or `CLOSED`.
- `priority`: Can be `P0`, `P1`, `P2`, `P3`, or `P4`. You
can specify multiple values for priority using the `OR` operator. For
example, `priority=P1 OR priority=P2`.
- `creator.email`: The email address of the case creator.

EXAMPLES:

- `state=CLOSED`
- `state=OPEN AND creator.email="tester@example.com"`
- `state=OPEN AND (priority=P0 OR priority=P1)`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of cases fetched with each request. Defaults to 10.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying the page of results to return. If unspecified, the
first page is retrieved.

=back

=head2 Google::Cloud::Support::V2::CaseService::ListCasesResponse

The response message for the ListCases endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cases() >> / C<< $msg->cases($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Case::Case>)

The list of cases associated with the parent after any
filters have been applied.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the `page_token`
field of subsequent `cases.list` requests. If unspecified, there are no
more results to retrieve.

=back

=head2 Google::Cloud::Support::V2::CaseService::SearchCasesRequest

The request message for the SearchCases endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource to search for cases under.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

An expression used to filter cases.

Expressions use the following fields separated by `AND` and specified with
`=`:

- `state`: Can be `OPEN` or `CLOSED`.
- `priority`: Can be `P0`, `P1`, `P2`, `P3`, or `P4`. You
can specify multiple values for priority using the `OR` operator. For
example, `priority=P1 OR priority=P2`.
- `creator.email`: The email address of the case creator.

To search across `displayName`, `description`, and comments, use a global
restriction with no keyword or operator. For example, `"my search"`.

To search only cases updated after a certain date, use `update_time`
restricted with that particular date, time, and timezone in ISO datetime
format. For example, `update_time>"2020-01-01T00:00:00-05:00"`.
`update_time` only supports the greater than operator (`>`).

If you are using the `v2` version of the API, you must specify the case
parent in the `parent` field. If you provide an empty `query`, all cases
under the parent resource will be returned.

If you are using the `v2beta` version of the API, you must specify the case
parent in the `query` field using one of the two fields below, which are
only available for `v2beta`. The `parent` field will be ignored.

- `organization`: An organization name in the form
`organizations/<organization_id>`.
- `project`: A project name in the form `projects/<project_id>`.

Examples:

For `v2`:

- `state=CLOSED`
- `state=OPEN AND creator.email="tester@example.com"`
- `state=OPEN AND (priority=P0 OR priority=P1)`
- `update_time>"2020-01-01T00:00:00-05:00"`

For `v2beta`:

- `organization="organizations/123456789"`
- `project="projects/my-project-id"`
- `project="projects/123456789"`
- `organization="organizations/123456789" AND state=CLOSED`
- `project="projects/my-project-id" AND creator.email="tester@example.com"`
- `project="projects/my-project-id" AND (priority=P0 OR priority=P1)`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of cases fetched with each request. The default page
size is 10.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying the page of results to return. If unspecified, the
first page is retrieved.

=back

=head2 Google::Cloud::Support::V2::CaseService::SearchCasesResponse

The response message for the SearchCases endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cases() >> / C<< $msg->cases($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Case::Case>)

The list of cases associated with the parent after any
filters have been applied.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the
`page_token` field of subsequent `cases.search` requests. If unspecified,
there are no more results to retrieve.

=back

=head2 Google::Cloud::Support::V2::CaseService::EscalateCaseRequest

The request message for the EscalateCase endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the case to be escalated.

=item * C<< $msg->escalation() >> / C<< $msg->escalation($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Escalation::Escalation>)

The escalation information to be sent with the escalation request.

=back

=head2 Google::Cloud::Support::V2::CaseService::UpdateCaseRequest

The request message for the UpdateCase endpoint

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->case() >> / C<< $msg->case($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Case::Case>)

Required. The case to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

A list of attributes of the case that should be updated. Supported values
are `priority`, `display_name`, and `subscriber_email_addresses`. If no
fields are specified, all supported fields are updated.

Be careful - if you do not provide a field mask, then you might
accidentally clear some fields. For example, if you leave the field mask
empty and do not provide a value for `subscriber_email_addresses`, then
`subscriber_email_addresses` is updated to empty.

=back

=head2 Google::Cloud::Support::V2::CaseService::CloseCaseRequest

The request message for the CloseCase endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the case to close.

=back

=head2 Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsRequest

The request message for the SearchCaseClassifications endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

An expression used to filter case classifications.

If it's an empty string, then no filtering happens. Otherwise, case
classifications will be returned that match the filter.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of classifications fetched with each request.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying the page of results to return. If unspecified, the
first page is retrieved.

=back

=head2 Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsResponse

The response message for SearchCaseClassifications endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->case_classifications() >> / C<< $msg->case_classifications($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Case::CaseClassification>)

The classifications retrieved.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the `page_token`
field of subsequent `caseClassifications.list` requests. If unspecified,
there are no more results to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::CaseService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
