package Google::Cloud::Security::Publicca::V1::Resources;

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
CjFnb29nbGUvY2xvdWQvc2VjdXJpdHkvcHVibGljY2EvdjEvcmVzb3VyY2VzLnByb3RvEiFn
b29nbGUuY2xvdWQuc2VjdXJpdHkucHVibGljY2EudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i9QEKEkV4dGVybmFsQWNj
b3VudEtleRIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSGgoGa2V5X2lkGAIgASgJQgPgQQNS
BWtleUlkEiMKC2I2NF9tYWNfa2V5GAMgASgMQgPgQQNSCWI2NE1hY0tleTqEAepBgAEKKnB1
YmxpY2NhLmdvb2dsZWFwaXMuY29tL0V4dGVybmFsQWNjb3VudEtleRJScHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2V4dGVybmFsQWNjb3VudEtleXMve2V4dGVy
bmFsX2FjY291bnRfa2V5fULsAQolY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eS5wdWJsaWNj
YS52MUIOUmVzb3VyY2VzUHJvdG9QAVpBY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eS9w
dWJsaWNjYS9hcGl2MS9wdWJsaWNjYXBiO3B1YmxpY2NhcGKqAiFHb29nbGUuQ2xvdWQuU2Vj
dXJpdHkuUHVibGljQ0EuVjHKAiFHb29nbGVcQ2xvdWRcU2VjdXJpdHlcUHVibGljQ0FcVjHq
AiVHb29nbGU6OkNsb3VkOjpTZWN1cml0eTo6UHVibGljQ0E6OlYxSrYMCgYSBA4AMgEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACoKCQoCAwASAxIAKQoJ
CgIDARIDEwAjCggKAQgSAxUAPgoJCgIIJRIDFQA+CggKAQgSAxYAWAoJCgIICxIDFgBYCggK
AQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgALwoJCgIICBIDGAAvCggKAQgSAxkAPgoJCgII
ARIDGQA+CggKAQgSAxoAPwoJCgIIKRIDGgA/CggKAQgSAxsAPgoJCgIILRIDGwA+Cp0BCgIE
ABIEHwAyARqQASBBIHJlcHJlc2VudGF0aW9uIG9mIGFuIEV4dGVybmFsQWNjb3VudEtleSB1
c2VkIGZvciBbZXh0ZXJuYWwgYWNjb3VudAogYmluZGluZ10oaHR0cHM6Ly90b29scy5pZXRm
Lm9yZy9odG1sL3JmYzg1NTUjc2VjdGlvbi03LjMuNCkgd2l0aGluIEFDTUUuCgoKCgMEAAES
Ax8IGgoLCgMEAAcSBCACIwQKDQoFBAAHnQgSBCACIwQKcAoEBAACABIDJwI+GmMgT3V0cHV0
IG9ubHkuIFJlc291cmNlIG5hbWUuCiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vZXh0ZXJuYWxBY2NvdW50S2V5cy97a2V5X2lkfQoKDAoFBAACAAUSAycCCAoM
CgUEAAIAARIDJwkNCgwKBQQAAgADEgMnEBEKDAoFBAACAAgSAycSPQoPCggEAAIACJwIABID
JxM8CoUBCgQEAAIBEgMsAkAaeCBPdXRwdXQgb25seS4gS2V5IElELgogSXQgaXMgZ2VuZXJh
dGVkIGJ5IHRoZSBQdWJsaWNDZXJ0aWZpY2F0ZUF1dGhvcml0eVNlcnZpY2UKIHdoZW4gdGhl
IEV4dGVybmFsQWNjb3VudEtleSBpcyBjcmVhdGVkCgoMCgUEAAIBBRIDLAIICgwKBQQAAgEB
EgMsCQ8KDAoFBAACAQMSAywSEwoMCgUEAAIBCBIDLBQ/Cg8KCAQAAgEInAgAEgMsFT4KnAEK
BAQAAgISAzECRBqOASBPdXRwdXQgb25seS4gQmFzZTY0LVVSTC1lbmNvZGVkIEhTMjU2IGtl
eS4KIEl0IGlzIGdlbmVyYXRlZCBieSB0aGUgUHVibGljQ2VydGlmaWNhdGVBdXRob3JpdHlT
ZXJ2aWNlCiB3aGVuIHRoZSBFeHRlcm5hbEFjY291bnRLZXkgaXMgY3JlYXRlZAoKDAoFBAAC
AgUSAzECBwoMCgUEAAICARIDMQgTCgwKBQQAAgIDEgMxFhcKDAoFBAACAggSAzEYQwoPCggE
AAICCJwIABIDMRlCYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey ===
    # Fields for ExternalAccountKey
    # Field: name Type: 9 ()
    # Field: key_id Type: 9 ()
    # Field: b64_mac_key Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Security::Publicca::V1::Resources - Compiled Protocol Buffers messages for google/cloud/security/publicca/v1/resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Security::Publicca::V1::Resources;

    my $msg = Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey->new({
        name => $name,
        key_id => $key_id,
        b64_mac_key => $b64_mac_key,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/security/publicca/v1/resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey

A representation of an ExternalAccountKey used for [external account
binding](https://tools.ietf.org/html/rfc8555#section-7.3.4) within ACME.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name.
projects/{project}/locations/{location}/externalAccountKeys/{key_id}

=item * C<< $msg->key_id() >> / C<< $msg->key_id($value) >>

Type: C<String>

Output only. Key ID.
It is generated by the PublicCertificateAuthorityService
when the ExternalAccountKey is created

=item * C<< $msg->b64_mac_key() >> / C<< $msg->b64_mac_key($value) >>

Type: C<Bytes>

Output only. Base64-URL-encoded HS256 key.
It is generated by the PublicCertificateAuthorityService
when the ExternalAccountKey is created

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Security::Publicca::V1::Resources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
