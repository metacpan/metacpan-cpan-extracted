package Google::Ai::Generativelanguage::V1alpha::TextService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1alpha::Citation };
    eval { require Google::Ai::Generativelanguage::V1alpha::Safety };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvdGV4dF9zZXJ2aWNlLnBy
b3RvEiRnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEaM2dvb2dsZS9haS9n
ZW5lcmF0aXZlbGFuZ3VhZ2UvdjFhbHBoYS9jaXRhdGlvbi5wcm90bxoxZ29vZ2xlL2FpL2dl
bmVyYXRpdmVsYW5ndWFnZS92MWFscGhhL3NhZmV0eS5wcm90bxocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iqgQKE0dlbmVy
YXRlVGV4dFJlcXVlc3QSGQoFbW9kZWwYASABKAlCA+BBAlIFbW9kZWwSTQoGcHJvbXB0GAIg
ASgLMjAuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLlRleHRQcm9tcHRC
A+BBAlIGcHJvbXB0EioKC3RlbXBlcmF0dXJlGAMgASgCQgPgQQFIAFILdGVtcGVyYXR1cmWI
AQESMQoPY2FuZGlkYXRlX2NvdW50GAQgASgFQgPgQQFIAVIOY2FuZGlkYXRlQ291bnSIAQES
NAoRbWF4X291dHB1dF90b2tlbnMYBSABKAVCA+BBAUgCUg9tYXhPdXRwdXRUb2tlbnOIAQES
HQoFdG9wX3AYBiABKAJCA+BBAUgDUgR0b3BQiAEBEh0KBXRvcF9rGAcgASgFQgPgQQFIBFIE
dG9wS4gBARJhCg9zYWZldHlfc2V0dGluZ3MYCCADKAsyMy5nb29nbGUuYWkuZ2VuZXJhdGl2
ZWxhbmd1YWdlLnYxYWxwaGEuU2FmZXR5U2V0dGluZ0ID4EEBUg5zYWZldHlTZXR0aW5ncxIl
Cg5zdG9wX3NlcXVlbmNlcxgJIAMoCVINc3RvcFNlcXVlbmNlc0IOCgxfdGVtcGVyYXR1cmVC
EgoQX2NhbmRpZGF0ZV9jb3VudEIUChJfbWF4X291dHB1dF90b2tlbnNCCAoGX3RvcF9wQggK
Bl90b3BfayKaAgoUR2VuZXJhdGVUZXh0UmVzcG9uc2USVAoKY2FuZGlkYXRlcxgBIAMoCzI0
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5UZXh0Q29tcGxldGlvblIK
Y2FuZGlkYXRlcxJNCgdmaWx0ZXJzGAMgAygLMjMuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWFscGhhLkNvbnRlbnRGaWx0ZXJSB2ZpbHRlcnMSXQoPc2FmZXR5X2ZlZWRiYWNr
GAQgAygLMjQuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLlNhZmV0eUZl
ZWRiYWNrUg5zYWZldHlGZWVkYmFjayIlCgpUZXh0UHJvbXB0EhcKBHRleHQYASABKAlCA+BB
AlIEdGV4dCKNAgoOVGV4dENvbXBsZXRpb24SGwoGb3V0cHV0GAEgASgJQgPgQQNSBm91dHB1
dBJZCg5zYWZldHlfcmF0aW5ncxgCIAMoCzIyLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3Vh
Z2UudjFhbHBoYS5TYWZldHlSYXRpbmdSDXNhZmV0eVJhdGluZ3MSbQoRY2l0YXRpb25fbWV0
YWRhdGEYAyABKAsyNi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuQ2l0
YXRpb25NZXRhZGF0YUID4EEDSABSEGNpdGF0aW9uTWV0YWRhdGGIAQFCFAoSX2NpdGF0aW9u
X21ldGFkYXRhInIKEEVtYmVkVGV4dFJlcXVlc3QSRQoFbW9kZWwYASABKAlCL+BBAvpBKQon
Z2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL01vZGVsUgVtb2RlbBIXCgR0ZXh0
GAIgASgJQgPgQQFSBHRleHQiegoRRW1iZWRUZXh0UmVzcG9uc2USVwoJZW1iZWRkaW5nGAEg
ASgLMi8uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkVtYmVkZGluZ0ID
4EEDSABSCWVtYmVkZGluZ4gBAUIMCgpfZW1iZWRkaW5nItIBChVCYXRjaEVtYmVkVGV4dFJl
cXVlc3QSRQoFbW9kZWwYASABKAlCL+BBAvpBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2ds
ZWFwaXMuY29tL01vZGVsUgVtb2RlbBIZCgV0ZXh0cxgCIAMoCUID4EEBUgV0ZXh0cxJXCghy
ZXF1ZXN0cxgDIAMoCzI2Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5F
bWJlZFRleHRSZXF1ZXN0QgPgQQFSCHJlcXVlc3RzIm4KFkJhdGNoRW1iZWRUZXh0UmVzcG9u
c2USVAoKZW1iZWRkaW5ncxgBIAMoCzIvLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2Uu
djFhbHBoYS5FbWJlZGRpbmdCA+BBA1IKZW1iZWRkaW5ncyIhCglFbWJlZGRpbmcSFAoFdmFs
dWUYASADKAJSBXZhbHVlIq4BChZDb3VudFRleHRUb2tlbnNSZXF1ZXN0EkUKBW1vZGVsGAEg
ASgJQi/gQQL6QSkKJ2dlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9Nb2RlbFIF
bW9kZWwSTQoGcHJvbXB0GAIgASgLMjAuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52
MWFscGhhLlRleHRQcm9tcHRCA+BBAlIGcHJvbXB0IjoKF0NvdW50VGV4dFRva2Vuc1Jlc3Bv
bnNlEh8KC3Rva2VuX2NvdW50GAEgASgFUgp0b2tlbkNvdW50Ms0HCgtUZXh0U2VydmljZRK0
AgoMR2VuZXJhdGVUZXh0EjkuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhh
LkdlbmVyYXRlVGV4dFJlcXVlc3QaOi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYx
YWxwaGEuR2VuZXJhdGVUZXh0UmVzcG9uc2UirAGC0+STAl0iJi92MWFscGhhL3ttb2RlbD1t
b2RlbHMvKn06Z2VuZXJhdGVUZXh0OgEqWjAiKy92MWFscGhhL3ttb2RlbD10dW5lZE1vZGVs
cy8qfTpnZW5lcmF0ZVRleHQ6ASraQUZtb2RlbCxwcm9tcHQsdGVtcGVyYXR1cmUsY2FuZGlk
YXRlX2NvdW50LG1heF9vdXRwdXRfdG9rZW5zLHRvcF9wLHRvcF9rErkBCglFbWJlZFRleHQS
Ni5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuRW1iZWRUZXh0UmVxdWVz
dBo3Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5FbWJlZFRleHRSZXNw
b25zZSI7gtPkkwIoIiMvdjFhbHBoYS97bW9kZWw9bW9kZWxzLyp9OmVtYmVkVGV4dDoBKtpB
Cm1vZGVsLHRleHQSzgEKDkJhdGNoRW1iZWRUZXh0EjsuZ29vZ2xlLmFpLmdlbmVyYXRpdmVs
YW5ndWFnZS52MWFscGhhLkJhdGNoRW1iZWRUZXh0UmVxdWVzdBo8Lmdvb2dsZS5haS5nZW5l
cmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5CYXRjaEVtYmVkVGV4dFJlc3BvbnNlIkGC0+STAi0i
KC92MWFscGhhL3ttb2RlbD1tb2RlbHMvKn06YmF0Y2hFbWJlZFRleHQ6ASraQQttb2RlbCx0
ZXh0cxLTAQoPQ291bnRUZXh0VG9rZW5zEjwuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFn
ZS52MWFscGhhLkNvdW50VGV4dFRva2Vuc1JlcXVlc3QaPS5nb29nbGUuYWkuZ2VuZXJhdGl2
ZWxhbmd1YWdlLnYxYWxwaGEuQ291bnRUZXh0VG9rZW5zUmVzcG9uc2UiQ4LT5JMCLiIpL3Yx
YWxwaGEve21vZGVsPW1vZGVscy8qfTpjb3VudFRleHRUb2tlbnM6ASraQQxtb2RlbCxwcm9t
cHQaJMpBIWdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbUKeAQooY29tLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYUIQVGV4dFNlcnZpY2VQcm90b1ABWl5j
bG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MWFscGhhL2dl
bmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVsYW5ndWFnZXBiSslQCgcSBQ4ArQIBCrwE
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
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSAD0K
CQoCAwESAxMAOwoJCgIDAhIDFAAmCgkKAgMDEgMVACEKCQoCAwQSAxYAKQoJCgIDBRIDFwAj
CggKAQgSAxkAdQoJCgIICxIDGQB1CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMQoJ
CgIICBIDGwAxCggKAQgSAxwAQQoJCgIIARIDHABBCsABCgIGABIEIgBPARqzASBBUEkgZm9y
IHVzaW5nIEdlbmVyYXRpdmUgTGFuZ3VhZ2UgTW9kZWxzIChHTE1zKSB0cmFpbmVkIHRvIGdl
bmVyYXRlIHRleHQuCgogQWxzbyBrbm93biBhcyBMYXJnZSBMYW5ndWFnZSBNb2RlbHMgKExM
TSlzLCB0aGVzZSBnZW5lcmF0ZSB0ZXh0IGdpdmVuIGFuCiBpbnB1dCBwcm9tcHQgZnJvbSB0
aGUgdXNlci4KCgoKAwYAARIDIggTCgoKAwYAAxIDIwJJCgwKBQYAA5kIEgMjAkkKSwoEBgAC
ABIEJgIxAxo9IEdlbmVyYXRlcyBhIHJlc3BvbnNlIGZyb20gdGhlIG1vZGVsIGdpdmVuIGFu
IGlucHV0IG1lc3NhZ2UuCgoMCgUGAAIAARIDJgYSCgwKBQYAAgACEgMmEyYKDAoFBgACAAMS
AyYxRQoNCgUGAAIABBIEJwQuBgoRCgkGAAIABLDKvCISBCcELgYKDQoFBgACAAQSBC8EMFEK
EAoIBgACAASbCAASBC8EMFEKTQoEBgACARIENAI6Axo/IEdlbmVyYXRlcyBhbiBlbWJlZGRp
bmcgZnJvbSB0aGUgbW9kZWwgZ2l2ZW4gYW4gaW5wdXQgbWVzc2FnZS4KCgwKBQYAAgEBEgM0
Bg8KDAoFBgACAQISAzQQIAoMCgUGAAIBAxIDNCs8Cg0KBQYAAgEEEgQ1BDgGChEKCQYAAgEE
sMq8IhIENQQ4BgoMCgUGAAIBBBIDOQQ4Cg8KCAYAAgEEmwgAEgM5BDgKZQoEBgACAhIEPgJE
AxpXIEdlbmVyYXRlcyBtdWx0aXBsZSBlbWJlZGRpbmdzIGZyb20gdGhlIG1vZGVsIGdpdmVu
IGlucHV0IHRleHQgaW4gYQogc3luY2hyb25vdXMgY2FsbC4KCgwKBQYAAgIBEgM+BhQKDAoF
BgACAgISAz4VKgoMCgUGAAICAxIDPjVLCg0KBQYAAgIEEgQ/BEIGChEKCQYAAgIEsMq8IhIE
PwRCBgoMCgUGAAICBBIDQwQ5Cg8KCAYAAgIEmwgAEgNDBDkKTwoEBgACAxIERwJOAxpBIFJ1
bnMgYSBtb2RlbCdzIHRva2VuaXplciBvbiBhIHRleHQgYW5kIHJldHVybnMgdGhlIHRva2Vu
IGNvdW50LgoKDAoFBgACAwESA0cGFQoMCgUGAAIDAhIDRxYsCgwKBQYAAgMDEgNIDyYKDQoF
BgACAwQSBEkETAYKEQoJBgACAwSwyrwiEgRJBEwGCgwKBQYAAgMEEgNNBDoKDwoIBgACAwSb
CAASA00EOgpNCgIEABIFUgCkAQEaQCBSZXF1ZXN0IHRvIGdlbmVyYXRlIGEgdGV4dCBjb21w
bGV0aW9uIHJlc3BvbnNlIGZyb20gdGhlIG1vZGVsLgoKCgoDBAABEgNSCBsKswEKBAQAAgAS
A1gCPBqlASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGBNb2RlbGAgb3IgYFR1bmVkTW9k
ZWxgIHRvIHVzZSBmb3IgZ2VuZXJhdGluZyB0aGUKIGNvbXBsZXRpb24uCiBFeGFtcGxlczoK
ICBtb2RlbHMvdGV4dC1iaXNvbi0wMDEKICB0dW5lZE1vZGVscy9zZW50ZW5jZS10cmFuc2xh
dG9yLXUzYjdtCgoMCgUEAAIABRIDWAIICgwKBQQAAgABEgNYCQ4KDAoFBAACAAMSA1gREgoM
CgUEAAIACBIDWBM7Cg8KCAQAAgAInAgAEgNYFDoKyAEKBAQAAgESA14CQRq6ASBSZXF1aXJl
ZC4gVGhlIGZyZWUtZm9ybSBpbnB1dCB0ZXh0IGdpdmVuIHRvIHRoZSBtb2RlbCBhcyBhIHBy
b21wdC4KCiBHaXZlbiBhIHByb21wdCwgdGhlIG1vZGVsIHdpbGwgZ2VuZXJhdGUgYSBUZXh0
Q29tcGxldGlvbiByZXNwb25zZSBpdAogcHJlZGljdHMgYXMgdGhlIGNvbXBsZXRpb24gb2Yg
dGhlIGlucHV0IHRleHQuCgoMCgUEAAIBBhIDXgIMCgwKBQQAAgEBEgNeDRMKDAoFBAACAQMS
A14WFwoMCgUEAAIBCBIDXhhACg8KCAQAAgEInAgAEgNeGT8KpwMKBAQAAgISA2gCShqZAyBP
cHRpb25hbC4gQ29udHJvbHMgdGhlIHJhbmRvbW5lc3Mgb2YgdGhlIG91dHB1dC4KIE5vdGU6
IFRoZSBkZWZhdWx0IHZhbHVlIHZhcmllcyBieSBtb2RlbCwgc2VlIHRoZSBgTW9kZWwudGVt
cGVyYXR1cmVgCiBhdHRyaWJ1dGUgb2YgdGhlIGBNb2RlbGAgcmV0dXJuZWQgdGhlIGBnZXRN
b2RlbGAgZnVuY3Rpb24uCgogVmFsdWVzIGNhbiByYW5nZSBmcm9tIFswLjAsMS4wXSwKIGlu
Y2x1c2l2ZS4gQSB2YWx1ZSBjbG9zZXIgdG8gMS4wIHdpbGwgcHJvZHVjZSByZXNwb25zZXMg
dGhhdCBhcmUgbW9yZQogdmFyaWVkIGFuZCBjcmVhdGl2ZSwgd2hpbGUgYSB2YWx1ZSBjbG9z
ZXIgdG8gMC4wIHdpbGwgdHlwaWNhbGx5IHJlc3VsdCBpbgogbW9yZSBzdHJhaWdodGZvcndh
cmQgcmVzcG9uc2VzIGZyb20gdGhlIG1vZGVsLgoKDAoFBAACAgQSA2gCCgoMCgUEAAICBRID
aAsQCgwKBQQAAgIBEgNoERwKDAoFBAACAgMSA2gfIAoMCgUEAAICCBIDaCFJCg8KCAQAAgII
nAgAEgNoIkgKlQEKBAQAAgMSA24CThqHASBPcHRpb25hbC4gTnVtYmVyIG9mIGdlbmVyYXRl
ZCByZXNwb25zZXMgdG8gcmV0dXJuLgoKIFRoaXMgdmFsdWUgbXVzdCBiZSBiZXR3ZWVuIFsx
LCA4XSwgaW5jbHVzaXZlLiBJZiB1bnNldCwgdGhpcyB3aWxsIGRlZmF1bHQKIHRvIDEuCgoM
CgUEAAIDBBIDbgIKCgwKBQQAAgMFEgNuCxAKDAoFBAACAwESA24RIAoMCgUEAAIDAxIDbiMk
CgwKBQQAAgMIEgNuJU0KDwoIBAACAwicCAASA24mTAquAQoEBAACBBIDdAJQGqABIE9wdGlv
bmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgdG9rZW5zIHRvIGluY2x1ZGUgaW4gYSBjYW5k
aWRhdGUuCgogSWYgdW5zZXQsIHRoaXMgd2lsbCBkZWZhdWx0IHRvIG91dHB1dF90b2tlbl9s
aW1pdCBzcGVjaWZpZWQgaW4gdGhlIGBNb2RlbGAKIHNwZWNpZmljYXRpb24uCgoMCgUEAAIE
BBIDdAIKCgwKBQQAAgQFEgN0CxAKDAoFBAACBAESA3QRIgoMCgUEAAIEAxIDdCUmCgwKBQQA
AgQIEgN0J08KDwoIBAACBAicCAASA3QoTgqkBAoEBAACBRIEggECRBqVBCBPcHRpb25hbC4g
VGhlIG1heGltdW0gY3VtdWxhdGl2ZSBwcm9iYWJpbGl0eSBvZiB0b2tlbnMgdG8gY29uc2lk
ZXIgd2hlbgogc2FtcGxpbmcuCgogVGhlIG1vZGVsIHVzZXMgY29tYmluZWQgVG9wLWsgYW5k
IG51Y2xldXMgc2FtcGxpbmcuCgogVG9rZW5zIGFyZSBzb3J0ZWQgYmFzZWQgb24gdGhlaXIg
YXNzaWduZWQgcHJvYmFiaWxpdGllcyBzbyB0aGF0IG9ubHkgdGhlCiBtb3N0IGxpa2VseSB0
b2tlbnMgYXJlIGNvbnNpZGVyZWQuIFRvcC1rIHNhbXBsaW5nIGRpcmVjdGx5IGxpbWl0cyB0
aGUKIG1heGltdW0gbnVtYmVyIG9mIHRva2VucyB0byBjb25zaWRlciwgd2hpbGUgTnVjbGV1
cyBzYW1wbGluZyBsaW1pdHMgbnVtYmVyCiBvZiB0b2tlbnMgYmFzZWQgb24gdGhlIGN1bXVs
YXRpdmUgcHJvYmFiaWxpdHkuCgogTm90ZTogVGhlIGRlZmF1bHQgdmFsdWUgdmFyaWVzIGJ5
IG1vZGVsLCBzZWUgdGhlIGBNb2RlbC50b3BfcGAKIGF0dHJpYnV0ZSBvZiB0aGUgYE1vZGVs
YCByZXR1cm5lZCB0aGUgYGdldE1vZGVsYCBmdW5jdGlvbi4KCg0KBQQAAgUEEgSCAQIKCg0K
BQQAAgUFEgSCAQsQCg0KBQQAAgUBEgSCAREWCg0KBQQAAgUDEgSCARkaCg0KBQQAAgUIEgSC
ARtDChAKCAQAAgUInAgAEgSCARxCCtoCCgQEAAIGEgSNAQJEGssCIE9wdGlvbmFsLiBUaGUg
bWF4aW11bSBudW1iZXIgb2YgdG9rZW5zIHRvIGNvbnNpZGVyIHdoZW4gc2FtcGxpbmcuCgog
VGhlIG1vZGVsIHVzZXMgY29tYmluZWQgVG9wLWsgYW5kIG51Y2xldXMgc2FtcGxpbmcuCgog
VG9wLWsgc2FtcGxpbmcgY29uc2lkZXJzIHRoZSBzZXQgb2YgYHRvcF9rYCBtb3N0IHByb2Jh
YmxlIHRva2Vucy4KIERlZmF1bHRzIHRvIDQwLgoKIE5vdGU6IFRoZSBkZWZhdWx0IHZhbHVl
IHZhcmllcyBieSBtb2RlbCwgc2VlIHRoZSBgTW9kZWwudG9wX2tgCiBhdHRyaWJ1dGUgb2Yg
dGhlIGBNb2RlbGAgcmV0dXJuZWQgdGhlIGBnZXRNb2RlbGAgZnVuY3Rpb24uCgoNCgUEAAIG
BBIEjQECCgoNCgUEAAIGBRIEjQELEAoNCgUEAAIGARIEjQERFgoNCgUEAAIGAxIEjQEZGgoN
CgUEAAIGCBIEjQEbQwoQCggEAAIGCJwIABIEjQEcQgq1BgoEBAACBxIGnQECngEvGqQGIE9w
dGlvbmFsLiBBIGxpc3Qgb2YgdW5pcXVlIGBTYWZldHlTZXR0aW5nYCBpbnN0YW5jZXMgZm9y
IGJsb2NraW5nIHVuc2FmZQogY29udGVudC4KCiB0aGF0IHdpbGwgYmUgZW5mb3JjZWQgb24g
dGhlIGBHZW5lcmF0ZVRleHRSZXF1ZXN0LnByb21wdGAgYW5kCiBgR2VuZXJhdGVUZXh0UmVz
cG9uc2UuY2FuZGlkYXRlc2AuIFRoZXJlIHNob3VsZCBub3QgYmUgbW9yZSB0aGFuIG9uZQog
c2V0dGluZyBmb3IgZWFjaCBgU2FmZXR5Q2F0ZWdvcnlgIHR5cGUuIFRoZSBBUEkgd2lsbCBi
bG9jayBhbnkgcHJvbXB0cyBhbmQKIHJlc3BvbnNlcyB0aGF0IGZhaWwgdG8gbWVldCB0aGUg
dGhyZXNob2xkcyBzZXQgYnkgdGhlc2Ugc2V0dGluZ3MuIFRoaXMgbGlzdAogb3ZlcnJpZGVz
IHRoZSBkZWZhdWx0IHNldHRpbmdzIGZvciBlYWNoIGBTYWZldHlDYXRlZ29yeWAgc3BlY2lm
aWVkIGluIHRoZQogc2FmZXR5X3NldHRpbmdzLiBJZiB0aGVyZSBpcyBubyBgU2FmZXR5U2V0
dGluZ2AgZm9yIGEgZ2l2ZW4KIGBTYWZldHlDYXRlZ29yeWAgcHJvdmlkZWQgaW4gdGhlIGxp
c3QsIHRoZSBBUEkgd2lsbCB1c2UgdGhlIGRlZmF1bHQgc2FmZXR5CiBzZXR0aW5nIGZvciB0
aGF0IGNhdGVnb3J5LiBIYXJtIGNhdGVnb3JpZXMgSEFSTV9DQVRFR09SWV9ERVJPR0FUT1JZ
LAogSEFSTV9DQVRFR09SWV9UT1hJQ0lUWSwgSEFSTV9DQVRFR09SWV9WSU9MRU5DRSwgSEFS
TV9DQVRFR09SWV9TRVhVQUwsCiBIQVJNX0NBVEVHT1JZX01FRElDQUwsIEhBUk1fQ0FURUdP
UllfREFOR0VST1VTIGFyZSBzdXBwb3J0ZWQgaW4gdGV4dAogc2VydmljZS4KCg0KBQQAAgcE
EgSdAQIKCg0KBQQAAgcGEgSdAQsYCg0KBQQAAgcBEgSdARkoCg0KBQQAAgcDEgSdASssCg0K
BQQAAgcIEgSeAQYuChAKCAQAAgcInAgAEgSeAQctCukBCgQEAAIIEgSjAQIlGtoBIFRoZSBz
ZXQgb2YgY2hhcmFjdGVyIHNlcXVlbmNlcyAodXAgdG8gNSkgdGhhdCB3aWxsIHN0b3Agb3V0
cHV0IGdlbmVyYXRpb24uCiBJZiBzcGVjaWZpZWQsIHRoZSBBUEkgd2lsbCBzdG9wIGF0IHRo
ZSBmaXJzdCBhcHBlYXJhbmNlIG9mIGEgc3RvcAogc2VxdWVuY2UuIFRoZSBzdG9wIHNlcXVl
bmNlIHdpbGwgbm90IGJlIGluY2x1ZGVkIGFzIHBhcnQgb2YgdGhlIHJlc3BvbnNlLgoKDQoF
BAACCAQSBKMBAgoKDQoFBAACCAUSBKMBCxEKDQoFBAACCAESBKMBEiAKDQoFBAACCAMSBKMB
IyQKTQoCBAESBqcBALoBARo/IFRoZSByZXNwb25zZSBmcm9tIHRoZSBtb2RlbCwgaW5jbHVk
aW5nIGNhbmRpZGF0ZSBjb21wbGV0aW9ucy4KCgsKAwQBARIEpwEIHAozCgQEAQIAEgSpAQIp
GiUgQ2FuZGlkYXRlIHJlc3BvbnNlcyBmcm9tIHRoZSBtb2RlbC4KCg0KBQQBAgAEEgSpAQIK
Cg0KBQQBAgAGEgSpAQsZCg0KBQQBAgABEgSpARokCg0KBQQBAgADEgSpAScoCvoDCgQEAQIB
EgS2AQIlGusDIEEgc2V0IG9mIGNvbnRlbnQgZmlsdGVyaW5nIG1ldGFkYXRhIGZvciB0aGUg
cHJvbXB0IGFuZCByZXNwb25zZQogdGV4dC4KCiBUaGlzIGluZGljYXRlcyB3aGljaCBgU2Fm
ZXR5Q2F0ZWdvcnlgKHMpIGJsb2NrZWQgYQogY2FuZGlkYXRlIGZyb20gdGhpcyByZXNwb25z
ZSwgdGhlIGxvd2VzdCBgSGFybVByb2JhYmlsaXR5YAogdGhhdCB0cmlnZ2VyZWQgYSBibG9j
aywgYW5kIHRoZSBIYXJtVGhyZXNob2xkIHNldHRpbmcgZm9yIHRoYXQgY2F0ZWdvcnkuCiBU
aGlzIGluZGljYXRlcyB0aGUgc21hbGxlc3QgY2hhbmdlIHRvIHRoZSBgU2FmZXR5U2V0dGlu
Z3NgIHRoYXQgd291bGQgYmUKIG5lY2Vzc2FyeSB0byB1bmJsb2NrIGF0IGxlYXN0IDEgcmVz
cG9uc2UuCgogVGhlIGJsb2NraW5nIGlzIGNvbmZpZ3VyZWQgYnkgdGhlIGBTYWZldHlTZXR0
aW5nc2AgaW4gdGhlIHJlcXVlc3QgKG9yIHRoZQogZGVmYXVsdCBgU2FmZXR5U2V0dGluZ3Ng
IG9mIHRoZSBBUEkpLgoKDQoFBAECAQQSBLYBAgoKDQoFBAECAQYSBLYBCxgKDQoFBAECAQES
BLYBGSAKDQoFBAECAQMSBLYBIyQKSQoEBAECAhIEuQECLho7IFJldHVybnMgYW55IHNhZmV0
eSBmZWVkYmFjayByZWxhdGVkIHRvIGNvbnRlbnQgZmlsdGVyaW5nLgoKDQoFBAECAgQSBLkB
AgoKDQoFBAECAgYSBLkBCxkKDQoFBAECAgESBLkBGikKDQoFBAECAgMSBLkBLC0KeAoCBAIS
Br8BAMIBARpqIFRleHQgZ2l2ZW4gdG8gdGhlIG1vZGVsIGFzIGEgcHJvbXB0LgoKIFRoZSBN
b2RlbCB3aWxsIHVzZSB0aGlzIFRleHRQcm9tcHQgdG8gR2VuZXJhdGUgYSB0ZXh0IGNvbXBs
ZXRpb24uCgoLCgMEAgESBL8BCBIKKgoEBAICABIEwQECOxocIFJlcXVpcmVkLiBUaGUgcHJv
bXB0IHRleHQuCgoNCgUEAgIABRIEwQECCAoNCgUEAgIAARIEwQEJDQoNCgUEAgIAAxIEwQEQ
EQoNCgUEAgIACBIEwQESOgoQCggEAgIACJwIABIEwQETOQoyCgIEAxIGxQEA1QEBGiQgT3V0
cHV0IHRleHQgcmV0dXJuZWQgZnJvbSBhIG1vZGVsLgoKCwoDBAMBEgTFAQgWCkgKBAQDAgAS
BMcBAkAaOiBPdXRwdXQgb25seS4gVGhlIGdlbmVyYXRlZCB0ZXh0IHJldHVybmVkIGZyb20g
dGhlIG1vZGVsLgoKDQoFBAMCAAUSBMcBAggKDQoFBAMCAAESBMcBCQ8KDQoFBAMCAAMSBMcB
EhMKDQoFBAMCAAgSBMcBFD8KEAoIBAMCAAicCAASBMcBFT4KYQoEBAMCARIEzAECKxpTIFJh
dGluZ3MgZm9yIHRoZSBzYWZldHkgb2YgYSByZXNwb25zZS4KCiBUaGVyZSBpcyBhdCBtb3N0
IG9uZSByYXRpbmcgcGVyIGNhdGVnb3J5LgoKDQoFBAMCAQQSBMwBAgoKDQoFBAMCAQYSBMwB
CxcKDQoFBAMCAQESBMwBGCYKDQoFBAMCAQMSBMwBKSoKzwEKBAQDAgISBtMBAtQBMhq+ASBP
dXRwdXQgb25seS4gQ2l0YXRpb24gaW5mb3JtYXRpb24gZm9yIG1vZGVsLWdlbmVyYXRlZCBg
b3V0cHV0YCBpbiB0aGlzCiBgVGV4dENvbXBsZXRpb25gLgoKIFRoaXMgZmllbGQgbWF5IGJl
IHBvcHVsYXRlZCB3aXRoIGF0dHJpYnV0aW9uIGluZm9ybWF0aW9uIGZvciBhbnkgdGV4dAog
aW5jbHVkZWQgaW4gdGhlIGBvdXRwdXRgLgoKDQoFBAMCAgQSBNMBAgoKDQoFBAMCAgYSBNMB
CxsKDQoFBAMCAgESBNMBHC0KDQoFBAMCAgMSBNMBMDEKDQoFBAMCAggSBNQBBjEKEAoIBAMC
AgicCAASBNQBBzAKPwoCBAQSBtgBAOQBARoxIFJlcXVlc3QgdG8gZ2V0IGEgdGV4dCBlbWJl
ZGRpbmcgZnJvbSB0aGUgbW9kZWwuCgoLCgMEBAESBNgBCBgKVwoEBAQCABIG2gEC3wEEGkcg
UmVxdWlyZWQuIFRoZSBtb2RlbCBuYW1lIHRvIHVzZSB3aXRoIHRoZSBmb3JtYXQgbW9kZWw9
bW9kZWxzL3ttb2RlbH0uCgoNCgUEBAIABRIE2gECCAoNCgUEBAIAARIE2gEJDgoNCgUEBAIA
AxIE2gEREgoPCgUEBAIACBIG2gET3wEDChAKCAQEAgAInAgAEgTbAQQqChEKBwQEAgAInwgS
BtwBBN4BBQpfCgQEBAIBEgTjAQI7GlEgT3B0aW9uYWwuIFRoZSBmcmVlLWZvcm0gaW5wdXQg
dGV4dCB0aGF0IHRoZSBtb2RlbCB3aWxsIHR1cm4gaW50byBhbgogZW1iZWRkaW5nLgoKDQoF
BAQCAQUSBOMBAggKDQoFBAQCAQESBOMBCQ0KDQoFBAQCAQMSBOMBEBEKDQoFBAQCAQgSBOMB
EjoKEAoIBAQCAQicCAASBOMBEzkKMwoCBAUSBucBAOoBARolIFRoZSByZXNwb25zZSB0byBh
IEVtYmVkVGV4dFJlcXVlc3QuCgoLCgMEBQESBOcBCBkKSQoEBAUCABIE6QECTxo7IE91dHB1
dCBvbmx5LiBUaGUgZW1iZWRkaW5nIGdlbmVyYXRlZCBmcm9tIHRoZSBpbnB1dCB0ZXh0LgoK
DQoFBAUCAAQSBOkBAgoKDQoFBAUCAAYSBOkBCxQKDQoFBAUCAAESBOkBFR4KDQoFBAUCAAMS
BOkBISIKDQoFBAUCAAgSBOkBI04KEAoIBAUCAAicCAASBOkBJE0KRQoCBAYSBu0BAIECARo3
IEJhdGNoIHJlcXVlc3QgdG8gZ2V0IGEgdGV4dCBlbWJlZGRpbmcgZnJvbSB0aGUgbW9kZWwu
CgoLCgMEBgESBO0BCB0KgAEKBAQGAgASBvEBAvYBBBpwIFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgYE1vZGVsYCB0byB1c2UgZm9yIGdlbmVyYXRpbmcgdGhlIGVtYmVkZGluZy4KIEV4
YW1wbGVzOgogIG1vZGVscy9lbWJlZGRpbmctZ2Vja28tMDAxCgoNCgUEBgIABRIE8QECCAoN
CgUEBgIAARIE8QEJDgoNCgUEBgIAAxIE8QEREgoPCgUEBgIACBIG8QET9gEDChAKCAQGAgAI
nAgAEgTyAQQqChEKBwQGAgAInwgSBvMBBPUBBQqmAQoEBAYCARIE+wECRRqXASBPcHRpb25h
bC4gVGhlIGZyZWUtZm9ybSBpbnB1dCB0ZXh0cyB0aGF0IHRoZSBtb2RlbCB3aWxsIHR1cm4g
aW50byBhbgogZW1iZWRkaW5nLiBUaGUgY3VycmVudCBsaW1pdCBpcyAxMDAgdGV4dHMsIG92
ZXIgd2hpY2ggYW4gZXJyb3Igd2lsbCBiZQogdGhyb3duLgoKDQoFBAYCAQQSBPsBAgoKDQoF
BAYCAQUSBPsBCxEKDQoFBAYCAQESBPsBEhcKDQoFBAYCAQMSBPsBGhsKDQoFBAYCAQgSBPsB
HEQKEAoIBAYCAQicCAASBPsBHUMKaAoEBAYCAhIG/wECgAIvGlggT3B0aW9uYWwuIEVtYmVk
IHJlcXVlc3RzIGZvciB0aGUgYmF0Y2guIE9ubHkgb25lIG9mIGB0ZXh0c2Agb3IgYHJlcXVl
c3RzYAogY2FuIGJlIHNldC4KCg0KBQQGAgIEEgT/AQIKCg0KBQQGAgIGEgT/AQsbCg0KBQQG
AgIBEgT/ARwkCg0KBQQGAgIDEgT/AScoCg0KBQQGAgIIEgSAAgYuChAKCAQGAgIInAgAEgSA
AgctCjMKAgQHEgaEAgCHAgEaJSBUaGUgcmVzcG9uc2UgdG8gYSBFbWJlZFRleHRSZXF1ZXN0
LgoKCwoDBAcBEgSEAggeCkoKBAQHAgASBIYCAlAaPCBPdXRwdXQgb25seS4gVGhlIGVtYmVk
ZGluZ3MgZ2VuZXJhdGVkIGZyb20gdGhlIGlucHV0IHRleHQuCgoNCgUEBwIABBIEhgICCgoN
CgUEBwIABhIEhgILFAoNCgUEBwIAARIEhgIVHwoNCgUEBwIAAxIEhgIiIwoNCgUEBwIACBIE
hgIkTwoQCggEBwIACJwIABIEhgIlTgo8CgIECBIGigIAjQIBGi4gQSBsaXN0IG9mIGZsb2F0
cyByZXByZXNlbnRpbmcgdGhlIGVtYmVkZGluZy4KCgsKAwQIARIEigIIEQolCgQECAIAEgSM
AgIbGhcgVGhlIGVtYmVkZGluZyB2YWx1ZXMuCgoNCgUECAIABBIEjAICCgoNCgUECAIABRIE
jAILEAoNCgUECAIAARIEjAIRFgoNCgUECAIAAxIEjAIZGgqqAQoCBAkSBpMCAKMCARqbASBD
b3VudHMgdGhlIG51bWJlciBvZiB0b2tlbnMgaW4gdGhlIGBwcm9tcHRgIHNlbnQgdG8gYSBt
b2RlbC4KCiBNb2RlbHMgbWF5IHRva2VuaXplIHRleHQgZGlmZmVyZW50bHksIHNvIGVhY2gg
bW9kZWwgbWF5IHJldHVybiBhIGRpZmZlcmVudAogYHRva2VuX2NvdW50YC4KCgsKAwQJARIE
kwIIHgrJAQoEBAkCABIGmgICnwIEGrgBIFJlcXVpcmVkLiBUaGUgbW9kZWwncyByZXNvdXJj
ZSBuYW1lLiBUaGlzIHNlcnZlcyBhcyBhbiBJRCBmb3IgdGhlIE1vZGVsIHRvCiB1c2UuCgog
VGhpcyBuYW1lIHNob3VsZCBtYXRjaCBhIG1vZGVsIG5hbWUgcmV0dXJuZWQgYnkgdGhlIGBM
aXN0TW9kZWxzYCBtZXRob2QuCgogRm9ybWF0OiBgbW9kZWxzL3ttb2RlbH1gCgoNCgUECQIA
BRIEmgICCAoNCgUECQIAARIEmgIJDgoNCgUECQIAAxIEmgIREgoPCgUECQIACBIGmgITnwID
ChAKCAQJAgAInAgAEgSbAgQqChEKBwQJAgAInwgSBpwCBJ4CBQpSCgQECQIBEgSiAgJBGkQg
UmVxdWlyZWQuIFRoZSBmcmVlLWZvcm0gaW5wdXQgdGV4dCBnaXZlbiB0byB0aGUgbW9kZWwg
YXMgYSBwcm9tcHQuCgoNCgUECQIBBhIEogICDAoNCgUECQIBARIEogINEwoNCgUECQIBAxIE
ogIWFwoNCgUECQIBCBIEogIYQAoQCggECQIBCJwIABIEogIZPwprCgIEChIGqAIArQIBGl0g
QSByZXNwb25zZSBmcm9tIGBDb3VudFRleHRUb2tlbnNgLgoKIEl0IHJldHVybnMgdGhlIG1v
ZGVsJ3MgYHRva2VuX2NvdW50YCBmb3IgdGhlIGBwcm9tcHRgLgoKCwoDBAoBEgSoAggfCmkK
BAQKAgASBKwCAhgaWyBUaGUgbnVtYmVyIG9mIHRva2VucyB0aGF0IHRoZSBgbW9kZWxgIHRv
a2VuaXplcyB0aGUgYHByb21wdGAgaW50by4KCiBBbHdheXMgbm9uLW5lZ2F0aXZlLgoKDQoF
BAoCAAUSBKwCAgcKDQoFBAoCAAESBKwCCBMKDQoFBAoCAAMSBKwCFhdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextRequest ===
    # Fields for GenerateTextRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1alpha.TextPrompt)
    # Field: temperature Type: 2 ()
    # Field: candidate_count Type: 5 ()
    # Field: max_output_tokens Type: 5 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()
    # Field: safety_settings Type: 11 (.google.ai.generativelanguage.v1alpha.SafetySetting)
    # Field: stop_sequences Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextResponse ===
    # Fields for GenerateTextResponse
    # Field: candidates Type: 11 (.google.ai.generativelanguage.v1alpha.TextCompletion)
    # Field: filters Type: 11 (.google.ai.generativelanguage.v1alpha.ContentFilter)
    # Field: safety_feedback Type: 11 (.google.ai.generativelanguage.v1alpha.SafetyFeedback)

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::TextPrompt ===
    # Fields for TextPrompt
    # Field: text Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::TextCompletion ===
    # Fields for TextCompletion
    # Field: output Type: 9 ()
    # Field: safety_ratings Type: 11 (.google.ai.generativelanguage.v1alpha.SafetyRating)
    # Field: citation_metadata Type: 11 (.google.ai.generativelanguage.v1alpha.CitationMetadata)

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextRequest ===
    # Fields for EmbedTextRequest
    # Field: model Type: 9 ()
    # Field: text Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextResponse ===
    # Fields for EmbedTextResponse
    # Field: embedding Type: 11 (.google.ai.generativelanguage.v1alpha.Embedding)

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextRequest ===
    # Fields for BatchEmbedTextRequest
    # Field: model Type: 9 ()
    # Field: texts Type: 9 ()
    # Field: requests Type: 11 (.google.ai.generativelanguage.v1alpha.EmbedTextRequest)

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextResponse ===
    # Fields for BatchEmbedTextResponse
    # Field: embeddings Type: 11 (.google.ai.generativelanguage.v1alpha.Embedding)

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::Embedding ===
    # Fields for Embedding
    # Field: value Type: 2 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensRequest ===
    # Fields for CountTextTokensRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1alpha.TextPrompt)

# === Message: Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensResponse ===
    # Fields for CountTextTokensResponse
    # Field: token_count Type: 5 ()

# === Service Client: Google::Ai::Generativelanguage::V1alpha::TextService::TextServiceClient ===
package Google::Ai::Generativelanguage::V1alpha::TextService::TextServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1alpha::TextService::TextServiceClient

Client stub representing the remote C<TextService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub generate_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.TextService',
        method         => 'GenerateText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextResponse',
    });
}

sub embed_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.TextService',
        method         => 'EmbedText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextResponse',
    });
}

sub batch_embed_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.TextService',
        method         => 'BatchEmbedText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextResponse',
    });
}

sub count_text_tokens {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.TextService',
        method         => 'CountTextTokens',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::TextService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/text_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::TextService;

    my $msg = Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextRequest->new({
        model => $model,
        prompt => $prompt,
        temperature => $temperature,
        candidate_count => $candidate_count,
    });

    # Read or update a field
    my $val = $msg->model();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/text_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextRequest

Request to generate a text completion response from the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The name of the `Model` or `TunedModel` to use for generating the
completion.
Examples:
 models/text-bison-001
 tunedModels/sentence-translator-u3b7m

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TextService::TextPrompt>)

Required. The free-form input text given to the model as a prompt.

Given a prompt, the model will generate a TextCompletion response it
predicts as the completion of the input text.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Optional. Controls the randomness of the output.
Note: The default value varies by model, see the `Model.temperature`
attribute of the `Model` returned the `getModel` function.

Values can range from [0.0,1.0],
inclusive. A value closer to 1.0 will produce responses that are more
varied and creative, while a value closer to 0.0 will typically result in
more straightforward responses from the model.

=item * C<< $msg->candidate_count() >> / C<< $msg->candidate_count($value) >>

Type: C<Int32>

Optional. Number of generated responses to return.

This value must be between [1, 8], inclusive. If unset, this will default
to 1.

=item * C<< $msg->max_output_tokens() >> / C<< $msg->max_output_tokens($value) >>

Type: C<Int32>

Optional. The maximum number of tokens to include in a candidate.

If unset, this will default to output_token_limit specified in the `Model`
specification.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

Optional. The maximum cumulative probability of tokens to consider when
sampling.

The model uses combined Top-k and nucleus sampling.

Tokens are sorted based on their assigned probabilities so that only the
most likely tokens are considered. Top-k sampling directly limits the
maximum number of tokens to consider, while Nucleus sampling limits number
of tokens based on the cumulative probability.

Note: The default value varies by model, see the `Model.top_p`
attribute of the `Model` returned the `getModel` function.

=item * C<< $msg->top_k() >> / C<< $msg->top_k($value) >>

Type: C<Int32>

Optional. The maximum number of tokens to consider when sampling.

The model uses combined Top-k and nucleus sampling.

Top-k sampling considers the set of `top_k` most probable tokens.
Defaults to 40.

Note: The default value varies by model, see the `Model.top_k`
attribute of the `Model` returned the `getModel` function.

=item * C<< $msg->safety_settings() >> / C<< $msg->safety_settings($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>)

Optional. A list of unique `SafetySetting` instances for blocking unsafe
content.

that will be enforced on the `GenerateTextRequest.prompt` and
`GenerateTextResponse.candidates`. There should not be more than one
setting for each `SafetyCategory` type. The API will block any prompts and
responses that fail to meet the thresholds set by these settings. This list
overrides the default settings for each `SafetyCategory` specified in the
safety_settings. If there is no `SafetySetting` for a given
`SafetyCategory` provided in the list, the API will use the default safety
setting for that category. Harm categories HARM_CATEGORY_DEROGATORY,
HARM_CATEGORY_TOXICITY, HARM_CATEGORY_VIOLENCE, HARM_CATEGORY_SEXUAL,
HARM_CATEGORY_MEDICAL, HARM_CATEGORY_DANGEROUS are supported in text
service.

=item * C<< $msg->stop_sequences() >> / C<< $msg->stop_sequences($value) >>

Type: C<String>

The set of character sequences (up to 5) that will stop output generation.
If specified, the API will stop at the first appearance of a stop
sequence. The stop sequence will not be included as part of the response.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextResponse

The response from the model, including candidate completions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->candidates() >> / C<< $msg->candidates($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TextService::TextCompletion>)

Candidate responses from the model.

=item * C<< $msg->filters() >> / C<< $msg->filters($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Safety::ContentFilter>)

A set of content filtering metadata for the prompt and response
text.

This indicates which `SafetyCategory`(s) blocked a
candidate from this response, the lowest `HarmProbability`
that triggered a block, and the HarmThreshold setting for that category.
This indicates the smallest change to the `SafetySettings` that would be
necessary to unblock at least 1 response.

The blocking is configured by the `SafetySettings` in the request (or the
default `SafetySettings` of the API).

=item * C<< $msg->safety_feedback() >> / C<< $msg->safety_feedback($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetyFeedback>)

Returns any safety feedback related to content filtering.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::TextPrompt

Text given to the model as a prompt.

The Model will use this TextPrompt to Generate a text completion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. The prompt text.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::TextCompletion

Output text returned from a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output() >> / C<< $msg->output($value) >>

Type: C<String>

Output only. The generated text returned from the model.

=item * C<< $msg->safety_ratings() >> / C<< $msg->safety_ratings($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetyRating>)

Ratings for the safety of a response.

There is at most one rating per category.

=item * C<< $msg->citation_metadata() >> / C<< $msg->citation_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Citation::CitationMetadata>)

Output only. Citation information for model-generated `output` in this
`TextCompletion`.

This field may be populated with attribution information for any text
included in the `output`.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextRequest

Request to get a text embedding from the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The model name to use with the format model=models/{model}.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Optional. The free-form input text that the model will turn into an
embedding.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextResponse

The response to a EmbedTextRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->embedding() >> / C<< $msg->embedding($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TextService::Embedding>)

Output only. The embedding generated from the input text.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextRequest

Batch request to get a text embedding from the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The name of the `Model` to use for generating the embedding.
Examples:
 models/embedding-gecko-001

=item * C<< $msg->texts() >> / C<< $msg->texts($value) >>

Type: C<String>

Optional. The free-form input texts that the model will turn into an
embedding. The current limit is 100 texts, over which an error will be
thrown.

=item * C<< $msg->requests() >> / C<< $msg->requests($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextRequest>)

Optional. Embed requests for the batch. Only one of `texts` or `requests`
can be set.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextResponse

The response to a EmbedTextRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->embeddings() >> / C<< $msg->embeddings($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TextService::Embedding>)

Output only. The embeddings generated from the input text.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::Embedding

A list of floats representing the embedding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Float>

The embedding values.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensRequest

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

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TextService::TextPrompt>)

Required. The free-form input text given to the model as a prompt.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensResponse

A response from `CountTextTokens`.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::TextService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
