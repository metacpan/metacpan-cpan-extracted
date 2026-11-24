package Google::Cloud::Discoveryengine::V1alpha::AclConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Common };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvYWNsX2NvbmZpZy5wcm90
bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjFnb29nbGUv
Y2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29tbW9uLnByb3RvItYBCglBY2xDb25m
aWcSFwoEbmFtZRgBIAEoCUID4EEFUgRuYW1lEk4KCmlkcF9jb25maWcYAiABKAsyLy5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuSWRwQ29uZmlnUglpZHBDb25maWc6
YOpBXQooZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0FjbENvbmZpZxIxcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FjbENvbmZpZ0KaAgooY29tLmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUIOQWNsQ29uZmlnUHJvdG9QAVpS
Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFhbHBoYS9kaXNjb3Zl
cnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCJEdvb2ds
ZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFBbHBoYcoCJEdvb2dsZVxDbG91ZFxEaXNjb3Zl
cnlFbmdpbmVcVjFhbHBoYeoCJ0dvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFh
bHBoYUruCQoGEgQOADABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
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
AhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA7CggKAQgSAxYAQQoJCgII
JRIDFgBBCggKAQgSAxcAaQoJCgIICxIDFwBpCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgS
AxkALwoJCgIICBIDGQAvCggKAQgSAxoAQQoJCgIIARIDGgBBCggKAQgSAxsALQoJCgIIJBID
GwAtCggKAQgSAxwAQQoJCgIIKRIDHABBCggKAQgSAx0AQAoJCgIILRIDHQBACisKAgQAEgQg
ADABGh8gQWNjZXNzIENvbnRyb2wgQ29uZmlndXJhdGlvbi4KCgoKAwQAARIDIAgRCgsKAwQA
BxIEIQIkBAoNCgUEAAedCBIEIQIkBArfAQoEBAACABIDLAI8GtEBIEltbXV0YWJsZS4gVGhl
IGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYWNsIGNvbmZpZ3VyYXRpb24uCiBGb3JtYXQ6
CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FjbENvbmZpZ2Au
CgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxl
bmd0aCBsaW1pdCBvZiAxMDI0CiBjaGFyYWN0ZXJzLgoKDAoFBAACAAUSAywCCAoMCgUEAAIA
ARIDLAkNCgwKBQQAAgADEgMsEBEKDAoFBAACAAgSAywSOwoPCggEAAIACJwIABIDLBM6CigK
BAQAAgESAy8CGxobIElkZW50aXR5IHByb3ZpZGVyIGNvbmZpZy4KCgwKBQQAAgEGEgMvAgsK
DAoFBAACAQESAy8MFgoMCgUEAAIBAxIDLxkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig ===
    # Fields for AclConfig
    # Field: name Type: 9 ()
    # Field: idp_config Type: 11 (.google.cloud.discoveryengine.v1alpha.IdpConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::AclConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/acl_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::AclConfig;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig->new({
        name => $name,
        idp_config => $idp_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/acl_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig

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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Common::IdpConfig>)

Identity provider config.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::AclConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
