package Google::Cloud::Dialogflow::Cx::V3beta1::Version;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3beta1::Flow };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3ZlcnNpb24ucHJvdG8SImdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQv
ZGlhbG9nZmxvdy9jeC92M2JldGExL2Zsb3cucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9v
cGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9w
cm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvImIKHkNyZWF0ZVZlcnNpb25PcGVy
YXRpb25NZXRhZGF0YRJACgd2ZXJzaW9uGAEgASgJQib6QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xl
YXBpcy5jb20vVmVyc2lvblIHdmVyc2lvbiKYBAoHVmVyc2lvbhISCgRuYW1lGAEgASgJUgRu
YW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRIgCgtkZXNjcmlw
dGlvbhgDIAEoCVILZGVzY3JpcHRpb24SVwoMbmx1X3NldHRpbmdzGAQgASgLMi8uZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5ObHVTZXR0aW5nc0ID4EEDUgtubHVTZXR0
aW5ncxJACgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZRJMCgVzdGF0ZRgGIAEoDjIxLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzYmV0YTEuVmVyc2lvbi5TdGF0ZUID4EEDUgVzdGF0ZSJGCgVTdGF0ZRIVChFT
VEFURV9VTlNQRUNJRklFRBAAEgsKB1JVTk5JTkcQARINCglTVUNDRUVERUQQAhIKCgZGQUlM
RUQQAzp+6kF7CiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb24SVnByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hZ2VudHMve2FnZW50fS9mbG93cy97
Zmxvd30vdmVyc2lvbnMve3ZlcnNpb259IpQBChNMaXN0VmVyc2lvbnNSZXF1ZXN0EkEKBnBh
cmVudBgBIAEoCUIp4EEC+kEjEiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb25S
BnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyAB
KAlSCXBhZ2VUb2tlbiKHAQoUTGlzdFZlcnNpb25zUmVzcG9uc2USRwoIdmVyc2lvbnMYASAD
KAsyKy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlZlcnNpb25SCHZlcnNp
b25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJSChFHZXRWZXJz
aW9uUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBp
cy5jb20vVmVyc2lvblIEbmFtZSKlAQoUQ3JlYXRlVmVyc2lvblJlcXVlc3QSQQoGcGFyZW50
GAEgASgJQingQQL6QSMSIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVmVyc2lvblIGcGFy
ZW50EkoKB3ZlcnNpb24YAiABKAsyKy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2Jl
dGExLlZlcnNpb25CA+BBAlIHdmVyc2lvbiKkAQoUVXBkYXRlVmVyc2lvblJlcXVlc3QSSgoH
dmVyc2lvbhgBIAEoCzIrLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVmVy
c2lvbkID4EECUgd2ZXJzaW9uEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrIlUKFERlbGV0ZVZlcnNpb25SZXF1ZXN0
Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9WZXJz
aW9uUgRuYW1lIpgBChJMb2FkVmVyc2lvblJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEj
CiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb25SBG5hbWUSQwoeYWxsb3dfb3Zl
cnJpZGVfYWdlbnRfcmVzb3VyY2VzGAIgASgIUhthbGxvd092ZXJyaWRlQWdlbnRSZXNvdXJj
ZXMi3QEKFkNvbXBhcmVWZXJzaW9uc1JlcXVlc3QSTAoMYmFzZV92ZXJzaW9uGAEgASgJQing
QQL6QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVmVyc2lvblILYmFzZVZlcnNpb24S
UAoOdGFyZ2V0X3ZlcnNpb24YAiABKAlCKeBBAvpBIwohZGlhbG9nZmxvdy5nb29nbGVhcGlz
LmNvbS9WZXJzaW9uUg10YXJnZXRWZXJzaW9uEiMKDWxhbmd1YWdlX2NvZGUYAyABKAlSDGxh
bmd1YWdlQ29kZSLSAQoXQ29tcGFyZVZlcnNpb25zUmVzcG9uc2USOQoZYmFzZV92ZXJzaW9u
X2NvbnRlbnRfanNvbhgBIAEoCVIWYmFzZVZlcnNpb25Db250ZW50SnNvbhI9Cht0YXJnZXRf
dmVyc2lvbl9jb250ZW50X2pzb24YAiABKAlSGHRhcmdldFZlcnNpb25Db250ZW50SnNvbhI9
Cgxjb21wYXJlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgtjb21w
YXJlVGltZTK8DQoIVmVyc2lvbnMS1gEKDExpc3RWZXJzaW9ucxI3Lmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzYmV0YTEuTGlzdFZlcnNpb25zUmVxdWVzdBo4Lmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuTGlzdFZlcnNpb25zUmVzcG9uc2UiU4LT5JMCRBJC
L3YzYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Zsb3dz
Lyp9L3ZlcnNpb25z2kEGcGFyZW50EsMBCgpHZXRWZXJzaW9uEjUuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5HZXRWZXJzaW9uUmVxdWVzdBorLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzYmV0YTEuVmVyc2lvbiJRgtPkkwJEEkIvdjNiZXRhMS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Zsb3dzLyovdmVyc2lvbnMvKn3aQQRu
YW1lEvsBCg1DcmVhdGVWZXJzaW9uEjguZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5DcmVhdGVWZXJzaW9uUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRp
b24ikAGC0+STAk0iQi92M2JldGExL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9h
Z2VudHMvKi9mbG93cy8qfS92ZXJzaW9uczoHdmVyc2lvbtpBDnBhcmVudCx2ZXJzaW9uykEp
CgdWZXJzaW9uEh5DcmVhdGVWZXJzaW9uT3BlcmF0aW9uTWV0YWRhdGES6QEKDVVwZGF0ZVZl
cnNpb24SOC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlVwZGF0ZVZlcnNp
b25SZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5WZXJzaW9u
InGC0+STAlUySi92M2JldGExL3t2ZXJzaW9uLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9hZ2VudHMvKi9mbG93cy8qL3ZlcnNpb25zLyp9Ogd2ZXJzaW9u2kETdmVyc2lvbix1cGRh
dGVfbWFzaxK0AQoNRGVsZXRlVmVyc2lvbhI4Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzYmV0YTEuRGVsZXRlVmVyc2lvblJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHki
UYLT5JMCRCpCL3YzYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMv
Ki9mbG93cy8qL3ZlcnNpb25zLyp92kEEbmFtZRLyAQoLTG9hZFZlcnNpb24SNi5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkxvYWRWZXJzaW9uUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24iiwGC0+STAkwiRy92M2JldGExL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZmxvd3MvKi92ZXJzaW9ucy8qfTpsb2FkOgEq
2kEEbmFtZcpBLwoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EhZnb29nbGUucHJvdG9idWYuU3Ry
dWN0EoACCg9Db21wYXJlVmVyc2lvbnMSOi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
M2JldGExLkNvbXBhcmVWZXJzaW9uc1JlcXVlc3QaOy5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52M2JldGExLkNvbXBhcmVWZXJzaW9uc1Jlc3BvbnNlInSC0+STAl8iWi92M2JldGEx
L3tiYXNlX3ZlcnNpb249cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9mbG93cy8q
L3ZlcnNpb25zLyp9OmNvbXBhcmVWZXJzaW9uczoBKtpBDGJhc2VfdmVyc2lvbhp4ykEZZGlh
bG9nZmxvdy5nb29nbGVhcGlzLmNvbdJBWWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaWFs
b2dmbG93QsMBCiZjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMUIMVmVy
c2lvblByb3RvUAFaNmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9jeC9hcGl2M2Jl
dGExL2N4cGI7Y3hwYqICAkRGqgIiR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuQ3guVjNCZXRh
MeoCJkdvb2dsZTo6Q2xvdWQ6OkRpYWxvZ2Zsb3c6OkNYOjpWM2JldGExSvhXCgcSBQ4A4QIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANwoJCgIDBRID
FwAtCgkKAgMGEgMYACUKCQoCAwcSAxkAKgoJCgIDCBIDGgAmCgkKAgMJEgMbACkKCAoBCBID
HQA/CgkKAgglEgMdAD8KCAoBCBIDHgBNCgkKAggLEgMeAE0KCAoBCBIDHwAiCgkKAggKEgMf
ACIKCAoBCBIDIAAtCgkKAggIEgMgAC0KCAoBCBIDIQA/CgkKAggBEgMhAD8KCAoBCBIDIgAg
CgkKAggkEgMiACAKCAoBCBIDIwA/CgkKAggtEgMjAD8KWwoCBgASBSYAhwEBGk4gU2Vydmlj
ZSBmb3IgbWFuYWdpbmcgW1ZlcnNpb25zXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
M2JldGExLlZlcnNpb25dLgoKCgoDBgABEgMmCBAKCgoDBgADEgMnAkEKDAoFBgADmQgSAycC
QQoLCgMGAAMSBCgCKjMKDQoFBgADmggSBCgCKjMKcwoEBgACABIELgIzAxplIFJldHVybnMg
dGhlIGxpc3Qgb2YgYWxsIHZlcnNpb25zIGluIHRoZSBzcGVjaWZpZWQKIFtGbG93XVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkZsb3ddLgoKDAoFBgACAAESAy4GEgoM
CgUGAAIAAhIDLhMmCgwKBQYAAgADEgMuMUUKDQoFBgACAAQSBC8EMQYKEQoJBgACAASwyrwi
EgQvBDEGCgwKBQYAAgAEEgMyBDQKDwoIBgACAASbCAASAzIENApfCgQGAAIBEgQ3AjwDGlEg
UmV0cmlldmVzIHRoZSBzcGVjaWZpZWQKIFtWZXJzaW9uXVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52M2JldGExLlZlcnNpb25dLgoKDAoFBgACAQESAzcGEAoMCgUGAAIBAhIDNxEi
CgwKBQYAAgEDEgM3LTQKDQoFBgACAQQSBDgEOgYKEQoJBgACAQSwyrwiEgQ4BDoGCgwKBQYA
AgEEEgM7BDIKDwoIBgACAQSbCAASAzsEMgqMBAoEBgACAhIESAJTAxr9AyBDcmVhdGVzIGEg
W1ZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVmVyc2lvbl0g
aW4gdGhlCiBzcGVjaWZpZWQgW0Zsb3ddW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
YmV0YTEuRmxvd10uCgogVGhpcyBtZXRob2QgaXMgYSBbbG9uZy1ydW5uaW5nCiBvcGVyYXRp
b25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2N4L2RvY3MvaG93L2xv
bmctcnVubmluZy1vcGVyYXRpb24pLgogVGhlIHJldHVybmVkIGBPcGVyYXRpb25gIHR5cGUg
aGFzIHRoZSBmb2xsb3dpbmcgbWV0aG9kLXNwZWNpZmljIGZpZWxkczoKCiAtIGBtZXRhZGF0
YWA6CiBbQ3JlYXRlVmVyc2lvbk9wZXJhdGlvbk1ldGFkYXRhXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52M2JldGExLkNyZWF0ZVZlcnNpb25PcGVyYXRpb25NZXRhZGF0YV0KIC0g
YHJlc3BvbnNlYDogW1ZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0
YTEuVmVyc2lvbl0KCgwKBQYAAgIBEgNIBhMKDAoFBgACAgISA0gUKAoMCgUGAAICAxIDSQ8r
Cg0KBQYAAgIEEgRKBE0GChEKCQYAAgIEsMq8IhIESgRNBgoMCgUGAAICBBIDTgQ8Cg8KCAYA
AgIEmwgAEgNOBDwKDQoFBgACAgQSBE8EUgYKDwoHBgACAgSZCBIETwRSBgpdCgQGAAIDEgRX
Al0DGk8gVXBkYXRlcyB0aGUgc3BlY2lmaWVkCiBbVmVyc2lvbl1bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5WZXJzaW9uXS4KCgwKBQYAAgMBEgNXBhMKDAoFBgACAwIS
A1cUKAoMCgUGAAIDAxIDVzM6Cg0KBQYAAgMEEgRYBFsGChEKCQYAAgMEsMq8IhIEWARbBgoM
CgUGAAIDBBIDXARBCg8KCAYAAgMEmwgAEgNcBEEKXQoEBgACBBIEYQJmAxpPIERlbGV0ZXMg
dGhlIHNwZWNpZmllZAogW1ZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
YmV0YTEuVmVyc2lvbl0uCgoMCgUGAAIEARIDYQYTCgwKBQYAAgQCEgNhFCgKDAoFBgACBAMS
A2EzSAoNCgUGAAIEBBIEYgRkBgoRCgkGAAIEBLDKvCISBGIEZAYKDAoFBgACBAQSA2UEMgoP
CggGAAIEBJsIABIDZQQyCogECgQGAAIFEgRyAnwDGvkDIExvYWRzIHJlc291cmNlcyBpbiB0
aGUgc3BlY2lmaWVkIHZlcnNpb24gdG8gdGhlIGRyYWZ0IGZsb3cuCgogVGhpcyBtZXRob2Qg
aXMgYSBbbG9uZy1ydW5uaW5nCiBvcGVyYXRpb25dKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9kaWFsb2dmbG93L2N4L2RvY3MvaG93L2xvbmctcnVubmluZy1vcGVyYXRpb24pLgogVGhl
IHJldHVybmVkIGBPcGVyYXRpb25gIHR5cGUgaGFzIHRoZSBmb2xsb3dpbmcgbWV0aG9kLXNw
ZWNpZmljIGZpZWxkczoKCiAtIGBtZXRhZGF0YWA6IEFuIGVtcHR5IFtTdHJ1Y3QKICAgbWVz
c2FnZV0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJvdG9jb2wtYnVmZmVycy9k
b2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYjc3RydWN0KQogLSBgcmVzcG9uc2VgOiBB
biBbRW1wdHkKICAgbWVzc2FnZV0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJv
dG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYjZW1wdHkpCgoM
CgUGAAIFARIDcgYRCgwKBQYAAgUCEgNyEiQKDAoFBgACBQMSA3IvSwoNCgUGAAIFBBIEcwR2
BgoRCgkGAAIFBLDKvCISBHMEdgYKDAoFBgACBQQSA3cEMgoPCggGAAIFBJsIABIDdwQyCg0K
BQYAAgUEEgR4BHsGCg8KBwYAAgUEmQgSBHgEewYKSQoEBgACBhIFfwKGAQMaOiBDb21wYXJl
cyB0aGUgc3BlY2lmaWVkIGJhc2UgdmVyc2lvbiB3aXRoIHRhcmdldCB2ZXJzaW9uLgoKDAoF
BgACBgESA38GFQoMCgUGAAIGAhIDfxYsCg0KBQYAAgYDEgSAAQ8mCg8KBQYAAgYEEgaBAQSE
AQYKEwoJBgACBgSwyrwiEgaBAQSEAQYKDQoFBgACBgQSBIUBBDoKEAoIBgACBgSbCAASBIUB
BDoKngEKAgQAEgaLAQCSAQEajwEgTWV0YWRhdGEgYXNzb2NpYXRlZCB3aXRoIHRoZSBsb25n
IHJ1bm5pbmcgb3BlcmF0aW9uIGZvcgogW1ZlcnNpb25zLkNyZWF0ZVZlcnNpb25dW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVmVyc2lvbnMuQ3JlYXRlVmVyc2lvbl0u
CgoLCgMEAAESBIsBCCYKnQEKBAQAAgASBo8BApEBBRqMASBOYW1lIG9mIHRoZSBjcmVhdGVk
IHZlcnNpb24uCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxM
b2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Zsb3dzLzxGbG93SUQ+L3ZlcnNpb25zLzxW
ZXJzaW9uSUQ+YC4KCg0KBQQAAgAFEgSPAQIICg0KBQQAAgABEgSPAQkQCg0KBQQAAgADEgSP
ARMUCg8KBQQAAgAIEgaPARWRAQQKEQoHBAACAAifCBIGjwEWkQEDCi8KAgQBEgaVAQDBAQEa
ISBSZXByZXNlbnRzIGEgdmVyc2lvbiBvZiBhIGZsb3cuCgoLCgMEAQESBJUBCA8KDQoDBAEH
EgaWAQKZAQQKDwoFBAEHnQgSBpYBApkBBAorCgQEAQQAEgacAQKoAQMaGyBUaGUgc3RhdGUg
b2YgdGhlIHZlcnNpb24uCgoNCgUEAQQAARIEnAEHDAo4CgYEAQQAAgASBJ4BBBoaKCBOb3Qg
c3BlY2lmaWVkLiBUaGlzIHZhbHVlIGlzIG5vdCB1c2VkLgoKDwoHBAEEAAIAARIEngEEFQoP
CgcEAQQAAgACEgSeARgZCksKBgQBBAACARIEoQEEEBo7IFZlcnNpb24gaXMgbm90IHJlYWR5
IHRvIHNlcnZlIChlLmcuIHRyYWluaW5nIGlzIHJ1bm5pbmcpLgoKDwoHBAEEAAIBARIEoQEE
CwoPCgcEAQQAAgECEgShAQ4PCkwKBgQBBAACAhIEpAEEEho8IFRyYWluaW5nIGhhcyBzdWNj
ZWVkZWQgYW5kIHRoaXMgdmVyc2lvbiBpcyByZWFkeSB0byBzZXJ2ZS4KCg8KBwQBBAACAgES
BKQBBA0KDwoHBAEEAAICAhIEpAEQEQoqCgYEAQQAAgMSBKcBBA8aGiBWZXJzaW9uIHRyYWlu
aW5nIGZhaWxlZC4KCg8KBwQBBAACAwESBKcBBAoKDwoHBAEEAAIDAhIEpwENDgrTAQoEBAEC
ABIErgECEhrEASBGb3JtYXQ6CiBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExv
Y2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZmxvd3MvPEZsb3dJRD4vdmVyc2lvbnMvPFZl
cnNpb25JRD4uCiBWZXJzaW9uIElEIGlzIGEgc2VsZi1pbmNyZWFzaW5nIG51bWJlciBnZW5l
cmF0ZWQgYnkgRGlhbG9nZmxvdyB1cG9uIHZlcnNpb24KIGNyZWF0aW9uLgoKDQoFBAECAAUS
BK4BAggKDQoFBAECAAESBK4BCQ0KDQoFBAECAAMSBK4BEBEKWQoEBAECARIEsQECQxpLIFJl
cXVpcmVkLiBUaGUgaHVtYW4tcmVhZGFibGUgbmFtZSBvZiB0aGUgdmVyc2lvbi4gTGltaXQg
b2YgNjQgY2hhcmFjdGVycy4KCg0KBQQBAgEFEgSxAQIICg0KBQQBAgEBEgSxAQkVCg0KBQQB
AgEDEgSxARgZCg0KBQQBAgEIEgSxARpCChAKCAQBAgEInAgAEgSxARtBCnwKBAQBAgISBLUB
AhkabiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIHZlcnNpb24uIFRoZSBtYXhpbXVtIGxlbmd0
aCBpcyA1MDAgY2hhcmFjdGVycy4gSWYKIGV4Y2VlZGVkLCB0aGUgcmVxdWVzdCBpcyByZWpl
Y3RlZC4KCg0KBQQBAgIFEgS1AQIICg0KBQQBAgIBEgS1AQkUCg0KBQQBAgIDEgS1ARcYCk4K
BAQBAgMSBLgBAksaQCBPdXRwdXQgb25seS4gVGhlIE5MVSBzZXR0aW5ncyBvZiB0aGUgZmxv
dyBhdCB2ZXJzaW9uIGNyZWF0aW9uLgoKDQoFBAECAwYSBLgBAg0KDQoFBAECAwESBLgBDhoK
DQoFBAECAwMSBLgBHR4KDQoFBAECAwgSBLgBH0oKEAoIBAECAwicCAASBLgBIEkKOgoEBAEC
BBIGuwECvAEyGiogT3V0cHV0IG9ubHkuIENyZWF0ZSB0aW1lIG9mIHRoZSB2ZXJzaW9uLgoK
DQoFBAECBAYSBLsBAhsKDQoFBAECBAESBLsBHCcKDQoFBAECBAMSBLsBKisKDQoFBAECBAgS
BLwBBjEKEAoIBAECBAicCAASBLwBBzAKgAEKBAQBAgUSBMABAj4aciBPdXRwdXQgb25seS4g
VGhlIHN0YXRlIG9mIHRoaXMgdmVyc2lvbi4gVGhpcyBmaWVsZCBpcyByZWFkLW9ubHkgYW5k
IGNhbm5vdAogYmUgc2V0IGJ5IGNyZWF0ZSBhbmQgdXBkYXRlIG1ldGhvZHMuCgoNCgUEAQIF
BhIEwAECBwoNCgUEAQIFARIEwAEIDQoNCgUEAQIFAxIEwAEQEQoNCgUEAQIFCBIEwAESPQoQ
CggEAQIFCJwIABIEwAETPAp7CgIEAhIGxQEA1gEBGm0gVGhlIHJlcXVlc3QgbWVzc2FnZSBm
b3IKIFtWZXJzaW9ucy5MaXN0VmVyc2lvbnNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzYmV0YTEuVmVyc2lvbnMuTGlzdFZlcnNpb25zXS4KCgsKAwQCARIExQEIGwrDAQoEBAIC
ABIGyQECzgEEGrIBIFJlcXVpcmVkLiBUaGUgW0Zsb3ddW2dvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzYmV0YTEuRmxvd10gdG8gbGlzdCBhbGwKIHZlcnNpb25zIGZvci4gRm9ybWF0
OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRz
LzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPmAuCgoNCgUEAgIABRIEyQECCAoNCgUEAgIAARIE
yQEJDwoNCgUEAgIAAxIEyQESEwoPCgUEAgIACBIGyQEUzgEDChAKCAQCAgAInAgAEgTKAQQq
ChEKBwQCAgAInwgSBssBBM0BBQpnCgQEAgIBEgTSAQIWGlkgVGhlIG1heGltdW0gbnVtYmVy
IG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeSBkZWZhdWx0IDIwIGFu
ZAogYXQgbW9zdCAxMDAuCgoNCgUEAgIBBRIE0gECBwoNCgUEAgIBARIE0gEIEQoNCgUEAgIB
AxIE0gEUFQpQCgQEAgICEgTVAQIYGkIgVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1
cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAICAgUSBNUBAggKDQoF
BAICAgESBNUBCRMKDQoFBAICAgMSBNUBFhcKfAoCBAMSBtoBAOMBARpuIFRoZSByZXNwb25z
ZSBtZXNzYWdlIGZvcgogW1ZlcnNpb25zLkxpc3RWZXJzaW9uc11bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjNiZXRhMS5WZXJzaW9ucy5MaXN0VmVyc2lvbnNdLgoKCwoDBAMBEgTa
AQgcCvIBCgQEAwIAEgTeAQIgGuMBIEEgbGlzdCBvZiB2ZXJzaW9ucy4gVGhlcmUgd2lsbCBi
ZSBhIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHJldHVybmVkIGJhc2VkCiBvbiB0aGUgcGFn
ZV9zaXplIGZpZWxkIGluIHRoZSByZXF1ZXN0LiBUaGUgbGlzdCBtYXkgaW4gc29tZSBjYXNl
cyBiZSBlbXB0eQogb3IgY29udGFpbiBmZXdlciBlbnRyaWVzIHRoYW4gcGFnZV9zaXplIGV2
ZW4gaWYgdGhpcyBpc24ndCB0aGUgbGFzdCBwYWdlLgoKDQoFBAMCAAQSBN4BAgoKDQoFBAMC
AAYSBN4BCxIKDQoFBAMCAAESBN4BExsKDQoFBAMCAAMSBN4BHh8KbwoEBAMCARIE4gECHRph
IFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkg
aWYgdGhlcmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAwIBBRIE
4gECCAoNCgUEAwIBARIE4gEJGAoNCgUEAwIBAxIE4gEbHAp3CgIEBBIG5wEA8QEBGmkgVGhl
IHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtWZXJzaW9ucy5HZXRWZXJzaW9uXVtnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlZlcnNpb25zLkdldFZlcnNpb25dLgoKCwoDBAQB
EgTnAQgZCtEBCgQEBAIAEgbrAQLwAQQawAEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZQog
W1ZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuVmVyc2lvbl0u
IEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+
L2FnZW50cy88QWdlbnRJRD4vZmxvd3MvPEZsb3dJRD4vdmVyc2lvbnMvPFZlcnNpb25JRD5g
LgoKDQoFBAQCAAUSBOsBAggKDQoFBAQCAAESBOsBCQ0KDQoFBAQCAAMSBOsBEBEKDwoFBAQC
AAgSBusBEvABAwoQCggEBAIACJwIABIE7AEEKgoRCgcEBAIACJ8IEgbtAQTvAQUKfQoCBAUS
BvUBAIICARpvIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVmVyc2lvbnMuQ3JlYXRlVmVy
c2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5WZXJzaW9ucy5DcmVh
dGVWZXJzaW9uXS4KCgsKAwQFARIE9QEIHArxAQoEBAUCABIG+QEC/gEEGuABIFJlcXVpcmVk
LiBUaGUgW0Zsb3ddW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRmxvd10g
dG8gY3JlYXRlIGFuCiBbVmVyc2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5WZXJzaW9uXSBmb3IuIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2Nh
dGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZmxvd3MvPEZsb3dJRD5gLgoK
DQoFBAUCAAUSBPkBAggKDQoFBAUCAAESBPkBCQ8KDQoFBAUCAAMSBPkBEhMKDwoFBAUCAAgS
BvkBFP4BAwoQCggEBQIACJwIABIE+gEEKgoRCgcEBQIACJ8IEgb7AQT9AQUKMAoEBAUCARIE
gQICPxoiIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiB0byBjcmVhdGUuCgoNCgUEBQIBBhIEgQIC
CQoNCgUEBQIBARIEgQIKEQoNCgUEBQIBAxIEgQIUFQoNCgUEBQIBCBIEgQIWPgoQCggEBQIB
CJwIABIEgQIXPQp9CgIEBhIGhgIAjgIBGm8gVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtW
ZXJzaW9ucy5VcGRhdGVWZXJzaW9uXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2Jl
dGExLlZlcnNpb25zLlVwZGF0ZVZlcnNpb25dLgoKCwoDBAYBEgSGAggcCjAKBAQGAgASBIgC
Aj8aIiBSZXF1aXJlZC4gVGhlIHZlcnNpb24gdG8gdXBkYXRlLgoKDQoFBAYCAAYSBIgCAgkK
DQoFBAYCAAESBIgCChEKDQoFBAYCAAMSBIgCFBUKDQoFBAYCAAgSBIgCFj4KEAoIBAYCAAic
CAASBIgCFz0KigEKBAQGAgESBowCAo0CLxp6IFJlcXVpcmVkLiBUaGUgbWFzayB0byBjb250
cm9sIHdoaWNoIGZpZWxkcyBnZXQgdXBkYXRlZC4gQ3VycmVudGx5IG9ubHkKIGBkZXNjcmlw
dGlvbmAgYW5kIGBkaXNwbGF5X25hbWVgIGNhbiBiZSB1cGRhdGVkLgoKDQoFBAYCAQYSBIwC
AhsKDQoFBAYCAQESBIwCHCcKDQoFBAYCAQMSBIwCKisKDQoFBAYCAQgSBI0CBi4KEAoIBAYC
AQicCAASBI0CBy0KfQoCBAcSBpICAJwCARpvIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBb
VmVyc2lvbnMuRGVsZXRlVmVyc2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5WZXJzaW9ucy5EZWxldGVWZXJzaW9uXS4KCgsKAwQHARIEkgIIHArbAQoEBAcCABIG
lgICmwIEGsoBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUKIFtWZXJzaW9uXVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlZlcnNpb25dIHRvIGRlbGV0ZS4gRm9ybWF0
OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRz
LzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPi92ZXJzaW9ucy88VmVyc2lvbklEPmAuCgoNCgUE
BwIABRIElgICCAoNCgUEBwIAARIElgIJDQoNCgUEBwIAAxIElgIQEQoPCgUEBwIACBIGlgIS
mwIDChAKCAQHAgAInAgAEgSXAgQqChEKBwQHAgAInwgSBpgCBJoCBQp5CgIECBIGoAIAsAIB
GmsgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtWZXJzaW9ucy5Mb2FkVmVyc2lvbl1bZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5WZXJzaW9ucy5Mb2FkVmVyc2lvbl0u
CgoLCgMECAESBKACCBoK4AEKBAQIAgASBqQCAqkCBBrPASBSZXF1aXJlZC4gVGhlIFtWZXJz
aW9uXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLlZlcnNpb25dIHRvIGJl
CiBsb2FkZWQgdG8gZHJhZnQgZmxvdy4gRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+
L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxvd0lE
Pi92ZXJzaW9ucy88VmVyc2lvbklEPmAuCgoNCgUECAIABRIEpAICCAoNCgUECAIAARIEpAIJ
DQoNCgUECAIAAxIEpAIQEQoPCgUECAIACBIGpAISqQIDChAKCAQIAgAInAgAEgSlAgQqChEK
BwQIAgAInwgSBqYCBKgCBQqeAgoEBAgCARIErwICKhqPAiBUaGlzIGZpZWxkIGlzIHVzZWQg
dG8gcHJldmVudCBhY2NpZGVudGFsIG92ZXJ3cml0ZSBvZiBvdGhlciBhZ2VudAogcmVzb3Vy
Y2VzLCB3aGljaCBjYW4gcG90ZW50aWFsbHkgaW1wYWN0IG90aGVyIGZsb3cncyBiZWhhdmlv
ci4gSWYKIGBhbGxvd19vdmVycmlkZV9hZ2VudF9yZXNvdXJjZXNgIGlzIGZhbHNlLCBjb25m
bGljdGVkIGFnZW50LWxldmVsIHJlc291cmNlcwogd2lsbCBub3QgYmUgb3ZlcnJpZGRlbiAo
aS5lLiBpbnRlbnRzLCBlbnRpdGllcywgd2ViaG9va3MpLgoKDQoFBAgCAQUSBK8CAgYKDQoF
BAgCAQESBK8CByUKDQoFBAgCAQMSBK8CKCkKgQEKAgQJEga0AgDUAgEacyBUaGUgcmVxdWVz
dCBtZXNzYWdlIGZvcgogW1ZlcnNpb25zLkNvbXBhcmVWZXJzaW9uc11bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5WZXJzaW9ucy5Db21wYXJlVmVyc2lvbnNdLgoKCwoD
BAkBEgS0AggeCpYCCgQECQIAEga6AgK/AgQahQIgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGJh
c2UgZmxvdyB2ZXJzaW9uIHRvIGNvbXBhcmUgd2l0aCB0aGUgdGFyZ2V0IHZlcnNpb24uCiBV
c2UgdmVyc2lvbiBJRCBgMGAgdG8gaW5kaWNhdGUgdGhlIGRyYWZ0IHZlcnNpb24gb2YgdGhl
IHNwZWNpZmllZCBmbG93LgoKIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2Nh
dGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZmxvd3MvPEZsb3dJRD4vdmVy
c2lvbnMvPFZlcnNpb25JRD5gLgoKDQoFBAkCAAUSBLoCAggKDQoFBAkCAAESBLoCCRUKDQoF
BAkCAAMSBLoCGBkKDwoFBAkCAAgSBroCGr8CAwoQCggECQIACJwIABIEuwIEKgoRCgcECQIA
CJ8IEga8AgS+AgUKlQIKBAQJAgESBsUCAsoCBBqEAiBSZXF1aXJlZC4gTmFtZSBvZiB0aGUg
dGFyZ2V0IGZsb3cgdmVyc2lvbiB0byBjb21wYXJlIHdpdGggdGhlCiBiYXNlIHZlcnNpb24u
IFVzZSB2ZXJzaW9uIElEIGAwYCB0byBpbmRpY2F0ZSB0aGUgZHJhZnQgdmVyc2lvbiBvZiB0
aGUKIHNwZWNpZmllZCBmbG93LiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9j
YXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Zsb3dzLzxGbG93SUQ+L3Zl
cnNpb25zLzxWZXJzaW9uSUQ+YC4KCg0KBQQJAgEFEgTFAgIICg0KBQQJAgEBEgTFAgkXCg0K
BQQJAgEDEgTFAhobCg8KBQQJAgEIEgbFAhzKAgMKEAoIBAkCAQicCAASBMYCBCoKEQoHBAkC
AQifCBIGxwIEyQIFCqACCgQECQICEgTTAgIbGpECIFRoZSBsYW5ndWFnZSB0byBjb21wYXJl
IHRoZSBmbG93IHZlcnNpb25zIGZvci4KCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgYWdlbnQn
cyBkZWZhdWx0IGxhbmd1YWdlIGlzIHVzZWQuCiBbTWFueQogbGFuZ3VhZ2VzXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9kb2NzL3JlZmVyZW5jZS9sYW5ndWFnZSkg
YXJlCiBzdXBwb3J0ZWQuIE5vdGU6IGxhbmd1YWdlcyBtdXN0IGJlIGVuYWJsZWQgaW4gdGhl
IGFnZW50IGJlZm9yZSB0aGV5IGNhbiBiZQogdXNlZC4KCg0KBQQJAgIFEgTTAgIICg0KBQQJ
AgIBEgTTAgkWCg0KBQQJAgIDEgTTAhkaCoIBCgIEChIG2AIA4QIBGnQgVGhlIHJlc3BvbnNl
IG1lc3NhZ2UgZm9yCiBbVmVyc2lvbnMuQ29tcGFyZVZlcnNpb25zXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52M2JldGExLlZlcnNpb25zLkNvbXBhcmVWZXJzaW9uc10uCgoLCgME
CgESBNgCCB8KQAoEBAoCABIE2gICJxoyIEpTT04gcmVwcmVzZW50YXRpb24gb2YgdGhlIGJh
c2UgdmVyc2lvbiBjb250ZW50LgoKDQoFBAoCAAUSBNoCAggKDQoFBAoCAAESBNoCCSIKDQoF
BAoCAAMSBNoCJSYKQgoEBAoCARIE3QICKRo0IEpTT04gcmVwcmVzZW50YXRpb24gb2YgdGhl
IHRhcmdldCB2ZXJzaW9uIGNvbnRlbnQuCgoNCgUECgIBBRIE3QICCAoNCgUECgIBARIE3QIJ
JAoNCgUECgIBAxIE3QInKAo8CgQECgICEgTgAgItGi4gVGhlIHRpbWVzdGFtcCB3aGVuIHRo
ZSB0d28gdmVyc2lvbiBjb21wYXJlcy4KCg0KBQQKAgIGEgTgAgIbCg0KBQQKAgIBEgTgAhwo
Cg0KBQQKAgIDEgTgAissYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::CreateVersionOperationMetadata ===
    # Fields for CreateVersionOperationMetadata
    # Field: version Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::Version ===
    # Fields for Version
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: nlu_settings Type: 11 (.google.cloud.dialogflow.cx.v3beta1.NluSettings)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.dialogflow.cx.v3beta1.Version.State)

# Enum: Version::State
our $Version_STATE_UNSPECIFIED = 0;
our $Version_RUNNING = 1;
our $Version_SUCCEEDED = 2;
our $Version_FAILED = 3;

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsRequest ===
    # Fields for ListVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsResponse ===
    # Fields for ListVersionsResponse
    # Field: versions Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Version)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::GetVersionRequest ===
    # Fields for GetVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::CreateVersionRequest ===
    # Fields for CreateVersionRequest
    # Field: parent Type: 9 ()
    # Field: version Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Version)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::UpdateVersionRequest ===
    # Fields for UpdateVersionRequest
    # Field: version Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Version)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::DeleteVersionRequest ===
    # Fields for DeleteVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::LoadVersionRequest ===
    # Fields for LoadVersionRequest
    # Field: name Type: 9 ()
    # Field: allow_override_agent_resources Type: 8 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::CompareVersionsRequest ===
    # Fields for CompareVersionsRequest
    # Field: base_version Type: 9 ()
    # Field: target_version Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Version::CompareVersionsResponse ===
    # Fields for CompareVersionsResponse
    # Field: base_version_content_json Type: 9 ()
    # Field: target_version_content_json Type: 9 ()
    # Field: compare_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Version::VersionsClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::Version::VersionsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Version::VersionsClient

Client stub representing the remote C<Versions> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Versions',
        method         => 'ListVersions',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsResponse',
    });
}

sub get_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Version::GetVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Versions',
        method         => 'GetVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Version::Version',
    });
}

sub create_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Version::CreateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Versions',
        method         => 'CreateVersion',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Version::UpdateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Versions',
        method         => 'UpdateVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Version::Version',
    });
}

sub delete_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Version::DeleteVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Versions',
        method         => 'DeleteVersion',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub load_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Version::LoadVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Versions',
        method         => 'LoadVersion',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub compare_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Version::CompareVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Versions',
        method         => 'CompareVersions',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Version::CompareVersionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Version - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/version.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::Version;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::Version::CreateVersionOperationMetadata->new({
        version => $version,
    });

    # Read or update a field
    my $val = $msg->version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::Version::CreateVersionOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::CreateVersionOperationMetadata

Metadata associated with the long running operation for
[Versions.CreateVersion][google.cloud.dialogflow.cx.v3beta1.Versions.CreateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Name of the created version.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::Version

Represents a version of a flow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Format:
projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>.
Version ID is a self-increasing number generated by Dialogflow upon version
creation.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human-readable name of the version. Limit of 64 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the version. The maximum length is 500 characters. If
exceeded, the request is rejected.

=item * C<< $msg->nlu_settings() >> / C<< $msg->nlu_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Flow::NluSettings>)

Output only. The NLU settings of the flow at version creation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the version.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Version::State>)

Output only. The state of this version. This field is read-only and cannot
be set by create and update methods.

=back

=head3 Enum: Version::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RUNNING> => C<1>

=item * C<SUCCEEDED> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsRequest

The request message for
[Versions.ListVersions][google.cloud.dialogflow.cx.v3beta1.Versions.ListVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The [Flow][google.cloud.dialogflow.cx.v3beta1.Flow] to list all
versions for. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 20 and
at most 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::ListVersionsResponse

The response message for
[Versions.ListVersions][google.cloud.dialogflow.cx.v3beta1.Versions.ListVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Version::Version>)

A list of versions. There will be a maximum number of items returned based
on the page_size field in the request. The list may in some cases be empty
or contain fewer entries than page_size even if this isn't the last page.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::GetVersionRequest

The request message for
[Versions.GetVersion][google.cloud.dialogflow.cx.v3beta1.Versions.GetVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[Version][google.cloud.dialogflow.cx.v3beta1.Version]. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::CreateVersionRequest

The request message for
[Versions.CreateVersion][google.cloud.dialogflow.cx.v3beta1.Versions.CreateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The [Flow][google.cloud.dialogflow.cx.v3beta1.Flow] to create an
[Version][google.cloud.dialogflow.cx.v3beta1.Version] for. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>`.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Version::Version>)

Required. The version to create.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::UpdateVersionRequest

The request message for
[Versions.UpdateVersion][google.cloud.dialogflow.cx.v3beta1.Versions.UpdateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Version::Version>)

Required. The version to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated. Currently only
`description` and `display_name` can be updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::DeleteVersionRequest

The request message for
[Versions.DeleteVersion][google.cloud.dialogflow.cx.v3beta1.Versions.DeleteVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[Version][google.cloud.dialogflow.cx.v3beta1.Version] to delete. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::LoadVersionRequest

The request message for
[Versions.LoadVersion][google.cloud.dialogflow.cx.v3beta1.Versions.LoadVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The [Version][google.cloud.dialogflow.cx.v3beta1.Version] to be
loaded to draft flow. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=item * C<< $msg->allow_override_agent_resources() >> / C<< $msg->allow_override_agent_resources($value) >>

Type: C<Bool>

This field is used to prevent accidental overwrite of other agent
resources, which can potentially impact other flow's behavior. If
`allow_override_agent_resources` is false, conflicted agent-level resources
will not be overridden (i.e. intents, entities, webhooks).

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::CompareVersionsRequest

The request message for
[Versions.CompareVersions][google.cloud.dialogflow.cx.v3beta1.Versions.CompareVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_version() >> / C<< $msg->base_version($value) >>

Type: C<String>

Required. Name of the base flow version to compare with the target version.
Use version ID `0` to indicate the draft version of the specified flow.

Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=item * C<< $msg->target_version() >> / C<< $msg->target_version($value) >>

Type: C<String>

Required. Name of the target flow version to compare with the
base version. Use version ID `0` to indicate the draft version of the
specified flow. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language to compare the flow versions for.

If not specified, the agent's default language is used.
[Many
languages](https://cloud.google.com/dialogflow/docs/reference/language) are
supported. Note: languages must be enabled in the agent before they can be
used.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Version::CompareVersionsResponse

The response message for
[Versions.CompareVersions][google.cloud.dialogflow.cx.v3beta1.Versions.CompareVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_version_content_json() >> / C<< $msg->base_version_content_json($value) >>

Type: C<String>

JSON representation of the base version content.

=item * C<< $msg->target_version_content_json() >> / C<< $msg->target_version_content_json($value) >>

Type: C<String>

JSON representation of the target version content.

=item * C<< $msg->compare_time() >> / C<< $msg->compare_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp when the two version compares.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::Version::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
