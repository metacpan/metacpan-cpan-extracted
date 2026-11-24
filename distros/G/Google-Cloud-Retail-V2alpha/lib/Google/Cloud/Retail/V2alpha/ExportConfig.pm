package Google::Cloud::Retail::V2alpha::ExportConfig;

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
Ci9nb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvZXhwb3J0X2NvbmZpZy5wcm90bxIbZ29v
Z2xlLmNsb3VkLnJldGFpbC52MmFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byLGAwoMT3V0cHV0Q29uZmlnEmMK
D2djc19kZXN0aW5hdGlvbhgBIAEoCzI4Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5P
dXRwdXRDb25maWcuR2NzRGVzdGluYXRpb25IAFIOZ2NzRGVzdGluYXRpb24ScgoUYmlncXVl
cnlfZGVzdGluYXRpb24YAiABKAsyPS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuT3V0
cHV0Q29uZmlnLkJpZ1F1ZXJ5RGVzdGluYXRpb25IAFITYmlncXVlcnlEZXN0aW5hdGlvbhpB
Cg5HY3NEZXN0aW5hdGlvbhIvChFvdXRwdXRfdXJpX3ByZWZpeBgBIAEoCUID4EECUg9vdXRw
dXRVcmlQcmVmaXgaigEKE0JpZ1F1ZXJ5RGVzdGluYXRpb24SIgoKZGF0YXNldF9pZBgBIAEo
CUID4EECUglkYXRhc2V0SWQSKwoPdGFibGVfaWRfcHJlZml4GAIgASgJQgPgQQJSDXRhYmxl
SWRQcmVmaXgSIgoKdGFibGVfdHlwZRgDIAEoCUID4EECUgl0YWJsZVR5cGVCDQoLZGVzdGlu
YXRpb24iRAoSRXhwb3J0RXJyb3JzQ29uZmlnEh8KCmdjc19wcmVmaXgYASABKAlIAFIJZ2Nz
UHJlZml4Qg0KC2Rlc3RpbmF0aW9uIsIBChVFeHBvcnRQcm9kdWN0c1JlcXVlc3QSPAoGcGFy
ZW50GAEgASgJQiTgQQL6QR4KHHJldGFpbC5nb29nbGVhcGlzLmNvbS9CcmFuY2hSBnBhcmVu
dBJTCg1vdXRwdXRfY29uZmlnGAIgASgLMikuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhh
Lk91dHB1dENvbmZpZ0ID4EECUgxvdXRwdXRDb25maWcSFgoGZmlsdGVyGAMgASgJUgZmaWx0
ZXIixQEKF0V4cG9ydFVzZXJFdmVudHNSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEf
Ch1yZXRhaWwuZ29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1IGcGFyZW50ElMKDW91dHB1dF9jb25m
aWcYAiABKAsyKS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuT3V0cHV0Q29uZmlnQgPg
QQJSDG91dHB1dENvbmZpZxIWCgZmaWx0ZXIYAyABKAlSBmZpbHRlciKrAQodRXhwb3J0QW5h
bHl0aWNzTWV0cmljc1JlcXVlc3QSHQoHY2F0YWxvZxgBIAEoCUID4EECUgdjYXRhbG9nElMK
DW91dHB1dF9jb25maWcYAiABKAsyKS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuT3V0
cHV0Q29uZmlnQgPgQQJSDG91dHB1dENvbmZpZxIWCgZmaWx0ZXIYAyABKAlSBmZpbHRlciKK
AQoORXhwb3J0TWV0YWRhdGESOwoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZSL3AQoWRXhwb3J0UHJvZHVjdHNSZXNw
b25zZRI3Cg1lcnJvcl9zYW1wbGVzGAEgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSDGVycm9y
U2FtcGxlcxJUCg1lcnJvcnNfY29uZmlnGAIgASgLMi8uZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmFscGhhLkV4cG9ydEVycm9yc0NvbmZpZ1IMZXJyb3JzQ29uZmlnEk4KDW91dHB1dF9yZXN1
bHQYAyABKAsyKS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuT3V0cHV0UmVzdWx0Ugxv
dXRwdXRSZXN1bHQi+QEKGEV4cG9ydFVzZXJFdmVudHNSZXNwb25zZRI3Cg1lcnJvcl9zYW1w
bGVzGAEgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSDGVycm9yU2FtcGxlcxJUCg1lcnJvcnNf
Y29uZmlnGAIgASgLMi8uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkV4cG9ydEVycm9y
c0NvbmZpZ1IMZXJyb3JzQ29uZmlnEk4KDW91dHB1dF9yZXN1bHQYAyABKAsyKS5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyYWxwaGEuT3V0cHV0UmVzdWx0UgxvdXRwdXRSZXN1bHQi/wEKHkV4
cG9ydEFuYWx5dGljc01ldHJpY3NSZXNwb25zZRI3Cg1lcnJvcl9zYW1wbGVzGAEgAygLMhIu
Z29vZ2xlLnJwYy5TdGF0dXNSDGVycm9yU2FtcGxlcxJUCg1lcnJvcnNfY29uZmlnGAIgASgL
Mi8uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkV4cG9ydEVycm9yc0NvbmZpZ1IMZXJy
b3JzQ29uZmlnEk4KDW91dHB1dF9yZXN1bHQYAyABKAsyKS5nb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuT3V0cHV0UmVzdWx0UgxvdXRwdXRSZXN1bHQitwEKDE91dHB1dFJlc3VsdBJa
Cg9iaWdxdWVyeV9yZXN1bHQYASADKAsyMS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEu
QmlnUXVlcnlPdXRwdXRSZXN1bHRSDmJpZ3F1ZXJ5UmVzdWx0EksKCmdjc19yZXN1bHQYAiAD
KAsyLC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuR2NzT3V0cHV0UmVzdWx0UglnY3NS
ZXN1bHQiUAoUQmlnUXVlcnlPdXRwdXRSZXN1bHQSHQoKZGF0YXNldF9pZBgBIAEoCVIJZGF0
YXNldElkEhkKCHRhYmxlX2lkGAIgASgJUgd0YWJsZUlkIjAKD0djc091dHB1dFJlc3VsdBId
CgpvdXRwdXRfdXJpGAEgASgJUglvdXRwdXRVcmlC1QEKH2NvbS5nb29nbGUuY2xvdWQucmV0
YWlsLnYyYWxwaGFCEUV4cG9ydENvbmZpZ1Byb3RvUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28v
cmV0YWlsL2FwaXYyYWxwaGEvcmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhtHb29nbGUu
Q2xvdWQuUmV0YWlsLlYyQWxwaGHKAhtHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYWxwaGHqAh5H
b29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYWxwaGFK910KBxIFDgCsAgEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAKQoJCgIDARIDEwAj
CgkKAgMCEgMUACkKCQoCAwMSAxUAIQoICgEIEgMXADgKCQoCCCUSAxcAOAoICgEIEgMYAE4K
CQoCCAsSAxgATgoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaADIKCQoCCAgSAxoAMgoI
CgEIEgMbADgKCQoCCAESAxsAOAoICgEIEgMcACQKCQoCCCQSAxwAJAoICgEIEgMdADgKCQoC
CCkSAx0AOAoICgEIEgMeADcKCQoCCC0SAx4ANwovCgIEABIEIQBFARojIFRoZSBvdXRwdXQg
Y29uZmlndXJhdGlvbiBzZXR0aW5nLgoKCgoDBAABEgMhCBQKSgoEBAADABIEIwIsAxo8IFRo
ZSBHb29nbGUgQ2xvdWQgU3RvcmFnZSBvdXRwdXQgZGVzdGluYXRpb24gY29uZmlndXJhdGlv
bi4KCgwKBQQAAwABEgMjChgKtAMKBgQAAwACABIDKwRKGqQDIFJlcXVpcmVkLiBUaGUgb3V0
cHV0IHVyaSBwcmVmaXggZm9yIHNhdmluZyBvdXRwdXQgZGF0YSB0byBqc29uIGZpbGVzLgog
U29tZSBtYXBwaW5nIGV4YW1wbGVzIGFyZSBhcyBmb2xsb3dzOgogb3V0cHV0X3VyaV9wcmVm
aXggICAgICAgICBzYW1wbGUgb3V0cHV0KGFzc3VtaW5nIHRoZSBvYmplY3QgaXMgZm9vLmpz
b24pCiA9PT09PT09PT09PT09PT09PT09PT09PT0gID09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT09PQogZ3M6Ly9idWNrZXQvICAgICAgICAgICAgICBnczov
L2J1Y2tldC9mb28uanNvbgogZ3M6Ly9idWNrZXQvZm9sZGVyLyAgICAgICBnczovL2J1Y2tl
dC9mb2xkZXIvZm9vLmpzb24KIGdzOi8vYnVja2V0L2ZvbGRlci9pdGVtXyAgZ3M6Ly9idWNr
ZXQvZm9sZGVyL2l0ZW1fZm9vLmpzb24KCg4KBwQAAwACAAUSAysECgoOCgcEAAMAAgABEgMr
CxwKDgoHBAADAAIAAxIDKx8gCg4KBwQAAwACAAgSAyshSQoRCgoEAAMAAgAInAgAEgMrIkgK
PgoEBAADARIELwI7AxowIFRoZSBCaWdRdWVyeSBvdXRwdXQgZGVzdGluYXRpb24gY29uZmln
dXJhdGlvbi4KCgwKBQQAAwEBEgMvCh0KOAoGBAADAQIAEgMxBEMaKSBSZXF1aXJlZC4gVGhl
IElEIG9mIGEgQmlnUXVlcnkgRGF0YXNldC4KCg4KBwQAAwECAAUSAzEECgoOCgcEAAMBAgAB
EgMxCxUKDgoHBAADAQIAAxIDMRgZCg4KBwQAAwECAAgSAzEaQgoRCgoEAAMBAgAInAgAEgMx
G0EKQgoGBAADAQIBEgM0BEgaMyBSZXF1aXJlZC4gVGhlIHByZWZpeCBvZiBleHBvcnRlZCBC
aWdRdWVyeSB0YWJsZXMuCgoOCgcEAAMBAgEFEgM0BAoKDgoHBAADAQIBARIDNAsaCg4KBwQA
AwECAQMSAzQdHgoOCgcEAAMBAgEIEgM0H0cKEQoKBAADAQIBCJwIABIDNCBGCrIBCgYEAAMB
AgISAzoEQxqiASBSZXF1aXJlZC4gRGVzY3JpYmVzIHRoZSB0YWJsZSB0eXBlLiBUaGUgZm9s
bG93aW5nIHZhbHVlcyBhcmUgc3VwcG9ydGVkOgoKICogYHRhYmxlYDogQSBCaWdRdWVyeSBu
YXRpdmUgdGFibGUuCiAqIGB2aWV3YDogQSB2aXJ0dWFsIHRhYmxlIGRlZmluZWQgYnkgYSBT
UUwgcXVlcnkuCgoOCgcEAAMBAgIFEgM6BAoKDgoHBAADAQICARIDOgsVCg4KBwQAAwECAgMS
AzoYGQoOCgcEAAMBAgIIEgM6GkIKEQoKBAADAQICCJwIABIDOhtBCkkKBAQACAASBD4CRAMa
OyBUaGUgY29uZmlndXJhdGlvbiBvZiBkZXN0aW5hdGlvbiBmb3IgaG9sZGluZyBvdXRwdXQg
ZGF0YS4KCgwKBQQACAABEgM+CBMKVgoEBAACABIDQAQnGkkgVGhlIEdvb2dsZSBDbG91ZCBT
dG9yYWdlIGxvY2F0aW9uIHdoZXJlIHRoZSBvdXRwdXQgaXMgdG8gYmUgd3JpdHRlbiB0by4K
CgwKBQQAAgAGEgNABBIKDAoFBAACAAESA0ATIgoMCgUEAAIAAxIDQCUmCkoKBAQAAgESA0ME
MRo9IFRoZSBCaWdRdWVyeSBsb2NhdGlvbiB3aGVyZSB0aGUgb3V0cHV0IGlzIHRvIGJlIHdy
aXR0ZW4gdG8uCgoMCgUEAAIBBhIDQwQXCgwKBQQAAgEBEgNDGCwKDAoFBAACAQMSA0MvMApF
CgIEARIESABRARo5IENvbmZpZ3VyYXRpb24gb2YgZGVzdGluYXRpb24gZm9yIEV4cG9ydCBy
ZWxhdGVkIGVycm9ycy4KCgoKAwQBARIDSAgaCi0KBAQBCAASBEoCUAMaHyBSZXF1aXJlZC4g
RXJyb3JzIGRlc3RpbmF0aW9uLgoKDAoFBAEIAAESA0oIEwrqAQoEBAECABIDTwQaGtwBIEdv
b2dsZSBDbG91ZCBTdG9yYWdlIHBhdGggZm9yIGltcG9ydCBlcnJvcnMuIFRoaXMgbXVzdCBi
ZSBhbiBlbXB0eSwKIGV4aXN0aW5nIENsb3VkIFN0b3JhZ2UgYnVja2V0LiBFeHBvcnQgZXJy
b3JzIHdpbGwgYmUgd3JpdHRlbiB0byBhIGZpbGUgaW4KIHRoaXMgYnVja2V0LCBvbmUgcGVy
IGxpbmUsIGFzIGEgSlNPTi1lbmNvZGVkCiBgZ29vZ2xlLnJwYy5TdGF0dXNgIG1lc3NhZ2Uu
CgoMCgUEAQIABRIDTwQKCgwKBQQBAgABEgNPCxUKDAoFBAECAAMSA08YGQo5CgIEAhIFVACN
AQEaLCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEV4cG9ydFByb2R1Y3RzIG1ldGhvZC4KCgoKAwQC
ARIDVAgdCvcBCgQEAgIAEgRYAlsEGugBIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIGEg
W0JyYW5jaF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkJyYW5jaF0sCiBhbmQgYGRl
ZmF1bHRfYnJhbmNoYCBmb3IgYnJhbmNoX2lkIGNvbXBvbmVudCBpcyBzdXBwb3J0ZWQuIEZv
ciBleGFtcGxlCiAgYHByb2plY3RzLzEyMzQvbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9ncy9k
ZWZhdWx0X2NhdGFsb2cvYnJhbmNoZXMvZGVmYXVsdF9icmFuY2hgCgoMCgUEAgIABRIDWAII
CgwKBQQCAgABEgNYCQ8KDAoFBAICAAMSA1gSEwoNCgUEAgIACBIEWBRbAwoPCggEAgIACJwI
ABIDWQQqCg4KBwQCAgAInwgSA1oETgo5CgQEAgIBEgNeAkoaLCBSZXF1aXJlZC4gVGhlIG91
dHB1dCBsb2NhdGlvbiBvZiB0aGUgZGF0YS4KCgwKBQQCAgEGEgNeAg4KDAoFBAICAQESA14P
HAoMCgUEAgIBAxIDXh8gCgwKBQQCAgEIEgNeIUkKDwoIBAICAQicCAASA14iSArdEQoEBAIC
AhIEjAECFBrOESBBIGZpbHRlcmluZyBleHByZXNzaW9uIHRvIHNwZWNpZnkgcmVzdHJpY3Rp
b25zIG9uIHJldHVybmVkIGV2ZW50cy4KIFRoZSBleHByZXNzaW9uIGlzIGEgc2VxdWVuY2Ug
b2YgdGVybXMuIEVhY2ggdGVybSBhcHBsaWVzIGEgcmVzdHJpY3Rpb24gdG8KIHRoZSByZXR1
cm5lZCBwcm9kdWN0cy4gVXNlIHRoaXMgZXhwcmVzc2lvbiB0byByZXN0cmljdCByZXN1bHRz
IHRvIGEKIHNwZWNpZmljIHRpbWUgcmFuZ2UsIHRhZywgb3Igc3RvY2sgc3RhdGUgb3IgdG8g
ZmlsdGVyIHByb2R1Y3RzIGJ5IHByb2R1Y3QKIHR5cGUuCiBGb3IgZXhhbXBsZSwgYGxhc3RN
b2RpZmllZFRpbWUgPiAiMjAxMi0wNC0yM1QxODoyNTo0My41MTFaIgogbGFzdE1vZGlmaWVk
VGltZTwiMjAxMi0wNC0yM1QxODoyNTo0My41MTFaIiBwcm9kdWN0VHlwZT1wcmltYXJ5YAoK
ICAgV2UgZXhwZWN0IG9ubHkgZm91ciB0eXBlcyBvZiBmaWVsZHM6CgogICAgKiBgbGFzdE1v
ZGlmaWVkVGltZWA6IFRoaXMgY2FuIGJlIHNwZWNpZmllZCB0d2ljZSwgb25jZSB3aXRoIGEK
ICAgICAgbGVzcyB0aGFuIG9wZXJhdG9yIGFuZCBvbmNlIHdpdGggYSBncmVhdGVyIHRoYW4g
b3BlcmF0b3IuIFRoZQogICAgICBgbGFzdE1vZGlmaWVkVGltZWAgcmVzdHJpY3Rpb24gc2hv
dWxkIHJlc3VsdCBpbiBvbmUsIGNvbnRpZ3VvdXMsCiAgICAgIHZhbGlkLCBsYXN0LW1vZGlm
aWVkLCB0aW1lIHJhbmdlLgoKICAgICogYHByb2R1Y3RUeXBlYDogU3VwcG9ydGVkIHZhbHVl
cyBhcmUgYHByaW1hcnlgIGFuZCBgdmFyaWFudGAuIFRoZQogICAgQm9vbGVhbiBvcGVyYXRv
cnMgYE9SYCBhbmQgYE5PVGAgYXJlIHN1cHBvcnRlZCBpZiB0aGUgZXhwcmVzc2lvbiBpcwog
ICAgZW5jbG9zZWQgaW4gcGFyZW50aGVzZXMgYW5kIG11c3QgYmUgc2VwYXJhdGVkIGZyb20g
dGhlCiAgICAgIGBwcm9kdWN0VHlwZWAgdmFsdWVzIGJ5IGEgc3BhY2UuCgogICAgKiBgYXZh
aWxhYmlsaXR5YDogU3VwcG9ydGVkIHZhbHVlcyBhcmUgYElOX1NUT0NLYCwgYE9VVF9PRl9T
VE9DS2AsCiAgICBgUFJFT1JERVJgLCBhbmQgYEJBQ0tPUkRFUmAuIEJvb2xlYW4gb3BlcmF0
b3JzIGBPUmAgYW5kIGBOT1RgIGFyZQogICAgc3VwcG9ydGVkIGlmIHRoZSBleHByZXNzaW9u
IGlzIGVuY2xvc2VkIGluIHBhcmVudGhlc2VzIGFuZCBtdXN0IGJlCiAgICBzZXBhcmF0ZWQg
ZnJvbSB0aGUgYGF2YWlsYWJpbGl0eWAgdmFsdWVzIGJ5IGEgc3BhY2UuCgogICAgKiBgVGFn
IGV4cHJlc3Npb25zYDogUmVzdHJpY3RzIG91dHB1dCB0byBwcm9kdWN0cyB0aGF0IG1hdGNo
IGFsbCBvZiB0aGUKICAgICAgc3BlY2lmaWVkIHRhZ3MuIEJvb2xlYW4gb3BlcmF0b3JzIGBP
UmAgYW5kIGBOT1RgIGFyZSBzdXBwb3J0ZWQgaWYgdGhlCiAgICAgIGV4cHJlc3Npb24gaXMg
ZW5jbG9zZWQgaW4gcGFyZW50aGVzZXMgYW5kIHRoZSBvcGVyYXRvcnMgYXJlIHNlcGFyYXRl
ZAogICAgICBmcm9tIHRoZSB0YWcgdmFsdWVzIGJ5IGEgc3BhY2UuIEFsc28gc3VwcG9ydGVk
IGlzICdgLSJ0YWdBImAnLCB3aGljaAogICAgICBpcyBlcXVpdmFsZW50IHRvICdgTk9UICJ0
YWdBImAnLiBUYWcgdmFsdWVzIG11c3QgYmUgZG91YmxlLXF1b3RlZCwKICAgICAgVVRGLTgg
ZW5jb2RlZCBzdHJpbmdzIGFuZCBoYXZlIGEgc2l6ZSBsaW1pdCBvZiAxLDAwMCBjaGFyYWN0
ZXJzLgoKICAgU29tZSBleGFtcGxlcyBvZiB2YWxpZCBmaWx0ZXJzIGV4cHJlc3Npb25zOgoK
ICAgKiBFeGFtcGxlIDE6IGBsYXN0TW9kaWZpZWRUaW1lID4gIjIwMTItMDQtMjNUMTg6MjU6
NDMuNTExWiIKICAgICAgICAgICAgIGxhc3RNb2RpZmllZFRpbWUgPCAiMjAxMi0wNC0yM1Qx
ODozMDo0My41MTFaImAKICAgKiBFeGFtcGxlIDI6IGBsYXN0TW9kaWZpZWRUaW1lID4gIjIw
MTItMDQtMjNUMTg6MjU6NDMuNTExWiIKICAgICAgICAgICAgIHByb2R1Y3RUeXBlID0gInZh
cmlhbnQiYAogICAqIEV4YW1wbGUgMzogYHRhZz0oIlJlZCIgT1IgIkJsdWUiKSB0YWc9Ik5l
dy1BcnJpdmFsIgogICAgICAgICAgICAgdGFnPShOT1QgInByb21vdGlvbmFsIikKICAgICAg
ICAgICAgIHByb2R1Y3RUeXBlID0gInByaW1hcnkiIGxhc3RNb2RpZmllZFRpbWUgPAogICAg
ICAgICAgICAgIjIwMTgtMDQtMjNUMTg6MzA6NDMuNTExWiJgCiAgICogRXhhbXBsZSA0OiBg
bGFzdE1vZGlmaWVkVGltZSA+ICIyMDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiYAogICAqIEV4
YW1wbGUgNTogYGF2YWlsYWJpbGl0eSA9IChJTl9TVE9DSyBPUiBCQUNLT1JERVIpYAoKDQoF
BAICAgUSBIwBAggKDQoFBAICAgESBIwBCQ8KDQoFBAICAgMSBIwBEhMKQgoCBAMSBpABAMEB
ARo0IFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIGBFeHBvcnRVc2VyRXZlbnRzYCBtZXRob2Qu
CgoLCgMEAwESBJABCB8KpwEKBAQDAgASBpQBApcBBBqWASBSZXF1aXJlZC4gUmVzb3VyY2Ug
bmFtZSBvZiBhCiBbQ2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLkNhdGFs
b2ddLiBGb3IgZXhhbXBsZQogYHByb2plY3RzLzEyMzQvbG9jYXRpb25zL2dsb2JhbC9jYXRh
bG9ncy9kZWZhdWx0X2NhdGFsb2dgCgoNCgUEAwIABRIElAECCAoNCgUEAwIAARIElAEJDwoN
CgUEAwIAAxIElAESEwoPCgUEAwIACBIGlAEUlwEDChAKCAQDAgAInAgAEgSVAQQqCg8KBwQD
AgAInwgSBJYBBE8KOgoEBAMCARIEmgECShosIFJlcXVpcmVkLiBUaGUgb3V0cHV0IGxvY2F0
aW9uIG9mIHRoZSBkYXRhLgoKDQoFBAMCAQYSBJoBAg4KDQoFBAMCAQESBJoBDxwKDQoFBAMC
AQMSBJoBHyAKDQoFBAMCAQgSBJoBIUkKEAoIBAMCAQicCAASBJoBIkgK+gwKBAQDAgISBMAB
AhQa6wwgQSBmaWx0ZXJpbmcgZXhwcmVzc2lvbiB0byBzcGVjaWZ5IHJlc3RyaWN0aW9ucyBv
biByZXR1cm5lZCBldmVudHMuCiBUaGUgZXhwcmVzc2lvbiBpcyBhIHNlcXVlbmNlIG9mIHRl
cm1zLiBFYWNoIHRlcm0gYXBwbGllcyBhIHJlc3RyaWN0aW9uIHRvCiB0aGUgcmV0dXJuZWQg
dXNlciBldmVudHMuIFVzZSB0aGlzIGV4cHJlc3Npb24gdG8gcmVzdHJpY3QgcmVzdWx0cyB0
byBhCiBzcGVjaWZpYyB0aW1lIHJhbmdlIG9yIHRvIGZpbHRlciBldmVudHMgYnkgZXZlbnRU
eXBlLgogRm9yIGV4YW1wbGUsIGBldmVudFRpbWUgPiAiMjAxMi0wNC0yM1QxODoyNTo0My41
MTFaIgogZXZlbnRzTWlzc2luZ0NhdGFsb2dJdGVtcyBldmVudFRpbWU8IjIwMTItMDQtMjNU
MTg6MjU6NDMuNTExWiIKIGV2ZW50VHlwZT1zZWFyY2hgCgogICBXZSBleHBlY3Qgb25seSB0
aHJlZSB0eXBlcyBvZiBmaWVsZHM6CgogICAgKiBgZXZlbnRUaW1lYDogVGhpcyBjYW4gYmUg
c3BlY2lmaWVkIHR3aWNlLCBvbmNlIHdpdGggYQogICAgICBsZXNzIHRoYW4gb3BlcmF0b3Ig
YW5kIG9uY2Ugd2l0aCBhIGdyZWF0ZXIgdGhhbiBvcGVyYXRvci4gVGhlCiAgICAgIGBldmVu
dFRpbWVgIHJlc3RyaWN0aW9uIHNob3VsZCByZXN1bHQgaW4gb25lLCBjb250aWd1b3VzLCB2
YWxpZCwKICAgICAgYGV2ZW50VGltZWAgcmFuZ2UuCgogICAgKiBgZXZlbnRUeXBlYDogQm9v
bGVhbiBvcGVyYXRvcnMgYE9SYCBhbmQgYE5PVGAgYXJlIHN1cHBvcnRlZCBpZiB0aGUKICAg
ICAgZXhwcmVzc2lvbiBpcyBlbmNsb3NlZCBpbiBwYXJlbnRoZXNlcyBhbmQgdGhlIG9wZXJh
dG9ycyBhcmUgc2VwYXJhdGVkCiAgICAgIGZyb20gdGhlIHRhZyB2YWx1ZXMgYnkgYSBzcGFj
ZS4KCiAgICAqIGBldmVudHNNaXNzaW5nQ2F0YWxvZ0l0ZW1zYDogVGhpcyByZXN0cmljdHMg
cmVzdWx0cwogICAgICB0byBldmVudHMgZm9yIHdoaWNoIGNhdGFsb2cgaXRlbXMgd2VyZSBu
b3QgZm91bmQgaW4gdGhlIGNhdGFsb2cuIFRoZQogICAgICBkZWZhdWx0IGJlaGF2aW9yIGlz
IHRvIHJldHVybiBvbmx5IHRob3NlIGV2ZW50cyBmb3Igd2hpY2ggY2F0YWxvZwogICAgICBp
dGVtcyB3ZXJlIGZvdW5kLgoKICAgU29tZSBleGFtcGxlcyBvZiB2YWxpZCBmaWx0ZXJzIGV4
cHJlc3Npb25zOgoKICAgKiBFeGFtcGxlIDE6IGBldmVudFRpbWUgPiAiMjAxMi0wNC0yM1Qx
ODoyNTo0My41MTFaIgogICAgICAgICAgICAgZXZlbnRUaW1lIDwgIjIwMTItMDQtMjNUMTg6
MzA6NDMuNTExWiJgCiAgICogRXhhbXBsZSAyOiBgZXZlbnRUaW1lID4gIjIwMTItMDQtMjNU
MTg6MjU6NDMuNTExWiIKICAgICAgICAgICAgIGV2ZW50VHlwZSA9IGRldGFpbC1wYWdlLXZp
ZXdgCiAgICogRXhhbXBsZSAzOiBgZXZlbnRzTWlzc2luZ0NhdGFsb2dJdGVtcwogICAgICAg
ICAgICAgZXZlbnRUeXBlID0gKE5PVCBzZWFyY2gpIGV2ZW50VGltZSA8CiAgICAgICAgICAg
ICAiMjAxOC0wNC0yM1QxODozMDo0My41MTFaImAKICAgKiBFeGFtcGxlIDQ6IGBldmVudFRp
bWUgPiAiMjAxMi0wNC0yM1QxODoyNTo0My41MTFaImAKICAgKiBFeGFtcGxlIDU6IGBldmVu
dFR5cGUgPSAoZGV0YWlsLXBhZ2UtdmlldyBPUiBzZWFyY2gpYAogICAqIEV4YW1wbGUgNjog
YGV2ZW50c01pc3NpbmdDYXRhbG9nSXRlbXNgCgoNCgUEAwICBRIEwAECCAoNCgUEAwICARIE
wAEJDwoNCgUEAwICAxIEwAESEwpICgIEBBIGxAEA3gEBGjogUmVxdWVzdCBtZXNzYWdlIGZv
ciB0aGUgYEV4cG9ydEFuYWx5dGljc01ldHJpY3NgIG1ldGhvZC4KCgsKAwQEARIExAEIJQp5
CgQEBAIAEgTHAQI+GmsgUmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcGFy
ZW50IGNhdGFsb2cuCiBFeHBlY3RlZCBmb3JtYXQ6IGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L2NhdGFsb2dzLypgCgoNCgUEBAIABRIExwECCAoNCgUEBAIAARIExwEJEAoNCgUEBAIAAxIE
xwETFAoNCgUEBAIACBIExwEVPQoQCggEBAIACJwIABIExwEWPAo6CgQEBAIBEgTKAQJKGiwg
UmVxdWlyZWQuIFRoZSBvdXRwdXQgbG9jYXRpb24gb2YgdGhlIGRhdGEuCgoNCgUEBAIBBhIE
ygECDgoNCgUEBAIBARIEygEPHAoNCgUEBAIBAxIEygEfIAoNCgUEBAIBCBIEygEhSQoQCggE
BAIBCJwIABIEygEiSArjBQoEBAQCAhIE3QECFBrUBSBBIGZpbHRlcmluZyBleHByZXNzaW9u
IHRvIHNwZWNpZnkgcmVzdHJpY3Rpb25zIG9uIHJldHVybmVkIG1ldHJpY3MuCiBUaGUgZXhw
cmVzc2lvbiBpcyBhIHNlcXVlbmNlIG9mIHRlcm1zLiBFYWNoIHRlcm0gYXBwbGllcyBhIHJl
c3RyaWN0aW9uIHRvCiB0aGUgcmV0dXJuZWQgbWV0cmljcy4gVXNlIHRoaXMgZXhwcmVzc2lv
biB0byByZXN0cmljdCByZXN1bHRzIHRvIGEKIHNwZWNpZmljIHRpbWUgcmFuZ2UuCgogICBD
dXJyZW50bHkgd2UgZXhwZWN0IG9ubHkgb25lIHR5cGVzIG9mIGZpZWxkczoKCiAgICAqIGB0
aW1lc3RhbXBgOiBUaGlzIGNhbiBiZSBzcGVjaWZpZWQgdHdpY2UsIG9uY2Ugd2l0aCBhCiAg
ICAgIGxlc3MgdGhhbiBvcGVyYXRvciBhbmQgb25jZSB3aXRoIGEgZ3JlYXRlciB0aGFuIG9w
ZXJhdG9yLiBUaGUKICAgICAgYHRpbWVzdGFtcGAgcmVzdHJpY3Rpb24gc2hvdWxkIHJlc3Vs
dCBpbiBvbmUsIGNvbnRpZ3VvdXMsIHZhbGlkLAogICAgICBgdGltZXN0YW1wYCByYW5nZS4K
CiAgIFNvbWUgZXhhbXBsZXMgb2YgdmFsaWQgZmlsdGVycyBleHByZXNzaW9uczoKCiAgICog
RXhhbXBsZSAxOiBgdGltZXN0YW1wID4gIjIwMTItMDQtMjNUMTg6MjU6NDMuNTExWiIKICAg
ICAgICAgICAgIHRpbWVzdGFtcCA8ICIyMDEyLTA0LTIzVDE4OjMwOjQzLjUxMVoiYAogICAq
IEV4YW1wbGUgMjogYHRpbWVzdGFtcCA+ICIyMDEyLTA0LTIzVDE4OjI1OjQzLjUxMVoiYAoK
DQoFBAQCAgUSBN0BAggKDQoFBAQCAgESBN0BCQ8KDQoFBAQCAgMSBN0BEhMKkAEKAgQFEgbi
AQDpAQEagQEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhlIEV4cG9y
dCBvcGVyYXRpb24uIFRoaXMgaXMKIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uLm1ldGFkYXRhIGZpZWxkLgoKCwoDBAUBEgTiAQgWCiYKBAQFAgASBOQB
AiwaGCBPcGVyYXRpb24gY3JlYXRlIHRpbWUuCgoNCgUEBQIABhIE5AECGwoNCgUEBQIAARIE
5AEcJwoNCgUEBQIAAxIE5AEqKwpkCgQEBQIBEgToAQIsGlYgT3BlcmF0aW9uIGxhc3QgdXBk
YXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24gaXMgZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQog
ZmluaXNoIHRpbWUuCgoNCgUEBQIBBhIE6AECGwoNCgUEBQIBARIE6AEcJwoNCgUEBQIBAxIE
6AEqKwrTAQoCBAYSBu4BAPcBARrEASBSZXNwb25zZSBvZiB0aGUgRXhwb3J0UHJvZHVjdHNS
ZXF1ZXN0LiBJZiB0aGUgbG9uZyBydW5uaW5nCiBvcGVyYXRpb24gaXMgZG9uZSwgdGhlbiB0
aGlzIG1lc3NhZ2UgaXMgcmV0dXJuZWQgYnkgdGhlCiBnb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9ucy5yZXNwb25zZSBmaWVsZCBpZiB0aGUgb3BlcmF0aW9uIHdhcyBzdWNjZXNzZnVs
LgoKCwoDBAYBEgTuAQgeCkwKBAQGAgASBPABAi8aPiBBIHNhbXBsZSBvZiBlcnJvcnMgZW5j
b3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUgcmVxdWVzdC4KCg0KBQQGAgAEEgTwAQIK
Cg0KBQQGAgAGEgTwAQscCg0KBQQGAgABEgTwAR0qCg0KBQQGAgADEgTwAS0uCigKBAQGAgES
BPMBAicaGiBUaGlzIGZpZWxkIGlzIG5ldmVyIHNldC4KCg0KBQQGAgEGEgTzAQIUCg0KBQQG
AgEBEgTzARUiCg0KBQQGAgEDEgTzASUmCkkKBAQGAgISBPYBAiEaOyBPdXRwdXQgcmVzdWx0
IGluZGljYXRpbmcgd2hlcmUgdGhlIGRhdGEgd2VyZSBleHBvcnRlZCB0by4KCg0KBQQGAgIG
EgT2AQIOCg0KBQQGAgIBEgT2AQ8cCg0KBQQGAgIDEgT2AR8gCtwBCgIEBxIG/AEAhQIBGs0B
IFJlc3BvbnNlIG9mIHRoZSBFeHBvcnRVc2VyRXZlbnRzUmVxdWVzdC4gSWYgdGhlIGxvbmcg
cnVubmluZwogb3BlcmF0aW9uIHdhcyBzdWNjZXNzZnVsLCB0aGVuIHRoaXMgbWVzc2FnZSBp
cyByZXR1cm5lZCBieSB0aGUKIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb25zLnJlc3Bv
bnNlIGZpZWxkIGlmIHRoZSBvcGVyYXRpb24gd2FzIHN1Y2Nlc3NmdWwuCgoLCgMEBwESBPwB
CCAKTAoEBAcCABIE/gECLxo+IEEgc2FtcGxlIG9mIGVycm9ycyBlbmNvdW50ZXJlZCB3aGls
ZSBwcm9jZXNzaW5nIHRoZSByZXF1ZXN0LgoKDQoFBAcCAAQSBP4BAgoKDQoFBAcCAAYSBP4B
CxwKDQoFBAcCAAESBP4BHSoKDQoFBAcCAAMSBP4BLS4KKAoEBAcCARIEgQICJxoaIFRoaXMg
ZmllbGQgaXMgbmV2ZXIgc2V0LgoKDQoFBAcCAQYSBIECAhQKDQoFBAcCAQESBIECFSIKDQoF
BAcCAQMSBIECJSYKSQoEBAcCAhIEhAICIRo7IE91dHB1dCByZXN1bHQgaW5kaWNhdGluZyB3
aGVyZSB0aGUgZGF0YSB3ZXJlIGV4cG9ydGVkIHRvLgoKDQoFBAcCAgYSBIQCAg4KDQoFBAcC
AgESBIQCDxwKDQoFBAcCAgMSBIQCHyAK4gEKAgQIEgaKAgCTAgEa0wEgUmVzcG9uc2Ugb2Yg
dGhlIEV4cG9ydEFuYWx5dGljc01ldHJpY3NSZXF1ZXN0LiBJZiB0aGUgbG9uZyBydW5uaW5n
CiBvcGVyYXRpb24gd2FzIHN1Y2Nlc3NmdWwsIHRoZW4gdGhpcyBtZXNzYWdlIGlzIHJldHVy
bmVkIGJ5IHRoZQogZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMucmVzcG9uc2UgZmll
bGQgaWYgdGhlIG9wZXJhdGlvbiB3YXMgc3VjY2Vzc2Z1bC4KCgsKAwQIARIEigIIJgpMCgQE
CAIAEgSMAgIvGj4gQSBzYW1wbGUgb2YgZXJyb3JzIGVuY291bnRlcmVkIHdoaWxlIHByb2Nl
c3NpbmcgdGhlIHJlcXVlc3QuCgoNCgUECAIABBIEjAICCgoNCgUECAIABhIEjAILHAoNCgUE
CAIAARIEjAIdKgoNCgUECAIAAxIEjAItLgooCgQECAIBEgSPAgInGhogVGhpcyBmaWVsZCBp
cyBuZXZlciBzZXQuCgoNCgUECAIBBhIEjwICFAoNCgUECAIBARIEjwIVIgoNCgUECAIBAxIE
jwIlJgpJCgQECAICEgSSAgIhGjsgT3V0cHV0IHJlc3VsdCBpbmRpY2F0aW5nIHdoZXJlIHRo
ZSBkYXRhIHdlcmUgZXhwb3J0ZWQgdG8uCgoNCgUECAICBhIEkgICDgoNCgUECAICARIEkgIP
HAoNCgUECAICAxIEkgIfIApjCgIECRIGlwIAnQIBGlUgT3V0cHV0IHJlc3VsdCB0aGF0IHN0
b3JlcyB0aGUgaW5mb3JtYXRpb24gYWJvdXQgd2hlcmUgdGhlIGV4cG9ydGVkIGRhdGEgaXMK
IHN0b3JlZC4KCgsKAwQJARIElwIIFApBCgQECQIAEgSZAgI0GjMgVGhlIEJpZ1F1ZXJ5IGxv
Y2F0aW9uIHdoZXJlIHRoZSByZXN1bHQgaXMgc3RvcmVkLgoKDQoFBAkCAAQSBJkCAgoKDQoF
BAkCAAYSBJkCCx8KDQoFBAkCAAESBJkCIC8KDQoFBAkCAAMSBJkCMjMKTQoEBAkCARIEnAIC
Kho/IFRoZSBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiB3aGVyZSB0aGUgcmVzdWx0
IGlzIHN0b3JlZC4KCg0KBQQJAgEEEgScAgIKCg0KBQQJAgEGEgScAgsaCg0KBQQJAgEBEgSc
AhslCg0KBQQJAgEDEgScAigpCikKAgQKEgagAgCmAgEaGyBBIEJpZ1F1ZXJ5IG91dHB1dCBy
ZXN1bHQuCgoLCgMECgESBKACCBwKLQoEBAoCABIEogICGBofIFRoZSBJRCBvZiBhIEJpZ1F1
ZXJ5IERhdGFzZXQuCgoNCgUECgIABRIEogICCAoNCgUECgIAARIEogIJEwoNCgUECgIAAxIE
ogIWFworCgQECgIBEgSlAgIWGh0gVGhlIElEIG9mIGEgQmlnUXVlcnkgVGFibGUuCgoNCgUE
CgIBBRIEpQICCAoNCgUECgIBARIEpQIJEQoNCgUECgIBAxIEpQIUFQokCgIECxIGqQIArAIB
GhYgQSBHY3Mgb3V0cHV0IHJlc3VsdC4KCgsKAwQLARIEqQIIFwolCgQECwIAEgSrAgIYGhcg
VGhlIHVyaSBvZiBHY3Mgb3V0cHV0CgoNCgUECwIABRIEqwICCAoNCgUECwIAARIEqwIJEwoN
CgUECwIAAxIEqwIWF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig ===
    # Fields for OutputConfig
    # Field: gcs_destination Type: 11 (.google.cloud.retail.v2alpha.OutputConfig.GcsDestination)
    # Field: bigquery_destination Type: 11 (.google.cloud.retail.v2alpha.OutputConfig.BigQueryDestination)

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::ExportErrorsConfig ===
    # Fields for ExportErrorsConfig
    # Field: gcs_prefix Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::ExportProductsRequest ===
    # Fields for ExportProductsRequest
    # Field: parent Type: 9 ()
    # Field: output_config Type: 11 (.google.cloud.retail.v2alpha.OutputConfig)
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::ExportUserEventsRequest ===
    # Fields for ExportUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: output_config Type: 11 (.google.cloud.retail.v2alpha.OutputConfig)
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::ExportAnalyticsMetricsRequest ===
    # Fields for ExportAnalyticsMetricsRequest
    # Field: catalog Type: 9 ()
    # Field: output_config Type: 11 (.google.cloud.retail.v2alpha.OutputConfig)
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::ExportMetadata ===
    # Fields for ExportMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::ExportProductsResponse ===
    # Fields for ExportProductsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2alpha.ExportErrorsConfig)
    # Field: output_result Type: 11 (.google.cloud.retail.v2alpha.OutputResult)

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::ExportUserEventsResponse ===
    # Fields for ExportUserEventsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2alpha.ExportErrorsConfig)
    # Field: output_result Type: 11 (.google.cloud.retail.v2alpha.OutputResult)

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::ExportAnalyticsMetricsResponse ===
    # Fields for ExportAnalyticsMetricsResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: errors_config Type: 11 (.google.cloud.retail.v2alpha.ExportErrorsConfig)
    # Field: output_result Type: 11 (.google.cloud.retail.v2alpha.OutputResult)

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::OutputResult ===
    # Fields for OutputResult
    # Field: bigquery_result Type: 11 (.google.cloud.retail.v2alpha.BigQueryOutputResult)
    # Field: gcs_result Type: 11 (.google.cloud.retail.v2alpha.GcsOutputResult)

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::BigQueryOutputResult ===
    # Fields for BigQueryOutputResult
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2alpha::ExportConfig::GcsOutputResult ===
    # Fields for GcsOutputResult
    # Field: output_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::ExportConfig - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/export_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::ExportConfig;

    my $msg = Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig->new({
        gcs_destination => $gcs_destination,
        bigquery_destination => $bigquery_destination,
    });

    # Read or update a field
    my $val = $msg->gcs_destination();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/export_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig

The output configuration setting.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_destination() >> / C<< $msg->gcs_destination($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig::GcsDestination>)

The Google Cloud Storage location where the output is to be written to.

=item * C<< $msg->bigquery_destination() >> / C<< $msg->bigquery_destination($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig::BigQueryDestination>)

The BigQuery location where the output is to be written to.

=back

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::ExportErrorsConfig

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

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::ExportProductsRequest

Request message for ExportProducts method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of a [Branch][google.cloud.retail.v2alpha.Branch],
and `default_branch` for branch_id component is supported. For example
 `projects/1234/locations/global/catalogs/default_catalog/branches/default_branch`

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig>)

Required. The output location of the data.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filtering expression to specify restrictions on returned events.
The expression is a sequence of terms. Each term applies a restriction to
the returned products. Use this expression to restrict results to a
specific time range, tag, or stock state or to filter products by product
type.
For example, `lastModifiedTime > "2012-04-23T18:25:43.511Z"
lastModifiedTime<"2012-04-23T18:25:43.511Z" productType=primary`

  We expect only four types of fields:

   * `lastModifiedTime`: This can be specified twice, once with a
     less than operator and once with a greater than operator. The
     `lastModifiedTime` restriction should result in one, contiguous,
     valid, last-modified, time range.

   * `productType`: Supported values are `primary` and `variant`. The
   Boolean operators `OR` and `NOT` are supported if the expression is
   enclosed in parentheses and must be separated from the
     `productType` values by a space.

   * `availability`: Supported values are `IN_STOCK`, `OUT_OF_STOCK`,
   `PREORDER`, and `BACKORDER`. Boolean operators `OR` and `NOT` are
   supported if the expression is enclosed in parentheses and must be
   separated from the `availability` values by a space.

   * `Tag expressions`: Restricts output to products that match all of the
     specified tags. Boolean operators `OR` and `NOT` are supported if the
     expression is enclosed in parentheses and the operators are separated
     from the tag values by a space. Also supported is '`-"tagA"`', which
     is equivalent to '`NOT "tagA"`'. Tag values must be double-quoted,
     UTF-8 encoded strings and have a size limit of 1,000 characters.

  Some examples of valid filters expressions:

  * Example 1: `lastModifiedTime > "2012-04-23T18:25:43.511Z"
            lastModifiedTime < "2012-04-23T18:30:43.511Z"`
  * Example 2: `lastModifiedTime > "2012-04-23T18:25:43.511Z"
            productType = "variant"`
  * Example 3: `tag=("Red" OR "Blue") tag="New-Arrival"
            tag=(NOT "promotional")
            productType = "primary" lastModifiedTime <
            "2018-04-23T18:30:43.511Z"`
  * Example 4: `lastModifiedTime > "2012-04-23T18:25:43.511Z"`
  * Example 5: `availability = (IN_STOCK OR BACKORDER)`

=back

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::ExportUserEventsRequest

Request message for the `ExportUserEvents` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of a
[Catalog][google.cloud.retail.v2alpha.Catalog]. For example
`projects/1234/locations/global/catalogs/default_catalog`

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig>)

Required. The output location of the data.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filtering expression to specify restrictions on returned events.
The expression is a sequence of terms. Each term applies a restriction to
the returned user events. Use this expression to restrict results to a
specific time range or to filter events by eventType.
For example, `eventTime > "2012-04-23T18:25:43.511Z"
eventsMissingCatalogItems eventTime<"2012-04-23T18:25:43.511Z"
eventType=search`

  We expect only three types of fields:

   * `eventTime`: This can be specified twice, once with a
     less than operator and once with a greater than operator. The
     `eventTime` restriction should result in one, contiguous, valid,
     `eventTime` range.

   * `eventType`: Boolean operators `OR` and `NOT` are supported if the
     expression is enclosed in parentheses and the operators are separated
     from the tag values by a space.

   * `eventsMissingCatalogItems`: This restricts results
     to events for which catalog items were not found in the catalog. The
     default behavior is to return only those events for which catalog
     items were found.

  Some examples of valid filters expressions:

  * Example 1: `eventTime > "2012-04-23T18:25:43.511Z"
            eventTime < "2012-04-23T18:30:43.511Z"`
  * Example 2: `eventTime > "2012-04-23T18:25:43.511Z"
            eventType = detail-page-view`
  * Example 3: `eventsMissingCatalogItems
            eventType = (NOT search) eventTime <
            "2018-04-23T18:30:43.511Z"`
  * Example 4: `eventTime > "2012-04-23T18:25:43.511Z"`
  * Example 5: `eventType = (detail-page-view OR search)`
  * Example 6: `eventsMissingCatalogItems`

=back

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::ExportAnalyticsMetricsRequest

Request message for the `ExportAnalyticsMetrics` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->catalog() >> / C<< $msg->catalog($value) >>

Type: C<String>

Required. Full resource name of the parent catalog.
Expected format: `projects/*/locations/*/catalogs/*`

=item * C<< $msg->output_config() >> / C<< $msg->output_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::OutputConfig>)

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

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::ExportMetadata

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

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::ExportProductsResponse

Response of the ExportProductsRequest. If the long running
operation is done, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::ExportErrorsConfig>)

This field is never set.

=item * C<< $msg->output_result() >> / C<< $msg->output_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::OutputResult>)

Output result indicating where the data were exported to.

=back

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::ExportUserEventsResponse

Response of the ExportUserEventsRequest. If the long running
operation was successful, then this message is returned by the
google.longrunning.Operations.response field if the operation was successful.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=item * C<< $msg->errors_config() >> / C<< $msg->errors_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::ExportErrorsConfig>)

This field is never set.

=item * C<< $msg->output_result() >> / C<< $msg->output_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::OutputResult>)

Output result indicating where the data were exported to.

=back

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::ExportAnalyticsMetricsResponse

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

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::ExportErrorsConfig>)

This field is never set.

=item * C<< $msg->output_result() >> / C<< $msg->output_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::OutputResult>)

Output result indicating where the data were exported to.

=back

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::OutputResult

Output result that stores the information about where the exported data is
stored.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bigquery_result() >> / C<< $msg->bigquery_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::BigQueryOutputResult>)

The BigQuery location where the result is stored.

=item * C<< $msg->gcs_result() >> / C<< $msg->gcs_result($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::ExportConfig::GcsOutputResult>)

The Google Cloud Storage location where the result is stored.

=back

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::BigQueryOutputResult

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

=head2 Google::Cloud::Retail::V2alpha::ExportConfig::GcsOutputResult

A Gcs output result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_uri() >> / C<< $msg->output_uri($value) >>

Type: C<String>

The uri of Gcs output

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::ExportConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
