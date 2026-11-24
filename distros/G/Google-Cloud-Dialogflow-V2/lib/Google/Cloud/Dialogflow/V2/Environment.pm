package Google::Cloud::Dialogflow::V2::Environment;

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
    eval { require Google::Cloud::Dialogflow::V2::AudioConfig };
    eval { require Google::Cloud::Dialogflow::V2::Fulfillment };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9lbnZpcm9ubWVudC5wcm90bxIaZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dv
b2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92
Mi9hdWRpb19jb25maWcucHJvdG8aLGdvb2dsZS9jbG91ZC9kaWFsb2dmbG93L3YyL2Z1bGZp
bGxtZW50LnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90
b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
ItsFCgtFbnZpcm9ubWVudBIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSJQoLZGVzY3JpcHRp
b24YAiABKAlCA+BBAVILZGVzY3JpcHRpb24STgoNYWdlbnRfdmVyc2lvbhgDIAEoCUIp4EEB
+kEjCiFkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1ZlcnNpb25SDGFnZW50VmVyc2lvbhJI
CgVzdGF0ZRgEIAEoDjItLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkVudmlyb25tZW50
LlN0YXRlQgPgQQNSBXN0YXRlEkAKC3VwZGF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEmwKF3RleHRfdG9fc3BlZWNoX3NldHRp
bmdzGAcgASgLMjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVGV4dFRvU3BlZWNoU2V0
dGluZ3NCA+BBAVIUdGV4dFRvU3BlZWNoU2V0dGluZ3MSTgoLZnVsZmlsbG1lbnQYCCABKAsy
Jy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5GdWxmaWxsbWVudEID4EEBUgtmdWxmaWxs
bWVudCJFCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgsKB1NUT1BQRUQQARILCgdM
T0FESU5HEAISCwoHUlVOTklORxADOqoB6kGmAQolZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNv
bS9FbnZpcm9ubWVudBIzcHJvamVjdHMve3Byb2plY3R9L2FnZW50L2Vudmlyb25tZW50cy97
ZW52aXJvbm1lbnR9Ekhwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
YWdlbnQvZW52aXJvbm1lbnRzL3tlbnZpcm9ubWVudH0i+gMKFFRleHRUb1NwZWVjaFNldHRp
bmdzEjYKFWVuYWJsZV90ZXh0X3RvX3NwZWVjaBgBIAEoCEID4EEBUhJlbmFibGVUZXh0VG9T
cGVlY2gSaAoVb3V0cHV0X2F1ZGlvX2VuY29kaW5nGAIgASgOMi8uZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjIuT3V0cHV0QXVkaW9FbmNvZGluZ0ID4EECUhNvdXRwdXRBdWRpb0VuY29k
aW5nEi8KEXNhbXBsZV9yYXRlX2hlcnR6GAMgASgFQgPgQQFSD3NhbXBsZVJhdGVIZXJ0ehKO
AQoZc3ludGhlc2l6ZV9zcGVlY2hfY29uZmlncxgEIAMoCzJNLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLlRleHRUb1NwZWVjaFNldHRpbmdzLlN5bnRoZXNpemVTcGVlY2hDb25maWdz
RW50cnlCA+BBAVIXc3ludGhlc2l6ZVNwZWVjaENvbmZpZ3MafgocU3ludGhlc2l6ZVNwZWVj
aENvbmZpZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRJICgV2YWx1ZRgCIAEoCzIyLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyLlN5bnRoZXNpemVTcGVlY2hDb25maWdSBXZhbHVlOgI4
ASKmAQoXTGlzdEVudmlyb25tZW50c1JlcXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScS
JWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vRW52aXJvbm1lbnRSBnBhcmVudBIgCglwYWdl
X3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglw
YWdlVG9rZW4ijwEKGExpc3RFbnZpcm9ubWVudHNSZXNwb25zZRJLCgxlbnZpcm9ubWVudHMY
ASADKAsyJy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5FbnZpcm9ubWVudFIMZW52aXJv
bm1lbnRzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJaChVHZXRF
bnZpcm9ubWVudFJlcXVlc3QSQQoEbmFtZRgBIAEoCUIt4EEC+kEnCiVkaWFsb2dmbG93Lmdv
b2dsZWFwaXMuY29tL0Vudmlyb25tZW50UgRuYW1lIt0BChhDcmVhdGVFbnZpcm9ubWVudFJl
cXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScSJWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5j
b20vRW52aXJvbm1lbnRSBnBhcmVudBJOCgtlbnZpcm9ubWVudBgCIAEoCzInLmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyLkVudmlyb25tZW50QgPgQQJSC2Vudmlyb25tZW50EioKDmVu
dmlyb25tZW50X2lkGAMgASgJQgPgQQJSDWVudmlyb25tZW50SWQihQIKGFVwZGF0ZUVudmly
b25tZW50UmVxdWVzdBJOCgtlbnZpcm9ubWVudBgBIAEoCzInLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLkVudmlyb25tZW50QgPgQQJSC2Vudmlyb25tZW50EkAKC3VwZGF0ZV9tYXNr
GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrElcK
J2FsbG93X2xvYWRfdG9fZHJhZnRfYW5kX2Rpc2NhcmRfY2hhbmdlcxgDIAEoCEID4EEBUiFh
bGxvd0xvYWRUb0RyYWZ0QW5kRGlzY2FyZENoYW5nZXMiXQoYRGVsZXRlRW52aXJvbm1lbnRS
ZXF1ZXN0EkEKBG5hbWUYASABKAlCLeBBAvpBJwolZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNv
bS9FbnZpcm9ubWVudFIEbmFtZSKrAQocR2V0RW52aXJvbm1lbnRIaXN0b3J5UmVxdWVzdBJF
CgZwYXJlbnQYASABKAlCLeBBAvpBJwolZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9FbnZp
cm9ubWVudFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiLBAgoSRW52aXJvbm1lbnRIaXN0b3J5
EhsKBnBhcmVudBgBIAEoCUID4EEDUgZwYXJlbnQSUwoHZW50cmllcxgCIAMoCzI0Lmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyLkVudmlyb25tZW50SGlzdG9yeS5FbnRyeUID4EEDUgdl
bnRyaWVzEisKD25leHRfcGFnZV90b2tlbhgDIAEoCUID4EEDUg1uZXh0UGFnZVRva2VuGosB
CgVFbnRyeRIjCg1hZ2VudF92ZXJzaW9uGAEgASgJUgxhZ2VudFZlcnNpb24SIAoLZGVzY3Jp
cHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEjsKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZTLLDAoMRW52aXJvbm1lbnRzEvQBChBM
aXN0RW52aXJvbm1lbnRzEjMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuTGlzdEVudmly
b25tZW50c1JlcXVlc3QaNC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5MaXN0RW52aXJv
bm1lbnRzUmVzcG9uc2UidYLT5JMCZhIqL3YyL3twYXJlbnQ9cHJvamVjdHMvKi9hZ2VudH0v
ZW52aXJvbm1lbnRzWjgSNi92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdl
bnR9L2Vudmlyb25tZW50c9pBBnBhcmVudBLaAQoOR2V0RW52aXJvbm1lbnQSMS5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52Mi5HZXRFbnZpcm9ubWVudFJlcXVlc3QaJy5nb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52Mi5FbnZpcm9ubWVudCJsgtPkkwJmEiovdjIve25hbWU9cHJvamVj
dHMvKi9hZ2VudC9lbnZpcm9ubWVudHMvKn1aOBI2L3YyL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRzLyp9EvwBChFDcmVhdGVFbnZpcm9ubWVudBI0
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNyZWF0ZUVudmlyb25tZW50UmVxdWVzdBon
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkVudmlyb25tZW50IocBgtPkkwKAASIqL3Yy
L3twYXJlbnQ9cHJvamVjdHMvKi9hZ2VudH0vZW52aXJvbm1lbnRzOgtlbnZpcm9ubWVudFpF
IjYvdjIve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FnZW50fS9lbnZpcm9ubWVu
dHM6C2Vudmlyb25tZW50EpQCChFVcGRhdGVFbnZpcm9ubWVudBI0Lmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyLlVwZGF0ZUVudmlyb25tZW50UmVxdWVzdBonLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyLkVudmlyb25tZW50Ip8BgtPkkwKYATI2L3YyL3tlbnZpcm9ubWVudC5u
YW1lPXByb2plY3RzLyovYWdlbnQvZW52aXJvbm1lbnRzLyp9OgtlbnZpcm9ubWVudFpRMkIv
djIve2Vudmlyb25tZW50Lm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hZ2VudC9lbnZp
cm9ubWVudHMvKn06C2Vudmlyb25tZW50Es8BChFEZWxldGVFbnZpcm9ubWVudBI0Lmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyLkRlbGV0ZUVudmlyb25tZW50UmVxdWVzdBoWLmdvb2ds
ZS5wcm90b2J1Zi5FbXB0eSJsgtPkkwJmKiovdjIve25hbWU9cHJvamVjdHMvKi9hZ2VudC9l
bnZpcm9ubWVudHMvKn1aOCo2L3YyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovYWdl
bnQvZW52aXJvbm1lbnRzLyp9EoQCChVHZXRFbnZpcm9ubWVudEhpc3RvcnkSOC5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52Mi5HZXRFbnZpcm9ubWVudEhpc3RvcnlSZXF1ZXN0Gi4uZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRW52aXJvbm1lbnRIaXN0b3J5IoABgtPkkwJ6EjQv
djIve3BhcmVudD1wcm9qZWN0cy8qL2FnZW50L2Vudmlyb25tZW50cy8qfS9oaXN0b3J5WkIS
QC92Mi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovYWdlbnQvZW52aXJvbm1lbnRz
Lyp9L2hpc3RvcnkaeMpBGWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb23SQVlodHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvZGlhbG9nZmxvd0KWAQoeY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyQhBFbnZpcm9ubWVudFByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9n
Zmxvdy9hcGl2Mi9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAhpHb29nbGUuQ2xv
dWQuRGlhbG9nZmxvdy5WMkroZgoHEgUOAJUDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJ
CgIDAxIDFQAjCgkKAgMEEgMWADcKCQoCAwUSAxcANgoJCgIDBhIDGAAlCgkKAgMHEgMZACoK
CQoCAwgSAxoAKQoICgEIEgMcADcKCQoCCCUSAxwANwoICgEIEgMdAFUKCQoCCAsSAx0AVQoI
CgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfADEKCQoCCAgSAx8AMQoICgEIEgMgADcKCQoC
CAESAyAANwoICgEIEgMhACAKCQoCCCQSAyEAIApaCgIGABIEJAB4ARpOIFNlcnZpY2UgZm9y
IG1hbmFnaW5nIFtFbnZpcm9ubWVudHNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkVu
dmlyb25tZW50XS4KCgoKAwYAARIDJAgUCgoKAwYAAxIDJQJBCgwKBQYAA5kIEgMlAkEKCwoD
BgADEgQmAigzCg0KBQYAA5oIEgQmAigzClgKBAYAAgASBCsCNAMaSiBSZXR1cm5zIHRoZSBs
aXN0IG9mIGFsbCBub24tZGVmYXVsdCBlbnZpcm9ubWVudHMgb2YgdGhlIHNwZWNpZmllZCBh
Z2VudC4KCgwKBQYAAgABEgMrBhYKDAoFBgACAAISAysXLgoMCgUGAAIAAxIDLA8nCg0KBQYA
AgAEEgQtBDIGChEKCQYAAgAEsMq8IhIELQQyBgoMCgUGAAIABBIDMwQ0Cg8KCAYAAgAEmwgA
EgMzBDQKOgoEBgACARIENwI+AxosIFJldHJpZXZlcyB0aGUgc3BlY2lmaWVkIGFnZW50IGVu
dmlyb25tZW50LgoKDAoFBgACAQESAzcGFAoMCgUGAAIBAhIDNxUqCgwKBQYAAgEDEgM3NUAK
DQoFBgACAQQSBDgEPQYKEQoJBgACAQSwyrwiEgQ4BD0GCi0KBAYAAgISBEECSgMaHyBDcmVh
dGVzIGFuIGFnZW50IGVudmlyb25tZW50LgoKDAoFBgACAgESA0EGFwoMCgUGAAICAhIDQRgw
CgwKBQYAAgIDEgNBO0YKDQoFBgACAgQSBEIESQYKEQoJBgACAgSwyrwiEgRCBEkGCu8FCgQG
AAIDEgRYAmEDGuAFIFVwZGF0ZXMgdGhlIHNwZWNpZmllZCBhZ2VudCBlbnZpcm9ubWVudC4K
CiBUaGlzIG1ldGhvZCBhbGxvd3MgeW91IHRvIGRlcGxveSBuZXcgYWdlbnQgdmVyc2lvbnMg
aW50byB0aGUgZW52aXJvbm1lbnQuCiBXaGVuIGFuIGVudmlyb25tZW50IGlzIHBvaW50ZWQg
dG8gYSBuZXcgYWdlbnQgdmVyc2lvbiBieSBzZXR0aW5nCiBgZW52aXJvbm1lbnQuYWdlbnRf
dmVyc2lvbmAsIHRoZSBlbnZpcm9ubWVudCBpcyB0ZW1wb3JhcmlseSBzZXQgdG8gdGhlCiBg
TE9BRElOR2Agc3RhdGUuIER1cmluZyB0aGF0IHRpbWUsIHRoZSBlbnZpcm9ubWVudCBjb250
aW51ZXMgc2VydmluZyB0aGUKIHByZXZpb3VzIHZlcnNpb24gb2YgdGhlIGFnZW50LiBBZnRl
ciB0aGUgbmV3IGFnZW50IHZlcnNpb24gaXMgZG9uZSBsb2FkaW5nLAogdGhlIGVudmlyb25t
ZW50IGlzIHNldCBiYWNrIHRvIHRoZSBgUlVOTklOR2Agc3RhdGUuCiBZb3UgY2FuIHVzZSAi
LSIgYXMgRW52aXJvbm1lbnQgSUQgaW4gZW52aXJvbm1lbnQgbmFtZSB0byB1cGRhdGUgYW4g
YWdlbnQKIHZlcnNpb24gaW4gdGhlIGRlZmF1bHQgZW52aXJvbm1lbnQuIFdBUk5JTkc6IHRo
aXMgd2lsbCBuZWdhdGUgYWxsIHJlY2VudAogY2hhbmdlcyB0byB0aGUgZHJhZnQgYWdlbnQg
YW5kIGNhbid0IGJlIHVuZG9uZS4gWW91IG1heSB3YW50IHRvIHNhdmUgdGhlCiBkcmFmdCBh
Z2VudCB0byBhIHZlcnNpb24gYmVmb3JlIGNhbGxpbmcgdGhpcyBtZXRob2QuCgoMCgUGAAID
ARIDWAYXCgwKBQYAAgMCEgNYGDAKDAoFBgACAwMSA1g7RgoNCgUGAAIDBBIEWQRgBgoRCgkG
AAIDBLDKvCISBFkEYAYKOAoEBgACBBIEZAJsAxoqIERlbGV0ZXMgdGhlIHNwZWNpZmllZCBh
Z2VudCBlbnZpcm9ubWVudC4KCgwKBQYAAgQBEgNkBhcKDAoFBgACBAISA2QYMAoMCgUGAAIE
AxIDZQ8kCg0KBQYAAgQEEgRmBGsGChEKCQYAAgQEsMq8IhIEZgRrBgo+CgQGAAIFEgRvAncD
GjAgR2V0cyB0aGUgaGlzdG9yeSBvZiB0aGUgc3BlY2lmaWVkIGVudmlyb25tZW50LgoKDAoF
BgACBQESA28GGwoMCgUGAAIFAhIDbxw4CgwKBQYAAgUDEgNwDyEKDQoFBgACBQQSBHEEdgYK
EQoJBgACBQSwyrwiEgRxBHYGCpYFCgIEABIGjAEA0AEBGocFIFlvdSBjYW4gY3JlYXRlIG11
bHRpcGxlIHZlcnNpb25zIG9mIHlvdXIgYWdlbnQgYW5kIHB1Ymxpc2ggdGhlbSB0byBzZXBh
cmF0ZQogZW52aXJvbm1lbnRzLgoKIFdoZW4geW91IGVkaXQgYW4gYWdlbnQsIHlvdSBhcmUg
ZWRpdGluZyB0aGUgZHJhZnQgYWdlbnQuIEF0IGFueSBwb2ludCwgeW91CiBjYW4gc2F2ZSB0
aGUgZHJhZnQgYWdlbnQgYXMgYW4gYWdlbnQgdmVyc2lvbiwgd2hpY2ggaXMgYW4gaW1tdXRh
YmxlIHNuYXBzaG90CiBvZiB5b3VyIGFnZW50LgoKIFdoZW4geW91IHNhdmUgdGhlIGRyYWZ0
IGFnZW50LCBpdCBpcyBwdWJsaXNoZWQgdG8gdGhlIGRlZmF1bHQgZW52aXJvbm1lbnQuCiBX
aGVuIHlvdSBjcmVhdGUgYWdlbnQgdmVyc2lvbnMsIHlvdSBjYW4gcHVibGlzaCB0aGVtIHRv
IGN1c3RvbSBlbnZpcm9ubWVudHMuCiBZb3UgY2FuIGNyZWF0ZSBhIHZhcmlldHkgb2YgY3Vz
dG9tIGVudmlyb25tZW50cyBmb3I6CgogLSB0ZXN0aW5nCiAtIGRldmVsb3BtZW50CiAtIHBy
b2R1Y3Rpb24KIC0gZXRjLgoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUgdGhlIFt2ZXJz
aW9ucyBhbmQgZW52aXJvbm1lbnRzCiBndWlkZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29t
L2RpYWxvZ2Zsb3cvZG9jcy9hZ2VudHMtdmVyc2lvbnMpLgoKCwoDBAABEgSMAQgTCg0KAwQA
BxIGjQECkQEECg8KBQQAB50IEgaNAQKRAQQK4AIKBAQABAASBpgBAqQBAxrPAiBSZXByZXNl
bnRzIGFuIGVudmlyb25tZW50IHN0YXRlLiBXaGVuIGFuIGVudmlyb25tZW50IGlzIHBvaW50
ZWQgdG8gYSBuZXcKIGFnZW50IHZlcnNpb24sIHRoZSBlbnZpcm9ubWVudCBpcyB0ZW1wb3Jh
cmlseSBzZXQgdG8gdGhlIGBMT0FESU5HYCBzdGF0ZS4KIER1cmluZyB0aGF0IHRpbWUsIHRo
ZSBlbnZpcm9ubWVudCBrZWVwcyBvbiBzZXJ2aW5nIHRoZSBwcmV2aW91cyB2ZXJzaW9uIG9m
CiB0aGUgYWdlbnQuIEFmdGVyIHRoZSBuZXcgYWdlbnQgdmVyc2lvbiBpcyBkb25lIGxvYWRp
bmcsIHRoZSBlbnZpcm9ubWVudCBpcwogc2V0IGJhY2sgdG8gdGhlIGBSVU5OSU5HYCBzdGF0
ZS4KCg0KBQQABAABEgSYAQcMCjgKBgQABAACABIEmgEEGhooIE5vdCBzcGVjaWZpZWQuIFRo
aXMgdmFsdWUgaXMgbm90IHVzZWQuCgoPCgcEAAQAAgABEgSaAQQVCg8KBwQABAACAAISBJoB
GBkKGgoGBAAEAAIBEgSdAQQQGgogU3RvcHBlZC4KCg8KBwQABAACAQESBJ0BBAsKDwoHBAAE
AAIBAhIEnQEODwoaCgYEAAQAAgISBKABBBAaCiBMb2FkaW5nLgoKDwoHBAAEAAICARIEoAEE
CwoPCgcEAAQAAgICEgSgAQ4PChoKBgQABAACAxIEowEEEBoKIFJ1bm5pbmcuCgoPCgcEAAQA
AgMBEgSjAQQLCg8KBwQABAACAwISBKMBDg8KtQIKBAQAAgASBK4BAj4apgIgT3V0cHV0IG9u
bHkuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGlzIGFnZW50IGVudmlyb25tZW50Lgog
U3VwcG9ydGVkIGZvcm1hdHM6CgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vu
dmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+
L2xvY2F0aW9ucy88TG9jYXRpb24KICAgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJv
bm1lbnQgSUQ+YAoKIFRoZSBlbnZpcm9ubWVudCBJRCBmb3IgdGhlIGRlZmF1bHQgZW52aXJv
bm1lbnQgaXMgYC1gLgoKDQoFBAACAAUSBK4BAggKDQoFBAACAAESBK4BCQ0KDQoFBAACAAMS
BK4BEBEKDQoFBAACAAgSBK4BEj0KEAoIBAACAAicCAASBK4BEzwKoAEKBAQAAgESBLIBAkIa
kQEgT3B0aW9uYWwuIFRoZSBkZXZlbG9wZXItcHJvdmlkZWQgZGVzY3JpcHRpb24gZm9yIHRo
aXMgZW52aXJvbm1lbnQuCiBUaGUgbWF4aW11bSBsZW5ndGggaXMgNTAwIGNoYXJhY3RlcnMu
IElmIGV4Y2VlZGVkLCB0aGUgcmVxdWVzdCBpcyByZWplY3RlZC4KCg0KBQQAAgEFEgSyAQII
Cg0KBQQAAgEBEgSyAQkUCg0KBQQAAgEDEgSyARcYCg0KBQQAAgEIEgSyARlBChAKCAQAAgEI
nAgAEgSyARpACuoBCgQEAAICEga6AQK/AQQa2QEgT3B0aW9uYWwuIFRoZSBhZ2VudCB2ZXJz
aW9uIGxvYWRlZCBpbnRvIHRoaXMgZW52aXJvbm1lbnQuCiBTdXBwb3J0ZWQgZm9ybWF0czoK
CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvdmVyc2lvbnMvPFZlcnNpb24gSUQ+
YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+L2Fn
ZW50L3ZlcnNpb25zLzxWZXJzaW9uCiAgIElEPmAKCg0KBQQAAgIFEgS6AQIICg0KBQQAAgIB
EgS6AQkWCg0KBQQAAgIDEgS6ARkaCg8KBQQAAgIIEga6ARu/AQMKEAoIBAACAgicCAASBLsB
BCoKEQoHBAACAgifCBIGvAEEvgEFCooBCgQEAAIDEgTDAQI+GnwgT3V0cHV0IG9ubHkuIFRo
ZSBzdGF0ZSBvZiB0aGlzIGVudmlyb25tZW50LiBUaGlzIGZpZWxkIGlzIHJlYWQtb25seSwg
aS5lLiwKIGl0IGNhbm5vdCBiZSBzZXQgYnkgY3JlYXRlIGFuZCB1cGRhdGUgbWV0aG9kcy4K
Cg0KBQQAAgMGEgTDAQIHCg0KBQQAAgMBEgTDAQgNCg0KBQQAAgMDEgTDARARCg0KBQQAAgMI
EgTDARI9ChAKCAQAAgMInAgAEgTDARM8CpgBCgQEAAIEEgbHAQLIATIahwEgT3V0cHV0IG9u
bHkuIFRoZSBsYXN0IHVwZGF0ZSB0aW1lIG9mIHRoaXMgZW52aXJvbm1lbnQuIFRoaXMgZmll
bGQgaXMKIHJlYWQtb25seSwgaS5lLiwgaXQgY2Fubm90IGJlIHNldCBieSBjcmVhdGUgYW5k
IHVwZGF0ZSBtZXRob2RzLgoKDQoFBAACBAYSBMcBAhsKDQoFBAACBAESBMcBHCcKDQoFBAAC
BAMSBMcBKisKDQoFBAACBAgSBMgBBjEKEAoIBAACBAicCAASBMgBBzAKSQoEBAACBRIGywEC
zAEvGjkgT3B0aW9uYWwuIFRleHQgdG8gc3BlZWNoIHNldHRpbmdzIGZvciB0aGlzIGVudmly
b25tZW50LgoKDQoFBAACBQYSBMsBAhYKDQoFBAACBQESBMsBFy4KDQoFBAACBQMSBMsBMTIK
DQoFBAACBQgSBMwBBi4KEAoIBAACBQicCAASBMwBBy0KTwoEBAACBhIEzwECRxpBIE9wdGlv
bmFsLiBUaGUgZnVsZmlsbG1lbnQgc2V0dGluZ3MgdG8gdXNlIGZvciB0aGlzIGVudmlyb25t
ZW50LgoKDQoFBAACBgYSBM8BAg0KDQoFBAACBgESBM8BDhkKDQoFBAACBgMSBM8BHB0KDQoF
BAACBggSBM8BHkYKEAoIBAACBgicCAASBM8BH0UKXQoCBAESBtMBAOgBARpPIEluc3RydWN0
cyB0aGUgc3BlZWNoIHN5bnRoZXNpemVyIG9uIGhvdyB0byBnZW5lcmF0ZSB0aGUgb3V0cHV0
IGF1ZGlvIGNvbnRlbnQuCgoLCgMEAQESBNMBCBwKmAEKBAQBAgASBNYBAkoaiQEgT3B0aW9u
YWwuIEluZGljYXRlcyB3aGV0aGVyIHRleHQgdG8gc3BlZWNoIGlzIGVuYWJsZWQuIEV2ZW4g
d2hlbiB0aGlzIGZpZWxkCiBpcyBmYWxzZSwgb3RoZXIgc2V0dGluZ3MgaW4gdGhpcyBwcm90
byBhcmUgc3RpbGwgcmV0YWluZWQuCgoNCgUEAQIABRIE1gECBgoNCgUEAQIAARIE1gEHHAoN
CgUEAQIAAxIE1gEfIAoNCgUEAQIACBIE1gEhSQoQCggEAQIACJwIABIE1gEiSApMCgQEAQIB
EgbZAQLaAS8aPCBSZXF1aXJlZC4gQXVkaW8gZW5jb2Rpbmcgb2YgdGhlIHN5bnRoZXNpemVk
IGF1ZGlvIGNvbnRlbnQuCgoNCgUEAQIBBhIE2QECFQoNCgUEAQIBARIE2QEWKwoNCgUEAQIB
AxIE2QEuLwoNCgUEAQIBCBIE2gEGLgoQCggEAQIBCJwIABIE2gEHLQr1AgoEBAECAhIE4QEC
RxrmAiBPcHRpb25hbC4gVGhlIHN5bnRoZXNpcyBzYW1wbGUgcmF0ZSAoaW4gaGVydHopIGZv
ciB0aGlzIGF1ZGlvLiBJZiBub3QKIHByb3ZpZGVkLCB0aGVuIHRoZSBzeW50aGVzaXplciB3
aWxsIHVzZSB0aGUgZGVmYXVsdCBzYW1wbGUgcmF0ZSBiYXNlZCBvbgogdGhlIGF1ZGlvIGVu
Y29kaW5nLiBJZiB0aGlzIGlzIGRpZmZlcmVudCBmcm9tIHRoZSB2b2ljZSdzIG5hdHVyYWwg
c2FtcGxlCiByYXRlLCB0aGVuIHRoZSBzeW50aGVzaXplciB3aWxsIGhvbm9yIHRoaXMgcmVx
dWVzdCBieSBjb252ZXJ0aW5nIHRvIHRoZQogZGVzaXJlZCBzYW1wbGUgcmF0ZSAod2hpY2gg
bWlnaHQgcmVzdWx0IGluIHdvcnNlIGF1ZGlvIHF1YWxpdHkpLgoKDQoFBAECAgUSBOEBAgcK
DQoFBAECAgESBOEBCBkKDQoFBAECAgMSBOEBHB0KDQoFBAECAggSBOEBHkYKEAoIBAECAgic
CAASBOEBH0UKwAEKBAQBAgMSBuYBAucBLxqvASBPcHRpb25hbC4gQ29uZmlndXJhdGlvbiBv
ZiBob3cgc3BlZWNoIHNob3VsZCBiZSBzeW50aGVzaXplZCwgbWFwcGluZyBmcm9tCiBsYW5n
dWFnZSAoaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvZG9jcy9yZWZlcmVu
Y2UvbGFuZ3VhZ2UpIHRvCiBTeW50aGVzaXplU3BlZWNoQ29uZmlnLgoKDQoFBAECAwYSBOYB
AiUKDQoFBAECAwESBOYBJj8KDQoFBAECAwMSBOYBQkMKDQoFBAECAwgSBOcBBi4KEAoIBAEC
AwicCAASBOcBBy0KgwEKAgQCEgbsAQD/AQEadSBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgog
W0Vudmlyb25tZW50cy5MaXN0RW52aXJvbm1lbnRzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5FbnZpcm9ubWVudHMuTGlzdEVudmlyb25tZW50c10uCgoLCgMEAgESBOwBCB8KqQEK
BAQCAgASBvIBAvcBBBqYASBSZXF1aXJlZC4gVGhlIGFnZW50IHRvIGxpc3QgYWxsIGVudmly
b25tZW50cyBmcm9tLgogRm9ybWF0OgoKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2Vu
dGAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9h
Z2VudGAKCg0KBQQCAgAFEgTyAQIICg0KBQQCAgABEgTyAQkPCg0KBQQCAgADEgTyARITCg8K
BQQCAgAIEgbyART3AQMKEAoIBAICAAicCAASBPMBBCoKEQoHBAICAAifCBIG9AEE9gEFCnMK
BAQCAgESBPsBAj8aZSBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRv
IHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeQogZGVmYXVsdCAxMDAgYW5kIGF0IG1vc3Qg
MTAwMC4KCg0KBQQCAgEFEgT7AQIHCg0KBQQCAgEBEgT7AQgRCg0KBQQCAgEDEgT7ARQVCg0K
BQQCAgEIEgT7ARY+ChAKCAQCAgEInAgAEgT7ARc9CloKBAQCAgISBP4BAkEaTCBPcHRpb25h
bC4gVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMg
bGlzdCByZXF1ZXN0LgoKDQoFBAICAgUSBP4BAggKDQoFBAICAgESBP4BCRMKDQoFBAICAgMS
BP4BFhcKDQoFBAICAggSBP4BGEAKEAoIBAICAgicCAASBP4BGT8KhAEKAgQDEgaDAgCLAgEa
diBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtFbnZpcm9ubWVudHMuTGlzdEVudmlyb25t
ZW50c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRW52aXJvbm1lbnRzLkxpc3RFbnZp
cm9ubWVudHNdLgoKCwoDBAMBEgSDAgggCo8BCgQEAwIAEgSGAgIoGoABIFRoZSBsaXN0IG9m
IGFnZW50IGVudmlyb25tZW50cy4gVGhlcmUgd2lsbCBiZSBhIG1heGltdW0gbnVtYmVyIG9m
IGl0ZW1zCiByZXR1cm5lZCBiYXNlZCBvbiB0aGUgcGFnZV9zaXplIGZpZWxkIGluIHRoZSBy
ZXF1ZXN0LgoKDQoFBAMCAAQSBIYCAgoKDQoFBAMCAAYSBIYCCxYKDQoFBAMCAAESBIYCFyMK
DQoFBAMCAAMSBIYCJicKbwoEBAMCARIEigICHRphIFRva2VuIHRvIHJldHJpZXZlIHRoZSBu
ZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBtb3JlIHJl
c3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUEAwIBBRIEigICCAoNCgUEAwIBARIEigIJGAoNCgUE
AwIBAxIEigIbHAp/CgIEBBIGjwIAngIBGnEgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtF
bnZpcm9ubWVudHMuR2V0RW52aXJvbm1lbnRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
LkVudmlyb25tZW50cy5HZXRFbnZpcm9ubWVudF0uCgoLCgMEBAESBI8CCB0KoAIKBAQEAgAS
BpgCAp0CBBqPAiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGVudmlyb25tZW50LgogU3Vw
cG9ydGVkIGZvcm1hdHM6CgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vudmly
b25tZW50cy88RW52aXJvbm1lbnQgSUQ+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xv
Y2F0aW9ucy88TG9jYXRpb24KICAgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1l
bnQgSUQ+YAoKIFRoZSBlbnZpcm9ubWVudCBJRCBmb3IgdGhlIGRlZmF1bHQgZW52aXJvbm1l
bnQgaXMgYC1gLgoKDQoFBAQCAAUSBJgCAggKDQoFBAQCAAESBJgCCQ0KDQoFBAQCAAMSBJgC
EBEKDwoFBAQCAAgSBpgCEp0CAwoQCggEBAIACJwIABIEmQIEKgoRCgcEBAIACJ8IEgaaAgSc
AgUKhQEKAgQFEgaiAgC0AgEadyBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0Vudmlyb25t
ZW50cy5DcmVhdGVFbnZpcm9ubWVudF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRW52
aXJvbm1lbnRzLkNyZWF0ZUVudmlyb25tZW50XS4KCgsKAwQFARIEogIIIAqzAQoEBAUCABIG
qAICrQIEGqIBIFJlcXVpcmVkLiBUaGUgYWdlbnQgdG8gY3JlYXRlIGFuIGVudmlyb25tZW50
IGZvci4KIFN1cHBvcnRlZCBmb3JtYXRzOgoKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9h
Z2VudGAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElE
Pi9hZ2VudGAKCg0KBQQFAgAFEgSoAgIICg0KBQQFAgABEgSoAgkPCg0KBQQFAgADEgSoAhIT
Cg8KBQQFAgAIEgaoAhStAgMKEAoIBAUCAAicCAASBKkCBCoKEQoHBAUCAAifCBIGqgIErAIF
CjQKBAQFAgESBLACAkcaJiBSZXF1aXJlZC4gVGhlIGVudmlyb25tZW50IHRvIGNyZWF0ZS4K
Cg0KBQQFAgEGEgSwAgINCg0KBQQFAgEBEgSwAg4ZCg0KBQQFAgEDEgSwAhwdCg0KBQQFAgEI
EgSwAh5GChAKCAQFAgEInAgAEgSwAh9FCj8KBAQFAgISBLMCAkUaMSBSZXF1aXJlZC4gVGhl
IHVuaXF1ZSBpZCBvZiB0aGUgbmV3IGVudmlyb25tZW50LgoKDQoFBAUCAgUSBLMCAggKDQoF
BAUCAgESBLMCCRcKDQoFBAUCAgMSBLMCGhsKDQoFBAUCAggSBLMCHEQKEAoIBAUCAgicCAAS
BLMCHUMKhQEKAgQGEga4AgDGAgEadyBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0Vudmly
b25tZW50cy5VcGRhdGVFbnZpcm9ubWVudF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIu
RW52aXJvbm1lbnRzLlVwZGF0ZUVudmlyb25tZW50XS4KCgsKAwQGARIEuAIIIAo0CgQEBgIA
EgS6AgJHGiYgUmVxdWlyZWQuIFRoZSBlbnZpcm9ubWVudCB0byB1cGRhdGUuCgoNCgUEBgIA
BhIEugICDQoNCgUEBgIAARIEugIOGQoNCgUEBgIAAxIEugIcHQoNCgUEBgIACBIEugIeRgoQ
CggEBgIACJwIABIEugIfRQpJCgQEBgIBEga9AgK+Ai8aOSBSZXF1aXJlZC4gVGhlIG1hc2sg
dG8gY29udHJvbCB3aGljaCBmaWVsZHMgZ2V0IHVwZGF0ZWQuCgoNCgUEBgIBBhIEvQICGwoN
CgUEBgIBARIEvQIcJwoNCgUEBgIBAxIEvQIqKwoNCgUEBgIBCBIEvgIGLgoQCggEBgIBCJwI
ABIEvgIHLQq2AgoEBAYCAhIGxAICxQIvGqUCIE9wdGlvbmFsLiBUaGlzIGZpZWxkIGlzIHVz
ZWQgdG8gcHJldmVudCBhY2NpZGVudGFsIG92ZXJ3cml0ZSBvZiB0aGUgZGVmYXVsdAogZW52
aXJvbm1lbnQsIHdoaWNoIGlzIGFuIG9wZXJhdGlvbiB0aGF0IGNhbm5vdCBiZSB1bmRvbmUu
IFRvIGNvbmZpcm0gdGhhdAogdGhlIGNhbGxlciBkZXNpcmVzIHRoaXMgb3ZlcndyaXRlLCB0
aGlzIGZpZWxkIG11c3QgYmUgZXhwbGljaXRseSBzZXQgdG8KIHRydWUgd2hlbiB1cGRhdGlu
ZyB0aGUgZGVmYXVsdCBlbnZpcm9ubWVudCAoZW52aXJvbm1lbnQgSUQgPSBgLWApLgoKDQoF
BAYCAgUSBMQCAgYKDQoFBAYCAgESBMQCBy4KDQoFBAYCAgMSBMQCMTIKDQoFBAYCAggSBMUC
Bi4KEAoIBAYCAgicCAASBMUCBy0KhQEKAgQHEgbKAgDZAgEadyBUaGUgcmVxdWVzdCBtZXNz
YWdlIGZvcgogW0Vudmlyb25tZW50cy5EZWxldGVFbnZpcm9ubWVudF1bZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjIuRW52aXJvbm1lbnRzLkRlbGV0ZUVudmlyb25tZW50XS4KCgsKAwQH
ARIEygIIIAqhAgoEBAcCABIG0wIC2AIEGpACIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUg
ZW52aXJvbm1lbnQgdG8gZGVsZXRlLgogLyBGb3JtYXQ6CgogLSBgcHJvamVjdHMvPFByb2pl
Y3QgSUQ+L2FnZW50L2Vudmlyb25tZW50cy88RW52aXJvbm1lbnQgSUQ+YAogLSBgcHJvamVj
dHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24KICAgSUQ+L2FnZW50L2Vudmly
b25tZW50cy88RW52aXJvbm1lbnQgSUQ+YAoKIFRoZSBlbnZpcm9ubWVudCBJRCBmb3IgdGhl
IGRlZmF1bHQgZW52aXJvbm1lbnQgaXMgYC1gLgoKDQoFBAcCAAUSBNMCAggKDQoFBAcCAAES
BNMCCQ0KDQoFBAcCAAMSBNMCEBEKDwoFBAcCAAgSBtMCEtgCAwoQCggEBwIACJwIABIE1AIE
KgoRCgcEBwIACJ8IEgbVAgTXAgUKjQEKAgQIEgbdAgDzAgEafyBUaGUgcmVxdWVzdCBtZXNz
YWdlIGZvcgogW0Vudmlyb25tZW50cy5HZXRFbnZpcm9ubWVudEhpc3RvcnldW2dvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyLkVudmlyb25tZW50cy5HZXRFbnZpcm9ubWVudEhpc3Rvcnld
LgoKCwoDBAgBEgTdAggkCrgCCgQECAIAEgbmAgLrAgQapwIgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBlbnZpcm9ubWVudCB0byByZXRyaWV2ZSBoaXN0b3J5IGZvci4KIFN1cHBvcnRl
ZCBmb3JtYXRzOgoKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9lbnZpcm9ubWVu
dHMvPEVudmlyb25tZW50IElEPmAKIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlv
bnMvPExvY2F0aW9uCiAgIElEPi9hZ2VudC9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50IElE
PmAKCiBUaGUgZW52aXJvbm1lbnQgSUQgZm9yIHRoZSBkZWZhdWx0IGVudmlyb25tZW50IGlz
IGAtYC4KCg0KBQQIAgAFEgTmAgIICg0KBQQIAgABEgTmAgkPCg0KBQQIAgADEgTmAhITCg8K
BQQIAgAIEgbmAhTrAgMKEAoIBAgCAAicCAASBOcCBCoKEQoHBAgCAAifCBIG6AIE6gIFCnMK
BAQIAgESBO8CAj8aZSBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRv
IHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLiBCeQogZGVmYXVsdCAxMDAgYW5kIGF0IG1vc3Qg
MTAwMC4KCg0KBQQIAgEFEgTvAgIHCg0KBQQIAgEBEgTvAggRCg0KBQQIAgEDEgTvAhQVCg0K
BQQIAgEIEgTvAhY+ChAKCAQIAgEInAgAEgTvAhc9CloKBAQIAgISBPICAkEaTCBPcHRpb25h
bC4gVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMg
bGlzdCByZXF1ZXN0LgoKDQoFBAgCAgUSBPICAggKDQoFBAgCAgESBPICCRMKDQoFBAgCAgMS
BPICFhcKDQoFBAgCAggSBPICGEAKEAoIBAgCAgicCAASBPICGT8KjwEKAgQJEgb3AgCVAwEa
gAEgVGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbRW52aXJvbm1lbnRzLkdldEVudmlyb25t
ZW50SGlzdG9yeV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuRW52aXJvbm1lbnRzLkdl
dEVudmlyb25tZW50SGlzdG9yeV0uCgoLCgMECQESBPcCCBoKOgoEBAkDABIG+QICggMDGiog
UmVwcmVzZW50cyBhbiBlbnZpcm9ubWVudCBoaXN0b3J5IGVudHJ5LgoKDQoFBAkDAAESBPkC
Cg8KTwoGBAkDAAIAEgT7AgQdGj8gVGhlIGFnZW50IHZlcnNpb24gbG9hZGVkIGludG8gdGhp
cyBlbnZpcm9ubWVudCBoaXN0b3J5IGVudHJ5LgoKDwoHBAkDAAIABRIE+wIECgoPCgcECQMA
AgABEgT7AgsYCg8KBwQJAwACAAMSBPsCGxwKWAoGBAkDAAIBEgT+AgQbGkggVGhlIGRldmVs
b3Blci1wcm92aWRlZCBkZXNjcmlwdGlvbiBmb3IgdGhpcyBlbnZpcm9ubWVudCBoaXN0b3J5
IGVudHJ5LgoKDwoHBAkDAAIBBRIE/gIECgoPCgcECQMAAgEBEgT+AgsWCg8KBwQJAwACAQMS
BP4CGRoKRgoGBAkDAAICEgSBAwQuGjYgVGhlIGNyZWF0aW9uIHRpbWUgb2YgdGhpcyBlbnZp
cm9ubWVudCBoaXN0b3J5IGVudHJ5LgoKDwoHBAkDAAICBhIEgQMEHQoPCgcECQMAAgIBEgSB
Ax4pCg8KBwQJAwACAgMSBIEDLC0KtgIKBAQJAgASBIwDAkAapwIgT3V0cHV0IG9ubHkuIFRo
ZSBuYW1lIG9mIHRoZSBlbnZpcm9ubWVudCB0aGlzIGhpc3RvcnkgaXMgZm9yLgogU3VwcG9y
dGVkIGZvcm1hdHM6CgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2Vudmlyb25t
ZW50cy88RW52aXJvbm1lbnQgSUQ+YAogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0
aW9ucy88TG9jYXRpb24KICAgIElEPi9hZ2VudC9lbnZpcm9ubWVudHMvPEVudmlyb25tZW50
IElEPmAKCiBUaGUgZW52aXJvbm1lbnQgSUQgZm9yIHRoZSBkZWZhdWx0IGVudmlyb25tZW50
IGlzIGAtYC4KCg0KBQQJAgAFEgSMAwIICg0KBQQJAgABEgSMAwkPCg0KBQQJAgADEgSMAxIT
Cg0KBQQJAgAIEgSMAxQ/ChAKCAQJAgAInAgAEgSMAxU+CpwBCgQECQIBEgSQAwJJGo0BIE91
dHB1dCBvbmx5LiBUaGUgbGlzdCBvZiBhZ2VudCBlbnZpcm9ubWVudHMuIFRoZXJlIHdpbGwg
YmUgYSBtYXhpbXVtIG51bWJlcgogb2YgaXRlbXMgcmV0dXJuZWQgYmFzZWQgb24gdGhlIHBh
Z2Vfc2l6ZSBmaWVsZCBpbiB0aGUgcmVxdWVzdC4KCg0KBQQJAgEEEgSQAwIKCg0KBQQJAgEG
EgSQAwsQCg0KBQQJAgEBEgSQAxEYCg0KBQQJAgEDEgSQAxscCg0KBQQJAgEIEgSQAx1IChAK
CAQJAgEInAgAEgSQAx5HCnwKBAQJAgISBJQDAkkabiBPdXRwdXQgb25seS4gVG9rZW4gdG8g
cmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZQog
YXJlIG5vIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQJAgIFEgSUAwIICg0KBQQJ
AgIBEgSUAwkYCg0KBQQJAgIDEgSUAxscCg0KBQQJAgIIEgSUAx1IChAKCAQJAgIInAgAEgSU
Ax5HYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Environment::Environment ===
    # Fields for Environment
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: agent_version Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dialogflow.v2.Environment.State)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: text_to_speech_settings Type: 11 (.google.cloud.dialogflow.v2.TextToSpeechSettings)
    # Field: fulfillment Type: 11 (.google.cloud.dialogflow.v2.Fulfillment)

# Enum: Environment::State
our $Environment_STATE_UNSPECIFIED = 0;
our $Environment_STOPPED = 1;
our $Environment_LOADING = 2;
our $Environment_RUNNING = 3;

# === Message: Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings ===
    # Fields for TextToSpeechSettings
    # Field: enable_text_to_speech Type: 8 ()
    # Field: output_audio_encoding Type: 14 (.google.cloud.dialogflow.v2.OutputAudioEncoding)
    # Field: sample_rate_hertz Type: 5 ()
    # Field: synthesize_speech_configs Type: 11 (.google.cloud.dialogflow.v2.TextToSpeechSettings.SynthesizeSpeechConfigsEntry)

# === Message: Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsRequest ===
    # Fields for ListEnvironmentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsResponse ===
    # Fields for ListEnvironmentsResponse
    # Field: environments Type: 11 (.google.cloud.dialogflow.v2.Environment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentRequest ===
    # Fields for GetEnvironmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Environment::CreateEnvironmentRequest ===
    # Fields for CreateEnvironmentRequest
    # Field: parent Type: 9 ()
    # Field: environment Type: 11 (.google.cloud.dialogflow.v2.Environment)
    # Field: environment_id Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Environment::UpdateEnvironmentRequest ===
    # Fields for UpdateEnvironmentRequest
    # Field: environment Type: 11 (.google.cloud.dialogflow.v2.Environment)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: allow_load_to_draft_and_discard_changes Type: 8 ()

# === Message: Google::Cloud::Dialogflow::V2::Environment::DeleteEnvironmentRequest ===
    # Fields for DeleteEnvironmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentHistoryRequest ===
    # Fields for GetEnvironmentHistoryRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory ===
    # Fields for EnvironmentHistory
    # Field: parent Type: 9 ()
    # Field: entries Type: 11 (.google.cloud.dialogflow.v2.EnvironmentHistory.Entry)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Dialogflow::V2::Environment::EnvironmentsClient ===
package Google::Cloud::Dialogflow::V2::Environment::EnvironmentsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::Environment::EnvironmentsClient

Client stub representing the remote C<Environments> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_environments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Environments',
        method         => 'ListEnvironments',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsResponse',
    });
}

sub get_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Environments',
        method         => 'GetEnvironment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Environment::Environment',
    });
}

sub create_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Environment::CreateEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Environments',
        method         => 'CreateEnvironment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Environment::Environment',
    });
}

sub update_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Environment::UpdateEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Environments',
        method         => 'UpdateEnvironment',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Environment::Environment',
    });
}

sub delete_environment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Environment::DeleteEnvironmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Environments',
        method         => 'DeleteEnvironment',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_environment_history {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentHistoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.Environments',
        method         => 'GetEnvironmentHistory',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Environment - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/environment.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Environment;

    my $msg = Google::Cloud::Dialogflow::V2::Environment::Environment->new({
        name => $name,
        description => $description,
        agent_version => $agent_version,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Environment::Environment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/environment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Environment::Environment

You can create multiple versions of your agent and publish them to separate
environments.

When you edit an agent, you are editing the draft agent. At any point, you
can save the draft agent as an agent version, which is an immutable snapshot
of your agent.

When you save the draft agent, it is published to the default environment.
When you create agent versions, you can publish them to custom environments.
You can create a variety of custom environments for:

- testing
- development
- production
- etc.

For more information, see the [versions and environments
guide](https://cloud.google.com/dialogflow/docs/agents-versions).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique identifier of this agent environment.
Supported formats:

- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>`

The environment ID for the default environment is `-`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The developer-provided description for this environment.
The maximum length is 500 characters. If exceeded, the request is rejected.

=item * C<< $msg->agent_version() >> / C<< $msg->agent_version($value) >>

Type: C<String>

Optional. The agent version loaded into this environment.
Supported formats:

- `projects/<Project ID>/agent/versions/<Version ID>`
- `projects/<Project ID>/locations/<Location ID>/agent/versions/<Version
  ID>`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::Environment::State>)

Output only. The state of this environment. This field is read-only, i.e.,
it cannot be set by create and update methods.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update time of this environment. This field is
read-only, i.e., it cannot be set by create and update methods.

=item * C<< $msg->text_to_speech_settings() >> / C<< $msg->text_to_speech_settings($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings>)

Optional. Text to speech settings for this environment.

=item * C<< $msg->fulfillment() >> / C<< $msg->fulfillment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment>)

Optional. The fulfillment settings to use for this environment.

=back

=head3 Enum: Environment::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STOPPED> => C<1>

=item * C<LOADING> => C<2>

=item * C<RUNNING> => C<3>

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings

Instructs the speech synthesizer on how to generate the output audio content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_text_to_speech() >> / C<< $msg->enable_text_to_speech($value) >>

Type: C<Bool>

Optional. Indicates whether text to speech is enabled. Even when this field
is false, other settings in this proto are still retained.

=item * C<< $msg->output_audio_encoding() >> / C<< $msg->output_audio_encoding($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::OutputAudioEncoding>)

Required. Audio encoding of the synthesized audio content.

=item * C<< $msg->sample_rate_hertz() >> / C<< $msg->sample_rate_hertz($value) >>

Type: C<Int32>

Optional. The synthesis sample rate (in hertz) for this audio. If not
provided, then the synthesizer will use the default sample rate based on
the audio encoding. If this is different from the voice's natural sample
rate, then the synthesizer will honor this request by converting to the
desired sample rate (which might result in worse audio quality).

=item * C<< $msg->synthesize_speech_configs() >> / C<< $msg->synthesize_speech_configs($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings::SynthesizeSpeechConfigsEntry>)

Optional. Configuration of how speech should be synthesized, mapping from
language (https://cloud.google.com/dialogflow/docs/reference/language) to
SynthesizeSpeechConfig.

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsRequest

The request message for
[Environments.ListEnvironments][google.cloud.dialogflow.v2.Environments.ListEnvironments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to list all environments from.
Format:

- `projects/<Project ID>/agent`
- `projects/<Project ID>/locations/<Location ID>/agent`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsResponse

The response message for
[Environments.ListEnvironments][google.cloud.dialogflow.v2.Environments.ListEnvironments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->environments() >> / C<< $msg->environments($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Environment::Environment>)

The list of agent environments. There will be a maximum number of items
returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentRequest

The request message for
[Environments.GetEnvironment][google.cloud.dialogflow.v2.Environments.GetEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the environment.
Supported formats:

- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>`

The environment ID for the default environment is `-`.

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::CreateEnvironmentRequest

The request message for
[Environments.CreateEnvironment][google.cloud.dialogflow.v2.Environments.CreateEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The agent to create an environment for.
Supported formats:

- `projects/<Project ID>/agent`
- `projects/<Project ID>/locations/<Location ID>/agent`

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Environment::Environment>)

Required. The environment to create.

=item * C<< $msg->environment_id() >> / C<< $msg->environment_id($value) >>

Type: C<String>

Required. The unique id of the new environment.

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::UpdateEnvironmentRequest

The request message for
[Environments.UpdateEnvironment][google.cloud.dialogflow.v2.Environments.UpdateEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->environment() >> / C<< $msg->environment($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Environment::Environment>)

Required. The environment to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated.

=item * C<< $msg->allow_load_to_draft_and_discard_changes() >> / C<< $msg->allow_load_to_draft_and_discard_changes($value) >>

Type: C<Bool>

Optional. This field is used to prevent accidental overwrite of the default
environment, which is an operation that cannot be undone. To confirm that
the caller desires this overwrite, this field must be explicitly set to
true when updating the default environment (environment ID = `-`).

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::DeleteEnvironmentRequest

The request message for
[Environments.DeleteEnvironment][google.cloud.dialogflow.v2.Environments.DeleteEnvironment].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the environment to delete.
/ Format:

- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>`

The environment ID for the default environment is `-`.

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentHistoryRequest

The request message for
[Environments.GetEnvironmentHistory][google.cloud.dialogflow.v2.Environments.GetEnvironmentHistory].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the environment to retrieve history for.
Supported formats:

- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
  ID>/agent/environments/<Environment ID>`

The environment ID for the default environment is `-`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory

The response message for
[Environments.GetEnvironmentHistory][google.cloud.dialogflow.v2.Environments.GetEnvironmentHistory].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Output only. The name of the environment this history is for.
Supported formats:

- `projects/<Project ID>/agent/environments/<Environment ID>`
- `projects/<Project ID>/locations/<Location
   ID>/agent/environments/<Environment ID>`

The environment ID for the default environment is `-`.

=item * C<< $msg->entries() >> / C<< $msg->entries($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory::Entry>)

Output only. The list of agent environments. There will be a maximum number
of items returned based on the page_size field in the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Output only. Token to retrieve the next page of results, or empty if there
are no more results in the list.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Environment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
