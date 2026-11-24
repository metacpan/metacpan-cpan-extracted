package Google::Cloud::Tasks::V2beta3::CmekConfig;

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
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvdGFza3MvdjJiZXRhMy9jbWVrX2NvbmZpZy5wcm90bxIaZ29vZ2xl
LmNsb3VkLnRhc2tzLnYyYmV0YTMaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ixQEKCkNtZWtDb25maWcSFwoEbmFtZRgBIAEo
CUID4EEDUgRuYW1lEj8KB2ttc19rZXkYAiABKAlCJvpBIwohY2xvdWRrbXMuZ29vZ2xlYXBp
cy5jb20vQ3J5cHRvS2V5UgZrbXNLZXk6XepBWgokY2xvdWR0YXNrcy5nb29nbGVhcGlzLmNv
bS9DbWVrQ29uZmlnEjJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
Y21la0NvbmZpZ0LzAQoeY29tLmdvb2dsZS5jbG91ZC50YXNrcy52MmJldGEzQg9DbWVrQ29u
ZmlnUHJvdG9QAVpDY2xvdWQuZ29vZ2xlLmNvbS9nby9jbG91ZHRhc2tzL2FwaXYyYmV0YTMv
Y2xvdWR0YXNrc3BiO2Nsb3VkdGFza3NwYupBeAohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20v
Q3J5cHRvS2V5ElNwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5
UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5fUrcCwoGEgQOADIBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACkK
CQoCAwESAxMAIwoICgEIEgMVAFoKCQoCCAsSAxUAWgoICgEIEgMWACIKCQoCCAoSAxYAIgoI
CgEIEgMXADAKCQoCCAgSAxcAMAoICgEIEgMYADcKCQoCCAESAxgANwoJCgEIEgQZABwCCgwK
BAidCAASBBkAHAIKeQoCBAASBCAAMgEabSBEZXNjcmliZXMgdGhlIGN1c3RvbWVyLW1hbmFn
ZWQgZW5jcnlwdGlvbiBrZXkgKENNRUspIGNvbmZpZ3VyYXRpb24gYXNzb2NpYXRlZAogd2l0
aCBhIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKCgoDBAABEgMgCBIKCwoDBAAHEgQhAiQECg0K
BQQAB50IEgQhAiQECsEBCgQEAAIAEgMpAj4aswEgT3V0cHV0IG9ubHkuIFRoZSBjb25maWcg
cmVzb3VyY2UgbmFtZSB3aGljaCBpbmNsdWRlcyB0aGUgcHJvamVjdCBhbmQKIGxvY2F0aW9u
IGFuZCBtdXN0IGVuZCBpbiAnY21la0NvbmZpZycsIGluIHRoZSBmb3JtYXQKIHByb2plY3Rz
L1BST0pFQ1RfSUQvbG9jYXRpb25zL0xPQ0FUSU9OX0lEL2NtZWtDb25maWdgCgoMCgUEAAIA
BRIDKQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQoMCgUEAAIACBIDKRI9Cg8KCAQA
AgAInAgAEgMpEzwKiwIKBAQAAgESBC8CMQUa/AEgUmVzb3VyY2UgbmFtZSBvZiB0aGUgQ2xv
dWQgS01TIGtleSwgb2YgdGhlIGZvcm0KIGBwcm9qZWN0cy9QUk9KRUNUX0lEL2xvY2F0aW9u
cy9MT0NBVElPTl9JRC9rZXlSaW5ncy9LRVlfUklOR19JRC9jcnlwdG9LZXlzL0tFWV9JRGAs
CiB0aGF0IHdpbGwgYmUgdXNlZCB0byBlbmNyeXB0IHRoZSBRdWV1ZXMgJiBUYXNrcyBpbiB0
aGUgcmVnaW9uLiBTZXR0aW5nCiB0aGlzIGFzIGJsYW5rIHdpbGwgdHVybiBvZmYgQ01FSyBl
bmNyeXB0aW9uLgoKDAoFBAACAQUSAy8CCAoMCgUEAAIBARIDLwkQCgwKBQQAAgEDEgMvExQK
DQoFBAACAQgSBC8VMQQKDwoHBAACAQifCBIELxYxA2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Tasks::V2beta3::CmekConfig::CmekConfig ===
    # Fields for CmekConfig
    # Field: name Type: 9 ()
    # Field: kms_key Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Tasks::V2beta3::CmekConfig - Compiled Protocol Buffers messages for google/cloud/tasks/v2beta3/cmek_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Tasks::V2beta3::CmekConfig;

    my $msg = Google::Cloud::Tasks::V2beta3::CmekConfig::CmekConfig->new({
        name => $name,
        kms_key => $kms_key,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Tasks::V2beta3::CmekConfig::CmekConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/tasks/v2beta3/cmek_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Tasks::V2beta3::CmekConfig::CmekConfig

Describes the customer-managed encryption key (CMEK) configuration associated
with a project and location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The config resource name which includes the project and
location and must end in 'cmekConfig', in the format
projects/PROJECT_ID/locations/LOCATION_ID/cmekConfig`

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Resource name of the Cloud KMS key, of the form
`projects/PROJECT_ID/locations/LOCATION_ID/keyRings/KEY_RING_ID/cryptoKeys/KEY_ID`,
that will be used to encrypt the Queues & Tasks in the region. Setting
this as blank will turn off CMEK encryption.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Tasks::V2beta3::CmekConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
