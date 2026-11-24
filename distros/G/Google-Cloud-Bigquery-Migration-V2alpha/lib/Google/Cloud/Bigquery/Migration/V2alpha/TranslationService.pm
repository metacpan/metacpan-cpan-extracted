package Google::Cloud::Bigquery::Migration::V2alpha::TranslationService;

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
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyYWxwaGEvdHJhbnNsYXRpb25f
c2VydmljZS5wcm90bxInZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhh
Ghxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90
bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJj
ZS5wcm90byLbAgoVVHJhbnNsYXRlUXVlcnlSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC
+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBKGAQoOc291
cmNlX2RpYWxlY3QYAiABKA4yWi5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYy
YWxwaGEuVHJhbnNsYXRlUXVlcnlSZXF1ZXN0LlNxbFRyYW5zbGF0aW9uU291cmNlRGlhbGVj
dEID4EECUg1zb3VyY2VEaWFsZWN0EhkKBXF1ZXJ5GAMgASgJQgPgQQJSBXF1ZXJ5IlsKG1Nx
bFRyYW5zbGF0aW9uU291cmNlRGlhbGVjdBIuCipTUUxfVFJBTlNMQVRJT05fU09VUkNFX0RJ
QUxFQ1RfVU5TUEVDSUZJRUQQABIMCghURVJBREFUQRABIqYCChZUcmFuc2xhdGVRdWVyeVJl
c3BvbnNlEi8KD3RyYW5zbGF0aW9uX2pvYhgEIAEoCUIG4EED4EEFUg50cmFuc2xhdGlvbkpv
YhIpChB0cmFuc2xhdGVkX3F1ZXJ5GAEgASgJUg90cmFuc2xhdGVkUXVlcnkSVAoGZXJyb3Jz
GAIgAygLMjwuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLlNxbFRy
YW5zbGF0aW9uRXJyb3JSBmVycm9ycxJaCgh3YXJuaW5ncxgDIAMoCzI+Lmdvb2dsZS5jbG91
ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBoYS5TcWxUcmFuc2xhdGlvbldhcm5pbmdSCHdh
cm5pbmdzIl8KGVNxbFRyYW5zbGF0aW9uRXJyb3JEZXRhaWwSEAoDcm93GAEgASgDUgNyb3cS
FgoGY29sdW1uGAIgASgDUgZjb2x1bW4SGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZSLrAgoT
U3FsVHJhbnNsYXRpb25FcnJvchJzCgplcnJvcl90eXBlGAEgASgOMlQuZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLlNxbFRyYW5zbGF0aW9uRXJyb3IuU3FsVHJh
bnNsYXRpb25FcnJvclR5cGVSCWVycm9yVHlwZRJlCgxlcnJvcl9kZXRhaWwYAiABKAsyQi5n
b29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuU3FsVHJhbnNsYXRpb25F
cnJvckRldGFpbFILZXJyb3JEZXRhaWwieAoXU3FsVHJhbnNsYXRpb25FcnJvclR5cGUSKgom
U1FMX1RSQU5TTEFUSU9OX0VSUk9SX1RZUEVfVU5TUEVDSUZJRUQQABITCg9TUUxfUEFSU0Vf
RVJST1IQARIcChhVTlNVUFBPUlRFRF9TUUxfRlVOQ1RJT04QAiKCAQoVU3FsVHJhbnNsYXRp
b25XYXJuaW5nEmkKDndhcm5pbmdfZGV0YWlsGAEgASgLMkIuZ29vZ2xlLmNsb3VkLmJpZ3F1
ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLlNxbFRyYW5zbGF0aW9uRXJyb3JEZXRhaWxSDXdhcm5p
bmdEZXRhaWwy4wIKFVNxbFRyYW5zbGF0aW9uU2VydmljZRLzAQoOVHJhbnNsYXRlUXVlcnkS
Pi5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuVHJhbnNsYXRlUXVl
cnlSZXF1ZXN0Gj8uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLlRy
YW5zbGF0ZVF1ZXJ5UmVzcG9uc2UiYILT5JMCPCI3L3YyYWxwaGEve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qfTp0cmFuc2xhdGVRdWVyeToBKtpBG3BhcmVudCxzb3VyY2VfZGlh
bGVjdCxxdWVyeRpUykEgYmlncXVlcnltaWdyYXRpb24uZ29vZ2xlYXBpcy5jb23SQS5odHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQucBCitjb20uZ29v
Z2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhQhdUcmFuc2xhdGlvblNlcnZp
Y2VQcm90b1ABWkljbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L21pZ3JhdGlvbi9hcGl2
MmFscGhhL21pZ3JhdGlvbnBiO21pZ3JhdGlvbnBiqgInR29vZ2xlLkNsb3VkLkJpZ1F1ZXJ5
Lk1pZ3JhdGlvbi5WMkFscGhhygInR29vZ2xlXENsb3VkXEJpZ1F1ZXJ5XE1pZ3JhdGlvblxW
MmFscGhhSt8gCgcSBQ4AhgEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAwCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMK
CAoBCBIDFwBECgkKAgglEgMXAEQKCAoBCBIDGABgCgkKAggLEgMYAGAKCAoBCBIDGQAiCgkK
AggKEgMZACIKCAoBCBIDGgA4CgkKAggIEgMaADgKCAoBCBIDGwBECgkKAggBEgMbAEQKCAoB
CBIDHABFCgkKAggpEgMcAEUKTgoCBgASBB8AKwEaQiBQcm92aWRlcyBvdGhlciBTUUwgZGlh
bGVjdHMgdG8gR29vZ2xlU1FMIHRyYW5zbGF0aW9uIG9wZXJhdGlvbnMuCgoKCgMGAAESAx8I
HQoKCgMGAAMSAyACSAoMCgUGAAOZCBIDIAJICgoKAwYAAxIDIQJWCgwKBQYAA5oIEgMhAlYK
SwoEBgACABIEJAIqAxo9IFRyYW5zbGF0ZXMgaW5wdXQgcXVlcmllcyBmcm9tIHNvdXJjZSBk
aWFsZWN0cyB0byBHb29nbGVTUUwuCgoMCgUGAAIAARIDJAYUCgwKBQYAAgACEgMkFSoKDAoF
BgACAAMSAyQ1SwoNCgUGAAIABBIEJQQoBgoRCgkGAAIABLDKvCISBCUEKAYKDAoFBgACAAQS
AykESQoPCggGAAIABJsIABIDKQRJCkUKAgQAEgQuAEYBGjkgVGhlIHJlcXVlc3Qgb2YgdHJh
bnNsYXRpbmcgYSBTUUwgcXVlcnkgdG8gU3RhbmRhcmQgU1FMLgoKCgoDBAABEgMuCB0KOgoE
BAAEABIEMAI2AxosIFN1cHBvcnRlZCBTUUwgdHJhbnNsYXRpb24gc291cmNlIGRpYWxlY3Rz
LgoKDAoFBAAEAAESAzAHIgo7CgYEAAQAAgASAzIEMxosIFNxbFRyYW5zbGF0aW9uU291cmNl
RGlhbGVjdCBub3Qgc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDMgQuCg4KBwQABAACAAISAzIx
MgoeCgYEAAQAAgESAzUEERoPIFRlcmFkYXRhIFNRTC4KCg4KBwQABAACAQESAzUEDAoOCgcE
AAQAAgECEgM1DxAKgwEKBAQAAgASBDoCPwQadSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IHByb2plY3QgdG8gd2hpY2ggdGhpcyB0cmFuc2xhdGlvbiByZXF1ZXN0IGJlbG9uZ3MuCiBF
eGFtcGxlOiBgcHJvamVjdHMvZm9vL2xvY2F0aW9ucy9iYXJgCgoMCgUEAAIABRIDOgIICgwK
BQQAAgABEgM6CQ8KDAoFBAACAAMSAzoSEwoNCgUEAAIACBIEOhQ/AwoPCggEAAIACJwIABID
OwQqCg8KBwQAAgAInwgSBDwEPgUKPQoEBAACARIDQgJaGjAgUmVxdWlyZWQuIFRoZSBzb3Vy
Y2UgU1FMIGRpYWxlY3Qgb2YgYHF1ZXJpZXNgLgoKDAoFBAACAQYSA0ICHQoMCgUEAAIBARID
Qh4sCgwKBQQAAgEDEgNCLzAKDAoFBAACAQgSA0IxWQoPCggEAAIBCJwIABIDQjJYCjQKBAQA
AgISA0UCPBonIFJlcXVpcmVkLiBUaGUgcXVlcnkgdG8gYmUgdHJhbnNsYXRlZC4KCgwKBQQA
AgIFEgNFAggKDAoFBAACAgESA0UJDgoMCgUEAAICAxIDRRESCgwKBQQAAgIIEgNFEzsKDwoI
BAACAgicCAASA0UUOgpGCgIEARIESQBaARo6IFRoZSByZXNwb25zZSBvZiB0cmFuc2xhdGlu
ZyBhIFNRTCBxdWVyeSB0byBTdGFuZGFyZCBTUUwuCgoKCgMEAQESA0kIHgqSAQoEBAECABIE
TAJPBBqDASBPdXRwdXQgb25seS4gSW1tdXRhYmxlLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIg
Zm9yIHRoZSBTUUwgdHJhbnNsYXRpb24gam9iLgogRXhhbXBsZTogYHByb2plY3RzLzEyMy9s
b2NhdGlvbnMvdXMvdHJhbnNsYXRpb24vMTIzNGAKCgwKBQQBAgAFEgNMAggKDAoFBAECAAES
A0wJGAoMCgUEAQIAAxIDTBscCg0KBQQBAgAIEgRMHU8DCg8KCAQBAgAInAgAEgNNBC0KDwoI
BAECAAicCAESA04EKwpSCgQEAQIBEgNSAh4aRSBUaGUgdHJhbnNsYXRlZCByZXN1bHQuIFRo
aXMgd2lsbCBiZSBlbXB0eSBpZiB0aGUgdHJhbnNsYXRpb24gZmFpbHMuCgoMCgUEAQIBBRID
UgIICgwKBQQBAgEBEgNSCRkKDAoFBAECAQMSA1IcHQpRCgQEAQICEgNVAioaRCBUaGUgbGlz
dCBvZiBlcnJvcnMgZW5jb3VudGVyZWQgZHVyaW5nIHRoZSB0cmFuc2xhdGlvbiwgaWYgcHJl
c2VudC4KCgwKBQQBAgIEEgNVAgoKDAoFBAECAgYSA1ULHgoMCgUEAQICARIDVR8lCgwKBQQB
AgIDEgNVKCkKhAEKBAQBAgMSA1kCLhp3IFRoZSBsaXN0IG9mIHdhcm5pbmdzIGVuY291bnRl
cmVkIGR1cmluZyB0aGUgdHJhbnNsYXRpb24sIGlmIHByZXNlbnQsCiBpbmRpY2F0ZXMgbm9u
LXNlbWFudGljYWxseSBjb3JyZWN0IHRyYW5zbGF0aW9uLgoKDAoFBAECAwQSA1kCCgoMCgUE
AQIDBhIDWQsgCgwKBQQBAgMBEgNZISkKDAoFBAECAwMSA1ksLQp+CgIEAhIEXgBnARpyIFN0
cnVjdHVyZWQgZXJyb3Igb2JqZWN0IGNhcHR1cmluZyB0aGUgZXJyb3IgbWVzc2FnZSBhbmQg
dGhlIGxvY2F0aW9uIGluIHRoZQogc291cmNlIHRleHQgd2hlcmUgdGhlIGVycm9yIG9jY3Vy
cy4KCgoKAwQCARIDXgghCk8KBAQCAgASA2ACEBpCIFNwZWNpZmllcyB0aGUgcm93IGZyb20g
dGhlIHNvdXJjZSB0ZXh0IHdoZXJlIHRoZSBlcnJvciBvY2N1cnJlZC4KCgwKBQQCAgAFEgNg
AgcKDAoFBAICAAESA2AICwoMCgUEAgIAAxIDYA4PClIKBAQCAgESA2MCExpFIFNwZWNpZmll
IHRoZSBjb2x1bW4gZnJvbSB0aGUgc291cmNlIHRleHRzIHdoZXJlIHRoZSBlcnJvciBvY2N1
cnJlZC4KCgwKBQQCAgEFEgNjAgcKDAoFBAICAQESA2MIDgoMCgUEAgIBAxIDYxESCjkKBAQC
AgISA2YCFRosIEEgaHVtYW4tcmVhZGFibGUgZGVzY3JpcHRpb24gb2YgdGhlIGVycm9yLgoK
DAoFBAICAgUSA2YCCAoMCgUEAgICARIDZgkQCgwKBQQCAgIDEgNmExQKSQoCBAMSBGoAfgEa
PSBUaGUgZGV0YWlsZWQgZXJyb3Igb2JqZWN0IGlmIHRoZSBTUUwgdHJhbnNsYXRpb24gam9i
IGZhaWxzLgoKCgoDBAMBEgNqCBsKOgoEBAMEABIEbAJ2AxosIFRoZSBlcnJvciB0eXBlIG9m
IHRoZSBTUUwgdHJhbnNsYXRpb24gam9iLgoKDAoFBAMEAAESA2wHHgo3CgYEAwQAAgASA24E
LxooIFNxbFRyYW5zbGF0aW9uRXJyb3JUeXBlIG5vdCBzcGVjaWZpZWQuCgoOCgcEAwQAAgAB
EgNuBCoKDgoHBAMEAAIAAhIDbi0uCj8KBgQDBAACARIDcQQYGjAgRmFpbGVkIHRvIHBhcnNl
IHRoZSBpbnB1dCB0ZXh0IGFzIGEgU1FMIHF1ZXJ5LgoKDgoHBAMEAAIBARIDcQQTCg4KBwQD
BAACAQISA3EWFwpkCgYEAwQAAgISA3UEIRpVIEZvdW5kIHVuc3VwcG9ydGVkIGZ1bmN0aW9u
cyBpbiB0aGUgaW5wdXQgU1FMIHF1ZXJ5IHRoYXQgYXJlIG5vdCBhYmxlIHRvCiB0cmFuc2xh
dGUuCgoOCgcEAwQAAgIBEgN1BBwKDgoHBAMEAAICAhIDdR8gCjEKBAQDAgASA3kCKRokIFRo
ZSB0eXBlIG9mIFNRTCB0cmFuc2xhdGlvbiBlcnJvci4KCgwKBQQDAgAGEgN5AhkKDAoFBAMC
AAESA3kaJAoMCgUEAwIAAxIDeScoCnIKBAQDAgESA30CLRplIFNwZWNpZmllcyB0aGUgZGV0
YWlscyBvZiB0aGUgZXJyb3IsIGluY2x1ZGluZyB0aGUgZXJyb3IgbWVzc2FnZSBhbmQKIGxv
Y2F0aW9uIGZyb20gdGhlIHNvdXJjZSB0ZXh0LgoKDAoFBAMCAQYSA30CGwoMCgUEAwIBARID
fRwoCgwKBQQDAgEDEgN9KywKcgoCBAQSBoIBAIYBARpkIFRoZSBkZXRhaWxlZCB3YXJuaW5n
IG9iamVjdCBpZiB0aGUgU1FMIHRyYW5zbGF0aW9uIGpvYiBpcyBjb21wbGV0ZWQgYnV0IG5v
dAogc2VtYW50aWNhbGx5IGNvcnJlY3QuCgoLCgMEBAESBIIBCB0KdwoEBAQCABIEhQECLxpp
IFNwZWNpZmllcyB0aGUgZGV0YWlscyBvZiB0aGUgd2FybmluZywgaW5jbHVkaW5nIHRoZSB3
YXJuaW5nIG1lc3NhZ2UgYW5kCiBsb2NhdGlvbiBmcm9tIHRoZSBzb3VyY2UgdGV4dC4KCg0K
BQQEAgAGEgSFAQIbCg0KBQQEAgABEgSFARwqCg0KBQQEAgADEgSFAS0uYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryRequest ===
    # Fields for TranslateQueryRequest
    # Field: parent Type: 9 ()
    # Field: source_dialect Type: 14 (.google.cloud.bigquery.migration.v2alpha.TranslateQueryRequest.SqlTranslationSourceDialect)
    # Field: query Type: 9 ()

# Enum: TranslateQueryRequest::SqlTranslationSourceDialect
our $TranslateQueryRequest_SQL_TRANSLATION_SOURCE_DIALECT_UNSPECIFIED = 0;
our $TranslateQueryRequest_TERADATA = 1;

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryResponse ===
    # Fields for TranslateQueryResponse
    # Field: translation_job Type: 9 ()
    # Field: translated_query Type: 9 ()
    # Field: errors Type: 11 (.google.cloud.bigquery.migration.v2alpha.SqlTranslationError)
    # Field: warnings Type: 11 (.google.cloud.bigquery.migration.v2alpha.SqlTranslationWarning)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationErrorDetail ===
    # Fields for SqlTranslationErrorDetail
    # Field: row Type: 3 ()
    # Field: column Type: 3 ()
    # Field: message Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationError ===
    # Fields for SqlTranslationError
    # Field: error_type Type: 14 (.google.cloud.bigquery.migration.v2alpha.SqlTranslationError.SqlTranslationErrorType)
    # Field: error_detail Type: 11 (.google.cloud.bigquery.migration.v2alpha.SqlTranslationErrorDetail)

# Enum: SqlTranslationError::SqlTranslationErrorType
our $SqlTranslationError_SQL_TRANSLATION_ERROR_TYPE_UNSPECIFIED = 0;
our $SqlTranslationError_SQL_PARSE_ERROR = 1;
our $SqlTranslationError_UNSUPPORTED_SQL_FUNCTION = 2;

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationWarning ===
    # Fields for SqlTranslationWarning
    # Field: warning_detail Type: 11 (.google.cloud.bigquery.migration.v2alpha.SqlTranslationErrorDetail)

# === Service Client: Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationServiceClient ===
package Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationServiceClient

Client stub representing the remote C<SqlTranslationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub translate_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.migration.v2alpha.SqlTranslationService',
        method         => 'TranslateQuery',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::TranslationService - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2alpha/translation_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2alpha::TranslationService;

    my $msg = Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryRequest->new({
        parent => $parent,
        source_dialect => $source_dialect,
        query => $query,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2alpha/translation_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryRequest

The request of translating a SQL query to Standard SQL.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the project to which this translation request belongs.
Example: `projects/foo/locations/bar`

=item * C<< $msg->source_dialect() >> / C<< $msg->source_dialect($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslateQueryRequest::SqlTranslationSourceDialect>)

Required. The source SQL dialect of `queries`.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Required. The query to be translated.

=back

=head3 Enum: TranslateQueryRequest::SqlTranslationSourceDialect

=over 4

=item * C<SQL_TRANSLATION_SOURCE_DIALECT_UNSPECIFIED> => C<0>

=item * C<TERADATA> => C<1>

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::TranslateQueryResponse

The response of translating a SQL query to Standard SQL.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translation_job() >> / C<< $msg->translation_job($value) >>

Type: C<String>

Output only. Immutable. The unique identifier for the SQL translation job.
Example: `projects/123/locations/us/translation/1234`

=item * C<< $msg->translated_query() >> / C<< $msg->translated_query($value) >>

Type: C<String>

The translated result. This will be empty if the translation fails.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationError>)

The list of errors encountered during the translation, if present.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationWarning>)

The list of warnings encountered during the translation, if present,
indicates non-semantically correct translation.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationErrorDetail

Structured error object capturing the error message and the location in the
source text where the error occurs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->row() >> / C<< $msg->row($value) >>

Type: C<Int64>

Specifies the row from the source text where the error occurred.

=item * C<< $msg->column() >> / C<< $msg->column($value) >>

Type: C<Int64>

Specifie the column from the source texts where the error occurred.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

A human-readable description of the error.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationError

The detailed error object if the SQL translation job fails.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->error_type() >> / C<< $msg->error_type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2alpha::SqlTranslationError::SqlTranslationErrorType>)

The type of SQL translation error.

=item * C<< $msg->error_detail() >> / C<< $msg->error_detail($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationErrorDetail>)

Specifies the details of the error, including the error message and
location from the source text.

=back

=head3 Enum: SqlTranslationError::SqlTranslationErrorType

=over 4

=item * C<SQL_TRANSLATION_ERROR_TYPE_UNSPECIFIED> => C<0>

=item * C<SQL_PARSE_ERROR> => C<1>

=item * C<UNSUPPORTED_SQL_FUNCTION> => C<2>

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationWarning

The detailed warning object if the SQL translation job is completed but not
semantically correct.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->warning_detail() >> / C<< $msg->warning_detail($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::SqlTranslationErrorDetail>)

Specifies the details of the warning, including the warning message and
location from the source text.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
