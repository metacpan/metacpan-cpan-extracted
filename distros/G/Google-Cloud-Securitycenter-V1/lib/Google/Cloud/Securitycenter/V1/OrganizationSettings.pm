package Google::Cloud::Securitycenter::V1::OrganizationSettings;

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
Cjpnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvb3JnYW5pemF0aW9uX3NldHRpbmdz
LnByb3RvEh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEaGWdvb2dsZS9hcGkvcmVz
b3VyY2UucHJvdG8ipAUKFE9yZ2FuaXphdGlvblNldHRpbmdzEhIKBG5hbWUYASABKAlSBG5h
bWUSNAoWZW5hYmxlX2Fzc2V0X2Rpc2NvdmVyeRgCIAEoCFIUZW5hYmxlQXNzZXREaXNjb3Zl
cnkSfwoWYXNzZXRfZGlzY292ZXJ5X2NvbmZpZxgDIAEoCzJJLmdvb2dsZS5jbG91ZC5zZWN1
cml0eWNlbnRlci52MS5Pcmdhbml6YXRpb25TZXR0aW5ncy5Bc3NldERpc2NvdmVyeUNvbmZp
Z1IUYXNzZXREaXNjb3ZlcnlDb25maWcapgIKFEFzc2V0RGlzY292ZXJ5Q29uZmlnEh8KC3By
b2plY3RfaWRzGAEgAygJUgpwcm9qZWN0SWRzEn4KDmluY2x1c2lvbl9tb2RlGAIgASgOMlcu
Z29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLk9yZ2FuaXphdGlvblNldHRpbmdzLkFz
c2V0RGlzY292ZXJ5Q29uZmlnLkluY2x1c2lvbk1vZGVSDWluY2x1c2lvbk1vZGUSHQoKZm9s
ZGVyX2lkcxgDIAMoCVIJZm9sZGVySWRzIk4KDUluY2x1c2lvbk1vZGUSHgoaSU5DTFVTSU9O
X01PREVfVU5TUEVDSUZJRUQQABIQCgxJTkNMVURFX09OTFkQARILCgdFWENMVURFEAI6lwHq
QZMBCjJzZWN1cml0eWNlbnRlci5nb29nbGVhcGlzLmNvbS9Pcmdhbml6YXRpb25TZXR0aW5n
cxIxb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9vcmdhbml6YXRpb25TZXR0aW5ncyoU
b3JnYW5pemF0aW9uU2V0dGluZ3MyFG9yZ2FuaXphdGlvblNldHRpbmdzQtgBCiJjb20uZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2Vj
dXJpdHljZW50ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIe
R29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYxygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5
Q2VudGVyXFYx6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSocYCgYSBA4A
VgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwAS
AxIAIwoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXADsKCQoCCAESAxcAOwoICgEIEgMYADsKCQoCCCkSAxgA
OwoICgEIEgMZADoKCQoCCC0SAxkAOgplCgIEABIEHQBWARpZIFVzZXIgc3BlY2lmaWVkIHNl
dHRpbmdzIHRoYXQgYXJlIGF0dGFjaGVkIHRvIHRoZSBTZWN1cml0eSBDb21tYW5kCiBDZW50
ZXIgb3JnYW5pemF0aW9uLgoKCgoDBAABEgMdCBwKCwoDBAAHEgQeAiMECg0KBQQAB50IEgQe
AiMECkAKBAQAAwASBCYCRgMaMiBUaGUgY29uZmlndXJhdGlvbiB1c2VkIGZvciBBc3NldCBE
aXNjb3ZlcnkgcnVucy4KCgwKBQQAAwABEgMmCh4K+wMKBgQAAwAEABIELwQ7BRrqAyBUaGUg
bW9kZSBvZiBpbmNsdXNpb24gd2hlbiBydW5uaW5nIEFzc2V0IERpc2NvdmVyeS4KIEFzc2V0
IGRpc2NvdmVyeSBjYW4gYmUgbGltaXRlZCBieSBleHBsaWNpdGx5IGlkZW50aWZ5aW5nIHBy
b2plY3RzIHRvIGJlCiBpbmNsdWRlZCBvciBleGNsdWRlZC4gSWYgSU5DTFVERV9PTkxZIGlz
IHNldCwgdGhlbiBvbmx5IHRob3NlIHByb2plY3RzCiB3aXRoaW4gdGhlIG9yZ2FuaXphdGlv
biBhbmQgdGhlaXIgY2hpbGRyZW4gYXJlIGRpc2NvdmVyZWQgZHVyaW5nIGFzc2V0CiBkaXNj
b3ZlcnkuIElmIEVYQ0xVREUgaXMgc2V0LCB0aGVuIHByb2plY3RzIHRoYXQgZG9uJ3QgbWF0
Y2ggdGhvc2UKIHByb2plY3RzIGFyZSBkaXNjb3ZlcmVkIGR1cmluZyBhc3NldCBkaXNjb3Zl
cnkuIElmIG5laXRoZXIgYXJlIHNldCwgdGhlbgogYWxsIHByb2plY3RzIHdpdGhpbiB0aGUg
b3JnYW5pemF0aW9uIGFyZSBkaXNjb3ZlcmVkIGR1cmluZyBhc3NldAogZGlzY292ZXJ5LgoK
DgoHBAADAAQAARIDLwkWCoEBCggEAAMABAACABIDMgYlGnAgVW5zcGVjaWZpZWQuIFNldHRp
bmcgdGhlIG1vZGUgd2l0aCB0aGlzIHZhbHVlIHdpbGwgZGlzYWJsZQogaW5jbHVzaW9uL2V4
Y2x1c2lvbiBmaWx0ZXJpbmcgZm9yIEFzc2V0IERpc2NvdmVyeS4KChAKCQQAAwAEAAIAARID
MgYgChAKCQQAAwAEAAIAAhIDMiMkCocBCggEAAMABAACARIDNgYXGnYgQXNzZXQgRGlzY292
ZXJ5IHdpbGwgY2FwdHVyZSBvbmx5IHRoZSByZXNvdXJjZXMgd2l0aGluIHRoZSBwcm9qZWN0
cwogc3BlY2lmaWVkLiBBbGwgb3RoZXIgcmVzb3VyY2VzIHdpbGwgYmUgaWdub3JlZC4KChAK
CQQAAwAEAAIBARIDNgYSChAKCQQAAwAEAAIBAhIDNhUWCoIBCggEAAMABAACAhIDOgYSGnEg
QXNzZXQgRGlzY292ZXJ5IHdpbGwgaWdub3JlIGFsbCByZXNvdXJjZXMgdW5kZXIgdGhlIHBy
b2plY3RzIHNwZWNpZmllZC4KIEFsbCBvdGhlciByZXNvdXJjZXMgd2lsbCBiZSByZXRyaWV2
ZWQuCgoQCgkEAAMABAACAgESAzoGDQoQCgkEAAMABAACAgISAzoQEQpGCgYEAAMAAgASAz4E
JBo3IFRoZSBwcm9qZWN0IGlkcyB0byB1c2UgZm9yIGZpbHRlcmluZyBhc3NldCBkaXNjb3Zl
cnkuCgoOCgcEAAMAAgAEEgM+BAwKDgoHBAADAAIABRIDPg0TCg4KBwQAAwACAAESAz4UHwoO
CgcEAAMAAgADEgM+IiMKPwoGBAADAAIBEgNBBCUaMCBUaGUgbW9kZSB0byB1c2UgZm9yIGZp
bHRlcmluZyBhc3NldCBkaXNjb3ZlcnkuCgoOCgcEAAMAAgEGEgNBBBEKDgoHBAADAAIBARID
QRIgCg4KBwQAAwACAQMSA0EjJAp2CgYEAAMAAgISA0UEIxpnIFRoZSBmb2xkZXIgaWRzIHRv
IHVzZSBmb3IgZmlsdGVyaW5nIGFzc2V0IGRpc2NvdmVyeS4KIEl0IGNvbnNpc3RzIG9mIG9u
bHkgZGlnaXRzLCBlLmcuLCA3NTY2MTk2NTQ5NjYuCgoOCgcEAAMAAgIEEgNFBAwKDgoHBAAD
AAICBRIDRQ0TCg4KBwQAAwACAgESA0UUHgoOCgcEAAMAAgIDEgNFISIKzwEKBAQAAgASA0wC
EhrBASBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgc2V0dGluZ3MuIFNlZToK
IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcyNy
ZWxhdGl2ZV9yZXNvdXJjZV9uYW1lCiBFeGFtcGxlOgogIm9yZ2FuaXphdGlvbnMve29yZ2Fu
aXphdGlvbl9pZH0vb3JnYW5pemF0aW9uU2V0dGluZ3MiLgoKDAoFBAACAAUSA0wCCAoMCgUE
AAIAARIDTAkNCgwKBQQAAgADEgNMEBEK/AEKBAQAAgESA1ICIhruASBBIGZsYWcgdGhhdCBp
bmRpY2F0ZXMgaWYgQXNzZXQgRGlzY292ZXJ5IHNob3VsZCBiZSBlbmFibGVkLiBJZiB0aGUg
ZmxhZyBpcwogc2V0IHRvIGB0cnVlYCwgdGhlbiBkaXNjb3Zlcnkgb2YgYXNzZXRzIHdpbGwg
b2NjdXIuIElmIGl0IGlzIHNldCB0bwogYGZhbHNlYCwgYWxsIGhpc3RvcmljYWwgYXNzZXRz
IHdpbGwgcmVtYWluLCBidXQgZGlzY292ZXJ5IG9mIGZ1dHVyZSBhc3NldHMKIHdpbGwgbm90
IG9jY3VyLgoKDAoFBAACAQUSA1ICBgoMCgUEAAIBARIDUgcdCgwKBQQAAgEDEgNSICEKPwoE
BAACAhIDVQIyGjIgVGhlIGNvbmZpZ3VyYXRpb24gdXNlZCBmb3IgQXNzZXQgRGlzY292ZXJ5
IHJ1bnMuCgoMCgUEAAICBhIDVQIWCgwKBQQAAgIBEgNVFy0KDAoFBAACAgMSA1UwMWIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings ===
    # Fields for OrganizationSettings
    # Field: name Type: 9 ()
    # Field: enable_asset_discovery Type: 8 ()
    # Field: asset_discovery_config Type: 11 (.google.cloud.securitycenter.v1.OrganizationSettings.AssetDiscoveryConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::OrganizationSettings - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/organization_settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::OrganizationSettings;

    my $msg = Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings->new({
        name => $name,
        enable_asset_discovery => $enable_asset_discovery,
        asset_discovery_config => $asset_discovery_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/organization_settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings

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
set to `true`, then discovery of assets will occur. If it is set to
`false`, all historical assets will remain, but discovery of future assets
will not occur.

=item * C<< $msg->asset_discovery_config() >> / C<< $msg->asset_discovery_config($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::OrganizationSettings::OrganizationSettings::AssetDiscoveryConfig>)

The configuration used for Asset Discovery runs.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::OrganizationSettings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
