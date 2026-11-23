package Google::Ai::Generativelanguage::V1beta::ModelService;

use strict;
use warnings;

our $VERSION = '0.12';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta::Model };
    eval { require Google::Ai::Generativelanguage::V1beta::TunedModel };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9tb2RlbF9zZXJ2aWNlLnBy
b3RvEiNnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YRovZ29vZ2xlL2FpL2dl
bmVyYXRpdmVsYW5ndWFnZS92MWJldGEvbW9kZWwucHJvdG8aNWdvb2dsZS9haS9nZW5lcmF0
aXZlbGFuZ3VhZ2UvdjFiZXRhL3R1bmVkX21vZGVsLnByb3RvGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2xv
bmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90
bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8iVgoPR2V0TW9kZWxSZXF1ZXN0
EkMKBG5hbWUYASABKAlCL+BBAvpBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMu
Y29tL01vZGVsUgRuYW1lIk8KEUxpc3RNb2RlbHNSZXF1ZXN0EhsKCXBhZ2Vfc2l6ZRgCIAEo
BVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIoABChJMaXN0TW9k
ZWxzUmVzcG9uc2USQgoGbW9kZWxzGAEgAygLMiouZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWJldGEuTW9kZWxSBm1vZGVscxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW4iYAoUR2V0VHVuZWRNb2RlbFJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC
+kEuCixnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vVHVuZWRNb2RlbFIEbmFt
ZSJ7ChZMaXN0VHVuZWRNb2RlbHNSZXF1ZXN0EiAKCXBhZ2Vfc2l6ZRgBIAEoBUID4EEBUghw
YWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAIgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIY
AyABKAlCA+BBAVIGZmlsdGVyIpUBChdMaXN0VHVuZWRNb2RlbHNSZXNwb25zZRJSCgx0dW5l
ZF9tb2RlbHMYASADKAsyLy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5U
dW5lZE1vZGVsUgt0dW5lZE1vZGVscxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4iswEKF0NyZWF0ZVR1bmVkTW9kZWxSZXF1ZXN0Ei4KDnR1bmVkX21vZGVsX2lk
GAEgASgJQgPgQQFIAFIMdHVuZWRNb2RlbElkiAEBElUKC3R1bmVkX21vZGVsGAIgASgLMi8u
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuVHVuZWRNb2RlbEID4EECUgp0
dW5lZE1vZGVsQhEKD190dW5lZF9tb2RlbF9pZCK4AgoYQ3JlYXRlVHVuZWRNb2RlbE1ldGFk
YXRhElIKC3R1bmVkX21vZGVsGAUgASgJQjH6QS4KLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29n
bGVhcGlzLmNvbS9UdW5lZE1vZGVsUgp0dW5lZE1vZGVsEh8KC3RvdGFsX3N0ZXBzGAEgASgF
Ugp0b3RhbFN0ZXBzEicKD2NvbXBsZXRlZF9zdGVwcxgCIAEoBVIOY29tcGxldGVkU3RlcHMS
KwoRY29tcGxldGVkX3BlcmNlbnQYAyABKAJSEGNvbXBsZXRlZFBlcmNlbnQSUQoJc25hcHNo
b3RzGAQgAygLMjMuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuVHVuaW5n
U25hcHNob3RSCXNuYXBzaG90cyKyAQoXVXBkYXRlVHVuZWRNb2RlbFJlcXVlc3QSVQoLdHVu
ZWRfbW9kZWwYASABKAsyLy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5U
dW5lZE1vZGVsQgPgQQJSCnR1bmVkTW9kZWwSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29n
bGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2siYwoXRGVsZXRlVHVuZWRN
b2RlbFJlcXVlc3QSSAoEbmFtZRgBIAEoCUI04EEC+kEuCixnZW5lcmF0aXZlbGFuZ3VhZ2Uu
Z29vZ2xlYXBpcy5jb20vVHVuZWRNb2RlbFIEbmFtZTLNCgoMTW9kZWxTZXJ2aWNlEpQBCghH
ZXRNb2RlbBI0Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkdldE1vZGVs
UmVxdWVzdBoqLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLk1vZGVsIiaC
0+STAhkSFy92MWJldGEve25hbWU9bW9kZWxzLyp92kEEbmFtZRKsAQoKTGlzdE1vZGVscxI2
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkxpc3RNb2RlbHNSZXF1ZXN0
GjcuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuTGlzdE1vZGVsc1Jlc3Bv
bnNlIi2C0+STAhASDi92MWJldGEvbW9kZWxz2kEUcGFnZV9zaXplLHBhZ2VfdG9rZW4SqAEK
DUdldFR1bmVkTW9kZWwSOS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5H
ZXRUdW5lZE1vZGVsUmVxdWVzdBovLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFi
ZXRhLlR1bmVkTW9kZWwiK4LT5JMCHhIcL3YxYmV0YS97bmFtZT10dW5lZE1vZGVscy8qfdpB
BG5hbWUSwAEKD0xpc3RUdW5lZE1vZGVscxI7Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3Vh
Z2UudjFiZXRhLkxpc3RUdW5lZE1vZGVsc1JlcXVlc3QaPC5nb29nbGUuYWkuZ2VuZXJhdGl2
ZWxhbmd1YWdlLnYxYmV0YS5MaXN0VHVuZWRNb2RlbHNSZXNwb25zZSIygtPkkwIVEhMvdjFi
ZXRhL3R1bmVkTW9kZWxz2kEUcGFnZV9zaXplLHBhZ2VfdG9rZW4S7QEKEENyZWF0ZVR1bmVk
TW9kZWwSPC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5DcmVhdGVUdW5l
ZE1vZGVsUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ifILT5JMCIiIT
L3YxYmV0YS90dW5lZE1vZGVsczoLdHVuZWRfbW9kZWzaQQt0dW5lZF9tb2RlbNpBGnR1bmVk
X21vZGVsX2lkLHR1bmVkX21vZGVsykEmCgpUdW5lZE1vZGVsEhhDcmVhdGVUdW5lZE1vZGVs
TWV0YWRhdGES2gEKEFVwZGF0ZVR1bmVkTW9kZWwSPC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxh
bmd1YWdlLnYxYmV0YS5VcGRhdGVUdW5lZE1vZGVsUmVxdWVzdBovLmdvb2dsZS5haS5nZW5l
cmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlR1bmVkTW9kZWwiV4LT5JMCNzIoL3YxYmV0YS97dHVu
ZWRfbW9kZWwubmFtZT10dW5lZE1vZGVscy8qfToLdHVuZWRfbW9kZWzaQRd0dW5lZF9tb2Rl
bCx1cGRhdGVfbWFzaxKVAQoQRGVsZXRlVHVuZWRNb2RlbBI8Lmdvb2dsZS5haS5nZW5lcmF0
aXZlbGFuZ3VhZ2UudjFiZXRhLkRlbGV0ZVR1bmVkTW9kZWxSZXF1ZXN0GhYuZ29vZ2xlLnBy
b3RvYnVmLkVtcHR5IiuC0+STAh4qHC92MWJldGEve25hbWU9dHVuZWRNb2RlbHMvKn3aQQRu
YW1lGiTKQSFnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb21CnQEKJ2NvbS5nb29n
bGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YUIRTW9kZWxTZXJ2aWNlUHJvdG9QAVpd
Y2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvYXBpdjFiZXRhL2dl
bmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSqw+CgcSBQ4AkgIBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSADkK
CQoCAwESAxMAPwoJCgIDAhIDFAAmCgkKAgMDEgMVACEKCQoCAwQSAxYAKQoJCgIDBRIDFwAj
CgkKAgMGEgMYAC0KCQoCAwcSAxkAJQoJCgIDCBIDGgAqCggKAQgSAxwAdAoJCgIICxIDHAB0
CggKAQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4AMgoJCgIICBIDHgAyCggKAQgSAx8AQAoJ
CgIIARIDHwBAClgKAgYAEgQiAHIBGkwgUHJvdmlkZXMgbWV0aG9kcyBmb3IgZ2V0dGluZyBt
ZXRhZGF0YSBpbmZvcm1hdGlvbiBhYm91dCBHZW5lcmF0aXZlIE1vZGVscy4KCgoKAwYAARID
IggUCgoKAwYAAxIDIwJJCgwKBQYAA5kIEgMjAkkK0wIKBAYAAgASBCsCMAMaxAIgR2V0cyBp
bmZvcm1hdGlvbiBhYm91dCBhIHNwZWNpZmljIGBNb2RlbGAgc3VjaCBhcyBpdHMgdmVyc2lv
biBudW1iZXIsIHRva2VuCiBsaW1pdHMsCiBbcGFyYW1ldGVyc10oaHR0cHM6Ly9haS5nb29n
bGUuZGV2L2dlbWluaS1hcGkvZG9jcy9tb2RlbHMvZ2VuZXJhdGl2ZS1tb2RlbHMjbW9kZWwt
cGFyYW1ldGVycykKIGFuZCBvdGhlciBtZXRhZGF0YS4gUmVmZXIgdG8gdGhlIFtHZW1pbmkg
bW9kZWxzCiBndWlkZV0oaHR0cHM6Ly9haS5nb29nbGUuZGV2L2dlbWluaS1hcGkvZG9jcy9t
b2RlbHMvZ2VtaW5pKSBmb3IgZGV0YWlsZWQKIG1vZGVsIGluZm9ybWF0aW9uLgoKDAoFBgAC
AAESAysGDgoMCgUGAAIAAhIDKw8eCgwKBQYAAgADEgMrKS4KDQoFBgACAAQSBCwELgYKEQoJ
BgACAASwyrwiEgQsBC4GCgwKBQYAAgAEEgMvBDIKDwoIBgACAASbCAASAy8EMgp8CgQGAAIB
EgQ0AjkDGm4gTGlzdHMgdGhlIFtgTW9kZWxgc10oaHR0cHM6Ly9haS5nb29nbGUuZGV2L2dl
bWluaS1hcGkvZG9jcy9tb2RlbHMvZ2VtaW5pKQogYXZhaWxhYmxlIHRocm91Z2ggdGhlIEdl
bWluaSBBUEkuCgoMCgUGAAIBARIDNAYQCgwKBQYAAgECEgM0ESIKDAoFBgACAQMSAzQtPwoN
CgUGAAIBBBIENQQ3BgoRCgkGAAIBBLDKvCISBDUENwYKDAoFBgACAQQSAzgEQgoPCggGAAIB
BJsIABIDOARCCj0KBAYAAgISBDwCQQMaLyBHZXRzIGluZm9ybWF0aW9uIGFib3V0IGEgc3Bl
Y2lmaWMgVHVuZWRNb2RlbC4KCgwKBQYAAgIBEgM8BhMKDAoFBgACAgISAzwUKAoMCgUGAAIC
AxIDPDM9Cg0KBQYAAgIEEgQ9BD8GChEKCQYAAgIEsMq8IhIEPQQ/BgoMCgUGAAICBBIDQAQy
Cg8KCAYAAgIEmwgAEgNABDIKKwoEBgACAxIERAJKAxodIExpc3RzIGNyZWF0ZWQgdHVuZWQg
bW9kZWxzLgoKDAoFBgACAwESA0QGFQoMCgUGAAIDAhIDRBYsCgwKBQYAAgMDEgNFDyYKDQoF
BgACAwQSBEYESAYKEQoJBgACAwSwyrwiEgRGBEgGCgwKBQYAAgMEEgNJBEIKDwoIBgACAwSb
CAASA0kEQgqKAgoEBgACBBIEUwJfAxr7ASBDcmVhdGVzIGEgdHVuZWQgbW9kZWwuCiBDaGVj
ayBpbnRlcm1lZGlhdGUgdHVuaW5nIHByb2dyZXNzIChpZiBhbnkpIHRocm91Z2ggdGhlCiBb
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnNdIHNlcnZpY2UuCgogQWNjZXNzIHN0YXR1
cyBhbmQgcmVzdWx0cyB0aHJvdWdoIHRoZSBPcGVyYXRpb25zIHNlcnZpY2UuCiBFeGFtcGxl
OgogICBHRVQgL3YxL3R1bmVkTW9kZWxzL2F6Mm1iMGJwdzZpL29wZXJhdGlvbnMvMDAwLTEx
MS0yMjIKCgwKBQYAAgQBEgNTBhYKDAoFBgACBAISA1MXLgoMCgUGAAIEAxIDVA8rCg0KBQYA
AgQEEgRVBFgGChEKCQYAAgQEsMq8IhIEVQRYBgoMCgUGAAIEBBIDWQQ5Cg8KCAYAAgQEmwgA
EgNZBDkKDAoFBgACBAQSA1oESAoPCggGAAIEBJsIARIDWgRICg0KBQYAAgQEEgRbBF4GCg8K
BwYAAgQEmQgSBFsEXgYKJgoEBgACBRIEYgJoAxoYIFVwZGF0ZXMgYSB0dW5lZCBtb2RlbC4K
CgwKBQYAAgUBEgNiBhYKDAoFBgACBQISA2IXLgoMCgUGAAIFAxIDYjlDCg0KBQYAAgUEEgRj
BGYGChEKCQYAAgUEsMq8IhIEYwRmBgoMCgUGAAIFBBIDZwRFCg8KCAYAAgUEmwgAEgNnBEUK
JgoEBgACBhIEawJxAxoYIERlbGV0ZXMgYSB0dW5lZCBtb2RlbC4KCgwKBQYAAgYBEgNrBhYK
DAoFBgACBgISA2sXLgoMCgUGAAIGAxIDbA8kCg0KBQYAAgYEEgRtBG8GChEKCQYAAgYEsMq8
IhIEbQRvBgoMCgUGAAIGBBIDcAQyCg8KCAYAAgYEmwgAEgNwBDIKRgoCBAASBXUAgQEBGjkg
UmVxdWVzdCBmb3IgZ2V0dGluZyBpbmZvcm1hdGlvbiBhYm91dCBhIHNwZWNpZmljIE1vZGVs
LgoKCgoDBAABEgN1CBcKoQEKBAQAAgASBXsCgAEEGpEBIFJlcXVpcmVkLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgbW9kZWwuCgogVGhpcyBuYW1lIHNob3VsZCBtYXRjaCBhIG1vZGVs
IG5hbWUgcmV0dXJuZWQgYnkgdGhlIGBMaXN0TW9kZWxzYCBtZXRob2QuCgogRm9ybWF0OiBg
bW9kZWxzL3ttb2RlbH1gCgoMCgUEAAIABRIDewIICgwKBQQAAgABEgN7CQ0KDAoFBAACAAMS
A3sQEQoOCgUEAAIACBIFexKAAQMKDwoIBAACAAicCAASA3wEKgoPCgcEAAIACJ8IEgR9BH8F
Ci8KAgQBEgaEAQCUAQEaISBSZXF1ZXN0IGZvciBsaXN0aW5nIGFsbCBNb2RlbHMuCgoLCgME
AQESBIQBCBkK1QEKBAQBAgASBIoBAhYaxgEgVGhlIG1heGltdW0gbnVtYmVyIG9mIGBNb2Rl
bHNgIHRvIHJldHVybiAocGVyIHBhZ2UpLgoKIElmIHVuc3BlY2lmaWVkLCA1MCBtb2RlbHMg
d2lsbCBiZSByZXR1cm5lZCBwZXIgcGFnZS4KIFRoaXMgbWV0aG9kIHJldHVybnMgYXQgbW9z
dCAxMDAwIG1vZGVscyBwZXIgcGFnZSwgZXZlbiBpZiB5b3UgcGFzcyBhIGxhcmdlcgogcGFn
ZV9zaXplLgoKDQoFBAECAAUSBIoBAgcKDQoFBAECAAESBIoBCBEKDQoFBAECAAMSBIoBFBUK
sAIKBAQBAgESBJMBAhgaoQIgQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlv
dXMgYExpc3RNb2RlbHNgIGNhbGwuCgogUHJvdmlkZSB0aGUgYHBhZ2VfdG9rZW5gIHJldHVy
bmVkIGJ5IG9uZSByZXF1ZXN0IGFzIGFuIGFyZ3VtZW50IHRvIHRoZSBuZXh0CiByZXF1ZXN0
IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3Ro
ZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0byBgTGlzdE1vZGVsc2AgbXVzdCBtYXRjaAogdGhl
IGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQBAgEFEgSTAQIICg0K
BQQBAgEBEgSTAQkTCg0KBQQBAgEDEgSTARYXClAKAgQCEgaXAQCfAQEaQiBSZXNwb25zZSBm
cm9tIGBMaXN0TW9kZWxgIGNvbnRhaW5pbmcgYSBwYWdpbmF0ZWQgbGlzdCBvZiBNb2RlbHMu
CgoLCgMEAgESBJcBCBoKJAoEBAICABIEmQECHBoWIFRoZSByZXR1cm5lZCBNb2RlbHMuCgoN
CgUEAgIABBIEmQECCgoNCgUEAgIABhIEmQELEAoNCgUEAgIAARIEmQERFwoNCgUEAgIAAxIE
mQEaGwqKAQoEBAICARIEngECHRp8IEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBw
YWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgoKIElmIHRoaXMgZmllbGQg
aXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIG1vcmUgcGFnZXMuCgoNCgUEAgIBBRIEngECCAoN
CgUEAgIBARIEngEJGAoNCgUEAgIBAxIEngEbHApHCgIEAxIGogEArAEBGjkgUmVxdWVzdCBm
b3IgZ2V0dGluZyBpbmZvcm1hdGlvbiBhYm91dCBhIHNwZWNpZmljIE1vZGVsLgoKCwoDBAMB
EgSiAQgcCl8KBAQDAgASBqYBAqsBBBpPIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgbW9kZWwuCgogRm9ybWF0OiBgdHVuZWRNb2RlbHMvbXktbW9kZWwtaWRgCgoNCgUE
AwIABRIEpgECCAoNCgUEAwIAARIEpgEJDQoNCgUEAwIAAxIEpgEQEQoPCgUEAwIACBIGpgES
qwEDChAKCAQDAgAInAgAEgSnAQQqChEKBwQDAgAInwgSBqgBBKoBBQowCgIEBBIGrwEA0AEB
GiIgUmVxdWVzdCBmb3IgbGlzdGluZyBUdW5lZE1vZGVscy4KCgsKAwQEARIErwEIHgqVAgoE
BAQCABIEtgECPxqGAiBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGBUdW5lZE1v
ZGVsc2AgdG8gcmV0dXJuIChwZXIgcGFnZSkuCiBUaGUgc2VydmljZSBtYXkgcmV0dXJuIGZl
d2VyIHR1bmVkIG1vZGVscy4KCiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCAxMCB0dW5lZCBt
b2RlbHMgd2lsbCBiZSByZXR1cm5lZC4KIFRoaXMgbWV0aG9kIHJldHVybnMgYXQgbW9zdCAx
MDAwIG1vZGVscyBwZXIgcGFnZSwgZXZlbiBpZiB5b3UgcGFzcyBhIGxhcmdlcgogcGFnZV9z
aXplLgoKDQoFBAQCAAUSBLYBAgcKDQoFBAQCAAESBLYBCBEKDQoFBAQCAAMSBLYBFBUKDQoF
BAQCAAgSBLYBFj4KEAoIBAQCAAicCAASBLYBFz0KxAIKBAQEAgESBL8BAkEatQIgT3B0aW9u
YWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0VHVuZWRN
b2RlbHNgIGNhbGwuCgogUHJvdmlkZSB0aGUgYHBhZ2VfdG9rZW5gIHJldHVybmVkIGJ5IG9u
ZSByZXF1ZXN0IGFzIGFuIGFyZ3VtZW50IHRvIHRoZSBuZXh0CiByZXF1ZXN0IHRvIHJldHJp
ZXZlIHRoZSBuZXh0IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1l
dGVycyBwcm92aWRlZCB0byBgTGlzdFR1bmVkTW9kZWxzYAogbXVzdCBtYXRjaCB0aGUgY2Fs
bCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAQCAQUSBL8BAggKDQoFBAQC
AQESBL8BCRMKDQoFBAQCAQMSBL8BFhcKDQoFBAQCAQgSBL8BGEAKEAoIBAQCAQicCAASBL8B
GT8K/AMKBAQEAgISBM8BAj0a7QMgT3B0aW9uYWwuIEEgZmlsdGVyIGlzIGEgZnVsbCB0ZXh0
IHNlYXJjaCBvdmVyIHRoZSB0dW5lZCBtb2RlbCdzIGRlc2NyaXB0aW9uCiBhbmQgZGlzcGxh
eSBuYW1lLiBCeSBkZWZhdWx0LCByZXN1bHRzIHdpbGwgbm90IGluY2x1ZGUgdHVuZWQgbW9k
ZWxzIHNoYXJlZAogd2l0aCBldmVyeW9uZS4KCiBBZGRpdGlvbmFsIG9wZXJhdG9yczoKICAg
LSBvd25lcjptZQogICAtIHdyaXRlcnM6bWUKICAgLSByZWFkZXJzOm1lCiAgIC0gcmVhZGVy
czpldmVyeW9uZQoKIEV4YW1wbGVzOgogICAib3duZXI6bWUiIHJldHVybnMgYWxsIHR1bmVk
IG1vZGVscyB0byB3aGljaCBjYWxsZXIgaGFzIG93bmVyIHJvbGUKICAgInJlYWRlcnM6bWUi
IHJldHVybnMgYWxsIHR1bmVkIG1vZGVscyB0byB3aGljaCBjYWxsZXIgaGFzIHJlYWRlciBy
b2xlCiAgICJyZWFkZXJzOmV2ZXJ5b25lIiByZXR1cm5zIGFsbCB0dW5lZCBtb2RlbHMgdGhh
dCBhcmUgc2hhcmVkIHdpdGggZXZlcnlvbmUKCg0KBQQEAgIFEgTPAQIICg0KBQQEAgIBEgTP
AQkPCg0KBQQEAgIDEgTPARITCg0KBQQEAgIIEgTPARQ8ChAKCAQEAgIInAgAEgTPARU7ClYK
AgQFEgbTAQDbAQEaSCBSZXNwb25zZSBmcm9tIGBMaXN0VHVuZWRNb2RlbHNgIGNvbnRhaW5p
bmcgYSBwYWdpbmF0ZWQgbGlzdCBvZiBNb2RlbHMuCgoLCgMEBQESBNMBCB8KJAoEBAUCABIE
1QECJxoWIFRoZSByZXR1cm5lZCBNb2RlbHMuCgoNCgUEBQIABBIE1QECCgoNCgUEBQIABhIE
1QELFQoNCgUEBQIAARIE1QEWIgoNCgUEBQIAAxIE1QElJgqKAQoEBAUCARIE2gECHRp8IEEg
dG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0
aGUgbmV4dCBwYWdlLgoKIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5v
IG1vcmUgcGFnZXMuCgoNCgUEBQIBBRIE2gECCAoNCgUEBQIBARIE2gEJGAoNCgUEBQIBAxIE
2gEbHAovCgIEBhIG3gEA5wEBGiEgUmVxdWVzdCB0byBjcmVhdGUgYSBUdW5lZE1vZGVsLgoK
CwoDBAYBEgTeAQgfCpICCgQEBgIAEgTjAQJOGoMCIE9wdGlvbmFsLiBUaGUgdW5pcXVlIGlk
IGZvciB0aGUgdHVuZWQgbW9kZWwgaWYgc3BlY2lmaWVkLgogVGhpcyB2YWx1ZSBzaG91bGQg
YmUgdXAgdG8gNDAgY2hhcmFjdGVycywgdGhlIGZpcnN0IGNoYXJhY3RlciBtdXN0IGJlIGEK
IGxldHRlciwgdGhlIGxhc3QgY291bGQgYmUgYSBsZXR0ZXIgb3IgYSBudW1iZXIuIFRoZSBp
ZCBtdXN0IG1hdGNoIHRoZQogcmVndWxhciBleHByZXNzaW9uOiBgW2Etel0oW2EtejAtOS1d
ezAsMzh9W2EtejAtOV0pP2AuCgoNCgUEBgIABBIE4wECCgoNCgUEBgIABRIE4wELEQoNCgUE
BgIAARIE4wESIAoNCgUEBgIAAxIE4wEjJAoNCgUEBgIACBIE4wElTQoQCggEBgIACJwIABIE
4wEmTAo0CgQEBgIBEgTmAQJGGiYgUmVxdWlyZWQuIFRoZSB0dW5lZCBtb2RlbCB0byBjcmVh
dGUuCgoNCgUEBgIBBhIE5gECDAoNCgUEBgIBARIE5gENGAoNCgUEBgIBAxIE5gEbHAoNCgUE
BgIBCBIE5gEdRQoQCggEBgIBCJwIABIE5gEeRAp5CgIEBxIG6wEA/AEBGmsgTWV0YWRhdGEg
YWJvdXQgdGhlIHN0YXRlIGFuZCBwcm9ncmVzcyBvZiBjcmVhdGluZyBhIHR1bmVkIG1vZGVs
IHJldHVybmVkIGZyb20KIHRoZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uCgoLCgMEBwESBOsB
CCAKTwoEBAcCABIG7QEC7wEFGj8gTmFtZSBvZiB0aGUgdHVuZWQgbW9kZWwgYXNzb2NpYXRl
ZCB3aXRoIHRoZSB0dW5pbmcgb3BlcmF0aW9uLgoKDQoFBAcCAAUSBO0BAggKDQoFBAcCAAES
BO0BCRQKDQoFBAcCAAMSBO0BFxgKDwoFBAcCAAgSBu0BGe8BBAoRCgcEBwIACJ8IEgbtARrv
AQMKMQoEBAcCARIE8gECGBojIFRoZSB0b3RhbCBudW1iZXIgb2YgdHVuaW5nIHN0ZXBzLgoK
DQoFBAcCAQUSBPIBAgcKDQoFBAcCAQESBPIBCBMKDQoFBAcCAQMSBPIBFhcKLgoEBAcCAhIE
9QECHBogIFRoZSBudW1iZXIgb2Ygc3RlcHMgY29tcGxldGVkLgoKDQoFBAcCAgUSBPUBAgcK
DQoFBAcCAgESBPUBCBcKDQoFBAcCAgMSBPUBGhsKQgoEBAcCAxIE+AECHho0IFRoZSBjb21w
bGV0ZWQgcGVyY2VudGFnZSBmb3IgdGhlIHR1bmluZyBvcGVyYXRpb24uCgoNCgUEBwIDBRIE
+AECBwoNCgUEBwIDARIE+AEIGQoNCgUEBwIDAxIE+AEcHQowCgQEBwIEEgT7AQIoGiIgTWV0
cmljcyBjb2xsZWN0ZWQgZHVyaW5nIHR1bmluZy4KCg0KBQQHAgQEEgT7AQIKCg0KBQQHAgQG
EgT7AQsZCg0KBQQHAgQBEgT7ARojCg0KBQQHAgQDEgT7ASYnCi8KAgQIEgb/AQCGAgEaISBS
ZXF1ZXN0IHRvIHVwZGF0ZSBhIFR1bmVkTW9kZWwuCgoLCgMECAESBP8BCB8KNAoEBAgCABIE
gQICRhomIFJlcXVpcmVkLiBUaGUgdHVuZWQgbW9kZWwgdG8gdXBkYXRlLgoKDQoFBAgCAAYS
BIECAgwKDQoFBAgCAAESBIECDRgKDQoFBAgCAAMSBIECGxwKDQoFBAgCAAgSBIECHUUKEAoI
BAgCAAicCAASBIECHkQKOQoEBAgCARIGhAIChQIvGikgT3B0aW9uYWwuIFRoZSBsaXN0IG9m
IGZpZWxkcyB0byB1cGRhdGUuCgoNCgUECAIBBhIEhAICGwoNCgUECAIBARIEhAIcJwoNCgUE
CAIBAxIEhAIqKwoNCgUECAIBCBIEhQIGLgoQCggECAIBCJwIABIEhQIHLQovCgIECRIGiQIA
kgIBGiEgUmVxdWVzdCB0byBkZWxldGUgYSBUdW5lZE1vZGVsLgoKCwoDBAkBEgSJAggfCl4K
BAQJAgASBowCApECBBpOIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbW9k
ZWwuCiBGb3JtYXQ6IGB0dW5lZE1vZGVscy9teS1tb2RlbC1pZGAKCg0KBQQJAgAFEgSMAgII
Cg0KBQQJAgABEgSMAgkNCg0KBQQJAgADEgSMAhARCg8KBQQJAgAIEgaMAhKRAgMKEAoIBAkC
AAicCAASBI0CBCoKEQoHBAkCAAifCBIGjgIEkAIFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest ===
    # Fields for GetModelRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest->new(
        page_size => $value,
    );

=head1 FIELDS

=over 4

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.ai.generativelanguage.v1beta.Model)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse->new(
        models => $value,
    );

=head1 FIELDS

=over 4

=item * B<models>

Type: Message (.google.ai.generativelanguage.v1beta.Model)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest ===
    # Fields for GetTunedModelRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest ===
    # Fields for ListTunedModelsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest->new(
        page_size => $value,
    );

=head1 FIELDS

=over 4

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=item * B<filter>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse ===
    # Fields for ListTunedModelsResponse
    # Field: tuned_models Type: 11 (.google.ai.generativelanguage.v1beta.TunedModel)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse->new(
        tuned_models => $value,
    );

=head1 FIELDS

=over 4

=item * B<tuned_models>

Type: Message (.google.ai.generativelanguage.v1beta.TunedModel)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest ===
    # Fields for CreateTunedModelRequest
    # Field: tuned_model_id Type: 9 ()
    # Field: tuned_model Type: 11 (.google.ai.generativelanguage.v1beta.TunedModel)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest->new(
        tuned_model_id => $value,
    );

=head1 FIELDS

=over 4

=item * B<tuned_model_id>

Type: String

=item * B<tuned_model>

Type: Message (.google.ai.generativelanguage.v1beta.TunedModel)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelMetadata ===
    # Fields for CreateTunedModelMetadata
    # Field: tuned_model Type: 9 ()
    # Field: total_steps Type: 5 ()
    # Field: completed_steps Type: 5 ()
    # Field: completed_percent Type: 2 ()
    # Field: snapshots Type: 11 (.google.ai.generativelanguage.v1beta.TuningSnapshot)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelMetadata - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelMetadata->new(
        tuned_model => $value,
    );

=head1 FIELDS

=over 4

=item * B<tuned_model>

Type: String

=item * B<total_steps>

Type: Int32

=item * B<completed_steps>

Type: Int32

=item * B<completed_percent>

Type: Float

=item * B<snapshots>

Type: Message (.google.ai.generativelanguage.v1beta.TuningSnapshot)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest ===
    # Fields for UpdateTunedModelRequest
    # Field: tuned_model Type: 11 (.google.ai.generativelanguage.v1beta.TunedModel)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest->new(
        tuned_model => $value,
    );

=head1 FIELDS

=over 4

=item * B<tuned_model>

Type: Message (.google.ai.generativelanguage.v1beta.TunedModel)

=item * B<update_mask>

Type: Message (.google.protobuf.FieldMask)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest ===
    # Fields for DeleteTunedModelRequest
    # Field: name Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest->new(
        name => $value,
    );

=head1 FIELDS

=over 4

=item * B<name>

Type: String

=back

=cut

# === Service Client: Google::Ai::Generativelanguage::V1beta::ModelService::ModelServiceClient ===
package Google::Ai::Generativelanguage::V1beta::ModelService::ModelServiceClient;

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::ModelServiceClient - Client stub representing the remote ModelService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head2 credentials

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
        ? Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'GetModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::Model::Model',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse',
    });
}

sub get_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'GetTunedModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel',
    });
}

sub list_tuned_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'ListTunedModels',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse',
    });
}

sub create_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'CreateTunedModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'UpdateTunedModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel',
    });
}

sub delete_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'DeleteTunedModel',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
