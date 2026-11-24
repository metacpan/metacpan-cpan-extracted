package Google::Cloud::Securitycenter::V1beta1::Asset;

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
    eval { require Google::Cloud::Securitycenter::V1beta1::SecurityMarks };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjFiZXRhMS9hc3NldC5wcm90bxIjZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOGdvb2dsZS9jbG91ZC9z
ZWN1cml0eWNlbnRlci92MWJldGExL3NlY3VyaXR5X21hcmtzLnByb3RvGhxnb29nbGUvcHJv
dG9idWYvc3RydWN0LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIogH
CgVBc3NldBISCgRuYW1lGAEgASgJUgRuYW1lEoEBChpzZWN1cml0eV9jZW50ZXJfcHJvcGVy
dGllcxgCIAEoCzJDLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MWJldGExLkFzc2V0
LlNlY3VyaXR5Q2VudGVyUHJvcGVydGllc1IYc2VjdXJpdHlDZW50ZXJQcm9wZXJ0aWVzEnMK
E3Jlc291cmNlX3Byb3BlcnRpZXMYByADKAsyQi5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50
ZXIudjFiZXRhMS5Bc3NldC5SZXNvdXJjZVByb3BlcnRpZXNFbnRyeVIScmVzb3VyY2VQcm9w
ZXJ0aWVzElkKDnNlY3VyaXR5X21hcmtzGAggASgLMjIuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5
Y2VudGVyLnYxYmV0YTEuU2VjdXJpdHlNYXJrc1INc2VjdXJpdHlNYXJrcxI7CgtjcmVhdGVf
dGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoL
dXBkYXRlX3RpbWUYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVU
aW1lGuYBChhTZWN1cml0eUNlbnRlclByb3BlcnRpZXMSKAoNcmVzb3VyY2VfbmFtZRgBIAEo
CUID4EEFUgxyZXNvdXJjZU5hbWUSIwoNcmVzb3VyY2VfdHlwZRgCIAEoCVIMcmVzb3VyY2VU
eXBlEicKD3Jlc291cmNlX3BhcmVudBgDIAEoCVIOcmVzb3VyY2VQYXJlbnQSKQoQcmVzb3Vy
Y2VfcHJvamVjdBgEIAEoCVIPcmVzb3VyY2VQcm9qZWN0EicKD3Jlc291cmNlX293bmVycxgF
IAMoCVIOcmVzb3VyY2VPd25lcnMaXQoXUmVzb3VyY2VQcm9wZXJ0aWVzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSLAoFdmFsdWUYAiABKAsyFi5nb29nbGUucHJvdG9idWYuVmFsdWVSBXZh
bHVlOgI4ATpV6kFSCiNzZWN1cml0eWNlbnRlci5nb29nbGVhcGlzLmNvbS9Bc3NldBIrb3Jn
YW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9hc3NldHMve2Fzc2V0fUJ8Cidjb20uZ29vZ2xl
LmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxYmV0YTFQAVpPY2xvdWQuZ29vZ2xlLmNvbS9nby9z
ZWN1cml0eWNlbnRlci9hcGl2MWJldGExL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50
ZXJwYkrTGwoGEgQOAFsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFABCCgkKAgMDEgMVACYKCQoC
AwQSAxYAKQoICgEIEgMYAGYKCQoCCAsSAxgAZgoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEI
EgMaAEAKCQoCCAESAxoAQArTAgoCBAASBCMAWwEaxgIgU2VjdXJpdHkgQ29tbWFuZCBDZW50
ZXIgcmVwcmVzZW50YXRpb24gb2YgYSBHb29nbGUgQ2xvdWQKIHJlc291cmNlLgoKIFRoZSBB
c3NldCBpcyBhIFNlY3VyaXR5IENvbW1hbmQgQ2VudGVyIHJlc291cmNlIHRoYXQgY2FwdHVy
ZXMgaW5mb3JtYXRpb24KIGFib3V0IGEgc2luZ2xlIEdvb2dsZSBDbG91ZCByZXNvdXJjZS4g
QWxsIG1vZGlmaWNhdGlvbnMgdG8gYW4gQXNzZXQgYXJlIG9ubHkKIHdpdGhpbiB0aGUgY29u
dGV4dCBvZiBTZWN1cml0eSBDb21tYW5kIENlbnRlciBhbmQgZG9uJ3QgYWZmZWN0IHRoZSBy
ZWZlcmVuY2VkCiBHb29nbGUgQ2xvdWQgcmVzb3VyY2UuCgoKCgMEAAESAyMIDQoLCgMEAAcS
BCQCJwQKDQoFBAAHnQgSBCQCJwQKmQEKBAQAAwASBCsCQQMaigEgU2VjdXJpdHkgQ29tbWFu
ZCBDZW50ZXIgbWFuYWdlZCBwcm9wZXJ0aWVzLiBUaGVzZSBwcm9wZXJ0aWVzIGFyZSBtYW5h
Z2VkIGJ5CiBTZWN1cml0eSBDb21tYW5kIENlbnRlciBhbmQgY2Fubm90IGJlIG1vZGlmaWVk
IGJ5IHRoZSB1c2VyLgoKDAoFBAADAAESAysKIgrgAQoGBAADAAIAEgMvBEca0AEgSW1tdXRh
YmxlLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBHb29nbGUgQ2xvdWQgcmVzb3Vy
Y2UgdGhpcyBhc3NldAogcmVwcmVzZW50cy4gVGhpcyBmaWVsZCBpcyBpbW11dGFibGUgYWZ0
ZXIgY3JlYXRlIHRpbWUuIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rl
c2lnbi9yZXNvdXJjZV9uYW1lcyNmdWxsX3Jlc291cmNlX25hbWUKCg4KBwQAAwACAAUSAy8E
CgoOCgcEAAMAAgABEgMvCxgKDgoHBAADAAIAAxIDLxscCg4KBwQAAwACAAgSAy8dRgoRCgoE
AAMAAgAInAgAEgMvHkUKgQIKBgQAAwACARIDNQQdGvEBIFRoZSB0eXBlIG9mIHRoZSBHb29n
bGUgQ2xvdWQgcmVzb3VyY2UuIEV4YW1wbGVzIGluY2x1ZGU6IEFQUExJQ0FUSU9OLAogUFJP
SkVDVCwgYW5kIE9SR0FOSVpBVElPTi4gVGhpcyBpcyBhIGNhc2UgaW5zZW5zaXRpdmUgZmll
bGQgZGVmaW5lZCBieQogU2VjdXJpdHkgQ29tbWFuZCBDZW50ZXIgYW5kL29yIHRoZSBwcm9k
dWNlciBvZiB0aGUgcmVzb3VyY2UgYW5kIGlzCiBpbW11dGFibGUgYWZ0ZXIgY3JlYXRlIHRp
bWUuCgoOCgcEAAMAAgEFEgM1BAoKDgoHBAADAAIBARIDNQsYCg4KBwQAAwACAQMSAzUbHAqe
AQoGBAADAAICEgM5BB8ajgEgVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgaW1tZWRp
YXRlIHBhcmVudCBvZiB0aGUgcmVzb3VyY2UuIFNlZToKIGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9hcGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcyNmdWxsX3Jlc291cmNlX25hbWUKCg4K
BwQAAwACAgUSAzkECgoOCgcEAAMAAgIBEgM5CxoKDgoHBAADAAICAxIDOR0eCp0BCgYEAAMA
AgMSAz0EIBqNASBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBwcm9qZWN0IHRoZSBy
ZXNvdXJjZSBiZWxvbmdzIHRvLiBTZWU6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBp
cy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMjZnVsbF9yZXNvdXJjZV9uYW1lCgoOCgcEAAMAAgMF
EgM9BAoKDgoHBAADAAIDARIDPQsbCg4KBwQAAwACAwMSAz0eHwo1CgYEAAMAAgQSA0AEKBom
IE93bmVycyBvZiB0aGUgR29vZ2xlIENsb3VkIHJlc291cmNlLgoKDgoHBAADAAIEBBIDQAQM
Cg4KBwQAAwACBAUSA0ANEwoOCgcEAAMAAgQBEgNAFCMKDgoHBAADAAIEAxIDQCYnCsoBCgQE
AAIAEgNHAhIavAEgVGhlIHJlbGF0aXZlIHJlc291cmNlIG5hbWUgb2YgdGhpcyBhc3NldC4g
U2VlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25h
bWVzI3JlbGF0aXZlX3Jlc291cmNlX25hbWUKIEV4YW1wbGU6CiAib3JnYW5pemF0aW9ucy97
b3JnYW5pemF0aW9uX2lkfS9hc3NldHMve2Fzc2V0X2lkfSIuCgoMCgUEAAIABRIDRwIICgwK
BQQAAgABEgNHCQ0KDAoFBAACAAMSA0cQEQqYAQoEBAACARIDSwI6GooBIFNlY3VyaXR5IENv
bW1hbmQgQ2VudGVyIG1hbmFnZWQgcHJvcGVydGllcy4gVGhlc2UgcHJvcGVydGllcyBhcmUg
bWFuYWdlZCBieQogU2VjdXJpdHkgQ29tbWFuZCBDZW50ZXIgYW5kIGNhbm5vdCBiZSBtb2Rp
ZmllZCBieSB0aGUgdXNlci4KCgwKBQQAAgEGEgNLAhoKDAoFBAACAQESA0sbNQoMCgUEAAIB
AxIDSzg5CpcBCgQEAAICEgNPAj0aiQEgUmVzb3VyY2UgbWFuYWdlZCBwcm9wZXJ0aWVzLiBU
aGVzZSBwcm9wZXJ0aWVzIGFyZSBtYW5hZ2VkIGFuZCBkZWZpbmVkIGJ5CiB0aGUgR29vZ2xl
IENsb3VkIHJlc291cmNlIGFuZCBjYW5ub3QgYmUgbW9kaWZpZWQgYnkgdGhlIHVzZXIuCgoM
CgUEAAICBhIDTwIkCgwKBQQAAgIBEgNPJTgKDAoFBAACAgMSA087PAqgAQoEBAACAxIDUwIj
GpIBIFVzZXIgc3BlY2lmaWVkIHNlY3VyaXR5IG1hcmtzLiBUaGVzZSBtYXJrcyBhcmUgZW50
aXJlbHkgbWFuYWdlZCBieSB0aGUgdXNlcgogYW5kIGNvbWUgZnJvbSB0aGUgU2VjdXJpdHlN
YXJrcyByZXNvdXJjZSB0aGF0IGJlbG9uZ3MgdG8gdGhlIGFzc2V0LgoKDAoFBAACAwYSA1MC
DwoMCgUEAAIDARIDUxAeCgwKBQQAAgMDEgNTISIKUgoEBAACBBIDVgIsGkUgVGhlIHRpbWUg
YXQgd2hpY2ggdGhlIGFzc2V0IHdhcyBjcmVhdGVkIGluIFNlY3VyaXR5IENvbW1hbmQgQ2Vu
dGVyLgoKDAoFBAACBAYSA1YCGwoMCgUEAAIEARIDVhwnCgwKBQQAAgQDEgNWKisKawoEBAAC
BRIDWgItGl4gVGhlIHRpbWUgYXQgd2hpY2ggdGhlIGFzc2V0IHdhcyBsYXN0IHVwZGF0ZWQs
IGFkZGVkLCBvciBkZWxldGVkIGluIFNlY3VyaXR5CiBDb21tYW5kIENlbnRlci4KCgwKBQQA
AgUGEgNaAhsKDAoFBAACBQESA1ocJwoMCgUEAAIFAxIDWiosYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1beta1::Asset::Asset ===
    # Fields for Asset
    # Field: name Type: 9 ()
    # Field: security_center_properties Type: 11 (.google.cloud.securitycenter.v1beta1.Asset.SecurityCenterProperties)
    # Field: resource_properties Type: 11 (.google.cloud.securitycenter.v1beta1.Asset.ResourcePropertiesEntry)
    # Field: security_marks Type: 11 (.google.cloud.securitycenter.v1beta1.SecurityMarks)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::Asset - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1beta1/asset.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1beta1::Asset;

    my $msg = Google::Cloud::Securitycenter::V1beta1::Asset::Asset->new({
        name => $name,
        security_center_properties => $security_center_properties,
        resource_properties => $resource_properties,
        security_marks => $security_marks,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1beta1::Asset::Asset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1beta1/asset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1beta1::Asset::Asset

Security Command Center representation of a Google Cloud
resource.

The Asset is a Security Command Center resource that captures information
about a single Google Cloud resource. All modifications to an Asset are only
within the context of Security Command Center and don't affect the referenced
Google Cloud resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of this asset. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Example:
"organizations/{organization_id}/assets/{asset_id}".

=item * C<< $msg->security_center_properties() >> / C<< $msg->security_center_properties($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1beta1::Asset::Asset::SecurityCenterProperties>)

Security Command Center managed properties. These properties are managed by
Security Command Center and cannot be modified by the user.

=item * C<< $msg->resource_properties() >> / C<< $msg->resource_properties($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1beta1::Asset::Asset::ResourcePropertiesEntry>)

Resource managed properties. These properties are managed and defined by
the Google Cloud resource and cannot be modified by the user.

=item * C<< $msg->security_marks() >> / C<< $msg->security_marks($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1beta1::SecurityMarks::SecurityMarks>)

User specified security marks. These marks are entirely managed by the user
and come from the SecurityMarks resource that belongs to the asset.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the asset was created in Security Command Center.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time at which the asset was last updated, added, or deleted in Security
Command Center.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1beta1::Asset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
