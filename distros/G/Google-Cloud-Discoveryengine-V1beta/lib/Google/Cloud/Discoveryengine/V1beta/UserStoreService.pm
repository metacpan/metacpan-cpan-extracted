package Google::Cloud::Discoveryengine::V1beta::UserStoreService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::UserStore };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS91c2VyX3N0b3JlX3NlcnZp
Y2UucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo0
Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvdXNlcl9zdG9yZS5wcm90bxog
Z29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8iWwoTR2V0VXNlclN0b3JlUmVxdWVz
dBJECgRuYW1lGAEgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9Vc2VyU3RvcmVSBG5hbWUirgEKFlVwZGF0ZVVzZXJTdG9yZVJlcXVlc3QSUgoKdXNlcl9z
dG9yZRgBIAEoCzIuLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVzZXJT
dG9yZUID4EECUgl1c2VyU3RvcmUSQAoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2syjwUKEFVzZXJTdG9yZVNlcnZpY2US
uwEKDEdldFVzZXJTdG9yZRI4Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
LkdldFVzZXJTdG9yZVJlcXVlc3QaLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5Vc2VyU3RvcmUiQYLT5JMCNBIyL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL3VzZXJTdG9yZXMvKn3aQQRuYW1lEuoBCg9VcGRhdGVVc2VyU3RvcmUSOy5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5VcGRhdGVVc2VyU3RvcmVSZXF1ZXN0
Gi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVXNlclN0b3JlImqC0+ST
AksyPS92MWJldGEve3VzZXJfc3RvcmUubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3Vz
ZXJTdG9yZXMvKn06CnVzZXJfc3RvcmXaQRZ1c2VyX3N0b3JlLHVwZGF0ZV9tYXNrGs8BykEe
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQpwCCidjb20uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFCFVVzZXJTdG9yZVNlcnZpY2VQcm90
b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWJldGEvZGlz
Y292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiNH
b29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0YcoCI0dvb2dsZVxDbG91ZFxEaXNj
b3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpW
MWJldGFKwxAKBhIEDgBWAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAALAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkK
AgMEEgMWAD4KCQoCAwUSAxcAKgoICgEIEgMZAEAKCQoCCCUSAxkAQAoICgEIEgMaAGgKCQoC
CAsSAxoAaAoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADYKCQoCCAgSAxwANgoICgEI
EgMdAEAKCQoCCAESAx0AQAoICgEIEgMeAC0KCQoCCCQSAx4ALQoICgEIEgMfAEAKCQoCCCkS
Ax8AQAoICgEIEgMgAD8KCQoCCC0SAyAAPwovCgIGABIEIwA6ARojIFNlcnZpY2UgZm9yIG1h
bmFnaW5nIFVzZXIgU3RvcmVzLgoKCgoDBgABEgMjCBgKCgoDBgADEgMkAkYKDAoFBgADmQgS
AyQCRgoLCgMGAAMSBCUCKEoKDQoFBgADmggSBCUCKEoKJAoEBgACABIEKwIwAxoWIEdldHMg
dGhlIFVzZXIgU3RvcmUuCgoMCgUGAAIAARIDKwYSCgwKBQYAAgACEgMrEyYKDAoFBgACAAMS
AysxOgoNCgUGAAIABBIELAQuBgoRCgkGAAIABLDKvCISBCwELgYKDAoFBgACAAQSAy8EMgoP
CggGAAIABJsIABIDLwQyCicKBAYAAgESBDMCOQMaGSBVcGRhdGVzIHRoZSBVc2VyIFN0b3Jl
LgoKDAoFBgACAQESAzMGFQoMCgUGAAIBAhIDMxYsCgwKBQYAAgEDEgMzN0AKDQoFBgACAQQS
BDQENwYKEQoJBgACAQSwyrwiEgQ0BDcGCgwKBQYAAgEEEgM4BEQKDwoIBgACAQSbCAASAzgE
RAqFAQoCBAASBD4ASAEaeSBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVXNlclN0b3JlU2Vydmlj
ZS5HZXRVc2VyU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVz
ZXJTdG9yZVNlcnZpY2UuR2V0VXNlclN0b3JlXQoKCgoDBAABEgM+CBsKiwEKBAQAAgASBEIC
RwQafSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIFVzZXIgU3RvcmUgdG8gZ2V0LgogRm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS91c2VyU3Rv
cmVzL3t1c2VyX3N0b3JlX2lkfWAKCgwKBQQAAgAFEgNCAggKDAoFBAACAAESA0IJDQoMCgUE
AAIAAxIDQhARCg0KBQQAAgAIEgRCEkcDCg8KCAQAAgAInAgAEgNDBCoKDwoHBAACAAifCBIE
RARGBQqVAQoCBAESBE0AVgEaiAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW1VzZXJTdG9yZVNl
cnZpY2UuVXBkYXRlVXNlclN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5Vc2VyU3RvcmVTZXJ2aWNlLlVwZGF0ZVVzZXJTdG9yZV0KIG1ldGhvZC4KCgoKAwQB
ARIDTQgeCoEBCgQEAQIAEgNRAkQadCBSZXF1aXJlZC4gVGhlIFVzZXIgU3RvcmUgdG8gdXBk
YXRlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS91c2VyU3RvcmVzL3t1c2VyX3N0b3JlX2lkfWAKCgwKBQQBAgAGEgNRAgsKDAoFBAECAAES
A1EMFgoMCgUEAQIAAxIDURkaCgwKBQQBAgAIEgNRG0MKDwoIBAECAAicCAASA1EcQgo3CgQE
AQIBEgRUAlUvGikgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuCgoM
CgUEAQIBBhIDVAIbCgwKBQQBAgEBEgNUHCcKDAoFBAECAQMSA1QqKwoMCgUEAQIBCBIDVQYu
Cg8KCAQBAgEInAgAEgNVBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest ===
    # Fields for GetUserStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::UserStoreService::UpdateUserStoreRequest ===
    # Fields for UpdateUserStoreRequest
    # Field: user_store Type: 11 (.google.cloud.discoveryengine.v1beta.UserStore)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::UserStoreService::UserStoreServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::UserStoreService::UserStoreServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::UserStoreService::UserStoreServiceClient

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
        ? Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserStoreService',
        method         => 'GetUserStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore',
    });
}

sub update_user_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::UserStoreService::UpdateUserStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserStoreService',
        method         => 'UpdateUserStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::UserStoreService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/user_store_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::UserStoreService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/user_store_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest

Request message for
[UserStoreService.GetUserStore][google.cloud.discoveryengine.v1beta.UserStoreService.GetUserStore]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the User Store to get.
Format:
`projects/{project}/locations/{location}/userStores/{user_store_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserStoreService::UpdateUserStoreRequest

Request message for
[UserStoreService.UpdateUserStore][google.cloud.discoveryengine.v1beta.UserStoreService.UpdateUserStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_store() >> / C<< $msg->user_store($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore>)

Required. The User Store to update.
Format:
`projects/{project}/locations/{location}/userStores/{user_store_id}`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::UserStoreService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
