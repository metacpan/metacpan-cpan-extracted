package Google::Cloud::Iap::V1beta1::Service;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvaWFwL3YxYmV0YTEvc2VydmljZS5wcm90bxIYZ29vZ2xlLmNsb3Vk
LmlhcC52MWJldGExGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBp
L2NsaWVudC5wcm90bxoeZ29vZ2xlL2lhbS92MS9pYW1fcG9saWN5LnByb3RvGhpnb29nbGUv
aWFtL3YxL3BvbGljeS5wcm90bzKABAoeSWRlbnRpdHlBd2FyZVByb3h5QWRtaW5WMUJldGEx
EnkKDFNldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuU2V0SWFtUG9saWN5UmVxdWVzdBoV
Lmdvb2dsZS5pYW0udjEuUG9saWN5Ii6C0+STAigiIy92MWJldGExL3tyZXNvdXJjZT0qKn06
c2V0SWFtUG9saWN5OgEqEnkKDEdldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuR2V0SWFt
UG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5Ii6C0+STAigiIy92MWJldGEx
L3tyZXNvdXJjZT0qKn06Z2V0SWFtUG9saWN5OgEqEp8BChJUZXN0SWFtUGVybWlzc2lvbnMS
KC5nb29nbGUuaWFtLnYxLlRlc3RJYW1QZXJtaXNzaW9uc1JlcXVlc3QaKS5nb29nbGUuaWFt
LnYxLlRlc3RJYW1QZXJtaXNzaW9uc1Jlc3BvbnNlIjSC0+STAi4iKS92MWJldGExL3tyZXNv
dXJjZT0qKn06dGVzdElhbVBlcm1pc3Npb25zOgEqGkbKQRJpYXAuZ29vZ2xlYXBpcy5jb23S
QS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQlAKHGNv
bS5nb29nbGUuY2xvdWQuaWFwLnYxYmV0YTFQAVouY2xvdWQuZ29vZ2xlLmNvbS9nby9pYXAv
YXBpdjFiZXRhMS9pYXBwYjtpYXBwYkq5DwoGEgQOAEYBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhID
FAAoCgkKAgMDEgMVACQKCAoBCBIDFwBFCgkKAggLEgMXAEUKCAoBCBIDGAAiCgkKAggKEgMY
ACIKCAoBCBIDGQA1CgkKAggBEgMZADUKQQoCBgASBBwARgEaNSBBUElzIGZvciBJZGVudGl0
eS1Bd2FyZSBQcm94eSBBZG1pbiBjb25maWd1cmF0aW9ucy4KCgoKAwYAARIDHAgmCgoKAwYA
AxIDHQI6CgwKBQYAA5kIEgMdAjoKCwoDBgADEgQeAh83Cg0KBQYAA5oIEgQeAh83Co4CCgQG
AAIAEgQlAisDGv8BIFNldHMgdGhlIGFjY2VzcyBjb250cm9sIHBvbGljeSBmb3IgYW4gSWRl
bnRpdHktQXdhcmUgUHJveHkgcHJvdGVjdGVkCiByZXNvdXJjZS4gUmVwbGFjZXMgYW55IGV4
aXN0aW5nIHBvbGljeS4KIE1vcmUgaW5mb3JtYXRpb24gYWJvdXQgbWFuYWdpbmcgYWNjZXNz
IHZpYSBJQVAgY2FuIGJlIGZvdW5kIGF0OgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lh
cC9kb2NzL21hbmFnaW5nLWFjY2VzcyNtYW5hZ2luZ19hY2Nlc3NfdmlhX3RoZV9hcGkKCgwK
BQYAAgABEgMlBhIKDAoFBgACAAISAyUTNAoMCgUGAAIAAxIDJg8jCg0KBQYAAgAEEgQnBCoG
ChEKCQYAAgAEsMq8IhIEJwQqBgrwAQoEBgACARIEMQI3AxrhASBHZXRzIHRoZSBhY2Nlc3Mg
Y29udHJvbCBwb2xpY3kgZm9yIGFuIElkZW50aXR5LUF3YXJlIFByb3h5IHByb3RlY3RlZAog
cmVzb3VyY2UuCiBNb3JlIGluZm9ybWF0aW9uIGFib3V0IG1hbmFnaW5nIGFjY2VzcyB2aWEg
SUFQIGNhbiBiZSBmb3VuZCBhdDoKIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9pYXAvZG9j
cy9tYW5hZ2luZy1hY2Nlc3MjbWFuYWdpbmdfYWNjZXNzX3ZpYV90aGVfYXBpCgoMCgUGAAIB
ARIDMQYSCgwKBQYAAgECEgMxEzQKDAoFBgACAQMSAzIPIwoNCgUGAAIBBBIEMwQ2BgoRCgkG
AAIBBLDKvCISBDMENgYKjQMKBAYAAgISBD8CRQMa/gIgUmV0dXJucyBwZXJtaXNzaW9ucyB0
aGF0IGEgY2FsbGVyIGhhcyBvbiB0aGUgSWRlbnRpdHktQXdhcmUgUHJveHkgcHJvdGVjdGVk
CiByZXNvdXJjZS4gSWYgdGhlIHJlc291cmNlIGRvZXMgbm90IGV4aXN0IG9yIHRoZSBjYWxs
ZXIgZG9lcyBub3QgaGF2ZQogSWRlbnRpdHktQXdhcmUgUHJveHkgcGVybWlzc2lvbnMgYSBb
Z29vZ2xlLnJwYy5Db2RlLlBFUk1JU1NJT05fREVOSUVEXQogd2lsbCBiZSByZXR1cm5lZC4K
IE1vcmUgaW5mb3JtYXRpb24gYWJvdXQgbWFuYWdpbmcgYWNjZXNzIHZpYSBJQVAgY2FuIGJl
IGZvdW5kIGF0OgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhcC9kb2NzL21hbmFnaW5n
LWFjY2VzcyNtYW5hZ2luZ19hY2Nlc3NfdmlhX3RoZV9hcGkKCgwKBQYAAgIBEgM/BhgKDAoF
BgACAgISAz8ZQAoMCgUGAAICAxIDQA83Cg0KBQYAAgIEEgRBBEQGChEKCQYAAgIEsMq8IhIE
QQREBmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Iap::V1beta1::Service::IdentityAwareProxyAdminV1Beta1Client ===
package Google::Cloud::Iap::V1beta1::Service::IdentityAwareProxyAdminV1Beta1Client;

=pod

=head2 Service Client: Google::Cloud::Iap::V1beta1::Service::IdentityAwareProxyAdminV1Beta1Client

Client stub representing the remote C<IdentityAwareProxyAdminV1Beta1> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<iap.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'iap.googleapis.com:443' );

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

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.iap.v1beta1.IdentityAwareProxyAdminV1Beta1',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.iap.v1beta1.IdentityAwareProxyAdminV1Beta1',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.iap.v1beta1.IdentityAwareProxyAdminV1Beta1',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Iap::V1beta1::Service - Compiled Protocol Buffers messages for google/cloud/iap/v1beta1/service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/iap/v1beta1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Iap::V1beta1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
