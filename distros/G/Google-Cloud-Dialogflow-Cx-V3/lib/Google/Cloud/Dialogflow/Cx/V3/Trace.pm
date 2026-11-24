package Google::Cloud::Dialogflow::Cx::V3::Trace;

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
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My90cmFjZS5wcm90bxIdZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cuY3gudjMaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ilwYKClRyYWNlQmxvY2sSbgoX
cGxheWJvb2tfdHJhY2VfbWV0YWRhdGEYASABKAsyNC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52My5QbGF5Ym9va1RyYWNlTWV0YWRhdGFIAFIVcGxheWJvb2tUcmFjZU1ldGFkYXRh
EmIKE2Zsb3dfdHJhY2VfbWV0YWRhdGEYAiABKAsyMC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy5jeC52My5GbG93VHJhY2VNZXRhZGF0YUgAUhFmbG93VHJhY2VNZXRhZGF0YRJ3ChpzcGVl
Y2hfcHJvY2Vzc2luZ19tZXRhZGF0YRgIIAEoCzI3Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LmN4LnYzLlNwZWVjaFByb2Nlc3NpbmdNZXRhZGF0YUgAUhhzcGVlY2hQcm9jZXNzaW5nTWV0
YWRhdGESPwoHYWN0aW9ucxgDIAMoCzIlLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYz
LkFjdGlvblIHYWN0aW9ucxI+CgpzdGFydF90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUglzdGFydFRpbWUSRAoNY29tcGxldGVfdGltZRgFIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IMY29tcGxldGVUaW1lEkcKEGlucHV0X3Bh
cmFtZXRlcnMYCSABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPgQQFSD2lucHV0UGFy
YW1ldGVycxJJChFvdXRwdXRfcGFyYW1ldGVycxgGIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5T
dHJ1Y3RCA+BBAVIQb3V0cHV0UGFyYW1ldGVycxJPCgllbmRfc3RhdGUYByABKA4yKi5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5PdXRwdXRTdGF0ZUIG4EED4EEBUghlbmRTdGF0
ZUIQCg50cmFjZV9tZXRhZGF0YSJCChhTcGVlY2hQcm9jZXNzaW5nTWV0YWRhdGESJgoMZGlz
cGxheV9uYW1lGAEgASgJQgPgQQNSC2Rpc3BsYXlOYW1lIocBChVQbGF5Ym9va1RyYWNlTWV0
YWRhdGESRgoIcGxheWJvb2sYASABKAlCKuBBAvpBJAoiZGlhbG9nZmxvdy5nb29nbGVhcGlz
LmNvbS9QbGF5Ym9va1IIcGxheWJvb2sSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQNSC2Rp
c3BsYXlOYW1lIncKEUZsb3dUcmFjZU1ldGFkYXRhEjoKBGZsb3cYASABKAlCJuBBAvpBIAoe
ZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9GbG93UgRmbG93EiYKDGRpc3BsYXlfbmFtZRgC
IAEoCUID4EEDUgtkaXNwbGF5TmFtZSJaCg1QbGF5Ym9va0lucHV0EkkKHnByZWNlZGluZ19j
b252ZXJzYXRpb25fc3VtbWFyeRgBIAEoCUID4EEBUhxwcmVjZWRpbmdDb252ZXJzYXRpb25T
dW1tYXJ5IkIKDlBsYXlib29rT3V0cHV0EjAKEWV4ZWN1dGlvbl9zdW1tYXJ5GAEgASgJQgPg
QQFSEGV4ZWN1dGlvblN1bW1hcnkiqwUKBkFjdGlvbhJaCg51c2VyX3V0dGVyYW5jZRgBIAEo
CzIsLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLlVzZXJVdHRlcmFuY2VCA+BBAUgA
Ug11c2VyVXR0ZXJhbmNlEl0KD2FnZW50X3V0dGVyYW5jZRgCIAEoCzItLmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LmN4LnYzLkFnZW50VXR0ZXJhbmNlQgPgQQFIAFIOYWdlbnRVdHRlcmFu
Y2USSAoIdG9vbF91c2UYAyABKAsyJi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5U
b29sVXNlQgPgQQFIAFIHdG9vbFVzZRJpChNwbGF5Ym9va19pbnZvY2F0aW9uGAQgASgLMjEu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuUGxheWJvb2tJbnZvY2F0aW9uQgPgQQFI
AFIScGxheWJvb2tJbnZvY2F0aW9uEl0KD2Zsb3dfaW52b2NhdGlvbhgFIAEoCzItLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzLkZsb3dJbnZvY2F0aW9uQgPgQQFIAFIOZmxvd0lu
dm9jYXRpb24SaQoTcGxheWJvb2tfdHJhbnNpdGlvbhgMIAEoCzIxLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LmN4LnYzLlBsYXlib29rVHJhbnNpdGlvbkID4EEBSABSEnBsYXlib29rVHJh
bnNpdGlvbhJdCg9mbG93X3RyYW5zaXRpb24YDSABKAsyLS5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy5jeC52My5GbG93VHJhbnNpdGlvbkID4EEBSABSDmZsb3dUcmFuc2l0aW9uQggKBmFj
dGlvbiIoCg1Vc2VyVXR0ZXJhbmNlEhcKBHRleHQYASABKAlCA+BBAlIEdGV4dCIpCg5BZ2Vu
dFV0dGVyYW5jZRIXCgR0ZXh0GAEgASgJQgPgQQJSBHRleHQiuAIKB1Rvb2xVc2USOgoEdG9v
bBgBIAEoCUIm4EEC+kEgCh5kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Rvb2xSBHRvb2wS
JgoMZGlzcGxheV9uYW1lGAggASgJQgPgQQNSC2Rpc3BsYXlOYW1lEhsKBmFjdGlvbhgCIAEo
CUID4EEBUgZhY3Rpb24SVAoXaW5wdXRfYWN0aW9uX3BhcmFtZXRlcnMYBSABKAsyFy5nb29n
bGUucHJvdG9idWYuU3RydWN0QgPgQQFSFWlucHV0QWN0aW9uUGFyYW1ldGVycxJWChhvdXRw
dXRfYWN0aW9uX3BhcmFtZXRlcnMYBiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPg
QQFSFm91dHB1dEFjdGlvblBhcmFtZXRlcnMikwMKElBsYXlib29rSW52b2NhdGlvbhJGCghw
bGF5Ym9vaxgBIAEoCUIq4EEC+kEkCiJkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1BsYXli
b29rUghwbGF5Ym9vaxImCgxkaXNwbGF5X25hbWUYBSABKAlCA+BBA1ILZGlzcGxheU5hbWUS
WAoOcGxheWJvb2tfaW5wdXQYAiABKAsyLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52
My5QbGF5Ym9va0lucHV0QgPgQQFSDXBsYXlib29rSW5wdXQSWwoPcGxheWJvb2tfb3V0cHV0
GAMgASgLMi0uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMuUGxheWJvb2tPdXRwdXRC
A+BBAVIOcGxheWJvb2tPdXRwdXQSVgoOcGxheWJvb2tfc3RhdGUYBCABKA4yKi5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy5jeC52My5PdXRwdXRTdGF0ZUID4EECUg1wbGF5Ym9va1N0YXRl
IsQBCg5GbG93SW52b2NhdGlvbhI6CgRmbG93GAEgASgJQibgQQL6QSAKHmRpYWxvZ2Zsb3cu
Z29vZ2xlYXBpcy5jb20vRmxvd1IEZmxvdxImCgxkaXNwbGF5X25hbWUYByABKAlCA+BBA1IL
ZGlzcGxheU5hbWUSTgoKZmxvd19zdGF0ZRgEIAEoDjIqLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LmN4LnYzLk91dHB1dFN0YXRlQgPgQQJSCWZsb3dTdGF0ZSKEAQoSUGxheWJvb2tUcmFu
c2l0aW9uEkYKCHBsYXlib29rGAEgASgJQirgQQL6QSQKImRpYWxvZ2Zsb3cuZ29vZ2xlYXBp
cy5jb20vUGxheWJvb2tSCHBsYXlib29rEiYKDGRpc3BsYXlfbmFtZRgDIAEoCUID4EEDUgtk
aXNwbGF5TmFtZSJ0Cg5GbG93VHJhbnNpdGlvbhI6CgRmbG93GAEgASgJQibgQQL6QSAKHmRp
YWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRmxvd1IEZmxvdxImCgxkaXNwbGF5X25hbWUYAyAB
KAlCA+BBA1ILZGlzcGxheU5hbWUqqwEKC091dHB1dFN0YXRlEhwKGE9VVFBVVF9TVEFURV9V
TlNQRUNJRklFRBAAEhMKD09VVFBVVF9TVEFURV9PSxABEhoKFk9VVFBVVF9TVEFURV9DQU5D
RUxMRUQQAhIXChNPVVRQVVRfU1RBVEVfRkFJTEVEEAMSGgoWT1VUUFVUX1NUQVRFX0VTQ0FM
QVRFRBAEEhgKFE9VVFBVVF9TVEFURV9QRU5ESU5HEAVCrQEKIWNvbS5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy5jeC52M0IKVHJhY2VQcm90b1ABWjFjbG91ZC5nb29nbGUuY29tL2dvL2Rp
YWxvZ2Zsb3cvY3gvYXBpdjMvY3hwYjtjeHBiogICREaqAh1Hb29nbGUuQ2xvdWQuRGlhbG9n
Zmxvdy5DeC5WM+oCIUdvb2dsZTo6Q2xvdWQ6OkRpYWxvZ2Zsb3c6OkNYOjpWM0qtSgoHEgUO
AJ4CAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJgoJCgID
ABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoJCgIDAxIDFQApCggKAQgSAxcAOgoJCgII
JRIDFwA6CggKAQgSAxgASAoJCgIICxIDGABICggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgS
AxoAKwoJCgIICBIDGgArCggKAQgSAxsAOgoJCgIIARIDGwA6CggKAQgSAxwAIAoJCgIIJBID
HAAgCggKAQgSAx0AOgoJCgIILRIDHQA6CmcKAgQAEgQhAEYBGlsgVGhlIHRyYWNlIGJsb2Nr
IHRyYWNrcyBhIHNlcXVlbmNlIG9mIGFjdGlvbnMgdGFrZW4gYnkgdGhlIGFnZW50IGluIGEg
ZmxvdyBvcgogYSBwbGF5Ym9vay4KCgoKAwQAARIDIQgSCiYKBAQACAASBCMCLAMaGCBNZXRh
ZGF0YSBvZiB0aGUgdHJhY2UuCgoMCgUEAAgAARIDIwgWCi4KBAQAAgASAyUENhohIE1ldGFk
YXRhIG9mIHRoZSBwbGF5Ym9vayB0cmFjZS4KCgwKBQQAAgAGEgMlBBkKDAoFBAACAAESAyUa
MQoMCgUEAAIAAxIDJTQ1CioKBAQAAgESAygELhodIE1ldGFkYXRhIG9mIHRoZSBmbG93IHRy
YWNlLgoKDAoFBAACAQYSAygEFQoMCgUEAAIBARIDKBYpCgwKBQQAAgEDEgMoLC0KTAoEBAAC
AhIDKwQ8Gj8gTWV0YWRhdGEgb2YgdGhlIHNwZWVjaC10by10ZXh0IGFuZCBzcGVlY2gtdG8t
dGV4dCBwcm9jZXNzaW5nLgoKDAoFBAACAgYSAysEHAoMCgUEAAICARIDKx03CgwKBQQAAgID
EgMrOjsKUwoEBAACAxIDLwIeGkYgVGhlIGFjdGlvbnMgcGVyZm9ybWVkIGJ5IHRoZSBhZ2Vu
dCBhbmQgdGhlIHVzZXIgZHVyaW5nIHRoaXMgc2Vzc2lvbi4KCgwKBQQAAgMEEgMvAgoKDAoF
BAACAwYSAy8LEQoMCgUEAAIDARIDLxIZCgwKBQQAAgMDEgMvHB0KRwoEBAACBBIEMgIzMho5
IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgb2YgdGhlIHN0YXJ0IG9mIHRoZSB0cmFjZSBibG9j
ay4KCgwKBQQAAgQGEgMyAhsKDAoFBAACBAESAzIcJgoMCgUEAAIEAxIDMikqCgwKBQQAAgQI
EgMzBjEKDwoIBAACBAicCAASAzMHMApFCgQEAAIFEgQ2AjcyGjcgT3V0cHV0IG9ubHkuIFRp
bWVzdGFtcCBvZiB0aGUgZW5kIG9mIHRoZSB0cmFjZSBibG9jay4KCgwKBQQAAgUGEgM2AhsK
DAoFBAACBQESAzYcKQoMCgUEAAIFAxIDNiwtCgwKBQQAAgUIEgM3BjEKDwoIBAACBQicCAAS
AzcHMApICgQEAAIGEgQ6AjsvGjogT3B0aW9uYWwuIEEgbGlzdCBvZiBpbnB1dCBwYXJhbWV0
ZXJzIG9mIHRoZSB0cmFjZSBibG9jay4KCgwKBQQAAgYGEgM6AhgKDAoFBAACBgESAzoZKQoM
CgUEAAIGAxIDOiwtCgwKBQQAAgYIEgM7Bi4KDwoIBAACBgicCAASAzsHLQpJCgQEAAIHEgQ+
Aj8vGjsgT3B0aW9uYWwuIEEgbGlzdCBvZiBvdXRwdXQgcGFyYW1ldGVycyBvZiB0aGUgdHJh
Y2UgYmxvY2suCgoMCgUEAAIHBhIDPgIYCgwKBQQAAgcBEgM+GSoKDAoFBAACBwMSAz4tLgoM
CgUEAAIHCBIDPwYuCg8KCAQAAgcInAgAEgM/By0KSAoEBAACCBIEQgJFBBo6IE9wdGlvbmFs
LiBPdXRwdXQgb25seS4gVGhlIGVuZCBzdGF0ZSBvZiB0aGUgdHJhY2UgYmxvY2suCgoMCgUE
AAIIBhIDQgINCgwKBQQAAggBEgNCDhcKDAoFBAACCAMSA0IaGwoNCgUEAAIICBIEQhxFAwoP
CggEAAIICJwIABIDQwQtCg8KCAQAAggInAgBEgNEBCoKSwoCBAESBEkATAEaPyBNZXRhZGF0
YSBvZiB0aGUgc3BlZWNoLXRvLXRleHQgYW5kIHRleHQtdG8tc3BlZWNoIHByb2Nlc3Npbmcu
CgoKCgMEAQESA0kIIApGCgQEAQIAEgNLAkYaOSBPdXRwdXQgb25seS4gVGhlIGRpc3BsYXkg
bmFtZSBvZiB0aGUgc3BlZWNoIHByb2Nlc3NpbmcuCgoMCgUEAQIABRIDSwIICgwKBQQBAgAB
EgNLCRUKDAoFBAECAAMSA0sYGQoMCgUEAQIACBIDSxpFCg8KCAQBAgAInAgAEgNLG0QKLQoC
BAISBE8AXAEaISBNZXRhZGF0YSBvZiB0aGUgcGxheWJvb2sgdHJhY2UuCgoKCgMEAgESA08I
HQqiAQoEBAICABIEUwJYBBqTASBSZXF1aXJlZC4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9m
IHRoZSBwbGF5Ym9vay4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlv
bnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vcGxheWJvb2tzLzxQbGF5Ym9va0lE
PmAuCgoMCgUEAgIABRIDUwIICgwKBQQCAgABEgNTCREKDAoFBAICAAMSA1MUFQoNCgUEAgIA
CBIEUxZYAwoPCggEAgIACJwIABIDVAQqCg8KBwQCAgAInwgSBFUEVwUKPQoEBAICARIDWwJG
GjAgT3V0cHV0IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHBsYXlib29rLgoKDAoF
BAICAQUSA1sCCAoMCgUEAgIBARIDWwkVCgwKBQQCAgEDEgNbGBkKDAoFBAICAQgSA1saRQoP
CggEAgIBCJwIABIDWxtECikKAgQDEgRfAGoBGh0gTWV0YWRhdGEgb2YgdGhlIGZsb3cgdHJh
Y2UuCgoKCgMEAwESA18IGQqWAQoEBAMCABIEYwJmBBqHASBSZXF1aXJlZC4gVGhlIHVuaXF1
ZSBpZGVudGlmaWVyIG9mIHRoZSBmbG93LgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0
SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9mbG93cy88Rmxv
d0lEPmAuCgoMCgUEAwIABRIDYwIICgwKBQQDAgABEgNjCQ0KDAoFBAMCAAMSA2MQEQoNCgUE
AwIACBIEYxJmAwoPCggEAwIACJwIABIDZAQqCg4KBwQDAgAInwgSA2UEUAo5CgQEAwIBEgNp
AkYaLCBPdXRwdXQgb25seS4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgZmxvdy4KCgwKBQQD
AgEFEgNpAggKDAoFBAMCAQESA2kJFQoMCgUEAwIBAxIDaRgZCgwKBQQDAgEIEgNpGkUKDwoI
BAMCAQicCAASA2kbRAokCgIEBBIEbQByARoYIElucHV0IG9mIHRoZSBwbGF5Ym9vay4KCgoK
AwQEARIDbQgVCmoKBAQEAgASBHACcS8aXCBPcHRpb25hbC4gU3VtbWFyeSBzdHJpbmcgb2Yg
dGhlIHByZWNlZGluZyBjb252ZXJzYXRpb24gZm9yIHRoZSBjaGlsZAogcGxheWJvb2sgaW52
b2NhdGlvbi4KCgwKBQQEAgAFEgNwAggKDAoFBAQCAAESA3AJJwoMCgUEBAIAAxIDcCorCgwK
BQQEAgAIEgNxBi4KDwoIBAQCAAicCAASA3EHLQolCgIEBRIEdQB4ARoZIE91dHB1dCBvZiB0
aGUgcGxheWJvb2suCgoKCgMEBQESA3UIFgpWCgQEBQIAEgN3AkgaSSBPcHRpb25hbC4gU3Vt
bWFyeSBzdHJpbmcgb2YgdGhlIGV4ZWN1dGlvbiByZXN1bHQgb2YgdGhlIGNoaWxkIHBsYXli
b29rLgoKDAoFBAUCAAUSA3cCCAoMCgUEBQIAARIDdwkaCgwKBQQFAgADEgN3HR4KDAoFBAUC
AAgSA3cfRwoPCggEBQIACJwIABIDdyBGClQKAgQGEgV7AJoBARpHIEFjdGlvbiBwZXJmb3Jt
ZWQgYnkgZW5kIHVzZXIgb3IgRGlhbG9nZmxvdyBhZ2VudCBpbiB0aGUgY29udmVyc2F0aW9u
LgoKCgoDBAYBEgN7CA4KIAoEBAYIABIFfQKZAQMaESBBY3Rpb24gZGV0YWlscy4KCgwKBQQG
CAABEgN9CA4KRAoEBAYCABIDfwROGjcgT3B0aW9uYWwuIEFnZW50IG9idGFpbmVkIGEgbWVz
c2FnZSBmcm9tIHRoZSBjdXN0b21lci4KCgwKBQQGAgAGEgN/BBEKDAoFBAYCAAESA38SIAoM
CgUEBgIAAxIDfyMkCgwKBQQGAgAIEgN/JU0KDwoIBAYCAAicCAASA38mTApFCgQEBgIBEgSC
AQRQGjcgT3B0aW9uYWwuIEFjdGlvbiBwZXJmb3JtZWQgYnkgdGhlIGFnZW50IGFzIGEgbWVz
c2FnZS4KCg0KBQQGAgEGEgSCAQQSCg0KBQQGAgEBEgSCARMiCg0KBQQGAgEDEgSCASUmCg0K
BQQGAgEIEgSCASdPChAKCAQGAgEInAgAEgSCAShOClwKBAQGAgISBIYBBEIaTiBPcHRpb25h
bC4gQWN0aW9uIHBlcmZvcm1lZCBvbiBiZWhhbGYgb2YgdGhlIGFnZW50IGJ5IGNhbGxpbmcg
YSBwbHVnaW4KIHRvb2wuCgoNCgUEBgICBhIEhgEECwoNCgUEBgICARIEhgEMFAoNCgUEBgIC
AxIEhgEXGAoNCgUEBgICCBIEhgEZQQoQCggEBgICCJwIABIEhgEaQApiCgQEBgIDEgaKAQSL
ATEaUiBPcHRpb25hbC4gQWN0aW9uIHBlcmZvcm1lZCBvbiBiZWhhbGYgb2YgdGhlIGFnZW50
IGJ5IGludm9raW5nIGEgY2hpbGQKIHBsYXlib29rLgoKDQoFBAYCAwYSBIoBBBYKDQoFBAYC
AwESBIoBFyoKDQoFBAYCAwMSBIoBLS4KDQoFBAYCAwgSBIsBCDAKEAoIBAYCAwicCAASBIsB
CS8KWAoEBAYCBBIEjgEEUBpKIE9wdGlvbmFsLiBBY3Rpb24gcGVyZm9ybWVkIG9uIGJlaGFs
ZiBvZiB0aGUgYWdlbnQgYnkgaW52b2tpbmcgYSBDWCBmbG93LgoKDQoFBAYCBAYSBI4BBBIK
DQoFBAYCBAESBI4BEyIKDQoFBAYCBAMSBI4BJSYKDQoFBAYCBAgSBI4BJ08KEAoIBAYCBAic
CAASBI4BKE4KawoEBAYCBRIGkgEEkwExGlsgT3B0aW9uYWwuIEFjdGlvbiBwZXJmb3JtZWQg
b24gYmVoYWxmIG9mIHRoZSBhZ2VudCBieSB0cmFuc2l0aW9uaW5nIHRvIGEKIHRhcmdldCBw
bGF5Ym9vay4KCg0KBQQGAgUGEgSSAQQWCg0KBQQGAgUBEgSSARcqCg0KBQQGAgUDEgSSAS0v
Cg0KBQQGAgUIEgSTAQgwChAKCAQGAgUInAgAEgSTAQkvCmoKBAQGAgYSBpcBBJgBMRpaIE9w
dGlvbmFsLiBBY3Rpb24gcGVyZm9ybWVkIG9uIGJlaGFsZiBvZiB0aGUgYWdlbnQgYnkgdHJh
bnNpdGlvbmluZyB0byBhCiB0YXJnZXQgQ1ggZmxvdy4KCg0KBQQGAgYGEgSXAQQSCg0KBQQG
AgYBEgSXARMiCg0KBQQGAgYDEgSXASUnCg0KBQQGAgYIEgSYAQgwChAKCAQGAgYInAgAEgSY
AQkvCkoKAgQHEgadAQCgAQEaPCBVc2VyVXR0ZXJhbmNlIHJlcHJlc2VudHMgb25lIG1lc3Nh
Z2Ugc2VudCBieSB0aGUgY3VzdG9tZXIuCgoLCgMEBwESBJ0BCBUKMgoEBAcCABIEnwECOxok
IFJlcXVpcmVkLiBNZXNzYWdlIGNvbnRlbnQgaW4gdGV4dC4KCg0KBQQHAgAFEgSfAQIICg0K
BQQHAgABEgSfAQkNCg0KBQQHAgADEgSfARARCg0KBQQHAgAIEgSfARI6ChAKCAQHAgAInAgA
EgSfARM5CkgKAgQIEgajAQCmAQEaOiBBZ2VudFV0dGVyYW5jZSByZXByZXNlbnRzIG9uZSBt
ZXNzYWdlIHNlbnQgYnkgdGhlIGFnZW50LgoKCwoDBAgBEgSjAQgWCjIKBAQIAgASBKUBAjsa
JCBSZXF1aXJlZC4gTWVzc2FnZSBjb250ZW50IGluIHRleHQuCgoNCgUECAIABRIEpQECCAoN
CgUECAIAARIEpQEJDQoNCgUECAIAAxIEpQEQEQoNCgUECAIACBIEpQESOgoQCggECAIACJwI
ABIEpQETOQpTCgIECRIGqQEAvwEBGkUgU3RvcmVzIG1ldGFkYXRhIG9mIHRoZSBpbnZvY2F0
aW9uIG9mIGFuIGFjdGlvbiBzdXBwb3J0ZWQgYnkgYSB0b29sLgoKCwoDBAkBEgSpAQgPCrkB
CgQECQIAEgatAQKwAQQaqAEgUmVxdWlyZWQuIFRoZSBbdG9vbF1bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cuY3gudjMuVG9vbF0gdGhhdCBzaG91bGQgYmUKIHVzZWQuIEZvcm1hdDoKIGBw
cm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdl
bnRJRD4vdG9vbHMvPFRvb2xJRD5gLgoKDQoFBAkCAAUSBK0BAggKDQoFBAkCAAESBK0BCQ0K
DQoFBAkCAAMSBK0BEBEKDwoFBAkCAAgSBq0BErABAwoQCggECQIACJwIABIErgEEKgoPCgcE
CQIACJ8IEgSvAQRQCjoKBAQJAgESBLMBAkYaLCBPdXRwdXQgb25seS4gVGhlIGRpc3BsYXkg
bmFtZSBvZiB0aGUgdG9vbC4KCg0KBQQJAgEFEgSzAQIICg0KBQQJAgEBEgSzAQkVCg0KBQQJ
AgEDEgSzARgZCg0KBQQJAgEIEgSzARpFChAKCAQJAgEInAgAEgSzARtECk4KBAQJAgISBLYB
Aj0aQCBPcHRpb25hbC4gTmFtZSBvZiB0aGUgYWN0aW9uIHRvIGJlIGNhbGxlZCBkdXJpbmcg
dGhlIHRvb2wgdXNlLgoKDQoFBAkCAgUSBLYBAggKDQoFBAkCAgESBLYBCQ8KDQoFBAkCAgMS
BLYBEhMKDQoFBAkCAggSBLYBFDwKEAoIBAkCAgicCAASBLYBFTsKRgoEBAkCAxIGuQECugEv
GjYgT3B0aW9uYWwuIEEgbGlzdCBvZiBpbnB1dCBwYXJhbWV0ZXJzIGZvciB0aGUgYWN0aW9u
LgoKDQoFBAkCAwYSBLkBAhgKDQoFBAkCAwESBLkBGTAKDQoFBAkCAwMSBLkBMzQKDQoFBAkC
AwgSBLoBBi4KEAoIBAkCAwicCAASBLoBBy0KUAoEBAkCBBIGvQECvgEvGkAgT3B0aW9uYWwu
IEEgbGlzdCBvZiBvdXRwdXQgcGFyYW1ldGVycyBnZW5lcmF0ZWQgYnkgdGhlIGFjdGlvbi4K
Cg0KBQQJAgQGEgS9AQIYCg0KBQQJAgQBEgS9ARkxCg0KBQQJAgQDEgS9ATQ1Cg0KBQQJAgQI
EgS+AQYuChAKCAQJAgQInAgAEgS+AQctCkYKAgQKEgbCAQDYAQEaOCBTdG9yZXMgbWV0YWRh
dGEgb2YgdGhlIGludm9jYXRpb24gb2YgYSBjaGlsZCBwbGF5Ym9vay4KCgsKAwQKARIEwgEI
GgqkAQoEBAoCABIGxgECywEEGpMBIFJlcXVpcmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIg
b2YgdGhlIHBsYXlib29rLgogRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0
aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi9wbGF5Ym9va3MvPFBsYXlib29r
SUQ+YC4KCg0KBQQKAgAFEgTGAQIICg0KBQQKAgABEgTGAQkRCg0KBQQKAgADEgTGARQVCg8K
BQQKAgAIEgbGARbLAQMKEAoIBAoCAAicCAASBMcBBCoKEQoHBAoCAAifCBIGyAEEygEFCj4K
BAQKAgESBM4BAkYaMCBPdXRwdXQgb25seS4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgcGxh
eWJvb2suCgoNCgUECgIBBRIEzgECCAoNCgUECgIBARIEzgEJFQoNCgUECgIBAxIEzgEYGQoN
CgUECgIBCBIEzgEaRQoQCggECgIBCJwIABIEzgEbRApBCgQECgICEgTRAQJMGjMgT3B0aW9u
YWwuIElucHV0IG9mIHRoZSBjaGlsZCBwbGF5Ym9vayBpbnZvY2F0aW9uLgoKDQoFBAoCAgYS
BNEBAg8KDQoFBAoCAgESBNEBEB4KDQoFBAoCAgMSBNEBISIKDQoFBAoCAggSBNEBI0sKEAoI
BAoCAgicCAASBNEBJEoKQgoEBAoCAxIE1AECTho0IE9wdGlvbmFsLiBPdXRwdXQgb2YgdGhl
IGNoaWxkIHBsYXlib29rIGludm9jYXRpb24uCgoNCgUECgIDBhIE1AECEAoNCgUECgIDARIE
1AERIAoNCgUECgIDAxIE1AEjJAoNCgUECgIDCBIE1AElTQoQCggECgIDCJwIABIE1AEmTAo9
CgQECgIEEgTXAQJKGi8gUmVxdWlyZWQuIFBsYXlib29rIGludm9jYXRpb24ncyBvdXRwdXQg
c3RhdGUuCgoNCgUECgIEBhIE1wECDQoNCgUECgIEARIE1wEOHAoNCgUECgIEAxIE1wEfIAoN
CgUECgIECBIE1wEhSQoQCggECgIECJwIABIE1wEiSAo/CgIECxIG2wEA6QEBGjEgU3RvcmVz
IG1ldGFkYXRhIG9mIHRoZSBpbnZvY2F0aW9uIG9mIGEgQ1ggZmxvdy4KCgsKAwQLARIE2wEI
FgqYAQoEBAsCABIG3wEC4gEEGocBIFJlcXVpcmVkLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIg
b2YgdGhlIGZsb3cuCiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3RJRD4vbG9jYXRpb25z
LzxMb2NhdGlvbklEPi9hZ2VudHMvPEFnZW50SUQ+L2Zsb3dzLzxGbG93SUQ+YC4KCg0KBQQL
AgAFEgTfAQIICg0KBQQLAgABEgTfAQkNCg0KBQQLAgADEgTfARARCg8KBQQLAgAIEgbfARLi
AQMKEAoIBAsCAAicCAASBOABBCoKDwoHBAsCAAifCBIE4QEEUAo6CgQECwIBEgTlAQJGGiwg
T3V0cHV0IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGZsb3cuCgoNCgUECwIBBRIE
5QECCAoNCgUECwIBARIE5QEJFQoNCgUECwIBAxIE5QEYGQoNCgUECwIBCBIE5QEaRQoQCggE
CwIBCJwIABIE5QEbRAo5CgQECwICEgToAQJGGisgUmVxdWlyZWQuIEZsb3cgaW52b2NhdGlv
bidzIG91dHB1dCBzdGF0ZS4KCg0KBQQLAgIGEgToAQINCg0KBQQLAgIBEgToAQ4YCg0KBQQL
AgIDEgToARscCg0KBQQLAgIIEgToAR1FChAKCAQLAgIInAgAEgToAR5ECqMBCgIEDBIG7QEA
+gEBGpQBIFN0b3JlcyBtZXRhZGF0YSBvZiB0aGUgdHJhbnNpdGlvbiB0byBhbm90aGVyIHRh
cmdldCBwbGF5Ym9vay4gUGxheWJvb2sKIHRyYW5zaXRpb24gYWN0aW9ucyBleGl0IHRoZSBj
YWxsZXIgcGxheWJvb2sgYW5kIGVudGVyIHRoZSB0YXJnZXQgcGxheWJvb2suCgoLCgMEDAES
BO0BCBoKpAEKBAQMAgASBvEBAvYBBBqTASBSZXF1aXJlZC4gVGhlIHVuaXF1ZSBpZGVudGlm
aWVyIG9mIHRoZSBwbGF5Ym9vay4KIEZvcm1hdDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9s
b2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50cy88QWdlbnRJRD4vcGxheWJvb2tzLzxQbGF5
Ym9va0lEPmAuCgoNCgUEDAIABRIE8QECCAoNCgUEDAIAARIE8QEJEQoNCgUEDAIAAxIE8QEU
FQoPCgUEDAIACBIG8QEW9gEDChAKCAQMAgAInAgAEgTyAQQqChEKBwQMAgAInwgSBvMBBPUB
BQo+CgQEDAIBEgT5AQJGGjAgT3V0cHV0IG9ubHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhl
IHBsYXlib29rLgoKDQoFBAwCAQUSBPkBAggKDQoFBAwCAQESBPkBCRUKDQoFBAwCAQMSBPkB
GBkKDQoFBAwCAQgSBPkBGkUKEAoIBAwCAQicCAASBPkBG0QKkwEKAgQNEgb+AQCJAgEahAEg
U3RvcmVzIG1ldGFkYXRhIG9mIHRoZSB0cmFuc2l0aW9uIHRvIGEgdGFyZ2V0IENYIGZsb3cu
IEZsb3cgdHJhbnNpdGlvbgogYWN0aW9ucyBleGl0IHRoZSBjYWxsZXIgcGxheWJvb2sgYW5k
IGVudGVyIHRoZSBjaGlsZCBmbG93LgoKCwoDBA0BEgT+AQgWCpQBCgQEDQIAEgaCAgKFAgQa
gwEgUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgZmxvdy4KIEZvcm1h
dDoKIGBwcm9qZWN0cy88UHJvamVjdElEPi9sb2NhdGlvbnMvPExvY2F0aW9uSUQ+L2FnZW50
cy88QWdlbnRmbG93cy88Rmxvd0lEPmAuCgoNCgUEDQIABRIEggICCAoNCgUEDQIAARIEggIJ
DQoNCgUEDQIAAxIEggIQEQoPCgUEDQIACBIGggIShQIDChAKCAQNAgAInAgAEgSDAgQqCg8K
BwQNAgAInwgSBIQCBFAKOgoEBA0CARIEiAICRhosIE91dHB1dCBvbmx5LiBUaGUgZGlzcGxh
eSBuYW1lIG9mIHRoZSBmbG93LgoKDQoFBA0CAQUSBIgCAggKDQoFBA0CAQESBIgCCRUKDQoF
BA0CAQMSBIgCGBkKDQoFBA0CAQgSBIgCGkUKEAoIBA0CAQicCAASBIgCG0QKHQoCBQASBowC
AJ4CARoPIE91dHB1dCBzdGF0ZS4KCgsKAwUAARIEjAIFEAojCgQFAAIAEgSOAgIfGhUgVW5z
cGVjaWZpZWQgb3V0cHV0LgoKDQoFBQACAAESBI4CAhoKDQoFBQACAAISBI4CHR4KGgoEBQAC
ARIEkQICFhoMIFN1Y2NlZWRlZC4KCg0KBQUAAgEBEgSRAgIRCg0KBQUAAgECEgSRAhQVChoK
BAUAAgISBJQCAh0aDCBDYW5jZWxsZWQuCgoNCgUFAAICARIElAICGAoNCgUFAAICAhIElAIb
HAoXCgQFAAIDEgSXAgIaGgkgRmFpbGVkLgoKDQoFBQACAwESBJcCAhUKDQoFBQACAwISBJcC
GBkKGgoEBQACBBIEmgICHRoMIEVzY2FsYXRlZC4KCg0KBQUAAgQBEgSaAgIYCg0KBQUAAgQC
EgSaAhscChgKBAUAAgUSBJ0CAhsaCiBQZW5kaW5nLgoKDQoFBQACBQESBJ0CAhYKDQoFBQAC
BQISBJ0CGRpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::TraceBlock ===
    # Fields for TraceBlock
    # Field: playbook_trace_metadata Type: 11 (.google.cloud.dialogflow.cx.v3.PlaybookTraceMetadata)
    # Field: flow_trace_metadata Type: 11 (.google.cloud.dialogflow.cx.v3.FlowTraceMetadata)
    # Field: speech_processing_metadata Type: 11 (.google.cloud.dialogflow.cx.v3.SpeechProcessingMetadata)
    # Field: actions Type: 11 (.google.cloud.dialogflow.cx.v3.Action)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: complete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: input_parameters Type: 11 (.google.protobuf.Struct)
    # Field: output_parameters Type: 11 (.google.protobuf.Struct)
    # Field: end_state Type: 14 (.google.cloud.dialogflow.cx.v3.OutputState)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::SpeechProcessingMetadata ===
    # Fields for SpeechProcessingMetadata
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTraceMetadata ===
    # Fields for PlaybookTraceMetadata
    # Field: playbook Type: 9 ()
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTraceMetadata ===
    # Fields for FlowTraceMetadata
    # Field: flow Type: 9 ()
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInput ===
    # Fields for PlaybookInput
    # Field: preceding_conversation_summary Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookOutput ===
    # Fields for PlaybookOutput
    # Field: execution_summary Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::Action ===
    # Fields for Action
    # Field: user_utterance Type: 11 (.google.cloud.dialogflow.cx.v3.UserUtterance)
    # Field: agent_utterance Type: 11 (.google.cloud.dialogflow.cx.v3.AgentUtterance)
    # Field: tool_use Type: 11 (.google.cloud.dialogflow.cx.v3.ToolUse)
    # Field: playbook_invocation Type: 11 (.google.cloud.dialogflow.cx.v3.PlaybookInvocation)
    # Field: flow_invocation Type: 11 (.google.cloud.dialogflow.cx.v3.FlowInvocation)
    # Field: playbook_transition Type: 11 (.google.cloud.dialogflow.cx.v3.PlaybookTransition)
    # Field: flow_transition Type: 11 (.google.cloud.dialogflow.cx.v3.FlowTransition)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::UserUtterance ===
    # Fields for UserUtterance
    # Field: text Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::AgentUtterance ===
    # Fields for AgentUtterance
    # Field: text Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::ToolUse ===
    # Fields for ToolUse
    # Field: tool Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: action Type: 9 ()
    # Field: input_action_parameters Type: 11 (.google.protobuf.Struct)
    # Field: output_action_parameters Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInvocation ===
    # Fields for PlaybookInvocation
    # Field: playbook Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: playbook_input Type: 11 (.google.cloud.dialogflow.cx.v3.PlaybookInput)
    # Field: playbook_output Type: 11 (.google.cloud.dialogflow.cx.v3.PlaybookOutput)
    # Field: playbook_state Type: 14 (.google.cloud.dialogflow.cx.v3.OutputState)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::FlowInvocation ===
    # Fields for FlowInvocation
    # Field: flow Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: flow_state Type: 14 (.google.cloud.dialogflow.cx.v3.OutputState)

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTransition ===
    # Fields for PlaybookTransition
    # Field: playbook Type: 9 ()
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTransition ===
    # Fields for FlowTransition
    # Field: flow Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Trace - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/trace.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::Trace;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::Trace::TraceBlock->new({
        playbook_trace_metadata => $playbook_trace_metadata,
        flow_trace_metadata => $flow_trace_metadata,
        speech_processing_metadata => $speech_processing_metadata,
        actions => $actions,
    });

    # Read or update a field
    my $val = $msg->playbook_trace_metadata();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::Trace::TraceBlock->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/trace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::TraceBlock

The trace block tracks a sequence of actions taken by the agent in a flow or
a playbook.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->playbook_trace_metadata() >> / C<< $msg->playbook_trace_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTraceMetadata>)

Metadata of the playbook trace.

=item * C<< $msg->flow_trace_metadata() >> / C<< $msg->flow_trace_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTraceMetadata>)

Metadata of the flow trace.

=item * C<< $msg->speech_processing_metadata() >> / C<< $msg->speech_processing_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::SpeechProcessingMetadata>)

Metadata of the speech-to-text and speech-to-text processing.

=item * C<< $msg->actions() >> / C<< $msg->actions($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::Action>)

The actions performed by the agent and the user during this session.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the start of the trace block.

=item * C<< $msg->complete_time() >> / C<< $msg->complete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of the end of the trace block.

=item * C<< $msg->input_parameters() >> / C<< $msg->input_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. A list of input parameters of the trace block.

=item * C<< $msg->output_parameters() >> / C<< $msg->output_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. A list of output parameters of the trace block.

=item * C<< $msg->end_state() >> / C<< $msg->end_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::OutputState>)

Optional. Output only. The end state of the trace block.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::SpeechProcessingMetadata

Metadata of the speech-to-text and text-to-speech processing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the speech processing.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTraceMetadata

Metadata of the playbook trace.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->playbook() >> / C<< $msg->playbook($value) >>

Type: C<String>

Required. The unique identifier of the playbook.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the playbook.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTraceMetadata

Metadata of the flow trace.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->flow() >> / C<< $msg->flow($value) >>

Type: C<String>

Required. The unique identifier of the flow.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the flow.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInput

Input of the playbook.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->preceding_conversation_summary() >> / C<< $msg->preceding_conversation_summary($value) >>

Type: C<String>

Optional. Summary string of the preceding conversation for the child
playbook invocation.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookOutput

Output of the playbook.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->execution_summary() >> / C<< $msg->execution_summary($value) >>

Type: C<String>

Optional. Summary string of the execution result of the child playbook.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::Action

Action performed by end user or Dialogflow agent in the conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_utterance() >> / C<< $msg->user_utterance($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::UserUtterance>)

Optional. Agent obtained a message from the customer.

=item * C<< $msg->agent_utterance() >> / C<< $msg->agent_utterance($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::AgentUtterance>)

Optional. Action performed by the agent as a message.

=item * C<< $msg->tool_use() >> / C<< $msg->tool_use($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::ToolUse>)

Optional. Action performed on behalf of the agent by calling a plugin
tool.

=item * C<< $msg->playbook_invocation() >> / C<< $msg->playbook_invocation($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInvocation>)

Optional. Action performed on behalf of the agent by invoking a child
playbook.

=item * C<< $msg->flow_invocation() >> / C<< $msg->flow_invocation($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::FlowInvocation>)

Optional. Action performed on behalf of the agent by invoking a CX flow.

=item * C<< $msg->playbook_transition() >> / C<< $msg->playbook_transition($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTransition>)

Optional. Action performed on behalf of the agent by transitioning to a
target playbook.

=item * C<< $msg->flow_transition() >> / C<< $msg->flow_transition($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTransition>)

Optional. Action performed on behalf of the agent by transitioning to a
target CX flow.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::UserUtterance

UserUtterance represents one message sent by the customer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. Message content in text.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::AgentUtterance

AgentUtterance represents one message sent by the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. Message content in text.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::ToolUse

Stores metadata of the invocation of an action supported by a tool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Required. The [tool][google.cloud.dialogflow.cx.v3.Tool] that should be
used. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/tools/<ToolID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the tool.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Optional. Name of the action to be called during the tool use.

=item * C<< $msg->input_action_parameters() >> / C<< $msg->input_action_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. A list of input parameters for the action.

=item * C<< $msg->output_action_parameters() >> / C<< $msg->output_action_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. A list of output parameters generated by the action.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInvocation

Stores metadata of the invocation of a child playbook.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->playbook() >> / C<< $msg->playbook($value) >>

Type: C<String>

Required. The unique identifier of the playbook.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the playbook.

=item * C<< $msg->playbook_input() >> / C<< $msg->playbook_input($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInput>)

Optional. Input of the child playbook invocation.

=item * C<< $msg->playbook_output() >> / C<< $msg->playbook_output($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookOutput>)

Optional. Output of the child playbook invocation.

=item * C<< $msg->playbook_state() >> / C<< $msg->playbook_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::OutputState>)

Required. Playbook invocation's output state.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::FlowInvocation

Stores metadata of the invocation of a CX flow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->flow() >> / C<< $msg->flow($value) >>

Type: C<String>

Required. The unique identifier of the flow.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/flows/<FlowID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the flow.

=item * C<< $msg->flow_state() >> / C<< $msg->flow_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::Cx::V3::OutputState>)

Required. Flow invocation's output state.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTransition

Stores metadata of the transition to another target playbook. Playbook
transition actions exit the caller playbook and enter the target playbook.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->playbook() >> / C<< $msg->playbook($value) >>

Type: C<String>

Required. The unique identifier of the playbook.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/playbooks/<PlaybookID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the playbook.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTransition

Stores metadata of the transition to a target CX flow. Flow transition
actions exit the caller playbook and enter the child flow.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->flow() >> / C<< $msg->flow($value) >>

Type: C<String>

Required. The unique identifier of the flow.
Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<Agentflows/<FlowID>`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the flow.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::Trace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
