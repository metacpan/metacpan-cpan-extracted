package Google::Cloud::Dialogflow::Cx::V3::Version;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3::Flow };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My92ZXJzaW9uLnByb3RvEh1nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC9kaWFsb2dmbG93
L2N4L3YzL2Zsb3cucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3Rv
Ghtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9t
YXNrLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvImIKHkNyZWF0ZVZlcnNpb25PcGVyYXRpb25NZXRhZGF0YRJA
Cgd2ZXJzaW9uGAEgASgJQib6QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVmVyc2lv
blIHdmVyc2lvbiKOBAoHVmVyc2lvbhISCgRuYW1lGAEgASgJUgRuYW1lEiYKDGRpc3BsYXlf
bmFtZRgCIAEoCUID4EECUgtkaXNwbGF5TmFtZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVz
Y3JpcHRpb24SUgoMbmx1X3NldHRpbmdzGAQgASgLMiouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjMuTmx1U2V0dGluZ3NCA+BBA1ILbmx1U2V0dGluZ3MSQAoLY3JlYXRlX3RpbWUY
BSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSRwoF
c3RhdGUYBiABKA4yLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5WZXJzaW9uLlN0
YXRlQgPgQQNSBXN0YXRlIkYKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoHUlVO
TklORxABEg0KCVNVQ0NFRURFRBACEgoKBkZBSUxFRBADOn7qQXsKIWRpYWxvZ2Zsb3cuZ29v
Z2xlYXBpcy5jb20vVmVyc2lvbhJWcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2FnZW50cy97YWdlbnR9L2Zsb3dzL3tmbG93fS92ZXJzaW9ucy97dmVyc2lvbn0i
lAEKE0xpc3RWZXJzaW9uc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMSIWRpYWxv
Z2Zsb3cuZ29vZ2xlYXBpcy5jb20vVmVyc2lvblIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEo
BVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIoIBChRMaXN0VmVy
c2lvbnNSZXNwb25zZRJCCgh2ZXJzaW9ucxgBIAMoCzImLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzLlZlcnNpb25SCHZlcnNpb25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVIN
bmV4dFBhZ2VUb2tlbiJSChFHZXRWZXJzaW9uUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6
QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVmVyc2lvblIEbmFtZSKgAQoUQ3JlYXRl
VmVyc2lvblJlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMSIWRpYWxvZ2Zsb3cuZ29v
Z2xlYXBpcy5jb20vVmVyc2lvblIGcGFyZW50EkUKB3ZlcnNpb24YAiABKAsyJi5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52My5WZXJzaW9uQgPgQQJSB3ZlcnNpb24inwEKFFVwZGF0
ZVZlcnNpb25SZXF1ZXN0EkUKB3ZlcnNpb24YASABKAsyJi5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52My5WZXJzaW9uQgPgQQJSB3ZlcnNpb24SQAoLdXBkYXRlX21hc2sYAiABKAsy
Gi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQJSCnVwZGF0ZU1hc2siVQoURGVsZXRl
VmVyc2lvblJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFkaWFsb2dmbG93Lmdvb2ds
ZWFwaXMuY29tL1ZlcnNpb25SBG5hbWUimAEKEkxvYWRWZXJzaW9uUmVxdWVzdBI9CgRuYW1l
GAEgASgJQingQQL6QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVmVyc2lvblIEbmFt
ZRJDCh5hbGxvd19vdmVycmlkZV9hZ2VudF9yZXNvdXJjZXMYAiABKAhSG2FsbG93T3ZlcnJp
ZGVBZ2VudFJlc291cmNlcyLdAQoWQ29tcGFyZVZlcnNpb25zUmVxdWVzdBJMCgxiYXNlX3Zl
cnNpb24YASABKAlCKeBBAvpBIwohZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9WZXJzaW9u
UgtiYXNlVmVyc2lvbhJQCg50YXJnZXRfdmVyc2lvbhgCIAEoCUIp4EEC+kEjCiFkaWFsb2dm
bG93Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb25SDXRhcmdldFZlcnNpb24SIwoNbGFuZ3VhZ2Vf
Y29kZRgDIAEoCVIMbGFuZ3VhZ2VDb2RlItIBChdDb21wYXJlVmVyc2lvbnNSZXNwb25zZRI5
ChliYXNlX3ZlcnNpb25fY29udGVudF9qc29uGAEgASgJUhZiYXNlVmVyc2lvbkNvbnRlbnRK
c29uEj0KG3RhcmdldF92ZXJzaW9uX2NvbnRlbnRfanNvbhgCIAEoCVIYdGFyZ2V0VmVyc2lv
bkNvbnRlbnRKc29uEj0KDGNvbXBhcmVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSC2NvbXBhcmVUaW1lMuIMCghWZXJzaW9ucxLHAQoMTGlzdFZlcnNpb25zEjIu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuTGlzdFZlcnNpb25zUmVxdWVzdBozLmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkxpc3RWZXJzaW9uc1Jlc3BvbnNlIk6C0+ST
Aj8SPS92My97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZmxvd3Mv
Kn0vdmVyc2lvbnPaQQZwYXJlbnQStAEKCkdldFZlcnNpb24SMC5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52My5HZXRWZXJzaW9uUmVxdWVzdBomLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzLlZlcnNpb24iTILT5JMCPxI9L3YzL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovYWdlbnRzLyovZmxvd3MvKi92ZXJzaW9ucy8qfdpBBG5hbWUS8QEKDUNyZWF0ZVZl
cnNpb24SMy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5DcmVhdGVWZXJzaW9uUmVx
dWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iiwGC0+STAkgiPS92My97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnRzLyovZmxvd3MvKn0vdmVyc2lvbnM6
B3ZlcnNpb27aQQ5wYXJlbnQsdmVyc2lvbspBKQoHVmVyc2lvbhIeQ3JlYXRlVmVyc2lvbk9w
ZXJhdGlvbk1ldGFkYXRhEtoBCg1VcGRhdGVWZXJzaW9uEjMuZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjMuVXBkYXRlVmVyc2lvblJlcXVlc3QaJi5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52My5WZXJzaW9uImyC0+STAlAyRS92My97dmVyc2lvbi5uYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovYWdlbnRzLyovZmxvd3MvKi92ZXJzaW9ucy8qfToHdmVyc2lvbtpB
E3ZlcnNpb24sdXBkYXRlX21hc2sSqgEKDURlbGV0ZVZlcnNpb24SMy5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52My5EZWxldGVWZXJzaW9uUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1
Zi5FbXB0eSJMgtPkkwI/Kj0vdjMve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2Vu
dHMvKi9mbG93cy8qL3ZlcnNpb25zLyp92kEEbmFtZRLoAQoLTG9hZFZlcnNpb24SMS5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5Mb2FkVmVyc2lvblJlcXVlc3QaHS5nb29nbGUu
bG9uZ3J1bm5pbmcuT3BlcmF0aW9uIoYBgtPkkwJHIkIvdjMve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9hZ2VudHMvKi9mbG93cy8qL3ZlcnNpb25zLyp9OmxvYWQ6ASraQQRuYW1l
ykEvChVnb29nbGUucHJvdG9idWYuRW1wdHkSFmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3QS8QEK
D0NvbXBhcmVWZXJzaW9ucxI1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkNvbXBh
cmVWZXJzaW9uc1JlcXVlc3QaNi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5Db21w
YXJlVmVyc2lvbnNSZXNwb25zZSJvgtPkkwJaIlUvdjMve2Jhc2VfdmVyc2lvbj1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Zsb3dzLyovdmVyc2lvbnMvKn06Y29tcGFyZVZl
cnNpb25zOgEq2kEMYmFzZV92ZXJzaW9uGnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t
0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dCrwEKIWNvbS5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52M0IMVmVyc2lvblByb3RvUAFaMWNsb3VkLmdvb2dsZS5j
b20vZ28vZGlhbG9nZmxvdy9jeC9hcGl2My9jeHBiO2N4cGKiAgJERqoCHUdvb2dsZS5DbG91
ZC5EaWFsb2dmbG93LkN4LlYz6gIhR29vZ2xlOjpDbG91ZDo6RGlhbG9nZmxvdzo6Q1g6OlYz
SvNWCgcSBQ4A3gIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAmCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQS
AxYAMgoJCgIDBRIDFwAtCgkKAgMGEgMYACUKCQoCAwcSAxkAKgoJCgIDCBIDGgAmCgkKAgMJ
EgMbACkKCAoBCBIDHQA6CgkKAgglEgMdADoKCAoBCBIDHgBICgkKAggLEgMeAEgKCAoBCBID
HwAiCgkKAggKEgMfACIKCAoBCBIDIAAtCgkKAggIEgMgAC0KCAoBCBIDIQA6CgkKAggBEgMh
ADoKCAoBCBIDIgAgCgkKAggkEgMiACAKCAoBCBIDIwA6CgkKAggtEgMjADoKVgoCBgASBSYA
hAEBGkkgU2VydmljZSBmb3IgbWFuYWdpbmcgW1ZlcnNpb25zXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52My5WZXJzaW9uXS4KCgoKAwYAARIDJggQCgoKAwYAAxIDJwJBCgwKBQYA
A5kIEgMnAkEKCwoDBgADEgQoAiozCg0KBQYAA5oIEgQoAiozCm4KBAYAAgASBC4CMwMaYCBS
ZXR1cm5zIHRoZSBsaXN0IG9mIGFsbCB2ZXJzaW9ucyBpbiB0aGUgc3BlY2lmaWVkCiBbRmxv
d11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRmxvd10uCgoMCgUGAAIAARIDLgYS
CgwKBQYAAgACEgMuEyYKDAoFBgACAAMSAy4xRQoNCgUGAAIABBIELwQxBgoRCgkGAAIABLDK
vCISBC8EMQYKDAoFBgACAAQSAzIENAoPCggGAAIABJsIABIDMgQ0ClkKBAYAAgESBDYCOwMa
SyBSZXRyaWV2ZXMgdGhlIHNwZWNpZmllZCBbVmVyc2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cuY3gudjMuVmVyc2lvbl0uCgoMCgUGAAIBARIDNgYQCgwKBQYAAgECEgM2ESIKDAoF
BgACAQMSAzYtNAoNCgUGAAIBBBIENwQ5BgoRCgkGAAIBBLDKvCISBDcEOQYKDAoFBgACAQQS
AzoEMgoPCggGAAIBBJsIABIDOgQyCvgDCgQGAAICEgRHAlIDGukDIENyZWF0ZXMgYSBbVmVy
c2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVmVyc2lvbl0gaW4gdGhlIHNw
ZWNpZmllZAogW0Zsb3ddW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkZsb3ddLgoK
IFRoaXMgbWV0aG9kIGlzIGEgW2xvbmctcnVubmluZwogb3BlcmF0aW9uXShodHRwczovL2Ns
b3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2hvdy9sb25nLXJ1bm5pbmctb3Bl
cmF0aW9uKS4KIFRoZSByZXR1cm5lZCBgT3BlcmF0aW9uYCB0eXBlIGhhcyB0aGUgZm9sbG93
aW5nIG1ldGhvZC1zcGVjaWZpYyBmaWVsZHM6CgogLSBgbWV0YWRhdGFgOgogW0NyZWF0ZVZl
cnNpb25PcGVyYXRpb25NZXRhZGF0YV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMu
Q3JlYXRlVmVyc2lvbk9wZXJhdGlvbk1ldGFkYXRhXQogLSBgcmVzcG9uc2VgOiBbVmVyc2lv
bl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVmVyc2lvbl0KCgwKBQYAAgIBEgNH
BhMKDAoFBgACAgISA0cUKAoMCgUGAAICAxIDSA8rCg0KBQYAAgIEEgRJBEwGChEKCQYAAgIE
sMq8IhIESQRMBgoMCgUGAAICBBIDTQQ8Cg8KCAYAAgIEmwgAEgNNBDwKDQoFBgACAgQSBE4E
UQYKDwoHBgACAgSZCBIETgRRBgpXCgQGAAIDEgRVAlsDGkkgVXBkYXRlcyB0aGUgc3BlY2lm
aWVkIFtWZXJzaW9uXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5WZXJzaW9uXS4K
CgwKBQYAAgMBEgNVBhMKDAoFBgACAwISA1UUKAoMCgUGAAIDAxIDVTM6Cg0KBQYAAgMEEgRW
BFkGChEKCQYAAgMEsMq8IhIEVgRZBgoMCgUGAAIDBBIDWgRBCg8KCAYAAgMEmwgAEgNaBEEK
VwoEBgACBBIEXgJjAxpJIERlbGV0ZXMgdGhlIHNwZWNpZmllZCBbVmVyc2lvbl1bZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVmVyc2lvbl0uCgoMCgUGAAIEARIDXgYTCgwKBQYA
AgQCEgNeFCgKDAoFBgACBAMSA14zSAoNCgUGAAIEBBIEXwRhBgoRCgkGAAIEBLDKvCISBF8E
YQYKDAoFBgACBAQSA2IEMgoPCggGAAIEBJsIABIDYgQyCogECgQGAAIFEgRvAnkDGvkDIExv
YWRzIHJlc291cmNlcyBpbiB0aGUgc3BlY2lmaWVkIHZlcnNpb24gdG8gdGhlIGRyYWZ0IGZs
b3cuCgogVGhpcyBtZXRob2QgaXMgYSBbbG9uZy1ydW5uaW5nCiBvcGVyYXRpb25dKGh0dHBz
Oi8vY2xvdWQuZ29vZ2xlLmNvbS9kaWFsb2dmbG93L2N4L2RvY3MvaG93L2xvbmctcnVubmlu
Zy1vcGVyYXRpb24pLgogVGhlIHJldHVybmVkIGBPcGVyYXRpb25gIHR5cGUgaGFzIHRoZSBm
b2xsb3dpbmcgbWV0aG9kLXNwZWNpZmljIGZpZWxkczoKCiAtIGBtZXRhZGF0YWA6IEFuIGVt
cHR5IFtTdHJ1Y3QKICAgbWVzc2FnZV0oaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20v
cHJvdG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYjc3RydWN0
KQogLSBgcmVzcG9uc2VgOiBBbiBbRW1wdHkKICAgbWVzc2FnZV0oaHR0cHM6Ly9kZXZlbG9w
ZXJzLmdvb2dsZS5jb20vcHJvdG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUu
cHJvdG9idWYjZW1wdHkpCgoMCgUGAAIFARIDbwYRCgwKBQYAAgUCEgNvEiQKDAoFBgACBQMS
A28vSwoNCgUGAAIFBBIEcARzBgoRCgkGAAIFBLDKvCISBHAEcwYKDAoFBgACBQQSA3QEMgoP
CggGAAIFBJsIABIDdAQyCg0KBQYAAgUEEgR1BHgGCg8KBwYAAgUEmQgSBHUEeAYKSQoEBgAC
BhIFfAKDAQMaOiBDb21wYXJlcyB0aGUgc3BlY2lmaWVkIGJhc2UgdmVyc2lvbiB3aXRoIHRh
cmdldCB2ZXJzaW9uLgoKDAoFBgACBgESA3wGFQoMCgUGAAIGAhIDfBYsCgwKBQYAAgYDEgN9
DyYKDgoFBgACBgQSBX4EgQEGChIKCQYAAgYEsMq8IhIFfgSBAQYKDQoFBgACBgQSBIIBBDoK
EAoIBgACBgSbCAASBIIBBDoKmQEKAgQAEgaIAQCPAQEaigEgTWV0YWRhdGEgYXNzb2NpYXRl
ZCB3aXRoIHRoZSBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uIGZvcgogW1ZlcnNpb25zLkNyZWF0
ZVZlcnNpb25dW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlZlcnNpb25zLkNyZWF0
ZVZlcnNpb25dLgoKCwoDBAABEgSIAQgmCp0BCgQEAAIAEgaMAQKOAQUajAEgTmFtZSBvZiB0
aGUgY3JlYXRlZCB2ZXJzaW9uLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xv
Y2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPi92
ZXJzaW9ucy88VmVyc2lvbklEPmAuCgoNCgUEAAIABRIEjAECCAoNCgUEAAIAARIEjAEJEAoN
CgUEAAIAAxIEjAETFAoPCgUEAAIACBIGjAEVjgEEChEKBwQAAgAInwgSBowBFo4BAwovCgIE
ARIGkgEAvgEBGiEgUmVwcmVzZW50cyBhIHZlcnNpb24gb2YgYSBmbG93LgoKCwoDBAEBEgSS
AQgPCg0KAwQBBxIGkwEClgEECg8KBQQBB50IEgaTAQKWAQQKKwoEBAEEABIGmQECpQEDGhsg
VGhlIHN0YXRlIG9mIHRoZSB2ZXJzaW9uLgoKDQoFBAEEAAESBJkBBwwKOAoGBAEEAAIAEgSb
AQQaGiggTm90IHNwZWNpZmllZC4gVGhpcyB2YWx1ZSBpcyBub3QgdXNlZC4KCg8KBwQBBAAC
AAESBJsBBBUKDwoHBAEEAAIAAhIEmwEYGQpLCgYEAQQAAgESBJ4BBBAaOyBWZXJzaW9uIGlz
IG5vdCByZWFkeSB0byBzZXJ2ZSAoZS5nLiB0cmFpbmluZyBpcyBydW5uaW5nKS4KCg8KBwQB
BAACAQESBJ4BBAsKDwoHBAEEAAIBAhIEngEODwpMCgYEAQQAAgISBKEBBBIaPCBUcmFpbmlu
ZyBoYXMgc3VjY2VlZGVkIGFuZCB0aGlzIHZlcnNpb24gaXMgcmVhZHkgdG8gc2VydmUuCgoP
CgcEAQQAAgIBEgShAQQNCg8KBwQBBAACAgISBKEBEBEKKgoGBAEEAAIDEgSkAQQPGhogVmVy
c2lvbiB0cmFpbmluZyBmYWlsZWQuCgoPCgcEAQQAAgMBEgSkAQQKCg8KBwQBBAACAwISBKQB
DQ4K0wEKBAQBAgASBKsBAhIaxAEgRm9ybWF0OgogcHJvamVjdHMvPFByb2plY3RJRD4vbG9j
YXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Zsb3dzLzxGbG93SUQ+L3Zl
cnNpb25zLzxWZXJzaW9uSUQ+LgogVmVyc2lvbiBJRCBpcyBhIHNlbGYtaW5jcmVhc2luZyBu
dW1iZXIgZ2VuZXJhdGVkIGJ5IERpYWxvZ2Zsb3cgdXBvbiB2ZXJzaW9uCiBjcmVhdGlvbi4K
Cg0KBQQBAgAFEgSrAQIICg0KBQQBAgABEgSrAQkNCg0KBQQBAgADEgSrARARClkKBAQBAgES
BK4BAkMaSyBSZXF1aXJlZC4gVGhlIGh1bWFuLXJlYWRhYmxlIG5hbWUgb2YgdGhlIHZlcnNp
b24uIExpbWl0IG9mIDY0IGNoYXJhY3RlcnMuCgoNCgUEAQIBBRIErgECCAoNCgUEAQIBARIE
rgEJFQoNCgUEAQIBAxIErgEYGQoNCgUEAQIBCBIErgEaQgoQCggEAQIBCJwIABIErgEbQQp8
CgQEAQICEgSyAQIZGm4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSB2ZXJzaW9uLiBUaGUgbWF4
aW11bSBsZW5ndGggaXMgNTAwIGNoYXJhY3RlcnMuIElmCiBleGNlZWRlZCwgdGhlIHJlcXVl
c3QgaXMgcmVqZWN0ZWQuCgoNCgUEAQICBRIEsgECCAoNCgUEAQICARIEsgEJFAoNCgUEAQIC
AxIEsgEXGApOCgQEAQIDEgS1AQJLGkAgT3V0cHV0IG9ubHkuIFRoZSBOTFUgc2V0dGluZ3Mg
b2YgdGhlIGZsb3cgYXQgdmVyc2lvbiBjcmVhdGlvbi4KCg0KBQQBAgMGEgS1AQINCg0KBQQB
AgMBEgS1AQ4aCg0KBQQBAgMDEgS1AR0eCg0KBQQBAgMIEgS1AR9KChAKCAQBAgMInAgAEgS1
ASBJCjoKBAQBAgQSBrgBArkBMhoqIE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZSBvZiB0aGUg
dmVyc2lvbi4KCg0KBQQBAgQGEgS4AQIbCg0KBQQBAgQBEgS4ARwnCg0KBQQBAgQDEgS4ASor
Cg0KBQQBAgQIEgS5AQYxChAKCAQBAgQInAgAEgS5AQcwCoABCgQEAQIFEgS9AQI+GnIgT3V0
cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGlzIHZlcnNpb24uIFRoaXMgZmllbGQgaXMgcmVh
ZC1vbmx5IGFuZCBjYW5ub3QKIGJlIHNldCBieSBjcmVhdGUgYW5kIHVwZGF0ZSBtZXRob2Rz
LgoKDQoFBAECBQYSBL0BAgcKDQoFBAECBQESBL0BCA0KDQoFBAECBQMSBL0BEBEKDQoFBAEC
BQgSBL0BEj0KEAoIBAECBQicCAASBL0BEzwKdgoCBAISBsIBANMBARpoIFRoZSByZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbVmVyc2lvbnMuTGlzdFZlcnNpb25zXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52My5WZXJzaW9ucy5MaXN0VmVyc2lvbnNdLgoKCwoDBAIBEgTCAQgbCr4B
CgQEAgIAEgbGAQLLAQQarQEgUmVxdWlyZWQuIFRoZSBbRmxvd11bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjMuRmxvd10gdG8gbGlzdCBhbGwKIHZlcnNpb25zIGZvci4gRm9ybWF0
OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRz
LzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPmAuCgoNCgUEAgIABRIExgECCAoNCgUEAgIAARIE
xgEJDwoNCgUEAgIAAxIExgESEwoPCgUEAgIACBIGxgEUywEDChAKCAQCAgAInAgAEgTHAQQq
ChEKBwQCAgAInwgSBsgBBMoBBQpnCgQEAgIBEgTPAQIWGlkgVGhlIG1heGltdW0gbnVtYmVy
IG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeSBkZWZhdWx0IDIwIGFu
ZAogYXQgbW9zdCAxMDAuCgoNCgUEAgIBBRIEzwECBwoNCgUEAgIBARIEzwEIEQoNCgUEAgIB
AxIEzwEUFQpQCgQEAgICEgTSAQIYGkIgVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1
cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAICAgUSBNIBAggKDQoF
BAICAgESBNIBCRMKDQoFBAICAgMSBNIBFhcKdwoCBAMSBtcBAOABARppIFRoZSByZXNwb25z
ZSBtZXNzYWdlIGZvcgogW1ZlcnNpb25zLkxpc3RWZXJzaW9uc11bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjMuVmVyc2lvbnMuTGlzdFZlcnNpb25zXS4KCgsKAwQDARIE1wEIHAry
AQoEBAMCABIE2wECIBrjASBBIGxpc3Qgb2YgdmVyc2lvbnMuIFRoZXJlIHdpbGwgYmUgYSBt
YXhpbXVtIG51bWJlciBvZiBpdGVtcyByZXR1cm5lZCBiYXNlZAogb24gdGhlIHBhZ2Vfc2l6
ZSBmaWVsZCBpbiB0aGUgcmVxdWVzdC4gVGhlIGxpc3QgbWF5IGluIHNvbWUgY2FzZXMgYmUg
ZW1wdHkKIG9yIGNvbnRhaW4gZmV3ZXIgZW50cmllcyB0aGFuIHBhZ2Vfc2l6ZSBldmVuIGlm
IHRoaXMgaXNuJ3QgdGhlIGxhc3QgcGFnZS4KCg0KBQQDAgAEEgTbAQIKCg0KBQQDAgAGEgTb
AQsSCg0KBQQDAgABEgTbARMbCg0KBQQDAgADEgTbAR4fCm8KBAQDAgESBN8BAh0aYSBUb2tl
biB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRo
ZXJlIGFyZSBubyBtb3JlCiByZXN1bHRzIGluIHRoZSBsaXN0LgoKDQoFBAMCAQUSBN8BAggK
DQoFBAMCAQESBN8BCRgKDQoFBAMCAQMSBN8BGxwKcgoCBAQSBuQBAO4BARpkIFRoZSByZXF1
ZXN0IG1lc3NhZ2UgZm9yCiBbVmVyc2lvbnMuR2V0VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjMuVmVyc2lvbnMuR2V0VmVyc2lvbl0uCgoLCgMEBAESBOQBCBkKzAEK
BAQEAgASBugBAu0BBBq7ASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIFtWZXJzaW9uXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5WZXJzaW9uXS4KIEZvcm1hdDoKIGBwcm9q
ZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJ
RD4vZmxvd3MvPEZsb3dJRD4vdmVyc2lvbnMvPFZlcnNpb25JRD5gLgoKDQoFBAQCAAUSBOgB
AggKDQoFBAQCAAESBOgBCQ0KDQoFBAQCAAMSBOgBEBEKDwoFBAQCAAgSBugBEu0BAwoQCggE
BAIACJwIABIE6QEEKgoRCgcEBAIACJ8IEgbqAQTsAQUKeAoCBAUSBvIBAP8BARpqIFRoZSBy
ZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVmVyc2lvbnMuQ3JlYXRlVmVyc2lvbl1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjMuVmVyc2lvbnMuQ3JlYXRlVmVyc2lvbl0uCgoLCgMEBQES
BPIBCBwK5wEKBAQFAgASBvYBAvsBBBrWASBSZXF1aXJlZC4gVGhlIFtGbG93XVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52My5GbG93XSB0byBjcmVhdGUgYW4KIFtWZXJzaW9uXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5WZXJzaW9uXSBmb3IuIEZvcm1hdDoKIGBw
cm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdl
bnRJRD4vZmxvd3MvPEZsb3dJRD5gLgoKDQoFBAUCAAUSBPYBAggKDQoFBAUCAAESBPYBCQ8K
DQoFBAUCAAMSBPYBEhMKDwoFBAUCAAgSBvYBFPsBAwoQCggEBQIACJwIABIE9wEEKgoRCgcE
BQIACJ8IEgb4AQT6AQUKMAoEBAUCARIE/gECPxoiIFJlcXVpcmVkLiBUaGUgdmVyc2lvbiB0
byBjcmVhdGUuCgoNCgUEBQIBBhIE/gECCQoNCgUEBQIBARIE/gEKEQoNCgUEBQIBAxIE/gEU
FQoNCgUEBQIBCBIE/gEWPgoQCggEBQIBCJwIABIE/gEXPQp4CgIEBhIGgwIAiwIBGmogVGhl
IHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtWZXJzaW9ucy5VcGRhdGVWZXJzaW9uXVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52My5WZXJzaW9ucy5VcGRhdGVWZXJzaW9uXS4KCgsKAwQG
ARIEgwIIHAowCgQEBgIAEgSFAgI/GiIgUmVxdWlyZWQuIFRoZSB2ZXJzaW9uIHRvIHVwZGF0
ZS4KCg0KBQQGAgAGEgSFAgIJCg0KBQQGAgABEgSFAgoRCg0KBQQGAgADEgSFAhQVCg0KBQQG
AgAIEgSFAhY+ChAKCAQGAgAInAgAEgSFAhc9CooBCgQEBgIBEgaJAgKKAi8aeiBSZXF1aXJl
ZC4gVGhlIG1hc2sgdG8gY29udHJvbCB3aGljaCBmaWVsZHMgZ2V0IHVwZGF0ZWQuIEN1cnJl
bnRseSBvbmx5CiBgZGVzY3JpcHRpb25gIGFuZCBgZGlzcGxheV9uYW1lYCBjYW4gYmUgdXBk
YXRlZC4KCg0KBQQGAgEGEgSJAgIbCg0KBQQGAgEBEgSJAhwnCg0KBQQGAgEDEgSJAiorCg0K
BQQGAgEIEgSKAgYuChAKCAQGAgEInAgAEgSKAgctCngKAgQHEgaPAgCZAgEaaiBUaGUgcmVx
dWVzdCBtZXNzYWdlIGZvcgogW1ZlcnNpb25zLkRlbGV0ZVZlcnNpb25dW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzLlZlcnNpb25zLkRlbGV0ZVZlcnNpb25dLgoKCwoDBAcBEgSP
AggcCtYBCgQEBwIAEgaTAgKYAgQaxQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBbVmVy
c2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVmVyc2lvbl0KIHRvIGRlbGV0
ZS4gRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25J
RD4vYWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPi92ZXJzaW9ucy88VmVyc2lvbklE
PmAuCgoNCgUEBwIABRIEkwICCAoNCgUEBwIAARIEkwIJDQoNCgUEBwIAAxIEkwIQEQoPCgUE
BwIACBIGkwISmAIDChAKCAQHAgAInAgAEgSUAgQqChEKBwQHAgAInwgSBpUCBJcCBQp0CgIE
CBIGnQIArQIBGmYgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtWZXJzaW9ucy5Mb2FkVmVy
c2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVmVyc2lvbnMuTG9hZFZlcnNp
b25dLgoKCwoDBAgBEgSdAggaCtsBCgQECAIAEgahAgKmAgQaygEgUmVxdWlyZWQuIFRoZSBb
VmVyc2lvbl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuVmVyc2lvbl0gdG8gYmUg
bG9hZGVkCiB0byBkcmFmdCBmbG93LiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4v
bG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Zsb3dzLzxGbG93SUQ+
L3ZlcnNpb25zLzxWZXJzaW9uSUQ+YC4KCg0KBQQIAgAFEgShAgIICg0KBQQIAgABEgShAgkN
Cg0KBQQIAgADEgShAhARCg8KBQQIAgAIEgahAhKmAgMKEAoIBAgCAAicCAASBKICBCoKEQoH
BAgCAAifCBIGowIEpQIFCp4CCgQECAIBEgSsAgIqGo8CIFRoaXMgZmllbGQgaXMgdXNlZCB0
byBwcmV2ZW50IGFjY2lkZW50YWwgb3ZlcndyaXRlIG9mIG90aGVyIGFnZW50CiByZXNvdXJj
ZXMsIHdoaWNoIGNhbiBwb3RlbnRpYWxseSBpbXBhY3Qgb3RoZXIgZmxvdydzIGJlaGF2aW9y
LiBJZgogYGFsbG93X292ZXJyaWRlX2FnZW50X3Jlc291cmNlc2AgaXMgZmFsc2UsIGNvbmZs
aWN0ZWQgYWdlbnQtbGV2ZWwgcmVzb3VyY2VzCiB3aWxsIG5vdCBiZSBvdmVycmlkZGVuIChp
LmUuIGludGVudHMsIGVudGl0aWVzLCB3ZWJob29rcykuCgoNCgUECAIBBRIErAICBgoNCgUE
CAIBARIErAIHJQoNCgUECAIBAxIErAIoKQp8CgIECRIGsQIA0QIBGm4gVGhlIHJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtWZXJzaW9ucy5Db21wYXJlVmVyc2lvbnNdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzLlZlcnNpb25zLkNvbXBhcmVWZXJzaW9uc10uCgoLCgMECQESBLEC
CB4KlgIKBAQJAgASBrcCArwCBBqFAiBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgYmFzZSBmbG93
IHZlcnNpb24gdG8gY29tcGFyZSB3aXRoIHRoZSB0YXJnZXQgdmVyc2lvbi4KIFVzZSB2ZXJz
aW9uIElEIGAwYCB0byBpbmRpY2F0ZSB0aGUgZHJhZnQgdmVyc2lvbiBvZiB0aGUgc3BlY2lm
aWVkIGZsb3cuCgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88
TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPi92ZXJzaW9ucy88
VmVyc2lvbklEPmAuCgoNCgUECQIABRIEtwICCAoNCgUECQIAARIEtwIJFQoNCgUECQIAAxIE
twIYGQoPCgUECQIACBIGtwIavAIDChAKCAQJAgAInAgAEgS4AgQqChEKBwQJAgAInwgSBrkC
BLsCBQqVAgoEBAkCARIGwgICxwIEGoQCIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSB0YXJnZXQg
ZmxvdyB2ZXJzaW9uIHRvIGNvbXBhcmUgd2l0aCB0aGUKIGJhc2UgdmVyc2lvbi4gVXNlIHZl
cnNpb24gSUQgYDBgIHRvIGluZGljYXRlIHRoZSBkcmFmdCB2ZXJzaW9uIG9mIHRoZQogc3Bl
Y2lmaWVkIGZsb3cuIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMv
PExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZmxvd3MvPEZsb3dJRD4vdmVyc2lvbnMv
PFZlcnNpb25JRD5gLgoKDQoFBAkCAQUSBMICAggKDQoFBAkCAQESBMICCRcKDQoFBAkCAQMS
BMICGhsKDwoFBAkCAQgSBsICHMcCAwoQCggECQIBCJwIABIEwwIEKgoRCgcECQIBCJ8IEgbE
AgTGAgUKoAIKBAQJAgISBNACAhsakQIgVGhlIGxhbmd1YWdlIHRvIGNvbXBhcmUgdGhlIGZs
b3cgdmVyc2lvbnMgZm9yLgoKIElmIG5vdCBzcGVjaWZpZWQsIHRoZSBhZ2VudCdzIGRlZmF1
bHQgbGFuZ3VhZ2UgaXMgdXNlZC4KIFtNYW55CiBsYW5ndWFnZXNdKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9kaWFsb2dmbG93L2RvY3MvcmVmZXJlbmNlL2xhbmd1YWdlKSBhcmUKIHN1
cHBvcnRlZC4gTm90ZTogbGFuZ3VhZ2VzIG11c3QgYmUgZW5hYmxlZCBpbiB0aGUgYWdlbnQg
YmVmb3JlIHRoZXkgY2FuIGJlCiB1c2VkLgoKDQoFBAkCAgUSBNACAggKDQoFBAkCAgESBNAC
CRYKDQoFBAkCAgMSBNACGRoKfQoCBAoSBtUCAN4CARpvIFRoZSByZXNwb25zZSBtZXNzYWdl
IGZvcgogW1ZlcnNpb25zLkNvbXBhcmVWZXJzaW9uc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjMuVmVyc2lvbnMuQ29tcGFyZVZlcnNpb25zXS4KCgsKAwQKARIE1QIIHwpACgQE
CgIAEgTXAgInGjIgSlNPTiByZXByZXNlbnRhdGlvbiBvZiB0aGUgYmFzZSB2ZXJzaW9uIGNv
bnRlbnQuCgoNCgUECgIABRIE1wICCAoNCgUECgIAARIE1wIJIgoNCgUECgIAAxIE1wIlJgpC
CgQECgIBEgTaAgIpGjQgSlNPTiByZXByZXNlbnRhdGlvbiBvZiB0aGUgdGFyZ2V0IHZlcnNp
b24gY29udGVudC4KCg0KBQQKAgEFEgTaAgIICg0KBQQKAgEBEgTaAgkkCg0KBQQKAgEDEgTa
AicoCjwKBAQKAgISBN0CAi0aLiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHR3byB2ZXJzaW9u
IGNvbXBhcmVzLgoKDQoFBAoCAgYSBN0CAhsKDQoFBAoCAgESBN0CHCgKDQoFBAoCAgMSBN0C
KyxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::CreateVersionOperationMetadata ===
    # Fields for CreateVersionOperationMetadata
    # Field: version Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::Version ===
    # Fields for Version
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: nlu_settings Type: 11 (.google.cloud.dialogflow.cx.v3.NluSettings)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.dialogflow.cx.v3.Version.State)

# Enum: Version::State
our $Version_STATE_UNSPECIFIED = 0;
our $Version_RUNNING = 1;
our $Version_SUCCEEDED = 2;
our $Version_FAILED = 3;

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsRequest ===
    # Fields for ListVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsResponse ===
    # Fields for ListVersionsResponse
    # Field: versions Type: 11 (.google.cloud.dialogflow.cx.v3.Version)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::GetVersionRequest ===
    # Fields for GetVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::CreateVersionRequest ===
    # Fields for CreateVersionRequest
    # Field: parent Type: 9 ()
    # Field: version Type: 11 (.google.cloud.dialogflow.cx.v3.Version)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::UpdateVersionRequest ===
    # Fields for UpdateVersionRequest
    # Field: version Type: 11 (.google.cloud.dialogflow.cx.v3.Version)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::DeleteVersionRequest ===
    # Fields for DeleteVersionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::LoadVersionRequest ===
    # Fields for LoadVersionRequest
    # Field: name Type: 9 ()
    # Field: allow_override_agent_resources Type: 8 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::CompareVersionsRequest ===
    # Fields for CompareVersionsRequest
    # Field: base_version Type: 9 ()
    # Field: target_version Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Version::CompareVersionsResponse ===
    # Fields for CompareVersionsResponse
    # Field: base_version_content_json Type: 9 ()
    # Field: target_version_content_json Type: 9 ()
    # Field: compare_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Dialogflow::Cx::V3::Version::VersionsClient ===
package Google::Cloud::Dialogflow::Cx::V3::Version::VersionsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3::Version::VersionsClient

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
        ? Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Versions',
        method         => 'ListVersions',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsResponse',
    });
}

sub get_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Version::GetVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Versions',
        method         => 'GetVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Version::Version',
    });
}

sub create_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Version::CreateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Versions',
        method         => 'CreateVersion',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Version::UpdateVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Versions',
        method         => 'UpdateVersion',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Version::Version',
    });
}

sub delete_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Version::DeleteVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Versions',
        method         => 'DeleteVersion',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub load_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Version::LoadVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Versions',
        method         => 'LoadVersion',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub compare_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Version::CompareVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Versions',
        method         => 'CompareVersions',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Version::CompareVersionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Version - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/version.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Version;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Version::CreateVersionOperationMetadata->new({
        version => $version,
    });

    # Read or update a field
    my $val = $msg->version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Version::CreateVersionOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::CreateVersionOperationMetadata

Metadata associated with the long running operation for
[Versions.CreateVersion][google.cloud.dialogflow.cx.v3.Versions.CreateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Name of the created version.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::Version

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

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Flow::NluSettings>)

Output only. The NLU settings of the flow at version creation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time of the version.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::Version::State>)

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

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsRequest

The request message for
[Versions.ListVersions][google.cloud.dialogflow.cx.v3.Versions.ListVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The [Flow][google.cloud.dialogflow.cx.v3.Flow] to list all
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

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::ListVersionsResponse

The response message for
[Versions.ListVersions][google.cloud.dialogflow.cx.v3.Versions.ListVersions].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->versions() >> / C<< $msg->versions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Version::Version>)

A list of versions. There will be a maximum number of items returned based
on the page_size field in the request. The list may in some cases be empty
or contain fewer entries than page_size even if this isn't the last page.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::GetVersionRequest

The request message for
[Versions.GetVersion][google.cloud.dialogflow.cx.v3.Versions.GetVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the [Version][google.cloud.dialogflow.cx.v3.Version].
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::CreateVersionRequest

The request message for
[Versions.CreateVersion][google.cloud.dialogflow.cx.v3.Versions.CreateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The [Flow][google.cloud.dialogflow.cx.v3.Flow] to create an
[Version][google.cloud.dialogflow.cx.v3.Version] for. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>`.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Version::Version>)

Required. The version to create.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::UpdateVersionRequest

The request message for
[Versions.UpdateVersion][google.cloud.dialogflow.cx.v3.Versions.UpdateVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Version::Version>)

Required. The version to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated. Currently only
`description` and `display_name` can be updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::DeleteVersionRequest

The request message for
[Versions.DeleteVersion][google.cloud.dialogflow.cx.v3.Versions.DeleteVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the [Version][google.cloud.dialogflow.cx.v3.Version]
to delete. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::LoadVersionRequest

The request message for
[Versions.LoadVersion][google.cloud.dialogflow.cx.v3.Versions.LoadVersion].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The [Version][google.cloud.dialogflow.cx.v3.Version] to be loaded
to draft flow. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VersionID>`.

=item * C<< $msg->allow_override_agent_resources() >> / C<< $msg->allow_override_agent_resources($value) >>

Type: C<Bool>

This field is used to prevent accidental overwrite of other agent
resources, which can potentially impact other flow's behavior. If
`allow_override_agent_resources` is false, conflicted agent-level resources
will not be overridden (i.e. intents, entities, webhooks).

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::CompareVersionsRequest

The request message for
[Versions.CompareVersions][google.cloud.dialogflow.cx.v3.Versions.CompareVersions].

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

=head2 Google::Cloud::Dialogflow::Cx::V3::Version::CompareVersionsResponse

The response message for
[Versions.CompareVersions][google.cloud.dialogflow.cx.v3.Versions.CompareVersions].

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Version::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
