package Google::Cloud::Discoveryengine::V1beta::RecommendationService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Document };
    eval { require Google::Cloud::Discoveryengine::V1beta::UserEvent };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9yZWNvbW1lbmRhdGlvbl9z
ZXJ2aWNlLnByb3RvEiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dv
b2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aMmdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFiZXRhL2RvY3VtZW50LnByb3Rv
GjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS91c2VyX2V2ZW50LnByb3Rv
Ghxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvIvIEChBSZWNvbW1lbmRSZXF1ZXN0ElsK
DnNlcnZpbmdfY29uZmlnGAEgASgJQjTgQQL6QS4KLGRpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbS9TZXJ2aW5nQ29uZmlnUg1zZXJ2aW5nQ29uZmlnElIKCnVzZXJfZXZlbnQYAiAB
KAsyLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Vc2VyRXZlbnRCA+BB
AlIJdXNlckV2ZW50EhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUSFgoGZmlsdGVyGAQg
ASgJUgZmaWx0ZXISIwoNdmFsaWRhdGVfb25seRgFIAEoCFIMdmFsaWRhdGVPbmx5ElkKBnBh
cmFtcxgGIAMoCzJBLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJlY29t
bWVuZFJlcXVlc3QuUGFyYW1zRW50cnlSBnBhcmFtcxJmCgt1c2VyX2xhYmVscxgIIAMoCzJF
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJlY29tbWVuZFJlcXVlc3Qu
VXNlckxhYmVsc0VudHJ5Ugp1c2VyTGFiZWxzGlEKC1BhcmFtc0VudHJ5EhAKA2tleRgBIAEo
CVIDa2V5EiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZToC
OAEaPQoPVXNlckxhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZToCOAEirQQKEVJlY29tbWVuZFJlc3BvbnNlEmUKB3Jlc3VsdHMYASADKAsySy5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5SZWNvbW1lbmRSZXNwb25zZS5S
ZWNvbW1lbmRhdGlvblJlc3VsdFIHcmVzdWx0cxIrChFhdHRyaWJ1dGlvbl90b2tlbhgCIAEo
CVIQYXR0cmlidXRpb25Ub2tlbhIfCgttaXNzaW5nX2lkcxgDIAMoCVIKbWlzc2luZ0lkcxIj
Cg12YWxpZGF0ZV9vbmx5GAQgASgIUgx2YWxpZGF0ZU9ubHkavQIKFFJlY29tbWVuZGF0aW9u
UmVzdWx0Eg4KAmlkGAEgASgJUgJpZBJJCghkb2N1bWVudBgCIAEoCzItLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRvY3VtZW50Ughkb2N1bWVudBJ1CghtZXRhZGF0
YRgDIAMoCzJZLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJlY29tbWVu
ZFJlc3BvbnNlLlJlY29tbWVuZGF0aW9uUmVzdWx0Lk1ldGFkYXRhRW50cnlSCG1ldGFkYXRh
GlMKDU1ldGFkYXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSLAoFdmFsdWUYAiABKAsyFi5n
b29nbGUucHJvdG9idWYuVmFsdWVSBXZhbHVlOgI4ATKhBQoVUmVjb21tZW5kYXRpb25TZXJ2
aWNlErUDCglSZWNvbW1lbmQSNS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5SZWNvbW1lbmRSZXF1ZXN0GjYuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuUmVjb21tZW5kUmVzcG9uc2UiuAKC0+STArECIlcvdjFiZXRhL3tzZXJ2aW5nX2NvbmZp
Zz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXJ2aW5nQ29uZmlncy8q
fTpyZWNvbW1lbmQ6ASpaaiJlL3YxYmV0YS97c2VydmluZ19jb25maWc9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKi9zZXJ2aW5nQ29uZmlncy8q
fTpyZWNvbW1lbmQ6ASpaZyJiL3YxYmV0YS97c2VydmluZ19jb25maWc9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKi9zZXJ2aW5nQ29uZmlncy8qfTpy
ZWNvbW1lbmQ6ASoazwHKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0
cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFk
d3JpdGVCoQIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIaUmVj
b21tZW5kYXRpb25TZXJ2aWNlUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3Zl
cnllbmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBi
ogIPRElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJl
dGHKAiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xv
dWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSoJFCgcSBQ4A5wEBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJ
CgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPAoJCgIDBRIDFwA+CgkKAgMGEgMYACYK
CAoBCBIDGgBACgkKAgglEgMaAEAKCAoBCBIDGwBoCgkKAggLEgMbAGgKCAoBCBIDHAAiCgkK
AggKEgMcACIKCAoBCBIDHQA7CgkKAggIEgMdADsKCAoBCBIDHgBACgkKAggBEgMeAEAKCAoB
CBIDHwAtCgkKAggkEgMfAC0KCAoBCBIDIABACgkKAggpEgMgAEAKCAoBCBIDIQA/CgkKAggt
EgMhAD8KMQoCBgASBCQAOgEaJSBTZXJ2aWNlIGZvciBtYWtpbmcgcmVjb21tZW5kYXRpb25z
LgoKCgoDBgABEgMkCB0KCgoDBgADEgMlAkYKDAoFBgADmQgSAyUCRgoLCgMGAAMSBCYCKUoK
DQoFBgADmggSBCYCKUoKTwoEBgACABIELAI5AxpBIE1ha2VzIGEgcmVjb21tZW5kYXRpb24s
IHdoaWNoIHJlcXVpcmVzIGEgY29udGV4dHVhbCB1c2VyIGV2ZW50LgoKDAoFBgACAAESAywG
DwoMCgUGAAIAAhIDLBAgCgwKBQYAAgADEgMsKzwKDQoFBgACAAQSBC0EOAYKEQoJBgACAASw
yrwiEgQtBDgGCjQKAgQAEgU9AL0BARonIFJlcXVlc3QgbWVzc2FnZSBmb3IgUmVjb21tZW5k
IG1ldGhvZC4KCgoKAwQAARIDPQgYCuAFCgQEAAIAEgRLAlAEGtEFIFJlcXVpcmVkLiBGdWxs
IHJlc291cmNlIG5hbWUgb2YgYQogW1NlcnZpbmdDb25maWddW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFiZXRhLlNlcnZpbmdDb25maWddOgogYHByb2plY3RzLyovbG9jYXRp
b25zL2dsb2JhbC9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKi9zZXJ2aW5nQ29uZmlncy8qYCwg
b3IKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMvKi9kYXRhU3Rv
cmVzLyovc2VydmluZ0NvbmZpZ3MvKmAKCiBPbmUgZGVmYXVsdCBzZXJ2aW5nIGNvbmZpZyBp
cyBjcmVhdGVkIGFsb25nIHdpdGggeW91ciByZWNvbW1lbmRhdGlvbiBlbmdpbmUKIGNyZWF0
aW9uLiBUaGUgZW5naW5lIElEIGlzIHVzZWQgYXMgdGhlIElEIG9mIHRoZSBkZWZhdWx0IHNl
cnZpbmcKIGNvbmZpZy4gRm9yIGV4YW1wbGUsIGZvciBFbmdpbmUKIGBwcm9qZWN0cy8qL2xv
Y2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMvKi9lbmdpbmVzL215LWVuZ2luZWAsIHlvdSBj
YW4gdXNlCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2NvbGxlY3Rpb25zLyovZW5n
aW5lcy9teS1lbmdpbmUvc2VydmluZ0NvbmZpZ3MvbXktZW5naW5lYAogZm9yIHlvdXIKIFtS
ZWNvbW1lbmRhdGlvblNlcnZpY2UuUmVjb21tZW5kXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5SZWNvbW1lbmRhdGlvblNlcnZpY2UuUmVjb21tZW5kXQogcmVxdWVz
dHMuCgoMCgUEAAIABRIDSwIICgwKBQQAAgABEgNLCRcKDAoFBAACAAMSA0saGwoNCgUEAAIA
CBIESxxQAwoPCggEAAIACJwIABIDTAQqCg8KBwQAAgAInwgSBE0ETwUK5gYKBAQAAgESA2IC
RBrYBiBSZXF1aXJlZC4gQ29udGV4dCBhYm91dCB0aGUgdXNlciwgd2hhdCB0aGV5IGFyZSBs
b29raW5nIGF0IGFuZCB3aGF0IGFjdGlvbgogdGhleSB0b29rIHRvIHRyaWdnZXIgdGhlIFJl
Y29tbWVuZCByZXF1ZXN0LiBOb3RlIHRoYXQgdGhpcyB1c2VyIGV2ZW50CiBkZXRhaWwgd29u
J3QgYmUgaW5nZXN0ZWQgdG8gdXNlckV2ZW50IGxvZ3MuIFRodXMsIGEgc2VwYXJhdGUgdXNl
ckV2ZW50CiB3cml0ZSByZXF1ZXN0IGlzIHJlcXVpcmVkIGZvciBldmVudCBsb2dnaW5nLgoK
IERvbid0IHNldAogW1VzZXJFdmVudC51c2VyX3BzZXVkb19pZF1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuVXNlckV2ZW50LnVzZXJfcHNldWRvX2lkXQogb3IKIFtV
c2VyRXZlbnQudXNlcl9pbmZvLnVzZXJfaWRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFiZXRhLlVzZXJJbmZvLnVzZXJfaWRdCiB0byB0aGUgc2FtZSBmaXhlZCBJRCBmb3Ig
ZGlmZmVyZW50IHVzZXJzLiBJZiB5b3UgYXJlIHRyeWluZyB0byByZWNlaXZlCiBub24tcGVy
c29uYWxpemVkIHJlY29tbWVuZGF0aW9ucyAobm90IHJlY29tbWVuZGVkOyB0aGlzIGNhbiBu
ZWdhdGl2ZWx5CiBpbXBhY3QgbW9kZWwgcGVyZm9ybWFuY2UpLCBpbnN0ZWFkIHNldAogW1Vz
ZXJFdmVudC51c2VyX3BzZXVkb19pZF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuVXNlckV2ZW50LnVzZXJfcHNldWRvX2lkXQogdG8gYSByYW5kb20gdW5pcXVlIElE
IGFuZCBsZWF2ZQogW1VzZXJFdmVudC51c2VyX2luZm8udXNlcl9pZF1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVXNlckluZm8udXNlcl9pZF0KIHVuc2V0LgoKDAoF
BAACAQYSA2ICCwoMCgUEAAIBARIDYgwWCgwKBQQAAgEDEgNiGRoKDAoFBAACAQgSA2IbQwoP
CggEAAIBCJwIABIDYhxCCu8BCgQEAAICEgNoAhYa4QEgTWF4aW11bSBudW1iZXIgb2YgcmVz
dWx0cyB0byByZXR1cm4uIFNldCB0aGlzIHByb3BlcnR5CiB0byB0aGUgbnVtYmVyIG9mIHJl
Y29tbWVuZGF0aW9uIHJlc3VsdHMgbmVlZGVkLiBJZiB6ZXJvLCB0aGUgc2VydmljZQogY2hv
b3NlcyBhIHJlYXNvbmFibGUgZGVmYXVsdC4gVGhlIG1heGltdW0gYWxsb3dlZCB2YWx1ZSBp
cyAxMDAuIFZhbHVlcwogYWJvdmUgMTAwIGFyZSBzZXQgdG8gMTAwLgoKDAoFBAACAgUSA2gC
BwoMCgUEAAICARIDaAgRCgwKBQQAAgIDEgNoFBUKjgkKBAQAAgMSBIUBAhQa/wggRmlsdGVy
IGZvciByZXN0cmljdGluZyByZWNvbW1lbmRhdGlvbiByZXN1bHRzIHdpdGggYSBsZW5ndGgg
bGltaXQgb2YgNSwwMDAKIGNoYXJhY3RlcnMuIEN1cnJlbnRseSwgb25seSBmaWx0ZXIgZXhw
cmVzc2lvbnMgb24gdGhlIGBmaWx0ZXJfdGFnc2AKIGF0dHJpYnV0ZSBpcyBzdXBwb3J0ZWQu
CgoKIEV4YW1wbGVzOgoKICAqIGAoZmlsdGVyX3RhZ3M6IEFOWSgiUmVkIiwgIkJsdWUiKSBP
UiBmaWx0ZXJfdGFnczogQU5ZKCJIb3QiLCAiQ29sZCIpKWAKICAqIGAoZmlsdGVyX3RhZ3M6
IEFOWSgiUmVkIiwgIkJsdWUiKSkgQU5EIE5PVCAoZmlsdGVyX3RhZ3M6IEFOWSgiR3JlZW4i
KSlgCgogSWYgYGF0dHJpYnV0ZUZpbHRlcmluZ1N5bnRheGAgaXMgc2V0IHRvIHRydWUgdW5k
ZXIgdGhlIGBwYXJhbXNgIGZpZWxkLCB0aGVuCiBhdHRyaWJ1dGUtYmFzZWQgZXhwcmVzc2lv
bnMgYXJlIGV4cGVjdGVkIGluc3RlYWQgb2YgdGhlIGFib3ZlIGRlc2NyaWJlZAogdGFnLWJh
c2VkIHN5bnRheC4gRXhhbXBsZXM6CgogICogKGxhbmd1YWdlOiBBTlkoImVuIiwgImVzIikp
IEFORCBOT1QgKGNhdGVnb3JpZXM6IEFOWSgiTW92aWUiKSkKICAqIChhdmFpbGFibGU6IHRy
dWUpIEFORAogICAgKGxhbmd1YWdlOiBBTlkoImVuIiwgImVzIikpIE9SIChjYXRlZ29yaWVz
OiBBTlkoIk1vdmllIikpCgogSWYgeW91ciBmaWx0ZXIgYmxvY2tzIGFsbCByZXN1bHRzLCB0
aGUgQVBJIHJldHVybnMgZ2VuZXJpYwogKHVuZmlsdGVyZWQpIHBvcHVsYXIgRG9jdW1lbnRz
LiBJZiB5b3Ugb25seSB3YW50IHJlc3VsdHMgc3RyaWN0bHkgbWF0Y2hpbmcKIHRoZSBmaWx0
ZXJzLCBzZXQgYHN0cmljdEZpbHRlcmluZ2AgdG8gYHRydWVgIGluCiBbUmVjb21tZW5kUmVx
dWVzdC5wYXJhbXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJlY29t
bWVuZFJlcXVlc3QucGFyYW1zXQogdG8gcmVjZWl2ZSBlbXB0eSByZXN1bHRzIGluc3RlYWQu
CgogTm90ZSB0aGF0IHRoZSBBUEkgbmV2ZXIgcmV0dXJucwogW0RvY3VtZW50XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Eb2N1bWVudF1zIHdpdGgKIGBzdG9yYWdl
U3RhdHVzYCBhcyBgRVhQSVJFRGAgb3IgYERFTEVURURgIHJlZ2FyZGxlc3Mgb2YgZmlsdGVy
IGNob2ljZXMuCgoNCgUEAAIDBRIEhQECCAoNCgUEAAIDARIEhQEJDwoNCgUEAAIDAxIEhQES
Ewr9AQoEBAACBBIEiwECGRruASBVc2UgdmFsaWRhdGUgb25seSBtb2RlIGZvciB0aGlzIHJl
Y29tbWVuZGF0aW9uIHF1ZXJ5LiBJZiBzZXQgdG8gYHRydWVgLCBhCiBmYWtlIG1vZGVsIGlz
IHVzZWQgdGhhdCByZXR1cm5zIGFyYml0cmFyeSBEb2N1bWVudCBJRHMuCiBOb3RlIHRoYXQg
dGhlIHZhbGlkYXRlIG9ubHkgbW9kZSBzaG91bGQgb25seSBiZSB1c2VkIGZvciB0ZXN0aW5n
IHRoZSBBUEksCiBvciBpZiB0aGUgbW9kZWwgaXMgbm90IHJlYWR5LgoKDQoFBAACBAUSBIsB
AgYKDQoFBAACBAESBIsBBxQKDQoFBAACBAMSBIsBFxgK+woKBAQAAgUSBKkBAjAa7AogQWRk
aXRpb25hbCBkb21haW4gc3BlY2lmaWMgcGFyYW1ldGVycyBmb3IgdGhlIHJlY29tbWVuZGF0
aW9ucy4KCiBBbGxvd2VkIHZhbHVlczoKCiAqIGByZXR1cm5Eb2N1bWVudGA6IEJvb2xlYW4u
IElmIHNldCB0byBgdHJ1ZWAsIHRoZSBhc3NvY2lhdGVkIERvY3VtZW50CiAgICBvYmplY3Qg
aXMgcmV0dXJuZWQgaW4KICAgIFtSZWNvbW1lbmRSZXNwb25zZS5SZWNvbW1lbmRhdGlvblJl
c3VsdC5kb2N1bWVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuUmVj
b21tZW5kUmVzcG9uc2UuUmVjb21tZW5kYXRpb25SZXN1bHQuZG9jdW1lbnRdLgogKiBgcmV0
dXJuU2NvcmVgOiBCb29sZWFuLiBJZiBzZXQgdG8gdHJ1ZSwgdGhlIHJlY29tbWVuZGF0aW9u
IHNjb3JlCiAgICBjb3JyZXNwb25kaW5nIHRvIGVhY2ggcmV0dXJuZWQgRG9jdW1lbnQgaXMg
c2V0IGluCiAgICBbUmVjb21tZW5kUmVzcG9uc2UuUmVjb21tZW5kYXRpb25SZXN1bHQubWV0
YWRhdGFdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJlY29tbWVuZFJl
c3BvbnNlLlJlY29tbWVuZGF0aW9uUmVzdWx0Lm1ldGFkYXRhXS4KICAgIFRoZSBnaXZlbiBz
Y29yZSBpbmRpY2F0ZXMgdGhlIHByb2JhYmlsaXR5IG9mIGEgRG9jdW1lbnQgY29udmVyc2lv
biBnaXZlbgogICAgdGhlIHVzZXIncyBjb250ZXh0IGFuZCBoaXN0b3J5LgogKiBgc3RyaWN0
RmlsdGVyaW5nYDogQm9vbGVhbi4gVHJ1ZSBieSBkZWZhdWx0LiBJZiBzZXQgdG8gYGZhbHNl
YCwgdGhlCiBzZXJ2aWNlCiAgICByZXR1cm5zIGdlbmVyaWMgKHVuZmlsdGVyZWQpIHBvcHVs
YXIgRG9jdW1lbnRzIGluc3RlYWQgb2YgZW1wdHkgaWYKICAgIHlvdXIgZmlsdGVyIGJsb2Nr
cyBhbGwgcmVjb21tZW5kYXRpb24gcmVzdWx0cy4KICogYGRpdmVyc2l0eUxldmVsYDogU3Ry
aW5nLiBEZWZhdWx0IGVtcHR5LiBJZiBzZXQgdG8gYmUgbm9uLWVtcHR5LCB0aGVuCiAgICBp
dCBuZWVkcyB0byBiZSBvbmUgb2Y6CiAgICAgKiAgYG5vLWRpdmVyc2l0eWAKICAgICAqICBg
bG93LWRpdmVyc2l0eWAKICAgICAqICBgbWVkaXVtLWRpdmVyc2l0eWAKICAgICAqICBgaGln
aC1kaXZlcnNpdHlgCiAgICAgKiAgYGF1dG8tZGl2ZXJzaXR5YAogICAgVGhpcyBnaXZlcyBy
ZXF1ZXN0LWxldmVsIGNvbnRyb2wgYW5kIGFkanVzdHMgcmVjb21tZW5kYXRpb24gcmVzdWx0
cwogICAgYmFzZWQgb24gRG9jdW1lbnQgY2F0ZWdvcnkuCiAqIGBhdHRyaWJ1dGVGaWx0ZXJp
bmdTeW50YXhgOiBCb29sZWFuLiBGYWxzZSBieSBkZWZhdWx0LiBJZiBzZXQgdG8gdHJ1ZSwK
ICAgIHRoZSBgZmlsdGVyYCBmaWVsZCBpcyBpbnRlcnByZXRlZCBhY2NvcmRpbmcgdG8gdGhl
IG5ldywKICAgIGF0dHJpYnV0ZS1iYXNlZCBzeW50YXguCgoNCgUEAAIFBhIEqQECJAoNCgUE
AAIFARIEqQElKwoNCgUEAAIFAxIEqQEuLwruBgoEBAACBhIEvAECJhrfBiBUaGUgdXNlciBs
YWJlbHMgYXBwbGllZCB0byBhIHJlc291cmNlIG11c3QgbWVldCB0aGUgZm9sbG93aW5nIHJl
cXVpcmVtZW50czoKCiAqIEVhY2ggcmVzb3VyY2UgY2FuIGhhdmUgbXVsdGlwbGUgbGFiZWxz
LCB1cCB0byBhIG1heGltdW0gb2YgNjQuCiAqIEVhY2ggbGFiZWwgbXVzdCBiZSBhIGtleS12
YWx1ZSBwYWlyLgogKiBLZXlzIGhhdmUgYSBtaW5pbXVtIGxlbmd0aCBvZiAxIGNoYXJhY3Rl
ciBhbmQgYSBtYXhpbXVtIGxlbmd0aCBvZiA2MwogICBjaGFyYWN0ZXJzIGFuZCBjYW5ub3Qg
YmUgZW1wdHkuIFZhbHVlcyBjYW4gYmUgZW1wdHkgYW5kIGhhdmUgYSBtYXhpbXVtCiAgIGxl
bmd0aCBvZiA2MyBjaGFyYWN0ZXJzLgogKiBLZXlzIGFuZCB2YWx1ZXMgY2FuIGNvbnRhaW4g
b25seSBsb3dlcmNhc2UgbGV0dGVycywgbnVtZXJpYyBjaGFyYWN0ZXJzLAogICB1bmRlcnNj
b3JlcywgYW5kIGRhc2hlcy4gQWxsIGNoYXJhY3RlcnMgbXVzdCB1c2UgVVRGLTggZW5jb2Rp
bmcsIGFuZAogICBpbnRlcm5hdGlvbmFsIGNoYXJhY3RlcnMgYXJlIGFsbG93ZWQuCiAqIFRo
ZSBrZXkgcG9ydGlvbiBvZiBhIGxhYmVsIG11c3QgYmUgdW5pcXVlLiBIb3dldmVyLCB5b3Ug
Y2FuIHVzZSB0aGUgc2FtZQogICBrZXkgd2l0aCBtdWx0aXBsZSByZXNvdXJjZXMuCiAqIEtl
eXMgbXVzdCBzdGFydCB3aXRoIGEgbG93ZXJjYXNlIGxldHRlciBvciBpbnRlcm5hdGlvbmFs
IGNoYXJhY3Rlci4KCiBTZWUgW1JlcXVpcmVtZW50cyBmb3IKIGxhYmVsc10oaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy9jcmVhdGluZy1tYW5hZ2lu
Zy1sYWJlbHMjcmVxdWlyZW1lbnRzKQogZm9yIG1vcmUgZGV0YWlscy4KCg0KBQQAAgYGEgS8
AQIVCg0KBQQAAgYBEgS8ARYhCg0KBQQAAgYDEgS8ASQlCjYKAgQBEgbAAQDnAQEaKCBSZXNw
b25zZSBtZXNzYWdlIGZvciBSZWNvbW1lbmQgbWV0aG9kLgoKCwoDBAEBEgTAAQgZCmwKBAQB
AwASBsMBAtMBAxpcIFJlY29tbWVuZGF0aW9uUmVzdWx0IHJlcHJlc2VudHMgYSBnZW5lcmlj
IHJlY29tbWVuZGF0aW9uIHJlc3VsdCB3aXRoCiBhc3NvY2lhdGVkIG1ldGFkYXRhLgoKDQoF
BAEDAAESBMMBCh4KOgoGBAEDAAIAEgTFAQQSGiogUmVzb3VyY2UgSUQgb2YgdGhlIHJlY29t
bWVuZGVkIERvY3VtZW50LgoKDwoHBAEDAAIABRIExQEECgoPCgcEAQMAAgABEgTFAQsNCg8K
BwQBAwACAAMSBMUBEBEKlQEKBgQBAwACARIEyQEEGhqEASBTZXQgaWYgYHJldHVybkRvY3Vt
ZW50YCBpcyBzZXQgdG8gdHJ1ZSBpbgogW1JlY29tbWVuZFJlcXVlc3QucGFyYW1zXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5SZWNvbW1lbmRSZXF1ZXN0LnBhcmFt
c10uCgoPCgcEAQMAAgEGEgTJAQQMCg8KBwQBAwACAQESBMkBDRUKDwoHBAEDAAIBAxIEyQEY
GQqNAgoGBAEDAAICEgTSAQQ0GvwBIEFkZGl0aW9uYWwgRG9jdW1lbnQgbWV0YWRhdGEgb3Ig
YW5ub3RhdGlvbnMuCgogUG9zc2libGUgdmFsdWVzOgoKICogYHNjb3JlYDogUmVjb21tZW5k
YXRpb24gc2NvcmUgaW4gZG91YmxlIHZhbHVlLiBJcyBzZXQgaWYKICAgYHJldHVyblNjb3Jl
YCBpcyBzZXQgdG8gdHJ1ZSBpbgogICBbUmVjb21tZW5kUmVxdWVzdC5wYXJhbXNdW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJlY29tbWVuZFJlcXVlc3QucGFyYW1z
XS4KCg8KBwQBAwACAgYSBNIBBCYKDwoHBAEDAAICARIE0gEnLwoPCgcEAQMAAgIDEgTSATIz
CoIBCgQEAQIAEgTXAQIsGnQgQSBsaXN0IG9mIHJlY29tbWVuZGVkIERvY3VtZW50cy4gVGhl
IG9yZGVyIHJlcHJlc2VudHMgdGhlIHJhbmtpbmcgKGZyb20gdGhlCiBtb3N0IHJlbGV2YW50
IERvY3VtZW50IHRvIHRoZSBsZWFzdCkuCgoNCgUEAQIABBIE1wECCgoNCgUEAQIABhIE1wEL
HwoNCgUEAQIAARIE1wEgJwoNCgUEAQIAAxIE1wEqKwr6AQoEBAECARIE3QECHxrrASBBIHVu
aXF1ZSBhdHRyaWJ1dGlvbiB0b2tlbi4gVGhpcyBzaG91bGQgYmUgaW5jbHVkZWQgaW4gdGhl
CiBbVXNlckV2ZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Vc2Vy
RXZlbnRdIGxvZ3MgcmVzdWx0aW5nCiBmcm9tIHRoaXMgcmVjb21tZW5kYXRpb24sIHdoaWNo
IGVuYWJsZXMgYWNjdXJhdGUgYXR0cmlidXRpb24gb2YKIHJlY29tbWVuZGF0aW9uIG1vZGVs
IHBlcmZvcm1hbmNlLgoKDQoFBAECAQUSBN0BAggKDQoFBAECAQESBN0BCRoKDQoFBAECAQMS
BN0BHR4KhwEKBAQBAgISBOEBAiIaeSBJRHMgb2YgZG9jdW1lbnRzIGluIHRoZSByZXF1ZXN0
IHRoYXQgd2VyZSBtaXNzaW5nIGZyb20gdGhlIGRlZmF1bHQgQnJhbmNoCiBhc3NvY2lhdGVk
IHdpdGggdGhlIHJlcXVlc3RlZCBTZXJ2aW5nQ29uZmlnLgoKDQoFBAECAgQSBOEBAgoKDQoF
BAECAgUSBOEBCxEKDQoFBAECAgESBOEBEh0KDQoFBAECAgMSBOEBICEKhwEKBAQBAgMSBOYB
AhkaeSBUcnVlIGlmCiBbUmVjb21tZW5kUmVxdWVzdC52YWxpZGF0ZV9vbmx5XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5SZWNvbW1lbmRSZXF1ZXN0LnZhbGlkYXRl
X29ubHldCiB3YXMgc2V0LgoKDQoFBAECAwUSBOYBAgYKDQoFBAECAwESBOYBBxQKDQoFBAEC
AwMSBOYBFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest ===
    # Fields for RecommendRequest
    # Field: serving_config Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.discoveryengine.v1beta.UserEvent)
    # Field: page_size Type: 5 ()
    # Field: filter Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: params Type: 11 (.google.cloud.discoveryengine.v1beta.RecommendRequest.ParamsEntry)
    # Field: user_labels Type: 11 (.google.cloud.discoveryengine.v1beta.RecommendRequest.UserLabelsEntry)

# === Message: Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse ===
    # Fields for RecommendResponse
    # Field: results Type: 11 (.google.cloud.discoveryengine.v1beta.RecommendResponse.RecommendationResult)
    # Field: attribution_token Type: 9 ()
    # Field: missing_ids Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Service Client: Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendationServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendationServiceClient

Client stub representing the remote C<RecommendationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub recommend {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.RecommendationService',
        method         => 'Recommend',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::RecommendationService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/recommendation_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::RecommendationService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest->new({
        serving_config => $serving_config,
        user_event => $user_event,
        page_size => $page_size,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->serving_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/recommendation_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest

Request message for Recommend method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. Full resource name of a
[ServingConfig][google.cloud.discoveryengine.v1beta.ServingConfig]:
`projects/*/locations/global/collections/*/engines/*/servingConfigs/*`, or
`projects/*/locations/global/collections/*/dataStores/*/servingConfigs/*`

One default serving config is created along with your recommendation engine
creation. The engine ID is used as the ID of the default serving
config. For example, for Engine
`projects/*/locations/global/collections/*/engines/my-engine`, you can use
`projects/*/locations/global/collections/*/engines/my-engine/servingConfigs/my-engine`
for your
[RecommendationService.Recommend][google.cloud.discoveryengine.v1beta.RecommendationService.Recommend]
requests.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent>)

Required. Context about the user, what they are looking at and what action
they took to trigger the Recommend request. Note that this user event
detail won't be ingested to userEvent logs. Thus, a separate userEvent
write request is required for event logging.

Don't set
[UserEvent.user_pseudo_id][google.cloud.discoveryengine.v1beta.UserEvent.user_pseudo_id]
or
[UserEvent.user_info.user_id][google.cloud.discoveryengine.v1beta.UserInfo.user_id]
to the same fixed ID for different users. If you are trying to receive
non-personalized recommendations (not recommended; this can negatively
impact model performance), instead set
[UserEvent.user_pseudo_id][google.cloud.discoveryengine.v1beta.UserEvent.user_pseudo_id]
to a random unique ID and leave
[UserEvent.user_info.user_id][google.cloud.discoveryengine.v1beta.UserInfo.user_id]
unset.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of results to return. Set this property
to the number of recommendation results needed. If zero, the service
chooses a reasonable default. The maximum allowed value is 100. Values
above 100 are set to 100.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter for restricting recommendation results with a length limit of 5,000
characters. Currently, only filter expressions on the `filter_tags`
attribute is supported.


Examples:

 * `(filter_tags: ANY("Red", "Blue") OR filter_tags: ANY("Hot", "Cold"))`
 * `(filter_tags: ANY("Red", "Blue")) AND NOT (filter_tags: ANY("Green"))`

If `attributeFilteringSyntax` is set to true under the `params` field, then
attribute-based expressions are expected instead of the above described
tag-based syntax. Examples:

 * (language: ANY("en", "es")) AND NOT (categories: ANY("Movie"))
 * (available: true) AND
   (language: ANY("en", "es")) OR (categories: ANY("Movie"))

If your filter blocks all results, the API returns generic
(unfiltered) popular Documents. If you only want results strictly matching
the filters, set `strictFiltering` to `true` in
[RecommendRequest.params][google.cloud.discoveryengine.v1beta.RecommendRequest.params]
to receive empty results instead.

Note that the API never returns
[Document][google.cloud.discoveryengine.v1beta.Document]s with
`storageStatus` as `EXPIRED` or `DELETED` regardless of filter choices.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Use validate only mode for this recommendation query. If set to `true`, a
fake model is used that returns arbitrary Document IDs.
Note that the validate only mode should only be used for testing the API,
or if the model is not ready.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest::ParamsEntry>)

Additional domain specific parameters for the recommendations.

Allowed values:

* `returnDocument`: Boolean. If set to `true`, the associated Document
   object is returned in
   [RecommendResponse.RecommendationResult.document][google.cloud.discoveryengine.v1beta.RecommendResponse.RecommendationResult.document].
* `returnScore`: Boolean. If set to true, the recommendation score
   corresponding to each returned Document is set in
   [RecommendResponse.RecommendationResult.metadata][google.cloud.discoveryengine.v1beta.RecommendResponse.RecommendationResult.metadata].
   The given score indicates the probability of a Document conversion given
   the user's context and history.
* `strictFiltering`: Boolean. True by default. If set to `false`, the
service
   returns generic (unfiltered) popular Documents instead of empty if
   your filter blocks all recommendation results.
* `diversityLevel`: String. Default empty. If set to be non-empty, then
   it needs to be one of:
    *  `no-diversity`
    *  `low-diversity`
    *  `medium-diversity`
    *  `high-diversity`
    *  `auto-diversity`
   This gives request-level control and adjusts recommendation results
   based on Document category.
* `attributeFilteringSyntax`: Boolean. False by default. If set to true,
   the `filter` field is interpreted according to the new,
   attribute-based syntax.

=item * C<< $msg->user_labels() >> / C<< $msg->user_labels($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest::UserLabelsEntry>)

The user labels applied to a resource must meet the following requirements:

* Each resource can have multiple labels, up to a maximum of 64.
* Each label must be a key-value pair.
* Keys have a minimum length of 1 character and a maximum length of 63
  characters and cannot be empty. Values can be empty and have a maximum
  length of 63 characters.
* Keys and values can contain only lowercase letters, numeric characters,
  underscores, and dashes. All characters must use UTF-8 encoding, and
  international characters are allowed.
* The key portion of a label must be unique. However, you can use the same
  key with multiple resources.
* Keys must start with a lowercase letter or international character.

See [Requirements for
labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements)
for more details.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse

Response message for Recommend method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->results() >> / C<< $msg->results($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse::RecommendationResult>)

A list of recommended Documents. The order represents the ranking (from the
most relevant Document to the least).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique attribution token. This should be included in the
[UserEvent][google.cloud.discoveryengine.v1beta.UserEvent] logs resulting
from this recommendation, which enables accurate attribution of
recommendation model performance.

=item * C<< $msg->missing_ids() >> / C<< $msg->missing_ids($value) >>

Type: C<String>

IDs of documents in the request that were missing from the default Branch
associated with the requested ServingConfig.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

True if
[RecommendRequest.validate_only][google.cloud.discoveryengine.v1beta.RecommendRequest.validate_only]
was set.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::RecommendationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
