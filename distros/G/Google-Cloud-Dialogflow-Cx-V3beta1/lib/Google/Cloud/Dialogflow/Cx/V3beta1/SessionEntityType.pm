package Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::EntityType };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3Nlc3Npb25fZW50aXR5X3R5
cGUucHJvdG8SImdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEaHGdvb2dsZS9h
cGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjRn
b29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2VudGl0eV90eXBlLnByb3RvGhtn
b29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNr
LnByb3RvIqMFChFTZXNzaW9uRW50aXR5VHlwZRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUS
fwoUZW50aXR5X292ZXJyaWRlX21vZGUYAyABKA4ySC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52M2JldGExLlNlc3Npb25FbnRpdHlUeXBlLkVudGl0eU92ZXJyaWRlTW9kZUID4EEC
UhJlbnRpdHlPdmVycmlkZU1vZGUSVgoIZW50aXRpZXMYBCADKAsyNS5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52M2JldGExLkVudGl0eVR5cGUuRW50aXR5QgPgQQJSCGVudGl0aWVz
IoIBChJFbnRpdHlPdmVycmlkZU1vZGUSJAogRU5USVRZX09WRVJSSURFX01PREVfVU5TUEVD
SUZJRUQQABIhCh1FTlRJVFlfT1ZFUlJJREVfTU9ERV9PVkVSUklERRABEiMKH0VOVElUWV9P
VkVSUklERV9NT0RFX1NVUFBMRU1FTlQQAjqWAupBkgIKK2RpYWxvZ2Zsb3cuZ29vZ2xlYXBp
cy5jb20vU2Vzc2lvbkVudGl0eVR5cGUSY3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9hZ2VudHMve2FnZW50fS9zZXNzaW9ucy97c2Vzc2lvbn0vZW50aXR5VHlw
ZXMve2VudGl0eV90eXBlfRJ+cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2FnZW50cy97YWdlbnR9L2Vudmlyb25tZW50cy97ZW52aXJvbm1lbnR9L3Nlc3Npb25z
L3tzZXNzaW9ufS9lbnRpdHlUeXBlcy97ZW50aXR5X3R5cGV9IqgBCh1MaXN0U2Vzc2lvbkVu
dGl0eVR5cGVzUmVxdWVzdBJLCgZwYXJlbnQYASABKAlCM+BBAvpBLRIrZGlhbG9nZmxvdy5n
b29nbGVhcGlzLmNvbS9TZXNzaW9uRW50aXR5VHlwZVIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgC
IAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIrEBCh5MaXN0
U2Vzc2lvbkVudGl0eVR5cGVzUmVzcG9uc2USZwoUc2Vzc2lvbl9lbnRpdHlfdHlwZXMYASAD
KAsyNS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlc3Npb25FbnRpdHlU
eXBlUhJzZXNzaW9uRW50aXR5VHlwZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0
UGFnZVRva2VuImYKG0dldFNlc3Npb25FbnRpdHlUeXBlUmVxdWVzdBJHCgRuYW1lGAEgASgJ
QjPgQQL6QS0KK2RpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vU2Vzc2lvbkVudGl0eVR5cGVS
BG5hbWUi2QEKHkNyZWF0ZVNlc3Npb25FbnRpdHlUeXBlUmVxdWVzdBJLCgZwYXJlbnQYASAB
KAlCM+BBAvpBLRIrZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9TZXNzaW9uRW50aXR5VHlw
ZVIGcGFyZW50EmoKE3Nlc3Npb25fZW50aXR5X3R5cGUYAiABKAsyNS5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52M2JldGExLlNlc3Npb25FbnRpdHlUeXBlQgPgQQJSEXNlc3Npb25F
bnRpdHlUeXBlIskBCh5VcGRhdGVTZXNzaW9uRW50aXR5VHlwZVJlcXVlc3QSagoTc2Vzc2lv
bl9lbnRpdHlfdHlwZRgBIAEoCzI1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0
YTEuU2Vzc2lvbkVudGl0eVR5cGVCA+BBAlIRc2Vzc2lvbkVudGl0eVR5cGUSOwoLdXBkYXRl
X21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrImkK
HkRlbGV0ZVNlc3Npb25FbnRpdHlUeXBlUmVxdWVzdBJHCgRuYW1lGAEgASgJQjPgQQL6QS0K
K2RpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vU2Vzc2lvbkVudGl0eVR5cGVSBG5hbWUypQ8K
ElNlc3Npb25FbnRpdHlUeXBlcxLXAgoWTGlzdFNlc3Npb25FbnRpdHlUeXBlcxJBLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuTGlzdFNlc3Npb25FbnRpdHlUeXBlc1Jl
cXVlc3QaQi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkxpc3RTZXNzaW9u
RW50aXR5VHlwZXNSZXNwb25zZSK1AYLT5JMCpQESSC92M2JldGExL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9zZXNzaW9ucy8qfS9lbnRpdHlUeXBlc1pZElcv
djNiZXRhMS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZW52aXJv
bm1lbnRzLyovc2Vzc2lvbnMvKn0vZW50aXR5VHlwZXPaQQZwYXJlbnQSxAIKFEdldFNlc3Np
b25FbnRpdHlUeXBlEj8uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5HZXRT
ZXNzaW9uRW50aXR5VHlwZVJlcXVlc3QaNS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
M2JldGExLlNlc3Npb25FbnRpdHlUeXBlIrMBgtPkkwKlARJIL3YzYmV0YTEve25hbWU9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9
WlkSVy92M2JldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZW52
aXJvbm1lbnRzLyovc2Vzc2lvbnMvKi9lbnRpdHlUeXBlcy8qfdpBBG5hbWUSigMKF0NyZWF0
ZVNlc3Npb25FbnRpdHlUeXBlEkIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRh
MS5DcmVhdGVTZXNzaW9uRW50aXR5VHlwZVJlcXVlc3QaNS5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52M2JldGExLlNlc3Npb25FbnRpdHlUeXBlIvMBgtPkkwLPASJIL3YzYmV0YTEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL3Nlc3Npb25zLyp9L2Vu
dGl0eVR5cGVzOhNzZXNzaW9uX2VudGl0eV90eXBlWm4iVy92M2JldGExL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9lbnZpcm9ubWVudHMvKi9zZXNzaW9ucy8q
fS9lbnRpdHlUeXBlczoTc2Vzc2lvbl9lbnRpdHlfdHlwZdpBGnBhcmVudCxzZXNzaW9uX2Vu
dGl0eV90eXBlErgDChdVcGRhdGVTZXNzaW9uRW50aXR5VHlwZRJCLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzYmV0YTEuVXBkYXRlU2Vzc2lvbkVudGl0eVR5cGVSZXF1ZXN0GjUu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5TZXNzaW9uRW50aXR5VHlwZSKh
AoLT5JMC+AEyXC92M2JldGExL3tzZXNzaW9uX2VudGl0eV90eXBlLm5hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9hZ2VudHMvKi9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9OhNzZXNz
aW9uX2VudGl0eV90eXBlWoIBMmsvdjNiZXRhMS97c2Vzc2lvbl9lbnRpdHlfdHlwZS5uYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZW52aXJvbm1lbnRzLyovc2Vzc2lv
bnMvKi9lbnRpdHlUeXBlcy8qfToTc2Vzc2lvbl9lbnRpdHlfdHlwZdpBH3Nlc3Npb25fZW50
aXR5X3R5cGUsdXBkYXRlX21hc2sSqwIKF0RlbGV0ZVNlc3Npb25FbnRpdHlUeXBlEkIuZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5EZWxldGVTZXNzaW9uRW50aXR5VHlw
ZVJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiswGC0+STAqUBKkgvdjNiZXRhMS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL3Nlc3Npb25zLyovZW50aXR5
VHlwZXMvKn1aWSpXL3YzYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2Vu
dHMvKi9lbnZpcm9ubWVudHMvKi9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp92kEEbmFtZRp4
ykEZZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9kaWFsb2dmbG93Qs0BCiZjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRh
MUIWU2Vzc2lvbkVudGl0eVR5cGVQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxv
Z2Zsb3cvY3gvYXBpdjNiZXRhMS9jeHBiO2N4cGKiAgJERqoCIkdvb2dsZS5DbG91ZC5EaWFs
b2dmbG93LkN4LlYzQmV0YTHqAiZHb29nbGU6OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjNi
ZXRhMUqgRQoHEgUOAJcCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAKwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkK
AgMEEgMWAD4KCQoCAwUSAxcAJQoJCgIDBhIDGAAqCggKAQgSAxoAPwoJCgIIJRIDGgA/CggK
AQgSAxsATQoJCgIICxIDGwBNCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANwoJCgII
CBIDHQA3CggKAQgSAx4APwoJCgIIARIDHgA/CggKAQgSAx8AIAoJCgIIJBIDHwAgCggKAQgS
AyAAPwoJCgIILRIDIAA/Cm8KAgYAEgQkAGkBGmMgU2VydmljZSBmb3IgbWFuYWdpbmcKIFtT
ZXNzaW9uRW50aXR5VHlwZXNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEu
U2Vzc2lvbkVudGl0eVR5cGVdLgoKCgoDBgABEgMkCBoKCgoDBgADEgMlAkEKDAoFBgADmQgS
AyUCQQoLCgMGAAMSBCYCKDMKDQoFBgADmggSBCYCKDMKVgoEBgACABIEKwI0AxpIIFJldHVy
bnMgdGhlIGxpc3Qgb2YgYWxsIHNlc3Npb24gZW50aXR5IHR5cGVzIGluIHRoZSBzcGVjaWZp
ZWQgc2Vzc2lvbi4KCgwKBQYAAgABEgMrBhwKDAoFBgACAAISAysdOgoMCgUGAAIAAxIDLA8t
Cg0KBQYAAgAEEgQtBDIGChEKCQYAAgAEsMq8IhIELQQyBgoMCgUGAAIABBIDMwQ0Cg8KCAYA
AgAEmwgAEgMzBDQKPAoEBgACARIENwJAAxouIFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkIHNl
c3Npb24gZW50aXR5IHR5cGUuCgoMCgUGAAIBARIDNwYaCgwKBQYAAgECEgM3GzYKDAoFBgAC
AQMSAzgPIAoNCgUGAAIBBBIEOQQ+BgoRCgkGAAIBBLDKvCISBDkEPgYKDAoFBgACAQQSAz8E
MgoPCggGAAIBBJsIABIDPwQyCi4KBAYAAgISBEMCTgMaICBDcmVhdGVzIGEgc2Vzc2lvbiBl
bnRpdHkgdHlwZS4KCgwKBQYAAgIBEgNDBh0KDAoFBgACAgISA0MePAoMCgUGAAICAxIDRA8g
Cg0KBQYAAgIEEgRFBEwGChEKCQYAAgIEsMq8IhIERQRMBgoMCgUGAAICBBIDTQRICg8KCAYA
AgIEmwgAEgNNBEgKOgoEBgACAxIEUQJcAxosIFVwZGF0ZXMgdGhlIHNwZWNpZmllZCBzZXNz
aW9uIGVudGl0eSB0eXBlLgoKDAoFBgACAwESA1EGHQoMCgUGAAIDAhIDUR48CgwKBQYAAgMD
EgNSDyAKDQoFBgACAwQSBFMEWgYKEQoJBgACAwSwyrwiEgRTBFoGCgwKBQYAAgMEEgNbBE0K
DwoIBgACAwSbCAASA1sETQo6CgQGAAIEEgRfAmgDGiwgRGVsZXRlcyB0aGUgc3BlY2lmaWVk
IHNlc3Npb24gZW50aXR5IHR5cGUuCgoMCgUGAAIEARIDXwYdCgwKBQYAAgQCEgNfHjwKDAoF
BgACBAMSA2APJAoNCgUGAAIEBBIEYQRmBgoRCgkGAAIEBLDKvCISBGEEZgYKDAoFBgACBAQS
A2cEMgoPCggGAAIEBJsIABIDZwQyCqEFCgIEABIFeACnAQEakwUgU2Vzc2lvbiBlbnRpdHkg
dHlwZXMgYXJlIHJlZmVycmVkIHRvIGFzICoqVXNlcioqIGVudGl0eSB0eXBlcyBhbmQgYXJl
CiBlbnRpdGllcyB0aGF0IGFyZSBidWlsdCBmb3IgYW4gaW5kaXZpZHVhbCB1c2VyIHN1Y2gg
YXMgZmF2b3JpdGVzLAogcHJlZmVyZW5jZXMsIHBsYXlsaXN0cywgYW5kIHNvIG9uLgoKIFlv
dSBjYW4gcmVkZWZpbmUgYSBzZXNzaW9uIGVudGl0eSB0eXBlIGF0IHRoZSBzZXNzaW9uIGxl
dmVsIHRvIGV4dGVuZCBvcgogcmVwbGFjZSBhIFtjdXN0b20gZW50aXR5IHR5cGVdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRW50aXR5VHlwZV0KIGF0IHRoZSB1c2Vy
IHNlc3Npb24gbGV2ZWwgKHdlIHJlZmVyIHRvIHRoZSBlbnRpdHkgdHlwZXMgZGVmaW5lZCBh
dCB0aGUgYWdlbnQKIGxldmVsIGFzICJjdXN0b20gZW50aXR5IHR5cGVzIikuCgogTm90ZTog
c2Vzc2lvbiBlbnRpdHkgdHlwZXMgYXBwbHkgdG8gYWxsIHF1ZXJpZXMsIHJlZ2FyZGxlc3Mg
b2YgdGhlIGxhbmd1YWdlLgoKIEZvciBtb3JlIGluZm9ybWF0aW9uIGFib3V0IGVudGl0eSB0
eXBlcywgc2VlIHRoZSBbRGlhbG9nZmxvdwogZG9jdW1lbnRhdGlvbl0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvZG9jcy9lbnRpdGllcy1vdmVydmlldykuCgoKCgME
AAESA3gIGQoLCgMEAAcSBHkCfQQKDQoFBAAHnQgSBHkCfQQKSQoEBAAEABIGgAECkwEDGjkg
VGhlIHR5cGVzIG9mIG1vZGlmaWNhdGlvbnMgZm9yIHRoZSBzZXNzaW9uIGVudGl0eSB0eXBl
LgoKDQoFBAAEAAESBIABBxkKQQoGBAAEAAIAEgSCAQQpGjEgTm90IHNwZWNpZmllZC4gVGhp
cyB2YWx1ZSBzaG91bGQgYmUgbmV2ZXIgdXNlZC4KCg8KBwQABAACAAESBIIBBCQKDwoHBAAE
AAIAAhIEggEnKAqDAQoGBAAEAAIBEgSGAQQmGnMgVGhlIGNvbGxlY3Rpb24gb2Ygc2Vzc2lv
biBlbnRpdGllcyBvdmVycmlkZXMgdGhlIGNvbGxlY3Rpb24gb2YgZW50aXRpZXMKIGluIHRo
ZSBjb3JyZXNwb25kaW5nIGN1c3RvbSBlbnRpdHkgdHlwZS4KCg8KBwQABAACAQESBIYBBCEK
DwoHBAAEAAIBAhIEhgEkJQqaBAoGBAAEAAICEgSSAQQoGokEIFRoZSBjb2xsZWN0aW9uIG9m
IHNlc3Npb24gZW50aXRpZXMgZXh0ZW5kcyB0aGUgY29sbGVjdGlvbiBvZiBlbnRpdGllcyBp
bgogdGhlIGNvcnJlc3BvbmRpbmcgY3VzdG9tIGVudGl0eSB0eXBlLgoKIE5vdGU6IEV2ZW4g
aW4gdGhpcyBvdmVycmlkZSBtb2RlIGNhbGxzIHRvIGBMaXN0U2Vzc2lvbkVudGl0eVR5cGVz
YCwKIGBHZXRTZXNzaW9uRW50aXR5VHlwZWAsIGBDcmVhdGVTZXNzaW9uRW50aXR5VHlwZWAg
YW5kCiBgVXBkYXRlU2Vzc2lvbkVudGl0eVR5cGVgIG9ubHkgcmV0dXJuIHRoZSBhZGRpdGlv
bmFsIGVudGl0aWVzIGFkZGVkIGluCiB0aGlzIHNlc3Npb24gZW50aXR5IHR5cGUuIElmIHlv
dSB3YW50IHRvIGdldCB0aGUgc3VwcGxlbWVudGVkIGxpc3QsCiBwbGVhc2UgY2FsbAogW0Vu
dGl0eVR5cGVzLkdldEVudGl0eVR5cGVdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
YmV0YTEuRW50aXR5VHlwZXMuR2V0RW50aXR5VHlwZV0KIG9uIHRoZSBjdXN0b20gZW50aXR5
IHR5cGUgYW5kIG1lcmdlLgoKDwoHBAAEAAICARIEkgEEIwoPCgcEAAQAAgICEgSSASYnCqYD
CgQEAAIAEgScAQI7GpcDIFJlcXVpcmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhl
IHNlc3Npb24gZW50aXR5IHR5cGUuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4v
bG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L3Nlc3Npb25zLzxTZXNz
aW9uSUQ+L2VudGl0eVR5cGVzLzxFbnRpdHlUeXBlSUQ+YAogb3IKIGBwcm9qZWN0cy88UHJv
amVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZW52aXJv
bm1lbnRzLzxFbnZpcm9ubWVudElEPi9zZXNzaW9ucy88U2Vzc2lvbklEPi9lbnRpdHlUeXBl
cy88RW50aXR5VHlwZUlEPmAuCiBJZiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZp
ZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcKIGVudmlyb25tZW50LgoKDQoFBAACAAUS
BJwBAggKDQoFBAACAAESBJwBCQ0KDQoFBAACAAMSBJwBEBEKDQoFBAACAAgSBJwBEjoKEAoI
BAACAAicCAASBJwBEzkKgwEKBAQAAgESBqABAqEBLxpzIFJlcXVpcmVkLiBJbmRpY2F0ZXMg
d2hldGhlciB0aGUgYWRkaXRpb25hbCBkYXRhIHNob3VsZCBvdmVycmlkZSBvcgogc3VwcGxl
bWVudCB0aGUgY3VzdG9tIGVudGl0eSB0eXBlIGRlZmluaXRpb24uCgoNCgUEAAIBBhIEoAEC
FAoNCgUEAAIBARIEoAEVKQoNCgUEAAIBAxIEoAEsLQoNCgUEAAIBCBIEoQEGLgoQCggEAAIB
CJwIABIEoQEHLQppCgQEAAICEgalAQKmAS8aWSBSZXF1aXJlZC4gVGhlIGNvbGxlY3Rpb24g
b2YgZW50aXRpZXMgdG8gb3ZlcnJpZGUgb3Igc3VwcGxlbWVudCB0aGUgY3VzdG9tCiBlbnRp
dHkgdHlwZS4KCg0KBQQAAgIEEgSlAQIKCg0KBQQAAgIGEgSlAQscCg0KBQQAAgIBEgSlAR0l
Cg0KBQQAAgIDEgSlASgpCg0KBQQAAgIIEgSmAQYuChAKCAQAAgIInAgAEgSmAQctCqQBCgIE
ARIGqwEAwAEBGpUBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2Vzc2lvbkVudGl0eVR5
cGVzLkxpc3RTZXNzaW9uRW50aXR5VHlwZXNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzYmV0YTEuU2Vzc2lvbkVudGl0eVR5cGVzLkxpc3RTZXNzaW9uRW50aXR5VHlwZXNdLgoK
CwoDBAEBEgSrAQglCvQCCgQEAQIAEgazAQK4AQQa4wIgUmVxdWlyZWQuIFRoZSBzZXNzaW9u
IHRvIGxpc3QgYWxsIHNlc3Npb24gZW50aXR5IHR5cGVzIGZyb20uCiBGb3JtYXQ6CiBgcHJv
amVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50
SUQ+L3Nlc3Npb25zLzxTZXNzaW9uSUQ+YAogb3IKIGBwcm9qZWN0cy88UHJvamVjdElEPi9s
b2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZW52aXJvbm1lbnRzLzxF
bnZpcm9ubWVudElEPi9zZXNzaW9ucy88U2Vzc2lvbklEPmAuCiBJZiBgRW52aXJvbm1lbnQg
SURgIGlzIG5vdCBzcGVjaWZpZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcKICBlbnZp
cm9ubWVudC4KCg0KBQQBAgAFEgSzAQIICg0KBQQBAgABEgSzAQkPCg0KBQQBAgADEgSzARIT
Cg8KBQQBAgAIEgazARS4AQMKEAoIBAECAAicCAASBLQBBCoKEQoHBAECAAifCBIGtQEEtwEF
CmkKBAQBAgESBLwBAhYaWyBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJu
IGluIGEgc2luZ2xlIHBhZ2UuIEJ5IGRlZmF1bHQgMTAwIGFuZAogYXQgbW9zdCAxMDAwLgoK
DQoFBAECAQUSBLwBAgcKDQoFBAECAQESBLwBCBEKDQoFBAECAQMSBLwBFBUKUAoEBAECAhIE
vwECGBpCIFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZp
b3VzIGxpc3QgcmVxdWVzdC4KCg0KBQQBAgIFEgS/AQIICg0KBQQBAgIBEgS/AQkTCg0KBQQB
AgIDEgS/ARYXCqUBCgIEAhIGxAEAzAEBGpYBIFRoZSByZXNwb25zZSBtZXNzYWdlIGZvcgog
W1Nlc3Npb25FbnRpdHlUeXBlcy5MaXN0U2Vzc2lvbkVudGl0eVR5cGVzXVtnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlc3Npb25FbnRpdHlUeXBlcy5MaXN0U2Vzc2lv
bkVudGl0eVR5cGVzXS4KCgsKAwQCARIExAEIJgqRAQoEBAICABIExwECNhqCASBUaGUgbGlz
dCBvZiBzZXNzaW9uIGVudGl0eSB0eXBlcy4gVGhlcmUgd2lsbCBiZSBhIG1heGltdW0gbnVt
YmVyIG9mIGl0ZW1zCiByZXR1cm5lZCBiYXNlZCBvbiB0aGUgcGFnZV9zaXplIGZpZWxkIGlu
IHRoZSByZXF1ZXN0LgoKDQoFBAICAAQSBMcBAgoKDQoFBAICAAYSBMcBCxwKDQoFBAICAAES
BMcBHTEKDQoFBAICAAMSBMcBNDUKbwoEBAICARIEywECHRphIFRva2VuIHRvIHJldHJpZXZl
IHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBt
b3JlIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAgIBBRIEywECCAoNCgUEAgIBARIEywEJ
GAoNCgUEAgIBAxIEywEbHAqgAQoCBAMSBtABAN4BARqRASBUaGUgcmVxdWVzdCBtZXNzYWdl
IGZvcgogW1Nlc3Npb25FbnRpdHlUeXBlcy5HZXRTZXNzaW9uRW50aXR5VHlwZV1bZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5TZXNzaW9uRW50aXR5VHlwZXMuR2V0U2Vz
c2lvbkVudGl0eVR5cGVdLgoKCwoDBAMBEgTQAQgjCpsDCgQEAwIAEgbYAQLdAQQaigMgUmVx
dWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzZXNzaW9uIGVudGl0eSB0eXBlLgogRm9ybWF0Ogog
YHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxB
Z2VudElEPi9zZXNzaW9ucy88U2Vzc2lvbklEPi9lbnRpdHlUeXBlcy88RW50aXR5VHlwZUlE
PmAKIG9yCiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9h
Z2VudHMvPEFnZW50SUQ+L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnRJRD4vc2Vzc2lvbnMv
PFNlc3Npb25JRD4vZW50aXR5VHlwZXMvPEVudGl0eVR5cGVJRD5gLgogSWYgYEVudmlyb25t
ZW50IElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnZHJhZnQnCiBl
bnZpcm9ubWVudC4KCg0KBQQDAgAFEgTYAQIICg0KBQQDAgABEgTYAQkNCg0KBQQDAgADEgTY
ARARCg8KBQQDAgAIEgbYARLdAQMKEAoIBAMCAAicCAASBNkBBCoKEQoHBAMCAAifCBIG2gEE
3AEFCqYBCgIEBBIG4gEA9AEBGpcBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2Vzc2lv
bkVudGl0eVR5cGVzLkNyZWF0ZVNlc3Npb25FbnRpdHlUeXBlXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52M2JldGExLlNlc3Npb25FbnRpdHlUeXBlcy5DcmVhdGVTZXNzaW9uRW50
aXR5VHlwZV0uCgoLCgMEBAESBOIBCCYK8QIKBAQEAgASBuoBAu8BBBrgAiBSZXF1aXJlZC4g
VGhlIHNlc3Npb24gdG8gY3JlYXRlIGEgc2Vzc2lvbiBlbnRpdHkgdHlwZSBmb3IuCiBGb3Jt
YXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2Vu
dHMvPEFnZW50SUQ+L3Nlc3Npb25zLzxTZXNzaW9uSUQ+YAogb3IKIGBwcm9qZWN0cy88UHJv
amVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZW52aXJv
bm1lbnRzLzxFbnZpcm9ubWVudElEPi9zZXNzaW9ucy88U2Vzc2lvbklEPmAuCiBJZiBgRW52
aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZpZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFm
dCcKIGVudmlyb25tZW50LgoKDQoFBAQCAAUSBOoBAggKDQoFBAQCAAESBOoBCQ8KDQoFBAQC
AAMSBOoBEhMKDwoFBAQCAAgSBuoBFO8BAwoQCggEBAIACJwIABIE6wEEKgoRCgcEBAIACJ8I
EgbsAQTuAQUKPgoEBAQCARIG8gEC8wEvGi4gUmVxdWlyZWQuIFRoZSBzZXNzaW9uIGVudGl0
eSB0eXBlIHRvIGNyZWF0ZS4KCg0KBQQEAgEGEgTyAQITCg0KBQQEAgEBEgTyARQnCg0KBQQE
AgEDEgTyASorCg0KBQQEAgEIEgTzAQYuChAKCAQEAgEInAgAEgTzAQctCqYBCgIEBRIG+AEA
hQIBGpcBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2Vzc2lvbkVudGl0eVR5cGVzLlVw
ZGF0ZVNlc3Npb25FbnRpdHlUeXBlXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2Jl
dGExLlNlc3Npb25FbnRpdHlUeXBlcy5VcGRhdGVTZXNzaW9uRW50aXR5VHlwZV0uCgoLCgME
BQESBPgBCCYKmQMKBAQFAgASBoACAoECLxqIAyBSZXF1aXJlZC4gVGhlIHNlc3Npb24gZW50
aXR5IHR5cGUgdG8gdXBkYXRlLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xv
Y2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9zZXNzaW9ucy88U2Vzc2lv
bklEPi9lbnRpdHlUeXBlcy88RW50aXR5VHlwZUlEPmAKIG9yCiBgcHJvamVjdHMvPFByb2pl
Y3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Vudmlyb25t
ZW50cy88RW52aXJvbm1lbnRJRD4vc2Vzc2lvbnMvPFNlc3Npb25JRD4vZW50aXR5VHlwZXMv
PEVudGl0eVR5cGVJRD5gLgogSWYgYEVudmlyb25tZW50IElEYCBpcyBub3Qgc3BlY2lmaWVk
LCB3ZSBhc3N1bWUgZGVmYXVsdCAnZHJhZnQnCiBlbnZpcm9ubWVudC4KCg0KBQQFAgAGEgSA
AgITCg0KBQQFAgABEgSAAhQnCg0KBQQFAgADEgSAAiorCg0KBQQFAgAIEgSBAgYuChAKCAQF
AgAInAgAEgSBAgctCj0KBAQFAgESBIQCAiwaLyBUaGUgbWFzayB0byBjb250cm9sIHdoaWNo
IGZpZWxkcyBnZXQgdXBkYXRlZC4KCg0KBQQFAgEGEgSEAgIbCg0KBQQFAgEBEgSEAhwnCg0K
BQQFAgEDEgSEAiorCqYBCgIEBhIGiQIAlwIBGpcBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbU2Vzc2lvbkVudGl0eVR5cGVzLkRlbGV0ZVNlc3Npb25FbnRpdHlUeXBlXVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlNlc3Npb25FbnRpdHlUeXBlcy5EZWxldGVT
ZXNzaW9uRW50aXR5VHlwZV0uCgoLCgMEBgESBIkCCCYKpQMKBAQGAgASBpECApYCBBqUAyBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHNlc3Npb24gZW50aXR5IHR5cGUgdG8gZGVsZXRl
LgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25J
RD4vYWdlbnRzLzxBZ2VudElEPi9zZXNzaW9ucy88U2Vzc2lvbklEPi9lbnRpdHlUeXBlcy88
RW50aXR5VHlwZUlEPmAKIG9yCiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxM
b2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnRJ
RD4vc2Vzc2lvbnMvPFNlc3Npb25JRD4vZW50aXR5VHlwZXMvPEVudGl0eVR5cGVJRD5gLgog
SWYgYEVudmlyb25tZW50IElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVs
dCAnZHJhZnQnCiBlbnZpcm9ubWVudC4KCg0KBQQGAgAFEgSRAgIICg0KBQQGAgABEgSRAgkN
Cg0KBQQGAgADEgSRAhARCg8KBQQGAgAIEgaRAhKWAgMKEAoIBAYCAAicCAASBJICBCoKEQoH
BAYCAAifCBIGkwIElQIFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType ===
    # Fields for SessionEntityType
    # Field: name Type: 9 ()
    # Field: entity_override_mode Type: 14 (.google.cloud.dialogflow.cx.v3beta1.SessionEntityType.EntityOverrideMode)
    # Field: entities Type: 11 (.google.cloud.dialogflow.cx.v3beta1.EntityType.Entity)

# Enum: SessionEntityType::EntityOverrideMode
our $SessionEntityType_ENTITY_OVERRIDE_MODE_UNSPECIFIED = 0;
our $SessionEntityType_ENTITY_OVERRIDE_MODE_OVERRIDE = 1;
our $SessionEntityType_ENTITY_OVERRIDE_MODE_SUPPLEMENT = 2;

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesRequest ===
    # Fields for ListSessionEntityTypesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesResponse ===
    # Fields for ListSessionEntityTypesResponse
    # Field: session_entity_types Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SessionEntityType)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::GetSessionEntityTypeRequest ===
    # Fields for GetSessionEntityTypeRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::CreateSessionEntityTypeRequest ===
    # Fields for CreateSessionEntityTypeRequest
    # Field: parent Type: 9 ()
    # Field: session_entity_type Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SessionEntityType)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::UpdateSessionEntityTypeRequest ===
    # Fields for UpdateSessionEntityTypeRequest
    # Field: session_entity_type Type: 11 (.google.cloud.dialogflow.cx.v3beta1.SessionEntityType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::DeleteSessionEntityTypeRequest ===
    # Fields for DeleteSessionEntityTypeRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityTypesClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityTypesClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityTypesClient

Client stub representing the remote C<SessionEntityTypes> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub list_session_entity_types {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes',
        method         => 'ListSessionEntityTypes',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesResponse',
    });
}

sub get_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::GetSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes',
        method         => 'GetSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType',
    });
}

sub create_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::CreateSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes',
        method         => 'CreateSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType',
    });
}

sub update_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::UpdateSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes',
        method         => 'UpdateSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType',
    });
}

sub delete_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::DeleteSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes',
        method         => 'DeleteSessionEntityType',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/session_entity_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType->new({
        name => $name,
        entity_override_mode => $entity_override_mode,
        entities => $entities,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/session_entity_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType

Session entity types are referred to as B<User> entity types and are
entities that are built for an individual user such as favorites,
preferences, playlists, and so on.

You can redefine a session entity type at the session level to extend or
replace a [custom entity type][google.cloud.dialogflow.cx.v3beta1.EntityType]
at the user session level (we refer to the entity types defined at the agent
level as "custom entity types").

Note: session entity types apply to all queries, regardless of the language.

For more information about entity types, see the [Dialogflow
documentation](https://cloud.google.com/dialogflow/docs/entities-overview).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier of the session entity type.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment.

=item * C<< $msg->entity_override_mode() >> / C<< $msg->entity_override_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::EntityOverrideMode>)

Required. Indicates whether the additional data should override or
supplement the custom entity type definition.

=item * C<< $msg->entities() >> / C<< $msg->entities($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::EntityType::EntityType::Entity>)

Required. The collection of entities to override or supplement the custom
entity type.

=back

=head3 Enum: SessionEntityType::EntityOverrideMode

=over 4

=item * C<ENTITY_OVERRIDE_MODE_UNSPECIFIED> => C<0>

=item * C<ENTITY_OVERRIDE_MODE_OVERRIDE> => C<1>

=item * C<ENTITY_OVERRIDE_MODE_SUPPLEMENT> => C<2>

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesRequest

The request message for
[SessionEntityTypes.ListSessionEntityTypes][google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes.ListSessionEntityTypes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to list all session entity types from.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/sessions/<SessionID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/sessions/<SessionID>`.
If `Environment ID` is not specified, we assume default 'draft'
 environment.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 100 and
at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::ListSessionEntityTypesResponse

The response message for
[SessionEntityTypes.ListSessionEntityTypes][google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes.ListSessionEntityTypes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_entity_types() >> / C<< $msg->session_entity_types($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType>)

The list of session entity types. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::GetSessionEntityTypeRequest

The request message for
[SessionEntityTypes.GetSessionEntityType][google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes.GetSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the session entity type.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::CreateSessionEntityTypeRequest

The request message for
[SessionEntityTypes.CreateSessionEntityType][google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes.CreateSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to create a session entity type for.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/sessions/<SessionID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/sessions/<SessionID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment.

=item * C<< $msg->session_entity_type() >> / C<< $msg->session_entity_type($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType>)

Required. The session entity type to create.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::UpdateSessionEntityTypeRequest

The request message for
[SessionEntityTypes.UpdateSessionEntityType][google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes.UpdateSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_entity_type() >> / C<< $msg->session_entity_type($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::SessionEntityType>)

Required. The session entity type to update.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::DeleteSessionEntityTypeRequest

The request message for
[SessionEntityTypes.DeleteSessionEntityType][google.cloud.dialogflow.cx.v3beta1.SessionEntityTypes.DeleteSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the session entity type to delete.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
