package Google::Cloud::Dialogflow::V2::ConversationDataset;

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
    eval { require Google::Cloud::Dialogflow::V2::Gcs };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9jb252ZXJzYXRpb25fZGF0YXNldC5wcm90
bxIaZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiRnb29nbGUvY2xvdWQvZGlh
bG9nZmxvdy92Mi9nY3MucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnBy
b3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8aF2dvb2dsZS9ycGMvc3RhdHVzLnByb3RvIjwKEENvbnZlcnNhdGlvbklu
Zm8SKAoNbGFuZ3VhZ2VfY29kZRgBIAEoCUID4EEBUgxsYW5ndWFnZUNvZGUiYAoLSW5wdXRD
b25maWcSRwoKZ2NzX3NvdXJjZRgBIAEoCzImLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
Lkdjc1NvdXJjZXNIAFIJZ2NzU291cmNlQggKBnNvdXJjZSKxBQoTQ29udmVyc2F0aW9uRGF0
YXNldBIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPg
QQJSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPgQQFSC2Rlc2NyaXB0aW9u
EkAKC2NyZWF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
UgpjcmVhdGVUaW1lEk8KDGlucHV0X2NvbmZpZxgFIAEoCzInLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLklucHV0Q29uZmlnQgPgQQNSC2lucHV0Q29uZmlnEl4KEWNvbnZlcnNhdGlv
bl9pbmZvGAYgASgLMiwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29udmVyc2F0aW9u
SW5mb0ID4EEDUhBjb252ZXJzYXRpb25JbmZvEjIKEmNvbnZlcnNhdGlvbl9jb3VudBgHIAEo
A0ID4EEDUhFjb252ZXJzYXRpb25Db3VudBItCg1zYXRpc2ZpZXNfcHppGAggASgIQgPgQQNI
AFIMc2F0aXNmaWVzUHppiAEBEi0KDXNhdGlzZmllc19wenMYCSABKAhCA+BBA0gBUgxzYXRp
c2ZpZXNQenOIAQE6iAHqQYQBCi1kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbnZlcnNh
dGlvbkRhdGFzZXQSU3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9j
b252ZXJzYXRpb25EYXRhc2V0cy97Y29udmVyc2F0aW9uX2RhdGFzZXR9QhAKDl9zYXRpc2Zp
ZXNfcHppQhAKDl9zYXRpc2ZpZXNfcHpzIqgBCiBDcmVhdGVDb252ZXJzYXRpb25EYXRhc2V0
UmVxdWVzdBIbCgZwYXJlbnQYASABKAlCA+BBAlIGcGFyZW50EmcKFGNvbnZlcnNhdGlvbl9k
YXRhc2V0GAIgASgLMi8uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29udmVyc2F0aW9u
RGF0YXNldEID4EECUhNjb252ZXJzYXRpb25EYXRhc2V0ImoKHUdldENvbnZlcnNhdGlvbkRh
dGFzZXRSZXF1ZXN0EkkKBG5hbWUYASABKAlCNeBBAvpBLwotZGlhbG9nZmxvdy5nb29nbGVh
cGlzLmNvbS9Db252ZXJzYXRpb25EYXRhc2V0UgRuYW1lIrYBCh9MaXN0Q29udmVyc2F0aW9u
RGF0YXNldHNSZXF1ZXN0Ek0KBnBhcmVudBgBIAEoCUI14EEC+kEvEi1kaWFsb2dmbG93Lmdv
b2dsZWFwaXMuY29tL0NvbnZlcnNhdGlvbkRhdGFzZXRSBnBhcmVudBIgCglwYWdlX3NpemUY
AiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9r
ZW4isAEKIExpc3RDb252ZXJzYXRpb25EYXRhc2V0c1Jlc3BvbnNlEmQKFWNvbnZlcnNhdGlv
bl9kYXRhc2V0cxgBIAMoCzIvLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNvbnZlcnNh
dGlvbkRhdGFzZXRSFGNvbnZlcnNhdGlvbkRhdGFzZXRzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbiJtCiBEZWxldGVDb252ZXJzYXRpb25EYXRhc2V0UmVxdWVz
dBJJCgRuYW1lGAEgASgJQjXgQQL6QS8KLWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vQ29u
dmVyc2F0aW9uRGF0YXNldFIEbmFtZSK7AQodSW1wb3J0Q29udmVyc2F0aW9uRGF0YVJlcXVl
c3QSSQoEbmFtZRgBIAEoCUI14EEC+kEvCi1kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0Nv
bnZlcnNhdGlvbkRhdGFzZXRSBG5hbWUSTwoMaW5wdXRfY29uZmlnGAIgASgLMicuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIuSW5wdXRDb25maWdCA+BBAlILaW5wdXRDb25maWcijAIK
J0ltcG9ydENvbnZlcnNhdGlvbkRhdGFPcGVyYXRpb25NZXRhZGF0YRJlChRjb252ZXJzYXRp
b25fZGF0YXNldBgBIAEoCUIy+kEvCi1kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL0NvbnZl
cnNhdGlvbkRhdGFzZXRSE2NvbnZlcnNhdGlvbkRhdGFzZXQSPQoQcGFydGlhbF9mYWlsdXJl
cxgCIAMoCzISLmdvb2dsZS5ycGMuU3RhdHVzUg9wYXJ0aWFsRmFpbHVyZXMSOwoLY3JlYXRl
X3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lIrMB
CidJbXBvcnRDb252ZXJzYXRpb25EYXRhT3BlcmF0aW9uUmVzcG9uc2USZQoUY29udmVyc2F0
aW9uX2RhdGFzZXQYASABKAlCMvpBLwotZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Db252
ZXJzYXRpb25EYXRhc2V0UhNjb252ZXJzYXRpb25EYXRhc2V0EiEKDGltcG9ydF9jb3VudBgD
IAEoBVILaW1wb3J0Q291bnQikwEKKkNyZWF0ZUNvbnZlcnNhdGlvbkRhdGFzZXRPcGVyYXRp
b25NZXRhZGF0YRJlChRjb252ZXJzYXRpb25fZGF0YXNldBgBIAEoCUIy+kEvCi1kaWFsb2dm
bG93Lmdvb2dsZWFwaXMuY29tL0NvbnZlcnNhdGlvbkRhdGFzZXRSE2NvbnZlcnNhdGlvbkRh
dGFzZXQiLAoqRGVsZXRlQ29udmVyc2F0aW9uRGF0YXNldE9wZXJhdGlvbk1ldGFkYXRhMtYM
ChRDb252ZXJzYXRpb25EYXRhc2V0cxKzAgoZQ3JlYXRlQ29udmVyc2F0aW9uRGF0YXNldBI8
Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkNyZWF0ZUNvbnZlcnNhdGlvbkRhdGFzZXRS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiK4AYLT5JMCUCI4L3YyL3tw
YXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vY29udmVyc2F0aW9uRGF0YXNldHM6FGNv
bnZlcnNhdGlvbl9kYXRhc2V02kEbcGFyZW50LGNvbnZlcnNhdGlvbl9kYXRhc2V0ykFBChND
b252ZXJzYXRpb25EYXRhc2V0EipDcmVhdGVDb252ZXJzYXRpb25EYXRhc2V0T3BlcmF0aW9u
TWV0YWRhdGES/QEKFkdldENvbnZlcnNhdGlvbkRhdGFzZXQSOS5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52Mi5HZXRDb252ZXJzYXRpb25EYXRhc2V0UmVxdWVzdBovLmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyLkNvbnZlcnNhdGlvbkRhdGFzZXQid4LT5JMCahIsL3YyL3tuYW1l
PXByb2plY3RzLyovY29udmVyc2F0aW9uRGF0YXNldHMvKn1aOhI4L3YyL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29udmVyc2F0aW9uRGF0YXNldHMvKn3aQQRuYW1lEpACChhM
aXN0Q29udmVyc2F0aW9uRGF0YXNldHMSOy5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5M
aXN0Q29udmVyc2F0aW9uRGF0YXNldHNSZXF1ZXN0GjwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cudjIuTGlzdENvbnZlcnNhdGlvbkRhdGFzZXRzUmVzcG9uc2UieYLT5JMCahIsL3YyL3tw
YXJlbnQ9cHJvamVjdHMvKn0vY29udmVyc2F0aW9uRGF0YXNldHNaOhI4L3YyL3twYXJlbnQ9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vY29udmVyc2F0aW9uRGF0YXNldHPaQQZwYXJlbnQS
iAIKGURlbGV0ZUNvbnZlcnNhdGlvbkRhdGFzZXQSPC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5EZWxldGVDb252ZXJzYXRpb25EYXRhc2V0UmVxdWVzdBodLmdvb2dsZS5sb25ncnVu
bmluZy5PcGVyYXRpb24ijQGC0+STAjoqOC92Mi97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2NvbnZlcnNhdGlvbkRhdGFzZXRzLyp92kEEbmFtZcpBQwoVZ29vZ2xlLnByb3RvYnVm
LkVtcHR5EipEZWxldGVDb252ZXJzYXRpb25EYXRhc2V0T3BlcmF0aW9uTWV0YWRhdGES7wIK
FkltcG9ydENvbnZlcnNhdGlvbkRhdGESOS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5J
bXBvcnRDb252ZXJzYXRpb25EYXRhUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVy
YXRpb24i+gGC0+STAp4BIkMvdjIve25hbWU9cHJvamVjdHMvKi9jb252ZXJzYXRpb25EYXRh
c2V0cy8qfTppbXBvcnRDb252ZXJzYXRpb25EYXRhOgEqWlQiTy92Mi97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2NvbnZlcnNhdGlvbkRhdGFzZXRzLyp9OmltcG9ydENvbnZlcnNh
dGlvbkRhdGE6ASrKQVIKJ0ltcG9ydENvbnZlcnNhdGlvbkRhdGFPcGVyYXRpb25SZXNwb25z
ZRInSW1wb3J0Q29udmVyc2F0aW9uRGF0YU9wZXJhdGlvbk1ldGFkYXRhGnjKQRlkaWFsb2dm
bG93Lmdvb2dsZWFwaXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
bG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zs
b3dCngEKHmNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MkIYQ29udmVyc2F0aW9uRGF0
YXNldFByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2Mi9kaWFs
b2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAhpHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5W
Mkr1VwoHEgUOANcCNQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAIwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgME
EgMWAC4KCQoCAwUSAxcALQoJCgIDBhIDGAAlCgkKAgMHEgMZACkKCQoCAwgSAxoAIQoICgEI
EgMcADcKCQoCCCUSAxwANwoICgEIEgMdAFUKCQoCCAsSAx0AVQoICgEIEgMeACIKCQoCCAoS
Ax4AIgoICgEIEgMfADkKCQoCCAgSAx8AOQoICgEIEgMgADcKCQoCCAESAyAANwoICgEIEgMh
ACAKCQoCCCQSAyEAIAqjAQoCBgASBScAjgEBGpUBIENvbnZlcnNhdGlvbiBkYXRhc2V0cy4K
CiBDb252ZXJzYXRpb24gZGF0YXNldHMgY29udGFpbiByYXcgY29udmVyc2F0aW9uIGZpbGVz
IGFuZCB0aGVpcgogY3VzdG9taXphYmxlIG1ldGFkYXRhIHRoYXQgY2FuIGJlIHVzZWQgZm9y
IG1vZGVsIHRyYWluaW5nLgoKCgoDBgABEgMnCBwKCgoDBgADEgMoAkEKDAoFBgADmQgSAygC
QQoLCgMGAAMSBCkCKzMKDQoFBgADmggSBCkCKzMKzwMKBAYAAgASBDcCQgMawAMgQ3JlYXRl
cyBhIG5ldyBjb252ZXJzYXRpb24gZGF0YXNldC4KCiBUaGlzIG1ldGhvZCBpcyBhIFtsb25n
LXJ1bm5pbmcKIG9wZXJhdGlvbl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zs
b3cvZXMvZG9jcy9ob3cvbG9uZy1ydW5uaW5nLW9wZXJhdGlvbnMpLgogVGhlIHJldHVybmVk
IGBPcGVyYXRpb25gIHR5cGUgaGFzIHRoZSBmb2xsb3dpbmcgbWV0aG9kLXNwZWNpZmljIGZp
ZWxkczoKCiAtIGBtZXRhZGF0YWA6CiBbQ3JlYXRlQ29udmVyc2F0aW9uRGF0YXNldE9wZXJh
dGlvbk1ldGFkYXRhXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5DcmVhdGVDb252ZXJz
YXRpb25EYXRhc2V0T3BlcmF0aW9uTWV0YWRhdGFdCiAtIGByZXNwb25zZWA6CiBbQ29udmVy
c2F0aW9uRGF0YXNldF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29udmVyc2F0aW9u
RGF0YXNldF0KCgwKBQYAAgABEgM3Bh8KDAoFBgACAAISAzcgQAoMCgUGAAIAAxIDOA8rCg0K
BQYAAgAEEgQ5BDwGChEKCQYAAgAEsMq8IhIEOQQ8BgoMCgUGAAIABBIDPQRJCg8KCAYAAgAE
mwgAEgM9BEkKDQoFBgACAAQSBD4EQQYKDwoHBgACAASZCBIEPgRBBgo9CgQGAAIBEgRFAk4D
Gi8gUmV0cmlldmVzIHRoZSBzcGVjaWZpZWQgY29udmVyc2F0aW9uIGRhdGFzZXQuCgoMCgUG
AAIBARIDRQYcCgwKBQYAAgECEgNFHToKDAoFBgACAQMSA0YPIgoNCgUGAAIBBBIERwRMBgoR
CgkGAAIBBLDKvCISBEcETAYKDAoFBgACAQQSA00EMgoPCggGAAIBBJsIABIDTQQyCmUKBAYA
AgISBFICWwMaVyBSZXR1cm5zIHRoZSBsaXN0IG9mIGFsbCBjb252ZXJzYXRpb24gZGF0YXNl
dHMgaW4gdGhlIHNwZWNpZmllZAogcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAICARID
UgYeCgwKBQYAAgICEgNSHz4KDAoFBgACAgMSA1MPLwoNCgUGAAICBBIEVARZBgoRCgkGAAIC
BLDKvCISBFQEWQYKDAoFBgACAgQSA1oENAoPCggGAAICBJsIABIDWgQ0CvsDCgQGAAIDEgRn
AnEDGuwDIERlbGV0ZXMgdGhlIHNwZWNpZmllZCBjb252ZXJzYXRpb24gZGF0YXNldC4KCiBU
aGlzIG1ldGhvZCBpcyBhIFtsb25nLXJ1bm5pbmcKIG9wZXJhdGlvbl0oaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvZXMvZG9jcy9ob3cvbG9uZy1ydW5uaW5nLW9wZXJh
dGlvbnMpLgogVGhlIHJldHVybmVkIGBPcGVyYXRpb25gIHR5cGUgaGFzIHRoZSBmb2xsb3dp
bmcgbWV0aG9kLXNwZWNpZmljIGZpZWxkczoKCiAtIGBtZXRhZGF0YWA6CiBbRGVsZXRlQ29u
dmVyc2F0aW9uRGF0YXNldE9wZXJhdGlvbk1ldGFkYXRhXVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52Mi5EZWxldGVDb252ZXJzYXRpb25EYXRhc2V0T3BlcmF0aW9uTWV0YWRhdGFdCiAt
IGByZXNwb25zZWA6IEFuIFtFbXB0eQogICBtZXNzYWdlXShodHRwczovL2RldmVsb3BlcnMu
Z29vZ2xlLmNvbS9wcm90b2NvbC1idWZmZXJzL2RvY3MvcmVmZXJlbmNlL2dvb2dsZS5wcm90
b2J1ZiNlbXB0eSkKCgwKBQYAAgMBEgNnBh8KDAoFBgACAwISA2cgQAoMCgUGAAIDAxIDaA8r
Cg0KBQYAAgMEEgRpBGsGChEKCQYAAgMEsMq8IhIEaQRrBgoMCgUGAAIDBBIDbAQyCg8KCAYA
AgMEmwgAEgNsBDIKDQoFBgACAwQSBG0EcAYKDwoHBgACAwSZCBIEbQRwBgrnBAoEBgACBBIF
fwKNAQMa1wQgSW1wb3J0IGRhdGEgaW50byB0aGUgc3BlY2lmaWVkIGNvbnZlcnNhdGlvbiBk
YXRhc2V0LiBOb3RlIHRoYXQgaXQKIGlzIG5vdCBhbGxvd2VkIHRvIGltcG9ydCBkYXRhIHRv
IGEgY29udmVyc2F0aW9uIGRhdGFzZXQgdGhhdAogYWxyZWFkeSBoYXMgZGF0YSBpbiBpdC4K
CiBUaGlzIG1ldGhvZCBpcyBhIFtsb25nLXJ1bm5pbmcKIG9wZXJhdGlvbl0oaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvZXMvZG9jcy9ob3cvbG9uZy1ydW5uaW5nLW9w
ZXJhdGlvbnMpLgogVGhlIHJldHVybmVkIGBPcGVyYXRpb25gIHR5cGUgaGFzIHRoZSBmb2xs
b3dpbmcgbWV0aG9kLXNwZWNpZmljIGZpZWxkczoKCiAtIGBtZXRhZGF0YWA6CiBbSW1wb3J0
Q29udmVyc2F0aW9uRGF0YU9wZXJhdGlvbk1ldGFkYXRhXVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52Mi5JbXBvcnRDb252ZXJzYXRpb25EYXRhT3BlcmF0aW9uTWV0YWRhdGFdCiAtIGBy
ZXNwb25zZWA6CiBbSW1wb3J0Q29udmVyc2F0aW9uRGF0YU9wZXJhdGlvblJlc3BvbnNlXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5JbXBvcnRDb252ZXJzYXRpb25EYXRhT3BlcmF0
aW9uUmVzcG9uc2VdCgoMCgUGAAIEARIDfwYcCgwKBQYAAgQCEgN/HToKDQoFBgACBAMSBIAB
DysKDwoFBgACBAQSBoEBBIgBBgoTCgkGAAIEBLDKvCISBoEBBIgBBgoPCgUGAAIEBBIGiQEE
jAEGChEKBwYAAgQEmQgSBokBBIwBBgo2CgIEABIGkQEAlgEBGiggUmVwcmVzZW50cyBtZXRh
ZGF0YSBvZiBhIGNvbnZlcnNhdGlvbi4KCgsKAwQAARIEkQEIGArJAQoEBAACABIElQECRBq6
ASBPcHRpb25hbC4gVGhlIGxhbmd1YWdlIGNvZGUgb2YgdGhlIGNvbnZlcnNhdGlvbiBkYXRh
IHdpdGhpbiB0aGlzIGRhdGFzZXQuCiBTZWUgaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2Fw
aXMvZGVzaWduL3N0YW5kYXJkX2ZpZWxkcyBmb3IgbW9yZQogaW5mb3JtYXRpb24uIFN1cHBv
cnRzIGFsbCBVVEYtOCBsYW5ndWFnZXMuCgoNCgUEAAIABRIElQECCAoNCgUEAAIAARIElQEJ
FgoNCgUEAAIAAxIElQEZGgoNCgUEAAIACBIElQEbQwoQCggEAAIACJwIABIElQEcQgpvCgIE
ARIGmgEAogEBGmEgUmVwcmVzZW50cyB0aGUgY29uZmlndXJhdGlvbiBvZiBpbXBvcnRpbmcg
YSBzZXQgb2YgY29udmVyc2F0aW9uIGZpbGVzIGluCiBHb29nbGUgQ2xvdWQgU3RvcmFnZS4K
CgsKAwQBARIEmgEIEwozCgQEAQgAEgacAQKhAQMaIyBSZXF1aXJlZC4gV2hlcmUgdGhlIGRh
dGEgaXMgZnJvbS4KCg0KBQQBCAABEgScAQgOCuQBCgQEAQIAEgSgAQQeGtUBIFRoZSBDbG91
ZCBTdG9yYWdlIFVSSSBoYXMgdGhlIGZvcm0gZ3M6Ly88R29vZ2xlIENsb3VkIFN0b3JhZ2Ug
YnVja2V0CiBuYW1lPi8vYWdlbnQqLmpzb24uIFdpbGRjYXJkcyBhcmUgYWxsb3dlZCBhbmQg
d2lsbCBiZSBleHBhbmRlZCBpbnRvIGFsbAogbWF0Y2hlZCBKU09OIGZpbGVzLCB3aGljaCB3
aWxsIGJlIHJlYWQgYXMgb25lIGNvbnZlcnNhdGlvbiBwZXIgZmlsZS4KCg0KBQQBAgAGEgSg
AQQOCg0KBQQBAgABEgSgAQ8ZCg0KBQQBAgADEgSgARwdCo0CCgIEAhIGqAEAzwEBGv4BIFJl
cHJlc2VudHMgYSBjb252ZXJzYXRpb24gZGF0YXNldCB0aGF0IGEgdXNlciBpbXBvcnRzIHJh
dyBkYXRhIGludG8uCiBUaGUgZGF0YSBpbnNpZGUgQ29udmVyc2F0aW9uRGF0YXNldCBjYW4g
bm90IGJlIGNoYW5nZWQgYWZ0ZXIKIEltcG9ydENvbnZlcnNhdGlvbkRhdGEgZmluaXNoZXMg
KGFuZCBjYWxsaW5nIEltcG9ydENvbnZlcnNhdGlvbkRhdGEgb24gYQogZGF0YXNldCB0aGF0
IGFscmVhZHkgaGFzIGRhdGEgaXMgbm90IGFsbG93ZWQpLgoKCwoDBAIBEgSoAQgbCg0KAwQC
BxIGqQECrAEECg8KBQQCB50IEgapAQKsAQQKqQEKBAQCAgASBLEBAj4amgEgT3V0cHV0IG9u
bHkuIENvbnZlcnNhdGlvbkRhdGFzZXQgcmVzb3VyY2UgbmFtZS4gRm9ybWF0OgogYHByb2pl
Y3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uCiBJRD4vY29udmVyc2F0aW9u
RGF0YXNldHMvPENvbnZlcnNhdGlvbiBEYXRhc2V0IElEPmAKCg0KBQQCAgAFEgSxAQIICg0K
BQQCAgABEgSxAQkNCg0KBQQCAgADEgSxARARCg0KBQQCAgAIEgSxARI9ChAKCAQCAgAInAgA
EgSxARM8Ck8KBAQCAgESBLQBAkMaQSBSZXF1aXJlZC4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0
aGUgZGF0YXNldC4gTWF4aW11bSBvZiA2NCBieXRlcy4KCg0KBQQCAgEFEgS0AQIICg0KBQQC
AgEBEgS0AQkVCg0KBQQCAgEDEgS0ARgZCg0KBQQCAgEIEgS0ARpCChAKCAQCAgEInAgAEgS0
ARtBClEKBAQCAgISBLcBAkIaQyBPcHRpb25hbC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBk
YXRhc2V0LiBNYXhpbXVtIG9mIDEwMDAwIGJ5dGVzLgoKDQoFBAICAgUSBLcBAggKDQoFBAIC
AgESBLcBCRQKDQoFBAICAgMSBLcBFxgKDQoFBAICAggSBLcBGUEKEAoIBAICAgicCAASBLcB
GkAKPQoEBAICAxIGugECuwEyGi0gT3V0cHV0IG9ubHkuIENyZWF0aW9uIHRpbWUgb2YgdGhp
cyBkYXRhc2V0LgoKDQoFBAICAwYSBLoBAhsKDQoFBAICAwESBLoBHCcKDQoFBAICAwMSBLoB
KisKDQoFBAICAwgSBLsBBjEKEAoIBAICAwicCAASBLsBBzAKVgoEBAICBBIEvgECSxpIIE91
dHB1dCBvbmx5LiBJbnB1dCBjb25maWd1cmF0aW9ucyBzZXQgZHVyaW5nIGNvbnZlcnNhdGlv
biBkYXRhIGltcG9ydC4KCg0KBQQCAgQGEgS+AQINCg0KBQQCAgQBEgS+AQ4aCg0KBQQCAgQD
EgS+AR0eCg0KBQQCAgQIEgS+AR9KChAKCAQCAgQInAgAEgS+ASBJCkwKBAQCAgUSBsEBAsIB
Mho8IE91dHB1dCBvbmx5LiBNZXRhZGF0YSBzZXQgZHVyaW5nIGNvbnZlcnNhdGlvbiBkYXRh
IGltcG9ydC4KCg0KBQQCAgUGEgTBAQISCg0KBQQCAgUBEgTBARMkCg0KBQQCAgUDEgTBASco
Cg0KBQQCAgUIEgTCAQYxChAKCAQCAgUInAgAEgTCAQcwCl0KBAQCAgYSBMYBAksaTyBPdXRw
dXQgb25seS4gVGhlIG51bWJlciBvZiBjb252ZXJzYXRpb25zIHRoaXMgY29udmVyc2F0aW9u
IGRhdGFzZXQKIGNvbnRhaW5zLgoKDQoFBAICBgUSBMYBAgcKDQoFBAICBgESBMYBCBoKDQoF
BAICBgMSBMYBHR4KDQoFBAICBggSBMYBH0oKEAoIBAICBgicCAASBMYBIEkKaAoEBAICBxIE
ygECThpaIE91dHB1dCBvbmx5LiBBIHJlYWQgb25seSBib29sZWFuIGZpZWxkIHJlZmxlY3Rp
bmcgWm9uZSBJc29sYXRpb24gc3RhdHVzIG9mCiB0aGUgZGF0YXNldC4KCg0KBQQCAgcEEgTK
AQIKCg0KBQQCAgcFEgTKAQsPCg0KBQQCAgcBEgTKARAdCg0KBQQCAgcDEgTKASAhCg0KBQQC
AgcIEgTKASJNChAKCAQCAgcInAgAEgTKASNMCmkKBAQCAggSBM4BAk4aWyBPdXRwdXQgb25s
eS4gQSByZWFkIG9ubHkgYm9vbGVhbiBmaWVsZCByZWZsZWN0aW5nIFpvbmUgU2VwYXJhdGlv
biBzdGF0dXMgb2YKIHRoZSBkYXRhc2V0LgoKDQoFBAICCAQSBM4BAgoKDQoFBAICCAUSBM4B
Cw8KDQoFBAICCAESBM4BEB0KDQoFBAICCAMSBM4BICEKDQoFBAICCAgSBM4BIk0KEAoIBAIC
CAicCAASBM4BI0wKpgEKAgQDEgbTAQDbAQEalwEgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IK
IFtDb252ZXJzYXRpb25EYXRhc2V0cy5DcmVhdGVDb252ZXJzYXRpb25EYXRhc2V0XVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db252ZXJzYXRpb25EYXRhc2V0cy5DcmVhdGVDb252
ZXJzYXRpb25EYXRhc2V0XS4KCgsKAwQDARIE0wEIKAqCAQoEBAMCABIE1gECPRp0IFJlcXVp
cmVkLiBUaGUgcHJvamVjdCB0byBjcmVhdGUgY29udmVyc2F0aW9uIGRhdGFzZXQgZm9yLiBG
b3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+
YAoKDQoFBAMCAAUSBNYBAggKDQoFBAMCAAESBNYBCQ8KDQoFBAMCAAMSBNYBEhMKDQoFBAMC
AAgSBNYBFDwKEAoIBAMCAAicCAASBNYBFTsKPwoEBAMCARIG2QEC2gEvGi8gUmVxdWlyZWQu
IFRoZSBjb252ZXJzYXRpb24gZGF0YXNldCB0byBjcmVhdGUuCgoNCgUEAwIBBhIE2QECFQoN
CgUEAwIBARIE2QEWKgoNCgUEAwIBAxIE2QEtLgoNCgUEAwIBCBIE2gEGLgoQCggEAwIBCJwI
ABIE2gEHLQqgAQoCBAQSBt8BAOkBARqRASBUaGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW0Nv
bnZlcnNhdGlvbkRhdGFzZXRzLkdldENvbnZlcnNhdGlvbkRhdGFzZXRdW2dvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyLkNvbnZlcnNhdGlvbkRhdGFzZXRzLkdldENvbnZlcnNhdGlvbkRh
dGFzZXRdLgoKCwoDBAQBEgTfAQglCqsBCgQEBAIAEgbjAQLoAQQamgEgUmVxdWlyZWQuIFRo
ZSBjb252ZXJzYXRpb24gZGF0YXNldCB0byByZXRyaWV2ZS4gRm9ybWF0OgogYHByb2plY3Rz
LzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uCiBJRD4vY29udmVyc2F0aW9uRGF0
YXNldHMvPENvbnZlcnNhdGlvbiBEYXRhc2V0IElEPmAKCg0KBQQEAgAFEgTjAQIICg0KBQQE
AgABEgTjAQkNCg0KBQQEAgADEgTjARARCg8KBQQEAgAIEgbjARLoAQMKEAoIBAQCAAicCAAS
BOQBBCoKEQoHBAQCAAifCBIG5QEE5wEFCqQBCgIEBRIG7QEA/QEBGpUBIFRoZSByZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbQ29udmVyc2F0aW9uRGF0YXNldHMuTGlzdENvbnZlcnNhdGlvbkRh
dGFzZXRzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db252ZXJzYXRpb25EYXRhc2V0
cy5MaXN0Q29udmVyc2F0aW9uRGF0YXNldHNdLgoKCwoDBAUBEgTtAQgnCpoBCgQEBQIAEgbw
AQL1AQQaiQEgUmVxdWlyZWQuIFRoZSBwcm9qZWN0IGFuZCBsb2NhdGlvbiBuYW1lIHRvIGxp
c3QgYWxsIGNvbnZlcnNhdGlvbiBkYXRhc2V0cwogZm9yLiBGb3JtYXQ6IGBwcm9qZWN0cy88
UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD5gCgoNCgUEBQIABRIE8AECCAoN
CgUEBQIAARIE8AEJDwoNCgUEBQIAAxIE8AESEwoPCgUEBQIACBIG8AEU9QEDChAKCAQFAgAI
nAgAEgTxAQQqChEKBwQFAgAInwgSBvIBBPQBBQp/CgQEBQIBEgT5AQI/GnEgT3B0aW9uYWwu
IE1heGltdW0gbnVtYmVyIG9mIGNvbnZlcnNhdGlvbiBkYXRhc2V0cyB0byByZXR1cm4gaW4g
YSBzaW5nbGUKIHBhZ2UuIEJ5IGRlZmF1bHQgMTAwIGFuZCBhdCBtb3N0IDEwMDAuCgoNCgUE
BQIBBRIE+QECBwoNCgUEBQIBARIE+QEIEQoNCgUEBQIBAxIE+QEUFQoNCgUEBQIBCBIE+QEW
PgoQCggEBQIBCJwIABIE+QEXPQpaCgQEBQICEgT8AQJBGkwgT3B0aW9uYWwuIFRoZSBuZXh0
X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGxpc3QgcmVxdWVz
dC4KCg0KBQQFAgIFEgT8AQIICg0KBQQFAgIBEgT8AQkTCg0KBQQFAgIDEgT8ARYXCg0KBQQF
AgIIEgT8ARhAChAKCAQFAgIInAgAEgT8ARk/CqUBCgIEBhIGgQIAiAIBGpYBIFRoZSByZXNw
b25zZSBtZXNzYWdlIGZvcgogW0NvbnZlcnNhdGlvbkRhdGFzZXRzLkxpc3RDb252ZXJzYXRp
b25EYXRhc2V0c11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29udmVyc2F0aW9uRGF0
YXNldHMuTGlzdENvbnZlcnNhdGlvbkRhdGFzZXRzXS4KCgsKAwQGARIEgQIIKAovCgQEBgIA
EgSDAgI5GiEgVGhlIGxpc3Qgb2YgZGF0YXNldHMgdG8gcmV0dXJuLgoKDQoFBAYCAAQSBIMC
AgoKDQoFBAYCAAYSBIMCCx4KDQoFBAYCAAESBIMCHzQKDQoFBAYCAAMSBIMCNzgKegoEBAYC
ARIEhwICHRpsIFRoZSB0b2tlbiB0byB1c2UgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBv
ZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZQogYXJlIG5vIG1vcmUgcmVzdWx0cyBpbiB0
aGUgbGlzdC4KCg0KBQQGAgEFEgSHAgIICg0KBQQGAgEBEgSHAgkYCg0KBQQGAgEDEgSHAhsc
CqYBCgIEBxIGjAIAlgIBGpcBIFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbQ29udmVyc2F0
aW9uRGF0YXNldHMuRGVsZXRlQ29udmVyc2F0aW9uRGF0YXNldF1bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjIuQ29udmVyc2F0aW9uRGF0YXNldHMuRGVsZXRlQ29udmVyc2F0aW9uRGF0
YXNldF0uCgoLCgMEBwESBIwCCCgKqQEKBAQHAgASBpACApUCBBqYASBSZXF1aXJlZC4gVGhl
IGNvbnZlcnNhdGlvbiBkYXRhc2V0IHRvIGRlbGV0ZS4gRm9ybWF0OgogYHByb2plY3RzLzxQ
cm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uCiBJRD4vY29udmVyc2F0aW9uRGF0YXNl
dHMvPENvbnZlcnNhdGlvbiBEYXRhc2V0IElEPmAKCg0KBQQHAgAFEgSQAgIICg0KBQQHAgAB
EgSQAgkNCg0KBQQHAgADEgSQAhARCg8KBQQHAgAIEgaQAhKVAgMKEAoIBAcCAAicCAASBJEC
BCoKEQoHBAcCAAifCBIGkgIElAIFCqABCgIECBIGmgIApwIBGpEBIFRoZSByZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbQ29udmVyc2F0aW9uRGF0YXNldHMuSW1wb3J0Q29udmVyc2F0aW9uRGF0
YV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29udmVyc2F0aW9uRGF0YXNldHMuSW1w
b3J0Q29udmVyc2F0aW9uRGF0YV0uCgoLCgMECAESBJoCCCUKnAEKBAQIAgASBp4CAqMCBBqL
ASBSZXF1aXJlZC4gRGF0YXNldCByZXNvdXJjZSBuYW1lLiBGb3JtYXQ6CiBgcHJvamVjdHMv
PFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRpb24KIElEPi9jb252ZXJzYXRpb25EYXRh
c2V0cy88Q29udmVyc2F0aW9uIERhdGFzZXQgSUQ+YAoKDQoFBAgCAAUSBJ4CAggKDQoFBAgC
AAESBJ4CCQ0KDQoFBAgCAAMSBJ4CEBEKDwoFBAgCAAgSBp4CEqMCAwoQCggECAIACJwIABIE
nwIEKgoRCgcECAIACJ8IEgagAgSiAgUKTQoEBAgCARIEpgICSBo/IFJlcXVpcmVkLiBDb25m
aWd1cmF0aW9uIGRlc2NyaWJpbmcgd2hlcmUgdG8gaW1wb3J0IGRhdGEgZnJvbS4KCg0KBQQI
AgEGEgSmAgINCg0KBQQIAgEBEgSmAg4aCg0KBQQIAgEDEgSmAh0eCg0KBQQIAgEIEgSmAh9H
ChAKCAQIAgEInAgAEgSmAiBGCqIBCgIECRIGrAIAuwIBGpMBIE1ldGFkYXRhIGZvciBhCiBb
Q29udmVyc2F0aW9uRGF0YXNldHMuSW1wb3J0Q29udmVyc2F0aW9uRGF0YV1bZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjIuQ29udmVyc2F0aW9uRGF0YXNldHMuSW1wb3J0Q29udmVyc2F0
aW9uRGF0YV0KIG9wZXJhdGlvbi4KCgsKAwQJARIErAIILwqzAQoEBAkCABIGsAICsgIFGqIB
IFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBpbXBvcnRlZCBjb252ZXJzYXRpb24gZGF0YXNl
dC4gRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9u
CiBJRD4vY29udmVyc2F0aW9uRGF0YXNldHMvPENvbnZlcnNhdGlvbiBEYXRhc2V0IElkPmAK
Cg0KBQQJAgAFEgSwAgIICg0KBQQJAgABEgSwAgkdCg0KBQQJAgADEgSwAiAhCg8KBQQJAgAI
EgawAiKyAgQKEQoHBAkCAAifCBIGsAIjsgIDCokBCgQECQIBEgS2AgIyGnsgUGFydGlhbCBm
YWlsdXJlcyBhcmUgZmFpbHVyZXMgdGhhdCBkb24ndCBmYWlsIHRoZSB3aG9sZSBsb25nIHJ1
bm5pbmcKIG9wZXJhdGlvbiwgZS5nLiBzaW5nbGUgZmlsZXMgdGhhdCBjb3VsZG4ndCBiZSBy
ZWFkLgoKDQoFBAkCAQQSBLYCAgoKDQoFBAkCAQYSBLYCCxwKDQoFBAkCAQESBLYCHS0KDQoF
BAkCAQMSBLYCMDEKcgoEBAkCAhIEugICLBpkIFRpbWVzdGFtcCB3aGVuIGltcG9ydCBjb252
ZXJzYXRpb24gZGF0YSByZXF1ZXN0IHdhcyBjcmVhdGVkLiBUaGUgdGltZSBpcwogbWVhc3Vy
ZWQgb24gc2VydmVyIHNpZGUuCgoNCgUECQICBhIEugICGwoNCgUECQICARIEugIcJwoNCgUE
CQICAxIEugIqKwqyAQoCBAoSBsACAMoCARqjASBSZXNwb25zZSB1c2VkIGZvcgogW0NvbnZl
cnNhdGlvbkRhdGFzZXRzLkltcG9ydENvbnZlcnNhdGlvbkRhdGFdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyLkNvbnZlcnNhdGlvbkRhdGFzZXRzLkltcG9ydENvbnZlcnNhdGlvbkRh
dGFdCiBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uLgoKCwoDBAoBEgTAAggvCrMBCgQECgIAEgbE
AgLGAgUaogEgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGltcG9ydGVkIGNvbnZlcnNhdGlv
biBkYXRhc2V0LiBGb3JtYXQ6CiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88
TG9jYXRpb24KIElEPi9jb252ZXJzYXRpb25EYXRhc2V0cy88Q29udmVyc2F0aW9uIERhdGFz
ZXQgSWQ+YAoKDQoFBAoCAAUSBMQCAggKDQoFBAoCAAESBMQCCR0KDQoFBAoCAAMSBMQCICEK
DwoFBAoCAAgSBsQCIsYCBAoRCgcECgIACJ8IEgbEAiPGAgMKPgoEBAoCARIEyQICGRowIE51
bWJlciBvZiBjb252ZXJzYXRpb25zIGltcG9ydGVkIHN1Y2Nlc3NmdWxseS4KCg0KBQQKAgEF
EgTJAgIHCg0KBQQKAgEBEgTJAggUCg0KBQQKAgEDEgTJAhcYCjsKAgQLEgbNAgDUAgEaLSBN
ZXRhZGF0YSBmb3IgW0NyZWF0ZUNvbnZlcnNhdGlvbkRhdGFzZXRdW10uCgoLCgMECwESBM0C
CDIKvwEKBAQLAgASBtECAtMCBRquASBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgY29udmVy
c2F0aW9uIGRhdGFzZXQgdGhhdCB3aWxsIGJlIGNyZWF0ZWQuIEZvcm1hdDoKIGBwcm9qZWN0
cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbgogSUQ+L2NvbnZlcnNhdGlvbkRh
dGFzZXRzLzxDb252ZXJzYXRpb24gRGF0YXNldCBJZD5gCgoNCgUECwIABRIE0QICCAoNCgUE
CwIAARIE0QIJHQoNCgUECwIAAxIE0QIgIQoPCgUECwIACBIG0QIi0wIEChEKBwQLAgAInwgS
BtECI9MCAwo5CgIEDBIE1wIANRotIE1ldGFkYXRhIGZvciBbRGVsZXRlQ29udmVyc2F0aW9u
RGF0YXNldF1bXS4KCgsKAwQMARIE1wIIMmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationInfo ===
    # Fields for ConversationInfo
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::InputConfig ===
    # Fields for InputConfig
    # Field: gcs_source Type: 11 (.google.cloud.dialogflow.v2.GcsSources)

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDataset ===
    # Fields for ConversationDataset
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: input_config Type: 11 (.google.cloud.dialogflow.v2.InputConfig)
    # Field: conversation_info Type: 11 (.google.cloud.dialogflow.v2.ConversationInfo)
    # Field: conversation_count Type: 3 ()
    # Field: satisfies_pzi Type: 8 ()
    # Field: satisfies_pzs Type: 8 ()

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetRequest ===
    # Fields for CreateConversationDatasetRequest
    # Field: parent Type: 9 ()
    # Field: conversation_dataset Type: 11 (.google.cloud.dialogflow.v2.ConversationDataset)

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::GetConversationDatasetRequest ===
    # Fields for GetConversationDatasetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsRequest ===
    # Fields for ListConversationDatasetsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsResponse ===
    # Fields for ListConversationDatasetsResponse
    # Field: conversation_datasets Type: 11 (.google.cloud.dialogflow.v2.ConversationDataset)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetRequest ===
    # Fields for DeleteConversationDatasetRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataRequest ===
    # Fields for ImportConversationDataRequest
    # Field: name Type: 9 ()
    # Field: input_config Type: 11 (.google.cloud.dialogflow.v2.InputConfig)

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationMetadata ===
    # Fields for ImportConversationDataOperationMetadata
    # Field: conversation_dataset Type: 9 ()
    # Field: partial_failures Type: 11 (.google.rpc.Status)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationResponse ===
    # Fields for ImportConversationDataOperationResponse
    # Field: conversation_dataset Type: 9 ()
    # Field: import_count Type: 5 ()

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetOperationMetadata ===
    # Fields for CreateConversationDatasetOperationMetadata
    # Field: conversation_dataset Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetOperationMetadata ===
    # Fields for DeleteConversationDatasetOperationMetadata

# === Service Client: Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDatasetsClient ===
package Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDatasetsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDatasetsClient

Client stub representing the remote C<ConversationDatasets> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_conversation_dataset {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.ConversationDatasets',
        method         => 'CreateConversationDataset',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_conversation_dataset {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::ConversationDataset::GetConversationDatasetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.ConversationDatasets',
        method         => 'GetConversationDataset',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDataset',
    });
}

sub list_conversation_datasets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.ConversationDatasets',
        method         => 'ListConversationDatasets',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsResponse',
    });
}

sub delete_conversation_dataset {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.ConversationDatasets',
        method         => 'DeleteConversationDataset',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_conversation_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.ConversationDatasets',
        method         => 'ImportConversationData',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::ConversationDataset - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/conversation_dataset.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::ConversationDataset;

    my $msg = Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationInfo->new({
        language_code => $language_code,
    });

    # Read or update a field
    my $val = $msg->language_code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/conversation_dataset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationInfo

Represents metadata of a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Optional. The language code of the conversation data within this dataset.
See https://cloud.google.com/apis/design/standard_fields for more
information. Supports all UTF-8 languages.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::InputConfig

Represents the configuration of importing a set of conversation files in
Google Cloud Storage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Gcs::GcsSources>)

The Cloud Storage URI has the form gs://<Google Cloud Storage bucket
name>//agent*.json. Wildcards are allowed and will be expanded into all
matched JSON files, which will be read as one conversation per file.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDataset

Represents a conversation dataset that a user imports raw data into.
The data inside ConversationDataset can not be changed after
ImportConversationData finishes (and calling ImportConversationData on a
dataset that already has data is not allowed).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. ConversationDataset resource name. Format:
`projects/<Project ID>/locations/<Location
ID>/conversationDatasets/<Conversation Dataset ID>`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the dataset. Maximum of 64 bytes.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the dataset. Maximum of 10000 bytes.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time of this dataset.

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::ConversationDataset::InputConfig>)

Output only. Input configurations set during conversation data import.

=item * C<< $msg->conversation_info() >> / C<< $msg->conversation_info($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationInfo>)

Output only. Metadata set during conversation data import.

=item * C<< $msg->conversation_count() >> / C<< $msg->conversation_count($value) >>

Type: C<Int64>

Output only. The number of conversations this conversation dataset
contains.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. A read only boolean field reflecting Zone Isolation status of
the dataset.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. A read only boolean field reflecting Zone Separation status of
the dataset.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetRequest

The request message for
[ConversationDatasets.CreateConversationDataset][google.cloud.dialogflow.v2.ConversationDatasets.CreateConversationDataset].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project to create conversation dataset for. Format:
`projects/<Project ID>/locations/<Location ID>`

=item * C<< $msg->conversation_dataset() >> / C<< $msg->conversation_dataset($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDataset>)

Required. The conversation dataset to create.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::GetConversationDatasetRequest

The request message for
[ConversationDatasets.GetConversationDataset][google.cloud.dialogflow.v2.ConversationDatasets.GetConversationDataset].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The conversation dataset to retrieve. Format:
`projects/<Project ID>/locations/<Location
ID>/conversationDatasets/<Conversation Dataset ID>`

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsRequest

The request message for
[ConversationDatasets.ListConversationDatasets][google.cloud.dialogflow.v2.ConversationDatasets.ListConversationDatasets].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location name to list all conversation datasets
for. Format: `projects/<Project ID>/locations/<Location ID>`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of conversation datasets to return in a single
page. By default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsResponse

The response message for
[ConversationDatasets.ListConversationDatasets][google.cloud.dialogflow.v2.ConversationDatasets.ListConversationDatasets].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation_datasets() >> / C<< $msg->conversation_datasets($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDataset>)

The list of datasets to return.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to use to retrieve the next page of results, or empty if there
are no more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetRequest

The request message for
[ConversationDatasets.DeleteConversationDataset][google.cloud.dialogflow.v2.ConversationDatasets.DeleteConversationDataset].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The conversation dataset to delete. Format:
`projects/<Project ID>/locations/<Location
ID>/conversationDatasets/<Conversation Dataset ID>`

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataRequest

The request message for
[ConversationDatasets.ImportConversationData][google.cloud.dialogflow.v2.ConversationDatasets.ImportConversationData].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Dataset resource name. Format:
`projects/<Project ID>/locations/<Location
ID>/conversationDatasets/<Conversation Dataset ID>`

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::ConversationDataset::InputConfig>)

Required. Configuration describing where to import data from.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationMetadata

Metadata for a
[ConversationDatasets.ImportConversationData][google.cloud.dialogflow.v2.ConversationDatasets.ImportConversationData]
operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation_dataset() >> / C<< $msg->conversation_dataset($value) >>

Type: C<String>

The resource name of the imported conversation dataset. Format:
`projects/<Project ID>/locations/<Location
ID>/conversationDatasets/<Conversation Dataset Id>`

=item * C<< $msg->partial_failures() >> / C<< $msg->partial_failures($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Partial failures are failures that don't fail the whole long running
operation, e.g. single files that couldn't be read.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when import conversation data request was created. The time is
measured on server side.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationResponse

Response used for
[ConversationDatasets.ImportConversationData][google.cloud.dialogflow.v2.ConversationDatasets.ImportConversationData]
long running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation_dataset() >> / C<< $msg->conversation_dataset($value) >>

Type: C<String>

The resource name of the imported conversation dataset. Format:
`projects/<Project ID>/locations/<Location
ID>/conversationDatasets/<Conversation Dataset Id>`

=item * C<< $msg->import_count() >> / C<< $msg->import_count($value) >>

Type: C<Int32>

Number of conversations imported successfully.

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetOperationMetadata

Metadata for [CreateConversationDataset][].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation_dataset() >> / C<< $msg->conversation_dataset($value) >>

Type: C<String>

The resource name of the conversation dataset that will be created. Format:
`projects/<Project ID>/locations/<Location
ID>/conversationDatasets/<Conversation Dataset Id>`

=back

=head2 Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetOperationMetadata

Metadata for [DeleteConversationDataset][].

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::ConversationDataset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
