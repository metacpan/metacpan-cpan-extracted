package Google::Devtools::Artifactregistry::V1beta2::Settings;

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
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL3NldHRpbmdzLnBy
b3RvEihnb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBn
b29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byKwAwoPUHJvamVjdFNldHRpbmdzEhIK
BG5hbWUYASABKAlSBG5hbWUShAEKGGxlZ2FjeV9yZWRpcmVjdGlvbl9zdGF0ZRgCIAEoDjJK
Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuUHJvamVjdFNldHRp
bmdzLlJlZGlyZWN0aW9uU3RhdGVSFmxlZ2FjeVJlZGlyZWN0aW9uU3RhdGUipwEKEFJlZGly
ZWN0aW9uU3RhdGUSIQodUkVESVJFQ1RJT05fU1RBVEVfVU5TUEVDSUZJRUQQABIkCiBSRURJ
UkVDVElPTl9GUk9NX0dDUl9JT19ESVNBQkxFRBABEiMKH1JFRElSRUNUSU9OX0ZST01fR0NS
X0lPX0VOQUJMRUQQAhIlCiFSRURJUkVDVElPTl9GUk9NX0dDUl9JT19GSU5BTElaRUQQAzpY
6kFVCi9hcnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1Byb2plY3RTZXR0aW5ncxIi
cHJvamVjdHMve3Byb2plY3R9L3Byb2plY3RTZXR0aW5ncyJoChlHZXRQcm9qZWN0U2V0dGlu
Z3NSZXF1ZXN0EksKBG5hbWUYASABKAlCN+BBAvpBMQovYXJ0aWZhY3RyZWdpc3RyeS5nb29n
bGVhcGlzLmNvbS9Qcm9qZWN0U2V0dGluZ3NSBG5hbWUiwQEKHFVwZGF0ZVByb2plY3RTZXR0
aW5nc1JlcXVlc3QSZAoQcHJvamVjdF9zZXR0aW5ncxgCIAEoCzI5Lmdvb2dsZS5kZXZ0b29s
cy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuUHJvamVjdFNldHRpbmdzUg9wcm9qZWN0U2V0
dGluZ3MSOwoLdXBkYXRlX21hc2sYAyABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNr
Ugp1cGRhdGVNYXNrQpECCixjb20uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnku
djFiZXRhMkINU2V0dGluZ3NQcm90b1ABWlVjbG91ZC5nb29nbGUuY29tL2dvL2FydGlmYWN0
cmVnaXN0cnkvYXBpdjFiZXRhMi9hcnRpZmFjdHJlZ2lzdHJ5cGI7YXJ0aWZhY3RyZWdpc3Ry
eXBiqgIlR29vZ2xlLkNsb3VkLkFydGlmYWN0UmVnaXN0cnkuVjFCZXRhMsoCJUdvb2dsZVxD
bG91ZFxBcnRpZmFjdFJlZ2lzdHJ5XFYxYmV0YTLqAihHb29nbGU6OkNsb3VkOjpBcnRpZmFj
dFJlZ2lzdHJ5OjpWMWJldGEyStQQCgYSBA4AUwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQADEKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoK
CAoBCBIDFgBCCgkKAgglEgMWAEIKCAoBCBIDFwBsCgkKAggLEgMXAGwKCAoBCBIDGAAiCgkK
AggKEgMYACIKCAoBCBIDGQAuCgkKAggIEgMZAC4KCAoBCBIDGgBFCgkKAggBEgMaAEUKCAoB
CBIDGwBCCgkKAggpEgMbAEIKCAoBCBIDHABBCgkKAggtEgMcAEEKRQoCBAASBB8APwEaOSBU
aGUgQXJ0aWZhY3QgUmVnaXN0cnkgc2V0dGluZ3MgdGhhdCBhcHBseSB0byBhIFByb2plY3Qu
CgoKCgMEAAESAx8IFwoLCgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQKSAoEBAAEABIEJgIy
Axo6IFRoZSBwb3NzaWJsZSByZWRpcmVjdGlvbiBzdGF0ZXMgZm9yIGxlZ2FjeSByZXBvc2l0
b3JpZXMuCgoMCgUEAAQAARIDJgcXCjQKBgQABAACABIDKAQmGiUgTm8gcmVkaXJlY3Rpb24g
c3RhdHVzIGhhcyBiZWVuIHNldC4KCg4KBwQABAACAAESAygEIQoOCgcEAAQAAgACEgMoJCUK
KQoGBAAEAAIBEgMrBCkaGiBSZWRpcmVjdGlvbiBpcyBkaXNhYmxlZC4KCg4KBwQABAACAQES
AysEJAoOCgcEAAQAAgECEgMrJygKKAoGBAAEAAICEgMuBCgaGSBSZWRpcmVjdGlvbiBpcyBl
bmFibGVkLgoKDgoHBAAEAAICARIDLgQjCg4KBwQABAACAgISAy4mJwpWCgYEAAQAAgMSAzEE
KhpHIFJlZGlyZWN0aW9uIGlzIGVuYWJsZWQsIGFuZCBoYXMgYmVlbiBmaW5hbGl6ZWQgc28g
Y2Fubm90IGJlIHJldmVydGVkLgoKDgoHBAAEAAIDARIDMQQlCg4KBwQABAACAwISAzEoKQqo
AQoEBAACABIDOwISGpoBIFRoZSBuYW1lIG9mIHRoZSBwcm9qZWN0J3Mgc2V0dGluZ3MuCgog
QWx3YXlzIG9mIHRoZSBmb3JtOgogcHJvamVjdHMve3Byb2plY3QtaWR9L3Byb2plY3RTZXR0
aW5ncwoKIEluIHVwZGF0ZSByZXF1ZXN0OiBuZXZlciBzZXQKIEluIHJlc3BvbnNlOiBhbHdh
eXMgc2V0CgoMCgUEAAIABRIDOwIICgwKBQQAAgABEgM7CQ0KDAoFBAACAAMSAzsQEQpQCgQE
AAIBEgM+AjAaQyBUaGUgcmVkaXJlY3Rpb24gc3RhdGUgb2YgdGhlIGxlZ2FjeSByZXBvc2l0
b3JpZXMgaW4gdGhpcyBwcm9qZWN0LgoKDAoFBAACAQYSAz4CEgoMCgUEAAIBARIDPhMrCgwK
BQQAAgEDEgM+Li8KOAoCBAESBEIASgEaLCBHZXRzIHRoZSByZWRpcmVjdGlvbiBzdGF0dXMg
Zm9yIGEgcHJvamVjdC4KCgoKAwQBARIDQgghCkMKBAQBAgASBEQCSQQaNSBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIHByb2plY3RTZXR0aW5ncyByZXNvdXJjZS4KCgwKBQQBAgAFEgNE
AggKDAoFBAECAAESA0QJDQoMCgUEAQIAAxIDRBARCg0KBQQBAgAIEgREEkkDCg8KCAQBAgAI
nAgAEgNFBCoKDwoHBAECAAifCBIERgRIBQovCgIEAhIETQBTARojIFNldHMgdGhlIHNldHRp
bmdzIG9mIHRoZSBwcm9qZWN0LgoKCgoDBAIBEgNNCCQKJAoEBAICABIDTwInGhcgVGhlIHBy
b2plY3Qgc2V0dGluZ3MuCgoMCgUEAgIABhIDTwIRCgwKBQQCAgABEgNPEiIKDAoFBAICAAMS
A08lJgo1CgQEAgIBEgNSAiwaKCBGaWVsZCBtYXNrIHRvIHN1cHBvcnQgcGFydGlhbCB1cGRh
dGVzLgoKDAoFBAICAQYSA1ICGwoMCgUEAgIBARIDUhwnCgwKBQQCAgEDEgNSKitiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings ===
    # Fields for ProjectSettings
    # Field: name Type: 9 ()
    # Field: legacy_redirection_state Type: 14 (.google.devtools.artifactregistry.v1beta2.ProjectSettings.RedirectionState)

# Enum: ProjectSettings::RedirectionState
our $ProjectSettings_REDIRECTION_STATE_UNSPECIFIED = 0;
our $ProjectSettings_REDIRECTION_FROM_GCR_IO_DISABLED = 1;
our $ProjectSettings_REDIRECTION_FROM_GCR_IO_ENABLED = 2;
our $ProjectSettings_REDIRECTION_FROM_GCR_IO_FINALIZED = 3;

# === Message: Google::Devtools::Artifactregistry::V1beta2::Settings::GetProjectSettingsRequest ===
    # Fields for GetProjectSettingsRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Settings::UpdateProjectSettingsRequest ===
    # Fields for UpdateProjectSettingsRequest
    # Field: project_settings Type: 11 (.google.devtools.artifactregistry.v1beta2.ProjectSettings)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Settings - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/settings.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::Settings;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings->new({
        name => $name,
        legacy_redirection_state => $legacy_redirection_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings

The Artifact Registry settings that apply to a Project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the project's settings.

Always of the form:
projects/{project-id}/projectSettings

In update request: never set
In response: always set

=item * C<< $msg->legacy_redirection_state() >> / C<< $msg->legacy_redirection_state($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1beta2::ProjectSettings::RedirectionState>)

The redirection state of the legacy repositories in this project.

=back

=head3 Enum: ProjectSettings::RedirectionState

=over 4

=item * C<REDIRECTION_STATE_UNSPECIFIED> => C<0>

=item * C<REDIRECTION_FROM_GCR_IO_DISABLED> => C<1>

=item * C<REDIRECTION_FROM_GCR_IO_ENABLED> => C<2>

=item * C<REDIRECTION_FROM_GCR_IO_FINALIZED> => C<3>

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Settings::GetProjectSettingsRequest

Gets the redirection status for a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the projectSettings resource.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Settings::UpdateProjectSettingsRequest

Sets the settings of the project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_settings() >> / C<< $msg->project_settings($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings>)

The project settings.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Field mask to support partial updates.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::Settings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
