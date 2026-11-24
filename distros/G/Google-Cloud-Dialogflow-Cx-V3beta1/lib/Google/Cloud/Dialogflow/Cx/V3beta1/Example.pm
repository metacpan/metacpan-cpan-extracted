package Google::Cloud::Dialogflow::Cx::V3beta1::Example;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::Trace };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2V4YW1wbGUucHJvdG8SImdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvY2xvdWQv
ZGlhbG9nZmxvdy9jeC92M2JldGExL3RyYWNlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIqUBChRDcmVhdGVFeGFtcGxlUmVxdWVzdBJBCgZwYXJl
bnQYASABKAlCKeBBAvpBIxIhZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9FeGFtcGxlUgZw
YXJlbnQSSgoHZXhhbXBsZRgCIAEoCzIrLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
YmV0YTEuRXhhbXBsZUID4EECUgdleGFtcGxlIlUKFERlbGV0ZUV4YW1wbGVSZXF1ZXN0Ej0K
BG5hbWUYASABKAlCKeBBAvpBIwohZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9FeGFtcGxl
UgRuYW1lIsgBChNMaXN0RXhhbXBsZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEj
EiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0V4YW1wbGVSBnBhcmVudBIgCglwYWdlX3Np
emUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdl
VG9rZW4SKAoNbGFuZ3VhZ2VfY29kZRgEIAEoCUID4EEBUgxsYW5ndWFnZUNvZGUihwEKFExp
c3RFeGFtcGxlc1Jlc3BvbnNlEkcKCGV4YW1wbGVzGAEgAygLMisuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5FeGFtcGxlUghleGFtcGxlcxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iUgoRR2V0RXhhbXBsZVJlcXVlc3QSPQoEbmFtZRgB
IAEoCUIp4EEC+kEjCiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0V4YW1wbGVSBG5hbWUi
pAEKFFVwZGF0ZUV4YW1wbGVSZXF1ZXN0EkoKB2V4YW1wbGUYASABKAsyKy5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkV4YW1wbGVCA+BBAlIHZXhhbXBsZRJACgt1cGRh
dGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRl
TWFzayLOBgoHRXhhbXBsZRISCgRuYW1lGAEgASgJUgRuYW1lEl0KDnBsYXlib29rX2lucHV0
GAMgASgLMjEuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5QbGF5Ym9va0lu
cHV0QgPgQQFSDXBsYXlib29rSW5wdXQSYAoPcGxheWJvb2tfb3V0cHV0GAQgASgLMjIuZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5QbGF5Ym9va091dHB1dEID4EEBUg5w
bGF5Ym9va091dHB1dBJJCgdhY3Rpb25zGAIgAygLMiouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjNiZXRhMS5BY3Rpb25CA+BBAlIHYWN0aW9ucxImCgxkaXNwbGF5X25hbWUYBiAB
KAlCA+BBAlILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YCCABKAlCA+BBAVILZGVzY3Jp
cHRpb24SJAoLdG9rZW5fY291bnQYCSABKANCA+BBA1IKdG9rZW5Db3VudBJACgtjcmVhdGVf
dGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGlt
ZRJACgt1cGRhdGVfdGltZRgLIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKdXBkYXRlVGltZRJjChJjb252ZXJzYXRpb25fc3RhdGUYDCABKA4yLy5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52M2JldGExLk91dHB1dFN0YXRlQgPgQQJSEWNvbnZlcnNhdGlv
blN0YXRlEigKDWxhbmd1YWdlX2NvZGUYDSABKAlCA+BBAVIMbGFuZ3VhZ2VDb2RlOpoB6kGW
AQohZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9FeGFtcGxlEl5wcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH0vcGxheWJvb2tzL3twbGF5
Ym9va30vZXhhbXBsZXMve2V4YW1wbGV9KghleGFtcGxlczIHZXhhbXBsZTK5CQoIRXhhbXBs
ZXMS4AEKDUNyZWF0ZUV4YW1wbGUSOC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2Jl
dGExLkNyZWF0ZUV4YW1wbGVSZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djNiZXRhMS5FeGFtcGxlImiC0+STAlEiRi92M2JldGExL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9hZ2VudHMvKi9wbGF5Ym9va3MvKn0vZXhhbXBsZXM6B2V4YW1wbGXaQQ5w
YXJlbnQsZXhhbXBsZRK4AQoNRGVsZXRlRXhhbXBsZRI4Lmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzYmV0YTEuRGVsZXRlRXhhbXBsZVJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYu
RW1wdHkiVYLT5JMCSCpGL3YzYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9h
Z2VudHMvKi9wbGF5Ym9va3MvKi9leGFtcGxlcy8qfdpBBG5hbWUS2gEKDExpc3RFeGFtcGxl
cxI3Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuTGlzdEV4YW1wbGVzUmVx
dWVzdBo4Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuTGlzdEV4YW1wbGVz
UmVzcG9uc2UiV4LT5JMCSBJGL3YzYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2FnZW50cy8qL3BsYXlib29rcy8qfS9leGFtcGxlc9pBBnBhcmVudBLHAQoKR2V0RXhh
bXBsZRI1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuR2V0RXhhbXBsZVJl
cXVlc3QaKy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkV4YW1wbGUiVYLT
5JMCSBJGL3YzYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9w
bGF5Ym9va3MvKi9leGFtcGxlcy8qfdpBBG5hbWUS7QEKDVVwZGF0ZUV4YW1wbGUSOC5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlVwZGF0ZUV4YW1wbGVSZXF1ZXN0Gisu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5FeGFtcGxlInWC0+STAlkyTi92
M2JldGExL3tleGFtcGxlLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9w
bGF5Ym9va3MvKi9leGFtcGxlcy8qfToHZXhhbXBsZdpBE2V4YW1wbGUsdXBkYXRlX21hc2sa
eMpBGWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb23SQVlodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvZGlhbG9nZmxvd0KaAQomY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0
YTFCDEV4YW1wbGVQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvY3gv
YXBpdjNiZXRhMS9jeHBiO2N4cGKiAgJERqoCIkdvb2dsZS5DbG91ZC5EaWFsb2dmbG93LkN4
LlYzQmV0YTFK4DoKBxIFDgDsAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACsKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
IwoJCgIDBBIDFgA4CgkKAgMFEgMXACUKCQoCAwYSAxgAKgoJCgIDBxIDGQApCggKAQgSAxsA
PwoJCgIIJRIDGwA/CggKAQgSAxwATQoJCgIICxIDHABNCggKAQgSAx0AIgoJCgIIChIDHQAi
CggKAQgSAx4ALQoJCgIICBIDHgAtCggKAQgSAx8APwoJCgIIARIDHwA/CggKAQgSAyAAIAoJ
CgIIJBIDIAAgCloKAgYAEgQjAFIBGk4gU2VydmljZSBmb3IgbWFuYWdpbmcgW0V4YW1wbGVz
XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkV4YW1wbGVdLgoKCgoDBgAB
EgMjCBAKCgoDBgADEgMkAkEKDAoFBgADmQgSAyQCQQoLCgMGAAMSBCUCJzMKDQoFBgADmggS
BCUCJzMKPQoEBgACABIEKgIwAxovIENyZWF0ZXMgYW4gZXhhbXBsZSBpbiB0aGUgc3BlY2lm
aWVkIHBsYXlib29rLgoKDAoFBgACAAESAyoGEwoMCgUGAAIAAhIDKhQoCgwKBQYAAgADEgMq
MzoKDQoFBgACAAQSBCsELgYKEQoJBgACAASwyrwiEgQrBC4GCgwKBQYAAgAEEgMvBDwKDwoI
BgACAASbCAASAy8EPAouCgQGAAIBEgQzAjgDGiAgRGVsZXRlcyB0aGUgc3BlY2lmaWVkIGV4
YW1wbGUuCgoMCgUGAAIBARIDMwYTCgwKBQYAAgECEgMzFCgKDAoFBgACAQMSAzMzSAoNCgUG
AAIBBBIENAQ2BgoRCgkGAAIBBLDKvCISBDQENgYKDAoFBgACAQQSAzcEMgoPCggGAAIBBJsI
ABIDNwQyCkUKBAYAAgISBDsCQAMaNyBSZXR1cm5zIGEgbGlzdCBvZiBleGFtcGxlcyBpbiB0
aGUgc3BlY2lmaWVkIHBsYXlib29rLgoKDAoFBgACAgESAzsGEgoMCgUGAAICAhIDOxMmCgwK
BQYAAgIDEgM7MUUKDQoFBgACAgQSBDwEPgYKEQoJBgACAgSwyrwiEgQ8BD4GCgwKBQYAAgIE
EgM/BDQKDwoIBgACAgSbCAASAz8ENAowCgQGAAIDEgRDAkgDGiIgUmV0cmlldmVzIHRoZSBz
cGVjaWZpZWQgZXhhbXBsZS4KCgwKBQYAAgMBEgNDBhAKDAoFBgACAwISA0MRIgoMCgUGAAID
AxIDQy00Cg0KBQYAAgMEEgREBEYGChEKCQYAAgMEsMq8IhIERARGBgoMCgUGAAIDBBIDRwQy
Cg8KCAYAAgMEmwgAEgNHBDIKLQoEBgACBBIESwJRAxofIFVwZGF0ZSB0aGUgc3BlY2lmaWVk
IGV4YW1wbGUuCgoMCgUGAAIEARIDSwYTCgwKBQYAAgQCEgNLFCgKDAoFBgACBAMSA0szOgoN
CgUGAAIEBBIETARPBgoRCgkGAAIEBLDKvCISBEwETwYKDAoFBgACBAQSA1AEQQoPCggGAAIE
BJsIABIDUARBCnsKAgQAEgRWAGMBGm8gVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtFeGFt
cGxlcy5DcmVhdGVFeGFtcGxlXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGEx
LkV4YW1wbGVzLkNyZWF0ZUV4YW1wbGVdLgoKCgoDBAABEgNWCBwKogEKBAQAAgASBFoCXwQa
kwEgUmVxdWlyZWQuIFRoZSBwbGF5Ym9vayB0byBjcmVhdGUgYW4gZXhhbXBsZSBmb3IuCiBG
b3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9h
Z2VudHMvPEFnZW50SUQ+L3BsYXlib29rcy88UGxheWJvb2tJRD5gLgoKDAoFBAACAAUSA1oC
CAoMCgUEAAIAARIDWgkPCgwKBQQAAgADEgNaEhMKDQoFBAACAAgSBFoUXwMKDwoIBAACAAic
CAASA1sEKgoPCgcEAAIACJ8IEgRcBF4FCi8KBAQAAgESA2ICPxoiIFJlcXVpcmVkLiBUaGUg
ZXhhbXBsZSB0byBjcmVhdGUuCgoMCgUEAAIBBhIDYgIJCgwKBQQAAgEBEgNiChEKDAoFBAAC
AQMSA2IUFQoMCgUEAAIBCBIDYhY+Cg8KCAQAAgEInAgAEgNiFz0KewoCBAESBGcAcQEabyBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0V4YW1wbGVzLkRlbGV0ZUV4YW1wbGVdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRXhhbXBsZXMuRGVsZXRlRXhhbXBsZV0u
CgoKCgMEAQESA2cIHAqzAQoEBAECABIEawJwBBqkASBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIGV4YW1wbGUgdG8gZGVsZXRlLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+
L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9wbGF5Ym9va3MvPFBs
YXlib29rSUQ+L2V4YW1wbGVzLzxFeGFtcGxlSUQ+YC4KCgwKBQQBAgAFEgNrAggKDAoFBAEC
AAESA2sJDQoMCgUEAQIAAxIDaxARCg0KBQQBAgAIEgRrEnADCg8KCAQBAgAInAgAEgNsBCoK
DwoHBAECAAifCBIEbQRvBQp6CgIEAhIFdQCMAQEabSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZv
cgogW0V4YW1wbGVzLkxpc3RFeGFtcGxlc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djNiZXRhMS5FeGFtcGxlcy5MaXN0RXhhbXBsZXNdLgoKCgoDBAIBEgN1CBsKowEKBAQCAgAS
BHkCfgQalAEgUmVxdWlyZWQuIFRoZSBwbGF5Ym9vayB0byBsaXN0IHRoZSBleGFtcGxlcyBm
cm9tLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRp
b25JRD4vYWdlbnRzLzxBZ2VudElEPi9wbGF5Ym9va3MvPFBsYXlib29rSUQ+YC4KCgwKBQQC
AgAFEgN5AggKDAoFBAICAAESA3kJDwoMCgUEAgIAAxIDeRITCg0KBQQCAgAIEgR5FH4DCg8K
CAQCAgAInAgAEgN6BCoKDwoHBAICAAifCBIEewR9BQpzCgQEAgIBEgSCAQI/GmUgT3B0aW9u
YWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4gaW4gYSBzaW5nbGUg
cGFnZS4gQnkKIGRlZmF1bHQgMTAwIGFuZCBhdCBtb3N0IDEwMDAuCgoNCgUEAgIBBRIEggEC
BwoNCgUEAgIBARIEggEIEQoNCgUEAgIBAxIEggEUFQoNCgUEAgIBCBIEggEWPgoQCggEAgIB
CJwIABIEggEXPQqCAQoEBAICAhIEhgECQRp0IE9wdGlvbmFsLiBUaGUgW25leHRfcGFnZV90
b2tlbl1bTGlzdEV4YW1wbGVSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dIHZhbHVlCiByZXR1
cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAICAgUSBIYBAggKDQoF
BAICAgESBIYBCRMKDQoFBAICAgMSBIYBFhcKDQoFBAICAggSBIYBGEAKEAoIBAICAgicCAAS
BIYBGT8KvQEKBAQCAgMSBIsBAkQargEgT3B0aW9uYWwuIFRoZSBsYW5ndWFnZSB0byBsaXN0
IGV4YW1wbGVzIGZvci4KIElmIG5vdCBzcGVjaWZpZWQsIGxpc3QgYWxsIGV4YW1wbGVzIHVu
ZGVyIHRoZSBwbGF5Ym9vay4KIE5vdGU6IGxhbmd1YWdlcyBtdXN0IGJlIGVuYWJsZWQgaW4g
dGhlIGFnZW50IGJlZm9yZSB0aGV5IGNhbiBiZSB1c2VkLgoKDQoFBAICAwUSBIsBAggKDQoF
BAICAwESBIsBCRYKDQoFBAICAwMSBIsBGRoKDQoFBAICAwgSBIsBG0MKEAoIBAICAwicCAAS
BIsBHEIKfAoCBAMSBpABAJoBARpuIFRoZSByZXNwb25zZSBtZXNzYWdlIGZvcgogW0V4YW1w
bGVzLkxpc3RFeGFtcGxlc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5F
eGFtcGxlcy5MaXN0RXhhbXBsZXNdLgoKCwoDBAMBEgSQAQgcCssBCgQEAwIAEgSVAQIgGrwB
IFRoZSBsaXN0IG9mIGV4YW1wbGVzLiBUaGVyZSB3aWxsIGJlIGEgbWF4aW11bSBudW1iZXIg
b2YgaXRlbXMgcmV0dXJuZWQKIGJhc2VkIG9uIHRoZQogW3BhZ2Vfc2l6ZV1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5MaXN0RXhhbXBsZXNSZXF1ZXN0LnBhZ2Vfc2l6
ZV0KIGZpZWxkIGluIHRoZSByZXF1ZXN0LgoKDQoFBAMCAAQSBJUBAgoKDQoFBAMCAAYSBJUB
CxIKDQoFBAMCAAESBJUBExsKDQoFBAMCAAMSBJUBHh8KbwoEBAMCARIEmQECHRphIFRva2Vu
IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhl
cmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAwIBBRIEmQECCAoN
CgUEAwIBARIEmQEJGAoNCgUEAwIBAxIEmQEbHAp3CgIEBBIGngEAqAEBGmkgVGhlIHJlcXVl
c3QgbWVzc2FnZSBmb3IKIFtFeGFtcGxlcy5HZXRFeGFtcGxlXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52M2JldGExLkV4YW1wbGVzLkdldEV4YW1wbGVdLgoKCwoDBAQBEgSeAQgZ
CqsBCgQEBAIAEgaiAQKnAQQamgEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBleGFtcGxl
LgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25J
RD4vYWdlbnRzLzxBZ2VudElEPi9wbGF5Ym9va3MvPFBsYXlib29rSUQ+L2V4YW1wbGVzLzxF
eGFtcGxlSUQ+YC4KCg0KBQQEAgAFEgSiAQIICg0KBQQEAgABEgSiAQkNCg0KBQQEAgADEgSi
ARARCg8KBQQEAgAIEgaiARKnAQMKEAoIBAQCAAicCAASBKMBBCoKEQoHBAQCAAifCBIGpAEE
pgEFCn0KAgQFEgasAQC0AQEabyBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0V4YW1wbGVz
LlVwZGF0ZUV4YW1wbGVdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRXhh
bXBsZXMuVXBkYXRlRXhhbXBsZV0uCgoLCgMEBQESBKwBCBwKMAoEBAUCABIErgECPxoiIFJl
cXVpcmVkLiBUaGUgZXhhbXBsZSB0byB1cGRhdGUuCgoNCgUEBQIABhIErgECCQoNCgUEBQIA
ARIErgEKEQoNCgUEBQIAAxIErgEUFQoNCgUEBQIACBIErgEWPgoQCggEBQIACJwIABIErgEX
PQqCAQoEBAUCARIGsgECswEvGnIgT3B0aW9uYWwuIFRoZSBtYXNrIHRvIGNvbnRyb2wgd2hp
Y2ggZmllbGRzIGdldCB1cGRhdGVkLiBJZiB0aGUgbWFzayBpcyBub3QKIHByZXNlbnQsIGFs
bCBmaWVsZHMgd2lsbCBiZSB1cGRhdGVkLgoKDQoFBAUCAQYSBLIBAhsKDQoFBAUCAQESBLIB
HCcKDQoFBAUCAQMSBLIBKisKDQoFBAUCAQgSBLMBBi4KEAoIBAUCAQicCAASBLMBBy0K8gEK
AgQGEga6AQDsAQEa4wEgRXhhbXBsZSByZXByZXNlbnRzIGEgc2FtcGxlIGV4ZWN1dGlvbiBv
ZiB0aGUgcGxheWJvb2sgaW4gdGhlIGNvbnZlcnNhdGlvbi4KCiBBbiBleGFtcGxlIGNvbnNp
c3RzIG9mIGEgbGlzdCBvZiBvcmRlcmVkIGFjdGlvbnMgcGVyZm9ybWVkIGJ5IGVuZCB1c2Vy
CiBvciBEaWFsb2dmbG93IGFnZW50IGFjY29yZGluZyB0aGUgcGxheWJvb2sgaW5zdHJ1Y3Rp
b25zIHRvIGZ1bGZpbGwgdGhlIHRhc2suCgoLCgMEBgESBLoBCA8KDQoDBAYHEga7AQLAAQQK
DwoFBAYHnQgSBrsBAsABBAq1AQoEBAYCABIExQECEhqmASBUaGUgdW5pcXVlIGlkZW50aWZp
ZXIgb2YgdGhlIHBsYXlib29rIGV4YW1wbGUuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2pl
Y3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L3BsYXlib29r
cy88UGxheWJvb2tJRD4vZXhhbXBsZXMvPEV4YW1wbGVJRD5gLgoKDQoFBAYCAAUSBMUBAggK
DQoFBAYCAAESBMUBCQ0KDQoFBAYCAAMSBMUBEBEKQwoEBAYCARIEyAECTBo1IE9wdGlvbmFs
LiBUaGUgaW5wdXQgdG8gdGhlIHBsYXlib29rIGluIHRoZSBleGFtcGxlLgoKDQoFBAYCAQYS
BMgBAg8KDQoFBAYCAQESBMgBEB4KDQoFBAYCAQMSBMgBISIKDQoFBAYCAQgSBMgBI0sKEAoI
BAYCAQicCAASBMgBJEoKRAoEBAYCAhIEywECTho2IE9wdGlvbmFsLiBUaGUgb3V0cHV0IG9m
IHRoZSBwbGF5Ym9vayBpbiB0aGUgZXhhbXBsZS4KCg0KBQQGAgIGEgTLAQIQCg0KBQQGAgIB
EgTLAREgCg0KBQQGAgIDEgTLASMkCg0KBQQGAgIIEgTLASVNChAKCAQGAgIInAgAEgTLASZM
CmoKBAQGAgMSBM8BAkcaXCBSZXF1aXJlZC4gVGhlIG9yZGVyZWQgbGlzdCBvZiBhY3Rpb25z
IHBlcmZvcm1lZCBieSB0aGUgZW5kIHVzZXIgYW5kIHRoZQogRGlhbG9nZmxvdyBhZ2VudC4K
Cg0KBQQGAgMEEgTPAQIKCg0KBQQGAgMGEgTPAQsRCg0KBQQGAgMBEgTPARIZCg0KBQQGAgMD
EgTPARwdCg0KBQQGAgMIEgTPAR5GChAKCAQGAgMInAgAEgTPAR9FCjoKBAQGAgQSBNIBAkMa
LCBSZXF1aXJlZC4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgZXhhbXBsZS4KCg0KBQQGAgQF
EgTSAQIICg0KBQQGAgQBEgTSAQkVCg0KBQQGAgQDEgTSARgZCg0KBQQGAgQIEgTSARpCChAK
CAQGAgQInAgAEgTSARtBCnIKBAQGAgUSBNYBAkIaZCBPcHRpb25hbC4gVGhlIGhpZ2ggbGV2
ZWwgY29uY2lzZSBkZXNjcmlwdGlvbiBvZiB0aGUgZXhhbXBsZS4gVGhlIG1heCBudW1iZXIK
IG9mIGNoYXJhY3RlcnMgaXMgMjAwLgoKDQoFBAYCBQUSBNYBAggKDQoFBAYCBQESBNYBCRQK
DQoFBAYCBQMSBNYBFxgKDQoFBAYCBQgSBNYBGUEKEAoIBAYCBQicCAASBNYBGkAKYwoEBAYC
BhIE2gECRBpVIE91dHB1dCBvbmx5LiBFc3RpbWF0ZWQgbnVtYmVyIG9mIHRva2VzIGN1cnJl
bnQgZXhhbXBsZSB0YWtlcyB3aGVuIHNlbnQgdG8KIHRoZSBMTE0uCgoNCgUEBgIGBRIE2gEC
BwoNCgUEBgIGARIE2gEIEwoNCgUEBgIGAxIE2gEWFwoNCgUEBgIGCBIE2gEYQwoQCggEBgIG
CJwIABIE2gEZQgpJCgQEBgIHEgbdAQLeATIaOSBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFt
cCBvZiBpbml0aWFsIGV4YW1wbGUgY3JlYXRpb24uCgoNCgUEBgIHBhIE3QECGwoNCgUEBgIH
ARIE3QEcJwoNCgUEBgIHAxIE3QEqLAoNCgUEBgIHCBIE3gEGMQoQCggEBgIHCJwIABIE3gEH
MApBCgQEBgIIEgbhAQLiATIaMSBPdXRwdXQgb25seS4gTGFzdCB0aW1lIHRoZSBleGFtcGxl
IHdhcyB1cGRhdGVkLgoKDQoFBAYCCAYSBOEBAhsKDQoFBAYCCAESBOEBHCcKDQoFBAYCCAMS
BOEBKiwKDQoFBAYCCAgSBOIBBjEKEAoIBAYCCAicCAASBOIBBzAKMQoEBAYCCRIE5QECTxoj
IFJlcXVpcmVkLiBFeGFtcGxlJ3Mgb3V0cHV0IHN0YXRlLgoKDQoFBAYCCQYSBOUBAg0KDQoF
BAYCCQESBOUBDiAKDQoFBAYCCQMSBOUBIyUKDQoFBAYCCQgSBOUBJk4KEAoIBAYCCQicCAAS
BOUBJ00KhwIKBAQGAgoSBOsBAkUa+AEgT3B0aW9uYWwuIFRoZSBsYW5ndWFnZSBjb2RlIG9m
IHRoZSBleGFtcGxlLgogSWYgbm90IHNwZWNpZmllZCwgdGhlIGFnZW50J3MgZGVmYXVsdCBs
YW5ndWFnZSBpcyB1c2VkLgogTm90ZTogbGFuZ3VhZ2VzIG11c3QgYmUgZW5hYmxlZCBpbiB0
aGUgYWdlbnQgYmVmb3JlIHRoZXkgY2FuIGJlIHVzZWQuCiBOb3RlOiBleGFtcGxlJ3MgbGFu
Z3VhZ2UgY29kZSBpcyBub3QgY3VycmVudGx5IHVzZWQgaW4gZGlhbG9nZmxvdyBhZ2VudHMu
CgoNCgUEBgIKBRIE6wECCAoNCgUEBgIKARIE6wEJFgoNCgUEBgIKAxIE6wEZGwoNCgUEBgIK
CBIE6wEcRAoQCggEBgIKCJwIABIE6wEdQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest ===
    # Fields for CreateExampleRequest
    # Field: parent Type: 9 ()
    # Field: example Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Example)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Example::DeleteExampleRequest ===
    # Fields for DeleteExampleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesRequest ===
    # Fields for ListExamplesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesResponse ===
    # Fields for ListExamplesResponse
    # Field: examples Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Example)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Example::GetExampleRequest ===
    # Fields for GetExampleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Example::UpdateExampleRequest ===
    # Fields for UpdateExampleRequest
    # Field: example Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Example)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example ===
    # Fields for Example
    # Field: name Type: 9 ()
    # Field: playbook_input Type: 11 (.google.cloud.dialogflow.cx.v3beta1.PlaybookInput)
    # Field: playbook_output Type: 11 (.google.cloud.dialogflow.cx.v3beta1.PlaybookOutput)
    # Field: actions Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Action)
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: token_count Type: 3 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: conversation_state Type: 14 (.google.cloud.dialogflow.cx.v3beta1.OutputState)
    # Field: language_code Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Example::ExamplesClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::Example::ExamplesClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Example::ExamplesClient

Client stub representing the remote C<Examples> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub create_example {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Examples',
        method         => 'CreateExample',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example',
    });
}

sub delete_example {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Example::DeleteExampleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Examples',
        method         => 'DeleteExample',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_examples {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Examples',
        method         => 'ListExamples',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesResponse',
    });
}

sub get_example {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Example::GetExampleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Examples',
        method         => 'GetExample',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example',
    });
}

sub update_example {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Example::UpdateExampleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Examples',
        method         => 'UpdateExample',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Example - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/example.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::Example;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest->new({
        parent => $parent,
        example => $example,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/example.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest

The request message for
[Examples.CreateExample][google.cloud.dialogflow.cx.v3beta1.Examples.CreateExample].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The playbook to create an example for.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>`.

=item * C<< $msg->example() >> / C<< $msg->example($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example>)

Required. The example to create.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Example::DeleteExampleRequest

The request message for
[Examples.DeleteExample][google.cloud.dialogflow.cx.v3beta1.Examples.DeleteExample].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the example to delete.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>/examples/<ExampleID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesRequest

The request message for
[Examples.ListExamples][google.cloud.dialogflow.cx.v3beta1.Examples.ListExamples].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The playbook to list the examples from.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The [next_page_token][ListExampleResponse.next_page_token] value
returned from a previous list request.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Optional. The language to list examples for.
If not specified, list all examples under the playbook.
Note: languages must be enabled in the agent before they can be used.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesResponse

The response message for
[Examples.ListExamples][google.cloud.dialogflow.cx.v3beta1.Examples.ListExamples].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example>)

The list of examples. There will be a maximum number of items returned
based on the
[page_size][google.cloud.dialogflow.cx.v3beta1.ListExamplesRequest.page_size]
field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Example::GetExampleRequest

The request message for
[Examples.GetExample][google.cloud.dialogflow.cx.v3beta1.Examples.GetExample].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the example.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>/examples/<ExampleID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Example::UpdateExampleRequest

The request message for
[Examples.UpdateExample][google.cloud.dialogflow.cx.v3beta1.Examples.UpdateExample].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->example() >> / C<< $msg->example($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example>)

Required. The example to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated. If the mask is not
present, all fields will be updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example

Example represents a sample execution of the playbook in the conversation.

An example consists of a list of ordered actions performed by end user
or Dialogflow agent according the playbook instructions to fulfill the task.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the playbook example.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>/examples/<ExampleID>`.

=item * C<< $msg->playbook_input() >> / C<< $msg->playbook_input($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookInput>)

Optional. The input to the playbook in the example.

=item * C<< $msg->playbook_output() >> / C<< $msg->playbook_output($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookOutput>)

Optional. The output of the playbook in the example.

=item * C<< $msg->actions() >> / C<< $msg->actions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action>)

Required. The ordered list of actions performed by the end user and the
Dialogflow agent.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the example.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The high level concise description of the example. The max number
of characters is 200.

=item * C<< $msg->token_count() >> / C<< $msg->token_count($value) >>

Type: C<Int64>

Output only. Estimated number of tokes current example takes when sent to
the LLM.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of initial example creation.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Last time the example was updated.

=item * C<< $msg->conversation_state() >> / C<< $msg->conversation_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::OutputState>)

Required. Example's output state.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Optional. The language code of the example.
If not specified, the agent's default language is used.
Note: languages must be enabled in the agent before they can be used.
Note: example's language code is not currently used in dialogflow agents.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::Example::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
