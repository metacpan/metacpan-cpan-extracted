package Google::Cloud::Identitytoolkit::V2::AccountManagementService;

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
    eval { require Google::Cloud::Identitytoolkit::V2::MfaInfo };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvaWRlbnRpdHl0b29sa2l0L3YyL2FjY291bnRfbWFuYWdlbWVudF9z
ZXJ2aWNlLnByb3RvEh9nb29nbGUuY2xvdWQuaWRlbnRpdHl0b29sa2l0LnYyGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxouZ29vZ2xlL2Nsb3VkL2lkZW50aXR5dG9vbGtp
dC92Mi9tZmFfaW5mby5wcm90byKLAgocRmluYWxpemVNZmFFbnJvbGxtZW50UmVxdWVzdBIe
CghpZF90b2tlbhgBIAEoCUID4EECUgdpZFRva2VuEiEKDGRpc3BsYXlfbmFtZRgDIAEoCVIL
ZGlzcGxheU5hbWUSdgoXcGhvbmVfdmVyaWZpY2F0aW9uX2luZm8YBCABKAsyPC5nb29nbGUu
Y2xvdWQuaWRlbnRpdHl0b29sa2l0LnYyLkZpbmFsaXplTWZhUGhvbmVSZXF1ZXN0SW5mb0gA
UhVwaG9uZVZlcmlmaWNhdGlvbkluZm8SGwoJdGVuYW50X2lkGAUgASgJUgh0ZW5hbnRJZEIT
ChF2ZXJpZmljYXRpb25faW5mbyLfAQodRmluYWxpemVNZmFFbnJvbGxtZW50UmVzcG9uc2US
GQoIaWRfdG9rZW4YASABKAlSB2lkVG9rZW4SIwoNcmVmcmVzaF90b2tlbhgCIAEoCVIMcmVm
cmVzaFRva2VuEmcKD3Bob25lX2F1dGhfaW5mbxgDIAEoCzI9Lmdvb2dsZS5jbG91ZC5pZGVu
dGl0eXRvb2xraXQudjIuRmluYWxpemVNZmFQaG9uZVJlc3BvbnNlSW5mb0gAUg1waG9uZUF1
dGhJbmZvQhUKE2F1eGlsaWFyeV9hdXRoX2luZm8i3AEKGVN0YXJ0TWZhRW5yb2xsbWVudFJl
cXVlc3QSHgoIaWRfdG9rZW4YASABKAlCA+BBAlIHaWRUb2tlbhJvChVwaG9uZV9lbnJvbGxt
ZW50X2luZm8YAyABKAsyOS5nb29nbGUuY2xvdWQuaWRlbnRpdHl0b29sa2l0LnYyLlN0YXJ0
TWZhUGhvbmVSZXF1ZXN0SW5mb0gAUhNwaG9uZUVucm9sbG1lbnRJbmZvEhsKCXRlbmFudF9p
ZBgEIAEoCVIIdGVuYW50SWRCEQoPZW5yb2xsbWVudF9pbmZvIp8BChpTdGFydE1mYUVucm9s
bG1lbnRSZXNwb25zZRJqChJwaG9uZV9zZXNzaW9uX2luZm8YASABKAsyOi5nb29nbGUuY2xv
dWQuaWRlbnRpdHl0b29sa2l0LnYyLlN0YXJ0TWZhUGhvbmVSZXNwb25zZUluZm9IAFIQcGhv
bmVTZXNzaW9uSW5mb0IVChNlbnJvbGxtZW50X3Jlc3BvbnNlIoIBChJXaXRoZHJhd01mYVJl
cXVlc3QSHgoIaWRfdG9rZW4YASABKAlCA+BBAlIHaWRUb2tlbhIvChFtZmFfZW5yb2xsbWVu
dF9pZBgCIAEoCUID4EECUg9tZmFFbnJvbGxtZW50SWQSGwoJdGVuYW50X2lkGAMgASgJUgh0
ZW5hbnRJZCJVChNXaXRoZHJhd01mYVJlc3BvbnNlEhkKCGlkX3Rva2VuGAEgASgJUgdpZFRv
a2VuEiMKDXJlZnJlc2hfdG9rZW4YAiABKAlSDHJlZnJlc2hUb2tlbjKfBQoYQWNjb3VudE1h
bmFnZW1lbnRTZXJ2aWNlEsYBChVGaW5hbGl6ZU1mYUVucm9sbG1lbnQSPS5nb29nbGUuY2xv
dWQuaWRlbnRpdHl0b29sa2l0LnYyLkZpbmFsaXplTWZhRW5yb2xsbWVudFJlcXVlc3QaPi5n
b29nbGUuY2xvdWQuaWRlbnRpdHl0b29sa2l0LnYyLkZpbmFsaXplTWZhRW5yb2xsbWVudFJl
c3BvbnNlIi6C0+STAigiIy92Mi9hY2NvdW50cy9tZmFFbnJvbGxtZW50OmZpbmFsaXplOgEq
EroBChJTdGFydE1mYUVucm9sbG1lbnQSOi5nb29nbGUuY2xvdWQuaWRlbnRpdHl0b29sa2l0
LnYyLlN0YXJ0TWZhRW5yb2xsbWVudFJlcXVlc3QaOy5nb29nbGUuY2xvdWQuaWRlbnRpdHl0
b29sa2l0LnYyLlN0YXJ0TWZhRW5yb2xsbWVudFJlc3BvbnNlIiuC0+STAiUiIC92Mi9hY2Nv
dW50cy9tZmFFbnJvbGxtZW50OnN0YXJ0OgEqEqgBCgtXaXRoZHJhd01mYRIzLmdvb2dsZS5j
bG91ZC5pZGVudGl0eXRvb2xraXQudjIuV2l0aGRyYXdNZmFSZXF1ZXN0GjQuZ29vZ2xlLmNs
b3VkLmlkZW50aXR5dG9vbGtpdC52Mi5XaXRoZHJhd01mYVJlc3BvbnNlIi6C0+STAigiIy92
Mi9hY2NvdW50cy9tZmFFbnJvbGxtZW50OndpdGhkcmF3OgEqGlLKQR5pZGVudGl0eXRvb2xr
aXQuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Ns
b3VkLXBsYXRmb3JtQt8BCiNjb20uZ29vZ2xlLmNsb3VkLmlkZW50aXR5dG9vbGtpdC52MlAB
Wk1jbG91ZC5nb29nbGUuY29tL2dvL2lkZW50aXR5dG9vbGtpdC9hcGl2Mi9pZGVudGl0eXRv
b2xraXRwYjtpZGVudGl0eXRvb2xraXRwYqoCH0dvb2dsZS5DbG91ZC5JZGVudGl0eVRvb2xr
aXQuVjLKAh9Hb29nbGVcQ2xvdWRcSWRlbnRpdHlUb29sa2l0XFYy6gIiR29vZ2xlOjpDbG91
ZDo6SWRlbnRpdHlUb29sa2l0OjpWMkrWIQoHEgUOAI4BAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAKQoJCgIDAxIDFQA4CggKAQgSAxcAPAoJCgIIJRIDFwA8CggKAQgSAxgAZAoJCgIICxID
GABkCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAPAoJCgIIARIDGgA8CggKAQgSAxsA
PAoJCgIIKRIDGwA8CggKAQgSAxwAOwoJCgIILRIDHAA7CjUKAgYAEgQfADsBGikgQWNjb3Vu
dCBtYW5hZ2VtZW50IGZvciBJZGVudGl0eSBUb29sa2l0CgoKCgMGAAESAx8IIAoKCgMGAAMS
AyACRgoMCgUGAAOZCBIDIAJGCgoKAwYAAxIDIQJWCgwKBQYAA5oIEgMhAlYKQAoEBgACABIE
JAIpAxoyIEZpbmlzaGVzIGVucm9sbGluZyBhIHNlY29uZCBmYWN0b3IgZm9yIHRoZSB1c2Vy
LgoKDAoFBgACAAESAyQGGwoMCgUGAAIAAhIDJBw4CgwKBQYAAgADEgMkQ2AKDQoFBgACAAQS
BCUEKAYKEQoJBgACAASwyrwiEgQlBCgGCnYKBAYAAgESBC0CMgMaaCBTdGVwIG9uZSBvZiB0
aGUgTUZBIGVucm9sbG1lbnQgcHJvY2Vzcy4gSW4gU01TIGNhc2UsIHRoaXMgc2VuZHMgYW4K
IFNNUyB2ZXJpZmljYXRpb24gY29kZSB0byB0aGUgdXNlci4KCgwKBQYAAgEBEgMtBhgKDAoF
BgACAQISAy0ZMgoMCgUGAAIBAxIDLT1XCg0KBQYAAgEEEgQuBDEGChEKCQYAAgEEsMq8IhIE
LgQxBgpaCgQGAAICEgQ1AjoDGkwgUmV2b2tlcyBvbmUgc2Vjb25kIGZhY3RvciBmcm9tIHRo
ZSBlbnJvbGxlZCBzZWNvbmQgZmFjdG9ycyBmb3IgYW4gYWNjb3VudC4KCgwKBQYAAgIBEgM1
BhEKDAoFBgACAgISAzUSJAoMCgUGAAICAxIDNS9CCg0KBQYAAgIEEgQ2BDkGChEKCQYAAgIE
sMq8IhIENgQ5Bgo+CgIEABIEPgBPARoyIEZpbmlzaGVzIGVucm9sbGluZyBhIHNlY29uZCBm
YWN0b3IgZm9yIHRoZSB1c2VyLgoKCgoDBAABEgM+CCQKIgoEBAACABIDQAI/GhUgUmVxdWly
ZWQuIElEIHRva2VuLgoKDAoFBAACAAUSA0ACCAoMCgUEAAIAARIDQAkRCgwKBQQAAgADEgNA
FBUKDAoFBAACAAgSA0AWPgoPCggEAAIACJwIABIDQBc9CokBCgQEAAIBEgNEAhoafCBEaXNw
bGF5IG5hbWUgd2hpY2ggaXMgZW50ZXJlZCAgYnkgdXNlcnMgdG8gZGlzdGluZ3Vpc2ggYmV0
d2VlbiBkaWZmZXJlbnQKIHNlY29uZCBmYWN0b3JzIHdpdGggc2FtZSB0eXBlIG9yIGRpZmZl
cmVudCB0eXBlLgoKDAoFBAACAQUSA0QCCAoMCgUEAAIBARIDRAkVCgwKBQQAAgEDEgNEGBkK
OgoEBAAIABIERwJKAxosIE1GQSBlbnJvbGxtZW50IGluZm9ybWF0aW9uIHRvIGJlIHZlcmlm
aWVkLgoKDAoFBAAIAAESA0cIGQpUCgQEAAICEgNJBDwaRyBWZXJpZmljYXRpb24gaW5mbyB0
byBhdXRob3JpemUgc2VuZGluZyBhbiBTTVMgZm9yIHBob25lIHZlcmlmaWNhdGlvbi4KCgwK
BQQAAgIGEgNJBB8KDAoFBAACAgESA0kgNwoMCgUEAAICAxIDSTo7CqYBCgQEAAIDEgNOAhca
mAEgVGhlIElEIG9mIHRoZSBJZGVudGl0eSBQbGF0Zm9ybSB0ZW5hbnQgdGhhdCB0aGUgdXNl
ciBlbnJvbGxpbmcgTUZBIGJlbG9uZ3MKIHRvLiBJZiBub3Qgc2V0LCB0aGUgdXNlciBiZWxv
bmdzIHRvIHRoZSBkZWZhdWx0IElkZW50aXR5IFBsYXRmb3JtIHByb2plY3QuCgoMCgUEAAID
BRIDTgIICgwKBQQAAgMBEgNOCRIKDAoFBAACAwMSA04VFgotCgIEARIEUgBeARohIEZpbmFs
aXplTWZhRW5yb2xsbWVudCByZXNwb25zZS4KCgoKAwQBARIDUgglCjoKBAQBAgASA1QCFhot
IElEIHRva2VuIHVwZGF0ZWQgdG8gcmVmbGVjdCBNRkEgZW5yb2xsbWVudC4KCgwKBQQBAgAF
EgNUAggKDAoFBAECAAESA1QJEQoMCgUEAQIAAxIDVBQVCj8KBAQBAgESA1cCGxoyIFJlZnJl
c2ggdG9rZW4gdXBkYXRlZCB0byByZWZsZWN0IE1GQSBlbnJvbGxtZW50LgoKDAoFBAECAQUS
A1cCCAoMCgUEAQIBARIDVwkWCgwKBQQBAgEDEgNXGRoKNAoEBAEIABIEWgJdAxomIE1GQSB2
ZXJpZmllZCBlbnJvbGxtZW50IGluZm9ybWF0aW9uLgoKDAoFBAEIAAESA1oIGwo6CgQEAQIC
EgNcBDUaLSBBdXhpbGlhcnkgYXV0aCBpbmZvIHNwZWNpZmljIHRvIHBob25lIGF1dGguCgoM
CgUEAQICBhIDXAQgCgwKBQQBAgIBEgNcITAKDAoFBAECAgMSA1wzNAo/CgIEAhIEYQBuARoz
IFNlbmRzIE1GQSBlbnJvbGxtZW50IHZlcmlmaWNhdGlvbiBTTVMgZm9yIGEgdXNlci4KCgoK
AwQCARIDYQghCikKBAQCAgASA2MCPxocIFJlcXVpcmVkLiBVc2VyJ3MgSUQgdG9rZW4uCgoM
CgUEAgIABRIDYwIICgwKBQQCAgABEgNjCREKDAoFBAICAAMSA2MUFQoMCgUEAgIACBIDYxY+
Cg8KCAQCAgAInAgAEgNjFz0KNgoEBAIIABIEZgJpAxooIE1GQSBpbmZvcm1hdGlvbiBieSB0
eXBlIG9mIDJuZCBmYWN0b3IuCgoMCgUEAggAARIDZggXClQKBAQCAgESA2gENxpHIFZlcmlm
aWNhdGlvbiBpbmZvIHRvIGF1dGhvcml6ZSBzZW5kaW5nIGFuIFNNUyBmb3IgcGhvbmUgdmVy
aWZpY2F0aW9uLgoKDAoFBAICAQYSA2gEHAoMCgUEAgIBARIDaB0yCgwKBQQCAgEDEgNoNTYK
pgEKBAQCAgISA20CFxqYASBUaGUgSUQgb2YgdGhlIElkZW50aXR5IFBsYXRmb3JtIHRlbmFu
dCB0aGF0IHRoZSB1c2VyIGVucm9sbGluZyBNRkEgYmVsb25ncwogdG8uIElmIG5vdCBzZXQs
IHRoZSB1c2VyIGJlbG9uZ3MgdG8gdGhlIGRlZmF1bHQgSWRlbnRpdHkgUGxhdGZvcm0gcHJv
amVjdC4KCgwKBQQCAgIFEgNtAggKDAoFBAICAgESA20JEgoMCgUEAgICAxIDbRUWCioKAgQD
EgRxAHcBGh4gU3RhcnRNZmFFbnJvbGxtZW50IHJlc3BvbnNlLgoKCgoDBAMBEgNxCCIKQQoE
BAMIABIEcwJ2AxozIE1GQSBzdGFydCBlbnJvbGxtZW50IHJlc3BvbnNlIGJ5IDJuZCBmYWN0
b3IgdHlwZS4KCgwKBQQDCAABEgNzCBsKVAoEBAMCABIDdQQ1GkcgVmVyaWZpY2F0aW9uIGlu
Zm8gdG8gYXV0aG9yaXplIHNlbmRpbmcgYW4gU01TIGZvciBwaG9uZSB2ZXJpZmljYXRpb24u
CgoMCgUEAwIABhIDdQQdCgwKBQQDAgABEgN1HjAKDAoFBAMCAAMSA3UzNAodCgIEBBIFegCF
AQEaECBXaXRoZHJhd3MgTUZBLgoKCgoDBAQBEgN6CBoKKQoEBAQCABIDfAI/GhwgUmVxdWly
ZWQuIFVzZXIncyBJRCB0b2tlbi4KCgwKBQQEAgAFEgN8AggKDAoFBAQCAAESA3wJEQoMCgUE
BAIAAxIDfBQVCgwKBQQEAgAIEgN8Fj4KDwoIBAQCAAicCAASA3wXPQpJCgQEBAIBEgN/Akga
PCBSZXF1aXJlZC4gTUZBIGVucm9sbG1lbnQgaWQgZnJvbSBhIGN1cnJlbnQgTUZBIGVucm9s
bG1lbnQuCgoMCgUEBAIBBRIDfwIICgwKBQQEAgEBEgN/CRoKDAoFBAQCAQMSA38dHgoMCgUE
BAIBCBIDfx9HCg8KCAQEAgEInAgAEgN/IEYKqgEKBAQEAgISBIQBAhcamwEgVGhlIElEIG9m
IHRoZSBJZGVudGl0eSBQbGF0Zm9ybSB0ZW5hbnQgdGhhdCB0aGUgdXNlciB1bmVucm9sbGlu
ZyBNRkEKIGJlbG9uZ3MgdG8uIElmIG5vdCBzZXQsIHRoZSB1c2VyIGJlbG9uZ3MgdG8gdGhl
IGRlZmF1bHQgSWRlbnRpdHkgUGxhdGZvcm0KIHByb2plY3QuCgoNCgUEBAICBRIEhAECCAoN
CgUEBAICARIEhAEJEgoNCgUEBAICAxIEhAEVFgozCgIEBRIGiAEAjgEBGiUgV2l0aGRyYXdz
IE11bHRpRmFjdG9yQXV0aCByZXNwb25zZS4KCgsKAwQFARIEiAEIGwpJCgQEBQIAEgSKAQIW
GjsgSUQgdG9rZW4gdXBkYXRlZCB0byByZWZsZWN0IHJlbW92YWwgb2YgdGhlIHNlY29uZCBm
YWN0b3IuCgoNCgUEBQIABRIEigECCAoNCgUEBQIAARIEigEJEQoNCgUEBQIAAxIEigEUFQpO
CgQEBQIBEgSNAQIbGkAgUmVmcmVzaCB0b2tlbiB1cGRhdGVkIHRvIHJlZmxlY3QgcmVtb3Zh
bCBvZiB0aGUgc2Vjb25kIGZhY3Rvci4KCg0KBQQFAgEFEgSNAQIICg0KBQQFAgEBEgSNAQkW
Cg0KBQQFAgEDEgSNARkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest ===
    # Fields for FinalizeMfaEnrollmentRequest
    # Field: id_token Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: phone_verification_info Type: 11 (.google.cloud.identitytoolkit.v2.FinalizeMfaPhoneRequestInfo)
    # Field: tenant_id Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse ===
    # Fields for FinalizeMfaEnrollmentResponse
    # Field: id_token Type: 9 ()
    # Field: refresh_token Type: 9 ()
    # Field: phone_auth_info Type: 11 (.google.cloud.identitytoolkit.v2.FinalizeMfaPhoneResponseInfo)

# === Message: Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest ===
    # Fields for StartMfaEnrollmentRequest
    # Field: id_token Type: 9 ()
    # Field: phone_enrollment_info Type: 11 (.google.cloud.identitytoolkit.v2.StartMfaPhoneRequestInfo)
    # Field: tenant_id Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse ===
    # Fields for StartMfaEnrollmentResponse
    # Field: phone_session_info Type: 11 (.google.cloud.identitytoolkit.v2.StartMfaPhoneResponseInfo)

# === Message: Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest ===
    # Fields for WithdrawMfaRequest
    # Field: id_token Type: 9 ()
    # Field: mfa_enrollment_id Type: 9 ()
    # Field: tenant_id Type: 9 ()

# === Message: Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse ===
    # Fields for WithdrawMfaResponse
    # Field: id_token Type: 9 ()
    # Field: refresh_token Type: 9 ()

# === Service Client: Google::Cloud::Identitytoolkit::V2::AccountManagementService::AccountManagementServiceClient ===
package Google::Cloud::Identitytoolkit::V2::AccountManagementService::AccountManagementServiceClient;

=pod

=head2 Service Client: Google::Cloud::Identitytoolkit::V2::AccountManagementService::AccountManagementServiceClient

Client stub representing the remote C<AccountManagementService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<identitytoolkit.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'identitytoolkit.googleapis.com:443' );

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

sub finalize_mfa_enrollment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.identitytoolkit.v2.AccountManagementService',
        method         => 'FinalizeMfaEnrollment',
        request        => $req,
        response_class => 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse',
    });
}

sub start_mfa_enrollment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.identitytoolkit.v2.AccountManagementService',
        method         => 'StartMfaEnrollment',
        request        => $req,
        response_class => 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse',
    });
}

sub withdraw_mfa {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.identitytoolkit.v2.AccountManagementService',
        method         => 'WithdrawMfa',
        request        => $req,
        response_class => 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Identitytoolkit::V2::AccountManagementService - Compiled Protocol Buffers messages for google/cloud/identitytoolkit/v2/account_management_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Identitytoolkit::V2::AccountManagementService;

    my $msg = Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest->new({
        id_token => $id_token,
        display_name => $display_name,
        phone_verification_info => $phone_verification_info,
        tenant_id => $tenant_id,
    });

    # Read or update a field
    my $val = $msg->id_token();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/identitytoolkit/v2/account_management_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest

Finishes enrolling a second factor for the user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id_token() >> / C<< $msg->id_token($value) >>

Type: C<String>

Required. ID token.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name which is entered  by users to distinguish between different
second factors with same type or different type.

=item * C<< $msg->phone_verification_info() >> / C<< $msg->phone_verification_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneRequestInfo>)

Verification info to authorize sending an SMS for phone verification.

=item * C<< $msg->tenant_id() >> / C<< $msg->tenant_id($value) >>

Type: C<String>

The ID of the Identity Platform tenant that the user enrolling MFA belongs
to. If not set, the user belongs to the default Identity Platform project.

=back

=head2 Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse

FinalizeMfaEnrollment response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id_token() >> / C<< $msg->id_token($value) >>

Type: C<String>

ID token updated to reflect MFA enrollment.

=item * C<< $msg->refresh_token() >> / C<< $msg->refresh_token($value) >>

Type: C<String>

Refresh token updated to reflect MFA enrollment.

=item * C<< $msg->phone_auth_info() >> / C<< $msg->phone_auth_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::FinalizeMfaPhoneResponseInfo>)

Auxiliary auth info specific to phone auth.

=back

=head2 Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest

Sends MFA enrollment verification SMS for a user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id_token() >> / C<< $msg->id_token($value) >>

Type: C<String>

Required. User's ID token.

=item * C<< $msg->phone_enrollment_info() >> / C<< $msg->phone_enrollment_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneRequestInfo>)

Verification info to authorize sending an SMS for phone verification.

=item * C<< $msg->tenant_id() >> / C<< $msg->tenant_id($value) >>

Type: C<String>

The ID of the Identity Platform tenant that the user enrolling MFA belongs
to. If not set, the user belongs to the default Identity Platform project.

=back

=head2 Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse

StartMfaEnrollment response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->phone_session_info() >> / C<< $msg->phone_session_info($value) >>

Type: C<Message> (L<Google::Cloud::Identitytoolkit::V2::MfaInfo::StartMfaPhoneResponseInfo>)

Verification info to authorize sending an SMS for phone verification.

=back

=head2 Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest

Withdraws MFA.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id_token() >> / C<< $msg->id_token($value) >>

Type: C<String>

Required. User's ID token.

=item * C<< $msg->mfa_enrollment_id() >> / C<< $msg->mfa_enrollment_id($value) >>

Type: C<String>

Required. MFA enrollment id from a current MFA enrollment.

=item * C<< $msg->tenant_id() >> / C<< $msg->tenant_id($value) >>

Type: C<String>

The ID of the Identity Platform tenant that the user unenrolling MFA
belongs to. If not set, the user belongs to the default Identity Platform
project.

=back

=head2 Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse

Withdraws MultiFactorAuth response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id_token() >> / C<< $msg->id_token($value) >>

Type: C<String>

ID token updated to reflect removal of the second factor.

=item * C<< $msg->refresh_token() >> / C<< $msg->refresh_token($value) >>

Type: C<String>

Refresh token updated to reflect removal of the second factor.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Identitytoolkit::V2::AccountManagementService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
