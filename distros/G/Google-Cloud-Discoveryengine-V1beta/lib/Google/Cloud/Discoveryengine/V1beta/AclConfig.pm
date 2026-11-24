package Google::Cloud::Discoveryengine::V1beta::AclConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Common };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9hY2xfY29uZmlnLnByb3Rv
EiNnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxowZ29vZ2xlL2Ns
b3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvY29tbW9uLnByb3RvItUBCglBY2xDb25maWcS
FwoEbmFtZRgBIAEoCUID4EEFUgRuYW1lEk0KCmlkcF9jb25maWcYAiABKAsyLi5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JZHBDb25maWdSCWlkcENvbmZpZzpg6kFd
CihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQWNsQ29uZmlnEjFwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWNsQ29uZmlnQpUCCidjb20uZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFCDkFjbENvbmZpZ1Byb3RvUAFaUWNsb3Vk
Lmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYmV0YS9kaXNjb3Zlcnllbmdp
bmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCI0dvb2dsZS5DbG91
ZC5EaXNjb3ZlcnlFbmdpbmUuVjFCZXRhygIjR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2lu
ZVxWMWJldGHqAiZHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYmV0YUruCQoG
EgQOADABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkK
AgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA6CggKAQgSAxYAQAoJCgIIJRIDFgBACggK
AQgSAxcAaAoJCgIICxIDFwBoCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkALwoJCgII
CBIDGQAvCggKAQgSAxoAQAoJCgIIARIDGgBACggKAQgSAxsALQoJCgIIJBIDGwAtCggKAQgS
AxwAQAoJCgIIKRIDHABACggKAQgSAx0APwoJCgIILRIDHQA/CisKAgQAEgQgADABGh8gQWNj
ZXNzIENvbnRyb2wgQ29uZmlndXJhdGlvbi4KCgoKAwQAARIDIAgRCgsKAwQABxIEIQIkBAoN
CgUEAAedCBIEIQIkBArfAQoEBAACABIDLAI8GtEBIEltbXV0YWJsZS4gVGhlIGZ1bGwgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgYWNsIGNvbmZpZ3VyYXRpb24uCiBGb3JtYXQ6CiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FjbENvbmZpZ2AuCgogVGhpcyBm
aWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1p
dCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAAUSAywCCAoMCgUEAAIAARIDLAkNCgwK
BQQAAgADEgMsEBEKDAoFBAACAAgSAywSOwoPCggEAAIACJwIABIDLBM6CigKBAQAAgESAy8C
GxobIElkZW50aXR5IHByb3ZpZGVyIGNvbmZpZy4KCgwKBQQAAgEGEgMvAgsKDAoFBAACAQES
Ay8MFgoMCgUEAAIBAxIDLxkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig ===
    # Fields for AclConfig
    # Field: name Type: 9 ()
    # Field: idp_config Type: 11 (.google.cloud.discoveryengine.v1beta.IdpConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::AclConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/acl_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::AclConfig;

    my $msg = Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig->new({
        name => $name,
        idp_config => $idp_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/acl_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig

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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig>)

Identity provider config.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::AclConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
