package Google::Cloud::Apptopology::V1::Schema;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvYXBwdG9wb2xvZ3kvdjEvc2NoZW1hLnByb3RvEhtnb29nbGUuY2xv
dWQuYXBwdG9wb2xvZ3kudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ilAEKBkRvbWFpbhIXCgRuYW1lGAEgASgJQgPgQQhS
BG5hbWU6cepBbgohYXBwdG9wb2xvZ3kuZ29vZ2xlYXBpcy5jb20vRG9tYWluEjhwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9tYWlucy97ZG9tYWlufSoHZG9t
YWluczIGZG9tYWluIsYDCgZTY2hlbWESFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEkQKCm5v
ZGVfdHlwZXMYAiADKAsyJS5nb29nbGUuY2xvdWQuYXBwdG9wb2xvZ3kudjEuTm9kZVR5cGVS
CW5vZGVUeXBlcxJECgplZGdlX3R5cGVzGAMgAygLMiUuZ29vZ2xlLmNsb3VkLmFwcHRvcG9s
b2d5LnYxLkVkZ2VUeXBlUgllZGdlVHlwZXMSVwoQbGFiZWxfcHJvcGVydGllcxgEIAMoCzIs
Lmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5MYWJlbFByb3BlcnRpZXNSD2xhYmVsUHJv
cGVydGllcxJECgplZGdlX3J1bGVzGAUgAygLMiUuZ29vZ2xlLmNsb3VkLmFwcHRvcG9sb2d5
LnYxLkVkZ2VSdWxlUgllZGdlUnVsZXM6eOpBdQohYXBwdG9wb2xvZ3kuZ29vZ2xlYXBpcy5j
b20vU2NoZW1hEj9wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9t
YWlucy97ZG9tYWlufS9zY2hlbWEqB3NjaGVtYXMyBnNjaGVtYSKBAQoITm9kZVR5cGUSEgoE
dHlwZRgBIAEoCVIEdHlwZRIWCgZsYWJlbHMYAiADKAlSBmxhYmVscxIgCgtkZXNjcmlwdGlv
bhgDIAEoCVILZGVzY3JpcHRpb24SJwoPb3B0aW9uYWxfbGFiZWxzGAQgAygJUg5vcHRpb25h
bExhYmVscyKBAQoIRWRnZVR5cGUSEgoEdHlwZRgBIAEoCVIEdHlwZRIWCgZsYWJlbHMYAiAD
KAlSBmxhYmVscxIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SJwoPb3B0aW9u
YWxfbGFiZWxzGAQgAygJUg5vcHRpb25hbExhYmVscyIvCglOb2RlR3JvdXASIgoKYW55X2xh
YmVscxgBIAMoCUID4EEBUglhbnlMYWJlbHMi0wIKCEVkZ2VSdWxlEikKDXNyY19ub2RlX3R5
cGUYBCABKAlCA+BBAUgAUgtzcmNOb2RlVHlwZRJTCg5zcmNfbm9kZV9ncm91cBgFIAEoCzIm
Lmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5Ob2RlR3JvdXBCA+BBAUgAUgxzcmNOb2Rl
R3JvdXASKwoOZGVzdF9ub2RlX3R5cGUYBiABKAlCA+BBAUgBUgxkZXN0Tm9kZVR5cGUSVQoP
ZGVzdF9ub2RlX2dyb3VwGAcgASgLMiYuZ29vZ2xlLmNsb3VkLmFwcHRvcG9sb2d5LnYxLk5v
ZGVHcm91cEID4EEBSAFSDWRlc3ROb2RlR3JvdXASIAoJZWRnZV90eXBlGAMgASgJQgPgQQFS
CGVkZ2VUeXBlQg0KC3NvdXJjZV9ub2RlQhIKEGRlc3RpbmF0aW9uX25vZGUikAEKD0xhYmVs
UHJvcGVydGllcxIUCgVsYWJlbBgBIAEoCVIFbGFiZWwSRQoKcHJvcGVydGllcxgCIAMoCzIl
Lmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5Qcm9wZXJ0eVIKcHJvcGVydGllcxIgCgtk
ZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24i9gIKCFByb3BlcnR5Ek0KDHN0cmluZ192
YWx1ZRgDIAEoCzIoLmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5TdHJpbmdWYWx1ZUgA
UgtzdHJpbmdWYWx1ZRJECglpbnRfdmFsdWUYBCABKAsyJS5nb29nbGUuY2xvdWQuYXBwdG9w
b2xvZ3kudjEuSW50VmFsdWVIAFIIaW50VmFsdWUSRwoKYm9vbF92YWx1ZRgFIAEoCzImLmdv
b2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5Cb29sVmFsdWVIAFIJYm9vbFZhbHVlEk0KDGRv
dWJsZV92YWx1ZRgGIAEoCzIoLmdvb2dsZS5jbG91ZC5hcHB0b3BvbG9neS52MS5Eb3VibGVW
YWx1ZUgAUgtkb3VibGVWYWx1ZRISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9u
GAogASgJUgtkZXNjcmlwdGlvbkIHCgV2YWx1ZSJQCgtTdHJpbmdWYWx1ZRIaCghyZXBlYXRl
ZBgBIAEoCFIIcmVwZWF0ZWQSJQoOYWxsb3dlZF92YWx1ZXMYAiADKAlSDWFsbG93ZWRWYWx1
ZXMiTQoISW50VmFsdWUSGgoIcmVwZWF0ZWQYASABKAhSCHJlcGVhdGVkEiUKDmFsbG93ZWRf
dmFsdWVzGAIgAygDUg1hbGxvd2VkVmFsdWVzIk4KCUJvb2xWYWx1ZRIaCghyZXBlYXRlZBgB
IAEoCFIIcmVwZWF0ZWQSJQoOYWxsb3dlZF92YWx1ZXMYAiADKAhSDWFsbG93ZWRWYWx1ZXMi
UAoLRG91YmxlVmFsdWUSGgoIcmVwZWF0ZWQYASABKAhSCHJlcGVhdGVkEiUKDmFsbG93ZWRf
dmFsdWVzGAIgAygBUg1hbGxvd2VkVmFsdWVzQtABCh9jb20uZ29vZ2xlLmNsb3VkLmFwcHRv
cG9sb2d5LnYxQgtTY2hlbWFQcm90b1ABWkFjbG91ZC5nb29nbGUuY29tL2dvL2FwcHRvcG9s
b2d5L2FwaXYxL2FwcHRvcG9sb2d5cGI7YXBwdG9wb2xvZ3lwYqoCG0dvb2dsZS5DbG91ZC5B
cHBUb3BvbG9neS5WMcoCG0dvb2dsZVxDbG91ZFxBcHBUb3BvbG9neVxWMeoCHkdvb2dsZTo6
Q2xvdWQ6OkFwcFRvcG9sb2d5OjpWMUqARwoHEgUOAP0BAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBID
FQA4CgkKAgglEgMVADgKCAoBCBIDFgBYCgkKAggLEgMWAFgKCAoBCBIDFwAiCgkKAggKEgMX
ACIKCAoBCBIDGAAsCgkKAggIEgMYACwKCAoBCBIDGQA4CgkKAggBEgMZADgKCAoBCBIDGgA4
CgkKAggpEgMaADgKCAoBCBIDGwA3CgkKAggtEgMbADcKdQoCBAASBB8AKwEaaSBEb21haW4g
aXMgYSBwcmUtZGVmaW5lZCB0b3BvbG9neSBxdWVyeSBkb21haW4uIEVhY2ggdG9wb2xvZ3kg
ZG9tYWluCiBjb250YWlucyBhIHNldCBvZiBub2RlcyBhbmQgZWRnZXMuCgoKCgMEAAESAx8I
DgoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKuQEKBAQAAgASAyoCPRqrASBJZGVudGlm
aWVyLiBUaGUgcHJlLWRlZmluZWQgdG9wb2xvZ3kgZG9tYWluLgogQ3VycmVudGx5IG9ubHkg
U1JFLCBERVZPUFMsIGFuZCBTRUNVUklUWSBhcmUgYXZhaWxhYmxlLgogRm9ybWF0OiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RvbWFpbnMve2RvbWFpbn1g
CgoMCgUEAAIABRIDKgIICgwKBQQAAgABEgMqCQ0KDAoFBAACAAMSAyoQEQoMCgUEAAIACBID
KhI8Cg8KCAQAAgAInAgAEgMqEzsKZAoCBAESBC8ASwEaWCBTY2hlbWEgaXMgYSBjb2xsZWN0
aW9uIG9mIHN1cHBvcnRlZCBub2RlICYgZWRnZSBsYWJlbHMgYW5kIHByb3BlcnRpZXMgZm9y
IGFuCiBvdmVybGF5LgoKCgoDBAEBEgMvCA4KCwoDBAEHEgQwAjUECg0KBQQBB50IEgQwAjUE
CocBCgQEAQIAEgM6Aj0aeiBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
c2NoZW1hLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9kb21haW5zL3tkb21haW59L3NjaGVtYWAKCgwKBQQBAgAFEgM6AggKDAoFBAECAAES
AzoJDQoMCgUEAQIAAxIDOhARCgwKBQQBAgAIEgM6EjwKDwoIBAECAAicCAASAzoTOwp8CgQE
AQIBEgM+AiMabyBBIGxpc3Qgb2YgYE5vZGVUeXBlYHMgZGVmaW5lZCB3aXRoaW4gdGhpcyBz
Y2hlbWEuCiBSZWZlciB0byB0aGUgZG9jdW1lbnRhdGlvbiBvZiBgTm9kZVR5cGVgIGZvciBt
b3JlIGRldGFpbHMuCgoMCgUEAQIBBBIDPgIKCgwKBQQBAgEGEgM+CxMKDAoFBAECAQESAz4U
HgoMCgUEAQIBAxIDPiEiCnwKBAQBAgISA0ICIxpvIEEgbGlzdCBvZiBgRWRnZVR5cGVgcyBk
ZWZpbmVkIHdpdGhpbiB0aGlzIHNjaGVtYS4KIFJlZmVyIHRvIHRoZSBkb2N1bWVudGF0aW9u
IG9mIGBFZGdlVHlwZWAgZm9yIG1vcmUgZGV0YWlscy4KCgwKBQQBAgIEEgNCAgoKDAoFBAEC
AgYSA0ILEwoMCgUEAQICARIDQhQeCgwKBQQBAgIDEgNCISIKRwoEBAECAxIDRQIwGjogQSBs
aXN0IG9mIHN1cHBvcnRlZCBsYWJlbHMgYW5kIGNvcnJlc3BvbmRpbmcgcHJvcGVydGllcy4K
CgwKBQQBAgMEEgNFAgoKDAoFBAECAwYSA0ULGgoMCgUEAQIDARIDRRsrCgwKBQQBAgMDEgNF
Li8KvgEKBAQBAgQSA0oCIxqwASBFZGdlIHJ1bGVzLiBUaGVzZSB3aWxsIGluZGljYXRlIHdo
aWNoIG5vZGUgdHlwZXMgY2FuIGJlIGNvbm5lY3RlZCBhbmQKIHRocm91Z2ggd2hhdCBlZGdl
IHR5cGUuIFRoaXMgaXMgYSBsaXN0IG9mIChzb3VyY2Vfbm9kZV90eXBlLCBlZGdlX3R5cGUs
CiBkZXN0aW5hdGlvbl9ub2RlX3R5cGUpIHR1cGxlcy4KCgwKBQQBAgQEEgNKAgoKDAoFBAEC
BAYSA0oLEwoMCgUEAQIEARIDShQeCgwKBQQBAgQDEgNKISIKRgoCBAISBE4AYQEaOiBOb2Rl
VHlwZSBkZWZpbmVzIHRoZSBzY2hlbWEgb2YgYSBub2RlIHR5cGUgaW4gdGhlIGdyYXBoLgoK
CgoDBAIBEgNOCBAKdQoEBAICABIDUgISGmggUkVRVUlSRUQKIE5hbWUgb2YgdGhlIG5vZGUg
dHlwZS4KIFRoaXMgbmFtZSBpcyB1c2VkIHRvIGFjY2VzcyB0aGUgbm9kZSB0eXBlIHdoaWxl
IGRlZmluaW5nIHRoZSBzY2hlbWEuCgoMCgUEAgIABRIDUgIICgwKBQQCAgABEgNSCQ0KDAoF
BAICAAMSA1IQEQr4AQoEBAICARIDWAIdGuoBIExhYmVscyBhdHRhY2hlZCB0byB0aGUgbm9k
ZS4gQ29tcG9zYWJsZSwgbmFtZXNwYWNlZCBidWlsZGluZyBibG9ja3MgdGhhdAogZGVmaW5l
IGNvcmUgYXR0cmlidXRlcyB0aHJvdWdoIGFzc29jaWF0ZWQgcHJvcGVydGllcy4gTXVsdGlw
bGUgbGFiZWxzCiBhZ2dyZWdhdGUgdG8gZnVsbHkgc3BlY2lmeSB0aGUgZnVuY3Rpb25hbCB0
cmFpdHMgYW5kIHByb3BlcnR5IHNjaGVtYSBvZiB0aGUKIG5vZGUgdHlwZS4KCgwKBQQCAgEE
EgNYAgoKDAoFBAICAQUSA1gLEQoMCgUEAgIBARIDWBIYCgwKBQQCAgEDEgNYGxwKPgoEBAIC
AhIDWwIZGjEgQSBodW1hbi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgYE5vZGVUeXBl
YC4KCgwKBQQCAgIFEgNbAggKDAoFBAICAgESA1sJFAoMCgUEAgICAxIDWxcYCqkBCgQEAgID
EgNgAiYamwEgQSBub2RlIG9mIHRoaXMgbm9kZSB0eXBlIGNhbiBoYXZlIDAgb3IgbW9yZSBv
ZiB0aGVzZSBsYWJlbHMuIFRoZXNlIG5vZGUKIG9iamVjdHMgb2YgdGhpcyBub2RlIHR5cGUg
d2lsbCBoYXZlIHRoZXNlIGxhYmVscyBhbG9uZ3NpZGUgdGhlCiByZXF1aXJlZCBsYWJlbHMu
CgoMCgUEAgIDBBIDYAIKCgwKBQQCAgMFEgNgCxEKDAoFBAICAwESA2ASIQoMCgUEAgIDAxID
YCQlCkcKAgQDEgRkAHcBGjsgRWRnZVR5cGUgZGVmaW5lcyB0aGUgc2NoZW1hIG9mIGFuIGVk
Z2UgdHlwZSBpbiB0aGUgZ3JhcGguCgoKCgMEAwESA2QIEAp1CgQEAwIAEgNoAhIaaCBSRVFV
SVJFRAogTmFtZSBvZiB0aGUgZWRnZSB0eXBlLgogVGhpcyBuYW1lIGlzIHVzZWQgdG8gYWNj
ZXNzIHRoZSBlZGdlIHR5cGUgd2hpbGUgZGVmaW5pbmcgdGhlIHNjaGVtYS4KCgwKBQQDAgAF
EgNoAggKDAoFBAMCAAESA2gJDQoMCgUEAwIAAxIDaBARCvgBCgQEAwIBEgNuAh0a6gEgTGFi
ZWxzIGF0dGFjaGVkIHRvIHRoZSBlZGdlLiBDb21wb3NhYmxlLCBuYW1lc3BhY2VkIGJ1aWxk
aW5nIGJsb2NrcyB0aGF0CiBkZWZpbmUgY29yZSBhdHRyaWJ1dGVzIHRocm91Z2ggYXNzb2Np
YXRlZCBwcm9wZXJ0aWVzLiBNdWx0aXBsZSBsYWJlbHMKIGFnZ3JlZ2F0ZSB0byBmdWxseSBz
cGVjaWZ5IHRoZSBmdW5jdGlvbmFsIHRyYWl0cyBhbmQgcHJvcGVydHkgc2NoZW1hIG9mIHRo
ZQogZWRnZSB0eXBlLgoKDAoFBAMCAQQSA24CCgoMCgUEAwIBBRIDbgsRCgwKBQQDAgEBEgNu
EhgKDAoFBAMCAQMSA24bHAo+CgQEAwICEgNxAhkaMSBBIGh1bWFuLXJlYWRhYmxlIGRlc2Ny
aXB0aW9uIG9mIHRoZSBgRWRnZVR5cGVgLgoKDAoFBAMCAgUSA3ECCAoMCgUEAwICARIDcQkU
CgwKBQQDAgIDEgNxFxgKqgEKBAQDAgMSA3YCJhqcASBBbiBlZGdlIG9mIHRoaXMgZWRnZSB0
eXBlIGNhbiBoYXZlIDAgb3IgbW9yZSBvZiB0aGVzZSBsYWJlbHMuIFRoZXNlIGVkZ2UKIG9i
amVjdHMgb2YgdGhpcyBlZGdlIHR5cGUgd2lsbCBoYXZlIHRoZXNlIGxhYmVscyBhbG9uZ3Np
ZGUgdGhlCiByZXF1aXJlZCBsYWJlbHMuCgoMCgUEAwIDBBIDdgIKCgwKBQQDAgMFEgN2CxEK
DAoFBAMCAwESA3YSIQoMCgUEAwIDAxIDdiQlCrMBCgIEBBIFfACAAQEapQEgTm9kZUdyb3Vw
IHJlcHJlc2VudHMgYSBkeW5hbWljIGNvbGxlY3Rpb24gb2Ygbm9kZXMgdGhhdCBzYXRpc2Z5
IHNwZWNpZmljCiBjcml0ZXJpYS4gQSBub2RlIGlzIGNvbnNpZGVyZWQgcGFydCBvZiB0aGlz
IGdyb3VwIGlmIGl0IG1hdGNoZXMgdGhlIGRlZmluZWQKIGNvbnN0cmFpbnRzLgoKCgoDBAQB
EgN8CBEKmAEKBAQEAgASA38CShqKASBPcHRpb25hbC4gQSBub2RlIG11c3QgaGF2ZSBhdCBs
ZWFzdCBvbmUgb2YgdGhlc2UgbGFiZWxzIHRvIGJlIGluY2x1ZGVkIGluCiB0aGUgZ3JvdXAu
IElmIGVtcHR5IG9yIHVuc2V0LCB0aGlzIGNvbnN0cmFpbnQgaXMgbm90IGFwcGxpZWQuCgoM
CgUEBAIABBIDfwIKCgwKBQQEAgAFEgN/CxEKDAoFBAQCAAESA38SHAoMCgUEBAIAAxIDfx8g
CgwKBQQEAgAIEgN/IUkKDwoIBAQCAAicCAASA38iSApNCgIEBRIGgwEApgEBGj8gRWRnZVJ1
bGUgZGVmaW5lcyB0aGUgY29ubmVjdGlvbiBydWxlcyBmb3Igbm9kZXMgaW4gdGhlIGdyYXBo
LgoKCwoDBAUBEgSDAQgQCpQCCgQEBQgAEgaKAQKSAQMagwIgU3BlY2lmaWVzIHRoZSBzb3Vy
Y2UgY3JpdGVyaWEgZm9yIHRoaXMgZWRnZSBydWxlLgogQW4gZWRnZSBydWxlIG11c3QgZGVm
aW5lIGl0cyBzb3VyY2UgZWl0aGVyIHN0YXRpY2FsbHkgdmlhIGEgc3BlY2lmaWMKIG5vZGUg
dHlwZSwgb3IgZHluYW1pY2FsbHkgdmlhIGEgZ3JvdXAgb2Ygbm9kZXMgdGhhdCBtYXRjaCBn
aXZlbgogY29uc3RyYWludHMuCgogVGhpcyB0YWtlcyBwcmVjZWRlbmNlIG92ZXIgdGhlIGBz
b3VyY2Vfbm9kZV90eXBlYCBmaWVsZC4KCg0KBQQFCAABEgSKAQgTCl0KBAQFAgASBI0BBEYa
TyBPcHRpb25hbC4gVGhlIHNwZWNpZmljIG5vZGUgdHlwZSBuYW1lIHRoYXQgYWN0cyBhcyB0
aGUgc291cmNlIGZvciB0aGlzCiBlZGdlLgoKDQoFBAUCAAUSBI0BBAoKDQoFBAUCAAESBI0B
CxgKDQoFBAUCAAMSBI0BGxwKDQoFBAUCAAgSBI0BHUUKEAoIBAUCAAicCAASBI0BHkQKfAoE
BAUCARIEkQEEShpuIE9wdGlvbmFsLiBBIGR5bmFtaWMgZ3JvdXAgb2Ygbm9kZXMsIGRlZmlu
ZWQgYnkgbGFiZWwgY29uc3RyYWludHMsIHRoYXQKIGNhbiBhY3QgYXMgdGhlIHNvdXJjZSBm
b3IgdGhpcyBlZGdlLgoKDQoFBAUCAQYSBJEBBA0KDQoFBAUCAQESBJEBDhwKDQoFBAUCAQMS
BJEBHyAKDQoFBAUCAQgSBJEBIUkKEAoIBAUCAQicCAASBJEBIkgKowIKBAQFCAESBpoBAqIB
AxqSAiBTcGVjaWZpZXMgdGhlIGRlc3RpbmF0aW9uIGNyaXRlcmlhIGZvciB0aGlzIGVkZ2Ug
cnVsZS4KIEFuIGVkZ2UgcnVsZSBtdXN0IGRlZmluZSBpdHMgZGVzdGluYXRpb24gZWl0aGVy
IHN0YXRpY2FsbHkgdmlhIGEgc3BlY2lmaWMKIG5vZGUgdHlwZSwgb3IgZHluYW1pY2FsbHkg
dmlhIGEgZ3JvdXAgb2Ygbm9kZXMgdGhhdCBtYXRjaCBnaXZlbgogY29uc3RyYWludHMuCgog
VGhpcyB0YWtlcyBwcmVjZWRlbmNlIG92ZXIgdGhlIGBkZXN0aW5hdGlvbl9ub2RlX3R5cGVg
IGZpZWxkLgoKDQoFBAUIAQESBJoBCBgKYgoEBAUCAhIEnQEERxpUIE9wdGlvbmFsLiBUaGUg
c3BlY2lmaWMgbm9kZSB0eXBlIG5hbWUgdGhhdCBhY3RzIGFzIHRoZSBkZXN0aW5hdGlvbiBm
b3IKIHRoaXMgZWRnZS4KCg0KBQQFAgIFEgSdAQQKCg0KBQQFAgIBEgSdAQsZCg0KBQQFAgID
EgSdARwdCg0KBQQFAgIIEgSdAR5GChAKCAQFAgIInAgAEgSdAR9FCoEBCgQEBQIDEgShAQRL
GnMgT3B0aW9uYWwuIEEgZHluYW1pYyBncm91cCBvZiBub2RlcywgZGVmaW5lZCBieSBsYWJl
bCBjb25zdHJhaW50cywgdGhhdAogY2FuIGFjdCBhcyB0aGUgZGVzdGluYXRpb24gZm9yIHRo
aXMgZWRnZS4KCg0KBQQFAgMGEgShAQQNCg0KBQQFAgMBEgShAQ4dCg0KBQQFAgMDEgShASAh
Cg0KBQQFAgMIEgShASJKChAKCAQFAgMInAgAEgShASNJCjoKBAQFAgQSBKUBAkAaLCBPcHRp
b25hbC4gTmFtZSBvZiB0aGUgY29ubmVjdGVkIGVkZ2UgdHlwZS4KCg0KBQQFAgQFEgSlAQII
Cg0KBQQFAgQBEgSlAQkSCg0KBQQFAgQDEgSlARUWCg0KBQQFAgQIEgSlARc/ChAKCAQFAgQI
nAgAEgSlARg+CkYKAgQGEgapAQCyAQEaOCBJZGVudGlmaWVyIGZvciB0aGUgbGFiZWwgYW5k
IGNvcnJlc3BvbmRpbmcgcHJvcGVydGllcy4KCgsKAwQGARIEqQEIFwoxCgQEBgIAEgSrAQIT
GiMgRnVsbCBxdWFsaWZpZWQgbmFtZSBvZiB0aGUgbGFiZWwuCgoNCgUEBgIABRIEqwECCAoN
CgUEBgIAARIEqwEJDgoNCgUEBgIAAxIEqwEREgo9CgQEBgIBEgSuAQIjGi8gTGlzdCBvZiBw
cm9wZXJ0aWVzIGFzc29jaWF0ZWQgd2l0aCB0aGUgbGFiZWwuCgoNCgUEBgIBBBIErgECCgoN
CgUEBgIBBhIErgELEwoNCgUEBgIBARIErgEUHgoNCgUEBgIBAxIErgEhIgo6CgQEBgICEgSx
AQIZGiwgQSBodW1hbi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgbGFiZWwuCgoNCgUE
BgICBRIEsQECCAoNCgUEBgICARIEsQEJFAoNCgUEBgICAxIEsQEXGApHCgIEBxIGtQEAzQEB
GjkgUHJvcGVydHkgZGVmaW5lcyB0aGUgc2NoZW1hIG9mIGEgcHJvcGVydHkgaW4gdGhlIGdy
YXBoLgoKCwoDBAcBEgS1AQgQCjcKBAQHCAASBrgBAsQBAxonIFJFUVVJUkVECiBWYWx1ZSB0
eXBlIG9mIHRoZSBwcm9wZXJ0eS4KCg0KBQQHCAABEgS4AQgNCk8KBAQHAgASBLoBBCEaQSBT
dHJpbmdWYWx1ZSByZXByZXNlbnRzIGEgcHJvcGVydHkgdGhhdCBoYXMgYSBzdHJpbmcgdmFs
dWUgdHlwZS4KCg0KBQQHAgAGEgS6AQQPCg0KBQQHAgABEgS6ARAcCg0KBQQHAgADEgS6AR8g
Ck4KBAQHAgESBL0BBBsaQCBJbnRWYWx1ZSByZXByZXNlbnRzIGEgcHJvcGVydHkgdGhhdCBo
YXMgYW4gaW50ZWdlciB2YWx1ZSB0eXBlLgoKDQoFBAcCAQYSBL0BBAwKDQoFBAcCAQESBL0B
DRYKDQoFBAcCAQMSBL0BGRoKTgoEBAcCAhIEwAEEHRpAIEJvb2xWYWx1ZSByZXByZXNlbnRz
IGEgcHJvcGVydHkgdGhhdCBoYXMgYSBib29sZWFuIHZhbHVlIHR5cGUuCgoNCgUEBwICBhIE
wAEEDQoNCgUEBwICARIEwAEOGAoNCgUEBwICAxIEwAEbHApPCgQEBwIDEgTDAQQhGkEgRG91
YmxlVmFsdWUgcmVwcmVzZW50cyBhIHByb3BlcnR5IHRoYXQgaGFzIGEgZG91YmxlIHZhbHVl
IHR5cGUuCgoNCgUEBwIDBhIEwwEEDwoNCgUEBwIDARIEwwEQHAoNCgUEBwIDAxIEwwEfIAqH
AQoEBAcCBBIEyAECEhp5IGBuYW1lYCBpcyB0aGUga2V5IHN0cmluZyB0byBpZGVudGlmeSB0
aGUgcHJvcGVydHkgaW4gYE5vZGVgcyAmIGBFZGdlYHMuCiBFeGFtcGxlczogYFByb2plY3RJ
ZGAsIGBCYXNlL2Rpc3BsYXlOYW1lYCBldGMuCgoNCgUEBwIEBRIEyAECCAoNCgUEBwIEARIE
yAEJDQoNCgUEBwIEAxIEyAEQEQqYAQoEBAcCBRIEzAECGhqJASBBIGh1bWFuLXJlYWRhYmxl
IGRlc2NyaXB0aW9uIG9mIHRoZSBgUHJvcGVydHlUeXBlYCwgZXhwbGFpbmluZyBpdHMgbWVh
bmluZywKIHB1cnBvc2UsIGFuZCBhbnkgY29uc3RyYWludHMgb3IgZXhwZWN0YXRpb25zIG9u
IGl0cyB2YWx1ZS4KCg0KBQQHAgUFEgTMAQIICg0KBQQHAgUBEgTMAQkUCg0KBQQHAgUDEgTM
ARcZCk8KAgQIEgbQAQDZAQEaQSBTdHJpbmdWYWx1ZSByZXByZXNlbnRzIGEgcHJvcGVydHkg
dGhhdCBoYXMgYSBzdHJpbmcgdmFsdWUgdHlwZS4KCgsKAwQIARIE0AEIEwo7CgQECAIAEgTT
AQIUGi0gT1BUSU9OQUwKIFdoZXRoZXIgdGhlIHByb3BlcnR5IGlzIHJlcGVhdGVkLgoKDQoF
BAgCAAUSBNMBAgYKDQoFBAgCAAESBNMBBw8KDQoFBAgCAAMSBNMBEhMKfgoEBAgCARIE2AEC
JRpwIE9QVElPTkFMCiBBbGxvd2VkIHZhbHVlcyBmb3IgdGhlIHByb3BlcnR5LiBJZiBwcm92
aWRlZCwgdGhlIHByb3BlcnR5IHZhbHVlIG11c3QgYmUKIG9uZSBvZiB0aGUgYWxsb3dlZCB2
YWx1ZXMuCgoNCgUECAIBBBIE2AECCgoNCgUECAIBBRIE2AELEQoNCgUECAIBARIE2AESIAoN
CgUECAIBAxIE2AEjJApOCgIECRIG3AEA5QEBGkAgSW50VmFsdWUgcmVwcmVzZW50cyBhIHBy
b3BlcnR5IHRoYXQgaGFzIGFuIGludGVnZXIgdmFsdWUgdHlwZS4KCgsKAwQJARIE3AEIEAo7
CgQECQIAEgTfAQIUGi0gT1BUSU9OQUwKIFdoZXRoZXIgdGhlIHByb3BlcnR5IGlzIHJlcGVh
dGVkLgoKDQoFBAkCAAUSBN8BAgYKDQoFBAkCAAESBN8BBw8KDQoFBAkCAAMSBN8BEhMKfgoE
BAkCARIE5AECJBpwIE9QVElPTkFMCiBBbGxvd2VkIHZhbHVlcyBmb3IgdGhlIHByb3BlcnR5
LiBJZiBwcm92aWRlZCwgdGhlIHByb3BlcnR5IHZhbHVlIG11c3QgYmUKIG9uZSBvZiB0aGUg
YWxsb3dlZCB2YWx1ZXMuCgoNCgUECQIBBBIE5AECCgoNCgUECQIBBRIE5AELEAoNCgUECQIB
ARIE5AERHwoNCgUECQIBAxIE5AEiIwpOCgIEChIG6AEA8QEBGkAgQm9vbFZhbHVlIHJlcHJl
c2VudHMgYSBwcm9wZXJ0eSB0aGF0IGhhcyBhIGJvb2xlYW4gdmFsdWUgdHlwZS4KCgsKAwQK
ARIE6AEIEQo7CgQECgIAEgTrAQIUGi0gT1BUSU9OQUwKIFdoZXRoZXIgdGhlIHByb3BlcnR5
IGlzIHJlcGVhdGVkLgoKDQoFBAoCAAUSBOsBAgYKDQoFBAoCAAESBOsBBw8KDQoFBAoCAAMS
BOsBEhMKfgoEBAoCARIE8AECIxpwIE9QVElPTkFMCiBBbGxvd2VkIHZhbHVlcyBmb3IgdGhl
IHByb3BlcnR5LiBJZiBwcm92aWRlZCwgdGhlIHByb3BlcnR5IHZhbHVlIG11c3QgYmUKIG9u
ZSBvZiB0aGUgYWxsb3dlZCB2YWx1ZXMuCgoNCgUECgIBBBIE8AECCgoNCgUECgIBBRIE8AEL
DwoNCgUECgIBARIE8AEQHgoNCgUECgIBAxIE8AEhIgpPCgIECxIG9AEA/QEBGkEgRG91Ymxl
VmFsdWUgcmVwcmVzZW50cyBhIHByb3BlcnR5IHRoYXQgaGFzIGEgZG91YmxlIHZhbHVlIHR5
cGUuCgoLCgMECwESBPQBCBMKOwoEBAsCABIE9wECFBotIE9QVElPTkFMCiBXaGV0aGVyIHRo
ZSBwcm9wZXJ0eSBpcyByZXBlYXRlZC4KCg0KBQQLAgAFEgT3AQIGCg0KBQQLAgABEgT3AQcP
Cg0KBQQLAgADEgT3ARITCn4KBAQLAgESBPwBAiUacCBPUFRJT05BTAogQWxsb3dlZCB2YWx1
ZXMgZm9yIHRoZSBwcm9wZXJ0eS4gSWYgcHJvdmlkZWQsIHRoZSBwcm9wZXJ0eSB2YWx1ZSBt
dXN0IGJlCiBvbmUgb2YgdGhlIGFsbG93ZWQgdmFsdWVzLgoKDQoFBAsCAQQSBPwBAgoKDQoF
BAsCAQUSBPwBCxEKDQoFBAsCAQESBPwBEiAKDQoFBAsCAQMSBPwBIyRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apptopology::V1::Schema::Domain ===
    # Fields for Domain
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::Schema ===
    # Fields for Schema
    # Field: name Type: 9 ()
    # Field: node_types Type: 11 (.google.cloud.apptopology.v1.NodeType)
    # Field: edge_types Type: 11 (.google.cloud.apptopology.v1.EdgeType)
    # Field: label_properties Type: 11 (.google.cloud.apptopology.v1.LabelProperties)
    # Field: edge_rules Type: 11 (.google.cloud.apptopology.v1.EdgeRule)

# === Message: Google::Cloud::Apptopology::V1::Schema::NodeType ===
    # Fields for NodeType
    # Field: type Type: 9 ()
    # Field: labels Type: 9 ()
    # Field: description Type: 9 ()
    # Field: optional_labels Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::EdgeType ===
    # Fields for EdgeType
    # Field: type Type: 9 ()
    # Field: labels Type: 9 ()
    # Field: description Type: 9 ()
    # Field: optional_labels Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::NodeGroup ===
    # Fields for NodeGroup
    # Field: any_labels Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::EdgeRule ===
    # Fields for EdgeRule
    # Field: src_node_type Type: 9 ()
    # Field: src_node_group Type: 11 (.google.cloud.apptopology.v1.NodeGroup)
    # Field: dest_node_type Type: 9 ()
    # Field: dest_node_group Type: 11 (.google.cloud.apptopology.v1.NodeGroup)
    # Field: edge_type Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::LabelProperties ===
    # Fields for LabelProperties
    # Field: label Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.apptopology.v1.Property)
    # Field: description Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::Property ===
    # Fields for Property
    # Field: string_value Type: 11 (.google.cloud.apptopology.v1.StringValue)
    # Field: int_value Type: 11 (.google.cloud.apptopology.v1.IntValue)
    # Field: bool_value Type: 11 (.google.cloud.apptopology.v1.BoolValue)
    # Field: double_value Type: 11 (.google.cloud.apptopology.v1.DoubleValue)
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::StringValue ===
    # Fields for StringValue
    # Field: repeated Type: 8 ()
    # Field: allowed_values Type: 9 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::IntValue ===
    # Fields for IntValue
    # Field: repeated Type: 8 ()
    # Field: allowed_values Type: 3 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::BoolValue ===
    # Fields for BoolValue
    # Field: repeated Type: 8 ()
    # Field: allowed_values Type: 8 ()

# === Message: Google::Cloud::Apptopology::V1::Schema::DoubleValue ===
    # Fields for DoubleValue
    # Field: repeated Type: 8 ()
    # Field: allowed_values Type: 1 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apptopology::V1::Schema - Compiled Protocol Buffers messages for google/cloud/apptopology/v1/schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Apptopology::V1::Schema;

    my $msg = Google::Cloud::Apptopology::V1::Schema::Domain->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apptopology::V1::Schema::Domain->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apptopology/v1/schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apptopology::V1::Schema::Domain

Domain is a pre-defined topology query domain. Each topology domain
contains a set of nodes and edges.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The pre-defined topology domain.
Currently only SRE, DEVOPS, and SECURITY are available.
Format: `projects/{project}/locations/{location}/domains/{domain}`

=back

=head2 Google::Cloud::Apptopology::V1::Schema::Schema

Schema is a collection of supported node & edge labels and properties for an
overlay.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the schema.
Format:
`projects/{project}/locations/{location}/domains/{domain}/schema`

=item * C<< $msg->node_types() >> / C<< $msg->node_types($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::NodeType>)

A list of `NodeType`s defined within this schema.
Refer to the documentation of `NodeType` for more details.

=item * C<< $msg->edge_types() >> / C<< $msg->edge_types($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::EdgeType>)

A list of `EdgeType`s defined within this schema.
Refer to the documentation of `EdgeType` for more details.

=item * C<< $msg->label_properties() >> / C<< $msg->label_properties($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::LabelProperties>)

A list of supported labels and corresponding properties.

=item * C<< $msg->edge_rules() >> / C<< $msg->edge_rules($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::EdgeRule>)

Edge rules. These will indicate which node types can be connected and
through what edge type. This is a list of (source_node_type, edge_type,
destination_node_type) tuples.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::NodeType

NodeType defines the schema of a node type in the graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

REQUIRED
Name of the node type.
This name is used to access the node type while defining the schema.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<String>

Labels attached to the node. Composable, namespaced building blocks that
define core attributes through associated properties. Multiple labels
aggregate to fully specify the functional traits and property schema of the
node type.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human-readable description of the `NodeType`.

=item * C<< $msg->optional_labels() >> / C<< $msg->optional_labels($value) >>

Type: C<String>

A node of this node type can have 0 or more of these labels. These node
objects of this node type will have these labels alongside the
required labels.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::EdgeType

EdgeType defines the schema of an edge type in the graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

REQUIRED
Name of the edge type.
This name is used to access the edge type while defining the schema.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<String>

Labels attached to the edge. Composable, namespaced building blocks that
define core attributes through associated properties. Multiple labels
aggregate to fully specify the functional traits and property schema of the
edge type.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human-readable description of the `EdgeType`.

=item * C<< $msg->optional_labels() >> / C<< $msg->optional_labels($value) >>

Type: C<String>

An edge of this edge type can have 0 or more of these labels. These edge
objects of this edge type will have these labels alongside the
required labels.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::NodeGroup

NodeGroup represents a dynamic collection of nodes that satisfy specific
criteria. A node is considered part of this group if it matches the defined
constraints.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->any_labels() >> / C<< $msg->any_labels($value) >>

Type: C<String>

Optional. A node must have at least one of these labels to be included in
the group. If empty or unset, this constraint is not applied.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::EdgeRule

EdgeRule defines the connection rules for nodes in the graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->src_node_type() >> / C<< $msg->src_node_type($value) >>

Type: C<String>

Optional. The specific node type name that acts as the source for this
edge.

=item * C<< $msg->src_node_group() >> / C<< $msg->src_node_group($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::NodeGroup>)

Optional. A dynamic group of nodes, defined by label constraints, that
can act as the source for this edge.

=item * C<< $msg->dest_node_type() >> / C<< $msg->dest_node_type($value) >>

Type: C<String>

Optional. The specific node type name that acts as the destination for
this edge.

=item * C<< $msg->dest_node_group() >> / C<< $msg->dest_node_group($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::NodeGroup>)

Optional. A dynamic group of nodes, defined by label constraints, that
can act as the destination for this edge.

=item * C<< $msg->edge_type() >> / C<< $msg->edge_type($value) >>

Type: C<String>

Optional. Name of the connected edge type.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::LabelProperties

Identifier for the label and corresponding properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<String>

Full qualified name of the label.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::Property>)

List of properties associated with the label.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human-readable description of the label.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::Property

Property defines the schema of a property in the graph.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::StringValue>)

StringValue represents a property that has a string value type.

=item * C<< $msg->int_value() >> / C<< $msg->int_value($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::IntValue>)

IntValue represents a property that has an integer value type.

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::BoolValue>)

BoolValue represents a property that has a boolean value type.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Message> (L<Google::Cloud::Apptopology::V1::Schema::DoubleValue>)

DoubleValue represents a property that has a double value type.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

`name` is the key string to identify the property in `Node`s & `Edge`s.
Examples: `ProjectId`, `Base/displayName` etc.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human-readable description of the `PropertyType`, explaining its meaning,
purpose, and any constraints or expectations on its value.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::StringValue

StringValue represents a property that has a string value type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repeated() >> / C<< $msg->repeated($value) >>

Type: C<Bool>

OPTIONAL
Whether the property is repeated.

=item * C<< $msg->allowed_values() >> / C<< $msg->allowed_values($value) >>

Type: C<String>

OPTIONAL
Allowed values for the property. If provided, the property value must be
one of the allowed values.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::IntValue

IntValue represents a property that has an integer value type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repeated() >> / C<< $msg->repeated($value) >>

Type: C<Bool>

OPTIONAL
Whether the property is repeated.

=item * C<< $msg->allowed_values() >> / C<< $msg->allowed_values($value) >>

Type: C<Int64>

OPTIONAL
Allowed values for the property. If provided, the property value must be
one of the allowed values.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::BoolValue

BoolValue represents a property that has a boolean value type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repeated() >> / C<< $msg->repeated($value) >>

Type: C<Bool>

OPTIONAL
Whether the property is repeated.

=item * C<< $msg->allowed_values() >> / C<< $msg->allowed_values($value) >>

Type: C<Bool>

OPTIONAL
Allowed values for the property. If provided, the property value must be
one of the allowed values.

=back

=head2 Google::Cloud::Apptopology::V1::Schema::DoubleValue

DoubleValue represents a property that has a double value type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repeated() >> / C<< $msg->repeated($value) >>

Type: C<Bool>

OPTIONAL
Whether the property is repeated.

=item * C<< $msg->allowed_values() >> / C<< $msg->allowed_values($value) >>

Type: C<Double>

OPTIONAL
Allowed values for the property. If provided, the property value must be
one of the allowed values.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apptopology::V1::Schema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
