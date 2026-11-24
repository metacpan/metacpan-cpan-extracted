package Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvc2Fhc3BsYXRmb3JtL3NhYXNzZXJ2aWNlbWdtdC92MS9jb21tb24u
cHJvdG8SLGdvb2dsZS5jbG91ZC5zYWFzcGxhdGZvcm0uc2Fhc3NlcnZpY2VtZ210LnYxGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8iaQoJQmx1ZXByaW50EiAKB3BhY2thZ2UYASABKAlCBuBBAeBBBVIH
cGFja2FnZRIbCgZlbmdpbmUYAiABKAlCA+BBA1IGZW5naW5lEh0KB3ZlcnNpb24YAyABKAlC
A+BBA1IHdmVyc2lvbiL9AQoMVW5pdFZhcmlhYmxlEiIKCHZhcmlhYmxlGAEgASgJQgbgQQLg
QQVSCHZhcmlhYmxlElsKBHR5cGUYAiABKA4yPy5nb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3Jt
LnNhYXNzZXJ2aWNlbWdtdC52MS5Vbml0VmFyaWFibGUuVHlwZUIG4EEB4EEFUgR0eXBlEhkK
BXZhbHVlGAMgASgJQgPgQQFSBXZhbHVlIlEKBFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAA
EgoKBlNUUklORxABEgcKA0lOVBACEggKBEJPT0wQAxIKCgZTVFJVQ1QQBBIICgRMSVNUEAUi
lAUKDVVuaXRDb25kaXRpb24SXwoGc3RhdHVzGAEgASgOMkIuZ29vZ2xlLmNsb3VkLnNhYXNw
bGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjEuVW5pdENvbmRpdGlvbi5TdGF0dXNCA+BBAlIG
c3RhdHVzElkKBHR5cGUYAiABKA4yQC5nb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3JtLnNhYXNz
ZXJ2aWNlbWdtdC52MS5Vbml0Q29uZGl0aW9uLlR5cGVCA+BBAlIEdHlwZRJRChRsYXN0X3Ry
YW5zaXRpb25fdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAlIS
bGFzdFRyYW5zaXRpb25UaW1lEh0KB21lc3NhZ2UYBCABKAlCA+BBAlIHbWVzc2FnZRIbCgZy
ZWFzb24YBSABKAlCA+BBAlIGcmVhc29uIlcKBlN0YXR1cxIWChJTVEFUVVNfVU5TUEVDSUZJ
RUQQABISCg5TVEFUVVNfVU5LTk9XThABEg8KC1NUQVRVU19UUlVFEAISEAoMU1RBVFVTX0ZB
TFNFEAMi3gEKBFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEg4KClRZUEVfUkVBRFkQARIR
Cg1UWVBFX1VQREFUSU5HEAISFAoQVFlQRV9QUk9WSVNJT05FRBADEhgKFFRZUEVfT1BFUkFU
SU9OX0VSUk9SEAQSIQodVFlQRV9GTEFHU19DT05GSUdfSU5JVElBTElaRUQQBRImCiJUWVBF
X0FQUF9DUkVBVEVEX09SX0FMUkVBRFlfRVhJU1RTEAYSIgoeVFlQRV9BUFBfQ09NUE9ORU5U
U19SRUdJU1RFUkVEEAcikgUKFlVuaXRPcGVyYXRpb25Db25kaXRpb24SaAoGc3RhdHVzGAEg
ASgOMksuZ29vZ2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjEuVW5p
dE9wZXJhdGlvbkNvbmRpdGlvbi5TdGF0dXNCA+BBAlIGc3RhdHVzEmIKBHR5cGUYAiABKA4y
SS5nb29nbGUuY2xvdWQuc2Fhc3BsYXRmb3JtLnNhYXNzZXJ2aWNlbWdtdC52MS5Vbml0T3Bl
cmF0aW9uQ29uZGl0aW9uLlR5cGVCA+BBAlIEdHlwZRJRChRsYXN0X3RyYW5zaXRpb25fdGlt
ZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAlISbGFzdFRyYW5zaXRp
b25UaW1lEh0KB21lc3NhZ2UYBCABKAlCA+BBAlIHbWVzc2FnZRIbCgZyZWFzb24YBSABKAlC
A+BBAlIGcmVhc29uIlcKBlN0YXR1cxIWChJTVEFUVVNfVU5TUEVDSUZJRUQQABISCg5TVEFU
VVNfVU5LTk9XThABEg8KC1NUQVRVU19UUlVFEAISEAoMU1RBVFVTX0ZBTFNFEAMiwQEKBFR5
cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEhIKDlRZUEVfU0NIRURVTEVEEAISEAoMVFlQRV9S
VU5OSU5HEAMSEgoOVFlQRV9TVUNDRUVERUQQBBISCg5UWVBFX0NBTkNFTExFRBAFEhQKEFRZ
UEVfQVBQX0NSRUFURUQQBhIiCh5UWVBFX0FQUF9DT01QT05FTlRTX1JFR0lTVEVSRUQQBxIb
ChdUWVBFX1dPUktMT0FEX1NVQ0NFRURFRBAIIvgDCg1TYWFzQ29uZGl0aW9uEl8KBnN0YXR1
cxgBIAEoDjJCLmdvb2dsZS5jbG91ZC5zYWFzcGxhdGZvcm0uc2Fhc3NlcnZpY2VtZ210LnYx
LlNhYXNDb25kaXRpb24uU3RhdHVzQgPgQQJSBnN0YXR1cxJZCgR0eXBlGAYgASgOMkAuZ29v
Z2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjEuU2Fhc0NvbmRpdGlv
bi5UeXBlQgPgQQJSBHR5cGUSUQoUbGFzdF90cmFuc2l0aW9uX3RpbWUYAyABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQJSEmxhc3RUcmFuc2l0aW9uVGltZRIdCgdtZXNz
YWdlGAQgASgJQgPgQQJSB21lc3NhZ2USGwoGcmVhc29uGAUgASgJQgPgQQJSBnJlYXNvbiJX
CgZTdGF0dXMSFgoSU1RBVFVTX1VOU1BFQ0lGSUVEEAASEgoOU1RBVFVTX1VOS05PV04QARIP
CgtTVEFUVVNfVFJVRRACEhAKDFNUQVRVU19GQUxTRRADIkMKBFR5cGUSFAoQVFlQRV9VTlNQ
RUNJRklFRBAAEg4KClRZUEVfUkVBRFkQARIVChFUWVBFX1NZTkNIUk9OSVpFRBACIkEKCUFn
Z3JlZ2F0ZRIZCgVncm91cBgBIAEoCUID4EECUgVncm91cBIZCgVjb3VudBgCIAEoBUID4EEC
UgVjb3VudCJmCg5EdXJhdGlvbkxpbWl0cxJUChZ1bml0X29wZXJhdGlvbl90aW1lb3V0GAEg
ASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQFSFHVuaXRPcGVyYXRpb25UaW1l
b3V0KpYBChpVbml0T3BlcmF0aW9uRXJyb3JDYXRlZ29yeRItCilVTklUX09QRVJBVElPTl9F
UlJPUl9DQVRFR09SWV9VTlNQRUNJRklFRBAAEhIKDk5PVF9BUFBMSUNBQkxFEAESCQoFRkFU
QUwQAhINCglSRVRSSUFCTEUQAxINCglJR05PUkFCTEUQBBIMCghTVEFOREFSRBAFQq4CCjBj
b20uZ29vZ2xlLmNsb3VkLnNhYXNwbGF0Zm9ybS5zYWFzc2VydmljZW1nbXQudjFCC0NvbW1v
blByb3RvUAFaWmNsb3VkLmdvb2dsZS5jb20vZ28vc2Fhc3BsYXRmb3JtL3NhYXNzZXJ2aWNl
bWdtdC9hcGl2MS9zYWFzc2VydmljZW1nbXRwYjtzYWFzc2VydmljZW1nbXRwYqoCLEdvb2ds
ZS5DbG91ZC5TYWFzUGxhdGZvcm0uU2Fhc1NlcnZpY2VNZ210LlYxygIsR29vZ2xlXENsb3Vk
XFNhYXNQbGF0Zm9ybVxTYWFzU2VydmljZU1nbXRcVjHqAjBHb29nbGU6OkNsb3VkOjpTYWFz
UGxhdGZvcm06OlNhYXNTZXJ2aWNlTWdtdDo6VjFKj1UKBxIFDgDHAgEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADUKCQoCAwASAxIAKQoJCgIDARIDEwAj
CgkKAgMCEgMUACgKCQoCAwMSAxUAKQoICgEIEgMXAEkKCQoCCCUSAxcASQoICgEIEgMYAHEK
CQoCCAsSAxgAcQoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaACwKCQoCCAgSAxoALAoI
CgEIEgMbAEkKCQoCCAESAxsASQoICgEIEgMcAEoKCQoCCCkSAxwASgoICgEIEgMdAEkKCQoC
CC0SAx0ASQpdCgIFABIEIQA0ARpRIFVuaXRPcGVyYXRpb25FcnJvckNhdGVnb3J5IGRlc2Ny
aWJlcyB0aGUgZXJyb3IgY2F0ZWdvcnkgb2YgdGhlIHVuaXQKIG9wZXJhdGlvbi4KCgoKAwUA
ARIDIQUfCjsKBAUAAgASAyMCMBouIFVuaXQgb3BlcmF0aW9uIGVycm9yIGNhdGVnb3J5IGlz
IHVuc3BlY2lmaWVkCgoMCgUFAAIAARIDIwIrCgwKBQUAAgACEgMjLi8KVQoEBQACARIDJgIV
GkggVW5pdCBvcGVyYXRpb24gZXJyb3IgY2F0ZWdvcnkgaXMgbm90IGFwcGxpY2FibGUsIG9y
IGl0IGlzIG5vdCBhbiBlcnJvcgoKDAoFBQACAQESAyYCEAoMCgUFAAIBAhIDJhMUCjUKBAUA
AgISAykCDBooIFVuaXQgb3BlcmF0aW9uIGVycm9yIGNhdGVnb3J5IGlzIGZhdGFsCgoMCgUF
AAICARIDKQIHCgwKBQUAAgICEgMpCgsKOQoEBQACAxIDLAIQGiwgVW5pdCBvcGVyYXRpb24g
ZXJyb3IgY2F0ZWdvcnkgaXMgcmV0cmlhYmxlCgoMCgUFAAIDARIDLAILCgwKBQUAAgMCEgMs
Dg8KOQoEBQACBBIDLwIQGiwgVW5pdCBvcGVyYXRpb24gZXJyb3IgY2F0ZWdvcnkgaXMgaWdu
b3JhYmxlCgoMCgUFAAIEARIDLwILCgwKBQUAAgQCEgMvDg8KXgoEBQACBRIDMwIPGlEgVW5p
dCBvcGVyYXRpb24gZXJyb3IgY2F0ZWdvcnkgaXMgc3RhbmRhcmQsIGNvdW50cyB0b3dhcmRz
IFJvbGxvdXQgZXJyb3IKIGJ1ZGdldAoKDAoFBQACBQESAzMCCgoMCgUFAAIFAhIDMw0OCvAC
CgIEABIEOwBJARrjAiBCbHVlcHJpbnRzIGFyZSBPQ0kgSW1hZ2VzIHRoYXQgY29udGFpbiBh
bGwgb2YgdGhlIGFydGlmYWN0cyBuZWVkZWQgdG8KIHByb3Zpc2lvbiBhIHVuaXQuIE1ldGFk
YXRhIHN1Y2ggYXMsIHR5cGUgb2YgdGhlIGVuZ2luZSB1c2VkIHRvIGFjdHVhdGUgdGhlCiBi
bHVlcHJpbnQgKFRlcnJhZm9ybSwgZm9yIGV4YW1wbGUpIGFuZCB2ZXJzaW9uIHdpbGwgY29t
ZSBmcm9tIHRoZSBpbWFnZQogbWFuaWZlc3QuIElmIHRoZSBob3N0bmFtZSBpcyBvbWl0dGVk
LCBpdCB3aWxsIGJlIGFzc3VtZWQgdG8gYmUgdGhlIHJlZ2lvbmFsCiBwYXRoIHRvIEFydGlm
YWN0IFJlZ2lzdHJ5IChlZy4gdXMtZWFzdDEtZG9ja2VyLnBrZy5kZXYpLgoKCgoDBAABEgM7
CBEKdwoEBAACABIEPgJBBBppIE9wdGlvbmFsLiBJbW11dGFibGUuIFVSSSB0byBhIGJsdWVw
cmludCB1c2VkIGJ5IHRoZSBVbml0IChyZXF1aXJlZCB1bmxlc3MKIHVuaXRLaW5kIG9yIHJl
bGVhc2UgaXMgc2V0KS4KCgwKBQQAAgAFEgM+AggKDAoFBAACAAESAz4JEAoMCgUEAAIAAxID
PhMUCg0KBQQAAgAIEgQ+FUEDCg8KCAQAAgAInAgAEgM/BCoKDwoIBAACAAicCAESA0AEKwpn
CgQEAAIBEgNFAkAaWiBPdXRwdXQgb25seS4gVHlwZSBvZiB0aGUgZW5naW5lIHVzZWQgdG8g
YWN0dWF0ZSB0aGUgYmx1ZXByaW50LiAoVGVycmFmb3JtLAogZm9yIGV4YW1wbGUpCgoMCgUE
AAIBBRIDRQIICgwKBQQAAgEBEgNFCQ8KDAoFBAACAQMSA0USEwoMCgUEAAIBCBIDRRQ/Cg8K
CAQAAgEInAgAEgNFFT4KSQoEBAACAhIDSAJBGjwgT3V0cHV0IG9ubHkuIFZlcnNpb24gbWV0
YWRhdGEgaWYgcHJlc2VudCBvbiB0aGUgYmx1ZXByaW50LgoKDAoFBAACAgUSA0gCCAoMCgUE
AAICARIDSAkQCgwKBQQAAgIDEgNIExQKDAoFBAACAggSA0gVQAoPCggEAAICCJwIABIDSBY/
CjwKAgQBEgRMAHIBGjAgVW5pdFZhcmlhYmxlIGRlc2NyaWJlcyBhIHBhcmFtZXRlciBmb3Ig
YSBVbml0LgoKCgoDBAEBEgNMCBQKagoEBAEEABIETwJhAxpcIEVudW1lcmF0aW9uIG9mIHZh
cmlhYmxlIHR5cGVzLgogYFNUUlVDVGAgYW5kIGBMSVNUYCB2YWx1ZXMgc2hvdWxkIGJlIEpT
T04tZW5jb2RlZCBzdHJpbmdzLgoKDAoFBAEEAAESA08HCwouCgYEAQQAAgASA1EEGRofIFZh
cmlhYmxlIHR5cGUgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAQQAAgABEgNRBBQKDgoHBAEEAAIA
AhIDURcYCikKBgQBBAACARIDVAQPGhogVmFyaWFibGUgdHlwZSBpcyBzdHJpbmcuCgoOCgcE
AQQAAgEBEgNUBAoKDgoHBAEEAAIBAhIDVA0OCiYKBgQBBAACAhIDVwQMGhcgVmFyaWFibGUg
dHlwZSBpcyBpbnQuCgoOCgcEAQQAAgIBEgNXBAcKDgoHBAEEAAICAhIDVwoLCicKBgQBBAAC
AxIDWgQNGhggVmFyaWFibGUgdHlwZSBpcyBib29sLgoKDgoHBAEEAAIDARIDWgQICg4KBwQB
BAACAwISA1oLDAopCgYEAQQAAgQSA10EDxoaIFZhcmlhYmxlIHR5cGUgaXMgc3RydWN0LgoK
DgoHBAEEAAIEARIDXQQKCg4KBwQBBAACBAISA10NDgonCgYEAQQAAgUSA2AEDRoYIFZhcmlh
YmxlIHR5cGUgaXMgbGlzdC4KCg4KBwQBBAACBQESA2AECAoOCgcEAQQAAgUCEgNgCwwKUQoE
BAECABIEZAJnBBpDIFJlcXVpcmVkLiBJbW11dGFibGUuIE5hbWUgb2YgdGhlIHZhcmlhYmxl
IGZyb20gYWN0dWF0aW9uIGNvbmZpZ3MuCgoMCgUEAQIABRIDZAIICgwKBQQBAgABEgNkCREK
DAoFBAECAAMSA2QUFQoNCgUEAQIACBIEZBZnAwoPCggEAQIACJwIABIDZQQqCg8KCAQBAgAI
nAgBEgNmBCsKbwoEBAECARIEawJuBBphIE9wdGlvbmFsLiBJbW11dGFibGUuIE5hbWUgb2Yg
YSBzdXBwb3J0ZWQgdmFyaWFibGUgdHlwZS4gU3VwcG9ydGVkIHR5cGVzIGFyZQogc3RyaW5n
LCBpbnQsIGJvb2wuCgoMCgUEAQIBBhIDawIGCgwKBQQBAgEBEgNrBwsKDAoFBAECAQMSA2sO
DwoNCgUEAQIBCBIEaxBuAwoPCggEAQIBCJwIABIDbAQqCg8KCAQBAgEInAgBEgNtBCsKPwoE
BAECAhIDcQI8GjIgT3B0aW9uYWwuIFN0cmluZyBlbmNvZGVkIHZhbHVlIGZvciB0aGUgdmFy
aWFibGUuCgoMCgUEAQICBRIDcQIICgwKBQQBAgIBEgNxCQ4KDAoFBAECAgMSA3EREgoMCgUE
AQICCBIDcRM7Cg8KCAQBAgIInAgAEgNxFDoKigEKAgQCEgV2ALQBARp9IFVuaXRDb25kaXRp
b24gZGVzY3JpYmVzIHRoZSBzdGF0dXMgb2YgYW4gVW5pdC4gVW5pdENvbmRpdGlvbiBpcyBp
bmRpdmlkdWFsCiBjb21wb25lbnRzIHRoYXQgY29udHJpYnV0ZSB0byBhbiBvdmVyYWxsIHN0
YXRlLgoKCgoDBAIBEgN2CBUKMwoEBAIEABIFeAKEAQMaJCBFbnVtZXJhdGlvbiBvZiBjb25k
aXRpb24gc3RhdHVzZXMuCgoMCgUEAgQAARIDeAcNCjEKBgQCBAACABIDegQbGiIgQ29uZGl0
aW9uIHN0YXR1cyBpcyB1bnNwZWNpZmllZC4KCg4KBwQCBAACAAESA3oEFgoOCgcEAgQAAgAC
EgN6GRoKJgoGBAIEAAIBEgN9BBcaFyBDb25kaXRpb24gaXMgdW5rbm93bi4KCg4KBwQCBAAC
AQESA30EEgoOCgcEAgQAAgECEgN9FRYKJAoGBAIEAAICEgSAAQQUGhQgQ29uZGl0aW9uIGlz
IHRydWUuCgoPCgcEAgQAAgIBEgSAAQQPCg8KBwQCBAACAgISBIABEhMKJQoGBAIEAAIDEgSD
AQQVGhUgQ29uZGl0aW9uIGlzIGZhbHNlLgoKDwoHBAIEAAIDARIEgwEEEAoPCgcEAgQAAgMC
EgSDARMUCjEKBAQCBAESBocBAqIBAxohIEVudW1lcmF0aW9uIG9mIGNvbmRpdGlvbiB0eXBl
cy4KCg0KBQQCBAEBEgSHAQcLCjAKBgQCBAECABIEiQEEGRogIENvbmRpdGlvbiB0eXBlIGlz
IHVuc3BlY2lmaWVkLgoKDwoHBAIEAQIAARIEiQEEFAoPCgcEAgQBAgACEgSJARcYCioKBgQC
BAECARIEjAEEExoaIENvbmRpdGlvbiB0eXBlIGlzIHJlYWR5LgoKDwoHBAIEAQIBARIEjAEE
DgoPCgcEAgQBAgECEgSMARESCi0KBgQCBAECAhIEjwEEFhodIENvbmRpdGlvbiB0eXBlIGlz
IHVwZGF0aW5nLgoKDwoHBAIEAQICARIEjwEEEQoPCgcEAgQBAgICEgSPARQVCjAKBgQCBAEC
AxIEkgEEGRogIENvbmRpdGlvbiB0eXBlIGlzIHByb3Zpc2lvbmVkLgoKDwoHBAIEAQIDARIE
kgEEFAoPCgcEAgQBAgMCEgSSARcYCngKBgQCBAECBBIElgEEHRpoIENvbmRpdGlvbiB0eXBl
IGlzIG9wZXJhdGlvbkVycm9yLgogVHJ1ZSB3aGVuIHRoZSBsYXN0IHVuaXQgb3BlcmF0aW9u
IGZhaWxzIHdpdGggYSBub24taWdub3JhYmxlIGVycm9yLgoKDwoHBAIEAQIEARIElgEEGAoP
CgcEAgQBAgQCEgSWARscCoYBCgYEAgQBAgUSBJoBBCYadiBDb25kaXRpb24gdHlwZSBpcyBm
bGFnc0NvbmZpZ0luaXRpYWxpemVkLgogVHJ1ZSB3aGVuIHRoZSBmbGFncyBjb25maWd1cmF0
aW9uIGlzIHN5bmNocm9uaXplZCBhbmQgcmVhZHkgdG8gYmUgc2VydmVkLgoKDwoHBAIEAQIF
ARIEmgEEIQoPCgcEAgQBAgUCEgSaASQlCmEKBgQCBAECBhIEngEEKxpRIEluZGljYXRlcyBp
ZiBBcHBIdWIgYXBwIGhhcyBiZWVuIGNyZWF0ZWQgb3IgaWYgQXBwaHViIGFwcCBoYXMgYWxy
ZWFkeQogZXhpc3RlZC4KCg8KBwQCBAECBgESBJ4BBCYKDwoHBAIEAQIGAhIEngEpKgpXCgYE
AgQBAgcSBKEBBCcaRyBJbmRpY2F0ZXMgaWYgc2VydmljZXMgYW5kIHdvcmtsb2FkcyBoYXZl
IGJlZW4gcmVnaXN0ZXJlZCB3aXRoIEFwcEh1Yi4KCg8KBwQCBAECBwESBKEBBCIKDwoHBAIE
AQIHAhIEoQElJgoyCgQEAgIAEgSlAQI9GiQgUmVxdWlyZWQuIFN0YXR1cyBvZiB0aGUgY29u
ZGl0aW9uLgoKDQoFBAICAAYSBKUBAggKDQoFBAICAAESBKUBCQ8KDQoFBAICAAMSBKUBEhMK
DQoFBAICAAgSBKUBFDwKEAoIBAICAAicCAASBKUBFTsKMAoEBAICARIEqAECORoiIFJlcXVp
cmVkLiBUeXBlIG9mIHRoZSBjb25kaXRpb24uCgoNCgUEAgIBBhIEqAECBgoNCgUEAgIBARIE
qAEHCwoNCgUEAgIBAxIEqAEODwoNCgUEAgIBCBIEqAEQOAoQCggEAgIBCJwIABIEqAERNwpZ
CgQEAgICEgarAQKsAS8aSSBSZXF1aXJlZC4gTGFzdCB0aW1lIHRoZSBjb25kaXRpb24gdHJh
bnNpdGVkIGZyb20gb25lIHN0YXR1cyB0byBhbm90aGVyLgoKDQoFBAICAgYSBKsBAhsKDQoF
BAICAgESBKsBHDAKDQoFBAICAgMSBKsBMzQKDQoFBAICAggSBKwBBi4KEAoIBAICAgicCAAS
BKwBBy0KXwoEBAICAxIEsAECPhpRIFJlcXVpcmVkLiBIdW1hbiByZWFkYWJsZSBtZXNzYWdl
IGluZGljYXRpbmcgZGV0YWlscyBhYm91dCB0aGUgbGFzdAogdHJhbnNpdGlvbi4KCg0KBQQC
AgMFEgSwAQIICg0KBQQCAgMBEgSwAQkQCg0KBQQCAgMDEgSwARMUCg0KBQQCAgMIEgSwARU9
ChAKCAQCAgMInAgAEgSwARY8CksKBAQCAgQSBLMBAj0aPSBSZXF1aXJlZC4gQnJpZWYgcmVh
c29uIGZvciB0aGUgY29uZGl0aW9uJ3MgbGFzdCB0cmFuc2l0aW9uLgoKDQoFBAICBAUSBLMB
AggKDQoFBAICBAESBLMBCQ8KDQoFBAICBAMSBLMBEhMKDQoFBAICBAgSBLMBFDwKEAoIBAIC
BAicCAASBLMBFTsKqQEKAgQDEga5AQD4AQEamgEgVW5pdE9wZXJhdGlvbkNvbmRpdGlvbiBk
ZXNjcmliZXMgdGhlIHN0YXR1cyBvZiBhbiBVbml0IE9wZXJhdGlvbi4KIFVuaXRPcGVyYXRp
b25Db25kaXRpb24gaXMgaW5kaXZpZHVhbCBjb21wb25lbnRzIHRoYXQgY29udHJpYnV0ZSB0
byBhbiBvdmVyYWxsCiBzdGF0ZS4KCgsKAwQDARIEuQEIHgo0CgQEAwQAEga7AQLHAQMaJCBF
bnVtZXJhdGlvbiBvZiBjb25kaXRpb24gc3RhdHVzZXMuCgoNCgUEAwQAARIEuwEHDQoyCgYE
AwQAAgASBL0BBBsaIiBDb25kaXRpb24gc3RhdHVzIGlzIHVuc3BlY2lmaWVkLgoKDwoHBAME
AAIAARIEvQEEFgoPCgcEAwQAAgACEgS9ARkaCicKBgQDBAACARIEwAEEFxoXIENvbmRpdGlv
biBpcyB1bmtub3duLgoKDwoHBAMEAAIBARIEwAEEEgoPCgcEAwQAAgECEgTAARUWCiQKBgQD
BAACAhIEwwEEFBoUIENvbmRpdGlvbiBpcyB0cnVlLgoKDwoHBAMEAAICARIEwwEEDwoPCgcE
AwQAAgICEgTDARITCiUKBgQDBAACAxIExgEEFRoVIENvbmRpdGlvbiBpcyBmYWxzZS4KCg8K
BwQDBAACAwESBMYBBBAKDwoHBAMEAAIDAhIExgETFAoxCgQEAwQBEgbKAQLmAQMaISBFbnVt
ZXJhdGlvbiBvZiBjb25kaXRpb24gdHlwZXMuCgoNCgUEAwQBARIEygEHCwowCgYEAwQBAgAS
BMwBBBkaICBDb25kaXRpb24gdHlwZSBpcyB1bnNwZWNpZmllZC4KCg8KBwQDBAECAAESBMwB
BBQKDwoHBAMEAQIAAhIEzAEXGAouCgYEAwQBAgESBM8BBBcaHiBDb25kaXRpb24gdHlwZSBp
cyBzY2hlZHVsZWQuCgoPCgcEAwQBAgEBEgTPAQQSCg8KBwQDBAECAQISBM8BFRYKLAoGBAME
AQICEgTSAQQVGhwgQ29uZGl0aW9uIHR5cGUgaXMgcnVubmluZy4KCg8KBwQDBAECAgESBNIB
BBAKDwoHBAMEAQICAhIE0gETFAouCgYEAwQBAgMSBNUBBBcaHiBDb25kaXRpb24gdHlwZSBp
cyBzdWNjZWVkZWQuCgoPCgcEAwQBAgMBEgTVAQQSCg8KBwQDBAECAwISBNUBFRYKLgoGBAME
AQIEEgTYAQQXGh4gQ29uZGl0aW9uIHR5cGUgaXMgY2FuY2VsbGVkLgoKDwoHBAMEAQIEARIE
2AEEEgoPCgcEAwQBAgQCEgTYARUWCjsKBgQDBAECBRIE2wEEGRorIEluZGljYXRlcyBpZiBB
cHBIdWIgYXBwIGhhcyBiZWVuIGNyZWF0ZWQuCgoPCgcEAwQBAgUBEgTbAQQUCg8KBwQDBAEC
BQISBNsBFxgKVwoGBAMEAQIGEgTeAQQnGkcgSW5kaWNhdGVzIGlmIHNlcnZpY2VzIGFuZCB3
b3JrbG9hZHMgaGF2ZSBiZWVuIHJlZ2lzdGVyZWQgd2l0aCBBcHBIdWIuCgoPCgcEAwQBAgYB
EgTeAQQiCg8KBwQDBAECBgISBN4BJSYKjwIKBgQDBAECBxIE5QEEIBr+ASBJbmRpY2F0ZXMg
aWYgdGhlIFVuaXRPcGVyYXRpb24ncyBjb3JlIHdvcmtsb2FkIGV4ZWN1dGlvbiBjb21wbGV0
ZWQKIHN1Y2Nlc3NmdWxseS4KIFRoZSB3b3JrbG9hZCBpcyB0aGUgY29yZSBleGVjdXRpb24g
b3BlcmF0aW9uIHBlcmZvcm1lZCBmb3IgYQogVW5pdE9wZXJhdGlvbiAoZS5nLiwgcHJvdmlz
aW9uaW5nLCB1cGRhdGluZywgb3IgZGVwcm92aXNpb25pbmcKIHJlc291cmNlcykgZXhjbHVk
aW5nIHBvc3Qtb3BlcmF0aW9uIGNoZWNrcy4KCg8KBwQDBAECBwESBOUBBBsKDwoHBAMEAQIH
AhIE5QEeHwoyCgQEAwIAEgTpAQI9GiQgUmVxdWlyZWQuIFN0YXR1cyBvZiB0aGUgY29uZGl0
aW9uLgoKDQoFBAMCAAYSBOkBAggKDQoFBAMCAAESBOkBCQ8KDQoFBAMCAAMSBOkBEhMKDQoF
BAMCAAgSBOkBFDwKEAoIBAMCAAicCAASBOkBFTsKMAoEBAMCARIE7AECORoiIFJlcXVpcmVk
LiBUeXBlIG9mIHRoZSBjb25kaXRpb24uCgoNCgUEAwIBBhIE7AECBgoNCgUEAwIBARIE7AEH
CwoNCgUEAwIBAxIE7AEODwoNCgUEAwIBCBIE7AEQOAoQCggEAwIBCJwIABIE7AERNwpZCgQE
AwICEgbvAQLwAS8aSSBSZXF1aXJlZC4gTGFzdCB0aW1lIHRoZSBjb25kaXRpb24gdHJhbnNp
dGVkIGZyb20gb25lIHN0YXR1cyB0byBhbm90aGVyLgoKDQoFBAMCAgYSBO8BAhsKDQoFBAMC
AgESBO8BHDAKDQoFBAMCAgMSBO8BMzQKDQoFBAMCAggSBPABBi4KEAoIBAMCAgicCAASBPAB
By0KXwoEBAMCAxIE9AECPhpRIFJlcXVpcmVkLiBIdW1hbiByZWFkYWJsZSBtZXNzYWdlIGlu
ZGljYXRpbmcgZGV0YWlscyBhYm91dCB0aGUgbGFzdAogdHJhbnNpdGlvbi4KCg0KBQQDAgMF
EgT0AQIICg0KBQQDAgMBEgT0AQkQCg0KBQQDAgMDEgT0ARMUCg0KBQQDAgMIEgT0ARU9ChAK
CAQDAgMInAgAEgT0ARY8CksKBAQDAgQSBPcBAj0aPSBSZXF1aXJlZC4gQnJpZWYgcmVhc29u
IGZvciB0aGUgY29uZGl0aW9uJ3MgbGFzdCB0cmFuc2l0aW9uLgoKDQoFBAMCBAUSBPcBAggK
DQoFBAMCBAESBPcBCQ8KDQoFBAMCBAMSBPcBEhMKDQoFBAMCBAgSBPcBFDwKEAoIBAMCBAic
CAASBPcBFTsKPQoCBAQSBvsBAKcCARovIFNhYXNDb25kaXRpb24gZGVzY3JpYmVzIHRoZSBz
dGF0dXMgb2YgYSBTYWFzLgoKCwoDBAQBEgT7AQgVCjQKBAQEBAASBv0BAokCAxokIEVudW1l
cmF0aW9uIG9mIGNvbmRpdGlvbiBzdGF0dXNlcy4KCg0KBQQEBAABEgT9AQcNCjIKBgQEBAAC
ABIE/wEEGxoiIENvbmRpdGlvbiBzdGF0dXMgaXMgdW5zcGVjaWZpZWQuCgoPCgcEBAQAAgAB
EgT/AQQWCg8KBwQEBAACAAISBP8BGRoKJwoGBAQEAAIBEgSCAgQXGhcgQ29uZGl0aW9uIGlz
IHVua25vd24uCgoPCgcEBAQAAgEBEgSCAgQSCg8KBwQEBAACAQISBIICFRYKJAoGBAQEAAIC
EgSFAgQUGhQgQ29uZGl0aW9uIGlzIHRydWUuCgoPCgcEBAQAAgIBEgSFAgQPCg8KBwQEBAAC
AgISBIUCEhMKJQoGBAQEAAIDEgSIAgQVGhUgQ29uZGl0aW9uIGlzIGZhbHNlLgoKDwoHBAQE
AAIDARIEiAIEEAoPCgcEBAQAAgMCEgSIAhMUCjEKBAQEBAESBowCApUCAxohIEVudW1lcmF0
aW9uIG9mIGNvbmRpdGlvbiB0eXBlcy4KCg0KBQQEBAEBEgSMAgcLCjAKBgQEBAECABIEjgIE
GRogIENvbmRpdGlvbiB0eXBlIGlzIHVuc3BlY2lmaWVkLgoKDwoHBAQEAQIAARIEjgIEFAoP
CgcEBAQBAgACEgSOAhcYCioKBgQEBAECARIEkQIEExoaIENvbmRpdGlvbiB0eXBlIGlzIHJl
YWR5LgoKDwoHBAQEAQIBARIEkQIEDgoPCgcEBAQBAgECEgSRAhESCjEKBgQEBAECAhIElAIE
GhohIENvbmRpdGlvbiB0eXBlIGlzIHN5bmNocm9uaXplZC4KCg8KBwQEBAECAgESBJQCBBUK
DwoHBAQEAQICAhIElAIYGQoyCgQEBAIAEgSYAgI9GiQgUmVxdWlyZWQuIFN0YXR1cyBvZiB0
aGUgY29uZGl0aW9uLgoKDQoFBAQCAAYSBJgCAggKDQoFBAQCAAESBJgCCQ8KDQoFBAQCAAMS
BJgCEhMKDQoFBAQCAAgSBJgCFDwKEAoIBAQCAAicCAASBJgCFTsKMAoEBAQCARIEmwICORoi
IFJlcXVpcmVkLiBUeXBlIG9mIHRoZSBjb25kaXRpb24uCgoNCgUEBAIBBhIEmwICBgoNCgUE
BAIBARIEmwIHCwoNCgUEBAIBAxIEmwIODwoNCgUEBAIBCBIEmwIQOAoQCggEBAIBCJwIABIE
mwIRNwpZCgQEBAICEgaeAgKfAi8aSSBSZXF1aXJlZC4gTGFzdCB0aW1lIHRoZSBjb25kaXRp
b24gdHJhbnNpdGVkIGZyb20gb25lIHN0YXR1cyB0byBhbm90aGVyLgoKDQoFBAQCAgYSBJ4C
AhsKDQoFBAQCAgESBJ4CHDAKDQoFBAQCAgMSBJ4CMzQKDQoFBAQCAggSBJ8CBi4KEAoIBAQC
AgicCAASBJ8CBy0KXwoEBAQCAxIEowICPhpRIFJlcXVpcmVkLiBIdW1hbiByZWFkYWJsZSBt
ZXNzYWdlIGluZGljYXRpbmcgZGV0YWlscyBhYm91dCB0aGUgbGFzdAogdHJhbnNpdGlvbi4K
Cg0KBQQEAgMFEgSjAgIICg0KBQQEAgMBEgSjAgkQCg0KBQQEAgMDEgSjAhMUCg0KBQQEAgMI
EgSjAhU9ChAKCAQEAgMInAgAEgSjAhY8CksKBAQEAgQSBKYCAj0aPSBSZXF1aXJlZC4gQnJp
ZWYgcmVhc29uIGZvciB0aGUgY29uZGl0aW9uJ3MgbGFzdCB0cmFuc2l0aW9uLgoKDQoFBAQC
BAUSBKYCAggKDQoFBAQCBAESBKYCCQ8KDQoFBAQCBAMSBKYCEhMKDQoFBAQCBAgSBKYCFDwK
EAoIBAQCBAicCAASBKYCFTsKvwEKAgQFEgasAgCyAgEasAEgUmVwcmVzZW50cyB0aGUgYWdn
cmVnYXRpb24gb2YgYSBzZXQgb2YgcG9wdWxhdGlvbiBvZiBsaWtlIHJlY29yZHMgYnkgYQog
Y2VydGFpbiBncm91cC4gRm9yIGV4YW1wbGUsIGEgY29sbGVjdGlvbiBvZiB1bml0IGNvdW50
cyBjYW4gYmUgYWdncmVnYXRlZCBhbmQKIGdyb3VwZWQgYnkgdGhlaXIgc3RhdGUuCgoLCgME
BQESBKwCCBEKNgoEBAUCABIErgICPBooIFJlcXVpcmVkLiBHcm91cCBieSB3aGljaCB0byBh
Z2dyZWdhdGUuCgoNCgUEBQIABRIErgICCAoNCgUEBQIAARIErgIJDgoNCgUEBQIAAxIErgIR
EgoNCgUEBQIACBIErgITOwoQCggEBQIACJwIABIErgIUOgo5CgQEBQIBEgSxAgI7GisgUmVx
dWlyZWQuIE51bWJlciBvZiByZWNvcmRzIGluIHRoZSBncm91cC4KCg0KBQQFAgEFEgSxAgIH
Cg0KBQQFAgEBEgSxAggNCg0KBQQFAgEDEgSxAhARCg0KBQQFAgEIEgSxAhI6ChAKCAQFAgEI
nAgAEgSxAhM5CskBCgIEBhIGuAIAxwIBGroBIER1cmF0aW9uTGltaXRzIGRlZmluZXMgdGhl
IHRpbWUtcmVsYXRlZCBjb25zdHJhaW50cyBmb3IgYSBVbml0T3BlcmF0aW9uJ3MKIGV4ZWN1
dGlvbi4KIFRoaXMgYWxsb3dzIHVzZXJzIHRvIGNvbnRyb2wgaG93IGxvbmcgYW4gb3BlcmF0
aW9uIGNhbiBydW4gYmVmb3JlIGJlaW5nCiBjYW5jZWxsZWQgYnkgdGhlIHN5c3RlbS4KCgsK
AwQGARIEuAIIFgrUAwoEBAYCABIGxQICxgIvGsMDIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBk
dXJhdGlvbiBhIFVuaXRPcGVyYXRpb24gaXMgYWxsb3dlZCB0byBleGVjdXRlIGluIHRoZQog
UlVOTklORyBzdGF0ZS4KCiAtIE1pbmltdW0gdmFsdWU6IDYwIHNlY29uZHMgKDEgbWludXRl
KQogLSBNYXhpbXVtIHZhbHVlOiA2MDQ4MDAgc2Vjb25kcyAoNyBkYXlzKQoKIElmIHRoaXMg
ZmllbGQgaXMgbm90IHNldCwgb3IgaWYgdGhlIHByb3ZpZGVkIHZhbHVlIGZhbGxzIG91dHNp
ZGUgdGhlCiBhbGxvd2VkIHJhbmdlLCB0aGUgc3lzdGVtIHdpbGwgdXNlIGEgZGVmYXVsdCB0
aW1lb3V0IG9mIDEwODAwIHNlY29uZHMgKDMKIGhvdXJzKS4KCiBVcG9uIGV4Y2VlZGluZyB0
aGlzIHRpbWUgbGltaXQsIHRoZSBVbml0T3BlcmF0aW9uIHdpbGwgYmUgYmVzdC1lZmZvcnQK
IGNhbmNlbGxlZCwgYW5kIGl0cyBzdGF0ZSB3aWxsIGJlIHNldCB0byBGQUlMRUQuCgoNCgUE
BgIABhIExQICGgoNCgUEBgIAARIExQIbMQoNCgUEBgIAAxIExQI0NQoNCgUEBgIACBIExgIG
LgoQCggEBgIACJwIABIExgIHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Blueprint ===
    # Fields for Blueprint
    # Field: package Type: 9 ()
    # Field: engine Type: 9 ()
    # Field: version Type: 9 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitVariable ===
    # Fields for UnitVariable
    # Field: variable Type: 9 ()
    # Field: type Type: 14 (.google.cloud.saasplatform.saasservicemgmt.v1.UnitVariable.Type)
    # Field: value Type: 9 ()

# Enum: UnitVariable::Type
our $UnitVariable_TYPE_UNSPECIFIED = 0;
our $UnitVariable_STRING = 1;
our $UnitVariable_INT = 2;
our $UnitVariable_BOOL = 3;
our $UnitVariable_STRUCT = 4;
our $UnitVariable_LIST = 5;

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitCondition ===
    # Fields for UnitCondition
    # Field: status Type: 14 (.google.cloud.saasplatform.saasservicemgmt.v1.UnitCondition.Status)
    # Field: type Type: 14 (.google.cloud.saasplatform.saasservicemgmt.v1.UnitCondition.Type)
    # Field: last_transition_time Type: 11 (.google.protobuf.Timestamp)
    # Field: message Type: 9 ()
    # Field: reason Type: 9 ()

# Enum: UnitCondition::Status
our $UnitCondition_STATUS_UNSPECIFIED = 0;
our $UnitCondition_STATUS_UNKNOWN = 1;
our $UnitCondition_STATUS_TRUE = 2;
our $UnitCondition_STATUS_FALSE = 3;

# Enum: UnitCondition::Type
our $UnitCondition_TYPE_UNSPECIFIED = 0;
our $UnitCondition_TYPE_READY = 1;
our $UnitCondition_TYPE_UPDATING = 2;
our $UnitCondition_TYPE_PROVISIONED = 3;
our $UnitCondition_TYPE_OPERATION_ERROR = 4;
our $UnitCondition_TYPE_FLAGS_CONFIG_INITIALIZED = 5;
our $UnitCondition_TYPE_APP_CREATED_OR_ALREADY_EXISTS = 6;
our $UnitCondition_TYPE_APP_COMPONENTS_REGISTERED = 7;

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitOperationCondition ===
    # Fields for UnitOperationCondition
    # Field: status Type: 14 (.google.cloud.saasplatform.saasservicemgmt.v1.UnitOperationCondition.Status)
    # Field: type Type: 14 (.google.cloud.saasplatform.saasservicemgmt.v1.UnitOperationCondition.Type)
    # Field: last_transition_time Type: 11 (.google.protobuf.Timestamp)
    # Field: message Type: 9 ()
    # Field: reason Type: 9 ()

# Enum: UnitOperationCondition::Status
our $UnitOperationCondition_STATUS_UNSPECIFIED = 0;
our $UnitOperationCondition_STATUS_UNKNOWN = 1;
our $UnitOperationCondition_STATUS_TRUE = 2;
our $UnitOperationCondition_STATUS_FALSE = 3;

# Enum: UnitOperationCondition::Type
our $UnitOperationCondition_TYPE_UNSPECIFIED = 0;
our $UnitOperationCondition_TYPE_SCHEDULED = 2;
our $UnitOperationCondition_TYPE_RUNNING = 3;
our $UnitOperationCondition_TYPE_SUCCEEDED = 4;
our $UnitOperationCondition_TYPE_CANCELLED = 5;
our $UnitOperationCondition_TYPE_APP_CREATED = 6;
our $UnitOperationCondition_TYPE_APP_COMPONENTS_REGISTERED = 7;
our $UnitOperationCondition_TYPE_WORKLOAD_SUCCEEDED = 8;

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::SaasCondition ===
    # Fields for SaasCondition
    # Field: status Type: 14 (.google.cloud.saasplatform.saasservicemgmt.v1.SaasCondition.Status)
    # Field: type Type: 14 (.google.cloud.saasplatform.saasservicemgmt.v1.SaasCondition.Type)
    # Field: last_transition_time Type: 11 (.google.protobuf.Timestamp)
    # Field: message Type: 9 ()
    # Field: reason Type: 9 ()

# Enum: SaasCondition::Status
our $SaasCondition_STATUS_UNSPECIFIED = 0;
our $SaasCondition_STATUS_UNKNOWN = 1;
our $SaasCondition_STATUS_TRUE = 2;
our $SaasCondition_STATUS_FALSE = 3;

# Enum: SaasCondition::Type
our $SaasCondition_TYPE_UNSPECIFIED = 0;
our $SaasCondition_TYPE_READY = 1;
our $SaasCondition_TYPE_SYNCHRONIZED = 2;

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Aggregate ===
    # Fields for Aggregate
    # Field: group Type: 9 ()
    # Field: count Type: 5 ()

# === Message: Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::DurationLimits ===
    # Fields for DurationLimits
    # Field: unit_operation_timeout Type: 11 (.google.protobuf.Duration)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common - Compiled Protocol Buffers messages for google/cloud/saasplatform/saasservicemgmt/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common;

    my $msg = Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Blueprint->new({
        package => $package,
        engine => $engine,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->package();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Blueprint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/saasplatform/saasservicemgmt/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Blueprint

Blueprints are OCI Images that contain all of the artifacts needed to
provision a unit. Metadata such as, type of the engine used to actuate the
blueprint (Terraform, for example) and version will come from the image
manifest. If the hostname is omitted, it will be assumed to be the regional
path to Artifact Registry (eg. us-east1-docker.pkg.dev).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->package() >> / C<< $msg->package($value) >>

Type: C<String>

Optional. Immutable. URI to a blueprint used by the Unit (required unless
unitKind or release is set).

=item * C<< $msg->engine() >> / C<< $msg->engine($value) >>

Type: C<String>

Output only. Type of the engine used to actuate the blueprint. (Terraform,
for example)

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Output only. Version metadata if present on the blueprint.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitVariable

UnitVariable describes a parameter for a Unit.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->variable() >> / C<< $msg->variable($value) >>

Type: C<String>

Required. Immutable. Name of the variable from actuation configs.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::UnitVariable::Type>)

Optional. Immutable. Name of a supported variable type. Supported types are
string, int, bool.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

Optional. String encoded value for the variable.

=back

=head3 Enum: UnitVariable::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<STRING> => C<1>

=item * C<INT> => C<2>

=item * C<BOOL> => C<3>

=item * C<STRUCT> => C<4>

=item * C<LIST> => C<5>

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitCondition

UnitCondition describes the status of an Unit. UnitCondition is individual
components that contribute to an overall state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::UnitCondition::Status>)

Required. Status of the condition.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::UnitCondition::Type>)

Required. Type of the condition.

=item * C<< $msg->last_transition_time() >> / C<< $msg->last_transition_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Last time the condition transited from one status to another.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Required. Human readable message indicating details about the last
transition.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Required. Brief reason for the condition's last transition.

=back

=head3 Enum: UnitCondition::Status

=over 4

=item * C<STATUS_UNSPECIFIED> => C<0>

=item * C<STATUS_UNKNOWN> => C<1>

=item * C<STATUS_TRUE> => C<2>

=item * C<STATUS_FALSE> => C<3>

=back

=head3 Enum: UnitCondition::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<TYPE_READY> => C<1>

=item * C<TYPE_UPDATING> => C<2>

=item * C<TYPE_PROVISIONED> => C<3>

=item * C<TYPE_OPERATION_ERROR> => C<4>

=item * C<TYPE_FLAGS_CONFIG_INITIALIZED> => C<5>

=item * C<TYPE_APP_CREATED_OR_ALREADY_EXISTS> => C<6>

=item * C<TYPE_APP_COMPONENTS_REGISTERED> => C<7>

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitOperationCondition

UnitOperationCondition describes the status of an Unit Operation.
UnitOperationCondition is individual components that contribute to an overall
state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::UnitOperationCondition::Status>)

Required. Status of the condition.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::UnitOperationCondition::Type>)

Required. Type of the condition.

=item * C<< $msg->last_transition_time() >> / C<< $msg->last_transition_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Last time the condition transited from one status to another.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Required. Human readable message indicating details about the last
transition.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Required. Brief reason for the condition's last transition.

=back

=head3 Enum: UnitOperationCondition::Status

=over 4

=item * C<STATUS_UNSPECIFIED> => C<0>

=item * C<STATUS_UNKNOWN> => C<1>

=item * C<STATUS_TRUE> => C<2>

=item * C<STATUS_FALSE> => C<3>

=back

=head3 Enum: UnitOperationCondition::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<TYPE_SCHEDULED> => C<2>

=item * C<TYPE_RUNNING> => C<3>

=item * C<TYPE_SUCCEEDED> => C<4>

=item * C<TYPE_CANCELLED> => C<5>

=item * C<TYPE_APP_CREATED> => C<6>

=item * C<TYPE_APP_COMPONENTS_REGISTERED> => C<7>

=item * C<TYPE_WORKLOAD_SUCCEEDED> => C<8>

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::SaasCondition

SaasCondition describes the status of a Saas.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::SaasCondition::Status>)

Required. Status of the condition.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::SaasCondition::Type>)

Required. Type of the condition.

=item * C<< $msg->last_transition_time() >> / C<< $msg->last_transition_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Last time the condition transited from one status to another.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Required. Human readable message indicating details about the last
transition.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Required. Brief reason for the condition's last transition.

=back

=head3 Enum: SaasCondition::Status

=over 4

=item * C<STATUS_UNSPECIFIED> => C<0>

=item * C<STATUS_UNKNOWN> => C<1>

=item * C<STATUS_TRUE> => C<2>

=item * C<STATUS_FALSE> => C<3>

=back

=head3 Enum: SaasCondition::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<TYPE_READY> => C<1>

=item * C<TYPE_SYNCHRONIZED> => C<2>

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Aggregate

Represents the aggregation of a set of population of like records by a
certain group. For example, a collection of unit counts can be aggregated and
grouped by their state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->group() >> / C<< $msg->group($value) >>

Type: C<String>

Required. Group by which to aggregate.

=item * C<< $msg->count() >> / C<< $msg->count($value) >>

Type: C<Int32>

Required. Number of records in the group.

=back

=head2 Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::DurationLimits

DurationLimits defines the time-related constraints for a UnitOperation's
execution.
This allows users to control how long an operation can run before being
cancelled by the system.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->unit_operation_timeout() >> / C<< $msg->unit_operation_timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The maximum duration a UnitOperation is allowed to execute in the
RUNNING state.

- Minimum value: 60 seconds (1 minute)
- Maximum value: 604800 seconds (7 days)

If this field is not set, or if the provided value falls outside the
allowed range, the system will use a default timeout of 10800 seconds (3
hours).

Upon exceeding this time limit, the UnitOperation will be best-effort
cancelled, and its state will be set to FAILED.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
