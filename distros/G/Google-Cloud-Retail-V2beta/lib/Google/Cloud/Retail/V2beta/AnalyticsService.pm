package Google::Cloud::Retail::V2beta::AnalyticsService;

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
    eval { require Google::Cloud::Retail::V2beta::ExportConfig };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9hbmFseXRpY3Nfc2VydmljZS5wcm90bxIa
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi5nb29nbGUvY2xvdWQvcmV0YWls
L3YyYmV0YS9leHBvcnRfY29uZmlnLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0
aW9ucy5wcm90bzKTAwoQQW5hbHl0aWNzU2VydmljZRKzAgoWRXhwb3J0QW5hbHl0aWNzTWV0
cmljcxI5Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkV4cG9ydEFuYWx5dGljc01ldHJp
Y3NSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiK+AYLT5JMCTyJKL3Yy
YmV0YS97Y2F0YWxvZz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9OmV4cG9y
dEFuYWx5dGljc01ldHJpY3M6ASrKQWYKOWdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLkV4
cG9ydEFuYWx5dGljc01ldHJpY3NSZXNwb25zZRIpZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJl
dGEuRXhwb3J0TWV0YWRhdGEaScpBFXJldGFpbC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C1AEKHmNvbS5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YUIVQW5hbHl0aWNzU2VydmljZVByb3RvUAFaNmNsb3VkLmdv
b2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYmV0YS9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJ
TKoCGkdvb2dsZS5DbG91ZC5SZXRhaWwuVjJCZXRhygIaR29vZ2xlXENsb3VkXFJldGFpbFxW
MmJldGHqAh1Hb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYmV0YUqiCgoGEgQOADgBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACYKCQoC
AwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAOAoJCgIDBRIDFwAtCggK
AQgSAxkANwoJCgIIJRIDGQA3CggKAQgSAxoATQoJCgIICxIDGgBNCggKAQgSAxsAIgoJCgII
ChIDGwAiCggKAQgSAxwANgoJCgIICBIDHAA2CggKAQgSAx0ANwoJCgIIARIDHQA3CggKAQgS
Ax4AJAoJCgIIJBIDHgAkCggKAQgSAx8ANwoJCgIIKRIDHwA3CggKAQgSAyAANgoJCgIILRID
IAA2CpEBCgIGABIEJAA4ARqEASBTZXJ2aWNlIGZvciBtYW5hZ2luZyAmIGFjY2Vzc2luZyBy
ZXRhaWwgc2VhcmNoIGJ1c2luZXNzIG1ldHJpYy4KIFJldGFpbCByZWNvbW1lbmRhdGlvbiBi
dXNpbmVzcyBtZXRyaWMgaXMgY3VycmVudGx5IG5vdCBhdmFpbGFibGUuCgoKCgMGAAESAyQI
GAoKCgMGAAMSAyUCPQoMCgUGAAOZCBIDJQI9CgsKAwYAAxIEJgInNwoNCgUGAAOaCBIEJgIn
NwqiAQoEBgACABIELQI3AxqTASBFeHBvcnRzIGFuYWx5dGljcyBtZXRyaWNzLgoKIGBPcGVy
YXRpb24ucmVzcG9uc2VgIGlzIG9mIHR5cGUgYEV4cG9ydEFuYWx5dGljc01ldHJpY3NSZXNw
b25zZWAuCiBgT3BlcmF0aW9uLm1ldGFkYXRhYCBpcyBvZiB0eXBlIGBFeHBvcnRNZXRhZGF0
YWAuCgoMCgUGAAIAARIDLQYcCgwKBQYAAgACEgMtHToKDAoFBgACAAMSAy4PKwoNCgUGAAIA
BBIELwQyBgoRCgkGAAIABLDKvCISBC8EMgYKDQoFBgACAAQSBDMENgYKDwoHBgACAASZCBIE
MwQ2BmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Retail::V2beta::AnalyticsService::AnalyticsServiceClient ===
package Google::Cloud::Retail::V2beta::AnalyticsService::AnalyticsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::AnalyticsService::AnalyticsServiceClient

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
        ? Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.AnalyticsService',
        method         => 'ExportAnalyticsMetrics',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::AnalyticsService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/analytics_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/analytics_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::AnalyticsService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
