package Google::Cloud::Discoveryengine::V1::AclConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1::Common };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2FjbF9jb25maWcucHJvdG8SH2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLGdvb2dsZS9jbG91ZC9kaXNj
b3ZlcnllbmdpbmUvdjEvY29tbW9uLnByb3RvItEBCglBY2xDb25maWcSFwoEbmFtZRgBIAEo
CUID4EEFUgRuYW1lEkkKCmlkcF9jb25maWcYAiABKAsyKi5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLklkcENvbmZpZ1IJaWRwQ29uZmlnOmDqQV0KKGRpc2NvdmVyeWVuZ2lu
ZS5nb29nbGVhcGlzLmNvbS9BY2xDb25maWcSMXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9hY2xDb25maWdCgQIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxQg5BY2xDb25maWdQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2Nv
dmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqIC
D0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9H
b29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292
ZXJ5RW5naW5lOjpWMUruCQoGEgQOADABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA2CggKAQgS
AxYAPAoJCgIIJRIDFgA8CggKAQgSAxcAZAoJCgIICxIDFwBkCggKAQgSAxgAIgoJCgIIChID
GAAiCggKAQgSAxkALwoJCgIICBIDGQAvCggKAQgSAxoAPAoJCgIIARIDGgA8CggKAQgSAxsA
LQoJCgIIJBIDGwAtCggKAQgSAxwAPAoJCgIIKRIDHAA8CggKAQgSAx0AOwoJCgIILRIDHQA7
CisKAgQAEgQgADABGh8gQWNjZXNzIENvbnRyb2wgQ29uZmlndXJhdGlvbi4KCgoKAwQAARID
IAgRCgsKAwQABxIEIQIkBAoNCgUEAAedCBIEIQIkBArfAQoEBAACABIDLAI8GtEBIEltbXV0
YWJsZS4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYWNsIGNvbmZpZ3VyYXRpb24u
CiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fj
bENvbmZpZ2AuCgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcg
d2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAAUSAywC
CAoMCgUEAAIAARIDLAkNCgwKBQQAAgADEgMsEBEKDAoFBAACAAgSAywSOwoPCggEAAIACJwI
ABIDLBM6CigKBAQAAgESAy8CGxobIElkZW50aXR5IHByb3ZpZGVyIGNvbmZpZy4KCgwKBQQA
AgEGEgMvAgsKDAoFBAACAQESAy8MFgoMCgUEAAIBAxIDLxkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig ===
    # Fields for AclConfig
    # Field: name Type: 9 ()
    # Field: idp_config Type: 11 (.google.cloud.discoveryengine.v1.IdpConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::AclConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/acl_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::AclConfig;

    my $msg = Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig->new({
        name => $name,
        idp_config => $idp_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/acl_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig

Access Control Configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The full resource name of the acl configuration.
Format:
`projects/{project}/locations/{location}/aclConfig`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->idp_config() >> / C<< $msg->idp_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Common::IdpConfig>)

Identity provider config.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::AclConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
