package Google::Cloud::Ces::V1beta::Schema;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9zY2hlbWEucHJvdG8SF2dvb2dsZS5jbG91ZC5j
ZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhxnb29nbGUvcHJv
dG9idWYvc3RydWN0LnByb3RvItYJCgZTY2hlbWESPQoEdHlwZRgBIAEoDjIkLmdvb2dsZS5j
bG91ZC5jZXMudjFiZXRhLlNjaGVtYS5UeXBlQgPgQQJSBHR5cGUSVAoKcHJvcGVydGllcxgC
IAMoCzIvLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlNjaGVtYS5Qcm9wZXJ0aWVzRW50cnlC
A+BBAVIKcHJvcGVydGllcxIfCghyZXF1aXJlZBgDIAMoCUID4EEBUghyZXF1aXJlZBIlCgtk
ZXNjcmlwdGlvbhgEIAEoCUID4EEBUgtkZXNjcmlwdGlvbhI6CgVpdGVtcxgFIAEoCzIfLmdv
b2dsZS5jbG91ZC5jZXMudjFiZXRhLlNjaGVtYUID4EEBUgVpdGVtcxIfCghudWxsYWJsZRgG
IAEoCEID4EEBUghudWxsYWJsZRImCgx1bmlxdWVfaXRlbXMYByABKAhCA+BBAVILdW5pcXVl
SXRlbXMSRwoMcHJlZml4X2l0ZW1zGAggAygLMh8uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEu
U2NoZW1hQgPgQQFSC3ByZWZpeEl0ZW1zElkKFWFkZGl0aW9uYWxfcHJvcGVydGllcxgJIAEo
CzIfLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlNjaGVtYUID4EEBUhRhZGRpdGlvbmFsUHJv
cGVydGllcxI7CgZhbnlfb2YYCiADKAsyHy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5TY2hl
bWFCA+BBAVIFYW55T2YSFwoEZW51bRgLIAMoCUID4EEBUgRlbnVtEjUKB2RlZmF1bHQYDCAB
KAsyFi5nb29nbGUucHJvdG9idWYuVmFsdWVCA+BBAVIHZGVmYXVsdBIVCgNyZWYYDSABKAlC
A+BBAVIDcmVmEkIKBGRlZnMYDiADKAsyKS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5TY2hl
bWEuRGVmc0VudHJ5QgPgQQFSBGRlZnMSGQoFdGl0bGUYDyABKAlCA+BBAVIFdGl0bGUSIAoJ
bWluX2l0ZW1zGBAgASgDQgPgQQFSCG1pbkl0ZW1zEiAKCW1heF9pdGVtcxgRIAEoA0ID4EEB
UghtYXhJdGVtcxIiCgdtaW5pbXVtGBIgASgBQgPgQQFIAFIHbWluaW11bYgBARIiCgdtYXhp
bXVtGBMgASgBQgPgQQFIAVIHbWF4aW11bYgBARpeCg9Qcm9wZXJ0aWVzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSNQoFdmFsdWUYAiABKAsyHy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5T
Y2hlbWFSBXZhbHVlOgI4ARpYCglEZWZzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSNQoFdmFs
dWUYAiABKAsyHy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5TY2hlbWFSBXZhbHVlOgI4ASJl
CgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABIKCgZTVFJJTkcQARILCgdJTlRFR0VSEAIS
CgoGTlVNQkVSEAMSCwoHQk9PTEVBThAEEgoKBk9CSkVDVBAFEgkKBUFSUkFZEAZCCgoIX21p
bmltdW1CCgoIX21heGltdW1CWwobY29tLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhQgtTY2hl
bWFQcm90b1ABWi1jbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7Y2Vz
cGJKkiYKBxIFDgCLAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACAKCQoCAwASAxIAKQoJCgIDARIDEwAmCggKAQgSAxUARAoJCgIICxIDFQBECggKAQgS
AxYAIgoJCgIIChIDFgAiCggKAQgSAxcALAoJCgIICBIDFwAsCggKAQgSAxgANAoJCgIIARID
GAA0CkoKAgQAEgUbAIsBARo9IFJlcHJlc2VudHMgYSBzZWxlY3Qgc3Vic2V0IG9mIGFuIE9w
ZW5BUEkgMy4wIHNjaGVtYSBvYmplY3QuCgoKCgMEAAESAxsIDgojCgQEAAQAEgQdAjIDGhUg
T3BlbkFQSSBkYXRhIHR5cGVzLgoKDAoFBAAEAAESAx0HCwoiCgYEAAQAAgASAx8EGRoTIFR5
cGUgdW5zcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMfBBQKDgoHBAAEAAIAAhIDHxcYCh0KBgQA
BAACARIDIgQPGg4gU3RyaW5nIHR5cGUuCgoOCgcEAAQAAgEBEgMiBAoKDgoHBAAEAAIBAhID
Ig0OCh4KBgQABAACAhIDJQQQGg8gSW50ZWdlciB0eXBlLgoKDgoHBAAEAAICARIDJQQLCg4K
BwQABAACAgISAyUODwodCgYEAAQAAgMSAygEDxoOIE51bWJlciB0eXBlLgoKDgoHBAAEAAID
ARIDKAQKCg4KBwQABAACAwISAygNDgoeCgYEAAQAAgQSAysEEBoPIEJvb2xlYW4gdHlwZS4K
Cg4KBwQABAACBAESAysECwoOCgcEAAQAAgQCEgMrDg8KHQoGBAAEAAIFEgMuBA8aDiBPYmpl
Y3QgdHlwZS4KCg4KBwQABAACBQESAy4ECgoOCgcEAAQAAgUCEgMuDQ4KHAoGBAAEAAIGEgMx
BA4aDSBBcnJheSB0eXBlLgoKDgoHBAAEAAIGARIDMQQJCg4KBwQABAACBgISAzEMDQouCgQE
AAIAEgM1AjkaISBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgdGhlIGRhdGEuCgoMCgUEAAIABhID
NQIGCgwKBQQAAgABEgM1BwsKDAoFBAACAAMSAzUODwoMCgUEAAIACBIDNRA4Cg8KCAQAAgAI
nAgAEgM1ETcKMwoEBAACARIDOAJOGiYgT3B0aW9uYWwuIFByb3BlcnRpZXMgb2YgVHlwZS5P
QkpFQ1QuCgoMCgUEAAIBBhIDOAIVCgwKBQQAAgEBEgM4FiAKDAoFBAACAQMSAzgjJAoMCgUE
AAIBCBIDOCVNCg8KCAQAAgEInAgAEgM4JkwKPAoEBAACAhIDOwJIGi8gT3B0aW9uYWwuIFJl
cXVpcmVkIHByb3BlcnRpZXMgb2YgVHlwZS5PQkpFQ1QuCgoMCgUEAAICBBIDOwIKCgwKBQQA
AgIFEgM7CxEKDAoFBAACAgESAzsSGgoMCgUEAAICAxIDOx0eCgwKBQQAAgIIEgM7H0cKDwoI
BAACAgicCAASAzsgRgo1CgQEAAIDEgM+AkIaKCBPcHRpb25hbC4gVGhlIGRlc2NyaXB0aW9u
IG9mIHRoZSBkYXRhLgoKDAoFBAACAwUSAz4CCAoMCgUEAAIDARIDPgkUCgwKBQQAAgMDEgM+
FxgKDAoFBAACAwgSAz4ZQQoPCggEAAIDCJwIABIDPhpACj4KBAQAAgQSA0ECPBoxIE9wdGlv
bmFsLiBTY2hlbWEgb2YgdGhlIGVsZW1lbnRzIG9mIFR5cGUuQVJSQVkuCgoMCgUEAAIEBhID
QQIICgwKBQQAAgQBEgNBCQ4KDAoFBAACBAMSA0EREgoMCgUEAAIECBIDQRM7Cg8KCAQAAgQI
nAgAEgNBFDoKPAoEBAACBRIDRAI9Gi8gT3B0aW9uYWwuIEluZGljYXRlcyBpZiB0aGUgdmFs
dWUgbWF5IGJlIG51bGwuCgoMCgUEAAIFBRIDRAIGCgwKBQQAAgUBEgNEBw8KDAoFBAACBQMS
A0QSEwoMCgUEAAIFCBIDRBQ8Cg8KCAQAAgUInAgAEgNEFTsKZQoEBAACBhIDSAJBGlggT3B0
aW9uYWwuIEluZGljYXRlIHRoZSBpdGVtcyBpbiB0aGUgYXJyYXkgbXVzdCBiZSB1bmlxdWUu
IE9ubHkgYXBwbGllcyB0bwogVFlQRS5BUlJBWS4KCgwKBQQAAgYFEgNIAgYKDAoFBAACBgES
A0gHEwoMCgUEAAIGAxIDSBYXCgwKBQQAAgYIEgNIGEAKDwoIBAACBgicCAASA0gZPwpDCgQE
AAIHEgNLAkwaNiBPcHRpb25hbC4gU2NoZW1hcyBvZiBpbml0aWFsIGVsZW1lbnRzIG9mIFR5
cGUuQVJSQVkuCgoMCgUEAAIHBBIDSwIKCgwKBQQAAgcGEgNLCxEKDAoFBAACBwESA0sSHgoM
CgUEAAIHAxIDSyEiCgwKBQQAAgcIEgNLI0sKDwoIBAACBwicCAASA0skSgpvCgQEAAIIEgNP
AkwaYiBPcHRpb25hbC4gQ2FuIGVpdGhlciBiZSBhIGJvb2xlYW4gb3IgYW4gb2JqZWN0LCBj
b250cm9scyB0aGUgcHJlc2VuY2Ugb2YKIGFkZGl0aW9uYWwgcHJvcGVydGllcy4KCgwKBQQA
AggGEgNPAggKDAoFBAACCAESA08JHgoMCgUEAAIIAxIDTyEiCgwKBQQAAggIEgNPI0sKDwoI
BAACCAicCAASA08kSgpwCgQEAAIJEgNTAkcaYyBPcHRpb25hbC4gVGhlIHZhbHVlIHNob3Vs
ZCBiZSB2YWxpZGF0ZWQgYWdhaW5zdCBhbnkgKG9uZSBvciBtb3JlKSBvZiB0aGUKIHN1YnNj
aGVtYXMgaW4gdGhlIGxpc3QuCgoMCgUEAAIJBBIDUwIKCgwKBQQAAgkGEgNTCxEKDAoFBAAC
CQESA1MSGAoMCgUEAAIJAxIDUxsdCgwKBQQAAgkIEgNTHkYKDwoIBAACCQicCAASA1MfRQqt
AgoEBAACChIDWwJFGp8CIE9wdGlvbmFsLiBQb3NzaWJsZSB2YWx1ZXMgb2YgdGhlIGVsZW1l
bnQgb2YgcHJpbWl0aXZlIHR5cGUgd2l0aCBlbnVtCiBmb3JtYXQuIEV4YW1wbGVzOgogMS4g
V2UgY2FuIGRlZmluZSBkaXJlY3Rpb24gYXMgOgoge3R5cGU6U1RSSU5HLCBmb3JtYXQ6ZW51
bSwgZW51bTpbIkVBU1QiLCBOT1JUSCIsICJTT1VUSCIsICJXRVNUIl19CiAyLiBXZSBjYW4g
ZGVmaW5lIGFwYXJ0bWVudCBudW1iZXIgYXMgOgoge3R5cGU6SU5URUdFUiwgZm9ybWF0OmVu
dW0sIGVudW06WyIxMDEiLCAiMjAxIiwgIjMwMSJdfQoKDAoFBAACCgQSA1sCCgoMCgUEAAIK
BRIDWwsRCgwKBQQAAgoBEgNbEhYKDAoFBAACCgMSA1sZGwoMCgUEAAIKCBIDWxxECg8KCAQA
AgoInAgAEgNbHUMKMwoEBAACCxIDXgJOGiYgT3B0aW9uYWwuIERlZmF1bHQgdmFsdWUgb2Yg
dGhlIGRhdGEuCgoMCgUEAAILBhIDXgIXCgwKBQQAAgsBEgNeGB8KDAoFBAACCwMSA14iJAoM
CgUEAAILCBIDXiVNCg8KCAQAAgsInAgAEgNeJkwKoQQKBAQAAgwSA3cCOxqTBCBPcHRpb25h
bC4gQWxsb3dzIGluZGlyZWN0IHJlZmVyZW5jZXMgYmV0d2VlbiBzY2hlbWEgbm9kZXMuIFRo
ZSB2YWx1ZSBzaG91bGQKIGJlIGEgdmFsaWQgcmVmZXJlbmNlIHRvIGEgY2hpbGQgb2YgdGhl
IHJvb3QgYGRlZnNgLgoKIEZvciBleGFtcGxlLCB0aGUgZm9sbG93aW5nIHNjaGVtYSBkZWZp
bmVzIGEgcmVmZXJlbmNlIHRvIGEgc2NoZW1hIG5vZGUKIG5hbWVkICJQZXQiOgoKIGBgYAog
dHlwZTogb2JqZWN0CiBwcm9wZXJ0aWVzOgogICBwZXQ6CiAgICAgcmVmOiAjL2RlZnMvUGV0
CiBkZWZzOgogICBQZXQ6CiAgICAgdHlwZTogb2JqZWN0CiAgICAgcHJvcGVydGllczoKICAg
ICAgIG5hbWU6CiAgICAgICAgIHR5cGU6IHN0cmluZwogYGBgCgogVGhlIHZhbHVlIG9mIHRo
ZSAicGV0IiBwcm9wZXJ0eSBpcyBhIHJlZmVyZW5jZSB0byB0aGUgc2NoZW1hIG5vZGUKIG5h
bWVkICJQZXQiLgogU2VlIGRldGFpbHMgaW4KIGh0dHBzOi8vanNvbi1zY2hlbWEub3JnL3Vu
ZGVyc3RhbmRpbmctanNvbi1zY2hlbWEvc3RydWN0dXJpbmcuCgoMCgUEAAIMBRIDdwIICgwK
BQQAAgwBEgN3CQwKDAoFBAACDAMSA3cPEQoMCgUEAAIMCBIDdxI6Cg8KCAQAAgwInAgAEgN3
EzkKaAoEBAACDRIDewJJGlsgT3B0aW9uYWwuIEEgbWFwIG9mIGRlZmluaXRpb25zIGZvciB1
c2UgYnkgYHJlZmAuIE9ubHkgYWxsb3dlZCBhdCB0aGUgcm9vdAogb2YgdGhlIHNjaGVtYS4K
CgwKBQQAAg0GEgN7AhUKDAoFBAACDQESA3sWGgoMCgUEAAINAxIDex0fCgwKBQQAAg0IEgN7
IEgKDwoIBAACDQicCAASA3shRwoxCgQEAAIOEgN+Aj0aJCBPcHRpb25hbC4gVGhlIHRpdGxl
IG9mIHRoZSBzY2hlbWEuCgoMCgUEAAIOBRIDfgIICgwKBQQAAg4BEgN+CQ4KDAoFBAACDgMS
A34REwoMCgUEAAIOCBIDfhQ8Cg8KCAQAAg4InAgAEgN+FTsKSAoEBAACDxIEgQECQBo6IE9w
dGlvbmFsLiBNaW5pbXVtIG51bWJlciBvZiB0aGUgZWxlbWVudHMgZm9yIFR5cGUuQVJSQVku
CgoNCgUEAAIPBRIEgQECBwoNCgUEAAIPARIEgQEIEQoNCgUEAAIPAxIEgQEUFgoNCgUEAAIP
CBIEgQEXPwoQCggEAAIPCJwIABIEgQEYPgpICgQEAAIQEgSEAQJAGjogT3B0aW9uYWwuIE1h
eGltdW0gbnVtYmVyIG9mIHRoZSBlbGVtZW50cyBmb3IgVHlwZS5BUlJBWS4KCg0KBQQAAhAF
EgSEAQIHCg0KBQQAAhABEgSEAQgRCg0KBQQAAhADEgSEARQWCg0KBQQAAhAIEgSEARc/ChAK
CAQAAhAInAgAEgSEARg+CkkKBAQAAhESBIcBAkgaOyBPcHRpb25hbC4gTWluaW11bSB2YWx1
ZSBmb3IgVHlwZS5JTlRFR0VSIGFuZCBUeXBlLk5VTUJFUi4KCg0KBQQAAhEEEgSHAQIKCg0K
BQQAAhEFEgSHAQsRCg0KBQQAAhEBEgSHARIZCg0KBQQAAhEDEgSHARweCg0KBQQAAhEIEgSH
AR9HChAKCAQAAhEInAgAEgSHASBGCkkKBAQAAhISBIoBAkgaOyBPcHRpb25hbC4gTWF4aW11
bSB2YWx1ZSBmb3IgVHlwZS5JTlRFR0VSIGFuZCBUeXBlLk5VTUJFUi4KCg0KBQQAAhIEEgSK
AQIKCg0KBQQAAhIFEgSKAQsRCg0KBQQAAhIBEgSKARIZCg0KBQQAAhIDEgSKARweCg0KBQQA
AhIIEgSKAR9HChAKCAQAAhIInAgAEgSKASBGYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Schema::Schema ===
    # Fields for Schema
    # Field: type Type: 14 (.google.cloud.ces.v1beta.Schema.Type)
    # Field: properties Type: 11 (.google.cloud.ces.v1beta.Schema.PropertiesEntry)
    # Field: required Type: 9 ()
    # Field: description Type: 9 ()
    # Field: items Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: nullable Type: 8 ()
    # Field: unique_items Type: 8 ()
    # Field: prefix_items Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: additional_properties Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: any_of Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: enum Type: 9 ()
    # Field: default Type: 11 (.google.protobuf.Value)
    # Field: ref Type: 9 ()
    # Field: defs Type: 11 (.google.cloud.ces.v1beta.Schema.DefsEntry)
    # Field: title Type: 9 ()
    # Field: min_items Type: 3 ()
    # Field: max_items Type: 3 ()
    # Field: minimum Type: 1 ()
    # Field: maximum Type: 1 ()

# Enum: Schema::Type
our $Schema_TYPE_UNSPECIFIED = 0;
our $Schema_STRING = 1;
our $Schema_INTEGER = 2;
our $Schema_NUMBER = 3;
our $Schema_BOOLEAN = 4;
our $Schema_OBJECT = 5;
our $Schema_ARRAY = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Schema - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Schema;

    my $msg = Google::Cloud::Ces::V1beta::Schema::Schema->new({
        type => $type,
        properties => $properties,
        required => $required,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Schema::Schema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Schema::Schema

Represents a select subset of an OpenAPI 3.0 schema object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::Schema::Type>)

Required. The type of the data.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema::PropertiesEntry>)

Optional. Properties of Type.OBJECT.

=item * C<< $msg->required() >> / C<< $msg->required($value) >>

Type: C<String>

Optional. Required properties of Type.OBJECT.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the data.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Optional. Schema of the elements of Type.ARRAY.

=item * C<< $msg->nullable() >> / C<< $msg->nullable($value) >>

Type: C<Bool>

Optional. Indicates if the value may be null.

=item * C<< $msg->unique_items() >> / C<< $msg->unique_items($value) >>

Type: C<Bool>

Optional. Indicate the items in the array must be unique. Only applies to
TYPE.ARRAY.

=item * C<< $msg->prefix_items() >> / C<< $msg->prefix_items($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Optional. Schemas of initial elements of Type.ARRAY.

=item * C<< $msg->additional_properties() >> / C<< $msg->additional_properties($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Optional. Can either be a boolean or an object, controls the presence of
additional properties.

=item * C<< $msg->any_of() >> / C<< $msg->any_of($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Optional. The value should be validated against any (one or more) of the
subschemas in the list.

=item * C<< $msg->enum() >> / C<< $msg->enum($value) >>

Type: C<String>

Optional. Possible values of the element of primitive type with enum
format. Examples:
1. We can define direction as :
{type:STRING, format:enum, enum:["EAST", NORTH", "SOUTH", "WEST"]}
2. We can define apartment number as :
{type:INTEGER, format:enum, enum:["101", "201", "301"]}

=item * C<< $msg->default() >> / C<< $msg->default($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Optional. Default value of the data.

=item * C<< $msg->ref() >> / C<< $msg->ref($value) >>

Type: C<String>

Optional. Allows indirect references between schema nodes. The value should
be a valid reference to a child of the root `defs`.

For example, the following schema defines a reference to a schema node
named "Pet":

```
type: object
properties:
  pet:
    ref: #/defs/Pet
defs:
  Pet:
    type: object
    properties:
      name:
        type: string
```

The value of the "pet" property is a reference to the schema node
named "Pet".
See details in
https://json-schema.org/understanding-json-schema/structuring.

=item * C<< $msg->defs() >> / C<< $msg->defs($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema::DefsEntry>)

Optional. A map of definitions for use by `ref`. Only allowed at the root
of the schema.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. The title of the schema.

=item * C<< $msg->min_items() >> / C<< $msg->min_items($value) >>

Type: C<Int64>

Optional. Minimum number of the elements for Type.ARRAY.

=item * C<< $msg->max_items() >> / C<< $msg->max_items($value) >>

Type: C<Int64>

Optional. Maximum number of the elements for Type.ARRAY.

=item * C<< $msg->minimum() >> / C<< $msg->minimum($value) >>

Type: C<Double>

Optional. Minimum value for Type.INTEGER and Type.NUMBER.

=item * C<< $msg->maximum() >> / C<< $msg->maximum($value) >>

Type: C<Double>

Optional. Maximum value for Type.INTEGER and Type.NUMBER.

=back

=head3 Enum: Schema::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<STRING> => C<1>

=item * C<INTEGER> => C<2>

=item * C<NUMBER> => C<3>

=item * C<BOOLEAN> => C<4>

=item * C<OBJECT> => C<5>

=item * C<ARRAY> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Schema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
