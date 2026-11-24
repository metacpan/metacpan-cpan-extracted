package Google::Cloud::Datalabeling::V1beta1::EvaluationJob;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Datalabeling::V1beta1::Dataset };
    eval { require Google::Cloud::Datalabeling::V1beta1::Evaluation };
    eval { require Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvZXZhbHVhdGlvbl9qb2IucHJv
dG8SIWdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMRoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxovZ29vZ2xlL2Nsb3VkL2RhdGFsYWJlbGluZy92MWJldGExL2RhdGFzZXQu
cHJvdG8aMmdvb2dsZS9jbG91ZC9kYXRhbGFiZWxpbmcvdjFiZXRhMS9ldmFsdWF0aW9uLnBy
b3RvGj9nb29nbGUvY2xvdWQvZGF0YWxhYmVsaW5nL3YxYmV0YTEvaHVtYW5fYW5ub3RhdGlv
bl9jb25maWcucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dvb2ds
ZS9ycGMvc3RhdHVzLnByb3RvIusFCg1FdmFsdWF0aW9uSm9iEhIKBG5hbWUYASABKAlSBG5h
bWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEkwKBXN0YXRlGAMgASgOMjYu
Z29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkV2YWx1YXRpb25Kb2IuU3RhdGVS
BXN0YXRlEhoKCHNjaGVkdWxlGAQgASgJUghzY2hlZHVsZRIjCg1tb2RlbF92ZXJzaW9uGAUg
ASgJUgxtb2RlbFZlcnNpb24SagoVZXZhbHVhdGlvbl9qb2JfY29uZmlnGAYgASgLMjYuZ29v
Z2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkV2YWx1YXRpb25Kb2JDb25maWdSE2V2
YWx1YXRpb25Kb2JDb25maWcSLgoTYW5ub3RhdGlvbl9zcGVjX3NldBgHIAEoCVIRYW5ub3Rh
dGlvblNwZWNTZXQSOwoabGFiZWxfbWlzc2luZ19ncm91bmRfdHJ1dGgYCCABKAhSF2xhYmVs
TWlzc2luZ0dyb3VuZFRydXRoEkYKCGF0dGVtcHRzGAkgAygLMiouZ29vZ2xlLmNsb3VkLmRh
dGFsYWJlbGluZy52MWJldGExLkF0dGVtcHRSCGF0dGVtcHRzEjsKC2NyZWF0ZV90aW1lGAog
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZSJTCgVTdGF0ZRIV
ChFTVEFURV9VTlNQRUNJRklFRBAAEg0KCVNDSEVEVUxFRBABEgsKB1JVTk5JTkcQAhIKCgZQ
QVVTRUQQAxILCgdTVE9QUEVEEAQ6YupBXwopZGF0YWxhYmVsaW5nLmdvb2dsZWFwaXMuY29t
L0V2YWx1YXRpb25Kb2ISMnByb2plY3RzL3twcm9qZWN0fS9ldmFsdWF0aW9uSm9icy97ZXZh
bHVhdGlvbl9qb2J9Iu4IChNFdmFsdWF0aW9uSm9iQ29uZmlnEn4KG2ltYWdlX2NsYXNzaWZp
Y2F0aW9uX2NvbmZpZxgEIAEoCzI8Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRh
MS5JbWFnZUNsYXNzaWZpY2F0aW9uQ29uZmlnSABSGWltYWdlQ2xhc3NpZmljYXRpb25Db25m
aWcSaQoUYm91bmRpbmdfcG9seV9jb25maWcYBSABKAsyNS5nb29nbGUuY2xvdWQuZGF0YWxh
YmVsaW5nLnYxYmV0YTEuQm91bmRpbmdQb2x5Q29uZmlnSABSEmJvdW5kaW5nUG9seUNvbmZp
ZxJ7Chp0ZXh0X2NsYXNzaWZpY2F0aW9uX2NvbmZpZxgIIAEoCzI7Lmdvb2dsZS5jbG91ZC5k
YXRhbGFiZWxpbmcudjFiZXRhMS5UZXh0Q2xhc3NpZmljYXRpb25Db25maWdIAFIYdGV4dENs
YXNzaWZpY2F0aW9uQ29uZmlnElEKDGlucHV0X2NvbmZpZxgBIAEoCzIuLmdvb2dsZS5jbG91
ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5JbnB1dENvbmZpZ1ILaW5wdXRDb25maWcSYAoRZXZh
bHVhdGlvbl9jb25maWcYAiABKAsyMy5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuRXZhbHVhdGlvbkNvbmZpZ1IQZXZhbHVhdGlvbkNvbmZpZxJwChdodW1hbl9hbm5vdGF0
aW9uX2NvbmZpZxgDIAEoCzI4Lmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5I
dW1hbkFubm90YXRpb25Db25maWdSFWh1bWFuQW5ub3RhdGlvbkNvbmZpZxKAAQoUYmlncXVl
cnlfaW1wb3J0X2tleXMYCSADKAsyTi5nb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuRXZhbHVhdGlvbkpvYkNvbmZpZy5CaWdxdWVyeUltcG9ydEtleXNFbnRyeVISYmlncXVl
cnlJbXBvcnRLZXlzEiMKDWV4YW1wbGVfY291bnQYCiABKAVSDGV4YW1wbGVDb3VudBI6Chll
eGFtcGxlX3NhbXBsZV9wZXJjZW50YWdlGAsgASgBUhdleGFtcGxlU2FtcGxlUGVyY2VudGFn
ZRJ6ChtldmFsdWF0aW9uX2pvYl9hbGVydF9jb25maWcYDSABKAsyOy5nb29nbGUuY2xvdWQu
ZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVhdGlvbkpvYkFsZXJ0Q29uZmlnUhhldmFsdWF0
aW9uSm9iQWxlcnRDb25maWcaRQoXQmlncXVlcnlJbXBvcnRLZXlzRW50cnkSEAoDa2V5GAEg
ASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AUIhCh9odW1hbl9hbm5vdGF0aW9u
X3JlcXVlc3RfY29uZmlnIoIBChhFdmFsdWF0aW9uSm9iQWxlcnRDb25maWcSFAoFZW1haWwY
ASABKAlSBWVtYWlsElAKJW1pbl9hY2NlcHRhYmxlX21lYW5fYXZlcmFnZV9wcmVjaXNpb24Y
AiABKAFSIW1pbkFjY2VwdGFibGVNZWFuQXZlcmFnZVByZWNpc2lvbiKHAQoHQXR0ZW1wdBI9
CgxhdHRlbXB0X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgthdHRl
bXB0VGltZRI9ChBwYXJ0aWFsX2ZhaWx1cmVzGAIgAygLMhIuZ29vZ2xlLnJwYy5TdGF0dXNS
D3BhcnRpYWxGYWlsdXJlc0LjAQolY29tLmdvb2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFi
ZXRhMVABWkljbG91ZC5nb29nbGUuY29tL2dvL2RhdGFsYWJlbGluZy9hcGl2MWJldGExL2Rh
dGFsYWJlbGluZ3BiO2RhdGFsYWJlbGluZ3BiqgIhR29vZ2xlLkNsb3VkLkRhdGFMYWJlbGlu
Zy5WMUJldGExygIhR29vZ2xlXENsb3VkXERhdGFMYWJlbGluZ1xWMWJldGEx6gIkR29vZ2xl
OjpDbG91ZDo6RGF0YUxhYmVsaW5nOjpWMWJldGExSotkCgcSBQ8AkQIBCr0ECgEMEgMPABIy
sgQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCggKAQISAxEAKgoJCgIDABIDEwAjCgkKAgMBEgMU
ADkKCQoCAwISAxUAPAoJCgIDAxIDFgBJCgkKAgMEEgMXACkKCQoCAwUSAxgAIQoICgEIEgMa
AD4KCQoCCCUSAxoAPgoICgEIEgMbAGAKCQoCCAsSAxsAYAoICgEIEgMcACIKCQoCCAoSAxwA
IgoICgEIEgMdAD4KCQoCCAESAx0APgoICgEIEgMeAD4KCQoCCCkSAx4APgoICgEIEgMfAD0K
CQoCCC0SAx8APQqSAgoCBAASBSUAmAEBGoQCIERlZmluZXMgYW4gZXZhbHVhdGlvbiBqb2Ig
dGhhdCBydW5zIHBlcmlvZGljYWxseSB0byBnZW5lcmF0ZQogW0V2YWx1YXRpb25zXVtnb29n
bGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVhdGlvbl0uIFtDcmVhdGluZyBh
biBldmFsdWF0aW9uCiBqb2JdKC9tbC1lbmdpbmUvZG9jcy9jb250aW51b3VzLWV2YWx1YXRp
b24vY3JlYXRlLWpvYikgaXMgdGhlIHN0YXJ0aW5nIHBvaW50CiBmb3IgdXNpbmcgY29udGlu
dW91cyBldmFsdWF0aW9uLgoKCgoDBAABEgMlCBUKCwoDBAAHEgQmAikECg0KBQQAB50IEgQm
AikECiEKBAQABAASBCwCWgMaEyBTdGF0ZSBvZiB0aGUgam9iLgoKDAoFBAAEAAESAywHDAoN
CgYEAAQAAgASAy0EGgoOCgcEAAQAAgABEgMtBBUKDgoHBAAEAAIAAhIDLRgZCtEDCgYEAAQA
AgESAzUEEhrBAyBUaGUgam9iIGlzIHNjaGVkdWxlZCB0byBydW4gYXQgdGhlIFtjb25maWd1
cmVkIGludGVydmFsXVtnb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVh
dGlvbkpvYi5zY2hlZHVsZV0uIFlvdQogY2FuIFtwYXVzZV1bZ29vZ2xlLmNsb3VkLmRhdGFs
YWJlbGluZy52MWJldGExLkRhdGFMYWJlbGluZ1NlcnZpY2UuUGF1c2VFdmFsdWF0aW9uSm9i
XSBvcgogW2RlbGV0ZV1bZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkRhdGFM
YWJlbGluZ1NlcnZpY2UuRGVsZXRlRXZhbHVhdGlvbkpvYl0gdGhlIGpvYi4KCiBXaGVuIHRo
ZSBqb2IgaXMgaW4gdGhpcyBzdGF0ZSwgaXQgc2FtcGxlcyBwcmVkaWN0aW9uIGlucHV0IGFu
ZCBvdXRwdXQKIGZyb20geW91ciBtb2RlbCB2ZXJzaW9uIGludG8geW91ciBCaWdRdWVyeSB0
YWJsZSBhcyBwcmVkaWN0aW9ucyBvY2N1ci4KCg4KBwQABAACAQESAzUEDQoOCgcEAAQAAgEC
EgM1EBEKnwwKBgQABAACAhIDUQQQGo8MIFRoZSBqb2IgaXMgY3VycmVudGx5IHJ1bm5pbmcu
IFdoZW4gdGhlIGpvYiBydW5zLCBEYXRhIExhYmVsaW5nIFNlcnZpY2UKIGRvZXMgc2V2ZXJh
bCB0aGluZ3M6CgogMS4gSWYgeW91IGhhdmUgY29uZmlndXJlZCB5b3VyIGpvYiB0byB1c2Ug
RGF0YSBMYWJlbGluZyBTZXJ2aWNlIGZvcgogICAgZ3JvdW5kIHRydXRoIGxhYmVsaW5nLCB0
aGUgc2VydmljZSBjcmVhdGVzIGEKICAgIFtEYXRhc2V0XVtnb29nbGUuY2xvdWQuZGF0YWxh
YmVsaW5nLnYxYmV0YTEuRGF0YXNldF0gYW5kIGEgbGFiZWxpbmcgdGFzayBmb3IgYWxsIGRh
dGEgc2FtcGxlZAogICAgc2luY2UgdGhlIGxhc3QgdGltZSB0aGUgam9iIHJhbi4gSHVtYW4g
bGFiZWxlcnMgcHJvdmlkZSBncm91bmQgdHJ1dGgKICAgIGxhYmVscyBmb3IgeW91ciBkYXRh
LiBIdW1hbiBsYWJlbGluZyBtYXkgdGFrZSBob3Vycywgb3IgZXZlbiBkYXlzLAogICAgZGVw
ZW5kaW5nIG9uIGhvdyBtdWNoIGRhdGEgaGFzIGJlZW4gc2FtcGxlZC4gVGhlIGpvYiByZW1h
aW5zIGluIHRoZQogICAgYFJVTk5JTkdgIHN0YXRlIGR1cmluZyB0aGlzIHRpbWUsIGFuZCBp
dCBjYW4gZXZlbiBiZSBydW5uaW5nIG11bHRpcGxlCiAgICB0aW1lcyBpbiBwYXJhbGxlbCBp
ZiBpdCBnZXRzIHRyaWdnZXJlZCBhZ2FpbiAoZm9yIGV4YW1wbGUgMjQgaG91cnMKICAgIGxh
dGVyKSBiZWZvcmUgdGhlIGVhcmxpZXIgcnVuIGhhcyBjb21wbGV0ZWQuIFdoZW4gaHVtYW4g
bGFiZWxlcnMgaGF2ZQogICAgZmluaXNoZWQgbGFiZWxpbmcgdGhlIGRhdGEsIHRoZSBuZXh0
IHN0ZXAgb2NjdXJzLgogICAgPGJyPjxicj4KICAgIElmIHlvdSBoYXZlIGNvbmZpZ3VyZWQg
eW91ciBqb2IgdG8gcHJvdmlkZSB5b3VyIG93biBncm91bmQgdHJ1dGgKICAgIGxhYmVscywg
RGF0YSBMYWJlbGluZyBTZXJ2aWNlIHN0aWxsIGNyZWF0ZXMgYSBbRGF0YXNldF1bZ29vZ2xl
LmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLkRhdGFzZXRdIGZvciBuZXdseQogICAgc2Ft
cGxlZCBkYXRhLCBidXQgaXQgZXhwZWN0cyB0aGF0IHlvdSBoYXZlIGFscmVhZHkgYWRkZWQg
Z3JvdW5kIHRydXRoCiAgICBsYWJlbHMgdG8gdGhlIEJpZ1F1ZXJ5IHRhYmxlIGJ5IHRoaXMg
dGltZS4gVGhlIG5leHQgc3RlcCBvY2N1cnMKICAgIGltbWVkaWF0ZWx5LgoKIDIuIERhdGEg
TGFiZWxpbmcgU2VydmljZSBjcmVhdGVzIGFuIFtFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQu
ZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVhdGlvbl0gYnkgY29tcGFyaW5nIHlvdXIKICAg
IG1vZGVsIHZlcnNpb24ncyBwcmVkaWN0aW9ucyB3aXRoIHRoZSBncm91bmQgdHJ1dGggbGFi
ZWxzLgoKIElmIHRoZSBqb2IgcmVtYWlucyBpbiB0aGlzIHN0YXRlIGZvciBhIGxvbmcgdGlt
ZSwgaXQgY29udGludWVzIHRvIHNhbXBsZQogcHJlZGljdGlvbiBkYXRhIGludG8geW91ciBC
aWdRdWVyeSB0YWJsZSBhbmQgd2lsbCBydW4gYWdhaW4gYXQgdGhlIG5leHQKIGludGVydmFs
LCBldmVuIGlmIGl0IGNhdXNlcyB0aGUgam9iIHRvIHJ1biBtdWx0aXBsZSB0aW1lcyBpbiBw
YXJhbGxlbC4KCg4KBwQABAACAgESA1EECwoOCgcEAAQAAgICEgNRDg8K9AEKBgQABAACAxID
VgQPGuQBIFRoZSBqb2IgaXMgbm90IHNhbXBsaW5nIHByZWRpY3Rpb24gaW5wdXQgYW5kIG91
dHB1dCBpbnRvIHlvdXIgQmlnUXVlcnkKIHRhYmxlIGFuZCBpdCB3aWxsIG5vdCBydW4gYWNj
b3JkaW5nIHRvIGl0cyBzY2hlZHVsZS4gWW91IGNhbgogW3Jlc3VtZV1bZ29vZ2xlLmNsb3Vk
LmRhdGFsYWJlbGluZy52MWJldGExLkRhdGFMYWJlbGluZ1NlcnZpY2UuUmVzdW1lRXZhbHVh
dGlvbkpvYl0gdGhlIGpvYi4KCg4KBwQABAACAwESA1YECgoOCgcEAAQAAgMCEgNWDQ4KQwoG
BAAEAAIEEgNZBBAaNCBUaGUgam9iIGhhcyB0aGlzIHN0YXRlIHJpZ2h0IGJlZm9yZSBpdCBp
cyBkZWxldGVkLgoKDgoHBAAEAAIEARIDWQQLCg4KBwQABAACBAISA1kODwrTAQoEBAACABID
YAISGsUBIE91dHB1dCBvbmx5LiBBZnRlciB5b3UgY3JlYXRlIGEgam9iLCBEYXRhIExhYmVs
aW5nIFNlcnZpY2UgYXNzaWducyBhIG5hbWUKIHRvIHRoZSBqb2Igd2l0aCB0aGUgZm9sbG93
aW5nIGZvcm1hdDoKCiAicHJvamVjdHMvPHZhcj57cHJvamVjdF9pZH08L3Zhcj4vZXZhbHVh
dGlvbkpvYnMvPHZhcj57ZXZhbHVhdGlvbl9qb2JfaWR9PC92YXI+IgoKDAoFBAACAAUSA2AC
CAoMCgUEAAIAARIDYAkNCgwKBQQAAgADEgNgEBEKZgoEBAACARIDZAIZGlkgUmVxdWlyZWQu
IERlc2NyaXB0aW9uIG9mIHRoZSBqb2IuIFRoZSBkZXNjcmlwdGlvbiBjYW4gYmUgdXAgdG8g
MjUsMDAwCiBjaGFyYWN0ZXJzIGxvbmcuCgoMCgUEAAIBBRIDZAIICgwKBQQAAgEBEgNkCRQK
DAoFBAACAQMSA2QXGApDCgQEAAICEgNnAhIaNiBPdXRwdXQgb25seS4gRGVzY3JpYmVzIHRo
ZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBqb2IuCgoMCgUEAAICBhIDZwIHCgwKBQQAAgIBEgNn
CA0KDAoFBAACAgMSA2cQEQq3BAoEBAACAxIDdAIWGqkEIFJlcXVpcmVkLiBEZXNjcmliZXMg
dGhlIGludGVydmFsIGF0IHdoaWNoIHRoZSBqb2IgcnVucy4gVGhpcyBpbnRlcnZhbCBtdXN0
CiBiZSBhdCBsZWFzdCAxIGRheSwgYW5kIGl0IGlzIHJvdW5kZWQgdG8gdGhlIG5lYXJlc3Qg
ZGF5LiBGb3IgZXhhbXBsZSwgaWYKIHlvdSBzcGVjaWZ5IGEgNTAtaG91ciBpbnRlcnZhbCwg
dGhlIGpvYiBydW5zIGV2ZXJ5IDIgZGF5cy4KCiBZb3UgY2FuIHByb3ZpZGUgdGhlIHNjaGVk
dWxlIGluCiBbY3JvbnRhYiBmb3JtYXRdKC9zY2hlZHVsZXIvZG9jcy9jb25maWd1cmluZy9j
cm9uLWpvYi1zY2hlZHVsZXMpIG9yIGluIGFuCiBbRW5nbGlzaC1saWtlCiBmb3JtYXRdKC9h
cHBlbmdpbmUvZG9jcy9zdGFuZGFyZC9weXRob24vY29uZmlnL2Nyb25yZWYjc2NoZWR1bGVf
Zm9ybWF0KS4KCiBSZWdhcmRsZXNzIG9mIHdoYXQgeW91IHNwZWNpZnksIHRoZSBqb2Igd2ls
bCBydW4gYXQgMTA6MDAgQU0gVVRDLiBPbmx5IHRoZQogaW50ZXJ2YWwgZnJvbSB0aGlzIHNj
aGVkdWxlIGlzIHVzZWQsIG5vdCB0aGUgc3BlY2lmaWMgdGltZSBvZiBkYXkuCgoMCgUEAAID
BRIDdAIICgwKBQQAAgMBEgN0CREKDAoFBAACAwMSA3QUFQqyAwoEBAACBBIDfgIbGqQDIFJl
cXVpcmVkLiBUaGUgW0FJIFBsYXRmb3JtIFByZWRpY3Rpb24gbW9kZWwKIHZlcnNpb25dKC9t
bC1lbmdpbmUvZG9jcy9wcmVkaWN0aW9uLW92ZXJ2aWV3KSB0byBiZSBldmFsdWF0ZWQuIFBy
ZWRpY3Rpb24KIGlucHV0IGFuZCBvdXRwdXQgaXMgc2FtcGxlZCBmcm9tIHRoaXMgbW9kZWwg
dmVyc2lvbi4gV2hlbiBjcmVhdGluZyBhbgogZXZhbHVhdGlvbiBqb2IsIHNwZWNpZnkgdGhl
IG1vZGVsIHZlcnNpb24gaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CgogInByb2plY3RzLzx2
YXI+e3Byb2plY3RfaWR9PC92YXI+L21vZGVscy88dmFyPnttb2RlbF9uYW1lfTwvdmFyPi92
ZXJzaW9ucy88dmFyPnt2ZXJzaW9uX25hbWV9PC92YXI+IgoKIFRoZXJlIGNhbiBvbmx5IGJl
IG9uZSBldmFsdWF0aW9uIGpvYiBwZXIgbW9kZWwgdmVyc2lvbi4KCgwKBQQAAgQFEgN+AggK
DAoFBAACBAESA34JFgoMCgUEAAIEAxIDfhkaCkcKBAQAAgUSBIEBAjAaOSBSZXF1aXJlZC4g
Q29uZmlndXJhdGlvbiBkZXRhaWxzIGZvciB0aGUgZXZhbHVhdGlvbiBqb2IuCgoNCgUEAAIF
BhIEgQECFQoNCgUEAAIFARIEgQEWKwoNCgUEAAIFAxIEgQEuLwqCAwoEBAACBhIEiQECIRrz
AiBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgW0Fubm90YXRpb25TcGVjU2V0XVtnb29nbGUuY2xv
dWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuQW5ub3RhdGlvblNwZWNTZXRdIGRlc2NyaWJpbmcg
YWxsIHRoZQogbGFiZWxzIHRoYXQgeW91ciBtYWNoaW5lIGxlYXJuaW5nIG1vZGVsIG91dHB1
dHMuIFlvdSBtdXN0IGNyZWF0ZSB0aGlzCiByZXNvdXJjZSBiZWZvcmUgeW91IGNyZWF0ZSBh
biBldmFsdWF0aW9uIGpvYiBhbmQgcHJvdmlkZSBpdHMgbmFtZSBpbiB0aGUKIGZvbGxvd2lu
ZyBmb3JtYXQ6CgogInByb2plY3RzLzx2YXI+e3Byb2plY3RfaWR9PC92YXI+L2Fubm90YXRp
b25TcGVjU2V0cy88dmFyPnthbm5vdGF0aW9uX3NwZWNfc2V0X2lkfTwvdmFyPiIKCg0KBQQA
AgYFEgSJAQIICg0KBQQAAgYBEgSJAQkcCg0KBQQAAgYDEgSJAR8gCscCCgQEAAIHEgSQAQIm
GrgCIFJlcXVpcmVkLiBXaGV0aGVyIHlvdSB3YW50IERhdGEgTGFiZWxpbmcgU2VydmljZSB0
byBwcm92aWRlIGdyb3VuZCB0cnV0aAogbGFiZWxzIGZvciBwcmVkaWN0aW9uIGlucHV0LiBJ
ZiB5b3Ugd2FudCB0aGUgc2VydmljZSB0byBhc3NpZ24gaHVtYW4KIGxhYmVsZXJzIHRvIGFu
bm90YXRlIHlvdXIgZGF0YSwgc2V0IHRoaXMgdG8gYHRydWVgLiBJZiB5b3Ugd2FudCB0byBw
cm92aWRlCiB5b3VyIG93biBncm91bmQgdHJ1dGggbGFiZWxzIGluIHRoZSBldmFsdWF0aW9u
IGpvYidzIEJpZ1F1ZXJ5IHRhYmxlLCBzZXQKIHRoaXMgdG8gYGZhbHNlYC4KCg0KBQQAAgcF
EgSQAQIGCg0KBQQAAgcBEgSQAQchCg0KBQQAAgcDEgSQASQlCoMBCgQEAAIIEgSUAQIgGnUg
T3V0cHV0IG9ubHkuIEV2ZXJ5IHRpbWUgdGhlIGV2YWx1YXRpb24gam9iIHJ1bnMgYW5kIGFu
IGVycm9yIG9jY3VycywgdGhlCiBmYWlsZWQgYXR0ZW1wdCBpcyBhcHBlbmRlZCB0byB0aGlz
IGFycmF5LgoKDQoFBAACCAQSBJQBAgoKDQoFBAACCAYSBJQBCxIKDQoFBAACCAESBJQBExsK
DQoFBAACCAMSBJQBHh8KTwoEBAACCRIElwECLRpBIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAg
b2Ygd2hlbiB0aGlzIGV2YWx1YXRpb24gam9iIHdhcyBjcmVhdGVkLgoKDQoFBAACCQYSBJcB
AhsKDQoFBAACCQESBJcBHCcKDQoFBAACCQMSBJcBKiwKlAEKAgQBEgacAQD7AQEahQEgQ29u
ZmlndXJlcyBzcGVjaWZpYyBkZXRhaWxzIG9mIGhvdyBhIGNvbnRpbnVvdXMgZXZhbHVhdGlv
biBqb2Igd29ya3MuIFByb3ZpZGUKIHRoaXMgY29uZmlndXJhdGlvbiB3aGVuIHlvdSBjcmVh
dGUgYW4gRXZhbHVhdGlvbkpvYi4KCgsKAwQBARIEnAEIGwplCgQEAQgAEgafAQK3AQMaVSBS
ZXF1aXJlZC4gRGV0YWlscyBmb3IgaG93IHlvdSB3YW50IGh1bWFuIHJldmlld2VycyB0byBw
cm92aWRlIGdyb3VuZCB0cnV0aAogbGFiZWxzLgoKDQoFBAEIAAESBJ8BCCcKxQMKBAQBAgAS
BKcBBD4atgMgU3BlY2lmeSB0aGlzIGZpZWxkIGlmIHlvdXIgbW9kZWwgdmVyc2lvbiBwZXJm
b3JtcyBpbWFnZSBjbGFzc2lmaWNhdGlvbiBvcgogZ2VuZXJhbCBjbGFzc2lmaWNhdGlvbi4K
CiBgYW5ub3RhdGlvblNwZWNTZXRgIGluIHRoaXMgY29uZmlndXJhdGlvbiBtdXN0IG1hdGNo
CiBbRXZhbHVhdGlvbkpvYi5hbm5vdGF0aW9uU3BlY1NldF1bZ29vZ2xlLmNsb3VkLmRhdGFs
YWJlbGluZy52MWJldGExLkV2YWx1YXRpb25Kb2IuYW5ub3RhdGlvbl9zcGVjX3NldF0uCiBg
YWxsb3dNdWx0aUxhYmVsYCBpbiB0aGlzIGNvbmZpZ3VyYXRpb24gbXVzdCBtYXRjaAogYGNs
YXNzaWZpY2F0aW9uTWV0YWRhdGEuaXNNdWx0aUxhYmVsYCBpbiBbaW5wdXRfY29uZmlnXVtn
b29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVhdGlvbkpvYkNvbmZpZy5p
bnB1dF9jb25maWddLgoKDQoFBAECAAYSBKcBBB0KDQoFBAECAAESBKcBHjkKDQoFBAECAAMS
BKcBPD0KlAIKBAQBAgESBK4BBDAahQIgU3BlY2lmeSB0aGlzIGZpZWxkIGlmIHlvdXIgbW9k
ZWwgdmVyc2lvbiBwZXJmb3JtcyBpbWFnZSBvYmplY3QgZGV0ZWN0aW9uCiAoYm91bmRpbmcg
Ym94IGRldGVjdGlvbikuCgogYGFubm90YXRpb25TcGVjU2V0YCBpbiB0aGlzIGNvbmZpZ3Vy
YXRpb24gbXVzdCBtYXRjaAogW0V2YWx1YXRpb25Kb2IuYW5ub3RhdGlvblNwZWNTZXRdW2dv
b2dsZS5jbG91ZC5kYXRhbGFiZWxpbmcudjFiZXRhMS5FdmFsdWF0aW9uSm9iLmFubm90YXRp
b25fc3BlY19zZXRdLgoKDQoFBAECAQYSBK4BBBYKDQoFBAECAQESBK4BFysKDQoFBAECAQMS
BK4BLi8KqQMKBAQBAgISBLYBBDwamgMgU3BlY2lmeSB0aGlzIGZpZWxkIGlmIHlvdXIgbW9k
ZWwgdmVyc2lvbiBwZXJmb3JtcyB0ZXh0IGNsYXNzaWZpY2F0aW9uLgoKIGBhbm5vdGF0aW9u
U3BlY1NldGAgaW4gdGhpcyBjb25maWd1cmF0aW9uIG11c3QgbWF0Y2gKIFtFdmFsdWF0aW9u
Sm9iLmFubm90YXRpb25TcGVjU2V0XVtnb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0
YTEuRXZhbHVhdGlvbkpvYi5hbm5vdGF0aW9uX3NwZWNfc2V0XS4KIGBhbGxvd011bHRpTGFi
ZWxgIGluIHRoaXMgY29uZmlndXJhdGlvbiBtdXN0IG1hdGNoCiBgY2xhc3NpZmljYXRpb25N
ZXRhZGF0YS5pc011bHRpTGFiZWxgIGluIFtpbnB1dF9jb25maWddW2dvb2dsZS5jbG91ZC5k
YXRhbGFiZWxpbmcudjFiZXRhMS5FdmFsdWF0aW9uSm9iQ29uZmlnLmlucHV0X2NvbmZpZ10u
CgoNCgUEAQICBhIEtgEEHAoNCgUEAQICARIEtgEdNwoNCgUEAQICAxIEtgE6OwrKBAoEBAEC
AxIEwwECHxq7BCBScXVpcmVkLiBEZXRhaWxzIGZvciB0aGUgc2FtcGxlZCBwcmVkaWN0aW9u
IGlucHV0LiBXaXRoaW4gdGhpcwogY29uZmlndXJhdGlvbiwgdGhlcmUgYXJlIHJlcXVpcmVt
ZW50cyBmb3Igc2V2ZXJhbCBmaWVsZHM6CgogKiBgZGF0YVR5cGVgIG11c3QgYmUgb25lIG9m
IGBJTUFHRWAsIGBURVhUYCwgb3IgYEdFTkVSQUxfREFUQWAuCiAqIGBhbm5vdGF0aW9uVHlw
ZWAgbXVzdCBiZSBvbmUgb2YgYElNQUdFX0NMQVNTSUZJQ0FUSU9OX0FOTk9UQVRJT05gLAog
ICBgVEVYVF9DTEFTU0lGSUNBVElPTl9BTk5PVEFUSU9OYCwgYEdFTkVSQUxfQ0xBU1NJRklD
QVRJT05fQU5OT1RBVElPTmAsCiAgIG9yIGBJTUFHRV9CT1VORElOR19CT1hfQU5OT1RBVElP
TmAgKGltYWdlIG9iamVjdCBkZXRlY3Rpb24pLgogKiBJZiB5b3VyIG1hY2hpbmUgbGVhcm5p
bmcgbW9kZWwgcGVyZm9ybXMgY2xhc3NpZmljYXRpb24sIHlvdSBtdXN0IHNwZWNpZnkKICAg
YGNsYXNzaWZpY2F0aW9uTWV0YWRhdGEuaXNNdWx0aUxhYmVsYC4KICogWW91IG11c3Qgc3Bl
Y2lmeSBgYmlncXVlcnlTb3VyY2VgIChub3QgYGdjc1NvdXJjZWApLgoKDQoFBAECAwYSBMMB
Ag0KDQoFBAECAwESBMMBDhoKDQoFBAECAwMSBMMBHR4K2gIKBAQBAgQSBMoBAikaywIgUmVx
dWlyZWQuIERldGFpbHMgZm9yIGNhbGN1bGF0aW5nIGV2YWx1YXRpb24gbWV0cmljcyBhbmQg
Y3JlYXRpbmcKIFtFdmF1bGF0aW9uc11bZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJl
dGExLkV2YWx1YXRpb25dLiBJZiB5b3VyIG1vZGVsIHZlcnNpb24gcGVyZm9ybXMgaW1hZ2Ug
b2JqZWN0CiBkZXRlY3Rpb24sIHlvdSBtdXN0IHNwZWNpZnkgdGhlIGBib3VuZGluZ0JveEV2
YWx1YXRpb25PcHRpb25zYCBmaWVsZCB3aXRoaW4KIHRoaXMgY29uZmlndXJhdGlvbi4gT3Ro
ZXJ3aXNlLCBwcm92aWRlIGFuIGVtcHR5IG9iamVjdCBmb3IgdGhpcwogY29uZmlndXJhdGlv
bi4KCg0KBQQBAgQGEgTKAQISCg0KBQQBAgQBEgTKARMkCg0KBQQBAgQDEgTKAScoCrYECgQE
AQIFEgTUAQI0GqcEIE9wdGlvbmFsLiBEZXRhaWxzIGZvciBodW1hbiBhbm5vdGF0aW9uIG9m
IHlvdXIgZGF0YS4gSWYgeW91IHNldAogW2xhYmVsTWlzc2luZ0dyb3VuZFRydXRoXVtnb29n
bGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVhdGlvbkpvYi5sYWJlbF9taXNz
aW5nX2dyb3VuZF90cnV0aF0gdG8KIGB0cnVlYCBmb3IgdGhpcyBldmFsdWF0aW9uIGpvYiwg
dGhlbiB5b3UgbXVzdCBzcGVjaWZ5IHRoaXMgZmllbGQuIElmIHlvdQogcGxhbiB0byBwcm92
aWRlIHlvdXIgb3duIGdyb3VuZCB0cnV0aCBsYWJlbHMsIHRoZW4gb21pdCB0aGlzIGZpZWxk
LgoKIE5vdGUgdGhhdCB5b3UgbXVzdCBjcmVhdGUgYW4gW0luc3RydWN0aW9uXVtnb29nbGUu
Y2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuSW5zdHJ1Y3Rpb25dIHJlc291cmNlIGJlZm9y
ZSB5b3UgY2FuCiBzcGVjaWZ5IHRoaXMgZmllbGQuIFByb3ZpZGUgdGhlIG5hbWUgb2YgdGhl
IGluc3RydWN0aW9uIHJlc291cmNlIGluIHRoZQogYGluc3RydWN0aW9uYCBmaWVsZCB3aXRo
aW4gdGhpcyBjb25maWd1cmF0aW9uLgoKDQoFBAECBQYSBNQBAhcKDQoFBAECBQESBNQBGC8K
DQoFBAECBQMSBNQBMjMKnQgKBAQBAgYSBOkBAi8ajgggUmVxdWlyZWQuIFByZWRpY3Rpb24g
a2V5cyB0aGF0IHRlbGwgRGF0YSBMYWJlbGluZyBTZXJ2aWNlIHdoZXJlIHRvIGZpbmQgdGhl
CiBkYXRhIGZvciBldmFsdWF0aW9uIGluIHlvdXIgQmlnUXVlcnkgdGFibGUuIFdoZW4gdGhl
IHNlcnZpY2Ugc2FtcGxlcwogcHJlZGljdGlvbiBpbnB1dCBhbmQgb3V0cHV0IGZyb20geW91
ciBtb2RlbCB2ZXJzaW9uIGFuZCBzYXZlcyBpdCB0bwogQmlnUXVlcnksIHRoZSBkYXRhIGdl
dHMgc3RvcmVkIGFzIEpTT04gc3RyaW5ncyBpbiB0aGUgQmlnUXVlcnkgdGFibGUuIFRoZXNl
CiBrZXlzIHRlbGwgRGF0YSBMYWJlbGluZyBTZXJ2aWNlIGhvdyB0byBwYXJzZSB0aGUgSlNP
Ti4KCiBZb3UgY2FuIHByb3ZpZGUgdGhlIGZvbGxvd2luZyBlbnRyaWVzIGluIHRoaXMgZmll
bGQ6CgogKiBgZGF0YV9qc29uX2tleWA6IHRoZSBkYXRhIGtleSBmb3IgcHJlZGljdGlvbiBp
bnB1dC4gWW91IG11c3QgcHJvdmlkZQogICBlaXRoZXIgdGhpcyBrZXkgb3IgYHJlZmVyZW5j
ZV9qc29uX2tleWAuCiAqIGByZWZlcmVuY2VfanNvbl9rZXlgOiB0aGUgZGF0YSByZWZlcmVu
Y2Uga2V5IGZvciBwcmVkaWN0aW9uIGlucHV0LiBZb3UKICAgbXVzdCBwcm92aWRlIGVpdGhl
ciB0aGlzIGtleSBvciBgZGF0YV9qc29uX2tleWAuCiAqIGBsYWJlbF9qc29uX2tleWA6IHRo
ZSBsYWJlbCBrZXkgZm9yIHByZWRpY3Rpb24gb3V0cHV0LiBSZXF1aXJlZC4KICogYGxhYmVs
X3Njb3JlX2pzb25fa2V5YDogdGhlIHNjb3JlIGtleSBmb3IgcHJlZGljdGlvbiBvdXRwdXQu
IFJlcXVpcmVkLgogKiBgYm91bmRpbmdfYm94X2pzb25fa2V5YDogdGhlIGJvdW5kaW5nIGJv
eCBrZXkgZm9yIHByZWRpY3Rpb24gb3V0cHV0LgogICBSZXF1aXJlZCBpZiB5b3VyIG1vZGVs
IHZlcnNpb24gcGVyZm9ybSBpbWFnZSBvYmplY3QgZGV0ZWN0aW9uLgoKIExlYXJuIFtob3cg
dG8gY29uZmlndXJlIHByZWRpY3Rpb24KIGtleXNdKC9tbC1lbmdpbmUvZG9jcy9jb250aW51
b3VzLWV2YWx1YXRpb24vY3JlYXRlLWpvYiNwcmVkaWN0aW9uLWtleXMpLgoKDQoFBAECBgYS
BOkBAhUKDQoFBAECBgESBOkBFioKDQoFBAECBgMSBOkBLS4KmQMKBAQBAgcSBPABAhsaigMg
UmVxdWlyZWQuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBwcmVkaWN0aW9ucyB0byBzYW1wbGUg
YW5kIHNhdmUgdG8gQmlnUXVlcnkKIGR1cmluZyBlYWNoIFtldmFsdWF0aW9uIGludGVydmFs
XVtnb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZhbHVhdGlvbkpvYi5zY2hl
ZHVsZV0uIFRoaXMgbGltaXQKIG92ZXJyaWRlcyBgZXhhbXBsZV9zYW1wbGVfcGVyY2VudGFn
ZWA6IGV2ZW4gaWYgdGhlIHNlcnZpY2UgaGFzIG5vdCBzYW1wbGVkCiBlbm91Z2ggcHJlZGlj
dGlvbnMgdG8gZnVsZmlsbCBgZXhhbXBsZV9zYW1wbGVfcGVyZWNlbnRhZ2VgIGR1cmluZyBh
bgogaW50ZXJ2YWwsIGl0IHN0b3BzIHNhbXBsaW5nIHByZWRpY3Rpb25zIHdoZW4gaXQgbWVl
dHMgdGhpcyBsaW1pdC4KCg0KBQQBAgcFEgTwAQIHCg0KBQQBAgcBEgTwAQgVCg0KBQQBAgcD
EgTwARgaCo4CCgQEAQIIEgT1AQIoGv8BIFJlcXVpcmVkLiBGcmFjdGlvbiBvZiBwcmVkaWN0
aW9ucyB0byBzYW1wbGUgYW5kIHNhdmUgdG8gQmlnUXVlcnkgZHVyaW5nCiBlYWNoIFtldmFs
dWF0aW9uIGludGVydmFsXVtnb29nbGUuY2xvdWQuZGF0YWxhYmVsaW5nLnYxYmV0YTEuRXZh
bHVhdGlvbkpvYi5zY2hlZHVsZV0uIEZvciBleGFtcGxlLCAwLjEgbWVhbnMKIDEwJSBvZiBw
cmVkaWN0aW9ucyBzZXJ2ZWQgYnkgeW91ciBtb2RlbCB2ZXJzaW9uIGdldCBzYXZlZCB0byBC
aWdRdWVyeS4KCg0KBQQBAggFEgT1AQIICg0KBQQBAggBEgT1AQkiCg0KBQQBAggDEgT1ASUn
CuQBCgQEAQIJEgT6AQI8GtUBIE9wdGlvbmFsLiBDb25maWd1cmF0aW9uIGRldGFpbHMgZm9y
IGV2YWx1YXRpb24gam9iIGFsZXJ0cy4gU3BlY2lmeSB0aGlzCiBmaWVsZCBpZiB5b3Ugd2Fu
dCB0byByZWNlaXZlIGVtYWlsIGFsZXJ0cyBpZiB0aGUgZXZhbHVhdGlvbiBqb2IgZmluZHMg
dGhhdAogeW91ciBwcmVkaWN0aW9ucyBoYXZlIGxvdyBtZWFuIGF2ZXJhZ2UgcHJlY2lzaW9u
IGR1cmluZyBhIHJ1bi4KCg0KBQQBAgkGEgT6AQIaCg0KBQQBAgkBEgT6ARs2Cg0KBQQBAgkD
EgT6ATk7Cm0KAgQCEgb/AQCJAgEaXyBQcm92aWRlcyBkZXRhaWxzIGZvciBob3cgYW4gZXZh
bHVhdGlvbiBqb2Igc2VuZHMgZW1haWwgYWxlcnRzIGJhc2VkIG9uIHRoZQogcmVzdWx0cyBv
ZiBhIHJ1bi4KCgsKAwQCARIE/wEIIAo9CgQEAgIAEgSBAgITGi8gUmVxdWlyZWQuIEFuIGVt
YWlsIGFkZHJlc3MgdG8gc2VuZCBhbGVydHMgdG8uCgoNCgUEAgIABRIEgQICCAoNCgUEAgIA
ARIEgQIJDgoNCgUEAgIAAxIEgQIREgqEAwoEBAICARIEiAICMxr1AiBSZXF1aXJlZC4gQSBu
dW1iZXIgYmV0d2VlbiAwIGFuZCAxIHRoYXQgZGVzY3JpYmVzIGEgbWluaW11bSBtZWFuIGF2
ZXJhZ2UKIHByZWNpc2lvbiB0aHJlc2hvbGQuIFdoZW4gdGhlIGV2YWx1YXRpb24gam9iIHJ1
bnMsIGlmIGl0IGNhbGN1bGF0ZXMgdGhhdAogeW91ciBtb2RlbCB2ZXJzaW9uJ3MgcHJlZGlj
dGlvbnMgZnJvbSB0aGUgcmVjZW50IGludGVydmFsIGhhdmUKIFttZWFuQXZlcmFnZVByZWNp
c2lvbl1bZ29vZ2xlLmNsb3VkLmRhdGFsYWJlbGluZy52MWJldGExLlByQ3VydmUubWVhbl9h
dmVyYWdlX3ByZWNpc2lvbl0gYmVsb3cgdGhpcwogdGhyZXNob2xkLCB0aGVuIGl0IHNlbmRz
IGFuIGFsZXJ0IHRvIHlvdXIgc3BlY2lmaWVkIGVtYWlsLgoKDQoFBAICAQUSBIgCAggKDQoF
BAICAQESBIgCCS4KDQoFBAICAQMSBIgCMTIKNAoCBAMSBowCAJECARomIFJlY29yZHMgYSBm
YWlsZWQgZXZhbHVhdGlvbiBqb2IgcnVuLgoKCwoDBAMBEgSMAggPCgwKBAQDAgASBI0CAi0K
DQoFBAMCAAYSBI0CAhsKDQoFBAMCAAESBI0CHCgKDQoFBAMCAAMSBI0CKywKMAoEBAMCARIE
kAICMhoiIERldGFpbHMgb2YgZXJyb3JzIHRoYXQgb2NjdXJyZWQuCgoNCgUEAwIBBBIEkAIC
CgoNCgUEAwIBBhIEkAILHAoNCgUEAwIBARIEkAIdLQoNCgUEAwIBAxIEkAIwMWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJob ===
    # Fields for EvaluationJob
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.datalabeling.v1beta1.EvaluationJob.State)
    # Field: schedule Type: 9 ()
    # Field: model_version Type: 9 ()
    # Field: evaluation_job_config Type: 11 (.google.cloud.datalabeling.v1beta1.EvaluationJobConfig)
    # Field: annotation_spec_set Type: 9 ()
    # Field: label_missing_ground_truth Type: 8 ()
    # Field: attempts Type: 11 (.google.cloud.datalabeling.v1beta1.Attempt)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# Enum: EvaluationJob::State
our $EvaluationJob_STATE_UNSPECIFIED = 0;
our $EvaluationJob_SCHEDULED = 1;
our $EvaluationJob_RUNNING = 2;
our $EvaluationJob_PAUSED = 3;
our $EvaluationJob_STOPPED = 4;

# === Message: Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig ===
    # Fields for EvaluationJobConfig
    # Field: image_classification_config Type: 11 (.google.cloud.datalabeling.v1beta1.ImageClassificationConfig)
    # Field: bounding_poly_config Type: 11 (.google.cloud.datalabeling.v1beta1.BoundingPolyConfig)
    # Field: text_classification_config Type: 11 (.google.cloud.datalabeling.v1beta1.TextClassificationConfig)
    # Field: input_config Type: 11 (.google.cloud.datalabeling.v1beta1.InputConfig)
    # Field: evaluation_config Type: 11 (.google.cloud.datalabeling.v1beta1.EvaluationConfig)
    # Field: human_annotation_config Type: 11 (.google.cloud.datalabeling.v1beta1.HumanAnnotationConfig)
    # Field: bigquery_import_keys Type: 11 (.google.cloud.datalabeling.v1beta1.EvaluationJobConfig.BigqueryImportKeysEntry)
    # Field: example_count Type: 5 ()
    # Field: example_sample_percentage Type: 1 ()
    # Field: evaluation_job_alert_config Type: 11 (.google.cloud.datalabeling.v1beta1.EvaluationJobAlertConfig)

# === Message: Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobAlertConfig ===
    # Fields for EvaluationJobAlertConfig
    # Field: email Type: 9 ()
    # Field: min_acceptable_mean_average_precision Type: 1 ()

# === Message: Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Attempt ===
    # Fields for Attempt
    # Field: attempt_time Type: 11 (.google.protobuf.Timestamp)
    # Field: partial_failures Type: 11 (.google.rpc.Status)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::EvaluationJob - Compiled Protocol Buffers messages for google/cloud/datalabeling/v1beta1/evaluation_job.proto

=head1 SYNOPSIS

    use Google::Cloud::Datalabeling::V1beta1::EvaluationJob;

    my $msg = Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJob->new({
        name => $name,
        description => $description,
        state => $state,
        schedule => $schedule,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJob->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datalabeling/v1beta1/evaluation_job.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJob

Defines an evaluation job that runs periodically to generate
[Evaluations][google.cloud.datalabeling.v1beta1.Evaluation]. [Creating an evaluation
job](/ml-engine/docs/continuous-evaluation/create-job) is the starting point
for using continuous evaluation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. After you create a job, Data Labeling Service assigns a name
to the job with the following format:

"projects/<var>{project_id}</var>/evaluationJobs/<var>{evaluation_job_id}</var>"

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. Description of the job. The description can be up to 25,000
characters long.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Datalabeling::V1beta1::EvaluationJob::State>)

Output only. Describes the current state of the job.

=item * C<< $msg->schedule() >> / C<< $msg->schedule($value) >>

Type: C<String>

Required. Describes the interval at which the job runs. This interval must
be at least 1 day, and it is rounded to the nearest day. For example, if
you specify a 50-hour interval, the job runs every 2 days.

You can provide the schedule in
[crontab format](/scheduler/docs/configuring/cron-job-schedules) or in an
[English-like
format](/appengine/docs/standard/python/config/cronref#schedule_format).

Regardless of what you specify, the job will run at 10:00 AM UTC. Only the
interval from this schedule is used, not the specific time of day.

=item * C<< $msg->model_version() >> / C<< $msg->model_version($value) >>

Type: C<String>

Required. The [AI Platform Prediction model
version](/ml-engine/docs/prediction-overview) to be evaluated. Prediction
input and output is sampled from this model version. When creating an
evaluation job, specify the model version in the following format:

"projects/<var>{project_id}</var>/models/<var>{model_name}</var>/versions/<var>{version_name}</var>"

There can only be one evaluation job per model version.

=item * C<< $msg->evaluation_job_config() >> / C<< $msg->evaluation_job_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig>)

Required. Configuration details for the evaluation job.

=item * C<< $msg->annotation_spec_set() >> / C<< $msg->annotation_spec_set($value) >>

Type: C<String>

Required. Name of the [AnnotationSpecSet][google.cloud.datalabeling.v1beta1.AnnotationSpecSet] describing all the
labels that your machine learning model outputs. You must create this
resource before you create an evaluation job and provide its name in the
following format:

"projects/<var>{project_id}</var>/annotationSpecSets/<var>{annotation_spec_set_id}</var>"

=item * C<< $msg->label_missing_ground_truth() >> / C<< $msg->label_missing_ground_truth($value) >>

Type: C<Bool>

Required. Whether you want Data Labeling Service to provide ground truth
labels for prediction input. If you want the service to assign human
labelers to annotate your data, set this to `true`. If you want to provide
your own ground truth labels in the evaluation job's BigQuery table, set
this to `false`.

=item * C<< $msg->attempts() >> / C<< $msg->attempts($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Attempt>)

Output only. Every time the evaluation job runs and an error occurs, the
failed attempt is appended to this array.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of when this evaluation job was created.

=back

=head3 Enum: EvaluationJob::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<SCHEDULED> => C<1>

=item * C<RUNNING> => C<2>

=item * C<PAUSED> => C<3>

=item * C<STOPPED> => C<4>

=back

=head2 Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig

Configures specific details of how a continuous evaluation job works. Provide
this configuration when you create an EvaluationJob.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->image_classification_config() >> / C<< $msg->image_classification_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ImageClassificationConfig>)

Specify this field if your model version performs image classification or
general classification.

`annotationSpecSet` in this configuration must match
[EvaluationJob.annotationSpecSet][google.cloud.datalabeling.v1beta1.EvaluationJob.annotation_spec_set].
`allowMultiLabel` in this configuration must match
`classificationMetadata.isMultiLabel` in [input_config][google.cloud.datalabeling.v1beta1.EvaluationJobConfig.input_config].

=item * C<< $msg->bounding_poly_config() >> / C<< $msg->bounding_poly_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::BoundingPolyConfig>)

Specify this field if your model version performs image object detection
(bounding box detection).

`annotationSpecSet` in this configuration must match
[EvaluationJob.annotationSpecSet][google.cloud.datalabeling.v1beta1.EvaluationJob.annotation_spec_set].

=item * C<< $msg->text_classification_config() >> / C<< $msg->text_classification_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextClassificationConfig>)

Specify this field if your model version performs text classification.

`annotationSpecSet` in this configuration must match
[EvaluationJob.annotationSpecSet][google.cloud.datalabeling.v1beta1.EvaluationJob.annotation_spec_set].
`allowMultiLabel` in this configuration must match
`classificationMetadata.isMultiLabel` in [input_config][google.cloud.datalabeling.v1beta1.EvaluationJobConfig.input_config].

=item * C<< $msg->input_config() >> / C<< $msg->input_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Dataset::InputConfig>)

Rquired. Details for the sampled prediction input. Within this
configuration, there are requirements for several fields:

* `dataType` must be one of `IMAGE`, `TEXT`, or `GENERAL_DATA`.
* `annotationType` must be one of `IMAGE_CLASSIFICATION_ANNOTATION`,
  `TEXT_CLASSIFICATION_ANNOTATION`, `GENERAL_CLASSIFICATION_ANNOTATION`,
  or `IMAGE_BOUNDING_BOX_ANNOTATION` (image object detection).
* If your machine learning model performs classification, you must specify
  `classificationMetadata.isMultiLabel`.
* You must specify `bigquerySource` (not `gcsSource`).

=item * C<< $msg->evaluation_config() >> / C<< $msg->evaluation_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationConfig>)

Required. Details for calculating evaluation metrics and creating
[Evaulations][google.cloud.datalabeling.v1beta1.Evaluation]. If your model version performs image object
detection, you must specify the `boundingBoxEvaluationOptions` field within
this configuration. Otherwise, provide an empty object for this
configuration.

=item * C<< $msg->human_annotation_config() >> / C<< $msg->human_annotation_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig>)

Optional. Details for human annotation of your data. If you set
[labelMissingGroundTruth][google.cloud.datalabeling.v1beta1.EvaluationJob.label_missing_ground_truth] to
`true` for this evaluation job, then you must specify this field. If you
plan to provide your own ground truth labels, then omit this field.

Note that you must create an [Instruction][google.cloud.datalabeling.v1beta1.Instruction] resource before you can
specify this field. Provide the name of the instruction resource in the
`instruction` field within this configuration.

=item * C<< $msg->bigquery_import_keys() >> / C<< $msg->bigquery_import_keys($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig::BigqueryImportKeysEntry>)

Required. Prediction keys that tell Data Labeling Service where to find the
data for evaluation in your BigQuery table. When the service samples
prediction input and output from your model version and saves it to
BigQuery, the data gets stored as JSON strings in the BigQuery table. These
keys tell Data Labeling Service how to parse the JSON.

You can provide the following entries in this field:

* `data_json_key`: the data key for prediction input. You must provide
  either this key or `reference_json_key`.
* `reference_json_key`: the data reference key for prediction input. You
  must provide either this key or `data_json_key`.
* `label_json_key`: the label key for prediction output. Required.
* `label_score_json_key`: the score key for prediction output. Required.
* `bounding_box_json_key`: the bounding box key for prediction output.
  Required if your model version perform image object detection.

Learn [how to configure prediction
keys](/ml-engine/docs/continuous-evaluation/create-job#prediction-keys).

=item * C<< $msg->example_count() >> / C<< $msg->example_count($value) >>

Type: C<Int32>

Required. The maximum number of predictions to sample and save to BigQuery
during each [evaluation interval][google.cloud.datalabeling.v1beta1.EvaluationJob.schedule]. This limit
overrides `example_sample_percentage`: even if the service has not sampled
enough predictions to fulfill `example_sample_perecentage` during an
interval, it stops sampling predictions when it meets this limit.

=item * C<< $msg->example_sample_percentage() >> / C<< $msg->example_sample_percentage($value) >>

Type: C<Double>

Required. Fraction of predictions to sample and save to BigQuery during
each [evaluation interval][google.cloud.datalabeling.v1beta1.EvaluationJob.schedule]. For example, 0.1 means
10% of predictions served by your model version get saved to BigQuery.

=item * C<< $msg->evaluation_job_alert_config() >> / C<< $msg->evaluation_job_alert_config($value) >>

Type: C<Message> (L<Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobAlertConfig>)

Optional. Configuration details for evaluation job alerts. Specify this
field if you want to receive email alerts if the evaluation job finds that
your predictions have low mean average precision during a run.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobAlertConfig

Provides details for how an evaluation job sends email alerts based on the
results of a run.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

Required. An email address to send alerts to.

=item * C<< $msg->min_acceptable_mean_average_precision() >> / C<< $msg->min_acceptable_mean_average_precision($value) >>

Type: C<Double>

Required. A number between 0 and 1 that describes a minimum mean average
precision threshold. When the evaluation job runs, if it calculates that
your model version's predictions from the recent interval have
[meanAveragePrecision][google.cloud.datalabeling.v1beta1.PrCurve.mean_average_precision] below this
threshold, then it sends an alert to your specified email.

=back

=head2 Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Attempt

Records a failed evaluation job run.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attempt_time() >> / C<< $msg->attempt_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

=item * C<< $msg->partial_failures() >> / C<< $msg->partial_failures($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Details of errors that occurred.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
