package Google::Iam::V3::PrincipalAccessBoundaryPolicyResources;

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
Cj5nb29nbGUvaWFtL3YzL3ByaW5jaXBhbF9hY2Nlc3NfYm91bmRhcnlfcG9saWN5X3Jlc291
cmNlcy5wcm90bxINZ29vZ2xlLmlhbS52MxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIoUGCh1QcmluY2lwYWxB
Y2Nlc3NCb3VuZGFyeVBvbGljeRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSHQoDdWlkGAIg
ASgJQgvijM/XCAIIAeBBA1IDdWlkEhcKBGV0YWcYAyABKAlCA+BBAVIEZXRhZxImCgxkaXNw
bGF5X25hbWUYBCABKAlCA+BBAVILZGlzcGxheU5hbWUSZAoLYW5ub3RhdGlvbnMYBSADKAsy
PS5nb29nbGUuaWFtLnYzLlByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5LkFubm90YXRp
b25zRW50cnlCA+BBAVILYW5ub3RhdGlvbnMSQAoLY3JlYXRlX3RpbWUYBiABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUY
ByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSUgoH
ZGV0YWlscxgIIAEoCzIzLmdvb2dsZS5pYW0udjMuUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQ
b2xpY3lEZXRhaWxzQgPgQQFSB2RldGFpbHMaPgoQQW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkY
ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOuwB6kHoAQowaWFtLmdvb2ds
ZWFwaXMuY29tL1ByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5EnRvcmdhbml6YXRpb25z
L3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L3ByaW5jaXBhbEFjY2Vzc0Jv
dW5kYXJ5UG9saWNpZXMve3ByaW5jaXBhbF9hY2Nlc3NfYm91bmRhcnlfcG9saWN5fSofcHJp
bmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY2llczIdcHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQ
b2xpY3kiqQEKJFByaW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5RGV0YWlscxJLCgVydWxl
cxgBIAMoCzIwLmdvb2dsZS5pYW0udjMuUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lS
dWxlQgPgQQJSBXJ1bGVzEjQKE2VuZm9yY2VtZW50X3ZlcnNpb24YBCABKAlCA+BBAVISZW5m
b3JjZW1lbnRWZXJzaW9uIvABCiFQcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljeVJ1bGUS
JQoLZGVzY3JpcHRpb24YASABKAlCA+BBAVILZGVzY3JpcHRpb24SIQoJcmVzb3VyY2VzGAIg
AygJQgPgQQJSCXJlc291cmNlcxJUCgZlZmZlY3QYAyABKA4yNy5nb29nbGUuaWFtLnYzLlBy
aW5jaXBhbEFjY2Vzc0JvdW5kYXJ5UG9saWN5UnVsZS5FZmZlY3RCA+BBAlIGZWZmZWN0IisK
BkVmZmVjdBIWChJFRkZFQ1RfVU5TUEVDSUZJRUQQABIJCgVBTExPVxABQpkBChFjb20uZ29v
Z2xlLmlhbS52M0IrUHJpbmNpcGFsQWNjZXNzQm91bmRhcnlQb2xpY3lSZXNvdXJjZXNQcm90
b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL2lhbS9hcGl2My9pYW1wYjtpYW1wYqoCE0dvb2ds
ZS5DbG91ZC5JYW0uVjPKAhNHb29nbGVcQ2xvdWRcSWFtXFYzSrcjCgYSBA4AfwEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABYKCQoCAwASAxIAKQoJCgID
ARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAKQoICgEIEgMXADAKCQoCCCUSAxcAMAoICgEI
EgMYAEAKCQoCCAsSAxgAQAoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAEwKCQoCCAgS
AxoATAoICgEIEgMbACoKCQoCCAESAxsAKgoICgEIEgMcADAKCQoCCCkSAxwAMAo/CgIEABIE
HwBOARozIEFuIElBTSBwcmluY2lwYWwgYWNjZXNzIGJvdW5kYXJ5IHBvbGljeSByZXNvdXJj
ZS4KCgoKAwQAARIDHwglCgsKAwQABxIEIAIlBAoNCgUEAAedCBIEIAIlBArfAQoEBAACABID
KwI9GtEBIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBwcmluY2lwYWwg
YWNjZXNzIGJvdW5kYXJ5IHBvbGljeS4KCiBUaGUgZm9sbG93aW5nIGZvcm1hdCBpcyBzdXBw
b3J0ZWQ6CiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9wcmluY2lwYWxBY2Nlc3NCb3VuZGFyeVBvbGljaWVzL3twb2xpY3lfaWR9YAoK
DAoFBAACAAUSAysCCAoMCgUEAAIAARIDKwkNCgwKBQQAAgADEgMrEBEKDAoFBAACAAgSAysS
PAoPCggEAAIACJwIABIDKxM7Cl0KBAQAAgESBC8CMgQaTyBPdXRwdXQgb25seS4gVGhlIGds
b2JhbGx5IHVuaXF1ZSBJRCBvZiB0aGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeQogcG9s
aWN5LgoKDAoFBAACAQUSAy8CCAoMCgUEAAIBARIDLwkMCgwKBQQAAgEDEgMvDxAKDQoFBAAC
AQgSBC8RMgMKEgoLBAACAQjM8fmKAQESAzAEKgoPCggEAAIBCJwIABIDMQQtCoUBCgQEAAIC
EgM2AjsaeCBPcHRpb25hbC4gVGhlIGV0YWcgZm9yIHRoZSBwcmluY2lwYWwgYWNjZXNzIGJv
dW5kYXJ5LgogSWYgdGhpcyBpcyBwcm92aWRlZCBvbiB1cGRhdGUsIGl0IG11c3QgbWF0Y2gg
dGhlIHNlcnZlcidzIGV0YWcuCgoMCgUEAAICBRIDNgIICgwKBQQAAgIBEgM2CQ0KDAoFBAAC
AgMSAzYQEQoMCgUEAAICCBIDNhI6Cg8KCAQAAgIInAgAEgM2EzkKfwoEBAACAxIDOgJDGnIg
T3B0aW9uYWwuIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgcHJpbmNpcGFsIGFjY2VzcyBib3Vu
ZGFyeSBwb2xpY3kuIE11c3QgYmUKIGxlc3MgdGhhbiBvciBlcXVhbCB0byA2MyBjaGFyYWN0
ZXJzLgoKDAoFBAACAwUSAzoCCAoMCgUEAAIDARIDOgkVCgwKBQQAAgMDEgM6GBkKDAoFBAAC
AwgSAzoaQgoPCggEAAIDCJwIABIDOhtBCpUBCgQEAAIEEgM/Ak8ahwEgT3B0aW9uYWwuIFVz
ZXIgZGVmaW5lZCBhbm5vdGF0aW9ucy4gU2VlCiBodHRwczovL2dvb2dsZS5haXAuZGV2LzE0
OCNhbm5vdGF0aW9ucyBmb3IgbW9yZSBkZXRhaWxzIHN1Y2ggYXMgZm9ybWF0IGFuZAogc2l6
ZSBsaW1pdGF0aW9ucwoKDAoFBAACBAYSAz8CFQoMCgUEAAIEARIDPxYhCgwKBQQAAgQDEgM/
JCUKDAoFBAACBAgSAz8mTgoPCggEAAIECJwIABIDPydNCl0KBAQAAgUSBEMCRDIaTyBPdXRw
dXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgcHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBw
b2xpY3kgd2FzCiBjcmVhdGVkLgoKDAoFBAACBQYSA0MCGwoMCgUEAAIFARIDQxwnCgwKBQQA
AgUDEgNDKisKDAoFBAACBQgSA0QGMQoPCggEAAIFCJwIABIDRAcwCmsKBAQAAgYSBEgCSTIa
XSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgcHJpbmNpcGFsIGFjY2VzcyBib3Vu
ZGFyeSBwb2xpY3kgd2FzIG1vc3QKIHJlY2VudGx5IHVwZGF0ZWQuCgoMCgUEAAIGBhIDSAIb
CgwKBQQAAgYBEgNIHCcKDAoFBAACBgMSA0gqKwoMCgUEAAIGCBIDSQYxCg8KCAQAAgYInAgA
EgNJBzAKTwoEBAACBxIETAJNLxpBIE9wdGlvbmFsLiBUaGUgZGV0YWlscyBmb3IgdGhlIHBy
aW5jaXBhbCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5LgoKDAoFBAACBwYSA0wCJgoMCgUEAAIH
ARIDTCcuCgwKBQQAAgcDEgNMMTIKDAoFBAACBwgSA00GLgoPCggEAAIHCJwIABIDTQctCjYK
AgQBEgRRAF0BGiogUHJpbmNpcGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3kgZGV0YWlscwoK
CgoDBAEBEgNRCCwKfwoEBAECABIEVAJVLxpxIFJlcXVpcmVkLiBBIGxpc3Qgb2YgcHJpbmNp
cGFsIGFjY2VzcyBib3VuZGFyeSBwb2xpY3kgcnVsZXMuIFRoZSBudW1iZXIgb2YKIHJ1bGVz
IGluIGEgcG9saWN5IGlzIGxpbWl0ZWQgdG8gNTAwLgoKDAoFBAECAAQSA1QCCgoMCgUEAQIA
BhIDVAssCgwKBQQBAgABEgNULTIKDAoFBAECAAMSA1Q1NgoMCgUEAQIACBIDVQYuCg8KCAQB
AgAInAgAEgNVBy0KiwIKBAQBAgESA1wCShr9ASBPcHRpb25hbC4KIFRoZSB2ZXJzaW9uIG51
bWJlciAoZm9yIGV4YW1wbGUsIGAxYCBvciBgbGF0ZXN0YCkgdGhhdCBpbmRpY2F0ZXMgd2hp
Y2gKIHBlcm1pc3Npb25zIGFyZSBhYmxlIHRvIGJlIGJsb2NrZWQgYnkgdGhlIHBvbGljeS4g
SWYgZW1wdHksIHRoZSBQQUIgcG9saWN5CiB2ZXJzaW9uIHdpbGwgYmUgc2V0IHRvIHRoZSBt
b3N0IHJlY2VudCB2ZXJzaW9uIG51bWJlciBhdCB0aGUgdGltZSBvZiB0aGUKIHBvbGljeSdz
IGNyZWF0aW9uLgoKDAoFBAECAQUSA1wCCAoMCgUEAQIBARIDXAkcCgwKBQQBAgEDEgNcHyAK
DAoFBAECAQgSA1whSQoPCggEAQIBCJwIABIDXCJIClcKAgQCEgRgAH8BGksgUHJpbmNpcGFs
IGFjY2VzcyBib3VuZGFyeSBwb2xpY3kgcnVsZSB0aGF0IGRlZmluZXMgdGhlIHJlc291cmNl
IGJvdW5kYXJ5LgoKCgoDBAIBEgNgCCkKPgoEBAIEABIEYgJoAxowIEFuIGVmZmVjdCB0byBk
ZXNjcmliZSB0aGUgYWNjZXNzIHJlbGF0aW9uc2hpcC4KCgwKBQQCBAABEgNiBw0KJAoGBAIE
AAIAEgNkBBsaFSBFZmZlY3QgdW5zcGVjaWZpZWQuCgoOCgcEAgQAAgABEgNkBBYKDgoHBAIE
AAIAAhIDZBkaCj0KBgQCBAACARIDZwQOGi4gQWxsb3dzIGFjY2VzcyB0byB0aGUgcmVzb3Vy
Y2VzIGluIHRoaXMgcnVsZS4KCg4KBwQCBAACAQESA2cECQoOCgcEAgQAAgECEgNnDA0KhQEK
BAQCAgASA2wCQhp4IE9wdGlvbmFsLiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIHByaW5jaXBh
bCBhY2Nlc3MgYm91bmRhcnkgcG9saWN5IHJ1bGUuCiBNdXN0IGJlIGxlc3MgdGhhbiBvciBl
cXVhbCB0byAyNTYgY2hhcmFjdGVycy4KCgwKBQQCAgAFEgNsAggKDAoFBAICAAESA2wJFAoM
CgUEAgIAAxIDbBcYCgwKBQQCAgAIEgNsGUEKDwoIBAICAAicCAASA2waQArYBAoEBAICARID
egJJGsoEIFJlcXVpcmVkLiBBIGxpc3Qgb2YgUmVzb3VyY2UgTWFuYWdlciByZXNvdXJjZXMu
IElmIGEgcmVzb3VyY2UgaXMgbGlzdGVkIGluCiB0aGUgcnVsZSwgdGhlbiB0aGUgcnVsZSBh
cHBsaWVzIGZvciB0aGF0IHJlc291cmNlIGFuZCBpdHMgZGVzY2VuZGFudHMuIFRoZQogbnVt
YmVyIG9mIHJlc291cmNlcyBpbiBhIHBvbGljeSBpcyBsaW1pdGVkIHRvIDUwMCBhY3Jvc3Mg
YWxsIHJ1bGVzIGluIHRoZQogcG9saWN5LgoKIFRoZSBmb2xsb3dpbmcgcmVzb3VyY2UgdHlw
ZXMgYXJlIHN1cHBvcnRlZDoKCiAqIE9yZ2FuaXphdGlvbnMsIHN1Y2ggYXMKIGAvL2Nsb3Vk
cmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL29yZ2FuaXphdGlvbnMvMTIzYC4KICog
Rm9sZGVycywgc3VjaCBhcyBgLy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNv
bS9mb2xkZXJzLzEyM2AuCiAqIFByb2plY3RzLCBzdWNoIGFzIGAvL2Nsb3VkcmVzb3VyY2Vt
YW5hZ2VyLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzLzEyM2AKICAgb3IgYC8vY2xvdWRyZXNv
dXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMvbXktcHJvamVjdC1pZGAuCgoM
CgUEAgIBBBIDegIKCgwKBQQCAgEFEgN6CxEKDAoFBAICAQESA3oSGwoMCgUEAgIBAxIDeh4f
CgwKBQQCAgEIEgN6IEgKDwoIBAICAQicCAASA3ohRwpeCgQEAgICEgN+Aj0aUSBSZXF1aXJl
ZC4gVGhlIGFjY2VzcyByZWxhdGlvbnNoaXAgb2YgcHJpbmNpcGFscyB0byB0aGUgcmVzb3Vy
Y2VzIGluIHRoaXMKIHJ1bGUuCgoMCgUEAgICBhIDfgIICgwKBQQCAgIBEgN+CQ8KDAoFBAIC
AgMSA34SEwoMCgUEAgICCBIDfhQ8Cg8KCAQCAgIInAgAEgN+FTtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy ===
    # Fields for PrincipalAccessBoundaryPolicy
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: annotations Type: 11 (.google.iam.v3.PrincipalAccessBoundaryPolicy.AnnotationsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: details Type: 11 (.google.iam.v3.PrincipalAccessBoundaryPolicyDetails)

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails ===
    # Fields for PrincipalAccessBoundaryPolicyDetails
    # Field: rules Type: 11 (.google.iam.v3.PrincipalAccessBoundaryPolicyRule)
    # Field: enforcement_version Type: 9 ()

# === Message: Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule ===
    # Fields for PrincipalAccessBoundaryPolicyRule
    # Field: description Type: 9 ()
    # Field: resources Type: 9 ()
    # Field: effect Type: 14 (.google.iam.v3.PrincipalAccessBoundaryPolicyRule.Effect)

# Enum: PrincipalAccessBoundaryPolicyRule::Effect
our $PrincipalAccessBoundaryPolicyRule_EFFECT_UNSPECIFIED = 0;
our $PrincipalAccessBoundaryPolicyRule_ALLOW = 1;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V3::PrincipalAccessBoundaryPolicyResources - Compiled Protocol Buffers messages for google/iam/v3/principal_access_boundary_policy_resources.proto

=head1 SYNOPSIS

    use Google::Iam::V3::PrincipalAccessBoundaryPolicyResources;

    my $msg = Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v3/principal_access_boundary_policy_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy

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

Type: C<Message> (L<Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy::AnnotationsEntry>)

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

Type: C<Message> (L<Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails>)

Optional. The details for the principal access boundary policy.

=back

=head2 Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails

Principal access boundary policy details

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule>)

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

=head2 Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule

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

Type: C<Enum> (L<Google::Iam::V3::PrincipalAccessBoundaryPolicyRule::Effect>)

Required. The access relationship of principals to the resources in this
rule.

=back

=head3 Enum: PrincipalAccessBoundaryPolicyRule::Effect

=over 4

=item * C<EFFECT_UNSPECIFIED> => C<0>

=item * C<ALLOW> => C<1>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V3::PrincipalAccessBoundaryPolicyResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
