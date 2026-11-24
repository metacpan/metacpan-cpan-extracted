package Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Cloud::Runtimeconfig::V1beta1::Resources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvcnVudGltZWNvbmZpZy92MWJldGExL3J1bnRpbWVjb25maWcucHJv
dG8SImdvb2dsZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEaHGdvb2dsZS9hcGkvYW5u
b3RhdGlvbnMucHJvdG8aMmdvb2dsZS9jbG91ZC9ydW50aW1lY29uZmlnL3YxYmV0YTEvcmVz
b3VyY2VzLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxobZ29v
Z2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnBy
b3RvImgKEkxpc3RDb25maWdzUmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIbCglw
YWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tl
biKKAQoTTGlzdENvbmZpZ3NSZXNwb25zZRJLCgdjb25maWdzGAEgAygLMjEuZ29vZ2xlLmNs
b3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMS5SdW50aW1lQ29uZmlnUgdjb25maWdzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiImChBHZXRDb25maWdSZXF1ZXN0
EhIKBG5hbWUYAiABKAlSBG5hbWUilwEKE0NyZWF0ZUNvbmZpZ1JlcXVlc3QSFgoGcGFyZW50
GAEgASgJUgZwYXJlbnQSSQoGY29uZmlnGAIgASgLMjEuZ29vZ2xlLmNsb3VkLnJ1bnRpbWVj
b25maWcudjFiZXRhMS5SdW50aW1lQ29uZmlnUgZjb25maWcSHQoKcmVxdWVzdF9pZBgDIAEo
CVIJcmVxdWVzdElkInQKE1VwZGF0ZUNvbmZpZ1JlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFt
ZRJJCgZjb25maWcYAiABKAsyMS5nb29nbGUuY2xvdWQucnVudGltZWNvbmZpZy52MWJldGEx
LlJ1bnRpbWVDb25maWdSBmNvbmZpZyIpChNEZWxldGVDb25maWdSZXF1ZXN0EhIKBG5hbWUY
ASABKAlSBG5hbWUipwEKFExpc3RWYXJpYWJsZXNSZXF1ZXN0EhYKBnBhcmVudBgBIAEoCVIG
cGFyZW50EhYKBmZpbHRlchgCIAEoCVIGZmlsdGVyEhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFn
ZVNpemUSHQoKcGFnZV90b2tlbhgEIAEoCVIJcGFnZVRva2VuEiMKDXJldHVybl92YWx1ZXMY
BSABKAhSDHJldHVyblZhbHVlcyKLAQoVTGlzdFZhcmlhYmxlc1Jlc3BvbnNlEkoKCXZhcmlh
YmxlcxgBIAMoCzIsLmdvb2dsZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuVmFyaWFi
bGVSCXZhcmlhYmxlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i
ZQoUV2F0Y2hWYXJpYWJsZVJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRI5CgpuZXdlcl90
aGFuGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJbmV3ZXJUaGFuIigKEkdl
dFZhcmlhYmxlUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lIpgBChVDcmVhdGVWYXJpYWJs
ZVJlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZwYXJlbnQSSAoIdmFyaWFibGUYAiABKAsyLC5n
b29nbGUuY2xvdWQucnVudGltZWNvbmZpZy52MWJldGExLlZhcmlhYmxlUgh2YXJpYWJsZRId
CgpyZXF1ZXN0X2lkGAMgASgJUglyZXF1ZXN0SWQidQoVVXBkYXRlVmFyaWFibGVSZXF1ZXN0
EhIKBG5hbWUYASABKAlSBG5hbWUSSAoIdmFyaWFibGUYAiABKAsyLC5nb29nbGUuY2xvdWQu
cnVudGltZWNvbmZpZy52MWJldGExLlZhcmlhYmxlUgh2YXJpYWJsZSJJChVEZWxldGVWYXJp
YWJsZVJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIcCglyZWN1cnNpdmUYAiABKAhSCXJl
Y3Vyc2l2ZSJoChJMaXN0V2FpdGVyc1JlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZwYXJlbnQS
GwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdl
VG9rZW4igwEKE0xpc3RXYWl0ZXJzUmVzcG9uc2USRAoHd2FpdGVycxgBIAMoCzIqLmdvb2ds
ZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuV2FpdGVyUgd3YWl0ZXJzEiYKD25leHRf
cGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiImChBHZXRXYWl0ZXJSZXF1ZXN0EhIK
BG5hbWUYASABKAlSBG5hbWUikAEKE0NyZWF0ZVdhaXRlclJlcXVlc3QSFgoGcGFyZW50GAEg
ASgJUgZwYXJlbnQSQgoGd2FpdGVyGAIgASgLMiouZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25m
aWcudjFiZXRhMS5XYWl0ZXJSBndhaXRlchIdCgpyZXF1ZXN0X2lkGAMgASgJUglyZXF1ZXN0
SWQiKQoTRGVsZXRlV2FpdGVyUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lMtYUChRSdW50
aW1lQ29uZmlnTWFuYWdlchKsAQoLTGlzdENvbmZpZ3MSNi5nb29nbGUuY2xvdWQucnVudGlt
ZWNvbmZpZy52MWJldGExLkxpc3RDb25maWdzUmVxdWVzdBo3Lmdvb2dsZS5jbG91ZC5ydW50
aW1lY29uZmlnLnYxYmV0YTEuTGlzdENvbmZpZ3NSZXNwb25zZSIsgtPkkwImEiQvdjFiZXRh
MS97cGFyZW50PXByb2plY3RzLyp9L2NvbmZpZ3MSogEKCUdldENvbmZpZxI0Lmdvb2dsZS5j
bG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuR2V0Q29uZmlnUmVxdWVzdBoxLmdvb2dsZS5j
bG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuUnVudGltZUNvbmZpZyIsgtPkkwImEiQvdjFi
ZXRhMS97bmFtZT1wcm9qZWN0cy8qL2NvbmZpZ3MvKn0SsAEKDENyZWF0ZUNvbmZpZxI3Lmdv
b2dsZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuQ3JlYXRlQ29uZmlnUmVxdWVzdBox
Lmdvb2dsZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuUnVudGltZUNvbmZpZyI0gtPk
kwIuIiQvdjFiZXRhMS97cGFyZW50PXByb2plY3RzLyp9L2NvbmZpZ3M6BmNvbmZpZxKwAQoM
VXBkYXRlQ29uZmlnEjcuZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMS5VcGRh
dGVDb25maWdSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMS5S
dW50aW1lQ29uZmlnIjSC0+STAi4aJC92MWJldGExL3tuYW1lPXByb2plY3RzLyovY29uZmln
cy8qfToGY29uZmlnEo0BCgxEZWxldGVDb25maWcSNy5nb29nbGUuY2xvdWQucnVudGltZWNv
bmZpZy52MWJldGExLkRlbGV0ZUNvbmZpZ1JlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1w
dHkiLILT5JMCJiokL3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9jb25maWdzLyp9Er4BCg1M
aXN0VmFyaWFibGVzEjguZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMS5MaXN0
VmFyaWFibGVzUmVxdWVzdBo5Lmdvb2dsZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEu
TGlzdFZhcmlhYmxlc1Jlc3BvbnNlIjiC0+STAjISMC92MWJldGExL3twYXJlbnQ9cHJvamVj
dHMvKi9jb25maWdzLyp9L3ZhcmlhYmxlcxKuAQoLR2V0VmFyaWFibGUSNi5nb29nbGUuY2xv
dWQucnVudGltZWNvbmZpZy52MWJldGExLkdldFZhcmlhYmxlUmVxdWVzdBosLmdvb2dsZS5j
bG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuVmFyaWFibGUiOYLT5JMCMxIxL3YxYmV0YTEv
e25hbWU9cHJvamVjdHMvKi9jb25maWdzLyovdmFyaWFibGVzLyoqfRK7AQoNV2F0Y2hWYXJp
YWJsZRI4Lmdvb2dsZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuV2F0Y2hWYXJpYWJs
ZVJlcXVlc3QaLC5nb29nbGUuY2xvdWQucnVudGltZWNvbmZpZy52MWJldGExLlZhcmlhYmxl
IkKC0+STAjwiNy92MWJldGExL3tuYW1lPXByb2plY3RzLyovY29uZmlncy8qL3ZhcmlhYmxl
cy8qKn06d2F0Y2g6ASoSvQEKDkNyZWF0ZVZhcmlhYmxlEjkuZ29vZ2xlLmNsb3VkLnJ1bnRp
bWVjb25maWcudjFiZXRhMS5DcmVhdGVWYXJpYWJsZVJlcXVlc3QaLC5nb29nbGUuY2xvdWQu
cnVudGltZWNvbmZpZy52MWJldGExLlZhcmlhYmxlIkKC0+STAjwiMC92MWJldGExL3twYXJl
bnQ9cHJvamVjdHMvKi9jb25maWdzLyp9L3ZhcmlhYmxlczoIdmFyaWFibGUSvgEKDlVwZGF0
ZVZhcmlhYmxlEjkuZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMS5VcGRhdGVW
YXJpYWJsZVJlcXVlc3QaLC5nb29nbGUuY2xvdWQucnVudGltZWNvbmZpZy52MWJldGExLlZh
cmlhYmxlIkOC0+STAj0aMS92MWJldGExL3tuYW1lPXByb2plY3RzLyovY29uZmlncy8qL3Zh
cmlhYmxlcy8qKn06CHZhcmlhYmxlEp4BCg5EZWxldGVWYXJpYWJsZRI5Lmdvb2dsZS5jbG91
ZC5ydW50aW1lY29uZmlnLnYxYmV0YTEuRGVsZXRlVmFyaWFibGVSZXF1ZXN0GhYuZ29vZ2xl
LnByb3RvYnVmLkVtcHR5IjmC0+STAjMqMS92MWJldGExL3tuYW1lPXByb2plY3RzLyovY29u
Zmlncy8qL3ZhcmlhYmxlcy8qKn0StgEKC0xpc3RXYWl0ZXJzEjYuZ29vZ2xlLmNsb3VkLnJ1
bnRpbWVjb25maWcudjFiZXRhMS5MaXN0V2FpdGVyc1JlcXVlc3QaNy5nb29nbGUuY2xvdWQu
cnVudGltZWNvbmZpZy52MWJldGExLkxpc3RXYWl0ZXJzUmVzcG9uc2UiNoLT5JMCMBIuL3Yx
YmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2NvbmZpZ3MvKn0vd2FpdGVycxKlAQoJR2V0V2Fp
dGVyEjQuZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMS5HZXRXYWl0ZXJSZXF1
ZXN0GiouZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMS5XYWl0ZXIiNoLT5JMC
MBIuL3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9jb25maWdzLyovd2FpdGVycy8qfRKmAQoM
Q3JlYXRlV2FpdGVyEjcuZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMS5DcmVh
dGVXYWl0ZXJSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiI+gtPkkwI4
Ii4vdjFiZXRhMS97cGFyZW50PXByb2plY3RzLyovY29uZmlncy8qfS93YWl0ZXJzOgZ3YWl0
ZXISlwEKDERlbGV0ZVdhaXRlchI3Lmdvb2dsZS5jbG91ZC5ydW50aW1lY29uZmlnLnYxYmV0
YTEuRGVsZXRlV2FpdGVyUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSI2gtPkkwIw
Ki4vdjFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2NvbmZpZ3MvKi93YWl0ZXJzLyp9QsIBCiZj
b20uZ29vZ2xlLmNsb3VkLnJ1bnRpbWVjb25maWcudjFiZXRhMVABWkxjbG91ZC5nb29nbGUu
Y29tL2dvL3J1bnRpbWVjb25maWcvYXBpdjFiZXRhMS9ydW50aW1lY29uZmlncGI7cnVudGlt
ZWNvbmZpZ3BiqgIiR29vZ2xlLkNsb3VkLlJ1bnRpbWVDb25maWcuVjFCZXRhMcoCIkdvb2ds
ZVxDbG91ZFxSdW50aW1lQ29uZmlnXFYxYmV0YTFKxHgKBxIFDgDCAwEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIAJgoJCgIDARIDEwA8
CgkKAgMCEgMUAC0KCQoCAwMSAxUAJQoJCgIDBBIDFgApCggKAQgSAxgAPwoJCgIIJRIDGAA/
CggKAQgSAxkAYwoJCgIICxIDGQBjCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAPwoJ
CgIIARIDGwA/CggKAQgSAxwAPwoJCgIIKRIDHAA/CqQECgIGABIFKAC4AQEalgQgUnVudGlt
ZUNvbmZpZyBBUEkgcmVwcmVzZW50cyBjb25maWd1cmF0aW9uIG9iamVjdHMgYW5kIG9wZXJh
dGlvbnMgb24gdGhvc2UKIGNvbmZpZ3VyYXRpb24gb2JqZWN0cy4KIFJ1bnRpbWVDb25maWcg
b2JqZWN0cyBjb25zaXN0IG9mIFZhcmlhYmxlcyBsb2dpY2FsbHkgZ3JvdXBlZCBpbiB0aGUg
dGhvc2UKIG9iamVjdHMuCiBWYXJpYWJsZXMgYXJlIHNpbXBsZSBrZXktdmFsdWUgcGFpcnMu
IFZhcmlhYmxlcyBjYW4gYmUgd2F0Y2hlZCBmb3IgY2hhbmdlcyBvcgogZGVsZXRpb25zLiBW
YXJpYWJsZSBrZXkgY2FuIGJlIGhpZWFyYXJjaGljYWwsIGUuZy4gcG9ydHMvc2VydmluZ19w
b3J0LAogcG9ydHMvbW9uaXRvcmluZ19wb3J0LCBldGMuIFZhcmlhYmxlIG5hbWVzIGNhbiBi
ZSBoaWVyYXJjaGljYWwuIE5vIHZhcmlhYmxlCiBuYW1lIGNhbiBiZSBwcmVmaXggb2YgYW5v
dGhlci4KIENvbmZpZyBvYmplY3RzIHJlcHJlc2VudCBsb2dpY2FsIGNvbnRhaW5lcnMgZm9y
IHZhcmlhYmxlcywgZS5nLiBmbGFncywKIHBhc3N3b3JkcywgZXRjLgoKCgoDBgABEgMoCBwK
RQoEBgACABIEKgIuAxo3IExpc3RzIGFsbCB0aGUgUnVudGltZUNvbmZpZyByZXNvdXJjZXMg
d2l0aGluIHByb2plY3QuCgoMCgUGAAIAARIDKgYRCgwKBQYAAgACEgMqEiQKDAoFBgACAAMS
AyovQgoNCgUGAAIABBIEKwQtBgoRCgkGAAIABLDKvCISBCsELQYKQAoEBgACARIEMQI1Axoy
IEdldHMgaW5mb3JtYXRpb24gYWJvdXQgYSBSdW50aW1lQ29uZmlnIHJlc291cmNlLgoKDAoF
BgACAQESAzEGDwoMCgUGAAIBAhIDMRAgCgwKBQYAAgEDEgMxKzgKDQoFBgACAQQSBDIENAYK
EQoJBgACAQSwyrwiEgQyBDQGCmwKBAYAAgISBDkCPgMaXiBDcmVhdGVzIGEgbmV3IFJ1bnRp
bWVDb25maWcgcmVzb3VyY2UuIFRoZSBjb25maWd1cmF0aW9uIG5hbWUgbXVzdCBiZQogdW5p
cXVlIHdpdGhpbiBwcm9qZWN0LgoKDAoFBgACAgESAzkGEgoMCgUGAAICAhIDORMmCgwKBQYA
AgIDEgM5MT4KDQoFBgACAgQSBDoEPQYKEQoJBgACAgSwyrwiEgQ6BD0GCloKBAYAAgMSBEEC
RgMaTCBVcGRhdGVzIGEgUnVudGltZUNvbmZpZyByZXNvdXJjZS4gVGhlIGNvbmZpZ3VyYXRp
b24gbXVzdCBleGlzdCBiZWZvcmVoYW5kLgoKDAoFBgACAwESA0EGEgoMCgUGAAIDAhIDQRMm
CgwKBQYAAgMDEgNBMT4KDQoFBgACAwQSBEIERQYKEQoJBgACAwSwyrwiEgRCBEUGCjEKBAYA
AgQSBEkCTQMaIyBEZWxldGVzIGEgUnVudGltZUNvbmZpZyByZXNvdXJjZS4KCgwKBQYAAgQB
EgNJBhIKDAoFBgACBAISA0kTJgoMCgUGAAIEAxIDSTFGCg0KBQYAAgQEEgRKBEwGChEKCQYA
AgQEsMq8IhIESgRMBgqLAgoEBgACBRIEUwJXAxr8ASBMaXN0cyB2YXJpYWJsZXMgd2l0aGlu
IGdpdmVuIGEgY29uZmlndXJhdGlvbiwgbWF0Y2hpbmcgYW55IHByb3ZpZGVkCiBmaWx0ZXJz
LiBUaGlzIG9ubHkgbGlzdHMgdmFyaWFibGUgbmFtZXMsIG5vdCB0aGUgdmFsdWVzLCB1bmxl
c3MKIGByZXR1cm5fdmFsdWVzYCBpcyB0cnVlLCBpbiB3aGljaCBjYXNlIG9ubHkgdmFyaWFi
bGVzIHRoYXQgdXNlciBoYXMgSUFNCiBwZXJtaXNzaW9uIHRvIEdldFZhcmlhYmxlIHdpbGwg
YmUgcmV0dXJuZWQuCgoMCgUGAAIFARIDUwYTCgwKBQYAAgUCEgNTFCgKDAoFBgACBQMSA1Mz
SAoNCgUGAAIFBBIEVARWBgoRCgkGAAIFBLDKvCISBFQEVgYKOQoEBgACBhIEWgJeAxorIEdl
dHMgaW5mb3JtYXRpb24gYWJvdXQgYSBzaW5nbGUgdmFyaWFibGUuCgoMCgUGAAIGARIDWgYR
CgwKBQYAAgYCEgNaEiQKDAoFBgACBgMSA1ovNwoNCgUGAAIGBBIEWwRdBgoRCgkGAAIGBLDK
vCISBFsEXQYKpQUKBAYAAgcSBG4CcwMalgUgV2F0Y2hlcyBhIHNwZWNpZmljIHZhcmlhYmxl
IGFuZCB3YWl0cyBmb3IgYSBjaGFuZ2UgaW4gdGhlIHZhcmlhYmxlJ3MgdmFsdWUuCiBXaGVu
IHRoZXJlIGlzIGEgY2hhbmdlLCB0aGlzIG1ldGhvZCByZXR1cm5zIHRoZSBuZXcgdmFsdWUg
b3IgdGltZXMgb3V0LgoKIElmIGEgdmFyaWFibGUgaXMgZGVsZXRlZCB3aGlsZSBiZWluZyB3
YXRjaGVkLCB0aGUgYHZhcmlhYmxlU3RhdGVgIHN0YXRlIGlzCiBzZXQgdG8gYERFTEVURURg
IGFuZCB0aGUgbWV0aG9kIHJldHVybnMgdGhlIGxhc3Qga25vd24gdmFyaWFibGUgYHZhbHVl
YC4KCiBJZiB5b3Ugc2V0IHRoZSBkZWFkbGluZSBmb3Igd2F0Y2hpbmcgdG8gYSBsYXJnZXIg
dmFsdWUgdGhhbiBpbnRlcm5hbAogdGltZW91dCAoNjAgc2Vjb25kcyksIHRoZSBjdXJyZW50
IHZhcmlhYmxlIHZhbHVlIGlzIHJldHVybmVkIGFuZCB0aGUKIGB2YXJpYWJsZVN0YXRlYCB3
aWxsIGJlIGBWQVJJQUJMRV9TVEFURV9VTlNQRUNJRklFRGAuCgogVG8gbGVhcm4gbW9yZSBh
Ym91dCBjcmVhdGluZyBhIHdhdGNoZXIsIHJlYWQgdGhlCiBbV2F0Y2hpbmcgYSBWYXJpYWJs
ZSBmb3IKIENoYW5nZXNdKC9kZXBsb3ltZW50LW1hbmFnZXIvcnVudGltZS1jb25maWd1cmF0
b3Ivd2F0Y2hpbmctYS12YXJpYWJsZSkKIGRvY3VtZW50YXRpb24uCgoMCgUGAAIHARIDbgYT
CgwKBQYAAgcCEgNuFCgKDAoFBgACBwMSA24zOwoNCgUGAAIHBBIEbwRyBgoRCgkGAAIHBLDK
vCISBG8EcgYK+QIKBAYAAggSBX0CggEDGukCIENyZWF0ZXMgYSB2YXJpYWJsZSB3aXRoaW4g
dGhlIGdpdmVuIGNvbmZpZ3VyYXRpb24uIFlvdSBjYW5ub3QgY3JlYXRlCiBhIHZhcmlhYmxl
IHdpdGggYSBuYW1lIHRoYXQgaXMgYSBwcmVmaXggb2YgYW4gZXhpc3RpbmcgdmFyaWFibGUg
bmFtZSwgb3IgYQogbmFtZSB0aGF0IGhhcyBhbiBleGlzdGluZyB2YXJpYWJsZSBuYW1lIGFz
IGEgcHJlZml4LgoKIFRvIGxlYXJuIG1vcmUgYWJvdXQgY3JlYXRpbmcgYSB2YXJpYWJsZSwg
cmVhZCB0aGUKIFtTZXR0aW5nIGFuZCBHZXR0aW5nCiBEYXRhXSgvZGVwbG95bWVudC1tYW5h
Z2VyL3J1bnRpbWUtY29uZmlndXJhdG9yL3NldC1hbmQtZ2V0LXZhcmlhYmxlcykKIGRvY3Vt
ZW50YXRpb24uCgoMCgUGAAIIARIDfQYUCgwKBQYAAggCEgN9FSoKDAoFBgACCAMSA301PQoO
CgUGAAIIBBIFfgSBAQYKEgoJBgACCASwyrwiEgV+BIEBBgpACgQGAAIJEgaFAQKKAQMaMCBV
cGRhdGVzIGFuIGV4aXN0aW5nIHZhcmlhYmxlIHdpdGggYSBuZXcgdmFsdWUuCgoNCgUGAAIJ
ARIEhQEGFAoNCgUGAAIJAhIEhQEVKgoNCgUGAAIJAxIEhQE1PQoPCgUGAAIJBBIGhgEEiQEG
ChMKCQYAAgkEsMq8IhIGhgEEiQEGCqgCCgQGAAIKEgaSAQKWAQMalwIgRGVsZXRlcyBhIHZh
cmlhYmxlIG9yIG11bHRpcGxlIHZhcmlhYmxlcy4KCiBJZiB5b3Ugc3BlY2lmeSBhIHZhcmlh
YmxlIG5hbWUsIHRoZW4gdGhhdCB2YXJpYWJsZSBpcyBkZWxldGVkLiBJZiB5b3UKIHNwZWNp
ZnkgYSBwcmVmaXggYW5kIGByZWN1cnNpdmVgIGlzIHRydWUsIHRoZW4gYWxsIHZhcmlhYmxl
cyB3aXRoIHRoYXQKIHByZWZpeCBhcmUgZGVsZXRlZC4gWW91IG11c3Qgc2V0IGEgYHJlY3Vy
c2l2ZWAgdG8gdHJ1ZSBpZiB5b3UgZGVsZXRlCiB2YXJpYWJsZXMgYnkgcHJlZml4LgoKDQoF
BgACCgESBJIBBhQKDQoFBgACCgISBJIBFSoKDQoFBgACCgMSBJIBNUoKDwoFBgACCgQSBpMB
BJUBBgoTCgkGAAIKBLDKvCISBpMBBJUBBgo+CgQGAAILEgaZAQKdAQMaLiBMaXN0IHdhaXRl
cnMgd2l0aGluIHRoZSBnaXZlbiBjb25maWd1cmF0aW9uLgoKDQoFBgACCwESBJkBBhEKDQoF
BgACCwISBJkBEiQKDQoFBgACCwMSBJkBL0IKDwoFBgACCwQSBpoBBJwBBgoTCgkGAAILBLDK
vCISBpoBBJwBBgo5CgQGAAIMEgagAQKkAQMaKSBHZXRzIGluZm9ybWF0aW9uIGFib3V0IGEg
c2luZ2xlIHdhaXRlci4KCg0KBQYAAgwBEgSgAQYPCg0KBQYAAgwCEgSgARAgCg0KBQYAAgwD
EgSgASsxCg8KBQYAAgwEEgahAQSjAQYKEwoJBgACDASwyrwiEgahAQSjAQYK+AIKBAYAAg0S
BqsBArABAxrnAiBDcmVhdGVzIGEgV2FpdGVyIHJlc291cmNlLiBUaGlzIG9wZXJhdGlvbiBy
ZXR1cm5zIGEgbG9uZy1ydW5uaW5nIE9wZXJhdGlvbgogcmVzb3VyY2Ugd2hpY2ggY2FuIGJl
IHBvbGxlZCBmb3IgY29tcGxldGlvbi4gSG93ZXZlciwgYSB3YWl0ZXIgd2l0aCB0aGUKIGdp
dmVuIG5hbWUgd2lsbCBleGlzdCAoYW5kIGNhbiBiZSByZXRyaWV2ZWQpIHByaW9yIHRvIHRo
ZSBvcGVyYXRpb24KIGNvbXBsZXRpbmcuIElmIHRoZSBvcGVyYXRpb24gZmFpbHMsIHRoZSBm
YWlsZWQgV2FpdGVyIHJlc291cmNlIHdpbGwKIHN0aWxsIGV4aXN0IGFuZCBtdXN0IGJlIGRl
bGV0ZWQgcHJpb3IgdG8gc3Vic2VxdWVudCBjcmVhdGlvbiBhdHRlbXB0cy4KCg0KBQYAAg0B
EgSrAQYSCg0KBQYAAg0CEgSrARMmCg0KBQYAAg0DEgSrATFNCg8KBQYAAg0EEgasAQSvAQYK
EwoJBgACDQSwyrwiEgasAQSvAQYKPQoEBgACDhIGswECtwEDGi0gRGVsZXRlcyB0aGUgd2Fp
dGVyIHdpdGggdGhlIHNwZWNpZmllZCBuYW1lLgoKDQoFBgACDgESBLMBBhIKDQoFBgACDgIS
BLMBEyYKDQoFBgACDgMSBLMBMUYKDwoFBgACDgQSBrQBBLYBBgoTCgkGAAIOBLDKvCISBrQB
BLYBBgo3CgIEABIGuwEAyAEBGikgUmVxdWVzdCBmb3IgdGhlIGBMaXN0Q29uZmlncygpYCBt
ZXRob2QuCgoLCgMEAAESBLsBCBoKpQEKBAQAAgASBL8BAhQalgEgVGhlIFtwcm9qZWN0CiBJ
RF0oaHR0cHM6Ly9zdXBwb3J0Lmdvb2dsZS5jb20vY2xvdWQvYW5zd2VyLzYxNTg4NDA/aGw9
ZW4mcmVmX3RvcGljPTYxNTg4NDgpCiBmb3IgdGhpcyByZXF1ZXN0LCBpbiB0aGUgZm9ybWF0
IGBwcm9qZWN0cy9bUFJPSkVDVF9JRF1gLgoKDQoFBAACAAUSBL8BAggKDQoFBAACAAESBL8B
CQ8KDQoFBAACAAMSBL8BEhMKkgEKBAQAAgESBMMBAhYagwEgU3BlY2lmaWVzIHRoZSBudW1i
ZXIgb2YgcmVzdWx0cyB0byByZXR1cm4gcGVyIHBhZ2UuIElmIHRoZXJlIGFyZSBmZXdlcgog
ZWxlbWVudHMgdGhhbiB0aGUgc3BlY2lmaWVkIG51bWJlciwgcmV0dXJucyBhbGwgZWxlbWVu
dHMuCgoNCgUEAAIBBRIEwwECBwoNCgUEAAIBARIEwwEIEQoNCgUEAAIBAxIEwwEUFQqaAQoE
BAACAhIExwECGBqLASBTcGVjaWZpZXMgYSBwYWdlIHRva2VuIHRvIHVzZS4gU2V0IGBwYWdl
VG9rZW5gIHRvIGEgYG5leHRQYWdlVG9rZW5gCiByZXR1cm5lZCBieSBhIHByZXZpb3VzIGxp
c3QgcmVxdWVzdCB0byBnZXQgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLgoKDQoFBAACAgUS
BMcBAggKDQoFBAACAgESBMcBCRMKDQoFBAACAgMSBMcBFhcKnwEKAgQBEgbMAQDXAQEakAEg
YExpc3RDb25maWdzKClgIHJldHVybnMgdGhlIGZvbGxvd2luZyByZXNwb25zZS4gVGhlIG9y
ZGVyIG9mIHJldHVybmVkCiBvYmplY3RzIGlzIGFyYml0cmFyeTsgdGhhdCBpcywgaXQgaXMg
bm90IG9yZGVyZWQgaW4gYW55IHBhcnRpY3VsYXIgd2F5LgoKCwoDBAEBEgTMAQgbCpwBCgQE
AQIAEgTPAQIlGo0BIEEgbGlzdCBvZiB0aGUgY29uZmlndXJhdGlvbnMgaW4gdGhlIHByb2pl
Y3QuIFRoZSBvcmRlciBvZiByZXR1cm5lZAogb2JqZWN0cyBpcyBhcmJpdHJhcnk7IHRoYXQg
aXMsIGl0IGlzIG5vdCBvcmRlcmVkIGluIGFueSBwYXJ0aWN1bGFyIHdheS4KCg0KBQQBAgAE
EgTPAQIKCg0KBQQBAgAGEgTPAQsYCg0KBQQBAgABEgTPARkgCg0KBQQBAgADEgTPASMkCtYC
CgQEAQIBEgTWAQIdGscCIFRoaXMgdG9rZW4gYWxsb3dzIHlvdSB0byBnZXQgdGhlIG5leHQg
cGFnZSBvZiByZXN1bHRzIGZvciBsaXN0IHJlcXVlc3RzLgogSWYgdGhlIG51bWJlciBvZiBy
ZXN1bHRzIGlzIGxhcmdlciB0aGFuIGBwYWdlU2l6ZWAsIHVzZSB0aGUgYG5leHRQYWdlVG9r
ZW5gCiBhcyBhIHZhbHVlIGZvciB0aGUgcXVlcnkgcGFyYW1ldGVyIGBwYWdlVG9rZW5gIGlu
IHRoZSBuZXh0IGxpc3QgcmVxdWVzdC4KIFN1YnNlcXVlbnQgbGlzdCByZXF1ZXN0cyB3aWxs
IGhhdmUgdGhlaXIgb3duIGBuZXh0UGFnZVRva2VuYCB0byBjb250aW51ZQogcGFnaW5nIHRo
cm91Z2ggdGhlIHJlc3VsdHMKCg0KBQQBAgEFEgTWAQIICg0KBQQBAgEBEgTWAQkYCg0KBQQB
AgEDEgTWARscCi4KAgQCEgbaAQDfAQEaICBHZXRzIGEgUnVudGltZUNvbmZpZyByZXNvdXJj
ZS4KCgsKAwQCARIE2gEIGAqCAQoEBAICABIE3gECEhp0IFRoZSBuYW1lIG9mIHRoZSBSdW50
aW1lQ29uZmlnIHJlc291cmNlIHRvIHJldHJpZXZlLCBpbiB0aGUgZm9ybWF0OgoKIGBwcm9q
ZWN0cy9bUFJPSkVDVF9JRF0vY29uZmlncy9bQ09ORklHX05BTUVdYAoKDQoFBAICAAUSBN4B
AggKDQoFBAICAAESBN4BCQ0KDQoFBAICAAMSBN4BEBEKMQoCBAMSBuIBAPYBARojIENyZWF0
ZXMgYSBSdW50aW1lQ29uZmlnIHJlc291cmNlLgoKCwoDBAMBEgTiAQgbCqUBCgQEAwIAEgTm
AQIUGpYBIFRoZSBbcHJvamVjdAogSURdKGh0dHBzOi8vc3VwcG9ydC5nb29nbGUuY29tL2Ns
b3VkL2Fuc3dlci82MTU4ODQwP2hsPWVuJnJlZl90b3BpYz02MTU4ODQ4KQogZm9yIHRoaXMg
cmVxdWVzdCwgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMvW1BST0pFQ1RfSURdYC4KCg0KBQQD
AgAFEgTmAQIICg0KBQQDAgABEgTmAQkPCg0KBQQDAgADEgTmARITCiwKBAQDAgESBOkBAhsa
HiBUaGUgUnVudGltZUNvbmZpZyB0byBjcmVhdGUuCgoNCgUEAwIBBhIE6QECDwoNCgUEAwIB
ARIE6QEQFgoNCgUEAwIBAxIE6QEZGgqzAwoEBAMCAhIE9QECGBqkAyBBbiBvcHRpb25hbCBi
dXQgcmVjb21tZW5kZWQgdW5pcXVlIGByZXF1ZXN0X2lkYC4gSWYgdGhlIHNlcnZlcgogcmVj
ZWl2ZXMgdHdvIGBjcmVhdGUoKWAgcmVxdWVzdHMgIHdpdGggdGhlIHNhbWUKIGByZXF1ZXN0
X2lkYCwgdGhlbiB0aGUgc2Vjb25kIHJlcXVlc3Qgd2lsbCBiZSBpZ25vcmVkIGFuZCB0aGUK
IGZpcnN0IHJlc291cmNlIGNyZWF0ZWQgYW5kIHN0b3JlZCBpbiB0aGUgYmFja2VuZCBpcyBy
ZXR1cm5lZC4KIEVtcHR5IGByZXF1ZXN0X2lkYCBmaWVsZHMgYXJlIGlnbm9yZWQuCgogSXQg
aXMgcmVzcG9uc2liaWxpdHkgb2YgdGhlIGNsaWVudCB0byBlbnN1cmUgdW5pcXVlbmVzcyBv
ZiB0aGUKIGByZXF1ZXN0X2lkYCBzdHJpbmdzLgoKIGByZXF1ZXN0X2lkYCBzdHJpbmdzIGFy
ZSBsaW1pdGVkIHRvIDY0IGNoYXJhY3RlcnMuCgoNCgUEAwICBRIE9QECCAoNCgUEAwICARIE
9QEJEwoNCgUEAwICAxIE9QEWFwo8CgIEBBIG+QEAgQIBGi4gUmVxdWVzdCBtZXNzYWdlIGZv
ciBgVXBkYXRlQ29uZmlnKClgIG1ldGhvZC4KCgsKAwQEARIE+QEIGwqAAQoEBAQCABIE/QEC
EhpyIFRoZSBuYW1lIG9mIHRoZSBSdW50aW1lQ29uZmlnIHJlc291cmNlIHRvIHVwZGF0ZSwg
aW4gdGhlIGZvcm1hdDoKCiBgcHJvamVjdHMvW1BST0pFQ1RfSURdL2NvbmZpZ3MvW0NPTkZJ
R19OQU1FXWAKCg0KBQQEAgAFEgT9AQIICg0KBQQEAgABEgT9AQkNCg0KBQQEAgADEgT9ARAR
Ci4KBAQEAgESBIACAhsaICBUaGUgY29uZmlnIHJlc291cmNlIHRvIHVwZGF0ZS4KCg0KBQQE
AgEGEgSAAgIPCg0KBQQEAgEBEgSAAhAWCg0KBQQEAgEDEgSAAhkaCjgKAgQFEgaEAgCJAgEa
KiBSZXF1ZXN0IGZvciB0aGUgYERlbGV0ZUNvbmZpZygpYCBtZXRob2QuCgoLCgMEBQESBIQC
CBsKdAoEBAUCABIEiAICEhpmIFRoZSBSdW50aW1lQ29uZmlnIHJlc291cmNlIHRvIGRlbGV0
ZSwgaW4gdGhlIGZvcm1hdDoKCiBgcHJvamVjdHMvW1BST0pFQ1RfSURdL2NvbmZpZ3MvW0NP
TkZJR19OQU1FXWAKCg0KBQQFAgAFEgSIAgIICg0KBQQFAgABEgSIAgkNCg0KBQQFAgADEgSI
AhARCjkKAgQGEgaMAgClAgEaKyBSZXF1ZXN0IGZvciB0aGUgYExpc3RWYXJpYWJsZXMoKWAg
bWV0aG9kLgoKCwoDBAYBEgSMAggcCtgBCgQEBgIAEgSSAgIUGskBIFRoZSBwYXRoIHRvIHRo
ZSBSdW50aW1lQ29uZmlnIHJlc291cmNlIGZvciB3aGljaCB5b3Ugd2FudCB0byBsaXN0CiB2
YXJpYWJsZXMuIFRoZSBjb25maWd1cmF0aW9uIG11c3QgZXhpc3QgYmVmb3JlaGFuZDsgdGhl
IHBhdGggbXVzdCBieSBpbiB0aGUKIGZvcm1hdDoKCiBgcHJvamVjdHMvW1BST0pFQ1RfSURd
L2NvbmZpZ3MvW0NPTkZJR19OQU1FXWAKCg0KBQQGAgAFEgSSAgIICg0KBQQGAgABEgSSAgkP
Cg0KBQQGAgADEgSSAhITCp8BCgQEBgIBEgSXAgIUGpABIEZpbHRlcnMgdmFyaWFibGVzIGJ5
IG1hdGNoaW5nIHRoZSBzcGVjaWZpZWQgZmlsdGVyLiBGb3IgZXhhbXBsZToKCiBgcHJvamVj
dHMvZXhhbXBsZS1wcm9qZWN0L2NvbmZpZy9bQ09ORklHX05BTUVdL3ZhcmlhYmxlcy9leGFt
cGxlLXZhcmlhYmxlYC4KCg0KBQQGAgEFEgSXAgIICg0KBQQGAgEBEgSXAgkPCg0KBQQGAgED
EgSXAhITCpIBCgQEBgICEgSbAgIWGoMBIFNwZWNpZmllcyB0aGUgbnVtYmVyIG9mIHJlc3Vs
dHMgdG8gcmV0dXJuIHBlciBwYWdlLiBJZiB0aGVyZSBhcmUgZmV3ZXIKIGVsZW1lbnRzIHRo
YW4gdGhlIHNwZWNpZmllZCBudW1iZXIsIHJldHVybnMgYWxsIGVsZW1lbnRzLgoKDQoFBAYC
AgUSBJsCAgcKDQoFBAYCAgESBJsCCBEKDQoFBAYCAgMSBJsCFBUKmgEKBAQGAgMSBJ8CAhga
iwEgU3BlY2lmaWVzIGEgcGFnZSB0b2tlbiB0byB1c2UuIFNldCBgcGFnZVRva2VuYCB0byBh
IGBuZXh0UGFnZVRva2VuYAogcmV0dXJuZWQgYnkgYSBwcmV2aW91cyBsaXN0IHJlcXVlc3Qg
dG8gZ2V0IHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4KCg0KBQQGAgMFEgSfAgIICg0KBQQG
AgMBEgSfAgkTCg0KBQQGAgMDEgSfAhYXCtEBCgQEBgIEEgSkAgIZGsIBIFRoZSBmbGFnIGlu
ZGljYXRlcyB3aGV0aGVyIHRoZSB1c2VyIHdhbnRzIHRvIHJldHVybiB2YWx1ZXMgb2YgdmFy
aWFibGVzLgogSWYgdHJ1ZSwgdGhlbiBvbmx5IHRob3NlIHZhcmlhYmxlcyB0aGF0IHVzZXIg
aGFzIElBTSBHZXRWYXJpYWJsZSBwZXJtaXNzaW9uCiB3aWxsIGJlIHJldHVybmVkIGFsb25n
IHdpdGggdGhlaXIgdmFsdWVzLgoKDQoFBAYCBAUSBKQCAgYKDQoFBAYCBAESBKQCBxQKDQoF
BAYCBAMSBKQCFxgKOgoCBAcSBqgCALMCARosIFJlc3BvbnNlIGZvciB0aGUgYExpc3RWYXJp
YWJsZXMoKWAgbWV0aG9kLgoKCwoDBAcBEgSoAggdCmsKBAQHAgASBKsCAiIaXSBBIGxpc3Qg
b2YgdmFyaWFibGVzIGFuZCB0aGVpciB2YWx1ZXMuIFRoZSBvcmRlciBvZiByZXR1cm5lZCB2
YXJpYWJsZQogb2JqZWN0cyBpcyBhcmJpdHJhcnkuCgoNCgUEBwIABBIEqwICCgoNCgUEBwIA
BhIEqwILEwoNCgUEBwIAARIEqwIUHQoNCgUEBwIAAxIEqwIgIQrWAgoEBAcCARIEsgICHRrH
AiBUaGlzIHRva2VuIGFsbG93cyB5b3UgdG8gZ2V0IHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0
cyBmb3IgbGlzdCByZXF1ZXN0cy4KIElmIHRoZSBudW1iZXIgb2YgcmVzdWx0cyBpcyBsYXJn
ZXIgdGhhbiBgcGFnZVNpemVgLCB1c2UgdGhlIGBuZXh0UGFnZVRva2VuYAogYXMgYSB2YWx1
ZSBmb3IgdGhlIHF1ZXJ5IHBhcmFtZXRlciBgcGFnZVRva2VuYCBpbiB0aGUgbmV4dCBsaXN0
IHJlcXVlc3QuCiBTdWJzZXF1ZW50IGxpc3QgcmVxdWVzdHMgd2lsbCBoYXZlIHRoZWlyIG93
biBgbmV4dFBhZ2VUb2tlbmAgdG8gY29udGludWUKIHBhZ2luZyB0aHJvdWdoIHRoZSByZXN1
bHRzCgoNCgUEBwIBBRIEsgICCAoNCgUEBwIBARIEsgIJGAoNCgUEBwIBAxIEsgIbHAo5CgIE
CBIGtgIAwwIBGisgUmVxdWVzdCBmb3IgdGhlIGBXYXRjaFZhcmlhYmxlKClgIG1ldGhvZC4K
CgsKAwQIARIEtgIIHApxCgQECAIAEgS6AgISGmMgVGhlIG5hbWUgb2YgdGhlIHZhcmlhYmxl
IHRvIHdhdGNoLCBpbiB0aGUgZm9ybWF0OgoKIGBwcm9qZWN0cy9bUFJPSkVDVF9JRF0vY29u
Zmlncy9bQ09ORklHX05BTUVdYAoKDQoFBAgCAAUSBLoCAggKDQoFBAgCAAESBLoCCQ0KDQoF
BAgCAAMSBLoCEBEKqQIKBAQIAgESBMICAisamgIgSWYgc3BlY2lmaWVkLCBjaGVja3MgdGhl
IGN1cnJlbnQgdGltZXN0YW1wIG9mIHRoZSB2YXJpYWJsZSBhbmQgaWYgdGhlCiBjdXJyZW50
IHRpbWVzdGFtcCBpcyBuZXdlciB0aGFuIGBuZXdlclRoYW5gIHRpbWVzdGFtcCwgdGhlIG1l
dGhvZCByZXR1cm5zCiBpbW1lZGlhdGVseS4KCiBJZiBub3Qgc3BlY2lmaWVkIG9yIHRoZSB2
YXJpYWJsZSBoYXMgYW4gb2xkZXIgdGltZXN0YW1wLCB0aGUgd2F0Y2hlciB3YWl0cwogZm9y
IGEgdGhlIHZhbHVlIHRvIGNoYW5nZSBiZWZvcmUgcmV0dXJuaW5nLgoKDQoFBAgCAQYSBMIC
AhsKDQoFBAgCAQESBMICHCYKDQoFBAgCAQMSBMICKSoKNwoCBAkSBsYCAMsCARopIFJlcXVl
c3QgZm9yIHRoZSBgR2V0VmFyaWFibGUoKWAgbWV0aG9kLgoKCwoDBAkBEgTGAggaCosBCgQE
CQIAEgTKAgISGn0gVGhlIG5hbWUgb2YgdGhlIHZhcmlhYmxlIHRvIHJldHVybiwgaW4gdGhl
IGZvcm1hdDoKCiBgcHJvamVjdHMvW1BST0pFQ1RfSURdL2NvbmZpZ3MvW0NPTkZJR19OQU1F
XS92YXJpYWJsZXMvW1ZBUklCTEVfTkFNRV1gCgoNCgUECQIABRIEygICCAoNCgUECQIAARIE
ygIJDQoNCgUECQIAAxIEygIQEQo6CgIEChIGzgIA4wIBGiwgUmVxdWVzdCBmb3IgdGhlIGBD
cmVhdGVWYXJpYWJsZSgpYCBtZXRob2QuCgoLCgMECgESBM4CCB0K1QEKBAQKAgASBNMCAhQa
xgEgVGhlIHBhdGggdG8gdGhlIFJ1dGltZUNvbmZpZyByZXNvdXJjZSB0aGF0IHRoaXMgdmFy
aWFibGUgc2hvdWxkIGJlbG9uZyB0by4KIFRoZSBjb25maWd1cmF0aW9uIG11c3QgZXhpc3Qg
YmVmb3JlaGFuZDsgdGhlIHBhdGggbXVzdCBieSBpbiB0aGUgZm9ybWF0OgoKIGBwcm9qZWN0
cy9bUFJPSkVDVF9JRF0vY29uZmlncy9bQ09ORklHX05BTUVdYAoKDQoFBAoCAAUSBNMCAggK
DQoFBAoCAAESBNMCCQ8KDQoFBAoCAAMSBNMCEhMKJwoEBAoCARIE1gICGBoZIFRoZSB2YXJp
YWJsZSB0byBjcmVhdGUuCgoNCgUECgIBBhIE1gICCgoNCgUECgIBARIE1gILEwoNCgUECgIB
AxIE1gIWFwqzAwoEBAoCAhIE4gICGBqkAyBBbiBvcHRpb25hbCBidXQgcmVjb21tZW5kZWQg
dW5pcXVlIGByZXF1ZXN0X2lkYC4gSWYgdGhlIHNlcnZlcgogcmVjZWl2ZXMgdHdvIGBjcmVh
dGUoKWAgcmVxdWVzdHMgIHdpdGggdGhlIHNhbWUKIGByZXF1ZXN0X2lkYCwgdGhlbiB0aGUg
c2Vjb25kIHJlcXVlc3Qgd2lsbCBiZSBpZ25vcmVkIGFuZCB0aGUKIGZpcnN0IHJlc291cmNl
IGNyZWF0ZWQgYW5kIHN0b3JlZCBpbiB0aGUgYmFja2VuZCBpcyByZXR1cm5lZC4KIEVtcHR5
IGByZXF1ZXN0X2lkYCBmaWVsZHMgYXJlIGlnbm9yZWQuCgogSXQgaXMgcmVzcG9uc2liaWxp
dHkgb2YgdGhlIGNsaWVudCB0byBlbnN1cmUgdW5pcXVlbmVzcyBvZiB0aGUKIGByZXF1ZXN0
X2lkYCBzdHJpbmdzLgoKIGByZXF1ZXN0X2lkYCBzdHJpbmdzIGFyZSBsaW1pdGVkIHRvIDY0
IGNoYXJhY3RlcnMuCgoNCgUECgICBRIE4gICCAoNCgUECgICARIE4gIJEwoNCgUECgICAxIE
4gIWFwo6CgIECxIG5gIA7gIBGiwgUmVxdWVzdCBmb3IgdGhlIGBVcGRhdGVWYXJpYWJsZSgp
YCBtZXRob2QuCgoLCgMECwESBOYCCB0KjAEKBAQLAgASBOoCAhIafiBUaGUgbmFtZSBvZiB0
aGUgdmFyaWFibGUgdG8gdXBkYXRlLCBpbiB0aGUgZm9ybWF0OgoKIGBwcm9qZWN0cy9bUFJP
SkVDVF9JRF0vY29uZmlncy9bQ09ORklHX05BTUVdL3ZhcmlhYmxlcy9bVkFSSUFCTEVfTkFN
RV1gCgoNCgUECwIABRIE6gICCAoNCgUECwIAARIE6gIJDQoNCgUECwIAAxIE6gIQEQonCgQE
CwIBEgTtAgIYGhkgVGhlIHZhcmlhYmxlIHRvIHVwZGF0ZS4KCg0KBQQLAgEGEgTtAgIKCg0K
BQQLAgEBEgTtAgsTCg0KBQQLAgEDEgTtAhYXCjoKAgQMEgbxAgD6AgEaLCBSZXF1ZXN0IGZv
ciB0aGUgYERlbGV0ZVZhcmlhYmxlKClgIG1ldGhvZC4KCgsKAwQMARIE8QIIHQqMAQoEBAwC
ABIE9QICEhp+IFRoZSBuYW1lIG9mIHRoZSB2YXJpYWJsZSB0byBkZWxldGUsIGluIHRoZSBm
b3JtYXQ6CgogYHByb2plY3RzL1tQUk9KRUNUX0lEXS9jb25maWdzL1tDT05GSUdfTkFNRV0v
dmFyaWFibGVzL1tWQVJJQUJMRV9OQU1FXWAKCg0KBQQMAgAFEgT1AgIICg0KBQQMAgABEgT1
AgkNCg0KBQQMAgADEgT1AhARCl0KBAQMAgESBPkCAhUaTyBTZXQgdG8gYHRydWVgIHRvIHJl
Y3Vyc2l2ZWx5IGRlbGV0ZSBtdWx0aXBsZSB2YXJpYWJsZXMgd2l0aCB0aGUgc2FtZQogcHJl
Zml4LgoKDQoFBAwCAQUSBPkCAgYKDQoFBAwCAQESBPkCBxAKDQoFBAwCAQMSBPkCExQKNwoC
BA0SBv0CAIsDARopIFJlcXVlc3QgZm9yIHRoZSBgTGlzdFdhaXRlcnMoKWAgbWV0aG9kLgoK
CwoDBA0BEgT9AggaCtUBCgQEDQIAEgSCAwIUGsYBIFRoZSBwYXRoIHRvIHRoZSBjb25maWd1
cmF0aW9uIGZvciB3aGljaCB5b3Ugd2FudCB0byBnZXQgYSBsaXN0IG9mIHdhaXRlcnMuCiBU
aGUgY29uZmlndXJhdGlvbiBtdXN0IGV4aXN0IGJlZm9yZWhhbmQ7IHRoZSBwYXRoIG11c3Qg
YnkgaW4gdGhlIGZvcm1hdDoKCiBgcHJvamVjdHMvW1BST0pFQ1RfSURdL2NvbmZpZ3MvW0NP
TkZJR19OQU1FXWAKCg0KBQQNAgAFEgSCAwIICg0KBQQNAgABEgSCAwkPCg0KBQQNAgADEgSC
AxITCpIBCgQEDQIBEgSGAwIWGoMBIFNwZWNpZmllcyB0aGUgbnVtYmVyIG9mIHJlc3VsdHMg
dG8gcmV0dXJuIHBlciBwYWdlLiBJZiB0aGVyZSBhcmUgZmV3ZXIKIGVsZW1lbnRzIHRoYW4g
dGhlIHNwZWNpZmllZCBudW1iZXIsIHJldHVybnMgYWxsIGVsZW1lbnRzLgoKDQoFBA0CAQUS
BIYDAgcKDQoFBA0CAQESBIYDCBEKDQoFBA0CAQMSBIYDFBUKmgEKBAQNAgISBIoDAhgaiwEg
U3BlY2lmaWVzIGEgcGFnZSB0b2tlbiB0byB1c2UuIFNldCBgcGFnZVRva2VuYCB0byBhIGBu
ZXh0UGFnZVRva2VuYAogcmV0dXJuZWQgYnkgYSBwcmV2aW91cyBsaXN0IHJlcXVlc3QgdG8g
Z2V0IHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4KCg0KBQQNAgIFEgSKAwIICg0KBQQNAgIB
EgSKAwkTCg0KBQQNAgIDEgSKAxYXCmgKAgQOEgaPAwCZAwEaWiBSZXNwb25zZSBmb3IgdGhl
IGBMaXN0V2FpdGVycygpYCBtZXRob2QuCiBPcmRlciBvZiByZXR1cm5lZCB3YWl0ZXIgb2Jq
ZWN0cyBpcyBhcmJpdHJhcnkuCgoLCgMEDgESBI8DCBsKLQoEBA4CABIEkQMCHhofIEZvdW5k
IHdhaXRlcnMgaW4gdGhlIHByb2plY3QuCgoNCgUEDgIABBIEkQMCCgoNCgUEDgIABhIEkQML
EQoNCgUEDgIAARIEkQMSGQoNCgUEDgIAAxIEkQMcHQrWAgoEBA4CARIEmAMCHRrHAiBUaGlz
IHRva2VuIGFsbG93cyB5b3UgdG8gZ2V0IHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cyBmb3Ig
bGlzdCByZXF1ZXN0cy4KIElmIHRoZSBudW1iZXIgb2YgcmVzdWx0cyBpcyBsYXJnZXIgdGhh
biBgcGFnZVNpemVgLCB1c2UgdGhlIGBuZXh0UGFnZVRva2VuYAogYXMgYSB2YWx1ZSBmb3Ig
dGhlIHF1ZXJ5IHBhcmFtZXRlciBgcGFnZVRva2VuYCBpbiB0aGUgbmV4dCBsaXN0IHJlcXVl
c3QuCiBTdWJzZXF1ZW50IGxpc3QgcmVxdWVzdHMgd2lsbCBoYXZlIHRoZWlyIG93biBgbmV4
dFBhZ2VUb2tlbmAgdG8gY29udGludWUKIHBhZ2luZyB0aHJvdWdoIHRoZSByZXN1bHRzCgoN
CgUEDgIBBRIEmAMCCAoNCgUEDgIBARIEmAMJGAoNCgUEDgIBAxIEmAMbHAo1CgIEDxIGnAMA
ogMBGicgUmVxdWVzdCBmb3IgdGhlIGBHZXRXYWl0ZXIoKWAgbWV0aG9kLgoKCwoDBA8BEgSc
AwgYCqoBCgQEDwIAEgShAwISGpsBIFRoZSBmdWxseS1xdWFsaWZpZWQgbmFtZSBvZiB0aGUg
V2FpdGVyIHJlc291cmNlIG9iamVjdCB0byByZXRyaWV2ZSwgaW4gdGhlCiBmb3JtYXQ6Cgog
YHByb2plY3RzL1tQUk9KRUNUX0lEXS9jb25maWdzL1tDT05GSUdfTkFNRV0vd2FpdGVycy9b
V0FJVEVSX05BTUVdYAoKDQoFBA8CAAUSBKEDAggKDQoFBA8CAAESBKEDCQ0KDQoFBA8CAAMS
BKEDEBEKPAoCBBASBqUDALoDARouIFJlcXVlc3QgbWVzc2FnZSBmb3IgYENyZWF0ZVdhaXRl
cigpYCBtZXRob2QuCgoLCgMEEAESBKUDCBsKwwEKBAQQAgASBKoDAhQatAEgVGhlIHBhdGgg
dG8gdGhlIGNvbmZpZ3VyYXRpb24gdGhhdCB3aWxsIG93biB0aGUgd2FpdGVyLgogVGhlIGNv
bmZpZ3VyYXRpb24gbXVzdCBleGlzdCBiZWZvcmVoYW5kOyB0aGUgcGF0aCBtdXN0IGJ5IGlu
IHRoZSBmb3JtYXQ6CgogYHByb2plY3RzL1tQUk9KRUNUX0lEXS9jb25maWdzL1tDT05GSUdf
TkFNRV1gLgoKDQoFBBACAAUSBKoDAggKDQoFBBACAAESBKoDCQ8KDQoFBBACAAMSBKoDEhMK
LgoEBBACARIErQMCFBogIFRoZSBXYWl0ZXIgcmVzb3VyY2UgdG8gY3JlYXRlLgoKDQoFBBAC
AQYSBK0DAggKDQoFBBACAQESBK0DCQ8KDQoFBBACAQMSBK0DEhMKswMKBAQQAgISBLkDAhga
pAMgQW4gb3B0aW9uYWwgYnV0IHJlY29tbWVuZGVkIHVuaXF1ZSBgcmVxdWVzdF9pZGAuIElm
IHRoZSBzZXJ2ZXIKIHJlY2VpdmVzIHR3byBgY3JlYXRlKClgIHJlcXVlc3RzICB3aXRoIHRo
ZSBzYW1lCiBgcmVxdWVzdF9pZGAsIHRoZW4gdGhlIHNlY29uZCByZXF1ZXN0IHdpbGwgYmUg
aWdub3JlZCBhbmQgdGhlCiBmaXJzdCByZXNvdXJjZSBjcmVhdGVkIGFuZCBzdG9yZWQgaW4g
dGhlIGJhY2tlbmQgaXMgcmV0dXJuZWQuCiBFbXB0eSBgcmVxdWVzdF9pZGAgZmllbGRzIGFy
ZSBpZ25vcmVkLgoKIEl0IGlzIHJlc3BvbnNpYmlsaXR5IG9mIHRoZSBjbGllbnQgdG8gZW5z
dXJlIHVuaXF1ZW5lc3Mgb2YgdGhlCiBgcmVxdWVzdF9pZGAgc3RyaW5ncy4KCiBgcmVxdWVz
dF9pZGAgc3RyaW5ncyBhcmUgbGltaXRlZCB0byA2NCBjaGFyYWN0ZXJzLgoKDQoFBBACAgUS
BLkDAggKDQoFBBACAgESBLkDCRMKDQoFBBACAgMSBLkDFhcKOAoCBBESBr0DAMIDARoqIFJl
cXVlc3QgZm9yIHRoZSBgRGVsZXRlV2FpdGVyKClgIG1ldGhvZC4KCgsKAwQRARIEvQMIGwqE
AQoEBBECABIEwQMCEhp2IFRoZSBXYWl0ZXIgcmVzb3VyY2UgdG8gZGVsZXRlLCBpbiB0aGUg
Zm9ybWF0OgoKICBgcHJvamVjdHMvW1BST0pFQ1RfSURdL2NvbmZpZ3MvW0NPTkZJR19OQU1F
XS93YWl0ZXJzL1tXQUlURVJfTkFNRV1gCgoNCgUEEQIABRIEwQMCCAoNCgUEEQIAARIEwQMJ
DQoNCgUEEQIAAxIEwQMQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsRequest ===
    # Fields for ListConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsResponse ===
    # Fields for ListConfigsResponse
    # Field: configs Type: 11 (.google.cloud.runtimeconfig.v1beta1.RuntimeConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetConfigRequest ===
    # Fields for GetConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateConfigRequest ===
    # Fields for CreateConfigRequest
    # Field: parent Type: 9 ()
    # Field: config Type: 11 (.google.cloud.runtimeconfig.v1beta1.RuntimeConfig)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateConfigRequest ===
    # Fields for UpdateConfigRequest
    # Field: name Type: 9 ()
    # Field: config Type: 11 (.google.cloud.runtimeconfig.v1beta1.RuntimeConfig)

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteConfigRequest ===
    # Fields for DeleteConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesRequest ===
    # Fields for ListVariablesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: return_values Type: 8 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesResponse ===
    # Fields for ListVariablesResponse
    # Field: variables Type: 11 (.google.cloud.runtimeconfig.v1beta1.Variable)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::WatchVariableRequest ===
    # Fields for WatchVariableRequest
    # Field: name Type: 9 ()
    # Field: newer_than Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetVariableRequest ===
    # Fields for GetVariableRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateVariableRequest ===
    # Fields for CreateVariableRequest
    # Field: parent Type: 9 ()
    # Field: variable Type: 11 (.google.cloud.runtimeconfig.v1beta1.Variable)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateVariableRequest ===
    # Fields for UpdateVariableRequest
    # Field: name Type: 9 ()
    # Field: variable Type: 11 (.google.cloud.runtimeconfig.v1beta1.Variable)

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteVariableRequest ===
    # Fields for DeleteVariableRequest
    # Field: name Type: 9 ()
    # Field: recursive Type: 8 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersRequest ===
    # Fields for ListWaitersRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersResponse ===
    # Fields for ListWaitersResponse
    # Field: waiters Type: 11 (.google.cloud.runtimeconfig.v1beta1.Waiter)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetWaiterRequest ===
    # Fields for GetWaiterRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateWaiterRequest ===
    # Fields for CreateWaiterRequest
    # Field: parent Type: 9 ()
    # Field: waiter Type: 11 (.google.cloud.runtimeconfig.v1beta1.Waiter)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteWaiterRequest ===
    # Fields for DeleteWaiterRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::RuntimeConfigManagerClient ===
package Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::RuntimeConfigManagerClient;

=pod

=head2 Service Client: Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::RuntimeConfigManagerClient

Client stub representing the remote C<RuntimeConfigManager> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<runtimeconfig.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'runtimeconfig.googleapis.com:443' );

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

sub list_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'ListConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsResponse',
    });
}

sub get_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'GetConfig',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig',
    });
}

sub create_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'CreateConfig',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig',
    });
}

sub update_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'UpdateConfig',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig',
    });
}

sub delete_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'DeleteConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_variables {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'ListVariables',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesResponse',
    });
}

sub get_variable {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetVariableRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'GetVariable',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable',
    });
}

sub watch_variable {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::WatchVariableRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'WatchVariable',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable',
    });
}

sub create_variable {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateVariableRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'CreateVariable',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable',
    });
}

sub update_variable {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateVariableRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'UpdateVariable',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable',
    });
}

sub delete_variable {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteVariableRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'DeleteVariable',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_waiters {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'ListWaiters',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersResponse',
    });
}

sub get_waiter {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetWaiterRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'GetWaiter',
        request        => $req,
        response_class => 'Google::Cloud::Runtimeconfig::V1beta1::Resources::Waiter',
    });
}

sub create_waiter {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateWaiterRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'CreateWaiter',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_waiter {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteWaiterRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.runtimeconfig.v1beta1.RuntimeConfigManager',
        method         => 'DeleteWaiter',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig - Compiled Protocol Buffers messages for google/cloud/runtimeconfig/v1beta1/runtimeconfig.proto

=head1 SYNOPSIS

    use Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig;

    my $msg = Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/runtimeconfig/v1beta1/runtimeconfig.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsRequest

Request for the `ListConfigs()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The [project
ID](https://support.google.com/cloud/answer/6158840?hl=en&ref_topic=6158848)
for this request, in the format `projects/[PROJECT_ID]`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Specifies the number of results to return per page. If there are fewer
elements than the specified number, returns all elements.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Specifies a page token to use. Set `pageToken` to a `nextPageToken`
returned by a previous list request to get the next page of results.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsResponse

`ListConfigs()` returns the following response. The order of returned
objects is arbitrary; that is, it is not ordered in any particular way.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->configs() >> / C<< $msg->configs($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig>)

A list of the configurations in the project. The order of returned
objects is arbitrary; that is, it is not ordered in any particular way.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token allows you to get the next page of results for list requests.
If the number of results is larger than `pageSize`, use the `nextPageToken`
as a value for the query parameter `pageToken` in the next list request.
Subsequent list requests will have their own `nextPageToken` to continue
paging through the results

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetConfigRequest

Gets a RuntimeConfig resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the RuntimeConfig resource to retrieve, in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]`

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateConfigRequest

Creates a RuntimeConfig resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The [project
ID](https://support.google.com/cloud/answer/6158840?hl=en&ref_topic=6158848)
for this request, in the format `projects/[PROJECT_ID]`.

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig>)

The RuntimeConfig to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional but recommended unique `request_id`. If the server
receives two `create()` requests  with the same
`request_id`, then the second request will be ignored and the
first resource created and stored in the backend is returned.
Empty `request_id` fields are ignored.

It is responsibility of the client to ensure uniqueness of the
`request_id` strings.

`request_id` strings are limited to 64 characters.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateConfigRequest

Request message for `UpdateConfig()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the RuntimeConfig resource to update, in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]`

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::RuntimeConfig>)

The config resource to update.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteConfigRequest

Request for the `DeleteConfig()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The RuntimeConfig resource to delete, in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]`

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesRequest

Request for the `ListVariables()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The path to the RuntimeConfig resource for which you want to list
variables. The configuration must exist beforehand; the path must by in the
format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filters variables by matching the specified filter. For example:

`projects/example-project/config/[CONFIG_NAME]/variables/example-variable`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Specifies the number of results to return per page. If there are fewer
elements than the specified number, returns all elements.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Specifies a page token to use. Set `pageToken` to a `nextPageToken`
returned by a previous list request to get the next page of results.

=item * C<< $msg->return_values() >> / C<< $msg->return_values($value) >>

Type: C<Bool>

The flag indicates whether the user wants to return values of variables.
If true, then only those variables that user has IAM GetVariable permission
will be returned along with their values.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesResponse

Response for the `ListVariables()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->variables() >> / C<< $msg->variables($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable>)

A list of variables and their values. The order of returned variable
objects is arbitrary.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token allows you to get the next page of results for list requests.
If the number of results is larger than `pageSize`, use the `nextPageToken`
as a value for the query parameter `pageToken` in the next list request.
Subsequent list requests will have their own `nextPageToken` to continue
paging through the results

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::WatchVariableRequest

Request for the `WatchVariable()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the variable to watch, in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]`

=item * C<< $msg->newer_than() >> / C<< $msg->newer_than($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

If specified, checks the current timestamp of the variable and if the
current timestamp is newer than `newerThan` timestamp, the method returns
immediately.

If not specified or the variable has an older timestamp, the watcher waits
for a the value to change before returning.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetVariableRequest

Request for the `GetVariable()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the variable to return, in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]/variables/[VARIBLE_NAME]`

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateVariableRequest

Request for the `CreateVariable()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The path to the RutimeConfig resource that this variable should belong to.
The configuration must exist beforehand; the path must by in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]`

=item * C<< $msg->variable() >> / C<< $msg->variable($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable>)

The variable to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional but recommended unique `request_id`. If the server
receives two `create()` requests  with the same
`request_id`, then the second request will be ignored and the
first resource created and stored in the backend is returned.
Empty `request_id` fields are ignored.

It is responsibility of the client to ensure uniqueness of the
`request_id` strings.

`request_id` strings are limited to 64 characters.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateVariableRequest

Request for the `UpdateVariable()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the variable to update, in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]/variables/[VARIABLE_NAME]`

=item * C<< $msg->variable() >> / C<< $msg->variable($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::Variable>)

The variable to update.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteVariableRequest

Request for the `DeleteVariable()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the variable to delete, in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]/variables/[VARIABLE_NAME]`

=item * C<< $msg->recursive() >> / C<< $msg->recursive($value) >>

Type: C<Bool>

Set to `true` to recursively delete multiple variables with the same
prefix.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersRequest

Request for the `ListWaiters()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The path to the configuration for which you want to get a list of waiters.
The configuration must exist beforehand; the path must by in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Specifies the number of results to return per page. If there are fewer
elements than the specified number, returns all elements.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Specifies a page token to use. Set `pageToken` to a `nextPageToken`
returned by a previous list request to get the next page of results.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersResponse

Response for the `ListWaiters()` method.
Order of returned waiter objects is arbitrary.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->waiters() >> / C<< $msg->waiters($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::Waiter>)

Found waiters in the project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token allows you to get the next page of results for list requests.
If the number of results is larger than `pageSize`, use the `nextPageToken`
as a value for the query parameter `pageToken` in the next list request.
Subsequent list requests will have their own `nextPageToken` to continue
paging through the results

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetWaiterRequest

Request for the `GetWaiter()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fully-qualified name of the Waiter resource object to retrieve, in the
format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]/waiters/[WAITER_NAME]`

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateWaiterRequest

Request message for `CreateWaiter()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The path to the configuration that will own the waiter.
The configuration must exist beforehand; the path must by in the format:

`projects/[PROJECT_ID]/configs/[CONFIG_NAME]`.

=item * C<< $msg->waiter() >> / C<< $msg->waiter($value) >>

Type: C<Message> (L<Google::Cloud::Runtimeconfig::V1beta1::Resources::Waiter>)

The Waiter resource to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

An optional but recommended unique `request_id`. If the server
receives two `create()` requests  with the same
`request_id`, then the second request will be ignored and the
first resource created and stored in the backend is returned.
Empty `request_id` fields are ignored.

It is responsibility of the client to ensure uniqueness of the
`request_id` strings.

`request_id` strings are limited to 64 characters.

=back

=head2 Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteWaiterRequest

Request for the `DeleteWaiter()` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The Waiter resource to delete, in the format:

 `projects/[PROJECT_ID]/configs/[CONFIG_NAME]/waiters/[WAITER_NAME]`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
