package Google::Dataflow::V1beta3::Messages;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvZGF0YWZsb3cvdjFiZXRhMy9tZXNzYWdlcy5wcm90bxIXZ29vZ2xlLmRhdGFm
bG93LnYxYmV0YTMaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkv
Y2xpZW50LnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvIs0BCgpKb2JNZXNzYWdlEg4KAmlkGAEgASgJUgJpZBIu
CgR0aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIEdGltZRIhCgxtZXNz
YWdlX3RleHQYAyABKAlSC21lc3NhZ2VUZXh0ElwKEm1lc3NhZ2VfaW1wb3J0YW5jZRgEIAEo
DjItLmdvb2dsZS5kYXRhZmxvdy52MWJldGEzLkpvYk1lc3NhZ2VJbXBvcnRhbmNlUhFtZXNz
YWdlSW1wb3J0YW5jZSL6AQoRU3RydWN0dXJlZE1lc3NhZ2USIQoMbWVzc2FnZV90ZXh0GAEg
ASgJUgttZXNzYWdlVGV4dBIfCgttZXNzYWdlX2tleRgCIAEoCVIKbWVzc2FnZUtleRJUCgpw
YXJhbWV0ZXJzGAMgAygLMjQuZ29vZ2xlLmRhdGFmbG93LnYxYmV0YTMuU3RydWN0dXJlZE1l
c3NhZ2UuUGFyYW1ldGVyUgpwYXJhbWV0ZXJzGksKCVBhcmFtZXRlchIQCgNrZXkYASABKAlS
A2tleRIsCgV2YWx1ZRgCIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZVIFdmFsdWUigAQK
EEF1dG9zY2FsaW5nRXZlbnQSLgoTY3VycmVudF9udW1fd29ya2VycxgBIAEoA1IRY3VycmVu
dE51bVdvcmtlcnMSLAoSdGFyZ2V0X251bV93b3JrZXJzGAIgASgDUhB0YXJnZXROdW1Xb3Jr
ZXJzEl0KCmV2ZW50X3R5cGUYAyABKA4yPi5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5BdXRv
c2NhbGluZ0V2ZW50LkF1dG9zY2FsaW5nRXZlbnRUeXBlUglldmVudFR5cGUSTAoLZGVzY3Jp
cHRpb24YBCABKAsyKi5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5TdHJ1Y3R1cmVkTWVzc2Fn
ZVILZGVzY3JpcHRpb24SLgoEdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSBHRpbWUSHwoLd29ya2VyX3Bvb2wYByABKAlSCndvcmtlclBvb2wijwEKFEF1dG9zY2Fs
aW5nRXZlbnRUeXBlEhAKDFRZUEVfVU5LTk9XThAAEh4KGlRBUkdFVF9OVU1fV09SS0VSU19D
SEFOR0VEEAESHwobQ1VSUkVOVF9OVU1fV09SS0VSU19DSEFOR0VEEAISFQoRQUNUVUFUSU9O
X0ZBSUxVUkUQAxINCglOT19DSEFOR0UQBCL2AgoWTGlzdEpvYk1lc3NhZ2VzUmVxdWVzdBId
Cgpwcm9qZWN0X2lkGAEgASgJUglwcm9qZWN0SWQSFQoGam9iX2lkGAIgASgJUgVqb2JJZBJc
ChJtaW5pbXVtX2ltcG9ydGFuY2UYAyABKA4yLS5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5K
b2JNZXNzYWdlSW1wb3J0YW5jZVIRbWluaW11bUltcG9ydGFuY2USGwoJcGFnZV9zaXplGAQg
ASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAUgASgJUglwYWdlVG9rZW4SOQoKc3RhcnRf
dGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1Cghl
bmRfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSGgoI
bG9jYXRpb24YCCABKAlSCGxvY2F0aW9uIuMBChdMaXN0Sm9iTWVzc2FnZXNSZXNwb25zZRJG
Cgxqb2JfbWVzc2FnZXMYASADKAsyIy5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5Kb2JNZXNz
YWdlUgtqb2JNZXNzYWdlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9r
ZW4SWAoSYXV0b3NjYWxpbmdfZXZlbnRzGAMgAygLMikuZ29vZ2xlLmRhdGFmbG93LnYxYmV0
YTMuQXV0b3NjYWxpbmdFdmVudFIRYXV0b3NjYWxpbmdFdmVudHMqsgEKFEpvYk1lc3NhZ2VJ
bXBvcnRhbmNlEiIKHkpPQl9NRVNTQUdFX0lNUE9SVEFOQ0VfVU5LTk9XThAAEhUKEUpPQl9N
RVNTQUdFX0RFQlVHEAESGAoUSk9CX01FU1NBR0VfREVUQUlMRUQQAhIVChFKT0JfTUVTU0FH
RV9CQVNJQxAFEhcKE0pPQl9NRVNTQUdFX1dBUk5JTkcQAxIVChFKT0JfTUVTU0FHRV9FUlJP
UhAEMoUDCg9NZXNzYWdlc1YxQmV0YTMS/AEKD0xpc3RKb2JNZXNzYWdlcxIvLmdvb2dsZS5k
YXRhZmxvdy52MWJldGEzLkxpc3RKb2JNZXNzYWdlc1JlcXVlc3QaMC5nb29nbGUuZGF0YWZs
b3cudjFiZXRhMy5MaXN0Sm9iTWVzc2FnZXNSZXNwb25zZSKFAYLT5JMCfxJHL3YxYjMvcHJv
amVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2pvYnMve2pvYl9pZH0v
bWVzc2FnZXNaNBIyL3YxYjMvcHJvamVjdHMve3Byb2plY3RfaWR9L2pvYnMve2pvYl9pZH0v
bWVzc2FnZXMac8pBF2RhdGFmbG93Lmdvb2dsZWFwaXMuY29t0kFWaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2NvbXB1dGVC0AEKG2NvbS5nb29nbGUuZGF0YWZsb3cudjFiZXRhM0INTWVz
c2FnZXNQcm90b1ABWj1jbG91ZC5nb29nbGUuY29tL2dvL2RhdGFmbG93L2FwaXYxYmV0YTMv
ZGF0YWZsb3dwYjtkYXRhZmxvd3BiqgIdR29vZ2xlLkNsb3VkLkRhdGFmbG93LlYxQmV0YTPK
Ah1Hb29nbGVcQ2xvdWRcRGF0YWZsb3dcVjFiZXRhM+oCIEdvb2dsZTo6Q2xvdWQ6OkRhdGFm
bG93OjpWMWJldGEzSuVCCgcSBQ4A6wEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAAmCgkKAgMD
EgMVACkKCAoBCBIDFwA6CgkKAgglEgMXADoKCAoBCBIDGABUCgkKAggLEgMYAFQKCAoBCBID
GQAiCgkKAggKEgMZACIKCAoBCBIDGgAuCgkKAggIEgMaAC4KCAoBCBIDGwA0CgkKAggBEgMb
ADQKCAoBCBIDHAA6CgkKAggpEgMcADoKCAoBCBIDHQA5CgkKAggtEgMdADkKWQoCBgASBCAA
NgEaTSBUaGUgRGF0YWZsb3cgTWVzc2FnZXMgQVBJIGlzIHVzZWQgdG8gbW9uaXRvciB0aGUg
cHJvZ3Jlc3Mgb2YgRGF0YWZsb3cgam9icy4KCgoKAwYAARIDIAgXCgoKAwYAAxIDIQI/CgwK
BQYAA5kIEgMhAj8KCwoDBgADEgQiAiQwCg0KBQYAA5oIEgQiAiQwCvACCgQGAAIAEgQtAjUD
GuECIFJlcXVlc3QgdGhlIGpvYiBzdGF0dXMuCgogVG8gcmVxdWVzdCB0aGUgc3RhdHVzIG9m
IGEgam9iLCB3ZSByZWNvbW1lbmQgdXNpbmcKIGBwcm9qZWN0cy5sb2NhdGlvbnMuam9icy5t
ZXNzYWdlcy5saXN0YCB3aXRoIGEgW3JlZ2lvbmFsIGVuZHBvaW50XQogKGh0dHBzOi8vY2xv
dWQuZ29vZ2xlLmNvbS9kYXRhZmxvdy9kb2NzL2NvbmNlcHRzL3JlZ2lvbmFsLWVuZHBvaW50
cykuIFVzaW5nCiBgcHJvamVjdHMuam9icy5tZXNzYWdlcy5saXN0YCBpcyBub3QgcmVjb21t
ZW5kZWQsIGFzIHlvdSBjYW4gb25seSByZXF1ZXN0CiB0aGUgc3RhdHVzIG9mIGpvYnMgdGhh
dCBhcmUgcnVubmluZyBpbiBgdXMtY2VudHJhbDFgLgoKDAoFBgACAAESAy0GFQoMCgUGAAIA
AhIDLRYsCgwKBQYAAgADEgMuDyYKDQoFBgACAAQSBC8ENAYKEQoJBgACAASwyrwiEgQvBDQG
CkAKAgQAEgQ5AEUBGjQgQSBwYXJ0aWN1bGFyIG1lc3NhZ2UgcGVydGFpbmluZyB0byBhIERh
dGFmbG93IGpvYi4KCgoKAwQAARIDOQgSChoKBAQAAgASAzsCEBoNIERlcHJlY2F0ZWQuCgoM
CgUEAAIABRIDOwIICgwKBQQAAgABEgM7CQsKDAoFBAACAAMSAzsODwosCgQEAAIBEgM+AiUa
HyBUaGUgdGltZXN0YW1wIG9mIHRoZSBtZXNzYWdlLgoKDAoFBAACAQYSAz4CGwoMCgUEAAIB
ARIDPhwgCgwKBQQAAgEDEgM+IyQKJwoEBAACAhIDQQIaGhogVGhlIHRleHQgb2YgdGhlIG1l
c3NhZ2UuCgoMCgUEAAICBRIDQQIICgwKBQQAAgIBEgNBCRUKDAoFBAACAgMSA0EYGQovCgQE
AAIDEgNEAi4aIiBJbXBvcnRhbmNlIGxldmVsIG9mIHRoZSBtZXNzYWdlLgoKDAoFBAACAwYS
A0QCFgoMCgUEAAIDARIDRBcpCgwKBQQAAgMDEgNELC0KNgoCBQASBEgAbAEaKiBJbmRpY2F0
ZXMgdGhlIGltcG9ydGFuY2Ugb2YgdGhlIG1lc3NhZ2UuCgoKCgMFAAESA0gFGQpFCgQFAAIA
EgNKAiUaOCBUaGUgbWVzc2FnZSBpbXBvcnRhbmNlIGlzbid0IHNwZWNpZmllZCwgb3IgaXMg
dW5rbm93bi4KCgwKBQUAAgABEgNKAiAKDAoFBQACAAISA0ojJArnAQoEBQACARIDUAIYGtkB
IFRoZSBtZXNzYWdlIGlzIGF0IHRoZSAnZGVidWcnIGxldmVsOiB0eXBpY2FsbHkgb25seSB1
c2VmdWwgZm9yCiBzb2Z0d2FyZSBlbmdpbmVlcnMgd29ya2luZyBvbiB0aGUgY29kZSB0aGUg
am9iIGlzIHJ1bm5pbmcuCiBUeXBpY2FsbHksIERhdGFmbG93IHBpcGVsaW5lIHJ1bm5lcnMg
ZG8gbm90IGRpc3BsYXkgbG9nIG1lc3NhZ2VzCiBhdCB0aGlzIGxldmVsIGJ5IGRlZmF1bHQu
CgoMCgUFAAIBARIDUAITCgwKBQUAAgECEgNQFhcKkQIKBAUAAgISA1cCGxqDAiBUaGUgbWVz
c2FnZSBpcyBhdCB0aGUgJ2RldGFpbGVkJyBsZXZlbDogc29tZXdoYXQgdmVyYm9zZSwgYnV0
CiBwb3RlbnRpYWxseSB1c2VmdWwgdG8gdXNlcnMuICBUeXBpY2FsbHksIERhdGFmbG93IHBp
cGVsaW5lCiBydW5uZXJzIGRvIG5vdCBkaXNwbGF5IGxvZyBtZXNzYWdlcyBhdCB0aGlzIGxl
dmVsIGJ5IGRlZmF1bHQuCiBUaGVzZSBtZXNzYWdlcyBhcmUgZGlzcGxheWVkIGJ5IGRlZmF1
bHQgaW4gdGhlIERhdGFmbG93CiBtb25pdG9yaW5nIFVJLgoKDAoFBQACAgESA1cCFgoMCgUF
AAICAhIDVxkaCpoCCgQFAAIDEgNeAhgajAIgVGhlIG1lc3NhZ2UgaXMgYXQgdGhlICdiYXNp
YycgbGV2ZWw6IHVzZWZ1bCBmb3Iga2VlcGluZwogdHJhY2sgb2YgdGhlIGV4ZWN1dGlvbiBv
ZiBhIERhdGFmbG93IHBpcGVsaW5lLiAgVHlwaWNhbGx5LAogRGF0YWZsb3cgcGlwZWxpbmUg
cnVubmVycyBkaXNwbGF5IGxvZyBtZXNzYWdlcyBhdCB0aGlzIGxldmVsIGJ5CiBkZWZhdWx0
LCBhbmQgdGhlc2UgbWVzc2FnZXMgYXJlIGRpc3BsYXllZCBieSBkZWZhdWx0IGluIHRoZQog
RGF0YWZsb3cgbW9uaXRvcmluZyBVSS4KCgwKBQUAAgMBEgNeAhMKDAoFBQACAwISA14WFwqq
AgoEBQACBBIDZQIaGpwCIFRoZSBtZXNzYWdlIGlzIGF0IHRoZSAnd2FybmluZycgbGV2ZWw6
IGluZGljYXRpbmcgYSBjb25kaXRpb24KIHBlcnRhaW5pbmcgdG8gYSBqb2Igd2hpY2ggbWF5
IHJlcXVpcmUgaHVtYW4gaW50ZXJ2ZW50aW9uLgogVHlwaWNhbGx5LCBEYXRhZmxvdyBwaXBl
bGluZSBydW5uZXJzIGRpc3BsYXkgbG9nIG1lc3NhZ2VzIGF0IHRoaXMKIGxldmVsIGJ5IGRl
ZmF1bHQsIGFuZCB0aGVzZSBtZXNzYWdlcyBhcmUgZGlzcGxheWVkIGJ5IGRlZmF1bHQgaW4K
IHRoZSBEYXRhZmxvdyBtb25pdG9yaW5nIFVJLgoKDAoFBQACBAESA2UCFQoMCgUFAAIEAhID
ZRgZCpACCgQFAAIFEgNrAhgaggIgVGhlIG1lc3NhZ2UgaXMgYXQgdGhlICdlcnJvcicgbGV2
ZWw6IGluZGljYXRpbmcgYSBjb25kaXRpb24KIHByZXZlbnRpbmcgYSBqb2IgZnJvbSBzdWNj
ZWVkaW5nLiAgVHlwaWNhbGx5LCBEYXRhZmxvdyBwaXBlbGluZQogcnVubmVycyBkaXNwbGF5
IGxvZyBtZXNzYWdlcyBhdCB0aGlzIGxldmVsIGJ5IGRlZmF1bHQsIGFuZCB0aGVzZQogbWVz
c2FnZXMgYXJlIGRpc3BsYXllZCBieSBkZWZhdWx0IGluIHRoZSBEYXRhZmxvdyBtb25pdG9y
aW5nIFVJLgoKDAoFBQACBQESA2sCEwoMCgUFAAIFAhIDaxYXCrwBCgIEARIFcQCEAQEargEg
QSByaWNoIG1lc3NhZ2UgZm9ybWF0LCBpbmNsdWRpbmcgYSBodW1hbiByZWFkYWJsZSBzdHJp
bmcsIGEga2V5IGZvcgogaWRlbnRpZnlpbmcgdGhlIG1lc3NhZ2UsIGFuZCBzdHJ1Y3R1cmVk
IGRhdGEgYXNzb2NpYXRlZCB3aXRoIHRoZSBtZXNzYWdlIGZvcgogcHJvZ3JhbW1hdGljIGNv
bnN1bXB0aW9uLgoKCgoDBAEBEgNxCBkKPQoEBAEDABIEcwJ5AxovIFN0cnVjdHVyZWQgZGF0
YSBhc3NvY2lhdGVkIHdpdGggdGhpcyBtZXNzYWdlLgoKDAoFBAEDAAESA3MKEwowCgYEAQMA
AgASA3UEExohIEtleSBvciBuYW1lIGZvciB0aGlzIHBhcmFtZXRlci4KCg4KBwQBAwACAAUS
A3UECgoOCgcEAQMAAgABEgN1Cw4KDgoHBAEDAAIAAxIDdRESCioKBgQBAwACARIDeAQkGhsg
VmFsdWUgZm9yIHRoaXMgcGFyYW1ldGVyLgoKDgoHBAEDAAIBBhIDeAQZCg4KBwQBAwACAQES
A3gaHwoOCgcEAQMAAgEDEgN4IiMKMQoEBAECABIDfAIaGiQgSHVtYW4tcmVhZGFibGUgdmVy
c2lvbiBvZiBtZXNzYWdlLgoKDAoFBAECAAUSA3wCCAoMCgUEAQIAARIDfAkVCgwKBQQBAgAD
EgN8GBkKeAoEBAECARIEgAECGRpqIElkZW50aWZpZXIgZm9yIHRoaXMgbWVzc2FnZSB0eXBl
LiAgVXNlZCBieSBleHRlcm5hbCBzeXN0ZW1zIHRvCiBpbnRlcm5hdGlvbmFsaXplIG9yIHBl
cnNvbmFsaXplIG1lc3NhZ2UuCgoNCgUEAQIBBRIEgAECCAoNCgUEAQIBARIEgAEJFAoNCgUE
AQIBAxIEgAEXGApBCgQEAQICEgSDAQIkGjMgVGhlIHN0cnVjdHVyZWQgZGF0YSBhc3NvY2lh
dGVkIHdpdGggdGhpcyBtZXNzYWdlLgoKDQoFBAECAgQSBIMBAgoKDQoFBAECAgYSBIMBCxQK
DQoFBAECAgESBIMBFR8KDQoFBAECAgMSBIMBIiMKZQoCBAISBogBALkBARpXIEEgc3RydWN0
dXJlZCBtZXNzYWdlIHJlcG9ydGluZyBhbiBhdXRvc2NhbGluZyBkZWNpc2lvbiBtYWRlIGJ5
IHRoZSBEYXRhZmxvdwogc2VydmljZS4KCgsKAwQCARIEiAEIGAo6CgQEAgQAEgaKAQKjAQMa
KiBJbmRpY2F0ZXMgdGhlIHR5cGUgb2YgYXV0b3NjYWxpbmcgZXZlbnQuCgoNCgUEAgQAARIE
igEHGwpNCgYEAgQAAgASBIwBBBUaPSBEZWZhdWx0IHR5cGUgZm9yIHRoZSBlbnVtLiAgVmFs
dWUgc2hvdWxkIG5ldmVyIGJlIHJldHVybmVkLgoKDwoHBAIEAAIAARIEjAEEEAoPCgcEAgQA
AgACEgSMARMUCogCCgYEAgQAAgESBJIBBCMa9wEgVGhlIFRBUkdFVF9OVU1fV09SS0VSU19D
SEFOR0VEIHR5cGUgc2hvdWxkIGJlIHVzZWQgd2hlbiB0aGUgdGFyZ2V0CiB3b3JrZXIgcG9v
bCBzaXplIGhhcyBjaGFuZ2VkIGF0IHRoZSBzdGFydCBvZiBhbiBhY3R1YXRpb24uIEFuIGV2
ZW50CiBzaG91bGQgYWx3YXlzIGJlIHNwZWNpZmllZCBhcyBUQVJHRVRfTlVNX1dPUktFUlNf
Q0hBTkdFRCBpZiBpdCByZWZsZWN0cwogYSBjaGFuZ2UgaW4gdGhlIHRhcmdldF9udW1fd29y
a2Vycy4KCg8KBwQCBAACAQESBJIBBB4KDwoHBAIEAAIBAhIEkgEhIgqiAQoGBAIEAAICEgSW
AQQkGpEBIFRoZSBDVVJSRU5UX05VTV9XT1JLRVJTX0NIQU5HRUQgdHlwZSBzaG91bGQgYmUg
dXNlZCB3aGVuIGFjdHVhbCB3b3JrZXIKIHBvb2wgc2l6ZSBoYXMgYmVlbiBjaGFuZ2VkLCBi
dXQgdGhlIHRhcmdldF9udW1fd29ya2VycyBoYXMgbm90IGNoYW5nZWQuCgoPCgcEAgQAAgIB
EgSWAQQfCg8KBwQCBAACAgISBJYBIiMK7wEKBgQCBAACAxIEnAEEGhreASBUaGUgQUNUVUFU
SU9OX0ZBSUxVUkUgdHlwZSBzaG91bGQgYmUgdXNlZCB3aGVuIHdlIHdhbnQgdG8gcmVwb3J0
CiBhbiBlcnJvciB0byB0aGUgdXNlciBpbmRpY2F0aW5nIHdoeSB0aGUgY3VycmVudCBudW1i
ZXIgb2Ygd29ya2VycwogaW4gdGhlIHBvb2wgY291bGQgbm90IGJlIGNoYW5nZWQuCiBEaXNw
bGF5ZWQgaW4gdGhlIGN1cnJlbnQgc3RhdHVzIGFuZCBoaXN0b3J5IHdpZGdldHMuCgoPCgcE
AgQAAgMBEgScAQQVCg8KBwQCBAACAwISBJwBGBkK1AEKBgQCBAACBBIEogEEEhrDASBVc2Vk
IHdoZW4gd2Ugd2FudCB0byByZXBvcnQgdG8gdGhlIHVzZXIgYSByZWFzb24gd2h5IHdlIGFy
ZQogbm90IGN1cnJlbnRseSBhZGp1c3RpbmcgdGhlIG51bWJlciBvZiB3b3JrZXJzLgogU2hv
dWxkIHNwZWNpZnkgYm90aCB0YXJnZXRfbnVtX3dvcmtlcnMsIGN1cnJlbnRfbnVtX3dvcmtl
cnMgYW5kIGEKIGRlY2lzaW9uX21lc3NhZ2UuCgoPCgcEAgQAAgQBEgSiAQQNCg8KBwQCBAAC
BAISBKIBEBEKOgoEBAICABIEpgECIBosIFRoZSBjdXJyZW50IG51bWJlciBvZiB3b3JrZXJz
IHRoZSBqb2IgaGFzLgoKDQoFBAICAAUSBKYBAgcKDQoFBAICAAESBKYBCBsKDQoFBAICAAMS
BKYBHh8KVAoEBAICARIEqQECHxpGIFRoZSB0YXJnZXQgbnVtYmVyIG9mIHdvcmtlcnMgdGhl
IHdvcmtlciBwb29sIHdhbnRzIHRvIHJlc2l6ZSB0byB1c2UuCgoNCgUEAgIBBRIEqQECBwoN
CgUEAgIBARIEqQEIGgoNCgUEAgIBAxIEqQEdHgo4CgQEAgICEgSsAQImGiogVGhlIHR5cGUg
b2YgYXV0b3NjYWxpbmcgZXZlbnQgdG8gcmVwb3J0LgoKDQoFBAICAgYSBKwBAhYKDQoFBAIC
AgESBKwBFyEKDQoFBAICAgMSBKwBJCUKwgEKBAQCAgMSBLEBAiQaswEgQSBtZXNzYWdlIGRl
c2NyaWJpbmcgd2h5IHRoZSBzeXN0ZW0gZGVjaWRlZCB0byBhZGp1c3QgdGhlIGN1cnJlbnQK
IG51bWJlciBvZiB3b3JrZXJzLCB3aHkgaXQgZmFpbGVkLCBvciB3aHkgdGhlIHN5c3RlbSBk
ZWNpZGVkIHRvCiBub3QgbWFrZSBhbnkgY2hhbmdlcyB0byB0aGUgbnVtYmVyIG9mIHdvcmtl
cnMuCgoNCgUEAgIDBhIEsQECEwoNCgUEAgIDARIEsQEUHwoNCgUEAgIDAxIEsQEiIwpnCgQE
AgIEEgS1AQIlGlkgVGhlIHRpbWUgdGhpcyBldmVudCB3YXMgZW1pdHRlZCB0byBpbmRpY2F0
ZSBhIG5ldyB0YXJnZXQgb3IgY3VycmVudAogbnVtX3dvcmtlcnMgdmFsdWUuCgoNCgUEAgIE
BhIEtQECGwoNCgUEAgIEARIEtQEcIAoNCgUEAgIEAxIEtQEjJApTCgQEAgIFEgS4AQIZGkUg
QSBzaG9ydCBhbmQgZnJpZW5kbHkgbmFtZSBmb3IgdGhlIHdvcmtlciBwb29sIHRoaXMgZXZl
bnQgcmVmZXJzIHRvLgoKDQoFBAICBQUSBLgBAggKDQoFBAICBQESBLgBCRQKDQoFBAICBQMS
BLgBFxgK8AEKAgQDEga/AQDfAQEa4QEgUmVxdWVzdCB0byBsaXN0IGpvYiBtZXNzYWdlcy4K
IFVwIHRvIG1heF9yZXN1bHRzIG1lc3NhZ2VzIHdpbGwgYmUgcmV0dXJuZWQgaW4gdGhlIHRp
bWUgcmFuZ2Ugc3BlY2lmaWVkCiBzdGFydGluZyB3aXRoIHRoZSBvbGRlc3QgbWVzc2FnZXMg
Zmlyc3QuIElmIG5vIHRpbWUgcmFuZ2UgaXMgc3BlY2lmaWVkCiB0aGUgcmVzdWx0cyB3aXRo
IHN0YXJ0IHdpdGggdGhlIG9sZGVzdCBtZXNzYWdlLgoKCwoDBAMBEgS/AQgeCh0KBAQDAgAS
BMEBAhgaDyBBIHByb2plY3QgaWQuCgoNCgUEAwIABRIEwQECCAoNCgUEAwIAARIEwQEJEwoN
CgUEAwIAAxIEwQEWFwouCgQEAwIBEgTEAQIUGiAgVGhlIGpvYiB0byBnZXQgbWVzc2FnZXMg
YWJvdXQuCgoNCgUEAwIBBRIExAECCAoNCgUEAwIBARIExAEJDwoNCgUEAwIBAxIExAESEwpE
CgQEAwICEgTHAQIuGjYgRmlsdGVyIHRvIG9ubHkgZ2V0IG1lc3NhZ2VzIHdpdGggaW1wb3J0
YW5jZSA+PSBsZXZlbAoKDQoFBAMCAgYSBMcBAhYKDQoFBAMCAgESBMcBFykKDQoFBAMCAgMS
BMcBLC0KywEKBAQDAgMSBMwBAhYavAEgSWYgc3BlY2lmaWVkLCBkZXRlcm1pbmVzIHRoZSBt
YXhpbXVtIG51bWJlciBvZiBtZXNzYWdlcyB0bwogcmV0dXJuLiAgSWYgdW5zcGVjaWZpZWQs
IHRoZSBzZXJ2aWNlIG1heSBjaG9vc2UgYW4gYXBwcm9wcmlhdGUKIGRlZmF1bHQsIG9yIG1h
eSByZXR1cm4gYW4gYXJiaXRyYXJpbHkgbGFyZ2UgbnVtYmVyIG9mIHJlc3VsdHMuCgoNCgUE
AwIDBRIEzAECBwoNCgUEAwIDARIEzAEIEQoNCgUEAwIDAxIEzAEUFQqhAQoEBAMCBBIE0QEC
GBqSASBJZiBzdXBwbGllZCwgdGhpcyBzaG91bGQgYmUgdGhlIHZhbHVlIG9mIG5leHRfcGFn
ZV90b2tlbiByZXR1cm5lZAogYnkgYW4gZWFybGllciBjYWxsLiBUaGlzIHdpbGwgY2F1c2Ug
dGhlIG5leHQgcGFnZSBvZiByZXN1bHRzIHRvCiBiZSByZXR1cm5lZC4KCg0KBQQDAgQFEgTR
AQIICg0KBQQDAgQBEgTRAQkTCg0KBQQDAgQDEgTRARYXCpYBCgQEAwIFEgTVAQIrGocBIElm
IHNwZWNpZmllZCwgcmV0dXJuIG9ubHkgbWVzc2FnZXMgd2l0aCB0aW1lc3RhbXBzID49IHN0
YXJ0X3RpbWUuCiBUaGUgZGVmYXVsdCBpcyB0aGUgam9iIGNyZWF0aW9uIHRpbWUgKGkuZS4g
YmVnaW5uaW5nIG9mIG1lc3NhZ2VzKS4KCg0KBQQDAgUGEgTVAQIbCg0KBQQDAgUBEgTVARwm
Cg0KBQQDAgUDEgTVASkqCocBCgQEAwIGEgTZAQIpGnkgUmV0dXJuIG9ubHkgbWVzc2FnZXMg
d2l0aCB0aW1lc3RhbXBzIDwgZW5kX3RpbWUuIFRoZSBkZWZhdWx0IGlzIG5vdwogKGkuZS4g
cmV0dXJuIHVwIHRvIHRoZSBsYXRlc3QgbWVzc2FnZXMgYXZhaWxhYmxlKS4KCg0KBQQDAgYG
EgTZAQIbCg0KBQQDAgYBEgTZARwkCg0KBQQDAgYDEgTZAScoCpoBCgQEAwIHEgTeAQIWGosB
IFRoZSBbcmVnaW9uYWwgZW5kcG9pbnRdCiAoaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2Rh
dGFmbG93L2RvY3MvY29uY2VwdHMvcmVnaW9uYWwtZW5kcG9pbnRzKSB0aGF0CiBjb250YWlu
cyB0aGUgam9iIHNwZWNpZmllZCBieSBqb2JfaWQuCgoNCgUEAwIHBRIE3gECCAoNCgUEAwIH
ARIE3gEJEQoNCgUEAwIHAxIE3gEUFQo7CgIEBBIG4gEA6wEBGi0gUmVzcG9uc2UgdG8gYSBy
ZXF1ZXN0IHRvIGxpc3Qgam9iIG1lc3NhZ2VzLgoKCwoDBAQBEgTiAQgfCjYKBAQEAgASBOQB
AicaKCBNZXNzYWdlcyBpbiBhc2NlbmRpbmcgdGltZXN0YW1wIG9yZGVyLgoKDQoFBAQCAAQS
BOQBAgoKDQoFBAQCAAYSBOQBCxUKDQoFBAQCAAESBOQBFiIKDQoFBAQCAAMSBOQBJSYKTwoE
BAQCARIE5wECHRpBIFRoZSB0b2tlbiB0byBvYnRhaW4gdGhlIG5leHQgcGFnZSBvZiByZXN1
bHRzIGlmIHRoZXJlIGFyZSBtb3JlLgoKDQoFBAQCAQUSBOcBAggKDQoFBAQCAQESBOcBCRgK
DQoFBAQCAQMSBOcBGxwKQAoEBAQCAhIE6gECMxoyIEF1dG9zY2FsaW5nIGV2ZW50cyBpbiBh
c2NlbmRpbmcgdGltZXN0YW1wIG9yZGVyLgoKDQoFBAQCAgQSBOoBAgoKDQoFBAQCAgYSBOoB
CxsKDQoFBAQCAgESBOoBHC4KDQoFBAQCAgMSBOoBMTJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Dataflow::V1beta3::Messages::JobMessage ===
    # Fields for JobMessage
    # Field: id Type: 9 ()
    # Field: time Type: 11 (.google.protobuf.Timestamp)
    # Field: message_text Type: 9 ()
    # Field: message_importance Type: 14 (.google.dataflow.v1beta3.JobMessageImportance)

=pod

=head1 NAME

Google::Dataflow::V1beta3::Messages::JobMessage - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Messages;

    my $msg = Google::Dataflow::V1beta3::Messages::JobMessage->new(
        id => $value,
    );

=head1 FIELDS

=over 4

=item * B<id>

Type: String

=item * B<time>

Type: Message (.google.protobuf.Timestamp)

=item * B<message_text>

Type: String

=item * B<message_importance>

Type: Enum (.google.dataflow.v1beta3.JobMessageImportance)

=back

=cut

# === Message: Google::Dataflow::V1beta3::Messages::StructuredMessage ===
    # Fields for StructuredMessage
    # Field: message_text Type: 9 ()
    # Field: message_key Type: 9 ()
    # Field: parameters Type: 11 (.google.dataflow.v1beta3.StructuredMessage.Parameter)

=pod

=head1 NAME

Google::Dataflow::V1beta3::Messages::StructuredMessage - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Messages;

    my $msg = Google::Dataflow::V1beta3::Messages::StructuredMessage->new(
        message_text => $value,
    );

=head1 FIELDS

=over 4

=item * B<message_text>

Type: String

=item * B<message_key>

Type: String

=item * B<parameters>

Type: Message (.google.dataflow.v1beta3.StructuredMessage.Parameter)

=back

=cut

# === Message: Google::Dataflow::V1beta3::Messages::AutoscalingEvent ===
    # Fields for AutoscalingEvent
    # Field: current_num_workers Type: 3 ()
    # Field: target_num_workers Type: 3 ()
    # Field: event_type Type: 14 (.google.dataflow.v1beta3.AutoscalingEvent.AutoscalingEventType)
    # Field: description Type: 11 (.google.dataflow.v1beta3.StructuredMessage)
    # Field: time Type: 11 (.google.protobuf.Timestamp)
    # Field: worker_pool Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Messages::AutoscalingEvent - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Messages;

    my $msg = Google::Dataflow::V1beta3::Messages::AutoscalingEvent->new(
        current_num_workers => $value,
    );

=head1 FIELDS

=over 4

=item * B<current_num_workers>

Type: Int64

=item * B<target_num_workers>

Type: Int64

=item * B<event_type>

Type: Enum (.google.dataflow.v1beta3.AutoscalingEvent.AutoscalingEventType)

=item * B<description>

Type: Message (.google.dataflow.v1beta3.StructuredMessage)

=item * B<time>

Type: Message (.google.protobuf.Timestamp)

=item * B<worker_pool>

Type: String

=back

=cut

# Enum: AutoscalingEvent::AutoscalingEventType
our $AutoscalingEvent_TYPE_UNKNOWN = 0;
our $AutoscalingEvent_TARGET_NUM_WORKERS_CHANGED = 1;
our $AutoscalingEvent_CURRENT_NUM_WORKERS_CHANGED = 2;
our $AutoscalingEvent_ACTUATION_FAILURE = 3;
our $AutoscalingEvent_NO_CHANGE = 4;

=pod

=head2 Enum: AutoscalingEvent::AutoscalingEventType

Values:

=over 4

=item * C<TYPE_UNKNOWN> => 0

=item * C<TARGET_NUM_WORKERS_CHANGED> => 1

=item * C<CURRENT_NUM_WORKERS_CHANGED> => 2

=item * C<ACTUATION_FAILURE> => 3

=item * C<NO_CHANGE> => 4

=back

=cut

# === Message: Google::Dataflow::V1beta3::Messages::ListJobMessagesRequest ===
    # Fields for ListJobMessagesRequest
    # Field: project_id Type: 9 ()
    # Field: job_id Type: 9 ()
    # Field: minimum_importance Type: 14 (.google.dataflow.v1beta3.JobMessageImportance)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Dataflow::V1beta3::Messages::ListJobMessagesRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Messages;

    my $msg = Google::Dataflow::V1beta3::Messages::ListJobMessagesRequest->new(
        project_id => $value,
    );

=head1 FIELDS

=over 4

=item * B<project_id>

Type: String

=item * B<job_id>

Type: String

=item * B<minimum_importance>

Type: Enum (.google.dataflow.v1beta3.JobMessageImportance)

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=item * B<start_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<end_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse ===
    # Fields for ListJobMessagesResponse
    # Field: job_messages Type: 11 (.google.dataflow.v1beta3.JobMessage)
    # Field: next_page_token Type: 9 ()
    # Field: autoscaling_events Type: 11 (.google.dataflow.v1beta3.AutoscalingEvent)

=pod

=head1 NAME

Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Messages;

    my $msg = Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse->new(
        job_messages => $value,
    );

=head1 FIELDS

=over 4

=item * B<job_messages>

Type: Message (.google.dataflow.v1beta3.JobMessage)

=item * B<next_page_token>

Type: String

=item * B<autoscaling_events>

Type: Message (.google.dataflow.v1beta3.AutoscalingEvent)

=back

=cut

# === Service Client: Google::Dataflow::V1beta3::Messages::MessagesV1beta3Client ===
package Google::Dataflow::V1beta3::Messages::MessagesV1beta3Client;

=pod

=head1 NAME

Google::Dataflow::V1beta3::Messages::MessagesV1beta3Client - Client stub representing the remote MessagesV1Beta3 service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<dataflow.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataflow.googleapis.com:443' );

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

sub list_job_messages {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Dataflow::V1beta3::Messages::ListJobMessagesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.dataflow.v1beta3.MessagesV1Beta3',
        method         => 'ListJobMessages',
        request        => $req,
        response_class => 'Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse',
    });
}

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Messages - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
