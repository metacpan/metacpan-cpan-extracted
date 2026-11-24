package Google::Cloud::Oslogin::V1beta::Oslogin;

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
    eval { require Google::Cloud::Oslogin::Common::Common };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvb3Nsb2dpbi92MWJldGEvb3Nsb2dpbi5wcm90bxIbZ29vZ2xlLmNs
b3VkLm9zbG9naW4udjFiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL29zbG9naW4vY29tbW9u
L2NvbW1vbi5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJv
dG9idWYvZmllbGRfbWFzay5wcm90byKbAwoMTG9naW5Qcm9maWxlEhcKBG5hbWUYASABKAlC
A+BBAlIEbmFtZRJQCg5wb3NpeF9hY2NvdW50cxgCIAMoCzIpLmdvb2dsZS5jbG91ZC5vc2xv
Z2luLmNvbW1vbi5Qb3NpeEFjY291bnRSDXBvc2l4QWNjb3VudHMSZAoPc3NoX3B1YmxpY19r
ZXlzGAMgAygLMjwuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFiZXRhLkxvZ2luUHJvZmlsZS5T
c2hQdWJsaWNLZXlzRW50cnlSDXNzaFB1YmxpY0tleXMSTQoNc2VjdXJpdHlfa2V5cxgFIAMo
CzIoLmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxYmV0YS5TZWN1cml0eUtleVIMc2VjdXJpdHlL
ZXlzGmsKElNzaFB1YmxpY0tleXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI/CgV2YWx1ZRgC
IAEoCzIpLmdvb2dsZS5jbG91ZC5vc2xvZ2luLmNvbW1vbi5Tc2hQdWJsaWNLZXlSBXZhbHVl
OgI4ASK2AQoZQ3JlYXRlU3NoUHVibGljS2V5UmVxdWVzdBJDCgZwYXJlbnQYASABKAlCK+BB
AvpBJRIjb3Nsb2dpbi5nb29nbGVhcGlzLmNvbS9Tc2hQdWJsaWNLZXlSBnBhcmVudBJUCg5z
c2hfcHVibGljX2tleRgCIAEoCzIpLmdvb2dsZS5jbG91ZC5vc2xvZ2luLmNvbW1vbi5Tc2hQ
dWJsaWNLZXlCA+BBAlIMc3NoUHVibGljS2V5IlwKGURlbGV0ZVBvc2l4QWNjb3VudFJlcXVl
c3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNvc2xvZ2luLmdvb2dsZWFwaXMuY29tL1Bvc2l4
QWNjb3VudFIEbmFtZSJcChlEZWxldGVTc2hQdWJsaWNLZXlSZXF1ZXN0Ej8KBG5hbWUYASAB
KAlCK+BBAvpBJQojb3Nsb2dpbi5nb29nbGVhcGlzLmNvbS9Tc2hQdWJsaWNLZXlSBG5hbWUi
0AEKFkdldExvZ2luUHJvZmlsZVJlcXVlc3QSNwoEbmFtZRgBIAEoCUIj4EEC+kEdChtvc2xv
Z2luLmdvb2dsZWFwaXMuY29tL1VzZXJSBG5hbWUSHQoKcHJvamVjdF9pZBgCIAEoCVIJcHJv
amVjdElkEhsKCXN5c3RlbV9pZBgDIAEoCVIIc3lzdGVtSWQSQQoEdmlldxgEIAEoDjItLmdv
b2dsZS5jbG91ZC5vc2xvZ2luLnYxYmV0YS5Mb2dpblByb2ZpbGVWaWV3UgR2aWV3IlkKFkdl
dFNzaFB1YmxpY0tleVJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNvc2xvZ2luLmdv
b2dsZWFwaXMuY29tL1NzaFB1YmxpY0tleVIEbmFtZSK0AgoZSW1wb3J0U3NoUHVibGljS2V5
UmVxdWVzdBJACgZwYXJlbnQYASABKAlCKPpBJRIjb3Nsb2dpbi5nb29nbGVhcGlzLmNvbS9T
c2hQdWJsaWNLZXlSBnBhcmVudBJUCg5zc2hfcHVibGljX2tleRgCIAEoCzIpLmdvb2dsZS5j
bG91ZC5vc2xvZ2luLmNvbW1vbi5Tc2hQdWJsaWNLZXlCA+BBAlIMc3NoUHVibGljS2V5Eh0K
CnByb2plY3RfaWQYAyABKAlSCXByb2plY3RJZBJBCgR2aWV3GAQgASgOMi0uZ29vZ2xlLmNs
b3VkLm9zbG9naW4udjFiZXRhLkxvZ2luUHJvZmlsZVZpZXdSBHZpZXcSHQoHcmVnaW9ucxgF
IAMoCUID4EEBUgdyZWdpb25zIoYBChpJbXBvcnRTc2hQdWJsaWNLZXlSZXNwb25zZRJOCg1s
b2dpbl9wcm9maWxlGAEgASgLMikuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFiZXRhLkxvZ2lu
UHJvZmlsZVIMbG9naW5Qcm9maWxlEhgKB2RldGFpbHMYAiABKAlSB2RldGFpbHMi7wEKGVVw
ZGF0ZVNzaFB1YmxpY0tleVJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNvc2xvZ2lu
Lmdvb2dsZWFwaXMuY29tL1NzaFB1YmxpY0tleVIEbmFtZRJUCg5zc2hfcHVibGljX2tleRgC
IAEoCzIpLmdvb2dsZS5jbG91ZC5vc2xvZ2luLmNvbW1vbi5Tc2hQdWJsaWNLZXlCA+BBAlIM
c3NoUHVibGljS2V5EjsKC3VwZGF0ZV9tYXNrGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZp
ZWxkTWFza1IKdXBkYXRlTWFzayLLAgoLU2VjdXJpdHlLZXkSHQoKcHVibGljX2tleRgBIAEo
CVIJcHVibGljS2V5Eh8KC3ByaXZhdGVfa2V5GAIgASgJUgpwcml2YXRlS2V5EmMKFHVuaXZl
cnNhbF90d29fZmFjdG9yGAMgASgLMi8uZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFiZXRhLlVu
aXZlcnNhbFR3b0ZhY3RvckgAUhJ1bml2ZXJzYWxUd29GYWN0b3ISRAoJd2ViX2F1dGhuGAQg
ASgLMiUuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFiZXRhLldlYkF1dGhuSABSCHdlYkF1dGhu
EiwKD2RldmljZV9uaWNrbmFtZRgFIAEoCUgBUg5kZXZpY2VOaWNrbmFtZYgBAUIPCg1wcm90
b2NvbF90eXBlQhIKEF9kZXZpY2Vfbmlja25hbWUiKwoSVW5pdmVyc2FsVHdvRmFjdG9yEhUK
BmFwcF9pZBgBIAEoCVIFYXBwSWQiHwoIV2ViQXV0aG4SEwoFcnBfaWQYASABKAlSBHJwSWQi
VwoXU2lnblNzaFB1YmxpY0tleVJlcXVlc3QSJAoOc3NoX3B1YmxpY19rZXkYASABKAlSDHNz
aFB1YmxpY0tleRIWCgZwYXJlbnQYAiABKAlSBnBhcmVudCJNChhTaWduU3NoUHVibGljS2V5
UmVzcG9uc2USMQoVc2lnbmVkX3NzaF9wdWJsaWNfa2V5GAEgASgJUhJzaWduZWRTc2hQdWJs
aWNLZXkqUwoQTG9naW5Qcm9maWxlVmlldxIiCh5MT0dJTl9QUk9GSUxFX1ZJRVdfVU5TUEVD
SUZJRUQQABIJCgVCQVNJQxABEhAKDFNFQ1VSSVRZX0tFWRACMvIOCg5Pc0xvZ2luU2Vydmlj
ZRLPAQoSQ3JlYXRlU3NoUHVibGljS2V5EjYuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFiZXRh
LkNyZWF0ZVNzaFB1YmxpY0tleVJlcXVlc3QaKS5nb29nbGUuY2xvdWQub3Nsb2dpbi5jb21t
b24uU3NoUHVibGljS2V5IlaC0+STAjgiJi92MWJldGEve3BhcmVudD11c2Vycy8qfS9zc2hQ
dWJsaWNLZXlzOg5zc2hfcHVibGljX2tledpBFXBhcmVudCxzc2hfcHVibGljX2tleRKWAQoS
RGVsZXRlUG9zaXhBY2NvdW50EjYuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFiZXRhLkRlbGV0
ZVBvc2l4QWNjb3VudFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiMILT5JMCIyoh
L3YxYmV0YS97bmFtZT11c2Vycy8qL3Byb2plY3RzLyp92kEEbmFtZRKbAQoSRGVsZXRlU3No
UHVibGljS2V5EjYuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFiZXRhLkRlbGV0ZVNzaFB1Ymxp
Y0tleVJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiNYLT5JMCKComL3YxYmV0YS97
bmFtZT11c2Vycy8qL3NzaFB1YmxpY0tleXMvKn3aQQRuYW1lEqUBCg9HZXRMb2dpblByb2Zp
bGUSMy5nb29nbGUuY2xvdWQub3Nsb2dpbi52MWJldGEuR2V0TG9naW5Qcm9maWxlUmVxdWVz
dBopLmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxYmV0YS5Mb2dpblByb2ZpbGUiMoLT5JMCJRIj
L3YxYmV0YS97bmFtZT11c2Vycy8qfS9sb2dpblByb2ZpbGXaQQRuYW1lEqgBCg9HZXRTc2hQ
dWJsaWNLZXkSMy5nb29nbGUuY2xvdWQub3Nsb2dpbi52MWJldGEuR2V0U3NoUHVibGljS2V5
UmVxdWVzdBopLmdvb2dsZS5jbG91ZC5vc2xvZ2luLmNvbW1vbi5Tc2hQdWJsaWNLZXkiNYLT
5JMCKBImL3YxYmV0YS97bmFtZT11c2Vycy8qL3NzaFB1YmxpY0tleXMvKn3aQQRuYW1lEoUC
ChJJbXBvcnRTc2hQdWJsaWNLZXkSNi5nb29nbGUuY2xvdWQub3Nsb2dpbi52MWJldGEuSW1w
b3J0U3NoUHVibGljS2V5UmVxdWVzdBo3Lmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxYmV0YS5J
bXBvcnRTc2hQdWJsaWNLZXlSZXNwb25zZSJ+gtPkkwI9IisvdjFiZXRhL3twYXJlbnQ9dXNl
cnMvKn06aW1wb3J0U3NoUHVibGljS2V5Og5zc2hfcHVibGljX2tledpBFXBhcmVudCxzc2hf
cHVibGljX2tledpBIHBhcmVudCxzc2hfcHVibGljX2tleSxwcm9qZWN0X2lkEu8BChJVcGRh
dGVTc2hQdWJsaWNLZXkSNi5nb29nbGUuY2xvdWQub3Nsb2dpbi52MWJldGEuVXBkYXRlU3No
UHVibGljS2V5UmVxdWVzdBopLmdvb2dsZS5jbG91ZC5vc2xvZ2luLmNvbW1vbi5Tc2hQdWJs
aWNLZXkidoLT5JMCODImL3YxYmV0YS97bmFtZT11c2Vycy8qL3NzaFB1YmxpY0tleXMvKn06
DnNzaF9wdWJsaWNfa2V52kETbmFtZSxzc2hfcHVibGljX2tledpBH25hbWUsc3NoX3B1Ymxp
Y19rZXksdXBkYXRlX21hc2sSqQIKEFNpZ25Tc2hQdWJsaWNLZXkSNC5nb29nbGUuY2xvdWQu
b3Nsb2dpbi52MWJldGEuU2lnblNzaFB1YmxpY0tleVJlcXVlc3QaNS5nb29nbGUuY2xvdWQu
b3Nsb2dpbi52MWJldGEuU2lnblNzaFB1YmxpY0tleVJlc3BvbnNlIqcBgtPkkwKIASI8L3Yx
YmV0YS97cGFyZW50PXVzZXJzLyovcHJvamVjdHMvKi96b25lcy8qfTpzaWduU3NoUHVibGlj
S2V5OgEqWkUiQC92MWJldGEve3BhcmVudD11c2Vycy8qL3Byb2plY3RzLyovbG9jYXRpb25z
Lyp9OnNpZ25Tc2hQdWJsaWNLZXk6ASraQRVwYXJlbnQsc3NoX3B1YmxpY19rZXka3QHKQRZv
c2xvZ2luLmdvb2dsZWFwaXMuY29t0kHAAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybS5yZWFkLW9ubHksaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
b21wdXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY29tcHV0ZS5yZWFkb25s
eULJAQofY29tLmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxYmV0YUIMT3NMb2dpblByb3RvUAFa
OWNsb3VkLmdvb2dsZS5jb20vZ28vb3Nsb2dpbi9hcGl2MWJldGEvb3Nsb2dpbnBiO29zbG9n
aW5wYqoCG0dvb2dsZS5DbG91ZC5Pc0xvZ2luLlYxQmV0YcoCG0dvb2dsZVxDbG91ZFxPc0xv
Z2luXFYxYmV0YeoCHkdvb2dsZTo6Q2xvdWQ6Ok9zTG9naW46OlYxYmV0YUrHSQoHEgUOAMkC
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADIKCQoCAwUS
AxcAJQoJCgIDBhIDGAAqCggKAQgSAxoAOAoJCgIIJRIDGgA4CggKAQgSAxsAUAoJCgIICxID
GwBQCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ALQoJCgIICBIDHQAtCggKAQgSAx4A
OAoJCgIIARIDHgA4CggKAQgSAx8AOAoJCgIIKRIDHwA4CggKAQgSAyAANwoJCgIILRIDIAA3
CrgBCgIGABIFJgCCAQEaqgEgQ2xvdWQgT1MgTG9naW4gQVBJCgogVGhlIENsb3VkIE9TIExv
Z2luIEFQSSBhbGxvd3MgeW91IHRvIG1hbmFnZSB1c2VycyBhbmQgdGhlaXIgYXNzb2NpYXRl
ZCBTU0gKIHB1YmxpYyBrZXlzIGZvciBsb2dnaW5nIGludG8gdmlydHVhbCBtYWNoaW5lcyBv
biBHb29nbGUgQ2xvdWQgUGxhdGZvcm0uCgoKCgMGAAESAyYIFgoKCgMGAAMSAycCPgoMCgUG
AAOZCBIDJwI+CgsKAwYAAxIEKAIsOQoNCgUGAAOaCBIEKAIsOQooCgQGAAIAEgQvAjYDGhog
Q3JlYXRlIGFuIFNTSCBwdWJsaWMga2V5CgoMCgUGAAIAARIDLwYYCgwKBQYAAgACEgMvGTIK
DAoFBgACAAMSAzAPNwoNCgUGAAIABBIEMQQ0BgoRCgkGAAIABLDKvCISBDEENAYKDAoFBgAC
AAQSAzUEQwoPCggGAAIABJsIABIDNQRDCigKBAYAAgESBDkCPwMaGiBEZWxldGVzIGEgUE9T
SVggYWNjb3VudC4KCgwKBQYAAgEBEgM5BhgKDAoFBgACAQISAzkZMgoMCgUGAAIBAxIDOg8k
Cg0KBQYAAgEEEgQ7BD0GChEKCQYAAgEEsMq8IhIEOwQ9BgoMCgUGAAIBBBIDPgQyCg8KCAYA
AgEEmwgAEgM+BDIKKgoEBgACAhIEQgJIAxocIERlbGV0ZXMgYW4gU1NIIHB1YmxpYyBrZXku
CgoMCgUGAAICARIDQgYYCgwKBQYAAgICEgNCGTIKDAoFBgACAgMSA0MPJAoNCgUGAAICBBIE
RARGBgoRCgkGAAICBLDKvCISBEQERgYKDAoFBgACAgQSA0cEMgoPCggGAAICBJsIABIDRwQy
CnUKBAYAAgMSBEwCUQMaZyBSZXRyaWV2ZXMgdGhlIHByb2ZpbGUgaW5mb3JtYXRpb24gdXNl
ZCBmb3IgbG9nZ2luZyBpbiB0byBhIHZpcnR1YWwgbWFjaGluZQogb24gR29vZ2xlIENvbXB1
dGUgRW5naW5lLgoKDAoFBgACAwESA0wGFQoMCgUGAAIDAhIDTBYsCgwKBQYAAgMDEgNMN0MK
DQoFBgACAwQSBE0ETwYKEQoJBgACAwSwyrwiEgRNBE8GCgwKBQYAAgMEEgNQBDIKDwoIBgAC
AwSbCAASA1AEMgosCgQGAAIEEgRUAloDGh4gUmV0cmlldmVzIGFuIFNTSCBwdWJsaWMga2V5
LgoKDAoFBgACBAESA1QGFQoMCgUGAAIEAhIDVBYsCgwKBQYAAgQDEgNVDzcKDQoFBgACBAQS
BFYEWAYKEQoJBgACBASwyrwiEgRWBFgGCgwKBQYAAgQEEgNZBDIKDwoIBgACBASbCAASA1kE
Mgq0AQoEBgACBRIEXwJnAxqlASBBZGRzIGFuIFNTSCBwdWJsaWMga2V5IGFuZCByZXR1cm5z
IHRoZSBwcm9maWxlIGluZm9ybWF0aW9uLiBEZWZhdWx0IFBPU0lYCiBhY2NvdW50IGluZm9y
bWF0aW9uIGlzIHNldCB3aGVuIG5vIHVzZXJuYW1lIGFuZCBVSUQgZXhpc3QgYXMgcGFydCBv
ZiB0aGUKIGxvZ2luIHByb2ZpbGUuCgoMCgUGAAIFARIDXwYYCgwKBQYAAgUCEgNfGTIKDAoF
BgACBQMSA2APKQoNCgUGAAIFBBIEYQRkBgoRCgkGAAIFBLDKvCISBGEEZAYKDAoFBgACBQQS
A2UEQwoPCggGAAIFBJsIABIDZQRDCgwKBQYAAgUEEgNmBE4KDwoIBgACBQSbCAESA2YETgp1
CgQGAAIGEgRrAnMDGmcgVXBkYXRlcyBhbiBTU0ggcHVibGljIGtleSBhbmQgcmV0dXJucyB0
aGUgcHJvZmlsZSBpbmZvcm1hdGlvbi4gVGhpcyBtZXRob2QKIHN1cHBvcnRzIHBhdGNoIHNl
bWFudGljcy4KCgwKBQYAAgYBEgNrBhgKDAoFBgACBgISA2sZMgoMCgUGAAIGAxIDbA83Cg0K
BQYAAgYEEgRtBHAGChEKCQYAAgYEsMq8IhIEbQRwBgoMCgUGAAIGBBIDcQRBCg8KCAYAAgYE
mwgAEgNxBEEKDAoFBgACBgQSA3IETQoPCggGAAIGBJsIARIDcgRNClMKBAYAAgcSBXYCgQED
GkQgU2lnbnMgYW4gU1NIIHB1YmxpYyBrZXkgZm9yIGEgdXNlciB0byBhdXRoZW50aWNhdGUg
dG8gYW4gaW5zdGFuY2UuCgoMCgUGAAIHARIDdgYWCgwKBQYAAgcCEgN2Fy4KDAoFBgACBwMS
A3cPJwoNCgUGAAIHBBIEeAR/BgoRCgkGAAIHBLDKvCISBHgEfwYKDQoFBgACBwQSBIABBEMK
EAoIBgACBwSbCAASBIABBEMKcAoCBAASBoYBAJIBARpiIFRoZSB1c2VyIHByb2ZpbGUgaW5m
b3JtYXRpb24gdXNlZCBmb3IgbG9nZ2luZyBpbiB0byBhIHZpcnR1YWwgbWFjaGluZSBvbgog
R29vZ2xlIENvbXB1dGUgRW5naW5lLgoKCwoDBAABEgSGAQgUCisKBAQAAgASBIgBAjsaHSBS
ZXF1aXJlZC4gQSB1bmlxdWUgdXNlciBJRC4KCg0KBQQAAgAFEgSIAQIICg0KBQQAAgABEgSI
AQkNCg0KBQQAAgADEgSIARARCg0KBQQAAgAIEgSIARI6ChAKCAQAAgAInAgAEgSIARM5CkQK
BAQAAgESBIsBAkcaNiBUaGUgbGlzdCBvZiBQT1NJWCBhY2NvdW50cyBhc3NvY2lhdGVkIHdp
dGggdGhlIHVzZXIuCgoNCgUEAAIBBBIEiwECCgoNCgUEAAIBBhIEiwELMwoNCgUEAAIBARIE
iwE0QgoNCgUEAAIBAxIEiwFFRgpTCgQEAAICEgSOAQJMGkUgQSBtYXAgZnJvbSBTU0ggcHVi
bGljIGtleSBmaW5nZXJwcmludCB0byB0aGUgYXNzb2NpYXRlZCBrZXkgb2JqZWN0LgoKDQoF
BAACAgYSBI4BAjcKDQoFBAACAgESBI4BOEcKDQoFBAACAgMSBI4BSksKQwoEBAACAxIEkQEC
KRo1IFRoZSByZWdpc3RlcmVkIHNlY3VyaXR5IGtleSBjcmVkZW50aWFscyBmb3IgYSB1c2Vy
LgoKDQoFBAACAwQSBJEBAgoKDQoFBAACAwYSBJEBCxYKDQoFBAACAwESBJEBFyQKDQoFBAAC
AwMSBJEBJygKQQoCBAESBpUBAKEBARozIEEgcmVxdWVzdCBtZXNzYWdlIGZvciBjcmVhdGlu
ZyBhbiBTU0ggcHVibGljIGtleS4KCgsKAwQBARIElQEIIQpQCgQEAQIAEgaXAQKcAQQaQCBS
ZXF1aXJlZC4gVGhlIHVuaXF1ZSBJRCBmb3IgdGhlIHVzZXIgaW4gZm9ybWF0IGB1c2Vycy97
dXNlcn1gLgoKDQoFBAECAAUSBJcBAggKDQoFBAECAAESBJcBCQ8KDQoFBAECAAMSBJcBEhMK
DwoFBAECAAgSBpcBFJwBAwoQCggEAQIACJwIABIEmAEEKgoRCgcEAQIACJ8IEgaZAQSbAQUK
QwoEBAECARIGnwECoAEvGjMgUmVxdWlyZWQuIFRoZSBTU0ggcHVibGljIGtleSBhbmQgZXhw
aXJhdGlvbiB0aW1lLgoKDQoFBAECAQYSBJ8BAioKDQoFBAECAQESBJ8BKzkKDQoFBAECAQMS
BJ8BPD0KDQoFBAECAQgSBKABBi4KEAoIBAECAQicCAASBKABBy0KRQoCBAISBqQBAK4BARo3
IEEgcmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhIFBPU0lYIGFjY291bnQgZW50cnku
CgoLCgMEAgESBKQBCCEK5QEKBAQCAgASBqgBAq0BBBrUASBSZXF1aXJlZC4gQSByZWZlcmVu
Y2UgdG8gdGhlIFBPU0lYIGFjY291bnQgdG8gdXBkYXRlLiBQT1NJWCBhY2NvdW50cyBhcmUK
IGlkZW50aWZpZWQgYnkgdGhlIHByb2plY3QgSUQgdGhleSBhcmUgYXNzb2NpYXRlZCB3aXRo
LiBBIHJlZmVyZW5jZSB0byB0aGUKIFBPU0lYIGFjY291bnQgaXMgaW4gZm9ybWF0IGB1c2Vy
cy97dXNlcn0vcHJvamVjdHMve3Byb2plY3R9YC4KCg0KBQQCAgAFEgSoAQIICg0KBQQCAgAB
EgSoAQkNCg0KBQQCAgADEgSoARARCg8KBQQCAgAIEgaoARKtAQMKEAoIBAICAAicCAASBKkB
BCoKEQoHBAICAAifCBIGqgEErAEFCkEKAgQDEgaxAQC7AQEaMyBBIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IgZGVsZXRpbmcgYW4gU1NIIHB1YmxpYyBrZXkuCgoLCgMEAwESBLEBCCEK3wEKBAQD
AgASBrUBAroBBBrOASBSZXF1aXJlZC4gVGhlIGZpbmdlcnByaW50IG9mIHRoZSBwdWJsaWMg
a2V5IHRvIHVwZGF0ZS4gUHVibGljIGtleXMgYXJlCiBpZGVudGlmaWVkIGJ5IHRoZWlyIFNI
QS0yNTYgZmluZ2VycHJpbnQuIFRoZSBmaW5nZXJwcmludCBvZiB0aGUgcHVibGljIGtleQog
aXMgaW4gZm9ybWF0IGB1c2Vycy97dXNlcn0vc3NoUHVibGljS2V5cy97ZmluZ2VycHJpbnR9
YC4KCg0KBQQDAgAFEgS1AQIICg0KBQQDAgABEgS1AQkNCg0KBQQDAgADEgS1ARARCg8KBQQD
AgAIEga1ARK6AQMKEAoIBAMCAAicCAASBLYBBCoKEQoHBAMCAAifCBIGtwEEuQEFCloKAgQE
Ega+AQDNAQEaTCBBIHJlcXVlc3QgbWVzc2FnZSBmb3IgcmV0cmlldmluZyB0aGUgbG9naW4g
cHJvZmlsZSBpbmZvcm1hdGlvbiBmb3IgYSB1c2VyLgoKCwoDBAQBEgS+AQgeClAKBAQEAgAS
BsABAsMBBBpAIFJlcXVpcmVkLiBUaGUgdW5pcXVlIElEIGZvciB0aGUgdXNlciBpbiBmb3Jt
YXQgYHVzZXJzL3t1c2VyfWAuCgoNCgUEBAIABRIEwAECCAoNCgUEBAIAARIEwAEJDQoNCgUE
BAIAAxIEwAEQEQoPCgUEBAIACBIGwAESwwEDChAKCAQEAgAInAgAEgTBAQQqCg8KBwQEAgAI
nwgSBMIBBE0KRAoEBAQCARIExgECGBo2IFRoZSBwcm9qZWN0IElEIG9mIHRoZSBHb29nbGUg
Q2xvdWQgUGxhdGZvcm0gcHJvamVjdC4KCg0KBQQEAgEFEgTGAQIICg0KBQQEAgEBEgTGAQkT
Cg0KBQQEAgEDEgTGARYXCkUKBAQEAgISBMkBAhcaNyBBIHN5c3RlbSBJRCBmb3IgZmlsdGVy
aW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LgoKDQoFBAQCAgUSBMkBAggKDQoFBAQC
AgESBMkBCRIKDQoFBAQCAgMSBMkBFRYKUgoEBAQCAxIEzAECHBpEIFRoZSB2aWV3IGNvbmZp
Z3VyZXMgd2hldGhlciB0byByZXRyaWV2ZSBzZWN1cml0eSBrZXlzIGluZm9ybWF0aW9uLgoK
DQoFBAQCAwYSBMwBAhIKDQoFBAQCAwESBMwBExcKDQoFBAQCAwMSBMwBGhsKQwoCBAUSBtAB
ANoBARo1IEEgcmVxdWVzdCBtZXNzYWdlIGZvciByZXRyaWV2aW5nIGFuIFNTSCBwdWJsaWMg
a2V5LgoKCwoDBAUBEgTQAQgeCuEBCgQEBQIAEgbUAQLZAQQa0AEgUmVxdWlyZWQuIFRoZSBm
aW5nZXJwcmludCBvZiB0aGUgcHVibGljIGtleSB0byByZXRyaWV2ZS4gUHVibGljIGtleXMg
YXJlCiBpZGVudGlmaWVkIGJ5IHRoZWlyIFNIQS0yNTYgZmluZ2VycHJpbnQuIFRoZSBmaW5n
ZXJwcmludCBvZiB0aGUgcHVibGljIGtleQogaXMgaW4gZm9ybWF0IGB1c2Vycy97dXNlcn0v
c3NoUHVibGljS2V5cy97ZmluZ2VycHJpbnR9YC4KCg0KBQQFAgAFEgTUAQIICg0KBQQFAgAB
EgTUAQkNCg0KBQQFAgADEgTUARARCg8KBQQFAgAIEgbUARLZAQMKEAoIBAUCAAicCAASBNUB
BCoKEQoHBAUCAAifCBIG1gEE2AEFCkIKAgQGEgbdAQDxAQEaNCBBIHJlcXVlc3QgbWVzc2Fn
ZSBmb3IgaW1wb3J0aW5nIGFuIFNTSCBwdWJsaWMga2V5LgoKCwoDBAYBEgTdAQghCkYKBAQG
AgASBt8BAuEBBRo2IFRoZSB1bmlxdWUgSUQgZm9yIHRoZSB1c2VyIGluIGZvcm1hdCBgdXNl
cnMve3VzZXJ9YC4KCg0KBQQGAgAFEgTfAQIICg0KBQQGAgABEgTfAQkPCg0KBQQGAgADEgTf
ARITCg8KBQQGAgAIEgbfARThAQQKEQoHBAYCAAifCBIG3wEV4QEDCkMKBAQGAgESBuQBAuUB
LxozIFJlcXVpcmVkLiBUaGUgU1NIIHB1YmxpYyBrZXkgYW5kIGV4cGlyYXRpb24gdGltZS4K
Cg0KBQQGAgEGEgTkAQIqCg0KBQQGAgEBEgTkASs5Cg0KBQQGAgEDEgTkATw9Cg0KBQQGAgEI
EgTlAQYuChAKCAQGAgEInAgAEgTlAQctCkQKBAQGAgISBOgBAhgaNiBUaGUgcHJvamVjdCBJ
RCBvZiB0aGUgR29vZ2xlIENsb3VkIFBsYXRmb3JtIHByb2plY3QuCgoNCgUEBgICBRIE6AEC
CAoNCgUEBgICARIE6AEJEwoNCgUEBgICAxIE6AEWFwpSCgQEBgIDEgTrAQIcGkQgVGhlIHZp
ZXcgY29uZmlndXJlcyB3aGV0aGVyIHRvIHJldHJpZXZlIHNlY3VyaXR5IGtleXMgaW5mb3Jt
YXRpb24uCgoNCgUEBgIDBhIE6wECEgoNCgUEBgIDARIE6wETFwoNCgUEBgIDAxIE6wEaGwrF
AQoEBAYCBBIE8AECRxq2ASBPcHRpb25hbC4gVGhlIHJlZ2lvbnMgdG8gd2hpY2ggdG8gYXNz
ZXJ0IHRoYXQgdGhlIGtleSB3YXMgd3JpdHRlbi4KIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0
cyB0byBhbGwgcmVnaW9ucy4KIFJlZ2lvbnMgYXJlIGxpc3RlZCBhdCBodHRwczovL2Nsb3Vk
Lmdvb2dsZS5jb20vYWJvdXQvbG9jYXRpb25zI3JlZ2lvbi4KCg0KBQQGAgQEEgTwAQIKCg0K
BQQGAgQFEgTwAQsRCg0KBQQGAgQBEgTwARIZCg0KBQQGAgQDEgTwARwdCg0KBQQGAgQIEgTw
AR5GChAKCAQGAgQInAgAEgTwAR9FCkMKAgQHEgb0AQD6AQEaNSBBIHJlc3BvbnNlIG1lc3Nh
Z2UgZm9yIGltcG9ydGluZyBhbiBTU0ggcHVibGljIGtleS4KCgsKAwQHARIE9AEIIgo7CgQE
BwIAEgT2AQIhGi0gVGhlIGxvZ2luIHByb2ZpbGUgaW5mb3JtYXRpb24gZm9yIHRoZSB1c2Vy
LgoKDQoFBAcCAAYSBPYBAg4KDQoFBAcCAAESBPYBDxwKDQoFBAcCAAMSBPYBHyAKOgoEBAcC
ARIE+QECFRosIERldGFpbGVkIGluZm9ybWF0aW9uIGFib3V0IGltcG9ydCByZXN1bHRzLgoK
DQoFBAcCAQUSBPkBAggKDQoFBAcCAQESBPkBCRAKDQoFBAcCAQMSBPkBExQKQQoCBAgSBv0B
AI4CARozIEEgcmVxdWVzdCBtZXNzYWdlIGZvciB1cGRhdGluZyBhbiBTU0ggcHVibGljIGtl
eS4KCgsKAwQIARIE/QEIIQrfAQoEBAgCABIGgQIChgIEGs4BIFJlcXVpcmVkLiBUaGUgZmlu
Z2VycHJpbnQgb2YgdGhlIHB1YmxpYyBrZXkgdG8gdXBkYXRlLiBQdWJsaWMga2V5cyBhcmUK
IGlkZW50aWZpZWQgYnkgdGhlaXIgU0hBLTI1NiBmaW5nZXJwcmludC4gVGhlIGZpbmdlcnBy
aW50IG9mIHRoZSBwdWJsaWMga2V5CiBpcyBpbiBmb3JtYXQgYHVzZXJzL3t1c2VyfS9zc2hQ
dWJsaWNLZXlzL3tmaW5nZXJwcmludH1gLgoKDQoFBAgCAAUSBIECAggKDQoFBAgCAAESBIEC
CQ0KDQoFBAgCAAMSBIECEBEKDwoFBAgCAAgSBoECEoYCAwoQCggECAIACJwIABIEggIEKgoR
CgcECAIACJ8IEgaDAgSFAgUKQwoEBAgCARIGiQICigIvGjMgUmVxdWlyZWQuIFRoZSBTU0gg
cHVibGljIGtleSBhbmQgZXhwaXJhdGlvbiB0aW1lLgoKDQoFBAgCAQYSBIkCAioKDQoFBAgC
AQESBIkCKzkKDQoFBAgCAQMSBIkCPD0KDQoFBAgCAQgSBIoCBi4KEAoIBAgCAQicCAASBIoC
By0KVQoEBAgCAhIEjQICLBpHIE1hc2sgdG8gY29udHJvbCB3aGljaCBmaWVsZHMgZ2V0IHVw
ZGF0ZWQuIFVwZGF0ZXMgYWxsIGlmIG5vdCBwcmVzZW50LgoKDQoFBAgCAgYSBI0CAhsKDQoF
BAgCAgESBI0CHCcKDQoFBAgCAgMSBI0CKisKUAoCBAkSBpECAKQCARpCIFRoZSBjcmVkZW50
aWFsIGluZm9ybWF0aW9uIGZvciBhIEdvb2dsZSByZWdpc3RlcmVkIHNlY3VyaXR5IGtleS4K
CgsKAwQJARIEkQIIEwp5CgQECQIAEgSUAgIYGmsgUHVibGljIGtleSB0ZXh0IGluIFNTSCBm
b3JtYXQsIGRlZmluZWQgYnkKIFtSRkM0MjUzXSgiaHR0cHM6Ly93d3cuaWV0Zi5vcmcvcmZj
L3JmYzQyNTMudHh0Iikgc2VjdGlvbiA2LjYuCgoNCgUECQIABRIElAICCAoNCgUECQIAARIE
lAIJEwoNCgUECQIAAxIElAIWFwo/CgQECQIBEgSXAgIZGjEgSGFyZHdhcmUtYmFja2VkIHBy
aXZhdGUga2V5IHRleHQgaW4gU1NIIGZvcm1hdC4KCg0KBQQJAgEFEgSXAgIICg0KBQQJAgEB
EgSXAgkUCg0KBQQJAgEDEgSXAhcYCkoKBAQJCAASBpoCAqACAxo6IFRoZSBGSURPIHByb3Rv
Y29sIHR5cGUgdXNlZCB0byByZWdpc3RlciB0aGlzIGNyZWRlbnRpYWwuCgoNCgUECQgAARIE
mgIIFQomCgQECQICEgScAgQwGhggVGhlIFUyRiBwcm90b2NvbCB0eXBlLgoKDQoFBAkCAgYS
BJwCBBYKDQoFBAkCAgESBJwCFysKDQoFBAkCAgMSBJwCLi8KNQoEBAkCAxIEnwIEGxonIFRo
ZSBXZWIgQXV0aGVudGljYXRpb24gcHJvdG9jb2wgdHlwZS4KCg0KBQQJAgMGEgSfAgQMCg0K
BQQJAgMBEgSfAg0WCg0KBQQJAgMDEgSfAhkaCkUKBAQJAgQSBKMCAiYaNyBUaGUgc2VjdXJp
dHkga2V5IG5pY2tuYW1lIGV4cGxpY2l0bHkgc2V0IGJ5IHRoZSB1c2VyLgoKDQoFBAkCBAQS
BKMCAgoKDQoFBAkCBAUSBKMCCxEKDQoFBAkCBAESBKMCEiEKDQoFBAkCBAMSBKMCJCUKRgoC
BAoSBqcCAKoCARo4IFNlY3VyaXR5IGtleSBpbmZvcm1hdGlvbiBzcGVjaWZpYyB0byB0aGUg
VTJGIHByb3RvY29sLgoKCwoDBAoBEgSnAggaCjQKBAQKAgASBKkCAhQaJiBBcHBsaWNhdGlv
biBJRCBmb3IgdGhlIFUyRiBwcm90b2NvbC4KCg0KBQQKAgAFEgSpAgIICg0KBQQKAgABEgSp
AgkPCg0KBQQKAgADEgSpAhITClUKAgQLEgatAgCwAgEaRyBTZWN1cml0eSBrZXkgaW5mb3Jt
YXRpb24gc3BlY2lmaWMgdG8gdGhlIFdlYiBBdXRoZW50aWNhdGlvbiBwcm90b2NvbC4KCgsK
AwQLARIErQIIEAo4CgQECwIAEgSvAgITGiogUmVseWluZyBwYXJ0eSBJRCBmb3IgV2ViIEF1
dGhlbnRpY2F0aW9uLgoKDQoFBAsCAAUSBK8CAggKDQoFBAsCAAESBK8CCQ4KDQoFBAsCAAMS
BK8CERIKDAoCBAwSBrICALgCAQoLCgMEDAESBLICCB8KKwoEBAwCABIEtAICHBodIFRoZSBT
U0ggcHVibGljIGtleSB0byBzaWduLgoKDQoFBAwCAAUSBLQCAggKDQoFBAwCAAESBLQCCRcK
DQoFBAwCAAMSBLQCGhsKRgoEBAwCARIEtwICFBo4IFRoZSBwYXJlbnQgcHJvamVjdCBhbmQg
cmVnaW9uIGZvciB0aGUgc2lnbmluZyByZXF1ZXN0LgoKDQoFBAwCAQUSBLcCAggKDQoFBAwC
AQESBLcCCQ8KDQoFBAwCAQMSBLcCEhMKDAoCBA0SBroCAL0CAQoLCgMEDQESBLoCCCAKRgoE
BA0CABIEvAICIxo4IFRoZSBzaWduZWQgU1NIIHB1YmxpYyBrZXkgdG8gdXNlIGluIHRoZSBT
U0ggaGFuZHNoYWtlLgoKDQoFBA0CAAUSBLwCAggKDQoFBA0CAAESBLwCCR4KDQoFBA0CAAMS
BLwCISIKSQoCBQASBsACAMkCARo7IFRoZSBsb2dpbiBwcm9maWxlIHZpZXcgbGltaXRzIHRo
ZSB1c2VyIGNvbnRlbnQgcmV0cmlldmVkLgoKCwoDBQABEgTAAgUVClMKBAUAAgASBMICAiUa
RSBUaGUgZGVmYXVsdCBsb2dpbiBwcm9maWxlIHZpZXcuIFRoZSBBUEkgZGVmYXVsdHMgdG8g
dGhlIEJBU0lDIHZpZXcuCgoNCgUFAAIAARIEwgICIAoNCgUFAAIAAhIEwgIjJAo3CgQFAAIB
EgTFAgIMGikgSW5jbHVkZXMgUE9TSVggYW5kIFNTSCBrZXkgaW5mb3JtYXRpb24uCgoNCgUF
AAIBARIExQICBwoNCgUFAAIBAhIExQIKCwo+CgQFAAICEgTIAgITGjAgSW5jbHVkZSBzZWN1
cml0eSBrZXkgaW5mb3JtYXRpb24gZm9yIHRoZSB1c2VyLgoKDQoFBQACAgESBMgCAg4KDQoF
BQACAgISBMgCERJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile ===
    # Fields for LoginProfile
    # Field: name Type: 9 ()
    # Field: posix_accounts Type: 11 (.google.cloud.oslogin.common.PosixAccount)
    # Field: ssh_public_keys Type: 11 (.google.cloud.oslogin.v1beta.LoginProfile.SshPublicKeysEntry)
    # Field: security_keys Type: 11 (.google.cloud.oslogin.v1beta.SecurityKey)

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::CreateSshPublicKeyRequest ===
    # Fields for CreateSshPublicKeyRequest
    # Field: parent Type: 9 ()
    # Field: ssh_public_key Type: 11 (.google.cloud.oslogin.common.SshPublicKey)

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::DeletePosixAccountRequest ===
    # Fields for DeletePosixAccountRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::DeleteSshPublicKeyRequest ===
    # Fields for DeleteSshPublicKeyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::GetLoginProfileRequest ===
    # Fields for GetLoginProfileRequest
    # Field: name Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: system_id Type: 9 ()
    # Field: view Type: 14 (.google.cloud.oslogin.v1beta.LoginProfileView)

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::GetSshPublicKeyRequest ===
    # Fields for GetSshPublicKeyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyRequest ===
    # Fields for ImportSshPublicKeyRequest
    # Field: parent Type: 9 ()
    # Field: ssh_public_key Type: 11 (.google.cloud.oslogin.common.SshPublicKey)
    # Field: project_id Type: 9 ()
    # Field: view Type: 14 (.google.cloud.oslogin.v1beta.LoginProfileView)
    # Field: regions Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyResponse ===
    # Fields for ImportSshPublicKeyResponse
    # Field: login_profile Type: 11 (.google.cloud.oslogin.v1beta.LoginProfile)
    # Field: details Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::UpdateSshPublicKeyRequest ===
    # Fields for UpdateSshPublicKeyRequest
    # Field: name Type: 9 ()
    # Field: ssh_public_key Type: 11 (.google.cloud.oslogin.common.SshPublicKey)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::SecurityKey ===
    # Fields for SecurityKey
    # Field: public_key Type: 9 ()
    # Field: private_key Type: 9 ()
    # Field: universal_two_factor Type: 11 (.google.cloud.oslogin.v1beta.UniversalTwoFactor)
    # Field: web_authn Type: 11 (.google.cloud.oslogin.v1beta.WebAuthn)
    # Field: device_nickname Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::UniversalTwoFactor ===
    # Fields for UniversalTwoFactor
    # Field: app_id Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::WebAuthn ===
    # Fields for WebAuthn
    # Field: rp_id Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyRequest ===
    # Fields for SignSshPublicKeyRequest
    # Field: ssh_public_key Type: 9 ()
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyResponse ===
    # Fields for SignSshPublicKeyResponse
    # Field: signed_ssh_public_key Type: 9 ()

# === Service Client: Google::Cloud::Oslogin::V1beta::Oslogin::OsLoginServiceClient ===
package Google::Cloud::Oslogin::V1beta::Oslogin::OsLoginServiceClient;

=pod

=head2 Service Client: Google::Cloud::Oslogin::V1beta::Oslogin::OsLoginServiceClient

Client stub representing the remote C<OsLoginService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<oslogin.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'oslogin.googleapis.com:443' );

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

sub create_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1beta::Oslogin::CreateSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1beta.OsLoginService',
        method         => 'CreateSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::Common::Common::SshPublicKey',
    });
}

sub delete_posix_account {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1beta::Oslogin::DeletePosixAccountRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1beta.OsLoginService',
        method         => 'DeletePosixAccount',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub delete_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1beta::Oslogin::DeleteSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1beta.OsLoginService',
        method         => 'DeleteSshPublicKey',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_login_profile {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1beta::Oslogin::GetLoginProfileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1beta.OsLoginService',
        method         => 'GetLoginProfile',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile',
    });
}

sub get_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1beta::Oslogin::GetSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1beta.OsLoginService',
        method         => 'GetSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::Common::Common::SshPublicKey',
    });
}

sub import_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1beta.OsLoginService',
        method         => 'ImportSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyResponse',
    });
}

sub update_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1beta::Oslogin::UpdateSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1beta.OsLoginService',
        method         => 'UpdateSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::Common::Common::SshPublicKey',
    });
}

sub sign_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1beta.OsLoginService',
        method         => 'SignSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oslogin::V1beta::Oslogin - Compiled Protocol Buffers messages for google/cloud/oslogin/v1beta/oslogin.proto

=head1 SYNOPSIS

    use Google::Cloud::Oslogin::V1beta::Oslogin;

    my $msg = Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile->new({
        name => $name,
        posix_accounts => $posix_accounts,
        ssh_public_keys => $ssh_public_keys,
        security_keys => $security_keys,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oslogin/v1beta/oslogin.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile

The user profile information used for logging in to a virtual machine on
Google Compute Engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A unique user ID.

=item * C<< $msg->posix_accounts() >> / C<< $msg->posix_accounts($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::Common::Common::PosixAccount>)

The list of POSIX accounts associated with the user.

=item * C<< $msg->ssh_public_keys() >> / C<< $msg->ssh_public_keys($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile::SshPublicKeysEntry>)

A map from SSH public key fingerprint to the associated key object.

=item * C<< $msg->security_keys() >> / C<< $msg->security_keys($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::V1beta::Oslogin::SecurityKey>)

The registered security key credentials for a user.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::CreateSshPublicKeyRequest

A request message for creating an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The unique ID for the user in format `users/{user}`.

=item * C<< $msg->ssh_public_key() >> / C<< $msg->ssh_public_key($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::Common::Common::SshPublicKey>)

Required. The SSH public key and expiration time.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::DeletePosixAccountRequest

A request message for deleting a POSIX account entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A reference to the POSIX account to update. POSIX accounts are
identified by the project ID they are associated with. A reference to the
POSIX account is in format `users/{user}/projects/{project}`.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::DeleteSshPublicKeyRequest

A request message for deleting an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The fingerprint of the public key to update. Public keys are
identified by their SHA-256 fingerprint. The fingerprint of the public key
is in format `users/{user}/sshPublicKeys/{fingerprint}`.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::GetLoginProfileRequest

A request message for retrieving the login profile information for a user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique ID for the user in format `users/{user}`.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The project ID of the Google Cloud Platform project.

=item * C<< $msg->system_id() >> / C<< $msg->system_id($value) >>

Type: C<String>

A system ID for filtering the results of the request.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Oslogin::V1beta::LoginProfileView>)

The view configures whether to retrieve security keys information.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::GetSshPublicKeyRequest

A request message for retrieving an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The fingerprint of the public key to retrieve. Public keys are
identified by their SHA-256 fingerprint. The fingerprint of the public key
is in format `users/{user}/sshPublicKeys/{fingerprint}`.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyRequest

A request message for importing an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The unique ID for the user in format `users/{user}`.

=item * C<< $msg->ssh_public_key() >> / C<< $msg->ssh_public_key($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::Common::Common::SshPublicKey>)

Required. The SSH public key and expiration time.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The project ID of the Google Cloud Platform project.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Oslogin::V1beta::LoginProfileView>)

The view configures whether to retrieve security keys information.

=item * C<< $msg->regions() >> / C<< $msg->regions($value) >>

Type: C<String>

Optional. The regions to which to assert that the key was written.
If unspecified, defaults to all regions.
Regions are listed at https://cloud.google.com/about/locations#region.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyResponse

A response message for importing an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->login_profile() >> / C<< $msg->login_profile($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile>)

The login profile information for the user.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<String>

Detailed information about import results.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::UpdateSshPublicKeyRequest

A request message for updating an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The fingerprint of the public key to update. Public keys are
identified by their SHA-256 fingerprint. The fingerprint of the public key
is in format `users/{user}/sshPublicKeys/{fingerprint}`.

=item * C<< $msg->ssh_public_key() >> / C<< $msg->ssh_public_key($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::Common::Common::SshPublicKey>)

Required. The SSH public key and expiration time.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Mask to control which fields get updated. Updates all if not present.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::SecurityKey

The credential information for a Google registered security key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->public_key() >> / C<< $msg->public_key($value) >>

Type: C<String>

Public key text in SSH format, defined by
[RFC4253]("https://www.ietf.org/rfc/rfc4253.txt") section 6.6.

=item * C<< $msg->private_key() >> / C<< $msg->private_key($value) >>

Type: C<String>

Hardware-backed private key text in SSH format.

=item * C<< $msg->universal_two_factor() >> / C<< $msg->universal_two_factor($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::V1beta::Oslogin::UniversalTwoFactor>)

The U2F protocol type.

=item * C<< $msg->web_authn() >> / C<< $msg->web_authn($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::V1beta::Oslogin::WebAuthn>)

The Web Authentication protocol type.

=item * C<< $msg->device_nickname() >> / C<< $msg->device_nickname($value) >>

Type: C<String>

The security key nickname explicitly set by the user.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::UniversalTwoFactor

Security key information specific to the U2F protocol.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->app_id() >> / C<< $msg->app_id($value) >>

Type: C<String>

Application ID for the U2F protocol.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::WebAuthn

Security key information specific to the Web Authentication protocol.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rp_id() >> / C<< $msg->rp_id($value) >>

Type: C<String>

Relying party ID for Web Authentication.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ssh_public_key() >> / C<< $msg->ssh_public_key($value) >>

Type: C<String>

The SSH public key to sign.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The parent project and region for the signing request.

=back

=head2 Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->signed_ssh_public_key() >> / C<< $msg->signed_ssh_public_key($value) >>

Type: C<String>

The signed SSH public key to use in the SSH handshake.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oslogin::V1beta::Oslogin::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
