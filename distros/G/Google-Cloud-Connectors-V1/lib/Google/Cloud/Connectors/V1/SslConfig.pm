package Google::Cloud::Connectors::V1::SslConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Connectors::V1::Common };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9zc2xfY29uZmlnLnByb3RvEhpnb29nbGUu
Y2xvdWQuY29ubmVjdG9ycy52MRonZ29vZ2xlL2Nsb3VkL2Nvbm5lY3RvcnMvdjEvY29tbW9u
LnByb3RvIoQDChFTc2xDb25maWdUZW1wbGF0ZRI+Cghzc2xfdHlwZRgBIAEoDjIjLmdvb2ds
ZS5jbG91ZC5jb25uZWN0b3JzLnYxLlNzbFR5cGVSB3NzbFR5cGUSKAoQaXNfdGxzX21hbmRh
dG9yeRgCIAEoCFIOaXNUbHNNYW5kYXRvcnkSTgoQc2VydmVyX2NlcnRfdHlwZRgDIAMoDjIk
Lmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkNlcnRUeXBlUg5zZXJ2ZXJDZXJ0VHlwZRJO
ChBjbGllbnRfY2VydF90eXBlGAQgAygOMiQuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEu
Q2VydFR5cGVSDmNsaWVudENlcnRUeXBlEmUKFGFkZGl0aW9uYWxfdmFyaWFibGVzGAUgAygL
MjIuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuQ29uZmlnVmFyaWFibGVUZW1wbGF0ZVIT
YWRkaXRpb25hbFZhcmlhYmxlcyLGBgoJU3NsQ29uZmlnEjcKBHR5cGUYASABKA4yIy5nb29n
bGUuY2xvdWQuY29ubmVjdG9ycy52MS5Tc2xUeXBlUgR0eXBlElEKC3RydXN0X21vZGVsGAIg
ASgOMjAuZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuU3NsQ29uZmlnLlRydXN0TW9kZWxS
CnRydXN0TW9kZWwSYAoacHJpdmF0ZV9zZXJ2ZXJfY2VydGlmaWNhdGUYAyABKAsyIi5nb29n
bGUuY2xvdWQuY29ubmVjdG9ycy52MS5TZWNyZXRSGHByaXZhdGVTZXJ2ZXJDZXJ0aWZpY2F0
ZRJRChJjbGllbnRfY2VydGlmaWNhdGUYBCABKAsyIi5nb29nbGUuY2xvdWQuY29ubmVjdG9y
cy52MS5TZWNyZXRSEWNsaWVudENlcnRpZmljYXRlElAKEmNsaWVudF9wcml2YXRlX2tleRgF
IAEoCzIiLmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLlNlY3JldFIQY2xpZW50UHJpdmF0
ZUtleRJZChdjbGllbnRfcHJpdmF0ZV9rZXlfcGFzcxgGIAEoCzIiLmdvb2dsZS5jbG91ZC5j
b25uZWN0b3JzLnYxLlNlY3JldFIUY2xpZW50UHJpdmF0ZUtleVBhc3MSTgoQc2VydmVyX2Nl
cnRfdHlwZRgHIAEoDjIkLmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxLkNlcnRUeXBlUg5z
ZXJ2ZXJDZXJ0VHlwZRJOChBjbGllbnRfY2VydF90eXBlGAggASgOMiQuZ29vZ2xlLmNsb3Vk
LmNvbm5lY3RvcnMudjEuQ2VydFR5cGVSDmNsaWVudENlcnRUeXBlEhcKB3VzZV9zc2wYCSAB
KAhSBnVzZVNzbBJdChRhZGRpdGlvbmFsX3ZhcmlhYmxlcxgKIAMoCzIqLmdvb2dsZS5jbG91
ZC5jb25uZWN0b3JzLnYxLkNvbmZpZ1ZhcmlhYmxlUhNhZGRpdGlvbmFsVmFyaWFibGVzIjMK
ClRydXN0TW9kZWwSCgoGUFVCTElDEAASCwoHUFJJVkFURRABEgwKCElOU0VDVVJFEAIqNgoH
U3NsVHlwZRIYChRTU0xfVFlQRV9VTlNQRUNJRklFRBAAEgcKA1RMUxABEggKBE1UTFMQAiou
CghDZXJ0VHlwZRIZChVDRVJUX1RZUEVfVU5TUEVDSUZJRUQQABIHCgNQRU0QAUJyCh5jb20u
Z29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjFCDlNzbENvbmZpZ1Byb3RvUAFaPmNsb3VkLmdv
b2dsZS5jb20vZ28vY29ubmVjdG9ycy9hcGl2MS9jb25uZWN0b3JzcGI7Y29ubmVjdG9yc3Bi
SpAZCgYSBA4AbAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACMKCQoCAwASAxIAMQoICgEIEgMUAFUKCQoCCAsSAxQAVQoICgEIEgMVACIKCQoCCAoSAxUA
IgoICgEIEgMWAC8KCQoCCAgSAxYALwoICgEIEgMXADcKCQoCCAESAxcANwo3CgIEABIEGgAp
ARorIFNzbCBjb25maWcgZGV0YWlscyBvZiBhIGNvbm5lY3RvciB2ZXJzaW9uCgoKCgMEAAES
AxoIGQpECgQEAAIAEgMcAhcaNyBDb250cm9scyB0aGUgc3NsIHR5cGUgZm9yIHRoZSBnaXZl
biBjb25uZWN0b3IgdmVyc2lvbgoKDAoFBAACAAYSAxwCCQoMCgUEAAIAARIDHAoSCgwKBQQA
AgADEgMcFRYKTQoEBAACARIDHwIcGkAgQm9vbGVhbiBmb3IgZGV0ZXJtaW5pbmcgaWYgdGhl
IGNvbm5lY3RvciB2ZXJzaW9uIG1hbmRhdGVzIFRMUy4KCgwKBQQAAgEFEgMfAgYKDAoFBAAC
AQESAx8HFwoMCgUEAAIBAxIDHxobCjIKBAQAAgISAyICKRolIExpc3Qgb2Ygc3VwcG9ydGVk
IFNlcnZlciBDZXJ0IFR5cGVzCgoMCgUEAAICBBIDIgIKCgwKBQQAAgIGEgMiCxMKDAoFBAAC
AgESAyIUJAoMCgUEAAICAxIDIicoCjIKBAQAAgMSAyUCKRolIExpc3Qgb2Ygc3VwcG9ydGVk
IENsaWVudCBDZXJ0IFR5cGVzCgoMCgUEAAIDBBIDJQIKCgwKBQQAAgMGEgMlCxMKDAoFBAAC
AwESAyUUJAoMCgUEAAIDAxIDJScoCj0KBAQAAgQSAygCOxowIEFueSBhZGRpdGlvbmFsIGZp
ZWxkcyB0aGF0IG5lZWQgdG8gYmUgcmVuZGVyZWQKCgwKBQQAAgQEEgMoAgoKDAoFBAACBAYS
AygLIQoMCgUEAAIEARIDKCI2CgwKBQQAAgQDEgMoOToKLwoCBAESBCwAVwEaIyBTU0wgQ29u
ZmlndXJhdGlvbiBvZiBhIGNvbm5lY3Rpb24KCgoKAwQBARIDLAgRCiQKBAQBBAASBC4CNwMa
FiBFbnVtIGZvciBUdHVzdCBNb2RlbAoKDAoFBAEEAAESAy4HEQpICgYEAQQAAgASAzAEDxo5
IFB1YmxpYyBUcnVzdCBNb2RlbC4gVGFrZXMgdGhlIERlZmF1bHQgSmF2YSB0cnVzdCBzdG9y
ZS4KCg4KBwQBBAACAAESAzAECgoOCgcEAQQAAgACEgMwDQ4KRwoGBAEEAAIBEgMzBBAaOCBQ
cml2YXRlIFRydXN0IE1vZGVsLiBUYWtlcyBjdXN0b20vcHJpdmF0ZSB0cnVzdCBzdG9yZS4K
Cg4KBwQBBAACAQESAzMECwoOCgcEAQQAAgECEgMzDg8KPwoGBAEEAAICEgM2BBEaMCBJbnNl
Y3VyZSBUcnVzdCBNb2RlbC4gQWNjZXB0IGFsbCBjZXJ0aWZpY2F0ZXMuCgoOCgcEAQQAAgIB
EgM2BAwKDgoHBAEEAAICAhIDNg8QCkUKBAQBAgASAzoCExo4IENvbnRyb2xzIHRoZSBzc2wg
dHlwZSBmb3IgdGhlIGdpdmVuIGNvbm5lY3RvciB2ZXJzaW9uLgoKDAoFBAECAAYSAzoCCQoM
CgUEAQIAARIDOgoOCgwKBQQBAgADEgM6ERIKMAoEBAECARIDPQIdGiMgVHJ1c3QgTW9kZWwg
b2YgdGhlIFNTTCBjb25uZWN0aW9uCgoMCgUEAQIBBhIDPQIMCgwKBQQBAgEBEgM9DRgKDAoF
BAECAQMSAz0bHApeCgQEAQICEgNBAigaUSBQcml2YXRlIFNlcnZlciBDZXJ0aWZpY2F0ZS4g
TmVlZHMgdG8gYmUgc3BlY2lmaWVkIGlmIHRydXN0IG1vZGVsIGlzCiBgUFJJVkFURWAuCgoM
CgUEAQICBhIDQQIICgwKBQQBAgIBEgNBCSMKDAoFBAECAgMSA0EmJwohCgQEAQIDEgNEAiAa
FCBDbGllbnQgQ2VydGlmaWNhdGUKCgwKBQQBAgMGEgNEAggKDAoFBAECAwESA0QJGwoMCgUE
AQIDAxIDRB4fCiEKBAQBAgQSA0cCIBoUIENsaWVudCBQcml2YXRlIEtleQoKDAoFBAECBAYS
A0cCCAoMCgUEAQIEARIDRwkbCgwKBQQBAgQDEgNHHh8KUQoEBAECBRIDSgIlGkQgU2VjcmV0
IGNvbnRhaW5pbmcgdGhlIHBhc3NwaHJhc2UgcHJvdGVjdGluZyB0aGUgQ2xpZW50IFByaXZh
dGUgS2V5CgoMCgUEAQIFBhIDSgIICgwKBQQBAgUBEgNKCSAKDAoFBAECBQMSA0ojJAo0CgQE
AQIGEgNNAiAaJyBUeXBlIG9mIFNlcnZlciBDZXJ0IChQRU0vSktTLy4uIGV0Yy4pCgoMCgUE
AQIGBhIDTQIKCgwKBQQBAgYBEgNNCxsKDAoFBAECBgMSA00eHwo0CgQEAQIHEgNQAiAaJyBU
eXBlIG9mIENsaWVudCBDZXJ0IChQRU0vSktTLy4uIGV0Yy4pCgoMCgUEAQIHBhIDUAIKCgwK
BQQBAgcBEgNQCxsKDAoFBAECBwMSA1AeHwokCgQEAQIIEgNTAhMaFyBCb29sIGZvciBlbmFi
bGluZyBTU0wKCgwKBQQBAggFEgNTAgYKDAoFBAECCAESA1MHDgoMCgUEAQIIAxIDUxESCjIK
BAQBAgkSA1YCNBolIEFkZGl0aW9uYWwgU1NMIHJlbGF0ZWQgZmllbGQgdmFsdWVzCgoMCgUE
AQIJBBIDVgIKCgwKBQQBAgkGEgNWCxkKDAoFBAECCQESA1YaLgoMCgUEAQIJAxIDVjEzCjoK
AgUAEgRaAGMBGi4gRW51bSBmb3IgY29udHJvbGxpbmcgdGhlIFNTTCBUeXBlIChUTFMvTVRM
UykKCgoKAwUAARIDWgUMCi0KBAUAAgASA1wCGxogIE5vIFNTTCBjb25maWd1cmF0aW9uIHJl
cXVpcmVkLgoKDAoFBQACAAESA1wCFgoMCgUFAAIAAhIDXBkaChwKBAUAAgESA18CChoPIFRM
UyBIYW5kc2hha2UKCgwKBQUAAgEBEgNfAgUKDAoFBQACAQISA18ICQoqCgQFAAICEgNiAgsa
HSBtdXR1YWwgVExTIChNVExTKSBIYW5kc2hha2UKCgwKBQUAAgIBEgNiAgYKDAoFBQACAgIS
A2IJCgohCgIFARIEZgBsARoVIEVudW0gZm9yIENlcnQgVHlwZXMKCgoKAwUBARIDZgUNCiUK
BAUBAgASA2gCHBoYIENlcnQgdHlwZSB1bnNwZWNpZmllZC4KCgwKBQUBAgABEgNoAhcKDAoF
BQECAAISA2gaGwovCgQFAQIBEgNrAgoaIiBQcml2YWN5IEVuaGFuY2VkIE1haWwgKFBFTSkg
VHlwZQoKDAoFBQECAQESA2sCBQoMCgUFAQIBAhIDawgJYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::SslConfig::SslConfigTemplate ===
    # Fields for SslConfigTemplate
    # Field: ssl_type Type: 14 (.google.cloud.connectors.v1.SslType)
    # Field: is_tls_mandatory Type: 8 ()
    # Field: server_cert_type Type: 14 (.google.cloud.connectors.v1.CertType)
    # Field: client_cert_type Type: 14 (.google.cloud.connectors.v1.CertType)
    # Field: additional_variables Type: 11 (.google.cloud.connectors.v1.ConfigVariableTemplate)

# === Message: Google::Cloud::Connectors::V1::SslConfig::SslConfig ===
    # Fields for SslConfig
    # Field: type Type: 14 (.google.cloud.connectors.v1.SslType)
    # Field: trust_model Type: 14 (.google.cloud.connectors.v1.SslConfig.TrustModel)
    # Field: private_server_certificate Type: 11 (.google.cloud.connectors.v1.Secret)
    # Field: client_certificate Type: 11 (.google.cloud.connectors.v1.Secret)
    # Field: client_private_key Type: 11 (.google.cloud.connectors.v1.Secret)
    # Field: client_private_key_pass Type: 11 (.google.cloud.connectors.v1.Secret)
    # Field: server_cert_type Type: 14 (.google.cloud.connectors.v1.CertType)
    # Field: client_cert_type Type: 14 (.google.cloud.connectors.v1.CertType)
    # Field: use_ssl Type: 8 ()
    # Field: additional_variables Type: 11 (.google.cloud.connectors.v1.ConfigVariable)

# Enum: SslConfig::TrustModel
our $SslConfig_PUBLIC = 0;
our $SslConfig_PRIVATE = 1;
our $SslConfig_INSECURE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::SslConfig - Compiled Protocol Buffers messages for google/cloud/connectors/v1/ssl_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::SslConfig;

    my $msg = Google::Cloud::Connectors::V1::SslConfig::SslConfigTemplate->new({
        ssl_type => $ssl_type,
        is_tls_mandatory => $is_tls_mandatory,
        server_cert_type => $server_cert_type,
        client_cert_type => $client_cert_type,
    });

    # Read or update a field
    my $val = $msg->ssl_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::SslConfig::SslConfigTemplate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/ssl_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::SslConfig::SslConfigTemplate

Ssl config details of a connector version

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ssl_type() >> / C<< $msg->ssl_type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::SslType>)

Controls the ssl type for the given connector version

=item * C<< $msg->is_tls_mandatory() >> / C<< $msg->is_tls_mandatory($value) >>

Type: C<Bool>

Boolean for determining if the connector version mandates TLS.

=item * C<< $msg->server_cert_type() >> / C<< $msg->server_cert_type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::CertType>)

List of supported Server Cert Types

=item * C<< $msg->client_cert_type() >> / C<< $msg->client_cert_type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::CertType>)

List of supported Client Cert Types

=item * C<< $msg->additional_variables() >> / C<< $msg->additional_variables($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::ConfigVariableTemplate>)

Any additional fields that need to be rendered

=back

=head2 Google::Cloud::Connectors::V1::SslConfig::SslConfig

SSL Configuration of a connection

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::SslType>)

Controls the ssl type for the given connector version.

=item * C<< $msg->trust_model() >> / C<< $msg->trust_model($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::SslConfig::TrustModel>)

Trust Model of the SSL connection

=item * C<< $msg->private_server_certificate() >> / C<< $msg->private_server_certificate($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::Secret>)

Private Server Certificate. Needs to be specified if trust model is
`PRIVATE`.

=item * C<< $msg->client_certificate() >> / C<< $msg->client_certificate($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::Secret>)

Client Certificate

=item * C<< $msg->client_private_key() >> / C<< $msg->client_private_key($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::Secret>)

Client Private Key

=item * C<< $msg->client_private_key_pass() >> / C<< $msg->client_private_key_pass($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::Secret>)

Secret containing the passphrase protecting the Client Private Key

=item * C<< $msg->server_cert_type() >> / C<< $msg->server_cert_type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::CertType>)

Type of Server Cert (PEM/JKS/.. etc.)

=item * C<< $msg->client_cert_type() >> / C<< $msg->client_cert_type($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::CertType>)

Type of Client Cert (PEM/JKS/.. etc.)

=item * C<< $msg->use_ssl() >> / C<< $msg->use_ssl($value) >>

Type: C<Bool>

Bool for enabling SSL

=item * C<< $msg->additional_variables() >> / C<< $msg->additional_variables($value) >>

Type: C<Message> (L<Google::Cloud::Connectors::V1::Common::ConfigVariable>)

Additional SSL related field values

=back

=head3 Enum: SslConfig::TrustModel

=over 4

=item * C<PUBLIC> => C<0>

=item * C<PRIVATE> => C<1>

=item * C<INSECURE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::SslConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
