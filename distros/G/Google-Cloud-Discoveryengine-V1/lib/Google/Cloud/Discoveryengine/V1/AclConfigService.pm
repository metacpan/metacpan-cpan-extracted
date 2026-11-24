package Google::Cloud::Discoveryengine::V1::AclConfigService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Discoveryengine::V1::AclConfig };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2FjbF9jb25maWdfc2VydmljZS5w
cm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMGdvb2dsZS9j
bG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvYWNsX2NvbmZpZy5wcm90byJbChNHZXRBY2xDb25m
aWdSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5ZW5naW5lLmdvb2ds
ZWFwaXMuY29tL0FjbENvbmZpZ1IEbmFtZSJoChZVcGRhdGVBY2xDb25maWdSZXF1ZXN0Ek4K
CmFjbF9jb25maWcYASABKAsyKi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkFj
bENvbmZpZ0ID4EECUglhY2xDb25maWcy2AQKEEFjbENvbmZpZ1NlcnZpY2USwgEKD1VwZGF0
ZUFjbENvbmZpZxI3Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXBkYXRlQWNs
Q29uZmlnUmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQWNsQ29u
ZmlnIkqC0+STAkQyNi92MS97YWNsX2NvbmZpZy5uYW1lPXByb2plY3RzLyovbG9jYXRpb25z
LyovYWNsQ29uZmlnfToKYWNsX2NvbmZpZxKsAQoMR2V0QWNsQ29uZmlnEjQuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5HZXRBY2xDb25maWdSZXF1ZXN0GiouZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5BY2xDb25maWciOoLT5JMCLRIrL3YxL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zLyovYWNsQ29uZmlnfdpBBG5hbWUazwHKQR5kaXNjb3Zlcnll
bmdpbmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2Nv
dmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9k
aXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVCiAIKI2NvbS5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxQhVBY2xDb25maWdTZXJ2aWNlUHJvdG9QAVpNY2xvdWQuZ29v
Z2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlz
Y292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAh9Hb29nbGUuQ2xvdWQuRGlzY292
ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMeoCIkdvb2ds
ZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFKiBAKBhIEDgBQAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADoKCAoBCBIDGAA8CgkKAgglEgMYADwK
CAoBCBIDGQBkCgkKAggLEgMZAGQKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA2CgkK
AggIEgMbADYKCAoBCBIDHAA8CgkKAggBEgMcADwKCAoBCBIDHQAtCgkKAggkEgMdAC0KCAoB
CBIDHgA8CgkKAggpEgMeADwKCAoBCBIDHwA7CgkKAggtEgMfADsKNQoCBgASBCIAOgEaKSBT
ZXJ2aWNlIGZvciBtYW5hZ2luZyBBY2wgQ29uZmlndXJhdGlvbi4KCgoKAwYAARIDIggYCgoK
AwYAAxIDIwJGCgwKBQYAA5kIEgMjAkYKCwoDBgADEgQkAidKCg0KBQYAA5oIEgQkAidKCrwB
CgQGAAIAEgQsAjEDGq0BIERlZmF1bHQgQUNMIGNvbmZpZ3VyYXRpb24gZm9yIHVzZSBpbiBh
IGxvY2F0aW9uIG9mIGEgY3VzdG9tZXIncyBwcm9qZWN0LgogVXBkYXRlcyB3aWxsIG9ubHkg
cmVmbGVjdCB0byBuZXcgZGF0YSBzdG9yZXMuIEV4aXN0aW5nIGRhdGEgc3RvcmVzIHdpbGwK
IHN0aWxsIHVzZSB0aGUgb2xkIHZhbHVlLgoKDAoFBgACAAESAywGFQoMCgUGAAIAAhIDLBYs
CgwKBQYAAgADEgMsN0AKDQoFBgACAAQSBC0EMAYKEQoJBgACAASwyrwiEgQtBDAGClAKBAYA
AgESBDQCOQMaQiBHZXRzIHRoZSBbQWNsQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkFjbENvbmZpZ10uCgoMCgUGAAIBARIDNAYSCgwKBQYAAgECEgM0EyYKDAoF
BgACAQMSAzQxOgoNCgUGAAIBBBIENQQ3BgoRCgkGAAIBBLDKvCISBDUENwYKDAoFBgACAQQS
AzgEMgoPCggGAAIBBJsIABIDOAQyCj0KAgQAEgQ9AEsBGjEgUmVxdWVzdCBtZXNzYWdlIGZv
ciBHZXRBY2xDb25maWdSZXF1ZXN0IG1ldGhvZC4KCgoKAwQAARIDPQgbCtECCgQEAAIAEgRF
AkoEGsICIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mCiBbQWNsQ29uZmlnXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkFjbENvbmZpZ10sIHN1Y2ggYXMKIGBwcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2FjbENvbmZpZ2AuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBo
YXZlIHBlcm1pc3Npb24gdG8gYWNjZXNzIHRoZQogW0FjbENvbmZpZ11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5BY2xDb25maWddLCByZWdhcmRsZXNzIG9mCiB3aGV0aGVy
IG9yIG5vdCBpdCBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJu
ZWQuCgoMCgUEAAIABRIDRQIICgwKBQQAAgABEgNFCQ0KDAoFBAACAAMSA0UQEQoNCgUEAAIA
CBIERRJKAwoPCggEAAIACJwIABIDRgQqCg8KBwQAAgAInwgSBEcESQUKOQoCBAESBE4AUAEa
LSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFVwZGF0ZUFjbENvbmZpZyBtZXRob2QuCgoKCgMEAQES
A04IHgoLCgQEAQIAEgNPAkQKDAoFBAECAAYSA08CCwoMCgUEAQIAARIDTwwWCgwKBQQBAgAD
EgNPGRoKDAoFBAECAAgSA08bQwoPCggEAQIACJwIABIDTxxCYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::AclConfigService::GetAclConfigRequest ===
    # Fields for GetAclConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::AclConfigService::UpdateAclConfigRequest ===
    # Fields for UpdateAclConfigRequest
    # Field: acl_config Type: 11 (.google.cloud.discoveryengine.v1.AclConfig)

# === Service Client: Google::Cloud::Discoveryengine::V1::AclConfigService::AclConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1::AclConfigService::AclConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::AclConfigService::AclConfigServiceClient

Client stub representing the remote C<AclConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub update_acl_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::AclConfigService::UpdateAclConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.AclConfigService',
        method         => 'UpdateAclConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig',
    });
}

sub get_acl_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::AclConfigService::GetAclConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.AclConfigService',
        method         => 'GetAclConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::AclConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/acl_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::AclConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1::AclConfigService::GetAclConfigRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::AclConfigService::GetAclConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/acl_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::AclConfigService::GetAclConfigRequest

Request message for GetAclConfigRequest method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of
[AclConfig][google.cloud.discoveryengine.v1.AclConfig], such as
`projects/*/locations/*/aclConfig`.

If the caller does not have permission to access the
[AclConfig][google.cloud.discoveryengine.v1.AclConfig], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::AclConfigService::UpdateAclConfigRequest

Request message for UpdateAclConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->acl_config() >> / C<< $msg->acl_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::AclConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
