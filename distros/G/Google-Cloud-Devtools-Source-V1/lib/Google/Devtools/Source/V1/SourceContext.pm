package Google::Devtools::Source::V1::SourceContext;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvZGV2dG9vbHMvc291cmNlL3YxL3NvdXJjZV9jb250ZXh0LnByb3RvEhlnb29n
bGUuZGV2dG9vbHMuc291cmNlLnYxItwCCg1Tb3VyY2VDb250ZXh0ElIKCmNsb3VkX3JlcG8Y
ASABKAsyMS5nb29nbGUuZGV2dG9vbHMuc291cmNlLnYxLkNsb3VkUmVwb1NvdXJjZUNvbnRl
eHRIAFIJY2xvdWRSZXBvEmEKD2Nsb3VkX3dvcmtzcGFjZRgCIAEoCzI2Lmdvb2dsZS5kZXZ0
b29scy5zb3VyY2UudjEuQ2xvdWRXb3Jrc3BhY2VTb3VyY2VDb250ZXh0SABSDmNsb3VkV29y
a3NwYWNlEkgKBmdlcnJpdBgDIAEoCzIuLmdvb2dsZS5kZXZ0b29scy5zb3VyY2UudjEuR2Vy
cml0U291cmNlQ29udGV4dEgAUgZnZXJyaXQSPwoDZ2l0GAYgASgLMisuZ29vZ2xlLmRldnRv
b2xzLnNvdXJjZS52MS5HaXRTb3VyY2VDb250ZXh0SABSA2dpdEIJCgdjb250ZXh0IuwBChVF
eHRlbmRlZFNvdXJjZUNvbnRleHQSQgoHY29udGV4dBgBIAEoCzIoLmdvb2dsZS5kZXZ0b29s
cy5zb3VyY2UudjEuU291cmNlQ29udGV4dFIHY29udGV4dBJUCgZsYWJlbHMYAiADKAsyPC5n
b29nbGUuZGV2dG9vbHMuc291cmNlLnYxLkV4dGVuZGVkU291cmNlQ29udGV4dC5MYWJlbHNF
bnRyeVIGbGFiZWxzGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVl
GAIgASgJUgV2YWx1ZToCOAEimAEKDEFsaWFzQ29udGV4dBJACgRraW5kGAEgASgOMiwuZ29v
Z2xlLmRldnRvb2xzLnNvdXJjZS52MS5BbGlhc0NvbnRleHQuS2luZFIEa2luZBISCgRuYW1l
GAIgASgJUgRuYW1lIjIKBEtpbmQSBwoDQU5ZEAASCQoFRklYRUQQARILCgdNT1ZBQkxFEAIS
CQoFT1RIRVIQBCL4AQoWQ2xvdWRSZXBvU291cmNlQ29udGV4dBI6CgdyZXBvX2lkGAEgASgL
MiEuZ29vZ2xlLmRldnRvb2xzLnNvdXJjZS52MS5SZXBvSWRSBnJlcG9JZBIhCgtyZXZpc2lv
bl9pZBgCIAEoCUgAUgpyZXZpc2lvbklkEiMKCmFsaWFzX25hbWUYAyABKAlCAhgBSABSCWFs
aWFzTmFtZRJOCg1hbGlhc19jb250ZXh0GAQgASgLMicuZ29vZ2xlLmRldnRvb2xzLnNvdXJj
ZS52MS5BbGlhc0NvbnRleHRIAFIMYWxpYXNDb250ZXh0QgoKCHJldmlzaW9uIo4BChtDbG91
ZFdvcmtzcGFjZVNvdXJjZUNvbnRleHQSTgoMd29ya3NwYWNlX2lkGAEgASgLMisuZ29vZ2xl
LmRldnRvb2xzLnNvdXJjZS52MS5DbG91ZFdvcmtzcGFjZUlkUgt3b3Jrc3BhY2VJZBIfCgtz
bmFwc2hvdF9pZBgCIAEoCVIKc25hcHNob3RJZCL7AQoTR2Vycml0U291cmNlQ29udGV4dBIZ
Cghob3N0X3VyaRgBIAEoCVIHaG9zdFVyaRIlCg5nZXJyaXRfcHJvamVjdBgCIAEoCVINZ2Vy
cml0UHJvamVjdBIhCgtyZXZpc2lvbl9pZBgDIAEoCUgAUgpyZXZpc2lvbklkEiMKCmFsaWFz
X25hbWUYBCABKAlCAhgBSABSCWFsaWFzTmFtZRJOCg1hbGlhc19jb250ZXh0GAUgASgLMicu
Z29vZ2xlLmRldnRvb2xzLnNvdXJjZS52MS5BbGlhc0NvbnRleHRIAFIMYWxpYXNDb250ZXh0
QgoKCHJldmlzaW9uIkUKEEdpdFNvdXJjZUNvbnRleHQSEAoDdXJsGAEgASgJUgN1cmwSHwoL
cmV2aXNpb25faWQYAiABKAlSCnJldmlzaW9uSWQidgoGUmVwb0lkElIKD3Byb2plY3RfcmVw
b19pZBgBIAEoCzIoLmdvb2dsZS5kZXZ0b29scy5zb3VyY2UudjEuUHJvamVjdFJlcG9JZEgA
Ug1wcm9qZWN0UmVwb0lkEhIKA3VpZBgCIAEoCUgAUgN1aWRCBAoCaWQiSwoNUHJvamVjdFJl
cG9JZBIdCgpwcm9qZWN0X2lkGAEgASgJUglwcm9qZWN0SWQSGwoJcmVwb19uYW1lGAIgASgJ
UghyZXBvTmFtZSJiChBDbG91ZFdvcmtzcGFjZUlkEjoKB3JlcG9faWQYASABKAsyIS5nb29n
bGUuZGV2dG9vbHMuc291cmNlLnYxLlJlcG9JZFIGcmVwb0lkEhIKBG5hbWUYAiABKAlSBG5h
bWVCvQEKHWNvbS5nb29nbGUuZGV2dG9vbHMuc291cmNlLnYxQhJTb3VyY2VDb250ZXh0UHJv
dG9QAVo/Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29scy9z
b3VyY2UvdjE7c291cmNl+AEBqgIfR29vZ2xlLkNsb3VkLkRldlRvb2xzLlNvdXJjZS5WMcoC
H0dvb2dsZVxDbG91ZFxEZXZUb29sc1xTb3VyY2VcVjFK8C0KBxIFDwC0AQEKvQQKAQwSAw8A
EjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAiCggKAQgSAxMAHwoJCgIIHxID
EwAfCggKAQgSAxQAPAoJCgIIJRIDFAA8CggKAQgSAxUAVgoJCgIICxIDFQBWCggKAQgSAxYA
IgoJCgIIChIDFgAiCggKAQgSAxcAMwoJCgIICBIDFwAzCggKAQgSAxgANgoJCgIIARIDGAA2
CggKAQgSAxkAPQoJCgIIKRIDGQA9CqEBCgIEABIEHQAsARqUASBBIFNvdXJjZUNvbnRleHQg
aXMgYSByZWZlcmVuY2UgdG8gYSB0cmVlIG9mIGZpbGVzLiBBIFNvdXJjZUNvbnRleHQgdG9n
ZXRoZXIKIHdpdGggYSBwYXRoIHBvaW50IHRvIGEgdW5pcXVlIHJldmlzaW9uIG9mIGEgc2lu
Z2xlIGZpbGUgb3IgZGlyZWN0b3J5LgoKCgoDBAABEgMdCBUKWQoEBAAIABIEHwIrAxpLIEEg
U291cmNlQ29udGV4dCBjYW4gcmVmZXIgYW55IG9uZSBvZiB0aGUgZm9sbG93aW5nIHR5cGVz
IG9mIHJlcG9zaXRvcmllcy4KCgwKBQQACAABEgMfCA8KRwoEBAACABIDIQQqGjogQSBTb3Vy
Y2VDb250ZXh0IHJlZmVycmluZyB0byBhIHJldmlzaW9uIGluIGEgY2xvdWQgcmVwby4KCgwK
BQQAAgAGEgMhBBoKDAoFBAACAAESAyEbJQoMCgUEAAIAAxIDISgpCkwKBAQAAgESAyQENBo/
IEEgU291cmNlQ29udGV4dCByZWZlcnJpbmcgdG8gYSBzbmFwc2hvdCBpbiBhIGNsb3VkIHdv
cmtzcGFjZS4KCgwKBQQAAgEGEgMkBB8KDAoFBAACAQESAyQgLwoMCgUEAAIBAxIDJDIzCj0K
BAQAAgISAycEIxowIEEgU291cmNlQ29udGV4dCByZWZlcnJpbmcgdG8gYSBHZXJyaXQgcHJv
amVjdC4KCgwKBQQAAgIGEgMnBBcKDAoFBAACAgESAycYHgoMCgUEAAICAxIDJyEiClMKBAQA
AgMSAyoEHRpGIEEgU291cmNlQ29udGV4dCByZWZlcnJpbmcgdG8gYW55IHRoaXJkIHBhcnR5
IEdpdCByZXBvIChlLmcuIEdpdEh1YikuCgoMCgUEAAIDBhIDKgQUCgwKBQQAAgMBEgMqFRgK
DAoFBAACAwMSAyobHApzCgIEARIEMAA2ARpnIEFuIEV4dGVuZGVkU291cmNlQ29udGV4dCBp
cyBhIFNvdXJjZUNvbnRleHQgY29tYmluZWQgd2l0aCBhZGRpdGlvbmFsCiBkZXRhaWxzIGRl
c2NyaWJpbmcgdGhlIGNvbnRleHQuCgoKCgMEAQESAzAIHQoiCgQEAQIAEgMyAhwaFSBBbnkg
c291cmNlIGNvbnRleHQuCgoMCgUEAQIABhIDMgIPCgwKBQQBAgABEgMyEBcKDAoFBAECAAMS
AzIaGwoxCgQEAQIBEgM1AiEaJCBMYWJlbHMgd2l0aCB1c2VyIGRlZmluZWQgbWV0YWRhdGEu
CgoMCgUEAQIBBhIDNQIVCgwKBQQBAgEBEgM1FhwKDAoFBAECAQMSAzUfIAoqCgIEAhIEOQBQ
ARoeIEFuIGFsaWFzIHRvIGEgcmVwbyByZXZpc2lvbi4KCgoKAwQCARIDOQgUCiUKBAQCBAAS
BDsCSQMaFyBUaGUgdHlwZSBvZiBhbiBBbGlhcy4KCgwKBQQCBAABEgM7BwsKHAoGBAIEAAIA
EgM9BAwaDSBEbyBub3QgdXNlLgoKDgoHBAIEAAIAARIDPQQHCg4KBwQCBAACAAISAz0KCwoY
CgYEAgQAAgESA0AEDhoJIEdpdCB0YWcKCg4KBwQCBAACAQESA0AECQoOCgcEAgQAAgECEgNA
DA0KGwoGBAIEAAICEgNDBBAaDCBHaXQgYnJhbmNoCgoOCgcEAgQAAgIBEgNDBAsKDgoHBAIE
AAICAhIDQw4PCsEBCgYEAgQAAgMSA0gEDhqxASBPVEhFUiBpcyB1c2VkIHRvIHNwZWNpZnkg
bm9uLXN0YW5kYXJkIGFsaWFzZXMsIHRob3NlIG5vdCBvZiB0aGUga2luZHMKIGFib3ZlLiBG
b3IgZXhhbXBsZSwgaWYgYSBHaXQgcmVwbyBoYXMgYSByZWYgbmFtZWQgInJlZnMvZm9vL2Jh
ciIsIGl0CiBpcyBjb25zaWRlcmVkIHRvIGJlIG9mIGtpbmQgT1RIRVIuCgoOCgcEAgQAAgMB
EgNIBAkKDgoHBAIEAAIDAhIDSAwNCh4KBAQCAgASA0wCEBoRIFRoZSBhbGlhcyBraW5kLgoK
DAoFBAICAAYSA0wCBgoMCgUEAgIAARIDTAcLCgwKBQQCAgADEgNMDg8KHgoEBAICARIDTwIS
GhEgVGhlIGFsaWFzIG5hbWUuCgoMCgUEAgIBBRIDTwIICgwKBQQCAgEBEgNPCQ0KDAoFBAIC
AQMSA08QEQqDAQoCBAMSBFQAZAEadyBBIENsb3VkUmVwb1NvdXJjZUNvbnRleHQgZGVub3Rl
cyBhIHBhcnRpY3VsYXIgcmV2aXNpb24gaW4gYSBjbG91ZAogcmVwbyAoYSByZXBvIGhvc3Rl
ZCBieSB0aGUgR29vZ2xlIENsb3VkIFBsYXRmb3JtKS4KCgoKAwQDARIDVAgeCiIKBAQDAgAS
A1YCFRoVIFRoZSBJRCBvZiB0aGUgcmVwby4KCgwKBQQDAgAGEgNWAggKDAoFBAMCAAESA1YJ
EAoMCgUEAwIAAxIDVhMUCmsKBAQDCAASBFoCYwMaXSBBIHJldmlzaW9uIGluIGEgY2xvdWQg
cmVwb3NpdG9yeSBjYW4gYmUgaWRlbnRpZmllZCBieSBlaXRoZXIgaXRzIHJldmlzaW9uCiBJ
RCBvciBpdHMgQWxpYXMuCgoMCgUEAwgAARIDWggQCh0KBAQDAgESA1wEGxoQIEEgcmV2aXNp
b24gSUQuCgoMCgUEAwIBBRIDXAQKCgwKBQQDAgEBEgNcCxYKDAoFBAMCAQMSA1wZGgo4CgQE
AwICEgNfBC4aKyBUaGUgbmFtZSBvZiBhbiBhbGlhcyAoYnJhbmNoLCB0YWcsIGV0Yy4pLgoK
DAoFBAMCAgUSA18ECgoMCgUEAwICARIDXwsVCgwKBQQDAgIDEgNfGBkKDAoFBAMCAggSA18a
LQoNCgYEAwICCAMSA18bLAo2CgQEAwIDEgNiBCMaKSBBbiBhbGlhcywgd2hpY2ggbWF5IGJl
IGEgYnJhbmNoIG9yIHRhZy4KCgwKBQQDAgMGEgNiBBAKDAoFBAMCAwESA2IRHgoMCgUEAwID
AxIDYiEiClkKAgQEEgRnAG4BGk0gQSBDbG91ZFdvcmtzcGFjZVNvdXJjZUNvbnRleHQgZGVu
b3RlcyBhIHdvcmtzcGFjZSBhdCBhIHBhcnRpY3VsYXIgc25hcHNob3QuCgoKCgMEBAESA2cI
IwonCgQEBAIAEgNpAiQaGiBUaGUgSUQgb2YgdGhlIHdvcmtzcGFjZS4KCgwKBQQEAgAGEgNp
AhIKDAoFBAQCAAESA2kTHwoMCgUEBAIAAxIDaSIjCmAKBAQEAgESA20CGRpTIFRoZSBJRCBv
ZiB0aGUgc25hcHNob3QuCiBBbiBlbXB0eSBzbmFwc2hvdF9pZCByZWZlcnMgdG8gdGhlIG1v
c3QgcmVjZW50IHNuYXBzaG90LgoKDAoFBAQCAQUSA20CCAoMCgUEBAIBARIDbQkUCgwKBQQE
AgEDEgNtFxgKPQoCBAUSBXEAhgEBGjAgQSBTb3VyY2VDb250ZXh0IHJlZmVycmluZyB0byBh
IEdlcnJpdCBwcm9qZWN0LgoKCgoDBAUBEgNxCBsKNAoEBAUCABIDcwIWGicgVGhlIFVSSSBv
ZiBhIHJ1bm5pbmcgR2Vycml0IGluc3RhbmNlLgoKDAoFBAUCAAUSA3MCCAoMCgUEBQIAARID
cwkRCgwKBQQFAgADEgNzFBUKpQEKBAQFAgESA3gCHBqXASBUaGUgZnVsbCBwcm9qZWN0IG5h
bWUgd2l0aGluIHRoZSBob3N0LiBQcm9qZWN0cyBtYXkgYmUgbmVzdGVkLCBzbwogInByb2pl
Y3Qvc3VicHJvamVjdCIgaXMgYSB2YWxpZCBwcm9qZWN0IG5hbWUuCiBUaGUgInJlcG8gbmFt
ZSIgaXMgaG9zdFVSSS9wcm9qZWN0LgoKDAoFBAUCAQUSA3gCCAoMCgUEBQIBARIDeAkXCgwK
BQQFAgEDEgN4GhsKagoEBAUIABIFfAKFAQMaWyBBIHJldmlzaW9uIGluIGEgR2Vycml0IHBy
b2plY3QgY2FuIGJlIGlkZW50aWZpZWQgYnkgZWl0aGVyIGl0cyByZXZpc2lvbiBJRAogb3Ig
aXRzIGFsaWFzLgoKDAoFBAUIAAESA3wIEAomCgQEBQICEgN+BBsaGSBBIHJldmlzaW9uIChj
b21taXQpIElELgoKDAoFBAUCAgUSA34ECgoMCgUEBQICARIDfgsWCgwKBQQFAgIDEgN+GRoK
OQoEBAUCAxIEgQEELhorIFRoZSBuYW1lIG9mIGFuIGFsaWFzIChicmFuY2gsIHRhZywgZXRj
LikuCgoNCgUEBQIDBRIEgQEECgoNCgUEBQIDARIEgQELFQoNCgUEBQIDAxIEgQEYGQoNCgUE
BQIDCBIEgQEaLQoOCgYEBQIDCAMSBIEBGywKNwoEBAUCBBIEhAEEIxopIEFuIGFsaWFzLCB3
aGljaCBtYXkgYmUgYSBicmFuY2ggb3IgdGFnLgoKDQoFBAUCBAYSBIQBBBAKDQoFBAUCBAES
BIQBER4KDQoFBAUCBAMSBIQBISIKcAoCBAYSBooBAJEBARpiIEEgR2l0U291cmNlQ29udGV4
dCBkZW5vdGVzIGEgcGFydGljdWxhciByZXZpc2lvbiBpbiBhIHRoaXJkIHBhcnR5IEdpdAog
cmVwb3NpdG9yeSAoZS5nLiBHaXRIdWIpLgoKCwoDBAYBEgSKAQgYCiMKBAQGAgASBIwBAhEa
FSBHaXQgcmVwb3NpdG9yeSBVUkwuCgoNCgUEBgIABRIEjAECCAoNCgUEBgIAARIEjAEJDAoN
CgUEBgIAAxIEjAEPEAorCgQEBgIBEgSQAQIZGh0gR2l0IGNvbW1pdCBoYXNoLgogcmVxdWly
ZWQuCgoNCgUEBgIBBRIEkAECCAoNCgUEBgIBARIEkAEJFAoNCgUEBgIBAxIEkAEXGAo1CgIE
BxIGlAEAngEBGicgQSB1bmlxdWUgaWRlbnRpZmllciBmb3IgYSBjbG91ZCByZXBvLgoKCwoD
BAcBEgSUAQgOCpUBCgQEBwgAEgaXAQKdAQMahAEgQSBjbG91ZCByZXBvc2l0b3J5IGNhbiBi
ZSBpZGVudGlmaWVkIGJ5IGVpdGhlciBpdHMgcHJvamVjdCBJRCBhbmQKIHJlcG9zaXRvcnkg
bmFtZSBjb21iaW5hdGlvbiwgb3IgaXRzIGdsb2JhbGx5IHVuaXF1ZSBpZGVudGlmaWVyLgoK
DQoFBAcIAAESBJcBCAoKPgoEBAcCABIEmQEEJhowIEEgY29tYmluYXRpb24gb2YgYSBwcm9q
ZWN0IElEIGFuZCBhIHJlcG8gbmFtZS4KCg0KBQQHAgAGEgSZAQQRCg0KBQQHAgABEgSZARIh
Cg0KBQQHAgADEgSZASQlCj4KBAQHAgESBJwBBBMaMCBBIHNlcnZlci1hc3NpZ25lZCwgZ2xv
YmFsbHkgdW5pcXVlIGlkZW50aWZpZXIuCgoNCgUEBwIBBRIEnAEECgoNCgUEBwIBARIEnAEL
DgoNCgUEBwIBAxIEnAEREgqEAQoCBAgSBqIBAKgBARp2IFNlbGVjdHMgYSByZXBvIHVzaW5n
IGEgR29vZ2xlIENsb3VkIFBsYXRmb3JtIHByb2plY3QgSUQKIChlLmcuIHdpbmdlZC1jYXJn
by0zMSkgYW5kIGEgcmVwbyBuYW1lIHdpdGhpbiB0aGF0IHByb2plY3QuCgoLCgMECAESBKIB
CBUKJgoEBAgCABIEpAECGBoYIFRoZSBJRCBvZiB0aGUgcHJvamVjdC4KCg0KBQQIAgAFEgSk
AQIICg0KBQQIAgABEgSkAQkTCg0KBQQIAgADEgSkARYXCkcKBAQIAgESBKcBAhcaOSBUaGUg
bmFtZSBvZiB0aGUgcmVwby4gTGVhdmUgZW1wdHkgZm9yIHRoZSBkZWZhdWx0IHJlcG8uCgoN
CgUECAIBBRIEpwECCAoNCgUECAIBARIEpwEJEgoNCgUECAIBAxIEpwEVFgrFAQoCBAkSBq0B
ALQBARq2ASBBIENsb3VkV29ya3NwYWNlSWQgaXMgYSB1bmlxdWUgaWRlbnRpZmllciBmb3Ig
YSBjbG91ZCB3b3Jrc3BhY2UuCiBBIGNsb3VkIHdvcmtzcGFjZSBpcyBhIHBsYWNlIGFzc29j
aWF0ZWQgd2l0aCBhIHJlcG8gd2hlcmUgbW9kaWZpZWQgZmlsZXMKIGNhbiBiZSBzdG9yZWQg
YmVmb3JlIHRoZXkgYXJlIGNvbW1pdHRlZC4KCgsKAwQJARIErQEIGAo8CgQECQIAEgSvAQIV
Gi4gVGhlIElEIG9mIHRoZSByZXBvIGNvbnRhaW5pbmcgdGhlIHdvcmtzcGFjZS4KCg0KBQQJ
AgAGEgSvAQIICg0KBQQJAgABEgSvAQkQCg0KBQQJAgADEgSvARMUCpYBCgQECQIBEgSzAQIS
GocBIFRoZSB1bmlxdWUgbmFtZSBvZiB0aGUgd29ya3NwYWNlIHdpdGhpbiB0aGUgcmVwby4g
IFRoaXMgaXMgdGhlIG5hbWUKIGNob3NlbiBieSB0aGUgY2xpZW50IGluIHRoZSBTb3VyY2Ug
QVBJJ3MgQ3JlYXRlV29ya3NwYWNlIG1ldGhvZC4KCg0KBQQJAgEFEgSzAQIICg0KBQQJAgEB
EgSzAQkNCg0KBQQJAgEDEgSzARARYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Source::V1::SourceContext::SourceContext ===
    # Fields for SourceContext
    # Field: cloud_repo Type: 11 (.google.devtools.source.v1.CloudRepoSourceContext)
    # Field: cloud_workspace Type: 11 (.google.devtools.source.v1.CloudWorkspaceSourceContext)
    # Field: gerrit Type: 11 (.google.devtools.source.v1.GerritSourceContext)
    # Field: git Type: 11 (.google.devtools.source.v1.GitSourceContext)

# === Message: Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext ===
    # Fields for ExtendedSourceContext
    # Field: context Type: 11 (.google.devtools.source.v1.SourceContext)
    # Field: labels Type: 11 (.google.devtools.source.v1.ExtendedSourceContext.LabelsEntry)

# === Message: Google::Devtools::Source::V1::SourceContext::AliasContext ===
    # Fields for AliasContext
    # Field: kind Type: 14 (.google.devtools.source.v1.AliasContext.Kind)
    # Field: name Type: 9 ()

# Enum: AliasContext::Kind
our $AliasContext_ANY = 0;
our $AliasContext_FIXED = 1;
our $AliasContext_MOVABLE = 2;
our $AliasContext_OTHER = 4;

# === Message: Google::Devtools::Source::V1::SourceContext::CloudRepoSourceContext ===
    # Fields for CloudRepoSourceContext
    # Field: repo_id Type: 11 (.google.devtools.source.v1.RepoId)
    # Field: revision_id Type: 9 ()
    # Field: alias_name Type: 9 ()
    # Field: alias_context Type: 11 (.google.devtools.source.v1.AliasContext)

# === Message: Google::Devtools::Source::V1::SourceContext::CloudWorkspaceSourceContext ===
    # Fields for CloudWorkspaceSourceContext
    # Field: workspace_id Type: 11 (.google.devtools.source.v1.CloudWorkspaceId)
    # Field: snapshot_id Type: 9 ()

# === Message: Google::Devtools::Source::V1::SourceContext::GerritSourceContext ===
    # Fields for GerritSourceContext
    # Field: host_uri Type: 9 ()
    # Field: gerrit_project Type: 9 ()
    # Field: revision_id Type: 9 ()
    # Field: alias_name Type: 9 ()
    # Field: alias_context Type: 11 (.google.devtools.source.v1.AliasContext)

# === Message: Google::Devtools::Source::V1::SourceContext::GitSourceContext ===
    # Fields for GitSourceContext
    # Field: url Type: 9 ()
    # Field: revision_id Type: 9 ()

# === Message: Google::Devtools::Source::V1::SourceContext::RepoId ===
    # Fields for RepoId
    # Field: project_repo_id Type: 11 (.google.devtools.source.v1.ProjectRepoId)
    # Field: uid Type: 9 ()

# === Message: Google::Devtools::Source::V1::SourceContext::ProjectRepoId ===
    # Fields for ProjectRepoId
    # Field: project_id Type: 9 ()
    # Field: repo_name Type: 9 ()

# === Message: Google::Devtools::Source::V1::SourceContext::CloudWorkspaceId ===
    # Fields for CloudWorkspaceId
    # Field: repo_id Type: 11 (.google.devtools.source.v1.RepoId)
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Source::V1::SourceContext - Compiled Protocol Buffers messages for google/devtools/source/v1/source_context.proto

=head1 SYNOPSIS

    use Google::Devtools::Source::V1::SourceContext;

    my $msg = Google::Devtools::Source::V1::SourceContext::SourceContext->new({
        cloud_repo => $cloud_repo,
        cloud_workspace => $cloud_workspace,
        gerrit => $gerrit,
        git => $git,
    });

    # Read or update a field
    my $val = $msg->cloud_repo();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Source::V1::SourceContext::SourceContext->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/source/v1/source_context.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Source::V1::SourceContext::SourceContext

A SourceContext is a reference to a tree of files. A SourceContext together
with a path point to a unique revision of a single file or directory.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_repo() >> / C<< $msg->cloud_repo($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::CloudRepoSourceContext>)

A SourceContext referring to a revision in a cloud repo.

=item * C<< $msg->cloud_workspace() >> / C<< $msg->cloud_workspace($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::CloudWorkspaceSourceContext>)

A SourceContext referring to a snapshot in a cloud workspace.

=item * C<< $msg->gerrit() >> / C<< $msg->gerrit($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::GerritSourceContext>)

A SourceContext referring to a Gerrit project.

=item * C<< $msg->git() >> / C<< $msg->git($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::GitSourceContext>)

A SourceContext referring to any third party Git repo (e.g. GitHub).

=back

=head2 Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext

An ExtendedSourceContext is a SourceContext combined with additional
details describing the context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::SourceContext>)

Any source context.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext::LabelsEntry>)

Labels with user defined metadata.

=back

=head2 Google::Devtools::Source::V1::SourceContext::AliasContext

An alias to a repo revision.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<Enum> (L<Google::Devtools::Source::V1::AliasContext::Kind>)

The alias kind.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The alias name.

=back

=head3 Enum: AliasContext::Kind

=over 4

=item * C<ANY> => C<0>

=item * C<FIXED> => C<1>

=item * C<MOVABLE> => C<2>

=item * C<OTHER> => C<4>

=back

=head2 Google::Devtools::Source::V1::SourceContext::CloudRepoSourceContext

A CloudRepoSourceContext denotes a particular revision in a cloud
repo (a repo hosted by the Google Cloud Platform).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repo_id() >> / C<< $msg->repo_id($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::RepoId>)

The ID of the repo.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

A revision ID.

=item * C<< $msg->alias_name() >> / C<< $msg->alias_name($value) >>

Type: C<String>

The name of an alias (branch, tag, etc.).

=item * C<< $msg->alias_context() >> / C<< $msg->alias_context($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::AliasContext>)

An alias, which may be a branch or tag.

=back

=head2 Google::Devtools::Source::V1::SourceContext::CloudWorkspaceSourceContext

A CloudWorkspaceSourceContext denotes a workspace at a particular snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workspace_id() >> / C<< $msg->workspace_id($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::CloudWorkspaceId>)

The ID of the workspace.

=item * C<< $msg->snapshot_id() >> / C<< $msg->snapshot_id($value) >>

Type: C<String>

The ID of the snapshot.
An empty snapshot_id refers to the most recent snapshot.

=back

=head2 Google::Devtools::Source::V1::SourceContext::GerritSourceContext

A SourceContext referring to a Gerrit project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->host_uri() >> / C<< $msg->host_uri($value) >>

Type: C<String>

The URI of a running Gerrit instance.

=item * C<< $msg->gerrit_project() >> / C<< $msg->gerrit_project($value) >>

Type: C<String>

The full project name within the host. Projects may be nested, so
"project/subproject" is a valid project name.
The "repo name" is hostURI/project.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

A revision (commit) ID.

=item * C<< $msg->alias_name() >> / C<< $msg->alias_name($value) >>

Type: C<String>

The name of an alias (branch, tag, etc.).

=item * C<< $msg->alias_context() >> / C<< $msg->alias_context($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::AliasContext>)

An alias, which may be a branch or tag.

=back

=head2 Google::Devtools::Source::V1::SourceContext::GitSourceContext

A GitSourceContext denotes a particular revision in a third party Git
repository (e.g. GitHub).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Git repository URL.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Git commit hash.
required.

=back

=head2 Google::Devtools::Source::V1::SourceContext::RepoId

A unique identifier for a cloud repo.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_repo_id() >> / C<< $msg->project_repo_id($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::ProjectRepoId>)

A combination of a project ID and a repo name.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

A server-assigned, globally unique identifier.

=back

=head2 Google::Devtools::Source::V1::SourceContext::ProjectRepoId

Selects a repo using a Google Cloud Platform project ID
(e.g. winged-cargo-31) and a repo name within that project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project.

=item * C<< $msg->repo_name() >> / C<< $msg->repo_name($value) >>

Type: C<String>

The name of the repo. Leave empty for the default repo.

=back

=head2 Google::Devtools::Source::V1::SourceContext::CloudWorkspaceId

A CloudWorkspaceId is a unique identifier for a cloud workspace.
A cloud workspace is a place associated with a repo where modified files
can be stored before they are committed.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repo_id() >> / C<< $msg->repo_id($value) >>

Type: C<Message> (L<Google::Devtools::Source::V1::SourceContext::RepoId>)

The ID of the repo containing the workspace.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique name of the workspace within the repo.  This is the name
chosen by the client in the Source API's CreateWorkspace method.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Source::V1::SourceContext::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
