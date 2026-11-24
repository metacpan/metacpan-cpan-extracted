package Google::Cloud::Eventarc::V1::Trigger;

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
    eval { require Google::Cloud::Eventarc::V1::NetworkConfig };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Code };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvdHJpZ2dlci5wcm90bxIYZ29vZ2xlLmNsb3Vk
LmV2ZW50YXJjLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvbmV0d29ya19j
b25maWcucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aFWdvb2dsZS9y
cGMvY29kZS5wcm90byLkCQoHVHJpZ2dlchIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSFQoD
dWlkGAIgASgJQgPgQQNSA3VpZBJACgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgGIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJSCg1ldmVudF9m
aWx0ZXJzGAggAygLMiUuZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnYxLkV2ZW50RmlsdGVyQgbg
QQbgQQJSDGV2ZW50RmlsdGVycxJSCg9zZXJ2aWNlX2FjY291bnQYCSABKAlCKeBBAfpBIwoh
aWFtLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VBY2NvdW50Ug5zZXJ2aWNlQWNjb3VudBJMCgtk
ZXN0aW5hdGlvbhgKIAEoCzIlLmdvb2dsZS5jbG91ZC5ldmVudGFyYy52MS5EZXN0aW5hdGlv
bkID4EECUgtkZXN0aW5hdGlvbhJGCgl0cmFuc3BvcnQYCyABKAsyIy5nb29nbGUuY2xvdWQu
ZXZlbnRhcmMudjEuVHJhbnNwb3J0QgPgQQFSCXRyYW5zcG9ydBJKCgZsYWJlbHMYDCADKAsy
LS5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjEuVHJpZ2dlci5MYWJlbHNFbnRyeUID4EEBUgZs
YWJlbHMSHQoHY2hhbm5lbBgNIAEoCUID4EEBUgdjaGFubmVsElYKCmNvbmRpdGlvbnMYDyAD
KAsyMS5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjEuVHJpZ2dlci5Db25kaXRpb25zRW50cnlC
A+BBA1IKY29uZGl0aW9ucxI6ChdldmVudF9kYXRhX2NvbnRlbnRfdHlwZRgQIAEoCUID4EEB
UhRldmVudERhdGFDb250ZW50VHlwZRIoCg1zYXRpc2ZpZXNfcHpzGBMgASgIQgPgQQNSDHNh
dGlzZmllc1B6cxJVCgxyZXRyeV9wb2xpY3kYFCABKAsyLS5nb29nbGUuY2xvdWQuZXZlbnRh
cmMudjEuVHJpZ2dlci5SZXRyeVBvbGljeUID4EEBUgtyZXRyeVBvbGljeRIXCgRldGFnGGMg
ASgJQgPgQQNSBGV0YWcaNQoLUmV0cnlQb2xpY3kSJgoMbWF4X2F0dGVtcHRzGAEgASgFQgPg
QQFSC21heEF0dGVtcHRzGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZh
bHVlGAIgASgJUgV2YWx1ZToCOAEaZwoPQ29uZGl0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5Ej4KBXZhbHVlGAIgASgLMiguZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnYxLlN0YXRlQ29u
ZGl0aW9uUgV2YWx1ZToCOAE6c+pBcAofZXZlbnRhcmMuZ29vZ2xlYXBpcy5jb20vVHJpZ2dl
chI6cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3RyaWdnZXJzL3t0
cmlnZ2VyfSoIdHJpZ2dlcnMyB3RyaWdnZXIibAoLRXZlbnRGaWx0ZXISIQoJYXR0cmlidXRl
GAEgASgJQgPgQQJSCWF0dHJpYnV0ZRIZCgV2YWx1ZRgCIAEoCUID4EECUgV2YWx1ZRIfCghv
cGVyYXRvchgDIAEoCUID4EEBUghvcGVyYXRvciJQCg5TdGF0ZUNvbmRpdGlvbhIkCgRjb2Rl
GAEgASgOMhAuZ29vZ2xlLnJwYy5Db2RlUgRjb2RlEhgKB21lc3NhZ2UYAiABKAlSB21lc3Nh
Z2Ui1gMKC0Rlc3RpbmF0aW9uEkEKCWNsb3VkX3J1bhgBIAEoCzIiLmdvb2dsZS5jbG91ZC5l
dmVudGFyYy52MS5DbG91ZFJ1bkgAUghjbG91ZFJ1bhJZCg5jbG91ZF9mdW5jdGlvbhgCIAEo
CUIw+kEtCitjbG91ZGZ1bmN0aW9ucy5nb29nbGVhcGlzLmNvbS9DbG91ZEZ1bmN0aW9uSABS
DWNsb3VkRnVuY3Rpb24SMQoDZ2tlGAMgASgLMh0uZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnYx
LkdLRUgAUgNna2USRAoId29ya2Zsb3cYBCABKAlCJvpBIwohd29ya2Zsb3dzLmdvb2dsZWFw
aXMuY29tL1dvcmtmbG93SABSCHdvcmtmbG93Ek0KDWh0dHBfZW5kcG9pbnQYBSABKAsyJi5n
b29nbGUuY2xvdWQuZXZlbnRhcmMudjEuSHR0cEVuZHBvaW50SABSDGh0dHBFbmRwb2ludBJT
Cg5uZXR3b3JrX2NvbmZpZxgGIAEoCzInLmdvb2dsZS5jbG91ZC5ldmVudGFyYy52MS5OZXR3
b3JrQ29uZmlnQgPgQQFSDW5ldHdvcmtDb25maWdCDAoKZGVzY3JpcHRvciJXCglUcmFuc3Bv
cnQSOgoGcHVic3ViGAEgASgLMiAuZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnYxLlB1YnN1YkgA
UgZwdWJzdWJCDgoMaW50ZXJtZWRpYXJ5In4KCENsb3VkUnVuEjwKB3NlcnZpY2UYASABKAlC
IuBBAvpBHAoacnVuLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VSB3NlcnZpY2USFwoEcGF0aBgC
IAEoCUID4EEBUgRwYXRoEhsKBnJlZ2lvbhgDIAEoCUID4EECUgZyZWdpb24ioAEKA0dLRRId
CgdjbHVzdGVyGAEgASgJQgPgQQJSB2NsdXN0ZXISHwoIbG9jYXRpb24YAiABKAlCA+BBAlII
bG9jYXRpb24SIQoJbmFtZXNwYWNlGAMgASgJQgPgQQJSCW5hbWVzcGFjZRIdCgdzZXJ2aWNl
GAQgASgJQgPgQQJSB3NlcnZpY2USFwoEcGF0aBgFIAEoCUID4EEBUgRwYXRoIkwKBlB1YnN1
YhIZCgV0b3BpYxgBIAEoCUID4EEBUgV0b3BpYxInCgxzdWJzY3JpcHRpb24YAiABKAlCA+BB
A1IMc3Vic2NyaXB0aW9uIiUKDEh0dHBFbmRwb2ludBIVCgN1cmkYASABKAlCA+BBAlIDdXJp
QqEFChxjb20uZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLnYxQgxUcmlnZ2VyUHJvdG9QAVo4Y2xv
dWQuZ29vZ2xlLmNvbS9nby9ldmVudGFyYy9hcGl2MS9ldmVudGFyY3BiO2V2ZW50YXJjcGLq
QWsKK2Nsb3VkZnVuY3Rpb25zLmdvb2dsZWFwaXMuY29tL0Nsb3VkRnVuY3Rpb24SPHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9mdW5jdGlvbnMve2Z1bmN0aW9u
fepBWQohaWFtLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VBY2NvdW50EjRwcm9qZWN0cy97cHJv
amVjdH0vc2VydmljZUFjY291bnRzL3tzZXJ2aWNlX2FjY291bnR96kEfChpydW4uZ29vZ2xl
YXBpcy5jb20vU2VydmljZRIBKupBYQohd29ya2Zsb3dzLmdvb2dsZWFwaXMuY29tL1dvcmtm
bG93Ejxwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vd29ya2Zsb3dz
L3t3b3JrZmxvd33qQXYKKGNvbXB1dGUuZ29vZ2xlYXBpcy5jb20vTmV0d29ya0F0dGFjaG1l
bnQSSnByb2plY3RzL3twcm9qZWN0fS9yZWdpb25zL3tyZWdpb259L25ldHdvcmtBdHRhY2ht
ZW50cy97bmV0d29ya2F0dGFjaG1lbnR96kFtCidpbnRlZ3JhdGlvbnMuZ29vZ2xlYXBpcy5j
b20vSW50ZWdyYXRpb24SQnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9pbnRlZ3JhdGlvbnMve2ludGVncmF0aW9ufUqJWwoHEgUOALgCAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQANwoJCgIDAxIDFQApCgkKAgMEEgMWAB8KCAoBCBIDGABPCgkKAggLEgMYAE8K
CAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAtCgkKAggIEgMaAC0KCAoBCBIDGwA1CgkK
AggBEgMbADUKCQoBCBIEHAAfAgoMCgQInQgAEgQcAB8CCgkKAQgSBCAAIwIKDAoECJ0IARIE
IAAjAgoJCgEIEgQkACcCCgwKBAidCAISBCQAJwIKCQoBCBIEKAArAgoMCgQInQgDEgQoACsC
CgkKAQgSBCwALwIKDAoECJ0IBBIELAAvAgoJCgEIEgQwADMCCgwKBAidCAUSBDAAMwIKOAoC
BAASBTYAmQEBGisgQSByZXByZXNlbnRhdGlvbiBvZiB0aGUgdHJpZ2dlciByZXNvdXJjZS4K
CgoKAwQAARIDNggPCgsKAwQABxIENwI8BAoNCgUEAAedCBIENwI8BApuCgQEAAMAEgRBAkUD
GmAgVGhlIHJldHJ5IHBvbGljeSBjb25maWd1cmF0aW9uIGZvciB0aGUgVHJpZ2dlci4KCiBD
YW4gb25seSBiZSBzZXQgd2l0aCBDbG91ZCBSdW4gZGVzdGluYXRpb25zLgoKDAoFBAADAAES
A0EKFQpvCgYEAAMAAgASA0QERBpgIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2Yg
ZGVsaXZlcnkgYXR0ZW1wdHMgZm9yIGFueSBtZXNzYWdlLiBUaGUKIG9ubHkgdmFsaWQgdmFs
dWUgaXMgMS4KCg4KBwQAAwACAAUSA0QECQoOCgcEAAMAAgABEgNEChYKDgoHBAADAAIAAxID
RBkaCg4KBwQAAwACAAgSA0QbQwoRCgoEAAMAAgAInAgAEgNEHEIKwwEKBAQAAgASA0oCOxq1
ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHRyaWdnZXIuIE11c3QgYmUg
dW5pcXVlIHdpdGhpbiB0aGUKIGxvY2F0aW9uIG9mIHRoZSBwcm9qZWN0IGFuZCBtdXN0IGJl
IGluCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3RyaWdnZXJz
L3t0cmlnZ2VyfWAgZm9ybWF0LgoKDAoFBAACAAUSA0oCCAoMCgUEAAIAARIDSgkNCgwKBQQA
AgADEgNKEBEKDAoFBAACAAgSA0oSOgoPCggEAAIACJwIABIDShM5Cq8BCgQEAAIBEgNPAj0a
oQEgT3V0cHV0IG9ubHkuIFNlcnZlci1hc3NpZ25lZCB1bmlxdWUgaWRlbnRpZmllciBmb3Ig
dGhlIHRyaWdnZXIuIFRoZSB2YWx1ZQogaXMgYSBVVUlENCBzdHJpbmcgYW5kIGd1YXJhbnRl
ZWQgdG8gcmVtYWluIHVuY2hhbmdlZCB1bnRpbCB0aGUgcmVzb3VyY2UgaXMKIGRlbGV0ZWQu
CgoMCgUEAAIBBRIDTwIICgwKBQQAAgEBEgNPCQwKDAoFBAACAQMSA08PEAoMCgUEAAIBCBID
TxE8Cg8KCAQAAgEInAgAEgNPEjsKLwoEBAACAhIEUgJTMhohIE91dHB1dCBvbmx5LiBUaGUg
Y3JlYXRpb24gdGltZS4KCgwKBQQAAgIGEgNSAhsKDAoFBAACAgESA1IcJwoMCgUEAAICAxID
UiorCgwKBQQAAgIIEgNTBjEKDwoIBAACAgicCAASA1MHMAo0CgQEAAIDEgRWAlcyGiYgT3V0
cHV0IG9ubHkuIFRoZSBsYXN0LW1vZGlmaWVkIHRpbWUuCgoMCgUEAAIDBhIDVgIbCgwKBQQA
AgMBEgNWHCcKDAoFBAACAwMSA1YqKwoMCgUEAAIDCBIDVwYxCg8KCAQAAgMInAgAEgNXBzAK
rwEKBAQAAgQSBFwCXwQaoAEgUmVxdWlyZWQuIFVub3JkZXJlZCBsaXN0LiBUaGUgbGlzdCBv
ZiBmaWx0ZXJzIHRoYXQgYXBwbGllcyB0byBldmVudAogYXR0cmlidXRlcy4gT25seSBldmVu
dHMgdGhhdCBtYXRjaCBhbGwgdGhlIHByb3ZpZGVkIGZpbHRlcnMgYXJlIHNlbnQgdG8gdGhl
CiBkZXN0aW5hdGlvbi4KCgwKBQQAAgQEEgNcAgoKDAoFBAACBAYSA1wLFgoMCgUEAAIEARID
XBckCgwKBQQAAgQDEgNcJygKDQoFBAACBAgSBFwpXwMKDwoIBAACBAicCAASA10EMAoPCggE
AAIECJwIARIDXgQqCqkDCgQEAAIFEgRpAm4EGpoDIE9wdGlvbmFsLiBUaGUgSUFNIHNlcnZp
Y2UgYWNjb3VudCBlbWFpbCBhc3NvY2lhdGVkIHdpdGggdGhlIHRyaWdnZXIuIFRoZQogc2Vy
dmljZSBhY2NvdW50IHJlcHJlc2VudHMgdGhlIGlkZW50aXR5IG9mIHRoZSB0cmlnZ2VyLgoK
IFRoZSBgaWFtLnNlcnZpY2VBY2NvdW50cy5hY3RBc2AgcGVybWlzc2lvbiBtdXN0IGJlIGdy
YW50ZWQgb24gdGhlIHNlcnZpY2UKIGFjY291bnQgdG8gYWxsb3cgYSBwcmluY2lwYWwgdG8g
aW1wZXJzb25hdGUgdGhlIHNlcnZpY2UgYWNjb3VudC4gRm9yIG1vcmUKIGluZm9ybWF0aW9u
LCBzZWUgdGhlCiBbUm9sZXMgYW5kIHBlcm1pc3Npb25zXSgvZXZlbnRhcmMvZG9jcy9hbGwt
cm9sZXMtcGVybWlzc2lvbnMpIHBhZ2Ugc3BlY2lmaWMKIHRvIHRoZSB0cmlnZ2VyIGRlc3Rp
bmF0aW9uLgoKDAoFBAACBQUSA2kCCAoMCgUEAAIFARIDaQkYCgwKBQQAAgUDEgNpGxwKDQoF
BAACBQgSBGkdbgMKDwoIBAACBQicCAASA2oEKgoPCgcEAAIFCJ8IEgRrBG0FClIKBAQAAgYS
A3ECSBpFIFJlcXVpcmVkLiBEZXN0aW5hdGlvbiBzcGVjaWZpZXMgd2hlcmUgdGhlIGV2ZW50
cyBzaG91bGQgYmUgc2VudCB0by4KCgwKBQQAAgYGEgNxAg0KDAoFBAACBgESA3EOGQoMCgUE
AAIGAxIDcRweCgwKBQQAAgYIEgNxH0cKDwoIBAACBgicCAASA3EgRgryAQoEBAACBxIDdwJE
GuQBIE9wdGlvbmFsLiBUbyBkZWxpdmVyIG1lc3NhZ2VzLCBFdmVudGFyYyBtaWdodCB1c2Ug
b3RoZXIgR29vZ2xlIENsb3VkCiBwcm9kdWN0cyBhcyBhIHRyYW5zcG9ydCBpbnRlcm1lZGlh
cnkuIFRoaXMgZmllbGQgY29udGFpbnMgYSByZWZlcmVuY2UgdG8KIHRoYXQgdHJhbnNwb3J0
IGludGVybWVkaWFyeS4gVGhpcyBpbmZvcm1hdGlvbiBjYW4gYmUgdXNlZCBmb3IgZGVidWdn
aW5nCiBwdXJwb3Nlcy4KCgwKBQQAAgcGEgN3AgsKDAoFBAACBwESA3cMFQoMCgUEAAIHAxID
dxgaCgwKBQQAAgcIEgN3G0MKDwoIBAACBwicCAASA3ccQgpjCgQEAAIIEgN7AksaViBPcHRp
b25hbC4gVXNlciBsYWJlbHMgYXR0YWNoZWQgdG8gdGhlIHRyaWdnZXJzIHRoYXQgY2FuIGJl
IHVzZWQgdG8gZ3JvdXAKIHJlc291cmNlcy4KCgwKBQQAAggGEgN7AhUKDAoFBAACCAESA3sW
HAoMCgUEAAIIAxIDex8hCgwKBQQAAggIEgN7IkoKDwoIBAACCAicCAASA3sjSQriAQoEBAAC
CRIEgAECPxrTASBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIGNoYW5uZWwgYXNzb2NpYXRl
ZCB3aXRoIHRoZSB0cmlnZ2VyIGluCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2NoYW5uZWxzL3tjaGFubmVsfWAgZm9ybWF0LgogWW91IG11c3QgcHJvdmlk
ZSBhIGNoYW5uZWwgdG8gcmVjZWl2ZSBldmVudHMgZnJvbSBFdmVudGFyYyBTYWFTIHBhcnRu
ZXJzLgoKDQoFBAACCQUSBIABAggKDQoFBAACCQESBIABCRAKDQoFBAACCQMSBIABExUKDQoF
BAACCQgSBIABFj4KEAoIBAACCQicCAASBIABFz0KTgoEBAACChIGgwEChAEyGj4gT3V0cHV0
IG9ubHkuIFRoZSByZWFzb24ocykgd2h5IGEgdHJpZ2dlciBpcyBpbiBGQUlMRUQgc3RhdGUu
CgoNCgUEAAIKBhIEgwECHQoNCgUEAAIKARIEgwEeKAoNCgUEAAIKAxIEgwErLQoNCgUEAAIK
CBIEhAEGMQoQCggEAAIKCJwIABIEhAEHMArOAQoEBAACCxIEiQECTxq/ASBPcHRpb25hbC4g
RXZlbnREYXRhQ29udGVudFR5cGUgc3BlY2lmaWVzIHRoZSB0eXBlIG9mIHBheWxvYWQgaW4g
TUlNRQogZm9ybWF0IHRoYXQgaXMgZXhwZWN0ZWQgZnJvbSB0aGUgQ2xvdWRFdmVudCBkYXRh
IGZpZWxkLiBUaGlzIGlzIHNldCB0bwogYGFwcGxpY2F0aW9uL2pzb25gIGlmIHRoZSB2YWx1
ZSBpcyBub3QgZGVmaW5lZC4KCg0KBQQAAgsFEgSJAQIICg0KBQQAAgsBEgSJAQkgCg0KBQQA
AgsDEgSJASMlCg0KBQQAAgsIEgSJASZOChAKCAQAAgsInAgAEgSJASdNCnAKBAQAAgwSBI0B
AkYaYiBPdXRwdXQgb25seS4gV2hldGhlciBvciBub3QgdGhpcyBUcmlnZ2VyIHNhdGlzZmll
cyB0aGUgcmVxdWlyZW1lbnRzIG9mCiBwaHlzaWNhbCB6b25lIHNlcGFyYXRpb24KCg0KBQQA
AgwFEgSNAQIGCg0KBQQAAgwBEgSNAQcUCg0KBQQAAgwDEgSNARcZCg0KBQQAAgwIEgSNARpF
ChAKCAQAAgwInAgAEgSNARtECsEBCgQEAAINEgSTAQJJGrIBIE9wdGlvbmFsLiBUaGUgcmV0
cnkgcG9saWN5IHRvIHVzZSBpbiB0aGUgVHJpZ2dlci4KCiBJZiB1bnNldCwgZXZlbnQgZGVs
aXZlcnkgd2lsbCBiZSByZXRyaWVkIGZvciB1cCB0byAyNCBob3VycyBieSBkZWZhdWx0Ogog
aHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2V2ZW50YXJjL2RvY3MvcmV0cnktZXZlbnRzCgoN
CgUEAAINBhIEkwECDQoNCgUEAAINARIEkwEOGgoNCgUEAAINAxIEkwEdHwoNCgUEAAINCBIE
kwEgSAoQCggEAAINCJwIABIEkwEhRwraAQoEBAACDhIEmAECPxrLASBPdXRwdXQgb25seS4g
VGhpcyBjaGVja3N1bSBpcyBjb21wdXRlZCBieSB0aGUgc2VydmVyIGJhc2VkIG9uIHRoZSB2
YWx1ZSBvZgogb3RoZXIgZmllbGRzLCBhbmQgbWlnaHQgYmUgc2VudCBvbmx5IG9uIGNyZWF0
ZSByZXF1ZXN0cyB0byBlbnN1cmUgdGhhdCB0aGUKIGNsaWVudCBoYXMgYW4gdXAtdG8tZGF0
ZSB2YWx1ZSBiZWZvcmUgcHJvY2VlZGluZy4KCg0KBQQAAg4FEgSYAQIICg0KBQQAAg4BEgSY
AQkNCg0KBQQAAg4DEgSYARASCg0KBQQAAg4IEgSYARM+ChAKCAQAAg4InAgAEgSYARQ9ClQK
AgQBEgacAQCuAQEaRiBGaWx0ZXJzIGV2ZW50cyBiYXNlZCBvbiBleGFjdCBtYXRjaGVzIG9u
IHRoZSBDbG91ZEV2ZW50cyBhdHRyaWJ1dGVzLgoKCwoDBAEBEgScAQgTCrYCCgQEAQIAEgSj
AQJAGqcCIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiBhIENsb3VkRXZlbnRzIGF0dHJpYnV0ZS4g
Q3VycmVudGx5LCBvbmx5IGEgc3Vic2V0IG9mCiBhdHRyaWJ1dGVzIGFyZSBzdXBwb3J0ZWQg
Zm9yIGZpbHRlcmluZy4gWW91IGNhbiBbcmV0cmlldmUgYSBzcGVjaWZpYwogcHJvdmlkZXIn
cyBzdXBwb3J0ZWQgZXZlbnQKIHR5cGVzXSgvZXZlbnRhcmMvZG9jcy9saXN0LXByb3ZpZGVy
cyNkZXNjcmliZS1wcm92aWRlcikuCgogQWxsIHRyaWdnZXJzIE1VU1QgcHJvdmlkZSBhIGZp
bHRlciBmb3IgdGhlICd0eXBlJyBhdHRyaWJ1dGUuCgoNCgUEAQIABRIEowECCAoNCgUEAQIA
ARIEowEJEgoNCgUEAQIAAxIEowEVFgoNCgUEAQIACBIEowEXPwoQCggEAQIACJwIABIEowEY
Pgo2CgQEAQIBEgSmAQI8GiggUmVxdWlyZWQuIFRoZSB2YWx1ZSBmb3IgdGhlIGF0dHJpYnV0
ZS4KCg0KBQQBAgEFEgSmAQIICg0KBQQBAgEBEgSmAQkOCg0KBQQBAgEDEgSmARESCg0KBQQB
AgEIEgSmARM7ChAKCAQBAgEInAgAEgSmARQ6Cr4CCgQEAQICEgStAQI/Gq8CIE9wdGlvbmFs
LiBUaGUgb3BlcmF0b3IgdXNlZCBmb3IgbWF0Y2hpbmcgdGhlIGV2ZW50cyB3aXRoIHRoZSB2
YWx1ZSBvZiB0aGUKIGZpbHRlci4gSWYgbm90IHNwZWNpZmllZCwgb25seSBldmVudHMgdGhh
dCBoYXZlIGFuIGV4YWN0IGtleS12YWx1ZSBwYWlyCiBzcGVjaWZpZWQgaW4gdGhlIGZpbHRl
ciBhcmUgbWF0Y2hlZC4gVGhlIGFsbG93ZWQgdmFsdWVzIGFyZSBgcGF0aF9wYXR0ZXJuYAog
YW5kIGBtYXRjaC1wYXRoLXBhdHRlcm5gLiBgcGF0aF9wYXR0ZXJuYCBpcyBvbmx5IGFsbG93
ZWQgZm9yIEdDRnYxCiB0cmlnZ2Vycy4KCg0KBQQBAgIFEgStAQIICg0KBQQBAgIBEgStAQkR
Cg0KBQQBAgIDEgStARQVCg0KBQQBAgIIEgStARY+ChAKCAQBAgIInAgAEgStARc9CkoKAgQC
EgaxAQC3AQEaPCBBIGNvbmRpdGlvbiB0aGF0IGlzIHBhcnQgb2YgdGhlIHRyaWdnZXIgc3Rh
dGUgY29tcHV0YXRpb24uCgoLCgMEAgESBLEBCBYKNAoEBAICABIEswECGxomIFRoZSBjYW5v
bmljYWwgY29kZSBvZiB0aGUgY29uZGl0aW9uLgoKDQoFBAICAAYSBLMBAhEKDQoFBAICAAES
BLMBEhYKDQoFBAICAAMSBLMBGRoKJwoEBAICARIEtgECFRoZIEh1bWFuLXJlYWRhYmxlIG1l
c3NhZ2UuCgoNCgUEAgIBBRIEtgECCAoNCgUEAgIBARIEtgEJEAoNCgUEAgIBAxIEtgETFAo/
CgIEAxIGugEA3wEBGjEgUmVwcmVzZW50cyBhIHRhcmdldCBvZiBhbiBpbnZvY2F0aW9uIG92
ZXIgSFRUUC4KCgsKAwQDARIEugEIEwoOCgQEAwgAEga7AQLZAQMKDQoFBAMIAAESBLsBCBIK
hgEKBAQDAgASBL4BBBsaeCBDbG91ZCBSdW4gZnVsbHktbWFuYWdlZCByZXNvdXJjZSB0aGF0
IHJlY2VpdmVzIHRoZSBldmVudHMuIFRoZSByZXNvdXJjZQogc2hvdWxkIGJlIGluIHRoZSBz
YW1lIHByb2plY3QgYXMgdGhlIHRyaWdnZXIuCgoNCgUEAwIABhIEvgEEDAoNCgUEAwIAARIE
vgENFgoNCgUEAwIAAxIEvgEZGgrXAgoEBAMCARIGxwEEyQEHGsYCIFRoZSBDbG91ZCBGdW5j
dGlvbiByZXNvdXJjZSBuYW1lLiBDbG91ZCBGdW5jdGlvbnMgVjEgYW5kIFYyIGFyZQogc3Vw
cG9ydGVkLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2Z1bmN0aW9ucy97ZnVuY3Rpb259YAoKIFRoaXMgaXMgYSByZWFkLW9ubHkgZmllbGQu
IENyZWF0aW5nIENsb3VkIEZ1bmN0aW9ucyBWMS9WMiB0cmlnZ2VycyBpcwogb25seSBzdXBw
b3J0ZWQgdmlhIHRoZSBDbG91ZCBGdW5jdGlvbnMgcHJvZHVjdC4gQW4gZXJyb3Igd2lsbCBi
ZSByZXR1cm5lZAogaWYgdGhlIHVzZXIgc2V0cyB0aGlzIHZhbHVlLgoKDQoFBAMCAQUSBMcB
BAoKDQoFBAMCAQESBMcBCxkKDQoFBAMCAQMSBMcBHB0KDwoFBAMCAQgSBscBHskBBgoRCgcE
AwIBCJ8IEgbHAR/JAQUKfQoEBAMCAhIEzQEEEBpvIEEgR0tFIHNlcnZpY2UgY2FwYWJsZSBv
ZiByZWNlaXZpbmcgZXZlbnRzLiBUaGUgc2VydmljZSBzaG91bGQgYmUgcnVubmluZwogaW4g
dGhlIHNhbWUgcHJvamVjdCBhcyB0aGUgdHJpZ2dlci4KCg0KBQQDAgIGEgTNAQQHCg0KBQQD
AgIBEgTNAQgLCg0KBQQDAgIDEgTNAQ4PCvkBCgQEAwIDEgbTAQTVAQca6AEgVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIFdvcmtmbG93IHdob3NlIEV4ZWN1dGlvbnMgYXJlIHRyaWdnZXJl
ZCBieQogdGhlIGV2ZW50cy4gVGhlIFdvcmtmbG93IHJlc291cmNlIHNob3VsZCBiZSBkZXBs
b3llZCBpbiB0aGUgc2FtZSBwcm9qZWN0CiBhcyB0aGUgdHJpZ2dlci4KIEZvcm1hdDogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS93b3JrZmxvd3Mve3dvcmtm
bG93fWAKCg0KBQQDAgMFEgTTAQQKCg0KBQQDAgMBEgTTAQsTCg0KBQQDAgMDEgTTARYXCg8K
BQQDAgMIEgbTARjVAQYKEQoHBAMCAwifCBIG0wEZ1QEFCkEKBAQDAgQSBNgBBCMaMyBBbiBI
VFRQIGVuZHBvaW50IGRlc3RpbmF0aW9uIGRlc2NyaWJlZCBieSBhbiBVUkkuCgoNCgUEAwIE
BhIE2AEEEAoNCgUEAwIEARIE2AERHgoNCgUEAwIEAxIE2AEhIgqxAQoEBAMCBRIE3gECTBqi
ASBPcHRpb25hbC4gTmV0d29yayBjb25maWcgaXMgdXNlZCB0byBjb25maWd1cmUgaG93IEV2
ZW50YXJjIHJlc29sdmVzIGFuZAogY29ubmVjdCB0byBhIGRlc3RpbmF0aW9uLgogVGhpcyBz
aG91bGQgb25seSBiZSB1c2VkIHdpdGggSHR0cEVuZHBvaW50IGRlc3RpbmF0aW9uIHR5cGUu
CgoNCgUEAwIFBhIE3gECDwoNCgUEAwIFARIE3gEQHgoNCgUEAwIFAxIE3gEhIgoNCgUEAwIF
CBIE3gEjSwoQCggEAwIFCJwIABIE3gEkSgpjCgIEBBIG4wEA6QEBGlUgUmVwcmVzZW50cyB0
aGUgdHJhbnNwb3J0IGludGVybWVkaWFyaWVzIGNyZWF0ZWQgZm9yIHRoZSB0cmlnZ2VyIHRv
CiBkZWxpdmVyIGV2ZW50cy4KCgsKAwQEARIE4wEIEQoOCgQEBAgAEgbkAQLoAQMKDQoFBAQI
AAESBOQBCBQKYQoEBAQCABIE5wEEFhpTIFRoZSBQdWIvU3ViIHRvcGljIGFuZCBzdWJzY3Jp
cHRpb24gdXNlZCBieSBFdmVudGFyYyBhcyBhIHRyYW5zcG9ydAogaW50ZXJtZWRpYXJ5LgoK
DQoFBAQCAAYSBOcBBAoKDQoFBAQCAAESBOcBCxEKDQoFBAQCAAMSBOcBFBUKMwoCBAUSBuwB
AIACARolIFJlcHJlc2VudHMgYSBDbG91ZCBSdW4gZGVzdGluYXRpb24uCgoLCgMEBQESBOwB
CBAK8gEKBAQFAgASBvIBAvUBBBrhASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIENsb3Vk
IFJ1biBzZXJ2aWNlIGJlaW5nIGFkZHJlc3NlZC4gU2VlCiBodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vcnVuL2RvY3MvcmVmZXJlbmNlL3Jlc3QvdjEvbmFtZXNwYWNlcy5zZXJ2aWNlcy4K
CiBPbmx5IHNlcnZpY2VzIGxvY2F0ZWQgaW4gdGhlIHNhbWUgcHJvamVjdCBhcyB0aGUgdHJp
Z2dlciBvYmplY3QKIGNhbiBiZSBhZGRyZXNzZWQuCgoNCgUEBQIABRIE8gECCAoNCgUEBQIA
ARIE8gEJEAoNCgUEBQIAAxIE8gETFAoPCgUEBQIACBIG8gEV9QEDChAKCAQFAgAInAgAEgTz
AQQqCg8KBwQFAgAInwgSBPQBBEwK7wEKBAQFAgESBPwBAjsa4AEgT3B0aW9uYWwuIFRoZSBy
ZWxhdGl2ZSBwYXRoIG9uIHRoZSBDbG91ZCBSdW4gc2VydmljZSB0aGUgZXZlbnRzIHNob3Vs
ZCBiZQogc2VudCB0by4KCiBUaGUgdmFsdWUgbXVzdCBjb25mb3JtIHRvIHRoZSBkZWZpbml0
aW9uIG9mIGEgVVJJIHBhdGggc2VnbWVudCAoc2VjdGlvbiAzLjMKIG9mIFJGQzIzOTYpLiBF
eGFtcGxlczogIi9yb3V0ZSIsICJyb3V0ZSIsICJyb3V0ZS9zdWJyb3V0ZSIuCgoNCgUEBQIB
BRIE/AECCAoNCgUEBQIBARIE/AEJDQoNCgUEBQIBAxIE/AEQEQoNCgUEBQIBCBIE/AESOgoQ
CggEBQIBCJwIABIE/AETOQpKCgQEBQICEgT/AQI9GjwgUmVxdWlyZWQuIFRoZSByZWdpb24g
dGhlIENsb3VkIFJ1biBzZXJ2aWNlIGlzIGRlcGxveWVkIGluLgoKDQoFBAUCAgUSBP8BAggK
DQoFBAUCAgESBP8BCQ8KDQoFBAUCAgMSBP8BEhMKDQoFBAUCAggSBP8BFDwKEAoIBAUCAgic
CAASBP8BFTsKLQoCBAYSBoMCAJoCARofIFJlcHJlc2VudHMgYSBHS0UgZGVzdGluYXRpb24u
CgoLCgMEBgESBIMCCAsKoAEKBAQGAgASBIYCAj4akQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9m
IHRoZSBjbHVzdGVyIHRoZSBHS0Ugc2VydmljZSBpcyBydW5uaW5nIGluLiBUaGUKIGNsdXN0
ZXIgbXVzdCBiZSBydW5uaW5nIGluIHRoZSBzYW1lIHByb2plY3QgYXMgdGhlIHRyaWdnZXIg
YmVpbmcgY3JlYXRlZC4KCg0KBQQGAgAFEgSGAgIICg0KBQQGAgABEgSGAgkQCg0KBQQGAgAD
EgSGAhMUCg0KBQQGAgAIEgSGAhU9ChAKCAQGAgAInAgAEgSGAhY8CvIBCgQEBgIBEgSMAgI/
GuMBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgR29vZ2xlIENvbXB1dGUgRW5naW5lIGlu
IHdoaWNoIHRoZSBjbHVzdGVyCiByZXNpZGVzLCB3aGljaCBjYW4gZWl0aGVyIGJlIGNvbXB1
dGUgem9uZSAoZm9yIGV4YW1wbGUsIHVzLWNlbnRyYWwxLWEpIGZvcgogdGhlIHpvbmFsIGNs
dXN0ZXJzIG9yIHJlZ2lvbiAoZm9yIGV4YW1wbGUsIHVzLWNlbnRyYWwxKSBmb3IgcmVnaW9u
YWwKIGNsdXN0ZXJzLgoKDQoFBAYCAQUSBIwCAggKDQoFBAYCAQESBIwCCREKDQoFBAYCAQMS
BIwCFBUKDQoFBAYCAQgSBIwCFj4KEAoIBAYCAQicCAASBIwCFz0KRgoEBAYCAhIEjwICQBo4
IFJlcXVpcmVkLiBUaGUgbmFtZXNwYWNlIHRoZSBHS0Ugc2VydmljZSBpcyBydW5uaW5nIGlu
LgoKDQoFBAYCAgUSBI8CAggKDQoFBAYCAgESBI8CCRIKDQoFBAYCAgMSBI8CFRYKDQoFBAYC
AggSBI8CFz8KEAoIBAYCAgicCAASBI8CGD4KMgoEBAYCAxIEkgICPhokIFJlcXVpcmVkLiBO
YW1lIG9mIHRoZSBHS0Ugc2VydmljZS4KCg0KBQQGAgMFEgSSAgIICg0KBQQGAgMBEgSSAgkQ
Cg0KBQQGAgMDEgSSAhMUCg0KBQQGAgMIEgSSAhU9ChAKCAQGAgMInAgAEgSSAhY8CukBCgQE
BgIEEgSZAgI7GtoBIE9wdGlvbmFsLiBUaGUgcmVsYXRpdmUgcGF0aCBvbiB0aGUgR0tFIHNl
cnZpY2UgdGhlIGV2ZW50cyBzaG91bGQgYmUgc2VudAogdG8uCgogVGhlIHZhbHVlIG11c3Qg
Y29uZm9ybSB0byB0aGUgZGVmaW5pdGlvbiBvZiBhIFVSSSBwYXRoIHNlZ21lbnQgKHNlY3Rp
b24gMy4zCiBvZiBSRkMyMzk2KS4gRXhhbXBsZXM6ICIvcm91dGUiLCAicm91dGUiLCAicm91
dGUvc3Vicm91dGUiLgoKDQoFBAYCBAUSBJkCAggKDQoFBAYCBAESBJkCCQ0KDQoFBAYCBAMS
BJkCEBEKDQoFBAYCBAgSBJkCEjoKEAoIBAYCBAicCAASBJkCEzkKLwoCBAcSBp0CAKsCARoh
IFJlcHJlc2VudHMgYSBQdWIvU3ViIHRyYW5zcG9ydC4KCgsKAwQHARIEnQIIDgrtAgoEBAcC
ABIEpQICPBreAiBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIFB1Yi9TdWIgdG9waWMgY3Jl
YXRlZCBhbmQgbWFuYWdlZCBieSBFdmVudGFyYyBhcwogYSB0cmFuc3BvcnQgZm9yIHRoZSBl
dmVudCBkZWxpdmVyeS4gRm9ybWF0OgogYHByb2plY3RzL3tQUk9KRUNUX0lEfS90b3BpY3Mv
e1RPUElDX05BTUV9YC4KCiBZb3UgY2FuIHNldCBhbiBleGlzdGluZyB0b3BpYyBmb3IgdHJp
Z2dlcnMgb2YgdGhlIHR5cGUKIGBnb29nbGUuY2xvdWQucHVic3ViLnRvcGljLnYxLm1lc3Nh
Z2VQdWJsaXNoZWRgLiBUaGUgdG9waWMgeW91IHByb3ZpZGUKIGhlcmUgaXMgbm90IGRlbGV0
ZWQgYnkgRXZlbnRhcmMgYXQgdHJpZ2dlciBkZWxldGlvbi4KCg0KBQQHAgAFEgSlAgIICg0K
BQQHAgABEgSlAgkOCg0KBQQHAgADEgSlAhESCg0KBQQHAgAIEgSlAhM7ChAKCAQHAgAInAgA
EgSlAhQ6Cs4BCgQEBwIBEgSqAgJGGr8BIE91dHB1dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGUg
UHViL1N1YiBzdWJzY3JpcHRpb24gY3JlYXRlZCBhbmQgbWFuYWdlZCBieQogRXZlbnRhcmMg
YXMgYSB0cmFuc3BvcnQgZm9yIHRoZSBldmVudCBkZWxpdmVyeS4gRm9ybWF0OgogYHByb2pl
Y3RzL3tQUk9KRUNUX0lEfS9zdWJzY3JpcHRpb25zL3tTVUJTQ1JJUFRJT05fTkFNRX1gLgoK
DQoFBAcCAQUSBKoCAggKDQoFBAcCAQESBKoCCRUKDQoFBAcCAQMSBKoCGBkKDQoFBAcCAQgS
BKoCGkUKEAoIBAcCAQicCAASBKoCG0QKNwoCBAgSBq4CALgCARopIFJlcHJlc2VudHMgYSBI
VFRQIGVuZHBvaW50IGRlc3RpbmF0aW9uLgoKCwoDBAgBEgSuAggUCoYDCgQECAIAEgS3AgI6
GvcCIFJlcXVpcmVkLiBUaGUgVVJJIG9mIHRoZSBIVFRQIGVuZHBvaW50LgoKIFRoZSB2YWx1
ZSBtdXN0IGJlIGEgUkZDMjM5NiBVUkkgc3RyaW5nLgogRXhhbXBsZXM6IGBodHRwOi8vMTAu
MTAuMTAuODo4MC9yb3V0ZWAsCiBgaHR0cDovL3N2Yy51cy1jZW50cmFsMS5wLmxvY2FsOjgw
ODAvYC4KIE9ubHkgSFRUUCBhbmQgSFRUUFMgcHJvdG9jb2xzIGFyZSBzdXBwb3J0ZWQuIFRo
ZSBob3N0IGNhbiBiZSBlaXRoZXIgYQogc3RhdGljIElQIGFkZHJlc3NhYmxlIGZyb20gdGhl
IFZQQyBzcGVjaWZpZWQgYnkgdGhlIG5ldHdvcmsgY29uZmlnLCBvcgogYW4gaW50ZXJuYWwg
RE5TIGhvc3RuYW1lIG9mIHRoZSBzZXJ2aWNlIHJlc29sdmFibGUgdmlhIENsb3VkIEROUy4K
Cg0KBQQIAgAFEgS3AgIICg0KBQQIAgABEgS3AgkMCg0KBQQIAgADEgS3Ag8QCg0KBQQIAgAI
EgS3AhE5ChAKCAQIAgAInAgAEgS3AhI4YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::Trigger::Trigger ===
    # Fields for Trigger
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: event_filters Type: 11 (.google.cloud.eventarc.v1.EventFilter)
    # Field: service_account Type: 9 ()
    # Field: destination Type: 11 (.google.cloud.eventarc.v1.Destination)
    # Field: transport Type: 11 (.google.cloud.eventarc.v1.Transport)
    # Field: labels Type: 11 (.google.cloud.eventarc.v1.Trigger.LabelsEntry)
    # Field: channel Type: 9 ()
    # Field: conditions Type: 11 (.google.cloud.eventarc.v1.Trigger.ConditionsEntry)
    # Field: event_data_content_type Type: 9 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: retry_policy Type: 11 (.google.cloud.eventarc.v1.Trigger.RetryPolicy)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Eventarc::V1::Trigger::EventFilter ===
    # Fields for EventFilter
    # Field: attribute Type: 9 ()
    # Field: value Type: 9 ()
    # Field: operator Type: 9 ()

# === Message: Google::Cloud::Eventarc::V1::Trigger::StateCondition ===
    # Fields for StateCondition
    # Field: code Type: 14 (.google.rpc.Code)
    # Field: message Type: 9 ()

# === Message: Google::Cloud::Eventarc::V1::Trigger::Destination ===
    # Fields for Destination
    # Field: cloud_run Type: 11 (.google.cloud.eventarc.v1.CloudRun)
    # Field: cloud_function Type: 9 ()
    # Field: gke Type: 11 (.google.cloud.eventarc.v1.GKE)
    # Field: workflow Type: 9 ()
    # Field: http_endpoint Type: 11 (.google.cloud.eventarc.v1.HttpEndpoint)
    # Field: network_config Type: 11 (.google.cloud.eventarc.v1.NetworkConfig)

# === Message: Google::Cloud::Eventarc::V1::Trigger::Transport ===
    # Fields for Transport
    # Field: pubsub Type: 11 (.google.cloud.eventarc.v1.Pubsub)

# === Message: Google::Cloud::Eventarc::V1::Trigger::CloudRun ===
    # Fields for CloudRun
    # Field: service Type: 9 ()
    # Field: path Type: 9 ()
    # Field: region Type: 9 ()

# === Message: Google::Cloud::Eventarc::V1::Trigger::GKE ===
    # Fields for GKE
    # Field: cluster Type: 9 ()
    # Field: location Type: 9 ()
    # Field: namespace Type: 9 ()
    # Field: service Type: 9 ()
    # Field: path Type: 9 ()

# === Message: Google::Cloud::Eventarc::V1::Trigger::Pubsub ===
    # Fields for Pubsub
    # Field: topic Type: 9 ()
    # Field: subscription Type: 9 ()

# === Message: Google::Cloud::Eventarc::V1::Trigger::HttpEndpoint ===
    # Fields for HttpEndpoint
    # Field: uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::Trigger - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/trigger.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::Trigger;

    my $msg = Google::Cloud::Eventarc::V1::Trigger::Trigger->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::Trigger::Trigger->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/trigger.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::Trigger::Trigger

A representation of the trigger resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the trigger. Must be unique within the
location of the project and must be in
`projects/{project}/locations/{location}/triggers/{trigger}` format.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server-assigned unique identifier for the trigger. The value
is a UUID4 string and guaranteed to remain unchanged until the resource is
deleted.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->event_filters() >> / C<< $msg->event_filters($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::EventFilter>)

Required. Unordered list. The list of filters that applies to event
attributes. Only events that match all the provided filters are sent to the
destination.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. The IAM service account email associated with the trigger. The
service account represents the identity of the trigger.

The `iam.serviceAccounts.actAs` permission must be granted on the service
account to allow a principal to impersonate the service account. For more
information, see the
[Roles and permissions](/eventarc/docs/all-roles-permissions) page specific
to the trigger destination.

=item * C<< $msg->destination() >> / C<< $msg->destination($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::Destination>)

Required. Destination specifies where the events should be sent to.

=item * C<< $msg->transport() >> / C<< $msg->transport($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::Transport>)

Optional. To deliver messages, Eventarc might use other Google Cloud
products as a transport intermediary. This field contains a reference to
that transport intermediary. This information can be used for debugging
purposes.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::Trigger::LabelsEntry>)

Optional. User labels attached to the triggers that can be used to group
resources.

=item * C<< $msg->channel() >> / C<< $msg->channel($value) >>

Type: C<String>

Optional. The name of the channel associated with the trigger in
`projects/{project}/locations/{location}/channels/{channel}` format.
You must provide a channel to receive events from Eventarc SaaS partners.

=item * C<< $msg->conditions() >> / C<< $msg->conditions($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::Trigger::ConditionsEntry>)

Output only. The reason(s) why a trigger is in FAILED state.

=item * C<< $msg->event_data_content_type() >> / C<< $msg->event_data_content_type($value) >>

Type: C<String>

Optional. EventDataContentType specifies the type of payload in MIME
format that is expected from the CloudEvent data field. This is set to
`application/json` if the value is not defined.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Whether or not this Trigger satisfies the requirements of
physical zone separation

=item * C<< $msg->retry_policy() >> / C<< $msg->retry_policy($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::Trigger::RetryPolicy>)

Optional. The retry policy to use in the Trigger.

If unset, event delivery will be retried for up to 24 hours by default:
https://cloud.google.com/eventarc/docs/retry-events

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. This checksum is computed by the server based on the value of
other fields, and might be sent only on create requests to ensure that the
client has an up-to-date value before proceeding.

=back

=head2 Google::Cloud::Eventarc::V1::Trigger::EventFilter

Filters events based on exact matches on the CloudEvents attributes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attribute() >> / C<< $msg->attribute($value) >>

Type: C<String>

Required. The name of a CloudEvents attribute. Currently, only a subset of
attributes are supported for filtering. You can [retrieve a specific
provider's supported event
types](/eventarc/docs/list-providers#describe-provider).

All triggers MUST provide a filter for the 'type' attribute.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

Required. The value for the attribute.

=item * C<< $msg->operator() >> / C<< $msg->operator($value) >>

Type: C<String>

Optional. The operator used for matching the events with the value of the
filter. If not specified, only events that have an exact key-value pair
specified in the filter are matched. The allowed values are `path_pattern`
and `match-path-pattern`. `path_pattern` is only allowed for GCFv1
triggers.

=back

=head2 Google::Cloud::Eventarc::V1::Trigger::StateCondition

A condition that is part of the trigger state computation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<Enum> (L<Google::Rpc::Code>)

The canonical code of the condition.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Human-readable message.

=back

=head2 Google::Cloud::Eventarc::V1::Trigger::Destination

Represents a target of an invocation over HTTP.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_run() >> / C<< $msg->cloud_run($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::CloudRun>)

Cloud Run fully-managed resource that receives the events. The resource
should be in the same project as the trigger.

=item * C<< $msg->cloud_function() >> / C<< $msg->cloud_function($value) >>

Type: C<String>

The Cloud Function resource name. Cloud Functions V1 and V2 are
supported.
Format: `projects/{project}/locations/{location}/functions/{function}`

This is a read-only field. Creating Cloud Functions V1/V2 triggers is
only supported via the Cloud Functions product. An error will be returned
if the user sets this value.

=item * C<< $msg->gke() >> / C<< $msg->gke($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::GKE>)

A GKE service capable of receiving events. The service should be running
in the same project as the trigger.

=item * C<< $msg->workflow() >> / C<< $msg->workflow($value) >>

Type: C<String>

The resource name of the Workflow whose Executions are triggered by
the events. The Workflow resource should be deployed in the same project
as the trigger.
Format: `projects/{project}/locations/{location}/workflows/{workflow}`

=item * C<< $msg->http_endpoint() >> / C<< $msg->http_endpoint($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::HttpEndpoint>)

An HTTP endpoint destination described by an URI.

=item * C<< $msg->network_config() >> / C<< $msg->network_config($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::NetworkConfig::NetworkConfig>)

Optional. Network config is used to configure how Eventarc resolves and
connect to a destination.
This should only be used with HttpEndpoint destination type.

=back

=head2 Google::Cloud::Eventarc::V1::Trigger::Transport

Represents the transport intermediaries created for the trigger to
deliver events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pubsub() >> / C<< $msg->pubsub($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Trigger::Pubsub>)

The Pub/Sub topic and subscription used by Eventarc as a transport
intermediary.

=back

=head2 Google::Cloud::Eventarc::V1::Trigger::CloudRun

Represents a Cloud Run destination.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

Required. The name of the Cloud Run service being addressed. See
https://cloud.google.com/run/docs/reference/rest/v1/namespaces.services.

Only services located in the same project as the trigger object
can be addressed.

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Optional. The relative path on the Cloud Run service the events should be
sent to.

The value must conform to the definition of a URI path segment (section 3.3
of RFC2396). Examples: "/route", "route", "route/subroute".

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

Required. The region the Cloud Run service is deployed in.

=back

=head2 Google::Cloud::Eventarc::V1::Trigger::GKE

Represents a GKE destination.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<String>

Required. The name of the cluster the GKE service is running in. The
cluster must be running in the same project as the trigger being created.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Required. The name of the Google Compute Engine in which the cluster
resides, which can either be compute zone (for example, us-central1-a) for
the zonal clusters or region (for example, us-central1) for regional
clusters.

=item * C<< $msg->namespace() >> / C<< $msg->namespace($value) >>

Type: C<String>

Required. The namespace the GKE service is running in.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

Required. Name of the GKE service.

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Optional. The relative path on the GKE service the events should be sent
to.

The value must conform to the definition of a URI path segment (section 3.3
of RFC2396). Examples: "/route", "route", "route/subroute".

=back

=head2 Google::Cloud::Eventarc::V1::Trigger::Pubsub

Represents a Pub/Sub transport.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic() >> / C<< $msg->topic($value) >>

Type: C<String>

Optional. The name of the Pub/Sub topic created and managed by Eventarc as
a transport for the event delivery. Format:
`projects/{PROJECT_ID}/topics/{TOPIC_NAME}`.

You can set an existing topic for triggers of the type
`google.cloud.pubsub.topic.v1.messagePublished`. The topic you provide
here is not deleted by Eventarc at trigger deletion.

=item * C<< $msg->subscription() >> / C<< $msg->subscription($value) >>

Type: C<String>

Output only. The name of the Pub/Sub subscription created and managed by
Eventarc as a transport for the event delivery. Format:
`projects/{PROJECT_ID}/subscriptions/{SUBSCRIPTION_NAME}`.

=back

=head2 Google::Cloud::Eventarc::V1::Trigger::HttpEndpoint

Represents a HTTP endpoint destination.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. The URI of the HTTP endpoint.

The value must be a RFC2396 URI string.
Examples: `http://10.10.10.8:80/route`,
`http://svc.us-central1.p.local:8080/`.
Only HTTP and HTTPS protocols are supported. The host can be either a
static IP addressable from the VPC specified by the network config, or
an internal DNS hostname of the service resolvable via Cloud DNS.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::Trigger::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
