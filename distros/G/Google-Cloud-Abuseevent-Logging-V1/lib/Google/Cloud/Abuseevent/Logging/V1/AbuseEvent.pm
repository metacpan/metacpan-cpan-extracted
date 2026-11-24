package Google::Cloud::Abuseevent::Logging::V1::AbuseEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldInfo };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvYWJ1c2VldmVudC9sb2dnaW5nL3YxL2FidXNlX2V2ZW50LnByb3Rv
EiJnb29nbGUuY2xvdWQuYWJ1c2VldmVudC5sb2dnaW5nLnYxGhtnb29nbGUvYXBpL2ZpZWxk
X2luZm8ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i2wkKCkFidXNl
RXZlbnQSYwoOZGV0ZWN0aW9uX3R5cGUYASABKA4yPC5nb29nbGUuY2xvdWQuYWJ1c2VldmVu
dC5sb2dnaW5nLnYxLkFidXNlRXZlbnQuRGV0ZWN0aW9uVHlwZVINZGV0ZWN0aW9uVHlwZRIW
CgZyZWFzb24YAiABKAlSBnJlYXNvbhJRCgZhY3Rpb24YAyABKA4yOS5nb29nbGUuY2xvdWQu
YWJ1c2VldmVudC5sb2dnaW5nLnYxLkFidXNlRXZlbnQuQWN0aW9uVHlwZVIGYWN0aW9uEmcK
E2NyeXB0b19taW5pbmdfZXZlbnQYBCABKAsyNS5nb29nbGUuY2xvdWQuYWJ1c2VldmVudC5s
b2dnaW5nLnYxLkNyeXB0b01pbmluZ0V2ZW50SABSEWNyeXB0b01pbmluZ0V2ZW50EnMKF2xl
YWtlZF9jcmVkZW50aWFsX2V2ZW50GAUgASgLMjkuZ29vZ2xlLmNsb3VkLmFidXNlZXZlbnQu
bG9nZ2luZy52MS5MZWFrZWRDcmVkZW50aWFsRXZlbnRIAFIVbGVha2VkQ3JlZGVudGlhbEV2
ZW50Em0KFWhhcm1mdWxfY29udGVudF9ldmVudBgGIAEoCzI3Lmdvb2dsZS5jbG91ZC5hYnVz
ZWV2ZW50LmxvZ2dpbmcudjEuSGFybWZ1bENvbnRlbnRFdmVudEgAUhNoYXJtZnVsQ29udGVu
dEV2ZW50EmkKE3JlaW5zdGF0ZW1lbnRfZXZlbnQYCCABKAsyNi5nb29nbGUuY2xvdWQuYWJ1
c2VldmVudC5sb2dnaW5nLnYxLlJlaW5zdGF0ZW1lbnRFdmVudEgAUhJyZWluc3RhdGVtZW50
RXZlbnQSeQoZZGVjaXNpb25fZXNjYWxhdGlvbl9ldmVudBgJIAEoCzI7Lmdvb2dsZS5jbG91
ZC5hYnVzZWV2ZW50LmxvZ2dpbmcudjEuRGVjaXNpb25Fc2NhbGF0aW9uRXZlbnRIAFIXZGVj
aXNpb25Fc2NhbGF0aW9uRXZlbnQScwoXaW50cnVzaW9uX2F0dGVtcHRfZXZlbnQYCiABKAsy
OS5nb29nbGUuY2xvdWQuYWJ1c2VldmVudC5sb2dnaW5nLnYxLkludHJ1c2lvbkF0dGVtcHRF
dmVudEgAUhVpbnRydXNpb25BdHRlbXB0RXZlbnQSKQoQcmVtZWRpYXRpb25fbGluaxgHIAEo
CVIPcmVtZWRpYXRpb25MaW5rIpoBCg1EZXRlY3Rpb25UeXBlEh4KGkRFVEVDVElPTl9UWVBF
X1VOU1BFQ0lGSUVEEAASEQoNQ1JZUFRPX01JTklORxABEhYKEkxFQUtFRF9DUkVERU5USUFM
UxACEgwKCFBISVNISU5HEAMSCwoHTUFMV0FSRRAEEgwKCE5PX0FCVVNFEAUSFQoRSU5UUlVT
SU9OX0FUVEVNUFQQBiJ/CgpBY3Rpb25UeXBlEhsKF0FDVElPTl9UWVBFX1VOU1BFQ0lGSUVE
EAASCgoGTk9USUZZEAESFgoSUFJPSkVDVF9TVVNQRU5TSU9OEAISDQoJUkVJTlNUQVRFEAMS
CAoEV0FSThAEEhcKE1JFU09VUkNFX1NVU1BFTlNJT04QBUIMCgpldmVudF90eXBlIoECChFD
cnlwdG9NaW5pbmdFdmVudBIfCgt2bV9yZXNvdXJjZRgBIAMoCVIKdm1SZXNvdXJjZRJXChpk
ZXRlY3RlZF9taW5pbmdfc3RhcnRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSF2RldGVjdGVkTWluaW5nU3RhcnRUaW1lElMKGGRldGVjdGVkX21pbmluZ19lbmRf
dGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSFWRldGVjdGVkTWluaW5n
RW5kVGltZRIdCgV2bV9pcBgEIAMoCUII4ozP1wgCCARSBHZtSXAisQIKFUxlYWtlZENyZWRl
bnRpYWxFdmVudBJ8ChpzZXJ2aWNlX2FjY291bnRfY3JlZGVudGlhbBgBIAEoCzI8Lmdvb2ds
ZS5jbG91ZC5hYnVzZWV2ZW50LmxvZ2dpbmcudjEuU2VydmljZUFjY291bnRDcmVkZW50aWFs
SABSGHNlcnZpY2VBY2NvdW50Q3JlZGVudGlhbBJkChJhcGlfa2V5X2NyZWRlbnRpYWwYAiAB
KAsyNC5nb29nbGUuY2xvdWQuYWJ1c2VldmVudC5sb2dnaW5nLnYxLkFwaUtleUNyZWRlbnRp
YWxIAFIQYXBpS2V5Q3JlZGVudGlhbBIhCgxkZXRlY3RlZF91cmkYAyABKAlSC2RldGVjdGVk
VXJpQhEKD2NyZWRlbnRpYWxfdHlwZSKRAgoVSW50cnVzaW9uQXR0ZW1wdEV2ZW50Eh8KC3Zt
X3Jlc291cmNlGAEgAygJUgp2bVJlc291cmNlEl0KHWRldGVjdGVkX2ludHJ1c2lvbl9zdGFy
dF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIaZGV0ZWN0ZWRJbnRy
dXNpb25TdGFydFRpbWUSWQobZGV0ZWN0ZWRfaW50cnVzaW9uX2VuZF90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIYZGV0ZWN0ZWRJbnRydXNpb25FbmRUaW1lEh0K
BXZtX2lwGAQgAygJQgjijM/XCAIIBFIEdm1JcCJaChhTZXJ2aWNlQWNjb3VudENyZWRlbnRp
YWwSJwoPc2VydmljZV9hY2NvdW50GAEgASgJUg5zZXJ2aWNlQWNjb3VudBIVCgZrZXlfaWQY
AiABKAlSBWtleUlkIisKEEFwaUtleUNyZWRlbnRpYWwSFwoHYXBpX2tleRgBIAEoCVIGYXBp
S2V5IicKE0hhcm1mdWxDb250ZW50RXZlbnQSEAoDdXJpGAEgAygJUgN1cmkiFAoSUmVpbnN0
YXRlbWVudEV2ZW50IhkKF0RlY2lzaW9uRXNjYWxhdGlvbkV2ZW50QqIBCiZjb20uZ29vZ2xl
LmNsb3VkLmFidXNlZXZlbnQubG9nZ2luZy52MUIPQWJ1c2VFdmVudFByb3RvUAFaQGNsb3Vk
Lmdvb2dsZS5jb20vZ28vYWJ1c2VldmVudC9sb2dnaW5nL2FwaXYxL2xvZ2dpbmdwYjtsb2dn
aW5ncGKqAiJHb29nbGUuQ2xvdWQuQWJ1c2VFdmVudC5Mb2dnaW5nLlYxSqk2CgcSBQ4AxQEi
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkKAgMAEgMS
ACUKCQoCAwESAxMAKQoICgEIEgMVAD8KCQoCCCUSAxUAPwoICgEIEgMWAFcKCQoCCAsSAxYA
VwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADAKCQoCCAgSAxgAMAoICgEIEgMZAD8K
CQoCCAESAxkAPwpRCgIEABIEHAB1ARpFIExvZ2dlZCBldmVudCBkaXNjdXNzaW5nIGFuIGFi
dXNlIGZpbmRpbmcgb24gdGhlIG1vbml0b3JlZCByZXNvdXJjZS4KCgoKAwQAARIDHAgSCk8K
BAQABAASBB4CNwMaQSBJbmRpY2F0ZXMgdGhlIHR5cGUgb2YgYWJ1c2UgZGV0ZWN0ZWQgb24g
dGhlIG1vbml0b3JlZCByZXNvdXJjZS4KCgwKBQQABAABEgMeBxQKOgoGBAAEAAIAEgMgBCMa
KyBEZWZhdWx0L3Vuc3BlY2lmaWVkIGFidXNlIGRldGVjdGlvbiB0eXBlLgoKDgoHBAAEAAIA
ARIDIAQeCg4KBwQABAACAAISAyAhIgpJCgYEAAQAAgESAyMEFho6IFRoZSBtb25pdG9yZWQg
cmVzb3VyY2UgaXMgdXNlZCB0byBtaW5lIGNyeXB0b2N1cnJlbmNpZXMuCgoOCgcEAAQAAgEB
EgMjBBEKDgoHBAAEAAIBAhIDIxQVCmUKBgQABAACAhIDJwQbGlYgVGhlIG1vbml0b3JlZCBy
ZXNvdXJjZSdzIGNyZWRlbnRpYWxzIGhhdmUgYWNjaWRlbnRhbGx5IGJlZW4gbGVha2VkIG9u
IHRoZQogaW50ZXJuZXQuCgoOCgcEAAQAAgIBEgMnBBYKDgoHBAAEAAICAhIDJxkaCkUKBgQA
BAACAxIDKgQRGjYgVGhlIG1vbml0b3JlZCByZXNvdXJjZSBpcyB1c2VkIGZvciBwaGlzaGlu
ZyBhdHRhY2tzLgoKDgoHBAAEAAIDARIDKgQMCg4KBwQABAACAwISAyoPEAp+CgYEAAQAAgQS
Ay4EEBpvIFRoZSBtb25pdG9yZWQgcmVzb3VyY2UgaXMgYXNzb2NpYXRlZCB3aXRoIGNvbnRl
bnQgdGhhdCBpcyBpbmZlY3RlZCBvcgogaW5mZWN0cyB1c2VycyB3aXRoIG1hbGljaW91cyBz
b2Z0d2FyZS4KCg4KBwQABAACBAESAy4ECwoOCgcEAAQAAgQCEgMuDg8KbAoGBAAEAAIFEgMy
BBEaXSBObyBhYnVzZSBpcyBkZXRlY3RlZCBvbiB0aGUgbW9uaXRvcmVkIHJlc291cmNlLCBi
dXQgaXRzIGFidXNlIHN0YXRlIG1heQogaGF2ZSBiZWVuIHVwZGF0ZWQuCgoOCgcEAAQAAgUB
EgMyBAwKDgoHBAAEAAIFAhIDMg8QCmwKBgQABAACBhIDNgQaGl0gVGhlIG1vbml0b3JlZCBy
ZXNvdXJjZSBpcyBiZWxpZXZlZCB0byBiZSBhdHRlbXB0aW5nIHRvIGludHJ1ZGUgdXBvbgog
dGhpcmQtcGFydHkgcmVzb3VyY2VzLgoKDgoHBAAEAAIGARIDNgQVCg4KBwQABAACBgISAzYY
GQpdCgQEAAQBEgQ7Ak8DGk8gSW5kaWNhdGVzIGFueSBhY3Rpb24gdGFrZW4gb24gdGhlIG1v
bml0b3JlZCByZXNvdXJjZSBkdWUgdG8gYWJ1c2UKIGRldGVjdGlvbi4KCgwKBQQABAEBEgM7
BxEKPQoGBAAEAQIAEgM9BCAaLiBUaGUgbW9uaXRvcmVkIHJlc291cmNlIHN0YXRlIGlzIHVu
c3BlY2lmaWVkLgoKDgoHBAAEAQIAARIDPQQbCg4KBwQABAECAAISAz0eHwpaCgYEAAQBAgES
A0AEDxpLIFRoZSBvd25lciBvZiB0aGUgbW9uaXRvcmVkIHJlc291cmNlIG5lZWRzIHRvIGJl
IG5vdGlmaWVkIGFib3V0IGEgZmluZGluZy4KCg4KBwQABAECAQESA0AECgoOCgcEAAQBAgEC
EgNADQ4KQQoGBAAEAQICEgNDBBsaMiBUaGUgYXNzb2NpYXRlZCBjbG91ZCBwcm9qZWN0IGhh
cyBiZWVuIHN1c3BlbmRlZC4KCg4KBwQABAECAgESA0MEFgoOCgcEAAQBAgICEgNDGRoKPAoG
BAAEAQIDEgNGBBIaLSBUaGUgbW9uaXRvcmVkIHJlc291cmNlIGhhcyBiZWVuIHJlaW5zdGF0
ZWQuCgoOCgcEAAQBAgMBEgNGBA0KDgoHBAAEAQIDAhIDRhARCukBCgYEAAQBAgQSA0sEDRrZ
ASBUaGUgb3duZXIgb2YgdGhlIG1vbml0b3JlZCByZXNvdXJjZSBuZWVkcyB0byBiZSB3YXJu
ZWQgYWJvdXQgYWJ1c2l2ZQogYmVoYXZpb3IuIFRoaXMgbm90aWZpY2F0aW9uIGNvdWxkIGxl
YWQgdG8gZnV0dXJlIGVuZm9yY2VtZW50cyBpZiByZW1lZGlhbAogYWN0aW9ucyBhcmUgbm90
IHRha2VuLiBUaGlzIGFjdGlvbiBzaG91bGQgbm90IGJlIGNvbmZ1c2VkIHdpdGggTk9USUZZ
LgoKDgoHBAAEAQIEARIDSwQICg4KBwQABAECBAISA0sLDAo6CgYEAAQBAgUSA04EHBorIFRo
ZSByZXNvdXJjZSAoZWc6IFZNKSBoYXMgYmVlbiBzdXNwZW5kZWQuCgoOCgcEAAQBAgUBEgNO
BBcKDgoHBAAEAQIFAhIDThobClEKBAQAAgASA1ICIxpEIFJFUVVJUkVEIENvcnJlbGF0ZXMg
dG8gdGhlIGFidXNlIGZpbmRpbmcgY2F1c2luZyB0aGUgbm90aWZpY2F0aW9uLgoKDAoFBAAC
AAYSA1ICDwoMCgUEAAIAARIDUhAeCgwKBQQAAgADEgNSISIKQwoEBAACARIDVQIUGjYgUkVR
VUlSRUQgRXhwbGFpbnMgdGhlIG1lYW5pbmcgb2YgdGhlIGRldGVjdGlvbl90eXBlLgoKDAoF
BAACAQUSA1UCCAoMCgUEAAIBARIDVQkPCgwKBQQAAgEDEgNVEhMKUQoEBAACAhIDWAIYGkQg
UkVRVUlSRUQgQ29ycmVsYXRlcyB0byB0aGUgYWN0aW9uIHRha2VuIG9uIHRoZSBtb25pdG9y
ZWQgcmVzb3VyY2UuCgoMCgUEAAICBhIDWAIMCgwKBQQAAgIBEgNYDRMKDAoFBAACAgMSA1gW
FwpUCgQEAAgAEgRbAnEDGkYgUkVRVUlSRUQgQ29udGFpbnMgYWRkaWlvbmFsIG1ldGFkYXRh
IGFib3V0IHRoZSBkZXRlY3RlZCBhYnVzZSBldmVudC4KCgwKBQQACAABEgNbCBIKYwoEBAAC
AxIDXgQuGlYgSW5mb3JtYXRpb24gYWJvdXQgYSBjcnlwdG9jdXJyZW5jeSBtaW5pbmcgZXZl
bnQgb2JzZXJ2ZWQgb24gdGhlIG1vbml0b3JlZAogcmVzb3VyY2UuCgoMCgUEAAIDBhIDXgQV
CgwKBQQAAgMBEgNeFikKDAoFBAACAwMSA14sLQpjCgQEAAIEEgNiBDYaViBJbmZvcm1hdGlv
biBhYm91dCB0aGUgbGVha2VkIGNsaWVudCBjcmVkZW50aWFscyBvYnNlcnZlZCBvbiB0aGUg
bW9uaXRvcmVkCiByZXNvdXJjZS4KCgwKBQQAAgQGEgNiBBkKDAoFBAACBAESA2IaMQoMCgUE
AAIEAxIDYjQ1CmUKBAQAAgUSA2YEMhpYIEluZm9ybWF0aW9uIGFib3V0IHRoZSBwaGlzaGlu
Zy9tYWx3YXJlIFVSSShzKSBhc3NvY2lhdGVkIHdpdGggdGhlCiBtb25pdG9yZWQgcmVzb3Vy
Y2UuCgoMCgUEAAIFBhIDZgQXCgwKBQQAAgUBEgNmGC0KDAoFBAACBQMSA2YwMQpUCgQEAAIG
EgNpBC8aRyBJbmZvcm1hdGlvbiBhYm91dCB0aGUgcmVpbnN0YXRlbWVudCBpc3N1ZWQgb24g
dGhlIG1vbml0b3JlZCByZXNvdXJjZS4KCgwKBQQAAgYGEgNpBBYKDAoFBAACBgESA2kXKgoM
CgUEAAIGAxIDaS0uCmEKBAQAAgcSA20EOhpUIEluZm9ybWF0aW9uIGFib3V0IHRoZSBlc2Nh
bGF0aW9uIG9mIGVuZm9yY2VtZW50IGFjdGlvbiBvbiB0aGUgbW9uaXRvcmVkCiByZXNvdXJj
ZS4KCgwKBQQAAgcGEgNtBBsKDAoFBAACBwESA20cNQoMCgUEAAIHAxIDbTg5CjwKBAQAAggS
A3AENxovIEluZm9ybWF0aW9uIGFib3V0IGFuIGludHJ1c2lvbiBhdHRlbXB0IGV2ZW50LgoK
DAoFBAACCAYSA3AEGQoMCgUEAAIIARIDcBoxCgwKBQQAAggDEgNwNDYKVgoEBAACCRIDdAIe
GkkgQ29udGFpbnMgdGhlIHVtYnJlbGxhIGxpbmsgZm9yIHJlbWVkaWF0aW9uIGFmdGVyIGFu
IGFidXNlIG5vdGlmaWNhdGlvbi4KCgwKBQQAAgkFEgN0AggKDAoFBAACCQESA3QJGQoMCgUE
AAIJAxIDdBwdCmMKAgQBEgV5AIcBARpWIEluZm9ybWF0aW9uIGFib3V0IGEgY3J5cHRvY3Vy
cmVuY3kgbWluaW5nIGV2ZW50IG9ic2VydmVkIG9uIHRoZSBtb25pdG9yZWQKIHJlc291cmNl
LgoKCgoDBAEBEgN5CBkKgQEKBAQBAgASA3wCIhp0IFZNIGFuZCB6b25lIGluIHdoaWNoIGNy
eXB0b2N1cnJlbmN5IG1pbmluZyBvY2N1cnJlZC4KIEZvcm1hdDogcHJvamVjdHMve3Byb2pl
Y3R9L3pvbmVzL3t6b25lfS9pbnN0YW5jZXMve2luc3RhbmNlfQoKDAoFBAECAAQSA3wCCgoM
CgUEAQIABRIDfAsRCgwKBQQBAgABEgN8Eh0KDAoFBAECAAMSA3wgIQpACgQEAQIBEgN/Ajsa
MyBEZXRlY3RlZCBzdGFydCB0aW1lIG9mIHRoZSBjcnlwdG9jdXJyZW5jeSBtaW5pbmcuCgoM
CgUEAQIBBhIDfwIbCgwKBQQBAgEBEgN/HDYKDAoFBAECAQMSA385Ogo/CgQEAQICEgSCAQI5
GjEgRGV0ZWN0ZWQgZW5kIHRpbWUgb2YgdGhlIGNyeXB0b2N1cnJlbmN5IG1pbmluZy4KCg0K
BQQBAgIGEgSCAQIbCg0KBQQBAgIBEgSCARw0Cg0KBQQBAgIDEgSCATc4CpcBCgQEAQIDEgSG
AQJMGogBIFRoZSBJUCBhZGRyZXNzKGVzKSBvZiB0aGUgVk0gYXNzb2NpYXRlZCB3aXRoIHRo
ZSBjcnlwdG9jdXJyZW5jeSBtaW5pbmcuCiBUaGlzIGZpZWxkIG1heSBiZSBlbXB0eSBpZiB0
aGlzIGluZm9ybWF0aW9uIGlzIG5vdCBhdmFpbGFibGUuCgoNCgUEAQIDBBIEhgECCgoNCgUE
AQIDBRIEhgELEQoNCgUEAQIDARIEhgESFwoNCgUEAQIDAxIEhgEaGwoNCgUEAQIDCBIEhgEc
SwoTCgsEAQIDCMzx+YoBARIEhgEdSgpkCgIEAhIGiwEAlwEBGlYgSW5mb3JtYXRpb24gYWJv
dXQgdGhlIGxlYWtlZCBjbGllbnQgY3JlZGVudGlhbHMgb2JzZXJ2ZWQgb24gdGhlIG1vbml0
b3JlZAogcmVzb3VyY2UuCgoLCgMEAgESBIsBCB0KOgoEBAIIABIGjQECkwEDGiogSW5kaWNh
dGVzIHRoZSB0eXBlIG9mIGNyZWRlbnRpYWwgbGVha2VkLgoKDQoFBAIIAAESBI0BCBcKOgoE
BAICABIEjwEEPBosIEluZm9ybWF0aW9uIGFib3V0IGxlYWtlZCBzZXJ2aWNlIGFjY291bnRz
LgoKDQoFBAICAAYSBI8BBBwKDQoFBAICAAESBI8BHTcKDQoFBAICAAMSBI8BOjsKMgoEBAIC
ARIEkgEELBokIEluZm9ybWF0aW9uIGFib3V0IGxlYWtlZCBBUEkga2V5cy4KCg0KBQQCAgEG
EgSSAQQUCg0KBQQCAgEBEgSSARUnCg0KBQQCAgEDEgSSASorCjwKBAQCAgISBJYBAhoaLiBV
Ukkgd2hlcmUgdGhlIGNsaWVudCBjcmVkZW50aWFscyB3ZXJlIGZvdW5kLgoKDQoFBAICAgUS
BJYBAggKDQoFBAICAgESBJYBCRUKDQoFBAICAgMSBJYBGBkKYQoCBAMSBpsBAKgBARpTIElu
Zm9ybWF0aW9uIGFib3V0IGFuIGludHJ1c2lvbiBhdHRlbXB0IGV2ZW50IG9ic2VydmVkIG9u
IHRoZSBtb25pdG9yZWQKIHJlc291cmNlLgoKCwoDBAMBEgSbAQgdCkQKBAQDAgASBJ0BAiIa
NiBWTSBhbmQgem9uZSBpbiB3aGljaCB0aGUgaW50cnVzaW9uIGF0dGVtcHQgb2NjdXJyZWQu
CgoNCgUEAwIABBIEnQECCgoNCgUEAwIABRIEnQELEQoNCgUEAwIAARIEnQESHQoNCgUEAwIA
AxIEnQEgIQo9CgQEAwIBEgSgAQI+Gi8gRGV0ZWN0ZWQgc3RhcnQgdGltZSBvZiB0aGUgaW50
cnVzaW9uIGF0dGVtcHQuCgoNCgUEAwIBBhIEoAECGwoNCgUEAwIBARIEoAEcOQoNCgUEAwIB
AxIEoAE8PQo7CgQEAwICEgSjAQI8Gi0gRGV0ZWN0ZWQgZW5kIHRpbWUgb2YgdGhlIGludHJ1
c2lvbiBhdHRlbXB0LgoKDQoFBAMCAgYSBKMBAhsKDQoFBAMCAgESBKMBHDcKDQoFBAMCAgMS
BKMBOjsKkwEKBAQDAgMSBKcBAkwahAEgVGhlIElQIGFkZHJlc3MoZXMpIG9mIHRoZSBWTSBh
c3NvY2lhdGVkIHdpdGggdGhlIGludHJ1c2lvbiBhdHRlbXB0LgogVGhpcyBmaWVsZCBtYXkg
YmUgZW1wdHkgaWYgdGhpcyBpbmZvcm1hdGlvbiBpcyBub3QgYXZhaWxhYmxlLgoKDQoFBAMC
AwQSBKcBAgoKDQoFBAMCAwUSBKcBCxEKDQoFBAMCAwESBKcBEhcKDQoFBAMCAwMSBKcBGhsK
DQoFBAMCAwgSBKcBHEsKEwoLBAMCAwjM8fmKAQESBKcBHUoKOgoCBAQSBqsBALEBARosIElu
Zm9ybWF0aW9uIGFib3V0IGxlYWtlZCBzZXJ2aWNlIGFjY291bnRzLgoKCwoDBAQBEgSrAQgg
Cj4KBAQEAgASBK0BAh0aMCBTZXJ2aWNlIGFjY291bnQgd2hvc2UgY3JlZGVudGlhbHMgd2Vy
ZSBsZWFrZWQuCgoNCgUEBAIABRIErQECCAoNCgUEBAIAARIErQEJGAoNCgUEBAIAAxIErQEb
HAozCgQEBAIBEgSwAQIUGiUgUHJpdmF0ZSBLZXkgSUQgZm9yIGFueSBsZWFrZWQga2V5cy4K
Cg0KBQQEAgEFEgSwAQIICg0KBQQEAgEBEgSwAQkPCg0KBQQEAgEDEgSwARITCjIKAgQFEga0
AQC3AQEaJCBJbmZvcm1hdGlvbiBhYm91dCBsZWFrZWQgQVBJIGtleXMuCgoLCgMEBQESBLQB
CBgKKAoEBAUCABIEtgECFRoaIEFQSSBrZXkgdGhhdCB3YXMgbGVha2VkLgoKDQoFBAUCAAUS
BLYBAggKDQoFBAUCAAESBLYBCRAKDQoFBAUCAAMSBLYBExQKZAoCBAYSBrsBAL4BARpWIElu
Zm9ybWF0aW9uIGFib3V0IHRoZSBwaGlzaGluZy9tYWx3YXJlIFVSSXMgYXNzb2NpYXRlZCB3
aXRoIHRoZSBtb25pdG9yZWQKIHJlc291cmNlLgoKCwoDBAYBEgS7AQgbCkIKBAQGAgASBL0B
AhoaNCBVUklzIGFzc29jaWF0ZWQgd2l0aCB0aGUgcGhpc2hpbmcvbWFsd2FyZSBmaW5kaW5n
LgoKDQoFBAYCAAQSBL0BAgoKDQoFBAYCAAUSBL0BCxEKDQoFBAYCAAESBL0BEhUKDQoFBAYC
AAMSBL0BGBkKUwoCBAcSBMEBAB0aRyBJbmZvcm1hdGlvbiBhYm91dCB0aGUgcmVpbnN0YXRl
bWVudCBpc3N1ZWQgb24gdGhlIG1vbml0b3JlZCByZXNvdXJjZS4KCgsKAwQHARIEwQEIGgp/
CgIECBIExQEAIhpzIEluZm9ybWF0aW9uIGFib3V0IHRoZSBlc2NhbGF0aW9uIG9mIGVuZm9y
Y2VtZW50IGFjdGlvbiBvbiB0aGUgbW9uaXRvcmVkCiByZXNvdXJjZS4gRWc6IFVzZWQgZm9y
IHJlcGVhdCBvZmZlbmRlcnMuCgoLCgMECAESBMUBCB9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::AbuseEvent ===
    # Fields for AbuseEvent
    # Field: detection_type Type: 14 (.google.cloud.abuseevent.logging.v1.AbuseEvent.DetectionType)
    # Field: reason Type: 9 ()
    # Field: action Type: 14 (.google.cloud.abuseevent.logging.v1.AbuseEvent.ActionType)
    # Field: crypto_mining_event Type: 11 (.google.cloud.abuseevent.logging.v1.CryptoMiningEvent)
    # Field: leaked_credential_event Type: 11 (.google.cloud.abuseevent.logging.v1.LeakedCredentialEvent)
    # Field: harmful_content_event Type: 11 (.google.cloud.abuseevent.logging.v1.HarmfulContentEvent)
    # Field: reinstatement_event Type: 11 (.google.cloud.abuseevent.logging.v1.ReinstatementEvent)
    # Field: decision_escalation_event Type: 11 (.google.cloud.abuseevent.logging.v1.DecisionEscalationEvent)
    # Field: intrusion_attempt_event Type: 11 (.google.cloud.abuseevent.logging.v1.IntrusionAttemptEvent)
    # Field: remediation_link Type: 9 ()

# Enum: AbuseEvent::DetectionType
our $AbuseEvent_DETECTION_TYPE_UNSPECIFIED = 0;
our $AbuseEvent_CRYPTO_MINING = 1;
our $AbuseEvent_LEAKED_CREDENTIALS = 2;
our $AbuseEvent_PHISHING = 3;
our $AbuseEvent_MALWARE = 4;
our $AbuseEvent_NO_ABUSE = 5;
our $AbuseEvent_INTRUSION_ATTEMPT = 6;

# Enum: AbuseEvent::ActionType
our $AbuseEvent_ACTION_TYPE_UNSPECIFIED = 0;
our $AbuseEvent_NOTIFY = 1;
our $AbuseEvent_PROJECT_SUSPENSION = 2;
our $AbuseEvent_REINSTATE = 3;
our $AbuseEvent_WARN = 4;
our $AbuseEvent_RESOURCE_SUSPENSION = 5;

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::CryptoMiningEvent ===
    # Fields for CryptoMiningEvent
    # Field: vm_resource Type: 9 ()
    # Field: detected_mining_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: detected_mining_end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: vm_ip Type: 9 ()

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::LeakedCredentialEvent ===
    # Fields for LeakedCredentialEvent
    # Field: service_account_credential Type: 11 (.google.cloud.abuseevent.logging.v1.ServiceAccountCredential)
    # Field: api_key_credential Type: 11 (.google.cloud.abuseevent.logging.v1.ApiKeyCredential)
    # Field: detected_uri Type: 9 ()

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::IntrusionAttemptEvent ===
    # Fields for IntrusionAttemptEvent
    # Field: vm_resource Type: 9 ()
    # Field: detected_intrusion_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: detected_intrusion_end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: vm_ip Type: 9 ()

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ServiceAccountCredential ===
    # Fields for ServiceAccountCredential
    # Field: service_account Type: 9 ()
    # Field: key_id Type: 9 ()

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ApiKeyCredential ===
    # Fields for ApiKeyCredential
    # Field: api_key Type: 9 ()

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::HarmfulContentEvent ===
    # Fields for HarmfulContentEvent
    # Field: uri Type: 9 ()

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ReinstatementEvent ===
    # Fields for ReinstatementEvent

# === Message: Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::DecisionEscalationEvent ===
    # Fields for DecisionEscalationEvent

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Abuseevent::Logging::V1::AbuseEvent - Compiled Protocol Buffers messages for google/cloud/abuseevent/logging/v1/abuse_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Abuseevent::Logging::V1::AbuseEvent;

    my $msg = Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::AbuseEvent->new({
        detection_type => $detection_type,
        reason => $reason,
        action => $action,
        crypto_mining_event => $crypto_mining_event,
    });

    # Read or update a field
    my $val = $msg->detection_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::AbuseEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/abuseevent/logging/v1/abuse_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::AbuseEvent

Logged event discussing an abuse finding on the monitored resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->detection_type() >> / C<< $msg->detection_type($value) >>

Type: C<Enum> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::DetectionType>)

REQUIRED Correlates to the abuse finding causing the notification.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

REQUIRED Explains the meaning of the detection_type.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ActionType>)

REQUIRED Correlates to the action taken on the monitored resource.

=item * C<< $msg->crypto_mining_event() >> / C<< $msg->crypto_mining_event($value) >>

Type: C<Message> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::CryptoMiningEvent>)

Information about a cryptocurrency mining event observed on the monitored
resource.

=item * C<< $msg->leaked_credential_event() >> / C<< $msg->leaked_credential_event($value) >>

Type: C<Message> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::LeakedCredentialEvent>)

Information about the leaked client credentials observed on the monitored
resource.

=item * C<< $msg->harmful_content_event() >> / C<< $msg->harmful_content_event($value) >>

Type: C<Message> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::HarmfulContentEvent>)

Information about the phishing/malware URI(s) associated with the
monitored resource.

=item * C<< $msg->reinstatement_event() >> / C<< $msg->reinstatement_event($value) >>

Type: C<Message> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ReinstatementEvent>)

Information about the reinstatement issued on the monitored resource.

=item * C<< $msg->decision_escalation_event() >> / C<< $msg->decision_escalation_event($value) >>

Type: C<Message> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::DecisionEscalationEvent>)

Information about the escalation of enforcement action on the monitored
resource.

=item * C<< $msg->intrusion_attempt_event() >> / C<< $msg->intrusion_attempt_event($value) >>

Type: C<Message> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::IntrusionAttemptEvent>)

Information about an intrusion attempt event.

=item * C<< $msg->remediation_link() >> / C<< $msg->remediation_link($value) >>

Type: C<String>

Contains the umbrella link for remediation after an abuse notification.

=back

=head3 Enum: AbuseEvent::DetectionType

=over 4

=item * C<DETECTION_TYPE_UNSPECIFIED> => C<0>

=item * C<CRYPTO_MINING> => C<1>

=item * C<LEAKED_CREDENTIALS> => C<2>

=item * C<PHISHING> => C<3>

=item * C<MALWARE> => C<4>

=item * C<NO_ABUSE> => C<5>

=item * C<INTRUSION_ATTEMPT> => C<6>

=back

=head3 Enum: AbuseEvent::ActionType

=over 4

=item * C<ACTION_TYPE_UNSPECIFIED> => C<0>

=item * C<NOTIFY> => C<1>

=item * C<PROJECT_SUSPENSION> => C<2>

=item * C<REINSTATE> => C<3>

=item * C<WARN> => C<4>

=item * C<RESOURCE_SUSPENSION> => C<5>

=back

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::CryptoMiningEvent

Information about a cryptocurrency mining event observed on the monitored
resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vm_resource() >> / C<< $msg->vm_resource($value) >>

Type: C<String>

VM and zone in which cryptocurrency mining occurred.
Format: projects/{project}/zones/{zone}/instances/{instance}

=item * C<< $msg->detected_mining_start_time() >> / C<< $msg->detected_mining_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Detected start time of the cryptocurrency mining.

=item * C<< $msg->detected_mining_end_time() >> / C<< $msg->detected_mining_end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Detected end time of the cryptocurrency mining.

=item * C<< $msg->vm_ip() >> / C<< $msg->vm_ip($value) >>

Type: C<String>

The IP address(es) of the VM associated with the cryptocurrency mining.
This field may be empty if this information is not available.

=back

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::LeakedCredentialEvent

Information about the leaked client credentials observed on the monitored
resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_account_credential() >> / C<< $msg->service_account_credential($value) >>

Type: C<Message> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ServiceAccountCredential>)

Information about leaked service accounts.

=item * C<< $msg->api_key_credential() >> / C<< $msg->api_key_credential($value) >>

Type: C<Message> (L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ApiKeyCredential>)

Information about leaked API keys.

=item * C<< $msg->detected_uri() >> / C<< $msg->detected_uri($value) >>

Type: C<String>

URI where the client credentials were found.

=back

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::IntrusionAttemptEvent

Information about an intrusion attempt event observed on the monitored
resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vm_resource() >> / C<< $msg->vm_resource($value) >>

Type: C<String>

VM and zone in which the intrusion attempt occurred.

=item * C<< $msg->detected_intrusion_start_time() >> / C<< $msg->detected_intrusion_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Detected start time of the intrusion attempt.

=item * C<< $msg->detected_intrusion_end_time() >> / C<< $msg->detected_intrusion_end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Detected end time of the intrusion attempt.

=item * C<< $msg->vm_ip() >> / C<< $msg->vm_ip($value) >>

Type: C<String>

The IP address(es) of the VM associated with the intrusion attempt.
This field may be empty if this information is not available.

=back

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ServiceAccountCredential

Information about leaked service accounts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Service account whose credentials were leaked.

=item * C<< $msg->key_id() >> / C<< $msg->key_id($value) >>

Type: C<String>

Private Key ID for any leaked keys.

=back

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ApiKeyCredential

Information about leaked API keys.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->api_key() >> / C<< $msg->api_key($value) >>

Type: C<String>

API key that was leaked.

=back

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::HarmfulContentEvent

Information about the phishing/malware URIs associated with the monitored
resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

URIs associated with the phishing/malware finding.

=back

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ReinstatementEvent

Information about the reinstatement issued on the monitored resource.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::DecisionEscalationEvent

Information about the escalation of enforcement action on the monitored
resource. Eg: Used for repeat offenders.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
