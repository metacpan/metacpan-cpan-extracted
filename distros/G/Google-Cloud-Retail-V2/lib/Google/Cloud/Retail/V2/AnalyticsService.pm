package Google::Cloud::Retail::V2::AnalyticsService;

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
    eval { require Google::Cloud::Retail::V2::ExportConfig };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvcmV0YWlsL3YyL2FuYWx5dGljc19zZXJ2aWNlLnByb3RvEhZnb29n
bGUuY2xvdWQucmV0YWlsLnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoqZ29vZ2xlL2Nsb3VkL3JldGFpbC92Mi9leHBv
cnRfY29uZmlnLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90bzKD
AwoQQW5hbHl0aWNzU2VydmljZRKjAgoWRXhwb3J0QW5hbHl0aWNzTWV0cmljcxI1Lmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjIuRXhwb3J0QW5hbHl0aWNzTWV0cmljc1JlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrIBgtPkkwJLIkYvdjIve2NhdGFsb2c9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9jYXRhbG9ncy8qfTpleHBvcnRBbmFseXRpY3NNZXRyaWNzOgEq
ykFeCjVnb29nbGUuY2xvdWQucmV0YWlsLnYyLkV4cG9ydEFuYWx5dGljc01ldHJpY3NSZXNw
b25zZRIlZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5FeHBvcnRNZXRhZGF0YRpJykEVcmV0YWls
Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybULAAQoaY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJCFUFuYWx5dGljc1Nl
cnZpY2VQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL3JldGFpbC9hcGl2Mi9yZXRhaWxw
YjtyZXRhaWxwYqICBlJFVEFJTKoCFkdvb2dsZS5DbG91ZC5SZXRhaWwuVjLKAhZHb29nbGVc
Q2xvdWRcUmV0YWlsXFYy6gIZR29vZ2xlOjpDbG91ZDo6UmV0YWlsOjpWMkqiCgoGEgQOADgB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANAoJCgIDBRID
FwAtCggKAQgSAxkAMwoJCgIIJRIDGQAzCggKAQgSAxoASQoJCgIICxIDGgBJCggKAQgSAxsA
IgoJCgIIChIDGwAiCggKAQgSAxwANgoJCgIICBIDHAA2CggKAQgSAx0AMwoJCgIIARIDHQAz
CggKAQgSAx4AJAoJCgIIJBIDHgAkCggKAQgSAx8AMwoJCgIIKRIDHwAzCggKAQgSAyAAMgoJ
CgIILRIDIAAyCpEBCgIGABIEJAA4ARqEASBTZXJ2aWNlIGZvciBtYW5hZ2luZyAmIGFjY2Vz
c2luZyByZXRhaWwgc2VhcmNoIGJ1c2luZXNzIG1ldHJpYy4KIFJldGFpbCByZWNvbW1lbmRh
dGlvbiBidXNpbmVzcyBtZXRyaWMgaXMgY3VycmVudGx5IG5vdCBhdmFpbGFibGUuCgoKCgMG
AAESAyQIGAoKCgMGAAMSAyUCPQoMCgUGAAOZCBIDJQI9CgsKAwYAAxIEJgInNwoNCgUGAAOa
CBIEJgInNwqiAQoEBgACABIELQI3AxqTASBFeHBvcnRzIGFuYWx5dGljcyBtZXRyaWNzLgoK
IGBPcGVyYXRpb24ucmVzcG9uc2VgIGlzIG9mIHR5cGUgYEV4cG9ydEFuYWx5dGljc01ldHJp
Y3NSZXNwb25zZWAuCiBgT3BlcmF0aW9uLm1ldGFkYXRhYCBpcyBvZiB0eXBlIGBFeHBvcnRN
ZXRhZGF0YWAuCgoMCgUGAAIAARIDLQYcCgwKBQYAAgACEgMtHToKDAoFBgACAAMSAy4PKwoN
CgUGAAIABBIELwQyBgoRCgkGAAIABLDKvCISBC8EMgYKDQoFBgACAAQSBDMENgYKDwoHBgAC
AASZCBIEMwQ2BmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Retail::V2::AnalyticsService::AnalyticsServiceClient ===
package Google::Cloud::Retail::V2::AnalyticsService::AnalyticsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2::AnalyticsService::AnalyticsServiceClient

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
        ? Google::Cloud::Retail::V2::ExportConfig::ExportAnalyticsMetricsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2.AnalyticsService',
        method         => 'ExportAnalyticsMetrics',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::AnalyticsService - Compiled Protocol Buffers messages for google/cloud/retail/v2/analytics_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/analytics_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::AnalyticsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
