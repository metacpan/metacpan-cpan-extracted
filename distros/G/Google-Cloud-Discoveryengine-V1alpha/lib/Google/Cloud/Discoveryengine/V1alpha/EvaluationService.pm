package Google::Cloud::Discoveryengine::V1alpha::EvaluationService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Evaluation };
    eval { require Google::Cloud::Discoveryengine::V1alpha::SampleQuery };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZXZhbHVhdGlvbl9zZXJ2
aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
GjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZXZhbHVhdGlvbi5wcm90
bxo3Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL3NhbXBsZV9xdWVyeS5w
cm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8iXQoUR2V0RXZhbHVh
dGlvblJlcXVlc3QSRQoEbmFtZRgBIAEoCUIx4EEC+kErCilkaXNjb3ZlcnllbmdpbmUuZ29v
Z2xlYXBpcy5jb20vRXZhbHVhdGlvblIEbmFtZSKdAQoWTGlzdEV2YWx1YXRpb25zUmVxdWVz
dBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMu
Y29tL0xvY2F0aW9uUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpw
YWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4ilQEKF0xpc3RFdmFsdWF0aW9uc1Jlc3BvbnNl
ElIKC2V2YWx1YXRpb25zGAEgAygLMjAuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkV2YWx1YXRpb25SC2V2YWx1YXRpb25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEo
CVINbmV4dFBhZ2VUb2tlbiK5AQoXQ3JlYXRlRXZhbHVhdGlvblJlcXVlc3QSRwoGcGFyZW50
GAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Mb2NhdGlv
blIGcGFyZW50ElUKCmV2YWx1YXRpb24YAiABKAsyMC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvbkID4EECUgpldmFsdWF0aW9uIhoKGENyZWF0ZUV2
YWx1YXRpb25NZXRhZGF0YSKtAQocTGlzdEV2YWx1YXRpb25SZXN1bHRzUmVxdWVzdBJRCgpl
dmFsdWF0aW9uGAEgASgJQjHgQQL6QSsKKWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9FdmFsdWF0aW9uUgpldmFsdWF0aW9uEhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUS
HQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIqEDCh1MaXN0RXZhbHVhdGlvblJlc3Vs
dHNSZXNwb25zZRKDAQoSZXZhbHVhdGlvbl9yZXN1bHRzGAEgAygLMlQuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3RFdmFsdWF0aW9uUmVzdWx0c1Jlc3BvbnNl
LkV2YWx1YXRpb25SZXN1bHRSEWV2YWx1YXRpb25SZXN1bHRzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbhrRAQoQRXZhbHVhdGlvblJlc3VsdBJZCgxzYW1wbGVf
cXVlcnkYASABKAsyMS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2Ft
cGxlUXVlcnlCA+BBA1ILc2FtcGxlUXVlcnkSYgoPcXVhbGl0eV9tZXRyaWNzGAIgASgLMjQu
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlF1YWxpdHlNZXRyaWNzQgPg
QQNSDnF1YWxpdHlNZXRyaWNzMskIChFFdmFsdWF0aW9uU2VydmljZRLCAQoNR2V0RXZhbHVh
dGlvbhI6Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5HZXRFdmFsdWF0
aW9uUmVxdWVzdBowLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FdmFs
dWF0aW9uIkOC0+STAjYSNC92MWFscGhhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
ZXZhbHVhdGlvbnMvKn3aQQRuYW1lEtUBCg9MaXN0RXZhbHVhdGlvbnMSPC5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdEV2YWx1YXRpb25zUmVxdWVzdBo9Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5MaXN0RXZhbHVhdGlvbnNSZXNw
b25zZSJFgtPkkwI2EjQvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9
L2V2YWx1YXRpb25z2kEGcGFyZW50EsICChBDcmVhdGVFdmFsdWF0aW9uEj0uZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNyZWF0ZUV2YWx1YXRpb25SZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLPAYLT5JMCQiI0L3YxYWxwaGEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9ldmFsdWF0aW9uczoKZXZhbHVhdGlvbtpBEXBh
cmVudCxldmFsdWF0aW9uykFwCi9nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuRXZhbHVhdGlvbhI9Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNy
ZWF0ZUV2YWx1YXRpb25NZXRhZGF0YRL9AQoVTGlzdEV2YWx1YXRpb25SZXN1bHRzEkIuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkxpc3RFdmFsdWF0aW9uUmVzdWx0
c1JlcXVlc3QaQy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuTGlzdEV2
YWx1YXRpb25SZXN1bHRzUmVzcG9uc2UiW4LT5JMCSBJGL3YxYWxwaGEve2V2YWx1YXRpb249
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9ldmFsdWF0aW9ucy8qfTpsaXN0UmVzdWx0c9pBCmV2
YWx1YXRpb24aUspBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CogIKKGNvbS5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCFkV2YWx1YXRpb25TZXJ2aWNlUHJvdG9Q
AVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFhbHBoYS9kaXNj
b3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCJEdv
b2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFBbHBoYcoCJEdvb2dsZVxDbG91ZFxEaXNj
b3ZlcnlFbmdpbmVcVjFhbHBoYeoCJ0dvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6
VjFhbHBoYUrEQgoHEgUOAPsBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAALQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAj
CgkKAgMEEgMWAD8KCQoCAwUSAxcAQQoJCgIDBhIDGAAtCggKAQgSAxoAQQoJCgIIJRIDGgBB
CggKAQgSAxsAaQoJCgIICxIDGwBpCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0ANwoJ
CgIICBIDHQA3CggKAQgSAx4AQQoJCgIIARIDHgBBCggKAQgSAx8ALQoJCgIIJBIDHwAtCggK
AQgSAyAAQQoJCgIIKRIDIABBCggKAQgSAyEAQAoJCgIILRIDIQBACmMKAgYAEgQlAFYBGlcg
U2VydmljZSBmb3IgbWFuYWdpbmcKIFtFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvbl1zLAoKCgoDBgABEgMlCBkKCgoDBgADEgMm
AkYKDAoFBgADmQgSAyYCRgoLCgMGAAMSBCcCKDcKDQoFBgADmggSBCcCKDcKVQoEBgACABIE
KwIwAxpHIEdldHMgYSBbRXZhbHVhdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWFscGhhLkV2YWx1YXRpb25dLgoKDAoFBgACAAESAysGEwoMCgUGAAIAAhIDKxQoCgwK
BQYAAgADEgMrMz0KDQoFBgACAAQSBCwELgYKEQoJBgACAASwyrwiEgQsBC4GCgwKBQYAAgAE
EgMvBDIKDwoIBgACAASbCAASAy8EMgpfCgQGAAIBEgQ0AjoDGlEgR2V0cyBhIGxpc3Qgb2YK
IFtFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZh
bHVhdGlvbl1zLgoKDAoFBgACAQESAzQGFQoMCgUGAAIBAhIDNBYsCgwKBQYAAgEDEgM1DyYK
DQoFBgACAQQSBDYEOAYKEQoJBgACAQSwyrwiEgQ2BDgGCgwKBQYAAgEEEgM5BDQKDwoIBgAC
AQSbCAASAzkENAqvAQoEBgACAhIEQAJLAxqgASBDcmVhdGVzIGEgW0V2YWx1YXRpb25dW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FdmFsdWF0aW9uXS4KCiBVcG9u
IGNyZWF0aW9uLCB0aGUgZXZhbHVhdGlvbiB3aWxsIGJlIGF1dG9tYXRpY2FsbHkgdHJpZ2dl
cmVkIGFuZCBiZWdpbgogZXhlY3V0aW9uLgoKDAoFBgACAgESA0AGFgoMCgUGAAICAhIDQBcu
CgwKBQYAAgIDEgNBDysKDQoFBgACAgQSBEIERQYKEQoJBgACAgSwyrwiEgRCBEUGCgwKBQYA
AgIEEgNGBD8KDwoIBgACAgSbCAASA0YEPwoNCgUGAAICBBIERwRKBgoPCgcGAAICBJkIEgRH
BEoGCnQKBAYAAgMSBE8CVQMaZiBHZXRzIGEgbGlzdCBvZiByZXN1bHRzIGZvciBhIGdpdmVu
IGEKIFtFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEu
RXZhbHVhdGlvbl0uCgoMCgUGAAIDARIDTwYbCgwKBQYAAgMCEgNPHDgKDAoFBgACAwMSA1AP
LAoNCgUGAAIDBBIEUQRTBgoRCgkGAAIDBLDKvCISBFEEUwYKDAoFBgACAwQSA1QEOAoPCggG
AAIDBJsIABIDVAQ4CpQBCgIEABIEWwBtARqHASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRXZh
bHVhdGlvblNlcnZpY2UuR2V0RXZhbHVhdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLkV2YWx1YXRpb25TZXJ2aWNlLkdldEV2YWx1YXRpb25dCiBtZXRob2Qu
CgoKCgMEAAESA1sIHAqGBAoEBAACABIEZwJsBBr3AyBSZXF1aXJlZC4gRnVsbCByZXNvdXJj
ZSBuYW1lIG9mCiBbRXZhbHVhdGlvbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkV2YWx1YXRpb25dLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2V2YWx1YXRpb25zL3tldmFsdWF0aW9ufWAuCgogSWYgdGhlIGNh
bGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gYWNjZXNzIHRoZQogW0V2YWx1YXRp
b25dW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FdmFsdWF0aW9uXSwg
cmVnYXJkbGVzcwogb2Ygd2hldGhlciBvciBub3QgaXQgZXhpc3RzLCBhIFBFUk1JU1NJT05f
REVOSUVEIGVycm9yIGlzIHJldHVybmVkLgoKIElmIHRoZSByZXF1ZXN0ZWQKIFtFdmFsdWF0
aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvbl0g
ZG9lcyBub3QKIGV4aXN0LCBhIE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQQA
AgAFEgNnAggKDAoFBAACAAESA2cJDQoMCgUEAAIAAxIDZxARCg0KBQQAAgAIEgRnEmwDCg8K
CAQAAgAInAgAEgNoBCoKDwoHBAACAAifCBIEaQRrBQqZAQoCBAESBXIAlAEBGosBIFJlcXVl
c3QgbWVzc2FnZSBmb3IKIFtFdmFsdWF0aW9uU2VydmljZS5MaXN0RXZhbHVhdGlvbnNdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FdmFsdWF0aW9uU2VydmljZS5M
aXN0RXZhbHVhdGlvbnNdCiBtZXRob2QuCgoKCgMEAQESA3IIHgrVAgoEBAECABIEegJ/BBrG
AiBSZXF1aXJlZC4gVGhlIHBhcmVudCBsb2NhdGlvbiByZXNvdXJjZSBuYW1lLCBzdWNoIGFz
CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCiBJZiB0aGUg
Y2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBsaXN0CiBbRXZhbHVhdGlvbl1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkV2YWx1YXRpb25dcyB1bmRl
ciB0aGlzCiBsb2NhdGlvbiwgcmVnYXJkbGVzcyBvZiB3aGV0aGVyIG9yIG5vdCB0aGlzIGxv
Y2F0aW9uIGV4aXN0cywgYQogYFBFUk1JU1NJT05fREVOSUVEYCBlcnJvciBpcyByZXR1cm5l
ZC4KCgwKBQQBAgAFEgN6AggKDAoFBAECAAESA3oJDwoMCgUEAQIAAxIDehITCg0KBQQBAgAI
EgR6FH8DCg8KCAQBAgAInAgAEgN7BCoKDwoHBAECAAifCBIEfAR+BQqkAgoEBAECARIEhwEC
FhqVAiBNYXhpbXVtIG51bWJlciBvZgogW0V2YWx1YXRpb25dW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5FdmFsdWF0aW9uXXMgdG8gcmV0dXJuLgogSWYgdW5zcGVj
aWZpZWQsIGRlZmF1bHRzIHRvIDEwMC4gVGhlIG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcyAx
MDAwLiBWYWx1ZXMKIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCgogSWYg
dGhpcyBmaWVsZCBpcyBuZWdhdGl2ZSwgYW4gYElOVkFMSURfQVJHVU1FTlRgIGVycm9yIGlz
IHJldHVybmVkLgoKDQoFBAECAQUSBIcBAgcKDQoFBAECAQESBIcBCBEKDQoFBAECAQMSBIcB
FBUK3AQKBAQBAgISBJMBAhgazQQgQSBwYWdlIHRva2VuCiBbTGlzdEV2YWx1YXRpb25zUmVz
cG9uc2UubmV4dF9wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YWxwaGEuTGlzdEV2YWx1YXRpb25zUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXSwKIHJlY2Vp
dmVkIGZyb20gYSBwcmV2aW91cwogW0V2YWx1YXRpb25TZXJ2aWNlLkxpc3RFdmFsdWF0aW9u
c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkV2YWx1YXRpb25TZXJ2
aWNlLkxpc3RFdmFsdWF0aW9uc10KIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0
aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFt
ZXRlcnMgcHJvdmlkZWQgdG8KIFtFdmFsdWF0aW9uU2VydmljZS5MaXN0RXZhbHVhdGlvbnNd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FdmFsdWF0aW9uU2Vydmlj
ZS5MaXN0RXZhbHVhdGlvbnNdCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQg
dGhlIHBhZ2UgdG9rZW4uIE90aGVyd2lzZSwgYW4KIGBJTlZBTElEX0FSR1VNRU5UYCBlcnJv
ciBpcyByZXR1cm5lZC4KCg0KBQQBAgIFEgSTAQIICg0KBQQBAgIBEgSTAQkTCg0KBQQBAgID
EgSTARYXCpsBCgIEAhIGmQEAogEBGowBIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbRXZhbHVh
dGlvblNlcnZpY2UuTGlzdEV2YWx1YXRpb25zXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYWxwaGEuRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2YWx1YXRpb25zXQogbWV0aG9k
LgoKCwoDBAIBEgSZAQgfClMKBAQCAgASBJsBAiYaRSBUaGUgW0V2YWx1YXRpb25dW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FdmFsdWF0aW9uXXMuCgoNCgUEAgIA
BBIEmwECCgoNCgUEAgIABhIEmwELFQoNCgUEAgIAARIEmwEWIQoNCgUEAgIAAxIEmwEkJQrv
AQoEBAICARIEoQECHRrgASBBIHRva2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMKIFtMaXN0RXZh
bHVhdGlvbnNSZXF1ZXN0LnBhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5MaXN0RXZhbHVhdGlvbnNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiB0byByZXRy
aWV2ZSB0aGUgbmV4dCBwYWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFy
ZSBubwogc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQCAgEFEgShAQIICg0KBQQCAgEBEgShAQkY
Cg0KBQQCAgEDEgShARscCpwBCgIEAxIGpwEAtAEBGo0BIFJlcXVlc3QgbWVzc2FnZSBmb3IK
IFtFdmFsdWF0aW9uU2VydmljZS5DcmVhdGVFdmFsdWF0aW9uXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvblNlcnZpY2UuQ3JlYXRlRXZhbHVhdGlv
bl0KIG1ldGhvZC4KCgsKAwQDARIEpwEIHwppCgQEAwIAEgaqAQKvAQQaWSBSZXF1aXJlZC4g
VGhlIHBhcmVudCByZXNvdXJjZSBuYW1lLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCg0KBQQDAgAFEgSqAQIICg0KBQQDAgABEgSqAQkP
Cg0KBQQDAgADEgSqARITCg8KBQQDAgAIEgaqARSvAQMKEAoIBAMCAAicCAASBKsBBCoKEQoH
BAMCAAifCBIGrAEErgEFCmcKBAQDAgESBLMBAkUaWSBSZXF1aXJlZC4gVGhlIFtFdmFsdWF0
aW9uXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvbl0K
IHRvIGNyZWF0ZS4KCg0KBQQDAgEGEgSzAQIMCg0KBQQDAgEBEgSzAQ0XCg0KBQQDAgEDEgSz
ARobCg0KBQQDAgEIEgSzARxEChAKCAQDAgEInAgAEgSzAR1DCpMBCgIEBBIEuQEAIxqGASBN
ZXRhZGF0YSBmb3IKIFtFdmFsdWF0aW9uU2VydmljZS5DcmVhdGVFdmFsdWF0aW9uXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvblNlcnZpY2UuQ3Jl
YXRlRXZhbHVhdGlvbl0KIG1ldGhvZC4KCgsKAwQEARIEuQEIIAqmAQoCBAUSBr4BAN4BARqX
ASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2YWx1YXRp
b25SZXN1bHRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVh
dGlvblNlcnZpY2UuTGlzdEV2YWx1YXRpb25SZXN1bHRzXQogbWV0aG9kLgoKCwoDBAUBEgS+
AQgkCsgCCgQEBQIAEgbFAQLKAQQatwIgUmVxdWlyZWQuIFRoZSBldmFsdWF0aW9uIHJlc291
cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vZXZhbHVhdGlvbnMve2V2YWx1YXRpb259YC4KCiBJZiB0aGUgY2FsbGVyIGRvZXMg
bm90IGhhdmUgcGVybWlzc2lvbiB0byBsaXN0IFtFdmFsdWF0aW9uUmVzdWx0XVtdCiB1bmRl
ciB0aGlzIGV2YWx1YXRpb24sIHJlZ2FyZGxlc3Mgb2Ygd2hldGhlciBvciBub3QgdGhpcyBl
dmFsdWF0aW9uCiBzZXQgZXhpc3RzLCBhIGBQRVJNSVNTSU9OX0RFTklFRGAgZXJyb3IgaXMg
cmV0dXJuZWQuCgoNCgUEBQIABRIExQECCAoNCgUEBQIAARIExQEJEwoNCgUEBQIAAxIExQEW
FwoPCgUEBQIACBIGxQEYygEDChAKCAQFAgAInAgAEgTGAQQqChEKBwQFAgAInwgSBscBBMkB
BQr5AQoEBAUCARIE0QECFhrqASBNYXhpbXVtIG51bWJlciBvZiBbRXZhbHVhdGlvblJlc3Vs
dF1bXSB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLAogZGVmYXVsdHMgdG8gMTAwLiBUaGUg
bWF4aW11bSBhbGxvd2VkIHZhbHVlIGlzIDEwMDAuIFZhbHVlcyBhYm92ZSAxMDAwIHdpbGwK
IGJlIGNvZXJjZWQgdG8gMTAwMC4KCiBJZiB0aGlzIGZpZWxkIGlzIG5lZ2F0aXZlLCBhbiBg
SU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEBQIBBRIE0QECBwoN
CgUEBQIBARIE0QEIEQoNCgUEBQIBAxIE0QEUFQqABQoEBAUCAhIE3QECGBrxBCBBIHBhZ2Ug
dG9rZW4KIFtMaXN0RXZhbHVhdGlvblJlc3VsdHNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5d
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5MaXN0RXZhbHVhdGlvblJl
c3VsdHNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dLAogcmVjZWl2ZWQgZnJvbSBhIHByZXZp
b3VzCiBbRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2YWx1YXRpb25SZXN1bHRzXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRXZhbHVhdGlvblNlcnZpY2UuTGlzdEV2
YWx1YXRpb25SZXN1bHRzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBz
dWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVy
cyBwcm92aWRlZCB0bwogW0V2YWx1YXRpb25TZXJ2aWNlLkxpc3RFdmFsdWF0aW9uUmVzdWx0
c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkV2YWx1YXRpb25TZXJ2
aWNlLkxpc3RFdmFsdWF0aW9uUmVzdWx0c10KIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBw
cm92aWRlZCB0aGUgcGFnZSB0b2tlbi4gT3RoZXJ3aXNlLCBhbgogYElOVkFMSURfQVJHVU1F
TlRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAUCAgUSBN0BAggKDQoFBAUCAgESBN0BCRMK
DQoFBAUCAgMSBN0BFhcKpwEKAgQGEgbjAQD7AQEamAEgUmVzcG9uc2UgbWVzc2FnZSBmb3IK
IFtFdmFsdWF0aW9uU2VydmljZS5MaXN0RXZhbHVhdGlvblJlc3VsdHNdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5FdmFsdWF0aW9uU2VydmljZS5MaXN0RXZhbHVh
dGlvblJlc3VsdHNdCiBtZXRob2QuCgoLCgMEBgESBOMBCCUKiAEKBAQGAwASBuYBAvABAxp4
IFJlcHJlc2VudHMgdGhlIHJlc3VsdHMgb2YgYW4gZXZhbHVhdGlvbiBmb3IgYSBzaW5nbGUK
IFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNh
bXBsZVF1ZXJ5XS4KCg0KBQQGAwABEgTmAQoaCngKBgQGAwACABIE6gEETRpoIE91dHB1dCBv
bmx5LiBUaGUKIFtTYW1wbGVRdWVyeV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLlNhbXBsZVF1ZXJ5XSB0aGF0IHdhcwogZXZhbHVhdGVkLgoKDwoHBAYDAAIABhIE
6gEEDwoPCgcEBgMAAgABEgTqARAcCg8KBwQGAwACAAMSBOoBHyAKDwoHBAYDAAIACBIE6gEh
TAoSCgoEBgMAAgAInAgAEgTqASJLCpcBCgYEBgMAAgESBu4BBO8BNBqEASBPdXRwdXQgb25s
eS4gVGhlIG1ldHJpY3MgcHJvZHVjZWQgYnkgdGhlIGV2YWx1YXRpb24sIGZvciBhIGdpdmVu
CiBbU2FtcGxlUXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5T
YW1wbGVRdWVyeV0uCgoPCgcEBgMAAgEGEgTuAQQSCg8KBwQGAwACAQESBO4BEyIKDwoHBAYD
AAIBAxIE7gElJgoPCgcEBgMAAgEIEgTvAQgzChIKCgQGAwACAQicCAASBO8BCTIKfgoEBAYC
ABIE9AECMxpwIFRoZQogW0V2YWx1YXRpb25SZXN1bHRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5MaXN0RXZhbHVhdGlvblJlc3VsdHNSZXNwb25zZS5FdmFsdWF0
aW9uUmVzdWx0XXMuCgoNCgUEBgIABBIE9AECCgoNCgUEBgIABhIE9AELGwoNCgUEBgIAARIE
9AEcLgoNCgUEBgIAAxIE9AExMgr7AQoEBAYCARIE+gECHRrsASBBIHRva2VuIHRoYXQgY2Fu
IGJlIHNlbnQgYXMKIFtMaXN0RXZhbHVhdGlvblJlc3VsdHNSZXF1ZXN0LnBhZ2VfdG9rZW5d
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5MaXN0RXZhbHVhdGlvblJl
c3VsdHNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLiBJ
ZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubwogc3Vic2VxdWVudCBwYWdl
cy4KCg0KBQQGAgEFEgT6AQIICg0KBQQGAgEBEgT6AQkYCg0KBQQGAgEDEgT6ARscYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest ===
    # Fields for GetEvaluationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsRequest ===
    # Fields for ListEvaluationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsResponse ===
    # Fields for ListEvaluationsResponse
    # Field: evaluations Type: 11 (.google.cloud.discoveryengine.v1alpha.Evaluation)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationRequest ===
    # Fields for CreateEvaluationRequest
    # Field: parent Type: 9 ()
    # Field: evaluation Type: 11 (.google.cloud.discoveryengine.v1alpha.Evaluation)

# === Message: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationMetadata ===
    # Fields for CreateEvaluationMetadata

# === Message: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsRequest ===
    # Fields for ListEvaluationResultsRequest
    # Field: evaluation Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse ===
    # Fields for ListEvaluationResultsResponse
    # Field: evaluation_results Type: 11 (.google.cloud.discoveryengine.v1alpha.ListEvaluationResultsResponse.EvaluationResult)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::EvaluationServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::EvaluationService::EvaluationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::EvaluationService::EvaluationServiceClient

Client stub representing the remote C<EvaluationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub get_evaluation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EvaluationService',
        method         => 'GetEvaluation',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation',
    });
}

sub list_evaluations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EvaluationService',
        method         => 'ListEvaluations',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsResponse',
    });
}

sub create_evaluation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EvaluationService',
        method         => 'CreateEvaluation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_evaluation_results {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EvaluationService',
        method         => 'ListEvaluationResults',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::EvaluationService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/evaluation_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::EvaluationService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/evaluation_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest

Request message for
[EvaluationService.GetEvaluation][google.cloud.discoveryengine.v1alpha.EvaluationService.GetEvaluation]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation], such as
`projects/{project}/locations/{location}/evaluations/{evaluation}`.

If the caller does not have permission to access the
[Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation], regardless
of whether or not it exists, a PERMISSION_DENIED error is returned.

If the requested
[Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation] does not
exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsRequest

Request message for
[EvaluationService.ListEvaluations][google.cloud.discoveryengine.v1alpha.EvaluationService.ListEvaluations]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent location resource name, such as
`projects/{project}/locations/{location}`.

If the caller does not have permission to list
[Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation]s under this
location, regardless of whether or not this location exists, a
`PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of
[Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation]s to return.
If unspecified, defaults to 100. The maximum allowed value is 1000. Values
above 1000 will be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListEvaluationsResponse.next_page_token][google.cloud.discoveryengine.v1alpha.ListEvaluationsResponse.next_page_token],
received from a previous
[EvaluationService.ListEvaluations][google.cloud.discoveryengine.v1alpha.EvaluationService.ListEvaluations]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[EvaluationService.ListEvaluations][google.cloud.discoveryengine.v1alpha.EvaluationService.ListEvaluations]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsResponse

Response message for
[EvaluationService.ListEvaluations][google.cloud.discoveryengine.v1alpha.EvaluationService.ListEvaluations]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluations() >> / C<< $msg->evaluations($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation>)

The [Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListEvaluationsRequest.page_token][google.cloud.discoveryengine.v1alpha.ListEvaluationsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationRequest

Request message for
[EvaluationService.CreateEvaluation][google.cloud.discoveryengine.v1alpha.EvaluationService.CreateEvaluation]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->evaluation() >> / C<< $msg->evaluation($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation>)

Required. The [Evaluation][google.cloud.discoveryengine.v1alpha.Evaluation]
to create.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationMetadata

Metadata for
[EvaluationService.CreateEvaluation][google.cloud.discoveryengine.v1alpha.EvaluationService.CreateEvaluation]
method.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsRequest

Request message for
[EvaluationService.ListEvaluationResults][google.cloud.discoveryengine.v1alpha.EvaluationService.ListEvaluationResults]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluation() >> / C<< $msg->evaluation($value) >>

Type: C<String>

Required. The evaluation resource name, such as
`projects/{project}/locations/{location}/evaluations/{evaluation}`.

If the caller does not have permission to list [EvaluationResult][]
under this evaluation, regardless of whether or not this evaluation
set exists, a `PERMISSION_DENIED` error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of [EvaluationResult][] to return. If unspecified,
defaults to 100. The maximum allowed value is 1000. Values above 1000 will
be coerced to 1000.

If this field is negative, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListEvaluationResultsResponse.next_page_token][google.cloud.discoveryengine.v1alpha.ListEvaluationResultsResponse.next_page_token],
received from a previous
[EvaluationService.ListEvaluationResults][google.cloud.discoveryengine.v1alpha.EvaluationService.ListEvaluationResults]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[EvaluationService.ListEvaluationResults][google.cloud.discoveryengine.v1alpha.EvaluationService.ListEvaluationResults]
must match the call that provided the page token. Otherwise, an
`INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse

Response message for
[EvaluationService.ListEvaluationResults][google.cloud.discoveryengine.v1alpha.EvaluationService.ListEvaluationResults]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluation_results() >> / C<< $msg->evaluation_results($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse::EvaluationResult>)

The
[EvaluationResult][google.cloud.discoveryengine.v1alpha.ListEvaluationResultsResponse.EvaluationResult]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListEvaluationResultsRequest.page_token][google.cloud.discoveryengine.v1alpha.ListEvaluationResultsRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::EvaluationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
