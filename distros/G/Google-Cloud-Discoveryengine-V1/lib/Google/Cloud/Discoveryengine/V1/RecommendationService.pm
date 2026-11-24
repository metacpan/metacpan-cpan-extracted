package Google::Cloud::Discoveryengine::V1::RecommendationService;

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
    eval { require Google::Cloud::Discoveryengine::V1::Document };
    eval { require Google::Cloud::Discoveryengine::V1::UserEvent };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3JlY29tbWVuZGF0aW9uX3NlcnZp
Y2UucHJvdG8SH2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29n
bGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2RvY3VtZW50LnByb3RvGjBnb29nbGUvY2xv
dWQvZGlzY292ZXJ5ZW5naW5lL3YxL3VzZXJfZXZlbnQucHJvdG8aHGdvb2dsZS9wcm90b2J1
Zi9zdHJ1Y3QucHJvdG8i5gQKEFJlY29tbWVuZFJlcXVlc3QSWwoOc2VydmluZ19jb25maWcY
ASABKAlCNOBBAvpBLgosZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NlcnZpbmdD
b25maWdSDXNlcnZpbmdDb25maWcSTgoKdXNlcl9ldmVudBgCIAEoCzIqLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXNlckV2ZW50QgPgQQJSCXVzZXJFdmVudBIbCglwYWdl
X3NpemUYAyABKAVSCHBhZ2VTaXplEhYKBmZpbHRlchgEIAEoCVIGZmlsdGVyEiMKDXZhbGlk
YXRlX29ubHkYBSABKAhSDHZhbGlkYXRlT25seRJVCgZwYXJhbXMYBiADKAsyPS5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJlY29tbWVuZFJlcXVlc3QuUGFyYW1zRW50cnlS
BnBhcmFtcxJiCgt1c2VyX2xhYmVscxgIIAMoCzJBLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuUmVjb21tZW5kUmVxdWVzdC5Vc2VyTGFiZWxzRW50cnlSCnVzZXJMYWJlbHMa
UQoLUGFyYW1zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSLAoFdmFsdWUYAiABKAsyFi5nb29n
bGUucHJvdG9idWYuVmFsdWVSBXZhbHVlOgI4ARo9Cg9Vc2VyTGFiZWxzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASKhBAoRUmVjb21tZW5kUmVz
cG9uc2USYQoHcmVzdWx0cxgBIAMoCzJHLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuUmVjb21tZW5kUmVzcG9uc2UuUmVjb21tZW5kYXRpb25SZXN1bHRSB3Jlc3VsdHMSKwoR
YXR0cmlidXRpb25fdG9rZW4YAiABKAlSEGF0dHJpYnV0aW9uVG9rZW4SHwoLbWlzc2luZ19p
ZHMYAyADKAlSCm1pc3NpbmdJZHMSIwoNdmFsaWRhdGVfb25seRgEIAEoCFIMdmFsaWRhdGVP
bmx5GrUCChRSZWNvbW1lbmRhdGlvblJlc3VsdBIOCgJpZBgBIAEoCVICaWQSRQoIZG9jdW1l
bnQYAiABKAsyKS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50Ughk
b2N1bWVudBJxCghtZXRhZGF0YRgDIAMoCzJVLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuUmVjb21tZW5kUmVzcG9uc2UuUmVjb21tZW5kYXRpb25SZXN1bHQuTWV0YWRhdGFF
bnRyeVIIbWV0YWRhdGEaUwoNTWV0YWRhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tleRIsCgV2
YWx1ZRgCIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZVIFdmFsdWU6AjgBMo0FChVSZWNv
bW1lbmRhdGlvblNlcnZpY2USoQMKCVJlY29tbWVuZBIxLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuUmVjb21tZW5kUmVxdWVzdBoyLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuUmVjb21tZW5kUmVzcG9uc2UirAKC0+STAqUCIlMvdjEve3NlcnZpbmdfY29u
ZmlnPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qL3NlcnZpbmdDb25maWdz
Lyp9OnJlY29tbWVuZDoBKlpmImEvdjEve3NlcnZpbmdfY29uZmlnPXByb2plY3RzLyovbG9j
YXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovc2VydmluZ0NvbmZpZ3MvKn06
cmVjb21tZW5kOgEqWmMiXi92MS97c2VydmluZ19jb25maWc9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9jb2xsZWN0aW9ucy8qL2VuZ2luZXMvKi9zZXJ2aW5nQ29uZmlncy8qfTpyZWNvbW1l
bmQ6ASoazwHKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29n
bGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVC
jQIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxQhpSZWNvbW1lbmRhdGlv
blNlcnZpY2VQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9h
cGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVO
R0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRc
RGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpW
MUrKRAoHEgUOAOcBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgME
EgMWADgKCQoCAwUSAxcAOgoJCgIDBhIDGAAmCggKAQgSAxoAPAoJCgIIJRIDGgA8CggKAQgS
AxsAZAoJCgIICxIDGwBkCggKAQgSAxwAIgoJCgIIChIDHAAiCggKAQgSAx0AOwoJCgIICBID
HQA7CggKAQgSAx4APAoJCgIIARIDHgA8CggKAQgSAx8ALQoJCgIIJBIDHwAtCggKAQgSAyAA
PAoJCgIIKRIDIAA8CggKAQgSAyEAOwoJCgIILRIDIQA7CjEKAgYAEgQkADoBGiUgU2Vydmlj
ZSBmb3IgbWFraW5nIHJlY29tbWVuZGF0aW9ucy4KCgoKAwYAARIDJAgdCgoKAwYAAxIDJQJG
CgwKBQYAA5kIEgMlAkYKCwoDBgADEgQmAilKCg0KBQYAA5oIEgQmAilKCk8KBAYAAgASBCwC
OQMaQSBNYWtlcyBhIHJlY29tbWVuZGF0aW9uLCB3aGljaCByZXF1aXJlcyBhIGNvbnRleHR1
YWwgdXNlciBldmVudC4KCgwKBQYAAgABEgMsBg8KDAoFBgACAAISAywQIAoMCgUGAAIAAxID
LCs8Cg0KBQYAAgAEEgQtBDgGChEKCQYAAgAEsMq8IhIELQQ4Bgo0CgIEABIFPQC9AQEaJyBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIFJlY29tbWVuZCBtZXRob2QuCgoKCgMEAAESAz0IGArYBQoE
BAACABIESwJQBBrJBSBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mIGEKIFtTZXJ2
aW5nQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlNlcnZpbmdDb25m
aWddOgogYHByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9jb2xsZWN0aW9ucy8qL2VuZ2lu
ZXMvKi9zZXJ2aW5nQ29uZmlncy8qYCwgb3IKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9i
YWwvY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovc2VydmluZ0NvbmZpZ3MvKmAKCiBPbmUg
ZGVmYXVsdCBzZXJ2aW5nIGNvbmZpZyBpcyBjcmVhdGVkIGFsb25nIHdpdGggeW91ciByZWNv
bW1lbmRhdGlvbiBlbmdpbmUKIGNyZWF0aW9uLiBUaGUgZW5naW5lIElEIGlzIHVzZWQgYXMg
dGhlIElEIG9mIHRoZSBkZWZhdWx0IHNlcnZpbmcKIGNvbmZpZy4gRm9yIGV4YW1wbGUsIGZv
ciBFbmdpbmUKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMvKi9l
bmdpbmVzL215LWVuZ2luZWAsIHlvdSBjYW4gdXNlCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMv
Z2xvYmFsL2NvbGxlY3Rpb25zLyovZW5naW5lcy9teS1lbmdpbmUvc2VydmluZ0NvbmZpZ3Mv
bXktZW5naW5lYAogZm9yIHlvdXIKIFtSZWNvbW1lbmRhdGlvblNlcnZpY2UuUmVjb21tZW5k
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJlY29tbWVuZGF0aW9uU2Vydmlj
ZS5SZWNvbW1lbmRdCiByZXF1ZXN0cy4KCgwKBQQAAgAFEgNLAggKDAoFBAACAAESA0sJFwoM
CgUEAAIAAxIDSxobCg0KBQQAAgAIEgRLHFADCg8KCAQAAgAInAgAEgNMBCoKDwoHBAACAAif
CBIETQRPBQrWBgoEBAACARIDYgJEGsgGIFJlcXVpcmVkLiBDb250ZXh0IGFib3V0IHRoZSB1
c2VyLCB3aGF0IHRoZXkgYXJlIGxvb2tpbmcgYXQgYW5kIHdoYXQgYWN0aW9uCiB0aGV5IHRv
b2sgdG8gdHJpZ2dlciB0aGUgUmVjb21tZW5kIHJlcXVlc3QuIE5vdGUgdGhhdCB0aGlzIHVz
ZXIgZXZlbnQKIGRldGFpbCB3b24ndCBiZSBpbmdlc3RlZCB0byB1c2VyRXZlbnQgbG9ncy4g
VGh1cywgYSBzZXBhcmF0ZSB1c2VyRXZlbnQKIHdyaXRlIHJlcXVlc3QgaXMgcmVxdWlyZWQg
Zm9yIGV2ZW50IGxvZ2dpbmcuCgogRG9uJ3Qgc2V0CiBbVXNlckV2ZW50LnVzZXJfcHNldWRv
X2lkXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlVzZXJFdmVudC51c2VyX3Bz
ZXVkb19pZF0KIG9yCiBbVXNlckV2ZW50LnVzZXJfaW5mby51c2VyX2lkXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLlVzZXJJbmZvLnVzZXJfaWRdCiB0byB0aGUgc2FtZSBm
aXhlZCBJRCBmb3IgZGlmZmVyZW50IHVzZXJzLiBJZiB5b3UgYXJlIHRyeWluZyB0byByZWNl
aXZlCiBub24tcGVyc29uYWxpemVkIHJlY29tbWVuZGF0aW9ucyAobm90IHJlY29tbWVuZGVk
OyB0aGlzIGNhbiBuZWdhdGl2ZWx5CiBpbXBhY3QgbW9kZWwgcGVyZm9ybWFuY2UpLCBpbnN0
ZWFkIHNldAogW1VzZXJFdmVudC51c2VyX3BzZXVkb19pZF1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MS5Vc2VyRXZlbnQudXNlcl9wc2V1ZG9faWRdCiB0byBhIHJhbmRvbSB1
bmlxdWUgSUQgYW5kIGxlYXZlCiBbVXNlckV2ZW50LnVzZXJfaW5mby51c2VyX2lkXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlVzZXJJbmZvLnVzZXJfaWRdCiB1bnNldC4K
CgwKBQQAAgEGEgNiAgsKDAoFBAACAQESA2IMFgoMCgUEAAIBAxIDYhkaCgwKBQQAAgEIEgNi
G0MKDwoIBAACAQicCAASA2IcQgrvAQoEBAACAhIDaAIWGuEBIE1heGltdW0gbnVtYmVyIG9m
IHJlc3VsdHMgdG8gcmV0dXJuLiBTZXQgdGhpcyBwcm9wZXJ0eQogdG8gdGhlIG51bWJlciBv
ZiByZWNvbW1lbmRhdGlvbiByZXN1bHRzIG5lZWRlZC4gSWYgemVybywgdGhlIHNlcnZpY2UK
IGNob29zZXMgYSByZWFzb25hYmxlIGRlZmF1bHQuIFRoZSBtYXhpbXVtIGFsbG93ZWQgdmFs
dWUgaXMgMTAwLiBWYWx1ZXMKIGFib3ZlIDEwMCBhcmUgc2V0IHRvIDEwMC4KCgwKBQQAAgIF
EgNoAgcKDAoFBAACAgESA2gIEQoMCgUEAAICAxIDaBQVCoYJCgQEAAIDEgSFAQIUGvcIIEZp
bHRlciBmb3IgcmVzdHJpY3RpbmcgcmVjb21tZW5kYXRpb24gcmVzdWx0cyB3aXRoIGEgbGVu
Z3RoIGxpbWl0IG9mIDUsMDAwCiBjaGFyYWN0ZXJzLiBDdXJyZW50bHksIG9ubHkgZmlsdGVy
IGV4cHJlc3Npb25zIG9uIHRoZSBgZmlsdGVyX3RhZ3NgCiBhdHRyaWJ1dGUgaXMgc3VwcG9y
dGVkLgoKCiBFeGFtcGxlczoKCiAgKiBgKGZpbHRlcl90YWdzOiBBTlkoIlJlZCIsICJCbHVl
IikgT1IgZmlsdGVyX3RhZ3M6IEFOWSgiSG90IiwgIkNvbGQiKSlgCiAgKiBgKGZpbHRlcl90
YWdzOiBBTlkoIlJlZCIsICJCbHVlIikpIEFORCBOT1QgKGZpbHRlcl90YWdzOiBBTlkoIkdy
ZWVuIikpYAoKIElmIGBhdHRyaWJ1dGVGaWx0ZXJpbmdTeW50YXhgIGlzIHNldCB0byB0cnVl
IHVuZGVyIHRoZSBgcGFyYW1zYCBmaWVsZCwgdGhlbgogYXR0cmlidXRlLWJhc2VkIGV4cHJl
c3Npb25zIGFyZSBleHBlY3RlZCBpbnN0ZWFkIG9mIHRoZSBhYm92ZSBkZXNjcmliZWQKIHRh
Zy1iYXNlZCBzeW50YXguIEV4YW1wbGVzOgoKICAqIChsYW5ndWFnZTogQU5ZKCJlbiIsICJl
cyIpKSBBTkQgTk9UIChjYXRlZ29yaWVzOiBBTlkoIk1vdmllIikpCiAgKiAoYXZhaWxhYmxl
OiB0cnVlKSBBTkQKICAgIChsYW5ndWFnZTogQU5ZKCJlbiIsICJlcyIpKSBPUiAoY2F0ZWdv
cmllczogQU5ZKCJNb3ZpZSIpKQoKIElmIHlvdXIgZmlsdGVyIGJsb2NrcyBhbGwgcmVzdWx0
cywgdGhlIEFQSSByZXR1cm5zIGdlbmVyaWMKICh1bmZpbHRlcmVkKSBwb3B1bGFyIERvY3Vt
ZW50cy4gSWYgeW91IG9ubHkgd2FudCByZXN1bHRzIHN0cmljdGx5IG1hdGNoaW5nCiB0aGUg
ZmlsdGVycywgc2V0IGBzdHJpY3RGaWx0ZXJpbmdgIHRvIGB0cnVlYCBpbgogW1JlY29tbWVu
ZFJlcXVlc3QucGFyYW1zXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJlY29t
bWVuZFJlcXVlc3QucGFyYW1zXQogdG8gcmVjZWl2ZSBlbXB0eSByZXN1bHRzIGluc3RlYWQu
CgogTm90ZSB0aGF0IHRoZSBBUEkgbmV2ZXIgcmV0dXJucwogW0RvY3VtZW50XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRvY3VtZW50XXMgd2l0aCBgc3RvcmFnZVN0YXR1
c2AKIGFzIGBFWFBJUkVEYCBvciBgREVMRVRFRGAgcmVnYXJkbGVzcyBvZiBmaWx0ZXIgY2hv
aWNlcy4KCg0KBQQAAgMFEgSFAQIICg0KBQQAAgMBEgSFAQkPCg0KBQQAAgMDEgSFARITCv0B
CgQEAAIEEgSLAQIZGu4BIFVzZSB2YWxpZGF0ZSBvbmx5IG1vZGUgZm9yIHRoaXMgcmVjb21t
ZW5kYXRpb24gcXVlcnkuIElmIHNldCB0byBgdHJ1ZWAsIGEKIGZha2UgbW9kZWwgaXMgdXNl
ZCB0aGF0IHJldHVybnMgYXJiaXRyYXJ5IERvY3VtZW50IElEcy4KIE5vdGUgdGhhdCB0aGUg
dmFsaWRhdGUgb25seSBtb2RlIHNob3VsZCBvbmx5IGJlIHVzZWQgZm9yIHRlc3RpbmcgdGhl
IEFQSSwKIG9yIGlmIHRoZSBtb2RlbCBpcyBub3QgcmVhZHkuCgoNCgUEAAIEBRIEiwECBgoN
CgUEAAIEARIEiwEHFAoNCgUEAAIEAxIEiwEXGArzCgoEBAACBRIEqQECMBrkCiBBZGRpdGlv
bmFsIGRvbWFpbiBzcGVjaWZpYyBwYXJhbWV0ZXJzIGZvciB0aGUgcmVjb21tZW5kYXRpb25z
LgoKIEFsbG93ZWQgdmFsdWVzOgoKICogYHJldHVybkRvY3VtZW50YDogQm9vbGVhbi4gSWYg
c2V0IHRvIGB0cnVlYCwgdGhlIGFzc29jaWF0ZWQgRG9jdW1lbnQKICAgIG9iamVjdCBpcyBy
ZXR1cm5lZCBpbgogICAgW1JlY29tbWVuZFJlc3BvbnNlLlJlY29tbWVuZGF0aW9uUmVzdWx0
LmRvY3VtZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJlY29tbWVuZFJl
c3BvbnNlLlJlY29tbWVuZGF0aW9uUmVzdWx0LmRvY3VtZW50XS4KICogYHJldHVyblNjb3Jl
YDogQm9vbGVhbi4gSWYgc2V0IHRvIHRydWUsIHRoZSByZWNvbW1lbmRhdGlvbiBzY29yZQog
ICAgY29ycmVzcG9uZGluZyB0byBlYWNoIHJldHVybmVkIERvY3VtZW50IGlzIHNldCBpbgog
ICAgW1JlY29tbWVuZFJlc3BvbnNlLlJlY29tbWVuZGF0aW9uUmVzdWx0Lm1ldGFkYXRhXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJlY29tbWVuZFJlc3BvbnNlLlJlY29t
bWVuZGF0aW9uUmVzdWx0Lm1ldGFkYXRhXS4KICAgIFRoZSBnaXZlbiBzY29yZSBpbmRpY2F0
ZXMgdGhlIHByb2JhYmlsaXR5IG9mIGEgRG9jdW1lbnQgY29udmVyc2lvbiBnaXZlbgogICAg
dGhlIHVzZXIncyBjb250ZXh0IGFuZCBoaXN0b3J5LgogKiBgc3RyaWN0RmlsdGVyaW5nYDog
Qm9vbGVhbi4gVHJ1ZSBieSBkZWZhdWx0LiBJZiBzZXQgdG8gYGZhbHNlYCwgdGhlCiBzZXJ2
aWNlCiAgICByZXR1cm5zIGdlbmVyaWMgKHVuZmlsdGVyZWQpIHBvcHVsYXIgRG9jdW1lbnRz
IGluc3RlYWQgb2YgZW1wdHkgaWYKICAgIHlvdXIgZmlsdGVyIGJsb2NrcyBhbGwgcmVjb21t
ZW5kYXRpb24gcmVzdWx0cy4KICogYGRpdmVyc2l0eUxldmVsYDogU3RyaW5nLiBEZWZhdWx0
IGVtcHR5LiBJZiBzZXQgdG8gYmUgbm9uLWVtcHR5LCB0aGVuCiAgICBpdCBuZWVkcyB0byBi
ZSBvbmUgb2Y6CiAgICAgKiAgYG5vLWRpdmVyc2l0eWAKICAgICAqICBgbG93LWRpdmVyc2l0
eWAKICAgICAqICBgbWVkaXVtLWRpdmVyc2l0eWAKICAgICAqICBgaGlnaC1kaXZlcnNpdHlg
CiAgICAgKiAgYGF1dG8tZGl2ZXJzaXR5YAogICAgVGhpcyBnaXZlcyByZXF1ZXN0LWxldmVs
IGNvbnRyb2wgYW5kIGFkanVzdHMgcmVjb21tZW5kYXRpb24gcmVzdWx0cwogICAgYmFzZWQg
b24gRG9jdW1lbnQgY2F0ZWdvcnkuCiAqIGBhdHRyaWJ1dGVGaWx0ZXJpbmdTeW50YXhgOiBC
b29sZWFuLiBGYWxzZSBieSBkZWZhdWx0LiBJZiBzZXQgdG8gdHJ1ZSwKICAgIHRoZSBgZmls
dGVyYCBmaWVsZCBpcyBpbnRlcnByZXRlZCBhY2NvcmRpbmcgdG8gdGhlIG5ldywKICAgIGF0
dHJpYnV0ZS1iYXNlZCBzeW50YXguCgoNCgUEAAIFBhIEqQECJAoNCgUEAAIFARIEqQElKwoN
CgUEAAIFAxIEqQEuLwruBgoEBAACBhIEvAECJhrfBiBUaGUgdXNlciBsYWJlbHMgYXBwbGll
ZCB0byBhIHJlc291cmNlIG11c3QgbWVldCB0aGUgZm9sbG93aW5nIHJlcXVpcmVtZW50czoK
CiAqIEVhY2ggcmVzb3VyY2UgY2FuIGhhdmUgbXVsdGlwbGUgbGFiZWxzLCB1cCB0byBhIG1h
eGltdW0gb2YgNjQuCiAqIEVhY2ggbGFiZWwgbXVzdCBiZSBhIGtleS12YWx1ZSBwYWlyLgog
KiBLZXlzIGhhdmUgYSBtaW5pbXVtIGxlbmd0aCBvZiAxIGNoYXJhY3RlciBhbmQgYSBtYXhp
bXVtIGxlbmd0aCBvZiA2MwogICBjaGFyYWN0ZXJzIGFuZCBjYW5ub3QgYmUgZW1wdHkuIFZh
bHVlcyBjYW4gYmUgZW1wdHkgYW5kIGhhdmUgYSBtYXhpbXVtCiAgIGxlbmd0aCBvZiA2MyBj
aGFyYWN0ZXJzLgogKiBLZXlzIGFuZCB2YWx1ZXMgY2FuIGNvbnRhaW4gb25seSBsb3dlcmNh
c2UgbGV0dGVycywgbnVtZXJpYyBjaGFyYWN0ZXJzLAogICB1bmRlcnNjb3JlcywgYW5kIGRh
c2hlcy4gQWxsIGNoYXJhY3RlcnMgbXVzdCB1c2UgVVRGLTggZW5jb2RpbmcsIGFuZAogICBp
bnRlcm5hdGlvbmFsIGNoYXJhY3RlcnMgYXJlIGFsbG93ZWQuCiAqIFRoZSBrZXkgcG9ydGlv
biBvZiBhIGxhYmVsIG11c3QgYmUgdW5pcXVlLiBIb3dldmVyLCB5b3UgY2FuIHVzZSB0aGUg
c2FtZQogICBrZXkgd2l0aCBtdWx0aXBsZSByZXNvdXJjZXMuCiAqIEtleXMgbXVzdCBzdGFy
dCB3aXRoIGEgbG93ZXJjYXNlIGxldHRlciBvciBpbnRlcm5hdGlvbmFsIGNoYXJhY3Rlci4K
CiBTZWUgW1JlcXVpcmVtZW50cyBmb3IKIGxhYmVsc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL3Jlc291cmNlLW1hbmFnZXIvZG9jcy9jcmVhdGluZy1tYW5hZ2luZy1sYWJlbHMjcmVx
dWlyZW1lbnRzKQogZm9yIG1vcmUgZGV0YWlscy4KCg0KBQQAAgYGEgS8AQIVCg0KBQQAAgYB
EgS8ARYhCg0KBQQAAgYDEgS8ASQlCjYKAgQBEgbAAQDnAQEaKCBSZXNwb25zZSBtZXNzYWdl
IGZvciBSZWNvbW1lbmQgbWV0aG9kLgoKCwoDBAEBEgTAAQgZCmwKBAQBAwASBsMBAtMBAxpc
IFJlY29tbWVuZGF0aW9uUmVzdWx0IHJlcHJlc2VudHMgYSBnZW5lcmljIHJlY29tbWVuZGF0
aW9uIHJlc3VsdCB3aXRoCiBhc3NvY2lhdGVkIG1ldGFkYXRhLgoKDQoFBAEDAAESBMMBCh4K
OgoGBAEDAAIAEgTFAQQSGiogUmVzb3VyY2UgSUQgb2YgdGhlIHJlY29tbWVuZGVkIERvY3Vt
ZW50LgoKDwoHBAEDAAIABRIExQEECgoPCgcEAQMAAgABEgTFAQsNCg8KBwQBAwACAAMSBMUB
EBEKkQEKBgQBAwACARIEyQEEGhqAASBTZXQgaWYgYHJldHVybkRvY3VtZW50YCBpcyBzZXQg
dG8gdHJ1ZSBpbgogW1JlY29tbWVuZFJlcXVlc3QucGFyYW1zXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLlJlY29tbWVuZFJlcXVlc3QucGFyYW1zXS4KCg8KBwQBAwACAQYS
BMkBBAwKDwoHBAEDAAIBARIEyQENFQoPCgcEAQMAAgEDEgTJARgZCokCCgYEAQMAAgISBNIB
BDQa+AEgQWRkaXRpb25hbCBEb2N1bWVudCBtZXRhZGF0YSBvciBhbm5vdGF0aW9ucy4KCiBQ
b3NzaWJsZSB2YWx1ZXM6CgogKiBgc2NvcmVgOiBSZWNvbW1lbmRhdGlvbiBzY29yZSBpbiBk
b3VibGUgdmFsdWUuIElzIHNldCBpZgogICBgcmV0dXJuU2NvcmVgIGlzIHNldCB0byB0cnVl
IGluCiAgIFtSZWNvbW1lbmRSZXF1ZXN0LnBhcmFtc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5SZWNvbW1lbmRSZXF1ZXN0LnBhcmFtc10uCgoPCgcEAQMAAgIGEgTSAQQm
Cg8KBwQBAwACAgESBNIBJy8KDwoHBAEDAAICAxIE0gEyMwqCAQoEBAECABIE1wECLBp0IEEg
bGlzdCBvZiByZWNvbW1lbmRlZCBEb2N1bWVudHMuIFRoZSBvcmRlciByZXByZXNlbnRzIHRo
ZSByYW5raW5nIChmcm9tIHRoZQogbW9zdCByZWxldmFudCBEb2N1bWVudCB0byB0aGUgbGVh
c3QpLgoKDQoFBAECAAQSBNcBAgoKDQoFBAECAAYSBNcBCx8KDQoFBAECAAESBNcBICcKDQoF
BAECAAMSBNcBKisK9gEKBAQBAgESBN0BAh8a5wEgQSB1bmlxdWUgYXR0cmlidXRpb24gdG9r
ZW4uIFRoaXMgc2hvdWxkIGJlIGluY2x1ZGVkIGluIHRoZQogW1VzZXJFdmVudF1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyRXZlbnRdIGxvZ3MgcmVzdWx0aW5nIGZy
b20KIHRoaXMgcmVjb21tZW5kYXRpb24sIHdoaWNoIGVuYWJsZXMgYWNjdXJhdGUgYXR0cmli
dXRpb24gb2YgcmVjb21tZW5kYXRpb24KIG1vZGVsIHBlcmZvcm1hbmNlLgoKDQoFBAECAQUS
BN0BAggKDQoFBAECAQESBN0BCRoKDQoFBAECAQMSBN0BHR4KhwEKBAQBAgISBOEBAiIaeSBJ
RHMgb2YgZG9jdW1lbnRzIGluIHRoZSByZXF1ZXN0IHRoYXQgd2VyZSBtaXNzaW5nIGZyb20g
dGhlIGRlZmF1bHQgQnJhbmNoCiBhc3NvY2lhdGVkIHdpdGggdGhlIHJlcXVlc3RlZCBTZXJ2
aW5nQ29uZmlnLgoKDQoFBAECAgQSBOEBAgoKDQoFBAECAgUSBOEBCxEKDQoFBAECAgESBOEB
Eh0KDQoFBAECAgMSBOEBICEKgwEKBAQBAgMSBOYBAhkadSBUcnVlIGlmCiBbUmVjb21tZW5k
UmVxdWVzdC52YWxpZGF0ZV9vbmx5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
LlJlY29tbWVuZFJlcXVlc3QudmFsaWRhdGVfb25seV0KIHdhcyBzZXQuCgoNCgUEAQIDBRIE
5gECBgoNCgUEAQIDARIE5gEHFAoNCgUEAQIDAxIE5gEXGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest ===
    # Fields for RecommendRequest
    # Field: serving_config Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.discoveryengine.v1.UserEvent)
    # Field: page_size Type: 5 ()
    # Field: filter Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: params Type: 11 (.google.cloud.discoveryengine.v1.RecommendRequest.ParamsEntry)
    # Field: user_labels Type: 11 (.google.cloud.discoveryengine.v1.RecommendRequest.UserLabelsEntry)

# === Message: Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse ===
    # Fields for RecommendResponse
    # Field: results Type: 11 (.google.cloud.discoveryengine.v1.RecommendResponse.RecommendationResult)
    # Field: attribution_token Type: 9 ()
    # Field: missing_ids Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Service Client: Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendationServiceClient ===
package Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendationServiceClient

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
        ? Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.RecommendationService',
        method         => 'Recommend',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::RecommendationService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/recommendation_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::RecommendationService;

    my $msg = Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest->new({
        serving_config => $serving_config,
        user_event => $user_event,
        page_size => $page_size,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->serving_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/recommendation_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest

Request message for Recommend method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. Full resource name of a
[ServingConfig][google.cloud.discoveryengine.v1.ServingConfig]:
`projects/*/locations/global/collections/*/engines/*/servingConfigs/*`, or
`projects/*/locations/global/collections/*/dataStores/*/servingConfigs/*`

One default serving config is created along with your recommendation engine
creation. The engine ID is used as the ID of the default serving
config. For example, for Engine
`projects/*/locations/global/collections/*/engines/my-engine`, you can use
`projects/*/locations/global/collections/*/engines/my-engine/servingConfigs/my-engine`
for your
[RecommendationService.Recommend][google.cloud.discoveryengine.v1.RecommendationService.Recommend]
requests.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent>)

Required. Context about the user, what they are looking at and what action
they took to trigger the Recommend request. Note that this user event
detail won't be ingested to userEvent logs. Thus, a separate userEvent
write request is required for event logging.

Don't set
[UserEvent.user_pseudo_id][google.cloud.discoveryengine.v1.UserEvent.user_pseudo_id]
or
[UserEvent.user_info.user_id][google.cloud.discoveryengine.v1.UserInfo.user_id]
to the same fixed ID for different users. If you are trying to receive
non-personalized recommendations (not recommended; this can negatively
impact model performance), instead set
[UserEvent.user_pseudo_id][google.cloud.discoveryengine.v1.UserEvent.user_pseudo_id]
to a random unique ID and leave
[UserEvent.user_info.user_id][google.cloud.discoveryengine.v1.UserInfo.user_id]
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
[RecommendRequest.params][google.cloud.discoveryengine.v1.RecommendRequest.params]
to receive empty results instead.

Note that the API never returns
[Document][google.cloud.discoveryengine.v1.Document]s with `storageStatus`
as `EXPIRED` or `DELETED` regardless of filter choices.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Use validate only mode for this recommendation query. If set to `true`, a
fake model is used that returns arbitrary Document IDs.
Note that the validate only mode should only be used for testing the API,
or if the model is not ready.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest::ParamsEntry>)

Additional domain specific parameters for the recommendations.

Allowed values:

* `returnDocument`: Boolean. If set to `true`, the associated Document
   object is returned in
   [RecommendResponse.RecommendationResult.document][google.cloud.discoveryengine.v1.RecommendResponse.RecommendationResult.document].
* `returnScore`: Boolean. If set to true, the recommendation score
   corresponding to each returned Document is set in
   [RecommendResponse.RecommendationResult.metadata][google.cloud.discoveryengine.v1.RecommendResponse.RecommendationResult.metadata].
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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest::UserLabelsEntry>)

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

=head2 Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse

Response message for Recommend method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->results() >> / C<< $msg->results($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse::RecommendationResult>)

A list of recommended Documents. The order represents the ranking (from the
most relevant Document to the least).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique attribution token. This should be included in the
[UserEvent][google.cloud.discoveryengine.v1.UserEvent] logs resulting from
this recommendation, which enables accurate attribution of recommendation
model performance.

=item * C<< $msg->missing_ids() >> / C<< $msg->missing_ids($value) >>

Type: C<String>

IDs of documents in the request that were missing from the default Branch
associated with the requested ServingConfig.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

True if
[RecommendRequest.validate_only][google.cloud.discoveryengine.v1.RecommendRequest.validate_only]
was set.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::RecommendationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
