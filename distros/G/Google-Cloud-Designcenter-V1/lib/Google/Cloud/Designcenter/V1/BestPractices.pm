package Google::Cloud::Designcenter::V1::BestPractices;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Designcenter::V1::Assessment };
    eval { require Google::Cloud::Designcenter::V1::Parameters };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2Jlc3RfcHJhY3RpY2VzLnByb3RvEhxn
b29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQvZGVzaWdu
Y2VudGVyL3YxL2Fzc2Vzc21lbnQucHJvdG8aLWdvb2dsZS9jbG91ZC9kZXNpZ25jZW50ZXIv
djEvcGFyYW1ldGVycy5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKk
BAoQQXNzZXNzbWVudFJlcG9ydBI1ChNhZGNfYXBwbGljYXRpb25fdXJpGAEgASgJQgPgQQNI
AFIRYWRjQXBwbGljYXRpb25VcmkSRgocYWRjX2FwcGxpY2F0aW9uX3RlbXBsYXRlX3VyaRgC
IAEoCUID4EEDSABSGWFkY0FwcGxpY2F0aW9uVGVtcGxhdGVVcmkSPgoYYWRjX2NhdGFsb2df
dGVtcGxhdGVfdXJpGAMgASgJQgPgQQNIAFIVYWRjQ2F0YWxvZ1RlbXBsYXRlVXJpEikKDWFk
Y19zcGFjZV91cmkYBCABKAlCA+BBA0gAUgthZGNTcGFjZVVyaRJ1Chlkb21haW5fYXNzZXNz
bWVudF9yZXBvcnRzGAUgAygLMjQuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5Eb21h
aW5Bc3Nlc3NtZW50UmVwb3J0QgPgQQNSF2RvbWFpbkFzc2Vzc21lbnRSZXBvcnRzElkKD3Nr
aXBwZWRfZG9tYWlucxgGIAMoCzIrLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEuU2tp
cHBlZERvbWFpbkID4EEDUg5za2lwcGVkRG9tYWlucxJACgtjcmVhdGVfdGltZRgHIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZUISChBhZGNfcmVz
b3VyY2VfdXJpIvMGCgZQb2xpY3kSJAoKcG9saWN5X3VyaRgFIAEoCUID4EEBSABSCXBvbGlj
eVVyaRI1ChNwb2xpY3lfcmV2aXNpb25fdXJpGAYgASgJQgPgQQFIAFIRcG9saWN5UmV2aXNp
b25VcmkSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID
4EEBUgtkaXNwbGF5TmFtZRIlCgtkZXNjcmlwdGlvbhgDIAEoCUID4EEBUgtkZXNjcmlwdGlv
bhJVCgtwb2xpY3lfdHlwZRgEIAEoDjIvLmdvb2dsZS5jbG91ZC5kZXNpZ25jZW50ZXIudjEu
UG9saWN5LlBvbGljeVR5cGVCA+BBAlIKcG9saWN5VHlwZRJcChBhcHBseV9jb25kaXRpb25z
GAcgAygLMiwuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5BcHBseUNvbmRpdGlvbkID
4EEBUg9hcHBseUNvbmRpdGlvbnMSQAoLY3JlYXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCSABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSbAoVY2xvdWRf
Y29udHJvbF9jb25maWdzGAogAygLMjAuZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MS5D
bG91ZENvbnRyb2xDb25maWdCBuBBBOBBAVITY2xvdWRDb250cm9sQ29uZmlncyJDCgpQb2xp
Y3lUeXBlEhsKF1BPTElDWV9UWVBFX1VOU1BFQ0lGSUVEEAASGAoUQ09NUExJQU5DRV9GUkFN
RVdPUksQATqwAepBrAEKImRlc2lnbmNlbnRlci5nb29nbGVhcGlzLmNvbS9Qb2xpY3kSdHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zcGFjZXMve3NwYWNlfS9h
cHBsaWNhdGlvblRlbXBsYXRlcy97YXBwbGljYXRpb25fdGVtcGxhdGV9L3BvbGljaWVzL3tw
b2xpY3l9Kghwb2xpY2llczIGcG9saWN5QgUKA3VyaULnAQogY29tLmdvb2dsZS5jbG91ZC5k
ZXNpZ25jZW50ZXIudjFCG0Jlc3RQcmFjdGljZXNSZXNvdXJjZXNQcm90b1ABWkRjbG91ZC5n
b29nbGUuY29tL2dvL2Rlc2lnbmNlbnRlci9hcGl2MS9kZXNpZ25jZW50ZXJwYjtkZXNpZ25j
ZW50ZXJwYqoCHEdvb2dsZS5DbG91ZC5EZXNpZ25DZW50ZXIuVjHKAhxHb29nbGVcQ2xvdWRc
RGVzaWduQ2VudGVyXFYx6gIfR29vZ2xlOjpDbG91ZDo6RGVzaWduQ2VudGVyOjpWMUrbIgoH
EgUOAIUBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQANwoJCgIDAxIDFQA3CgkKAgMEEgMWACkK
CAoBCBIDGAA5CgkKAgglEgMYADkKCAoBCBIDGQBbCgkKAggLEgMZAFsKCAoBCBIDGgAiCgkK
AggKEgMaACIKCAoBCBIDGwA8CgkKAggIEgMbADwKCAoBCBIDHAA5CgkKAggBEgMcADkKCAoB
CBIDHQA5CgkKAggpEgMdADkKCAoBCBIDHgA4CgkKAggtEgMeADgKPAoCBAASBCEAPgEaMCBB
Z2dyZWdhdGVkIGFzc2Vzc21lbnQgcmVwb3J0IGZyb20gYWxsIGRvbWFpbnMuCgoKCgMEAAES
AyEIGAo0CgQEAAgAEgQjAjEDGiYgUmVzb3VyY2UgYXNzb2NpYXRlZCB3aXRoIHRoZSByZXBv
cnQuCgoMCgUEAAgAARIDIwgYCiwKBAQAAgASAyUETxofIE91dHB1dCBvbmx5LiBBcHBsaWNh
dGlvbiBVUkkuCgoMCgUEAAIABRIDJQQKCgwKBQQAAgABEgMlCx4KDAoFBAACAAMSAyUhIgoM
CgUEAAIACBIDJSNOCg8KCAQAAgAInAgAEgMlJE0KNgoEBAACARIEKAQpNBooIE91dHB1dCBv
bmx5LiBBcHBsaWNhdGlvbiBUZW1wbGF0ZSBVUkkuCgoMCgUEAAIBBRIDKAQKCgwKBQQAAgEB
EgMoCycKDAoFBAACAQMSAygqKwoMCgUEAAIBCBIDKQgzCg8KCAQAAgEInAgAEgMpCTIKMgoE
BAACAhIELAQtNBokIE91dHB1dCBvbmx5LiBDYXRhbG9nIFRlbXBsYXRlIFVSSS4KCgwKBQQA
AgIFEgMsBAoKDAoFBAACAgESAywLIwoMCgUEAAICAxIDLCYnCgwKBQQAAgIIEgMtCDMKDwoI
BAACAgicCAASAy0JMgomCgQEAAIDEgMwBEkaGSBPdXRwdXQgb25seS4gU3BhY2UgVVJJLgoK
DAoFBAACAwUSAzAECgoMCgUEAAIDARIDMAsYCgwKBQQAAgMDEgMwGxwKDAoFBAACAwgSAzAd
SAoPCggEAAIDCJwIABIDMB5HCj0KBAQAAgQSBDQCNTIaLyBPdXRwdXQgb25seS4gR2VuZXJh
dGVkIGJlc3QgcHJhY3RpY2UgcmVwb3J0cy4KCgwKBQQAAgQEEgM0AgoKDAoFBAACBAYSAzQL
IQoMCgUEAAIEARIDNCI7CgwKBQQAAgQDEgM0Pj8KDAoFBAACBAgSAzUGMQoPCggEAAIECJwI
ABIDNQcwCi0KBAQAAgUSBDgCOTIaHyBPdXRwdXQgb25seS4gU2tpcHBlZCBkb21haW5zLgoK
DAoFBAACBQQSAzgCCgoMCgUEAAIFBhIDOAsYCgwKBQQAAgUBEgM4GSgKDAoFBAACBQMSAzgr
LAoMCgUEAAIFCBIDOQYxCg8KCAQAAgUInAgAEgM5BzAKRgoEBAACBhIEPAI9Mho4IE91dHB1
dCBvbmx5LiBUaGUgdGltZSBhdCB3aGljaCB0aGUgcmVwb3J0IHdhcyBjcmVhdGVkLgoKDAoF
BAACBgYSAzwCGwoMCgUEAAIGARIDPBwnCgwKBQQAAgYDEgM8KisKDAoFBAACBggSAz0GMQoP
CggEAAIGCJwIABIDPQcwCrsBCgIEARIFQwCFAQEarQEgQSBQb2xpY3kgaXMgYSByZXNvdXJj
ZSB3aXRoaW4gYW4gQXBwbGljYXRpb24gVGVtcGxhdGUgdGhhdCByZWZlcnMgdG8gYSBQb2xp
Y3kKIHRoYXQgeW91IGF1dGhvciBvdXRzaWRlIG9mIEFwcGxpY2F0aW9uIERlc2lnbiBDZW50
ZXIgYW5kIGF0dGFjaCB0byBhbgogYXBwbGljYXRpb24gdGVtcGxhdGUuCgoKCgMEAQESA0MI
DgoLCgMEAQcSBEQCSQQKDQoFBAEHnQgSBEQCSQQKIAoEBAEEABIETAJSAxoSIFRoZSBwb2xp
Y3kgdHlwZS4KCgwKBQQBBAABEgNMBxEKGQoGBAEEAAIAEgNOBCAaCiBEZWZhdWx0LgoKDgoH
BAEEAAIAARIDTgQbCg4KBwQBBAACAAISA04eHwotCgYEAQQAAgESA1EEHRoeIENvbXBsaWFu
Y2UgZnJhbWV3b3JrIHBvbGljeS4KCg4KBwQBBAACAQESA1EEGAoOCgcEAQQAAgECEgNRGxwK
OQoEBAEIABIEVQJbAxorIFVSSSBvZiB0aGUgcG9saWN5IG9yIHRoZSBwb2xpY3kgcmV2aXNp
b24uCgoMCgUEAQgAARIDVQgLCisKBAQBAgASA1cEQxoeIE9wdGlvbmFsLiBVUkkgb2YgdGhl
IHBvbGljeS4KCgwKBQQBAgAFEgNXBAoKDAoFBAECAAESA1cLFQoMCgUEAQIAAxIDVxgZCgwK
BQQBAgAIEgNXGkIKDwoIBAECAAicCAASA1cbQQo0CgQEAQIBEgNaBEwaJyBPcHRpb25hbC4g
VVJJIG9mIHRoZSBwb2xpY3kgcmV2aXNpb24uCgoMCgUEAQIBBRIDWgQKCgwKBQQBAgEBEgNa
Cx4KDAoFBAECAQMSA1ohIgoMCgUEAQIBCBIDWiNLCg8KCAQBAgEInAgAEgNaJEoKtgEKBAQB
AgISA18CPRqoASBJZGVudGlmaWVyLiBUaGUgcG9saWN5IG5hbWUgaW4gdGhlIGZvbGxvd2lu
ZyBmb3JtYXQ6CiBgcHJvamVjdHMvJHByb2plY3QvbG9jYXRpb25zLyRsb2NhdGlvbi9zcGFj
ZXMvJHNwYWNlL2FwcGxpY2F0aW9uVGVtcGxhdGVzLyRhcHBsaWNhdGlvblRlbXBsYXRlL3Bv
bGljaWVzLyRwb2xpY3lgCgoMCgUEAQICBRIDXwIICgwKBQQBAgIBEgNfCQ0KDAoFBAECAgMS
A18QEQoMCgUEAQICCBIDXxI8Cg8KCAQBAgIInAgAEgNfEzsKMQoEBAECAxIDYgJDGiQgT3B0
aW9uYWwuIFRoZSBwb2xpY3kgZGlzcGxheSBuYW1lLgoKDAoFBAECAwUSA2ICCAoMCgUEAQID
ARIDYgkVCgwKBQQBAgMDEgNiGBkKDAoFBAECAwgSA2IaQgoPCggEAQIDCJwIABIDYhtBCjAK
BAQBAgQSA2UCQhojIE9wdGlvbmFsLiBUaGUgcG9saWN5IGRlc2NyaXB0aW9uLgoKDAoFBAEC
BAUSA2UCCAoMCgUEAQIEARIDZQkUCgwKBQQBAgQDEgNlFxgKDAoFBAECBAgSA2UZQQoPCggE
AQIECJwIABIDZRpACmUKBAQBAgUSA2kCRhpYIFJlcXVpcmVkLiBUaGUgcG9saWN5IHR5cGUu
CiBQb2xpY3kgdHlwZSBpcyB1c2VkIHRvIGRldGVybWluZSB0aGUgZG9tYWluIG9mIHRoZSBw
b2xpY3kuCgoMCgUEAQIFBhIDaQIMCgwKBQQBAgUBEgNpDRgKDAoFBAECBQMSA2kbHAoMCgUE
AQIFCBIDaR1FCg8KCAQBAgUInAgAEgNpHkQKnwEKBAQBAgYSBG0Cbi8akAEgT3B0aW9uYWwu
IENvbmRpdGlvbnMgZm9yIGFwcGx5aW5nIHRoZSBwb2xpY3kuIENvbmRpdGlvbiBhY2NlcHRz
IHRoZQogYGNyaXRpY2FsaXR5YCBhbmQgYGVudmlyb25tZW50YCBwYXJhbWV0ZXJzIGZyb20g
dGhlIGFwcGxpY2F0aW9uIHRlbXBsYXRlLgoKDAoFBAECBgQSA20CCgoMCgUEAQIGBhIDbQsZ
CgwKBQQBAgYBEgNtGioKDAoFBAECBgMSA20tLgoMCgUEAQIGCBIDbgYuCg8KCAQBAgYInAgA
EgNuBy0KOwoEBAECBxIEcQJyMhotIE91dHB1dCBvbmx5LiBUaGUgcG9saWN5IGNyZWF0aW9u
IHRpbWVzdGFtcC4KCgwKBQQBAgcGEgNxAhsKDAoFBAECBwESA3EcJwoMCgUEAQIHAxIDcSor
CgwKBQQBAgcIEgNyBjEKDwoIBAECBwicCAASA3IHMAo5CgQEAQIIEgR1AnYyGisgT3V0cHV0
IG9ubHkuIFRoZSBwb2xpY3kgdXBkYXRlIHRpbWVzdGFtcC4KCgwKBQQBAggGEgN1AhsKDAoF
BAECCAESA3UcJwoMCgUEAQIIAxIDdSorCgwKBQQBAggIEgN2BjEKDwoIBAECCAicCAASA3YH
MAqgBAoEBAECCRIGgQEChAEEGo8EIE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBQYXJhbWV0ZXIg
dmFsdWVzIGZvciB0aGUgY2xvdWQgY29udHJvbHMgb2YgdGhlCiBwb2xpY3kncyBmcmFtZXdv
cmssIGdyb3VwZWQgYnkgY2xvdWQgY29udHJvbC4gT25seSBob25vcmVkIHdoZW4gZnJhbWV3
b3JrCiBwYXJhbWV0ZXIgc3VwcG9ydCBpcyBlbmFibGVkIGZvciB0aGUgcHJvamVjdDsgaWdu
b3JlZCBvdGhlcndpc2UuCgogVGhlIHZhbHVlcyBhcmUgc2F2ZWQgd2l0aCB0aGUgYXBwbGlj
YXRpb24gdGVtcGxhdGUgYW5kIGFyZSBub3QgcmV0dXJuZWQgb24KIHRoZSBwb2xpY3kuIE9u
IHVwZGF0ZSwgdGhleSByZXBsYWNlIHRoZSBzYXZlZCB2YWx1ZXMuIElmIHRoZXkgYXJlIGVt
cHR5LAogdGhlIHNhdmVkIHZhbHVlcyBhcmUgY2xlYXJlZCBpZiBgY2xvdWRfY29udHJvbF9j
b25maWdzYCBpcyBuYW1lZCBpbiB0aGUKIHVwZGF0ZSBtYXNrLiBPdGhlcndpc2UsIHRoZSBz
YXZlZCB2YWx1ZXMgYXJlIGtlcHQsIHVubGVzcyB0aGUgcG9saWN5J3MKIGZyYW1ld29yayBj
aGFuZ2VzLgoKDQoFBAECCQQSBIEBAgoKDQoFBAECCQYSBIEBCx0KDQoFBAECCQESBIEBHjMK
DQoFBAECCQMSBIEBNjgKDwoFBAECCQgSBoEBOYQBAwoQCggEAQIJCJwIABIEggEELAoQCggE
AQIJCJwIARIEgwEEKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport ===
    # Fields for AssessmentReport
    # Field: adc_application_uri Type: 9 ()
    # Field: adc_application_template_uri Type: 9 ()
    # Field: adc_catalog_template_uri Type: 9 ()
    # Field: adc_space_uri Type: 9 ()
    # Field: domain_assessment_reports Type: 11 (.google.cloud.designcenter.v1.DomainAssessmentReport)
    # Field: skipped_domains Type: 11 (.google.cloud.designcenter.v1.SkippedDomain)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Designcenter::V1::BestPractices::Policy ===
    # Fields for Policy
    # Field: policy_uri Type: 9 ()
    # Field: policy_revision_uri Type: 9 ()
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: policy_type Type: 14 (.google.cloud.designcenter.v1.Policy.PolicyType)
    # Field: apply_conditions Type: 11 (.google.cloud.designcenter.v1.ApplyCondition)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: cloud_control_configs Type: 11 (.google.cloud.designcenter.v1.CloudControlConfig)

# Enum: Policy::PolicyType
our $Policy_POLICY_TYPE_UNSPECIFIED = 0;
our $Policy_COMPLIANCE_FRAMEWORK = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::BestPractices - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/best_practices.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::BestPractices;

    my $msg = Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport->new({
        adc_application_uri => $adc_application_uri,
        adc_application_template_uri => $adc_application_template_uri,
        adc_catalog_template_uri => $adc_catalog_template_uri,
        adc_space_uri => $adc_space_uri,
    });

    # Read or update a field
    my $val = $msg->adc_application_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/best_practices.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::BestPractices::AssessmentReport

Aggregated assessment report from all domains.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->adc_application_uri() >> / C<< $msg->adc_application_uri($value) >>

Type: C<String>

Output only. Application URI.

=item * C<< $msg->adc_application_template_uri() >> / C<< $msg->adc_application_template_uri($value) >>

Type: C<String>

Output only. Application Template URI.

=item * C<< $msg->adc_catalog_template_uri() >> / C<< $msg->adc_catalog_template_uri($value) >>

Type: C<String>

Output only. Catalog Template URI.

=item * C<< $msg->adc_space_uri() >> / C<< $msg->adc_space_uri($value) >>

Type: C<String>

Output only. Space URI.

=item * C<< $msg->domain_assessment_reports() >> / C<< $msg->domain_assessment_reports($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Assessment::DomainAssessmentReport>)

Output only. Generated best practice reports.

=item * C<< $msg->skipped_domains() >> / C<< $msg->skipped_domains($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Assessment::SkippedDomain>)

Output only. Skipped domains.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the report was created.

=back

=head2 Google::Cloud::Designcenter::V1::BestPractices::Policy

A Policy is a resource within an Application Template that refers to a Policy
that you author outside of Application Design Center and attach to an
application template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_uri() >> / C<< $msg->policy_uri($value) >>

Type: C<String>

Optional. URI of the policy.

=item * C<< $msg->policy_revision_uri() >> / C<< $msg->policy_revision_uri($value) >>

Type: C<String>

Optional. URI of the policy revision.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The policy name in the following format:
`projects/$project/locations/$location/spaces/$space/applicationTemplates/$applicationTemplate/policies/$policy`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The policy display name.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The policy description.

=item * C<< $msg->policy_type() >> / C<< $msg->policy_type($value) >>

Type: C<Enum> (L<Google::Cloud::Designcenter::V1::Policy::PolicyType>)

Required. The policy type.
Policy type is used to determine the domain of the policy.

=item * C<< $msg->apply_conditions() >> / C<< $msg->apply_conditions($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Assessment::ApplyCondition>)

Optional. Conditions for applying the policy. Condition accepts the
`criticality` and `environment` parameters from the application template.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The policy creation timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The policy update timestamp.

=item * C<< $msg->cloud_control_configs() >> / C<< $msg->cloud_control_configs($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::Parameters::CloudControlConfig>)

Optional. Input only. Parameter values for the cloud controls of the
policy's framework, grouped by cloud control. Only honored when framework
parameter support is enabled for the project; ignored otherwise.

The values are saved with the application template and are not returned on
the policy. On update, they replace the saved values. If they are empty,
the saved values are cleared if `cloud_control_configs` is named in the
update mask. Otherwise, the saved values are kept, unless the policy's
framework changes.

=back

=head3 Enum: Policy::PolicyType

=over 4

=item * C<POLICY_TYPE_UNSPECIFIED> => C<0>

=item * C<COMPLIANCE_FRAMEWORK> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::BestPractices::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
