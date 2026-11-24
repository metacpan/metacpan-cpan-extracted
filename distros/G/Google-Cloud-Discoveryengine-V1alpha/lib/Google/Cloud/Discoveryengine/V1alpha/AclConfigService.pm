package Google::Cloud::Discoveryengine::V1alpha::AclConfigService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::AclConfig };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvYWNsX2NvbmZpZ19zZXJ2
aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
GjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvYWNsX2NvbmZpZy5wcm90
byJbChNHZXRBY2xDb25maWdSZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpBKgooZGlzY292
ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0FjbENvbmZpZ1IEbmFtZSJtChZVcGRhdGVBY2xD
b25maWdSZXF1ZXN0ElMKCmFjbF9jb25maWcYASABKAsyLy5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuQWNsQ29uZmlnQgPgQQJSCWFjbENvbmZpZzL4AwoQQWNsQ29u
ZmlnU2VydmljZRLRAQoPVXBkYXRlQWNsQ29uZmlnEjwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlVwZGF0ZUFjbENvbmZpZ1JlcXVlc3QaLy5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQWNsQ29uZmlnIk+C0+STAkkyOy92MWFscGhhL3th
Y2xfY29uZmlnLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hY2xDb25maWd9OgphY2xf
Y29uZmlnErsBCgxHZXRBY2xDb25maWcSOS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYWxwaGEuR2V0QWNsQ29uZmlnUmVxdWVzdBovLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5BY2xDb25maWciP4LT5JMCMhIwL3YxYWxwaGEve25hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9hY2xDb25maWd92kEEbmFtZRpSykEeZGlzY292ZXJ5ZW5naW5l
Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybUKhAgooY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YUIVQWNsQ29uZmlnU2VydmljZVByb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292
ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5l
cGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYx
QWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6
OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFKlxAKBhIEDgBOAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgAmCgkKAgMBEgMT
ACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAD8KCAoBCBIDGABBCgkKAgglEgMY
AEEKCAoBCBIDGQBpCgkKAggLEgMZAGkKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA2
CgkKAggIEgMbADYKCAoBCBIDHABBCgkKAggBEgMcAEEKCAoBCBIDHQAtCgkKAggkEgMdAC0K
CAoBCBIDHgBBCgkKAggpEgMeAEEKCAoBCBIDHwBACgkKAggtEgMfAEAKNQoCBgASBCIAOAEa
KSBTZXJ2aWNlIGZvciBtYW5hZ2luZyBBY2wgQ29uZmlndXJhdGlvbi4KCgoKAwYAARIDIggY
CgoKAwYAAxIDIwJGCgwKBQYAA5kIEgMjAkYKCwoDBgADEgQkAiU3Cg0KBQYAA5oIEgQkAiU3
CrwBCgQGAAIAEgQqAi8DGq0BIERlZmF1bHQgQUNMIGNvbmZpZ3VyYXRpb24gZm9yIHVzZSBp
biBhIGxvY2F0aW9uIG9mIGEgY3VzdG9tZXIncyBwcm9qZWN0LgogVXBkYXRlcyB3aWxsIG9u
bHkgcmVmbGVjdCB0byBuZXcgZGF0YSBzdG9yZXMuIEV4aXN0aW5nIGRhdGEgc3RvcmVzIHdp
bGwKIHN0aWxsIHVzZSB0aGUgb2xkIHZhbHVlLgoKDAoFBgACAAESAyoGFQoMCgUGAAIAAhID
KhYsCgwKBQYAAgADEgMqN0AKDQoFBgACAAQSBCsELgYKEQoJBgACAASwyrwiEgQrBC4GClUK
BAYAAgESBDICNwMaRyBHZXRzIHRoZSBbQWNsQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuQWNsQ29uZmlnXS4KCgwKBQYAAgEBEgMyBhIKDAoFBgACAQIS
AzITJgoMCgUGAAIBAxIDMjE6Cg0KBQYAAgEEEgQzBDUGChEKCQYAAgEEsMq8IhIEMwQ1BgoM
CgUGAAIBBBIDNgQyCg8KCAYAAgEEmwgAEgM2BDIKPQoCBAASBDsASQEaMSBSZXF1ZXN0IG1l
c3NhZ2UgZm9yIEdldEFjbENvbmZpZ1JlcXVlc3QgbWV0aG9kLgoKCgoDBAABEgM7CBsK2wIK
BAQAAgASBEMCSAQazAIgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YKIFtBY2xDb25maWdd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5BY2xDb25maWddLCBzdWNo
IGFzCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9hY2xDb25maWdgLgoKIElmIHRoZSBjYWxs
ZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNzaW9uIHRvIGFjY2VzcyB0aGUKIFtBY2xDb25maWdd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5BY2xDb25maWddLCByZWdh
cmRsZXNzIG9mCiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5J
RUQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUEAAIABRIDQwIICgwKBQQAAgABEgNDCQ0KDAoF
BAACAAMSA0MQEQoNCgUEAAIACBIEQxJIAwoPCggEAAIACJwIABIDRAQqCg8KBwQAAgAInwgS
BEUERwUKOQoCBAESBEwATgEaLSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIFVwZGF0ZUFjbENvbmZp
ZyBtZXRob2QuCgoKCgMEAQESA0wIHgoLCgQEAQIAEgNNAkQKDAoFBAECAAYSA00CCwoMCgUE
AQIAARIDTQwWCgwKBQQBAgADEgNNGRoKDAoFBAECAAgSA00bQwoPCggEAQIACJwIABIDTRxC
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest ===
    # Fields for GetAclConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest ===
    # Fields for UpdateAclConfigRequest
    # Field: acl_config Type: 11 (.google.cloud.discoveryengine.v1alpha.AclConfig)

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::AclConfigService::AclConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::AclConfigService::AclConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::AclConfigService::AclConfigServiceClient

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
        ? Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.AclConfigService',
        method         => 'UpdateAclConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig',
    });
}

sub get_acl_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.AclConfigService',
        method         => 'GetAclConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::AclConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/acl_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::AclConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/acl_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest

Request message for GetAclConfigRequest method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of
[AclConfig][google.cloud.discoveryengine.v1alpha.AclConfig], such as
`projects/*/locations/*/aclConfig`.

If the caller does not have permission to access the
[AclConfig][google.cloud.discoveryengine.v1alpha.AclConfig], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest

Request message for UpdateAclConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->acl_config() >> / C<< $msg->acl_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::AclConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
