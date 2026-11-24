package Google::Cloud::Shell::V1::Cloudshell;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvc2hlbGwvdjEvY2xvdWRzaGVsbC5wcm90bxIVZ29vZ2xlLmNsb3Vk
LnNoZWxsLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2Ns
aWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ihQQKC0Vudmlyb25tZW50EhcKBG5h
bWUYASABKAlCA+BBBVIEbmFtZRITCgJpZBgCIAEoCUID4EEDUgJpZBIpCgxkb2NrZXJfaW1h
Z2UYAyABKAlCBuBBAuBBBVILZG9ja2VySW1hZ2USQwoFc3RhdGUYBCABKA4yKC5nb29nbGUu
Y2xvdWQuc2hlbGwudjEuRW52aXJvbm1lbnQuU3RhdGVCA+BBA1IFc3RhdGUSHgoId2ViX2hv
c3QYDCABKAlCA+BBA1IHd2ViSG9zdBImCgxzc2hfdXNlcm5hbWUYBSABKAlCA+BBA1ILc3No
VXNlcm5hbWUSHgoIc3NoX2hvc3QYBiABKAlCA+BBA1IHc3NoSG9zdBIeCghzc2hfcG9ydBgH
IAEoBUID4EEDUgdzc2hQb3J0EiQKC3B1YmxpY19rZXlzGAggAygJQgPgQQNSCnB1YmxpY0tl
eXMiVQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABINCglTVVNQRU5ERUQQARILCgdQ
RU5ESU5HEAISCwoHUlVOTklORxADEgwKCERFTEVUSU5HEAQ6U+pBUAolY2xvdWRzaGVsbC5n
b29nbGVhcGlzLmNvbS9FbnZpcm9ubWVudBIndXNlcnMve3VzZXJ9L2Vudmlyb25tZW50cy97
ZW52aXJvbm1lbnR9IloKFUdldEVudmlyb25tZW50UmVxdWVzdBJBCgRuYW1lGAEgASgJQi3g
QQL6QScKJWNsb3Vkc2hlbGwuZ29vZ2xlYXBpcy5jb20vRW52aXJvbm1lbnRSBG5hbWUiGwoZ
Q3JlYXRlRW52aXJvbm1lbnRNZXRhZGF0YSIbChlEZWxldGVFbnZpcm9ubWVudE1ldGFkYXRh
InEKF1N0YXJ0RW52aXJvbm1lbnRSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUSIQoMYWNj
ZXNzX3Rva2VuGAIgASgJUgthY2Nlc3NUb2tlbhIfCgtwdWJsaWNfa2V5cxgDIAMoCVIKcHVi
bGljS2V5cyKsAQobQXV0aG9yaXplRW52aXJvbm1lbnRSZXF1ZXN0EhIKBG5hbWUYASABKAlS
BG5hbWUSIQoMYWNjZXNzX3Rva2VuGAIgASgJUgthY2Nlc3NUb2tlbhIZCghpZF90b2tlbhgE
IAEoCVIHaWRUb2tlbhI7CgtleHBpcmVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSCmV4cGlyZVRpbWUiHgocQXV0aG9yaXplRW52aXJvbm1lbnRSZXNwb25zZSIe
ChxBdXRob3JpemVFbnZpcm9ubWVudE1ldGFkYXRhItkBChhTdGFydEVudmlyb25tZW50TWV0
YWRhdGESSwoFc3RhdGUYASABKA4yNS5nb29nbGUuY2xvdWQuc2hlbGwudjEuU3RhcnRFbnZp
cm9ubWVudE1ldGFkYXRhLlN0YXRlUgVzdGF0ZSJwCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJ
RklFRBAAEgwKCFNUQVJUSU5HEAESFAoQVU5BUkNISVZJTkdfRElTSxACEh4KGkFXQUlUSU5H
X0NPTVBVVEVfUkVTT1VSQ0VTEAQSDAoIRklOSVNIRUQQAyJgChhTdGFydEVudmlyb25tZW50
UmVzcG9uc2USRAoLZW52aXJvbm1lbnQYASABKAsyIi5nb29nbGUuY2xvdWQuc2hlbGwudjEu
RW52aXJvbm1lbnRSC2Vudmlyb25tZW50IkkKE0FkZFB1YmxpY0tleVJlcXVlc3QSIAoLZW52
aXJvbm1lbnQYASABKAlSC2Vudmlyb25tZW50EhAKA2tleRgCIAEoCVIDa2V5IigKFEFkZFB1
YmxpY0tleVJlc3BvbnNlEhAKA2tleRgBIAEoCVIDa2V5IhYKFEFkZFB1YmxpY0tleU1ldGFk
YXRhIkwKFlJlbW92ZVB1YmxpY0tleVJlcXVlc3QSIAoLZW52aXJvbm1lbnQYASABKAlSC2Vu
dmlyb25tZW50EhAKA2tleRgCIAEoCVIDa2V5IhkKF1JlbW92ZVB1YmxpY0tleVJlc3BvbnNl
IhkKF1JlbW92ZVB1YmxpY0tleU1ldGFkYXRhIqQCChZDbG91ZFNoZWxsRXJyb3JEZXRhaWxz
ElUKBGNvZGUYASABKA4yQS5nb29nbGUuY2xvdWQuc2hlbGwudjEuQ2xvdWRTaGVsbEVycm9y
RGV0YWlscy5DbG91ZFNoZWxsRXJyb3JDb2RlUgRjb2RlIrIBChNDbG91ZFNoZWxsRXJyb3JD
b2RlEiYKIkNMT1VEX1NIRUxMX0VSUk9SX0NPREVfVU5TUEVDSUZJRUQQABIVChFJTUFHRV9V
TkFWQUlMQUJMRRABEhgKFENMT1VEX1NIRUxMX0RJU0FCTEVEEAISEQoNVE9TX1ZJT0xBVElP
ThAEEhIKDlFVT1RBX0VYQ0VFREVEEAUSGwoXRU5WSVJPTk1FTlRfVU5BVkFJTEFCTEUQBjLU
CAoRQ2xvdWRTaGVsbFNlcnZpY2USlAEKDkdldEVudmlyb25tZW50EiwuZ29vZ2xlLmNsb3Vk
LnNoZWxsLnYxLkdldEVudmlyb25tZW50UmVxdWVzdBoiLmdvb2dsZS5jbG91ZC5zaGVsbC52
MS5FbnZpcm9ubWVudCIwgtPkkwIjEiEvdjEve25hbWU9dXNlcnMvKi9lbnZpcm9ubWVudHMv
Kn3aQQRuYW1lEswBChBTdGFydEVudmlyb25tZW50Ei4uZ29vZ2xlLmNsb3VkLnNoZWxsLnYx
LlN0YXJ0RW52aXJvbm1lbnRSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
biJpgtPkkwIsIicvdjEve25hbWU9dXNlcnMvKi9lbnZpcm9ubWVudHMvKn06c3RhcnQ6ASrK
QTQKGFN0YXJ0RW52aXJvbm1lbnRSZXNwb25zZRIYU3RhcnRFbnZpcm9ubWVudE1ldGFkYXRh
EuABChRBdXRob3JpemVFbnZpcm9ubWVudBIyLmdvb2dsZS5jbG91ZC5zaGVsbC52MS5BdXRo
b3JpemVFbnZpcm9ubWVudFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9u
InWC0+STAjAiKy92MS97bmFtZT11c2Vycy8qL2Vudmlyb25tZW50cy8qfTphdXRob3JpemU6
ASrKQTwKHEF1dGhvcml6ZUVudmlyb25tZW50UmVzcG9uc2USHEF1dGhvcml6ZUVudmlyb25t
ZW50TWV0YWRhdGESygEKDEFkZFB1YmxpY0tleRIqLmdvb2dsZS5jbG91ZC5zaGVsbC52MS5B
ZGRQdWJsaWNLZXlSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJvgtPk
kwI6IjUvdjEve2Vudmlyb25tZW50PXVzZXJzLyovZW52aXJvbm1lbnRzLyp9OmFkZFB1Ymxp
Y0tleToBKspBLAoUQWRkUHVibGljS2V5UmVzcG9uc2USFEFkZFB1YmxpY0tleU1ldGFkYXRh
EtkBCg9SZW1vdmVQdWJsaWNLZXkSLS5nb29nbGUuY2xvdWQuc2hlbGwudjEuUmVtb3ZlUHVi
bGljS2V5UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ieILT5JMCPSI4
L3YxL3tlbnZpcm9ubWVudD11c2Vycy8qL2Vudmlyb25tZW50cy8qfTpyZW1vdmVQdWJsaWNL
ZXk6ASrKQTIKF1JlbW92ZVB1YmxpY0tleVJlc3BvbnNlEhdSZW1vdmVQdWJsaWNLZXlNZXRh
ZGF0YRpNykEZY2xvdWRzaGVsbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CXwoZY29tLmdvb2dsZS5jbG91ZC5zaGVs
bC52MUIPQ2xvdWRTaGVsbFByb3RvUAFaL2Nsb3VkLmdvb2dsZS5jb20vZ28vc2hlbGwvYXBp
djEvc2hlbGxwYjtzaGVsbHBiSqhtCgcSBQ4AhgMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAeCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAAp
CgkKAgMDEgMVACMKCQoCAwQSAxYALQoJCgIDBRIDFwApCggKAQgSAxkARgoJCgIICxIDGQBG
CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMAoJCgIICBIDGwAwCggKAQgSAxwAMgoJ
CgIIARIDHAAyCtkDCgIGABIEJQBtARrMAyBBUEkgZm9yIGludGVyYWN0aW5nIHdpdGggR29v
Z2xlIENsb3VkIFNoZWxsLiBFYWNoIHVzZXIgb2YgQ2xvdWQgU2hlbGwgaGFzIGF0CiBsZWFz
dCBvbmUgZW52aXJvbm1lbnQsIHdoaWNoIGhhcyB0aGUgSUQgImRlZmF1bHQiLiBFbnZpcm9u
bWVudCBjb25zaXN0cyBvZiBhCiBEb2NrZXIgaW1hZ2UgZGVmaW5pbmcgd2hhdCBpcyBpbnN0
YWxsZWQgb24gdGhlIGVudmlyb25tZW50IGFuZCBhIGhvbWUKIGRpcmVjdG9yeSBjb250YWlu
aW5nIHRoZSB1c2VyJ3MgZGF0YSB0aGF0IHdpbGwgcmVtYWluIGFjcm9zcyBzZXNzaW9ucy4K
IENsaWVudHMgdXNlIHRoaXMgQVBJIHRvIHN0YXJ0IGFuZCBmZXRjaCBpbmZvcm1hdGlvbiBh
Ym91dCB0aGVpciBlbnZpcm9ubWVudCwKIHdoaWNoIGNhbiB0aGVuIGJlIHVzZWQgdG8gY29u
bmVjdCB0byB0aGF0IGVudmlyb25tZW50IHZpYSBhIHNlcGFyYXRlIFNTSAogY2xpZW50LgoK
CgoDBgABEgMlCBkKCgoDBgADEgMmAkEKDAoFBgADmQgSAyYCQQoKCgMGAAMSAycCVgoMCgUG
AAOaCBIDJwJWClkKBAYAAgASBCoCLwMaSyBHZXRzIGFuIGVudmlyb25tZW50LiBSZXR1cm5z
IE5PVF9GT1VORCBpZiB0aGUgZW52aXJvbm1lbnQgZG9lcyBub3QgZXhpc3QuCgoMCgUGAAIA
ARIDKgYUCgwKBQYAAgACEgMqFSoKDAoFBgACAAMSAyo1QAoNCgUGAAIABBIEKwQtBgoRCgkG
AAIABLDKvCISBCsELQYKDAoFBgACAAQSAy4EMgoPCggGAAIABJsIABIDLgQyCq8DCgQGAAIB
EgQ3AkADGqADIFN0YXJ0cyBhbiBleGlzdGluZyBlbnZpcm9ubWVudCwgYWxsb3dpbmcgY2xp
ZW50cyB0byBjb25uZWN0IHRvIGl0LiBUaGUKIHJldHVybmVkIG9wZXJhdGlvbiB3aWxsIGNv
bnRhaW4gYW4gaW5zdGFuY2Ugb2YgU3RhcnRFbnZpcm9ubWVudE1ldGFkYXRhIGluCiBpdHMg
bWV0YWRhdGEgZmllbGQuIFVzZXJzIGNhbiB3YWl0IGZvciB0aGUgZW52aXJvbm1lbnQgdG8g
c3RhcnQgYnkgcG9sbGluZwogdGhpcyBvcGVyYXRpb24gdmlhIEdldE9wZXJhdGlvbi4gT25j
ZSB0aGUgZW52aXJvbm1lbnQgaGFzIGZpbmlzaGVkIHN0YXJ0aW5nCiBhbmQgaXMgcmVhZHkg
dG8gYWNjZXB0IGNvbm5lY3Rpb25zLCB0aGUgb3BlcmF0aW9uIHdpbGwgY29udGFpbiBhCiBT
dGFydEVudmlyb25tZW50UmVzcG9uc2UgaW4gaXRzIHJlc3BvbnNlIGZpZWxkLgoKDAoFBgAC
AQESAzcGFgoMCgUGAAIBAhIDNxcuCgwKBQYAAgEDEgM3OVUKDQoFBgACAQQSBDgEOwYKEQoJ
BgACAQSwyrwiEgQ4BDsGCg0KBQYAAgEEEgQ8BD8GCg8KBwYAAgEEmQgSBDwEPwYK9QEKBAYA
AgISBEYCTwMa5gEgU2VuZHMgT0F1dGggY3JlZGVudGlhbHMgdG8gYSBydW5uaW5nIGVudmly
b25tZW50IG9uIGJlaGFsZiBvZiBhIHVzZXIuIFdoZW4KIHRoaXMgY29tcGxldGVzLCB0aGUg
ZW52aXJvbm1lbnQgd2lsbCBiZSBhdXRob3JpemVkIHRvIHJ1biB2YXJpb3VzIEdvb2dsZQog
Q2xvdWQgY29tbWFuZCBsaW5lIHRvb2xzIHdpdGhvdXQgcmVxdWlyaW5nIHRoZSB1c2VyIHRv
IG1hbnVhbGx5CiBhdXRoZW50aWNhdGUuCgoMCgUGAAICARIDRgYaCgwKBQYAAgICEgNGGzYK
DAoFBgACAgMSA0ZBXQoNCgUGAAICBBIERwRKBgoRCgkGAAICBLDKvCISBEcESgYKDQoFBgAC
AgQSBEsETgYKDwoHBgACAgSZCBIESwROBgrrAQoEBgACAxIEVAJdAxrcASBBZGRzIGEgcHVi
bGljIFNTSCBrZXkgdG8gYW4gZW52aXJvbm1lbnQsIGFsbG93aW5nIGNsaWVudHMgd2l0aCB0
aGUKIGNvcnJlc3BvbmRpbmcgcHJpdmF0ZSBrZXkgdG8gY29ubmVjdCB0byB0aGF0IGVudmly
b25tZW50IHZpYSBTU0guIElmIGEga2V5CiB3aXRoIHRoZSBzYW1lIGNvbnRlbnQgYWxyZWFk
eSBleGlzdHMsIHRoaXMgd2lsbCBlcnJvciB3aXRoIEFMUkVBRFlfRVhJU1RTLgoKDAoFBgAC
AwESA1QGEgoMCgUGAAIDAhIDVBMmCgwKBQYAAgMDEgNUMU0KDQoFBgACAwQSBFUEWAYKEQoJ
BgACAwSwyrwiEgRVBFgGCg0KBQYAAgMEEgRZBFwGCg8KBwYAAgMEmQgSBFkEXAYK8gEKBAYA
AgQSBGMCbAMa4wEgUmVtb3ZlcyBhIHB1YmxpYyBTU0gga2V5IGZyb20gYW4gZW52aXJvbm1l
bnQuIENsaWVudHMgd2lsbCBubyBsb25nZXIgYmUKIGFibGUgdG8gY29ubmVjdCB0byB0aGUg
ZW52aXJvbm1lbnQgdXNpbmcgdGhlIGNvcnJlc3BvbmRpbmcgcHJpdmF0ZSBrZXkuCiBJZiBh
IGtleSB3aXRoIHRoZSBzYW1lIGNvbnRlbnQgaXMgbm90IHByZXNlbnQsIHRoaXMgd2lsbCBl
cnJvciB3aXRoCiBOT1RfRk9VTkQuCgoMCgUGAAIEARIDYwYVCgwKBQYAAgQCEgNjFiwKDAoF
BgACBAMSA2M3UwoNCgUGAAIEBBIEZARnBgoRCgkGAAIEBLDKvCISBGQEZwYKDQoFBgACBAQS
BGgEawYKDwoHBgACBASZCBIEaARrBgqiAgoCBAASBXMAugEBGpQCIEEgQ2xvdWQgU2hlbGwg
ZW52aXJvbm1lbnQsIHdoaWNoIGlzIGRlZmluZWQgYXMgdGhlIGNvbWJpbmF0aW9uIG9mIGEg
RG9ja2VyCiBpbWFnZSBzcGVjaWZ5aW5nIHdoYXQgaXMgaW5zdGFsbGVkIG9uIHRoZSBlbnZp
cm9ubWVudCBhbmQgYSBob21lIGRpcmVjdG9yeQogY29udGFpbmluZyB0aGUgdXNlcidzIGRh
dGEgdGhhdCB3aWxsIHJlbWFpbiBhY3Jvc3Mgc2Vzc2lvbnMuIEVhY2ggdXNlciBoYXMKIGF0
IGxlYXN0IGFuIGVudmlyb25tZW50IHdpdGggdGhlIElEICJkZWZhdWx0Ii4KCgoKAwQAARID
cwgTCgsKAwQABxIEdAJ3BAoNCgUEAAedCBIEdAJ3BAo+CgQEAAQAEgV6Ao0BAxovIFBvc3Np
YmxlIGV4ZWN1dGlvbiBzdGF0ZXMgZm9yIGFuIGVudmlyb25tZW50LgoKDAoFBAAEAAESA3oH
DAo1CgYEAAQAAgASA3wEGhomIFRoZSBlbnZpcm9ubWVudCdzIHN0YXRlcyBpcyB1bmtub3du
LgoKDgoHBAAEAAIAARIDfAQVCg4KBwQABAACAAISA3wYGQqOAQoGBAAEAAIBEgSAAQQSGn4g
VGhlIGVudmlyb25tZW50IGlzIG5vdCBydW5uaW5nIGFuZCBjYW4ndCBiZSBjb25uZWN0ZWQg
dG8uIFN0YXJ0aW5nIHRoZQogZW52aXJvbm1lbnQgd2lsbCB0cmFuc2l0aW9uIGl0IHRvIHRo
ZSBQRU5ESU5HIHN0YXRlLgoKDwoHBAAEAAIBARIEgAEEDQoPCgcEAAQAAgECEgSAARARCl8K
BgQABAACAhIEhAEEEBpPIFRoZSBlbnZpcm9ubWVudCBpcyBiZWluZyBzdGFydGVkIGJ1dCBp
cyBub3QgeWV0IHJlYWR5IHRvIGFjY2VwdAogY29ubmVjdGlvbnMuCgoPCgcEAAQAAgIBEgSE
AQQLCg8KBwQABAACAgISBIQBDg8KxQEKBgQABAACAxIEiQEEEBq0ASBUaGUgZW52aXJvbm1l
bnQgaXMgcnVubmluZyBhbmQgcmVhZHkgdG8gYWNjZXB0IGNvbm5lY3Rpb25zLiBJdCB3aWxs
CiBhdXRvbWF0aWNhbGx5IHRyYW5zaXRpb24gYmFjayB0byBESVNBQkxFRCBhZnRlciBhIHBl
cmlvZCBvZiBpbmFjdGl2aXR5IG9yCiBpZiBhbm90aGVyIGVudmlyb25tZW50IGlzIHN0YXJ0
ZWQuCgoPCgcEAAQAAgMBEgSJAQQLCg8KBwQABAACAwISBIkBDg8KTQoGBAAEAAIEEgSMAQQR
Gj0gVGhlIGVudmlyb25tZW50IGlzIGJlaW5nIGRlbGV0ZWQgYW5kIGNhbid0IGJlIGNvbm5l
Y3RlZCB0by4KCg8KBwQABAACBAESBIwBBAwKDwoHBAAEAAIEAhIEjAEPEArOAgoEBAACABIE
lAECPBq/AiBJbW11dGFibGUuIEZ1bGwgbmFtZSBvZiB0aGlzIHJlc291cmNlLCBpbiB0aGUg
Zm9ybWF0CiBgdXNlcnMve293bmVyX2VtYWlsfS9lbnZpcm9ubWVudHMve2Vudmlyb25tZW50
X2lkfWAuIGB7b3duZXJfZW1haWx9YCBpcyB0aGUKIGVtYWlsIGFkZHJlc3Mgb2YgdGhlIHVz
ZXIgdG8gd2hvbSB0aGlzIGVudmlyb25tZW50IGJlbG9uZ3MsIGFuZAogYHtlbnZpcm9ubWVu
dF9pZH1gIGlzIHRoZSBpZGVudGlmaWVyIG9mIHRoaXMgZW52aXJvbm1lbnQuIEZvciBleGFt
cGxlLAogYHVzZXJzL3NvbWVvbmVAZXhhbXBsZS5jb20vZW52aXJvbm1lbnRzL2RlZmF1bHRg
LgoKDQoFBAACAAUSBJQBAggKDQoFBAACAAESBJQBCQ0KDQoFBAACAAMSBJQBEBEKDQoFBAAC
AAgSBJQBEjsKEAoIBAACAAicCAASBJQBEzoKYQoEBAACARIEmAECPBpTIE91dHB1dCBvbmx5
LiBUaGUgZW52aXJvbm1lbnQncyBpZGVudGlmaWVyLCB1bmlxdWUgYW1vbmcgdGhlIHVzZXIn
cwogZW52aXJvbm1lbnRzLgoKDQoFBAACAQUSBJgBAggKDQoFBAACAQESBJgBCQsKDQoFBAAC
AQMSBJgBDg8KDQoFBAACAQgSBJgBEDsKEAoIBAACAQicCAASBJgBEToKkQEKBAQAAgISBpwB
Ap8BBBqAASBSZXF1aXJlZC4gSW1tdXRhYmxlLiBGdWxsIHBhdGggdG8gdGhlIERvY2tlciBp
bWFnZSB1c2VkIHRvIHJ1biB0aGlzIGVudmlyb25tZW50LCBlLmcuCiAiZ2NyLmlvL2Rldi1j
b24vY2xvdWQtZGV2c2hlbGw6bGF0ZXN0Ii4KCg0KBQQAAgIFEgScAQIICg0KBQQAAgIBEgSc
AQkVCg0KBQQAAgIDEgScARgZCg8KBQQAAgIIEgacARqfAQMKEAoIBAACAgicCAASBJ0BBCoK
EAoIBAACAgicCAESBJ4BBCsKSQoEBAACAxIEogECPho7IE91dHB1dCBvbmx5LiBDdXJyZW50
IGV4ZWN1dGlvbiBzdGF0ZSBvZiB0aGlzIGVudmlyb25tZW50LgoKDQoFBAACAwYSBKIBAgcK
DQoFBAACAwESBKIBCA0KDQoFBAACAwMSBKIBEBEKDQoFBAACAwgSBKIBEj0KEAoIBAACAwic
CAASBKIBEzwKegoEBAACBBIEpgECQxpsIE91dHB1dCBvbmx5LiBIb3N0IHRvIHdoaWNoIGNs
aWVudHMgY2FuIGNvbm5lY3QgdG8gaW5pdGlhdGUgSFRUUFMgb3IgV1NTCiBjb25uZWN0aW9u
cyB3aXRoIHRoZSBlbnZpcm9ubWVudC4KCg0KBQQAAgQFEgSmAQIICg0KBQQAAgQBEgSmAQkR
Cg0KBQQAAgQDEgSmARQWCg0KBQQAAgQIEgSmARdCChAKCAQAAgQInAgAEgSmARhBCnEKBAQA
AgUSBKoBAkYaYyBPdXRwdXQgb25seS4gVXNlcm5hbWUgdGhhdCBjbGllbnRzIHNob3VsZCB1
c2Ugd2hlbiBpbml0aWF0aW5nIFNTSCBzZXNzaW9ucwogd2l0aCB0aGUgZW52aXJvbm1lbnQu
CgoNCgUEAAIFBRIEqgECCAoNCgUEAAIFARIEqgEJFQoNCgUEAAIFAxIEqgEYGQoNCgUEAAIF
CBIEqgEaRQoQCggEAAIFCJwIABIEqgEbRApuCgQEAAIGEgSuAQJCGmAgT3V0cHV0IG9ubHku
IEhvc3QgdG8gd2hpY2ggY2xpZW50cyBjYW4gY29ubmVjdCB0byBpbml0aWF0ZSBTU0ggc2Vz
c2lvbnMKIHdpdGggdGhlIGVudmlyb25tZW50LgoKDQoFBAACBgUSBK4BAggKDQoFBAACBgES
BK4BCREKDQoFBAACBgMSBK4BFBUKDQoFBAACBggSBK4BFkEKEAoIBAACBgicCAASBK4BF0AK
bgoEBAACBxIEsgECQRpgIE91dHB1dCBvbmx5LiBQb3J0IHRvIHdoaWNoIGNsaWVudHMgY2Fu
IGNvbm5lY3QgdG8gaW5pdGlhdGUgU1NIIHNlc3Npb25zCiB3aXRoIHRoZSBlbnZpcm9ubWVu
dC4KCg0KBQQAAgcFEgSyAQIHCg0KBQQAAgcBEgSyAQgQCg0KBQQAAgcDEgSyARMUCg0KBQQA
AgcIEgSyARVAChAKCAQAAgcInAgAEgSyARY/Cr4CCgQEAAIIEgS5AQJOGq8CIE91dHB1dCBv
bmx5LiBQdWJsaWMga2V5cyBhc3NvY2lhdGVkIHdpdGggdGhlIGVudmlyb25tZW50LiBDbGll
bnRzIGNhbgogY29ubmVjdCB0byB0aGlzIGVudmlyb25tZW50IHZpYSBTU0ggb25seSBpZiB0
aGV5IHBvc3Nlc3MgYSBwcml2YXRlIGtleQogY29ycmVzcG9uZGluZyB0byBhdCBsZWFzdCBv
bmUgb2YgdGhlc2UgcHVibGljIGtleXMuIEtleXMgY2FuIGJlIGFkZGVkIHRvIG9yCiByZW1v
dmVkIGZyb20gdGhlIGVudmlyb25tZW50IHVzaW5nIHRoZSBBZGRQdWJsaWNLZXkgYW5kIFJl
bW92ZVB1YmxpY0tleQogbWV0aG9kcy4KCg0KBQQAAggEEgS5AQIKCg0KBQQAAggFEgS5AQsR
Cg0KBQQAAggBEgS5ARIdCg0KBQQAAggDEgS5ASAhCg0KBQQAAggIEgS5ASJNChAKCAQAAggI
nAgAEgS5ASNMCm4KAgQBEga+AQDHAQEaYCBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbR2V0RW52
aXJvbm1lbnRdW2dvb2dsZS5jbG91ZC5zaGVsbC52MS5DbG91ZFNoZWxsU2VydmljZS5HZXRF
bnZpcm9ubWVudF0uCgoLCgMEAQESBL4BCB0KngEKBAQBAgASBsEBAsYBBBqNASBSZXF1aXJl
ZC4gTmFtZSBvZiB0aGUgcmVxdWVzdGVkIHJlc291cmNlLCBmb3IgZXhhbXBsZSBgdXNlcnMv
bWUvZW52aXJvbm1lbnRzL2RlZmF1bHRgCiBvciBgdXNlcnMvc29tZW9uZUBleGFtcGxlLmNv
bS9lbnZpcm9ubWVudHMvZGVmYXVsdGAuCgoNCgUEAQIABRIEwQECCAoNCgUEAQIAARIEwQEJ
DQoNCgUEAQIAAxIEwQEQEQoPCgUEAQIACBIGwQESxgEDChAKCAQBAgAInAgAEgTCAQQqChEK
BwQBAgAInwgSBsMBBMUBBQqkAQoCBAISBssBAM0BARqVASBNZXNzYWdlIGluY2x1ZGVkIGlu
IHRoZSBtZXRhZGF0YSBmaWVsZCBvZiBvcGVyYXRpb25zIHJldHVybmVkIGZyb20KIFtDcmVh
dGVFbnZpcm9ubWVudF1bZ29vZ2xlLmNsb3VkLnNoZWxsLnYxLkNsb3VkU2hlbGxTZXJ2aWNl
LkNyZWF0ZUVudmlyb25tZW50XS4KCgsKAwQCARIEywEIIQqkAQoCBAMSBtEBANMBARqVASBN
ZXNzYWdlIGluY2x1ZGVkIGluIHRoZSBtZXRhZGF0YSBmaWVsZCBvZiBvcGVyYXRpb25zIHJl
dHVybmVkIGZyb20KIFtEZWxldGVFbnZpcm9ubWVudF1bZ29vZ2xlLmNsb3VkLnNoZWxsLnYx
LkNsb3VkU2hlbGxTZXJ2aWNlLkRlbGV0ZUVudmlyb25tZW50XS4KCgsKAwQDARIE0QEIIQpy
CgIEBBIG1wEA5QEBGmQgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1N0YXJ0RW52aXJvbm1lbnRd
W2dvb2dsZS5jbG91ZC5zaGVsbC52MS5DbG91ZFNoZWxsU2VydmljZS5TdGFydEVudmlyb25t
ZW50XS4KCgsKAwQEARIE1wEIHwqgAQoEBAQCABIE2wECEhqRASBOYW1lIG9mIHRoZSByZXNv
dXJjZSB0aGF0IHNob3VsZCBiZSBzdGFydGVkLCBmb3IgZXhhbXBsZQogYHVzZXJzL21lL2Vu
dmlyb25tZW50cy9kZWZhdWx0YCBvcgogYHVzZXJzL3NvbWVvbmVAZXhhbXBsZS5jb20vZW52
aXJvbm1lbnRzL2RlZmF1bHRgLgoKDQoFBAQCAAUSBNsBAggKDQoFBAQCAAESBNsBCQ0KDQoF
BAQCAAMSBNsBEBEKrQIKBAQEAgESBOEBAhoangIgVGhlIGluaXRpYWwgYWNjZXNzIHRva2Vu
IHBhc3NlZCB0byB0aGUgZW52aXJvbm1lbnQuIElmIHRoaXMgaXMgcHJlc2VudCBhbmQKIHZh
bGlkLCB0aGUgZW52aXJvbm1lbnQgd2lsbCBiZSBwcmUtYXV0aGVudGljYXRlZCB3aXRoIGdj
bG91ZCBzbyB0aGF0IHRoZQogdXNlciBjYW4gcnVuIGdjbG91ZCBjb21tYW5kcyBpbiBDbG91
ZCBTaGVsbCB3aXRob3V0IGhhdmluZyB0byBsb2cgaW4uIFRoaXMKIGNvZGUgY2FuIGJlIHVw
ZGF0ZWQgbGF0ZXIgYnkgY2FsbGluZyBBdXRob3JpemVFbnZpcm9ubWVudC4KCg0KBQQEAgEF
EgThAQIICg0KBQQEAgEBEgThAQkVCg0KBQQEAgEDEgThARgZClkKBAQEAgISBOQBAiIaSyBQ
dWJsaWMga2V5cyB0aGF0IHNob3VsZCBiZSBhZGRlZCB0byB0aGUgZW52aXJvbm1lbnQgYmVm
b3JlIGl0IGlzIHN0YXJ0ZWQuCgoNCgUEBAICBBIE5AECCgoNCgUEBAICBRIE5AELEQoNCgUE
BAICARIE5AESHQoNCgUEBAICAxIE5AEgIQp6CgIEBRIG6QEA+AEBGmwgUmVxdWVzdCBtZXNz
YWdlIGZvcgogW0F1dGhvcml6ZUVudmlyb25tZW50XVtnb29nbGUuY2xvdWQuc2hlbGwudjEu
Q2xvdWRTaGVsbFNlcnZpY2UuQXV0aG9yaXplRW52aXJvbm1lbnRdLgoKCwoDBAUBEgTpAQgj
Cq0BCgQEBQIAEgTtAQISGp4BIE5hbWUgb2YgdGhlIHJlc291cmNlIHRoYXQgc2hvdWxkIHJl
Y2VpdmUgdGhlIGNyZWRlbnRpYWxzLCBmb3IgZXhhbXBsZQogYHVzZXJzL21lL2Vudmlyb25t
ZW50cy9kZWZhdWx0YCBvcgogYHVzZXJzL3NvbWVvbmVAZXhhbXBsZS5jb20vZW52aXJvbm1l
bnRzL2RlZmF1bHRgLgoKDQoFBAUCAAUSBO0BAggKDQoFBAUCAAESBO0BCQ0KDQoFBAUCAAMS
BO0BEBEKTgoEBAUCARIE8AECGhpAIFRoZSBPQXV0aCBhY2Nlc3MgdG9rZW4gdGhhdCBzaG91
bGQgYmUgc2VudCB0byB0aGUgZW52aXJvbm1lbnQuCgoNCgUEBQIBBRIE8AECCAoNCgUEBQIB
ARIE8AEJFQoNCgUEBQIBAxIE8AEYGQpKCgQEBQICEgTzAQIWGjwgVGhlIE9BdXRoIElEIHRv
a2VuIHRoYXQgc2hvdWxkIGJlIHNlbnQgdG8gdGhlIGVudmlyb25tZW50LgoKDQoFBAUCAgUS
BPMBAggKDQoFBAUCAgESBPMBCREKDQoFBAUCAgMSBPMBFBUKggEKBAQFAgMSBPcBAiwadCBU
aGUgdGltZSB3aGVuIHRoZSBjcmVkZW50aWFscyBleHBpcmUuIElmIG5vdCBzZXQsIGRlZmF1
bHRzIHRvIG9uZSBob3VyIGZyb20KIHdoZW4gdGhlIHNlcnZlciByZWNlaXZlZCB0aGUgcmVx
dWVzdC4KCg0KBQQFAgMGEgT3AQIbCg0KBQQFAgMBEgT3ARwnCg0KBQQFAgMDEgT3ASorCnsK
AgQGEgb8AQD+AQEabSBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0F1dGhvcml6ZUVudmlyb25t
ZW50XVtnb29nbGUuY2xvdWQuc2hlbGwudjEuQ2xvdWRTaGVsbFNlcnZpY2UuQXV0aG9yaXpl
RW52aXJvbm1lbnRdLgoKCwoDBAYBEgT8AQgkCqoBCgIEBxIGggIAhAIBGpsBIE1lc3NhZ2Ug
aW5jbHVkZWQgaW4gdGhlIG1ldGFkYXRhIGZpZWxkIG9mIG9wZXJhdGlvbnMgcmV0dXJuZWQg
ZnJvbQogW0F1dGhvcml6ZUVudmlyb25tZW50XVtnb29nbGUuY2xvdWQuc2hlbGwudjEuQ2xv
dWRTaGVsbFNlcnZpY2UuQXV0aG9yaXplRW52aXJvbm1lbnRdLgoKCwoDBAcBEgSCAggkCqIB
CgIECBIGiAIAqQIBGpMBIE1lc3NhZ2UgaW5jbHVkZWQgaW4gdGhlIG1ldGFkYXRhIGZpZWxk
IG9mIG9wZXJhdGlvbnMgcmV0dXJuZWQgZnJvbQogW1N0YXJ0RW52aXJvbm1lbnRdW2dvb2ds
ZS5jbG91ZC5zaGVsbC52MS5DbG91ZFNoZWxsU2VydmljZS5TdGFydEVudmlyb25tZW50XS4K
CgsKAwQIARIEiAIIIArMAgoEBAgEABIGjgICpQIDGrsCIFBvc3NpYmxlIHN0YXRlcyBhbiBl
bnZpcm9ubWVudCBtaWdodCB0cmFuc2l0aW9uIGJldHdlZW4gZHVyaW5nIHN0YXJ0dXAuCiBU
aGVzZSBzdGF0ZXMgYXJlIG5vdCBub3JtYWxseSBhY3Rpb25hYmxlIGJ5IGNsaWVudHMsIGJ1
dCBtYXkgYmUgdXNlZCB0bwogc2hvdyBhIHByb2dyZXNzIG1lc3NhZ2UgdG8gdGhlIHVzZXIu
IEFuIGVudmlyb25tZW50IHdvbid0IG5lY2Vzc2FyaWx5IGdvCiB0aHJvdWdoIGFsbCBvZiB0
aGVzZSBzdGF0ZXMgd2hlbiBzdGFydGluZy4gTW9yZSBzdGF0ZXMgYXJlIGxpa2VseSB0byBi
ZQogYWRkZWQgaW4gdGhlIGZ1dHVyZS4KCg0KBQQIBAABEgSOAgcMCjsKBgQIBAACABIEkAIE
GhorIFRoZSBlbnZpcm9ubWVudCdzIHN0YXJ0IHN0YXRlIGlzIHVua25vd24uCgoPCgcECAQA
AgABEgSQAgQVCg8KBwQIBAACAAISBJACGBkKbwoGBAgEAAIBEgSUAgQRGl8gVGhlIGVudmly
b25tZW50IGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIHN0YXJ0ZWQsIGJ1dCBubyBhZGRp
dGlvbmFsCiBkZXRhaWxzIGFyZSBhdmFpbGFibGUuCgoPCgcECAQAAgEBEgSUAgQMCg8KBwQI
BAACAQISBJQCDxAK4AEKBgQIBAACAhIEmQIEGRrPASBTdGFydHVwIGlzIHdhaXRpbmcgZm9y
IHRoZSB1c2VyJ3MgZGlzayB0byBiZSB1bmFyY2hpdmVkLiBUaGlzIGNhbiBoYXBwZW4KIHdo
ZW4gdGhlIHVzZXIgcmV0dXJucyB0byBDbG91ZCBTaGVsbCBhZnRlciBub3QgaGF2aW5nIHVz
ZWQgaXQgZm9yIGEKIHdoaWxlLCBhbmQgc3VnZ2VzdHMgdGhhdCBzdGFydHVwIHdpbGwgdGFr
ZSBsb25nZXIgdGhhbiBub3JtYWwuCgoPCgcECAQAAgIBEgSZAgQUCg8KBwQIBAACAgISBJkC
FxgKgAIKBgQIBAACAxIEnwIEIxrvASBTdGFydHVwIGlzIHdhaXRpbmcgZm9yIGNvbXB1dGUg
cmVzb3VyY2VzIHRvIGJlIGFzc2lnbmVkIHRvIHRoZQogZW52aXJvbm1lbnQuIFRoaXMgc2hv
dWxkIG5vcm1hbGx5IGhhcHBlbiB2ZXJ5IHF1aWNrbHksIGJ1dCBhbiBlbnZpcm9ubWVudAog
bWlnaHQgc3RheSBpbiB0aGlzIHN0YXRlIGZvciBhbiBleHRlbmRlZCBwZXJpb2Qgb2YgdGlt
ZSBpZiB0aGUgc3lzdGVtIGlzCiBleHBlcmllbmNpbmcgaGVhdnkgbG9hZC4KCg8KBwQIBAAC
AwESBJ8CBB4KDwoHBAgEAAIDAhIEnwIhIgrdAQoGBAgEAAIEEgSkAgQRGswBIFN0YXJ0dXAg
aGFzIGNvbXBsZXRlZC4gSWYgdGhlIHN0YXJ0IG9wZXJhdGlvbiB3YXMgc3VjY2Vzc2Z1bCwg
dGhlIHVzZXIKIHNob3VsZCBiZSBhYmxlIHRvIGVzdGFibGlzaCBhbiBTU0ggY29ubmVjdGlv
biB0byB0aGVpciBlbnZpcm9ubWVudC4KIE90aGVyd2lzZSwgdGhlIG9wZXJhdGlvbiB3aWxs
IGNvbnRhaW4gZGV0YWlscyBvZiB0aGUgZmFpbHVyZS4KCg8KBwQIBAACBAESBKQCBAwKDwoH
BAgEAAIEAhIEpAIPEAo/CgQECAIAEgSoAgISGjEgQ3VycmVudCBzdGF0ZSBvZiB0aGUgZW52
aXJvbm1lbnQgYmVpbmcgc3RhcnRlZC4KCg0KBQQIAgAGEgSoAgIHCg0KBQQIAgABEgSoAggN
Cg0KBQQIAgADEgSoAhARCsIBCgIECRIGrgIAsQIBGrMBIE1lc3NhZ2UgaW5jbHVkZWQgaW4g
dGhlIHJlc3BvbnNlIGZpZWxkIG9mIG9wZXJhdGlvbnMgcmV0dXJuZWQgZnJvbQogW1N0YXJ0
RW52aXJvbm1lbnRdW2dvb2dsZS5jbG91ZC5zaGVsbC52MS5DbG91ZFNoZWxsU2VydmljZS5T
dGFydEVudmlyb25tZW50XQogb25jZSB0aGUgb3BlcmF0aW9uIGlzIGNvbXBsZXRlLgoKCwoD
BAkBEgSuAgggCi0KBAQJAgASBLACAh4aHyBFbnZpcm9ubWVudCB0aGF0IHdhcyBzdGFydGVk
LgoKDQoFBAkCAAYSBLACAg0KDQoFBAkCAAESBLACDhkKDQoFBAkCAAMSBLACHB0KagoCBAoS
BrUCAMECARpcIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtBZGRQdWJsaWNLZXldW2dvb2dsZS5j
bG91ZC5zaGVsbC52MS5DbG91ZFNoZWxsU2VydmljZS5BZGRQdWJsaWNLZXldLgoKCwoDBAoB
EgS1AggbCl8KBAQKAgASBLgCAhkaUSBFbnZpcm9ubWVudCB0aGlzIGtleSBzaG91bGQgYmUg
YWRkZWQgdG8sIGUuZy4KIGB1c2Vycy9tZS9lbnZpcm9ubWVudHMvZGVmYXVsdGAuCgoNCgUE
CgIABRIEuAICCAoNCgUECgIAARIEuAIJFAoNCgUECgIAAxIEuAIXGArqAgoEBAoCARIEwAIC
ERrbAiBLZXkgdGhhdCBzaG91bGQgYmUgYWRkZWQgdG8gdGhlIGVudmlyb25tZW50LiBTdXBw
b3J0ZWQgZm9ybWF0cyBhcmUKIGBzc2gtZHNzYCAoc2VlIFJGQzQyNTMpLCBgc3NoLXJzYWAg
KHNlZSBSRkM0MjUzKSwgYGVjZHNhLXNoYTItbmlzdHAyNTZgCiAoc2VlIFJGQzU2NTYpLCBg
ZWNkc2Etc2hhMi1uaXN0cDM4NGAgKHNlZSBSRkM1NjU2KSBhbmQKIGBlY2RzYS1zaGEyLW5p
c3RwNTIxYCAoc2VlIFJGQzU2NTYpLiBJdCBzaG91bGQgYmUgc3RydWN0dXJlZCBhcwogJmx0
O2Zvcm1hdCZndDsgJmx0O2NvbnRlbnQmZ3Q7LCB3aGVyZSAmbHQ7Y29udGVudCZndDsgcGFy
dCBpcyBlbmNvZGVkIHdpdGgKIEJhc2U2NC4KCg0KBQQKAgEFEgTAAgIICg0KBQQKAgEBEgTA
AgkMCg0KBQQKAgEDEgTAAg8QCmsKAgQLEgbFAgDIAgEaXSBSZXNwb25zZSBtZXNzYWdlIGZv
cgogW0FkZFB1YmxpY0tleV1bZ29vZ2xlLmNsb3VkLnNoZWxsLnYxLkNsb3VkU2hlbGxTZXJ2
aWNlLkFkZFB1YmxpY0tleV0uCgoLCgMECwESBMUCCBwKNgoEBAsCABIExwICERooIEtleSB0
aGF0IHdhcyBhZGRlZCB0byB0aGUgZW52aXJvbm1lbnQuCgoNCgUECwIABRIExwICCAoNCgUE
CwIAARIExwIJDAoNCgUECwIAAxIExwIPEAqaAQoCBAwSBswCAM4CARqLASBNZXNzYWdlIGlu
Y2x1ZGVkIGluIHRoZSBtZXRhZGF0YSBmaWVsZCBvZiBvcGVyYXRpb25zIHJldHVybmVkIGZy
b20KIFtBZGRQdWJsaWNLZXldW2dvb2dsZS5jbG91ZC5zaGVsbC52MS5DbG91ZFNoZWxsU2Vy
dmljZS5BZGRQdWJsaWNLZXldLgoKCwoDBAwBEgTMAggcCnAKAgQNEgbSAgDZAgEaYiBSZXF1
ZXN0IG1lc3NhZ2UgZm9yCiBbUmVtb3ZlUHVibGljS2V5XVtnb29nbGUuY2xvdWQuc2hlbGwu
djEuQ2xvdWRTaGVsbFNlcnZpY2UuUmVtb3ZlUHVibGljS2V5XS4KCgsKAwQNARIE0gIIHgpj
CgQEDQIAEgTVAgIZGlUgRW52aXJvbm1lbnQgdGhpcyBrZXkgc2hvdWxkIGJlIHJlbW92ZWQg
ZnJvbSwgZS5nLgogYHVzZXJzL21lL2Vudmlyb25tZW50cy9kZWZhdWx0YC4KCg0KBQQNAgAF
EgTVAgIICg0KBQQNAgABEgTVAgkUCg0KBQQNAgADEgTVAhcYCkAKBAQNAgESBNgCAhEaMiBL
ZXkgdGhhdCBzaG91bGQgYmUgcmVtb3ZlZCBmcm9tIHRoZSBlbnZpcm9ubWVudC4KCg0KBQQN
AgEFEgTYAgIICg0KBQQNAgEBEgTYAgkMCg0KBQQNAgEDEgTYAg8QCnEKAgQOEgbdAgDfAgEa
YyBSZXNwb25zZSBtZXNzYWdlIGZvcgogW1JlbW92ZVB1YmxpY0tleV1bZ29vZ2xlLmNsb3Vk
LnNoZWxsLnYxLkNsb3VkU2hlbGxTZXJ2aWNlLlJlbW92ZVB1YmxpY0tleV0uCgoLCgMEDgES
BN0CCB8KoAEKAgQPEgbjAgDlAgEakQEgTWVzc2FnZSBpbmNsdWRlZCBpbiB0aGUgbWV0YWRh
dGEgZmllbGQgb2Ygb3BlcmF0aW9ucyByZXR1cm5lZCBmcm9tCiBbUmVtb3ZlUHVibGljS2V5
XVtnb29nbGUuY2xvdWQuc2hlbGwudjEuQ2xvdWRTaGVsbFNlcnZpY2UuUmVtb3ZlUHVibGlj
S2V5XS4KCgsKAwQPARIE4wIIHwpoCgIEEBIG6QIAhgMBGlogQ2xvdWQtc2hlbGwgc3BlY2lm
aWMgaW5mb3JtYXRpb24gdGhhdCB3aWxsIGJlIGluY2x1ZGVkIGFzIGRldGFpbHMgaW4gZmFp
bHVyZQogcmVzcG9uc2VzLgoKCwoDBBABEgTpAggeCkEKBAQQBAASBusCAoIDAxoxIFNldCBv
ZiBwb3NzaWJsZSBlcnJvcnMgcmV0dXJuZWQgZnJvbSBBUEkgY2FsbHMuCgoNCgUEEAQAARIE
6wIHGgosCgYEEAQAAgASBO0CBCsaHCBBbiB1bmtub3duIGVycm9yIG9jY3VycmVkLgoKDwoH
BBAEAAIAARIE7QIEJgoPCgcEEAQAAgACEgTtAikqCn4KBgQQBAACARIE8QIEGhpuIFRoZSBp
bWFnZSB1c2VkIGJ5IHRoZSBDbG91ZCBTaGVsbCBlbnZpcm9ubWVudCBlaXRoZXIgZG9lcyBu
b3QgZXhpc3Qgb3IKIHRoZSB1c2VyIGRvZXMgbm90IGhhdmUgYWNjZXNzIHRvIGl0LgoKDwoH
BBAEAAIBARIE8QIEFQoPCgcEEAQAAgECEgTxAhgZCmUKBgQQBAACAhIE9QIEHRpVIENsb3Vk
IFNoZWxsIGhhcyBiZWVuIGRpc2FibGVkIGJ5IGFuIGFkbWluaXN0cmF0b3IgZm9yIHRoZSB1
c2VyIG1ha2luZyB0aGUKIHJlcXVlc3QuCgoPCgcEEAQAAgIBEgT1AgQYCg8KBwQQBAACAgIS
BPUCGxwKbQoGBBAEAAIDEgT5AgQWGl0gQ2xvdWQgU2hlbGwgaGFzIGJlZW4gcGVybWFuZW50
bHkgZGlzYWJsZWQgZHVlIHRvIGEgVGVybXMgb2YgU2VydmljZQogdmlvbGF0aW9uIGJ5IHRo
ZSB1c2VyLgoKDwoHBBAEAAIDARIE+QIEEQoPCgcEEAQAAgMCEgT5AhQVCoIBCgYEEAQAAgQS
BP0CBBcaciBUaGUgdXNlciBoYXMgZXhoYXVzdGVkIHRoZWlyIHdlZWtseSBDbG91ZCBTaGVs
bCBxdW90YSwgYW5kIENsb3VkIFNoZWxsCiB3aWxsIGJlIGRpc2FibGVkIHVudGlsIHRoZSBx
dW90YSByZXNldHMuCgoPCgcEEAQAAgQBEgT9AgQSCg8KBwQQBAACBAISBP0CFRYKZwoGBBAE
AAIFEgSBAwQgGlcgVGhlIENsb3VkIFNoZWxsIGVudmlyb25tZW50IGlzIHVuYXZhaWxhYmxl
IGFuZCBjYW5ub3QgYmUgY29ubmVjdGVkIHRvIGF0CiB0aGUgbW9tZW50LgoKDwoHBBAEAAIF
ARIEgQMEGwoPCgcEEAQAAgUCEgSBAx4fCkAKBAQQAgASBIUDAh8aMiBDb2RlIGluZGljYXRp
bmcgdGhlIHNwZWNpZmljIGVycm9yIHRoZSBvY2N1cnJlZC4KCg0KBQQQAgAGEgSFAwIVCg0K
BQQQAgABEgSFAxYaCg0KBQQQAgADEgSFAx0eYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Shell::V1::Cloudshell::Environment ===
    # Fields for Environment
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: docker_image Type: 9 ()
    # Field: state Type: 14 (.google.cloud.shell.v1.Environment.State)
    # Field: web_host Type: 9 ()
    # Field: ssh_username Type: 9 ()
    # Field: ssh_host Type: 9 ()
    # Field: ssh_port Type: 5 ()
    # Field: public_keys Type: 9 ()

# Enum: Environment::State
our $Environment_STATE_UNSPECIFIED = 0;
our $Environment_SUSPENDED = 1;
our $Environment_PENDING = 2;
our $Environment_RUNNING = 3;
our $Environment_DELETING = 4;

# === Message: Google::Cloud::Shell::V1::Cloudshell::GetEnvironmentRequest ===
    # Fields for GetEnvironmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Shell::V1::Cloudshell::CreateEnvironmentMetadata ===
    # Fields for CreateEnvironmentMetadata

# === Message: Google::Cloud::Shell::V1::Cloudshell::DeleteEnvironmentMetadata ===
    # Fields for DeleteEnvironmentMetadata

# === Message: Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentRequest ===
    # Fields for StartEnvironmentRequest
    # Field: name Type: 9 ()
    # Field: access_token Type: 9 ()
    # Field: public_keys Type: 9 ()

# === Message: Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentRequest ===
    # Fields for AuthorizeEnvironmentRequest
    # Field: name Type: 9 ()
    # Field: access_token Type: 9 ()
    # Field: id_token Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentResponse ===
    # Fields for AuthorizeEnvironmentResponse

# === Message: Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentMetadata ===
    # Fields for AuthorizeEnvironmentMetadata

# === Message: Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentMetadata ===
    # Fields for StartEnvironmentMetadata
    # Field: state Type: 14 (.google.cloud.shell.v1.StartEnvironmentMetadata.State)

# Enum: StartEnvironmentMetadata::State
our $StartEnvironmentMetadata_STATE_UNSPECIFIED = 0;
our $StartEnvironmentMetadata_STARTING = 1;
our $StartEnvironmentMetadata_UNARCHIVING_DISK = 2;
our $StartEnvironmentMetadata_AWAITING_COMPUTE_RESOURCES = 4;
our $StartEnvironmentMetadata_FINISHED = 3;

# === Message: Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentResponse ===
    # Fields for StartEnvironmentResponse
    # Field: environment Type: 11 (.google.cloud.shell.v1.Environment)

# === Message: Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyRequest ===
    # Fields for AddPublicKeyRequest
    # Field: environment Type: 9 ()
    # Field: key Type: 9 ()

# === Message: Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyResponse ===
    # Fields for AddPublicKeyResponse
    # Field: key Type: 9 ()

# === Message: Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyMetadata ===
    # Fields for AddPublicKeyMetadata

# === Message: Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyRequest ===
    # Fields for RemovePublicKeyRequest
    # Field: environment Type: 9 ()
    # Field: key Type: 9 ()

# === Message: Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyResponse ===
    # Fields for RemovePublicKeyResponse

# === Message: Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyMetadata ===
    # Fields for RemovePublicKeyMetadata

# === Message: Google::Cloud::Shell::V1::Cloudshell::CloudShellErrorDetails ===
    # Fields for CloudShellErrorDetails
    # Field: code Type: 14 (.google.cloud.shell.v1.CloudShellErrorDetails.CloudShellErrorCode)

# Enum: CloudShellErrorDetails::CloudShellErrorCode
our $CloudShellErrorDetails_CLOUD_SHELL_ERROR_CODE_UNSPECIFIED = 0;
our $CloudShellErrorDetails_IMAGE_UNAVAILABLE = 1;
our $CloudShellErrorDetails_CLOUD_SHELL_DISABLED = 2;
our $CloudShellErrorDetails_TOS_VIOLATION = 4;
our $CloudShellErrorDetails_QUOTA_EXCEEDED = 5;
our $CloudShellErrorDetails_ENVIRONMENT_UNAVAILABLE = 6;

# === Service Client: Google::Cloud::Shell::V1::Cloudshell::CloudShellServiceClient ===
package Google::Cloud::Shell::V1::Cloudshell::CloudShellServiceClient;

=pod

=head2 Service Client: Google::Cloud::Shell::V1::Cloudshell::CloudShellServiceClient

Client stub representing the remote C<CloudShellService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<shell.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'shell.googleapis.com:443' );

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

sub get_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Shell::V1::Cloudshell::GetEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.shell.v1.CloudShellService',
        method         => 'GetEnvironment',
        request        => $req,
        response_class => 'Google::Cloud::Shell::V1::Cloudshell::Environment',
    });
}

sub start_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.shell.v1.CloudShellService',
        method         => 'StartEnvironment',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub authorize_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.shell.v1.CloudShellService',
        method         => 'AuthorizeEnvironment',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub add_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.shell.v1.CloudShellService',
        method         => 'AddPublicKey',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub remove_public_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.shell.v1.CloudShellService',
        method         => 'RemovePublicKey',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Shell::V1::Cloudshell - Compiled Protocol Buffers messages for google/cloud/shell/v1/cloudshell.proto

=head1 SYNOPSIS

    use Google::Cloud::Shell::V1::Cloudshell;

    my $msg = Google::Cloud::Shell::V1::Cloudshell::Environment->new({
        name => $name,
        id => $id,
        docker_image => $docker_image,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Shell::V1::Cloudshell::Environment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/shell/v1/cloudshell.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Shell::V1::Cloudshell::Environment

A Cloud Shell environment, which is defined as the combination of a Docker
image specifying what is installed on the environment and a home directory
containing the user's data that will remain across sessions. Each user has
at least an environment with the ID "default".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Full name of this resource, in the format
`users/{owner_email}/environments/{environment_id}`. `{owner_email}` is the
email address of the user to whom this environment belongs, and
`{environment_id}` is the identifier of this environment. For example,
`users/someone@example.com/environments/default`.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. The environment's identifier, unique among the user's
environments.

=item * C<< $msg->docker_image() >> / C<< $msg->docker_image($value) >>

Type: C<String>

Required. Immutable. Full path to the Docker image used to run this environment, e.g.
"gcr.io/dev-con/cloud-devshell:latest".

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Shell::V1::Environment::State>)

Output only. Current execution state of this environment.

=item * C<< $msg->web_host() >> / C<< $msg->web_host($value) >>

Type: C<String>

Output only. Host to which clients can connect to initiate HTTPS or WSS
connections with the environment.

=item * C<< $msg->ssh_username() >> / C<< $msg->ssh_username($value) >>

Type: C<String>

Output only. Username that clients should use when initiating SSH sessions
with the environment.

=item * C<< $msg->ssh_host() >> / C<< $msg->ssh_host($value) >>

Type: C<String>

Output only. Host to which clients can connect to initiate SSH sessions
with the environment.

=item * C<< $msg->ssh_port() >> / C<< $msg->ssh_port($value) >>

Type: C<Int32>

Output only. Port to which clients can connect to initiate SSH sessions
with the environment.

=item * C<< $msg->public_keys() >> / C<< $msg->public_keys($value) >>

Type: C<String>

Output only. Public keys associated with the environment. Clients can
connect to this environment via SSH only if they possess a private key
corresponding to at least one of these public keys. Keys can be added to or
removed from the environment using the AddPublicKey and RemovePublicKey
methods.

=back

=head3 Enum: Environment::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<SUSPENDED> => C<1>

=item * C<PENDING> => C<2>

=item * C<RUNNING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::GetEnvironmentRequest

Request message for
[GetEnvironment][google.cloud.shell.v1.CloudShellService.GetEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the requested resource, for example `users/me/environments/default`
or `users/someone@example.com/environments/default`.

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::CreateEnvironmentMetadata

Message included in the metadata field of operations returned from
[CreateEnvironment][google.cloud.shell.v1.CloudShellService.CreateEnvironment].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Shell::V1::Cloudshell::DeleteEnvironmentMetadata

Message included in the metadata field of operations returned from
[DeleteEnvironment][google.cloud.shell.v1.CloudShellService.DeleteEnvironment].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentRequest

Request message for
[StartEnvironment][google.cloud.shell.v1.CloudShellService.StartEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the resource that should be started, for example
`users/me/environments/default` or
`users/someone@example.com/environments/default`.

=item * C<< $msg->access_token() >> / C<< $msg->access_token($value) >>

Type: C<String>

The initial access token passed to the environment. If this is present and
valid, the environment will be pre-authenticated with gcloud so that the
user can run gcloud commands in Cloud Shell without having to log in. This
code can be updated later by calling AuthorizeEnvironment.

=item * C<< $msg->public_keys() >> / C<< $msg->public_keys($value) >>

Type: C<String>

Public keys that should be added to the environment before it is started.

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentRequest

Request message for
[AuthorizeEnvironment][google.cloud.shell.v1.CloudShellService.AuthorizeEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the resource that should receive the credentials, for example
`users/me/environments/default` or
`users/someone@example.com/environments/default`.

=item * C<< $msg->access_token() >> / C<< $msg->access_token($value) >>

Type: C<String>

The OAuth access token that should be sent to the environment.

=item * C<< $msg->id_token() >> / C<< $msg->id_token($value) >>

Type: C<String>

The OAuth ID token that should be sent to the environment.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the credentials expire. If not set, defaults to one hour from
when the server received the request.

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentResponse

Response message for
[AuthorizeEnvironment][google.cloud.shell.v1.CloudShellService.AuthorizeEnvironment].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentMetadata

Message included in the metadata field of operations returned from
[AuthorizeEnvironment][google.cloud.shell.v1.CloudShellService.AuthorizeEnvironment].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentMetadata

Message included in the metadata field of operations returned from
[StartEnvironment][google.cloud.shell.v1.CloudShellService.StartEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Shell::V1::StartEnvironmentMetadata::State>)

Current state of the environment being started.

=back

=head3 Enum: StartEnvironmentMetadata::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STARTING> => C<1>

=item * C<UNARCHIVING_DISK> => C<2>

=item * C<AWAITING_COMPUTE_RESOURCES> => C<4>

=item * C<FINISHED> => C<3>

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentResponse

Message included in the response field of operations returned from
[StartEnvironment][google.cloud.shell.v1.CloudShellService.StartEnvironment]
once the operation is complete.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Message> (L<Google::Cloud::Shell::V1::Cloudshell::Environment>)

Environment that was started.

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyRequest

Request message for
[AddPublicKey][google.cloud.shell.v1.CloudShellService.AddPublicKey].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<String>

Environment this key should be added to, e.g.
`users/me/environments/default`.

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Key that should be added to the environment. Supported formats are
`ssh-dss` (see RFC4253), `ssh-rsa` (see RFC4253), `ecdsa-sha2-nistp256`
(see RFC5656), `ecdsa-sha2-nistp384` (see RFC5656) and
`ecdsa-sha2-nistp521` (see RFC5656). It should be structured as
&lt;format&gt; &lt;content&gt;, where &lt;content&gt; part is encoded with
Base64.

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyResponse

Response message for
[AddPublicKey][google.cloud.shell.v1.CloudShellService.AddPublicKey].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Key that was added to the environment.

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyMetadata

Message included in the metadata field of operations returned from
[AddPublicKey][google.cloud.shell.v1.CloudShellService.AddPublicKey].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyRequest

Request message for
[RemovePublicKey][google.cloud.shell.v1.CloudShellService.RemovePublicKey].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<String>

Environment this key should be removed from, e.g.
`users/me/environments/default`.

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Key that should be removed from the environment.

=back

=head2 Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyResponse

Response message for
[RemovePublicKey][google.cloud.shell.v1.CloudShellService.RemovePublicKey].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyMetadata

Message included in the metadata field of operations returned from
[RemovePublicKey][google.cloud.shell.v1.CloudShellService.RemovePublicKey].

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Shell::V1::Cloudshell::CloudShellErrorDetails

Cloud-shell specific information that will be included as details in failure
responses.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Cloud::Shell::V1::CloudShellErrorDetails::CloudShellErrorCode>)

Code indicating the specific error the occurred.

=back

=head3 Enum: CloudShellErrorDetails::CloudShellErrorCode

=over 4

=item * C<CLOUD_SHELL_ERROR_CODE_UNSPECIFIED> => C<0>

=item * C<IMAGE_UNAVAILABLE> => C<1>

=item * C<CLOUD_SHELL_DISABLED> => C<2>

=item * C<TOS_VIOLATION> => C<4>

=item * C<QUOTA_EXCEEDED> => C<5>

=item * C<ENVIRONMENT_UNAVAILABLE> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Shell::V1::Cloudshell::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
