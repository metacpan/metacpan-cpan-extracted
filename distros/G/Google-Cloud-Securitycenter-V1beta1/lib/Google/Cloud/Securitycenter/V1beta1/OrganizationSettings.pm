package Google::Cloud::Securitycenter::V1beta1::OrganizationSettings;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjFiZXRhMS9vcmdhbml6YXRpb25fc2V0
dGluZ3MucHJvdG8SI2dvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MWJldGExGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvIuMEChRPcmdhbml6YXRpb25TZXR0aW5ncxISCgRuYW1l
GAEgASgJUgRuYW1lEjQKFmVuYWJsZV9hc3NldF9kaXNjb3ZlcnkYAiABKAhSFGVuYWJsZUFz
c2V0RGlzY292ZXJ5EoQBChZhc3NldF9kaXNjb3ZlcnlfY29uZmlnGAMgASgLMk4uZ29vZ2xl
LmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxYmV0YTEuT3JnYW5pemF0aW9uU2V0dGluZ3MuQXNz
ZXREaXNjb3ZlcnlDb25maWdSFGFzc2V0RGlzY292ZXJ5Q29uZmlnGo0CChRBc3NldERpc2Nv
dmVyeUNvbmZpZxIfCgtwcm9qZWN0X2lkcxgBIAMoCVIKcHJvamVjdElkcxKDAQoOaW5jbHVz
aW9uX21vZGUYAiABKA4yXC5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFiZXRhMS5P
cmdhbml6YXRpb25TZXR0aW5ncy5Bc3NldERpc2NvdmVyeUNvbmZpZy5JbmNsdXNpb25Nb2Rl
Ug1pbmNsdXNpb25Nb2RlIk4KDUluY2x1c2lvbk1vZGUSHgoaSU5DTFVTSU9OX01PREVfVU5T
UEVDSUZJRUQQABIQCgxJTkNMVURFX09OTFkQARILCgdFWENMVURFEAI6aupBZwoyc2VjdXJp
dHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vT3JnYW5pemF0aW9uU2V0dGluZ3MSMW9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vb3JnYW5pemF0aW9uU2V0dGluZ3NCfAonY29tLmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MWJldGExUAFaT2Nsb3VkLmdvb2dsZS5jb20vZ28v
c2VjdXJpdHljZW50ZXIvYXBpdjFiZXRhMS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2Vu
dGVycGJKjxYKBhIEDgBNAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAALAoJCgIDABIDEgAjCggKAQgSAxQAZgoJCgIICxIDFABmCggKAQgSAxUAIgoJCgII
ChIDFQAiCggKAQgSAxYAQAoJCgIIARIDFgBACmUKAgQAEgQaAE0BGlkgVXNlciBzcGVjaWZp
ZWQgc2V0dGluZ3MgdGhhdCBhcmUgYXR0YWNoZWQgdG8gdGhlIFNlY3VyaXR5IENvbW1hbmQK
IENlbnRlciBvcmdhbml6YXRpb24uCgoKCgMEAAESAxoIHAoLCgMEAAcSBBsCHgQKDQoFBAAH
nQgSBBsCHgQKQAoEBAADABIEIQI9AxoyIFRoZSBjb25maWd1cmF0aW9uIHVzZWQgZm9yIEFz
c2V0IERpc2NvdmVyeSBydW5zLgoKDAoFBAADAAESAyEKHgr7AwoGBAADAAQAEgQqBDYFGuoD
IFRoZSBtb2RlIG9mIGluY2x1c2lvbiB3aGVuIHJ1bm5pbmcgQXNzZXQgRGlzY292ZXJ5Lgog
QXNzZXQgZGlzY292ZXJ5IGNhbiBiZSBsaW1pdGVkIGJ5IGV4cGxpY2l0bHkgaWRlbnRpZnlp
bmcgcHJvamVjdHMgdG8gYmUKIGluY2x1ZGVkIG9yIGV4Y2x1ZGVkLiBJZiBJTkNMVURFX09O
TFkgaXMgc2V0LCB0aGVuIG9ubHkgdGhvc2UgcHJvamVjdHMKIHdpdGhpbiB0aGUgb3JnYW5p
emF0aW9uIGFuZCB0aGVpciBjaGlsZHJlbiBhcmUgZGlzY292ZXJlZCBkdXJpbmcgYXNzZXQK
IGRpc2NvdmVyeS4gSWYgRVhDTFVERSBpcyBzZXQsIHRoZW4gcHJvamVjdHMgdGhhdCBkb24n
dCBtYXRjaCB0aG9zZQogcHJvamVjdHMgYXJlIGRpc2NvdmVyZWQgZHVyaW5nIGFzc2V0IGRp
c2NvdmVyeS4gSWYgbmVpdGhlciBhcmUgc2V0LCB0aGVuCiBhbGwgcHJvamVjdHMgd2l0aGlu
IHRoZSBvcmdhbml6YXRpb24gYXJlIGRpc2NvdmVyZWQgZHVyaW5nIGFzc2V0CiBkaXNjb3Zl
cnkuCgoOCgcEAAMABAABEgMqCRYKgQEKCAQAAwAEAAIAEgMtBiUacCBVbnNwZWNpZmllZC4g
U2V0dGluZyB0aGUgbW9kZSB3aXRoIHRoaXMgdmFsdWUgd2lsbCBkaXNhYmxlCiBpbmNsdXNp
b24vZXhjbHVzaW9uIGZpbHRlcmluZyBmb3IgQXNzZXQgRGlzY292ZXJ5LgoKEAoJBAADAAQA
AgABEgMtBiAKEAoJBAADAAQAAgACEgMtIyQKhwEKCAQAAwAEAAIBEgMxBhcadiBBc3NldCBE
aXNjb3Zlcnkgd2lsbCBjYXB0dXJlIG9ubHkgdGhlIHJlc291cmNlcyB3aXRoaW4gdGhlIHBy
b2plY3RzCiBzcGVjaWZpZWQuIEFsbCBvdGhlciByZXNvdXJjZXMgd2lsbCBiZSBpZ25vcmVk
LgoKEAoJBAADAAQAAgEBEgMxBhIKEAoJBAADAAQAAgECEgMxFRYKggEKCAQAAwAEAAICEgM1
BhIacSBBc3NldCBEaXNjb3Zlcnkgd2lsbCBpZ25vcmUgYWxsIHJlc291cmNlcyB1bmRlciB0
aGUgcHJvamVjdHMgc3BlY2lmaWVkLgogQWxsIG90aGVyIHJlc291cmNlcyB3aWxsIGJlIHJl
dHJpZXZlZC4KChAKCQQAAwAEAAICARIDNQYNChAKCQQAAwAEAAICAhIDNRARCkYKBgQAAwAC
ABIDOQQkGjcgVGhlIHByb2plY3QgaWRzIHRvIHVzZSBmb3IgZmlsdGVyaW5nIGFzc2V0IGRp
c2NvdmVyeS4KCg4KBwQAAwACAAQSAzkEDAoOCgcEAAMAAgAFEgM5DRMKDgoHBAADAAIAARID
ORQfCg4KBwQAAwACAAMSAzkiIwo/CgYEAAMAAgESAzwEJRowIFRoZSBtb2RlIHRvIHVzZSBm
b3IgZmlsdGVyaW5nIGFzc2V0IGRpc2NvdmVyeS4KCg4KBwQAAwACAQYSAzwEEQoOCgcEAAMA
AgEBEgM8EiAKDgoHBAADAAIBAxIDPCMkCs8BCgQEAAIAEgNDAhIawQEgVGhlIHJlbGF0aXZl
IHJlc291cmNlIG5hbWUgb2YgdGhlIHNldHRpbmdzLiBTZWU6CiBodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMjcmVsYXRpdmVfcmVzb3VyY2Vf
bmFtZQogRXhhbXBsZToKICJvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L29yZ2Fu
aXphdGlvblNldHRpbmdzIi4KCgwKBQQAAgAFEgNDAggKDAoFBAACAAESA0MJDQoMCgUEAAIA
AxIDQxARCvsBCgQEAAIBEgNJAiIa7QEgQSBmbGFnIHRoYXQgaW5kaWNhdGVzIGlmIEFzc2V0
IERpc2NvdmVyeSBzaG91bGQgYmUgZW5hYmxlZC4gSWYgdGhlIGZsYWcgaXMKIHNldCB0byBg
dHJ1ZWAsIHRoZW4gZGlzY292ZXJ5IG9mIGFzc2V0cyB3aWxsIG9jY3VyLiBJZiBpdCBpcyBz
ZXQgdG8gYGZhbHNlLAogYWxsIGhpc3RvcmljYWwgYXNzZXRzIHdpbGwgcmVtYWluLCBidXQg
ZGlzY292ZXJ5IG9mIGZ1dHVyZSBhc3NldHMgd2lsbCBub3QKIG9jY3VyLgoKDAoFBAACAQUS
A0kCBgoMCgUEAAIBARIDSQcdCgwKBQQAAgEDEgNJICEKPwoEBAACAhIDTAIyGjIgVGhlIGNv
bmZpZ3VyYXRpb24gdXNlZCBmb3IgQXNzZXQgRGlzY292ZXJ5IHJ1bnMuCgoMCgUEAAICBhID
TAIWCgwKBQQAAgIBEgNMFy0KDAoFBAACAgMSA0wwMWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1beta1::OrganizationSettings::OrganizationSettings ===
    # Fields for OrganizationSettings
    # Field: name Type: 9 ()
    # Field: enable_asset_discovery Type: 8 ()
    # Field: asset_discovery_config Type: 11 (.google.cloud.securitycenter.v1beta1.OrganizationSettings.AssetDiscoveryConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::OrganizationSettings - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1beta1/organization_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1beta1::OrganizationSettings;

    my $msg = Google::Cloud::Securitycenter::V1beta1::OrganizationSettings::OrganizationSettings->new({
        name => $name,
        enable_asset_discovery => $enable_asset_discovery,
        asset_discovery_config => $asset_discovery_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1beta1::OrganizationSettings::OrganizationSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1beta1/organization_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1beta1::OrganizationSettings::OrganizationSettings

User specified settings that are attached to the Security Command
Center organization.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of the settings. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Example:
"organizations/{organization_id}/organizationSettings".

=item * C<< $msg->enable_asset_discovery() >> / C<< $msg->enable_asset_discovery($value) >>

Type: C<Bool>

A flag that indicates if Asset Discovery should be enabled. If the flag is
set to `true`, then discovery of assets will occur. If it is set to `false,
all historical assets will remain, but discovery of future assets will not
occur.

=item * C<< $msg->asset_discovery_config() >> / C<< $msg->asset_discovery_config($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1beta1::OrganizationSettings::OrganizationSettings::AssetDiscoveryConfig>)

The configuration used for Asset Discovery runs.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1beta1::OrganizationSettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
