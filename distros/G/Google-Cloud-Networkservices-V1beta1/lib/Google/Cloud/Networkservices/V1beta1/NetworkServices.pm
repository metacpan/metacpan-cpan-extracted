package Google::Cloud::Networkservices::V1beta1::NetworkServices;

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
    eval { require Google::Cloud::Networkservices::V1beta1::EndpointPolicy };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxYmV0YTEvbmV0d29ya19zZXJ2aWNl
cy5wcm90bxIkZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MWJldGExGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxo6Z29vZ2xl
L2Nsb3VkL25ldHdvcmtzZXJ2aWNlcy92MWJldGExL2VuZHBvaW50X3BvbGljeS5wcm90bxoj
Z29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8yzwsKD05ldHdvcmtTZXJ2aWNl
cxLpAQoUTGlzdEVuZHBvaW50UG9saWNpZXMSQS5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZp
Y2VzLnYxYmV0YTEuTGlzdEVuZHBvaW50UG9saWNpZXNSZXF1ZXN0GkIuZ29vZ2xlLmNsb3Vk
Lm5ldHdvcmtzZXJ2aWNlcy52MWJldGExLkxpc3RFbmRwb2ludFBvbGljaWVzUmVzcG9uc2Ui
SoLT5JMCOxI5L3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9lbmRw
b2ludFBvbGljaWVz2kEGcGFyZW50EtMBChFHZXRFbmRwb2ludFBvbGljeRI+Lmdvb2dsZS5j
bG91ZC5uZXR3b3Jrc2VydmljZXMudjFiZXRhMS5HZXRFbmRwb2ludFBvbGljeVJlcXVlc3Qa
NC5nb29nbGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEuRW5kcG9pbnRQb2xpY3ki
SILT5JMCOxI5L3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9lbmRwb2lu
dFBvbGljaWVzLyp92kEEbmFtZRLEAgoUQ3JlYXRlRW5kcG9pbnRQb2xpY3kSQS5nb29nbGUu
Y2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEuQ3JlYXRlRW5kcG9pbnRQb2xpY3lSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLJAYLT5JMCTCI5L3YxYmV0YTEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9lbmRwb2ludFBvbGljaWVzOg9lbmRw
b2ludF9wb2xpY3naQSlwYXJlbnQsZW5kcG9pbnRfcG9saWN5LGVuZHBvaW50X3BvbGljeV9p
ZMpBSAoORW5kcG9pbnRQb2xpY3kSNmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjFi
ZXRhMS5PcGVyYXRpb25NZXRhZGF0YRLGAgoUVXBkYXRlRW5kcG9pbnRQb2xpY3kSQS5nb29n
bGUuY2xvdWQubmV0d29ya3NlcnZpY2VzLnYxYmV0YTEuVXBkYXRlRW5kcG9pbnRQb2xpY3lS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLLAYLT5JMCXDJJL3YxYmV0
YTEve2VuZHBvaW50X3BvbGljeS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZW5kcG9p
bnRQb2xpY2llcy8qfToPZW5kcG9pbnRfcG9saWN52kEbZW5kcG9pbnRfcG9saWN5LHVwZGF0
ZV9tYXNrykFICg5FbmRwb2ludFBvbGljeRI2Z29vZ2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNl
cy52MWJldGExLk9wZXJhdGlvbk1ldGFkYXRhEpUCChREZWxldGVFbmRwb2ludFBvbGljeRJB
Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjFiZXRhMS5EZWxldGVFbmRwb2ludFBv
bGljeVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIpoBgtPkkwI7Kjkv
djFiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2VuZHBvaW50UG9saWNpZXMv
Kn3aQQRuYW1lykFPChVnb29nbGUucHJvdG9idWYuRW1wdHkSNmdvb2dsZS5jbG91ZC5uZXR3
b3Jrc2VydmljZXMudjFiZXRhMS5PcGVyYXRpb25NZXRhZGF0YRpSykEebmV0d29ya3NlcnZp
Y2VzLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
bG91ZC1wbGF0Zm9ybUL4AQooY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjFi
ZXRhMVABWlJjbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtzZXJ2aWNlcy9hcGl2MWJldGEx
L25ldHdvcmtzZXJ2aWNlc3BiO25ldHdvcmtzZXJ2aWNlc3BiqgIkR29vZ2xlLkNsb3VkLk5l
dHdvcmtTZXJ2aWNlcy5WMUJldGExygIkR29vZ2xlXENsb3VkXE5ldHdvcmtTZXJ2aWNlc1xW
MWJldGEx6gInR29vZ2xlOjpDbG91ZDo6TmV0d29ya1NlcnZpY2VzOjpWMWJldGExSrgOCgYS
BA4AXgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC0KCQoC
AwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUAEQKCQoCAwMSAxUALQoICgEIEgMXAEEKCQoC
CCUSAxcAQQoICgEIEgMYAGkKCQoCCAsSAxgAaQoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEI
EgMaAEEKCQoCCAESAxoAQQoICgEIEgMbAEEKCQoCCCkSAxsAQQoICgEIEgMcAEAKCQoCCC0S
AxwAQAo4CgIGABIEHwBeARosIFNlcnZpY2UgZGVzY3JpYmluZyBoYW5kbGVycyBmb3IgcmVz
b3VyY2VzLgoKCgoDBgABEgMfCBcKCgoDBgADEgMgAkYKDAoFBgADmQgSAyACRgoLCgMGAAMS
BCECIjcKDQoFBgADmggSBCECIjcKRwoEBgACABIEJQIrAxo5IExpc3RzIEVuZHBvaW50UG9s
aWNpZXMgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgABEgMlBhoK
DAoFBgACAAISAyUbNgoMCgUGAAIAAxIDJg8rCg0KBQYAAgAEEgQnBCkGChEKCQYAAgAEsMq8
IhIEJwQpBgoMCgUGAAIABBIDKgQ0Cg8KCAYAAgAEmwgAEgMqBDQKOAoEBgACARIELgIzAxoq
IEdldHMgZGV0YWlscyBvZiBhIHNpbmdsZSBFbmRwb2ludFBvbGljeS4KCgwKBQYAAgEBEgMu
BhcKDAoFBgACAQISAy4YMAoMCgUGAAIBAxIDLjtJCg0KBQYAAgEEEgQvBDEGChEKCQYAAgEE
sMq8IhIELwQxBgoMCgUGAAIBBBIDMgQyCg8KCAYAAgEEmwgAEgMyBDIKTQoEBgACAhIENgJC
Axo/IENyZWF0ZXMgYSBuZXcgRW5kcG9pbnRQb2xpY3kgaW4gYSBnaXZlbiBwcm9qZWN0IGFu
ZCBsb2NhdGlvbi4KCgwKBQYAAgIBEgM2BhoKDAoFBgACAgISAzYbNgoMCgUGAAICAxIDNw8r
Cg0KBQYAAgIEEgQ4BDsGChEKCQYAAgIEsMq8IhIEOAQ7BgoNCgUGAAICBBIEPAQ9NAoQCggG
AAICBJsIABIEPAQ9NAoNCgUGAAICBBIEPgRBBgoPCgcGAAICBJkIEgQ+BEEGCkIKBAYAAgMS
BEUCUAMaNCBVcGRhdGVzIHRoZSBwYXJhbWV0ZXJzIG9mIGEgc2luZ2xlIEVuZHBvaW50UG9s
aWN5LgoKDAoFBgACAwESA0UGGgoMCgUGAAIDAhIDRRs2CgwKBQYAAgMDEgNGDysKDQoFBgAC
AwQSBEcESgYKEQoJBgACAwSwyrwiEgRHBEoGCgwKBQYAAgMEEgNLBEkKDwoIBgACAwSbCAAS
A0sESQoNCgUGAAIDBBIETARPBgoPCgcGAAIDBJkIEgRMBE8GCjAKBAYAAgQSBFMCXQMaIiBE
ZWxldGVzIGEgc2luZ2xlIEVuZHBvaW50UG9saWN5LgoKDAoFBgACBAESA1MGGgoMCgUGAAIE
AhIDUxs2CgwKBQYAAgQDEgNUDysKDQoFBgACBAQSBFUEVwYKEQoJBgACBASwyrwiEgRVBFcG
CgwKBQYAAgQEEgNYBDIKDwoIBgACBASbCAASA1gEMgoNCgUGAAIEBBIEWQRcBgoPCgcGAAIE
BJkIEgRZBFwGYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Networkservices::V1beta1::NetworkServices::NetworkServicesClient ===
package Google::Cloud::Networkservices::V1beta1::NetworkServices::NetworkServicesClient;

=pod

=head2 Service Client: Google::Cloud::Networkservices::V1beta1::NetworkServices::NetworkServicesClient

Client stub representing the remote C<NetworkServices> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<networkservices.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networkservices.googleapis.com:443' );

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

sub list_endpoint_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkservices::V1beta1::EndpointPolicy::ListEndpointPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkservices.v1beta1.NetworkServices',
        method         => 'ListEndpointPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Networkservices::V1beta1::EndpointPolicy::ListEndpointPoliciesResponse',
    });
}

sub get_endpoint_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkservices::V1beta1::EndpointPolicy::GetEndpointPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkservices.v1beta1.NetworkServices',
        method         => 'GetEndpointPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Networkservices::V1beta1::EndpointPolicy::EndpointPolicy',
    });
}

sub create_endpoint_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkservices::V1beta1::EndpointPolicy::CreateEndpointPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkservices.v1beta1.NetworkServices',
        method         => 'CreateEndpointPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_endpoint_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkservices::V1beta1::EndpointPolicy::UpdateEndpointPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkservices.v1beta1.NetworkServices',
        method         => 'UpdateEndpointPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_endpoint_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkservices::V1beta1::EndpointPolicy::DeleteEndpointPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkservices.v1beta1.NetworkServices',
        method         => 'DeleteEndpointPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkservices::V1beta1::NetworkServices - Compiled Protocol Buffers messages for google/cloud/networkservices/v1beta1/network_services.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkservices/v1beta1/network_services.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkservices::V1beta1::NetworkServices::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
