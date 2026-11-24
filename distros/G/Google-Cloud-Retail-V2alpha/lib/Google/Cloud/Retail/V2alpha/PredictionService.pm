package Google::Cloud::Retail::V2alpha::PredictionService;

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
    eval { require Google::Cloud::Retail::V2alpha::UserEvent };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvcHJlZGljdGlvbl9zZXJ2aWNlLnByb3Rv
Ehtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMu
cHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGixnb29nbGUvY2xvdWQvcmV0
YWlsL3YyYWxwaGEvdXNlcl9ldmVudC5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5w
cm90byKsBAoOUHJlZGljdFJlcXVlc3QSIQoJcGxhY2VtZW50GAEgASgJQgPgQQJSCXBsYWNl
bWVudBJKCgp1c2VyX2V2ZW50GAIgASgLMiYuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhh
LlVzZXJFdmVudEID4EECUgl1c2VyRXZlbnQSGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6
ZRIhCgpwYWdlX3Rva2VuGAQgASgJQgIYAVIJcGFnZVRva2VuEhYKBmZpbHRlchgFIAEoCVIG
ZmlsdGVyEiMKDXZhbGlkYXRlX29ubHkYBiABKAhSDHZhbGlkYXRlT25seRJPCgZwYXJhbXMY
ByADKAsyNy5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuUHJlZGljdFJlcXVlc3QuUGFy
YW1zRW50cnlSBnBhcmFtcxJPCgZsYWJlbHMYCCADKAsyNy5nb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuUHJlZGljdFJlcXVlc3QuTGFiZWxzRW50cnlSBmxhYmVscxpRCgtQYXJhbXNF
bnRyeRIQCgNrZXkYASABKAlSA2tleRIsCgV2YWx1ZRgCIAEoCzIWLmdvb2dsZS5wcm90b2J1
Zi5WYWx1ZVIFdmFsdWU6AjgBGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK
BXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiwAMKD1ByZWRpY3RSZXNwb25zZRJXCgdyZXN1bHRz
GAEgAygLMj0uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlByZWRpY3RSZXNwb25zZS5Q
cmVkaWN0aW9uUmVzdWx0UgdyZXN1bHRzEisKEWF0dHJpYnV0aW9uX3Rva2VuGAIgASgJUhBh
dHRyaWJ1dGlvblRva2VuEh8KC21pc3NpbmdfaWRzGAMgAygJUgptaXNzaW5nSWRzEiMKDXZh
bGlkYXRlX29ubHkYBCABKAhSDHZhbGlkYXRlT25seRrgAQoQUHJlZGljdGlvblJlc3VsdBIO
CgJpZBgBIAEoCVICaWQSZwoIbWV0YWRhdGEYAiADKAsySy5nb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuUHJlZGljdFJlc3BvbnNlLlByZWRpY3Rpb25SZXN1bHQuTWV0YWRhdGFFbnRy
eVIIbWV0YWRhdGEaUwoNTWV0YWRhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tleRIsCgV2YWx1
ZRgCIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZVIFdmFsdWU6AjgBMvUCChFQcmVkaWN0
aW9uU2VydmljZRKUAgoHUHJlZGljdBIrLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Q
cmVkaWN0UmVxdWVzdBosLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5QcmVkaWN0UmVz
cG9uc2UirQGC0+STAqYBIksvdjJhbHBoYS97cGxhY2VtZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyovY2F0YWxvZ3MvKi9wbGFjZW1lbnRzLyp9OnByZWRpY3Q6ASpaVCJPL3YyYWxwaGEv
e3BsYWNlbWVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0Nv
bmZpZ3MvKn06cHJlZGljdDoBKhpJykEVcmV0YWlsLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULaAQofY29tLmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJhbHBoYUIWUHJlZGljdGlvblNlcnZpY2VQcm90b1ABWjdjbG91
ZC5nb29nbGUuY29tL2dvL3JldGFpbC9hcGl2MmFscGhhL3JldGFpbHBiO3JldGFpbHBiogIG
UkVUQUlMqgIbR29vZ2xlLkNsb3VkLlJldGFpbC5WMkFscGhhygIbR29vZ2xlXENsb3VkXFJl
dGFpbFxWMmFscGhh6gIeR29vZ2xlOjpDbG91ZDo6UmV0YWlsOjpWMmFscGhhSuVHCgcSBQ4A
4QEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMA
EgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANgoJCgID
BRIDFwAmCggKAQgSAxkAOAoJCgIIJRIDGQA4CggKAQgSAxoATgoJCgIICxIDGgBOCggKAQgS
AxsAIgoJCgIIChIDGwAiCggKAQgSAxwANwoJCgIICBIDHAA3CggKAQgSAx0AOAoJCgIIARID
HQA4CggKAQgSAx4AJAoJCgIIJBIDHgAkCggKAQgSAx8AOAoJCgIIKRIDHwA4CggKAQgSAyAA
NwoJCgIILRIDIAA3CjsKAgYAEgQjADMBGi8gU2VydmljZSBmb3IgbWFraW5nIHJlY29tbWVu
ZGF0aW9uIHByZWRpY3Rpb24uCgoKCgMGAAESAyMIGQoKCgMGAAMSAyQCPQoMCgUGAAOZCBID
JAI9CgsKAwYAAxIEJQImNwoNCgUGAAOaCBIEJQImNwoyCgQGAAIAEgQpAjIDGiQgTWFrZXMg
YSByZWNvbW1lbmRhdGlvbiBwcmVkaWN0aW9uLgoKDAoFBgACAAESAykGDQoMCgUGAAIAAhID
KQ4cCgwKBQYAAgADEgMpJzYKDQoFBgACAAQSBCoEMQYKEQoJBgACAASwyrwiEgQqBDEGCjIK
AgQAEgU2AL4BARolIFJlcXVlc3QgbWVzc2FnZSBmb3IgUHJlZGljdCBtZXRob2QuCgoKCgME
AAESAzYIFgroBQoEBAACABIDRQJAGtoFIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5hbWUg
b2YgdGhlIGZvcm1hdDoKIGB7cGxhY2VtZW50PXByb2plY3RzLyovbG9jYXRpb25zL2dsb2Jh
bC9jYXRhbG9ncy9kZWZhdWx0X2NhdGFsb2cvc2VydmluZ0NvbmZpZ3MvKn1gCiBvcgogYHtw
bGFjZW1lbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2NhdGFsb2dzL2RlZmF1bHRf
Y2F0YWxvZy9wbGFjZW1lbnRzLyp9YC4KIFdlIHJlY29tbWVuZCB1c2luZyB0aGUgYHNlcnZp
bmdDb25maWdzYCByZXNvdXJjZS4gYHBsYWNlbWVudHNgIGlzIGEgbGVnYWN5CiByZXNvdXJj
ZS4KIFRoZSBJRCBvZiB0aGUgUmVjb21tZW5kYXRpb25zIEFJIHNlcnZpbmcgY29uZmlnIG9y
IHBsYWNlbWVudC4KIEJlZm9yZSB5b3UgY2FuIHJlcXVlc3QgcHJlZGljdGlvbnMgZnJvbSB5
b3VyIG1vZGVsLCB5b3UgbXVzdCBjcmVhdGUgYXQKIGxlYXN0IG9uZSBzZXJ2aW5nIGNvbmZp
ZyBvciBwbGFjZW1lbnQgZm9yIGl0LiBGb3IgbW9yZSBpbmZvcm1hdGlvbiwgc2VlCiBbTWFu
YWdlIHNlcnZpbmcgY29uZmlnc10KIChodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWls
L2RvY3MvbWFuYWdlLWNvbmZpZ3MpLgoKIFRoZSBmdWxsIGxpc3Qgb2YgYXZhaWxhYmxlIHNl
cnZpbmcgY29uZmlncyBjYW4gYmUgc2VlbiBhdAogaHR0cHM6Ly9jb25zb2xlLmNsb3VkLmdv
b2dsZS5jb20vYWkvcmV0YWlsL2NhdGFsb2dzL2RlZmF1bHRfY2F0YWxvZy9jb25maWdzCgoM
CgUEAAIABRIDRQIICgwKBQQAAgABEgNFCRIKDAoFBAACAAMSA0UVFgoMCgUEAAIACBIDRRc/
Cg8KCAQAAgAInAgAEgNFGD4KnAYKBAQAAgESA1UCRBqOBiBSZXF1aXJlZC4gQ29udGV4dCBh
Ym91dCB0aGUgdXNlciwgd2hhdCB0aGV5IGFyZSBsb29raW5nIGF0IGFuZCB3aGF0IGFjdGlv
bgogdGhleSB0b29rIHRvIHRyaWdnZXIgdGhlIHByZWRpY3QgcmVxdWVzdC4gTm90ZSB0aGF0
IHRoaXMgdXNlciBldmVudCBkZXRhaWwKIHdvbid0IGJlIGluZ2VzdGVkIHRvIHVzZXJFdmVu
dCBsb2dzLiBUaHVzLCBhIHNlcGFyYXRlIHVzZXJFdmVudCB3cml0ZQogcmVxdWVzdCBpcyBy
ZXF1aXJlZCBmb3IgZXZlbnQgbG9nZ2luZy4KCiBEb24ndCBzZXQKIFtVc2VyRXZlbnQudmlz
aXRvcl9pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlVzZXJFdmVudC52aXNpdG9y
X2lkXSBvcgogW1VzZXJJbmZvLnVzZXJfaWRdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBo
YS5Vc2VySW5mby51c2VyX2lkXSB0byB0aGUKIHNhbWUgZml4ZWQgSUQgZm9yIGRpZmZlcmVu
dCB1c2Vycy4gSWYgeW91IGFyZSB0cnlpbmcgdG8gcmVjZWl2ZQogbm9uLXBlcnNvbmFsaXpl
ZCByZWNvbW1lbmRhdGlvbnMgKG5vdCByZWNvbW1lbmRlZDsgdGhpcyBjYW4gbmVnYXRpdmVs
eQogaW1wYWN0IG1vZGVsIHBlcmZvcm1hbmNlKSwgaW5zdGVhZCBzZXQKIFtVc2VyRXZlbnQu
dmlzaXRvcl9pZF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlVzZXJFdmVudC52aXNp
dG9yX2lkXSB0bwogYSByYW5kb20gdW5pcXVlIElEIGFuZCBsZWF2ZQogW1VzZXJJbmZvLnVz
ZXJfaWRdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5Vc2VySW5mby51c2VyX2lkXSB1
bnNldC4KCgwKBQQAAgEGEgNVAgsKDAoFBAACAQESA1UMFgoMCgUEAAIBAxIDVRkaCgwKBQQA
AgEIEgNVG0MKDwoIBAACAQicCAASA1UcQgr3AQoEBAACAhIDWwIWGukBIE1heGltdW0gbnVt
YmVyIG9mIHJlc3VsdHMgdG8gcmV0dXJuLiBTZXQgdGhpcyBwcm9wZXJ0eSB0byB0aGUgbnVt
YmVyIG9mCiBwcmVkaWN0aW9uIHJlc3VsdHMgbmVlZGVkLiBJZiB6ZXJvLCB0aGUgc2Vydmlj
ZSB3aWxsIGNob29zZSBhIHJlYXNvbmFibGUKIGRlZmF1bHQuIFRoZSBtYXhpbXVtIGFsbG93
ZWQgdmFsdWUgaXMgMTAwLiBWYWx1ZXMgYWJvdmUgMTAwIHdpbGwgYmUgY29lcmNlZAogdG8g
MTAwLgoKDAoFBAACAgUSA1sCBwoMCgUEAAICARIDWwgRCgwKBQQAAgIDEgNbFBUKNgoEBAAC
AxIDXgIsGikgVGhpcyBmaWVsZCBpcyBub3QgdXNlZDsgbGVhdmUgaXQgdW5zZXQuCgoMCgUE
AAIDBRIDXgIICgwKBQQAAgMBEgNeCRMKDAoFBAACAwMSA14WFwoMCgUEAAIDCBIDXhgrCg0K
BgQAAgMIAxIDXhkqCr8NCgQEAAIEEgSHAQIUGrANIEZpbHRlciBmb3IgcmVzdHJpY3Rpbmcg
cHJlZGljdGlvbiByZXN1bHRzIHdpdGggYSBsZW5ndGggbGltaXQgb2YgNSwwMDAKIGNoYXJh
Y3RlcnMuIEFjY2VwdHMgdmFsdWVzIGZvciB0YWdzIGFuZCB0aGUgYGZpbHRlck91dE9mU3Rv
Y2tJdGVtc2AgZmxhZy4KCiAgKiBUYWcgZXhwcmVzc2lvbnMuIFJlc3RyaWN0cyBwcmVkaWN0
aW9ucyB0byBwcm9kdWN0cyB0aGF0IG1hdGNoIGFsbCBvZiB0aGUKICAgIHNwZWNpZmllZCB0
YWdzLiBCb29sZWFuIG9wZXJhdG9ycyBgT1JgIGFuZCBgTk9UYCBhcmUgc3VwcG9ydGVkIGlm
IHRoZQogICAgZXhwcmVzc2lvbiBpcyBlbmNsb3NlZCBpbiBwYXJlbnRoZXNlcywgYW5kIG11
c3QgYmUgc2VwYXJhdGVkIGZyb20gdGhlCiAgICB0YWcgdmFsdWVzIGJ5IGEgc3BhY2UuIGAt
InRhZ0EiYCBpcyBhbHNvIHN1cHBvcnRlZCBhbmQgaXMgZXF1aXZhbGVudCB0bwogICAgYE5P
VCAidGFnQSJgLiBUYWcgdmFsdWVzIG11c3QgYmUgZG91YmxlIHF1b3RlZCBVVEYtOCBlbmNv
ZGVkIHN0cmluZ3MKICAgIHdpdGggYSBzaXplIGxpbWl0IG9mIDEsMDAwIGNoYXJhY3RlcnMu
CgogICAgTm90ZTogIlJlY2VudGx5IHZpZXdlZCIgbW9kZWxzIGRvbid0IHN1cHBvcnQgdGFn
IGZpbHRlcmluZyBhdCB0aGUKICAgIG1vbWVudC4KCiAgKiBmaWx0ZXJPdXRPZlN0b2NrSXRl
bXMuIFJlc3RyaWN0cyBwcmVkaWN0aW9ucyB0byBwcm9kdWN0cyB0aGF0IGRvIG5vdAogIGhh
dmUgYQogICAgc3RvY2tTdGF0ZSB2YWx1ZSBvZiBPVVRfT0ZfU1RPQ0suCgogRXhhbXBsZXM6
CgogICogdGFnPSgiUmVkIiBPUiAiQmx1ZSIpIHRhZz0iTmV3LUFycml2YWwiIHRhZz0oTk9U
ICJwcm9tb3Rpb25hbCIpCiAgKiBmaWx0ZXJPdXRPZlN0b2NrSXRlbXMgIHRhZz0oLSJwcm9t
b3Rpb25hbCIpCiAgKiBmaWx0ZXJPdXRPZlN0b2NrSXRlbXMKCiBJZiB5b3VyIGZpbHRlciBi
bG9ja3MgYWxsIHByZWRpY3Rpb24gcmVzdWx0cywgdGhlIEFQSSB3aWxsIHJldHVybiAqbm8q
CiByZXN1bHRzLiBJZiBpbnN0ZWFkIHlvdSB3YW50IGVtcHR5IHJlc3VsdCBzZXRzIHRvIHJl
dHVybiBnZW5lcmljCiAodW5maWx0ZXJlZCkgcG9wdWxhciBwcm9kdWN0cywgc2V0IGBzdHJp
Y3RGaWx0ZXJpbmdgIHRvIEZhbHNlIGluCiBgUHJlZGljdFJlcXVlc3QucGFyYW1zYC4gTm90
ZSB0aGF0IHRoZSBBUEkgd2lsbCBuZXZlciByZXR1cm4gaXRlbXMgd2l0aAogc3RvcmFnZVN0
YXR1cyBvZiAiRVhQSVJFRCIgb3IgIkRFTEVURUQiIHJlZ2FyZGxlc3Mgb2YgZmlsdGVyIGNo
b2ljZXMuCgogSWYgYGZpbHRlclN5bnRheFYyYCBpcyBzZXQgdG8gdHJ1ZSB1bmRlciB0aGUg
YHBhcmFtc2AgZmllbGQsIHRoZW4KIGF0dHJpYnV0ZS1iYXNlZCBleHByZXNzaW9ucyBhcmUg
ZXhwZWN0ZWQgaW5zdGVhZCBvZiB0aGUgYWJvdmUgZGVzY3JpYmVkCiB0YWctYmFzZWQgc3lu
dGF4LiBFeGFtcGxlczoKCiAgKiAoY29sb3JzOiBBTlkoIlJlZCIsICJCbHVlIikpIEFORCBO
T1QgKGNhdGVnb3JpZXM6IEFOWSgiUGhvbmVzIikpCiAgKiAoYXZhaWxhYmlsaXR5OiBBTlko
IklOX1NUT0NLIikpIEFORAogICAgKGNvbG9yczogQU5ZKCJSZWQiKSBPUiBjYXRlZ29yaWVz
OiBBTlkoIlBob25lcyIpKQoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKIFtGaWx0ZXIg
cmVjb21tZW5kYXRpb25zXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vcmV0YWlsL2RvY3Mv
ZmlsdGVyLXJlY3MpLgoKDQoFBAACBAUSBIcBAggKDQoFBAACBAESBIcBCQ8KDQoFBAACBAMS
BIcBEhMK+QEKBAQAAgUSBI0BAhka6gEgVXNlIHZhbGlkYXRlIG9ubHkgbW9kZSBmb3IgdGhp
cyBwcmVkaWN0aW9uIHF1ZXJ5LiBJZiBzZXQgdG8gdHJ1ZSwgYQogZHVtbXkgbW9kZWwgd2ls
bCBiZSB1c2VkIHRoYXQgcmV0dXJucyBhcmJpdHJhcnkgcHJvZHVjdHMuCiBOb3RlIHRoYXQg
dGhlIHZhbGlkYXRlIG9ubHkgbW9kZSBzaG91bGQgb25seSBiZSB1c2VkIGZvciB0ZXN0aW5n
IHRoZSBBUEksCiBvciBpZiB0aGUgbW9kZWwgaXMgbm90IHJlYWR5LgoKDQoFBAACBQUSBI0B
AgYKDQoFBAACBQESBI0BBxQKDQoFBAACBQMSBI0BFxgK4AsKBAQAAgYSBKoBAjAa0QsgQWRk
aXRpb25hbCBkb21haW4gc3BlY2lmaWMgcGFyYW1ldGVycyBmb3IgdGhlIHByZWRpY3Rpb25z
LgoKIEFsbG93ZWQgdmFsdWVzOgoKICogYHJldHVyblByb2R1Y3RgOiBCb29sZWFuLiBJZiBz
ZXQgdG8gdHJ1ZSwgdGhlIGFzc29jaWF0ZWQgcHJvZHVjdAogICAgb2JqZWN0IHdpbGwgYmUg
cmV0dXJuZWQgaW4gdGhlIGByZXN1bHRzLm1ldGFkYXRhYCBmaWVsZCBpbiB0aGUKICAgIHBy
ZWRpY3Rpb24gcmVzcG9uc2UuCiAqIGByZXR1cm5TY29yZWA6IEJvb2xlYW4uIElmIHNldCB0
byB0cnVlLCB0aGUgcHJlZGljdGlvbiAnc2NvcmUnCiAgICBjb3JyZXNwb25kaW5nIHRvIGVh
Y2ggcmV0dXJuZWQgcHJvZHVjdCB3aWxsIGJlIHNldCBpbiB0aGUKICAgIGByZXN1bHRzLm1l
dGFkYXRhYCBmaWVsZCBpbiB0aGUgcHJlZGljdGlvbiByZXNwb25zZS4gVGhlIGdpdmVuCiAg
ICAnc2NvcmUnIGluZGljYXRlcyB0aGUgcHJvYmFiaWxpdHkgb2YgYSBwcm9kdWN0IGJlaW5n
IGNsaWNrZWQvcHVyY2hhc2VkCiAgICBnaXZlbiB0aGUgdXNlcidzIGNvbnRleHQgYW5kIGhp
c3RvcnkuCiAqIGBzdHJpY3RGaWx0ZXJpbmdgOiBCb29sZWFuLiBUcnVlIGJ5IGRlZmF1bHQu
IElmIHNldCB0byBmYWxzZSwgdGhlIHNlcnZpY2UKICAgIHdpbGwgcmV0dXJuIGdlbmVyaWMg
KHVuZmlsdGVyZWQpIHBvcHVsYXIgcHJvZHVjdHMgaW5zdGVhZCBvZiBlbXB0eSBpZgogICAg
eW91ciBmaWx0ZXIgYmxvY2tzIGFsbCBwcmVkaWN0aW9uIHJlc3VsdHMuCiAqIGBwcmljZVJl
cmFua0xldmVsYDogU3RyaW5nLiBEZWZhdWx0IGVtcHR5LiBJZiBzZXQgdG8gYmUgbm9uLWVt
cHR5LCB0aGVuCiAgICBpdCBuZWVkcyB0byBiZSBvbmUgb2Ygeyduby1wcmljZS1yZXJhbmtp
bmcnLCAnbG93LXByaWNlLXJlcmFua2luZycsCiAgICAnbWVkaXVtLXByaWNlLXJlcmFua2lu
ZycsICdoaWdoLXByaWNlLXJlcmFua2luZyd9LiBUaGlzIGdpdmVzCiAgICByZXF1ZXN0LWxl
dmVsIGNvbnRyb2wgYW5kIGFkanVzdHMgcHJlZGljdGlvbiByZXN1bHRzIGJhc2VkIG9uIHBy
b2R1Y3QKICAgIHByaWNlLgogKiBgZGl2ZXJzaXR5TGV2ZWxgOiBTdHJpbmcuIERlZmF1bHQg
ZW1wdHkuIElmIHNldCB0byBiZSBub24tZW1wdHksIHRoZW4KICAgIGl0IG5lZWRzIHRvIGJl
IG9uZSBvZiB7J25vLWRpdmVyc2l0eScsICdsb3ctZGl2ZXJzaXR5JywKICAgICdtZWRpdW0t
ZGl2ZXJzaXR5JywgJ2hpZ2gtZGl2ZXJzaXR5JywgJ2F1dG8tZGl2ZXJzaXR5J30uIFRoaXMg
Z2l2ZXMKICAgIHJlcXVlc3QtbGV2ZWwgY29udHJvbCBhbmQgYWRqdXN0cyBwcmVkaWN0aW9u
IHJlc3VsdHMgYmFzZWQgb24gcHJvZHVjdAogICAgY2F0ZWdvcnkuCiAqIGBmaWx0ZXJTeW50
YXhWMmA6IEJvb2xlYW4uIEZhbHNlIGJ5IGRlZmF1bHQuIElmIHNldCB0byB0cnVlLCB0aGUg
YGZpbHRlcmAKICAgZmllbGQgaXMgaW50ZXJwcmV0ZXRlZCBhY2NvcmRpbmcgdG8gdGhlIG5l
dywgYXR0cmlidXRlLWJhc2VkIHN5bnRheC4KCg0KBQQAAgYGEgSqAQIkCg0KBQQAAgYBEgSq
ASUrCg0KBQQAAgYDEgSqAS4vCucGCgQEAAIHEgS9AQIhGtgGIFRoZSBsYWJlbHMgYXBwbGll
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
CiBTZWUgW0dvb2dsZSBDbG91ZAogRG9jdW1lbnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvY3JlYXRpbmctbWFuYWdpbmctbGFiZWxzI3JlcXVp
cmVtZW50cykKIGZvciBtb3JlIGRldGFpbHMuCgoNCgUEAAIHBhIEvQECFQoNCgUEAAIHARIE
vQEWHAoNCgUEAAIHAxIEvQEfIAo0CgIEARIGwQEA4QEBGiYgUmVzcG9uc2UgbWVzc2FnZSBm
b3IgcHJlZGljdCBtZXRob2QuCgoLCgMEAQESBMEBCBcKVAoEBAEDABIGwwEC0AEDGkQgUHJl
ZGljdGlvblJlc3VsdCByZXByZXNlbnRzIHRoZSByZWNvbW1lbmRhdGlvbiBwcmVkaWN0aW9u
IHJlc3VsdHMuCgoNCgUEAQMAARIEwwEKGgovCgYEAQMAAgASBMUBBBIaHyBJRCBvZiB0aGUg
cmVjb21tZW5kZWQgcHJvZHVjdAoKDwoHBAEDAAIABRIExQEECgoPCgcEAQMAAgABEgTFAQsN
Cg8KBwQBAwACAAMSBMUBEBEKvwIKBgQBAwACARIEzwEENBquAiBBZGRpdGlvbmFsIHByb2R1
Y3QgbWV0YWRhdGEgLyBhbm5vdGF0aW9ucy4KCiBQb3NzaWJsZSB2YWx1ZXM6CgogKiBgcHJv
ZHVjdGA6IEpTT04gcmVwcmVzZW50YXRpb24gb2YgdGhlIHByb2R1Y3QuIElzIHNldCBpZgog
ICBgcmV0dXJuUHJvZHVjdGAgaXMgc2V0IHRvIHRydWUgaW4gYFByZWRpY3RSZXF1ZXN0LnBh
cmFtc2AuCiAqIGBzY29yZWA6IFByZWRpY3Rpb24gc2NvcmUgaW4gZG91YmxlIHZhbHVlLiBJ
cyBzZXQgaWYKICAgYHJldHVyblNjb3JlYCBpcyBzZXQgdG8gdHJ1ZSBpbiBgUHJlZGljdFJl
cXVlc3QucGFyYW1zYC4KCg8KBwQBAwACAQYSBM8BBCYKDwoHBAEDAAIBARIEzwEnLwoPCgcE
AQMAAgEDEgTPATIzCoABCgQEAQIAEgTUAQIoGnIgQSBsaXN0IG9mIHJlY29tbWVuZGVkIHBy
b2R1Y3RzLiBUaGUgb3JkZXIgcmVwcmVzZW50cyB0aGUgcmFua2luZyAoZnJvbSB0aGUKIG1v
c3QgcmVsZXZhbnQgcHJvZHVjdCB0byB0aGUgbGVhc3QpLgoKDQoFBAECAAQSBNQBAgoKDQoF
BAECAAYSBNQBCxsKDQoFBAECAAESBNQBHCMKDQoFBAECAAMSBNQBJicK8gEKBAQBAgESBNoB
Ah8a4wEgQSB1bmlxdWUgYXR0cmlidXRpb24gdG9rZW4uIFRoaXMgc2hvdWxkIGJlIGluY2x1
ZGVkIGluIHRoZQogW1VzZXJFdmVudF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlVz
ZXJFdmVudF0gbG9ncyByZXN1bHRpbmcgZnJvbSB0aGlzCiByZWNvbW1lbmRhdGlvbiwgd2hp
Y2ggZW5hYmxlcyBhY2N1cmF0ZSBhdHRyaWJ1dGlvbiBvZiByZWNvbW1lbmRhdGlvbiBtb2Rl
bAogcGVyZm9ybWFuY2UuCgoNCgUEAQIBBRIE2gECCAoNCgUEAQIBARIE2gEJGgoNCgUEAQIB
AxIE2gEdHgpUCgQEAQICEgTdAQIiGkYgSURzIG9mIHByb2R1Y3RzIGluIHRoZSByZXF1ZXN0
IHRoYXQgd2VyZSBtaXNzaW5nIGZyb20gdGhlIGludmVudG9yeS4KCg0KBQQBAgIEEgTdAQIK
Cg0KBQQBAgIFEgTdAQsRCg0KBQQBAgIBEgTdARIdCg0KBQQBAgIDEgTdASAhCkkKBAQBAgMS
BOABAhkaOyBUcnVlIGlmIHRoZSB2YWxpZGF0ZU9ubHkgcHJvcGVydHkgd2FzIHNldCBpbiB0
aGUgcmVxdWVzdC4KCg0KBQQBAgMFEgTgAQIGCg0KBQQBAgMBEgTgAQcUCg0KBQQBAgMDEgTg
ARcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest ===
    # Fields for PredictRequest
    # Field: placement Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.retail.v2alpha.UserEvent)
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: validate_only Type: 8 ()
    # Field: params Type: 11 (.google.cloud.retail.v2alpha.PredictRequest.ParamsEntry)
    # Field: labels Type: 11 (.google.cloud.retail.v2alpha.PredictRequest.LabelsEntry)

# === Message: Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse ===
    # Fields for PredictResponse
    # Field: results Type: 11 (.google.cloud.retail.v2alpha.PredictResponse.PredictionResult)
    # Field: attribution_token Type: 9 ()
    # Field: missing_ids Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Service Client: Google::Cloud::Retail::V2alpha::PredictionService::PredictionServiceClient ===
package Google::Cloud::Retail::V2alpha::PredictionService::PredictionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::PredictionService::PredictionServiceClient

Client stub representing the remote C<PredictionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub predict {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.PredictionService',
        method         => 'Predict',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::PredictionService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/prediction_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::PredictionService;

    my $msg = Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest->new({
        placement => $placement,
        user_event => $user_event,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->placement();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/prediction_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest

Request message for Predict method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->placement() >> / C<< $msg->placement($value) >>

Type: C<String>

Required. Full resource name of the format:
`{placement=projects/*/locations/global/catalogs/default_catalog/servingConfigs/*}`
or
`{placement=projects/*/locations/global/catalogs/default_catalog/placements/*}`.
We recommend using the `servingConfigs` resource. `placements` is a legacy
resource.
The ID of the Recommendations AI serving config or placement.
Before you can request predictions from your model, you must create at
least one serving config or placement for it. For more information, see
[Manage serving configs]
(https://cloud.google.com/retail/docs/manage-configs).

The full list of available serving configs can be seen at
https://console.cloud.google.com/ai/retail/catalogs/default_catalog/configs

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::UserEvent::UserEvent>)

Required. Context about the user, what they are looking at and what action
they took to trigger the predict request. Note that this user event detail
won't be ingested to userEvent logs. Thus, a separate userEvent write
request is required for event logging.

Don't set
[UserEvent.visitor_id][google.cloud.retail.v2alpha.UserEvent.visitor_id] or
[UserInfo.user_id][google.cloud.retail.v2alpha.UserInfo.user_id] to the
same fixed ID for different users. If you are trying to receive
non-personalized recommendations (not recommended; this can negatively
impact model performance), instead set
[UserEvent.visitor_id][google.cloud.retail.v2alpha.UserEvent.visitor_id] to
a random unique ID and leave
[UserInfo.user_id][google.cloud.retail.v2alpha.UserInfo.user_id] unset.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of results to return. Set this property to the number of
prediction results needed. If zero, the service will choose a reasonable
default. The maximum allowed value is 100. Values above 100 will be coerced
to 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

This field is not used; leave it unset.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter for restricting prediction results with a length limit of 5,000
characters. Accepts values for tags and the `filterOutOfStockItems` flag.

 * Tag expressions. Restricts predictions to products that match all of the
   specified tags. Boolean operators `OR` and `NOT` are supported if the
   expression is enclosed in parentheses, and must be separated from the
   tag values by a space. `-"tagA"` is also supported and is equivalent to
   `NOT "tagA"`. Tag values must be double quoted UTF-8 encoded strings
   with a size limit of 1,000 characters.

   Note: "Recently viewed" models don't support tag filtering at the
   moment.

 * filterOutOfStockItems. Restricts predictions to products that do not
 have a
   stockState value of OUT_OF_STOCK.

Examples:

 * tag=("Red" OR "Blue") tag="New-Arrival" tag=(NOT "promotional")
 * filterOutOfStockItems  tag=(-"promotional")
 * filterOutOfStockItems

If your filter blocks all prediction results, the API will return *no*
results. If instead you want empty result sets to return generic
(unfiltered) popular products, set `strictFiltering` to False in
`PredictRequest.params`. Note that the API will never return items with
storageStatus of "EXPIRED" or "DELETED" regardless of filter choices.

If `filterSyntaxV2` is set to true under the `params` field, then
attribute-based expressions are expected instead of the above described
tag-based syntax. Examples:

 * (colors: ANY("Red", "Blue")) AND NOT (categories: ANY("Phones"))
 * (availability: ANY("IN_STOCK")) AND
   (colors: ANY("Red") OR categories: ANY("Phones"))

For more information, see
[Filter recommendations](https://cloud.google.com/retail/docs/filter-recs).

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Use validate only mode for this prediction query. If set to true, a
dummy model will be used that returns arbitrary products.
Note that the validate only mode should only be used for testing the API,
or if the model is not ready.

=item * C<< $msg->params() >> / C<< $msg->params($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest::ParamsEntry>)

Additional domain specific parameters for the predictions.

Allowed values:

* `returnProduct`: Boolean. If set to true, the associated product
   object will be returned in the `results.metadata` field in the
   prediction response.
* `returnScore`: Boolean. If set to true, the prediction 'score'
   corresponding to each returned product will be set in the
   `results.metadata` field in the prediction response. The given
   'score' indicates the probability of a product being clicked/purchased
   given the user's context and history.
* `strictFiltering`: Boolean. True by default. If set to false, the service
   will return generic (unfiltered) popular products instead of empty if
   your filter blocks all prediction results.
* `priceRerankLevel`: String. Default empty. If set to be non-empty, then
   it needs to be one of {'no-price-reranking', 'low-price-reranking',
   'medium-price-reranking', 'high-price-reranking'}. This gives
   request-level control and adjusts prediction results based on product
   price.
* `diversityLevel`: String. Default empty. If set to be non-empty, then
   it needs to be one of {'no-diversity', 'low-diversity',
   'medium-diversity', 'high-diversity', 'auto-diversity'}. This gives
   request-level control and adjusts prediction results based on product
   category.
* `filterSyntaxV2`: Boolean. False by default. If set to true, the `filter`
  field is interpreteted according to the new, attribute-based syntax.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest::LabelsEntry>)

The labels applied to a resource must meet the following requirements:

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

See [Google Cloud
Document](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements)
for more details.

=back

=head2 Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse

Response message for predict method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->results() >> / C<< $msg->results($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse::PredictionResult>)

A list of recommended products. The order represents the ranking (from the
most relevant product to the least).

=item * C<< $msg->attribution_token() >> / C<< $msg->attribution_token($value) >>

Type: C<String>

A unique attribution token. This should be included in the
[UserEvent][google.cloud.retail.v2alpha.UserEvent] logs resulting from this
recommendation, which enables accurate attribution of recommendation model
performance.

=item * C<< $msg->missing_ids() >> / C<< $msg->missing_ids($value) >>

Type: C<String>

IDs of products in the request that were missing from the inventory.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

True if the validateOnly property was set in the request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::PredictionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
