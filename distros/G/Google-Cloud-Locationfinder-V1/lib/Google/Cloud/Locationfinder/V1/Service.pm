package Google::Cloud::Locationfinder::V1::Service;

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
    eval { require Google::Cloud::Locationfinder::V1::CloudLocation };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvbG9jYXRpb25maW5kZXIvdjEvc2VydmljZS5wcm90bxIeZ29vZ2xl
LmNsb3VkLmxvY2F0aW9uZmluZGVyLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxozZ29vZ2xlL2Nsb3VkL2xvY2F0aW9uZmluZGVy
L3YxL2Nsb3VkX2xvY2F0aW9uLnByb3RvMvwFChNDbG91ZExvY2F0aW9uRmluZGVyEtABChJM
aXN0Q2xvdWRMb2NhdGlvbnMSOS5nb29nbGUuY2xvdWQubG9jYXRpb25maW5kZXIudjEuTGlz
dENsb3VkTG9jYXRpb25zUmVxdWVzdBo6Lmdvb2dsZS5jbG91ZC5sb2NhdGlvbmZpbmRlci52
MS5MaXN0Q2xvdWRMb2NhdGlvbnNSZXNwb25zZSJDgtPkkwI0EjIvdjEve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qfS9jbG91ZExvY2F0aW9uc9pBBnBhcmVudBK9AQoQR2V0Q2xv
dWRMb2NhdGlvbhI3Lmdvb2dsZS5jbG91ZC5sb2NhdGlvbmZpbmRlci52MS5HZXRDbG91ZExv
Y2F0aW9uUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5sb2NhdGlvbmZpbmRlci52MS5DbG91ZExv
Y2F0aW9uIkGC0+STAjQSMi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nsb3Vk
TG9jYXRpb25zLyp92kEEbmFtZRL5AQoUU2VhcmNoQ2xvdWRMb2NhdGlvbnMSOy5nb29nbGUu
Y2xvdWQubG9jYXRpb25maW5kZXIudjEuU2VhcmNoQ2xvdWRMb2NhdGlvbnNSZXF1ZXN0Gjwu
Z29vZ2xlLmNsb3VkLmxvY2F0aW9uZmluZGVyLnYxLlNlYXJjaENsb3VkTG9jYXRpb25zUmVz
cG9uc2UiZoLT5JMCOxI5L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vY2xv
dWRMb2NhdGlvbnM6c2VhcmNo2kEicGFyZW50LHNvdXJjZV9jbG91ZF9sb2NhdGlvbixxdWVy
eRpWykEiY2xvdWRsb2NhdGlvbmZpbmRlci5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C5gEKImNvbS5nb29nbGUuY2xv
dWQubG9jYXRpb25maW5kZXIudjFCDFNlcnZpY2VQcm90b1ABWkpjbG91ZC5nb29nbGUuY29t
L2dvL2xvY2F0aW9uZmluZGVyL2FwaXYxL2xvY2F0aW9uZmluZGVycGI7bG9jYXRpb25maW5k
ZXJwYqoCHkdvb2dsZS5DbG91ZC5Mb2NhdGlvbkZpbmRlci5WMcoCHkdvb2dsZVxDbG91ZFxM
b2NhdGlvbkZpbmRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OkxvY2F0aW9uRmluZGVyOjpWMUqt
CwoGEgQOAD0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAn
CgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAA9CggKAQgSAxYAOwoJCgIIJRIDFgA7
CggKAQgSAxcAYQoJCgIICxIDFwBhCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkALQoJ
CgIICBIDGQAtCggKAQgSAxoAOwoJCgIIARIDGgA7CggKAQgSAxsAOwoJCgIIKRIDGwA7CggK
AQgSAxwAOgoJCgIILRIDHAA6CjcKAgYAEgQfAD0BGisgU2VydmljZSBkZXNjcmliaW5nIGhh
bmRsZXJzIGZvciByZXNvdXJjZXMKCgoKAwYAARIDHwgbCgoKAwYAAxIDIAJKCgwKBQYAA5kI
EgMgAkoKCwoDBgADEgQhAiI3Cg0KBQYAA5oIEgQhAiI3CkkKBAYAAgASBCUCKwMaOyBMaXN0
cyBjbG91ZCBsb2NhdGlvbnMgdW5kZXIgYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4K
CgwKBQYAAgABEgMlBhgKDAoFBgACAAISAyUZMgoMCgUGAAIAAxIDJg8pCg0KBQYAAgAEEgQn
BCkGChEKCQYAAgAEsMq8IhIEJwQpBgoMCgUGAAIABBIDKgQ0Cg8KCAYAAgAEmwgAEgMqBDQK
UwoEBgACARIELgIzAxpFIFJldHJpZXZlcyBhIHJlc291cmNlIGNvbnRhaW5pbmcgaW5mb3Jt
YXRpb24gYWJvdXQgYSBjbG91ZCBsb2NhdGlvbi4KCgwKBQYAAgEBEgMuBhYKDAoFBgACAQIS
Ay4XLgoMCgUGAAIBAxIDLjlGCg0KBQYAAgEEEgQvBDEGChEKCQYAAgEEsMq8IhIELwQxBgoM
CgUGAAIBBBIDMgQyCg8KCAYAAgEEmwgAEgMyBDIKSgoEBgACAhIENgI8Axo8IFNlYXJjaGVz
IGZvciBjbG91ZCBsb2NhdGlvbnMgZnJvbSBhIGdpdmVuIHNvdXJjZSBsb2NhdGlvbi4KCgwK
BQYAAgIBEgM2BhoKDAoFBgACAgISAzYbNgoMCgUGAAICAxIDNw8rCg0KBQYAAgIEEgQ4BDoG
ChEKCQYAAgIEsMq8IhIEOAQ6BgoMCgUGAAICBBIDOwRQCg8KCAYAAgIEmwgAEgM7BFBiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Locationfinder::V1::Service::CloudLocationFinderClient ===
package Google::Cloud::Locationfinder::V1::Service::CloudLocationFinderClient;

=pod

=head2 Service Client: Google::Cloud::Locationfinder::V1::Service::CloudLocationFinderClient

Client stub representing the remote C<CloudLocationFinder> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<locationfinder.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'locationfinder.googleapis.com:443' );

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

sub list_cloud_locations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.locationfinder.v1.CloudLocationFinder',
        method         => 'ListCloudLocations',
        request        => $req,
        response_class => 'Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsResponse',
    });
}

sub get_cloud_location {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Locationfinder::V1::CloudLocation::GetCloudLocationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.locationfinder.v1.CloudLocationFinder',
        method         => 'GetCloudLocation',
        request        => $req,
        response_class => 'Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation',
    });
}

sub search_cloud_locations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.locationfinder.v1.CloudLocationFinder',
        method         => 'SearchCloudLocations',
        request        => $req,
        response_class => 'Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Locationfinder::V1::Service - Compiled Protocol Buffers messages for google/cloud/locationfinder/v1/service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/locationfinder/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Locationfinder::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
