package Google::Cloud::Discoveryengine::V1::WidgetConfigService;

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
    eval { require Google::Cloud::Discoveryengine::V1::WidgetConfig };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3dpZGdldF9jb25maWdfc2Vydmlj
ZS5wcm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9h
bm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aM2dvb2ds
ZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvd2lkZ2V0X2NvbmZpZy5wcm90bxogZ29vZ2xl
L3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8ingQKFkdldFdpZGdldENvbmZpZ1JlcXVlc3QS
RwoEbmFtZRgBIAEoCUIz4EEC+kEtCitkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
V2lkZ2V0Q29uZmlnUgRuYW1lEiYKDGFjY2VwdF9jYWNoZRgCIAEoCEID4EEBUgthY2NlcHRD
YWNoZRKhAQogZ2V0X3dpZGdldF9jb25maWdfcmVxdWVzdF9vcHRpb24YAyABKAsyVC5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkdldFdpZGdldENvbmZpZ1JlcXVlc3QuR2V0
V2lkZ2V0Q29uZmlnUmVxdWVzdE9wdGlvbkID4EEBUhxnZXRXaWRnZXRDb25maWdSZXF1ZXN0
T3B0aW9uEigKDWxhbmd1YWdlX2NvZGUYBCABKAlCA+BBAVIMbGFuZ3VhZ2VDb2RlElsKD21v
ZGVsX2luZm9fdmlldxgFIAEoDjIuLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
TW9kZWxJbmZvVmlld0ID4EEBUg1tb2RlbEluZm9WaWV3GmgKHEdldFdpZGdldENvbmZpZ1Jl
cXVlc3RPcHRpb24SSAoedHVybl9vZmZfY29sbGVjdGlvbl9jb21wb25lbnRzGAEgASgIQgPg
QQFSG3R1cm5PZmZDb2xsZWN0aW9uQ29tcG9uZW50cyKxAQoZVXBkYXRlV2lkZ2V0Q29uZmln
UmVxdWVzdBJXCg13aWRnZXRfY29uZmlnGAEgASgLMi0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5XaWRnZXRDb25maWdCA+BBAlIMd2lkZ2V0Q29uZmlnEjsKC3VwZGF0ZV9t
YXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzazLuCAoT
V2lkZ2V0Q29uZmlnU2VydmljZRLnAgoPR2V0V2lkZ2V0Q29uZmlnEjcuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5HZXRXaWRnZXRDb25maWdSZXF1ZXN0Gi0uZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5XaWRnZXRDb25maWci6wGC0+STAt0BEj4vdjEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovd2lkZ2V0Q29uZmlncy8q
fVpOEkwvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2Rh
dGFTdG9yZXMvKi93aWRnZXRDb25maWdzLyp9WksSSS92MS97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5naW5lcy8qL3dpZGdldENvbmZpZ3MvKn3aQQRu
YW1lEtkDChJVcGRhdGVXaWRnZXRDb25maWcSOi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLlVwZGF0ZVdpZGdldENvbmZpZ1JlcXVlc3QaLS5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLldpZGdldENvbmZpZyLXAoLT5JMCtAIyTC92MS97d2lkZ2V0X2NvbmZp
Zy5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3dpZGdldENvbmZp
Z3MvKn06DXdpZGdldF9jb25maWdaazJaL3YxL3t3aWRnZXRfY29uZmlnLm5hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi93aWRnZXRDb25m
aWdzLyp9Og13aWRnZXRfY29uZmlnWmgyVy92MS97d2lkZ2V0X2NvbmZpZy5uYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyovd2lkZ2V0Q29uZmln
cy8qfToNd2lkZ2V0X2NvbmZpZ9pBGXdpZGdldF9jb25maWcsdXBkYXRlX21hc2sakALKQR5k
aXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQesBaHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9h
dXRoL2Rpc2NvdmVyeWVuZ2luZS5hc3Npc3QucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0ZSxodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2aW5nLnJlYWR3cml0ZUKL
AgojY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFCGFdpZGdldENvbmZpZ1Nl
cnZpY2VQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2
MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lO
RaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlz
Y292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUrR
IwoHEgUOAJQBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
KAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMW
AD0KCQoCAwUSAxcAKgoICgEIEgMZADwKCQoCCCUSAxkAPAoICgEIEgMaAGQKCQoCCAsSAxoA
ZAoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADkKCQoCCAgSAxwAOQoICgEIEgMdADwK
CQoCCAESAx0APAoICgEIEgMeAC0KCQoCCCQSAx4ALQoICgEIEgMfADwKCQoCCCkSAx8APAoI
CgEIEgMgADsKCQoCCC0SAyAAOwpvCgIGABIEJABKARpjIFNlcnZpY2UgZm9yIG1hbmFnaW5n
CiBbV2lkZ2V0Q29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLldpZGdl
dENvbmZpZ10gY29uZmlndXJhdGlvbi4KCgoKAwYAARIDJAgbCgoKAwYAAxIDJQJGCgwKBQYA
A5kIEgMlAkYKCwoDBgADEgQmAipKCg0KBQYAA5oIEgQmAipKClQKBAYAAgASBC0COAMaRiBH
ZXRzIGEgW1dpZGdldENvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5X
aWRnZXRDb25maWddLgoKDAoFBgACAAESAy0GFQoMCgUGAAIAAhIDLRYsCgwKBQYAAgADEgMt
N0MKDQoFBgACAAQSBC4ENgYKEQoJBgACAASwyrwiEgQuBDYGCgwKBQYAAgAEEgM3BDIKDwoI
BgACAASbCAASAzcEMgomCgQGAAIBEgQ7AkkDGhggVXBkYXRlIGEgV2lkZ2V0Q29uZmlnLgoK
DAoFBgACAQESAzsGGAoMCgUGAAIBAhIDOxkyCgwKBQYAAgEDEgM7PUkKDQoFBgACAQQSBDwE
RwYKEQoJBgACAQSwyrwiEgQ8BEcGCgwKBQYAAgEEEgNIBEcKDwoIBgACAQSbCAASA0gERwqP
AQoCBAASBE8AewEaggEgUmVxdWVzdCBmb3IKIFtXaWRnZXRDb25maWdTZXJ2aWNlLkdldFdp
ZGdldENvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5XaWRnZXRDb25m
aWdTZXJ2aWNlLkdldFdpZGdldENvbmZpZ10KIG1ldGhvZC4KCgoKAwQAARIDTwgeCjMKBAQA
AwASBFECVgMaJSBPcHRpb25zIGZvciBHZXRXaWRnZXRDb25maWdSZXF1ZXN0LgoKDAoFBAAD
AAESA1EKJgp/CgYEAAMAAgASBFQEVTEabyBPcHRpb25hbC4gV2hldGhlciB0byB0dXJuIG9m
ZiBjb2xsZWN0aW9uX2NvbXBvbmVudHMgaW4gV2lkZ2V0Q29uZmlnIHRvCiByZWR1Y2UgbGF0
ZW5jeSBhbmQgZGF0YSB0cmFuc21pc3Npb24uCgoOCgcEAAMAAgAFEgNUBAgKDgoHBAADAAIA
ARIDVAknCg4KBwQAAwACAAMSA1QqKwoOCgcEAAMAAgAIEgNVCDAKEQoKBAADAAIACJwIABID
VQkvCsYBCgQEAAIAEgRaAl8EGrcBIFJlcXVpcmVkLiBGdWxsIFdpZGdldENvbmZpZyByZXNv
dXJjZSBuYW1lLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9kYXRhU3RvcmVzL3tkYXRhX3N0
b3JlX2lkfS93aWRnZXRDb25maWdzL3t3aWRnZXRfY29uZmlnX2lkfWAKCgwKBQQAAgAFEgNa
AggKDAoFBAACAAESA1oJDQoMCgUEAAIAAxIDWhARCg0KBQQAAgAIEgRaEl8DCg8KCAQAAgAI
nAgAEgNbBCoKDwoHBAACAAifCBIEXAReBQqJAwoEBAACARIDZwJBGvsCIE9wdGlvbmFsLiBX
aGV0aGVyIGl0J3MgYWNjZXB0YWJsZSB0byBsb2FkIHRoZSB3aWRnZXQgY29uZmlnIGZyb20g
Y2FjaGUuIElmCiBzZXQgdG8gdHJ1ZSwgcmVjZW50IGNoYW5nZXMgb24gd2lkZ2V0IGNvbmZp
Z3MgbWF5IHRha2UgYSBmZXcgbWludXRlcyB0bwogcmVmbGVjdCBvbiB0aGUgZW5kIHVzZXIn
cyB2aWV3LiBJdCdzIHJlY29tbWVuZGVkIHRvIHNldCB0byB0cnVlIGZvcgogbWF0dXJlbHkg
ZGV2ZWxvcGVkIHdpZGdldHMsIGFzIGl0IGltcHJvdmVzIHdpZGdldCBwZXJmb3JtYW5jZS4g
U2V0IHRvIGZhbHNlCiB0byBzZWUgY2hhbmdlcyByZWZsZWN0ZWQgaW4gcHJvZCByaWdodCBh
d2F5LCBpZiB5b3VyIHdpZGdldCBpcyB1bmRlcgogZGV2ZWxvcG1lbnQuCgoMCgUEAAIBBRID
ZwIGCgwKBQQAAgEBEgNnBxMKDAoFBAACAQMSA2cWFwoMCgUEAAIBCBIDZxhACg8KCAQAAgEI
nAgAEgNnGT8KPQoEBAACAhIEagJrLxovIE9wdGlvbmFsLiBPcHRpb25zIGZvciBHZXRXaWRn
ZXRDb25maWdSZXF1ZXN0LgoKDAoFBAACAgYSA2oCHgoMCgUEAAICARIDah8/CgwKBQQAAgID
EgNqQkMKDAoFBAACAggSA2sGLgoPCggEAAICCJwIABIDawctCqQCCgQEAAIDEgNyAkQalgIg
T3B0aW9uYWwuIEJDUC00NyBsYW5ndWFnZSB0YWcgKGUuZy4gImVuIiwgImZyLUNBIikuIFVz
ZWQgdG8gbG9jYWxpemUKIGh1bWFuLXJlYWRhYmxlIHN0cmluZ3MgaW4gdGhlIHJlc3BvbnNl
LCBzdWNoIGFzIHRoZSBtb2RlbCBzZWxlY3RvcgogYGRpc3BsYXlfbmFtZWAgLyBgZGVzY3Jp
cHRpb25gIG9uCiBgV2lkZ2V0Q29uZmlnLlVpU2V0dGluZ3MuTW9kZWxDb25maWdJbmZvYC4g
RW1wdHkgLyB1bnNldCBmYWxscyBiYWNrIHRvCiB0aGUgZGVmYXVsdCBsYW5ndWFnZSAoRW5n
bGlzaCkuCgoMCgUEAAIDBRIDcgIICgwKBQQAAgMBEgNyCRYKDAoFBAACAwMSA3IZGgoMCgUE
AAIDCBIDchtDCg8KCAQAAgMInAgAEgNyHEIKowMKBAQAAgQSA3oCTRqVAyBPcHRpb25hbC4g
U2VsZWN0cyB3aGljaCB2aWV3IG9mIGBXaWRnZXRDb25maWcuVWlTZXR0aW5ncy5Nb2RlbENv
bmZpZ0luZm9gCiB0aGUgYmFja2VuZCBjb21wdXRlcy4gYEFETUlOYCBpcyBzZXQgYnkgdGhl
IENsb3VkIENvbnNvbGUgYWRtaW4gIkZlYXR1cmUKIE1hbmFnZW1lbnQiIHBhZ2UgdG8gcmVj
ZWl2ZSB0aGUgYWRtaW4tc3VyZmFjZWQKIG1vZGVsIHNldCB3aXRoIGBSZXNvbHZlZE1vZGVs
LmFkbWluX3ZpZXdgIHBvcHVsYXRlZDsgYEVORF9VU0VSX01PQklMRWAgaXMKIHNldCBieSB0
aGUgR2VtaW5pIEVudGVycHJpc2UgbW9iaWxlIGFwcCB0byByZWNlaXZlIHRoZSBtb2JpbGUg
bW9kZWwgc2V0OwogdW5zZXQgLyBgRU5EX1VTRVJfV0VCYCByZXR1cm5zIHRoZSBlbmQtdXNl
ciB3ZWIgc2VsZWN0b3IuCgoMCgUEAAIEBhIDegIPCgwKBQQAAgQBEgN6EB8KDAoFBAACBAMS
A3oiIwoMCgUEAAIECBIDeiRMCg8KCAQAAgQInAgAEgN6JUsKlwEKAgQBEgaAAQCUAQEaiAEg
UmVxdWVzdCBmb3IKIFtXaWRnZXRDb25maWdTZXJ2aWNlLlVwZGF0ZVdpZGdldENvbmZpZ11b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5XaWRnZXRDb25maWdTZXJ2aWNlLlVw
ZGF0ZVdpZGdldENvbmZpZ10KIG1ldGhvZC4KCgsKAwQBARIEgAEIIQqKAwoEBAECABIEigEC
Shr7AiBSZXF1aXJlZC4gVGhlIFtXaWRnZXRDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuV2lkZ2V0Q29uZmlnXQogdG8gdXBkYXRlLgoKIElmIHRoZSBjYWxsZXIg
ZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIHVwZGF0ZSB0aGUKIFtXaWRnZXRDb25maWdd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuV2lkZ2V0Q29uZmlnXSwgdGhlbiBh
CiBQRVJNSVNTSU9OX0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW1dpZGdl
dENvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5XaWRnZXRDb25maWdd
IHRvCiB1cGRhdGUgZG9lcyBub3QgZXhpc3QsIGEgTk9UX0ZPVU5EIGVycm9yIGlzIHJldHVy
bmVkLgoKDQoFBAECAAYSBIoBAg4KDQoFBAECAAESBIoBDxwKDQoFBAECAAMSBIoBHyAKDQoF
BAECAAgSBIoBIUkKEAoIBAECAAicCAASBIoBIkgKxwIKBAQBAgESBJMBAiwauAIgSW5kaWNh
dGVzIHdoaWNoIGZpZWxkcyBpbiB0aGUgcHJvdmlkZWQKIFtXaWRnZXRDb25maWddW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuV2lkZ2V0Q29uZmlnXSB0byB1cGRhdGUuIFRo
ZQogZm9sbG93aW5nIGFyZSB0aGUgb25seSBzdXBwb3J0ZWQgZmllbGRzOgoKICogW1dpZGdl
dENvbmZpZy5lbmFibGVfYXV0b2NvbXBsZXRlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLldpZGdldENvbmZpZy5lbmFibGVfYXV0b2NvbXBsZXRlXQoKIElmIG5vdCBzZXQs
IGFsbCBzdXBwb3J0ZWQgZmllbGRzIGFyZSB1cGRhdGVkLgoKDQoFBAECAQYSBJMBAhsKDQoF
BAECAQESBJMBHCcKDQoFBAECAQMSBJMBKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest ===
    # Fields for GetWidgetConfigRequest
    # Field: name Type: 9 ()
    # Field: accept_cache Type: 8 ()
    # Field: get_widget_config_request_option Type: 11 (.google.cloud.discoveryengine.v1.GetWidgetConfigRequest.GetWidgetConfigRequestOption)
    # Field: language_code Type: 9 ()
    # Field: model_info_view Type: 14 (.google.cloud.discoveryengine.v1.ModelInfoView)

# === Message: Google::Cloud::Discoveryengine::V1::WidgetConfigService::UpdateWidgetConfigRequest ===
    # Fields for UpdateWidgetConfigRequest
    # Field: widget_config Type: 11 (.google.cloud.discoveryengine.v1.WidgetConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Discoveryengine::V1::WidgetConfigService::WidgetConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1::WidgetConfigService::WidgetConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::WidgetConfigService::WidgetConfigServiceClient

Client stub representing the remote C<WidgetConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub get_widget_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.WidgetConfigService',
        method         => 'GetWidgetConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig',
    });
}

sub update_widget_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::WidgetConfigService::UpdateWidgetConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.WidgetConfigService',
        method         => 'UpdateWidgetConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::WidgetConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/widget_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::WidgetConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest->new({
        name => $name,
        accept_cache => $accept_cache,
        get_widget_config_request_option => $get_widget_config_request_option,
        language_code => $language_code,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/widget_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest

Request for
[WidgetConfigService.GetWidgetConfig][google.cloud.discoveryengine.v1.WidgetConfigService.GetWidgetConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full WidgetConfig resource name. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}/widgetConfigs/{widget_config_id}`

=item * C<< $msg->accept_cache() >> / C<< $msg->accept_cache($value) >>

Type: C<Bool>

Optional. Whether it's acceptable to load the widget config from cache. If
set to true, recent changes on widget configs may take a few minutes to
reflect on the end user's view. It's recommended to set to true for
maturely developed widgets, as it improves widget performance. Set to false
to see changes reflected in prod right away, if your widget is under
development.

=item * C<< $msg->get_widget_config_request_option() >> / C<< $msg->get_widget_config_request_option($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest::GetWidgetConfigRequestOption>)

Optional. Options for GetWidgetConfigRequest.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

Optional. BCP-47 language tag (e.g. "en", "fr-CA"). Used to localize
human-readable strings in the response, such as the model selector
`display_name` / `description` on
`WidgetConfig.UiSettings.ModelConfigInfo`. Empty / unset falls back to
the default language (English).

=item * C<< $msg->model_info_view() >> / C<< $msg->model_info_view($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::ModelInfoView>)

Optional. Selects which view of `WidgetConfig.UiSettings.ModelConfigInfo`
the backend computes. `ADMIN` is set by the Cloud Console admin "Feature
Management" page to receive the admin-surfaced
model set with `ResolvedModel.admin_view` populated; `END_USER_MOBILE` is
set by the Gemini Enterprise mobile app to receive the mobile model set;
unset / `END_USER_WEB` returns the end-user web selector.

=back

=head2 Google::Cloud::Discoveryengine::V1::WidgetConfigService::UpdateWidgetConfigRequest

Request for
[WidgetConfigService.UpdateWidgetConfig][google.cloud.discoveryengine.v1.WidgetConfigService.UpdateWidgetConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->widget_config() >> / C<< $msg->widget_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig>)

Required. The [WidgetConfig][google.cloud.discoveryengine.v1.WidgetConfig]
to update.

If the caller does not have permission to update the
[WidgetConfig][google.cloud.discoveryengine.v1.WidgetConfig], then a
PERMISSION_DENIED error is returned.

If the [WidgetConfig][google.cloud.discoveryengine.v1.WidgetConfig] to
update does not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[WidgetConfig][google.cloud.discoveryengine.v1.WidgetConfig] to update. The
following are the only supported fields:

* [WidgetConfig.enable_autocomplete][google.cloud.discoveryengine.v1.WidgetConfig.enable_autocomplete]

If not set, all supported fields are updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::WidgetConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
