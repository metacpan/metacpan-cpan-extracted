package Google::Cloud::Apphub::V1::Application;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Apphub::V1::Attributes };
    eval { require Google::Cloud::Apphub::V1::Properties };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvYXBwaHViL3YxL2FwcGxpY2F0aW9uLnByb3RvEhZnb29nbGUuY2xv
dWQuYXBwaHViLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhtnb29nbGUv
YXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJ2dvb2ds
ZS9jbG91ZC9hcHBodWIvdjEvYXR0cmlidXRlcy5wcm90bxonZ29vZ2xlL2Nsb3VkL2FwcGh1
Yi92MS9wcm9wZXJ0aWVzLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3Rv
IvkGCgtBcHBsaWNhdGlvbhIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJgoMZGlzcGxheV9u
YW1lGAIgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPgQQFS
C2Rlc2NyaXB0aW9uEkcKCmF0dHJpYnV0ZXMYBCABKAsyIi5nb29nbGUuY2xvdWQuYXBwaHVi
LnYxLkF0dHJpYnV0ZXNCA+BBAVIKYXR0cmlidXRlcxJACgtjcmVhdGVfdGltZRgFIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVf
dGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGlt
ZRI7CgVzY29wZRgJIAEoCzIdLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuU2NvcGVCBuBBAuBB
BVIFc2NvcGUSHQoDdWlkGAogASgJQgvijM/XCAIIAeBBA1IDdWlkEkQKBXN0YXRlGAsgASgO
MikuZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5BcHBsaWNhdGlvbi5TdGF0ZUID4EEDUgVzdGF0
ZRJpChZhcHBsaWNhdGlvbl9wcm9wZXJ0aWVzGAwgASgLMi0uZ29vZ2xlLmNsb3VkLmFwcGh1
Yi52MS5BcHBsaWNhdGlvblByb3BlcnRpZXNCA+BBA1IVYXBwbGljYXRpb25Qcm9wZXJ0aWVz
ElcKEGFwcGxpY2F0aW9uX3R5cGUYDSABKAsyJy5nb29nbGUuY2xvdWQuYXBwaHViLnYxLkFw
cGxpY2F0aW9uVHlwZUID4EEDUg9hcHBsaWNhdGlvblR5cGUiRgoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgoKBkFDVElWRRACEgwKCERFTEVUSU5HEAM6
hgHqQYIBCiFhcHBodWIuZ29vZ2xlYXBpcy5jb20vQXBwbGljYXRpb24SQnByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBsaWNhdGlvbnMve2FwcGxpY2F0aW9u
fSoMYXBwbGljYXRpb25zMgthcHBsaWNhdGlvbiKFAQoPQXBwbGljYXRpb25UeXBlEkAKBHR5
cGUYASABKA4yLC5nb29nbGUuY2xvdWQuYXBwaHViLnYxLkFwcGxpY2F0aW9uVHlwZS5UeXBl
UgR0eXBlIjAKBFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEhIKDkFJX0FQUExJQ0FUSU9O
EAEikAEKBVNjb3BlEjsKBHR5cGUYASABKA4yIi5nb29nbGUuY2xvdWQuYXBwaHViLnYxLlNj
b3BlLlR5cGVCA+BBAlIEdHlwZSJKCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABIMCghS
RUdJT05BTBABEgoKBkdMT0JBTBACEhIKDk1VTFRJX1JFR0lPTkFMEAMi/QEKFUFwcGxpY2F0
aW9uUHJvcGVydGllcxJ1ChFleHRlbmRlZF9tZXRhZGF0YRgBIAMoCzJDLmdvb2dsZS5jbG91
ZC5hcHBodWIudjEuQXBwbGljYXRpb25Qcm9wZXJ0aWVzLkV4dGVuZGVkTWV0YWRhdGFFbnRy
eUID4EEDUhBleHRlbmRlZE1ldGFkYXRhGm0KFUV4dGVuZGVkTWV0YWRhdGFFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRI+CgV2YWx1ZRgCIAEoCzIoLmdvb2dsZS5jbG91ZC5hcHBodWIudjEu
RXh0ZW5kZWRNZXRhZGF0YVIFdmFsdWU6AjgBQrIBChpjb20uZ29vZ2xlLmNsb3VkLmFwcGh1
Yi52MUIQQXBwbGljYXRpb25Qcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2FwcGh1Yi9h
cGl2MS9hcHBodWJwYjthcHBodWJwYqoCFkdvb2dsZS5DbG91ZC5BcHBIdWIuVjHKAhZHb29n
bGVcQ2xvdWRcQXBwSHViXFYx6gIZR29vZ2xlOjpDbG91ZDo6QXBwSHViOjpWMUq+IwoHEgUO
AJoBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgID
ABIDEgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxIDFQAxCgkKAgMEEgMWADEKCQoC
AwUSAxcAKQoICgEIEgMZADMKCQoCCCUSAxkAMwoICgEIEgMaAEkKCQoCCAsSAxoASQoICgEI
EgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADEKCQoCCAgSAxwAMQoICgEIEgMdADMKCQoCCAES
Ax0AMwoICgEIEgMeADMKCQoCCCkSAx4AMwoICgEIEgMfADIKCQoCCC0SAx8AMgrgAQoCBAAS
BCUAbAEa0wEgQXBwbGljYXRpb24gZGVmaW5lcyB0aGUgZ292ZXJuYW5jZSBib3VuZGFyeSBm
b3IgQXBwIEh1YiBlbnRpdGllcyB0aGF0CiBwZXJmb3JtIGEgbG9naWNhbCBlbmQtdG8tZW5k
IGJ1c2luZXNzIGZ1bmN0aW9uLgogQXBwIEh1YiBzdXBwb3J0cyBhcHBsaWNhdGlvbiBsZXZl
bCBJQU0gcGVybWlzc2lvbiB0byBhbGlnbiB3aXRoIGdvdmVybmFuY2UKIHJlcXVpcmVtZW50
cy4KCgoKAwQAARIDJQgTCgsKAwQABxIEJgIrBAoNCgUEAAedCBIEJgIrBAoiCgQEAAQAEgQu
AjoDGhQgQXBwbGljYXRpb24gc3RhdGUuCgoMCgUEAAQAARIDLgcMCiMKBgQABAACABIDMAQa
GhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoOCgcEAAQAAgABEgMwBBUKDgoHBAAEAAIAAhIDMBgZ
CjIKBgQABAACARIDMwQRGiMgVGhlIEFwcGxpY2F0aW9uIGlzIGJlaW5nIGNyZWF0ZWQuCgoO
CgcEAAQAAgEBEgMzBAwKDgoHBAAEAAIBAhIDMw8QCk0KBgQABAACAhIDNgQPGj4gVGhlIEFw
cGxpY2F0aW9uIGlzIHJlYWR5IHRvIHJlZ2lzdGVyIFNlcnZpY2VzIGFuZCBXb3JrbG9hZHMu
CgoOCgcEAAQAAgIBEgM2BAoKDgoHBAAEAAICAhIDNg0OCjIKBgQABAACAxIDOQQRGiMgVGhl
IEFwcGxpY2F0aW9uIGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgMBEgM5BAwKDgoHBAAE
AAIDAhIDOQ8QCpsBCgQEAAIAEgM+Aj0ajQEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5h
bWUgb2YgYW4gQXBwbGljYXRpb24uIEZvcm1hdDoKIGAicHJvamVjdHMve2hvc3QtcHJvamVj
dC1pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwbGljYXRpb25zL3thcHBsaWNhdGlvbi1p
ZH0iYAoKDAoFBAACAAUSAz4CCAoMCgUEAAIAARIDPgkNCgwKBQQAAgADEgM+EBEKDAoFBAAC
AAgSAz4SPAoPCggEAAIACJwIABIDPhM7CmwKBAQAAgESA0ICQxpfIE9wdGlvbmFsLiBVc2Vy
LWRlZmluZWQgbmFtZSBmb3IgdGhlIEFwcGxpY2F0aW9uLgogQ2FuIGhhdmUgYSBtYXhpbXVt
IGxlbmd0aCBvZiA2MyBjaGFyYWN0ZXJzLgoKDAoFBAACAQUSA0ICCAoMCgUEAAIBARIDQgkV
CgwKBQQAAgEDEgNCGBkKDAoFBAACAQgSA0IaQgoPCggEAAIBCJwIABIDQhtBCnMKBAQAAgIS
A0YCQhpmIE9wdGlvbmFsLiBVc2VyLWRlZmluZWQgZGVzY3JpcHRpb24gb2YgYW4gQXBwbGlj
YXRpb24uCiBDYW4gaGF2ZSBhIG1heGltdW0gbGVuZ3RoIG9mIDIwNDggY2hhcmFjdGVycy4K
CgwKBQQAAgIFEgNGAggKDAoFBAACAgESA0YJFAoMCgUEAAICAxIDRhcYCgwKBQQAAgIIEgNG
GUEKDwoIBAACAgicCAASA0YaQAo2CgQEAAIDEgNJAkUaKSBPcHRpb25hbC4gQ29uc3VtZXIg
cHJvdmlkZWQgYXR0cmlidXRlcy4KCgwKBQQAAgMGEgNJAgwKDAoFBAACAwESA0kNFwoMCgUE
AAIDAxIDSRobCgwKBQQAAgMIEgNJHEQKDwoIBAACAwicCAASA0kdQwopCgQEAAIEEgRMAk0y
GhsgT3V0cHV0IG9ubHkuIENyZWF0ZSB0aW1lLgoKDAoFBAACBAYSA0wCGwoMCgUEAAIEARID
TBwnCgwKBQQAAgQDEgNMKisKDAoFBAACBAgSA00GMQoPCggEAAIECJwIABIDTQcwCikKBAQA
AgUSBFACUTIaGyBPdXRwdXQgb25seS4gVXBkYXRlIHRpbWUuCgoMCgUEAAIFBhIDUAIbCgwK
BQQAAgUBEgNQHCcKDAoFBAACBQMSA1AqKwoMCgUEAAIFCBIDUQYxCg8KCAQAAgUInAgAEgNR
BzAKlgEKBAQAAgYSBFUCWAQahwEgUmVxdWlyZWQuIEltbXV0YWJsZS4gRGVmaW5lcyB3aGF0
IGRhdGEgY2FuIGJlIGluY2x1ZGVkIGludG8gdGhpcwogQXBwbGljYXRpb24uIExpbWl0cyB3
aGljaCBTZXJ2aWNlcyBhbmQgV29ya2xvYWRzIGNhbiBiZSByZWdpc3RlcmVkLgoKDAoFBAAC
BgYSA1UCBwoMCgUEAAIGARIDVQgNCgwKBQQAAgYDEgNVEBEKDQoFBAACBggSBFUSWAMKDwoI
BAACBgicCAASA1YEKgoPCggEAAIGCJwIARIDVwQrCmYKBAQAAgcSBFwCXwQaWCBPdXRwdXQg
b25seS4gQSB1bml2ZXJzYWxseSB1bmlxdWUgaWRlbnRpZmllciAoaW4gVVVJRDQgZm9ybWF0
KSBmb3IgdGhlCiBgQXBwbGljYXRpb25gLgoKDAoFBAACBwUSA1wCCAoMCgUEAAIHARIDXAkM
CgwKBQQAAgcDEgNcDxEKDQoFBAACBwgSBFwSXwMKEgoLBAACBwjM8fmKAQESA10EKgoPCggE
AAIHCJwIABIDXgQtCi4KBAQAAggSA2ICPxohIE91dHB1dCBvbmx5LiBBcHBsaWNhdGlvbiBz
dGF0ZS4KCgwKBQQAAggGEgNiAgcKDAoFBAACCAESA2IIDQoMCgUEAAIIAxIDYhASCgwKBQQA
AggIEgNiEz4KDwoIBAACCAicCAASA2IUPQpqCgQEAAIJEgRmAmcyGlwgT3V0cHV0IG9ubHku
IFByb3BlcnRpZXMgb2YgYW4gdW5kZXJseWluZyBjbG91ZCByZXNvdXJjZSB0aGF0IGNhbiBj
b21wcmlzZQogYW4gQXBwbGljYXRpb24uCgoMCgUEAAIJBhIDZgIXCgwKBQQAAgkBEgNmGC4K
DAoFBAACCQMSA2YxMwoMCgUEAAIJCBIDZwYxCg8KCAQAAgkInAgAEgNnBzAKLgoEBAACChIE
agJrMhogIE91dHB1dCBvbmx5LiBBcHBsaWNhdGlvbiB0eXBlLgoKDAoFBAACCgYSA2oCEQoM
CgUEAAIKARIDahIiCgwKBQQAAgoDEgNqJScKDAoFBAACCggSA2sGMQoPCggEAAIKCJwIABID
awcwCh8KAgQBEgRvAHsBGhMgQXBwbGljYXRpb24gdHlwZS4KCgoKAwQBARIDbwgXCiYKBAQB
BAASBHECdwMaGCBBcHBsaWNhdGlvbiB0eXBlIGVudW0uCgoMCgUEAQQAARIDcQcLCiIKBgQB
BAACABIDcwQZGhMgVW5zcGVjaWZpZWQgdHlwZS4KCg4KBwQBBAACAAESA3MEFAoOCgcEAQQA
AgACEgNzFxgKJQoGBAEEAAIBEgN2BBcaFiBBSSBBcHBsaWNhdGlvbiB0eXBlLgoKDgoHBAEE
AAIBARIDdgQSCg4KBwQBBAACAQISA3YVFgorCgQEAQIAEgN6AhAaHiBUaGUgdHlwZSBvZiB0
aGUgYXBwbGljYXRpb24uCgoMCgUEAQIABhIDegIGCgwKBQQBAgABEgN6BwsKDAoFBAECAAMS
A3oODwonCgIEAhIFfgCQAQEaGiBTY29wZSBvZiBhbiBhcHBsaWNhdGlvbi4KCgoKAwQCARID
fggNCh0KBAQCBAASBoABAowBAxoNIFNjb3BlIFR5cGUuCgoNCgUEAgQAARIEgAEHCwojCgYE
AgQAAgASBIIBBBkaEyBVbnNwZWNpZmllZCB0eXBlLgoKDwoHBAIEAAIAARIEggEEFAoPCgcE
AgQAAgACEgSCARcYCiAKBgQCBAACARIEhQEEERoQIFJlZ2lvbmFsIHR5cGUuCgoPCgcEAgQA
AgEBEgSFAQQMCg8KBwQCBAACAQISBIUBDxAKHgoGBAIEAAICEgSIAQQPGg4gR2xvYmFsIHR5
cGUuCgoPCgcEAgQAAgIBEgSIAQQKCg8KBwQCBAACAgISBIgBDQ4KJgoGBAIEAAIDEgSLAQQX
GhYgTXVsdGktcmVnaW9uYWwgdHlwZS4KCg8KBwQCBAACAwESBIsBBBIKDwoHBAIEAAIDAhIE
iwEVFgolCgQEAgIAEgSPAQI5GhcgUmVxdWlyZWQuIFNjb3BlIFR5cGUuCgoNCgUEAgIABhIE
jwECBgoNCgUEAgIAARIEjwEHCwoNCgUEAgIAAxIEjwEODwoNCgUEAgIACBIEjwEQOAoQCggE
AgIACJwIABIEjwERNwo/CgIEAxIGkwEAmgEBGjEgQWRkaXRpb25hbCBzeXN0ZW0gcHJvcGVy
dGllcyBvZiBhbiBBcHBsaWNhdGlvbi4KCgsKAwQDARIEkwEIHQqFAgoEBAMCABIGmAECmQEy
GvQBIE91dHB1dCBvbmx5LiBBZGRpdGlvbmFsIG1ldGFkYXRhIHNwZWNpZmljIHRvIHRoZSBB
cHAgSHViIGFwcGxpY2F0aW9uLgogVGhlIGtleSBpcyBhIHN0cmluZyB0aGF0IGlkZW50aWZp
ZXMgdGhlIHR5cGUgb2YgbWV0YWRhdGEgYW5kIHRoZSB2YWx1ZSBpcwogdGhlIG1ldGFkYXRh
IGNvbnRlbnRzIHNwZWNpZmljIHRvIHRoYXQgdHlwZS4KIEtleSBmb3JtYXQ6IGBhcHBodWIu
Z29vZ2xlYXBpcy5jb20ve21ldGFkYXRhVHlwZX1gCgoNCgUEAwIABhIEmAECHwoNCgUEAwIA
ARIEmAEgMQoNCgUEAwIAAxIEmAE0NQoNCgUEAwIACBIEmQEGMQoQCggEAwIACJwIABIEmQEH
MGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apphub::V1::Application::Application ===
    # Fields for Application
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.apphub.v1.Attributes)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: scope Type: 11 (.google.cloud.apphub.v1.Scope)
    # Field: uid Type: 9 ()
    # Field: state Type: 14 (.google.cloud.apphub.v1.Application.State)
    # Field: application_properties Type: 11 (.google.cloud.apphub.v1.ApplicationProperties)
    # Field: application_type Type: 11 (.google.cloud.apphub.v1.ApplicationType)

# Enum: Application::State
our $Application_STATE_UNSPECIFIED = 0;
our $Application_CREATING = 1;
our $Application_ACTIVE = 2;
our $Application_DELETING = 3;

# === Message: Google::Cloud::Apphub::V1::Application::ApplicationType ===
    # Fields for ApplicationType
    # Field: type Type: 14 (.google.cloud.apphub.v1.ApplicationType.Type)

# Enum: ApplicationType::Type
our $ApplicationType_TYPE_UNSPECIFIED = 0;
our $ApplicationType_AI_APPLICATION = 1;

# === Message: Google::Cloud::Apphub::V1::Application::Scope ===
    # Fields for Scope
    # Field: type Type: 14 (.google.cloud.apphub.v1.Scope.Type)

# Enum: Scope::Type
our $Scope_TYPE_UNSPECIFIED = 0;
our $Scope_REGIONAL = 1;
our $Scope_GLOBAL = 2;
our $Scope_MULTI_REGIONAL = 3;

# === Message: Google::Cloud::Apphub::V1::Application::ApplicationProperties ===
    # Fields for ApplicationProperties
    # Field: extended_metadata Type: 11 (.google.cloud.apphub.v1.ApplicationProperties.ExtendedMetadataEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apphub::V1::Application - Compiled Protocol Buffers messages for google/cloud/apphub/v1/application.proto

=head1 SYNOPSIS

    use Google::Cloud::Apphub::V1::Application;

    my $msg = Google::Cloud::Apphub::V1::Application::Application->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        attributes => $attributes,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apphub::V1::Application::Application->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apphub/v1/application.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apphub::V1::Application::Application

Application defines the governance boundary for App Hub entities that
perform a logical end-to-end business function.
App Hub supports application level IAM permission to align with governance
requirements.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of an Application. Format:
`"projects/{host-project-id}/locations/{location}/applications/{application-id}"`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User-defined name for the Application.
Can have a maximum length of 63 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-defined description of an Application.
Can have a maximum length of 2048 characters.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::Attributes>)

Optional. Consumer provided attributes.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Application::Scope>)

Required. Immutable. Defines what data can be included into this
Application. Limits which Services and Workloads can be registered.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A universally unique identifier (in UUID4 format) for the
`Application`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::Application::State>)

Output only. Application state.

=item * C<< $msg->application_properties() >> / C<< $msg->application_properties($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Application::ApplicationProperties>)

Output only. Properties of an underlying cloud resource that can comprise
an Application.

=item * C<< $msg->application_type() >> / C<< $msg->application_type($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Application::ApplicationType>)

Output only. Application type.

=back

=head3 Enum: Application::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=back

=head2 Google::Cloud::Apphub::V1::Application::ApplicationType

Application type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::ApplicationType::Type>)

The type of the application.

=back

=head3 Enum: ApplicationType::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<AI_APPLICATION> => C<1>

=back

=head2 Google::Cloud::Apphub::V1::Application::Scope

Scope of an application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::Scope::Type>)

Required. Scope Type.

=back

=head3 Enum: Scope::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<REGIONAL> => C<1>

=item * C<GLOBAL> => C<2>

=item * C<MULTI_REGIONAL> => C<3>

=back

=head2 Google::Cloud::Apphub::V1::Application::ApplicationProperties

Additional system properties of an Application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->extended_metadata() >> / C<< $msg->extended_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Application::ApplicationProperties::ExtendedMetadataEntry>)

Output only. Additional metadata specific to the App Hub application.
The key is a string that identifies the type of metadata and the value is
the metadata contents specific to that type.
Key format: `apphub.googleapis.com/{metadataType}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apphub::V1::Application::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
