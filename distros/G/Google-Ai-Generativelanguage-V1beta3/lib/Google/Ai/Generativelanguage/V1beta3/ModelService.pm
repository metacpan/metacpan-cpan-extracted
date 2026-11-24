package Google::Ai::Generativelanguage::V1beta3::ModelService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta3::Model };
    eval { require Google::Ai::Generativelanguage::V1beta3::TunedModel };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YTMvbW9kZWxfc2VydmljZS5w
cm90bxIkZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzGjBnb29nbGUvYWkv
Z2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YTMvbW9kZWwucHJvdG8aNmdvb2dsZS9haS9nZW5l
cmF0aXZlbGFuZ3VhZ2UvdjFiZXRhMy90dW5lZF9tb2RlbC5wcm90bxocZ29vZ2xlL2FwaS9h
bm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2ds
ZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHku
cHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIlYKD0dldE1vZGVsUmVx
dWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ2dlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVh
cGlzLmNvbS9Nb2RlbFIEbmFtZSJPChFMaXN0TW9kZWxzUmVxdWVzdBIbCglwYWdlX3NpemUY
AiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKBAQoSTGlz
dE1vZGVsc1Jlc3BvbnNlEkMKBm1vZGVscxgBIAMoCzIrLmdvb2dsZS5haS5nZW5lcmF0aXZl
bGFuZ3VhZ2UudjFiZXRhMy5Nb2RlbFIGbW9kZWxzEiYKD25leHRfcGFnZV90b2tlbhgCIAEo
CVINbmV4dFBhZ2VUb2tlbiJgChRHZXRUdW5lZE1vZGVsUmVxdWVzdBJICgRuYW1lGAEgASgJ
QjTgQQL6QS4KLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9UdW5lZE1vZGVs
UgRuYW1lIl4KFkxpc3RUdW5lZE1vZGVsc1JlcXVlc3QSIAoJcGFnZV9zaXplGAEgASgFQgPg
QQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAiABKAlCA+BBAVIJcGFnZVRva2VuIpYBChdM
aXN0VHVuZWRNb2RlbHNSZXNwb25zZRJTCgx0dW5lZF9tb2RlbHMYASADKAsyMC5nb29nbGUu
YWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuVHVuZWRNb2RlbFILdHVuZWRNb2RlbHMS
JgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIrQBChdDcmVhdGVUdW5l
ZE1vZGVsUmVxdWVzdBIuCg50dW5lZF9tb2RlbF9pZBgBIAEoCUID4EEBSABSDHR1bmVkTW9k
ZWxJZIgBARJWCgt0dW5lZF9tb2RlbBgCIAEoCzIwLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFu
Z3VhZ2UudjFiZXRhMy5UdW5lZE1vZGVsQgPgQQJSCnR1bmVkTW9kZWxCEQoPX3R1bmVkX21v
ZGVsX2lkIrkCChhDcmVhdGVUdW5lZE1vZGVsTWV0YWRhdGESUgoLdHVuZWRfbW9kZWwYBSAB
KAlCMfpBLgosZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL1R1bmVkTW9kZWxS
CnR1bmVkTW9kZWwSHwoLdG90YWxfc3RlcHMYASABKAVSCnRvdGFsU3RlcHMSJwoPY29tcGxl
dGVkX3N0ZXBzGAIgASgFUg5jb21wbGV0ZWRTdGVwcxIrChFjb21wbGV0ZWRfcGVyY2VudBgD
IAEoAlIQY29tcGxldGVkUGVyY2VudBJSCglzbmFwc2hvdHMYBCADKAsyNC5nb29nbGUuYWku
Z2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuVHVuaW5nU25hcHNob3RSCXNuYXBzaG90cyKz
AQoXVXBkYXRlVHVuZWRNb2RlbFJlcXVlc3QSVgoLdHVuZWRfbW9kZWwYASABKAsyMC5nb29n
bGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuVHVuZWRNb2RlbEID4EECUgp0dW5l
ZE1vZGVsEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFz
a0ID4EECUgp1cGRhdGVNYXNrImMKF0RlbGV0ZVR1bmVkTW9kZWxSZXF1ZXN0EkgKBG5hbWUY
ASABKAlCNOBBAvpBLgosZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL1R1bmVk
TW9kZWxSBG5hbWUy4AoKDE1vZGVsU2VydmljZRKXAQoIR2V0TW9kZWwSNS5nb29nbGUuYWku
Z2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuR2V0TW9kZWxSZXF1ZXN0GisuZ29vZ2xlLmFp
LmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLk1vZGVsIieC0+STAhoSGC92MWJldGEzL3tu
YW1lPW1vZGVscy8qfdpBBG5hbWUSrwEKCkxpc3RNb2RlbHMSNy5nb29nbGUuYWkuZ2VuZXJh
dGl2ZWxhbmd1YWdlLnYxYmV0YTMuTGlzdE1vZGVsc1JlcXVlc3QaOC5nb29nbGUuYWkuZ2Vu
ZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuTGlzdE1vZGVsc1Jlc3BvbnNlIi6C0+STAhESDy92
MWJldGEzL21vZGVsc9pBFHBhZ2Vfc2l6ZSxwYWdlX3Rva2VuEqsBCg1HZXRUdW5lZE1vZGVs
EjouZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLkdldFR1bmVkTW9kZWxS
ZXF1ZXN0GjAuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLlR1bmVkTW9k
ZWwiLILT5JMCHxIdL3YxYmV0YTMve25hbWU9dHVuZWRNb2RlbHMvKn3aQQRuYW1lEsMBCg9M
aXN0VHVuZWRNb2RlbHMSPC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMu
TGlzdFR1bmVkTW9kZWxzUmVxdWVzdBo9Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2Uu
djFiZXRhMy5MaXN0VHVuZWRNb2RlbHNSZXNwb25zZSIzgtPkkwIWEhQvdjFiZXRhMy90dW5l
ZE1vZGVsc9pBFHBhZ2Vfc2l6ZSxwYWdlX3Rva2VuEu8BChBDcmVhdGVUdW5lZE1vZGVsEj0u
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLkNyZWF0ZVR1bmVkTW9kZWxS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ9gtPkkwIjIhQvdjFiZXRh
My90dW5lZE1vZGVsczoLdHVuZWRfbW9kZWzaQQt0dW5lZF9tb2RlbNpBGnR1bmVkX21vZGVs
X2lkLHR1bmVkX21vZGVsykEmCgpUdW5lZE1vZGVsEhhDcmVhdGVUdW5lZE1vZGVsTWV0YWRh
dGES3QEKEFVwZGF0ZVR1bmVkTW9kZWwSPS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdl
LnYxYmV0YTMuVXBkYXRlVHVuZWRNb2RlbFJlcXVlc3QaMC5nb29nbGUuYWkuZ2VuZXJhdGl2
ZWxhbmd1YWdlLnYxYmV0YTMuVHVuZWRNb2RlbCJYgtPkkwI4MikvdjFiZXRhMy97dHVuZWRf
bW9kZWwubmFtZT10dW5lZE1vZGVscy8qfToLdHVuZWRfbW9kZWzaQRd0dW5lZF9tb2RlbCx1
cGRhdGVfbWFzaxKXAQoQRGVsZXRlVHVuZWRNb2RlbBI9Lmdvb2dsZS5haS5nZW5lcmF0aXZl
bGFuZ3VhZ2UudjFiZXRhMy5EZWxldGVUdW5lZE1vZGVsUmVxdWVzdBoWLmdvb2dsZS5wcm90
b2J1Zi5FbXB0eSIsgtPkkwIfKh0vdjFiZXRhMy97bmFtZT10dW5lZE1vZGVscy8qfdpBBG5h
bWUaJMpBIWdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbUKfAQooY29tLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhM0IRTW9kZWxTZXJ2aWNlUHJvdG9QAVpe
Y2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvYXBpdjFiZXRhMy9n
ZW5lcmF0aXZlbGFuZ3VhZ2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkq+NwoHEgUOAP0BAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgA6
CgkKAgMBEgMTAEAKCQoCAwISAxQAJgoJCgIDAxIDFQAhCgkKAgMEEgMWACkKCQoCAwUSAxcA
IwoJCgIDBhIDGAAtCgkKAgMHEgMZACUKCQoCAwgSAxoAKgoICgEIEgMcAHUKCQoCCAsSAxwA
dQoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeADIKCQoCCAgSAx4AMgoICgEIEgMfAEEK
CQoCCAESAx8AQQpYCgIGABIEIgBsARpMIFByb3ZpZGVzIG1ldGhvZHMgZm9yIGdldHRpbmcg
bWV0YWRhdGEgaW5mb3JtYXRpb24gYWJvdXQgR2VuZXJhdGl2ZSBNb2RlbHMuCgoKCgMGAAES
AyIIFAoKCgMGAAMSAyMCSQoMCgUGAAOZCBIDIwJJCjgKBAYAAgASBCYCKwMaKiBHZXRzIGlu
Zm9ybWF0aW9uIGFib3V0IGEgc3BlY2lmaWMgTW9kZWwuCgoMCgUGAAIAARIDJgYOCgwKBQYA
AgACEgMmDx4KDAoFBgACAAMSAyYpLgoNCgUGAAIABBIEJwQpBgoRCgkGAAIABLDKvCISBCcE
KQYKDAoFBgACAAQSAyoEMgoPCggGAAIABJsIABIDKgQyCjcKBAYAAgESBC4CMwMaKSBMaXN0
cyBtb2RlbHMgYXZhaWxhYmxlIHRocm91Z2ggdGhlIEFQSS4KCgwKBQYAAgEBEgMuBhAKDAoF
BgACAQISAy4RIgoMCgUGAAIBAxIDLi0/Cg0KBQYAAgEEEgQvBDEGChEKCQYAAgEEsMq8IhIE
LwQxBgoMCgUGAAIBBBIDMgRCCg8KCAYAAgEEmwgAEgMyBEIKPQoEBgACAhIENgI7AxovIEdl
dHMgaW5mb3JtYXRpb24gYWJvdXQgYSBzcGVjaWZpYyBUdW5lZE1vZGVsLgoKDAoFBgACAgES
AzYGEwoMCgUGAAICAhIDNhQoCgwKBQYAAgIDEgM2Mz0KDQoFBgACAgQSBDcEOQYKEQoJBgAC
AgSwyrwiEgQ3BDkGCgwKBQYAAgIEEgM6BDIKDwoIBgACAgSbCAASAzoEMgo1CgQGAAIDEgQ+
AkQDGicgTGlzdHMgdHVuZWQgbW9kZWxzIG93bmVkIGJ5IHRoZSB1c2VyLgoKDAoFBgACAwES
Az4GFQoMCgUGAAIDAhIDPhYsCgwKBQYAAgMDEgM/DyYKDQoFBgACAwQSBEAEQgYKEQoJBgAC
AwSwyrwiEgRABEIGCgwKBQYAAgMEEgNDBEIKDwoIBgACAwSbCAASA0MEQgqZAgoEBgACBBIE
TQJZAxqKAiBDcmVhdGVzIGEgdHVuZWQgbW9kZWwuCiBJbnRlcm1lZGlhdGUgdHVuaW5nIHBy
b2dyZXNzIChpZiBhbnkpIGlzIGFjY2Vzc2VkIHRocm91Z2ggdGhlCiBbZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbnNdIHNlcnZpY2UuCgogU3RhdHVzIGFuZCByZXN1bHRzIGNhbiBi
ZSBhY2Nlc3NlZCB0aHJvdWdoIHRoZSBPcGVyYXRpb25zIHNlcnZpY2UuCiBFeGFtcGxlOgog
ICBHRVQgL3YxL3R1bmVkTW9kZWxzL2F6Mm1iMGJwdzZpL29wZXJhdGlvbnMvMDAwLTExMS0y
MjIKCgwKBQYAAgQBEgNNBhYKDAoFBgACBAISA00XLgoMCgUGAAIEAxIDTg8rCg0KBQYAAgQE
EgRPBFIGChEKCQYAAgQEsMq8IhIETwRSBgoMCgUGAAIEBBIDUwQ5Cg8KCAYAAgQEmwgAEgNT
BDkKDAoFBgACBAQSA1QESAoPCggGAAIEBJsIARIDVARICg0KBQYAAgQEEgRVBFgGCg8KBwYA
AgQEmQgSBFUEWAYKJgoEBgACBRIEXAJiAxoYIFVwZGF0ZXMgYSB0dW5lZCBtb2RlbC4KCgwK
BQYAAgUBEgNcBhYKDAoFBgACBQISA1wXLgoMCgUGAAIFAxIDXDlDCg0KBQYAAgUEEgRdBGAG
ChEKCQYAAgUEsMq8IhIEXQRgBgoMCgUGAAIFBBIDYQRFCg8KCAYAAgUEmwgAEgNhBEUKJgoE
BgACBhIEZQJrAxoYIERlbGV0ZXMgYSB0dW5lZCBtb2RlbC4KCgwKBQYAAgYBEgNlBhYKDAoF
BgACBgISA2UXLgoMCgUGAAIGAxIDZg8kCg0KBQYAAgYEEgRnBGkGChEKCQYAAgYEsMq8IhIE
ZwRpBgoMCgUGAAIGBBIDagQyCg8KCAYAAgYEmwgAEgNqBDIKRQoCBAASBG8AewEaOSBSZXF1
ZXN0IGZvciBnZXR0aW5nIGluZm9ybWF0aW9uIGFib3V0IGEgc3BlY2lmaWMgTW9kZWwuCgoK
CgMEAAESA28IFwqgAQoEBAACABIEdQJ6BBqRASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIG1vZGVsLgoKIFRoaXMgbmFtZSBzaG91bGQgbWF0Y2ggYSBtb2RlbCBuYW1l
IHJldHVybmVkIGJ5IHRoZSBgTGlzdE1vZGVsc2AgbWV0aG9kLgoKIEZvcm1hdDogYG1vZGVs
cy97bW9kZWx9YAoKDAoFBAACAAUSA3UCCAoMCgUEAAIAARIDdQkNCgwKBQQAAgADEgN1EBEK
DQoFBAACAAgSBHUSegMKDwoIBAACAAicCAASA3YEKgoPCgcEAAIACJ8IEgR3BHkFCi4KAgQB
EgV+AI8BARohIFJlcXVlc3QgZm9yIGxpc3RpbmcgYWxsIE1vZGVscy4KCgoKAwQBARIDfggZ
CoMCCgQEAQIAEgSFAQIWGvQBIFRoZSBtYXhpbXVtIG51bWJlciBvZiBgTW9kZWxzYCB0byBy
ZXR1cm4gKHBlciBwYWdlKS4KCiBUaGUgc2VydmljZSBtYXkgcmV0dXJuIGZld2VyIG1vZGVs
cy4KIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwIG1vZGVscyB3aWxsIGJlIHJldHVybmVk
IHBlciBwYWdlLgogVGhpcyBtZXRob2QgcmV0dXJucyBhdCBtb3N0IDEwMDAgbW9kZWxzIHBl
ciBwYWdlLCBldmVuIGlmIHlvdSBwYXNzIGEgbGFyZ2VyCiBwYWdlX3NpemUuCgoNCgUEAQIA
BRIEhQECBwoNCgUEAQIAARIEhQEIEQoNCgUEAQIAAxIEhQEUFQqwAgoEBAECARIEjgECGBqh
AiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdE1vZGVsc2Ag
Y2FsbC4KCiBQcm92aWRlIHRoZSBgcGFnZV90b2tlbmAgcmV0dXJuZWQgYnkgb25lIHJlcXVl
c3QgYXMgYW4gYXJndW1lbnQgdG8gdGhlIG5leHQKIHJlcXVlc3QgdG8gcmV0cmlldmUgdGhl
IG5leHQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHBy
b3ZpZGVkIHRvIGBMaXN0TW9kZWxzYCBtdXN0IG1hdGNoCiB0aGUgY2FsbCB0aGF0IHByb3Zp
ZGVkIHRoZSBwYWdlIHRva2VuLgoKDQoFBAECAQUSBI4BAggKDQoFBAECAQESBI4BCRMKDQoF
BAECAQMSBI4BFhcKUAoCBAISBpIBAJoBARpCIFJlc3BvbnNlIGZyb20gYExpc3RNb2RlbGAg
Y29udGFpbmluZyBhIHBhZ2luYXRlZCBsaXN0IG9mIE1vZGVscy4KCgsKAwQCARIEkgEIGgok
CgQEAgIAEgSUAQIcGhYgVGhlIHJldHVybmVkIE1vZGVscy4KCg0KBQQCAgAEEgSUAQIKCg0K
BQQCAgAGEgSUAQsQCg0KBQQCAgABEgSUAREXCg0KBQQCAgADEgSUARobCooBCgQEAgIBEgSZ
AQIdGnwgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJl
dHJpZXZlIHRoZSBuZXh0IHBhZ2UuCgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVy
ZSBhcmUgbm8gbW9yZSBwYWdlcy4KCg0KBQQCAgEFEgSZAQIICg0KBQQCAgEBEgSZAQkYCg0K
BQQCAgEDEgSZARscCkcKAgQDEgadAQCnAQEaOSBSZXF1ZXN0IGZvciBnZXR0aW5nIGluZm9y
bWF0aW9uIGFib3V0IGEgc3BlY2lmaWMgTW9kZWwuCgoLCgMEAwESBJ0BCBwKXwoEBAMCABIG
oQECpgEEGk8gUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbC4KCiBG
b3JtYXQ6IGB0dW5lZE1vZGVscy9teS1tb2RlbC1pZGAKCg0KBQQDAgAFEgShAQIICg0KBQQD
AgABEgShAQkNCg0KBQQDAgADEgShARARCg8KBQQDAgAIEgahARKmAQMKEAoIBAMCAAicCAAS
BKIBBCoKEQoHBAMCAAifCBIGowEEpQEFCjAKAgQEEgaqAQC7AQEaIiBSZXF1ZXN0IGZvciBs
aXN0aW5nIFR1bmVkTW9kZWxzLgoKCwoDBAQBEgSqAQgeCpUCCgQEBAIAEgSxAQI/GoYCIE9w
dGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYFR1bmVkTW9kZWxzYCB0byByZXR1cm4g
KHBlciBwYWdlKS4KIFRoZSBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIgdHVuZWQgbW9kZWxz
LgoKIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDEwIHR1bmVkIG1vZGVscyB3aWxsIGJlIHJl
dHVybmVkLgogVGhpcyBtZXRob2QgcmV0dXJucyBhdCBtb3N0IDEwMDAgbW9kZWxzIHBlciBw
YWdlLCBldmVuIGlmIHlvdSBwYXNzIGEgbGFyZ2VyCiBwYWdlX3NpemUuCgoNCgUEBAIABRIE
sQECBwoNCgUEBAIAARIEsQEIEQoNCgUEBAIAAxIEsQEUFQoNCgUEBAIACBIEsQEWPgoQCggE
BAIACJwIABIEsQEXPQrEAgoEBAQCARIEugECQRq1AiBPcHRpb25hbC4gQSBwYWdlIHRva2Vu
LCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RUdW5lZE1vZGVsc2AgY2FsbC4KCiBQ
cm92aWRlIHRoZSBgcGFnZV90b2tlbmAgcmV0dXJuZWQgYnkgb25lIHJlcXVlc3QgYXMgYW4g
YXJndW1lbnQgdG8gdGhlIG5leHQKIHJlcXVlc3QgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFn
ZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRv
IGBMaXN0VHVuZWRNb2RlbHNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQg
dGhlIHBhZ2UgdG9rZW4uCgoNCgUEBAIBBRIEugECCAoNCgUEBAIBARIEugEJEwoNCgUEBAIB
AxIEugEWFwoNCgUEBAIBCBIEugEYQAoQCggEBAIBCJwIABIEugEZPwpWCgIEBRIGvgEAxgEB
GkggUmVzcG9uc2UgZnJvbSBgTGlzdFR1bmVkTW9kZWxzYCBjb250YWluaW5nIGEgcGFnaW5h
dGVkIGxpc3Qgb2YgTW9kZWxzLgoKCwoDBAUBEgS+AQgfCiQKBAQFAgASBMABAicaFiBUaGUg
cmV0dXJuZWQgTW9kZWxzLgoKDQoFBAUCAAQSBMABAgoKDQoFBAUCAAYSBMABCxUKDQoFBAUC
AAESBMABFiIKDQoFBAUCAAMSBMABJSYKigEKBAQFAgESBMUBAh0afCBBIHRva2VuLCB3aGlj
aCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFn
ZS4KCiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBtb3JlIHBhZ2Vz
LgoKDQoFBAUCAQUSBMUBAggKDQoFBAUCAQESBMUBCRgKDQoFBAUCAQMSBMUBGxwKLwoCBAYS
BskBANIBARohIFJlcXVlc3QgdG8gY3JlYXRlIGEgVHVuZWRNb2RlbC4KCgsKAwQGARIEyQEI
HwqQAgoEBAYCABIEzgECThqBAiBPcHRpb25hbC4gVGhlIHVuaXF1ZSBpZCBmb3IgdGhlIHR1
bmVkIG1vZGVsIGlmIHNwZWNpZmllZC4KIFRoaXMgdmFsdWUgc2hvdWxkIGJlIHVwIHRvIDQw
IGNoYXJhY3RlcnMsIHRoZSBmaXJzdCBjaGFyYWN0ZXIgbXVzdCBiZSBhCiBsZXR0ZXIsIHRo
ZSBsYXN0IGNvdWxkIGJlIGEgbGV0dGVyIG9yIGEgbnVtYmVyLiBUaGUgaWQgbXVzdCBtYXRj
aCB0aGUKIHJlZ3VsYXIgZXhwcmVzc2lvbjogW2Etel0oW2EtejAtOS1dezAsMzh9W2EtejAt
OV0pPy4KCg0KBQQGAgAEEgTOAQIKCg0KBQQGAgAFEgTOAQsRCg0KBQQGAgABEgTOARIgCg0K
BQQGAgADEgTOASMkCg0KBQQGAgAIEgTOASVNChAKCAQGAgAInAgAEgTOASZMCjQKBAQGAgES
BNEBAkYaJiBSZXF1aXJlZC4gVGhlIHR1bmVkIG1vZGVsIHRvIGNyZWF0ZS4KCg0KBQQGAgEG
EgTRAQIMCg0KBQQGAgEBEgTRAQ0YCg0KBQQGAgEDEgTRARscCg0KBQQGAgEIEgTRAR1FChAK
CAQGAgEInAgAEgTRAR5ECnkKAgQHEgbWAQDnAQEaayBNZXRhZGF0YSBhYm91dCB0aGUgc3Rh
dGUgYW5kIHByb2dyZXNzIG9mIGNyZWF0aW5nIGEgdHVuZWQgbW9kZWwgcmV0dXJuZWQgZnJv
bQogdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24KCgsKAwQHARIE1gEIIApPCgQEBwIAEgbY
AQLaAQUaPyBOYW1lIG9mIHRoZSB0dW5lZCBtb2RlbCBhc3NvY2lhdGVkIHdpdGggdGhlIHR1
bmluZyBvcGVyYXRpb24uCgoNCgUEBwIABRIE2AECCAoNCgUEBwIAARIE2AEJFAoNCgUEBwIA
AxIE2AEXGAoPCgUEBwIACBIG2AEZ2gEEChEKBwQHAgAInwgSBtgBGtoBAwoxCgQEBwIBEgTd
AQIYGiMgVGhlIHRvdGFsIG51bWJlciBvZiB0dW5pbmcgc3RlcHMuCgoNCgUEBwIBBRIE3QEC
BwoNCgUEBwIBARIE3QEIEwoNCgUEBwIBAxIE3QEWFwouCgQEBwICEgTgAQIcGiAgVGhlIG51
bWJlciBvZiBzdGVwcyBjb21wbGV0ZWQuCgoNCgUEBwICBRIE4AECBwoNCgUEBwICARIE4AEI
FwoNCgUEBwICAxIE4AEaGwpCCgQEBwIDEgTjAQIeGjQgVGhlIGNvbXBsZXRlZCBwZXJjZW50
YWdlIGZvciB0aGUgdHVuaW5nIG9wZXJhdGlvbi4KCg0KBQQHAgMFEgTjAQIHCg0KBQQHAgMB
EgTjAQgZCg0KBQQHAgMDEgTjARwdCjAKBAQHAgQSBOYBAigaIiBNZXRyaWNzIGNvbGxlY3Rl
ZCBkdXJpbmcgdHVuaW5nLgoKDQoFBAcCBAQSBOYBAgoKDQoFBAcCBAYSBOYBCxkKDQoFBAcC
BAESBOYBGiMKDQoFBAcCBAMSBOYBJicKLwoCBAgSBuoBAPEBARohIFJlcXVlc3QgdG8gdXBk
YXRlIGEgVHVuZWRNb2RlbC4KCgsKAwQIARIE6gEIHwo0CgQECAIAEgTsAQJGGiYgUmVxdWly
ZWQuIFRoZSB0dW5lZCBtb2RlbCB0byB1cGRhdGUuCgoNCgUECAIABhIE7AECDAoNCgUECAIA
ARIE7AENGAoNCgUECAIAAxIE7AEbHAoNCgUECAIACBIE7AEdRQoQCggECAIACJwIABIE7AEe
RAo5CgQECAIBEgbvAQLwAS8aKSBSZXF1aXJlZC4gVGhlIGxpc3Qgb2YgZmllbGRzIHRvIHVw
ZGF0ZS4KCg0KBQQIAgEGEgTvAQIbCg0KBQQIAgEBEgTvARwnCg0KBQQIAgEDEgTvASorCg0K
BQQIAgEIEgTwAQYuChAKCAQIAgEInAgAEgTwAQctCi8KAgQJEgb0AQD9AQEaISBSZXF1ZXN0
IHRvIGRlbGV0ZSBhIFR1bmVkTW9kZWwuCgoLCgMECQESBPQBCB8KXgoEBAkCABIG9wEC/AEE
Gk4gUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbC4KIEZvcm1hdDog
YHR1bmVkTW9kZWxzL215LW1vZGVsLWlkYAoKDQoFBAkCAAUSBPcBAggKDQoFBAkCAAESBPcB
CQ0KDQoFBAkCAAMSBPcBEBEKDwoFBAkCAAgSBvcBEvwBAwoQCggECQIACJwIABIE+AEEKgoR
CgcECQIACJ8IEgb5AQT7AQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::GetModelRequest ===
    # Fields for GetModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsRequest ===
    # Fields for ListModelsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsResponse ===
    # Fields for ListModelsResponse
    # Field: models Type: 11 (.google.ai.generativelanguage.v1beta3.Model)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::GetTunedModelRequest ===
    # Fields for GetTunedModelRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsRequest ===
    # Fields for ListTunedModelsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsResponse ===
    # Fields for ListTunedModelsResponse
    # Field: tuned_models Type: 11 (.google.ai.generativelanguage.v1beta3.TunedModel)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::CreateTunedModelRequest ===
    # Fields for CreateTunedModelRequest
    # Field: tuned_model_id Type: 9 ()
    # Field: tuned_model Type: 11 (.google.ai.generativelanguage.v1beta3.TunedModel)

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::CreateTunedModelMetadata ===
    # Fields for CreateTunedModelMetadata
    # Field: tuned_model Type: 9 ()
    # Field: total_steps Type: 5 ()
    # Field: completed_steps Type: 5 ()
    # Field: completed_percent Type: 2 ()
    # Field: snapshots Type: 11 (.google.ai.generativelanguage.v1beta3.TuningSnapshot)

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::UpdateTunedModelRequest ===
    # Fields for UpdateTunedModelRequest
    # Field: tuned_model Type: 11 (.google.ai.generativelanguage.v1beta3.TunedModel)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Ai::Generativelanguage::V1beta3::ModelService::DeleteTunedModelRequest ===
    # Fields for DeleteTunedModelRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Ai::Generativelanguage::V1beta3::ModelService::ModelServiceClient ===
package Google::Ai::Generativelanguage::V1beta3::ModelService::ModelServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1beta3::ModelService::ModelServiceClient

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
        ? Google::Ai::Generativelanguage::V1beta3::ModelService::GetModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'GetModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::Model::Model',
    });
}

sub list_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'ListModels',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsResponse',
    });
}

sub get_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::ModelService::GetTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'GetTunedModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel',
    });
}

sub list_tuned_models {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'ListTunedModels',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsResponse',
    });
}

sub create_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::ModelService::CreateTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'CreateTunedModel',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::ModelService::UpdateTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'UpdateTunedModel',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel',
    });
}

sub delete_tuned_model {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::ModelService::DeleteTunedModelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.ModelService',
        method         => 'DeleteTunedModel',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::ModelService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta3/model_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::ModelService;

    my $msg = Google::Ai::Generativelanguage::V1beta3::ModelService::GetModelRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta3::ModelService::GetModelRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta3/model_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::GetModelRequest

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

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsRequest

Request for listing all Models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of `Models` to return (per page).

The service may return fewer models.
If unspecified, at most 50 models will be returned per page.
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

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsResponse

Response from `ListModel` containing a paginated list of Models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->models() >> / C<< $msg->models($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Model::Model>)

The returned Models.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.

If this field is omitted, there are no more pages.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::GetTunedModelRequest

Request for getting information about a specific Model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the model.

Format: `tunedModels/my-model-id`

=back

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsRequest

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

=back

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsResponse

Response from `ListTunedModels` containing a paginated list of Models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_models() >> / C<< $msg->tuned_models($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel>)

The returned Models.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.

If this field is omitted, there are no more pages.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::CreateTunedModelRequest

Request to create a TunedModel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model_id() >> / C<< $msg->tuned_model_id($value) >>

Type: C<String>

Optional. The unique id for the tuned model if specified.
This value should be up to 40 characters, the first character must be a
letter, the last could be a letter or a number. The id must match the
regular expression: [a-z]([a-z0-9-]{0,38}[a-z0-9])?.

=item * C<< $msg->tuned_model() >> / C<< $msg->tuned_model($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel>)

Required. The tuned model to create.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::CreateTunedModelMetadata

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

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningSnapshot>)

Metrics collected during tuning.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::UpdateTunedModelRequest

Request to update a TunedModel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model() >> / C<< $msg->tuned_model($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel>)

Required. The tuned model to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The list of fields to update.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::ModelService::DeleteTunedModelRequest

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta3::ModelService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
