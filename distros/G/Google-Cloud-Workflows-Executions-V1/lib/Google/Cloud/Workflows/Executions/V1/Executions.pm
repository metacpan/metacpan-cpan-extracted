package Google::Cloud::Workflows::Executions::V1::Executions;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvd29ya2Zsb3dzL2V4ZWN1dGlvbnMvdjEvZXhlY3V0aW9ucy5wcm90
bxIkZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxGhxnb29nbGUvYXBpL2Fu
bm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xl
L3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvIs8QCglFeGVjdXRpb24SFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEj4KCnN0YXJ0X3Rp
bWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXN0YXJ0VGltZRI6
CghlbmRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5k
VGltZRI6CghkdXJhdGlvbhgMIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbkID4EED
UghkdXJhdGlvbhJQCgVzdGF0ZRgEIAEoDjI1Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhl
Y3V0aW9ucy52MS5FeGVjdXRpb24uU3RhdGVCA+BBA1IFc3RhdGUSGgoIYXJndW1lbnQYBSAB
KAlSCGFyZ3VtZW50EhsKBnJlc3VsdBgGIAEoCUID4EEDUgZyZXN1bHQSUAoFZXJyb3IYByAB
KAsyNS5nb29nbGUuY2xvdWQud29ya2Zsb3dzLmV4ZWN1dGlvbnMudjEuRXhlY3V0aW9uLkVy
cm9yQgPgQQNSBWVycm9yEjUKFHdvcmtmbG93X3JldmlzaW9uX2lkGAggASgJQgPgQQNSEndv
cmtmbG93UmV2aXNpb25JZBJiCg5jYWxsX2xvZ19sZXZlbBgJIAEoDjI8Lmdvb2dsZS5jbG91
ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MS5FeGVjdXRpb24uQ2FsbExvZ0xldmVsUgxjYWxs
TG9nTGV2ZWwSUwoGc3RhdHVzGAogASgLMjYuZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVj
dXRpb25zLnYxLkV4ZWN1dGlvbi5TdGF0dXNCA+BBA1IGc3RhdHVzElMKBmxhYmVscxgLIAMo
CzI7Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MS5FeGVjdXRpb24uTGFi
ZWxzRW50cnlSBmxhYmVscxJgCgtzdGF0ZV9lcnJvchgNIAEoCzI6Lmdvb2dsZS5jbG91ZC53
b3JrZmxvd3MuZXhlY3V0aW9ucy52MS5FeGVjdXRpb24uU3RhdGVFcnJvckID4EEDUgpzdGF0
ZUVycm9yGvkBChFTdGFja1RyYWNlRWxlbWVudBISCgRzdGVwGAEgASgJUgRzdGVwEhgKB3Jv
dXRpbmUYAiABKAlSB3JvdXRpbmUSZgoIcG9zaXRpb24YAyABKAsySi5nb29nbGUuY2xvdWQu
d29ya2Zsb3dzLmV4ZWN1dGlvbnMudjEuRXhlY3V0aW9uLlN0YWNrVHJhY2VFbGVtZW50LlBv
c2l0aW9uUghwb3NpdGlvbhpOCghQb3NpdGlvbhISCgRsaW5lGAEgASgDUgRsaW5lEhYKBmNv
bHVtbhgCIAEoA1IGY29sdW1uEhYKBmxlbmd0aBgDIAEoA1IGbGVuZ3RoGmsKClN0YWNrVHJh
Y2USXQoIZWxlbWVudHMYASADKAsyQS5nb29nbGUuY2xvdWQud29ya2Zsb3dzLmV4ZWN1dGlv
bnMudjEuRXhlY3V0aW9uLlN0YWNrVHJhY2VFbGVtZW50UghlbGVtZW50cxqYAQoFRXJyb3IS
GAoHcGF5bG9hZBgBIAEoCVIHcGF5bG9hZBIYCgdjb250ZXh0GAIgASgJUgdjb250ZXh0ElsK
C3N0YWNrX3RyYWNlGAMgASgLMjouZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25z
LnYxLkV4ZWN1dGlvbi5TdGFja1RyYWNlUgpzdGFja1RyYWNlGqABCgZTdGF0dXMSYAoNY3Vy
cmVudF9zdGVwcxgBIAMoCzI7Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52
MS5FeGVjdXRpb24uU3RhdHVzLlN0ZXBSDGN1cnJlbnRTdGVwcxo0CgRTdGVwEhgKB3JvdXRp
bmUYASABKAlSB3JvdXRpbmUSEgoEc3RlcBgCIAEoCVIEc3RlcBqoAQoKU3RhdGVFcnJvchIY
CgdkZXRhaWxzGAEgASgJUgdkZXRhaWxzElMKBHR5cGUYAiABKA4yPy5nb29nbGUuY2xvdWQu
d29ya2Zsb3dzLmV4ZWN1dGlvbnMudjEuRXhlY3V0aW9uLlN0YXRlRXJyb3IuVHlwZVIEdHlw
ZSIrCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABINCglLTVNfRVJST1IQARo5CgtMYWJl
bHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBInEK
BVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASCgoGQUNUSVZFEAESDQoJU1VDQ0VFREVE
EAISCgoGRkFJTEVEEAMSDQoJQ0FOQ0VMTEVEEAQSDwoLVU5BVkFJTEFCTEUQBRIKCgZRVUVV
RUQQBiJkCgxDYWxsTG9nTGV2ZWwSHgoaQ0FMTF9MT0dfTEVWRUxfVU5TUEVDSUZJRUQQABIR
Cg1MT0dfQUxMX0NBTExTEAESEwoPTE9HX0VSUk9SU19PTkxZEAISDAoITE9HX05PTkUQAzqG
AepBggEKK3dvcmtmbG93ZXhlY3V0aW9ucy5nb29nbGVhcGlzLmNvbS9FeGVjdXRpb24SU3By
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS93b3JrZmxvd3Mve3dvcmtm
bG93fS9leGVjdXRpb25zL3tleGVjdXRpb259IqECChVMaXN0RXhlY3V0aW9uc1JlcXVlc3QS
QQoGcGFyZW50GAEgASgJQingQQL6QSMKIXdvcmtmbG93cy5nb29nbGVhcGlzLmNvbS9Xb3Jr
Zmxvd1IGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tl
bhgDIAEoCVIJcGFnZVRva2VuEkwKBHZpZXcYBCABKA4yMy5nb29nbGUuY2xvdWQud29ya2Zs
b3dzLmV4ZWN1dGlvbnMudjEuRXhlY3V0aW9uVmlld0ID4EEBUgR2aWV3EhsKBmZpbHRlchgF
IAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBiABKAlCA+BBAVIHb3JkZXJCeSKRAQoW
TGlzdEV4ZWN1dGlvbnNSZXNwb25zZRJPCgpleGVjdXRpb25zGAEgAygLMi8uZ29vZ2xlLmNs
b3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxLkV4ZWN1dGlvblIKZXhlY3V0aW9ucxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4irwEKFkNyZWF0ZUV4ZWN1dGlv
blJlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIXdvcmtmbG93cy5nb29nbGVhcGlz
LmNvbS9Xb3JrZmxvd1IGcGFyZW50ElIKCWV4ZWN1dGlvbhgCIAEoCzIvLmdvb2dsZS5jbG91
ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MS5FeGVjdXRpb25CA+BBAlIJZXhlY3V0aW9uIqwB
ChNHZXRFeGVjdXRpb25SZXF1ZXN0EkcKBG5hbWUYASABKAlCM+BBAvpBLQord29ya2Zsb3dl
eGVjdXRpb25zLmdvb2dsZWFwaXMuY29tL0V4ZWN1dGlvblIEbmFtZRJMCgR2aWV3GAIgASgO
MjMuZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxLkV4ZWN1dGlvblZpZXdC
A+BBAVIEdmlldyJhChZDYW5jZWxFeGVjdXRpb25SZXF1ZXN0EkcKBG5hbWUYASABKAlCM+BB
AvpBLQord29ya2Zsb3dleGVjdXRpb25zLmdvb2dsZWFwaXMuY29tL0V4ZWN1dGlvblIEbmFt
ZSpECg1FeGVjdXRpb25WaWV3Eh4KGkVYRUNVVElPTl9WSUVXX1VOU1BFQ0lGSUVEEAASCQoF
QkFTSUMQARIICgRGVUxMEAIywwcKCkV4ZWN1dGlvbnMS2AEKDkxpc3RFeGVjdXRpb25zEjsu
Z29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxLkxpc3RFeGVjdXRpb25zUmVx
dWVzdBo8Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MS5MaXN0RXhlY3V0
aW9uc1Jlc3BvbnNlIkuC0+STAjwSOi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
Lyovd29ya2Zsb3dzLyp9L2V4ZWN1dGlvbnPaQQZwYXJlbnQS4gEKD0NyZWF0ZUV4ZWN1dGlv
bhI8Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MS5DcmVhdGVFeGVjdXRp
b25SZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxLkV4ZWN1
dGlvbiJggtPkkwJHIjovdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3dvcmtm
bG93cy8qfS9leGVjdXRpb25zOglleGVjdXRpb27aQRBwYXJlbnQsZXhlY3V0aW9uEsUBCgxH
ZXRFeGVjdXRpb24SOS5nb29nbGUuY2xvdWQud29ya2Zsb3dzLmV4ZWN1dGlvbnMudjEuR2V0
RXhlY3V0aW9uUmVxdWVzdBovLmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52
MS5FeGVjdXRpb24iSYLT5JMCPBI6L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
d29ya2Zsb3dzLyovZXhlY3V0aW9ucy8qfdpBBG5hbWUS1QEKD0NhbmNlbEV4ZWN1dGlvbhI8
Lmdvb2dsZS5jbG91ZC53b3JrZmxvd3MuZXhlY3V0aW9ucy52MS5DYW5jZWxFeGVjdXRpb25S
ZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxLkV4ZWN1dGlv
biJTgtPkkwJGIkEvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi93b3JrZmxvd3Mv
Ki9leGVjdXRpb25zLyp9OmNhbmNlbDoBKtpBBG5hbWUaVcpBIXdvcmtmbG93ZXhlY3V0aW9u
cy5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xv
dWQtcGxhdGZvcm1C6wEKKGNvbS5nb29nbGUuY2xvdWQud29ya2Zsb3dzLmV4ZWN1dGlvbnMu
djFCD0V4ZWN1dGlvbnNQcm90b1ABWkhjbG91ZC5nb29nbGUuY29tL2dvL3dvcmtmbG93cy9l
eGVjdXRpb25zL2FwaXYxL2V4ZWN1dGlvbnNwYjtleGVjdXRpb25zcGLqQWEKIXdvcmtmbG93
cy5nb29nbGVhcGlzLmNvbS9Xb3JrZmxvdxI8cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L3dvcmtmbG93cy97d29ya2Zsb3d9SpZtCgcSBQ4AjgMBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACYKCQoCAwES
AxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAKAoJCgIDBRIDFwApCggKAQgS
AxkAXwoJCgIICxIDGQBfCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMAoJCgIICBID
GwAwCggKAQgSAxwAQQoJCgIIARIDHABBCgkKAQgSBB0AIAIKDAoECJ0IABIEHQAgAgqOAQoC
BgASBCQATQEagQEgRXhlY3V0aW9ucyBpcyB1c2VkIHRvIHN0YXJ0IGFuZCBtYW5hZ2UgcnVu
bmluZyBpbnN0YW5jZXMgb2YKIFtXb3JrZmxvd3NdW2dvb2dsZS5jbG91ZC53b3JrZmxvd3Mu
djEuV29ya2Zsb3ddIGNhbGxlZCBleGVjdXRpb25zLgoKCgoDBgABEgMkCBIKCgoDBgADEgMl
AkkKDAoFBgADmQgSAyUCSQoLCgMGAAMSBCYCJzcKDQoFBgADmggSBCYCJzcK3wEKBAYAAgAS
BC0CMgMa0AEgUmV0dXJucyBhIGxpc3Qgb2YgZXhlY3V0aW9ucyB3aGljaCBiZWxvbmcgdG8g
dGhlIHdvcmtmbG93IHdpdGgKIHRoZSBnaXZlbiBuYW1lLiBUaGUgbWV0aG9kIHJldHVybnMg
ZXhlY3V0aW9ucyBvZiBhbGwgd29ya2Zsb3cKIHJldmlzaW9ucy4gUmV0dXJuZWQgZXhlY3V0
aW9ucyBhcmUgb3JkZXJlZCBieSB0aGVpciBzdGFydCB0aW1lIChuZXdlc3QKIGZpcnN0KS4K
CgwKBQYAAgABEgMtBhQKDAoFBgACAAISAy0VKgoMCgUGAAIAAxIDLTVLCg0KBQYAAgAEEgQu
BDAGChEKCQYAAgAEsMq8IhIELgQwBgoMCgUGAAIABBIDMQQ0Cg8KCAYAAgAEmwgAEgMxBDQK
WAoEBgACARIENQI7AxpKIENyZWF0ZXMgYSBuZXcgZXhlY3V0aW9uIHVzaW5nIHRoZSBsYXRl
c3QgcmV2aXNpb24gb2YgdGhlIGdpdmVuIHdvcmtmbG93LgoKDAoFBgACAQESAzUGFQoMCgUG
AAIBAhIDNRYsCgwKBQYAAgEDEgM1N0AKDQoFBgACAQQSBDYEOQYKEQoJBgACAQSwyrwiEgQ2
BDkGCgwKBQYAAgEEEgM6BD4KDwoIBgACAQSbCAASAzoEPgo3CgQGAAICEgQ+AkMDGikgUmV0
dXJucyBhbiBleGVjdXRpb24gb2YgdGhlIGdpdmVuIG5hbWUuCgoMCgUGAAICARIDPgYSCgwK
BQYAAgICEgM+EyYKDAoFBgACAgMSAz4xOgoNCgUGAAICBBIEPwRBBgoRCgkGAAICBLDKvCIS
BD8EQQYKDAoFBgACAgQSA0IEMgoPCggGAAICBJsIABIDQgQyCjcKBAYAAgMSBEYCTAMaKSBD
YW5jZWxzIGFuIGV4ZWN1dGlvbiBvZiB0aGUgZ2l2ZW4gbmFtZS4KCgwKBQYAAgMBEgNGBhUK
DAoFBgACAwISA0YWLAoMCgUGAAIDAxIDRjdACg0KBQYAAgMEEgRHBEoGChEKCQYAAgMEsMq8
IhIERwRKBgoMCgUGAAIDBBIDSwQyCg8KCAYAAgMEmwgAEgNLBDIKcwoCBAASBVEAkQIBGmYg
QSBydW5uaW5nIGluc3RhbmNlIG9mIGEKIFtXb3JrZmxvd10oL3dvcmtmbG93cy9kb2NzL3Jl
ZmVyZW5jZS9yZXN0L3YxL3Byb2plY3RzLmxvY2F0aW9ucy53b3JrZmxvd3MpLgoKCgoDBAAB
EgNRCBEKCwoDBAAHEgRSAlUECg0KBQQAB50IEgRSAlUECmgKBAQABAASBFkCbgMaWiBEZXNj
cmliZXMgdGhlIGN1cnJlbnQgc3RhdGUgb2YgdGhlIGV4ZWN1dGlvbi4gTW9yZSBzdGF0ZXMg
bWlnaHQgYmUgYWRkZWQKIGluIHRoZSBmdXR1cmUuCgoMCgUEAAQAARIDWQcMCh8KBgQABAAC
ABIDWwQaGhAgSW52YWxpZCBzdGF0ZS4KCg4KBwQABAACAAESA1sEFQoOCgcEAAQAAgACEgNb
GBkKLgoGBAAEAAIBEgNeBA8aHyBUaGUgZXhlY3V0aW9uIGlzIGluIHByb2dyZXNzLgoKDgoH
BAAEAAIBARIDXgQKCg4KBwQABAACAQISA14NDgo1CgYEAAQAAgISA2EEEhomIFRoZSBleGVj
dXRpb24gZmluaXNoZWQgc3VjY2Vzc2Z1bGx5LgoKDgoHBAAEAAICARIDYQQNCg4KBwQABAAC
AgISA2EQEQo0CgYEAAQAAgMSA2QEDxolIFRoZSBleGVjdXRpb24gZmFpbGVkIHdpdGggYW4g
ZXJyb3IuCgoOCgcEAAQAAgMBEgNkBAoKDgoHBAAEAAIDAhIDZA0OCjkKBgQABAACBBIDZwQS
GiogVGhlIGV4ZWN1dGlvbiB3YXMgc3RvcHBlZCBpbnRlbnRpb25hbGx5LgoKDgoHBAAEAAIE
ARIDZwQNCg4KBwQABAACBAISA2cQEQpMCgYEAAQAAgUSA2oEFBo9IEV4ZWN1dGlvbiBkYXRh
IGlzIHVuYXZhaWxhYmxlLiBTZWUgdGhlIGBzdGF0ZV9lcnJvcmAgZmllbGQuCgoOCgcEAAQA
AgUBEgNqBA8KDgoHBAAEAAIFAhIDahITClcKBgQABAACBhIDbQQPGkggUmVxdWVzdCBoYXMg
YmVlbiBwbGFjZWQgaW4gdGhlIGJhY2tsb2cgZm9yIHByb2Nlc3NpbmcgYXQgYSBsYXRlciB0
aW1lLgoKDgoHBAAEAAIGARIDbQQKCg4KBwQABAACBgISA20NDgpICgQEAAMAEgVxAokBAxo5
IEEgc2luZ2xlIHN0YWNrIGVsZW1lbnQgKGZyYW1lKSB3aGVyZSBhbiBlcnJvciBvY2N1cnJl
ZC4KCgwKBQQAAwABEgNxChsKqgEKBgQAAwADABIEdQR/BRqZASBQb3NpdGlvbiBjb250YWlu
cyBzb3VyY2UgcG9zaXRpb24gaW5mb3JtYXRpb24gYWJvdXQgdGhlIHN0YWNrIHRyYWNlCiBl
bGVtZW50IHN1Y2ggYXMgbGluZSBudW1iZXIsIGNvbHVtbiBudW1iZXIgYW5kIGxlbmd0aCBv
ZiB0aGUgY29kZSBibG9jawogaW4gYnl0ZXMuCgoOCgcEAAMAAwABEgN1DBQKWgoIBAADAAMA
AgASA3cGFRpJIFRoZSBzb3VyY2UgY29kZSBsaW5lIG51bWJlciB0aGUgY3VycmVudCBpbnN0
cnVjdGlvbiB3YXMgZ2VuZXJhdGVkIGZyb20uCgoQCgkEAAMAAwACAAUSA3cGCwoQCgkEAAMA
AwACAAESA3cMEAoQCgkEAAMAAwACAAMSA3cTFAptCggEAAMAAwACARIDewYXGlwgVGhlIHNv
dXJjZSBjb2RlIGNvbHVtbiBwb3NpdGlvbiAob2YgdGhlIGxpbmUpIHRoZSBjdXJyZW50IGlu
c3RydWN0aW9uCiB3YXMgZ2VuZXJhdGVkIGZyb20uCgoQCgkEAAMAAwACAQUSA3sGCwoQCgkE
AAMAAwACAQESA3sMEgoQCgkEAAMAAwACAQMSA3sVFgpZCggEAAMAAwACAhIDfgYXGkggVGhl
IG51bWJlciBvZiBieXRlcyBvZiBzb3VyY2UgY29kZSBtYWtpbmcgdXAgdGhpcyBzdGFjayB0
cmFjZSBlbGVtZW50LgoKEAoJBAADAAMAAgIFEgN+BgsKEAoJBAADAAMAAgIBEgN+DBIKEAoJ
BAADAAMAAgIDEgN+FRYKMQoGBAADAAIAEgSCAQQUGiEgVGhlIHN0ZXAgdGhlIGVycm9yIG9j
Y3VycmVkIGF0LgoKDwoHBAADAAIABRIEggEECgoPCgcEAAMAAgABEgSCAQsPCg8KBwQAAwAC
AAMSBIIBEhMKNwoGBAADAAIBEgSFAQQXGicgVGhlIHJvdXRpbmUgd2hlcmUgdGhlIGVycm9y
IG9jY3VycmVkLgoKDwoHBAADAAIBBRIEhQEECgoPCgcEAAMAAgEBEgSFAQsSCg8KBwQAAwAC
AQMSBIUBFRYKTQoGBAADAAICEgSIAQQaGj0gVGhlIHNvdXJjZSBwb3NpdGlvbiBpbmZvcm1h
dGlvbiBvZiB0aGUgc3RhY2sgdHJhY2UgZWxlbWVudC4KCg8KBwQAAwACAgYSBIgBBAwKDwoH
BAADAAICARIEiAENFQoPCgcEAAMAAgIDEgSIARgZClIKBAQAAwESBowBAo8BAxpCIEEgY29s
bGVjdGlvbiBvZiBzdGFjayBlbGVtZW50cyAoZnJhbWVzKSB3aGVyZSBhbiBlcnJvciBvY2N1
cnJlZC4KCg0KBQQAAwEBEgSMAQoUCi0KBgQAAwECABIEjgEELBodIEFuIGFycmF5IG9mIHN0
YWNrIGVsZW1lbnRzLgoKDwoHBAADAQIABBIEjgEEDAoPCgcEAAMBAgAGEgSOAQ0eCg8KBwQA
AwECAAESBI4BHycKDwoHBAADAQIAAxIEjgEqKwpOCgQEAAMCEgaSAQKbAQMaPiBFcnJvciBk
ZXNjcmliZXMgd2h5IHRoZSBleGVjdXRpb24gd2FzIGFibm9ybWFsbHkgdGVybWluYXRlZC4K
Cg0KBQQAAwIBEgSSAQoPCk8KBgQAAwICABIElAEEFxo/IEVycm9yIG1lc3NhZ2UgYW5kIGRh
dGEgcmV0dXJuZWQgcmVwcmVzZW50ZWQgYXMgYSBKU09OIHN0cmluZy4KCg8KBwQAAwICAAUS
BJQBBAoKDwoHBAADAgIAARIElAELEgoPCgcEAAMCAgADEgSUARUWCjQKBgQAAwICARIElwEE
FxokIEh1bWFuLXJlYWRhYmxlIHN0YWNrIHRyYWNlIHN0cmluZy4KCg8KBwQAAwICAQUSBJcB
BAoKDwoHBAADAgIBARIElwELEgoPCgcEAAMCAgEDEgSXARUWClUKBgQAAwICAhIEmgEEHxpF
IFN0YWNrIHRyYWNlIHdpdGggZGV0YWlsZWQgaW5mb3JtYXRpb24gb2Ygd2hlcmUgZXJyb3Ig
d2FzIGdlbmVyYXRlZC4KCg8KBwQAAwICAgYSBJoBBA4KDwoHBAADAgICARIEmgEPGgoPCgcE
AAMCAgIDEgSaAR0eCnsKBAQABAESBp8BAqwBAxprIERlc2NyaWJlcyB0aGUgbGV2ZWwgb2Yg
cGxhdGZvcm0gbG9nZ2luZyB0byBhcHBseSB0byBjYWxscyBhbmQgY2FsbAogcmVzcG9uc2Vz
IGR1cmluZyB3b3JrZmxvdyBleGVjdXRpb25zLgoKDQoFBAAEAQESBJ8BBxMKMgoGBAAEAQIA
EgShAQQjGiIgTm8gY2FsbCBsb2dnaW5nIGxldmVsIHNwZWNpZmllZC4KCg8KBwQABAECAAES
BKEBBB4KDwoHBAAEAQIAAhIEoQEhIgpkCgYEAAQBAgESBKUBBBYaVCBMb2cgYWxsIGNhbGwg
c3RlcHMgd2l0aGluIHdvcmtmbG93cywgYWxsIGNhbGwgcmV0dXJucywgYW5kIGFsbCBleGNl
cHRpb25zCiByYWlzZWQuCgoPCgcEAAQBAgEBEgSlAQQRCg8KBwQABAECAQISBKUBFBUKVwoG
BAAEAQICEgSoAQQYGkcgTG9nIG9ubHkgZXhjZXB0aW9ucyB0aGF0IGFyZSByYWlzZWQgZnJv
bSBjYWxsIHN0ZXBzIHdpdGhpbiB3b3JrZmxvd3MuCgoPCgcEAAQBAgIBEgSoAQQTCg8KBwQA
BAECAgISBKgBFhcKKQoGBAAEAQIDEgSrAQQRGhkgRXhwbGljaXRseSBsb2cgbm90aGluZy4K
Cg8KBwQABAECAwESBKsBBAwKDwoHBAAEAQIDAhIEqwEPEApCCgQEAAMDEgavAQLBAQMaMiBS
ZXByZXNlbnRzIHRoZSBjdXJyZW50IHN0YXR1cyBvZiB0aGlzIGV4ZWN1dGlvbi4KCg0KBQQA
AwMBEgSvAQoQClAKBgQAAwMDABIGsQEEtwEFGj4gUmVwcmVzZW50cyBhIHN0ZXAgb2YgdGhl
IHdvcmtmbG93IHRoaXMgZXhlY3V0aW9uIGlzIHJ1bm5pbmcuCgoPCgcEAAMDAwABEgSxAQwQ
CjoKCAQAAwMDAAIAEgSzAQYZGiggTmFtZSBvZiBhIHJvdXRpbmUgd2l0aGluIHRoZSB3b3Jr
Zmxvdy4KChEKCQQAAwMDAAIABRIEswEGDAoRCgkEAAMDAwACAAESBLMBDRQKEQoJBAADAwMA
AgADEgSzARcYCjYKCAQAAwMDAAIBEgS2AQYWGiQgTmFtZSBvZiBhIHN0ZXAgd2l0aGluIHRo
ZSByb3V0aW5lLgoKEQoJBAADAwMAAgEFEgS2AQYMChEKCQQAAwMDAAIBARIEtgENEQoRCgkE
AAMDAwACAQMSBLYBFBUK5QMKBgQAAwMCABIEwAEEJBrUAyBBIGxpc3Qgb2YgY3VycmVudGx5
IGV4ZWN1dGluZyBvciBsYXN0IGV4ZWN1dGVkIHN0ZXAgbmFtZXMgZm9yIHRoZQogd29ya2Zs
b3cgZXhlY3V0aW9uIGN1cnJlbnRseSBydW5uaW5nLiBJZiB0aGUgd29ya2Zsb3cgaGFzIHN1
Y2NlZWRlZCBvcgogZmFpbGVkLCB0aGlzIGlzIHRoZSBsYXN0IGF0dGVtcHRlZCBvciBleGVj
dXRlZCBzdGVwLiBQcmVzZW50bHksIGlmIHRoZQogY3VycmVudCBzdGVwIGlzIGluc2lkZSBh
IHN1YndvcmtmbG93LCB0aGUgbGlzdCBvbmx5IGluY2x1ZGVzIHRoYXQgc3RlcC4KIEluIHRo
ZSBmdXR1cmUsIHRoZSBsaXN0IHdpbGwgY29udGFpbiBpdGVtcyBmb3IgZWFjaCBzdGVwIGlu
IHRoZSBjYWxsCiBzdGFjaywgc3RhcnRpbmcgd2l0aCB0aGUgb3V0ZXJtb3N0IHN0ZXAgaW4g
dGhlIGBtYWluYCBzdWJ3b3JrZmxvdywgYW5kCiBlbmRpbmcgd2l0aCB0aGUgbW9zdCBkZWVw
bHkgbmVzdGVkIHN0ZXAuCgoPCgcEAAMDAgAEEgTAAQQMCg8KBwQAAwMCAAYSBMABDREKDwoH
BAADAwIAARIEwAESHwoPCgcEAAMDAgADEgTAASIjClwKBAQAAwQSBsQBAtMBAxpMIERlc2Ny
aWJlcyBhbiBlcnJvciByZWxhdGVkIHRvIHRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBFeGVj
dXRpb24gcmVzb3VyY2UuCgoNCgUEAAMEARIExAEKFApCCgYEAAMEBAASBsYBBMwBBRowIERl
c2NyaWJlcyB0aGUgcG9zc2libGUgdHlwZXMgb2YgYSBzdGF0ZSBlcnJvci4KCg8KBwQAAwQE
AAESBMYBCQ0KJgoIBAADBAQAAgASBMgBBhsaFCBObyB0eXBlIHNwZWNpZmllZC4KChEKCQQA
AwQEAAIAARIEyAEGFgoRCgkEAAMEBAACAAISBMgBGRoKMAoIBAADBAQAAgESBMsBBhQaHiBD
YXVzZWQgYnkgYW4gaXNzdWUgd2l0aCBLTVMuCgoRCgkEAAMEBAACAQESBMsBBg8KEQoJBAAD
BAQAAgECEgTLARITCjUKBgQAAwQCABIEzwEEFxolIFByb3ZpZGVzIHNwZWNpZmljcyBhYm91
dCB0aGUgZXJyb3IuCgoPCgcEAAMEAgAFEgTPAQQKCg8KBwQAAwQCAAESBM8BCxIKDwoHBAAD
BAIAAxIEzwEVFgovCgYEAAMEAgESBNIBBBIaHyBUaGUgdHlwZSBvZiB0aGlzIHN0YXRlIGVy
cm9yLgoKDwoHBAADBAIBBhIE0gEECAoPCgcEAAMEAgEBEgTSAQkNCg8KBwQAAwQCAQMSBNIB
EBEKnwEKBAQAAgASBNgBAj4akAEgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBleGVjdXRpb24uCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vd29ya2Zsb3dzL3t3b3JrZmxvd30vZXhlY3V0aW9ucy97ZXhlY3V0aW9u
fQoKDQoFBAACAAUSBNgBAggKDQoFBAACAAESBNgBCQ0KDQoFBAACAAMSBNgBEBEKDQoFBAAC
AAgSBNgBEj0KEAoIBAACAAicCAASBNgBEzwKQAoEBAACARIG2wEC3AEyGjAgT3V0cHV0IG9u
bHkuIE1hcmtzIHRoZSBiZWdpbm5pbmcgb2YgZXhlY3V0aW9uLgoKDQoFBAACAQYSBNsBAhsK
DQoFBAACAQESBNsBHCYKDQoFBAACAQMSBNsBKSoKDQoFBAACAQgSBNwBBjEKEAoIBAACAQic
CAASBNwBBzAKTQoEBAACAhIG3wEC4AEyGj0gT3V0cHV0IG9ubHkuIE1hcmtzIHRoZSBlbmQg
b2YgZXhlY3V0aW9uLCBzdWNjZXNzZnVsIG9yIG5vdC4KCg0KBQQAAgIGEgTfAQIbCg0KBQQA
AgIBEgTfARwkCg0KBQQAAgIDEgTfAScoCg0KBQQAAgIIEgTgAQYxChAKCAQAAgIInAgAEgTg
AQcwCkYKBAQAAgMSBuMBAuQBMho2IE91dHB1dCBvbmx5LiBNZWFzdXJlcyB0aGUgZHVyYXRp
b24gb2YgdGhlIGV4ZWN1dGlvbi4KCg0KBQQAAgMGEgTjAQIaCg0KBQQAAgMBEgTjARsjCg0K
BQQAAgMDEgTjASYoCg0KBQQAAgMIEgTkAQYxChAKCAQAAgMInAgAEgTkAQcwCjwKBAQAAgQS
BOcBAj4aLiBPdXRwdXQgb25seS4gQ3VycmVudCBzdGF0ZSBvZiB0aGUgZXhlY3V0aW9uLgoK
DQoFBAACBAYSBOcBAgcKDQoFBAACBAESBOcBCA0KDQoFBAACBAMSBOcBEBEKDQoFBAACBAgS
BOcBEj0KEAoIBAACBAicCAASBOcBEzwKswIKBAQAAgUSBO8BAhYapAIgSW5wdXQgcGFyYW1l
dGVycyBvZiB0aGUgZXhlY3V0aW9uIHJlcHJlc2VudGVkIGFzIGEgSlNPTiBzdHJpbmcuCiBU
aGUgc2l6ZSBsaW1pdCBpcyAzMktCLgoKICpOb3RlKjogSWYgeW91IGFyZSB1c2luZyB0aGUg
UkVTVCBBUEkgZGlyZWN0bHkgdG8gcnVuIHlvdXIgd29ya2Zsb3csIHlvdQogbXVzdCBlc2Nh
cGUgYW55IEpTT04gc3RyaW5nIHZhbHVlIG9mIGBhcmd1bWVudGAuIEV4YW1wbGU6CiBgJ3si
YXJndW1lbnQiOiJ7XCJmaXJzdE5hbWVcIjpcIkZJUlNUXCIsXCJsYXN0TmFtZVwiOlwiTEFT
VFwifSJ9J2AKCg0KBQQAAgUFEgTvAQIICg0KBQQAAgUBEgTvAQkRCg0KBQQAAgUDEgTvARQV
CpsBCgQEAAIGEgTzAQJAGowBIE91dHB1dCBvbmx5LiBPdXRwdXQgb2YgdGhlIGV4ZWN1dGlv
biByZXByZXNlbnRlZCBhcyBhIEpTT04gc3RyaW5nLiBUaGUKIHZhbHVlIGNhbiBvbmx5IGJl
IHByZXNlbnQgaWYgdGhlIGV4ZWN1dGlvbidzIHN0YXRlIGlzIGBTVUNDRUVERURgLgoKDQoF
BAACBgUSBPMBAggKDQoFBAACBgESBPMBCQ8KDQoFBAACBgMSBPMBEhMKDQoFBAACBggSBPMB
FD8KEAoIBAACBgicCAASBPMBFT4KqgEKBAQAAgcSBPgBAj4amwEgT3V0cHV0IG9ubHkuIFRo
ZSBlcnJvciB3aGljaCBjYXVzZWQgdGhlIGV4ZWN1dGlvbiB0byBmaW5pc2ggcHJlbWF0dXJl
bHkuCiBUaGUgdmFsdWUgaXMgb25seSBwcmVzZW50IGlmIHRoZSBleGVjdXRpb24ncyBzdGF0
ZSBpcyBgRkFJTEVEYAogb3IgYENBTkNFTExFRGAuCgoNCgUEAAIHBhIE+AECBwoNCgUEAAIH
ARIE+AEIDQoNCgUEAAIHAxIE+AEQEQoNCgUEAAIHCBIE+AESPQoQCggEAAIHCJwIABIE+AET
PApOCgQEAAIIEgT7AQJOGkAgT3V0cHV0IG9ubHkuIFJldmlzaW9uIG9mIHRoZSB3b3JrZmxv
dyB0aGlzIGV4ZWN1dGlvbiBpcyB1c2luZy4KCg0KBQQAAggFEgT7AQIICg0KBQQAAggBEgT7
AQkdCg0KBQQAAggDEgT7ASAhCg0KBQQAAggIEgT7ASJNChAKCAQAAggInAgAEgT7ASNMCkQK
BAQAAgkSBP4BAiIaNiBUaGUgY2FsbCBsb2dnaW5nIGxldmVsIGFzc29jaWF0ZWQgdG8gdGhp
cyBleGVjdXRpb24uCgoNCgUEAAIJBhIE/gECDgoNCgUEAAIJARIE/gEPHQoNCgUEAAIJAxIE
/gEgIQpiCgQEAAIKEgSCAgJBGlQgT3V0cHV0IG9ubHkuIFN0YXR1cyB0cmFja3MgdGhlIGN1
cnJlbnQgc3RlcHMgYW5kIHByb2dyZXNzIGRhdGEgb2YgdGhpcwogZXhlY3V0aW9uLgoKDQoF
BAACCgYSBIICAggKDQoFBAACCgESBIICCQ8KDQoFBAACCgMSBIICEhQKDQoFBAACCggSBIIC
FUAKEAoIBAACCgicCAASBIICFj8KqwMKBAQAAgsSBIsCAiIanAMgTGFiZWxzIGFzc29jaWF0
ZWQgd2l0aCB0aGlzIGV4ZWN1dGlvbi4KIExhYmVscyBjYW4gY29udGFpbiBhdCBtb3N0IDY0
IGVudHJpZXMuIEtleXMgYW5kIHZhbHVlcyBjYW4gYmUgbm8gbG9uZ2VyCiB0aGFuIDYzIGNo
YXJhY3RlcnMgYW5kIGNhbiBvbmx5IGNvbnRhaW4gbG93ZXJjYXNlIGxldHRlcnMsIG51bWVy
aWMKIGNoYXJhY3RlcnMsIHVuZGVyc2NvcmVzLCBhbmQgZGFzaGVzLiBMYWJlbCBrZXlzIG11
c3Qgc3RhcnQgd2l0aCBhIGxldHRlci4KIEludGVybmF0aW9uYWwgY2hhcmFjdGVycyBhcmUg
YWxsb3dlZC4KIEJ5IGRlZmF1bHQsIGxhYmVscyBhcmUgaW5oZXJpdGVkIGZyb20gdGhlIHdv
cmtmbG93IGJ1dCBhcmUgb3ZlcnJpZGRlbiBieQogYW55IGxhYmVscyBhc3NvY2lhdGVkIHdp
dGggdGhlIGV4ZWN1dGlvbi4KCg0KBQQAAgsGEgSLAgIVCg0KBQQAAgsBEgSLAhYcCg0KBQQA
AgsDEgSLAh8hCs0BCgQEAAIMEgSQAgJKGr4BIE91dHB1dCBvbmx5LiBFcnJvciByZWdhcmRp
bmcgdGhlIHN0YXRlIG9mIHRoZSBFeGVjdXRpb24gcmVzb3VyY2UuIEZvcgogZXhhbXBsZSwg
dGhpcyBmaWVsZCB3aWxsIGhhdmUgZXJyb3IgZGV0YWlscyBpZiB0aGUgZXhlY3V0aW9uIGRh
dGEgaXMKIHVuYXZhaWxhYmxlIGR1ZSB0byByZXZva2VkIEtNUyBrZXkgcGVybWlzc2lvbnMu
CgoNCgUEAAIMBhIEkAICDAoNCgUEAAIMARIEkAINGAoNCgUEAAIMAxIEkAIbHQoNCgUEAAIM
CBIEkAIeSQoQCggEAAIMCJwIABIEkAIfSAo8CgIEARIGlgIAwAIBGi4gUmVxdWVzdCBmb3Ig
dGhlCiBbTGlzdEV4ZWN1dGlvbnNdW10KIG1ldGhvZC4KCgsKAwQBARIElgIIHQqiAQoEBAEC
ABIGmQICngIEGpEBIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSB3b3JrZmxvdyBmb3Igd2hpY2gg
dGhlIGV4ZWN1dGlvbnMgc2hvdWxkIGJlIGxpc3RlZC4KIEZvcm1hdDogcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3dvcmtmbG93cy97d29ya2Zsb3d9CgoNCgUE
AQIABRIEmQICCAoNCgUEAQIAARIEmQIJDwoNCgUEAQIAAxIEmQISEwoPCgUEAQIACBIGmQIU
ngIDChAKCAQBAgAInAgAEgSaAgQqChEKBwQBAgAInwgSBpsCBJ0CBQrDAgoEBAECARIEpQIC
Fhq0AiBNYXhpbXVtIG51bWJlciBvZiBleGVjdXRpb25zIHRvIHJldHVybiBwZXIgY2FsbC4K
IE1heCBzdXBwb3J0ZWQgdmFsdWUgZGVwZW5kcyBvbiB0aGUgc2VsZWN0ZWQgRXhlY3V0aW9u
IHZpZXc6IGl0J3MgMTAwMCBmb3IKIEJBU0lDIGFuZCAxMDAgZm9yIEZVTEwuIFRoZSBkZWZh
dWx0IHZhbHVlIHVzZWQgaWYgdGhlIGZpZWxkIGlzIG5vdAogc3BlY2lmaWVkIGlzIDEwMCwg
cmVnYXJkbGVzcyBvZiB0aGUgc2VsZWN0ZWQgdmlldy4gVmFsdWVzIGdyZWF0ZXIgdGhhbgog
dGhlIG1heCB2YWx1ZSB3aWxsIGJlIGNvZXJjZWQgZG93biB0byBpdC4KCg0KBQQBAgEFEgSl
AgIHCg0KBQQBAgEBEgSlAggRCg0KBQQBAgEDEgSlAhQVCusCCgQEAQICEgSvAgIYGtwCIEEg
cGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0RXhlY3V0aW9uc2Ag
Y2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoK
IFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExp
c3RFeGVjdXRpb25zYCBtdXN0CiBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBw
YWdlIHRva2VuLgoKIE5vdGUgdGhhdCBwYWdpbmF0aW9uIGlzIGFwcGxpZWQgdG8gZHluYW1p
YyBkYXRhLiBUaGUgbGlzdCBvZiBleGVjdXRpb25zCiByZXR1cm5lZCBjYW4gY2hhbmdlIGJl
dHdlZW4gcGFnZSByZXF1ZXN0cy4KCg0KBQQBAgIFEgSvAgIICg0KBQQBAgIBEgSvAgkTCg0K
BQQBAgIDEgSvAhYXCowBCgQEAQIDEgSzAgJCGn4gT3B0aW9uYWwuIEEgdmlldyBkZWZpbmlu
ZyB3aGljaCBmaWVsZHMgc2hvdWxkIGJlIGZpbGxlZCBpbiB0aGUgcmV0dXJuZWQKIGV4ZWN1
dGlvbnMuIFRoZSBBUEkgd2lsbCBkZWZhdWx0IHRvIHRoZSBCQVNJQyB2aWV3LgoKDQoFBAEC
AwYSBLMCAg8KDQoFBAECAwESBLMCEBQKDQoFBAECAwMSBLMCFxgKDQoFBAECAwgSBLMCGUEK
EAoIBAECAwicCAASBLMCGkAK5gEKBAQBAgQSBLkCAj0a1wEgT3B0aW9uYWwuIEZpbHRlcnMg
YXBwbGllZCB0byB0aGUgW0V4ZWN1dGlvbnMuTGlzdEV4ZWN1dGlvbnNdIHJlc3VsdHMuCiBU
aGUgZm9sbG93aW5nIGZpZWxkcyBhcmUgc3VwcG9ydGVkIGZvciBmaWx0ZXJpbmc6CiBleGVj
dXRpb25JRCwgc3RhdGUsIHN0YXJ0VGltZSwgZW5kVGltZSwgZHVyYXRpb24sIHdvcmtmbG93
UmV2aXNpb25JRCwKIHN0ZXBOYW1lLCBhbmQgbGFiZWwuCgoNCgUEAQIEBRIEuQICCAoNCgUE
AQIEARIEuQIJDwoNCgUEAQIEAxIEuQISEwoNCgUEAQIECBIEuQIUPAoQCggEAQIECJwIABIE
uQIVOwqUAgoEBAECBRIEvwICPxqFAiBPcHRpb25hbC4gVGhlIG9yZGVyaW5nIGFwcGxpZWQg
dG8gdGhlIFtFeGVjdXRpb25zLkxpc3RFeGVjdXRpb25zXSByZXN1bHRzLgogQnkgZGVmYXVs
dCB0aGUgb3JkZXJpbmcgaXMgYmFzZWQgb24gZGVzY2VuZGluZyBzdGFydCB0aW1lLgogVGhl
IGZvbGxvd2luZyBmaWVsZHMgYXJlIHN1cHBvcnRlZCBmb3Igb3JkZXIgYnk6CiBleGVjdXRp
b25JRCwgc3RhcnRUaW1lLCBlbmRUaW1lLCBkdXJhdGlvbiwgc3RhdGUsIGFuZCB3b3JrZmxv
d1JldmlzaW9uSUQuCgoNCgUEAQIFBRIEvwICCAoNCgUEAQIFARIEvwIJEQoNCgUEAQIFAxIE
vwIUFQoNCgUEAQIFCBIEvwIWPgoQCggEAQIFCJwIABIEvwIXPQp7CgIEAhIGxQIAzAIBGm0g
UmVzcG9uc2UgZm9yIHRoZQogW0xpc3RFeGVjdXRpb25zXVtnb29nbGUuY2xvdWQud29ya2Zs
b3dzLmV4ZWN1dGlvbnMudjEuRXhlY3V0aW9ucy5MaXN0RXhlY3V0aW9uc10KIG1ldGhvZC4K
CgsKAwQCARIExQIIHgo3CgQEAgIAEgTHAgIkGikgVGhlIGV4ZWN1dGlvbnMgd2hpY2ggbWF0
Y2ggdGhlIHJlcXVlc3QuCgoNCgUEAgIABBIExwICCgoNCgUEAgIABhIExwILFAoNCgUEAgIA
ARIExwIVHwoNCgUEAgIAAxIExwIiIwqQAQoEBAICARIEywICHRqBASBBIHRva2VuLCB3aGlj
aCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFn
ZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQg
cGFnZXMuCgoNCgUEAgIBBRIEywICCAoNCgUEAgIBARIEywIJGAoNCgUEAgIBAxIEywIbHAp8
CgIEAxIG0QIA3gIBGm4gUmVxdWVzdCBmb3IgdGhlCiBbQ3JlYXRlRXhlY3V0aW9uXVtnb29n
bGUuY2xvdWQud29ya2Zsb3dzLmV4ZWN1dGlvbnMudjEuRXhlY3V0aW9ucy5DcmVhdGVFeGVj
dXRpb25dCiBtZXRob2QuCgoLCgMEAwESBNECCB4K1AEKBAQDAgASBtUCAtoCBBrDASBSZXF1
aXJlZC4gTmFtZSBvZiB0aGUgd29ya2Zsb3cgZm9yIHdoaWNoIGFuIGV4ZWN1dGlvbiBzaG91
bGQgYmUgY3JlYXRlZC4KIEZvcm1hdDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L3dvcmtmbG93cy97d29ya2Zsb3d9CiBUaGUgbGF0ZXN0IHJldmlzaW9uIG9m
IHRoZSB3b3JrZmxvdyB3aWxsIGJlIHVzZWQuCgoNCgUEAwIABRIE1QICCAoNCgUEAwIAARIE
1QIJDwoNCgUEAwIAAxIE1QISEwoPCgUEAwIACBIG1QIU2gIDChAKCAQDAgAInAgAEgTWAgQq
ChEKBwQDAgAInwgSBtcCBNkCBQoyCgQEAwIBEgTdAgJDGiQgUmVxdWlyZWQuIEV4ZWN1dGlv
biB0byBiZSBjcmVhdGVkLgoKDQoFBAMCAQYSBN0CAgsKDQoFBAMCAQESBN0CDBUKDQoFBAMC
AQMSBN0CGBkKDQoFBAMCAQgSBN0CGkIKEAoIBAMCAQicCAASBN0CG0EKdgoCBAQSBuMCAPEC
ARpoIFJlcXVlc3QgZm9yIHRoZQogW0dldEV4ZWN1dGlvbl1bZ29vZ2xlLmNsb3VkLndvcmtm
bG93cy5leGVjdXRpb25zLnYxLkV4ZWN1dGlvbnMuR2V0RXhlY3V0aW9uXQogbWV0aG9kLgoK
CwoDBAQBEgTjAggbCqEBCgQEBAIAEgbnAgLsAgQakAEgUmVxdWlyZWQuIE5hbWUgb2YgdGhl
IGV4ZWN1dGlvbiB0byBiZSByZXRyaWV2ZWQuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vd29ya2Zsb3dzL3t3b3JrZmxvd30vZXhlY3V0aW9u
cy97ZXhlY3V0aW9ufQoKDQoFBAQCAAUSBOcCAggKDQoFBAQCAAESBOcCCQ0KDQoFBAQCAAMS
BOcCEBEKDwoFBAQCAAgSBucCEuwCAwoQCggEBAIACJwIABIE6AIEKgoRCgcEBAIACJ8IEgbp
AgTrAgUKigEKBAQEAgESBPACAkIafCBPcHRpb25hbC4gQSB2aWV3IGRlZmluaW5nIHdoaWNo
IGZpZWxkcyBzaG91bGQgYmUgZmlsbGVkIGluIHRoZSByZXR1cm5lZAogZXhlY3V0aW9uLiBU
aGUgQVBJIHdpbGwgZGVmYXVsdCB0byB0aGUgRlVMTCB2aWV3LgoKDQoFBAQCAQYSBPACAg8K
DQoFBAQCAQESBPACEBQKDQoFBAQCAQMSBPACFxgKDQoFBAQCAQgSBPACGUEKEAoIBAQCAQic
CAASBPACGkAKfAoCBAUSBvYCAIADARpuIFJlcXVlc3QgZm9yIHRoZQogW0NhbmNlbEV4ZWN1
dGlvbl1bZ29vZ2xlLmNsb3VkLndvcmtmbG93cy5leGVjdXRpb25zLnYxLkV4ZWN1dGlvbnMu
Q2FuY2VsRXhlY3V0aW9uXQogbWV0aG9kLgoKCwoDBAUBEgT2AggeCqEBCgQEBQIAEgb6AgL/
AgQakAEgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGV4ZWN1dGlvbiB0byBiZSBjYW5jZWxsZWQu
CiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vd29y
a2Zsb3dzL3t3b3JrZmxvd30vZXhlY3V0aW9ucy97ZXhlY3V0aW9ufQoKDQoFBAUCAAUSBPoC
AggKDQoFBAUCAAESBPoCCQ0KDQoFBAUCAAMSBPoCEBEKDwoFBAUCAAgSBvoCEv8CAwoQCggE
BQIACJwIABIE+wIEKgoRCgcEBQIACJ8IEgb8AgT+AgUKPgoCBQASBoMDAI4DARowIERlZmlu
ZXMgcG9zc2libGUgdmlld3MgZm9yIGV4ZWN1dGlvbiByZXNvdXJjZS4KCgsKAwUAARIEgwMF
EgoqCgQFAAIAEgSFAwIhGhwgVGhlIGRlZmF1bHQgLyB1bnNldCB2YWx1ZS4KCg0KBQUAAgAB
EgSFAwIcCg0KBQUAAgACEgSFAx8gCq4BCgQFAAIBEgSKAwIMGp8BIEluY2x1ZGVzIG9ubHkg
YmFzaWMgbWV0YWRhdGEgYWJvdXQgdGhlIGV4ZWN1dGlvbi4KIFRoZSBmb2xsb3dpbmcgZmll
bGRzIGFyZSByZXR1cm5lZDogbmFtZSwgc3RhcnRfdGltZSwgZW5kX3RpbWUsIGR1cmF0aW9u
LAogc3RhdGUsIGFuZCB3b3JrZmxvd19yZXZpc2lvbl9pZC4KCg0KBQUAAgEBEgSKAwIHCg0K
BQUAAgECEgSKAwoLCiIKBAUAAgISBI0DAgsaFCBJbmNsdWRlcyBhbGwgZGF0YS4KCg0KBQUA
AgIBEgSNAwIGCg0KBQUAAgICEgSNAwkKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Workflows::Executions::V1::Executions::Execution ===
    # Fields for Execution
    # Field: name Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: duration Type: 11 (.google.protobuf.Duration)
    # Field: state Type: 14 (.google.cloud.workflows.executions.v1.Execution.State)
    # Field: argument Type: 9 ()
    # Field: result Type: 9 ()
    # Field: error Type: 11 (.google.cloud.workflows.executions.v1.Execution.Error)
    # Field: workflow_revision_id Type: 9 ()
    # Field: call_log_level Type: 14 (.google.cloud.workflows.executions.v1.Execution.CallLogLevel)
    # Field: status Type: 11 (.google.cloud.workflows.executions.v1.Execution.Status)
    # Field: labels Type: 11 (.google.cloud.workflows.executions.v1.Execution.LabelsEntry)
    # Field: state_error Type: 11 (.google.cloud.workflows.executions.v1.Execution.StateError)

# Enum: Execution::State
our $Execution_STATE_UNSPECIFIED = 0;
our $Execution_ACTIVE = 1;
our $Execution_SUCCEEDED = 2;
our $Execution_FAILED = 3;
our $Execution_CANCELLED = 4;
our $Execution_UNAVAILABLE = 5;
our $Execution_QUEUED = 6;

# Enum: Execution::CallLogLevel
our $Execution_CALL_LOG_LEVEL_UNSPECIFIED = 0;
our $Execution_LOG_ALL_CALLS = 1;
our $Execution_LOG_ERRORS_ONLY = 2;
our $Execution_LOG_NONE = 3;

# === Message: Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsRequest ===
    # Fields for ListExecutionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: view Type: 14 (.google.cloud.workflows.executions.v1.ExecutionView)
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsResponse ===
    # Fields for ListExecutionsResponse
    # Field: executions Type: 11 (.google.cloud.workflows.executions.v1.Execution)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Workflows::Executions::V1::Executions::CreateExecutionRequest ===
    # Fields for CreateExecutionRequest
    # Field: parent Type: 9 ()
    # Field: execution Type: 11 (.google.cloud.workflows.executions.v1.Execution)

# === Message: Google::Cloud::Workflows::Executions::V1::Executions::GetExecutionRequest ===
    # Fields for GetExecutionRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.cloud.workflows.executions.v1.ExecutionView)

# === Message: Google::Cloud::Workflows::Executions::V1::Executions::CancelExecutionRequest ===
    # Fields for CancelExecutionRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Workflows::Executions::V1::Executions::ExecutionsClient ===
package Google::Cloud::Workflows::Executions::V1::Executions::ExecutionsClient;

=pod

=head2 Service Client: Google::Cloud::Workflows::Executions::V1::Executions::ExecutionsClient

Client stub representing the remote C<Executions> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<workflows.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'workflows.googleapis.com:443' );

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

sub list_executions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.executions.v1.Executions',
        method         => 'ListExecutions',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsResponse',
    });
}

sub create_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::Executions::V1::Executions::CreateExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.executions.v1.Executions',
        method         => 'CreateExecution',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::Executions::V1::Executions::Execution',
    });
}

sub get_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::Executions::V1::Executions::GetExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.executions.v1.Executions',
        method         => 'GetExecution',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::Executions::V1::Executions::Execution',
    });
}

sub cancel_execution {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::Executions::V1::Executions::CancelExecutionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.executions.v1.Executions',
        method         => 'CancelExecution',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::Executions::V1::Executions::Execution',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Workflows::Executions::V1::Executions - Compiled Protocol Buffers messages for google/cloud/workflows/executions/v1/executions.proto

=head1 SYNOPSIS

    use Google::Cloud::Workflows::Executions::V1::Executions;

    my $msg = Google::Cloud::Workflows::Executions::V1::Executions::Execution->new({
        name => $name,
        start_time => $start_time,
        end_time => $end_time,
        duration => $duration,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Workflows::Executions::V1::Executions::Execution->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/workflows/executions/v1/executions.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Workflows::Executions::V1::Executions::Execution

A running instance of a
[Workflow](/workflows/docs/reference/rest/v1/projects.locations.workflows).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the execution.
Format:
projects/{project}/locations/{location}/workflows/{workflow}/executions/{execution}

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Marks the beginning of execution.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Marks the end of execution, successful or not.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. Measures the duration of the execution.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Workflows::Executions::V1::Execution::State>)

Output only. Current state of the execution.

=item * C<< $msg->argument() >> / C<< $msg->argument($value) >>

Type: C<String>

Input parameters of the execution represented as a JSON string.
The size limit is 32KB.

*Note*: If you are using the REST API directly to run your workflow, you
must escape any JSON string value of `argument`. Example:
`'{"argument":"{\"firstName\":\"FIRST\",\"lastName\":\"LAST\"}"}'`

=item * C<< $msg->result() >> / C<< $msg->result($value) >>

Type: C<String>

Output only. Output of the execution represented as a JSON string. The
value can only be present if the execution's state is `SUCCEEDED`.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1::Executions::Execution::Error>)

Output only. The error which caused the execution to finish prematurely.
The value is only present if the execution's state is `FAILED`
or `CANCELLED`.

=item * C<< $msg->workflow_revision_id() >> / C<< $msg->workflow_revision_id($value) >>

Type: C<String>

Output only. Revision of the workflow this execution is using.

=item * C<< $msg->call_log_level() >> / C<< $msg->call_log_level($value) >>

Type: C<Enum> (L<Google::Cloud::Workflows::Executions::V1::Execution::CallLogLevel>)

The call logging level associated to this execution.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1::Executions::Execution::Status>)

Output only. Status tracks the current steps and progress data of this
execution.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1::Executions::Execution::LabelsEntry>)

Labels associated with this execution.
Labels can contain at most 64 entries. Keys and values can be no longer
than 63 characters and can only contain lowercase letters, numeric
characters, underscores, and dashes. Label keys must start with a letter.
International characters are allowed.
By default, labels are inherited from the workflow but are overridden by
any labels associated with the execution.

=item * C<< $msg->state_error() >> / C<< $msg->state_error($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1::Executions::Execution::StateError>)

Output only. Error regarding the state of the Execution resource. For
example, this field will have error details if the execution data is
unavailable due to revoked KMS key permissions.

=back

=head3 Enum: Execution::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<SUCCEEDED> => C<2>

=item * C<FAILED> => C<3>

=item * C<CANCELLED> => C<4>

=item * C<UNAVAILABLE> => C<5>

=item * C<QUEUED> => C<6>

=back

=head3 Enum: Execution::CallLogLevel

=over 4

=item * C<CALL_LOG_LEVEL_UNSPECIFIED> => C<0>

=item * C<LOG_ALL_CALLS> => C<1>

=item * C<LOG_ERRORS_ONLY> => C<2>

=item * C<LOG_NONE> => C<3>

=back

=head2 Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsRequest

Request for the
[ListExecutions][]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of the workflow for which the executions should be listed.
Format: projects/{project}/locations/{location}/workflows/{workflow}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of executions to return per call.
Max supported value depends on the selected Execution view: it's 1000 for
BASIC and 100 for FULL. The default value used if the field is not
specified is 100, regardless of the selected view. Values greater than
the max value will be coerced down to it.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListExecutions` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListExecutions` must
match the call that provided the page token.

Note that pagination is applied to dynamic data. The list of executions
returned can change between page requests.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Workflows::Executions::V1::ExecutionView>)

Optional. A view defining which fields should be filled in the returned
executions. The API will default to the BASIC view.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filters applied to the [Executions.ListExecutions] results.
The following fields are supported for filtering:
executionID, state, startTime, endTime, duration, workflowRevisionID,
stepName, and label.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. The ordering applied to the [Executions.ListExecutions] results.
By default the ordering is based on descending start time.
The following fields are supported for order by:
executionID, startTime, endTime, duration, state, and workflowRevisionID.

=back

=head2 Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsResponse

Response for the
[ListExecutions][google.cloud.workflows.executions.v1.Executions.ListExecutions]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->executions() >> / C<< $msg->executions($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1::Executions::Execution>)

The executions which match the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Workflows::Executions::V1::Executions::CreateExecutionRequest

Request for the
[CreateExecution][google.cloud.workflows.executions.v1.Executions.CreateExecution]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of the workflow for which an execution should be created.
Format: projects/{project}/locations/{location}/workflows/{workflow}
The latest revision of the workflow will be used.

=item * C<< $msg->execution() >> / C<< $msg->execution($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::Executions::V1::Executions::Execution>)

Required. Execution to be created.

=back

=head2 Google::Cloud::Workflows::Executions::V1::Executions::GetExecutionRequest

Request for the
[GetExecution][google.cloud.workflows.executions.v1.Executions.GetExecution]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the execution to be retrieved.
Format:
projects/{project}/locations/{location}/workflows/{workflow}/executions/{execution}

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Workflows::Executions::V1::ExecutionView>)

Optional. A view defining which fields should be filled in the returned
execution. The API will default to the FULL view.

=back

=head2 Google::Cloud::Workflows::Executions::V1::Executions::CancelExecutionRequest

Request for the
[CancelExecution][google.cloud.workflows.executions.v1.Executions.CancelExecution]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the execution to be cancelled.
Format:
projects/{project}/locations/{location}/workflows/{workflow}/executions/{execution}

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Workflows::Executions::V1::Executions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
