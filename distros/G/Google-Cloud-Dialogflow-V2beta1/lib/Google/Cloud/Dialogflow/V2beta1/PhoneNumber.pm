package Google::Cloud::Dialogflow::V2beta1::PhoneNumber;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL3Bob25lX251bWJlci5wcm90bxIf
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9u
cy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1
Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrcG
CgtQaG9uZU51bWJlchIXCgRuYW1lGAEgASgJQgPgQQFSBG5hbWUSJgoMcGhvbmVfbnVtYmVy
GAIgASgJQgPgQQNSC3Bob25lTnVtYmVyEjYKFGNvbnZlcnNhdGlvbl9wcm9maWxlGAMgASgJ
QgPgQQFSE2NvbnZlcnNhdGlvblByb2ZpbGUSaQoPbGlmZWN5Y2xlX3N0YXRlGAQgASgOMjsu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5QaG9uZU51bWJlci5MaWZlY3ljbGVT
dGF0ZUID4EEDUg5saWZlY3ljbGVTdGF0ZRJyChJhbGxvd2VkX3NpcF90cnVua3MYByABKAsy
PS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlBob25lTnVtYmVyLkFsbG93ZWRT
aXBUcnVua3NCA+BBAUgAUhBhbGxvd2VkU2lwVHJ1bmtzEj4KCnB1cmdlX3RpbWUYCCABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXB1cmdlVGltZRqAAQoQQWxsb3dl
ZFNpcFRydW5rcxJGCgpzaXBfdHJ1bmtzGAEgAygJQif6QSQKImRpYWxvZ2Zsb3cuZ29vZ2xl
YXBpcy5jb20vU2lwVHJ1bmtSCXNpcFRydW5rcxIkCgtjYXJyaWVyX2lkcxgCIAMoCUID4EEB
UgpjYXJyaWVySWRzIlMKDkxpZmVjeWNsZVN0YXRlEh8KG0xJRkVDWUNMRV9TVEFURV9VTlNQ
RUNJRklFRBAAEgoKBkFDVElWRRABEhQKEERFTEVURV9SRVFVRVNURUQQAjqgAepBnAEKJWRp
YWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vUGhvbmVOdW1iZXISLnByb2plY3RzL3twcm9qZWN0
fS9waG9uZU51bWJlcnMve3Bob25lX251bWJlcn0SQ3Byb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9waG9uZU51bWJlcnMve3Bob25lX251bWJlcn1CFQoTaW5ib3Vu
ZF9yZXN0cmljdGlvbiJdChhEZWxldGVQaG9uZU51bWJlclJlcXVlc3QSQQoEbmFtZRgBIAEo
CUIt4EEC+kEnCiVkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Bob25lTnVtYmVyUgRuYW1l
Il8KGlVuZGVsZXRlUGhvbmVOdW1iZXJSZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwol
ZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9QaG9uZU51bWJlclIEbmFtZSLOAQoXTGlzdFBo
b25lTnVtYmVyc1JlcXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScSJWRpYWxvZ2Zsb3cu
Z29vZ2xlYXBpcy5jb20vUGhvbmVOdW1iZXJSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVC
A+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4SJgoM
c2hvd19kZWxldGVkGAQgASgIQgPgQQFSC3Nob3dEZWxldGVkIpUBChhMaXN0UGhvbmVOdW1i
ZXJzUmVzcG9uc2USUQoNcGhvbmVfbnVtYmVycxgBIAMoCzIsLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTEuUGhvbmVOdW1iZXJSDHBob25lTnVtYmVycxImCg9uZXh0X3BhZ2Vf
dG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4isgEKGFVwZGF0ZVBob25lTnVtYmVyUmVxdWVz
dBJUCgxwaG9uZV9udW1iZXIYASABKAsyLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJl
dGExLlBob25lTnVtYmVyQgPgQQJSC3Bob25lTnVtYmVyEkAKC3VwZGF0ZV9tYXNrGAIgASgL
MhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrMsYJCgxQaG9u
ZU51bWJlcnMS/AEKEExpc3RQaG9uZU51bWJlcnMSOC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52MmJldGExLkxpc3RQaG9uZU51bWJlcnNSZXF1ZXN0GjkuZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjJiZXRhMS5MaXN0UGhvbmVOdW1iZXJzUmVzcG9uc2Uic4LT5JMCZBIpL3YyYmV0
YTEve3BhcmVudD1wcm9qZWN0cy8qfS9waG9uZU51bWJlcnNaNxI1L3YyYmV0YTEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9waG9uZU51bWJlcnPaQQZwYXJlbnQSuwIKEVVw
ZGF0ZVBob25lTnVtYmVyEjkuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5VcGRh
dGVQaG9uZU51bWJlclJlcXVlc3QaLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGEx
LlBob25lTnVtYmVyIrwBgtPkkwKaATI2L3YyYmV0YTEve3Bob25lX251bWJlci5uYW1lPXBy
b2plY3RzLyovcGhvbmVOdW1iZXJzLyp9OgxwaG9uZV9udW1iZXJaUjJCL3YyYmV0YTEve3Bo
b25lX251bWJlci5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcGhvbmVOdW1iZXJzLyp9
OgxwaG9uZV9udW1iZXLaQRhwaG9uZV9udW1iZXIsdXBkYXRlX21hc2sS7wEKEURlbGV0ZVBo
b25lTnVtYmVyEjkuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5EZWxldGVQaG9u
ZU51bWJlclJlcXVlc3QaLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlBob25l
TnVtYmVyInGC0+STAmQqKS92MmJldGExL3tuYW1lPXByb2plY3RzLyovcGhvbmVOdW1iZXJz
Lyp9WjcqNS92MmJldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcGhvbmVOdW1i
ZXJzLyp92kEEbmFtZRKMAgoTVW5kZWxldGVQaG9uZU51bWJlchI7Lmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyYmV0YTEuVW5kZWxldGVQaG9uZU51bWJlclJlcXVlc3QaLC5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlBob25lTnVtYmVyIokBgtPkkwJ8IjIvdjJiZXRh
MS97bmFtZT1wcm9qZWN0cy8qL3Bob25lTnVtYmVycy8qfTp1bmRlbGV0ZToBKlpDIj4vdjJi
ZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3Bob25lTnVtYmVycy8qfTp1bmRl
bGV0ZToBKtpBBG5hbWUaeMpBGWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb23SQVlodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvZGlhbG9nZmxvd0KlAQojY29tLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyYmV0YTFCEFBob25lTnVtYmVyUHJvdG9QAVpDY2xvdWQuZ29vZ2xlLmNvbS9n
by9kaWFsb2dmbG93L2FwaXYyYmV0YTEvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dwYqICAkRG
qgIfR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuVjJCZXRhMUqxQAoHEgUOAPsBAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMB
EgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACoKCQoCAwUSAxcAKQoICgEI
EgMZADwKCQoCCCUSAxkAPAoICgEIEgMaAFoKCQoCCAsSAxoAWgoICgEIEgMbACIKCQoCCAoS
AxsAIgoICgEIEgMcADEKCQoCCAgSAxwAMQoICgEIEgMdADwKCQoCCAESAx0APAoICgEIEgMe
ACAKCQoCCCQSAx4AIApgCgIGABIEIgBgARpUIFNlcnZpY2UgZm9yIG1hbmFnaW5nCiBbUGhv
bmVOdW1iZXJzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlBob25lTnVtYmVy
XS4KCgoKAwYAARIDIggUCgoKAwYAAxIDIwJBCgwKBQYAA5kIEgMjAkEKCwoDBgADEgQkAiYz
Cg0KBQYAA5oIEgQkAiYzCk8KBAYAAgASBCkCMgMaQSBSZXR1cm5zIHRoZSBsaXN0IG9mIGFs
bCBwaG9uZSBudW1iZXJzIGluIHRoZSBzcGVjaWZpZWQgcHJvamVjdC4KCgwKBQYAAgABEgMp
BhYKDAoFBgACAAISAykXLgoMCgUGAAIAAxIDKg8nCg0KBQYAAgAEEgQrBDAGChEKCQYAAgAE
sMq8IhIEKwQwBgoMCgUGAAIABBIDMQQ0Cg8KCAYAAgAEmwgAEgMxBDQKNAoEBgACARIENQI/
AxomIFVwZGF0ZXMgdGhlIHNwZWNpZmllZCBgUGhvbmVOdW1iZXJgLgoKDAoFBgACAQESAzUG
FwoMCgUGAAIBAhIDNRgwCgwKBQYAAgEDEgM1O0YKDQoFBgACAQQSBDYEPQYKEQoJBgACAQSw
yrwiEgQ2BD0GCgwKBQYAAgEEEgM+BEYKDwoIBgACAQSbCAASAz4ERgqKAwoEBgACAhIERwJP
Axr7AiBSZXF1ZXN0cyBkZWxldGlvbiBvZiBhIGBQaG9uZU51bWJlcmAuIFRoZSBgUGhvbmVO
dW1iZXJgIGlzIG1vdmVkIGludG8gdGhlCiBbREVMRVRFX1JFUVVFU1RFRF1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5QaG9uZU51bWJlci5MaWZlY3ljbGVTdGF0ZS5ERUxF
VEVfUkVRVUVTVEVEXQogc3RhdGUgaW1tZWRpYXRlbHksIGFuZCBpcyBkZWxldGVkIGFwcHJv
eGltYXRlbHkgMzAgZGF5cyBsYXRlci4gVGhpcyBtZXRob2QKIG1heSBvbmx5IGJlIGNhbGxl
ZCBvbiBhIGBQaG9uZU51bWJlcmAgaW4gdGhlCiBbQUNUSVZFXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MmJldGExLlBob25lTnVtYmVyLkxpZmVjeWNsZVN0YXRlLkFDVElWRV0KIHN0
YXRlLgoKDAoFBgACAgESA0cGFwoMCgUGAAICAhIDRxgwCgwKBQYAAgIDEgNHO0YKDQoFBgAC
AgQSBEgETQYKEQoJBgACAgSwyrwiEgRIBE0GCgwKBQYAAgIEEgNOBDIKDwoIBgACAgSbCAAS
A04EMgrlAQoEBgACAxIEVQJfAxrWASBDYW5jZWxzIHRoZSBkZWxldGlvbiByZXF1ZXN0IGZv
ciBhIGBQaG9uZU51bWJlcmAuIFRoaXMgbWV0aG9kIG1heSBvbmx5IGJlCiBjYWxsZWQgb24g
YSBgUGhvbmVOdW1iZXJgIGluIHRoZQogW0RFTEVURV9SRVFVRVNURURdW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyYmV0YTEuUGhvbmVOdW1iZXIuTGlmZWN5Y2xlU3RhdGUuREVMRVRF
X1JFUVVFU1RFRF0KIHN0YXRlLgoKDAoFBgACAwESA1UGGQoMCgUGAAIDAhIDVRo0CgwKBQYA
AgMDEgNVP0oKDQoFBgACAwQSBFYEXQYKEQoJBgACAwSwyrwiEgRWBF0GCgwKBQYAAgMEEgNe
BDIKDwoIBgACAwSbCAASA14EMgrpAQoCBAASBWYArAEBGtsBIFJlcHJlc2VudHMgYSBwaG9u
ZSBudW1iZXIuCiBgUGhvbmVOdW1iZXJgIHJlc291cmNlcyBlbmFibGUgcGhvbmUgY2FsbHMg
dG8gYmUgYW5zd2VyZWQgYnkgRGlhbG9nZmxvdwogc2VydmljZXMgYW5kIGFyZSBhZGRlZCB0
byBhIHByb2plY3QgdGhyb3VnaCBhCiBbUGhvbmVOdW1iZXJPcmRlcl1bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjJiZXRhMS5QaG9uZU51bWJlck9yZGVyXS4KCgoKAwQAARIDZggTCgsK
AwQABxIEZwJrBAoNCgUEAAedCBIEZwJrBAo6CgQEAAQAEgRuAncDGiwgVGhlIHN0YXRlcyB0
aGF0IGEgYFBob25lTnVtYmVyYCBjYW4gYmUgaW4uCgoMCgUEAAQAARIDbgcVCioKBgQABAAC
ABIDcAQkGhsgVGhpcyB2YWx1ZSBpcyBuZXZlciB1c2VkLgoKDgoHBAAEAAIAARIDcAQfCg4K
BwQABAACAAISA3AiIwo+CgYEAAQAAgESA3MEDxovIE51bWJlciBpcyBhY3RpdmUgYW5kIGNh
biByZWNlaXZlIHBob25lIGNhbGxzLgoKDgoHBAAEAAIBARIDcwQKCg4KBwQABAACAQISA3MN
DgpGCgYEAAQAAgISA3YEGRo3IE51bWJlciBpcyBwZW5kaW5nIGRlbGV0aW9uLCBhbmQgY2Fu
bm90IHJlY2VpdmUgY2FsbHMuCgoOCgcEAAQAAgIBEgN2BBQKDgoHBAAEAAICAhIDdhcYClgK
BAQAAwASBXoChQEDGkkgTGlzdCBvZiBTSVAgdHJ1bmtzIHRoYXQgYXJlIGFsbG93ZWQgdG8g
bWFrZSBjYWxscyB0byB0aGlzIHBob25lIG51bWJlci4KCgwKBQQAAwABEgN6ChoKfgoGBAAD
AAIAEgR9BH8HGm4gTGlzdCBvZiBTSVAgdHJ1bmtzIHRoYXQgYXJlIGFsbG93ZWQgdG8gbWFr
ZSBjYWxscyB0byB0aGlzIHBob25lIG51bWJlci4KIElmIGVtcHR5LCBhbnkgU0lQIHRydW5r
IGlzIGFsbG93ZWQuCgoOCgcEAAMAAgAEEgN9BAwKDgoHBAADAAIABRIDfQ0TCg4KBwQAAwAC
AAESA30UHgoOCgcEAAMAAgADEgN9ISIKDwoHBAADAAIACBIEfSN/BgoRCgkEAAMAAgAInwgS
BH0kfwUKrgEKBgQAAwACARIEhAEETRqdASBPcHRpb25hbC4gTGlzdCBvZiBHVFAgY2Fycmll
ciBJRHMgYWxsb3dlZCB0byBtYWtlIGNhbGxzIHRvIHRoaXMgcGhvbmUKIG51bWJlci4gVXNl
ZCBmb3IgcHJpdmF0ZSBpbnRlcmNvbm5lY3RzIHdoZXJlIHN0YW5kYXJkIFNJUCB0cnVua3Mg
YXJlbid0CiBhcHBsaWNhYmxlLgoKDwoHBAADAAIBBBIEhAEEDAoPCgcEAAMAAgEFEgSEAQ0T
Cg8KBwQAAwACAQESBIQBFB8KDwoHBAADAAIBAxIEhAEiIwoPCgcEAAMAAgEIEgSEASRMChIK
CgQAAwACAQicCAASBIQBJUsK1wIKBAQAAgASBI0BAjsayAIgT3B0aW9uYWwuIFRoZSB1bmlx
dWUgaWRlbnRpZmllciBvZiB0aGlzIHBob25lIG51bWJlci4KIFJlcXVpcmVkIGZvcgogW1Bo
b25lTnVtYmVycy5VcGRhdGVQaG9uZU51bWJlcl1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djJiZXRhMS5QaG9uZU51bWJlcnMuVXBkYXRlUGhvbmVOdW1iZXJdCiBtZXRob2QuIEZvcm1h
dDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9waG9uZU51bWJlcnMvPFBob25lTnVtYmVyIElE
PmAuCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlv
bgogSUQ+L3Bob25lTnVtYmVycy88UGhvbmVOdW1iZXIgSUQ+YC4KCg0KBQQAAgAFEgSNAQII
Cg0KBQQAAgABEgSNAQkNCg0KBQQAAgADEgSNARARCg0KBQQAAgAIEgSNARI6ChAKCAQAAgAI
nAgAEgSNARM5CqMBCgQEAAIBEgSRAQJGGpQBIE91dHB1dCBvbmx5LiBQaG9uZSBudW1iZXIg
aW4gW0UuMTY0XShodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9FLjE2NCkKIGZvcm1h
dC4gQW4gZXhhbXBsZSBvZiBhIGNvcnJlY3RseSBmb3JtYXR0ZWQgcGhvbmUgbnVtYmVyOiAr
MTU1NTY3Njc4ODguCgoNCgUEAAIBBRIEkQECCAoNCgUEAAIBARIEkQEJFQoNCgUEAAIBAxIE
kQEYGQoNCgUEAAIBCBIEkQEaRQoQCggEAAIBCJwIABIEkQEbRAqGAwoEBAACAhIEmgECSxr3
AiBPcHRpb25hbC4gVGhlIGNvbnZlcnNhdGlvbiBwcm9maWxlIGNhbGxzIHRvIHRoaXMgYFBo
b25lTnVtYmVyYCBzaG91bGQgdXNlLgogVGhlIHByb2plY3QgSUQgaGVyZSBzaG91bGQgYmUg
dGhlIHNhbWUgYXMgdGhlIG9uZSBpbgogW25hbWVdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyYmV0YTEuUGhvbmVOdW1iZXIubmFtZV0uCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVj
dCBJRD4vY29udmVyc2F0aW9uUHJvZmlsZXMvPENvbnZlcnNhdGlvblByb2ZpbGUKIElEPmAu
CiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbgog
SUQ+L2NvbnZlcnNhdGlvblByb2ZpbGVzLzxDb252ZXJzYXRpb25Qcm9maWxlIElEPmAuCgoN
CgUEAAICBRIEmgECCAoNCgUEAAICARIEmgEJHQoNCgUEAAICAxIEmgEgIQoNCgUEAAICCBIE
mgEiSgoQCggEAAICCJwIABIEmgEjSQrTAQoEBAACAxIGnwECoAEyGsIBIE91dHB1dCBvbmx5
LiBUaGUgc3RhdGUgb2YgdGhlIGBQaG9uZU51bWJlcmAuIERlZmF1bHRzIHRvIGBBQ1RJVkVg
LgogYFBob25lTnVtYmVyYCBvYmplY3RzIHNldCB0byBgREVMRVRFX1JFUVVFU1RFRGAgYWx3
YXlzIGRlY2xpbmUgaW5jb21pbmcKIGNhbGxzIGFuZCBjYW4gYmUgcmVtb3ZlZCBjb21wbGV0
ZWx5IHdpdGhpbiAzMCBkYXlzLgoKDQoFBAACAwYSBJ8BAhAKDQoFBAACAwESBJ8BESAKDQoF
BAACAwMSBJ8BIyQKDQoFBAACAwgSBKABBjEKEAoIBAACAwicCAASBKABBzAKKQoEBAAIABIG
owECpwEDGhkgUmVzdHJpY3RzIGluYm91bmQgY2FsbHMKCg0KBQQACAABEgSjAQgbCksKBAQA
AgQSBqUBBKYBMRo7IE9wdGlvbmFsLiBPbmx5IGFsbG93IGNhbGxzIGZyb20gdGhlIHNwZWNp
ZmllZCBTSVAgdHJ1bmtzLgoKDQoFBAACBAYSBKUBBBQKDQoFBAACBAESBKUBFScKDQoFBAAC
BAMSBKUBKisKDQoFBAACBAgSBKYBCDAKEAoIBAACBAicCAASBKYBCS8KTgoEBAACBRIGqgEC
qwEyGj4gT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoaXMgcmVzb3VyY2Ugd2ls
bCBiZSBwdXJnZWQuCgoNCgUEAAIFBhIEqgECGwoNCgUEAAIFARIEqgEcJgoNCgUEAAIFAxIE
qgEpKgoNCgUEAAIFCBIEqwEGMQoQCggEAAIFCJwIABIEqwEHMAqKAQoCBAESBrABALsBARp8
IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbUGhvbmVOdW1iZXJzLkRlbGV0ZVBob25lTnVt
YmVyXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlBob25lTnVtYmVycy5EZWxl
dGVQaG9uZU51bWJlcl0uCgoLCgMEAQESBLABCCAK6wEKBAQBAgASBrUBAroBBBraASBSZXF1
aXJlZC4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBgUGhvbmVOdW1iZXJgIHRvIGRl
bGV0ZS4KIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9waG9uZU51bWJlcnMvPFBo
b25lTnVtYmVyIElEPmAuCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRp
b25zLzxMb2NhdGlvbgogSUQ+L3Bob25lTnVtYmVycy88UGhvbmVOdW1iZXIgSUQ+YC4KCg0K
BQQBAgAFEgS1AQIICg0KBQQBAgABEgS1AQkNCg0KBQQBAgADEgS1ARARCg8KBQQBAgAIEga1
ARK6AQMKEAoIBAECAAicCAASBLYBBCoKEQoHBAECAAifCBIGtwEEuQEFCo8BCgIEAhIGvwEA
ygEBGoABIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbUGhvbmVOdW1iZXJzLlVuZGVsZXRl
UGhvbmVOdW1iZXJdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuUGhvbmVOdW1i
ZXJzLlVuZGVsZXRlUGhvbmVOdW1iZXJdLgoKCwoDBAIBEgS/AQgiCusBCgQEAgIAEgbEAQLJ
AQQa2gEgUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgYFBob25lTnVt
YmVyYCB0byBkZWxldGUuCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vcGhvbmVO
dW1iZXJzLzxQaG9uZU51bWJlciBJRD5gLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3Qg
SUQ+L2xvY2F0aW9ucy88TG9jYXRpb24KIElEPi9waG9uZU51bWJlcnMvPFBob25lTnVtYmVy
IElEPmAuCgoNCgUEAgIABRIExAECCAoNCgUEAgIAARIExAEJDQoNCgUEAgIAAxIExAEQEQoP
CgUEAgIACBIGxAESyQEDChAKCAQCAgAInAgAEgTFAQQqChEKBwQCAgAInwgSBsYBBMgBBQqI
AQoCBAMSBs4BAOQBARp6IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbUGhvbmVOdW1iZXJz
Lkxpc3RQaG9uZU51bWJlcnNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuUGhv
bmVOdW1iZXJzLkxpc3RQaG9uZU51bWJlcnNdLgoKCwoDBAMBEgTOAQgfCq4BCgQEAwIAEgbS
AQLXAQQanQEgUmVxdWlyZWQuIFRoZSBwcm9qZWN0IHRvIGxpc3QgYWxsIGBQaG9uZU51bWJl
cmAgcmVzb3VyY2VzIGZyb20uCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD5gLgog
Rm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+
YC4KCg0KBQQDAgAFEgTSAQIICg0KBQQDAgABEgTSAQkPCg0KBQQDAgADEgTSARITCg8KBQQD
AgAIEgbSARTXAQMKEAoIBAMCAAicCAASBNMBBCoKEQoHBAMCAAifCBIG1AEE1gEFCocBCgQE
AwIBEgTbAQI/GnkgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byBy
ZXR1cm4gaW4gYSBzaW5nbGUgcGFnZS4KIFRoZSBkZWZhdWx0IHZhbHVlIGlzIDEwMC4gVGhl
IG1heGltdW0gdmFsdWUgaXMgMTAwMC4KCg0KBQQDAgEFEgTbAQIHCg0KBQQDAgEBEgTbAQgR
Cg0KBQQDAgEDEgTbARQVCg0KBQQDAgEIEgTbARY+ChAKCAQDAgEInAgAEgTbARc9CloKBAQD
AgISBN4BAkEaTCBPcHRpb25hbC4gVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5l
ZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LgoKDQoFBAMCAgUSBN4BAggKDQoFBAMC
AgESBN4BCRMKDQoFBAMCAgMSBN4BFhcKDQoFBAMCAggSBN4BGEAKEAoIBAMCAgicCAASBN4B
GT8K2QEKBAQDAgMSBOMBAkEaygEgT3B0aW9uYWwuIENvbnRyb2xzIHdoZXRoZXIgYFBob25l
TnVtYmVyYCByZXNvdXJjZXMgaW4gdGhlCiBbREVMRVRFX1JFUVVFU1RFRF1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5QaG9uZU51bWJlci5MaWZlY3ljbGVTdGF0ZS5ERUxF
VEVfUkVRVUVTVEVEXQogc3RhdGUgc2hvdWxkIGJlIHJldHVybmVkLiBEZWZhdWx0cyB0byBm
YWxzZS4KCg0KBQQDAgMFEgTjAQIGCg0KBQQDAgMBEgTjAQcTCg0KBQQDAgMDEgTjARYXCg0K
BQQDAgMIEgTjARhAChAKCAQDAgMInAgAEgTjARk/CokBCgIEBBIG6AEA8AEBGnsgVGhlIHJl
c3BvbnNlIG1lc3NhZ2UgZm9yCiBbUGhvbmVOdW1iZXJzLkxpc3RQaG9uZU51bWJlcnNdW2dv
b2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuUGhvbmVOdW1iZXJzLkxpc3RQaG9uZU51
bWJlcnNdLgoKCwoDBAQBEgToAQggCo8BCgQEBAIAEgTrAQIpGoABIFRoZSBsaXN0IG9mIGBQ
aG9uZU51bWJlcmAgcmVzb3VyY2VzLiBUaGVyZSBpcyBhIG1heGltdW0gbnVtYmVyIG9mIGl0
ZW1zCiByZXR1cm5lZCBiYXNlZCBvbiB0aGUgcGFnZV9zaXplIGZpZWxkIGluIHRoZSByZXF1
ZXN0LgoKDQoFBAQCAAQSBOsBAgoKDQoFBAQCAAYSBOsBCxYKDQoFBAQCAAESBOsBFyQKDQoF
BAQCAAMSBOsBJygKbwoEBAQCARIE7wECHRphIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0
IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBtb3JlIHJlc3Vs
dHMgaW4gdGhlIGxpc3QuCgoNCgUEBAIBBRIE7wECCAoNCgUEBAIBARIE7wEJGAoNCgUEBAIB
AxIE7wEbHAqKAQoCBAUSBvQBAPsBARp8IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbUGhv
bmVOdW1iZXJzLlVwZGF0ZVBob25lTnVtYmVyXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52
MmJldGExLlBob25lTnVtYmVycy5VcGRhdGVQaG9uZU51bWJlcl0uCgoLCgMEBQESBPQBCCAK
NgoEBAUCABIE9gECSBooIFJlcXVpcmVkLiBUaGUgYFBob25lTnVtYmVyYCB0byB1cGRhdGUu
CgoNCgUEBQIABhIE9gECDQoNCgUEBQIAARIE9gEOGgoNCgUEBQIAAxIE9gEdHgoNCgUEBQIA
CBIE9gEfRwoQCggEBQIACJwIABIE9gEgRgpJCgQEBQIBEgb5AQL6AS8aOSBPcHRpb25hbC4g
VGhlIG1hc2sgdG8gY29udHJvbCB3aGljaCBmaWVsZHMgZ2V0IHVwZGF0ZWQuCgoNCgUEBQIB
BhIE+QECGwoNCgUEBQIBARIE+QEcJwoNCgUEBQIBAxIE+QEqKwoNCgUEBQIBCBIE+gEGLgoQ
CggEBQIBCJwIABIE+gEHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber ===
    # Fields for PhoneNumber
    # Field: name Type: 9 ()
    # Field: phone_number Type: 9 ()
    # Field: conversation_profile Type: 9 ()
    # Field: lifecycle_state Type: 14 (.google.cloud.dialogflow.v2beta1.PhoneNumber.LifecycleState)
    # Field: allowed_sip_trunks Type: 11 (.google.cloud.dialogflow.v2beta1.PhoneNumber.AllowedSipTrunks)
    # Field: purge_time Type: 11 (.google.protobuf.Timestamp)

# Enum: PhoneNumber::LifecycleState
our $PhoneNumber_LIFECYCLE_STATE_UNSPECIFIED = 0;
our $PhoneNumber_ACTIVE = 1;
our $PhoneNumber_DELETE_REQUESTED = 2;

# === Message: Google::Cloud::Dialogflow::V2beta1::PhoneNumber::DeletePhoneNumberRequest ===
    # Fields for DeletePhoneNumberRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UndeletePhoneNumberRequest ===
    # Fields for UndeletePhoneNumberRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest ===
    # Fields for ListPhoneNumbersRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: show_deleted Type: 8 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse ===
    # Fields for ListPhoneNumbersResponse
    # Field: phone_numbers Type: 11 (.google.cloud.dialogflow.v2beta1.PhoneNumber)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UpdatePhoneNumberRequest ===
    # Fields for UpdatePhoneNumberRequest
    # Field: phone_number Type: 11 (.google.cloud.dialogflow.v2beta1.PhoneNumber)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumbersClient ===
package Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumbersClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumbersClient

Client stub representing the remote C<PhoneNumbers> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_phone_numbers {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.PhoneNumbers',
        method         => 'ListPhoneNumbers',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse',
    });
}

sub update_phone_number {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UpdatePhoneNumberRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.PhoneNumbers',
        method         => 'UpdatePhoneNumber',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber',
    });
}

sub delete_phone_number {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::PhoneNumber::DeletePhoneNumberRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.PhoneNumbers',
        method         => 'DeletePhoneNumber',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber',
    });
}

sub undelete_phone_number {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UndeletePhoneNumberRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.PhoneNumbers',
        method         => 'UndeletePhoneNumber',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::PhoneNumber - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/phone_number.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::PhoneNumber;

    my $msg = Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber->new({
        name => $name,
        phone_number => $phone_number,
        conversation_profile => $conversation_profile,
        lifecycle_state => $lifecycle_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/phone_number.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber

Represents a phone number.
`PhoneNumber` resources enable phone calls to be answered by Dialogflow
services and are added to a project through a
[PhoneNumberOrder][google.cloud.dialogflow.v2beta1.PhoneNumberOrder].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The unique identifier of this phone number.
Required for
[PhoneNumbers.UpdatePhoneNumber][google.cloud.dialogflow.v2beta1.PhoneNumbers.UpdatePhoneNumber]
method. Format: `projects/<Project ID>/phoneNumbers/<PhoneNumber ID>`.
Format: `projects/<Project ID>/locations/<Location
ID>/phoneNumbers/<PhoneNumber ID>`.

=item * C<< $msg->phone_number() >> / C<< $msg->phone_number($value) >>

Type: C<String>

Output only. Phone number in [E.164](https://en.wikipedia.org/wiki/E.164)
format. An example of a correctly formatted phone number: +15556767888.

=item * C<< $msg->conversation_profile() >> / C<< $msg->conversation_profile($value) >>

Type: C<String>

Optional. The conversation profile calls to this `PhoneNumber` should use.
The project ID here should be the same as the one in
[name][google.cloud.dialogflow.v2beta1.PhoneNumber.name].
Format: `projects/<Project ID>/conversationProfiles/<ConversationProfile
ID>`.
Format: `projects/<Project ID>/locations/<Location
ID>/conversationProfiles/<ConversationProfile ID>`.

=item * C<< $msg->lifecycle_state() >> / C<< $msg->lifecycle_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::PhoneNumber::LifecycleState>)

Output only. The state of the `PhoneNumber`. Defaults to `ACTIVE`.
`PhoneNumber` objects set to `DELETE_REQUESTED` always decline incoming
calls and can be removed completely within 30 days.

=item * C<< $msg->allowed_sip_trunks() >> / C<< $msg->allowed_sip_trunks($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber::AllowedSipTrunks>)

Optional. Only allow calls from the specified SIP trunks.

=item * C<< $msg->purge_time() >> / C<< $msg->purge_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this resource will be purged.

=back

=head3 Enum: PhoneNumber::LifecycleState

=over 4

=item * C<LIFECYCLE_STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<DELETE_REQUESTED> => C<2>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::PhoneNumber::DeletePhoneNumberRequest

The request message for
[PhoneNumbers.DeletePhoneNumber][google.cloud.dialogflow.v2beta1.PhoneNumbers.DeletePhoneNumber].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier of the `PhoneNumber` to delete.
Format: `projects/<Project ID>/phoneNumbers/<PhoneNumber ID>`.
Format: `projects/<Project ID>/locations/<Location
ID>/phoneNumbers/<PhoneNumber ID>`.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UndeletePhoneNumberRequest

The request message for
[PhoneNumbers.UndeletePhoneNumber][google.cloud.dialogflow.v2beta1.PhoneNumbers.UndeletePhoneNumber].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The unique identifier of the `PhoneNumber` to delete.
Format: `projects/<Project ID>/phoneNumbers/<PhoneNumber ID>`.
Format: `projects/<Project ID>/locations/<Location
ID>/phoneNumbers/<PhoneNumber ID>`.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest

The request message for
[PhoneNumbers.ListPhoneNumbers][google.cloud.dialogflow.v2beta1.PhoneNumbers.ListPhoneNumbers].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project to list all `PhoneNumber` resources from.
Format: `projects/<Project ID>`.
Format: `projects/<Project ID>/locations/<Location ID>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page.
The default value is 100. The maximum value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=item * C<< $msg->show_deleted() >> / C<< $msg->show_deleted($value) >>

Type: C<Bool>

Optional. Controls whether `PhoneNumber` resources in the
[DELETE_REQUESTED][google.cloud.dialogflow.v2beta1.PhoneNumber.LifecycleState.DELETE_REQUESTED]
state should be returned. Defaults to false.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse

The response message for
[PhoneNumbers.ListPhoneNumbers][google.cloud.dialogflow.v2beta1.PhoneNumbers.ListPhoneNumbers].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->phone_numbers() >> / C<< $msg->phone_numbers($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber>)

The list of `PhoneNumber` resources. There is a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UpdatePhoneNumberRequest

The request message for
[PhoneNumbers.UpdatePhoneNumber][google.cloud.dialogflow.v2beta1.PhoneNumbers.UpdatePhoneNumber].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->phone_number() >> / C<< $msg->phone_number($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber>)

Required. The `PhoneNumber` to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::PhoneNumber::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
