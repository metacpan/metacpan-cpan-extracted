package Google::Firestore::V1beta1::Document;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Latlng };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvZmlyZXN0b3JlL3YxYmV0YTEvZG9jdW1lbnQucHJvdG8SGGdvb2dsZS5maXJl
c3RvcmUudjFiZXRhMRocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90bxoYZ29vZ2xlL3R5cGUvbGF0bG5nLnByb3RvIrwCCghE
b2N1bWVudBISCgRuYW1lGAEgASgJUgRuYW1lEkYKBmZpZWxkcxgCIAMoCzIuLmdvb2dsZS5m
aXJlc3RvcmUudjFiZXRhMS5Eb2N1bWVudC5GaWVsZHNFbnRyeVIGZmllbGRzEjsKC2NyZWF0
ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7
Cgt1cGRhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0
ZVRpbWUaWgoLRmllbGRzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSNQoFdmFsdWUYAiABKAsy
Hy5nb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEuVmFsdWVSBXZhbHVlOgI4ASLKBAoFVmFsdWUS
OwoKbnVsbF92YWx1ZRgLIAEoDjIaLmdvb2dsZS5wcm90b2J1Zi5OdWxsVmFsdWVIAFIJbnVs
bFZhbHVlEiUKDWJvb2xlYW5fdmFsdWUYASABKAhIAFIMYm9vbGVhblZhbHVlEiUKDWludGVn
ZXJfdmFsdWUYAiABKANIAFIMaW50ZWdlclZhbHVlEiMKDGRvdWJsZV92YWx1ZRgDIAEoAUgA
Ugtkb3VibGVWYWx1ZRJFCg90aW1lc3RhbXBfdmFsdWUYCiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wSABSDnRpbWVzdGFtcFZhbHVlEiMKDHN0cmluZ192YWx1ZRgRIAEoCUgA
UgtzdHJpbmdWYWx1ZRIhCgtieXRlc192YWx1ZRgSIAEoDEgAUgpieXRlc1ZhbHVlEikKD3Jl
ZmVyZW5jZV92YWx1ZRgFIAEoCUgAUg5yZWZlcmVuY2VWYWx1ZRI9Cg9nZW9fcG9pbnRfdmFs
dWUYCCABKAsyEy5nb29nbGUudHlwZS5MYXRMbmdIAFINZ2VvUG9pbnRWYWx1ZRJHCgthcnJh
eV92YWx1ZRgJIAEoCzIkLmdvb2dsZS5maXJlc3RvcmUudjFiZXRhMS5BcnJheVZhbHVlSABS
CmFycmF5VmFsdWUSQQoJbWFwX3ZhbHVlGAYgASgLMiIuZ29vZ2xlLmZpcmVzdG9yZS52MWJl
dGExLk1hcFZhbHVlSABSCG1hcFZhbHVlQgwKCnZhbHVlX3R5cGUiRQoKQXJyYXlWYWx1ZRI3
CgZ2YWx1ZXMYASADKAsyHy5nb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEuVmFsdWVSBnZhbHVl
cyKuAQoITWFwVmFsdWUSRgoGZmllbGRzGAEgAygLMi4uZ29vZ2xlLmZpcmVzdG9yZS52MWJl
dGExLk1hcFZhbHVlLkZpZWxkc0VudHJ5UgZmaWVsZHMaWgoLRmllbGRzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSNQoFdmFsdWUYAiABKAsyHy5nb29nbGUuZmlyZXN0b3JlLnYxYmV0YTEu
VmFsdWVSBXZhbHVlOgI4AULeAQocY29tLmdvb2dsZS5maXJlc3RvcmUudjFiZXRhMUINRG9j
dW1lbnRQcm90b1ABWkBjbG91ZC5nb29nbGUuY29tL2dvL2ZpcmVzdG9yZS9hcGl2MWJldGEx
L2ZpcmVzdG9yZXBiO2ZpcmVzdG9yZXBiogIER0NGU6oCHkdvb2dsZS5DbG91ZC5GaXJlc3Rv
cmUuVjFCZXRhMcoCHkdvb2dsZVxDbG91ZFxGaXJlc3RvcmVcVjFiZXRhMeoCIUdvb2dsZTo6
Q2xvdWQ6OkZpcmVzdG9yZTo6VjFiZXRhMUqZJgoHEgUOAJQBAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgAmCgkKAgMBEgMTACkKCQoC
AwISAxQAIgoICgEIEgMWADsKCQoCCCUSAxYAOwoICgEIEgMXAFcKCQoCCAsSAxcAVwoICgEI
EgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC4KCQoCCAgSAxkALgoICgEIEgMaADUKCQoCCAES
AxoANQoICgEIEgMbACIKCQoCCCQSAxsAIgoICgEIEgMcADsKCQoCCCkSAxwAOwoICgEIEgMd
ADoKCQoCCC0SAx0AOgpGCgIEABIEIgBOARo6IEEgRmlyZXN0b3JlIGRvY3VtZW50LgoKIE11
c3Qgbm90IGV4Y2VlZCAxIE1pQiAtIDQgYnl0ZXMuCgoKCgMEAAESAyIIEAqJAQoEBAACABID
JQISGnwgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGRvY3VtZW50LCBmb3IgZXhhbXBsZQog
YHByb2plY3RzL3twcm9qZWN0X2lkfS9kYXRhYmFzZXMve2RhdGFiYXNlX2lkfS9kb2N1bWVu
dHMve2RvY3VtZW50X3BhdGh9YC4KCgwKBQQAAgAFEgMlAggKDAoFBAACAAESAyUJDQoMCgUE
AAIAAxIDJRARCsAICgQEAAIBEgM/AiAasgggVGhlIGRvY3VtZW50J3MgZmllbGRzLgoKIFRo
ZSBtYXAga2V5cyByZXByZXNlbnQgZmllbGQgbmFtZXMuCgogQSBzaW1wbGUgZmllbGQgbmFt
ZSBjb250YWlucyBvbmx5IGNoYXJhY3RlcnMgYGFgIHRvIGB6YCwgYEFgIHRvIGBaYCwKIGAw
YCB0byBgOWAsIG9yIGBfYCwgYW5kIG11c3Qgbm90IHN0YXJ0IHdpdGggYDBgIHRvIGA5YC4g
Rm9yIGV4YW1wbGUsCiBgZm9vX2Jhcl8xN2AuCgogRmllbGQgbmFtZXMgbWF0Y2hpbmcgdGhl
IHJlZ3VsYXIgZXhwcmVzc2lvbiBgX18uKl9fYCBhcmUgcmVzZXJ2ZWQuIFJlc2VydmVkCiBm
aWVsZCBuYW1lcyBhcmUgZm9yYmlkZGVuIGV4Y2VwdCBpbiBjZXJ0YWluIGRvY3VtZW50ZWQg
Y29udGV4dHMuIFRoZSBtYXAKIGtleXMsIHJlcHJlc2VudGVkIGFzIFVURi04LCBtdXN0IG5v
dCBleGNlZWQgMSw1MDAgYnl0ZXMgYW5kIGNhbm5vdCBiZQogZW1wdHkuCgogRmllbGQgcGF0
aHMgbWF5IGJlIHVzZWQgaW4gb3RoZXIgY29udGV4dHMgdG8gcmVmZXIgdG8gc3RydWN0dXJl
ZCBmaWVsZHMKIGRlZmluZWQgaGVyZS4gRm9yIGBtYXBfdmFsdWVgLCB0aGUgZmllbGQgcGF0
aCBpcyByZXByZXNlbnRlZCBieSB0aGUgc2ltcGxlCiBvciBxdW90ZWQgZmllbGQgbmFtZXMg
b2YgdGhlIGNvbnRhaW5pbmcgZmllbGRzLCBkZWxpbWl0ZWQgYnkgYC5gLiBGb3IKIGV4YW1w
bGUsIHRoZSBzdHJ1Y3R1cmVkIGZpZWxkCiBgImZvbyIgOiB7IG1hcF92YWx1ZTogeyAieCZ5
IiA6IHsgc3RyaW5nX3ZhbHVlOiAiaGVsbG8iIH19fWAgd291bGQgYmUKIHJlcHJlc2VudGVk
IGJ5IHRoZSBmaWVsZCBwYXRoIGBmb28ueCZ5YC4KCiBXaXRoaW4gYSBmaWVsZCBwYXRoLCBh
IHF1b3RlZCBmaWVsZCBuYW1lIHN0YXJ0cyBhbmQgZW5kcyB3aXRoIGBgIGAgYGAgYW5kCiBt
YXkgY29udGFpbiBhbnkgY2hhcmFjdGVyLiBTb21lIGNoYXJhY3RlcnMsIGluY2x1ZGluZyBg
YCBgIGBgLCBtdXN0IGJlCiBlc2NhcGVkIHVzaW5nIGEgYFxgLiBGb3IgZXhhbXBsZSwgYGAg
YHgmeWAgYGAgcmVwcmVzZW50cyBgeCZ5YCBhbmQKIGBgIGBiYWtcYHRpa2AgYGAgcmVwcmVz
ZW50cyBgYCBiYWtgdGlrIGBgLgoKDAoFBAACAQYSAz8CFAoMCgUEAAIBARIDPxUbCgwKBQQA
AgEDEgM/Hh8K8QEKBAQAAgISA0YCLBrjASBPdXRwdXQgb25seS4gVGhlIHRpbWUgYXQgd2hp
Y2ggdGhlIGRvY3VtZW50IHdhcyBjcmVhdGVkLgoKIFRoaXMgdmFsdWUgaW5jcmVhc2VzIG1v
bm90b25pY2FsbHkgd2hlbiBhIGRvY3VtZW50IGlzIGRlbGV0ZWQgdGhlbgogcmVjcmVhdGVk
LiBJdCBjYW4gYWxzbyBiZSBjb21wYXJlZCB0byB2YWx1ZXMgZnJvbSBvdGhlciBkb2N1bWVu
dHMgYW5kCiB0aGUgYHJlYWRfdGltZWAgb2YgYSBxdWVyeS4KCgwKBQQAAgIGEgNGAhsKDAoF
BAACAgESA0YcJwoMCgUEAAICAxIDRiorCpgCCgQEAAIDEgNNAiwaigIgT3V0cHV0IG9ubHku
IFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBkb2N1bWVudCB3YXMgbGFzdCBjaGFuZ2VkLgoKIFRo
aXMgdmFsdWUgaXMgaW5pdGlhbGx5IHNldCB0byB0aGUgYGNyZWF0ZV90aW1lYCB0aGVuIGlu
Y3JlYXNlcwogbW9ub3RvbmljYWxseSB3aXRoIGVhY2ggY2hhbmdlIHRvIHRoZSBkb2N1bWVu
dC4gSXQgY2FuIGFsc28gYmUKIGNvbXBhcmVkIHRvIHZhbHVlcyBmcm9tIG90aGVyIGRvY3Vt
ZW50cyBhbmQgdGhlIGByZWFkX3RpbWVgIG9mIGEgcXVlcnkuCgoMCgUEAAIDBhIDTQIbCgwK
BQQAAgMBEgNNHCcKDAoFBAACAwMSA00qKwpICgIEARIFUQCDAQEaOyBBIG1lc3NhZ2UgdGhh
dCBjYW4gaG9sZCBhbnkgb2YgdGhlIHN1cHBvcnRlZCB2YWx1ZSB0eXBlcy4KCgoKAwQBARID
UQgNCicKBAQBCAASBVMCggEDGhggTXVzdCBoYXZlIGEgdmFsdWUgc2V0LgoKDAoFBAEIAAES
A1MIEgocCgQEAQIAEgNVBC4aDyBBIG51bGwgdmFsdWUuCgoMCgUEAQIABhIDVQQdCgwKBQQB
AgABEgNVHigKDAoFBAECAAMSA1UrLQofCgQEAQIBEgNYBBsaEiBBIGJvb2xlYW4gdmFsdWUu
CgoMCgUEAQIBBRIDWAQICgwKBQQBAgEBEgNYCRYKDAoFBAECAQMSA1gZGgogCgQEAQICEgNb
BBwaEyBBbiBpbnRlZ2VyIHZhbHVlLgoKDAoFBAECAgUSA1sECQoMCgUEAQICARIDWwoXCgwK
BQQBAgIDEgNbGhsKHgoEBAECAxIDXgQcGhEgQSBkb3VibGUgdmFsdWUuCgoMCgUEAQIDBRID
XgQKCgwKBQQBAgMBEgNeCxcKDAoFBAECAwMSA14aGwp5CgQEAQIEEgNkBDMabCBBIHRpbWVz
dGFtcCB2YWx1ZS4KCiBQcmVjaXNlIG9ubHkgdG8gbWljcm9zZWNvbmRzLiBXaGVuIHN0b3Jl
ZCwgYW55IGFkZGl0aW9uYWwgcHJlY2lzaW9uIGlzCiByb3VuZGVkIGRvd24uCgoMCgUEAQIE
BhIDZAQdCgwKBQQBAgQBEgNkHi0KDAoFBAECBAMSA2QwMgq5AQoEBAECBRIDawQdGqsBIEEg
c3RyaW5nIHZhbHVlLgoKIFRoZSBzdHJpbmcsIHJlcHJlc2VudGVkIGFzIFVURi04LCBtdXN0
IG5vdCBleGNlZWQgMSBNaUIgLSA4OSBieXRlcy4KIE9ubHkgdGhlIGZpcnN0IDEsNTAwIGJ5
dGVzIG9mIHRoZSBVVEYtOCByZXByZXNlbnRhdGlvbiBhcmUgY29uc2lkZXJlZCBieQogcXVl
cmllcy4KCgwKBQQBAgUFEgNrBAoKDAoFBAECBQESA2sLFwoMCgUEAQIFAxIDaxocCngKBAQB
AgYSA3EEGxprIEEgYnl0ZXMgdmFsdWUuCgogTXVzdCBub3QgZXhjZWVkIDEgTWlCIC0gODkg
Ynl0ZXMuCiBPbmx5IHRoZSBmaXJzdCAxLDUwMCBieXRlcyBhcmUgY29uc2lkZXJlZCBieSBx
dWVyaWVzLgoKDAoFBAECBgUSA3EECQoMCgUEAQIGARIDcQoVCgwKBQQBAgYDEgNxGBoKggEK
BAQBAgcSA3UEHxp1IEEgcmVmZXJlbmNlIHRvIGEgZG9jdW1lbnQuIEZvciBleGFtcGxlOgog
YHByb2plY3RzL3twcm9qZWN0X2lkfS9kYXRhYmFzZXMve2RhdGFiYXNlX2lkfS9kb2N1bWVu
dHMve2RvY3VtZW50X3BhdGh9YC4KCgwKBQQBAgcFEgN1BAoKDAoFBAECBwESA3ULGgoMCgUE
AQIHAxIDdR0eCk4KBAQBAggSA3gEKxpBIEEgZ2VvIHBvaW50IHZhbHVlIHJlcHJlc2VudGlu
ZyBhIHBvaW50IG9uIHRoZSBzdXJmYWNlIG9mIEVhcnRoLgoKDAoFBAECCAYSA3gEFgoMCgUE
AQIIARIDeBcmCgwKBQQBAggDEgN4KSoKhgEKBAQBAgkSA34EHxp5IEFuIGFycmF5IHZhbHVl
LgoKIENhbm5vdCBkaXJlY3RseSBjb250YWluIGFub3RoZXIgYXJyYXkgdmFsdWUsIHRob3Vn
aCBjYW4gY29udGFpbiBhbgogbWFwIHdoaWNoIGNvbnRhaW5zIGFub3RoZXIgYXJyYXkuCgoM
CgUEAQIJBhIDfgQOCgwKBQQBAgkBEgN+DxoKDAoFBAECCQMSA34dHgocCgQEAQIKEgSBAQQb
Gg4gQSBtYXAgdmFsdWUuCgoNCgUEAQIKBhIEgQEEDAoNCgUEAQIKARIEgQENFgoNCgUEAQIK
AxIEgQEZGgofCgIEAhIGhgEAiQEBGhEgQW4gYXJyYXkgdmFsdWUuCgoLCgMEAgESBIYBCBIK
JAoEBAICABIEiAECHBoWIFZhbHVlcyBpbiB0aGUgYXJyYXkuCgoNCgUEAgIABBIEiAECCgoN
CgUEAgIABhIEiAELEAoNCgUEAgIAARIEiAERFwoNCgUEAgIAAxIEiAEaGwocCgIEAxIGjAEA
lAEBGg4gQSBtYXAgdmFsdWUuCgoLCgMEAwESBIwBCBAKrQIKBAQDAgASBJMBAiAangIgVGhl
IG1hcCdzIGZpZWxkcy4KCiBUaGUgbWFwIGtleXMgcmVwcmVzZW50IGZpZWxkIG5hbWVzLiBG
aWVsZCBuYW1lcyBtYXRjaGluZyB0aGUgcmVndWxhcgogZXhwcmVzc2lvbiBgX18uKl9fYCBh
cmUgcmVzZXJ2ZWQuIFJlc2VydmVkIGZpZWxkIG5hbWVzIGFyZSBmb3JiaWRkZW4gZXhjZXB0
CiBpbiBjZXJ0YWluIGRvY3VtZW50ZWQgY29udGV4dHMuIFRoZSBtYXAga2V5cywgcmVwcmVz
ZW50ZWQgYXMgVVRGLTgsIG11c3QKIG5vdCBleGNlZWQgMSw1MDAgYnl0ZXMgYW5kIGNhbm5v
dCBiZSBlbXB0eS4KCg0KBQQDAgAGEgSTAQIUCg0KBQQDAgABEgSTARUbCg0KBQQDAgADEgST
AR4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1beta1::Document::Document ===
    # Fields for Document
    # Field: name Type: 9 ()
    # Field: fields Type: 11 (.google.firestore.v1beta1.Document.FieldsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Firestore::V1beta1::Document::Value ===
    # Fields for Value
    # Field: null_value Type: 14 (.google.protobuf.NullValue)
    # Field: boolean_value Type: 8 ()
    # Field: integer_value Type: 3 ()
    # Field: double_value Type: 1 ()
    # Field: timestamp_value Type: 11 (.google.protobuf.Timestamp)
    # Field: string_value Type: 9 ()
    # Field: bytes_value Type: 12 ()
    # Field: reference_value Type: 9 ()
    # Field: geo_point_value Type: 11 (.google.type.LatLng)
    # Field: array_value Type: 11 (.google.firestore.v1beta1.ArrayValue)
    # Field: map_value Type: 11 (.google.firestore.v1beta1.MapValue)

# === Message: Google::Firestore::V1beta1::Document::ArrayValue ===
    # Fields for ArrayValue
    # Field: values Type: 11 (.google.firestore.v1beta1.Value)

# === Message: Google::Firestore::V1beta1::Document::MapValue ===
    # Fields for MapValue
    # Field: fields Type: 11 (.google.firestore.v1beta1.MapValue.FieldsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1beta1::Document - Compiled Protocol Buffers messages for google/firestore/v1beta1/document.proto

=head1 SYNOPSIS

    use Google::Firestore::V1beta1::Document;

    my $msg = Google::Firestore::V1beta1::Document::Document->new({
        name => $name,
        fields => $fields,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1beta1::Document::Document->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1beta1/document.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1beta1::Document::Document

A Firestore document.

Must not exceed 1 MiB - 4 bytes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the document, for example
`projects/{project_id}/databases/{database_id}/documents/{document_path}`.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Document::Document::FieldsEntry>)

The document's fields.

The map keys represent field names.

A simple field name contains only characters `a` to `z`, `A` to `Z`,
`0` to `9`, or `_`, and must not start with `0` to `9`. For example,
`foo_bar_17`.

Field names matching the regular expression `__.*__` are reserved. Reserved
field names are forbidden except in certain documented contexts. The map
keys, represented as UTF-8, must not exceed 1,500 bytes and cannot be
empty.

Field paths may be used in other contexts to refer to structured fields
defined here. For `map_value`, the field path is represented by the simple
or quoted field names of the containing fields, delimited by `.`. For
example, the structured field
`"foo" : { map_value: { "x&y" : { string_value: "hello" }}}` would be
represented by the field path `foo.x&y`.

Within a field path, a quoted field name starts and ends with `` ` `` and
may contain any character. Some characters, including `` ` ``, must be
escaped using a `\`. For example, `` `x&y` `` represents `x&y` and
`` `bak\`tik` `` represents `` bak`tik ``.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the document was created.

This value increases monotonically when a document is deleted then
recreated. It can also be compared to values from other documents and
the `read_time` of a query.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the document was last changed.

This value is initially set to the `create_time` then increases
monotonically with each change to the document. It can also be
compared to values from other documents and the `read_time` of a query.

=back

=head2 Google::Firestore::V1beta1::Document::Value

A message that can hold any of the supported value types.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->null_value() >> / C<< $msg->null_value($value) >>

Type: C<Enum> (L<Google::Protobuf::NullValue>)

A null value.

=item * C<< $msg->boolean_value() >> / C<< $msg->boolean_value($value) >>

Type: C<Bool>

A boolean value.

=item * C<< $msg->integer_value() >> / C<< $msg->integer_value($value) >>

Type: C<Int64>

An integer value.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

A double value.

=item * C<< $msg->timestamp_value() >> / C<< $msg->timestamp_value($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

A timestamp value.

Precise only to microseconds. When stored, any additional precision is
rounded down.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

A string value.

The string, represented as UTF-8, must not exceed 1 MiB - 89 bytes.
Only the first 1,500 bytes of the UTF-8 representation are considered by
queries.

=item * C<< $msg->bytes_value() >> / C<< $msg->bytes_value($value) >>

Type: C<Bytes>

A bytes value.

Must not exceed 1 MiB - 89 bytes.
Only the first 1,500 bytes are considered by queries.

=item * C<< $msg->reference_value() >> / C<< $msg->reference_value($value) >>

Type: C<String>

A reference to a document. For example:
`projects/{project_id}/databases/{database_id}/documents/{document_path}`.

=item * C<< $msg->geo_point_value() >> / C<< $msg->geo_point_value($value) >>

Type: C<Message> (L<Google::Type::Latlng::LatLng>)

A geo point value representing a point on the surface of Earth.

=item * C<< $msg->array_value() >> / C<< $msg->array_value($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Document::ArrayValue>)

An array value.

Cannot directly contain another array value, though can contain an
map which contains another array.

=item * C<< $msg->map_value() >> / C<< $msg->map_value($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Document::MapValue>)

A map value.

=back

=head2 Google::Firestore::V1beta1::Document::ArrayValue

An array value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Document::Value>)

Values in the array.

=back

=head2 Google::Firestore::V1beta1::Document::MapValue

A map value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Firestore::V1beta1::Document::MapValue::FieldsEntry>)

The map's fields.

The map keys represent field names. Field names matching the regular
expression `__.*__` are reserved. Reserved field names are forbidden except
in certain documented contexts. The map keys, represented as UTF-8, must
not exceed 1,500 bytes and cannot be empty.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1beta1::Document::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
