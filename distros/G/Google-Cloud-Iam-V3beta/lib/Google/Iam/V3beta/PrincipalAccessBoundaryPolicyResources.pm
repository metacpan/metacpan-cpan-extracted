package Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvaWFtL3YzYmV0YS9wcmluY2lwYWxfYWNjZXNzX2JvdW5kYXJ5X3BvbGljeV9y
ZXNvdXJjZXMucHJvdG8SEWdvb2dsZS5pYW0udjNiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ijQYKHVBy
aW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRId
CgN1aWQYAiABKAlCC+KMz9cIAggB4EEDUgN1aWQSFwoEZXRhZxgDIAEoCUID4EEBUgRldGFn
EiYKDGRpc3BsYXlfbmFtZRgEIAEoCUID4EEBUgtkaXNwbGF5TmFtZRJoCgthbm5vdGF0aW9u
cxgFIAMoCzJBLmdvb2dsZS5pYW0udjNiZXRhLlByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9s
aWN5LkFubm90YXRpb25zRW50cnlCA+BBAVILYW5ub3RhdGlvbnMSQAoLY3JlYXRlX3RpbWUY
BiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoL
dXBkYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVw
ZGF0ZVRpbWUSVgoHZGV0YWlscxgIIAEoCzI3Lmdvb2dsZS5pYW0udjNiZXRhLlByaW5jaXBh
bEFjY2Vzc0JvdW5kYXJ5UG9saWN5RGV0YWlsc0ID4EEBUgdkZXRhaWxzGj4KEEFubm90YXRp
b25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATrs
AepB6AEKMGlhbS5nb29nbGVhcGlzLmNvbS9QcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGlj
eRJ0b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9w
cmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzL3twcmluY2lwYWxfYWNjZXNzX2JvdW5k
YXJ5X3BvbGljeX0qH3ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWNpZXMyHXByaW5jaXBh
bEFjY2Vzc0JvdW5kYXJ5UG9saWN5Iq0BCiRQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGlj
eURldGFpbHMSTwoFcnVsZXMYASADKAsyNC5nb29nbGUuaWFtLnYzYmV0YS5QcmluY2lwYWxB
Y2Nlc3NCb3VuZGFyeVBvbGljeVJ1bGVCA+BBAlIFcnVsZXMSNAoTZW5mb3JjZW1lbnRfdmVy
c2lvbhgEIAEoCUID4EEBUhJlbmZvcmNlbWVudFZlcnNpb24i9AEKIVByaW5jaXBhbEFjY2Vz
c0JvdW5kYXJ5UG9saWN5UnVsZRIlCgtkZXNjcmlwdGlvbhgBIAEoCUID4EEBUgtkZXNjcmlw
dGlvbhIhCglyZXNvdXJjZXMYAiADKAlCA+BBAlIJcmVzb3VyY2VzElgKBmVmZmVjdBgDIAEo
DjI7Lmdvb2dsZS5pYW0udjNiZXRhLlByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UnVs
ZS5FZmZlY3RCA+BBAlIGZWZmZWN0IisKBkVmZmVjdBIWChJFRkZFQ1RfVU5TUEVDSUZJRUQQ
ABIJCgVBTExPVxABQqkBChVjb20uZ29vZ2xlLmlhbS52M2JldGFCK1ByaW5jaXBhbEFjY2Vz
c0JvdW5kYXJ5UG9saWN5UmVzb3VyY2VzUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9p
YW0vYXBpdjNiZXRhL2lhbXBiO2lhbXBiqgIXR29vZ2xlLkNsb3VkLklhbS5WM0JldGHKAhdH
b29nbGVcQ2xvdWRcSWFtXFYzYmV0YUq3IwoGEgQOAH8BCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAaCgkKAgMAEgMSACkKCQoCAwESAxMAJQoJCgIDAhID
FAAjCgkKAgMDEgMVACkKCAoBCBIDFwA0CgkKAgglEgMXADQKCAoBCBIDGABECgkKAggLEgMY
AEQKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgBMCgkKAggIEgMaAEwKCAoBCBIDGwAu
CgkKAggBEgMbAC4KCAoBCBIDHAA0CgkKAggpEgMcADQKPwoCBAASBB8ATgEaMyBBbiBJQU0g
cHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3kgcmVzb3VyY2UuCgoKCgMEAAESAx8I
JQoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQK3wEKBAQAAgASAysCPRrRASBJZGVudGlm
aWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFy
eSBwb2xpY3kuCgogVGhlIGZvbGxvd2luZyBmb3JtYXQgaXMgc3VwcG9ydGVkOgogYG9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJpbmNp
cGFsQWNjZXNzQm91bmRhcnlQb2xpY2llcy97cG9saWN5X2lkfWAKCgwKBQQAAgAFEgMrAggK
DAoFBAACAAESAysJDQoMCgUEAAIAAxIDKxARCgwKBQQAAgAIEgMrEjwKDwoIBAACAAicCAAS
AysTOwpdCgQEAAIBEgQvAjIEGk8gT3V0cHV0IG9ubHkuIFRoZSBnbG9iYWxseSB1bmlxdWUg
SUQgb2YgdGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkKIHBvbGljeS4KCgwKBQQAAgEF
EgMvAggKDAoFBAACAQESAy8JDAoMCgUEAAIBAxIDLw8QCg0KBQQAAgEIEgQvETIDChIKCwQA
AgEIzPH5igEBEgMwBCoKDwoIBAACAQicCAASAzEELQqFAQoEBAACAhIDNgI7GnggT3B0aW9u
YWwuIFRoZSBldGFnIGZvciB0aGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeS4KIElmIHRo
aXMgaXMgcHJvdmlkZWQgb24gdXBkYXRlLCBpdCBtdXN0IG1hdGNoIHRoZSBzZXJ2ZXIncyBl
dGFnLgoKDAoFBAACAgUSAzYCCAoMCgUEAAICARIDNgkNCgwKBQQAAgIDEgM2EBEKDAoFBAAC
AggSAzYSOgoPCggEAAICCJwIABIDNhM5Cn8KBAQAAgMSAzoCQxpyIE9wdGlvbmFsLiBUaGUg
ZGVzY3JpcHRpb24gb2YgdGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5LiBN
dXN0IGJlCiBsZXNzIHRoYW4gb3IgZXF1YWwgdG8gNjMgY2hhcmFjdGVycy4KCgwKBQQAAgMF
EgM6AggKDAoFBAACAwESAzoJFQoMCgUEAAIDAxIDOhgZCgwKBQQAAgMIEgM6GkIKDwoIBAAC
AwicCAASAzobQQqVAQoEBAACBBIDPwJPGocBIE9wdGlvbmFsLiBVc2VyIGRlZmluZWQgYW5u
b3RhdGlvbnMuIFNlZQogaHR0cHM6Ly9nb29nbGUuYWlwLmRldi8xNDgjYW5ub3RhdGlvbnMg
Zm9yIG1vcmUgZGV0YWlscyBzdWNoIGFzIGZvcm1hdCBhbmQKIHNpemUgbGltaXRhdGlvbnMK
CgwKBQQAAgQGEgM/AhUKDAoFBAACBAESAz8WIQoMCgUEAAIEAxIDPyQlCgwKBQQAAgQIEgM/
Jk4KDwoIBAACBAicCAASAz8nTQpdCgQEAAIFEgRDAkQyGk8gT3V0cHV0IG9ubHkuIFRoZSB0
aW1lIHdoZW4gdGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5IHdhcwogY3Jl
YXRlZC4KCgwKBQQAAgUGEgNDAhsKDAoFBAACBQESA0McJwoMCgUEAAIFAxIDQyorCgwKBQQA
AgUIEgNEBjEKDwoIBAACBQicCAASA0QHMAprCgQEAAIGEgRIAkkyGl0gT3V0cHV0IG9ubHku
IFRoZSB0aW1lIHdoZW4gdGhlIHByaW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5IHdh
cyBtb3N0CiByZWNlbnRseSB1cGRhdGVkLgoKDAoFBAACBgYSA0gCGwoMCgUEAAIGARIDSBwn
CgwKBQQAAgYDEgNIKisKDAoFBAACBggSA0kGMQoPCggEAAIGCJwIABIDSQcwCk8KBAQAAgcS
BEwCTS8aQSBPcHRpb25hbC4gVGhlIGRldGFpbHMgZm9yIHRoZSBwcmluY2lwYWwgYWNjZXNz
IGJvdW5kYXJ5IHBvbGljeS4KCgwKBQQAAgcGEgNMAiYKDAoFBAACBwESA0wnLgoMCgUEAAIH
AxIDTDEyCgwKBQQAAgcIEgNNBi4KDwoIBAACBwicCAASA00HLQo2CgIEARIEUQBdARoqIFBy
aW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5IGRldGFpbHMKCgoKAwQBARIDUQgsCn8K
BAQBAgASBFQCVS8acSBSZXF1aXJlZC4gQSBsaXN0IG9mIHByaW5jaXBhbCBhY2Nlc3MgYm91
bmRhcnkgcG9saWN5IHJ1bGVzLiBUaGUgbnVtYmVyIG9mCiBydWxlcyBpbiBhIHBvbGljeSBp
cyBsaW1pdGVkIHRvIDUwMC4KCgwKBQQBAgAEEgNUAgoKDAoFBAECAAYSA1QLLAoMCgUEAQIA
ARIDVC0yCgwKBQQBAgADEgNUNTYKDAoFBAECAAgSA1UGLgoPCggEAQIACJwIABIDVQctCosC
CgQEAQIBEgNcAkoa/QEgT3B0aW9uYWwuCiBUaGUgdmVyc2lvbiBudW1iZXIgKGZvciBleGFt
cGxlLCBgMWAgb3IgYGxhdGVzdGApIHRoYXQgaW5kaWNhdGVzIHdoaWNoCiBwZXJtaXNzaW9u
cyBhcmUgYWJsZSB0byBiZSBibG9ja2VkIGJ5IHRoZSBwb2xpY3kuIElmIGVtcHR5LCB0aGUg
UEFCIHBvbGljeQogdmVyc2lvbiB3aWxsIGJlIHNldCB0byB0aGUgbW9zdCByZWNlbnQgdmVy
c2lvbiBudW1iZXIgYXQgdGhlIHRpbWUgb2YgdGhlCiBwb2xpY3kncyBjcmVhdGlvbi4KCgwK
BQQBAgEFEgNcAggKDAoFBAECAQESA1wJHAoMCgUEAQIBAxIDXB8gCgwKBQQBAgEIEgNcIUkK
DwoIBAECAQicCAASA1wiSApXCgIEAhIEYAB/ARpLIFByaW5jaXBhbCBhY2Nlc3MgYm91bmRh
cnkgcG9saWN5IHJ1bGUgdGhhdCBkZWZpbmVzIHRoZSByZXNvdXJjZSBib3VuZGFyeS4KCgoK
AwQCARIDYAgpCj4KBAQCBAASBGICaAMaMCBBbiBlZmZlY3QgdG8gZGVzY3JpYmUgdGhlIGFj
Y2VzcyByZWxhdGlvbnNoaXAuCgoMCgUEAgQAARIDYgcNCiQKBgQCBAACABIDZAQbGhUgRWZm
ZWN0IHVuc3BlY2lmaWVkLgoKDgoHBAIEAAIAARIDZAQWCg4KBwQCBAACAAISA2QZGgo9CgYE
AgQAAgESA2cEDhouIEFsbG93cyBhY2Nlc3MgdG8gdGhlIHJlc291cmNlcyBpbiB0aGlzIHJ1
bGUuCgoOCgcEAgQAAgEBEgNnBAkKDgoHBAIEAAIBAhIDZwwNCoUBCgQEAgIAEgNsAkIaeCBP
cHRpb25hbC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBwcmluY2lwYWwgYWNjZXNzIGJvdW5k
YXJ5IHBvbGljeSBydWxlLgogTXVzdCBiZSBsZXNzIHRoYW4gb3IgZXF1YWwgdG8gMjU2IGNo
YXJhY3RlcnMuCgoMCgUEAgIABRIDbAIICgwKBQQCAgABEgNsCRQKDAoFBAICAAMSA2wXGAoM
CgUEAgIACBIDbBlBCg8KCAQCAgAInAgAEgNsGkAK2AQKBAQCAgESA3oCSRrKBCBSZXF1aXJl
ZC4gQSBsaXN0IG9mIFJlc291cmNlIE1hbmFnZXIgcmVzb3VyY2VzLiBJZiBhIHJlc291cmNl
IGlzIGxpc3RlZCBpbgogdGhlIHJ1bGUsIHRoZW4gdGhlIHJ1bGUgYXBwbGllcyBmb3IgdGhh
dCByZXNvdXJjZSBhbmQgaXRzIGRlc2NlbmRhbnRzLiBUaGUKIG51bWJlciBvZiByZXNvdXJj
ZXMgaW4gYSBwb2xpY3kgaXMgbGltaXRlZCB0byA1MDAgYWNyb3NzIGFsbCBydWxlcyBpbiB0
aGUKIHBvbGljeS4KCiBUaGUgZm9sbG93aW5nIHJlc291cmNlIHR5cGVzIGFyZSBzdXBwb3J0
ZWQ6CgogKiBPcmdhbml6YXRpb25zLCBzdWNoIGFzCiBgLy9jbG91ZHJlc291cmNlbWFuYWdl
ci5nb29nbGVhcGlzLmNvbS9vcmdhbml6YXRpb25zLzEyM2AuCiAqIEZvbGRlcnMsIHN1Y2gg
YXMgYC8vY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vZm9sZGVycy8xMjNg
LgogKiBQcm9qZWN0cywgc3VjaCBhcyBgLy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVh
cGlzLmNvbS9wcm9qZWN0cy8xMjNgCiAgIG9yIGAvL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdv
b2dsZWFwaXMuY29tL3Byb2plY3RzL215LXByb2plY3QtaWRgLgoKDAoFBAICAQQSA3oCCgoM
CgUEAgIBBRIDegsRCgwKBQQCAgEBEgN6EhsKDAoFBAICAQMSA3oeHwoMCgUEAgIBCBIDeiBI
Cg8KCAQCAgEInAgAEgN6IUcKXgoEBAICAhIDfgI9GlEgUmVxdWlyZWQuIFRoZSBhY2Nlc3Mg
cmVsYXRpb25zaGlwIG9mIHByaW5jaXBhbHMgdG8gdGhlIHJlc291cmNlcyBpbiB0aGlzCiBy
dWxlLgoKDAoFBAICAgYSA34CCAoMCgUEAgICARIDfgkPCgwKBQQCAgIDEgN+EhMKDAoFBAIC
AggSA34UPAoPCggEAgICCJwIABIDfhU7YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy ===
    # Fields for PrincipalAccessBoundaryPolicy
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: annotations Type: 11 (.google.iam.v3beta.PrincipalAccessBoundaryPolicy.AnnotationsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: details Type: 11 (.google.iam.v3beta.PrincipalAccessBoundaryPolicyDetails)

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails ===
    # Fields for PrincipalAccessBoundaryPolicyDetails
    # Field: rules Type: 11 (.google.iam.v3beta.PrincipalAccessBoundaryPolicyRule)
    # Field: enforcement_version Type: 9 ()

# === Message: Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule ===
    # Fields for PrincipalAccessBoundaryPolicyRule
    # Field: description Type: 9 ()
    # Field: resources Type: 9 ()
    # Field: effect Type: 14 (.google.iam.v3beta.PrincipalAccessBoundaryPolicyRule.Effect)

# Enum: PrincipalAccessBoundaryPolicyRule::Effect
our $PrincipalAccessBoundaryPolicyRule_EFFECT_UNSPECIFIED = 0;
our $PrincipalAccessBoundaryPolicyRule_ALLOW = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources - Compiled Protocol Buffers messages for google/iam/v3beta/principal_access_boundary_policy_resources.proto

=head1 SYNOPSIS

    use Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources;

    my $msg = Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3beta/principal_access_boundary_policy_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy

An IAM principal access boundary policy resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the principal access boundary policy.

The following format is supported:
`organizations/{organization_id}/locations/{location}/principalAccessBoundaryPolicies/{policy_id}`

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The globally unique ID of the principal access boundary
policy.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The etag for the principal access boundary.
If this is provided on update, it must match the server's etag.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The description of the principal access boundary policy. Must be
less than or equal to 63 characters.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy::AnnotationsEntry>)

Optional. User defined annotations. See
https://google.aip.dev/148#annotations for more details such as format and
size limitations

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the principal access boundary policy was
created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the principal access boundary policy was most
recently updated.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails>)

Optional. The details for the principal access boundary policy.

=back

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails

Principal access boundary policy details

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule>)

Required. A list of principal access boundary policy rules. The number of
rules in a policy is limited to 500.

=item * C<< $msg->enforcement_version() >> / C<< $msg->enforcement_version($value) >>

Type: C<String>

Optional.
The version number (for example, `1` or `latest`) that indicates which
permissions are able to be blocked by the policy. If empty, the PAB policy
version will be set to the most recent version number at the time of the
policy's creation.

=back

=head2 Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule

Principal access boundary policy rule that defines the resource boundary.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the principal access boundary policy rule.
Must be less than or equal to 256 characters.

=item * C<< $msg->resources() >> / C<< $msg->resources($value) >>

Type: C<String>

Required. A list of Resource Manager resources. If a resource is listed in
the rule, then the rule applies for that resource and its descendants. The
number of resources in a policy is limited to 500 across all rules in the
policy.

The following resource types are supported:

* Organizations, such as
`//cloudresourcemanager.googleapis.com/organizations/123`.
* Folders, such as `//cloudresourcemanager.googleapis.com/folders/123`.
* Projects, such as `//cloudresourcemanager.googleapis.com/projects/123`
  or `//cloudresourcemanager.googleapis.com/projects/my-project-id`.

=item * C<< $msg->effect() >> / C<< $msg->effect($value) >>

Type: C<Enum> (L<Google::Iam::V3beta::PrincipalAccessBoundaryPolicyRule::Effect>)

Required. The access relationship of principals to the resources in this
rule.

=back

=head3 Enum: PrincipalAccessBoundaryPolicyRule::Effect

=over 4

=item * C<EFFECT_UNSPECIFIED> => C<0>

=item * C<ALLOW> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
