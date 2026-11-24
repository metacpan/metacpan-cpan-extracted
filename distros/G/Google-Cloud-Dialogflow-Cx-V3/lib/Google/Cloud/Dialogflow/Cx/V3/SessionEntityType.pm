package Google::Cloud::Dialogflow::Cx::V3::SessionEntityType;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3::EntityType };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9zZXNzaW9uX2VudGl0eV90eXBlLnBy
b3RvEh1nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52MxocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aL2dvb2dsZS9jbG91
ZC9kaWFsb2dmbG93L2N4L3YzL2VudGl0eV90eXBlLnByb3RvGhtnb29nbGUvcHJvdG9idWYv
ZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIpkFChFTZXNz
aW9uRW50aXR5VHlwZRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSegoUZW50aXR5X292ZXJy
aWRlX21vZGUYAyABKA4yQy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZXNzaW9u
RW50aXR5VHlwZS5FbnRpdHlPdmVycmlkZU1vZGVCA+BBAlISZW50aXR5T3ZlcnJpZGVNb2Rl
ElEKCGVudGl0aWVzGAQgAygLMjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRW50
aXR5VHlwZS5FbnRpdHlCA+BBAlIIZW50aXRpZXMiggEKEkVudGl0eU92ZXJyaWRlTW9kZRIk
CiBFTlRJVFlfT1ZFUlJJREVfTU9ERV9VTlNQRUNJRklFRBAAEiEKHUVOVElUWV9PVkVSUklE
RV9NT0RFX09WRVJSSURFEAESIwofRU5USVRZX09WRVJSSURFX01PREVfU1VQUExFTUVOVBAC
OpYC6kGSAgorZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9TZXNzaW9uRW50aXR5VHlwZRJj
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50cy97YWdlbnR9
L3Nlc3Npb25zL3tzZXNzaW9ufS9lbnRpdHlUeXBlcy97ZW50aXR5X3R5cGV9En5wcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH0vZW52aXJv
bm1lbnRzL3tlbnZpcm9ubWVudH0vc2Vzc2lvbnMve3Nlc3Npb259L2VudGl0eVR5cGVzL3tl
bnRpdHlfdHlwZX0iqAEKHUxpc3RTZXNzaW9uRW50aXR5VHlwZXNSZXF1ZXN0EksKBnBhcmVu
dBgBIAEoCUIz4EEC+kEtEitkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Nlc3Npb25FbnRp
dHlUeXBlUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rv
a2VuGAMgASgJUglwYWdlVG9rZW4irAEKHkxpc3RTZXNzaW9uRW50aXR5VHlwZXNSZXNwb25z
ZRJiChRzZXNzaW9uX2VudGl0eV90eXBlcxgBIAMoCzIwLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzLlNlc3Npb25FbnRpdHlUeXBlUhJzZXNzaW9uRW50aXR5VHlwZXMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuImYKG0dldFNlc3Npb25FbnRpdHlU
eXBlUmVxdWVzdBJHCgRuYW1lGAEgASgJQjPgQQL6QS0KK2RpYWxvZ2Zsb3cuZ29vZ2xlYXBp
cy5jb20vU2Vzc2lvbkVudGl0eVR5cGVSBG5hbWUi1AEKHkNyZWF0ZVNlc3Npb25FbnRpdHlU
eXBlUmVxdWVzdBJLCgZwYXJlbnQYASABKAlCM+BBAvpBLRIrZGlhbG9nZmxvdy5nb29nbGVh
cGlzLmNvbS9TZXNzaW9uRW50aXR5VHlwZVIGcGFyZW50EmUKE3Nlc3Npb25fZW50aXR5X3R5
cGUYAiABKAsyMC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZXNzaW9uRW50aXR5
VHlwZUID4EECUhFzZXNzaW9uRW50aXR5VHlwZSLEAQoeVXBkYXRlU2Vzc2lvbkVudGl0eVR5
cGVSZXF1ZXN0EmUKE3Nlc3Npb25fZW50aXR5X3R5cGUYASABKAsyMC5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52My5TZXNzaW9uRW50aXR5VHlwZUID4EECUhFzZXNzaW9uRW50aXR5
VHlwZRI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tS
CnVwZGF0ZU1hc2siaQoeRGVsZXRlU2Vzc2lvbkVudGl0eVR5cGVSZXF1ZXN0EkcKBG5hbWUY
ASABKAlCM+BBAvpBLQorZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9TZXNzaW9uRW50aXR5
VHlwZVIEbmFtZTLFDgoSU2Vzc2lvbkVudGl0eVR5cGVzEsMCChZMaXN0U2Vzc2lvbkVudGl0
eVR5cGVzEjwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuTGlzdFNlc3Npb25FbnRp
dHlUeXBlc1JlcXVlc3QaPS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5MaXN0U2Vz
c2lvbkVudGl0eVR5cGVzUmVzcG9uc2UiqwGC0+STApsBEkMvdjMve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL3Nlc3Npb25zLyp9L2VudGl0eVR5cGVzWlQSUi92
My97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZW52aXJvbm1lbnRz
Lyovc2Vzc2lvbnMvKn0vZW50aXR5VHlwZXPaQQZwYXJlbnQSsAIKFEdldFNlc3Npb25FbnRp
dHlUeXBlEjouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuR2V0U2Vzc2lvbkVudGl0
eVR5cGVSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2Vzc2lvbkVu
dGl0eVR5cGUiqQGC0+STApsBEkMvdjMve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9h
Z2VudHMvKi9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9WlQSUi92My97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Vudmlyb25tZW50cy8qL3Nlc3Npb25zLyovZW50
aXR5VHlwZXMvKn3aQQRuYW1lEvYCChdDcmVhdGVTZXNzaW9uRW50aXR5VHlwZRI9Lmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkNyZWF0ZVNlc3Npb25FbnRpdHlUeXBlUmVxdWVz
dBowLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlNlc3Npb25FbnRpdHlUeXBlIukB
gtPkkwLFASJDL3YzL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9z
ZXNzaW9ucy8qfS9lbnRpdHlUeXBlczoTc2Vzc2lvbl9lbnRpdHlfdHlwZVppIlIvdjMve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Vudmlyb25tZW50cy8qL3Nl
c3Npb25zLyp9L2VudGl0eVR5cGVzOhNzZXNzaW9uX2VudGl0eV90eXBl2kEacGFyZW50LHNl
c3Npb25fZW50aXR5X3R5cGUSowMKF1VwZGF0ZVNlc3Npb25FbnRpdHlUeXBlEj0uZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVXBkYXRlU2Vzc2lvbkVudGl0eVR5cGVSZXF1ZXN0
GjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2Vzc2lvbkVudGl0eVR5cGUilgKC
0+STAu0BMlcvdjMve3Nlc3Npb25fZW50aXR5X3R5cGUubmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2FnZW50cy8qL3Nlc3Npb25zLyovZW50aXR5VHlwZXMvKn06E3Nlc3Npb25fZW50
aXR5X3R5cGVafTJmL3YzL3tzZXNzaW9uX2VudGl0eV90eXBlLm5hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9hZ2VudHMvKi9lbnZpcm9ubWVudHMvKi9zZXNzaW9ucy8qL2VudGl0eVR5
cGVzLyp9OhNzZXNzaW9uX2VudGl0eV90eXBl2kEfc2Vzc2lvbl9lbnRpdHlfdHlwZSx1cGRh
dGVfbWFzaxKcAgoXRGVsZXRlU2Vzc2lvbkVudGl0eVR5cGUSPS5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52My5EZWxldGVTZXNzaW9uRW50aXR5VHlwZVJlcXVlc3QaFi5nb29nbGUu
cHJvdG9idWYuRW1wdHkiqQGC0+STApsBKkMvdjMve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9hZ2VudHMvKi9zZXNzaW9ucy8qL2VudGl0eVR5cGVzLyp9WlQqUi92My97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Vudmlyb25tZW50cy8qL3Nlc3Npb25z
LyovZW50aXR5VHlwZXMvKn3aQQRuYW1lGnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t
0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dCuQEKIWNvbS5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M0IWU2Vzc2lvbkVudGl0eVR5cGVQcm90b1ABWjFjbG91
ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvY3gvYXBpdjMvY3hwYjtjeHBiogICREaqAh1H
b29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5DeC5WM+oCIUdvb2dsZTo6Q2xvdWQ6OkRpYWxvZ2Zs
b3c6OkNYOjpWM0ryRAoHEgUOAJcCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAJgoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQAjCgkKAgMEEgMWADkKCQoCAwUSAxcAJQoJCgIDBhIDGAAqCggKAQgSAxoAOgoJCgIIJRID
GgA6CggKAQgSAxsASAoJCgIICxIDGwBICggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0A
NwoJCgIICBIDHQA3CggKAQgSAx4AOgoJCgIIARIDHgA6CggKAQgSAx8AIAoJCgIIJBIDHwAg
CggKAQgSAyAAOgoJCgIILRIDIAA6CmoKAgYAEgQkAGkBGl4gU2VydmljZSBmb3IgbWFuYWdp
bmcKIFtTZXNzaW9uRW50aXR5VHlwZXNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
LlNlc3Npb25FbnRpdHlUeXBlXS4KCgoKAwYAARIDJAgaCgoKAwYAAxIDJQJBCgwKBQYAA5kI
EgMlAkEKCwoDBgADEgQmAigzCg0KBQYAA5oIEgQmAigzClYKBAYAAgASBCsCNAMaSCBSZXR1
cm5zIHRoZSBsaXN0IG9mIGFsbCBzZXNzaW9uIGVudGl0eSB0eXBlcyBpbiB0aGUgc3BlY2lm
aWVkIHNlc3Npb24uCgoMCgUGAAIAARIDKwYcCgwKBQYAAgACEgMrHToKDAoFBgACAAMSAywP
LQoNCgUGAAIABBIELQQyBgoRCgkGAAIABLDKvCISBC0EMgYKDAoFBgACAAQSAzMENAoPCggG
AAIABJsIABIDMwQ0CjwKBAYAAgESBDcCQAMaLiBSZXRyaWV2ZXMgdGhlIHNwZWNpZmllZCBz
ZXNzaW9uIGVudGl0eSB0eXBlLgoKDAoFBgACAQESAzcGGgoMCgUGAAIBAhIDNxs2CgwKBQYA
AgEDEgM4DyAKDQoFBgACAQQSBDkEPgYKEQoJBgACAQSwyrwiEgQ5BD4GCgwKBQYAAgEEEgM/
BDIKDwoIBgACAQSbCAASAz8EMgouCgQGAAICEgRDAk4DGiAgQ3JlYXRlcyBhIHNlc3Npb24g
ZW50aXR5IHR5cGUuCgoMCgUGAAICARIDQwYdCgwKBQYAAgICEgNDHjwKDAoFBgACAgMSA0QP
IAoNCgUGAAICBBIERQRMBgoRCgkGAAICBLDKvCISBEUETAYKDAoFBgACAgQSA00ESAoPCggG
AAICBJsIABIDTQRICjoKBAYAAgMSBFECXAMaLCBVcGRhdGVzIHRoZSBzcGVjaWZpZWQgc2Vz
c2lvbiBlbnRpdHkgdHlwZS4KCgwKBQYAAgMBEgNRBh0KDAoFBgACAwISA1EePAoMCgUGAAID
AxIDUg8gCg0KBQYAAgMEEgRTBFoGChEKCQYAAgMEsMq8IhIEUwRaBgoMCgUGAAIDBBIDWwRN
Cg8KCAYAAgMEmwgAEgNbBE0KOgoEBgACBBIEXwJoAxosIERlbGV0ZXMgdGhlIHNwZWNpZmll
ZCBzZXNzaW9uIGVudGl0eSB0eXBlLgoKDAoFBgACBAESA18GHQoMCgUGAAIEAhIDXx48CgwK
BQYAAgQDEgNgDyQKDQoFBgACBAQSBGEEZgYKEQoJBgACBASwyrwiEgRhBGYGCgwKBQYAAgQE
EgNnBDIKDwoIBgACBASbCAASA2cEMgqcBQoCBAASBXgApwEBGo4FIFNlc3Npb24gZW50aXR5
IHR5cGVzIGFyZSByZWZlcnJlZCB0byBhcyAqKlVzZXIqKiBlbnRpdHkgdHlwZXMgYW5kIGFy
ZQogZW50aXRpZXMgdGhhdCBhcmUgYnVpbHQgZm9yIGFuIGluZGl2aWR1YWwgdXNlciBzdWNo
IGFzIGZhdm9yaXRlcywKIHByZWZlcmVuY2VzLCBwbGF5bGlzdHMsIGFuZCBzbyBvbi4KCiBZ
b3UgY2FuIHJlZGVmaW5lIGEgc2Vzc2lvbiBlbnRpdHkgdHlwZSBhdCB0aGUgc2Vzc2lvbiBs
ZXZlbCB0byBleHRlbmQgb3IKIHJlcGxhY2UgYSBbY3VzdG9tIGVudGl0eSB0eXBlXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5FbnRpdHlUeXBlXSBhdAogdGhlIHVzZXIgc2Vz
c2lvbiBsZXZlbCAod2UgcmVmZXIgdG8gdGhlIGVudGl0eSB0eXBlcyBkZWZpbmVkIGF0IHRo
ZSBhZ2VudAogbGV2ZWwgYXMgImN1c3RvbSBlbnRpdHkgdHlwZXMiKS4KCiBOb3RlOiBzZXNz
aW9uIGVudGl0eSB0eXBlcyBhcHBseSB0byBhbGwgcXVlcmllcywgcmVnYXJkbGVzcyBvZiB0
aGUgbGFuZ3VhZ2UuCgogRm9yIG1vcmUgaW5mb3JtYXRpb24gYWJvdXQgZW50aXR5IHR5cGVz
LCBzZWUgdGhlIFtEaWFsb2dmbG93CiBkb2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vZGlhbG9nZmxvdy9kb2NzL2VudGl0aWVzLW92ZXJ2aWV3KS4KCgoKAwQAARID
eAgZCgsKAwQABxIEeQJ9BAoNCgUEAAedCBIEeQJ9BApJCgQEAAQAEgaAAQKTAQMaOSBUaGUg
dHlwZXMgb2YgbW9kaWZpY2F0aW9ucyBmb3IgdGhlIHNlc3Npb24gZW50aXR5IHR5cGUuCgoN
CgUEAAQAARIEgAEHGQpBCgYEAAQAAgASBIIBBCkaMSBOb3Qgc3BlY2lmaWVkLiBUaGlzIHZh
bHVlIHNob3VsZCBiZSBuZXZlciB1c2VkLgoKDwoHBAAEAAIAARIEggEEJAoPCgcEAAQAAgAC
EgSCAScoCoMBCgYEAAQAAgESBIYBBCYacyBUaGUgY29sbGVjdGlvbiBvZiBzZXNzaW9uIGVu
dGl0aWVzIG92ZXJyaWRlcyB0aGUgY29sbGVjdGlvbiBvZiBlbnRpdGllcwogaW4gdGhlIGNv
cnJlc3BvbmRpbmcgY3VzdG9tIGVudGl0eSB0eXBlLgoKDwoHBAAEAAIBARIEhgEEIQoPCgcE
AAQAAgECEgSGASQlCpUECgYEAAQAAgISBJIBBCgahAQgVGhlIGNvbGxlY3Rpb24gb2Ygc2Vz
c2lvbiBlbnRpdGllcyBleHRlbmRzIHRoZSBjb2xsZWN0aW9uIG9mIGVudGl0aWVzIGluCiB0
aGUgY29ycmVzcG9uZGluZyBjdXN0b20gZW50aXR5IHR5cGUuCgogTm90ZTogRXZlbiBpbiB0
aGlzIG92ZXJyaWRlIG1vZGUgY2FsbHMgdG8gYExpc3RTZXNzaW9uRW50aXR5VHlwZXNgLAog
YEdldFNlc3Npb25FbnRpdHlUeXBlYCwgYENyZWF0ZVNlc3Npb25FbnRpdHlUeXBlYCBhbmQK
IGBVcGRhdGVTZXNzaW9uRW50aXR5VHlwZWAgb25seSByZXR1cm4gdGhlIGFkZGl0aW9uYWwg
ZW50aXRpZXMgYWRkZWQgaW4KIHRoaXMgc2Vzc2lvbiBlbnRpdHkgdHlwZS4gSWYgeW91IHdh
bnQgdG8gZ2V0IHRoZSBzdXBwbGVtZW50ZWQgbGlzdCwKIHBsZWFzZSBjYWxsCiBbRW50aXR5
VHlwZXMuR2V0RW50aXR5VHlwZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRW50
aXR5VHlwZXMuR2V0RW50aXR5VHlwZV0KIG9uIHRoZSBjdXN0b20gZW50aXR5IHR5cGUgYW5k
IG1lcmdlLgoKDwoHBAAEAAICARIEkgEEIwoPCgcEAAQAAgICEgSSASYnCqYDCgQEAAIAEgSc
AQI7GpcDIFJlcXVpcmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIHNlc3Npb24g
ZW50aXR5IHR5cGUuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25z
LzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L3Nlc3Npb25zLzxTZXNzaW9uSUQ+L2Vu
dGl0eVR5cGVzLzxFbnRpdHlUeXBlSUQ+YAogb3IKIGBwcm9qZWN0cy88UHJvamVjdElEPi9s
b2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZW52aXJvbm1lbnRzLzxF
bnZpcm9ubWVudElEPi9zZXNzaW9ucy88U2Vzc2lvbklEPi9lbnRpdHlUeXBlcy88RW50aXR5
VHlwZUlEPmAuCiBJZiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZpZWQsIHdlIGFz
c3VtZSBkZWZhdWx0ICdkcmFmdCcKIGVudmlyb25tZW50LgoKDQoFBAACAAUSBJwBAggKDQoF
BAACAAESBJwBCQ0KDQoFBAACAAMSBJwBEBEKDQoFBAACAAgSBJwBEjoKEAoIBAACAAicCAAS
BJwBEzkKgwEKBAQAAgESBqABAqEBLxpzIFJlcXVpcmVkLiBJbmRpY2F0ZXMgd2hldGhlciB0
aGUgYWRkaXRpb25hbCBkYXRhIHNob3VsZCBvdmVycmlkZSBvcgogc3VwcGxlbWVudCB0aGUg
Y3VzdG9tIGVudGl0eSB0eXBlIGRlZmluaXRpb24uCgoNCgUEAAIBBhIEoAECFAoNCgUEAAIB
ARIEoAEVKQoNCgUEAAIBAxIEoAEsLQoNCgUEAAIBCBIEoQEGLgoQCggEAAIBCJwIABIEoQEH
LQppCgQEAAICEgalAQKmAS8aWSBSZXF1aXJlZC4gVGhlIGNvbGxlY3Rpb24gb2YgZW50aXRp
ZXMgdG8gb3ZlcnJpZGUgb3Igc3VwcGxlbWVudCB0aGUgY3VzdG9tCiBlbnRpdHkgdHlwZS4K
Cg0KBQQAAgIEEgSlAQIKCg0KBQQAAgIGEgSlAQscCg0KBQQAAgIBEgSlAR0lCg0KBQQAAgID
EgSlASgpCg0KBQQAAgIIEgSmAQYuChAKCAQAAgIInAgAEgSmAQctCp8BCgIEARIGqwEAwAEB
GpABIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2Vzc2lvbkVudGl0eVR5cGVzLkxpc3RT
ZXNzaW9uRW50aXR5VHlwZXNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlNlc3Np
b25FbnRpdHlUeXBlcy5MaXN0U2Vzc2lvbkVudGl0eVR5cGVzXS4KCgsKAwQBARIEqwEIJQrz
AgoEBAECABIGswECuAEEGuICIFJlcXVpcmVkLiBUaGUgc2Vzc2lvbiB0byBsaXN0IGFsbCBz
ZXNzaW9uIGVudGl0eSB0eXBlcyBmcm9tLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0
SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9zZXNzaW9ucy88
U2Vzc2lvbklEPmAKIG9yCiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2Nh
dGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnRJRD4v
c2Vzc2lvbnMvPFNlc3Npb25JRD5gLgogSWYgYEVudmlyb25tZW50IElEYCBpcyBub3Qgc3Bl
Y2lmaWVkLCB3ZSBhc3N1bWUgZGVmYXVsdCAnZHJhZnQnCiBlbnZpcm9ubWVudC4KCg0KBQQB
AgAFEgSzAQIICg0KBQQBAgABEgSzAQkPCg0KBQQBAgADEgSzARITCg8KBQQBAgAIEgazARS4
AQMKEAoIBAECAAicCAASBLQBBCoKEQoHBAECAAifCBIGtQEEtwEFCmkKBAQBAgESBLwBAhYa
WyBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGluIGEgc2luZ2xlIHBh
Z2UuIEJ5IGRlZmF1bHQgMTAwIGFuZAogYXQgbW9zdCAxMDAwLgoKDQoFBAECAQUSBLwBAgcK
DQoFBAECAQESBLwBCBEKDQoFBAECAQMSBLwBFBUKUAoEBAECAhIEvwECGBpCIFRoZSBuZXh0
X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGxpc3QgcmVxdWVz
dC4KCg0KBQQBAgIFEgS/AQIICg0KBQQBAgIBEgS/AQkTCg0KBQQBAgIDEgS/ARYXCqABCgIE
AhIGxAEAzAEBGpEBIFRoZSByZXNwb25zZSBtZXNzYWdlIGZvcgogW1Nlc3Npb25FbnRpdHlU
eXBlcy5MaXN0U2Vzc2lvbkVudGl0eVR5cGVzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52My5TZXNzaW9uRW50aXR5VHlwZXMuTGlzdFNlc3Npb25FbnRpdHlUeXBlc10uCgoLCgME
AgESBMQBCCYKkQEKBAQCAgASBMcBAjYaggEgVGhlIGxpc3Qgb2Ygc2Vzc2lvbiBlbnRpdHkg
dHlwZXMuIFRoZXJlIHdpbGwgYmUgYSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcwogcmV0dXJu
ZWQgYmFzZWQgb24gdGhlIHBhZ2Vfc2l6ZSBmaWVsZCBpbiB0aGUgcmVxdWVzdC4KCg0KBQQC
AgAEEgTHAQIKCg0KBQQCAgAGEgTHAQscCg0KBQQCAgABEgTHAR0xCg0KBQQCAgADEgTHATQ1
Cm8KBAQCAgESBMsBAh0aYSBUb2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJl
c3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubwogbW9yZSByZXN1bHRzIGluIHRoZSBs
aXN0LgoKDQoFBAICAQUSBMsBAggKDQoFBAICAQESBMsBCRgKDQoFBAICAQMSBMsBGxwKmwEK
AgQDEgbQAQDeAQEajAEgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZXNzaW9uRW50aXR5
VHlwZXMuR2V0U2Vzc2lvbkVudGl0eVR5cGVdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzLlNlc3Npb25FbnRpdHlUeXBlcy5HZXRTZXNzaW9uRW50aXR5VHlwZV0uCgoLCgMEAwES
BNABCCMKmwMKBAQDAgASBtgBAt0BBBqKAyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHNl
c3Npb24gZW50aXR5IHR5cGUuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9j
YXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L3Nlc3Npb25zLzxTZXNzaW9u
SUQ+L2VudGl0eVR5cGVzLzxFbnRpdHlUeXBlSUQ+YAogb3IKIGBwcm9qZWN0cy88UHJvamVj
dElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZW52aXJvbm1l
bnRzLzxFbnZpcm9ubWVudElEPi9zZXNzaW9ucy88U2Vzc2lvbklEPi9lbnRpdHlUeXBlcy88
RW50aXR5VHlwZUlEPmAuCiBJZiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZpZWQs
IHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcKIGVudmlyb25tZW50LgoKDQoFBAMCAAUSBNgB
AggKDQoFBAMCAAESBNgBCQ0KDQoFBAMCAAMSBNgBEBEKDwoFBAMCAAgSBtgBEt0BAwoQCggE
AwIACJwIABIE2QEEKgoRCgcEAwIACJ8IEgbaAQTcAQUKoQEKAgQEEgbiAQD0AQEakgEgVGhl
IHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTZXNzaW9uRW50aXR5VHlwZXMuQ3JlYXRlU2Vzc2lv
bkVudGl0eVR5cGVdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlNlc3Npb25FbnRp
dHlUeXBlcy5DcmVhdGVTZXNzaW9uRW50aXR5VHlwZV0uCgoLCgMEBAESBOIBCCYK8QIKBAQE
AgASBuoBAu8BBBrgAiBSZXF1aXJlZC4gVGhlIHNlc3Npb24gdG8gY3JlYXRlIGEgc2Vzc2lv
biBlbnRpdHkgdHlwZSBmb3IuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9j
YXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L3Nlc3Npb25zLzxTZXNzaW9u
SUQ+YAogb3IKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+
L2FnZW50cy88QWdlbnRJRD4vZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudElEPi9zZXNzaW9u
cy88U2Vzc2lvbklEPmAuCiBJZiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZpZWQs
IHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcKIGVudmlyb25tZW50LgoKDQoFBAQCAAUSBOoB
AggKDQoFBAQCAAESBOoBCQ8KDQoFBAQCAAMSBOoBEhMKDwoFBAQCAAgSBuoBFO8BAwoQCggE
BAIACJwIABIE6wEEKgoRCgcEBAIACJ8IEgbsAQTuAQUKPgoEBAQCARIG8gEC8wEvGi4gUmVx
dWlyZWQuIFRoZSBzZXNzaW9uIGVudGl0eSB0eXBlIHRvIGNyZWF0ZS4KCg0KBQQEAgEGEgTy
AQITCg0KBQQEAgEBEgTyARQnCg0KBQQEAgEDEgTyASorCg0KBQQEAgEIEgTzAQYuChAKCAQE
AgEInAgAEgTzAQctCqEBCgIEBRIG+AEAhQIBGpIBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbU2Vzc2lvbkVudGl0eVR5cGVzLlVwZGF0ZVNlc3Npb25FbnRpdHlUeXBlXVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52My5TZXNzaW9uRW50aXR5VHlwZXMuVXBkYXRlU2Vzc2lv
bkVudGl0eVR5cGVdLgoKCwoDBAUBEgT4AQgmCpkDCgQEBQIAEgaAAgKBAi8aiAMgUmVxdWly
ZWQuIFRoZSBzZXNzaW9uIGVudGl0eSB0eXBlIHRvIHVwZGF0ZS4KIEZvcm1hdDoKIGBwcm9q
ZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJ
RD4vc2Vzc2lvbnMvPFNlc3Npb25JRD4vZW50aXR5VHlwZXMvPEVudGl0eVR5cGVJRD5gCiBv
cgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRz
LzxBZ2VudElEPi9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50SUQ+L3Nlc3Npb25zLzxTZXNz
aW9uSUQ+L2VudGl0eVR5cGVzLzxFbnRpdHlUeXBlSUQ+YC4KIElmIGBFbnZpcm9ubWVudCBJ
RGAgaXMgbm90IHNwZWNpZmllZCwKIHdlIGFzc3VtZSBkZWZhdWx0ICdkcmFmdCcgZW52aXJv
bm1lbnQuCgoNCgUEBQIABhIEgAICEwoNCgUEBQIAARIEgAIUJwoNCgUEBQIAAxIEgAIqKwoN
CgUEBQIACBIEgQIGLgoQCggEBQIACJwIABIEgQIHLQo9CgQEBQIBEgSEAgIsGi8gVGhlIG1h
c2sgdG8gY29udHJvbCB3aGljaCBmaWVsZHMgZ2V0IHVwZGF0ZWQuCgoNCgUEBQIBBhIEhAIC
GwoNCgUEBQIBARIEhAIcJwoNCgUEBQIBAxIEhAIqKwqhAQoCBAYSBokCAJcCARqSASBUaGUg
cmVxdWVzdCBtZXNzYWdlIGZvcgogW1Nlc3Npb25FbnRpdHlUeXBlcy5EZWxldGVTZXNzaW9u
RW50aXR5VHlwZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuU2Vzc2lvbkVudGl0
eVR5cGVzLkRlbGV0ZVNlc3Npb25FbnRpdHlUeXBlXS4KCgsKAwQGARIEiQIIJgqlAwoEBAYC
ABIGkQIClgIEGpQDIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc2Vzc2lvbiBlbnRpdHkg
dHlwZSB0byBkZWxldGUuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRp
b25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L3Nlc3Npb25zLzxTZXNzaW9uSUQ+
L2VudGl0eVR5cGVzLzxFbnRpdHlUeXBlSUQ+YAogb3IKIGBwcm9qZWN0cy88UHJvamVjdElE
Pi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZW52aXJvbm1lbnRz
LzxFbnZpcm9ubWVudElEPi9zZXNzaW9ucy88U2Vzc2lvbklEPi9lbnRpdHlUeXBlcy88RW50
aXR5VHlwZUlEPmAuCiBJZiBgRW52aXJvbm1lbnQgSURgIGlzIG5vdCBzcGVjaWZpZWQsCiB3
ZSBhc3N1bWUgZGVmYXVsdCAnZHJhZnQnIGVudmlyb25tZW50LgoKDQoFBAYCAAUSBJECAggK
DQoFBAYCAAESBJECCQ0KDQoFBAYCAAMSBJECEBEKDwoFBAYCAAgSBpECEpYCAwoQCggEBgIA
CJwIABIEkgIEKgoRCgcEBgIACJ8IEgaTAgSVAgViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType ===
    # Fields for SessionEntityType
    # Field: name Type: 9 ()
    # Field: entity_override_mode Type: 14 (.google.cloud.dialogflow.cx.v3.SessionEntityType.EntityOverrideMode)
    # Field: entities Type: 11 (.google.cloud.dialogflow.cx.v3.EntityType.Entity)

# Enum: SessionEntityType::EntityOverrideMode
our $SessionEntityType_ENTITY_OVERRIDE_MODE_UNSPECIFIED = 0;
our $SessionEntityType_ENTITY_OVERRIDE_MODE_OVERRIDE = 1;
our $SessionEntityType_ENTITY_OVERRIDE_MODE_SUPPLEMENT = 2;

# === Message: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesRequest ===
    # Fields for ListSessionEntityTypesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesResponse ===
    # Fields for ListSessionEntityTypesResponse
    # Field: session_entity_types Type: 11 (.google.cloud.dialogflow.cx.v3.SessionEntityType)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::GetSessionEntityTypeRequest ===
    # Fields for GetSessionEntityTypeRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::CreateSessionEntityTypeRequest ===
    # Fields for CreateSessionEntityTypeRequest
    # Field: parent Type: 9 ()
    # Field: session_entity_type Type: 11 (.google.cloud.dialogflow.cx.v3.SessionEntityType)

# === Message: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::UpdateSessionEntityTypeRequest ===
    # Fields for UpdateSessionEntityTypeRequest
    # Field: session_entity_type Type: 11 (.google.cloud.dialogflow.cx.v3.SessionEntityType)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::DeleteSessionEntityTypeRequest ===
    # Fields for DeleteSessionEntityTypeRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityTypesClient ===
package Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityTypesClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityTypesClient

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
        ? Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SessionEntityTypes',
        method         => 'ListSessionEntityTypes',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesResponse',
    });
}

sub get_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::GetSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SessionEntityTypes',
        method         => 'GetSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType',
    });
}

sub create_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::CreateSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SessionEntityTypes',
        method         => 'CreateSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType',
    });
}

sub update_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::UpdateSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SessionEntityTypes',
        method         => 'UpdateSessionEntityType',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType',
    });
}

sub delete_session_entity_type {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::DeleteSessionEntityTypeRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.SessionEntityTypes',
        method         => 'DeleteSessionEntityType',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::SessionEntityType - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/session_entity_type.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::SessionEntityType;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType->new({
        name => $name,
        entity_override_mode => $entity_override_mode,
        entities => $entities,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/session_entity_type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType

Session entity types are referred to as B<User> entity types and are
entities that are built for an individual user such as favorites,
preferences, playlists, and so on.

You can redefine a session entity type at the session level to extend or
replace a [custom entity type][google.cloud.dialogflow.cx.v3.EntityType] at
the user session level (we refer to the entity types defined at the agent
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

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::EntityOverrideMode>)

Required. Indicates whether the additional data should override or
supplement the custom entity type definition.

=item * C<< $msg->entities() >> / C<< $msg->entities($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType::Entity>)

Required. The collection of entities to override or supplement the custom
entity type.

=back

=head3 Enum: SessionEntityType::EntityOverrideMode

=over 4

=item * C<ENTITY_OVERRIDE_MODE_UNSPECIFIED> => C<0>

=item * C<ENTITY_OVERRIDE_MODE_OVERRIDE> => C<1>

=item * C<ENTITY_OVERRIDE_MODE_SUPPLEMENT> => C<2>

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesRequest

The request message for
[SessionEntityTypes.ListSessionEntityTypes][google.cloud.dialogflow.cx.v3.SessionEntityTypes.ListSessionEntityTypes].

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

=head2 Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::ListSessionEntityTypesResponse

The response message for
[SessionEntityTypes.ListSessionEntityTypes][google.cloud.dialogflow.cx.v3.SessionEntityTypes.ListSessionEntityTypes].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_entity_types() >> / C<< $msg->session_entity_types($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType>)

The list of session entity types. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::GetSessionEntityTypeRequest

The request message for
[SessionEntityTypes.GetSessionEntityType][google.cloud.dialogflow.cx.v3.SessionEntityTypes.GetSessionEntityType].

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

=head2 Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::CreateSessionEntityTypeRequest

The request message for
[SessionEntityTypes.CreateSessionEntityType][google.cloud.dialogflow.cx.v3.SessionEntityTypes.CreateSessionEntityType].

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

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType>)

Required. The session entity type to create.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::UpdateSessionEntityTypeRequest

The request message for
[SessionEntityTypes.UpdateSessionEntityType][google.cloud.dialogflow.cx.v3.SessionEntityTypes.UpdateSessionEntityType].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_entity_type() >> / C<< $msg->session_entity_type($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::SessionEntityType>)

Required. The session entity type to update.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`
or
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/sessions/<SessionID>/entityTypes/<EntityTypeID>`.
If `Environment ID` is not specified,
we assume default 'draft' environment.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::DeleteSessionEntityTypeRequest

The request message for
[SessionEntityTypes.DeleteSessionEntityType][google.cloud.dialogflow.cx.v3.SessionEntityTypes.DeleteSessionEntityType].

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
If `Environment ID` is not specified,
we assume default 'draft' environment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::SessionEntityType::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
