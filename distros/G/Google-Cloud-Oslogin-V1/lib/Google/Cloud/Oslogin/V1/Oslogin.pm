package Google::Cloud::Oslogin::V1::Oslogin;

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
CiVnb29nbGUvY2xvdWQvb3Nsb2dpbi92MS9vc2xvZ2luLnByb3RvEhdnb29nbGUuY2xvdWQu
b3Nsb2dpbi52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9j
bGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC9vc2xvZ2luL2NvbW1vbi9jb21tb24u
cHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2Zp
ZWxkX21hc2sucHJvdG8iyAIKDExvZ2luUHJvZmlsZRIXCgRuYW1lGAEgASgJQgPgQQJSBG5h
bWUSUAoOcG9zaXhfYWNjb3VudHMYAiADKAsyKS5nb29nbGUuY2xvdWQub3Nsb2dpbi5jb21t
b24uUG9zaXhBY2NvdW50Ug1wb3NpeEFjY291bnRzEmAKD3NzaF9wdWJsaWNfa2V5cxgDIAMo
CzI4Lmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxLkxvZ2luUHJvZmlsZS5Tc2hQdWJsaWNLZXlz
RW50cnlSDXNzaFB1YmxpY0tleXMaawoSU3NoUHVibGljS2V5c0VudHJ5EhAKA2tleRgBIAEo
CVIDa2V5Ej8KBXZhbHVlGAIgASgLMikuZ29vZ2xlLmNsb3VkLm9zbG9naW4uY29tbW9uLlNz
aFB1YmxpY0tleVIFdmFsdWU6AjgBIrYBChlDcmVhdGVTc2hQdWJsaWNLZXlSZXF1ZXN0EkMK
BnBhcmVudBgBIAEoCUIr4EEC+kElEiNvc2xvZ2luLmdvb2dsZWFwaXMuY29tL1NzaFB1Ymxp
Y0tleVIGcGFyZW50ElQKDnNzaF9wdWJsaWNfa2V5GAIgASgLMikuZ29vZ2xlLmNsb3VkLm9z
bG9naW4uY29tbW9uLlNzaFB1YmxpY0tleUID4EECUgxzc2hQdWJsaWNLZXkiXAoZRGVsZXRl
UG9zaXhBY2NvdW50UmVxdWVzdBI/CgRuYW1lGAEgASgJQivgQQL6QSUKI29zbG9naW4uZ29v
Z2xlYXBpcy5jb20vUG9zaXhBY2NvdW50UgRuYW1lIlwKGURlbGV0ZVNzaFB1YmxpY0tleVJl
cXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kElCiNvc2xvZ2luLmdvb2dsZWFwaXMuY29tL1Nz
aFB1YmxpY0tleVIEbmFtZSKVAQoWR2V0TG9naW5Qcm9maWxlUmVxdWVzdBI/CgRuYW1lGAEg
ASgJQivgQQL6QSUSI29zbG9naW4uZ29vZ2xlYXBpcy5jb20vUG9zaXhBY2NvdW50UgRuYW1l
Eh0KCnByb2plY3RfaWQYAiABKAlSCXByb2plY3RJZBIbCglzeXN0ZW1faWQYAyABKAlSCHN5
c3RlbUlkIlkKFkdldFNzaFB1YmxpY0tleVJlcXVlc3QSPwoEbmFtZRgBIAEoCUIr4EEC+kEl
CiNvc2xvZ2luLmdvb2dsZWFwaXMuY29tL1NzaFB1YmxpY0tleVIEbmFtZSL0AQoZSW1wb3J0
U3NoUHVibGljS2V5UmVxdWVzdBJDCgZwYXJlbnQYASABKAlCK+BBAvpBJRIjb3Nsb2dpbi5n
b29nbGVhcGlzLmNvbS9Tc2hQdWJsaWNLZXlSBnBhcmVudBJUCg5zc2hfcHVibGljX2tleRgC
IAEoCzIpLmdvb2dsZS5jbG91ZC5vc2xvZ2luLmNvbW1vbi5Tc2hQdWJsaWNLZXlCA+BBAVIM
c3NoUHVibGljS2V5Eh0KCnByb2plY3RfaWQYAyABKAlSCXByb2plY3RJZBIdCgdyZWdpb25z
GAUgAygJQgPgQQFSB3JlZ2lvbnMiggEKGkltcG9ydFNzaFB1YmxpY0tleVJlc3BvbnNlEkoK
DWxvZ2luX3Byb2ZpbGUYASABKAsyJS5nb29nbGUuY2xvdWQub3Nsb2dpbi52MS5Mb2dpblBy
b2ZpbGVSDGxvZ2luUHJvZmlsZRIYCgdkZXRhaWxzGAIgASgJUgdkZXRhaWxzIu8BChlVcGRh
dGVTc2hQdWJsaWNLZXlSZXF1ZXN0Ej8KBG5hbWUYASABKAlCK+BBAvpBJQojb3Nsb2dpbi5n
b29nbGVhcGlzLmNvbS9Tc2hQdWJsaWNLZXlSBG5hbWUSVAoOc3NoX3B1YmxpY19rZXkYAiAB
KAsyKS5nb29nbGUuY2xvdWQub3Nsb2dpbi5jb21tb24uU3NoUHVibGljS2V5QgPgQQJSDHNz
aFB1YmxpY0tleRI7Cgt1cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVs
ZE1hc2tSCnVwZGF0ZU1hc2syhgwKDk9zTG9naW5TZXJ2aWNlEscBChJDcmVhdGVTc2hQdWJs
aWNLZXkSMi5nb29nbGUuY2xvdWQub3Nsb2dpbi52MS5DcmVhdGVTc2hQdWJsaWNLZXlSZXF1
ZXN0GikuZ29vZ2xlLmNsb3VkLm9zbG9naW4uY29tbW9uLlNzaFB1YmxpY0tleSJSgtPkkwI0
IiIvdjEve3BhcmVudD11c2Vycy8qfS9zc2hQdWJsaWNLZXlzOg5zc2hfcHVibGljX2tledpB
FXBhcmVudCxzc2hfcHVibGljX2tleRKOAQoSRGVsZXRlUG9zaXhBY2NvdW50EjIuZ29vZ2xl
LmNsb3VkLm9zbG9naW4udjEuRGVsZXRlUG9zaXhBY2NvdW50UmVxdWVzdBoWLmdvb2dsZS5w
cm90b2J1Zi5FbXB0eSIsgtPkkwIfKh0vdjEve25hbWU9dXNlcnMvKi9wcm9qZWN0cy8qfdpB
BG5hbWUSkwEKEkRlbGV0ZVNzaFB1YmxpY0tleRIyLmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYx
LkRlbGV0ZVNzaFB1YmxpY0tleVJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiMYLT
5JMCJCoiL3YxL3tuYW1lPXVzZXJzLyovc3NoUHVibGljS2V5cy8qfdpBBG5hbWUSmQEKD0dl
dExvZ2luUHJvZmlsZRIvLmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxLkdldExvZ2luUHJvZmls
ZVJlcXVlc3QaJS5nb29nbGUuY2xvdWQub3Nsb2dpbi52MS5Mb2dpblByb2ZpbGUiLoLT5JMC
IRIfL3YxL3tuYW1lPXVzZXJzLyp9L2xvZ2luUHJvZmlsZdpBBG5hbWUSoAEKD0dldFNzaFB1
YmxpY0tleRIvLmdvb2dsZS5jbG91ZC5vc2xvZ2luLnYxLkdldFNzaFB1YmxpY0tleVJlcXVl
c3QaKS5nb29nbGUuY2xvdWQub3Nsb2dpbi5jb21tb24uU3NoUHVibGljS2V5IjGC0+STAiQS
Ii92MS97bmFtZT11c2Vycy8qL3NzaFB1YmxpY0tleXMvKn3aQQRuYW1lEvkBChJJbXBvcnRT
c2hQdWJsaWNLZXkSMi5nb29nbGUuY2xvdWQub3Nsb2dpbi52MS5JbXBvcnRTc2hQdWJsaWNL
ZXlSZXF1ZXN0GjMuZ29vZ2xlLmNsb3VkLm9zbG9naW4udjEuSW1wb3J0U3NoUHVibGljS2V5
UmVzcG9uc2UieoLT5JMCOSInL3YxL3twYXJlbnQ9dXNlcnMvKn06aW1wb3J0U3NoUHVibGlj
S2V5Og5zc2hfcHVibGljX2tledpBFXBhcmVudCxzc2hfcHVibGljX2tledpBIHBhcmVudCxz
c2hfcHVibGljX2tleSxwcm9qZWN0X2lkEucBChJVcGRhdGVTc2hQdWJsaWNLZXkSMi5nb29n
bGUuY2xvdWQub3Nsb2dpbi52MS5VcGRhdGVTc2hQdWJsaWNLZXlSZXF1ZXN0GikuZ29vZ2xl
LmNsb3VkLm9zbG9naW4uY29tbW9uLlNzaFB1YmxpY0tleSJygtPkkwI0MiIvdjEve25hbWU9
dXNlcnMvKi9zc2hQdWJsaWNLZXlzLyp9Og5zc2hfcHVibGljX2tledpBE25hbWUsc3NoX3B1
YmxpY19rZXnaQR9uYW1lLHNzaF9wdWJsaWNfa2V5LHVwZGF0ZV9tYXNrGt0BykEWb3Nsb2dp
bi5nb29nbGVhcGlzLmNvbdJBwAFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Ns
b3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxh
dGZvcm0ucmVhZC1vbmx5LGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY29tcHV0
ZSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2NvbXB1dGUucmVhZG9ubHlCtQEK
G2NvbS5nb29nbGUuY2xvdWQub3Nsb2dpbi52MUIMT3NMb2dpblByb3RvUAFaNWNsb3VkLmdv
b2dsZS5jb20vZ28vb3Nsb2dpbi9hcGl2MS9vc2xvZ2lucGI7b3Nsb2dpbnBiqgIXR29vZ2xl
LkNsb3VkLk9zTG9naW4uVjHKAhdHb29nbGVcQ2xvdWRcT3NMb2dpblxWMeoCGkdvb2dsZTo6
Q2xvdWQ6Ok9zTG9naW46OlYxSok2CgcSBQ4A/AEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAAp
CgkKAgMDEgMVACMKCQoCAwQSAxYAMgoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgA0
CgkKAgglEgMaADQKCAoBCBIDGwBMCgkKAggLEgMbAEwKCAoBCBIDHAAiCgkKAggKEgMcACIK
CAoBCBIDHQAtCgkKAggIEgMdAC0KCAoBCBIDHgA0CgkKAggBEgMeADQKCAoBCBIDHwA0CgkK
AggpEgMfADQKCAoBCBIDIAAzCgkKAggtEgMgADMKtwEKAgYAEgQmAHQBGqoBIENsb3VkIE9T
IExvZ2luIEFQSQoKIFRoZSBDbG91ZCBPUyBMb2dpbiBBUEkgYWxsb3dzIHlvdSB0byBtYW5h
Z2UgdXNlcnMgYW5kIHRoZWlyIGFzc29jaWF0ZWQgU1NICiBwdWJsaWMga2V5cyBmb3IgbG9n
Z2luZyBpbnRvIHZpcnR1YWwgbWFjaGluZXMgb24gR29vZ2xlIENsb3VkIFBsYXRmb3JtLgoK
CgoDBgABEgMmCBYKCgoDBgADEgMnAj4KDAoFBgADmQgSAycCPgoLCgMGAAMSBCgCLDkKDQoF
BgADmggSBCgCLDkKKAoEBgACABIELwI2AxoaIENyZWF0ZSBhbiBTU0ggcHVibGljIGtleQoK
DAoFBgACAAESAy8GGAoMCgUGAAIAAhIDLxkyCgwKBQYAAgADEgMwDzcKDQoFBgACAAQSBDEE
NAYKEQoJBgACAASwyrwiEgQxBDQGCgwKBQYAAgAEEgM1BEMKDwoIBgACAASbCAASAzUEQwoo
CgQGAAIBEgQ5Aj8DGhogRGVsZXRlcyBhIFBPU0lYIGFjY291bnQuCgoMCgUGAAIBARIDOQYY
CgwKBQYAAgECEgM5GTIKDAoFBgACAQMSAzoPJAoNCgUGAAIBBBIEOwQ9BgoRCgkGAAIBBLDK
vCISBDsEPQYKDAoFBgACAQQSAz4EMgoPCggGAAIBBJsIABIDPgQyCioKBAYAAgISBEICSAMa
HCBEZWxldGVzIGFuIFNTSCBwdWJsaWMga2V5LgoKDAoFBgACAgESA0IGGAoMCgUGAAICAhID
QhkyCgwKBQYAAgIDEgNDDyQKDQoFBgACAgQSBEQERgYKEQoJBgACAgSwyrwiEgREBEYGCgwK
BQYAAgIEEgNHBDIKDwoIBgACAgSbCAASA0cEMgp1CgQGAAIDEgRMAlEDGmcgUmV0cmlldmVz
IHRoZSBwcm9maWxlIGluZm9ybWF0aW9uIHVzZWQgZm9yIGxvZ2dpbmcgaW4gdG8gYSB2aXJ0
dWFsIG1hY2hpbmUKIG9uIEdvb2dsZSBDb21wdXRlIEVuZ2luZS4KCgwKBQYAAgMBEgNMBhUK
DAoFBgACAwISA0wWLAoMCgUGAAIDAxIDTDdDCg0KBQYAAgMEEgRNBE8GChEKCQYAAgMEsMq8
IhIETQRPBgoMCgUGAAIDBBIDUAQyCg8KCAYAAgMEmwgAEgNQBDIKLAoEBgACBBIEVAJaAxoe
IFJldHJpZXZlcyBhbiBTU0ggcHVibGljIGtleS4KCgwKBQYAAgQBEgNUBhUKDAoFBgACBAIS
A1QWLAoMCgUGAAIEAxIDVQ83Cg0KBQYAAgQEEgRWBFgGChEKCQYAAgQEsMq8IhIEVgRYBgoM
CgUGAAIEBBIDWQQyCg8KCAYAAgQEmwgAEgNZBDIKtAEKBAYAAgUSBF8CZwMapQEgQWRkcyBh
biBTU0ggcHVibGljIGtleSBhbmQgcmV0dXJucyB0aGUgcHJvZmlsZSBpbmZvcm1hdGlvbi4g
RGVmYXVsdCBQT1NJWAogYWNjb3VudCBpbmZvcm1hdGlvbiBpcyBzZXQgd2hlbiBubyB1c2Vy
bmFtZSBhbmQgVUlEIGV4aXN0IGFzIHBhcnQgb2YgdGhlCiBsb2dpbiBwcm9maWxlLgoKDAoF
BgACBQESA18GGAoMCgUGAAIFAhIDXxkyCgwKBQYAAgUDEgNgDykKDQoFBgACBQQSBGEEZAYK
EQoJBgACBQSwyrwiEgRhBGQGCgwKBQYAAgUEEgNlBEMKDwoIBgACBQSbCAASA2UEQwoMCgUG
AAIFBBIDZgROCg8KCAYAAgUEmwgBEgNmBE4KdQoEBgACBhIEawJzAxpnIFVwZGF0ZXMgYW4g
U1NIIHB1YmxpYyBrZXkgYW5kIHJldHVybnMgdGhlIHByb2ZpbGUgaW5mb3JtYXRpb24uIFRo
aXMgbWV0aG9kCiBzdXBwb3J0cyBwYXRjaCBzZW1hbnRpY3MuCgoMCgUGAAIGARIDawYYCgwK
BQYAAgYCEgNrGTIKDAoFBgACBgMSA2wPNwoNCgUGAAIGBBIEbQRwBgoRCgkGAAIGBLDKvCIS
BG0EcAYKDAoFBgACBgQSA3EEQQoPCggGAAIGBJsIABIDcQRBCgwKBQYAAgYEEgNyBE0KDwoI
BgACBgSbCAESA3IETQpvCgIEABIFeACBAQEaYiBUaGUgdXNlciBwcm9maWxlIGluZm9ybWF0
aW9uIHVzZWQgZm9yIGxvZ2dpbmcgaW4gdG8gYSB2aXJ0dWFsIG1hY2hpbmUgb24KIEdvb2ds
ZSBDb21wdXRlIEVuZ2luZS4KCgoKAwQAARIDeAgUCioKBAQAAgASA3oCOxodIFJlcXVpcmVk
LiBBIHVuaXF1ZSB1c2VyIElELgoKDAoFBAACAAUSA3oCCAoMCgUEAAIAARIDegkNCgwKBQQA
AgADEgN6EBEKDAoFBAACAAgSA3oSOgoPCggEAAIACJwIABIDehM5CkMKBAQAAgESA30CRxo2
IFRoZSBsaXN0IG9mIFBPU0lYIGFjY291bnRzIGFzc29jaWF0ZWQgd2l0aCB0aGUgdXNlci4K
CgwKBQQAAgEEEgN9AgoKDAoFBAACAQYSA30LMwoMCgUEAAIBARIDfTRCCgwKBQQAAgEDEgN9
RUYKUwoEBAACAhIEgAECTBpFIEEgbWFwIGZyb20gU1NIIHB1YmxpYyBrZXkgZmluZ2VycHJp
bnQgdG8gdGhlIGFzc29jaWF0ZWQga2V5IG9iamVjdC4KCg0KBQQAAgIGEgSAAQI3Cg0KBQQA
AgIBEgSAAThHCg0KBQQAAgIDEgSAAUpLCkEKAgQBEgaEAQCQAQEaMyBBIHJlcXVlc3QgbWVz
c2FnZSBmb3IgY3JlYXRpbmcgYW4gU1NIIHB1YmxpYyBrZXkuCgoLCgMEAQESBIQBCCEKUAoE
BAECABIGhgECiwEEGkAgUmVxdWlyZWQuIFRoZSB1bmlxdWUgSUQgZm9yIHRoZSB1c2VyIGlu
IGZvcm1hdCBgdXNlcnMve3VzZXJ9YC4KCg0KBQQBAgAFEgSGAQIICg0KBQQBAgABEgSGAQkP
Cg0KBQQBAgADEgSGARITCg8KBQQBAgAIEgaGARSLAQMKEAoIBAECAAicCAASBIcBBCoKEQoH
BAECAAifCBIGiAEEigEFCkMKBAQBAgESBo4BAo8BLxozIFJlcXVpcmVkLiBUaGUgU1NIIHB1
YmxpYyBrZXkgYW5kIGV4cGlyYXRpb24gdGltZS4KCg0KBQQBAgEGEgSOAQIqCg0KBQQBAgEB
EgSOASs5Cg0KBQQBAgEDEgSOATw9Cg0KBQQBAgEIEgSPAQYuChAKCAQBAgEInAgAEgSPAQct
CkUKAgQCEgaTAQCdAQEaNyBBIHJlcXVlc3QgbWVzc2FnZSBmb3IgZGVsZXRpbmcgYSBQT1NJ
WCBhY2NvdW50IGVudHJ5LgoKCwoDBAIBEgSTAQghCuUBCgQEAgIAEgaXAQKcAQQa1AEgUmVx
dWlyZWQuIEEgcmVmZXJlbmNlIHRvIHRoZSBQT1NJWCBhY2NvdW50IHRvIHVwZGF0ZS4gUE9T
SVggYWNjb3VudHMgYXJlCiBpZGVudGlmaWVkIGJ5IHRoZSBwcm9qZWN0IElEIHRoZXkgYXJl
IGFzc29jaWF0ZWQgd2l0aC4gQSByZWZlcmVuY2UgdG8gdGhlCiBQT1NJWCBhY2NvdW50IGlz
IGluIGZvcm1hdCBgdXNlcnMve3VzZXJ9L3Byb2plY3RzL3twcm9qZWN0fWAuCgoNCgUEAgIA
BRIElwECCAoNCgUEAgIAARIElwEJDQoNCgUEAgIAAxIElwEQEQoPCgUEAgIACBIGlwESnAED
ChAKCAQCAgAInAgAEgSYAQQqChEKBwQCAgAInwgSBpkBBJsBBQpBCgIEAxIGoAEAqgEBGjMg
QSByZXF1ZXN0IG1lc3NhZ2UgZm9yIGRlbGV0aW5nIGFuIFNTSCBwdWJsaWMga2V5LgoKCwoD
BAMBEgSgAQghCt8BCgQEAwIAEgakAQKpAQQazgEgUmVxdWlyZWQuIFRoZSBmaW5nZXJwcmlu
dCBvZiB0aGUgcHVibGljIGtleSB0byB1cGRhdGUuIFB1YmxpYyBrZXlzIGFyZQogaWRlbnRp
ZmllZCBieSB0aGVpciBTSEEtMjU2IGZpbmdlcnByaW50LiBUaGUgZmluZ2VycHJpbnQgb2Yg
dGhlIHB1YmxpYyBrZXkKIGlzIGluIGZvcm1hdCBgdXNlcnMve3VzZXJ9L3NzaFB1YmxpY0tl
eXMve2ZpbmdlcnByaW50fWAuCgoNCgUEAwIABRIEpAECCAoNCgUEAwIAARIEpAEJDQoNCgUE
AwIAAxIEpAEQEQoPCgUEAwIACBIGpAESqQEDChAKCAQDAgAInAgAEgSlAQQqChEKBwQDAgAI
nwgSBqYBBKgBBQpaCgIEBBIGrQEAuwEBGkwgQSByZXF1ZXN0IG1lc3NhZ2UgZm9yIHJldHJp
ZXZpbmcgdGhlIGxvZ2luIHByb2ZpbGUgaW5mb3JtYXRpb24gZm9yIGEgdXNlci4KCgsKAwQE
ARIErQEIHgpQCgQEBAIAEgavAQK0AQQaQCBSZXF1aXJlZC4gVGhlIHVuaXF1ZSBJRCBmb3Ig
dGhlIHVzZXIgaW4gZm9ybWF0IGB1c2Vycy97dXNlcn1gLgoKDQoFBAQCAAUSBK8BAggKDQoF
BAQCAAESBK8BCQ0KDQoFBAQCAAMSBK8BEBEKDwoFBAQCAAgSBq8BErQBAwoQCggEBAIACJwI
ABIEsAEEKgoRCgcEBAIACJ8IEgaxAQSzAQUKRAoEBAQCARIEtwECGBo2IFRoZSBwcm9qZWN0
IElEIG9mIHRoZSBHb29nbGUgQ2xvdWQgUGxhdGZvcm0gcHJvamVjdC4KCg0KBQQEAgEFEgS3
AQIICg0KBQQEAgEBEgS3AQkTCg0KBQQEAgEDEgS3ARYXCkUKBAQEAgISBLoBAhcaNyBBIHN5
c3RlbSBJRCBmb3IgZmlsdGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LgoKDQoF
BAQCAgUSBLoBAggKDQoFBAQCAgESBLoBCRIKDQoFBAQCAgMSBLoBFRYKQwoCBAUSBr4BAMgB
ARo1IEEgcmVxdWVzdCBtZXNzYWdlIGZvciByZXRyaWV2aW5nIGFuIFNTSCBwdWJsaWMga2V5
LgoKCwoDBAUBEgS+AQgeCuEBCgQEBQIAEgbCAQLHAQQa0AEgUmVxdWlyZWQuIFRoZSBmaW5n
ZXJwcmludCBvZiB0aGUgcHVibGljIGtleSB0byByZXRyaWV2ZS4gUHVibGljIGtleXMgYXJl
CiBpZGVudGlmaWVkIGJ5IHRoZWlyIFNIQS0yNTYgZmluZ2VycHJpbnQuIFRoZSBmaW5nZXJw
cmludCBvZiB0aGUgcHVibGljIGtleQogaXMgaW4gZm9ybWF0IGB1c2Vycy97dXNlcn0vc3No
UHVibGljS2V5cy97ZmluZ2VycHJpbnR9YC4KCg0KBQQFAgAFEgTCAQIICg0KBQQFAgABEgTC
AQkNCg0KBQQFAgADEgTCARARCg8KBQQFAgAIEgbCARLHAQMKEAoIBAUCAAicCAASBMMBBCoK
EQoHBAUCAAifCBIGxAEExgEFCkIKAgQGEgbLAQDfAQEaNCBBIHJlcXVlc3QgbWVzc2FnZSBm
b3IgaW1wb3J0aW5nIGFuIFNTSCBwdWJsaWMga2V5LgoKCwoDBAYBEgTLAQghClAKBAQGAgAS
Bs0BAtIBBBpAIFJlcXVpcmVkLiBUaGUgdW5pcXVlIElEIGZvciB0aGUgdXNlciBpbiBmb3Jt
YXQgYHVzZXJzL3t1c2VyfWAuCgoNCgUEBgIABRIEzQECCAoNCgUEBgIAARIEzQEJDwoNCgUE
BgIAAxIEzQESEwoPCgUEBgIACBIGzQEU0gEDChAKCAQGAgAInAgAEgTOAQQqChEKBwQGAgAI
nwgSBs8BBNEBBQpDCgQEBgIBEgbVAQLWAS8aMyBPcHRpb25hbC4gVGhlIFNTSCBwdWJsaWMg
a2V5IGFuZCBleHBpcmF0aW9uIHRpbWUuCgoNCgUEBgIBBhIE1QECKgoNCgUEBgIBARIE1QEr
OQoNCgUEBgIBAxIE1QE8PQoNCgUEBgIBCBIE1gEGLgoQCggEBgIBCJwIABIE1gEHLQpECgQE
BgICEgTZAQIYGjYgVGhlIHByb2plY3QgSUQgb2YgdGhlIEdvb2dsZSBDbG91ZCBQbGF0Zm9y
bSBwcm9qZWN0LgoKDQoFBAYCAgUSBNkBAggKDQoFBAYCAgESBNkBCRMKDQoFBAYCAgMSBNkB
FhcKxQEKBAQGAgMSBN4BAkcatgEgT3B0aW9uYWwuIFRoZSByZWdpb25zIHRvIHdoaWNoIHRv
IGFzc2VydCB0aGF0IHRoZSBrZXkgd2FzIHdyaXR0ZW4uCiBJZiB1bnNwZWNpZmllZCwgZGVm
YXVsdHMgdG8gYWxsIHJlZ2lvbnMuCiBSZWdpb25zIGFyZSBsaXN0ZWQgYXQgaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL2Fib3V0L2xvY2F0aW9ucyNyZWdpb24uCgoNCgUEBgIDBBIE3gEC
CgoNCgUEBgIDBRIE3gELEQoNCgUEBgIDARIE3gESGQoNCgUEBgIDAxIE3gEcHQoNCgUEBgID
CBIE3gEeRgoQCggEBgIDCJwIABIE3gEfRQpDCgIEBxIG4gEA6AEBGjUgQSByZXNwb25zZSBt
ZXNzYWdlIGZvciBpbXBvcnRpbmcgYW4gU1NIIHB1YmxpYyBrZXkuCgoLCgMEBwESBOIBCCIK
OwoEBAcCABIE5AECIRotIFRoZSBsb2dpbiBwcm9maWxlIGluZm9ybWF0aW9uIGZvciB0aGUg
dXNlci4KCg0KBQQHAgAGEgTkAQIOCg0KBQQHAgABEgTkAQ8cCg0KBQQHAgADEgTkAR8gCjoK
BAQHAgESBOcBAhUaLCBEZXRhaWxlZCBpbmZvcm1hdGlvbiBhYm91dCBpbXBvcnQgcmVzdWx0
cy4KCg0KBQQHAgEFEgTnAQIICg0KBQQHAgEBEgTnAQkQCg0KBQQHAgEDEgTnARMUCkEKAgQI
EgbrAQD8AQEaMyBBIHJlcXVlc3QgbWVzc2FnZSBmb3IgdXBkYXRpbmcgYW4gU1NIIHB1Ymxp
YyBrZXkuCgoLCgMECAESBOsBCCEK3wEKBAQIAgASBu8BAvQBBBrOASBSZXF1aXJlZC4gVGhl
IGZpbmdlcnByaW50IG9mIHRoZSBwdWJsaWMga2V5IHRvIHVwZGF0ZS4gUHVibGljIGtleXMg
YXJlCiBpZGVudGlmaWVkIGJ5IHRoZWlyIFNIQS0yNTYgZmluZ2VycHJpbnQuIFRoZSBmaW5n
ZXJwcmludCBvZiB0aGUgcHVibGljIGtleQogaXMgaW4gZm9ybWF0IGB1c2Vycy97dXNlcn0v
c3NoUHVibGljS2V5cy97ZmluZ2VycHJpbnR9YC4KCg0KBQQIAgAFEgTvAQIICg0KBQQIAgAB
EgTvAQkNCg0KBQQIAgADEgTvARARCg8KBQQIAgAIEgbvARL0AQMKEAoIBAgCAAicCAASBPAB
BCoKEQoHBAgCAAifCBIG8QEE8wEFCkMKBAQIAgESBvcBAvgBLxozIFJlcXVpcmVkLiBUaGUg
U1NIIHB1YmxpYyBrZXkgYW5kIGV4cGlyYXRpb24gdGltZS4KCg0KBQQIAgEGEgT3AQIqCg0K
BQQIAgEBEgT3ASs5Cg0KBQQIAgEDEgT3ATw9Cg0KBQQIAgEIEgT4AQYuChAKCAQIAgEInAgA
EgT4AQctClUKBAQIAgISBPsBAiwaRyBNYXNrIHRvIGNvbnRyb2wgd2hpY2ggZmllbGRzIGdl
dCB1cGRhdGVkLiBVcGRhdGVzIGFsbCBpZiBub3QgcHJlc2VudC4KCg0KBQQIAgIGEgT7AQIb
Cg0KBQQIAgIBEgT7ARwnCg0KBQQIAgIDEgT7ASorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oslogin::V1::Oslogin::LoginProfile ===
    # Fields for LoginProfile
    # Field: name Type: 9 ()
    # Field: posix_accounts Type: 11 (.google.cloud.oslogin.common.PosixAccount)
    # Field: ssh_public_keys Type: 11 (.google.cloud.oslogin.v1.LoginProfile.SshPublicKeysEntry)

# === Message: Google::Cloud::Oslogin::V1::Oslogin::CreateSshPublicKeyRequest ===
    # Fields for CreateSshPublicKeyRequest
    # Field: parent Type: 9 ()
    # Field: ssh_public_key Type: 11 (.google.cloud.oslogin.common.SshPublicKey)

# === Message: Google::Cloud::Oslogin::V1::Oslogin::DeletePosixAccountRequest ===
    # Fields for DeletePosixAccountRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1::Oslogin::DeleteSshPublicKeyRequest ===
    # Fields for DeleteSshPublicKeyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1::Oslogin::GetLoginProfileRequest ===
    # Fields for GetLoginProfileRequest
    # Field: name Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: system_id Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1::Oslogin::GetSshPublicKeyRequest ===
    # Fields for GetSshPublicKeyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1::Oslogin::ImportSshPublicKeyRequest ===
    # Fields for ImportSshPublicKeyRequest
    # Field: parent Type: 9 ()
    # Field: ssh_public_key Type: 11 (.google.cloud.oslogin.common.SshPublicKey)
    # Field: project_id Type: 9 ()
    # Field: regions Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1::Oslogin::ImportSshPublicKeyResponse ===
    # Fields for ImportSshPublicKeyResponse
    # Field: login_profile Type: 11 (.google.cloud.oslogin.v1.LoginProfile)
    # Field: details Type: 9 ()

# === Message: Google::Cloud::Oslogin::V1::Oslogin::UpdateSshPublicKeyRequest ===
    # Fields for UpdateSshPublicKeyRequest
    # Field: name Type: 9 ()
    # Field: ssh_public_key Type: 11 (.google.cloud.oslogin.common.SshPublicKey)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Oslogin::V1::Oslogin::OsLoginServiceClient ===
package Google::Cloud::Oslogin::V1::Oslogin::OsLoginServiceClient;

=pod

=head2 Service Client: Google::Cloud::Oslogin::V1::Oslogin::OsLoginServiceClient

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
        ? Google::Cloud::Oslogin::V1::Oslogin::CreateSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1.OsLoginService',
        method         => 'CreateSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::Common::Common::SshPublicKey',
    });
}

sub delete_posix_account {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1::Oslogin::DeletePosixAccountRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1.OsLoginService',
        method         => 'DeletePosixAccount',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub delete_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1::Oslogin::DeleteSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1.OsLoginService',
        method         => 'DeleteSshPublicKey',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_login_profile {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1::Oslogin::GetLoginProfileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1.OsLoginService',
        method         => 'GetLoginProfile',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::V1::Oslogin::LoginProfile',
    });
}

sub get_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1::Oslogin::GetSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1.OsLoginService',
        method         => 'GetSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::Common::Common::SshPublicKey',
    });
}

sub import_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1::Oslogin::ImportSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1.OsLoginService',
        method         => 'ImportSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::V1::Oslogin::ImportSshPublicKeyResponse',
    });
}

sub update_ssh_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Oslogin::V1::Oslogin::UpdateSshPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.oslogin.v1.OsLoginService',
        method         => 'UpdateSshPublicKey',
        request        => $req,
        response_class => 'Google::Cloud::Oslogin::Common::Common::SshPublicKey',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oslogin::V1::Oslogin - Compiled Protocol Buffers messages for google/cloud/oslogin/v1/oslogin.proto

=head1 SYNOPSIS

    use Google::Cloud::Oslogin::V1::Oslogin;

    my $msg = Google::Cloud::Oslogin::V1::Oslogin::LoginProfile->new({
        name => $name,
        posix_accounts => $posix_accounts,
        ssh_public_keys => $ssh_public_keys,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oslogin::V1::Oslogin::LoginProfile->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oslogin/v1/oslogin.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oslogin::V1::Oslogin::LoginProfile

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

Type: C<Message> (L<Google::Cloud::Oslogin::V1::Oslogin::LoginProfile::SshPublicKeysEntry>)

A map from SSH public key fingerprint to the associated key object.

=back

=head2 Google::Cloud::Oslogin::V1::Oslogin::CreateSshPublicKeyRequest

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

=head2 Google::Cloud::Oslogin::V1::Oslogin::DeletePosixAccountRequest

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

=head2 Google::Cloud::Oslogin::V1::Oslogin::DeleteSshPublicKeyRequest

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

=head2 Google::Cloud::Oslogin::V1::Oslogin::GetLoginProfileRequest

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

=back

=head2 Google::Cloud::Oslogin::V1::Oslogin::GetSshPublicKeyRequest

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

=head2 Google::Cloud::Oslogin::V1::Oslogin::ImportSshPublicKeyRequest

A request message for importing an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The unique ID for the user in format `users/{user}`.

=item * C<< $msg->ssh_public_key() >> / C<< $msg->ssh_public_key($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::Common::Common::SshPublicKey>)

Optional. The SSH public key and expiration time.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The project ID of the Google Cloud Platform project.

=item * C<< $msg->regions() >> / C<< $msg->regions($value) >>

Type: C<String>

Optional. The regions to which to assert that the key was written.
If unspecified, defaults to all regions.
Regions are listed at https://cloud.google.com/about/locations#region.

=back

=head2 Google::Cloud::Oslogin::V1::Oslogin::ImportSshPublicKeyResponse

A response message for importing an SSH public key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->login_profile() >> / C<< $msg->login_profile($value) >>

Type: C<Message> (L<Google::Cloud::Oslogin::V1::Oslogin::LoginProfile>)

The login profile information for the user.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<String>

Detailed information about import results.

=back

=head2 Google::Cloud::Oslogin::V1::Oslogin::UpdateSshPublicKeyRequest

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

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oslogin::V1::Oslogin::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
