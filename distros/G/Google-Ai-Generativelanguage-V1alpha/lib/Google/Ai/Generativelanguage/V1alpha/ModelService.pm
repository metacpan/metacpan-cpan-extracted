package Google::Ai::Generativelanguage::V1alpha::ModelService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1alpha::Model };
    eval { require Google::Ai::Generativelanguage::V1alpha::TunedModel };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvbW9kZWxfc2VydmljZS5w
cm90bxIkZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhGjBnb29nbGUvYWkv
Z2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvbW9kZWwucHJvdG8aNmdvb2dsZS9haS9nZW5l
cmF0aXZlbGFuZ3VhZ2UvdjFhbHBoYS90dW5lZF9tb2RlbC5wcm90bxocZ29vZ2xlL2FwaS9h
bm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2ds
ZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHku
cHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIlYKD0dldE1vZGVsUmVx
dWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ2dlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVh
cGlzLmNvbS9Nb2RlbFIEbmFtZSJPChFMaXN0TW9kZWxzUmVxdWVzdBIbCglwYWdlX3NpemUY
AiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKBAQoSTGlz
dE1vZGVsc1Jlc3BvbnNlEkMKBm1vZGVscxgBIAMoCzIrLmdvb2dsZS5haS5nZW5lcmF0aXZl
bGFuZ3VhZ2UudjFhbHBoYS5Nb2RlbFIGbW9kZWxzEiYKD25leHRfcGFnZV90b2tlbhgCIAEo
CVINbmV4dFBhZ2VUb2tlbiJgChRHZXRUdW5lZE1vZGVsUmVxdWVzdBJICgRuYW1lGAEgASgJ
QjTgQQL6QS4KLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9UdW5lZE1vZGVs
UgRuYW1lInsKFkxpc3RUdW5lZE1vZGVsc1JlcXVlc3QSIAoJcGFnZV9zaXplGAEgASgFQgPg
QQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAiABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZp
bHRlchgDIAEoCUID4EEBUgZmaWx0ZXIilgEKF0xpc3RUdW5lZE1vZGVsc1Jlc3BvbnNlElMK
DHR1bmVkX21vZGVscxgBIAMoCzIwLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFh
bHBoYS5UdW5lZE1vZGVsUgt0dW5lZE1vZGVscxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlS
DW5leHRQYWdlVG9rZW4itAEKF0NyZWF0ZVR1bmVkTW9kZWxSZXF1ZXN0Ei4KDnR1bmVkX21v
ZGVsX2lkGAEgASgJQgPgQQFIAFIMdHVuZWRNb2RlbElkiAEBElYKC3R1bmVkX21vZGVsGAIg
ASgLMjAuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLlR1bmVkTW9kZWxC
A+BBAlIKdHVuZWRNb2RlbEIRCg9fdHVuZWRfbW9kZWxfaWQiuQIKGENyZWF0ZVR1bmVkTW9k
ZWxNZXRhZGF0YRJSCgt0dW5lZF9tb2RlbBgFIAEoCUIx+kEuCixnZW5lcmF0aXZlbGFuZ3Vh
Z2UuZ29vZ2xlYXBpcy5jb20vVHVuZWRNb2RlbFIKdHVuZWRNb2RlbBIfCgt0b3RhbF9zdGVw
cxgBIAEoBVIKdG90YWxTdGVwcxInCg9jb21wbGV0ZWRfc3RlcHMYAiABKAVSDmNvbXBsZXRl
ZFN0ZXBzEisKEWNvbXBsZXRlZF9wZXJjZW50GAMgASgCUhBjb21wbGV0ZWRQZXJjZW50ElIK
CXNuYXBzaG90cxgEIAMoCzI0Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBo
YS5UdW5pbmdTbmFwc2hvdFIJc25hcHNob3RzIrMBChdVcGRhdGVUdW5lZE1vZGVsUmVxdWVz
dBJWCgt0dW5lZF9tb2RlbBgBIAEoCzIwLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2Uu
djFhbHBoYS5UdW5lZE1vZGVsQgPgQQJSCnR1bmVkTW9kZWwSQAoLdXBkYXRlX21hc2sYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2siYwoXRGVs
ZXRlVHVuZWRNb2RlbFJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuCixnZW5lcmF0aXZl
bGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vVHVuZWRNb2RlbFIEbmFtZTLgCgoMTW9kZWxTZXJ2
aWNlEpcBCghHZXRNb2RlbBI1Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBo
YS5HZXRNb2RlbFJlcXVlc3QaKy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxw
aGEuTW9kZWwiJ4LT5JMCGhIYL3YxYWxwaGEve25hbWU9bW9kZWxzLyp92kEEbmFtZRKvAQoK
TGlzdE1vZGVscxI3Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5MaXN0
TW9kZWxzUmVxdWVzdBo4Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5M
aXN0TW9kZWxzUmVzcG9uc2UiLoLT5JMCERIPL3YxYWxwaGEvbW9kZWxz2kEUcGFnZV9zaXpl
LHBhZ2VfdG9rZW4SqwEKDUdldFR1bmVkTW9kZWwSOi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxh
bmd1YWdlLnYxYWxwaGEuR2V0VHVuZWRNb2RlbFJlcXVlc3QaMC5nb29nbGUuYWkuZ2VuZXJh
dGl2ZWxhbmd1YWdlLnYxYWxwaGEuVHVuZWRNb2RlbCIsgtPkkwIfEh0vdjFhbHBoYS97bmFt
ZT10dW5lZE1vZGVscy8qfdpBBG5hbWUSwwEKD0xpc3RUdW5lZE1vZGVscxI8Lmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5MaXN0VHVuZWRNb2RlbHNSZXF1ZXN0Gj0u
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkxpc3RUdW5lZE1vZGVsc1Jl
c3BvbnNlIjOC0+STAhYSFC92MWFscGhhL3R1bmVkTW9kZWxz2kEUcGFnZV9zaXplLHBhZ2Vf
dG9rZW4S7wEKEENyZWF0ZVR1bmVkTW9kZWwSPS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1
YWdlLnYxYWxwaGEuQ3JlYXRlVHVuZWRNb2RlbFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uIn2C0+STAiMiFC92MWFscGhhL3R1bmVkTW9kZWxzOgt0dW5lZF9tb2Rl
bNpBC3R1bmVkX21vZGVs2kEadHVuZWRfbW9kZWxfaWQsdHVuZWRfbW9kZWzKQSYKClR1bmVk
TW9kZWwSGENyZWF0ZVR1bmVkTW9kZWxNZXRhZGF0YRLdAQoQVXBkYXRlVHVuZWRNb2RlbBI9
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5VcGRhdGVUdW5lZE1vZGVs
UmVxdWVzdBowLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5UdW5lZE1v
ZGVsIliC0+STAjgyKS92MWFscGhhL3t0dW5lZF9tb2RlbC5uYW1lPXR1bmVkTW9kZWxzLyp9
Ogt0dW5lZF9tb2RlbNpBF3R1bmVkX21vZGVsLHVwZGF0ZV9tYXNrEpcBChBEZWxldGVUdW5l
ZE1vZGVsEj0uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkRlbGV0ZVR1
bmVkTW9kZWxSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IiyC0+STAh8qHS92MWFs
cGhhL3tuYW1lPXR1bmVkTW9kZWxzLyp92kEEbmFtZRokykEhZ2VuZXJhdGl2ZWxhbmd1YWdl
Lmdvb2dsZWFwaXMuY29tQp8BCihjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52
MWFscGhhQhFNb2RlbFNlcnZpY2VQcm90b1ABWl5jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dl
bmVyYXRpdmVsYW5ndWFnZS9hcGl2MWFscGhhL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVy
YXRpdmVsYW5ndWFnZXBiSqw+CgcSBQ4AkgIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSADoKCQoCAwESAxMAQAoJCgIDAhIDFAAmCgkK
AgMDEgMVACEKCQoCAwQSAxYAKQoJCgIDBRIDFwAjCgkKAgMGEgMYAC0KCQoCAwcSAxkAJQoJ
CgIDCBIDGgAqCggKAQgSAxwAdQoJCgIICxIDHAB1CggKAQgSAx0AIgoJCgIIChIDHQAiCggK
AQgSAx4AMgoJCgIICBIDHgAyCggKAQgSAx8AQQoJCgIIARIDHwBBClgKAgYAEgQiAHIBGkwg
UHJvdmlkZXMgbWV0aG9kcyBmb3IgZ2V0dGluZyBtZXRhZGF0YSBpbmZvcm1hdGlvbiBhYm91
dCBHZW5lcmF0aXZlIE1vZGVscy4KCgoKAwYAARIDIggUCgoKAwYAAxIDIwJJCgwKBQYAA5kI
EgMjAkkK0wIKBAYAAgASBCsCMAMaxAIgR2V0cyBpbmZvcm1hdGlvbiBhYm91dCBhIHNwZWNp
ZmljIGBNb2RlbGAgc3VjaCBhcyBpdHMgdmVyc2lvbiBudW1iZXIsIHRva2VuCiBsaW1pdHMs
CiBbcGFyYW1ldGVyc10oaHR0cHM6Ly9haS5nb29nbGUuZGV2L2dlbWluaS1hcGkvZG9jcy9t
b2RlbHMvZ2VuZXJhdGl2ZS1tb2RlbHMjbW9kZWwtcGFyYW1ldGVycykKIGFuZCBvdGhlciBt
ZXRhZGF0YS4gUmVmZXIgdG8gdGhlIFtHZW1pbmkgbW9kZWxzCiBndWlkZV0oaHR0cHM6Ly9h
aS5nb29nbGUuZGV2L2dlbWluaS1hcGkvZG9jcy9tb2RlbHMvZ2VtaW5pKSBmb3IgZGV0YWls
ZWQKIG1vZGVsIGluZm9ybWF0aW9uLgoKDAoFBgACAAESAysGDgoMCgUGAAIAAhIDKw8eCgwK
BQYAAgADEgMrKS4KDQoFBgACAAQSBCwELgYKEQoJBgACAASwyrwiEgQsBC4GCgwKBQYAAgAE
EgMvBDIKDwoIBgACAASbCAASAy8EMgp8CgQGAAIBEgQ0AjkDGm4gTGlzdHMgdGhlIFtgTW9k
ZWxgc10oaHR0cHM6Ly9haS5nb29nbGUuZGV2L2dlbWluaS1hcGkvZG9jcy9tb2RlbHMvZ2Vt
aW5pKQogYXZhaWxhYmxlIHRocm91Z2ggdGhlIEdlbWluaSBBUEkuCgoMCgUGAAIBARIDNAYQ
CgwKBQYAAgECEgM0ESIKDAoFBgACAQMSAzQtPwoNCgUGAAIBBBIENQQ3BgoRCgkGAAIBBLDK
vCISBDUENwYKDAoFBgACAQQSAzgEQgoPCggGAAIBBJsIABIDOARCCj0KBAYAAgISBDwCQQMa
LyBHZXRzIGluZm9ybWF0aW9uIGFib3V0IGEgc3BlY2lmaWMgVHVuZWRNb2RlbC4KCgwKBQYA
AgIBEgM8BhMKDAoFBgACAgISAzwUKAoMCgUGAAICAxIDPDM9Cg0KBQYAAgIEEgQ9BD8GChEK
CQYAAgIEsMq8IhIEPQQ/BgoMCgUGAAICBBIDQAQyCg8KCAYAAgIEmwgAEgNABDIKKwoEBgAC
AxIERAJKAxodIExpc3RzIGNyZWF0ZWQgdHVuZWQgbW9kZWxzLgoKDAoFBgACAwESA0QGFQoM
CgUGAAIDAhIDRBYsCgwKBQYAAgMDEgNFDyYKDQoFBgACAwQSBEYESAYKEQoJBgACAwSwyrwi
EgRGBEgGCgwKBQYAAgMEEgNJBEIKDwoIBgACAwSbCAASA0kEQgqKAgoEBgACBBIEUwJfAxr7
ASBDcmVhdGVzIGEgdHVuZWQgbW9kZWwuCiBDaGVjayBpbnRlcm1lZGlhdGUgdHVuaW5nIHBy
b2dyZXNzIChpZiBhbnkpIHRocm91Z2ggdGhlCiBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbnNdIHNlcnZpY2UuCgogQWNjZXNzIHN0YXR1cyBhbmQgcmVzdWx0cyB0aHJvdWdoIHRo
ZSBPcGVyYXRpb25zIHNlcnZpY2UuCiBFeGFtcGxlOgogICBHRVQgL3YxL3R1bmVkTW9kZWxz
L2F6Mm1iMGJwdzZpL29wZXJhdGlvbnMvMDAwLTExMS0yMjIKCgwKBQYAAgQBEgNTBhYKDAoF
BgACBAISA1MXLgoMCgUGAAIEAxIDVA8rCg0KBQYAAgQEEgRVBFgGChEKCQYAAgQEsMq8IhIE
VQRYBgoMCgUGAAIEBBIDWQQ5Cg8KCAYAAgQEmwgAEgNZBDkKDAoFBgACBAQSA1oESAoPCggG
AAIEBJsIARIDWgRICg0KBQYAAgQEEgRbBF4GCg8KBwYAAgQEmQgSBFsEXgYKJgoEBgACBRIE
YgJoAxoYIFVwZGF0ZXMgYSB0dW5lZCBtb2RlbC4KCgwKBQYAAgUBEgNiBhYKDAoFBgACBQIS
A2IXLgoMCgUGAAIFAxIDYjlDCg0KBQYAAgUEEgRjBGYGChEKCQYAAgUEsMq8IhIEYwRmBgoM
CgUGAAIFBBIDZwRFCg8KCAYAAgUEmwgAEgNnBEUKJgoEBgACBhIEawJxAxoYIERlbGV0ZXMg
YSB0dW5lZCBtb2RlbC4KCgwKBQYAAgYBEgNrBhYKDAoFBgACBgISA2sXLgoMCgUGAAIGAxID
bA8kCg0KBQYAAgYEEgRtBG8GChEKCQYAAgYEsMq8IhIEbQRvBgoMCgUGAAIGBBIDcAQyCg8K
CAYAAgYEmwgAEgNwBDIKRgoCBAASBXUAgQEBGjkgUmVxdWVzdCBmb3IgZ2V0dGluZyBpbmZv
cm1hdGlvbiBhYm91dCBhIHNwZWNpZmljIE1vZGVsLgoKCgoDBAABEgN1CBcKoQEKBAQAAgAS
BXsCgAEEGpEBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbW9kZWwuCgog
VGhpcyBuYW1lIHNob3VsZCBtYXRjaCBhIG1vZGVsIG5hbWUgcmV0dXJuZWQgYnkgdGhlIGBM
aXN0TW9kZWxzYCBtZXRob2QuCgogRm9ybWF0OiBgbW9kZWxzL3ttb2RlbH1gCgoMCgUEAAIA
BRIDewIICgwKBQQAAgABEgN7CQ0KDAoFBAACAAMSA3sQEQoOCgUEAAIACBIFexKAAQMKDwoI
BAACAAicCAASA3wEKgoPCgcEAAIACJ8IEgR9BH8FCi8KAgQBEgaEAQCUAQEaISBSZXF1ZXN0
IGZvciBsaXN0aW5nIGFsbCBNb2RlbHMuCgoLCgMEAQESBIQBCBkK1QEKBAQBAgASBIoBAhYa
xgEgVGhlIG1heGltdW0gbnVtYmVyIG9mIGBNb2RlbHNgIHRvIHJldHVybiAocGVyIHBhZ2Up
LgoKIElmIHVuc3BlY2lmaWVkLCA1MCBtb2RlbHMgd2lsbCBiZSByZXR1cm5lZCBwZXIgcGFn
ZS4KIFRoaXMgbWV0aG9kIHJldHVybnMgYXQgbW9zdCAxMDAwIG1vZGVscyBwZXIgcGFnZSwg
ZXZlbiBpZiB5b3UgcGFzcyBhIGxhcmdlcgogcGFnZV9zaXplLgoKDQoFBAECAAUSBIoBAgcK
DQoFBAECAAESBIoBCBEKDQoFBAECAAMSBIoBFBUKsAIKBAQBAgESBJMBAhgaoQIgQSBwYWdl
IHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RNb2RlbHNgIGNhbGwuCgog
UHJvdmlkZSB0aGUgYHBhZ2VfdG9rZW5gIHJldHVybmVkIGJ5IG9uZSByZXF1ZXN0IGFzIGFu
IGFyZ3VtZW50IHRvIHRoZSBuZXh0CiByZXF1ZXN0IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBh
Z2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0
byBgTGlzdE1vZGVsc2AgbXVzdCBtYXRjaAogdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUg
cGFnZSB0b2tlbi4KCg0KBQQBAgEFEgSTAQIICg0KBQQBAgEBEgSTAQkTCg0KBQQBAgEDEgST
ARYXClAKAgQCEgaXAQCfAQEaQiBSZXNwb25zZSBmcm9tIGBMaXN0TW9kZWxgIGNvbnRhaW5p
bmcgYSBwYWdpbmF0ZWQgbGlzdCBvZiBNb2RlbHMuCgoLCgMEAgESBJcBCBoKJAoEBAICABIE
mQECHBoWIFRoZSByZXR1cm5lZCBNb2RlbHMuCgoNCgUEAgIABBIEmQECCgoNCgUEAgIABhIE
mQELEAoNCgUEAgIAARIEmQERFwoNCgUEAgIAAxIEmQEaGwqKAQoEBAICARIEngECHRp8IEEg
dG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0
aGUgbmV4dCBwYWdlLgoKIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5v
IG1vcmUgcGFnZXMuCgoNCgUEAgIBBRIEngECCAoNCgUEAgIBARIEngEJGAoNCgUEAgIBAxIE
ngEbHApHCgIEAxIGogEArAEBGjkgUmVxdWVzdCBmb3IgZ2V0dGluZyBpbmZvcm1hdGlvbiBh
Ym91dCBhIHNwZWNpZmljIE1vZGVsLgoKCwoDBAMBEgSiAQgcCl8KBAQDAgASBqYBAqsBBBpP
IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbW9kZWwuCgogRm9ybWF0OiBg
dHVuZWRNb2RlbHMvbXktbW9kZWwtaWRgCgoNCgUEAwIABRIEpgECCAoNCgUEAwIAARIEpgEJ
DQoNCgUEAwIAAxIEpgEQEQoPCgUEAwIACBIGpgESqwEDChAKCAQDAgAInAgAEgSnAQQqChEK
BwQDAgAInwgSBqgBBKoBBQowCgIEBBIGrwEA0AEBGiIgUmVxdWVzdCBmb3IgbGlzdGluZyBU
dW5lZE1vZGVscy4KCgsKAwQEARIErwEIHgqVAgoEBAQCABIEtgECPxqGAiBPcHRpb25hbC4g
VGhlIG1heGltdW0gbnVtYmVyIG9mIGBUdW5lZE1vZGVsc2AgdG8gcmV0dXJuIChwZXIgcGFn
ZSkuCiBUaGUgc2VydmljZSBtYXkgcmV0dXJuIGZld2VyIHR1bmVkIG1vZGVscy4KCiBJZiB1
bnNwZWNpZmllZCwgYXQgbW9zdCAxMCB0dW5lZCBtb2RlbHMgd2lsbCBiZSByZXR1cm5lZC4K
IFRoaXMgbWV0aG9kIHJldHVybnMgYXQgbW9zdCAxMDAwIG1vZGVscyBwZXIgcGFnZSwgZXZl
biBpZiB5b3UgcGFzcyBhIGxhcmdlcgogcGFnZV9zaXplLgoKDQoFBAQCAAUSBLYBAgcKDQoF
BAQCAAESBLYBCBEKDQoFBAQCAAMSBLYBFBUKDQoFBAQCAAgSBLYBFj4KEAoIBAQCAAicCAAS
BLYBFz0KxAIKBAQEAgESBL8BAkEatQIgT3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2
ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0VHVuZWRNb2RlbHNgIGNhbGwuCgogUHJvdmlkZSB0
aGUgYHBhZ2VfdG9rZW5gIHJldHVybmVkIGJ5IG9uZSByZXF1ZXN0IGFzIGFuIGFyZ3VtZW50
IHRvIHRoZSBuZXh0CiByZXF1ZXN0IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCgogV2hl
biBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0byBgTGlzdFR1
bmVkTW9kZWxzYAogbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdl
IHRva2VuLgoKDQoFBAQCAQUSBL8BAggKDQoFBAQCAQESBL8BCRMKDQoFBAQCAQMSBL8BFhcK
DQoFBAQCAQgSBL8BGEAKEAoIBAQCAQicCAASBL8BGT8K/AMKBAQEAgISBM8BAj0a7QMgT3B0
aW9uYWwuIEEgZmlsdGVyIGlzIGEgZnVsbCB0ZXh0IHNlYXJjaCBvdmVyIHRoZSB0dW5lZCBt
b2RlbCdzIGRlc2NyaXB0aW9uCiBhbmQgZGlzcGxheSBuYW1lLiBCeSBkZWZhdWx0LCByZXN1
bHRzIHdpbGwgbm90IGluY2x1ZGUgdHVuZWQgbW9kZWxzIHNoYXJlZAogd2l0aCBldmVyeW9u
ZS4KCiBBZGRpdGlvbmFsIG9wZXJhdG9yczoKICAgLSBvd25lcjptZQogICAtIHdyaXRlcnM6
bWUKICAgLSByZWFkZXJzOm1lCiAgIC0gcmVhZGVyczpldmVyeW9uZQoKIEV4YW1wbGVzOgog
ICAib3duZXI6bWUiIHJldHVybnMgYWxsIHR1bmVkIG1vZGVscyB0byB3aGljaCBjYWxsZXIg
aGFzIG93bmVyIHJvbGUKICAgInJlYWRlcnM6bWUiIHJldHVybnMgYWxsIHR1bmVkIG1vZGVs
cyB0byB3aGljaCBjYWxsZXIgaGFzIHJlYWRlciByb2xlCiAgICJyZWFkZXJzOmV2ZXJ5b25l
IiByZXR1cm5zIGFsbCB0dW5lZCBtb2RlbHMgdGhhdCBhcmUgc2hhcmVkIHdpdGggZXZlcnlv
bmUKCg0KBQQEAgIFEgTPAQIICg0KBQQEAgIBEgTPAQkPCg0KBQQEAgIDEgTPARITCg0KBQQE
AgIIEgTPARQ8ChAKCAQEAgIInAgAEgTPARU7ClYKAgQFEgbTAQDbAQEaSCBSZXNwb25zZSBm
cm9tIGBMaXN0VHVuZWRNb2RlbHNgIGNvbnRhaW5pbmcgYSBwYWdpbmF0ZWQgbGlzdCBvZiBN
b2RlbHMuCgoLCgMEBQESBNMBCB8KJAoEBAUCABIE1QECJxoWIFRoZSByZXR1cm5lZCBNb2Rl
bHMuCgoNCgUEBQIABBIE1QECCgoNCgUEBQIABhIE1QELFQoNCgUEBQIAARIE1QEWIgoNCgUE
BQIAAxIE1QElJgqKAQoEBAUCARIE2gECHRp8IEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50
IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgoKIElmIHRoaXMg
ZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIG1vcmUgcGFnZXMuCgoNCgUEBQIBBRIE
2gECCAoNCgUEBQIBARIE2gEJGAoNCgUEBQIBAxIE2gEbHAovCgIEBhIG3gEA5wEBGiEgUmVx
dWVzdCB0byBjcmVhdGUgYSBUdW5lZE1vZGVsLgoKCwoDBAYBEgTeAQgfCpICCgQEBgIAEgTj
AQJOGoMCIE9wdGlvbmFsLiBUaGUgdW5pcXVlIGlkIGZvciB0aGUgdHVuZWQgbW9kZWwgaWYg
c3BlY2lmaWVkLgogVGhpcyB2YWx1ZSBzaG91bGQgYmUgdXAgdG8gNDAgY2hhcmFjdGVycywg
dGhlIGZpcnN0IGNoYXJhY3RlciBtdXN0IGJlIGEKIGxldHRlciwgdGhlIGxhc3QgY291bGQg
YmUgYSBsZXR0ZXIgb3IgYSBudW1iZXIuIFRoZSBpZCBtdXN0IG1hdGNoIHRoZQogcmVndWxh
ciBleHByZXNzaW9uOiBgW2Etel0oW2EtejAtOS1dezAsMzh9W2EtejAtOV0pP2AuCgoNCgUE
BgIABBIE4wECCgoNCgUEBgIABRIE4wELEQoNCgUEBgIAARIE4wESIAoNCgUEBgIAAxIE4wEj
JAoNCgUEBgIACBIE4wElTQoQCggEBgIACJwIABIE4wEmTAo0CgQEBgIBEgTmAQJGGiYgUmVx
dWlyZWQuIFRoZSB0dW5lZCBtb2RlbCB0byBjcmVhdGUuCgoNCgUEBgIBBhIE5gECDAoNCgUE
BgIBARIE5gENGAoNCgUEBgIBAxIE5gEbHAoNCgUEBgIBCBIE5gEdRQoQCggEBgIBCJwIABIE
5gEeRAp5CgIEBxIG6wEA/AEBGmsgTWV0YWRhdGEgYWJvdXQgdGhlIHN0YXRlIGFuZCBwcm9n
cmVzcyBvZiBjcmVhdGluZyBhIHR1bmVkIG1vZGVsIHJldHVybmVkIGZyb20KIHRoZSBsb25n
LXJ1bm5pbmcgb3BlcmF0aW9uCgoLCgMEBwESBOsBCCAKTwoEBAcCABIG7QEC7wEFGj8gTmFt
ZSBvZiB0aGUgdHVuZWQgbW9kZWwgYXNzb2NpYXRlZCB3aXRoIHRoZSB0dW5pbmcgb3BlcmF0
aW9uLgoKDQoFBAcCAAUSBO0BAggKDQoFBAcCAAESBO0BCRQKDQoFBAcCAAMSBO0BFxgKDwoF
BAcCAAgSBu0BGe8BBAoRCgcEBwIACJ8IEgbtARrvAQMKMQoEBAcCARIE8gECGBojIFRoZSB0
b3RhbCBudW1iZXIgb2YgdHVuaW5nIHN0ZXBzLgoKDQoFBAcCAQUSBPIBAgcKDQoFBAcCAQES
BPIBCBMKDQoFBAcCAQMSBPIBFhcKLgoEBAcCAhIE9QECHBogIFRoZSBudW1iZXIgb2Ygc3Rl
cHMgY29tcGxldGVkLgoKDQoFBAcCAgUSBPUBAgcKDQoFBAcCAgESBPUBCBcKDQoFBAcCAgMS
BPUBGhsKQgoEBAcCAxIE+AECHho0IFRoZSBjb21wbGV0ZWQgcGVyY2VudGFnZSBmb3IgdGhl
IHR1bmluZyBvcGVyYXRpb24uCgoNCgUEBwIDBRIE+AECBwoNCgUEBwIDARIE+AEIGQoNCgUE
BwIDAxIE+AEcHQowCgQEBwIEEgT7AQIoGiIgTWV0cmljcyBjb2xsZWN0ZWQgZHVyaW5nIHR1
bmluZy4KCg0KBQQHAgQEEgT7AQIKCg0KBQQHAgQGEgT7AQsZCg0KBQQHAgQBEgT7ARojCg0K
BQQHAgQDEgT7ASYnCi8KAgQIEgb/AQCGAgEaISBSZXF1ZXN0IHRvIHVwZGF0ZSBhIFR1bmVk
TW9kZWwuCgoLCgMECAESBP8BCB8KNAoEBAgCABIEgQICRhomIFJlcXVpcmVkLiBUaGUgdHVu
ZWQgbW9kZWwgdG8gdXBkYXRlLgoKDQoFBAgCAAYSBIECAgwKDQoFBAgCAAESBIECDRgKDQoF
BAgCAAMSBIECGxwKDQoFBAgCAAgSBIECHUUKEAoIBAgCAAicCAASBIECHkQKOQoEBAgCARIG
hAIChQIvGikgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuCgoNCgUE
CAIBBhIEhAICGwoNCgUECAIBARIEhAIcJwoNCgUECAIBAxIEhAIqKwoNCgUECAIBCBIEhQIG
LgoQCggECAIBCJwIABIEhQIHLQovCgIECRIGiQIAkgIBGiEgUmVxdWVzdCB0byBkZWxldGUg
YSBUdW5lZE1vZGVsLgoKCwoDBAkBEgSJAggfCl4KBAQJAgASBowCApECBBpOIFJlcXVpcmVk
LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbW9kZWwuCiBGb3JtYXQ6IGB0dW5lZE1vZGVs
cy9teS1tb2RlbC1pZGAKCg0KBQQJAgAFEgSMAgIICg0KBQQJAgABEgSMAgkNCg0KBQQJAgAD
EgSMAhARCg8KBQQJAgAIEgaMAhKRAgMKEAoIBAkCAAicCAASBI0CBCoKEQoHBAkCAAifCBIG
jgIEkAIFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::GetModelRequest ===
    # Fields for GetModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.ai.generativelanguage.v1alpha.Model)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::GetTunedModelRequest ===
    # Fields for GetTunedModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsRequest ===
    # Fields for ListTunedModelsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsResponse ===
    # Fields for ListTunedModelsResponse
    # Field: tuned_models Type: 11 (.google.ai.generativelanguage.v1alpha.TunedModel)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::CreateTunedModelRequest ===
    # Fields for CreateTunedModelRequest
    # Field: tuned_model_id Type: 9 ()
    # Field: tuned_model Type: 11 (.google.ai.generativelanguage.v1alpha.TunedModel)

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::CreateTunedModelMetadata ===
    # Fields for CreateTunedModelMetadata
    # Field: tuned_model Type: 9 ()
    # Field: total_steps Type: 5 ()
    # Field: completed_steps Type: 5 ()
    # Field: completed_percent Type: 2 ()
    # Field: snapshots Type: 11 (.google.ai.generativelanguage.v1alpha.TuningSnapshot)

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::UpdateTunedModelRequest ===
    # Fields for UpdateTunedModelRequest
    # Field: tuned_model Type: 11 (.google.ai.generativelanguage.v1alpha.TunedModel)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Ai::Generativelanguage::V1alpha::ModelService::DeleteTunedModelRequest ===
    # Fields for DeleteTunedModelRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Ai::Generativelanguage::V1alpha::ModelService::ModelServiceClient ===
package Google::Ai::Generativelanguage::V1alpha::ModelService::ModelServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1alpha::ModelService::ModelServiceClient

Client stub representing the remote C<ModelService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ai.googleapis.com:443' );

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

sub get_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::ModelService::GetModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'GetModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::Model::Model',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsResponse',
    });
}

sub get_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::ModelService::GetTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'GetTunedModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel',
    });
}

sub list_tuned_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'ListTunedModels',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsResponse',
    });
}

sub create_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::ModelService::CreateTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'CreateTunedModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::ModelService::UpdateTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'UpdateTunedModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel',
    });
}

sub delete_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::ModelService::DeleteTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'DeleteTunedModel',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::ModelService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/model_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1alpha::ModelService::GetModelRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::ModelService::GetModelRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/model_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::GetModelRequest

Request for getting information about a specific Model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the model.

This name should match a model name returned by the `ListModels` method.

Format: `models/{model}`

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsRequest

Request for listing all Models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of `Models` to return (per page).

If unspecified, 50 models will be returned per page.
This method returns at most 1000 models per page, even if you pass a larger
page_size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListModels` call.

Provide the `page_token` returned by one request as an argument to the next
request to retrieve the next page.

When paginating, all other parameters provided to `ListModels` must match
the call that provided the page token.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsResponse

Response from `ListModel` containing a paginated list of Models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Model::Model>)

The returned Models.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.

If this field is omitted, there are no more pages.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::GetTunedModelRequest

Request for getting information about a specific Model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the model.

Format: `tunedModels/my-model-id`

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsRequest

Request for listing TunedModels.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of `TunedModels` to return (per page).
The service may return fewer tuned models.

If unspecified, at most 10 tuned models will be returned.
This method returns at most 1000 models per page, even if you pass a larger
page_size.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListTunedModels` call.

Provide the `page_token` returned by one request as an argument to the next
request to retrieve the next page.

When paginating, all other parameters provided to `ListTunedModels`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter is a full text search over the tuned model's description
and display name. By default, results will not include tuned models shared
with everyone.

Additional operators:
  - owner:me
  - writers:me
  - readers:me
  - readers:everyone

Examples:
  "owner:me" returns all tuned models to which caller has owner role
  "readers:me" returns all tuned models to which caller has reader role
  "readers:everyone" returns all tuned models that are shared with everyone

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsResponse

Response from `ListTunedModels` containing a paginated list of Models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_models() >> / C<< $msg->tuned_models($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel>)

The returned Models.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.

If this field is omitted, there are no more pages.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::CreateTunedModelRequest

Request to create a TunedModel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model_id() >> / C<< $msg->tuned_model_id($value) >>

Type: C<String>

Optional. The unique id for the tuned model if specified.
This value should be up to 40 characters, the first character must be a
letter, the last could be a letter or a number. The id must match the
regular expression: `[a-z]([a-z0-9-]{0,38}[a-z0-9])?`.

=item * C<< $msg->tuned_model() >> / C<< $msg->tuned_model($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel>)

Required. The tuned model to create.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::CreateTunedModelMetadata

Metadata about the state and progress of creating a tuned model returned from
the long-running operation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model() >> / C<< $msg->tuned_model($value) >>

Type: C<String>

Name of the tuned model associated with the tuning operation.

=item * C<< $msg->total_steps() >> / C<< $msg->total_steps($value) >>

Type: C<Int32>

The total number of tuning steps.

=item * C<< $msg->completed_steps() >> / C<< $msg->completed_steps($value) >>

Type: C<Int32>

The number of steps completed.

=item * C<< $msg->completed_percent() >> / C<< $msg->completed_percent($value) >>

Type: C<Float>

The completed percentage for the tuning operation.

=item * C<< $msg->snapshots() >> / C<< $msg->snapshots($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningSnapshot>)

Metrics collected during tuning.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::UpdateTunedModelRequest

Request to update a TunedModel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model() >> / C<< $msg->tuned_model($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel>)

Required. The tuned model to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::ModelService::DeleteTunedModelRequest

Request to delete a TunedModel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the model.
Format: `tunedModels/my-model-id`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::ModelService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
