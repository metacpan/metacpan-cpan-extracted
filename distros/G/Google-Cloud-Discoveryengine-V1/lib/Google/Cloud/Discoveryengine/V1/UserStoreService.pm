package Google::Cloud::Discoveryengine::V1::UserStoreService;

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
    eval { require Google::Cloud::Discoveryengine::V1::UserStore };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3VzZXJfc3RvcmVfc2VydmljZS5w
cm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMGdvb2dsZS9j
bG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvdXNlcl9zdG9yZS5wcm90bxogZ29vZ2xlL3Byb3Rv
YnVmL2ZpZWxkX21hc2sucHJvdG8iWwoTR2V0VXNlclN0b3JlUmVxdWVzdBJECgRuYW1lGAEg
ASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Vc2VyU3RvcmVS
BG5hbWUiqgEKFlVwZGF0ZVVzZXJTdG9yZVJlcXVlc3QSTgoKdXNlcl9zdG9yZRgBIAEoCzIq
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXNlclN0b3JlQgPgQQJSCXVzZXJT
dG9yZRJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tC
A+BBAVIKdXBkYXRlTWFzazL3BAoQVXNlclN0b3JlU2VydmljZRKvAQoMR2V0VXNlclN0b3Jl
EjQuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5HZXRVc2VyU3RvcmVSZXF1ZXN0
GiouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyU3RvcmUiPYLT5JMCMBIu
L3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovdXNlclN0b3Jlcy8qfdpBBG5hbWUS
3gEKD1VwZGF0ZVVzZXJTdG9yZRI3Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
VXBkYXRlVXNlclN0b3JlUmVxdWVzdBoqLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuVXNlclN0b3JlImaC0+STAkcyOS92MS97dXNlcl9zdG9yZS5uYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovdXNlclN0b3Jlcy8qfToKdXNlcl9zdG9yZdpBFnVzZXJfc3RvcmUsdXBk
YXRlX21hc2sazwHKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5n
b29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93
d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3Jp
dGVCiAIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxQhVVc2VyU3RvcmVT
ZXJ2aWNlUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBp
djEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJ
TkWqAh9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENsb3VkXERp
c2NvdmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFK
uxAKBhIEDgBWAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
KAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMW
ADoKCQoCAwUSAxcAKgoICgEIEgMZADwKCQoCCCUSAxkAPAoICgEIEgMaAGQKCQoCCAsSAxoA
ZAoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADYKCQoCCAgSAxwANgoICgEIEgMdADwK
CQoCCAESAx0APAoICgEIEgMeAC0KCQoCCCQSAx4ALQoICgEIEgMfADwKCQoCCCkSAx8APAoI
CgEIEgMgADsKCQoCCC0SAyAAOwovCgIGABIEIwA6ARojIFNlcnZpY2UgZm9yIG1hbmFnaW5n
IFVzZXIgU3RvcmVzLgoKCgoDBgABEgMjCBgKCgoDBgADEgMkAkYKDAoFBgADmQgSAyQCRgoL
CgMGAAMSBCUCKEoKDQoFBgADmggSBCUCKEoKJAoEBgACABIEKwIwAxoWIEdldHMgdGhlIFVz
ZXIgU3RvcmUuCgoMCgUGAAIAARIDKwYSCgwKBQYAAgACEgMrEyYKDAoFBgACAAMSAysxOgoN
CgUGAAIABBIELAQuBgoRCgkGAAIABLDKvCISBCwELgYKDAoFBgACAAQSAy8EMgoPCggGAAIA
BJsIABIDLwQyCicKBAYAAgESBDMCOQMaGSBVcGRhdGVzIHRoZSBVc2VyIFN0b3JlLgoKDAoF
BgACAQESAzMGFQoMCgUGAAIBAhIDMxYsCgwKBQYAAgEDEgMzN0AKDQoFBgACAQQSBDQENwYK
EQoJBgACAQSwyrwiEgQ0BDcGCgwKBQYAAgEEEgM4BEQKDwoIBgACAQSbCAASAzgERAqBAQoC
BAASBD4ASAEadSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVXNlclN0b3JlU2VydmljZS5HZXRV
c2VyU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXNlclN0b3JlU2Vy
dmljZS5HZXRVc2VyU3RvcmVdCgoKCgMEAAESAz4IGwqLAQoEBAACABIEQgJHBBp9IFJlcXVp
cmVkLiBUaGUgbmFtZSBvZiB0aGUgVXNlciBTdG9yZSB0byBnZXQuCiBGb3JtYXQ6CiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3VzZXJTdG9yZXMve3VzZXJf
c3RvcmVfaWR9YAoKDAoFBAACAAUSA0ICCAoMCgUEAAIAARIDQgkNCgwKBQQAAgADEgNCEBEK
DQoFBAACAAgSBEISRwMKDwoIBAACAAicCAASA0MEKgoPCgcEAAIACJ8IEgREBEYFCpEBCgIE
ARIETQBWARqEASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVXNlclN0b3JlU2VydmljZS5VcGRh
dGVVc2VyU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXNlclN0b3Jl
U2VydmljZS5VcGRhdGVVc2VyU3RvcmVdCiBtZXRob2QuCgoKCgMEAQESA00IHgqBAQoEBAEC
ABIDUQJEGnQgUmVxdWlyZWQuIFRoZSBVc2VyIFN0b3JlIHRvIHVwZGF0ZS4KIEZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdXNlclN0b3Jlcy97
dXNlcl9zdG9yZV9pZH1gCgoMCgUEAQIABhIDUQILCgwKBQQBAgABEgNRDBYKDAoFBAECAAMS
A1EZGgoMCgUEAQIACBIDURtDCg8KCAQBAgAInAgAEgNRHEIKNwoEBAECARIEVAJVLxopIE9w
dGlvbmFsLiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gdXBkYXRlLgoKDAoFBAECAQYSA1QCGwoM
CgUEAQIBARIDVBwnCgwKBQQBAgEDEgNUKisKDAoFBAECAQgSA1UGLgoPCggEAQIBCJwIABID
VQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::UserStoreService::GetUserStoreRequest ===
    # Fields for GetUserStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::UserStoreService::UpdateUserStoreRequest ===
    # Fields for UpdateUserStoreRequest
    # Field: user_store Type: 11 (.google.cloud.discoveryengine.v1.UserStore)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Discoveryengine::V1::UserStoreService::UserStoreServiceClient ===
package Google::Cloud::Discoveryengine::V1::UserStoreService::UserStoreServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::UserStoreService::UserStoreServiceClient

Client stub representing the remote C<UserStoreService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub get_user_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::UserStoreService::GetUserStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserStoreService',
        method         => 'GetUserStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::UserStore::UserStore',
    });
}

sub update_user_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::UserStoreService::UpdateUserStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserStoreService',
        method         => 'UpdateUserStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::UserStore::UserStore',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::UserStoreService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/user_store_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::UserStoreService;

    my $msg = Google::Cloud::Discoveryengine::V1::UserStoreService::GetUserStoreRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::UserStoreService::GetUserStoreRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/user_store_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::UserStoreService::GetUserStoreRequest

Request message for
[UserStoreService.GetUserStore][google.cloud.discoveryengine.v1.UserStoreService.GetUserStore]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the User Store to get.
Format:
`projects/{project}/locations/{location}/userStores/{user_store_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1::UserStoreService::UpdateUserStoreRequest

Request message for
[UserStoreService.UpdateUserStore][google.cloud.discoveryengine.v1.UserStoreService.UpdateUserStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_store() >> / C<< $msg->user_store($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::UserStore::UserStore>)

Required. The User Store to update.
Format:
`projects/{project}/locations/{location}/userStores/{user_store_id}`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::UserStoreService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
