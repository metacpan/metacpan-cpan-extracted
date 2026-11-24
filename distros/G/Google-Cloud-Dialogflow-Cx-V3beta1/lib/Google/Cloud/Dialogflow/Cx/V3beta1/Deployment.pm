package Google::Cloud::Dialogflow::Cx::V3beta1::Deployment;

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
CjNnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2RlcGxveW1lbnQucHJvdG8S
Imdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEaHGdvb2dsZS9hcGkvYW5ub3Rh
dGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIpYGCgpEZXBsb3ltZW50EhIKBG5hbWUYASABKAlSBG5h
bWUSSQoMZmxvd192ZXJzaW9uGAIgASgJQib6QSMKIWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5j
b20vVmVyc2lvblILZmxvd1ZlcnNpb24SSgoFc3RhdGUYAyABKA4yNC5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52M2JldGExLkRlcGxveW1lbnQuU3RhdGVSBXN0YXRlEk0KBnJlc3Vs
dBgEIAEoCzI1Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRGVwbG95bWVu
dC5SZXN1bHRSBnJlc3VsdBI5CgpzdGFydF90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAYgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcFIHZW5kVGltZRq6AQoGUmVzdWx0EmUKF2RlcGxveW1lbnRfdGVzdF9y
ZXN1bHRzGAEgAygJQi36QSoKKGRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVGVzdENhc2VS
ZXN1bHRSFWRlcGxveW1lbnRUZXN0UmVzdWx0cxJJCgpleHBlcmltZW50GAIgASgJQin6QSYK
JGRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRXhwZXJpbWVudFIKZXhwZXJpbWVudCJGCgVT
dGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgsKB1JVTk5JTkcQARINCglTVUNDRUVERUQQ
AhIKCgZGQUlMRUQQAzqWAepBkgEKJGRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRGVwbG95
bWVudBJqcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50cy97
YWdlbnR9L2Vudmlyb25tZW50cy97ZW52aXJvbm1lbnR9L2RlcGxveW1lbnRzL3tkZXBsb3lt
ZW50fSKaAQoWTGlzdERlcGxveW1lbnRzUmVxdWVzdBJECgZwYXJlbnQYASABKAlCLOBBAvpB
JhIkZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9EZXBsb3ltZW50UgZwYXJlbnQSGwoJcGFn
ZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4i
kwEKF0xpc3REZXBsb3ltZW50c1Jlc3BvbnNlElAKC2RlcGxveW1lbnRzGAEgAygLMi4uZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5EZXBsb3ltZW50UgtkZXBsb3ltZW50
cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iWAoUR2V0RGVwbG95
bWVudFJlcXVlc3QSQAoEbmFtZRgBIAEoCUIs4EEC+kEmCiRkaWFsb2dmbG93Lmdvb2dsZWFw
aXMuY29tL0RlcGxveW1lbnRSBG5hbWUyzAQKC0RlcGxveW1lbnRzEukBCg9MaXN0RGVwbG95
bWVudHMSOi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkxpc3REZXBsb3lt
ZW50c1JlcXVlc3QaOy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkxpc3RE
ZXBsb3ltZW50c1Jlc3BvbnNlIl2C0+STAk4STC92M2JldGExL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9hZ2VudHMvKi9lbnZpcm9ubWVudHMvKn0vZGVwbG95bWVudHPaQQZw
YXJlbnQS1gEKDUdldERlcGxveW1lbnQSOC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
M2JldGExLkdldERlcGxveW1lbnRSZXF1ZXN0Gi4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
Y3gudjNiZXRhMS5EZXBsb3ltZW50IluC0+STAk4STC92M2JldGExL3tuYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovYWdlbnRzLyovZW52aXJvbm1lbnRzLyovZGVwbG95bWVudHMvKn3a
QQRuYW1lGnjKQRlkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29t0kFZaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2RpYWxvZ2Zsb3dCxgEKJmNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExQg9EZXBsb3ltZW50UHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFs
b2dmbG93L2N4L2FwaXYzYmV0YTEvY3hwYjtjeHBiogICREaqAiJHb29nbGUuQ2xvdWQuRGlh
bG9nZmxvdy5DeC5WM0JldGEx6gImR29vZ2xlOjpDbG91ZDo6RGlhbG9nZmxvdzo6Q1g6OlYz
YmV0YTFKlioKBxIFDgCvAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACsKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJ
CgIDBBIDFgApCggKAQgSAxgAPwoJCgIIJRIDGAA/CggKAQgSAxkATQoJCgIICxIDGQBNCggK
AQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMAoJCgIICBIDGwAwCggKAQgSAxwAPwoJCgII
ARIDHAA/CggKAQgSAx0AIAoJCgIIJBIDHQAgCggKAQgSAx4APwoJCgIILRIDHgA/CmEKAgYA
EgQiADoBGlUgU2VydmljZSBmb3IgbWFuYWdpbmcKIFtEZXBsb3ltZW50c11bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5EZXBsb3ltZW50XS4KCgoKAwYAARIDIggTCgoK
AwYAAxIDIwJBCgwKBQYAA5kIEgMjAkEKCwoDBgADEgQkAiYzCg0KBQYAA5oIEgQkAiYzCoQB
CgQGAAIAEgQqAjADGnYgUmV0dXJucyB0aGUgbGlzdCBvZiBhbGwgZGVwbG95bWVudHMgaW4g
dGhlIHNwZWNpZmllZAogW0Vudmlyb25tZW50XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5j
eC52M2JldGExLkVudmlyb25tZW50XS4KCgwKBQYAAgABEgMqBhUKDAoFBgACAAISAyoWLAoM
CgUGAAIAAxIDKw8mCg0KBQYAAgAEEgQsBC4GChEKCQYAAgAEsMq8IhIELAQuBgoMCgUGAAIA
BBIDLwQ0Cg8KCAYAAgAEmwgAEgMvBDQKZQoEBgACARIENAI5AxpXIFJldHJpZXZlcyB0aGUg
c3BlY2lmaWVkCiBbRGVwbG95bWVudF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNi
ZXRhMS5EZXBsb3ltZW50XS4KCgwKBQYAAgEBEgM0BhMKDAoFBgACAQISAzQUKAoMCgUGAAIB
AxIDNDM9Cg0KBQYAAgEEEgQ1BDcGChEKCQYAAgEEsMq8IhIENQQ3BgoMCgUGAAIBBBIDOAQy
Cg8KCAYAAgEEmwgAEgM4BDIKgwIKAgQAEgRAAH4BGvYBIFJlcHJlc2VudHMgYSBkZXBsb3lt
ZW50IGluIGFuIGVudmlyb25tZW50LiBBIGRlcGxveW1lbnQgaGFwcGVucyB3aGVuIGEgZmxv
dwogdmVyc2lvbiBjb25maWd1cmVkIHRvIGJlIGFjdGl2ZSBpbiB0aGUgZW52aXJvbm1lbnQu
IFlvdSBjYW4gY29uZmlndXJlIHJ1bm5pbmcKIHByZS1kZXBsb3ltZW50IHN0ZXBzLCBlLmcu
IHJ1bm5pbmcgdmFsaWRhdGlvbiB0ZXN0IGNhc2VzLCBleHBlcmltZW50CiBhdXRvLXJvbGxv
dXQsIGV0Yy4KCgoKAwQAARIDQAgSCgsKAwQABxIEQQJEBAoNCgUEAAedCBIEQQJEBAosCgQE
AAQAEgRHAlMDGh4gVGhlIHN0YXRlIG9mIHRoZSBkZXBsb3ltZW50LgoKDAoFBAAEAAESA0cH
DAojCgYEAAQAAgASA0kEGhoUIFN0YXRlIHVuc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDSQQV
Cg4KBwQABAACAAISA0kYGQorCgYEAAQAAgESA0wEEBocIFRoZSBkZXBsb3ltZW50IGlzIHJ1
bm5pbmcuCgoOCgcEAAQAAgEBEgNMBAsKDgoHBAAEAAIBAhIDTA4PCioKBgQABAACAhIDTwQS
GhsgVGhlIGRlcGxveW1lbnQgc3VjY2VlZGVkLgoKDgoHBAAEAAICARIDTwQNCg4KBwQABAAC
AgISA08QEQonCgYEAAQAAgMSA1IEDxoYIFRoZSBkZXBsb3ltZW50IGZhaWxlZC4KCg4KBwQA
BAACAwESA1IECgoOCgcEAAQAAgMCEgNSDQ4KKQoEBAADABIEVgJlAxobIFJlc3VsdCBvZiB0
aGUgZGVwbG95bWVudC4KCgwKBQQAAwABEgNWChAKwwEKBgQAAwACABIEWgRdCxqyASBSZXN1
bHRzIG9mIHRlc3QgY2FzZXMgcnVubmluZyBiZWZvcmUgdGhlIGRlcGxveW1lbnQuCiBGb3Jt
YXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2Vu
dHMvPEFnZW50SUQ+L3Rlc3RDYXNlcy88VGVzdENhc2VJRD4vcmVzdWx0cy88VGVzdENhc2VS
ZXN1bHRJRD5gLgoKDgoHBAADAAIABBIDWgQMCg4KBwQAAwACAAUSA1oNEwoOCgcEAAMAAgAB
EgNaFCsKDgoHBAADAAIAAxIDWi4vCg8KBwQAAwACAAgSBFsIXQoKEQoJBAADAAIACJ8IEgRb
CV0JCssBCgYEAAMAAgESBGIEZAcaugEgVGhlIG5hbWUgb2YgdGhlIGV4cGVyaW1lbnQgdHJp
Z2dlcmVkIGJ5IHRoaXMgZGVwbG95bWVudC4KIEZvcm1hdDoKIHByb2plY3RzLzxQcm9qZWN0
SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9lbnZpcm9ubWVu
dHMvPEVudmlyb25tZW50SUQ+L2V4cGVyaW1lbnRzLzxFeHBlcmltZW50SUQ+LgoKDgoHBAAD
AAIBBRIDYgQKCg4KBwQAAwACAQESA2ILFQoOCgcEAAMAAgEDEgNiGBkKDwoHBAADAAIBCBIE
YhpkBgoRCgkEAAMAAgEInwgSBGIbZAUKqwEKBAQAAgASA2oCEhqdASBUaGUgbmFtZSBvZiB0
aGUgZGVwbG95bWVudC4KIEZvcm1hdDoKIHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9u
cy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9lbnZpcm9ubWVudHMvPEVudmlyb25t
ZW50SUQ+L2RlcGxveW1lbnRzLzxEZXBsb3ltZW50SUQ+LgoKDAoFBAACAAUSA2oCCAoMCgUE
AAIAARIDagkNCgwKBQQAAgADEgNqEBEKrQEKBAQAAgESBG8CcQUangEgVGhlIG5hbWUgb2Yg
dGhlIGZsb3cgdmVyc2lvbiBmb3IgdGhpcyBkZXBsb3ltZW50LgogRm9ybWF0OgogcHJvamVj
dHMvPFByb2plY3RJRD4vbG9jYXRpb25zLzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+
L2Zsb3dzLzxGbG93SUQ+L3ZlcnNpb25zLzxWZXJpb25JRD4uCgoMCgUEAAIBBRIDbwIICgwK
BQQAAgEBEgNvCRUKDAoFBAACAQMSA28YGQoNCgUEAAIBCBIEbxpxBAoPCgcEAAIBCJ8IEgRv
G3EDCjMKBAQAAgISA3QCEhomIFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBkZXBsb3ltZW50
LgoKDAoFBAACAgYSA3QCBwoMCgUEAAICARIDdAgNCgwKBQQAAgIDEgN0EBEKKAoEBAACAxID
dwIUGhsgUmVzdWx0IG9mIHRoZSBkZXBsb3ltZW50LgoKDAoFBAACAwYSA3cCCAoMCgUEAAID
ARIDdwkPCgwKBQQAAgMDEgN3EhMKLQoEBAACBBIDegIrGiAgU3RhcnQgdGltZSBvZiB0aGlz
IGRlcGxveW1lbnQuCgoMCgUEAAIEBhIDegIbCgwKBQQAAgQBEgN6HCYKDAoFBAACBAMSA3op
KgorCgQEAAIFEgN9AikaHiBFbmQgdGltZSBvZiB0aGlzIGRlcGxveW1lbnQuCgoMCgUEAAIF
BhIDfQIbCgwKBQQAAgUBEgN9HCQKDAoFBAACBQMSA30nKAqHAQoCBAESBoIBAJMBARp5IFRo
ZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGVwbG95bWVudHMuTGlzdERlcGxveW1lbnRzXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M2JldGExLkRlcGxveW1lbnRzLkxpc3REZXBs
b3ltZW50c10uCgoLCgMEAQESBIIBCB4K4wEKBAQBAgASBoYBAosBBBrSASBSZXF1aXJlZC4g
VGhlIFtFbnZpcm9ubWVudF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5F
bnZpcm9ubWVudF0KIHRvIGxpc3QgYWxsIGVudmlyb25tZW50cyBmb3IuIEZvcm1hdDoKIGBw
cm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdl
bnRJRD4vZW52aXJvbm1lbnRzLzxFbnZpcm9ubWVudElEPmAuCgoNCgUEAQIABRIEhgECCAoN
CgUEAQIAARIEhgEJDwoNCgUEAQIAAxIEhgESEwoPCgUEAQIACBIGhgEUiwEDChAKCAQBAgAI
nAgAEgSHAQQqChEKBwQBAgAInwgSBogBBIoBBQpnCgQEAQIBEgSPAQIWGlkgVGhlIG1heGlt
dW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeSBkZWZh
dWx0IDIwIGFuZAogYXQgbW9zdCAxMDAuCgoNCgUEAQIBBRIEjwECBwoNCgUEAQIBARIEjwEI
EQoNCgUEAQIBAxIEjwEUFQpQCgQEAQICEgSSAQIYGkIgVGhlIG5leHRfcGFnZV90b2tlbiB2
YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAECAgUS
BJIBAggKDQoFBAECAgESBJIBCRMKDQoFBAECAgMSBJIBFhcKiAEKAgQCEgaXAQChAQEaeiBU
aGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtEZXBsb3ltZW50cy5MaXN0RGVwbG95bWVudHNd
W2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEuRGVwbG95bWVudHMuTGlzdERl
cGxveW1lbnRzXS4KCgsKAwQCARIElwEIHwr4AQoEBAICABIEnAECJhrpASBUaGUgbGlzdCBv
ZiBkZXBsb3ltZW50cy4gVGhlcmUgd2lsbCBiZSBhIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1z
CiByZXR1cm5lZCBiYXNlZCBvbiB0aGUgcGFnZV9zaXplIGZpZWxkIGluIHRoZSByZXF1ZXN0
LiBUaGUgbGlzdCBtYXkgaW4gc29tZQogY2FzZXMgYmUgZW1wdHkgb3IgY29udGFpbiBmZXdl
ciBlbnRyaWVzIHRoYW4gcGFnZV9zaXplIGV2ZW4gaWYgdGhpcyBpc24ndAogdGhlIGxhc3Qg
cGFnZS4KCg0KBQQCAgAEEgScAQIKCg0KBQQCAgAGEgScAQsVCg0KBQQCAgABEgScARYhCg0K
BQQCAgADEgScASQlCm8KBAQCAgESBKABAh0aYSBUb2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4
dCBwYWdlIG9mIHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubyBtb3JlCiByZXN1
bHRzIGluIHRoZSBsaXN0LgoKDQoFBAICAQUSBKABAggKDQoFBAICAQESBKABCRgKDQoFBAIC
AQMSBKABGxwKgwEKAgQDEgalAQCvAQEadSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0Rl
cGxveW1lbnRzLkdldERlcGxveW1lbnRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
YmV0YTEuRGVwbG95bWVudHMuR2V0RGVwbG95bWVudF0uCgoLCgMEAwESBKUBCBwK6wEKBAQD
AgASBqkBAq4BBBraASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlCiBbRGVwbG95bWVudF1b
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5EZXBsb3ltZW50XS4gRm9ybWF0
OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRz
LzxBZ2VudElEPi9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50SUQ+L2RlcGxveW1lbnRzLzxE
ZXBsb3ltZW50SUQ+YC4KCg0KBQQDAgAFEgSpAQIICg0KBQQDAgABEgSpAQkNCg0KBQQDAgAD
EgSpARARCg8KBQQDAgAIEgapARKuAQMKEAoIBAMCAAicCAASBKoBBCoKEQoHBAMCAAifCBIG
qwEErQEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment ===
    # Fields for Deployment
    # Field: name Type: 9 ()
    # Field: flow_version Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dialogflow.cx.v3beta1.Deployment.State)
    # Field: result Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Deployment.Result)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Deployment::State
our $Deployment_STATE_UNSPECIFIED = 0;
our $Deployment_RUNNING = 1;
our $Deployment_SUCCEEDED = 2;
our $Deployment_FAILED = 3;

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsRequest ===
    # Fields for ListDeploymentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsResponse ===
    # Fields for ListDeploymentsResponse
    # Field: deployments Type: 11 (.google.cloud.dialogflow.cx.v3beta1.Deployment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::GetDeploymentRequest ===
    # Fields for GetDeploymentRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::DeploymentsClient ===
package Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::DeploymentsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::DeploymentsClient

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
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Deployments',
        method         => 'ListDeployments',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsResponse',
    });
}

sub get_deployment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::GetDeploymentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Deployments',
        method         => 'GetDeployment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Deployment - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/deployment.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::Deployment;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment->new({
        name => $name,
        flow_version => $flow_version,
        state => $state,
        result => $result,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/deployment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment

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

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::State>)

The current state of the deployment.

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment::Result>)

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

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsRequest

The request message for
[Deployments.ListDeployments][google.cloud.dialogflow.cx.v3beta1.Deployments.ListDeployments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The [Environment][google.cloud.dialogflow.cx.v3beta1.Environment]
to list all environments for. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return in a single page. By default 20 and
at most 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsResponse

The response message for
[Deployments.ListDeployments][google.cloud.dialogflow.cx.v3beta1.Deployments.ListDeployments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deployments() >> / C<< $msg->deployments($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment>)

The list of deployments. There will be a maximum number of items
returned based on the page_size field in the request. The list may in some
cases be empty or contain fewer entries than page_size even if this isn't
the last page.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no more
results in the list.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::GetDeploymentRequest

The request message for
[Deployments.GetDeployment][google.cloud.dialogflow.cx.v3beta1.Deployments.GetDeployment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the
[Deployment][google.cloud.dialogflow.cx.v3beta1.Deployment]. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/environments/<EnvironmentID>/deployments/<DeploymentID>`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
