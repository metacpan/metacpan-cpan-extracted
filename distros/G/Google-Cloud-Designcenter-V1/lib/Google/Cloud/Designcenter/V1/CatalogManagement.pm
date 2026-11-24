package Google::Cloud::Designcenter::V1::CatalogManagement;

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
    eval { require Google::Cloud::Designcenter::V1::Authoring };
    eval { require Google::Cloud::Designcenter::V1::Enums };
    eval { require Google::Cloud::Designcenter::V1::Ingestion };
    eval { require Google::Cloud::Designcenter::V1::Metadata };
    eval { require Google::Cloud::Designcenter::V1::Parameters };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2NhdGFsb2dfbWFuYWdlbWVudC5wcm90
bxIcZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2Nsb3VkL2Rl
c2lnbmNlbnRlci92MS9hdXRob3JpbmcucHJvdG8aKGdvb2dsZS9jbG91ZC9kZXNpZ25jZW50
ZXIvdjEvZW51bXMucHJvdG8aLGdvb2dsZS9jbG91ZC9kZXNpZ25jZW50ZXIvdjEvaW5nZXN0
aW9uLnByb3RvGitnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL21ldGFkYXRhLnByb3Rv
Gi1nb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL3BhcmFtZXRlcnMucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i9gQKBVNwYWNlEhcKBG5hbWUYASABKAlCA+BB
CFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVz
Y3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24SQAoLY3JlYXRlX3RpbWUYBCABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRl
X3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRp
bWUSRwobZW5hYmxlX2djcF9zaGFyZWRfdGVtcGxhdGVzGAYgASgIQgPgQQFIAFIYZW5hYmxl
R2NwU2hhcmVkVGVtcGxhdGVziAEBEiIKCmdjc19idWNrZXQYByABKAlCA+BBAVIJZ2NzQnVj
a2V0EkwKBHRhZ3MYCCADKAsyLS5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLlNwYWNl
LlRhZ3NFbnRyeUIJ4EEE4EEF4EEBUgR0YWdzGjcKCVRhZ3NFbnRyeRIQCgNrZXkYASABKAlS
A2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOm3qQWoKIWRlc2lnbmNlbnRlci5nb29n
bGVhcGlzLmNvbS9TcGFjZRI2cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L3NwYWNlcy97c3BhY2V9KgZzcGFjZXMyBXNwYWNlQh4KHF9lbmFibGVfZ2NwX3NoYXJl
ZF90ZW1wbGF0ZXMi/wIKB0NhdGFsb2cSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRp
c3BsYXlfbmFtZRgCIAEoCUID4EEBUgtkaXNwbGF5TmFtZRIlCgtkZXNjcmlwdGlvbhgDIAEo
CUID4EEBUgtkZXNjcmlwdGlvbhJACgtjcmVhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgFIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZTqHAepBgwEKI2Rl
c2lnbmNlbnRlci5nb29nbGVhcGlzLmNvbS9DYXRhbG9nEklwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vc3BhY2VzL3tzcGFjZX0vY2F0YWxvZ3Mve2NhdGFsb2d9
KghjYXRhbG9nczIHY2F0YWxvZyKvBQoPQ2F0YWxvZ1RlbXBsYXRlEhcKBG5hbWUYASABKAlC
A+BBCFIEbmFtZRImCgxkaXNwbGF5X25hbWUYByABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoL
ZGVzY3JpcHRpb24YAiABKAlCA+BBAVILZGVzY3JpcHRpb24SFwoEdXVpZBgFIAEoCUID4EED
UgR1dWlkEkAKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEjEKEmxhdGVzdF9yZXZpc2lvbl9pZBgG
IAEoCUID4EEDUhBsYXRlc3RSZXZpc2lvbklkEmAKEXRlbXBsYXRlX2NhdGVnb3J5GAggASgO
Mi4uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5UZW1wbGF0ZUNhdGVnb3J5QgPgQQJS
EHRlbXBsYXRlQ2F0ZWdvcnkSQwoEdHlwZRgJIAEoDjIqLmdvb2dsZS5jbG91ZC5kZXNpZ25j
ZW50ZXIudjEuVGVtcGxhdGVUeXBlQgPgQQFSBHR5cGU6vAHqQbgBCitkZXNpZ25jZW50ZXIu
Z29vZ2xlYXBpcy5jb20vQ2F0YWxvZ1RlbXBsYXRlEmZwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vc3BhY2VzL3tzcGFjZX0vY2F0YWxvZ3Mve2NhdGFsb2d9L3Rl
bXBsYXRlcy97Y2F0YWxvZ190ZW1wbGF0ZX0qEGNhdGFsb2dUZW1wbGF0ZXMyD2NhdGFsb2dU
ZW1wbGF0ZSLKEgoXQ2F0YWxvZ1RlbXBsYXRlUmV2aXNpb24STQoKZ2l0X3NvdXJjZRgFIAEo
CzInLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuR2l0U291cmNlQgPgQQFIAFIJZ2l0
U291cmNlEi0KDmdjc19zb3VyY2VfdXJpGBQgASgJQgUYAeBBAUgAUgxnY3NTb3VyY2VVcmkS
kgEKJGFwcGxpY2F0aW9uX3RlbXBsYXRlX3JldmlzaW9uX3NvdXJjZRgLIAEoCUI/4EEB+kE5
CjdkZXNpZ25jZW50ZXIuZ29vZ2xlYXBpcy5jb20vQXBwbGljYXRpb25UZW1wbGF0ZVJldmlz
aW9uSABSIWFwcGxpY2F0aW9uVGVtcGxhdGVSZXZpc2lvblNvdXJjZRKIAQofZGV2ZWxvcGVy
X2Nvbm5lY3Rfc291cmNlX2NvbmZpZxgPIAEoCzI6Lmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50
ZXIudjEuRGV2ZWxvcGVyQ29ubmVjdFNvdXJjZUNvbmZpZ0ID4EEBSABSHGRldmVsb3BlckNv
bm5lY3RTb3VyY2VDb25maWcSRwoIb2NpX3JlcG8YESABKAsyJS5nb29nbGUuY2xvdWQuZGVz
aWduY2VudGVyLnYxLk9jaVJlcG9CA+BBAUgAUgdvY2lSZXBvEhcKBG5hbWUYASABKAlCA+BB
CFIEbmFtZRIlCgtkZXNjcmlwdGlvbhgOIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJDCgR0eXBl
GAIgASgOMiouZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5UZW1wbGF0ZVR5cGVCA+BB
AVIEdHlwZRJACgtjcmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJjChF0ZW1wbGF0ZV9tZXRhZGF0YRgI
IAEoCzIxLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuVEZCbHVlcHJpbnRNZXRhZGF0
YUID4EEDUhB0ZW1wbGF0ZU1ldGFkYXRhElYKBXN0YXRlGAkgASgOMjsuZ29vZ2xlLmNsb3Vk
LmRlc2lnbmNlbnRlci52MS5DYXRhbG9nVGVtcGxhdGVSZXZpc2lvbi5TdGF0ZUID4EEDUgVz
dGF0ZRKEAQodYXBwbGljYXRpb25fdGVtcGxhdGVfcmV2aXNpb24YDCABKAsyOy5nb29nbGUu
Y2xvdWQuZGVzaWduY2VudGVyLnYxLlNlcmlhbGl6ZWRBcHBsaWNhdGlvblRlbXBsYXRlQgPg
QQNSG2FwcGxpY2F0aW9uVGVtcGxhdGVSZXZpc2lvbhJkChNoZWxtX2NoYXJ0X21ldGFkYXRh
GBAgASgLMi8uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5IZWxtQ2hhcnRNZXRhZGF0
YUID4EEDUhFoZWxtQ2hhcnRNZXRhZGF0YRIXCgR1dWlkGA0gASgJQgPgQQNSBHV1aWQSVwoO
bWV0YWRhdGFfaW5wdXQYEiABKAsyKy5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLk1l
dGFkYXRhSW5wdXRCA+BBAVINbWV0YWRhdGFJbnB1dBJgChF0ZW1wbGF0ZV9jYXRlZ29yeRgT
IAEoDjIuLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuVGVtcGxhdGVDYXRlZ29yeUID
4EEDUhB0ZW1wbGF0ZUNhdGVnb3J5ElwKEGxvZ2ljYWxfcHJvZHVjdHMYFSADKAsyLC5nb29n
bGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLkxvZ2ljYWxQcm9kdWN0QgPgQQNSD2xvZ2ljYWxQ
cm9kdWN0cxJtCgthbm5vdGF0aW9ucxgWIAMoCzJGLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50
ZXIudjEuQ2F0YWxvZ1RlbXBsYXRlUmV2aXNpb24uQW5ub3RhdGlvbnNFbnRyeUID4EEBUgth
bm5vdGF0aW9ucxJgChFpbmZlcnJlZF9tZXRhZGF0YRgXIAEoCzIuLmdvb2dsZS5jbG91ZC5k
ZXNpZ25jZW50ZXIudjEuSW5mZXJyZWRNZXRhZGF0YUID4EEDUhBpbmZlcnJlZE1ldGFkYXRh
ElYKDnJlc291cmNlX3R5cGVzGBggAygLMiouZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52
MS5SZXNvdXJjZVR5cGVCA+BBA1INcmVzb3VyY2VUeXBlcxJLCgppYWNfc291cmNlGBsgASgO
MicuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5JQUNTb3VyY2VCA+BBA1IJaWFjU291
cmNlEmMKFmFwcGxpY2F0aW9uX3BhcmFtZXRlcnMYHCADKAsyJy5nb29nbGUuY2xvdWQuZGVz
aWduY2VudGVyLnYxLlBhcmFtZXRlckID4EEBUhVhcHBsaWNhdGlvblBhcmFtZXRlcnMaPgoQ
QW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBIkcKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDgoKVkFMSURBVElORxAB
EgoKBkFDVElWRRACEgsKB0lOVkFMSUQQAzrpAepB5QEKM2Rlc2lnbmNlbnRlci5nb29nbGVh
cGlzLmNvbS9DYXRhbG9nVGVtcGxhdGVSZXZpc2lvbhJ7cHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L3NwYWNlcy97c3BhY2V9L2NhdGFsb2dzL3tjYXRhbG9nfS90
ZW1wbGF0ZXMve2NhdGFsb2dfdGVtcGxhdGV9L3JldmlzaW9ucy97cmV2aXNpb259KhhjYXRh
bG9nVGVtcGxhdGVSZXZpc2lvbnMyF2NhdGFsb2dUZW1wbGF0ZVJldmlzaW9uQhMKEWFydGlm
YWN0X2xvY2F0aW9uQusBCiBjb20uZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MUIfQ2F0
YWxvZ01hbmFnZW1lbnRSZXNvdXJjZXNQcm90b1ABWkRjbG91ZC5nb29nbGUuY29tL2dvL2Rl
c2lnbmNlbnRlci9hcGl2MS9kZXNpZ25jZW50ZXJwYjtkZXNpZ25jZW50ZXJwYqoCHEdvb2ds
ZS5DbG91ZC5EZXNpZ25DZW50ZXIuVjHKAhxHb29nbGVcQ2xvdWRcRGVzaWduQ2VudGVyXFYx
6gIfR29vZ2xlOjpDbG91ZDo6RGVzaWduQ2VudGVyOjpWMUrNTAoHEgUOAJwCAQq8BAoBDBID
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
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCgkKAgMB
EgMTACMKCQoCAwISAxQANgoJCgIDAxIDFQAyCgkKAgMEEgMWADYKCQoCAwUSAxcANQoJCgID
BhIDGAA3CgkKAgMHEgMZACkKCAoBCBIDGwA5CgkKAgglEgMbADkKCAoBCBIDHABbCgkKAggL
EgMcAFsKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgBACgkKAggIEgMeAEAKCAoBCBID
HwA5CgkKAggBEgMfADkKCAoBCBIDIAA5CgkKAggpEgMgADkKCAoBCBIDIQA4CgkKAggtEgMh
ADgKeAoCBAASBCUAWwEabCBTcGFjZSBpcyBhIHRvcCBsZXZlbCByZXNvdXJjZSBmb3IgbWFu
YWdpbmcgdGVhbXMgYnVpbGRpbmcgYXBwbGljYXRpb25zCiB0aHJvdWdoIEFwcGxpY2F0aW9u
IERlc2lnbiBDZW50ZXIuCgoKCgMEAAESAyUIDQoLCgMEAAcSBCYCKwQKDQoFBAAHnQgSBCYC
KwQKKgoEBAACABIDLgI9Gh0gSWRlbnRpZmllci4gVGhlIHNwYWNlIG5hbWUuCgoMCgUEAAIA
BRIDLgIICgwKBQQAAgABEgMuCQ0KDAoFBAACAAMSAy4QEQoMCgUEAAIACBIDLhI8Cg8KCAQA
AgAInAgAEgMuEzsKNAoEBAACARIDMQJDGicgT3B0aW9uYWwuIERpc3BsYXkgbmFtZSBmb3Ig
dGhlIHNwYWNlLgoKDAoFBAACAQUSAzECCAoMCgUEAAIBARIDMQkVCgwKBQQAAgEDEgMxGBkK
DAoFBAACAQgSAzEaQgoPCggEAAIBCJwIABIDMRtBCjMKBAQAAgISAzQCQhomIE9wdGlvbmFs
LiBEZXNjcmlwdGlvbiBmb3IgdGhlIHNwYWNlLgoKDAoFBAACAgUSAzQCCAoMCgUEAAICARID
NAkUCgwKBQQAAgIDEgM0FxgKDAoFBAACAggSAzQZQQoPCggEAAICCJwIABIDNBpACjYKBAQA
AgMSBDcCODIaKCBPdXRwdXQgb25seS4gU3BhY2UgY3JlYXRpb24gdGltZXN0YW1wLgoKDAoF
BAACAwYSAzcCGwoMCgUEAAIDARIDNxwnCgwKBQQAAgMDEgM3KisKDAoFBAACAwgSAzgGMQoP
CggEAAIDCJwIABIDOAcwCjMKBAQAAgQSBDsCPDIaJSBPdXRwdXQgb25seS4gU3BhY2UgdXBk
YXRlIHRpbWVzdGFtcAoKDAoFBAACBAYSAzsCGwoMCgUEAAIEARIDOxwnCgwKBQQAAgQDEgM7
KisKDAoFBAACBAgSAzwGMQoPCggEAAIECJwIABIDPAcwCk0KBAQAAgUSBD8CQC8aPyBPcHRp
b25hbC4gRmxhZyB0byBlbmFibGUgR29vZ2xlIG9waW5pb25hdGVkIHNoYXJlZCB0ZW1wbGF0
ZXMuCgoMCgUEAAIFBBIDPwIKCgwKBQQAAgUFEgM/Cw8KDAoFBAACBQESAz8QKwoMCgUEAAIF
AxIDPy4vCgwKBQQAAgUIEgNABi4KDwoIBAACBQicCAASA0AHLQrnBAoEBAACBhIDSwJBGtkE
IE9wdGlvbmFsLiBBbiBleGlzdGluZyBHb29nbGUgQ2xvdWQgU3RvcmFnZSBidWNrZXQgdGhh
dCB5b3Ugd2FudCB0byB1c2UKIGluc3RlYWQgb2YgY3JlYXRpbmcgYSBuZXcgYnVja2V0IGR1
cmluZyBBcHBsaWNhdGlvbiBEZXNpZ24gQ2VudGVyIHNldHVwLiBJZgogbm90IHByb3ZpZGVk
LCBhIGRlZmF1bHQgYnVja2V0IGlzIGNyZWF0ZWQgZHVyaW5nIHNldHVwLiBUaGUgYnVja2V0
IG11c3QKIGV4aXN0IGluIHRoZSBzYW1lIHByb2plY3QgYXMgdGhlIHNwYWNlLiBJZiB0aGUg
YnVja2V0IG5hbWUgZG9lcyBub3QgZXhpc3QKIGluIHRoZSBzYW1lIHByb2plY3QgYXMgdGhl
IHNwYWNlLCB0aGUgcmVxdWVzdCBmYWlscyB3aXRoIGFuCiBJTlZBTElEX0FSR1VNRU5UIGVy
cm9yLiBJZiB5b3UgZG8gbm90IGhhdmUgYWNjZXNzIHRvIHRoZSBidWNrZXQsIHRoZQogcmVx
dWVzdCBmYWlscyB3aXRoIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IuIEZvcm1hdDogeyRi
dWNrZXRfbmFtZX0gRm9yCiBleGFtcGxlLCBpZiB0aGUgQ2xvdWQgU3RvcmFnZSBidWNrZXQg
VVJJIGlzIGdzOlwvXC97JGJ1Y2tldF9uYW1lfSwgdGhlCiBmb3JtYXQgaXMgeyRidWNrZXRf
bmFtZX0uCgoMCgUEAAIGBRIDSwIICgwKBQQAAgYBEgNLCRMKDAoFBAACBgMSA0sWFwoMCgUE
AAIGCBIDSxhACg8KCAQAAgYInAgAEgNLGT8KtQIKBAQAAgcSBFYCWgQapgIgT3B0aW9uYWwu
IElucHV0IG9ubHkuIEltbXV0YWJsZS4gVGFncyBhcmUga2V5L3ZhbHVlcyBib3VuZCB0byBz
cGFjZQogcmVzb3VyY2UuIEV4YW1wbGU6CiBgYGAKICAgIjEyMy9lbnZpcm9ubWVudCI6ICJw
cm9kdWN0aW9uIgogICAiMTIzL2Nvc3RDZW50ZXIiOiAibWFya2V0aW5nIgogYGBgCgogRm9y
IG1vcmUgaW5mb3JtYXRpb24gb24gdGFnIGNyZWF0aW9uIGFuZCBtYW5hZ2VtZW50LCBzZWUK
IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvdGFncy90
YWdzLW92ZXJ2aWV3LgoKDAoFBAACBwYSA1YCFQoMCgUEAAIHARIDVhYaCgwKBQQAAgcDEgNW
HR4KDQoFBAACBwgSBFYfWgMKDwoIBAACBwicCAASA1cELAoPCggEAAIHCJwIARIDWAQrCg8K
CAQAAgcInAgCEgNZBCoKNQoCBAESBF4AdwEaKSBBIGNhdGFsb2cgaXMgYSBjb2xsZWN0aW9u
IG9mIHRlbXBsYXRlcy4KCgoKAwQBARIDXggPCgsKAwQBBxIEXwJkBAoNCgUEAQedCBIEXwJk
BAqOAQoEBAECABIDaAI9GoABIElkZW50aWZpZXIuIFRoZSBjYXRhbG9nIG5hbWUgaW4gdGhl
IGZvbGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2Nh
dGlvbi9zcGFjZXMvJHNwYWNlL2NhdGFsb2dzLyRjYXRhbG9nYAoKDAoFBAECAAUSA2gCCAoM
CgUEAQIAARIDaAkNCgwKBQQBAgADEgNoEBEKDAoFBAECAAgSA2gSPAoPCggEAQIACJwIABID
aBM7CjIKBAQBAgESA2sCQxolIE9wdGlvbmFsLiBUaGUgY2F0YWxvZyBkaXNwbGF5IG5hbWUu
CgoMCgUEAQIBBRIDawIICgwKBQQBAgEBEgNrCRUKDAoFBAECAQMSA2sYGQoMCgUEAQIBCBID
axpCCg8KCAQBAgEInAgAEgNrG0EKMQoEBAECAhIDbgJCGiQgT3B0aW9uYWwuIFRoZSBjYXRh
bG9nIGRlc2NyaXB0aW9uLgoKDAoFBAECAgUSA24CCAoMCgUEAQICARIDbgkUCgwKBQQBAgID
EgNuFxgKDAoFBAECAggSA24ZQQoPCggEAQICCJwIABIDbhpACjwKBAQBAgMSBHECcjIaLiBP
dXRwdXQgb25seS4gVGhlIGNhdGFsb2cgY3JlYXRpb24gdGltZXN0YW1wLgoKDAoFBAECAwYS
A3ECGwoMCgUEAQIDARIDcRwnCgwKBQQBAgMDEgNxKisKDAoFBAECAwgSA3IGMQoPCggEAQID
CJwIABIDcgcwCjoKBAQBAgQSBHUCdjIaLCBPdXRwdXQgb25seS4gVGhlIGNhdGFsb2cgdXBk
YXRlIHRpbWVzdGFtcC4KCgwKBQQBAgQGEgN1AhsKDAoFBAECBAESA3UcJwoMCgUEAQIEAxID
dSorCgwKBQQBAgQIEgN2BjEKDwoIBAECBAicCAASA3YHMAorCgIEAhIFegChAQEaHiBBIHRl
bXBsYXRlIGluc2lkZSBhIGNhdGFsb2cuCgoKCgMEAgESA3oIFwoMCgMEAgcSBXsCgAEECg4K
BQQCB50IEgV7AoABBAqoAQoEBAICABIEhAECPRqZASBJZGVudGlmaWVyLiBUaGUgY2F0YWxv
ZyB0ZW1wbGF0ZSBuYW1lIGluIGZvbGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvJHByb2pl
Y3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFjZXMvJHNwYWNlL2NhdGFsb2dzLyRjYXRhbG9n
L3RlbXBsYXRlcy8kdGVtcGxhdGVgCgoNCgUEAgIABRIEhAECCAoNCgUEAgIAARIEhAEJDQoN
CgUEAgIAAxIEhAEQEQoNCgUEAgIACBIEhAESPAoQCggEAgIACJwIABIEhAETOwpBCgQEAgIB
EgSHAQJDGjMgT3B0aW9uYWwuIFRoZSBkaXNwbGF5IG5hbWUgb2YgYSBjYXRhbG9nIHRlbXBs
YXRlLgoKDQoFBAICAQUSBIcBAggKDQoFBAICAQESBIcBCRUKDQoFBAICAQMSBIcBGBkKDQoF
BAICAQgSBIcBGkIKEAoIBAICAQicCAASBIcBG0EKOwoEBAICAhIEigECQhotIE9wdGlvbmFs
LiBUaGUgY2F0YWxvZyB0ZW1wbGF0ZSBkZXNjcmlwdGlvbi4KCg0KBQQCAgIFEgSKAQIICg0K
BQQCAgIBEgSKAQkUCg0KBQQCAgIDEgSKARcYCg0KBQQCAgIIEgSKARlBChAKCAQCAgIInAgA
EgSKARpACjkKBAQCAgMSBI0BAj4aKyBPdXRwdXQgb25seS4gVGhlIHRlbXBsYXRlIHJldmlz
aW9ucyBVVUlELgoKDQoFBAICAwUSBI0BAggKDQoFBAICAwESBI0BCQ0KDQoFBAICAwMSBI0B
EBEKDQoFBAICAwgSBI0BEj0KEAoIBAICAwicCAASBI0BEzwKRwoEBAICBBIGkAECkQEyGjcg
T3V0cHV0IG9ubHkuIFRoZSBjYXRhbG9nIHRlbXBsYXRlIGNyZWF0aW9uIHRpbWVzdGFtcC4K
Cg0KBQQCAgQGEgSQAQIbCg0KBQQCAgQBEgSQARwnCg0KBQQCAgQDEgSQASorCg0KBQQCAgQI
EgSRAQYxChAKCAQCAgQInAgAEgSRAQcwCkUKBAQCAgUSBpQBApUBMho1IE91dHB1dCBvbmx5
LiBUaGUgY2F0YWxvZyB0ZW1wbGF0ZSB1cGRhdGUgdGltZXN0YW1wLgoKDQoFBAICBQYSBJQB
AhsKDQoFBAICBQESBJQBHCcKDQoFBAICBQMSBJQBKisKDQoFBAICBQgSBJUBBjEKEAoIBAIC
BQicCAASBJUBBzAKPQoEBAICBhIEmAECTBovIE91dHB1dCBvbmx5LiBMYXRlc3QgcmV2aXNp
b24gb2YgdGhlIHRlbXBsYXRlLgoKDQoFBAICBgUSBJgBAggKDQoFBAICBgESBJgBCRsKDQoF
BAICBgMSBJgBHh8KDQoFBAICBggSBJgBIEsKEAoIBAICBgicCAASBJgBIUoKYAoEBAICBxIG
nAECnQEvGlAgUmVxdWlyZWQuIFRoZSBjYXRlZ29yeSBvZiB0aGUgQXBwbGljYXRpb24gRGVz
aWduIENlbnRlciBhcHBsaWNhdGlvbgogdGVtcGxhdGUuCgoNCgUEAgIHBhIEnAECEgoNCgUE
AgIHARIEnAETJAoNCgUEAgIHAxIEnAEnKAoNCgUEAgIHCBIEnQEGLgoQCggEAgIHCJwIABIE
nQEHLQpSCgQEAgIIEgSgAQJBGkQgT3B0aW9uYWwuIFRoZSBBcHBsaWNhdGlvbiBEZXNpZ24g
Q2VudGVyIGFwcGxpY2F0aW9uIHRlbXBsYXRlIHR5cGUuCgoNCgUEAgIIBhIEoAECDgoNCgUE
AgIIARIEoAEPEwoNCgUEAgIIAxIEoAEWFwoNCgUEAgIICBIEoAEYQAoQCggEAgIICJwIABIE
oAEZPwo0CgIEAxIGpAEAnAIBGiYgVGVtcGxhdGUgcmV2aXNpb25zIGluc2lkZSBhIGNhdGFs
b2cuCgoLCgMEAwESBKQBCB8KDQoDBAMHEgalAQKqAQQKDwoFBAMHnQgSBqUBAqoBBAolCgQE
AwQAEgatAQK5AQMaFSBUaGUgdGVtcGxhdGUgc3RhdGUuCgoNCgUEAwQAARIErQEHDAoaCgYE
AwQAAgASBK8BBBoaCiBEZWZhdWx0LgoKDwoHBAMEAAIAARIErwEEFQoPCgcEAwQAAgACEgSv
ARgZCjIKBgQDBAACARIEsgEEExoiIFRoZSB0ZW1wbGF0ZSBpcyBiZWluZyB2YWxpZGF0ZWQu
CgoPCgcEAwQAAgEBEgSyAQQOCg8KBwQDBAACAQISBLIBERIKMwoGBAMEAAICEgS1AQQPGiMg
VGhlIHRlbXBsYXRlIGlzIHJlYWR5IHRvIGJlIHVzZWQuCgoPCgcEAwQAAgIBEgS1AQQKCg8K
BwQDBAACAgISBLUBDQ4KKgoGBAMEAAIDEgS4AQQQGhogVGhlIHRlbXBsYXRlIGlzIGludmFs
aWQuCgoPCgcEAwQAAgMBEgS4AQQLCg8KBwQDBAACAwISBLgBDg8KSQoEBAMIABIGvAEC1gED
GjkgVGhlIGFydGlmYWN0IGxvY2F0aW9uIG9mIHRoZSBUZXJyYWZvcm0gaW4gdGhlIHRlbXBs
YXRlLgoKDQoFBAMIAAESBLwBCBkKKQoEBAMCABIEvgEERhobIE9wdGlvbmFsLiBUaGUgZ2l0
IHNvdXJjZS4KCg0KBQQDAgAGEgS+AQQNCg0KBQQDAgABEgS+AQ4YCg0KBQQDAgADEgS+ARsc
Cg0KBQQDAgAIEgS+AR1FChAKCAQDAgAInAgAEgS+AR5ECqkBCgQEAwIBEgbDAQTEAUQamAEg
T3B0aW9uYWwuIERlcHJlY2F0ZWQ6IEFkZGVkIG5ldyBmaWVsZCB0Zl9tb2R1bGVfZ2NzX3Vy
aS4KIFRoZSBDbG91ZCBTdG9yYWdlIFVSSSwgd2hpY2ggbXVzdCBiZSBpbiB0aGUgZm9ybWF0
IGdzOi8vW2J1Y2tldF0gb3IKIGdzOi8vW2J1Y2tldF0vW29iamVjdF0uCgoNCgUEAwIBBRIE
wwEECgoNCgUEAwIBARIEwwELGQoNCgUEAwIBAxIEwwEcHgoNCgUEAwIBCBIExAEIQwoOCgYE
AwIBCAMSBMQBCRoKEAoIBAMCAQicCAASBMQBHEIKRQoEBAMCAhIGxwEEzAEGGjUgT3B0aW9u
YWwuIFRoZSBhcHBsaWNhdGlvbiB0ZW1wbGF0ZSByZXZpc2lvbiBzb3VyY2UuCgoNCgUEAwIC
BRIExwEECgoNCgUEAwICARIExwELLwoNCgUEAwICAxIExwEyNAoPCgUEAwICCBIGxwE1zAEF
ChAKCAQDAgIInAgAEgTIAQYsChEKBwQDAgIInwgSBskBBssBBwqTAQoEBAMCAxIG0AEE0QEx
GoIBIE9wdGlvbmFsLiBDb25maWd1cmF0aW9uIGZvciBmZXRjaGluZyBjb250ZW50IGZyb20g
c291cmNlIGNvZGUgcmVwb3NpdG9yeQogc3VjaCBhcyBHaXRIdWIgb3IgQml0YnVja2V0IHRo
cm91Z2ggRGV2ZWxvcGVyIENvbm5lY3QuCgoNCgUEAwIDBhIE0AEEIAoNCgUEAwIDARIE0AEh
QAoNCgUEAwIDAxIE0AFDRQoNCgUEAwIDCBIE0QEIMAoQCggEAwIDCJwIABIE0QEJLwplCgQE
AwIEEgTVAQRDGlcgT3B0aW9uYWwuIFRoZSBPcGVuIENvbnRhaW5lciBJbml0aWF0aXZlIChP
Q0kpIHJlcG8gc291cmNlIHRoYXQgY29udGFpbnMKIGhlbG0gY2hhcnRzLgoKDQoFBAMCBAYS
BNUBBAsKDQoFBAMCBAESBNUBDBQKDQoFBAMCBAMSBNUBFxkKDQoFBAMCBAgSBNUBGkIKEAoI
BAMCBAicCAASBNUBG0EKsQEKBAQDAgUSBNoBAj0aogEgSWRlbnRpZmllci4gVGhlIGNhdGFs
b2cgdGVtcGxhdGUgcmV2aXNpb24gbmFtZS4KIGBwcm9qZWN0cy8kcHJvamVjdC9sb2NhdGlv
bnMvJGxvY2F0aW9uL3NwYWNlcy8kc3BhY2UvY2F0YWxvZ3MvJGNhdGFsb2cvdGVtcGxhdGVz
LyR0ZW1wbGF0ZS9yZXZpc2lvbnMvJHJldmlzaW9uYAoKDQoFBAMCBQUSBNoBAggKDQoFBAMC
BQESBNoBCQ0KDQoFBAMCBQMSBNoBEBEKDQoFBAMCBQgSBNoBEjwKEAoIBAMCBQicCAASBNoB
EzsKRAoEBAMCBhIE3QECQxo2IE9wdGlvbmFsLiBUaGUgY2F0YWxvZyB0ZW1wbGF0ZSByZXZp
c2lvbiBkZXNjcmlwdGlvbi4KCg0KBQQDAgYFEgTdAQIICg0KBQQDAgYBEgTdAQkUCg0KBQQD
AgYDEgTdARcZCg0KBQQDAgYIEgTdARpCChAKCAQDAgYInAgAEgTdARtBClIKBAQDAgcSBOAB
AkEaRCBPcHRpb25hbC4gVGhlIEFwcGxpY2F0aW9uIERlc2lnbiBDZW50ZXIgYXBwbGljYXRp
b24gdGVtcGxhdGUgdHlwZS4KCg0KBQQDAgcGEgTgAQIOCg0KBQQDAgcBEgTgAQ8TCg0KBQQD
AgcDEgTgARYXCg0KBQQDAgcIEgTgARhAChAKCAQDAgcInAgAEgTgARk/CkcKBAQDAggSBuMB
AuQBMho3IE91dHB1dCBvbmx5LiBUaGUgY2F0YWxvZyB0ZW1wbGF0ZSBjcmVhdGlvbiB0aW1l
c3RhbXAuCgoNCgUEAwIIBhIE4wECGwoNCgUEAwIIARIE4wEcJwoNCgUEAwIIAxIE4wEqKwoN
CgUEAwIICBIE5AEGMQoQCggEAwIICJwIABIE5AEHMApFCgQEAwIJEgbnAQLoATIaNSBPdXRw
dXQgb25seS4gVGhlIGNhdGFsb2cgdGVtcGxhdGUgdXBkYXRlIHRpbWVzdGFtcC4KCg0KBQQD
AgkGEgTnAQIbCg0KBQQDAgkBEgTnARwnCg0KBQQDAgkDEgTnASorCg0KBQQDAgkIEgToAQYx
ChAKCAQDAgkInAgAEgToAQcwClcKBAQDAgoSBusBAuwBMhpHIE91dHB1dCBvbmx5LiBUZW1w
bGF0ZSBtZXRhZGF0YSByZWxhdGVkIHRvIFRlcnJhZm9ybSBpbnB1dCBhbmQgb3V0cHV0LgoK
DQoFBAMCCgYSBOsBAhUKDQoFBAMCCgESBOsBFicKDQoFBAMCCgMSBOsBKisKDQoFBAMCCggS
BOwBBjEKEAoIBAMCCgicCAASBOwBBzAKSwoEBAMCCxIE7wECPho9IE91dHB1dCBvbmx5LiBU
aGUgdGVtcGxhdGUgc3RhdGUgKHZhbGlkYXRpbmcvcmVhZHkvaW52YWxpZCkuCgoNCgUEAwIL
BhIE7wECBwoNCgUEAwILARIE7wEIDQoNCgUEAwILAxIE7wEQEQoNCgUEAwILCBIE7wESPQoQ
CggEAwILCJwIABIE7wETPApBCgQEAwIMEgbyAQLzATIaMSBPdXRwdXQgb25seS4gVGhlIGFw
cGxpY2F0aW9uIHRlbXBsYXRlIHJldmlzaW9uLgoKDQoFBAMCDAYSBPIBAh8KDQoFBAMCDAES
BPIBID0KDQoFBAMCDAMSBPIBQEIKDQoFBAMCDAgSBPMBBjEKEAoIBAMCDAicCAASBPMBBzAK
NwoEBAMCDRIG9gEC9wEyGicgT3V0cHV0IG9ubHkuIFRoZSBoZWxtIGNoYXJ0IG1ldGFkYXRh
LgoKDQoFBAMCDQYSBPYBAhMKDQoFBAMCDQESBPYBFCcKDQoFBAMCDQMSBPYBKiwKDQoFBAMC
DQgSBPcBBjEKEAoIBAMCDQicCAASBPcBBzAKOwoEBAMCDhIE+gECPxotIE91dHB1dCBvbmx5
LiBVVUlEIG9mIHRoZSB0ZW1wbGF0ZSByZXZpc2lvbi4KCg0KBQQDAg4FEgT6AQIICg0KBQQD
Ag4BEgT6AQkNCg0KBQQDAg4DEgT6ARASCg0KBQQDAg4IEgT6ARM+ChAKCAQDAg4InAgAEgT6
ARQ9CikKBAQDAg8SBP0BAk0aGyBPcHRpb25hbC4gTWV0YWRhdGEgaW5wdXQuCgoNCgUEAwIP
BhIE/QECDwoNCgUEAwIPARIE/QEQHgoNCgUEAwIPAxIE/QEhIwoNCgUEAwIPCBIE/QEkTAoQ
CggEAwIPCJwIABIE/QElSwo8CgQEAwIQEgaAAgKBAjIaLCBPdXRwdXQgb25seS4gVGhlIGNh
dGVnb3J5IG9mIHRoZSB0ZW1wbGF0ZS4KCg0KBQQDAhAGEgSAAgISCg0KBQQDAhABEgSAAhMk
Cg0KBQQDAhADEgSAAicpCg0KBQQDAhAIEgSBAgYxChAKCAQDAhAInAgAEgSBAgcwClEKBAQD
AhESBoQCAoUCMhpBIE91dHB1dCBvbmx5LiBUaGUgUHJvZHVjdCBNYWluIGxvZ2ljYWwgcHJv
ZHVjdCB0eXBlIGluZm9ybWF0aW9uLgoKDQoFBAMCEQQSBIQCAgoKDQoFBAMCEQYSBIQCCxkK
DQoFBAMCEQESBIQCGioKDQoFBAMCEQMSBIQCLS8KDQoFBAMCEQgSBIUCBjEKEAoIBAMCEQic
CAASBIUCBzAKfwoEBAMCEhIEiQICUBpxIE9wdGlvbmFsLiBUaGUgYW5ub3RhdGlvbnMgb2Yg
dGhlIHRlbXBsYXRlIHJldmlzaW9uLgogS2V5IGlzIHRoZSBhbm5vdGF0aW9uIG5hbWUuIFZh
bHVlIGlzIHRoZSBhbm5vdGF0aW9uIHZhbHVlLgoKDQoFBAMCEgYSBIkCAhUKDQoFBAMCEgES
BIkCFiEKDQoFBAMCEgMSBIkCJCYKDQoFBAMCEggSBIkCJ08KEAoIBAMCEgicCAASBIkCKE4K
qQEKBAQDAhMSBo4CAo8CMhqYASBPdXRwdXQgb25seS4gTWV0YWRhdGEgdGhhdCB3YXMgYXV0
b21hdGljYWxseSBpbmZlcnJlZCBmcm9tIHRoZSB0ZW1wbGF0ZQogY29udGVudC4gVGhpcyBm
aWVsZCBjYW4gYmUgdXBkYXRlZCBieSB0aGUgc3lzdGVtIGFzIGl0IGdldHMgbmV3CiBpbmZv
cm1hdGlvbi4KCg0KBQQDAhMGEgSOAgISCg0KBQQDAhMBEgSOAhMkCg0KBQQDAhMDEgSOAicp
Cg0KBQQDAhMIEgSPAgYxChAKCAQDAhMInAgAEgSPAgcwClMKBAQDAhQSBpICApMCMhpDIE91
dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgdHlwZXMgcHJlc2VudCBpbiB0aGUgdGVtcGxhdGUg
cmV2aXNpb24uCgoNCgUEAwIUBBIEkgICCgoNCgUEAwIUBhIEkgILFwoNCgUEAwIUARIEkgIY
JgoNCgUEAwIUAxIEkgIpKwoNCgUEAwIUCBIEkwIGMQoQCggEAwIUCJwIABIEkwIHMApgCgQE
AwIVEgSXAgJIGlIgT3V0cHV0IG9ubHkuIEluZGljYXRlcyB0aGUgSWFDIHNvdXJjZSBmb3Jt
YXQgb2YgdGhpcyBjYXRhbG9nIHRlbXBsYXRlCiByZXZpc2lvbi4KCg0KBQQDAhUGEgSXAgIL
Cg0KBQQDAhUBEgSXAgwWCg0KBQQDAhUDEgSXAhkbCg0KBQQDAhUIEgSXAhxHChAKCAQDAhUI
nAgAEgSXAh1GCkgKBAQDAhYSBpoCApsCLxo4IE9wdGlvbmFsLiBUaGUgdmFsdWVzIHByb3Zp
ZGVkIGZvciB0aGUgaW5wdXQgdmFyaWFibGVzLgoKDQoFBAMCFgQSBJoCAgoKDQoFBAMCFgYS
BJoCCxQKDQoFBAMCFgESBJoCFSsKDQoFBAMCFgMSBJoCLjAKDQoFBAMCFggSBJsCBi4KEAoI
BAMCFgicCAASBJsCBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::CatalogManagement::Space ===
    # Fields for Space
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: enable_gcp_shared_templates Type: 8 ()
    # Field: gcs_bucket Type: 9 ()
    # Field: tags Type: 11 (.google.cloud.designcenter.v1.Space.TagsEntry)

# === Message: Google::Cloud::Designcenter::V1::CatalogManagement::Catalog ===
    # Fields for Catalog
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplate ===
    # Fields for CatalogTemplate
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: uuid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: latest_revision_id Type: 9 ()
    # Field: template_category Type: 14 (.google.cloud.designcenter.v1.TemplateCategory)
    # Field: type Type: 14 (.google.cloud.designcenter.v1.TemplateType)

# === Message: Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision ===
    # Fields for CatalogTemplateRevision
    # Field: git_source Type: 11 (.google.cloud.designcenter.v1.GitSource)
    # Field: gcs_source_uri Type: 9 ()
    # Field: application_template_revision_source Type: 9 ()
    # Field: developer_connect_source_config Type: 11 (.google.cloud.designcenter.v1.DeveloperConnectSourceConfig)
    # Field: oci_repo Type: 11 (.google.cloud.designcenter.v1.OciRepo)
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: type Type: 14 (.google.cloud.designcenter.v1.TemplateType)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: template_metadata Type: 11 (.google.cloud.designcenter.v1.TFBlueprintMetadata)
    # Field: state Type: 14 (.google.cloud.designcenter.v1.CatalogTemplateRevision.State)
    # Field: application_template_revision Type: 11 (.google.cloud.designcenter.v1.SerializedApplicationTemplate)
    # Field: helm_chart_metadata Type: 11 (.google.cloud.designcenter.v1.HelmChartMetadata)
    # Field: uuid Type: 9 ()
    # Field: metadata_input Type: 11 (.google.cloud.designcenter.v1.MetadataInput)
    # Field: template_category Type: 14 (.google.cloud.designcenter.v1.TemplateCategory)
    # Field: logical_products Type: 11 (.google.cloud.designcenter.v1.LogicalProduct)
    # Field: annotations Type: 11 (.google.cloud.designcenter.v1.CatalogTemplateRevision.AnnotationsEntry)
    # Field: inferred_metadata Type: 11 (.google.cloud.designcenter.v1.InferredMetadata)
    # Field: resource_types Type: 11 (.google.cloud.designcenter.v1.ResourceType)
    # Field: iac_source Type: 14 (.google.cloud.designcenter.v1.IACSource)
    # Field: application_parameters Type: 11 (.google.cloud.designcenter.v1.Parameter)

# Enum: CatalogTemplateRevision::State
our $CatalogTemplateRevision_STATE_UNSPECIFIED = 0;
our $CatalogTemplateRevision_VALIDATING = 1;
our $CatalogTemplateRevision_ACTIVE = 2;
our $CatalogTemplateRevision_INVALID = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::CatalogManagement - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/catalog_management.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::CatalogManagement;

    my $msg = Google::Cloud::Designcenter::V1::CatalogManagement::Space->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::CatalogManagement::Space->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/catalog_management.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::CatalogManagement::Space

Space is a top level resource for managing teams building applications
through Application Design Center.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The space name.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Display name for the space.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description for the space.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Space creation timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Space update timestamp

=item * C<< $msg->enable_gcp_shared_templates() >> / C<< $msg->enable_gcp_shared_templates($value) >>

Type: C<Bool>

Optional. Flag to enable Google opinionated shared templates.

=item * C<< $msg->gcs_bucket() >> / C<< $msg->gcs_bucket($value) >>

Type: C<String>

Optional. An existing Google Cloud Storage bucket that you want to use
instead of creating a new bucket during Application Design Center setup. If
not provided, a default bucket is created during setup. The bucket must
exist in the same project as the space. If the bucket name does not exist
in the same project as the space, the request fails with an
INVALID_ARGUMENT error. If you do not have access to the bucket, the
request fails with a PERMISSION_DENIED error. Format: {$bucket_name} For
example, if the Cloud Storage bucket URI is gs:\/\/{$bucket_name}, the
format is {$bucket_name}.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::CatalogManagement::Space::TagsEntry>)

Optional. Input only. Immutable. Tags are key/values bound to space
resource. Example:
```
  "123/environment": "production"
  "123/costCenter": "marketing"
```

For more information on tag creation and management, see
https://cloud.google.com/resource-manager/docs/tags/tags-overview.

=back

=head2 Google::Cloud::Designcenter::V1::CatalogManagement::Catalog

A catalog is a collection of templates.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The catalog name in the following format:
`projects/$project/locations/$location/spaces/$space/catalogs/$catalog`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The catalog display name.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The catalog description.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The catalog creation timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The catalog update timestamp.

=back

=head2 Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplate

A template inside a catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The catalog template name in following format:
`projects/$project/locations/$location/spaces/$space/catalogs/$catalog/templates/$template`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The display name of a catalog template.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The catalog template description.

=item * C<< $msg->uuid() >> / C<< $msg->uuid($value) >>

Type: C<String>

Output only. The template revisions UUID.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The catalog template creation timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The catalog template update timestamp.

=item * C<< $msg->latest_revision_id() >> / C<< $msg->latest_revision_id($value) >>

Type: C<String>

Output only. Latest revision of the template.

=item * C<< $msg->template_category() >> / C<< $msg->template_category($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::TemplateCategory>)

Required. The category of the Application Design Center application
template.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::TemplateType>)

Optional. The Application Design Center application template type.

=back

=head2 Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision

Template revisions inside a catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->git_source() >> / C<< $msg->git_source($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::GitSource>)

Optional. The git source.

=item * C<< $msg->gcs_source_uri() >> / C<< $msg->gcs_source_uri($value) >>

Type: C<String>

Optional. Deprecated: Added new field tf_module_gcs_uri.
The Cloud Storage URI, which must be in the format gs://[bucket] or
gs://[bucket]/[object].

=item * C<< $msg->application_template_revision_source() >> / C<< $msg->application_template_revision_source($value) >>

Type: C<String>

Optional. The application template revision source.

=item * C<< $msg->developer_connect_source_config() >> / C<< $msg->developer_connect_source_config($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::DeveloperConnectSourceConfig>)

Optional. Configuration for fetching content from source code repository
such as GitHub or Bitbucket through Developer Connect.

=item * C<< $msg->oci_repo() >> / C<< $msg->oci_repo($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Ingestion::OciRepo>)

Optional. The Open Container Initiative (OCI) repo source that contains
helm charts.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The catalog template revision name.
`projects/$project/locations/$location/spaces/$space/catalogs/$catalog/templates/$template/revisions/$revision`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The catalog template revision description.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::TemplateType>)

Optional. The Application Design Center application template type.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The catalog template creation timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The catalog template update timestamp.

=item * C<< $msg->template_metadata() >> / C<< $msg->template_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::TFBlueprintMetadata>)

Output only. Template metadata related to Terraform input and output.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::CatalogTemplateRevision::State>)

Output only. The template state (validating/ready/invalid).

=item * C<< $msg->application_template_revision() >> / C<< $msg->application_template_revision($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Authoring::SerializedApplicationTemplate>)

Output only. The application template revision.

=item * C<< $msg->helm_chart_metadata() >> / C<< $msg->helm_chart_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::HelmChartMetadata>)

Output only. The helm chart metadata.

=item * C<< $msg->uuid() >> / C<< $msg->uuid($value) >>

Type: C<String>

Output only. UUID of the template revision.

=item * C<< $msg->metadata_input() >> / C<< $msg->metadata_input($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::MetadataInput>)

Optional. Metadata input.

=item * C<< $msg->template_category() >> / C<< $msg->template_category($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::TemplateCategory>)

Output only. The category of the template.

=item * C<< $msg->logical_products() >> / C<< $msg->logical_products($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::LogicalProduct>)

Output only. The Product Main logical product type information.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision::AnnotationsEntry>)

Optional. The annotations of the template revision.
Key is the annotation name. Value is the annotation value.

=item * C<< $msg->inferred_metadata() >> / C<< $msg->inferred_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::InferredMetadata>)

Output only. Metadata that was automatically inferred from the template
content. This field can be updated by the system as it gets new
information.

=item * C<< $msg->resource_types() >> / C<< $msg->resource_types($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Metadata::ResourceType>)

Output only. The resource types present in the template revision.

=item * C<< $msg->iac_source() >> / C<< $msg->iac_source($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::IACSource>)

Output only. Indicates the IaC source format of this catalog template
revision.

=item * C<< $msg->application_parameters() >> / C<< $msg->application_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Parameters::Parameter>)

Optional. The values provided for the input variables.

=back

=head3 Enum: CatalogTemplateRevision::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<VALIDATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<INVALID> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::CatalogManagement::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
