package Google::Cloud::Retail::V2::ExportConfig;

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
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2V4cG9ydF9jb25maWcucHJvdG8SFmdvb2dsZS5j
bG91ZC5yZXRhaWwudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8a
F2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvIrwDCgxPdXRwdXRDb25maWcSXgoPZ2NzX2Rlc3Rp
bmF0aW9uGAEgASgLMjMuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5PdXRwdXRDb25maWcuR2Nz
RGVzdGluYXRpb25IAFIOZ2NzRGVzdGluYXRpb24SbQoUYmlncXVlcnlfZGVzdGluYXRpb24Y
AiABKAsyOC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLk91dHB1dENvbmZpZy5CaWdRdWVyeURl
c3RpbmF0aW9uSABSE2JpZ3F1ZXJ5RGVzdGluYXRpb24aQQoOR2NzRGVzdGluYXRpb24SLwoR
b3V0cHV0X3VyaV9wcmVmaXgYASABKAlCA+BBAlIPb3V0cHV0VXJpUHJlZml4GooBChNCaWdR
dWVyeURlc3RpbmF0aW9uEiIKCmRhdGFzZXRfaWQYASABKAlCA+BBAlIJZGF0YXNldElkEisK
D3RhYmxlX2lkX3ByZWZpeBgCIAEoCUID4EECUg10YWJsZUlkUHJlZml4EiIKCnRhYmxlX3R5
cGUYAyABKAlCA+BBAlIJdGFibGVUeXBlQg0KC2Rlc3RpbmF0aW9uIkQKEkV4cG9ydEVycm9y
c0NvbmZpZxIfCgpnY3NfcHJlZml4GAEgASgJSABSCWdjc1ByZWZpeEINCgtkZXN0aW5hdGlv
biKmAQodRXhwb3J0QW5hbHl0aWNzTWV0cmljc1JlcXVlc3QSHQoHY2F0YWxvZxgBIAEoCUID
4EECUgdjYXRhbG9nEk4KDW91dHB1dF9jb25maWcYAiABKAsyJC5nb29nbGUuY2xvdWQucmV0
YWlsLnYyLk91dHB1dENvbmZpZ0ID4EECUgxvdXRwdXRDb25maWcSFgoGZmlsdGVyGAMgASgJ
UgZmaWx0ZXIiigEKDkV4cG9ydE1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUi9QEKHkV4cG9ydEFu
YWx5dGljc01ldHJpY3NSZXNwb25zZRI3Cg1lcnJvcl9zYW1wbGVzGAEgAygLMhIuZ29vZ2xl
LnJwYy5TdGF0dXNSDGVycm9yU2FtcGxlcxJPCg1lcnJvcnNfY29uZmlnGAIgASgLMiouZ29v
Z2xlLmNsb3VkLnJldGFpbC52Mi5FeHBvcnRFcnJvcnNDb25maWdSDGVycm9yc0NvbmZpZxJJ
Cg1vdXRwdXRfcmVzdWx0GAMgASgLMiQuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5PdXRwdXRS
ZXN1bHRSDG91dHB1dFJlc3VsdCKtAQoMT3V0cHV0UmVzdWx0ElUKD2JpZ3F1ZXJ5X3Jlc3Vs
dBgBIAMoCzIsLmdvb2dsZS5jbG91ZC5yZXRhaWwudjIuQmlnUXVlcnlPdXRwdXRSZXN1bHRS
DmJpZ3F1ZXJ5UmVzdWx0EkYKCmdjc19yZXN1bHQYAiADKAsyJy5nb29nbGUuY2xvdWQucmV0
YWlsLnYyLkdjc091dHB1dFJlc3VsdFIJZ2NzUmVzdWx0IlAKFEJpZ1F1ZXJ5T3V0cHV0UmVz
dWx0Eh0KCmRhdGFzZXRfaWQYASABKAlSCWRhdGFzZXRJZBIZCgh0YWJsZV9pZBgCIAEoCVIH
dGFibGVJZCIwCg9HY3NPdXRwdXRSZXN1bHQSHQoKb3V0cHV0X3VyaRgBIAEoCVIJb3V0cHV0
VXJpQrwBChpjb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MkIRRXhwb3J0Q29uZmlnUHJvdG9Q
AVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjIvcmV0YWlscGI7cmV0YWlscGKi
AgZSRVRBSUyqAhZHb29nbGUuQ2xvdWQuUmV0YWlsLlYyygIWR29vZ2xlXENsb3VkXFJldGFp
bFxWMuoCGUdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJKmi0KBxIFDgCgAQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoJCgIDARID
EwAjCgkKAgMCEgMUACkKCQoCAwMSAxUAIQoICgEIEgMXADMKCQoCCCUSAxcAMwoICgEIEgMY
AEkKCQoCCAsSAxgASQoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADIKCQoCCAgSAxoA
MgoICgEIEgMbADMKCQoCCAESAxsAMwoICgEIEgMcACQKCQoCCCQSAxwAJAoICgEIEgMdADMK
CQoCCCkSAx0AMwoICgEIEgMeADIKCQoCCC0SAx4AMgovCgIEABIEIQBFARojIFRoZSBvdXRw
dXQgY29uZmlndXJhdGlvbiBzZXR0aW5nLgoKCgoDBAABEgMhCBQKSgoEBAADABIEIwIsAxo8
IFRoZSBHb29nbGUgQ2xvdWQgU3RvcmFnZSBvdXRwdXQgZGVzdGluYXRpb24gY29uZmlndXJh
dGlvbi4KCgwKBQQAAwABEgMjChgKtAMKBgQAAwACABIDKwRKGqQDIFJlcXVpcmVkLiBUaGUg
b3V0cHV0IHVyaSBwcmVmaXggZm9yIHNhdmluZyBvdXRwdXQgZGF0YSB0byBqc29uIGZpbGVz
LgogU29tZSBtYXBwaW5nIGV4YW1wbGVzIGFyZSBhcyBmb2xsb3dzOgogb3V0cHV0X3VyaV9w
cmVmaXggICAgICAgICBzYW1wbGUgb3V0cHV0KGFzc3VtaW5nIHRoZSBvYmplY3QgaXMgZm9v
Lmpzb24pCiA9PT09PT09PT09PT09PT09PT09PT09PT0gID09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT09PT09PQogZ3M6Ly9idWNrZXQvICAgICAgICAgICAgICBn
czovL2J1Y2tldC9mb28uanNvbgogZ3M6Ly9idWNrZXQvZm9sZGVyLyAgICAgICBnczovL2J1
Y2tldC9mb2xkZXIvZm9vLmpzb24KIGdzOi8vYnVja2V0L2ZvbGRlci9pdGVtXyAgZ3M6Ly9i
dWNrZXQvZm9sZGVyL2l0ZW1fZm9vLmpzb24KCg4KBwQAAwACAAUSAysECgoOCgcEAAMAAgAB
EgMrCxwKDgoHBAADAAIAAxIDKx8gCg4KBwQAAwACAAgSAyshSQoRCgoEAAMAAgAInAgAEgMr
IkgKPgoEBAADARIELwI7AxowIFRoZSBCaWdRdWVyeSBvdXRwdXQgZGVzdGluYXRpb24gY29u
ZmlndXJhdGlvbi4KCgwKBQQAAwEBEgMvCh0KOAoGBAADAQIAEgMxBEMaKSBSZXF1aXJlZC4g
VGhlIElEIG9mIGEgQmlnUXVlcnkgRGF0YXNldC4KCg4KBwQAAwECAAUSAzEECgoOCgcEAAMB
AgABEgMxCxUKDgoHBAADAQIAAxIDMRgZCg4KBwQAAwECAAgSAzEaQgoRCgoEAAMBAgAInAgA
EgMxG0EKQgoGBAADAQIBEgM0BEgaMyBSZXF1aXJlZC4gVGhlIHByZWZpeCBvZiBleHBvcnRl
ZCBCaWdRdWVyeSB0YWJsZXMuCgoOCgcEAAMBAgEFEgM0BAoKDgoHBAADAQIBARIDNAsaCg4K
BwQAAwECAQMSAzQdHgoOCgcEAAMBAgEIEgM0H0cKEQoKBAADAQIBCJwIABIDNCBGCrIBCgYE
AAMBAgISAzoEQxqiASBSZXF1aXJlZC4gRGVzY3JpYmVzIHRoZSB0YWJsZSB0eXBlLiBUaGUg
Zm9sbG93aW5nIHZhbHVlcyBhcmUgc3VwcG9ydGVkOgoKICogYHRhYmxlYDogQSBCaWdRdWVy
eSBuYXRpdmUgdGFibGUuCiAqIGB2aWV3YDogQSB2aXJ0dWFsIHRhYmxlIGRlZmluZWQgYnkg
YSBTUUwgcXVlcnkuCgoOCgcEAAMBAgIFEgM6BAoKDgoHBAADAQICARIDOgsVCg4KBwQAAwEC
AgMSAzoYGQoOCgcEAAMBAgIIEgM6GkIKEQoKBAADAQICCJwIABIDOhtBCkkKBAQACAASBD4C
RAMaOyBUaGUgY29uZmlndXJhdGlvbiBvZiBkZXN0aW5hdGlvbiBmb3IgaG9sZGluZyBvdXRw
dXQgZGF0YS4KCgwKBQQACAABEgM+CBMKVgoEBAACABIDQAQnGkkgVGhlIEdvb2dsZSBDbG91
ZCBTdG9yYWdlIGxvY2F0aW9uIHdoZXJlIHRoZSBvdXRwdXQgaXMgdG8gYmUgd3JpdHRlbiB0
by4KCgwKBQQAAgAGEgNABBIKDAoFBAACAAESA0ATIgoMCgUEAAIAAxIDQCUmCkoKBAQAAgES
A0MEMRo9IFRoZSBCaWdRdWVyeSBsb2NhdGlvbiB3aGVyZSB0aGUgb3V0cHV0IGlzIHRvIGJl
IHdyaXR0ZW4gdG8uCgoMCgUEAAIBBhIDQwQXCgwKBQQAAgEBEgNDGCwKDAoFBAACAQMSA0Mv
MApFCgIEARIESABRARo5IENvbmZpZ3VyYXRpb24gb2YgZGVzdGluYXRpb24gZm9yIEV4cG9y
dCByZWxhdGVkIGVycm9ycy4KCgoKAwQBARIDSAgaCi0KBAQBCAASBEoCUAMaHyBSZXF1aXJl
ZC4gRXJyb3JzIGRlc3RpbmF0aW9uLgoKDAoFBAEIAAESA0oIEwrqAQoEBAECABIDTwQaGtwB
IEdvb2dsZSBDbG91ZCBTdG9yYWdlIHBhdGggZm9yIGltcG9ydCBlcnJvcnMuIFRoaXMgbXVz
dCBiZSBhbiBlbXB0eSwKIGV4aXN0aW5nIENsb3VkIFN0b3JhZ2UgYnVja2V0LiBFeHBvcnQg
ZXJyb3JzIHdpbGwgYmUgd3JpdHRlbiB0byBhIGZpbGUgaW4KIHRoaXMgYnVja2V0LCBvbmUg
cGVyIGxpbmUsIGFzIGEgSlNPTi1lbmNvZGVkCiBgZ29vZ2xlLnJwYy5TdGF0dXNgIG1lc3Nh
Z2UuCgoMCgUEAQIABRIDTwQKCgwKBQQBAgABEgNPCxUKDAoFBAECAAMSA08YGQpGCgIEAhIE
VABuARo6IFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIGBFeHBvcnRBbmFseXRpY3NNZXRyaWNz
YCBtZXRob2QuCgoKCgMEAgESA1QIJQp4CgQEAgIAEgNXAj4aayBSZXF1aXJlZC4gRnVsbCBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBwYXJlbnQgY2F0YWxvZy4KIEV4cGVjdGVkIGZvcm1hdDog
YHByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKmAKCgwKBQQCAgAFEgNXAggKDAoF
BAICAAESA1cJEAoMCgUEAgIAAxIDVxMUCgwKBQQCAgAIEgNXFT0KDwoIBAICAAicCAASA1cW
PAo5CgQEAgIBEgNaAkoaLCBSZXF1aXJlZC4gVGhlIG91dHB1dCBsb2NhdGlvbiBvZiB0aGUg
ZGF0YS4KCgwKBQQCAgEGEgNaAg4KDAoFBAICAQESA1oPHAoMCgUEAgIBAxIDWh8gCgwKBQQC
AgEIEgNaIUkKDwoIBAICAQicCAASA1oiSAriBQoEBAICAhIDbQIUGtQFIEEgZmlsdGVyaW5n
IGV4cHJlc3Npb24gdG8gc3BlY2lmeSByZXN0cmljdGlvbnMgb24gcmV0dXJuZWQgbWV0cmlj
cy4KIFRoZSBleHByZXNzaW9uIGlzIGEgc2VxdWVuY2Ugb2YgdGVybXMuIEVhY2ggdGVybSBh
cHBsaWVzIGEgcmVzdHJpY3Rpb24gdG8KIHRoZSByZXR1cm5lZCBtZXRyaWNzLiBVc2UgdGhp
cyBleHByZXNzaW9uIHRvIHJlc3RyaWN0IHJlc3VsdHMgdG8gYQogc3BlY2lmaWMgdGltZSBy
YW5nZS4KCiAgIEN1cnJlbnRseSB3ZSBleHBlY3Qgb25seSBvbmUgdHlwZXMgb2YgZmllbGRz
OgoKICAgICogYHRpbWVzdGFtcGA6IFRoaXMgY2FuIGJlIHNwZWNpZmllZCB0d2ljZSwgb25j
ZSB3aXRoIGEKICAgICAgbGVzcyB0aGFuIG9wZXJhdG9yIGFuZCBvbmNlIHdpdGggYSBncmVh
dGVyIHRoYW4gb3BlcmF0b3IuIFRoZQogICAgICBgdGltZXN0YW1wYCByZXN0cmljdGlvbiBz
aG91bGQgcmVzdWx0IGluIG9uZSwgY29udGlndW91cywgdmFsaWQsCiAgICAgIGB0aW1lc3Rh
bXBgIHJhbmdlLgoKICAgU29tZSBleGFtcGxlcyBvZiB2YWxpZCBmaWx0ZXJzIGV4cHJlc3Np
b25zOgoKICAgKiBFeGFtcGxlIDE6IGB0aW1lc3RhbXAgPiAiMjAxMi0wNC0yM1QxODoyNTo0
My41MTFaIgogICAgICAgICAgICAgdGltZXN0YW1wIDwgIjIwMTItMDQtMjNUMTg6MzA6NDMu
NTExWiJgCiAgICogRXhhbXBsZSAyOiBgdGltZXN0YW1wID4gIjIwMTItMDQtMjNUMTg6MjU6
NDMuNTExWiJgCgoMCgUEAgICBRIDbQIICgwKBQQCAgIBEgNtCQ8KDAoFBAICAgMSA20SEwqO
AQoCBAMSBHIAeQEagQEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhl
IEV4cG9ydCBvcGVyYXRpb24uIFRoaXMgaXMKIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRhIGZpZWxkLgoKCgoDBAMBEgNyCBYKJQoEBAMC
ABIDdAIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDAoFBAMCAAYSA3QCGwoMCgUEAwIA
ARIDdBwnCgwKBQQDAgADEgN0KisKYwoEBAMCARIDeAIsGlYgT3BlcmF0aW9uIGxhc3QgdXBk
YXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQog
ZmluaXNoIHRpbWUuCgoMCgUEAwIBBhIDeAIbCgwKBQQDAgEBEgN4HCcKDAoFBAMCAQMSA3gq
KwrhAQoCBAQSBX4AhwEBGtMBIFJlc3BvbnNlIG9mIHRoZSBFeHBvcnRBbmFseXRpY3NNZXRy
aWNzUmVxdWVzdC4gSWYgdGhlIGxvbmcgcnVubmluZwogb3BlcmF0aW9uIHdhcyBzdWNjZXNz
ZnVsLCB0aGVuIHRoaXMgbWVzc2FnZSBpcyByZXR1cm5lZCBieSB0aGUKIGdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb25zLnJlc3BvbnNlIGZpZWxkIGlmIHRoZSBvcGVyYXRpb24gd2Fz
IHN1Y2Nlc3NmdWwuCgoKCgMEBAESA34IJgpMCgQEBAIAEgSAAQIvGj4gQSBzYW1wbGUgb2Yg
ZXJyb3JzIGVuY291bnRlcmVkIHdoaWxlIHByb2Nlc3NpbmcgdGhlIHJlcXVlc3QuCgoNCgUE
BAIABBIEgAECCgoNCgUEBAIABhIEgAELHAoNCgUEBAIAARIEgAEdKgoNCgUEBAIAAxIEgAEt
LgooCgQEBAIBEgSDAQInGhogVGhpcyBmaWVsZCBpcyBuZXZlciBzZXQuCgoNCgUEBAIBBhIE
gwECFAoNCgUEBAIBARIEgwEVIgoNCgUEBAIBAxIEgwElJgpJCgQEBAICEgSGAQIhGjsgT3V0
cHV0IHJlc3VsdCBpbmRpY2F0aW5nIHdoZXJlIHRoZSBkYXRhIHdlcmUgZXhwb3J0ZWQgdG8u
CgoNCgUEBAICBhIEhgECDgoNCgUEBAICARIEhgEPHAoNCgUEBAICAxIEhgEfIApjCgIEBRIG
iwEAkQEBGlUgT3V0cHV0IHJlc3VsdCB0aGF0IHN0b3JlcyB0aGUgaW5mb3JtYXRpb24gYWJv
dXQgd2hlcmUgdGhlIGV4cG9ydGVkIGRhdGEgaXMKIHN0b3JlZC4KCgsKAwQFARIEiwEIFApB
CgQEBQIAEgSNAQI0GjMgVGhlIEJpZ1F1ZXJ5IGxvY2F0aW9uIHdoZXJlIHRoZSByZXN1bHQg
aXMgc3RvcmVkLgoKDQoFBAUCAAQSBI0BAgoKDQoFBAUCAAYSBI0BCx8KDQoFBAUCAAESBI0B
IC8KDQoFBAUCAAMSBI0BMjMKTQoEBAUCARIEkAECKho/IFRoZSBHb29nbGUgQ2xvdWQgU3Rv
cmFnZSBsb2NhdGlvbiB3aGVyZSB0aGUgcmVzdWx0IGlzIHN0b3JlZC4KCg0KBQQFAgEEEgSQ
AQIKCg0KBQQFAgEGEgSQAQsaCg0KBQQFAgEBEgSQARslCg0KBQQFAgEDEgSQASgpCikKAgQG
EgaUAQCaAQEaGyBBIEJpZ1F1ZXJ5IG91dHB1dCByZXN1bHQuCgoLCgMEBgESBJQBCBwKLQoE
BAYCABIElgECGBofIFRoZSBJRCBvZiBhIEJpZ1F1ZXJ5IERhdGFzZXQuCgoNCgUEBgIABRIE
lgECCAoNCgUEBgIAARIElgEJEwoNCgUEBgIAAxIElgEWFworCgQEBgIBEgSZAQIWGh0gVGhl
IElEIG9mIGEgQmlnUXVlcnkgVGFibGUuCgoNCgUEBgIBBRIEmQECCAoNCgUEBgIBARIEmQEJ
EQoNCgUEBgIBAxIEmQEUFQokCgIEBxIGnQEAoAEBGhYgQSBHY3Mgb3V0cHV0IHJlc3VsdC4K
CgsKAwQHARIEnQEIFwolCgQEBwIAEgSfAQIYGhcgVGhlIHVyaSBvZiBHY3Mgb3V0cHV0CgoN
CgUEBwIABRIEnwECCAoNCgUEBwIAARIEnwEJEwoNCgUEBwIAAxIEnwEWF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::ExportConfig::OutputConfig ===
    # Fields for OutputConfig
    # Field: gcs_destination Type: 11 (.google.cloud.retail.v2.OutputConfig.GcsDestination)
    # Field: bigquery_destination Type: 11 (.google.cloud.retail.v2.OutputConfig.BigQueryDestination)

# === Message: Google::Cloud::Retail::V2::ExportConfig::ExportErrorsConfig ===
    # Fields for ExportErrorsConfig
    # Field: gcs_prefix Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ExportConfig::ExportAnalyticsMetricsRequest ===
    # Fields for ExportAnalyticsMetricsRequest
    # Field: catalog Type: 9 ()
    # Field: output_config Type: 11 (.google.cloud.retail.v2.OutputConfig)
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ExportConfig::ExportMetadata ===
    # Fields for ExportMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Retail::V2::ExportConfig::ExportAnalyticsMetricsResponse ===
    # Fields for ExportAnalyticsMetricsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2.ExportErrorsConfig)
    # Field: output_result Type: 11 (.google.cloud.retail.v2.OutputResult)

# === Message: Google::Cloud::Retail::V2::ExportConfig::OutputResult ===
    # Fields for OutputResult
    # Field: bigquery_result Type: 11 (.google.cloud.retail.v2.BigQueryOutputResult)
    # Field: gcs_result Type: 11 (.google.cloud.retail.v2.GcsOutputResult)

# === Message: Google::Cloud::Retail::V2::ExportConfig::BigQueryOutputResult ===
    # Fields for BigQueryOutputResult
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2::ExportConfig::GcsOutputResult ===
    # Fields for GcsOutputResult
    # Field: output_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::ExportConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2/export_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::ExportConfig;

    my $msg = Google::Cloud::Retail::V2::ExportConfig::OutputConfig->new({
        gcs_destination => $gcs_destination,
        bigquery_destination => $bigquery_destination,
    });

    # Read or update a field
    my $val = $msg->gcs_destination();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::ExportConfig::OutputConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/export_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::ExportConfig::OutputConfig

The output configuration setting.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_destination() >> / C<< $msg->gcs_destination($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ExportConfig::OutputConfig::GcsDestination>)

The Google Cloud Storage location where the output is to be written to.

=item * C<< $msg->bigquery_destination() >> / C<< $msg->bigquery_destination($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ExportConfig::OutputConfig::BigQueryDestination>)

The BigQuery location where the output is to be written to.

=back

=head2 Google::Cloud::Retail::V2::ExportConfig::ExportErrorsConfig

Configuration of destination for Export related errors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_prefix() >> / C<< $msg->gcs_prefix($value) >>

Type: C<String>

Google Cloud Storage path for import errors. This must be an empty,
existing Cloud Storage bucket. Export errors will be written to a file in
this bucket, one per line, as a JSON-encoded
`google.rpc.Status` message.

=back

=head2 Google::Cloud::Retail::V2::ExportConfig::ExportAnalyticsMetricsRequest

Request message for the `ExportAnalyticsMetrics` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Full resource name of the parent catalog.
Expected format: `projects/*/locations/*/catalogs/*`

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ExportConfig::OutputConfig>)

Required. The output location of the data.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filtering expression to specify restrictions on returned metrics.
The expression is a sequence of terms. Each term applies a restriction to
the returned metrics. Use this expression to restrict results to a
specific time range.

  Currently we expect only one types of fields:

   * `timestamp`: This can be specified twice, once with a
     less than operator and once with a greater than operator. The
     `timestamp` restriction should result in one, contiguous, valid,
     `timestamp` range.

  Some examples of valid filters expressions:

  * Example 1: `timestamp > "2012-04-23T18:25:43.511Z"
            timestamp < "2012-04-23T18:30:43.511Z"`
  * Example 2: `timestamp > "2012-04-23T18:25:43.511Z"`

=back

=head2 Google::Cloud::Retail::V2::ExportConfig::ExportMetadata

Metadata related to the progress of the Export operation. This is
returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Retail::V2::ExportConfig::ExportAnalyticsMetricsResponse

Response of the ExportAnalyticsMetricsRequest. If the long running
operation was successful, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ExportConfig::ExportErrorsConfig>)

This field is never set.

=item * C<< $msg->output_result() >> / C<< $msg->output_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ExportConfig::OutputResult>)

Output result indicating where the data were exported to.

=back

=head2 Google::Cloud::Retail::V2::ExportConfig::OutputResult

Output result that stores the information about where the exported data is
stored.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bigquery_result() >> / C<< $msg->bigquery_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ExportConfig::BigQueryOutputResult>)

The BigQuery location where the result is stored.

=item * C<< $msg->gcs_result() >> / C<< $msg->gcs_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::ExportConfig::GcsOutputResult>)

The Google Cloud Storage location where the result is stored.

=back

=head2 Google::Cloud::Retail::V2::ExportConfig::BigQueryOutputResult

A BigQuery output result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

The ID of a BigQuery Dataset.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

The ID of a BigQuery Table.

=back

=head2 Google::Cloud::Retail::V2::ExportConfig::GcsOutputResult

A Gcs output result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_uri() >> / C<< $msg->output_uri($value) >>

Type: C<String>

The uri of Gcs output

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::ExportConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
