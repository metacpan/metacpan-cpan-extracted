package Google::Ai::Generativelanguage::V1beta::DiscussService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta::Citation };
    eval { require Google::Ai::Generativelanguage::V1beta::Safety };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9kaXNjdXNzX3NlcnZpY2Uu
cHJvdG8SI2dvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhGjJnb29nbGUvYWkv
Z2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9jaXRhdGlvbi5wcm90bxowZ29vZ2xlL2FpL2dl
bmVyYXRpdmVsYW5ndWFnZS92MWJldGEvc2FmZXR5LnByb3RvGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKFAwoWR2VuZXJh
dGVNZXNzYWdlUmVxdWVzdBJFCgVtb2RlbBgBIAEoCUIv4EEC+kEpCidnZW5lcmF0aXZlbGFu
Z3VhZ2UuZ29vZ2xlYXBpcy5jb20vTW9kZWxSBW1vZGVsEk8KBnByb21wdBgCIAEoCzIyLmdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLk1lc3NhZ2VQcm9tcHRCA+BBAlIG
cHJvbXB0EioKC3RlbXBlcmF0dXJlGAMgASgCQgPgQQFIAFILdGVtcGVyYXR1cmWIAQESMQoP
Y2FuZGlkYXRlX2NvdW50GAQgASgFQgPgQQFIAVIOY2FuZGlkYXRlQ291bnSIAQESHQoFdG9w
X3AYBSABKAJCA+BBAUgCUgR0b3BQiAEBEh0KBXRvcF9rGAYgASgFQgPgQQFIA1IEdG9wS4gB
AUIOCgxfdGVtcGVyYXR1cmVCEgoQX2NhbmRpZGF0ZV9jb3VudEIICgZfdG9wX3BCCAoGX3Rv
cF9rIv8BChdHZW5lcmF0ZU1lc3NhZ2VSZXNwb25zZRJMCgpjYW5kaWRhdGVzGAEgAygLMiwu
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuTWVzc2FnZVIKY2FuZGlkYXRl
cxJICghtZXNzYWdlcxgCIAMoCzIsLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFi
ZXRhLk1lc3NhZ2VSCG1lc3NhZ2VzEkwKB2ZpbHRlcnMYAyADKAsyMi5nb29nbGUuYWkuZ2Vu
ZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5Db250ZW50RmlsdGVyUgdmaWx0ZXJzIskBCgdNZXNz
YWdlEhsKBmF1dGhvchgBIAEoCUID4EEBUgZhdXRob3ISHQoHY29udGVudBgCIAEoCUID4EEC
Ugdjb250ZW50EmwKEWNpdGF0aW9uX21ldGFkYXRhGAMgASgLMjUuZ29vZ2xlLmFpLmdlbmVy
YXRpdmVsYW5ndWFnZS52MWJldGEuQ2l0YXRpb25NZXRhZGF0YUID4EEDSABSEGNpdGF0aW9u
TWV0YWRhdGGIAQFCFAoSX2NpdGF0aW9uX21ldGFkYXRhIswBCg1NZXNzYWdlUHJvbXB0Eh0K
B2NvbnRleHQYASABKAlCA+BBAVIHY29udGV4dBJNCghleGFtcGxlcxgCIAMoCzIsLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkV4YW1wbGVCA+BBAVIIZXhhbXBsZXMS
TQoIbWVzc2FnZXMYAyADKAsyLC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0
YS5NZXNzYWdlQgPgQQJSCG1lc3NhZ2VzIp0BCgdFeGFtcGxlEkcKBWlucHV0GAEgASgLMiwu
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuTWVzc2FnZUID4EECUgVpbnB1
dBJJCgZvdXRwdXQYAiABKAsyLC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0
YS5NZXNzYWdlQgPgQQJSBm91dHB1dCKzAQoZQ291bnRNZXNzYWdlVG9rZW5zUmVxdWVzdBJF
CgVtb2RlbBgBIAEoCUIv4EEC+kEpCidnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5j
b20vTW9kZWxSBW1vZGVsEk8KBnByb21wdBgCIAEoCzIyLmdvb2dsZS5haS5nZW5lcmF0aXZl
bGFuZ3VhZ2UudjFiZXRhLk1lc3NhZ2VQcm9tcHRCA+BBAlIGcHJvbXB0Ij0KGkNvdW50TWVz
c2FnZVRva2Vuc1Jlc3BvbnNlEh8KC3Rva2VuX2NvdW50GAEgASgFUgp0b2tlbkNvdW50MpAE
Cg5EaXNjdXNzU2VydmljZRL4AQoPR2VuZXJhdGVNZXNzYWdlEjsuZ29vZ2xlLmFpLmdlbmVy
YXRpdmVsYW5ndWFnZS52MWJldGEuR2VuZXJhdGVNZXNzYWdlUmVxdWVzdBo8Lmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkdlbmVyYXRlTWVzc2FnZVJlc3BvbnNlImqC
0+STAi0iKC92MWJldGEve21vZGVsPW1vZGVscy8qfTpnZW5lcmF0ZU1lc3NhZ2U6ASraQTRt
b2RlbCxwcm9tcHQsdGVtcGVyYXR1cmUsY2FuZGlkYXRlX2NvdW50LHRvcF9wLHRvcF9rEtwB
ChJDb3VudE1lc3NhZ2VUb2tlbnMSPi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYx
YmV0YS5Db3VudE1lc3NhZ2VUb2tlbnNSZXF1ZXN0Gj8uZ29vZ2xlLmFpLmdlbmVyYXRpdmVs
YW5ndWFnZS52MWJldGEuQ291bnRNZXNzYWdlVG9rZW5zUmVzcG9uc2UiRYLT5JMCMCIrL3Yx
YmV0YS97bW9kZWw9bW9kZWxzLyp9OmNvdW50TWVzc2FnZVRva2VuczoBKtpBDG1vZGVsLHBy
b21wdBokykEhZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tQp8BCidjb20uZ29v
Z2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGFCE0Rpc2N1c3NTZXJ2aWNlUHJvdG9Q
AVpdY2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvYXBpdjFiZXRh
L2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSo9CCgcSBQ4A9QEB
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
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMS
ADwKCQoCAwESAxMAOgoJCgIDAhIDFAAmCgkKAgMDEgMVACEKCQoCAwQSAxYAKQoJCgIDBRID
FwAjCggKAQgSAxkAdAoJCgIICxIDGQB0CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsA
NAoJCgIICBIDGwA0CggKAQgSAxwAQAoJCgIIARIDHABACskBCgIGABIEIgA5ARq8ASBBbiBB
UEkgZm9yIHVzaW5nIEdlbmVyYXRpdmUgTGFuZ3VhZ2UgTW9kZWxzIChHTE1zKSBpbiBkaWFs
b2cgYXBwbGljYXRpb25zLgoKIEFsc28ga25vd24gYXMgbGFyZ2UgbGFuZ3VhZ2UgbW9kZWxz
IChMTE1zKSwgdGhpcyBBUEkgcHJvdmlkZXMgbW9kZWxzIHRoYXQKIGFyZSB0cmFpbmVkIGZv
ciBtdWx0aS10dXJuIGRpYWxvZy4KCgoKAwYAARIDIggWCgoKAwYAAxIDIwJJCgwKBQYAA5kI
EgMjAkkKUwoEBgACABIEJgIuAxpFIEdlbmVyYXRlcyBhIHJlc3BvbnNlIGZyb20gdGhlIG1v
ZGVsIGdpdmVuIGFuIGlucHV0IGBNZXNzYWdlUHJvbXB0YC4KCgwKBQYAAgABEgMmBhUKDAoF
BgACAAISAyYWLAoMCgUGAAIAAxIDJw8mCg0KBQYAAgAEEgQoBCsGChEKCQYAAgAEsMq8IhIE
KAQrBgoNCgUGAAIABBIELAQtPwoQCggGAAIABJsIABIELAQtPwpRCgQGAAIBEgQxAjgDGkMg
UnVucyBhIG1vZGVsJ3MgdG9rZW5pemVyIG9uIGEgc3RyaW5nIGFuZCByZXR1cm5zIHRoZSB0
b2tlbiBjb3VudC4KCgwKBQYAAgEBEgMxBhgKDAoFBgACAQISAzEZMgoMCgUGAAIBAxIDMg8p
Cg0KBQYAAgEEEgQzBDYGChEKCQYAAgEEsMq8IhIEMwQ2BgoMCgUGAAIBBBIDNwQ6Cg8KCAYA
AgEEmwgAEgM3BDoKRAoCBAASBDwAawEaOCBSZXF1ZXN0IHRvIGdlbmVyYXRlIGEgbWVzc2Fn
ZSByZXNwb25zZSBmcm9tIHRoZSBtb2RlbC4KCgoKAwQAARIDPAgeClgKBAQAAgASBEACRQQa
SiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIG1vZGVsIHRvIHVzZS4KCiBGb3JtYXQ6IGBu
YW1lPW1vZGVscy97bW9kZWx9YC4KCgwKBQQAAgAFEgNAAggKDAoFBAACAAESA0AJDgoMCgUE
AAIAAxIDQBESCg0KBQQAAgAIEgRAE0UDCg8KCAQAAgAInAgAEgNBBCoKDwoHBAACAAifCBIE
QgREBQq4AQoEBAACARIDTAJEGqoBIFJlcXVpcmVkLiBUaGUgc3RydWN0dXJlZCB0ZXh0dWFs
IGlucHV0IGdpdmVuIHRvIHRoZSBtb2RlbCBhcyBhIHByb21wdC4KCiBHaXZlbiBhCiBwcm9t
cHQsIHRoZSBtb2RlbCB3aWxsIHJldHVybiB3aGF0IGl0IHByZWRpY3RzIGlzIHRoZSBuZXh0
IG1lc3NhZ2UgaW4gdGhlCiBkaXNjdXNzaW9uLgoKDAoFBAACAQYSA0wCDwoMCgUEAAIBARID
TBAWCgwKBQQAAgEDEgNMGRoKDAoFBAACAQgSA0wbQwoPCggEAAIBCJwIABIDTBxCCpkCCgQE
AAICEgNUAkoaiwIgT3B0aW9uYWwuIENvbnRyb2xzIHRoZSByYW5kb21uZXNzIG9mIHRoZSBv
dXRwdXQuCgogVmFsdWVzIGNhbiByYW5nZSBvdmVyIGBbMC4wLDEuMF1gLAogaW5jbHVzaXZl
LiBBIHZhbHVlIGNsb3NlciB0byBgMS4wYCB3aWxsIHByb2R1Y2UgcmVzcG9uc2VzIHRoYXQg
YXJlIG1vcmUKIHZhcmllZCwgd2hpbGUgYSB2YWx1ZSBjbG9zZXIgdG8gYDAuMGAgd2lsbCB0
eXBpY2FsbHkgcmVzdWx0IGluCiBsZXNzIHN1cnByaXNpbmcgcmVzcG9uc2VzIGZyb20gdGhl
IG1vZGVsLgoKDAoFBAACAgQSA1QCCgoMCgUEAAICBRIDVAsQCgwKBQQAAgIBEgNUERwKDAoF
BAACAgMSA1QfIAoMCgUEAAICCBIDVCFJCg8KCAQAAgIInAgAEgNUIkgKpQEKBAQAAgMSA1oC
ThqXASBPcHRpb25hbC4gVGhlIG51bWJlciBvZiBnZW5lcmF0ZWQgcmVzcG9uc2UgbWVzc2Fn
ZXMgdG8gcmV0dXJuLgoKIFRoaXMgdmFsdWUgbXVzdCBiZSBiZXR3ZWVuCiBgWzEsIDhdYCwg
aW5jbHVzaXZlLiBJZiB1bnNldCwgdGhpcyB3aWxsIGRlZmF1bHQgdG8gYDFgLgoKDAoFBAAC
AwQSA1oCCgoMCgUEAAIDBRIDWgsQCgwKBQQAAgMBEgNaESAKDAoFBAACAwMSA1ojJAoMCgUE
AAIDCBIDWiVNCg8KCAQAAgMInAgAEgNaJkwK/AEKBAQAAgQSA2MCRBruASBPcHRpb25hbC4g
VGhlIG1heGltdW0gY3VtdWxhdGl2ZSBwcm9iYWJpbGl0eSBvZiB0b2tlbnMgdG8gY29uc2lk
ZXIgd2hlbgogc2FtcGxpbmcuCgogVGhlIG1vZGVsIHVzZXMgY29tYmluZWQgVG9wLWsgYW5k
IG51Y2xldXMgc2FtcGxpbmcuCgogTnVjbGV1cyBzYW1wbGluZyBjb25zaWRlcnMgdGhlIHNt
YWxsZXN0IHNldCBvZiB0b2tlbnMgd2hvc2UgcHJvYmFiaWxpdHkKIHN1bSBpcyBhdCBsZWFz
dCBgdG9wX3BgLgoKDAoFBAACBAQSA2MCCgoMCgUEAAIEBRIDYwsQCgwKBQQAAgQBEgNjERYK
DAoFBAACBAMSA2MZGgoMCgUEAAIECBIDYxtDCg8KCAQAAgQInAgAEgNjHEIKywEKBAQAAgUS
A2oCRBq9ASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHRva2VucyB0byBjb25z
aWRlciB3aGVuIHNhbXBsaW5nLgoKIFRoZSBtb2RlbCB1c2VzIGNvbWJpbmVkIFRvcC1rIGFu
ZCBudWNsZXVzIHNhbXBsaW5nLgoKIFRvcC1rIHNhbXBsaW5nIGNvbnNpZGVycyB0aGUgc2V0
IG9mIGB0b3Bfa2AgbW9zdCBwcm9iYWJsZSB0b2tlbnMuCgoMCgUEAAIFBBIDagIKCgwKBQQA
AgUFEgNqCxAKDAoFBAACBQESA2oRFgoMCgUEAAIFAxIDahkaCgwKBQQAAgUIEgNqG0MKDwoI
BAACBQicCAASA2ocQgqZAQoCBAESBHEAfwEajAEgVGhlIHJlc3BvbnNlIGZyb20gdGhlIG1v
ZGVsLgoKIFRoaXMgaW5jbHVkZXMgY2FuZGlkYXRlIG1lc3NhZ2VzIGFuZAogY29udmVyc2F0
aW9uIGhpc3RvcnkgaW4gdGhlIGZvcm0gb2YgY2hyb25vbG9naWNhbGx5LW9yZGVyZWQgbWVz
c2FnZXMuCgoKCgMEAQESA3EIHwo6CgQEAQIAEgNzAiIaLSBDYW5kaWRhdGUgcmVzcG9uc2Ug
bWVzc2FnZXMgZnJvbSB0aGUgbW9kZWwuCgoMCgUEAQIABBIDcwIKCgwKBQQBAgAGEgNzCxIK
DAoFBAECAAESA3MTHQoMCgUEAQIAAxIDcyAhCjoKBAQBAgESA3YCIBotIFRoZSBjb252ZXJz
YXRpb24gaGlzdG9yeSB1c2VkIGJ5IHRoZSBtb2RlbC4KCgwKBQQBAgEEEgN2AgoKDAoFBAEC
AQYSA3YLEgoMCgUEAQIBARIDdhMbCgwKBQQBAgEDEgN2Hh8KkQIKBAQBAgISA34CJRqDAiBB
IHNldCBvZiBjb250ZW50IGZpbHRlcmluZyBtZXRhZGF0YSBmb3IgdGhlIHByb21wdCBhbmQg
cmVzcG9uc2UKIHRleHQuCgogVGhpcyBpbmRpY2F0ZXMgd2hpY2ggYFNhZmV0eUNhdGVnb3J5
YChzKSBibG9ja2VkIGEKIGNhbmRpZGF0ZSBmcm9tIHRoaXMgcmVzcG9uc2UsIHRoZSBsb3dl
c3QgYEhhcm1Qcm9iYWJpbGl0eWAKIHRoYXQgdHJpZ2dlcmVkIGEgYmxvY2ssIGFuZCB0aGUg
SGFybVRocmVzaG9sZCBzZXR0aW5nIGZvciB0aGF0IGNhdGVnb3J5LgoKDAoFBAECAgQSA34C
CgoMCgUEAQICBhIDfgsYCgwKBQQBAgIBEgN+GSAKDAoFBAECAgMSA34jJArKAQoCBAISBogB
AJwBARq7ASBUaGUgYmFzZSB1bml0IG9mIHN0cnVjdHVyZWQgdGV4dC4KCiBBIGBNZXNzYWdl
YCBpbmNsdWRlcyBhbiBgYXV0aG9yYCBhbmQgdGhlIGBjb250ZW50YCBvZgogdGhlIGBNZXNz
YWdlYC4KCiBUaGUgYGF1dGhvcmAgaXMgdXNlZCB0byB0YWcgbWVzc2FnZXMgd2hlbiB0aGV5
IGFyZSBmZWQgdG8gdGhlCiBtb2RlbCBhcyB0ZXh0LgoKCwoDBAIBEgSIAQgPCsgBCgQEAgIA
EgSPAQI9GrkBIE9wdGlvbmFsLiBUaGUgYXV0aG9yIG9mIHRoaXMgTWVzc2FnZS4KCiBUaGlz
IHNlcnZlcyBhcyBhIGtleSBmb3IgdGFnZ2luZwogdGhlIGNvbnRlbnQgb2YgdGhpcyBNZXNz
YWdlIHdoZW4gaXQgaXMgZmVkIHRvIHRoZSBtb2RlbCBhcyB0ZXh0LgoKIFRoZSBhdXRob3Ig
Y2FuIGJlIGFueSBhbHBoYW51bWVyaWMgc3RyaW5nLgoKDQoFBAICAAUSBI8BAggKDQoFBAIC
AAESBI8BCQ8KDQoFBAICAAMSBI8BEhMKDQoFBAICAAgSBI8BFDwKEAoIBAICAAicCAASBI8B
FTsKRwoEBAICARIEkgECPho5IFJlcXVpcmVkLiBUaGUgdGV4dCBjb250ZW50IG9mIHRoZSBz
dHJ1Y3R1cmVkIGBNZXNzYWdlYC4KCg0KBQQCAgEFEgSSAQIICg0KBQQCAgEBEgSSAQkQCg0K
BQQCAgEDEgSSARMUCg0KBQQCAgEIEgSSARU9ChAKCAQCAgEInAgAEgSSARY8CqgCCgQEAgIC
EgaaAQKbATIalwIgT3V0cHV0IG9ubHkuIENpdGF0aW9uIGluZm9ybWF0aW9uIGZvciBtb2Rl
bC1nZW5lcmF0ZWQgYGNvbnRlbnRgIGluIHRoaXMKIGBNZXNzYWdlYC4KCiBJZiB0aGlzIGBN
ZXNzYWdlYCB3YXMgZ2VuZXJhdGVkIGFzIG91dHB1dCBmcm9tIHRoZSBtb2RlbCwgdGhpcyBm
aWVsZCBtYXkgYmUKIHBvcHVsYXRlZCB3aXRoIGF0dHJpYnV0aW9uIGluZm9ybWF0aW9uIGZv
ciBhbnkgdGV4dCBpbmNsdWRlZCBpbiB0aGUKIGBjb250ZW50YC4gVGhpcyBmaWVsZCBpcyB1
c2VkIG9ubHkgb24gb3V0cHV0LgoKDQoFBAICAgQSBJoBAgoKDQoFBAICAgYSBJoBCxsKDQoF
BAICAgESBJoBHC0KDQoFBAICAgMSBJoBMDEKDQoFBAICAggSBJsBBjEKEAoIBAICAgicCAAS
BJsBBzAKpgMKAgQDEgalAQDKAQEalwMgQWxsIG9mIHRoZSBzdHJ1Y3R1cmVkIGlucHV0IHRl
eHQgcGFzc2VkIHRvIHRoZSBtb2RlbCBhcyBhIHByb21wdC4KCiBBIGBNZXNzYWdlUHJvbXB0
YCBjb250YWlucyBhIHN0cnVjdHVyZWQgc2V0IG9mIGZpZWxkcyB0aGF0IHByb3ZpZGUgY29u
dGV4dAogZm9yIHRoZSBjb252ZXJzYXRpb24sIGV4YW1wbGVzIG9mIHVzZXIgaW5wdXQvbW9k
ZWwgb3V0cHV0IG1lc3NhZ2UgcGFpcnMgdGhhdAogcHJpbWUgdGhlIG1vZGVsIHRvIHJlc3Bv
bmQgaW4gZGlmZmVyZW50IHdheXMsIGFuZCB0aGUgY29udmVyc2F0aW9uIGhpc3RvcnkKIG9y
IGxpc3Qgb2YgbWVzc2FnZXMgcmVwcmVzZW50aW5nIHRoZSBhbHRlcm5hdGluZyB0dXJucyBv
ZiB0aGUgY29udmVyc2F0aW9uCiBiZXR3ZWVuIHRoZSB1c2VyIGFuZCB0aGUgbW9kZWwuCgoL
CgMEAwESBKUBCBUKyQUKBAQDAgASBLUBAj4augUgT3B0aW9uYWwuIFRleHQgdGhhdCBzaG91
bGQgYmUgcHJvdmlkZWQgdG8gdGhlIG1vZGVsIGZpcnN0IHRvIGdyb3VuZCB0aGUKIHJlc3Bv
bnNlLgoKIElmIG5vdCBlbXB0eSwgdGhpcyBgY29udGV4dGAgd2lsbCBiZSBnaXZlbiB0byB0
aGUgbW9kZWwgZmlyc3QgYmVmb3JlIHRoZQogYGV4YW1wbGVzYCBhbmQgYG1lc3NhZ2VzYC4g
V2hlbiB1c2luZyBhIGBjb250ZXh0YCBiZSBzdXJlIHRvIHByb3ZpZGUgaXQKIHdpdGggZXZl
cnkgcmVxdWVzdCB0byBtYWludGFpbiBjb250aW51aXR5LgoKIFRoaXMgZmllbGQgY2FuIGJl
IGEgZGVzY3JpcHRpb24gb2YgeW91ciBwcm9tcHQgdG8gdGhlIG1vZGVsIHRvIGhlbHAgcHJv
dmlkZQogY29udGV4dCBhbmQgZ3VpZGUgdGhlIHJlc3BvbnNlcy4gRXhhbXBsZXM6ICJUcmFu
c2xhdGUgdGhlIHBocmFzZSBmcm9tCiBFbmdsaXNoIHRvIEZyZW5jaC4iIG9yICJHaXZlbiBh
IHN0YXRlbWVudCwgY2xhc3NpZnkgdGhlIHNlbnRpbWVudCBhcyBoYXBweSwKIHNhZCBvciBu
ZXV0cmFsLiIKCiBBbnl0aGluZyBpbmNsdWRlZCBpbiB0aGlzIGZpZWxkIHdpbGwgdGFrZSBw
cmVjZWRlbmNlIG92ZXIgbWVzc2FnZSBoaXN0b3J5CiBpZiB0aGUgdG90YWwgaW5wdXQgc2l6
ZSBleGNlZWRzIHRoZSBtb2RlbCdzIGBpbnB1dF90b2tlbl9saW1pdGAgYW5kIHRoZQogaW5w
dXQgcmVxdWVzdCBpcyB0cnVuY2F0ZWQuCgoNCgUEAwIABRIEtQECCAoNCgUEAwIAARIEtQEJ
EAoNCgUEAwIAAxIEtQETFAoNCgUEAwIACBIEtQEVPQoQCggEAwIACJwIABIEtQEWPAq1AwoE
BAMCARIEwAECSRqmAyBPcHRpb25hbC4gRXhhbXBsZXMgb2Ygd2hhdCB0aGUgbW9kZWwgc2hv
dWxkIGdlbmVyYXRlLgoKIFRoaXMgaW5jbHVkZXMgYm90aCB1c2VyIGlucHV0IGFuZCB0aGUg
cmVzcG9uc2UgdGhhdCB0aGUgbW9kZWwgc2hvdWxkCiBlbXVsYXRlLgoKIFRoZXNlIGBleGFt
cGxlc2AgYXJlIHRyZWF0ZWQgaWRlbnRpY2FsbHkgdG8gY29udmVyc2F0aW9uIG1lc3NhZ2Vz
IGV4Y2VwdAogdGhhdCB0aGV5IHRha2UgcHJlY2VkZW5jZSBvdmVyIHRoZSBoaXN0b3J5IGlu
IGBtZXNzYWdlc2A6CiBJZiB0aGUgdG90YWwgaW5wdXQgc2l6ZSBleGNlZWRzIHRoZSBtb2Rl
bCdzIGBpbnB1dF90b2tlbl9saW1pdGAgdGhlIGlucHV0CiB3aWxsIGJlIHRydW5jYXRlZC4g
SXRlbXMgd2lsbCBiZSBkcm9wcGVkIGZyb20gYG1lc3NhZ2VzYCBiZWZvcmUgYGV4YW1wbGVz
YC4KCg0KBQQDAgEEEgTAAQIKCg0KBQQDAgEGEgTAAQsSCg0KBQQDAgEBEgTAARMbCg0KBQQD
AgEDEgTAAR4fCg0KBQQDAgEIEgTAASBIChAKCAQDAgEInAgAEgTAASFHCpoCCgQEAwICEgTJ
AQJJGosCIFJlcXVpcmVkLiBBIHNuYXBzaG90IG9mIHRoZSByZWNlbnQgY29udmVyc2F0aW9u
IGhpc3Rvcnkgc29ydGVkCiBjaHJvbm9sb2dpY2FsbHkuCgogVHVybnMgYWx0ZXJuYXRlIGJl
dHdlZW4gdHdvIGF1dGhvcnMuCgogSWYgdGhlIHRvdGFsIGlucHV0IHNpemUgZXhjZWVkcyB0
aGUgbW9kZWwncyBgaW5wdXRfdG9rZW5fbGltaXRgIHRoZSBpbnB1dAogd2lsbCBiZSB0cnVu
Y2F0ZWQ6IFRoZSBvbGRlc3QgaXRlbXMgd2lsbCBiZSBkcm9wcGVkIGZyb20gYG1lc3NhZ2Vz
YC4KCg0KBQQDAgIEEgTJAQIKCg0KBQQDAgIGEgTJAQsSCg0KBQQDAgIBEgTJARMbCg0KBQQD
AgIDEgTJAR4fCg0KBQQDAgIIEgTJASBIChAKCAQDAgIInAgAEgTJASFHCooBCgIEBBIGzwEA
1QEBGnwgQW4gaW5wdXQvb3V0cHV0IGV4YW1wbGUgdXNlZCB0byBpbnN0cnVjdCB0aGUgTW9k
ZWwuCgogSXQgZGVtb25zdHJhdGVzIGhvdyB0aGUgbW9kZWwgc2hvdWxkIHJlc3BvbmQgb3Ig
Zm9ybWF0IGl0cyByZXNwb25zZS4KCgsKAwQEARIEzwEIDwpJCgQEBAIAEgTRAQI9GjsgUmVx
dWlyZWQuIEFuIGV4YW1wbGUgb2YgYW4gaW5wdXQgYE1lc3NhZ2VgIGZyb20gdGhlIHVzZXIu
CgoNCgUEBAIABhIE0QECCQoNCgUEBAIAARIE0QEKDwoNCgUEBAIAAxIE0QESEwoNCgUEBAIA
CBIE0QEUPAoQCggEBAIACJwIABIE0QEVOwpVCgQEBAIBEgTUAQI+GkcgUmVxdWlyZWQuIEFu
IGV4YW1wbGUgb2Ygd2hhdCB0aGUgbW9kZWwgc2hvdWxkIG91dHB1dCBnaXZlbiB0aGUgaW5w
dXQuCgoNCgUEBAIBBhIE1AECCQoNCgUEBAIBARIE1AEKEAoNCgUEBAIBAxIE1AETFAoNCgUE
BAIBCBIE1AEVPQoQCggEBAIBCJwIABIE1AEWPAqqAQoCBAUSBtsBAOsBARqbASBDb3VudHMg
dGhlIG51bWJlciBvZiB0b2tlbnMgaW4gdGhlIGBwcm9tcHRgIHNlbnQgdG8gYSBtb2RlbC4K
CiBNb2RlbHMgbWF5IHRva2VuaXplIHRleHQgZGlmZmVyZW50bHksIHNvIGVhY2ggbW9kZWwg
bWF5IHJldHVybiBhIGRpZmZlcmVudAogYHRva2VuX2NvdW50YC4KCgsKAwQFARIE2wEIIQrJ
AQoEBAUCABIG4gEC5wEEGrgBIFJlcXVpcmVkLiBUaGUgbW9kZWwncyByZXNvdXJjZSBuYW1l
LiBUaGlzIHNlcnZlcyBhcyBhbiBJRCBmb3IgdGhlIE1vZGVsIHRvCiB1c2UuCgogVGhpcyBu
YW1lIHNob3VsZCBtYXRjaCBhIG1vZGVsIG5hbWUgcmV0dXJuZWQgYnkgdGhlIGBMaXN0TW9k
ZWxzYCBtZXRob2QuCgogRm9ybWF0OiBgbW9kZWxzL3ttb2RlbH1gCgoNCgUEBQIABRIE4gEC
CAoNCgUEBQIAARIE4gEJDgoNCgUEBQIAAxIE4gEREgoPCgUEBQIACBIG4gET5wEDChAKCAQF
AgAInAgAEgTjAQQqChEKBwQFAgAInwgSBuQBBOYBBQpKCgQEBQIBEgTqAQJEGjwgUmVxdWly
ZWQuIFRoZSBwcm9tcHQsIHdob3NlIHRva2VuIGNvdW50IGlzIHRvIGJlIHJldHVybmVkLgoK
DQoFBAUCAQYSBOoBAg8KDQoFBAUCAQESBOoBEBYKDQoFBAUCAQMSBOoBGRoKDQoFBAUCAQgS
BOoBG0MKEAoIBAUCAQicCAASBOoBHEIKbgoCBAYSBvABAPUBARpgIEEgcmVzcG9uc2UgZnJv
bSBgQ291bnRNZXNzYWdlVG9rZW5zYC4KCiBJdCByZXR1cm5zIHRoZSBtb2RlbCdzIGB0b2tl
bl9jb3VudGAgZm9yIHRoZSBgcHJvbXB0YC4KCgsKAwQGARIE8AEIIgppCgQEBgIAEgT0AQIY
GlsgVGhlIG51bWJlciBvZiB0b2tlbnMgdGhhdCB0aGUgYG1vZGVsYCB0b2tlbml6ZXMgdGhl
IGBwcm9tcHRgIGludG8uCgogQWx3YXlzIG5vbi1uZWdhdGl2ZS4KCg0KBQQGAgAFEgT0AQIH
Cg0KBQQGAgABEgT0AQgTCg0KBQQGAgADEgT0ARYXYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest ===
    # Fields for GenerateMessageRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1beta.MessagePrompt)
    # Field: temperature Type: 2 ()
    # Field: candidate_count Type: 5 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()

# === Message: Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse ===
    # Fields for GenerateMessageResponse
    # Field: candidates Type: 11 (.google.ai.generativelanguage.v1beta.Message)
    # Field: messages Type: 11 (.google.ai.generativelanguage.v1beta.Message)
    # Field: filters Type: 11 (.google.ai.generativelanguage.v1beta.ContentFilter)

# === Message: Google::Ai::Generativelanguage::V1beta::DiscussService::Message ===
    # Fields for Message
    # Field: author Type: 9 ()
    # Field: content Type: 9 ()
    # Field: citation_metadata Type: 11 (.google.ai.generativelanguage.v1beta.CitationMetadata)

# === Message: Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt ===
    # Fields for MessagePrompt
    # Field: context Type: 9 ()
    # Field: examples Type: 11 (.google.ai.generativelanguage.v1beta.Example)
    # Field: messages Type: 11 (.google.ai.generativelanguage.v1beta.Message)

# === Message: Google::Ai::Generativelanguage::V1beta::DiscussService::Example ===
    # Fields for Example
    # Field: input Type: 11 (.google.ai.generativelanguage.v1beta.Message)
    # Field: output Type: 11 (.google.ai.generativelanguage.v1beta.Message)

# === Message: Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest ===
    # Fields for CountMessageTokensRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1beta.MessagePrompt)

# === Message: Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse ===
    # Fields for CountMessageTokensResponse
    # Field: token_count Type: 5 ()

# === Service Client: Google::Ai::Generativelanguage::V1beta::DiscussService::DiscussServiceClient ===
package Google::Ai::Generativelanguage::V1beta::DiscussService::DiscussServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1beta::DiscussService::DiscussServiceClient

Client stub representing the remote C<DiscussService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub generate_message {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.DiscussService',
        method         => 'GenerateMessage',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse',
    });
}

sub count_message_tokens {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.DiscussService',
        method         => 'CountMessageTokens',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta::DiscussService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/discuss_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::DiscussService;

    my $msg = Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest->new({
        model => $model,
        prompt => $prompt,
        temperature => $temperature,
        candidate_count => $candidate_count,
    });

    # Read or update a field
    my $val = $msg->model();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/discuss_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest

Request to generate a message response from the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The name of the model to use.

Format: `name=models/{model}`.

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt>)

Required. The structured textual input given to the model as a prompt.

Given a
prompt, the model will return what it predicts is the next message in the
discussion.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Optional. Controls the randomness of the output.

Values can range over `[0.0,1.0]`,
inclusive. A value closer to `1.0` will produce responses that are more
varied, while a value closer to `0.0` will typically result in
less surprising responses from the model.

=item * C<< $msg->candidate_count() >> / C<< $msg->candidate_count($value) >>

Type: C<Int32>

Optional. The number of generated response messages to return.

This value must be between
`[1, 8]`, inclusive. If unset, this will default to `1`.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

Optional. The maximum cumulative probability of tokens to consider when
sampling.

The model uses combined Top-k and nucleus sampling.

Nucleus sampling considers the smallest set of tokens whose probability
sum is at least `top_p`.

=item * C<< $msg->top_k() >> / C<< $msg->top_k($value) >>

Type: C<Int32>

Optional. The maximum number of tokens to consider when sampling.

The model uses combined Top-k and nucleus sampling.

Top-k sampling considers the set of `top_k` most probable tokens.

=back

=head2 Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse

The response from the model.

This includes candidate messages and
conversation history in the form of chronologically-ordered messages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->candidates() >> / C<< $msg->candidates($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::DiscussService::Message>)

Candidate response messages from the model.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::DiscussService::Message>)

The conversation history used by the model.

=item * C<< $msg->filters() >> / C<< $msg->filters($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Safety::ContentFilter>)

A set of content filtering metadata for the prompt and response
text.

This indicates which `SafetyCategory`(s) blocked a
candidate from this response, the lowest `HarmProbability`
that triggered a block, and the HarmThreshold setting for that category.

=back

=head2 Google::Ai::Generativelanguage::V1beta::DiscussService::Message

The base unit of structured text.

A `Message` includes an `author` and the `content` of
the `Message`.

The `author` is used to tag messages when they are fed to the
model as text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->author() >> / C<< $msg->author($value) >>

Type: C<String>

Optional. The author of this Message.

This serves as a key for tagging
the content of this Message when it is fed to the model as text.

The author can be any alphanumeric string.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Required. The text content of the structured `Message`.

=item * C<< $msg->citation_metadata() >> / C<< $msg->citation_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::Citation::CitationMetadata>)

Output only. Citation information for model-generated `content` in this
`Message`.

If this `Message` was generated as output from the model, this field may be
populated with attribution information for any text included in the
`content`. This field is used only on output.

=back

=head2 Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt

All of the structured input text passed to the model as a prompt.

A `MessagePrompt` contains a structured set of fields that provide context
for the conversation, examples of user input/model output message pairs that
prime the model to respond in different ways, and the conversation history
or list of messages representing the alternating turns of the conversation
between the user and the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<String>

Optional. Text that should be provided to the model first to ground the
response.

If not empty, this `context` will be given to the model first before the
`examples` and `messages`. When using a `context` be sure to provide it
with every request to maintain continuity.

This field can be a description of your prompt to the model to help provide
context and guide the responses. Examples: "Translate the phrase from
English to French." or "Given a statement, classify the sentiment as happy,
sad or neutral."

Anything included in this field will take precedence over message history
if the total input size exceeds the model's `input_token_limit` and the
input request is truncated.

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::DiscussService::Example>)

Optional. Examples of what the model should generate.

This includes both user input and the response that the model should
emulate.

These `examples` are treated identically to conversation messages except
that they take precedence over the history in `messages`:
If the total input size exceeds the model's `input_token_limit` the input
will be truncated. Items will be dropped from `messages` before `examples`.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::DiscussService::Message>)

Required. A snapshot of the recent conversation history sorted
chronologically.

Turns alternate between two authors.

If the total input size exceeds the model's `input_token_limit` the input
will be truncated: The oldest items will be dropped from `messages`.

=back

=head2 Google::Ai::Generativelanguage::V1beta::DiscussService::Example

An input/output example used to instruct the Model.

It demonstrates how the model should respond or format its response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input() >> / C<< $msg->input($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::DiscussService::Message>)

Required. An example of an input `Message` from the user.

=item * C<< $msg->output() >> / C<< $msg->output($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::DiscussService::Message>)

Required. An example of what the model should output given the input.

=back

=head2 Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest

Counts the number of tokens in the `prompt` sent to a model.

Models may tokenize text differently, so each model may return a different
`token_count`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The model's resource name. This serves as an ID for the Model to
use.

This name should match a model name returned by the `ListModels` method.

Format: `models/{model}`

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt>)

Required. The prompt, whose token count is to be returned.

=back

=head2 Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse

A response from `CountMessageTokens`.

It returns the model's `token_count` for the `prompt`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->token_count() >> / C<< $msg->token_count($value) >>

Type: C<Int32>

The number of tokens that the `model` tokenizes the `prompt` into.

Always non-negative.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::DiscussService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
