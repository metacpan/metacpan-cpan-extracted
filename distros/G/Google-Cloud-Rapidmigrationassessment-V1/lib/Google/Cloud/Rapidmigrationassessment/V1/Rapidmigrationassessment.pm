package Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment;

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
    eval { require Google::Cloud::Rapidmigrationassessment::V1::ApiEntities };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ckdnb29nbGUvY2xvdWQvcmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50L3YxL3JhcGlkbWlncmF0
aW9uYXNzZXNzbWVudC5wcm90bxIoZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNz
bWVudC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGll
bnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aO2dvb2dsZS9jbG91ZC9yYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQv
djEvYXBpX2VudGl0aWVzLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5w
cm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8i2wEKF0NyZWF0ZUFubm90YXRpb25SZXF1ZXN0EkEKBnBhcmVu
dBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBh
cmVudBJZCgphbm5vdGF0aW9uGAIgASgLMjQuZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9u
YXNzZXNzbWVudC52MS5Bbm5vdGF0aW9uQgPgQQJSCmFubm90YXRpb24SIgoKcmVxdWVzdF9p
ZBgEIAEoCUID4EEBUglyZXF1ZXN0SWQiZgoUR2V0QW5ub3RhdGlvblJlcXVlc3QSTgoEbmFt
ZRgBIAEoCUI64EEC+kE0CjJyYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQuZ29vZ2xlYXBpcy5j
b20vQW5ub3RhdGlvblIEbmFtZSL/AQoWQ3JlYXRlQ29sbGVjdG9yUmVxdWVzdBJBCgZwYXJl
bnQYASABKAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZw
YXJlbnQSJgoMY29sbGVjdG9yX2lkGAIgASgJQgPgQQJSC2NvbGxlY3RvcklkElYKCWNvbGxl
Y3RvchgDIAEoCzIzLmdvb2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQudjEu
Q29sbGVjdG9yQgPgQQJSCWNvbGxlY3RvchIiCgpyZXF1ZXN0X2lkGAQgASgJQgPgQQFSCXJl
cXVlc3RJZCLJAQoVTGlzdENvbGxlY3RvcnNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC
+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdl
X3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIW
CgZmaWx0ZXIYBCABKAlSBmZpbHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJCeSK3AQoW
TGlzdENvbGxlY3RvcnNSZXNwb25zZRJTCgpjb2xsZWN0b3JzGAEgAygLMjMuZ29vZ2xlLmNs
b3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC52MS5Db2xsZWN0b3JSCmNvbGxlY3RvcnMS
JgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxl
GAMgAygJUgt1bnJlYWNoYWJsZSJkChNHZXRDb2xsZWN0b3JSZXF1ZXN0Ek0KBG5hbWUYASAB
KAlCOeBBAvpBMwoxcmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50Lmdvb2dsZWFwaXMuY29tL0Nv
bGxlY3RvclIEbmFtZSKLAQoWRGVsZXRlQ29sbGVjdG9yUmVxdWVzdBJNCgRuYW1lGAEgASgJ
QjngQQL6QTMKMXJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC5nb29nbGVhcGlzLmNvbS9Db2xs
ZWN0b3JSBG5hbWUSIgoKcmVxdWVzdF9pZBgCIAEoCUID4EEBUglyZXF1ZXN0SWQi1gEKFlVw
ZGF0ZUNvbGxlY3RvclJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASABKAsyGi5nb29nbGUucHJv
dG9idWYuRmllbGRNYXNrQgPgQQJSCnVwZGF0ZU1hc2sSVgoJY29sbGVjdG9yGAIgASgLMjMu
Z29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC52MS5Db2xsZWN0b3JCA+BB
AlIJY29sbGVjdG9yEiIKCnJlcXVlc3RfaWQYAyABKAlCA+BBAVIJcmVxdWVzdElkIosBChZS
ZXN1bWVDb2xsZWN0b3JSZXF1ZXN0Ek0KBG5hbWUYASABKAlCOeBBAvpBMwoxcmFwaWRtaWdy
YXRpb25hc3Nlc3NtZW50Lmdvb2dsZWFwaXMuY29tL0NvbGxlY3RvclIEbmFtZRIiCgpyZXF1
ZXN0X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJZCKNAQoYUmVnaXN0ZXJDb2xsZWN0b3JSZXF1
ZXN0Ek0KBG5hbWUYASABKAlCOeBBAvpBMwoxcmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50Lmdv
b2dsZWFwaXMuY29tL0NvbGxlY3RvclIEbmFtZRIiCgpyZXF1ZXN0X2lkGAIgASgJQgPgQQFS
CXJlcXVlc3RJZCKKAQoVUGF1c2VDb2xsZWN0b3JSZXF1ZXN0Ek0KBG5hbWUYASABKAlCOeBB
AvpBMwoxcmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50Lmdvb2dsZWFwaXMuY29tL0NvbGxlY3Rv
clIEbmFtZRIiCgpyZXF1ZXN0X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJZCLVAgoRT3BlcmF0
aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRh
cmdldBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKgoOc3RhdHVzX21lc3NhZ2UYBSABKAlC
A+BBA1INc3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAYgASgIQgPg
QQNSFXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgHIAEoCUID4EEDUgph
cGlWZXJzaW9uMrcSChhSYXBpZE1pZ3JhdGlvbkFzc2Vzc21lbnQS9wEKD0NyZWF0ZUNvbGxl
Y3RvchJALmdvb2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQudjEuQ3JlYXRl
Q29sbGVjdG9yUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iggGC0+ST
AjsiLi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2NvbGxlY3RvcnM6CWNv
bGxlY3RvctpBHXBhcmVudCxjb2xsZWN0b3IsY29sbGVjdG9yX2lkykEeCglDb2xsZWN0b3IS
EU9wZXJhdGlvbk1ldGFkYXRhEu8BChBDcmVhdGVBbm5vdGF0aW9uEkEuZ29vZ2xlLmNsb3Vk
LnJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC52MS5DcmVhdGVBbm5vdGF0aW9uUmVxdWVzdBod
Lmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ieYLT5JMCPSIvL3YxL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKn0vYW5ub3RhdGlvbnM6CmFubm90YXRpb27aQRFwYXJlbnQs
YW5ub3RhdGlvbspBHwoKQW5ub3RhdGlvbhIRT3BlcmF0aW9uTWV0YWRhdGESxQEKDUdldEFu
bm90YXRpb24SPi5nb29nbGUuY2xvdWQucmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50LnYxLkdl
dEFubm90YXRpb25SZXF1ZXN0GjQuZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNz
bWVudC52MS5Bbm5vdGF0aW9uIj6C0+STAjESLy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2Fubm90YXRpb25zLyp92kEEbmFtZRLUAQoOTGlzdENvbGxlY3RvcnMSPy5nb29n
bGUuY2xvdWQucmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50LnYxLkxpc3RDb2xsZWN0b3JzUmVx
dWVzdBpALmdvb2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQudjEuTGlzdENv
bGxlY3RvcnNSZXNwb25zZSI/gtPkkwIwEi4vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qfS9jb2xsZWN0b3Jz2kEGcGFyZW50EsEBCgxHZXRDb2xsZWN0b3ISPS5nb29nbGUu
Y2xvdWQucmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50LnYxLkdldENvbGxlY3RvclJlcXVlc3Qa
My5nb29nbGUuY2xvdWQucmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50LnYxLkNvbGxlY3RvciI9
gtPkkwIwEi4vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0b3JzLyp9
2kEEbmFtZRL5AQoPVXBkYXRlQ29sbGVjdG9yEkAuZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0
aW9uYXNzZXNzbWVudC52MS5VcGRhdGVDb2xsZWN0b3JSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbiKEAYLT5JMCRTI4L3YxL3tjb2xsZWN0b3IubmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3RvcnMvKn06CWNvbGxlY3RvctpBFWNvbGxlY3Rvcix1
cGRhdGVfbWFza8pBHgoJQ29sbGVjdG9yEhFPcGVyYXRpb25NZXRhZGF0YRLSAQoPRGVsZXRl
Q29sbGVjdG9yEkAuZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC52MS5E
ZWxldGVDb2xsZWN0b3JSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJe
gtPkkwIwKi4vdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0b3JzLyp9
2kEEbmFtZcpBHgoJQ29sbGVjdG9yEhFPcGVyYXRpb25NZXRhZGF0YRLcAQoPUmVzdW1lQ29s
bGVjdG9yEkAuZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVudC52MS5SZXN1
bWVDb2xsZWN0b3JSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJogtPk
kwI6IjUvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0b3JzLyp9OnJl
c3VtZToBKtpBBG5hbWXKQR4KCUNvbGxlY3RvchIRT3BlcmF0aW9uTWV0YWRhdGES4gEKEVJl
Z2lzdGVyQ29sbGVjdG9yEkIuZ29vZ2xlLmNsb3VkLnJhcGlkbWlncmF0aW9uYXNzZXNzbWVu
dC52MS5SZWdpc3RlckNvbGxlY3RvclJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uImqC0+STAjwiNy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxl
Y3RvcnMvKn06cmVnaXN0ZXI6ASraQQRuYW1lykEeCglDb2xsZWN0b3ISEU9wZXJhdGlvbk1l
dGFkYXRhEtkBCg5QYXVzZUNvbGxlY3RvchI/Lmdvb2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlv
bmFzc2Vzc21lbnQudjEuUGF1c2VDb2xsZWN0b3JSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5u
aW5nLk9wZXJhdGlvbiJngtPkkwI5IjQvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jb2xsZWN0b3JzLyp9OnBhdXNlOgEq2kEEbmFtZcpBHgoJQ29sbGVjdG9yEhFPcGVyYXRp
b25NZXRhZGF0YRpbykEncmFwaWRtaWdyYXRpb25hc3Nlc3NtZW50Lmdvb2dsZWFwaXMuY29t
0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUK9Agos
Y29tLmdvb2dsZS5jbG91ZC5yYXBpZG1pZ3JhdGlvbmFzc2Vzc21lbnQudjFCHVJhcGlkTWln
cmF0aW9uQXNzZXNzbWVudFByb3RvUAFaaGNsb3VkLmdvb2dsZS5jb20vZ28vcmFwaWRtaWdy
YXRpb25hc3Nlc3NtZW50L2FwaXYxL3JhcGlkbWlncmF0aW9uYXNzZXNzbWVudHBiO3JhcGlk
bWlncmF0aW9uYXNzZXNzbWVudHBiqgIoR29vZ2xlLkNsb3VkLlJhcGlkTWlncmF0aW9uQXNz
ZXNzbWVudC5WMcoCKEdvb2dsZVxDbG91ZFxSYXBpZE1pZ3JhdGlvbkFzc2Vzc21lbnRcVjHq
AitHb29nbGU6OkNsb3VkOjpSYXBpZE1pZ3JhdGlvbkFzc2Vzc21lbnQ6OlYxSudkCgcSBQ4A
pQMBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAxCgkKAgMA
EgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYARQoJCgID
BRIDFwAtCgkKAgMGEgMYACoKCQoCAwcSAxkAKQoICgEIEgMbAEUKCQoCCCUSAxsARQoICgEI
EgMcAH8KCQoCCAsSAxwAfwoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeAD4KCQoCCAgS
Ax4APgoICgEIEgMfAEUKCQoCCAESAx8ARQoICgEIEgMgAEUKCQoCCCkSAyAARQoICgEIEgMh
AEQKCQoCCC0SAyEARAo5CgIGABIFJACjAQEaLCBTZXJ2aWNlIGRlc2NyaWJpbmcgaGFuZGxl
cnMgZm9yIHJlc291cmNlcy4KCgoKAwYAARIDJAggCgoKAwYAAxIDJQJPCgwKBQYAA5kIEgMl
Ak8KCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3CnUKBAYAAgASBCsCNgMaZyBDcmVhdGUg
YSBDb2xsZWN0b3IgdG8gbWFuYWdlIHRoZSBvbi1wcmVtIGFwcGxpYW5jZSB3aGljaCBjb2xs
ZWN0cwogaW5mb3JtYXRpb24gYWJvdXQgQ3VzdG9tZXIgYXNzZXRzLgoKDAoFBgACAAESAysG
FQoMCgUGAAIAAhIDKxYsCgwKBQYAAgADEgMsDysKDQoFBgACAAQSBC0EMAYKEQoJBgACAASw
yrwiEgQtBDAGCgwKBQYAAgAEEgMxBEsKDwoIBgACAASbCAASAzEESwoNCgUGAAIABBIEMgQ1
BgoPCgcGAAIABJkIEgQyBDUGCiUKBAYAAgESBDkCRAMaFyBDcmVhdGVzIGFuIEFubm90YXRp
b24KCgwKBQYAAgEBEgM5BhYKDAoFBgACAQISAzkXLgoMCgUGAAIBAxIDOg8rCg0KBQYAAgEE
EgQ7BD4GChEKCQYAAgEEsMq8IhIEOwQ+BgoMCgUGAAIBBBIDPwQ/Cg8KCAYAAgEEmwgAEgM/
BD8KDQoFBgACAQQSBEAEQwYKDwoHBgACAQSZCBIEQARDBgo0CgQGAAICEgRHAkwDGiYgR2V0
cyBkZXRhaWxzIG9mIGEgc2luZ2xlIEFubm90YXRpb24uCgoMCgUGAAICARIDRwYTCgwKBQYA
AgICEgNHFCgKDAoFBgACAgMSA0czPQoNCgUGAAICBBIESARKBgoRCgkGAAICBLDKvCISBEgE
SgYKDAoFBgACAgQSA0sEMgoPCggGAAICBJsIABIDSwQyCkEKBAYAAgMSBE8CVAMaMyBMaXN0
cyBDb2xsZWN0b3JzIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAID
ARIDTwYUCgwKBQYAAgMCEgNPFSoKDAoFBgACAwMSA081SwoNCgUGAAIDBBIEUARSBgoRCgkG
AAIDBLDKvCISBFAEUgYKDAoFBgACAwQSA1MENAoPCggGAAIDBJsIABIDUwQ0CjMKBAYAAgQS
BFcCXAMaJSBHZXRzIGRldGFpbHMgb2YgYSBzaW5nbGUgQ29sbGVjdG9yLgoKDAoFBgACBAES
A1cGEgoMCgUGAAIEAhIDVxMmCgwKBQYAAgQDEgNXMToKDQoFBgACBAQSBFgEWgYKEQoJBgAC
BASwyrwiEgRYBFoGCgwKBQYAAgQEEgNbBDIKDwoIBgACBASbCAASA1sEMgo9CgQGAAIFEgRf
AmoDGi8gVXBkYXRlcyB0aGUgcGFyYW1ldGVycyBvZiBhIHNpbmdsZSBDb2xsZWN0b3IuCgoM
CgUGAAIFARIDXwYVCgwKBQYAAgUCEgNfFiwKDAoFBgACBQMSA2APKwoNCgUGAAIFBBIEYQRk
BgoRCgkGAAIFBLDKvCISBGEEZAYKDAoFBgACBQQSA2UEQwoPCggGAAIFBJsIABIDZQRDCg0K
BQYAAgUEEgRmBGkGCg8KBwYAAgUEmQgSBGYEaQYKkgEKBAYAAgYSBG4CeAMagwEgRGVsZXRl
cyBhIHNpbmdsZSBDb2xsZWN0b3IgLSBjaGFuZ2VzIHN0YXRlIG9mIGNvbGxlY3RvciB0byAi
RGVsZXRpbmciLgogQmFja2dyb3VuZCBqb2JzIGRvZXMgZmluYWwgZGVsZXRpb24gdGhyb3Vn
aCBwcm9kdWNlciBBUEkuCgoMCgUGAAIGARIDbgYVCgwKBQYAAgYCEgNuFiwKDAoFBgACBgMS
A28PKwoNCgUGAAIGBBIEcARyBgoRCgkGAAIGBLDKvCISBHAEcgYKDAoFBgACBgQSA3MEMgoP
CggGAAIGBJsIABIDcwQyCg0KBQYAAgYEEgR0BHcGCg8KBwYAAgYEmQgSBHQEdwYKLQoEBgAC
BxIFewKGAQMaHiBSZXN1bWVzIHRoZSBnaXZlbiBjb2xsZWN0b3IuCgoMCgUGAAIHARIDewYV
CgwKBQYAAgcCEgN7FiwKDAoFBgACBwMSA3wPKwoOCgUGAAIHBBIFfQSAAQYKEgoJBgACBwSw
yrwiEgV9BIABBgoNCgUGAAIHBBIEgQEEMgoQCggGAAIHBJsIABIEgQEEMgoPCgUGAAIHBBIG
ggEEhQEGChEKBwYAAgcEmQgSBoIBBIUBBgowCgQGAAIIEgaJAQKUAQMaICBSZWdpc3RlcnMg
dGhlIGdpdmVuIGNvbGxlY3Rvci4KCg0KBQYAAggBEgSJAQYXCg0KBQYAAggCEgSJARgwCg0K
BQYAAggDEgSKAQ8rCg8KBQYAAggEEgaLAQSOAQYKEwoJBgACCASwyrwiEgaLAQSOAQYKDQoF
BgACCAQSBI8BBDIKEAoIBgACCASbCAASBI8BBDIKDwoFBgACCAQSBpABBJMBBgoRCgcGAAII
BJkIEgaQAQSTAQYKLQoEBgACCRIGlwECogEDGh0gUGF1c2VzIHRoZSBnaXZlbiBjb2xsZWN0
b3IuCgoNCgUGAAIJARIElwEGFAoNCgUGAAIJAhIElwEVKgoNCgUGAAIJAxIEmAEPKwoPCgUG
AAIJBBIGmQEEnAEGChMKCQYAAgkEsMq8IhIGmQEEnAEGCg0KBQYAAgkEEgSdAQQyChAKCAYA
AgkEmwgAEgSdAQQyCg8KBQYAAgkEEgaeAQShAQYKEQoHBgACCQSZCBIGngEEoQEGCjQKAgQA
EgamAQC0AQEaJiBNZXNzYWdlIGZvciBjcmVhdGluZyBhbiBBbm5vdGF0aW9uUy4KCgsKAwQA
ARIEpgEIHwpCCgQEAAIAEgaoAQKtAQQaMiBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcGFyZW50
IChwcm9qZWN0K2xvY2F0aW9uKS4KCg0KBQQAAgAFEgSoAQIICg0KBQQAAgABEgSoAQkPCg0K
BQQAAgADEgSoARITCg8KBQQAAgAIEgaoARStAQMKEAoIBAACAAicCAASBKkBBCoKEQoHBAAC
AAifCBIGqgEErAEFCjUKBAQAAgESBLABAkUaJyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGJl
aW5nIGNyZWF0ZWQuCgoNCgUEAAIBBhIEsAECDAoNCgUEAAIBARIEsAENFwoNCgUEAAIBAxIE
sAEaGwoNCgUEAAIBCBIEsAEcRAoQCggEAAIBCJwIABIEsAEdQwpGCgQEAAICEgSzAQJBGjgg
T3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMu
CgoNCgUEAAICBRIEswECCAoNCgUEAAICARIEswEJEwoNCgUEAAICAxIEswEWFwoNCgUEAAIC
CBIEswEYQAoQCggEAAICCJwIABIEswEZPwo5CgIEARIGtwEAvwEBGisgTWVzc2FnZSBmb3Ig
Z2V0dGluZyBhIHNwZWNpZmljIEFubm90YXRpb24KCgsKAwQBARIEtwEIHAoxCgQEAQIAEga5
AQK+AQQaISBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoNCgUEAQIABRIEuQEC
CAoNCgUEAQIAARIEuQEJDQoNCgUEAQIAAxIEuQEQEQoPCgUEAQIACBIGuQESvgEDChAKCAQB
AgAInAgAEgS6AQQqChEKBwQBAgAInwgSBrsBBL0BBQoxCgIEAhIGwgEA0wEBGiMgTWVzc2Fn
ZSBmb3IgY3JlYXRpbmcgYSBDb2xsZWN0b3IuCgoLCgMEAgESBMIBCB4KQgoEBAICABIGxAEC
yQEEGjIgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHBhcmVudCAocHJvamVjdCtsb2NhdGlvbiku
CgoNCgUEAgIABRIExAECCAoNCgUEAgIAARIExAEJDwoNCgUEAgIAAxIExAESEwoPCgUEAgIA
CBIGxAEUyQEDChAKCAQCAgAInAgAEgTFAQQqChEKBwQCAgAInwgSBsYBBMgBBQo2CgQEAgIB
EgTMAQJDGiggUmVxdWlyZWQuIElkIG9mIHRoZSByZXF1ZXN0aW5nIG9iamVjdC4KCg0KBQQC
AgEFEgTMAQIICg0KBQQCAgEBEgTMAQkVCg0KBQQCAgEDEgTMARgZCg0KBQQCAgEIEgTMARpC
ChAKCAQCAgEInAgAEgTMARtBCjUKBAQCAgISBM8BAkMaJyBSZXF1aXJlZC4gVGhlIHJlc291
cmNlIGJlaW5nIGNyZWF0ZWQuCgoNCgUEAgICBhIEzwECCwoNCgUEAgICARIEzwEMFQoNCgUE
AgICAxIEzwEYGQoNCgUEAgICCBIEzwEaQgoQCggEAgICCJwIABIEzwEbQQpGCgQEAgIDEgTS
AQJBGjggT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVx
dWVzdHMuCgoNCgUEAgIDBRIE0gECCAoNCgUEAgIDARIE0gEJEwoNCgUEAgIDAxIE0gEWFwoN
CgUEAgIDCBIE0gEYQAoQCggEAgIDCJwIABIE0gEZPwo6CgIEAxIG1gEA6wEBGiwgTWVzc2Fn
ZSBmb3IgcmVxdWVzdGluZyBsaXN0IG9mIENvbGxlY3RvcnMuCgoLCgMEAwESBNYBCB0KQwoE
BAMCABIG2AEC3QEEGjMgUmVxdWlyZWQuIFBhcmVudCB2YWx1ZSBmb3IgTGlzdENvbGxlY3Rv
cnNSZXF1ZXN0LgoKDQoFBAMCAAUSBNgBAggKDQoFBAMCAAESBNgBCQ8KDQoFBAMCAAMSBNgB
EhMKDwoFBAMCAAgSBtgBFN0BAwoQCggEAwIACJwIABIE2QEEKgoRCgcEAwIACJ8IEgbaAQTc
AQUKjAEKBAQDAgESBOEBAhYafiBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBTZXJ2ZXIgbWF5IHJl
dHVybiBmZXdlciBpdGVtcyB0aGFuIHJlcXVlc3RlZC4KIElmIHVuc3BlY2lmaWVkLCBzZXJ2
ZXIgd2lsbCBwaWNrIGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoNCgUEAwIBBRIE4QECBwoN
CgUEAwIBARIE4QEIEQoNCgUEAwIBAxIE4QEUFQpPCgQEAwICEgTkAQIYGkEgQSB0b2tlbiBp
ZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4u
CgoNCgUEAwICBRIE5AECCAoNCgUEAwICARIE5AEJEwoNCgUEAwICAxIE5AEWFwoiCgQEAwID
EgTnAQIUGhQgRmlsdGVyaW5nIHJlc3VsdHMuCgoNCgUEAwIDBRIE5wECCAoNCgUEAwIDARIE
5wEJDwoNCgUEAwIDAxIE5wESEwoyCgQEAwIEEgTqAQIWGiQgSGludCBmb3IgaG93IHRvIG9y
ZGVyIHRoZSByZXN1bHRzLgoKDQoFBAMCBAUSBOoBAggKDQoFBAMCBAESBOoBCREKDQoFBAMC
BAMSBOoBFBUKOwoCBAQSBu4BAPcBARotIE1lc3NhZ2UgZm9yIHJlc3BvbnNlIHRvIGxpc3Rp
bmcgQ29sbGVjdG9ycy4KCgsKAwQEARIE7gEIHgonCgQEBAIAEgTwAQIkGhkgVGhlIGxpc3Qg
b2YgQ29sbGVjdG9ycy4KCg0KBQQEAgAEEgTwAQIKCg0KBQQEAgAGEgTwAQsUCg0KBQQEAgAB
EgTwARUfCg0KBQQEAgADEgTwASIjCk8KBAQEAgESBPMBAh0aQSBBIHRva2VuIGlkZW50aWZ5
aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0KBQQE
AgEFEgTzAQIICg0KBQQEAgEBEgTzAQkYCg0KBQQEAgEDEgTzARscCjQKBAQEAgISBPYBAiIa
JiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQEAgIEEgT2AQIK
Cg0KBQQEAgIFEgT2AQsRCg0KBQQEAgIBEgT2ARIdCg0KBQQEAgIDEgT2ASAhCjkKAgQFEgb6
AQCCAgEaKyBNZXNzYWdlIGZvciBnZXR0aW5nIGEgc3BlY2lmaWMgQ29sbGVjdG9yLgoKCwoD
BAUBEgT6AQgbCjEKBAQFAgASBvwBAoECBBohIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNv
dXJjZS4KCg0KBQQFAgAFEgT8AQIICg0KBQQFAgABEgT8AQkNCg0KBQQFAgADEgT8ARARCg8K
BQQFAgAIEgb8ARKBAgMKEAoIBAUCAAicCAASBP0BBCoKEQoHBAUCAAifCBIG/gEEgAIFCjEK
AgQGEgaFAgCcAgEaIyBNZXNzYWdlIGZvciBkZWxldGluZyBhIENvbGxlY3Rvci4KCgsKAwQG
ARIEhQIIHgoxCgQEBgIAEgaHAgKMAgQaISBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3Vy
Y2UuCgoNCgUEBgIABRIEhwICCAoNCgUEBgIAARIEhwIJDQoNCgUEBgIAAxIEhwIQEQoPCgUE
BgIACBIGhwISjAIDChAKCAQGAgAInAgAEgSIAgQqChEKBwQGAgAInwgSBokCBIsCBQqPBgoE
BAYCARIEmwICQRqABiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVu
dGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlm
IHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8K
IGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4g
VGhlIHNlcnZlciB3aWxsCiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRl
cyBhZnRlciB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgYSBz
aXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCByZXF1ZXN0IGFuZAogdGhlIHJl
cXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRo
ZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBjaGVjayBpZiBvcmlnaW5hbCBv
cGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3YXMgcmVjZWl2ZWQsIGFuZCBp
ZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzCiBj
bGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50
cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNl
cHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAt
MDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBgIBBRIEmwICCAoNCgUEBgIBARIEmwIJ
EwoNCgUEBgIBAxIEmwIWFwoNCgUEBgIBCBIEmwIYQAoQCggEBgIBCJwIABIEmwIZPwoxCgIE
BxIGnwIAuQIBGiMgTWVzc2FnZSBmb3IgdXBkYXRpbmcgYSBDb2xsZWN0b3IuCgoLCgMEBwES
BJ8CCB4K2wIKBAQHAgASBqUCAqYCLxrKAiBSZXF1aXJlZC4gRmllbGQgbWFzayBpcyB1c2Vk
IHRvIHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIENvbGxl
Y3RvciByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4g
dGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAogdGhl
IGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGlu
IHRoZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBh
bGwgZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoNCgUEBwIABhIEpQICGwoNCgUEBwIA
ARIEpQIcJwoNCgUEBwIAAxIEpQIqKwoNCgUEBwIACBIEpgIGLgoQCggEBwIACJwIABIEpgIH
LQo1CgQEBwIBEgSpAgJDGicgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBiZWluZyB1cGRhdGVk
LgoKDQoFBAcCAQYSBKkCAgsKDQoFBAcCAQESBKkCDBUKDQoFBAcCAQMSBKkCGBkKDQoFBAcC
AQgSBKkCGkIKEAoIBAcCAQicCAASBKkCG0EKjwYKBAQHAgISBLgCAkEagAYgT3B0aW9uYWwu
IEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkg
YSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJl
cXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYg
aXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFu
dGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVl
c3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtl
IGFuIGluaXRpYWwgcmVxdWVzdCBhbmQKIHRoZSByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91
IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhl
IHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUg
cmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBz
ZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxs
eSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVz
dCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlz
CiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAp
LgoKDQoFBAcCAgUSBLgCAggKDQoFBAcCAgESBLgCCRMKDQoFBAcCAgMSBLgCFhcKDQoFBAcC
AggSBLgCGEAKEAoIBAcCAgicCAASBLgCGT8KMQoCBAgSBrwCANMCARojIE1lc3NhZ2UgZm9y
IHJlc3VtaW5nIGEgQ29sbGVjdG9yLgoKCwoDBAgBEgS8AggeCjEKBAQIAgASBr4CAsMCBBoh
IFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNvdXJjZS4KCg0KBQQIAgAFEgS+AgIICg0KBQQI
AgABEgS+AgkNCg0KBQQIAgADEgS+AhARCg8KBQQIAgAIEga+AhLDAgMKEAoIBAgCAAicCAAS
BL8CBCoKEQoHBAgCAAifCBIGwAIEwgIFCo8GCgQECAIBEgTSAgJBGoAGIE9wdGlvbmFsLiBB
biBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEg
dW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1
ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0
IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwKIGd1YXJhbnRl
ZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIGFmdGVyIHRoZSBmaXJzdCByZXF1ZXN0
LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBh
biBpbml0aWFsIHJlcXVlc3QgYW5kCiB0aGUgcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBt
YWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBz
ZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJl
cXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vj
b25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkg
Y3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3Qg
YmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwog
bm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4K
Cg0KBQQIAgEFEgTSAgIICg0KBQQIAgEBEgTSAgkTCg0KBQQIAgEDEgTSAhYXCg0KBQQIAgEI
EgTSAhhAChAKCAQIAgEInAgAEgTSAhk/CjQKAgQJEgbWAgDtAgEaJiBNZXNzYWdlIGZvciBy
ZWdpc3RlcmluZyBhIENvbGxlY3Rvci4KCgsKAwQJARIE1gIIIAoxCgQECQIAEgbYAgLdAgQa
ISBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoNCgUECQIABRIE2AICCAoNCgUE
CQIAARIE2AIJDQoNCgUECQIAAxIE2AIQEQoPCgUECQIACBIG2AIS3QIDChAKCAQJAgAInAgA
EgTZAgQqChEKBwQJAgAInwgSBtoCBNwCBQqPBgoEBAkCARIE7AICQRqABiBPcHRpb25hbC4g
QW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBh
IHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVx
dWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBp
dCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsCiBndWFyYW50
ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBhZnRlciB0aGUgZmlyc3QgcmVxdWVz
dC4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2Ug
YW4gaW5pdGlhbCByZXF1ZXN0IGFuZAogdGhlIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3Ug
bWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUg
c2VydmVyIGNhbiBjaGVjayBpZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSBy
ZXF1ZXN0IElECiB3YXMgcmVjZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNl
Y29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5
IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0
IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMK
IG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCku
CgoNCgUECQIBBRIE7AICCAoNCgUECQIBARIE7AIJEwoNCgUECQIBAxIE7AIWFwoNCgUECQIB
CBIE7AIYQAoQCggECQIBCJwIABIE7AIZPwowCgIEChIG8AIAhwMBGiIgTWVzc2FnZSBmb3Ig
cGF1c2luZyBhIENvbGxlY3Rvci4KCgsKAwQKARIE8AIIHQoxCgQECgIAEgbyAgL3AgQaISBS
ZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoNCgUECgIABRIE8gICCAoNCgUECgIA
ARIE8gIJDQoNCgUECgIAAxIE8gIQEQoPCgUECgIACBIG8gIS9wIDChAKCAQKAgAInAgAEgTz
AgQqChEKBwQKAgAInwgSBvQCBPYCBQqPBgoEBAoCARIEhgMCQRqABiBPcHRpb25hbC4gQW4g
b3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVu
aXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVz
dCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBo
YXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciB3aWxsCiBndWFyYW50ZWUg
dGhhdCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBhZnRlciB0aGUgZmlyc3QgcmVxdWVzdC4K
CiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4g
aW5pdGlhbCByZXF1ZXN0IGFuZAogdGhlIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFr
ZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2Vy
dmVyIGNhbiBjaGVjayBpZiBvcmlnaW5hbCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1
ZXN0IElECiB3YXMgcmVjZWl2ZWQsIGFuZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29u
ZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzCiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNy
ZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJl
IGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5v
dCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoN
CgUECgIBBRIEhgMCCAoNCgUECgIBARIEhgMJEwoNCgUECgIBAxIEhgMWFwoNCgUECgIBCBIE
hgMYQAoQCggECgIBCJwIABIEhgMZPwpGCgIECxIGigMApQMBGjggUmVwcmVzZW50cyB0aGUg
bWV0YWRhdGEgb2YgdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoLCgMECwESBIoDCBkK
QgoEBAsCABIGjAMCjQMyGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24g
d2FzIGNyZWF0ZWQuCgoNCgUECwIABhIEjAMCGwoNCgUECwIAARIEjAMcJwoNCgUECwIAAxIE
jAMqKwoNCgUECwIACBIEjQMGMQoQCggECwIACJwIABIEjQMHMApHCgQECwIBEgaQAwKRAzIa
NyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5n
LgoKDQoFBAsCAQYSBJADAhsKDQoFBAsCAQESBJADHCQKDQoFBAsCAQMSBJADJygKDQoFBAsC
AQgSBJEDBjEKEAoIBAsCAQicCAASBJEDBzAKWgoEBAsCAhIElAMCQBpMIE91dHB1dCBvbmx5
LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRoIGZvciB0aGUgdGFyZ2V0IG9mIHRoZSBv
cGVyYXRpb24uCgoNCgUECwICBRIElAMCCAoNCgUECwICARIElAMJDwoNCgUECwICAxIElAMS
EwoNCgUECwICCBIElAMUPwoQCggECwICCJwIABIElAMVPgpICgQECwIDEgSXAwI+GjogT3V0
cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkgdGhlIG9wZXJhdGlvbi4K
Cg0KBQQLAgMFEgSXAwIICg0KBQQLAgMBEgSXAwkNCg0KBQQLAgMDEgSXAxARCg0KBQQLAgMI
EgSXAxI9ChAKCAQLAgMInAgAEgSXAxM8CkwKBAQLAgQSBJoDAkgaPiBPdXRwdXQgb25seS4g
SHVtYW4tcmVhZGFibGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRpb24sIGlmIGFueS4KCg0KBQQL
AgQFEgSaAwIICg0KBQQLAgQBEgSaAwkXCg0KBQQLAgQDEgSaAxobCg0KBQQLAgQIEgSaAxxH
ChAKCAQLAgQInAgAEgSaAx1GCpsCCgQECwIFEgShAwJOGowCIE91dHB1dCBvbmx5LiBJZGVu
dGlmaWVzIHdoZXRoZXIgdGhlIHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24KIG9m
IHRoZSBvcGVyYXRpb24uIE9wZXJhdGlvbnMgdGhhdCBoYXZlIHN1Y2Nlc3NmdWxseSBiZWVu
IGNhbmNlbGxlZAogaGF2ZSBbT3BlcmF0aW9uLmVycm9yXVtdIHZhbHVlIHdpdGggYQogW2dv
b2dsZS5ycGMuU3RhdHVzLmNvZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsIGNv
cnJlc3BvbmRpbmcgdG8KIGBDb2RlLkNBTkNFTExFRGAuCgoNCgUECwIFBRIEoQMCBgoNCgUE
CwIFARIEoQMHHQoNCgUECwIFAxIEoQMgIQoNCgUECwIFCBIEoQMiTQoQCggECwIFCJwIABIE
oQMjTApFCgQECwIGEgSkAwJFGjcgT3V0cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8g
c3RhcnQgdGhlIG9wZXJhdGlvbi4KCg0KBQQLAgYFEgSkAwIICg0KBQQLAgYBEgSkAwkUCg0K
BQQLAgYDEgSkAxcYCg0KBQQLAgYIEgSkAxlEChAKCAQLAgYInAgAEgSkAxpDYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateAnnotationRequest ===
    # Fields for CreateAnnotationRequest
    # Field: parent Type: 9 ()
    # Field: annotation Type: 11 (.google.cloud.rapidmigrationassessment.v1.Annotation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetAnnotationRequest ===
    # Fields for GetAnnotationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateCollectorRequest ===
    # Fields for CreateCollectorRequest
    # Field: parent Type: 9 ()
    # Field: collector_id Type: 9 ()
    # Field: collector Type: 11 (.google.cloud.rapidmigrationassessment.v1.Collector)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsRequest ===
    # Fields for ListCollectorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsResponse ===
    # Fields for ListCollectorsResponse
    # Field: collectors Type: 11 (.google.cloud.rapidmigrationassessment.v1.Collector)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetCollectorRequest ===
    # Fields for GetCollectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::DeleteCollectorRequest ===
    # Fields for DeleteCollectorRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::UpdateCollectorRequest ===
    # Fields for UpdateCollectorRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: collector Type: 11 (.google.cloud.rapidmigrationassessment.v1.Collector)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ResumeCollectorRequest ===
    # Fields for ResumeCollectorRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RegisterCollectorRequest ===
    # Fields for RegisterCollectorRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::PauseCollectorRequest ===
    # Fields for PauseCollectorRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RapidMigrationAssessmentClient ===
package Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RapidMigrationAssessmentClient;

=pod

=head2 Service Client: Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RapidMigrationAssessmentClient

Client stub representing the remote C<RapidMigrationAssessment> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<rapidmigrationassessment.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'rapidmigrationassessment.googleapis.com:443' );

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

sub create_collector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateCollectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'CreateCollector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub create_annotation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateAnnotationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'CreateAnnotation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_annotation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetAnnotationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'GetAnnotation',
        request        => $req,
        response_class => 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation',
    });
}

sub list_collectors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'ListCollectors',
        request        => $req,
        response_class => 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsResponse',
    });
}

sub get_collector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetCollectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'GetCollector',
        request        => $req,
        response_class => 'Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector',
    });
}

sub update_collector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::UpdateCollectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'UpdateCollector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_collector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::DeleteCollectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'DeleteCollector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub resume_collector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ResumeCollectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'ResumeCollector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub register_collector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RegisterCollectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'RegisterCollector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub pause_collector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::PauseCollectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.rapidmigrationassessment.v1.RapidMigrationAssessment',
        method         => 'PauseCollector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment - Compiled Protocol Buffers messages for google/cloud/rapidmigrationassessment/v1/rapidmigrationassessment.proto

=head1 SYNOPSIS

    use Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment;

    my $msg = Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateAnnotationRequest->new({
        parent => $parent,
        annotation => $annotation,
        request_id => $request_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateAnnotationRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/rapidmigrationassessment/v1/rapidmigrationassessment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateAnnotationRequest

Message for creating an AnnotationS.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of the parent (project+location).

=item * C<< $msg->annotation() >> / C<< $msg->annotation($value) >>

Type: C<Message> (L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Annotation>)

Required. The resource being created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests.

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetAnnotationRequest

Message for getting a specific Annotation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateCollectorRequest

Message for creating a Collector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Name of the parent (project+location).

=item * C<< $msg->collector_id() >> / C<< $msg->collector_id($value) >>

Type: C<String>

Required. Id of the requesting object.

=item * C<< $msg->collector() >> / C<< $msg->collector($value) >>

Type: C<Message> (L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector>)

Required. The resource being created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests.

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsRequest

Message for requesting list of Collectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListCollectorsRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. Server may return fewer items than requested.
If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filtering results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Hint for how to order the results.

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsResponse

Message for response to listing Collectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->collectors() >> / C<< $msg->collectors($value) >>

Type: C<Message> (L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector>)

The list of Collectors.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetCollectorRequest

Message for getting a specific Collector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::DeleteCollectorRequest

Message for deleting a Collector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::UpdateCollectorRequest

Message for updating a Collector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
Collector resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->collector() >> / C<< $msg->collector($value) >>

Type: C<Message> (L<Google::Cloud::Rapidmigrationassessment::V1::ApiEntities::Collector>)

Required. The resource being updated.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ResumeCollectorRequest

Message for resuming a Collector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RegisterCollectorRequest

Message for registering a Collector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::PauseCollectorRequest

Message for pausing a Collector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
