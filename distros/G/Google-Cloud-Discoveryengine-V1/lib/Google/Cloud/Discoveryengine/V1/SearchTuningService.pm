package Google::Cloud::Discoveryengine::V1::SearchTuningService;

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
    eval { require Google::Cloud::Discoveryengine::V1::CustomTuningModel };
    eval { require Google::Cloud::Discoveryengine::V1::ImportConfig };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3NlYXJjaF90dW5pbmdfc2Vydmlj
ZS5wcm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9h
bm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOWdvb2ds
ZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvY3VzdG9tX3R1bmluZ19tb2RlbC5wcm90bxoz
Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MS9pbXBvcnRfY29uZmlnLnByb3RvGiNn
b29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8iagoXTGlzdEN1c3RvbU1v
ZGVsc1JlcXVlc3QSTwoKZGF0YV9zdG9yZRgBIAEoCUIw4EEC+kEqCihkaXNjb3Zlcnllbmdp
bmUuZ29vZ2xlYXBpcy5jb20vRGF0YVN0b3JlUglkYXRhU3RvcmUiZgoYTGlzdEN1c3RvbU1v
ZGVsc1Jlc3BvbnNlEkoKBm1vZGVscxgBIAMoCzIyLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuQ3VzdG9tVHVuaW5nTW9kZWxSBm1vZGVscyK9BAoXVHJhaW5DdXN0b21Nb2Rl
bFJlcXVlc3QSeQoSZ2NzX3RyYWluaW5nX2lucHV0GAIgASgLMkkuZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5UcmFpbkN1c3RvbU1vZGVsUmVxdWVzdC5HY3NUcmFpbmluZ0lu
cHV0SABSEGdjc1RyYWluaW5nSW5wdXQSTwoKZGF0YV9zdG9yZRgBIAEoCUIw4EEC+kEqCihk
aXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRGF0YVN0b3JlUglkYXRhU3RvcmUSHQoK
bW9kZWxfdHlwZRgDIAEoCVIJbW9kZWxUeXBlElUKDGVycm9yX2NvbmZpZxgEIAEoCzIyLmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuSW1wb3J0RXJyb3JDb25maWdSC2Vycm9y
Q29uZmlnEhkKCG1vZGVsX2lkGAUgASgJUgdtb2RlbElkGrIBChBHY3NUcmFpbmluZ0lucHV0
EigKEGNvcnB1c19kYXRhX3BhdGgYASABKAlSDmNvcnB1c0RhdGFQYXRoEiYKD3F1ZXJ5X2Rh
dGFfcGF0aBgCIAEoCVINcXVlcnlEYXRhUGF0aBImCg90cmFpbl9kYXRhX3BhdGgYAyABKAlS
DXRyYWluRGF0YVBhdGgSJAoOdGVzdF9kYXRhX3BhdGgYBCABKAlSDHRlc3REYXRhUGF0aEIQ
Cg50cmFpbmluZ19pbnB1dCKKAwoYVHJhaW5DdXN0b21Nb2RlbFJlc3BvbnNlEjcKDWVycm9y
X3NhbXBsZXMYASADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVzElUKDGVy
cm9yX2NvbmZpZxgCIAEoCzIyLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuSW1w
b3J0RXJyb3JDb25maWdSC2Vycm9yQ29uZmlnEiEKDG1vZGVsX3N0YXR1cxgDIAEoCVILbW9k
ZWxTdGF0dXMSYAoHbWV0cmljcxgEIAMoCzJGLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuVHJhaW5DdXN0b21Nb2RlbFJlc3BvbnNlLk1ldHJpY3NFbnRyeVIHbWV0cmljcxId
Cgptb2RlbF9uYW1lGAUgASgJUgltb2RlbE5hbWUaOgoMTWV0cmljc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgBUgV2YWx1ZToCOAEilAEKGFRyYWluQ3VzdG9tTW9k
ZWxNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lMpAGChNTZWFyY2hUdW5pbmdTZXJ2aWNlEsMCChBU
cmFpbkN1c3RvbU1vZGVsEjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5UcmFp
bkN1c3RvbU1vZGVsUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i1QGC
0+STAlgiUy92MS97ZGF0YV9zdG9yZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rp
b25zLyovZGF0YVN0b3Jlcy8qfTp0cmFpbkN1c3RvbU1vZGVsOgEqykF0Cjhnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLlRyYWluQ3VzdG9tTW9kZWxSZXNwb25zZRI4Z29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5UcmFpbkN1c3RvbU1vZGVsTWV0YWRhdGES4AEK
EExpc3RDdXN0b21Nb2RlbHMSOC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxp
c3RDdXN0b21Nb2RlbHNSZXF1ZXN0GjkuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5MaXN0Q3VzdG9tTW9kZWxzUmVzcG9uc2UiV4LT5JMCURJPL3YxL3tkYXRhX3N0b3JlPXBy
b2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9L2N1c3Rv
bU1vZGVscxrPAcpBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJBqgFodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0ZSxodHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2aW5nLnJlYWR3cml0
ZUKLAgojY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFCGFNlYXJjaFR1bmlu
Z1NlcnZpY2VQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9h
cGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVO
R0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRc
RGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpW
MUqPMQoHEgUOAMUBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
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
AxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgME
EgMWAEMKCQoCAwUSAxcAPQoJCgIDBhIDGAAtCgkKAgMHEgMZACkKCQoCAwgSAxoAIQoICgEI
EgMcADwKCQoCCCUSAxwAPAoICgEIEgMdAGQKCQoCCAsSAx0AZAoICgEIEgMeACIKCQoCCAoS
Ax4AIgoICgEIEgMfADkKCQoCCAgSAx8AOQoICgEIEgMgADwKCQoCCAESAyAAPAoICgEIEgMh
AC0KCQoCCCQSAyEALQoICgEIEgMiADwKCQoCCCkSAyIAPAoICgEIEgMjADsKCQoCCC0SAyMA
OwooCgIGABIEJgBBARocIFNlcnZpY2UgZm9yIHNlYXJjaCB0dW5pbmcuCgoKCgMGAAESAyYI
GwoKCgMGAAMSAycCRgoMCgUGAAOZCBIDJwJGCgsKAwYAAxIEKAIrSgoNCgUGAAOaCBIEKAIr
SgomCgQGAAIAEgQuAjgDGhggVHJhaW5zIGEgY3VzdG9tIG1vZGVsLgoKDAoFBgACAAESAy4G
FgoMCgUGAAIAAhIDLhcuCgwKBQYAAgADEgMvDysKDQoFBgACAAQSBDAEMwYKEQoJBgACAASw
yrwiEgQwBDMGCg0KBQYAAgAEEgQ0BDcGCg8KBwYAAgAEmQgSBDQENwYKNQoEBgACARIEOwJA
AxonIEdldHMgYSBsaXN0IG9mIGFsbCB0aGUgY3VzdG9tIG1vZGVscy4KCgwKBQYAAgEBEgM7
BhYKDAoFBgACAQISAzsXLgoMCgUGAAIBAxIDPA8nCg0KBQYAAgEEEgQ9BD8GChEKCQYAAgEE
sMq8IhIEPQQ/BgqZAQoCBAASBEYAUQEajAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1NlYXJj
aFR1bmluZ1NlcnZpY2UuTGlzdEN1c3RvbU1vZGVsc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5TZWFyY2hUdW5pbmdTZXJ2aWNlLkxpc3RDdXN0b21Nb2RlbHNdCiBtZXRo
b2QuCgoKCgMEAAESA0YIHwr7AQoEBAACABIESwJQBBrsASBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIHBhcmVudCBEYXRhIFN0b3JlLCBzdWNoIGFzCiBgcHJvamVjdHMv
Ki9sb2NhdGlvbnMvZ2xvYmFsL2NvbGxlY3Rpb25zL2RlZmF1bHRfY29sbGVjdGlvbi9kYXRh
U3RvcmVzL2RlZmF1bHRfZGF0YV9zdG9yZWAuCiBUaGlzIGZpZWxkIGlzIHVzZWQgdG8gaWRl
bnRpZnkgdGhlIGRhdGEgc3RvcmUgd2hlcmUgdG8gZmV0Y2ggdGhlIG1vZGVscwogZnJvbS4K
CgwKBQQAAgAFEgNLAggKDAoFBAACAAESA0sJEwoMCgUEAAIAAxIDSxYXCg0KBQQAAgAIEgRL
GFADCg8KCAQAAgAInAgAEgNMBCoKDwoHBAACAAifCBIETQRPBQqaAQoCBAESBFYAWQEajQEg
UmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtTZWFyY2hUdW5pbmdTZXJ2aWNlLkxpc3RDdXN0b21N
b2RlbHNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuU2VhcmNoVHVuaW5nU2Vy
dmljZS5MaXN0Q3VzdG9tTW9kZWxzXQogbWV0aG9kLgoKCgoDBAEBEgNWCCAKLAoEBAECABID
WAIoGh8gTGlzdCBvZiBjdXN0b20gdHVuaW5nIG1vZGVscy4KCgwKBQQBAgAEEgNYAgoKDAoF
BAECAAYSA1gLHAoMCgUEAQIAARIDWB0jCgwKBQQBAgADEgNYJicKmgEKAgQCEgVeAJ4BARqM
ASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2VhcmNoVHVuaW5nU2VydmljZS5UcmFpbkN1c3Rv
bU1vZGVsXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNlYXJjaFR1bmluZ1Nl
cnZpY2UuVHJhaW5DdXN0b21Nb2RlbF0KIG1ldGhvZC4KCgoKAwQCARIDXggfCjMKBAQCAwAS
BWACgQEDGiQgQ2xvdWQgU3RvcmFnZSB0cmFpbmluZyBkYXRhIGlucHV0LgoKDAoFBAIDAAES
A2AKGgrbAgoGBAIDAAIAEgNoBCAaywIgVGhlIENsb3VkIFN0b3JhZ2UgY29ycHVzIGRhdGEg
d2hpY2ggY291bGQgYmUgYXNzb2NpYXRlZCBpbiB0cmFpbiBkYXRhLgogVGhlIGRhdGEgcGF0
aCBmb3JtYXQgaXMgYGdzOi8vPGJ1Y2tldF90b19kYXRhPi88anNvbmxfZmlsZV9uYW1lPmAu
CiBBIG5ld2xpbmUgZGVsaW1pdGVkIGpzb25sL25kanNvbiBmaWxlLgoKIEZvciBzZWFyY2gt
dHVuaW5nIG1vZGVsLCBlYWNoIGxpbmUgc2hvdWxkIGhhdmUgdGhlIF9pZCwgdGl0bGUKIGFu
ZCB0ZXh0LiBFeGFtcGxlOgogYHsiX2lkIjogImRvYzEiLCB0aXRsZTogInJlbGV2YW50IGRv
YyIsICJ0ZXh0IjogInJlbGV2YW50IHRleHQifWAKCg4KBwQCAwACAAUSA2gECgoOCgcEAgMA
AgABEgNoCxsKDgoHBAIDAAIAAxIDaB4fCrICCgYEAgMAAgESA3AEHxqiAiBUaGUgZ2NzIHF1
ZXJ5IGRhdGEgd2hpY2ggY291bGQgYmUgYXNzb2NpYXRlZCBpbiB0cmFpbiBkYXRhLgogVGhl
IGRhdGEgcGF0aCBmb3JtYXQgaXMgYGdzOi8vPGJ1Y2tldF90b19kYXRhPi88anNvbmxfZmls
ZV9uYW1lPmAuCiBBIG5ld2xpbmUgZGVsaW1pdGVkIGpzb25sL25kanNvbiBmaWxlLgoKIEZv
ciBzZWFyY2gtdHVuaW5nIG1vZGVsLCBlYWNoIGxpbmUgc2hvdWxkIGhhdmUgdGhlIF9pZAog
YW5kIHRleHQuIEV4YW1wbGU6IHsiX2lkIjogInF1ZXJ5MSIsICAidGV4dCI6ICJleGFtcGxl
IHF1ZXJ5In0KCg4KBwQCAwACAQUSA3AECgoOCgcEAgMAAgEBEgNwCxoKDgoHBAIDAAIBAxID
cB0eCtoDCgYEAgMAAgISA3wEHxrKAyBDbG91ZCBTdG9yYWdlIHRyYWluaW5nIGRhdGEgcGF0
aCB3aG9zZSBmb3JtYXQgc2hvdWxkIGJlCiBgZ3M6Ly88YnVja2V0X3RvX2RhdGE+Lzx0c3Zf
ZmlsZV9uYW1lPmAuIFRoZSBmaWxlIHNob3VsZCBiZSBpbiB0c3YKIGZvcm1hdC4gRWFjaCBs
aW5lIHNob3VsZCBoYXZlIHRoZSBkb2NfaWQgYW5kIHF1ZXJ5X2lkIGFuZCBzY29yZSAobnVt
YmVyKS4KCiBGb3Igc2VhcmNoLXR1bmluZyBtb2RlbCwgaXQgc2hvdWxkIGhhdmUgdGhlIHF1
ZXJ5LWlkIGNvcnB1cy1pZAogc2NvcmUgYXMgdHN2IGZpbGUgaGVhZGVyLiBUaGUgc2NvcmUg
c2hvdWxkIGJlIGEgbnVtYmVyIGluIGBbMCwgaW5mKylgLgogVGhlIGxhcmdlciB0aGUgbnVt
YmVyIGlzLCB0aGUgbW9yZSByZWxldmFudCB0aGUgcGFpciBpcy4gRXhhbXBsZToKCiAqIGBx
dWVyeS1pZFx0Y29ycHVzLWlkXHRzY29yZWAKICogYHF1ZXJ5MVx0ZG9jMVx0MWAKCg4KBwQC
AwACAgUSA3wECgoOCgcEAgMAAgIBEgN8CxoKDgoHBAIDAAICAxIDfB0eCqMBCgYEAgMAAgMS
BIABBB4akgEgQ2xvdWQgU3RvcmFnZSB0ZXN0IGRhdGEuIFNhbWUgZm9ybWF0IGFzIHRyYWlu
X2RhdGFfcGF0aC4gSWYgbm90IHByb3ZpZGVkLAogYSByYW5kb20gODAvMjAgdHJhaW4vdGVz
dCBzcGxpdCB3aWxsIGJlIHBlcmZvcm1lZCBvbiB0cmFpbl9kYXRhX3BhdGguCgoPCgcEAgMA
AgMFEgSAAQQKCg8KBwQCAwACAwESBIABCxkKDwoHBAIDAAIDAxIEgAEcHQonCgQEAggAEgaE
AQKHAQMaFyBNb2RlbCB0cmFpbmluZyBpbnB1dC4KCg0KBQQCCAABEgSEAQgWCi0KBAQCAgAS
BIYBBCwaHyBDbG91ZCBTdG9yYWdlIHRyYWluaW5nIGlucHV0LgoKDQoFBAICAAYSBIYBBBQK
DQoFBAICAAESBIYBFScKDQoFBAICAAMSBIYBKisK8AEKBAQCAgESBowBApEBBBrfASBSZXF1
aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIERhdGEgU3RvcmUsIHN1Y2ggYXMKIGBw
cm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMvZGVmYXVsdF9jb2xsZWN0
aW9uL2RhdGFTdG9yZXMvZGVmYXVsdF9kYXRhX3N0b3JlYC4KIFRoaXMgZmllbGQgaXMgdXNl
ZCB0byBpZGVudGlmeSB0aGUgZGF0YSBzdG9yZSB3aGVyZSB0byB0cmFpbiB0aGUgbW9kZWxz
LgoKDQoFBAICAQUSBIwBAggKDQoFBAICAQESBIwBCRMKDQoFBAICAQMSBIwBFhcKDwoFBAIC
AQgSBowBGJEBAwoQCggEAgIBCJwIABIEjQEEKgoRCgcEAgIBCJ8IEgaOAQSQAQUKiAEKBAQC
AgISBJYBAhgaeiBNb2RlbCB0byBiZSB0cmFpbmVkLiBTdXBwb3J0ZWQgdmFsdWVzIGFyZToK
CiAgKiAqKnNlYXJjaC10dW5pbmcqKjogRmluZSB0dW5pbmcgdGhlIHNlYXJjaCBzeXN0ZW0g
YmFzZWQgb24gZGF0YSBwcm92aWRlZC4KCg0KBQQCAgIFEgSWAQIICg0KBQQCAgIBEgSWAQkT
Cg0KBQQCAgIDEgSWARYXCmAKBAQCAgMSBJoBAiUaUiBUaGUgZGVzaXJlZCBsb2NhdGlvbiBv
ZiBlcnJvcnMgaW5jdXJyZWQgZHVyaW5nIHRoZSBkYXRhIGluZ2VzdGlvbiBhbmQKIHRyYWlu
aW5nLgoKDQoFBAICAwYSBJoBAhMKDQoFBAICAwESBJoBFCAKDQoFBAICAwMSBJoBIyQKOgoE
BAICBBIEnQECFhosIElmIG5vdCBwcm92aWRlZCwgYSBVVUlEIHdpbGwgYmUgZ2VuZXJhdGVk
LgoKDQoFBAICBAUSBJ0BAggKDQoFBAICBAESBJ0BCREKDQoFBAICBAMSBJ0BFBUKxAEKAgQD
EgajAQC6AQEatQEgUmVzcG9uc2Ugb2YgdGhlCiBbVHJhaW5DdXN0b21Nb2RlbFJlcXVlc3Rd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVHJhaW5DdXN0b21Nb2RlbFJlcXVl
c3RdLgogVGhpcyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9ucy5yZXNwb25zZSBmaWVsZC4KCgsKAwQDARIEowEIIApJCgQEAwIAEgSl
AQIvGjsgQSBzYW1wbGUgb2YgZXJyb3JzIGVuY291bnRlcmVkIHdoaWxlIHByb2Nlc3Npbmcg
dGhlIGRhdGEuCgoNCgUEAwIABBIEpQECCgoNCgUEAwIABhIEpQELHAoNCgUEAwIAARIEpQEd
KgoNCgUEAwIAAxIEpQEtLgpVCgQEAwIBEgSoAQIlGkcgRWNob2VzIHRoZSBkZXN0aW5hdGlv
biBmb3IgdGhlIGNvbXBsZXRlIGVycm9ycyBpbiB0aGUgcmVxdWVzdCBpZiBzZXQuCgoNCgUE
AwIBBhIEqAECEwoNCgUEAwIBARIEqAEUIAoNCgUEAwIBAxIEqAEjJArSAwoEBAMCAhIEswEC
GhrDAyBUaGUgdHJhaW5lZCBtb2RlbCBzdGF0dXMuIFBvc3NpYmxlIHZhbHVlcyBhcmU6Cgog
ICogKipiYWQtZGF0YSoqOiBUaGUgdHJhaW5pbmcgZGF0YSBxdWFsaXR5IGlzIGJhZC4KICAq
ICoqbm8taW1wcm92ZW1lbnQqKjogVHVuaW5nIGRpZG4ndCBpbXByb3ZlIHBlcmZvcm1hbmNl
LiBXb24ndCBkZXBsb3kuCiAgKiAqKmluLXByb2dyZXNzKio6IE1vZGVsIHRyYWluaW5nIGpv
YiBjcmVhdGlvbiBpcyBpbiBwcm9ncmVzcy4KICAqICoqdHJhaW5pbmcqKjogTW9kZWwgaXMg
YWN0aXZlbHkgdHJhaW5pbmcuCiAgKiAqKmV2YWx1YXRpbmcqKjogVGhlIG1vZGVsIGlzIGV2
YWx1YXRpbmcgdHJhaW5lZCBtZXRyaWNzLgogICogKippbmRleGluZyoqOiBUaGUgbW9kZWwg
dHJhaW5lZCBtZXRyaWNzIGFyZSBpbmRleGluZy4KICAqICoqcmVhZHkqKjogVGhlIG1vZGVs
IGlzIHJlYWR5IGZvciBzZXJ2aW5nLgoKDQoFBAMCAgUSBLMBAggKDQoFBAMCAgESBLMBCRUK
DQoFBAMCAgMSBLMBGBkKMQoEBAMCAxIEtgECIhojIFRoZSBtZXRyaWNzIG9mIHRoZSB0cmFp
bmVkIG1vZGVsLgoKDQoFBAMCAwYSBLYBAhUKDQoFBAMCAwESBLYBFh0KDQoFBAMCAwMSBLYB
ICEKPgoEBAMCBBIEuQECGBowIEZ1bGx5IHF1YWxpZmllZCBuYW1lIG9mIHRoZSBDdXN0b21U
dW5pbmdNb2RlbC4KCg0KBQQDAgQFEgS5AQIICg0KBQQDAgQBEgS5AQkTCg0KBQQDAgQDEgS5
ARYXCpoBCgIEBBIGvgEAxQEBGosBIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNz
IG9mIHRoZSBUcmFpbkN1c3RvbU1vZGVsIG9wZXJhdGlvbi4gVGhpcyBpcwogcmV0dXJuZWQg
YnkgdGhlIGdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ubWV0YWRhdGEgZmllbGQuCgoL
CgMEBAESBL4BCCAKJgoEBAQCABIEwAECLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0K
BQQEAgAGEgTAAQIbCg0KBQQEAgABEgTAARwnCg0KBQQEAgADEgTAASorCmQKBAQEAgESBMQB
AiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBk
b25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0KBQQEAgEGEgTEAQIbCg0K
BQQEAgEBEgTEARwnCg0KBQQEAgEDEgTEASorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::SearchTuningService::ListCustomModelsRequest ===
    # Fields for ListCustomModelsRequest
    # Field: data_store Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SearchTuningService::ListCustomModelsResponse ===
    # Fields for ListCustomModelsResponse
    # Field: models Type: 11 (.google.cloud.discoveryengine.v1.CustomTuningModel)

# === Message: Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelRequest ===
    # Fields for TrainCustomModelRequest
    # Field: gcs_training_input Type: 11 (.google.cloud.discoveryengine.v1.TrainCustomModelRequest.GcsTrainingInput)
    # Field: data_store Type: 9 ()
    # Field: model_type Type: 9 ()
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1.ImportErrorConfig)
    # Field: model_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelResponse ===
    # Fields for TrainCustomModelResponse
    # Field: error_samples Type: 11 (.google.rpc.Status)
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1.ImportErrorConfig)
    # Field: model_status Type: 9 ()
    # Field: metrics Type: 11 (.google.cloud.discoveryengine.v1.TrainCustomModelResponse.MetricsEntry)
    # Field: model_name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelMetadata ===
    # Fields for TrainCustomModelMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1::SearchTuningService::SearchTuningServiceClient ===
package Google::Cloud::Discoveryengine::V1::SearchTuningService::SearchTuningServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::SearchTuningService::SearchTuningServiceClient

Client stub representing the remote C<SearchTuningService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub train_custom_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SearchTuningService',
        method         => 'TrainCustomModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_custom_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::SearchTuningService::ListCustomModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.SearchTuningService',
        method         => 'ListCustomModels',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::SearchTuningService::ListCustomModelsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::SearchTuningService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/search_tuning_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::SearchTuningService;

    my $msg = Google::Cloud::Discoveryengine::V1::SearchTuningService::ListCustomModelsRequest->new({
        data_store => $data_store,
    });

    # Read or update a field
    my $val = $msg->data_store();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::SearchTuningService::ListCustomModelsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/search_tuning_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::SearchTuningService::ListCustomModelsRequest

Request message for
[SearchTuningService.ListCustomModels][google.cloud.discoveryengine.v1.SearchTuningService.ListCustomModels]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<String>

Required. The resource name of the parent Data Store, such as
`projects/*/locations/global/collections/default_collection/dataStores/default_data_store`.
This field is used to identify the data store where to fetch the models
from.

=back

=head2 Google::Cloud::Discoveryengine::V1::SearchTuningService::ListCustomModelsResponse

Response message for
[SearchTuningService.ListCustomModels][google.cloud.discoveryengine.v1.SearchTuningService.ListCustomModels]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::CustomTuningModel::CustomTuningModel>)

List of custom tuning models.

=back

=head2 Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelRequest

Request message for
[SearchTuningService.TrainCustomModel][google.cloud.discoveryengine.v1.SearchTuningService.TrainCustomModel]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_training_input() >> / C<< $msg->gcs_training_input($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelRequest::GcsTrainingInput>)

Cloud Storage training input.

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<String>

Required. The resource name of the Data Store, such as
`projects/*/locations/global/collections/default_collection/dataStores/default_data_store`.
This field is used to identify the data store where to train the models.

=item * C<< $msg->model_type() >> / C<< $msg->model_type($value) >>

Type: C<String>

Model to be trained. Supported values are:

 * B<search-tuning>: Fine tuning the search system based on data provided.

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::ImportConfig::ImportErrorConfig>)

The desired location of errors incurred during the data ingestion and
training.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

If not provided, a UUID will be generated.

=back

=head2 Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelResponse

Response of the
[TrainCustomModelRequest][google.cloud.discoveryengine.v1.TrainCustomModelRequest].
This message is returned by the google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the data.

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::ImportConfig::ImportErrorConfig>)

Echoes the destination for the complete errors in the request if set.

=item * C<< $msg->model_status() >> / C<< $msg->model_status($value) >>

Type: C<String>

The trained model status. Possible values are:

 * B<bad-data>: The training data quality is bad.
 * B<no-improvement>: Tuning didn't improve performance. Won't deploy.
 * B<in-progress>: Model training job creation is in progress.
 * B<training>: Model is actively training.
 * B<evaluating>: The model is evaluating trained metrics.
 * B<indexing>: The model trained metrics are indexing.
 * B<ready>: The model is ready for serving.

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelResponse::MetricsEntry>)

The metrics of the trained model.

=item * C<< $msg->model_name() >> / C<< $msg->model_name($value) >>

Type: C<String>

Fully qualified name of the CustomTuningModel.

=back

=head2 Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelMetadata

Metadata related to the progress of the TrainCustomModel operation. This is
returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::SearchTuningService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
