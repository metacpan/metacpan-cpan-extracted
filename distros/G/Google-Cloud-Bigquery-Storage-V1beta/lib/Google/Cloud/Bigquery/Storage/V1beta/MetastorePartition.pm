package Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition;

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
    eval { require Google::Cloud::Bigquery::Storage::V1beta::Partition };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGEvbWV0YXN0b3JlX3BhcnRp
dGlvbi5wcm90bxIkZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhGhxnb29n
bGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxo0Z29vZ2xlL2Nsb3VkL2JpZ3F1ZXJ5L3N0b3JhZ2UvdjFiZXRhL3BhcnRpdGlvbi5wcm90
bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRf
bWFzay5wcm90byLQAQofQ3JlYXRlTWV0YXN0b3JlUGFydGl0aW9uUmVxdWVzdBI9CgZwYXJl
bnQYASABKAlCJeBBAvpBHwodYmlncXVlcnkuZ29vZ2xlYXBpcy5jb20vVGFibGVSBnBhcmVu
dBJuChNtZXRhc3RvcmVfcGFydGl0aW9uGAIgASgLMjguZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5
LnN0b3JhZ2UudjFiZXRhLk1ldGFzdG9yZVBhcnRpdGlvbkID4EECUhJtZXRhc3RvcmVQYXJ0
aXRpb24irQIKJUJhdGNoQ3JlYXRlTWV0YXN0b3JlUGFydGl0aW9uc1JlcXVlc3QSPQoGcGFy
ZW50GAEgASgJQiXgQQL6QR8KHWJpZ3F1ZXJ5Lmdvb2dsZWFwaXMuY29tL1RhYmxlUgZwYXJl
bnQSZgoIcmVxdWVzdHMYAiADKAsyRS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52
MWJldGEuQ3JlYXRlTWV0YXN0b3JlUGFydGl0aW9uUmVxdWVzdEID4EECUghyZXF1ZXN0cxI9
Chhza2lwX2V4aXN0aW5nX3BhcnRpdGlvbnMYAyABKAhCA+BBAVIWc2tpcEV4aXN0aW5nUGFy
dGl0aW9ucxIeCgh0cmFjZV9pZBgEIAEoCUID4EEBUgd0cmFjZUlkIoIBCiZCYXRjaENyZWF0
ZU1ldGFzdG9yZVBhcnRpdGlvbnNSZXNwb25zZRJYCgpwYXJ0aXRpb25zGAEgAygLMjguZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhLk1ldGFzdG9yZVBhcnRpdGlvblIK
cGFydGl0aW9ucyL2AQolQmF0Y2hEZWxldGVNZXRhc3RvcmVQYXJ0aXRpb25zUmVxdWVzdBI9
CgZwYXJlbnQYASABKAlCJeBBAvpBHwodYmlncXVlcnkuZ29vZ2xlYXBpcy5jb20vVGFibGVS
BnBhcmVudBJuChBwYXJ0aXRpb25fdmFsdWVzGAIgAygLMj4uZ29vZ2xlLmNsb3VkLmJpZ3F1
ZXJ5LnN0b3JhZ2UudjFiZXRhLk1ldGFzdG9yZVBhcnRpdGlvblZhbHVlc0ID4EECUg9wYXJ0
aXRpb25WYWx1ZXMSHgoIdHJhY2VfaWQYBCABKAlCA+BBAVIHdHJhY2VJZCLTAQofVXBkYXRl
TWV0YXN0b3JlUGFydGl0aW9uUmVxdWVzdBJuChNtZXRhc3RvcmVfcGFydGl0aW9uGAEgASgL
MjguZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhLk1ldGFzdG9yZVBhcnRp
dGlvbkID4EECUhJtZXRhc3RvcmVQYXJ0aXRpb24SQAoLdXBkYXRlX21hc2sYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2si7gEKJUJhdGNoVXBk
YXRlTWV0YXN0b3JlUGFydGl0aW9uc1JlcXVlc3QSPQoGcGFyZW50GAEgASgJQiXgQQL6QR8K
HWJpZ3F1ZXJ5Lmdvb2dsZWFwaXMuY29tL1RhYmxlUgZwYXJlbnQSZgoIcmVxdWVzdHMYAiAD
KAsyRS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEuVXBkYXRlTWV0YXN0
b3JlUGFydGl0aW9uUmVxdWVzdEID4EECUghyZXF1ZXN0cxIeCgh0cmFjZV9pZBgEIAEoCUID
4EEBUgd0cmFjZUlkIoIBCiZCYXRjaFVwZGF0ZU1ldGFzdG9yZVBhcnRpdGlvbnNSZXNwb25z
ZRJYCgpwYXJ0aXRpb25zGAEgAygLMjguZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2Uu
djFiZXRhLk1ldGFzdG9yZVBhcnRpdGlvblIKcGFydGl0aW9ucyKcAQoeTGlzdE1ldGFzdG9y
ZVBhcnRpdGlvbnNSZXF1ZXN0Ej0KBnBhcmVudBgBIAEoCUIl4EEC+kEfCh1iaWdxdWVyeS5n
b29nbGVhcGlzLmNvbS9UYWJsZVIGcGFyZW50EhsKBmZpbHRlchgCIAEoCUID4EEBUgZmaWx0
ZXISHgoIdHJhY2VfaWQYAyABKAlCA+BBAVIHdHJhY2VJZCLbAQofTGlzdE1ldGFzdG9yZVBh
cnRpdGlvbnNSZXNwb25zZRJeCgpwYXJ0aXRpb25zGAEgASgLMjwuZ29vZ2xlLmNsb3VkLmJp
Z3F1ZXJ5LnN0b3JhZ2UudjFiZXRhLk1ldGFzdG9yZVBhcnRpdGlvbkxpc3RIAFIKcGFydGl0
aW9ucxJMCgdzdHJlYW1zGAIgASgLMjAuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2Uu
djFiZXRhLlN0cmVhbUxpc3RIAFIHc3RyZWFtc0IKCghyZXNwb25zZSKSAgogU3RyZWFtTWV0
YXN0b3JlUGFydGl0aW9uc1JlcXVlc3QSPQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHWJpZ3F1
ZXJ5Lmdvb2dsZWFwaXMuY29tL1RhYmxlUgZwYXJlbnQScAoUbWV0YXN0b3JlX3BhcnRpdGlv
bnMYAiADKAsyOC5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEuTWV0YXN0
b3JlUGFydGl0aW9uQgPgQQFSE21ldGFzdG9yZVBhcnRpdGlvbnMSPQoYc2tpcF9leGlzdGlu
Z19wYXJ0aXRpb25zGAMgASgIQgPgQQFSFnNraXBFeGlzdGluZ1BhcnRpdGlvbnMisQEKIVN0
cmVhbU1ldGFzdG9yZVBhcnRpdGlvbnNSZXNwb25zZRJFCh90b3RhbF9wYXJ0aXRpb25zX3N0
cmVhbWVkX2NvdW50GAIgASgDUhx0b3RhbFBhcnRpdGlvbnNTdHJlYW1lZENvdW50EkUKH3Rv
dGFsX3BhcnRpdGlvbnNfaW5zZXJ0ZWRfY291bnQYAyABKANSHHRvdGFsUGFydGl0aW9uc0lu
c2VydGVkQ291bnQiaAoWQmF0Y2hTaXplVG9vTGFyZ2VFcnJvchIkCg5tYXhfYmF0Y2hfc2l6
ZRgBIAEoA1IMbWF4QmF0Y2hTaXplEigKDWVycm9yX21lc3NhZ2UYAiABKAlCA+BBAVIMZXJy
b3JNZXNzYWdlMtEKChlNZXRhc3RvcmVQYXJ0aXRpb25TZXJ2aWNlEo4CCh5CYXRjaENyZWF0
ZU1ldGFzdG9yZVBhcnRpdGlvbnMSSy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52
MWJldGEuQmF0Y2hDcmVhdGVNZXRhc3RvcmVQYXJ0aXRpb25zUmVxdWVzdBpMLmdvb2dsZS5j
bG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YS5CYXRjaENyZWF0ZU1ldGFzdG9yZVBhcnRp
dGlvbnNSZXNwb25zZSJRgtPkkwJLIkYvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9kYXRh
c2V0cy8qL3RhYmxlcy8qfS9wYXJ0aXRpb25zOmJhdGNoQ3JlYXRlOgEqEtgBCh5CYXRjaERl
bGV0ZU1ldGFzdG9yZVBhcnRpdGlvbnMSSy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFn
ZS52MWJldGEuQmF0Y2hEZWxldGVNZXRhc3RvcmVQYXJ0aXRpb25zUmVxdWVzdBoWLmdvb2ds
ZS5wcm90b2J1Zi5FbXB0eSJRgtPkkwJLIkYvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9k
YXRhc2V0cy8qL3RhYmxlcy8qfS9wYXJ0aXRpb25zOmJhdGNoRGVsZXRlOgEqEo4CCh5CYXRj
aFVwZGF0ZU1ldGFzdG9yZVBhcnRpdGlvbnMSSy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3Rv
cmFnZS52MWJldGEuQmF0Y2hVcGRhdGVNZXRhc3RvcmVQYXJ0aXRpb25zUmVxdWVzdBpMLmdv
b2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YS5CYXRjaFVwZGF0ZU1ldGFzdG9y
ZVBhcnRpdGlvbnNSZXNwb25zZSJRgtPkkwJLIkYvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMv
Ki9kYXRhc2V0cy8qL3RhYmxlcy8qfS9wYXJ0aXRpb25zOmJhdGNoVXBkYXRlOgEqEoQCChdM
aXN0TWV0YXN0b3JlUGFydGl0aW9ucxJELmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdl
LnYxYmV0YS5MaXN0TWV0YXN0b3JlUGFydGl0aW9uc1JlcXVlc3QaRS5nb29nbGUuY2xvdWQu
YmlncXVlcnkuc3RvcmFnZS52MWJldGEuTGlzdE1ldGFzdG9yZVBhcnRpdGlvbnNSZXNwb25z
ZSJcgtPkkwJNEksvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9kYXRh
c2V0cy8qL3RhYmxlcy8qfS9wYXJ0aXRpb25zOmxpc3TaQQZwYXJlbnQSsgEKGVN0cmVhbU1l
dGFzdG9yZVBhcnRpdGlvbnMSRi5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJl
dGEuU3RyZWFtTWV0YXN0b3JlUGFydGl0aW9uc1JlcXVlc3QaRy5nb29nbGUuY2xvdWQuYmln
cXVlcnkuc3RvcmFnZS52MWJldGEuU3RyZWFtTWV0YXN0b3JlUGFydGl0aW9uc1Jlc3BvbnNl
IgAoATABGnvKQR5iaWdxdWVyeXN0b3JhZ2UuZ29vZ2xlYXBpcy5jb23SQVdodHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2JpZ3F1ZXJ5LGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CtgIKKGNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnku
c3RvcmFnZS52MWJldGFCHk1ldGFzdG9yZVBhcnRpdGlvblNlcnZpY2VQcm90b1ABWkJjbG91
ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3N0b3JhZ2UvYXBpdjFiZXRhL3N0b3JhZ2VwYjtz
dG9yYWdlcGKqAiRHb29nbGUuQ2xvdWQuQmlnUXVlcnkuU3RvcmFnZS5WMUJldGHKAiRHb29n
bGVcQ2xvdWRcQmlnUXVlcnlcU3RvcmFnZVxWMWJldGHqQVUKHWJpZ3F1ZXJ5Lmdvb2dsZWFw
aXMuY29tL1RhYmxlEjRwcm9qZWN0cy97cHJvamVjdH0vZGF0YXNldHMve2RhdGFzZXR9L3Rh
Ymxlcy97dGFibGV9SuxaCgcSBQ4AuAIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
bnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYAPgoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgBBCgkKAggl
EgMaAEEKCAoBCBIDGwBZCgkKAggLEgMbAFkKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBID
HQA/CgkKAggIEgMdAD8KCAoBCBIDHgBBCgkKAggBEgMeAEEKCAoBCBIDHwBCCgkKAggpEgMf
AEIKCQoBCBIEIAAjAgoMCgQInQgAEgQgACMCCsABCgIGABIEKABaARqzASBCaWdRdWVyeSBN
ZXRhc3RvcmUgUGFydGl0aW9uIFNlcnZpY2UgQVBJLgogIFRoaXMgc2VydmljZSBpcyB1c2Vk
IGZvciBtYW5hZ2luZyBtZXRhc3RvcmUgcGFydGl0aW9ucyBpbiBCaWdRdWVyeQogIG1ldGFz
dG9yZS4gVGhlIHNlcnZpY2Ugc3VwcG9ydHMgb25seSBiYXRjaCBvcGVyYXRpb25zIGZvciB3
cml0ZS4KCgoKAwYAARIDKAghCgoKAwYAAxIDKQJGCgwKBQYAA5kIEgMpAkYKCwoDBgADEgQq
Aiw3Cg0KBQYAA5oIEgQqAiw3CjUKBAYAAgASBC8CNQMaJyBBZGRzIG1ldGFzdG9yZSBwYXJ0
aXRpb25zIHRvIGEgdGFibGUuCgoMCgUGAAIAARIDLwYkCgwKBQYAAgACEgMvJUoKDAoFBgAC
AAMSAzAPNQoNCgUGAAIABBIEMQQ0BgoRCgkGAAIABLDKvCISBDEENAYKOgoEBgACARIEOAI+
AxosIERlbGV0ZXMgbWV0YXN0b3JlIHBhcnRpdGlvbnMgZnJvbSBhIHRhYmxlLgoKDAoFBgAC
AQESAzgGJAoMCgUGAAIBAhIDOCVKCgwKBQYAAgEDEgM5DyQKDQoFBgACAQQSBDoEPQYKEQoJ
BgACAQSwyrwiEgQ6BD0GCjgKBAYAAgISBEECRwMaKiBVcGRhdGVzIG1ldGFzdG9yZSBwYXJ0
aXRpb25zIGluIGEgdGFibGUuCgoMCgUGAAICARIDQQYkCgwKBQYAAgICEgNBJUoKDAoFBgAC
AgMSA0IPNQoNCgUGAAICBBIEQwRGBgoRCgkGAAICBLDKvCISBEMERgYKNwoEBgACAxIESgJQ
AxopIEdldHMgbWV0YXN0b3JlIHBhcnRpdGlvbnMgZnJvbSBhIHRhYmxlLgoKDAoFBgACAwES
A0oGHQoMCgUGAAIDAhIDSh48CgwKBQYAAgMDEgNLDy4KDQoFBgACAwQSBEwETgYKEQoJBgAC
AwSwyrwiEgRMBE4GCgwKBQYAAgMEEgNPBDQKDwoIBgACAwSbCAASA08ENAqhAwoEBgACBBIE
WAJZOxqSAyBUaGlzIGlzIGEgYmktZGkgc3RyZWFtaW5nIHJwYyBtZXRob2QgdGhhdCBhbGxv
d3MgdGhlIGNsaWVudCB0byBzZW5kCiBhIHN0cmVhbSBvZiBwYXJ0aXRpb25zIGFuZCBjb21t
aXQgYWxsIG9mIHRoZW0gYXRvbWljYWxseSBhdCB0aGUgZW5kLgogSWYgdGhlIGNvbW1pdCBp
cyBzdWNjZXNzZnVsLCB0aGUgc2VydmVyIHdpbGwgcmV0dXJuIGEKIHJlc3BvbnNlIGFuZCBj
bG9zZSB0aGUgc3RyZWFtLiBJZiB0aGUgY29tbWl0IGZhaWxzIChkdWUgdG8gZHVwbGljYXRl
CiBwYXJ0aXRpb25zIG9yIG90aGVyIHJlYXNvbiksIHRoZSBzZXJ2ZXIgd2lsbCBjbG9zZSB0
aGUgc3RyZWFtIHdpdGggYW4KIGVycm9yLiBUaGlzIG1ldGhvZCBpcyBvbmx5IGF2YWlsYWJs
ZSB2aWEgdGhlIGdSUEMgQVBJIChub3QgUkVTVCkuCgoMCgUGAAIEARIDWAYfCgwKBQYAAgQF
EgNYICYKDAoFBgACBAISA1gnRwoMCgUGAAIEBhIDWQ8VCgwKBQYAAgQDEgNZFjcKyQEKAgQA
EgRfAGsBGrwBIFJlcXVlc3QgbWVzc2FnZSBmb3IgQ3JlYXRlTWV0YXN0b3JlUGFydGl0aW9u
LiBUaGUgTWV0YXN0b3JlUGFydGl0aW9uIGlzCiB1bmlxdWVseSBpZGVudGlmaWVkIGJ5IHZh
bHVlcywgd2hpY2ggaXMgYW4gb3JkZXJlZCBsaXN0LiBIZW5jZSwgdGhlcmUgaXMgbm8KIHNl
cGFyYXRlIG5hbWUgb3IgcGFydGl0aW9uIGlkIGZpZWxkLgoKCgoDBAABEgNfCCcKqwEKBAQA
AgASBGMCZgQanAEgUmVxdWlyZWQuIFJlZmVyZW5jZSB0byB0aGUgdGFibGUgdG8gd2hlcmUg
dGhlIG1ldGFzdG9yZSBwYXJ0aXRpb24gdG8gYmUKIGFkZGVkLCBpbiB0aGUgZm9ybWF0IG9m
CiBwcm9qZWN0cy97cHJvamVjdH0vZGF0YWJhc2VzL3tkYXRhYmFzZXN9L3RhYmxlcy97dGFi
bGV9LgoKDAoFBAACAAUSA2MCCAoMCgUEAAIAARIDYwkPCgwKBQQAAgADEgNjEhMKDQoFBAAC
AAgSBGMUZgMKDwoIBAACAAicCAASA2QEKgoOCgcEAAIACJ8IEgNlBE8KPgoEBAACARIEaQJq
LxowIFJlcXVpcmVkLiBUaGUgbWV0YXN0b3JlIHBhcnRpdGlvbiB0byBiZSBhZGRlZC4KCgwK
BQQAAgEGEgNpAhQKDAoFBAACAQESA2kVKAoMCgUEAAIBAxIDaSssCgwKBQQAAgEIEgNqBi4K
DwoIBAACAQicCAASA2oHLQpCCgIEARIFbgCIAQEaNSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEJh
dGNoQ3JlYXRlTWV0YXN0b3JlUGFydGl0aW9ucy4KCgoKAwQBARIDbggtCr4BCgQEAQIAEgRy
AnUEGq8BIFJlcXVpcmVkLiBSZWZlcmVuY2UgdG8gdGhlIHRhYmxlIHRvIHdoZXJlIHRoZSBt
ZXRhc3RvcmUgcGFydGl0aW9ucyB0byBiZQogYWRkZWQsIGluIHRoZSBmb3JtYXQgb2YKIHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhc2V0cy97ZGF0YXNl
dH0vdGFibGVzL3t0YWJsZX0uCgoMCgUEAQIABRIDcgIICgwKBQQBAgABEgNyCQ8KDAoFBAEC
AAMSA3ISEwoNCgUEAQIACBIEchR1AwoPCggEAQIACJwIABIDcwQqCg4KBwQBAgAInwgSA3QE
TwpMCgQEAQIBEgR4AnkvGj4gUmVxdWlyZWQuIFJlcXVlc3RzIHRvIGFkZCBtZXRhc3RvcmUg
cGFydGl0aW9ucyB0byB0aGUgdGFibGUuCgoMCgUEAQIBBBIDeAIKCgwKBQQBAgEGEgN4CyoK
DAoFBAECAQESA3grMwoMCgUEAQIBAxIDeDY3CgwKBQQBAgEIEgN5Bi4KDwoIBAECAQicCAAS
A3kHLQrwAgoEBAECAhIEgAECTRrhAiBPcHRpb25hbC4gTWltaWNzIHRoZSBpZk5vdEV4aXN0
cyBmbGFnIGluIElNZXRhU3RvcmVDbGllbnQKIGFkZF9wYXJ0aXRpb25zKC4uKS4gSWYgdGhl
IGZsYWcgaXMgc2V0IHRvIGZhbHNlLCB0aGUgc2VydmVyIHdpbGwgcmV0dXJuCiBBTFJFQURZ
X0VYSVNUUyBpZiBhbnkgcGFydGl0aW9uIGFscmVhZHkgZXhpc3RzLiBJZiB0aGUgZmxhZyBp
cyBzZXQgdG8gdHJ1ZSwKIHRoZSBzZXJ2ZXIgd2lsbCBza2lwIGV4aXN0aW5nIHBhcnRpdGlv
bnMgYW5kIGluc2VydCBvbmx5IHRoZSBub24tZXhpc3RpbmcKIHBhcnRpdGlvbnMuIEEgbWF4
aW11bSBvZiA5MDAgcGFydGl0aW9ucyBjYW4gYmUgaW5zZXJ0ZWQgaW4gYSBiYXRjaC4KCg0K
BQQBAgIFEgSAAQIGCg0KBQQBAgIBEgSAAQcfCg0KBQQBAgIDEgSAASIjCg0KBQQBAgIIEgSA
ASRMChAKCAQBAgIInAgAEgSAASVLCt0CCgQEAQIDEgSHAQI/Gs4CIE9wdGlvbmFsLiBPcHRp
b25hbCB0cmFjZSBpZCB0byBiZSB1c2VkIGZvciBkZWJ1Z2dpbmcuIEl0IGlzIGV4cGVjdGVk
IHRoYXQKIHRoZSBjbGllbnQgc2V0cyB0aGUgc2FtZSBgdHJhY2VfaWRgIGZvciBhbGwgdGhl
IGJhdGNoZXMgaW4gdGhlIHNhbWUKIG9wZXJhdGlvbiwgc28gdGhhdCBpdCBpcyBwb3NzaWJs
ZSB0byB0aWUgdG9nZXRoZXIgdGhlIGxvZ3MgdG8gYWxsIHRoZQogYmF0Y2hlcyBpbiB0aGUg
c2FtZSBvcGVyYXRpb24uIExpbWl0ZWQgdG8gMjU2IGNoYXJhY3RlcnMuIFRoaXMgaXMgZXhw
ZWN0ZWQsCiBidXQgbm90IHJlcXVpcmVkLCB0byBiZSBnbG9iYWxseSB1bmlxdWUuCgoNCgUE
AQIDBRIEhwECCAoNCgUEAQIDARIEhwEJEQoNCgUEAQIDAxIEhwEUFQoNCgUEAQIDCBIEhwEW
PgoQCggEAQIDCJwIABIEhwEXPQpECgIEAhIGiwEAjgEBGjYgUmVzcG9uc2UgbWVzc2FnZSBm
b3IgQmF0Y2hDcmVhdGVNZXRhc3RvcmVQYXJ0aXRpb25zLgoKCwoDBAIBEgSLAQguCkgKBAQC
AgASBI0BAi0aOiBUaGUgbGlzdCBvZiBtZXRhc3RvcmUgcGFydGl0aW9ucyB0aGF0IGhhdmUg
YmVlbiBjcmVhdGVkLgoKDQoFBAICAAQSBI0BAgoKDQoFBAICAAYSBI0BCx0KDQoFBAICAAES
BI0BHigKDQoFBAICAAMSBI0BKywK0QEKAgQDEgaTAQCnAQEawgEgUmVxdWVzdCBtZXNzYWdl
IGZvciBCYXRjaERlbGV0ZU1ldGFzdG9yZVBhcnRpdGlvbnMuIFRoZSBNZXRhc3RvcmVQYXJ0
aXRpb24gaXMKIHVuaXF1ZWx5IGlkZW50aWZpZWQgYnkgdmFsdWVzLCB3aGljaCBpcyBhbiBv
cmRlcmVkIGxpc3QuIEhlbmNlLCB0aGVyZSBpcyBubwogc2VwYXJhdGUgbmFtZSBvciBwYXJ0
aXRpb24gaWQgZmllbGQuCgoLCgMEAwESBJMBCC0KvQEKBAQDAgASBpcBApoBBBqsASBSZXF1
aXJlZC4gUmVmZXJlbmNlIHRvIHRoZSB0YWJsZSB0byB3aGljaCB0aGVzZSBtZXRhc3RvcmUg
cGFydGl0aW9ucwogYmVsb25nLCBpbiB0aGUgZm9ybWF0IG9mCiBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YXNldHMve2RhdGFzZXR9L3RhYmxlcy97dGFi
bGV9LgoKDQoFBAMCAAUSBJcBAggKDQoFBAMCAAESBJcBCQ8KDQoFBAMCAAMSBJcBEhMKDwoF
BAMCAAgSBpcBFJoBAwoQCggEAwIACJwIABIEmAEEKgoPCgcEAwIACJ8IEgSZAQRPCp8BCgQE
AwIBEgaeAQKfAS8ajgEgUmVxdWlyZWQuIFRoZSBsaXN0IG9mIG1ldGFzdG9yZSBwYXJ0aXRp
b25zIChpZGVudGlmaWVkIGJ5IGl0cyB2YWx1ZXMpIHRvIGJlCiBkZWxldGVkLiBBIG1heGlt
dW0gb2YgOTAwIHBhcnRpdGlvbnMgY2FuIGJlIGRlbGV0ZWQgaW4gYSBiYXRjaC4KCg0KBQQD
AgEEEgSeAQIKCg0KBQQDAgEGEgSeAQsjCg0KBQQDAgEBEgSeASQ0Cg0KBQQDAgEDEgSeATc4
Cg0KBQQDAgEIEgSfAQYuChAKCAQDAgEInAgAEgSfAQctCsICCgQEAwICEgSmAQI/GrMCIE9w
dGlvbmFsLiBPcHRpb25hbCB0cmFjZSBpZCB0byBiZSB1c2VkIGZvciBkZWJ1Z2dpbmcuIEl0
IGlzIGV4cGVjdGVkIHRoYXQKIHRoZSBjbGllbnQgc2V0cyB0aGUgc2FtZSBgdHJhY2VfaWRg
IGZvciBhbGwgdGhlIGJhdGNoZXMgaW4gdGhlIHNhbWUKIG9wZXJhdGlvbiwgc28gdGhhdCBp
dCBpcyBwb3NzaWJsZSB0byB0aWUgdG9nZXRoZXIgdGhlIGxvZ3MgdG8gYWxsIHRoZQogYmF0
Y2hlcyBpbiB0aGUgc2FtZSBvcGVyYXRpb24uIFRoaXMgaXMgZXhwZWN0ZWQsIGJ1dCBub3Qg
cmVxdWlyZWQsIHRvIGJlCiBnbG9iYWxseSB1bmlxdWUuCgoNCgUEAwICBRIEpgECCAoNCgUE
AwICARIEpgEJEQoNCgUEAwICAxIEpgEUFQoNCgUEAwICCBIEpgEWPgoQCggEAwICCJwIABIE
pgEXPQo9CgIEBBIGqgEAsgEBGi8gUmVxdWVzdCBtZXNzYWdlIGZvciBVcGRhdGVNZXRhc3Rv
cmVQYXJ0aXRpb24uCgoLCgMEBAESBKoBCCcKQgoEBAQCABIGrAECrQEvGjIgUmVxdWlyZWQu
IFRoZSBtZXRhc3RvcmUgcGFydGl0aW9uIHRvIGJlIHVwZGF0ZWQuCgoNCgUEBAIABhIErAEC
FAoNCgUEBAIAARIErAEVKAoNCgUEBAIAAxIErAErLAoNCgUEBAIACBIErQEGLgoQCggEBAIA
CJwIABIErQEHLQo5CgQEBAIBEgawAQKxAS8aKSBPcHRpb25hbC4gVGhlIGxpc3Qgb2YgZmll
bGRzIHRvIHVwZGF0ZS4KCg0KBQQEAgEGEgSwAQIbCg0KBQQEAgEBEgSwARwnCg0KBQQEAgED
EgSwASorCg0KBQQEAgEIEgSxAQYuChAKCAQEAgEInAgAEgSxAQctCkMKAgQFEga1AQDIAQEa
NSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEJhdGNoVXBkYXRlTWV0YXN0b3JlUGFydGl0aW9ucy4K
CgsKAwQFARIEtQEILQq9AQoEBAUCABIGuQECvAEEGqwBIFJlcXVpcmVkLiBSZWZlcmVuY2Ug
dG8gdGhlIHRhYmxlIHRvIHdoaWNoIHRoZXNlIG1ldGFzdG9yZSBwYXJ0aXRpb25zCiBiZWxv
bmcsIGluIHRoZSBmb3JtYXQgb2YKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9kYXRhc2V0cy97ZGF0YXNldH0vdGFibGVzL3t0YWJsZX0uCgoNCgUEBQIABRIE
uQECCAoNCgUEBQIAARIEuQEJDwoNCgUEBQIAAxIEuQESEwoPCgUEBQIACBIGuQEUvAEDChAK
CAQFAgAInAgAEgS6AQQqCg8KBwQFAgAInwgSBLsBBE8KUQoEBAUCARIGvwECwAEvGkEgUmVx
dWlyZWQuIFJlcXVlc3RzIHRvIHVwZGF0ZSBtZXRhc3RvcmUgcGFydGl0aW9ucyBpbiB0aGUg
dGFibGUuCgoNCgUEBQIBBBIEvwECCgoNCgUEBQIBBhIEvwELKgoNCgUEBQIBARIEvwErMwoN
CgUEBQIBAxIEvwE2NwoNCgUEBQIBCBIEwAEGLgoQCggEBQIBCJwIABIEwAEHLQrCAgoEBAUC
AhIExwECPxqzAiBPcHRpb25hbC4gT3B0aW9uYWwgdHJhY2UgaWQgdG8gYmUgdXNlZCBmb3Ig
ZGVidWdnaW5nLiBJdCBpcyBleHBlY3RlZCB0aGF0CiB0aGUgY2xpZW50IHNldHMgdGhlIHNh
bWUgYHRyYWNlX2lkYCBmb3IgYWxsIHRoZSBiYXRjaGVzIGluIHRoZSBzYW1lCiBvcGVyYXRp
b24sIHNvIHRoYXQgaXQgaXMgcG9zc2libGUgdG8gdGllIHRvZ2V0aGVyIHRoZSBsb2dzIHRv
IGFsbCB0aGUKIGJhdGNoZXMgaW4gdGhlIHNhbWUgb3BlcmF0aW9uLiBUaGlzIGlzIGV4cGVj
dGVkLCBidXQgbm90IHJlcXVpcmVkLCB0byBiZQogZ2xvYmFsbHkgdW5pcXVlLgoKDQoFBAUC
AgUSBMcBAggKDQoFBAUCAgESBMcBCREKDQoFBAUCAgMSBMcBFBUKDQoFBAUCAggSBMcBFj4K
EAoIBAUCAgicCAASBMcBFz0KRAoCBAYSBssBAM8BARo2IFJlc3BvbnNlIG1lc3NhZ2UgZm9y
IEJhdGNoVXBkYXRlTWV0YXN0b3JlUGFydGl0aW9ucy4KCgsKAwQGARIEywEILgqAAQoEBAYC
ABIEzgECLRpyIFRoZSBsaXN0IG9mIG1ldGFzdG9yZSBwYXJ0aXRpb25zIHRoYXQgaGF2ZSBi
ZWVuIHVwZGF0ZWQuCiBBIG1heGltdW0gb2YgOTAwIHBhcnRpdGlvbnMgY2FuIGJlIHVwZGF0
ZWQgaW4gYSBiYXRjaC4KCg0KBQQGAgAEEgTOAQIKCg0KBQQGAgAGEgTOAQsdCg0KBQQGAgAB
EgTOAR4oCg0KBQQGAgADEgTOASssCjwKAgQHEgbSAQDvAQEaLiBSZXF1ZXN0IG1lc3NhZ2Ug
Zm9yIExpc3RNZXRhc3RvcmVQYXJ0aXRpb25zLgoKCwoDBAcBEgTSAQgmCr0BCgQEBwIAEgbW
AQLZAQQarAEgUmVxdWlyZWQuIFJlZmVyZW5jZSB0byB0aGUgdGFibGUgdG8gd2hpY2ggdGhl
c2UgbWV0YXN0b3JlIHBhcnRpdGlvbnMKIGJlbG9uZywgaW4gdGhlIGZvcm1hdCBvZgogcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFzZXRzL3tkYXRhc2V0
fS90YWJsZXMve3RhYmxlfS4KCg0KBQQHAgAFEgTWAQIICg0KBQQHAgABEgTWAQkPCg0KBQQH
AgADEgTWARITCg8KBQQHAgAIEgbWARTZAQMKEAoIBAcCAAicCAASBNcBBCoKDwoHBAcCAAif
CBIE2AEETwqjAwoEBAcCARIE5wECPRqUAyBPcHRpb25hbC4gU1FMIHRleHQgZmlsdGVyaW5n
IHN0YXRlbWVudCwgc2ltaWxhciB0byBhIFdIRVJFIGNsYXVzZSBpbiBhCiBxdWVyeS4gT25s
eSBzdXBwb3J0cyBzaW5nbGUtcm93IGV4cHJlc3Npb25zLiAgQWdncmVnYXRlIGZ1bmN0aW9u
cyBhcmUgbm90CiBzdXBwb3J0ZWQuCgogRXhhbXBsZXM6CiAqICJpbnRfZmllbGQgPiA1Igog
KiAiZGF0ZV9maWVsZCA9IENBU1QoJzIwMTQtOS0yNycgYXMgREFURSkiCiAqICJudWxsYWJs
ZV9maWVsZCBpcyBub3QgTlVMTCIKICogInN0X2VxdWFscyhnZW9fZmllbGQsIHN0X2dlb2Zy
b210ZXh0KCJQT0lOVCgyLCAyKSIpKSIKICogIm51bWVyaWNfZmllbGQgQkVUV0VFTiAxLjAg
QU5EIDUuMCIKCiBSZXN0cmljdGVkIHRvIGEgbWF4aW11bSBsZW5ndGggb2YgMSBNQi4KCg0K
BQQHAgEFEgTnAQIICg0KBQQHAgEBEgTnAQkPCg0KBQQHAgEDEgTnARITCg0KBQQHAgEIEgTn
ARQ8ChAKCAQHAgEInAgAEgTnARU7Ct0CCgQEBwICEgTuAQI/Gs4CIE9wdGlvbmFsLiBPcHRp
b25hbCB0cmFjZSBpZCB0byBiZSB1c2VkIGZvciBkZWJ1Z2dpbmcuIEl0IGlzIGV4cGVjdGVk
IHRoYXQKIHRoZSBjbGllbnQgc2V0cyB0aGUgc2FtZSBgdHJhY2VfaWRgIGZvciBhbGwgdGhl
IGJhdGNoZXMgaW4gdGhlIHNhbWUKIG9wZXJhdGlvbiwgc28gdGhhdCBpdCBpcyBwb3NzaWJs
ZSB0byB0aWUgdG9nZXRoZXIgdGhlIGxvZ3MgdG8gYWxsIHRoZQogYmF0Y2hlcyBpbiB0aGUg
c2FtZSBvcGVyYXRpb24uIExpbWl0ZWQgdG8gMjU2IGNoYXJhY3RlcnMuIFRoaXMgaXMgZXhw
ZWN0ZWQsCiBidXQgbm90IHJlcXVpcmVkLCB0byBiZSBnbG9iYWxseSB1bmlxdWUuCgoNCgUE
BwICBRIE7gECCAoNCgUEBwICARIE7gEJEQoNCgUEBwICAxIE7gEUFQoNCgUEBwICCBIE7gEW
PgoQCggEBwICCJwIABIE7gEXPQo9CgIECBIG8gEAgQIBGi8gUmVzcG9uc2UgbWVzc2FnZSBm
b3IgTGlzdE1ldGFzdG9yZVBhcnRpdGlvbnMuCgoLCgMECAESBPIBCCcK8gMKBAQICAASBvoB
AoACAxrhAyBUaGUgcmVzcG9uc2UgZGVwZW5kcyBvbiB0aGUgbnVtYmVyIG9mIG1ldGFzdG9y
ZSBwYXJ0aXRpb25zIHRvIGJlIHJldHVybmVkOwogaXQgY2FuIGJlIGEgbGlzdCBvZiBwYXJ0
aXRpb25zIG9yIGEgbGlzdCBvZgogW1JlYWRTdHJlYW1dKChodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vYmlncXVlcnkvZG9jcy9yZWZlcmVuY2Uvc3RvcmFnZS9ycGMvZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnN0b3JhZ2UudjEjcmVhZHN0cmVhbSkpCiBvYmplY3RzLiBGb3IgdGhlIHNl
Y29uZCBzaXR1YXRpb24sIHRoZSBCaWdRdWVyeSBbUmVhZCBBUEkKIFJlYWRSb3dzXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vYmlncXVlcnkvZG9jcy9yZWZlcmVuY2Uvc3RvcmFnZSNy
ZWFkX2Zyb21fYV9zZXNzaW9uX3N0cmVhbSkKIG1ldGhvZCBtdXN0IGJlIHVzZWQgdG8gc3Ry
ZWFtIHRoZSBkYXRhIGFuZCBjb252ZXJ0IGl0IGludG8gYSBsaXN0IG9mCiBwYXJ0aXRpb25z
LgoKDQoFBAgIAAESBPoBCBAKJwoEBAgCABIE/AEEKhoZIFRoZSBsaXN0IG9mIHBhcnRpdGlv
bnMuCgoNCgUECAIABhIE/AEEGgoNCgUECAIAARIE/AEbJQoNCgUECAIAAxIE/AEoKQokCgQE
CAIBEgT/AQQbGhYgVGhlIGxpc3Qgb2Ygc3RyZWFtcy4KCg0KBQQIAgEGEgT/AQQOCg0KBQQI
AgEBEgT/AQ8WCg0KBQQIAgEDEgT/ARkaCqwBCgIECRIGhgIAnAIBGp0BIFRoZSB0b3AtbGV2
ZWwgbWVzc2FnZSBzZW50IGJ5IHRoZSBjbGllbnQgdG8gdGhlCiBbUGFydGl0aW9ucy5TdHJl
YW1NZXRhc3RvcmVQYXJ0aXRpb25zXVtdIG1ldGhvZC4KIEZvbGxvd3MgdGhlIGRlZmF1bHQg
Z1JQQyBzdHJlYW1pbmcgbWF4aW11bSBzaXplIG9mIDQgTUIuCgoLCgMECQESBIYCCCgKtQEK
BAQJAgASBooCAo0CBBqkASBSZXF1aXJlZC4gUmVmZXJlbmNlIHRvIHRoZSB0YWJsZSB0byB3
aGVyZSB0aGUgcGFydGl0aW9uIHRvIGJlIGFkZGVkLCBpbiB0aGUKIGZvcm1hdCBvZgogcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFzZXRzL3tkYXRhc2V0
fS90YWJsZXMve3RhYmxlfS4KCg0KBQQJAgAFEgSKAgIICg0KBQQJAgABEgSKAgkPCg0KBQQJ
AgADEgSKAhITCg8KBQQJAgAIEgaKAhSNAgMKEAoIBAkCAAicCAASBIsCBCoKDwoHBAkCAAif
CBIEjAIETwpUCgQECQIBEgaQAgKRAi8aRCBPcHRpb25hbC4gQSBsaXN0IG9mIG1ldGFzdG9y
ZSBwYXJ0aXRpb25zIHRvIGJlIGFkZGVkIHRvIHRoZSB0YWJsZS4KCg0KBQQJAgEEEgSQAgIK
Cg0KBQQJAgEGEgSQAgsdCg0KBQQJAgEBEgSQAh4yCg0KBQQJAgEDEgSQAjU2Cg0KBQQJAgEI
EgSRAgYuChAKCAQJAgEInAgAEgSRAgctCsIDCgQECQICEgSbAgJNGrMDIE9wdGlvbmFsLiBN
aW1pY3MgdGhlIGlmTm90RXhpc3RzIGZsYWcgaW4gSU1ldGFTdG9yZUNsaWVudAogYWRkX3Bh
cnRpdGlvbnMoLi4pLiBJZiB0aGUgZmxhZyBpcyBzZXQgdG8gZmFsc2UsIHRoZSBzZXJ2ZXIg
d2lsbCByZXR1cm4KIEFMUkVBRFlfRVhJU1RTIG9uIGNvbW1pdCBpZiBhbnkgcGFydGl0aW9u
IGFscmVhZHkgZXhpc3RzLiBJZiB0aGUgZmxhZyBpcwogc2V0IHRvIHRydWU6CiAgMSkgdGhl
IHNlcnZlciB3aWxsIHNraXAgZXhpc3RpbmcgcGFydGl0aW9ucwogIGluc2VydCBvbmx5IHRo
ZSBub24tZXhpc3RpbmcgcGFydGl0aW9ucyBhcyBwYXJ0IG9mIHRoZSBjb21taXQuCiAgMikg
VGhlIGNsaWVudCBtdXN0IHNldCB0aGUgYHNraXBfZXhpc3RpbmdfcGFydGl0aW9uc2AgZmll
bGQgdG8gdHJ1ZSBmb3IKICBhbGwgcmVxdWVzdHMgaW4gdGhlIHN0cmVhbS4KCg0KBQQJAgIF
EgSbAgIGCg0KBQQJAgIBEgSbAgcfCg0KBQQJAgIDEgSbAiIjCg0KBQQJAgIIEgSbAiRMChAK
CAQJAgIInAgAEgSbAiVLCuEBCgIEChIGogIArAIBGtIBIFRoaXMgaXMgdGhlIHJlc3BvbnNl
IG1lc3NhZ2Ugc2VudCBieSB0aGUgc2VydmVyCiB0byB0aGUgY2xpZW50IGZvciB0aGUgW1Bh
cnRpdGlvbnMuU3RyZWFtTWV0YXN0b3JlUGFydGl0aW9uc11bXSBtZXRob2Qgd2hlbgogdGhl
IGNvbW1pdCBpcyBzdWNjZXNzZnVsLiBTZXJ2ZXIgd2lsbCBjbG9zZSB0aGUgc3RyZWFtIGFm
dGVyIHNlbmRpbmcgdGhpcwogbWVzc2FnZS4KCgsKAwQKARIEogIIKQqwAQoEBAoCABIEpgIC
LBqhASBUb3RhbCBjb3VudCBvZiBwYXJ0aXRpb25zIHN0cmVhbWVkIGJ5IHRoZSBjbGllbnQg
ZHVyaW5nIHRoZSBsaWZldGltZSBvZiB0aGUKIHN0cmVhbS4gVGhpcyBpcyBvbmx5IHNldCBp
biB0aGUgZmluYWwgcmVzcG9uc2UgbWVzc2FnZSBiZWZvcmUgY2xvc2luZyB0aGUKIHN0cmVh
bS4KCg0KBQQKAgAFEgSmAgIHCg0KBQQKAgABEgSmAggnCg0KBQQKAgADEgSmAiorCrABCgQE
CgIBEgSrAgIsGqEBIFRvdGFsIGNvdW50IG9mIHBhcnRpdGlvbnMgaW5zZXJ0ZWQgYnkgdGhl
IHNlcnZlciBkdXJpbmcgdGhlIGxpZmV0aW1lIG9mIHRoZQogc3RyZWFtLiBUaGlzIGlzIG9u
bHkgc2V0IGluIHRoZSBmaW5hbCByZXNwb25zZSBtZXNzYWdlIGJlZm9yZSBjbG9zaW5nIHRo
ZQogc3RyZWFtLgoKDQoFBAoCAQUSBKsCAgcKDQoFBAoCAQESBKsCCCcKDQoFBAoCAQMSBKsC
KisKygEKAgQLEgaxAgC4AgEauwEgU3RydWN0dXJlZCBjdXN0b20gZXJyb3IgbWVzc2FnZSBm
b3IgYmF0Y2ggc2l6ZSB0b28gbGFyZ2UgZXJyb3IuCiBUaGUgZXJyb3IgY2FuIGJlIGF0dGFj
aGVkIGFzIGVycm9yIGRldGFpbHMgaW4gdGhlIHJldHVybmVkIHJwYyBTdGF0dXMgZm9yCiBt
b3JlIHN0cnVjdHVyZWQgZXJyb3IgaGFuZGxpbmcgaW4gdGhlIGNsaWVudC4KCgsKAwQLARIE
sQIIHgqWAQoEBAsCABIEtAICGxqHASBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRlbXMgdGhh
dCBhcmUgc3VwcG9ydGVkIGluIGEgc2luZ2xlIGJhdGNoLiBUaGlzIGlzCiByZXR1cm5lZCBh
cyBhIGhpbnQgdG8gdGhlIGNsaWVudCB0byBhZGp1c3QgdGhlIGJhdGNoIHNpemUuCgoNCgUE
CwIABRIEtAICBwoNCgUECwIAARIEtAIIFgoNCgUECwIAAxIEtAIZGgpLCgQECwIBEgS3AgJE
Gj0gT3B0aW9uYWwuIFRoZSBlcnJvciBtZXNzYWdlIHRoYXQgaXMgcmV0dXJuZWQgdG8gdGhl
IGNsaWVudC4KCg0KBQQLAgEFEgS3AgIICg0KBQQLAgEBEgS3AgkWCg0KBQQLAgEDEgS3Ahka
Cg0KBQQLAgEIEgS3AhtDChAKCAQLAgEInAgAEgS3AhxCYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::CreateMetastorePartitionRequest ===
    # Fields for CreateMetastorePartitionRequest
    # Field: parent Type: 9 ()
    # Field: metastore_partition Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartition)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsRequest ===
    # Fields for BatchCreateMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.bigquery.storage.v1beta.CreateMetastorePartitionRequest)
    # Field: skip_existing_partitions Type: 8 ()
    # Field: trace_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsResponse ===
    # Fields for BatchCreateMetastorePartitionsResponse
    # Field: partitions Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartition)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchDeleteMetastorePartitionsRequest ===
    # Fields for BatchDeleteMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: partition_values Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartitionValues)
    # Field: trace_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::UpdateMetastorePartitionRequest ===
    # Fields for UpdateMetastorePartitionRequest
    # Field: metastore_partition Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartition)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchUpdateMetastorePartitionsRequest ===
    # Fields for BatchUpdateMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: requests Type: 11 (.google.cloud.bigquery.storage.v1beta.UpdateMetastorePartitionRequest)
    # Field: trace_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchUpdateMetastorePartitionsResponse ===
    # Fields for BatchUpdateMetastorePartitionsResponse
    # Field: partitions Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartition)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::ListMetastorePartitionsRequest ===
    # Fields for ListMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: trace_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::ListMetastorePartitionsResponse ===
    # Fields for ListMetastorePartitionsResponse
    # Field: partitions Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartitionList)
    # Field: streams Type: 11 (.google.cloud.bigquery.storage.v1beta.StreamList)

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsRequest ===
    # Fields for StreamMetastorePartitionsRequest
    # Field: parent Type: 9 ()
    # Field: metastore_partitions Type: 11 (.google.cloud.bigquery.storage.v1beta.MetastorePartition)
    # Field: skip_existing_partitions Type: 8 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsResponse ===
    # Fields for StreamMetastorePartitionsResponse
    # Field: total_partitions_streamed_count Type: 3 ()
    # Field: total_partitions_inserted_count Type: 3 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchSizeTooLargeError ===
    # Fields for BatchSizeTooLargeError
    # Field: max_batch_size Type: 3 ()
    # Field: error_message Type: 9 ()

# === Service Client: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::MetastorePartitionServiceClient ===
package Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::MetastorePartitionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::MetastorePartitionServiceClient

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
        ? Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService',
        method         => 'BatchCreateMetastorePartitions',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsResponse',
    });
}

sub batch_delete_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchDeleteMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService',
        method         => 'BatchDeleteMetastorePartitions',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub batch_update_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchUpdateMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService',
        method         => 'BatchUpdateMetastorePartitions',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchUpdateMetastorePartitionsResponse',
    });
}

sub list_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::ListMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService',
        method         => 'ListMetastorePartitions',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::ListMetastorePartitionsResponse',
    });
}

sub stream_metastore_partitions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService',
        method         => 'StreamMetastorePartitions',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta/metastore_partition.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::CreateMetastorePartitionRequest->new({
        parent => $parent,
        metastore_partition => $metastore_partition,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::CreateMetastorePartitionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta/metastore_partition.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::CreateMetastorePartitionRequest

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

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition>)

Required. The metastore partition to be added.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsRequest

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

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::CreateMetastorePartitionRequest>)

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

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsResponse

Response message for BatchCreateMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition>)

The list of metastore partitions that have been created.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchDeleteMetastorePartitionsRequest

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

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionValues>)

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

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::UpdateMetastorePartitionRequest

Request message for UpdateMetastorePartition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metastore_partition() >> / C<< $msg->metastore_partition($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition>)

Required. The metastore partition to be updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchUpdateMetastorePartitionsRequest

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

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::UpdateMetastorePartitionRequest>)

Required. Requests to update metastore partitions in the table.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Optional. Optional trace id to be used for debugging. It is expected that
the client sets the same `trace_id` for all the batches in the same
operation, so that it is possible to tie together the logs to all the
batches in the same operation. This is expected, but not required, to be
globally unique.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchUpdateMetastorePartitionsResponse

Response message for BatchUpdateMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition>)

The list of metastore partitions that have been updated.
A maximum of 900 partitions can be updated in a batch.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::ListMetastorePartitionsRequest

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

Examples:
* "int_field > 5"
* "date_field = CAST('2014-9-27' as DATE)"
* "nullable_field is not NULL"
* "st_equals(geo_field, st_geofromtext("POINT(2, 2)"))"
* "numeric_field BETWEEN 1.0 AND 5.0"

Restricted to a maximum length of 1 MB.

=item * C<< $msg->trace_id() >> / C<< $msg->trace_id($value) >>

Type: C<String>

Optional. Optional trace id to be used for debugging. It is expected that
the client sets the same `trace_id` for all the batches in the same
operation, so that it is possible to tie together the logs to all the
batches in the same operation. Limited to 256 characters. This is expected,
but not required, to be globally unique.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::ListMetastorePartitionsResponse

Response message for ListMetastorePartitions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitions() >> / C<< $msg->partitions($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionList>)

The list of partitions.

=item * C<< $msg->streams() >> / C<< $msg->streams($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::StreamList>)

The list of streams.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsRequest

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

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition>)

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

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsResponse

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

=head2 Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchSizeTooLargeError

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
