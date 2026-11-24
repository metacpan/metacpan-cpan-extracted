package Google::Cloud::Dialogflow::V2beta1::Webhook;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dialogflow::V2beta1::Context };
    eval { require Google::Cloud::Dialogflow::V2beta1::Intent };
    eval { require Google::Cloud::Dialogflow::V2beta1::Session };
    eval { require Google::Cloud::Dialogflow::V2beta1::SessionEntityType };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL3dlYmhvb2sucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
LWdvb2dsZS9jbG91ZC9kaWFsb2dmbG93L3YyYmV0YTEvY29udGV4dC5wcm90bxosZ29vZ2xl
L2Nsb3VkL2RpYWxvZ2Zsb3cvdjJiZXRhMS9pbnRlbnQucHJvdG8aLWdvb2dsZS9jbG91ZC9k
aWFsb2dmbG93L3YyYmV0YTEvc2Vzc2lvbi5wcm90bxo5Z29vZ2xlL2Nsb3VkL2RpYWxvZ2Zs
b3cvdjJiZXRhMS9zZXNzaW9uX2VudGl0eV90eXBlLnByb3RvGhxnb29nbGUvcHJvdG9idWYv
c3RydWN0LnByb3RvIooDCg5XZWJob29rUmVxdWVzdBIYCgdzZXNzaW9uGAQgASgJUgdzZXNz
aW9uEh8KC3Jlc3BvbnNlX2lkGAEgASgJUgpyZXNwb25zZUlkEk8KDHF1ZXJ5X3Jlc3VsdBgC
IAEoCzIsLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuUXVlcnlSZXN1bHRSC3F1
ZXJ5UmVzdWx0EmgKGWFsdGVybmF0aXZlX3F1ZXJ5X3Jlc3VsdHMYBSADKAsyLC5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlF1ZXJ5UmVzdWx0UhdhbHRlcm5hdGl2ZVF1ZXJ5
UmVzdWx0cxKBAQoeb3JpZ2luYWxfZGV0ZWN0X2ludGVudF9yZXF1ZXN0GAMgASgLMjwuZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5PcmlnaW5hbERldGVjdEludGVudFJlcXVl
c3RSG29yaWdpbmFsRGV0ZWN0SW50ZW50UmVxdWVzdCLaBAoPV2ViaG9va1Jlc3BvbnNlEikK
EGZ1bGZpbGxtZW50X3RleHQYASABKAlSD2Z1bGZpbGxtZW50VGV4dBJiChRmdWxmaWxsbWVu
dF9tZXNzYWdlcxgCIAMoCzIvLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuSW50
ZW50Lk1lc3NhZ2VSE2Z1bGZpbGxtZW50TWVzc2FnZXMSFgoGc291cmNlGAMgASgJUgZzb3Vy
Y2USMQoHcGF5bG9hZBgEIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSB3BheWxvYWQS
UQoPb3V0cHV0X2NvbnRleHRzGAUgAygLMiguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJi
ZXRhMS5Db250ZXh0Ug5vdXRwdXRDb250ZXh0cxJdChRmb2xsb3d1cF9ldmVudF9pbnB1dBgG
IAEoCzIrLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuRXZlbnRJbnB1dFISZm9s
bG93dXBFdmVudElucHV0EiwKEmxpdmVfYWdlbnRfaGFuZG9mZhgHIAEoCFIQbGl2ZUFnZW50
SGFuZG9mZhInCg9lbmRfaW50ZXJhY3Rpb24YCCABKAhSDmVuZEludGVyYWN0aW9uEmQKFHNl
c3Npb25fZW50aXR5X3R5cGVzGAogAygLMjIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJi
ZXRhMS5TZXNzaW9uRW50aXR5VHlwZVISc2Vzc2lvbkVudGl0eVR5cGVzIoIBChtPcmlnaW5h
bERldGVjdEludGVudFJlcXVlc3QSFgoGc291cmNlGAEgASgJUgZzb3VyY2USGAoHdmVyc2lv
bhgCIAEoCVIHdmVyc2lvbhIxCgdwYXlsb2FkGAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0
cnVjdFIHcGF5bG9hZEKgAgojY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTFC
DFdlYmhvb2tQcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjJi
ZXRhMS9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAh9Hb29nbGUuQ2xvdWQuRGlh
bG9nZmxvdy5WMkJldGEx6kF8CidzZXJ2aWNlZGlyZWN0b3J5Lmdvb2dsZWFwaXMuY29tL1Nl
cnZpY2USUXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9uYW1lc3Bh
Y2VzL3tuYW1lc3BhY2V9L3NlcnZpY2VzL3tzZXJ2aWNlfUqsOAoHEgUOAK4BAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAjCgkKAgMB
EgMTADcKCQoCAwISAxQANgoJCgIDAxIDFQA3CgkKAgMEEgMWAEMKCQoCAwUSAxcAJgoICgEI
EgMZADwKCQoCCCUSAxkAPAoICgEIEgMaAFoKCQoCCAsSAxoAWgoICgEIEgMbACIKCQoCCAoS
AxsAIgoICgEIEgMcAC0KCQoCCAgSAxwALQoICgEIEgMdADwKCQoCCAESAx0APAoICgEIEgMe
ACAKCQoCCCQSAx4AIAoJCgEIEgQfACICCgwKBAidCAASBB8AIgIKNQoCBAASBCUAQQEaKSBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvciBhIHdlYmhvb2sgY2FsbC4KCgoKAwQAARIDJQgWCpIE
CgQEAAIAEgMxAhUahAQgVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIGRldGVjdEludGVudCBy
ZXF1ZXN0IHNlc3Npb24uCiBDYW4gYmUgdXNlZCB0byBpZGVudGlmeSBlbmQtdXNlciBpbnNp
ZGUgd2ViaG9vayBpbXBsZW1lbnRhdGlvbi4KIFN1cHBvcnRlZCBmb3JtYXRzOgogLSBgcHJv
amVjdHMvPFByb2plY3QgSUQ+L2FnZW50L3Nlc3Npb25zLzxTZXNzaW9uIElEPiwKIC0gYHBy
b2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9hZ2VudC9zZXNz
aW9ucy88U2Vzc2lvbgogICBJRD5gLAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50
L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+L3VzZXJzLzxVc2VyCiAgIElEPi9zZXNz
aW9ucy88U2Vzc2lvbiBJRD5gLAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9u
cy88TG9jYXRpb24KICAgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+
L3VzZXJzLzxVc2VyIElEPi9zZXNzaW9ucy88U2Vzc2lvbgogICBJRD5gLAoKDAoFBAACAAUS
AzECCAoMCgUEAAIAARIDMQkQCgwKBQQAAgADEgMxExQKgAEKBAQAAgESAzUCGRpzIFRoZSB1
bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgcmVzcG9uc2UuIENvbnRhaW5zIHRoZSBzYW1lIHZh
bHVlIGFzCiBgW1N0cmVhbWluZ11EZXRlY3RJbnRlbnRSZXNwb25zZS5yZXNwb25zZV9pZGAu
CgoMCgUEAAIBBRIDNQIICgwKBQQAAgEBEgM1CRQKDAoFBAACAQMSAzUXGAqXAQoEBAACAhID
OQIfGokBIFRoZSByZXN1bHQgb2YgdGhlIGNvbnZlcnNhdGlvbmFsIHF1ZXJ5IG9yIGV2ZW50
IHByb2Nlc3NpbmcuIENvbnRhaW5zIHRoZQogc2FtZSB2YWx1ZSBhcyBgW1N0cmVhbWluZ11E
ZXRlY3RJbnRlbnRSZXNwb25zZS5xdWVyeV9yZXN1bHRgLgoKDAoFBAACAgYSAzkCDQoMCgUE
AAICARIDOQ4aCgwKBQQAAgIDEgM5HR4KPwoEBAACAxIDPAI1GjIgQWx0ZXJuYXRpdmUgcXVl
cnkgcmVzdWx0cyBmcm9tIEtub3dsZWRnZVNlcnZpY2UuCgoMCgUEAAIDBBIDPAIKCgwKBQQA
AgMGEgM8CxYKDAoFBAACAwESAzwXMAoMCgUEAAIDAxIDPDM0CnEKBAQAAgQSA0ACQRpkIE9w
dGlvbmFsLiBUaGUgY29udGVudHMgb2YgdGhlIG9yaWdpbmFsIHJlcXVlc3QgdGhhdCB3YXMg
cGFzc2VkIHRvCiBgW1N0cmVhbWluZ11EZXRlY3RJbnRlbnRgIGNhbGwuCgoMCgUEAAIEBhID
QAIdCgwKBQQAAgQBEgNAHjwKDAoFBAACBAMSA0A/QArhBAoCBAESBVIAkgEBGtMEIFRoZSBy
ZXNwb25zZSBtZXNzYWdlIGZvciBhIHdlYmhvb2sgY2FsbC4KCiBUaGlzIHJlc3BvbnNlIGlz
IHZhbGlkYXRlZCBieSB0aGUgRGlhbG9nZmxvdyBzZXJ2ZXIuIElmIHZhbGlkYXRpb24gZmFp
bHMsCiBhbiBlcnJvciB3aWxsIGJlIHJldHVybmVkIGluIHRoZQogW1F1ZXJ5UmVzdWx0LmRp
YWdub3N0aWNfaW5mb11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5RdWVyeVJl
c3VsdC5kaWFnbm9zdGljX2luZm9dCiBmaWVsZC4gU2V0dGluZyBKU09OIGZpZWxkcyB0byBh
biBlbXB0eSB2YWx1ZSB3aXRoIHRoZSB3cm9uZyB0eXBlIGlzIGEgY29tbW9uCiBlcnJvci4g
VG8gYXZvaWQgdGhpcyBlcnJvcjoKCiAtIFVzZSBgIiJgIGZvciBlbXB0eSBzdHJpbmdzCiAt
IFVzZSBge31gIG9yIGBudWxsYCBmb3IgZW1wdHkgb2JqZWN0cwogLSBVc2UgYFtdYCBvciBg
bnVsbGAgZm9yIGVtcHR5IGFycmF5cwoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUgdGhl
CiBbUHJvdG9jb2wgQnVmZmVycyBMYW5ndWFnZQogR3VpZGVdKGh0dHBzOi8vZGV2ZWxvcGVy
cy5nb29nbGUuY29tL3Byb3RvY29sLWJ1ZmZlcnMvZG9jcy9wcm90bzMjanNvbikuCgoKCgME
AQESA1IIFwrSAgoEBAECABIDWAIeGsQCIE9wdGlvbmFsLiBUaGUgdGV4dCByZXNwb25zZSBt
ZXNzYWdlIGludGVuZGVkIGZvciB0aGUgZW5kLXVzZXIuCiBJdCBpcyByZWNvbW1lbmRlZCB0
byB1c2UgYGZ1bGZpbGxtZW50X21lc3NhZ2VzLnRleHQudGV4dFswXWAgaW5zdGVhZC4KIFdo
ZW4gcHJvdmlkZWQsIERpYWxvZ2Zsb3cgdXNlcyB0aGlzIGZpZWxkIHRvIHBvcHVsYXRlCiBb
UXVlcnlSZXN1bHQuZnVsZmlsbG1lbnRfdGV4dF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djJiZXRhMS5RdWVyeVJlc3VsdC5mdWxmaWxsbWVudF90ZXh0XQogc2VudCB0byB0aGUgaW50
ZWdyYXRpb24gb3IgQVBJIGNhbGxlci4KCgwKBQQBAgAFEgNYAggKDAoFBAECAAESA1gJGQoM
CgUEAQIAAxIDWBwdCpQCCgQEAQIBEgNeAjMahgIgT3B0aW9uYWwuIFRoZSByaWNoIHJlc3Bv
bnNlIG1lc3NhZ2VzIGludGVuZGVkIGZvciB0aGUgZW5kLXVzZXIuCiBXaGVuIHByb3ZpZGVk
LCBEaWFsb2dmbG93IHVzZXMgdGhpcyBmaWVsZCB0byBwb3B1bGF0ZQogW1F1ZXJ5UmVzdWx0
LmZ1bGZpbGxtZW50X21lc3NhZ2VzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGEx
LlF1ZXJ5UmVzdWx0LmZ1bGZpbGxtZW50X21lc3NhZ2VzXQogc2VudCB0byB0aGUgaW50ZWdy
YXRpb24gb3IgQVBJIGNhbGxlci4KCgwKBQQBAgEEEgNeAgoKDAoFBAECAQYSA14LGQoMCgUE
AQIBARIDXhouCgwKBQQBAgEDEgNeMTIKqAIKBAQBAgISA2UCFBqaAiBPcHRpb25hbC4gQSBj
dXN0b20gZmllbGQgdXNlZCB0byBpZGVudGlmeSB0aGUgd2ViaG9vayBzb3VyY2UuCiBBcmJp
dHJhcnkgc3RyaW5ncyBhcmUgc3VwcG9ydGVkLgogV2hlbiBwcm92aWRlZCwgRGlhbG9nZmxv
dyB1c2VzIHRoaXMgZmllbGQgdG8gcG9wdWxhdGUKIFtRdWVyeVJlc3VsdC53ZWJob29rX3Nv
dXJjZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5RdWVyeVJlc3VsdC53ZWJo
b29rX3NvdXJjZV0KIHNlbnQgdG8gdGhlIGludGVncmF0aW9uIG9yIEFQSSBjYWxsZXIuCgoM
CgUEAQICBRIDZQIICgwKBQQBAgIBEgNlCQ8KDAoFBAECAgMSA2USEwqSBQoEBAECAxIDcQIl
GoQFIE9wdGlvbmFsLiBUaGlzIGZpZWxkIGNhbiBiZSB1c2VkIHRvIHBhc3MgY3VzdG9tIGRh
dGEgZnJvbSB5b3VyIHdlYmhvb2sgdG8KIHRoZSBpbnRlZ3JhdGlvbiBvciBBUEkgY2FsbGVy
LiBBcmJpdHJhcnkgSlNPTiBvYmplY3RzIGFyZSBzdXBwb3J0ZWQuIFdoZW4KIHByb3ZpZGVk
LCBEaWFsb2dmbG93IHVzZXMgdGhpcyBmaWVsZCB0byBwb3B1bGF0ZQogW1F1ZXJ5UmVzdWx0
LndlYmhvb2tfcGF5bG9hZF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5RdWVy
eVJlc3VsdC53ZWJob29rX3BheWxvYWRdCiBzZW50IHRvIHRoZSBpbnRlZ3JhdGlvbiBvciBB
UEkgY2FsbGVyLiBUaGlzIGZpZWxkIGlzIGFsc28gdXNlZCBieSB0aGUKIFtHb29nbGUgQXNz
aXN0YW50CiBpbnRlZ3JhdGlvbl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zs
b3cvZG9jcy9pbnRlZ3JhdGlvbnMvYW9nKQogZm9yIHJpY2ggcmVzcG9uc2UgbWVzc2FnZXMu
CiBTZWUgdGhlIGZvcm1hdCBkZWZpbml0aW9uIGF0IFtHb29nbGUgQXNzaXN0YW50IERpYWxv
Z2Zsb3cgd2ViaG9vawogZm9ybWF0XShodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9h
c3Npc3RhbnQvYWN0aW9ucy9idWlsZC9qc29uL2RpYWxvZ2Zsb3ctd2ViaG9vay1qc29uKQoK
DAoFBAECAwYSA3ECGAoMCgUEAQIDARIDcRkgCgwKBQQBAgMDEgNxIyQK0AIKBAQBAgQSA3gC
JxrCAiBPcHRpb25hbC4gVGhlIGNvbGxlY3Rpb24gb2Ygb3V0cHV0IGNvbnRleHRzIHRoYXQg
d2lsbCBvdmVyd3JpdGUgY3VycmVudGx5CiBhY3RpdmUgY29udGV4dHMgZm9yIHRoZSBzZXNz
aW9uIGFuZCByZXNldCB0aGVpciBsaWZlc3BhbnMuCiBXaGVuIHByb3ZpZGVkLCBEaWFsb2dm
bG93IHVzZXMgdGhpcyBmaWVsZCB0byBwb3B1bGF0ZQogW1F1ZXJ5UmVzdWx0Lm91dHB1dF9j
b250ZXh0c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5RdWVyeVJlc3VsdC5v
dXRwdXRfY29udGV4dHNdCiBzZW50IHRvIHRoZSBpbnRlZ3JhdGlvbiBvciBBUEkgY2FsbGVy
LgoKDAoFBAECBAQSA3gCCgoMCgUEAQIEBhIDeAsSCgwKBQQBAgQBEgN4EyIKDAoFBAECBAMS
A3glJgqpAQoEBAECBRIDfQImGpsBIE9wdGlvbmFsLiBJbnZva2VzIHRoZSBzdXBwbGllZCBl
dmVudHMuCiBXaGVuIHRoaXMgZmllbGQgaXMgc2V0LCBEaWFsb2dmbG93IGlnbm9yZXMgdGhl
IGBmdWxmaWxsbWVudF90ZXh0YCwKIGBmdWxmaWxsbWVudF9tZXNzYWdlc2AsIGFuZCBgcGF5
bG9hZGAgZmllbGRzLgoKDAoFBAECBQYSA30CDAoMCgUEAQIFARIDfQ0hCgwKBQQBAgUDEgN9
JCUK6gEKBAQBAgYSBIMBAh4a2wEgSW5kaWNhdGVzIHRoYXQgYSBsaXZlIGFnZW50IHNob3Vs
ZCBiZSBicm91Z2h0IGluIHRvIGhhbmRsZSB0aGUKIGludGVyYWN0aW9uIHdpdGggdGhlIHVz
ZXIuIEluIG1vc3QgY2FzZXMsIHdoZW4geW91IHNldCB0aGlzIGZsYWcgdG8gdHJ1ZSwKIHlv
dSB3b3VsZCBhbHNvIHdhbnQgdG8gc2V0IGVuZF9pbnRlcmFjdGlvbiB0byB0cnVlIGFzIHdl
bGwuIERlZmF1bHQgaXMKIGZhbHNlLgoKDQoFBAECBgUSBIMBAgYKDQoFBAECBgESBIMBBxkK
DQoFBAECBgMSBIMBHB0K4gEKBAQBAgcSBIgBAhsa0wEgT3B0aW9uYWwuIEluZGljYXRlcyB0
aGF0IHRoaXMgaW50ZW50IGVuZHMgYW4gaW50ZXJhY3Rpb24uIFNvbWUgaW50ZWdyYXRpb25z
CiAoZS5nLiwgQWN0aW9ucyBvbiBHb29nbGUgb3IgRGlhbG9nZmxvdyBwaG9uZSBnYXRld2F5
KSB1c2UgdGhpcyBpbmZvcm1hdGlvbgogdG8gY2xvc2UgaW50ZXJhY3Rpb24gd2l0aCBhbiBl
bmQgdXNlci4gRGVmYXVsdCBpcyBmYWxzZS4KCg0KBQQBAgcFEgSIAQIGCg0KBQQBAgcBEgSI
AQcWCg0KBQQBAgcDEgSIARkaCp4DCgQEAQIIEgSRAQI3Go8DIE9wdGlvbmFsLiBBZGRpdGlv
bmFsIHNlc3Npb24gZW50aXR5IHR5cGVzIHRvIHJlcGxhY2Ugb3IgZXh0ZW5kIGRldmVsb3Bl
cgogZW50aXR5IHR5cGVzIHdpdGguIFRoZSBlbnRpdHkgc3lub255bXMgYXBwbHkgdG8gYWxs
IGxhbmd1YWdlcyBhbmQgcGVyc2lzdAogZm9yIHRoZSBzZXNzaW9uLiBTZXR0aW5nIHRoaXMg
ZGF0YSBmcm9tIGEgd2ViaG9vayBvdmVyd3JpdGVzCiB0aGUgc2Vzc2lvbiBlbnRpdHkgdHlw
ZXMgdGhhdCBoYXZlIGJlZW4gc2V0IHVzaW5nIGBkZXRlY3RJbnRlbnRgLAogYHN0cmVhbWlu
Z0RldGVjdEludGVudGAgb3IKIFtTZXNzaW9uRW50aXR5VHlwZV1bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjJiZXRhMS5TZXNzaW9uRW50aXR5VHlwZV0KIG1hbmFnZW1lbnQgbWV0aG9k
cy4KCg0KBQQBAggEEgSRAQIKCg0KBQQBAggGEgSRAQscCg0KBQQBAggBEgSRAR0xCg0KBQQB
AggDEgSRATQ2CncKAgQCEgaWAQCuAQEaaSBSZXByZXNlbnRzIHRoZSBjb250ZW50cyBvZiB0
aGUgb3JpZ2luYWwgcmVxdWVzdCB0aGF0IHdhcyBwYXNzZWQgdG8KIHRoZSBgW1N0cmVhbWlu
Z11EZXRlY3RJbnRlbnRgIGNhbGwuCgoLCgMEAgESBJYBCCMKeAoEBAICABIEmQECFBpqIFRo
ZSBzb3VyY2Ugb2YgdGhpcyByZXF1ZXN0LCBlLmcuLCBgZ29vZ2xlYCwgYGZhY2Vib29rYCwg
YHNsYWNrYC4gSXQgaXMgc2V0CiBieSBEaWFsb2dmbG93LW93bmVkIHNlcnZlcnMuCgoNCgUE
AgIABRIEmQECCAoNCgUEAgIAARIEmQEJDwoNCgUEAgIAAxIEmQESEwppCgQEAgIBEgSdAQIV
GlsgT3B0aW9uYWwuIFRoZSB2ZXJzaW9uIG9mIHRoZSBwcm90b2NvbCB1c2VkIGZvciB0aGlz
IHJlcXVlc3QuCiBUaGlzIGZpZWxkIGlzIEFvRy1zcGVjaWZpYy4KCg0KBQQCAgEFEgSdAQII
Cg0KBQQCAgEBEgSdAQkQCg0KBQQCAgEDEgSdARMUCscECgQEAgICEgStAQIlGrgEIE9wdGlv
bmFsLiBUaGlzIGZpZWxkIGlzIHNldCB0byB0aGUgdmFsdWUgb2YgdGhlIGBRdWVyeVBhcmFt
ZXRlcnMucGF5bG9hZGAKIGZpZWxkIHBhc3NlZCBpbiB0aGUgcmVxdWVzdC4gU29tZSBpbnRl
Z3JhdGlvbnMgdGhhdCBxdWVyeSBhIERpYWxvZ2Zsb3cKIGFnZW50IG1heSBwcm92aWRlIGFk
ZGl0aW9uYWwgaW5mb3JtYXRpb24gaW4gdGhlIHBheWxvYWQuCgogSW4gcGFydGljdWxhciwg
Zm9yIHRoZSBEaWFsb2dmbG93IFBob25lIEdhdGV3YXkgaW50ZWdyYXRpb24sIHRoaXMgZmll
bGQgaGFzCiB0aGUgZm9ybToKIDxwcmU+ewogICJ0ZWxlcGhvbnkiOiB7CiAgICAiY2FsbGVy
X2lkIjogIisxODU1ODM2Mzk4NyIKICB9CiB9PC9wcmU+CiBOb3RlOiBUaGUgY2FsbGVyIElE
IGZpZWxkIChgY2FsbGVyX2lkYCkgd2lsbCBiZSByZWRhY3RlZCBmb3IgVHJpYWwKIEVkaXRp
b24gYWdlbnRzIGFuZCBwb3B1bGF0ZWQgd2l0aCB0aGUgY2FsbGVyIElEIGluIFtFLjE2NAog
Zm9ybWF0XShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9FLjE2NCkgZm9yIEVzc2Vu
dGlhbHMgRWRpdGlvbiBhZ2VudHMuCgoNCgUEAgICBhIErQECGAoNCgUEAgICARIErQEZIAoN
CgUEAgICAxIErQEjJGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookRequest ===
    # Fields for WebhookRequest
    # Field: session Type: 9 ()
    # Field: response_id Type: 9 ()
    # Field: query_result Type: 11 (.google.cloud.dialogflow.v2beta1.QueryResult)
    # Field: alternative_query_results Type: 11 (.google.cloud.dialogflow.v2beta1.QueryResult)
    # Field: original_detect_intent_request Type: 11 (.google.cloud.dialogflow.v2beta1.OriginalDetectIntentRequest)

# === Message: Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookResponse ===
    # Fields for WebhookResponse
    # Field: fulfillment_text Type: 9 ()
    # Field: fulfillment_messages Type: 11 (.google.cloud.dialogflow.v2beta1.Intent.Message)
    # Field: source Type: 9 ()
    # Field: payload Type: 11 (.google.protobuf.Struct)
    # Field: output_contexts Type: 11 (.google.cloud.dialogflow.v2beta1.Context)
    # Field: followup_event_input Type: 11 (.google.cloud.dialogflow.v2beta1.EventInput)
    # Field: live_agent_handoff Type: 8 ()
    # Field: end_interaction Type: 8 ()
    # Field: session_entity_types Type: 11 (.google.cloud.dialogflow.v2beta1.SessionEntityType)

# === Message: Google::Cloud::Dialogflow::V2beta1::Webhook::OriginalDetectIntentRequest ===
    # Fields for OriginalDetectIntentRequest
    # Field: source Type: 9 ()
    # Field: version Type: 9 ()
    # Field: payload Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Webhook - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/webhook.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::Webhook;

    my $msg = Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookRequest->new({
        session => $session,
        response_id => $response_id,
        query_result => $query_result,
        alternative_query_results => $alternative_query_results,
    });

    # Read or update a field
    my $val = $msg->session();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/webhook.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookRequest

The request message for a webhook call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session() >> / C<< $msg->session($value) >>

Type: C<String>

The unique identifier of detectIntent request session.
Can be used to identify end-user inside webhook implementation.
Supported formats:
- `projects/<Project ID>/agent/sessions/<Session ID>,
- `projects/<Project ID>/locations/<Location ID>/agent/sessions/<Session
  ID>`,
- `projects/<Project ID>/agent/environments/<Environment ID>/users/<User
  ID>/sessions/<Session ID>`,
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>/users/<User ID>/sessions/<Session
  ID>`,

=item * C<< $msg->response_id() >> / C<< $msg->response_id($value) >>

Type: C<String>

The unique identifier of the response. Contains the same value as
`[Streaming]DetectIntentResponse.response_id`.

=item * C<< $msg->query_result() >> / C<< $msg->query_result($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Session::QueryResult>)

The result of the conversational query or event processing. Contains the
same value as `[Streaming]DetectIntentResponse.query_result`.

=item * C<< $msg->alternative_query_results() >> / C<< $msg->alternative_query_results($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Session::QueryResult>)

Alternative query results from KnowledgeService.

=item * C<< $msg->original_detect_intent_request() >> / C<< $msg->original_detect_intent_request($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Webhook::OriginalDetectIntentRequest>)

Optional. The contents of the original request that was passed to
`[Streaming]DetectIntent` call.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookResponse

The response message for a webhook call.

This response is validated by the Dialogflow server. If validation fails,
an error will be returned in the
[QueryResult.diagnostic_info][google.cloud.dialogflow.v2beta1.QueryResult.diagnostic_info]
field. Setting JSON fields to an empty value with the wrong type is a common
error. To avoid this error:

- Use `""` for empty strings
- Use `{}` or `null` for empty objects
- Use `[]` or `null` for empty arrays

For more information, see the
[Protocol Buffers Language
Guide](https://developers.google.com/protocol-buffers/docs/proto3#json).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fulfillment_text() >> / C<< $msg->fulfillment_text($value) >>

Type: C<String>

Optional. The text response message intended for the end-user.
It is recommended to use `fulfillment_messages.text.text[0]` instead.
When provided, Dialogflow uses this field to populate
[QueryResult.fulfillment_text][google.cloud.dialogflow.v2beta1.QueryResult.fulfillment_text]
sent to the integration or API caller.

=item * C<< $msg->fulfillment_messages() >> / C<< $msg->fulfillment_messages($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Intent::Intent::Message>)

Optional. The rich response messages intended for the end-user.
When provided, Dialogflow uses this field to populate
[QueryResult.fulfillment_messages][google.cloud.dialogflow.v2beta1.QueryResult.fulfillment_messages]
sent to the integration or API caller.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

Optional. A custom field used to identify the webhook source.
Arbitrary strings are supported.
When provided, Dialogflow uses this field to populate
[QueryResult.webhook_source][google.cloud.dialogflow.v2beta1.QueryResult.webhook_source]
sent to the integration or API caller.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. This field can be used to pass custom data from your webhook to
the integration or API caller. Arbitrary JSON objects are supported. When
provided, Dialogflow uses this field to populate
[QueryResult.webhook_payload][google.cloud.dialogflow.v2beta1.QueryResult.webhook_payload]
sent to the integration or API caller. This field is also used by the
[Google Assistant
integration](https://cloud.google.com/dialogflow/docs/integrations/aog)
for rich response messages.
See the format definition at [Google Assistant Dialogflow webhook
format](https://developers.google.com/assistant/actions/build/json/dialogflow-webhook-json)

=item * C<< $msg->output_contexts() >> / C<< $msg->output_contexts($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Context::Context>)

Optional. The collection of output contexts that will overwrite currently
active contexts for the session and reset their lifespans.
When provided, Dialogflow uses this field to populate
[QueryResult.output_contexts][google.cloud.dialogflow.v2beta1.QueryResult.output_contexts]
sent to the integration or API caller.

=item * C<< $msg->followup_event_input() >> / C<< $msg->followup_event_input($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Session::EventInput>)

Optional. Invokes the supplied events.
When this field is set, Dialogflow ignores the `fulfillment_text`,
`fulfillment_messages`, and `payload` fields.

=item * C<< $msg->live_agent_handoff() >> / C<< $msg->live_agent_handoff($value) >>

Type: C<Bool>

Indicates that a live agent should be brought in to handle the
interaction with the user. In most cases, when you set this flag to true,
you would also want to set end_interaction to true as well. Default is
false.

=item * C<< $msg->end_interaction() >> / C<< $msg->end_interaction($value) >>

Type: C<Bool>

Optional. Indicates that this intent ends an interaction. Some integrations
(e.g., Actions on Google or Dialogflow phone gateway) use this information
to close interaction with an end user. Default is false.

=item * C<< $msg->session_entity_types() >> / C<< $msg->session_entity_types($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SessionEntityType::SessionEntityType>)

Optional. Additional session entity types to replace or extend developer
entity types with. The entity synonyms apply to all languages and persist
for the session. Setting this data from a webhook overwrites
the session entity types that have been set using `detectIntent`,
`streamingDetectIntent` or
[SessionEntityType][google.cloud.dialogflow.v2beta1.SessionEntityType]
management methods.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::Webhook::OriginalDetectIntentRequest

Represents the contents of the original request that was passed to
the `[Streaming]DetectIntent` call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

The source of this request, e.g., `google`, `facebook`, `slack`. It is set
by Dialogflow-owned servers.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional. The version of the protocol used for this request.
This field is AoG-specific.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. This field is set to the value of the `QueryParameters.payload`
field passed in the request. Some integrations that query a Dialogflow
agent may provide additional information in the payload.

In particular, for the Dialogflow Phone Gateway integration, this field has
the form:
<pre>{
 "telephony": {
   "caller_id": "+18558363987"
 }
}</pre>
Note: The caller ID field (`caller_id`) will be redacted for Trial
Edition agents and populated with the caller ID in [E.164
format](https://en.wikipedia.org/wiki/E.164) for Essentials Edition agents.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::Webhook::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
