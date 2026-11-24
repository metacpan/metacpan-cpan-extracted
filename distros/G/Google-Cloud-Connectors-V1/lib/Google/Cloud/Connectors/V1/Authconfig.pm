package Google::Cloud::Connectors::V1::Authconfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Connectors::V1::Common };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9hdXRoY29uZmlnLnByb3RvEhpnb29nbGUu
Y2xvdWQuY29ubmVjdG9ycy52MRonZ29vZ2xlL2Nsb3VkL2Nvbm5lY3RvcnMvdjEvY29tbW9u
LnByb3RvIr4KCgpBdXRoQ29uZmlnEkEKCWF1dGhfdHlwZRgBIAEoDjIkLmdvb2dsZS5jbG91
ZC5jb25uZWN0b3JzLnYxLkF1dGhUeXBlUghhdXRoVHlwZRJaCg11c2VyX3Bhc3N3b3JkGAIg
ASgLMjMuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuQXV0aENvbmZpZy5Vc2VyUGFzc3dv
cmRIAFIMdXNlclBhc3N3b3JkEmQKEW9hdXRoMl9qd3RfYmVhcmVyGAMgASgLMjYuZ29vZ2xl
LmNsb3VkLmNvbm5lY3RvcnMudjEuQXV0aENvbmZpZy5PYXV0aDJKd3RCZWFyZXJIAFIPb2F1
dGgySnd0QmVhcmVyEnwKGW9hdXRoMl9jbGllbnRfY3JlZGVudGlhbHMYBCABKAsyPi5nb29n
bGUuY2xvdWQuY29ubmVjdG9ycy52MS5BdXRoQ29uZmlnLk9hdXRoMkNsaWVudENyZWRlbnRp
YWxzSABSF29hdXRoMkNsaWVudENyZWRlbnRpYWxzElsKDnNzaF9wdWJsaWNfa2V5GAYgASgL
MjMuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuQXV0aENvbmZpZy5Tc2hQdWJsaWNLZXlI
AFIMc3NoUHVibGljS2V5El0KFGFkZGl0aW9uYWxfdmFyaWFibGVzGAUgAygLMiouZ29vZ2xl
LmNsb3VkLmNvbm5lY3RvcnMudjEuQ29uZmlnVmFyaWFibGVSE2FkZGl0aW9uYWxWYXJpYWJs
ZXMaagoMVXNlclBhc3N3b3JkEhoKCHVzZXJuYW1lGAEgASgJUgh1c2VybmFtZRI+CghwYXNz
d29yZBgCIAEoCzIiLmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLlNlY3JldFIIcGFzc3dv
cmQakAIKD09hdXRoMkp3dEJlYXJlchJBCgpjbGllbnRfa2V5GAEgASgLMiIuZ29vZ2xlLmNs
b3VkLmNvbm5lY3RvcnMudjEuU2VjcmV0UgljbGllbnRLZXkSXwoKand0X2NsYWltcxgCIAEo
CzJALmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkF1dGhDb25maWcuT2F1dGgySnd0QmVh
cmVyLkp3dENsYWltc1IJand0Q2xhaW1zGlkKCUp3dENsYWltcxIWCgZpc3N1ZXIYASABKAlS
Bmlzc3VlchIYCgdzdWJqZWN0GAIgASgJUgdzdWJqZWN0EhoKCGF1ZGllbmNlGAMgASgJUghh
dWRpZW5jZRp/ChdPYXV0aDJDbGllbnRDcmVkZW50aWFscxIbCgljbGllbnRfaWQYASABKAlS
CGNsaWVudElkEkcKDWNsaWVudF9zZWNyZXQYAiABKAsyIi5nb29nbGUuY2xvdWQuY29ubmVj
dG9ycy52MS5TZWNyZXRSDGNsaWVudFNlY3JldBroAQoMU3NoUHVibGljS2V5EhoKCHVzZXJu
YW1lGAEgASgJUgh1c2VybmFtZRJKCg9zc2hfY2xpZW50X2NlcnQYAyABKAsyIi5nb29nbGUu
Y2xvdWQuY29ubmVjdG9ycy52MS5TZWNyZXRSDXNzaENsaWVudENlcnQSGwoJY2VydF90eXBl
GAQgASgJUghjZXJ0VHlwZRJTChRzc2hfY2xpZW50X2NlcnRfcGFzcxgFIAEoCzIiLmdvb2ds
ZS5jbG91ZC5jb25uZWN0b3JzLnYxLlNlY3JldFIRc3NoQ2xpZW50Q2VydFBhc3NCBgoEdHlw
ZSKMAgoSQXV0aENvbmZpZ1RlbXBsYXRlEkEKCWF1dGhfdHlwZRgBIAEoDjIkLmdvb2dsZS5j
bG91ZC5jb25uZWN0b3JzLnYxLkF1dGhUeXBlUghhdXRoVHlwZRJuChljb25maWdfdmFyaWFi
bGVfdGVtcGxhdGVzGAIgAygLMjIuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuQ29uZmln
VmFyaWFibGVUZW1wbGF0ZVIXY29uZmlnVmFyaWFibGVUZW1wbGF0ZXMSIQoMZGlzcGxheV9u
YW1lGAMgASgJUgtkaXNwbGF5TmFtZRIgCgtkZXNjcmlwdGlvbhgEIAEoCVILZGVzY3JpcHRp
b24qnQEKCEF1dGhUeXBlEhkKFUFVVEhfVFlQRV9VTlNQRUNJRklFRBAAEhEKDVVTRVJfUEFT
U1dPUkQQARIVChFPQVVUSDJfSldUX0JFQVJFUhACEh0KGU9BVVRIMl9DTElFTlRfQ1JFREVO
VElBTFMQAxISCg5TU0hfUFVCTElDX0tFWRAEEhkKFU9BVVRIMl9BVVRIX0NPREVfRkxPVxAF
QnMKHmNvbS5nb29nbGUuY2xvdWQuY29ubmVjdG9ycy52MUIPQXV0aENvbmZpZ1Byb3RvUAFa
PmNsb3VkLmdvb2dsZS5jb20vZ28vY29ubmVjdG9ycy9hcGl2MS9jb25uZWN0b3JzcGI7Y29u
bmVjdG9yc3BiSqIlCgcSBQ4AkAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAjCgkKAgMAEgMSADEKCAoBCBIDFABVCgkKAggLEgMUAFUKCAoBCBIDFQAi
CgkKAggKEgMVACIKCAoBCBIDFgAwCgkKAggIEgMWADAKCAoBCBIDFwA3CgkKAggBEgMXADcK
QgoCBAASBBoAawEaNiBBdXRoQ29uZmlnIGRlZmluZXMgZGV0YWlscyBvZiBhIGF1dGhlbnRp
Y2F0aW9uIHR5cGUuCgoKCgMEAAESAxoIEgpLCgQEAAMAEgQcAiIDGj0gUGFyYW1ldGVycyB0
byBzdXBwb3J0IFVzZXJuYW1lIGFuZCBQYXNzd29yZCBBdXRoZW50aWNhdGlvbi4KCgwKBQQA
AwABEgMcChYKGgoGBAADAAIAEgMeBBgaCyBVc2VybmFtZS4KCg4KBwQAAwACAAUSAx4ECgoO
CgcEAAMAAgABEgMeCxMKDgoHBAADAAIAAxIDHhYXCkIKBgQAAwACARIDIQQYGjMgU2VjcmV0
IHZlcnNpb24gcmVmZXJlbmNlIGNvbnRhaW5pbmcgdGhlIHBhc3N3b3JkLgoKDgoHBAADAAIB
BhIDIQQKCg4KBwQAAwACAQESAyELEwoOCgcEAAMAAgEDEgMhFhcKtwEKBAQAAwESBCcCPAMa
qAEgUGFyYW1ldGVycyB0byBzdXBwb3J0IEpTT04gV2ViIFRva2VuIChKV1QpIFByb2ZpbGUg
Zm9yIE9hdXRoIDIuMAogQXV0aG9yaXphdGlvbiBHcmFudCBiYXNlZCBhdXRoZW50aWNhdGlv
bi4KIFNlZSBodHRwczovL3Rvb2xzLmlldGYub3JnL2h0bWwvcmZjNzUyMyBmb3IgbW9yZSBk
ZXRhaWxzLgoKDAoFBAADAQESAycKGQpJCgYEAAMBAwASBCkEMgUaOSBKV1QgY2xhaW1zIHVz
ZWQgZm9yIHRoZSBqd3QtYmVhcmVyIGF1dGhvcml6YXRpb24gZ3JhbnQuCgoOCgcEAAMBAwAB
EgMpDBUKLQoIBAADAQMAAgASAysGGBocIFZhbHVlIGZvciB0aGUgImlzcyIgY2xhaW0uCgoQ
CgkEAAMBAwACAAUSAysGDAoQCgkEAAMBAwACAAESAysNEwoQCgkEAAMBAwACAAMSAysWFwot
CggEAAMBAwACARIDLgYZGhwgVmFsdWUgZm9yIHRoZSAic3ViIiBjbGFpbS4KChAKCQQAAwED
AAIBBRIDLgYMChAKCQQAAwEDAAIBARIDLg0UChAKCQQAAwEDAAIBAxIDLhcYCi0KCAQAAwED
AAICEgMxBhoaHCBWYWx1ZSBmb3IgdGhlICJhdWQiIGNsYWltLgoKEAoJBAADAQMAAgIFEgMx
BgwKEAoJBAADAQMAAgIBEgMxDRUKEAoJBAADAQMAAgIDEgMxGBkKlgIKBgQAAwECABIDOAQa
GoYCIFNlY3JldCB2ZXJzaW9uIHJlZmVyZW5jZSBjb250YWluaW5nIGEgUEtDUyM4IFBFTS1l
bmNvZGVkIHByaXZhdGUKIGtleSBhc3NvY2lhdGVkIHdpdGggdGhlIENsaWVudCBDZXJ0aWZp
Y2F0ZS4gVGhpcyBwcml2YXRlIGtleSB3aWxsIGJlCiB1c2VkIHRvIHNpZ24gSldUcyB1c2Vk
IGZvciB0aGUgand0LWJlYXJlciBhdXRob3JpemF0aW9uIGdyYW50LgogU3BlY2lmaWVkIGlu
IHRoZSBmb3JtIGFzOiBgcHJvamVjdHMvKi9zZWNyZXRzLyovdmVyc2lvbnMvKmAuCgoOCgcE
AAMBAgAGEgM4BAoKDgoHBAADAQIAARIDOAsVCg4KBwQAAwECAAMSAzgYGQpCCgYEAAMBAgES
AzsEHRozIEp3dENsYWltcyBwcm92aWRlcnMgZmllbGRzIHRvIGdlbmVyYXRlIHRoZSB0b2tl
bi4KCg4KBwQAAwECAQYSAzsEDQoOCgcEAAMBAgEBEgM7DhgKDgoHBAADAQIBAxIDOxscCqIB
CgQEAAMCEgRAAkYDGpMBIFBhcmFtZXRlcnMgdG8gc3VwcG9ydCBPYXV0aCAyLjAgQ2xpZW50
IENyZWRlbnRpYWxzIEdyYW50IEF1dGhlbnRpY2F0aW9uLgogU2VlIGh0dHBzOi8vdG9vbHMu
aWV0Zi5vcmcvaHRtbC9yZmM2NzQ5I3NlY3Rpb24tMS4zLjQgZm9yIG1vcmUgZGV0YWlscy4K
CgwKBQQAAwIBEgNACiEKJwoGBAADAgIAEgNCBBkaGCBUaGUgY2xpZW50IGlkZW50aWZpZXIu
CgoOCgcEAAMCAgAFEgNCBAoKDgoHBAADAgIAARIDQgsUCg4KBwQAAwICAAMSA0IXGApHCgYE
AAMCAgESA0UEHRo4IFNlY3JldCB2ZXJzaW9uIHJlZmVyZW5jZSBjb250YWluaW5nIHRoZSBj
bGllbnQgc2VjcmV0LgoKDgoHBAADAgIBBhIDRQQKCg4KBwQAAwICAQESA0ULGAoOCgcEAAMC
AgEDEgNFGxwKRAoEBAADAxIESQJVAxo2IFBhcmFtZXRlcnMgdG8gc3VwcG9ydCBTc2ggcHVi
bGljIGtleSBBdXRoZW50aWNhdGlvbi4KCgwKBQQAAwMBEgNJChYKNwoGBAADAwIAEgNLBBga
KCBUaGUgdXNlciBhY2NvdW50IHVzZWQgdG8gYXV0aGVudGljYXRlLgoKDgoHBAADAwIABRID
SwQKCg4KBwQAAwMCAAESA0sLEwoOCgcEAAMDAgADEgNLFhcKUAoGBAADAwIBEgNOBB8aQSBT
U0ggQ2xpZW50IENlcnQuIEl0IHNob3VsZCBjb250YWluIGJvdGggcHVibGljIGFuZCBwcml2
YXRlIGtleS4KCg4KBwQAAwMCAQYSA04ECgoOCgcEAAMDAgEBEgNOCxoKDgoHBAADAwIBAxID
Th0eCisKBgQAAwMCAhIDUQQZGhwgRm9ybWF0IG9mIFNTSCBDbGllbnQgY2VydC4KCg4KBwQA
AwMCAgUSA1EECgoOCgcEAAMDAgIBEgNRCxQKDgoHBAADAwICAxIDURcYClAKBgQAAwMCAxID
VAQkGkEgUGFzc3dvcmQgKHBhc3NwaHJhc2UpIGZvciBzc2ggY2xpZW50IGNlcnRpZmljYXRl
IGlmIGl0IGhhcyBvbmUuCgoOCgcEAAMDAgMGEgNUBAoKDgoHBAADAwIDARIDVAsfCg4KBwQA
AwMCAwMSA1QiIwo1CgQEAAIAEgNYAhkaKCBUaGUgdHlwZSBvZiBhdXRoZW50aWNhdGlvbiBj
b25maWd1cmVkLgoKDAoFBAACAAYSA1gCCgoMCgUEAAIAARIDWAsUCgwKBQQAAgADEgNYFxgK
JQoEBAAIABIEWwJnAxoXIFN1cHBvcnRlZCBhdXRoIHR5cGVzLgoKDAoFBAAIAAESA1sIDAoc
CgQEAAIBEgNdBCMaDyBVc2VyUGFzc3dvcmQuCgoMCgUEAAIBBhIDXQQQCgwKBQQAAgEBEgNd
ER4KDAoFBAACAQMSA10hIgofCgQEAAICEgNgBCoaEiBPYXV0aDJKd3RCZWFyZXIuCgoMCgUE
AAICBhIDYAQTCgwKBQQAAgIBEgNgFCUKDAoFBAACAgMSA2AoKQonCgQEAAIDEgNjBDoaGiBP
YXV0aDJDbGllbnRDcmVkZW50aWFscy4KCgwKBQQAAgMGEgNjBBsKDAoFBAACAwESA2McNQoM
CgUEAAIDAxIDYzg5Ch4KBAQAAgQSA2YEJBoRIFNTSCBQdWJsaWMgS2V5LgoKDAoFBAACBAYS
A2YEEAoMCgUEAAIEARIDZhEfCgwKBQQAAgQDEgNmIiMKNwoEBAACBRIDagIzGiogTGlzdCBj
b250YWluaW5nIGFkZGl0aW9uYWwgYXV0aCBjb25maWdzLgoKDAoFBAACBQQSA2oCCgoMCgUE
AAIFBhIDagsZCgwKBQQAAgUBEgNqGi4KDAoFBAACBQMSA2oxMgpUCgIEARIEbgB6ARpIIEF1
dGhDb25maWdUZW1wbGF0ZSBkZWZpbmVzIHJlcXVpcmVkIGZpZWxkIG92ZXIgYW4gYXV0aGVu
dGljYXRpb24gdHlwZS4KCgoKAwQBARIDbggaCjUKBAQBAgASA3ACGRooIFRoZSB0eXBlIG9m
IGF1dGhlbnRpY2F0aW9uIGNvbmZpZ3VyZWQuCgoMCgUEAQIABhIDcAIKCgwKBQQBAgABEgNw
CxQKDAoFBAECAAMSA3AXGApPCgQEAQIBEgNzAkAaQiBDb25maWcgdmFyaWFibGVzIHRvIGRl
c2NyaWJlIGFuIGBBdXRoQ29uZmlnYCBmb3IgYSBgQ29ubmVjdGlvbmAuCgoMCgUEAQIBBBID
cwIKCgwKBQQBAgEGEgNzCyEKDAoFBAECAQESA3MiOwoMCgUEAQIBAxIDcz4/CjgKBAQBAgIS
A3YCGhorIERpc3BsYXkgbmFtZSBmb3IgYXV0aGVudGljYXRpb24gdGVtcGxhdGUuCgoMCgUE
AQICBRIDdgIICgwKBQQBAgIBEgN2CRUKDAoFBAECAgMSA3YYGQpNCgQEAQIDEgN5AhkaQCBD
b25uZWN0b3Igc3BlY2lmaWMgZGVzY3JpcHRpb24gZm9yIGFuIGF1dGhlbnRpY2F0aW9uIHRl
bXBsYXRlLgoKDAoFBAECAwUSA3kCCAoMCgUEAQIDARIDeQkUCgwKBQQBAgMDEgN5FxgKPwoC
BQASBX0AkAEBGjIgQXV0aFR5cGUgZGVmaW5lcyBkaWZmZXJlbnQgYXV0aGVudGljYXRpb24g
dHlwZXMuCgoKCgMFAAESA30FDQoxCgQFAAIAEgN/AhwaJCBBdXRoZW50aWNhdGlvbiB0eXBl
IG5vdCBzcGVjaWZpZWQuCgoMCgUFAAIAARIDfwIXCgwKBQUAAgACEgN/GhsKNQoEBQACARIE
ggECFBonIFVzZXJuYW1lIGFuZCBQYXNzd29yZCBBdXRoZW50aWNhdGlvbi4KCg0KBQUAAgEB
EgSCAQIPCg0KBQUAAgECEgSCARITCmQKBAUAAgISBIYBAhgaViBKU09OIFdlYiBUb2tlbiAo
SldUKSBQcm9maWxlIGZvciBPYXV0aCAyLjAKIEF1dGhvcml6YXRpb24gR3JhbnQgYmFzZWQg
YXV0aGVudGljYXRpb24KCg0KBQUAAgIBEgSGAQITCg0KBQUAAgICEgSGARYXCkEKBAUAAgMS
BIkBAiAaMyBPYXV0aCAyLjAgQ2xpZW50IENyZWRlbnRpYWxzIEdyYW50IEF1dGhlbnRpY2F0
aW9uCgoNCgUFAAIDARIEiQECGwoNCgUFAAIDAhIEiQEeHwotCgQFAAIEEgSMAQIVGh8gU1NI
IFB1YmxpYyBLZXkgQXV0aGVudGljYXRpb24KCg0KBQUAAgQBEgSMAQIQCg0KBQUAAgQCEgSM
ARMUCjEKBAUAAgUSBI8BAhwaIyBPYXV0aCAyLjAgQXV0aG9yaXphdGlvbiBDb2RlIEZsb3cK
Cg0KBQUAAgUBEgSPAQIXCg0KBQUAAgUCEgSPARobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::Authconfig::AuthConfig ===
    # Fields for AuthConfig
    # Field: auth_type Type: 14 (.google.cloud.connectors.v1.AuthType)
    # Field: user_password Type: 11 (.google.cloud.connectors.v1.AuthConfig.UserPassword)
    # Field: oauth2_jwt_bearer Type: 11 (.google.cloud.connectors.v1.AuthConfig.Oauth2JwtBearer)
    # Field: oauth2_client_credentials Type: 11 (.google.cloud.connectors.v1.AuthConfig.Oauth2ClientCredentials)
    # Field: ssh_public_key Type: 11 (.google.cloud.connectors.v1.AuthConfig.SshPublicKey)
    # Field: additional_variables Type: 11 (.google.cloud.connectors.v1.ConfigVariable)

# === Message: Google::Cloud::Connectors::V1::Authconfig::AuthConfigTemplate ===
    # Fields for AuthConfigTemplate
    # Field: auth_type Type: 14 (.google.cloud.connectors.v1.AuthType)
    # Field: config_variable_templates Type: 11 (.google.cloud.connectors.v1.ConfigVariableTemplate)
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::Authconfig - Compiled Protocol Buffers messages for google/cloud/connectors/v1/authconfig.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::Authconfig;

    my $msg = Google::Cloud::Connectors::V1::Authconfig::AuthConfig->new({
        auth_type => $auth_type,
        user_password => $user_password,
        oauth2_jwt_bearer => $oauth2_jwt_bearer,
        oauth2_client_credentials => $oauth2_client_credentials,
    });

    # Read or update a field
    my $val = $msg->auth_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::Authconfig::AuthConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/authconfig.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::Authconfig::AuthConfig

AuthConfig defines details of a authentication type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auth_type() >> / C<< $msg->auth_type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::AuthType>)

The type of authentication configured.

=item * C<< $msg->user_password() >> / C<< $msg->user_password($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Authconfig::AuthConfig::UserPassword>)

UserPassword.

=item * C<< $msg->oauth2_jwt_bearer() >> / C<< $msg->oauth2_jwt_bearer($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2JwtBearer>)

Oauth2JwtBearer.

=item * C<< $msg->oauth2_client_credentials() >> / C<< $msg->oauth2_client_credentials($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2ClientCredentials>)

Oauth2ClientCredentials.

=item * C<< $msg->ssh_public_key() >> / C<< $msg->ssh_public_key($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Authconfig::AuthConfig::SshPublicKey>)

SSH Public Key.

=item * C<< $msg->additional_variables() >> / C<< $msg->additional_variables($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::ConfigVariable>)

List containing additional auth configs.

=back

=head2 Google::Cloud::Connectors::V1::Authconfig::AuthConfigTemplate

AuthConfigTemplate defines required field over an authentication type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->auth_type() >> / C<< $msg->auth_type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::AuthType>)

The type of authentication configured.

=item * C<< $msg->config_variable_templates() >> / C<< $msg->config_variable_templates($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::ConfigVariableTemplate>)

Config variables to describe an `AuthConfig` for a `Connection`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name for authentication template.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Connector specific description for an authentication template.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::Authconfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
