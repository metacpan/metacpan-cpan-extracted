package Google::Cloud::Retail::V2alpha::AnalyticsService;

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
    eval { require Google::Cloud::Retail::V2alpha::ExportConfig };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvYW5hbHl0aWNzX3NlcnZpY2UucHJvdG8S
G2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aL2dvb2dsZS9jbG91ZC9yZXRh
aWwvdjJhbHBoYS9leHBvcnRfY29uZmlnLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3Bl
cmF0aW9ucy5wcm90bzKXAwoQQW5hbHl0aWNzU2VydmljZRK3AgoWRXhwb3J0QW5hbHl0aWNz
TWV0cmljcxI6Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5FeHBvcnRBbmFseXRpY3NN
ZXRyaWNzUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iwQGC0+STAlAi
Sy92MmFscGhhL3tjYXRhbG9nPXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn06
ZXhwb3J0QW5hbHl0aWNzTWV0cmljczoBKspBaAo6Z29vZ2xlLmNsb3VkLnJldGFpbC52MmFs
cGhhLkV4cG9ydEFuYWx5dGljc01ldHJpY3NSZXNwb25zZRIqZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmFscGhhLkV4cG9ydE1ldGFkYXRhGknKQRVyZXRhaWwuZ29vZ2xlYXBpcy5jb23SQS5o
dHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQtkBCh9jb20u
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhQhVBbmFseXRpY3NTZXJ2aWNlUHJvdG9QAVo3
Y2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjJhbHBoYS9yZXRhaWxwYjtyZXRhaWxw
YqICBlJFVEFJTKoCG0dvb2dsZS5DbG91ZC5SZXRhaWwuVjJBbHBoYcoCG0dvb2dsZVxDbG91
ZFxSZXRhaWxcVjJhbHBoYeoCHkdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJhbHBoYUqiCgoG
EgQOADgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkK
AgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAOQoJ
CgIDBRIDFwAtCggKAQgSAxkAOAoJCgIIJRIDGQA4CggKAQgSAxoATgoJCgIICxIDGgBOCggK
AQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwANgoJCgIICBIDHAA2CggKAQgSAx0AOAoJCgII
ARIDHQA4CggKAQgSAx4AJAoJCgIIJBIDHgAkCggKAQgSAx8AOAoJCgIIKRIDHwA4CggKAQgS
AyAANwoJCgIILRIDIAA3CpEBCgIGABIEJAA4ARqEASBTZXJ2aWNlIGZvciBtYW5hZ2luZyAm
IGFjY2Vzc2luZyByZXRhaWwgc2VhcmNoIGJ1c2luZXNzIG1ldHJpYy4KIFJldGFpbCByZWNv
bW1lbmRhdGlvbiBidXNpbmVzcyBtZXRyaWMgaXMgY3VycmVudGx5IG5vdCBhdmFpbGFibGUu
CgoKCgMGAAESAyQIGAoKCgMGAAMSAyUCPQoMCgUGAAOZCBIDJQI9CgsKAwYAAxIEJgInNwoN
CgUGAAOaCBIEJgInNwqiAQoEBgACABIELQI3AxqTASBFeHBvcnRzIGFuYWx5dGljcyBtZXRy
aWNzLgoKIGBPcGVyYXRpb24ucmVzcG9uc2VgIGlzIG9mIHR5cGUgYEV4cG9ydEFuYWx5dGlj
c01ldHJpY3NSZXNwb25zZWAuCiBgT3BlcmF0aW9uLm1ldGFkYXRhYCBpcyBvZiB0eXBlIGBF
eHBvcnRNZXRhZGF0YWAuCgoMCgUGAAIAARIDLQYcCgwKBQYAAgACEgMtHToKDAoFBgACAAMS
Ay4PKwoNCgUGAAIABBIELwQyBgoRCgkGAAIABLDKvCISBC8EMgYKDQoFBgACAAQSBDMENgYK
DwoHBgACAASZCBIEMwQ2BmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Retail::V2alpha::AnalyticsService::AnalyticsServiceClient ===
package Google::Cloud::Retail::V2alpha::AnalyticsService::AnalyticsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2alpha::AnalyticsService::AnalyticsServiceClient

Client stub representing the remote C<AnalyticsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub export_analytics_metrics {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2alpha::ExportConfig::ExportAnalyticsMetricsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2alpha.AnalyticsService',
        method         => 'ExportAnalyticsMetrics',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::AnalyticsService - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/analytics_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/analytics_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::AnalyticsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
