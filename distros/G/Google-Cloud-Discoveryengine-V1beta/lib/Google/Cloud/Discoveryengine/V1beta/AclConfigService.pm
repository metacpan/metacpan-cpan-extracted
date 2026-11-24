package Google::Cloud::Discoveryengine::V1beta::AclConfigService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::AclConfig };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9hY2xfY29uZmlnX3NlcnZp
Y2UucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo0
Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvYWNsX2NvbmZpZy5wcm90byJb
ChNHZXRBY2xDb25maWdSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29tL0FjbENvbmZpZ1IEbmFtZSJsChZVcGRhdGVBY2xDb25m
aWdSZXF1ZXN0ElIKCmFjbF9jb25maWcYASABKAsyLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5BY2xDb25maWdCA+BBAlIJYWNsQ29uZmlnMvAEChBBY2xDb25maWdT
ZXJ2aWNlEs4BCg9VcGRhdGVBY2xDb25maWcSOy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5VcGRhdGVBY2xDb25maWdSZXF1ZXN0Gi4uZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuQWNsQ29uZmlnIk6C0+STAkgyOi92MWJldGEve2FjbF9jb25m
aWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FjbENvbmZpZ306CmFjbF9jb25maWcS
uAEKDEdldEFjbENvbmZpZxI4Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LkdldEFjbENvbmZpZ1JlcXVlc3QaLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5BY2xDb25maWciPoLT5JMCMRIvL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2FjbENvbmZpZ33aQQRuYW1lGs8BykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZv
cm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUucmVh
ZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5l
LnNlcnZpbmcucmVhZHdyaXRlQpwCCidjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGFCFUFjbENvbmZpZ1NlcnZpY2VQcm90b1ABWlFjbG91ZC5nb29nbGUuY29tL2dv
L2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5
ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5n
aW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gImR29v
Z2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFKlBAKBhIEDgBQAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgAmCgkKAgMB
EgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAD4KCAoBCBIDGABACgkKAggl
EgMYAEAKCAoBCBIDGQBoCgkKAggLEgMZAGgKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBID
GwA2CgkKAggIEgMbADYKCAoBCBIDHABACgkKAggBEgMcAEAKCAoBCBIDHQAtCgkKAggkEgMd
AC0KCAoBCBIDHgBACgkKAggpEgMeAEAKCAoBCBIDHwA/CgkKAggtEgMfAD8KNQoCBgASBCIA
OgEaKSBTZXJ2aWNlIGZvciBtYW5hZ2luZyBBY2wgQ29uZmlndXJhdGlvbi4KCgoKAwYAARID
IggYCgoKAwYAAxIDIwJGCgwKBQYAA5kIEgMjAkYKCwoDBgADEgQkAidKCg0KBQYAA5oIEgQk
AidKCrwBCgQGAAIAEgQsAjEDGq0BIERlZmF1bHQgQUNMIGNvbmZpZ3VyYXRpb24gZm9yIHVz
ZSBpbiBhIGxvY2F0aW9uIG9mIGEgY3VzdG9tZXIncyBwcm9qZWN0LgogVXBkYXRlcyB3aWxs
IG9ubHkgcmVmbGVjdCB0byBuZXcgZGF0YSBzdG9yZXMuIEV4aXN0aW5nIGRhdGEgc3RvcmVz
IHdpbGwKIHN0aWxsIHVzZSB0aGUgb2xkIHZhbHVlLgoKDAoFBgACAAESAywGFQoMCgUGAAIA
AhIDLBYsCgwKBQYAAgADEgMsN0AKDQoFBgACAAQSBC0EMAYKEQoJBgACAASwyrwiEgQtBDAG
ClQKBAYAAgESBDQCOQMaRiBHZXRzIHRoZSBbQWNsQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5BY2xDb25maWddLgoKDAoFBgACAQESAzQGEgoMCgUGAAIB
AhIDNBMmCgwKBQYAAgEDEgM0MToKDQoFBgACAQQSBDUENwYKEQoJBgACAQSwyrwiEgQ1BDcG
CgwKBQYAAgEEEgM4BDIKDwoIBgACAQSbCAASAzgEMgo9CgIEABIEPQBLARoxIFJlcXVlc3Qg
bWVzc2FnZSBmb3IgR2V0QWNsQ29uZmlnUmVxdWVzdCBtZXRob2QuCgoKCgMEAAESAz0IGwrZ
AgoEBAACABIERQJKBBrKAiBSZXF1aXJlZC4gUmVzb3VyY2UgbmFtZSBvZgogW0FjbENvbmZp
Z11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQWNsQ29uZmlnXSwgc3Vj
aCBhcwogYHByb2plY3RzLyovbG9jYXRpb25zLyovYWNsQ29uZmlnYC4KCiBJZiB0aGUgY2Fs
bGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBhY2Nlc3MgdGhlCiBbQWNsQ29uZmln
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5BY2xDb25maWddLCByZWdh
cmRsZXNzIG9mCiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5J
RUQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUEAAIABRIDRQIICgwKBQQAAgABEgNFCQ0KDAoF
BAACAAMSA0UQEQoNCgUEAAIACBIERRJKAwoPCggEAAIACJwIABIDRgQqCg8KBwQAAgAInwgS
BEcESQUKOQoCBAESBE4AUAEaLSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFVwZGF0ZUFjbENvbmZp
ZyBtZXRob2QuCgoKCgMEAQESA04IHgoLCgQEAQIAEgNPAkQKDAoFBAECAAYSA08CCwoMCgUE
AQIAARIDTwwWCgwKBQQBAgADEgNPGRoKDAoFBAECAAgSA08bQwoPCggEAQIACJwIABIDTxxC
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::AclConfigService::GetAclConfigRequest ===
    # Fields for GetAclConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::AclConfigService::UpdateAclConfigRequest ===
    # Fields for UpdateAclConfigRequest
    # Field: acl_config Type: 11 (.google.cloud.discoveryengine.v1beta.AclConfig)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::AclConfigService::AclConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::AclConfigService::AclConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::AclConfigService::AclConfigServiceClient

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
        ? Google::Cloud::Discoveryengine::V1beta::AclConfigService::UpdateAclConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.AclConfigService',
        method         => 'UpdateAclConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig',
    });
}

sub get_acl_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::AclConfigService::GetAclConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.AclConfigService',
        method         => 'GetAclConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::AclConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/acl_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::AclConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::AclConfigService::GetAclConfigRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::AclConfigService::GetAclConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/acl_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::AclConfigService::GetAclConfigRequest

Request message for GetAclConfigRequest method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of
[AclConfig][google.cloud.discoveryengine.v1beta.AclConfig], such as
`projects/*/locations/*/aclConfig`.

If the caller does not have permission to access the
[AclConfig][google.cloud.discoveryengine.v1beta.AclConfig], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::AclConfigService::UpdateAclConfigRequest

Request message for UpdateAclConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->acl_config() >> / C<< $msg->acl_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::AclConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
