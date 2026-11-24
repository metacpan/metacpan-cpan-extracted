package Google::Appengine::V1::DomainMapping;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvYXBwZW5naW5lL3YxL2RvbWFpbl9tYXBwaW5nLnByb3RvEhNnb29nbGUuYXBw
ZW5naW5lLnYxIsgBCg1Eb21haW5NYXBwaW5nEhIKBG5hbWUYASABKAlSBG5hbWUSDgoCaWQY
AiABKAlSAmlkEkMKDHNzbF9zZXR0aW5ncxgDIAEoCzIgLmdvb2dsZS5hcHBlbmdpbmUudjEu
U3NsU2V0dGluZ3NSC3NzbFNldHRpbmdzEk4KEHJlc291cmNlX3JlY29yZHMYBCADKAsyIy5n
b29nbGUuYXBwZW5naW5lLnYxLlJlc291cmNlUmVjb3JkUg9yZXNvdXJjZVJlY29yZHMisgIK
C1NzbFNldHRpbmdzEiUKDmNlcnRpZmljYXRlX2lkGAEgASgJUg1jZXJ0aWZpY2F0ZUlkEmIK
E3NzbF9tYW5hZ2VtZW50X3R5cGUYAyABKA4yMi5nb29nbGUuYXBwZW5naW5lLnYxLlNzbFNl
dHRpbmdzLlNzbE1hbmFnZW1lbnRUeXBlUhFzc2xNYW5hZ2VtZW50VHlwZRJDCh5wZW5kaW5n
X21hbmFnZWRfY2VydGlmaWNhdGVfaWQYBCABKAlSG3BlbmRpbmdNYW5hZ2VkQ2VydGlmaWNh
dGVJZCJTChFTc2xNYW5hZ2VtZW50VHlwZRIjCh9TU0xfTUFOQUdFTUVOVF9UWVBFX1VOU1BF
Q0lGSUVEEAASDQoJQVVUT01BVElDEAESCgoGTUFOVUFMEAIixwEKDlJlc291cmNlUmVjb3Jk
EhIKBG5hbWUYASABKAlSBG5hbWUSFgoGcnJkYXRhGAIgASgJUgZycmRhdGESQgoEdHlwZRgD
IAEoDjIuLmdvb2dsZS5hcHBlbmdpbmUudjEuUmVzb3VyY2VSZWNvcmQuUmVjb3JkVHlwZVIE
dHlwZSJFCgpSZWNvcmRUeXBlEhsKF1JFQ09SRF9UWVBFX1VOU1BFQ0lGSUVEEAASBQoBQRAB
EggKBEFBQUEQAhIJCgVDTkFNRRADQsMBChdjb20uZ29vZ2xlLmFwcGVuZ2luZS52MUISRG9t
YWluTWFwcGluZ1Byb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vYXBwZW5naW5lL2FwaXYx
L2FwcGVuZ2luZXBiO2FwcGVuZ2luZXBiqgIZR29vZ2xlLkNsb3VkLkFwcEVuZ2luZS5WMcoC
GUdvb2dsZVxDbG91ZFxBcHBFbmdpbmVcVjHqAhxHb29nbGU6OkNsb3VkOjpBcHBFbmdpbmU6
OlYxSoEjCgYSBA4AegEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQABwKCAoBCBIDEgA2CgkKAgglEgMSADYKCAoBCBIDEwBSCgkKAggLEgMTAFIKCAoBCBID
FAAiCgkKAggKEgMUACIKCAoBCBIDFQAzCgkKAggIEgMVADMKCAoBCBIDFgAwCgkKAggBEgMW
ADAKCAoBCBIDFwA2CgkKAggpEgMXADYKCAoBCBIDGAA1CgkKAggtEgMYADUKOQoCBAASBBsA
MAEaLSBBIGRvbWFpbiBzZXJ2aW5nIGFuIEFwcCBFbmdpbmUgYXBwbGljYXRpb24uCgoKCgME
AAESAxsIFQqEAQoEBAACABIDIAISGncgRnVsbCBwYXRoIHRvIHRoZSBgRG9tYWluTWFwcGlu
Z2AgcmVzb3VyY2UgaW4gdGhlIEFQSS4gRXhhbXBsZToKIGBhcHBzL215YXBwL2RvbWFpbk1h
cHBpbmcvZXhhbXBsZS5jb21gLgoKIEBPdXRwdXRPbmx5CgoMCgUEAAIABRIDIAIICgwKBQQA
AgABEgMgCQ0KDAoFBAACAAMSAyAQEQpcCgQEAAIBEgMkAhAaTyBSZWxhdGl2ZSBuYW1lIG9m
IHRoZSBkb21haW4gc2VydmluZyB0aGUgYXBwbGljYXRpb24uIEV4YW1wbGU6CiBgZXhhbXBs
ZS5jb21gLgoKDAoFBAACAQUSAyQCCAoMCgUEAAIBARIDJAkLCgwKBQQAAgEDEgMkDg8KaAoE
BAACAhIDKAIfGlsgU1NMIGNvbmZpZ3VyYXRpb24gZm9yIHRoaXMgZG9tYWluLiBJZiB1bmNv
bmZpZ3VyZWQsIHRoaXMgZG9tYWluIHdpbGwgbm90CiBzZXJ2ZSB3aXRoIFNTTC4KCgwKBQQA
AgIGEgMoAg0KDAoFBAACAgESAygOGgoMCgUEAAICAxIDKB0eCtgBCgQEAAIDEgMvAi8aygEg
VGhlIHJlc291cmNlIHJlY29yZHMgcmVxdWlyZWQgdG8gY29uZmlndXJlIHRoaXMgZG9tYWlu
IG1hcHBpbmcuIFRoZXNlCiByZWNvcmRzIG11c3QgYmUgYWRkZWQgdG8gdGhlIGRvbWFpbidz
IEROUyBjb25maWd1cmF0aW9uIGluIG9yZGVyIHRvCiBzZXJ2ZSB0aGUgYXBwbGljYXRpb24g
dmlhIHRoaXMgZG9tYWluIG1hcHBpbmcuCgogQE91dHB1dE9ubHkKCgwKBQQAAgMEEgMvAgoK
DAoFBAACAwYSAy8LGQoMCgUEAAIDARIDLxoqCgwKBQQAAgMDEgMvLS4KPwoCBAESBDMAXQEa
MyBTU0wgY29uZmlndXJhdGlvbiBmb3IgYSBgRG9tYWluTWFwcGluZ2AgcmVzb3VyY2UuCgoK
CgMEAQESAzMIEwo4CgQEAQQAEgQ1AkEDGiogVGhlIFNTTCBtYW5hZ2VtZW50IHR5cGUgZm9y
IHRoaXMgZG9tYWluLgoKDAoFBAEEAAESAzUHGAopCgYEAQQAAgASAzcEKBoaIERlZmF1bHRz
IHRvIGBBVVRPTUFUSUNgLgoKDgoHBAEEAAIAARIDNwQjCg4KBwQBBAACAAISAzcmJwqEAQoG
BAEEAAIBEgM7BBIadSBTU0wgc3VwcG9ydCBmb3IgdGhpcyBkb21haW4gaXMgY29uZmlndXJl
ZCBhdXRvbWF0aWNhbGx5LiBUaGUgbWFwcGVkIFNTTAogY2VydGlmaWNhdGUgd2lsbCBiZSBh
dXRvbWF0aWNhbGx5IHJlbmV3ZWQuCgoOCgcEAQQAAgEBEgM7BA0KDgoHBAEEAAIBAhIDOxAR
CsUBCgYEAQQAAgISA0AEDxq1ASBTU0wgc3VwcG9ydCBmb3IgdGhpcyBkb21haW4gaXMgY29u
ZmlndXJlZCBtYW51YWxseSBieSB0aGUgdXNlci4gRWl0aGVyCiB0aGUgZG9tYWluIGhhcyBu
byBTU0wgc3VwcG9ydCBvciBhIHVzZXItb2J0YWluZWQgU1NMIGNlcnRpZmljYXRlIGhhcyBi
ZWVuCiBleHBsaWN0bHkgbWFwcGVkIHRvIHRoaXMgZG9tYWluLgoKDgoHBAEEAAICARIDQAQK
Cg4KBwQBBAACAgISA0ANDgrvAwoEBAECABIDTAIcGuEDIElEIG9mIHRoZSBgQXV0aG9yaXpl
ZENlcnRpZmljYXRlYCByZXNvdXJjZSBjb25maWd1cmluZyBTU0wgZm9yIHRoZQogYXBwbGlj
YXRpb24uIENsZWFyaW5nIHRoaXMgZmllbGQgd2lsbCByZW1vdmUgU1NMIHN1cHBvcnQuCgog
QnkgZGVmYXVsdCwgYSBtYW5hZ2VkIGNlcnRpZmljYXRlIGlzIGF1dG9tYXRpY2FsbHkgY3Jl
YXRlZCBmb3IgZXZlcnkKIGRvbWFpbiBtYXBwaW5nLiBUbyBvbWl0IFNTTCBzdXBwb3J0IG9y
IHRvIGNvbmZpZ3VyZSBTU0wgbWFudWFsbHksIHNwZWNpZnkKIGBTc2xNYW5hZ2VtZW50VHlw
ZS5NQU5VQUxgIG9uIGEgYENSRUFURWAgb3IgYFVQREFURWAgcmVxdWVzdC4gWW91IG11c3QK
IGJlIGF1dGhvcml6ZWQgdG8gYWRtaW5pc3RlciB0aGUgYEF1dGhvcml6ZWRDZXJ0aWZpY2F0
ZWAgcmVzb3VyY2UgdG8KIG1hbnVhbGx5IG1hcCBpdCB0byBhIGBEb21haW5NYXBwaW5nYCBy
ZXNvdXJjZS4KIEV4YW1wbGU6IGAxMjM0NWAuCgoMCgUEAQIABRIDTAIICgwKBQQBAgABEgNM
CRcKDAoFBAECAAMSA0waGwreAQoEBAECARIDUQIsGtABIFNTTCBtYW5hZ2VtZW50IHR5cGUg
Zm9yIHRoaXMgZG9tYWluLiBJZiBgQVVUT01BVElDYCwgYSBtYW5hZ2VkIGNlcnRpZmljYXRl
CiBpcyBhdXRvbWF0aWNhbGx5IHByb3Zpc2lvbmVkLiBJZiBgTUFOVUFMYCwgYGNlcnRpZmlj
YXRlX2lkYCBtdXN0IGJlCiBtYW51YWxseSBzcGVjaWZpZWQgaW4gb3JkZXIgdG8gY29uZmln
dXJlIFNTTCBmb3IgdGhpcyBkb21haW4uCgoMCgUEAQIBBhIDUQITCgwKBQQBAgEBEgNRFCcK
DAoFBAECAQMSA1EqKwqSBAoEBAECAhIDXAIsGoQEIElEIG9mIHRoZSBtYW5hZ2VkIGBBdXRo
b3JpemVkQ2VydGlmaWNhdGVgIHJlc291cmNlIGN1cnJlbnRseSBiZWluZwogcHJvdmlzaW9u
ZWQsIGlmIGFwcGxpY2FibGUuIFVudGlsIHRoZSBuZXcgbWFuYWdlZCBjZXJ0aWZpY2F0ZSBo
YXMgYmVlbgogc3VjY2Vzc2Z1bGx5IHByb3Zpc2lvbmVkLCB0aGUgcHJldmlvdXMgU1NMIHN0
YXRlIHdpbGwgYmUgcHJlc2VydmVkLiBPbmNlCiB0aGUgcHJvdmlzaW9uaW5nIHByb2Nlc3Mg
Y29tcGxldGVzLCB0aGUgYGNlcnRpZmljYXRlX2lkYCBmaWVsZCB3aWxsIHJlZmxlY3QKIHRo
ZSBuZXcgbWFuYWdlZCBjZXJ0aWZpY2F0ZSBhbmQgdGhpcyBmaWVsZCB3aWxsIGJlIGxlZnQg
ZW1wdHkuIFRvIHJlbW92ZQogU1NMIHN1cHBvcnQgd2hpbGUgdGhlcmUgaXMgc3RpbGwgYSBw
ZW5kaW5nIG1hbmFnZWQgY2VydGlmaWNhdGUsIGNsZWFyIHRoZQogYGNlcnRpZmljYXRlX2lk
YCBmaWVsZCB3aXRoIGFuIGBVcGRhdGVEb21haW5NYXBwaW5nUmVxdWVzdGAuCgogQE91dHB1
dE9ubHkKCgwKBQQBAgIFEgNcAggKDAoFBAECAgESA1wJJwoMCgUEAQICAxIDXCorCiQKAgQC
EgRgAHoBGhggQSBETlMgcmVzb3VyY2UgcmVjb3JkLgoKCgoDBAIBEgNgCBYKJwoEBAIEABIE
YgJuAxoZIEEgcmVzb3VyY2UgcmVjb3JkIHR5cGUuCgoMCgUEAgQAARIDYgcRCiwKBgQCBAAC
ABIDZAQgGh0gQW4gdW5rbm93biByZXNvdXJjZSByZWNvcmQuCgoOCgcEAgQAAgABEgNkBBsK
DgoHBAIEAAIAAhIDZB4fCj8KBgQCBAACARIDZwQKGjAgQW4gQSByZXNvdXJjZSByZWNvcmQu
IERhdGEgaXMgYW4gSVB2NCBhZGRyZXNzLgoKDgoHBAIEAAIBARIDZwQFCg4KBwQCBAACAQIS
A2cICQpCCgYEAgQAAgISA2oEDRozIEFuIEFBQUEgcmVzb3VyY2UgcmVjb3JkLiBEYXRhIGlz
IGFuIElQdjYgYWRkcmVzcy4KCg4KBwQCBAACAgESA2oECAoOCgcEAgQAAgICEgNqCwwKTgoG
BAIEAAIDEgNtBA4aPyBBIENOQU1FIHJlc291cmNlIHJlY29yZC4gRGF0YSBpcyBhIGRvbWFp
biBuYW1lIHRvIGJlIGFsaWFzZWQuCgoOCgcEAgQAAgMBEgNtBAkKDgoHBAIEAAIDAhIDbQwN
CnkKBAQCAgASA3ICEhpsIFJlbGF0aXZlIG5hbWUgb2YgdGhlIG9iamVjdCBhZmZlY3RlZCBi
eSB0aGlzIHJlY29yZC4gT25seSBhcHBsaWNhYmxlIGZvcgogYENOQU1FYCByZWNvcmRzLiBF
eGFtcGxlOiAnd3d3Jy4KCgwKBQQCAgAFEgNyAggKDAoFBAICAAESA3IJDQoMCgUEAgIAAxID
chARCoIBCgQEAgIBEgN2AhQadSBEYXRhIGZvciB0aGlzIHJlY29yZC4gVmFsdWVzIHZhcnkg
YnkgcmVjb3JkIHR5cGUsIGFzIGRlZmluZWQgaW4gUkZDIDEwMzUKIChzZWN0aW9uIDUpIGFu
ZCBSRkMgMTAzNCAoc2VjdGlvbiAzLjYuMSkuCgoMCgUEAgIBBRIDdgIICgwKBQQCAgEBEgN2
CQ8KDAoFBAICAQMSA3YSEwo1CgQEAgICEgN5AhYaKCBSZXNvdXJjZSByZWNvcmQgdHlwZS4g
RXhhbXBsZTogYEFBQUFgLgoKDAoFBAICAgYSA3kCDAoMCgUEAgICARIDeQ0RCgwKBQQCAgID
EgN5FBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::DomainMapping::DomainMapping ===
    # Fields for DomainMapping
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: ssl_settings Type: 11 (.google.appengine.v1.SslSettings)
    # Field: resource_records Type: 11 (.google.appengine.v1.ResourceRecord)

# === Message: Google::Appengine::V1::DomainMapping::SslSettings ===
    # Fields for SslSettings
    # Field: certificate_id Type: 9 ()
    # Field: ssl_management_type Type: 14 (.google.appengine.v1.SslSettings.SslManagementType)
    # Field: pending_managed_certificate_id Type: 9 ()

# Enum: SslSettings::SslManagementType
our $SslSettings_SSL_MANAGEMENT_TYPE_UNSPECIFIED = 0;
our $SslSettings_AUTOMATIC = 1;
our $SslSettings_MANUAL = 2;

# === Message: Google::Appengine::V1::DomainMapping::ResourceRecord ===
    # Fields for ResourceRecord
    # Field: name Type: 9 ()
    # Field: rrdata Type: 9 ()
    # Field: type Type: 14 (.google.appengine.v1.ResourceRecord.RecordType)

# Enum: ResourceRecord::RecordType
our $ResourceRecord_RECORD_TYPE_UNSPECIFIED = 0;
our $ResourceRecord_A = 1;
our $ResourceRecord_AAAA = 2;
our $ResourceRecord_CNAME = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::DomainMapping - Compiled Protocol Buffers messages for google/appengine/v1/domain_mapping.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::DomainMapping;

    my $msg = Google::Appengine::V1::DomainMapping::DomainMapping->new({
        name => $name,
        id => $id,
        ssl_settings => $ssl_settings,
        resource_records => $resource_records,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::DomainMapping::DomainMapping->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/domain_mapping.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::DomainMapping::DomainMapping

A domain serving an App Engine application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full path to the `DomainMapping` resource in the API. Example:
`apps/myapp/domainMapping/example.com`.

@OutputOnly

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Relative name of the domain serving the application. Example:
`example.com`.

=item * C<< $msg->ssl_settings() >> / C<< $msg->ssl_settings($value) >>

Type: C<Message> (L<Google::Appengine::V1::DomainMapping::SslSettings>)

SSL configuration for this domain. If unconfigured, this domain will not
serve with SSL.

=item * C<< $msg->resource_records() >> / C<< $msg->resource_records($value) >>

Type: C<Message> (L<Google::Appengine::V1::DomainMapping::ResourceRecord>)

The resource records required to configure this domain mapping. These
records must be added to the domain's DNS configuration in order to
serve the application via this domain mapping.

@OutputOnly

=back

=head2 Google::Appengine::V1::DomainMapping::SslSettings

SSL configuration for a `DomainMapping` resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->certificate_id() >> / C<< $msg->certificate_id($value) >>

Type: C<String>

ID of the `AuthorizedCertificate` resource configuring SSL for the
application. Clearing this field will remove SSL support.

By default, a managed certificate is automatically created for every
domain mapping. To omit SSL support or to configure SSL manually, specify
`SslManagementType.MANUAL` on a `CREATE` or `UPDATE` request. You must
be authorized to administer the `AuthorizedCertificate` resource to
manually map it to a `DomainMapping` resource.
Example: `12345`.

=item * C<< $msg->ssl_management_type() >> / C<< $msg->ssl_management_type($value) >>

Type: C<Enum> (L<Google::Appengine::V1::SslSettings::SslManagementType>)

SSL management type for this domain. If `AUTOMATIC`, a managed certificate
is automatically provisioned. If `MANUAL`, `certificate_id` must be
manually specified in order to configure SSL for this domain.

=item * C<< $msg->pending_managed_certificate_id() >> / C<< $msg->pending_managed_certificate_id($value) >>

Type: C<String>

ID of the managed `AuthorizedCertificate` resource currently being
provisioned, if applicable. Until the new managed certificate has been
successfully provisioned, the previous SSL state will be preserved. Once
the provisioning process completes, the `certificate_id` field will reflect
the new managed certificate and this field will be left empty. To remove
SSL support while there is still a pending managed certificate, clear the
`certificate_id` field with an `UpdateDomainMappingRequest`.

@OutputOnly

=back

=head3 Enum: SslSettings::SslManagementType

=over 4

=item * C<SSL_MANAGEMENT_TYPE_UNSPECIFIED> => C<0>

=item * C<AUTOMATIC> => C<1>

=item * C<MANUAL> => C<2>

=back

=head2 Google::Appengine::V1::DomainMapping::ResourceRecord

A DNS resource record.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Relative name of the object affected by this record. Only applicable for
`CNAME` records. Example: 'www'.

=item * C<< $msg->rrdata() >> / C<< $msg->rrdata($value) >>

Type: C<String>

Data for this record. Values vary by record type, as defined in RFC 1035
(section 5) and RFC 1034 (section 3.6.1).

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Appengine::V1::ResourceRecord::RecordType>)

Resource record type. Example: `AAAA`.

=back

=head3 Enum: ResourceRecord::RecordType

=over 4

=item * C<RECORD_TYPE_UNSPECIFIED> => C<0>

=item * C<A> => C<1>

=item * C<AAAA> => C<2>

=item * C<CNAME> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::DomainMapping::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
