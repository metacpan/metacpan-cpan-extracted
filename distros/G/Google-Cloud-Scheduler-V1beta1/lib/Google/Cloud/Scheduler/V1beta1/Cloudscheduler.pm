package Google::Cloud::Scheduler::V1beta1::Cloudscheduler;

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
    eval { require Google::Cloud::Scheduler::V1beta1::Job };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvc2NoZWR1bGVyL3YxYmV0YTEvY2xvdWRzY2hlZHVsZXIucHJvdG8S
Hmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9u
cy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC9z
Y2hlZHVsZXIvdjFiZXRhMS9qb2IucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90
bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8i3QEKD0xpc3RKb2JzUmVxdWVz
dBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIxIhY2xvdWRzY2hlZHVsZXIuZ29vZ2xlYXBpcy5j
b20vSm9iUgZwYXJlbnQSFgoGZmlsdGVyGAQgASgJUgZmaWx0ZXISGwoJcGFnZV9zaXplGAUg
ASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAYgASgJUglwYWdlVG9rZW4SMwoWbGVnYWN5
X2FwcF9lbmdpbmVfY3JvbhgHIAEoCFITbGVnYWN5QXBwRW5naW5lQ3JvbiJzChBMaXN0Sm9i
c1Jlc3BvbnNlEjcKBGpvYnMYASADKAsyIy5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0
YTEuSm9iUgRqb2JzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJO
Cg1HZXRKb2JSZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohY2xvdWRzY2hlZHVsZXIu
Z29vZ2xlYXBpcy5jb20vSm9iUgRuYW1lIpEBChBDcmVhdGVKb2JSZXF1ZXN0EkEKBnBhcmVu
dBgBIAEoCUIp4EEC+kEjEiFjbG91ZHNjaGVkdWxlci5nb29nbGVhcGlzLmNvbS9Kb2JSBnBh
cmVudBI6CgNqb2IYAiABKAsyIy5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSm9i
QgPgQQJSA2pvYiKLAQoQVXBkYXRlSm9iUmVxdWVzdBI6CgNqb2IYASABKAsyIy5nb29nbGUu
Y2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSm9iQgPgQQJSA2pvYhI7Cgt1cGRhdGVfbWFzaxgC
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2sihgEKEERlbGV0
ZUpvYlJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFjbG91ZHNjaGVkdWxlci5nb29n
bGVhcGlzLmNvbS9Kb2JSBG5hbWUSMwoWbGVnYWN5X2FwcF9lbmdpbmVfY3JvbhgCIAEoCFIT
bGVnYWN5QXBwRW5naW5lQ3JvbiJQCg9QYXVzZUpvYlJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp
4EEC+kEjCiFjbG91ZHNjaGVkdWxlci5nb29nbGVhcGlzLmNvbS9Kb2JSBG5hbWUiUQoQUmVz
dW1lSm9iUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWNsb3Vkc2NoZWR1bGVyLmdv
b2dsZWFwaXMuY29tL0pvYlIEbmFtZSKDAQoNUnVuSm9iUmVxdWVzdBI9CgRuYW1lGAEgASgJ
QingQQL6QSMKIWNsb3Vkc2NoZWR1bGVyLmdvb2dsZWFwaXMuY29tL0pvYlIEbmFtZRIzChZs
ZWdhY3lfYXBwX2VuZ2luZV9jcm9uGAIgASgIUhNsZWdhY3lBcHBFbmdpbmVDcm9uMqYLCg5D
bG91ZFNjaGVkdWxlchKtAQoITGlzdEpvYnMSLy5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYx
YmV0YTEuTGlzdEpvYnNSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGEx
Lkxpc3RKb2JzUmVzcG9uc2UiPoLT5JMCLxItL3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qfS9qb2Jz2kEGcGFyZW50EpoBCgZHZXRKb2ISLS5nb29nbGUuY2xvdWQu
c2NoZWR1bGVyLnYxYmV0YTEuR2V0Sm9iUmVxdWVzdBojLmdvb2dsZS5jbG91ZC5zY2hlZHVs
ZXIudjFiZXRhMS5Kb2IiPILT5JMCLxItL3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9qb2JzLyp92kEEbmFtZRKrAQoJQ3JlYXRlSm9iEjAuZ29vZ2xlLmNsb3VkLnNj
aGVkdWxlci52MWJldGExLkNyZWF0ZUpvYlJlcXVlc3QaIy5nb29nbGUuY2xvdWQuc2NoZWR1
bGVyLnYxYmV0YTEuSm9iIkeC0+STAjQiLS92MWJldGExL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKn0vam9iczoDam9i2kEKcGFyZW50LGpvYhK0AQoJVXBkYXRlSm9iEjAuZ29v
Z2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLlVwZGF0ZUpvYlJlcXVlc3QaIy5nb29nbGUu
Y2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSm9iIlCC0+STAjgyMS92MWJldGExL3tqb2IubmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMvKn06A2pvYtpBD2pvYix1cGRhdGVfbWFz
axKTAQoJRGVsZXRlSm9iEjAuZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkRlbGV0
ZUpvYlJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiPILT5JMCLyotL3YxYmV0YTEv
e25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9qb2JzLyp92kEEbmFtZRKnAQoIUGF1c2VK
b2ISLy5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuUGF1c2VKb2JSZXF1ZXN0GiMu
Z29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkpvYiJFgtPkkwI4IjMvdjFiZXRhMS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMvKn06cGF1c2U6ASraQQRuYW1lEqoB
CglSZXN1bWVKb2ISMC5nb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuUmVzdW1lSm9i
UmVxdWVzdBojLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5Kb2IiRoLT5JMCOSI0
L3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9qb2JzLyp9OnJlc3VtZToB
KtpBBG5hbWUSoQEKBlJ1bkpvYhItLmdvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5S
dW5Kb2JSZXF1ZXN0GiMuZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkpvYiJDgtPk
kwI2IjEvdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2pvYnMvKn06cnVu
OgEq2kEEbmFtZRpRykEdY2xvdWRzY2hlZHVsZXIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQoQBCiJjb20uZ29vZ2xl
LmNsb3VkLnNjaGVkdWxlci52MWJldGExQg5TY2hlZHVsZXJQcm90b1ABWkBjbG91ZC5nb29n
bGUuY29tL2dvL3NjaGVkdWxlci9hcGl2MWJldGExL3NjaGVkdWxlcnBiO3NjaGVkdWxlcnBi
ogIJU0NIRURVTEVSSuNMCgcSBQ4AugIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
bnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYAMgoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgBXCgkKAggL
EgMaAFcKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAAvCgkKAggIEgMcAC8KCAoBCBID
HQA7CgkKAggBEgMdADsKCAoBCBIDHgAnCgkKAggkEgMeACcKaAoCBgASBSIAiwEBGlsgVGhl
IENsb3VkIFNjaGVkdWxlciBBUEkgYWxsb3dzIGV4dGVybmFsIGVudGl0aWVzIHRvIHJlbGlh
Ymx5CiBzY2hlZHVsZSBhc3luY2hyb25vdXMgam9icy4KCgoKAwYAARIDIggWCgoKAwYAAxID
IwJFCgwKBQYAA5kIEgMjAkUKCwoDBgADEgQkAiU3Cg0KBQYAA5oIEgQkAiU3ChsKBAYAAgAS
BCgCLQMaDSBMaXN0cyBqb2JzLgoKDAoFBgACAAESAygGDgoMCgUGAAIAAhIDKA8eCgwKBQYA
AgADEgMoKTkKDQoFBgACAAQSBCkEKwYKEQoJBgACAASwyrwiEgQpBCsGCgwKBQYAAgAEEgMs
BDQKDwoIBgACAASbCAASAywENAobCgQGAAIBEgQwAjUDGg0gR2V0cyBhIGpvYi4KCgwKBQYA
AgEBEgMwBgwKDAoFBgACAQISAzANGgoMCgUGAAIBAxIDMCUoCg0KBQYAAgEEEgQxBDMGChEK
CQYAAgEEsMq8IhIEMQQzBgoMCgUGAAIBBBIDNAQyCg8KCAYAAgEEmwgAEgM0BDIKHgoEBgAC
AhIEOAI+AxoQIENyZWF0ZXMgYSBqb2IuCgoMCgUGAAICARIDOAYPCgwKBQYAAgICEgM4ECAK
DAoFBgACAgMSAzgrLgoNCgUGAAICBBIEOQQ8BgoRCgkGAAICBLDKvCISBDkEPAYKDAoFBgAC
AgQSAz0EOAoPCggGAAICBJsIABIDPQQ4CtgDCgQGAAIDEgRKAlADGskDIFVwZGF0ZXMgYSBq
b2IuCgogSWYgc3VjY2Vzc2Z1bCwgdGhlIHVwZGF0ZWQgW0pvYl1bZ29vZ2xlLmNsb3VkLnNj
aGVkdWxlci52MWJldGExLkpvYl0gaXMKIHJldHVybmVkLiBJZiB0aGUgam9iIGRvZXMgbm90
IGV4aXN0LCBgTk9UX0ZPVU5EYCBpcyByZXR1cm5lZC4KCiBJZiBVcGRhdGVKb2IgZG9lcyBu
b3Qgc3VjY2Vzc2Z1bGx5IHJldHVybiwgaXQgaXMgcG9zc2libGUgZm9yIHRoZQogam9iIHRv
IGJlIGluIGFuCiBbSm9iLlN0YXRlLlVQREFURV9GQUlMRURdW2dvb2dsZS5jbG91ZC5zY2hl
ZHVsZXIudjFiZXRhMS5Kb2IuU3RhdGUuVVBEQVRFX0ZBSUxFRF0KIHN0YXRlLiBBIGpvYiBp
biB0aGlzIHN0YXRlIG1heSBub3QgYmUgZXhlY3V0ZWQuIElmIHRoaXMgaGFwcGVucywgcmV0
cnkgdGhlCiBVcGRhdGVKb2IgcmVxdWVzdCB1bnRpbCBhIHN1Y2Nlc3NmdWwgcmVzcG9uc2Ug
aXMgcmVjZWl2ZWQuCgoMCgUGAAIDARIDSgYPCgwKBQYAAgMCEgNKECAKDAoFBgACAwMSA0or
LgoNCgUGAAIDBBIESwROBgoRCgkGAAIDBLDKvCISBEsETgYKDAoFBgACAwQSA08EPQoPCggG
AAIDBJsIABIDTwQ9Ch4KBAYAAgQSBFMCWAMaECBEZWxldGVzIGEgam9iLgoKDAoFBgACBAES
A1MGDwoMCgUGAAIEAhIDUxAgCgwKBQYAAgQDEgNTK0AKDQoFBgACBAQSBFQEVgYKEQoJBgAC
BASwyrwiEgRUBFYGCgwKBQYAAgQEEgNXBDIKDwoIBgACBASbCAASA1cEMgrjAwoEBgACBRIE
ZQJrAxrUAyBQYXVzZXMgYSBqb2IuCgogSWYgYSBqb2IgaXMgcGF1c2VkIHRoZW4gdGhlIHN5
c3RlbSB3aWxsIHN0b3AgZXhlY3V0aW5nIHRoZSBqb2IKIHVudGlsIGl0IGlzIHJlLWVuYWJs
ZWQgdmlhCiBbUmVzdW1lSm9iXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQ2xv
dWRTY2hlZHVsZXIuUmVzdW1lSm9iXS4gVGhlCiBzdGF0ZSBvZiB0aGUgam9iIGlzIHN0b3Jl
ZCBpbgogW3N0YXRlXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSm9iLnN0YXRl
XTsgaWYgcGF1c2VkIGl0IHdpbGwgYmUgc2V0CiB0byBbSm9iLlN0YXRlLlBBVVNFRF1bZ29v
Z2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkpvYi5TdGF0ZS5QQVVTRURdLiBBCiBqb2Ig
bXVzdCBiZSBpbgogW0pvYi5TdGF0ZS5FTkFCTEVEXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVy
LnYxYmV0YTEuSm9iLlN0YXRlLkVOQUJMRURdIHRvIGJlCiBwYXVzZWQuCgoMCgUGAAIFARID
ZQYOCgwKBQYAAgUCEgNlDx4KDAoFBgACBQMSA2UpLAoNCgUGAAIFBBIEZgRpBgoRCgkGAAIF
BLDKvCISBGYEaQYKDAoFBgACBQQSA2oEMgoPCggGAAIFBJsIABIDagQyCskDCgQGAAIGEgR4
An4DGroDIFJlc3VtZSBhIGpvYi4KCiBUaGlzIG1ldGhvZCByZWVuYWJsZXMgYSBqb2IgYWZ0
ZXIgaXQgaGFzIGJlZW4KIFtKb2IuU3RhdGUuUEFVU0VEXVtnb29nbGUuY2xvdWQuc2NoZWR1
bGVyLnYxYmV0YTEuSm9iLlN0YXRlLlBBVVNFRF0uIFRoZQogc3RhdGUgb2YgYSBqb2IgaXMg
c3RvcmVkIGluCiBbSm9iLnN0YXRlXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEu
Sm9iLnN0YXRlXTsgYWZ0ZXIgY2FsbGluZyB0aGlzCiBtZXRob2QgaXQgd2lsbCBiZSBzZXQg
dG8KIFtKb2IuU3RhdGUuRU5BQkxFRF1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGEx
LkpvYi5TdGF0ZS5FTkFCTEVEXS4gQQogam9iIG11c3QgYmUgaW4KIFtKb2IuU3RhdGUuUEFV
U0VEXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSm9iLlN0YXRlLlBBVVNFRF0g
dG8gYmUKIHJlc3VtZWQuCgoMCgUGAAIGARIDeAYPCgwKBQYAAgYCEgN4ECAKDAoFBgACBgMS
A3grLgoNCgUGAAIGBBIEeQR8BgoRCgkGAAIGBLDKvCISBHkEfAYKDAoFBgACBgQSA30EMgoP
CggGAAIGBJsIABIDfQQyCpUBCgQGAAIHEgaEAQKKAQMahAEgRm9yY2VzIGEgam9iIHRvIHJ1
biBub3cuCgogV2hlbiB0aGlzIG1ldGhvZCBpcyBjYWxsZWQsIENsb3VkIFNjaGVkdWxlciB3
aWxsIGRpc3BhdGNoIHRoZSBqb2IsIGV2ZW4KIGlmIHRoZSBqb2IgaXMgYWxyZWFkeSBydW5u
aW5nLgoKDQoFBgACBwESBIQBBgwKDQoFBgACBwISBIQBDRoKDQoFBgACBwMSBIQBJSgKDwoF
BgACBwQSBoUBBIgBBgoTCgkGAAIHBLDKvCISBoUBBIgBBgoNCgUGAAIHBBIEiQEEMgoQCggG
AAIHBJsIABIEiQEEMgp7CgIEABIGjwEAuwEBGm0gUmVxdWVzdCBtZXNzYWdlIGZvciBsaXN0
aW5nIGpvYnMgdXNpbmcKIFtMaXN0Sm9ic11bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJl
dGExLkNsb3VkU2NoZWR1bGVyLkxpc3RKb2JzXS4KCgsKAwQAARIEjwEIFwppCgQEAAIAEgaS
AQKXAQQaWSBSZXF1aXJlZC4gVGhlIGxvY2F0aW9uIG5hbWUuIEZvciBleGFtcGxlOgogYHBy
b2plY3RzL1BST0pFQ1RfSUQvbG9jYXRpb25zL0xPQ0FUSU9OX0lEYC4KCg0KBQQAAgAFEgSS
AQIICg0KBQQAAgABEgSSAQkPCg0KBQQAAgADEgSSARITCg8KBQQAAgAIEgaSARSXAQMKEAoI
BAACAAicCAASBJMBBCoKEQoHBAACAAifCBIGlAEElgEFCo0DCgQEAAIBEgShAQIUGv4CIGBm
aWx0ZXJgIGNhbiBiZSB1c2VkIHRvIHNwZWNpZnkgYSBzdWJzZXQgb2Ygam9icy4KCiBJZiBg
ZmlsdGVyYCBlcXVhbHMgYHRhcmdldF9jb25maWc9Ikh0dHBDb25maWciYCwgdGhlbiB0aGUg
aHR0cAogdGFyZ2V0IGpvYnMgYXJlIHJldHJpZXZlZC4gSWYgYGZpbHRlcmAgZXF1YWxzCiBg
dGFyZ2V0X2NvbmZpZz0iUHViU3ViQ29uZmlnImAsIHRoZW4gdGhlIFB1Yi9TdWIgdGFyZ2V0
IGpvYnMgYXJlCiByZXRyaWV2ZWQuIElmIGBmaWx0ZXJgIGVxdWFscyBgbGFiZWxzLmZvbz12
YWx1ZTEKIGxhYmVscy5mb289dmFsdWUyYCB0aGVuIG9ubHkgam9icyB3aGljaCBhcmUgbGFi
ZWxlZCB3aXRoCiBmb289dmFsdWUxIEFORCBmb289dmFsdWUyIHdpbGwgYmUgcmV0dXJuZWQu
CgoNCgUEAAIBBRIEoQECCAoNCgUEAAIBARIEoQEJDwoNCgUEAAIBAxIEoQESEwr2AQoEBAAC
AhIEqQECFhrnASBSZXF1ZXN0ZWQgcGFnZSBzaXplLgoKIFRoZSBtYXhpbXVtIHBhZ2Ugc2l6
ZSBpcyA1MDAuIElmIHVuc3BlY2lmaWVkLCB0aGUgcGFnZSBzaXplIHdpbGwKIGJlIHRoZSBt
YXhpbXVtLiBGZXdlciBqb2JzIHRoYW4gcmVxdWVzdGVkIG1pZ2h0IGJlIHJldHVybmVkLAog
ZXZlbiBpZiBtb3JlIGpvYnMgZXhpc3Q7IHVzZSBuZXh0X3BhZ2VfdG9rZW4gdG8gZGV0ZXJt
aW5lIGlmIG1vcmUKIGpvYnMgZXhpc3QuCgoNCgUEAAICBRIEqQECBwoNCgUEAAICARIEqQEI
EQoNCgUEAAICAxIEqQEUFQrfBAoEBAACAxIEtQECGBrQBCBBIHRva2VuIGlkZW50aWZ5aW5n
IGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgd2lsbCByZXR1cm4uIFRvCiByZXF1ZXN0
IHRoZSBmaXJzdCBwYWdlIHJlc3VsdHMsIHBhZ2VfdG9rZW4gbXVzdCBiZSBlbXB0eS4gVG8K
IHJlcXVlc3QgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBwYWdlX3Rva2VuIG11c3QgYmUg
dGhlIHZhbHVlIG9mCiBbbmV4dF9wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVy
LnYxYmV0YTEuTGlzdEpvYnNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dCiByZXR1cm5lZCBm
cm9tIHRoZSBwcmV2aW91cyBjYWxsIHRvCiBbTGlzdEpvYnNdW2dvb2dsZS5jbG91ZC5zY2hl
ZHVsZXIudjFiZXRhMS5DbG91ZFNjaGVkdWxlci5MaXN0Sm9ic10uIEl0IGlzCiBhbiBlcnJv
ciB0byBzd2l0Y2ggdGhlIHZhbHVlIG9mCiBbZmlsdGVyXVtnb29nbGUuY2xvdWQuc2NoZWR1
bGVyLnYxYmV0YTEuTGlzdEpvYnNSZXF1ZXN0LmZpbHRlcl0gb3IKIFtvcmRlcl9ieV1bZ29v
Z2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkxpc3RKb2JzUmVxdWVzdC5vcmRlcl9ieV0g
d2hpbGUKIGl0ZXJhdGluZyB0aHJvdWdoIHBhZ2VzLgoKDQoFBAACAwUSBLUBAggKDQoFBAAC
AwESBLUBCRMKDQoFBAACAwMSBLUBFhcKwAEKBAQAAgQSBLoBAiIasQEgVGhpcyBmaWVsZCBp
cyB1c2VkIHRvIG1hbmFnZSB0aGUgbGVnYWN5IEFwcCBFbmdpbmUgQ3JvbiBqb2JzIHVzaW5n
IHRoZQogQ2xvdWQgU2NoZWR1bGVyIEFQSS4gSWYgdGhlIGZpZWxkIGlzIHNldCB0byB0cnVl
LCB0aGUgam9icyBpbiB0aGUgX19jcm9uCiBxdWV1ZSB3aWxsIGJlIGxpc3RlZCBpbnN0ZWFk
LgoKDQoFBAACBAUSBLoBAgYKDQoFBAACBAESBLoBBx0KDQoFBAACBAMSBLoBICEKfAoCBAES
Br8BAMwBARpuIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIGxpc3Rpbmcgam9icyB1c2luZwogW0xp
c3RKb2JzXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQ2xvdWRTY2hlZHVsZXIu
TGlzdEpvYnNdLgoKCwoDBAEBEgS/AQgYCiEKBAQBAgASBMEBAhgaEyBUaGUgbGlzdCBvZiBq
b2JzLgoKDQoFBAECAAQSBMEBAgoKDQoFBAECAAYSBMEBCw4KDQoFBAECAAESBMEBDxMKDQoF
BAECAAMSBMEBFhcKqwMKBAQBAgESBMsBAh0anAMgQSB0b2tlbiB0byByZXRyaWV2ZSBuZXh0
IHBhZ2Ugb2YgcmVzdWx0cy4gUGFzcyB0aGlzIHZhbHVlIGluIHRoZQogW3BhZ2VfdG9rZW5d
W2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5MaXN0Sm9ic1JlcXVlc3QucGFnZV90
b2tlbl0KIGZpZWxkIGluIHRoZSBzdWJzZXF1ZW50IGNhbGwgdG8KIFtMaXN0Sm9ic11bZ29v
Z2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkNsb3VkU2NoZWR1bGVyLkxpc3RKb2JzXSB0
bwogcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLiBJZiB0aGlzIGlzIGVtcHR5
IGl0IGluZGljYXRlcyB0aGF0IHRoZXJlCiBhcmUgbm8gbW9yZSByZXN1bHRzIHRocm91Z2gg
d2hpY2ggdG8gcGFnaW5hdGUuCgogVGhlIHBhZ2UgdG9rZW4gaXMgdmFsaWQgZm9yIG9ubHkg
MiBob3Vycy4KCg0KBQQBAgEFEgTLAQIICg0KBQQBAgEBEgTLAQkYCg0KBQQBAgEDEgTLARsc
CmQKAgQCEgbQAQDZAQEaViBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbR2V0Sm9iXVtnb29nbGUu
Y2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQ2xvdWRTY2hlZHVsZXIuR2V0Sm9iXS4KCgsKAwQC
ARIE0AEIFQpwCgQEAgIAEgbTAQLYAQQaYCBSZXF1aXJlZC4gVGhlIGpvYiBuYW1lLiBGb3Ig
ZXhhbXBsZToKIGBwcm9qZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9ucy9MT0NBVElPTl9JRC9q
b2JzL0pPQl9JRGAuCgoNCgUEAgIABRIE0wECCAoNCgUEAgIAARIE0wEJDQoNCgUEAgIAAxIE
0wEQEQoPCgUEAgIACBIG0wES2AEDChAKCAQCAgAInAgAEgTUAQQqChEKBwQCAgAInwgSBtUB
BNcBBQpqCgIEAxIG3QEA7gEBGlwgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0NyZWF0ZUpvYl1b
Z29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkNsb3VkU2NoZWR1bGVyLkNyZWF0ZUpv
Yl0uCgoLCgMEAwESBN0BCBgKaQoEBAMCABIG4AEC5QEEGlkgUmVxdWlyZWQuIFRoZSBsb2Nh
dGlvbiBuYW1lLiBGb3IgZXhhbXBsZToKIGBwcm9qZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9u
cy9MT0NBVElPTl9JRGAuCgoNCgUEAwIABRIE4AECCAoNCgUEAwIAARIE4AEJDwoNCgUEAwIA
AxIE4AESEwoPCgUEAwIACBIG4AEU5QEDChAKCAQDAgAInAgAEgThAQQqChEKBwQDAgAInwgS
BuIBBOQBBQqUAwoEBAMCARIE7QECNxqFAyBSZXF1aXJlZC4gVGhlIGpvYiB0byBhZGQuIFRo
ZSB1c2VyIGNhbiBvcHRpb25hbGx5IHNwZWNpZnkgYSBuYW1lIGZvciB0aGUKIGpvYiBpbiBb
bmFtZV1bZ29vZ2xlLmNsb3VkLnNjaGVkdWxlci52MWJldGExLkpvYi5uYW1lXS4KIFtuYW1l
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuSm9iLm5hbWVdIGNhbm5vdCBiZSB0
aGUgc2FtZSBhcyBhbgogZXhpc3Rpbmcgam9iLiBJZiBhIG5hbWUgaXMgbm90IHNwZWNpZmll
ZCB0aGVuIHRoZSBzeXN0ZW0gd2lsbAogZ2VuZXJhdGUgYSByYW5kb20gdW5pcXVlIG5hbWUg
dGhhdCB3aWxsIGJlIHJldHVybmVkCiAoW25hbWVdW2dvb2dsZS5jbG91ZC5zY2hlZHVsZXIu
djFiZXRhMS5Kb2IubmFtZV0pIGluIHRoZSByZXNwb25zZS4KCg0KBQQDAgEGEgTtAQIFCg0K
BQQDAgEBEgTtAQYJCg0KBQQDAgEDEgTtAQwNCg0KBQQDAgEIEgTtAQ42ChAKCAQDAgEInAgA
EgTtAQ81CmoKAgQEEgbyAQD8AQEaXCBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVXBkYXRlSm9i
XVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQ2xvdWRTY2hlZHVsZXIuVXBkYXRl
Sm9iXS4KCgsKAwQEARIE8gEIGAruAQoEBAQCABIE+AECNxrfASBSZXF1aXJlZC4gVGhlIG5l
dyBqb2IgcHJvcGVydGllcy4KIFtuYW1lXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0
YTEuSm9iLm5hbWVdIG11c3QgYmUgc3BlY2lmaWVkLgoKIE91dHB1dCBvbmx5IGZpZWxkcyBj
YW5ub3QgYmUgbW9kaWZpZWQgdXNpbmcgVXBkYXRlSm9iLgogQW55IHZhbHVlIHNwZWNpZmll
ZCBmb3IgYW4gb3V0cHV0IG9ubHkgZmllbGQgd2lsbCBiZSBpZ25vcmVkLgoKDQoFBAQCAAYS
BPgBAgUKDQoFBAQCAAESBPgBBgkKDQoFBAQCAAMSBPgBDA0KDQoFBAQCAAgSBPgBDjYKEAoI
BAQCAAicCAASBPgBDzUKUgoEBAQCARIE+wECLBpEIEEgIG1hc2sgdXNlZCB0byBzcGVjaWZ5
IHdoaWNoIGZpZWxkcyBvZiB0aGUgam9iIGFyZSBiZWluZyB1cGRhdGVkLgoKDQoFBAQCAQYS
BPsBAhsKDQoFBAQCAQESBPsBHCcKDQoFBAQCAQMSBPsBKisKfwoCBAUSBoACAI4CARpxIFJl
cXVlc3QgbWVzc2FnZSBmb3IgZGVsZXRpbmcgYSBqb2IgdXNpbmcKIFtEZWxldGVKb2JdW2dv
b2dsZS5jbG91ZC5zY2hlZHVsZXIudjFiZXRhMS5DbG91ZFNjaGVkdWxlci5EZWxldGVKb2Jd
LgoKCwoDBAUBEgSAAggYCnAKBAQFAgASBoMCAogCBBpgIFJlcXVpcmVkLiBUaGUgam9iIG5h
bWUuIEZvciBleGFtcGxlOgogYHByb2plY3RzL1BST0pFQ1RfSUQvbG9jYXRpb25zL0xPQ0FU
SU9OX0lEL2pvYnMvSk9CX0lEYC4KCg0KBQQFAgAFEgSDAgIICg0KBQQFAgABEgSDAgkNCg0K
BQQFAgADEgSDAhARCg8KBQQFAgAIEgaDAhKIAgMKEAoIBAUCAAicCAASBIQCBCoKEQoHBAUC
AAifCBIGhQIEhwIFCtwBCgQEBQIBEgSNAgIiGs0BIFRoaXMgZmllbGQgaXMgdXNlZCB0byBt
YW5hZ2UgdGhlIGxlZ2FjeSBBcHAgRW5naW5lIENyb24gam9icyB1c2luZyB0aGUKIENsb3Vk
IFNjaGVkdWxlciBBUEkuIElmIHRoZSBmaWVsZCBpcyBzZXQgdG8gdHJ1ZSwgdGhlIGpvYiBp
biB0aGUgX19jcm9uCiBxdWV1ZSB3aXRoIHRoZSBjb3JyZXNwb25kaW5nIG5hbWUgd2lsbCBi
ZSBkZWxldGVkIGluc3RlYWQuCgoNCgUEBQIBBRIEjQICBgoNCgUEBQIBARIEjQIHHQoNCgUE
BQIBAxIEjQIgIQpoCgIEBhIGkgIAmwIBGlogUmVxdWVzdCBtZXNzYWdlIGZvcgogW1BhdXNl
Sm9iXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQ2xvdWRTY2hlZHVsZXIuUGF1
c2VKb2JdLgoKCwoDBAYBEgSSAggXCnAKBAQGAgASBpUCApoCBBpgIFJlcXVpcmVkLiBUaGUg
am9iIG5hbWUuIEZvciBleGFtcGxlOgogYHByb2plY3RzL1BST0pFQ1RfSUQvbG9jYXRpb25z
L0xPQ0FUSU9OX0lEL2pvYnMvSk9CX0lEYC4KCg0KBQQGAgAFEgSVAgIICg0KBQQGAgABEgSV
AgkNCg0KBQQGAgADEgSVAhARCg8KBQQGAgAIEgaVAhKaAgMKEAoIBAYCAAicCAASBJYCBCoK
EQoHBAYCAAifCBIGlwIEmQIFCmoKAgQHEgafAgCoAgEaXCBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbUmVzdW1lSm9iXVtnb29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQ2xvdWRTY2hl
ZHVsZXIuUmVzdW1lSm9iXS4KCgsKAwQHARIEnwIIGApwCgQEBwIAEgaiAgKnAgQaYCBSZXF1
aXJlZC4gVGhlIGpvYiBuYW1lLiBGb3IgZXhhbXBsZToKIGBwcm9qZWN0cy9QUk9KRUNUX0lE
L2xvY2F0aW9ucy9MT0NBVElPTl9JRC9qb2JzL0pPQl9JRGAuCgoNCgUEBwIABRIEogICCAoN
CgUEBwIAARIEogIJDQoNCgUEBwIAAxIEogIQEQoPCgUEBwIACBIGogISpwIDChAKCAQHAgAI
nAgAEgSjAgQqChEKBwQHAgAInwgSBqQCBKYCBQqDAQoCBAgSBqwCALoCARp1IFJlcXVlc3Qg
bWVzc2FnZSBmb3IgZm9yY2luZyBhIGpvYiB0byBydW4gbm93IHVzaW5nCiBbUnVuSm9iXVtn
b29nbGUuY2xvdWQuc2NoZWR1bGVyLnYxYmV0YTEuQ2xvdWRTY2hlZHVsZXIuUnVuSm9iXS4K
CgsKAwQIARIErAIIFQpwCgQECAIAEgavAgK0AgQaYCBSZXF1aXJlZC4gVGhlIGpvYiBuYW1l
LiBGb3IgZXhhbXBsZToKIGBwcm9qZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9ucy9MT0NBVElP
Tl9JRC9qb2JzL0pPQl9JRGAuCgoNCgUECAIABRIErwICCAoNCgUECAIAARIErwIJDQoNCgUE
CAIAAxIErwIQEQoPCgUECAIACBIGrwIStAIDChAKCAQIAgAInAgAEgSwAgQqChEKBwQIAgAI
nwgSBrECBLMCBQriAQoEBAgCARIEuQICIhrTASBUaGlzIGZpZWxkIGlzIHVzZWQgdG8gbWFu
YWdlIHRoZSBsZWdhY3kgQXBwIEVuZ2luZSBDcm9uIGpvYnMgdXNpbmcgdGhlCiBDbG91ZCBT
Y2hlZHVsZXIgQVBJLiBJZiB0aGUgZmllbGQgaXMgc2V0IHRvIHRydWUsIHRoZSBqb2IgaW4g
dGhlIF9fY3JvbgogcXVldWUgd2l0aCB0aGUgY29ycmVzcG9uZGluZyBuYW1lIHdpbGwgYmUg
Zm9yY2VkIHRvIHJ1biBpbnN0ZWFkLgoKDQoFBAgCAQUSBLkCAgYKDQoFBAgCAQESBLkCBx0K
DQoFBAgCAQMSBLkCICFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsRequest ===
    # Fields for ListJobsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: legacy_app_engine_cron Type: 8 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsResponse ===
    # Fields for ListJobsResponse
    # Field: jobs Type: 11 (.google.cloud.scheduler.v1beta1.Job)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::GetJobRequest ===
    # Fields for GetJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CreateJobRequest ===
    # Fields for CreateJobRequest
    # Field: parent Type: 9 ()
    # Field: job Type: 11 (.google.cloud.scheduler.v1beta1.Job)

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::UpdateJobRequest ===
    # Fields for UpdateJobRequest
    # Field: job Type: 11 (.google.cloud.scheduler.v1beta1.Job)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::DeleteJobRequest ===
    # Fields for DeleteJobRequest
    # Field: name Type: 9 ()
    # Field: legacy_app_engine_cron Type: 8 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::PauseJobRequest ===
    # Fields for PauseJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ResumeJobRequest ===
    # Fields for ResumeJobRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::RunJobRequest ===
    # Fields for RunJobRequest
    # Field: name Type: 9 ()
    # Field: legacy_app_engine_cron Type: 8 ()

# === Service Client: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CloudSchedulerClient ===
package Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CloudSchedulerClient;

=pod

=head2 Service Client: Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CloudSchedulerClient

Client stub representing the remote C<CloudScheduler> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<scheduler.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'scheduler.googleapis.com:443' );

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

sub list_jobs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1beta1.CloudScheduler',
        method         => 'ListJobs',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsResponse',
    });
}

sub get_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1beta1::Cloudscheduler::GetJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1beta1.CloudScheduler',
        method         => 'GetJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1beta1::Job::Job',
    });
}

sub create_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CreateJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1beta1.CloudScheduler',
        method         => 'CreateJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1beta1::Job::Job',
    });
}

sub update_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1beta1::Cloudscheduler::UpdateJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1beta1.CloudScheduler',
        method         => 'UpdateJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1beta1::Job::Job',
    });
}

sub delete_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1beta1::Cloudscheduler::DeleteJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1beta1.CloudScheduler',
        method         => 'DeleteJob',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub pause_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1beta1::Cloudscheduler::PauseJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1beta1.CloudScheduler',
        method         => 'PauseJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1beta1::Job::Job',
    });
}

sub resume_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ResumeJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1beta1.CloudScheduler',
        method         => 'ResumeJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1beta1::Job::Job',
    });
}

sub run_job {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Scheduler::V1beta1::Cloudscheduler::RunJobRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.scheduler.v1beta1.CloudScheduler',
        method         => 'RunJob',
        request        => $req,
        response_class => 'Google::Cloud::Scheduler::V1beta1::Job::Job',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Scheduler::V1beta1::Cloudscheduler - Compiled Protocol Buffers messages for google/cloud/scheduler/v1beta1/cloudscheduler.proto

=head1 SYNOPSIS

    use Google::Cloud::Scheduler::V1beta1::Cloudscheduler;

    my $msg = Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsRequest->new({
        parent => $parent,
        filter => $filter,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/scheduler/v1beta1/cloudscheduler.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsRequest

Request message for listing jobs using
[ListJobs][google.cloud.scheduler.v1beta1.CloudScheduler.ListJobs].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

`filter` can be used to specify a subset of jobs.

If `filter` equals `target_config="HttpConfig"`, then the http
target jobs are retrieved. If `filter` equals
`target_config="PubSubConfig"`, then the Pub/Sub target jobs are
retrieved. If `filter` equals `labels.foo=value1
labels.foo=value2` then only jobs which are labeled with
foo=value1 AND foo=value2 will be returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size.

The maximum page size is 500. If unspecified, the page size will
be the maximum. Fewer jobs than requested might be returned,
even if more jobs exist; use next_page_token to determine if more
jobs exist.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results the server will return. To
request the first page results, page_token must be empty. To
request the next page of results, page_token must be the value of
[next_page_token][google.cloud.scheduler.v1beta1.ListJobsResponse.next_page_token]
returned from the previous call to
[ListJobs][google.cloud.scheduler.v1beta1.CloudScheduler.ListJobs]. It is
an error to switch the value of
[filter][google.cloud.scheduler.v1beta1.ListJobsRequest.filter] or
[order_by][google.cloud.scheduler.v1beta1.ListJobsRequest.order_by] while
iterating through pages.

=item * C<< $msg->legacy_app_engine_cron() >> / C<< $msg->legacy_app_engine_cron($value) >>

Type: C<Bool>

This field is used to manage the legacy App Engine Cron jobs using the
Cloud Scheduler API. If the field is set to true, the jobs in the __cron
queue will be listed instead.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsResponse

Response message for listing jobs using
[ListJobs][google.cloud.scheduler.v1beta1.CloudScheduler.ListJobs].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->jobs() >> / C<< $msg->jobs($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Job::Job>)

The list of jobs.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve next page of results. Pass this value in the
[page_token][google.cloud.scheduler.v1beta1.ListJobsRequest.page_token]
field in the subsequent call to
[ListJobs][google.cloud.scheduler.v1beta1.CloudScheduler.ListJobs] to
retrieve the next page of results. If this is empty it indicates that there
are no more results through which to paginate.

The page token is valid for only 2 hours.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::GetJobRequest

Request message for
[GetJob][google.cloud.scheduler.v1beta1.CloudScheduler.GetJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CreateJobRequest

Request message for
[CreateJob][google.cloud.scheduler.v1beta1.CloudScheduler.CreateJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID`.

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Job::Job>)

Required. The job to add. The user can optionally specify a name for the
job in [name][google.cloud.scheduler.v1beta1.Job.name].
[name][google.cloud.scheduler.v1beta1.Job.name] cannot be the same as an
existing job. If a name is not specified then the system will
generate a random unique name that will be returned
([name][google.cloud.scheduler.v1beta1.Job.name]) in the response.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::UpdateJobRequest

Request message for
[UpdateJob][google.cloud.scheduler.v1beta1.CloudScheduler.UpdateJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job() >> / C<< $msg->job($value) >>

Type: C<Message> (L<Google::Cloud::Scheduler::V1beta1::Job::Job>)

Required. The new job properties.
[name][google.cloud.scheduler.v1beta1.Job.name] must be specified.

Output only fields cannot be modified using UpdateJob.
Any value specified for an output only field will be ignored.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

A  mask used to specify which fields of the job are being updated.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::DeleteJobRequest

Request message for deleting a job using
[DeleteJob][google.cloud.scheduler.v1beta1.CloudScheduler.DeleteJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=item * C<< $msg->legacy_app_engine_cron() >> / C<< $msg->legacy_app_engine_cron($value) >>

Type: C<Bool>

This field is used to manage the legacy App Engine Cron jobs using the
Cloud Scheduler API. If the field is set to true, the job in the __cron
queue with the corresponding name will be deleted instead.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::PauseJobRequest

Request message for
[PauseJob][google.cloud.scheduler.v1beta1.CloudScheduler.PauseJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ResumeJobRequest

Request message for
[ResumeJob][google.cloud.scheduler.v1beta1.CloudScheduler.ResumeJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=back

=head2 Google::Cloud::Scheduler::V1beta1::Cloudscheduler::RunJobRequest

Request message for forcing a job to run now using
[RunJob][google.cloud.scheduler.v1beta1.CloudScheduler.RunJob].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The job name. For example:
`projects/PROJECT_ID/locations/LOCATION_ID/jobs/JOB_ID`.

=item * C<< $msg->legacy_app_engine_cron() >> / C<< $msg->legacy_app_engine_cron($value) >>

Type: C<Bool>

This field is used to manage the legacy App Engine Cron jobs using the
Cloud Scheduler API. If the field is set to true, the job in the __cron
queue with the corresponding name will be forced to run instead.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Scheduler::V1beta1::Cloudscheduler::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
