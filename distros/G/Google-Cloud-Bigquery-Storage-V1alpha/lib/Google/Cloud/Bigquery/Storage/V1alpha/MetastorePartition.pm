package Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition;

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
    eval { require Google::Cloud::Bigquery::Storage::V1alpha::Partition };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWFscGhhL21ldGFzdG9yZV9wYXJ0
aXRpb24ucHJvdG8SJWdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYWxwaGEaHGdv
b2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGjVnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWFscGhhL3BhcnRpdGlvbi5w
cm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmll
bGRfbWFzay5wcm90byLRAQofQ3JlYXRlTWV0YXN0b3JlUGFydGl0aW9uUmVxdWVzdBI9CgZw
YXJlbnQYASABKAlCJeBBAvpBHwodYmlncXVlcnkuZ29vZ2xlYXBpcy5jb20vVGFibGVSBnBh
cmVudBJvChNtZXRhc3RvcmVfcGFydGl0aW9uGAIgASgLMjkuZ29vZ2xlLmNsb3VkLmJpZ3F1
ZXJ5LnN0b3JhZ2UudjFhbHBoYS5NZXRhc3RvcmVQYXJ0aXRpb25CA+BBAlISbWV0YXN0b3Jl
UGFydGl0aW9uIq4CCiVCYXRjaENyZWF0ZU1ldGFzdG9yZVBhcnRpdGlvbnNSZXF1ZXN0Ej0K
BnBhcmVudBgBIAEoCUIl4EEC+kEfCh1iaWdxdWVyeS5nb29nbGVhcGlzLmNvbS9UYWJsZVIG
cGFyZW50EmcKCHJlcXVlc3RzGAIgAygLMkYuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3Jh
Z2UudjFhbHBoYS5DcmVhdGVNZXRhc3RvcmVQYXJ0aXRpb25SZXF1ZXN0QgPgQQJSCHJlcXVl
c3RzEj0KGHNraXBfZXhpc3RpbmdfcGFydGl0aW9ucxgDIAEoCEID4EEBUhZza2lwRXhpc3Rp
bmdQYXJ0aXRpb25zEh4KCHRyYWNlX2lkGAQgASgJQgPgQQFSB3RyYWNlSWQigwEKJkJhdGNo
Q3JlYXRlTWV0YXN0b3JlUGFydGl0aW9uc1Jlc3BvbnNlElkKCnBhcnRpdGlvbnMYASADKAsy
OS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWFscGhhLk1ldGFzdG9yZVBhcnRp
dGlvblIKcGFydGl0aW9ucyL3AQolQmF0Y2hEZWxldGVNZXRhc3RvcmVQYXJ0aXRpb25zUmVx
dWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodYmlncXVlcnkuZ29vZ2xlYXBpcy5jb20v
VGFibGVSBnBhcmVudBJvChBwYXJ0aXRpb25fdmFsdWVzGAIgAygLMj8uZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnN0b3JhZ2UudjFhbHBoYS5NZXRhc3RvcmVQYXJ0aXRpb25WYWx1ZXNCA+BB
AlIPcGFydGl0aW9uVmFsdWVzEh4KCHRyYWNlX2lkGAQgASgJQgPgQQFSB3RyYWNlSWQi1AEK
H1VwZGF0ZU1ldGFzdG9yZVBhcnRpdGlvblJlcXVlc3QSbwoTbWV0YXN0b3JlX3BhcnRpdGlv
bhgBIAEoCzI5Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYWxwaGEuTWV0YXN0
b3JlUGFydGl0aW9uQgPgQQJSEm1ldGFzdG9yZVBhcnRpdGlvbhJACgt1cGRhdGVfbWFzaxgC
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayLvAQol
QmF0Y2hVcGRhdGVNZXRhc3RvcmVQYXJ0aXRpb25zUmVxdWVzdBI9CgZwYXJlbnQYASABKAlC
JeBBAvpBHwodYmlncXVlcnkuZ29vZ2xlYXBpcy5jb20vVGFibGVSBnBhcmVudBJnCghyZXF1
ZXN0cxgCIAMoCzJGLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYWxwaGEuVXBk
YXRlTWV0YXN0b3JlUGFydGl0aW9uUmVxdWVzdEID4EECUghyZXF1ZXN0cxIeCgh0cmFjZV9p
ZBgEIAEoCUID4EEBUgd0cmFjZUlkIoMBCiZCYXRjaFVwZGF0ZU1ldGFzdG9yZVBhcnRpdGlv
bnNSZXNwb25zZRJZCgpwYXJ0aXRpb25zGAEgAygLMjkuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5
LnN0b3JhZ2UudjFhbHBoYS5NZXRhc3RvcmVQYXJ0aXRpb25SCnBhcnRpdGlvbnMinAEKHkxp
c3RNZXRhc3RvcmVQYXJ0aXRpb25zUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwod
YmlncXVlcnkuZ29vZ2xlYXBpcy5jb20vVGFibGVSBnBhcmVudBIbCgZmaWx0ZXIYAiABKAlC
A+BBAVIGZmlsdGVyEh4KCHRyYWNlX2lkGAMgASgJQgPgQQFSB3RyYWNlSWQi3QEKH0xpc3RN
ZXRhc3RvcmVQYXJ0aXRpb25zUmVzcG9uc2USXwoKcGFydGl0aW9ucxgBIAEoCzI9Lmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYWxwaGEuTWV0YXN0b3JlUGFydGl0aW9uTGlz
dEgAUgpwYXJ0aXRpb25zEk0KB3N0cmVhbXMYAiABKAsyMS5nb29nbGUuY2xvdWQuYmlncXVl
cnkuc3RvcmFnZS52MWFscGhhLlN0cmVhbUxpc3RIAFIHc3RyZWFtc0IKCghyZXNwb25zZSKT
AgogU3RyZWFtTWV0YXN0b3JlUGFydGl0aW9uc1JlcXVlc3QSPQoGcGFyZW50GAEgASgJQiXg
QQL6QR8KHWJpZ3F1ZXJ5Lmdvb2dsZWFwaXMuY29tL1RhYmxlUgZwYXJlbnQScQoUbWV0YXN0
b3JlX3BhcnRpdGlvbnMYAiADKAsyOS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52
MWFscGhhLk1ldGFzdG9yZVBhcnRpdGlvbkID4EEBUhNtZXRhc3RvcmVQYXJ0aXRpb25zEj0K
GHNraXBfZXhpc3RpbmdfcGFydGl0aW9ucxgDIAEoCEID4EEBUhZza2lwRXhpc3RpbmdQYXJ0
aXRpb25zIrEBCiFTdHJlYW1NZXRhc3RvcmVQYXJ0aXRpb25zUmVzcG9uc2USRQofdG90YWxf
cGFydGl0aW9uc19zdHJlYW1lZF9jb3VudBgCIAEoA1IcdG90YWxQYXJ0aXRpb25zU3RyZWFt
ZWRDb3VudBJFCh90b3RhbF9wYXJ0aXRpb25zX2luc2VydGVkX2NvdW50GAMgASgDUhx0b3Rh
bFBhcnRpdGlvbnNJbnNlcnRlZENvdW50ImgKFkJhdGNoU2l6ZVRvb0xhcmdlRXJyb3ISJAoO
bWF4X2JhdGNoX3NpemUYASABKANSDG1heEJhdGNoU2l6ZRIoCg1lcnJvcl9tZXNzYWdlGAIg
ASgJQgPgQQFSDGVycm9yTWVzc2FnZTLeCgoZTWV0YXN0b3JlUGFydGl0aW9uU2VydmljZRKR
AgoeQmF0Y2hDcmVhdGVNZXRhc3RvcmVQYXJ0aXRpb25zEkwuZ29vZ2xlLmNsb3VkLmJpZ3F1
ZXJ5LnN0b3JhZ2UudjFhbHBoYS5CYXRjaENyZWF0ZU1ldGFzdG9yZVBhcnRpdGlvbnNSZXF1
ZXN0Gk0uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFhbHBoYS5CYXRjaENyZWF0
ZU1ldGFzdG9yZVBhcnRpdGlvbnNSZXNwb25zZSJSgtPkkwJMIkcvdjFhbHBoYS97cGFyZW50
PXByb2plY3RzLyovZGF0YXNldHMvKi90YWJsZXMvKn0vcGFydGl0aW9uczpiYXRjaENyZWF0
ZToBKhLaAQoeQmF0Y2hEZWxldGVNZXRhc3RvcmVQYXJ0aXRpb25zEkwuZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnN0b3JhZ2UudjFhbHBoYS5CYXRjaERlbGV0ZU1ldGFzdG9yZVBhcnRpdGlv
bnNSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IlKC0+STAkwiRy92MWFscGhhL3tw
YXJlbnQ9cHJvamVjdHMvKi9kYXRhc2V0cy8qL3RhYmxlcy8qfS9wYXJ0aXRpb25zOmJhdGNo
RGVsZXRlOgEqEpECCh5CYXRjaFVwZGF0ZU1ldGFzdG9yZVBhcnRpdGlvbnMSTC5nb29nbGUu
Y2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWFscGhhLkJhdGNoVXBkYXRlTWV0YXN0b3JlUGFy
dGl0aW9uc1JlcXVlc3QaTS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWFscGhh
LkJhdGNoVXBkYXRlTWV0YXN0b3JlUGFydGl0aW9uc1Jlc3BvbnNlIlKC0+STAkwiRy92MWFs
cGhhL3twYXJlbnQ9cHJvamVjdHMvKi9kYXRhc2V0cy8qL3RhYmxlcy8qfS9wYXJ0aXRpb25z
OmJhdGNoVXBkYXRlOgEqEocCChdMaXN0TWV0YXN0b3JlUGFydGl0aW9ucxJFLmdvb2dsZS5j
bG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYWxwaGEuTGlzdE1ldGFzdG9yZVBhcnRpdGlvbnNS
ZXF1ZXN0GkYuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFhbHBoYS5MaXN0TWV0
YXN0b3JlUGFydGl0aW9uc1Jlc3BvbnNlIl2C0+STAk4STC92MWFscGhhL3twYXJlbnQ9cHJv
amVjdHMvKi9sb2NhdGlvbnMvKi9kYXRhc2V0cy8qL3RhYmxlcy8qfS9wYXJ0aXRpb25zOmxp
c3TaQQZwYXJlbnQStAEKGVN0cmVhbU1ldGFzdG9yZVBhcnRpdGlvbnMSRy5nb29nbGUuY2xv
dWQuYmlncXVlcnkuc3RvcmFnZS52MWFscGhhLlN0cmVhbU1ldGFzdG9yZVBhcnRpdGlvbnNS
ZXF1ZXN0GkguZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFhbHBoYS5TdHJlYW1N
ZXRhc3RvcmVQYXJ0aXRpb25zUmVzcG9uc2UiACgBMAEae8pBHmJpZ3F1ZXJ5c3RvcmFnZS5n
b29nbGVhcGlzLmNvbdJBV2h0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvYmlncXVl
cnksaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUK6Agop
Y29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYWxwaGFCHk1ldGFzdG9yZVBh
cnRpdGlvblNlcnZpY2VQcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3N0
b3JhZ2UvYXBpdjFhbHBoYS9zdG9yYWdlcGI7c3RvcmFnZXBiqgIlR29vZ2xlLkNsb3VkLkJp
Z1F1ZXJ5LlN0b3JhZ2UuVjFBbHBoYcoCJUdvb2dsZVxDbG91ZFxCaWdRdWVyeVxTdG9yYWdl
XFYxYWxwaGHqQVUKHWJpZ3F1ZXJ5Lmdvb2dsZWFwaXMuY29tL1RhYmxlEjRwcm9qZWN0cy97
cHJvamVjdH0vZGF0YXNldHMve2RhdGFzZXR9L3RhYmxlcy97dGFibGV9SolbCgcSBQ4AtgIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAuCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPwoJCgIDBRID
FwAlCgkKAgMGEgMYACoKCAoBCBIDGgBCCgkKAgglEgMaAEIKCAoBCBIDGwBaCgkKAggLEgMb
AFoKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA/CgkKAggIEgMdAD8KCAoBCBIDHgBC
CgkKAggBEgMeAEIKCAoBCBIDHwBDCgkKAggpEgMfAEMKCQoBCBIEIAAjAgoMCgQInQgAEgQg
ACMCCsABCgIGABIEKABaARqzASBCaWdRdWVyeSBNZXRhc3RvcmUgUGFydGl0aW9uIFNlcnZp
Y2UgQVBJLgogIFRoaXMgc2VydmljZSBpcyB1c2VkIGZvciBtYW5hZ2luZyBtZXRhc3RvcmUg
cGFydGl0aW9ucyBpbiBCaWdRdWVyeQogIG1ldGFzdG9yZS4gVGhlIHNlcnZpY2Ugc3VwcG9y
dHMgb25seSBiYXRjaCBvcGVyYXRpb25zIGZvciB3cml0ZS4KCgoKAwYAARIDKAghCgoKAwYA
AxIDKQJGCgwKBQYAA5kIEgMpAkYKCwoDBgADEgQqAiw3Cg0KBQYAA5oIEgQqAiw3CjUKBAYA
AgASBC8CNQMaJyBBZGRzIG1ldGFzdG9yZSBwYXJ0aXRpb25zIHRvIGEgdGFibGUuCgoMCgUG
AAIAARIDLwYkCgwKBQYAAgACEgMvJUoKDAoFBgACAAMSAzAPNQoNCgUGAAIABBIEMQQ0BgoR
CgkGAAIABLDKvCISBDEENAYKOgoEBgACARIEOAI+AxosIERlbGV0ZXMgbWV0YXN0b3JlIHBh
cnRpdGlvbnMgZnJvbSBhIHRhYmxlLgoKDAoFBgACAQESAzgGJAoMCgUGAAIBAhIDOCVKCgwK
BQYAAgEDEgM5DyQKDQoFBgACAQQSBDoEPQYKEQoJBgACAQSwyrwiEgQ6BD0GCjgKBAYAAgIS
BEECRwMaKiBVcGRhdGVzIG1ldGFzdG9yZSBwYXJ0aXRpb25zIGluIGEgdGFibGUuCgoMCgUG
AAICARIDQQYkCgwKBQYAAgICEgNBJUoKDAoFBgACAgMSA0IPNQoNCgUGAAICBBIEQwRGBgoR
CgkGAAICBLDKvCISBEMERgYKNwoEBgACAxIESgJQAxopIEdldHMgbWV0YXN0b3JlIHBhcnRp
dGlvbnMgZnJvbSBhIHRhYmxlLgoKDAoFBgACAwESA0oGHQoMCgUGAAIDAhIDSh48CgwKBQYA
AgMDEgNLDy4KDQoFBgACAwQSBEwETgYKEQoJBgACAwSwyrwiEgRMBE4GCgwKBQYAAgMEEgNP
BDQKDwoIBgACAwSbCAASA08ENAqhAwoEBgACBBIEWAJZOxqSAyBUaGlzIGlzIGEgYmktZGkg
c3RyZWFtaW5nIHJwYyBtZXRob2QgdGhhdCBhbGxvd3MgdGhlIGNsaWVudCB0byBzZW5kCiBh
IHN0cmVhbSBvZiBwYXJ0aXRpb25zIGFuZCBjb21taXQgYWxsIG9mIHRoZW0gYXRvbWljYWxs
eSBhdCB0aGUgZW5kLgogSWYgdGhlIGNvbW1pdCBpcyBzdWNjZXNzZnVsLCB0aGUgc2VydmVy
IHdpbGwgcmV0dXJuIGEKIHJlc3BvbnNlIGFuZCBjbG9zZSB0aGUgc3RyZWFtLiBJZiB0aGUg
Y29tbWl0IGZhaWxzIChkdWUgdG8gZHVwbGljYXRlCiBwYXJ0aXRpb25zIG9yIG90aGVyIHJl
YXNvbiksIHRoZSBzZXJ2ZXIgd2lsbCBjbG9zZSB0aGUgc3RyZWFtIHdpdGggYW4KIGVycm9y
LiBUaGlzIG1ldGhvZCBpcyBvbmx5IGF2YWlsYWJsZSB2aWEgdGhlIGdSUEMgQVBJIChub3Qg
UkVTVCkuCgoMCgUGAAIEARIDWAYfCgwKBQYAAgQFEgNYICYKDAoFBgACBAISA1gnRwoMCgUG
AAIEBhIDWQ8VCgwKBQYAAgQDEgNZFjcKyQEKAgQAEgRfAGsBGrwBIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgQ3JlYXRlTWV0YXN0b3JlUGFydGl0aW9uLiBUaGUgTWV0YXN0b3JlUGFydGl0aW9u
IGlzCiB1bmlxdWVseSBpZGVudGlmaWVkIGJ5IHZhbHVlcywgd2hpY2ggaXMgYW4gb3JkZXJl
ZCBsaXN0LiBIZW5jZSwgdGhlcmUgaXMgbm8KIHNlcGFyYXRlIG5hbWUgb3IgcGFydGl0aW9u
IGlkIGZpZWxkLgoKCgoDBAABEgNfCCcKqwEKBAQAAgASBGMCZgQanAEgUmVxdWlyZWQuIFJl
ZmVyZW5jZSB0byB0aGUgdGFibGUgdG8gd2hlcmUgdGhlIG1ldGFzdG9yZSBwYXJ0aXRpb24g
dG8gYmUKIGFkZGVkLCBpbiB0aGUgZm9ybWF0IG9mCiBwcm9qZWN0cy97cHJvamVjdH0vZGF0
YWJhc2VzL3tkYXRhYmFzZXN9L3RhYmxlcy97dGFibGV9LgoKDAoFBAACAAUSA2MCCAoMCgUE
AAIAARIDYwkPCgwKBQQAAgADEgNjEhMKDQoFBAACAAgSBGMUZgMKDwoIBAACAAicCAASA2QE
KgoOCgcEAAIACJ8IEgNlBE8KPgoEBAACARIEaQJqLxowIFJlcXVpcmVkLiBUaGUgbWV0YXN0
b3JlIHBhcnRpdGlvbiB0byBiZSBhZGRlZC4KCgwKBQQAAgEGEgNpAhQKDAoFBAACAQESA2kV
KAoMCgUEAAIBAxIDaSssCgwKBQQAAgEIEgNqBi4KDwoIBAACAQicCAASA2oHLQpCCgIEARIF
bgCIAQEaNSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEJhdGNoQ3JlYXRlTWV0YXN0b3JlUGFydGl0
aW9ucy4KCgoKAwQBARIDbggtCr4BCgQEAQIAEgRyAnUEGq8BIFJlcXVpcmVkLiBSZWZlcmVu
Y2UgdG8gdGhlIHRhYmxlIHRvIHdoZXJlIHRoZSBtZXRhc3RvcmUgcGFydGl0aW9ucyB0byBi
ZQogYWRkZWQsIGluIHRoZSBmb3JtYXQgb2YKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9kYXRhc2V0cy97ZGF0YXNldH0vdGFibGVzL3t0YWJsZX0uCgoMCgUE
AQIABRIDcgIICgwKBQQBAgABEgNyCQ8KDAoFBAECAAMSA3ISEwoNCgUEAQIACBIEchR1AwoP
CggEAQIACJwIABIDcwQqCg4KBwQBAgAInwgSA3QETwpMCgQEAQIBEgR4AnkvGj4gUmVxdWly
ZWQuIFJlcXVlc3RzIHRvIGFkZCBtZXRhc3RvcmUgcGFydGl0aW9ucyB0byB0aGUgdGFibGUu
CgoMCgUEAQIBBBIDeAIKCgwKBQQBAgEGEgN4CyoKDAoFBAECAQESA3grMwoMCgUEAQIBAxID
eDY3CgwKBQQBAgEIEgN5Bi4KDwoIBAECAQicCAASA3kHLQrwAgoEBAECAhIEgAECTRrhAiBP
cHRpb25hbC4gTWltaWNzIHRoZSBpZk5vdEV4aXN0cyBmbGFnIGluIElNZXRhU3RvcmVDbGll
bnQKIGFkZF9wYXJ0aXRpb25zKC4uKS4gSWYgdGhlIGZsYWcgaXMgc2V0IHRvIGZhbHNlLCB0
aGUgc2VydmVyIHdpbGwgcmV0dXJuCiBBTFJFQURZX0VYSVNUUyBpZiBhbnkgcGFydGl0aW9u
IGFscmVhZHkgZXhpc3RzLiBJZiB0aGUgZmxhZyBpcyBzZXQgdG8gdHJ1ZSwKIHRoZSBzZXJ2
ZXIgd2lsbCBza2lwIGV4aXN0aW5nIHBhcnRpdGlvbnMgYW5kIGluc2VydCBvbmx5IHRoZSBu
b24tZXhpc3RpbmcKIHBhcnRpdGlvbnMuIEEgbWF4aW11bSBvZiA5MDAgcGFydGl0aW9ucyBj
YW4gYmUgaW5zZXJ0ZWQgaW4gYSBiYXRjaC4KCg0KBQQBAgIFEgSAAQIGCg0KBQQBAgIBEgSA
AQcfCg0KBQQBAgIDEgSAASIjCg0KBQQBAgIIEgSAASRMChAKCAQBAgIInAgAEgSAASVLCt0C
CgQEAQIDEgSHAQI/Gs4CIE9wdGlvbmFsLiBPcHRpb25hbCB0cmFjZSBpZCB0byBiZSB1c2Vk
IGZvciBkZWJ1Z2dpbmcuIEl0IGlzIGV4cGVjdGVkIHRoYXQKIHRoZSBjbGllbnQgc2V0cyB0
aGUgc2FtZSBgdHJhY2VfaWRgIGZvciBhbGwgdGhlIGJhdGNoZXMgaW4gdGhlIHNhbWUKIG9w
ZXJhdGlvbiwgc28gdGhhdCBpdCBpcyBwb3NzaWJsZSB0byB0aWUgdG9nZXRoZXIgdGhlIGxv
Z3MgdG8gYWxsIHRoZQogYmF0Y2hlcyBpbiB0aGUgc2FtZSBvcGVyYXRpb24uIExpbWl0ZWQg
dG8gMjU2IGNoYXJhY3RlcnMuIFRoaXMgaXMgZXhwZWN0ZWQsCiBidXQgbm90IHJlcXVpcmVk
LCB0byBiZSBnbG9iYWxseSB1bmlxdWUuCgoNCgUEAQIDBRIEhwECCAoNCgUEAQIDARIEhwEJ
EQoNCgUEAQIDAxIEhwEUFQoNCgUEAQIDCBIEhwEWPgoQCggEAQIDCJwIABIEhwEXPQpECgIE
AhIGiwEAjgEBGjYgUmVzcG9uc2UgbWVzc2FnZSBmb3IgQmF0Y2hDcmVhdGVNZXRhc3RvcmVQ
YXJ0aXRpb25zLgoKCwoDBAIBEgSLAQguCkgKBAQCAgASBI0BAi0aOiBUaGUgbGlzdCBvZiBt
ZXRhc3RvcmUgcGFydGl0aW9ucyB0aGF0IGhhdmUgYmVlbiBjcmVhdGVkLgoKDQoFBAICAAQS
BI0BAgoKDQoFBAICAAYSBI0BCx0KDQoFBAICAAESBI0BHigKDQoFBAICAAMSBI0BKywK0QEK
AgQDEgaTAQCnAQEawgEgUmVxdWVzdCBtZXNzYWdlIGZvciBCYXRjaERlbGV0ZU1ldGFzdG9y
ZVBhcnRpdGlvbnMuIFRoZSBNZXRhc3RvcmVQYXJ0aXRpb24gaXMKIHVuaXF1ZWx5IGlkZW50
aWZpZWQgYnkgdmFsdWVzLCB3aGljaCBpcyBhbiBvcmRlcmVkIGxpc3QuIEhlbmNlLCB0aGVy
ZSBpcyBubwogc2VwYXJhdGUgbmFtZSBvciBwYXJ0aXRpb24gaWQgZmllbGQuCgoLCgMEAwES
BJMBCC0KvQEKBAQDAgASBpcBApoBBBqsASBSZXF1aXJlZC4gUmVmZXJlbmNlIHRvIHRoZSB0
YWJsZSB0byB3aGljaCB0aGVzZSBtZXRhc3RvcmUgcGFydGl0aW9ucwogYmVsb25nLCBpbiB0
aGUgZm9ybWF0IG9mCiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
ZGF0YXNldHMve2RhdGFzZXR9L3RhYmxlcy97dGFibGV9LgoKDQoFBAMCAAUSBJcBAggKDQoF
BAMCAAESBJcBCQ8KDQoFBAMCAAMSBJcBEhMKDwoFBAMCAAgSBpcBFJoBAwoQCggEAwIACJwI
ABIEmAEEKgoPCgcEAwIACJ8IEgSZAQRPCp8BCgQEAwIBEgaeAQKfAS8ajgEgUmVxdWlyZWQu
IFRoZSBsaXN0IG9mIG1ldGFzdG9yZSBwYXJ0aXRpb25zIChpZGVudGlmaWVkIGJ5IGl0cyB2
YWx1ZXMpIHRvIGJlCiBkZWxldGVkLiBBIG1heGltdW0gb2YgOTAwIHBhcnRpdGlvbnMgY2Fu
IGJlIGRlbGV0ZWQgaW4gYSBiYXRjaC4KCg0KBQQDAgEEEgSeAQIKCg0KBQQDAgEGEgSeAQsj
Cg0KBQQDAgEBEgSeASQ0Cg0KBQQDAgEDEgSeATc4Cg0KBQQDAgEIEgSfAQYuChAKCAQDAgEI
nAgAEgSfAQctCsICCgQEAwICEgSmAQI/GrMCIE9wdGlvbmFsLiBPcHRpb25hbCB0cmFjZSBp
ZCB0byBiZSB1c2VkIGZvciBkZWJ1Z2dpbmcuIEl0IGlzIGV4cGVjdGVkIHRoYXQKIHRoZSBj
bGllbnQgc2V0cyB0aGUgc2FtZSBgdHJhY2VfaWRgIGZvciBhbGwgdGhlIGJhdGNoZXMgaW4g
dGhlIHNhbWUKIG9wZXJhdGlvbiwgc28gdGhhdCBpdCBpcyBwb3NzaWJsZSB0byB0aWUgdG9n
ZXRoZXIgdGhlIGxvZ3MgdG8gYWxsIHRoZQogYmF0Y2hlcyBpbiB0aGUgc2FtZSBvcGVyYXRp
b24uIFRoaXMgaXMgZXhwZWN0ZWQsIGJ1dCBub3QgcmVxdWlyZWQsIHRvIGJlCiBnbG9iYWxs
eSB1bmlxdWUuCgoNCgUEAwICBRIEpgECCAoNCgUEAwICARIEpgEJEQoNCgUEAwICAxIEpgEU
FQoNCgUEAwICCBIEpgEWPgoQCggEAwICCJwIABIEpgEXPQo9CgIEBBIGqgEAsgEBGi8gUmVx
dWVzdCBtZXNzYWdlIGZvciBVcGRhdGVNZXRhc3RvcmVQYXJ0aXRpb24uCgoLCgMEBAESBKoB
CCcKQgoEBAQCABIGrAECrQEvGjIgUmVxdWlyZWQuIFRoZSBtZXRhc3RvcmUgcGFydGl0aW9u
IHRvIGJlIHVwZGF0ZWQuCgoNCgUEBAIABhIErAECFAoNCgUEBAIAARIErAEVKAoNCgUEBAIA
AxIErAErLAoNCgUEBAIACBIErQEGLgoQCggEBAIACJwIABIErQEHLQo5CgQEBAIBEgawAQKx
AS8aKSBPcHRpb25hbC4gVGhlIGxpc3Qgb2YgZmllbGRzIHRvIHVwZGF0ZS4KCg0KBQQEAgEG
EgSwAQIbCg0KBQQEAgEBEgSwARwnCg0KBQQEAgEDEgSwASorCg0KBQQEAgEIEgSxAQYuChAK
CAQEAgEInAgAEgSxAQctCkMKAgQFEga1AQDIAQEaNSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEJh
dGNoVXBkYXRlTWV0YXN0b3JlUGFydGl0aW9ucy4KCgsKAwQFARIEtQEILQq9AQoEBAUCABIG
uQECvAEEGqwBIFJlcXVpcmVkLiBSZWZlcmVuY2UgdG8gdGhlIHRhYmxlIHRvIHdoaWNoIHRo
ZXNlIG1ldGFzdG9yZSBwYXJ0aXRpb25zCiBiZWxvbmcsIGluIHRoZSBmb3JtYXQgb2YKIHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhc2V0cy97ZGF0YXNl
dH0vdGFibGVzL3t0YWJsZX0uCgoNCgUEBQIABRIEuQECCAoNCgUEBQIAARIEuQEJDwoNCgUE
BQIAAxIEuQESEwoPCgUEBQIACBIGuQEUvAEDChAKCAQFAgAInAgAEgS6AQQqCg8KBwQFAgAI
nwgSBLsBBE8KUQoEBAUCARIGvwECwAEvGkEgUmVxdWlyZWQuIFJlcXVlc3RzIHRvIHVwZGF0
ZSBtZXRhc3RvcmUgcGFydGl0aW9ucyBpbiB0aGUgdGFibGUuCgoNCgUEBQIBBBIEvwECCgoN
CgUEBQIBBhIEvwELKgoNCgUEBQIBARIEvwErMwoNCgUEBQIBAxIEvwE2NwoNCgUEBQIBCBIE
wAEGLgoQCggEBQIBCJwIABIEwAEHLQrCAgoEBAUCAhIExwECPxqzAiBPcHRpb25hbC4gT3B0
aW9uYWwgdHJhY2UgaWQgdG8gYmUgdXNlZCBmb3IgZGVidWdnaW5nLiBJdCBpcyBleHBlY3Rl
ZCB0aGF0CiB0aGUgY2xpZW50IHNldHMgdGhlIHNhbWUgYHRyYWNlX2lkYCBmb3IgYWxsIHRo
ZSBiYXRjaGVzIGluIHRoZSBzYW1lCiBvcGVyYXRpb24sIHNvIHRoYXQgaXQgaXMgcG9zc2li
bGUgdG8gdGllIHRvZ2V0aGVyIHRoZSBsb2dzIHRvIGFsbCB0aGUKIGJhdGNoZXMgaW4gdGhl
IHNhbWUgb3BlcmF0aW9uLiBUaGlzIGlzIGV4cGVjdGVkLCBidXQgbm90IHJlcXVpcmVkLCB0
byBiZQogZ2xvYmFsbHkgdW5pcXVlLgoKDQoFBAUCAgUSBMcBAggKDQoFBAUCAgESBMcBCREK
DQoFBAUCAgMSBMcBFBUKDQoFBAUCAggSBMcBFj4KEAoIBAUCAgicCAASBMcBFz0KRAoCBAYS
BssBAM8BARo2IFJlc3BvbnNlIG1lc3NhZ2UgZm9yIEJhdGNoVXBkYXRlTWV0YXN0b3JlUGFy
dGl0aW9ucy4KCgsKAwQGARIEywEILgqAAQoEBAYCABIEzgECLRpyIFRoZSBsaXN0IG9mIG1l
dGFzdG9yZSBwYXJ0aXRpb25zIHRoYXQgaGF2ZSBiZWVuIHVwZGF0ZWQuCiBBIG1heGltdW0g
b2YgOTAwIHBhcnRpdGlvbnMgY2FuIGJlIHVwZGF0ZWQgaW4gYSBiYXRjaC4KCg0KBQQGAgAE
EgTOAQIKCg0KBQQGAgAGEgTOAQsdCg0KBQQGAgABEgTOAR4oCg0KBQQGAgADEgTOASssCjwK
AgQHEgbSAQDtAQEaLiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIExpc3RNZXRhc3RvcmVQYXJ0aXRp
b25zLgoKCwoDBAcBEgTSAQgmCr0BCgQEBwIAEgbWAQLZAQQarAEgUmVxdWlyZWQuIFJlZmVy
ZW5jZSB0byB0aGUgdGFibGUgdG8gd2hpY2ggdGhlc2UgbWV0YXN0b3JlIHBhcnRpdGlvbnMK
IGJlbG9uZywgaW4gdGhlIGZvcm1hdCBvZgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2RhdGFzZXRzL3tkYXRhc2V0fS90YWJsZXMve3RhYmxlfS4KCg0KBQQH
AgAFEgTWAQIICg0KBQQHAgABEgTWAQkPCg0KBQQHAgADEgTWARITCg8KBQQHAgAIEgbWARTZ
AQMKEAoIBAcCAAicCAASBNcBBCoKDwoHBAcCAAifCBIE2AEETwrAAwoEBAcCARIE5QECPRqx
AyBPcHRpb25hbC4gU1FMIHRleHQgZmlsdGVyaW5nIHN0YXRlbWVudCwgc2ltaWxhciB0byBh
IFdIRVJFIGNsYXVzZSBpbiBhCiBxdWVyeS4gT25seSBzdXBwb3J0cyBzaW5nbGUtcm93IGV4
cHJlc3Npb25zLiAgQWdncmVnYXRlIGZ1bmN0aW9ucyBhcmUgbm90CiBzdXBwb3J0ZWQuCgog
RXhhbXBsZXM6ICJpbnRfZmllbGQgPiA1IgogICAgICAgICAgICJkYXRlX2ZpZWxkID0gQ0FT
VCgnMjAxNC05LTI3JyBhcyBEQVRFKSIKICAgICAgICAgICAibnVsbGFibGVfZmllbGQgaXMg
bm90IE5VTEwiCiAgICAgICAgICAgInN0X2VxdWFscyhnZW9fZmllbGQsIHN0X2dlb2Zyb210
ZXh0KCJQT0lOVCgyLCAyKSIpKSIKICAgICAgICAgICAibnVtZXJpY19maWVsZCBCRVRXRUVO
IDEuMCBBTkQgNS4wIgogUmVzdHJpY3RlZCB0byBhIG1heGltdW0gbGVuZ3RoIGZvciAxIE1C
LgoKDQoFBAcCAQUSBOUBAggKDQoFBAcCAQESBOUBCQ8KDQoFBAcCAQMSBOUBEhMKDQoFBAcC
AQgSBOUBFDwKEAoIBAcCAQicCAASBOUBFTsK3QIKBAQHAgISBOwBAj8azgIgT3B0aW9uYWwu
IE9wdGlvbmFsIHRyYWNlIGlkIHRvIGJlIHVzZWQgZm9yIGRlYnVnZ2luZy4gSXQgaXMgZXhw
ZWN0ZWQgdGhhdAogdGhlIGNsaWVudCBzZXRzIHRoZSBzYW1lIGB0cmFjZV9pZGAgZm9yIGFs
bCB0aGUgYmF0Y2hlcyBpbiB0aGUgc2FtZQogb3BlcmF0aW9uLCBzbyB0aGF0IGl0IGlzIHBv
c3NpYmxlIHRvIHRpZSB0b2dldGhlciB0aGUgbG9ncyB0byBhbGwgdGhlCiBiYXRjaGVzIGlu
IHRoZSBzYW1lIG9wZXJhdGlvbi4gTGltaXRlZCB0byAyNTYgY2hhcmFjdGVycy4gVGhpcyBp
cyBleHBlY3RlZCwKIGJ1dCBub3QgcmVxdWlyZWQsIHRvIGJlIGdsb2JhbGx5IHVuaXF1ZS4K
Cg0KBQQHAgIFEgTsAQIICg0KBQQHAgIBEgTsAQkRCg0KBQQHAgIDEgTsARQVCg0KBQQHAgII
EgTsARY+ChAKCAQHAgIInAgAEgTsARc9Cj0KAgQIEgbwAQD/AQEaLyBSZXNwb25zZSBtZXNz
YWdlIGZvciBMaXN0TWV0YXN0b3JlUGFydGl0aW9ucy4KCgsKAwQIARIE8AEIJwryAwoEBAgI
ABIG+AEC/gEDGuEDIFRoZSByZXNwb25zZSBkZXBlbmRzIG9uIHRoZSBudW1iZXIgb2YgbWV0
YXN0b3JlIHBhcnRpdGlvbnMgdG8gYmUgcmV0dXJuZWQ7CiBpdCBjYW4gYmUgYSBsaXN0IG9m
IHBhcnRpdGlvbnMgb3IgYSBsaXN0IG9mCiBbUmVhZFN0cmVhbV0oKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9iaWdxdWVyeS9kb2NzL3JlZmVyZW5jZS9zdG9yYWdlL3JwYy9nb29nbGUu
Y2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MSNyZWFkc3RyZWFtKSkKIG9iamVjdHMuIEZvciB0
aGUgc2Vjb25kIHNpdHVhdGlvbiwgdGhlIEJpZ1F1ZXJ5IFtSZWFkIEFQSQogUmVhZFJvd3Nd
KGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9iaWdxdWVyeS9kb2NzL3JlZmVyZW5jZS9zdG9y
YWdlI3JlYWRfZnJvbV9hX3Nlc3Npb25fc3RyZWFtKQogbWV0aG9kIG11c3QgYmUgdXNlZCB0
byBzdHJlYW0gdGhlIGRhdGEgYW5kIGNvbnZlcnQgaXQgaW50byBhIGxpc3Qgb2YKIHBhcnRp
dGlvbnMuCgoNCgUECAgAARIE+AEIEAonCgQECAIAEgT6AQQqGhkgVGhlIGxpc3Qgb2YgcGFy
dGl0aW9ucy4KCg0KBQQIAgAGEgT6AQQaCg0KBQQIAgABEgT6ARslCg0KBQQIAgADEgT6ASgp
CiQKBAQIAgESBP0BBBsaFiBUaGUgbGlzdCBvZiBzdHJlYW1zLgoKDQoFBAgCAQYSBP0BBA4K
DQoFBAgCAQESBP0BDxYKDQoFBAgCAQMSBP0BGRoKrAEKAgQJEgaEAgCaAgEanQEgVGhlIHRv
cC1sZXZlbCBtZXNzYWdlIHNlbnQgYnkgdGhlIGNsaWVudCB0byB0aGUKIFtQYXJ0aXRpb25z
LlN0cmVhbU1ldGFzdG9yZVBhcnRpdGlvbnNdW10gbWV0aG9kLgogRm9sbG93cyB0aGUgZGVm
YXVsdCBnUlBDIHN0cmVhbWluZyBtYXhpbXVtIHNpemUgb2YgNCBNQi4KCgsKAwQJARIEhAII
KAq1AQoEBAkCABIGiAICiwIEGqQBIFJlcXVpcmVkLiBSZWZlcmVuY2UgdG8gdGhlIHRhYmxl
IHRvIHdoZXJlIHRoZSBwYXJ0aXRpb24gdG8gYmUgYWRkZWQsIGluIHRoZQogZm9ybWF0IG9m
CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YXNldHMve2Rh
dGFzZXR9L3RhYmxlcy97dGFibGV9LgoKDQoFBAkCAAUSBIgCAggKDQoFBAkCAAESBIgCCQ8K
DQoFBAkCAAMSBIgCEhMKDwoFBAkCAAgSBogCFIsCAwoQCggECQIACJwIABIEiQIEKgoPCgcE
CQIACJ8IEgSKAgRPClQKBAQJAgESBo4CAo8CLxpEIE9wdGlvbmFsLiBBIGxpc3Qgb2YgbWV0
YXN0b3JlIHBhcnRpdGlvbnMgdG8gYmUgYWRkZWQgdG8gdGhlIHRhYmxlLgoKDQoFBAkCAQQS
BI4CAgoKDQoFBAkCAQYSBI4CCx0KDQoFBAkCAQESBI4CHjIKDQoFBAkCAQMSBI4CNTYKDQoF
BAkCAQgSBI8CBi4KEAoIBAkCAQicCAASBI8CBy0KwgMKBAQJAgISBJkCAk0aswMgT3B0aW9u
YWwuIE1pbWljcyB0aGUgaWZOb3RFeGlzdHMgZmxhZyBpbiBJTWV0YVN0b3JlQ2xpZW50CiBh
ZGRfcGFydGl0aW9ucyguLikuIElmIHRoZSBmbGFnIGlzIHNldCB0byBmYWxzZSwgdGhlIHNl
cnZlciB3aWxsIHJldHVybgogQUxSRUFEWV9FWElTVFMgb24gY29tbWl0IGlmIGFueSBwYXJ0
aXRpb24gYWxyZWFkeSBleGlzdHMuIElmIHRoZSBmbGFnIGlzCiBzZXQgdG8gdHJ1ZToKICAx
KSB0aGUgc2VydmVyIHdpbGwgc2tpcCBleGlzdGluZyBwYXJ0aXRpb25zCiAgaW5zZXJ0IG9u
bHkgdGhlIG5vbi1leGlzdGluZyBwYXJ0aXRpb25zIGFzIHBhcnQgb2YgdGhlIGNvbW1pdC4K
ICAyKSBUaGUgY2xpZW50IG11c3Qgc2V0IHRoZSBgc2tpcF9leGlzdGluZ19wYXJ0aXRpb25z
YCBmaWVsZCB0byB0cnVlIGZvcgogIGFsbCByZXF1ZXN0cyBpbiB0aGUgc3RyZWFtLgoKDQoF
BAkCAgUSBJkCAgYKDQoFBAkCAgESBJkCBx8KDQoFBAkCAgMSBJkCIiMKDQoFBAkCAggSBJkC
JEwKEAoIBAkCAgicCAASBJkCJUsK4QEKAgQKEgagAgCqAgEa0gEgVGhpcyBpcyB0aGUgcmVz
cG9uc2UgbWVzc2FnZSBzZW50IGJ5IHRoZSBzZXJ2ZXIKIHRvIHRoZSBjbGllbnQgZm9yIHRo
ZSBbUGFydGl0aW9ucy5TdHJlYW1NZXRhc3RvcmVQYXJ0aXRpb25zXVtdIG1ldGhvZCB3aGVu
CiB0aGUgY29tbWl0IGlzIHN1Y2Nlc3NmdWwuIFNlcnZlciB3aWxsIGNsb3NlIHRoZSBzdHJl
YW0gYWZ0ZXIgc2VuZGluZyB0aGlzCiBtZXNzYWdlLgoKCwoDBAoBEgSgAggpCrABCgQECgIA
EgSkAgIsGqEBIFRvdGFsIGNvdW50IG9mIHBhcnRpdGlvbnMgc3RyZWFtZWQgYnkgdGhlIGNs
aWVudCBkdXJpbmcgdGhlIGxpZmV0aW1lIG9mIHRoZQogc3RyZWFtLiBUaGlzIGlzIG9ubHkg
c2V0IGluIHRoZSBmaW5hbCByZXNwb25zZSBtZXNzYWdlIGJlZm9yZSBjbG9zaW5nIHRoZQog
c3RyZWFtLgoKDQoFBAoCAAUSBKQCAgcKDQoFBAoCAAESBKQCCCcKDQoFBAoCAAMSBKQCKisK
sAEKBAQKAgESBKkCAiwaoQEgVG90YWwgY291bnQgb2YgcGFydGl0aW9ucyBpbnNlcnRlZCBi
eSB0aGUgc2VydmVyIGR1cmluZyB0aGUgbGlmZXRpbWUgb2YgdGhlCiBzdHJlYW0uIFRoaXMg
aXMgb25seSBzZXQgaW4gdGhlIGZpbmFsIHJlc3BvbnNlIG1lc3NhZ2UgYmVmb3JlIGNsb3Np
bmcgdGhlCiBzdHJlYW0uCgoNCgUECgIBBRIEqQICBwoNCgUECgIBARIEqQIIJwoNCgUECgIB
AxIEqQIqKwrKAQoCBAsSBq8CALYCARq7ASBTdHJ1Y3R1cmVkIGN1c3RvbSBlcnJvciBtZXNz
YWdlIGZvciBiYXRjaCBzaXplIHRvbyBsYXJnZSBlcnJvci4KIFRoZSBlcnJvciBjYW4gYmUg
YXR0YWNoZWQgYXMgZXJyb3IgZGV0YWlscyBpbiB0aGUgcmV0dXJuZWQgcnBjIFN0YXR1cyBm
b3IKIG1vcmUgc3RydWN0dXJlZCBlcnJvciBoYW5kbGluZyBpbiB0aGUgY2xpZW50LgoKCwoD
BAsBEgSvAggeCpYBCgQECwIAEgSyAgIbGocBIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVt
cyB0aGF0IGFyZSBzdXBwb3J0ZWQgaW4gYSBzaW5nbGUgYmF0Y2guIFRoaXMgaXMKIHJldHVy
bmVkIGFzIGEgaGludCB0byB0aGUgY2xpZW50IHRvIGFkanVzdCB0aGUgYmF0Y2ggc2l6ZS4K
Cg0KBQQLAgAFEgSyAgIHCg0KBQQLAgABEgSyAggWCg0KBQQLAgADEgSyAhkaCksKBAQLAgES
BLUCAkQaPSBPcHRpb25hbC4gVGhlIGVycm9yIG1lc3NhZ2UgdGhhdCBpcyByZXR1cm5lZCB0
byB0aGUgY2xpZW50LgoKDQoFBAsCAQUSBLUCAggKDQoFBAsCAQESBLUCCRYKDQoFBAsCAQMS
BLUCGRoKDQoFBAsCAQgSBLUCG0MKEAoIBAsCAQicCAASBLUCHEJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::CreateMetastorePartitionRequest ===
    # Fields for CreateMetastorePartitionRequest
    # Field: parent Type: 9 ()
    # Field: metastore_partition Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartition)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsRequest ===
    # Fields for BatchCreateMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.bigquery.storage.v1alpha.CreateMetastorePartitionRequest)
    # Field: skip_existing_partitions Type: 8 ()
    # Field: trace_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsResponse ===
    # Fields for BatchCreateMetastorePartitionsResponse
    # Field: partitions Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartition)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchDeleteMetastorePartitionsRequest ===
    # Fields for BatchDeleteMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: partition_values Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartitionValues)
    # Field: trace_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::UpdateMetastorePartitionRequest ===
    # Fields for UpdateMetastorePartitionRequest
    # Field: metastore_partition Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartition)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsRequest ===
    # Fields for BatchUpdateMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.bigquery.storage.v1alpha.UpdateMetastorePartitionRequest)
    # Field: trace_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsResponse ===
    # Fields for BatchUpdateMetastorePartitionsResponse
    # Field: partitions Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartition)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsRequest ===
    # Fields for ListMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: trace_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsResponse ===
    # Fields for ListMetastorePartitionsResponse
    # Field: partitions Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartitionList)
    # Field: streams Type: 11 (.google.cloud.bigquery.storage.v1alpha.StreamList)

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsRequest ===
    # Fields for StreamMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: metastore_partitions Type: 11 (.google.cloud.bigquery.storage.v1alpha.MetastorePartition)
    # Field: skip_existing_partitions Type: 8 ()

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsResponse ===
    # Fields for StreamMetastorePartitionsResponse
    # Field: total_partitions_streamed_count Type: 3 ()
    # Field: total_partitions_inserted_count Type: 3 ()

# === Message: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchSizeTooLargeError ===
    # Fields for BatchSizeTooLargeError
    # Field: max_batch_size Type: 3 ()
    # Field: error_message Type: 9 ()

# === Service Client: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::MetastorePartitionServiceClient ===
package Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::MetastorePartitionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::MetastorePartitionServiceClient

Client stub representing the remote C<MetastorePartitionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

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

sub batch_create_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1alpha.MetastorePartitionService',
        method         => 'BatchCreateMetastorePartitions',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsResponse',
    });
}

sub batch_delete_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchDeleteMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1alpha.MetastorePartitionService',
        method         => 'BatchDeleteMetastorePartitions',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub batch_update_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1alpha.MetastorePartitionService',
        method         => 'BatchUpdateMetastorePartitions',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsResponse',
    });
}

sub list_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1alpha.MetastorePartitionService',
        method         => 'ListMetastorePartitions',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsResponse',
    });
}

sub stream_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1alpha.MetastorePartitionService',
        method         => 'StreamMetastorePartitions',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1alpha/metastore_partition.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition;

    my $msg = Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::CreateMetastorePartitionRequest->new({
        parent => $parent,
        metastore_partition => $metastore_partition,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::CreateMetastorePartitionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1alpha/metastore_partition.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::CreateMetastorePartitionRequest

Request message for CreateMetastorePartition. The MetastorePartition is
uniquely identified by values, which is an ordered list. Hence, there is no
separate name or partition id field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Reference to the table to where the metastore partition to be
added, in the format of
projects/{project}/databases/{databases}/tables/{table}.

=item * C<< $msg->metastore_partition() >> / C<< $msg->metastore_partition($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition>)

Required. The metastore partition to be added.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsRequest

Request message for BatchCreateMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Reference to the table to where the metastore partitions to be
added, in the format of
projects/{project}/locations/{location}/datasets/{dataset}/tables/{table}.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::CreateMetastorePartitionRequest>)

Required. Requests to add metastore partitions to the table.

=item * C<< $msg->skip_existing_partitions() >> / C<< $msg->skip_existing_partitions($value) >>

Type: C<Bool>

Optional. Mimics the ifNotExists flag in IMetaStoreClient
add_partitions(..). If the flag is set to false, the server will return
ALREADY_EXISTS if any partition already exists. If the flag is set to true,
the server will skip existing partitions and insert only the non-existing
partitions. A maximum of 900 partitions can be inserted in a batch.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Optional. Optional trace id to be used for debugging. It is expected that
the client sets the same `trace_id` for all the batches in the same
operation, so that it is possible to tie together the logs to all the
batches in the same operation. Limited to 256 characters. This is expected,
but not required, to be globally unique.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsResponse

Response message for BatchCreateMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition>)

The list of metastore partitions that have been created.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchDeleteMetastorePartitionsRequest

Request message for BatchDeleteMetastorePartitions. The MetastorePartition is
uniquely identified by values, which is an ordered list. Hence, there is no
separate name or partition id field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Reference to the table to which these metastore partitions
belong, in the format of
projects/{project}/locations/{location}/datasets/{dataset}/tables/{table}.

=item * C<< $msg->partition_values() >> / C<< $msg->partition_values($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartitionValues>)

Required. The list of metastore partitions (identified by its values) to be
deleted. A maximum of 900 partitions can be deleted in a batch.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Optional. Optional trace id to be used for debugging. It is expected that
the client sets the same `trace_id` for all the batches in the same
operation, so that it is possible to tie together the logs to all the
batches in the same operation. This is expected, but not required, to be
globally unique.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::UpdateMetastorePartitionRequest

Request message for UpdateMetastorePartition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metastore_partition() >> / C<< $msg->metastore_partition($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition>)

Required. The metastore partition to be updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsRequest

Request message for BatchUpdateMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Reference to the table to which these metastore partitions
belong, in the format of
projects/{project}/locations/{location}/datasets/{dataset}/tables/{table}.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::UpdateMetastorePartitionRequest>)

Required. Requests to update metastore partitions in the table.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Optional. Optional trace id to be used for debugging. It is expected that
the client sets the same `trace_id` for all the batches in the same
operation, so that it is possible to tie together the logs to all the
batches in the same operation. This is expected, but not required, to be
globally unique.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsResponse

Response message for BatchUpdateMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition>)

The list of metastore partitions that have been updated.
A maximum of 900 partitions can be updated in a batch.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsRequest

Request message for ListMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Reference to the table to which these metastore partitions
belong, in the format of
projects/{project}/locations/{location}/datasets/{dataset}/tables/{table}.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. SQL text filtering statement, similar to a WHERE clause in a
query. Only supports single-row expressions.  Aggregate functions are not
supported.

Examples: "int_field > 5"
          "date_field = CAST('2014-9-27' as DATE)"
          "nullable_field is not NULL"
          "st_equals(geo_field, st_geofromtext("POINT(2, 2)"))"
          "numeric_field BETWEEN 1.0 AND 5.0"
Restricted to a maximum length for 1 MB.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Optional. Optional trace id to be used for debugging. It is expected that
the client sets the same `trace_id` for all the batches in the same
operation, so that it is possible to tie together the logs to all the
batches in the same operation. Limited to 256 characters. This is expected,
but not required, to be globally unique.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsResponse

Response message for ListMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartitionList>)

The list of partitions.

=item * C<< $msg->streams() >> / C<< $msg->streams($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::StreamList>)

The list of streams.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsRequest

The top-level message sent by the client to the
[Partitions.StreamMetastorePartitions][] method.
Follows the default gRPC streaming maximum size of 4 MB.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Reference to the table to where the partition to be added, in the
format of
projects/{project}/locations/{location}/datasets/{dataset}/tables/{table}.

=item * C<< $msg->metastore_partitions() >> / C<< $msg->metastore_partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1alpha::Partition::MetastorePartition>)

Optional. A list of metastore partitions to be added to the table.

=item * C<< $msg->skip_existing_partitions() >> / C<< $msg->skip_existing_partitions($value) >>

Type: C<Bool>

Optional. Mimics the ifNotExists flag in IMetaStoreClient
add_partitions(..). If the flag is set to false, the server will return
ALREADY_EXISTS on commit if any partition already exists. If the flag is
set to true:
 1) the server will skip existing partitions
 insert only the non-existing partitions as part of the commit.
 2) The client must set the `skip_existing_partitions` field to true for
 all requests in the stream.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsResponse

This is the response message sent by the server
to the client for the [Partitions.StreamMetastorePartitions][] method when
the commit is successful. Server will close the stream after sending this
message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->total_partitions_streamed_count() >> / C<< $msg->total_partitions_streamed_count($value) >>

Type: C<Int64>

Total count of partitions streamed by the client during the lifetime of the
stream. This is only set in the final response message before closing the
stream.

=item * C<< $msg->total_partitions_inserted_count() >> / C<< $msg->total_partitions_inserted_count($value) >>

Type: C<Int64>

Total count of partitions inserted by the server during the lifetime of the
stream. This is only set in the final response message before closing the
stream.

=back

=head2 Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchSizeTooLargeError

Structured custom error message for batch size too large error.
The error can be attached as error details in the returned rpc Status for
more structured error handling in the client.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->max_batch_size() >> / C<< $msg->max_batch_size($value) >>

Type: C<Int64>

The maximum number of items that are supported in a single batch. This is
returned as a hint to the client to adjust the batch size.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

Optional. The error message that is returned to the client.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
