package Google::Cloud::Cloudcontrolspartner::V1::Monitoring;

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
    eval { require Google::Cloud::Cloudcontrolspartner::V1::Violations };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvbW9uaXRvcmluZy5wcm90
bxIkZ29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxGhxnb29nbGUvYXBpL2Fu
bm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxo1Z29vZ2xlL2Nsb3Vk
L2Nsb3VkY29udHJvbHNwYXJ0bmVyL3YxL3Zpb2xhdGlvbnMucHJvdG8yvgQKHkNsb3VkQ29u
dHJvbHNQYXJ0bmVyTW9uaXRvcmluZxLpAQoOTGlzdFZpb2xhdGlvbnMSOy5nb29nbGUuY2xv
dWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuTGlzdFZpb2xhdGlvbnNSZXF1ZXN0GjwuZ29v
Z2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxLkxpc3RWaW9sYXRpb25zUmVzcG9u
c2UiXILT5JMCTRJLL3YxL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL2N1
c3RvbWVycy8qL3dvcmtsb2Fkcy8qfS92aW9sYXRpb25z2kEGcGFyZW50EtYBCgxHZXRWaW9s
YXRpb24SOS5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuR2V0VmlvbGF0
aW9uUmVxdWVzdBovLmdvb2dsZS5jbG91ZC5jbG91ZGNvbnRyb2xzcGFydG5lci52MS5WaW9s
YXRpb24iWoLT5JMCTRJLL3YxL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9j
dXN0b21lcnMvKi93b3JrbG9hZHMvKi92aW9sYXRpb25zLyp92kEEbmFtZRpXykEjY2xvdWRj
b250cm9sc3BhcnRuZXIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQpMCCihjb20uZ29vZ2xlLmNsb3VkLmNsb3VkY29u
dHJvbHNwYXJ0bmVyLnYxQg9Nb25pdG9yaW5nUHJvdG9QAVpcY2xvdWQuZ29vZ2xlLmNvbS9n
by9jbG91ZGNvbnRyb2xzcGFydG5lci9hcGl2MS9jbG91ZGNvbnRyb2xzcGFydG5lcnBiO2Ns
b3VkY29udHJvbHNwYXJ0bmVycGKqAiRHb29nbGUuQ2xvdWQuQ2xvdWRDb250cm9sc1BhcnRu
ZXIuVjHKAiRHb29nbGVcQ2xvdWRcQ2xvdWRDb250cm9sc1BhcnRuZXJcVjHqAidHb29nbGU6
OkNsb3VkOjpDbG91ZENvbnRyb2xzUGFydG5lcjo6VjFKkgwKBhIEDgA5AQq8BAoBDBIDDgAS
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
ACEKCQoCAwISAxQAPwoICgEIEgMWAEEKCQoCCCUSAxYAQQoICgEIEgMXAHMKCQoCCAsSAxcA
cwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADAKCQoCCAgSAxkAMAoICgEIEgMaAEEK
CQoCCAESAxoAQQoICgEIEgMbAEEKCQoCCCkSAxsAQQoICgEIEgMcAEAKCQoCCC0SAxwAQAo3
CgIGABIEHwA5ARorIFNlcnZpY2UgZGVzY3JpYmluZyBoYW5kbGVycyBmb3IgcmVzb3VyY2Vz
CgoKCgMGAAESAx8IJgoKCgMGAAMSAyACSwoMCgUGAAOZCBIDIAJLCgsKAwYAAxIEIQIiNwoN
CgUGAAOaCBIEIQIiNwqEAwoEBgACABIEKwIwAxr1AiBMaXN0cyBWaW9sYXRpb25zIGZvciBh
IHdvcmtsb2FkCiBDYWxsZXJzIG1heSBhbHNvIGNob29zZSB0byByZWFkIGFjcm9zcyBtdWx0
aXBsZSBDdXN0b21lcnMgb3IgZm9yIGEgc2luZ2xlCiBjdXN0b21lciBhcyBwZXIKIFtBSVAt
MTU5XShodHRwczovL2dvb2dsZS5haXAuZGV2LzE1OSkgYnkgdXNpbmcgJy0nICh0aGUgaHlw
aGVuIG9yIGRhc2gKIGNoYXJhY3RlcikgYXMgYSB3aWxkY2FyZCBjaGFyYWN0ZXIgaW5zdGVh
ZCBvZiB7Y3VzdG9tZXJ9ICYge3dvcmtsb2FkfS4KIEZvcm1hdDoKIGBvcmdhbml6YXRpb25z
L3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L2N1c3RvbWVycy97Y3VzdG9t
ZXJ9L3dvcmtsb2Fkcy97d29ya2xvYWR9YAoKDAoFBgACAAESAysGFAoMCgUGAAIAAhIDKxUq
CgwKBQYAAgADEgMrNUsKDQoFBgACAAQSBCwELgYKEQoJBgACAASwyrwiEgQsBC4GCgwKBQYA
AgAEEgMvBDQKDwoIBgACAASbCAASAy8ENAozCgQGAAIBEgQzAjgDGiUgR2V0cyBkZXRhaWxz
IG9mIGEgc2luZ2xlIFZpb2xhdGlvbi4KCgwKBQYAAgEBEgMzBhIKDAoFBgACAQISAzMTJgoM
CgUGAAIBAxIDMzE6Cg0KBQYAAgEEEgQ0BDYGChEKCQYAAgEEsMq8IhIENAQ2BgoMCgUGAAIB
BBIDNwQyCg8KCAYAAgEEmwgAEgM3BDJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Cloudcontrolspartner::V1::Monitoring::CloudControlsPartnerMonitoringClient ===
package Google::Cloud::Cloudcontrolspartner::V1::Monitoring::CloudControlsPartnerMonitoringClient;

=pod

=head2 Service Client: Google::Cloud::Cloudcontrolspartner::V1::Monitoring::CloudControlsPartnerMonitoringClient

Client stub representing the remote C<CloudControlsPartnerMonitoring> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<cloudcontrolspartner.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'cloudcontrolspartner.googleapis.com:443' );

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

sub list_violations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerMonitoring',
        method         => 'ListViolations',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::Violations::ListViolationsResponse',
    });
}

sub get_violation {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Cloudcontrolspartner::V1::Violations::GetViolationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerMonitoring',
        method         => 'GetViolation',
        request        => $req,
        response_class => 'Google::Cloud::Cloudcontrolspartner::V1::Violations::Violation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::Monitoring - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/monitoring.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/monitoring.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::Monitoring::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
