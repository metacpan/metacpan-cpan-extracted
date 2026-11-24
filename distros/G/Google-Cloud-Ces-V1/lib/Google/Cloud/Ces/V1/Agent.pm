package Google::Cloud::Ces::V1::Agent;

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
    eval { require Google::Cloud::Ces::V1::AgentTransfers };
    eval { require Google::Cloud::Ces::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ch9nb29nbGUvY2xvdWQvY2VzL3YxL2FnZW50LnByb3RvEhNnb29nbGUuY2xvdWQuY2VzLnYx
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGilnb29nbGUvY2xvdWQvY2VzL3YxL2FnZW50X3RyYW5zZmVycy5wcm90bxogZ29v
Z2xlL2Nsb3VkL2Nlcy92MS9jb21tb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8i6hMKBUFnZW50EkcKCWxsbV9hZ2VudBgaIAEoCzIjLmdvb2dsZS5jbG91ZC5j
ZXMudjEuQWdlbnQuTGxtQWdlbnRCA+BBAUgAUghsbG1BZ2VudBJvChdyZW1vdGVfZGlhbG9n
Zmxvd19hZ2VudBgbIAEoCzIwLmdvb2dsZS5jbG91ZC5jZXMudjEuQWdlbnQuUmVtb3RlRGlh
bG9nZmxvd0FnZW50QgPgQQFIAFIVcmVtb3RlRGlhbG9nZmxvd0FnZW50EhcKBG5hbWUYASAB
KAlCA+BBCFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUS
JQoLZGVzY3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24STgoObW9kZWxfc2V0dGlu
Z3MYBCABKAsyIi5nb29nbGUuY2xvdWQuY2VzLnYxLk1vZGVsU2V0dGluZ3NCA+BBAVINbW9k
ZWxTZXR0aW5ncxIlCgtpbnN0cnVjdGlvbhgGIAEoCUID4EEBUgtpbnN0cnVjdGlvbhI1CgV0
b29scxgHIAMoCUIf4EEB+kEZChdjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbFIFdG9vbHMSQwoM
Y2hpbGRfYWdlbnRzGAggAygJQiDgQQH6QRoKGGNlcy5nb29nbGVhcGlzLmNvbS9BZ2VudFIL
Y2hpbGRBZ2VudHMSWAoWYmVmb3JlX2FnZW50X2NhbGxiYWNrcxgSIAMoCzIdLmdvb2dsZS5j
bG91ZC5jZXMudjEuQ2FsbGJhY2tCA+BBAVIUYmVmb3JlQWdlbnRDYWxsYmFja3MSVgoVYWZ0
ZXJfYWdlbnRfY2FsbGJhY2tzGBMgAygLMh0uZ29vZ2xlLmNsb3VkLmNlcy52MS5DYWxsYmFj
a0ID4EEBUhNhZnRlckFnZW50Q2FsbGJhY2tzElgKFmJlZm9yZV9tb2RlbF9jYWxsYmFja3MY
FCADKAsyHS5nb29nbGUuY2xvdWQuY2VzLnYxLkNhbGxiYWNrQgPgQQFSFGJlZm9yZU1vZGVs
Q2FsbGJhY2tzElYKFWFmdGVyX21vZGVsX2NhbGxiYWNrcxgVIAMoCzIdLmdvb2dsZS5jbG91
ZC5jZXMudjEuQ2FsbGJhY2tCA+BBAVITYWZ0ZXJNb2RlbENhbGxiYWNrcxJWChViZWZvcmVf
dG9vbF9jYWxsYmFja3MYFiADKAsyHS5nb29nbGUuY2xvdWQuY2VzLnYxLkNhbGxiYWNrQgPg
QQFSE2JlZm9yZVRvb2xDYWxsYmFja3MSVAoUYWZ0ZXJfdG9vbF9jYWxsYmFja3MYFyADKAsy
HS5nb29nbGUuY2xvdWQuY2VzLnYxLkNhbGxiYWNrQgPgQQFSEmFmdGVyVG9vbENhbGxiYWNr
cxJACgtjcmVhdGVfdGltZRgPIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgQIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJECgpndWFyZHJhaWxzGBEgAygJQiTgQQH6QR4K
HGNlcy5nb29nbGVhcGlzLmNvbS9HdWFyZHJhaWxSCmd1YXJkcmFpbHMSEgoEZXRhZxgYIAEo
CVIEZXRhZxJICgh0b29sc2V0cxgcIAMoCzInLmdvb2dsZS5jbG91ZC5jZXMudjEuQWdlbnQu
QWdlbnRUb29sc2V0QgPgQQFSCHRvb2xzZXRzEjAKEWdlbmVyYXRlZF9zdW1tYXJ5GB0gASgJ
QgPgQQNSEGdlbmVyYXRlZFN1bW1hcnkSTQoOdHJhbnNmZXJfcnVsZXMYHiADKAsyIS5nb29n
bGUuY2xvdWQuY2VzLnYxLlRyYW5zZmVyUnVsZUID4EEBUg10cmFuc2ZlclJ1bGVzEjAKEXZh
bGlkYXRpb25fZXJyb3JzGCAgAygJQgPgQQNSEHZhbGlkYXRpb25FcnJvcnMaCgoITGxtQWdl
bnQa5QUKFVJlbW90ZURpYWxvZ2Zsb3dBZ2VudBJHCgVhZ2VudBgBIAEoCUIx4EEC+kErCilk
aWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0RpYWxvZ2Zsb3dBZ2VudFIFYWdlbnQSHAoHZmxv
d19pZBgCIAEoCUID4EEBUgZmbG93SWQSKgoOZW52aXJvbm1lbnRfaWQYAyABKAlCA+BBAVIN
ZW52aXJvbm1lbnRJZBKFAQoWaW5wdXRfdmFyaWFibGVfbWFwcGluZxgEIAMoCzJKLmdvb2ds
ZS5jbG91ZC5jZXMudjEuQWdlbnQuUmVtb3RlRGlhbG9nZmxvd0FnZW50LklucHV0VmFyaWFi
bGVNYXBwaW5nRW50cnlCA+BBAVIUaW5wdXRWYXJpYWJsZU1hcHBpbmcSiAEKF291dHB1dF92
YXJpYWJsZV9tYXBwaW5nGAUgAygLMksuZ29vZ2xlLmNsb3VkLmNlcy52MS5BZ2VudC5SZW1v
dGVEaWFsb2dmbG93QWdlbnQuT3V0cHV0VmFyaWFibGVNYXBwaW5nRW50cnlCA+BBAVIVb3V0
cHV0VmFyaWFibGVNYXBwaW5nElgKJnJlc3BlY3RfcmVzcG9uc2VfaW50ZXJydXB0aW9uX3Nl
dHRpbmdzGAYgASgIQgPgQQFSI3Jlc3BlY3RSZXNwb25zZUludGVycnVwdGlvblNldHRpbmdz
EjkKFmxhbmd1YWdlX2NvZGVfdmFyaWFibGUYByABKAlCA+BBAVIUbGFuZ3VhZ2VDb2RlVmFy
aWFibGUaRwoZSW5wdXRWYXJpYWJsZU1hcHBpbmdFbnRyeRIQCgNrZXkYASABKAlSA2tleRIU
CgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGkgKGk91dHB1dFZhcmlhYmxlTWFwcGluZ0VudHJ5
EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEabAoMQWdlbnRU
b29sc2V0EjwKB3Rvb2xzZXQYASABKAlCIuBBAvpBHAoaY2VzLmdvb2dsZWFwaXMuY29tL1Rv
b2xzZXRSB3Rvb2xzZXQSHgoIdG9vbF9pZHMYBCADKAlCA+BBAVIHdG9vbElkczpv6kFsChhj
ZXMuZ29vZ2xlYXBpcy5jb20vQWdlbnQSQXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9hcHBzL3thcHB9L2FnZW50cy97YWdlbnR9KgZhZ2VudHMyBWFnZW50QgwK
CmFnZW50X3R5cGVCuAEKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQgpBZ2VudFByb3RvUAFa
KWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3Bi6kFjCilkaWFsb2dm
bG93Lmdvb2dsZWFwaXMuY29tL0RpYWxvZ2Zsb3dBZ2VudBI2cHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50cy97YWdlbnR9Sp9QCgcSBQ4A9QEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACkKCQoC
AwESAxMAIwoJCgIDAhIDFAAzCgkKAgMDEgMVACoKCQoCAwQSAxYAKQoICgEIEgMYAEAKCQoC
CAsSAxgAQAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaACsKCQoCCAgSAxoAKwoICgEI
EgMbADAKCQoCCAESAxsAMAoJCgEIEgQcAB8CCgwKBAidCAASBBwAHwIKmwEKAgQAEgUjAPUB
ARqNASBBbiBhZ2VudCBhY3RzIGFzIHRoZSBmdW5kYW1lbnRhbCBidWlsZGluZyBibG9jayB0
aGF0IHByb3ZpZGVzIGluc3RydWN0aW9ucyB0bwogdGhlIExhcmdlIExhbmd1YWdlIE1vZGVs
IChMTE0pIGZvciBleGVjdXRpbmcgc3BlY2lmaWMgdGFza3MuCgoKCgMEAAESAyMIDQoLCgME
AAcSBCQCKQQKDQoFBAAHnQgSBCQCKQQKlwEKBAQAAwASAy0CFRqJASBEZWZhdWx0IGFnZW50
IHR5cGUuIFRoZSBhZ2VudCB1c2VzIGluc3RydWN0aW9ucyBhbmQgY2FsbGJhY2tzIHNwZWNp
ZmllZCBpbgogdGhlIGFnZW50IHRvIHBlcmZvcm0gdGhlIHRhc2sgdXNpbmcgYSBsYXJnZSBs
YW5ndWFnZSBtb2RlbC4KCgwKBQQAAwABEgMtChIKvAIKBAQAAwESBDUCYwMarQIgVGhlIGFn
ZW50IHdoaWNoIHdpbGwgdHJhbnNmZXIgZXhlY3V0aW9uIHRvIGEgcmVtb3RlCiBbRGlhbG9n
ZmxvdwogQ1hdKGh0dHBzOi8vZG9jcy5jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvY3gv
ZG9jcy9jb25jZXB0L2FnZW50KSBhZ2VudC4KIFRoZSBEaWFsb2dmbG93IGFnZW50IHdpbGwg
cHJvY2VzcyBzdWJzZXF1ZW50IHVzZXIgcXVlcmllcyB1bnRpbCB0aGUgc2Vzc2lvbgogZW5k
cyBvciBmbG93IGVuZHMsIGFuZCB0aGUgY29udHJvbCBpcyB0cmFuc2ZlcnJlZCBiYWNrIHRv
IHRoZSBwYXJlbnQgQ0VTCiBhZ2VudC4KCgwKBQQAAwEBEgM1Ch8KxgEKBgQAAwECABIEOgQ/
Bhq1ASBSZXF1aXJlZC4gVGhlCiBbRGlhbG9nZmxvd10oaHR0cHM6Ly9kb2NzLmNsb3VkLmdv
b2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2NvbmNlcHQvYWdlbnQpCiBhZ2VudCByZXNv
dXJjZSBuYW1lLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2FnZW50cy97YWdlbnR9YAoKDgoHBAADAQIABRIDOgQKCg4KBwQAAwECAAESAzoL
EAoOCgcEAAMBAgADEgM6ExQKDwoHBAADAQIACBIEOhU/BQoRCgoEAAMBAgAInAgAEgM7BiwK
EQoJBAADAQIACJ8IEgQ8Bj4HCksKBgQAAwECARIDQgRAGjwgT3B0aW9uYWwuIFRoZSBmbG93
IElEIG9mIHRoZSBmbG93IGluIHRoZSBEaWFsb2dmbG93IGFnZW50LgoKDgoHBAADAQIBBRID
QgQKCg4KBwQAAwECAQESA0ILEgoOCgcEAAMBAgEDEgNCFRYKDgoHBAADAQIBCBIDQhc/ChEK
CgQAAwECAQicCAASA0IYPgqhAQoGBAADAQICEgNGBEcakQEgT3B0aW9uYWwuIFRoZSBlbnZp
cm9ubWVudCBJRCBvZiB0aGUgRGlhbG9nZmxvdyBhZ2VudCB0byBiZSB1c2VkIGZvciB0aGUK
IGFnZW50IGV4ZWN1dGlvbi4gSWYgbm90IHNwZWNpZmllZCwgdGhlIGRyYWZ0IGVudmlyb25t
ZW50IHdpbGwgYmUgdXNlZC4KCg4KBwQAAwECAgUSA0YECgoOCgcEAAMBAgIBEgNGCxkKDgoH
BAADAQICAxIDRhwdCg4KBwQAAwECAggSA0YeRgoRCgoEAAMBAgIInAgAEgNGH0UKnAEKBgQA
AwECAxIESgRLMRqLASBPcHRpb25hbC4gVGhlIG1hcHBpbmcgb2YgdGhlIGFwcCB2YXJpYWJs
ZXMgbmFtZXMgdG8gdGhlIERpYWxvZ2Zsb3cKIHNlc3Npb24gcGFyYW1ldGVycyBuYW1lcyB0
byBiZSBzZW50IHRvIHRoZSBEaWFsb2dmbG93IGFnZW50IGFzIGlucHV0LgoKDgoHBAADAQID
BhIDSgQXCg4KBwQAAwECAwESA0oYLgoOCgcEAAMBAgMDEgNKMTIKDgoHBAADAQIDCBIDSwgw
ChEKCgQAAwECAwicCAASA0sJLwq8AQoGBAADAQIEEgRQBFExGqsBIE9wdGlvbmFsLiBUaGUg
bWFwcGluZyBvZiB0aGUgRGlhbG9nZmxvdyBzZXNzaW9uIHBhcmFtZXRlcnMgbmFtZXMgdG8g
dGhlCiBhcHAgdmFyaWFibGVzIG5hbWVzIHRvIGJlIHNlbnQgYmFjayB0byB0aGUgQ0VTIGFn
ZW50IGFmdGVyIHRoZSBEaWFsb2dmbG93CiBhZ2VudCBleGVjdXRpb24gZW5kcy4KCg4KBwQA
AwECBAYSA1AEFwoOCgcEAAMBAgQBEgNQGC8KDgoHBAADAQIEAxIDUDIzCg4KBwQAAwECBAgS
A1EIMAoRCgoEAAMBAgQInAgAEgNRCS8K+QMKBgQAAwECBRIEXARdMRroAyBPcHRpb25hbC4g
SW5kaWNhdGVzIHdoZXRoZXIgdG8gcmVzcGVjdCB0aGUgbWVzc2FnZS1sZXZlbCBpbnRlcnJ1
cHRpb24KIHNldHRpbmdzIGNvbmZpZ3VyZWQgaW4gdGhlIERpYWxvZ2Zsb3cgYWdlbnQuCgog
KiBJZiBmYWxzZTogYWxsIHJlc3BvbnNlIG1lc3NhZ2VzIGZyb20gdGhlIERpYWxvZ2Zsb3cg
YWdlbnQgZm9sbG93IHRoZQogYXBwLWxldmVsIGJhcmdlLWluIHNldHRpbmdzLgogKiBJZiB0
cnVlOiBvbmx5IHJlc3BvbnNlIG1lc3NhZ2VzIHdpdGgKIFtgYWxsb3dfcGxheWJhY2tfaW50
ZXJydXB0aW9uYF0oaHR0cHM6Ly9kb2NzLmNsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9j
eC9kb2NzL3JlZmVyZW5jZS9ycGMvZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMjdGV4
dCkKIHNldCB0byB0cnVlIHdpbGwgYmUgaW50ZXJydXB0YWJsZSwgYWxsIG90aGVyIG1lc3Nh
Z2VzIGZvbGxvdyB0aGUKIGFwcC1sZXZlbCBiYXJnZS1pbiBzZXR0aW5ncy4KCg4KBwQAAwEC
BQUSA1wECAoOCgcEAAMBAgUBEgNcCS8KDgoHBAADAQIFAxIDXDIzCg4KBwQAAwECBQgSA10I
MAoRCgoEAAMBAgUInAgAEgNdCS8KzQEKBgQAAwECBhIDYgRPGr0BIE9wdGlvbmFsLiBUaGUg
bmFtZSBvZiB0aGUgdmFyaWFibGUgdGhhdCBjb250YWlucyB0aGUgbGFuZ3VhZ2UgY29kZSB0
byBiZQogdXNlZCBmb3IgdGhlIERpYWxvZ2Zsb3cgc2Vzc2lvbi4gSWYgdW5zcGVjaWZpZWQs
IHRoZSBkZWZhdWx0IGxhbmd1YWdlCiBjb2RlIG9mIHRoZSBEaWFsb2dmbG93IGFnZW50IHdp
bGwgYmUgdXNlZC4KCg4KBwQAAwECBgUSA2IECgoOCgcEAAMBAgYBEgNiCyEKDgoHBAADAQIG
AxIDYiQlCg4KBwQAAwECBggSA2ImTgoRCgoEAAMBAgYInAgAEgNiJ00KOAoEBAADAhIEZgJx
AxoqIEEgdG9vbHNldCB3aXRoIGEgc2VsZWN0aW9uIG9mIGl0cyB0b29scy4KCgwKBQQAAwIB
EgNmChYKjwEKBgQAAwICABIEagRtBhp/IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgdG9vbHNldC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vYXBwcy97YXBwfS90b29sc2V0cy97dG9vbHNldH1gCgoOCgcEAAMCAgAF
EgNqBAoKDgoHBAADAgIAARIDagsSCg4KBwQAAwICAAMSA2oVFgoPCgcEAAMCAgAIEgRqF20F
ChEKCgQAAwICAAicCAASA2sGLAoQCgkEAAMCAgAInwgSA2wGTgo/CgYEAAMCAgESA3AEShow
IE9wdGlvbmFsLiBUaGUgdG9vbHMgSURzIHRvIGZpbHRlciB0aGUgdG9vbHNldC4KCg4KBwQA
AwICAQQSA3AEDAoOCgcEAAMCAgEFEgNwDRMKDgoHBAADAgIBARIDcBQcCg4KBwQAAwICAQMS
A3AfIAoOCgcEAAMCAgEIEgNwIUkKEQoKBAADAgIBCJwIABIDcCJICiMKBAQACAASBXQCggED
GhQgVGhlIHR5cGUgb2YgYWdlbnQuCgoMCgUEAAgAARIDdAgSCjAKBAQAAgASA3YERRojIE9w
dGlvbmFsLiBUaGUgZGVmYXVsdCBhZ2VudCB0eXBlLgoKDAoFBAACAAYSA3YEDAoMCgUEAAIA
ARIDdg0WCgwKBQQAAgADEgN2GRsKDAoFBAACAAgSA3YcRAoPCggEAAIACJwIABIDdh1DCskD
CgQEAAIBEgaAAQSBATEauAMgT3B0aW9uYWwuIFRoZSByZW1vdGUKIFtEaWFsb2dmbG93XSho
dHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2NvbmNlcHQvY29u
c29sZS1jb252ZXJzYXRpb25hbC1hZ2VudHMpCiBhZ2VudCB0byBiZSB1c2VkIGZvciB0aGUg
YWdlbnQgZXhlY3V0aW9uLiBJZiB0aGlzIGZpZWxkIGlzIHNldCwgYWxsIG90aGVyCiBhZ2Vu
dCBsZXZlbCBwcm9wZXJ0aWVzIHdpbGwgYmUgaWdub3JlZC4KCiBOb3RlOiBJZiB0aGUgRGlh
bG9nZmxvdyBhZ2VudCBpcyBpbiBhIGRpZmZlcmVudCBwcm9qZWN0IGZyb20gdGhlIGFwcCwg
eW91CiBzaG91bGQgZ3JhbnQgYHJvbGVzL2RpYWxvZ2Zsb3cuY2xpZW50YCB0byB0aGUgQ0VT
IHNlcnZpY2UgYWdlbnQKIGBzZXJ2aWNlLTxQUk9KRUNULU5VTUJFUj5AZ2NwLXNhLWNlcy5p
YW0uZ3NlcnZpY2VhY2NvdW50LmNvbWAuCgoNCgUEAAIBBhIEgAEEGQoNCgUEAAIBARIEgAEa
MQoNCgUEAAIBAxIEgAE0NgoNCgUEAAIBCBIEgQEIMAoQCggEAAIBCJwIABIEgQEJLwqMAQoE
BAACAhIEhgECPRp+IElkZW50aWZpZXIuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUg
YWdlbnQuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYXBwcy97YXBwfS9hZ2VudHMve2FnZW50fWAKCg0KBQQAAgIFEgSGAQIICg0KBQQAAgIB
EgSGAQkNCg0KBQQAAgIDEgSGARARCg0KBQQAAgIIEgSGARI8ChAKCAQAAgIInAgAEgSGARM7
CjQKBAQAAgMSBIkBAkMaJiBSZXF1aXJlZC4gRGlzcGxheSBuYW1lIG9mIHRoZSBhZ2VudC4K
Cg0KBQQAAgMFEgSJAQIICg0KBQQAAgMBEgSJAQkVCg0KBQQAAgMDEgSJARgZCg0KBQQAAgMI
EgSJARpCChAKCAQAAgMInAgAEgSJARtBCkIKBAQAAgQSBIwBAkIaNCBPcHRpb25hbC4gSHVt
YW4tcmVhZGFibGUgZGVzY3JpcHRpb24gb2YgdGhlIGFnZW50LgoKDQoFBAACBAUSBIwBAggK
DQoFBAACBAESBIwBCRQKDQoFBAACBAMSBIwBFxgKDQoFBAACBAgSBIwBGUEKEAoIBAACBAic
CAASBIwBGkAKOwoEBAACBRIEjwECTBotIE9wdGlvbmFsLiBDb25maWd1cmF0aW9ucyBmb3Ig
dGhlIExMTSBtb2RlbC4KCg0KBQQAAgUGEgSPAQIPCg0KBQQAAgUBEgSPARAeCg0KBQQAAgUD
EgSPASEiCg0KBQQAAgUIEgSPASNLChAKCAQAAgUInAgAEgSPASRKClcKBAQAAgYSBJIBAkIa
SSBPcHRpb25hbC4gSW5zdHJ1Y3Rpb25zIGZvciB0aGUgTExNIG1vZGVsIHRvIGd1aWRlIHRo
ZSBhZ2VudCdzIGJlaGF2aW9yLgoKDQoFBAACBgUSBJIBAggKDQoFBAACBgESBJIBCRQKDQoF
BAACBgMSBJIBFxgKDQoFBAACBggSBJIBGUEKEAoIBAACBgicCAASBJIBGkAKjQEKBAQAAgcS
BpYBApkBBBp9IE9wdGlvbmFsLiBMaXN0IG9mIGF2YWlsYWJsZSB0b29scyBmb3IgdGhlIGFn
ZW50LgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2FwcHMve2FwcH0vdG9vbHMve3Rvb2x9YAoKDQoFBAACBwQSBJYBAgoKDQoFBAACBwUSBJYB
CxEKDQoFBAACBwESBJYBEhcKDQoFBAACBwMSBJYBGhsKDwoFBAACBwgSBpYBHJkBAwoQCggE
AAIHCJwIABIElwEEKgoPCgcEAAIHCJ8IEgSYAQRJCpEBCgQEAAIIEgadAQKgAQQagAEgT3B0
aW9uYWwuIExpc3Qgb2YgY2hpbGQgYWdlbnRzIGluIHRoZSBhZ2VudCB0cmVlLgogRm9ybWF0
OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0v
YWdlbnRzL3thZ2VudH1gCgoNCgUEAAIIBBIEnQECCgoNCgUEAAIIBRIEnQELEQoNCgUEAAII
ARIEnQESHgoNCgUEAAIIAxIEnQEhIgoPCgUEAAIICBIGnQEjoAEDChAKCAQAAggInAgAEgSe
AQQqCg8KBwQAAggInwgSBJ8BBEoKmwIKBAQAAgkSBqYBAqcBLxqKAiBPcHRpb25hbC4gVGhl
IGNhbGxiYWNrcyB0byBleGVjdXRlIGJlZm9yZSB0aGUgYWdlbnQgaXMgY2FsbGVkLgogVGhl
IHByb3ZpZGVkIGNhbGxiYWNrcyBhcmUgZXhlY3V0ZWQgc2VxdWVudGlhbGx5IGluIHRoZSBl
eGFjdCBvcmRlciB0aGV5CiBhcmUgZ2l2ZW4gaW4gdGhlIGxpc3QuIElmIGEgY2FsbGJhY2sg
cmV0dXJucyBhbiBvdmVycmlkZGVuIHJlc3BvbnNlLAogZXhlY3V0aW9uIHN0b3BzIGFuZCBh
bnkgcmVtYWluaW5nIGNhbGxiYWNrcyBhcmUgc2tpcHBlZC4KCg0KBQQAAgkEEgSmAQIKCg0K
BQQAAgkGEgSmAQsTCg0KBQQAAgkBEgSmARQqCg0KBQQAAgkDEgSmAS0vCg0KBQQAAgkIEgSn
AQYuChAKCAQAAgkInAgAEgSnAQctCpoCCgQEAAIKEgatAQKuAS8aiQIgT3B0aW9uYWwuIFRo
ZSBjYWxsYmFja3MgdG8gZXhlY3V0ZSBhZnRlciB0aGUgYWdlbnQgaXMgY2FsbGVkLgogVGhl
IHByb3ZpZGVkIGNhbGxiYWNrcyBhcmUgZXhlY3V0ZWQgc2VxdWVudGlhbGx5IGluIHRoZSBl
eGFjdCBvcmRlciB0aGV5CiBhcmUgZ2l2ZW4gaW4gdGhlIGxpc3QuIElmIGEgY2FsbGJhY2sg
cmV0dXJucyBhbiBvdmVycmlkZGVuIHJlc3BvbnNlLAogZXhlY3V0aW9uIHN0b3BzIGFuZCBh
bnkgcmVtYWluaW5nIGNhbGxiYWNrcyBhcmUgc2tpcHBlZC4KCg0KBQQAAgoEEgStAQIKCg0K
BQQAAgoGEgStAQsTCg0KBQQAAgoBEgStARQpCg0KBQQAAgoDEgStASwuCg0KBQQAAgoIEgSu
AQYuChAKCAQAAgoInAgAEgSuAQctCvQCCgQEAAILEga1AQK2AS8a4wIgT3B0aW9uYWwuIFRo
ZSBjYWxsYmFja3MgdG8gZXhlY3V0ZSBiZWZvcmUgdGhlIG1vZGVsIGlzIGNhbGxlZC4gSWYg
dGhlcmUgYXJlCiBtdWx0aXBsZSBjYWxscyB0byB0aGUgbW9kZWwsIHRoZSBjYWxsYmFjayB3
aWxsIGJlIGV4ZWN1dGVkIG11bHRpcGxlIHRpbWVzLgogVGhlIHByb3ZpZGVkIGNhbGxiYWNr
cyBhcmUgZXhlY3V0ZWQgc2VxdWVudGlhbGx5IGluIHRoZSBleGFjdCBvcmRlciB0aGV5CiBh
cmUgZ2l2ZW4gaW4gdGhlIGxpc3QuIElmIGEgY2FsbGJhY2sgcmV0dXJucyBhbiBvdmVycmlk
ZGVuIHJlc3BvbnNlLAogZXhlY3V0aW9uIHN0b3BzIGFuZCBhbnkgcmVtYWluaW5nIGNhbGxi
YWNrcyBhcmUgc2tpcHBlZC4KCg0KBQQAAgsEEgS1AQIKCg0KBQQAAgsGEgS1AQsTCg0KBQQA
AgsBEgS1ARQqCg0KBQQAAgsDEgS1AS0vCg0KBQQAAgsIEgS2AQYuChAKCAQAAgsInAgAEgS2
AQctCvMCCgQEAAIMEga9AQK+AS8a4gIgT3B0aW9uYWwuIFRoZSBjYWxsYmFja3MgdG8gZXhl
Y3V0ZSBhZnRlciB0aGUgbW9kZWwgaXMgY2FsbGVkLiBJZiB0aGVyZSBhcmUKIG11bHRpcGxl
IGNhbGxzIHRvIHRoZSBtb2RlbCwgdGhlIGNhbGxiYWNrIHdpbGwgYmUgZXhlY3V0ZWQgbXVs
dGlwbGUgdGltZXMuCiBUaGUgcHJvdmlkZWQgY2FsbGJhY2tzIGFyZSBleGVjdXRlZCBzZXF1
ZW50aWFsbHkgaW4gdGhlIGV4YWN0IG9yZGVyIHRoZXkKIGFyZSBnaXZlbiBpbiB0aGUgbGlz
dC4gSWYgYSBjYWxsYmFjayByZXR1cm5zIGFuIG92ZXJyaWRkZW4gcmVzcG9uc2UsCiBleGVj
dXRpb24gc3RvcHMgYW5kIGFueSByZW1haW5pbmcgY2FsbGJhY2tzIGFyZSBza2lwcGVkLgoK
DQoFBAACDAQSBL0BAgoKDQoFBAACDAYSBL0BCxMKDQoFBAACDAESBL0BFCkKDQoFBAACDAMS
BL0BLC4KDQoFBAACDAgSBL4BBi4KEAoIBAACDAicCAASBL4BBy0K8gIKBAQAAg0SBsUBAsYB
LxrhAiBPcHRpb25hbC4gVGhlIGNhbGxiYWNrcyB0byBleGVjdXRlIGJlZm9yZSB0aGUgdG9v
bCBpcyBpbnZva2VkLiBJZiB0aGVyZSBhcmUKIG11bHRpcGxlIHRvb2wgaW52b2NhdGlvbnMs
IHRoZSBjYWxsYmFjayB3aWxsIGJlIGV4ZWN1dGVkIG11bHRpcGxlIHRpbWVzLgogVGhlIHBy
b3ZpZGVkIGNhbGxiYWNrcyBhcmUgZXhlY3V0ZWQgc2VxdWVudGlhbGx5IGluIHRoZSBleGFj
dCBvcmRlciB0aGV5CiBhcmUgZ2l2ZW4gaW4gdGhlIGxpc3QuIElmIGEgY2FsbGJhY2sgcmV0
dXJucyBhbiBvdmVycmlkZGVuIHJlc3BvbnNlLAogZXhlY3V0aW9uIHN0b3BzIGFuZCBhbnkg
cmVtYWluaW5nIGNhbGxiYWNrcyBhcmUgc2tpcHBlZC4KCg0KBQQAAg0EEgTFAQIKCg0KBQQA
Ag0GEgTFAQsTCg0KBQQAAg0BEgTFARQpCg0KBQQAAg0DEgTFASwuCg0KBQQAAg0IEgTGAQYu
ChAKCAQAAg0InAgAEgTGAQctCvECCgQEAAIOEgbNAQLOAS8a4AIgT3B0aW9uYWwuIFRoZSBj
YWxsYmFja3MgdG8gZXhlY3V0ZSBhZnRlciB0aGUgdG9vbCBpcyBpbnZva2VkLiBJZiB0aGVy
ZSBhcmUKIG11bHRpcGxlIHRvb2wgaW52b2NhdGlvbnMsIHRoZSBjYWxsYmFjayB3aWxsIGJl
IGV4ZWN1dGVkIG11bHRpcGxlIHRpbWVzLgogVGhlIHByb3ZpZGVkIGNhbGxiYWNrcyBhcmUg
ZXhlY3V0ZWQgc2VxdWVudGlhbGx5IGluIHRoZSBleGFjdCBvcmRlciB0aGV5CiBhcmUgZ2l2
ZW4gaW4gdGhlIGxpc3QuIElmIGEgY2FsbGJhY2sgcmV0dXJucyBhbiBvdmVycmlkZGVuIHJl
c3BvbnNlLAogZXhlY3V0aW9uIHN0b3BzIGFuZCBhbnkgcmVtYWluaW5nIGNhbGxiYWNrcyBh
cmUgc2tpcHBlZC4KCg0KBQQAAg4EEgTNAQIKCg0KBQQAAg4GEgTNAQsTCg0KBQQAAg4BEgTN
ARQoCg0KBQQAAg4DEgTNASstCg0KBQQAAg4IEgTOAQYuChAKCAQAAg4InAgAEgTOAQctCkQK
BAQAAg8SBtEBAtIBMho0IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGUgYWdlbnQg
d2FzIGNyZWF0ZWQuCgoNCgUEAAIPBhIE0QECGwoNCgUEAAIPARIE0QEcJwoNCgUEAAIPAxIE
0QEqLAoNCgUEAAIPCBIE0gEGMQoQCggEAAIPCJwIABIE0gEHMApJCgQEAAIQEgbVAQLWATIa
OSBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIGFnZW50IHdhcyBsYXN0IHVwZGF0
ZWQuCgoNCgUEAAIQBhIE1QECGwoNCgUEAAIQARIE1QEcJwoNCgUEAAIQAxIE1QEqLAoNCgUE
AAIQCBIE1gEGMQoQCggEAAIQCJwIABIE1gEHMAqUAQoEBAACERIG2wEC3gEEGoMBIE9wdGlv
bmFsLiBMaXN0IG9mIGd1YXJkcmFpbHMgZm9yIHRoZSBhZ2VudC4KIEZvcm1hdDoKIGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS9ndWFyZHJh
aWxzL3tndWFyZHJhaWx9YAoKDQoFBAACEQQSBNsBAgoKDQoFBAACEQUSBNsBCxEKDQoFBAAC
EQESBNsBEhwKDQoFBAACEQMSBNsBHyEKDwoFBAACEQgSBtsBIt4BAwoQCggEAAIRCJwIABIE
3AEEKgoPCgcEAAIRCJ8IEgTdAQROCq4BCgQEAAISEgTjAQITGp8BIEV0YWcgdXNlZCB0byBl
bnN1cmUgdGhlIG9iamVjdCBoYXNuJ3QgY2hhbmdlZCBkdXJpbmcgYSByZWFkLW1vZGlmeS13
cml0ZQogb3BlcmF0aW9uLiBJZiB0aGUgZXRhZyBpcyBlbXB0eSwgdGhlIHVwZGF0ZSB3aWxs
IG92ZXJ3cml0ZSBhbnkgY29uY3VycmVudAogY2hhbmdlcy4KCg0KBQQAAhIFEgTjAQIICg0K
BQQAAhIBEgTjAQkNCg0KBQQAAhIDEgTjARASCjkKBAQAAhMSBOYBAk8aKyBPcHRpb25hbC4g
TGlzdCBvZiB0b29sc2V0cyBmb3IgdGhlIGFnZW50LgoKDQoFBAACEwQSBOYBAgoKDQoFBAAC
EwYSBOYBCxcKDQoFBAACEwESBOYBGCAKDQoFBAACEwMSBOYBIyUKDQoFBAACEwgSBOYBJk4K
EAoIBAACEwicCAASBOYBJ00KigEKBAQAAhQSBOoBAkwafCBPdXRwdXQgb25seS4gSWYgdGhl
IGFnZW50IGlzIGdlbmVyYXRlZCBieSB0aGUgTExNIGFzc2lzdGFudCwgdGhpcyBmaWVsZAog
Y29udGFpbnMgYSBkZXNjcmlwdGl2ZSBzdW1tYXJ5IG9mIHRoZSBnZW5lcmF0aW9uLgoKDQoF
BAACFAUSBOoBAggKDQoFBAACFAESBOoBCRoKDQoFBAACFAMSBOoBHR8KDQoFBAACFAgSBOoB
IEsKEAoIBAACFAicCAASBOoBIUoKcwoEBAACFRIG7gEC7wEvGmMgT3B0aW9uYWwuIEFnZW50
IHRyYW5zZmVyIHJ1bGVzLgogSWYgbXVsdGlwbGUgcnVsZXMgbWF0Y2gsIHRoZSBmaXJzdCBv
bmUgaW4gdGhlIGxpc3Qgd2lsbCBiZSB1c2VkLgoKDQoFBAACFQQSBO4BAgoKDQoFBAACFQYS
BO4BCxcKDQoFBAACFQESBO4BGCYKDQoFBAACFQMSBO4BKSsKDQoFBAACFQgSBO8BBi4KEAoI
BAACFQicCAASBO8BBy0KZwoEBAACFhIG8wEC9AEyGlcgT3V0cHV0IG9ubHkuIE1pc2NvbmZp
Z3VyYXRpb25zIG9yIGVycm9ycyBpbiB0aGUgYWdlbnQgdGhhdCBtYXkgYWZmZWN0IGFnZW50
CiBxdWFsaXR5LgoKDQoFBAACFgQSBPMBAgoKDQoFBAACFgUSBPMBCxEKDQoFBAACFgESBPMB
EiMKDQoFBAACFgMSBPMBJigKDQoFBAACFggSBPQBBjEKEAoIBAACFgicCAASBPQBBzBiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Agent::Agent ===
    # Fields for Agent
    # Field: llm_agent Type: 11 (.google.cloud.ces.v1.Agent.LlmAgent)
    # Field: remote_dialogflow_agent Type: 11 (.google.cloud.ces.v1.Agent.RemoteDialogflowAgent)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: model_settings Type: 11 (.google.cloud.ces.v1.ModelSettings)
    # Field: instruction Type: 9 ()
    # Field: tools Type: 9 ()
    # Field: child_agents Type: 9 ()
    # Field: before_agent_callbacks Type: 11 (.google.cloud.ces.v1.Callback)
    # Field: after_agent_callbacks Type: 11 (.google.cloud.ces.v1.Callback)
    # Field: before_model_callbacks Type: 11 (.google.cloud.ces.v1.Callback)
    # Field: after_model_callbacks Type: 11 (.google.cloud.ces.v1.Callback)
    # Field: before_tool_callbacks Type: 11 (.google.cloud.ces.v1.Callback)
    # Field: after_tool_callbacks Type: 11 (.google.cloud.ces.v1.Callback)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: guardrails Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: toolsets Type: 11 (.google.cloud.ces.v1.Agent.AgentToolset)
    # Field: generated_summary Type: 9 ()
    # Field: transfer_rules Type: 11 (.google.cloud.ces.v1.TransferRule)
    # Field: validation_errors Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Agent - Compiled Protocol Buffers messages for google/cloud/ces/v1/agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Agent;

    my $msg = Google::Cloud::Ces::V1::Agent::Agent->new({
        llm_agent => $llm_agent,
        remote_dialogflow_agent => $remote_dialogflow_agent,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->llm_agent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Agent::Agent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Agent::Agent

An agent acts as the fundamental building block that provides instructions to
the Large Language Model (LLM) for executing specific tasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->llm_agent() >> / C<< $msg->llm_agent($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Agent::Agent::LlmAgent>)

Optional. The default agent type.

=item * C<< $msg->remote_dialogflow_agent() >> / C<< $msg->remote_dialogflow_agent($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Agent::Agent::RemoteDialogflowAgent>)

Optional. The remote
[Dialogflow](https://cloud.google.com/dialogflow/cx/docs/concept/console-conversational-agents)
agent to be used for the agent execution. If this field is set, all other
agent level properties will be ignored.

Note: If the Dialogflow agent is in a different project from the app, you
should grant `roles/dialogflow.client` to the CES service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the agent.
Format: `projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the agent.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Human-readable description of the agent.

=item * C<< $msg->model_settings() >> / C<< $msg->model_settings($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ModelSettings>)

Optional. Configurations for the LLM model.

=item * C<< $msg->instruction() >> / C<< $msg->instruction($value) >>

Type: C<String>

Optional. Instructions for the LLM model to guide the agent's behavior.

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<String>

Optional. List of available tools for the agent.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->child_agents() >> / C<< $msg->child_agents($value) >>

Type: C<String>

Optional. List of child agents in the agent tree.
Format: `projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->before_agent_callbacks() >> / C<< $msg->before_agent_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::Callback>)

Optional. The callbacks to execute before the agent is called.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->after_agent_callbacks() >> / C<< $msg->after_agent_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::Callback>)

Optional. The callbacks to execute after the agent is called.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->before_model_callbacks() >> / C<< $msg->before_model_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::Callback>)

Optional. The callbacks to execute before the model is called. If there are
multiple calls to the model, the callback will be executed multiple times.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->after_model_callbacks() >> / C<< $msg->after_model_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::Callback>)

Optional. The callbacks to execute after the model is called. If there are
multiple calls to the model, the callback will be executed multiple times.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->before_tool_callbacks() >> / C<< $msg->before_tool_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::Callback>)

Optional. The callbacks to execute before the tool is invoked. If there are
multiple tool invocations, the callback will be executed multiple times.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->after_tool_callbacks() >> / C<< $msg->after_tool_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::Callback>)

Optional. The callbacks to execute after the tool is invoked. If there are
multiple tool invocations, the callback will be executed multiple times.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the agent was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the agent was last updated.

=item * C<< $msg->guardrails() >> / C<< $msg->guardrails($value) >>

Type: C<String>

Optional. List of guardrails for the agent.
Format:
`projects/{project}/locations/{location}/apps/{app}/guardrails/{guardrail}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Etag used to ensure the object hasn't changed during a read-modify-write
operation. If the etag is empty, the update will overwrite any concurrent
changes.

=item * C<< $msg->toolsets() >> / C<< $msg->toolsets($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Agent::Agent::AgentToolset>)

Optional. List of toolsets for the agent.

=item * C<< $msg->generated_summary() >> / C<< $msg->generated_summary($value) >>

Type: C<String>

Output only. If the agent is generated by the LLM assistant, this field
contains a descriptive summary of the generation.

=item * C<< $msg->transfer_rules() >> / C<< $msg->transfer_rules($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentTransfers::TransferRule>)

Optional. Agent transfer rules.
If multiple rules match, the first one in the list will be used.

=item * C<< $msg->validation_errors() >> / C<< $msg->validation_errors($value) >>

Type: C<String>

Output only. Misconfigurations or errors in the agent that may affect agent
quality.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Agent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
