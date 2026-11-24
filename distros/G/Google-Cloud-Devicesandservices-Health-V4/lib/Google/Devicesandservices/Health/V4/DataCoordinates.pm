package Google::Devicesandservices::Health::V4::DataCoordinates;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Date };
    eval { require Google::Type::Timeofday };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvZGV2aWNlc2FuZHNlcnZpY2VzL2hlYWx0aC92NC9kYXRhX2Nvb3JkaW5hdGVz
LnByb3RvEiNnb29nbGUuZGV2aWNlc2FuZHNlcnZpY2VzLmhlYWx0aC52NBofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhZnb29nbGUvdHlwZS9kYXRlLnBy
b3RvGhtnb29nbGUvdHlwZS90aW1lb2ZkYXkucHJvdG8ibAoNQ2l2aWxEYXRlVGltZRIqCgRk
YXRlGAEgASgLMhEuZ29vZ2xlLnR5cGUuRGF0ZUID4EECUgRkYXRlEi8KBHRpbWUYAiABKAsy
Fi5nb29nbGUudHlwZS5UaW1lT2ZEYXlCA+BBAVIEdGltZSKtAQoRQ2l2aWxUaW1lSW50ZXJ2
YWwSTQoFc3RhcnQYASABKAsyMi5nb29nbGUuZGV2aWNlc2FuZHNlcnZpY2VzLmhlYWx0aC52
NC5DaXZpbERhdGVUaW1lQgPgQQJSBXN0YXJ0EkkKA2VuZBgCIAEoCzIyLmdvb2dsZS5kZXZp
Y2VzYW5kc2VydmljZXMuaGVhbHRoLnY0LkNpdmlsRGF0ZVRpbWVCA+BBAlIDZW5kIucDChdP
YnNlcnZhdGlvblRpbWVJbnRlcnZhbBI+CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EECUglzdGFydFRpbWUSSAoQc3RhcnRfdXRjX29mZnNldBgC
IAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbkID4EECUg5zdGFydFV0Y09mZnNldBI6
CghlbmRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAlIHZW5k
VGltZRJECg5lbmRfdXRjX29mZnNldBgEIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
bkID4EECUgxlbmRVdGNPZmZzZXQSYQoQY2l2aWxfc3RhcnRfdGltZRgFIAEoCzIyLmdvb2ds
ZS5kZXZpY2VzYW5kc2VydmljZXMuaGVhbHRoLnY0LkNpdmlsRGF0ZVRpbWVCA+BBA1IOY2l2
aWxTdGFydFRpbWUSXQoOY2l2aWxfZW5kX3RpbWUYBiABKAsyMi5nb29nbGUuZGV2aWNlc2Fu
ZHNlcnZpY2VzLmhlYWx0aC52NC5DaXZpbERhdGVUaW1lQgPgQQNSDGNpdmlsRW5kVGltZSLj
AwoTU2Vzc2lvblRpbWVJbnRlcnZhbBI+CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EECUglzdGFydFRpbWUSSAoQc3RhcnRfdXRjX29mZnNldBgC
IAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbkID4EECUg5zdGFydFV0Y09mZnNldBI6
CghlbmRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAlIHZW5k
VGltZRJECg5lbmRfdXRjX29mZnNldBgEIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlv
bkID4EECUgxlbmRVdGNPZmZzZXQSYQoQY2l2aWxfc3RhcnRfdGltZRgFIAEoCzIyLmdvb2ds
ZS5kZXZpY2VzYW5kc2VydmljZXMuaGVhbHRoLnY0LkNpdmlsRGF0ZVRpbWVCA+BBA1IOY2l2
aWxTdGFydFRpbWUSXQoOY2l2aWxfZW5kX3RpbWUYBiABKAsyMi5nb29nbGUuZGV2aWNlc2Fu
ZHNlcnZpY2VzLmhlYWx0aC52NC5DaXZpbERhdGVUaW1lQgPgQQNSDGNpdmlsRW5kVGltZSL0
AQoVT2JzZXJ2YXRpb25TYW1wbGVUaW1lEkQKDXBoeXNpY2FsX3RpbWUYASABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQJSDHBoeXNpY2FsVGltZRI9Cgp1dGNfb2Zmc2V0
GAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQJSCXV0Y09mZnNldBJWCgpj
aXZpbF90aW1lGAMgASgLMjIuZ29vZ2xlLmRldmljZXNhbmRzZXJ2aWNlcy5oZWFsdGgudjQu
Q2l2aWxEYXRlVGltZUID4EEDUgljaXZpbFRpbWVChgIKJ2NvbS5nb29nbGUuZGV2aWNlc2Fu
ZHNlcnZpY2VzLmhlYWx0aC52NEIURGF0YUNvb3JkaW5hdGVzUHJvdG9QAVpOZ29vZ2xlLmdv
bGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZpY2VzYW5kc2VydmljZXMvaGVhbHRo
L2FwaXY0O2hlYWx0aHBiqgIjR29vZ2xlLkRldmljZXNBbmRTZXJ2aWNlcy5IZWFsdGguVjTK
AiNHb29nbGVcRGV2aWNlc0FuZFNlcnZpY2VzXEhlYWx0aFxWNOoCJkdvb2dsZTo6RGV2aWNl
c0FuZFNlcnZpY2VzOjpIZWFsdGg6OlY0Ss0lCgcSBQ4AggEBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMAKAoJCgID
AhIDFAApCgkKAgMDEgMVACAKCQoCAwQSAxYAJQoICgEIEgMYAEAKCQoCCCUSAxgAQAoICgEI
EgMZAGUKCQoCCAsSAxkAZQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADUKCQoCCAgS
AxsANQoICgEIEgMcAEAKCQoCCAESAxwAQAoICgEIEgMdAEAKCQoCCCkSAx0AQAoICgEIEgMe
AD8KCQoCCC0SAx4APwrkAQoCBAASBCQAKwEa1wEgQ2l2aWwgdGltZSByZXByZXNlbnRhdGlv
biBzaW1pbGFyIHRvCiBbZ29vZ2xlLnR5cGUuRGF0ZVRpbWVdW2dvb2dsZS50eXBlLkRhdGVU
aW1lXSwgYnV0IGVuc3VyZXMgdGhhdCBuZWl0aGVyIHRoZQogdGltZXpvbmUgbm9yIHRoZSBV
VEMgb2Zmc2V0IGNhbiBiZSBzZXQgdG8gYXZvaWQgY29uZnVzaW9uIGJldHdlZW4gY2l2aWwg
YW5kCiBwaHlzaWNhbCB0aW1lIHF1ZXJpZXMuCgoKCgMEAAESAyQIFQonCgQEAAIAEgMmAkUa
GiBSZXF1aXJlZC4gQ2FsZW5kYXIgZGF0ZS4KCgwKBQQAAgAGEgMmAhIKDAoFBAACAAESAyYT
FwoMCgUEAAIAAxIDJhobCgwKBQQAAgAIEgMmHEQKDwoIBAACAAicCAASAyYdQwpgCgQEAAIB
EgMqAkoaUyBPcHRpb25hbC4gVGltZSBvZiBkYXkuIERlZmF1bHRzIHRvIHRoZSBzdGFydCBv
ZiB0aGUgZGF5LCBhdCBtaWRuaWdodCBpZgogb21pdHRlZC4KCgwKBQQAAgEGEgMqAhcKDAoF
BAACAQESAyoYHAoMCgUEAAIBAxIDKh8gCgwKBQQAAgEIEgMqIUkKDwoIBAACAQicCAASAyoi
SAqaAQoCBAESBC8ANQEajQEgQ291bnRlcnBhcnQgb2YgW2dvb2dsZS50eXBlLkludGVydmFs
XVtnb29nbGUudHlwZS5JbnRlcnZhbF0sIGJ1dCB1c2luZwogW0NpdmlsRGF0ZVRpbWVdW2dv
b2dsZS5kZXZpY2VzYW5kc2VydmljZXMuaGVhbHRoLnY0LkNpdmlsRGF0ZVRpbWVdLgoKCgoD
BAEBEgMvCBkKOgoEBAECABIDMQJDGi0gUmVxdWlyZWQuIFRoZSBpbmNsdXNpdmUgc3RhcnQg
b2YgdGhlIHJhbmdlLgoKDAoFBAECAAYSAzECDwoMCgUEAQIAARIDMRAVCgwKBQQBAgADEgMx
GBkKDAoFBAECAAgSAzEaQgoPCggEAQIACJwIABIDMRtBCjgKBAQBAgESAzQCQRorIFJlcXVp
cmVkLiBUaGUgZXhjbHVzaXZlIGVuZCBvZiB0aGUgcmFuZ2UuCgoMCgUEAQIBBhIDNAIPCgwK
BQQBAgEBEgM0EBMKDAoFBAECAQMSAzQWFwoMCgUEAQIBCBIDNBhACg8KCAQBAgEInAgAEgM0
GT8KQwoCBAISBDgAUwEaNyBSZXByZXNlbnRzIGEgdGltZSBpbnRlcnZhbCBvZiBhbiBvYnNl
cnZlZCBkYXRhIHBvaW50LgoKCgoDBAIBEgM4CB8KNwoEBAICABIEOgI7LxopIFJlcXVpcmVk
LiBPYnNlcnZlZCBpbnRlcnZhbCBzdGFydCB0aW1lLgoKDAoFBAICAAYSAzoCGwoMCgUEAgIA
ARIDOhwmCgwKBQQCAgADEgM6KSoKDAoFBAICAAgSAzsGLgoPCggEAgIACJwIABIDOwctCpEB
CgQEAgIBEgQ/AkAvGoIBIFJlcXVpcmVkLiBUaGUgb2Zmc2V0IG9mIHRoZSB1c2VyJ3MgbG9j
YWwgdGltZSBhdCB0aGUgc3RhcnQgb2YgdGhlCiBvYnNlcnZhdGlvbiByZWxhdGl2ZSB0byB0
aGUgQ29vcmRpbmF0ZWQgVW5pdmVyc2FsIFRpbWUgKFVUQykuCgoMCgUEAgIBBhIDPwIaCgwK
BQQCAgEBEgM/GysKDAoFBAICAQMSAz8uLwoMCgUEAgIBCBIDQAYuCg8KCAQCAgEInAgAEgNA
By0KNQoEBAICAhIEQwJELxonIFJlcXVpcmVkLiBPYnNlcnZlZCBpbnRlcnZhbCBlbmQgdGlt
ZS4KCgwKBQQCAgIGEgNDAhsKDAoFBAICAgESA0McJAoMCgUEAgICAxIDQycoCgwKBQQCAgII
EgNEBi4KDwoIBAICAgicCAASA0QHLQqPAQoEBAICAxIESAJJLxqAASBSZXF1aXJlZC4gVGhl
IG9mZnNldCBvZiB0aGUgdXNlcidzIGxvY2FsIHRpbWUgYXQgdGhlIGVuZCBvZiB0aGUgb2Jz
ZXJ2YXRpb24KIHJlbGF0aXZlIHRvIHRoZSBDb29yZGluYXRlZCBVbml2ZXJzYWwgVGltZSAo
VVRDKS4KCgwKBQQCAgMGEgNIAhoKDAoFBAICAwESA0gbKQoMCgUEAgIDAxIDSCwtCgwKBQQC
AgMIEgNJBi4KDwoIBAICAwicCAASA0kHLQqRAQoEBAICBBIETQJOMhqCASBPdXRwdXQgb25s
eS4gT2JzZXJ2ZWQgaW50ZXJ2YWwgc3RhcnQgdGltZSBpbiBjaXZpbCB0aW1lIGluIHRoZSB0
aW1lem9uZSB0aGUKIHN1YmplY3QgaXMgaW4gYXQgdGhlIHN0YXJ0IG9mIHRoZSBvYnNlcnZl
ZCBpbnRlcnZhbAoKDAoFBAICBAYSA00CDwoMCgUEAgIEARIDTRAgCgwKBQQCAgQDEgNNIyQK
DAoFBAICBAgSA04GMQoPCggEAgIECJwIABIDTgcwCosBCgQEAgIFEgNSAk8afiBPdXRwdXQg
b25seS4gT2JzZXJ2ZWQgaW50ZXJ2YWwgZW5kIHRpbWUgaW4gY2l2aWwgdGltZSBpbiB0aGUg
dGltZXpvbmUgdGhlCiBzdWJqZWN0IGlzIGluIGF0IHRoZSBlbmQgb2YgdGhlIG9ic2VydmVk
IGludGVydmFsCgoMCgUEAgIFBhIDUgIPCgwKBQQCAgUBEgNSEB4KDAoFBAICBQMSA1IhIgoM
CgUEAgIFCBIDUiNOCg8KCAQCAgUInAgAEgNSJE0KcgoCBAMSBFcAcgEaZiBSZXByZXNlbnRz
IGEgdGltZSBpbnRlcnZhbCBvZiBzZXNzaW9uIGRhdGEgcG9pbnQsIHdoaWNoIGJ1bmRsZXMg
bXVsdGlwbGUKIG9ic2VydmVkIG1ldHJpY3MgdG9nZXRoZXIuCgoKCgMEAwESA1cIGwpBCgQE
AwIAEgRZAlovGjMgUmVxdWlyZWQuIFRoZSBzdGFydCB0aW1lIG9mIHRoZSBvYnNlcnZlZCBz
ZXNzaW9uLgoKDAoFBAMCAAYSA1kCGwoMCgUEAwIAARIDWRwmCgwKBQQDAgADEgNZKSoKDAoF
BAMCAAgSA1oGLgoPCggEAwIACJwIABIDWgctCowBCgQEAwIBEgReAl8vGn4gUmVxdWlyZWQu
IFRoZSBvZmZzZXQgb2YgdGhlIHVzZXIncyBsb2NhbCB0aW1lIGF0IHRoZSBzdGFydCBvZiB0
aGUgc2Vzc2lvbgogcmVsYXRpdmUgdG8gdGhlIENvb3JkaW5hdGVkIFVuaXZlcnNhbCBUaW1l
IChVVEMpLgoKDAoFBAMCAQYSA14CGgoMCgUEAwIBARIDXhsrCgwKBQQDAgEDEgNeLi8KDAoF
BAMCAQgSA18GLgoPCggEAwIBCJwIABIDXwctCj8KBAQDAgISBGICYy8aMSBSZXF1aXJlZC4g
VGhlIGVuZCB0aW1lIG9mIHRoZSBvYnNlcnZlZCBzZXNzaW9uLgoKDAoFBAMCAgYSA2ICGwoM
CgUEAwICARIDYhwkCgwKBQQDAgIDEgNiJygKDAoFBAMCAggSA2MGLgoPCggEAwICCJwIABID
YwctCooBCgQEAwIDEgRnAmgvGnwgUmVxdWlyZWQuIFRoZSBvZmZzZXQgb2YgdGhlIHVzZXIn
cyBsb2NhbCB0aW1lIGF0IHRoZSBlbmQgb2YgdGhlIHNlc3Npb24KIHJlbGF0aXZlIHRvIHRo
ZSBDb29yZGluYXRlZCBVbml2ZXJzYWwgVGltZSAoVVRDKS4KCgwKBQQDAgMGEgNnAhoKDAoF
BAMCAwESA2cbKQoMCgUEAwIDAxIDZywtCgwKBQQDAgMIEgNoBi4KDwoIBAMCAwicCAASA2gH
LQp9CgQEAwIEEgRsAm0yGm8gT3V0cHV0IG9ubHkuIFNlc3Npb24gc3RhcnQgdGltZSBpbiBj
aXZpbCB0aW1lIGluIHRoZSB0aW1lem9uZSB0aGUgc3ViamVjdAogaXMgaW4gYXQgdGhlIHN0
YXJ0IG9mIHRoZSBzZXNzaW9uLgoKDAoFBAMCBAYSA2wCDwoMCgUEAwIEARIDbBAgCgwKBQQD
AgQDEgNsIyQKDAoFBAMCBAgSA20GMQoPCggEAwIECJwIABIDbQcwCngKBAQDAgUSA3ECTxpr
IE91dHB1dCBvbmx5LiBTZXNzaW9uIGVuZCB0aW1lIGluIGNpdmlsIHRpbWUgaW4gdGhlIHRp
bWV6b25lIHRoZSBzdWJqZWN0IGlzCiBpbiBhdCB0aGUgZW5kIG9mIHRoZSBzZXNzaW9uLgoK
DAoFBAMCBQYSA3ECDwoMCgUEAwIFARIDcRAeCgwKBQQDAgUDEgNxISIKDAoFBAMCBQgSA3Ej
TgoPCggEAwIFCJwIABIDcSRNCkIKAgQEEgV1AIIBARo1IFJlcHJlc2VudHMgYSBzYW1wbGUg
dGltZSBvZiBhbiBvYnNlcnZlZCBkYXRhIHBvaW50LgoKCgoDBAQBEgN1CB0KNgoEBAQCABIE
dwJ4LxooIFJlcXVpcmVkLiBUaGUgdGltZSBvZiB0aGUgb2JzZXJ2YXRpb24uCgoMCgUEBAIA
BhIDdwIbCgwKBQQEAgABEgN3HCkKDAoFBAQCAAMSA3csLQoMCgUEBAIACBIDeAYuCg8KCAQE
AgAInAgAEgN4By0KhwEKBAQEAgESBHwCfS8aeSBSZXF1aXJlZC4gVGhlIG9mZnNldCBvZiB0
aGUgdXNlcidzIGxvY2FsIHRpbWUgZHVyaW5nIHRoZSBvYnNlcnZhdGlvbgogcmVsYXRpdmUg
dG8gdGhlIENvb3JkaW5hdGVkIFVuaXZlcnNhbCBUaW1lIChVVEMpLgoKDAoFBAQCAQYSA3wC
GgoMCgUEBAIBARIDfBslCgwKBQQEAgEDEgN8KCkKDAoFBAQCAQgSA30GLgoPCggEBAIBCJwI
ABIDfQctCm4KBAQEAgISBIEBAksaYCBPdXRwdXQgb25seS4gVGhlIGNpdmlsIHRpbWUgaW4g
dGhlIHRpbWV6b25lIHRoZSBzdWJqZWN0IGlzIGluCiBhdCB0aGUgdGltZSBvZiB0aGUgb2Jz
ZXJ2YXRpb24uCgoNCgUEBAICBhIEgQECDwoNCgUEBAICARIEgQEQGgoNCgUEBAICAxIEgQEd
HgoNCgUEBAICCBIEgQEfSgoQCggEBAICCJwIABIEgQEgSWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime ===
    # Fields for CivilDateTime
    # Field: date Type: 11 (.google.type.Date)
    # Field: time Type: 11 (.google.type.TimeOfDay)

# === Message: Google::Devicesandservices::Health::V4::DataCoordinates::CivilTimeInterval ===
    # Fields for CivilTimeInterval
    # Field: start Type: 11 (.google.devicesandservices.health.v4.CivilDateTime)
    # Field: end Type: 11 (.google.devicesandservices.health.v4.CivilDateTime)

# === Message: Google::Devicesandservices::Health::V4::DataCoordinates::ObservationTimeInterval ===
    # Fields for ObservationTimeInterval
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: start_utc_offset Type: 11 (.google.protobuf.Duration)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_utc_offset Type: 11 (.google.protobuf.Duration)
    # Field: civil_start_time Type: 11 (.google.devicesandservices.health.v4.CivilDateTime)
    # Field: civil_end_time Type: 11 (.google.devicesandservices.health.v4.CivilDateTime)

# === Message: Google::Devicesandservices::Health::V4::DataCoordinates::SessionTimeInterval ===
    # Fields for SessionTimeInterval
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: start_utc_offset Type: 11 (.google.protobuf.Duration)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_utc_offset Type: 11 (.google.protobuf.Duration)
    # Field: civil_start_time Type: 11 (.google.devicesandservices.health.v4.CivilDateTime)
    # Field: civil_end_time Type: 11 (.google.devicesandservices.health.v4.CivilDateTime)

# === Message: Google::Devicesandservices::Health::V4::DataCoordinates::ObservationSampleTime ===
    # Fields for ObservationSampleTime
    # Field: physical_time Type: 11 (.google.protobuf.Timestamp)
    # Field: utc_offset Type: 11 (.google.protobuf.Duration)
    # Field: civil_time Type: 11 (.google.devicesandservices.health.v4.CivilDateTime)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devicesandservices::Health::V4::DataCoordinates - Compiled Protocol Buffers messages for google/devicesandservices/health/v4/data_coordinates.proto

=head1 SYNOPSIS

    use Google::Devicesandservices::Health::V4::DataCoordinates;

    my $msg = Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime->new({
        date => $date,
        time => $time,
    });

    # Read or update a field
    my $val = $msg->date();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devicesandservices/health/v4/data_coordinates.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime

Civil time representation similar to
[google.type.DateTime][google.type.DateTime], but ensures that neither the
timezone nor the UTC offset can be set to avoid confusion between civil and
physical time queries.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->date() >> / C<< $msg->date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Required. Calendar date.

=item * C<< $msg->time() >> / C<< $msg->time($value) >>

Type: C<Message> (L<Google::Type::Timeofday::TimeOfDay>)

Optional. Time of day. Defaults to the start of the day, at midnight if
omitted.

=back

=head2 Google::Devicesandservices::Health::V4::DataCoordinates::CivilTimeInterval

Counterpart of [google.type.Interval][google.type.Interval], but using
[CivilDateTime][google.devicesandservices.health.v4.CivilDateTime].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start() >> / C<< $msg->start($value) >>

Type: C<Message> (L<Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime>)

Required. The inclusive start of the range.

=item * C<< $msg->end() >> / C<< $msg->end($value) >>

Type: C<Message> (L<Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime>)

Required. The exclusive end of the range.

=back

=head2 Google::Devicesandservices::Health::V4::DataCoordinates::ObservationTimeInterval

Represents a time interval of an observed data point.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Observed interval start time.

=item * C<< $msg->start_utc_offset() >> / C<< $msg->start_utc_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. The offset of the user's local time at the start of the
observation relative to the Coordinated Universal Time (UTC).

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Observed interval end time.

=item * C<< $msg->end_utc_offset() >> / C<< $msg->end_utc_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. The offset of the user's local time at the end of the observation
relative to the Coordinated Universal Time (UTC).

=item * C<< $msg->civil_start_time() >> / C<< $msg->civil_start_time($value) >>

Type: C<Message> (L<Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime>)

Output only. Observed interval start time in civil time in the timezone the
subject is in at the start of the observed interval

=item * C<< $msg->civil_end_time() >> / C<< $msg->civil_end_time($value) >>

Type: C<Message> (L<Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime>)

Output only. Observed interval end time in civil time in the timezone the
subject is in at the end of the observed interval

=back

=head2 Google::Devicesandservices::Health::V4::DataCoordinates::SessionTimeInterval

Represents a time interval of session data point, which bundles multiple
observed metrics together.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The start time of the observed session.

=item * C<< $msg->start_utc_offset() >> / C<< $msg->start_utc_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. The offset of the user's local time at the start of the session
relative to the Coordinated Universal Time (UTC).

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The end time of the observed session.

=item * C<< $msg->end_utc_offset() >> / C<< $msg->end_utc_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. The offset of the user's local time at the end of the session
relative to the Coordinated Universal Time (UTC).

=item * C<< $msg->civil_start_time() >> / C<< $msg->civil_start_time($value) >>

Type: C<Message> (L<Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime>)

Output only. Session start time in civil time in the timezone the subject
is in at the start of the session.

=item * C<< $msg->civil_end_time() >> / C<< $msg->civil_end_time($value) >>

Type: C<Message> (L<Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime>)

Output only. Session end time in civil time in the timezone the subject is
in at the end of the session.

=back

=head2 Google::Devicesandservices::Health::V4::DataCoordinates::ObservationSampleTime

Represents a sample time of an observed data point.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->physical_time() >> / C<< $msg->physical_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The time of the observation.

=item * C<< $msg->utc_offset() >> / C<< $msg->utc_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Required. The offset of the user's local time during the observation
relative to the Coordinated Universal Time (UTC).

=item * C<< $msg->civil_time() >> / C<< $msg->civil_time($value) >>

Type: C<Message> (L<Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime>)

Output only. The civil time in the timezone the subject is in
at the time of the observation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devicesandservices::Health::V4::DataCoordinates::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
