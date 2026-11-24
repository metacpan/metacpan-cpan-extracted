package Google::Cloud::Oslogin::V1alpha::Oslogin;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Cloud::Oslogin::Common::Common };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvb3Nsb2dpbi92MWFscGhhL29zbG9naW4ucHJvdG8SHGdvb2dsZS5j
bG91ZC5vc2xvZ2luLnYxYWxwaGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aKGdv
b2dsZS9jbG91ZC9vc2xvZ2luL2NvbW1vbi9jb21tb24ucHJvdG8aG2dvb2dsZS9wcm90b2J1
Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8i5gIKDExv
Z2luUHJvZmlsZRISCgRuYW1lGAEgASgJUgRuYW1lElAKDnBvc2l4X2FjY291bnRzGAIgAygL
MikuZ29vZ2xlLmNsb3VkLm9zbG9naW4uY29tbW9uLlBvc2l4QWNjb3VudFINcG9zaXhBY2Nv
dW50cxJlCg9zc2hfcHVibGljX2tleXMYAyADKAsyPS5nb29nbGUuY2xvdWQub3Nsb2dpbi52
MWFscGhhLkxvZ2luUHJvZmlsZS5Tc2hQdWJsaWNLZXlzRW50cnlSDXNzaFB1YmxpY0tleXMS
HAoJc3VzcGVuZGVkGAQgASgIUglzdXNwZW5kZWQaawoSU3NoUHVibGljS2V5c0VudHJ5EhAK
A2tleRgBIAEoCVIDa2V5Ej8KBXZhbHVlGAIgASgLMikuZ29vZ2xlLmNsb3VkLm9zbG9naW4u
Y29tbW9uLlNzaFB1YmxpY0tleVIFdmFsdWU6AjgBIi8KGURlbGV0ZVBvc2l4QWNjb3VudFJl
cXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZSIvChlEZWxldGVTc2hQdWJsaWNLZXlSZXF1ZXN0
EhIKBG5hbWUYASABKAlSBG5hbWUiLAoWR2V0TG9naW5Qcm9maWxlUmVxdWVzdBISCgRuYW1l
GAEgASgJUgRuYW1lIiwKFkdldFNzaFB1YmxpY0tleVJlcXVlc3QSEgoEbmFtZRgBIAEoCVIE
bmFtZSKjAQoZSW1wb3J0U3NoUHVibGljS2V5UmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBh
cmVudBJPCg5zc2hfcHVibGljX2tleRgCIAEoCzIpLmdvb2dsZS5jbG91ZC5vc2xvZ2luLmNv
bW1vbi5Tc2hQdWJsaWNLZXlSDHNzaFB1YmxpY0tleRIdCgpwcm9qZWN0X2lkGAMgASgJUglw
cm9qZWN0SWQibQoaSW1wb3J0U3NoUHVibGljS2V5UmVzcG9uc2USTwoNbG9naW5fcHJvZmls
ZRgBIAEoCzIqLmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxYWxwaGEuTG9naW5Qcm9maWxlUgxs
b2dpblByb2ZpbGUivQEKGVVwZGF0ZVNzaFB1YmxpY0tleVJlcXVlc3QSEgoEbmFtZRgBIAEo
CVIEbmFtZRJPCg5zc2hfcHVibGljX2tleRgCIAEoCzIpLmdvb2dsZS5jbG91ZC5vc2xvZ2lu
LmNvbW1vbi5Tc2hQdWJsaWNLZXlSDHNzaFB1YmxpY0tleRI7Cgt1cGRhdGVfbWFzaxgDIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sykwgKDk9zTG9naW5T
ZXJ2aWNlEpEBChJEZWxldGVQb3NpeEFjY291bnQSNy5nb29nbGUuY2xvdWQub3Nsb2dpbi52
MWFscGhhLkRlbGV0ZVBvc2l4QWNjb3VudFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1w
dHkiKoLT5JMCJCoiL3YxYWxwaGEve25hbWU9dXNlcnMvKi9wcm9qZWN0cy8qfRKWAQoSRGVs
ZXRlU3NoUHVibGljS2V5EjcuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFhbHBoYS5EZWxldGVT
c2hQdWJsaWNLZXlSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5Ii+C0+STAikqJy92
MWFscGhhL3tuYW1lPXVzZXJzLyovc3NoUHVibGljS2V5cy8qfRKhAQoPR2V0TG9naW5Qcm9m
aWxlEjQuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFhbHBoYS5HZXRMb2dpblByb2ZpbGVSZXF1
ZXN0GiouZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFhbHBoYS5Mb2dpblByb2ZpbGUiLILT5JMC
JhIkL3YxYWxwaGEve25hbWU9dXNlcnMvKn0vbG9naW5Qcm9maWxlEqMBCg9HZXRTc2hQdWJs
aWNLZXkSNC5nb29nbGUuY2xvdWQub3Nsb2dpbi52MWFscGhhLkdldFNzaFB1YmxpY0tleVJl
cXVlc3QaKS5nb29nbGUuY2xvdWQub3Nsb2dpbi5jb21tb24uU3NoUHVibGljS2V5Ii+C0+ST
AikSJy92MWFscGhhL3tuYW1lPXVzZXJzLyovc3NoUHVibGljS2V5cy8qfRLNAQoSSW1wb3J0
U3NoUHVibGljS2V5EjcuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFhbHBoYS5JbXBvcnRTc2hQ
dWJsaWNLZXlSZXF1ZXN0GjguZ29vZ2xlLmNsb3VkLm9zbG9naW4udjFhbHBoYS5JbXBvcnRT
c2hQdWJsaWNLZXlSZXNwb25zZSJEgtPkkwI+IiwvdjFhbHBoYS97cGFyZW50PXVzZXJzLyp9
OmltcG9ydFNzaFB1YmxpY0tleToOc3NoX3B1YmxpY19rZXkSuQEKElVwZGF0ZVNzaFB1Ymxp
Y0tleRI3Lmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxYWxwaGEuVXBkYXRlU3NoUHVibGljS2V5
UmVxdWVzdBopLmdvb2dsZS5jbG91ZC5vc2xvZ2luLmNvbW1vbi5Tc2hQdWJsaWNLZXkiP4LT
5JMCOTInL3YxYWxwaGEve25hbWU9dXNlcnMvKi9zc2hQdWJsaWNLZXlzLyp9Og5zc2hfcHVi
bGljX2tleUKsAQogY29tLmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxYWxwaGFCDE9zTG9naW5Q
cm90b1ABWjpjbG91ZC5nb29nbGUuY29tL2dvL29zbG9naW4vYXBpdjFhbHBoYS9vc2xvZ2lu
cGI7b3Nsb2dpbnBiqgIcR29vZ2xlLkNsb3VkLk9zTG9naW4uVjFBbHBoYcoCHEdvb2dsZVxD
bG91ZFxPc0xvZ2luXFYxYWxwaGFK3yYKBxIFDgClAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIAJgoJCgIDARIDEwAyCgkKAgMCEgMU
ACUKCQoCAwMSAxUAKgoICgEIEgMXADkKCQoCCCUSAxcAOQoICgEIEgMYAFEKCQoCCAsSAxgA
UQoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAC0KCQoCCAgSAxoALQoICgEIEgMbADkK
CQoCCAESAxsAOQoICgEIEgMcADkKCQoCCCkSAxwAOQq3AQoCBgASBCIAVwEaqgEgQ2xvdWQg
T1MgTG9naW4gQVBJCgogVGhlIENsb3VkIE9TIExvZ2luIEFQSSBhbGxvd3MgeW91IHRvIG1h
bmFnZSB1c2VycyBhbmQgdGhlaXIgYXNzb2NpYXRlZCBTU0gKIHB1YmxpYyBrZXlzIGZvciBs
b2dnaW5nIGludG8gdmlydHVhbCBtYWNoaW5lcyBvbiBHb29nbGUgQ2xvdWQgUGxhdGZvcm0u
CgoKCgMGAAESAyIIFgooCgQGAAIAEgQkAikDGhogRGVsZXRlcyBhIFBPU0lYIGFjY291bnQu
CgoMCgUGAAIAARIDJAYYCgwKBQYAAgACEgMkGTIKDAoFBgACAAMSAyUPJAoNCgUGAAIABBIE
JgQoBgoRCgkGAAIABLDKvCISBCYEKAYKKgoEBgACARIELAIxAxocIERlbGV0ZXMgYW4gU1NI
IHB1YmxpYyBrZXkuCgoMCgUGAAIBARIDLAYYCgwKBQYAAgECEgMsGTIKDAoFBgACAQMSAy0P
JAoNCgUGAAIBBBIELgQwBgoRCgkGAAIBBLDKvCISBC4EMAYKdQoEBgACAhIENQI5AxpnIFJl
dHJpZXZlcyB0aGUgcHJvZmlsZSBpbmZvcm1hdGlvbiB1c2VkIGZvciBsb2dnaW5nIGluIHRv
IGEgdmlydHVhbCBtYWNoaW5lCiBvbiBHb29nbGUgQ29tcHV0ZSBFbmdpbmUuCgoMCgUGAAIC
ARIDNQYVCgwKBQYAAgICEgM1FiwKDAoFBgACAgMSAzU3QwoNCgUGAAICBBIENgQ4BgoRCgkG
AAICBLDKvCISBDYEOAYKLAoEBgACAxIEPAJBAxoeIFJldHJpZXZlcyBhbiBTU0ggcHVibGlj
IGtleS4KCgwKBQYAAgMBEgM8BhUKDAoFBgACAwISAzwWLAoMCgUGAAIDAxIDPQ83Cg0KBQYA
AgMEEgQ+BEAGChEKCQYAAgMEsMq8IhIEPgRABgq0AQoEBgACBBIERgJMAxqlASBBZGRzIGFu
IFNTSCBwdWJsaWMga2V5IGFuZCByZXR1cm5zIHRoZSBwcm9maWxlIGluZm9ybWF0aW9uLiBE
ZWZhdWx0IFBPU0lYCiBhY2NvdW50IGluZm9ybWF0aW9uIGlzIHNldCB3aGVuIG5vIHVzZXJu
YW1lIGFuZCBVSUQgZXhpc3QgYXMgcGFydCBvZiB0aGUKIGxvZ2luIHByb2ZpbGUuCgoMCgUG
AAIEARIDRgYYCgwKBQYAAgQCEgNGGTIKDAoFBgACBAMSA0cPKQoNCgUGAAIEBBIESARLBgoR
CgkGAAIEBLDKvCISBEgESwYKdQoEBgACBRIEUAJWAxpnIFVwZGF0ZXMgYW4gU1NIIHB1Ymxp
YyBrZXkgYW5kIHJldHVybnMgdGhlIHByb2ZpbGUgaW5mb3JtYXRpb24uIFRoaXMgbWV0aG9k
CiBzdXBwb3J0cyBwYXRjaCBzZW1hbnRpY3MuCgoMCgUGAAIFARIDUAYYCgwKBQYAAgUCEgNQ
GTIKDAoFBgACBQMSA1EPNwoNCgUGAAIFBBIEUgRVBgoRCgkGAAIFBLDKvCISBFIEVQYKbgoC
BAASBFsAZwEaYiBUaGUgdXNlciBwcm9maWxlIGluZm9ybWF0aW9uIHVzZWQgZm9yIGxvZ2dp
bmcgaW4gdG8gYSB2aXJ0dWFsIG1hY2hpbmUgb24KIEdvb2dsZSBDb21wdXRlIEVuZ2luZS4K
CgoKAwQAARIDWwgUCjkKBAQAAgASA10CEhosIEEgdW5pcXVlIHVzZXIgSUQgZm9yIGlkZW50
aWZ5aW5nIHRoZSB1c2VyLgoKDAoFBAACAAUSA10CCAoMCgUEAAIAARIDXQkNCgwKBQQAAgAD
EgNdEBEKUQoEBAACARIDYAJHGkQgVGhlIGxpc3Qgb2YgUE9TSVggYWNjb3VudHMgYXNzb2Np
YXRlZCB3aXRoIHRoZSBEaXJlY3RvcnkgQVBJIHVzZXIuCgoMCgUEAAIBBBIDYAIKCgwKBQQA
AgEGEgNgCzMKDAoFBAACAQESA2A0QgoMCgUEAAIBAxIDYEVGClIKBAQAAgISA2MCTBpFIEEg
bWFwIGZyb20gU1NIIHB1YmxpYyBrZXkgZmluZ2VycHJpbnQgdG8gdGhlIGFzc29jaWF0ZWQg
a2V5IG9iamVjdC4KCgwKBQQAAgIGEgNjAjcKDAoFBAACAgESA2M4RwoMCgUEAAICAxIDY0pL
CjIKBAQAAgMSA2YCFRolIEluZGljYXRlcyBpZiB0aGUgdXNlciBpcyBzdXNwZW5kZWQuCgoM
CgUEAAIDBRIDZgIGCgwKBQQAAgMBEgNmBxAKDAoFBAACAwMSA2YTFApDCgIEARIEagBvARo3
IEEgcmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhIFBPU0lYIGFjY291bnQgZW50cnku
CgoKCgMEAQESA2oIIQrYAQoEBAECABIDbgISGsoBIEEgcmVmZXJlbmNlIHRvIHRoZSBQT1NJ
WCBhY2NvdW50IHRvIHVwZGF0ZS4gUE9TSVggYWNjb3VudHMgYXJlIGlkZW50aWZpZWQKIGJ5
IHRoZSBwcm9qZWN0IElEIHRoZXkgYXJlIGFzc29jaWF0ZWQgd2l0aC4gQSByZWZlcmVuY2Ug
dG8gdGhlIFBPU0lYCiBhY2NvdW50IGlzIGluIGZvcm1hdCBgdXNlcnMve3VzZXJ9L3Byb2pl
Y3RzL3twcm9qZWN0fWAuCgoMCgUEAQIABRIDbgIICgwKBQQBAgABEgNuCQ0KDAoFBAECAAMS
A24QEQo/CgIEAhIEcgB3ARozIEEgcmVxdWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhbiBT
U0ggcHVibGljIGtleS4KCgoKAwQCARIDcgghCtIBCgQEAgIAEgN2AhIaxAEgVGhlIGZpbmdl
cnByaW50IG9mIHRoZSBwdWJsaWMga2V5IHRvIHVwZGF0ZS4gUHVibGljIGtleXMgYXJlIGlk
ZW50aWZpZWQgYnkKIHRoZWlyIFNIQS0yNTYgZmluZ2VycHJpbnQuIFRoZSBmaW5nZXJwcmlu
dCBvZiB0aGUgcHVibGljIGtleSBpcyBpbiBmb3JtYXQKIGB1c2Vycy97dXNlcn0vc3NoUHVi
bGljS2V5cy97ZmluZ2VycHJpbnR9YC4KCgwKBQQCAgAFEgN2AggKDAoFBAICAAESA3YJDQoM
CgUEAgIAAxIDdhARClgKAgQDEgR6AH0BGkwgQSByZXF1ZXN0IG1lc3NhZ2UgZm9yIHJldHJp
ZXZpbmcgdGhlIGxvZ2luIHByb2ZpbGUgaW5mb3JtYXRpb24gZm9yIGEgdXNlci4KCgoKAwQD
ARIDeggeCkMKBAQDAgASA3wCEho2IFRoZSB1bmlxdWUgSUQgZm9yIHRoZSB1c2VyIGluIGZv
cm1hdCBgdXNlcnMve3VzZXJ9YC4KCgwKBQQDAgAFEgN8AggKDAoFBAMCAAESA3wJDQoMCgUE
AwIAAxIDfBARCkMKAgQEEgaAAQCFAQEaNSBBIHJlcXVlc3QgbWVzc2FnZSBmb3IgcmV0cmll
dmluZyBhbiBTU0ggcHVibGljIGtleS4KCgsKAwQEARIEgAEIHgrVAQoEBAQCABIEhAECEhrG
ASBUaGUgZmluZ2VycHJpbnQgb2YgdGhlIHB1YmxpYyBrZXkgdG8gcmV0cmlldmUuIFB1Ymxp
YyBrZXlzIGFyZSBpZGVudGlmaWVkCiBieSB0aGVpciBTSEEtMjU2IGZpbmdlcnByaW50LiBU
aGUgZmluZ2VycHJpbnQgb2YgdGhlIHB1YmxpYyBrZXkgaXMgaW4KIGZvcm1hdCBgdXNlcnMv
e3VzZXJ9L3NzaFB1YmxpY0tleXMve2ZpbmdlcnByaW50fWAuCgoNCgUEBAIABRIEhAECCAoN
CgUEBAIAARIEhAEJDQoNCgUEBAIAAxIEhAEQEQpCCgIEBRIGiAEAkQEBGjQgQSByZXF1ZXN0
IG1lc3NhZ2UgZm9yIGltcG9ydGluZyBhbiBTU0ggcHVibGljIGtleS4KCgsKAwQFARIEiAEI
IQpECgQEBQIAEgSKAQIUGjYgVGhlIHVuaXF1ZSBJRCBmb3IgdGhlIHVzZXIgaW4gZm9ybWF0
IGB1c2Vycy97dXNlcn1gLgoKDQoFBAUCAAUSBIoBAggKDQoFBAUCAAESBIoBCQ8KDQoFBAUC
AAMSBIoBEhMKNwoEBAUCARIEjQECPhopIFRoZSBTU0ggcHVibGljIGtleSBhbmQgZXhwaXJh
dGlvbiB0aW1lLgoKDQoFBAUCAQYSBI0BAioKDQoFBAUCAQESBI0BKzkKDQoFBAUCAQMSBI0B
PD0KRAoEBAUCAhIEkAECGBo2IFRoZSBwcm9qZWN0IElEIG9mIHRoZSBHb29nbGUgQ2xvdWQg
UGxhdGZvcm0gcHJvamVjdC4KCg0KBQQFAgIFEgSQAQIICg0KBQQFAgIBEgSQAQkTCg0KBQQF
AgIDEgSQARYXCkMKAgQGEgaUAQCXAQEaNSBBIHJlc3BvbnNlIG1lc3NhZ2UgZm9yIGltcG9y
dGluZyBhbiBTU0ggcHVibGljIGtleS4KCgsKAwQGARIElAEIIgo7CgQEBgIAEgSWAQIhGi0g
VGhlIGxvZ2luIHByb2ZpbGUgaW5mb3JtYXRpb24gZm9yIHRoZSB1c2VyLgoKDQoFBAYCAAYS
BJYBAg4KDQoFBAYCAAESBJYBDxwKDQoFBAYCAAMSBJYBHyAKQQoCBAcSBpoBAKUBARozIEEg
cmVxdWVzdCBtZXNzYWdlIGZvciB1cGRhdGluZyBhbiBTU0ggcHVibGljIGtleS4KCgsKAwQH
ARIEmgEIIQrTAQoEBAcCABIEngECEhrEASBUaGUgZmluZ2VycHJpbnQgb2YgdGhlIHB1Ymxp
YyBrZXkgdG8gdXBkYXRlLiBQdWJsaWMga2V5cyBhcmUgaWRlbnRpZmllZCBieQogdGhlaXIg
U0hBLTI1NiBmaW5nZXJwcmludC4gVGhlIGZpbmdlcnByaW50IG9mIHRoZSBwdWJsaWMga2V5
IGlzIGluIGZvcm1hdAogYHVzZXJzL3t1c2VyfS9zc2hQdWJsaWNLZXlzL3tmaW5nZXJwcmlu
dH1gLgoKDQoFBAcCAAUSBJ4BAggKDQoFBAcCAAESBJ4BCQ0KDQoFBAcCAAMSBJ4BEBEKNwoE
BAcCARIEoQECPhopIFRoZSBTU0ggcHVibGljIGtleSBhbmQgZXhwaXJhdGlvbiB0aW1lLgoK
DQoFBAcCAQYSBKEBAioKDQoFBAcCAQESBKEBKzkKDQoFBAcCAQMSBKEBPD0KVQoEBAcCAhIE
pAECLBpHIE1hc2sgdG8gY29udHJvbCB3aGljaCBmaWVsZHMgZ2V0IHVwZGF0ZWQuIFVwZGF0
ZXMgYWxsIGlmIG5vdCBwcmVzZW50LgoKDQoFBAcCAgYSBKQBAhsKDQoFBAcCAgESBKQBHCcK
DQoFBAcCAgMSBKQBKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile ===
    # Fields for LoginProfile
    # Field: name Type: 9 ()
    # Field: posix_accounts Type: 11 (.google.cloud.oslogin.common.PosixAccount)
    # Field: ssh_public_keys Type: 11 (.google.cloud.oslogin.v1alpha.LoginProfile.SshPublicKeysEntry)
    # Field: suspended Type: 8 ()

# === Message: Google::Cloud::Oslogin::V1alpha::Oslogin::DeletePosixAccountRequest ===
    # Fields for DeletePosixAccountRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1alpha::Oslogin::DeleteSshPublicKeyRequest ===
    # Fields for DeleteSshPublicKeyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1alpha::Oslogin::GetLoginProfileRequest ===
    # Fields for GetLoginProfileRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1alpha::Oslogin::GetSshPublicKeyRequest ===
    # Fields for GetSshPublicKeyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyRequest ===
    # Fields for ImportSshPublicKeyRequest
    # Field: parent Type: 9 ()
    # Field: ssh_public_key Type: 11 (.google.cloud.oslogin.common.SshPublicKey)
    # Field: project_id Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyResponse ===
    # Fields for ImportSshPublicKeyResponse
    # Field: login_profile Type: 11 (.google.cloud.oslogin.v1alpha.LoginProfile)

# === Message: Google::Cloud::Oslogin::V1alpha::Oslogin::UpdateSshPublicKeyRequest ===
    # Fields for UpdateSshPublicKeyRequest
    # Field: name Type: 9 ()
    # Field: ssh_public_key Type: 11 (.google.cloud.oslogin.common.SshPublicKey)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Oslogin::V1alpha::Oslogin::OsLoginServiceClient ===
package Google::Cloud::Oslogin::V1alpha::Oslogin::OsLoginServiceClient;

=pod

=head2 Service Client: Google::Cloud::Oslogin::V1alpha::Oslogin::OsLoginServiceClient

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

sub delete_posix_account {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1alpha::Oslogin::DeletePosixAccountRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1alpha.OsLoginService',
        method         => 'DeletePosixAccount',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub delete_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1alpha::Oslogin::DeleteSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1alpha.OsLoginService',
        method         => 'DeleteSshPublicKey',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_login_profile {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1alpha::Oslogin::GetLoginProfileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1alpha.OsLoginService',
        method         => 'GetLoginProfile',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile',
    });
}

sub get_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1alpha::Oslogin::GetSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1alpha.OsLoginService',
        method         => 'GetSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::Common::Common::SshPublicKey',
    });
}

sub import_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1alpha.OsLoginService',
        method         => 'ImportSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyResponse',
    });
}

sub update_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1alpha::Oslogin::UpdateSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1alpha.OsLoginService',
        method         => 'UpdateSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::Common::Common::SshPublicKey',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oslogin::V1alpha::Oslogin - Compiled Protocol Buffers messages for google/cloud/oslogin/v1alpha/oslogin.proto

=head1 SYNOPSIS

    use Google::Cloud::Oslogin::V1alpha::Oslogin;

    my $msg = Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile->new({
        name => $name,
        posix_accounts => $posix_accounts,
        ssh_public_keys => $ssh_public_keys,
        suspended => $suspended,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oslogin/v1alpha/oslogin.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile

The user profile information used for logging in to a virtual machine on
Google Compute Engine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

A unique user ID for identifying the user.

=item * C<< $msg->posix_accounts() >> / C<< $msg->posix_accounts($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::Common::Common::PosixAccount>)

The list of POSIX accounts associated with the Directory API user.

=item * C<< $msg->ssh_public_keys() >> / C<< $msg->ssh_public_keys($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile::SshPublicKeysEntry>)

A map from SSH public key fingerprint to the associated key object.

=item * C<< $msg->suspended() >> / C<< $msg->suspended($value) >>

Type: C<Bool>

Indicates if the user is suspended.

=back

=head2 Google::Cloud::Oslogin::V1alpha::Oslogin::DeletePosixAccountRequest

A request message for deleting a POSIX account entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

A reference to the POSIX account to update. POSIX accounts are identified
by the project ID they are associated with. A reference to the POSIX
account is in format `users/{user}/projects/{project}`.

=back

=head2 Google::Cloud::Oslogin::V1alpha::Oslogin::DeleteSshPublicKeyRequest

A request message for deleting an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fingerprint of the public key to update. Public keys are identified by
their SHA-256 fingerprint. The fingerprint of the public key is in format
`users/{user}/sshPublicKeys/{fingerprint}`.

=back

=head2 Google::Cloud::Oslogin::V1alpha::Oslogin::GetLoginProfileRequest

A request message for retrieving the login profile information for a user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique ID for the user in format `users/{user}`.

=back

=head2 Google::Cloud::Oslogin::V1alpha::Oslogin::GetSshPublicKeyRequest

A request message for retrieving an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fingerprint of the public key to retrieve. Public keys are identified
by their SHA-256 fingerprint. The fingerprint of the public key is in
format `users/{user}/sshPublicKeys/{fingerprint}`.

=back

=head2 Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyRequest

A request message for importing an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The unique ID for the user in format `users/{user}`.

=item * C<< $msg->ssh_public_key() >> / C<< $msg->ssh_public_key($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::Common::Common::SshPublicKey>)

The SSH public key and expiration time.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The project ID of the Google Cloud Platform project.

=back

=head2 Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyResponse

A response message for importing an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->login_profile() >> / C<< $msg->login_profile($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile>)

The login profile information for the user.

=back

=head2 Google::Cloud::Oslogin::V1alpha::Oslogin::UpdateSshPublicKeyRequest

A request message for updating an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fingerprint of the public key to update. Public keys are identified by
their SHA-256 fingerprint. The fingerprint of the public key is in format
`users/{user}/sshPublicKeys/{fingerprint}`.

=item * C<< $msg->ssh_public_key() >> / C<< $msg->ssh_public_key($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::Common::Common::SshPublicKey>)

The SSH public key and expiration time.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Mask to control which fields get updated. Updates all if not present.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oslogin::V1alpha::Oslogin::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
