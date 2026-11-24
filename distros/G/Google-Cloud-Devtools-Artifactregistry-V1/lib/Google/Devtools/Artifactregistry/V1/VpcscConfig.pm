package Google::Devtools::Artifactregistry::V1::VpcscConfig;

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
CjZnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS92cGNzY19jb25maWcucHJv
dG8SI2dvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiBnb29nbGUv
cHJvdG9idWYvZmllbGRfbWFzay5wcm90byKrAgoLVlBDU0NDb25maWcSEgoEbmFtZRgBIAEo
CVIEbmFtZRJfCgx2cGNzY19wb2xpY3kYAiABKA4yPC5nb29nbGUuZGV2dG9vbHMuYXJ0aWZh
Y3RyZWdpc3RyeS52MS5WUENTQ0NvbmZpZy5WUENTQ1BvbGljeVILdnBjc2NQb2xpY3kiQAoL
VlBDU0NQb2xpY3kSHAoYVlBDU0NfUE9MSUNZX1VOU1BFQ0lGSUVEEAASCAoEREVOWRABEgkK
BUFMTE9XEAI6ZepBYgorYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9WcGNzY0Nv
bmZpZxIzcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3ZwY3NjQ29u
ZmlnImAKFUdldFZQQ1NDQ29uZmlnUmVxdWVzdBJHCgRuYW1lGAEgASgJQjPgQQL6QS0KK2Fy
dGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vVnBjc2NDb25maWdSBG5hbWUirAEKGFVw
ZGF0ZVZQQ1NDQ29uZmlnUmVxdWVzdBJTCgx2cGNzY19jb25maWcYASABKAsyMC5nb29nbGUu
ZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5WUENTQ0NvbmZpZ1ILdnBjc2NDb25maWcS
OwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRh
dGVNYXNrQvsBCidjb20uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFCEFZQ
Q1NDQ29uZmlnUHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9hcnRpZmFjdHJlZ2lzdHJ5
L2FwaXYxL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiBHb29nbGUu
Q2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMcoCIEdvb2dsZVxDbG91ZFxBcnRpZmFjdFJlZ2lz
dHJ5XFYx6gIjR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RSZWdpc3RyeTo6VjFK8xIKBhIEDgBV
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABID
EgApCgkKAgMBEgMTACMKCQoCAwISAxQAKgoICgEIEgMWAD0KCQoCCCUSAxYAPQoICgEIEgMX
AGcKCQoCCAsSAxcAZwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADEKCQoCCAgSAxkA
MQoICgEIEgMaAEAKCQoCCAESAxoAQAoICgEIEgMbAD0KCQoCCCkSAxsAPQoICgEIEgMcADwK
CQoCCC0SAxwAPApKCgIEABIEHwBBARo+IFRoZSBBcnRpZmFjdCBSZWdpc3RyeSBWUEMgU0Mg
Y29uZmlnIHRoYXQgYXBwbHkgdG8gYSBQcm9qZWN0LgoKCgoDBAABEgMfCBMKCwoDBAAHEgQg
AiMECg0KBQQAB50IEgQgAiMECkoKBAQABAASBCYCMwMaPCBWUENTQ1BvbGljeSBpcyB0aGUg
VlBDIFNDIHBvbGljeSBmb3IgcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUEAAQAARIDJgcS
CqwBCgYEAAQAAgASAyoEIRqcASBWUENTQ19QT0xJQ1lfVU5TUEVDSUZJRUQgLSB0aGUgVlBT
IFNDIHBvbGljeSBpcyBub3QgZGVmaW5lZC4KIFdoZW4gVlBTIFNDIHBvbGljeSBpcyBub3Qg
ZGVmaW5lZCAtIHRoZSBTZXJ2aWNlIHdpbGwgdXNlIHRoZSBkZWZhdWx0CiBiZWhhdmlvciAo
VlBDU0NfREVOWSkuCgoOCgcEAAQAAgABEgMqBBwKDgoHBAAEAAIAAhIDKh8gCpQBCgYEAAQA
AgESAy4EDRqEASBWUENTQ19ERU5ZIC0gcmVwb3NpdG9yeSB3aWxsIGJsb2NrIHRoZSByZXF1
ZXN0cyB0byB0aGUgVXBzdHJlYW1zIGZvciB0aGUKIFJlbW90ZSBSZXBvc2l0b3JpZXMgaWYg
dGhlIHJlc291cmNlIGlzIGluIHRoZSBwZXJpbWV0ZXIuCgoOCgcEAAQAAgEBEgMuBAgKDgoH
BAAEAAIBAhIDLgsMCpUBCgYEAAQAAgISAzIEDhqFASBWUENTQ19BTExPVyAtIHJlcG9zaXRv
cnkgd2lsbCBhbGxvdyB0aGUgcmVxdWVzdHMgdG8gdGhlIFVwc3RyZWFtcyBmb3IgdGhlCiBS
ZW1vdGUgUmVwb3NpdG9yaWVzIGlmIHRoZSByZXNvdXJjZSBpcyBpbiB0aGUgcGVyaW1ldGVy
LgoKDgoHBAAEAAICARIDMgQJCg4KBwQABAACAgISAzIMDQq9AQoEBAACABIDPAISGq8BIFRo
ZSBuYW1lIG9mIHRoZSBwcm9qZWN0J3MgVlBDIFNDIENvbmZpZy4KCiBBbHdheXMgb2YgdGhl
IGZvcm06CiBwcm9qZWN0cy97cHJvamVjdElEfS9sb2NhdGlvbnMve2xvY2F0aW9ufS92cGNz
Y0NvbmZpZwoKIEluIHVwZGF0ZSByZXF1ZXN0OiBuZXZlciBzZXQKIEluIHJlc3BvbnNlOiBh
bHdheXMgc2V0CgoMCgUEAAIABRIDPAIICgwKBQQAAgABEgM8CQ0KDAoFBAACAAMSAzwQEQp/
CgQEAAIBEgNAAh8aciBUaGUgcHJvamVjdCBwZXIgbG9jYXRpb24gVlBDIFNDIHBvbGljeSB0
aGF0IGRlZmluZXMgdGhlIFZQQyBTQyBiZWhhdmlvciBmb3IKIHRoZSBSZW1vdGUgUmVwb3Np
dG9yeSAoQWxsb3cvRGVueSkuCgoMCgUEAAIBBhIDQAINCgwKBQQAAgEBEgNADhoKDAoFBAAC
AQMSA0AdHgozCgIEARIERABMARonIEdldHMgdGhlIFZQQyBTQyBjb25maWcgZm9yIGEgcHJv
amVjdC4KCgoKAwQBARIDRAgdCj8KBAQBAgASBEYCSwQaMSBSZXF1aXJlZC4gVGhlIG5hbWUg
b2YgdGhlIFZQQ1NDQ29uZmlnIHJlc291cmNlLgoKDAoFBAECAAUSA0YCCAoMCgUEAQIAARID
RgkNCgwKBQQBAgADEgNGEBEKDQoFBAECAAgSBEYSSwMKDwoIBAECAAicCAASA0cEKgoPCgcE
AQIACJ8IEgRIBEoFCjMKAgQCEgRPAFUBGicgU2V0cyB0aGUgVlBDU0MgY29uZmlnIG9mIHRo
ZSBwcm9qZWN0LgoKCgoDBAIBEgNPCCAKIgoEBAICABIDUQIfGhUgVGhlIHByb2plY3QgY29u
ZmlnLgoKDAoFBAICAAYSA1ECDQoMCgUEAgIAARIDUQ4aCgwKBQQCAgADEgNRHR4KNQoEBAIC
ARIDVAIsGiggRmllbGQgbWFzayB0byBzdXBwb3J0IHBhcnRpYWwgdXBkYXRlcy4KCgwKBQQC
AgEGEgNUAhsKDAoFBAICAQESA1QcJwoMCgUEAgIBAxIDVCorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::VpcscConfig::VPCSCConfig ===
    # Fields for VPCSCConfig
    # Field: name Type: 9 ()
    # Field: vpcsc_policy Type: 14 (.google.devtools.artifactregistry.v1.VPCSCConfig.VPCSCPolicy)

# Enum: VPCSCConfig::VPCSCPolicy
our $VPCSCConfig_VPCSC_POLICY_UNSPECIFIED = 0;
our $VPCSCConfig_DENY = 1;
our $VPCSCConfig_ALLOW = 2;

# === Message: Google::Devtools::Artifactregistry::V1::VpcscConfig::GetVPCSCConfigRequest ===
    # Fields for GetVPCSCConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::VpcscConfig::UpdateVPCSCConfigRequest ===
    # Fields for UpdateVPCSCConfigRequest
    # Field: vpcsc_config Type: 11 (.google.devtools.artifactregistry.v1.VPCSCConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::VpcscConfig - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/vpcsc_config.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::VpcscConfig;

    my $msg = Google::Devtools::Artifactregistry::V1::VpcscConfig::VPCSCConfig->new({
        name => $name,
        vpcsc_policy => $vpcsc_policy,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::VpcscConfig::VPCSCConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/vpcsc_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::VpcscConfig::VPCSCConfig

The Artifact Registry VPC SC config that apply to a Project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the project's VPC SC Config.

Always of the form:
projects/{projectID}/locations/{location}/vpcscConfig

In update request: never set
In response: always set

=item * C<< $msg->vpcsc_policy() >> / C<< $msg->vpcsc_policy($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::VPCSCConfig::VPCSCPolicy>)

The project per location VPC SC policy that defines the VPC SC behavior for
the Remote Repository (Allow/Deny).

=back

=head3 Enum: VPCSCConfig::VPCSCPolicy

=over 4

=item * C<VPCSC_POLICY_UNSPECIFIED> => C<0>

=item * C<DENY> => C<1>

=item * C<ALLOW> => C<2>

=back

=head2 Google::Devtools::Artifactregistry::V1::VpcscConfig::GetVPCSCConfigRequest

Gets the VPC SC config for a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the VPCSCConfig resource.

=back

=head2 Google::Devtools::Artifactregistry::V1::VpcscConfig::UpdateVPCSCConfigRequest

Sets the VPCSC config of the project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vpcsc_config() >> / C<< $msg->vpcsc_config($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::VpcscConfig::VPCSCConfig>)

The project config.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Field mask to support partial updates.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::VpcscConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
