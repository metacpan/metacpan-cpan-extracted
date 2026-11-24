package Google::Monitoring::V3::ServiceService;

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
    eval { require Google::Monitoring::V3::Service };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvbW9uaXRvcmluZy92My9zZXJ2aWNlX3NlcnZpY2UucHJvdG8SFGdvb2dsZS5t
b25pdG9yaW5nLnYzGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBp
L2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxoiZ29vZ2xlL21vbml0b3JpbmcvdjMvc2VydmljZS5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90byK2AQoUQ3JlYXRlU2VydmljZVJlcXVlc3QSQQoGcGFyZW50GAEgASgJQing
QQL6QSMSIW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vU2VydmljZVIGcGFyZW50Eh0KCnNl
cnZpY2VfaWQYAyABKAlSCXNlcnZpY2VJZBI8CgdzZXJ2aWNlGAIgASgLMh0uZ29vZ2xlLm1v
bml0b3JpbmcudjMuU2VydmljZUID4EECUgdzZXJ2aWNlIlIKEUdldFNlcnZpY2VSZXF1ZXN0
Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohbW9uaXRvcmluZy5nb29nbGVhcGlzLmNvbS9TZXJ2
aWNlUgRuYW1lIqwBChNMaXN0U2VydmljZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC
+kEjEiFtb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VSBnBhcmVudBIWCgZmaWx0
ZXIYAiABKAlSBmZpbHRlchIbCglwYWdlX3NpemUYAyABKAVSCHBhZ2VTaXplEh0KCnBhZ2Vf
dG9rZW4YBCABKAlSCXBhZ2VUb2tlbiJ5ChRMaXN0U2VydmljZXNSZXNwb25zZRI5CghzZXJ2
aWNlcxgBIAMoCzIdLmdvb2dsZS5tb25pdG9yaW5nLnYzLlNlcnZpY2VSCHNlcnZpY2VzEiYK
D25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiKRAQoUVXBkYXRlU2Vydmlj
ZVJlcXVlc3QSPAoHc2VydmljZRgBIAEoCzIdLmdvb2dsZS5tb25pdG9yaW5nLnYzLlNlcnZp
Y2VCA+BBAlIHc2VydmljZRI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2siVQoURGVsZXRlU2VydmljZVJlcXVlc3QSPQoEbmFt
ZRgBIAEoCUIp4EEC+kEjCiFtb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VSBG5h
bWUijgIKIkNyZWF0ZVNlcnZpY2VMZXZlbE9iamVjdGl2ZVJlcXVlc3QSQQoGcGFyZW50GAEg
ASgJQingQQL6QSMKIW1vbml0b3JpbmcuZ29vZ2xlYXBpcy5jb20vU2VydmljZVIGcGFyZW50
EjsKGnNlcnZpY2VfbGV2ZWxfb2JqZWN0aXZlX2lkGAMgASgJUhdzZXJ2aWNlTGV2ZWxPYmpl
Y3RpdmVJZBJoChdzZXJ2aWNlX2xldmVsX29iamVjdGl2ZRgCIAEoCzIrLmdvb2dsZS5tb25p
dG9yaW5nLnYzLlNlcnZpY2VMZXZlbE9iamVjdGl2ZUID4EECUhVzZXJ2aWNlTGV2ZWxPYmpl
Y3RpdmUitAEKH0dldFNlcnZpY2VMZXZlbE9iamVjdGl2ZVJlcXVlc3QSSwoEbmFtZRgBIAEo
CUI34EEC+kExCi9tb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VMZXZlbE9iamVj
dGl2ZVIEbmFtZRJECgR2aWV3GAIgASgOMjAuZ29vZ2xlLm1vbml0b3JpbmcudjMuU2Vydmlj
ZUxldmVsT2JqZWN0aXZlLlZpZXdSBHZpZXcigAIKIUxpc3RTZXJ2aWNlTGV2ZWxPYmplY3Rp
dmVzUmVxdWVzdBJBCgZwYXJlbnQYASABKAlCKeBBAvpBIwohbW9uaXRvcmluZy5nb29nbGVh
cGlzLmNvbS9TZXJ2aWNlUgZwYXJlbnQSFgoGZmlsdGVyGAIgASgJUgZmaWx0ZXISGwoJcGFn
ZV9zaXplGAMgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAQgASgJUglwYWdlVG9rZW4S
RAoEdmlldxgFIAEoDjIwLmdvb2dsZS5tb25pdG9yaW5nLnYzLlNlcnZpY2VMZXZlbE9iamVj
dGl2ZS5WaWV3UgR2aWV3IrMBCiJMaXN0U2VydmljZUxldmVsT2JqZWN0aXZlc1Jlc3BvbnNl
EmUKGHNlcnZpY2VfbGV2ZWxfb2JqZWN0aXZlcxgBIAMoCzIrLmdvb2dsZS5tb25pdG9yaW5n
LnYzLlNlcnZpY2VMZXZlbE9iamVjdGl2ZVIWc2VydmljZUxldmVsT2JqZWN0aXZlcxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iywEKIlVwZGF0ZVNlcnZpY2VM
ZXZlbE9iamVjdGl2ZVJlcXVlc3QSaAoXc2VydmljZV9sZXZlbF9vYmplY3RpdmUYASABKAsy
Ky5nb29nbGUubW9uaXRvcmluZy52My5TZXJ2aWNlTGV2ZWxPYmplY3RpdmVCA+BBAlIVc2Vy
dmljZUxldmVsT2JqZWN0aXZlEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJxCiJEZWxldGVTZXJ2aWNlTGV2ZWxPYmplY3Rp
dmVSZXF1ZXN0EksKBG5hbWUYASABKAlCN+BBAvpBMQovbW9uaXRvcmluZy5nb29nbGVhcGlz
LmNvbS9TZXJ2aWNlTGV2ZWxPYmplY3RpdmVSBG5hbWUy6g8KGFNlcnZpY2VNb25pdG9yaW5n
U2VydmljZRKXAQoNQ3JlYXRlU2VydmljZRIqLmdvb2dsZS5tb25pdG9yaW5nLnYzLkNyZWF0
ZVNlcnZpY2VSZXF1ZXN0Gh0uZ29vZ2xlLm1vbml0b3JpbmcudjMuU2VydmljZSI7gtPkkwIk
IhkvdjMve3BhcmVudD0qLyp9L3NlcnZpY2VzOgdzZXJ2aWNl2kEOcGFyZW50LHNlcnZpY2US
fgoKR2V0U2VydmljZRInLmdvb2dsZS5tb25pdG9yaW5nLnYzLkdldFNlcnZpY2VSZXF1ZXN0
Gh0uZ29vZ2xlLm1vbml0b3JpbmcudjMuU2VydmljZSIogtPkkwIbEhkvdjMve25hbWU9Ki8q
L3NlcnZpY2VzLyp92kEEbmFtZRKRAQoMTGlzdFNlcnZpY2VzEikuZ29vZ2xlLm1vbml0b3Jp
bmcudjMuTGlzdFNlcnZpY2VzUmVxdWVzdBoqLmdvb2dsZS5tb25pdG9yaW5nLnYzLkxpc3RT
ZXJ2aWNlc1Jlc3BvbnNlIiqC0+STAhsSGS92My97cGFyZW50PSovKn0vc2VydmljZXPaQQZw
YXJlbnQSmAEKDVVwZGF0ZVNlcnZpY2USKi5nb29nbGUubW9uaXRvcmluZy52My5VcGRhdGVT
ZXJ2aWNlUmVxdWVzdBodLmdvb2dsZS5tb25pdG9yaW5nLnYzLlNlcnZpY2UiPILT5JMCLDIh
L3YzL3tzZXJ2aWNlLm5hbWU9Ki8qL3NlcnZpY2VzLyp9OgdzZXJ2aWNl2kEHc2VydmljZRJ9
Cg1EZWxldGVTZXJ2aWNlEiouZ29vZ2xlLm1vbml0b3JpbmcudjMuRGVsZXRlU2VydmljZVJl
cXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiKILT5JMCGyoZL3YzL3tuYW1lPSovKi9z
ZXJ2aWNlcy8qfdpBBG5hbWUS+gEKG0NyZWF0ZVNlcnZpY2VMZXZlbE9iamVjdGl2ZRI4Lmdv
b2dsZS5tb25pdG9yaW5nLnYzLkNyZWF0ZVNlcnZpY2VMZXZlbE9iamVjdGl2ZVJlcXVlc3Qa
Ky5nb29nbGUubW9uaXRvcmluZy52My5TZXJ2aWNlTGV2ZWxPYmplY3RpdmUidILT5JMCTSIy
L3YzL3twYXJlbnQ9Ki8qL3NlcnZpY2VzLyp9L3NlcnZpY2VMZXZlbE9iamVjdGl2ZXM6F3Nl
cnZpY2VfbGV2ZWxfb2JqZWN0aXZl2kEecGFyZW50LHNlcnZpY2VfbGV2ZWxfb2JqZWN0aXZl
EsEBChhHZXRTZXJ2aWNlTGV2ZWxPYmplY3RpdmUSNS5nb29nbGUubW9uaXRvcmluZy52My5H
ZXRTZXJ2aWNlTGV2ZWxPYmplY3RpdmVSZXF1ZXN0GisuZ29vZ2xlLm1vbml0b3JpbmcudjMu
U2VydmljZUxldmVsT2JqZWN0aXZlIkGC0+STAjQSMi92My97bmFtZT0qLyovc2VydmljZXMv
Ki9zZXJ2aWNlTGV2ZWxPYmplY3RpdmVzLyp92kEEbmFtZRLUAQoaTGlzdFNlcnZpY2VMZXZl
bE9iamVjdGl2ZXMSNy5nb29nbGUubW9uaXRvcmluZy52My5MaXN0U2VydmljZUxldmVsT2Jq
ZWN0aXZlc1JlcXVlc3QaOC5nb29nbGUubW9uaXRvcmluZy52My5MaXN0U2VydmljZUxldmVs
T2JqZWN0aXZlc1Jlc3BvbnNlIkOC0+STAjQSMi92My97cGFyZW50PSovKi9zZXJ2aWNlcy8q
fS9zZXJ2aWNlTGV2ZWxPYmplY3RpdmVz2kEGcGFyZW50EowCChtVcGRhdGVTZXJ2aWNlTGV2
ZWxPYmplY3RpdmUSOC5nb29nbGUubW9uaXRvcmluZy52My5VcGRhdGVTZXJ2aWNlTGV2ZWxP
YmplY3RpdmVSZXF1ZXN0GisuZ29vZ2xlLm1vbml0b3JpbmcudjMuU2VydmljZUxldmVsT2Jq
ZWN0aXZlIoUBgtPkkwJlMkovdjMve3NlcnZpY2VfbGV2ZWxfb2JqZWN0aXZlLm5hbWU9Ki8q
L3NlcnZpY2VzLyovc2VydmljZUxldmVsT2JqZWN0aXZlcy8qfToXc2VydmljZV9sZXZlbF9v
YmplY3RpdmXaQRdzZXJ2aWNlX2xldmVsX29iamVjdGl2ZRKyAQobRGVsZXRlU2VydmljZUxl
dmVsT2JqZWN0aXZlEjguZ29vZ2xlLm1vbml0b3JpbmcudjMuRGVsZXRlU2VydmljZUxldmVs
T2JqZWN0aXZlUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJBgtPkkwI0KjIvdjMv
e25hbWU9Ki8qL3NlcnZpY2VzLyovc2VydmljZUxldmVsT2JqZWN0aXZlcy8qfdpBBG5hbWUa
qQHKQRltb25pdG9yaW5nLmdvb2dsZWFwaXMuY29t0kGJAWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9tb25pdG9yaW5nLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvbW9uaXRv
cmluZy5yZWFkQtgBChhjb20uZ29vZ2xlLm1vbml0b3JpbmcudjNCHVNlcnZpY2VNb25pdG9y
aW5nU2VydmljZVByb3RvUAFaQWNsb3VkLmdvb2dsZS5jb20vZ28vbW9uaXRvcmluZy9hcGl2
My92Mi9tb25pdG9yaW5ncGI7bW9uaXRvcmluZ3BiqgIaR29vZ2xlLkNsb3VkLk1vbml0b3Jp
bmcuVjPKAhpHb29nbGVcQ2xvdWRcTW9uaXRvcmluZ1xWM+oCHUdvb2dsZTo6Q2xvdWQ6Ok1v
bml0b3Jpbmc6OlYzSr9WCgcSBQ4A6AIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
bnNlLgoKCAoBAhIDEAAdCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYALAoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgA3CgkKAggl
EgMaADcKCAoBCBIDGwBYCgkKAggLEgMbAFgKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBID
HQA+CgkKAggIEgMdAD4KCAoBCBIDHgAxCgkKAggBEgMeADEKCAoBCBIDHwA3CgkKAggpEgMf
ADcKCAoBCBIDIAA2CgkKAggtEgMgADYKlQIKAgYAEgUmAIUBARqHAiBUaGUgQ2xvdWQgTW9u
aXRvcmluZyBTZXJ2aWNlLU9yaWVudGVkIE1vbml0b3JpbmcgQVBJIGhhcyBlbmRwb2ludHMg
Zm9yCiBtYW5hZ2luZyBhbmQgcXVlcnlpbmcgYXNwZWN0cyBvZiBhIE1ldHJpY3MgU2NvcGUn
cyBzZXJ2aWNlcy4gVGhlc2UgaW5jbHVkZQogdGhlIGBTZXJ2aWNlYCdzIG1vbml0b3JlZCBy
ZXNvdXJjZXMsIGl0cyBTZXJ2aWNlLUxldmVsIE9iamVjdGl2ZXMsIGFuZCBhCiB0YXhvbm9t
eSBvZiBjYXRlZ29yaXplZCBIZWFsdGggTWV0cmljcy4KCgoKAwYAARIDJgggCgoKAwYAAxID
JwJBCgwKBQYAA5kIEgMnAkEKCwoDBgADEgQoAis4Cg0KBQYAA5oIEgQoAis4CiMKBAYAAgAS
BC4CNAMaFSBDcmVhdGUgYSBgU2VydmljZWAuCgoMCgUGAAIAARIDLgYTCgwKBQYAAgACEgMu
FCgKDAoFBgACAAMSAy4zOgoNCgUGAAIABBIELwQyBgoRCgkGAAIABLDKvCISBC8EMgYKDAoF
BgACAAQSAzMEPAoPCggGAAIABJsIABIDMwQ8CigKBAYAAgESBDcCPAMaGiBHZXQgdGhlIG5h
bWVkIGBTZXJ2aWNlYC4KCgwKBQYAAgEBEgM3BhAKDAoFBgACAQISAzcRIgoMCgUGAAIBAxID
Ny00Cg0KBQYAAgEEEgQ4BDoGChEKCQYAAgEEsMq8IhIEOAQ6BgoMCgUGAAIBBBIDOwQyCg8K
CAYAAgEEmwgAEgM7BDIKNwoEBgACAhIEPwJEAxopIExpc3QgYFNlcnZpY2VgcyBmb3IgdGhp
cyBNZXRyaWNzIFNjb3BlLgoKDAoFBgACAgESAz8GEgoMCgUGAAICAhIDPxMmCgwKBQYAAgID
EgM/MUUKDQoFBgACAgQSBEAEQgYKEQoJBgACAgSwyrwiEgRABEIGCgwKBQYAAgIEEgNDBDQK
DwoIBgACAgSbCAASA0MENAomCgQGAAIDEgRHAk0DGhggVXBkYXRlIHRoaXMgYFNlcnZpY2Vg
LgoKDAoFBgACAwESA0cGEwoMCgUGAAIDAhIDRxQoCgwKBQYAAgMDEgNHMzoKDQoFBgACAwQS
BEgESwYKEQoJBgACAwSwyrwiEgRIBEsGCgwKBQYAAgMEEgNMBDUKDwoIBgACAwSbCAASA0wE
NQorCgQGAAIEEgRQAlUDGh0gU29mdCBkZWxldGUgdGhpcyBgU2VydmljZWAuCgoMCgUGAAIE
ARIDUAYTCgwKBQYAAgQCEgNQFCgKDAoFBgACBAMSA1AzSAoNCgUGAAIEBBIEUQRTBgoRCgkG
AAIEBLDKvCISBFEEUwYKDAoFBgACBAQSA1QEMgoPCggGAAIEBJsIABIDVAQyCkkKBAYAAgUS
BFgCXwMaOyBDcmVhdGUgYSBgU2VydmljZUxldmVsT2JqZWN0aXZlYCBmb3IgdGhlIGdpdmVu
IGBTZXJ2aWNlYC4KCgwKBQYAAgUBEgNYBiEKDAoFBgACBQISA1giRAoMCgUGAAIFAxIDWQ8k
Cg0KBQYAAgUEEgRaBF0GChEKCQYAAgUEsMq8IhIEWgRdBgoMCgUGAAIFBBIDXgRMCg8KCAYA
AgUEmwgAEgNeBEwKNgoEBgACBhIEYgJoAxooIEdldCBhIGBTZXJ2aWNlTGV2ZWxPYmplY3Rp
dmVgIGJ5IG5hbWUuCgoMCgUGAAIGARIDYgYeCgwKBQYAAgYCEgNiHz4KDAoFBgACBgMSA2MP
JAoNCgUGAAIGBBIEZARmBgoRCgkGAAIGBLDKvCISBGQEZgYKDAoFBgACBgQSA2cEMgoPCggG
AAIGBJsIABIDZwQyCkoKBAYAAgcSBGsCcQMaPCBMaXN0IHRoZSBgU2VydmljZUxldmVsT2Jq
ZWN0aXZlYHMgZm9yIHRoZSBnaXZlbiBgU2VydmljZWAuCgoMCgUGAAIHARIDawYgCgwKBQYA
AgcCEgNrIUIKDAoFBgACBwMSA2wPMQoNCgUGAAIHBBIEbQRvBgoRCgkGAAIHBLDKvCISBG0E
bwYKDAoFBgACBwQSA3AENAoPCggGAAIHBJsIABIDcAQ0CjkKBAYAAggSBHQCewMaKyBVcGRh
dGUgdGhlIGdpdmVuIGBTZXJ2aWNlTGV2ZWxPYmplY3RpdmVgLgoKDAoFBgACCAESA3QGIQoM
CgUGAAIIAhIDdCJECgwKBQYAAggDEgN1DyQKDQoFBgACCAQSBHYEeQYKEQoJBgACCASwyrwi
EgR2BHkGCgwKBQYAAggEEgN6BEUKDwoIBgACCASbCAASA3oERQo6CgQGAAIJEgV+AoQBAxor
IERlbGV0ZSB0aGUgZ2l2ZW4gYFNlcnZpY2VMZXZlbE9iamVjdGl2ZWAuCgoMCgUGAAIJARID
fgYhCgwKBQYAAgkCEgN+IkQKDAoFBgACCQMSA38PJAoPCgUGAAIJBBIGgAEEggEGChMKCQYA
AgkEsMq8IhIGgAEEggEGCg0KBQYAAgkEEgSDAQQyChAKCAYAAgkEmwgAEgSDAQQyCiwKAgQA
EgaIAQCbAQEaHiBUaGUgYENyZWF0ZVNlcnZpY2VgIHJlcXVlc3QuCgoLCgMEAAESBIgBCBwK
uQEKBAQAAgASBo4BApMBBBqoASBSZXF1aXJlZC4gUmVzb3VyY2UKIFtuYW1lXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vbW9uaXRvcmluZy9hcGkvdjMjcHJvamVjdF9uYW1lKSBvZiB0
aGUKIHBhcmVudCBNZXRyaWNzIFNjb3BlLiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9qZWN0
cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdCgoNCgUEAAIABRIEjgECCAoNCgUEAAIAARIEjgEJ
DwoNCgUEAAIAAxIEjgESEwoPCgUEAAIACBIGjgEUkwEDChAKCAQAAgAInAgAEgSPAQQqChEK
BwQAAgAInwgSBpABBJIBBQqVAQoEBAACARIElwECGBqGASBPcHRpb25hbC4gVGhlIFNlcnZp
Y2UgaWQgdG8gdXNlIGZvciB0aGlzIFNlcnZpY2UuIElmIG9taXR0ZWQsIGFuIGlkIHdpbGwg
YmUKIGdlbmVyYXRlZCBpbnN0ZWFkLiBNdXN0IG1hdGNoIHRoZSBwYXR0ZXJuIGBbYS16MC05
XC1dK2AKCg0KBQQAAgEFEgSXAQIICg0KBQQAAgEBEgSXAQkTCg0KBQQAAgEDEgSXARYXCjIK
BAQAAgISBJoBAj8aJCBSZXF1aXJlZC4gVGhlIGBTZXJ2aWNlYCB0byBjcmVhdGUuCgoNCgUE
AAICBhIEmgECCQoNCgUEAAICARIEmgEKEQoNCgUEAAICAxIEmgEUFQoNCgUEAAICCBIEmgEW
PgoQCggEAAICCJwIABIEmgEXPQopCgIEARIGngEAqAEBGhsgVGhlIGBHZXRTZXJ2aWNlYCBy
ZXF1ZXN0LgoKCwoDBAEBEgSeAQgZCoYBCgQEAQIAEgaiAQKnAQQadiBSZXF1aXJlZC4gUmVz
b3VyY2UgbmFtZSBvZiB0aGUgYFNlcnZpY2VgLiBUaGUgZm9ybWF0IGlzOgoKICAgICBwcm9q
ZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL3NlcnZpY2VzL1tTRVJWSUNFX0lEXQoKDQoF
BAECAAUSBKIBAggKDQoFBAECAAESBKIBCQ0KDQoFBAECAAMSBKIBEBEKDwoFBAECAAgSBqIB
EqcBAwoQCggEAQIACJwIABIEowEEKgoRCgcEAQIACJ8IEgakAQSmAQUKKwoCBAISBqsBANUB
ARodIFRoZSBgTGlzdFNlcnZpY2VzYCByZXF1ZXN0LgoKCwoDBAIBEgSrAQgbCqgCCgQEAgIA
EgayAQK3AQQalwIgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHBhcmVudCBjb250
YWluaW5nIHRoZSBsaXN0ZWQgc2VydmljZXMsCiBlaXRoZXIgYSBbcHJvamVjdF0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL21vbml0b3JpbmcvYXBpL3YzI3Byb2plY3RfbmFtZSkKIG9y
IGEgTW9uaXRvcmluZyBNZXRyaWNzIFNjb3BlLiBUaGUgZm9ybWF0cyBhcmU6CgogICAgIHBy
b2plY3RzL1tQUk9KRUNUX0lEX09SX05VTUJFUl0KICAgICB3b3Jrc3BhY2VzL1tIT1NUX1BS
T0pFQ1RfSURfT1JfTlVNQkVSXQoKDQoFBAICAAUSBLIBAggKDQoFBAICAAESBLIBCQ8KDQoF
BAICAAMSBLIBEhMKDwoFBAICAAgSBrIBFLcBAwoQCggEAgIACJwIABIEswEEKgoRCgcEAgIA
CJ8IEga0AQS2AQUK5AgKBAQCAgESBMsBAhQa1QggQSBmaWx0ZXIgc3BlY2lmeWluZyB3aGF0
IGBTZXJ2aWNlYHMgdG8gcmV0dXJuLiBUaGUgZmlsdGVyIHN1cHBvcnRzCiBmaWx0ZXJpbmcg
b24gYSBwYXJ0aWN1bGFyIHNlcnZpY2UtaWRlbnRpZmllciB0eXBlIG9yIG9uZSBvZiBpdHMg
YXR0cmlidXRlcy4KCiBUbyBmaWx0ZXIgb24gYSBwYXJ0aWN1bGFyIHNlcnZpY2UtaWRlbnRp
ZmllciB0eXBlLCB0aGUgYGlkZW50aWZpZXJfY2FzZWAKIHJlZmVycyB0byB3aGljaCBvcHRp
b24gaW4gdGhlIGBpZGVudGlmaWVyYCBmaWVsZCBpcyBwb3B1bGF0ZWQuIEZvciBleGFtcGxl
LAogdGhlIGZpbHRlciBgaWRlbnRpZmllcl9jYXNlID0gIkNVU1RPTSJgIHdvdWxkIG1hdGNo
IGFsbCBzZXJ2aWNlcyB3aXRoIGEKIHZhbHVlIGZvciB0aGUgYGN1c3RvbWAgZmllbGQuIFZh
bGlkIG9wdGlvbnMgaW5jbHVkZSAiQ1VTVE9NIiwgIkFQUF9FTkdJTkUiLAogIk1FU0hfSVNU
SU8iLCBhbmQgdGhlIG90aGVyIG9wdGlvbnMgbGlzdGVkIGF0CiBodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vbW9uaXRvcmluZy9hcGkvcmVmX3YzL3Jlc3QvdjMvc2VydmljZXMjU2Vydmlj
ZQoKIFRvIGZpbHRlciBvbiBhbiBhdHRyaWJ1dGUgb2YgYSBzZXJ2aWNlLWlkZW50aWZpZXIg
dHlwZSwgYXBwbHkgdGhlIGZpbHRlcgogbmFtZSBieSB1c2luZyB0aGUgc25ha2UgY2FzZSBv
ZiB0aGUgc2VydmljZS1pZGVudGlmaWVyIHR5cGUgYW5kIHRoZQogYXR0cmlidXRlIG9mIHRo
YXQgc2VydmljZS1pZGVudGlmaWVyIHR5cGUsIGFuZCBqb2luIHRoZSB0d28gd2l0aCBhIHBl
cmlvZC4KIEZvciBleGFtcGxlLCB0byBmaWx0ZXIgYnkgdGhlIGBtZXNoVWlkYCBmaWVsZCBv
ZiB0aGUgYE1lc2hJc3Rpb2AKIHNlcnZpY2UtaWRlbnRpZmllciB0eXBlLCB5b3UgbXVzdCBm
aWx0ZXIgb24gYG1lc2hfaXN0aW8ubWVzaF91aWQgPQogIjEyMyJgIHRvIG1hdGNoIGFsbCBz
ZXJ2aWNlcyB3aXRoIG1lc2ggVUlEICIxMjMiLiBTZXJ2aWNlLWlkZW50aWZpZXIgdHlwZXMK
IGFuZCB0aGVpciBhdHRyaWJ1dGVzIGFyZSBkZXNjcmliZWQgYXQKIGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9tb25pdG9yaW5nL2FwaS9yZWZfdjMvcmVzdC92My9zZXJ2aWNlcyNTZXJ2
aWNlCgoNCgUEAgIBBRIEywECCAoNCgUEAgIBARIEywEJDwoNCgUEAgIBAxIEywESEwp2CgQE
AgICEgTPAQIWGmggQSBub24tbmVnYXRpdmUgbnVtYmVyIHRoYXQgaXMgdGhlIG1heGltdW0g
bnVtYmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuLgogV2hlbiAwLCB1c2UgZGVmYXVsdCBwYWdl
IHNpemUuCgoNCgUEAgICBRIEzwECBwoNCgUEAgICARIEzwEIEQoNCgUEAgICAxIEzwEUFQro
AQoEBAICAxIE1AECGBrZASBJZiB0aGlzIGZpZWxkIGlzIG5vdCBlbXB0eSB0aGVuIGl0IG11
c3QgY29udGFpbiB0aGUgYG5leHRQYWdlVG9rZW5gIHZhbHVlCiByZXR1cm5lZCBieSBhIHBy
ZXZpb3VzIGNhbGwgdG8gdGhpcyBtZXRob2QuICBVc2luZyB0aGlzIGZpZWxkIGNhdXNlcyB0
aGUKIG1ldGhvZCB0byByZXR1cm4gYWRkaXRpb25hbCByZXN1bHRzIGZyb20gdGhlIHByZXZp
b3VzIG1ldGhvZCBjYWxsLgoKDQoFBAICAwUSBNQBAggKDQoFBAICAwESBNQBCRMKDQoFBAIC
AwMSBNQBFhcKLAoCBAMSBtgBAOABARoeIFRoZSBgTGlzdFNlcnZpY2VzYCByZXNwb25zZS4K
CgsKAwQDARIE2AEIHAo9CgQEAwIAEgTaAQIgGi8gVGhlIGBTZXJ2aWNlYHMgbWF0Y2hpbmcg
dGhlIHNwZWNpZmllZCBmaWx0ZXIuCgoNCgUEAwIABBIE2gECCgoNCgUEAwIABhIE2gELEgoN
CgUEAwIAARIE2gETGwoNCgUEAwIAAxIE2gEeHwrSAQoEBAMCARIE3wECHRrDASBJZiB0aGVy
ZSBhcmUgbW9yZSByZXN1bHRzIHRoYW4gaGF2ZSBiZWVuIHJldHVybmVkLCB0aGVuIHRoaXMg
ZmllbGQgaXMgc2V0CiB0byBhIG5vbi1lbXB0eSB2YWx1ZS4gIFRvIHNlZSB0aGUgYWRkaXRp
b25hbCByZXN1bHRzLAogdXNlIHRoYXQgdmFsdWUgYXMgYHBhZ2VfdG9rZW5gIGluIHRoZSBu
ZXh0IGNhbGwgdG8gdGhpcyBtZXRob2QuCgoNCgUEAwIBBRIE3wECCAoNCgUEAwIBARIE3wEJ
GAoNCgUEAwIBAxIE3wEbHAosCgIEBBIG4wEA6gEBGh4gVGhlIGBVcGRhdGVTZXJ2aWNlYCBy
ZXF1ZXN0LgoKCwoDBAQBEgTjAQgcCnEKBAQEAgASBOYBAj8aYyBSZXF1aXJlZC4gVGhlIGBT
ZXJ2aWNlYCB0byBkcmF3IHVwZGF0ZXMgZnJvbS4KIFRoZSBnaXZlbiBgbmFtZWAgc3BlY2lm
aWVzIHRoZSByZXNvdXJjZSB0byB1cGRhdGUuCgoNCgUEBAIABhIE5gECCQoNCgUEBAIAARIE
5gEKEQoNCgUEBAIAAxIE5gEUFQoNCgUEBAIACBIE5gEWPgoQCggEBAIACJwIABIE5gEXPQpR
CgQEBAIBEgTpAQIsGkMgQSBzZXQgb2YgZmllbGQgcGF0aHMgZGVmaW5pbmcgd2hpY2ggZmll
bGRzIHRvIHVzZSBmb3IgdGhlIHVwZGF0ZS4KCg0KBQQEAgEGEgTpAQIbCg0KBQQEAgEBEgTp
ARwnCg0KBQQEAgEDEgTpASorCiwKAgQFEgbtAQD3AQEaHiBUaGUgYERlbGV0ZVNlcnZpY2Vg
IHJlcXVlc3QuCgoLCgMEBQESBO0BCBwKkQEKBAQFAgASBvEBAvYBBBqAASBSZXF1aXJlZC4g
UmVzb3VyY2UgbmFtZSBvZiB0aGUgYFNlcnZpY2VgIHRvIGRlbGV0ZS4gVGhlIGZvcm1hdCBp
czoKCiAgICAgcHJvamVjdHMvW1BST0pFQ1RfSURfT1JfTlVNQkVSXS9zZXJ2aWNlcy9bU0VS
VklDRV9JRF0KCg0KBQQFAgAFEgTxAQIICg0KBQQFAgABEgTxAQkNCg0KBQQFAgADEgTxARAR
Cg8KBQQFAgAIEgbxARL2AQMKEAoIBAUCAAicCAASBPIBBCoKEQoHBAUCAAifCBIG8wEE9QEF
CjoKAgQGEgb6AQCPAgEaLCBUaGUgYENyZWF0ZVNlcnZpY2VMZXZlbE9iamVjdGl2ZWAgcmVx
dWVzdC4KCgsKAwQGARIE+gEIKgqNAQoEBAYCABIG/gECgwIEGn0gUmVxdWlyZWQuIFJlc291
cmNlIG5hbWUgb2YgdGhlIHBhcmVudCBgU2VydmljZWAuIFRoZSBmb3JtYXQgaXM6CgogICAg
IHByb2plY3RzL1tQUk9KRUNUX0lEX09SX05VTUJFUl0vc2VydmljZXMvW1NFUlZJQ0VfSURd
CgoNCgUEBgIABRIE/gECCAoNCgUEBgIAARIE/gEJDwoNCgUEBgIAAxIE/gESEwoPCgUEBgIA
CBIG/gEUgwIDChAKCAQGAgAInAgAEgT/AQQqChEKBwQGAgAInwgSBoACBIICBQq5AQoEBAYC
ARIEiAICKBqqASBPcHRpb25hbC4gVGhlIFNlcnZpY2VMZXZlbE9iamVjdGl2ZSBpZCB0byB1
c2UgZm9yIHRoaXMKIFNlcnZpY2VMZXZlbE9iamVjdGl2ZS4gSWYgb21pdHRlZCwgYW4gaWQg
d2lsbCBiZSBnZW5lcmF0ZWQgaW5zdGVhZC4gTXVzdAogbWF0Y2ggdGhlIHBhdHRlcm4gYF5b
YS16QS1aMC05LV86Ll0rJGAKCg0KBQQGAgEFEgSIAgIICg0KBQQGAgEBEgSIAgkjCg0KBQQG
AgEDEgSIAiYnCqABCgQEBgICEgaNAgKOAi8ajwEgUmVxdWlyZWQuIFRoZSBgU2VydmljZUxl
dmVsT2JqZWN0aXZlYCB0byBjcmVhdGUuCiBUaGUgcHJvdmlkZWQgYG5hbWVgIHdpbGwgYmUg
cmVzcGVjdGVkIGlmIG5vIGBTZXJ2aWNlTGV2ZWxPYmplY3RpdmVgIGV4aXN0cwogd2l0aCB0
aGlzIG5hbWUuCgoNCgUEBgICBhIEjQICFwoNCgUEBgICARIEjQIYLwoNCgUEBgICAxIEjQIy
MwoNCgUEBgICCBIEjgIGLgoQCggEBgICCJwIABIEjgIHLQo3CgIEBxIGkgIAowIBGikgVGhl
IGBHZXRTZXJ2aWNlTGV2ZWxPYmplY3RpdmVgIHJlcXVlc3QuCgoLCgMEBwESBJICCCcKvwEK
BAQHAgASBpcCApwCBBquASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgYFNlcnZp
Y2VMZXZlbE9iamVjdGl2ZWAgdG8gZ2V0LiBUaGUgZm9ybWF0CiBpczoKCiAgICAgcHJvamVj
dHMvW1BST0pFQ1RfSURfT1JfTlVNQkVSXS9zZXJ2aWNlcy9bU0VSVklDRV9JRF0vc2Vydmlj
ZUxldmVsT2JqZWN0aXZlcy9bU0xPX05BTUVdCgoNCgUEBwIABRIElwICCAoNCgUEBwIAARIE
lwIJDQoNCgUEBwIAAxIElwIQEQoPCgUEBwIACBIGlwISnAIDChAKCAQHAgAInAgAEgSYAgQq
ChEKBwQHAgAInwgSBpkCBJsCBQqzAgoEBAcCARIEogICJhqkAiBWaWV3IG9mIHRoZSBgU2Vy
dmljZUxldmVsT2JqZWN0aXZlYCB0byByZXR1cm4uIElmIGBERUZBVUxUYCwgcmV0dXJuIHRo
ZQogYFNlcnZpY2VMZXZlbE9iamVjdGl2ZWAgYXMgb3JpZ2luYWxseSBkZWZpbmVkLiBJZiBg
RVhQTElDSVRgIGFuZCB0aGUKIGBTZXJ2aWNlTGV2ZWxPYmplY3RpdmVgIGlzIGRlZmluZWQg
aW4gdGVybXMgb2YgYSBgQmFzaWNTbGlgLCByZXBsYWNlIHRoZQogYEJhc2ljU2xpYCB3aXRo
IGEgYFJlcXVlc3RCYXNlZFNsaWAgc3BlbGxpbmcgb3V0IGhvdyB0aGUgU0xJIGlzIGNvbXB1
dGVkLgoKDQoFBAcCAQYSBKICAhwKDQoFBAcCAQESBKICHSEKDQoFBAcCAQMSBKICJCUKOQoC
BAgSBqYCAMQCARorIFRoZSBgTGlzdFNlcnZpY2VMZXZlbE9iamVjdGl2ZXNgIHJlcXVlc3Qu
CgoLCgMECAESBKYCCCkKiQIKBAQIAgASBqwCArECBBr4ASBSZXF1aXJlZC4gUmVzb3VyY2Ug
bmFtZSBvZiB0aGUgcGFyZW50IGNvbnRhaW5pbmcgdGhlIGxpc3RlZCBTTE9zLCBlaXRoZXIg
YQogcHJvamVjdCBvciBhIE1vbml0b3JpbmcgTWV0cmljcyBTY29wZS4gVGhlIGZvcm1hdHMg
YXJlOgoKICAgICBwcm9qZWN0cy9bUFJPSkVDVF9JRF9PUl9OVU1CRVJdL3NlcnZpY2VzL1tT
RVJWSUNFX0lEXQogICAgIHdvcmtzcGFjZXMvW0hPU1RfUFJPSkVDVF9JRF9PUl9OVU1CRVJd
L3NlcnZpY2VzLy0KCg0KBQQIAgAFEgSsAgIICg0KBQQIAgABEgSsAgkPCg0KBQQIAgADEgSs
AhITCg8KBQQIAgAIEgasAhSxAgMKEAoIBAgCAAicCAASBK0CBCoKEQoHBAgCAAifCBIGrgIE
sAIFCkwKBAQIAgESBLQCAhQaPiBBIGZpbHRlciBzcGVjaWZ5aW5nIHdoYXQgYFNlcnZpY2VM
ZXZlbE9iamVjdGl2ZWBzIHRvIHJldHVybi4KCg0KBQQIAgEFEgS0AgIICg0KBQQIAgEBEgS0
AgkPCg0KBQQIAgEDEgS0AhITCnYKBAQIAgISBLgCAhYaaCBBIG5vbi1uZWdhdGl2ZSBudW1i
ZXIgdGhhdCBpcyB0aGUgbWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1cm4uCiBX
aGVuIDAsIHVzZSBkZWZhdWx0IHBhZ2Ugc2l6ZS4KCg0KBQQIAgIFEgS4AgIHCg0KBQQIAgIB
EgS4AggRCg0KBQQIAgIDEgS4AhQVCugBCgQECAIDEgS9AgIYGtkBIElmIHRoaXMgZmllbGQg
aXMgbm90IGVtcHR5IHRoZW4gaXQgbXVzdCBjb250YWluIHRoZSBgbmV4dFBhZ2VUb2tlbmAg
dmFsdWUKIHJldHVybmVkIGJ5IGEgcHJldmlvdXMgY2FsbCB0byB0aGlzIG1ldGhvZC4gIFVz
aW5nIHRoaXMgZmllbGQgY2F1c2VzIHRoZQogbWV0aG9kIHRvIHJldHVybiBhZGRpdGlvbmFs
IHJlc3VsdHMgZnJvbSB0aGUgcHJldmlvdXMgbWV0aG9kIGNhbGwuCgoNCgUECAIDBRIEvQIC
CAoNCgUECAIDARIEvQIJEwoNCgUECAIDAxIEvQIWFwq1AgoEBAgCBBIEwwICJhqmAiBWaWV3
IG9mIHRoZSBgU2VydmljZUxldmVsT2JqZWN0aXZlYHMgdG8gcmV0dXJuLiBJZiBgREVGQVVM
VGAsIHJldHVybiBlYWNoCiBgU2VydmljZUxldmVsT2JqZWN0aXZlYCBhcyBvcmlnaW5hbGx5
IGRlZmluZWQuIElmIGBFWFBMSUNJVGAgYW5kIHRoZQogYFNlcnZpY2VMZXZlbE9iamVjdGl2
ZWAgaXMgZGVmaW5lZCBpbiB0ZXJtcyBvZiBhIGBCYXNpY1NsaWAsIHJlcGxhY2UgdGhlCiBg
QmFzaWNTbGlgIHdpdGggYSBgUmVxdWVzdEJhc2VkU2xpYCBzcGVsbGluZyBvdXQgaG93IHRo
ZSBTTEkgaXMgY29tcHV0ZWQuCgoNCgUECAIEBhIEwwICHAoNCgUECAIEARIEwwIdIQoNCgUE
CAIEAxIEwwIkJQo6CgIECRIGxwIAzwIBGiwgVGhlIGBMaXN0U2VydmljZUxldmVsT2JqZWN0
aXZlc2AgcmVzcG9uc2UuCgoLCgMECQESBMcCCCoKSwoEBAkCABIEyQICPho9IFRoZSBgU2Vy
dmljZUxldmVsT2JqZWN0aXZlYHMgbWF0Y2hpbmcgdGhlIHNwZWNpZmllZCBmaWx0ZXIuCgoN
CgUECQIABBIEyQICCgoNCgUECQIABhIEyQILIAoNCgUECQIAARIEyQIhOQoNCgUECQIAAxIE
yQI8PQrSAQoEBAkCARIEzgICHRrDASBJZiB0aGVyZSBhcmUgbW9yZSByZXN1bHRzIHRoYW4g
aGF2ZSBiZWVuIHJldHVybmVkLCB0aGVuIHRoaXMgZmllbGQgaXMgc2V0CiB0byBhIG5vbi1l
bXB0eSB2YWx1ZS4gIFRvIHNlZSB0aGUgYWRkaXRpb25hbCByZXN1bHRzLAogdXNlIHRoYXQg
dmFsdWUgYXMgYHBhZ2VfdG9rZW5gIGluIHRoZSBuZXh0IGNhbGwgdG8gdGhpcyBtZXRob2Qu
CgoNCgUECQIBBRIEzgICCAoNCgUECQIBARIEzgIJGAoNCgUECQIBAxIEzgIbHAo6CgIEChIG
0gIA2gIBGiwgVGhlIGBVcGRhdGVTZXJ2aWNlTGV2ZWxPYmplY3RpdmVgIHJlcXVlc3QuCgoL
CgMECgESBNICCCoKgQEKBAQKAgASBtUCAtYCLxpxIFJlcXVpcmVkLiBUaGUgYFNlcnZpY2VM
ZXZlbE9iamVjdGl2ZWAgdG8gZHJhdyB1cGRhdGVzIGZyb20uCiBUaGUgZ2l2ZW4gYG5hbWVg
IHNwZWNpZmllcyB0aGUgcmVzb3VyY2UgdG8gdXBkYXRlLgoKDQoFBAoCAAYSBNUCAhcKDQoF
BAoCAAESBNUCGC8KDQoFBAoCAAMSBNUCMjMKDQoFBAoCAAgSBNYCBi4KEAoIBAoCAAicCAAS
BNYCBy0KUQoEBAoCARIE2QICLBpDIEEgc2V0IG9mIGZpZWxkIHBhdGhzIGRlZmluaW5nIHdo
aWNoIGZpZWxkcyB0byB1c2UgZm9yIHRoZSB1cGRhdGUuCgoNCgUECgIBBhIE2QICGwoNCgUE
CgIBARIE2QIcJwoNCgUECgIBAxIE2QIqKwo6CgIECxIG3QIA6AIBGiwgVGhlIGBEZWxldGVT
ZXJ2aWNlTGV2ZWxPYmplY3RpdmVgIHJlcXVlc3QuCgoLCgMECwESBN0CCCoKwgEKBAQLAgAS
BuICAucCBBqxASBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgYFNlcnZpY2VMZXZl
bE9iamVjdGl2ZWAgdG8gZGVsZXRlLiBUaGUKIGZvcm1hdCBpczoKCiAgICAgcHJvamVjdHMv
W1BST0pFQ1RfSURfT1JfTlVNQkVSXS9zZXJ2aWNlcy9bU0VSVklDRV9JRF0vc2VydmljZUxl
dmVsT2JqZWN0aXZlcy9bU0xPX05BTUVdCgoNCgUECwIABRIE4gICCAoNCgUECwIAARIE4gIJ
DQoNCgUECwIAAxIE4gIQEQoPCgUECwIACBIG4gIS5wIDChAKCAQLAgAInAgAEgTjAgQqChEK
BwQLAgAInwgSBuQCBOYCBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::V3::ServiceService::CreateServiceRequest ===
    # Fields for CreateServiceRequest
    # Field: parent Type: 9 ()
    # Field: service_id Type: 9 ()
    # Field: service Type: 11 (.google.monitoring.v3.Service)

# === Message: Google::Monitoring::V3::ServiceService::GetServiceRequest ===
    # Fields for GetServiceRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::ServiceService::ListServicesRequest ===
    # Fields for ListServicesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Monitoring::V3::ServiceService::ListServicesResponse ===
    # Fields for ListServicesResponse
    # Field: services Type: 11 (.google.monitoring.v3.Service)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Monitoring::V3::ServiceService::UpdateServiceRequest ===
    # Fields for UpdateServiceRequest
    # Field: service Type: 11 (.google.monitoring.v3.Service)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Monitoring::V3::ServiceService::DeleteServiceRequest ===
    # Fields for DeleteServiceRequest
    # Field: name Type: 9 ()

# === Message: Google::Monitoring::V3::ServiceService::CreateServiceLevelObjectiveRequest ===
    # Fields for CreateServiceLevelObjectiveRequest
    # Field: parent Type: 9 ()
    # Field: service_level_objective_id Type: 9 ()
    # Field: service_level_objective Type: 11 (.google.monitoring.v3.ServiceLevelObjective)

# === Message: Google::Monitoring::V3::ServiceService::GetServiceLevelObjectiveRequest ===
    # Fields for GetServiceLevelObjectiveRequest
    # Field: name Type: 9 ()
    # Field: view Type: 14 (.google.monitoring.v3.ServiceLevelObjective.View)

# === Message: Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesRequest ===
    # Fields for ListServiceLevelObjectivesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: view Type: 14 (.google.monitoring.v3.ServiceLevelObjective.View)

# === Message: Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesResponse ===
    # Fields for ListServiceLevelObjectivesResponse
    # Field: service_level_objectives Type: 11 (.google.monitoring.v3.ServiceLevelObjective)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Monitoring::V3::ServiceService::UpdateServiceLevelObjectiveRequest ===
    # Fields for UpdateServiceLevelObjectiveRequest
    # Field: service_level_objective Type: 11 (.google.monitoring.v3.ServiceLevelObjective)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Monitoring::V3::ServiceService::DeleteServiceLevelObjectiveRequest ===
    # Fields for DeleteServiceLevelObjectiveRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Monitoring::V3::ServiceService::ServiceMonitoringServiceClient ===
package Google::Monitoring::V3::ServiceService::ServiceMonitoringServiceClient;

=pod

=head2 Service Client: Google::Monitoring::V3::ServiceService::ServiceMonitoringServiceClient

Client stub representing the remote C<ServiceMonitoringService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<monitoring.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'monitoring.googleapis.com:443' );

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

sub create_service {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::CreateServiceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'CreateService',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Service::Service',
    });
}

sub get_service {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::GetServiceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'GetService',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Service::Service',
    });
}

sub list_services {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::ListServicesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'ListServices',
        request        => $req,
        response_class => 'Google::Monitoring::V3::ServiceService::ListServicesResponse',
    });
}

sub update_service {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::UpdateServiceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'UpdateService',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Service::Service',
    });
}

sub delete_service {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::DeleteServiceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'DeleteService',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub create_service_level_objective {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::CreateServiceLevelObjectiveRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'CreateServiceLevelObjective',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Service::ServiceLevelObjective',
    });
}

sub get_service_level_objective {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::GetServiceLevelObjectiveRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'GetServiceLevelObjective',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Service::ServiceLevelObjective',
    });
}

sub list_service_level_objectives {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'ListServiceLevelObjectives',
        request        => $req,
        response_class => 'Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesResponse',
    });
}

sub update_service_level_objective {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::UpdateServiceLevelObjectiveRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'UpdateServiceLevelObjective',
        request        => $req,
        response_class => 'Google::Monitoring::V3::Service::ServiceLevelObjective',
    });
}

sub delete_service_level_objective {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Monitoring::V3::ServiceService::DeleteServiceLevelObjectiveRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'DeleteServiceLevelObjective',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::V3::ServiceService - Compiled Protocol Buffers messages for google/monitoring/v3/service_service.proto

=head1 SYNOPSIS

    use Google::Monitoring::V3::ServiceService;

    my $msg = Google::Monitoring::V3::ServiceService::CreateServiceRequest->new({
        parent => $parent,
        service_id => $service_id,
        service => $service,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::V3::ServiceService::CreateServiceRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/v3/service_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::V3::ServiceService::CreateServiceRequest

The `CreateService` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource
[name](https://cloud.google.com/monitoring/api/v3#project_name) of the
parent Metrics Scope. The format is:

    projects/[PROJECT_ID_OR_NUMBER]

=item * C<< $msg->service_id() >> / C<< $msg->service_id($value) >>

Type: C<String>

Optional. The Service id to use for this Service. If omitted, an id will be
generated instead. Must match the pattern `[a-z0-9\-]+`

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Service::Service>)

Required. The `Service` to create.

=back

=head2 Google::Monitoring::V3::ServiceService::GetServiceRequest

The `GetService` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the `Service`. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/services/[SERVICE_ID]

=back

=head2 Google::Monitoring::V3::ServiceService::ListServicesRequest

The `ListServices` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the parent containing the listed services,
either a [project](https://cloud.google.com/monitoring/api/v3#project_name)
or a Monitoring Metrics Scope. The formats are:

    projects/[PROJECT_ID_OR_NUMBER]
    workspaces/[HOST_PROJECT_ID_OR_NUMBER]

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filter specifying what `Service`s to return. The filter supports
filtering on a particular service-identifier type or one of its attributes.

To filter on a particular service-identifier type, the `identifier_case`
refers to which option in the `identifier` field is populated. For example,
the filter `identifier_case = "CUSTOM"` would match all services with a
value for the `custom` field. Valid options include "CUSTOM", "APP_ENGINE",
"MESH_ISTIO", and the other options listed at
https://cloud.google.com/monitoring/api/ref_v3/rest/v3/services#Service

To filter on an attribute of a service-identifier type, apply the filter
name by using the snake case of the service-identifier type and the
attribute of that service-identifier type, and join the two with a period.
For example, to filter by the `meshUid` field of the `MeshIstio`
service-identifier type, you must filter on `mesh_istio.mesh_uid =
"123"` to match all services with mesh UID "123". Service-identifier types
and their attributes are described at
https://cloud.google.com/monitoring/api/ref_v3/rest/v3/services#Service

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

A non-negative number that is the maximum number of results to return.
When 0, use default page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

If this field is not empty then it must contain the `nextPageToken` value
returned by a previous call to this method.  Using this field causes the
method to return additional results from the previous method call.

=back

=head2 Google::Monitoring::V3::ServiceService::ListServicesResponse

The `ListServices` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->services() >> / C<< $msg->services($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Service::Service>)

The `Service`s matching the specified filter.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there are more results than have been returned, then this field is set
to a non-empty value.  To see the additional results,
use that value as `page_token` in the next call to this method.

=back

=head2 Google::Monitoring::V3::ServiceService::UpdateServiceRequest

The `UpdateService` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Service::Service>)

Required. The `Service` to draw updates from.
The given `name` specifies the resource to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

A set of field paths defining which fields to use for the update.

=back

=head2 Google::Monitoring::V3::ServiceService::DeleteServiceRequest

The `DeleteService` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the `Service` to delete. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/services/[SERVICE_ID]

=back

=head2 Google::Monitoring::V3::ServiceService::CreateServiceLevelObjectiveRequest

The `CreateServiceLevelObjective` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the parent `Service`. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/services/[SERVICE_ID]

=item * C<< $msg->service_level_objective_id() >> / C<< $msg->service_level_objective_id($value) >>

Type: C<String>

Optional. The ServiceLevelObjective id to use for this
ServiceLevelObjective. If omitted, an id will be generated instead. Must
match the pattern `^[a-zA-Z0-9-_:.]+$`

=item * C<< $msg->service_level_objective() >> / C<< $msg->service_level_objective($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Service::ServiceLevelObjective>)

Required. The `ServiceLevelObjective` to create.
The provided `name` will be respected if no `ServiceLevelObjective` exists
with this name.

=back

=head2 Google::Monitoring::V3::ServiceService::GetServiceLevelObjectiveRequest

The `GetServiceLevelObjective` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the `ServiceLevelObjective` to get. The format
is:

    projects/[PROJECT_ID_OR_NUMBER]/services/[SERVICE_ID]/serviceLevelObjectives/[SLO_NAME]

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Monitoring::V3::ServiceLevelObjective::View>)

View of the `ServiceLevelObjective` to return. If `DEFAULT`, return the
`ServiceLevelObjective` as originally defined. If `EXPLICIT` and the
`ServiceLevelObjective` is defined in terms of a `BasicSli`, replace the
`BasicSli` with a `RequestBasedSli` spelling out how the SLI is computed.

=back

=head2 Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesRequest

The `ListServiceLevelObjectives` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the parent containing the listed SLOs, either a
project or a Monitoring Metrics Scope. The formats are:

    projects/[PROJECT_ID_OR_NUMBER]/services/[SERVICE_ID]
    workspaces/[HOST_PROJECT_ID_OR_NUMBER]/services/-

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filter specifying what `ServiceLevelObjective`s to return.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

A non-negative number that is the maximum number of results to return.
When 0, use default page size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

If this field is not empty then it must contain the `nextPageToken` value
returned by a previous call to this method.  Using this field causes the
method to return additional results from the previous method call.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Monitoring::V3::ServiceLevelObjective::View>)

View of the `ServiceLevelObjective`s to return. If `DEFAULT`, return each
`ServiceLevelObjective` as originally defined. If `EXPLICIT` and the
`ServiceLevelObjective` is defined in terms of a `BasicSli`, replace the
`BasicSli` with a `RequestBasedSli` spelling out how the SLI is computed.

=back

=head2 Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesResponse

The `ListServiceLevelObjectives` response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_level_objectives() >> / C<< $msg->service_level_objectives($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Service::ServiceLevelObjective>)

The `ServiceLevelObjective`s matching the specified filter.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there are more results than have been returned, then this field is set
to a non-empty value.  To see the additional results,
use that value as `page_token` in the next call to this method.

=back

=head2 Google::Monitoring::V3::ServiceService::UpdateServiceLevelObjectiveRequest

The `UpdateServiceLevelObjective` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_level_objective() >> / C<< $msg->service_level_objective($value) >>

Type: C<Message> (L<Google::Monitoring::V3::Service::ServiceLevelObjective>)

Required. The `ServiceLevelObjective` to draw updates from.
The given `name` specifies the resource to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

A set of field paths defining which fields to use for the update.

=back

=head2 Google::Monitoring::V3::ServiceService::DeleteServiceLevelObjectiveRequest

The `DeleteServiceLevelObjective` request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the `ServiceLevelObjective` to delete. The
format is:

    projects/[PROJECT_ID_OR_NUMBER]/services/[SERVICE_ID]/serviceLevelObjectives/[SLO_NAME]

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::V3::ServiceService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
