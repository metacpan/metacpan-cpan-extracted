package Google::Devtools::Artifactregistry::V1::Settings;

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
CjJnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9zZXR0aW5ncy5wcm90bxIj
Z29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90
b2J1Zi9maWVsZF9tYXNrLnByb3RvIrMECg9Qcm9qZWN0U2V0dGluZ3MSEgoEbmFtZRgBIAEo
CVIEbmFtZRJ/ChhsZWdhY3lfcmVkaXJlY3Rpb25fc3RhdGUYAiABKA4yRS5nb29nbGUuZGV2
dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5Qcm9qZWN0U2V0dGluZ3MuUmVkaXJlY3Rpb25T
dGF0ZVIWbGVnYWN5UmVkaXJlY3Rpb25TdGF0ZRIhCgxwdWxsX3BlcmNlbnQYAyABKAVSC3B1
bGxQZXJjZW50Io0CChBSZWRpcmVjdGlvblN0YXRlEiEKHVJFRElSRUNUSU9OX1NUQVRFX1VO
U1BFQ0lGSUVEEAASJAogUkVESVJFQ1RJT05fRlJPTV9HQ1JfSU9fRElTQUJMRUQQARIjCh9S
RURJUkVDVElPTl9GUk9NX0dDUl9JT19FTkFCTEVEEAISKQohUkVESVJFQ1RJT05fRlJPTV9H
Q1JfSU9fRklOQUxJWkVEEAMaAggBEi8KK1JFRElSRUNUSU9OX0ZST01fR0NSX0lPX0VOQUJM
RURfQU5EX0NPUFlJTkcQBRIvCitSRURJUkVDVElPTl9GUk9NX0dDUl9JT19QQVJUSUFMX0FO
RF9DT1BZSU5HEAY6WOpBVQovYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9Qcm9q
ZWN0U2V0dGluZ3MSInByb2plY3RzL3twcm9qZWN0fS9wcm9qZWN0U2V0dGluZ3MiaAoZR2V0
UHJvamVjdFNldHRpbmdzUmVxdWVzdBJLCgRuYW1lGAEgASgJQjfgQQL6QTEKL2FydGlmYWN0
cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vUHJvamVjdFNldHRpbmdzUgRuYW1lIrwBChxVcGRh
dGVQcm9qZWN0U2V0dGluZ3NSZXF1ZXN0El8KEHByb2plY3Rfc2V0dGluZ3MYAiABKAsyNC5n
b29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5Qcm9qZWN0U2V0dGluZ3NSD3By
b2plY3RTZXR0aW5ncxI7Cgt1cGRhdGVfbWFzaxgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5G
aWVsZE1hc2tSCnVwZGF0ZU1hc2tC+AEKJ2NvbS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3Ry
ZWdpc3RyeS52MUINU2V0dGluZ3NQcm90b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL2FydGlm
YWN0cmVnaXN0cnkvYXBpdjEvYXJ0aWZhY3RyZWdpc3RyeXBiO2FydGlmYWN0cmVnaXN0cnlw
YqoCIEdvb2dsZS5DbG91ZC5BcnRpZmFjdFJlZ2lzdHJ5LlYxygIgR29vZ2xlXENsb3VkXEFy
dGlmYWN0UmVnaXN0cnlcVjHqAiNHb29nbGU6OkNsb3VkOjpBcnRpZmFjdFJlZ2lzdHJ5OjpW
MUr0EwoGEgQOAF0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAsCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAqCggKAQgSAxYAPQoJCgIIJRID
FgA9CggKAQgSAxcAZwoJCgIICxIDFwBnCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkA
LgoJCgIICBIDGQAuCggKAQgSAxoAQAoJCgIIARIDGgBACggKAQgSAxsAPQoJCgIIKRIDGwA9
CggKAQgSAxwAPAoJCgIILRIDHAA8CkUKAgQAEgQfAEkBGjkgVGhlIEFydGlmYWN0IFJlZ2lz
dHJ5IHNldHRpbmdzIHRoYXQgYXBwbHkgdG8gYSBQcm9qZWN0LgoKCgoDBAABEgMfCBcKCwoD
BAAHEgQgAiMECg0KBQQAB50IEgQgAiMECkgKBAQABAASBCYCOAMaOiBUaGUgcG9zc2libGUg
cmVkaXJlY3Rpb24gc3RhdGVzIGZvciBsZWdhY3kgcmVwb3NpdG9yaWVzLgoKDAoFBAAEAAES
AyYHFwo0CgYEAAQAAgASAygEJholIE5vIHJlZGlyZWN0aW9uIHN0YXR1cyBoYXMgYmVlbiBz
ZXQuCgoOCgcEAAQAAgABEgMoBCEKDgoHBAAEAAIAAhIDKCQlCikKBgQABAACARIDKwQpGhog
UmVkaXJlY3Rpb24gaXMgZGlzYWJsZWQuCgoOCgcEAAQAAgEBEgMrBCQKDgoHBAAEAAIBAhID
KycoCigKBgQABAACAhIDLgQoGhkgUmVkaXJlY3Rpb24gaXMgZW5hYmxlZC4KCg4KBwQABAAC
AgESAy4EIwoOCgcEAAQAAgICEgMuJicKVgoGBAAEAAIDEgMxBD4aRyBSZWRpcmVjdGlvbiBp
cyBlbmFibGVkLCBhbmQgaGFzIGJlZW4gZmluYWxpemVkIHNvIGNhbm5vdCBiZSByZXZlcnRl
ZC4KCg4KBwQABAACAwESAzEEJQoOCgcEAAQAAgMCEgMxKCkKDgoHBAAEAAIDAxIDMSo9Cg8K
CAQABAACAwMBEgMxKzwKTgoGBAAEAAIEEgM0BDQaPyBSZWRpcmVjdGlvbiBpcyBlbmFibGVk
IGFuZCBtaXNzaW5nIGltYWdlcyBhcmUgY29waWVkIGZyb20gR0NSCgoOCgcEAAQAAgQBEgM0
BC8KDgoHBAAEAAIEAhIDNDIzClgKBgQABAACBRIDNwQ0GkkgUmVkaXJlY3Rpb24gaXMgcGFy
dGlhbGx5IGVuYWJsZWQgYW5kIG1pc3NpbmcgaW1hZ2VzIGFyZSBjb3BpZWQgZnJvbSBHQ1IK
Cg4KBwQABAACBQESAzcELwoOCgcEAAQAAgUCEgM3MjMKqAEKBAQAAgASA0ECEhqaASBUaGUg
bmFtZSBvZiB0aGUgcHJvamVjdCdzIHNldHRpbmdzLgoKIEFsd2F5cyBvZiB0aGUgZm9ybToK
IHByb2plY3RzL3twcm9qZWN0LWlkfS9wcm9qZWN0U2V0dGluZ3MKCiBJbiB1cGRhdGUgcmVx
dWVzdDogbmV2ZXIgc2V0CiBJbiByZXNwb25zZTogYWx3YXlzIHNldAoKDAoFBAACAAUSA0EC
CAoMCgUEAAIAARIDQQkNCgwKBQQAAgADEgNBEBEKUAoEBAACARIDRAIwGkMgVGhlIHJlZGly
ZWN0aW9uIHN0YXRlIG9mIHRoZSBsZWdhY3kgcmVwb3NpdG9yaWVzIGluIHRoaXMgcHJvamVj
dC4KCgwKBQQAAgEGEgNEAhIKDAoFBAACAQESA0QTKwoMCgUEAAIBAxIDRC4vCmkKBAQAAgIS
A0gCGRpcIFRoZSBwZXJjZW50YWdlIG9mIHB1bGwgdHJhZmZpYyB0byByZWRpcmVjdCBmcm9t
IEdDUiB0byBBUiB3aGVuIHVzaW5nCiBwYXJ0aWFsIHJlZGlyZWN0aW9uLgoKDAoFBAACAgUS
A0gCBwoMCgUEAAICARIDSAgUCgwKBQQAAgIDEgNIFxgKOAoCBAESBEwAVAEaLCBHZXRzIHRo
ZSByZWRpcmVjdGlvbiBzdGF0dXMgZm9yIGEgcHJvamVjdC4KCgoKAwQBARIDTAghCkMKBAQB
AgASBE4CUwQaNSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHByb2plY3RTZXR0aW5ncyBy
ZXNvdXJjZS4KCgwKBQQBAgAFEgNOAggKDAoFBAECAAESA04JDQoMCgUEAQIAAxIDThARCg0K
BQQBAgAIEgROElMDCg8KCAQBAgAInAgAEgNPBCoKDwoHBAECAAifCBIEUARSBQovCgIEAhIE
VwBdARojIFNldHMgdGhlIHNldHRpbmdzIG9mIHRoZSBwcm9qZWN0LgoKCgoDBAIBEgNXCCQK
JAoEBAICABIDWQInGhcgVGhlIHByb2plY3Qgc2V0dGluZ3MuCgoMCgUEAgIABhIDWQIRCgwK
BQQCAgABEgNZEiIKDAoFBAICAAMSA1klJgo1CgQEAgIBEgNcAiwaKCBGaWVsZCBtYXNrIHRv
IHN1cHBvcnQgcGFydGlhbCB1cGRhdGVzLgoKDAoFBAICAQYSA1wCGwoMCgUEAgIBARIDXBwn
CgwKBQQCAgEDEgNcKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Settings::ProjectSettings ===
    # Fields for ProjectSettings
    # Field: name Type: 9 ()
    # Field: legacy_redirection_state Type: 14 (.google.devtools.artifactregistry.v1.ProjectSettings.RedirectionState)
    # Field: pull_percent Type: 5 ()

# Enum: ProjectSettings::RedirectionState
our $ProjectSettings_REDIRECTION_STATE_UNSPECIFIED = 0;
our $ProjectSettings_REDIRECTION_FROM_GCR_IO_DISABLED = 1;
our $ProjectSettings_REDIRECTION_FROM_GCR_IO_ENABLED = 2;
our $ProjectSettings_REDIRECTION_FROM_GCR_IO_FINALIZED = 3;
our $ProjectSettings_REDIRECTION_FROM_GCR_IO_ENABLED_AND_COPYING = 5;
our $ProjectSettings_REDIRECTION_FROM_GCR_IO_PARTIAL_AND_COPYING = 6;

# === Message: Google::Devtools::Artifactregistry::V1::Settings::GetProjectSettingsRequest ===
    # Fields for GetProjectSettingsRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Settings::UpdateProjectSettingsRequest ===
    # Fields for UpdateProjectSettingsRequest
    # Field: project_settings Type: 11 (.google.devtools.artifactregistry.v1.ProjectSettings)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Settings - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/settings.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Settings;

    my $msg = Google::Devtools::Artifactregistry::V1::Settings::ProjectSettings->new({
        name => $name,
        legacy_redirection_state => $legacy_redirection_state,
        pull_percent => $pull_percent,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Settings::ProjectSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Settings::ProjectSettings

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

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::ProjectSettings::RedirectionState>)

The redirection state of the legacy repositories in this project.

=item * C<< $msg->pull_percent() >> / C<< $msg->pull_percent($value) >>

Type: C<Int32>

The percentage of pull traffic to redirect from GCR to AR when using
partial redirection.

=back

=head3 Enum: ProjectSettings::RedirectionState

=over 4

=item * C<REDIRECTION_STATE_UNSPECIFIED> => C<0>

=item * C<REDIRECTION_FROM_GCR_IO_DISABLED> => C<1>

=item * C<REDIRECTION_FROM_GCR_IO_ENABLED> => C<2>

=item * C<REDIRECTION_FROM_GCR_IO_FINALIZED> => C<3>

=item * C<REDIRECTION_FROM_GCR_IO_ENABLED_AND_COPYING> => C<5>

=item * C<REDIRECTION_FROM_GCR_IO_PARTIAL_AND_COPYING> => C<6>

=back

=head2 Google::Devtools::Artifactregistry::V1::Settings::GetProjectSettingsRequest

Gets the redirection status for a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the projectSettings resource.

=back

=head2 Google::Devtools::Artifactregistry::V1::Settings::UpdateProjectSettingsRequest

Sets the settings of the project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_settings() >> / C<< $msg->project_settings($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Settings::ProjectSettings>)

The project settings.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Field mask to support partial updates.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Settings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
