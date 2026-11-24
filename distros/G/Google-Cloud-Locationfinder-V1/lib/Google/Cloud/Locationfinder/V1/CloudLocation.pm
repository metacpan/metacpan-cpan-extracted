package Google::Cloud::Locationfinder::V1::CloudLocation;

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
CjNnb29nbGUvY2xvdWQvbG9jYXRpb25maW5kZXIvdjEvY2xvdWRfbG9jYXRpb24ucHJvdG8S
Hmdvb2dsZS5jbG91ZC5sb2NhdGlvbmZpbmRlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byK7CAoNQ2xvdWRMb2NhdGlv
bhIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSdAoZY29udGFpbmluZ19jbG91ZF9sb2NhdGlv
bhgCIAEoCUI44EED+kEyCjBjbG91ZGxvY2F0aW9uZmluZGVyLmdvb2dsZWFwaXMuY29tL0Ns
b3VkTG9jYXRpb25SF2NvbnRhaW5pbmdDbG91ZExvY2F0aW9uEiYKDGRpc3BsYXlfbmFtZRgD
IAEoCUID4EEBUgtkaXNwbGF5TmFtZRJnCg5jbG91ZF9wcm92aWRlchgEIAEoDjI7Lmdvb2ds
ZS5jbG91ZC5sb2NhdGlvbmZpbmRlci52MS5DbG91ZExvY2F0aW9uLkNsb3VkUHJvdmlkZXJC
A+BBAVINY2xvdWRQcm92aWRlchIqCg50ZXJyaXRvcnlfY29kZRgFIAEoCUID4EEBUg10ZXJy
aXRvcnlDb2RlEnQKE2Nsb3VkX2xvY2F0aW9uX3R5cGUYBiABKA4yPy5nb29nbGUuY2xvdWQu
bG9jYXRpb25maW5kZXIudjEuQ2xvdWRMb2NhdGlvbi5DbG91ZExvY2F0aW9uVHlwZUID4EEB
UhFjbG91ZExvY2F0aW9uVHlwZRJLCh1jYXJib25fZnJlZV9lbmVyZ3lfcGVyY2VudGFnZRgH
IAEoAkID4EEBSABSGmNhcmJvbkZyZWVFbmVyZ3lQZXJjZW50YWdliAEBIpEBCg1DbG91ZFBy
b3ZpZGVyEh4KGkNMT1VEX1BST1ZJREVSX1VOU1BFQ0lGSUVEEAASFgoSQ0xPVURfUFJPVklE
RVJfR0NQEAESFgoSQ0xPVURfUFJPVklERVJfQVdTEAISGAoUQ0xPVURfUFJPVklERVJfQVpV
UkUQAxIWChJDTE9VRF9QUk9WSURFUl9PQ0kQBCLDAQoRQ2xvdWRMb2NhdGlvblR5cGUSIwof
Q0xPVURfTE9DQVRJT05fVFlQRV9VTlNQRUNJRklFRBAAEh4KGkNMT1VEX0xPQ0FUSU9OX1RZ
UEVfUkVHSU9OEAESHAoYQ0xPVURfTE9DQVRJT05fVFlQRV9aT05FEAISKAokQ0xPVURfTE9D
QVRJT05fVFlQRV9SRUdJT05fRVhURU5TSU9OEAMSIQodQ0xPVURfTE9DQVRJT05fVFlQRV9H
RENDX1pPTkUQBDqeAepBmgEKMGNsb3VkbG9jYXRpb25maW5kZXIuZ29vZ2xlYXBpcy5jb20v
Q2xvdWRMb2NhdGlvbhJHcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2Nsb3VkTG9jYXRpb25zL3tjbG91ZF9sb2NhdGlvbn0qDmNsb3VkTG9jYXRpb25zMg1jbG91
ZExvY2F0aW9uQiAKHl9jYXJib25fZnJlZV9lbmVyZ3lfcGVyY2VudGFnZSLQAQoZTGlzdENs
b3VkTG9jYXRpb25zUmVxdWVzdBJQCgZwYXJlbnQYASABKAlCOOBBAvpBMhIwY2xvdWRsb2Nh
dGlvbmZpbmRlci5nb29nbGVhcGlzLmNvbS9DbG91ZExvY2F0aW9uUgZwYXJlbnQSIAoJcGFn
ZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJ
cGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIipgEKGkxpc3RDbG91ZExv
Y2F0aW9uc1Jlc3BvbnNlElsKD2Nsb3VkX2xvY2F0aW9ucxgBIAMoCzItLmdvb2dsZS5jbG91
ZC5sb2NhdGlvbmZpbmRlci52MS5DbG91ZExvY2F0aW9uQgPgQQNSDmNsb3VkTG9jYXRpb25z
EisKD25leHRfcGFnZV90b2tlbhgCIAEoCUID4EEDUg1uZXh0UGFnZVRva2VuImcKF0dldENs
b3VkTG9jYXRpb25SZXF1ZXN0EkwKBG5hbWUYASABKAlCOOBBAvpBMgowY2xvdWRsb2NhdGlv
bmZpbmRlci5nb29nbGVhcGlzLmNvbS9DbG91ZExvY2F0aW9uUgRuYW1lIr4CChtTZWFyY2hD
bG91ZExvY2F0aW9uc1JlcXVlc3QSUAoGcGFyZW50GAEgASgJQjjgQQL6QTISMGNsb3VkbG9j
YXRpb25maW5kZXIuZ29vZ2xlYXBpcy5jb20vQ2xvdWRMb2NhdGlvblIGcGFyZW50EmwKFXNv
dXJjZV9jbG91ZF9sb2NhdGlvbhgCIAEoCUI44EEC+kEyCjBjbG91ZGxvY2F0aW9uZmluZGVy
Lmdvb2dsZWFwaXMuY29tL0Nsb3VkTG9jYXRpb25SE3NvdXJjZUNsb3VkTG9jYXRpb24SIAoJ
cGFnZV9zaXplGAMgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YBCABKAlCA+BB
AVIJcGFnZVRva2VuEhkKBXF1ZXJ5GAYgASgJQgPgQQFSBXF1ZXJ5IqgBChxTZWFyY2hDbG91
ZExvY2F0aW9uc1Jlc3BvbnNlElsKD2Nsb3VkX2xvY2F0aW9ucxgBIAMoCzItLmdvb2dsZS5j
bG91ZC5sb2NhdGlvbmZpbmRlci52MS5DbG91ZExvY2F0aW9uQgPgQQNSDmNsb3VkTG9jYXRp
b25zEisKD25leHRfcGFnZV90b2tlbhgCIAEoCUID4EEDUg1uZXh0UGFnZVRva2VuQuwBCiJj
b20uZ29vZ2xlLmNsb3VkLmxvY2F0aW9uZmluZGVyLnYxQhJDbG91ZExvY2F0aW9uUHJvdG9Q
AVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9sb2NhdGlvbmZpbmRlci9hcGl2MS9sb2NhdGlvbmZp
bmRlcnBiO2xvY2F0aW9uZmluZGVycGKqAh5Hb29nbGUuQ2xvdWQuTG9jYXRpb25GaW5kZXIu
VjHKAh5Hb29nbGVcQ2xvdWRcTG9jYXRpb25GaW5kZXJcVjHqAiFHb29nbGU6OkNsb3VkOjpM
b2NhdGlvbkZpbmRlcjo6VjFKikAKBxIFDgDhAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
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
IExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAOwoJ
CgIIJRIDFQA7CggKAQgSAxYAYQoJCgIICxIDFgBhCggKAQgSAxcAIgoJCgIIChIDFwAiCggK
AQgSAxgAMwoJCgIICBIDGAAzCggKAQgSAxkAOwoJCgIIARIDGQA7CggKAQgSAxoAOwoJCgII
KRIDGgA7CggKAQgSAxsAOgoJCgIILRIDGwA6CjIKAgQAEgQeAHQBGiYgUmVwcmVzZW50cyBy
ZXNvdXJjZSBjbG91ZCBsb2NhdGlvbnMuCgoKCgMEAAESAx4IFQoLCgMEAAcSBB8CJAQKDQoF
BAAHnQgSBB8CJAQKawoEBAAEABIEKAI3AxpdIFRoZSB0eXBlIG9mIHRoZSBjbG91ZCBwcm92
aWRlci4gVGhpcyBlbnVtIGxpc3RzIGFsbCBwb3NzaWJsZSBwcm92aWRlcnMgb2YKIGNsb3Vk
IGxvY2F0aW9ucy4KCgwKBQQABAABEgMoBxQKIgoGBAAEAAIAEgMqBCMaEyBVbnNwZWNpZmll
ZCB0eXBlLgoKDgoHBAAEAAIAARIDKgQeCg4KBwQABAACAAISAyohIgo2CgYEAAQAAgESAy0E
GxonIENsb3VkIHByb3ZpZGVyIHR5cGUgZm9yIEdvb2dsZSBDbG91ZC4KCg4KBwQABAACAQES
Ay0EFgoOCgcEAAQAAgECEgMtGRoKLQoGBAAEAAICEgMwBBsaHiBDbG91ZCBwcm92aWRlciB0
eXBlIGZvciBBV1MuCgoOCgcEAAQAAgIBEgMwBBYKDgoHBAAEAAICAhIDMBkaCi8KBgQABAAC
AxIDMwQdGiAgQ2xvdWQgcHJvdmlkZXIgdHlwZSBmb3IgQXp1cmUuCgoOCgcEAAQAAgMBEgMz
BBgKDgoHBAAEAAIDAhIDMxscCi0KBgQABAACBBIDNgQbGh4gQ2xvdWQgcHJvdmlkZXIgdHlw
ZSBmb3IgT0NJLgoKDgoHBAAEAAIEARIDNgQWCg4KBwQABAACBAISAzYZGgpsCgQEAAQBEgQ7
AkoDGl4gVGhlIHR5cGUgb2YgdGhlIGNsb3VkIGxvY2F0aW9uLiBUaGlzIGVudW0gbGlzdHMg
YWxsIHBvc3NpYmxlIGNhdGVnb3JpZXMgb2YKIGNsb3VkIGxvY2F0aW9ucy4KCgwKBQQABAEB
EgM7BxgKIgoGBAAEAQIAEgM9BCgaEyBVbnNwZWNpZmllZCB0eXBlLgoKDgoHBAAEAQIAARID
PQQjCg4KBwQABAECAAISAz0mJwovCgYEAAQBAgESA0AEIxogIENsb3VkTG9jYXRpb24gdHlw
ZSBmb3IgcmVnaW9uLgoKDgoHBAAEAQIBARIDQAQeCg4KBwQABAECAQISA0AhIgotCgYEAAQB
AgISA0MEIRoeIENsb3VkTG9jYXRpb24gdHlwZSBmb3Igem9uZS4KCg4KBwQABAECAgESA0ME
HAoOCgcEAAQBAgICEgNDHyAKOQoGBAAEAQIDEgNGBC0aKiBDbG91ZExvY2F0aW9uIHR5cGUg
Zm9yIHJlZ2lvbiBleHRlbnNpb24uCgoOCgcEAAQBAgMBEgNGBCgKDgoHBAAEAQIDAhIDRiss
ClAKBgQABAECBBIDSQQmGkEgQ2xvdWRMb2NhdGlvbiB0eXBlIGZvciBHb29nbGUgRGlzdHJp
YnV0ZWQgQ2xvdWQgQ29ubmVjdGVkIFpvbmUuCgoOCgcEAAQBAgQBEgNJBCEKDgoHBAAEAQIE
AhIDSSQlCtcBCgQEAAIAEgNPAj0ayQEgSWRlbnRpZmllci4gTmFtZSBvZiB0aGUgY2xvdWQg
bG9jYXRpb24uIFVuaXF1ZSBuYW1lIG9mIHRoZSBjbG91ZCBsb2NhdGlvbgogaW5jbHVkaW5n
IHByb2plY3QgYW5kIGxvY2F0aW9uIHVzaW5nIHRoZSBmb3JtOgogYHByb2plY3RzL3twcm9q
ZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbG91ZExvY2F0aW9ucy97Y2xvdWRfbG9j
YXRpb259YAoKDAoFBAACAAUSA08CCAoMCgUEAAIAARIDTwkNCgwKBQQAAgADEgNPEBEKDAoF
BAACAAgSA08SPAoPCggEAAIACJwIABIDTxM7Cp8BCgQEAAIBEgRTAlgEGpABIE91dHB1dCBv
bmx5LiBUaGUgY29udGFpbmluZyBjbG91ZCBsb2NhdGlvbiBpbiB0aGUgc3RyaWN0IG5lc3Rp
bmcgaGllcmFyY2h5LgogRm9yIGV4YW1wbGUsIHRoZSBjb250YWluaW5nIGNsb3VkIGxvY2F0
aW9uIG9mIGEgem9uZSBpcyBhIHJlZ2lvbi4KCgwKBQQAAgEFEgNTAggKDAoFBAACAQESA1MJ
IgoMCgUEAAIBAxIDUyUmCg0KBQQAAgEIEgRTJ1gDCg8KCAQAAgEInAgAEgNUBC0KDwoHBAAC
AQifCBIEVQRXBQpmCgQEAAICEgNcAkMaWSBPcHRpb25hbC4gVGhlIGh1bWFuLXJlYWRhYmxl
IG5hbWUgb2YgdGhlIGNsb3VkIGxvY2F0aW9uLiBFeGFtcGxlOgogdXMtZWFzdC0yLCB1cy1l
YXN0MS4KCgwKBQQAAgIFEgNcAggKDAoFBAACAgESA1wJFQoMCgUEAAICAxIDXBgZCgwKBQQA
AgIIEgNcGkIKDwoIBAACAgicCAASA1wbQQqqAQoEBAACAxIDYQJMGpwBIE9wdGlvbmFsLiBU
aGUgcHJvdmlkZXIgb2YgdGhlIGNsb3VkIGxvY2F0aW9uLiBWYWx1ZXMgY2FuIGJlIEdvb2ds
ZSBDbG91ZCBvcgogdGhpcmQtcGFydHkgcHJvdmlkZXJzLCBpbmNsdWRpbmcgQVdTLCBBenVy
ZSwgb3IgT3JhY2xlIENsb3VkCiBJbmZyYXN0cnVjdHVyZS4KCgwKBQQAAgMGEgNhAg8KDAoF
BAACAwESA2EQHgoMCgUEAAIDAxIDYSEiCgwKBQQAAgMIEgNhI0sKDwoIBAACAwicCAASA2Ek
SgptCgQEAAIEEgNlAkUaYCBPcHRpb25hbC4gVGhlIHR3by1sZXR0ZXIgSVNPIDMxNjYtMSBh
bHBoYS0yIGNvZGUgb2YgdGhlIGNsb3VkIGxvY2F0aW9uLgogRXhhbXBsZXM6IFVTLCBKUCwg
S1IuCgoMCgUEAAIEBRIDZQIICgwKBQQAAgQBEgNlCRcKDAoFBAACBAMSA2UaGwoMCgUEAAIE
CBIDZRxECg8KCAQAAgQInAgAEgNlHUMKOQoEBAACBRIEaAJpLxorIE9wdGlvbmFsLiBUaGUg
dHlwZSBvZiB0aGUgY2xvdWQgbG9jYXRpb24uCgoMCgUEAAIFBhIDaAITCgwKBQQAAgUBEgNo
FCcKDAoFBAACBQMSA2gqKwoMCgUEAAIFCBIDaQYuCg8KCAQAAgUInAgAEgNpBy0KxgMKBAQA
AgYSBHICcy8atwMgT3B0aW9uYWwuIFRoZSBjYXJib24gZnJlZSBlbmVyZ3kgcGVyY2VudGFn
ZSBvZiB0aGUgY2xvdWQgbG9jYXRpb24uIFRoaXMKIHJlcHJlc2VudHMgdGhlIGF2ZXJhZ2Ug
cGVyY2VudGFnZSBvZiB0aW1lIGN1c3RvbWVycycgYXBwbGljYXRpb24gd2lsbCBiZQogcnVu
bmluZyBvbiBjYXJib24tZnJlZSBlbmVyZ3kuIFNlZQogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL3N1c3RhaW5hYmlsaXR5L3JlZ2lvbi1jYXJib24gZm9yIG1vcmUgZGV0YWlscy4KIFRo
ZXJlIGlzIGEgZGlmZmVyZW5jZSBiZXR3ZWVuIGRlZmF1bHQgdmFsdWUgMCBhbmQgdW5zZXQg
dmFsdWUuIDAgbWVhbnMgdGhlCiBjYXJib24gZnJlZSBlbmVyZ3kgcGVyY2VudGFnZSBpcyAw
JSwgd2hpbGUgdW5zZXQgdmFsdWUgbWVhbnMgdGhlIGNhcmJvbgogZm9vdHByaW50IGRhdGEg
aXMgbm90IGF2YWlsYWJsZS4KCgwKBQQAAgYEEgNyAgoKDAoFBAACBgUSA3ILEAoMCgUEAAIG
ARIDchEuCgwKBQQAAgYDEgNyMTIKDAoFBAACBggSA3MGLgoPCggEAAIGCJwIABIDcwctCj8K
AgQBEgV3AJUBARoyIE1lc3NhZ2UgZm9yIHJlcXVlc3RpbmcgbGlzdCBvZiBjbG91ZCBsb2Nh
dGlvbnMuLgoKCgoDBAEBEgN3CCEKhQEKBAQBAgASBHoCfwQadyBSZXF1aXJlZC4gVGhlIHBh
cmVudCwgd2hpY2ggb3ducyB0aGlzIGNvbGxlY3Rpb24gb2YgY2xvdWQgbG9jYXRpb25zLgog
Rm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCgwKBQQB
AgAFEgN6AggKDAoFBAECAAESA3oJDwoMCgUEAQIAAxIDehITCg0KBQQBAgAIEgR6FH8DCg8K
CAQBAgAInAgAEgN7BCoKDwoHBAECAAifCBIEfAR+BQrPAQoEBAECARIEhAECPxrAASBPcHRp
b25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGNsb3VkIGxvY2F0aW9ucyB0byByZXR1cm4g
cGVyIHBhZ2UuIFRoZQogc2VydmljZSBtaWdodCByZXR1cm4gZmV3ZXIgY2xvdWQgbG9jYXRp
b25zIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVjaWZpZWQsCiBzZXJ2ZXIgd2lsbCBwaWNr
IGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoNCgUEAQIBBRIEhAECBwoNCgUEAQIBARIEhAEI
EQoNCgUEAQIBAxIEhAEUFQoNCgUEAQIBCBIEhAEWPgoQCggEAQIBCJwIABIEhAEXPQrBAgoE
BAECAhIEiwECQRqyAiBPcHRpb25hbC4gQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2Yg
cmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4uCiBQcm92aWRlIHBhZ2UgdG9rZW4g
cmV0dXJuZWQgYnkgYSBwcmV2aW91cyAnTGlzdENsb3VkTG9jYXRpb25zJyBjYWxsIHRvCiBy
ZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMuIFdoZW4gcGFnaW5hdGluZywgYWxs
IG90aGVyIHBhcmFtZXRlcnMKIHByb3ZpZGVkIHRvICdMaXN0Q2xvdWRMb2NhdGlvbnMnIG11
c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZQogdG9rZW4uCgoNCgUE
AQICBRIEiwECCAoNCgUEAQICARIEiwEJEwoNCgUEAQICAxIEiwEWFwoNCgUEAQICCBIEiwEY
QAoQCggEAQICCJwIABIEiwEZPwq9AwoEBAECAxIElAECPRquAyBPcHRpb25hbC4gQSBmaWx0
ZXIgZXhwcmVzc2lvbiB0aGF0IGZpbHRlcnMgcmVzb3VyY2VzIGxpc3RlZCBpbiB0aGUKIHJl
c3BvbnNlLiBUaGUgZXhwcmVzc2lvbiBpcyBpbiB0aGUgZm9ybSBvZiBmaWVsZD12YWx1ZS4g
Rm9yIGV4YW1wbGUsCiAnY2xvdWRfbG9jYXRpb25fdHlwZT1DTE9VRF9MT0NBVElPTl9UWVBF
X1JFR0lPTicuIE11bHRpcGxlIGZpbHRlciBxdWVyaWVzCiBhcmUgc3BhY2Utc2VwYXJhdGVk
LiBGb3IgZXhhbXBsZSwKICdjbG91ZF9sb2NhdGlvbl90eXBlPUNMT1VEX0xPQ0FUSU9OX1RZ
UEVfUkVHSU9OIHRlcnJpdG9yeV9jb2RlPSJVUyInIEJ5CiBkZWZhdWx0LCBlYWNoIGV4cHJl
c3Npb24gaXMgYW4gQU5EIGV4cHJlc3Npb24uIEhvd2V2ZXIsIHlvdSBjYW4gaW5jbHVkZSBB
TkQKIGFuZCBPUiBleHByZXNzaW9ucyBleHBsaWNpdGx5LgoKDQoFBAECAwUSBJQBAggKDQoF
BAECAwESBJQBCQ8KDQoFBAECAwMSBJQBEhMKDQoFBAECAwgSBJQBFDwKEAoIBAECAwicCAAS
BJQBFTsKQAoCBAISBpgBAKIBARoyIE1lc3NhZ2UgZm9yIHJlc3BvbnNlIHRvIGxpc3Rpbmcg
Y2xvdWQgbG9jYXRpb25zLgoKCwoDBAIBEgSYAQgiCjcKBAQCAgASBpoBApsBMhonIE91dHB1
dCBvbmx5LiBMaXN0IG9mIGNsb3VkIGxvY2F0aW9ucy4KCg0KBQQCAgAEEgSaAQIKCg0KBQQC
AgAGEgSaAQsYCg0KBQQCAgABEgSaARkoCg0KBQQCAgADEgSaASssCg0KBQQCAgAIEgSbAQYx
ChAKCAQCAgAInAgAEgSbAQcwCooCCgQEAgIBEgShAQJJGvsBIE91dHB1dCBvbmx5LiBUaGUg
Y29udGludWF0aW9uIHRva2VuLCB1c2VkIHRvIHBhZ2UgdGhyb3VnaCBsYXJnZSByZXN1bHQK
IHNldHMuIFByb3ZpZGUgdGhpcyB2YWx1ZSBpbiBhIHN1YnNlcXVlbnQgcmVxdWVzdCBhcyBw
YWdlX3Rva2VuIGluCiBzdWJzZXF1ZW50IHJlcXVlc3RzIHRvIHJldHJpZXZlIHRoZSBuZXh0
IHBhZ2UuIElmIHRoaXMgZmllbGQgaXMgbm90CiBwcmVzZW50LCB0aGVyZSBhcmUgbm8gc3Vi
c2VxdWVudCByZXN1bHRzLgoKDQoFBAICAQUSBKEBAggKDQoFBAICAQESBKEBCRgKDQoFBAIC
AQMSBKEBGxwKDQoFBAICAQgSBKEBHUgKEAoIBAICAQicCAASBKEBHkcKNQoCBAMSBqUBAK0B
ARonIE1lc3NhZ2UgZm9yIGdldHRpbmcgYSBjbG91ZCBsb2NhdGlvbi4KCgsKAwQDARIEpQEI
HwoxCgQEAwIAEganAQKsAQQaISBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoN
CgUEAwIABRIEpwECCAoNCgUEAwIAARIEpwEJDQoNCgUEAwIAAxIEpwEQEQoPCgUEAwIACBIG
pwESrAEDChAKCAQDAgAInAgAEgSoAQQqChEKBwQDAgAInwgSBqkBBKsBBQpTCgIEBBIGsAEA
1AEBGkUgTWVzc2FnZSBmb3Igc2VhcmNoaW5nIGNsb3VkIGxvY2F0aW9ucyBmcm9tIGEgZ2l2
ZW4gc291cmNlIGxvY2F0aW9uLgoKCwoDBAQBEgSwAQgjCocBCgQEBAIAEgazAQK4AQQadyBS
ZXF1aXJlZC4gVGhlIHBhcmVudCwgd2hpY2ggb3ducyB0aGlzIGNvbGxlY3Rpb24gb2YgY2xv
dWQgbG9jYXRpb25zLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0KCg0KBQQEAgAFEgSzAQIICg0KBQQEAgABEgSzAQkPCg0KBQQEAgADEgSzARIT
Cg8KBQQEAgAIEgazARS4AQMKEAoIBAQCAAicCAASBLQBBCoKEQoHBAQCAAifCBIGtQEEtwEF
CqoBCgQEBAIBEga9AQLCAQQamQEgUmVxdWlyZWQuIFRoZSBzb3VyY2UgY2xvdWQgbG9jYXRp
b24gdG8gc2VhcmNoIGZyb20uCiBFeGFtcGxlIHNlYXJjaCBjYW4gYmUgc2VhcmNoaW5nIG5l
YXJieSBjbG91ZCBsb2NhdGlvbnMgZnJvbSB0aGUgc291cmNlCiBjbG91ZCBsb2NhdGlvbiBi
eSBsYXRlbmN5LgoKDQoFBAQCAQUSBL0BAggKDQoFBAQCAQESBL0BCR4KDQoFBAQCAQMSBL0B
ISIKDwoFBAQCAQgSBr0BI8IBAwoQCggEBAIBCJwIABIEvgEEKgoRCgcEBAIBCJ8IEga/AQTB
AQUKxgEKBAQEAgISBMcBAj8atwEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBj
bG91ZCBsb2NhdGlvbnMgdG8gcmV0dXJuLiBUaGUgc2VydmljZQogbWlnaHQgcmV0dXJuIGZl
d2VyIGNsb3VkIGxvY2F0aW9ucyB0aGFuIHRoaXMgdmFsdWUuIElmIHVuc3BlY2lmaWVkLCBz
ZXJ2ZXIKIHdpbGwgcGljayBhbiBhcHByb3ByaWF0ZSBkZWZhdWx0LgoKDQoFBAQCAgUSBMcB
AgcKDQoFBAQCAgESBMcBCBEKDQoFBAQCAgMSBMcBFBUKDQoFBAQCAggSBMcBFj4KEAoIBAQC
AgicCAASBMcBFz0KwQIKBAQEAgMSBM4BAkEasgIgT3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRp
ZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgogUHJv
dmlkZSBQYWdlIHRva2VuIHJldHVybmVkIGJ5IGEgcHJldmlvdXMgJ0xpc3RDbG91ZExvY2F0
aW9ucycgY2FsbCB0bwogcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLiBXaGVu
IHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzCiBwcm92aWRlZCB0byAnTGlzdENs
b3VkTG9jYXRpb25zJyBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBh
Z2UKIHRva2VuLgoKDQoFBAQCAwUSBM4BAggKDQoFBAQCAwESBM4BCRMKDQoFBAQCAwMSBM4B
FhcKDQoFBAQCAwgSBM4BGEAKEAoIBAQCAwicCAASBM4BGT8KuAEKBAQEAgQSBNMBAjwaqQEg
T3B0aW9uYWwuIFRoZSBxdWVyeSBzdHJpbmcgaW4gc2VhcmNoIHF1ZXJ5IHN5bnRheC4gV2hp
bGUgZmlsdGVyIGlzIHVzZWQgdG8KIGZpbHRlciB0aGUgc2VhcmNoIHJlc3VsdHMgYnkgYXR0
cmlidXRlcywgcXVlcnkgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZQogc2VhcmNoIHJlcXVpcmVt
ZW50cy4KCg0KBQQEAgQFEgTTAQIICg0KBQQEAgQBEgTTAQkOCg0KBQQEAgQDEgTTARESCg0K
BQQEAgQIEgTTARM7ChAKCAQEAgQInAgAEgTTARQ6CkIKAgQFEgbXAQDhAQEaNCBNZXNzYWdl
IGZvciByZXNwb25zZSB0byBzZWFyY2hpbmcgY2xvdWQgbG9jYXRpb25zLgoKCwoDBAUBEgTX
AQgkCjcKBAQFAgASBtkBAtoBMhonIE91dHB1dCBvbmx5LiBMaXN0IG9mIGNsb3VkIGxvY2F0
aW9ucy4KCg0KBQQFAgAEEgTZAQIKCg0KBQQFAgAGEgTZAQsYCg0KBQQFAgABEgTZARkoCg0K
BQQFAgADEgTZASssCg0KBQQFAgAIEgTaAQYxChAKCAQFAgAInAgAEgTaAQcwCooCCgQEBQIB
EgTgAQJJGvsBIE91dHB1dCBvbmx5LiBUaGUgY29udGludWF0aW9uIHRva2VuLCB1c2VkIHRv
IHBhZ2UgdGhyb3VnaCBsYXJnZSByZXN1bHQKIHNldHMuIFByb3ZpZGUgdGhpcyB2YWx1ZSBp
biBhIHN1YnNlcXVlbnQgcmVxdWVzdCBhcyBwYWdlX3Rva2VuIGluCiBzdWJzZXF1ZW50IHJl
cXVlc3RzIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuIElmIHRoaXMgZmllbGQgaXMgbm90
CiBwcmVzZW50LCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCByZXN1bHRzLgoKDQoFBAUCAQUS
BOABAggKDQoFBAUCAQESBOABCRgKDQoFBAUCAQMSBOABGxwKDQoFBAUCAQgSBOABHUgKEAoI
BAUCAQicCAASBOABHkdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation ===
    # Fields for CloudLocation
    # Field: name Type: 9 ()
    # Field: containing_cloud_location Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: cloud_provider Type: 14 (.google.cloud.locationfinder.v1.CloudLocation.CloudProvider)
    # Field: territory_code Type: 9 ()
    # Field: cloud_location_type Type: 14 (.google.cloud.locationfinder.v1.CloudLocation.CloudLocationType)
    # Field: carbon_free_energy_percentage Type: 2 ()

# Enum: CloudLocation::CloudProvider
our $CloudLocation_CLOUD_PROVIDER_UNSPECIFIED = 0;
our $CloudLocation_CLOUD_PROVIDER_GCP = 1;
our $CloudLocation_CLOUD_PROVIDER_AWS = 2;
our $CloudLocation_CLOUD_PROVIDER_AZURE = 3;
our $CloudLocation_CLOUD_PROVIDER_OCI = 4;

# Enum: CloudLocation::CloudLocationType
our $CloudLocation_CLOUD_LOCATION_TYPE_UNSPECIFIED = 0;
our $CloudLocation_CLOUD_LOCATION_TYPE_REGION = 1;
our $CloudLocation_CLOUD_LOCATION_TYPE_ZONE = 2;
our $CloudLocation_CLOUD_LOCATION_TYPE_REGION_EXTENSION = 3;
our $CloudLocation_CLOUD_LOCATION_TYPE_GDCC_ZONE = 4;

# === Message: Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsRequest ===
    # Fields for ListCloudLocationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsResponse ===
    # Fields for ListCloudLocationsResponse
    # Field: cloud_locations Type: 11 (.google.cloud.locationfinder.v1.CloudLocation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Locationfinder::V1::CloudLocation::GetCloudLocationRequest ===
    # Fields for GetCloudLocationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsRequest ===
    # Fields for SearchCloudLocationsRequest
    # Field: parent Type: 9 ()
    # Field: source_cloud_location Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: query Type: 9 ()

# === Message: Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsResponse ===
    # Fields for SearchCloudLocationsResponse
    # Field: cloud_locations Type: 11 (.google.cloud.locationfinder.v1.CloudLocation)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Locationfinder::V1::CloudLocation - Compiled Protocol Buffers messages for google/cloud/locationfinder/v1/cloud_location.proto

=head1 SYNOPSIS

    use Google::Cloud::Locationfinder::V1::CloudLocation;

    my $msg = Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation->new({
        name => $name,
        containing_cloud_location => $containing_cloud_location,
        display_name => $display_name,
        cloud_provider => $cloud_provider,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/locationfinder/v1/cloud_location.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation

Represents resource cloud locations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the cloud location. Unique name of the cloud location
including project and location using the form:
`projects/{project_id}/locations/{location}/cloudLocations/{cloud_location}`

=item * C<< $msg->containing_cloud_location() >> / C<< $msg->containing_cloud_location($value) >>

Type: C<String>

Output only. The containing cloud location in the strict nesting hierarchy.
For example, the containing cloud location of a zone is a region.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The human-readable name of the cloud location. Example:
us-east-2, us-east1.

=item * C<< $msg->cloud_provider() >> / C<< $msg->cloud_provider($value) >>

Type: C<Enum> (L<Google::Cloud::Locationfinder::V1::CloudLocation::CloudProvider>)

Optional. The provider of the cloud location. Values can be Google Cloud or
third-party providers, including AWS, Azure, or Oracle Cloud
Infrastructure.

=item * C<< $msg->territory_code() >> / C<< $msg->territory_code($value) >>

Type: C<String>

Optional. The two-letter ISO 3166-1 alpha-2 code of the cloud location.
Examples: US, JP, KR.

=item * C<< $msg->cloud_location_type() >> / C<< $msg->cloud_location_type($value) >>

Type: C<Enum> (L<Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocationType>)

Optional. The type of the cloud location.

=item * C<< $msg->carbon_free_energy_percentage() >> / C<< $msg->carbon_free_energy_percentage($value) >>

Type: C<Float>

Optional. The carbon free energy percentage of the cloud location. This
represents the average percentage of time customers' application will be
running on carbon-free energy. See
https://cloud.google.com/sustainability/region-carbon for more details.
There is a difference between default value 0 and unset value. 0 means the
carbon free energy percentage is 0%, while unset value means the carbon
footprint data is not available.

=back

=head3 Enum: CloudLocation::CloudProvider

=over 4

=item * C<CLOUD_PROVIDER_UNSPECIFIED> => C<0>

=item * C<CLOUD_PROVIDER_GCP> => C<1>

=item * C<CLOUD_PROVIDER_AWS> => C<2>

=item * C<CLOUD_PROVIDER_AZURE> => C<3>

=item * C<CLOUD_PROVIDER_OCI> => C<4>

=back

=head3 Enum: CloudLocation::CloudLocationType

=over 4

=item * C<CLOUD_LOCATION_TYPE_UNSPECIFIED> => C<0>

=item * C<CLOUD_LOCATION_TYPE_REGION> => C<1>

=item * C<CLOUD_LOCATION_TYPE_ZONE> => C<2>

=item * C<CLOUD_LOCATION_TYPE_REGION_EXTENSION> => C<3>

=item * C<CLOUD_LOCATION_TYPE_GDCC_ZONE> => C<4>

=back

=head2 Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsRequest

Message for requesting list of cloud locations..

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of cloud locations.
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of cloud locations to return per page. The
service might return fewer cloud locations than this value. If unspecified,
server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.
Provide page token returned by a previous 'ListCloudLocations' call to
retrieve the next page of results. When paginating, all other parameters
provided to 'ListCloudLocations' must match the call that provided the page
token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters resources listed in the
response. The expression is in the form of field=value. For example,
'cloud_location_type=CLOUD_LOCATION_TYPE_REGION'. Multiple filter queries
are space-separated. For example,
'cloud_location_type=CLOUD_LOCATION_TYPE_REGION territory_code="US"' By
default, each expression is an AND expression. However, you can include AND
and OR expressions explicitly.

=back

=head2 Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsResponse

Message for response to listing cloud locations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_locations() >> / C<< $msg->cloud_locations($value) >>

Type: C<Message> (L<Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation>)

Output only. List of cloud locations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Output only. The continuation token, used to page through large result
sets. Provide this value in a subsequent request as page_token in
subsequent requests to retrieve the next page. If this field is not
present, there are no subsequent results.

=back

=head2 Google::Cloud::Locationfinder::V1::CloudLocation::GetCloudLocationRequest

Message for getting a cloud location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsRequest

Message for searching cloud locations from a given source location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of cloud locations.
Format: projects/{project}/locations/{location}

=item * C<< $msg->source_cloud_location() >> / C<< $msg->source_cloud_location($value) >>

Type: C<String>

Required. The source cloud location to search from.
Example search can be searching nearby cloud locations from the source
cloud location by latency.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of cloud locations to return. The service
might return fewer cloud locations than this value. If unspecified, server
will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.
Provide Page token returned by a previous 'ListCloudLocations' call to
retrieve the next page of results. When paginating, all other parameters
provided to 'ListCloudLocations' must match the call that provided the page
token.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Optional. The query string in search query syntax. While filter is used to
filter the search results by attributes, query is used to specify the
search requirements.

=back

=head2 Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsResponse

Message for response to searching cloud locations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_locations() >> / C<< $msg->cloud_locations($value) >>

Type: C<Message> (L<Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation>)

Output only. List of cloud locations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Output only. The continuation token, used to page through large result
sets. Provide this value in a subsequent request as page_token in
subsequent requests to retrieve the next page. If this field is not
present, there are no subsequent results.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Locationfinder::V1::CloudLocation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
