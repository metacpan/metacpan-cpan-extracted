package Google::Cloud::Chronicle::V1::BigQueryExport;

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
CjBnb29nbGUvY2xvdWQvY2hyb25pY2xlL3YxL2JpZ19xdWVyeV9leHBvcnQucHJvdG8SGWdv
b2dsZS5jbG91ZC5jaHJvbmljbGUudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8a
F2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKUBwoOQmlnUXVl
cnlFeHBvcnQSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiUKC3Byb3Zpc2lvbmVkGAIgASgI
QgPgQQNSC3Byb3Zpc2lvbmVkEm4KGGJpZ19xdWVyeV9leHBvcnRfcGFja2FnZRgDIAEoDjIw
Lmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuQmlnUXVlcnlFeHBvcnRQYWNrYWdlQgPgQQNS
FWJpZ1F1ZXJ5RXhwb3J0UGFja2FnZRJsChVlbnRpdHlfZ3JhcGhfc2V0dGluZ3MYBCABKAsy
My5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkRhdGFTb3VyY2VFeHBvcnRTZXR0aW5nc0ID
4EEBUhNlbnRpdHlHcmFwaFNldHRpbmdzEmoKFGlvY19tYXRjaGVzX3NldHRpbmdzGAUgASgL
MjMuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5EYXRhU291cmNlRXhwb3J0U2V0dGluZ3NC
A+BBAVISaW9jTWF0Y2hlc1NldHRpbmdzEnIKGHJ1bGVfZGV0ZWN0aW9uc19zZXR0aW5ncxgG
IAEoCzIzLmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuRGF0YVNvdXJjZUV4cG9ydFNldHRp
bmdzQgPgQQFSFnJ1bGVEZXRlY3Rpb25zU2V0dGluZ3MSfQoedWRtX2V2ZW50c19hZ2dyZWdh
dGVzX3NldHRpbmdzGAcgASgLMjMuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5EYXRhU291
cmNlRXhwb3J0U2V0dGluZ3NCA+BBAVIbdWRtRXZlbnRzQWdncmVnYXRlc1NldHRpbmdzEmgK
E3VkbV9ldmVudHNfc2V0dGluZ3MYCCABKAsyMy5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYx
LkRhdGFTb3VyY2VFeHBvcnRTZXR0aW5nc0ID4EEBUhF1ZG1FdmVudHNTZXR0aW5nczqaAepB
lgEKJ2Nocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9CaWdRdWVyeUV4cG9ydBJLcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L2Jp
Z1F1ZXJ5RXhwb3J0Kg5iaWdRdWVyeUV4cG9ydDIOYmlnUXVlcnlFeHBvcnQiyQIKGERhdGFT
b3VyY2VFeHBvcnRTZXR0aW5ncxIdCgdlbmFibGVkGAEgASgIQgPgQQJSB2VuYWJsZWQSKgoO
cmV0ZW50aW9uX2RheXMYAiABKAVCA+BBAlINcmV0ZW50aW9uRGF5cxJrChdsYXRlc3RfZXhw
b3J0X2pvYl9zdGF0ZRgDIAEoDjIvLmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuTGF0ZXN0
RXhwb3J0Sm9iU3RhdGVCA+BBA1IUbGF0ZXN0RXhwb3J0Sm9iU3RhdGUSTwoTZGF0YV9mcmVz
aG5lc3NfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IRZGF0
YUZyZXNobmVzc1RpbWUSJAoLZGF0YV92b2x1bWUYBSABKANCA+BBA1IKZGF0YVZvbHVtZSJf
ChhHZXRCaWdRdWVyeUV4cG9ydFJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEpCidjaHJv
bmljbGUuZ29vZ2xlYXBpcy5jb20vQmlnUXVlcnlFeHBvcnRSBG5hbWUiuQEKG1VwZGF0ZUJp
Z1F1ZXJ5RXhwb3J0UmVxdWVzdBJYChBiaWdfcXVlcnlfZXhwb3J0GAEgASgLMikuZ29vZ2xl
LmNsb3VkLmNocm9uaWNsZS52MS5CaWdRdWVyeUV4cG9ydEID4EECUg5iaWdRdWVyeUV4cG9y
dBJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BB
AVIKdXBkYXRlTWFzayJpCh5Qcm92aXNpb25CaWdRdWVyeUV4cG9ydFJlcXVlc3QSRwoGcGFy
ZW50GAEgASgJQi/gQQL6QSkSJ2Nocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9CaWdRdWVyeUV4
cG9ydFIGcGFyZW50KowBChVCaWdRdWVyeUV4cG9ydFBhY2thZ2USKAokQklHX1FVRVJZX0VY
UE9SVF9QQUNLQUdFX1VOU1BFQ0lGSUVEEAASIgoeQklHX1FVRVJZX0VYUE9SVF9QQUNLQUdF
X0JZT0JREAESJQohQklHX1FVRVJZX0VYUE9SVF9QQUNLQUdFX0FEVkFOQ0VEEAIqiAEKFExh
dGVzdEV4cG9ydEpvYlN0YXRlEicKI0xBVEVTVF9FWFBPUlRfSk9CX1NUQVRFX1VOU1BFQ0lG
SUVEEAASIwofTEFURVNUX0VYUE9SVF9KT0JfU1RBVEVfU1VDQ0VTUxABEiIKHkxBVEVTVF9F
WFBPUlRfSk9CX1NUQVRFX0ZBSUxFRBACMuwGChVCaWdRdWVyeUV4cG9ydFNlcnZpY2USwAEK
EUdldEJpZ1F1ZXJ5RXhwb3J0EjMuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5HZXRCaWdR
dWVyeUV4cG9ydFJlcXVlc3QaKS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkJpZ1F1ZXJ5
RXhwb3J0IkuC0+STAj4SPC92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3Rh
bmNlcy8qL2JpZ1F1ZXJ5RXhwb3J0fdpBBG5hbWUSggIKFFVwZGF0ZUJpZ1F1ZXJ5RXhwb3J0
EjYuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5VcGRhdGVCaWdRdWVyeUV4cG9ydFJlcXVl
c3QaKS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkJpZ1F1ZXJ5RXhwb3J0IoYBgtPkkwJh
Mk0vdjEve2JpZ19xdWVyeV9leHBvcnQubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2lu
c3RhbmNlcy8qL2JpZ1F1ZXJ5RXhwb3J0fToQYmlnX3F1ZXJ5X2V4cG9ydNpBHGJpZ19xdWVy
eV9leHBvcnQsdXBkYXRlX21hc2sS3QEKF1Byb3Zpc2lvbkJpZ1F1ZXJ5RXhwb3J0EjkuZ29v
Z2xlLmNsb3VkLmNocm9uaWNsZS52MS5Qcm92aXNpb25CaWdRdWVyeUV4cG9ydFJlcXVlc3Qa
KS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkJpZ1F1ZXJ5RXhwb3J0IlyC0+STAk0iSC92
MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyp9L2JpZ1F1ZXJ5
RXhwb3J0OnByb3Zpc2lvbjoBKtpBBnBhcmVudBqqAcpBGGNocm9uaWNsZS5nb29nbGVhcGlz
LmNvbdJBiwFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nocm9uaWNsZSxodHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nocm9uaWNsZS5yZWFkb25seSxodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQsoBCh1jb20uZ29vZ2xl
LmNsb3VkLmNocm9uaWNsZS52MUITQmlnUXVlcnlFeHBvcnRQcm90b1ABWjtjbG91ZC5nb29n
bGUuY29tL2dvL2Nocm9uaWNsZS9hcGl2MS9jaHJvbmljbGVwYjtjaHJvbmljbGVwYqoCGUdv
b2dsZS5DbG91ZC5DaHJvbmljbGUuVjHKAhlHb29nbGVcQ2xvdWRcQ2hyb25pY2xlXFYx6gIc
R29vZ2xlOjpDbG91ZDo6Q2hyb25pY2xlOjpWMUrjLwoHEgUOAMUBAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACoKCQoCAwUSAxcAKQoICgEIEgMZADYK
CQoCCCUSAxkANgoICgEIEgMaAFIKCQoCCAsSAxoAUgoICgEIEgMbACIKCQoCCAoSAxsAIgoI
CgEIEgMcADQKCQoCCAgSAxwANAoICgEIEgMdADYKCQoCCAESAx0ANgoICgEIEgMeADYKCQoC
CCkSAx4ANgoICgEIEgMfADUKCQoCCC0SAx8ANQpaCgIGABIEIgBGARpOIFNlcnZpY2UgZm9y
IG1hbmFnaW5nIEJpZ1F1ZXJ5IGV4cG9ydCBjb25maWd1cmF0aW9ucyBmb3IgQ2hyb25pY2xl
IGluc3RhbmNlcy4KCgoKAwYAARIDIggdCgoKAwYAAxIDIwJACgwKBQYAA5kIEgMjAkAKCwoD
BgADEgQkAic3Cg0KBQYAA5oIEgQkAic3Ck8KBAYAAgASBCoCLwMaQSBHZXQgdGhlIEJpZ1F1
ZXJ5IGV4cG9ydCBjb25maWd1cmF0aW9uIGZvciBhIENocm9uaWNsZSBpbnN0YW5jZS4KCgwK
BQYAAgABEgMqBhcKDAoFBgACAAISAyoYMAoMCgUGAAIAAxIDKjtJCg0KBQYAAgAEEgQrBC0G
ChEKCQYAAgAEsMq8IhIEKwQtBgoMCgUGAAIABBIDLgQyCg8KCAYAAgAEmwgAEgMuBDIKUgoE
BgACARIEMgI5AxpEIFVwZGF0ZSB0aGUgQmlnUXVlcnkgZXhwb3J0IGNvbmZpZ3VyYXRpb24g
Zm9yIGEgQ2hyb25pY2xlIGluc3RhbmNlLgoKDAoFBgACAQESAzIGGgoMCgUGAAIBAhIDMhs2
CgwKBQYAAgEDEgMzDx0KDQoFBgACAQQSBDQENwYKEQoJBgACAQSwyrwiEgQ0BDcGCgwKBQYA
AgEEEgM4BEoKDwoIBgACAQSbCAASAzgESgrZAQoEBgACAhIEPgJFAxrKASBQcm92aXNpb24g
dGhlIEJpZ1F1ZXJ5IGV4cG9ydCBmb3IgYSBDaHJvbmljbGUgaW5zdGFuY2UuIFRoaXMgd2ls
bCBjcmVhdGUKIHt7Z2NwX25hbWV9fSByZXNvdXJjZXMgbGlrZSB7e3N0b3JhZ2VfbmFtZX19
IGJ1Y2tldHMsIEJpZ1F1ZXJ5IGRhdGFzZXRzCiBhbmQgc2V0IGRlZmF1bHQgZXhwb3J0IHNl
dHRpbmdzIGZvciBlYWNoIGRhdGEgc291cmNlLgoKDAoFBgACAgESAz4GHQoMCgUGAAICAhID
Ph48CgwKBQYAAgIDEgM/Dx0KDQoFBgACAgQSBEAEQwYKEQoJBgACAgSwyrwiEgRABEMGCgwK
BQYAAgIEEgNEBDQKDwoIBgACAgSbCAASA0QENApMCgIFABIESQBSARpAIFRoZSBCaWdRdWVy
eUV4cG9ydFBhY2thZ2UgZW50aXRsZWQgZm9yIHRoZSBDaHJvbmljbGUgaW5zdGFuY2UuCgoK
CgMFAAESA0kFGgo4CgQFAAIAEgNLAisaKyBUaGUgQmlnUXVlcnlFeHBvcnRQYWNrYWdlIGlz
IHVuc3BlY2lmaWVkLgoKDAoFBQACAAESA0sCJgoMCgUFAAIAAhIDSykqCkQKBAUAAgESA04C
JRo3IFRoZSBCaWdRdWVyeUV4cG9ydFBhY2thZ2UgaXMgQnJpbmcgWW91ciBPd24gQmlnUXVl
cnkuCgoMCgUFAAIBARIDTgIgCgwKBQUAAgECEgNOIyQKPgoEBQACAhIDUQIoGjEgVGhlIEJp
Z1F1ZXJ5RXhwb3J0UGFja2FnZSBpcyBBZHZhbmNlZCBCaWdRdWVyeS4KCgwKBQUAAgIBEgNR
AiMKDAoFBQACAgISA1EmJwo9CgIFARIEVQBeARoxIFRoZSBzdGF0ZSBvZiB0aGUgbGF0ZXN0
IGRhdGEgc291cmNlIGV4cG9ydCBqb2IuCgoKCgMFAQESA1UFGQo6CgQFAQIAEgNXAioaLSBU
aGUgbGF0ZXN0IGV4cG9ydCBqb2Igc3RhdGUgaXMgdW5zcGVjaWZpZWQuCgoMCgUFAQIAARID
VwIlCgwKBQUBAgACEgNXKCkKOQoEBQECARIDWgImGiwgVGhlIGxhdGVzdCBleHBvcnQgam9i
IHN0YXRlIGlzIHN1Y2Nlc3NmdWwuCgoMCgUFAQIBARIDWgIhCgwKBQUBAgECEgNaJCUKNQoE
BQECAhIDXQIlGiggVGhlIGxhdGVzdCBleHBvcnQgam9iIHN0YXRlIGlzIGZhaWxlZC4KCgwK
BQUBAgIBEgNdAiAKDAoFBQECAgISA10jJAr0AQoCBAASBWMAiwEBGuYBIFRoaXMgcmVzb3Vy
Y2UgcmVwcmVzZW50cyB0aGUgQmlnUXVlcnkgZXhwb3J0IGNvbmZpZ3VyYXRpb24gZm9yIGEg
Q2hyb25pY2xlCiBpbnN0YW5jZSB3aGljaCBpbmNsdWRlcyBHb29nbGUgQ2xvdWQgUGxhdGZv
cm0gcmVzb3VyY2VzIGxpa2UgQ2xvdWQgU3RvcmFnZQogYnVja2V0cywgQmlnUXVlcnkgZGF0
YXNldHMgZXRjIGFuZCB0aGUgZXhwb3J0IHNldHRpbmdzIGZvciBlYWNoIGRhdGEgc291cmNl
LgoKCgoDBAABEgNjCBYKCwoDBAAHEgRkAmkECg0KBQQAB50IEgRkAmkECpoBCgQEAAIAEgNu
Aj0ajAEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIEJpZ1F1ZXJ5RXhw
b3J0LgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2luc3RhbmNlcy97aW5zdGFuY2V9L2JpZ1F1ZXJ5RXhwb3J0CgoMCgUEAAIABRIDbgIICgwK
BQQAAgABEgNuCQ0KDAoFBAACAAMSA24QEQoMCgUEAAIACBIDbhI8Cg8KCAQAAgAInAgAEgNu
EzsKaAoEBAACARIDcgJDGlsgT3V0cHV0IG9ubHkuIFdoZXRoZXIgdGhlIEJpZ1F1ZXJ5RXhw
b3J0IGhhcyBiZWVuIHByb3Zpc2lvbmVkIGZvciB0aGUKIENocm9uaWNsZSBpbnN0YW5jZS4K
CgwKBQQAAgEFEgNyAgYKDAoFBAACAQESA3IHEgoMCgUEAAIBAxIDchUWCgwKBQQAAgEIEgNy
F0IKDwoIBAACAQicCAASA3IYQQpbCgQEAAICEgR1AnYyGk0gT3V0cHV0IG9ubHkuIFRoZSBC
aWdRdWVyeUV4cG9ydFBhY2thZ2UgZW50aXRsZWQgZm9yIHRoZSBDaHJvbmljbGUgaW5zdGFu
Y2UuCgoMCgUEAAICBhIDdQIXCgwKBQQAAgIBEgN1GDAKDAoFBAACAgMSA3UzNAoMCgUEAAIC
CBIDdgYxCg8KCAQAAgIInAgAEgN2BzAKTwoEBAACAxIEeQJ6LxpBIE9wdGlvbmFsLiBUaGUg
ZXhwb3J0IHNldHRpbmdzIGZvciB0aGUgRW50aXR5IEdyYXBoIGRhdGEgc291cmNlLgoKDAoF
BAACAwYSA3kCGgoMCgUEAAIDARIDeRswCgwKBQQAAgMDEgN5MzQKDAoFBAACAwgSA3oGLgoP
CggEAAIDCJwIABIDegctCk4KBAQAAgQSBH0Cfi8aQCBPcHRpb25hbC4gVGhlIGV4cG9ydCBz
ZXR0aW5ncyBmb3IgdGhlIElPQyBNYXRjaGVzIGRhdGEgc291cmNlLgoKDAoFBAACBAYSA30C
GgoMCgUEAAIEARIDfRsvCgwKBQQAAgQDEgN9MjMKDAoFBAACBAgSA34GLgoPCggEAAIECJwI
ABIDfgctClQKBAQAAgUSBoEBAoIBLxpEIE9wdGlvbmFsLiBUaGUgZXhwb3J0IHNldHRpbmdz
IGZvciB0aGUgUnVsZSBEZXRlY3Rpb25zIGRhdGEgc291cmNlLgoKDQoFBAACBQYSBIEBAhoK
DQoFBAACBQESBIEBGzMKDQoFBAACBQMSBIEBNjcKDQoFBAACBQgSBIIBBi4KEAoIBAACBQic
CAASBIIBBy0KWgoEBAACBhIGhQEChgEvGkogT3B0aW9uYWwuIFRoZSBleHBvcnQgc2V0dGlu
Z3MgZm9yIHRoZSBVRE0gRXZlbnRzIEFnZ3JlZ2F0ZXMgZGF0YSBzb3VyY2UuCgoNCgUEAAIG
BhIEhQECGgoNCgUEAAIGARIEhQEbOQoNCgUEAAIGAxIEhQE8PQoNCgUEAAIGCBIEhgEGLgoQ
CggEAAIGCJwIABIEhgEHLQpPCgQEAAIHEgaJAQKKAS8aPyBPcHRpb25hbC4gVGhlIGV4cG9y
dCBzZXR0aW5ncyBmb3IgdGhlIFVETSBFdmVudHMgZGF0YSBzb3VyY2UuCgoNCgUEAAIHBhIE
iQECGgoNCgUEAAIHARIEiQEbLgoNCgUEAAIHAxIEiQExMgoNCgUEAAIHCBIEigEGLgoQCggE
AAIHCJwIABIEigEHLQo2CgIEARIGjgEAoAEBGiggVGhlIGV4cG9ydCBzZXR0aW5ncyBmb3Ig
YSBkYXRhIHNvdXJjZS4KCgsKAwQBARIEjgEIIApICgQEAQIAEgSQAQI8GjogUmVxdWlyZWQu
IFdoZXRoZXIgdGhlIGRhdGEgc291cmNlIGlzIGVuYWJsZWQgZm9yIGV4cG9ydC4KCg0KBQQB
AgAFEgSQAQIGCg0KBQQBAgABEgSQAQcOCg0KBQQBAgADEgSQARESCg0KBQQBAgAIEgSQARM7
ChAKCAQBAgAInAgAEgSQARQ6CksKBAQBAgESBJMBAkQaPSBSZXF1aXJlZC4gVGhlIHJldGVu
dGlvbiBwZXJpb2QgZm9yIHRoZSBkYXRhIHNvdXJjZSBpbiBkYXlzLgoKDQoFBAECAQUSBJMB
AgcKDQoFBAECAQESBJMBCBYKDQoFBAECAQMSBJMBGRoKDQoFBAECAQgSBJMBG0MKEAoIBAEC
AQicCAASBJMBHEIKTgoEBAECAhIGlgEClwEyGj4gT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBv
ZiB0aGUgbGF0ZXN0IGRhdGEgc291cmNlIGV4cG9ydCBqb2IuCgoNCgUEAQICBhIElgECFgoN
CgUEAQICARIElgEXLgoNCgUEAQICAxIElgExMgoNCgUEAQICCBIElwEGMQoQCggEAQICCJwI
ABIElwEHMAqPAQoEBAECAxIGmwECnAEyGn8gT3V0cHV0IG9ubHkuIFRoZSBkYXRhIGZyZXNo
bmVzcyBvZiB0aGUgZ2l2ZW4gZXhwb3J0IHdoaWNoIHJlcHJlc2VudHMgdGhlCiB0aW1lIGJ1
Y2tldCBhdCB3aGljaCB0aGUgbGF0ZXN0IGV2ZW50IHdhcyBleHBvcnRlZC4KCg0KBQQBAgMG
EgSbAQIbCg0KBQQBAgMBEgSbARwvCg0KBQQBAgMDEgSbATIzCg0KBQQBAgMIEgScAQYxChAK
CAQBAgMInAgAEgScAQcwCkcKBAQBAgQSBJ8BAkQaOSBPdXRwdXQgb25seS4gVGhlIHN0b3Jl
ZCBkYXRhIHZvbHVtZSBvZiBhbGwgdGhlIGV4cG9ydHMuCgoNCgUEAQIEBRIEnwECBwoNCgUE
AQIEARIEnwEIEwoNCgUEAQIEAxIEnwEWFwoNCgUEAQIECBIEnwEYQwoQCggEAQIECJwIABIE
nwEZQgpLCgIEAhIGowEArQEBGj0gVGhlIHJlcXVlc3QgbWVzc2FnZSB0byBmZXRjaCBCaWdR
dWVyeSBFeHBvcnQgY29uZmlndXJhdGlvbi4KCgsKAwQCARIEowEIIAqnAQoEBAICABIGpwEC
rAEEGpYBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQmlncXVlcnlFeHBv
cnQgdG8gcmV0cmlldmUuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vYmlnUXVlcnlFeHBvcnQKCg0KBQQC
AgAFEgSnAQIICg0KBQQCAgABEgSnAQkNCg0KBQQCAgADEgSnARARCg8KBQQCAgAIEganARKs
AQMKEAoIBAICAAicCAASBKgBBCoKEQoHBAICAAifCBIGqQEEqwEFCkwKAgQDEgawAQC5AQEa
PiBUaGUgcmVxdWVzdCBtZXNzYWdlIHRvIHVwZGF0ZSBCaWdRdWVyeSBFeHBvcnQgY29uZmln
dXJhdGlvbi4KCgsKAwQDARIEsAEIIwqXAQoEBAMCABIEtAECTxqIASBSZXF1aXJlZC4gVGhl
IEJpZ1F1ZXJ5RXhwb3J0IHNldHRpbmdzIHRvIHVwZGF0ZS4KIEZvcm1hdDoKIHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9i
aWdRdWVyeUV4cG9ydAoKDQoFBAMCAAYSBLQBAhAKDQoFBAMCAAESBLQBESEKDQoFBAMCAAMS
BLQBJCUKDQoFBAMCAAgSBLQBJk4KEAoIBAMCAAicCAASBLQBJ00KOQoEBAMCARIGtwECuAEv
GikgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuCgoNCgUEAwIBBhIE
twECGwoNCgUEAwIBARIEtwEcJwoNCgUEAwIBAxIEtwEqKwoNCgUEAwIBCBIEuAEGLgoQCggE
AwIBCJwIABIEuAEHLQpPCgIEBBIGvAEAxQEBGkEgVGhlIHJlcXVlc3QgbWVzc2FnZSB0byBw
cm92aXNpb24gQmlnUXVlcnkgRXhwb3J0IGNvbmZpZ3VyYXRpb24uCgoLCgMEBAESBLwBCCYK
nwEKBAQEAgASBr8BAsQBBBqOASBSZXF1aXJlZC4gVGhlIGluc3RhbmNlIGZvciB3aGljaCBC
aWdRdWVyeSBleHBvcnQgaXMgYmVpbmcgcHJvdmlzaW9uZWQuCiBGb3JtYXQ6IHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfQoK
DQoFBAQCAAUSBL8BAggKDQoFBAQCAAESBL8BCQ8KDQoFBAQCAAMSBL8BEhMKDwoFBAQCAAgS
Br8BFMQBAwoQCggEBAIACJwIABIEwAEEKgoRCgcEBAIACJ8IEgbBAQTDAQViBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport ===
    # Fields for BigQueryExport
    # Field: name Type: 9 ()
    # Field: provisioned Type: 8 ()
    # Field: big_query_export_package Type: 14 (.google.cloud.chronicle.v1.BigQueryExportPackage)
    # Field: entity_graph_settings Type: 11 (.google.cloud.chronicle.v1.DataSourceExportSettings)
    # Field: ioc_matches_settings Type: 11 (.google.cloud.chronicle.v1.DataSourceExportSettings)
    # Field: rule_detections_settings Type: 11 (.google.cloud.chronicle.v1.DataSourceExportSettings)
    # Field: udm_events_aggregates_settings Type: 11 (.google.cloud.chronicle.v1.DataSourceExportSettings)
    # Field: udm_events_settings Type: 11 (.google.cloud.chronicle.v1.DataSourceExportSettings)

# === Message: Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings ===
    # Fields for DataSourceExportSettings
    # Field: enabled Type: 8 ()
    # Field: retention_days Type: 5 ()
    # Field: latest_export_job_state Type: 14 (.google.cloud.chronicle.v1.LatestExportJobState)
    # Field: data_freshness_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data_volume Type: 3 ()

# === Message: Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest ===
    # Fields for GetBigQueryExportRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::BigQueryExport::UpdateBigQueryExportRequest ===
    # Fields for UpdateBigQueryExportRequest
    # Field: big_query_export Type: 11 (.google.cloud.chronicle.v1.BigQueryExport)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest ===
    # Fields for ProvisionBigQueryExportRequest
    # Field: parent Type: 9 ()

# === Service Client: Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExportServiceClient ===
package Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExportServiceClient;

=pod

=head2 Service Client: Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExportServiceClient

Client stub representing the remote C<BigQueryExportService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chronicle.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chronicle.googleapis.com:443' );

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

sub get_big_query_export {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.BigQueryExportService',
        method         => 'GetBigQueryExport',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport',
    });
}

sub update_big_query_export {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::BigQueryExport::UpdateBigQueryExportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.BigQueryExportService',
        method         => 'UpdateBigQueryExport',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport',
    });
}

sub provision_big_query_export {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.BigQueryExportService',
        method         => 'ProvisionBigQueryExport',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Chronicle::V1::BigQueryExport - Compiled Protocol Buffers messages for google/cloud/chronicle/v1/big_query_export.proto

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::BigQueryExport;

    my $msg = Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport->new({
        name => $name,
        provisioned => $provisioned,
        big_query_export_package => $big_query_export_package,
        entity_graph_settings => $entity_graph_settings,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/chronicle/v1/big_query_export.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport

This resource represents the BigQuery export configuration for a Chronicle
instance which includes Google Cloud Platform resources like Cloud Storage
buckets, BigQuery datasets etc and the export settings for each data source.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the BigQueryExport.
Format:
projects/{project}/locations/{location}/instances/{instance}/bigQueryExport

=item * C<< $msg->provisioned() >> / C<< $msg->provisioned($value) >>

Type: C<Bool>

Output only. Whether the BigQueryExport has been provisioned for the
Chronicle instance.

=item * C<< $msg->big_query_export_package() >> / C<< $msg->big_query_export_package($value) >>

Type: C<Enum> (L<Google::Cloud::Chronicle::V1::BigQueryExportPackage>)

Output only. The BigQueryExportPackage entitled for the Chronicle instance.

=item * C<< $msg->entity_graph_settings() >> / C<< $msg->entity_graph_settings($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings>)

Optional. The export settings for the Entity Graph data source.

=item * C<< $msg->ioc_matches_settings() >> / C<< $msg->ioc_matches_settings($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings>)

Optional. The export settings for the IOC Matches data source.

=item * C<< $msg->rule_detections_settings() >> / C<< $msg->rule_detections_settings($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings>)

Optional. The export settings for the Rule Detections data source.

=item * C<< $msg->udm_events_aggregates_settings() >> / C<< $msg->udm_events_aggregates_settings($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings>)

Optional. The export settings for the UDM Events Aggregates data source.

=item * C<< $msg->udm_events_settings() >> / C<< $msg->udm_events_settings($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings>)

Optional. The export settings for the UDM Events data source.

=back

=head2 Google::Cloud::Chronicle::V1::BigQueryExport::DataSourceExportSettings

The export settings for a data source.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Required. Whether the data source is enabled for export.

=item * C<< $msg->retention_days() >> / C<< $msg->retention_days($value) >>

Type: C<Int32>

Required. The retention period for the data source in days.

=item * C<< $msg->latest_export_job_state() >> / C<< $msg->latest_export_job_state($value) >>

Type: C<Enum> (L<Google::Cloud::Chronicle::V1::LatestExportJobState>)

Output only. The state of the latest data source export job.

=item * C<< $msg->data_freshness_time() >> / C<< $msg->data_freshness_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The data freshness of the given export which represents the
time bucket at which the latest event was exported.

=item * C<< $msg->data_volume() >> / C<< $msg->data_volume($value) >>

Type: C<Int64>

Output only. The stored data volume of all the exports.

=back

=head2 Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest

The request message to fetch BigQuery Export configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the BigqueryExport to retrieve.
Format:
projects/{project}/locations/{location}/instances/{instance}/bigQueryExport

=back

=head2 Google::Cloud::Chronicle::V1::BigQueryExport::UpdateBigQueryExportRequest

The request message to update BigQuery Export configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->big_query_export() >> / C<< $msg->big_query_export($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport>)

Required. The BigQueryExport settings to update.
Format:
projects/{project}/locations/{location}/instances/{instance}/bigQueryExport

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest

The request message to provision BigQuery Export configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The instance for which BigQuery export is being provisioned.
Format: projects/{project}/locations/{location}/instances/{instance}

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Chronicle::V1::BigQueryExport::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
