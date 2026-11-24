package Google::Cloud::Retail::V2beta::Model;

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
    eval { require Google::Cloud::Retail::V2beta::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9tb2RlbC5wcm90bxIaZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MmJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aJ2dvb2dsZS9jbG91ZC9yZXRhaWwvdjJiZXRhL2NvbW1v
bi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLiEAoFTW9kZWwSFwoE
bmFtZRgBIAEoCUID4EECUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNw
bGF5TmFtZRJbCg50cmFpbmluZ19zdGF0ZRgDIAEoDjIvLmdvb2dsZS5jbG91ZC5yZXRhaWwu
djJiZXRhLk1vZGVsLlRyYWluaW5nU3RhdGVCA+BBAVINdHJhaW5pbmdTdGF0ZRJYCg1zZXJ2
aW5nX3N0YXRlGAQgASgOMi4uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuTW9kZWwuU2Vy
dmluZ1N0YXRlQgPgQQNSDHNlcnZpbmdTdGF0ZRJACgtjcmVhdGVfdGltZRgFIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGlt
ZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIX
CgR0eXBlGAcgASgJQgPgQQJSBHR5cGUSOgoWb3B0aW1pemF0aW9uX29iamVjdGl2ZRgIIAEo
CUID4EEBUhVvcHRpbWl6YXRpb25PYmplY3RpdmUSbgoVcGVyaW9kaWNfdHVuaW5nX3N0YXRl
GAsgASgOMjUuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuTW9kZWwuUGVyaW9kaWNUdW5p
bmdTdGF0ZUID4EEBUhNwZXJpb2RpY1R1bmluZ1N0YXRlEkUKDmxhc3RfdHVuZV90aW1lGAwg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgxsYXN0VHVuZVRpbWUSLgoQ
dHVuaW5nX29wZXJhdGlvbhgPIAEoCUID4EEDUg90dW5pbmdPcGVyYXRpb24STwoKZGF0YV9z
dGF0ZRgQIAEoDjIrLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLk1vZGVsLkRhdGFTdGF0
ZUID4EEDUglkYXRhU3RhdGUSagoQZmlsdGVyaW5nX29wdGlvbhgSIAEoDjI6Lmdvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhLlJlY29tbWVuZGF0aW9uc0ZpbHRlcmluZ09wdGlvbkID4EEB
Ug9maWx0ZXJpbmdPcHRpb24SagoUc2VydmluZ19jb25maWdfbGlzdHMYEyADKAsyMy5nb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Nb2RlbC5TZXJ2aW5nQ29uZmlnTGlzdEID4EEDUhJz
ZXJ2aW5nQ29uZmlnTGlzdHMSbgoVbW9kZWxfZmVhdHVyZXNfY29uZmlnGBYgASgLMjUuZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmJldGEuTW9kZWwuTW9kZWxGZWF0dXJlc0NvbmZpZ0ID4EEB
UhNtb2RlbEZlYXR1cmVzQ29uZmlnGkYKEVNlcnZpbmdDb25maWdMaXN0EjEKEnNlcnZpbmdf
Y29uZmlnX2lkcxgBIAMoCUID4EEBUhBzZXJ2aW5nQ29uZmlnSWRzGpgBCiZGcmVxdWVudGx5
Qm91Z2h0VG9nZXRoZXJGZWF0dXJlc0NvbmZpZxJuChVjb250ZXh0X3Byb2R1Y3RzX3R5cGUY
AiABKA4yNS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Nb2RlbC5Db250ZXh0UHJvZHVj
dHNUeXBlQgPgQQFSE2NvbnRleHRQcm9kdWN0c1R5cGUaxgEKE01vZGVsRmVhdHVyZXNDb25m
aWcSlQEKIWZyZXF1ZW50bHlfYm91Z2h0X3RvZ2V0aGVyX2NvbmZpZxgBIAEoCzJILmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJiZXRhLk1vZGVsLkZyZXF1ZW50bHlCb3VnaHRUb2dldGhlckZl
YXR1cmVzQ29uZmlnSABSHmZyZXF1ZW50bHlCb3VnaHRUb2dldGhlckNvbmZpZ0IXChV0eXBl
X2RlZGljYXRlZF9jb25maWciUgoMU2VydmluZ1N0YXRlEh0KGVNFUlZJTkdfU1RBVEVfVU5T
UEVDSUZJRUQQABIMCghJTkFDVElWRRABEgoKBkFDVElWRRACEgkKBVRVTkVEEAMiSQoNVHJh
aW5pbmdTdGF0ZRIeChpUUkFJTklOR19TVEFURV9VTlNQRUNJRklFRBAAEgoKBlBBVVNFRBAB
EgwKCFRSQUlOSU5HEAIikAEKE1BlcmlvZGljVHVuaW5nU3RhdGUSJQohUEVSSU9ESUNfVFVO
SU5HX1NUQVRFX1VOU1BFQ0lGSUVEEAASHAoYUEVSSU9ESUNfVFVOSU5HX0RJU0FCTEVEEAES
FwoTQUxMX1RVTklOR19ESVNBQkxFRBADEhsKF1BFUklPRElDX1RVTklOR19FTkFCTEVEEAIi
RAoJRGF0YVN0YXRlEhoKFkRBVEFfU1RBVEVfVU5TUEVDSUZJRUQQABILCgdEQVRBX09LEAES
DgoKREFUQV9FUlJPUhACIncKE0NvbnRleHRQcm9kdWN0c1R5cGUSJQohQ09OVEVYVF9QUk9E
VUNUU19UWVBFX1VOU1BFQ0lGSUVEEAASGgoWU0lOR0xFX0NPTlRFWFRfUFJPRFVDVBABEh0K
GU1VTFRJUExFX0NPTlRFWFRfUFJPRFVDVFMQAjpr6kFoChtyZXRhaWwuZ29vZ2xlYXBpcy5j
b20vTW9kZWwSSXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jYXRh
bG9ncy97Y2F0YWxvZ30vbW9kZWxzL3ttb2RlbH1CyQEKHmNvbS5nb29nbGUuY2xvdWQucmV0
YWlsLnYyYmV0YUIKTW9kZWxQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL3JldGFpbC9h
cGl2MmJldGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhpHb29nbGUuQ2xvdWQuUmV0
YWlsLlYyQmV0YcoCGkdvb2dsZVxDbG91ZFxSZXRhaWxcVjJiZXRh6gIdR29vZ2xlOjpDbG91
ZDo6UmV0YWlsOjpWMmJldGFKkFIKBxIFDgCUAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADEK
CQoCAwMSAxUAKQoICgEIEgMXADcKCQoCCCUSAxcANwoICgEIEgMYAE0KCQoCCAsSAxgATQoI
CgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaACsKCQoCCAgSAxoAKwoICgEIEgMbADcKCQoC
CAESAxsANwoICgEIEgMcACQKCQoCCCQSAxwAJAoICgEIEgMdADcKCQoCCCkSAx0ANwoICgEI
EgMeADYKCQoCCC0SAx4ANgqoAgoCBAASBSUAlAIBGpoCIE1ldGFkYXRhIHRoYXQgZGVzY3Jp
YmVzIHRoZSB0cmFpbmluZyBhbmQgc2VydmluZyBwYXJhbWV0ZXJzIG9mIGEKIFtNb2RlbF1b
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuTW9kZWxdLiBBCiBbTW9kZWxdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhLk1vZGVsXSBjYW4gYmUgYXNzb2NpYXRlZCB3aXRoIGEKIFtT
ZXJ2aW5nQ29uZmlnXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZXJ2aW5nQ29uZmln
XSBhbmQgdGhlbiBxdWVyaWVkCiB0aHJvdWdoIHRoZSBQcmVkaWN0IEFQSS4KCgoKAwQAARID
JQgNCgsKAwQABxIEJgIpBAoNCgUEAAedCBIEJgIpBAqHAQoEBAADABIELQIyAxp5IFJlcHJl
c2VudHMgYW4gb3JkZXJlZCBjb21iaW5hdGlvbiBvZiB2YWxpZCBzZXJ2aW5nIGNvbmZpZ3Ms
IHdoaWNoCiBjYW4gYmUgdXNlZCBmb3IgYFBBR0VfT1BUSU1JWkFUSU9OYCByZWNvbW1lbmRh
dGlvbnMuCgoMCgUEAAMAARIDLQobCmUKBgQAAwACABIEMAQxMRpVIE9wdGlvbmFsLiBBIHNl
dCBvZiB2YWxpZCBzZXJ2aW5nIGNvbmZpZ3MgdGhhdCBtYXkgYmUgdXNlZCBmb3IKIGBQQUdF
X09QVElNSVpBVElPTmAuCgoOCgcEAAMAAgAEEgMwBAwKDgoHBAADAAIABRIDMA0TCg4KBwQA
AwACAAESAzAUJgoOCgcEAAMAAgADEgMwKSoKDgoHBAADAAIACBIDMQgwChEKCgQAAwACAAic
CAASAzEJLwpRCgQEAAMBEgQ1AjwDGkMgQWRkaXRpb25hbCBjb25maWdzIGZvciB0aGUgZnJl
cXVlbnRseS1ib3VnaHQtdG9nZXRoZXIgbW9kZWwgdHlwZS4KCgwKBQQAAwEBEgM1CjAKtQIK
BgQAAwECABIEOgQ7MRqkAiBPcHRpb25hbC4gU3BlY2lmaWVzIHRoZSBjb250ZXh0IG9mIHRo
ZSBtb2RlbCB3aGVuIGl0IGlzIHVzZWQgaW4gcHJlZGljdAogcmVxdWVzdHMuIENhbiBvbmx5
IGJlIHNldCBmb3IgdGhlIGBmcmVxdWVudGx5LWJvdWdodC10b2dldGhlcmAgdHlwZS4gSWYK
IGl0IGlzbid0IHNwZWNpZmllZCwgaXQgZGVmYXVsdHMgdG8KIFtNVUxUSVBMRV9DT05URVhU
X1BST0RVQ1RTXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Nb2RlbC5Db250ZXh0UHJv
ZHVjdHNUeXBlLk1VTFRJUExFX0NPTlRFWFRfUFJPRFVDVFNdLgoKDgoHBAADAQIABhIDOgQX
Cg4KBwQAAwECAAESAzoYLQoOCgcEAAMBAgADEgM6MDEKDgoHBAADAQIACBIDOwgwChEKCgQA
AwECAAicCAASAzsJLwoxCgQEAAMCEgQ/AkUDGiMgQWRkaXRpb25hbCBtb2RlbCBmZWF0dXJl
cyBjb25maWcuCgoMCgUEAAMCARIDPwodCg4KBgQAAwIIABIEQAREBQoOCgcEAAMCCAABEgNA
Ch8KSwoGBAADAgIAEgRCBkMMGjsgQWRkaXRpb25hbCBjb25maWdzIGZvciBmcmVxdWVudGx5
LWJvdWdodC10b2dldGhlciBtb2RlbHMuCgoOCgcEAAMCAgAGEgNCBiwKDgoHBAADAgIAARID
Qi1OCg4KBwQAAwICAAMSA0MKCwovCgQEAAQAEgRIAlUDGiEgVGhlIHNlcnZpbmcgc3RhdGUg
b2YgdGhlIG1vZGVsLgoKDAoFBAAEAAESA0gHEworCgYEAAQAAgASA0oEIhocIFVuc3BlY2lm
aWVkIHNlcnZpbmcgc3RhdGUuCgoOCgcEAAQAAgABEgNKBB0KDgoHBAAEAAIAAhIDSiAhCioK
BgQABAACARIDTQQRGhsgVGhlIG1vZGVsIGlzIG5vdCBzZXJ2aW5nLgoKDgoHBAAEAAIBARID
TQQMCg4KBwQABAACAQISA00PEAo5CgYEAAQAAgISA1AEDxoqIFRoZSBtb2RlbCBpcyBzZXJ2
aW5nIGFuZCBjYW4gYmUgcXVlcmllZC4KCg4KBwQABAACAgESA1AECgoOCgcEAAQAAgICEgNQ
DQ4KUwoGBAAEAAIDEgNUBA4aRCBUaGUgbW9kZWwgaXMgdHJhaW5lZCBvbiB0dW5lZCBoeXBl
cnBhcmFtZXRlcnMgYW5kIGNhbiBiZQogcXVlcmllZC4KCg4KBwQABAACAwESA1QECQoOCgcE
AAQAAgMCEgNUDA0KMAoEBAAEARIEWAJhAxoiIFRoZSB0cmFpbmluZyBzdGF0ZSBvZiB0aGUg
bW9kZWwuCgoMCgUEAAQBARIDWAcUCiwKBgQABAECABIDWgQjGh0gVW5zcGVjaWZpZWQgdHJh
aW5pbmcgc3RhdGUuCgoOCgcEAAQBAgABEgNaBB4KDgoHBAAEAQIAAhIDWiEiCi4KBgQABAEC
ARIDXQQPGh8gVGhlIG1vZGVsIHRyYWluaW5nIGlzIHBhdXNlZC4KCg4KBwQABAECAQESA10E
CgoOCgcEAAQBAgECEgNdDQ4KJwoGBAAEAQICEgNgBBEaGCBUaGUgbW9kZWwgaXMgdHJhaW5p
bmcuCgoOCgcEAAQBAgIBEgNgBAwKDgoHBAAEAQICAhIDYA8QCvwCCgQEAAQCEgRpAnsDGu0C
IERlc2NyaWJlcyB3aGV0aGVyIHBlcmlvZGljIHR1bmluZyBpcyBlbmFibGVkIGZvciB0aGlz
IG1vZGVsCiBvciBub3QuIFBlcmlvZGljIHR1bmluZyBpcyBzY2hlZHVsZWQgYXQgbW9zdCBl
dmVyeSB0aHJlZSBtb250aHMuIFlvdSBjYW4KIHN0YXJ0IGEgdHVuaW5nIHByb2Nlc3MgbWFu
dWFsbHkgYnkgdXNpbmcgdGhlIGBUdW5lTW9kZWxgCiBtZXRob2QsIHdoaWNoIHN0YXJ0cyBh
IHR1bmluZyBwcm9jZXNzIGltbWVkaWF0ZWx5IGFuZCByZXNldHMgdGhlIHF1YXJ0ZXJseQog
c2NoZWR1bGUuIEVuYWJsaW5nIG9yIGRpc2FibGluZyBwZXJpb2RpYyB0dW5pbmcgZG9lcyBu
b3QgYWZmZWN0IGFueQogY3VycmVudCB0dW5pbmcgcHJvY2Vzc2VzLgoKDAoFBAAEAgESA2kH
GgpLCgYEAAQCAgASA2sEKho8IFVuc3BlY2lmaWVkIGRlZmF1bHQgdmFsdWUsIHNob3VsZCBu
ZXZlciBiZSBleHBsaWNpdGx5IHNldC4KCg4KBwQABAICAAESA2sEJQoOCgcEAAQCAgACEgNr
KCkKqwEKBgQABAICARIDcAQhGpsBIFRoZSBtb2RlbCBoYXMgcGVyaW9kaWMgdHVuaW5nIGRp
c2FibGVkLiBUdW5pbmcKIGNhbiBiZSByZWVuYWJsZWQgYnkgY2FsbGluZyB0aGUgYEVuYWJs
ZU1vZGVsUGVyaW9kaWNUdW5pbmdgCiBtZXRob2Qgb3IgYnkgY2FsbGluZyB0aGUgYFR1bmVN
b2RlbGAgbWV0aG9kLgoKDgoHBAAEAgIBARIDcAQcCg4KBwQABAICAQISA3AfIAq5AQoGBAAE
AgICEgN1BBwaqQEgVGhlIG1vZGVsIGNhbm5vdCBiZSB0dW5lZCB3aXRoIHBlcmlvZGljIHR1
bmluZyBPUiB0aGUKIGBUdW5lTW9kZWxgIG1ldGhvZC4gSGlkZSB0aGUgb3B0aW9ucyBpbiBj
dXN0b21lciBVSSBhbmQKIHJlamVjdCBhbnkgcmVxdWVzdHMgdGhyb3VnaCB0aGUgYmFja2Vu
ZCBzZWxmIHNlcnZlIEFQSS4KCg4KBwQABAICAgESA3UEFwoOCgcEAAQCAgICEgN1GhsKhAEK
BgQABAICAxIDegQgGnUgVGhlIG1vZGVsIGhhcyBwZXJpb2RpYyB0dW5pbmcgZW5hYmxlZC4g
VHVuaW5nCiBjYW4gYmUgZGlzYWJsZWQgYnkgY2FsbGluZyB0aGUgYERpc2FibGVNb2RlbFBl
cmlvZGljVHVuaW5nYAogbWV0aG9kLgoKDgoHBAAEAgIDARIDegQbCg4KBwQABAICAwISA3oe
HwpoCgQEAAQDEgV/AokBAxpZIERlc2NyaWJlcyB3aGV0aGVyIHRoaXMgbW9kZWwgaGF2ZSBz
dWZmaWNpZW50IHRyYWluaW5nIGRhdGEKIHRvIGJlIGNvbnRpbnVvdXNseSB0cmFpbmVkLgoK
DAoFBAAEAwESA38HEApMCgYEAAQDAgASBIEBBB8aPCBVbnNwZWNpZmllZCBkZWZhdWx0IHZh
bHVlLCBzaG91bGQgbmV2ZXIgYmUgZXhwbGljaXRseSBzZXQuCgoPCgcEAAQDAgABEgSBAQQa
Cg8KBwQABAMCAAISBIEBHR4KOQoGBAAEAwIBEgSEAQQQGikgVGhlIG1vZGVsIGhhcyBzdWZm
aWNpZW50IHRyYWluaW5nIGRhdGEuCgoPCgcEAAQDAgEBEgSEAQQLCg8KBwQABAMCAQISBIQB
Dg8KcwoGBAAEAwICEgSIAQQTGmMgVGhlIG1vZGVsIGRvZXMgbm90IGhhdmUgc3VmZmljaWVu
dCB0cmFpbmluZyBkYXRhLiBFcnJvcgogbWVzc2FnZXMgY2FuIGJlIHF1ZXJpZWQgdmlhIFN0
YWNrZHJpdmVyLgoKDwoHBAAEAwICARIEiAEEDgoPCgcEAAQDAgICEgSIARESCk4KBAQABAQS
BowBApkBAxo+IFVzZSBzaW5nbGUgb3IgbXVsdGlwbGUgY29udGV4dCBwcm9kdWN0cyBmb3Ig
cmVjb21tZW5kYXRpb25zLgoKDQoFBAAEBAESBIwBBxoKyAEKBgQABAQCABIEkAEEKhq3ASBV
bnNwZWNpZmllZCBkZWZhdWx0IHZhbHVlLCBzaG91bGQgbmV2ZXIgYmUgZXhwbGljaXRseSBz
ZXQuCiBEZWZhdWx0cyB0bwogW01VTFRJUExFX0NPTlRFWFRfUFJPRFVDVFNdW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhLk1vZGVsLkNvbnRleHRQcm9kdWN0c1R5cGUuTVVMVElQTEVf
Q09OVEVYVF9QUk9EVUNUU10uCgoPCgcEAAQEAgABEgSQAQQlCg8KBwQABAQCAAISBJABKCkK
jAEKBgQABAQCARIElAEEHxp8IFVzZSBvbmx5IGEgc2luZ2xlIHByb2R1Y3QgYXMgY29udGV4
dCBmb3IgdGhlIHJlY29tbWVuZGF0aW9uLiBUeXBpY2FsbHkKIHVzZWQgb24gcGFnZXMgbGlr
ZSBhZGQtdG8tY2FydCBvciBwcm9kdWN0IGRldGFpbHMuCgoPCgcEAAQEAgEBEgSUAQQaCg8K
BwQABAQCAQISBJQBHR4KeQoGBAAEBAICEgSYAQQiGmkgVXNlIG9uZSBvciBtdWx0aXBsZSBw
cm9kdWN0cyBhcyBjb250ZXh0IGZvciB0aGUgcmVjb21tZW5kYXRpb24uIFR5cGljYWxseQog
dXNlZCBvbiBzaG9wcGluZyBjYXJ0IHBhZ2VzLgoKDwoHBAAEBAICARIEmAEEHQoPCgcEAAQE
AgICEgSYASAhCoICCgQEAAIAEgShAQI7GvMBIFJlcXVpcmVkLiBUaGUgZnVsbHkgcXVhbGlm
aWVkIHJlc291cmNlIG5hbWUgb2YgdGhlIG1vZGVsLgoKIEZvcm1hdDoKIGBwcm9qZWN0cy97
cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRh
bG9nX2lkfS9tb2RlbHMve21vZGVsX2lkfWAKIGNhdGFsb2dfaWQgaGFzIGNoYXIgbGltaXQg
b2YgNTAuCiByZWNvbW1lbmRhdGlvbl9tb2RlbF9pZCBoYXMgY2hhciBsaW1pdCBvZiA0MC4K
Cg0KBQQAAgAFEgShAQIICg0KBQQAAgABEgShAQkNCg0KBQQAAgADEgShARARCg0KBQQAAgAI
EgShARI6ChAKCAQAAgAInAgAEgShARM5CtgBCgQEAAIBEgSoAQJDGskBIFJlcXVpcmVkLiBU
aGUgZGlzcGxheSBuYW1lIG9mIHRoZSBtb2RlbC4KCiBTaG91bGQgYmUgaHVtYW4gcmVhZGFi
bGUsIHVzZWQgdG8gZGlzcGxheSBSZWNvbW1lbmRhdGlvbiBNb2RlbHMgaW4gdGhlCiBSZXRh
aWwgQ2xvdWQgQ29uc29sZSBEYXNoYm9hcmQuIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGgg
bGltaXQgb2YgMTAyNAogY2hhcmFjdGVycy4KCg0KBQQAAgEFEgSoAQIICg0KBQQAAgEBEgSo
AQkVCg0KBQQAAgEDEgSoARgZCg0KBQQAAgEIEgSoARpCChAKCAQAAgEInAgAEgSoARtBCp0D
CgQEAAICEgSyAQJMGo4DIE9wdGlvbmFsLiBUaGUgdHJhaW5pbmcgc3RhdGUgdGhhdCB0aGUg
bW9kZWwgaXMgaW4gKGUuZy4KIGBUUkFJTklOR2Agb3IgYFBBVVNFRGApLgoKIFNpbmNlIHBh
cnQgb2YgdGhlIGNvc3Qgb2YgcnVubmluZyB0aGUgc2VydmljZQogaXMgZnJlcXVlbmN5IG9m
IHRyYWluaW5nIC0gdGhpcyBjYW4gYmUgdXNlZCB0byBkZXRlcm1pbmUgd2hlbiB0byB0cmFp
bgogbW9kZWwgaW4gb3JkZXIgdG8gY29udHJvbCBjb3N0LiBJZiBub3Qgc3BlY2lmaWVkOiB0
aGUgZGVmYXVsdCB2YWx1ZSBmb3IKIGBDcmVhdGVNb2RlbGAgbWV0aG9kIGlzIGBUUkFJTklO
R2AuIFRoZSBkZWZhdWx0IHZhbHVlIGZvcgogYFVwZGF0ZU1vZGVsYCBtZXRob2QgaXMgdG8g
a2VlcCB0aGUgc3RhdGUgdGhlIHNhbWUgYXMgYmVmb3JlLgoKDQoFBAACAgYSBLIBAg8KDQoF
BAACAgESBLIBEB4KDQoFBAACAgMSBLIBISIKDQoFBAACAggSBLIBI0sKEAoIBAACAgicCAAS
BLIBJEoKVAoEBAACAxIEtQECTRpGIE91dHB1dCBvbmx5LiBUaGUgc2VydmluZyBzdGF0ZSBv
ZiB0aGUgbW9kZWw6IGBBQ1RJVkVgLCBgTk9UX0FDVElWRWAuCgoNCgUEAAIDBhIEtQECDgoN
CgUEAAIDARIEtQEPHAoNCgUEAAIDAxIEtQEfIAoNCgUEAAIDCBIEtQEhTAoQCggEAAIDCJwI
ABIEtQEiSwpRCgQEAAIEEga4AQK5ATIaQSBPdXRwdXQgb25seS4gVGltZXN0YW1wIHRoZSBS
ZWNvbW1lbmRhdGlvbiBNb2RlbCB3YXMgY3JlYXRlZCBhdC4KCg0KBQQAAgQGEgS4AQIbCg0K
BQQAAgQBEgS4ARwnCg0KBQQAAgQDEgS4ASorCg0KBQQAAgQIEgS5AQYxChAKCAQAAgQInAgA
EgS5AQcwCrIBCgQEAAIFEga+AQK/ATIaoQEgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB0aGUg
UmVjb21tZW5kYXRpb24gTW9kZWwgd2FzIGxhc3QgdXBkYXRlZC4gRS5nLgogaWYgYSBSZWNv
bW1lbmRhdGlvbiBNb2RlbCB3YXMgcGF1c2VkIC0gdGhpcyB3b3VsZCBiZSB0aGUgdGltZSB0
aGUgcGF1c2Ugd2FzCiBpbml0aWF0ZWQuCgoNCgUEAAIFBhIEvgECGwoNCgUEAAIFARIEvgEc
JwoNCgUEAAIFAxIEvgEqKwoNCgUEAAIFCBIEvwEGMQoQCggEAAIFCJwIABIEvwEHMAq6BgoE
BAACBhIE0AECOxqrBiBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgbW9kZWwgZS5nLiBgaG9tZS1w
YWdlYC4KCiBDdXJyZW50bHkgc3VwcG9ydGVkIHZhbHVlczogYHJlY29tbWVuZGVkLWZvci15
b3VgLCBgb3RoZXJzLXlvdS1tYXktbGlrZWAsCiBgZnJlcXVlbnRseS1ib3VnaHQtdG9nZXRo
ZXJgLCBgcGFnZS1vcHRpbWl6YXRpb25gLCBgc2ltaWxhci1pdGVtc2AsCiBgYnV5LWl0LWFn
YWluYCwgYG9uLXNhbGUtaXRlbXNgLCBhbmQgYHJlY2VudGx5LXZpZXdlZGAocmVhZG9ubHkg
dmFsdWUpLgoKIFRoaXMgZmllbGQgdG9nZXRoZXIgd2l0aAogW29wdGltaXphdGlvbl9vYmpl
Y3RpdmVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLk1vZGVsLm9wdGltaXphdGlvbl9v
YmplY3RpdmVdCiBkZXNjcmliZSBtb2RlbCBtZXRhZGF0YSB0byB1c2UgdG8gY29udHJvbCBt
b2RlbCB0cmFpbmluZyBhbmQgc2VydmluZy4KIFNlZSBodHRwczovL2Nsb3VkLmdvb2dsZS5j
b20vcmV0YWlsL2RvY3MvbW9kZWxzCiBmb3IgbW9yZSBkZXRhaWxzIG9uIHdoYXQgdGhlIG1v
ZGVsIG1ldGFkYXRhIGNvbnRyb2wgYW5kIHdoaWNoIGNvbWJpbmF0aW9uCiBvZiBwYXJhbWV0
ZXJzIGFyZSB2YWxpZC4gRm9yIGludmFsaWQgY29tYmluYXRpb25zIG9mIHBhcmFtZXRlcnMg
KGUuZy4gdHlwZQogPSBgZnJlcXVlbnRseS1ib3VnaHQtdG9nZXRoZXJgIGFuZCBvcHRpbWl6
YXRpb25fb2JqZWN0aXZlID0gYGN0cmApLCB5b3UKIHJlY2VpdmUgYW4gZXJyb3IgNDAwIGlm
IHlvdSB0cnkgdG8gY3JlYXRlL3VwZGF0ZSBhIHJlY29tbWVuZGF0aW9uIHdpdGgKIHRoaXMg
c2V0IG9mIGtub2JzLgoKDQoFBAACBgUSBNABAggKDQoFBAACBgESBNABCQ0KDQoFBAACBgMS
BNABEBEKDQoFBAACBggSBNABEjoKEAoIBAACBgicCAASBNABEzkK8wYKBAQAAgcSBOkBAk0a
5AYgT3B0aW9uYWwuIFRoZSBvcHRpbWl6YXRpb24gb2JqZWN0aXZlIGUuZy4gYGN2cmAuCgog
Q3VycmVudGx5IHN1cHBvcnRlZAogdmFsdWVzOiBgY3RyYCwgYGN2cmAsIGByZXZlbnVlLXBl
ci1vcmRlcmAuCgogIElmIG5vdCBzcGVjaWZpZWQsIHdlIGNob29zZSBkZWZhdWx0IGJhc2Vk
IG9uIG1vZGVsIHR5cGUuCiBEZWZhdWx0IGRlcGVuZHMgb24gdHlwZSBvZiByZWNvbW1lbmRh
dGlvbjoKCiBgcmVjb21tZW5kZWQtZm9yLXlvdWAgPT4gYGN0cmAKCiBgb3RoZXJzLXlvdS1t
YXktbGlrZWAgPT4gYGN0cmAKCiBgZnJlcXVlbnRseS1ib3VnaHQtdG9nZXRoZXJgID0+IGBy
ZXZlbnVlX3Blcl9vcmRlcmAKCiBUaGlzIGZpZWxkIHRvZ2V0aGVyIHdpdGgKIFtvcHRpbWl6
YXRpb25fb2JqZWN0aXZlXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Nb2RlbC50eXBl
XQogZGVzY3JpYmUgbW9kZWwgbWV0YWRhdGEgdG8gdXNlIHRvIGNvbnRyb2wgbW9kZWwgdHJh
aW5pbmcgYW5kIHNlcnZpbmcuCiBTZWUgaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3JldGFp
bC9kb2NzL21vZGVscwogZm9yIG1vcmUgZGV0YWlscyBvbiB3aGF0IHRoZSBtb2RlbCBtZXRh
ZGF0YSBjb250cm9sIGFuZCB3aGljaCBjb21iaW5hdGlvbgogb2YgcGFyYW1ldGVycyBhcmUg
dmFsaWQuIEZvciBpbnZhbGlkIGNvbWJpbmF0aW9ucyBvZiBwYXJhbWV0ZXJzIChlLmcuIHR5
cGUKID0gYGZyZXF1ZW50bHktYm91Z2h0LXRvZ2V0aGVyYCBhbmQgb3B0aW1pemF0aW9uX29i
amVjdGl2ZSA9IGBjdHJgKSwgeW91CiByZWNlaXZlIGFuIGVycm9yIDQwMCBpZiB5b3UgdHJ5
IHRvIGNyZWF0ZS91cGRhdGUgYSByZWNvbW1lbmRhdGlvbiB3aXRoCiB0aGlzIHNldCBvZiBr
bm9icy4KCg0KBQQAAgcFEgTpAQIICg0KBQQAAgcBEgTpAQkfCg0KBQQAAgcDEgTpASIjCg0K
BQQAAgcIEgTpASRMChAKCAQAAgcInAgAEgTpASVLCsMBCgQEAAIIEgbwAQLxAS8asgEgT3B0
aW9uYWwuIFRoZSBzdGF0ZSBvZiBwZXJpb2RpYyB0dW5pbmcuCgogVGhlIHBlcmlvZCB3ZSB1
c2UgaXMgMyBtb250aHMgLSB0byBkbyBhCiBvbmUtb2ZmIHR1bmUgZWFybGllciB1c2UgdGhl
IGBUdW5lTW9kZWxgIG1ldGhvZC4gRGVmYXVsdCB2YWx1ZQogaXMgYFBFUklPRElDX1RVTklO
R19FTkFCTEVEYC4KCg0KBQQAAggGEgTwAQIVCg0KBQQAAggBEgTwARYrCg0KBQQAAggDEgTw
AS4wCg0KBQQAAggIEgTxAQYuChAKCAQAAggInAgAEgTxAQctClYKBAQAAgkSBvQBAvUBMhpG
IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIGxhdGVzdCBzdWNjZXNzZnVs
IHR1bmUgZmluaXNoZWQuCgoNCgUEAAIJBhIE9AECGwoNCgUEAAIJARIE9AEcKgoNCgUEAAIJ
AxIE9AEtLwoNCgUEAAIJCBIE9QEGMQoQCggEAAIJCJwIABIE9QEHMArEAQoEBAACChIE+wEC
Sxq1ASBPdXRwdXQgb25seS4gVGhlIHR1bmUgb3BlcmF0aW9uIGFzc29jaWF0ZWQgd2l0aCB0
aGUgbW9kZWwuCgogQ2FuIGJlIHVzZWQgdG8gZGV0ZXJtaW5lIGlmIHRoZXJlIGlzIGFuIG9u
Z29pbmcgdHVuZSBmb3IgdGhpcwogcmVjb21tZW5kYXRpb24uIEVtcHR5IGZpZWxkIGltcGxp
ZXMgbm8gdHVuZSBpcyBnb2lnIG9uLgoKDQoFBAACCgUSBPsBAggKDQoFBAACCgESBPsBCRkK
DQoFBAACCgMSBPsBHB4KDQoFBAACCggSBPsBH0oKEAoIBAACCgicCAASBPsBIEkKiwMKBAQA
AgsSBIUCAkga/AIgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiBkYXRhIHJlcXVpcmVtZW50
cyBmb3IgdGhpcyBtb2RlbDogYERBVEFfT0tgIGFuZAogYERBVEFfRVJST1JgLgoKIFJlY29t
bWVuZGF0aW9uIG1vZGVsIGNhbm5vdCBiZSB0cmFpbmVkIGlmIHRoZSBkYXRhIGlzIGluCiBg
REFUQV9FUlJPUmAgc3RhdGUuIFJlY29tbWVuZGF0aW9uIG1vZGVsIGNhbiBoYXZlIGBEQVRB
X0VSUk9SYCBzdGF0ZSBldmVuCiBpZiBzZXJ2aW5nIHN0YXRlIGlzIGBBQ1RJVkVgOiBtb2Rl
bHMgd2VyZSB0cmFpbmVkIHN1Y2Nlc3NmdWxseSBiZWZvcmUsIGJ1dAogY2Fubm90IGJlIHJl
ZnJlc2hlZCBiZWNhdXNlIG1vZGVsIG5vIGxvbmdlciBoYXMgc3VmZmljaWVudAogZGF0YSBm
b3IgdHJhaW5pbmcuCgoNCgUEAAILBhIEhQICCwoNCgUEAAILARIEhQIMFgoNCgUEAAILAxIE
hQIZGwoNCgUEAAILCBIEhQIcRwoQCggEAAILCJwIABIEhQIdRgqFAQoEBAACDBIGiQICigIv
GnUgT3B0aW9uYWwuIElmIGBSRUNPTU1FTkRBVElPTlNfRklMVEVSSU5HX0VOQUJMRURgLCBy
ZWNvbW1lbmRhdGlvbiBmaWx0ZXJpbmcKIGJ5IGF0dHJpYnV0ZXMgaXMgZW5hYmxlZCBmb3Ig
dGhlIG1vZGVsLgoKDQoFBAACDAYSBIkCAiAKDQoFBAACDAESBIkCITEKDQoFBAACDAMSBIkC
NDYKDQoFBAACDAgSBIoCBi4KEAoIBAACDAicCAASBIoCBy0KbQoEBAACDRIGjgICjwIyGl0g
T3V0cHV0IG9ubHkuIFRoZSBsaXN0IG9mIHZhbGlkIHNlcnZpbmcgY29uZmlncyBhc3NvY2lh
dGVkIHdpdGggdGhlCiBQYWdlT3B0aW1pemF0aW9uQ29uZmlnLgoKDQoFBAACDQQSBI4CAgoK
DQoFBAACDQYSBI4CCxwKDQoFBAACDQESBI4CHTEKDQoFBAACDQMSBI4CNDYKDQoFBAACDQgS
BI8CBjEKEAoIBAACDQicCAASBI8CBzAKPQoEBAACDhIGkgICkwIvGi0gT3B0aW9uYWwuIEFk
ZGl0aW9uYWwgbW9kZWwgZmVhdHVyZXMgY29uZmlnLgoKDQoFBAACDgYSBJICAhUKDQoFBAAC
DgESBJICFisKDQoFBAACDgMSBJICLjAKDQoFBAACDggSBJMCBi4KEAoIBAACDgicCAASBJMC
By1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::Model::Model ===
    # Fields for Model
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: training_state Type: 14 (.google.cloud.retail.v2beta.Model.TrainingState)
    # Field: serving_state Type: 14 (.google.cloud.retail.v2beta.Model.ServingState)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: type Type: 9 ()
    # Field: optimization_objective Type: 9 ()
    # Field: periodic_tuning_state Type: 14 (.google.cloud.retail.v2beta.Model.PeriodicTuningState)
    # Field: last_tune_time Type: 11 (.google.protobuf.Timestamp)
    # Field: tuning_operation Type: 9 ()
    # Field: data_state Type: 14 (.google.cloud.retail.v2beta.Model.DataState)
    # Field: filtering_option Type: 14 (.google.cloud.retail.v2beta.RecommendationsFilteringOption)
    # Field: serving_config_lists Type: 11 (.google.cloud.retail.v2beta.Model.ServingConfigList)
    # Field: model_features_config Type: 11 (.google.cloud.retail.v2beta.Model.ModelFeaturesConfig)

# Enum: Model::ServingState
our $Model_SERVING_STATE_UNSPECIFIED = 0;
our $Model_INACTIVE = 1;
our $Model_ACTIVE = 2;
our $Model_TUNED = 3;

# Enum: Model::TrainingState
our $Model_TRAINING_STATE_UNSPECIFIED = 0;
our $Model_PAUSED = 1;
our $Model_TRAINING = 2;

# Enum: Model::PeriodicTuningState
our $Model_PERIODIC_TUNING_STATE_UNSPECIFIED = 0;
our $Model_PERIODIC_TUNING_DISABLED = 1;
our $Model_ALL_TUNING_DISABLED = 3;
our $Model_PERIODIC_TUNING_ENABLED = 2;

# Enum: Model::DataState
our $Model_DATA_STATE_UNSPECIFIED = 0;
our $Model_DATA_OK = 1;
our $Model_DATA_ERROR = 2;

# Enum: Model::ContextProductsType
our $Model_CONTEXT_PRODUCTS_TYPE_UNSPECIFIED = 0;
our $Model_SINGLE_CONTEXT_PRODUCT = 1;
our $Model_MULTIPLE_CONTEXT_PRODUCTS = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::Model - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/model.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::Model;

    my $msg = Google::Cloud::Retail::V2beta::Model::Model->new({
        name => $name,
        display_name => $display_name,
        training_state => $training_state,
        serving_state => $serving_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::Model::Model

Metadata that describes the training and serving parameters of a
[Model][google.cloud.retail.v2beta.Model]. A
[Model][google.cloud.retail.v2beta.Model] can be associated with a
[ServingConfig][google.cloud.retail.v2beta.ServingConfig] and then queried
through the Predict API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The fully qualified resource name of the model.

Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}`
catalog_id has char limit of 50.
recommendation_model_id has char limit of 40.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the model.

Should be human readable, used to display Recommendation Models in the
Retail Cloud Console Dashboard. UTF-8 encoded string with limit of 1024
characters.

=item * C<< $msg->training_state() >> / C<< $msg->training_state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::Model::TrainingState>)

Optional. The training state that the model is in (e.g.
`TRAINING` or `PAUSED`).

Since part of the cost of running the service
is frequency of training - this can be used to determine when to train
model in order to control cost. If not specified: the default value for
`CreateModel` method is `TRAINING`. The default value for
`UpdateModel` method is to keep the state the same as before.

=item * C<< $msg->serving_state() >> / C<< $msg->serving_state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::Model::ServingState>)

Output only. The serving state of the model: `ACTIVE`, `NOT_ACTIVE`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the Recommendation Model was created at.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the Recommendation Model was last updated. E.g.
if a Recommendation Model was paused - this would be the time the pause was
initiated.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. The type of model e.g. `home-page`.

Currently supported values: `recommended-for-you`, `others-you-may-like`,
`frequently-bought-together`, `page-optimization`, `similar-items`,
`buy-it-again`, `on-sale-items`, and `recently-viewed`(readonly value).

This field together with
[optimization_objective][google.cloud.retail.v2beta.Model.optimization_objective]
describe model metadata to use to control model training and serving.
See https://cloud.google.com/retail/docs/models
for more details on what the model metadata control and which combination
of parameters are valid. For invalid combinations of parameters (e.g. type
 = `frequently-bought-together` and optimization_objective = `ctr`), you
receive an error 400 if you try to create/update a recommendation with
this set of knobs.

=item * C<< $msg->optimization_objective() >> / C<< $msg->optimization_objective($value) >>

Type: C<String>

Optional. The optimization objective e.g. `cvr`.

Currently supported
values: `ctr`, `cvr`, `revenue-per-order`.

 If not specified, we choose default based on model type.
Default depends on type of recommendation:

`recommended-for-you` => `ctr`

`others-you-may-like` => `ctr`

`frequently-bought-together` => `revenue_per_order`

This field together with
[optimization_objective][google.cloud.retail.v2beta.Model.type]
describe model metadata to use to control model training and serving.
See https://cloud.google.com/retail/docs/models
for more details on what the model metadata control and which combination
of parameters are valid. For invalid combinations of parameters (e.g. type
 = `frequently-bought-together` and optimization_objective = `ctr`), you
receive an error 400 if you try to create/update a recommendation with
this set of knobs.

=item * C<< $msg->periodic_tuning_state() >> / C<< $msg->periodic_tuning_state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::Model::PeriodicTuningState>)

Optional. The state of periodic tuning.

The period we use is 3 months - to do a
one-off tune earlier use the `TuneModel` method. Default value
is `PERIODIC_TUNING_ENABLED`.

=item * C<< $msg->last_tune_time() >> / C<< $msg->last_tune_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the latest successful tune finished.

=item * C<< $msg->tuning_operation() >> / C<< $msg->tuning_operation($value) >>

Type: C<String>

Output only. The tune operation associated with the model.

Can be used to determine if there is an ongoing tune for this
recommendation. Empty field implies no tune is goig on.

=item * C<< $msg->data_state() >> / C<< $msg->data_state($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::Model::DataState>)

Output only. The state of data requirements for this model: `DATA_OK` and
`DATA_ERROR`.

Recommendation model cannot be trained if the data is in
`DATA_ERROR` state. Recommendation model can have `DATA_ERROR` state even
if serving state is `ACTIVE`: models were trained successfully before, but
cannot be refreshed because model no longer has sufficient
data for training.

=item * C<< $msg->filtering_option() >> / C<< $msg->filtering_option($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::RecommendationsFilteringOption>)

Optional. If `RECOMMENDATIONS_FILTERING_ENABLED`, recommendation filtering
by attributes is enabled for the model.

=item * C<< $msg->serving_config_lists() >> / C<< $msg->serving_config_lists($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Model::Model::ServingConfigList>)

Output only. The list of valid serving configs associated with the
PageOptimizationConfig.

=item * C<< $msg->model_features_config() >> / C<< $msg->model_features_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Model::Model::ModelFeaturesConfig>)

Optional. Additional model features config.

=back

=head3 Enum: Model::ServingState

=over 4

=item * C<SERVING_STATE_UNSPECIFIED> => C<0>

=item * C<INACTIVE> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<TUNED> => C<3>

=back

=head3 Enum: Model::TrainingState

=over 4

=item * C<TRAINING_STATE_UNSPECIFIED> => C<0>

=item * C<PAUSED> => C<1>

=item * C<TRAINING> => C<2>

=back

=head3 Enum: Model::PeriodicTuningState

=over 4

=item * C<PERIODIC_TUNING_STATE_UNSPECIFIED> => C<0>

=item * C<PERIODIC_TUNING_DISABLED> => C<1>

=item * C<ALL_TUNING_DISABLED> => C<3>

=item * C<PERIODIC_TUNING_ENABLED> => C<2>

=back

=head3 Enum: Model::DataState

=over 4

=item * C<DATA_STATE_UNSPECIFIED> => C<0>

=item * C<DATA_OK> => C<1>

=item * C<DATA_ERROR> => C<2>

=back

=head3 Enum: Model::ContextProductsType

=over 4

=item * C<CONTEXT_PRODUCTS_TYPE_UNSPECIFIED> => C<0>

=item * C<SINGLE_CONTEXT_PRODUCT> => C<1>

=item * C<MULTIPLE_CONTEXT_PRODUCTS> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
