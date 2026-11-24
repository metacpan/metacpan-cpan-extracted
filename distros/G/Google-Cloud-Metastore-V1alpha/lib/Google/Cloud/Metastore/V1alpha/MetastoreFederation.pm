package Google::Cloud::Metastore::V1alpha::MetastoreFederation;

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
    eval { require Google::Cloud::Metastore::V1alpha::Metastore };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvbWV0YXN0b3JlL3YxYWxwaGEvbWV0YXN0b3JlX2ZlZGVyYXRpb24u
cHJvdG8SHmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUudjFhbHBoYRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLmdvb2dsZS9j
bG91ZC9tZXRhc3RvcmUvdjFhbHBoYS9tZXRhc3RvcmUucHJvdG8aI2dvb2dsZS9sb25ncnVu
bmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdv
b2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvIsAHCgpGZWRlcmF0aW9uEhcKBG5hbWUYASABKAlCA+BBBVIEbmFtZRJACgtj
cmVhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3Jl
YXRlVGltZRJACgt1cGRhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IKdXBkYXRlVGltZRJOCgZsYWJlbHMYBCADKAsyNi5nb29nbGUuY2xvdWQubWV0
YXN0b3JlLnYxYWxwaGEuRmVkZXJhdGlvbi5MYWJlbHNFbnRyeVIGbGFiZWxzEh0KB3ZlcnNp
b24YBSABKAlCA+BBBVIHdmVyc2lvbhJwChJiYWNrZW5kX21ldGFzdG9yZXMYBiADKAsyQS5n
b29nbGUuY2xvdWQubWV0YXN0b3JlLnYxYWxwaGEuRmVkZXJhdGlvbi5CYWNrZW5kTWV0YXN0
b3Jlc0VudHJ5UhFiYWNrZW5kTWV0YXN0b3JlcxImCgxlbmRwb2ludF91cmkYByABKAlCA+BB
A1ILZW5kcG9pbnRVcmkSSwoFc3RhdGUYCCABKA4yMC5nb29nbGUuY2xvdWQubWV0YXN0b3Jl
LnYxYWxwaGEuRmVkZXJhdGlvbi5TdGF0ZUID4EEDUgVzdGF0ZRIoCg1zdGF0ZV9tZXNzYWdl
GAkgASgJQgPgQQNSDHN0YXRlTWVzc2FnZRIVCgN1aWQYCiABKAlCA+BBA1IDdWlkGjkKC0xh
YmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEa
dgoWQmFja2VuZE1ldGFzdG9yZXNFbnRyeRIQCgNrZXkYASABKAVSA2tleRJGCgV2YWx1ZRgC
IAEoCzIwLmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUudjFhbHBoYS5CYWNrZW5kTWV0YXN0b3Jl
UgV2YWx1ZToCOAEiXwoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElO
RxABEgoKBkFDVElWRRACEgwKCFVQREFUSU5HEAMSDAoIREVMRVRJTkcQBBIJCgVFUlJPUhAF
OmrqQWcKI21ldGFzdG9yZS5nb29nbGVhcGlzLmNvbS9GZWRlcmF0aW9uEkBwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZmVkZXJhdGlvbnMve2ZlZGVyYXRpb259
IvIBChBCYWNrZW5kTWV0YXN0b3JlEhIKBG5hbWUYASABKAlSBG5hbWUSZQoObWV0YXN0b3Jl
X3R5cGUYAiABKA4yPi5nb29nbGUuY2xvdWQubWV0YXN0b3JlLnYxYWxwaGEuQmFja2VuZE1l
dGFzdG9yZS5NZXRhc3RvcmVUeXBlUg1tZXRhc3RvcmVUeXBlImMKDU1ldGFzdG9yZVR5cGUS
HgoaTUVUQVNUT1JFX1RZUEVfVU5TUEVDSUZJRUQQABIMCghEQVRBUExFWBABEgwKCEJJR1FV
RVJZEAISFgoSREFUQVBST0NfTUVUQVNUT1JFEAMi4AEKFkxpc3RGZWRlcmF0aW9uc1JlcXVl
c3QSQwoGcGFyZW50GAEgASgJQivgQQL6QSUSI21ldGFzdG9yZS5nb29nbGVhcGlzLmNvbS9G
ZWRlcmF0aW9uUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIK
CnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEB
UgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSKxAQoXTGlzdEZlZGVy
YXRpb25zUmVzcG9uc2USTAoLZmVkZXJhdGlvbnMYASADKAsyKi5nb29nbGUuY2xvdWQubWV0
YXN0b3JlLnYxYWxwaGEuRmVkZXJhdGlvblILZmVkZXJhdGlvbnMSJgoPbmV4dF9wYWdlX3Rv
a2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNo
YWJsZSJXChRHZXRGZWRlcmF0aW9uUmVxdWVzdBI/CgRuYW1lGAEgASgJQivgQQL6QSUKI21l
dGFzdG9yZS5nb29nbGVhcGlzLmNvbS9GZWRlcmF0aW9uUgRuYW1lIv0BChdDcmVhdGVGZWRl
cmF0aW9uUmVxdWVzdBJDCgZwYXJlbnQYASABKAlCK+BBAvpBJRIjbWV0YXN0b3JlLmdvb2ds
ZWFwaXMuY29tL0ZlZGVyYXRpb25SBnBhcmVudBIoCg1mZWRlcmF0aW9uX2lkGAIgASgJQgPg
QQJSDGZlZGVyYXRpb25JZBJPCgpmZWRlcmF0aW9uGAMgASgLMiouZ29vZ2xlLmNsb3VkLm1l
dGFzdG9yZS52MWFscGhhLkZlZGVyYXRpb25CA+BBAlIKZmVkZXJhdGlvbhIiCgpyZXF1ZXN0
X2lkGAQgASgJQgPgQQFSCXJlcXVlc3RJZCLQAQoXVXBkYXRlRmVkZXJhdGlvblJlcXVlc3QS
QAoLdXBkYXRlX21hc2sYASABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQJS
CnVwZGF0ZU1hc2sSTwoKZmVkZXJhdGlvbhgCIAEoCzIqLmdvb2dsZS5jbG91ZC5tZXRhc3Rv
cmUudjFhbHBoYS5GZWRlcmF0aW9uQgPgQQJSCmZlZGVyYXRpb24SIgoKcmVxdWVzdF9pZBgD
IAEoCUID4EEBUglyZXF1ZXN0SWQifgoXRGVsZXRlRmVkZXJhdGlvblJlcXVlc3QSPwoEbmFt
ZRgBIAEoCUIr4EEC+kElCiNtZXRhc3RvcmUuZ29vZ2xlYXBpcy5jb20vRmVkZXJhdGlvblIE
bmFtZRIiCgpyZXF1ZXN0X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJZDKnCgobRGF0YXByb2NN
ZXRhc3RvcmVGZWRlcmF0aW9uEskBCg9MaXN0RmVkZXJhdGlvbnMSNi5nb29nbGUuY2xvdWQu
bWV0YXN0b3JlLnYxYWxwaGEuTGlzdEZlZGVyYXRpb25zUmVxdWVzdBo3Lmdvb2dsZS5jbG91
ZC5tZXRhc3RvcmUudjFhbHBoYS5MaXN0RmVkZXJhdGlvbnNSZXNwb25zZSJFgtPkkwI2EjQv
djFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2ZlZGVyYXRpb25z2kEG
cGFyZW50ErYBCg1HZXRGZWRlcmF0aW9uEjQuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWFs
cGhhLkdldEZlZGVyYXRpb25SZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWFs
cGhhLkZlZGVyYXRpb24iQ4LT5JMCNhI0L3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9mZWRlcmF0aW9ucy8qfdpBBG5hbWUSmAIKEENyZWF0ZUZlZGVyYXRpb24SNy5n
b29nbGUuY2xvdWQubWV0YXN0b3JlLnYxYWxwaGEuQ3JlYXRlRmVkZXJhdGlvblJlcXVlc3Qa
HS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqsBgtPkkwJCIjQvdjFhbHBoYS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2ZlZGVyYXRpb25zOgpmZWRlcmF0aW9u2kEf
cGFyZW50LGZlZGVyYXRpb24sZmVkZXJhdGlvbl9pZMpBPgoKRmVkZXJhdGlvbhIwZ29vZ2xl
LmNsb3VkLm1ldGFzdG9yZS52MWFscGhhLk9wZXJhdGlvbk1ldGFkYXRhEpoCChBVcGRhdGVG
ZWRlcmF0aW9uEjcuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWFscGhhLlVwZGF0ZUZlZGVy
YXRpb25SZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKtAYLT5JMCTTI/
L3YxYWxwaGEve2ZlZGVyYXRpb24ubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2ZlZGVy
YXRpb25zLyp9OgpmZWRlcmF0aW9u2kEWZmVkZXJhdGlvbix1cGRhdGVfbWFza8pBPgoKRmVk
ZXJhdGlvbhIwZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWFscGhhLk9wZXJhdGlvbk1ldGFk
YXRhEvwBChBEZWxldGVGZWRlcmF0aW9uEjcuZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWFs
cGhhLkRlbGV0ZUZlZGVyYXRpb25SZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbiKPAYLT5JMCNio0L3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9m
ZWRlcmF0aW9ucy8qfdpBBG5hbWXKQUkKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRIwZ29vZ2xl
LmNsb3VkLm1ldGFzdG9yZS52MWFscGhhLk9wZXJhdGlvbk1ldGFkYXRhGkzKQRhtZXRhc3Rv
cmUuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Ns
b3VkLXBsYXRmb3JtQoIBCiJjb20uZ29vZ2xlLmNsb3VkLm1ldGFzdG9yZS52MWFscGhhQhhN
ZXRhc3RvcmVGZWRlcmF0aW9uUHJvdG9QAVpAY2xvdWQuZ29vZ2xlLmNvbS9nby9tZXRhc3Rv
cmUvYXBpdjFhbHBoYS9tZXRhc3RvcmVwYjttZXRhc3RvcmVwYkq3ZwoHEgUOAPgCAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAmCgkK
AgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADgKCQoCAwUSAxcALQoJ
CgIDBhIDGAAlCgkKAgMHEgMZACoKCQoCAwgSAxoAKQoICgEIEgMcAFcKCQoCCAsSAxwAVwoI
CgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeADkKCQoCCAgSAx4AOQoICgEIEgMfADsKCQoC
CAESAx8AOwrtBQoCBgASBC4AbAEa4AUgQ29uZmlndXJlcyBhbmQgbWFuYWdlcyBtZXRhc3Rv
cmUgZmVkZXJhdGlvbiBzZXJ2aWNlcy4KIERhdGFwcm9jIE1ldGFzdG9yZSBGZWRlcmF0aW9u
IFNlcnZpY2UgYWxsb3dzIGZlZGVyYXRpbmcgYSBjb2xsZWN0aW9uIG9mCiBiYWNrZW5kIG1l
dGFzdG9yZXMgbGlrZSBCaWdRdWVyeSwgRGF0YXBsZXggTGFrZXMsIGFuZCBvdGhlciBEYXRh
cHJvYwogTWV0YXN0b3Jlcy4gVGhlIEZlZGVyYXRpb24gU2VydmljZSBleHBvc2VzIGEgZ1JQ
QyBVUkwgdGhyb3VnaCB3aGljaCBtZXRhZGF0YQogZnJvbSB0aGUgYmFja2VuZCBtZXRhc3Rv
cmVzIGFyZSBzZXJ2ZWQgYXQgcXVlcnkgdGltZS4KCiBUaGUgRGF0YXByb2MgTWV0YXN0b3Jl
IEZlZGVyYXRpb24gQVBJIGRlZmluZXMgdGhlIGZvbGxvd2luZyByZXNvdXJjZSBtb2RlbDoK
ICogVGhlIHNlcnZpY2Ugd29ya3Mgd2l0aCBhIGNvbGxlY3Rpb24gb2YgR29vZ2xlIENsb3Vk
IHByb2plY3RzLgogKiBFYWNoIHByb2plY3QgaGFzIGEgY29sbGVjdGlvbiBvZiBhdmFpbGFi
bGUgbG9jYXRpb25zLgogKiBFYWNoIGxvY2F0aW9uIGhhcyBhIGNvbGxlY3Rpb24gb2YgZmVk
ZXJhdGlvbnMuCiAqIERhdGFwcm9jIE1ldGFzdG9yZSBGZWRlcmF0aW9ucyBhcmUgcmVzb3Vy
Y2VzIHdpdGggbmFtZXMgb2YgdGhlCiBmb3JtOgogYHByb2plY3RzL3twcm9qZWN0X251bWJl
cn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vZmVkZXJhdGlvbnMve2ZlZGVyYXRpb25faWR9
YC4KCgoKAwYAARIDLggjCgoKAwYAAxIDLwJACgwKBQYAA5kIEgMvAkAKCwoDBgADEgQwAjE3
Cg0KBQYAA5oIEgQwAjE3CjwKBAYAAgASBDQCOgMaLiBMaXN0cyBmZWRlcmF0aW9ucyBpbiBh
IHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACAAESAzQGFQoMCgUGAAIAAhIDNBYsCgwK
BQYAAgADEgM1DyYKDQoFBgACAAQSBDYEOAYKEQoJBgACAASwyrwiEgQ2BDgGCgwKBQYAAgAE
EgM5BDQKDwoIBgACAASbCAASAzkENAo4CgQGAAIBEgQ9AkIDGiogR2V0cyB0aGUgZGV0YWls
cyBvZiBhIHNpbmdsZSBmZWRlcmF0aW9uLgoKDAoFBgACAQESAz0GEwoMCgUGAAIBAhIDPRQo
CgwKBQYAAgEDEgM9Mz0KDQoFBgACAQQSBD4EQAYKEQoJBgACAQSwyrwiEgQ+BEAGCgwKBQYA
AgEEEgNBBDIKDwoIBgACAQSbCAASA0EEMgpJCgQGAAICEgRFAlADGjsgQ3JlYXRlcyBhIG1l
dGFzdG9yZSBmZWRlcmF0aW9uIGluIGEgcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAIC
ARIDRQYWCgwKBQYAAgICEgNFFy4KDAoFBgACAgMSA0YPKwoNCgUGAAICBBIERwRKBgoRCgkG
AAICBLDKvCISBEcESgYKDAoFBgACAgQSA0sETQoPCggGAAICBJsIABIDSwRNCg0KBQYAAgIE
EgRMBE8GCg8KBwYAAgIEmQgSBEwETwYKMwoEBgACAxIEUwJeAxolIFVwZGF0ZXMgdGhlIGZp
ZWxkcyBvZiBhIGZlZGVyYXRpb24uCgoMCgUGAAIDARIDUwYWCgwKBQYAAgMCEgNTFy4KDAoF
BgACAwMSA1QPKwoNCgUGAAIDBBIEVQRYBgoRCgkGAAIDBLDKvCISBFUEWAYKDAoFBgACAwQS
A1kERAoPCggGAAIDBJsIABIDWQRECg0KBQYAAgMEEgRaBF0GCg8KBwYAAgMEmQgSBFoEXQYK
LAoEBgACBBIEYQJrAxoeIERlbGV0ZXMgYSBzaW5nbGUgZmVkZXJhdGlvbi4KCgwKBQYAAgQB
EgNhBhYKDAoFBgACBAISA2EXLgoMCgUGAAIEAxIDYg8rCg0KBQYAAgQEEgRjBGUGChEKCQYA
AgQEsMq8IhIEYwRlBgoMCgUGAAIEBBIDZgQyCg8KCAYAAgQEmwgAEgNmBDIKDQoFBgACBAQS
BGcEagYKDwoHBgACBASZCBIEZwRqBgpGCgIEABIFbwC1AQEaOSBSZXByZXNlbnRzIGEgZmVk
ZXJhdGlvbiBvZiBtdWx0aXBsZSBiYWNrZW5kIG1ldGFzdG9yZXMuCgoKCgMEAAESA28IEgoL
CgMEAAcSBHACcwQKDQoFBAAHnQgSBHACcwQKNQoEBAAEABIFdgKKAQMaJiBUaGUgY3VycmVu
dCBzdGF0ZSBvZiB0aGUgZmVkZXJhdGlvbi4KCgwKBQQABAABEgN2BwwKQgoGBAAEAAIAEgN4
BBoaMyBUaGUgc3RhdGUgb2YgdGhlIG1ldGFzdG9yZSBmZWRlcmF0aW9uIGlzIHVua25vd24u
CgoOCgcEAAQAAgABEgN4BBUKDgoHBAAEAAIAAhIDeBgZCk0KBgQABAACARIDewQRGj4gVGhl
IG1ldGFzdG9yZSBmZWRlcmF0aW9uIGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIGNyZWF0
ZWQuCgoOCgcEAAQAAgEBEgN7BAwKDgoHBAAEAAIBAhIDew8QClAKBgQABAACAhIDfgQPGkEg
VGhlIG1ldGFzdG9yZSBmZWRlcmF0aW9uIGlzIHJ1bm5pbmcgYW5kIHJlYWR5IHRvIHNlcnZl
IHF1ZXJpZXMuCgoOCgcEAAQAAgIBEgN+BAoKDgoHBAAEAAICAhIDfg0OCpkBCgYEAAQAAgMS
BIIBBBEaiAEgVGhlIG1ldGFzdG9yZSBmZWRlcmF0aW9uIGlzIGJlaW5nIHVwZGF0ZWQuIEl0
IHJlbWFpbnMgdXNhYmxlIGJ1dCBjYW5ub3QKIGFjY2VwdCBhZGRpdGlvbmFsIHVwZGF0ZSBy
ZXF1ZXN0cyBvciBiZSBkZWxldGVkIGF0IHRoaXMgdGltZS4KCg8KBwQABAACAwESBIIBBAwK
DwoHBAAEAAIDAhIEggEPEApVCgYEAAQAAgQSBIUBBBEaRSBUaGUgbWV0YXN0b3JlIGZlZGVy
YXRpb24gaXMgdW5kZXJnb2luZyBkZWxldGlvbi4gSXQgY2Fubm90IGJlIHVzZWQuCgoPCgcE
AAQAAgQBEgSFAQQMCg8KBwQABAACBAISBIUBDxAKhAEKBgQABAACBRIEiQEEDhp0IFRoZSBt
ZXRhc3RvcmUgZmVkZXJhdGlvbiBoYXMgZW5jb3VudGVyZWQgYW4gZXJyb3IgYW5kIGNhbm5v
dCBiZSB1c2VkLiBUaGUKIG1ldGFzdG9yZSBmZWRlcmF0aW9uIHNob3VsZCBiZSBkZWxldGVk
LgoKDwoHBAAEAAIFARIEiQEECQoPCgcEAAQAAgUCEgSJAQwNCqgBCgQEAAIAEgSPAQI8GpkB
IEltbXV0YWJsZS4gVGhlIHJlbGF0aXZlIHJlc291cmNlIG5hbWUgb2YgdGhlIGZlZGVyYXRp
b24sIG9mIHRoZQogZm9ybToKIHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25z
L3tsb2NhdGlvbl9pZH0vZmVkZXJhdGlvbnMve2ZlZGVyYXRpb25faWR9YC4KCg0KBQQAAgAF
EgSPAQIICg0KBQQAAgABEgSPAQkNCg0KBQQAAgADEgSPARARCg0KBQQAAgAIEgSPARI7ChAK
CAQAAgAInAgAEgSPARM6ClIKBAQAAgESBpIBApMBMhpCIE91dHB1dCBvbmx5LiBUaGUgdGlt
ZSB3aGVuIHRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiB3YXMgY3JlYXRlZC4KCg0KBQQAAgEG
EgSSAQIbCg0KBQQAAgEBEgSSARwnCg0KBQQAAgEDEgSSASorCg0KBQQAAgEIEgSTAQYxChAK
CAQAAgEInAgAEgSTAQcwClcKBAQAAgISBpYBApcBMhpHIE91dHB1dCBvbmx5LiBUaGUgdGlt
ZSB3aGVuIHRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbiB3YXMgbGFzdCB1cGRhdGVkLgoKDQoF
BAACAgYSBJYBAhsKDQoFBAACAgESBJYBHCcKDQoFBAACAgMSBJYBKisKDQoFBAACAggSBJcB
BjEKEAoIBAACAgicCAASBJcBBzAKQQoEBAACAxIEmgECIRozIFVzZXItZGVmaW5lZCBsYWJl
bHMgZm9yIHRoZSBtZXRhc3RvcmUgZmVkZXJhdGlvbi4KCg0KBQQAAgMGEgSaAQIVCg0KBQQA
AgMBEgSaARYcCg0KBQQAAgMDEgSaAR8gCqABCgQEAAIEEgSeAQI/GpEBIEltbXV0YWJsZS4g
VGhlIEFwYWNoZSBIaXZlIG1ldGFzdG9yZSB2ZXJzaW9uIG9mIHRoZSBmZWRlcmF0aW9uLiBB
bGwgYmFja2VuZAogbWV0YXN0b3JlIHZlcnNpb25zIG11c3QgYmUgY29tcGF0aWJsZSB3aXRo
IHRoZSBmZWRlcmF0aW9uIHZlcnNpb24uCgoNCgUEAAIEBRIEngECCAoNCgUEAAIEARIEngEJ
EAoNCgUEAAIEAxIEngETFAoNCgUEAAIECBIEngEVPgoQCggEAAIECJwIABIEngEWPQqkAwoE
BAACBRIEpgECNhqVAyBBIG1hcCBmcm9tIGBCYWNrZW5kTWV0YXN0b3JlYCByYW5rIHRvIGBC
YWNrZW5kTWV0YXN0b3JlYHMgZnJvbSB3aGljaCB0aGUKIGZlZGVyYXRpb24gc2VydmljZSBz
ZXJ2ZXMgbWV0YWRhdGEgYXQgcXVlcnkgdGltZS4gVGhlIG1hcCBrZXkgcmVwcmVzZW50cwog
dGhlIG9yZGVyIGluIHdoaWNoIGBCYWNrZW5kTWV0YXN0b3JlYHMgc2hvdWxkIGJlIGV2YWx1
YXRlZCB0byByZXNvbHZlCiBkYXRhYmFzZSBuYW1lcyBhdCBxdWVyeSB0aW1lIGFuZCBzaG91
bGQgYmUgZ3JlYXRlciB0aGFuIG9yIGVxdWFsIHRvIHplcm8uIEEKIGBCYWNrZW5kTWV0YXN0
b3JlYCB3aXRoIGEgbG93ZXIgbnVtYmVyIHdpbGwgYmUgZXZhbHVhdGVkIGJlZm9yZSBhCiBg
QmFja2VuZE1ldGFzdG9yZWAgd2l0aCBhIGhpZ2hlciBudW1iZXIuCgoNCgUEAAIFBhIEpgEC
HgoNCgUEAAIFARIEpgEfMQoNCgUEAAIFAxIEpgE0NQo1CgQEAAIGEgSpAQJGGicgT3V0cHV0
IG9ubHkuIFRoZSBmZWRlcmF0aW9uIGVuZHBvaW50LgoKDQoFBAACBgUSBKkBAggKDQoFBAAC
BgESBKkBCRUKDQoFBAACBgMSBKkBGBkKDQoFBAACBggSBKkBGkUKEAoIBAACBgicCAASBKkB
G0QKQQoEBAACBxIErAECPhozIE91dHB1dCBvbmx5LiBUaGUgY3VycmVudCBzdGF0ZSBvZiB0
aGUgZmVkZXJhdGlvbi4KCg0KBQQAAgcGEgSsAQIHCg0KBQQAAgcBEgSsAQgNCg0KBQQAAgcD
EgSsARARCg0KBQQAAgcIEgSsARI9ChAKCAQAAgcInAgAEgSsARM8CncKBAQAAggSBLABAkca
aSBPdXRwdXQgb25seS4gQWRkaXRpb25hbCBpbmZvcm1hdGlvbiBhYm91dCB0aGUgY3VycmVu
dCBzdGF0ZSBvZiB0aGUKIG1ldGFzdG9yZSBmZWRlcmF0aW9uLCBpZiBhdmFpbGFibGUuCgoN
CgUEAAIIBRIEsAECCAoNCgUEAAIIARIEsAEJFgoNCgUEAAIIAxIEsAEZGgoNCgUEAAIICBIE
sAEbRgoQCggEAAIICJwIABIEsAEcRQpiCgQEAAIJEgS0AQI+GlQgT3V0cHV0IG9ubHkuIFRo
ZSBnbG9iYWxseSB1bmlxdWUgcmVzb3VyY2UgaWRlbnRpZmllciBvZiB0aGUgbWV0YXN0b3Jl
CiBmZWRlcmF0aW9uLgoKDQoFBAACCQUSBLQBAggKDQoFBAACCQESBLQBCQwKDQoFBAACCQMS
BLQBDxEKDQoFBAACCQgSBLQBEj0KEAoIBAACCQicCAASBLQBEzwKQgoCBAESBrgBANQBARo0
IFJlcHJlc2VudHMgYSBiYWNrZW5kIG1ldGFzdG9yZSBmb3IgdGhlIGZlZGVyYXRpb24uCgoL
CgMEAQESBLgBCBgKNAoEBAEEABIGugECxgEDGiQgVGhlIHR5cGUgb2YgdGhlIGJhY2tlbmQg
bWV0YXN0b3JlLgoKDQoFBAEEAAESBLoBBxQKMAoGBAEEAAIAEgS8AQQjGiAgVGhlIG1ldGFz
dG9yZSB0eXBlIGlzIG5vdCBzZXQuCgoPCgcEAQQAAgABEgS8AQQeCg8KBwQBBAACAAISBLwB
ISIKNAoGBAEEAAIBEgS/AQQRGiQgVGhlIGJhY2tlbmQgbWV0YXN0b3JlIGlzIERhdGFwbGV4
LgoKDwoHBAEEAAIBARIEvwEEDAoPCgcEAQQAAgECEgS/AQ8QCjQKBgQBBAACAhIEwgEEERok
IFRoZSBiYWNrZW5kIG1ldGFzdG9yZSBpcyBCaWdRdWVyeS4KCg8KBwQBBAACAgESBMIBBAwK
DwoHBAEEAAICAhIEwgEPEAo+CgYEAQQAAgMSBMUBBBsaLiBUaGUgYmFja2VuZCBtZXRhc3Rv
cmUgaXMgRGF0YXByb2MgTWV0YXN0b3JlLgoKDwoHBAEEAAIDARIExQEEFgoPCgcEAQQAAgMC
EgTFARkaCscCCgQEAQIAEgTQAQISGrgCIFRoZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBtZXRhc3RvcmUgdGhhdCBpcyBiZWluZyBmZWRlcmF0ZWQuCiBUaGUgZm9ybWF0cyBv
ZiB0aGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZXMgZm9yIHRoZSBjdXJyZW50bHkgc3VwcG9y
dGVkCiBtZXRhc3RvcmVzIGFyZSBsaXN0ZWQgYmVsb3c6CgogKiBCaWdRdWVyeQogICAgICog
YHByb2plY3RzL3twcm9qZWN0X2lkfWAKICogRGF0YXByb2MgTWV0YXN0b3JlCiAgICAgKiBg
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3NlcnZpY2VzL3tz
ZXJ2aWNlX2lkfWAKCg0KBQQBAgAFEgTQAQIICg0KBQQBAgABEgTQAQkNCg0KBQQBAgADEgTQ
ARARCjIKBAQBAgESBNMBAiMaJCBUaGUgdHlwZSBvZiB0aGUgYmFja2VuZCBtZXRhc3RvcmUu
CgoNCgUEAQIBBhIE0wECDwoNCgUEAQIBARIE0wEQHgoNCgUEAQIBAxIE0wEhIgo0CgIEAhIG
1wEA+QEBGiYgUmVxdWVzdCBtZXNzYWdlIGZvciBMaXN0RmVkZXJhdGlvbnMuCgoLCgMEAgES
BNcBCB4KtwEKBAQCAgASBtsBAuABBBqmASBSZXF1aXJlZC4gVGhlIHJlbGF0aXZlIHJlc291
cmNlIG5hbWUgb2YgdGhlIGxvY2F0aW9uIG9mIG1ldGFzdG9yZQogZmVkZXJhdGlvbnMgdG8g
bGlzdCwgaW4gdGhlIGZvbGxvd2luZyBmb3JtOgogYHByb2plY3RzL3twcm9qZWN0X251bWJl
cn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH1gLgoKDQoFBAICAAUSBNsBAggKDQoFBAICAAES
BNsBCQ8KDQoFBAICAAMSBNsBEhMKDwoFBAICAAgSBtsBFOABAwoQCggEAgIACJwIABIE3AEE
KgoRCgcEAgIACJ8IEgbdAQTfAQUK+wEKBAQCAgESBOYBAj8a7AEgT3B0aW9uYWwuIFRoZSBt
YXhpbXVtIG51bWJlciBvZiBmZWRlcmF0aW9ucyB0byByZXR1cm4uIFRoZSByZXNwb25zZSBt
YXkKIGNvbnRhaW4gbGVzcyB0aGFuIHRoZSBtYXhpbXVtIG51bWJlci4gSWYgdW5zcGVjaWZp
ZWQsIG5vIG1vcmUgdGhhbiA1MDAKIHNlcnZpY2VzIGFyZSByZXR1cm5lZC4gVGhlIG1heGlt
dW0gdmFsdWUgaXMgMTAwMDsgdmFsdWVzIGFib3ZlIDEwMDAgYXJlCiBjaGFuZ2VkIHRvIDEw
MDAuCgoNCgUEAgIBBRIE5gECBwoNCgUEAgIBARIE5gEIEQoNCgUEAgIBAxIE5gEUFQoNCgUE
AgIBCBIE5gEWPgoQCggEAgIBCJwIABIE5gEXPQrIAgoEBAICAhIE8AECQRq5AiBPcHRpb25h
bC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgTGlzdEZlZGVyYXRp
b25TZXJ2aWNlcwogY2FsbC4gUHJvdmlkZSB0aGlzIHRva2VuIHRvIHJldHJpZXZlIHRoZSBz
dWJzZXF1ZW50IHBhZ2UuCgogVG8gcmV0cmlldmUgdGhlIGZpcnN0IHBhZ2UsIHN1cHBseSBh
biBlbXB0eSBwYWdlIHRva2VuLgoKIFdoZW4gcGFnaW5hdGluZywgb3RoZXIgcGFyYW1ldGVy
cyBwcm92aWRlZCB0bwogTGlzdEZlZGVyYXRpb25TZXJ2aWNlcyBtdXN0IG1hdGNoIHRoZSBj
YWxsIHRoYXQgcHJvdmlkZWQgdGhlCiBwYWdlIHRva2VuLgoKDQoFBAICAgUSBPABAggKDQoF
BAICAgESBPABCRMKDQoFBAICAgMSBPABFhcKDQoFBAICAggSBPABGEAKEAoIBAICAgicCAAS
BPABGT8KPgoEBAICAxIE8wECPRowIE9wdGlvbmFsLiBUaGUgZmlsdGVyIHRvIGFwcGx5IHRv
IGxpc3QgcmVzdWx0cy4KCg0KBQQCAgMFEgTzAQIICg0KBQQCAgMBEgTzAQkPCg0KBQQCAgMD
EgTzARITCg0KBQQCAgMIEgTzARQ8ChAKCAQCAgMInAgAEgTzARU7CuQBCgQEAgIEEgT4AQI/
GtUBIE9wdGlvbmFsLiBTcGVjaWZ5IHRoZSBvcmRlcmluZyBvZiByZXN1bHRzIGFzIGRlc2Ny
aWJlZCBpbiBbU29ydGluZwogT3JkZXJdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlz
L2Rlc2lnbi9kZXNpZ25fcGF0dGVybnMjc29ydGluZ19vcmRlcikuCiBJZiBub3Qgc3BlY2lm
aWVkLCB0aGUgcmVzdWx0cyB3aWxsIGJlIHNvcnRlZCBpbiB0aGUgZGVmYXVsdCBvcmRlci4K
Cg0KBQQCAgQFEgT4AQIICg0KBQQCAgQBEgT4AQkRCg0KBQQCAgQDEgT4ARQVCg0KBQQCAgQI
EgT4ARY+ChAKCAQCAgQInAgAEgT4ARc9CjQKAgQDEgb8AQCGAgEaJiBSZXNwb25zZSBtZXNz
YWdlIGZvciBMaXN0RmVkZXJhdGlvbnMKCgsKAwQDARIE/AEIHwo3CgQEAwIAEgT+AQImGikg
VGhlIHNlcnZpY2VzIGluIHRoZSBzcGVjaWZpZWQgbG9jYXRpb24uCgoNCgUEAwIABBIE/gEC
CgoNCgUEAwIABhIE/gELFQoNCgUEAwIAARIE/gEWIQoNCgUEAwIAAxIE/gEkJQqNAQoEBAMC
ARIEggICHRp/IEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8g
cmV0cmlldmUgdGhlIG5leHQgcGFnZS4gSWYgdGhpcwogZmllbGQgaXMgb21pdHRlZCwgdGhl
cmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEAwIBBRIEggICCAoNCgUEAwIBARIE
ggIJGAoNCgUEAwIBAxIEggIbHAo0CgQEAwICEgSFAgIiGiYgTG9jYXRpb25zIHRoYXQgY291
bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAwICBBIEhQICCgoNCgUEAwICBRIEhQILEQoNCgUE
AwICARIEhQISHQoNCgUEAwICAxIEhQIgIQoyCgIEBBIGiQIAlAIBGiQgUmVxdWVzdCBtZXNz
YWdlIGZvciBHZXRGZWRlcmF0aW9uLgoKCwoDBAQBEgSJAggcCssBCgQEBAIAEgaOAgKTAgQa
ugEgUmVxdWlyZWQuIFRoZSByZWxhdGl2ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBtZXRhc3Rv
cmUgZmVkZXJhdGlvbiB0bwogcmV0cmlldmUsIGluIHRoZSBmb2xsb3dpbmcgZm9ybToKCiBg
cHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9mZWRl
cmF0aW9ucy97ZmVkZXJhdGlvbl9pZH1gLgoKDQoFBAQCAAUSBI4CAggKDQoFBAQCAAESBI4C
CQ0KDQoFBAQCAAMSBI4CEBEKDwoFBAQCAAgSBo4CEpMCAwoQCggEBAIACJwIABIEjwIEKgoR
CgcEBAIACJ8IEgaQAgSSAgUKNQoCBAUSBpcCAL0CARonIFJlcXVlc3QgbWVzc2FnZSBmb3Ig
Q3JlYXRlRmVkZXJhdGlvbi4KCgsKAwQFARIElwIIHwq/AQoEBAUCABIGnAICoQIEGq4BIFJl
cXVpcmVkLiBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbG9jYXRpb24gaW4g
d2hpY2ggdG8gY3JlYXRlIGEKIGZlZGVyYXRpb24gc2VydmljZSwgaW4gdGhlIGZvbGxvd2lu
ZyBmb3JtOgoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRp
b25faWR9YC4KCg0KBQQFAgAFEgScAgIICg0KBQQFAgABEgScAgkPCg0KBQQFAgADEgScAhIT
Cg8KBQQFAgAIEgacAhShAgMKEAoIBAUCAAicCAASBJ0CBCoKEQoHBAUCAAifCBIGngIEoAIF
CrcCCgQEBQIBEgSpAgJEGqgCIFJlcXVpcmVkLiBUaGUgSUQgb2YgdGhlIG1ldGFzdG9yZSBm
ZWRlcmF0aW9uLCB3aGljaCBpcyB1c2VkIGFzIHRoZSBmaW5hbAogY29tcG9uZW50IG9mIHRo
ZSBtZXRhc3RvcmUgZmVkZXJhdGlvbidzIG5hbWUuCgogVGhpcyB2YWx1ZSBtdXN0IGJlIGJl
dHdlZW4gMiBhbmQgNjMgY2hhcmFjdGVycyBsb25nIGluY2x1c2l2ZSwgYmVnaW4gd2l0aCBh
CiBsZXR0ZXIsIGVuZCB3aXRoIGEgbGV0dGVyIG9yIG51bWJlciwgYW5kIGNvbnNpc3Qgb2Yg
YWxwaGEtbnVtZXJpYwogQVNDSUkgY2hhcmFjdGVycyBvciBoeXBoZW5zLgoKDQoFBAUCAQUS
BKkCAggKDQoFBAUCAQESBKkCCRYKDQoFBAUCAQMSBKkCGRoKDQoFBAUCAQgSBKkCG0MKEAoI
BAUCAQicCAASBKkCHEIKwQEKBAQFAgISBK4CAkUasgEgUmVxdWlyZWQuIFRoZSBNZXRhc3Rv
cmUgRmVkZXJhdGlvbiB0byBjcmVhdGUuIFRoZSBgbmFtZWAgZmllbGQgaXMKIGlnbm9yZWQu
IFRoZSBJRCBvZiB0aGUgY3JlYXRlZCBtZXRhc3RvcmUgZmVkZXJhdGlvbiBtdXN0IGJlCiBw
cm92aWRlZCBpbiB0aGUgcmVxdWVzdCdzIGBmZWRlcmF0aW9uX2lkYCBmaWVsZC4KCg0KBQQF
AgIGEgSuAgIMCg0KBQQFAgIBEgSuAg0XCg0KBQQFAgIDEgSuAhobCg0KBQQFAgIIEgSuAhxE
ChAKCAQFAgIInAgAEgSuAh1DCvkECgQEBQIDEgS8AgJBGuoEIE9wdGlvbmFsLiBBIHJlcXVl
c3QgSUQuIFNwZWNpZnkgYSB1bmlxdWUgcmVxdWVzdCBJRCB0byBhbGxvdyB0aGUgc2VydmVy
IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGNvbXBsZXRlZC4gVGhlIHNlcnZl
ciB3aWxsIGlnbm9yZSBzdWJzZXF1ZW50CiByZXF1ZXN0cyB0aGF0IHByb3ZpZGUgYSBkdXBs
aWNhdGUgcmVxdWVzdCBJRCBmb3IgYXQgbGVhc3QgNjAgbWludXRlcyBhZnRlcgogdGhlIGZp
cnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGlmIGFuIGluaXRpYWwgcmVxdWVzdCB0aW1l
cyBvdXQsIGZvbGxvd2VkIGJ5IGFub3RoZXIgcmVxdWVzdAogd2l0aCB0aGUgc2FtZSByZXF1
ZXN0IElELCB0aGUgc2VydmVyIGlnbm9yZXMgdGhlIHNlY29uZCByZXF1ZXN0IHRvIHByZXZl
bnQKIHRoZSBjcmVhdGlvbiBvZiBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVl
c3QgSUQgbXVzdCBiZSBhIHZhbGlkCiBbVVVJRF0oaHR0cHM6Ly9lbi53aWtpcGVkaWEub3Jn
L3dpa2kvVW5pdmVyc2FsbHlfdW5pcXVlX2lkZW50aWZpZXIjRm9ybWF0KQogQSB6ZXJvIFVV
SUQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkgaXMgbm90IHN1cHBv
cnRlZC4KCg0KBQQFAgMFEgS8AgIICg0KBQQFAgMBEgS8AgkTCg0KBQQFAgMDEgS8AhYXCg0K
BQQFAgMIEgS8AhhAChAKCAQFAgMInAgAEgS8Ahk/CjUKAgQGEgbAAgDcAgEaJyBSZXF1ZXN0
IG1lc3NhZ2UgZm9yIFVwZGF0ZUZlZGVyYXRpb24uCgoLCgMEBgESBMACCB8KmAIKBAQGAgAS
BsUCAsYCLxqHAiBSZXF1aXJlZC4gQSBmaWVsZCBtYXNrIHVzZWQgdG8gc3BlY2lmeSB0aGUg
ZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGluIHRoZQogbWV0YXN0b3JlIGZlZGVyYXRpb24g
cmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4KIEZpZWxkcyBzcGVjaWZpZWQgaW4gdGhlIGB1cGRh
dGVfbWFza2AgYXJlIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSAobm90CiB0byB0aGUgZnVs
bCByZXF1ZXN0KS4gQSBmaWVsZCBpcyBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFz
ay4KCg0KBQQGAgAGEgTFAgIbCg0KBQQGAgABEgTFAhwnCg0KBQQGAgADEgTFAiorCg0KBQQG
AgAIEgTGAgYuChAKCAQGAgAInAgAEgTGAgctCvgBCgQEBgIBEgTNAgJFGukBIFJlcXVpcmVk
LiBUaGUgbWV0YXN0b3JlIGZlZGVyYXRpb24gdG8gdXBkYXRlLiBUaGUgc2VydmVyIG9ubHkg
bWVyZ2VzIGZpZWxkcwogaW4gdGhlIHNlcnZpY2UgaWYgdGhleSBhcmUgc3BlY2lmaWVkIGlu
IGB1cGRhdGVfbWFza2AuCgogVGhlIG1ldGFzdG9yZSBmZWRlcmF0aW9uJ3MgYG5hbWVgIGZp
ZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhlCiBtZXRhc3RvcmUgc2VydmljZSB0byBiZSB1
cGRhdGVkLgoKDQoFBAYCAQYSBM0CAgwKDQoFBAYCAQESBM0CDRcKDQoFBAYCAQMSBM0CGhsK
DQoFBAYCAQgSBM0CHEQKEAoIBAYCAQicCAASBM0CHUMK+QQKBAQGAgISBNsCAkEa6gQgT3B0
aW9uYWwuIEEgcmVxdWVzdCBJRC4gU3BlY2lmeSBhIHVuaXF1ZSByZXF1ZXN0IElEIHRvIGFs
bG93IHRoZSBzZXJ2ZXIgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgY29tcGxl
dGVkLiBUaGUgc2VydmVyIHdpbGwgaWdub3JlIHN1YnNlcXVlbnQKIHJlcXVlc3RzIHRoYXQg
cHJvdmlkZSBhIGR1cGxpY2F0ZSByZXF1ZXN0IElEIGZvciBhdCBsZWFzdCA2MCBtaW51dGVz
IGFmdGVyCiB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgaWYgYW4gaW5pdGlh
bCByZXF1ZXN0IHRpbWVzIG91dCwgZm9sbG93ZWQgYnkgYW5vdGhlciByZXF1ZXN0CiB3aXRo
IHRoZSBzYW1lIHJlcXVlc3QgSUQsIHRoZSBzZXJ2ZXIgaWdub3JlcyB0aGUgc2Vjb25kIHJl
cXVlc3QgdG8gcHJldmVudAogdGhlIGNyZWF0aW9uIG9mIGR1cGxpY2F0ZSBjb21taXRtZW50
cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQKIFtVVUlEXShodHRwczovL2Vu
Lndpa2lwZWRpYS5vcmcvd2lraS9Vbml2ZXJzYWxseV91bmlxdWVfaWRlbnRpZmllciNGb3Jt
YXQpCiBBIHplcm8gVVVJRCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAw
KSBpcyBub3Qgc3VwcG9ydGVkLgoKDQoFBAYCAgUSBNsCAggKDQoFBAYCAgESBNsCCRMKDQoF
BAYCAgMSBNsCFhcKDQoFBAYCAggSBNsCGEAKEAoIBAYCAgicCAASBNsCGT8KNQoCBAcSBt8C
APgCARonIFJlcXVlc3QgbWVzc2FnZSBmb3IgRGVsZXRlRmVkZXJhdGlvbi4KCgsKAwQHARIE
3wIIHwrJAQoEBAcCABIG5AIC6QIEGrgBIFJlcXVpcmVkLiBUaGUgcmVsYXRpdmUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgbWV0YXN0b3JlIGZlZGVyYXRpb24gdG8gZGVsZXRlLAogaW4gdGhl
IGZvbGxvd2luZyBmb3JtOgoKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9u
cy97bG9jYXRpb25faWR9L2ZlZGVyYXRpb25zL3tmZWRlcmF0aW9uX2lkfWAuCgoNCgUEBwIA
BRIE5AICCAoNCgUEBwIAARIE5AIJDQoNCgUEBwIAAxIE5AIQEQoPCgUEBwIACBIG5AIS6QID
ChAKCAQHAgAInAgAEgTlAgQqChEKBwQHAgAInwgSBuYCBOgCBQr5BAoEBAcCARIE9wICQRrq
BCBPcHRpb25hbC4gQSByZXF1ZXN0IElELiBTcGVjaWZ5IGEgdW5pcXVlIHJlcXVlc3QgSUQg
dG8gYWxsb3cgdGhlIHNlcnZlciB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBj
b21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbCBpZ25vcmUgc3Vic2VxdWVudAogcmVxdWVzdHMg
dGhhdCBwcm92aWRlIGEgZHVwbGljYXRlIHJlcXVlc3QgSUQgZm9yIGF0IGxlYXN0IDYwIG1p
bnV0ZXMgYWZ0ZXIKIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBpZiBhbiBp
bml0aWFsIHJlcXVlc3QgdGltZXMgb3V0LCBmb2xsb3dlZCBieSBhbm90aGVyIHJlcXVlc3QK
IHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRCwgdGhlIHNlcnZlciBpZ25vcmVzIHRoZSBzZWNv
bmQgcmVxdWVzdCB0byBwcmV2ZW50CiB0aGUgY3JlYXRpb24gb2YgZHVwbGljYXRlIGNvbW1p
dG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZAogW1VVSURdKGh0dHBz
Oi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL1VuaXZlcnNhbGx5X3VuaXF1ZV9pZGVudGlmaWVy
I0Zvcm1hdCkKIEEgemVybyBVVUlEICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAw
MDAwMDApIGlzIG5vdCBzdXBwb3J0ZWQuCgoNCgUEBwIBBRIE9wICCAoNCgUEBwIBARIE9wIJ
EwoNCgUEBwIBAxIE9wIWFwoNCgUEBwIBCBIE9wIYQAoQCggEBwIBCJwIABIE9wIZP2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation ===
    # Fields for Federation
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.metastore.v1alpha.Federation.LabelsEntry)
    # Field: version Type: 9 ()
    # Field: backend_metastores Type: 11 (.google.cloud.metastore.v1alpha.Federation.BackendMetastoresEntry)
    # Field: endpoint_uri Type: 9 ()
    # Field: state Type: 14 (.google.cloud.metastore.v1alpha.Federation.State)
    # Field: state_message Type: 9 ()
    # Field: uid Type: 9 ()

# Enum: Federation::State
our $Federation_STATE_UNSPECIFIED = 0;
our $Federation_CREATING = 1;
our $Federation_ACTIVE = 2;
our $Federation_UPDATING = 3;
our $Federation_DELETING = 4;
our $Federation_ERROR = 5;

# === Message: Google::Cloud::Metastore::V1alpha::MetastoreFederation::BackendMetastore ===
    # Fields for BackendMetastore
    # Field: name Type: 9 ()
    # Field: metastore_type Type: 14 (.google.cloud.metastore.v1alpha.BackendMetastore.MetastoreType)

# Enum: BackendMetastore::MetastoreType
our $BackendMetastore_METASTORE_TYPE_UNSPECIFIED = 0;
our $BackendMetastore_DATAPLEX = 1;
our $BackendMetastore_BIGQUERY = 2;
our $BackendMetastore_DATAPROC_METASTORE = 3;

# === Message: Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsRequest ===
    # Fields for ListFederationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsResponse ===
    # Fields for ListFederationsResponse
    # Field: federations Type: 11 (.google.cloud.metastore.v1alpha.Federation)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Metastore::V1alpha::MetastoreFederation::GetFederationRequest ===
    # Fields for GetFederationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Metastore::V1alpha::MetastoreFederation::CreateFederationRequest ===
    # Fields for CreateFederationRequest
    # Field: parent Type: 9 ()
    # Field: federation_id Type: 9 ()
    # Field: federation Type: 11 (.google.cloud.metastore.v1alpha.Federation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Metastore::V1alpha::MetastoreFederation::UpdateFederationRequest ===
    # Fields for UpdateFederationRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: federation Type: 11 (.google.cloud.metastore.v1alpha.Federation)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Metastore::V1alpha::MetastoreFederation::DeleteFederationRequest ===
    # Fields for DeleteFederationRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Service Client: Google::Cloud::Metastore::V1alpha::MetastoreFederation::DataprocMetastoreFederationClient ===
package Google::Cloud::Metastore::V1alpha::MetastoreFederation::DataprocMetastoreFederationClient;

=pod

=head2 Service Client: Google::Cloud::Metastore::V1alpha::MetastoreFederation::DataprocMetastoreFederationClient

Client stub representing the remote C<DataprocMetastoreFederation> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<metastore.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'metastore.googleapis.com:443' );

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

sub list_federations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1alpha.DataprocMetastoreFederation',
        method         => 'ListFederations',
        request        => $req,
        response_class => 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsResponse',
    });
}

sub get_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1alpha::MetastoreFederation::GetFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1alpha.DataprocMetastoreFederation',
        method         => 'GetFederation',
        request        => $req,
        response_class => 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation',
    });
}

sub create_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1alpha::MetastoreFederation::CreateFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1alpha.DataprocMetastoreFederation',
        method         => 'CreateFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1alpha::MetastoreFederation::UpdateFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1alpha.DataprocMetastoreFederation',
        method         => 'UpdateFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_federation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Metastore::V1alpha::MetastoreFederation::DeleteFederationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.metastore.v1alpha.DataprocMetastoreFederation',
        method         => 'DeleteFederation',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Metastore::V1alpha::MetastoreFederation - Compiled Protocol Buffers messages for google/cloud/metastore/v1alpha/metastore_federation.proto

=head1 SYNOPSIS

    use Google::Cloud::Metastore::V1alpha::MetastoreFederation;

    my $msg = Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/metastore/v1alpha/metastore_federation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation

Represents a federation of multiple backend metastores.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The relative resource name of the federation, of the
form:
projects/{project_number}/locations/{location_id}/federations/{federation_id}`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the metastore federation was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the metastore federation was last updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation::LabelsEntry>)

User-defined labels for the metastore federation.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Immutable. The Apache Hive metastore version of the federation. All backend
metastore versions must be compatible with the federation version.

=item * C<< $msg->backend_metastores() >> / C<< $msg->backend_metastores($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation::BackendMetastoresEntry>)

A map from `BackendMetastore` rank to `BackendMetastore`s from which the
federation service serves metadata at query time. The map key represents
the order in which `BackendMetastore`s should be evaluated to resolve
database names at query time and should be greater than or equal to zero. A
`BackendMetastore` with a lower number will be evaluated before a
`BackendMetastore` with a higher number.

=item * C<< $msg->endpoint_uri() >> / C<< $msg->endpoint_uri($value) >>

Type: C<String>

Output only. The federation endpoint.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Metastore::V1alpha::Federation::State>)

Output only. The current state of the federation.

=item * C<< $msg->state_message() >> / C<< $msg->state_message($value) >>

Type: C<String>

Output only. Additional information about the current state of the
metastore federation, if available.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The globally unique resource identifier of the metastore
federation.

=back

=head3 Enum: Federation::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=item * C<ERROR> => C<5>

=back

=head2 Google::Cloud::Metastore::V1alpha::MetastoreFederation::BackendMetastore

Represents a backend metastore for the federation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of the metastore that is being federated.
The formats of the relative resource names for the currently supported
metastores are listed below:

* BigQuery
    * `projects/{project_id}`
* Dataproc Metastore
    * `projects/{project_id}/locations/{location}/services/{service_id}`

=item * C<< $msg->metastore_type() >> / C<< $msg->metastore_type($value) >>

Type: C<Enum> (L<Google::Cloud::Metastore::V1alpha::BackendMetastore::MetastoreType>)

The type of the backend metastore.

=back

=head3 Enum: BackendMetastore::MetastoreType

=over 4

=item * C<METASTORE_TYPE_UNSPECIFIED> => C<0>

=item * C<DATAPLEX> => C<1>

=item * C<BIGQUERY> => C<2>

=item * C<DATAPROC_METASTORE> => C<3>

=back

=head2 Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsRequest

Request message for ListFederations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The relative resource name of the location of metastore
federations to list, in the following form:
`projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of federations to return. The response may
contain less than the maximum number. If unspecified, no more than 500
services are returned. The maximum value is 1000; values above 1000 are
changed to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous ListFederationServices
call. Provide this token to retrieve the subsequent page.

To retrieve the first page, supply an empty page token.

When paginating, other parameters provided to
ListFederationServices must match the call that provided the
page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter to apply to list results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Specify the ordering of results as described in [Sorting
Order](https://cloud.google.com/apis/design/design_patterns#sorting_order).
If not specified, the results will be sorted in the default order.

=back

=head2 Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsResponse

Response message for ListFederations

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->federations() >> / C<< $msg->federations($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation>)

The services in the specified location.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page. If this
field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Metastore::V1alpha::MetastoreFederation::GetFederationRequest

Request message for GetFederation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The relative resource name of the metastore federation to
retrieve, in the following form:

`projects/{project_number}/locations/{location_id}/federations/{federation_id}`.

=back

=head2 Google::Cloud::Metastore::V1alpha::MetastoreFederation::CreateFederationRequest

Request message for CreateFederation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The relative resource name of the location in which to create a
federation service, in the following form:

`projects/{project_number}/locations/{location_id}`.

=item * C<< $msg->federation_id() >> / C<< $msg->federation_id($value) >>

Type: C<String>

Required. The ID of the metastore federation, which is used as the final
component of the metastore federation's name.

This value must be between 2 and 63 characters long inclusive, begin with a
letter, end with a letter or number, and consist of alpha-numeric
ASCII characters or hyphens.

=item * C<< $msg->federation() >> / C<< $msg->federation($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation>)

Required. The Metastore Federation to create. The `name` field is
ignored. The ID of the created metastore federation must be
provided in the request's `federation_id` field.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID. Specify a unique request ID to allow the server to
ignore the request if it has completed. The server will ignore subsequent
requests that provide a duplicate request ID for at least 60 minutes after
the first request.

For example, if an initial request times out, followed by another request
with the same request ID, the server ignores the second request to prevent
the creation of duplicate commitments.

The request ID must be a valid
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Format)
A zero UUID (00000000-0000-0000-0000-000000000000) is not supported.

=back

=head2 Google::Cloud::Metastore::V1alpha::MetastoreFederation::UpdateFederationRequest

Request message for UpdateFederation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. A field mask used to specify the fields to be overwritten in the
metastore federation resource by the update.
Fields specified in the `update_mask` are relative to the resource (not
to the full request). A field is overwritten if it is in the mask.

=item * C<< $msg->federation() >> / C<< $msg->federation($value) >>

Type: C<Message> (L<Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation>)

Required. The metastore federation to update. The server only merges fields
in the service if they are specified in `update_mask`.

The metastore federation's `name` field is used to identify the
metastore service to be updated.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID. Specify a unique request ID to allow the server to
ignore the request if it has completed. The server will ignore subsequent
requests that provide a duplicate request ID for at least 60 minutes after
the first request.

For example, if an initial request times out, followed by another request
with the same request ID, the server ignores the second request to prevent
the creation of duplicate commitments.

The request ID must be a valid
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Format)
A zero UUID (00000000-0000-0000-0000-000000000000) is not supported.

=back

=head2 Google::Cloud::Metastore::V1alpha::MetastoreFederation::DeleteFederationRequest

Request message for DeleteFederation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The relative resource name of the metastore federation to delete,
in the following form:

`projects/{project_number}/locations/{location_id}/federations/{federation_id}`.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. A request ID. Specify a unique request ID to allow the server to
ignore the request if it has completed. The server will ignore subsequent
requests that provide a duplicate request ID for at least 60 minutes after
the first request.

For example, if an initial request times out, followed by another request
with the same request ID, the server ignores the second request to prevent
the creation of duplicate commitments.

The request ID must be a valid
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Format)
A zero UUID (00000000-0000-0000-0000-000000000000) is not supported.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Metastore::V1alpha::MetastoreFederation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
