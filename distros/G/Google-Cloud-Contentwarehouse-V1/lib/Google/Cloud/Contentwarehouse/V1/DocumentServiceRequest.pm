package Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest;

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
    eval { require Google::Cloud::Contentwarehouse::V1::Common };
    eval { require Google::Cloud::Contentwarehouse::V1::Document };
    eval { require Google::Cloud::Contentwarehouse::V1::Filters };
    eval { require Google::Cloud::Contentwarehouse::V1::Histogram };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9kb2N1bWVudF9zZXJ2aWNlX3Jl
cXVlc3QucHJvdG8SIGdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1n
b29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9jb21tb24ucHJvdG8aL2dvb2dsZS9j
bG91ZC9jb250ZW50d2FyZWhvdXNlL3YxL2RvY3VtZW50LnByb3RvGi5nb29nbGUvY2xvdWQv
Y29udGVudHdhcmVob3VzZS92MS9maWx0ZXJzLnByb3RvGjBnb29nbGUvY2xvdWQvY29udGVu
dHdhcmVob3VzZS92MS9oaXN0b2dyYW0ucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnBy
b3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byL3AgoVQ2xvdWRBSURvY3Vt
ZW50T3B0aW9uEj4KG2VuYWJsZV9lbnRpdGllc19jb252ZXJzaW9ucxgBIAEoCFIZZW5hYmxl
RW50aXRpZXNDb252ZXJzaW9ucxLBAQoqY3VzdG9taXplZF9lbnRpdGllc19wcm9wZXJ0aWVz
X2NvbnZlcnNpb25zGAIgAygLMmQuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEu
Q2xvdWRBSURvY3VtZW50T3B0aW9uLkN1c3RvbWl6ZWRFbnRpdGllc1Byb3BlcnRpZXNDb252
ZXJzaW9uc0VudHJ5UidjdXN0b21pemVkRW50aXRpZXNQcm9wZXJ0aWVzQ29udmVyc2lvbnMa
WgosQ3VzdG9taXplZEVudGl0aWVzUHJvcGVydGllc0NvbnZlcnNpb25zRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASLqAwoVQ3JlYXRlRG9jdW1l
bnRSZXF1ZXN0EkgKBnBhcmVudBgBIAEoCUIw4EEC+kEqCihjb250ZW50d2FyZWhvdXNlLmdv
b2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSSwoIZG9jdW1lbnQYAiABKAsyKi5nb29n
bGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5Eb2N1bWVudEID4EECUghkb2N1bWVudBJc
ChByZXF1ZXN0X21ldGFkYXRhGAMgASgLMjEuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91
c2UudjEuUmVxdWVzdE1ldGFkYXRhUg9yZXF1ZXN0TWV0YWRhdGESLQoGcG9saWN5GAQgASgL
MhUuZ29vZ2xlLmlhbS52MS5Qb2xpY3lSBnBvbGljeRJwChhjbG91ZF9haV9kb2N1bWVudF9v
cHRpb24YBSABKAsyNy5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5DbG91ZEFJ
RG9jdW1lbnRPcHRpb25SFWNsb3VkQWlEb2N1bWVudE9wdGlvbhI7CgtjcmVhdGVfbWFzaxgG
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCmNyZWF0ZU1hc2siuAEKEkdldERv
Y3VtZW50UmVxdWVzdBJECgRuYW1lGAEgASgJQjDgQQL6QSoKKGNvbnRlbnR3YXJlaG91c2Uu
Z29vZ2xlYXBpcy5jb20vRG9jdW1lbnRSBG5hbWUSXAoQcmVxdWVzdF9tZXRhZGF0YRgCIAEo
CzIxLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJlcXVlc3RNZXRhZGF0YVIP
cmVxdWVzdE1ldGFkYXRhItIDChVVcGRhdGVEb2N1bWVudFJlcXVlc3QSRAoEbmFtZRgBIAEo
CUIw4EEC+kEqCihjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50UgRu
YW1lEksKCGRvY3VtZW50GAIgASgLMiouZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2Uu
djEuRG9jdW1lbnRCA+BBAlIIZG9jdW1lbnQSXAoQcmVxdWVzdF9tZXRhZGF0YRgDIAEoCzIx
Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJlcXVlc3RNZXRhZGF0YVIPcmVx
dWVzdE1ldGFkYXRhEnAKGGNsb3VkX2FpX2RvY3VtZW50X29wdGlvbhgFIAEoCzI3Lmdvb2ds
ZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkNsb3VkQUlEb2N1bWVudE9wdGlvblIVY2xv
dWRBaURvY3VtZW50T3B0aW9uElYKDnVwZGF0ZV9vcHRpb25zGAYgASgLMi8uZ29vZ2xlLmNs
b3VkLmNvbnRlbnR3YXJlaG91c2UudjEuVXBkYXRlT3B0aW9uc1INdXBkYXRlT3B0aW9ucyK7
AQoVRGVsZXRlRG9jdW1lbnRSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpBKgooY29udGVu
dHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVudFIEbmFtZRJcChByZXF1ZXN0X21l
dGFkYXRhGAIgASgLMjEuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUmVxdWVz
dE1ldGFkYXRhUg9yZXF1ZXN0TWV0YWRhdGEiiQYKFlNlYXJjaERvY3VtZW50c1JlcXVlc3QS
SAoGcGFyZW50GAEgASgJQjDgQQL6QSoKKGNvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5j
b20vTG9jYXRpb25SBnBhcmVudBJcChByZXF1ZXN0X21ldGFkYXRhGAMgASgLMjEuZ29vZ2xl
LmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUmVxdWVzdE1ldGFkYXRhUg9yZXF1ZXN0TWV0
YWRhdGESVgoOZG9jdW1lbnRfcXVlcnkYBCABKAsyLy5nb29nbGUuY2xvdWQuY29udGVudHdh
cmVob3VzZS52MS5Eb2N1bWVudFF1ZXJ5Ug1kb2N1bWVudFF1ZXJ5EhYKBm9mZnNldBgFIAEo
BVIGb2Zmc2V0EhsKCXBhZ2Vfc2l6ZRgGIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgH
IAEoCVIJcGFnZVRva2VuEhkKCG9yZGVyX2J5GAggASgJUgdvcmRlckJ5El0KEWhpc3RvZ3Jh
bV9xdWVyaWVzGAkgAygLMjAuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuSGlz
dG9ncmFtUXVlcnlSEGhpc3RvZ3JhbVF1ZXJpZXMSLAoScmVxdWlyZV90b3RhbF9zaXplGAog
ASgIUhByZXF1aXJlVG90YWxTaXplEnQKEXRvdGFsX3Jlc3VsdF9zaXplGAwgASgOMkguZ29v
Z2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuU2VhcmNoRG9jdW1lbnRzUmVxdWVzdC5U
b3RhbFJlc3VsdFNpemVSD3RvdGFsUmVzdWx0U2l6ZRIiCg1xYV9zaXplX2xpbWl0GAsgASgF
UgtxYVNpemVMaW1pdCJZCg9Ub3RhbFJlc3VsdFNpemUSIQodVE9UQUxfUkVTVUxUX1NJWkVf
VU5TUEVDSUZJRUQQABISCg5FU1RJTUFURURfU0laRRABEg8KC0FDVFVBTF9TSVpFEAIizwEK
E0xvY2tEb2N1bWVudFJlcXVlc3QSRAoEbmFtZRgBIAEoCUIw4EEC+kEqCihjb250ZW50d2Fy
ZWhvdXNlLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50UgRuYW1lEiMKDWNvbGxlY3Rpb25faWQY
AiABKAlSDGNvbGxlY3Rpb25JZBJNCgxsb2NraW5nX3VzZXIYAyABKAsyKi5nb29nbGUuY2xv
dWQuY29udGVudHdhcmVob3VzZS52MS5Vc2VySW5mb1ILbG9ja2luZ1VzZXIitQEKD0ZldGNo
QWNsUmVxdWVzdBIfCghyZXNvdXJjZRgBIAEoCUID4EECUghyZXNvdXJjZRJcChByZXF1ZXN0
X21ldGFkYXRhGAIgASgLMjEuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUmVx
dWVzdE1ldGFkYXRhUg9yZXF1ZXN0TWV0YWRhdGESIwoNcHJvamVjdF9vd25lchgDIAEoCFIM
cHJvamVjdE93bmVyIucBCg1TZXRBY2xSZXF1ZXN0Eh8KCHJlc291cmNlGAEgASgJQgPgQQJS
CHJlc291cmNlEjIKBnBvbGljeRgCIAEoCzIVLmdvb2dsZS5pYW0udjEuUG9saWN5QgPgQQJS
BnBvbGljeRJcChByZXF1ZXN0X21ldGFkYXRhGAMgASgLMjEuZ29vZ2xlLmNsb3VkLmNvbnRl
bnR3YXJlaG91c2UudjEuUmVxdWVzdE1ldGFkYXRhUg9yZXF1ZXN0TWV0YWRhdGESIwoNcHJv
amVjdF9vd25lchgEIAEoCFIMcHJvamVjdE93bmVyQoMCCiRjb20uZ29vZ2xlLmNsb3VkLmNv
bnRlbnR3YXJlaG91c2UudjFCG0RvY3VtZW50U2VydmljZVJlcXVlc3RQcm90b1ABWlBjbG91
ZC5nb29nbGUuY29tL2dvL2NvbnRlbnR3YXJlaG91c2UvYXBpdjEvY29udGVudHdhcmVob3Vz
ZXBiO2NvbnRlbnR3YXJlaG91c2VwYqoCIEdvb2dsZS5DbG91ZC5Db250ZW50V2FyZWhvdXNl
LlYxygIgR29vZ2xlXENsb3VkXENvbnRlbnRXYXJlaG91c2VcVjHqAiNHb29nbGU6OkNsb3Vk
OjpDb250ZW50V2FyZWhvdXNlOjpWMUqTaAoHEgUOAOICAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQANwoJCgIDAxIDFQA5CgkKAgMEEgMWADgKCQoCAwUSAxcAOgoJCgIDBhIDGAAkCgkKAgMH
EgMZACoKCAoBCBIDGwA9CgkKAgglEgMbAD0KCAoBCBIDHABnCgkKAggLEgMcAGcKCAoBCBID
HQAiCgkKAggKEgMdACIKCAoBCBIDHgA8CgkKAggIEgMeADwKCAoBCBIDHwA9CgkKAggBEgMf
AD0KCAoBCBIDIAA9CgkKAggpEgMgAD0KCAoBCBIDIQA8CgkKAggtEgMhADwKTQoCBAASBCQA
KgEaQSBSZXF1ZXN0IE9wdGlvbiBmb3IgcHJvY2Vzc2luZyBDbG91ZCBBSSBEb2N1bWVudCBp
biBDVyBEb2N1bWVudC4KCgoKAwQAARIDJAgdCkEKBAQAAgASAyYCJxo0IFdoZXRoZXIgdG8g
Y29udmVydCBhbGwgdGhlIGVudGl0aWVzIHRvIHByb3BlcnRpZXMuCgoMCgUEAAIABRIDJgIG
CgwKBQQAAgABEgMmByIKDAoFBAACAAMSAyYlJgpOCgQEAAIBEgMpAkUaQSBJZiBzZXQsIG9u
bHkgc2VsZWN0ZWQgZW50aXRpZXMgd2lsbCBiZSBjb252ZXJ0ZWQgdG8gcHJvcGVydGllcy4K
CgwKBQQAAgEGEgMpAhUKDAoFBAACAQESAykWQAoMCgUEAAIBAxIDKUNECkEKAgQBEgQtAFAB
GjUgUmVxdWVzdCBtZXNzYWdlIGZvciBEb2N1bWVudFNlcnZpY2UuQ3JlYXRlRG9jdW1lbnQu
CgoKCgMEAQESAy0IHQpjCgQEAQIAEgQwAjUEGlUgUmVxdWlyZWQuIFRoZSBwYXJlbnQgbmFt
ZS4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0
aW9ufS4KCgwKBQQBAgAFEgMwAggKDAoFBAECAAESAzAJDwoMCgUEAQIAAxIDMBITCg0KBQQB
AgAIEgQwFDUDCg8KCAQBAgAInAgAEgMxBCoKDwoHBAECAAifCBIEMgQ0BQowCgQEAQIBEgM4
AkEaIyBSZXF1aXJlZC4gVGhlIGRvY3VtZW50IHRvIGNyZWF0ZS4KCgwKBQQBAgEGEgM4AgoK
DAoFBAECAQESAzgLEwoMCgUEAQIBAxIDOBYXCgwKBQQBAgEIEgM4GEAKDwoIBAECAQicCAAS
AzgZPwpyCgQEAQICEgM8AicaZSBUaGUgbWV0YSBpbmZvcm1hdGlvbiBjb2xsZWN0ZWQgYWJv
dXQgdGhlIGVuZCB1c2VyLCB1c2VkIHRvIGVuZm9yY2UgYWNjZXNzCiBjb250cm9sIGZvciB0
aGUgc2VydmljZS4KCgwKBQQBAgIGEgM8AhEKDAoFBAECAgESAzwSIgoMCgUEAQICAxIDPCUm
CtMBCgQEAQIDEgNCAiIaxQEgRGVmYXVsdCBkb2N1bWVudCBwb2xpY3kgZHVyaW5nIGNyZWF0
aW9uLgogVGhpcyByZWZlcnMgdG8gYW4gSWRlbnRpdHkgYW5kIEFjY2VzcyAoSUFNKSBwb2xp
Y3ksIHdoaWNoIHNwZWNpZmllcyBhY2Nlc3MKIGNvbnRyb2xzIGZvciB0aGUgRG9jdW1lbnQu
CiBDb25kaXRpb25zIGRlZmluZWQgaW4gdGhlIHBvbGljeSB3aWxsIGJlIGlnbm9yZWQuCgoM
CgUEAQIDBhIDQgIWCgwKBQQBAgMBEgNCFx0KDAoFBAECAwMSA0IgIQqUAgoEBAECBBIDSAI1
GoYCIFJlcXVlc3QgT3B0aW9uIGZvciBwcm9jZXNzaW5nIENsb3VkIEFJIERvY3VtZW50IGlu
IERvY3VtZW50IFdhcmVob3VzZS4KIFRoaXMgZmllbGQgb2ZmZXJzIGxpbWl0ZWQgc3VwcG9y
dCBmb3IgbWFwcGluZyBlbnRpdGllcyBmcm9tIENsb3VkIEFJCiBEb2N1bWVudCB0byBXYXJl
aG91c2UgRG9jdW1lbnQuIFBsZWFzZSBjb25zdWx0IHdpdGggcHJvZHVjdCB0ZWFtIGJlZm9y
ZQogdXNpbmcgdGhpcyBmaWVsZCBhbmQgb3RoZXIgYXZhaWxhYmxlIG9wdGlvbnMuCgoMCgUE
AQIEBhIDSAIXCgwKBQQBAgQBEgNIGDAKDAoFBAECBAMSA0gzNArwAQoEBAECBRIDTwIsGuIB
IEZpZWxkIG1hc2sgZm9yIGNyZWF0aW5nIERvY3VtZW50IGZpZWxkcy4gSWYgbWFzayBwYXRo
IGlzIGVtcHR5LAogaXQgbWVhbnMgYWxsIGZpZWxkcyBhcmUgbWFza2VkLgogRm9yIHRoZSBg
RmllbGRNYXNrYCBkZWZpbml0aW9uLAogc2VlCiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xl
LmNvbS9wcm90b2NvbC1idWZmZXJzL2RvY3MvcmVmZXJlbmNlL2dvb2dsZS5wcm90b2J1ZiNm
aWVsZG1hc2suCgoMCgUEAQIFBhIDTwIbCgwKBQQBAgUBEgNPHCcKDAoFBAECBQMSA08qKwo+
CgIEAhIEUwBiARoyIFJlcXVlc3QgbWVzc2FnZSBmb3IgRG9jdW1lbnRTZXJ2aWNlLkdldERv
Y3VtZW50LgoKCgoDBAIBEgNTCBoK6gEKBAQCAgASBFgCXQQa2wEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBkb2N1bWVudCB0byByZXRyaWV2ZS4KIEZvcm1hdDoKIHByb2plY3RzL3tw
cm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9jdW1lbnRzL3tkb2N1bWVu
dF9pZH0gb3IKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vZG9jdW1lbnRzL3JlZmVyZW5jZUlkL3tyZWZlcmVuY2VfaWR9LgoKDAoFBAICAAUSA1gC
CAoMCgUEAgIAARIDWAkNCgwKBQQCAgADEgNYEBEKDQoFBAICAAgSBFgSXQMKDwoIBAICAAic
CAASA1kEKgoPCgcEAgIACJ8IEgRaBFwFCnIKBAQCAgESA2ECJxplIFRoZSBtZXRhIGluZm9y
bWF0aW9uIGNvbGxlY3RlZCBhYm91dCB0aGUgZW5kIHVzZXIsIHVzZWQgdG8gZW5mb3JjZSBh
Y2Nlc3MKIGNvbnRyb2wgZm9yIHRoZSBzZXJ2aWNlLgoKDAoFBAICAQYSA2ECEQoMCgUEAgIB
ARIDYRIiCgwKBQQCAgEDEgNhJSYKQgoCBAMSBWUAgQEBGjUgUmVxdWVzdCBtZXNzYWdlIGZv
ciBEb2N1bWVudFNlcnZpY2UuVXBkYXRlRG9jdW1lbnQuCgoKCgMEAwESA2UIHQrpAQoEBAMC
ABIEawJwBBraASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGRvY3VtZW50IHRvIHVwZGF0
ZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vZG9jdW1lbnRzL3tkb2N1bWVudF9pZH0KIG9yCiBwcm9qZWN0cy97cHJvamVjdF9u
dW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2RvY3VtZW50cy9yZWZlcmVuY2VJZC97cmVm
ZXJlbmNlX2lkfS4KCgwKBQQDAgAFEgNrAggKDAoFBAMCAAESA2sJDQoMCgUEAwIAAxIDaxAR
Cg0KBQQDAgAIEgRrEnADCg8KCAQDAgAInAgAEgNsBCoKDwoHBAMCAAifCBIEbQRvBQowCgQE
AwIBEgNzAkEaIyBSZXF1aXJlZC4gVGhlIGRvY3VtZW50IHRvIHVwZGF0ZS4KCgwKBQQDAgEG
EgNzAgoKDAoFBAMCAQESA3MLEwoMCgUEAwIBAxIDcxYXCgwKBQQDAgEIEgNzGEAKDwoIBAMC
AQicCAASA3MZPwpyCgQEAwICEgN3AicaZSBUaGUgbWV0YSBpbmZvcm1hdGlvbiBjb2xsZWN0
ZWQgYWJvdXQgdGhlIGVuZCB1c2VyLCB1c2VkIHRvIGVuZm9yY2UgYWNjZXNzCiBjb250cm9s
IGZvciB0aGUgc2VydmljZS4KCgwKBQQDAgIGEgN3AhEKDAoFBAMCAgESA3cSIgoMCgUEAwIC
AxIDdyUmCpQCCgQEAwIDEgN9AjUahgIgUmVxdWVzdCBPcHRpb24gZm9yIHByb2Nlc3Npbmcg
Q2xvdWQgQUkgRG9jdW1lbnQgaW4gRG9jdW1lbnQgV2FyZWhvdXNlLgogVGhpcyBmaWVsZCBv
ZmZlcnMgbGltaXRlZCBzdXBwb3J0IGZvciBtYXBwaW5nIGVudGl0aWVzIGZyb20gQ2xvdWQg
QUkKIERvY3VtZW50IHRvIFdhcmVob3VzZSBEb2N1bWVudC4gUGxlYXNlIGNvbnN1bHQgd2l0
aCBwcm9kdWN0IHRlYW0gYmVmb3JlCiB1c2luZyB0aGlzIGZpZWxkIGFuZCBvdGhlciBhdmFp
bGFibGUgb3B0aW9ucy4KCgwKBQQDAgMGEgN9AhcKDAoFBAMCAwESA30YMAoMCgUEAwIDAxID
fTM0CjEKBAQDAgQSBIABAiMaIyBPcHRpb25zIGZvciB0aGUgdXBkYXRlIG9wZXJhdGlvbi4K
Cg0KBQQDAgQGEgSAAQIPCg0KBQQDAgQBEgSAARAeCg0KBQQDAgQDEgSAASEiCkMKAgQEEgaE
AQCUAQEaNSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIERvY3VtZW50U2VydmljZS5EZWxldGVEb2N1
bWVudC4KCgsKAwQEARIEhAEIHQrrAQoEBAQCABIGigECjwEEGtoBIFJlcXVpcmVkLiBUaGUg
bmFtZSBvZiB0aGUgZG9jdW1lbnQgdG8gZGVsZXRlLgogRm9ybWF0OgogcHJvamVjdHMve3By
b2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1bWVudHMve2RvY3VtZW50
X2lkfQogb3IKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vZG9jdW1lbnRzL3JlZmVyZW5jZUlkL3tyZWZlcmVuY2VfaWR9LgoKDQoFBAQCAAUSBIoB
AggKDQoFBAQCAAESBIoBCQ0KDQoFBAQCAAMSBIoBEBEKDwoFBAQCAAgSBooBEo8BAwoQCggE
BAIACJwIABIEiwEEKgoRCgcEBAIACJ8IEgaMAQSOAQUKcwoEBAQCARIEkwECJxplIFRoZSBt
ZXRhIGluZm9ybWF0aW9uIGNvbGxlY3RlZCBhYm91dCB0aGUgZW5kIHVzZXIsIHVzZWQgdG8g
ZW5mb3JjZSBhY2Nlc3MKIGNvbnRyb2wgZm9yIHRoZSBzZXJ2aWNlLgoKDQoFBAQCAQYSBJMB
AhEKDQoFBAQCAQESBJMBEiIKDQoFBAQCAQMSBJMBJSYKRAoCBAUSBpcBAJQCARo2IFJlcXVl
c3QgbWVzc2FnZSBmb3IgRG9jdW1lbnRTZXJ2aWNlLlNlYXJjaERvY3VtZW50cy4KCgsKAwQF
ARIElwEIHgo5CgQEBQQAEgaZAQKjAQMaKSBUaGUgdG90YWwgbnVtYmVyIG9mIG1hdGNoaW5n
IGRvY3VtZW50cy4KCg0KBQQFBAABEgSZAQcWCjsKBgQFBAACABIEmwEEJhorIFRvdGFsIG51
bWJlciBjYWxjdWxhdGlvbiB3aWxsIGJlIHNraXBwZWQuCgoPCgcEBQQAAgABEgSbAQQhCg8K
BwQFBAACAAISBJsBJCUKlwEKBgQFBAACARIEnwEEFxqGASBFc3RpbWF0ZSB0b3RhbCBudW1i
ZXIuIFRoZSB0b3RhbCByZXN1bHQgc2l6ZSB3aWxsIGJlIGFjY3VyYXRlZCB1cCB0bwogMTAs
MDAwLiBUaGlzIG9wdGlvbiB3aWxsIGFkZCBjb3N0IGFuZCBsYXRlbmN5IHRvIHlvdXIgcmVx
dWVzdC4KCg8KBwQFBAACAQESBJ8BBBIKDwoHBAUEAAIBAhIEnwEVFgpNCgYEBQQAAgISBKIB
BBQaPSBJdCBtYXkgYWR2ZXJzZWx5IGltcGFjdCBwZXJmb3JtYW5jZS4gVGhlIGxpbWl0IGlz
IDEwMDAsMDAwLgoKDwoHBAUEAAICARIEogEEDwoPCgcEBQQAAgICEgSiARITCokBCgQEBQIA
EganAQKsAQQaeSBSZXF1aXJlZC4gVGhlIHBhcmVudCwgd2hpY2ggb3ducyB0aGlzIGNvbGxl
Y3Rpb24gb2YgZG9jdW1lbnRzLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9
L2xvY2F0aW9ucy97bG9jYXRpb259LgoKDQoFBAUCAAUSBKcBAggKDQoFBAUCAAESBKcBCQ8K
DQoFBAUCAAMSBKcBEhMKDwoFBAUCAAgSBqcBFKwBAwoQCggEBQIACJwIABIEqAEEKgoRCgcE
BQIACJ8IEgapAQSrAQUKkgEKBAQFAgESBLABAicagwEgVGhlIG1ldGEgaW5mb3JtYXRpb24g
Y29sbGVjdGVkIGFib3V0IHRoZSBlbmQgdXNlciwgdXNlZCB0byBlbmZvcmNlIGFjY2Vzcwog
Y29udHJvbCBhbmQgaW1wcm92ZSB0aGUgc2VhcmNoIHF1YWxpdHkgb2YgdGhlIHNlcnZpY2Uu
CgoNCgUEBQIBBhIEsAECEQoNCgUEBQIBARIEsAESIgoNCgUEBQIBAxIEsAElJgpQCgQEBQIC
EgSzAQIjGkIgUXVlcnkgdXNlZCB0byBzZWFyY2ggYWdhaW5zdCBkb2N1bWVudHMgKGtleXdv
cmQsIGZpbHRlcnMsIGV0Yy4pLgoKDQoFBAUCAgYSBLMBAg8KDQoFBAUCAgESBLMBEB4KDQoF
BAUCAgMSBLMBISIK5wQKBAQFAgMSBMEBAhMa2AQgQW4gaW50ZWdlciB0aGF0IHNwZWNpZmll
cyB0aGUgY3VycmVudCBvZmZzZXQgKHRoYXQgaXMsIHN0YXJ0aW5nIHJlc3VsdAogbG9jYXRp
b24sIGFtb25nc3QgdGhlIGRvY3VtZW50cyBkZWVtZWQgYnkgdGhlIEFQSSBhcyByZWxldmFu
dCkgaW4gc2VhcmNoCiByZXN1bHRzLiBUaGlzIGZpZWxkIGlzIG9ubHkgY29uc2lkZXJlZCBp
ZgogW3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlNlYXJj
aERvY3VtZW50c1JlcXVlc3QucGFnZV90b2tlbl0KIGlzIHVuc2V0LgoKIFRoZSBtYXhpbXVt
IGFsbG93ZWQgdmFsdWUgaXMgNTAwMC4gT3RoZXJ3aXNlIGFuIGVycm9yIGlzIHRocm93bi4K
CiBGb3IgZXhhbXBsZSwgMCBtZWFucyB0byAgcmV0dXJuIHJlc3VsdHMgc3RhcnRpbmcgZnJv
bSB0aGUgZmlyc3QgbWF0Y2hpbmcKIGRvY3VtZW50LCBhbmQgMTAgbWVhbnMgdG8gcmV0dXJu
IGZyb20gdGhlIDExdGggZG9jdW1lbnQuIFRoaXMgY2FuIGJlIHVzZWQKIGZvciBwYWdpbmF0
aW9uLCAoZm9yIGV4YW1wbGUsIHBhZ2VTaXplID0gMTAgYW5kIG9mZnNldCA9IDEwIG1lYW5z
IHRvIHJldHVybgogZnJvbSB0aGUgc2Vjb25kIHBhZ2UpLgoKDQoFBAUCAwUSBMEBAgcKDQoF
BAUCAwESBMEBCA4KDQoFBAUCAwMSBMEBERIK0AEKBAQFAgQSBMYBAhYawQEgQSBsaW1pdCBv
biB0aGUgbnVtYmVyIG9mIGRvY3VtZW50cyByZXR1cm5lZCBpbiB0aGUgc2VhcmNoIHJlc3Vs
dHMuCiBJbmNyZWFzaW5nIHRoaXMgdmFsdWUgYWJvdmUgdGhlIGRlZmF1bHQgdmFsdWUgb2Yg
MTAgY2FuIGluY3JlYXNlIHNlYXJjaAogcmVzcG9uc2UgdGltZS4gVGhlIHZhbHVlIGNhbiBi
ZSBiZXR3ZWVuIDEgYW5kIDEwMC4KCg0KBQQFAgQFEgTGAQIHCg0KBQQFAgQBEgTGAQgRCg0K
BQQFAgQDEgTGARQVCo0CCgQEBQIFEgTMAQIYGv4BIFRoZSB0b2tlbiBzcGVjaWZ5aW5nIHRo
ZSBjdXJyZW50IG9mZnNldCB3aXRoaW4gc2VhcmNoIHJlc3VsdHMuCiBTZWUKIFtTZWFyY2hE
b2N1bWVudHNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5jb250ZW50
d2FyZWhvdXNlLnYxLlNlYXJjaERvY3VtZW50c1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl0K
IGZvciBhbiBleHBsYW5hdGlvbiBvZiBob3cgdG8gb2J0YWluIHRoZSBuZXh0IHNldCBvZiBx
dWVyeSByZXN1bHRzLgoKDQoFBAUCBQUSBMwBAggKDQoFBAUCBQESBMwBCRMKDQoFBAUCBQMS
BMwBFhcKrQUKBAQFAgYSBN0BAhYangUgVGhlIGNyaXRlcmlhIGRldGVybWluaW5nIGhvdyBz
ZWFyY2ggcmVzdWx0cyBhcmUgc29ydGVkLiBGb3Igbm9uLWVtcHR5CiBxdWVyeSwgZGVmYXVs
dCBpcyBgInJlbGV2YW5jZSBkZXNjImAuIEZvciBlbXB0eSBxdWVyeSwgZGVmYXVsdCBpcwog
YCJ1cGxvYWRfZGF0ZSBkZXNjImAuCgogU3VwcG9ydGVkIG9wdGlvbnMgYXJlOgoKICogYCJy
ZWxldmFuY2UgZGVzYyJgOiBCeSByZWxldmFuY2UgZGVzY2VuZGluZywgYXMgZGV0ZXJtaW5l
ZCBieSB0aGUgQVBJCiAgIGFsZ29yaXRobXMuCiAqIGAidXBsb2FkX2RhdGUgZGVzYyJgOiBC
eSB1cGxvYWQgZGF0ZSBkZXNjZW5kaW5nLgogKiBgInVwbG9hZF9kYXRlImA6IEJ5IHVwbG9h
ZCBkYXRlIGFzY2VuZGluZy4KICogYCJ1cGRhdGVfZGF0ZSBkZXNjImA6IEJ5IGxhc3QgdXBk
YXRlZCBkYXRlIGRlc2NlbmRpbmcuCiAqIGAidXBkYXRlX2RhdGUiYDogQnkgbGFzdCB1cGRh
dGVkIGRhdGUgYXNjZW5kaW5nLgogKiBgInJldHJpZXZhbF9pbXBvcnRhbmNlIGRlc2MiYDog
QnkgcmV0cmlldmFsIGltcG9ydGFuY2Ugb2YgcHJvcGVydGllcwogICBkZXNjZW5kaW5nLiBU
aGlzIGZlYXR1cmUgaXMgc3RpbGwgdW5kZXIgZGV2ZWxvcG1lbnQsIHBsZWFzZSBkbyBub3Qg
dXNlCiAgIHVubGVzcyBvdGhlcndpc2UgaW5zdHJ1Y3RlZCB0byBkbyBzby4KCg0KBQQFAgYF
EgTdAQIICg0KBQQFAgYBEgTdAQkRCg0KBQQFAgYDEgTdARQVCq4JCgQEBQIHEgT9AQIwGp8J
IEFuIGV4cHJlc3Npb24gc3BlY2lmeWluZyBhIGhpc3RvZ3JhbSByZXF1ZXN0IGFnYWluc3Qg
bWF0Y2hpbmcKIGRvY3VtZW50cy4gRXhwcmVzc2lvbiBzeW50YXggaXMgYW4gYWdncmVnYXRp
b24gZnVuY3Rpb24gY2FsbCB3aXRoCiBoaXN0b2dyYW0gZmFjZXRzIGFuZCBvdGhlciBvcHRp
b25zLgoKIFRoZSBmb2xsb3dpbmcgYWdncmVnYXRpb24gZnVuY3Rpb25zIGFyZSBzdXBwb3J0
ZWQ6CgogKiBgY291bnQoc3RyaW5nX2hpc3RvZ3JhbV9mYWNldClgOiBDb3VudCB0aGUgbnVt
YmVyIG9mIG1hdGNoaW5nIGVudGl0aWVzCiBmb3IgZWFjaCBkaXN0aW5jdCBhdHRyaWJ1dGUg
dmFsdWUuCgogRGF0YSB0eXBlczoKCiAqIEhpc3RvZ3JhbSBmYWNldCAoYWthIGZpbHRlcmFi
bGUgcHJvcGVydGllcyk6IEZhY2V0IG5hbWVzIHdpdGggZm9ybWF0CiAmbHQ7c2NoZW1hIGlk
Jmd0Oy4mbHQ7ZmFjZXQmZ3Q7LiBGYWNldHMgd2lsbCBoYXZlIHRoZQogZm9ybWF0IG9mOiBg
W2EtekEtWl1bYS16QS1aMC05XzovLS5dYC4gSWYgdGhlIGZhY2V0IGlzIGEgY2hpbGQKIGZh
Y2V0LCB0aGVuIHRoZSBwYXJlbnQgaGllcmFyY2h5IG5lZWRzIHRvIGJlIHNwZWNpZmllZCBz
ZXBhcmF0ZWQgYnkKIGRvdHMgaW4gdGhlIHByZWZpeCBhZnRlciB0aGUgc2NoZW1hIGlkLiBU
aHVzLCB0aGUgZm9ybWF0IGZvciBhIG11bHRpLQogbGV2ZWwgZmFjZXQgaXM6ICZsdDtzY2hl
bWEgaWQmZ3Q7LiZsdDtwYXJlbnQgZmFjZXQgbmFtZSZndDsuCiAmbHQ7Y2hpbGQgZmFjZXQg
bmFtZSZndDsuIEV4YW1wbGU6CiBzY2hlbWExMjMucm9vdF9wYXJlbnRfZmFjZXQubWlkZGxl
X2ZhY2V0LmNoaWxkX2ZhY2V0CiAqIERvY3VtZW50U2NoZW1hSWQ6ICh3aXRoIG5vIHNjaGVt
YSBpZCBwcmVmaXgpIHRvIGdldAogaGlzdG9ncmFtcyBmb3IgZWFjaCBkb2N1bWVudCB0eXBl
IChyZXR1cm5zIHRoZSBzY2hlbWEgaWQgcGF0aCwgZS5nLgogcHJvamVjdHMvMTIzNDUvbG9j
YXRpb25zL3VzLXdlc3QvZG9jdW1lbnRTY2hlbWFzL2FiYzEyMykuCgogRXhhbXBsZSBleHBy
ZXNzaW9uOgoKICogRG9jdW1lbnQgdHlwZSBjb3VudHM6CiAgIGNvdW50KCdEb2N1bWVudFNj
aGVtYUlkJykKCiAqIEZvciBzY2hlbWEgaWQsIGFiYzEyMywgZ2V0IHRoZSBjb3VudHMgZm9y
IE1PUlRHQUdFX1RZUEU6CiAgIGNvdW50KCdhYmMxMjMuTU9SVEdBR0VfVFlQRScpCgoNCgUE
BQIHBBIE/QECCgoNCgUEBQIHBhIE/QELGQoNCgUEBQIHARIE/QEaKwoNCgUEBQIHAxIE/QEu
LwrKAwoEBAUCCBIEiAICHxq7AyBDb250cm9scyBpZiB0aGUgc2VhcmNoIGRvY3VtZW50IHJl
cXVlc3QgcmVxdWlyZXMgdGhlIHJldHVybiBvZiBhIHRvdGFsIHNpemUKIG9mIG1hdGNoZWQg
ZG9jdW1lbnRzLiBTZWUKIFtTZWFyY2hEb2N1bWVudHNSZXNwb25zZS50b3RhbF9zaXplXVtn
b29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5TZWFyY2hEb2N1bWVudHNSZXNwb25z
ZS50b3RhbF9zaXplXS4KCiBFbmFibGluZyB0aGlzIGZsYWcgbWF5IGFkdmVyc2VseSBpbXBh
Y3QgcGVyZm9ybWFuY2UuIEhpbnQ6IElmIHRoaXMgaXMKIHVzZWQgd2l0aCBwYWdpbmF0aW9u
LCBzZXQgdGhpcyBmbGFnIG9uIHRoZSBpbml0aWFsIHF1ZXJ5IGJ1dCBzZXQgdGhpcwogdG8g
ZmFsc2Ugb24gc3Vic2VxdWVudCBwYWdlIGNhbGxzIChrZWVwIHRoZSB0b3RhbCBjb3VudCBs
b2NhbGx5KS4KCiBEZWZhdWx0cyB0byBmYWxzZS4KCg0KBQQFAggFEgSIAgIGCg0KBQQFAggB
EgSIAgcZCg0KBQQFAggDEgSIAhweCuMBCgQEBQIJEgSNAgIpGtQBIENvbnRyb2xzIGlmIHRo
ZSBzZWFyY2ggZG9jdW1lbnQgcmVxdWVzdCByZXF1aXJlcyB0aGUgcmV0dXJuIG9mIGEgdG90
YWwgc2l6ZQogb2YgbWF0Y2hlZCBkb2N1bWVudHMuIFNlZQogW1NlYXJjaERvY3VtZW50c1Jl
c3BvbnNlLnRvdGFsX3NpemVdW2dvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlNl
YXJjaERvY3VtZW50c1Jlc3BvbnNlLnRvdGFsX3NpemVdLgoKDQoFBAUCCQYSBI0CAhEKDQoF
BAUCCQESBI0CEiMKDQoFBAUCCQMSBI0CJigK1gEKBAQFAgoSBJMCAhsaxwEgRXhwZXJpbWVu
dGFsLCBkbyBub3QgdXNlLgogVGhlIGxpbWl0IG9uIHRoZSBudW1iZXIgb2YgZG9jdW1lbnRz
IHJldHVybmVkIGZvciB0aGUgcXVlc3Rpb24tYW5zd2VyaW5nCiBmZWF0dXJlLiBUbyBlbmFi
bGUgdGhlIHF1ZXN0aW9uLWFuc3dlcmluZyBmZWF0dXJlLCBzZXQKIFtEb2N1bWVudFF1ZXJ5
XS5baXNfbmxfcXVlcnldW10gdG8gdHJ1ZS4KCg0KBQQFAgoFEgSTAgIHCg0KBQQFAgoBEgST
AggVCg0KBQQFAgoDEgSTAhgaCkEKAgQGEgaXAgCnAgEaMyBSZXF1ZXN0IG1lc3NhZ2UgZm9y
IERvY3VtZW50U2VydmljZS5Mb2NrRG9jdW1lbnQuCgoLCgMEBgESBJcCCBsKjAEKBAQGAgAS
BpsCAqACBBp8IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgZG9jdW1lbnQgdG8gbG9jay4K
IEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vZG9jdW1lbnRzL3tkb2N1bWVudH0uCgoNCgUEBgIABRIEmwICCAoNCgUEBgIAARIEmwIJ
DQoNCgUEBgIAAxIEmwIQEQoPCgUEBgIACBIGmwISoAIDChAKCAQGAgAInAgAEgScAgQqChEK
BwQGAgAInwgSBp0CBJ8CBQo4CgQEBgIBEgSjAgIbGiogVGhlIGNvbGxlY3Rpb24gdGhlIGRv
Y3VtZW50IGNvbm5lY3RzIHRvLgoKDQoFBAYCAQUSBKMCAggKDQoFBAYCAQESBKMCCRYKDQoF
BAYCAQMSBKMCGRoKPAoEBAYCAhIEpgICHBouIFRoZSB1c2VyIGluZm9ybWF0aW9uIHdobyBs
b2NrcyB0aGUgZG9jdW1lbnQuCgoNCgUEBgICBhIEpgICCgoNCgUEBgICARIEpgILFwoNCgUE
BgICAxIEpgIaGwo8CgIEBxIGqgIAugIBGi4gUmVxdWVzdCBtZXNzYWdlIGZvciBEb2N1bWVu
dFNlcnZpY2UuRmV0Y2hBY2wKCgsKAwQHARIEqgIIFwrOAgoEBAcCABIEsQICPxq/AiBSZXF1
aXJlZC4gUkVRVUlSRUQ6IFRoZSByZXNvdXJjZSBmb3Igd2hpY2ggdGhlIHBvbGljeSBpcyBi
ZWluZyByZXF1ZXN0ZWQuCiBGb3JtYXQgZm9yIGRvY3VtZW50OgogcHJvamVjdHMve3Byb2pl
Y3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1bWVudHMve2RvY3VtZW50X2lk
fS4KIEZvcm1hdCBmb3IgY29sbGVjdGlvbjoKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9LgogRm9y
bWF0IGZvciBwcm9qZWN0OiBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9LgoKDQoFBAcCAAUS
BLECAggKDQoFBAcCAAESBLECCREKDQoFBAcCAAMSBLECFBUKDQoFBAcCAAgSBLECFj4KEAoI
BAcCAAicCAASBLECFz0KcwoEBAcCARIEtQICJxplIFRoZSBtZXRhIGluZm9ybWF0aW9uIGNv
bGxlY3RlZCBhYm91dCB0aGUgZW5kIHVzZXIsIHVzZWQgdG8gZW5mb3JjZSBhY2Nlc3MKIGNv
bnRyb2wgZm9yIHRoZSBzZXJ2aWNlLgoKDQoFBAcCAQYSBLUCAhEKDQoFBAcCAQESBLUCEiIK
DQoFBAcCAQMSBLUCJSYKdAoEBAcCAhIEuQICGRpmIEZvciBHZXQgUHJvamVjdCBBQ0wgb25s
eS4gQXV0aG9yaXphdGlvbiBjaGVjayBmb3IgZW5kIHVzZXIgd2lsbCBiZSBpZ25vcmVkCiB3
aGVuIHByb2plY3Rfb3duZXI9dHJ1ZS4KCg0KBQQHAgIFEgS5AgIGCg0KBQQHAgIBEgS5AgcU
Cg0KBQQHAgIDEgS5AhcYCjsKAgQIEga9AgDiAgEaLSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIERv
Y3VtZW50U2VydmljZS5TZXRBY2wuCgoLCgMECAESBL0CCBUKzgIKBAQIAgASBMQCAj8avwIg
UmVxdWlyZWQuIFJFUVVJUkVEOiBUaGUgcmVzb3VyY2UgZm9yIHdoaWNoIHRoZSBwb2xpY3kg
aXMgYmVpbmcgcmVxdWVzdGVkLgogRm9ybWF0IGZvciBkb2N1bWVudDoKIHByb2plY3RzL3tw
cm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9jdW1lbnRzL3tkb2N1bWVu
dF9pZH0uCiBGb3JtYXQgZm9yIGNvbGxlY3Rpb246CiBwcm9qZWN0cy97cHJvamVjdF9udW1i
ZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS4K
IEZvcm1hdCBmb3IgcHJvamVjdDogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS4KCg0KBQQI
AgAFEgTEAgIICg0KBQQIAgABEgTEAgkRCg0KBQQIAgADEgTEAhQVCg0KBQQIAgAIEgTEAhY+
ChAKCAQIAgAInAgAEgTEAhc9CvoGCgQECAIBEgTZAgJLGusGIFJlcXVpcmVkLiBSRVFVSVJF
RDogVGhlIGNvbXBsZXRlIHBvbGljeSB0byBiZSBhcHBsaWVkIHRvIHRoZSBgcmVzb3VyY2Vg
LgogVGhlIHNpemUgb2YgdGhlIHBvbGljeSBpcyBsaW1pdGVkIHRvIGEgZmV3IDEwcyBvZiBL
Qi4gVGhpcyByZWZlcnMgdG8gYW4KIElkZW50aXR5IGFuZCBBY2Nlc3MgKElBTSkgcG9saWN5
LCB3aGljaCBzcGVjaWZpZXMgYWNjZXNzIGNvbnRyb2xzIGZvciB0aGUKIERvY3VtZW50LgoK
IFlvdSBjYW4gc2V0IEFDTCB3aXRoIGNvbmRpdGlvbiBmb3IgcHJvamVjdHMgb25seS4KCiBT
dXBwb3J0ZWQgb3BlcmF0b3JzIGFyZTogYD1gLCBgIT1gLCBgPGAsIGA8PWAsIGA+YCwgYW5k
IGA+PWAgd2hlcmUKIHRoZSBsZWZ0IG9mIHRoZSBvcGVyYXRvciBpcyBgRG9jdW1lbnRTY2hl
bWFJZGAgb3IgcHJvcGVydHkgbmFtZSBhbmQgdGhlCiByaWdodCBvZiB0aGUgb3BlcmF0b3Ig
aXMgYSBudW1iZXIgb3IgYSBxdW90ZWQgc3RyaW5nLiBZb3UgbXVzdCBlc2NhcGUKIGJhY2tz
bGFzaCAoXFwpIGFuZCBxdW90ZSAoXCIpIGNoYXJhY3RlcnMuCgogQm9vbGVhbiBleHByZXNz
aW9ucyAoQU5EL09SKSBhcmUgc3VwcG9ydGVkIHVwIHRvIDMgbGV2ZWxzIG9mIG5lc3Rpbmcg
KGZvcgogZXhhbXBsZSwgIigoQSBBTkQgQiBBTkQgQykgT1IgRCkgQU5EIEUiKSwgYSBtYXhp
bXVtIG9mIDEwIGNvbXBhcmlzb25zIGFyZQogYWxsb3dlZCBpbiB0aGUgZXhwcmVzc2lvbi4g
VGhlIGV4cHJlc3Npb24gbXVzdCBiZSA8IDYwMDAgYnl0ZXMgaW4gbGVuZ3RoLgoKIFNhbXBs
ZSBjb25kaXRpb246CiAgICAgYCJEb2N1bWVudFNjaGVtYUlkID0gXCJzb21lIHNjaGVtYSBp
ZFwiIE9SIFNjaGVtYUlkLmZsb2F0UHJvcGVydHlOYW1lCiAgICAgPj0gMTAiYAoKDQoFBAgC
AQYSBNkCAhYKDQoFBAgCAQESBNkCFx0KDQoFBAgCAQMSBNkCICEKDQoFBAgCAQgSBNkCIkoK
EAoIBAgCAQicCAASBNkCI0kKcwoEBAgCAhIE3QICJxplIFRoZSBtZXRhIGluZm9ybWF0aW9u
IGNvbGxlY3RlZCBhYm91dCB0aGUgZW5kIHVzZXIsIHVzZWQgdG8gZW5mb3JjZSBhY2Nlc3MK
IGNvbnRyb2wgZm9yIHRoZSBzZXJ2aWNlLgoKDQoFBAgCAgYSBN0CAhEKDQoFBAgCAgESBN0C
EiIKDQoFBAgCAgMSBN0CJSYKdAoEBAgCAxIE4QICGRpmIEZvciBTZXQgUHJvamVjdCBBQ0wg
b25seS4gQXV0aG9yaXphdGlvbiBjaGVjayBmb3IgZW5kIHVzZXIgd2lsbCBiZSBpZ25vcmVk
CiB3aGVuIHByb2plY3Rfb3duZXI9dHJ1ZS4KCg0KBQQIAgMFEgThAgIGCg0KBQQIAgMBEgTh
AgcUCg0KBQQIAgMDEgThAhcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption ===
    # Fields for CloudAIDocumentOption
    # Field: enable_entities_conversions Type: 8 ()
    # Field: customized_entities_properties_conversions Type: 11 (.google.cloud.contentwarehouse.v1.CloudAIDocumentOption.CustomizedEntitiesPropertiesConversionsEntry)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CreateDocumentRequest ===
    # Fields for CreateDocumentRequest
    # Field: parent Type: 9 ()
    # Field: document Type: 11 (.google.cloud.contentwarehouse.v1.Document)
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)
    # Field: policy Type: 11 (.google.iam.v1.Policy)
    # Field: cloud_ai_document_option Type: 11 (.google.cloud.contentwarehouse.v1.CloudAIDocumentOption)
    # Field: create_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::GetDocumentRequest ===
    # Fields for GetDocumentRequest
    # Field: name Type: 9 ()
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::UpdateDocumentRequest ===
    # Fields for UpdateDocumentRequest
    # Field: name Type: 9 ()
    # Field: document Type: 11 (.google.cloud.contentwarehouse.v1.Document)
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)
    # Field: cloud_ai_document_option Type: 11 (.google.cloud.contentwarehouse.v1.CloudAIDocumentOption)
    # Field: update_options Type: 11 (.google.cloud.contentwarehouse.v1.UpdateOptions)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::DeleteDocumentRequest ===
    # Fields for DeleteDocumentRequest
    # Field: name Type: 9 ()
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SearchDocumentsRequest ===
    # Fields for SearchDocumentsRequest
    # Field: parent Type: 9 ()
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)
    # Field: document_query Type: 11 (.google.cloud.contentwarehouse.v1.DocumentQuery)
    # Field: offset Type: 5 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: histogram_queries Type: 11 (.google.cloud.contentwarehouse.v1.HistogramQuery)
    # Field: require_total_size Type: 8 ()
    # Field: total_result_size Type: 14 (.google.cloud.contentwarehouse.v1.SearchDocumentsRequest.TotalResultSize)
    # Field: qa_size_limit Type: 5 ()

# Enum: SearchDocumentsRequest::TotalResultSize
our $SearchDocumentsRequest_TOTAL_RESULT_SIZE_UNSPECIFIED = 0;
our $SearchDocumentsRequest_ESTIMATED_SIZE = 1;
our $SearchDocumentsRequest_ACTUAL_SIZE = 2;

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::LockDocumentRequest ===
    # Fields for LockDocumentRequest
    # Field: name Type: 9 ()
    # Field: collection_id Type: 9 ()
    # Field: locking_user Type: 11 (.google.cloud.contentwarehouse.v1.UserInfo)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::FetchAclRequest ===
    # Fields for FetchAclRequest
    # Field: resource Type: 9 ()
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)
    # Field: project_owner Type: 8 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SetAclRequest ===
    # Fields for SetAclRequest
    # Field: resource Type: 9 ()
    # Field: policy Type: 11 (.google.iam.v1.Policy)
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)
    # Field: project_owner Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/document_service_request.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest;

    my $msg = Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption->new({
        enable_entities_conversions => $enable_entities_conversions,
        customized_entities_properties_conversions => $customized_entities_properties_conversions,
    });

    # Read or update a field
    my $val = $msg->enable_entities_conversions();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/document_service_request.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption

Request Option for processing Cloud AI Document in CW Document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_entities_conversions() >> / C<< $msg->enable_entities_conversions($value) >>

Type: C<Bool>

Whether to convert all the entities to properties.

=item * C<< $msg->customized_entities_properties_conversions() >> / C<< $msg->customized_entities_properties_conversions($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption::CustomizedEntitiesPropertiesConversionsEntry>)

If set, only selected entities will be converted to properties.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CreateDocumentRequest

Request message for DocumentService.CreateDocument.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent name.
Format: projects/{project_number}/locations/{location}.

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::Document>)

Required. The document to create.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the end user, used to enforce access
control for the service.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Policy>)

Default document policy during creation.
This refers to an Identity and Access (IAM) policy, which specifies access
controls for the Document.
Conditions defined in the policy will be ignored.

=item * C<< $msg->cloud_ai_document_option() >> / C<< $msg->cloud_ai_document_option($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption>)

Request Option for processing Cloud AI Document in Document Warehouse.
This field offers limited support for mapping entities from Cloud AI
Document to Warehouse Document. Please consult with product team before
using this field and other available options.

=item * C<< $msg->create_mask() >> / C<< $msg->create_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Field mask for creating Document fields. If mask path is empty,
it means all fields are masked.
For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::GetDocumentRequest

Request message for DocumentService.GetDocument.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the document to retrieve.
Format:
projects/{project_number}/locations/{location}/documents/{document_id} or
projects/{project_number}/locations/{location}/documents/referenceId/{reference_id}.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the end user, used to enforce access
control for the service.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::UpdateDocumentRequest

Request message for DocumentService.UpdateDocument.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the document to update.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}
or
projects/{project_number}/locations/{location}/documents/referenceId/{reference_id}.

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::Document>)

Required. The document to update.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the end user, used to enforce access
control for the service.

=item * C<< $msg->cloud_ai_document_option() >> / C<< $msg->cloud_ai_document_option($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption>)

Request Option for processing Cloud AI Document in Document Warehouse.
This field offers limited support for mapping entities from Cloud AI
Document to Warehouse Document. Please consult with product team before
using this field and other available options.

=item * C<< $msg->update_options() >> / C<< $msg->update_options($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::UpdateOptions>)

Options for the update operation.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::DeleteDocumentRequest

Request message for DocumentService.DeleteDocument.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the document to delete.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}
or
projects/{project_number}/locations/{location}/documents/referenceId/{reference_id}.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the end user, used to enforce access
control for the service.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SearchDocumentsRequest

Request message for DocumentService.SearchDocuments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of documents.
Format: projects/{project_number}/locations/{location}.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the end user, used to enforce access
control and improve the search quality of the service.

=item * C<< $msg->document_query() >> / C<< $msg->document_query($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Filters::DocumentQuery>)

Query used to search against documents (keyword, filters, etc.).

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int32>

An integer that specifies the current offset (that is, starting result
location, amongst the documents deemed by the API as relevant) in search
results. This field is only considered if
[page_token][google.cloud.contentwarehouse.v1.SearchDocumentsRequest.page_token]
is unset.

The maximum allowed value is 5000. Otherwise an error is thrown.

For example, 0 means to  return results starting from the first matching
document, and 10 means to return from the 11th document. This can be used
for pagination, (for example, pageSize = 10 and offset = 10 means to return
from the second page).

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

A limit on the number of documents returned in the search results.
Increasing this value above the default value of 10 can increase search
response time. The value can be between 1 and 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The token specifying the current offset within search results.
See
[SearchDocumentsResponse.next_page_token][google.cloud.contentwarehouse.v1.SearchDocumentsResponse.next_page_token]
for an explanation of how to obtain the next set of query results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

The criteria determining how search results are sorted. For non-empty
query, default is `"relevance desc"`. For empty query, default is
`"upload_date desc"`.

Supported options are:

* `"relevance desc"`: By relevance descending, as determined by the API
  algorithms.
* `"upload_date desc"`: By upload date descending.
* `"upload_date"`: By upload date ascending.
* `"update_date desc"`: By last updated date descending.
* `"update_date"`: By last updated date ascending.
* `"retrieval_importance desc"`: By retrieval importance of properties
  descending. This feature is still under development, please do not use
  unless otherwise instructed to do so.

=item * C<< $msg->histogram_queries() >> / C<< $msg->histogram_queries($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Histogram::HistogramQuery>)

An expression specifying a histogram request against matching
documents. Expression syntax is an aggregation function call with
histogram facets and other options.

The following aggregation functions are supported:

* `count(string_histogram_facet)`: Count the number of matching entities
for each distinct attribute value.

Data types:

* Histogram facet (aka filterable properties): Facet names with format
&lt;schema id&gt;.&lt;facet&gt;. Facets will have the
format of: `[a-zA-Z][a-zA-Z0-9_:/-.]`. If the facet is a child
facet, then the parent hierarchy needs to be specified separated by
dots in the prefix after the schema id. Thus, the format for a multi-
level facet is: &lt;schema id&gt;.&lt;parent facet name&gt;.
&lt;child facet name&gt;. Example:
schema123.root_parent_facet.middle_facet.child_facet
* DocumentSchemaId: (with no schema id prefix) to get
histograms for each document type (returns the schema id path, e.g.
projects/12345/locations/us-west/documentSchemas/abc123).

Example expression:

* Document type counts:
  count('DocumentSchemaId')

* For schema id, abc123, get the counts for MORTGAGE_TYPE:
  count('abc123.MORTGAGE_TYPE')

=item * C<< $msg->require_total_size() >> / C<< $msg->require_total_size($value) >>

Type: C<Bool>

Controls if the search document request requires the return of a total size
of matched documents. See
[SearchDocumentsResponse.total_size][google.cloud.contentwarehouse.v1.SearchDocumentsResponse.total_size].

Enabling this flag may adversely impact performance. Hint: If this is
used with pagination, set this flag on the initial query but set this
to false on subsequent page calls (keep the total count locally).

Defaults to false.

=item * C<< $msg->total_result_size() >> / C<< $msg->total_result_size($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::SearchDocumentsRequest::TotalResultSize>)

Controls if the search document request requires the return of a total size
of matched documents. See
[SearchDocumentsResponse.total_size][google.cloud.contentwarehouse.v1.SearchDocumentsResponse.total_size].

=item * C<< $msg->qa_size_limit() >> / C<< $msg->qa_size_limit($value) >>

Type: C<Int32>

Experimental, do not use.
The limit on the number of documents returned for the question-answering
feature. To enable the question-answering feature, set
[DocumentQuery].[is_nl_query][] to true.

=back

=head3 Enum: SearchDocumentsRequest::TotalResultSize

=over 4

=item * C<TOTAL_RESULT_SIZE_UNSPECIFIED> => C<0>

=item * C<ESTIMATED_SIZE> => C<1>

=item * C<ACTUAL_SIZE> => C<2>

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::LockDocumentRequest

Request message for DocumentService.LockDocument.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the document to lock.
Format:
projects/{project_number}/locations/{location}/documents/{document}.

=item * C<< $msg->collection_id() >> / C<< $msg->collection_id($value) >>

Type: C<String>

The collection the document connects to.

=item * C<< $msg->locking_user() >> / C<< $msg->locking_user($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::UserInfo>)

The user information who locks the document.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::FetchAclRequest

Request message for DocumentService.FetchAcl

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Required. REQUIRED: The resource for which the policy is being requested.
Format for document:
projects/{project_number}/locations/{location}/documents/{document_id}.
Format for collection:
projects/{project_number}/locations/{location}/collections/{collection_id}.
Format for project: projects/{project_number}.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the end user, used to enforce access
control for the service.

=item * C<< $msg->project_owner() >> / C<< $msg->project_owner($value) >>

Type: C<Bool>

For Get Project ACL only. Authorization check for end user will be ignored
when project_owner=true.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SetAclRequest

Request message for DocumentService.SetAcl.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Required. REQUIRED: The resource for which the policy is being requested.
Format for document:
projects/{project_number}/locations/{location}/documents/{document_id}.
Format for collection:
projects/{project_number}/locations/{location}/collections/{collection_id}.
Format for project: projects/{project_number}.

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Policy>)

Required. REQUIRED: The complete policy to be applied to the `resource`.
The size of the policy is limited to a few 10s of KB. This refers to an
Identity and Access (IAM) policy, which specifies access controls for the
Document.

You can set ACL with condition for projects only.

Supported operators are: `=`, `!=`, `<`, `<=`, `>`, and `>=` where
the left of the operator is `DocumentSchemaId` or property name and the
right of the operator is a number or a quoted string. You must escape
backslash (\\) and quote (\") characters.

Boolean expressions (AND/OR) are supported up to 3 levels of nesting (for
example, "((A AND B AND C) OR D) AND E"), a maximum of 10 comparisons are
allowed in the expression. The expression must be < 6000 bytes in length.

Sample condition:
    `"DocumentSchemaId = \"some schema id\" OR SchemaId.floatPropertyName
    >= 10"`

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the end user, used to enforce access
control for the service.

=item * C<< $msg->project_owner() >> / C<< $msg->project_owner($value) >>

Type: C<Bool>

For Set Project ACL only. Authorization check for end user will be ignored
when project_owner=true.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
