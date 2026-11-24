package Google::Appengine::V1beta::DomainMapping;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9kb21haW5fbWFwcGluZy5wcm90bxIXZ29vZ2xl
LmFwcGVuZ2luZS52MWJldGEi0AEKDURvbWFpbk1hcHBpbmcSEgoEbmFtZRgBIAEoCVIEbmFt
ZRIOCgJpZBgCIAEoCVICaWQSRwoMc3NsX3NldHRpbmdzGAMgASgLMiQuZ29vZ2xlLmFwcGVu
Z2luZS52MWJldGEuU3NsU2V0dGluZ3NSC3NzbFNldHRpbmdzElIKEHJlc291cmNlX3JlY29y
ZHMYBCADKAsyJy5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5SZXNvdXJjZVJlY29yZFIPcmVz
b3VyY2VSZWNvcmRzIpECCgtTc2xTZXR0aW5ncxIlCg5jZXJ0aWZpY2F0ZV9pZBgBIAEoCVIN
Y2VydGlmaWNhdGVJZBJmChNzc2xfbWFuYWdlbWVudF90eXBlGAMgASgOMjYuZ29vZ2xlLmFw
cGVuZ2luZS52MWJldGEuU3NsU2V0dGluZ3MuU3NsTWFuYWdlbWVudFR5cGVSEXNzbE1hbmFn
ZW1lbnRUeXBlEkMKHnBlbmRpbmdfbWFuYWdlZF9jZXJ0aWZpY2F0ZV9pZBgEIAEoCVIbcGVu
ZGluZ01hbmFnZWRDZXJ0aWZpY2F0ZUlkIi4KEVNzbE1hbmFnZW1lbnRUeXBlEg0KCUFVVE9N
QVRJQxAAEgoKBk1BTlVBTBABIq4BCg5SZXNvdXJjZVJlY29yZBISCgRuYW1lGAEgASgJUgRu
YW1lEhYKBnJyZGF0YRgCIAEoCVIGcnJkYXRhEkYKBHR5cGUYAyABKA4yMi5nb29nbGUuYXBw
ZW5naW5lLnYxYmV0YS5SZXNvdXJjZVJlY29yZC5SZWNvcmRUeXBlUgR0eXBlIigKClJlY29y
ZFR5cGUSBQoBQRAAEggKBEFBQUEQARIJCgVDTkFNRRACQtgBChtjb20uZ29vZ2xlLmFwcGVu
Z2luZS52MWJldGFCEkRvbWFpbk1hcHBpbmdQcm90b1ABWkBnb29nbGUuZ29sYW5nLm9yZy9n
ZW5wcm90by9nb29nbGVhcGlzL2FwcGVuZ2luZS92MWJldGE7YXBwZW5naW5lqgIdR29vZ2xl
LkNsb3VkLkFwcEVuZ2luZS5WMUJldGHKAh1Hb29nbGVcQ2xvdWRcQXBwRW5naW5lXFYxYmV0
YeoCIEdvb2dsZTo6Q2xvdWQ6OkFwcEVuZ2luZTo6VjFiZXRhSughCgYSBA4AdQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCAoBCBIDEwA6CgkKAggl
EgMTADoKCAoBCBIDFABXCgkKAggLEgMUAFcKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBID
FgAzCgkKAggIEgMWADMKCAoBCBIDFwA0CgkKAggBEgMXADQKCAoBCBIDGAA6CgkKAggpEgMY
ADoKCAoBCBIDGQA5CgkKAggtEgMZADkKOQoCBAASBBwAMQEaLSBBIGRvbWFpbiBzZXJ2aW5n
IGFuIEFwcCBFbmdpbmUgYXBwbGljYXRpb24uCgoKCgMEAAESAxwIFQqEAQoEBAACABIDIQIS
GncgRnVsbCBwYXRoIHRvIHRoZSBgRG9tYWluTWFwcGluZ2AgcmVzb3VyY2UgaW4gdGhlIEFQ
SS4gRXhhbXBsZToKIGBhcHBzL215YXBwL2RvbWFpbk1hcHBpbmcvZXhhbXBsZS5jb21gLgoK
IEBPdXRwdXRPbmx5CgoMCgUEAAIABRIDIQIICgwKBQQAAgABEgMhCQ0KDAoFBAACAAMSAyEQ
EQpcCgQEAAIBEgMlAhAaTyBSZWxhdGl2ZSBuYW1lIG9mIHRoZSBkb21haW4gc2VydmluZyB0
aGUgYXBwbGljYXRpb24uIEV4YW1wbGU6CiBgZXhhbXBsZS5jb21gLgoKDAoFBAACAQUSAyUC
CAoMCgUEAAIBARIDJQkLCgwKBQQAAgEDEgMlDg8KaAoEBAACAhIDKQIfGlsgU1NMIGNvbmZp
Z3VyYXRpb24gZm9yIHRoaXMgZG9tYWluLiBJZiB1bmNvbmZpZ3VyZWQsIHRoaXMgZG9tYWlu
IHdpbGwgbm90CiBzZXJ2ZSB3aXRoIFNTTC4KCgwKBQQAAgIGEgMpAg0KDAoFBAACAgESAykO
GgoMCgUEAAICAxIDKR0eCtgBCgQEAAIDEgMwAi8aygEgVGhlIHJlc291cmNlIHJlY29yZHMg
cmVxdWlyZWQgdG8gY29uZmlndXJlIHRoaXMgZG9tYWluIG1hcHBpbmcuIFRoZXNlCiByZWNv
cmRzIG11c3QgYmUgYWRkZWQgdG8gdGhlIGRvbWFpbidzIEROUyBjb25maWd1cmF0aW9uIGlu
IG9yZGVyIHRvCiBzZXJ2ZSB0aGUgYXBwbGljYXRpb24gdmlhIHRoaXMgZG9tYWluIG1hcHBp
bmcuCgogQE91dHB1dE9ubHkKCgwKBQQAAgMEEgMwAgoKDAoFBAACAwYSAzALGQoMCgUEAAID
ARIDMBoqCgwKBQQAAgMDEgMwLS4KPwoCBAESBDQAWwEaMyBTU0wgY29uZmlndXJhdGlvbiBm
b3IgYSBgRG9tYWluTWFwcGluZ2AgcmVzb3VyY2UuCgoKCgMEAQESAzQIEwo4CgQEAQQAEgQ2
Aj8DGiogVGhlIFNTTCBtYW5hZ2VtZW50IHR5cGUgZm9yIHRoaXMgZG9tYWluLgoKDAoFBAEE
AAESAzYHGAqEAQoGBAEEAAIAEgM5BBIadSBTU0wgc3VwcG9ydCBmb3IgdGhpcyBkb21haW4g
aXMgY29uZmlndXJlZCBhdXRvbWF0aWNhbGx5LiBUaGUgbWFwcGVkIFNTTAogY2VydGlmaWNh
dGUgd2lsbCBiZSBhdXRvbWF0aWNhbGx5IHJlbmV3ZWQuCgoOCgcEAQQAAgABEgM5BA0KDgoH
BAEEAAIAAhIDORARCsUBCgYEAQQAAgESAz4EDxq1ASBTU0wgc3VwcG9ydCBmb3IgdGhpcyBk
b21haW4gaXMgY29uZmlndXJlZCBtYW51YWxseSBieSB0aGUgdXNlci4gRWl0aGVyCiB0aGUg
ZG9tYWluIGhhcyBubyBTU0wgc3VwcG9ydCBvciBhIHVzZXItb2J0YWluZWQgU1NMIGNlcnRp
ZmljYXRlIGhhcyBiZWVuCiBleHBsaWN0bHkgbWFwcGVkIHRvIHRoaXMgZG9tYWluLgoKDgoH
BAEEAAIBARIDPgQKCg4KBwQBBAACAQISAz4NDgrvAwoEBAECABIDSgIcGuEDIElEIG9mIHRo
ZSBgQXV0aG9yaXplZENlcnRpZmljYXRlYCByZXNvdXJjZSBjb25maWd1cmluZyBTU0wgZm9y
IHRoZQogYXBwbGljYXRpb24uIENsZWFyaW5nIHRoaXMgZmllbGQgd2lsbCByZW1vdmUgU1NM
IHN1cHBvcnQuCgogQnkgZGVmYXVsdCwgYSBtYW5hZ2VkIGNlcnRpZmljYXRlIGlzIGF1dG9t
YXRpY2FsbHkgY3JlYXRlZCBmb3IgZXZlcnkKIGRvbWFpbiBtYXBwaW5nLiBUbyBvbWl0IFNT
TCBzdXBwb3J0IG9yIHRvIGNvbmZpZ3VyZSBTU0wgbWFudWFsbHksIHNwZWNpZnkKIGBTc2xN
YW5hZ2VtZW50VHlwZS5NQU5VQUxgIG9uIGEgYENSRUFURWAgb3IgYFVQREFURWAgcmVxdWVz
dC4gWW91IG11c3QKIGJlIGF1dGhvcml6ZWQgdG8gYWRtaW5pc3RlciB0aGUgYEF1dGhvcml6
ZWRDZXJ0aWZpY2F0ZWAgcmVzb3VyY2UgdG8KIG1hbnVhbGx5IG1hcCBpdCB0byBhIGBEb21h
aW5NYXBwaW5nYCByZXNvdXJjZS4KIEV4YW1wbGU6IGAxMjM0NWAuCgoMCgUEAQIABRIDSgII
CgwKBQQBAgABEgNKCRcKDAoFBAECAAMSA0oaGwreAQoEBAECARIDTwIsGtABIFNTTCBtYW5h
Z2VtZW50IHR5cGUgZm9yIHRoaXMgZG9tYWluLiBJZiBgQVVUT01BVElDYCwgYSBtYW5hZ2Vk
IGNlcnRpZmljYXRlCiBpcyBhdXRvbWF0aWNhbGx5IHByb3Zpc2lvbmVkLiBJZiBgTUFOVUFM
YCwgYGNlcnRpZmljYXRlX2lkYCBtdXN0IGJlCiBtYW51YWxseSBzcGVjaWZpZWQgaW4gb3Jk
ZXIgdG8gY29uZmlndXJlIFNTTCBmb3IgdGhpcyBkb21haW4uCgoMCgUEAQIBBhIDTwITCgwK
BQQBAgEBEgNPFCcKDAoFBAECAQMSA08qKwqSBAoEBAECAhIDWgIsGoQEIElEIG9mIHRoZSBt
YW5hZ2VkIGBBdXRob3JpemVkQ2VydGlmaWNhdGVgIHJlc291cmNlIGN1cnJlbnRseSBiZWlu
ZwogcHJvdmlzaW9uZWQsIGlmIGFwcGxpY2FibGUuIFVudGlsIHRoZSBuZXcgbWFuYWdlZCBj
ZXJ0aWZpY2F0ZSBoYXMgYmVlbgogc3VjY2Vzc2Z1bGx5IHByb3Zpc2lvbmVkLCB0aGUgcHJl
dmlvdXMgU1NMIHN0YXRlIHdpbGwgYmUgcHJlc2VydmVkLiBPbmNlCiB0aGUgcHJvdmlzaW9u
aW5nIHByb2Nlc3MgY29tcGxldGVzLCB0aGUgYGNlcnRpZmljYXRlX2lkYCBmaWVsZCB3aWxs
IHJlZmxlY3QKIHRoZSBuZXcgbWFuYWdlZCBjZXJ0aWZpY2F0ZSBhbmQgdGhpcyBmaWVsZCB3
aWxsIGJlIGxlZnQgZW1wdHkuIFRvIHJlbW92ZQogU1NMIHN1cHBvcnQgd2hpbGUgdGhlcmUg
aXMgc3RpbGwgYSBwZW5kaW5nIG1hbmFnZWQgY2VydGlmaWNhdGUsIGNsZWFyIHRoZQogYGNl
cnRpZmljYXRlX2lkYCBmaWVsZCB3aXRoIGFuIGBVcGRhdGVEb21haW5NYXBwaW5nUmVxdWVz
dGAuCgogQE91dHB1dE9ubHkKCgwKBQQBAgIFEgNaAggKDAoFBAECAgESA1oJJwoMCgUEAQIC
AxIDWiorCiQKAgQCEgReAHUBGhggQSBETlMgcmVzb3VyY2UgcmVjb3JkLgoKCgoDBAIBEgNe
CBYKJwoEBAIEABIEYAJpAxoZIEEgcmVzb3VyY2UgcmVjb3JkIHR5cGUuCgoMCgUEAgQAARID
YAcRCj8KBgQCBAACABIDYgQKGjAgQW4gQSByZXNvdXJjZSByZWNvcmQuIERhdGEgaXMgYW4g
SVB2NCBhZGRyZXNzLgoKDgoHBAIEAAIAARIDYgQFCg4KBwQCBAACAAISA2IICQpCCgYEAgQA
AgESA2UEDRozIEFuIEFBQUEgcmVzb3VyY2UgcmVjb3JkLiBEYXRhIGlzIGFuIElQdjYgYWRk
cmVzcy4KCg4KBwQCBAACAQESA2UECAoOCgcEAgQAAgECEgNlCwwKTgoGBAIEAAICEgNoBA4a
PyBBIENOQU1FIHJlc291cmNlIHJlY29yZC4gRGF0YSBpcyBhIGRvbWFpbiBuYW1lIHRvIGJl
IGFsaWFzZWQuCgoOCgcEAgQAAgIBEgNoBAkKDgoHBAIEAAICAhIDaAwNCnkKBAQCAgASA20C
EhpsIFJlbGF0aXZlIG5hbWUgb2YgdGhlIG9iamVjdCBhZmZlY3RlZCBieSB0aGlzIHJlY29y
ZC4gT25seSBhcHBsaWNhYmxlIGZvcgogYENOQU1FYCByZWNvcmRzLiBFeGFtcGxlOiAnd3d3
Jy4KCgwKBQQCAgAFEgNtAggKDAoFBAICAAESA20JDQoMCgUEAgIAAxIDbRARCoIBCgQEAgIB
EgNxAhQadSBEYXRhIGZvciB0aGlzIHJlY29yZC4gVmFsdWVzIHZhcnkgYnkgcmVjb3JkIHR5
cGUsIGFzIGRlZmluZWQgaW4gUkZDIDEwMzUKIChzZWN0aW9uIDUpIGFuZCBSRkMgMTAzNCAo
c2VjdGlvbiAzLjYuMSkuCgoMCgUEAgIBBRIDcQIICgwKBQQCAgEBEgNxCQ8KDAoFBAICAQMS
A3ESEwo1CgQEAgICEgN0AhYaKCBSZXNvdXJjZSByZWNvcmQgdHlwZS4gRXhhbXBsZTogYEFB
QUFgLgoKDAoFBAICAgYSA3QCDAoMCgUEAgICARIDdA0RCgwKBQQCAgIDEgN0FBViBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::DomainMapping::DomainMapping ===
    # Fields for DomainMapping
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: ssl_settings Type: 11 (.google.appengine.v1beta.SslSettings)
    # Field: resource_records Type: 11 (.google.appengine.v1beta.ResourceRecord)

# === Message: Google::Appengine::V1beta::DomainMapping::SslSettings ===
    # Fields for SslSettings
    # Field: certificate_id Type: 9 ()
    # Field: ssl_management_type Type: 14 (.google.appengine.v1beta.SslSettings.SslManagementType)
    # Field: pending_managed_certificate_id Type: 9 ()

# Enum: SslSettings::SslManagementType
our $SslSettings_AUTOMATIC = 0;
our $SslSettings_MANUAL = 1;

# === Message: Google::Appengine::V1beta::DomainMapping::ResourceRecord ===
    # Fields for ResourceRecord
    # Field: name Type: 9 ()
    # Field: rrdata Type: 9 ()
    # Field: type Type: 14 (.google.appengine.v1beta.ResourceRecord.RecordType)

# Enum: ResourceRecord::RecordType
our $ResourceRecord_A = 0;
our $ResourceRecord_AAAA = 1;
our $ResourceRecord_CNAME = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::DomainMapping - Compiled Protocol Buffers messages for google/appengine/v1beta/domain_mapping.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::DomainMapping;

    my $msg = Google::Appengine::V1beta::DomainMapping::DomainMapping->new({
        name => $name,
        id => $id,
        ssl_settings => $ssl_settings,
        resource_records => $resource_records,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::DomainMapping::DomainMapping->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/domain_mapping.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::DomainMapping::DomainMapping

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

Type: C<Message> (L<Google::Appengine::V1beta::DomainMapping::SslSettings>)

SSL configuration for this domain. If unconfigured, this domain will not
serve with SSL.

=item * C<< $msg->resource_records() >> / C<< $msg->resource_records($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::DomainMapping::ResourceRecord>)

The resource records required to configure this domain mapping. These
records must be added to the domain's DNS configuration in order to
serve the application via this domain mapping.

@OutputOnly

=back

=head2 Google::Appengine::V1beta::DomainMapping::SslSettings

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

Type: C<Enum> (L<Google::Appengine::V1beta::SslSettings::SslManagementType>)

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

=item * C<AUTOMATIC> => C<0>

=item * C<MANUAL> => C<1>

=back

=head2 Google::Appengine::V1beta::DomainMapping::ResourceRecord

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

Type: C<Enum> (L<Google::Appengine::V1beta::ResourceRecord::RecordType>)

Resource record type. Example: `AAAA`.

=back

=head3 Enum: ResourceRecord::RecordType

=over 4

=item * C<A> => C<0>

=item * C<AAAA> => C<1>

=item * C<CNAME> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::DomainMapping::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
