package Google::Cloud::Datalabeling::V1beta1::Dataset;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Datalabeling::V1beta1::Annotation };
    eval { require Google::Cloud::Datalabeling::V1beta1::AnnotationSpecSet };
    eval { require Google::Cloud::Datalabeling::V1beta1::DataPayloads };
    eval { require Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvZGF0YXNldC5wcm90bxIhZ29v
Z2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGjJnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvYW5ub3RhdGlvbi5wcm90
bxo7Z29vZ2xlL2Nsb3VkL2RhdGFsYWJlbGluZy92MWJldGExL2Fubm90YXRpb25fc3BlY19z
ZXQucHJvdG8aNWdvb2dsZS9jbG91ZC9kYXRhbGFiZWxpbmcvdjFiZXRhMS9kYXRhX3BheWxv
YWRzLnByb3RvGj9nb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvaHVtYW5fYW5u
b3RhdGlvbl9jb25maWcucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
nAMKB0RhdGFzZXQSEgoEbmFtZRgBIAEoCVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlS
C2Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbhI7CgtjcmVh
dGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUS
UwoNaW5wdXRfY29uZmlncxgFIAMoCzIuLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFi
ZXRhMS5JbnB1dENvbmZpZ1IMaW5wdXRDb25maWdzEi0KEmJsb2NraW5nX3Jlc291cmNlcxgG
IAMoCVIRYmxvY2tpbmdSZXNvdXJjZXMSJgoPZGF0YV9pdGVtX2NvdW50GAcgASgDUg1kYXRh
SXRlbUNvdW50Ok/qQUwKI2RhdGFsYWJlbGluZy5nb29nbGVhcGlzLmNvbS9EYXRhc2V0EiVw
cm9qZWN0cy97cHJvamVjdH0vZGF0YXNldHMve2RhdGFzZXR9IswECgtJbnB1dENvbmZpZxJW
Cg10ZXh0X21ldGFkYXRhGAYgASgLMi8uZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJl
dGExLlRleHRNZXRhZGF0YUgAUgx0ZXh0TWV0YWRhdGESTQoKZ2NzX3NvdXJjZRgCIAEoCzIs
Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5HY3NTb3VyY2VIAVIJZ2NzU291
cmNlElwKD2JpZ3F1ZXJ5X3NvdXJjZRgFIAEoCzIxLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxp
bmcudjFiZXRhMS5CaWdRdWVyeVNvdXJjZUgBUg5iaWdxdWVyeVNvdXJjZRJICglkYXRhX3R5
cGUYASABKA4yKy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRGF0YVR5cGVS
CGRhdGFUeXBlEloKD2Fubm90YXRpb25fdHlwZRgDIAEoDjIxLmdvb2dsZS5jbG91ZC5kYXRh
bGFiZWxpbmcudjFiZXRhMS5Bbm5vdGF0aW9uVHlwZVIOYW5ub3RhdGlvblR5cGUScgoXY2xh
c3NpZmljYXRpb25fbWV0YWRhdGEYBCABKAsyOS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5n
LnYxYmV0YTEuQ2xhc3NpZmljYXRpb25NZXRhZGF0YVIWY2xhc3NpZmljYXRpb25NZXRhZGF0
YUIUChJkYXRhX3R5cGVfbWV0YWRhdGFCCAoGc291cmNlIjMKDFRleHRNZXRhZGF0YRIjCg1s
YW5ndWFnZV9jb2RlGAEgASgJUgxsYW5ndWFnZUNvZGUiPgoWQ2xhc3NpZmljYXRpb25NZXRh
ZGF0YRIkCg5pc19tdWx0aV9sYWJlbBgBIAEoCFIMaXNNdWx0aUxhYmVsIkUKCUdjc1NvdXJj
ZRIbCglpbnB1dF91cmkYASABKAlSCGlucHV0VXJpEhsKCW1pbWVfdHlwZRgCIAEoCVIIbWlt
ZVR5cGUiLQoOQmlnUXVlcnlTb3VyY2USGwoJaW5wdXRfdXJpGAEgASgJUghpbnB1dFVyaSLs
AQoMT3V0cHV0Q29uZmlnElwKD2djc19kZXN0aW5hdGlvbhgBIAEoCzIxLmdvb2dsZS5jbG91
ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5HY3NEZXN0aW5hdGlvbkgAUg5nY3NEZXN0aW5hdGlv
bhJvChZnY3NfZm9sZGVyX2Rlc3RpbmF0aW9uGAIgASgLMjcuZ29vZ2xlLmNsb3VkLmRhdGFs
YWJlbGluZy52MWJldGExLkdjc0ZvbGRlckRlc3RpbmF0aW9uSABSFGdjc0ZvbGRlckRlc3Rp
bmF0aW9uQg0KC2Rlc3RpbmF0aW9uIkwKDkdjc0Rlc3RpbmF0aW9uEh0KCm91dHB1dF91cmkY
ASABKAlSCW91dHB1dFVyaRIbCgltaW1lX3R5cGUYAiABKAlSCG1pbWVUeXBlIkIKFEdjc0Zv
bGRlckRlc3RpbmF0aW9uEioKEW91dHB1dF9mb2xkZXJfdXJpGAEgASgJUg9vdXRwdXRGb2xk
ZXJVcmkilgMKCERhdGFJdGVtElYKDWltYWdlX3BheWxvYWQYAiABKAsyLy5nb29nbGUuY2xv
dWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuSW1hZ2VQYXlsb2FkSABSDGltYWdlUGF5bG9hZBJT
Cgx0ZXh0X3BheWxvYWQYAyABKAsyLi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuVGV4dFBheWxvYWRIAFILdGV4dFBheWxvYWQSVgoNdmlkZW9fcGF5bG9hZBgEIAEoCzIv
Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5WaWRlb1BheWxvYWRIAFIMdmlk
ZW9QYXlsb2FkEhIKBG5hbWUYASABKAlSBG5hbWU6ZupBYwokZGF0YWxhYmVsaW5nLmdvb2ds
ZWFwaXMuY29tL0RhdGFJdGVtEjtwcm9qZWN0cy97cHJvamVjdH0vZGF0YXNldHMve2RhdGFz
ZXR9L2RhdGFJdGVtcy97ZGF0YV9pdGVtfUIJCgdwYXlsb2FkIpsGChBBbm5vdGF0ZWREYXRh
c2V0EhIKBG5hbWUYASABKAlSBG5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5
TmFtZRIgCgtkZXNjcmlwdGlvbhgJIAEoCVILZGVzY3JpcHRpb24SYAoRYW5ub3RhdGlvbl9z
b3VyY2UYAyABKA4yMy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3Rh
dGlvblNvdXJjZVIQYW5ub3RhdGlvblNvdXJjZRJaCg9hbm5vdGF0aW9uX3R5cGUYCCABKA4y
MS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvblR5cGVSDmFu
bm90YXRpb25UeXBlEiMKDWV4YW1wbGVfY291bnQYBCABKANSDGV4YW1wbGVDb3VudBI2Chdj
b21wbGV0ZWRfZXhhbXBsZV9jb3VudBgFIAEoA1IVY29tcGxldGVkRXhhbXBsZUNvdW50Ek4K
C2xhYmVsX3N0YXRzGAYgASgLMi0uZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGEx
LkxhYmVsU3RhdHNSCmxhYmVsU3RhdHMSOwoLY3JlYXRlX3RpbWUYByABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lElcKCG1ldGFkYXRhGAogASgLMjsuZ29v
Z2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkFubm90YXRlZERhdGFzZXRNZXRhZGF0
YVIIbWV0YWRhdGESLQoSYmxvY2tpbmdfcmVzb3VyY2VzGAsgAygJUhFibG9ja2luZ1Jlc291
cmNlczp+6kF7CixkYXRhbGFiZWxpbmcuZ29vZ2xlYXBpcy5jb20vQW5ub3RhdGVkRGF0YXNl
dBJLcHJvamVjdHMve3Byb2plY3R9L2RhdGFzZXRzL3tkYXRhc2V0fS9hbm5vdGF0ZWREYXRh
c2V0cy97YW5ub3RhdGVkX2RhdGFzZXR9IrMBCgpMYWJlbFN0YXRzEmQKDWV4YW1wbGVfY291
bnQYASADKAsyPy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuTGFiZWxTdGF0
cy5FeGFtcGxlQ291bnRFbnRyeVIMZXhhbXBsZUNvdW50Gj8KEUV4YW1wbGVDb3VudEVudHJ5
EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgDUgV2YWx1ZToCOAEimAoKGEFubm90
YXRlZERhdGFzZXRNZXRhZGF0YRJ+ChtpbWFnZV9jbGFzc2lmaWNhdGlvbl9jb25maWcYAiAB
KAsyPC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuSW1hZ2VDbGFzc2lmaWNh
dGlvbkNvbmZpZ0gAUhlpbWFnZUNsYXNzaWZpY2F0aW9uQ29uZmlnEmkKFGJvdW5kaW5nX3Bv
bHlfY29uZmlnGAMgASgLMjUuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkJv
dW5kaW5nUG9seUNvbmZpZ0gAUhJib3VuZGluZ1BvbHlDb25maWcSXAoPcG9seWxpbmVfY29u
ZmlnGAQgASgLMjEuZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLlBvbHlsaW5l
Q29uZmlnSABSDnBvbHlsaW5lQ29uZmlnEmgKE3NlZ21lbnRhdGlvbl9jb25maWcYBSABKAsy
NS5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuU2VnbWVudGF0aW9uQ29uZmln
SABSEnNlZ21lbnRhdGlvbkNvbmZpZxJ+Cht2aWRlb19jbGFzc2lmaWNhdGlvbl9jb25maWcY
BiABKAsyPC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuVmlkZW9DbGFzc2lm
aWNhdGlvbkNvbmZpZ0gAUhl2aWRlb0NsYXNzaWZpY2F0aW9uQ29uZmlnEnIKF29iamVjdF9k
ZXRlY3Rpb25fY29uZmlnGAcgASgLMjguZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJl
dGExLk9iamVjdERldGVjdGlvbkNvbmZpZ0gAUhVvYmplY3REZXRlY3Rpb25Db25maWcSbwoW
b2JqZWN0X3RyYWNraW5nX2NvbmZpZxgIIAEoCzI3Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxp
bmcudjFiZXRhMS5PYmplY3RUcmFja2luZ0NvbmZpZ0gAUhRvYmplY3RUcmFja2luZ0NvbmZp
ZxJTCgxldmVudF9jb25maWcYCSABKAsyLi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYx
YmV0YTEuRXZlbnRDb25maWdIAFILZXZlbnRDb25maWcSewoadGV4dF9jbGFzc2lmaWNhdGlv
bl9jb25maWcYCiABKAsyOy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuVGV4
dENsYXNzaWZpY2F0aW9uQ29uZmlnSABSGHRleHRDbGFzc2lmaWNhdGlvbkNvbmZpZxKCAQod
dGV4dF9lbnRpdHlfZXh0cmFjdGlvbl9jb25maWcYCyABKAsyPS5nb29nbGUuY2xvdWQuZGF0
YWxhYmVsaW5nLnYxYmV0YTEuVGV4dEVudGl0eUV4dHJhY3Rpb25Db25maWdIAFIadGV4dEVu
dGl0eUV4dHJhY3Rpb25Db25maWcScAoXaHVtYW5fYW5ub3RhdGlvbl9jb25maWcYASABKAsy
OC5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuSHVtYW5Bbm5vdGF0aW9uQ29u
ZmlnUhVodW1hbkFubm90YXRpb25Db25maWdCGwoZYW5ub3RhdGlvbl9yZXF1ZXN0X2NvbmZp
ZyKKBAoHRXhhbXBsZRJWCg1pbWFnZV9wYXlsb2FkGAIgASgLMi8uZ29vZ2xlLmNsb3VkLmRh
dGFsYWJlbGluZy52MWJldGExLkltYWdlUGF5bG9hZEgAUgxpbWFnZVBheWxvYWQSUwoMdGV4
dF9wYXlsb2FkGAYgASgLMi4uZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLlRl
eHRQYXlsb2FkSABSC3RleHRQYXlsb2FkElYKDXZpZGVvX3BheWxvYWQYByABKAsyLy5nb29n
bGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuVmlkZW9QYXlsb2FkSABSDHZpZGVvUGF5
bG9hZBISCgRuYW1lGAEgASgJUgRuYW1lEk8KC2Fubm90YXRpb25zGAUgAygLMi0uZ29vZ2xl
LmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkFubm90YXRpb25SC2Fubm90YXRpb25zOokB
6kGFAQojZGF0YWxhYmVsaW5nLmdvb2dsZWFwaXMuY29tL0V4YW1wbGUSXnByb2plY3RzL3tw
cm9qZWN0fS9kYXRhc2V0cy97ZGF0YXNldH0vYW5ub3RhdGVkRGF0YXNldHMve2Fubm90YXRl
ZF9kYXRhc2V0fS9leGFtcGxlcy97ZXhhbXBsZX1CCQoHcGF5bG9hZCpXCghEYXRhVHlwZRIZ
ChVEQVRBX1RZUEVfVU5TUEVDSUZJRUQQABIJCgVJTUFHRRABEgkKBVZJREVPEAISCAoEVEVY
VBAEEhAKDEdFTkVSQUxfREFUQRAGQuMBCiVjb20uZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGlu
Zy52MWJldGExUAFaSWNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YWxhYmVsaW5nL2FwaXYxYmV0
YTEvZGF0YWxhYmVsaW5ncGI7ZGF0YWxhYmVsaW5ncGKqAiFHb29nbGUuQ2xvdWQuRGF0YUxh
YmVsaW5nLlYxQmV0YTHKAiFHb29nbGVcQ2xvdWRcRGF0YUxhYmVsaW5nXFYxYmV0YTHqAiRH
b29nbGU6OkNsb3VkOjpEYXRhTGFiZWxpbmc6OlYxYmV0YTFKsV0KBxIFDwDaAgEKvQQKAQwS
Aw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAqCgkKAgMAEgMTACMKCQoC
AwESAxQAPAoJCgIDAhIDFQBFCgkKAgMDEgMWAD8KCQoCAwQSAxcASQoJCgIDBRIDGAApCggK
AQgSAxoAPgoJCgIIJRIDGgA+CggKAQgSAxsAYAoJCgIICxIDGwBgCggKAQgSAxwAIgoJCgII
ChIDHAAiCggKAQgSAx0APgoJCgIIARIDHQA+CggKAQgSAx4APgoJCgIIKRIDHgA+CggKAQgS
Ax8APQoJCgIILRIDHwA9CgoKAgUAEgQhAC4BCgoKAwUAARIDIQUNCgsKBAUAAgASAyICHAoM
CgUFAAIAARIDIgIXCgwKBQUAAgACEgMiGhsKMQoEBQACARIDJQIMGiQgQWxsb3dlZCBmb3Ig
Y29udGludW91cyBldmFsdWF0aW9uLgoKDAoFBQACAQESAyUCBwoMCgUFAAIBAhIDJQoLCgsK
BAUAAgISAycCDAoMCgUFAAICARIDJwIHCgwKBQUAAgICEgMnCgsKMQoEBQACAxIDKgILGiQg
QWxsb3dlZCBmb3IgY29udGludW91cyBldmFsdWF0aW9uLgoKDAoFBQACAwESAyoCBgoMCgUF
AAIDAhIDKgkKCjEKBAUAAgQSAy0CExokIEFsbG93ZWQgZm9yIGNvbnRpbnVvdXMgZXZhbHVh
dGlvbi4KCgwKBQUAAgQBEgMtAg4KDAoFBQACBAISAy0REgqiAQoCBAASBDIAUQEalQEgRGF0
YXNldCBpcyB0aGUgcmVzb3VyY2UgdG8gaG9sZCB5b3VyIGRhdGEuIFlvdSBjYW4gcmVxdWVz
dCBtdWx0aXBsZSBsYWJlbGluZwogdGFza3MgZm9yIGEgZGF0YXNldCB3aGlsZSBlYWNoIG9u
ZSB3aWxsIGdlbmVyYXRlIGFuIEFubm90YXRlZERhdGFzZXQuCgoKCgMEAAESAzIIDwoLCgME
AAcSBDMCNgQKDQoFBAAHnQgSBDMCNgQKagoEBAACABIDOgISGl0gT3V0cHV0IG9ubHkuIERh
dGFzZXQgcmVzb3VyY2UgbmFtZSwgZm9ybWF0IGlzOgogcHJvamVjdHMve3Byb2plY3RfaWR9
L2RhdGFzZXRzL3tkYXRhc2V0X2lkfQoKDAoFBAACAAUSAzoCCAoMCgUEAAIAARIDOgkNCgwK
BQQAAgADEgM6EBEKUwoEBAACARIDPQIaGkYgUmVxdWlyZWQuIFRoZSBkaXNwbGF5IG5hbWUg
b2YgdGhlIGRhdGFzZXQuIE1heGltdW0gb2YgNjQgY2hhcmFjdGVycy4KCgwKBQQAAgEFEgM9
AggKDAoFBAACAQESAz0JFQoMCgUEAAIBAxIDPRgZCowBCgQEAAICEgNBAhkafyBPcHRpb25h
bC4gVXNlci1wcm92aWRlZCBkZXNjcmlwdGlvbiBvZiB0aGUgYW5ub3RhdGlvbiBzcGVjaWZp
Y2F0aW9uIHNldC4KIFRoZSBkZXNjcmlwdGlvbiBjYW4gYmUgdXAgdG8gMTAwMDAgY2hhcmFj
dGVycyBsb25nLgoKDAoFBAACAgUSA0ECCAoMCgUEAAICARIDQQkUCgwKBQQAAgIDEgNBFxgK
OAoEBAACAxIDRAIsGisgT3V0cHV0IG9ubHkuIFRpbWUgdGhlIGRhdGFzZXQgaXMgY3JlYXRl
ZC4KCgwKBQQAAgMGEgNEAhsKDAoFBAACAwESA0QcJwoMCgUEAAIDAxIDRCorCrABCgQEAAIE
EgNJAikaogEgT3V0cHV0IG9ubHkuIFRoaXMgaXMgcG9wdWxhdGVkIHdpdGggdGhlIG9yaWdp
bmFsIGlucHV0IGNvbmZpZ3MKIHdoZXJlIEltcG9ydERhdGEgaXMgY2FsbGVkLiBJdCBpcyBh
dmFpbGFibGUgb25seSBhZnRlciB0aGUgY2xpZW50cwogaW1wb3J0IGRhdGEgdG8gdGhpcyBk
YXRhc2V0LgoKDAoFBAACBAQSA0kCCgoMCgUEAAIEBhIDSQsWCgwKBQQAAgQBEgNJFyQKDAoF
BAACBAMSA0knKAppCgQEAAIFEgNNAikaXCBPdXRwdXQgb25seS4gVGhlIG5hbWVzIG9mIGFu
eSByZWxhdGVkIHJlc291cmNlcyB0aGF0IGFyZSBibG9ja2luZyBjaGFuZ2VzCiB0byB0aGUg
ZGF0YXNldC4KCgwKBQQAAgUEEgNNAgoKDAoFBAACBQUSA00LEQoMCgUEAAIFARIDTRIkCgwK
BQQAAgUDEgNNJygKRAoEBAACBhIDUAIcGjcgT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2Yg
ZGF0YSBpdGVtcyBpbiB0aGUgZGF0YXNldC4KCgwKBQQAAgYFEgNQAgcKDAoFBAACBgESA1AI
FwoMCgUEAAIGAxIDUBobClIKAgQBEgRUAHEBGkYgVGhlIGNvbmZpZ3VyYXRpb24gb2YgaW5w
dXQgZGF0YSwgaW5jbHVkaW5nIGRhdGEgdHlwZSwgbG9jYXRpb24sIGV0Yy4KCgoKAwQBARID
VAgTCkYKBAQBCAASBFYCWQMaOCBPcHRpb25hbC4gVGhlIG1ldGFkYXRhIGFzc29jaWF0ZWQg
d2l0aCBlYWNoIGRhdGEgdHlwZS4KCgwKBQQBCAABEgNWCBoKTAoEBAECABIDWAQjGj8gUmVx
dWlyZWQgZm9yIHRleHQgaW1wb3J0LCBhcyBsYW5ndWFnZSBjb2RlIG11c3QgYmUgc3BlY2lm
aWVkLgoKDAoFBAECAAYSA1gEEAoMCgUEAQIAARIDWBEeCgwKBQQBAgADEgNYISIKMQoEBAEI
ARIEXAJjAxojIFJlcXVpcmVkLiBXaGVyZSB0aGUgZGF0YSBpcyBmcm9tLgoKDAoFBAEIAQES
A1wIDgovCgQEAQIBEgNeBB0aIiBTb3VyY2UgbG9jYXRlZCBpbiBDbG91ZCBTdG9yYWdlLgoK
DAoFBAECAQYSA14EDQoMCgUEAQIBARIDXg4YCgwKBQQBAgEDEgNeGxwKsgEKBAQBAgISA2IE
JxqkASBTb3VyY2UgbG9jYXRlZCBpbiBCaWdRdWVyeS4gWW91IG11c3Qgc3BlY2lmeSB0aGlz
IGZpZWxkIGlmIHlvdSBhcmUgdXNpbmcKIHRoaXMgSW5wdXRDb25maWcgaW4gYW4gW0V2YWx1
YXRpb25Kb2JdW2dvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5FdmFsdWF0aW9u
Sm9iXS4KCgwKBQQBAgIGEgNiBBIKDAoFBAECAgESA2ITIgoMCgUEAQICAxIDYiUmClMKBAQB
AgMSA2YCGRpGIFJlcXVpcmVkLiBEYXRhIHR5cGUgbXVzdCBiZSBzcGVjaWZlZCB3aGVuIHVz
ZXIgdHJpZXMgdG8gaW1wb3J0IGRhdGEuCgoMCgUEAQIDBhIDZgIKCgwKBQQBAgMBEgNmCxQK
DAoFBAECAwMSA2YXGArWAQoEBAECBBIDawIlGsgBIE9wdGlvbmFsLiBUaGUgdHlwZSBvZiBh
bm5vdGF0aW9uIHRvIGJlIHBlcmZvcm1lZCBvbiB0aGlzIGRhdGEuIFlvdSBtdXN0CiBzcGVj
aWZ5IHRoaXMgZmllbGQgaWYgeW91IGFyZSB1c2luZyB0aGlzIElucHV0Q29uZmlnIGluIGFu
CiBbRXZhbHVhdGlvbkpvYl1bZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkV2
YWx1YXRpb25Kb2JdLgoKDAoFBAECBAYSA2sCEAoMCgUEAQIEARIDaxEgCgwKBQQBAgQDEgNr
IyQK/AEKBAQBAgUSA3ACNRruASBPcHRpb25hbC4gTWV0YWRhdGEgYWJvdXQgYW5ub3RhdGlv
bnMgZm9yIHRoZSBpbnB1dC4gWW91IG11c3Qgc3BlY2lmeSB0aGlzCiBmaWVsZCBpZiB5b3Ug
YXJlIHVzaW5nIHRoaXMgSW5wdXRDb25maWcgaW4gYW4gW0V2YWx1YXRpb25Kb2JdW2dvb2ds
ZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5FdmFsdWF0aW9uSm9iXSBmb3IgYQogbW9k
ZWwgdmVyc2lvbiB0aGF0IHBlcmZvcm1zIGNsYXNzaWZpY2F0aW9uLgoKDAoFBAECBQYSA3AC
GAoMCgUEAQIFARIDcBkwCgwKBQQBAgUDEgNwMzQKJAoCBAISBHQAeQEaGCBNZXRhZGF0YSBm
b3IgdGhlIHRleHQuCgoKCgMEAgESA3QIFAqAAQoEBAICABIDeAIbGnMgVGhlIGxhbmd1YWdl
IG9mIHRoaXMgdGV4dCwgYXMgYQogW0JDUC00N10oaHR0cHM6Ly93d3cucmZjLWVkaXRvci5v
cmcvcmZjL2JjcC9iY3A0Ny50eHQpLgogRGVmYXVsdCB2YWx1ZSBpcyBlbi1VUy4KCgwKBQQC
AgAFEgN4AggKDAoFBAICAAESA3gJFgoMCgUEAgIAAxIDeBkaCjYKAgQDEgR8AH8BGiogTWV0
YWRhdGEgZm9yIGNsYXNzaWZpY2F0aW9uIGFubm90YXRpb25zLgoKCgoDBAMBEgN8CB4KRQoE
BAMCABIDfgIaGjggV2hldGhlciB0aGUgY2xhc3NpZmljYXRpb24gdGFzayBpcyBtdWx0aS1s
YWJlbCBvciBub3QuCgoMCgUEAwIABRIDfgIGCgwKBQQDAgABEgN+BxUKDAoFBAMCAAMSA34Y
GQpACgIEBBIGggEAiQEBGjIgU291cmNlIG9mIHRoZSBDbG91ZCBTdG9yYWdlIGZpbGUgdG8g
YmUgaW1wb3J0ZWQuCgoLCgMEBAESBIIBCBEKaAoEBAQCABIEhQECFxpaIFJlcXVpcmVkLiBU
aGUgaW5wdXQgVVJJIG9mIHNvdXJjZSBmaWxlLiBUaGlzIG11c3QgYmUgYSBDbG91ZCBTdG9y
YWdlIHBhdGgKIChgZ3M6Ly8uLi5gKS4KCg0KBQQEAgAFEgSFAQIICg0KBQQEAgABEgSFAQkS
Cg0KBQQEAgADEgSFARUWClYKBAQEAgESBIgBAhcaSCBSZXF1aXJlZC4gVGhlIGZvcm1hdCBv
ZiB0aGUgc291cmNlIGZpbGUuIE9ubHkgInRleHQvY3N2IiBpcyBzdXBwb3J0ZWQuCgoNCgUE
BAIBBRIEiAECCAoNCgUEBAIBARIEiAEJEgoNCgUEBAIBAxIEiAEVFgroAQoCBAUSBo4BAJ4B
ARrZASBUaGUgQmlnUXVlcnkgbG9jYXRpb24gZm9yIGlucHV0IGRhdGEuIElmIHVzZWQgaW4g
YW4gW0V2YWx1YXRpb25Kb2JdW2dvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5F
dmFsdWF0aW9uSm9iXSwgdGhpcwogaXMgd2hlcmUgdGhlIHNlcnZpY2Ugc2F2ZXMgdGhlIHBy
ZWRpY3Rpb24gaW5wdXQgYW5kIG91dHB1dCBzYW1wbGVkIGZyb20gdGhlCiBtb2RlbCB2ZXJz
aW9uLgoKCwoDBAUBEgSOAQgWCqkFCgQEBQIAEgSdAQIXGpoFIFJlcXVpcmVkLiBCaWdRdWVy
eSBVUkkgdG8gYSB0YWJsZSwgdXAgdG8gMiwwMDAgY2hhcmFjdGVycyBsb25nLiBJZiB5b3UK
IHNwZWNpZnkgdGhlIFVSSSBvZiBhIHRhYmxlIHRoYXQgZG9lcyBub3QgZXhpc3QsIERhdGEg
TGFiZWxpbmcgU2VydmljZQogY3JlYXRlcyBhIHRhYmxlIGF0IHRoZSBVUkkgd2l0aCB0aGUg
Y29ycmVjdCBzY2hlbWEgd2hlbiB5b3UgY3JlYXRlIHlvdXIKIFtFdmFsdWF0aW9uSm9iXVtn
b29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVhdGlvbkpvYl0uIElmIHlv
dSBzcGVjaWZ5IHRoZSBVUkkgb2YgYSB0YWJsZSB0aGF0IGFscmVhZHkgZXhpc3RzLAogaXQg
bXVzdCBoYXZlIHRoZQogW2NvcnJlY3QKIHNjaGVtYV0oL21sLWVuZ2luZS9kb2NzL2NvbnRp
bnVvdXMtZXZhbHVhdGlvbi9jcmVhdGUtam9iI3RhYmxlLXNjaGVtYSkuCgogUHJvdmlkZSB0
aGUgdGFibGUgVVJJIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgoKICJicTovLzx2YXI+e3lv
dXJfcHJvamVjdF9pZH08L3Zhcj4vPHZhcj57eW91cl9kYXRhc2V0X25hbWV9PC92YXI+Lzx2
YXI+e3lvdXJfdGFibGVfbmFtZX08L3Zhcj4iCgogW0xlYXJuCiBtb3JlXSgvbWwtZW5naW5l
L2RvY3MvY29udGludW91cy1ldmFsdWF0aW9uL2NyZWF0ZS1qb2IjdGFibGUtc2NoZW1hKS4K
Cg0KBQQFAgAFEgSdAQIICg0KBQQFAgABEgSdAQkSCg0KBQQFAgADEgSdARUWCjEKAgQGEgah
AQCsAQEaIyBUaGUgY29uZmlndXJhdGlvbiBvZiBvdXRwdXQgZGF0YS4KCgsKAwQGARIEoQEI
FAo3CgQEBggAEgajAQKrAQMaJyBSZXF1aXJlZC4gTG9jYXRpb24gdG8gb3V0cHV0IGRhdGEg
dG8uCgoNCgUEBggAARIEowEIEwp1CgQEBgIAEgSmAQQnGmcgT3V0cHV0IHRvIGEgZmlsZSBp
biBDbG91ZCBTdG9yYWdlLiBTaG91bGQgYmUgdXNlZCBmb3IgbGFiZWxpbmcgb3V0cHV0CiBv
dGhlciB0aGFuIGltYWdlIHNlZ21lbnRhdGlvbi4KCg0KBQQGAgAGEgSmAQQSCg0KBQQGAgAB
EgSmARMiCg0KBQQGAgADEgSmASUmCmwKBAQGAgESBKoBBDQaXiBPdXRwdXQgdG8gYSBmb2xk
ZXIgaW4gQ2xvdWQgU3RvcmFnZS4gU2hvdWxkIGJlIHVzZWQgZm9yIGltYWdlCiBzZWdtZW50
YXRpb24gbGFiZWxpbmcgb3V0cHV0LgoKDQoFBAYCAQYSBKoBBBgKDQoFBAYCAQESBKoBGS8K
DQoFBAYCAQMSBKoBMjMKVwoCBAcSBrABALgBARpJIEV4cG9ydCBkZXN0aW5hdGlvbiBvZiB0
aGUgZGF0YS5Pbmx5IGdjcyBwYXRoIGlzIGFsbG93ZWQgaW4KIG91dHB1dF91cmkuCgoLCgME
BwESBLABCBYKPQoEBAcCABIEsgECGBovIFJlcXVpcmVkLiBUaGUgb3V0cHV0IHVyaSBvZiBk
ZXN0aW5hdGlvbiBmaWxlLgoKDQoFBAcCAAUSBLIBAggKDQoFBAcCAAESBLIBCRMKDQoFBAcC
AAMSBLIBFhcKdAoEBAcCARIEtwECFxpmIFJlcXVpcmVkLiBUaGUgZm9ybWF0IG9mIHRoZSBn
Y3MgZGVzdGluYXRpb24uIE9ubHkgInRleHQvY3N2IiBhbmQKICJhcHBsaWNhdGlvbi9qc29u
IgogYXJlIHN1cHBvcnRlZC4KCg0KBQQHAgEFEgS3AQIICg0KBQQHAgEBEgS3AQkSCg0KBQQH
AgEDEgS3ARUWCjYKAgQIEga7AQC+AQEaKCBFeHBvcnQgZm9sZGVyIGRlc3RpbmF0aW9uIG9m
IHRoZSBkYXRhLgoKCwoDBAgBEgS7AQgcCkQKBAQIAgASBL0BAh8aNiBSZXF1aXJlZC4gQ2xv
dWQgU3RvcmFnZSBkaXJlY3RvcnkgdG8gZXhwb3J0IGRhdGEgdG8uCgoNCgUECAIABRIEvQEC
CAoNCgUECAIAARIEvQEJGgoNCgUECAIAAxIEvQEdHgpXCgIECRIGwQEA1gEBGkkgRGF0YUl0
ZW0gaXMgYSBwaWVjZSBvZiBkYXRhLCB3aXRob3V0IGFubm90YXRpb24uIEZvciBleGFtcGxl
LCBhbiBpbWFnZS4KCgsKAwQJARIEwQEIEAoNCgMECQcSBsIBAsUBBAoPCgUECQedCBIGwgEC
xQEECh4KBAQJCAASBsgBAtEBAxoOIE91dHB1dCBvbmx5LgoKDQoFBAkIAAESBMgBCA8KRgoE
BAkCABIEygEEIxo4IFRoZSBpbWFnZSBwYXlsb2FkLCBhIGNvbnRhaW5lciBvZiB0aGUgaW1h
Z2UgYnl0ZXMvdXJpLgoKDQoFBAkCAAYSBMoBBBAKDQoFBAkCAAESBMoBER4KDQoFBAkCAAMS
BMoBISIKPgoEBAkCARIEzQEEIRowIFRoZSB0ZXh0IHBheWxvYWQsIGEgY29udGFpbmVyIG9m
IHRleHQgY29udGVudC4KCg0KBQQJAgEGEgTNAQQPCg0KBQQJAgEBEgTNARAcCg0KBQQJAgED
EgTNAR8gCkAKBAQJAgISBNABBCMaMiBUaGUgdmlkZW8gcGF5bG9hZCwgYSBjb250YWluZXIg
b2YgdGhlIHZpZGVvIHVyaS4KCg0KBQQJAgIGEgTQAQQQCg0KBQQJAgIBEgTQAREeCg0KBQQJ
AgIDEgTQASEiCocBCgQECQIDEgTVAQISGnkgT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIGRh
dGEgaXRlbSwgaW4gZm9ybWF0IG9mOgogcHJvamVjdHMve3Byb2plY3RfaWR9L2RhdGFzZXRz
L3tkYXRhc2V0X2lkfS9kYXRhSXRlbXMve2RhdGFfaXRlbV9pZH0KCg0KBQQJAgMFEgTVAQII
Cg0KBQQJAgMBEgTVAQkNCg0KBQQJAgMDEgTVARARCr4BCgIEChIG2wEAigIBGq8BIEFubm90
YXRlZERhdGFzZXQgaXMgYSBzZXQgaG9sZGluZyBhbm5vdGF0aW9ucyBmb3IgZGF0YSBpbiBh
IERhdGFzZXQuIEVhY2gKIGxhYmVsaW5nIHRhc2sgd2lsbCBnZW5lcmF0ZSBhbiBBbm5vdGF0
ZWREYXRhc2V0IHVuZGVyIHRoZSBEYXRhc2V0IHRoYXQgdGhlCiB0YXNrIGlzIHJlcXVlc3Rl
ZCBmb3IuCgoLCgMECgESBNsBCBgKDQoDBAoHEgbcAQLfAQQKDwoFBAoHnQgSBtwBAt8BBAqi
AQoEBAoCABIE5AECEhqTASBPdXRwdXQgb25seS4gQW5ub3RhdGVkRGF0YXNldCByZXNvdXJj
ZSBuYW1lIGluIGZvcm1hdCBvZjoKIHByb2plY3RzL3twcm9qZWN0X2lkfS9kYXRhc2V0cy97
ZGF0YXNldF9pZH0vYW5ub3RhdGVkRGF0YXNldHMvCiB7YW5ub3RhdGVkX2RhdGFzZXRfaWR9
CgoNCgUECgIABRIE5AECCAoNCgUECgIAARIE5AEJDQoNCgUECgIAAxIE5AEQEQquAQoEBAoC
ARIE6QECGhqfASBPdXRwdXQgb25seS4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgQW5ub3Rh
dGVkRGF0YXNldC4gSXQgaXMgc3BlY2lmaWVkIGluCiBIdW1hbkFubm90YXRpb25Db25maWcg
d2hlbiB1c2VyIHN0YXJ0cyBhIGxhYmVsaW5nIHRhc2suIE1heGltdW0gb2YgNjQKIGNoYXJh
Y3RlcnMuCgoNCgUECgIBBRIE6QECCAoNCgUECgIBARIE6QEJFQoNCgUECgIBAxIE6QEYGQqw
AQoEBAoCAhIE7gECGRqhASBPdXRwdXQgb25seS4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBB
bm5vdGF0ZWREYXRhc2V0LiBJdCBpcyBzcGVjaWZpZWQgaW4KIEh1bWFuQW5ub3RhdGlvbkNv
bmZpZyB3aGVuIHVzZXIgc3RhcnRzIGEgbGFiZWxpbmcgdGFzay4gTWF4aW11bSBvZiAxMDAw
MAogY2hhcmFjdGVycy4KCg0KBQQKAgIFEgTuAQIICg0KBQQKAgIBEgTuAQkUCg0KBQQKAgID
EgTuARcYCjYKBAQKAgMSBPEBAikaKCBPdXRwdXQgb25seS4gU291cmNlIG9mIHRoZSBhbm5v
dGF0aW9uLgoKDQoFBAoCAwYSBPEBAhIKDQoFBAoCAwESBPEBEyQKDQoFBAoCAwMSBPEBJygK
YgoEBAoCBBIE9QECJRpUIE91dHB1dCBvbmx5LiBUeXBlIG9mIHRoZSBhbm5vdGF0aW9uLiBJ
dCBpcyBzcGVjaWZpZWQgd2hlbiBzdGFydGluZyBsYWJlbGluZwogdGFzay4KCg0KBQQKAgQG
EgT1AQIQCg0KBQQKAgQBEgT1AREgCg0KBQQKAgQDEgT1ASMkCkkKBAQKAgUSBPgBAhoaOyBP
dXRwdXQgb25seS4gTnVtYmVyIG9mIGV4YW1wbGVzIGluIHRoZSBhbm5vdGF0ZWQgZGF0YXNl
dC4KCg0KBQQKAgUFEgT4AQIHCg0KBQQKAgUBEgT4AQgVCg0KBQQKAgUDEgT4ARgZCl8KBAQK
AgYSBPwBAiQaUSBPdXRwdXQgb25seS4gTnVtYmVyIG9mIGV4YW1wbGVzIHRoYXQgaGF2ZSBh
bm5vdGF0aW9uIGluIHRoZSBhbm5vdGF0ZWQKIGRhdGFzZXQuCgoNCgUECgIGBRIE/AECBwoN
CgUECgIGARIE/AEIHwoNCgUECgIGAxIE/AEiIwoyCgQECgIHEgT/AQIdGiQgT3V0cHV0IG9u
bHkuIFBlciBsYWJlbCBzdGF0aXN0aWNzLgoKDQoFBAoCBwYSBP8BAgwKDQoFBAoCBwESBP8B
DRgKDQoFBAoCBwMSBP8BGxwKQwoEBAoCCBIEggICLBo1IE91dHB1dCBvbmx5LiBUaW1lIHRo
ZSBBbm5vdGF0ZWREYXRhc2V0IHdhcyBjcmVhdGVkLgoKDQoFBAoCCAYSBIICAhsKDQoFBAoC
CAESBIICHCcKDQoFBAoCCAMSBIICKisKSwoEBAoCCRIEhQICKRo9IE91dHB1dCBvbmx5LiBB
ZGRpdGlvbmFsIGluZm9ybWF0aW9uIGFib3V0IEFubm90YXRlZERhdGFzZXQuCgoNCgUECgIJ
BhIEhQICGgoNCgUECgIJARIEhQIbIwoNCgUECgIJAxIEhQImKAp0CgQECgIKEgSJAgIqGmYg
T3V0cHV0IG9ubHkuIFRoZSBuYW1lcyBvZiBhbnkgcmVsYXRlZCByZXNvdXJjZXMgdGhhdCBh
cmUgYmxvY2tpbmcgY2hhbmdlcwogdG8gdGhlIGFubm90YXRlZCBkYXRhc2V0LgoKDQoFBAoC
CgQSBIkCAgoKDQoFBAoCCgUSBIkCCxEKDQoFBAoCCgESBIkCEiQKDQoFBAoCCgMSBIkCJykK
MgoCBAsSBo0CAJQCARokIFN0YXRpc3RpY3MgYWJvdXQgYW5ub3RhdGlvbiBzcGVjcy4KCgsK
AwQLARIEjQIIEgq+AgoEBAsCABIEkwICJxqvAiBNYXAgb2YgZWFjaCBhbm5vdGF0aW9uIHNw
ZWMncyBleGFtcGxlIGNvdW50LiBLZXkgaXMgdGhlIGFubm90YXRpb24gc3BlYwogbmFtZSBh
bmQgdmFsdWUgaXMgdGhlIG51bWJlciBvZiBleGFtcGxlcyBmb3IgdGhhdCBhbm5vdGF0aW9u
IHNwZWMuCiBJZiB0aGUgYW5ub3RhdGVkIGRhdGFzZXQgZG9lcyBub3QgaGF2ZSBhbm5vdGF0
aW9uIHNwZWMsIHRoZSBtYXAgd2lsbCByZXR1cm4KIGEgcGFpciB3aGVyZSB0aGUga2V5IGlz
IGVtcHR5IHN0cmluZyBhbmQgdmFsdWUgaXMgdGhlIHRvdGFsIG51bWJlciBvZgogYW5ub3Rh
dGlvbnMuCgoNCgUECwIABhIEkwICFAoNCgUECwIAARIEkwIVIgoNCgUECwIAAxIEkwIlJgot
CgIEDBIGlwIAvAIBGh8gTWV0YWRhdGEgb24gQW5ub3RhdGVkRGF0YXNldC4KCgsKAwQMARIE
lwIIIApYCgQEDAgAEgaZAgK3AgMaSCBTcGVjaWZpYyByZXF1ZXN0IGNvbmZpZ3VyYXRpb24g
dXNlZCB3aGVuIHJlcXVlc3RpbmcgdGhlIGxhYmVsaW5nIHRhc2suCgoNCgUEDAgAARIEmQII
IQo8CgQEDAIAEgSbAgQ+Gi4gQ29uZmlndXJhdGlvbiBmb3IgaW1hZ2UgY2xhc3NpZmljYXRp
b24gdGFzay4KCg0KBQQMAgAGEgSbAgQdCg0KBQQMAgABEgSbAh45Cg0KBQQMAgADEgSbAjw9
CkwKBAQMAgESBJ4CBDAaPiBDb25maWd1cmF0aW9uIGZvciBpbWFnZSBib3VuZGluZyBib3gg
YW5kIGJvdW5kaW5nIHBvbHkgdGFzay4KCg0KBQQMAgEGEgSeAgQWCg0KBQQMAgEBEgSeAhcr
Cg0KBQQMAgEDEgSeAi4vCjYKBAQMAgISBKECBCcaKCBDb25maWd1cmF0aW9uIGZvciBpbWFn
ZSBwb2x5bGluZSB0YXNrLgoKDQoFBAwCAgYSBKECBBIKDQoFBAwCAgESBKECEyIKDQoFBAwC
AgMSBKECJSYKOgoEBAwCAxIEpAIELxosIENvbmZpZ3VyYXRpb24gZm9yIGltYWdlIHNlZ21l
bnRhdGlvbiB0YXNrLgoKDQoFBAwCAwYSBKQCBBYKDQoFBAwCAwESBKQCFyoKDQoFBAwCAwMS
BKQCLS4KPAoEBAwCBBIEpwIEPhouIENvbmZpZ3VyYXRpb24gZm9yIHZpZGVvIGNsYXNzaWZp
Y2F0aW9uIHRhc2suCgoNCgUEDAIEBhIEpwIEHQoNCgUEDAIEARIEpwIeOQoNCgUEDAIEAxIE
pwI8PQo+CgQEDAIFEgSqAgQ2GjAgQ29uZmlndXJhdGlvbiBmb3IgdmlkZW8gb2JqZWN0IGRl
dGVjdGlvbiB0YXNrLgoKDQoFBAwCBQYSBKoCBBkKDQoFBAwCBQESBKoCGjEKDQoFBAwCBQMS
BKoCNDUKPQoEBAwCBhIErQIENBovIENvbmZpZ3VyYXRpb24gZm9yIHZpZGVvIG9iamVjdCB0
cmFja2luZyB0YXNrLgoKDQoFBAwCBgYSBK0CBBgKDQoFBAwCBgESBK0CGS8KDQoFBAwCBgMS
BK0CMjMKPAoEBAwCBxIEsAIEIRouIENvbmZpZ3VyYXRpb24gZm9yIHZpZGVvIGV2ZW50IGxh
YmVsaW5nIHRhc2suCgoNCgUEDAIHBhIEsAIEDwoNCgUEDAIHARIEsAIQHAoNCgUEDAIHAxIE
sAIfIAo7CgQEDAIIEgSzAgQ9Gi0gQ29uZmlndXJhdGlvbiBmb3IgdGV4dCBjbGFzc2lmaWNh
dGlvbiB0YXNrLgoKDQoFBAwCCAYSBLMCBBwKDQoFBAwCCAESBLMCHTcKDQoFBAwCCAMSBLMC
OjwKPgoEBAwCCRIEtgIEQhowIENvbmZpZ3VyYXRpb24gZm9yIHRleHQgZW50aXR5IGV4dHJh
Y3Rpb24gdGFzay4KCg0KBQQMAgkGEgS2AgQeCg0KBQQMAgkBEgS2Ah88Cg0KBQQMAgkDEgS2
Aj9BCm4KBAQMAgoSBLsCAjQaYCBIdW1hbkFubm90YXRpb25Db25maWcgdXNlZCB3aGVuIHJl
cXVlc3RpbmcgdGhlIGh1bWFuIGxhYmVsaW5nIHRhc2sgZm9yIHRoaXMKIEFubm90YXRlZERh
dGFzZXQuCgoNCgUEDAIKBhIEuwICFwoNCgUEDAIKARIEuwIYLwoNCgUEDAIKAxIEuwIyMwps
CgIEDRIGwAIA2gIBGl4gQW4gRXhhbXBsZSBpcyBhIHBpZWNlIG9mIGRhdGEgYW5kIGl0cyBh
bm5vdGF0aW9uLiBGb3IgZXhhbXBsZSwgYW4gaW1hZ2Ugd2l0aAogbGFiZWwgImhvdXNlIi4K
CgsKAwQNARIEwAIIDwoNCgMEDQcSBsECAsQCBAoPCgUEDQedCBIGwQICxAIECjgKBAQNCAAS
BscCAtACAxooIE91dHB1dCBvbmx5LiBUaGUgZGF0YSBwYXJ0IG9mIEV4YW1wbGUuCgoNCgUE
DQgAARIExwIIDwpGCgQEDQIAEgTJAgQjGjggVGhlIGltYWdlIHBheWxvYWQsIGEgY29udGFp
bmVyIG9mIHRoZSBpbWFnZSBieXRlcy91cmkuCgoNCgUEDQIABhIEyQIEEAoNCgUEDQIAARIE
yQIRHgoNCgUEDQIAAxIEyQIhIgpCCgQEDQIBEgTMAgQhGjQgVGhlIHRleHQgcGF5bG9hZCwg
YSBjb250YWluZXIgb2YgdGhlIHRleHQgY29udGVudC4KCg0KBQQNAgEGEgTMAgQPCg0KBQQN
AgEBEgTMAhAcCg0KBQQNAgEDEgTMAh8gCkAKBAQNAgISBM8CBCMaMiBUaGUgdmlkZW8gcGF5
bG9hZCwgYSBjb250YWluZXIgb2YgdGhlIHZpZGVvIHVyaS4KCg0KBQQNAgIGEgTPAgQQCg0K
BQQNAgIBEgTPAhEeCg0KBQQNAgIDEgTPAiEiCq4BCgQEDQIDEgTVAgISGp8BIE91dHB1dCBv
bmx5LiBOYW1lIG9mIHRoZSBleGFtcGxlLCBpbiBmb3JtYXQgb2Y6CiBwcm9qZWN0cy97cHJv
amVjdF9pZH0vZGF0YXNldHMve2RhdGFzZXRfaWR9L2Fubm90YXRlZERhdGFzZXRzLwoge2Fu
bm90YXRlZF9kYXRhc2V0X2lkfS9leGFtcGxlcy97ZXhhbXBsZV9pZH0KCg0KBQQNAgMFEgTV
AgIICg0KBQQNAgMBEgTVAgkNCg0KBQQNAgMDEgTVAhARCnwKBAQNAgQSBNkCAiYabiBPdXRw
dXQgb25seS4gQW5ub3RhdGlvbnMgZm9yIHRoZSBwaWVjZSBvZiBkYXRhIGluIEV4YW1wbGUu
CiBPbmUgcGllY2Ugb2YgZGF0YSBjYW4gaGF2ZSBtdWx0aXBsZSBhbm5vdGF0aW9ucy4KCg0K
BQQNAgQEEgTZAgIKCg0KBQQNAgQGEgTZAgsVCg0KBQQNAgQBEgTZAhYhCg0KBQQNAgQDEgTZ
AiQlYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset ===
    # Fields for Dataset
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: input_configs Type: 11 (.google.cloud.datalabeling.v1beta1.InputConfig)
    # Field: blocking_resources Type: 9 ()
    # Field: data_item_count Type: 3 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::InputConfig ===
    # Fields for InputConfig
    # Field: text_metadata Type: 11 (.google.cloud.datalabeling.v1beta1.TextMetadata)
    # Field: gcs_source Type: 11 (.google.cloud.datalabeling.v1beta1.GcsSource)
    # Field: bigquery_source Type: 11 (.google.cloud.datalabeling.v1beta1.BigQuerySource)
    # Field: data_type Type: 14 (.google.cloud.datalabeling.v1beta1.DataType)
    # Field: annotation_type Type: 14 (.google.cloud.datalabeling.v1beta1.AnnotationType)
    # Field: classification_metadata Type: 11 (.google.cloud.datalabeling.v1beta1.ClassificationMetadata)

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::TextMetadata ===
    # Fields for TextMetadata
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::ClassificationMetadata ===
    # Fields for ClassificationMetadata
    # Field: is_multi_label Type: 8 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::GcsSource ===
    # Fields for GcsSource
    # Field: input_uri Type: 9 ()
    # Field: mime_type Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::BigQuerySource ===
    # Fields for BigQuerySource
    # Field: input_uri Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::OutputConfig ===
    # Fields for OutputConfig
    # Field: gcs_destination Type: 11 (.google.cloud.datalabeling.v1beta1.GcsDestination)
    # Field: gcs_folder_destination Type: 11 (.google.cloud.datalabeling.v1beta1.GcsFolderDestination)

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::GcsDestination ===
    # Fields for GcsDestination
    # Field: output_uri Type: 9 ()
    # Field: mime_type Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::GcsFolderDestination ===
    # Fields for GcsFolderDestination
    # Field: output_folder_uri Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::DataItem ===
    # Fields for DataItem
    # Field: image_payload Type: 11 (.google.cloud.datalabeling.v1beta1.ImagePayload)
    # Field: text_payload Type: 11 (.google.cloud.datalabeling.v1beta1.TextPayload)
    # Field: video_payload Type: 11 (.google.cloud.datalabeling.v1beta1.VideoPayload)
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDataset ===
    # Fields for AnnotatedDataset
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: annotation_source Type: 14 (.google.cloud.datalabeling.v1beta1.AnnotationSource)
    # Field: annotation_type Type: 14 (.google.cloud.datalabeling.v1beta1.AnnotationType)
    # Field: example_count Type: 3 ()
    # Field: completed_example_count Type: 3 ()
    # Field: label_stats Type: 11 (.google.cloud.datalabeling.v1beta1.LabelStats)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: metadata Type: 11 (.google.cloud.datalabeling.v1beta1.AnnotatedDatasetMetadata)
    # Field: blocking_resources Type: 9 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats ===
    # Fields for LabelStats
    # Field: example_count Type: 11 (.google.cloud.datalabeling.v1beta1.LabelStats.ExampleCountEntry)

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDatasetMetadata ===
    # Fields for AnnotatedDatasetMetadata
    # Field: image_classification_config Type: 11 (.google.cloud.datalabeling.v1beta1.ImageClassificationConfig)
    # Field: bounding_poly_config Type: 11 (.google.cloud.datalabeling.v1beta1.BoundingPolyConfig)
    # Field: polyline_config Type: 11 (.google.cloud.datalabeling.v1beta1.PolylineConfig)
    # Field: segmentation_config Type: 11 (.google.cloud.datalabeling.v1beta1.SegmentationConfig)
    # Field: video_classification_config Type: 11 (.google.cloud.datalabeling.v1beta1.VideoClassificationConfig)
    # Field: object_detection_config Type: 11 (.google.cloud.datalabeling.v1beta1.ObjectDetectionConfig)
    # Field: object_tracking_config Type: 11 (.google.cloud.datalabeling.v1beta1.ObjectTrackingConfig)
    # Field: event_config Type: 11 (.google.cloud.datalabeling.v1beta1.EventConfig)
    # Field: text_classification_config Type: 11 (.google.cloud.datalabeling.v1beta1.TextClassificationConfig)
    # Field: text_entity_extraction_config Type: 11 (.google.cloud.datalabeling.v1beta1.TextEntityExtractionConfig)
    # Field: human_annotation_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::Dataset::Example ===
    # Fields for Example
    # Field: image_payload Type: 11 (.google.cloud.datalabeling.v1beta1.ImagePayload)
    # Field: text_payload Type: 11 (.google.cloud.datalabeling.v1beta1.TextPayload)
    # Field: video_payload Type: 11 (.google.cloud.datalabeling.v1beta1.VideoPayload)
    # Field: name Type: 9 ()
    # Field: annotations Type: 11 (.google.cloud.datalabeling.v1beta1.Annotation)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Dataset - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/dataset.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::Dataset;

    my $msg = Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/dataset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset

Dataset is the resource to hold your data. You can request multiple labeling
tasks for a dataset while each one will generate an AnnotatedDataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Dataset resource name, format is:
projects/{project_id}/datasets/{dataset_id}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The display name of the dataset. Maximum of 64 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-provided description of the annotation specification set.
The description can be up to 10000 characters long.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the dataset is created.

=item * C<< $msg->input_configs() >> / C<< $msg->input_configs($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::InputConfig>)

Output only. This is populated with the original input configs
where ImportData is called. It is available only after the clients
import data to this dataset.

=item * C<< $msg->blocking_resources() >> / C<< $msg->blocking_resources($value) >>

Type: C<String>

Output only. The names of any related resources that are blocking changes
to the dataset.

=item * C<< $msg->data_item_count() >> / C<< $msg->data_item_count($value) >>

Type: C<Int64>

Output only. The number of data items in the dataset.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::InputConfig

The configuration of input data, including data type, location, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_metadata() >> / C<< $msg->text_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::TextMetadata>)

Required for text import, as language code must be specified.

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::GcsSource>)

Source located in Cloud Storage.

=item * C<< $msg->bigquery_source() >> / C<< $msg->bigquery_source($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::BigQuerySource>)

Source located in BigQuery. You must specify this field if you are using
this InputConfig in an [EvaluationJob][google.cloud.datalabeling.v1beta1.EvaluationJob].

=item * C<< $msg->data_type() >> / C<< $msg->data_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::DataType>)

Required. Data type must be specifed when user tries to import data.

=item * C<< $msg->annotation_type() >> / C<< $msg->annotation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationType>)

Optional. The type of annotation to be performed on this data. You must
specify this field if you are using this InputConfig in an
[EvaluationJob][google.cloud.datalabeling.v1beta1.EvaluationJob].

=item * C<< $msg->classification_metadata() >> / C<< $msg->classification_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::ClassificationMetadata>)

Optional. Metadata about annotations for the input. You must specify this
field if you are using this InputConfig in an [EvaluationJob][google.cloud.datalabeling.v1beta1.EvaluationJob] for a
model version that performs classification.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::TextMetadata

Metadata for the text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language of this text, as a
[BCP-47](https://www.rfc-editor.org/rfc/bcp/bcp47.txt).
Default value is en-US.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::ClassificationMetadata

Metadata for classification annotations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->is_multi_label() >> / C<< $msg->is_multi_label($value) >>

Type: C<Bool>

Whether the classification task is multi-label or not.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::GcsSource

Source of the Cloud Storage file to be imported.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_uri() >> / C<< $msg->input_uri($value) >>

Type: C<String>

Required. The input URI of source file. This must be a Cloud Storage path
(`gs://...`).

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Required. The format of the source file. Only "text/csv" is supported.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::BigQuerySource

The BigQuery location for input data. If used in an [EvaluationJob][google.cloud.datalabeling.v1beta1.EvaluationJob], this
is where the service saves the prediction input and output sampled from the
model version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_uri() >> / C<< $msg->input_uri($value) >>

Type: C<String>

Required. BigQuery URI to a table, up to 2,000 characters long. If you
specify the URI of a table that does not exist, Data Labeling Service
creates a table at the URI with the correct schema when you create your
[EvaluationJob][google.cloud.datalabeling.v1beta1.EvaluationJob]. If you specify the URI of a table that already exists,
it must have the
[correct
schema](/ml-engine/docs/continuous-evaluation/create-job#table-schema).

Provide the table URI in the following format:

"bq://<var>{your_project_id}</var>/<var>{your_dataset_name}</var>/<var>{your_table_name}</var>"

[Learn
more](/ml-engine/docs/continuous-evaluation/create-job#table-schema).

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::OutputConfig

The configuration of output data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_destination() >> / C<< $msg->gcs_destination($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::GcsDestination>)

Output to a file in Cloud Storage. Should be used for labeling output
other than image segmentation.

=item * C<< $msg->gcs_folder_destination() >> / C<< $msg->gcs_folder_destination($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::GcsFolderDestination>)

Output to a folder in Cloud Storage. Should be used for image
segmentation labeling output.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::GcsDestination

Export destination of the data.Only gcs path is allowed in
output_uri.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_uri() >> / C<< $msg->output_uri($value) >>

Type: C<String>

Required. The output uri of destination file.

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Required. The format of the gcs destination. Only "text/csv" and
"application/json"
are supported.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::GcsFolderDestination

Export folder destination of the data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_folder_uri() >> / C<< $msg->output_folder_uri($value) >>

Type: C<String>

Required. Cloud Storage directory to export data to.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::DataItem

DataItem is a piece of data, without annotation. For example, an image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_payload() >> / C<< $msg->image_payload($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload>)

The image payload, a container of the image bytes/uri.

=item * C<< $msg->text_payload() >> / C<< $msg->text_payload($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::DataPayloads::TextPayload>)

The text payload, a container of text content.

=item * C<< $msg->video_payload() >> / C<< $msg->video_payload($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoPayload>)

The video payload, a container of the video uri.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the data item, in format of:
projects/{project_id}/datasets/{dataset_id}/dataItems/{data_item_id}

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDataset

AnnotatedDataset is a set holding annotations for data in a Dataset. Each
labeling task will generate an AnnotatedDataset under the Dataset that the
task is requested for.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. AnnotatedDataset resource name in format of:
projects/{project_id}/datasets/{dataset_id}/annotatedDatasets/
{annotated_dataset_id}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the AnnotatedDataset. It is specified in
HumanAnnotationConfig when user starts a labeling task. Maximum of 64
characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the AnnotatedDataset. It is specified in
HumanAnnotationConfig when user starts a labeling task. Maximum of 10000
characters.

=item * C<< $msg->annotation_source() >> / C<< $msg->annotation_source($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationSource>)

Output only. Source of the annotation.

=item * C<< $msg->annotation_type() >> / C<< $msg->annotation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::AnnotationType>)

Output only. Type of the annotation. It is specified when starting labeling
task.

=item * C<< $msg->example_count() >> / C<< $msg->example_count($value) >>

Type: C<Int64>

Output only. Number of examples in the annotated dataset.

=item * C<< $msg->completed_example_count() >> / C<< $msg->completed_example_count($value) >>

Type: C<Int64>

Output only. Number of examples that have annotation in the annotated
dataset.

=item * C<< $msg->label_stats() >> / C<< $msg->label_stats($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats>)

Output only. Per label statistics.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the AnnotatedDataset was created.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDatasetMetadata>)

Output only. Additional information about AnnotatedDataset.

=item * C<< $msg->blocking_resources() >> / C<< $msg->blocking_resources($value) >>

Type: C<String>

Output only. The names of any related resources that are blocking changes
to the annotated dataset.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats

Statistics about annotation specs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->example_count() >> / C<< $msg->example_count($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats::ExampleCountEntry>)

Map of each annotation spec's example count. Key is the annotation spec
name and value is the number of examples for that annotation spec.
If the annotated dataset does not have annotation spec, the map will return
a pair where the key is empty string and value is the total number of
annotations.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDatasetMetadata

Metadata on AnnotatedDataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_classification_config() >> / C<< $msg->image_classification_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ImageClassificationConfig>)

Configuration for image classification task.

=item * C<< $msg->bounding_poly_config() >> / C<< $msg->bounding_poly_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::BoundingPolyConfig>)

Configuration for image bounding box and bounding poly task.

=item * C<< $msg->polyline_config() >> / C<< $msg->polyline_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::PolylineConfig>)

Configuration for image polyline task.

=item * C<< $msg->segmentation_config() >> / C<< $msg->segmentation_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SegmentationConfig>)

Configuration for image segmentation task.

=item * C<< $msg->video_classification_config() >> / C<< $msg->video_classification_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig>)

Configuration for video classification task.

=item * C<< $msg->object_detection_config() >> / C<< $msg->object_detection_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectDetectionConfig>)

Configuration for video object detection task.

=item * C<< $msg->object_tracking_config() >> / C<< $msg->object_tracking_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectTrackingConfig>)

Configuration for video object tracking task.

=item * C<< $msg->event_config() >> / C<< $msg->event_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::EventConfig>)

Configuration for video event labeling task.

=item * C<< $msg->text_classification_config() >> / C<< $msg->text_classification_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextClassificationConfig>)

Configuration for text classification task.

=item * C<< $msg->text_entity_extraction_config() >> / C<< $msg->text_entity_extraction_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextEntityExtractionConfig>)

Configuration for text entity extraction task.

=item * C<< $msg->human_annotation_config() >> / C<< $msg->human_annotation_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

HumanAnnotationConfig used when requesting the human labeling task for this
AnnotatedDataset.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::Dataset::Example

An Example is a piece of data and its annotation. For example, an image with
label "house".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_payload() >> / C<< $msg->image_payload($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload>)

The image payload, a container of the image bytes/uri.

=item * C<< $msg->text_payload() >> / C<< $msg->text_payload($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::DataPayloads::TextPayload>)

The text payload, a container of the text content.

=item * C<< $msg->video_payload() >> / C<< $msg->video_payload($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoPayload>)

The video payload, a container of the video uri.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the example, in format of:
projects/{project_id}/datasets/{dataset_id}/annotatedDatasets/
{annotated_dataset_id}/examples/{example_id}

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Annotation::Annotation>)

Output only. Annotations for the piece of data in Example.
One piece of data can have multiple annotations.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::Dataset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
