package Google::Cloud::Dialogflow::Cx::V3::Example;

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
    eval { require Google::Cloud::Dialogflow::Cx::V3::Trace };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9leGFtcGxlLnByb3RvEh1nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKWdvb2dsZS9jbG91ZC9kaWFsb2dmbG93
L2N4L3YzL3RyYWNlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2ds
ZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1w
LnByb3RvIqABChRDcmVhdGVFeGFtcGxlUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpB
IxIhZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9FeGFtcGxlUgZwYXJlbnQSRQoHZXhhbXBs
ZRgCIAEoCzImLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkV4YW1wbGVCA+BBAlIH
ZXhhbXBsZSJVChREZWxldGVFeGFtcGxlUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMK
IWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRXhhbXBsZVIEbmFtZSLIAQoTTGlzdEV4YW1w
bGVzUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIxIhZGlhbG9nZmxvdy5nb29nbGVh
cGlzLmNvbS9FeGFtcGxlUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VT
aXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEigKDWxhbmd1YWdlX2Nv
ZGUYBCABKAlCA+BBAVIMbGFuZ3VhZ2VDb2RlIoIBChRMaXN0RXhhbXBsZXNSZXNwb25zZRJC
CghleGFtcGxlcxgBIAMoCzImLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkV4YW1w
bGVSCGV4YW1wbGVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJS
ChFHZXRFeGFtcGxlUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWRpYWxvZ2Zsb3cu
Z29vZ2xlYXBpcy5jb20vRXhhbXBsZVIEbmFtZSKfAQoUVXBkYXRlRXhhbXBsZVJlcXVlc3QS
RQoHZXhhbXBsZRgBIAEoCzImLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkV4YW1w
bGVCA+BBAlIHZXhhbXBsZRJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayK6BgoHRXhhbXBsZRISCgRuYW1lGAEgASgJ
UgRuYW1lElgKDnBsYXlib29rX2lucHV0GAMgASgLMiwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cuY3gudjMuUGxheWJvb2tJbnB1dEID4EEBUg1wbGF5Ym9va0lucHV0ElsKD3BsYXlib29r
X291dHB1dBgEIAEoCzItLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlBsYXlib29r
T3V0cHV0QgPgQQFSDnBsYXlib29rT3V0cHV0EkQKB2FjdGlvbnMYAiADKAsyJS5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52My5BY3Rpb25CA+BBAlIHYWN0aW9ucxImCgxkaXNwbGF5
X25hbWUYBiABKAlCA+BBAlILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YCCABKAlCA+BB
AVILZGVzY3JpcHRpb24SJAoLdG9rZW5fY291bnQYCSABKANCA+BBA1IKdG9rZW5Db3VudBJA
CgtjcmVhdGVfdGltZRgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
Y3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgLIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKdXBkYXRlVGltZRJeChJjb252ZXJzYXRpb25fc3RhdGUYDCABKA4yKi5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5PdXRwdXRTdGF0ZUID4EECUhFjb252ZXJz
YXRpb25TdGF0ZRIoCg1sYW5ndWFnZV9jb2RlGA0gASgJQgPgQQFSDGxhbmd1YWdlQ29kZTqa
AepBlgEKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRXhhbXBsZRJecHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50cy97YWdlbnR9L3BsYXlib29rcy97
cGxheWJvb2t9L2V4YW1wbGVzL3tleGFtcGxlfSoIZXhhbXBsZXMyB2V4YW1wbGUy8wgKCEV4
YW1wbGVzEtEBCg1DcmVhdGVFeGFtcGxlEjMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djMuQ3JlYXRlRXhhbXBsZVJlcXVlc3QaJi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
My5FeGFtcGxlImOC0+STAkwiQS92My97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyov
YWdlbnRzLyovcGxheWJvb2tzLyp9L2V4YW1wbGVzOgdleGFtcGxl2kEOcGFyZW50LGV4YW1w
bGUSrgEKDURlbGV0ZUV4YW1wbGUSMy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5E
ZWxldGVFeGFtcGxlUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJQgtPkkwJDKkEv
djMve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9wbGF5Ym9va3MvKi9l
eGFtcGxlcy8qfdpBBG5hbWUSywEKDExpc3RFeGFtcGxlcxIyLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzLkxpc3RFeGFtcGxlc1JlcXVlc3QaMy5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52My5MaXN0RXhhbXBsZXNSZXNwb25zZSJSgtPkkwJDEkEvdjMve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL3BsYXlib29rcy8qfS9leGFtcGxlc9pB
BnBhcmVudBK4AQoKR2V0RXhhbXBsZRIwLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
LkdldEV4YW1wbGVSZXF1ZXN0GiYuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRXhh
bXBsZSJQgtPkkwJDEkEvdjMve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMv
Ki9wbGF5Ym9va3MvKi9leGFtcGxlcy8qfdpBBG5hbWUS3gEKDVVwZGF0ZUV4YW1wbGUSMy5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5VcGRhdGVFeGFtcGxlUmVxdWVzdBomLmdv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkV4YW1wbGUicILT5JMCVDJJL3YzL3tleGFt
cGxlLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudHMvKi9wbGF5Ym9va3MvKi9l
eGFtcGxlcy8qfToHZXhhbXBsZdpBE2V4YW1wbGUsdXBkYXRlX21hc2saeMpBGWRpYWxvZ2Zs
b3cuZ29vZ2xlYXBpcy5jb23SQVlodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Ns
b3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlhbG9nZmxv
d0KvAQohY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzQgxFeGFtcGxlUHJvdG9Q
AVoxY2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dmbG93L2N4L2FwaXYzL2N4cGI7Y3hwYqIC
AkRGqgIdR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuQ3guVjPqAiFHb29nbGU6OkNsb3VkOjpE
aWFsb2dmbG93OjpDWDo6VjNKzToKBxIFDgDtAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkK
CQoCAwMSAxUAIwoJCgIDBBIDFgAzCgkKAgMFEgMXACUKCQoCAwYSAxgAKgoJCgIDBxIDGQAp
CggKAQgSAxsAOgoJCgIIJRIDGwA6CggKAQgSAxwASAoJCgIICxIDHABICggKAQgSAx0AIgoJ
CgIIChIDHQAiCggKAQgSAx4ALQoJCgIICBIDHgAtCggKAQgSAx8AOgoJCgIIARIDHwA6CggK
AQgSAyAAIAoJCgIIJBIDIAAgCggKAQgSAyEAOgoJCgIILRIDIQA6ClUKAgYAEgQkAFMBGkkg
U2VydmljZSBmb3IgbWFuYWdpbmcgW0V4YW1wbGVzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52My5FeGFtcGxlXS4KCgoKAwYAARIDJAgQCgoKAwYAAxIDJQJBCgwKBQYAA5kIEgMl
AkEKCwoDBgADEgQmAigzCg0KBQYAA5oIEgQmAigzCj0KBAYAAgASBCsCMQMaLyBDcmVhdGVz
IGFuIGV4YW1wbGUgaW4gdGhlIHNwZWNpZmllZCBwbGF5Ym9vay4KCgwKBQYAAgABEgMrBhMK
DAoFBgACAAISAysUKAoMCgUGAAIAAxIDKzM6Cg0KBQYAAgAEEgQsBC8GChEKCQYAAgAEsMq8
IhIELAQvBgoMCgUGAAIABBIDMAQ8Cg8KCAYAAgAEmwgAEgMwBDwKLgoEBgACARIENAI5Axog
IERlbGV0ZXMgdGhlIHNwZWNpZmllZCBleGFtcGxlLgoKDAoFBgACAQESAzQGEwoMCgUGAAIB
AhIDNBQoCgwKBQYAAgEDEgM0M0gKDQoFBgACAQQSBDUENwYKEQoJBgACAQSwyrwiEgQ1BDcG
CgwKBQYAAgEEEgM4BDIKDwoIBgACAQSbCAASAzgEMgpFCgQGAAICEgQ8AkEDGjcgUmV0dXJu
cyBhIGxpc3Qgb2YgZXhhbXBsZXMgaW4gdGhlIHNwZWNpZmllZCBwbGF5Ym9vay4KCgwKBQYA
AgIBEgM8BhIKDAoFBgACAgISAzwTJgoMCgUGAAICAxIDPDFFCg0KBQYAAgIEEgQ9BD8GChEK
CQYAAgIEsMq8IhIEPQQ/BgoMCgUGAAICBBIDQAQ0Cg8KCAYAAgIEmwgAEgNABDQKMAoEBgAC
AxIERAJJAxoiIFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkIGV4YW1wbGUuCgoMCgUGAAIDARID
RAYQCgwKBQYAAgMCEgNEESIKDAoFBgACAwMSA0QtNAoNCgUGAAIDBBIERQRHBgoRCgkGAAID
BLDKvCISBEUERwYKDAoFBgACAwQSA0gEMgoPCggGAAIDBJsIABIDSAQyCi0KBAYAAgQSBEwC
UgMaHyBVcGRhdGUgdGhlIHNwZWNpZmllZCBleGFtcGxlLgoKDAoFBgACBAESA0wGEwoMCgUG
AAIEAhIDTBQoCgwKBQYAAgQDEgNMMzoKDQoFBgACBAQSBE0EUAYKEQoJBgACBASwyrwiEgRN
BFAGCgwKBQYAAgQEEgNRBEEKDwoIBgACBASbCAASA1EEQQp2CgIEABIEVwBkARpqIFRoZSBy
ZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRXhhbXBsZXMuQ3JlYXRlRXhhbXBsZV1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjMuRXhhbXBsZXMuQ3JlYXRlRXhhbXBsZV0uCgoKCgMEAAES
A1cIHAqiAQoEBAACABIEWwJgBBqTASBSZXF1aXJlZC4gVGhlIHBsYXlib29rIHRvIGNyZWF0
ZSBhbiBleGFtcGxlIGZvci4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2Nh
dGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vcGxheWJvb2tzLzxQbGF5Ym9v
a0lEPmAuCgoMCgUEAAIABRIDWwIICgwKBQQAAgABEgNbCQ8KDAoFBAACAAMSA1sSEwoNCgUE
AAIACBIEWxRgAwoPCggEAAIACJwIABIDXAQqCg8KBwQAAgAInwgSBF0EXwUKLwoEBAACARID
YwI/GiIgUmVxdWlyZWQuIFRoZSBleGFtcGxlIHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgNjAgkK
DAoFBAACAQESA2MKEQoMCgUEAAIBAxIDYxQVCgwKBQQAAgEIEgNjFj4KDwoIBAACAQicCAAS
A2MXPQp2CgIEARIEaAByARpqIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRXhhbXBsZXMu
RGVsZXRlRXhhbXBsZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRXhhbXBsZXMu
RGVsZXRlRXhhbXBsZV0uCgoKCgMEAQESA2gIHAqzAQoEBAECABIEbAJxBBqkASBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIGV4YW1wbGUgdG8gZGVsZXRlLgogRm9ybWF0OgogYHByb2pl
Y3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElE
Pi9wbGF5Ym9va3MvPFBsYXlib29rSUQ+L2V4YW1wbGVzLzxFeGFtcGxlSUQ+YC4KCgwKBQQB
AgAFEgNsAggKDAoFBAECAAESA2wJDQoMCgUEAQIAAxIDbBARCg0KBQQBAgAIEgRsEnEDCg8K
CAQBAgAInAgAEgNtBCoKDwoHBAECAAifCBIEbgRwBQp1CgIEAhIFdgCNAQEaaCBUaGUgcmVx
dWVzdCBtZXNzYWdlIGZvcgogW0V4YW1wbGVzLkxpc3RFeGFtcGxlc11bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cuY3gudjMuRXhhbXBsZXMuTGlzdEV4YW1wbGVzXS4KCgoKAwQCARIDdggb
CqMBCgQEAgIAEgR6An8EGpQBIFJlcXVpcmVkLiBUaGUgcGxheWJvb2sgdG8gbGlzdCB0aGUg
ZXhhbXBsZXMgZnJvbS4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlv
bnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vcGxheWJvb2tzLzxQbGF5Ym9va0lE
PmAuCgoMCgUEAgIABRIDegIICgwKBQQCAgABEgN6CQ8KDAoFBAICAAMSA3oSEwoNCgUEAgIA
CBIEehR/AwoPCggEAgIACJwIABIDewQqCg8KBwQCAgAInwgSBHwEfgUKcwoEBAICARIEgwEC
PxplIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdG8gcmV0dXJuIGlu
IGEgc2luZ2xlIHBhZ2UuIEJ5CiBkZWZhdWx0IDEwMCBhbmQgYXQgbW9zdCAxMDAwLgoKDQoF
BAICAQUSBIMBAgcKDQoFBAICAQESBIMBCBEKDQoFBAICAQMSBIMBFBUKDQoFBAICAQgSBIMB
Fj4KEAoIBAICAQicCAASBIMBFz0KggEKBAQCAgISBIcBAkEadCBPcHRpb25hbC4gVGhlIFtu
ZXh0X3BhZ2VfdG9rZW5dW0xpc3RFeGFtcGxlUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXSB2
YWx1ZQogcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGxpc3QgcmVxdWVzdC4KCg0KBQQCAgIF
EgSHAQIICg0KBQQCAgIBEgSHAQkTCg0KBQQCAgIDEgSHARYXCg0KBQQCAgIIEgSHARhAChAK
CAQCAgIInAgAEgSHARk/Cr0BCgQEAgIDEgSMAQJEGq4BIE9wdGlvbmFsLiBUaGUgbGFuZ3Vh
Z2UgdG8gbGlzdCBleGFtcGxlcyBmb3IuCiBJZiBub3Qgc3BlY2lmaWVkLCBsaXN0IGFsbCBl
eGFtcGxlcyB1bmRlciB0aGUgcGxheWJvb2suCiBOb3RlOiBsYW5ndWFnZXMgbXVzdCBiZSBl
bmFibGVkIGluIHRoZSBhZ2VudCBiZWZvcmUgdGhleSBjYW4gYmUgdXNlZC4KCg0KBQQCAgMF
EgSMAQIICg0KBQQCAgMBEgSMAQkWCg0KBQQCAgMDEgSMARkaCg0KBQQCAgMIEgSMARtDChAK
CAQCAgMInAgAEgSMARxCCncKAgQDEgaRAQCbAQEaaSBUaGUgcmVzcG9uc2UgbWVzc2FnZSBm
b3IKIFtFeGFtcGxlcy5MaXN0RXhhbXBsZXNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzLkV4YW1wbGVzLkxpc3RFeGFtcGxlc10uCgoLCgMEAwESBJEBCBwKxgEKBAQDAgASBJYB
AiAatwEgVGhlIGxpc3Qgb2YgZXhhbXBsZXMuIFRoZXJlIHdpbGwgYmUgYSBtYXhpbXVtIG51
bWJlciBvZiBpdGVtcyByZXR1cm5lZAogYmFzZWQgb24gdGhlCiBbcGFnZV9zaXplXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5MaXN0RXhhbXBsZXNSZXF1ZXN0LnBhZ2Vfc2l6
ZV0KIGZpZWxkIGluIHRoZSByZXF1ZXN0LgoKDQoFBAMCAAQSBJYBAgoKDQoFBAMCAAYSBJYB
CxIKDQoFBAMCAAESBJYBExsKDQoFBAMCAAMSBJYBHh8KbwoEBAMCARIEmgECHRphIFRva2Vu
IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhl
cmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAwIBBRIEmgECCAoN
CgUEAwIBARIEmgEJGAoNCgUEAwIBAxIEmgEbHApyCgIEBBIGnwEAqQEBGmQgVGhlIHJlcXVl
c3QgbWVzc2FnZSBmb3IKIFtFeGFtcGxlcy5HZXRFeGFtcGxlXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52My5FeGFtcGxlcy5HZXRFeGFtcGxlXS4KCgsKAwQEARIEnwEIGQqrAQoE
BAQCABIGowECqAEEGpoBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgZXhhbXBsZS4KIEZv
cm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2Fn
ZW50cy88QWdlbnRJRD4vcGxheWJvb2tzLzxQbGF5Ym9va0lEPi9leGFtcGxlcy88RXhhbXBs
ZUlEPmAuCgoNCgUEBAIABRIEowECCAoNCgUEBAIAARIEowEJDQoNCgUEBAIAAxIEowEQEQoP
CgUEBAIACBIGowESqAEDChAKCAQEAgAInAgAEgSkAQQqChEKBwQEAgAInwgSBqUBBKcBBQp4
CgIEBRIGrQEAtQEBGmogVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtFeGFtcGxlcy5VcGRh
dGVFeGFtcGxlXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5FeGFtcGxlcy5VcGRh
dGVFeGFtcGxlXS4KCgsKAwQFARIErQEIHAowCgQEBQIAEgSvAQI/GiIgUmVxdWlyZWQuIFRo
ZSBleGFtcGxlIHRvIHVwZGF0ZS4KCg0KBQQFAgAGEgSvAQIJCg0KBQQFAgABEgSvAQoRCg0K
BQQFAgADEgSvARQVCg0KBQQFAgAIEgSvARY+ChAKCAQFAgAInAgAEgSvARc9CoIBCgQEBQIB
EgazAQK0AS8aciBPcHRpb25hbC4gVGhlIG1hc2sgdG8gY29udHJvbCB3aGljaCBmaWVsZHMg
Z2V0IHVwZGF0ZWQuIElmIHRoZSBtYXNrIGlzIG5vdAogcHJlc2VudCwgYWxsIGZpZWxkcyB3
aWxsIGJlIHVwZGF0ZWQuCgoNCgUEBQIBBhIEswECGwoNCgUEBQIBARIEswEcJwoNCgUEBQIB
AxIEswEqKwoNCgUEBQIBCBIEtAEGLgoQCggEBQIBCJwIABIEtAEHLQryAQoCBAYSBrsBAO0B
ARrjASBFeGFtcGxlIHJlcHJlc2VudHMgYSBzYW1wbGUgZXhlY3V0aW9uIG9mIHRoZSBwbGF5
Ym9vayBpbiB0aGUgY29udmVyc2F0aW9uLgoKIEFuIGV4YW1wbGUgY29uc2lzdHMgb2YgYSBs
aXN0IG9mIG9yZGVyZWQgYWN0aW9ucyBwZXJmb3JtZWQgYnkgZW5kIHVzZXIKIG9yIERpYWxv
Z2Zsb3cgYWdlbnQgYWNjb3JkaW5nIHRoZSBwbGF5Ym9vayBpbnN0cnVjdGlvbnMgdG8gZnVs
ZmlsbCB0aGUgdGFzay4KCgsKAwQGARIEuwEIDwoNCgMEBgcSBrwBAsEBBAoPCgUEBgedCBIG
vAECwQEECrUBCgQEBgIAEgTGAQISGqYBIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUg
cGxheWJvb2sgZXhhbXBsZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2Nh
dGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vcGxheWJvb2tzLzxQbGF5Ym9v
a0lEPi9leGFtcGxlcy88RXhhbXBsZUlEPmAuCgoNCgUEBgIABRIExgECCAoNCgUEBgIAARIE
xgEJDQoNCgUEBgIAAxIExgEQEQpDCgQEBgIBEgTJAQJMGjUgT3B0aW9uYWwuIFRoZSBpbnB1
dCB0byB0aGUgcGxheWJvb2sgaW4gdGhlIGV4YW1wbGUuCgoNCgUEBgIBBhIEyQECDwoNCgUE
BgIBARIEyQEQHgoNCgUEBgIBAxIEyQEhIgoNCgUEBgIBCBIEyQEjSwoQCggEBgIBCJwIABIE
yQEkSgpECgQEBgICEgTMAQJOGjYgT3B0aW9uYWwuIFRoZSBvdXRwdXQgb2YgdGhlIHBsYXli
b29rIGluIHRoZSBleGFtcGxlLgoKDQoFBAYCAgYSBMwBAhAKDQoFBAYCAgESBMwBESAKDQoF
BAYCAgMSBMwBIyQKDQoFBAYCAggSBMwBJU0KEAoIBAYCAgicCAASBMwBJkwKagoEBAYCAxIE
0AECRxpcIFJlcXVpcmVkLiBUaGUgb3JkZXJlZCBsaXN0IG9mIGFjdGlvbnMgcGVyZm9ybWVk
IGJ5IHRoZSBlbmQgdXNlciBhbmQgdGhlCiBEaWFsb2dmbG93IGFnZW50LgoKDQoFBAYCAwQS
BNABAgoKDQoFBAYCAwYSBNABCxEKDQoFBAYCAwESBNABEhkKDQoFBAYCAwMSBNABHB0KDQoF
BAYCAwgSBNABHkYKEAoIBAYCAwicCAASBNABH0UKOgoEBAYCBBIE0wECQxosIFJlcXVpcmVk
LiBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSBleGFtcGxlLgoKDQoFBAYCBAUSBNMBAggKDQoF
BAYCBAESBNMBCRUKDQoFBAYCBAMSBNMBGBkKDQoFBAYCBAgSBNMBGkIKEAoIBAYCBAicCAAS
BNMBG0EKcgoEBAYCBRIE1wECQhpkIE9wdGlvbmFsLiBUaGUgaGlnaCBsZXZlbCBjb25jaXNl
IGRlc2NyaXB0aW9uIG9mIHRoZSBleGFtcGxlLiBUaGUgbWF4IG51bWJlcgogb2YgY2hhcmFj
dGVycyBpcyAyMDAuCgoNCgUEBgIFBRIE1wECCAoNCgUEBgIFARIE1wEJFAoNCgUEBgIFAxIE
1wEXGAoNCgUEBgIFCBIE1wEZQQoQCggEBgIFCJwIABIE1wEaQApjCgQEBgIGEgTbAQJEGlUg
T3V0cHV0IG9ubHkuIEVzdGltYXRlZCBudW1iZXIgb2YgdG9rZXMgY3VycmVudCBleGFtcGxl
IHRha2VzIHdoZW4gc2VudCB0bwogdGhlIExMTS4KCg0KBQQGAgYFEgTbAQIHCg0KBQQGAgYB
EgTbAQgTCg0KBQQGAgYDEgTbARYXCg0KBQQGAgYIEgTbARhDChAKCAQGAgYInAgAEgTbARlC
CkkKBAQGAgcSBt4BAt8BMho5IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIG9mIGluaXRp
YWwgZXhhbXBsZSBjcmVhdGlvbi4KCg0KBQQGAgcGEgTeAQIbCg0KBQQGAgcBEgTeARwnCg0K
BQQGAgcDEgTeASosCg0KBQQGAgcIEgTfAQYxChAKCAQGAgcInAgAEgTfAQcwCkEKBAQGAggS
BuIBAuMBMhoxIE91dHB1dCBvbmx5LiBMYXN0IHRpbWUgdGhlIGV4YW1wbGUgd2FzIHVwZGF0
ZWQuCgoNCgUEBgIIBhIE4gECGwoNCgUEBgIIARIE4gEcJwoNCgUEBgIIAxIE4gEqLAoNCgUE
BgIICBIE4wEGMQoQCggEBgIICJwIABIE4wEHMAoxCgQEBgIJEgTmAQJPGiMgUmVxdWlyZWQu
IEV4YW1wbGUncyBvdXRwdXQgc3RhdGUuCgoNCgUEBgIJBhIE5gECDQoNCgUEBgIJARIE5gEO
IAoNCgUEBgIJAxIE5gEjJQoNCgUEBgIJCBIE5gEmTgoQCggEBgIJCJwIABIE5gEnTQqHAgoE
BAYCChIE7AECRRr4ASBPcHRpb25hbC4gVGhlIGxhbmd1YWdlIGNvZGUgb2YgdGhlIGV4YW1w
bGUuCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgYWdlbnQncyBkZWZhdWx0IGxhbmd1YWdlIGlz
IHVzZWQuCiBOb3RlOiBsYW5ndWFnZXMgbXVzdCBiZSBlbmFibGVkIGluIHRoZSBhZ2VudCBi
ZWZvcmUgdGhleSBjYW4gYmUgdXNlZC4KIE5vdGU6IGV4YW1wbGUncyBsYW5ndWFnZSBjb2Rl
IGlzIG5vdCBjdXJyZW50bHkgdXNlZCBpbiBkaWFsb2dmbG93IGFnZW50cy4KCg0KBQQGAgoF
EgTsAQIICg0KBQQGAgoBEgTsAQkWCg0KBQQGAgoDEgTsARkbCg0KBQQGAgoIEgTsARxEChAK
CAQGAgoInAgAEgTsAR1DYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Example::CreateExampleRequest ===
    # Fields for CreateExampleRequest
    # Field: parent Type: 9 ()
    # Field: example Type: 11 (.google.cloud.dialogflow.cx.v3.Example)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Example::DeleteExampleRequest ===
    # Fields for DeleteExampleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Example::ListExamplesRequest ===
    # Fields for ListExamplesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Example::ListExamplesResponse ===
    # Fields for ListExamplesResponse
    # Field: examples Type: 11 (.google.cloud.dialogflow.cx.v3.Example)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Example::GetExampleRequest ===
    # Fields for GetExampleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Example::UpdateExampleRequest ===
    # Fields for UpdateExampleRequest
    # Field: example Type: 11 (.google.cloud.dialogflow.cx.v3.Example)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Example::Example ===
    # Fields for Example
    # Field: name Type: 9 ()
    # Field: playbook_input Type: 11 (.google.cloud.dialogflow.cx.v3.PlaybookInput)
    # Field: playbook_output Type: 11 (.google.cloud.dialogflow.cx.v3.PlaybookOutput)
    # Field: actions Type: 11 (.google.cloud.dialogflow.cx.v3.Action)
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: token_count Type: 3 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: conversation_state Type: 14 (.google.cloud.dialogflow.cx.v3.OutputState)
    # Field: language_code Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3::Example::ExamplesClient ===
package Google::Cloud::Dialogflow::Cx::V3::Example::ExamplesClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3::Example::ExamplesClient

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
        ? Google::Cloud::Dialogflow::Cx::V3::Example::CreateExampleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Examples',
        method         => 'CreateExample',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Example::Example',
    });
}

sub delete_example {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Example::DeleteExampleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Examples',
        method         => 'DeleteExample',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_examples {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Example::ListExamplesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Examples',
        method         => 'ListExamples',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Example::ListExamplesResponse',
    });
}

sub get_example {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Example::GetExampleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Examples',
        method         => 'GetExample',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Example::Example',
    });
}

sub update_example {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Example::UpdateExampleRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Examples',
        method         => 'UpdateExample',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Example::Example',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Example - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/example.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Example;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Example::CreateExampleRequest->new({
        parent => $parent,
        example => $example,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Example::CreateExampleRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/example.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Example::CreateExampleRequest

The request message for
[Examples.CreateExample][google.cloud.dialogflow.cx.v3.Examples.CreateExample].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The playbook to create an example for.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>`.

=item * C<< $msg->example() >> / C<< $msg->example($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Example::Example>)

Required. The example to create.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Example::DeleteExampleRequest

The request message for
[Examples.DeleteExample][google.cloud.dialogflow.cx.v3.Examples.DeleteExample].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the example to delete.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>/examples/<ExampleID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Example::ListExamplesRequest

The request message for
[Examples.ListExamples][google.cloud.dialogflow.cx.v3.Examples.ListExamples].

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

=head2 Google::Cloud::Dialogflow::Cx::V3::Example::ListExamplesResponse

The response message for
[Examples.ListExamples][google.cloud.dialogflow.cx.v3.Examples.ListExamples].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Example::Example>)

The list of examples. There will be a maximum number of items returned
based on the
[page_size][google.cloud.dialogflow.cx.v3.ListExamplesRequest.page_size]
field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Example::GetExampleRequest

The request message for
[Examples.GetExample][google.cloud.dialogflow.cx.v3.Examples.GetExample].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the example.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>/examples/<ExampleID>`.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Example::UpdateExampleRequest

The request message for
[Examples.UpdateExample][google.cloud.dialogflow.cx.v3.Examples.UpdateExample].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->example() >> / C<< $msg->example($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Example::Example>)

Required. The example to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated. If the mask is not
present, all fields will be updated.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Example::Example

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

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInput>)

Optional. The input to the playbook in the example.

=item * C<< $msg->playbook_output() >> / C<< $msg->playbook_output($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookOutput>)

Optional. The output of the playbook in the example.

=item * C<< $msg->actions() >> / C<< $msg->actions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::Action>)

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

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::OutputState>)

Required. Example's output state.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Optional. The language code of the example.
If not specified, the agent's default language is used.
Note: languages must be enabled in the agent before they can be used.
Note: example's language code is not currently used in dialogflow agents.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Example::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
