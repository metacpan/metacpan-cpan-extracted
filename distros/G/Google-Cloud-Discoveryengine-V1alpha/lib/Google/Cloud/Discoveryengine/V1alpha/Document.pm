package Google::Cloud::Discoveryengine::V1alpha::Document;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Common };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZG9jdW1lbnQucHJvdG8S
JGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoxZ29vZ2xlL2Ns
b3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL2NvbW1vbi5wcm90bxocZ29vZ2xlL3Byb3Rv
YnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoXZ29v
Z2xlL3JwYy9zdGF0dXMucHJvdG8i8QoKCERvY3VtZW50EjoKC3N0cnVjdF9kYXRhGAQgASgL
MhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEgAUgpzdHJ1Y3REYXRhEh0KCWpzb25fZGF0YRgF
IAEoCUgAUghqc29uRGF0YRIXCgRuYW1lGAEgASgJQgPgQQVSBG5hbWUSEwoCaWQYAiABKAlC
A+BBBVICaWQSGwoJc2NoZW1hX2lkGAMgASgJUghzY2hlbWFJZBJQCgdjb250ZW50GAogASgL
MjYuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50LkNvbnRl
bnRSB2NvbnRlbnQSLAoScGFyZW50X2RvY3VtZW50X2lkGAcgASgJUhBwYXJlbnREb2N1bWVu
dElkEkwKE2Rlcml2ZWRfc3RydWN0X2RhdGEYBiABKAsyFy5nb29nbGUucHJvdG9idWYuU3Ry
dWN0QgPgQQNSEWRlcml2ZWRTdHJ1Y3REYXRhElEKCGFjbF9pbmZvGAsgASgLMjYuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50LkFjbEluZm9SB2FjbElu
Zm8SPgoKaW5kZXhfdGltZRgNIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IJaW5kZXhUaW1lEmIKDGluZGV4X3N0YXR1cxgPIAEoCzI6Lmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5Eb2N1bWVudC5JbmRleFN0YXR1c0ID4EEDUgtpbmRleFN0
YXR1cxpkCgdDb250ZW50Eh0KCXJhd19ieXRlcxgCIAEoDEgAUghyYXdCeXRlcxISCgN1cmkY
AyABKAlIAFIDdXJpEhsKCW1pbWVfdHlwZRgBIAEoCVIIbWltZVR5cGVCCQoHY29udGVudBru
AQoHQWNsSW5mbxJiCgdyZWFkZXJzGAEgAygLMkguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLkRvY3VtZW50LkFjbEluZm8uQWNjZXNzUmVzdHJpY3Rpb25SB3JlYWRl
cnMafwoRQWNjZXNzUmVzdHJpY3Rpb24STwoKcHJpbmNpcGFscxgBIAMoCzIvLmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5QcmluY2lwYWxSCnByaW5jaXBhbHMSGQoI
aWRwX3dpZGUYAiABKAhSB2lkcFdpZGUagQEKC0luZGV4U3RhdHVzEjkKCmluZGV4X3RpbWUY
ASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglpbmRleFRpbWUSNwoNZXJyb3Jf
c2FtcGxlcxgCIAMoCzISLmdvb2dsZS5ycGMuU3RhdHVzUgxlcnJvclNhbXBsZXM6lgLqQZIC
CidkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRG9jdW1lbnQSZnByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9i
cmFuY2hlcy97YnJhbmNofS9kb2N1bWVudHMve2RvY3VtZW50fRJ/cHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRh
U3RvcmVzL3tkYXRhX3N0b3JlfS9icmFuY2hlcy97YnJhbmNofS9kb2N1bWVudHMve2RvY3Vt
ZW50fUIGCgRkYXRhIpgBChFQcm9jZXNzZWREb2N1bWVudBIdCglqc29uX2RhdGEYAiABKAlI
AFIIanNvbkRhdGESSwoIZG9jdW1lbnQYASABKAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5l
Lmdvb2dsZWFwaXMuY29tL0RvY3VtZW50Ughkb2N1bWVudEIXChVwcm9jZXNzZWRfZGF0YV9m
b3JtYXRCmQIKKGNvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCDURv
Y3VtZW50UHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBp
djFhbHBoYS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVS
WUVOR0lORaoCJEdvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFBbHBoYcoCJEdvb2ds
ZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFhbHBoYeoCJ0dvb2dsZTo6Q2xvdWQ6OkRpc2Nv
dmVyeUVuZ2luZTo6VjFhbHBoYUqSPQoHEgUOAPUBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQA
OwoJCgIDAxIDFQAmCgkKAgMEEgMWACkKCQoCAwUSAxcAIQoICgEIEgMZAEEKCQoCCCUSAxkA
QQoICgEIEgMaAGkKCQoCCAsSAxoAaQoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcAC4K
CQoCCAgSAxwALgoICgEIEgMdAEEKCQoCCAESAx0AQQoICgEIEgMeAC0KCQoCCCQSAx4ALQoI
CgEIEgMfAEEKCQoCCCkSAx8AQQoICgEIEgMgAEAKCQoCCC0SAyAAQApmCgIEABIFJADiAQEa
WSBEb2N1bWVudCBjYXB0dXJlcyBhbGwgcmF3IG1ldGFkYXRhIGluZm9ybWF0aW9uIG9mIGl0
ZW1zIHRvIGJlIHJlY29tbWVuZGVkIG9yCiBzZWFyY2hlZC4KCgoKAwQAARIDJAgQCgsKAwQA
BxIEJQIpBAoNCgUEAAedCBIEJQIpBAo6CgQEAAMAEgQsAkgDGiwgVW5zdHJ1Y3R1cmVkIGRh
dGEgbGlua2VkIHRvIHRoaXMgZG9jdW1lbnQuCgoMCgUEAAMAARIDLAoRCg4KBgQAAwAIABIE
LQQ8BQoOCgcEAAMACAABEgMtChEKpgMKBgQAAwACABIDNgYaGpYDIFRoZSBjb250ZW50IHJl
cHJlc2VudGVkIGFzIGEgc3RyZWFtIG9mIGJ5dGVzLiBUaGUgbWF4aW11bSBsZW5ndGggaXMK
IDEsMDAwLDAwMCBieXRlcyAoMSBNQiAvIH4wLjk1IE1pQikuCgogTm90ZTogQXMgd2l0aCBh
bGwgYGJ5dGVzYCBmaWVsZHMsIHRoaXMgZmllbGQgaXMgcmVwcmVzZW50ZWQgYXMgcHVyZQog
YmluYXJ5IGluIFByb3RvY29sIEJ1ZmZlcnMgYW5kIGJhc2U2NC1lbmNvZGVkIHN0cmluZyBp
biBKU09OLiBGb3IKIGV4YW1wbGUsIGBhYmMxMjMhPyQqJigpJy09QH5gIHNob3VsZCBiZSBy
ZXByZXNlbnRlZCBhcwogYFlXSmpNVEl6SVQ4a0tpWW9LU2N0UFVCK2AgaW4gSlNPTi4gU2Vl
CiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9wcm90b2NvbC1idWZmZXJzL2RvY3Mv
cHJvdG8zI2pzb24uCgoOCgcEAAMAAgAFEgM2BgsKDgoHBAADAAIAARIDNgwVCg4KBwQAAwAC
AAMSAzYYGQrLAQoGBAADAAIBEgM7BhUauwEgVGhlIFVSSSBvZiB0aGUgY29udGVudC4gT25s
eSBDbG91ZCBTdG9yYWdlIFVSSXMgKGUuZy4KIGBnczovL2J1Y2tldC1uYW1lL3BhdGgvdG8v
ZmlsZWApIGFyZSBzdXBwb3J0ZWQuIFRoZSBtYXhpbXVtIGZpbGUgc2l6ZQogaXMgMi41IE1C
IGZvciB0ZXh0LWJhc2VkIGZvcm1hdHMsIDIwMCBNQiBmb3Igb3RoZXIgZm9ybWF0cy4KCg4K
BwQAAwACAQUSAzsGDAoOCgcEAAMAAgEBEgM7DRAKDgoHBAADAAIBAxIDOxMUCqADCgYEAAMA
AgISA0cEGRqQAyBUaGUgTUlNRSB0eXBlIG9mIHRoZSBjb250ZW50LiBTdXBwb3J0ZWQgdHlw
ZXM6CgogKiBgYXBwbGljYXRpb24vcGRmYCAoUERGLCBvbmx5IG5hdGl2ZSBQREZzIGFyZSBz
dXBwb3J0ZWQgZm9yIG5vdykKICogYHRleHQvaHRtbGAgKEhUTUwpCiAqIGBhcHBsaWNhdGlv
bi92bmQub3BlbnhtbGZvcm1hdHMtb2ZmaWNlZG9jdW1lbnQud29yZHByb2Nlc3NpbmdtbC5k
b2N1bWVudGAgKERPQ1gpCiAqIGBhcHBsaWNhdGlvbi92bmQub3BlbnhtbGZvcm1hdHMtb2Zm
aWNlZG9jdW1lbnQucHJlc2VudGF0aW9ubWwucHJlc2VudGF0aW9uYCAoUFBUWCkKICogYHRl
eHQvcGxhaW5gIChUWFQpCgogU2VlIGh0dHBzOi8vd3d3LmlhbmEub3JnL2Fzc2lnbm1lbnRz
L21lZGlhLXR5cGVzL21lZGlhLXR5cGVzLnhodG1sLgoKDgoHBAADAAICBRIDRwQKCg4KBwQA
AwACAgESA0cLFAoOCgcEAAMAAgIDEgNHFxgKMQoEBAADARIFSwKRAQMaIiBBQ0wgSW5mb3Jt
YXRpb24gb2YgdGhlIERvY3VtZW50LgoKDAoFBAADAQESA0sKEQq0CAoGBAADAQMAEgaHAQSN
AQUaoQggQWNsUmVzdHJpY3Rpb24gdG8gbW9kZWwgY29tcGxleCBpbmhlcml0YW5jZSByZXN0
cmljdGlvbnMuCgogRXhhbXBsZTogTW9kZWxpbmcgYSAiQm90aCBQZXJtaXQiIGluaGVyaXRh
bmNlLCB3aGVyZSB0byBhY2Nlc3MgYQogY2hpbGQgZG9jdW1lbnQsIHVzZXIgbmVlZHMgdG8g
aGF2ZSBhY2Nlc3MgdG8gcGFyZW50IGRvY3VtZW50LgoKIERvY3VtZW50IEhpZXJhcmNoeSAt
IFNwYWNlX1MgLS0+IFBhZ2VfUC4KCiBSZWFkZXJzOgogICBTcGFjZV9TOiBncm91cF8xLCB1
c2VyXzEKICAgUGFnZV9QOiBncm91cF8yLCBncm91cF8zLCB1c2VyXzIKCiBTcGFjZV9TIEFD
TCBSZXN0cmljdGlvbiAtCiB7CiAgICJhY2xfaW5mbyI6IHsKICAgICAicmVhZGVycyI6IFsK
ICAgICAgIHsKICAgICAgICAgInByaW5jaXBhbHMiOiBbCiAgICAgICAgICAgewogICAgICAg
ICAgICAgImdyb3VwX2lkIjogImdyb3VwXzEiCiAgICAgICAgICAgfSwKICAgICAgICAgICB7
CiAgICAgICAgICAgICAidXNlcl9pZCI6ICJ1c2VyXzEiCiAgICAgICAgICAgfQogICAgICAg
ICBdCiAgICAgICB9CiAgICAgXQogICB9CiB9CgogUGFnZV9QIEFDTCBSZXN0cmljdGlvbi4K
IHsKICAgImFjbF9pbmZvIjogewogICAgICJyZWFkZXJzIjogWwogICAgICAgewogICAgICAg
ICAicHJpbmNpcGFscyI6IFsKICAgICAgICAgICB7CiAgICAgICAgICAgICAiZ3JvdXBfaWQi
OiAiZ3JvdXBfMiIKICAgICAgICAgICB9LAogICAgICAgICAgIHsKICAgICAgICAgICAgICJn
cm91cF9pZCI6ICJncm91cF8zIgogICAgICAgICAgIH0sCiAgICAgICAgICAgewogICAgICAg
ICAgICAgInVzZXJfaWQiOiAidXNlcl8yIgogICAgICAgICAgIH0KICAgICAgICAgXSwKICAg
ICAgIH0sCiAgICAgICB7CiAgICAgICAgICJwcmluY2lwYWxzIjogWwogICAgICAgICAgIHsK
ICAgICAgICAgICAgICJncm91cF9pZCI6ICJncm91cF8xIgogICAgICAgICAgIH0sCiAgICAg
ICAgICAgewogICAgICAgICAgICAgInVzZXJfaWQiOiAidXNlcl8xIgogICAgICAgICAgIH0K
ICAgICAgICAgXSwKICAgICAgIH0KICAgICBdCiAgIH0KIH0KCg8KBwQAAwEDAAESBIcBDB0K
JwoIBAADAQMAAgASBIkBBigaFSBMaXN0IG9mIHByaW5jaXBhbHMuCgoRCgkEAAMBAwACAAQS
BIkBBg4KEQoJBAADAQMAAgAGEgSJAQ8YChEKCQQAAwEDAAIAARIEiQEZIwoRCgkEAAMBAwAC
AAMSBIkBJicKOwoIBAADAQMAAgESBIwBBhgaKSBBbGwgdXNlcnMgd2l0aGluIHRoZSBJZGVu
dGl0eSBQcm92aWRlci4KChEKCQQAAwEDAAIBBRIEjAEGCgoRCgkEAAMBAwACAQESBIwBCxMK
EQoJBAADAQMAAgEDEgSMARYXCioKBgQAAwECABIEkAEEKxoaIFJlYWRlcnMgb2YgdGhlIGRv
Y3VtZW50LgoKDwoHBAADAQIABBIEkAEEDAoPCgcEAAMBAgAGEgSQAQ0eCg8KBwQAAwECAAES
BJABHyYKDwoHBAADAQIAAxIEkAEpKgovCgQEAAMCEgaUAQKcAQMaHyBJbmRleCBzdGF0dXMg
b2YgdGhlIGRvY3VtZW50LgoKDQoFBAADAgESBJQBChUKfgoGBAADAgIAEgSXAQQtGm4gVGhl
IHRpbWUgd2hlbiB0aGUgZG9jdW1lbnQgd2FzIGluZGV4ZWQuCiBJZiB0aGlzIGZpZWxkIGlz
IHBvcHVsYXRlZCwgaXQgbWVhbnMgdGhlIGRvY3VtZW50IGhhcyBiZWVuIGluZGV4ZWQuCgoP
CgcEAAMCAgAGEgSXAQQdCg8KBwQAAwICAAESBJcBHigKDwoHBAADAgIAAxIElwErLAqWAQoG
BAADAgIBEgSbAQQxGoUBIEEgc2FtcGxlIG9mIGVycm9ycyBlbmNvdW50ZXJlZCB3aGlsZSBp
bmRleGluZyB0aGUgZG9jdW1lbnQuCiBJZiB0aGlzIGZpZWxkIGlzIHBvcHVsYXRlZCwgdGhl
IGRvY3VtZW50IGlzIG5vdCBpbmRleGVkIGR1ZSB0byBlcnJvcnMuCgoPCgcEAAMCAgEEEgSb
AQQMCg8KBwQAAwICAQYSBJsBDR4KDwoHBAADAgIBARIEmwEfLAoPCgcEAAMCAgEDEgSbAS8w
CoYCCgQEAAgAEgaiAQKsAQMa9QEgRGF0YSByZXByZXNlbnRhdGlvbi4gT25lIG9mCiBbc3Ry
dWN0X2RhdGFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Eb2N1bWVu
dC5zdHJ1Y3RfZGF0YV0gb3IKIFtqc29uX2RhdGFdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5Eb2N1bWVudC5qc29uX2RhdGFdIHNob3VsZAogYmUgcHJvdmlkZWQg
b3RoZXJ3aXNlIGFuIGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyB0aHJvd24uCgoNCgUE
AAgAARIEogEIDArBAQoEBAACABIEpgEEKxqyASBUaGUgc3RydWN0dXJlZCBKU09OIGRhdGEg
Zm9yIHRoZSBkb2N1bWVudC4gSXQgc2hvdWxkIGNvbmZvcm0gdG8gdGhlCiByZWdpc3RlcmVk
IFtTY2hlbWFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFd
IG9yIGFuCiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgdGhyb3duLgoKDQoFBAACAAYS
BKYBBBoKDQoFBAACAAESBKYBGyYKDQoFBAACAAMSBKYBKSoKxgEKBAQAAgESBKsBBBkatwEg
VGhlIEpTT04gc3RyaW5nIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBkb2N1bWVudC4gSXQgc2hv
dWxkIGNvbmZvcm0gdG8gdGhlCiByZWdpc3RlcmVkIFtTY2hlbWFdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TY2hlbWFdIG9yIGFuCiBgSU5WQUxJRF9BUkdVTUVO
VGAgZXJyb3IgaXMgdGhyb3duLgoKDQoFBAACAQUSBKsBBAoKDQoFBAACAQESBKsBCxQKDQoF
BAACAQMSBKsBFxgKqAIKBAQAAgISBLQBAjwamQIgSW1tdXRhYmxlLiBUaGUgZnVsbCByZXNv
dXJjZSBuYW1lIG9mIHRoZSBkb2N1bWVudC4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFT
dG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9L2RvY3VtZW50cy97ZG9jdW1l
bnRfaWR9YC4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3
aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEwMjQKIGNoYXJhY3RlcnMuCgoNCgUEAAICBRIEtAEC
CAoNCgUEAAICARIEtAEJDQoNCgUEAAICAxIEtAEQEQoNCgUEAAICCBIEtAESOwoQCggEAAIC
CJwIABIEtAETOgqyAQoEBAACAxIEugECOhqjASBJbW11dGFibGUuIFRoZSBpZGVudGlmaWVy
IG9mIHRoZSBkb2N1bWVudC4KCiBJZCBzaG91bGQgY29uZm9ybSB0byBbUkZDLTEwMzRdKGh0
dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9yZmMxMDM0KQogc3RhbmRhcmQgd2l0aCBhIGxl
bmd0aCBsaW1pdCBvZiA2MyBjaGFyYWN0ZXJzLgoKDQoFBAACAwUSBLoBAggKDQoFBAACAwES
BLoBCQsKDQoFBAACAwMSBLoBDg8KDQoFBAACAwgSBLoBEDkKEAoIBAACAwicCAASBLoBETgK
TAoEBAACBBIEvQECFxo+IFRoZSBpZGVudGlmaWVyIG9mIHRoZSBzY2hlbWEgbG9jYXRlZCBp
biB0aGUgc2FtZSBkYXRhIHN0b3JlLgoKDQoFBAACBAUSBL0BAggKDQoFBAACBAESBL0BCRIK
DQoFBAACBAMSBL0BFRYKkAEKBAQAAgUSBMIBAhcagQEgVGhlIHVuc3RydWN0dXJlZCBkYXRh
IGxpbmtlZCB0byB0aGlzIGRvY3VtZW50LiBDb250ZW50IG11c3QgYmUgc2V0IGlmIHRoaXMK
IGRvY3VtZW50IGlzIHVuZGVyIGEKIGBDT05URU5UX1JFUVVJUkVEYCBkYXRhIHN0b3JlLgoK
DQoFBAACBQYSBMIBAgkKDQoFBAACBQESBMIBChEKDQoFBAACBQMSBMIBFBYK6AEKBAQAAgYS
BMkBAiAa2QEgVGhlIGlkZW50aWZpZXIgb2YgdGhlIHBhcmVudCBkb2N1bWVudC4gQ3VycmVu
dGx5IHN1cHBvcnRzIGF0IG1vc3QgdHdvIGxldmVsCiBkb2N1bWVudCBoaWVyYXJjaHkuCgog
SWQgc2hvdWxkIGNvbmZvcm0gdG8gW1JGQy0xMDM0XShodHRwczovL3Rvb2xzLmlldGYub3Jn
L2h0bWwvcmZjMTAzNCkKIHN0YW5kYXJkIHdpdGggYSBsZW5ndGggbGltaXQgb2YgNjMgY2hh
cmFjdGVycy4KCg0KBQQAAgYFEgTJAQIICg0KBQQAAgYBEgTJAQkbCg0KBQQAAgYDEgTJAR4f
CoABCgQEAAIHEgbNAQLOATIacCBPdXRwdXQgb25seS4gVGhpcyBmaWVsZCBpcyBPVVRQVVRf
T05MWS4KIEl0IGNvbnRhaW5zIGRlcml2ZWQgZGF0YSB0aGF0IGFyZSBub3QgaW4gdGhlIG9y
aWdpbmFsIGlucHV0IGRvY3VtZW50LgoKDQoFBAACBwYSBM0BAhgKDQoFBAACBwESBM0BGSwK
DQoFBAACBwMSBM0BLzAKDQoFBAACBwgSBM4BBjEKEAoIBAACBwicCAASBM4BBzAKPAoEBAAC
CBIE0QECGBouIEFjY2VzcyBjb250cm9sIGluZm9ybWF0aW9uIGZvciB0aGUgZG9jdW1lbnQu
CgoNCgUEAAIIBhIE0QECCQoNCgUEAAIIARIE0QEKEgoNCgUEAAIIAxIE0QEVFwr8AQoEBAAC
CRIG2AEC2QEyGusBIE91dHB1dCBvbmx5LiBUaGUgbGFzdCB0aW1lIHRoZSBkb2N1bWVudCB3
YXMgaW5kZXhlZC4gSWYgdGhpcyBmaWVsZCBpcyBzZXQsCiB0aGUgZG9jdW1lbnQgY291bGQg
YmUgcmV0dXJuZWQgaW4gc2VhcmNoIHJlc3VsdHMuCgogVGhpcyBmaWVsZCBpcyBPVVRQVVRf
T05MWS4gSWYgdGhpcyBmaWVsZCBpcyBub3QgcG9wdWxhdGVkLCBpdCBtZWFucyB0aGUKIGRv
Y3VtZW50IGhhcyBuZXZlciBiZWVuIGluZGV4ZWQuCgoNCgUEAAIJBhIE2AECGwoNCgUEAAIJ
ARIE2AEcJgoNCgUEAAIJAxIE2AEpKwoNCgUEAAIJCBIE2QEGMQoQCggEAAIJCJwIABIE2QEH
MAqRAgoEBAACChIE4QECTBqCAiBPdXRwdXQgb25seS4gVGhlIGluZGV4IHN0YXR1cyBvZiB0
aGUgZG9jdW1lbnQuCgogKiBJZiBkb2N1bWVudCBpcyBpbmRleGVkIHN1Y2Nlc3NmdWxseSwg
dGhlIGluZGV4X3RpbWUgZmllbGQgaXMgcG9wdWxhdGVkLgogKiBPdGhlcndpc2UsIGlmIGRv
Y3VtZW50IGlzIG5vdCBpbmRleGVkIGR1ZSB0byBlcnJvcnMsIHRoZSBlcnJvcl9zYW1wbGVz
CiAgIGZpZWxkIGlzIHBvcHVsYXRlZC4KICogT3RoZXJ3aXNlLCBpbmRleF9zdGF0dXMgaXMg
dW5zZXQuCgoNCgUEAAIKBhIE4QECDQoNCgUEAAIKARIE4QEOGgoNCgUEAAIKAxIE4QEdHwoN
CgUEAAIKCBIE4QEgSwoQCggEAAIKCJwIABIE4QEhSgpnCgIEARIG5gEA9QEBGlkgRG9jdW1l
bnQgY2FwdHVyZXMgYWxsIHJhdyBtZXRhZGF0YSBpbmZvcm1hdGlvbiBvZiBpdGVtcyB0byBi
ZSByZWNvbW1lbmRlZCBvcgogc2VhcmNoZWQuCgoLCgMEAQESBOYBCBkKOgoEBAEIABIG6AEC
6wEDGiogT3V0cHV0IGZvcm1hdCBvZiB0aGUgcHJvY2Vzc2VkIGRvY3VtZW50LgoKDQoFBAEI
AAESBOgBCB0KSQoEBAECABIE6gEEGRo7IFRoZSBKU09OIHN0cmluZyByZXByZXNlbnRhdGlv
biBvZiB0aGUgcHJvY2Vzc2VkIGRvY3VtZW50LgoKDQoFBAECAAUSBOoBBAoKDQoFBAECAAES
BOoBCxQKDQoFBAECAAMSBOoBFxgKpgEKBAQBAgESBu8BAvQBBBqVASBSZXF1aXJlZC4gRnVs
bCByZXNvdXJjZSBuYW1lIG9mIHRoZSByZWZlcmVuY2VkIGRvY3VtZW50LCBpbiB0aGUgZm9y
bWF0CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMv
Ki9icmFuY2hlcy8qL2RvY3VtZW50cy8qYC4KCg0KBQQBAgEFEgTvAQIICg0KBQQBAgEBEgTv
AQkRCg0KBQQBAgEDEgTvARQVCg8KBQQBAgEIEgbvARb0AQMKEAoIBAECAQicCAASBPABBCoK
EQoHBAECAQifCBIG8QEE8wEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Document::Document ===
    # Fields for Document
    # Field: struct_data Type: 11 (.google.protobuf.Struct)
    # Field: json_data Type: 9 ()
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: schema_id Type: 9 ()
    # Field: content Type: 11 (.google.cloud.discoveryengine.v1alpha.Document.Content)
    # Field: parent_document_id Type: 9 ()
    # Field: derived_struct_data Type: 11 (.google.protobuf.Struct)
    # Field: acl_info Type: 11 (.google.cloud.discoveryengine.v1alpha.Document.AclInfo)
    # Field: index_time Type: 11 (.google.protobuf.Timestamp)
    # Field: index_status Type: 11 (.google.cloud.discoveryengine.v1alpha.Document.IndexStatus)

# === Message: Google::Cloud::Discoveryengine::V1alpha::Document::ProcessedDocument ===
    # Fields for ProcessedDocument
    # Field: json_data Type: 9 ()
    # Field: document Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Document - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/document.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Document;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Document::Document->new({
        struct_data => $struct_data,
        json_data => $json_data,
        name => $name,
        id => $id,
    });

    # Read or update a field
    my $val = $msg->struct_data();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Document::Document->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/document.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Document::Document

Document captures all raw metadata information of items to be recommended or
searched.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->struct_data() >> / C<< $msg->struct_data($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The structured JSON data for the document. It should conform to the
registered [Schema][google.cloud.discoveryengine.v1alpha.Schema] or an
`INVALID_ARGUMENT` error is thrown.

=item * C<< $msg->json_data() >> / C<< $msg->json_data($value) >>

Type: C<String>

The JSON string representation of the document. It should conform to the
registered [Schema][google.cloud.discoveryengine.v1alpha.Schema] or an
`INVALID_ARGUMENT` error is thrown.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The full resource name of the document.
Format:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document_id}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Immutable. The identifier of the document.

Id should conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters.

=item * C<< $msg->schema_id() >> / C<< $msg->schema_id($value) >>

Type: C<String>

The identifier of the schema located in the same data store.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Document::Document::Content>)

The unstructured data linked to this document. Content must be set if this
document is under a
`CONTENT_REQUIRED` data store.

=item * C<< $msg->parent_document_id() >> / C<< $msg->parent_document_id($value) >>

Type: C<String>

The identifier of the parent document. Currently supports at most two level
document hierarchy.

Id should conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters.

=item * C<< $msg->derived_struct_data() >> / C<< $msg->derived_struct_data($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. This field is OUTPUT_ONLY.
It contains derived data that are not in the original input document.

=item * C<< $msg->acl_info() >> / C<< $msg->acl_info($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Document::Document::AclInfo>)

Access control information for the document.

=item * C<< $msg->index_time() >> / C<< $msg->index_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last time the document was indexed. If this field is set,
the document could be returned in search results.

This field is OUTPUT_ONLY. If this field is not populated, it means the
document has never been indexed.

=item * C<< $msg->index_status() >> / C<< $msg->index_status($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Document::Document::IndexStatus>)

Output only. The index status of the document.

* If document is indexed successfully, the index_time field is populated.
* Otherwise, if document is not indexed due to errors, the error_samples
  field is populated.
* Otherwise, index_status is unset.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Document::ProcessedDocument

Document captures all raw metadata information of items to be recommended or
searched.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->json_data() >> / C<< $msg->json_data($value) >>

Type: C<String>

The JSON string representation of the processed document.

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<String>

Required. Full resource name of the referenced document, in the format
`projects/*/locations/*/collections/*/dataStores/*/branches/*/documents/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Document::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
