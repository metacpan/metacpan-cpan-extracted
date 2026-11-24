package Google::Ai::Generativelanguage::V1alpha::CacheService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1alpha::CachedContent };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvY2FjaGVfc2VydmljZS5w
cm90bxIkZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhGjlnb29nbGUvYWkv
Z2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvY2FjaGVkX2NvbnRlbnQucHJvdG8aHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
Ghtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9t
YXNrLnByb3RvImEKGUxpc3RDYWNoZWRDb250ZW50c1JlcXVlc3QSIAoJcGFnZV9zaXplGAEg
ASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAiABKAlCA+BBAVIJcGFnZVRva2Vu
IqIBChpMaXN0Q2FjaGVkQ29udGVudHNSZXNwb25zZRJcCg9jYWNoZWRfY29udGVudHMYASAD
KAsyMy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuQ2FjaGVkQ29udGVu
dFIOY2FjaGVkQ29udGVudHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuIn0KGkNyZWF0ZUNhY2hlZENvbnRlbnRSZXF1ZXN0El8KDmNhY2hlZF9jb250ZW50GAEg
ASgLMjMuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkNhY2hlZENvbnRl
bnRCA+BBAlINY2FjaGVkQ29udGVudCJmChdHZXRDYWNoZWRDb250ZW50UmVxdWVzdBJLCgRu
YW1lGAEgASgJQjfgQQL6QTEKL2dlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9D
YWNoZWRDb250ZW50UgRuYW1lIroBChpVcGRhdGVDYWNoZWRDb250ZW50UmVxdWVzdBJfCg5j
YWNoZWRfY29udGVudBgBIAEoCzIzLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFh
bHBoYS5DYWNoZWRDb250ZW50QgPgQQJSDWNhY2hlZENvbnRlbnQSOwoLdXBkYXRlX21hc2sY
AiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVNYXNrImkKGkRlbGV0
ZUNhY2hlZENvbnRlbnRSZXF1ZXN0EksKBG5hbWUYASABKAlCN+BBAvpBMQovZ2VuZXJhdGl2
ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL0NhY2hlZENvbnRlbnRSBG5hbWUylQgKDENhY2hl
U2VydmljZRK7AQoSTGlzdENhY2hlZENvbnRlbnRzEj8uZ29vZ2xlLmFpLmdlbmVyYXRpdmVs
YW5ndWFnZS52MWFscGhhLkxpc3RDYWNoZWRDb250ZW50c1JlcXVlc3QaQC5nb29nbGUuYWku
Z2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuTGlzdENhY2hlZENvbnRlbnRzUmVzcG9uc2Ui
IoLT5JMCGRIXL3YxYWxwaGEvY2FjaGVkQ29udGVudHPaQQASzgEKE0NyZWF0ZUNhY2hlZENv
bnRlbnQSQC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuQ3JlYXRlQ2Fj
aGVkQ29udGVudFJlcXVlc3QaMy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxw
aGEuQ2FjaGVkQ29udGVudCJAgtPkkwIpIhcvdjFhbHBoYS9jYWNoZWRDb250ZW50czoOY2Fj
aGVkX2NvbnRlbnTaQQ5jYWNoZWRfY29udGVudBK3AQoQR2V0Q2FjaGVkQ29udGVudBI9Lmdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5HZXRDYWNoZWRDb250ZW50UmVx
dWVzdBozLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5DYWNoZWRDb250
ZW50Ii+C0+STAiISIC92MWFscGhhL3tuYW1lPWNhY2hlZENvbnRlbnRzLyp92kEEbmFtZRLy
AQoTVXBkYXRlQ2FjaGVkQ29udGVudBJALmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2Uu
djFhbHBoYS5VcGRhdGVDYWNoZWRDb250ZW50UmVxdWVzdBozLmdvb2dsZS5haS5nZW5lcmF0
aXZlbGFuZ3VhZ2UudjFhbHBoYS5DYWNoZWRDb250ZW50ImSC0+STAkEyLy92MWFscGhhL3tj
YWNoZWRfY29udGVudC5uYW1lPWNhY2hlZENvbnRlbnRzLyp9Og5jYWNoZWRfY29udGVudNpB
GmNhY2hlZF9jb250ZW50LHVwZGF0ZV9tYXNrEqABChNEZWxldGVDYWNoZWRDb250ZW50EkAu
Z29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkRlbGV0ZUNhY2hlZENvbnRl
bnRSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5Ii+C0+STAiIqIC92MWFscGhhL3tu
YW1lPWNhY2hlZENvbnRlbnRzLyp92kEEbmFtZRokykEhZ2VuZXJhdGl2ZWxhbmd1YWdlLmdv
b2dsZWFwaXMuY29tQp8BCihjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFs
cGhhQhFDYWNoZVNlcnZpY2VQcm90b1ABWl5jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVy
YXRpdmVsYW5ndWFnZS9hcGl2MWFscGhhL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRp
dmVsYW5ndWFnZXBiSrEfCgcSBQ4AkgEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
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
bnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSAEMKCQoCAwESAxMAJgoJCgIDAhIDFAAhCgkKAgMD
EgMVACkKCQoCAwQSAxYAIwoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgB1CgkKAggL
EgMaAHUKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAAyCgkKAggIEgMcADIKCAoBCBID
HQBBCgkKAggBEgMdAEEKswIKAgYAEgQjAFEBGqYCIEFQSSBmb3IgbWFuYWdpbmcgY2FjaGUg
b2YgY29udGVudCAoQ2FjaGVkQ29udGVudCByZXNvdXJjZXMpIHRoYXQgY2FuIGJlIHVzZWQK
IGluIEdlbmVyYXRpdmVTZXJ2aWNlIHJlcXVlc3RzLiBUaGlzIHdheSBnZW5lcmF0ZSBjb250
ZW50IHJlcXVlc3RzIGNhbiBiZW5lZml0CiBmcm9tIHByZXByb2Nlc3Npbmcgd29yayBiZWlu
ZyBkb25lIGVhcmxpZXIsIHBvc3NpYmx5IGxvd2VyaW5nIHRoZWlyCiBjb21wdXRhdGlvbmFs
IGNvc3QuIEl0IGlzIGludGVuZGVkIHRvIGJlIHVzZWQgd2l0aCBsYXJnZSBjb250ZXh0cy4K
CgoKAwYAARIDIwgUCgoKAwYAAxIDJAJJCgwKBQYAA5kIEgMkAkkKJQoEBgACABIEJwItAxoX
IExpc3RzIENhY2hlZENvbnRlbnRzLgoKDAoFBgACAAESAycGGAoMCgUGAAIAAhIDJxkyCgwK
BQYAAgADEgMoDykKDQoFBgACAAQSBCkEKwYKEQoJBgACAASwyrwiEgQpBCsGCgwKBQYAAgAE
EgMsBC4KDwoIBgACAASbCAASAywELgovCgQGAAIBEgQwAjYDGiEgQ3JlYXRlcyBDYWNoZWRD
b250ZW50IHJlc291cmNlLgoKDAoFBgACAQESAzAGGQoMCgUGAAIBAhIDMBo0CgwKBQYAAgED
EgMwP0wKDQoFBgACAQQSBDEENAYKEQoJBgACAQSwyrwiEgQxBDQGCgwKBQYAAgEEEgM1BDwK
DwoIBgACAQSbCAASAzUEPAotCgQGAAICEgQ5Aj4DGh8gUmVhZHMgQ2FjaGVkQ29udGVudCBy
ZXNvdXJjZS4KCgwKBQYAAgIBEgM5BhYKDAoFBgACAgISAzkXLgoMCgUGAAICAxIDOTlGCg0K
BQYAAgIEEgQ6BDwGChEKCQYAAgIEsMq8IhIEOgQ8BgoMCgUGAAICBBIDPQQyCg8KCAYAAgIE
mwgAEgM9BDIKTgoEBgACAxIEQQJHAxpAIFVwZGF0ZXMgQ2FjaGVkQ29udGVudCByZXNvdXJj
ZSAob25seSBleHBpcmF0aW9uIGlzIHVwZGF0YWJsZSkuCgoMCgUGAAIDARIDQQYZCgwKBQYA
AgMCEgNBGjQKDAoFBgACAwMSA0E/TAoNCgUGAAIDBBIEQgRFBgoRCgkGAAIDBLDKvCISBEIE
RQYKDAoFBgACAwQSA0YESAoPCggGAAIDBJsIABIDRgRICi8KBAYAAgQSBEoCUAMaISBEZWxl
dGVzIENhY2hlZENvbnRlbnQgcmVzb3VyY2UuCgoMCgUGAAIEARIDSgYZCgwKBQYAAgQCEgNK
GjQKDAoFBgACBAMSA0sPJAoNCgUGAAIEBBIETAROBgoRCgkGAAIEBLDKvCISBEwETgYKDAoF
BgACBAQSA08EMgoPCggGAAIEBJsIABIDTwQyCi0KAgQAEgRUAGEBGiEgUmVxdWVzdCB0byBs
aXN0IENhY2hlZENvbnRlbnRzLgoKCgoDBAABEgNUCCEKkAIKBAQAAgASA1kCPxqCAiBPcHRp
b25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGNhY2hlZCBjb250ZW50cyB0byByZXR1cm4u
IFRoZSBzZXJ2aWNlIG1heQogcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5z
cGVjaWZpZWQsIHNvbWUgZGVmYXVsdCAodW5kZXIgbWF4aW11bSkKIG51bWJlciBvZiBpdGVt
cyB3aWxsIGJlIHJldHVybmVkLiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMg
YWJvdmUKIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCgoMCgUEAAIABRIDWQIHCgwK
BQQAAgABEgNZCBEKDAoFBAACAAMSA1kUFQoMCgUEAAIACBIDWRY+Cg8KCAQAAgAInAgAEgNZ
Fz0KhgIKBAQAAgESA2ACQRr4ASBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBm
cm9tIGEgcHJldmlvdXMgYExpc3RDYWNoZWRDb250ZW50c2AgY2FsbC4KIFByb3ZpZGUgdGhp
cyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywg
YWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RDYWNoZWRDb250ZW50c2Ag
bXVzdAogbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCgwK
BQQAAgEFEgNgAggKDAoFBAACAQESA2AJEwoMCgUEAAIBAxIDYBYXCgwKBQQAAgEIEgNgGEAK
DwoIBAACAQicCAASA2AZPwowCgIEARIEZABrARokIFJlc3BvbnNlIHdpdGggQ2FjaGVkQ29u
dGVudHMgbGlzdC4KCgoKAwQBARIDZAgiCicKBAQBAgASA2YCLRoaIExpc3Qgb2YgY2FjaGVk
IGNvbnRlbnRzLgoKDAoFBAECAAQSA2YCCgoMCgUEAQIABhIDZgsYCgwKBQQBAgABEgNmGSgK
DAoFBAECAAMSA2YrLAqPAQoEBAECARIDagIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBz
ZW50IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhp
cyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCgwK
BQQBAgEFEgNqAggKDAoFBAECAQESA2oJGAoMCgUEAQIBAxIDahscCi4KAgQCEgRuAHEBGiIg
UmVxdWVzdCB0byBjcmVhdGUgQ2FjaGVkQ29udGVudC4KCgoKAwQCARIDbggiCjYKBAQCAgAS
A3ACTBopIFJlcXVpcmVkLiBUaGUgY2FjaGVkIGNvbnRlbnQgdG8gY3JlYXRlLgoKDAoFBAIC
AAYSA3ACDwoMCgUEAgIAARIDcBAeCgwKBQQCAgADEgNwISIKDAoFBAICAAgSA3AjSwoPCggE
AgIACJwIABIDcCRKCiwKAgQDEgR0AH0BGiAgUmVxdWVzdCB0byByZWFkIENhY2hlZENvbnRl
bnQuCgoKCgMEAwESA3QIHwpwCgQEAwIAEgR3AnwEGmIgUmVxdWlyZWQuIFRoZSByZXNvdXJj
ZSBuYW1lIHJlZmVycmluZyB0byB0aGUgY29udGVudCBjYWNoZSBlbnRyeS4KIEZvcm1hdDog
YGNhY2hlZENvbnRlbnRzL3tpZH1gCgoMCgUEAwIABRIDdwIICgwKBQQDAgABEgN3CQ0KDAoF
BAMCAAMSA3cQEQoNCgUEAwIACBIEdxJ8AwoPCggEAwIACJwIABIDeAQqCg8KBwQDAgAInwgS
BHkEewUKMAoCBAQSBoABAIYBARoiIFJlcXVlc3QgdG8gdXBkYXRlIENhY2hlZENvbnRlbnQu
CgoLCgMEBAESBIABCCIKOwoEBAQCABIEggECTBotIFJlcXVpcmVkLiBUaGUgY29udGVudCBj
YWNoZSBlbnRyeSB0byB1cGRhdGUKCg0KBQQEAgAGEgSCAQIPCg0KBQQEAgABEgSCARAeCg0K
BQQEAgADEgSCASEiCg0KBQQEAgAIEgSCASNLChAKCAQEAgAInAgAEgSCASRKCi0KBAQEAgES
BIUBAiwaHyBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gdXBkYXRlLgoKDQoFBAQCAQYSBIUBAhsK
DQoFBAQCAQESBIUBHCcKDQoFBAQCAQMSBIUBKisKMAoCBAUSBokBAJIBARoiIFJlcXVlc3Qg
dG8gZGVsZXRlIENhY2hlZENvbnRlbnQuCgoLCgMEBQESBIkBCCIKcQoEBAUCABIGjAECkQEE
GmEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIHJlZmVycmluZyB0byB0aGUgY29udGVu
dCBjYWNoZSBlbnRyeQogRm9ybWF0OiBgY2FjaGVkQ29udGVudHMve2lkfWAKCg0KBQQFAgAF
EgSMAQIICg0KBQQFAgABEgSMAQkNCg0KBQQFAgADEgSMARARCg8KBQQFAgAIEgaMARKRAQMK
EAoIBAUCAAicCAASBI0BBCoKEQoHBAUCAAifCBIGjgEEkAEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsRequest ===
    # Fields for ListCachedContentsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsResponse ===
    # Fields for ListCachedContentsResponse
    # Field: cached_contents Type: 11 (.google.ai.generativelanguage.v1alpha.CachedContent)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::CacheService::CreateCachedContentRequest ===
    # Fields for CreateCachedContentRequest
    # Field: cached_content Type: 11 (.google.ai.generativelanguage.v1alpha.CachedContent)

# === Message: Google::Ai::Generativelanguage::V1alpha::CacheService::GetCachedContentRequest ===
    # Fields for GetCachedContentRequest
    # Field: name Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::CacheService::UpdateCachedContentRequest ===
    # Fields for UpdateCachedContentRequest
    # Field: cached_content Type: 11 (.google.ai.generativelanguage.v1alpha.CachedContent)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Ai::Generativelanguage::V1alpha::CacheService::DeleteCachedContentRequest ===
    # Fields for DeleteCachedContentRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Ai::Generativelanguage::V1alpha::CacheService::CacheServiceClient ===
package Google::Ai::Generativelanguage::V1alpha::CacheService::CacheServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1alpha::CacheService::CacheServiceClient

Client stub representing the remote C<CacheService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_cached_contents {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'ListCachedContents',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsResponse',
    });
}

sub create_cached_content {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::CacheService::CreateCachedContentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'CreateCachedContent',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent',
    });
}

sub get_cached_content {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::CacheService::GetCachedContentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'GetCachedContent',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent',
    });
}

sub update_cached_content {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::CacheService::UpdateCachedContentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'UpdateCachedContent',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent',
    });
}

sub delete_cached_content {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::CacheService::DeleteCachedContentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'DeleteCachedContent',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::CacheService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/cache_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::CacheService;

    my $msg = Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsRequest->new({
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->page_size();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/cache_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsRequest

Request to list CachedContents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of cached contents to return. The service may
return fewer than this value. If unspecified, some default (under maximum)
number of items will be returned. The maximum value is 1000; values above
1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListCachedContents` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListCachedContents` must
match the call that provided the page token.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsResponse

Response with CachedContents list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cached_contents() >> / C<< $msg->cached_contents($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent>)

List of cached contents.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::CacheService::CreateCachedContentRequest

Request to create CachedContent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cached_content() >> / C<< $msg->cached_content($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent>)

Required. The cached content to create.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::CacheService::GetCachedContentRequest

Request to read CachedContent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name referring to the content cache entry.
Format: `cachedContents/{id}`

=back

=head2 Google::Ai::Generativelanguage::V1alpha::CacheService::UpdateCachedContentRequest

Request to update CachedContent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cached_content() >> / C<< $msg->cached_content($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent>)

Required. The content cache entry to update

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to update.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::CacheService::DeleteCachedContentRequest

Request to delete CachedContent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name referring to the content cache entry
Format: `cachedContents/{id}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::CacheService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
