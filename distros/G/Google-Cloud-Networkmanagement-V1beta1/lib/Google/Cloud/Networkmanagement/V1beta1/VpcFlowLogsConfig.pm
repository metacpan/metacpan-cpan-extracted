package Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig;

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
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvbmV0d29ya21hbmFnZW1lbnQvdjFiZXRhMS92cGNfZmxvd19sb2dz
X2NvbmZpZy5wcm90bxImZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEa
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8isxIKEVZwY0Zsb3dMb2dz
Q29uZmlnEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIqCgtkZXNjcmlwdGlvbhgCIAEoCUID
4EEBSAFSC2Rlc2NyaXB0aW9uiAEBEl8KBXN0YXRlGAMgASgOMj8uZ29vZ2xlLmNsb3VkLm5l
dHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuVnBjRmxvd0xvZ3NDb25maWcuU3RhdGVCA+BBAUgC
UgVzdGF0ZYgBARKKAQoUYWdncmVnYXRpb25faW50ZXJ2YWwYBCABKA4yTS5nb29nbGUuY2xv
dWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5WcGNGbG93TG9nc0NvbmZpZy5BZ2dyZWdh
dGlvbkludGVydmFsQgPgQQFIA1ITYWdncmVnYXRpb25JbnRlcnZhbIgBARItCg1mbG93X3Nh
bXBsaW5nGAUgASgCQgPgQQFIBFIMZmxvd1NhbXBsaW5niAEBEmgKCG1ldGFkYXRhGAYgASgO
MkIuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuVnBjRmxvd0xvZ3ND
b25maWcuTWV0YWRhdGFCA+BBAUgFUghtZXRhZGF0YYgBARIsCg9tZXRhZGF0YV9maWVsZHMY
ByADKAlCA+BBAVIObWV0YWRhdGFGaWVsZHMSKQoLZmlsdGVyX2V4cHIYCCABKAlCA+BBAUgG
UgpmaWx0ZXJFeHByiAEBEo4BChZjcm9zc19wcm9qZWN0X21ldGFkYXRhGA0gASgOMk4uZ29v
Z2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuVnBjRmxvd0xvZ3NDb25maWcu
Q3Jvc3NQcm9qZWN0TWV0YWRhdGFCA+BBAUgHUhRjcm9zc1Byb2plY3RNZXRhZGF0YYgBARKL
AQoVdGFyZ2V0X3Jlc291cmNlX3N0YXRlGAwgASgOMk0uZ29vZ2xlLmNsb3VkLm5ldHdvcmtt
YW5hZ2VtZW50LnYxYmV0YTEuVnBjRmxvd0xvZ3NDb25maWcuVGFyZ2V0UmVzb3VyY2VTdGF0
ZUID4EEDSAhSE3RhcmdldFJlc291cmNlU3RhdGWIAQESGgoHbmV0d29yaxhkIAEoCUgAUgdu
ZXR3b3JrEhgKBnN1Ym5ldBhlIAEoCUgAUgZzdWJuZXQSOQoXaW50ZXJjb25uZWN0X2F0dGFj
aG1lbnQYZiABKAlIAFIWaW50ZXJjb25uZWN0QXR0YWNobWVudBIfCgp2cG5fdHVubmVsGGcg
ASgJSABSCXZwblR1bm5lbBJiCgZsYWJlbHMYCyADKAsyRS5nb29nbGUuY2xvdWQubmV0d29y
a21hbmFnZW1lbnQudjFiZXRhMS5WcGNGbG93TG9nc0NvbmZpZy5MYWJlbHNFbnRyeUID4EEB
UgZsYWJlbHMSQAoLY3JlYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCiABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUaOQoLTGFiZWxzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASI5CgVTdGF0ZRIVChFTVEFU
RV9VTlNQRUNJRklFRBAAEgsKB0VOQUJMRUQQARIMCghESVNBQkxFRBACIrYBChNBZ2dyZWdh
dGlvbkludGVydmFsEiQKIEFHR1JFR0FUSU9OX0lOVEVSVkFMX1VOU1BFQ0lGSUVEEAASEgoO
SU5URVJWQUxfNV9TRUMQARITCg9JTlRFUlZBTF8zMF9TRUMQAhISCg5JTlRFUlZBTF8xX01J
ThADEhIKDklOVEVSVkFMXzVfTUlOEAQSEwoPSU5URVJWQUxfMTBfTUlOEAUSEwoPSU5URVJW
QUxfMTVfTUlOEAYibQoITWV0YWRhdGESGAoUTUVUQURBVEFfVU5TUEVDSUZJRUQQABIYChRJ
TkNMVURFX0FMTF9NRVRBREFUQRABEhgKFEVYQ0xVREVfQUxMX01FVEFEQVRBEAISEwoPQ1VT
VE9NX01FVEFEQVRBEAMihwEKFENyb3NzUHJvamVjdE1ldGFkYXRhEiYKIkNST1NTX1BST0pF
Q1RfTUVUQURBVEFfVU5TUEVDSUZJRUQQABIiCh5DUk9TU19QUk9KRUNUX01FVEFEQVRBX0VO
QUJMRUQQARIjCh9DUk9TU19QUk9KRUNUX01FVEFEQVRBX0RJU0FCTEVEEAIifAoTVGFyZ2V0
UmVzb3VyY2VTdGF0ZRIlCiFUQVJHRVRfUkVTT1VSQ0VfU1RBVEVfVU5TUEVDSUZJRUQQABIa
ChZUQVJHRVRfUkVTT1VSQ0VfRVhJU1RTEAESIgoeVEFSR0VUX1JFU09VUkNFX0RPRVNfTk9U
X0VYSVNUEAI6jwLqQYsCCjJuZXR3b3JrbWFuYWdlbWVudC5nb29nbGVhcGlzLmNvbS9WcGNG
bG93TG9nc0NvbmZpZxJRcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L3ZwY0Zsb3dMb2dzQ29uZmlncy97dnBjX2Zsb3dfbG9nc19jb25maWd9Eltvcmdhbml6YXRp
b25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L3ZwY0Zsb3dMb2dzQ29u
Zmlncy97dnBjX2Zsb3dfbG9nc19jb25maWd9KhJ2cGNGbG93TG9nc0NvbmZpZ3MyEXZwY0Zs
b3dMb2dzQ29uZmlnQhEKD3RhcmdldF9yZXNvdXJjZUIOCgxfZGVzY3JpcHRpb25CCAoGX3N0
YXRlQhcKFV9hZ2dyZWdhdGlvbl9pbnRlcnZhbEIQCg5fZmxvd19zYW1wbGluZ0ILCglfbWV0
YWRhdGFCDgoMX2ZpbHRlcl9leHByQhkKF19jcm9zc19wcm9qZWN0X21ldGFkYXRhQhgKFl90
YXJnZXRfcmVzb3VyY2Vfc3RhdGUikAkKGkVmZmVjdGl2ZVZwY0Zsb3dMb2dzQ29uZmlnEhIK
BG5hbWUYASABKAlSBG5hbWUSWgoFc3RhdGUYAyABKA4yPy5nb29nbGUuY2xvdWQubmV0d29y
a21hbmFnZW1lbnQudjFiZXRhMS5WcGNGbG93TG9nc0NvbmZpZy5TdGF0ZUgBUgVzdGF0ZYgB
ARKFAQoUYWdncmVnYXRpb25faW50ZXJ2YWwYBCABKA4yTS5nb29nbGUuY2xvdWQubmV0d29y
a21hbmFnZW1lbnQudjFiZXRhMS5WcGNGbG93TG9nc0NvbmZpZy5BZ2dyZWdhdGlvbkludGVy
dmFsSAJSE2FnZ3JlZ2F0aW9uSW50ZXJ2YWyIAQESKAoNZmxvd19zYW1wbGluZxgFIAEoAkgD
UgxmbG93U2FtcGxpbmeIAQESYwoIbWV0YWRhdGEYBiABKA4yQi5nb29nbGUuY2xvdWQubmV0
d29ya21hbmFnZW1lbnQudjFiZXRhMS5WcGNGbG93TG9nc0NvbmZpZy5NZXRhZGF0YUgEUght
ZXRhZGF0YYgBARInCg9tZXRhZGF0YV9maWVsZHMYByADKAlSDm1ldGFkYXRhRmllbGRzEiQK
C2ZpbHRlcl9leHByGAggASgJSAVSCmZpbHRlckV4cHKIAQESiQEKFmNyb3NzX3Byb2plY3Rf
bWV0YWRhdGEYDSABKA4yTi5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRh
MS5WcGNGbG93TG9nc0NvbmZpZy5Dcm9zc1Byb2plY3RNZXRhZGF0YUgGUhRjcm9zc1Byb2pl
Y3RNZXRhZGF0YYgBARIaCgduZXR3b3JrGGQgASgJSABSB25ldHdvcmsSGAoGc3VibmV0GGUg
ASgJSABSBnN1Ym5ldBI5ChdpbnRlcmNvbm5lY3RfYXR0YWNobWVudBhmIAEoCUgAUhZpbnRl
cmNvbm5lY3RBdHRhY2htZW50Eh8KCnZwbl90dW5uZWwYZyABKAlIAFIJdnBuVHVubmVsEmMK
BXNjb3BlGAwgASgOMkguZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEu
RWZmZWN0aXZlVnBjRmxvd0xvZ3NDb25maWcuU2NvcGVIB1IFc2NvcGWIAQEijgEKBVNjb3Bl
EhUKEVNDT1BFX1VOU1BFQ0lGSUVEEAASCgoGU1VCTkVUEAESFgoSQ09NUFVURV9BUElfU1VC
TkVUEAISCwoHTkVUV09SSxADEg4KClZQTl9UVU5ORUwQBBIbChdJTlRFUkNPTk5FQ1RfQVRU
QUNITUVOVBAFEhAKDE9SR0FOSVpBVElPThAGQhEKD3RhcmdldF9yZXNvdXJjZUIICgZfc3Rh
dGVCFwoVX2FnZ3JlZ2F0aW9uX2ludGVydmFsQhAKDl9mbG93X3NhbXBsaW5nQgsKCV9tZXRh
ZGF0YUIOCgxfZmlsdGVyX2V4cHJCGQoXX2Nyb3NzX3Byb2plY3RfbWV0YWRhdGFCCAoGX3Nj
b3BlQosDCipjb20uZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTFCFlZw
Y0Zsb3dMb2dzQ29uZmlnUHJvdG9QAVpYY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3JrbWFu
YWdlbWVudC9hcGl2MWJldGExL25ldHdvcmttYW5hZ2VtZW50cGI7bmV0d29ya21hbmFnZW1l
bnRwYqoCJkdvb2dsZS5DbG91ZC5OZXR3b3JrTWFuYWdlbWVudC5WMUJldGExygImR29vZ2xl
XENsb3VkXE5ldHdvcmtNYW5hZ2VtZW50XFYxYmV0YTHqAilHb29nbGU6OkNsb3VkOjpOZXR3
b3JrTWFuYWdlbWVudDo6VjFiZXRhMepBago1bmV0d29ya21hbmFnZW1lbnQuZ29vZ2xlYXBp
cy5jb20vT3JnYW5pemF0aW9uTG9jYXRpb24SMW9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlv
bn0vbG9jYXRpb25zL3tsb2NhdGlvbn1K410KBxIFDgC4AgEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC8KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMC
EgMUACkKCAoBCBIDFgBDCgkKAgglEgMWAEMKCAoBCBIDFwBvCgkKAggLEgMXAG8KCAoBCBID
GAAiCgkKAggKEgMYACIKCAoBCBIDGQA3CgkKAggIEgMZADcKCAoBCBIDGgBDCgkKAggBEgMa
AEMKCAoBCBIDGwBDCgkKAggpEgMbAEMKCAoBCBIDHABCCgkKAggtEgMcAEIKCQoBCBIEHQAg
AgoMCgQInQgAEgQdACACCjkKAgQAEgUjANMBARosIEEgY29uZmlndXJhdGlvbiB0byBnZW5l
cmF0ZSBWUEMgRmxvdyBMb2dzLgoKCgoDBAABEgMjCBkKCwoDBAAHEgQkAioECg0KBQQAB50I
EgQkAioECk4KBAQABAASBC0CNgMaQCBEZXRlcm1pbmVzIHdoZXRoZXIgdGhpcyBjb25maWd1
cmF0aW9uIHdpbGwgYmUgZ2VuZXJhdGluZyBsb2dzLgoKDAoFBAAEAAESAy0HDAo7CgYEAAQA
AgASAy8EGhosIElmIG5vdCBzcGVjaWZpZWQsIHdpbGwgZGVmYXVsdCB0byBFTkFCTEVELgoK
DgoHBAAEAAIAARIDLwQVCg4KBwQABAACAAISAy8YGQpFCgYEAAQAAgESAzIEEBo2IFdoZW4g
RU5BQkxFRCwgdGhpcyBjb25maWd1cmF0aW9uIHdpbGwgZ2VuZXJhdGUgbG9ncy4KCg4KBwQA
BAACAQESAzIECwoOCgcEAAQAAgECEgMyDg8KSgoGBAAEAAICEgM1BBEaOyBXaGVuIERJU0FC
TEVELCB0aGlzIGNvbmZpZ3VyYXRpb24gd2lsbCBub3QgZ2VuZXJhdGUgbG9ncy4KCg4KBwQA
BAACAgESAzUEDAoOCgcEAAQAAgICEgM1DxAKVQoEBAAEARIEOQJOAxpHIFRvZ2dsZXMgdGhl
IGFnZ3JlZ2F0aW9uIGludGVydmFsIGZvciBjb2xsZWN0aW5nIGZsb3cgbG9ncyBieSA1LXR1
cGxlLgoKDAoFBAAEAQESAzkHGgpCCgYEAAQBAgASAzsEKRozIElmIG5vdCBzcGVjaWZpZWQs
IHdpbGwgZGVmYXVsdCB0byBJTlRFUlZBTF81X1NFQy4KCg4KBwQABAECAAESAzsEJAoOCgcE
AAQBAgACEgM7JygKMAoGBAAEAQIBEgM+BBcaISBBZ2dyZWdhdGUgbG9ncyBpbiA1cyBpbnRl
cnZhbHMuCgoOCgcEAAQBAgEBEgM+BBIKDgoHBAAEAQIBAhIDPhUWCjEKBgQABAECAhIDQQQY
GiIgQWdncmVnYXRlIGxvZ3MgaW4gMzBzIGludGVydmFscy4KCg4KBwQABAECAgESA0EEEwoO
CgcEAAQBAgICEgNBFhcKMAoGBAAEAQIDEgNEBBcaISBBZ2dyZWdhdGUgbG9ncyBpbiAxbSBp
bnRlcnZhbHMuCgoOCgcEAAQBAgMBEgNEBBIKDgoHBAAEAQIDAhIDRBUWCjAKBgQABAECBBID
RwQXGiEgQWdncmVnYXRlIGxvZ3MgaW4gNW0gaW50ZXJ2YWxzLgoKDgoHBAAEAQIEARIDRwQS
Cg4KBwQABAECBAISA0cVFgoxCgYEAAQBAgUSA0oEGBoiIEFnZ3JlZ2F0ZSBsb2dzIGluIDEw
bSBpbnRlcnZhbHMuCgoOCgcEAAQBAgUBEgNKBBMKDgoHBAAEAQIFAhIDShYXCjEKBgQABAEC
BhIDTQQYGiIgQWdncmVnYXRlIGxvZ3MgaW4gMTVtIGludGVydmFscy4KCg4KBwQABAECBgES
A00EEwoOCgcEAAQBAgYCEgNNFhcKPgoEBAAEAhIEUQJdAxowIENvbmZpZ3VyZXMgd2hpY2gg
bG9nIGZpZWxkcyB3b3VsZCBiZSBpbmNsdWRlZC4KCgwKBQQABAIBEgNRBw8KSAoGBAAEAgIA
EgNTBB0aOSBJZiBub3Qgc3BlY2lmaWVkLCB3aWxsIGRlZmF1bHQgdG8gSU5DTFVERV9BTExf
TUVUQURBVEEuCgoOCgcEAAQCAgABEgNTBBgKDgoHBAAEAgIAAhIDUxscCi0KBgQABAICARID
VgQdGh4gSW5jbHVkZSBhbGwgbWV0YWRhdGEgZmllbGRzLgoKDgoHBAAEAgIBARIDVgQYCg4K
BwQABAICAQISA1YbHAotCgYEAAQCAgISA1kEHRoeIEV4Y2x1ZGUgYWxsIG1ldGFkYXRhIGZp
ZWxkcy4KCg4KBwQABAICAgESA1kEGAoOCgcEAAQCAgICEgNZGxwKSwoGBAAEAgIDEgNcBBga
PCBJbmNsdWRlIG9ubHkgY3VzdG9tIGZpZWxkcyAoc3BlY2lmaWVkIGluIG1ldGFkYXRhX2Zp
ZWxkcykuCgoOCgcEAAQCAgMBEgNcBBMKDgoHBAAEAgIDAhIDXBYXCp8BCgQEAAQDEgRhAmwD
GpABIERldGVybWluZXMgd2hldGhlciB0byBpbmNsdWRlIGNyb3NzIHByb2plY3QgYW5ub3Rh
dGlvbnMgaW4gdGhlIGxvZ3MuCiBQcm9qZWN0IGNvbmZpZ3VyYXRpb25zIHdpbGwgYWx3YXlz
IGhhdmUgQ1JPU1NfUFJPSkVDVF9NRVRBREFUQV9ESVNBQkxFRC4KCgwKBQQABAMBEgNhBxsK
UQoGBAAEAwIAEgNjBCsaQiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgZGVmYXVsdCBpcyBDUk9T
U19QUk9KRUNUX01FVEFEQVRBX0VOQUJMRUQuCgoOCgcEAAQDAgABEgNjBCYKDgoHBAAEAwIA
AhIDYykqCnEKBgQABAMCARIDZwQnGmIgV2hlbiBDUk9TU19QUk9KRUNUX01FVEFEQVRBX0VO
QUJMRUQsIG1ldGFkYXRhIGZyb20gb3RoZXIgcHJvamVjdHMgd2lsbCBiZQogaW5jbHVkZWQg
aW4gdGhlIGxvZ3MuCgoOCgcEAAQDAgEBEgNnBCIKDgoHBAAEAwIBAhIDZyUmCnYKBgQABAMC
AhIDawQoGmcgV2hlbiBDUk9TU19QUk9KRUNUX01FVEFEQVRBX0RJU0FCTEVELCBtZXRhZGF0
YSBmcm9tIG90aGVyIHByb2plY3RzIHdpbGwKIG5vdCBiZSBpbmNsdWRlZCBpbiB0aGUgbG9n
cy4KCg4KBwQABAMCAgESA2sEIwoOCgcEAAQDAgICEgNrJicKZAoEBAAEBBIEcAJ5AxpWIE91
dHB1dCBvbmx5LiBJbmRpY2F0ZXMgd2hldGhlciB0aGUgdGFyZ2V0IHJlc291cmNlIGV4aXN0
cywgZm9yIGRpYWdub3N0aWMKIHB1cnBvc2VzLgoKDAoFBAAEBAESA3AHGgozCgYEAAQEAgAS
A3IEKhokIFVuc3BlY2lmaWVkIHRhcmdldCByZXNvdXJjZSBzdGF0ZS4KCg4KBwQABAQCAAES
A3IEJQoOCgcEAAQEAgACEgNyKCkKOwoGBAAEBAIBEgN1BB8aLCBJbmRpY2F0ZXMgdGhhdCB0
aGUgdGFyZ2V0IHJlc291cmNlIGV4aXN0cy4KCg4KBwQABAQCAQESA3UEGgoOCgcEAAQEAgEC
EgN1HR4KQwoGBAAEBAICEgN4BCcaNCBJbmRpY2F0ZXMgdGhhdCB0aGUgdGFyZ2V0IHJlc291
cmNlIGRvZXMgbm90IGV4aXN0LgoKDgoHBAAEBAICARIDeAQiCg4KBwQABAQCAgISA3glJgr2
AgoEBAACABIEgwECPRrnAiBJZGVudGlmaWVyLiBVbmlxdWUgbmFtZSBvZiB0aGUgY29uZmln
dXJhdGlvbi4gVGhlIG5hbWUgY2FuIGhhdmUgb25lIG9mIHRoZQogZm9sbG93aW5nIGZvcm1z
OgoKIC0gRm9yIHByb2plY3QtbGV2ZWwgY29uZmlndXJhdGlvbnM6CiBgcHJvamVjdHMve3By
b2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwvdnBjRmxvd0xvZ3NDb25maWdzL3t2cGNfZmxv
d19sb2dzX2NvbmZpZ19pZH1gCgogLSBGb3Igb3JnYW5pemF0aW9uLWxldmVsIGNvbmZpZ3Vy
YXRpb25zOgogYG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL2ds
b2JhbC92cGNGbG93TG9nc0NvbmZpZ3Mve3ZwY19mbG93X2xvZ3NfY29uZmlnX2lkfWAKCg0K
BQQAAgAFEgSDAQIICg0KBQQAAgABEgSDAQkNCg0KBQQAAgADEgSDARARCg0KBQQAAgAIEgSD
ARI8ChAKCAQAAgAInAgAEgSDARM7CncKBAQAAgESBIcBAksaaSBPcHRpb25hbC4gVGhlIHVz
ZXItc3VwcGxpZWQgZGVzY3JpcHRpb24gb2YgdGhlIFZQQyBGbG93IExvZ3MgY29uZmlndXJh
dGlvbi4KIE1heGltdW0gb2YgNTEyIGNoYXJhY3RlcnMuCgoNCgUEAAIBBBIEhwECCgoNCgUE
AAIBBRIEhwELEQoNCgUEAAIBARIEhwESHQoNCgUEAAIBAxIEhwEgIQoNCgUEAAIBCBIEhwEi
SgoQCggEAAIBCJwIABIEhwEjSQrgAQoEBAACAhIEjAECRBrRASBPcHRpb25hbC4gVGhlIHN0
YXRlIG9mIHRoZSBWUEMgRmxvdyBMb2cgY29uZmlndXJhdGlvbi4gRGVmYXVsdCB2YWx1ZSBp
cwogRU5BQkxFRC4gV2hlbiBjcmVhdGluZyBhIG5ldyBjb25maWd1cmF0aW9uLCBpdCBtdXN0
IGJlIGVuYWJsZWQuIFNldHRpbmcKIHN0YXRlPURJU0FCTEVEIHdpbGwgcGF1c2UgdGhlIGxv
ZyBnZW5lcmF0aW9uIGZvciB0aGlzIGNvbmZpZy4KCg0KBQQAAgIEEgSMAQIKCg0KBQQAAgIG
EgSMAQsQCg0KBQQAAgIBEgSMAREWCg0KBQQAAgIDEgSMARkaCg0KBQQAAgIIEgSMARtDChAK
CAQAAgIInAgAEgSMARxCCmQKBAQAAgMSBpABApEBLxpUIE9wdGlvbmFsLiBUaGUgYWdncmVn
YXRpb24gaW50ZXJ2YWwgZm9yIHRoZSBsb2dzLiBEZWZhdWx0IHZhbHVlIGlzCiBJTlRFUlZB
TF81X1NFQy4KCg0KBQQAAgMEEgSQAQIKCg0KBQQAAgMGEgSQAQseCg0KBQQAAgMBEgSQAR8z
Cg0KBQQAAgMDEgSQATY3Cg0KBQQAAgMIEgSRAQYuChAKCAQAAgMInAgAEgSRAQctCqUCCgQE
AAIEEgSXAQJMGpYCIE9wdGlvbmFsLiBUaGUgdmFsdWUgb2YgdGhlIGZpZWxkIG11c3QgYmUg
aW4gKDAsIDFdLiBUaGUgc2FtcGxpbmcgcmF0ZSBvZgogVlBDIEZsb3cgTG9ncyB3aGVyZSAx
LjAgbWVhbnMgYWxsIGNvbGxlY3RlZCBsb2dzIGFyZSByZXBvcnRlZC4gU2V0dGluZyB0aGUK
IHNhbXBsaW5nIHJhdGUgdG8gMC4wIGlzIG5vdCBhbGxvd2VkLiBJZiB5b3Ugd2FudCB0byBk
aXNhYmxlIFZQQyBGbG93IExvZ3MsCiB1c2UgdGhlIHN0YXRlIGZpZWxkIGluc3RlYWQuIERl
ZmF1bHQgdmFsdWUgaXMgMS4wLgoKDQoFBAACBAQSBJcBAgoKDQoFBAACBAUSBJcBCxAKDQoF
BAACBAESBJcBER4KDQoFBAACBAMSBJcBISIKDQoFBAACBAgSBJcBI0sKEAoIBAACBAicCAAS
BJcBJEoKrgEKBAQAAgUSBJwBAkoanwEgT3B0aW9uYWwuIENvbmZpZ3VyZXMgd2hldGhlciBh
bGwsIG5vbmUgb3IgYSBzdWJzZXQgb2YgbWV0YWRhdGEgZmllbGRzCiBzaG91bGQgYmUgYWRk
ZWQgdG8gdGhlIHJlcG9ydGVkIFZQQyBmbG93IGxvZ3MuIERlZmF1bHQgdmFsdWUgaXMKIElO
Q0xVREVfQUxMX01FVEFEQVRBLgoKDQoFBAACBQQSBJwBAgoKDQoFBAACBQYSBJwBCxMKDQoF
BAACBQESBJwBFBwKDQoFBAACBQMSBJwBHyAKDQoFBAACBQgSBJwBIUkKEAoIBAACBQicCAAS
BJwBIkgKnAEKBAQAAgYSBKABAk8ajQEgT3B0aW9uYWwuIEN1c3RvbSBtZXRhZGF0YSBmaWVs
ZHMgdG8gaW5jbHVkZSBpbiB0aGUgcmVwb3J0ZWQgVlBDIGZsb3cgbG9ncy4KIENhbiBvbmx5
IGJlIHNwZWNpZmllZCBpZiAibWV0YWRhdGEiIHdhcyBzZXQgdG8gQ1VTVE9NX01FVEFEQVRB
LgoKDQoFBAACBgQSBKABAgoKDQoFBAACBgUSBKABCxEKDQoFBAACBgESBKABEiEKDQoFBAAC
BgMSBKABJCUKDQoFBAACBggSBKABJk4KEAoIBAACBgicCAASBKABJ00KXQoEBAACBxIEpAEC
SxpPIE9wdGlvbmFsLiBFeHBvcnQgZmlsdGVyIHVzZWQgdG8gZGVmaW5lIHdoaWNoIFZQQyBG
bG93IExvZ3Mgc2hvdWxkIGJlCiBsb2dnZWQuCgoNCgUEAAIHBBIEpAECCgoNCgUEAAIHBRIE
pAELEQoNCgUEAAIHARIEpAESHQoNCgUEAAIHAxIEpAEgIQoNCgUEAAIHCBIEpAEiSgoQCggE
AAIHCJwIABIEpAEjSQrwAQoEBAACCBIGqQECqgEvGt8BIE9wdGlvbmFsLiBEZXRlcm1pbmVz
IHdoZXRoZXIgdG8gaW5jbHVkZSBjcm9zcyBwcm9qZWN0IGFubm90YXRpb25zIGluIHRoZQog
bG9ncy4gVGhpcyBmaWVsZCBpcyBhdmFpbGFibGUgb25seSBmb3Igb3JnYW5pemF0aW9uIGNv
bmZpZ3VyYXRpb25zLiBJZiBub3QKIHNwZWNpZmllZCBpbiBvcmcgY29uZmlncyB3aWxsIGJl
IHNldCB0byBDUk9TU19QUk9KRUNUX01FVEFEQVRBX0VOQUJMRUQuCgoNCgUEAAIIBBIEqQEC
CgoNCgUEAAIIBhIEqQELHwoNCgUEAAIIARIEqQEgNgoNCgUEAAIIAxIEqQE5OwoNCgUEAAII
CBIEqgEGLgoQCggEAAIICJwIABIEqgEHLQpuCgQEAAIJEgauAQKvATIaXiBPdXRwdXQgb25s
eS4gRGVzY3JpYmVzIHRoZSBzdGF0ZSBvZiB0aGUgY29uZmlndXJlZCB0YXJnZXQgcmVzb3Vy
Y2UgZm9yCiBkaWFnbm9zdGljIHB1cnBvc2VzLgoKDQoFBAACCQQSBK4BAgoKDQoFBAACCQYS
BK4BCx4KDQoFBAACCQESBK4BHzQKDQoFBAACCQMSBK4BNzkKDQoFBAACCQgSBK8BBjEKEAoI
BAACCQicCAASBK8BBzAKggIKBAQACAASBrUBAscBAxrxASBSZWZlcmVuY2UgdG8gdGhlIHJl
c291cmNlIG9mIHRoZSBjb25maWcgc2NvcGUuIFRoYXQgaXMsIHRoZSBzY29wZSBmcm9tCiB3
aGljaCB0cmFmZmljIGlzIGxvZ2dlZC4gVGhlIHRhcmdldCByZXNvdXJjZSBtdXN0IGJlbG9u
ZyB0byB0aGUgc2FtZQogcHJvamVjdCBhcyB0aGUgY29uZmlndXJhdGlvbi4KIFRoaXMgZmll
bGQgaXMgbm90IHN1cHBvcnRlZCBmb3Igb3JnYW5pemF0aW9uIGxldmVsIGNvbmZpZ3VyYXRp
b25zLgoKDQoFBAAIAAESBLUBCBcKpQEKBAQAAgoSBLkBBBkalgEgVHJhZmZpYyB3aWxsIGJl
IGxvZ2dlZCBmcm9tIFZNcywgVlBOIHR1bm5lbHMgYW5kIEludGVyY29ubmVjdCBBdHRhY2ht
ZW50cwogd2l0aGluIHRoZSBuZXR3b3JrLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdF9p
ZH0vZ2xvYmFsL25ldHdvcmtzL3tuYW1lfQoKDQoFBAACCgUSBLkBBAoKDQoFBAACCgESBLkB
CxIKDQoFBAACCgMSBLkBFRgKiQEKBAQAAgsSBL0BBBgaeyBUcmFmZmljIHdpbGwgYmUgbG9n
Z2VkIGZyb20gVk1zIHdpdGhpbiB0aGUgc3VibmV0d29yay4KIEZvcm1hdDogcHJvamVjdHMv
e3Byb2plY3RfaWR9L3JlZ2lvbnMve3JlZ2lvbn0vc3VibmV0d29ya3Mve25hbWV9CgoNCgUE
AAILBRIEvQEECgoNCgUEAAILARIEvQELEQoNCgUEAAILAxIEvQEUFwqZAQoEBAACDBIEwgEE
KRqKASBUcmFmZmljIHdpbGwgYmUgbG9nZ2VkIGZyb20gdGhlIEludGVyY29ubmVjdCBBdHRh
Y2htZW50LgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3RfaWR9L3JlZ2lvbnMve3JlZ2lv
bn0vaW50ZXJjb25uZWN0QXR0YWNobWVudHMve25hbWV9CgoNCgUEAAIMBRIEwgEECgoNCgUE
AAIMARIEwgELIgoNCgUEAAIMAxIEwgElKAp9CgQEAAINEgTGAQQcGm8gVHJhZmZpYyB3aWxs
IGJlIGxvZ2dlZCBmcm9tIHRoZSBWUE4gVHVubmVsLgogRm9ybWF0OiBwcm9qZWN0cy97cHJv
amVjdF9pZH0vcmVnaW9ucy97cmVnaW9ufS92cG5UdW5uZWxzL3tuYW1lfQoKDQoFBAACDQUS
BMYBBAoKDQoFBAACDQESBMYBCxUKDQoFBAACDQMSBMYBGBsKTgoEBAACDhIEygECSxpAIE9w
dGlvbmFsLiBSZXNvdXJjZSBsYWJlbHMgdG8gcmVwcmVzZW50IHVzZXItcHJvdmlkZWQgbWV0
YWRhdGEuCgoNCgUEAAIOBhIEygECFQoNCgUEAAIOARIEygEWHAoNCgUEAAIOAxIEygEfIQoN
CgUEAAIOCBIEygEiSgoQCggEAAIOCJwIABIEygEjSQo/CgQEAAIPEgbNAQLOATIaLyBPdXRw
dXQgb25seS4gVGhlIHRpbWUgdGhlIGNvbmZpZyB3YXMgY3JlYXRlZC4KCg0KBQQAAg8GEgTN
AQIbCg0KBQQAAg8BEgTNARwnCg0KBQQAAg8DEgTNASorCg0KBQQAAg8IEgTOAQYxChAKCAQA
Ag8InAgAEgTOAQcwCj8KBAQAAhASBtEBAtIBMhovIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0
aGUgY29uZmlnIHdhcyB1cGRhdGVkLgoKDQoFBAACEAYSBNEBAhsKDQoFBAACEAESBNEBHCcK
DQoFBAACEAMSBNEBKiwKDQoFBAACEAgSBNIBBjEKEAoIBAACEAicCAASBNIBBzAKYgoCBAES
BtcBALgCARpUIEEgY29uZmlndXJhdGlvbiB0byBnZW5lcmF0ZSBhIHJlc3BvbnNlIGZvciBH
ZXRFZmZlY3RpdmVWcGNGbG93TG9nc0NvbmZpZwogcmVxdWVzdC4KCgsKAwQBARIE1wEIIgo8
CgQEAQQAEgbZAQLvAQMaLCBUaGUgc2NvcGUgZm9yIHRoaXMgZmxvdyBsb2cgY29uZmlndXJh
dGlvbi4KCg0KBQQBBAABEgTZAQcMCicKBgQBBAACABIE2wEEGhoXIFNjb3BlIGlzIHVuc3Bl
Y2lmaWVkLgoKDwoHBAEEAAIAARIE2wEEFQoPCgcEAQQAAgACEgTbARgZCkcKBgQBBAACARIE
3gEEDxo3IFRhcmdldCByZXNvdXJjZSBpcyBhIHN1Ym5ldCAoTmV0d29yayBNYW5hZ2VtZW50
IEFQSSkuCgoPCgcEAQQAAgEBEgTeAQQKCg8KBwQBBAACAQISBN4BDQ4KXwoGBAEEAAICEgTi
AQQbGk8gVGFyZ2V0IHJlc291cmNlIGlzIGEgc3VibmV0LCBhbmQgdGhlIGNvbmZpZyBvcmln
aW5hdGVzIGZyb20gdGhlIENvbXB1dGUKIEFQSS4KCg8KBwQBBAACAgESBOIBBBYKDwoHBAEE
AAICAhIE4gEZGgovCgYEAQQAAgMSBOUBBBAaHyBUYXJnZXQgcmVzb3VyY2UgaXMgYSBuZXR3
b3JrLgoKDwoHBAEEAAIDARIE5QEECwoPCgcEAQQAAgMCEgTlAQ4PCjIKBgQBBAACBBIE6AEE
ExoiIFRhcmdldCByZXNvdXJjZSBpcyBhIFZQTiB0dW5uZWwuCgoPCgcEAQQAAgQBEgToAQQO
Cg8KBwQBBAACBAISBOgBERIKQAoGBAEEAAIFEgTrAQQgGjAgVGFyZ2V0IHJlc291cmNlIGlz
IGFuIGludGVyY29ubmVjdCBhdHRhY2htZW50LgoKDwoHBAEEAAIFARIE6wEEGwoPCgcEAQQA
AgUCEgTrAR4fCkIKBgQBBAACBhIE7gEEFRoyIENvbmZpZ3VyYXRpb24gYXBwbGllcyB0byBh
biBlbnRpcmUgb3JnYW5pemF0aW9uLgoKDwoHBAEEAAIGARIE7gEEEAoPCgcEAQQAAgYCEgTu
ARMUCu8DCgQEAQIAEgT8AQISGuADIFVuaXF1ZSBuYW1lIG9mIHRoZSBjb25maWd1cmF0aW9u
LiBUaGUgbmFtZSBjYW4gaGF2ZSBvbmUgb2YgdGhlIGZvbGxvd2luZwogZm9ybXM6CgogLSBG
b3IgcHJvamVjdC1sZXZlbCBjb25maWd1cmF0aW9uczoKIGBwcm9qZWN0cy97cHJvamVjdF9p
ZH0vbG9jYXRpb25zL2dsb2JhbC92cGNGbG93TG9nc0NvbmZpZ3Mve3ZwY19mbG93X2xvZ3Nf
Y29uZmlnX2lkfWAKCiAtIEZvciBvcmdhbml6YXRpb24tbGV2ZWwgY29uZmlndXJhdGlvbnM6
CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMvZ2xvYmFsL3Zw
Y0Zsb3dMb2dzQ29uZmlncy97dnBjX2Zsb3dfbG9nc19jb25maWdfaWR9YAoKIC0gRm9yIGEg
Q29tcHV0ZSBjb25maWcsIHRoZSBuYW1lIHdpbGwgYmUgdGhlIHBhdGggb2YgdGhlIHN1Ym5l
dDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vcmVnaW9ucy97cmVnaW9ufS9zdWJuZXR3b3Jr
cy97c3VibmV0X2lkfWAKCg0KBQQBAgAFEgT8AQIICg0KBQQBAgABEgT8AQkNCg0KBQQBAgAD
EgT8ARARCtYBCgQEAQIBEgSBAgItGscBIFRoZSBzdGF0ZSBvZiB0aGUgVlBDIEZsb3cgTG9n
IGNvbmZpZ3VyYXRpb24uIERlZmF1bHQgdmFsdWUgaXMgRU5BQkxFRC4KIFdoZW4gY3JlYXRp
bmcgYSBuZXcgY29uZmlndXJhdGlvbiwgaXQgbXVzdCBiZSBlbmFibGVkLgogU2V0dGluZyBz
dGF0ZT1ESVNBQkxFRCB3aWxsIHBhdXNlIHRoZSBsb2cgZ2VuZXJhdGlvbiBmb3IgdGhpcyBj
b25maWcuCgoNCgUEAQIBBBIEgQICCgoNCgUEAQIBBhIEgQILIgoNCgUEAQIBARIEgQIjKAoN
CgUEAQIBAxIEgQIrLApXCgQEAQICEgSEAgJKGkkgVGhlIGFnZ3JlZ2F0aW9uIGludGVydmFs
IGZvciB0aGUgbG9ncy4gRGVmYXVsdCB2YWx1ZSBpcyBJTlRFUlZBTF81X1NFQy4KCg0KBQQB
AgIEEgSEAgIKCg0KBQQBAgIGEgSEAgswCg0KBQQBAgIBEgSEAjFFCg0KBQQBAgIDEgSEAkhJ
CpwCCgQEAQIDEgSLAgIjGo0CIFRoZSB2YWx1ZSBvZiB0aGUgZmllbGQgbXVzdCBiZSBpbiAo
MCwgMV0uIFRoZSBzYW1wbGluZyByYXRlIG9mIFZQQyBGbG93CiBMb2dzIHdoZXJlIDEuMCBt
ZWFucyBhbGwgY29sbGVjdGVkIGxvZ3MgYXJlIHJlcG9ydGVkLgogU2V0dGluZyB0aGUgc2Ft
cGxpbmcgcmF0ZSB0byAwLjAgaXMgbm90IGFsbG93ZWQuIElmIHlvdSB3YW50IHRvIGRpc2Fi
bGUgVlBDCiBGbG93IExvZ3MsIHVzZSB0aGUgc3RhdGUgZmllbGQgaW5zdGVhZC4KIERlZmF1
bHQgdmFsdWUgaXMgMS4wLgoKDQoFBAECAwQSBIsCAgoKDQoFBAECAwUSBIsCCxAKDQoFBAEC
AwESBIsCER4KDQoFBAECAwMSBIsCISIKpAEKBAQBAgQSBJACAjMalQEgQ29uZmlndXJlcyB3
aGV0aGVyIGFsbCwgbm9uZSBvciBhIHN1YnNldCBvZiBtZXRhZGF0YSBmaWVsZHMgc2hvdWxk
IGJlCiBhZGRlZCB0byB0aGUgcmVwb3J0ZWQgVlBDIGZsb3cgbG9ncy4KIERlZmF1bHQgdmFs
dWUgaXMgSU5DTFVERV9BTExfTUVUQURBVEEuCgoNCgUEAQIEBBIEkAICCgoNCgUEAQIEBhIE
kAILJQoNCgUEAQIEARIEkAImLgoNCgUEAQIEAxIEkAIxMgqSAQoEBAECBRIElAICJhqDASBD
dXN0b20gbWV0YWRhdGEgZmllbGRzIHRvIGluY2x1ZGUgaW4gdGhlIHJlcG9ydGVkIFZQQyBm
bG93IGxvZ3MuCiBDYW4gb25seSBiZSBzcGVjaWZpZWQgaWYgIm1ldGFkYXRhIiB3YXMgc2V0
IHRvIENVU1RPTV9NRVRBREFUQS4KCg0KBQQBAgUEEgSUAgIKCg0KBQQBAgUFEgSUAgsRCg0K
BQQBAgUBEgSUAhIhCg0KBQQBAgUDEgSUAiQlClIKBAQBAgYSBJcCAiIaRCBFeHBvcnQgZmls
dGVyIHVzZWQgdG8gZGVmaW5lIHdoaWNoIFZQQyBGbG93IExvZ3Mgc2hvdWxkIGJlIGxvZ2dl
ZC4KCg0KBQQBAgYEEgSXAgIKCg0KBQQBAgYFEgSXAgsRCg0KBQQBAgYBEgSXAhIdCg0KBQQB
AgYDEgSXAiAhCuQBCgQEAQIHEgScAgJOGtUBIERldGVybWluZXMgd2hldGhlciB0byBpbmNs
dWRlIGNyb3NzIHByb2plY3QgYW5ub3RhdGlvbnMgaW4gdGhlIGxvZ3MuCiBUaGlzIGZpZWxk
IGlzIGF2YWlsYWJsZSBvbmx5IGZvciBvcmdhbml6YXRpb24gY29uZmlndXJhdGlvbnMuIElm
IG5vdAogc3BlY2lmaWVkIGluIG9yZyBjb25maWdzIHdpbGwgYmUgc2V0IHRvIENST1NTX1BS
T0pFQ1RfTUVUQURBVEFfRU5BQkxFRC4KCg0KBQQBAgcEEgScAgIKCg0KBQQBAgcGEgScAgsx
Cg0KBQQBAgcBEgScAjJICg0KBQQBAgcDEgScAktNCoICCgQEAQgAEgaiAgK0AgMa8QEgUmVm
ZXJlbmNlIHRvIHRoZSByZXNvdXJjZSBvZiB0aGUgY29uZmlnIHNjb3BlLiBUaGF0IGlzLCB0
aGUgc2NvcGUgZnJvbQogd2hpY2ggdHJhZmZpYyBpcyBsb2dnZWQuIFRoZSB0YXJnZXQgcmVz
b3VyY2UgbXVzdCBiZWxvbmcgdG8gdGhlIHNhbWUKIHByb2plY3QgYXMgdGhlIGNvbmZpZ3Vy
YXRpb24uCiBUaGlzIGZpZWxkIGlzIG5vdCBzdXBwb3J0ZWQgZm9yIG9yZ2FuaXphdGlvbiBs
ZXZlbCBjb25maWd1cmF0aW9ucy4KCg0KBQQBCAABEgSiAggXCqUBCgQEAQIIEgSmAgQZGpYB
IFRyYWZmaWMgd2lsbCBiZSBsb2dnZWQgZnJvbSBWTXMsIFZQTiB0dW5uZWxzIGFuZCBJbnRl
cmNvbm5lY3QgQXR0YWNobWVudHMKIHdpdGhpbiB0aGUgbmV0d29yay4KIEZvcm1hdDogcHJv
amVjdHMve3Byb2plY3RfaWR9L2dsb2JhbC9uZXR3b3Jrcy97bmFtZX0KCg0KBQQBAggFEgSm
AgQKCg0KBQQBAggBEgSmAgsSCg0KBQQBAggDEgSmAhUYCokBCgQEAQIJEgSqAgQYGnsgVHJh
ZmZpYyB3aWxsIGJlIGxvZ2dlZCBmcm9tIFZNcyB3aXRoaW4gdGhlIHN1Ym5ldHdvcmsuCiBG
b3JtYXQ6IHByb2plY3RzL3twcm9qZWN0X2lkfS9yZWdpb25zL3tyZWdpb259L3N1Ym5ldHdv
cmtzL3tuYW1lfQoKDQoFBAECCQUSBKoCBAoKDQoFBAECCQESBKoCCxEKDQoFBAECCQMSBKoC
FBcKmQEKBAQBAgoSBK8CBCkaigEgVHJhZmZpYyB3aWxsIGJlIGxvZ2dlZCBmcm9tIHRoZSBJ
bnRlcmNvbm5lY3QgQXR0YWNobWVudC4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0X2lk
fS9yZWdpb25zL3tyZWdpb259L2ludGVyY29ubmVjdEF0dGFjaG1lbnRzL3tuYW1lfQoKDQoF
BAECCgUSBK8CBAoKDQoFBAECCgESBK8CCyIKDQoFBAECCgMSBK8CJSgKfQoEBAECCxIEswIE
HBpvIFRyYWZmaWMgd2lsbCBiZSBsb2dnZWQgZnJvbSB0aGUgVlBOIFR1bm5lbC4KIEZvcm1h
dDogcHJvamVjdHMve3Byb2plY3RfaWR9L3JlZ2lvbnMve3JlZ2lvbn0vdnBuVHVubmVscy97
bmFtZX0KCg0KBQQBAgsFEgSzAgQKCg0KBQQBAgsBEgSzAgsVCg0KBQQBAgsDEgSzAhgbCloK
BAQBAgwSBLcCAhwaTCBTcGVjaWZpZXMgdGhlIHNjb3BlIG9mIHRoZSBjb25maWcgKGUuZy4s
IFNVQk5FVCwgTkVUV09SSywgT1JHQU5JWkFUSU9OLi4pLgoKDQoFBAECDAQSBLcCAgoKDQoF
BAECDAYSBLcCCxAKDQoFBAECDAESBLcCERYKDQoFBAECDAMSBLcCGRtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig ===
    # Fields for VpcFlowLogsConfig
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.State)
    # Field: aggregation_interval Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.AggregationInterval)
    # Field: flow_sampling Type: 2 ()
    # Field: metadata Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.Metadata)
    # Field: metadata_fields Type: 9 ()
    # Field: filter_expr Type: 9 ()
    # Field: cross_project_metadata Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.CrossProjectMetadata)
    # Field: target_resource_state Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.TargetResourceState)
    # Field: network Type: 9 ()
    # Field: subnet Type: 9 ()
    # Field: interconnect_attachment Type: 9 ()
    # Field: vpn_tunnel Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: VpcFlowLogsConfig::State
our $VpcFlowLogsConfig_STATE_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_ENABLED = 1;
our $VpcFlowLogsConfig_DISABLED = 2;

# Enum: VpcFlowLogsConfig::AggregationInterval
our $VpcFlowLogsConfig_AGGREGATION_INTERVAL_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_INTERVAL_5_SEC = 1;
our $VpcFlowLogsConfig_INTERVAL_30_SEC = 2;
our $VpcFlowLogsConfig_INTERVAL_1_MIN = 3;
our $VpcFlowLogsConfig_INTERVAL_5_MIN = 4;
our $VpcFlowLogsConfig_INTERVAL_10_MIN = 5;
our $VpcFlowLogsConfig_INTERVAL_15_MIN = 6;

# Enum: VpcFlowLogsConfig::Metadata
our $VpcFlowLogsConfig_METADATA_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_INCLUDE_ALL_METADATA = 1;
our $VpcFlowLogsConfig_EXCLUDE_ALL_METADATA = 2;
our $VpcFlowLogsConfig_CUSTOM_METADATA = 3;

# Enum: VpcFlowLogsConfig::CrossProjectMetadata
our $VpcFlowLogsConfig_CROSS_PROJECT_METADATA_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_CROSS_PROJECT_METADATA_ENABLED = 1;
our $VpcFlowLogsConfig_CROSS_PROJECT_METADATA_DISABLED = 2;

# Enum: VpcFlowLogsConfig::TargetResourceState
our $VpcFlowLogsConfig_TARGET_RESOURCE_STATE_UNSPECIFIED = 0;
our $VpcFlowLogsConfig_TARGET_RESOURCE_EXISTS = 1;
our $VpcFlowLogsConfig_TARGET_RESOURCE_DOES_NOT_EXIST = 2;

# === Message: Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig ===
    # Fields for EffectiveVpcFlowLogsConfig
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.State)
    # Field: aggregation_interval Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.AggregationInterval)
    # Field: flow_sampling Type: 2 ()
    # Field: metadata Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.Metadata)
    # Field: metadata_fields Type: 9 ()
    # Field: filter_expr Type: 9 ()
    # Field: cross_project_metadata Type: 14 (.google.cloud.networkmanagement.v1beta1.VpcFlowLogsConfig.CrossProjectMetadata)
    # Field: network Type: 9 ()
    # Field: subnet Type: 9 ()
    # Field: interconnect_attachment Type: 9 ()
    # Field: vpn_tunnel Type: 9 ()
    # Field: scope Type: 14 (.google.cloud.networkmanagement.v1beta1.EffectiveVpcFlowLogsConfig.Scope)

# Enum: EffectiveVpcFlowLogsConfig::Scope
our $EffectiveVpcFlowLogsConfig_SCOPE_UNSPECIFIED = 0;
our $EffectiveVpcFlowLogsConfig_SUBNET = 1;
our $EffectiveVpcFlowLogsConfig_COMPUTE_API_SUBNET = 2;
our $EffectiveVpcFlowLogsConfig_NETWORK = 3;
our $EffectiveVpcFlowLogsConfig_VPN_TUNNEL = 4;
our $EffectiveVpcFlowLogsConfig_INTERCONNECT_ATTACHMENT = 5;
our $EffectiveVpcFlowLogsConfig_ORGANIZATION = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig - Compiled Protocol Buffers messages for google/cloud/networkmanagement/v1beta1/vpc_flow_logs_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig;

    my $msg = Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig->new({
        name => $name,
        description => $description,
        state => $state,
        aggregation_interval => $aggregation_interval,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkmanagement/v1beta1/vpc_flow_logs_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig

A configuration to generate VPC Flow Logs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Unique name of the configuration. The name can have one of the
following forms:

- For project-level configurations:
`projects/{project_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

- For organization-level configurations:
`organizations/{organization_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The user-supplied description of the VPC Flow Logs configuration.
Maximum of 512 characters.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::State>)

Optional. The state of the VPC Flow Log configuration. Default value is
ENABLED. When creating a new configuration, it must be enabled. Setting
state=DISABLED will pause the log generation for this config.

=item * C<< $msg->aggregation_interval() >> / C<< $msg->aggregation_interval($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::AggregationInterval>)

Optional. The aggregation interval for the logs. Default value is
INTERVAL_5_SEC.

=item * C<< $msg->flow_sampling() >> / C<< $msg->flow_sampling($value) >>

Type: C<Float>

Optional. The value of the field must be in (0, 1]. The sampling rate of
VPC Flow Logs where 1.0 means all collected logs are reported. Setting the
sampling rate to 0.0 is not allowed. If you want to disable VPC Flow Logs,
use the state field instead. Default value is 1.0.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::Metadata>)

Optional. Configures whether all, none or a subset of metadata fields
should be added to the reported VPC flow logs. Default value is
INCLUDE_ALL_METADATA.

=item * C<< $msg->metadata_fields() >> / C<< $msg->metadata_fields($value) >>

Type: C<String>

Optional. Custom metadata fields to include in the reported VPC flow logs.
Can only be specified if "metadata" was set to CUSTOM_METADATA.

=item * C<< $msg->filter_expr() >> / C<< $msg->filter_expr($value) >>

Type: C<String>

Optional. Export filter used to define which VPC Flow Logs should be
logged.

=item * C<< $msg->cross_project_metadata() >> / C<< $msg->cross_project_metadata($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::CrossProjectMetadata>)

Optional. Determines whether to include cross project annotations in the
logs. This field is available only for organization configurations. If not
specified in org configs will be set to CROSS_PROJECT_METADATA_ENABLED.

=item * C<< $msg->target_resource_state() >> / C<< $msg->target_resource_state($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::TargetResourceState>)

Output only. Describes the state of the configured target resource for
diagnostic purposes.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Traffic will be logged from VMs, VPN tunnels and Interconnect Attachments
within the network.
Format: projects/{project_id}/global/networks/{name}

=item * C<< $msg->subnet() >> / C<< $msg->subnet($value) >>

Type: C<String>

Traffic will be logged from VMs within the subnetwork.
Format: projects/{project_id}/regions/{region}/subnetworks/{name}

=item * C<< $msg->interconnect_attachment() >> / C<< $msg->interconnect_attachment($value) >>

Type: C<String>

Traffic will be logged from the Interconnect Attachment.
Format:
projects/{project_id}/regions/{region}/interconnectAttachments/{name}

=item * C<< $msg->vpn_tunnel() >> / C<< $msg->vpn_tunnel($value) >>

Type: C<String>

Traffic will be logged from the VPN Tunnel.
Format: projects/{project_id}/regions/{region}/vpnTunnels/{name}

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::VpcFlowLogsConfig::LabelsEntry>)

Optional. Resource labels to represent user-provided metadata.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the config was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the config was updated.

=back

=head3 Enum: VpcFlowLogsConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=back

=head3 Enum: VpcFlowLogsConfig::AggregationInterval

=over 4

=item * C<AGGREGATION_INTERVAL_UNSPECIFIED> => C<0>

=item * C<INTERVAL_5_SEC> => C<1>

=item * C<INTERVAL_30_SEC> => C<2>

=item * C<INTERVAL_1_MIN> => C<3>

=item * C<INTERVAL_5_MIN> => C<4>

=item * C<INTERVAL_10_MIN> => C<5>

=item * C<INTERVAL_15_MIN> => C<6>

=back

=head3 Enum: VpcFlowLogsConfig::Metadata

=over 4

=item * C<METADATA_UNSPECIFIED> => C<0>

=item * C<INCLUDE_ALL_METADATA> => C<1>

=item * C<EXCLUDE_ALL_METADATA> => C<2>

=item * C<CUSTOM_METADATA> => C<3>

=back

=head3 Enum: VpcFlowLogsConfig::CrossProjectMetadata

=over 4

=item * C<CROSS_PROJECT_METADATA_UNSPECIFIED> => C<0>

=item * C<CROSS_PROJECT_METADATA_ENABLED> => C<1>

=item * C<CROSS_PROJECT_METADATA_DISABLED> => C<2>

=back

=head3 Enum: VpcFlowLogsConfig::TargetResourceState

=over 4

=item * C<TARGET_RESOURCE_STATE_UNSPECIFIED> => C<0>

=item * C<TARGET_RESOURCE_EXISTS> => C<1>

=item * C<TARGET_RESOURCE_DOES_NOT_EXIST> => C<2>

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig

A configuration to generate a response for GetEffectiveVpcFlowLogsConfig
request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Unique name of the configuration. The name can have one of the following
forms:

- For project-level configurations:
`projects/{project_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

- For organization-level configurations:
`organizations/{organization_id}/locations/global/vpcFlowLogsConfigs/{vpc_flow_logs_config_id}`

- For a Compute config, the name will be the path of the subnet:
`projects/{project_id}/regions/{region}/subnetworks/{subnet_id}`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::State>)

The state of the VPC Flow Log configuration. Default value is ENABLED.
When creating a new configuration, it must be enabled.
Setting state=DISABLED will pause the log generation for this config.

=item * C<< $msg->aggregation_interval() >> / C<< $msg->aggregation_interval($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::AggregationInterval>)

The aggregation interval for the logs. Default value is INTERVAL_5_SEC.

=item * C<< $msg->flow_sampling() >> / C<< $msg->flow_sampling($value) >>

Type: C<Float>

The value of the field must be in (0, 1]. The sampling rate of VPC Flow
Logs where 1.0 means all collected logs are reported.
Setting the sampling rate to 0.0 is not allowed. If you want to disable VPC
Flow Logs, use the state field instead.
Default value is 1.0.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::Metadata>)

Configures whether all, none or a subset of metadata fields should be
added to the reported VPC flow logs.
Default value is INCLUDE_ALL_METADATA.

=item * C<< $msg->metadata_fields() >> / C<< $msg->metadata_fields($value) >>

Type: C<String>

Custom metadata fields to include in the reported VPC flow logs.
Can only be specified if "metadata" was set to CUSTOM_METADATA.

=item * C<< $msg->filter_expr() >> / C<< $msg->filter_expr($value) >>

Type: C<String>

Export filter used to define which VPC Flow Logs should be logged.

=item * C<< $msg->cross_project_metadata() >> / C<< $msg->cross_project_metadata($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::CrossProjectMetadata>)

Determines whether to include cross project annotations in the logs.
This field is available only for organization configurations. If not
specified in org configs will be set to CROSS_PROJECT_METADATA_ENABLED.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Traffic will be logged from VMs, VPN tunnels and Interconnect Attachments
within the network.
Format: projects/{project_id}/global/networks/{name}

=item * C<< $msg->subnet() >> / C<< $msg->subnet($value) >>

Type: C<String>

Traffic will be logged from VMs within the subnetwork.
Format: projects/{project_id}/regions/{region}/subnetworks/{name}

=item * C<< $msg->interconnect_attachment() >> / C<< $msg->interconnect_attachment($value) >>

Type: C<String>

Traffic will be logged from the Interconnect Attachment.
Format:
projects/{project_id}/regions/{region}/interconnectAttachments/{name}

=item * C<< $msg->vpn_tunnel() >> / C<< $msg->vpn_tunnel($value) >>

Type: C<String>

Traffic will be logged from the VPN Tunnel.
Format: projects/{project_id}/regions/{region}/vpnTunnels/{name}

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<Enum> (L<Google::Cloud::Networkmanagement::V1beta1::EffectiveVpcFlowLogsConfig::Scope>)

Specifies the scope of the config (e.g., SUBNET, NETWORK, ORGANIZATION..).

=back

=head3 Enum: EffectiveVpcFlowLogsConfig::Scope

=over 4

=item * C<SCOPE_UNSPECIFIED> => C<0>

=item * C<SUBNET> => C<1>

=item * C<COMPUTE_API_SUBNET> => C<2>

=item * C<NETWORK> => C<3>

=item * C<VPN_TUNNEL> => C<4>

=item * C<INTERCONNECT_ATTACHMENT> => C<5>

=item * C<ORGANIZATION> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
