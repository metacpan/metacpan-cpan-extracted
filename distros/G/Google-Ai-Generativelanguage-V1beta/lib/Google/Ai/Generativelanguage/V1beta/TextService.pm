package Google::Ai::Generativelanguage::V1beta::TextService;

use strict;
use warnings;

our $VERSION = '0.12';

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
CjZnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS90ZXh0X3NlcnZpY2UucHJv
dG8SI2dvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhGjJnb29nbGUvYWkvZ2Vu
ZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9jaXRhdGlvbi5wcm90bxowZ29vZ2xlL2FpL2dlbmVy
YXRpdmVsYW5ndWFnZS92MWJldGEvc2FmZXR5LnByb3RvGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKoBAoTR2VuZXJhdGVU
ZXh0UmVxdWVzdBIZCgVtb2RlbBgBIAEoCUID4EECUgVtb2RlbBJMCgZwcm9tcHQYAiABKAsy
Ly5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5UZXh0UHJvbXB0QgPgQQJS
BnByb21wdBIqCgt0ZW1wZXJhdHVyZRgDIAEoAkID4EEBSABSC3RlbXBlcmF0dXJliAEBEjEK
D2NhbmRpZGF0ZV9jb3VudBgEIAEoBUID4EEBSAFSDmNhbmRpZGF0ZUNvdW50iAEBEjQKEW1h
eF9vdXRwdXRfdG9rZW5zGAUgASgFQgPgQQFIAlIPbWF4T3V0cHV0VG9rZW5ziAEBEh0KBXRv
cF9wGAYgASgCQgPgQQFIA1IEdG9wUIgBARIdCgV0b3BfaxgHIAEoBUID4EEBSARSBHRvcEuI
AQESYAoPc2FmZXR5X3NldHRpbmdzGAggAygLMjIuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWJldGEuU2FmZXR5U2V0dGluZ0ID4EEBUg5zYWZldHlTZXR0aW5ncxIlCg5zdG9w
X3NlcXVlbmNlcxgJIAMoCVINc3RvcFNlcXVlbmNlc0IOCgxfdGVtcGVyYXR1cmVCEgoQX2Nh
bmRpZGF0ZV9jb3VudEIUChJfbWF4X291dHB1dF90b2tlbnNCCAoGX3RvcF9wQggKBl90b3Bf
ayKXAgoUR2VuZXJhdGVUZXh0UmVzcG9uc2USUwoKY2FuZGlkYXRlcxgBIAMoCzIzLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlRleHRDb21wbGV0aW9uUgpjYW5kaWRh
dGVzEkwKB2ZpbHRlcnMYAyADKAsyMi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYx
YmV0YS5Db250ZW50RmlsdGVyUgdmaWx0ZXJzElwKD3NhZmV0eV9mZWVkYmFjaxgEIAMoCzIz
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlNhZmV0eUZlZWRiYWNrUg5z
YWZldHlGZWVkYmFjayIlCgpUZXh0UHJvbXB0EhcKBHRleHQYASABKAlCA+BBAlIEdGV4dCKL
AgoOVGV4dENvbXBsZXRpb24SGwoGb3V0cHV0GAEgASgJQgPgQQNSBm91dHB1dBJYCg5zYWZl
dHlfcmF0aW5ncxgCIAMoCzIxLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRh
LlNhZmV0eVJhdGluZ1INc2FmZXR5UmF0aW5ncxJsChFjaXRhdGlvbl9tZXRhZGF0YRgDIAEo
CzI1Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkNpdGF0aW9uTWV0YWRh
dGFCA+BBA0gAUhBjaXRhdGlvbk1ldGFkYXRhiAEBQhQKEl9jaXRhdGlvbl9tZXRhZGF0YSJy
ChBFbWJlZFRleHRSZXF1ZXN0EkUKBW1vZGVsGAEgASgJQi/gQQL6QSkKJ2dlbmVyYXRpdmVs
YW5ndWFnZS5nb29nbGVhcGlzLmNvbS9Nb2RlbFIFbW9kZWwSFwoEdGV4dBgCIAEoCUID4EEB
UgR0ZXh0InkKEUVtYmVkVGV4dFJlc3BvbnNlElYKCWVtYmVkZGluZxgBIAEoCzIuLmdvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkVtYmVkZGluZ0ID4EEDSABSCWVtYmVk
ZGluZ4gBAUIMCgpfZW1iZWRkaW5nItEBChVCYXRjaEVtYmVkVGV4dFJlcXVlc3QSRQoFbW9k
ZWwYASABKAlCL+BBAvpBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL01v
ZGVsUgVtb2RlbBIZCgV0ZXh0cxgCIAMoCUID4EEBUgV0ZXh0cxJWCghyZXF1ZXN0cxgDIAMo
CzI1Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkVtYmVkVGV4dFJlcXVl
c3RCA+BBAVIIcmVxdWVzdHMibQoWQmF0Y2hFbWJlZFRleHRSZXNwb25zZRJTCgplbWJlZGRp
bmdzGAEgAygLMi4uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuRW1iZWRk
aW5nQgPgQQNSCmVtYmVkZGluZ3MiIQoJRW1iZWRkaW5nEhQKBXZhbHVlGAEgAygCUgV2YWx1
ZSKtAQoWQ291bnRUZXh0VG9rZW5zUmVxdWVzdBJFCgVtb2RlbBgBIAEoCUIv4EEC+kEpCidn
ZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vTW9kZWxSBW1vZGVsEkwKBnByb21w
dBgCIAEoCzIvLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlRleHRQcm9t
cHRCA+BBAlIGcHJvbXB0IjoKF0NvdW50VGV4dFRva2Vuc1Jlc3BvbnNlEh8KC3Rva2VuX2Nv
dW50GAEgASgFUgp0b2tlbkNvdW50MsAHCgtUZXh0U2VydmljZRKwAgoMR2VuZXJhdGVUZXh0
EjguZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuR2VuZXJhdGVUZXh0UmVx
dWVzdBo5Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLkdlbmVyYXRlVGV4
dFJlc3BvbnNlIqoBgtPkkwJbIiUvdjFiZXRhL3ttb2RlbD1tb2RlbHMvKn06Z2VuZXJhdGVU
ZXh0OgEqWi8iKi92MWJldGEve21vZGVsPXR1bmVkTW9kZWxzLyp9OmdlbmVyYXRlVGV4dDoB
KtpBRm1vZGVsLHByb21wdCx0ZW1wZXJhdHVyZSxjYW5kaWRhdGVfY291bnQsbWF4X291dHB1
dF90b2tlbnMsdG9wX3AsdG9wX2sStgEKCUVtYmVkVGV4dBI1Lmdvb2dsZS5haS5nZW5lcmF0
aXZlbGFuZ3VhZ2UudjFiZXRhLkVtYmVkVGV4dFJlcXVlc3QaNi5nb29nbGUuYWkuZ2VuZXJh
dGl2ZWxhbmd1YWdlLnYxYmV0YS5FbWJlZFRleHRSZXNwb25zZSI6gtPkkwInIiIvdjFiZXRh
L3ttb2RlbD1tb2RlbHMvKn06ZW1iZWRUZXh0OgEq2kEKbW9kZWwsdGV4dBLLAQoOQmF0Y2hF
bWJlZFRleHQSOi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5CYXRjaEVt
YmVkVGV4dFJlcXVlc3QaOy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5C
YXRjaEVtYmVkVGV4dFJlc3BvbnNlIkCC0+STAiwiJy92MWJldGEve21vZGVsPW1vZGVscy8q
fTpiYXRjaEVtYmVkVGV4dDoBKtpBC21vZGVsLHRleHRzEtABCg9Db3VudFRleHRUb2tlbnMS
Oy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5Db3VudFRleHRUb2tlbnNS
ZXF1ZXN0GjwuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEuQ291bnRUZXh0
VG9rZW5zUmVzcG9uc2UiQoLT5JMCLSIoL3YxYmV0YS97bW9kZWw9bW9kZWxzLyp9OmNvdW50
VGV4dFRva2VuczoBKtpBDG1vZGVsLHByb21wdBokykEhZ2VuZXJhdGl2ZWxhbmd1YWdlLmdv
b2dsZWFwaXMuY29tQpwBCidjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJl
dGFCEFRleHRTZXJ2aWNlUHJvdG9QAVpdY2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0
aXZlbGFuZ3VhZ2UvYXBpdjFiZXRhL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVs
YW5ndWFnZXBiSslQCgcSBQ4ArQIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAsCgkKAgMAEgMSADwKCQoCAwESAxMAOgoJCgIDAhIDFAAmCgkKAgMDEgMV
ACEKCQoCAwQSAxYAKQoJCgIDBRIDFwAjCggKAQgSAxkAdAoJCgIICxIDGQB0CggKAQgSAxoA
IgoJCgIIChIDGgAiCggKAQgSAxsAMQoJCgIICBIDGwAxCggKAQgSAxwAQAoJCgIIARIDHABA
CsABCgIGABIEIgBPARqzASBBUEkgZm9yIHVzaW5nIEdlbmVyYXRpdmUgTGFuZ3VhZ2UgTW9k
ZWxzIChHTE1zKSB0cmFpbmVkIHRvIGdlbmVyYXRlIHRleHQuCgogQWxzbyBrbm93biBhcyBM
YXJnZSBMYW5ndWFnZSBNb2RlbHMgKExMTSlzLCB0aGVzZSBnZW5lcmF0ZSB0ZXh0IGdpdmVu
IGFuCiBpbnB1dCBwcm9tcHQgZnJvbSB0aGUgdXNlci4KCgoKAwYAARIDIggTCgoKAwYAAxID
IwJJCgwKBQYAA5kIEgMjAkkKSwoEBgACABIEJgIxAxo9IEdlbmVyYXRlcyBhIHJlc3BvbnNl
IGZyb20gdGhlIG1vZGVsIGdpdmVuIGFuIGlucHV0IG1lc3NhZ2UuCgoMCgUGAAIAARIDJgYS
CgwKBQYAAgACEgMmEyYKDAoFBgACAAMSAyYxRQoNCgUGAAIABBIEJwQuBgoRCgkGAAIABLDK
vCISBCcELgYKDQoFBgACAAQSBC8EMFEKEAoIBgACAASbCAASBC8EMFEKTQoEBgACARIENAI6
Axo/IEdlbmVyYXRlcyBhbiBlbWJlZGRpbmcgZnJvbSB0aGUgbW9kZWwgZ2l2ZW4gYW4gaW5w
dXQgbWVzc2FnZS4KCgwKBQYAAgEBEgM0Bg8KDAoFBgACAQISAzQQIAoMCgUGAAIBAxIDNCs8
Cg0KBQYAAgEEEgQ1BDgGChEKCQYAAgEEsMq8IhIENQQ4BgoMCgUGAAIBBBIDOQQ4Cg8KCAYA
AgEEmwgAEgM5BDgKZQoEBgACAhIEPgJEAxpXIEdlbmVyYXRlcyBtdWx0aXBsZSBlbWJlZGRp
bmdzIGZyb20gdGhlIG1vZGVsIGdpdmVuIGlucHV0IHRleHQgaW4gYQogc3luY2hyb25vdXMg
Y2FsbC4KCgwKBQYAAgIBEgM+BhQKDAoFBgACAgISAz4VKgoMCgUGAAICAxIDPjVLCg0KBQYA
AgIEEgQ/BEIGChEKCQYAAgIEsMq8IhIEPwRCBgoMCgUGAAICBBIDQwQ5Cg8KCAYAAgIEmwgA
EgNDBDkKTwoEBgACAxIERwJOAxpBIFJ1bnMgYSBtb2RlbCdzIHRva2VuaXplciBvbiBhIHRl
eHQgYW5kIHJldHVybnMgdGhlIHRva2VuIGNvdW50LgoKDAoFBgACAwESA0cGFQoMCgUGAAID
AhIDRxYsCgwKBQYAAgMDEgNIDyYKDQoFBgACAwQSBEkETAYKEQoJBgACAwSwyrwiEgRJBEwG
CgwKBQYAAgMEEgNNBDoKDwoIBgACAwSbCAASA00EOgpNCgIEABIFUgCkAQEaQCBSZXF1ZXN0
IHRvIGdlbmVyYXRlIGEgdGV4dCBjb21wbGV0aW9uIHJlc3BvbnNlIGZyb20gdGhlIG1vZGVs
LgoKCgoDBAABEgNSCBsKswEKBAQAAgASA1gCPBqlASBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIGBNb2RlbGAgb3IgYFR1bmVkTW9kZWxgIHRvIHVzZSBmb3IgZ2VuZXJhdGluZyB0aGUK
IGNvbXBsZXRpb24uCiBFeGFtcGxlczoKICBtb2RlbHMvdGV4dC1iaXNvbi0wMDEKICB0dW5l
ZE1vZGVscy9zZW50ZW5jZS10cmFuc2xhdG9yLXUzYjdtCgoMCgUEAAIABRIDWAIICgwKBQQA
AgABEgNYCQ4KDAoFBAACAAMSA1gREgoMCgUEAAIACBIDWBM7Cg8KCAQAAgAInAgAEgNYFDoK
yAEKBAQAAgESA14CQRq6ASBSZXF1aXJlZC4gVGhlIGZyZWUtZm9ybSBpbnB1dCB0ZXh0IGdp
dmVuIHRvIHRoZSBtb2RlbCBhcyBhIHByb21wdC4KCiBHaXZlbiBhIHByb21wdCwgdGhlIG1v
ZGVsIHdpbGwgZ2VuZXJhdGUgYSBUZXh0Q29tcGxldGlvbiByZXNwb25zZSBpdAogcHJlZGlj
dHMgYXMgdGhlIGNvbXBsZXRpb24gb2YgdGhlIGlucHV0IHRleHQuCgoMCgUEAAIBBhIDXgIM
CgwKBQQAAgEBEgNeDRMKDAoFBAACAQMSA14WFwoMCgUEAAIBCBIDXhhACg8KCAQAAgEInAgA
EgNeGT8KpwMKBAQAAgISA2gCShqZAyBPcHRpb25hbC4gQ29udHJvbHMgdGhlIHJhbmRvbW5l
c3Mgb2YgdGhlIG91dHB1dC4KIE5vdGU6IFRoZSBkZWZhdWx0IHZhbHVlIHZhcmllcyBieSBt
b2RlbCwgc2VlIHRoZSBgTW9kZWwudGVtcGVyYXR1cmVgCiBhdHRyaWJ1dGUgb2YgdGhlIGBN
b2RlbGAgcmV0dXJuZWQgdGhlIGBnZXRNb2RlbGAgZnVuY3Rpb24uCgogVmFsdWVzIGNhbiBy
YW5nZSBmcm9tIFswLjAsMS4wXSwKIGluY2x1c2l2ZS4gQSB2YWx1ZSBjbG9zZXIgdG8gMS4w
IHdpbGwgcHJvZHVjZSByZXNwb25zZXMgdGhhdCBhcmUgbW9yZQogdmFyaWVkIGFuZCBjcmVh
dGl2ZSwgd2hpbGUgYSB2YWx1ZSBjbG9zZXIgdG8gMC4wIHdpbGwgdHlwaWNhbGx5IHJlc3Vs
dCBpbgogbW9yZSBzdHJhaWdodGZvcndhcmQgcmVzcG9uc2VzIGZyb20gdGhlIG1vZGVsLgoK
DAoFBAACAgQSA2gCCgoMCgUEAAICBRIDaAsQCgwKBQQAAgIBEgNoERwKDAoFBAACAgMSA2gf
IAoMCgUEAAICCBIDaCFJCg8KCAQAAgIInAgAEgNoIkgKlQEKBAQAAgMSA24CThqHASBPcHRp
b25hbC4gTnVtYmVyIG9mIGdlbmVyYXRlZCByZXNwb25zZXMgdG8gcmV0dXJuLgoKIFRoaXMg
dmFsdWUgbXVzdCBiZSBiZXR3ZWVuIFsxLCA4XSwgaW5jbHVzaXZlLiBJZiB1bnNldCwgdGhp
cyB3aWxsIGRlZmF1bHQKIHRvIDEuCgoMCgUEAAIDBBIDbgIKCgwKBQQAAgMFEgNuCxAKDAoF
BAACAwESA24RIAoMCgUEAAIDAxIDbiMkCgwKBQQAAgMIEgNuJU0KDwoIBAACAwicCAASA24m
TAquAQoEBAACBBIDdAJQGqABIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgdG9r
ZW5zIHRvIGluY2x1ZGUgaW4gYSBjYW5kaWRhdGUuCgogSWYgdW5zZXQsIHRoaXMgd2lsbCBk
ZWZhdWx0IHRvIG91dHB1dF90b2tlbl9saW1pdCBzcGVjaWZpZWQgaW4gdGhlIGBNb2RlbGAK
IHNwZWNpZmljYXRpb24uCgoMCgUEAAIEBBIDdAIKCgwKBQQAAgQFEgN0CxAKDAoFBAACBAES
A3QRIgoMCgUEAAIEAxIDdCUmCgwKBQQAAgQIEgN0J08KDwoIBAACBAicCAASA3QoTgqkBAoE
BAACBRIEggECRBqVBCBPcHRpb25hbC4gVGhlIG1heGltdW0gY3VtdWxhdGl2ZSBwcm9iYWJp
bGl0eSBvZiB0b2tlbnMgdG8gY29uc2lkZXIgd2hlbgogc2FtcGxpbmcuCgogVGhlIG1vZGVs
IHVzZXMgY29tYmluZWQgVG9wLWsgYW5kIG51Y2xldXMgc2FtcGxpbmcuCgogVG9rZW5zIGFy
ZSBzb3J0ZWQgYmFzZWQgb24gdGhlaXIgYXNzaWduZWQgcHJvYmFiaWxpdGllcyBzbyB0aGF0
IG9ubHkgdGhlCiBtb3N0IGxpa2VseSB0b2tlbnMgYXJlIGNvbnNpZGVyZWQuIFRvcC1rIHNh
bXBsaW5nIGRpcmVjdGx5IGxpbWl0cyB0aGUKIG1heGltdW0gbnVtYmVyIG9mIHRva2VucyB0
byBjb25zaWRlciwgd2hpbGUgTnVjbGV1cyBzYW1wbGluZyBsaW1pdHMgbnVtYmVyCiBvZiB0
b2tlbnMgYmFzZWQgb24gdGhlIGN1bXVsYXRpdmUgcHJvYmFiaWxpdHkuCgogTm90ZTogVGhl
IGRlZmF1bHQgdmFsdWUgdmFyaWVzIGJ5IG1vZGVsLCBzZWUgdGhlIGBNb2RlbC50b3BfcGAK
IGF0dHJpYnV0ZSBvZiB0aGUgYE1vZGVsYCByZXR1cm5lZCB0aGUgYGdldE1vZGVsYCBmdW5j
dGlvbi4KCg0KBQQAAgUEEgSCAQIKCg0KBQQAAgUFEgSCAQsQCg0KBQQAAgUBEgSCAREWCg0K
BQQAAgUDEgSCARkaCg0KBQQAAgUIEgSCARtDChAKCAQAAgUInAgAEgSCARxCCtoCCgQEAAIG
EgSNAQJEGssCIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgdG9rZW5zIHRvIGNv
bnNpZGVyIHdoZW4gc2FtcGxpbmcuCgogVGhlIG1vZGVsIHVzZXMgY29tYmluZWQgVG9wLWsg
YW5kIG51Y2xldXMgc2FtcGxpbmcuCgogVG9wLWsgc2FtcGxpbmcgY29uc2lkZXJzIHRoZSBz
ZXQgb2YgYHRvcF9rYCBtb3N0IHByb2JhYmxlIHRva2Vucy4KIERlZmF1bHRzIHRvIDQwLgoK
IE5vdGU6IFRoZSBkZWZhdWx0IHZhbHVlIHZhcmllcyBieSBtb2RlbCwgc2VlIHRoZSBgTW9k
ZWwudG9wX2tgCiBhdHRyaWJ1dGUgb2YgdGhlIGBNb2RlbGAgcmV0dXJuZWQgdGhlIGBnZXRN
b2RlbGAgZnVuY3Rpb24uCgoNCgUEAAIGBBIEjQECCgoNCgUEAAIGBRIEjQELEAoNCgUEAAIG
ARIEjQERFgoNCgUEAAIGAxIEjQEZGgoNCgUEAAIGCBIEjQEbQwoQCggEAAIGCJwIABIEjQEc
Qgq1BgoEBAACBxIGnQECngEvGqQGIE9wdGlvbmFsLiBBIGxpc3Qgb2YgdW5pcXVlIGBTYWZl
dHlTZXR0aW5nYCBpbnN0YW5jZXMgZm9yIGJsb2NraW5nIHVuc2FmZQogY29udGVudC4KCiB0
aGF0IHdpbGwgYmUgZW5mb3JjZWQgb24gdGhlIGBHZW5lcmF0ZVRleHRSZXF1ZXN0LnByb21w
dGAgYW5kCiBgR2VuZXJhdGVUZXh0UmVzcG9uc2UuY2FuZGlkYXRlc2AuIFRoZXJlIHNob3Vs
ZCBub3QgYmUgbW9yZSB0aGFuIG9uZQogc2V0dGluZyBmb3IgZWFjaCBgU2FmZXR5Q2F0ZWdv
cnlgIHR5cGUuIFRoZSBBUEkgd2lsbCBibG9jayBhbnkgcHJvbXB0cyBhbmQKIHJlc3BvbnNl
cyB0aGF0IGZhaWwgdG8gbWVldCB0aGUgdGhyZXNob2xkcyBzZXQgYnkgdGhlc2Ugc2V0dGlu
Z3MuIFRoaXMgbGlzdAogb3ZlcnJpZGVzIHRoZSBkZWZhdWx0IHNldHRpbmdzIGZvciBlYWNo
IGBTYWZldHlDYXRlZ29yeWAgc3BlY2lmaWVkIGluIHRoZQogc2FmZXR5X3NldHRpbmdzLiBJ
ZiB0aGVyZSBpcyBubyBgU2FmZXR5U2V0dGluZ2AgZm9yIGEgZ2l2ZW4KIGBTYWZldHlDYXRl
Z29yeWAgcHJvdmlkZWQgaW4gdGhlIGxpc3QsIHRoZSBBUEkgd2lsbCB1c2UgdGhlIGRlZmF1
bHQgc2FmZXR5CiBzZXR0aW5nIGZvciB0aGF0IGNhdGVnb3J5LiBIYXJtIGNhdGVnb3JpZXMg
SEFSTV9DQVRFR09SWV9ERVJPR0FUT1JZLAogSEFSTV9DQVRFR09SWV9UT1hJQ0lUWSwgSEFS
TV9DQVRFR09SWV9WSU9MRU5DRSwgSEFSTV9DQVRFR09SWV9TRVhVQUwsCiBIQVJNX0NBVEVH
T1JZX01FRElDQUwsIEhBUk1fQ0FURUdPUllfREFOR0VST1VTIGFyZSBzdXBwb3J0ZWQgaW4g
dGV4dAogc2VydmljZS4KCg0KBQQAAgcEEgSdAQIKCg0KBQQAAgcGEgSdAQsYCg0KBQQAAgcB
EgSdARkoCg0KBQQAAgcDEgSdASssCg0KBQQAAgcIEgSeAQYuChAKCAQAAgcInAgAEgSeAQct
CukBCgQEAAIIEgSjAQIlGtoBIFRoZSBzZXQgb2YgY2hhcmFjdGVyIHNlcXVlbmNlcyAodXAg
dG8gNSkgdGhhdCB3aWxsIHN0b3Agb3V0cHV0IGdlbmVyYXRpb24uCiBJZiBzcGVjaWZpZWQs
IHRoZSBBUEkgd2lsbCBzdG9wIGF0IHRoZSBmaXJzdCBhcHBlYXJhbmNlIG9mIGEgc3RvcAog
c2VxdWVuY2UuIFRoZSBzdG9wIHNlcXVlbmNlIHdpbGwgbm90IGJlIGluY2x1ZGVkIGFzIHBh
cnQgb2YgdGhlIHJlc3BvbnNlLgoKDQoFBAACCAQSBKMBAgoKDQoFBAACCAUSBKMBCxEKDQoF
BAACCAESBKMBEiAKDQoFBAACCAMSBKMBIyQKTQoCBAESBqcBALoBARo/IFRoZSByZXNwb25z
ZSBmcm9tIHRoZSBtb2RlbCwgaW5jbHVkaW5nIGNhbmRpZGF0ZSBjb21wbGV0aW9ucy4KCgsK
AwQBARIEpwEIHAozCgQEAQIAEgSpAQIpGiUgQ2FuZGlkYXRlIHJlc3BvbnNlcyBmcm9tIHRo
ZSBtb2RlbC4KCg0KBQQBAgAEEgSpAQIKCg0KBQQBAgAGEgSpAQsZCg0KBQQBAgABEgSpARok
Cg0KBQQBAgADEgSpAScoCvoDCgQEAQIBEgS2AQIlGusDIEEgc2V0IG9mIGNvbnRlbnQgZmls
dGVyaW5nIG1ldGFkYXRhIGZvciB0aGUgcHJvbXB0IGFuZCByZXNwb25zZQogdGV4dC4KCiBU
aGlzIGluZGljYXRlcyB3aGljaCBgU2FmZXR5Q2F0ZWdvcnlgKHMpIGJsb2NrZWQgYQogY2Fu
ZGlkYXRlIGZyb20gdGhpcyByZXNwb25zZSwgdGhlIGxvd2VzdCBgSGFybVByb2JhYmlsaXR5
YAogdGhhdCB0cmlnZ2VyZWQgYSBibG9jaywgYW5kIHRoZSBIYXJtVGhyZXNob2xkIHNldHRp
bmcgZm9yIHRoYXQgY2F0ZWdvcnkuCiBUaGlzIGluZGljYXRlcyB0aGUgc21hbGxlc3QgY2hh
bmdlIHRvIHRoZSBgU2FmZXR5U2V0dGluZ3NgIHRoYXQgd291bGQgYmUKIG5lY2Vzc2FyeSB0
byB1bmJsb2NrIGF0IGxlYXN0IDEgcmVzcG9uc2UuCgogVGhlIGJsb2NraW5nIGlzIGNvbmZp
Z3VyZWQgYnkgdGhlIGBTYWZldHlTZXR0aW5nc2AgaW4gdGhlIHJlcXVlc3QgKG9yIHRoZQog
ZGVmYXVsdCBgU2FmZXR5U2V0dGluZ3NgIG9mIHRoZSBBUEkpLgoKDQoFBAECAQQSBLYBAgoK
DQoFBAECAQYSBLYBCxgKDQoFBAECAQESBLYBGSAKDQoFBAECAQMSBLYBIyQKSQoEBAECAhIE
uQECLho7IFJldHVybnMgYW55IHNhZmV0eSBmZWVkYmFjayByZWxhdGVkIHRvIGNvbnRlbnQg
ZmlsdGVyaW5nLgoKDQoFBAECAgQSBLkBAgoKDQoFBAECAgYSBLkBCxkKDQoFBAECAgESBLkB
GikKDQoFBAECAgMSBLkBLC0KeAoCBAISBr8BAMIBARpqIFRleHQgZ2l2ZW4gdG8gdGhlIG1v
ZGVsIGFzIGEgcHJvbXB0LgoKIFRoZSBNb2RlbCB3aWxsIHVzZSB0aGlzIFRleHRQcm9tcHQg
dG8gR2VuZXJhdGUgYSB0ZXh0IGNvbXBsZXRpb24uCgoLCgMEAgESBL8BCBIKKgoEBAICABIE
wQECOxocIFJlcXVpcmVkLiBUaGUgcHJvbXB0IHRleHQuCgoNCgUEAgIABRIEwQECCAoNCgUE
AgIAARIEwQEJDQoNCgUEAgIAAxIEwQEQEQoNCgUEAgIACBIEwQESOgoQCggEAgIACJwIABIE
wQETOQoyCgIEAxIGxQEA1QEBGiQgT3V0cHV0IHRleHQgcmV0dXJuZWQgZnJvbSBhIG1vZGVs
LgoKCwoDBAMBEgTFAQgWCkgKBAQDAgASBMcBAkAaOiBPdXRwdXQgb25seS4gVGhlIGdlbmVy
YXRlZCB0ZXh0IHJldHVybmVkIGZyb20gdGhlIG1vZGVsLgoKDQoFBAMCAAUSBMcBAggKDQoF
BAMCAAESBMcBCQ8KDQoFBAMCAAMSBMcBEhMKDQoFBAMCAAgSBMcBFD8KEAoIBAMCAAicCAAS
BMcBFT4KYQoEBAMCARIEzAECKxpTIFJhdGluZ3MgZm9yIHRoZSBzYWZldHkgb2YgYSByZXNw
b25zZS4KCiBUaGVyZSBpcyBhdCBtb3N0IG9uZSByYXRpbmcgcGVyIGNhdGVnb3J5LgoKDQoF
BAMCAQQSBMwBAgoKDQoFBAMCAQYSBMwBCxcKDQoFBAMCAQESBMwBGCYKDQoFBAMCAQMSBMwB
KSoKzwEKBAQDAgISBtMBAtQBMhq+ASBPdXRwdXQgb25seS4gQ2l0YXRpb24gaW5mb3JtYXRp
b24gZm9yIG1vZGVsLWdlbmVyYXRlZCBgb3V0cHV0YCBpbiB0aGlzCiBgVGV4dENvbXBsZXRp
b25gLgoKIFRoaXMgZmllbGQgbWF5IGJlIHBvcHVsYXRlZCB3aXRoIGF0dHJpYnV0aW9uIGlu
Zm9ybWF0aW9uIGZvciBhbnkgdGV4dAogaW5jbHVkZWQgaW4gdGhlIGBvdXRwdXRgLgoKDQoF
BAMCAgQSBNMBAgoKDQoFBAMCAgYSBNMBCxsKDQoFBAMCAgESBNMBHC0KDQoFBAMCAgMSBNMB
MDEKDQoFBAMCAggSBNQBBjEKEAoIBAMCAgicCAASBNQBBzAKPwoCBAQSBtgBAOQBARoxIFJl
cXVlc3QgdG8gZ2V0IGEgdGV4dCBlbWJlZGRpbmcgZnJvbSB0aGUgbW9kZWwuCgoLCgMEBAES
BNgBCBgKVwoEBAQCABIG2gEC3wEEGkcgUmVxdWlyZWQuIFRoZSBtb2RlbCBuYW1lIHRvIHVz
ZSB3aXRoIHRoZSBmb3JtYXQgbW9kZWw9bW9kZWxzL3ttb2RlbH0uCgoNCgUEBAIABRIE2gEC
CAoNCgUEBAIAARIE2gEJDgoNCgUEBAIAAxIE2gEREgoPCgUEBAIACBIG2gET3wEDChAKCAQE
AgAInAgAEgTbAQQqChEKBwQEAgAInwgSBtwBBN4BBQpfCgQEBAIBEgTjAQI7GlEgT3B0aW9u
YWwuIFRoZSBmcmVlLWZvcm0gaW5wdXQgdGV4dCB0aGF0IHRoZSBtb2RlbCB3aWxsIHR1cm4g
aW50byBhbgogZW1iZWRkaW5nLgoKDQoFBAQCAQUSBOMBAggKDQoFBAQCAQESBOMBCQ0KDQoF
BAQCAQMSBOMBEBEKDQoFBAQCAQgSBOMBEjoKEAoIBAQCAQicCAASBOMBEzkKMwoCBAUSBucB
AOoBARolIFRoZSByZXNwb25zZSB0byBhIEVtYmVkVGV4dFJlcXVlc3QuCgoLCgMEBQESBOcB
CBkKSQoEBAUCABIE6QECTxo7IE91dHB1dCBvbmx5LiBUaGUgZW1iZWRkaW5nIGdlbmVyYXRl
ZCBmcm9tIHRoZSBpbnB1dCB0ZXh0LgoKDQoFBAUCAAQSBOkBAgoKDQoFBAUCAAYSBOkBCxQK
DQoFBAUCAAESBOkBFR4KDQoFBAUCAAMSBOkBISIKDQoFBAUCAAgSBOkBI04KEAoIBAUCAAic
CAASBOkBJE0KRQoCBAYSBu0BAIECARo3IEJhdGNoIHJlcXVlc3QgdG8gZ2V0IGEgdGV4dCBl
bWJlZGRpbmcgZnJvbSB0aGUgbW9kZWwuCgoLCgMEBgESBO0BCB0KgAEKBAQGAgASBvEBAvYB
BBpwIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgYE1vZGVsYCB0byB1c2UgZm9yIGdlbmVy
YXRpbmcgdGhlIGVtYmVkZGluZy4KIEV4YW1wbGVzOgogIG1vZGVscy9lbWJlZGRpbmctZ2Vj
a28tMDAxCgoNCgUEBgIABRIE8QECCAoNCgUEBgIAARIE8QEJDgoNCgUEBgIAAxIE8QEREgoP
CgUEBgIACBIG8QET9gEDChAKCAQGAgAInAgAEgTyAQQqChEKBwQGAgAInwgSBvMBBPUBBQqm
AQoEBAYCARIE+wECRRqXASBPcHRpb25hbC4gVGhlIGZyZWUtZm9ybSBpbnB1dCB0ZXh0cyB0
aGF0IHRoZSBtb2RlbCB3aWxsIHR1cm4gaW50byBhbgogZW1iZWRkaW5nLiBUaGUgY3VycmVu
dCBsaW1pdCBpcyAxMDAgdGV4dHMsIG92ZXIgd2hpY2ggYW4gZXJyb3Igd2lsbCBiZQogdGhy
b3duLgoKDQoFBAYCAQQSBPsBAgoKDQoFBAYCAQUSBPsBCxEKDQoFBAYCAQESBPsBEhcKDQoF
BAYCAQMSBPsBGhsKDQoFBAYCAQgSBPsBHEQKEAoIBAYCAQicCAASBPsBHUMKaAoEBAYCAhIG
/wECgAIvGlggT3B0aW9uYWwuIEVtYmVkIHJlcXVlc3RzIGZvciB0aGUgYmF0Y2guIE9ubHkg
b25lIG9mIGB0ZXh0c2Agb3IgYHJlcXVlc3RzYAogY2FuIGJlIHNldC4KCg0KBQQGAgIEEgT/
AQIKCg0KBQQGAgIGEgT/AQsbCg0KBQQGAgIBEgT/ARwkCg0KBQQGAgIDEgT/AScoCg0KBQQG
AgIIEgSAAgYuChAKCAQGAgIInAgAEgSAAgctCjMKAgQHEgaEAgCHAgEaJSBUaGUgcmVzcG9u
c2UgdG8gYSBFbWJlZFRleHRSZXF1ZXN0LgoKCwoDBAcBEgSEAggeCkoKBAQHAgASBIYCAlAa
PCBPdXRwdXQgb25seS4gVGhlIGVtYmVkZGluZ3MgZ2VuZXJhdGVkIGZyb20gdGhlIGlucHV0
IHRleHQuCgoNCgUEBwIABBIEhgICCgoNCgUEBwIABhIEhgILFAoNCgUEBwIAARIEhgIVHwoN
CgUEBwIAAxIEhgIiIwoNCgUEBwIACBIEhgIkTwoQCggEBwIACJwIABIEhgIlTgo8CgIECBIG
igIAjQIBGi4gQSBsaXN0IG9mIGZsb2F0cyByZXByZXNlbnRpbmcgdGhlIGVtYmVkZGluZy4K
CgsKAwQIARIEigIIEQolCgQECAIAEgSMAgIbGhcgVGhlIGVtYmVkZGluZyB2YWx1ZXMuCgoN
CgUECAIABBIEjAICCgoNCgUECAIABRIEjAILEAoNCgUECAIAARIEjAIRFgoNCgUECAIAAxIE
jAIZGgqqAQoCBAkSBpMCAKMCARqbASBDb3VudHMgdGhlIG51bWJlciBvZiB0b2tlbnMgaW4g
dGhlIGBwcm9tcHRgIHNlbnQgdG8gYSBtb2RlbC4KCiBNb2RlbHMgbWF5IHRva2VuaXplIHRl
eHQgZGlmZmVyZW50bHksIHNvIGVhY2ggbW9kZWwgbWF5IHJldHVybiBhIGRpZmZlcmVudAog
YHRva2VuX2NvdW50YC4KCgsKAwQJARIEkwIIHgrJAQoEBAkCABIGmgICnwIEGrgBIFJlcXVp
cmVkLiBUaGUgbW9kZWwncyByZXNvdXJjZSBuYW1lLiBUaGlzIHNlcnZlcyBhcyBhbiBJRCBm
b3IgdGhlIE1vZGVsIHRvCiB1c2UuCgogVGhpcyBuYW1lIHNob3VsZCBtYXRjaCBhIG1vZGVs
IG5hbWUgcmV0dXJuZWQgYnkgdGhlIGBMaXN0TW9kZWxzYCBtZXRob2QuCgogRm9ybWF0OiBg
bW9kZWxzL3ttb2RlbH1gCgoNCgUECQIABRIEmgICCAoNCgUECQIAARIEmgIJDgoNCgUECQIA
AxIEmgIREgoPCgUECQIACBIGmgITnwIDChAKCAQJAgAInAgAEgSbAgQqChEKBwQJAgAInwgS
BpwCBJ4CBQpSCgQECQIBEgSiAgJBGkQgUmVxdWlyZWQuIFRoZSBmcmVlLWZvcm0gaW5wdXQg
dGV4dCBnaXZlbiB0byB0aGUgbW9kZWwgYXMgYSBwcm9tcHQuCgoNCgUECQIBBhIEogICDAoN
CgUECQIBARIEogINEwoNCgUECQIBAxIEogIWFwoNCgUECQIBCBIEogIYQAoQCggECQIBCJwI
ABIEogIZPwprCgIEChIGqAIArQIBGl0gQSByZXNwb25zZSBmcm9tIGBDb3VudFRleHRUb2tl
bnNgLgoKIEl0IHJldHVybnMgdGhlIG1vZGVsJ3MgYHRva2VuX2NvdW50YCBmb3IgdGhlIGBw
cm9tcHRgLgoKCwoDBAoBEgSoAggfCmkKBAQKAgASBKwCAhgaWyBUaGUgbnVtYmVyIG9mIHRv
a2VucyB0aGF0IHRoZSBgbW9kZWxgIHRva2VuaXplcyB0aGUgYHByb21wdGAgaW50by4KCiBB
bHdheXMgbm9uLW5lZ2F0aXZlLgoKDQoFBAoCAAUSBKwCAgcKDQoFBAoCAAESBKwCCBMKDQoF
BAoCAAMSBKwCFhdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest ===
    # Fields for GenerateTextRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1beta.TextPrompt)
    # Field: temperature Type: 2 ()
    # Field: candidate_count Type: 5 ()
    # Field: max_output_tokens Type: 5 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()
    # Field: safety_settings Type: 11 (.google.ai.generativelanguage.v1beta.SafetySetting)
    # Field: stop_sequences Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest->new(
        model => $value,
    );

=head1 FIELDS

=over 4

=item * B<model>

Type: String

=item * B<prompt>

Type: Message (.google.ai.generativelanguage.v1beta.TextPrompt)

=item * B<temperature>

Type: Float

=item * B<candidate_count>

Type: Int32

=item * B<max_output_tokens>

Type: Int32

=item * B<top_p>

Type: Float

=item * B<top_k>

Type: Int32

=item * B<safety_settings>

Type: Message (.google.ai.generativelanguage.v1beta.SafetySetting)

=item * B<stop_sequences>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse ===
    # Fields for GenerateTextResponse
    # Field: candidates Type: 11 (.google.ai.generativelanguage.v1beta.TextCompletion)
    # Field: filters Type: 11 (.google.ai.generativelanguage.v1beta.ContentFilter)
    # Field: safety_feedback Type: 11 (.google.ai.generativelanguage.v1beta.SafetyFeedback)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse->new(
        candidates => $value,
    );

=head1 FIELDS

=over 4

=item * B<candidates>

Type: Message (.google.ai.generativelanguage.v1beta.TextCompletion)

=item * B<filters>

Type: Message (.google.ai.generativelanguage.v1beta.ContentFilter)

=item * B<safety_feedback>

Type: Message (.google.ai.generativelanguage.v1beta.SafetyFeedback)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::TextPrompt ===
    # Fields for TextPrompt
    # Field: text Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::TextPrompt - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::TextPrompt->new(
        text => $value,
    );

=head1 FIELDS

=over 4

=item * B<text>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::TextCompletion ===
    # Fields for TextCompletion
    # Field: output Type: 9 ()
    # Field: safety_ratings Type: 11 (.google.ai.generativelanguage.v1beta.SafetyRating)
    # Field: citation_metadata Type: 11 (.google.ai.generativelanguage.v1beta.CitationMetadata)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::TextCompletion - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::TextCompletion->new(
        output => $value,
    );

=head1 FIELDS

=over 4

=item * B<output>

Type: String

=item * B<safety_ratings>

Type: Message (.google.ai.generativelanguage.v1beta.SafetyRating)

=item * B<citation_metadata>

Type: Message (.google.ai.generativelanguage.v1beta.CitationMetadata)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest ===
    # Fields for EmbedTextRequest
    # Field: model Type: 9 ()
    # Field: text Type: 9 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest->new(
        model => $value,
    );

=head1 FIELDS

=over 4

=item * B<model>

Type: String

=item * B<text>

Type: String

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse ===
    # Fields for EmbedTextResponse
    # Field: embedding Type: 11 (.google.ai.generativelanguage.v1beta.Embedding)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse->new(
        embedding => $value,
    );

=head1 FIELDS

=over 4

=item * B<embedding>

Type: Message (.google.ai.generativelanguage.v1beta.Embedding)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest ===
    # Fields for BatchEmbedTextRequest
    # Field: model Type: 9 ()
    # Field: texts Type: 9 ()
    # Field: requests Type: 11 (.google.ai.generativelanguage.v1beta.EmbedTextRequest)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest->new(
        model => $value,
    );

=head1 FIELDS

=over 4

=item * B<model>

Type: String

=item * B<texts>

Type: String

=item * B<requests>

Type: Message (.google.ai.generativelanguage.v1beta.EmbedTextRequest)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse ===
    # Fields for BatchEmbedTextResponse
    # Field: embeddings Type: 11 (.google.ai.generativelanguage.v1beta.Embedding)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse->new(
        embeddings => $value,
    );

=head1 FIELDS

=over 4

=item * B<embeddings>

Type: Message (.google.ai.generativelanguage.v1beta.Embedding)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::Embedding ===
    # Fields for Embedding
    # Field: value Type: 2 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::Embedding - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::Embedding->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: Float

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest ===
    # Fields for CountTextTokensRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1beta.TextPrompt)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest->new(
        model => $value,
    );

=head1 FIELDS

=over 4

=item * B<model>

Type: String

=item * B<prompt>

Type: Message (.google.ai.generativelanguage.v1beta.TextPrompt)

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse ===
    # Fields for CountTextTokensResponse
    # Field: token_count Type: 5 ()

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse->new(
        token_count => $value,
    );

=head1 FIELDS

=over 4

=item * B<token_count>

Type: Int32

=back

=cut

# === Service Client: Google::Ai::Generativelanguage::V1beta::TextService::TextServiceClient ===
package Google::Ai::Generativelanguage::V1beta::TextService::TextServiceClient;

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::TextServiceClient - Client stub representing the remote TextService service

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

sub generate_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.TextService',
        method         => 'GenerateText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse',
    });
}

sub embed_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.TextService',
        method         => 'EmbedText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse',
    });
}

sub batch_embed_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.TextService',
        method         => 'BatchEmbedText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse',
    });
}

sub count_text_tokens {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta.TextService',
        method         => 'CountTextTokens',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse',
    });
}

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
