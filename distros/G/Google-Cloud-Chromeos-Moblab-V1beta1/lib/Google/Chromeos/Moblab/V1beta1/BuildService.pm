package Google::Chromeos::Moblab::V1beta1::BuildService;

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
    eval { require Google::Api::Routing };
    eval { require Google::Chromeos::Moblab::V1beta1::Resources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2hyb21lb3MvbW9ibGFiL3YxYmV0YTEvYnVpbGRfc2VydmljZS5wcm90bxIe
Z29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJldGExGhxnb29nbGUvYXBpL2Fubm90YXRpb25z
LnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoYZ29vZ2xlL2FwaS9yb3V0
aW5nLnByb3RvGi5nb29nbGUvY2hyb21lb3MvbW9ibGFiL3YxYmV0YTEvcmVzb3VyY2VzLnBy
b3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bxogZ29vZ2xlL3Byb3Rv
YnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
tQEKGkZpbmRNb3N0U3RhYmxlQnVpbGRSZXF1ZXN0ElQKDGJ1aWxkX3RhcmdldBgBIAEoCUIx
4EEB+kErCiljaHJvbWVvc21vYmxhYi5nb29nbGVhcGlzLmNvbS9CdWlsZFRhcmdldFILYnVp
bGRUYXJnZXQSQQoFbW9kZWwYAiABKAlCK+BBAfpBJQojY2hyb21lb3Ntb2JsYWIuZ29vZ2xl
YXBpcy5jb20vTW9kZWxSBW1vZGVsIloKG0ZpbmRNb3N0U3RhYmxlQnVpbGRSZXNwb25zZRI7
CgVidWlsZBgBIAEoCzIlLmdvb2dsZS5jaHJvbWVvcy5tb2JsYWIudjFiZXRhMS5CdWlsZFIF
YnVpbGQifAoXTGlzdEJ1aWxkVGFyZ2V0c1JlcXVlc3QSIAoJcGFnZV9zaXplGAEgASgFQgPg
QQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAiABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZp
bHRlchgDIAEoCUID4EEBUgZmaWx0ZXIiswEKGExpc3RCdWlsZFRhcmdldHNSZXNwb25zZRJQ
Cg1idWlsZF90YXJnZXRzGAEgAygLMisuZ29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJldGEx
LkJ1aWxkVGFyZ2V0UgxidWlsZFRhcmdldHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1u
ZXh0UGFnZVRva2VuEh0KCnRvdGFsX3NpemUYAyABKAVSCXRvdGFsU2l6ZSKkAQoRTGlzdE1v
ZGVsc1JlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWNocm9tZW9zbW9ibGFiLmdv
b2dsZWFwaXMuY29tL0J1aWxkVGFyZ2V0UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPg
QQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIpoBChJM
aXN0TW9kZWxzUmVzcG9uc2USPQoGbW9kZWxzGAEgAygLMiUuZ29vZ2xlLmNocm9tZW9zLm1v
YmxhYi52MWJldGExLk1vZGVsUgZtb2RlbHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1u
ZXh0UGFnZVRva2VuEh0KCnRvdGFsX3NpemUYAyABKAVSCXRvdGFsU2l6ZSK1AgoRTGlzdEJ1
aWxkc1JlcXVlc3QSQwoGcGFyZW50GAEgASgJQivgQQL6QSUKI2Nocm9tZW9zbW9ibGFiLmdv
b2dsZWFwaXMuY29tL01vZGVsUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBh
Z2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgE
IAEoCUID4EEBUgZmaWx0ZXISPAoJcmVhZF9tYXNrGAUgASgLMhouZ29vZ2xlLnByb3RvYnVm
LkZpZWxkTWFza0ID4EEBUghyZWFkTWFzaxI6Cghncm91cF9ieRgGIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIHZ3JvdXBCeSKaAQoSTGlzdEJ1aWxkc1Jlc3BvbnNl
Ej0KBmJ1aWxkcxgBIAMoCzIlLmdvb2dsZS5jaHJvbWVvcy5tb2JsYWIudjFiZXRhMS5CdWls
ZFIGYnVpbGRzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIdCgp0
b3RhbF9zaXplGAMgASgFUgl0b3RhbFNpemUi8QEKHENoZWNrQnVpbGRTdGFnZVN0YXR1c1Jl
cXVlc3QSRwoEbmFtZRgBIAEoCUIz4EEC+kEtCitjaHJvbWVvc21vYmxhYi5nb29nbGVhcGlz
LmNvbS9CdWlsZEFydGlmYWN0UgRuYW1lEhsKBmZpbHRlchgCIAEoCUID4EEBUgZmaWx0ZXIS
LQoQc291cmNlX2J1Y2tldF9pZBgDIAEoCUID4EEBUg5zb3VyY2VCdWNrZXRJZBIbCgZicmFu
Y2gYBCABKAlCA+BBAVIGYnJhbmNoEh8KCGFydGlmYWN0GAUgASgJQgPgQQFSCGFydGlmYWN0
It8CCh1DaGVja0J1aWxkU3RhZ2VTdGF0dXNSZXNwb25zZRImCg9pc19idWlsZF9zdGFnZWQY
ASABKAhSDWlzQnVpbGRTdGFnZWQSYQoVc3RhZ2VkX2J1aWxkX2FydGlmYWN0GAIgASgLMi0u
Z29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJldGExLkJ1aWxkQXJ0aWZhY3RSE3N0YWdlZEJ1
aWxkQXJ0aWZhY3QSYQoVc291cmNlX2J1aWxkX2FydGlmYWN0GAMgASgLMi0uZ29vZ2xlLmNo
cm9tZW9zLm1vYmxhYi52MWJldGExLkJ1aWxkQXJ0aWZhY3RSE3NvdXJjZUJ1aWxkQXJ0aWZh
Y3QSUAoLY2xvdWRfYnVpbGQYBCABKAsyKi5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0
YTEuQ2xvdWRCdWlsZEID4EEBUgpjbG91ZEJ1aWxkIuYBChFTdGFnZUJ1aWxkUmVxdWVzdBJH
CgRuYW1lGAEgASgJQjPgQQL6QS0KK2Nocm9tZW9zbW9ibGFiLmdvb2dsZWFwaXMuY29tL0J1
aWxkQXJ0aWZhY3RSBG5hbWUSGwoGZmlsdGVyGAIgASgJQgPgQQFSBmZpbHRlchItChBzb3Vy
Y2VfYnVja2V0X2lkGAMgASgJQgPgQQFSDnNvdXJjZUJ1Y2tldElkEhsKBmJyYW5jaBgEIAEo
CUID4EEBUgZicmFuY2gSHwoIYXJ0aWZhY3QYBSABKAlCA+BBAVIIYXJ0aWZhY3QiyAEKElN0
YWdlQnVpbGRSZXNwb25zZRJhChVzdGFnZWRfYnVpbGRfYXJ0aWZhY3QYASABKAsyLS5nb29n
bGUuY2hyb21lb3MubW9ibGFiLnYxYmV0YTEuQnVpbGRBcnRpZmFjdFITc3RhZ2VkQnVpbGRB
cnRpZmFjdBJPCgtjbG91ZF9idWlsZBgCIAEoCzIqLmdvb2dsZS5jaHJvbWVvcy5tb2JsYWIu
djFiZXRhMS5DbG91ZEJ1aWxkQgIYAVIKY2xvdWRCdWlsZCL+AQoSU3RhZ2VCdWlsZE1ldGFk
YXRhEikKEHByb2dyZXNzX3BlcmNlbnQYASABKAJSD3Byb2dyZXNzUGVyY2VudBI5CgpzdGFy
dF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRUaW1lEjUK
CGVuZF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHZW5kVGltZRJL
CgtjbG91ZF9idWlsZBgEIAEoCzIqLmdvb2dsZS5jaHJvbWVvcy5tb2JsYWIudjFiZXRhMS5D
bG91ZEJ1aWxkUgpjbG91ZEJ1aWxkMrwLCgxCdWlsZFNlcnZpY2USpAEKEExpc3RCdWlsZFRh
cmdldHMSNy5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0YTEuTGlzdEJ1aWxkVGFyZ2V0
c1JlcXVlc3QaOC5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0YTEuTGlzdEJ1aWxkVGFy
Z2V0c1Jlc3BvbnNlIh2C0+STAhcSFS92MWJldGExL2J1aWxkVGFyZ2V0cxKtAQoKTGlzdE1v
ZGVscxIxLmdvb2dsZS5jaHJvbWVvcy5tb2JsYWIudjFiZXRhMS5MaXN0TW9kZWxzUmVxdWVz
dBoyLmdvb2dsZS5jaHJvbWVvcy5tb2JsYWIudjFiZXRhMS5MaXN0TW9kZWxzUmVzcG9uc2Ui
OILT5JMCKRInL3YxYmV0YTEve3BhcmVudD1idWlsZFRhcmdldHMvKn0vbW9kZWxz2kEGcGFy
ZW50ErYBCgpMaXN0QnVpbGRzEjEuZ29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJldGExLkxp
c3RCdWlsZHNSZXF1ZXN0GjIuZ29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJldGExLkxpc3RC
dWlsZHNSZXNwb25zZSJBgtPkkwIyEjAvdjFiZXRhMS97cGFyZW50PWJ1aWxkVGFyZ2V0cy8q
L21vZGVscy8qfS9idWlsZHPaQQZwYXJlbnQS5wEKFUNoZWNrQnVpbGRTdGFnZVN0YXR1cxI8
Lmdvb2dsZS5jaHJvbWVvcy5tb2JsYWIudjFiZXRhMS5DaGVja0J1aWxkU3RhZ2VTdGF0dXNS
ZXF1ZXN0Gj0uZ29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJldGExLkNoZWNrQnVpbGRTdGFn
ZVN0YXR1c1Jlc3BvbnNlIlGC0+STAkQSQi92MWJldGExL3tuYW1lPWJ1aWxkVGFyZ2V0cy8q
L21vZGVscy8qL2J1aWxkcy8qL2FydGlmYWN0cy8qfTpjaGVja9pBBG5hbWUS3wEKClN0YWdl
QnVpbGQSMS5nb29nbGUuY2hyb21lb3MubW9ibGFiLnYxYmV0YTEuU3RhZ2VCdWlsZFJlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIn+C0+STAkciQi92MWJldGExL3tu
YW1lPWJ1aWxkVGFyZ2V0cy8qL21vZGVscy8qL2J1aWxkcy8qL2FydGlmYWN0cy8qfTpzdGFn
ZToBKtpBBG5hbWXKQSgKElN0YWdlQnVpbGRSZXNwb25zZRISU3RhZ2VCdWlsZE1ldGFkYXRh
EoEDChNGaW5kTW9zdFN0YWJsZUJ1aWxkEjouZ29vZ2xlLmNocm9tZW9zLm1vYmxhYi52MWJl
dGExLkZpbmRNb3N0U3RhYmxlQnVpbGRSZXF1ZXN0GjsuZ29vZ2xlLmNocm9tZW9zLm1vYmxh
Yi52MWJldGExLkZpbmRNb3N0U3RhYmxlQnVpbGRSZXNwb25zZSLwAYLT5JMCfBI6L3YxYmV0
YTEve2J1aWxkX3RhcmdldD1idWlsZFRhcmdldHMvKn06ZmluZE1vc3RTdGFibGVCdWlsZFo+
EjwvdjFiZXRhMS97bW9kZWw9YnVpbGRUYXJnZXRzLyovbW9kZWxzLyp9OmZpbmRNb3N0U3Rh
YmxlQnVpbGSK0+STAlkSLQoMYnVpbGRfdGFyZ2V0Eh17YnVpbGRfdGFyZ2V0PWJ1aWxkVGFy
Z2V0cy8qfRIoCgVtb2RlbBIfe21vZGVsPWJ1aWxkVGFyZ2V0cy8qL21vZGVscy8qfdpBDGJ1
aWxkX3RhcmdldBpMykEdY2hyb21lb3Ntb2JsYWIuZ29vZ2xlYXBpcy5jb23SQSlodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL21vYmxhYmFwaUKBAQoiY29tLmdvb2dsZS5jaHJv
bWVvcy5tb2JsYWIudjFiZXRhMUIRQnVpbGRTZXJ2aWNlUHJvdG9IAVABWkRnb29nbGUuZ29s
YW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2Nocm9tZW9zL21vYmxhYi92MWJldGExO21v
YmxhYkq7XwoHEgUOAPQCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAJwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkK
AgMEEgMWACIKCQoCAwUSAxcAOAoJCgIDBhIDGAAtCgkKAgMHEgMZACoKCQoCAwgSAxoAKQoI
CgEIEgMcAFsKCQoCCAsSAxwAWwoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeADIKCQoC
CAgSAx4AMgoICgEIEgMfADsKCQoCCAESAx8AOwoICgEIEgMgABwKCQoCCAkSAyAAHAovCgIG
ABIEIwB+ARojIE1hbmFnZXMgQ2hyb21lIE9TIGJ1aWxkIHNlcnZpY2VzLgoKCgoDBgABEgMj
CBQKCgoDBgADEgMkAkUKDAoFBgADmQgSAyQCRQoLCgMGAAMSBCUCJjIKDQoFBgADmggSBCUC
JjIKQgoEBgACABIEKQIuAxo0IExpc3RzIGFsbCBidWlsZCB0YXJnZXRzIHRoYXQgYSB1c2Vy
IGhhcyBhY2Nlc3MgdG8uCgoMCgUGAAIAARIDKQYWCgwKBQYAAgACEgMpFy4KDAoFBgACAAMS
AyoPJwoNCgUGAAIABBIEKwQtBgoRCgkGAAIABLDKvCISBCsELQYKPAoEBgACARIEMQI2Axou
IExpc3RzIGFsbCBtb2RlbHMgZm9yIHRoZSBnaXZlbiBidWlsZCB0YXJnZXQuCgoMCgUGAAIB
ARIDMQYQCgwKBQYAAgECEgMxESIKDAoFBgACAQMSAzEtPwoNCgUGAAIBBBIEMgQ0BgoRCgkG
AAIBBLDKvCISBDIENAYKDAoFBgACAQQSAzUENAoPCggGAAIBBJsIABIDNQQ0CoEBCgQGAAIC
EgQ6Aj8DGnMgTGlzdHMgYWxsIGJ1aWxkcyBmb3IgdGhlIGdpdmVuIGJ1aWxkIHRhcmdldCBh
bmQgbW9kZWwgaW4gZGVzY2VuZGluZyBvcmRlcgogZm9yIHRoZSBtaWxlc3RvbmVzIGFuZCBi
dWlsZCB2ZXJzaW9ucy4KCgwKBQYAAgIBEgM6BhAKDAoFBgACAgISAzoRIgoMCgUGAAICAxID
Oi0/Cg0KBQYAAgIEEgQ7BD0GChEKCQYAAgIEsMq8IhIEOwQ9BgoMCgUGAAICBBIDPgQ0Cg8K
CAYAAgIEmwgAEgM+BDQKbQoEBgACAxIEQwJJAxpfIENoZWNrcyB0aGUgc3RhZ2Ugc3RhdHVz
IGZvciBhIGdpdmVuIGJ1aWxkIGFydGlmYWN0IGluIGEgcGFydG5lciBHb29nbGUKIENsb3Vk
IFN0b3JhZ2UgYnVja2V0LgoKDAoFBgACAwESA0MGGwoMCgUGAAIDAhIDQxw4CgwKBQYAAgMD
EgNEDywKDQoFBgACAwQSBEUERwYKEQoJBgACAwSwyrwiEgRFBEcGCgwKBQYAAgMEEgNIBDIK
DwoIBgACAwSbCAASA0gEMgq7AwoEBgACBBIEUgJcAxqsAyBTdGFnZXMgYSBnaXZlbiBidWls
ZCBhcnRpZmFjdCBmcm9tIGEgaW50ZXJuYWwgR29vZ2xlIENsb3VkIFN0b3JhZ2UgYnVja2V0
CiB0byBhIHBhcnRuZXIgR29vZ2xlIENsb3VkIFN0b3JhZ2UgYnVja2V0LiBUaGUgc3RhZ2Ug
d2lsbCBiZSBza2lwcGVkIGlmIGFsbAogdGhlIG9iamVjdHMgaW4gdGhlIHBhcnRuZXIgYnVj
a2V0IGFyZSB0aGUgc2FtZSBhcyBpbiB0aGUgaW50ZXJuYWwgYnVja2V0LgogT3BlcmF0aW9u
CiA8cmVzcG9uc2U6W1N0YWdlQnVpbGRSZXNwb25zZV1bZ29vZ2xlLmNocm9tZW9zLm1vYmxh
Yi52MWJldGExLlN0YWdlQnVpbGRSZXNwb25zZV0sCiAgICAgICAgICAgIG1ldGFkYXRhOgog
ICAgICAgICAgICBbU3RhZ2VCdWlsZE1ldGFkYXRhXVtnb29nbGUuY2hyb21lb3MubW9ibGFi
LnYxYmV0YTEuU3RhZ2VCdWlsZE1ldGFkYXRhXT4KCgwKBQYAAgQBEgNSBhAKDAoFBgACBAIS
A1IRIgoMCgUGAAIEAxIDUi1JCg0KBQYAAgQEEgRTBFYGChEKCQYAAgQEsMq8IhIEUwRWBgoM
CgUGAAIEBBIDVwQyCg8KCAYAAgQEmwgAEgNXBDIKDQoFBgACBAQSBFgEWwYKDwoHBgACBASZ
CBIEWARbBgrrBAoEBgACBRIEagJ9AxrcBCBGaW5kcyB0aGUgbW9zdCBzdGFibGUgYnVpbGQg
Zm9yIHRoZSBnaXZlbiBidWlsZCB0YXJnZXQuIFRoZSBkZWZpbml0aW9uIG9mCiB0aGUgbW9z
dCBzdGFibGUgYnVpbGQgaXMgZGV0ZXJtaW5lZCBieSBldmFsdWF0aW5nIHRoZSBmb2xsb3dp
bmcgcnVsZSBpbgogb3JkZXIgdW50aWwgb25lIGlzIHRydWUuIElmIG5vbmUgYXJlIHRydWUs
IHRoZW4gdGhlcmUgaXMgbm8gc3RhYmxlIGJ1aWxkCiBhbmQgaXQgd2lsbCByZXR1cm4gYW4g
ZW1wdHkgcmVzcG9uc2UuCgogRXZhbHVhdGlvbiBydWxlczoKICAgMS4gU3RhYmxlIGNoYW5u
ZWwgYnVpbGQgd2l0aCBsYWJlbCDigJxMaXZl4oCdCiAgIDIuIEJldGEgY2hhbm5lbCBidWls
ZCB3aXRoIGxhYmVsIOKAnExpdmXigJ0KICAgMy4gRGV2IGNoYW5uZWwgYnVpbGQgd2l0aCBs
YWJlbCDigJxMaXZl4oCdCiAgIDQuIE1vc3QgcmVjZW50IHN0YWJsZSBjaGFubmVsIGJ1aWxk
IHdpdGggYnVpbGQgc3RhdHVzIFBhc3MKICAgNS4gTW9zdCByZWNlbnQgYmV0YSBjaGFubmVs
IGJ1aWxkIHdpdGggYnVpbGQgc3RhdHVzIFBhc3MKICAgNi4gTW9zdCByZWNlbnQgZGV2IGNo
YW5uZWwgYnVpbGQgd2l0aCBidWlsZCBzdGF0dXMgUGFzcwoKDAoFBgACBQESA2oGGQoMCgUG
AAIFAhIDaho0CgwKBQYAAgUDEgNrDyoKDQoFBgACBQQSBGwEcQYKEQoJBgACBQSwyrwiEgRs
BHEGCg0KBQYAAgUEEgRyBHsGChEKCQYAAgUEscq8IhIEcgR7BgoMCgUGAAIFBBIDfAQ6Cg8K
CAYAAgUEmwgAEgN8BDoKQgoCBAASBoEBAJUBARo0IFJlcXVlc3QgbWVzc2FnZSBmb3IgZmlu
ZGluZyB0aGUgbW9zdCBzdGFibGUgYnVpbGQuCgoLCgMEAAESBIEBCCIKbgoEBAACABIGhQEC
igEEGl4gT3B0aW9uYWwuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIGJ1aWxkIHRh
cmdldC4KIEZvciBleGFtcGxlLAogJ2J1aWxkVGFyZ2V0cy9vY3RvcHVzJy4KCg0KBQQAAgAF
EgSFAQIICg0KBQQAAgABEgSFAQkVCg0KBQQAAgADEgSFARgZCg8KBQQAAgAIEgaFARqKAQMK
EAoIBAACAAicCAASBIYBBCoKEQoHBAACAAifCBIGhwEEiQEFCoQBCgQEAAIBEgaPAQKUAQQa
dCBPcHRpb25hbC4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYnVpbGQgdGFyZ2V0
IG9yIG1vZGVsLgogRm9yIGV4YW1wbGUsCiAnYnVpbGRUYXJnZXRzL29jdG9wdXMvbW9kZWxz
L2JvYmJhJy4KCg0KBQQAAgEFEgSPAQIICg0KBQQAAgEBEgSPAQkOCg0KBQQAAgEDEgSPARES
Cg8KBQQAAgEIEgaPAROUAQMKEAoIBAACAQicCAASBJABBCoKEQoHBAACAQifCBIGkQEEkwEF
CkMKAgQBEgaYAQCbAQEaNSBSZXNwb25zZSBtZXNzYWdlIGZvciBmaW5kaW5nIHRoZSBtb3N0
IHN0YWJsZSBidWlsZC4KCgsKAwQBARIEmAEIIwomCgQEAQIAEgSaAQISGhggVGhlIG1vc3Qg
c3RhYmxlIGJ1aWxkLgoKDQoFBAECAAYSBJoBAgcKDQoFBAECAAESBJoBCA0KDQoFBAECAAMS
BJoBEBEKOgoCBAISBp4BAKoBARosIFJlcXVlc3QgbWVzc2FnZSBmb3IgbGlzdGluZyBidWls
ZCB0YXJnZXRzLgoKCwoDBAIBEgSeAQgfCkoKBAQCAgASBKABAj8aPCBPcHRpb25hbC4gVGhl
IG51bWJlciBvZiBidWlsZCB0YXJnZXRzIHRvIHJldHVybiBpbiBhIHBhZ2UuCgoNCgUEAgIA
BRIEoAECBwoNCgUEAgIAARIEoAEIEQoNCgUEAgIAAxIEoAEUFQoNCgUEAgIACBIEoAEWPgoQ
CggEAgIACJwIABIEoAEXPQqIAQoEBAICARIEpAECQRp6IE9wdGlvbmFsLiBBIHBhZ2UgdG9r
ZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdEJ1aWxkVGFyZ2V0c2AgY2FsbC4K
IFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKDQoFBAIC
AQUSBKQBAggKDQoFBAICAQESBKQBCRMKDQoFBAICAQMSBKQBFhcKDQoFBAICAQgSBKQBGEAK
EAoIBAICAQicCAASBKQBGT8KzgEKBAQCAgISBKkBAj0avwEgT3B0aW9uYWwuIEZpbHRlciB0
aGF0IHNwZWNpZmllcyB2YWx1ZSBjb25zdHJhaW50cyBvZiBmaWVsZHMuIEZvciBleGFtcGxl
LAogdGhlIGZpbHRlciBjYW4gYmUgc2V0IGFzICJmaWx0ZXI9J21vZGVsPW1vZGVsTmFtZSci
IHRvIG9ubHkgc2VsZWN0IGJ1aWxkCiB0YXJnZXRzIGFzc29jaWF0ZWQgd2l0aCB0aGUgZ2l2
ZW4gbW9kZWwuCgoNCgUEAgICBRIEqQECCAoNCgUEAgICARIEqQEJDwoNCgUEAgICAxIEqQES
EwoNCgUEAgICCBIEqQEUPAoQCggEAgICCJwIABIEqQEVOwo7CgIEAxIGrQEAtwEBGi0gUmVz
cG9uc2UgbWVzc2FnZSBmb3IgbGlzdGluZyBidWlsZCB0YXJnZXRzLgoKCwoDBAMBEgStAQgg
CioKBAQDAgASBK8BAikaHCBUaGUgbGlzdCBvZiBidWlsZCB0YXJnZXRzLgoKDQoFBAMCAAQS
BK8BAgoKDQoFBAMCAAYSBK8BCxYKDQoFBAMCAAESBK8BFyQKDQoFBAMCAAMSBK8BJygKewoE
BAMCARIEswECHRptIFRva2VuIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgYnVpbGQg
dGFyZ2V0cy4gSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLAogdGhlcmUgYXJlIG5vIHN1YnNl
cXVlbnQgcGFnZXMuCgoNCgUEAwIBBRIEswECCAoNCgUEAwIBARIEswEJGAoNCgUEAwIBAxIE
swEbHAouCgQEAwICEgS2AQIXGiAgVG90YWwgbnVtYmVyIG9mIGJ1aWxkIHRhcmdldHMuCgoN
CgUEAwICBRIEtgECBwoNCgUEAwICARIEtgEIEgoNCgUEAwICAxIEtgEVFgozCgIEBBIGugEA
yQEBGiUgUmVxdWVzdCBtZXNzYWdlIGZvciBsaXN0aW5nIG1vZGVscy4KCgsKAwQEARIEugEI
GQpDCgQEBAIAEga8AQLBAQQaMyBSZXF1aXJlZC4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBv
ZiBidWlsZCB0YXJnZXQuCgoNCgUEBAIABRIEvAECCAoNCgUEBAIAARIEvAEJDwoNCgUEBAIA
AxIEvAESEwoPCgUEBAIACBIGvAEUwQEDChAKCAQEAgAInAgAEgS9AQQqChEKBwQEAgAInwgS
Br4BBMABBQpDCgQEBAIBEgTEAQI/GjUgT3B0aW9uYWwuIFRoZSBudW1iZXIgb2YgbW9kZWxz
IHRvIHJldHVybiBpbiBhIHBhZ2UuCgoNCgUEBAIBBRIExAECBwoNCgUEBAIBARIExAEIEQoN
CgUEBAIBAxIExAEUFQoNCgUEBAIBCBIExAEWPgoQCggEBAIBCJwIABIExAEXPQqCAQoEBAQC
AhIEyAECQRp0IE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2
aW91cyBgTGlzdE1vZGVsc2AgY2FsbC4gUHJvdmlkZQogdGhpcyB0byByZXRyaWV2ZSB0aGUg
c3Vic2VxdWVudCBwYWdlLgoKDQoFBAQCAgUSBMgBAggKDQoFBAQCAgESBMgBCRMKDQoFBAQC
AgMSBMgBFhcKDQoFBAQCAggSBMgBGEAKEAoIBAQCAgicCAASBMgBGT8KNAoCBAUSBswBANYB
ARomIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIGxpc3RpbmcgbW9kZWxzLgoKCwoDBAUBEgTMAQga
CiMKBAQFAgASBM4BAhwaFSBUaGUgbGlzdCBvZiBtb2RlbHMuCgoNCgUEBQIABBIEzgECCgoN
CgUEBQIABhIEzgELEAoNCgUEBQIAARIEzgERFwoNCgUEBQIAAxIEzgEaGwp0CgQEBQIBEgTS
AQIdGmYgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiBtb2RlbHMuIElmIHRo
aXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUKIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoK
DQoFBAUCAQUSBNIBAggKDQoFBAUCAQESBNIBCRgKDQoFBAUCAQMSBNIBGxwKJwoEBAUCAhIE
1QECFxoZIFRvdGFsIG51bWJlciBvZiBtb2RlbHMuCgoNCgUEBQICBRIE1QECBwoNCgUEBQIC
ARIE1QEIEgoNCgUEBQICAxIE1QEVFgozCgIEBhIG2QEA/gEBGiUgUmVxdWVzdCBtZXNzYWdl
IGZvciBsaXN0aW5nIGJ1aWxkcy4KCgsKAwQGARIE2QEIGQq+AQoEBAYCABIG3gEC4wEEGq0B
IFJlcXVpcmVkLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbC4gVGhlIG1v
ZGVsIGlkIGlzIHRoZSBzYW1lIGFzCiB0aGUgYnVpbGQgdGFyZ2V0IGlkIGZvciBub24tdW5p
ZmllZCBidWlsZHMuCiBGb3IgZXhhbXBsZSwKICdidWlsZFRhcmdldHMvb2N0b3B1cy9tb2Rl
bHMvYm9iYmEnLgoKDQoFBAYCAAUSBN4BAggKDQoFBAYCAAESBN4BCQ8KDQoFBAYCAAMSBN4B
EhMKDwoFBAYCAAgSBt4BFOMBAwoQCggEBgIACJwIABIE3wEEKgoRCgcEBgIACJ8IEgbgAQTi
AQUKQwoEBAYCARIE5gECPxo1IE9wdGlvbmFsLiBUaGUgbnVtYmVyIG9mIGJ1aWxkcyB0byBy
ZXR1cm4gaW4gYSBwYWdlLgoKDQoFBAYCAQUSBOYBAgcKDQoFBAYCAQESBOYBCBEKDQoFBAYC
AQMSBOYBFBUKDQoFBAYCAQgSBOYBFj4KEAoIBAYCAQicCAASBOYBFz0KggEKBAQGAgISBOoB
AkEadCBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMg
YExpc3RCdWlsZHNgIGNhbGwuIFByb3ZpZGUKIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNl
cXVlbnQgcGFnZS4KCg0KBQQGAgIFEgTqAQIICg0KBQQGAgIBEgTqAQkTCg0KBQQGAgIDEgTq
ARYXCg0KBQQGAgIIEgTqARhAChAKCAQGAgIInAgAEgTqARk/Cr8BCgQEBgIDEgTvAQI9GrAB
IE9wdGlvbmFsLiBGaWx0ZXIgdGhhdCBzcGVjaWZpZXMgdmFsdWUgY29uc3RyYWludHMgb2Yg
ZmllbGRzLiBGb3IgZXhhbXBsZSwKIHRoZSBmaWx0ZXIgY2FuIGJlIHNldCBhcyAiZmlsdGVy
PSdtaWxlc3RvbmU9bWlsZXN0b25lcy84MCciIHRvIG9ubHkgc2VsZWN0CiBidWlsZHMgaW4g
bWlsZXN0b25lIDgwLgoKDQoFBAYCAwUSBO8BAggKDQoFBAYCAwESBO8BCQ8KDQoFBAYCAwMS
BO8BEhMKDQoFBAYCAwgSBO8BFDwKEAoIBAYCAwicCAASBO8BFTsKxQIKBAQGAgQSBvYBAvcB
Lxq0AiBPcHRpb25hbC4gUmVhZCBtYXNrIHRoYXQgc3BlY2lmaWVzIHdoaWNoIEJ1aWxkIGZp
ZWxkcyB0byByZXR1cm4uIElmIGVtcHR5LAogYWxsIEJ1aWxkIGZpZWxkcyB3aWxsIGJlIHJl
dHVybmVkLiBWYWxpZCBmaWVsZHM6IG5hbWUsIG1pbGVzdG9uZSwKIGJ1aWxkX3ZlcnNpb24u
IEZvciBleGFtcGxlLCBpZiB0aGUgcmVhZF9tYXNrIGlzIHNldCBhcwogInJlYWRfbWFzaz0n
bWlsZXN0b25lJyIsIHRoZSBMaXN0QnVpbGRzIHdpbGwgcmV0dXJuIGEgbGlzdCBvZiBCdWls
ZHMgb2JqZWN0CiB3aXRoIG9ubHkgdGhlIG1pbGVzdG9uZSBmaWVsZC4KCg0KBQQGAgQGEgT2
AQIbCg0KBQQGAgQBEgT2ARwlCg0KBQQGAgQDEgT2ASgpCg0KBQQGAgQIEgT3AQYuChAKCAQG
AgQInAgAEgT3AQctCr8BCgQEBgIFEgb8AQL9AS8argEgT3B0aW9uYWwuIFRoZSBvcGVyYXRp
b24gdGhhdCBncm91cHMgYnkgYWxsIHRoZSBCdWlsZCBmaWVsZHMgc3BlY2lmaWVkIGluCiB0
aGUgcmVhZCBtYXNrLiBUaGUgZ3JvdXBfYnkgZmllbGQgc2hvdWxkIGJlIHRoZSBzYW1lIGFz
IHRoZSByZWFkX21hc2sgZmllbGQKIGluIGNvbnZlbnRpb24gb2YgU1FMLgoKDQoFBAYCBQYS
BPwBAhsKDQoFBAYCBQESBPwBHCQKDQoFBAYCBQMSBPwBJygKDQoFBAYCBQgSBP0BBi4KEAoI
BAYCBQicCAASBP0BBy0KNAoCBAcSBoECAIsCARomIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIGxp
c3RpbmcgYnVpbGRzLgoKCwoDBAcBEgSBAggaCiMKBAQHAgASBIMCAhwaFSBUaGUgbGlzdCBv
ZiBidWlsZHMuCgoNCgUEBwIABBIEgwICCgoNCgUEBwIABhIEgwILEAoNCgUEBwIAARIEgwIR
FwoNCgUEBwIAAxIEgwIaGwp0CgQEBwIBEgSHAgIdGmYgVG9rZW4gdG8gcmV0cmlldmUgdGhl
IG5leHQgcGFnZSBvZiBidWlsZHMuIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUK
IGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAcCAQUSBIcCAggKDQoFBAcCAQESBIcC
CRgKDQoFBAcCAQMSBIcCGxwKJwoEBAcCAhIEigICFxoZIFRvdGFsIG51bWJlciBvZiBidWls
ZHMuCgoNCgUEBwICBRIEigICBwoNCgUEBwICARIEigIIEgoNCgUEBwICAxIEigIVFgpNCgIE
CBIGjgIArAIBGj8gUmVxdWVzdCBtZXNzYWdlIGZvciBjaGVja2luZyBpZiB0aGUgYnVpbGQg
YXJ0aWZhY3QgaXMgc3RhZ2VkLgoKCwoDBAgBEgSOAggkCrYBCgQECAIAEgaSAgKXAgQapQEg
UmVxdWlyZWQuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIGJ1aWxkIGFydGlmYWN0
LgogRm9yIGV4YW1wbGUsCiAnYnVpbGRUYXJnZXRzL29jdG9wdXMvbW9kZWxzL2JvYmJhL2J1
aWxkcy8xMjYwNy42LjAvYXJ0aWZhY3RzL2Nocm9tZW9zLW1vYmxhYi1wZW5nLXN0YWdpbmcn
LgoKDQoFBAgCAAUSBJICAggKDQoFBAgCAAESBJICCQ0KDQoFBAgCAAMSBJICEBEKDwoFBAgC
AAgSBpICEpcCAwoQCggECAIACJwIABIEkwIEKgoRCgcECAIACJ8IEgaUAgSWAgUKrwEKBAQI
AgESBJwCAj0aoAEgT3B0aW9uYWwuIEZpbHRlciB0aGF0IHNwZWNpZmllcyB2YWx1ZSBjb25z
dHJhaW50cyBvZiBmaWVsZHMuIEZvciBleGFtcGxlLAogdGhlIGZpbHRlciBjYW4gYmUgc2V0
IGFzICJmaWx0ZXI9J3R5cGU9cmVsZWFzZSciIHRvIG9ubHkgY2hlY2sgdGhlIHJlbGVhc2UK
IGJ1aWxkcy4KCg0KBQQIAgEFEgScAgIICg0KBQQIAgEBEgScAgkPCg0KBQQIAgEDEgScAhIT
Cg0KBQQIAgEIEgScAhQ8ChAKCAQIAgEInAgAEgScAhU7CnAKBAQIAgISBKACAkcaYiBPcHRp
b25hbC4gVGhlIHNvdXJjZSBsb2NhdGlvbiBvZiB0aGUgYXJ0aWZhY3QsIGRlZmF1bHRzIHRv
CiBgY2hyb21lb3MtaW1hZ2UtYXJjaGl2ZWAgaWYgbWlzc2luZy4KCg0KBQQIAgIFEgSgAgII
Cg0KBQQIAgIBEgSgAgkZCg0KBQQIAgIDEgSgAhwdCg0KBQQIAgIIEgSgAh5GChAKCAQIAgII
nAgAEgSgAh9FCtYBCgQECAIDEgSlAgI9GscBIE9wdGlvbmFsLiBUaGUgYnJhbmNoIGRpcmVj
dG9yeSBpbiB0aGUgc291cmNlX2J1Y2tldF9pZCB3aGVyZSB0aGUgYXJ0aWZhY3QKIGlzIGxv
Y2F0ZWQsIHN1Y2ggYXMgYGZpcm13YXJlLWVjLVIxNDMtMTY0NjMuMi5CYC4gSWYgdW5zcGVj
aWZpZWQsIHRoZSBidWlsZAogd2lsbCBiZSBmb3VuZCBpbiBnb2xkZW5leWUgYnkgdmVyc2lv
biBudW1iZXIuCgoNCgUECAIDBRIEpQICCAoNCgUECAIDARIEpQIJDwoNCgUECAIDAxIEpQIS
EwoNCgUECAIDCBIEpQIUPAoQCggECAIDCJwIABIEpQIVOwrvAQoEBAgCBBIEqwICPxrgASBP
cHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIGFydGlmYWN0IHRvIHN0YWdlLCBzdWNoIGFzCiBg
a2FyaXMuRUMuMTY0NjMuMi42LnRhci5iejJgIG9yIGByZXgvZmlybXdhcmVfZnJvbV9zb3Vy
Y2UudGFyLmJ6MmAgSWYKIHVuc3BlY2lmaWVkLCB0aGUgZGVmYXVsdCBhcnRpZmFjdHMgd2ls
bCBiZSBzdGFnZWQuIFRoaXMgb25seSBtYWtlcyBzZW5zZQogZm9yIGZpcm13YXJlIGFydGlm
YWN0cy4KCg0KBQQIAgQFEgSrAgIICg0KBQQIAgQBEgSrAgkRCg0KBQQIAgQDEgSrAhQVCg0K
BQQIAgQIEgSrAhY+ChAKCAQIAgQInAgAEgSrAhc9ClMKAgQJEgavAgC7AgEaRSBSZXNwb25z
ZSBtZXNzYWdlIGZvciBjaGVja2luZyB0aGUgc3RhZ2Ugc3RhdHVzIG9mIGEgYnVpbGQgYXJ0
aWZhY3QuCgoLCgMECQESBK8CCCUKRgoEBAkCABIEsQICGxo4IFRoZSBzdGF0dXMgdG8gcmVw
cmVzZW50IGlmIHRoZSBidWlsZCBpcyBzdGFnZWQgb3Igbm90LgoKDQoFBAkCAAUSBLECAgYK
DQoFBAkCAAESBLECBxYKDQoFBAkCAAMSBLECGRoKRAoEBAkCARIEtAICKho2IFRoZSBzdGFn
ZWQgYnVpbGQgYXJ0aWZhY3QgaW4gdGhlIGRlc3RpbmF0aW9uIGJ1Y2tldC4KCg0KBQQJAgEG
EgS0AgIPCg0KBQQJAgEBEgS0AhAlCg0KBQQJAgEDEgS0AigpCj8KBAQJAgISBLcCAioaMSBU
aGUgc291cmNlIGJ1aWxkIGFydGlmYWN0IGluIHRoZSBzb3VyY2UgYnVja2V0LgoKDQoFBAkC
AgYSBLcCAg8KDQoFBAkCAgESBLcCECUKDQoFBAkCAgMSBLcCKCkKRgoEBAkCAxIEugICRho4
IE9wdGlvbmFsLiBUaGUgY2xvdWQgYnVpbGQgaWYgdGhlIGJ1aWxkIGlkIGlzIHByb3ZpZGVk
LgoKDQoFBAkCAwYSBLoCAgwKDQoFBAkCAwESBLoCDRgKDQoFBAkCAwMSBLoCGxwKDQoFBAkC
AwgSBLoCHUUKEAoIBAkCAwicCAASBLoCHkQKPQoCBAoSBr4CANwCARovIFJlcXVlc3QgbWVz
c2FnZSBmb3Igc3RhZ2luZyBhIGJ1aWxkIGFydGlmYWN0LgoKCwoDBAoBEgS+AggZCrYBCgQE
CgIAEgbCAgLHAgQapQEgUmVxdWlyZWQuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhl
IGJ1aWxkIGFydGlmYWN0LgogRm9yIGV4YW1wbGUsCiAnYnVpbGRUYXJnZXRzL29jdG9wdXMv
bW9kZWxzL2JvYmJhL2J1aWxkcy8xMjYwNy42LjAvYXJ0aWZhY3RzL2Nocm9tZW9zLW1vYmxh
Yi1wZW5nLXN0YWdpbmcnLgoKDQoFBAoCAAUSBMICAggKDQoFBAoCAAESBMICCQ0KDQoFBAoC
AAMSBMICEBEKDwoFBAoCAAgSBsICEscCAwoQCggECgIACJwIABIEwwIEKgoRCgcECgIACJ8I
EgbEAgTGAgUKrwEKBAQKAgESBMwCAj0aoAEgT3B0aW9uYWwuIEZpbHRlciB0aGF0IHNwZWNp
ZmllcyB2YWx1ZSBjb25zdHJhaW50cyBvZiBmaWVsZHMuIEZvciBleGFtcGxlLAogdGhlIGZp
bHRlciBjYW4gYmUgc2V0IGFzICJmaWx0ZXI9J3R5cGU9cmVsZWFzZSciIHRvIG9ubHkgY2hl
Y2sgdGhlIHJlbGVhc2UKIGJ1aWxkcy4KCg0KBQQKAgEFEgTMAgIICg0KBQQKAgEBEgTMAgkP
Cg0KBQQKAgEDEgTMAhITCg0KBQQKAgEIEgTMAhQ8ChAKCAQKAgEInAgAEgTMAhU7CnAKBAQK
AgISBNACAkcaYiBPcHRpb25hbC4gVGhlIHNvdXJjZSBsb2NhdGlvbiBvZiB0aGUgYXJ0aWZh
Y3QsIGRlZmF1bHRzIHRvCiBgY2hyb21lb3MtaW1hZ2UtYXJjaGl2ZWAgaWYgbWlzc2luZy4K
Cg0KBQQKAgIFEgTQAgIICg0KBQQKAgIBEgTQAgkZCg0KBQQKAgIDEgTQAhwdCg0KBQQKAgII
EgTQAh5GChAKCAQKAgIInAgAEgTQAh9FCtYBCgQECgIDEgTVAgI9GscBIE9wdGlvbmFsLiBU
aGUgYnJhbmNoIGRpcmVjdG9yeSBpbiB0aGUgc291cmNlX2J1Y2tldF9pZCB3aGVyZSB0aGUg
YXJ0aWZhY3QKIGlzIGxvY2F0ZWQsIHN1Y2ggYXMgYGZpcm13YXJlLWVjLVIxNDMtMTY0NjMu
Mi5CYC4gSWYgdW5zcGVjaWZpZWQsIHRoZSBidWlsZAogd2lsbCBiZSBmb3VuZCBpbiBnb2xk
ZW5leWUgYnkgdmVyc2lvbiBudW1iZXIuCgoNCgUECgIDBRIE1QICCAoNCgUECgIDARIE1QIJ
DwoNCgUECgIDAxIE1QISEwoNCgUECgIDCBIE1QIUPAoQCggECgIDCJwIABIE1QIVOwrvAQoE
BAoCBBIE2wICPxrgASBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIGFydGlmYWN0IHRvIHN0
YWdlLCBzdWNoIGFzCiBga2FyaXMuRUMuMTY0NjMuMi42LnRhci5iejJgIG9yIGByZXgvZmly
bXdhcmVfZnJvbV9zb3VyY2UudGFyLmJ6MmAgSWYKIHVuc3BlY2lmaWVkLCB0aGUgZGVmYXVs
dCBhcnRpZmFjdHMgd2lsbCBiZSBzdGFnZWQuIFRoaXMgb25seSBtYWtlcyBzZW5zZQogZm9y
IGZpcm13YXJlIGFydGlmYWN0cy4KCg0KBQQKAgQFEgTbAgIICg0KBQQKAgQBEgTbAgkRCg0K
BQQKAgQDEgTbAhQVCg0KBQQKAgQIEgTbAhY+ChAKCAQKAgQInAgAEgTbAhc9Cj4KAgQLEgbf
AgDlAgEaMCBSZXNwb25zZSBtZXNzYWdlIGZvciBzdGFnaW5nIGEgYnVpbGQgYXJ0aWZhY3Qu
CgoLCgMECwESBN8CCBoKOwoEBAsCABIE4QICKhotIFRoZSBzdGFnZWQgYnVpbGQgaW4gdGhl
IGRlc3RpbmF0aW9uIGJ1Y2tldC4KCg0KBQQLAgAGEgThAgIPCg0KBQQLAgABEgThAhAlCg0K
BQQLAgADEgThAigpCjoKBAQLAgESBOQCAjEaLCBUaGUgY2xvdWQgYnVpbGQgaWQgb2YgdGhl
IGJ1aWxkIGFydGlmYWN0cy4KCg0KBQQLAgEGEgTkAgIMCg0KBQQLAgEBEgTkAg0YCg0KBQQL
AgEDEgTkAhscCg0KBQQLAgEIEgTkAh0wCg4KBgQLAgEIAxIE5AIeLwo+CgIEDBIG6AIA9AIB
GjAgTWV0YWRhdGEgbWVzc2FnZSBmb3Igc3RhZ2luZyBhIGJ1aWxkIGFydGlmYWN0LgoKCwoD
BAwBEgToAggaCkgKBAQMAgASBOoCAh0aOiBBcHByb3hpbWF0ZSBwZXJjZW50YWdlIG9mIHBy
b2dyZXNzLCBlLmcuICI1MCIgbWVhbnMgNTAlLgoKDQoFBAwCAAUSBOoCAgcKDQoFBAwCAAES
BOoCCBgKDQoFBAwCAAMSBOoCGxwKJwoEBAwCARIE7QICKxoZIEJ1aWxkIHN0YWdlIHN0YXJ0
IHRpbWUuCgoNCgUEDAIBBhIE7QICGwoNCgUEDAIBARIE7QIcJgoNCgUEDAIBAxIE7QIpKgol
CgQEDAICEgTwAgIpGhcgQnVpbGQgc3RhZ2UgZW5kIHRpbWUuCgoNCgUEDAICBhIE8AICGwoN
CgUEDAICARIE8AIcJAoNCgUEDAICAxIE8AInKAo3CgQEDAIDEgTzAgIdGikgVGhlIGNsb3Vk
IGJ1aWxkIG9mIHRoZSBidWlsZCBhcnRpZmFjdHMuCgoNCgUEDAIDBhIE8wICDAoNCgUEDAID
ARIE8wINGAoNCgUEDAIDAxIE8wIbHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildRequest ===
    # Fields for FindMostStableBuildRequest
    # Field: build_target Type: 9 ()
    # Field: model Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildResponse ===
    # Fields for FindMostStableBuildResponse
    # Field: build Type: 11 (.google.chromeos.moblab.v1beta1.Build)

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsRequest ===
    # Fields for ListBuildTargetsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsResponse ===
    # Fields for ListBuildTargetsResponse
    # Field: build_targets Type: 11 (.google.chromeos.moblab.v1beta1.BuildTarget)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.chromeos.moblab.v1beta1.Model)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsRequest ===
    # Fields for ListBuildsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: read_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: group_by Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsResponse ===
    # Fields for ListBuildsResponse
    # Field: builds Type: 11 (.google.chromeos.moblab.v1beta1.Build)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusRequest ===
    # Fields for CheckBuildStageStatusRequest
    # Field: name Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: source_bucket_id Type: 9 ()
    # Field: branch Type: 9 ()
    # Field: artifact Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusResponse ===
    # Fields for CheckBuildStageStatusResponse
    # Field: is_build_staged Type: 8 ()
    # Field: staged_build_artifact Type: 11 (.google.chromeos.moblab.v1beta1.BuildArtifact)
    # Field: source_build_artifact Type: 11 (.google.chromeos.moblab.v1beta1.BuildArtifact)
    # Field: cloud_build Type: 11 (.google.chromeos.moblab.v1beta1.CloudBuild)

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildRequest ===
    # Fields for StageBuildRequest
    # Field: name Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: source_bucket_id Type: 9 ()
    # Field: branch Type: 9 ()
    # Field: artifact Type: 9 ()

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildResponse ===
    # Fields for StageBuildResponse
    # Field: staged_build_artifact Type: 11 (.google.chromeos.moblab.v1beta1.BuildArtifact)
    # Field: cloud_build Type: 11 (.google.chromeos.moblab.v1beta1.CloudBuild)

# === Message: Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildMetadata ===
    # Fields for StageBuildMetadata
    # Field: progress_percent Type: 2 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: cloud_build Type: 11 (.google.chromeos.moblab.v1beta1.CloudBuild)

# === Service Client: Google::Chromeos::Moblab::V1beta1::BuildService::BuildServiceClient ===
package Google::Chromeos::Moblab::V1beta1::BuildService::BuildServiceClient;

=pod

=head2 Service Client: Google::Chromeos::Moblab::V1beta1::BuildService::BuildServiceClient

Client stub representing the remote C<BuildService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chromeos.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chromeos.googleapis.com:443' );

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

sub list_build_targets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.BuildService',
        method         => 'ListBuildTargets',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsResponse',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.BuildService',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsResponse',
    });
}

sub list_builds {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.BuildService',
        method         => 'ListBuilds',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsResponse',
    });
}

sub check_build_stage_status {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.BuildService',
        method         => 'CheckBuildStageStatus',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusResponse',
    });
}

sub stage_build {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.BuildService',
        method         => 'StageBuild',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub find_most_stable_build {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.chromeos.moblab.v1beta1.BuildService',
        method         => 'FindMostStableBuild',
        request        => $req,
        response_class => 'Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Chromeos::Moblab::V1beta1::BuildService - Compiled Protocol Buffers messages for google/chromeos/moblab/v1beta1/build_service.proto

=head1 SYNOPSIS

    use Google::Chromeos::Moblab::V1beta1::BuildService;

    my $msg = Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildRequest->new({
        build_target => $build_target,
        model => $model,
    });

    # Read or update a field
    my $val = $msg->build_target();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/chromeos/moblab/v1beta1/build_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildRequest

Request message for finding the most stable build.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->build_target() >> / C<< $msg->build_target($value) >>

Type: C<String>

Optional. The full resource name of the build target.
For example,
'buildTargets/octopus'.

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Optional. The full resource name of the build target or model.
For example,
'buildTargets/octopus/models/bobba'.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::FindMostStableBuildResponse

Response message for finding the most stable build.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->build() >> / C<< $msg->build($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::Build>)

The most stable build.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsRequest

Request message for listing build targets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The number of build targets to return in a page.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListBuildTargets` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter that specifies value constraints of fields. For example,
the filter can be set as "filter='model=modelName'" to only select build
targets associated with the given model.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsResponse

Response message for listing build targets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->build_targets() >> / C<< $msg->build_targets($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::BuildTarget>)

The list of build targets.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of build targets. If this field is omitted,
there are no subsequent pages.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

Total number of build targets.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsRequest

Request message for listing models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The full resource name of build target.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The number of models to return in a page.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListModels` call. Provide
this to retrieve the subsequent page.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsResponse

Response message for listing models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::Model>)

The list of models.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of models. If this field is omitted, there
are no subsequent pages.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

Total number of models.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsRequest

Request message for listing builds.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The full resource name of the model. The model id is the same as
the build target id for non-unified builds.
For example,
'buildTargets/octopus/models/bobba'.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The number of builds to return in a page.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListBuilds` call. Provide
this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter that specifies value constraints of fields. For example,
the filter can be set as "filter='milestone=milestones/80'" to only select
builds in milestone 80.

=item * C<< $msg->read_mask() >> / C<< $msg->read_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Read mask that specifies which Build fields to return. If empty,
all Build fields will be returned. Valid fields: name, milestone,
build_version. For example, if the read_mask is set as
"read_mask='milestone'", the ListBuilds will return a list of Builds object
with only the milestone field.

=item * C<< $msg->group_by() >> / C<< $msg->group_by($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The operation that groups by all the Build fields specified in
the read mask. The group_by field should be the same as the read_mask field
in convention of SQL.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildsResponse

Response message for listing builds.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->builds() >> / C<< $msg->builds($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::Build>)

The list of builds.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of builds. If this field is omitted, there
are no subsequent pages.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

Total number of builds.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusRequest

Request message for checking if the build artifact is staged.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the build artifact.
For example,
'buildTargets/octopus/models/bobba/builds/12607.6.0/artifacts/chromeos-moblab-peng-staging'.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter that specifies value constraints of fields. For example,
the filter can be set as "filter='type=release'" to only check the release
builds.

=item * C<< $msg->source_bucket_id() >> / C<< $msg->source_bucket_id($value) >>

Type: C<String>

Optional. The source location of the artifact, defaults to
`chromeos-image-archive` if missing.

=item * C<< $msg->branch() >> / C<< $msg->branch($value) >>

Type: C<String>

Optional. The branch directory in the source_bucket_id where the artifact
is located, such as `firmware-ec-R143-16463.2.B`. If unspecified, the build
will be found in goldeneye by version number.

=item * C<< $msg->artifact() >> / C<< $msg->artifact($value) >>

Type: C<String>

Optional. The name of the artifact to stage, such as
`karis.EC.16463.2.6.tar.bz2` or `rex/firmware_from_source.tar.bz2` If
unspecified, the default artifacts will be staged. This only makes sense
for firmware artifacts.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::CheckBuildStageStatusResponse

Response message for checking the stage status of a build artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->is_build_staged() >> / C<< $msg->is_build_staged($value) >>

Type: C<Bool>

The status to represent if the build is staged or not.

=item * C<< $msg->staged_build_artifact() >> / C<< $msg->staged_build_artifact($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::BuildArtifact>)

The staged build artifact in the destination bucket.

=item * C<< $msg->source_build_artifact() >> / C<< $msg->source_build_artifact($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::BuildArtifact>)

The source build artifact in the source bucket.

=item * C<< $msg->cloud_build() >> / C<< $msg->cloud_build($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::CloudBuild>)

Optional. The cloud build if the build id is provided.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildRequest

Request message for staging a build artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The full resource name of the build artifact.
For example,
'buildTargets/octopus/models/bobba/builds/12607.6.0/artifacts/chromeos-moblab-peng-staging'.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter that specifies value constraints of fields. For example,
the filter can be set as "filter='type=release'" to only check the release
builds.

=item * C<< $msg->source_bucket_id() >> / C<< $msg->source_bucket_id($value) >>

Type: C<String>

Optional. The source location of the artifact, defaults to
`chromeos-image-archive` if missing.

=item * C<< $msg->branch() >> / C<< $msg->branch($value) >>

Type: C<String>

Optional. The branch directory in the source_bucket_id where the artifact
is located, such as `firmware-ec-R143-16463.2.B`. If unspecified, the build
will be found in goldeneye by version number.

=item * C<< $msg->artifact() >> / C<< $msg->artifact($value) >>

Type: C<String>

Optional. The name of the artifact to stage, such as
`karis.EC.16463.2.6.tar.bz2` or `rex/firmware_from_source.tar.bz2` If
unspecified, the default artifacts will be staged. This only makes sense
for firmware artifacts.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildResponse

Response message for staging a build artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->staged_build_artifact() >> / C<< $msg->staged_build_artifact($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::BuildArtifact>)

The staged build in the destination bucket.

=item * C<< $msg->cloud_build() >> / C<< $msg->cloud_build($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::CloudBuild>)

The cloud build id of the build artifacts.

=back

=head2 Google::Chromeos::Moblab::V1beta1::BuildService::StageBuildMetadata

Metadata message for staging a build artifact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Float>

Approximate percentage of progress, e.g. "50" means 50%.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Build stage start time.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Build stage end time.

=item * C<< $msg->cloud_build() >> / C<< $msg->cloud_build($value) >>

Type: C<Message> (L<Google::Chromeos::Moblab::V1beta1::Resources::CloudBuild>)

The cloud build of the build artifacts.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Chromeos::Moblab::V1beta1::BuildService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
