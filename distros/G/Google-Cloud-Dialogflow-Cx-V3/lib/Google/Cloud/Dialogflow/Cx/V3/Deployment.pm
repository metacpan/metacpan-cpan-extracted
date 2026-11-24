package Google::Cloud::Dialogflow::Cx::V3::Deployment;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9kZXBsb3ltZW50LnByb3RvEh1nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8ijAYKCkRlcGxveW1lbnQSEgoEbmFtZRgBIAEoCVIEbmFtZRJJCgxmbG93
X3ZlcnNpb24YAiABKAlCJvpBIwohZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9WZXJzaW9u
UgtmbG93VmVyc2lvbhJFCgVzdGF0ZRgDIAEoDjIvLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzLkRlcGxveW1lbnQuU3RhdGVSBXN0YXRlEkgKBnJlc3VsdBgEIAEoCzIwLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkRlcGxveW1lbnQuUmVzdWx0UgZyZXN1bHQSOQoK
c3RhcnRfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGlt
ZRI1CghlbmRfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRp
bWUaugEKBlJlc3VsdBJlChdkZXBsb3ltZW50X3Rlc3RfcmVzdWx0cxgBIAMoCUIt+kEqCihk
aWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Rlc3RDYXNlUmVzdWx0UhVkZXBsb3ltZW50VGVz
dFJlc3VsdHMSSQoKZXhwZXJpbWVudBgCIAEoCUIp+kEmCiRkaWFsb2dmbG93Lmdvb2dsZWFw
aXMuY29tL0V4cGVyaW1lbnRSCmV4cGVyaW1lbnQiRgoFU3RhdGUSFQoRU1RBVEVfVU5TUEVD
SUZJRUQQABILCgdSVU5OSU5HEAESDQoJU1VDQ0VFREVEEAISCgoGRkFJTEVEEAM6lgHqQZIB
CiRkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0RlcGxveW1lbnQSanByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hZ2VudHMve2FnZW50fS9lbnZpcm9ubWVudHMv
e2Vudmlyb25tZW50fS9kZXBsb3ltZW50cy97ZGVwbG95bWVudH0imgEKFkxpc3REZXBsb3lt
ZW50c1JlcXVlc3QSRAoGcGFyZW50GAEgASgJQizgQQL6QSYSJGRpYWxvZ2Zsb3cuZ29vZ2xl
YXBpcy5jb20vRGVwbG95bWVudFIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNp
emUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIo4BChdMaXN0RGVwbG95bWVudHNS
ZXNwb25zZRJLCgtkZXBsb3ltZW50cxgBIAMoCzIpLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzLkRlcGxveW1lbnRSC2RlcGxveW1lbnRzEiYKD25leHRfcGFnZV90b2tlbhgCIAEo
CVINbmV4dFBhZ2VUb2tlbiJYChRHZXREZXBsb3ltZW50UmVxdWVzdBJACgRuYW1lGAEgASgJ
QizgQQL6QSYKJGRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRGVwbG95bWVudFIEbmFtZTKu
BAoLRGVwbG95bWVudHMS2gEKD0xpc3REZXBsb3ltZW50cxI1Lmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzLkxpc3REZXBsb3ltZW50c1JlcXVlc3QaNi5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52My5MaXN0RGVwbG95bWVudHNSZXNwb25zZSJYgtPkkwJJEkcvdjMve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50cy8qL2Vudmlyb25tZW50cy8qfS9k
ZXBsb3ltZW50c9pBBnBhcmVudBLHAQoNR2V0RGVwbG95bWVudBIzLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzLkdldERlcGxveW1lbnRSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjMuRGVwbG95bWVudCJWgtPkkwJJEkcvdjMve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9hZ2VudHMvKi9lbnZpcm9ubWVudHMvKi9kZXBsb3ltZW50cy8qfdpB
BG5hbWUaeMpBGWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb23SQVlodHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlhbG9nZmxvd0KyAQohY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4
LnYzQg9EZXBsb3ltZW50UHJvdG9QAVoxY2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFsb2dmbG93
L2N4L2FwaXYzL2N4cGI7Y3hwYqICAkRGqgIdR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuQ3gu
VjPqAiFHb29nbGU6OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjNK6ykKBxIFDgCuAQEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAJgoJ
CgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgApCggKAQgSAxgAOgoJ
CgIIJRIDGAA6CggKAQgSAxkASAoJCgIICxIDGQBICggKAQgSAxoAIgoJCgIIChIDGgAiCggK
AQgSAxsAMAoJCgIICBIDGwAwCggKAQgSAxwAOgoJCgIIARIDHAA6CggKAQgSAx0AIAoJCgII
JBIDHQAgCggKAQgSAx4AOgoJCgIILRIDHgA6ClsKAgYAEgQhADkBGk8gU2VydmljZSBmb3Ig
bWFuYWdpbmcgW0RlcGxveW1lbnRzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5E
ZXBsb3ltZW50XS4KCgoKAwYAARIDIQgTCgoKAwYAAxIDIgJBCgwKBQYAA5kIEgMiAkEKCwoD
BgADEgQjAiUzCg0KBQYAA5oIEgQjAiUzCn8KBAYAAgASBCkCLwMacSBSZXR1cm5zIHRoZSBs
aXN0IG9mIGFsbCBkZXBsb3ltZW50cyBpbiB0aGUgc3BlY2lmaWVkCiBbRW52aXJvbm1lbnRd
W2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkVudmlyb25tZW50XS4KCgwKBQYAAgAB
EgMpBhUKDAoFBgACAAISAykWLAoMCgUGAAIAAxIDKg8mCg0KBQYAAgAEEgQrBC0GChEKCQYA
AgAEsMq8IhIEKwQtBgoMCgUGAAIABBIDLgQ0Cg8KCAYAAgAEmwgAEgMuBDQKYAoEBgACARIE
MwI4AxpSIFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkCiBbRGVwbG95bWVudF1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjMuRGVwbG95bWVudF0uCgoMCgUGAAIBARIDMwYTCgwKBQYA
AgECEgMzFCgKDAoFBgACAQMSAzMzPQoNCgUGAAIBBBIENAQ2BgoRCgkGAAIBBLDKvCISBDQE
NgYKDAoFBgACAQQSAzcEMgoPCggGAAIBBJsIABIDNwQyCoMCCgIEABIEPwB9ARr2ASBSZXBy
ZXNlbnRzIGEgZGVwbG95bWVudCBpbiBhbiBlbnZpcm9ubWVudC4gQSBkZXBsb3ltZW50IGhh
cHBlbnMgd2hlbiBhIGZsb3cKIHZlcnNpb24gY29uZmlndXJlZCB0byBiZSBhY3RpdmUgaW4g
dGhlIGVudmlyb25tZW50LiBZb3UgY2FuIGNvbmZpZ3VyZSBydW5uaW5nCiBwcmUtZGVwbG95
bWVudCBzdGVwcywgZS5nLiBydW5uaW5nIHZhbGlkYXRpb24gdGVzdCBjYXNlcywgZXhwZXJp
bWVudAogYXV0by1yb2xsb3V0LCBldGMuCgoKCgMEAAESAz8IEgoLCgMEAAcSBEACQwQKDQoF
BAAHnQgSBEACQwQKLAoEBAAEABIERgJSAxoeIFRoZSBzdGF0ZSBvZiB0aGUgZGVwbG95bWVu
dC4KCgwKBQQABAABEgNGBwwKIwoGBAAEAAIAEgNIBBoaFCBTdGF0ZSB1bnNwZWNpZmllZC4K
Cg4KBwQABAACAAESA0gEFQoOCgcEAAQAAgACEgNIGBkKKwoGBAAEAAIBEgNLBBAaHCBUaGUg
ZGVwbG95bWVudCBpcyBydW5uaW5nLgoKDgoHBAAEAAIBARIDSwQLCg4KBwQABAACAQISA0sO
DwoqCgYEAAQAAgISA04EEhobIFRoZSBkZXBsb3ltZW50IHN1Y2NlZWRlZC4KCg4KBwQABAAC
AgESA04EDQoOCgcEAAQAAgICEgNOEBEKJwoGBAAEAAIDEgNRBA8aGCBUaGUgZGVwbG95bWVu
dCBmYWlsZWQuCgoOCgcEAAQAAgMBEgNRBAoKDgoHBAAEAAIDAhIDUQ0OCikKBAQAAwASBFUC
ZAMaGyBSZXN1bHQgb2YgdGhlIGRlcGxveW1lbnQuCgoMCgUEAAMAARIDVQoQCsMBCgYEAAMA
AgASBFkEXAsasgEgUmVzdWx0cyBvZiB0ZXN0IGNhc2VzIHJ1bm5pbmcgYmVmb3JlIHRoZSBk
ZXBsb3ltZW50LgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88
TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi90ZXN0Q2FzZXMvPFRlc3RDYXNlSUQ+L3Jl
c3VsdHMvPFRlc3RDYXNlUmVzdWx0SUQ+YC4KCg4KBwQAAwACAAQSA1kEDAoOCgcEAAMAAgAF
EgNZDRMKDgoHBAADAAIAARIDWRQrCg4KBwQAAwACAAMSA1kuLwoPCgcEAAMAAgAIEgRaCFwK
ChEKCQQAAwACAAifCBIEWglcCQrLAQoGBAADAAIBEgRhBGMHGroBIFRoZSBuYW1lIG9mIHRo
ZSBleHBlcmltZW50IHRyaWdnZXJlZCBieSB0aGlzIGRlcGxveW1lbnQuCiBGb3JtYXQ6CiBw
cm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdl
bnRJRD4vZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudElEPi9leHBlcmltZW50cy88RXhwZXJp
bWVudElEPi4KCg4KBwQAAwACAQUSA2EECgoOCgcEAAMAAgEBEgNhCxUKDgoHBAADAAIBAxID
YRgZCg8KBwQAAwACAQgSBGEaYwYKEQoJBAADAAIBCJ8IEgRhG2MFCqsBCgQEAAIAEgNpAhIa
nQEgVGhlIG5hbWUgb2YgdGhlIGRlcGxveW1lbnQuCiBGb3JtYXQ6CiBwcm9qZWN0cy88UHJv
amVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vZW52aXJv
bm1lbnRzLzxFbnZpcm9ubWVudElEPi9kZXBsb3ltZW50cy88RGVwbG95bWVudElEPi4KCgwK
BQQAAgAFEgNpAggKDAoFBAACAAESA2kJDQoMCgUEAAIAAxIDaRARCq0BCgQEAAIBEgRuAnAF
Gp4BIFRoZSBuYW1lIG9mIHRoZSBmbG93IHZlcnNpb24gZm9yIHRoaXMgZGVwbG95bWVudC4K
IEZvcm1hdDoKIHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4v
YWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxvd0lEPi92ZXJzaW9ucy88VmVyaW9uSUQ+LgoK
DAoFBAACAQUSA24CCAoMCgUEAAIBARIDbgkVCgwKBQQAAgEDEgNuGBkKDQoFBAACAQgSBG4a
cAQKDwoHBAACAQifCBIEbhtwAwozCgQEAAICEgNzAhIaJiBUaGUgY3VycmVudCBzdGF0ZSBv
ZiB0aGUgZGVwbG95bWVudC4KCgwKBQQAAgIGEgNzAgcKDAoFBAACAgESA3MIDQoMCgUEAAIC
AxIDcxARCigKBAQAAgMSA3YCFBobIFJlc3VsdCBvZiB0aGUgZGVwbG95bWVudC4KCgwKBQQA
AgMGEgN2AggKDAoFBAACAwESA3YJDwoMCgUEAAIDAxIDdhITCi0KBAQAAgQSA3kCKxogIFN0
YXJ0IHRpbWUgb2YgdGhpcyBkZXBsb3ltZW50LgoKDAoFBAACBAYSA3kCGwoMCgUEAAIEARID
eRwmCgwKBQQAAgQDEgN5KSoKKwoEBAACBRIDfAIpGh4gRW5kIHRpbWUgb2YgdGhpcyBkZXBs
b3ltZW50LgoKDAoFBAACBQYSA3wCGwoMCgUEAAIFARIDfBwkCgwKBQQAAgUDEgN8JygKggEK
AgQBEgaBAQCSAQEadCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0RlcGxveW1lbnRzLkxp
c3REZXBsb3ltZW50c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuRGVwbG95bWVu
dHMuTGlzdERlcGxveW1lbnRzXS4KCgsKAwQBARIEgQEIHgreAQoEBAECABIGhQECigEEGs0B
IFJlcXVpcmVkLiBUaGUgW0Vudmlyb25tZW50XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52My5FbnZpcm9ubWVudF0gdG8KIGxpc3QgYWxsIGVudmlyb25tZW50cyBmb3IuIEZvcm1h
dDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50
cy88QWdlbnRJRD4vZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudElEPmAuCgoNCgUEAQIABRIE
hQECCAoNCgUEAQIAARIEhQEJDwoNCgUEAQIAAxIEhQESEwoPCgUEAQIACBIGhQEUigEDChAK
CAQBAgAInAgAEgSGAQQqChEKBwQBAgAInwgSBocBBIkBBQpnCgQEAQIBEgSOAQIWGlkgVGhl
IG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBC
eSBkZWZhdWx0IDIwIGFuZAogYXQgbW9zdCAxMDAuCgoNCgUEAQIBBRIEjgECBwoNCgUEAQIB
ARIEjgEIEQoNCgUEAQIBAxIEjgEUFQpQCgQEAQICEgSRAQIYGkIgVGhlIG5leHRfcGFnZV90
b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoF
BAECAgUSBJEBAggKDQoFBAECAgESBJEBCRMKDQoFBAECAgMSBJEBFhcKgwEKAgQCEgaWAQCg
AQEadSBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtEZXBsb3ltZW50cy5MaXN0RGVwbG95
bWVudHNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkRlcGxveW1lbnRzLkxpc3RE
ZXBsb3ltZW50c10uCgoLCgMEAgESBJYBCB8K+AEKBAQCAgASBJsBAiYa6QEgVGhlIGxpc3Qg
b2YgZGVwbG95bWVudHMuIFRoZXJlIHdpbGwgYmUgYSBtYXhpbXVtIG51bWJlciBvZiBpdGVt
cwogcmV0dXJuZWQgYmFzZWQgb24gdGhlIHBhZ2Vfc2l6ZSBmaWVsZCBpbiB0aGUgcmVxdWVz
dC4gVGhlIGxpc3QgbWF5IGluIHNvbWUKIGNhc2VzIGJlIGVtcHR5IG9yIGNvbnRhaW4gZmV3
ZXIgZW50cmllcyB0aGFuIHBhZ2Vfc2l6ZSBldmVuIGlmIHRoaXMgaXNuJ3QKIHRoZSBsYXN0
IHBhZ2UuCgoNCgUEAgIABBIEmwECCgoNCgUEAgIABhIEmwELFQoNCgUEAgIAARIEmwEWIQoN
CgUEAgIAAxIEmwEkJQpvCgQEAgIBEgSfAQIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5l
eHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8gbW9yZQogcmVz
dWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQCAgEFEgSfAQIICg0KBQQCAgEBEgSfAQkYCg0KBQQC
AgEDEgSfARscCn4KAgQDEgakAQCuAQEacCBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0Rl
cGxveW1lbnRzLkdldERlcGxveW1lbnRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
LkRlcGxveW1lbnRzLkdldERlcGxveW1lbnRdLgoKCwoDBAMBEgSkAQgcCuYBCgQEAwIAEgao
AQKtAQQa1QEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZQogW0RlcGxveW1lbnRdW2dvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkRlcGxveW1lbnRdLiBGb3JtYXQ6CiBgcHJvamVj
dHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+
L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnRJRD4vZGVwbG95bWVudHMvPERlcGxveW1lbnRJ
RD5gLgoKDQoFBAMCAAUSBKgBAggKDQoFBAMCAAESBKgBCQ0KDQoFBAMCAAMSBKgBEBEKDwoF
BAMCAAgSBqgBEq0BAwoQCggEAwIACJwIABIEqQEEKgoRCgcEAwIACJ8IEgaqAQSsAQViBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Deployment::Deployment ===
    # Fields for Deployment
    # Field: name Type: 9 ()
    # Field: flow_version Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dialogflow.cx.v3.Deployment.State)
    # Field: result Type: 11 (.google.cloud.dialogflow.cx.v3.Deployment.Result)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Deployment::State
our $Deployment_STATE_UNSPECIFIED = 0;
our $Deployment_RUNNING = 1;
our $Deployment_SUCCEEDED = 2;
our $Deployment_FAILED = 3;

# === Message: Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsRequest ===
    # Fields for ListDeploymentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsResponse ===
    # Fields for ListDeploymentsResponse
    # Field: deployments Type: 11 (.google.cloud.dialogflow.cx.v3.Deployment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Deployment::GetDeploymentRequest ===
    # Fields for GetDeploymentRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3::Deployment::DeploymentsClient ===
package Google::Cloud::Dialogflow::Cx::V3::Deployment::DeploymentsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3::Deployment::DeploymentsClient

Client stub representing the remote C<Deployments> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_deployments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Deployments',
        method         => 'ListDeployments',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsResponse',
    });
}

sub get_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3::Deployment::GetDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3.Deployments',
        method         => 'GetDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3::Deployment::Deployment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Deployment - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/deployment.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Deployment;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Deployment::Deployment->new({
        name => $name,
        flow_version => $flow_version,
        state => $state,
        result => $result,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Deployment::Deployment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/deployment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Deployment::Deployment

Represents a deployment in an environment. A deployment happens when a flow
version configured to be active in the environment. You can configure running
pre-deployment steps, e.g. running validation test cases, experiment
auto-rollout, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the deployment.
Format:
projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/deployments/<DeploymentID>.

=item * C<< $msg->flow_version() >> / C<< $msg->flow_version($value) >>

Type: C<String>

The name of the flow version for this deployment.
Format:
projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>/versions/<VerionID>.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::Deployment::State>)

The current state of the deployment.

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Deployment::Deployment::Result>)

Result of the deployment.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Start time of this deployment.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

End time of this deployment.

=back

=head3 Enum: Deployment::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RUNNING> => C<1>

=item * C<SUCCEEDED> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsRequest

The request message for
[Deployments.ListDeployments][google.cloud.dialogflow.cx.v3.Deployments.ListDeployments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The [Environment][google.cloud.dialogflow.cx.v3.Environment] to
list all environments for. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 20 and
at most 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Deployment::ListDeploymentsResponse

The response message for
[Deployments.ListDeployments][google.cloud.dialogflow.cx.v3.Deployments.ListDeployments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deployments() >> / C<< $msg->deployments($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Deployment::Deployment>)

The list of deployments. There will be a maximum number of items
returned based on the page_size field in the request. The list may in some
cases be empty or contain fewer entries than page_size even if this isn't
the last page.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Deployment::GetDeploymentRequest

The request message for
[Deployments.GetDeployment][google.cloud.dialogflow.cx.v3.Deployments.GetDeployment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[Deployment][google.cloud.dialogflow.cx.v3.Deployment]. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/deployments/<DeploymentID>`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Deployment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
