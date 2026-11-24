package Google::Cloud::Dialogflow::V2::SessionEntityType;

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
    eval { require Google::Cloud::Dialogflow::V2::EntityType };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9zZXNzaW9uX2VudGl0eV90eXBlLnByb3Rv
Ehpnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLGdvb2dsZS9jbG91ZC9kaWFs
b2dmbG93L3YyL2VudGl0eV90eXBlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJv
dG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIsUGChFTZXNzaW9uRW50aXR5
VHlwZRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSdwoUZW50aXR5X292ZXJyaWRlX21vZGUY
AiABKA4yQC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TZXNzaW9uRW50aXR5VHlwZS5F
bnRpdHlPdmVycmlkZU1vZGVCA+BBAlISZW50aXR5T3ZlcnJpZGVNb2RlEk4KCGVudGl0aWVz
GAMgAygLMi0uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRW50aXR5VHlwZS5FbnRpdHlC
A+BBAlIIZW50aXRpZXMiggEKEkVudGl0eU92ZXJyaWRlTW9kZRIkCiBFTlRJVFlfT1ZFUlJJ
REVfTU9ERV9VTlNQRUNJRklFRBAAEiEKHUVOVElUWV9PVkVSUklERV9NT0RFX09WRVJSSURF
EAESIwofRU5USVRZX09WRVJSSURFX01PREVfU1VQUExFTUVOVBACOsgD6kHEAworZGlhbG9n
Zmxvdy5nb29nbGVhcGlzLmNvbS9TZXNzaW9uRW50aXR5VHlwZRJFcHJvamVjdHMve3Byb2pl
Y3R9L2FnZW50L3Nlc3Npb25zL3tzZXNzaW9ufS9lbnRpdHlUeXBlcy97ZW50aXR5X3R5cGV9
Em1wcm9qZWN0cy97cHJvamVjdH0vYWdlbnQvZW52aXJvbm1lbnRzL3tlbnZpcm9ubWVudH0v
dXNlcnMve3VzZXJ9L3Nlc3Npb25zL3tzZXNzaW9ufS9lbnRpdHlUeXBlcy97ZW50aXR5X3R5
cGV9Elpwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnQvc2Vz
c2lvbnMve3Nlc3Npb259L2VudGl0eVR5cGVzL3tlbnRpdHlfdHlwZX0SggFwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnQvZW52aXJvbm1lbnRzL3tlbnZp
cm9ubWVudH0vdXNlcnMve3VzZXJ9L3Nlc3Npb25zL3tzZXNzaW9ufS9lbnRpdHlUeXBlcy97
ZW50aXR5X3R5cGV9IrIBCh1MaXN0U2Vzc2lvbkVudGl0eVR5cGVzUmVxdWVzdBJLCgZwYXJl
bnQYASABKAlCM+BBAvpBLRIrZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9TZXNzaW9uRW50
aXR5VHlwZVIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKpAQoeTGlzdFNlc3Npb25FbnRpdHlU
eXBlc1Jlc3BvbnNlEl8KFHNlc3Npb25fZW50aXR5X3R5cGVzGAEgAygLMi0uZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjIuU2Vzc2lvbkVudGl0eVR5cGVSEnNlc3Npb25FbnRpdHlUeXBl
cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iZgobR2V0U2Vzc2lv
bkVudGl0eVR5cGVSZXF1ZXN0EkcKBG5hbWUYASABKAlCM+BBAvpBLQorZGlhbG9nZmxvdy5n
b29nbGVhcGlzLmNvbS9TZXNzaW9uRW50aXR5VHlwZVIEbmFtZSLRAQoeQ3JlYXRlU2Vzc2lv
bkVudGl0eVR5cGVSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtEitkaWFsb2dmbG93
Lmdvb2dsZWFwaXMuY29tL1Nlc3Npb25FbnRpdHlUeXBlUgZwYXJlbnQSYgoTc2Vzc2lvbl9l
bnRpdHlfdHlwZRgCIAEoCzItLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlNlc3Npb25F
bnRpdHlUeXBlQgPgQQJSEXNlc3Npb25FbnRpdHlUeXBlIsYBCh5VcGRhdGVTZXNzaW9uRW50
aXR5VHlwZVJlcXVlc3QSYgoTc2Vzc2lvbl9lbnRpdHlfdHlwZRgBIAEoCzItLmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyLlNlc3Npb25FbnRpdHlUeXBlQgPgQQJSEXNlc3Npb25FbnRp
dHlUeXBlEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFz
a0ID4EEBUgp1cGRhdGVNYXNrImkKHkRlbGV0ZVNlc3Npb25FbnRpdHlUeXBlUmVxdWVzdBJH
CgRuYW1lGAEgASgJQjPgQQL6QS0KK2RpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vU2Vzc2lv
bkVudGl0eVR5cGVSBG5hbWUy6hQKElNlc3Npb25FbnRpdHlUeXBlcxLGAwoWTGlzdFNlc3Np
b25FbnRpdHlUeXBlcxI5Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkxpc3RTZXNzaW9u
RW50aXR5VHlwZXNSZXF1ZXN0GjouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuTGlzdFNl
c3Npb25FbnRpdHlUeXBlc1Jlc3BvbnNlIrQCgtPkkwKkAhI0L3YyL3twYXJlbnQ9cHJvamVj
dHMvKi9hZ2VudC9zZXNzaW9ucy8qfS9lbnRpdHlUeXBlc1pNEksvdjIve3BhcmVudD1wcm9q
ZWN0cy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKn0vZW50aXR5
VHlwZXNaQhJAL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9zZXNz
aW9ucy8qfS9lbnRpdHlUeXBlc1pZElcvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKn0vZW50aXR5VHlw
ZXPaQQZwYXJlbnQSswMKFEdldFNlc3Npb25FbnRpdHlUeXBlEjcuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjIuR2V0U2Vzc2lvbkVudGl0eVR5cGVSZXF1ZXN0Gi0uZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjIuU2Vzc2lvbkVudGl0eVR5cGUisgKC0+STAqQCEjQvdjIve25hbWU9
cHJvamVjdHMvKi9hZ2VudC9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9Wk0SSy92Mi97bmFt
ZT1wcm9qZWN0cy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKi9l
bnRpdHlUeXBlcy8qfVpCEkAvdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2Vu
dC9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9WlkSVy92Mi97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lvbnMvKi9lbnRp
dHlUeXBlcy8qfdpBBG5hbWUSowQKF0NyZWF0ZVNlc3Npb25FbnRpdHlUeXBlEjouZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ3JlYXRlU2Vzc2lvbkVudGl0eVR5cGVSZXF1ZXN0Gi0u
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuU2Vzc2lvbkVudGl0eVR5cGUinAOC0+STAvgC
IjQvdjIve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50L3Nlc3Npb25zLyp9L2VudGl0eVR5cGVz
OhNzZXNzaW9uX2VudGl0eV90eXBlWmIiSy92Mi97cGFyZW50PXByb2plY3RzLyovYWdlbnQv
ZW52aXJvbm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qfS9lbnRpdHlUeXBlczoTc2Vzc2lv
bl9lbnRpdHlfdHlwZVpXIkAvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Fn
ZW50L3Nlc3Npb25zLyp9L2VudGl0eVR5cGVzOhNzZXNzaW9uX2VudGl0eV90eXBlWm4iVy92
Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRzLyov
dXNlcnMvKi9zZXNzaW9ucy8qfS9lbnRpdHlUeXBlczoTc2Vzc2lvbl9lbnRpdHlfdHlwZdpB
GnBhcmVudCxzZXNzaW9uX2VudGl0eV90eXBlEo8FChdVcGRhdGVTZXNzaW9uRW50aXR5VHlw
ZRI6Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlVwZGF0ZVNlc3Npb25FbnRpdHlUeXBl
UmVxdWVzdBotLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlNlc3Npb25FbnRpdHlUeXBl
IogEgtPkkwLJAzJIL3YyL3tzZXNzaW9uX2VudGl0eV90eXBlLm5hbWU9cHJvamVjdHMvKi9h
Z2VudC9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9OhNzZXNzaW9uX2VudGl0eV90eXBlWnYy
Xy92Mi97c2Vzc2lvbl9lbnRpdHlfdHlwZS5uYW1lPXByb2plY3RzLyovYWdlbnQvZW52aXJv
bm1lbnRzLyovdXNlcnMvKi9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9OhNzZXNzaW9uX2Vu
dGl0eV90eXBlWmsyVC92Mi97c2Vzc2lvbl9lbnRpdHlfdHlwZS5uYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovYWdlbnQvc2Vzc2lvbnMvKi9lbnRpdHlUeXBlcy8qfToTc2Vzc2lvbl9l
bnRpdHlfdHlwZVqCATJrL3YyL3tzZXNzaW9uX2VudGl0eV90eXBlLm5hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9hZ2VudC9lbnZpcm9ubWVudHMvKi91c2Vycy8qL3Nlc3Npb25zLyov
ZW50aXR5VHlwZXMvKn06E3Nlc3Npb25fZW50aXR5X3R5cGXaQRNzZXNzaW9uX2VudGl0eV90
eXBl2kEfc2Vzc2lvbl9lbnRpdHlfdHlwZSx1cGRhdGVfbWFzaxKiAwoXRGVsZXRlU2Vzc2lv
bkVudGl0eVR5cGUSOi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5EZWxldGVTZXNzaW9u
RW50aXR5VHlwZVJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkisgKC0+STAqQCKjQv
djIve25hbWU9cHJvamVjdHMvKi9hZ2VudC9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9Wk0q
Sy92Mi97bmFtZT1wcm9qZWN0cy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vz
c2lvbnMvKi9lbnRpdHlUeXBlcy8qfVpCKkAvdjIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9hZ2VudC9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9WlkqVy92Mi97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50L2Vudmlyb25tZW50cy8qL3VzZXJzLyovc2Vzc2lv
bnMvKi9lbnRpdHlUeXBlcy8qfdpBBG5hbWUaeMpBGWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5j
b23SQVlodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlhbG9nZmxvd0KcAQoeY29tLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyQhZTZXNzaW9uRW50aXR5VHlwZVByb3RvUAFaPmNsb3Vk
Lmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2Mi9kaWFsb2dmbG93cGI7ZGlhbG9nZmxv
d3BiogICREaqAhpHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkqMSwoHEgUOAMkCAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgAmCgkK
AgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADYKCQoCAwUSAxcAJQoJ
CgIDBhIDGAAqCggKAQgSAxoANwoJCgIIJRIDGgA3CggKAQgSAxsAVQoJCgIICxIDGwBVCggK
AQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANwoJCgIICBIDHQA3CggKAQgSAx4ANwoJCgII
ARIDHgA3CggKAQgSAx8AIAoJCgIIJBIDHwAgCmgKAgYAEgUjAKIBARpbIFNlcnZpY2UgZm9y
IG1hbmFnaW5nCiBbU2Vzc2lvbkVudGl0eVR5cGVzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5TZXNzaW9uRW50aXR5VHlwZV0uCgoKCgMGAAESAyMIGgoKCgMGAAMSAyQCQQoMCgUG
AAOZCBIDJAJBCgsKAwYAAxIEJQInMwoNCgUGAAOaCBIEJQInMwr5AQoEBgACABIELgI9Axrq
ASBSZXR1cm5zIHRoZSBsaXN0IG9mIGFsbCBzZXNzaW9uIGVudGl0eSB0eXBlcyBpbiB0aGUg
c3BlY2lmaWVkIHNlc3Npb24uCgogVGhpcyBtZXRob2QgZG9lc24ndCB3b3JrIHdpdGggR29v
Z2xlIEFzc2lzdGFudCBpbnRlZ3JhdGlvbi4KIENvbnRhY3QgRGlhbG9nZmxvdyBzdXBwb3J0
IGlmIHlvdSBuZWVkIHRvIHVzZSBzZXNzaW9uIGVudGl0aWVzCiB3aXRoIEdvb2dsZSBBc3Np
c3RhbnQgaW50ZWdyYXRpb24uCgoMCgUGAAIAARIDLgYcCgwKBQYAAgACEgMuHToKDAoFBgAC
AAMSAy8PLQoNCgUGAAIABBIEMAQ7BgoRCgkGAAIABLDKvCISBDAEOwYKDAoFBgACAAQSAzwE
NAoPCggGAAIABJsIABIDPAQ0Ct8BCgQGAAIBEgREAlMDGtABIFJldHJpZXZlcyB0aGUgc3Bl
Y2lmaWVkIHNlc3Npb24gZW50aXR5IHR5cGUuCgogVGhpcyBtZXRob2QgZG9lc24ndCB3b3Jr
IHdpdGggR29vZ2xlIEFzc2lzdGFudCBpbnRlZ3JhdGlvbi4KIENvbnRhY3QgRGlhbG9nZmxv
dyBzdXBwb3J0IGlmIHlvdSBuZWVkIHRvIHVzZSBzZXNzaW9uIGVudGl0aWVzCiB3aXRoIEdv
b2dsZSBBc3Npc3RhbnQgaW50ZWdyYXRpb24uCgoMCgUGAAIBARIDRAYaCgwKBQYAAgECEgNE
GzYKDAoFBgACAQMSA0UPIAoNCgUGAAIBBBIERgRRBgoRCgkGAAIBBLDKvCISBEYEUQYKDAoF
BgACAQQSA1IEMgoPCggGAAIBBJsIABIDUgQyCqwCCgQGAAICEgRdAnADGp0CIENyZWF0ZXMg
YSBzZXNzaW9uIGVudGl0eSB0eXBlLgoKIElmIHRoZSBzcGVjaWZpZWQgc2Vzc2lvbiBlbnRp
dHkgdHlwZSBhbHJlYWR5IGV4aXN0cywgb3ZlcnJpZGVzIHRoZSBzZXNzaW9uCiBlbnRpdHkg
dHlwZS4KCiBUaGlzIG1ldGhvZCBkb2Vzbid0IHdvcmsgd2l0aCBHb29nbGUgQXNzaXN0YW50
IGludGVncmF0aW9uLgogQ29udGFjdCBEaWFsb2dmbG93IHN1cHBvcnQgaWYgeW91IG5lZWQg
dG8gdXNlIHNlc3Npb24gZW50aXRpZXMKIHdpdGggR29vZ2xlIEFzc2lzdGFudCBpbnRlZ3Jh
dGlvbi4KCgwKBQYAAgIBEgNdBh0KDAoFBgACAgISA10ePAoMCgUGAAICAxIDXg8gCg0KBQYA
AgIEEgRfBG4GChEKCQYAAgIEsMq8IhIEXwRuBgoMCgUGAAICBBIDbwRICg8KCAYAAgIEmwgA
EgNvBEgK3gEKBAYAAgMSBXcCiwEDGs4BIFVwZGF0ZXMgdGhlIHNwZWNpZmllZCBzZXNzaW9u
IGVudGl0eSB0eXBlLgoKIFRoaXMgbWV0aG9kIGRvZXNuJ3Qgd29yayB3aXRoIEdvb2dsZSBB
c3Npc3RhbnQgaW50ZWdyYXRpb24uCiBDb250YWN0IERpYWxvZ2Zsb3cgc3VwcG9ydCBpZiB5
b3UgbmVlZCB0byB1c2Ugc2Vzc2lvbiBlbnRpdGllcwogd2l0aCBHb29nbGUgQXNzaXN0YW50
IGludGVncmF0aW9uLgoKDAoFBgACAwESA3cGHQoMCgUGAAIDAhIDdx48CgwKBQYAAgMDEgN4
DyAKDgoFBgACAwQSBXkEiAEGChIKCQYAAgMEsMq8IhIFeQSIAQYKDQoFBgACAwQSBIkBBEEK
EAoIBgACAwSbCAASBIkBBEEKDQoFBgACAwQSBIoBBE0KEAoIBgACAwSbCAESBIoBBE0K3wEK
BAYAAgQSBpIBAqEBAxrOASBEZWxldGVzIHRoZSBzcGVjaWZpZWQgc2Vzc2lvbiBlbnRpdHkg
dHlwZS4KCiBUaGlzIG1ldGhvZCBkb2Vzbid0IHdvcmsgd2l0aCBHb29nbGUgQXNzaXN0YW50
IGludGVncmF0aW9uLgogQ29udGFjdCBEaWFsb2dmbG93IHN1cHBvcnQgaWYgeW91IG5lZWQg
dG8gdXNlIHNlc3Npb24gZW50aXRpZXMKIHdpdGggR29vZ2xlIEFzc2lzdGFudCBpbnRlZ3Jh
dGlvbi4KCg0KBQYAAgQBEgSSAQYdCg0KBQYAAgQCEgSSAR48Cg0KBQYAAgQDEgSTAQ8kCg8K
BQYAAgQEEgaUAQSfAQYKEwoJBgACBASwyrwiEgaUAQSfAQYKDQoFBgACBAQSBKABBDIKEAoI
BgACBASbCAASBKABBDIK8wMKAgQAEgasAQDgAQEa5AMgQSBzZXNzaW9uIHJlcHJlc2VudHMg
YSBjb252ZXJzYXRpb24gYmV0d2VlbiBhIERpYWxvZ2Zsb3cgYWdlbnQgYW5kIGFuCiBlbmQt
dXNlci4gWW91IGNhbiBjcmVhdGUgc3BlY2lhbCBlbnRpdGllcywgY2FsbGVkIHNlc3Npb24g
ZW50aXRpZXMsIGR1cmluZyBhCiBzZXNzaW9uLiBTZXNzaW9uIGVudGl0aWVzIGNhbiBleHRl
bmQgb3IgcmVwbGFjZSBjdXN0b20gZW50aXR5IHR5cGVzIGFuZCBvbmx5CiBleGlzdCBkdXJp
bmcgdGhlIHNlc3Npb24gdGhhdCB0aGV5IHdlcmUgY3JlYXRlZCBmb3IuIEFsbCBzZXNzaW9u
IGRhdGEsCiBpbmNsdWRpbmcgc2Vzc2lvbiBlbnRpdGllcywgaXMgc3RvcmVkIGJ5IERpYWxv
Z2Zsb3cgZm9yIDIwIG1pbnV0ZXMuCgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZSB0aGUg
W3Nlc3Npb24gZW50aXR5CiBndWlkZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxv
Z2Zsb3cvZG9jcy9lbnRpdGllcy1zZXNzaW9uKS4KCgsKAwQAARIErAEIGQoNCgMEAAcSBq0B
ArMBBAoPCgUEAAedCBIGrQECswEECkcKBAQABAASBrYBAskBAxo3IFRoZSB0eXBlcyBvZiBt
b2RpZmljYXRpb25zIGZvciBhIHNlc3Npb24gZW50aXR5IHR5cGUuCgoNCgUEAAQAARIEtgEH
GQpBCgYEAAQAAgASBLgBBCkaMSBOb3Qgc3BlY2lmaWVkLiBUaGlzIHZhbHVlIHNob3VsZCBi
ZSBuZXZlciB1c2VkLgoKDwoHBAAEAAIAARIEuAEEJAoPCgcEAAQAAgACEgS4AScoCoMBCgYE
AAQAAgESBLwBBCYacyBUaGUgY29sbGVjdGlvbiBvZiBzZXNzaW9uIGVudGl0aWVzIG92ZXJy
aWRlcyB0aGUgY29sbGVjdGlvbiBvZiBlbnRpdGllcwogaW4gdGhlIGNvcnJlc3BvbmRpbmcg
Y3VzdG9tIGVudGl0eSB0eXBlLgoKDwoHBAAEAAIBARIEvAEEIQoPCgcEAAQAAgECEgS8ASQl
CpIECgYEAAQAAgISBMgBBCgagQQgVGhlIGNvbGxlY3Rpb24gb2Ygc2Vzc2lvbiBlbnRpdGll
cyBleHRlbmRzIHRoZSBjb2xsZWN0aW9uIG9mIGVudGl0aWVzIGluCiB0aGUgY29ycmVzcG9u
ZGluZyBjdXN0b20gZW50aXR5IHR5cGUuCgogTm90ZTogRXZlbiBpbiB0aGlzIG92ZXJyaWRl
IG1vZGUgY2FsbHMgdG8gYExpc3RTZXNzaW9uRW50aXR5VHlwZXNgLAogYEdldFNlc3Npb25F
bnRpdHlUeXBlYCwgYENyZWF0ZVNlc3Npb25FbnRpdHlUeXBlYCBhbmQKIGBVcGRhdGVTZXNz
aW9uRW50aXR5VHlwZWAgb25seSByZXR1cm4gdGhlIGFkZGl0aW9uYWwgZW50aXRpZXMgYWRk
ZWQgaW4KIHRoaXMgc2Vzc2lvbiBlbnRpdHkgdHlwZS4gSWYgeW91IHdhbnQgdG8gZ2V0IHRo
ZSBzdXBwbGVtZW50ZWQgbGlzdCwKIHBsZWFzZSBjYWxsCiBbRW50aXR5VHlwZXMuR2V0RW50
aXR5VHlwZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRW50aXR5VHlwZXMuR2V0RW50
aXR5VHlwZV0KIG9uIHRoZSBjdXN0b20gZW50aXR5IHR5cGUgYW5kIG1lcmdlLgoKDwoHBAAE
AAICARIEyAEEIwoPCgcEAAQAAgICEgTIASYnCtsECgQEAAIAEgTVAQI7GswEIFJlcXVpcmVk
LiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhpcyBzZXNzaW9uIGVudGl0eSB0eXBlLiBG
b3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9u
IElEPi9lbnRpdHlUeXBlcy88RW50aXR5IFR5cGUKIERpc3BsYXkgTmFtZT5gLCBvciBgcHJv
amVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQKIElE
Pi91c2Vycy88VXNlciBJRD4vc2Vzc2lvbnMvPFNlc3Npb24gSUQ+L2VudGl0eVR5cGVzLzxF
bnRpdHkgVHlwZSBEaXNwbGF5CiBOYW1lPmAuCiBJZiBgRW52aXJvbm1lbnQgSURgIGlzIG5v
dCBzcGVjaWZpZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcKIGVudmlyb25tZW50LiBJ
ZiBgVXNlciBJRGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJy0nIHVz
ZXIuCgogYDxFbnRpdHkgVHlwZSBEaXNwbGF5IE5hbWU+YCBtdXN0IGJlIHRoZSBkaXNwbGF5
IG5hbWUgb2YgYW4gZXhpc3RpbmcgZW50aXR5CiB0eXBlIGluIHRoZSBzYW1lIGFnZW50IHRo
YXQgd2lsbCBiZSBvdmVycmlkZGVuIG9yIHN1cHBsZW1lbnRlZC4KCg0KBQQAAgAFEgTVAQII
Cg0KBQQAAgABEgTVAQkNCg0KBQQAAgADEgTVARARCg0KBQQAAgAIEgTVARI6ChAKCAQAAgAI
nAgAEgTVARM5CoMBCgQEAAIBEgbZAQLaAS8acyBSZXF1aXJlZC4gSW5kaWNhdGVzIHdoZXRo
ZXIgdGhlIGFkZGl0aW9uYWwgZGF0YSBzaG91bGQgb3ZlcnJpZGUgb3IKIHN1cHBsZW1lbnQg
dGhlIGN1c3RvbSBlbnRpdHkgdHlwZSBkZWZpbml0aW9uLgoKDQoFBAACAQYSBNkBAhQKDQoF
BAACAQESBNkBFSkKDQoFBAACAQMSBNkBLC0KDQoFBAACAQgSBNoBBi4KEAoIBAACAQicCAAS
BNoBBy0KYQoEBAACAhIG3gEC3wEvGlEgUmVxdWlyZWQuIFRoZSBjb2xsZWN0aW9uIG9mIGVu
dGl0aWVzIGFzc29jaWF0ZWQgd2l0aCB0aGlzIHNlc3Npb24gZW50aXR5CiB0eXBlLgoKDQoF
BAACAgQSBN4BAgoKDQoFBAACAgYSBN4BCxwKDQoFBAACAgESBN4BHSUKDQoFBAACAgMSBN4B
KCkKDQoFBAACAggSBN8BBi4KEAoIBAACAgicCAASBN8BBy0KnAEKAgQBEgbkAQD4AQEajQEg
VGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZXNzaW9uRW50aXR5VHlwZXMuTGlzdFNlc3Np
b25FbnRpdHlUeXBlc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuU2Vzc2lvbkVudGl0
eVR5cGVzLkxpc3RTZXNzaW9uRW50aXR5VHlwZXNdLgoKCwoDBAEBEgTkAQglCv8CCgQEAQIA
EgbrAQLwAQQa7gIgUmVxdWlyZWQuIFRoZSBzZXNzaW9uIHRvIGxpc3QgYWxsIHNlc3Npb24g
ZW50aXR5IHR5cGVzIGZyb20uCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdl
bnQvc2Vzc2lvbnMvPFNlc3Npb24gSUQ+YCBvcgogYHByb2plY3RzLzxQcm9qZWN0IElEPi9h
Z2VudC9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50IElEPi91c2Vycy88VXNlciBJRD4vCiBz
ZXNzaW9ucy88U2Vzc2lvbiBJRD5gLgogSWYgYEVudmlyb25tZW50IElEYCBpcyBub3Qgc3Bl
Y2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnZHJhZnQnCiBlbnZpcm9ubWVudC4gSWYgYFVz
ZXIgSURgIGlzIG5vdCBzcGVjaWZpZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICctJyB1c2VyLgoK
DQoFBAECAAUSBOsBAggKDQoFBAECAAESBOsBCQ8KDQoFBAECAAMSBOsBEhMKDwoFBAECAAgS
BusBFPABAwoQCggEAQIACJwIABIE7AEEKgoRCgcEAQIACJ8IEgbtAQTvAQUKcwoEBAECARIE
9AECPxplIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJu
IGluIGEgc2luZ2xlIHBhZ2UuIEJ5CiBkZWZhdWx0IDEwMCBhbmQgYXQgbW9zdCAxMDAwLgoK
DQoFBAECAQUSBPQBAgcKDQoFBAECAQESBPQBCBEKDQoFBAECAQMSBPQBFBUKDQoFBAECAQgS
BPQBFj4KEAoIBAECAQicCAASBPQBFz0KWgoEBAECAhIE9wECQRpMIE9wdGlvbmFsLiBUaGUg
bmV4dF9wYWdlX3Rva2VuIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJl
cXVlc3QuCgoNCgUEAQICBRIE9wECCAoNCgUEAQICARIE9wEJEwoNCgUEAQICAxIE9wEWFwoN
CgUEAQICCBIE9wEYQAoQCggEAQICCJwIABIE9wEZPwqdAQoCBAISBvwBAIQCARqOASBUaGUg
cmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtTZXNzaW9uRW50aXR5VHlwZXMuTGlzdFNlc3Npb25F
bnRpdHlUeXBlc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuU2Vzc2lvbkVudGl0eVR5
cGVzLkxpc3RTZXNzaW9uRW50aXR5VHlwZXNdLgoKCwoDBAIBEgT8AQgmCpEBCgQEAgIAEgT/
AQI2GoIBIFRoZSBsaXN0IG9mIHNlc3Npb24gZW50aXR5IHR5cGVzLiBUaGVyZSB3aWxsIGJl
IGEgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMKIHJldHVybmVkIGJhc2VkIG9uIHRoZSBwYWdl
X3NpemUgZmllbGQgaW4gdGhlIHJlcXVlc3QuCgoNCgUEAgIABBIE/wECCgoNCgUEAgIABhIE
/wELHAoNCgUEAgIAARIE/wEdMQoNCgUEAgIAAxIE/wE0NQpvCgQEAgIBEgSDAgIdGmEgVG9r
ZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0
aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQCAgEFEgSDAgII
Cg0KBQQCAgEBEgSDAgkYCg0KBQQCAgEDEgSDAhscCpgBCgIEAxIGiAIAlgIBGokBIFRoZSBy
ZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2Vzc2lvbkVudGl0eVR5cGVzLkdldFNlc3Npb25FbnRp
dHlUeXBlXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TZXNzaW9uRW50aXR5VHlwZXMu
R2V0U2Vzc2lvbkVudGl0eVR5cGVdLgoKCwoDBAMBEgSIAggjCr8DCgQEAwIAEgaQAgKVAgQa
rgMgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBzZXNzaW9uIGVudGl0eSB0eXBlLiBGb3Jt
YXQ6CiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9uIElE
Pi9lbnRpdHlUeXBlcy88RW50aXR5IFR5cGUKIERpc3BsYXkgTmFtZT5gIG9yIGBwcm9qZWN0
cy88UHJvamVjdCBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudAogSUQ+L3Vz
ZXJzLzxVc2VyIElEPi9zZXNzaW9ucy88U2Vzc2lvbiBJRD4vZW50aXR5VHlwZXMvPEVudGl0
eSBUeXBlIERpc3BsYXkKIE5hbWU+YC4KIElmIGBFbnZpcm9ubWVudCBJRGAgaXMgbm90IHNw
ZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJ2RyYWZ0JwogZW52aXJvbm1lbnQuIElmIGBV
c2VyIElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnLScgdXNlci4K
Cg0KBQQDAgAFEgSQAgIICg0KBQQDAgABEgSQAgkNCg0KBQQDAgADEgSQAhARCg8KBQQDAgAI
EgaQAhKVAgMKEAoIBAMCAAicCAASBJECBCoKEQoHBAMCAAifCBIGkgIElAIFCp4BCgIEBBIG
mgIAqwIBGo8BIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2Vzc2lvbkVudGl0eVR5cGVz
LkNyZWF0ZVNlc3Npb25FbnRpdHlUeXBlXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5T
ZXNzaW9uRW50aXR5VHlwZXMuQ3JlYXRlU2Vzc2lvbkVudGl0eVR5cGVdLgoKCwoDBAQBEgSa
AggmCv0CCgQEBAIAEgahAgKmAgQa7AIgUmVxdWlyZWQuIFRoZSBzZXNzaW9uIHRvIGNyZWF0
ZSBhIHNlc3Npb24gZW50aXR5IHR5cGUgZm9yLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2pl
Y3QgSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9uIElEPmAgb3IKIGBwcm9qZWN0cy88UHJv
amVjdCBJRD4vYWdlbnQvZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudCBJRD4vdXNlcnMvPFVz
ZXIgSUQ+Lwogc2Vzc2lvbnMvPFNlc3Npb24gSUQ+YC4KIElmIGBFbnZpcm9ubWVudCBJRGAg
aXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJ2RyYWZ0JwogZW52aXJvbm1l
bnQuIElmIGBVc2VyIElEYCBpcyBub3Qgc3BlY2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAn
LScgdXNlci4KCg0KBQQEAgAFEgShAgIICg0KBQQEAgABEgShAgkPCg0KBQQEAgADEgShAhIT
Cg8KBQQEAgAIEgahAhSmAgMKEAoIBAQCAAicCAASBKICBCoKEQoHBAQCAAifCBIGowIEpQIF
Cj4KBAQEAgESBqkCAqoCLxouIFJlcXVpcmVkLiBUaGUgc2Vzc2lvbiBlbnRpdHkgdHlwZSB0
byBjcmVhdGUuCgoNCgUEBAIBBhIEqQICEwoNCgUEBAIBARIEqQIUJwoNCgUEBAIBAxIEqQIq
KwoNCgUEBAIBCBIEqgIGLgoQCggEBAIBCJwIABIEqgIHLQqeAQoCBAUSBq8CALcCARqPASBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW1Nlc3Npb25FbnRpdHlUeXBlcy5VcGRhdGVTZXNz
aW9uRW50aXR5VHlwZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuU2Vzc2lvbkVudGl0
eVR5cGVzLlVwZGF0ZVNlc3Npb25FbnRpdHlUeXBlXS4KCgsKAwQFARIErwIIJgo+CgQEBQIA
EgaxAgKyAi8aLiBSZXF1aXJlZC4gVGhlIHNlc3Npb24gZW50aXR5IHR5cGUgdG8gdXBkYXRl
LgoKDQoFBAUCAAYSBLECAhMKDQoFBAUCAAESBLECFCcKDQoFBAUCAAMSBLECKisKDQoFBAUC
AAgSBLICBi4KEAoIBAUCAAicCAASBLICBy0KSQoEBAUCARIGtQICtgIvGjkgT3B0aW9uYWwu
IFRoZSBtYXNrIHRvIGNvbnRyb2wgd2hpY2ggZmllbGRzIGdldCB1cGRhdGVkLgoKDQoFBAUC
AQYSBLUCAhsKDQoFBAUCAQESBLUCHCcKDQoFBAUCAQMSBLUCKisKDQoFBAUCAQgSBLYCBi4K
EAoIBAUCAQicCAASBLYCBy0KngEKAgQGEga7AgDJAgEajwEgVGhlIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtTZXNzaW9uRW50aXR5VHlwZXMuRGVsZXRlU2Vzc2lvbkVudGl0eVR5cGVdW2dv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlNlc3Npb25FbnRpdHlUeXBlcy5EZWxldGVTZXNz
aW9uRW50aXR5VHlwZV0uCgoLCgMEBgESBLsCCCYKwQMKBAQGAgASBsMCAsgCBBqwAyBSZXF1
aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGVudGl0eSB0eXBlIHRvIGRlbGV0ZS4gRm9ybWF0Ogog
YHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9zZXNzaW9ucy88U2Vzc2lvbiBJRD4vZW50
aXR5VHlwZXMvPEVudGl0eSBUeXBlCiBEaXNwbGF5IE5hbWU+YCBvciBgcHJvamVjdHMvPFBy
b2plY3QgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQKIElEPi91c2Vycy88
VXNlciBJRD4vc2Vzc2lvbnMvPFNlc3Npb24gSUQ+L2VudGl0eVR5cGVzLzxFbnRpdHkgVHlw
ZSBEaXNwbGF5CiBOYW1lPmAuCiBJZiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZp
ZWQsIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcKIGVudmlyb25tZW50LiBJZiBgVXNlciBJ
RGAgaXMgbm90IHNwZWNpZmllZCwgd2UgYXNzdW1lIGRlZmF1bHQgJy0nIHVzZXIuCgoNCgUE
BgIABRIEwwICCAoNCgUEBgIAARIEwwIJDQoNCgUEBgIAAxIEwwIQEQoPCgUEBgIACBIGwwIS
yAIDChAKCAQGAgAInAgAEgTEAgQqChEKBwQGAgAInwgSBsUCBMcCBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType ===
    # Fields for SessionEntityType
    # Field: name Type: 9 ()
    # Field: entity_override_mode Type: 14 (.google.cloud.dialogflow.v2.SessionEntityType.EntityOverrideMode)
    # Field: entities Type: 11 (.google.cloud.dialogflow.v2.EntityType.Entity)

# Enum: SessionEntityType::EntityOverrideMode
our $SessionEntityType_ENTITY_OVERRIDE_MODE_UNSPECIFIED = 0;
our $SessionEntityType_ENTITY_OVERRIDE_MODE_OVERRIDE = 1;
our $SessionEntityType_ENTITY_OVERRIDE_MODE_SUPPLEMENT = 2;

# === Message: Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesRequest ===
    # Fields for ListSessionEntityTypesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesResponse ===
    # Fields for ListSessionEntityTypesResponse
    # Field: session_entity_types Type: 11 (.google.cloud.dialogflow.v2.SessionEntityType)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::SessionEntityType::GetSessionEntityTypeRequest ===
    # Fields for GetSessionEntityTypeRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::SessionEntityType::CreateSessionEntityTypeRequest ===
    # Fields for CreateSessionEntityTypeRequest
    # Field: parent Type: 9 ()
    # Field: session_entity_type Type: 11 (.google.cloud.dialogflow.v2.SessionEntityType)

# === Message: Google::Cloud::Dialogflow::V2::SessionEntityType::UpdateSessionEntityTypeRequest ===
    # Fields for UpdateSessionEntityTypeRequest
    # Field: session_entity_type Type: 11 (.google.cloud.dialogflow.v2.SessionEntityType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2::SessionEntityType::DeleteSessionEntityTypeRequest ===
    # Fields for DeleteSessionEntityTypeRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityTypesClient ===
package Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityTypesClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityTypesClient

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
        ? Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SessionEntityTypes',
        method         => 'ListSessionEntityTypes',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesResponse',
    });
}

sub get_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::SessionEntityType::GetSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SessionEntityTypes',
        method         => 'GetSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType',
    });
}

sub create_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::SessionEntityType::CreateSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SessionEntityTypes',
        method         => 'CreateSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType',
    });
}

sub update_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::SessionEntityType::UpdateSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SessionEntityTypes',
        method         => 'UpdateSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType',
    });
}

sub delete_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::SessionEntityType::DeleteSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.SessionEntityTypes',
        method         => 'DeleteSessionEntityType',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::SessionEntityType - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/session_entity_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::SessionEntityType;

    my $msg = Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType->new({
        name => $name,
        entity_override_mode => $entity_override_mode,
        entities => $entities,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/session_entity_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType

A session represents a conversation between a Dialogflow agent and an
end-user. You can create special entities, called session entities, during a
session. Session entities can extend or replace custom entity types and only
exist during the session that they were created for. All session data,
including session entities, is stored by Dialogflow for 20 minutes.

For more information, see the [session entity
guide](https://cloud.google.com/dialogflow/docs/entities-session).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier of this session entity type. Format:
`projects/<Project ID>/agent/sessions/<Session ID>/entityTypes/<Entity Type
Display Name>`, or `projects/<Project ID>/agent/environments/<Environment
ID>/users/<User ID>/sessions/<Session ID>/entityTypes/<Entity Type Display
Name>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

`<Entity Type Display Name>` must be the display name of an existing entity
type in the same agent that will be overridden or supplemented.

=item * C<< $msg->entity_override_mode() >> / C<< $msg->entity_override_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::SessionEntityType::EntityOverrideMode>)

Required. Indicates whether the additional data should override or
supplement the custom entity type definition.

=item * C<< $msg->entities() >> / C<< $msg->entities($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::EntityType::EntityType::Entity>)

Required. The collection of entities associated with this session entity
type.

=back

=head3 Enum: SessionEntityType::EntityOverrideMode

=over 4

=item * C<ENTITY_OVERRIDE_MODE_UNSPECIFIED> => C<0>

=item * C<ENTITY_OVERRIDE_MODE_OVERRIDE> => C<1>

=item * C<ENTITY_OVERRIDE_MODE_SUPPLEMENT> => C<2>

=back

=head2 Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesRequest

The request message for
[SessionEntityTypes.ListSessionEntityTypes][google.cloud.dialogflow.v2.SessionEntityTypes.ListSessionEntityTypes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to list all session entity types from.
Format: `projects/<Project ID>/agent/sessions/<Session ID>` or
`projects/<Project ID>/agent/environments/<Environment ID>/users/<User ID>/
sessions/<Session ID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesResponse

The response message for
[SessionEntityTypes.ListSessionEntityTypes][google.cloud.dialogflow.v2.SessionEntityTypes.ListSessionEntityTypes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_entity_types() >> / C<< $msg->session_entity_types($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType>)

The list of session entity types. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2::SessionEntityType::GetSessionEntityTypeRequest

The request message for
[SessionEntityTypes.GetSessionEntityType][google.cloud.dialogflow.v2.SessionEntityTypes.GetSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the session entity type. Format:
`projects/<Project ID>/agent/sessions/<Session ID>/entityTypes/<Entity Type
Display Name>` or `projects/<Project ID>/agent/environments/<Environment
ID>/users/<User ID>/sessions/<Session ID>/entityTypes/<Entity Type Display
Name>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

=back

=head2 Google::Cloud::Dialogflow::V2::SessionEntityType::CreateSessionEntityTypeRequest

The request message for
[SessionEntityTypes.CreateSessionEntityType][google.cloud.dialogflow.v2.SessionEntityTypes.CreateSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The session to create a session entity type for.
Format: `projects/<Project ID>/agent/sessions/<Session ID>` or
`projects/<Project ID>/agent/environments/<Environment ID>/users/<User ID>/
sessions/<Session ID>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

=item * C<< $msg->session_entity_type() >> / C<< $msg->session_entity_type($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType>)

Required. The session entity type to create.

=back

=head2 Google::Cloud::Dialogflow::V2::SessionEntityType::UpdateSessionEntityTypeRequest

The request message for
[SessionEntityTypes.UpdateSessionEntityType][google.cloud.dialogflow.v2.SessionEntityTypes.UpdateSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_entity_type() >> / C<< $msg->session_entity_type($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType>)

Required. The session entity type to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::V2::SessionEntityType::DeleteSessionEntityTypeRequest

The request message for
[SessionEntityTypes.DeleteSessionEntityType][google.cloud.dialogflow.v2.SessionEntityTypes.DeleteSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the entity type to delete. Format:
`projects/<Project ID>/agent/sessions/<Session ID>/entityTypes/<Entity Type
Display Name>` or `projects/<Project ID>/agent/environments/<Environment
ID>/users/<User ID>/sessions/<Session ID>/entityTypes/<Entity Type Display
Name>`.
If `Environment ID` is not specified, we assume default 'draft'
environment. If `User ID` is not specified, we assume default '-' user.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::SessionEntityType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
